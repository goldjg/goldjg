# ISDF_Detect.ps1
# Outputs exactly the 4 booleans your compliance JSON expects:
# AzEnvOk, TenantIdOk, SystemManufacturerOk, SystemProductNamePrefixOk

# -------- Force 64-bit ----------
if ($env:PROCESSOR_ARCHITEW6432 -and -not $env:CI_RUN_IN_64BIT) {
    $env:CI_RUN_IN_64BIT = '1'
    & "$env:WINDIR\SysNative\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath @args
    exit $LASTEXITCODE
}
# ---------------------------------
$ErrorActionPreference = 'SilentlyContinue'

$RegPath = 'HKLM:\SOFTWARE\ISDF'
$ExpectedManufacturer = 'Microsoft Corporation'
$CorpTenant = 'd980314b-cb2f-44e3-9ce7-06d7361ab382'

# Helpers
function Get-IMDS {
    for ($i=0; $i -lt 3; $i++) {
        try {
            return Invoke-RestMethod -Headers @{ Metadata='true' } -Uri 'http://169.254.169.254/metadata/instance?api-version=2021-02-01' -TimeoutSec 3
        } catch { Start-Sleep -Seconds (2 * ($i+1)) }
    }
    $null
}
function Parse-TagValue($compute, [string]$needle) {
    if (-not $compute) { return $null }
    $val = $null
    if ($compute.PSObject.Properties.Name -contains 'tagsList' -and $compute.tagsList) {
        foreach ($e in $compute.tagsList) {
            $s = [string]$e
            if ($s -like "*$needle*") {
                $txt = $s.Trim('@','{','}')
                $name = $null; $value = $null
                foreach ($p in ($txt -split ';')) {
                    $kv = $p.Trim()
                    if ($kv -like 'name=*')  { $name  = $kv.Substring(5) }
                    if ($kv -like 'value=*') { $value = $kv.Substring(6) }
                }
                $val = $value; break
            }
        }
    }
    if (-not $val -and $compute.PSObject.Properties.Name -contains 'tags' -and $compute.tags) {
        $flat = [string]$compute.tags
        if ($flat -match "$([Regex]::Escape($needle)):([^;]+)") { $val = $matches[1].Trim() }
    }
    return $val
}
function Get-Channel($compute) {
    $src = Parse-TagValue -compute $compute -needle 'origin.sourcearmid.0'
    if (-not $src) { return 'W365' }
    if ($src -match 'Providers/Microsoft\.DevCenter')             { return 'DevBox' }
    if ($src -match 'Providers/Microsoft\.DesktopVirtualization')  { return 'AVD' }
    if ($src -match 'Providers/Microsoft\.DevTestLab')             { return 'DevTestLab' }
    'W365'
}
function Get-OriginTenantId($compute) {
    Parse-TagValue -compute $compute -needle 'origin.tenantid'
}
function Derive-KeyBytes16($compute) {
    if (-not $compute) { return $null }
    $azEnv = if ($compute.PSObject.Properties.Name -contains 'azEnvironment') { $compute.azEnvironment } else { $null }
    $subId = if ($compute.PSObject.Properties.Name -contains 'subscriptionId') { $compute.subscriptionId } else { $null }
    $rg    = if ($compute.PSObject.Properties.Name -contains 'resourceGroupName') { $compute.resourceGroupName } else { $null }
    $vmId  = if ($compute.PSObject.Properties.Name -contains 'vmId') { $compute.vmId } else { $null }
    $offer = if ($compute.PSObject.Properties.Name -contains 'offer') { $compute.offer } else { $null }
    $tenId = Get-OriginTenantId $compute
    $parts = @($azEnv,$subId,$rg,$vmId,$offer,$tenId) -join '|'
    $sha = [Security.Cryptography.SHA256]::Create()
    try { $digest = $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($parts)) } finally { $sha.Dispose() }
    return $digest[0..15]
}
function Unprotect-WithKey([string]$blob, [byte[]]$key) {
    try {
        $sec = ConvertTo-SecureString -String $blob -Key $key
        $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
        try { [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
        finally { if ($ptr -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) } }
    } catch { $null }
}
function FromDoubleB64([string]$s) {
    try {
        $b1 = [Convert]::FromBase64String($s)
        $s1 = [Text.Encoding]::UTF8.GetString($b1)
        $b2 = [Convert]::FromBase64String($s1)
        [Text.Encoding]::UTF8.GetString($b2)
    } catch { $null }
}

# Live values (SystemInformation only)
$sysMfr  = $null
$sysProd = $null
try {
    $si = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SystemInformation' -ErrorAction Stop
    $sysMfr  = $si.SystemManufacturer
    $sysProd = $si.SystemProductName
} catch {}

# IMDS + channel + gating
$imds    = Get-IMDS
$compute = if ($imds -and $imds.PSObject.Properties.Name -contains 'compute') { $imds.compute } else { $null }
$azEnv   = if ($compute -and $compute.PSObject.Properties.Name -contains 'azEnvironment') { $compute.azEnvironment } else { $null }
$tenantId= Get-OriginTenantId $compute
$channel = if ($compute) { Get-Channel $compute } else { $null }
$provName= if ($compute -and $compute.PSObject.Properties.Name -contains 'osProfile' -and $compute.osProfile) { $compute.osProfile.computerName } else { $null }
$localHost = ($env:COMPUTERNAME -split '\.')[0]

# Defaults: IMDS-sourced checks default to TRUE when IMDS is inactive
$AzEnvOk    = $true
$TenantIdOk = $true
$SystemManufacturerOk      = $true
$SystemProductNamePrefixOk = $true

$imdsActive = ($azEnv -and $azEnv -eq 'AzurePublicCloud')
if ($imdsActive) {
    $AzEnvOk    = $true
    $TenantIdOk = ($tenantId -eq $CorpTenant)

    # Expected values from registry (prefer v2 with -Key; else v1)
    $SM_v2=$null;$SPN_v2=$null;$Prov_v2=$null;$SM_v1=$null;$SPN_v1=$null;$Prov_v1=$null
    try {
        $p = Get-ItemProperty -Path $RegPath -ErrorAction Stop
        if ($p.PSObject.Properties.Name -contains 'SM_v2')     { $SM_v2  = $p.SM_v2 }
        if ($p.PSObject.Properties.Name -contains 'SPN_v2')    { $SPN_v2 = $p.SPN_v2 }
        if ($p.PSObject.Properties.Name -contains 'ProvName_v2'){ $Prov_v2= $p.ProvName_v2 }
        if ($p.PSObject.Properties.Name -contains 'SM')        { $SM_v1  = $p.SM }
        if ($p.PSObject.Properties.Name -contains 'SPN')       { $SPN_v1 = $p.SPN }
        if ($p.PSObject.Properties.Name -contains 'ProvName')  { $Prov_v1= $p.ProvName }
    } catch {}

    $keyBytes = Derive-KeyBytes16 $compute
    $expSM  = $ExpectedManufacturer
    $expSPN = if ($channel -eq 'DevBox') { 'Microsoft Dev Box' } else { 'Cloud PC' }
    $expProv= $provName

    if ($keyBytes -and $SM_v2 -and $SPN_v2) {
        $tmpSM  = Unprotect-WithKey $SM_v2  $keyBytes
        $tmpSPN = Unprotect-WithKey $SPN_v2 $keyBytes
        if ($tmpSM)  { $expSM  = $tmpSM }
        if ($tmpSPN) { $expSPN = $tmpSPN }
    } elseif ($SM_v1 -and $SPN_v1) {
        $tmpSM  = FromDoubleB64 $SM_v1
        $tmpSPN = FromDoubleB64 $SPN_v1
        if ($tmpSM)  { $expSM  = $tmpSM }
        if ($tmpSPN) { $expSPN = $tmpSPN }
    }
    if ($keyBytes -and $Prov_v2) {
        $tmpProv = Unprotect-WithKey $Prov_v2 $keyBytes
        if ($tmpProv) { $expProv = $tmpProv }
    } elseif ($Prov_v1) {
        $tmpProv = FromDoubleB64 $Prov_v1
        if ($tmpProv) { $expProv = $tmpProv }
    }

    # Manufacturer check
    $SystemManufacturerOk = ($sysMfr -eq $expSM)

    # Channel-aware check:
    if ($channel -in @('W365','DevBox')) {
        # W365: expect "Cloud PC"; DevBox: expect "Microsoft Dev Box"
        $SystemProductNamePrefixOk = ($sysProd -and $expSPN -and $sysProd.StartsWith($expSPN))
    } elseif ($channel -in @('AVD','DevTestLab')) {
        # Omit model; enforce hostname equals provisioned name
        $SystemProductNamePrefixOk = ($expProv -and ($localHost.Trim().ToUpper() -eq $expProv.Trim().ToUpper()))
    } else {
        # Unknown: be conservative, use model prefix "Cloud PC"
        $SystemProductNamePrefixOk = ($sysProd -and $sysProd.StartsWith('Cloud PC'))
    }
}

# Emit only the four booleans
[ordered]@{
    AzEnvOk = [bool]$AzEnvOk
    TenantIdOk = [bool]$TenantIdOk
    SystemManufacturerOk = [bool]$SystemManufacturerOk
    SystemProductNamePrefixOk = [bool]$SystemProductNamePrefixOk
} | ConvertTo-Json -Compress

# Exit according to AND of four booleans
if ($AzEnvOk -and $TenantIdOk -and $SystemManufacturerOk -and $SystemProductNamePrefixOk) { exit 0 } else { exit 1 }
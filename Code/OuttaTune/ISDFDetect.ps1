# ISDFDetect.ps1
# Emits exactly 5 booleans for ISDF compliance:
# AzEnvOk, TenantIdOk, SystemManufacturerOk, SystemProductNamePrefixOk, HostnameOk

# -------- Force 64-bit ----------
if ($env:PROCESSOR_ARCHITEW6432 -and -not $env:CI_RUN_IN_64BIT) {
    $env:CI_RUN_IN_64BIT = '1'
    & "$env:WINDIR\SysNative\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath @args
    exit $LASTEXITCODE
}
# ---------------------------------
$ErrorActionPreference = 'SilentlyContinue'

# Constants
$RegPath = 'HKLM:\SOFTWARE\ISDF'
$ExpectedManufacturer = 'Microsoft Corporation'
$CorpTenant = 'd980314b-cb2f-44e3-9ce7-06d7361ab382'

# ---------- Helpers ----------
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
# Channel classification (W365 = zero subscription GUID AND no /providers/ in origin.sourcearmid.0)
function Get-Channel($compute) {
    $src = Parse-TagValue -compute $compute -needle 'origin.sourcearmid.0'
    if (-not $src) { return 'Unknown' }

    $sid = $null
    if ($src -match '/subscriptions/([0-9a-fA-F-]{36})') { $sid = $matches[1] }
    $hasProviders = ($src -match '/providers/')
    $isZeroSid = $false
    if ($sid) { $isZeroSid = (($sid -replace '-', '') -match '^0{32}$') }

    if ($isZeroSid -and -not $hasProviders) { return 'W365' }
    if ($src -match 'Providers/Microsoft\.DevCenter')             { return 'DevBox' }
    if ($src -match 'Providers/Microsoft\.DesktopVirtualization') { return 'AVD' }
    if ($src -match 'Providers/Microsoft\.DevTestLab')            { return 'DevTestLab' }
    return 'Unknown'
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
function Protect-Text-WithKey([string]$plain, [byte[]]$key) {
    $sec = ConvertTo-SecureString -String $plain -AsPlainText -Force
    ConvertFrom-SecureString -SecureString $sec -Key $key
}
function Unprotect-WithKey([string]$blob, [byte[]]$key) {
    try {
        $sec = ConvertTo-SecureString -String $blob -Key $key
        $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
        try { [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
        finally { if ($ptr -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) } }
    } catch { $null }
}
function DoubleB64([string]$s) {
    $b1=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($s))
    [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($b1))
}
function FromDoubleB64([string]$s) {
    try {
        $b1 = [Convert]::FromBase64String($s)
        $s1 = [Text.Encoding]::UTF8.GetString($b1)
        $b2 = [Convert]::FromBase64String($s1)
        [Text.Encoding]::UTF8.GetString($b2)
    } catch { $null }
}
# -----------------------------

# Live values (SystemInformation only; no WMI)
$sysMfr  = $null
$sysProd = $null
try {
    $si = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SystemInformation' -ErrorAction Stop
    $sysMfr  = $si.SystemManufacturer
    $sysProd = $si.SystemProductName
} catch {}

# IMDS and channel
$imds    = Get-IMDS
$compute = if ($imds -and $imds.PSObject.Properties.Name -contains 'compute') { $imds.compute } else { $null }
$azEnv   = if ($compute -and $compute.PSObject.Properties.Name -contains 'azEnvironment') { $compute.azEnvironment } else { $null }
$tenantId= Get-OriginTenantId $compute
$channel = if ($compute) { Get-Channel $compute } else { $null }
$provName= if ($compute -and $compute.PSObject.Properties.Name -contains 'osProfile' -and $compute.osProfile) { $compute.osProfile.computerName } else { $null }

# Hostname boolean: compare LIVE hostname vs IMDS osProfile.computerName (case-insensitive, ignore domain)
$localHost = ($env:COMPUTERNAME -split '\.')[0]
$HostnameOk = $true
if ($compute -and $provName) {
    $HostnameOk = ($localHost.Trim().ToUpper() -eq $provName.Trim().ToUpper())
}

# IMDS gating (do not penalize when IMDS inactive/not AzurePublicCloud)
$AzEnvOk    = $true
$TenantIdOk = $true
$SystemManufacturerOk      = $true
$SystemProductNamePrefixOk = $true

$imdsActive = ($azEnv -and $azEnv -eq 'AzurePublicCloud')

# ---- Bootstrap: seed ISDF hive if IMDS is active and values are missing ----
if ($imdsActive) {
    $haveAny = $false
    if (Test-Path $RegPath) {
        try {
            $pre = Get-ItemProperty -Path $RegPath -ErrorAction Stop
            $haveAny = ($pre.PSObject.Properties.Name -contains 'SM_v2') -or
                       ($pre.PSObject.Properties.Name -contains 'SPN_v2') -or
                       ($pre.PSObject.Properties.Name -contains 'ProvName_v2') -or
                       ($pre.PSObject.Properties.Name -contains 'Channel_v2') -or
                       ($pre.PSObject.Properties.Name -contains 'SM') -or
                       ($pre.PSObject.Properties.Name -contains 'SPN') -or
                       ($pre.PSObject.Properties.Name -contains 'ProvName') -or
                       ($pre.PSObject.Properties.Name -contains 'Channel')
        } catch { $haveAny = $false }
    }
    if (-not $haveAny) {
        if (-not (Test-Path $RegPath)) { New-Item -Path $RegPath -Force | Out-Null }
        $keyBytes = Derive-KeyBytes16 $compute
        $expSpn = switch ($channel) {
            'DevBox'     { 'Microsoft Dev Box' }
            'AVD'        { '' }
            'DevTestLab' { '' }
            'W365'       { 'Cloud PC' }
            default      { 'Cloud PC' }
        }
        $seedOk = $false
        if ($keyBytes -and $keyBytes.Length -eq 16) {
            try {
                $encSM   = Protect-Text-WithKey $ExpectedManufacturer $keyBytes
                New-ItemProperty -Path $RegPath -Name 'SM_v2' -PropertyType String -Value $encSM -Force | Out-Null
                if ($expSpn) {
                    $encSPN = Protect-Text-WithKey $expSpn $keyBytes
                    New-ItemProperty -Path $RegPath -Name 'SPN_v2' -PropertyType String -Value $encSPN -Force | Out-Null
                }
                if ($provName) {
                    $encHost = Protect-Text-WithKey $provName $keyBytes
                    New-ItemProperty -Path $RegPath -Name 'ProvName_v2' -PropertyType String -Value $encHost -Force | Out-Null
                }
                $encChan = Protect-Text-WithKey $channel $keyBytes
                New-ItemProperty -Path $RegPath -Name 'Channel_v2' -PropertyType String -Value $encChan -Force | Out-Null
                New-ItemProperty -Path $RegPath -Name 'SCHEMA_VERSION' -PropertyType String -Value '2' -Force | Out-Null
                $seedOk = $true
            } catch { $seedOk = $false }
        }
        if (-not $seedOk) {
            # b64 fallback
            New-ItemProperty -Path $RegPath -Name 'SM'       -PropertyType String -Value (DoubleB64 $ExpectedManufacturer) -Force | Out-Null
            if ($expSpn)  { New-ItemProperty -Path $RegPath -Name 'SPN'      -PropertyType String -Value (DoubleB64 $expSpn) -Force | Out-Null }
            if ($provName){ New-ItemProperty -Path $RegPath -Name 'ProvName' -PropertyType String -Value (DoubleB64 $provName) -Force | Out-Null }
            New-ItemProperty -Path $RegPath -Name 'Channel'  -PropertyType String -Value (DoubleB64 $channel) -Force | Out-Null
        }
    }
}

# ---- Evaluate compliance when IMDS is active ----
if ($imdsActive) {
    $AzEnvOk    = $true
    $TenantIdOk = ($tenantId -eq $CorpTenant)

    # Read expected values (prefer v2; else v1)
    $SM_v2=$null;$SPN_v2=$null;$Prov_v2=$null;$SM_v1=$null;$SPN_v1=$null;$Prov_v1=$null
    try {
        $p = Get-ItemProperty -Path $RegPath -ErrorAction Stop
        if ($p.PSObject.Properties.Name -contains 'SM_v2')      { $SM_v2  = $p.SM_v2 }
        if ($p.PSObject.Properties.Name -contains 'SPN_v2')     { $SPN_v2 = $p.SPN_v2 }
        if ($p.PSObject.Properties.Name -contains 'ProvName_v2'){ $Prov_v2= $p.ProvName_v2 }
        if ($p.PSObject.Properties.Name -contains 'SM')         { $SM_v1  = $p.SM }
        if ($p.PSObject.Properties.Name -contains 'SPN')        { $SPN_v1 = $p.SPN }
        if ($p.PSObject.Properties.Name -contains 'ProvName')   { $Prov_v1= $p.ProvName }
    } catch {}

    $keyBytes = Derive-KeyBytes16 $compute
    $expSM  = $ExpectedManufacturer
    $expSPN = switch ($channel) {
        'DevBox'     { 'Microsoft Dev Box' }
        'AVD'        { '' }
        'DevTestLab' { '' }
        'W365'       { 'Cloud PC' }
        default      { 'Cloud PC' }
    }
    $expProv= $provName

    if ($keyBytes -and $SM_v2) {
        $tmp = Unprotect-WithKey $SM_v2 $keyBytes
        if ($tmp) { $expSM = $tmp }
    } elseif ($SM_v1) {
        $tmp = FromDoubleB64 $SM_v1
        if ($tmp) { $expSM = $tmp }
    }
    if ($expSPN) {
        if ($keyBytes -and $SPN_v2) {
            $tmp = Unprotect-WithKey $SPN_v2 $keyBytes
            if ($tmp) { $expSPN = $tmp }
        } elseif ($SPN_v1) {
            $tmp = FromDoubleB64 $SPN_v1
            if ($tmp) { $expSPN = $tmp }
        }
    }
    if ($keyBytes -and $Prov_v2) {
        $tmp = Unprotect-WithKey $Prov_v2 $keyBytes
        if ($tmp) { $expProv = $tmp }
    } elseif ($Prov_v1) {
        $tmp = FromDoubleB64 $Prov_v1
        if ($tmp) { $expProv = $tmp }
    }

    # Manufacturer
    $SystemManufacturerOk = ($sysMfr -eq $expSM)

    # Channel-aware model/hostname check
    if ($channel -in @('W365','DevBox')) {
        $SystemProductNamePrefixOk = ($sysProd -and $expSPN -and $sysProd.StartsWith($expSPN))
    } elseif ($channel -in @('AVD','DevTestLab')) {
        # For AVD/DTL we omit model check; rely on HostnameOk
        $SystemProductNamePrefixOk = $true
    } else {
        # Unknown: conservative default
        $SystemProductNamePrefixOk = ($sysProd -and $sysProd.StartsWith('Cloud PC'))
    }
}

# Emit only the five booleans
[ordered]@{
    AzEnvOk = [bool]$AzEnvOk
    TenantIdOk = [bool]$TenantIdOk
    SystemManufacturerOk = [bool]$SystemManufacturerOk
    SystemProductNamePrefixOk = [bool]$SystemProductNamePrefixOk
    HostnameOk = [bool]$HostnameOk
} | ConvertTo-Json -Compress

# Exit by AND
if ($AzEnvOk -and $TenantIdOk -and $SystemManufacturerOk -and $SystemProductNamePrefixOk -and $HostnameOk) { exit 0 } else { exit 1 }

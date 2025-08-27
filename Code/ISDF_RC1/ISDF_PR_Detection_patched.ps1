# ISDF_PR_Detection.ps1
# Proactive Remediation DETECT: validates ISDF v2 baseline against live facts.
# - PS 5.1-safe (no '??', no '?.'), no WMI
# - 64-bit bootstrap is synchronous
# - Decrypts HKLM:\SOFTWARE\ISDF\SignalProtected_v2 using the same per-VM key tuple
# - Compares stable fields (ignores TimestampUtc)
# - Exit 0 on full match; exit 1 otherwise

[CmdletBinding()]
param()

# ---- 64-bit bootstrap (avoid WOW64 registry redirection) ----
try {
    if ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) {
        $sysNative = "$env:WINDIR\SysNative\WindowsPowerShell\v1.0\powershell.exe"
        if (Test-Path $sysNative) {
            & $sysNative -NoLogo -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath @args
            exit $LASTEXITCODE
        }
    }
} catch {}

$ErrorActionPreference = 'Stop'
$RegBase = 'HKLM:\SOFTWARE\ISDF'

# ---------------- System / IMDS / AAD helpers ----------------
function Get-IMDSCompute {
    try {
        Invoke-RestMethod -Method GET -Uri 'http://169.254.169.254/metadata/instance/compute?api-version=2021-02-01' `
            -Headers @{ Metadata='true' } -TimeoutSec 2
    } catch { $null }
}
function Get-SystemInfo {
    $rk = 'HKLM:\SYSTEM\CurrentControlSet\Control\SystemInformation'
    try {
        $m = Get-ItemProperty -Path $rk -ErrorAction Stop
        [pscustomobject]@{ SystemManufacturer = $m.SystemManufacturer; SystemProductName = $m.SystemProductName }
    } catch { [pscustomobject]@{ SystemManufacturer=''; SystemProductName='' } }
}
function Get-DsRegStatusText { try { (& "dsregcmd.exe" /status) | Out-String } catch { '' } }
function Parse-GuidFromText { param([string]$Text,[string[]]$Labels)
    foreach ($label in $Labels) {
        $m = [regex]::Match($Text, "^\s*$label\s*:\s*([0-9a-fA-F-]{36})\s*$", 'Multiline')
        if ($m.Success) { return $m.Groups[1].Value }
    }
    $null
}
function Get-AADIds {
    $txt = Get-DsRegStatusText
    $tenantId = Parse-GuidFromText -Text $txt -Labels @('TenantId','AzureAdTenantId','Tenant Id')
    $deviceId = Parse-GuidFromText -Text $txt -Labels @('DeviceId','AzureAdDeviceId','Device Id')
    [pscustomobject]@{ TenantId=$tenantId; DeviceId=$deviceId }
}

# ---------------- Tag/origin helpers (PS 5.1 safe) ----------------
function Parse-TagsMap {
    param($compute)
    $map = @{}
    if ($compute -and ($compute.tags -is [string]) -and $compute.tags.Length -gt 0) {
        foreach ($pair in ($compute.tags -split ';')) {
            if ($pair -match '=') {
                $k,$v = $pair -split '=',2
                if ($k) { $map[$k.Trim().ToLower()] = $v.Trim() }
            }
        }
    }
    if ($compute -and $compute.tagsList) {
        foreach ($t in $compute.tagsList) {
            if ($t -is [string]) {
                $m = [regex]::Match($t, 'name\s*=\s*([^;]+);\s*value\s*=\s*(.+)\}?$')
                if ($m.Success) { $map[$m.Groups[1].Value.Trim().ToLower()] = $m.Groups[2].Value.Trim() }
            } elseif ($t -and $t.name) {
                $map[[string]$t.name.ToLower()] = [string]$t.value
            }
        }
    }
    $map
}
function Get-OriginSourceArmText {
    param($compute)
    $vals = @()
    try {
        if ($compute -and $compute.tagsList) {
            foreach ($t in $compute.tagsList) {
                if ($t -and $t.name -and $t.value) {
                    if ([string]$t.name -like 'ms.inv.v0.backedby.origin.sourcearmid*') { $vals += [string]$t.value }
                }
            }
        }
    } catch {}
    try {
        if ($compute -and ($compute.tags -is [string]) -and $compute.tags.Length -gt 0) {
            foreach ($pair in ($compute.tags -split ';')) {
                if ($pair -match '=') {
                    $k,$v = $pair -split '=',2
                    if ($k -and ($k.Trim().ToLower() -like 'ms.inv.v0.backedby.origin.sourcearmid*')) { $vals += $v.Trim() }
                }
            }
        }
    } catch {}
    (($vals -join ';')).ToLower()
}
function Has-DTLHiddenTags { param($compute,$tagsMap)
    if ($tagsMap) {
        foreach ($k in $tagsMap.Keys) { if ($k -match '^hidden-devtestlabs-') { return $true } }
    }
    if ($compute -and $compute.tagsList) {
        foreach ($t in $compute.tagsList) {
            if ($t -and $t.name -and ([string]$t.name).ToLower() -match '^hidden-devtestlabs-') { return $true }
        }
    }
    $false
}
function Test-ZeroGuid([string]$g){ return [bool]($g -match '^(00000000-0000-0000-0000-000000000000)$') }
function Derive-Channel {
    param($compute,$tagsMap)
    if (-not $compute) { return 'ISDF:AzureVM' }
    $src = Get-OriginSourceArmText -compute $compute
    if (-not [string]::IsNullOrEmpty($src)) {
        if ($src -match '/subscriptions/00000000-0000-0000-0000-000000000000') { return 'ISDF:W365' }
        if ($src -match '/providers/microsoft\.devcenter')                   { return 'ISDF:DevBox' }
        if ($src -match '/providers/microsoft\.desktopvirtualization')       { return 'ISDF:AVD' }
        if ($src -match '/providers/microsoft\.devtestlab')                  { return 'ISDF:DevTestLabs' }
    }
    $ridL = ([string]$compute.resourceId).ToLower()
    if ($ridL -match 'microsoft\.desktopvirtualization/hostpools') { return 'ISDF:AVD' }
    if (Has-DTLHiddenTags -compute $compute -tagsMap $tagsMap)     { return 'ISDF:DevTestLabs' }
    $nameL = ([string]$compute.name).ToLower()
    if (($compute.isHostCompatibilityLayerVm -eq $true) -or ($nameL -like 'cpc_*')) { return 'ISDF:W365' }
    'ISDF:AzureVM'
}

# ---------------- Crypto helpers (same as main detect) ----------------
function Key16 { param([string]$Tuple)
    $bytes=[Text.Encoding]::UTF8.GetBytes($Tuple.ToLower())
    $sha=[Security.Cryptography.SHA256]::Create()
    $h=$sha.ComputeHash($bytes)
    $h[0..15]
}
function Unprotect { param([string]$Cipher,[byte[]]$Key16)
    try {
        $sec=ConvertTo-SecureString -String $Cipher -Key $Key16
        $plain=[System.Net.NetworkCredential]::new('', $sec).Password
        ,$true,$plain
    } catch { ,$false,$null }
}

# ---------------- Gather live facts ----------------
$compute  = Get-IMDSCompute
$sys      = Get-SystemInfo
$aad      = Get-AADIds
$tagsMap  = Parse-TagsMap $compute

$hostname = $env:COMPUTERNAME

# Prefer osProfile.computerName; fallback to compute.name
$provComputer = $null
try {
    if ($compute -and ($compute | Get-Member -Name osProfile -ErrorAction SilentlyContinue)) {
        $osProf = $compute.osProfile
        if ($osProf -is [System.Collections.Hashtable]) {
            if ($osProf.Keys -contains 'computerName') { $provComputer = [string]$osProf['computerName'] }
        } else {
            $provComputer = [string]$osProf.computerName
        }
    }
} catch {}
if ([string]::IsNullOrWhiteSpace($provComputer)) { $provComputer = [string]$compute.name }

$azEnv      = [string]$compute.azEnvironment
$subId      = [string]$compute.subscriptionId
$rg         = [string]$compute.resourceGroupName
$vmId       = [string]$compute.vmId
$resourceId = [string]$compute.resourceId
$tenantId   = [string]$aad.TenantId
$liveChannel= Derive-Channel -compute $compute -tagsMap $tagsMap

# ---------------- Derive per-VM key (tuple) ----------------
$tuple = "{0}|{1}|{2}|{3}|{4}|{5}" -f $azEnv,$subId,$rg,$vmId,'',$tenantId
$key16 = Key16 $tuple

# ---------------- Read + decrypt baseline ----------------
$cipher = $null
try { $cipher = (Get-ItemProperty -Path $RegBase -Name 'SignalProtected_v2' -ErrorAction Stop).'SignalProtected_v2' } catch {}
if ([string]::IsNullOrWhiteSpace($cipher)) { Write-Host 'SignalProtected_v2 missing'; exit 1 }

$ok,$plain = Unprotect $cipher $key16
if (-not $ok -or [string]::IsNullOrWhiteSpace($plain)) { Write-Host 'Decrypt failed'; exit 1 }

# ---------------- Parse decrypted JSON and compare stable fields ----------------
try { $sig = $plain | ConvertFrom-Json -ErrorAction Stop } catch { $sig = $null }
if ($null -eq $sig) { Write-Host 'Decrypted JSON invalid'; exit 1 }

function _nz([string]$s){ if ($null -eq $s) { return '' } else { return $s } }
function Eq([string]$a,[string]$b){ $a=_nz $a; $b=_nz $b; return [string]::Equals($a,$b,'InvariantCulture') }
function Ei([string]$a,[string]$b){ $a=_nz $a; $b=_nz $b; return [string]::Equals($a,$b,'InvariantCultureIgnoreCase') }

$checks = @()
$checks += (Ei $sig.AzEnvironment        $azEnv)
$checks += (Ei $sig.SubscriptionId       $subId)
$checks += (Ei $sig.ResourceGroup        $rg)
$checks += (Ei $sig.VMId                 $vmId)
$checks += (Ei $sig.AadTenantId          $tenantId)
$checks += (Ei $sig.ResourceId           $resourceId)
$checks += (Ei $sig.Hostname             $hostname)
$checks += (Ei $sig.ProvisionedHostname  $provComputer)
$checks += (Eq $sig.SystemManufacturer   $sys.SystemManufacturer)
$checks += (Eq $sig.SystemProductName    $sys.SystemProductName)

# Channel (only enforce if present in baseline AND we could derive a live channel)
if ($sig.PSObject.Properties['Channel'] -and -not [string]::IsNullOrWhiteSpace($liveChannel)) {
    $checks += (Eq $sig.Channel $liveChannel)
}

# Evaluate
if ($checks.Count -eq 0 -or ($checks -contains $false)) {
    Write-Host 'Baseline does not match current stable fields'
    exit 1
}

Write-Host 'Local decrypt + stable-field compare OK'
exit 0
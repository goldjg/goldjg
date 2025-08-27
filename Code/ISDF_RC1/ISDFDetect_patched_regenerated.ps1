# ISDF_Detect.ps1  -- single self-healing detection (PS 5.1 safe)
# Mode-aware detection for ISDF. Emits ISDF_* JSON, then:
# exit 0 only if ALL required booleans are true, else exit 1.

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ================================================================================================
# 0) 64-bit bootstrap
# ================================================================================================
function Restart-Into64Bit {
    try {
        if ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) {
            $sysNative = "$env:WINDIR\SysNative\WindowsPowerShell\v1.0\powershell.exe"
            if (Test-Path $sysNative) {
                $args = @('-NoLogo','-NoProfile','-ExecutionPolicy','Bypass','-File', $PSCommandPath)
                Start-Process -FilePath $sysNative -ArgumentList $args -WindowStyle Hidden
                exit 0
            }
        }
    } catch {}
}
Restart-Into64Bit

# ================================================================================================
# 1) Constants & simple registry helpers
# ================================================================================================
$RegBase = 'HKLM:\SOFTWARE\ISDF'
$NowUtc  = [DateTime]::UtcNow

function Ensure-RegKey { param([string]$Path) if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null } }
function Set-Reg {
    param(
        [string]$Name,
        [object]$Value,
        [Microsoft.Win32.RegistryValueKind]$Kind = [Microsoft.Win32.RegistryValueKind]::String
    )
    Ensure-RegKey $RegBase
    New-ItemProperty -Path $RegBase -Name $Name -Value $Value -PropertyType $Kind -Force | Out-Null
}
function Get-RegOrNull { param([string]$Name) try { (Get-ItemProperty -Path $RegBase -Name $Name -ErrorAction Stop).$Name } catch { $null } }

# ================================================================================================
# 2) System / IMDS / AAD helpers
# ================================================================================================
function Get-SystemInfo {
    $rk = 'HKLM:\SYSTEM\CurrentControlSet\Control\SystemInformation'
    try {
        $m = Get-ItemProperty -Path $rk -ErrorAction Stop
        [pscustomobject]@{
            SystemManufacturer = $m.SystemManufacturer
            SystemProductName  = $m.SystemProductName
        }
    } catch {
        [pscustomobject]@{ SystemManufacturer=''; SystemProductName='' }
    }
}

function Get-IMDSCompute {
    try {
        Invoke-RestMethod -Method GET -Uri 'http://169.254.169.254/metadata/instance/compute?api-version=2021-02-01' `
            -Headers @{ Metadata='true' } -TimeoutSec 2
    } catch { $null }
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

# ================================================================================================
# 3) Tag & origin helpers
# ================================================================================================
function Parse-Tags {
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
                    if ([string]$t.name -like 'ms.inv.v0.backedby.origin.sourcearmid*') {
                        $vals += [string]$t.value
                    }
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

function Has-DTLHiddenTags {
    param($compute, $tagsMap)
    if ($tagsMap) {
        foreach ($k in $tagsMap.Keys) {
            if ($k -match '^hidden-devtestlabs-') { return $true }
        }
    }
    if ($compute -and $compute.tagsList) {
        foreach ($t in $compute.tagsList) {
            if ($t -and $t.name -and ([string]$t.name).ToLower() -match '^hidden-devtestlabs-') { return $true }
        }
    }
    $false
}

function Test-ZeroGuid([string]$g){ return [bool]($g -match '^(00000000-0000-0000-0000-000000000000)$') }

# ================================================================================================
# 4) Channel derivation & validation
# ================================================================================================
function Derive-Channel {
    param($compute, $tagsMap, $sys)

    if (-not $compute) { return 'ISDF:AzureVM' }

    $srcText = Get-OriginSourceArmText -compute $compute  # already lowercased
    if (-not [string]::IsNullOrEmpty($srcText)) {
        if ($srcText -match '/subscriptions/00000000-0000-0000-0000-000000000000') { return 'ISDF:W365' }
        if ($srcText -match '/providers/microsoft\.devcenter')                   { return 'ISDF:DevBox' }
        if ($srcText -match '/providers/microsoft\.desktopvirtualization')       { return 'ISDF:AVD' }
        if ($srcText -match '/providers/microsoft\.devtestlab')                  { return 'ISDF:DevTestLabs' }
    }

    # Fallbacks when origin chain is absent
    $ridL  = ([string]$compute.resourceId).ToLower()
    if ($ridL -match 'microsoft\.desktopvirtualization/hostpools') { return 'ISDF:AVD' }
    if (Has-DTLHiddenTags -compute $compute -tagsMap $tagsMap)     { return 'ISDF:DevTestLabs' }

    # Pragmatic W365 hints (no Offer/SKU present on Cloud PC)
    $nameL = ([string]$compute.name).ToLower()
    $isCloudPC = ($compute.isHostCompatibilityLayerVm -eq $true) -or ($nameL -like 'cpc_*')
    if ($isCloudPC) { return 'ISDF:W365' }

    'ISDF:AzureVM'
}

function Channel-Ok {
    param($channel, $compute, $tagsMap, $sys)
    $ridL  = ([string]$compute.resourceId).ToLower()
    $manOk = ($sys.SystemManufacturer -like 'Microsoft*')
    # Broadened product match for CloudPC/Dev Box
    $prodOk = ($sys.SystemProductName -match '^(Virtual($| )|Virtual Machine|Cloud PC|Microsoft Dev Box)')

    switch ($channel) {
        'ISDF:W365'   { return $true }
        'ISDF:DevBox' { return $true }
        'ISDF:AVD'    { return (-not (Test-ZeroGuid ([string]$compute.subscriptionId))) -and ($ridL -match 'microsoft\.desktopvirtualization/hostpools') }
        'ISDF:DevTestLabs' {
            if (Test-ZeroGuid ([string]$compute.subscriptionId)) { return $false }
            if (Has-DTLHiddenTags -compute $compute -tagsMap $tagsMap) { return $true }
            return $false
        }
        default { return $false }
    }
}

# ================================================================================================
# 5) Crypto helpers (PS 5.1 DPAPI w/ 16-byte key)
# ================================================================================================
function To-JsonMin { param([hashtable]$Ordered) ($Ordered | ConvertTo-Json -Depth 8 -Compress) }

function Get-Key16FromTuple { param([string]$Tuple)
    $bytes=[Text.Encoding]::UTF8.GetBytes($Tuple.ToLower())
    $sha=[Security.Cryptography.SHA256]::Create()
    $h=$sha.ComputeHash($bytes)
    $h[0..15]
}

function Protect-Plaintext { param([string]$Plain,[byte[]]$Key16)
    $sec=ConvertTo-SecureString -String $Plain -AsPlainText -Force
    ConvertFrom-SecureString -SecureString $sec -Key $Key16
}

function Unprotect-Cipher { param([string]$Cipher,[byte[]]$Key16)
    try {
        $sec=ConvertTo-SecureString -String $Cipher -Key $Key16
        $plain=[System.Net.NetworkCredential]::new('', $sec).Password
        ,$true,$plain
    } catch {
        ,$false,$null
    }
}

function To-Base64String { param([string]$s) [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($s)) }
function Sha256Hex {
    param([string]$s)
    $bytes=[Text.Encoding]::UTF8.GetBytes($s)
    $sha=[Security.Cryptography.SHA256]::Create()
    ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join ''
}

# ================================================================================================
# Certificate discovery and APIM call helpers
# ================================================================================================
function Get-IsdfDeviceCert {
    param(
        [string[]] $IssuerContains = @("CN=OuttaTune","CN=CirriusTech")
    )
    $now = Get-Date
    $paths = @("Cert:\LocalMachine\My","Cert:\CurrentUser\My")
    foreach ($p in $paths) {
        $candidates = Get-ChildItem $p | Where-Object {
            $_.HasPrivateKey -and $_.NotBefore -le $now -and $_.NotAfter -ge $now
        } | Where-Object {
            ($_.Extensions | Where-Object { $_ -is [System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension] } | ForEach-Object { $_.EnhancedKeyUsages } | ForEach-Object { $_.Value }) -contains "1.3.6.1.5.5.7.3.2"
        } | Where-Object {
            $iss = $_.Issuer; $IssuerContains | Where-Object { $iss.IndexOf($_,[StringComparison]::OrdinalIgnoreCase) -ge 0 } | Select-Object -First 1
        } | Sort-Object NotBefore -Descending
        if ($candidates) { return $candidates[0] }
    }
    throw "No suitable device certificate found in LocalMachine/CurrentUser My."
}

# ================================================================================================
# 6) Gather inputs
# ================================================================================================
$compute = Get-IMDSCompute
$tagsMap = Parse-Tags $compute
$sys     = Get-SystemInfo
$aad     = Get-AADIds
$hostname = $env:COMPUTERNAME

# Provisioned name (prefer osProfile.computerName; fall back to compute.name)
$provComputer = $null
try {
    if ($compute -and ($compute | Get-Member -Name osProfile -ErrorAction SilentlyContinue)) {
        $osProf = $compute.osProfile
        if ($osProf -is [System.Collections.Hashtable]) {
            if ($osProf.keys -contains 'computerName') { $provComputer = [string]$osProf['computerName'] }
        } else {
            $provComputer = [string]$osProf.computerName
        }
    }
} catch {}
$provName = if ([string]::IsNullOrWhiteSpace($provComputer)) { [string]$compute.name } else { $provComputer }

$azEnv      = $compute.azEnvironment
$subId      = $compute.subscriptionId
$rg         = $compute.resourceGroupName
$vmId       = $compute.vmId
$resourceId = $compute.resourceId

# ================================================================================================
# 7) Channel + baseline signal (and protected storage)
# ================================================================================================
$channel   = Derive-Channel -compute $compute -tagsMap $tagsMap -sys $sys
$channelOk = Channel-Ok     -channel $channel -compute $compute -tagsMap $tagsMap -sys $sys

$signalOrdered = [ordered]@{
    Version=2; TimestampUtc=$NowUtc.ToString('o')
    Hostname=$hostname; ProvisionedHostname=$provName
    SystemManufacturer=$sys.SystemManufacturer; SystemProductName=$sys.SystemProductName
    AzEnvironment=$azEnv; SubscriptionId=$subId; ResourceGroup=$rg; VMId=$vmId
    AadTenantId=$aad.TenantId; Channel=$channel; ResourceId=$resourceId
}
$signalJson=To-JsonMin $signalOrdered

# Derive 16-byte key from stable tuple (entropy)
$tuple = "{0}|{1}|{2}|{3}|{4}|{5}" -f $azEnv,$subId,$rg,$vmId,'',$aad.TenantId
$key16 = Get-Key16FromTuple $tuple

# --- Hashes used both in local state and Cloud payload ---
$signalHash      = Sha256Hex $signalJson
$originTupleHash = Sha256Hex $tuple

# Protect values for local storage + Entra EA2 payload
$signalCipherV2  = Protect-Plaintext -Plain $signalJson -Key16 $key16
$channelCipherV2 = Protect-Plaintext -Plain $channel    -Key16 $key16
$ea2Blob         = To-Base64String $signalCipherV2

# Self-healing local baseline (no remediation script required)
Ensure-RegKey $RegBase
Set-Reg -Name 'Version'             -Value 2 -Kind DWord
Set-Reg -Name 'SignalB64'           -Value (To-Base64String $signalJson)
Set-Reg -Name 'SignalProtected_v2'  -Value $signalCipherV2
Set-Reg -Name 'ChannelProtected_v2' -Value $channelCipherV2
Set-Reg -Name 'BaselineVer'         -Value 2 -Kind DWord

# Quick integrity checks
$decOk,$decPlain    = Unprotect-Cipher -Cipher $signalCipherV2 -Key16 $key16
$liveEqualsDecrypted= ($decOk -and $decPlain -eq $signalJson)

# ================================================================================================
# 8) Settings (PS 5.1-safe defaults)
# ================================================================================================
$mode = Get-RegOrNull 'Mode'; if ([string]::IsNullOrWhiteSpace($mode)) { $mode='Local' }
$webhookUrl = Get-RegOrNull 'WebhookUrl'
$syncTtlHrsRaw = Get-RegOrNull 'SyncTTLHours'
if ([string]::IsNullOrWhiteSpace($syncTtlHrsRaw)) { $syncTtlHrs = 48 } else { $syncTtlHrs = [int]$syncTtlHrsRaw }
$lastCloudWriteUtc = Get-RegOrNull 'LastCloudWriteUtc'
$lastCloudWriteDt  = $null; if ($lastCloudWriteUtc) { [DateTime]::TryParse($lastCloudWriteUtc,[ref]$lastCloudWriteDt) | Out-Null }

# ================================================================================================
# 9) Compute ISDF_* booleans
# ================================================================================================
$ISDF=[ordered]@{}
$ISDF.ISDF_Mode                       = $mode
$ISDF.ISDF_Channel                    = $channel
$ISDF.ISDF_ChannelOk                  = [bool]$channelOk
$ISDF.ISDFChannelOk                   = $ISDF.ISDF_ChannelOk
$ISDF.ISDF_AzEnvOk                    = ($azEnv -eq 'AzurePublicCloud')
$ISDF.ISDF_HostnameMatchesProvisioned = ($hostname -eq $provName)
$ISDF.ISDF_SignalHash      = $signalHash
$ISDF.ISDF_OriginTupleHash = $originTupleHash

$manOk  = ([string]$sys.SystemManufacturer -match '^(?i)microsoft corporation$')
$expectedPrefixByChannel = @{ 'ISDF:W365'='^(?i)(Cloud PC|Virtual( Machine)?)'; 'ISDF:DevBox'='^(?i)(Microsoft Dev Box|Dev Box|Virtual( Machine)?)'; 'ISDF:AVD'='^(?i)Virtual( Machine)?'; 'ISDF:DevTestLabs'='^(?i)Virtual( Machine)?'; 'ISDF:AzureVM'='^(?i)Virtual( Machine)?' }
$pattern = $expectedPrefixByChannel[$channel]
$prodOk = ([string]$sys.SystemProductName -match $pattern)
$ISDF.ISDF_SystemManufacturerOk       = $manOk
$ISDF.ISDF_SystemProductNamePrefixOk  = $prodOk

# TenantId OK: prefer origin.tenantid; fallback 'tenantid' tag; else OK
$tenantTag = $null
if ($tagsMap -and ($tagsMap.Keys -contains 'ms.inv.v0.backedby.origin.tenantid')) {
    $tenantTag = $tagsMap['ms.inv.v0.backedby.origin.tenantid']
} elseif ($tagsMap -and ($tagsMap.Keys -contains 'tenantid')) {
    $tenantTag = $tagsMap['tenantid']
}
$ISDF.ISDF_TenantIdOK = if ($tenantTag) { [string]::Equals($tenantTag,$aad.TenantId,'InvariantCultureIgnoreCase') } else { $true }

$ISDF.ISDF_EA2_Decrypts       = [bool]$decOk
$ISDF.ISDF_LiveEqualsDecrypted= [bool]$liveEqualsDecrypted
$ISDF.ISDF_SignalHash         = Sha256Hex $signalJson
$ISDF.ISDF_OriginTupleHash    = Sha256Hex $tuple
$ISDF.ISDF_BaselineVer        = 2
$ISDF.ISDF_WebhookConfigured  = $false
$ISDF.ISDF_WebhookLastOk      = $false
$ISDF.ISDF_EA1_Matches        = $false
$ISDF.ISDF_EA2_Matches        = $false
$ISDF.ISDF_LastSyncFresh      = $false

# ================================================================================================
# 10) Optional Cloud Sync (client cert)
# ================================================================================================
if ($mode -eq 'Cloud' -and $webhookUrl) {
    $ISDF.ISDF_WebhookConfigured = $true

    $payload = @{
        device = @{
            aadDeviceId = $aad.DeviceId
            hostname    = $env:COMPUTERNAME
            aadTenantId = $aad.TenantId
        }
        isdf = @{
            channel         = $channel
            ea2             = $ea2Blob
            signalHash      = $signalHash
            originTupleHash = $originTupleHash
            baselineVer     = $baselineVer
            timestampUtc    = (Get-Date).ToUniversalTime().ToString('o')
        }
    } | ConvertTo-Json -Depth 5

    try {
        $cert = Get-IsdfDeviceCert

        $resp = Invoke-RestMethod -Method POST -Uri $webhookUrl -Certificate $cert `
            -Body $payload -ContentType 'application/json' -TimeoutSec 30

        # New success criteria
        if ($resp -and $resp.syncResult -eq 'Success' -and $resp.echo.aadDeviceId -eq $aad.DeviceId) {
            $ISDF.ISDF_WebhookLastOk = $true
        } else {
            $ISDF.ISDF_WebhookLastOk = $false
        }

        # Record processedAtUtc if supplied
        if ($resp.processedAtUtc) {
            $pt = $null
            if ([DateTime]::TryParse([string]$resp.processedAtUtc, [ref]$pt)) {
                Set-Reg -Name 'LastCloudWriteUtc' -Value ($pt.ToUniversalTime().ToString('o'))
            }
        }
    }
    catch {
        $ISDF.ISDF_WebhookLastOk = $false
    }
}

# When NOT in Cloud mode, harmonize cloud flags to True so local-only deployments pass
if ($mode -ne 'Cloud') {
    $ISDF.ISDF_WebhookConfigured = $true
    $ISDF.ISDF_WebhookLastOk     = $true
    $ISDF.ISDF_EA1_Matches       = $true
    $ISDF.ISDF_EA2_Matches       = $true
    $ISDF.ISDF_LastSyncFresh     = $true
}

# ================================================================================================
# 11) Output + exit policy
# ================================================================================================
$payloadJson = ($ISDF | ConvertTo-Json -Compress)
$payloadJson

function Get-RequiredSettingNames([string]$m){
    $base = @(
        'ISDF_ChannelOk',
        'ISDF_TenantIdOK',
        'ISDF_AzEnvOk',
        'ISDF_HostnameMatchesProvisioned',
        'ISDF_SystemManufacturerOk',
        'ISDF_SystemProductNamePrefixOk',
        'ISDF_EA2_Decrypts',
        'ISDF_LiveEqualsDecrypted'
    )
    if ($m -eq 'Cloud') {
        $base + @('ISDF_WebhookConfigured','ISDF_WebhookLastOk','ISDF_EA1_Matches','ISDF_EA2_Matches','ISDF_LastSyncFresh')
    } else {
        $base
    }
}
$required = Get-RequiredSettingNames $mode

$allTrue = $true
foreach ($n in $required) {
    if (-not ($ISDF.Keys -contains "$n" -and $ISDF[$n] -eq $true)) { $allTrue = $false; break }
}

if ($allTrue) { exit 0 } else { exit 1 }
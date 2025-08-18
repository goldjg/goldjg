# ISDF_Detect.ps1  -- single self-healing detection (PS 5.1 safe)

# -------- 64-bit trampoline --------
if ($env:PROCESSOR_ARCHITEW6432 -and -not $env:ISDF_RUN_64) {
    $env:ISDF_RUN_64 = '1'
    $ps64 = Join-Path $env:WINDIR 'SysNative\WindowsPowerShell\v1.0\powershell.exe'
    & $ps64 -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath @args
    exit $LASTEXITCODE
}
# -----------------------------------

$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference    = 'SilentlyContinue'

# ----------------- Config -----------------
$RegPath              = 'HKLM:\SOFTWARE\ISDF'
$Name_SignalB64       = 'SignalB64'
$Name_SignalProt      = 'SignalProtected'      # DPAPI (legacy fallback)
$Name_ChannelProt     = 'ChannelProtected'     # DPAPI (legacy fallback)
$Name_SignalProtV2    = 'SignalProtected_v2'   # Protected with per-VM Key
$Name_ChannelProtV2   = 'ChannelProtected_v2'  # Protected with per-VM Key
$Name_Version         = 'Version'
$SchemaVersion        = '2'

$ImdsApiVersion       = '2021-02-01'
$SysInfoKey           = 'HKLM:\SYSTEM\CurrentControlSet\Control\SystemInformation'
$ExpectedManufacturer = 'Microsoft Corporation'
$ExpectedTenantId     = 'd980314b-cb2f-44e3-9ce7-06d7361ab382'
$Prefix_W365          = 'Cloud PC'
$Prefix_DevBox        = 'Microsoft Dev Box'
# -------------------------------------------

# ---------- Helpers (PS 5.1 safe) ----------
function Get-ImdsCompute {
    $hdr = New-Object 'System.Collections.Generic.Dictionary[string,string]'
    $hdr.Add('Metadata','true')
    $uri = "http://169.254.169.254/metadata/instance?api-version=$ImdsApiVersion"
    for ($i=0; $i -lt 2; $i++) {
        try {
            $resp = Invoke-RestMethod -Headers $hdr -Method GET -Uri $uri -TimeoutSec 2
            if ($resp -and $resp.compute) { return $resp.compute }
        } catch { Start-Sleep -Milliseconds (200 * ($i+1)) }
    }
    return $null
}
function Get-SystemInfo {
    $m=$null;$p=$null
    try {
        $si = Get-ItemProperty -Path $SysInfoKey -ErrorAction Stop
        $m = [string]$si.SystemManufacturer
        $p = [string]$si.SystemProductName
    } catch {}
    [pscustomobject]@{ Manufacturer=$m; Product=$p }
}
function Get-TagsMap($compute) {
    $map=@{}
    if ($compute -and $compute.tagsList) {
        foreach ($t in $compute.tagsList) { if ($t -and $t.name) { $map[$t.name]=$t.value } }
    }
    $map
}
function Derive-Channel($compute) {
    if (-not $compute) { return 'Unknown' }
    $vals=@()
    if ($compute.tagsList) {
        foreach ($t in $compute.tagsList) {
            if ($t.name -like 'ms.inv.v0.backedby.origin.sourcearmid*' -and $t.value) { $vals += [string]$t.value }
        }
    }
    $srcText = ($vals -join ';')
    if ([string]::IsNullOrEmpty($srcText)) { return 'Unknown' }
    if ($srcText -match '/subscriptions/00000000-0000-0000-0000-000000000000') { return 'W365' }
    if ($srcText -match '/providers/Microsoft\.DevCenter')             { return 'DevBox' }
    if ($srcText -match '/providers/Microsoft\.DesktopVirtualization') { return 'AVD' }
    if ($srcText -match '/providers/Microsoft\.DevTestLab')            { return 'DTL' }
    'Unknown'
}
function Build-SignalJson($tenantId,$azEnv,$provHost,$channel) {
    $obj=[ordered]@{
        TenantId            = $tenantId
        AzEnvironment       = $azEnv
        ProvisionedHostname = $provHost
        Channel             = $channel
        TimestampUtc        = [DateTime]::UtcNow.ToString('o')
    }
    $obj | ConvertTo-Json -Depth 4 -Compress
}
function Derive-KeyBytes16($compute,$tagsMap) {
    if (-not $compute) { return $null }
    $az    = if ($compute.azEnvironment)      { [string]$compute.azEnvironment }      else { '' }
    $sub   = if ($compute.subscriptionId)     { [string]$compute.subscriptionId }     else { '' }
    $rg    = if ($compute.resourceGroupName)  { [string]$compute.resourceGroupName }  else { '' }
    $vmid  = if ($compute.vmId)               { [string]$compute.vmId }               else { '' }
    $offer = if ($compute.offer)              { [string]$compute.offer }              else { '' }
    $ten   = if ($tagsMap.ContainsKey('ms.inv.v0.backedby.origin.tenantid')) { [string]$tagsMap['ms.inv.v0.backedby.origin.tenantid'] } else { '' }
    $canon = ($az.ToLower()+'|'+$sub.ToLower()+'|'+$rg.ToLower()+'|'+$vmid.ToLower()+'|'+$offer.ToLower()+'|'+$ten.ToLower())
    $sha = [Security.Cryptography.SHA256]::Create()
    try { $digest = $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($canon)) } finally { $sha.Dispose() }
    return $digest[0..15] # 16-byte key for ConvertFrom/To-SecureString -Key
}
function Protect-WithKey([string]$plain,[byte[]]$key) {
    try {
        $sec = ConvertTo-SecureString -String $plain -AsPlainText -Force
        return (ConvertFrom-SecureString -SecureString $sec -Key $key)
    } catch { return $null }
}
function Protect-DPAPI([string]$plain) {
    try {
        $sec = ConvertTo-SecureString -String $plain -AsPlainText -Force
        return ($sec | ConvertFrom-SecureString)
    } catch { return $null }
}
# --------------------------------------------

# -------- Gather live signals --------
$compute   = Get-ImdsCompute
$sys       = Get-SystemInfo
$azEnv     = $null
$provHost  = $null
$tenantId  = $null
$channel   = 'Unknown'
$tagsMap   = @{}
if ($compute) {
    $azEnv    = $compute.azEnvironment
    if ($compute.osProfile -and $compute.osProfile.computerName) { $provHost = [string]$compute.osProfile.computerName }
    $tagsMap  = Get-TagsMap -compute $compute
    if ($tagsMap.ContainsKey('ms.inv.v0.backedby.origin.tenantid')) { $tenantId = $tagsMap['ms.inv.v0.backedby.origin.tenantid'] }
    $channel  = Derive-Channel -compute $compute
}
$liveHost  = $env:COMPUTERNAME

# -------- Self-heal baseline (uses per-VM key when possible) --------
if ($compute) {
    $signal   = Build-SignalJson -tenantId $tenantId -azEnv $azEnv -provHost $provHost -channel $channel
    $signalB64= [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($signal))
    $keyBytes = Derive-KeyBytes16 -compute $compute -tagsMap $tagsMap

    if (-not (Test-Path -LiteralPath $RegPath)) { New-Item -Path $RegPath -Force | Out-Null }

    $needWrite = $true
    try {
        $cur = Get-ItemProperty -Path $RegPath -ErrorAction Stop
        if ($cur.$Name_SignalB64 -and ($cur.$Name_SignalB64 -eq $signalB64)) { $needWrite = $false }
    } catch {}

    if ($needWrite) {
        $protV2  = $null
        $chanV2  = $null
        if ($keyBytes -and $keyBytes.Length -eq 16) {
            $protV2 = Protect-WithKey -plain $signal -key $keyBytes
            $chanV2 = Protect-WithKey -plain $channel -key $keyBytes
        }
        # Always store SignalB64 for deterministic compare; store v2 when available; also keep DPAPI fallback fields for legacy readers.
        New-ItemProperty -Path $RegPath -Name $Name_SignalB64    -Value $signalB64 -PropertyType String -Force | Out-Null
        if ($protV2)  { New-ItemProperty -Path $RegPath -Name $Name_SignalProtV2  -Value $protV2  -PropertyType String -Force | Out-Null }
        if ($chanV2)  { New-ItemProperty -Path $RegPath -Name $Name_ChannelProtV2 -Value $chanV2  -PropertyType String -Force | Out-Null }
        # DPAPI legacy fallbacks (don’t depend on them for comparison)
        $dpSig = Protect-DPAPI -plain $signal
        $dpCha = Protect-DPAPI -plain $channel
        if ($dpSig) { New-ItemProperty -Path $RegPath -Name $Name_SignalProt  -Value $dpSig -PropertyType String -Force | Out-Null }
        if ($dpCha) { New-ItemProperty -Path $RegPath -Name $Name_ChannelProt -Value $dpCha -PropertyType String -Force | Out-Null }
        New-ItemProperty -Path $RegPath -Name $Name_Version -Value $SchemaVersion -PropertyType String -Force | Out-Null
    }
}

# -------- Evaluate booleans (IMDS gating) --------
$AzEnvOk = $false
if (-not [string]::IsNullOrEmpty($azEnv)) { $AzEnvOk = ($azEnv -eq 'AzurePublicCloud') }

# Gate the rest: when not in AzurePublicCloud (or IMDS absent), they default to TRUE
$TenantIdOk                  = $true
$SystemManufacturerOk        = $true
$SystemProductNamePrefixOk   = $true
$HostnameMatchesProvisioned  = $true

if ($AzEnvOk) {
    $TenantIdOk           = ($tenantId -eq $ExpectedTenantId)
    $SystemManufacturerOk = ($sys.Manufacturer -eq $ExpectedManufacturer)

    if     ($channel -eq 'W365')   { $SystemProductNamePrefixOk = ($sys.Product -like "$Prefix_W365*") }
    elseif ($channel -eq 'DevBox') { $SystemProductNamePrefixOk = ($sys.Product -like "$Prefix_DevBox*") }
    elseif ($channel -in @('AVD','DTL')) { $SystemProductNamePrefixOk = $true }  # omitted for these
    else { $SystemProductNamePrefixOk = $true }

    if (-not [string]::IsNullOrEmpty($provHost) -and -not [string]::IsNullOrEmpty($liveHost)) {
        $HostnameMatchesProvisioned = ([string]::Equals($liveHost,$provHost,[StringComparison]::OrdinalIgnoreCase))
    } else {
        $HostnameMatchesProvisioned = $true
    }
}

# -------- Emit ONLY the JSON expected by your compliance policy --------
[ordered]@{
    AzEnvOk                    = [bool]$AzEnvOk
    TenantIdOk                 = [bool]$TenantIdOk
    SystemManufacturerOk       = [bool]$SystemManufacturerOk
    SystemProductNamePrefixOk  = [bool]$SystemProductNamePrefixOk
    HostnameMatchesProvisioned = [bool]$HostnameMatchesProvisioned
} | ConvertTo-Json -Compress | Write-Output
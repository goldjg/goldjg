# Detection Script: SMDI_CloudPC_ComplianceDetect.ps1
# Emits JSON for Intune Custom Compliance rules.

# -- BEGIN Force-64bit Bootstrap --
if ($env:PROCESSOR_ARCHITEW6432 -and -not $env:CI_RUN_IN_64BIT) {
    # Mark to prevent recursion
    $env:CI_RUN_IN_64BIT = '1'
    $argList = $MyInvocation.UnboundArguments | ForEach-Object {
        if ($_ -is [string] -and $_ -contains ' ') { "`"$_`"" } else { $_ }
    }
    $ps64 = Join-Path $env:windir 'SysNative\WindowsPowerShell\v1.0\powershell.exe'
    & $ps64 -NoProfile -ExecutionPolicy Bypass -File $MyInvocation.MyCommand.Path @argList
    Exit $LASTEXITCODE
}
# -- END Force-64bit Bootstrap --

$ErrorActionPreference = 'SilentlyContinue'

function DoubleBase64([string]$text) {
    try {
        $b1 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($text))
        $b2 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($b1))
        return $b2
    } catch {
        return $null
    }
}

function DoubleDecode([string]$b64b64) {
    try {
        $once = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($b64b64))
        [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($once))
    } catch {
        return $null
    }
}

# Defaults
$azEnv = $null
$tenantId = $null
$sysMfr = $null
$sysProd = $null

# 1) SystemInformation registry
try {
    $si = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SystemInformation' -ErrorAction Stop
    $sysMfr = $si.SystemManufacturer
    $sysProd = $si.SystemProductName
} catch {}

# 2) IMDS
try {
    $imds = Invoke-RestMethod -Headers @{ Metadata = 'true' } -Uri 'http://169.254.169.254/metadata/instance?api-version=2021-02-01' -TimeoutSec 2
    $azEnv = $imds.compute.azEnvironment
    $tenantId = ($imds.compute.tagsList | Where-Object { $_.name -like '*tenantid*' } | Select-Object -First 1).value
} catch {}

# 3) Read expected values (double-encoded) from HKLM:\SOFTWARE\SMDI
$baseKey = 'HKLM:\SOFTWARE\SMDI'
$expEncSM = $null
$expEncSPN = $null
try {
    $props = Get-ItemProperty -Path $baseKey -ErrorAction Stop
    $expEncSM = $props.SM
    $expEncSPN = $props.SPN
} catch {}

# 4) Double-encode live values for comparison (kept for SM exact-compare & diagnostics)
$liveEncSM  = if ($sysMfr)  { DoubleBase64 $sysMfr }  else { $null }
$liveEncSPN = if ($sysProd) { DoubleBase64 $sysProd } else { $null }

# 5) Evaluate the four immediate-fail conditions
$AzEnvOk  = ($azEnv -eq 'AzurePublicCloud')
$TenantOk = ($tenantId -eq 'd980314b-cb2f-44e3-9ce7-06d7361ab382')

# SystemManufacturer exact match, using double-encoded comparison via stored expected (unchanged)
$SysMfrOk = $false
if ($expEncSM -and $liveEncSM) {
    $SysMfrOk = ($liveEncSM -eq $expEncSM)
}

# SystemProductName "starts with Cloud PC" — FIXED:
# decode the stored expected SPN, then compare plain-text prefix with live SystemProductName
$SysProdPrefixOk = $false
$expSPNPlain = if ($expEncSPN) { DoubleDecode $expEncSPN } else { $null }
if ($expSPNPlain -and $sysProd) {
    $SysProdPrefixOk = $sysProd.StartsWith($expSPNPlain, [StringComparison]::Ordinal)
}

# Optional: include raw (sanitized) context to help troubleshooting
$result = [ordered]@{
    AzEnvOk                   = [bool]$AzEnvOk
    TenantIdOk                = [bool]$TenantOk
    SystemManufacturerOk      = [bool]$SysMfrOk
    SystemProductNamePrefixOk = [bool]$SysProdPrefixOk

    # Helpful diag (not used by rules)
    Observed = @{
        azEnvironment        = $azEnv
        tenantid             = $tenantId
        SystemManufacturer   = $sysMfr
        SystemProductName    = $sysProd
        LiveEnc_SM_IsNull    = [bool]([string]::IsNullOrEmpty($liveEncSM))
        LiveEnc_SPN_IsNull   = [bool]([string]::IsNullOrEmpty($liveEncSPN))
        ExpEnc_SM_IsNull     = [bool]([string]::IsNullOrEmpty($expEncSM))
        ExpEnc_SPN_IsNull    = [bool]([string]::IsNullOrEmpty($expEncSPN))
    }
}

$result | ConvertTo-Json -Compress -Depth 6 | Write-Output

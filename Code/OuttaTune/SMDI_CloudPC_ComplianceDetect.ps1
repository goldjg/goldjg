# ISDF_ComplianceDetect.ps1
# Intune Custom Compliance detection script
# Supports v1 (double base64) and v2 (DPAPI w/ IMDS entropy) registry entries
# Will pass compliance if EITHER set is present and matches expected

# --- 64-bit bootstrap ---
if ($env:PROCESSOR_ARCHITEW6432 -and -not $env:CI_RUN_IN_64BIT) {
    $env:CI_RUN_IN_64BIT='1'
    & "$env:WINDIR\SysNative\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath @args
    exit $LASTEXITCODE
}
$ErrorActionPreference = 'Stop'

# --- expected values ---
$expectedSystemManufacturer   = 'Microsoft Corporation'
$expectedSystemProductNamePre = 'Cloud PC'

# --- helpers ---
function Get-IMDS {
    for ($i=0; $i -lt 3; $i++) {
        try {
            return Invoke-RestMethod -Headers @{Metadata='true'} -Uri 'http://169.254.169.254/metadata/instance?api-version=2021-02-01' -TimeoutSec 3
        } catch {
            Start-Sleep -Seconds (2 * ($i+1))
        }
    }
    return $null
}

function Get-EntropyBytes($compute){
    if (-not $compute) { return $null }
    $parts = @(
        $compute.azEnvironment,
        $compute.subscriptionId,
        $compute.resourceGroupName,
        $compute.vmId,
        $compute.location,
        $compute.sku,
        $compute.osType
    ) -join '|'
    $b = [Text.Encoding]::UTF8.GetBytes($parts)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { $sha.ComputeHash($b) } finally { $sha.Dispose() }
}

function Unprotect-Bytes([byte[]]$cipher,[byte[]]$entropy){
    try {
        $plainBytes = [Security.Cryptography.ProtectedData]::Unprotect($cipher,$entropy,[Security.Cryptography.DataProtectionScope]::LocalMachine)
        [Text.Encoding]::UTF8.GetString($plainBytes)
    } catch {
        $null
    }
}

function FromDoubleBase64([string]$t){
    try {
        $b1 = [System.Convert]::FromBase64String($t)
        $s1 = [System.Text.Encoding]::UTF8.GetString($b1)
        $b2 = [System.Convert]::FromBase64String($s1)
        [System.Text.Encoding]::UTF8.GetString($b2)
    } catch {
        $null
    }
}

# --- detection logic ---
$regPath = 'HKLM:\SOFTWARE\SMDI'
$props   = $null
if (Test-Path $regPath) {
    $props = Get-ItemProperty -Path $regPath
}

# Get actual current values from Win32_ComputerSystem
$actualSM  = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
$actualSPN = (Get-CimInstance -ClassName Win32_ComputerSystem).Model

# Flags
$HasV2 = $props -and ($props.PSObject.Properties.Name -contains 'SM_v2') -and ($props.SM_v2 -is [byte[]]) -and ($props.PSObject.Properties.Name -contains 'SPN_v2') -and ($props.SPN_v2 -is [byte[]])
$HasV1 = $props -and ($props.PSObject.Properties.Name -contains 'SM') -and ($props.PSObject.Properties.Name -contains 'SPN') -and -not [string]::IsNullOrEmpty($props.SM) -and -not [string]::IsNullOrEmpty($props.SPN)
$ExpectedValuesPresent = $HasV2 -or $HasV1

# Prepare result object
$result = @{
    SystemManufacturerOk        = $false
    SystemProductNamePrefixOk   = $false
    ExpectedValuesPresent       = $ExpectedValuesPresent
    Observed_Manufacturer       = $actualSM
    Observed_ProductName        = $actualSPN
    DetectedSchemaVersion       = $props.SCHEMA_VERSION
    DetectionPath               = $regPath
    UsedV2                      = $false
    DebugNote                   = $null
}

if (-not $ExpectedValuesPresent) {
    $result.DebugNote = "Neither v1 nor v2 registry entries present."
    $result | ConvertTo-Json -Compress
    exit 1
}

if ($HasV2) {
    $result.UsedV2 = $true
    $imds = Get-IMDS
    $entropy = Get-EntropyBytes $imds.compute
    if ($null -eq $entropy) {
        $result.DebugNote = "V2 present but IMDS entropy unavailable."
        $result | ConvertTo-Json -Compress
        exit 1
    }
    $decodedSM  = Unprotect-Bytes $props.SM_v2  $entropy
    $decodedSPN = Unprotect-Bytes $props.SPN_v2 $entropy
    $result.DebugNote = "Decoded via v2."

} elseif ($HasV1) {
    $decodedSM  = FromDoubleBase64 $props.SM
    $decodedSPN = FromDoubleBase64 $props.SPN
    $result.DebugNote = "Decoded via v1."
}

# Compare decoded vs expected
if ($decodedSM -eq $expectedSystemManufacturer) {
    $result.SystemManufacturerOk = $true
}
if ($decodedSPN -and $decodedSPN.StartsWith($expectedSystemProductNamePre)) {
    $result.SystemProductNamePrefixOk = $true
}

# Return JSON result
$result | ConvertTo-Json -Compress

# Set exit code based on compliance
if ($result.SystemManufacturerOk -and $result.SystemProductNamePrefixOk) {
    exit 0
} else {
    exit 1
}
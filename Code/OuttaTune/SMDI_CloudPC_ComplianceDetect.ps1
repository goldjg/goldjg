# SMDI_CloudPC_ComplianceDetect_v2.ps1
# Emits JSON for custom compliance; prefers v2 DPAPI blobs (REG_BINARY) and falls back to v1 if present.
# Tenant/Manufacturer/Product checks apply ONLY when azEnvironment == AzurePublicCloud.

# --- Force 64-bit host ---
if ($env:PROCESSOR_ARCHITEW6432 -and -not $env:CI_RUN_IN_64BIT) {
  $env:CI_RUN_IN_64BIT='1'
  $ps64 = Join-Path $env:WINDIR 'SysNative\WindowsPowerShell\v1.0\powershell.exe'
  & $ps64 -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath @args
  exit $LASTEXITCODE
}
$ErrorActionPreference = 'SilentlyContinue'

# ===== helpers =====
function DoubleDecode([string]$b64b64){
  try {
    $once=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($b64b64))
    [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($once))
  } catch { $null }
}
function Get-IMDS {
  try { Invoke-RestMethod -Headers @{Metadata='true'} -Uri 'http://169.254.169.254/metadata/instance?api-version=2021-02-01' -TimeoutSec 2 }
  catch { $null }
}
function Get-EntropyBytes($compute){
  if (-not $compute) { return $null }
  $parts = @(
    $compute.azEnvironment, $compute.subscriptionId, $compute.resourceGroupName,
    $compute.vmId, $compute.location, $compute.sku, $compute.osType
  ) -join '|'
  $bytes=[Text.Encoding]::UTF8.GetBytes($parts)
  $sha=[Security.Cryptography.SHA256]::Create()
  try { $sha.ComputeHash($bytes) } finally { $sha.Dispose() }
}
function Unprotect-Bytes([byte[]]$cipher,[byte[]]$entropy){
  try {
    $plain=[Security.Cryptography.ProtectedData]::Unprotect($cipher,$entropy,[Security.Cryptography.DataProtectionScope]::LocalMachine)
    [Text.Encoding]::UTF8.GetString($plain)
  } catch { $null }
}
function Sha256Hex([string]$text){
  $sha=[Security.Cryptography.SHA256]::Create()
  try { ($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($text))|%{ $_.ToString('x2') })-join'' } finally { $sha.Dispose() }
}

# ===== live values =====
$sysMfr=$null; $sysProd=$null
try {
  $si = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\SystemInformation' -ErrorAction Stop
  $sysMfr  = $si.SystemManufacturer
  $sysProd = $si.SystemProductName
} catch {}

$imds    = Get-IMDS
$compute = if ($imds) { $imds.compute } else { $null }
$azEnv   = if ($compute) { $compute.azEnvironment } else { $null }
$tenantId = if ($compute) { ($compute.tagsList | ? { $_.name -like '*tenantid*' } | select -First 1).value } else { $null }

# ===== expected values =====
$props=$null
try { $props = Get-ItemProperty 'HKLM:\SOFTWARE\SMDI' -ErrorAction Stop } catch {}

$expectedSMPlain  = $null
$expectedSPNPlain = $null
$computeOk = $true

if ($props) {
  # Prefer v2 binary blobs
  if ($props.SM_v2 -is [byte[]] -and $props.SPN_v2 -is [byte[]] -and $compute) {
    $entropy = Get-EntropyBytes $compute
    $expectedSMPlain  = Unprotect-Bytes $props.SM_v2  $entropy
    $expectedSPNPlain = Unprotect-Bytes $props.SPN_v2 $entropy
    $entropy=$null
  }
  # Fallback to v1 double-Base64 if v2 missing
  if (-not $expectedSMPlain  -and $props.SM)  { $expectedSMPlain  = DoubleDecode $props.SM }
  if (-not $expectedSPNPlain -and $props.SPN) { $expectedSPNPlain = DoubleDecode $props.SPN }

  if ($props.'IMDS_Compute_SHA_v2' -and $compute) {
    $computeOk = ($props.'IMDS_Compute_SHA_v2' -eq (Sha256Hex (($compute | ConvertTo-Json -Depth 12))))
  }
}

# ===== logic (gated) =====
$AzEnvOk = ($azEnv -eq 'AzurePublicCloud')

if ($AzEnvOk) {
  $TenantIdOk = ($tenantId -eq 'd980314b-cb2f-44e3-9ce7-06d7361ab382')
  $SystemManufacturerOk      = ($expectedSMPlain  -and $sysMfr  -and ($sysMfr -eq $expectedSMPlain))
  $SystemProductNamePrefixOk = ($expectedSPNPlain -and $sysProd -and $sysProd.StartsWith($expectedSPNPlain, [StringComparison]::Ordinal))
} else {
  # Not AzurePublicCloud => ignore tenant/manufacturer/product
  $TenantIdOk = $true
  $SystemManufacturerOk = $true
  $SystemProductNamePrefixOk = $true
}

# ===== output =====
[ordered]@{
  AzEnvOk                   = [bool]$AzEnvOk
  TenantIdOk                = [bool]$TenantIdOk
  SystemManufacturerOk      = [bool]$SystemManufacturerOk
  SystemProductNamePrefixOk = [bool]$SystemProductNamePrefixOk
  ComputeMetadataOk         = [bool]$computeOk
  Observed = @{
    azEnvironment      = $azEnv
    tenantid           = $tenantId
    SystemManufacturer = $sysMfr
    SystemProductName  = $sysProd
    UsingV2            = [bool]($props -and ($props.SM_v2 -is [byte[]]) -and ($props.SPN_v2 -is [byte[]]))
  }
} | ConvertTo-Json -Compress -Depth 6 | Write-Output

# zero plaintext
$expectedSMPlain=$null; $expectedSPNPlain=$null; [GC]::Collect()
exit 0
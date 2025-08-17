# ISDFRemediate.ps1
# Writes expected values into HKLM:\SOFTWARE\ISDF using SecureString + -Key (per-machine entropy).
# Falls back to double-Base64 only if SecureString -Key isn't available/supported.
# Idempotent. 64-bit forced.

# -------- Force 64-bit ----------
if ($env:PROCESSOR_ARCHITEW6432 -and -not $env:CI_RUN_IN_64BIT) {
  $env:CI_RUN_IN_64BIT='1'
  & "$env:WINDIR\SysNative\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath @args
  exit $LASTEXITCODE
}
# ---------------------------------
$ErrorActionPreference = 'Stop'

# Constants
$ExpectedManufacturer = 'Microsoft Corporation'
$RegPath = 'HKLM:\SOFTWARE\ISDF'

# Helpers
function Get-IMDSCompute {
  for ($i=0; $i -lt 3; $i++) {
    try {
      return Invoke-RestMethod -Headers @{ Metadata='true' } -Uri 'http://169.254.169.254/metadata/instance/compute?api-version=2021-02-01' -TimeoutSec 3
    } catch { Start-Sleep -Seconds (2 * ($i+1)) }
  }
  return $null
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

# >>> Fixed classification <<<
function Get-Channel($compute) {
  $src = Parse-TagValue -compute $compute -needle 'origin.sourcearmid.0'
  if (-not $src) { return 'Unknown' }

  $sid = $null
  if ($src -match '/subscriptions/([0-9a-fA-F-]{36})') { $sid = $matches[1] }
  $hasProviders = ($src -match '/providers/')
  $isZeroSid = $false
  if ($sid) { $isZeroSid = (($sid -replace '-', '') -match '^0{32}$') }

  if ($isZeroSid -and -not $hasProviders) { return 'W365' }
  if ($src -match 'Providers/Microsoft\.DevCenter')            { return 'DevBox' }
  if ($src -match 'Providers/Microsoft\.DesktopVirtualization'){ return 'AVD' }
  if ($src -match 'Providers/Microsoft\.DevTestLab')           { return 'DevTestLab' }
  return 'Unknown'
}
# -----------------------------

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
function DoubleB64([string]$s) {
  $b1=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($s))
  [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($b1))
}

# Ensure key exists
if (-not (Test-Path $RegPath)) { New-Item -Path $RegPath -Force | Out-Null }

# IMDS + channel
$compute  = Get-IMDSCompute
if (-not $compute) { exit 0 }  # not in Azure fabric or IMDS blocked; skip stamping
$channel  = Get-Channel $compute
$provName = if ($compute.PSObject.Properties.Name -contains 'osProfile' -and $compute.osProfile) { $compute.osProfile.computerName } else { $null }

# Channel-specific SPN prefix
$ExpectedSpnPrefix = switch ($channel) {
  'DevBox'    { 'Microsoft Dev Box' }
  'AVD'       { '' }              # SPN not enforced (hostname check is used instead)
  'DevTestLab'{ '' }
  'W365'      { 'Cloud PC' }
  default     { 'Cloud PC' }      # conservative default
}

# Derive per-machine key
$keyBytes = Derive-KeyBytes16 $compute
$wroteV2 = $false
if ($keyBytes -and $keyBytes.Length -eq 16) {
  try {
    $encSM   = Protect-Text-WithKey $ExpectedManufacturer $keyBytes
    $encSPN  = if ($ExpectedSpnPrefix) { Protect-Text-WithKey $ExpectedSpnPrefix $keyBytes } else { $null }
    $encHost = if ($provName) { Protect-Text-WithKey $provName $keyBytes } else { $null }

    New-ItemProperty -Path $RegPath -Name 'SM_v2'      -PropertyType String -Value $encSM   -Force | Out-Null
    if ($encSPN) { New-ItemProperty -Path $RegPath -Name 'SPN_v2'     -PropertyType String -Value $encSPN  -Force | Out-Null }
    if ($encHost){ New-ItemProperty -Path $RegPath -Name 'ProvName_v2' -PropertyType String -Value $encHost -Force | Out-Null }
    New-ItemProperty -Path $RegPath -Name 'SCHEMA_VERSION' -PropertyType String -Value '2' -Force | Out-Null
    New-ItemProperty -Path $RegPath -Name 'Channel'        -PropertyType String -Value $channel -Force | Out-Null

    $wroteV2 = $true
  } catch { $wroteV2 = $false }
}

if (-not $wroteV2) {
  # Fallback only if SecureString -Key wasn't usable
  New-ItemProperty -Path $RegPath -Name 'SM'  -PropertyType String -Value (DoubleB64 $ExpectedManufacturer) -Force | Out-Null
  if ($ExpectedSpnPrefix) {
    New-ItemProperty -Path $RegPath -Name 'SPN' -PropertyType String -Value (DoubleB64 $ExpectedSpnPrefix) -Force | Out-Null
  }
  if ($provName) {
    New-ItemProperty -Path $RegPath -Name 'ProvName' -PropertyType String -Value (DoubleB64 $provName) -Force | Out-Null
  }
}

exit 0
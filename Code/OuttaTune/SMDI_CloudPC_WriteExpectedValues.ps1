# SMDI_CloudPC_WriteExpectedValues_v2_1.ps1
# Writes v2 DPAPI(LocalMachine)+IMDS-entropy blobs as REG_BINARY.
# Removes v1 only after v2 readback succeeds. Forces 64-bit.

# --- 64-bit bootstrap ---
if ($env:PROCESSOR_ARCHITEW6432 -and -not $env:CI_RUN_IN_64BIT) {
  $env:CI_RUN_IN_64BIT='1'
  & "$env:WINDIR\SysNative\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath @args
  exit $LASTEXITCODE
}
$ErrorActionPreference = 'Stop'

# --- helpers ---
function Get-IMDS {
  for ($i=0; $i -lt 3; $i++) {
    try {
      return Invoke-RestMethod -Headers @{Metadata='true'} -Uri 'http://169.254.169.254/metadata/instance?api-version=2021-02-01' -TimeoutSec 3
    } catch { Start-Sleep -Seconds (2 * ($i+1)) }
  }
  return $null
}
function Get-EntropyBytes($compute){
  if (-not $compute) { return $null }
  $parts = @(
    $compute.azEnvironment, $compute.subscriptionId, $compute.resourceGroupName,
    $compute.vmId, $compute.location, $compute.sku, $compute.osType
  ) -join '|'
  $b = [Text.Encoding]::UTF8.GetBytes($parts)
  $sha=[Security.Cryptography.SHA256]::Create()
  try { $sha.ComputeHash($b) } finally { $sha.Dispose() }
}
function Protect-String([string]$plaintext,[byte[]]$entropy){
  $bytes=[Text.Encoding]::UTF8.GetBytes($plaintext)
  [Security.Cryptography.ProtectedData]::Protect($bytes,$entropy,[Security.Cryptography.DataProtectionScope]::LocalMachine)
}
function DoubleBase64([string]$t){
  $b1=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($t))
  [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($b1))
}

# --- expected (edit if ever needed) ---
$expectedSM  = 'Microsoft Corporation'
$expectedSPN = 'Cloud PC'

# --- ensure 64-bit hive key exists ---
$reg = 'HKLM:\SOFTWARE\SMDI'
if (-not (Test-Path $reg)) { New-Item -Path $reg -Force | Out-Null }

# --- IMDS + entropy (with guard) ---
$imds = Get-IMDS
$compute = $imds?.compute
$entropy = Get-EntropyBytes $compute

# If we can't get entropy, DO NOT attempt v2; keep/refresh v1 so detection still works
$canWriteV2 = ($null -ne $entropy -and $entropy.Length -gt 0)

# --- always (re)write v1 as safety net unless we prove v2 works ---
New-ItemProperty -Path $reg -Name 'SM'  -PropertyType String -Value (DoubleBase64 $expectedSM)  -Force | Out-Null
New-ItemProperty -Path $reg -Name 'SPN' -PropertyType String -Value (DoubleBase64 $expectedSPN) -Force | Out-Null

if ($canWriteV2) {
  try {
    [byte[]]$sm_v2  = Protect-String $expectedSM  $entropy
    [byte[]]$spn_v2 = Protect-String $expectedSPN $entropy

    New-ItemProperty -Path $reg -Name 'SM_v2'  -PropertyType Binary -Value $sm_v2  -Force | Out-Null
    New-ItemProperty -Path $reg -Name 'SPN_v2' -PropertyType Binary -Value $spn_v2 -Force | Out-Null
    New-ItemProperty -Path $reg -Name 'SCHEMA_VERSION' -PropertyType String -Value '2' -Force | Out-Null

    # verify readback (type + non-empty)
    $p = Get-ItemProperty -Path $reg -ErrorAction Stop
    $v2ok = ($p.SM_v2 -is [byte[]] -and $p.SPN_v2 -is [byte[]] -and $p.SM_v2.Length -gt 0 -and $p.SPN_v2.Length -gt 0)

    if ($v2ok) {
      # only now remove v1
      Remove-ItemProperty -Path $reg -Name 'SM','SPN' -ErrorAction SilentlyContinue
    } else {
      Write-Host 'SMDI: v2 verification failed; keeping v1.'
    }
  } catch {
    Write-Host "SMDI: v2 write failed ($($_.Exception.Message)); keeping v1."
  }
} else {
  Write-Host 'SMDI: IMDS/entropy unavailable; wrote/kept v1 only.'
}

exit 0
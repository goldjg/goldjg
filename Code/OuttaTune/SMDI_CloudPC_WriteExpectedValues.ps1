# SMDI_PR_Remediate_v2.ps1
# Purpose: Write v2 DPAPI-protected SM/SPN and compressed IMDS compute blob to HKLM:\SOFTWARE\SMDI (64-bit hive).
# Hardened: REG_BINARY, tight ACLs, no entropy breadcrumbs, optional v1 removal.

param(
  [bool]$RemoveV1AfterWrite = $true
)

# --- Force 64-bit host ---
if ($env:PROCESSOR_ARCHITEW6432 -and -not $env:CI_RUN_IN_64BIT) {
  $env:CI_RUN_IN_64BIT='1'
  & "$env:WINDIR\SysNative\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath @args
  exit $LASTEXITCODE
}
$ErrorActionPreference = 'Stop'

# ===== helpers =====
function DoubleBase64([string]$t){
  $b1=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($t))
  [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($b1))
}
function Get-IMDS {
  Invoke-RestMethod -Headers @{Metadata='true'} -Uri 'http://169.254.169.254/metadata/instance?api-version=2021-02-01' -TimeoutSec 3
}
function Get-EntropyBytes($compute){
  # Choose stable, per-VM fields; not stored anywhere.
  $parts = @(
    $compute.azEnvironment, $compute.subscriptionId, $compute.resourceGroupName,
    $compute.vmId, $compute.location, $compute.sku, $compute.osType
  ) -join '|'
  $bytes = [Text.Encoding]::UTF8.GetBytes($parts)
  $sha = [Security.Cryptography.SHA256]::Create()
  try { $sha.ComputeHash($bytes) } finally { $sha.Dispose() }
}
function Protect-String([string]$plaintext, [byte[]]$entropy){
  $bytes  = [Text.Encoding]::UTF8.GetBytes($plaintext)
  $cipher = [Security.Cryptography.ProtectedData]::Protect($bytes, $entropy, [Security.Cryptography.DataProtectionScope]::LocalMachine)
  $cipher # return raw bytes
}
function Compress-ToGzipBase64([string]$text){
  $in  = [Text.Encoding]::UTF8.GetBytes($text)
  $ms  = New-Object System.IO.MemoryStream
  $gz  = New-Object System.IO.Compression.GzipStream($ms, [IO.Compression.CompressionMode]::Compress)
  $gz.Write($in,0,$in.Length); $gz.Close()
  [Convert]::ToBase64String($ms.ToArray())
}
function Sha256Hex([string]$text){
  $sha=[Security.Cryptography.SHA256]::Create()
  try { ($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($text))|%{ $_.ToString('x2') })-join'' } finally { $sha.Dispose() }
}

# ===== inputs =====
$expectedSM  = 'Microsoft Corporation'
$expectedSPN = 'Cloud PC'

# ===== IMDS / entropy =====
$imds    = Get-IMDS
$compute = $imds.compute
$entropy = Get-EntropyBytes $compute

# ===== protect values & capture compute =====
[byte[]]$sm_v2_bytes  = Protect-String $expectedSM  $entropy
[byte[]]$spn_v2_bytes = Protect-String $expectedSPN $entropy

$computeJson   = ($compute | ConvertTo-Json -Depth 12)
$computeB64Gz  = Compress-ToGzipBase64 $computeJson
$computeSha256 = Sha256Hex $computeJson

# ===== write registry (64-bit hive) =====
$reg64 = 'HKLM:\SOFTWARE\SMDI'
if (-not (Test-Path $reg64)) { New-Item -Path $reg64 -Force | Out-Null }

# v2 binary blobs
New-ItemProperty -Path $reg64 -Name 'SM_v2'  -PropertyType Binary -Value $sm_v2_bytes  -Force | Out-Null
New-ItemProperty -Path $reg64 -Name 'SPN_v2' -PropertyType Binary -Value $spn_v2_bytes -Force | Out-Null

# IMDS snapshot (string) + hash
New-ItemProperty -Path $reg64 -Name 'IMDS_Compute_v2'     -PropertyType String -Value $computeB64Gz  -Force | Out-Null
New-ItemProperty -Path $reg64 -Name 'IMDS_Compute_SHA_v2' -PropertyType String -Value $computeSha256 -Force | Out-Null
New-ItemProperty -Path $reg64 -Name 'SCHEMA_VERSION'      -PropertyType String -Value '2'            -Force | Out-Null

# Back-compat v1 (double-Base64) -- optional removal
New-ItemProperty -Path $reg64 -Name 'SM'  -PropertyType String -Value (DoubleBase64 $expectedSM)  -Force | Out-Null
New-ItemProperty -Path $reg64 -Name 'SPN' -PropertyType String -Value (DoubleBase64 $expectedSPN) -Force | Out-Null
if ($RemoveV1AfterWrite) {
  Remove-ItemProperty -Path $reg64 -Name 'SM','SPN' -ErrorAction SilentlyContinue
}

# Remove any 32-bit/wow6432 leftovers
$reg32 = 'HKLM:\SOFTWARE\WOW6432Node\SMDI'
if (Test-Path $reg32) { try { Remove-Item -Path $reg32 -Recurse -Force } catch {} }

# Tighten ACLs: SYSTEM + Administrators full control
try {
  $rk = (Get-Item $reg64).Handle # Opens with default rights; reopen via .NET to set ACLs
  $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SOFTWARE\SMDI', 'ReadWriteSubTree', [System.Security.AccessControl.RegistryRights]::ChangePermissions)
  $acl = New-Object System.Security.AccessControl.RegistrySecurity
  $system = New-Object System.Security.Principal.NTAccount('SYSTEM')
  $admins = New-Object System.Security.Principal.NTAccount('BUILTIN','Administrators')
  $ruleSys = New-Object System.Security.AccessControl.RegistryAccessRule($system,'FullControl','ContainerInherit,ObjectInherit','None','Allow')
  $ruleAdm = New-Object System.Security.AccessControl.RegistryAccessRule($admins,'FullControl','ContainerInherit,ObjectInherit','None','Allow')
  $acl.SetOwner($admins); $acl.SetAccessRule($ruleSys); $acl.AddAccessRule($ruleAdm)
  $key.SetAccessControl($acl); $key.Close()
} catch {}

# Zero sensitive variables
[Array]::Clear($sm_v2_bytes,0,$sm_v2_bytes.Length)
[Array]::Clear($spn_v2_bytes,0,$spn_v2_bytes.Length)
$expectedSM=$null; $expectedSPN=$null; $entropy=$null; [GC]::Collect()

exit 0
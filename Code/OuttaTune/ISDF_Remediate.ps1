# ISDF_Remediate.ps1

# -------- Force 64-bit ----------
if ($env:PROCESSOR_ARCHITEW6432 -and -not $env:CI_RUN_IN_64BIT) {
  $env:CI_RUN_IN_64BIT='1'
  & "$env:WINDIR\SysNative\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath @args
  exit $LASTEXITCODE
}
# ---------------------------------

$ErrorActionPreference = 'Stop'

# === Config (expected plaintexts) ===
$ExpectedSystemManufacturer   = 'Microsoft Corporation'
$ExpectedSystemProductNamePre = 'Cloud PC'
$RegPath = 'HKLM:\SOFTWARE\ISDF'
# ====================================

function DoubleBase64([string]$t){
  $b1=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($t))
  [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($b1))
}

function Protect-Text([string]$plain){
  $sec  = ConvertTo-SecureString -String $plain -AsPlainText -Force
  # DPAPI (LocalMachine when running as SYSTEM in PR), returns a REG_SZ-safe blob
  $blob = $sec | ConvertFrom-SecureString
  $blob
}

function Unprotect-Text([string]$blob){
  try {
    $sec = ConvertTo-SecureString -String $blob
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
    try { [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
    finally { if ($ptr -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) } }
  } catch { $null }
}

# Ensure key exists
if (-not (Test-Path $RegPath)) { New-Item -Path $RegPath -Force | Out-Null }

# v1 (safety net)
New-ItemProperty -Path $RegPath -Name 'SM'  -PropertyType String -Value (DoubleBase64 $ExpectedSystemManufacturer)   -Force | Out-Null
New-ItemProperty -Path $RegPath -Name 'SPN' -PropertyType String -Value (DoubleBase64 $ExpectedSystemProductNamePre) -Force | Out-Null

# v2 write
$sm2  = Protect-Text $ExpectedSystemManufacturer
$spn2 = Protect-Text $ExpectedSystemProductNamePre
New-ItemProperty -Path $RegPath -Name 'SM_v2'  -PropertyType String -Value $sm2  -Force | Out-Null
New-ItemProperty -Path $RegPath -Name 'SPN_v2' -PropertyType String -Value $spn2 -Force | Out-Null
New-ItemProperty -Path $RegPath -Name 'SCHEMA_VERSION' -PropertyType String -Value '2' -Force | Out-Null

# Verify v2 by decrypting and comparing
$ok = $false
try {
  $p = Get-ItemProperty -Path $RegPath -ErrorAction Stop
  $decSM  = Unprotect-Text $p.SM_v2
  $decSPN = Unprotect-Text $p.SPN_v2
  if ($decSM -eq $ExpectedSystemManufacturer -and $decSPN -eq $ExpectedSystemProductNamePre) { $ok = $true }
} catch {}

# Remove v1 only if v2 verified
if ($ok) {
  Remove-ItemProperty -Path $RegPath -Name 'SM','SPN' -ErrorAction SilentlyContinue
}

exit 0
# Registers/repairs \Microsoft\ISDF\Watchdog to run every 15m using -EncodedCommand.
# The payload locates detect.ps1 by matching the first-line header you specified.

$taskName    = '\Microsoft\ISDF\Watchdog'
$intervalMin = 15
$ps64        = "$env:WINDIR\SysNative\WindowsPowerShell\v1.0\powershell.exe"

# --- Compact watchdog payload (PS 5.1-safe) ---
$payload = @'
$ErrorActionPreference='SilentlyContinue';$ProgressPreference='SilentlyContinue';
# 0) Always nudge device mgmt sync
schtasks /run /tn "\Microsoft\Intune\PushLaunch" | Out-Null;

# 1) Find the correct detect.ps1 by matching the first line
$root='C:\Windows\IMECache\HealthScripts';
$expected='# ISDF_Detect.ps1  -- single self-healing detection (PS 5.1 safe)';
$detect=$null;
if(Test-Path -LiteralPath $root){
 $dirs=Get-ChildItem -LiteralPath $root -Directory -EA SilentlyContinue | Sort-Object LastWriteTimeUtc -Descending;
 foreach($d in $dirs){
  $p=Join-Path $d.FullName 'detect.ps1';
  if(Test-Path -LiteralPath $p){
   $first=(Get-Content -LiteralPath $p -TotalCount 1 -EA SilentlyContinue);
   if($first -and ($first.Trim() -eq $expected)){ $detect=$p; break }
  }
 }
 # Fallback: if no header match found, use newest detect.ps1 (optional)
 if(-not $detect){
  $firstDir=$dirs | Select-Object -First 1;
  if($firstDir){ $tmp=Join-Path $firstDir.FullName 'detect.ps1'; if(Test-Path -LiteralPath $tmp){ $detect=$tmp } }
 }
}

if(-not $detect){ return }

# OPTIONAL: if you later stamp an expected hash in HKLM:\SOFTWARE\ISDF\ExpectedDetectHash (SHA256 hex),
# uncomment the block below to enforce it before running.
<# 
try{
 $h=(Get-ItemProperty -Path 'HKLM:\SOFTWARE\ISDF' -EA Stop).ExpectedDetectHash
 if($h){
   $fh=(Get-FileHash -LiteralPath $detect -Algorithm SHA256).Hash
   if(-not [string]::Equals($fh,$h,[System.StringComparison]::OrdinalIgnoreCase)){ return }
 }
}catch{}
#>

# 2) Run detect via 64-bit host and parse JSON
$out=& "$env:WINDIR\SysNative\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File $detect 2>$null;
if([string]::IsNullOrWhiteSpace($out)){ return }
try{ $o=$out|ConvertFrom-Json }catch{ return }

# 3) If any boolean false -> trigger IME compliance eval now
$keys='AzEnvOk','TenantIdOk','SystemManufacturerOk','SystemProductNamePrefixOk','HostnameMatchesProvisioned';
$vals=@(); foreach($k in $keys){ if($o.PSObject.Properties[$k]){ $vals+=[bool]$o.$k } }
if(($vals.Count -gt 0) -and ($vals -contains $false)){
  try{ Start-Process 'intunemanagementextension://synccompliance' -WindowStyle Hidden | Out-Null }catch{}
  schtasks /run /tn "\Microsoft\Intune\PushLaunch" | Out-Null
}

Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 1000);
'@

# Encode for -EncodedCommand (UTF-16LE -> Base64)
$enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($payload))

# Create/repair the SYSTEM task
$create = @(
  '/Create','/TN', $taskName,
  '/SC','MINUTE','/MO',"$intervalMin",
  '/RU','SYSTEM','/RL','HIGHEST','/F',
  '/TR', ('"'+$ps64+'" -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -EncodedCommand ' + $enc)
)
Start-Process schtasks.exe -ArgumentList $create -WindowStyle Hidden -Wait | Out-Null

# Kick it once now
schtasks /run /tn $taskName | Out-Null
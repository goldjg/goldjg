# Registers/repairs \Microsoft\ISDF\Watchdog to run every 15m using -EncodedCommand.

$taskName    = '\Microsoft\ISDF\Watchdog'
$intervalMin = 15
$ps64        = "$env:WINDIR\SysNative\WindowsPowerShell\v1.0\powershell.exe"

# --- Minimal watchdog payload (PS 5.1-safe): only do the 3 things requested ---
$payload = @'
$ErrorActionPreference='SilentlyContinue';$ProgressPreference='SilentlyContinue';

# Gather all task names (CSV is easiest on PS 5.1)
$rows = schtasks /Query /FO CSV 2>$null
$taskNames = @()

try {
  $csv = $rows | ConvertFrom-Csv
  if($csv -and ($csv[0].PSObject.Properties.Name -contains 'TaskName')){
    $taskNames = $csv | ForEach-Object { $_.TaskName }
  }
} catch {}

# Fallback CSV-first-column parse if header was localized or ConvertFrom-Csv failed
if(-not $taskNames -or $taskNames.Count -eq 0){
  foreach($line in $rows){
    $m = [regex]::Match($line,'^"([^"]+)",')
    if($m.Success){ $taskNames += $m.Groups[1].Value }
  }
}

# 1) Run all copies of PushLaunch
$push = $taskNames | Where-Object { $_ -match '(^|\\)PushLaunch$' } | Sort-Object -Unique
foreach($tn in $push){ schtasks /Run /TN $tn | Out-Null }

# 2) Run all copies whose name starts with "Schedule #3"
$sche3 = $taskNames | Where-Object { $_ -match '(^|\\)Schedule #3.*$' } | Sort-Object -Unique
foreach($tn in $sche3){ schtasks /Run /TN $tn | Out-Null }

# 3) Trigger compliance sync via IME URI
try { Start-Process 'intunemanagementextension://synccompliance' -WindowStyle Hidden | Out-Null } catch {}

# Small jitter to avoid thundering herd effects if deployed widely
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
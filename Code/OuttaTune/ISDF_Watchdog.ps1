# Ensures a Scheduled Task exists that triggers PushLaunch, "Schedule #3*" tasks, and IME compliance sync.
# Safe to re-run (idempotent). Scope this deployment to your "enhanced monitoring" devices.

# Registers/repairs \Microsoft\ISDF\Watchdog to run every 15m using -EncodedCommand.


#Requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

$taskPath = '\ISDF\'
$taskName = 'ComplianceSync'

# 1) Build the action: 64-bit PowerShell, hidden window, tiny jitter, then run the three actions
$psExe = "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe"
$inline = @'
$ErrorActionPreference = "SilentlyContinue"
Start-Sleep -Seconds (Get-Random -Minimum 5 -Maximum 45)  # small jitter

# 1) Run all copies of PushLaunch
Get-ScheduledTask -TaskName "PushLaunch" -ErrorAction SilentlyContinue | ForEach-Object {
  $_ | Start-ScheduledTask
}

# 2) Run all copies whose name starts with "Schedule #3"
Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
  $_.TaskName -like "Schedule #3*"
} | ForEach-Object {
  $_ | Start-ScheduledTask
}

# 3) Trigger IME compliance sync
try { Start-Process 'intunemanagementextension://synccompliance' -WindowStyle Hidden | Out-Null } catch {}

exit 0
'@

# Use -EncodedCommand to avoid quoting/length issues (UTF-16LE)
$encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($inline))
$arg = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand ' + $encoded

$action = New-ScheduledTaskAction -Execute $psExe -Argument $arg

# 2) Triggers: at startup, at logon, and every 15 minutes (all day, today). The -Once start is midnight today.
$trigStartup = New-ScheduledTaskTrigger -AtStartup
$trigLogon   = New-ScheduledTaskTrigger -AtLogOn
$trigRepeat  = New-ScheduledTaskTrigger -Once -At (Get-Date).Date `
               -RepetitionInterval (New-TimeSpan -Minutes 15)

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

# 3) Run as SYSTEM, highest privileges
$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -RunLevel Highest -LogonType ServiceAccount

# 4) Settings: allow on battery, wake not required, stop if running > 5 min, ignore overlapping runs
$settings = New-ScheduledTaskSettingsSet `
  -AllowStartIfOnBatteries `
  -DontStopIfGoingOnBatteries `
  -StartWhenAvailable `
  -ExecutionTimeLimit (New-TimeSpan -Minutes 5) `
  -Compatibility Win8 `
  -MultipleInstances IgnoreNew

# 5) Register (create or update in place)
$task = New-ScheduledTask -Action $action -Trigger @($trigStartup,$trigLogon,$trigRepeat) `
        -Principal $principal -Settings $settings

try {
  if (-not (Get-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction SilentlyContinue)) {
    Register-ScheduledTask -TaskPath $taskPath -TaskName $taskName -InputObject $task | Out-Null
  } else {
    Register-ScheduledTask -TaskPath $taskPath -TaskName $taskName -InputObject $task -Force | Out-Null
  }
  Write-Information "ISDF: ComplianceSync task is present and up to date."
} catch {
  Register-ScheduledTask -TaskPath $taskPath -TaskName $taskName -InputObject $task | Out-Null
  Write-Information "ISDF: ComplianceSync task created."
}
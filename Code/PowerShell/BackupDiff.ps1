$ErrorActionPreference = "Continue" # or "Stop"
 
Write-Host ((get-date -format g) + " - Syncing Documentation Repository")|out-default
 
Sleep -s 5
 
$SrcDir = "\\##SHAREPOINT URL PATH"
$DestDir = "##REDACTED##"
$OptsA = @("/COPY:DT","/ZB","/E","/R:0","/V","/NP","/XJ")
$LogFile = "\\##REDACTED##\Sync_" `
                + (get-date -uformat %d_%m_%y) + ".txt"
Robocopy $SrcDir $DestDir $OptsA /LOG+:$LogFile|out-default
 
$FirstRunExit = $LastExitCode
 
If ($FirstRunExit -lt 16) {
    Write-Host ("`n" + (get-date -format g) + " - Sync of Documentation Repository successful")|out-default
    }

Write-Host ("`n" + (get-date -format g) + " - Sync exit code: " + $FirstRunExit)|out-default
Write-Host (get-content $LogFile|select -last 13|out-string)|out-default
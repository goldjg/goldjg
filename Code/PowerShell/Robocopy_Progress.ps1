$ErrorActionPreference = "Continue" # or "Stop"
 
Write-Host ((get-date -format g) + " - Syncing Folders")|out-default
 
#Sleep -s 5
 
$SrcDir = "\\##REDACTED##\Documentation Repository"
$DestDir = "\\##REDACTED##"
$OptsA = @("/COPY:DAT","/L","/NS","/NC","/ZB","/E","/NP")
$LogFile = "\\##REDACTED##\TestSync_" `
                + (get-date -uformat %d_%m_%y) + ".txt"
$filestocopy = (dir -recurse $SrcDir)

Write-Host ("`n" + (get-date -format g) + " - Sync of folders successful")|out-default
#Initialise path variables
$LANPath = "\\##REDACTED##"
$SharepointPath = "\\##REDACTED##"
$ScriptPath = $LANPath + "\bin"

#Open sharepoint folder in Windows Explorer, if available
explorer $SharepointPath

sleep -s 5

Get-Focus     
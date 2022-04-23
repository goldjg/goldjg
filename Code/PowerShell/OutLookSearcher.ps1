 [String]$Scope = "'Inbox','Sent Items','Folders'"
 [String]$Compare ="cron"
 [String]$Filter = ("urn:schemas:httpmail:textdescription LIKE '%" + $Compare + "%'")
Add-Type -Assembly "Microsoft.Office.Interop.Outlook"
$Outlook = New-Object -ComObject Outlook.Application
$Results = $Outlook.AdvancedSearch($Scope,$Filter,$True,"GGSearch").Results
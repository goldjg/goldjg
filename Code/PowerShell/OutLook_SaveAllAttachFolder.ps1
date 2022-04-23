<#
https://social.technet.microsoft.com/forums/windowsserver/en-US/11218cf2-eb24-4110-967f-b29234064501/how-do-i-save-outlook-attachments-using-powershell
#>
$o = New-Object -comobject outlook.application
 $n = $o.GetNamespace("MAPI")

$f = $n.PickFolder()

$filepath = "K:\FTPLOGS\"
 $f.Items| foreach {
  $SendName = $_.SenderName
    $_.attachments|foreach {
     Write-Host $_.filename
     $a = $_.filename
     If ($a.Contains("TXT") -and ($SendName -like 'ALPHA*')) {
     $_.saveasfile((Join-Path $filepath $a))
    }
   }
 }

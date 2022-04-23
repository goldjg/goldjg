<#try{$webresult = Invoke-WebRequest -Uri "http://##REDACTED##" -UseDefaultCredentials}
Catch {$ErrorMessage = $_.Exception.Message
       $FailedItem = $_.Exception.ItemName
       write-host ($ErrorMessage + " :: " + $FailedItem)
       $exc = $_.Exception}
#>

$oIE=new-object -com internetexplorer.application
$oIE.navigate2("http://##REDACTED##")
while ($oIE.busy) {
    sleep -milliseconds 50
}
$oIE.visible=$true
Function Tagit([string[]]$params){$params|foreach{write-host $_;Set-Variable -name $_ -Description "Script" -scope 1}}
$filein="\\blah\blah"
[string[]]$RepsToRun = "IAM","OPS","ADMIN"
Tagit('filein','RepsToRun')
Get-Variable filein -Scope 1|select Name,Description,Value
Get-Variable RepsToRun|select Name,Description,Value
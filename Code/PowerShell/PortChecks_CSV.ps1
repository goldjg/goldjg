<#"FQDN","IP","PORT"
"srv.dom.local","1.2.3.4","443"
#>

$Servers=Import-Csv .\ort_Check_Src.csv

$servers|ForEach-Object{Test-NetConnection -ComputerName $_.FQDN -port $_.PORT -WarningAction SilentlyContinue|Select-Object ComputerName,SourceAddress,RemotePort,TCPTestSucceeded}
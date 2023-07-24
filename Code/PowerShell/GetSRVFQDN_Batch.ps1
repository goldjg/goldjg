$servers = Get-Content "C:\ServerList.txt"
$list = @{}

foreach ($srv in $servers) {
    $rslt=Resolve-DnsName -Name $srv -Type A -ErrorAction SilentlyContinue -QuickTimeout
    If ($rslt) {$FQDN=($rslt|Select-Object -ExpandProperty Name)} else { $FQDN = "Name resolution failed"}

    $list.Add($srv,$rslt.IPAddress)  
    
}
$list.GetEnumerator() | Select-Object -Property @{N='Server';E={$_.Key}},
    @{N='FQDN';E={$_.Value}} | Export-Csv -NoTypeInformation  "C:\ServerList.csv"
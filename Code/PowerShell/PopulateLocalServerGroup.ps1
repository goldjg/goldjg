$servers = Get-Content "SRV.txt"
$DomainName = "dom.Local"
$UserName = ""

foreach ($srv in $servers) {
    $AdminGroup = [ADSI]"WinNT://$srv/Administrators,group"
    $User = [ADSI]"WinNT://$DomainName/$UserName,user"
    $AdminGroup.Add($User.Path)
}
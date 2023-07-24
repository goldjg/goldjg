$users = Get-Content "C:\users.txt"
$list = @()

foreach ($user in $users) {
$obj = New-Object System.Object
rv usrgroups -ErrorAction SilentlyContinue

Switch -Regex ($user) {
    '^*1.co.uk$'{$server = "1.local"}
    '^*1.co.uk$'{$server = "1.co.uk"}
    '^*1.1.com$'{$server = "1.local"}
    '^*1.local$'{$server = "1.local"}
}

    $usrgroups=get-aduser -server $server -filter 'UserPrincipalName -eq $user' -Properties MemberOf|Select -ExpandProperty MemberOf|Select-String "SA_CA_";
                                         $obj | Add-Member -Type NoteProperty -Name UserPrincipalName -Value ([String]$user -as [String]);
                                         If ($usrgroups.count -eq 0){$usrgroups ="None"} else { $usrgroups = $usrgroups|Select -ExpandProperty Line };
                                         $obj | Add-Member -Type NoteProperty -Name CyberArkGroups -Value ([String]$usrgroups -replace " CN",";CN");       
        
$obj
$list += $obj
}

$list | ConvertTo-Csv -NoTypeInformation -Delimiter "," | out-file "C:\test2.csv"
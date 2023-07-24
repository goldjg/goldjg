$users = Get-Content "C:\users.txt"
$table = @()

foreach ($user in $users) {
$obj = New-Object System.Object

Switch -Regex ($user) {
    '^*1.co.uk$'{$server = "1.local"}
    '^*1.co.uk$'{$server = "1.co.uk"}
    '^*1.1.com$'{$server = "1.local"}
    '^*1.local$'{$server = "1.local"}
}

    $usrgroups=get-aduser -server $server -filter 'UserPrincipalName -eq $user' -Properties MemberOf|Select -ExpandProperty MemberOf|Select-String "";
                                         $obj | Add-Member -Type NoteProperty -Name UserPrincipalName -Value ([String]$user -as [String]);
                                         If ($usrgroups.count -eq 0){$usrgroups ="None"} else { $usrgroups = $usrgroups|Select-Object -ExpandProperty Line };
                                         $obj | Add-Member -Type NoteProperty -Name Groups -Value ([String]$usrgroups -replace " CN",";CN");       
        
$obj
$table += $obj
}
$table
$list | ConvertTo-Csv -NoTypeInformation -Delimiter "," | out-file "C:\out.csv"
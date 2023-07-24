$users = Import-Csv "C:\CyberArk\EPVUserslist.csv"
$table = @()

foreach ($user in $users) {
$obj = New-Object System.Object

Switch -Regex ($user.Location) {
    '^\\$'{$server = "production.local"}
    '^\\PEOPLE\\LDAP\\dom1\.CO\.UK$'{$server = "dom1.co.uk"}
    '^\\PEOPLE\\LDAP\\dom2\.LOCAL$'{$server = "dom2.local"}
    '^\\PEOPLE\\LDAP\\dom3\.LOCAL$'{$server = "dom3.local"}
}

Switch -Regex ($user.User) {
    '^*\@.*$' {$AccountType="Active Directory"}
    Default {$AccountType="CyberArk"}
}
    $UPN=$($user.user)
    If ($accountType -ne "CyberArk") {$usrdetails=get-aduser -server $server -filter 'UserPrincipalName -eq $UPN' -ErrorAction SilentlyContinue} 
    else { $server = "Local"};
        $obj | Add-Member -Type NoteProperty -Name "UserPrincipalName" -Value $UPN;
        $obj | Add-Member -Type NoteProperty -Name "Domain" -Value $server;
        $obj | Add-Member -Type NoteProperty -Name "AccountType" -Value $AccountType
        $obj | Add-Member -Type NoteProperty -Name "SamAccountName" -Value ([String]$usrdetails.samaccountname -as [String]);       
        
$obj
$table += $obj
}
$table
$table | ConvertTo-Csv -NoTypeInformation -Delimiter "," | out-file "C:\Users\\CyberArk\EPV_Users_UPN_to_Sam.csv"
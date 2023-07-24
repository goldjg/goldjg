$users = Import-Csv "C:\User_Groups.csv"
$table = @()

foreach ($user in $users) {
$obj = New-Object System.Object
    $usrgroups=get-aduser -server $user.domain  -Identity $user.Username -Properties MemberOf|Select -ExpandProperty MemberOf|Select-String "";
                                         $obj | Add-Member -NotePropertyName "Employee Name" -NotePropertyValue ($user.'Employee Name');
                                         If (!($usrgroups)){$usrgroups = "User Not Found or no matching groups"
                                         } else { $usrgroups = $usrgroups|Select-Object -ExpandProperty Line};
                                         $obj | Add-Member -NotePropertyName "Groups" -NotePropertyValue ([String]$usrgroups -replace " CN",";CN");
                                         $obj | Add-Member -NotePropertyName "User ID" -NotePropertyValue $user.Username
                                         $obj | Add-Member -NotePropertyName "Domain" -NotePropertyValue $user.Domain  
                                         $obj | Add-Member -NotePropertyName "Early Adopters" -NotePropertyValue $user.'Early Adopters'        
$obj
$table += $obj
}

$table | ConvertTo-Csv -NoTypeInformation -Delimiter "," | out-file "C:\Groups_Out.csv"
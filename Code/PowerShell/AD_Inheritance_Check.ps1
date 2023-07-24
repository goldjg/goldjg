$users = Get-ADUser -ldapfilter "(objectclass=user)" -searchbase "DC=dom,DC=local"

$output=@()

ForEach($user in $users)
{
   
    $i++;
    Write-Progress -Activity ("Processing user object $i of "+ $users.count)
    $obj = New-Object System.Object
    $dn= [ADSI]("LDAP://" + $user)
    $acl= $dn.psbase.objectSecurity
    <#if ($acl.get_AreAccessRulesProtected())
    {
        $isProtected = $false # $false to enable inheritance
                              # $true to disable inheritance
        $preserveInheritance = $true # $true to keep inherited access rules
                                     # $false to remove inherited access rules.
                                     # ignored if isProtected=$false
        $acl.SetAccessRuleProtection($isProtected, $preserveInheritance)
        $dn.psbase.commitchanges()
        Write-Host($user.SamAccountName + "|" + `
                   $user.DistinguishedName + `
                   "|inheritance set to enabled")
    }
    else
    {
        write-host($user.SamAccountName + "|" + `
                   $user.DistinguishedName + `
                   "|inheritance already enabled")}
  #>  
$uname=$user.Name
$protected=$acl.get_AreAccessRulesProtected()

$obj | Add-Member -NotePropertyName User -NotePropertyValue $uname
$obj | Add-Member -NotePropertyName AccessRulesProtected -NotePropertyValue $protected
$obj | Add-Member -NotePropertyName OU -NotePropertyValue $user.DistinguishedName.Split(",",2)[1]

$output+=$obj

}

$output|Export-Csv -NoTypeInformation -Path C:\Users\me\ProtectedUsers.csv
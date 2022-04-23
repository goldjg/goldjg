$table = @()
Get-ADGroupMember -Identity ##REDACTED##|foreach{
    $User = Get-ADUser -Identity $_.Name;
    
    If($User.DistinguishedName -like '*##REDACTED##*'){
        $row = New-Object System.Object
        $row | Add-Member -MemberType NoteProperty -Name Surname -Value $User.Surname
        $row | Add-Member -MemberType NoteProperty -Name Name -Value $User.GivenName
        $row | Add-Member -MemberType NoteProperty -Name Id -Value $User.Name
        $row | Add-Member -MemberType NoteProperty -Name Company (($User.DistinguishedName).Split(",")[1]).Split("=")[1]
        $table+=$row}
    }
    $table|ogv
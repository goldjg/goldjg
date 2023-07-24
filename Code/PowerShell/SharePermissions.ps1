$shares = Get-WMIObject -class Win32_share | Where-Object { $_.Path -ne "" }
$Report = @()
Foreach ($share in $shares) {
    $Acl = Get-Acl -Path $share.Path
    foreach ($Access in $acl.Access)
        {
            $Properties = [ordered]@{'ShareName'=$share.Name;
            'Path'=$share.Path;
            'Group/User'=$Access.IdentityReference;
            'Access Type'=$Access.AccessControlType;
            'Permissions'=$Access.FileSystemRights;
            'Inherited?'=$Access.IsInherited;
            'Inheritance'=$Access.InheritanceFlags;
            'Permission Propagation'=$Access.PropagationFlags}
            $Report += New-Object -TypeName PSObject -Property $Properties
        }
}
$Report | Export-Csv -NoTypeInformation -path "$env:USERDATA\FolderPermissions.csv"
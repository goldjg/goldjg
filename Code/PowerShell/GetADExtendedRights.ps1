param(
    [Parameter(Mandatory=$True)]
    [string]$server,

    [Parameter(Mandatory=$True)]
    [string]$DN,

    [Parameter(Mandatory=$True)]
    [System.Management.Automation.PSCredential]$crds
)
$rootdse = Get-ADRootDSE -Server $server
$ExtendedMapParams = @{
    SearchBase = ($rootdse.ConfigurationNamingContext)
    LDAPFilter = "(&(objectclass=controlAccessRight)(rightsguid=*))"
    Properties = ("displayName", "rightsGuid")
}
$extendedrightsmap = @{ }
Get-ADObject @ExtendedMapParams | ForEach-Object { $extendedrightsmap[([System.GUID]$_.rightsGuid)] = $_.displayName }

$rslt=(get-acl "AD:$DN").Access

$table = @()

Foreach ($item in $rslt) {
    $obj = New-Object System.Object
    $obj|Add-Member -MemberType NoteProperty -Name IdentityReference -Value $item.IdentityReference
    $obj|Add-Member -MemberType NoteProperty -Name AccessControlType -Value $item.AccessControlType
    $obj|Add-Member -MemberType NoteProperty -Name ActiveDirectoryRights -Value $item.ActiveDirectoryRights
    $ExRV1 = $extendedrightsmap.Item($item.ObjectType)
    If (!($ExRV1)) {$ExRV1 = "N/A"}
    $obj|Add-Member -MemberType NoteProperty -Name ExtendedRights1 -Value ($ExRV1)
    $ExRV2 = $extendedrightsmap.Item($item.InheritedObjectType)
    If (!($ExRV2)) {$ExRV2 = "N/A"}
    $obj|Add-Member -MemberType NoteProperty -Name ExtendedRights2 -Value ($ExRV2)
    $table += $obj
}

return $table

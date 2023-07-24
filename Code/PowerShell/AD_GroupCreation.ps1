#Script to create a new Domain Setup
[cmdletBinding()]
Param
(
	[Parameter(mandatory=$true,ValueFromPipeline=$true)]
	[string]$Domain,
	[Parameter(mandatory=$true,ValueFromPipeline=$true)]
	[string]$OU,
	[Parameter(mandatory=$true,ValueFromPipeline=$true)]
	[string]$Group,
	[Parameter(mandatory=$false,ValueFromPipeline=$true)]
	[PSCredential]$Cred
)

Import-Module ActiveDirectory
If($Cred -ne $Null){
	$rootdse = Get-ADRootDSE -Server $Domain -Credential $Cred
	$objdomain = Get-ADDomain -Server $Domain -Credential $Cred
} else {
	$rootdse = Get-ADRootDSE -Server $Domain
	$objdomain = Get-ADDomain -Server $Domain
}
$guidmap = @{}
If($Cred -ne $Null){
	Get-ADObject -SearchBase ($rootdse.SchemaNamingContext) -LDAPFilter "(schemaidguid=*)" -Properties lDAPDisplayName,schemaIDGUID -Server $Domain -Credential $Cred | % {$guidmap[$_.lDAPDisplayName]=[System.GUID]$_.schemaIDGUID}
} else {
	Get-ADObject -SearchBase ($rootdse.SchemaNamingContext) -LDAPFilter "(schemaidguid=*)" -Properties lDAPDisplayName,schemaIDGUID -Server $Domain | % {$guidmap[$_.lDAPDisplayName]=[System.GUID]$_.schemaIDGUID}
}

$extendedrightsmap = @{}
If($Cred -ne $Null){
	Get-ADObject -SearchBase ($rootdse.ConfigurationNamingContext) -LDAPFilter "(&(objectclass=controlAccessRight)(rightsguid=*))" -Properties displayName,rightsGuid -Server $Domain -Credential $Cred | % {$extendedrightsmap[$_.displayName]=[System.GUID]$_.rightsGuid}
	$objou = Get-ADOrganizationalUnit -Identity ("$OU,$objDomain") -Server $Domain -Credential $Cred
	$objperm = New-Object System.Security.Principal.SecurityIdentifier (Get-ADGroup "$Group" -Server $Domain -Credential $Cred).SID
	$ps=New-PSDrive -Name AD2 -PSProvider ActiveDirectory -Server $Domain -root "//RootDSE/" -Credential $Cred
} else {
	Get-ADObject -SearchBase ($rootdse.ConfigurationNamingContext) -LDAPFilter "(&(objectclass=controlAccessRight)(rightsguid=*))" -Properties displayName,rightsGuid -Server $Domain | % {$extendedrightsmap[$_.displayName]=[System.GUID]$_.rightsGuid}
	$objou = Get-ADOrganizationalUnit -Identity ("$OU,$objDomain") -Server $Domain
	$objperm = New-Object System.Security.Principal.SecurityIdentifier (Get-ADGroup "$Group" -Server $Domain).SID
	$ps=New-PSDrive -Name AD2 -PSProvider ActiveDirectory -Server $Domain -root "//RootDSE/"
}
$acl = Get-ACL -Path ("AD2:\"+($objou.DistinguishedName))
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $objperm,"GenericAll","Allow","Descendents",$guidmap["group"]))
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $objperm,"CreateChild,DeleteChild","Allow",$guidmap["group"],"All"))
Set-ACL -ACLObject $acl -Path ("AD2:\"+($objou.DistinguishedName))

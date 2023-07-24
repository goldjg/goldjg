Param
(
    [Parameter(Mandatory = $true)]
    [String] $searchUser
)
$mgSID      =  (Get-ADDomain -server 1).DomainSID.Value
$prodSID    =  (Get-ADDomain -server 2).DomainSID.Value
$corpSID    =  (Get-ADDomain -server 3).DomainSID.Value
$pgdsSID    =  (Get-ADDomain -server 4).DomainSID.Value
$Tenant = ""

try { 
    $ADTenant = Get-AzureADTenantDetail 
} 
catch [Microsoft.Open.Azure.AD.CommonLibrary.AadNeedAuthenticationException] { 
    Write-Host "You're not connected to AzureAD, authenticating..."; 
    Connect-AzureAD -TenantID $Tenant -Verbose;
}

$userSID = (Get-AzureADUser -SearchString $searchUser).OnPremisesSecurityIdentifier
If ($userSID.Length -gt 0){
    switch -wildcard ($userSID) {
        "$corpSID*"     { return "[INFO] User $searchuser Primary Domain is 1" }
        "$prodSID*"     { return "[INFO] User $searchuser Primary Domain is 2" }
        "$mgSID*"       { return "[INFO] User $searchuser Primary Domain is 3" }
        "$pgdsSID*"     { return "[INFO] User $searchuser Primary Domain is 4" }
        Default         { return "[ERROR] User SID $userSID not found in the domains 1,2,3 or 4" }
    }
} else {
    return "[ERROR] User $searchUser not found in AzureAD in Tenant: $($ADTenant.DisplayName)"
}
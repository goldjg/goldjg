$searchHost = ""
$searchHosts = "'',''"
$searchRole = ""
$searchEnv = "env"

$KQLVMPrefix = "Resources | where type =~ 'microsoft.compute/virtualmachines'"
$KQLSingleVM = "$KQLVMPrefix | where tags['HostName'] startswith '$searchHost'"
$KQListVMs = "$KQLVMPrefix | where tolower(tags['HostName']) in ($searchHosts)"
$KQLRoleVMs = "$KQLVMPrefix | where tags['Role'] =~ '$searchRole'"
$KQLRoleVMsByEnv = "$KQLRoleVMs | where tags['ProductEnvironment'] has '$searchEnv'"

Import-Module Az.ResourceGraph
Connect-AzAccount

Write-Host "Running query: $KQLSingleVM"
Search-AzGraph -Query $KQLSingleVM | Out-File SingleVM.txt

Write-Host "Running query: $KQListVMs"
Search-AzGraph -Query $KQListVMs | Out-File ListVMs.txt

Write-Host "Running query: $KQLRoleVMs"
Search-AzGraph -Query $KQLRoleVMs | Out-File RoleVMs.txt

Write-Host "Running query: $KQLRoleVMsByEnv"
Search-AzGraph -Query $KQLRoleVMsByEnv | Out-File RoleVMsPrd.txt
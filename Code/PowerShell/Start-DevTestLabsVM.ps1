Connect-AzAccount
Set-AzContext -SubscriptionId blah
$devTestLabName = ""
$vMToStart = ""
$vmAction = "Start"

# Get the lab information
$devTestLab = Get-AzResource -ResourceType 'Microsoft.DevTestLab/labs' -ResourceName $devTestLabName

# Start or stop the VM and return a succeeded or failed status
# Get the lab information
$devTestLab = Get-AzResource -ResourceType 'Microsoft.DevTestLab/labs' -ResourceName $devTestLabName

# Start or stop the VM and return a succeeded or failed status
$returnStatus = Invoke-AzResourceAction `
                    -ResourceId "$($devTestLab.ResourceId)/virtualmachines/$vMToStart" `
                    -Action $vmAction `
                    -Force

if ($returnStatus.Status -eq 'Succeeded') {
    Write-Output "##[section] Successfully updated DTL machine: $vMToStart, Action: $vmAction"
}
else {
    Write-Error "##[error] Failed to update DTL machine: $vMToStart, Action: $vmAction"
}
Param(
    [Parameter(Mandatory=$False)]
    [switch]$UpdateAdmins
)

$PolicyAdmins = @(
    "$(hostname)\sniwadmin",
    "DOM\grp1",
    "DOM\acc1",
    "DOM\acc2",
    "DOM\acc3",
    "DOM\acc4",
    "DOM\acc5"
 )
Write-Host "Expected Local Admins:"
Write-Host "====================="
Write-Host $PolicyAdmins
Write-Host

$LocalAdmins = Get-LocalGroupMember -Group Administrators | Select-Object -ExpandProperty Name
Write-Host "Actual Local Admins:"
Write-Host "==================="
$LocalAdmins
Write-Host

$ExtraAdmins = Compare-Object $PolicyAdmins $LocalAdmins | Where {
    $_.SideIndicator -eq "=>"
}

Write-Host "Extra Local Admins:"
Write-Host "=================="
$ExtraAdmins.InputObject
Write-Host

$MissingAdmins = Compare-Object $PolicyAdmins $LocalAdmins | Where {
    $_.SideIndicator -eq "<="
}

Write-Host "Missing Local Admins:"
Write-Host "===================="
$MissingAdmins.InputObject
Write-Host

Write-Host "Verifying required changes..."

$MissingAdmins | Foreach {
    Add-LocalGroupMember -Group Administrators -Member $_.InputObject -WhatIf
}

$ExtraAdmins | Foreach {
    Remove-LocalGroupMember -Group Administrators -Member $_.InputObject -WhatIf
}

If ($UpdateAdmins) {

    Write-Host "-Update switch was set, updating local admins..."

    $MissingAdmins | Foreach {
        Add-LocalGroupMember -Group Administrators -Member $_.InputObject
    }

    $ExtraAdmins | Foreach {
    Remove-LocalGroupMember -Group Administrators -Member $_.InputObject
        }

    $NewLocalAdmins = Get-LocalGroupMember -Group Administrators | Select-Object -ExpandProperty Name
    Write-Host "New Local Admins:"
    Write-Host "================"
    $NewLocalAdmins
    Write-Host

}
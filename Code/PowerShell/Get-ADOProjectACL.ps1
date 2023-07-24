$AZStatus = az --version
$AZError = $Error[0]
If ($LASTEXITCODE -ne 0) {
    If ($AZError.CategoryInfo.Category -eq "ObjectNotFound") {
        Write-Host -ForegroundColor Red "AZ CLI is not installed and is a pre-requisite"
        $Choice = Get-Host "Install AZ CLI? (Y/N) : Requires Elevation to Administrator security context"
        Switch ($Choice) {
            Y {$InstallAZCLI = $true}
            y {$InstallAZCLI = $true}
            N {$InstallAZCLI = $false}
            n {$InstallAZCLI = $false}
            else {Throw "Invalid choice, assuming choice is not to install AZ CLI"}
        }
        If ($InstallAZCLI){
            #$ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi
            Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet' -Verb RunAs
            Remove-Item .\AzureCLI.msi
        }
    }
}

$AZDevStatus = az extension list | ConvertFrom-Json

If (-not $AZDevStatus.name -eq "azure-devops") {
    az extension add --name azure-devops
}

$graphGrps = az devops security group list --project ""
$jsonGrps = $graphGrps|ConvertFrom-Json
$graphNS = az devops security permission namespace list
$jsonNS = $graphNS|ConvertFrom-Json

$jsonGrps.graphGroups.descriptor | ForEach-Object {
    $groupID = $_
    $jsonNS | ForEach-Object {
        $grpACL = az devops security permission list --subject $groupID --id $_.namespaceID --recurse
        $grpACL | Out-File -FilePath "C:\temp\$($groupID).json"
    }
}
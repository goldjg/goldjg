<# 
.SYNOPSIS 
  Enumerates all secrets in all Key Vaults in all subscriptions using the Azure Management API to walk through the tenant and outputs the results.
.DESCRIPTION 
  This script uses the `Az` module to authenticate to Azure using device authentication. It then retrieves an access token for `management.azure.com` and uses `Invoke-RestMethod` to call the management API to enumerate secrets in Key Vaults. The output can be displayed, or saved to JSON and/or CSV files.
  This script does the following:
  1. Checks if the `Az` PowerShell module is installed and installs it if it is not.
  2. Imports the `Az` module.
  3. Logs in to Azure using `Connect-AzAccount` with device authentication.
  4. Retrieves an access token for `management.azure.com` using `Get-AzAccessToken`.
  5. Uses `Invoke-RestMethod` to call the management.azure.com API endpoints for all subscriptions, resource groups, Key Vaults, and secrets.
  6. Outputs the details of each secret, including each field in the `properties` field.
  7. Uses parameters `-json`, `-csv`, and `-noDisplay` to control the output format and display behavior.
  8. Collects secret details in a collection and outputs them to JSON or CSV if the respective parameter is supplied.
  9. Displays a count of secrets, Key Vaults, resource groups, and subscriptions in a summary table at the end.
.PARAMETER json
  <Optional> Output results to a JSON file.
.PARAMETER csv
  <Optional> Output results to a CSV file.
.PARAMETER noDisplay
  <Optional> Do not display the secrets on screen but still respect the json and csv options.
.EXAMPLE 
  .\Skywalker.ps1
  This will display the results on the screen.

.EXAMPLE 
  .\Skywalker.ps1 -json
  This will output the results to a JSON file.

.EXAMPLE 
  .\Skywalker.ps1 -csv
  This will output the results to a CSV file.

.EXAMPLE 
  .\Skywalker.ps1 -json -csv
  This will output the results to both a JSON and a CSV file.

.EXAMPLE 
  .\Skywalker.ps1 -noDisplay
  This will not display the secrets on screen but will still output the results to JSON and/or CSV if the respective parameters are set.

.EXAMPLE 
  .\Skywalker.ps1 -json -noDisplay
  This will output the results to a JSON file but will not display the secrets on screen.

.EXAMPLE 
  .\Skywalker.ps1 -csv -noDisplay
  This will output the results to a CSV file but will not display the secrets on screen.

.NOTES 
  Make sure the `Az` module is installed and you are authenticated to Azure.
#>

param (
    [switch]$json,
    [switch]$csv,
    [switch]$noDisplay
)

# Check if the Az module is installed, and install it if it isn't
if (-not (Get-Module -ListAvailable -Name Az)) {
    Install-Module -Name Az -Force -AllowClobber -Scope CurrentUser
}

# Import the Az module
Import-Module Az

# Login to Azure using device authentication
Connect-AzAccount

# Get the access token for management.azure.com
$token = (Get-AzAccessToken -ResourceUrl "https://management.azure.com").Token

# Variables
$subscriptionApiVersion = "2014-04-01"
$resourceGroupApiVersion = "2014-04-01"
$keyVaultApiVersion = "2016-10-01"

# Initialize collection to hold secret details
$allSecrets = @()

# Get all subscriptions
$subscriptions = Invoke-RestMethod -Method Get -Uri "https://management.azure.com/subscriptions?api-version=$subscriptionApiVersion" -Headers @{ Authorization = "Bearer $token" }

# Initialize counters
$subscriptionCount = 0
$resourceGroupCount = 0
$keyVaultCount = 0
$secretCount = 0

# Iterate over each subscription
foreach ($subscription in $subscriptions.value) {
    $subscriptionCount++
    # Get all resource groups in the current subscription
    $resourceGroups = Invoke-RestMethod -Method Get -Uri "https://management.azure.com/subscriptions/$($subscription.subscriptionId)/resourceGroups?api-version=$resourceGroupApiVersion" -Headers @{ Authorization = "Bearer $token" }

    foreach ($resourceGroup in $resourceGroups.value) {
        $resourceGroupCount++
        # Get all Key Vaults in the current resource group
        $keyVaults = Invoke-RestMethod -Method Get -Uri "https://management.azure.com/subscriptions/$($subscription.subscriptionId)/resourceGroups/$($resourceGroup.name)/providers/Microsoft.KeyVault/vaults?api-version=$keyVaultApiVersion" -Headers @{ Authorization = "Bearer $token" }

        foreach ($keyVault in $keyVaults.value) {
            $keyVaultCount++
            # Get all secrets in the current Key Vault
            $secrets = Invoke-RestMethod -Method Get -Uri "https://management.azure.com/subscriptions/$($subscription.subscriptionId)/resourceGroups/$($resourceGroup.name)/providers/Microsoft.KeyVault/vaults/$($keyVault.name)/secrets?api-version=$keyVaultApiVersion" -Headers @{ Authorization = "Bearer $token" }

            foreach ($secret in $secrets.value) {
                $secretCount++
                # Capture the secret details
                $secretDetails = [PSCustomObject]@{
                    SubscriptionId       = $subscription.subscriptionId
                    ResourceGroupName    = $resourceGroup.name
                    KeyVaultName         = $keyVault.name
                    SecretName           = $secret.name
                    ContentType          = $secret.properties.contentType
                    Enabled              = $secret.properties.attributes.enabled
                    NotBefore            = $secret.properties.attributes.nbf
                    Expires              = $secret.properties.attributes.exp
                    Created              = $secret.properties.attributes.created
                    Updated              = $secret.properties.attributes.updated
                    SecretUri            = $secret.properties.secretUri
                    SecretUriWithVersion = $secret.properties.secretUriWithVersion
                }

                # Add to the collection
                $allSecrets += $secretDetails

                # Display the secret details if -noDisplay is not set
                if (-not $noDisplay) {
                    $secretDetails
                }
            }
        }
    }
}

# Output to JSON if -json is set
if ($json) {
    $allSecrets | ConvertTo-Json | Out-File -FilePath "secrets.json"
}

# Output to CSV if -csv is set
if ($csv) {
    $allSecrets | Export-Csv -Path "secrets.csv" -NoTypeInformation
}

# Display a count summary
$summary = [PSCustomObject]@{
    TotalSecrets        = $secretCount
    TotalKeyVaults      = $keyVaultCount
    TotalResourceGroups = $resourceGroupCount
    TotalSubscriptions  = $subscriptionCount
}

$summary | Format-Table -AutoSize
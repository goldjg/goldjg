# After reading $props:
$HasV2 = ($props.SM_v2 -is [byte[]]) -and ($props.SPN_v2 -is [byte[]])
$HasV1 = -not [string]::IsNullOrEmpty($props.SM) -and -not [string]::IsNullOrEmpty($props.SPN)
$ExpectedValuesPresent = $HasV2 -or $HasV1

# then in your result:
$result.ExpectedValuesPresent = [bool]$ExpectedValuesPresent
# (optionally) if (-not $ExpectedValuesPresent) { $result.SystemManufacturerOk = $false; $result.SystemProductNamePrefixOk = $false }
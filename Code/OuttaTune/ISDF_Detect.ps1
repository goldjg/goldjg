# Detect.ps1
# Exit 0 = compliant, 1 = needs remediation

#region Config
$RegPath = 'HKLM:\SOFTWARE\SMDILite'
$RegNameB64 = 'SignalB64'
$ImdsApiVersion = '2021-02-01'
$TagHints = @('Windows365','CloudPC','DevBox','Microsoft Dev Box')
$ExpectedAzEnvironments = @('AzurePublicCloud','AzureCloud','AzureGlobalCloud')
#endregion

function Get-DeviceMfrModel {
    $ctrlKey = 'HKLM:\SYSTEM\CurrentControlSet\Control'
    $manufacturer = $null
    $product = $null
    try {
        $props = Get-ItemProperty -Path $ctrlKey -Name SystemManufacturer,SystemProductName -ErrorAction Stop
        $manufacturer = $props.SystemManufacturer
        $product      = $props.SystemProductName
    } catch { }
    [pscustomobject]@{
        Manufacturer = $manufacturer
        Product      = $product
        Source       = 'Registry(Control)'
    }
}

function Get-ImdsCompute {
    try {
        $hdr = New-Object System.Collections.Generic.Dictionary[string,string]
        $hdr.Add('Metadata','true')
        $uri = "http://169.254.169.254/metadata/instance/compute?api-version=$ImdsApiVersion"
        Invoke-RestMethod -Headers $hdr -Method GET -Uri $uri -TimeoutSec 2
    } catch { $null }
}

function Get-TagListFromImds($compute) {
    $tags = @()
    if ($compute -ne $null) {
        $raw = $compute.tags
        if (-not [string]::IsNullOrWhiteSpace($raw)) {
            foreach ($p in ($raw -split ';')) {
                if (-not [string]::IsNullOrWhiteSpace($p)) { $tags += $p.Trim() }
            }
        }
    }
    $tags
}

function Build-SignalJson {
    param([Parameter(Mandatory=$true)]$Hw,[Parameter(Mandatory=$false)]$Compute)
    $azEnv = $null; $tags = @()
    if ($Compute -ne $null) {
        $azEnv = $Compute.azEnvironment
        $tags  = Get-TagListFromImds -compute $Compute
    }
    $obj = [ordered]@{
        Manufacturer = $Hw.Manufacturer
        Product      = $Hw.Product
        AzEnvironment= $azEnv
        Tags         = $tags
        TimestampUtc = [DateTime]::UtcNow.ToString('o')
    }
    ($obj | ConvertTo-Json -Depth 4 -Compress)
}

function Is-MicrosoftHostedCloudVM {
    param([Parameter(Mandatory=$true)]$Hw,[Parameter(Mandatory=$false)]$Compute)
    $m = $Hw.Manufacturer
    $p = $Hw.Product

    $mLooksMsft = (-not [string]::IsNullOrWhiteSpace($m)) -and ($m -like '*Microsoft*')
    $pLooksVm   = (-not [string]::IsNullOrWhiteSpace($p)) -and ( ($p -like '*Virtual*') -or ($p -like '*Cloud*') -or ($p -like '*Windows 365*') -or ($p -like '*Dev Box*') )

    $azOk = $false; $tagHit = $false
    if ($Compute -ne $null) {
        $az = $Compute.azEnvironment
        if (-not [string]::IsNullOrWhiteSpace($az)) {
            $azOk = $ExpectedAzEnvironments -contains $az
        }
        foreach ($hint in $TagHints) {
            foreach ($t in (Get-TagListFromImds -compute $Compute)) {
                if ($t -like "*$hint*") { $tagHit = $true; break }
            }
            if ($tagHit) { break }
        }
    }

    if ($mLooksMsft -and ($pLooksVm -or $azOk -or $tagHit)) { return $true }
    $false
}

# --- main ---
$hw      = Get-DeviceMfrModel
$compute = Get-ImdsCompute

$shouldHaveMarker = Is-MicrosoftHostedCloudVM -Hw $hw -Compute $compute
$haveMarker = $false
$matches    = $false

if (Test-Path -Path $RegPath) {
    try {
        $existing = Get-ItemProperty -Path $RegPath -Name $RegNameB64 -ErrorAction Stop
        $storedB64 = $existing.$RegNameB64
        if (-not [string]::IsNullOrWhiteSpace($storedB64)) {
            $haveMarker = $true
            $currentJson = Build-SignalJson -Hw $hw -Compute $compute
            $currentB64  = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($currentJson))
            if ($storedB64 -eq $currentB64) { $matches = $true }
        }
    } catch { }
}

if ($shouldHaveMarker) {
    if ($haveMarker -and $matches) { exit 0 } else { exit 1 }
} else {
    if ($haveMarker) { exit 1 } else { exit 0 }
}
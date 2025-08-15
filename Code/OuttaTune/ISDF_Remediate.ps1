# Remediate.ps1
# Writes SignalB64 and DPAPI-protected SignalProtected

#region Config
$RegPath = 'HKLM:\SOFTWARE\ISDF'
$RegNameB64 = 'SignalB64'
$RegNameProtected = 'SignalProtected'
$ImdsApiVersion = '2021-02-01'
#endregion

function Get-DeviceMfrModel {
    $ctrlKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\SystemInformation'
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

function Protect-Text {
    param([Parameter(Mandatory=$true)][string]$PlainText)
    $sec  = ConvertTo-SecureString -String $PlainText -AsPlainText -Force
    $blob = $sec | ConvertFrom-SecureString   # DPAPI (SYSTEM when run by Intune Remediations)
    $blob
}

# --- main ---
$hw      = Get-DeviceMfrModel
$compute = Get-ImdsCompute
$json    = Build-SignalJson -Hw $hw -Compute $compute
$b64     = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($json))
$prot    = Protect-Text -PlainText $json

if (-not (Test-Path -Path $RegPath)) {
    New-Item -Path $RegPath -Force | Out-Null
}

New-ItemProperty -Path $RegPath -Name $RegNameB64       -Value $b64  -PropertyType String -Force | Out-Null
New-ItemProperty -Path $RegPath -Name $RegNameProtected -Value $prot -PropertyType String -Force | Out-Null

exit 0
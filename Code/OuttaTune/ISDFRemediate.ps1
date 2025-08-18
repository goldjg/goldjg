# ISDFRemediate.ps1
# Ensures baseline registry is present and stores protected channel.
# PS 5.1 compatible.

# ------------------------------
# Force 64-bit Bootstrap
# ------------------------------
if ($env:PROCESSOR_ARCHITEW6432 -and -not $env:CI_RUN_IN_64BIT) {
    $env:CI_RUN_IN_64BIT = '1'
    $argList = $MyInvocation.UnboundArguments | ForEach-Object {
        if ($_ -is [string] -and $_.Contains(' ')) { '"{0}"' -f $_ } else { $_ }
    }
    $ps64 = Join-Path $env:WINDIR 'SysNative\WindowsPowerShell\v1.0\powershell.exe'
    & $ps64 -NoProfile -ExecutionPolicy Bypass -File $MyInvocation.MyCommand.Path @argList
    exit $LASTEXITCODE
}

$ErrorActionPreference = 'SilentlyContinue'

# ------------------------------
# Config
# ------------------------------
$IMDSApiVersion = '2021-02-01'
$RegPath        = 'HKLM:\SOFTWARE\ISDF'
$RegNameProtChan= 'ChannelProtected'

# ------------------------------
# Helpers (PS 5.1 safe)
# ------------------------------
function Get-Prop {
    param($obj,[string]$name)
    if ($null -ne $obj -and $obj.PSObject.Properties[$name]) { return $obj.$name }
    return $null
}

function Get-IMDSCompute {
    try {
        $hdr = New-Object 'System.Collections.Generic.Dictionary[string,string]'
        $hdr.Add('Metadata','true')
        $uri = "http://169.254.169.254/metadata/instance?api-version=$IMDSApiVersion"
        $raw = Invoke-RestMethod -Headers $hdr -Method GET -Uri $uri -TimeoutSec 2
        return (Get-Prop $raw 'compute')
    } catch { $null }
}

function Get-ChannelFromIMDS {
    param($compute)

    $channel = 'Unknown'
    if ($null -eq $compute) { return $channel }

    $tagsList = @()
    if ($compute.PSObject.Properties['tagsList']) {
        $tagsList = @($compute.tagsList)
    }

    $sourceArm = $null
    foreach ($t in $tagsList) {
        if ($t -like '*origin.sourcearmid.0*') { $sourceArm = $t; break }
    }

    if ($sourceArm -and ($sourceArm -match 'value=([^}]*)')) {
        $val = $Matches[1]
        if ($val -match '/subscriptions/00000000-0000-0000-0000-000000000000($|/)') { return 'Windows365' }
        if ($val -match '/providers/Microsoft\.DevCenter')             { return 'DevBox' }
        if ($val -match '/providers/Microsoft\.DesktopVirtualization') { return 'AVD' }
        if ($val -match '/providers/Microsoft\.DevTestLab')            { return 'DevTestLab' }
    }

    return $channel
}

function Protect-Text {
    param([Parameter(Mandatory=$true)][string]$Plain)
    # DPAPI (machine/SYSTEM) via SecureString
    $sec  = ConvertTo-SecureString -String $Plain -AsPlainText -Force
    $blob = $sec | ConvertFrom-SecureString
    return $blob
}

# ------------------------------
# Ensure baseline + write protected channel
# ------------------------------
if (-not (Test-Path $RegPath)) {
    New-Item -Path $RegPath -Force | Out-Null
}

$compute = Get-IMDSCompute
$channel = Get-ChannelFromIMDS -compute $compute
if ([string]::IsNullOrWhiteSpace($channel)) { $channel = 'Unknown' }

# Store channel protected to reduce tampering
$prot = Protect-Text -Plain $channel
New-ItemProperty -Path $RegPath -Name $RegNameProtChan -Value $prot -PropertyType String -Force | Out-Null

# Nothing else needs to be emitted for remediation; exit success
exit 0
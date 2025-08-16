# ISDF_Detect.ps1
# Emits exactly four booleans for Intune Custom Compliance:
# AzEnvOk, TenantIdOk, SystemManufacturerOk, SystemProductNamePrefixOk

# IMDS compute metadata is stamped at machine provisioning time - doesn't change thereafter unless you reprovision

# "azEnvironment": azure_environment
#   If not "AzurePublicCloud" then incorrect value or wrong hosting type (gov cloud?)
#   If not present/null - no IMDS == not a cloud PC despite anything else the host metadata in Intune/Entra say

# osProfile.computerName == hostname at provisioning time

# "tagsList": ["@{name=ms.inv.v0.backedby.origin.sourcearmid.0; value=path_to_resource_in_customer_tenant}"
#   Providers\Microsoft.DevCenter == DevBox
#   Providers\Microsoft.DevTestLab == Azure Lab Services (formerly DevTest Labs)
#   Providers\Microsoft.DesktopVirtualization == Azure Virtual Desktop (WVD too?)
#   No Providers = W365

# "tagsList": ["@{name=ms.inv.v0.backedby.origin.tenantid; value=customer_tenant_id}",

# "tagsList": ["@{name=ms.inv.v0.backedby.resourceattributes; value=companyname: company_name}",

# -------- Force 64-bit ----------
if ($env:PROCESSOR_ARCHITEW6432 -and -not $env:CI_RUN_IN_64BIT) {
    $env:CI_RUN_IN_64BIT = '1'
    & "$env:WINDIR\SysNative\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath @args
    exit $LASTEXITCODE
}
# ---------------------------------

$ErrorActionPreference = 'SilentlyContinue'

# Helpers
function Get-IMDS {
    for ($i=0; $i -lt 3; $i++) {
        try {
            return Invoke-RestMethod -Headers @{ Metadata = 'true' } -Uri 'http://169.254.169.254/metadata/instance?api-version=2021-02-01' -TimeoutSec 3
        } catch { Start-Sleep -Seconds (2 * ($i+1)) }
    }
    $null
}
function FromDoubleBase64([string]$t){
    try {
        $b1 = [Convert]::FromBase64String($t)
        $s1 = [Text.Encoding]::UTF8.GetString($b1)
        $b2 = [Convert]::FromBase64String($s1)
        [Text.Encoding]::UTF8.GetString($b2)
    } catch { $null }
}
function Unprotect-Text([string]$blob){
    try {
        $sec = ConvertTo-SecureString -String $blob
        $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
        try { [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
        finally { if ($ptr -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) } }
    } catch { $null }
}

# Live values (SystemInformation registry only)
$sysMfr  = $null
$sysProd = $null
try {
    $si = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SystemInformation' -ErrorAction Stop
    $sysMfr  = $si.SystemManufacturer
    $sysProd = $si.SystemProductName
} catch {}

# IMDS
$imds     = Get-IMDS
$azEnv    = $imds.compute.azEnvironment
$tenantId = ($imds.compute.tagsList | Where-Object { $_.name -like '*tenantid*' } | Select-Object -First 1).value

# Expected (from ISDF hive)
$regPath = 'HKLM:\SOFTWARE\ISDF'
$SM_v2  = $null; $SPN_v2 = $null
$SM_v1  = $null; $SPN_v1 = $null
try {
    $p = Get-ItemProperty -Path $regPath -ErrorAction Stop
    $SM_v2  = $p.SM_v2
    $SPN_v2 = $p.SPN_v2
    $SM_v1  = $p.SM
    $SPN_v1 = $p.SPN
} catch {}

# Expected plaintexts via v2 (preferred) or v1
$expSM  = $null
$expSPN = $null
if (-not [string]::IsNullOrWhiteSpace($SM_v2) -and -not [string]::IsNullOrWhiteSpace($SPN_v2)) {
    $expSM  = Unprotect-Text $SM_v2
    $expSPN = Unprotect-Text $SPN_v2
} elseif (-not [string]::IsNullOrWhiteSpace($SM_v1) -and -not [string]::IsNullOrWhiteSpace($SPN_v1)) {
    $expSM  = FromDoubleBase64 $SM_v1
    $expSPN = FromDoubleBase64 $SPN_v1
}

# IMDS-sourced checks: gating logic
# If azEnvironment is AzurePublicCloud -> evaluate both normally
# Else (including null/empty) -> mark IMDS-sourced settings as TRUE in the output JSON
$imdsActive = ([string]::IsNullOrWhiteSpace($azEnv) -eq $false) -and ($azEnv -eq 'AzurePublicCloud')

if ($imdsActive) {
    $AzEnvOk    = $true                    # explicitly AzurePublicCloud
    $TenantIdOk = ($tenantId -eq 'd980314b-cb2f-44e3-9ce7-06d7361ab382')
} else {
    # IMDS not available or not AzurePublicCloud -> do not penalize; mark IMDS checks as true
    $AzEnvOk    = $true
    $TenantIdOk = $true
}

# Manufacturer / Product prefix checks (unchanged)
$SystemManufacturerOk      = $false
$SystemProductNamePrefixOk = $false

if ($sysMfr -and $expSM -and ($sysMfr -eq $expSM)) { $SystemManufacturerOk = $true }
if ($sysProd -and $expSPN -and ($sysProd.StartsWith($expSPN))) { $SystemProductNamePrefixOk = $true }

# Emit ONLY the four keys your compliance JSON expects
[ordered]@{
    AzEnvOk = [bool]$AzEnvOk
    TenantIdOk = [bool]$TenantIdOk
    SystemManufacturerOk = [bool]$SystemManufacturerOk
    SystemProductNamePrefixOk = [bool]$SystemProductNamePrefixOk
} | ConvertTo-Json -Compress

# Exit code aligns with overall compliance (AND)
if ($AzEnvOk -and $TenantIdOk -and $SystemManufacturerOk -and $SystemProductNamePrefixOk) { exit 0 } else { exit 1 }
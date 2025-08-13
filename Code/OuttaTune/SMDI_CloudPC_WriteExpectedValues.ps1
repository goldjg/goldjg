# Remediation Script: SMDI_CloudPC_WriteExpectedValues.ps1
# Purpose: Write double-base64 encoded expected values to registry (idempotent).

# -- BEGIN Force-64bit Bootstrap --
if ($env:PROCESSOR_ARCHITEW6432 -and -not $env:CI_RUN_IN_64BIT) {
    # Mark to prevent recursion
    $env:CI_RUN_IN_64BIT = '1'
    $argList = $MyInvocation.UnboundArguments | ForEach-Object {
        if ($_ -is [string] -and $_ -contains ' ') { "`"$_`"" } else { $_ }
    }
    $ps64 = Join-Path $env:windir 'SysNative\WindowsPowerShell\v1.0\powershell.exe'
    & $ps64 -NoProfile -ExecutionPolicy Bypass -File $MyInvocation.MyCommand.Path @argList
    Exit $LASTEXITCODE
}
# -- END Force-64bit Bootstrap --

$ErrorActionPreference = 'Stop'

function DoubleBase64([string]$text) {
    $b1 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($text))
    $b2 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($b1))
    return $b2
}

# Expected plaintext values
$expectedSM  = 'Microsoft Corporation'   # exact match
$expectedSPN = 'Cloud PC'                # prefix match for SystemProductName

# Double-encode
$encSM  = DoubleBase64 $expectedSM
$encSPN = DoubleBase64 $expectedSPN

# Target registry
$baseKey = 'HKLM:\SOFTWARE\SMDI'
if (-not (Test-Path $baseKey)) {
    New-Item -Path $baseKey -Force | Out-Null
}

# Write values if missing or different
$currentSM  = (Get-ItemProperty -Path $baseKey -Name 'SM' -ErrorAction SilentlyContinue).SM
$currentSPN = (Get-ItemProperty -Path $baseKey -Name 'SPN' -ErrorAction SilentlyContinue).SPN

if ($currentSM -ne $encSM) {
    New-ItemProperty -Path $baseKey -Name 'SM' -PropertyType String -Value $encSM -Force | Out-Null
}

if ($currentSPN -ne $encSPN) {
    New-ItemProperty -Path $baseKey -Name 'SPN' -PropertyType String -Value $encSPN -Force | Out-Null
}

# Done
exit 0

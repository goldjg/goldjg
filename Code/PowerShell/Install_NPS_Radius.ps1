param (
    [Parameter(position=1,mandatory=$false)]
    [string]$RepoPath="",
    [Parameter(position=2,mandatory=$false)]
    [string]$NPSInstFile="NpsExtnForAzureMfaInstaller.exe",
    [Parameter(position=3,mandatory=$false)]
    [string]$VCRedistInstFile="vcredist_x64.exe"
)

Install-WindowsFeature -Name NPAS -IncludeManagementTools

$vcredistInstUrl = ($RepoPath+"/"+$VCRedistInstFile)
$vcredistInst = "${env:Temp}\$VCRedistInstFile"

try
{
    (New-Object System.Net.WebClient).DownloadFile($vcredistInstUrl, $vcredistInst)
}
catch
{
    Write-Error "Failed to download vcredist_x64 Install"
}

try
{
    Start-Process -FilePath $vcredistInst -ArgumentList "/install /passive /norestart"
}
catch
{
    Write-Error 'Failed to install vcredist_x64'
}

$mFAInstUrl = ($RepoPath+"/"+$NPSInstFile)
$mFAInst = "${env:Temp}\$NPSInstFile"
try
{
    (New-Object System.Net.WebClient).DownloadFile($mFAInstUrl, $mFAInst)
}
catch
{
    Write-Error "Failed to download Azure MFA Install"
}

try
{
    Start-Process -FilePath $mFAInst -ArgumentList "/Silent"
}
catch
{
    Write-Error 'Failed to install Azure MFA'
}

Register-PSRepository -Name MGPGallery -SourceLocation http://url/api/nuget/gallery -InstallationPolicy Trusted

$shortcutPath = "C:\Packages\RegisterConnector.ps1"
$installDir = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Azure AD Connect Authentication Agent" -Name "InstallDir").InstallDir
$registerConnectorPath = Join-Path $installDir "RegisterConnector.ps1"

Write-Output 'function Disable-InternetExplorerESC {' | Out-File -FilePath $shortcutPath -Encoding utf8
Write-Output '    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"' | Out-File -FilePath $shortcutPath -Encoding utf8 -Append
Write-Output '    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"' | Out-File -FilePath $shortcutPath -Encoding utf8 -Append
Write-Output '    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0' | Out-File -FilePath $shortcutPath -Encoding utf8 -Append
Write-Output '    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0' | Out-File -FilePath $shortcutPath -Encoding utf8 -Append
Write-Output '    Rundll32 iesetup.dll, IEHardenLMSettings' | Out-File -FilePath $shortcutPath -Encoding utf8 -Append
Write-Output '    Rundll32 iesetup.dll, IEHardenUser' | Out-File -FilePath $shortcutPath -Encoding utf8 -Append
Write-Output '    Rundll32 iesetup.dll, IEHardenAdmin' | Out-File -FilePath $shortcutPath -Encoding utf8 -Append
Write-Output '    Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green' | Out-File -FilePath $shortcutPath -Encoding utf8 -Append
Write-Output '}' | Out-File -FilePath $shortcutPath -Encoding utf8 -Append

Write-Output 'function Enable-InternetExplorerESC {' | Out-File -FilePath $shortcutPath -Encoding utf8 -Append
Write-Output '    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"' | Out-File -FilePath $shortcutPath -Encoding utf8 -Append
Write-Output '    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"' | Out-File -FilePath $shortcutPath -Encoding utf8 -Append
Write-Output '    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 1' | Out-File -FilePath $shortcutPath -Encoding utf8 -Append
Write-Output '    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 1' | Out-File -FilePath $shortcutPath -Encoding utf8 -Append
Write-Output '    Rundll32 iesetup.dll, IEHardenLMSettings' | Out-File -FilePath $shortcutPath -Encoding utf8 -Append
Write-Output '    Rundll32 iesetup.dll, IEHardenUser' | Out-File -FilePath $shortcutPath -Encoding utf8 -Append
Write-Output '    Rundll32 iesetup.dll, IEHardenAdmin' | Out-File -FilePath $shortcutPath -Encoding utf8 -Append
Write-Output '    Write-Host "IE Enhanced Security Configuration (ESC) has been enabled." -ForegroundColor Green' | Out-File -FilePath $shortcutPath -Encoding utf8 -Append
Write-Output '}' | Out-File -FilePath $shortcutPath -Encoding utf8 -Append
Write-Output 'Disable-InternetExplorerESC' | Out-File -FilePath $shortcutPath -Encoding utf8 -Append
Write-Output ("&'C:\Program Files\Microsoft\AzureMfa\Config\AzureMfaNpsExtnConfigSetup.ps1'") | Out-File -FilePath $shortcutPath -Encoding utf8 -Append
Write-Output 'Enable-InternetExplorerESC' | Out-File -FilePath $shortcutPath -Encoding utf8 -Append



<# New-NpsRadiusClient -Address "" -Name "" -SharedSecret (Read-Host -Prompt "Enter Shared Secret for ")

netsh nps reset crp
netsh nps add crp name = "" state = "ENABLE" processingorder = "1" conditionid = "0x20" conditiondata = "NoADAuth" conditionid = "0x1" conditiondata = "[@|\\]" profileid = "0x1025" profiledata = "0x0"
#netsh nps add crp name = "C" state = "ENABLE" processingorder = "1" conditionid = "0x100c" conditiondata = "" profileid = "0x1025" profiledata = "0x0"
#netsh nps add crp name = "" state = "ENABLE" processingorder = "2" conditionid = "0x100c" conditiondata = "" profileid = "0x1025" profiledata = "0x0"
#>
Restart-Service -Name IAS

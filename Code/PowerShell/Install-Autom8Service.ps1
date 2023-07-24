<# 
.SYNOPSIS 
  Script to install Autom8 service on a Windows Server VM
  
.DESCRIPTION 
  Download NSSM Service Wrapper (http://nssm.cc/) from software repo.
  Download Autom8-Service.ps1 core service code from repo.
  Create new windows service, Autom8, using NSSM, calling the Autom8-Service.ps1 script from within the service wrapper.
  Configure Service to run as groupManagedServiceAccount
.PARAMETER Environment
  Controls which groupManagedServiceAccount should be used to run Autom8 service
  <Optional> Default Value: "Prod"
  Valid Values: "Prod" or "NonProd"
.PARAMETER ForceNSSMInstall
  If set, forces NSSM install - if already installed, first uninstalls.
  <Optional> Default: Not Set
.PARAMETER ForceServiceCodeUpdate
  If Set, causes the service code to be redownloaded and updated,
     without reinstalling the NSSM Service Wrapper, or rebooting.
  <Optional> Default: Not Set
  #>
  Param
  (
      [Parameter(Mandatory = $false)]
      [ValidateSet("Prod","NonProd")]
      [string]$Environment = "Prod",
  
      [Parameter(Mandatory = $False)]
      [switch]$ForceNSSMInstall,
  
      [Parameter(Mandatory = $False)]
      [switch]$ForceServiceCodeUpdate
  )
  
  #############
  # Variables #
  #############
  
  $RepoBasePath = ""
  $NSSMVersion = "2.24"
  $NSSMRepoPath = "NSSM/nssm-$NSSMVersion.zip"
  $ScriptRepoPath = "scripts/Autom8/Autom8-API.ps1"
  $NSSMLocalDir = "C:\NSSM"
  $NSSMLocalPath = "$NSSMLocalDir\nssm-$NSSMVersion\win64\nssm.exe"
  $ServiceName = 'Autom8'
  $PSExePath = (Get-Command powershell).Source
  $ServiceScriptPath = 'C:\Autom8\Autom8-API.ps1'
  $ServiceArguments = '-ExecutionPolicy Bypass -NoProfile -File "{0}"' -f $ServiceScriptPath
  $LogPath = "C:\Windows\LogFiles\Autom8"
  $LogName = "Autom8.log"
  $LogRotateSeconds = "86400"
  $LogRotate = "1"
  $LogRotateOnline = "1"
  
  If ($Environment -eq "NonProd"){
    $gMSAName = "DOM\gMSASecAutom8Z01$"
  } else {
    $gMSAName = "DOM\gMSASecAutom8P01$"
  }
  
  #############
  # Functions #
  #############
  
  function Check-NSSMInstalled {
    
    Write-Host "[INFO] Checking for existence of NSSM base directory"
    If (-not (Test-Path -Path $NSSMLocalDir -PathType Container)){
        Write-Host "[INFO] Creating NSSM base directory"
        New-Item -Path $NSSMLocalDir -ItemType Container
    }  

    Write-Host "[INFO] Checking if NSSM is installed and what version number."
    try {
      $InstalledVersions = Get-ChildItem $NSSMLocalDir\*.exe -Recurse | ForEach { Get-Command $_ }
    }
    catch [ItemNotFoundException]{
      Write-Host -ForegroundColor Yellow "[INFO] All or part of $NSSMLocalDir is not present"
      $NSSMPathNotFound = $True 
    }
  
    If (-not $InstalledVersions) {
      Write-Host -ForegroundColor Yellow "[INFO] Path exists but executables are missing"
    } else {
      $InstalledVersion = $InstalledVersions.VersionInfo | where {$_.Filename -like "*win64*"} | Select -ExpandProperty ProductVersion
    }
    
    If (-not $InstalledVersion){
      Return $False
    } else {
      Return $True
    }
    
  }

  function Check-Autom8Installed{
    Write-Host "[INFO] Checking that Autom8 service code is present in $ServiceScriptPath"
    If (-not (Test-Path -Path $ServiceScriptPath -PathType Leaf)){
      If (-not( Test-Path -Path "C:\Autom8" -PathType Container)){
        New-Item -Path C:\Autom8 -ItemType Container -Force
      }
      Return $False
    } else {
    Return $True
    }
  }
  
  function DownloadFile {
    Param(
      [Parameter(Mandatory = $True)]
      [ValidatePattern("https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)")]
      [string]$WebFilePath,
  
      [Parameter(Mandatory = $True)]
      [string]$SavePath
    )
    Write-Host "[INFO] Downloading $WebFilePath to $SavePath"
    try {
      Invoke-WebRequest -Uri $WebFilePath -Method Get -OutFile $SavePath
    }
    catch {
      Throw "File Download failure downloading $WebFilePath to $SavePath"
    }
    Return $True
  }  
  
  function ExtractArchiveFile{
    Param(
      [Parameter(Mandatory = $True)]
      [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
      [string]$ArchiveFilePath,
  
      [Parameter(Mandatory = $True)]
      [string]$ExtractPath
    )
    Write-Host "[INFO] Extracting $ArchiveFilePath to $ExtractPath"  
    try {
      Unblock-File $ArchiveFilePath
      #Remove-Item $ExtractPath -Recurse -Force
      Expand-Archive $ArchiveFilePath -DestinationPath $ExtractPath -Force
    }
    catch {
      Throw "Failure extracting $ArchiveFilePath to $ExtractPath"
    }
    Return $True
  }
  
  function InstallService{
    Write-Host "[INFO] Installing Autom8 Service"
    #Create Log Dir if missing
    try{
      New-Item -Path $LogPath -ItemType Container -Force
    }
    catch{
      Write-Error "Error creating log directory $LogPath"
    }
  
    # Install NSSM service with script as the wrapped service code
    try{
      & $NSSMLocalPath install $ServiceName $PSExePath $ServiceArguments
    }
    catch{
      Throw "Error installing service $ServiceName using NSSM"
    }
  
    # Check service status via NSSM
    Try{
      & $NSSMLocalPath status $ServiceName
    }
    catch{
      Throw "Error retrieving status of $ServiceName service via NSSM"
    }
  
    Write-Host "[INFO] changing logon settings for Autom8 service to use gMSA"

    # Change logon settings to use gMSA rather than LocalSystem (the default)
    Try{
      $ServiceObject = Get-WmiObject -Class Win32_Service -Filter "Name='$ServiceName'"
      $ServiceObject.Change($null, $null, $null, $null, $null, $null, "$gMSAName", $null, $null, $null, $null)
    }
    catch{
      Throw "Error changing logon settings for $ServiceName service"
    }
  
    # Configure service logging
    Write-Host "[INFO] Setting logging options for Autom8 service"
    try{
      & $NSSMLocalPath set $ServiceName AppStdout "$LogPath\$Logname"
      & $NSSMLocalPath set $ServiceName AppStderr "$LogPath\$LogName"
      & $NSSMLocalPath set $ServiceName AppRotateFiles $LogRotate
      & $NSSMLocalPath set $ServiceName AppRotateSeconds $LogRotateSeconds
      & $NSSMLocalPath set $ServiceName AppRotateOnline $LogRotateOnline
    }
    catch{
      Throw "Error setting logging options"
    }
  
    # Start Service
    Write-Host "[INFO] Starting Autom8 service"
    try{
      Start-Service $ServiceName
    }
    catch{
      Throw "Error starting $ServiceName service"
    }
  
    # Check Service status and properties
    Write-Host "[INFO] Checking Autom8 service status"
    try{
      Get-Service $ServiceName
    }
    catch{
      Throw "Error getting status of $ServiceName service"
    }
  }
  
  function UnInstallService{
    Write-Host "[INFO] Uninstalling Autom8 service"
    # Check service status via NSSM
    Try{
      & $NSSMLocalPath stop $ServiceName
    }
    catch{
      Throw "Error stopping $ServiceName service via NSSM"
    }
  
    # Revert logon user to LocalSystem to allow removal of service via NSSM
    Try{
      & $NSSMLocalPath set $ServiceName ObjectName LocalSystem
    }
    catch{
      Throw "Error reverting logon user of $ServiceName service to LocalSystem via NSSM"
    }
  
    # Remove service via NSSM
    Try{
      & $NSSMLocalPath remove $ServiceName confirm
    }
    catch{
      Throw "Error removing $ServiceName service via NSSM"
    }
    
  }


 If ($ForceServiceCodeUpdate -or (-not (Check-Autom8Installed))){
    Write-Host "[INFO] Installing or Updating Autom8 Code"
    If (Check-Autom8Installed){ 
        Remove-Item $ServiceScriptPath -Force
    }
    DownloadFile -WebFilePath "$RepoBasePath/$ScriptRepoPath" -SavePath $ServiceScriptPath
    Restart-Service $ServiceName
}
  
If ($ForceNSSMInstall -or (-not (Check-NSSMInstalled))){
    Write-Host "[INFO] Installing or updating Autom8 service/NSSM"
    If (Check-NSSMInstalled) {
        UnInstallService
    }
    DownloadFile -WebFilePath "$RepoBasePath/$NSSMRepoPath" -SavePath "$NSSMLocalDir\nssm-$NSSMVersion.zip" -Verbose -Debug
    ExtractArchiveFile -ArchiveFilePath "$NSSMLocalDir\nssm-$NSSMVersion.zip" -ExtractPath "$NSSMLocalDir"
    InstallService
}
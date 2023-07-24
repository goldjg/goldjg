<# 
.SYNOPSIS 
  Script to install Git on a Windows Server VM
  
.DESCRIPTION 
  Download Git (https://git-scm.com/) from software repo.
  Silently Install Git
#>

#############
# Variables #
#############

$RepoBasePath = ""
$GitVersion = "2.40.1-64-bit"
$GitRepoPath = "git/client/Git-$GitVersion.exe"
$DownloadPath = "C:\Users\Public\Downloads\Git-$GitVersion.exe"

#############
# Functions #
#############

function DownloadFile {
  Param(
    [Parameter(Mandatory = $True)]
    [ValidatePattern("https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)")]
    [string]$WebFilePath,

    [Parameter(Mandatory = $True)]
    [string]$SavePath
  )

  Invoke-WebRequest -Uri $WebFilePath -Method Get -OutFile $SavePath
  
  If ($LASTEXITCODE -eq 0){
      Return $True
    } else {
    Return $False
    }
}  

DownloadFile -WebFilePath "$RepoBasePath/$GitRepoPath" -SavePath $DownloadPath
Unblock-File $DownloadPath
Start-Process $DownloadPath -ArgumentList "/VERYSILENT /LOG /LOGFILE:gitinstall.log" -Verb RunAs -Verbose
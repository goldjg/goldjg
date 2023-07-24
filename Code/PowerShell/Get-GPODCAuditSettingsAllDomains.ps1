<# 
.SYNOPSIS 
  Runs a GPO report against each of our  domains to extract Advanced Audit Policy Settings for the domain to a CSV File per domain
  You should run this as a PGDS domain user - either via a powershell session running as that user 
  	start powershell -credential ""
	(will prompt for the credentials)
  Alternatively:
  	$Credential = Get-Credential
  	$FILE = <path to the script file>
  	Start-Process powershell.exe -Credential $Credential -ArgumentList "-file $FILE"
.DESCRIPTION 
  Executes Get-GPOReport Cmdlet
.PARAMETER Domains
  <Optional> Domains     : String Array - defaults to hardcoded list in script
.PARAMETER WorkDir 
  <Optional> WorkDir     : Directory Path to create files in - defaults to C:\Temp as that tends to be accessible to all users on a system
#>
Param
(
	
    [Parameter(Mandatory = $false)]
    [String[]]$Domains = @(	"test.LOCAL",
							"test2.LOCAL"
						),

    [Parameter(Mandatory = $False)]
	[ValidateScript({Test-Path $_})]
    [String]$WorkDir = "C:\temp"

)

$MyUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

If ($MyUser -notlike "admin\*") {
	$Choice = Read-Host -Prompt "You are not running this script as an admin domain user - some domains will therefore be inaccessible.`r`nDo you still want to continue? (Y/N)"
	switch ($Choice) {
		"N" { Exit 1 }
		"n" { Exit 1 }
		"Y" { Break }
		"y" { Break }
		Default { Break }
	}
}

Foreach ($Domain in $Domains) {
    Write-Host "Getting GPO for $Domain"
	[xml]$xml = Get-GPOReport -Name "Default Domain Controllers Policy" -Domain $Domain -ReportType XML -Verbose
	
	$ShortDom = ($Domain).Split(".")[0]
    Write-Host "Getting Audit settings for $Domain and exporting to CSV file"
    $xml.gpo.Computer.ExtensionData.Extension.AuditSetting | Select-Object PolicyTarget,SubcategoryName,SettingValue | Export-Csv -NoTypeInformation -Path ($WorkDir+"\"+$ShortDom+"_DC_Audit_Settings.csv") -Verbose

    Remove-Variable xml -ErrorAction SilentlyContinue
}
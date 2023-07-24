<# 
.SYNOPSIS 
  Runs a GPO report against each of our domains to extract PAM Settings to a CSV File per domain
  You should run this as an admin domain user - either via a powershell session running as that user 
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

$DomainCount = $Domains.Count

Foreach ($Domain in $Domains) {
    
	$outarray = @()

	$CurrentDomain+=1
	Write-Progress -Id 1 "Processing domain $CurrentDomain of $DomainCount"

	Write-Host "Getting PAM GPOs for $Domain domain..."
	
	$PAMGPOs = Get-Gpo -Domain $Domain -Verbose -All | Where-Object { 
		($_.DisplayName -like "1*") -or ($_.DisplayName -like "*2*") -or ($_.DisplayName -like "*3*")
	} | Select-Object DisplayName,Id

	If ($PAMGPOs.Count -gt 0){

	$MatchingGPOs = $PAMGPOs.Count
	Write-Host "Found $MatchingGPOs PAM GPO(s)..."
	
	$CurrentGPO = 0

	ForEach ($GPOName in $PAMGPOs){
		
		$obj = New-Object System.Object

		$CurrentGPO+=1
		Write-Progress -Id 0 "Processing GPO $CurrentGPO of $MatchingGPOs in domain $Domain"

		Write-Host "Checking $($GPOName.DisplayName)"
		[xml]$Xml = Get-GPOReport -Guid $GPOName.Id -ReportType xml -Domain $Domain
		$ApplyMachineGroups = $XML.GPO.SecurityDescriptor.SDDL.'#text' | ConvertFrom-SddlString | Select -Expand DiscretionaryAcl | Select-String "a" | Select-Object -ExpandProperty Line | Where-Object {$_ -notlike "*Denied*"}
		If ($ApplyMachineGroups.Length -gt 0) {
			Write-Verbose "GPO has the following Machine Groups which apply GPO to group member servers:"
			Write-Verbose "$($ApplyMachineGroups -split ':' | Select-String "a")"
		} else {
			Write-Verbose "GPO has no Machine Groups which apply GPO to servers via group membership"
			$ApplyMachineGroups = "None"
		}

		$DenyMachineGroups = $XML.GPO.SecurityDescriptor.SDDL.'#text' | ConvertFrom-SddlString | Select -Expand DiscretionaryAcl | Select-String "a" | Select-Object -ExpandProperty Line | Where-Object {$_ -like "*Denied*"}
		If ($DenyMachineGroups.Length -gt 0) {
			Write-Verbose "GPO has the following Machine Groups which deny GPO to group member servers:"
			Write-Verbose "$($DenyMachineGroups -split ':' | Select-String "a")"
		} else {
			Write-Verbose "GPO has no Machine Groups which deny GPO to servers via group membership"
			$DenyMachineGroups = "None"
		}

		If ( $XML.GPO.InnerXML -like "*RestrictedGroups*") { 
			$RestrictedGroups = $xml.GPO.Computer.ExtensionData.Extension.RestrictedGroups.Member.Name.'#text'
			Write-Verbose "Restricted Groups - Local Administrators Members:"
			Write-Verbose "$RestrictedGroups"
			
		}

		If ( $XML.GPO.InnerXML -like "*LocalUsersAndGroups*") { 
			$LocalUsersAndGroups = $xml.GPO.Computer.ExtensionData.Extension.LocalUsersAndGroups.Group.Properties.Members.Member.Name
			Write-Verbose "Preference Groups - Local Administrators Members:"
			Write-Verbose "$LocalUsersAndGroups"
		}

		$GroupName = $($ApplyMachineGroups -split ':' -split '\\' | Select-String "SRV" | Select-Object -ExpandProperty Line -Unique)  -split " " | Where-Object { $_ -notlike "*Exception" }

		If ($GroupName.Length -gt 0){
			$MachinesInGroupFQDN = Get-ADGroupMember -Server $Domain -Identity "$GroupName" | ForEach { 
									Get-ADComputer -Server $Domain -Identity $_.Name 
								} | Select-Object -ExpandProperty DNSHostName
								} else {
									$MachinesInGroupFQDN = ""
								}

		If ($GroupName.Length -gt 0){
			$MachinesInGroupDN = $(Get-ADGroupMember -Server $Domain -Identity "$GroupName" | Select-Object -ExpandProperty distinguishedName)
		} else {
			$MachinesInGroupDN = ""
		}

		$obj | Add-Member -MemberType NoteProperty 	-Name Domain  					-Value "$Domain"
		$obj | Add-Member -MemberType NoteProperty 	-Name PolicyName				-Value $GPOName.DisplayName
		$obj | Add-Member -MemberType NoteProperty 	-Name PolicyGuid				-Value $GPOName.Id
		$obj | Add-Member -MemberType NoteProperty 	-Name RestrictedGroupMembers  	-Value "$RestrictedGroups"
		$obj | Add-Member -MemberType NoteProperty 	-Name PreferenceGroupMembers  	-Value "$LocalUsersAndGroups"
		$obj | Add-Member -MemberType NoteProperty 	-Name ApplyMachineGroups  		-Value "$ApplyMachineGroups"
		$obj | Add-Member -MemberType NoteProperty 	-Name "MachinesInGroup(FQDN)"	-Value "$MachinesInGroupFQDN"
		$obj | Add-Member -MemberType NoteProperty 	-Name "MachinesInGroup(DN)"		-Value "$MachinesInGroupDN"
		$outarray += $obj
		$ApplyMachineGroups=$DenyMachineGroups=$LocalUsersAndGroups=$MachinesInGroupDN=$MachinesInGroupFQDN=$RestrictedGroups=""
	}
		$outarray | Export-CSV -NoTypeInformation -Delimiter "," -Path $WorkDir\"$($Domain.Split('.')[0])_PAM_Out.csv"
		Remove-Variable obj, outarray
	} else {
		Write-Host "No PAM GPOs found in domain $Domain"
	}
}
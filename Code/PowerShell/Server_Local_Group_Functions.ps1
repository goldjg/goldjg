Function Get-LocalGroupMember {
    param (
      [Parameter(Mandatory=$false)][string]$Computername=$env:COMPUTERNAME,
      [Parameter(Mandatory=$false)][string]$LocalGroupName="Administrators",
      [Parameter(Mandatory=$false)][bool]$Output
      )
    
        $Group = [ADSI]("WinNT://$ComputerName/$LocalGroupName,group") 
     
        $Group.Members() | 
            foreach { 
                $AdsPath = $_.GetType().InvokeMember('Adspath', 'GetProperty', $null, $_, $null) 
                $a = $AdsPath.split('/',[StringSplitOptions]::RemoveEmptyEntries) 
                $Names = $a[-1]  
                $Domain = $a[-2] 
                If ($Output -eq $true) {
                    Write-Host ("""" + $ComputerName + ""","""+$LocalGroupName + """,""" + $Domain + "/" + $Names + """")
                }
            } 
        If($Output -eq $False) {Return $Group}
    }

Function Add-LocalGroupMember {
    param (
        [Parameter(Mandatory=$false)][string]$Computername=$env:COMPUTERNAME,
        [Parameter(Mandatory=$false)][string]$LocalGroupName="Administrators",
        [Parameter(Mandatory=$true)][string]$MemberName
        )
    
        $Group = [ADSI]("WinNT://$ComputerName/$LocalGroupName")
        $MemberName=$MemberName.Replace("\","/")
        Write-Host "Adding $MemberName to $ComputerName/$LocalGroupName"
        $Group.Add("WinNT://$MemberName")
    }
    
Function Remove-LocalGroupMember {
    param (
        [Parameter(Mandatory=$false)][string]$Computername=$env:COMPUTERNAME,
        [Parameter(Mandatory=$false)][string]$LocalGroupName="Administrators",
        [Parameter(Mandatory=$true)][string]$MemberName
        )
    
        $Group = [ADSI]("WinNT://$ComputerName/$LocalGroupName")
        $MemberName=$MemberName.Replace("\","/")
        Write-Host "Removing $MemberName from $ComputerName/$LocalGroupName"
        $Group.Remove("WinNT://$MemberName")
    }
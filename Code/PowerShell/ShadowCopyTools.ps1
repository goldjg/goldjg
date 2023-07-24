#region Get-ShadowCopy
function Get-ShadowCopy()
{
    <#
    .SYNOPSIS
       Function used to list shadow copies of a volume.
      
    .DESCRIPTION
       Function used to list shadow copies of a volume. Command should requires administrator privileges.
             
    .EXAMPLE
        Get-ShadowCopy -ComputerName localhost
       
    Description
    -----------
    Command will list all shadow copies of a volume.
    #>  

    Param(
          [Parameter(Position=0, 
                     Mandatory=$false)]
          [string] $ComputerName = "localhost",
          [Parameter(Mandatory=$false)]
          [string] $Id
        )

    #if( Test-IsAdmin )
    {
        $shadowCopies = Get-WMIObject -Class Win32_ShadowCopy -Computer $ComputerName

        $copies = @()

        foreach( $c in $shadowCopies)
        {
            $tmp = get-driveletter $c.volumename $ComputerName
            $c | Add-Member -MemberType NoteProperty -Name Drive -Value $tmp

            $tmp = $c.ConvertToDateTime($c.InstallDate)
            $c | Add-Member -MemberType NoteProperty -Name Date -Value $tmp

            $copies += $c
        }

        if ($PSBoundParameters.ContainsKey('Id'))
        {
            $copies | Where-Object { $_.Id -eq $Id } | Select-Object -Property Id, Date, Drive
        }
        else
        {
            $copies | Select-Object -Property Id, Date, Drive
        }
   # }
    #else
    #{
    #    Write-Error "This command should be run with administrator level access."
    #}
}
#endregion

#region New-ShadowCopy
function New-ShadowCopy()
{
    <#
    .SYNOPSIS
       Function used to create a shadow copy of a volume.
      
    .DESCRIPTION
       Function used to create a shadow copy of a volume. Command should requires administrator privileges.
             
    .EXAMPLE
        New-ShadowCopy -Drive c: -ComputerName localhost
       
    Description
    -----------
    Command will create a shadow copy of a volume.
    #>  

    Param(
          [Parameter(Position=0, 
                     Mandatory=$true)]
        [string] $Drive,
          [Parameter(Position=1, 
                     Mandatory=$false)]
        [string] $ComputerName = "localhost"
        )

    if( Test-IsAdmin )
    {
        $s = (gwmi -List Win32_ShadowCopy -ComputerName $ComputerName).Create($Drive + "\", "ClientAccessible")
        $id = $s.GetPropertyValue("ShadowID")
        Get-ShadowCopy -Id $id
    }
    else
    {
        Write-Error "This command should be run with administrator level access."
    }
}
#endregion

#region Remove-ShadowCopy
function Remove-ShadowCopy()
{
    <#
    .SYNOPSIS
       Function used to remove a shadow copy.
      
    .DESCRIPTION
       Function used to remove a shadow copy. Command should requires administrator privileges.
             
    .EXAMPLE
        Remove-ShadowCopy -Id shadowcopyid
          
    Description
    -----------
    Command will remove a shadow copy.
    #>  

    Param(
          [Parameter(Position=0, 
                     Mandatory=$true, 
                     ValueFromPipeline=$true,
                     ValueFromPipelineByPropertyName=$true)]
                        [String[]]$Id,
          [Parameter(Position=1, 
                     Mandatory=$false)]
          [string] $ComputerName = "localhost"
        )

    Begin {}

    Process
    {
        if( Test-IsAdmin )
        {
            $shadowCopies = Get-WMIObject -Class Win32_ShadowCopy -Computer $ComputerName
            foreach( $sc in $shadowCopies)
            {
                if( $sc.ID -eq $Id)
                {
                    $sc.Delete()
                }
            }
        }
        else
        {
            Write-Error "This command should be run with administrator level access."
        }
    }
    
    End {}    
}
#endregion

#region Mount-ShadowCopy
function Mount-ShadowCopy()
{
    <#
    .SYNOPSIS
       Function used to mount a shadow copy of a volume to a folder.
      
    .DESCRIPTION
       Function used to mount a shadow copy of a volume to a folder. Target directory must not exist. Command should requires administrator privileges.
             
    .EXAMPLE
        Mount-ShadowCopy -Id shadowcopyid -Path c:\shadowcopy
       
    Description
    -----------
    Command will mount a shadow copy to a folder.
    #>  

    Param(
          [Parameter(Position=0, 
                     Mandatory=$true, 
                     ValueFromPipeline=$true,
                     ValueFromPipelineByPropertyName=$true)]
                        [String]$Id,
        [string] $Path
        )
    
    if( Test-IsAdmin )
    {
        if( Test-Path $Path )
        {
            Write-Error "Destination already exists."
        }
        else
        {
            $s2 = gwmi Win32_ShadowCopy | ? { $_.ID -eq $ID }
            $d  = $s2.DeviceObject + "\"
            cmd /c mklink /d $Path $d
        }
    }
    else
    {
        Write-Error "Command must be run with administrator level access."
    }
}
#endregion

#region Unmount-ShadowCopy
function Unmount-ShadowCopy()
{
    <#
    .SYNOPSIS
       Function used to unmount a shadow copy of a volume from a folder.
      
    .DESCRIPTION
       Function used to unmount a shadow copy of a volume from a folder. Command should requires administrator privileges.
             
    .EXAMPLE
        Unmount-ShadowCopy -Path c:\shadowcopy
       
    Description
    -----------
    Command will unmount a shadow copies from a folder.
    #>  

    Param(
          [Parameter(Position=0, 
                     Mandatory=$true)]
                        [String]$Path
        )

    if( Test-IsAdmin )
    {
        #Test if target path exists and is a directory
        if( Test-Path($Path) -PathType Container)
        {
           $p = resolve-path $Path    

           cmd /c rd "$p"
        }
        else
        {
            Write-Error "Target path does not exist or is not a directory."
        }
    }
    else
    {
        Write-Error "Command must be run with administrator level access."
    }
}
#endregion

#region Helper Functions that are not exposed
Function Test-IsAdmin   
{  
<#
.SYNOPSIS
   Function used to detect if current user is an Administrator.
      
.DESCRIPTION
   Function used to detect if current user is an Administrator.
             
.EXAMPLE
    Test-IsAdmin
       
    
Description
-----------
Command will check the current user to see if an Administrator.
#>  
    [cmdletbinding()]  
    Param()  
      
# Write-Verbose "Checking to see if current user context is Administrator"
    If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))  
    {  
        return $false
    }  
    Else   
    {  
        return $true
    }  
}

# This function returns the driveletter of a volume givven the volume id
function get-driveletter()
{
    Param(
        [string] $VolumeID,
        [string] $ComputerName = "localhost"
        )

    $var = Get-WMIObject -Class Win32_Volume -ComputerName $ComputerName
    $var2 = $var | Where-Object {$_.deviceid -eq $VolumeID }
    return $var2.driveletter
}
#endregion

#region Exports
Export-ModuleMember -function New-ShadowCopy
Export-ModuleMember -function Get-ShadowCopy
Export-ModuleMember -function Remove-ShadowCopy
Export-ModuleMember -function Mount-ShadowCopy
Export-ModuleMember -function Unmount-ShadowCopy
#endregion
Contact UsTerms of UsePrivacy PolicyGallery StatusFeedbackFAQs© 2021 Microsoft Corporation
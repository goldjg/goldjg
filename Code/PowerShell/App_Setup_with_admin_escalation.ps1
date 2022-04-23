<#
Elevation code from the blog below - slightly modified to suppress output from the starting of the elevated process on the console.
https://blogs.msdn.microsoft.com/virtual_pc_guy/2010/09/23/a-self-elevating-powershell-script/
#>
# Get the ID and security principal of the current user account
 $myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
 $myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
  
 # Get the security principal for the Administrator role
 $adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
  
 # Check to see if we are currently running "as Administrator"
 if ($myWindowsPrincipal.IsInRole($adminRole))
    {
    # We are running "as Administrator" - so change the title and background color to indicate this
    $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
    $Host.UI.RawUI.BackgroundColor = "DarkBlue"
    clear-host
    }
 else
    {
    # We are not running "as Administrator" - so relaunch as administrator
    
    # Create a new process object that starts PowerShell
    $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
    
    # Specify the current script path and name as a parameter
    $newProcess.Arguments = $myInvocation.MyCommand.Definition;
    
    # Indicate that the process should be elevated
    $newProcess.Verb = "runas";
    
    # Start the new process
    [System.Diagnostics.Process]::Start($newProcess)|Out-Null;
    
    # Exit from the current, unelevated, process
    exit
    }
   
 # Run the code that needs to be elevated here

#Setup paths for APP and home drive
$APPPath="\\##REDACTED##\APP"
$PersonalPath="\\" + $ENV:HomeDataServer + "\" + $env:USERNAME

#run APP.EXE to register all required libraries
Write-Host "Running APP.EXE to register"
& ($APPPath + "\APP.EXE")

#check there's an APPUSER.INI in user home drive, otherwise copy in from APPCCF path.
If (!(Test-Path ($PersonalPath +"\APPUSER.INI"))){
    Write-Host "APPUSER.INI doesn't exist in home drive, so copying in default"
    copy-item ($APPPath + "\APPUSER.INI") ($PersonalPath + "\APPUSER.INI")
    }

Write-Host "APP Setup complete - please run $APPPath\APPDEBUG.EXE"

<# Check we are running in a console host and not an ISE console
    - if console host, use readkey to pause until key pressed before exit
    - otherwise, just sleep for 10 seconds then exit #>
If ($host.Name -notcontains "ISE"){
    Write-Host "Press any key to exit"
    $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")}
    else
    {sleep -s 10}
exit
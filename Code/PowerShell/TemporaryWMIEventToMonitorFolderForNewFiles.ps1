# -----------------------------------------------------------------------------
# Script: TemporaryWMIEventToMonitorFolderForNewFiles.ps1
# Author: ed wilson, msft
# Date: 07/13/2012 16:05:50
# Keywords: WMI, Events and Monitoring
# comments: creates temporary event consumer to watch files. Also has a function
# to cleanup events and subscribers after running the script.
# hsg-7-17-2012
# -----------------------------------------------------------------------------
$query = @"
 Select * from __InstanceCreationEvent within 10 
 where targetInstance isa 'Cim_DirectoryContainsFile' 
 and targetInstance.GroupComponent = 'Win32_Directory.Name="c:\\\\test"'
"@
Register-WmiEvent -Query $query -SourceIdentifier "MonitorFiles"
$fileEvent = Wait-Event -SourceIdentifier "MonitorFiles"
$fileEvent.SourceEventArgs.NewEvent.TargetInstance.PartComponent

Function Remove-WMIEventAndSubscriber
{
 Get-EventSubscriber | Unregister-Event
 Get-Event | Remove-Event
} #end function Remove-WmiEventAndSubscriber
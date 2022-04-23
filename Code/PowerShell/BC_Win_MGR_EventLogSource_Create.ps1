# ----------------------------------------------------------------------------- 
# CreateEventLogSources.ps1 
# AUTHOR: Ken O. Bonn 
# DATE: 03/29/2014 
# PURPOSE: Ensure Event Logs and Sources exist for application "MyApplication" to write events to. 
# NOTES: (1)The only customization required is to specify your event log, source pair. 
# (2)This can be run from a command prompt as below, assuming policy allows that 
# PowerShell.exe -File CreateEventLogSources.ps1 
# ----------------------------------------------------------------------------- 
# 
# ----------------------------------------------------------------------------- 
# CREATE EVENT LOG SOURCES IF THEY DO NOT EXIST. 
# ----------------------------------------------------------------------------- 
# 
#eventSources is an array of comma delimited strings containing the Event Log followed by the event source.  
$eventSources = @("Application,BC_Win_MGR")  
                   
#Loop through each event log,source pair to create the source on the specified log if it does not exist.  
    foreach($logSource in $eventSources) { 
        $log = $logSource.split(",")[0] 
        $source = $logSource.split(",")[1] 
        if ([System.Diagnostics.EventLog]::SourceExists($source) -eq $false) { 
            write-host "Creating event source $source on event log $log" 
            [System.Diagnostics.EventLog]::CreateEventSource($source, $log) 
            write-host -foregroundcolor green "Event source $source created" 
            } else { 
            write-host -foregroundcolor yellow "Warning: Event source $source already exists. Cannot create this source on Event log $log" 
            } 
    }  
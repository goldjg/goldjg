# The following example demonstrates reading the Output Manager log file 
#  looking for all PrintComplete log entries within the last 24 hours.

add-type -path .\Interface.dll
add-type -path .\eomlogging.dll


     # Get today's date/time.
     #DateTime today = DateTime.Now;
     # Get yesterday's date/time.
     #DateTime yesterday = new DateTime(today.AddDays(-1).Ticks);
     # Specify the log entry filter - only want to see Print Complete log entries.
     $filter = New-Object -TypeName System.Collections.ArrayList;
     
     get-member -inputobject $filter;
     
     #$filter.Add([Interface]::OutputMgr.Logging.LogEntryType.PrintComplete);
     
     # Get the LogReader object.
     
     #$logreader = New-Object -TypeName OutputMgr.Logging.LogReader(
     #   "\\lgrdcpsrv87\e$\server\apps\Unisys\Enterprise Output Manager\LogFiles\",
     #   yesterday,       # Specify start date/time
     #   today,           # Specify end date/time
     #   false,           # UTC time?
     #   filter);         # Filter specifies PrintComplete log entries
     #foreach (object $logEntry in $logreader)
     #{
     #   # Print Complete log entry.
     #   if ($logEntry is OutputMgr.Logging.IPrintCompleteV1)
     #   {
     #       OutputMgr.Logging.IPrintCompleteV1 log = (OutputMgr.Logging.IPrintCompleteV1)logEntry;
     #       # Add your code here to process log entry ...
     #    }
     # } # End for loop.


Imports System.Text.RegularExpressions
Imports System.IO
'################################################################################################
'# EOM Logger written by Graham Gold (##REDACTED##) 2012                                        #
'# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                                                #
'#                                                                                              #
'# VB.NET Console Application that uses Unisys Enterprise Output Manager API (eomlogging.dll)   #
'#  to produce extracts of EOM logs in CSV format for easy analysis in MS Excel                 #
'#                                                                                              #
'# Runs from command prompt (must be in path, or use path to executable when calling).          #
'#                                                                                              #
'# If ran with '-help' or '/?' parameters, displays help screen with usage information.         #
'#                                                                                              #
'# Can be ran with -mode=, -loghost=, -logtype=, -outdir=, -startdate= and -enddate= parameters #
'# or if ran with no parameters, will prompt for input (interactive mode)                       #
'#                                                                                              #
'# VERSION 0.1  Initial Implementation      ##REDACTED## GXG NOV 2012                           #
'#                                                                                              #
'################################################################################################
Module Module1

    Sub Main(ByVal arguments() As String)

        'Dimension main variables
        Dim InterInput As String
        Dim Batch As Boolean = False
        Dim Interactive As Boolean = False
        Dim Mode As String
        Dim LogType As String
        Dim LogHost As String
        Dim OutDir As String
        Dim StartDate As String
        Dim EndDate As String
        Dim logPath As String
        Dim logOutputPath As String
        Dim ValidatedStartDate As DateTime
        Dim ValidatedEndDate As DateTime
        Dim thisMonth As New DateTime(DateTime.Today.Year, DateTime.Today.Month, 1)
        Dim firstDayLastMonth As DateTime
        Dim lastDayLastMonth As DateTime
        Dim filter As System.Collections.ArrayList = New System.Collections.ArrayList()

        Console.Clear()

        'If there are no arguments, we need to prompt for input
        If arguments.Length = 0 Then
            Console.WriteLine("No parameters passed, switching to interactive mode")
            Console.WriteLine()

            '####################
            '# INTERACTIVE MODE #
            '####################
            Interactive = True
            'Check hostname, if one of the EOM servers, set mode to local
            Select Case System.Environment.MachineName
                Case "##REDACTED##"
                    Mode = "Local"
                    LogHost = System.Environment.MachineName
                Case "##REDACTED##"
                    Mode = "Local"
                    LogHost = System.Environment.MachineName
                Case "##REDACTED##"
                    Mode = "Local"
                    LogHost = System.Environment.MachineName
                Case Else
                    'Not running on an EOM server, set mode to remote
                    Mode = "Remote"

                    'Prompt user to select remote server to be logged
                    Dim RemSrv As String
                    Console.Write("What server to log (1=##REDACTED##,2=##REDACTED##,3=##REDACTED##)? ")
                    Console.WriteLine()

                    Do Until (RemSrv = "1" Or RemSrv = "2" Or RemSrv = "3")
                        RemSrv = Console.ReadKey(True).KeyChar
                    Loop

                    Select Case RemSrv
                        Case "1"
                            LogHost = "##REDACTED##"
                        Case "2"
                            LogHost = "##REDACTED##"
                        Case "3"
                            LogHost = "##REDACTED##"
                    End Select
            End Select

            'Prompt user to select log entry type to be extracted
            Dim InputLogOpt As String
            Console.Write("What Log Type (1=PrintComplete, 2=TransferComplete)? ")
            Console.WriteLine()

            Do Until (InputLogOpt = "1" Or InputLogOpt = "2")
                InputLogOpt = Console.ReadKey(True).KeyChar
            Loop

            Select Case InputLogOpt
                Case "1"
                    LogType = "PrintComplete"
                Case "2"
                    LogType = "TransferComplete"
            End Select

            'Prompt user for output directory (blank = default)
            InterInput = Nothing
            Console.Write("Where should the output be saved?" & vbCrLf & vbTab & "(Leave blank for default) ")
            Console.WriteLine()
            InterInput = Console.ReadLine()
            If Not InterInput = Nothing Then
                OutDir = InterInput
            End If

            'Prompt user for start date
            InterInput = Nothing
            Console.Write("What is the start date in dd/mm/yyyy format?" & vbCrLf & vbTab & "(Leave blank to log every day last month)")
            Console.WriteLine()
            InterInput = Console.ReadLine()
            StartDate = InterInput

            'If start date supplied, also prompt for end date
            If Not InterInput = Nothing Then
                InterInput = Nothing
                Console.Write("What is the end date in dd/mm/yyyy format?" & vbCrLf & vbTab & "(Leave blank to log until 23:59:59 tonight) ")
                Console.WriteLine()
                InterInput = Console.ReadLine()
                EndDate = InterInput
            End If
        End If

        'If at least one argument, parse them

        If arguments.Length > 0 Then
            If arguments.Length = 1 Then
                'Single argument means help mode

                '#############
                '# HELP MODE #
                '#############

                Select Case arguments(0).ToLower
                    Case "-help"
                        If Console.WindowHeight < 40 Then
                            Console.SetWindowSize(Console.WindowWidth, 40)
                        End If
                        Console.Clear()
                        Console.WriteLine("-----------------------------------------------------")
                        Console.WriteLine("EOM Logger v 0.1 created by Graham Gold (C) ##REDACTED## 2012")
                        Console.WriteLine("-----------------------------------------------------")
                        Console.WriteLine("Usage:  eomlogger -mode=[local/remote] -loghost=[<servername>]")
                        Console.WriteLine("                     -logtype=[printcomplete/transfercomplete] -outdir=[]")
                        Console.WriteLine("                     -startdate=[dd/mm/yyyy] -enddate=[dd/mm/yyyy]")
                        Console.WriteLine()
                        Console.WriteLine("*** Runs in interactive mode if no parameters are passed ***")
                        Console.WriteLine()
                        Console.WriteLine("Options:")
                        Console.WriteLine(vbTab & "-mode=" & vbTab & vbTab & "Read logs on LOCAL host or REMOTE host")
                        Console.WriteLine()
                        Console.WriteLine(vbTab & "-loghost=" & vbTab & "Name of server hosting logs. Valid only in REMOTE mode")
                        Console.WriteLine()
                        Console.WriteLine(vbTab & "-logtype=" & vbTab & "Log type to extract")
                        Console.WriteLine(vbTab & vbTab & vbTab & "Only PRINTCOMPLETE or TRANSFERCOMPLETE supported")
                        Console.WriteLine()
                        Console.WriteLine(vbTab & "-outdir=" & vbTab & "Output directory")
                        Console.WriteLine(vbTab & vbTab & vbTab & "Default:")
                        Console.WriteLine(vbTab & vbTab & vbTab & "##REDACTED##")
                        Console.WriteLine()
                        Console.WriteLine(vbTab & "-startdate=" & vbTab & "Start of log range in dd/mm/yyyy format.")
                        Console.WriteLine(vbTab & vbTab & vbTab & "Start date must be supplied if no end date is supplied.")
                        Console.WriteLine(vbTab & vbTab & vbTab & "If neither is supplied, default log range is ")
                        Console.WriteLine(vbTab & vbTab & vbTab & "1st day of last month at 00:00:00 until last" & vbCrLf & vbTab & vbTab & vbTab & "day of last month at 23:59:59.")
                        Console.WriteLine()
                        Console.WriteLine(vbTab & "-enddate=" & vbTab & "End of log range in dd/mm/yyyy format.")
                        Console.WriteLine(vbTab & vbTab & vbTab & "If start date supplied but not end date, defaults to" & vbCrLf & vbTab & vbTab & vbTab & "today at 23:59:59.")
                        Console.WriteLine()
                        Console.WriteLine(vbTab & "-help or /?" & vbTab & "Help Mode , shows this prompt")
                        Console.ReadKey(True)
                        Exit Sub
                    Case "/?"
                        If Console.WindowHeight < 40 Then
                            Console.SetWindowSize(Console.WindowWidth, 40)
                        End If
                        Console.Clear()
                        Console.WriteLine("-----------------------------------------------------")
                        Console.WriteLine("EOM Logger v 0.1 created by Graham Gold (C) ##REDACTED## 2012")
                        Console.WriteLine("-----------------------------------------------------")
                        Console.WriteLine("Usage:  eomlogger -mode=[local/remote] -loghost=[<servername>]")
                        Console.WriteLine("                     -logtype=[printcomplete/transfercomplete] -outdir=[]")
                        Console.WriteLine("                     -startdate=[dd/mm/yyyy] -enddate=[dd/mm/yyyy]")
                        Console.WriteLine()
                        Console.WriteLine("*** Runs in interactive mode if no parameters are passed ***")
                        Console.WriteLine()
                        Console.WriteLine("Options:")
                        Console.WriteLine(vbTab & "-mode=" & vbTab & vbTab & "Read logs on LOCAL host or REMOTE host")
                        Console.WriteLine()
                        Console.WriteLine(vbTab & "-loghost=" & vbTab & "Name of server hosting logs. Valid only in REMOTE mode")
                        Console.WriteLine()
                        Console.WriteLine(vbTab & "-logtype=" & vbTab & "Log type to extract")
                        Console.WriteLine(vbTab & vbTab & vbTab & "Only PRINTCOMPLETE or TRANSFERCOMPLETE supported")
                        Console.WriteLine()
                        Console.WriteLine(vbTab & "-outdir=" & vbTab & "Output directory")
                        Console.WriteLine(vbTab & vbTab & vbTab & "Default:")
                        Console.WriteLine(vbTab & vbTab & vbTab & "##REDACTED##")
                        Console.WriteLine()
                        Console.WriteLine(vbTab & "-startdate=" & vbTab & "Start of log range in dd/mm/yyyy format.")
                        Console.WriteLine(vbTab & vbTab & vbTab & "Start date must be supplied if no end date is supplied.")
                        Console.WriteLine(vbTab & vbTab & vbTab & "If neither is supplied, default log range is ")
                        Console.WriteLine(vbTab & vbTab & vbTab & "1st day of last month at 00:00:00 until last" & vbCrLf & vbTab & vbTab & vbTab & "day of last month at 23:59:59.")
                        Console.WriteLine()
                        Console.WriteLine(vbTab & "-enddate=" & vbTab & "End of log range in dd/mm/yyyy format.")
                        Console.WriteLine(vbTab & vbTab & vbTab & "If start date supplied but not end date, defaults to" & vbCrLf & vbTab & vbTab & vbTab & "today at 23:59:59.")
                        Console.WriteLine()
                        Console.WriteLine(vbTab & "-help or /?" & vbTab & "Help Mode , shows this prompt")
                        Console.ReadKey(True)
                        Exit Sub
                End Select
            End If

            'More than 1 argument, so parse them

            '##############
            '# BATCH MODE #
            '##############
            Batch = True
            'paired arguments (-key=value) are listed in arguments array as follows:
            ' -key1=value1
            ' -key2=value2
            ' etc

            'loop through array items, splitting each array item in two using = character as split character
            'Regular Expressions (Regex) made available by import of System.Text.RegularExpressions .NET class at start of code
            For Each argument As String In arguments
                Dim param() As String = Regex.Split(argument, "=")
                'param(0) is the key for the current item, param(1) is the associated value
                Select Case param(0).ToLower
                    Case "-mode"
                        Mode = param(1)
                    Case "-logtype"
                        LogType = param(1)
                    Case "-loghost"
                        LogHost = param(1)
                    Case "-outdir"
                        OutDir = param(1)
                    Case "-startdate"
                        StartDate = param(1)
                    Case "-enddate"
                        EndDate = param(1)
                    Case Else
                        Console.WriteLine("ERROR: Invalid parameter - " & param(0))
                        Exit Sub
                End Select
            Next
        End If

        'Now that we've parses the parameters passed, we need to validate them
        '########################
        '# Parameter Validation #
        '########################
        'handle missing mode parameter (mandatory param)
        If Mode = Nothing Then
            Console.WriteLine("ERROR: A mode parameter must be supplied")
            Exit Sub
        End If

        'setup default output directory if outdir param not passed
        If OutDir = Nothing Then
            OutDir = "##REDACTED##"
            Console.WriteLine("No Output Directory supplied, using default of" & vbCrLf & vbTab & "##REDACTED##")
            Console.WriteLine()
        End If

        'streamwriter will not write a file in a directory that does not exist, so check existence first and give option to create
        ' Directory.Exists is a method from the system.io .NET class, imported at the start of the code
        If Directory.Exists(OutDir) Then
            Console.WriteLine("Output directory is " & OutDir)
            Console.WriteLine()
        Else
            If Not Batch Then
                Console.WriteLine("Invalid output directory: " & OutDir)
                Console.WriteLine("Would you like the directory to be created? (Y/N)")
                Console.WriteLine()

                'Get input from console user (Y or N)
                Dim YorN As String

                Do Until (YorN = "y" Or YorN = "Y" Or YorN = "n" Or YorN = "N")
                    YorN = Console.ReadKey(True).KeyChar
                Loop

                Select Case YorN.ToString.ToLower
                    Case "y"
                        If Not OutDir.Substring(OutDir.Length - 1) = "\" Then
                            OutDir = OutDir & "\"
                        End If
                        Directory.CreateDirectory(OutDir)
                    Case "n"
                        Console.Write("Press any key to continue...")
                        Console.ReadKey(True)
                        Exit Sub 'exit as streamwriter will fail if directory does not exist
                End Select
            Else
                Console.WriteLine("Invalid output directory: " & OutDir)
                Exit Sub
            End If

        End If

        'Validate mode value 
        Select Case Mode.ToLower
            Case "local" 'Can only be in local mode if running on a DEPCON/EOM server. If so, set appropriate log and output paths
                Console.WriteLine()
                Console.WriteLine("Logging Mode = Local")
                Console.WriteLine()
                Select Case System.Environment.MachineName
                    Case "##REDACTED##"
                        Console.WriteLine("Local Host is " & System.Environment.MachineName)
                        Console.WriteLine()
                        LogHost = System.Environment.MachineName
                        logPath = "E:\server\apps\Unisys\Enterprise Output Manager\LogFiles\"
                        logOutputPath = OutDir & System.Environment.MachineName & "_" & LogType.ToUpper & "_" & DateTime.Now.ToString("yyyyMMdd-HHmmss") & ".csv"
                    Case "##REDACTED##"
                        Console.WriteLine("Local Host is " & System.Environment.MachineName)
                        Console.WriteLine()
                        LogHost = System.Environment.MachineName
                        logPath = "E:\server\apps\Unisys\Enterprise Output Manager\LogFiles\"
                        logOutputPath = OutDir & System.Environment.MachineName & "_" & LogType.ToUpper & "_" & DateTime.Now.ToString("yyyyMMdd-HHmmss") & ".csv"
                    Case "##REDACTED##"
                        Console.WriteLine("Local Host is " & System.Environment.MachineName)
                        Console.WriteLine()
                        LogHost = System.Environment.MachineName
                        logPath = "E:\server\apps\Unisys\Enterprise Output Manager\LogFiles\"
                        logOutputPath = OutDir & System.Environment.MachineName & "_" & LogType.ToUpper & "_" & DateTime.Now.ToString("yyyyMMdd-HHmmss") & ".csv"
                    Case Else
                        Console.WriteLine("ERROR: Cannot use local mode if not on a DEPCON server")
                        If Interactive Then
                            Console.Write("Press any key to continue...")
                            Console.ReadKey(True)
                        End If
                        Exit Sub
                End Select

            Case "remote"
                Console.WriteLine()
                Console.WriteLine("Logging Mode = Remote")
                Console.WriteLine()
            Case Else
                Console.WriteLine("ERROR: Invalid logging mode '" & Mode & "' - Only Remote or Local are support")
                If Interactive Then
                    Console.Write("Press any key to continue...")
                    Console.ReadKey(True)
                End If
                Exit Sub
        End Select

        'Validate logtype param, accept abbreviations so e.g. print = printcomplete
        If Not LogType = Nothing Then
            If LogType.ToLower.StartsWith("print") Then
                LogType = "PrintComplete"
                Console.WriteLine("Log type = " & LogType.ToUpper)
            End If

            If LogType.ToLower.StartsWith("transfer") Then
                LogType = "TransferComplete"
                Console.WriteLine("Log type = " & LogType.ToUpper)
            End If
            If Not (LogType.ToLower.StartsWith("print") Or LogType.ToLower.StartsWith("transfer")) Then
                Console.WriteLine("ERROR: Unsupported log type - " & LogType)
                If Interactive Then
                    Console.Write("Press any key to continue...")
                    Console.ReadKey(True)
                End If
                Exit Sub
            End If
        Else
            Console.WriteLine("ERROR: LogType not supplied")
            If Interactive Then
                Console.Write("Press any key to continue...")
                Console.ReadKey(True)
            End If
            Exit Sub
        End If

        'Validate Loghost param (for remote mode). Set appropriate log and output paths
        If Not LogHost = Nothing Then
            Select Case LogHost.ToLower
                Case "##REDACTED##"
                    Console.WriteLine("Log Host = " & LogHost.ToUpper)
                    Console.WriteLine()
                    logPath = "\\" & LogHost & "\e$\server\apps\Unisys\Enterprise Output Manager\LogFiles\"
                    logOutputPath = OutDir & LogHost.ToUpper & "_" & LogType.ToUpper & "_" & DateTime.Now.ToString("yyyyMMdd-HHmmss") & ".csv"
                Case "##REDACTED##"
                    Console.WriteLine("Log Host = " & LogHost.ToUpper)
                    Console.WriteLine()
                    logPath = "\\" & LogHost & "\e$\server\apps\Unisys\Enterprise Output Manager\LogFiles\"
                    logOutputPath = OutDir & LogHost.ToUpper & "_" & LogType.ToUpper & "_" & DateTime.Now.ToString("yyyyMMdd-HHmmss") & ".csv"
                Case "##REDACTED##"
                    Console.WriteLine("Log Host = " & LogHost.ToUpper)
                    Console.WriteLine()
                    logPath = "\\" & LogHost & "\e$\server\apps\Unisys\Enterprise Output Manager\LogFiles\"
                    logOutputPath = OutDir & LogHost.ToUpper & "_" & LogType.ToUpper & "_" & DateTime.Now.ToString("yyyyMMdd-HHmmss") & ".csv"
                Case Else
                    Console.WriteLine("ERROR: Unsupported log host - " & LogHost)
                    If Interactive Then
                        Console.Write("Press any key to continue...")
                        Console.ReadKey(True)
                    End If
                    Exit Sub
            End Select
        Else
            Console.WriteLine("ERROR: LogHost not supplied")
            If Interactive Then
                Console.Write("Press any key to continue...")
                Console.ReadKey(True)
            End If
            Exit Sub
        End If

        'Display log path
        Console.Write("Output file: " & vbCrLf & logOutputPath)
        Console.WriteLine()

        'Setup datetime variables for 1st and last day of previous month
        firstDayLastMonth = thisMonth.AddMonths(-1) 'thismonth = first of this month, so deduct 1 month
        lastDayLastMonth = thisMonth.AddSeconds(-1) 'thismonthy = first of this month at midnight, so deduct 1 second

        '################
        '# Date Parsing #
        '################
        'If startdate was passed (as string), try to convert to a datetime variable
        If Not StartDate = Nothing Then
            If DateTime.TryParse(StartDate, ValidatedStartDate) Then 'datetime conversion successful
                Console.WriteLine("Start Date Format Validated OK: " & ValidatedStartDate.ToLongDateString & " " & ValidatedStartDate.ToLongTimeString)
                Console.WriteLine()
            Else 'startdate string can't be converted to datetime
                Console.WriteLine("Invalid Start Date: " & StartDate)
                If Interactive Then
                    Console.Write("Press any key to continue...")
                    Console.ReadKey(True)
                End If
                Exit Sub
            End If
        End If

        'If enddate was passed (as string), try to convert to a datetime variable
        If Not EndDate = Nothing Then
            If DateTime.TryParse(EndDate, ValidatedEndDate) Then 'datetime conversion successful so set time on this date to 23:59:00 (default = midnight)
                ValidatedEndDate = ValidatedEndDate.AddHours(23)
                ValidatedEndDate = ValidatedEndDate.AddMinutes(59)
                ValidatedEndDate = ValidatedEndDate.AddSeconds(59)
                Console.WriteLine("End Date Format Validated OK: " & ValidatedEndDate.ToLongDateString & " " & ValidatedEndDate.ToLongTimeString)
                Console.WriteLine()
            Else 'enddate string can't be converted to datetime
                Console.WriteLine("Invalid End Date: " & EndDate)
                If Interactive Then
                    Console.Write("Press any key to continue...")
                    Console.ReadKey(True)
                End If
                Exit Sub
            End If
        End If

        'Handle when no date params are passed, set date range to first and last day of previous month
        If StartDate = Nothing And EndDate = Nothing Then
            Console.WriteLine("No dates supplied, using default of 1st and Last Day of last month")
            Console.WriteLine()
            ValidatedStartDate = firstDayLastMonth
            ValidatedEndDate = lastDayLastMonth
        End If

        'Handle when an enddate is passed and no startdate is passed
        'You can't log if you don't know when to start in the logs!
        If StartDate = Nothing And Not EndDate = Nothing Then
            Console.WriteLine("ERROR: Cannot have an End Date without a Start Date")
            If Interactive Then
                Console.Write("Press any key to continue...")
                Console.ReadKey(True)
            End If
            Exit Sub
        End If

        'Handle when startdate passed but not enddate.
        ' Assume enddate = today at 23:59:59 in other words read from start date thru all logs written up till now
        If EndDate = Nothing And Not StartDate = Nothing Then
            ValidatedEndDate = DateTime.Today.Date
            ValidatedEndDate = ValidatedEndDate.AddHours(23)
            ValidatedEndDate = ValidatedEndDate.AddMinutes(59)
            ValidatedEndDate = ValidatedEndDate.AddSeconds(59)
            Console.WriteLine("Start Date supplied without an end date, using Today at 23:59:59 for End Date")
            Console.WriteLine()
        End If

        'Handle startdate in the future (BAD!)
        If DateTime.Compare(ValidatedStartDate.Date, ValidatedEndDate.Date) > 0 Then
            Console.WriteLine("ERROR: StartDate is in the future, time travel is not possible")
            If Interactive Then
                Console.Write("Press any key to continue...")
                Console.ReadKey(True)
            End If
            Exit Sub
        End If

        'Handle enddate before startdate
        If DateDiff(DateInterval.Day, ValidatedStartDate.Date, ValidatedEndDate.Date) < 0 Then
            Console.WriteLine("ERROR: End Date cannot be earlier then Start Date")
            If Interactive Then
                Console.Write("Press any key to continue...")
                Console.ReadKey(True)
            End If
            Exit Sub
        End If

        'Define streamwriter object for writing of output file
        Dim sw As System.IO.StreamWriter
        sw = Nothing

        'display logging time range
        Console.WriteLine("Logging from " & ValidatedStartDate.Date & " " & ValidatedStartDate.ToLongTimeString & " to " & ValidatedEndDate)
        Console.WriteLine()
        Console.WriteLine()
        '#####################
        '# END OF VALIDATION #
        '#####################



        '#############################################################
        '# START OF MAIN EOM API CODE - BASED ON UNISYS EXAMPLE CODE #
        '#############################################################

        'Check which logtype
        Select Case LogType.ToLower
            Case "printcomplete" 'we are logging PrintComplete log entries

                Try 'Put it in a try/catch/finally to trap any errors
                    filter.Add(OutputMgr.Logging.LogEntryType.PrintComplete) 'set the log type filter
                    sw = New System.IO.StreamWriter(logOutputPath) 'create output file

                    'write column headings to file
                    sw.Write("Date,Time,Account,Banner,EmulationType,EntryLevel,EntryType,FileNumber," _
                             & "FileType,FormType,HostFCycle,HostFileName,HostName,HostQualifier,HostQueue," _
                             & "LogicalPages,NumberBytesPrinted,NumberBytesInLogEntry,PageRange,XenosQueue," _
                             & "PhysicalPages,PhysicalPrinterName,PrintAttributeName,PrintCompletionType," _
                             & "PrintToFileName,Project,Runid,Userid")
                    sw.WriteLine()

                    ' Create the LogReader object using logpath, validated start and end dates and filter, and set UTC to false (don't interpret date range as UTC)
                    Dim lr As OutputMgr.Logging.LogReader
                    lr = New OutputMgr.Logging.LogReader(logPath, ValidatedStartDate, ValidatedEndDate, False, filter)

                    'Initialize variables used in log entry scanning
                    Dim LocDate As DateTime
                    Dim logEnTry As Object
                    Dim entries As Integer

                    'Char position in PCFileName denoting queue sub directory name start. Used pull out only that directory name
                    'Use substring function to pull out the part of string from pos 31 until the character position before the last '\' character
                    ' e.g. log.PcFileName.Substring(QPos, (log.PcFileName.LastIndexOf("\") - QPos))
                    Dim QPos As Integer = 31

                    'loop through log entries in time range
                    For Each logEnTry In lr
                        'Match PrintComplete entries
                        If TypeOf logEnTry Is OutputMgr.Logging.IPrintCompleteV1 Then
                            Dim log As OutputMgr.Logging.IPrintCompleteV1 = CType(logEnTry, OutputMgr.Logging.IPrintCompleteV1)

                            entries = entries + 1 'Increase counter for log entries found, for display on console
                            LocDate = New DateTime(log.LocalDateTime, DateTimeKind.Local) 'store log entry datetime

                            'Write line to output file.
                            'Use String.Format to setup line format, followed by items to put on the line
                            '(the log entry attributes we are interested in)
                            sw.Write(String.Format("{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10},{11},{12},{13},{14},{15},{16},{17},{18},{19},{20},{21},{22},{23},{24},{25},{26},{27}",
                                LocDate.ToShortDateString(),
                                LocDate.ToShortTimeString(),
                                log.Account,
                                log.Banner,
                                log.EmulationType,
                                log.EntryLevel,
                                log.EntryType,
                                log.FileNumber,
                                log.FileType,
                                log.FormType,
                                log.HostFCycle,
                                log.HostFileName,
                                log.HostName,
                                log.HostQualifier,
                                log.HostQueue,
                                log.LogicalPages,
                                log.NumberBytesPrinted,
                                log.NumberOfBytesInEntry,
                                log.PageRange,
                                log.PcFileName.Substring(QPos, (log.PcFileName.LastIndexOf("\") - QPos)),
                                log.PhysicalPages,
                                log.PhysicalPrinterName,
                                log.PrintAttributeName,
                                log.PrintCompletionType,
                                log.PrintToFileName,
                                log.Project,
                                log.Runid,
                                log.Userid
                                ))
                            sw.WriteLine()

                            '#############################################################
                            '# Display progress on same 2 lines each time round the loop #
                            '#############################################################
                            Console.CursorTop -= 2 'move console cursor up 2 lines
                            Console.CursorLeft = 0 'move cursor horizontal position to start of the line

                            'Write progress to console
                            Console.WriteLine("Log Entries Found: " & entries)
                            Console.WriteLine("Currently Scanning Date: " & LocDate.ToShortDateString)
                        End If
                    Next
                    ' End for loop.
                Catch e As System.Exception
                    MsgBox(e.Message, MsgBoxStyle.OkOnly, "EOM Log Reader") 'display error as a popup message box
                    Exit Sub
                Finally
                    If Not sw Is Nothing Then 'no errors so close the output file
                        sw.Close()
                        If Interactive Then
                            Console.Write("Press any key to continue...")
                            Console.ReadKey(True)
                        End If
                    End If
                End Try

            Case "transfercomplete" 'we are logging TransferComplete log entries

                Try 'Put it in a try/catch/finally to trap any errors
                    filter.Add(OutputMgr.Logging.LogEntryType.TransferComplete) 'set output filter
                    sw = New System.IO.StreamWriter(logOutputPath) 'create output file

                    'write column headings to file
                    sw.Write("Date,Time,Account,Banner,BytesTransferred,Completion,EntryLevel,EntryType," _
                             & "FileType,HostFCyle,HostFileName,HostQualifier,HostQueue,NumberBytesInLogEntry," _
                             & "Pathname,XenosQueue,Peer,PeerName,Project,Runid,SendReceive,TransferAttributeName,TransferID,Userid")
                    sw.WriteLine()

                    ' Create the LogReader object using logpath, validated start and end dates and filter, and set UTC to false (don't interpret date range as UTC)
                    Dim lr As OutputMgr.Logging.LogReader
                    lr = New OutputMgr.Logging.LogReader(logPath, ValidatedStartDate, ValidatedEndDate, False, filter)

                    'Initialize variables used in log entry scanning
                    Dim LocDate As DateTime
                    Dim logEnTry As Object
                    Dim entries As Integer

                    'Char position in PCFileName denoting queue sub directory name start. Used pull out only that directory name
                    'Use substring function to pull out the part of string from pos 31 until the character position before the last '\' character
                    ' e.g. log.PcFileName.Substring(QPos, (log.PcFileName.LastIndexOf("\") - QPos))
                    Dim QPos As Integer = 31

                    'loop through log entries in time range
                    For Each logEnTry In lr
                        ' Match TransferComplete entries
                        If TypeOf logEnTry Is OutputMgr.Logging.ITransferCompleteV1 Then
                            Dim log As OutputMgr.Logging.ITransferCompleteV1 = CType(logEnTry, OutputMgr.Logging.ITransferCompleteV1)

                            entries = entries + 1 'Increase counter for log entries found, for display on console
                            LocDate = New DateTime(log.LocalDateTime, DateTimeKind.Local) 'store log entry datetime

                            'Write line to output file.
                            'Use String.Format to setup line format, followed by items to put on the line
                            '(the log entry attributes we are interested in)
                            sw.Write(String.Format("{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10},{11},{12},{13},{14},{15},{16},{17},{18},{19},{20},{21},{22},{23}",
                                    LocDate.ToShortDateString(),
                                    LocDate.ToShortTimeString(),
                                    log.Account,
                                    log.Banner,
                                    log.BytesTransferred,
                                    log.Completion,
                                    log.EntryLevel,
                                    log.EntryType,
                                    log.FileType,
                                    log.HostFCycle,
                                    log.HostFileName,
                                    log.HostQualifier,
                                    log.HostQueue,
                                    log.NumberOfBytesInEntry,
                                    log.PathName,
                                    log.PcFileName.Substring(QPos, (log.PcFileName.LastIndexOf("\") - QPos)),
                                    log.Peer,
                                    log.PeerName,
                                    log.Project,
                                    log.Runid,
                                    log.SendReceive,
                                    log.TransferAttributeName,
                                    log.TransferID,
                                    log.Userid
                                    ))
                            sw.WriteLine()

                            '#############################################################
                            '# Display progress on same 2 lines each time round the loop #
                            '#############################################################
                            Console.CursorTop -= 2 'move console cursor up 2 lines
                            Console.CursorLeft = 0 'move cursor horizontal position to start of the line

                            'Write progress to console
                            Console.WriteLine("Log Entries Found: " & entries)
                            Console.WriteLine("Currently Scanning Date: " & LocDate.ToShortDateString)
                        End If
                    Next
                    ' End for loop.
                Catch e As System.Exception
                    MsgBox(e.Message, MsgBoxStyle.OkOnly, "EOM Log Reader") 'display error as a popup message box
                    Exit Sub
                Finally
                    If Not sw Is Nothing Then 'no errors so close the output file
                        sw.Close()
                        If Interactive Then
                            Console.Write("Press any key to continue...")
                            Console.ReadKey(True)
                        End If
                    End If
                End Try
        End Select
    End Sub

End Module

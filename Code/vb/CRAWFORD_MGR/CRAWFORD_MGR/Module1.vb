Imports System.ComponentModel


Module Module1
    Public WithEvents BackgroundTask As BackgroundWorker

    '####### Status Variables #######
    Public Prod_Task_Status As String
    Public Prod_Process_Status As String
    Public DR_Task_Status As String
    Public DR_Process_Status As String
    Public Dev_Task_Status As String
    Public Dev_Process_Status As String
    Public Prod_Queued As String
    Public Prod_ERRS As String
    Public DR_Queued As String
    Public DR_ERRS As String
    Public Dev_Queued As String
    Public Dev_ERRS As String
    Public ProcessingFlag As Integer
    Public DoingMenuFlag As Integer
    Public CurrentMenu As String

    Public Const StatusFieldLen As Integer = 21
    Public Const Scheduled_Task As String = "CTI_MANAGER"
    Public Const Process_name As String = "proworkflowserver"
    Public Const Process_Display As String = "PROWorkFlowServer"

    '####### Server Names #######
    Public Const Prod_Server As String = "##REDACTED##"
    Public Const DR_Server As String = "##REDACTED##"
    Public Const Dev_Server As String = "##REDACTED##"

    '####### Console Dimensions #######
    Public Const ConsWidth As Integer = 88
    Public Const ConsHeight As Integer = 30
    Public Const MenuLine As Integer = 15

    '####### Status Message Expiry Timer (Milliseconds) #######
    Public Const MSGTimer As Integer = 2000
    
    '####### Interval between refreshes in seconds #######
    Public Const PauseCount As Integer = 30
    Public Const CountTab As String = "        "
    Public Const Countmess As String = " seconds to refresh"
    Public bgwPause As Integer
    Public Const OneSecond = 1000 '# milliseconds #

    '####### Refresh 

    Sub Main()
        '################################################################
        '#  Main Subroutine                                             #
        '#  ===============                                             #
        '#  Initialises Console and displays main menu.                 #
        '#                                                              #
        '#  Required Parameters:                                        #
        '#  - NONE                                                      #
        '################################################################

        'Initialise Console
        Console.SetWindowSize(ConsWidth, ConsHeight)
        Console.BufferHeight = ConsHeight
        Console.BufferWidth = ConsWidth
        Console.CursorVisible = False
        Console.Title = My.Application.Info.Title.ToString & " " & My.Application.Info.Version.ToString
        Console.Clear()

        'Display the main menu - everything else called/driven from there

        bgwPause = PauseCount
        BackgroundTask = New BackgroundWorker()
        BackgroundTask.RunWorkerAsync()

        Do Until MainMenu(0) = "999"

        Loop

    End Sub 'Main

    Function ClearMessageArea()
        '################################################################
        '#  ClearMenu Function                                          #
        '#  =================                                           #
        '#  Clear the message status area at the bottom of the screen.  #
        '#                                                              #
        '#  Required Parameters:                                        #
        '#  - None                                                      #
        '################################################################

        'Set cursor to start of last line on console (0-relative so number of rows - 1)
        Console.SetCursorPosition(0, ConsHeight - 1)

        'Restore colours to default standard status colours
        Console.BackgroundColor = ConsoleColor.Black
        Console.ForegroundColor = ConsoleColor.Gray

        'Write spaces for console width (-1) to wipe any stray message
        Console.Write(Space(ConsWidth - 1))

        Return True

    End Function 'ClearMessageArea

    Function WriteStatus(StatMSG As String)
        '################################################################
        '#  WriteStatus Function                                        #
        '#  ====================                                        #
        '#  Display status message on bottom of console window with     #
        '#  white text on dark yellow background.                       #
        '#                                                              #
        '#  Required Parameters:                                        #
        '#  - StatMSG (String)                                          #
        '#    ¬Any text that is to be displayed                         #
        '################################################################

        'Set Message colours
        Console.BackgroundColor = ConsoleColor.DarkYellow
        Console.ForegroundColor = ConsoleColor.White

        'Set cursor to start of last line on console (0-relative so number of rows - 1)
        Console.SetCursorPosition(0, ConsHeight - 1)

        'Write spaces for console width (-1) to wipe any stray message
        Console.Write(Space(ConsWidth - 1))

        'Reset cursor to start of last line
        Console.SetCursorPosition(0, ConsHeight - 1)

        'Write the message, padding with space up to console width (-1)
        Console.Write(StatMSG & Space((ConsWidth - 1) - StatMSG.Length))

        'Restore colours to default standard status colours
        Console.BackgroundColor = ConsoleColor.Black
        Console.ForegroundColor = ConsoleColor.Gray

        Return True

    End Function 'WriteStatus

    Function CallShell(ByVal strCMD As String,
               ByVal strARGS As String) As String
        '################################################################
        '#  GetTaskStatus Function                                      #
        '#  ======================                                      #
        '#  Does the actual shell call and returns the reply.           #
        '#  Required Parameters:                                        #
        '#  - strCMD - Shell call command.                              #
        '#  - strARGS - Sgell call arguments.                           #
        '################################################################
        Dim clsProcess As New System.Diagnostics.Process
        With clsProcess
            .StartInfo.FileName = strCMD
            .StartInfo.Arguments = strARGS
            .StartInfo.UseShellExecute = False
            .StartInfo.RedirectStandardOutput = True
            .Start()
        End With
        clsProcess.WaitForExit()

        Dim sOutput As String
        Using oStreamReader As System.IO.StreamReader = clsProcess.StandardOutput
            sOutput = oStreamReader.ReadToEnd()
        End Using
        Return sOutput

    End Function 'CallShell

    Function GetTaskStatus(ByRef Prod_Task_Status As String, ByRef DR_Task_Status As String, ByRef Dev_Task_status As String)
        '################################################################
        '#  GetTaskStatus Function                                      #
        '#  ======================                                      #
        '#  Interrogates the scheduled tasks on each of the conversion  #
        '#  servers useing a shell call and returns the status of each. #
        '#  Required Parameters:                                        #
        '#  - Prod_Task_Status - Return paramater for prod status.      #
        '#  - DR_Task_status   - Return paramater for DR status.        #
        '#  - Dev_Task_Status  - Return paramater for dev status.       #
        '################################################################
        Dim strShellReply As String
        Dim strARGS As String

        strARGS = " /s " + Prod_Server + " /query /tn " + Scheduled_Task
        strShellReply = CallShell("schtasks", strARGS)

        If InStr(strShellReply, "Ready") > 0 Then
            Prod_Task_Status = "Enabled"
        Else
            Prod_Task_Status = "Disabled"
        End If

        strARGS = " /s " + DR_Server + " /query /tn " + Scheduled_Task
        strShellReply = CallShell("schtasks", strARGS)
        'Dim length As Integer = Len(strShellReply)
        If InStr(strShellReply, "Ready") > 0 Then
            DR_Task_Status = "Enabled"
        Else
            DR_Task_Status = "Disabled"
        End If

        strARGS = " /s " + Dev_Server + " /query /tn " + Scheduled_Task
        strShellReply = CallShell("schtasks", strARGS)
        'Dim length As Integer = Len(strShellReply)
        If InStr(strShellReply, "Ready") > 0 Then
            Dev_Task_status = "Enabled"
        Else
            Dev_Task_status = "Disabled"
        End If

        Return True

    End Function 'GetTaskStatus

    Function CountQueues(ByRef TargetServer As String)
        '################################################################
        '#  CountQueues Function                                        #
        '#  =================                                           #
        '#  Interrogates each ASCII folder on a server for mta files    #
        '#  waiting for conversion and and returns the total            #
        '#  Required Parameters:                                        #
        '#  - TargetServer - Which server to take the action on.        #
        '################################################################
        Dim TotalCount As Integer

        TotalCount = 0

        Dim counter = My.Computer.FileSystem.GetFiles("\\" & TargetServer & "\e$\Server\data\Queues\##REDACTED##\bigfiles\Ascii")
        TotalCount = TotalCount + counter.Count
        counter = My.Computer.FileSystem.GetFiles("\\" & TargetServer & "\e$\Server\data\Queues\##REDACTED##\##REDACTED##\Ascii")
        TotalCount += counter.Count
        counter = My.Computer.FileSystem.GetFiles("\\" & TargetServer & "\e$\Server\data\Queues\##REDACTED##\##REDACTED##\Ascii")
        TotalCount += counter.Count
        counter = My.Computer.FileSystem.GetFiles("\\" & TargetServer & "\e$\Server\data\Queues\##REDACTED##\##REDACTED##\Ascii")
        TotalCount += counter.Count
        counter = My.Computer.FileSystem.GetFiles("\\" & TargetServer & "\e$\Server\data\Queues\##REDACTED##\##REDACTED##\Ascii")
        TotalCount += counter.Count
        counter = My.Computer.FileSystem.GetFiles("\\" & TargetServer & "\e$\Server\data\Queues\##REDACTED##\weefiles\Ascii")
        TotalCount += counter.Count
        counter = My.Computer.FileSystem.GetFiles("\\" & TargetServer & "\e$\Server\data\Queues\##REDACTED##\bigfiles\Ascii")
        TotalCount += counter.Count
        counter = My.Computer.FileSystem.GetFiles("\\" & TargetServer & "\e$\Server\data\Queues\##REDACTED##\##REDACTED##\Ascii")
        TotalCount += counter.Count
        counter = My.Computer.FileSystem.GetFiles("\\" & TargetServer & "\e$\Server\data\Queues\##REDACTED##\##REDACTED##\Ascii")
        TotalCount += counter.Count
        counter = My.Computer.FileSystem.GetFiles("\\" & TargetServer & "\e$\Server\data\Queues\##REDACTED##\##REDACTED##\Ascii")
        TotalCount += counter.Count
        counter = My.Computer.FileSystem.GetFiles("\\" & TargetServer & "\e$\Server\data\Queues\##REDACTED##\##REDACTED##\Ascii")
        TotalCount += counter.Count
        counter = My.Computer.FileSystem.GetFiles("\\" & TargetServer & "\e$\Server\data\Queues\##REDACTED##\weefiles\Ascii")
        TotalCount += counter.Count

        Return TotalCount

    End Function 'CountQueues

    Function CountErrors(ByRef TargetServer As String)
        '################################################################
        '#  CountErrors Function                                        #
        '#  =================                                           #
        '#  Interrogates each ERR folder on a server for any files      #
        '#  Required Parameters:                                        #
        '#  - TargetServer - Which server to take the action on.        #
        '################################################################
        Dim TotalCount As Integer

        TotalCount = 0

        Dim counter = My.Computer.FileSystem.GetFiles("\\" & TargetServer & "\e$\Server\data\Queues\##REDACTED##\bigfiles\ERR")
        TotalCount = TotalCount + counter.Count
        counter = My.Computer.FileSystem.GetFiles("\\" & TargetServer & "\e$\Server\data\Queues\##REDACTED##\##REDACTED##\ERR")
        TotalCount += counter.Count
        counter = My.Computer.FileSystem.GetFiles("\\" & TargetServer & "\e$\Server\data\Queues\##REDACTED##\##REDACTED##\ERR")
        TotalCount += counter.Count
        counter = My.Computer.FileSystem.GetFiles("\\" & TargetServer & "\e$\Server\data\Queues\##REDACTED##\##REDACTED##\ERR")
        TotalCount += counter.Count
        counter = My.Computer.FileSystem.GetFiles("\\" & TargetServer & "\e$\Server\data\Queues\##REDACTED##\##REDACTED##\ERR")
        TotalCount += counter.Count
        counter = My.Computer.FileSystem.GetFiles("\\" & TargetServer & "\e$\Server\data\Queues\##REDACTED##\weefiles\ERR")
        TotalCount += counter.Count
        counter = My.Computer.FileSystem.GetFiles("\\" & TargetServer & "\e$\Server\data\Queues\##REDACTED##\bigfiles\ERR")
        TotalCount += counter.Count
        counter = My.Computer.FileSystem.GetFiles("\\" & TargetServer & "\e$\Server\data\Queues\##REDACTED##\##REDACTED##\ERR")
        TotalCount += counter.Count
        counter = My.Computer.FileSystem.GetFiles("\\" & TargetServer & "\e$\Server\data\Queues\##REDACTED##\##REDACTED##\ERR")
        TotalCount += counter.Count
        counter = My.Computer.FileSystem.GetFiles("\\" & TargetServer & "\e$\Server\data\Queues\##REDACTED##\##REDACTED##\ERR")
        TotalCount += counter.Count
        counter = My.Computer.FileSystem.GetFiles("\\" & TargetServer & "\e$\Server\data\Queues\##REDACTED##\##REDACTED##\ERR")
        TotalCount += counter.Count
        counter = My.Computer.FileSystem.GetFiles("\\" & TargetServer & "\e$\Server\data\Queues\##REDACTED##\weefiles\ERR")
        TotalCount += counter.Count

        Return TotalCount

    End Function 'CountErrors

    Function GetProcessStatus(ByRef Prod_Process_Status As String, ByRef DR_Process_Status As String, ByRef Dev_Process_status As String)
        '################################################################
        '#  GetProcessStatus Function                                   #
        '#  =================                                           #
        '#  Interrogates a server's running tasks looking for the       #
        '#  ProWorkflowserver task and also counts any MTA files on the #
        '#  queues waiting to be converted.                             #
        '#  Required Parameters:                                        #
        '#  - TargetServer - Which server to take the action on.        #
        '################################################################
        Prod_Process_Status = "Not Running"
        For Each prog As Process In Process.GetProcesses(Prod_Server)
            If prog.ProcessName = Process_name Then
                Prod_Process_Status = "Running"
            End If
        Next

        DR_Process_Status = "Not Running"
        For Each prog As Process In Process.GetProcesses(DR_Server)
            If prog.ProcessName = Process_name Then
                DR_Process_Status = "Running"
            End If
        Next

        Dev_Process_status = "Not Running"
        For Each prog As Process In Process.GetProcesses(Dev_Server)
            If prog.ProcessName = Process_name Then
                Dev_Process_status = "Running"
            End If
        Next

        WriteStatus("Checking Queues Status...")

        Prod_Queued = CStr(CountQueues(Prod_Server)) & " queued requests"
        DR_Queued = CStr(CountQueues(DR_Server)) & " queued requests"
        Dev_Queued = CStr(CountQueues(Dev_Server)) & " queued requests"

        If CountErrors(Prod_Server) > 0 Then
            Prod_ERRS = "Check for errors"
        Else
            Prod_ERRS = " "
        End If
        If CountErrors(DR_Server) > 0 Then
            DR_ERRS = "Check for errors"
        Else
            DR_ERRS = " "
        End If
        If CountErrors(Dev_Server) > 0 Then
            Dev_ERRS = "Check for errors"
        Else
            Dev_ERRS = " "
        End If

        Return True

    End Function 'GetProcessStatus

    Function GetStatus()
        '################################################################
        '#  GetStatus Function                                          #
        '#  ==================                                          #
        '#  Gets status of launcher and of active scenarion scripts by  #
        '#  calling GetActiveScenario and GetLauncherStatus functions   #
        '#  and then writes the status header/info to the screen.       #
        '#                                                              #
        '#  Required Parameters:                                        #
        '#  - NONE                                                      #
        '################################################################
        '####### Menu Screen Functions #######

        WriteStatus("Checking Schedule Tasks Status...")
        GetTaskStatus(Prod_Task_Status, DR_Task_Status, Dev_Task_Status)

        WriteStatus("Checking PROWorkflow Status...")
        GetProcessStatus(Prod_Process_Status, DR_Process_Status, Dev_Process_Status)

        ClearMessageArea()
        ClearStatus()

        'Clear all contents of console and buffer window
        'Console.Clear()
        Console.SetCursorPosition(0, 0)

        'Write Status Heading
        Console.BackgroundColor = ConsoleColor.DarkCyan
        Console.ForegroundColor = ConsoleColor.Yellow
        Console.Write(vbTab & vbTab & vbTab & "    Crawford PDF Conversion Server Status" & vbTab & vbTab & vbTab & vbCrLf)

        'Write Status
        Console.BackgroundColor = ConsoleColor.Black
        Console.ForegroundColor = ConsoleColor.Gray
        Console.Write(vbTab & vbTab & vbTab & vbTab & "******************" & vbTab & "*********************" & vbCrLf &
                      vbTab & vbTab & vbTab & vbTab & "* Scheduled Task *" & vbTab & "* " & Process_Display & " *" & vbCrLf &
                      vbTab & vbTab & vbTab & vbTab & "******************" & vbTab & "*********************" & vbCrLf)

        'Restore colours to default standard status colours
        Console.ForegroundColor = ConsoleColor.Gray
        Console.Write(vbTab & Prod_Server & " (Prod)")

        'Set text colour of status
        If Prod_Task_Status.Contains("Enable") Then
            Console.ForegroundColor = ConsoleColor.Green
        Else
            Console.ForegroundColor = ConsoleColor.Red
        End If
        Console.Write((vbTab & Prod_Task_Status & Space(StatusFieldLen - Prod_Task_Status.Length)).Substring(0, StatusFieldLen))
        Console.ForegroundColor = ConsoleColor.Gray

        If Prod_Process_Status.Contains("Not") Then
            Console.ForegroundColor = ConsoleColor.Red
        Else
            Console.ForegroundColor = ConsoleColor.Green
        End If
        Console.Write((vbTab & Prod_Process_Status & Space(StatusFieldLen - Prod_Process_Status.Length)).Substring(0, StatusFieldLen))
        Console.ForegroundColor = ConsoleColor.Gray
        Console.Write(vbCrLf)

        If Left(Prod_Queued, 1) <> "0" Then
            Console.ForegroundColor = ConsoleColor.DarkYellow
        End If
        Console.Write(vbTab & vbTab & vbTab & vbTab & vbTab & vbTab & vbTab & Left(Prod_Queued, StatusFieldLen))
        Console.ForegroundColor = ConsoleColor.Gray
        Console.Write(vbCrLf)
        If Left(Prod_ERRS, 1) <> " " Then
            Console.ForegroundColor = ConsoleColor.Red
            Console.Write(vbTab & vbTab & vbTab & vbTab & vbTab & vbTab & vbTab & Left(Prod_ERRS, StatusFieldLen))
            Console.ForegroundColor = ConsoleColor.Gray
        End If
        Console.Write(vbCrLf)

        Console.Write(vbTab & DR_Server & " (DR)")

        If DR_Task_Status.Contains("Enable") Then
            Console.ForegroundColor = ConsoleColor.Red
        Else
            Console.ForegroundColor = ConsoleColor.Green
        End If
        Console.Write((vbTab & DR_Task_Status & Space(StatusFieldLen - DR_Task_Status.Length)).Substring(0, StatusFieldLen))
        If DR_Process_Status.Contains("Not") Then
            Console.ForegroundColor = ConsoleColor.Green
        Else
            Console.ForegroundColor = ConsoleColor.Red
        End If
        Console.Write((vbTab & DR_Process_Status & Space(StatusFieldLen - DR_Process_Status.Length)).Substring(0, StatusFieldLen))
        Console.ForegroundColor = ConsoleColor.Gray
        Console.Write(vbCrLf)
        If Left(DR_Queued, 1) <> "0" Then
            Console.ForegroundColor = ConsoleColor.DarkYellow
        End If
        Console.Write(vbTab & vbTab & vbTab & vbTab & vbTab & vbTab & vbTab & Left(DR_Queued, StatusFieldLen))
        Console.ForegroundColor = ConsoleColor.Gray
        Console.Write(vbCrLf)
        If Left(DR_ERRS, 1) <> " " Then
            Console.ForegroundColor = ConsoleColor.Red
            Console.Write(vbTab & vbTab & vbTab & vbTab & vbTab & vbTab & vbTab & Left(DR_ERRS, StatusFieldLen))
            Console.ForegroundColor = ConsoleColor.Gray
        End If
        Console.Write(vbCrLf)

        Console.Write(vbTab & Dev_Server & " (Dev)")
        If Dev_Task_Status.Contains("Enable") Then
            Console.ForegroundColor = ConsoleColor.DarkGreen
        Else
            Console.ForegroundColor = ConsoleColor.DarkRed
        End If
        Console.Write((vbTab & Dev_Task_Status & Space(StatusFieldLen - Dev_Task_Status.Length)).Substring(0, StatusFieldLen))
        If Dev_Process_Status.Contains("Not") Then
            Console.ForegroundColor = ConsoleColor.DarkRed
        Else
            Console.ForegroundColor = ConsoleColor.DarkGreen
        End If
        Console.Write((vbTab & Dev_Process_Status & Space(StatusFieldLen - Dev_Process_Status.Length)).Substring(0, StatusFieldLen))
        Console.ForegroundColor = ConsoleColor.Gray
        Console.Write(vbCrLf)

        If Left(Dev_Queued, 1) <> "0" Then
            Console.ForegroundColor = ConsoleColor.DarkYellow
        End If
        Console.Write(vbTab & vbTab & vbTab & vbTab & vbTab & vbTab & vbTab & Left(Dev_Queued, StatusFieldLen))
        Console.ForegroundColor = ConsoleColor.Gray

        If Left(Dev_ERRS, 1) <> " " Then
            Console.Write(vbCrLf)
            Console.ForegroundColor = ConsoleColor.DarkRed
            Console.Write(vbTab & vbTab & vbTab & vbTab & vbTab & vbTab & vbTab & Left(Dev_ERRS, StatusFieldLen))
            Console.ForegroundColor = ConsoleColor.Gray
        End If

        Return True

    End Function 'GetStatus

    Function GetNumericChoice(ByRef NumChoices As Integer)
        '##################################################################
        '#  GetNumericChoice Function                                     #
        '#  =========================                                     #
        '#  Gets single digit numeric input within specified range.       #
        '#                                                                #
        '#  Required Parameters:                                          #
        '#  - NumChoices (Integer)                                        #
        '#      ¬ Number of choices required (between 1 and this number). #
        '#                                                                #
        '##################################################################

        Dim KeyPressed As String = vbNullString
        Dim Num As Integer = 0

        DoingMenuFlag = 0
        'Flag indicates that a menu option has been chosen so clear until event.

        'Loop reading each key pressed until it is an integer and within the requested range
        Do Until (Integer.TryParse(KeyPressed, Num) = True And Num >= 1 And Num <= NumChoices)
            KeyPressed = Console.ReadKey(True).KeyChar '(True) means hide input from console display
        Loop

        Do Until (ProcessingFlag = 0)
            'Flag indicates that the background refresh task is in progress, so wait until it isn't.
        Loop

        DoingMenuFlag = 1
        'Flag indicates that a chice has been made so flag it, and then reset the "refresh in" counter
        bgwPause = PauseCount

        Return Num

    End Function 'GetNumericChoice

    Function ProcessTask(ByVal TargetServer As String)
        '################################################################
        '#  ProcessTask Function                                        #
        '#  =================                                           #
        '#  Carries out menu scheduled task action basesd on current    #
        '#  status. If enabled then disable...                          #
        '#  Required Parameters:                                        #
        '#  - TargetServer - Which server to take the action on.        #
        '################################################################
        Dim MyActionDisplay As String = "?"

        If TargetServer = Prod_Server Then
            If Prod_Task_Status.Contains("En") Then
                MyActionDisplay = "Disabling"
            Else
                MyActionDisplay = "Enabling"
            End If
        ElseIf TargetServer = DR_Server Then
            If DR_Task_Status.Contains("En") Then
                MyActionDisplay = "Disabling"
            Else
                MyActionDisplay = "Enabling"
            End If
        ElseIf TargetServer = Dev_Server Then
            If Dev_Task_Status.Contains("En") Then
                MyActionDisplay = "Disabling"
            Else
                MyActionDisplay = "Enabling"
            End If
        End If
        WriteStatus(MyActionDisplay & " " & Scheduled_Task & " on " & TargetServer & "...")

        If MyActionDisplay = "Disabling" Then
            Dim strARGS As String = " /s " + TargetServer + " /change /tn " + Scheduled_Task + " /disable"
            Dim strShellReply As String = CallShell("schtasks", strARGS)
            Dim length As Integer = Len(strShellReply)
        Else
            Dim strARGS As String = " /s " + TargetServer + " /change /tn " + Scheduled_Task + " /enable"
            Dim strShellReply As String = CallShell("schtasks", strARGS)
            Dim length As Integer = Len(strShellReply)
        End If

        'System.Threading.Thread.Sleep(2000)

        Return True

    End Function 'ProcessTask

    Function ClearMenu()
        '################################################################
        '#  ClearMenu Function                                          #
        '#  =================                                           #
        '#  Clear the menu area (bottom half) of the screen ready for   #
        '#  refreshing. Originally introduced to reduce potential of    #
        '#  flicker, i.e. only refresh as much of the screen as you     #
        '#  need to.                                                    #
        '#                                                              #
        '#  Required Parameters:                                        #
        '#  - None                                                      #
        '################################################################

        'Set the cursor to the menu line
        Dim ClearCount As Integer = MenuLine

        'Restore colours to default standard status colours
        Console.BackgroundColor = ConsoleColor.Black
        Console.ForegroundColor = ConsoleColor.Gray

        While (ClearCount < ConsHeight - 2)
            Console.SetCursorPosition(0, ClearCount)
            'Write spaces for console width (-1) to wipe any message
            Console.Write(Space(ConsWidth))
            ClearCount += 1

        End While

        Return True

    End Function 'ClearMenu

    Function ClearStatus()
        '################################################################
        '#  ClearStatus Function                                        #
        '#  =================                                           #
        '#  Clear the status area (top half) of the screen ready for    #
        '#  refreshing. Originally introduced to reduce potential of    #
        '#  flicker, i.e. only refresh as much of the screen as you     #
        '#  need to.                                                    #
        '#                                                              #
        '#  Required Parameters:                                        #
        '#  - None                                                      #
        '################################################################
        'Set the cursor to the first line of the status area
        Dim ClearCount As Integer = 2

        'Restore colours to default standard status colours
        Console.BackgroundColor = ConsoleColor.Black
        Console.ForegroundColor = ConsoleColor.Gray

        While (ClearCount < MenuLine)
            Console.SetCursorPosition(0, ClearCount)
            'Write spaces for console width (-1) to wipe any message
            Console.Write(Space(ConsWidth))
            ClearCount += 1

        End While

        Return True

    End Function 'ClearStatus

    Function TaskMenu(ByVal RefreshOnly As Integer)
        '################################################################
        '#  ProcessMenu Function                                        #
        '#  =================                                           #
        '#  Checks Status of scheduled tasks and service on each server #
        '#  and displays the scheduled task menu, getting menu input    #
        '#  when it is entered.                                         #
        '#                                                              #
        '#  Required Parameters:                                        #
        '#  - RefreshOnly - 0 - Indicates a full refresh is required    #
        '#                      and captured action request is to be    #
        '#                      processed.                              #
        '#                  otherwise - Indicates a refresh of the      #
        '#                      screen is only required (called from    #
        '#                      background refresh task.                #
        '################################################################
GetStatus:
        'Get status of 
        GetStatus()

DrawMenu:
        ClearMenu()

        Console.SetCursorPosition(0, MenuLine)

        'Write menu choices
        Console.Write(vbTab & vbTab & vbTab)
        Console.BackgroundColor = ConsoleColor.DarkCyan
        Console.ForegroundColor = ConsoleColor.Yellow
        Console.Write("    Scheduled Task Menu    ")
        Console.BackgroundColor = ConsoleColor.Black
        Console.ForegroundColor = ConsoleColor.Yellow

        Console.Write(vbCrLf & vbCrLf)

        Console.Write(vbTab & vbTab & vbTab & "1. ")
        If Prod_Task_Status.Contains("Enable") Then
            Console.Write("Disable ")
        Else
            Console.Write("Enable ")
        End If
        Console.Write("Prod (" & Prod_Server & ")" & vbCrLf)

        Console.Write(vbTab & vbTab & vbTab & "2. ")
        If DR_Task_Status.Contains("Enable") Then
            Console.Write("Disable ")
        Else
            Console.Write("Enable ")
        End If
        Console.Write("DR (" & DR_Server & ")" & vbCrLf)

        Console.Write(vbTab & vbTab & vbTab & "3. ")
        If Dev_Task_Status.Contains("Enable") Then
            Console.Write("Disable ")
        Else
            Console.Write("Enable ")
        End If
        Console.Write("Dev (" & Dev_Server & ")" & vbCrLf)

        Console.Write(vbTab & vbTab & vbTab & "4. Refresh Status" & vbCrLf)

        Console.Write(vbTab & vbTab & vbTab & "5. Return to Main Menu" & vbCrLf)

        CurrentMenu = "TASK"

        If RefreshOnly = 0 Then
            'Call GetNumericChoice function with number of numeric choices required
            '   - only returns when one of the required options has been chosen
            Select Case GetNumericChoice(5)
                Case 1
                    'Pressed 1
                    'Do Until TaskMenu() = "9"
                    ProcessTask(Prod_Server)
                    'Loop
                    Return "1"
                Case 2
                    'Pressed 2
                    'Do Until ProcessMenu() = "9"
                    ProcessTask(DR_Server)
                    'Loop
                    Return "2"
                Case 3
                    'Pressed 3
                    'Do Until TaskMenu() = "9"
                    ProcessTask(Dev_Server)
                    'Loop
                    Return "3"
                Case 4
                    'Pressed 4
                    GoTo GetStatus
                    Return "4"
                Case 5
                    'Pressed 5 - exit
                    Return "9"
            End Select
        End If

        Return True

    End Function 'TaskMenu

    Function ProcessAction(ByVal TargetServer As String)
        '################################################################
        '#  ProcessAction Function                                      #
        '#  =================                                           #
        '#  Carries out menu ProWorkflowserver action basesd on current #
        '#  status. If stopped then start...                            #
        '#  Required Parameters:                                        #
        '#  - TargetServer - Which server to take the action on.        #
        '################################################################

        Dim MyActionDisplay As String = "?"
        Dim strARGS As String
        Dim clsProcess As New System.Diagnostics.Process

        'Set up status message to display what is happening based on the server 
        'and the current status
        If TargetServer = Prod_Server Then
            If Prod_Process_Status.Contains("Not") Then
                MyActionDisplay = "Starting"
            Else
                MyActionDisplay = "Stopping"
            End If
        ElseIf TargetServer = DR_Server Then
            If DR_Process_Status.Contains("Not") Then
                MyActionDisplay = "Starting"
            Else
                MyActionDisplay = "Stopping"
            End If
        ElseIf TargetServer = Dev_Server Then
            If Dev_Process_Status.Contains("Not") Then
                MyActionDisplay = "Starting"
            Else
                MyActionDisplay = "Stopping"
            End If
        End If

        'Display the status message
        WriteStatus(MyActionDisplay & " " & Process_Display & " on " & TargetServer & "...")

        'Now do the operation, also enabling the scheduled task first if required and
        'displaying the progress
        If MyActionDisplay = "Stopping" Then
            strARGS = "/s " + TargetServer + " /im " + Process_name + ".exe"
            With clsProcess
                .StartInfo.FileName = "taskkill"
                .StartInfo.Arguments = strARGS
                .StartInfo.UseShellExecute = False
                .StartInfo.RedirectStandardOutput = True
                .Start()
            End With
            clsProcess.WaitForExit()
        Else
            If (TargetServer = Prod_Server And Prod_Task_Status.Contains("Dis")) Or
                (TargetServer = DR_Server And DR_Task_Status.Contains("Dis")) Or
                (TargetServer = Dev_Server And Dev_Task_Status.Contains("Dis")) Then

                WriteStatus("Enabling " & Scheduled_Task & " on " & TargetServer & "...")
                strARGS = " /s " + TargetServer + " /change /tn " + Scheduled_Task + " /enable"
                Dim strShellReply As String = CallShell("schtasks", strARGS)
                Dim length As Integer = Len(strShellReply)

            End If
            strARGS = "/s " + TargetServer + " /run /tn " + Scheduled_Task
            With clsProcess
                .StartInfo.FileName = "schtasks"
                .StartInfo.Arguments = strARGS
                .StartInfo.UseShellExecute = False
                .StartInfo.RedirectStandardOutput = True
                .Start()
            End With
            clsProcess.WaitForExit()
        End If

        Return True

    End Function 'ProcessAction

    Function ProcessMenu(ByVal RefreshOnly As Integer)
        '################################################################
        '#  ProcessMenu Function                                        #
        '#  =================                                           #
        '#  Checks Status of scheduled tasks and service on each server #
        '#  and displays the process menu, getting menu input when it   #
        '#  is entered.                                                 #
        '#                                                              #
        '#  Required Parameters:                                        #
        '#  - RefreshOnly - 0 - Indicates a full refresh is required    #
        '#                      and captured action request is to be    #
        '#                      processed.                              #
        '#                  otherwise - Indicates a refresh of the      #
        '#                      screen is only required (called from    #
        '#                      background refresh task.                #
        '################################################################
GetStatus:
        'Get status of scheduled task and ProWorkflowserver process on each server.
        GetStatus()

DrawMenu:
        'Write menu choices

        ClearMenu()

        Console.SetCursorPosition(0, MenuLine)

        Console.Write(vbTab & vbTab & vbTab)
        Console.BackgroundColor = ConsoleColor.DarkCyan
        Console.ForegroundColor = ConsoleColor.Yellow
        Console.Write("    PROWorkflowserver Menu    ")
        Console.BackgroundColor = ConsoleColor.Black
        Console.ForegroundColor = ConsoleColor.Yellow

        Console.Write(vbCrLf & vbCrLf)

        Console.Write(vbTab & vbTab & vbTab & "1. ")
        If Prod_Process_Status.Contains("Not") Then
            Console.Write("Start ")
        Else
            Console.Write("Stop ")
        End If
        Console.Write("Prod (" & Prod_Server & ")" & vbCrLf)

        Console.Write(vbTab & vbTab & vbTab & "2. ")
        If DR_Process_Status.Contains("Not") Then
            Console.Write("Start ")
        Else
            Console.Write("Stop ")
        End If
        Console.Write("DR (" & DR_Server & ")" & vbCrLf)

        Console.Write(vbTab & vbTab & vbTab & "3. ")
        If Dev_Process_Status.Contains("Not") Then
            Console.Write("Start ")
        Else
            Console.Write("Stop ")
        End If
        Console.Write("Dev (" & Dev_Server & ")" & vbCrLf)

        Console.Write(vbTab & vbTab & vbTab & "4. Refresh Status" & vbCrLf)

        Console.Write(vbTab & vbTab & vbTab & "5. Return to Main Menu" & vbCrLf)

        CurrentMenu = "PROCESS"

        If RefreshOnly = 0 Then
            'Call GetNumericChoice function with number of numeric choices required
            '   - only returns when one of the required options has been chosen
            Select Case GetNumericChoice(5)
                Case 1
                    'Pressed 1
                    'Do Until TaskMenu() = "9"
                    ProcessAction(Prod_Server)
                    'Loop
                    Return "1"
                Case 2
                    'Pressed 2
                    'Do Until ProcessMenu() = "9"
                    ProcessAction(DR_Server)
                    'Loop
                    Return "2"
                Case 3
                    'Pressed 3
                    'Do Until TaskMenu() = "9"
                    ProcessAction(Dev_Server)
                    'Loop
                    Return "3"
                Case 4
                    'Pressed 4
                    GoTo GetStatus
                    Return "4"
                Case 5
                    'Pressed 5 - exit
                    Return "9"
            End Select
        End If

        Return True

    End Function 'ProcessMenu

    Function MainMenu(ByVal RefreshOnly As Integer)
        '################################################################
        '#  MainMenu Function                                           #
        '#  =================                                           #
        '#  Checks Status of scheduled tasks and service on each server #
        '#  and display the status/menu, getting menu input when it is  #
        '#  entered.                                                    #
        '#                                                              #
        '#  Required Parameters:                                        #
        '#  - NONE                                                      #
        '################################################################
GetStatus:
        'Get status of launcher and name of prod/dev active scripts on each server and write out status info.
        GetStatus()

DrawMenu:

        'Write Menu Choices
        ClearMenu()

        Console.SetCursorPosition(0, MenuLine)

        Console.Write(vbTab & vbTab & vbTab)
        Console.BackgroundColor = ConsoleColor.DarkCyan
        Console.ForegroundColor = ConsoleColor.Yellow
        Console.Write(vbTab & vbTab & "Main Menu" & vbTab & vbTab)
        Console.Write(vbCrLf)
        Console.BackgroundColor = ConsoleColor.Black
        Console.ForegroundColor = ConsoleColor.Yellow
        Console.Write(vbCrLf &
                      vbTab & vbTab & vbTab & "1. Scheduled Task Menu" & vbCrLf &
                      vbTab & vbTab & vbTab & "2. PROWorkflowServer Menu" & vbCrLf &
                      vbTab & vbTab & vbTab & "3. Refresh Status" & vbCrLf &
                      vbTab & vbTab & vbTab & "4. Exit" & vbCrLf)

        CurrentMenu = "MAIN"

        If RefreshOnly = 0 Then

            'Call GetNumericChoice function with number of numeric choices required
            '   - only returns when one of the required options has been chosen
            Select Case GetNumericChoice(4)
                Case 1
                    'Pressed 1
                    Do Until TaskMenu(0) = "9"

                    Loop
                    Return "1"
                Case 2
                    'Pressed 2
                    Do Until ProcessMenu(0) = "9"

                    Loop
                    Return "2"
                Case 3
                    'Pressed 3
                    GoTo GetStatus
                    Return "3"
                Case 4
                    'Pressed 4 - exit
                    Return "999"
            End Select
        End If

        Return True
    End Function 'MainMenu

    Private Sub BackgroundTask_DoWork(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles BackgroundTask.DoWork
        '################################################################
        '#  BackgroundTask_DoWork                                       #
        '#  =====================                                       #
        '#  Background thread to refresh status every <bgwPause>        #
        '#  seconds. Kicked off before any other processing and outwith #
        '#  main loop.  Executes until end of script as bgwCount never  #
        '#  altered from default.                                       #
        '#                                                              #
        '################################################################

        Dim bgwCount As Integer
        
        Do Until (bgwCount = 1)

            Do Until bgwPause < 0
                System.Threading.Thread.Sleep(OneSecond)
                Do Until DoingMenuFlag = 0
                    'Flag indicates that a menu option has been selected. Pause the background task
                    'until the menu selection has been processed.
                Loop

                ProcessingFlag = 1
                'Flag indicates that the background refresh task is in process and will pause any 
                'menu selection until complete.

                'Count down the seconds to the next refresh and display on the appropriate line to let 
                'the user know we're still working.
                Console.SetCursorPosition(0, ConsHeight - 3)
                Console.BackgroundColor = ConsoleColor.Black
                Console.ForegroundColor = ConsoleColor.Gray
                'Write the refresh message, padding with space up to console width (-1) again.
                Console.Write(CountTab & bgwPause & Countmess &
                              Space(ConsWidth - CountTab.Length - Countmess.Length - CType(bgwPause, String).Length - 1))
                ProcessingFlag = 0

                'Attempt to count down to 0 again.  Count is reset by any menu action request.
                bgwPause -= 1
            Loop

            Do Until DoingMenuFlag = 0
                'Flag indicates a menu selection is in progress. Wait until it's done.
            Loop

            ProcessingFlag = 1
            'Flag indicates background refresh task in process to pause any menu selection.

            Do Until DoingMenuFlag = 0
                'Check menu selection flag again after setting refresh flag and wait until it's done.
            Loop

            If CurrentMenu = "TASK" Then
                TaskMenu(1)
            ElseIf CurrentMenu = "PROCESS" Then
                ProcessMenu(1)
            Else
                MainMenu(1)
            End If

            'We're done. Yipee!  Reset the refresh flag to allow menu selection and reset the count 
            'down timer.
            ProcessingFlag = 0
            bgwPause = PauseCount
        Loop

    End Sub 'BackgroundTask_DoWork
End Module

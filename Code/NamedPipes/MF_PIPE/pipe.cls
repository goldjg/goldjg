VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "pipe"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Option Explicit
Public sPipeName As String
Public lPipeHandle As Long
Public sBuffer As String
Public lPipeSize As Long
Public sError As String
Public lTimeout As Long
Public x As Integer
Public sUser As String
Public sPassword As String
Public sServer As String
Public sDiagFile As String
Public bDiag As Boolean
Public bOpen As Integer
Public bDiagGlobal As Boolean
Public sDiagFileGlobal As String



Public Function mfOpen() As Integer
Dim iResult As Integer
Dim oReg As New RegProfiles
On Error GoTo err_mfOpen

bDiagGlobal = oReg.QueryValue(oReg.HKEY_LOCAL_MACHINE, "software\extranet db", "mfdiag") = 1
sDiagFileGlobal = oReg.QueryValue(oReg.HKEY_LOCAL_MACHINE, "software\extranet db", "mfdiagfile")

WriteDiag "Entered mfOpen"
If sPipeName = "" Then
    iResult = False
    sError = "No pipe name specified"
    WriteDiag sError
ElseIf bOpen Then
    iResult = False
    sError = "Pipe already open"
    WriteDiag sError
Else
    WriteDiag "All correct, opening pipe"
    lPipeHandle = OpenPipe(sPipeName, sUser, sPassword, sServer, bDiagGlobal, sDiagFileGlobal)
    If lPipeHandle = -1 Then
        iResult = False
        bOpen = False
        sError = "Pipe open failed"
        WriteDiag sError
    Else
        iResult = True
        bOpen = True
        sError = ""
        WriteDiag "Open successful, handle " & CStr(lPipeHandle)
    End If
End If

mfOpen = iResult

res_mfOpen:
WriteDiag "Leaving mfOpen"
Exit Function

err_mfOpen:
ReportError "MFOpen :- " & Err.Description
Resume res_mfOpen

End Function

Public Function mfRead() As Long
Dim lresult As Long
On Error GoTo err_mfRead

On Error GoTo err_mfRead

WriteDiag "(" & CStr(lPipeHandle) & ") " & "Entered mfRead"
If Not bOpen Then
    lresult = -1
    sError = "Pipe not open"
    WriteDiag "(" & CStr(lPipeHandle) & ") " & sError
ElseIf lPipeSize = 0 Then
    lresult = -1
    sError = "No pipe size specified"
    WriteDiag "(" & CStr(lPipeHandle) & ") " & sError
Else
    WriteDiag "(" & CStr(lPipeHandle) & ") " & "All OK, progressing to read"
    sBuffer = Space(lPipeSize)
    sError = ""
    lresult = ReadPipe(lPipeHandle, sBuffer, lPipeSize, lTimeout, bDiagGlobal, sDiagFileGlobal)
    If lresult > 0 Then
        WriteDiag "(" & CStr(lPipeHandle) & ") " & "All OK, converting from EBCDIC"
        sBuffer = FromEbcdic(sBuffer, lresult)
        WriteDiag "(" & CStr(lPipeHandle) & ") " & "Converted string is " & sBuffer
    Else
        WriteDiag "(" & CStr(lPipeHandle) & ") " & "Read returned no characters"
    End If
End If

mfRead = lresult
res_mfRead:
WriteDiag "(" & CStr(lPipeHandle) & ") " & "Leaving mfRead"
Exit Function
err_mfRead:
ReportError "(" & CStr(lPipeHandle) & ") " & "MFRead :- " & Err.Description
Resume res_mfRead

End Function

Public Function mfWrite() As Long
Dim lresult As Long
On Error GoTo err_mfWrite

WriteDiag "(" & CStr(lPipeHandle) & ") " & "Entered mfWrite"
If Not bOpen Then
    lresult = -1
    sError = "Pipe not open"
    WriteDiag "(" & CStr(lPipeHandle) & ") " & sError
Else
    sError = ""
    WriteDiag "(" & CStr(lPipeHandle) & ") " & "All OK, proceeding to write"
    WriteDiag "(" & CStr(lPipeHandle) & ") " & "Contents :- " & sBuffer
    WriteDiag "(" & CStr(lPipeHandle) & ") " & "Converting text to EBCDIC"
    sBuffer = ToEbcdic(sBuffer, Len(sBuffer))
    WriteDiag "(" & CStr(lPipeHandle) & ") " & "Preparing to call Write"
    lresult = WritePipe(lPipeHandle, sBuffer, lTimeout, bDiagGlobal, sDiagFileGlobal)
End If

mfWrite = lresult
res_mfWrite:
WriteDiag "(" & CStr(lPipeHandle) & ") " & "Leaving mfWrite"

Exit Function
err_mfWrite:
ReportError "(" & CStr(lPipeHandle) & ") " & "MFWrite :- " & Err.Description
Resume res_mfWrite

End Function

Public Function mfClose() As Integer
Dim iResult As Integer

On Error GoTo err_mfClose

WriteDiag "(" & CStr(lPipeHandle) & ") " & "Entering mfClose"

If Not bOpen Then
    iResult = False
    sError = "Pipe not open"
    WriteDiag "(" & CStr(lPipeHandle) & ") " & sError
Else
    sError = ""
    WriteDiag "(" & CStr(lPipeHandle) & ") " & "All OK, proceeding to close pipe"
    ClosePipe lPipeHandle, bDiagGlobal, sDiagFileGlobal
    iResult = True
    bOpen = False
End If

mfClose = iResult
res_mfClose:
WriteDiag "(" & CStr(lPipeHandle) & ") " & "Leaving mfClose"

Exit Function
err_mfClose:
ReportError "(" & CStr(lPipeHandle) & ") " & "MFClose :- " & Err.Description
Resume res_mfClose

End Function


Private Sub Class_Initialize()

Call InitEbcdic
bOpen = False
sError = 0
lPipeSize = 0
sPipeName = ""
lTimeout = 30000

End Sub

Public Sub Wait(lDelay As Long)

Delay (lDelay)

End Sub

Private Sub Class_Terminate()

On Error GoTo err_Terminate
WriteDiag "Terminating class"

If bOpen Then
    mfClose
    bOpen = False
End If

res_Terminate:
WriteDiag "Leaving Terminate"

Exit Sub
err_Terminate:
ReportError "Terminate :- " & Err.Description
Resume res_Terminate

End Sub


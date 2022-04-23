VERSION 1.0 CLASS
BEGIN
  MultiUse = 0   'False
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

Public bOpen As Integer

Public Function mfOpen() As Integer
Dim iResult As Integer

If sPipeName = "" Then
    iResult = False
    sError = "No pipe name specified"
ElseIf bOpen Then
    iResult = False
    sError = "Pipe already open"
Else
    lPipeHandle = OpenPipe(sPipeName, lTimeout, lTimeout, sUser, sPassword, sServer)
    If lPipeHandle = -1 Then
        iResult = False
        bOpen = False
        sError = "Pipe open failed"
    Else
        iResult = True
        bOpen = True
        sError = ""
    End If
End If

mfOpen = iResult
End Function

Public Function mfRead() As Long
Dim lresult As Long

If Not bOpen Then
    lresult = -1
    sError = "Pipe not open"
ElseIf lPipeSize = 0 Then
    lresult = -1
    sError = "No pipe size specified"
Else
    sBuffer = Space(lPipeSize)
    sError = ""
    lresult = ReadPipe(lPipeHandle, sBuffer, lPipeSize)
    If lresult > 0 Then
        sBuffer = FromEbcdic(sBuffer, lresult)
    End If
End If

mfRead = lresult


End Function

Public Function mfWrite() As Long
Dim lresult As Long

If Not bOpen Then
    lresult = -1
    sError = "Pipe not open"
Else
    sError = ""
    sBuffer = ToEbcdic(sBuffer, Len(sBuffer))
    lresult = WritePipe(lPipeHandle, sBuffer)
End If

mfWrite = lresult

End Function

Public Function mfClose() As Integer
Dim iResult As Integer

If Not bOpen Then
    iResult = False
    sError = "Pipe not open"
Else
    sError = ""
    ClosePipe (lPipeHandle)
    iResult = True
    bOpen = False
End If

mfClose = iResult

End Function


Private Sub Class_Initialize()

Call InitEbcdic
bOpen = False
sError = 0
lPipeSize = 0
sPipeName = ""

End Sub



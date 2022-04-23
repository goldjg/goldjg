Attribute VB_Name = "NamedPipe"
Declare Function PeekNamedPipe Lib "kernel32" (ByVal hNamedPipe As Long, lpBuffer As Any, ByVal nBufferSize As Long, lpBytesRead As Long, lpTotalBytesAvail As Long, lpBytesLeftThisMessage As Long) As Long
Declare Function OpenPipe Lib "npdll.dll" (ByVal sPipe As String, ByVal sUser As String, ByVal sPassword As String, ByVal sServer As String, ByVal bDiag As Boolean, ByVal sDiagFile As String) As Long

Declare Function ReadPipe Lib "npdll.dll" (ByVal hPipe As Long, ByVal sMessage As String, ByVal lNumBytes As Long, ByVal lTimeout As Long, ByVal bDiag As Boolean, ByVal sDiagFile As String) As Long
Declare Function WritePipe Lib "npdll.dll" (ByVal hPipe As Long, ByVal sMessage As String, ByVal lTimeout As Long, ByVal bDiag As Boolean, ByVal sDiagFile As String) As Long

Declare Sub ClosePipe Lib "npdll.dll" (ByVal hPipe As Long, ByVal bDiag As Boolean, ByVal sDiagFile As String)
Declare Sub Delay Lib "npdll.dll" (ByVal lCount As Long)

Dim ebcdic_chars As String
Dim ascii_chars As String

Public Function FromEbcdic(ByVal s As String, ByVal ioSize As Long) As String

Dim sTemp As String
Dim iTemp As Integer
Dim uLimit As Integer
Dim iCode As Integer

    sTemp = ""
    For iTemp = 1 To ioSize
        iCode = Asc(Mid(s, iTemp, 1))
        If iCode > 0 Then
            If iCode = 13 Then
                sTemp = sTemp & Chr(13) & Chr(10)
            ElseIf iCode = 37 Then
                'do nothing
            ElseIf Mid(ebcdic_chars, iCode, 1) = "^" Then
                sTemp = sTemp & "?"
            Else
                sTemp = sTemp & Mid(ebcdic_chars, iCode, 1)
            End If
        Else
            sTemp = sTemp & " "
        End If
    Next iTemp
    FromEbcdic = sTemp
End Function

Public Function ToEbcdic(ByVal s As String, ByVal ioSize As Long) As String
Dim sTemp As String
Dim iTemp As Integer
Dim uLimit As Integer
Dim iCode As Integer

sTemp = ""
    For iTemp = 1 To ioSize
        iCode = Asc(Mid(s, iTemp, 1))
        If iCode > 0 Then
            sTemp = sTemp & Mid(ascii_chars, iCode, 1)
        Else
            sTemp = sTemp & " "
        End If
    Next iTemp
    ToEbcdic = sTemp

End Function


Sub InsertString(sOriginal As String, sNew As String, iPos As Integer)

sOriginal = Left(sOriginal, iPos - 1) & sNew & Right(sOriginal, Len(sOriginal) - iPos - Len(sNew) + 1)

End Sub

Public Sub InitEbcdic()
Dim iPos As Integer
Dim iCode As Integer

For iPos = 1 To 16
    ebcdic_chars = ebcdic_chars & "^^^^^^^^^^^^^^^^"
Next iPos
ascii_chars = ebcdic_chars
InsertString ebcdic_chars, "abcdefghi^^^^^^^jklmnopqr^^^^^^^^stuvwxyz", 129
InsertString ebcdic_chars, "ABCDEFGHI^^^^^^}JKLMNOPQR^^^^^^\^STUVWXYZ", 193
InsertString ebcdic_chars, "0123456789", 240
InsertString ebcdic_chars, ".<(+|&", 75
InsertString ebcdic_chars, "!$*);^-/", 90
InsertString ebcdic_chars, ",%_>?", 107
InsertString ebcdic_chars, ":#@'=""", 122
InsertString ebcdic_chars, " ", 64

For iPos = 1 To 255
    iCode = Asc(Mid(ebcdic_chars, iPos, 1))
    InsertString ascii_chars, Chr(iPos), iCode
Next iPos

End Sub


Attribute VB_Name = "Module1"
Sub OpenPipes()
Dim objMFdll As Object
Dim sServer As String, sPipename As String, iTemp As Long


    Set objMFdll = CreateObject("mfDLL.pipe")
    If objMFdll Is Nothing Then
        Text1.Text = Text1.Text & "Error creating object"
        Exit Sub
    End If
    
    sServer = "##REDACTED##"
    sPipename = "\\" & sServer & "\pipe\coms\coms\HARNES\TESTPIPE" & Int((99 * Rnd()) + 1)
    objMFdll.sPipename = sPipename
    Text1.Text = Text1.Text & "Pipename = " & objMFdll.sPipename
    objMFdll.lPipeSize = 65000
    objMFdll.lTimeout = 5000
    objMFdll.sUser = "##REDACTED##"    'not including in secured version
    objMFdll.sPassword = "##REDACTED##"   'not including in secured version
    objMFdll.sServer = sServer
    iTemp = objMFdll.mfOpen

    'MsgBox "mfOpen=" & CStr(iTemp)
    'MsgBox "Error=" & CStr(objMFdll.sError)

    If iTemp = 0 Then 'error opening pipe
        Set objMFdll = Nothing
        Text1.Text = Text1.Text & "Error opening pipe"
        Exit Sub
    Else
        Text1.Text = Text1.Text & "Pipe open"
    End If
    
    
    objMFdll.sBuffer = ""
    lTemp = objMFdll.mfread
    
    'MsgBox "lTemp = " & lTemp

    While InStr(objMFdll.sBuffer, "##REDACTED##") <= 0 And lTemp > 0
        lTemp = objMFdll.mfread
    Wend

    If lTemp = 0 Then
        objMFdll.mfClose
        Set objMFdll = Nothing
        Text1.Text = Text1.Text & "Error retrieving mainframe information"
        Exit Sub
    Else
        Text1.Text = Text1.Text & "Success retrieving mainframe information"
    End If
        
    sPostTest = ""
    sPostTest = "##REDACTED##"

    objMFdll.sBuffer = sPostTest 'request("cmdline")
    
    lTemp = objMFdll.mfWrite
    If lTemp = 0 Then
        objMFdll.mfClose
        Set objMFdll = Nothing
        Text1.Text = Text1.Text & "Error writing mainframe information"
        Exit Sub
    Else
        Text1.Text = Text1.Text & "Success writing mainframe information"
        Text1.Text = Text1.Text & "Message length = " & Len(objMFdll.sBuffer)
        'MsgBox "Return value = " & lTemp
    End If

    lTemp = objMFdll.mfread
    'MsgBox "lTemp = " & lTemp
    
    If lTemp = 0 Then
        objMFdll.mfClose
        Set objMFdll = Nothing
        Text1.Text = Text1.Text & "Error reading mainframe information"
        Exit Sub
    Else
        Text1.Text = Text1.Text & "Success reading mainframe information"
    End If
    
    'MsgBox "objMFdll.sError = " & objMFdll.sError

    sBuffer = objMFdll.sBuffer
    
    Text1.Text = Text1.Text & "Message = " & sBuffer
    'MsgBox "objMFdll.sError = " & objMFdll.sError
    'set objMFdll = Nothing
    'exit sub


    'Code ripped off from GnCommon
    nAttempt_No = 1
    Do Until (nAttempt_No > 1)
    
        Text1.Text = Text1.Text & "MF call number: " & nAttempt_No
        
        objMFdll.sBuffer = sPostTest
        
        lTemp = objMFdll.mfWrite
        lTemp = objMFdll.mfread
        '-----
        'Mainframe TP's can return error string first then pass
        'the valid output. When this happens mfRead will return a value
        'of 20 and the returned string will contain 'GL IGNORE'.
        
        Text1.Text = Text1.Text & "Message = " & objMFdll.sBuffer
        Text1.Text = Text1.Text & "Message Length = " & Len(objMFdll.sBuffer)

        bErrorString_Ret = False
        If InStr(objMFdll.sBuffer, "GL IGNORE") > 0 Then
            bErrorString_Ret = True
        End If
        
        'MsgBox "bErrorString_Ret = " & bErrorString_Ret
        
        '-----
        bWithinTimeLimit = True
        sngStart = Timer
        icount = 1
        While ((lTemp < 3) Or bErrorString_Ret) And bWithinTimeLimit And icount < 10
            If Timer - sngStart > 100 Then 'CHECK THIS VALUE
                bWithinTimeLimit = False
            End If
            
            Text1.Text = Text1.Text & "Read number: " & icount
            
            lTemp = objMFdll.mfread

            Text1.Text = Text1.Text & "Message = " & objMFdll.sBuffer
            
            bErrorString_Ret = False
            If InStr(objMFdll.sBuffer, "GL IGNORE") > 0 Then
                bErrorString_Ret = True
            End If
            '-----
            icount = icount + 1
        Wend
        Text1.Text = Text1.Text & "" & InStr(objMFdll.sBuffer, "caused a program to fail")
        If InStr(objMFdll.sBuffer, "caused a program to fail") = 0 Then
            Text1.Text = Text1.Text & "incrementing loop number"
            nAttempt_No = nAttempt_No + 1
        Else
            Text1.Text = Text1.Text & "exiting loop"
            Exit Do
        End If
        Text1.Text = Text1.Text & "end of loop"
    Loop
    
    iTemp = objMFdll.mfClose

    Text1.Text = Text1.Text & "Message = " & sBuffer
    Exit Sub
End Sub


Sub SetupFiles()
    FileCopy "NPDLL.dll", "C:\WINNT\system32\NPDLL.dll"
    
    regsvr32 /s mfdll.dll
    
End Sub    

'function to call to register NPDLL.dll
    Private Declare Function RegNPDLL Lib "NPDLL.DLL" Alias _
    "DllRegisterServer" () As Long
            
    'function to call to register mfdll.dll
    Private Declare Function Regmfdll Lib "mfdll.dll" Alias _
    "DllRegisterServer" () As Long
    
    Const ERROR_SUCCESS = 0&

    Dim retCode As Long

    On Error Resume Next

    ' move to the NPDLL directory
    ChDrive "C:"
    ChDir "C:\WINNT\system32"

    ' register the NPDLL
    retCode = RegNPDLL()

    If Err <> 0 Then
        ' probably the DLL isn't there
        MsgBox "Unable to find the NPDLL.DLL file"
    ElseIf retCode <> ERROR_SUCCESS Then
        ' the registration run but failed
        MsgBox "Registration failed"
    End If

    ' register the mfdll
    retCode = Regmfdll()

    If Err <> 0 Then
        ' probably the DLL isn't there
        MsgBox "Unable to find the mfdll.dll file"
    ElseIf retCode <> ERROR_SUCCESS Then
        ' the registration run but failed
        MsgBox "Registration failed"
    End If
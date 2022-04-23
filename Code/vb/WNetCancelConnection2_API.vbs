
Private Declare Function WNetCancelConnection2 Lib "mpr.dll" Alias "WNetCancelConnection2A" (ByVal lpName As String, ByVal dwFlags As Long, ByVal lpszLocalName As Boolean) As Long


    Dim strIPC As String
    Dim lDisconnect As Long
    
    'Ensure no cached credentials, remove IPC$ share for host if it exists
    strIPC = "\\" & txtMF.Text & "\IPC$"
    lDisconnect = WNetCancelConnection2(strIPC, 0, True)


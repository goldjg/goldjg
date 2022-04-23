Attribute VB_Name = "Module2"
Option Explicit
    Const strRFC2822 = "[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!" & _
                        "#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:" & _
                        "[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:" & _
                        "[a-z0-9-]*[a-z0-9])?"
                        
Function IsMail(ByVal strEmail As String) As Boolean
    Dim objRegEx As Object
    On Error GoTo Fin
    Set objRegEx = CreateObject("Vbscript.Regexp")
    With objRegEx
        .Pattern = strRFC2822
        .IgnoreCase = True
        IsMail = .Test(strEmail)
    End With
Fin:
    Set objRegEx = Nothing
    If Err.Number <> 0 Then MsgBox "Error: " & _
        Err.Number & " " & Err.Description
End Function




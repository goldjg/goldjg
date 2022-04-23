Public blnSearchComp As Boolean
  
Private Sub Application_AdvancedSearchComplete(ByVal SearchObject As Search)
    Debug.Print "The AdvancedSearchComplete Event fired"
    If SearchObject.Tag = "Test" Then
        blnSearchComp = True
    End If
  
End Sub
  
Sub TestAdvancedSearchComplete()
    Dim sch As Outlook.Search
    Dim rsts As Outlook.Results
    Dim i As Integer
    blnSearchComp = False
    Const strF As String = "urn:schemas:mailheader:subject = '##REDACTED##'"
    Const strS As String = "'Folders\LOGS'"
    Set sch = Application.AdvancedSearch(strS, strF, False, "Test")
    While blnSearchComp = False
        DoEvents
    Wend
    Set rsts = sch.Results
    For i = 1 To rsts.Count
        MsgBox rsts.Item(i).SenderName & vbCrLf & rsts.Item(i).Body & vbCrLf & rsts.Item(i).ReceivedTime
    Next
End Sub

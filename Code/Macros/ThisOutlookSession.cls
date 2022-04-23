VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ThisOutlookSession"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = True
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
    Dim intCnt As Integer
    Dim strMissing As String
    Dim strMissingSender As String
    Dim intMissing As Integer
    Dim cmp
        blnSearchComp = False
    Const strF As String = "urn:schemas:mailheader:subject = '##REDACTED##'"
    Const strS As String = "'Folders\LOGS'"
    Set sch = Application.AdvancedSearch(strS, strF, False, "Test")
    While blnSearchComp = False
        DoEvents
    Wend
    Set rsts = sch.Results
    
    Dim SearchTokens(1 To 11) As String 'Setup array for search tokens
    Dim Token As String
    Dim intToken As Integer
           
    'Populate SearchTokens array with tokens to be searched for
    SearchTokens(1) = "system: ##REDACTED##"
    SearchTokens(2) = "system: ##REDACTED##"
    SearchTokens(3) = "system: ##REDACTED##"
    SearchTokens(4) = "system: ##REDACTED##"
    SearchTokens(5) = "system: ##REDACTED##"
    SearchTokens(6) = "system: ##REDACTED##"
    SearchTokens(7) = "system: ##REDACTED##"
    SearchTokens(8) = "system: ##REDACTED##"
    SearchTokens(9) = "system: ##REDACTED##"
    SearchTokens(10) = "system: ##REDACTED##"
    SearchTokens(11) = "system: ##REDACTED##"
    
    For intCnt = 1 To rsts.Count
    
        'Loop through the SearchTokens array.
        'For each token, scan the sheet for that token, add the row for each found cell into a range.
        For intToken = 1 To UBound(SearchTokens)
            Token = SearchTokens(intToken)
            Do
                Set cmp = Nothing
                cmp = InStr(1, rsts.Item(intCnt).Body, Token, vbTextCompare)
                If cmp <> 0 Then
                    strMissing = strMissing & Token & ","
                    strMissingSender = strMissingSender & rsts.Item(intCnt).SenderName & ","
                    intMissing = intMissing + 1
                    Exit Do
                Else
                Exit Do
                End If
            Loop
        Next intToken
    
    Next intCnt
    
    If intMissing < rsts.Count Then
        MsgBox "The following " & intMissing & " emails were missing:" & vbCrLf & strMissing & vbCrLf & strMissingSender
    ElseIf intMissing = rsts.Count Then
        MsgBox "All emails recieved today"
    End If
End Sub




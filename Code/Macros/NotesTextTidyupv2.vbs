Sub NotesTextTidyupV2()
'
' NotesTextTidyup Macro v2
' Macro created 28/07/2005 by Graham Gold
'

    Do Until ActiveDocument.Bookmarks("\Sel") = _
    ActiveDocument.Bookmarks("\EndOfDoc")
    
'begin search and replace/editing

Dim mySearch As String
mySearch = "Received:"

With Selection.Find
    bFound = .Execute(findtext:=mySearch, Forward:=True, Wrap:=wdFindStop)
    Selection.MoveRight Unit:=wdSentence, Count:=50, Extend:=wdExtend
    Selection.Delete
  End With
 
 If bFound = "False" Then Exit Do
 
 Loop
End Sub
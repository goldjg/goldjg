Sub NotesTextTidyup()
'
' NotesTextTidyup Macro
' Macro created 28/07/2005 by Graham Gold
'
    Do Until ActiveDocument.Bookmarks("\Sel") = _
    ActiveDocument.Bookmarks("\EndOfDoc")

'begin search and replace/editing

Dim var
Dim mySearch(22) As String
mySearch(0) = "Received:"
mySearch(1) = "ReplyTo:"
mySearch(2) = "From:"
mySearch(3) = "SendTo:"
mySearch(4) = "Subject:"
mySearch(5) = "PostedDate:"
mySearch(6) = "$MessageID:"
mySearch(7) = "MIME_Version:"
mySearch(8) = "DeliveryPriority:"
mySearch(9) = "X_MSMail_Priority:"
mySearch(10) = "$Mailer:"
mySearch(11) = "Importance:"
mySearch(12) = "$MIMETrack:"
mySearch(13) = "SMTPOriginator:"
mySearch(14) = "NAI101567:"
mySearch(15) = "RouteServers:"
mySearch(16) = "RouteTimes:"
mySearch(17) = "$Orig:"
mySearch(18) = "RoutingState:"
mySearch(19) = "$UpdatedBy:"
mySearch(20) = "Categories:"
mySearch(21) = "$Revisions:"
mySearch(22) = "$MsgTrackFlags:"

With Selection.Find
  For var = 0 To 22
   Do While (.Execute(findtext:=mySearch(var), Forward:=True) = True) = True
    Selection.MoveRight Unit:=wdSentence, Count:=1, Extend:=wdExtend
    Selection.Delete
    Selection.HomeKey Unit:=wdStory
       Loop
    Next
  End With
Loop
End Sub
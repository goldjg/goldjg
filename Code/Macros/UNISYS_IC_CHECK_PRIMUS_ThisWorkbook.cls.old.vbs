VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ThisWorkbook"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = True
Sub Update_Query()
'################################################################################
'#  Update_Query Sub                                                            #
'#  ~~~~~~~~~~~~~~~~                                                            #
'#  Author:      Graham Gold                                                    #
'#  Created:     20th May 2013                                                  #
'#  Parameters:  None                                                           #
'#  Description: Checks Unisys site using Web Query in Query_Res sheet to get a #
'#               list of products and current IC level/date.                    #
'#               Updates appropriate sheets with information.                   #
'################################################################################
'#  VERSION CONTROL                                                             #
'#  ~~~~~~~~~~~~~~~                                                             #
'#  [V1.0.0]    INITIAL IMPLEMENTATION              {Graham Gold - 20/05/2013}  #
'################################################################################
'[Initialise Variables]
Dim Ans As Long
Dim objQuerySheet As Worksheet
Dim iUpd As Integer
Dim sTmp As String

'[Prompt to remind user to login to Unisys support site first and authentication for web query picked up from browser]
Ans = MsgBox("Ensure you have logged in to Unisys Product Support site before continuing with PRIMUS search", vbOKCancel)
If Ans = vbCancel Then
    Exit Sub
End If

'[Select query sheet and refresh the querytable]
Set objQuerySheet = Sheets("Query_Res")
objQuerySheet.QueryTables(1).Refresh

'[Select WHAT_CHANGED sheet]
Set objMainSheet = Sheets("WHAT_CHANGED")

'[Select A1 cell on Query_Res sheet, copy to sTmp, copy data of this sheet to NEW_FIXES sheet]
Sheets("Query_Res").Select
sTmp = Range("A1")
Sheets("Query_Res").Select
Columns("A:C").Select
Selection.Copy
Sheets("NEW_FIXES").Select
Selection.PasteSpecial Paste:=xlPasteValues, Operation:=xlNone, SkipBlanks _
    :=False, Transpose:=False

'[Select WHAT_CHANGED sheet and update iUpd using calculated value in cell E1 for number of updated products.
' Cell counts cells in column E that contain "http" at start of cell]
Sheets("WHAT_CHANGED").Select
iUpd = Range("E1")

'[Check if refresh worked (Query_Res!A1 should contain the word "Product")]
If sTmp = "Product" Then
    '[No updated products]
    Select Case iUpd
    Case 0:
    '[Advise user and prompt to update local datastore]
    Ans = MsgBox("Unisys Primus query successful - No updated products found." & vbCrLf & "Would you like to update the local datastore?", vbYesNo)
    
    '[user clicked yes, so copy NEW_FIXES to PREV_FIXES, update PRIMUS and Datastore update timestamps on WHAT_CHANGED sheet and call Hide_NoUpdate]
    If Ans = vbYes Then
        Sheets("NEW_FIXES").Select
        Columns("A:C").Select
        Selection.Copy
        Sheets("PREV_FIXES").Select
        Selection.PasteSpecial Paste:=xlPasteValues, Operation:=xlNone, SkipBlanks _
            :=False, Transpose:=False
        Sheets("WHAT_CHANGED").Select
        Range("B2").Value = Date & " " & Time
        Range("B3").Value = Date & " " & Time
        Call Hide_NoUpdate
    Else
        '[user pressed no, so just warn that datastore not up to date, and update PRIMUS last update timestamp then call Hide_NoUpdate]
        MsgBox "Warning: Local datastore may not be up to date!", vbCritical
        Sheets("WHAT_CHANGED").Select
        Range("B2").Value = Date & " " & Time
        Call Hide_NoUpdate
    End If
    
    Case Else
    '[more than one updated product, advise user and primpt to update local datastore]
    Ans = MsgBox("Unisys Primus query successful - " & iUpd & " updated products found." & vbCrLf & "Would you like to update the local datastore?", vbYesNo)
    
    '[user clicked yes, so copy NEW_FIXES to PREV_FIXES, update PRIMUS and Datastore update timestamps on WHAT_CHANGED sheet and call Hide_NoUpdate]
    If Ans = vbYes Then
        Sheets("NEW_FIXES").Select
        Columns("A:C").Select
        Selection.Copy
        Sheets("PREV_FIXES").Select
        Selection.PasteSpecial Paste:=xlPasteValues, Operation:=xlNone, SkipBlanks _
            :=False, Transpose:=False
        Sheets("WHAT_CHANGED").Select
        Range("B2").Value = Date & " " & Time
        Range("B3").Value = Date & " " & Time
        Call Hide_NoUpdate
    Else
        '[user pressed no, so just warn that datastore not up to date, and update PRIMUS last update timestamp then call Hide_NoUpdate]
        MsgBox "Warning: Local datastore may not be up to date!", vbCritical
        Sheets("WHAT_CHANGED").Select
        Range("B2").Value = Date & " " & Time
        Call Hide_NoUpdate
    End If

    End Select
    
Else
    '[Update from PRIMUS failed - query returned login screen]
    MsgBox "Please login to Unisys support site before opening this spreadsheet"
    Sheets("WHAT_CHANGED").Select
End If
End Sub

Sub Update_Local()
'################################################################################
'#  Update_Local Sub                                                            #
'#  ~~~~~~~~~~~~~~~~                                                            #
'#  Author:      Graham Gold                                                    #
'#  Created:     20th May 2013                                                  #
'#  Parameters:  None                                                           #
'#  Description: Updates PREV_FIXES sheet with data from NEW_FIXES.             #
'################################################################################
'#  VERSION CONTROL                                                             #
'#  ~~~~~~~~~~~~~~~                                                             #
'#  [V1.0.0]    INITIAL IMPLEMENTATION              {Graham Gold - 20/05/2013}  #
'################################################################################
'[Select NEW_FIXES sheet and data]
Sheets("NEW_FIXES").Select
Columns("A:C").Select

'[Copy data]
Selection.Copy

'[Select PREV_FIXES and paste in the data]
Sheets("PREV_FIXES").Select
Selection.PasteSpecial Paste:=xlPasteValues, Operation:=xlNone, SkipBlanks _
        :=False, Transpose:=False

'[Select WHAT_CHANGED sheet, update the Datastore update timestamp and call Hide_No_Update]
Sheets("WHAT_CHANGED").Select
Range("B3").Value = Date & " " & Time
Call Hide_NoUpdate
End Sub

Sub Hide_NoUpdate()
'################################################################################
'#  Hide_NoUpdate Sub                                                           #
'#  ~~~~~~~~~~~~~~~~~                                                           #
'#  Author:      Graham Gold                                                    #
'#  Created:     20th May 2013                                                  #
'#  Parameters:  None                                                           #
'#  Description: Re-applies AutoFilter on WHAT_CHANGED sheet and autofits rows. #
'#               This code also in the worksheet_Change sub for the worksheets  #
'#               PREV_FIXES, NEW_FIXES and Query_Res.                           #
'################################################################################
'#  VERSION CONTROL                                                             #
'#  ~~~~~~~~~~~~~~~                                                             #
'#  [V1.0.0]    INITIAL IMPLEMENTATION              {Graham Gold - 20/05/2013}  #
'################################################################################
    With ActiveWorkbook.Worksheets("WHAT_CHANGED").ListObjects("Table2")
         .AutoFilter.ApplyFilter
    End With
    With ActiveWorkbook.Worksheets("WHAT_CHANGED").Range("A:A")
        .Rows.EntireRow.AutoFit
    End With
End Sub


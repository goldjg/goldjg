Attribute VB_Name = "Module1"
Sub Format_JobStats()
Attribute Format_JobStats.VB_ProcData.VB_Invoke_Func = "m\n14"
'
' Format_JobStats Macro
' Macro recorded 25/06/2010 by Graham Gold
'
' Keyboard Shortcut: Ctrl+m
'
    Columns("J:N").Select
    Selection.Delete Shift:=xlToLeft
    Columns("K:O").Select
    Selection.Delete Shift:=xlToLeft
    Columns("M:AA").Select
    Selection.Delete Shift:=xlToLeft
    ActiveWindow.LargeScroll ToRight:=-1
    Cells.Select
    Range("M1").Activate
    ActiveWindow.Zoom = 85
    ActiveWindow.Zoom = 70
    ActiveWindow.LargeScroll ToRight:=-1
    Range("A2").Select
    With ActiveWindow
        .SplitColumn = 0
        .SplitRow = 1
    End With
    ActiveWindow.FreezePanes = True
    Rows("1:1").Select
    Selection.Font.Bold = True
    Cells.Select
    Cells.EntireColumn.AutoFit
    
    Dim rng As Range, cell As Range, del As Range
    Set rng = Intersect(Range("D:D"), ActiveSheet.UsedRange)
    For Each cell In rng
        If (cell.Value) = "0" _
        Then
            If del Is Nothing Then
                Set del = cell
            Else: Set del = Union(del, cell)
            End If
        End If
    Next cell
    On Error Resume Next
    del.EntireRow.Delete

    Set rng = Intersect(Range("E:E"), ActiveSheet.UsedRange)
    Set cell = Nothing
    Set del = Nothing
    For Each cell In rng
        If (cell.Value) = "0" _
        Then
            If del Is Nothing Then
                Set del = cell
            Else: Set del = Union(del, cell)
            End If
        End If
    Next cell
    On Error Resume Next
    del.EntireRow.Delete
    
    Dim SearchTokens(1 To 33) As String
    Dim Token As String
    Dim i As Integer
        
    Set rng = Nothing
    
    SearchTokens(1) = "##REDACTED##"
    SearchTokens(2) = "##REDACTED##"
    SearchTokens(3) = "##REDACTED##"    
        
    For i = 1 To UBound(SearchTokens)
        Token = SearchTokens(i)
        Do
            Set rng = ActiveSheet.UsedRange.Find(Token)
            If rng Is Nothing Then
                Exit Do
            Else
                Rows(rng.Row).Delete
            End If
        Loop
    Next i

End Sub

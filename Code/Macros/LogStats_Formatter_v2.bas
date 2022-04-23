Attribute VB_Name = "Module1"
Sub Format_JobStats()
Attribute Format_JobStats.VB_ProcData.VB_Invoke_Func = "m\n14"
'
' Format_JobStats Macro
' Macro recorded 25/06/2010 by Graham Gold
'
' Keyboard Shortcut: Ctrl+m
'
    Dim s
    Dim s2
    ChDrive "c:"
    ChDir "c:\"
    s = Application.GetOpenFilename("Text Files (*.txt), *.txt", , "Open TXT file")
    If s <> False Then ' user pressed cancel
        Workbooks.OpenText (s)
    Workbooks.OpenText Filename:=s, Origin:=xlMSDOS, StartRow:=1 _
        , DataType:=xlDelimited, TextQualifier:=xlDoubleQuote, _
        ConsecutiveDelimiter:=False, Tab:=False, Semicolon:=False, Comma:=True _
        , Space:=False, Other:=False, FieldInfo:=Array(Array(1, 1), Array(2, 1), _
        Array(3, 1), Array(4, 1), Array(5, 1), Array(6, 1), Array(7, 1), Array(8, 1), Array(9, 1), _
        Array(10, 9), Array(11, 9), Array(12, 9), Array(13, 9), Array(14, 9), Array(15, 1), Array( _
        16, 9), Array(17, 9), Array(18, 9), Array(19, 9), Array(20, 9), Array(21, 1), Array(22, 1), _
        Array(23, 9), Array(24, 9), Array(25, 9), Array(26, 9), Array(27, 9), Array(28, 9), Array( _
        29, 9), Array(30, 9), Array(31, 9), Array(32, 9), Array(33, 9), Array(34, 9), Array(35, 9), _
        Array(36, 9), Array(37, 9), Array(38, 1)), TrailingMinusNumbers:=True
    Else: Exit Sub
    End If

    Cells.Select
    Range("M1").Activate
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
    
    Application.ScreenUpdating = False
    
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
    
    Dim SearchTokens(1 To 3) As String
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
      
    Set rng = Intersect(Range("L:L"), ActiveSheet.UsedRange)
    Set cell = Nothing
    Set del = Nothing
    For Each cell In rng
        If cell.Value <> "" Then
        Application.Calculation = xlCalculationManual
        Application.EnableEvents = False
        cell.Value = cell.Value / 86400
        Application.Calculation = xlCalculationAutomatic
        Application.EnableEvents = True
        End If
    Next cell
    On Error Resume Next
    
    Columns("K:L").Select
    Selection.NumberFormat = "[hh]:mm"
    Columns("D:D").Select
    Selection.NumberFormat = "0000"
    Columns("G:G").Select
    Selection.NumberFormat = "0000"
        Columns("I:I").Select
    Selection.NumberFormat = "0000"
    Cells.Select
    Range("L1").Activate
    Selection.Sort Key1:=Range("F2"), Order1:=xlAscending, Key2:=Range("C2") _
        , Order2:=xlAscending, Key3:=Range("G2"), Order3:=xlAscending, Header:= _
        xlGuess, OrderCustom:=1, MatchCase:=False, Orientation:=xlTopToBottom, _
        DataOption1:=xlSortNormal, DataOption2:=xlSortNormal, DataOption3:= _
        xlSortNormal
    
    Columns("C:C").Select
    Selection.Insert Shift:=xlToRight
    Range("C2").Select
    ActiveCell.FormulaR1C1 = "=LEFT(RC[1],2)"
    Range("C2").Select
    Selection.Copy
    Columns("C:C").Select
    Selection.PasteSpecial Paste:=xlPasteFormulas, Operation:=xlNone, _
        SkipBlanks:=False, Transpose:=False
    Range("C1").Select
    Application.CutCopyMode = False
    Selection.ClearContents
    ActiveCell.FormulaR1C1 = "SUITE"
        Columns("A:N").Select
    Range("C1").Activate
    Selection.AutoFilter
    Range("A2").Select
    Sheets(1).Select
    Sheets(1).Name = "LOGSTATS"
    Sheets.Add
    Sheets("Sheet1").Select
    Sheets("Sheet1").Name = "LOGSTATS(2HR)"
    Sheets("LOGSTATS(2HR)").Select
    Sheets("LOGSTATS(2HR)").Move After:=Sheets(2)
    Sheets("LOGSTATS").Select
    Columns("A:N").Select
    Range("A2").Activate
    Selection.Copy
    Sheets("LOGSTATS(2HR)").Select
    ActiveSheet.Paste
    Sheets("LOGSTATS(2HR)").Select
    ActiveWindow.Zoom = 70
    ActiveWindow.SmallScroll Down:=-15
    Range("A2").Select
    With ActiveWindow
        .SplitColumn = 0
        .SplitRow = 1
    End With
    ActiveWindow.FreezePanes = True
    Columns("A:N").Select
    Range("A2").Activate
    Application.CutCopyMode = False
    Selection.AutoFilter
    Selection.AutoFilter Field:=12, Criteria1:="<02:00", Operator:=xlAnd
    Selection.Delete
    ActiveWindow.SmallScroll Down:=-15
    Range("A1").Select
    Sheets("LOGSTATS").Select
    Range("A1").Select
    Application.ScreenUpdating = True
    s2 = Left(s, ((Len(s)) - 4))
    ActiveWorkbook.SaveAs Filename:=s2, FileFormat:=xlExcel9795, _
        Password:="", WriteResPassword:="", ReadOnlyRecommended:=False, _
        CreateBackup:=False
    MsgBox ("Processing Complete")
End Sub

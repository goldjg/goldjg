Sub Format_FTP_Logs()
'
' Format_FTP_Logs Macro
' Macro recorded 25/04/2007 by Graham Gold
'
' Keyboard Shortcut: Ctrl+f
'

    Dim s

    ChDrive "c:"
    ChDir "c:\"
    s = Application.GetOpenFilename("Text Files (*.txt,*.log), *.txt,*.log", , "Open FTP Log File")
    If s <> False Then ' user pressed cancel
        Workbooks.OpenText (s)
    End If
    
    Workbooks.OpenText Filename:=s, Origin:=xlMSDOS, StartRow:= _
        1, DataType:=xlDelimited, TextQualifier:=xlDoubleQuote, _
        ConsecutiveDelimiter:=False, Tab:=True, Semicolon:=False, Comma:=False _
        , Space:=False, Other:=False, FieldInfo:=Array(1, 1), _
        TrailingMinusNumbers:=True


    Call Format1
    Call Format2
    Columns("A:A").Select
    Call DeleteRowOnCell
    Range("A1").Select

End Sub
Sub Format1()
    Range("A1").Select
        With Selection.Font
        .Name = "Arial"
        .Size = 9
        .Strikethrough = False
        .Superscript = False
        .Subscript = False
        .OutlineFont = False
        .Shadow = False
        .Underline = xlUnderlineStyleNone
        .ColorIndex = xlAutomatic
    End With
    
    Range("A1").Select
    Cells.Replace what:="LOGANALYZER*", Replacement:="", lookat:=xlPart, _
        searchorder:=xlByColumns, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False
    Cells.Replace what:="MCP *", Replacement:="", lookat:=xlPart, _
        searchorder:=xlByColumns, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False
    Cells.Replace what:="ANALYZED BY *", Replacement:="", lookat:=xlPart, _
        searchorder:=xlByColumns, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False
    Cells.Replace what:="REQUEST: *", Replacement:="", lookat:=xlPart, _
        searchorder:=xlByColumns, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False
    Cells.Replace what:="SUMLOG #*", Replacement:="", lookat:=xlPart, _
        searchorder:=xlByColumns, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False
    Cells.Replace what:="TITLE =*", Replacement:="", lookat:=xlPart, _
        searchorder:=xlByColumns, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False
    Cells.Replace what:="FILE CONTAINS*", Replacement:="", lookat:=xlPart, _
        searchorder:=xlByColumns, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False
    Cells.Replace what:="HWERRORSUPPORT*", Replacement:="", lookat:=xlPart, _
        searchorder:=xlByColumns, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False
    Cells.Replace what:="                          ", Replacement:="", lookat:=xlPart, _
        searchorder:=xlByColumns, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False
    Cells.Replace what:="TYPE:*", Replacement:="", lookat:=xlPart, _
        searchorder:=xlByColumns, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False
    Cells.Replace what:="STRUCTURE:*", Replacement:="", lookat:=xlPart, _
        searchorder:=xlByColumns, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False
    Cells.Replace what:="MODE:*", Replacement:="", lookat:=xlPart, _
        searchorder:=xlByColumns, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False
    Cells.Replace what:="PORT:*", Replacement:="", lookat:=xlPart, _
        searchorder:=xlByColumns, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False
    Cells.Replace what:="PROCESSOR TIME:*", Replacement:="", lookat:=xlPart, _
        searchorder:=xlByColumns, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False
    Cells.Replace what:="I/O TIME:*", Replacement:="", lookat:=xlPart, _
        searchorder:=xlByColumns, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False
    Cells.Replace what:="NORMAL TERM*", Replacement:="", lookat:=xlPart, _
        searchorder:=xlByColumns, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False

    Columns("A:A").Select
    Selection.TextToColumns Destination:=Range("A1"), DataType:=xlDelimited, _
        TextQualifier:=xlDoubleQuote, ConsecutiveDelimiter:=True, Tab:=False, _
        Semicolon:=False, Comma:=False, Space:=True, Other:=False, FieldInfo _
        :=Array(Array(1, 1), Array(2, 1), Array(3, 1), Array(4, 1), Array(5, 1), Array(6, 1), _
        Array(7, 1), Array(8, 1), Array(9, 1)), TrailingMinusNumbers:=True
    Range("A1").Select
    Cells.Replace what:="DISK:*", Replacement:="", lookat:=xlPart, _
        searchorder:=xlByColumns, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False
    Cells.Replace what:="ELAPSED", Replacement:="", lookat:=xlWhole, _
        searchorder:=xlByColumns, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False
    Cells.Replace what:="FTP", Replacement:="", lookat:=xlWhole, searchorder _
        :=xlByColumns, MatchCase:=False, SearchFormat:=False, ReplaceFormat:= _
        False
    Cells.Replace what:="TIME:*", Replacement:="", lookat:=xlPart, _
        searchorder:=xlByColumns, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False
    Cells.Replace what:="TO", Replacement:="OUTBOUND", lookat:=xlWhole, _
        searchorder:=xlByColumns, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False
    Cells.Replace what:="FROM", Replacement:="INBOUND", lookat:=xlWhole, _
        searchorder:=xlByColumns, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False
    Columns("D:D").Select
    Selection.Delete Shift:=xlToLeft
    Columns("E:E").Select
    Selection.Delete Shift:=xlToLeft
    
    Range("A1").Select
    Cells.Replace what:="Octets,", Replacement:="", lookat:=xlPart, _
        searchorder:=xlByColumns, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False
    Cells.Replace what:="I/Os", Replacement:="", lookat:=xlPart, searchorder _
        :=xlByColumns, MatchCase:=False, SearchFormat:=False, ReplaceFormat:= _
        False
    Columns("A:A").Select
    Selection.NumberFormat = "hh:mm:ss"
    Columns("B:B").Select
    Selection.NumberFormat = "0"
    Columns("C:C").Select
    Selection.NumberFormat = "hh:mm:ss"
    Columns("A:A").EntireColumn.AutoFit
    Cells.Replace what:="*day,", Replacement:="", lookat:=xlPart, _
        searchorder:=xlByColumns, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False
    Cells.Replace what:="~*", Replacement:="", lookat:=xlPart, _
        searchorder:=xlByColumns, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False
    Range("A1").Select
    Columns("A:A").EntireColumn.AutoFit
    Columns("B:B").EntireColumn.AutoFit
    Columns("C:C").EntireColumn.AutoFit
    Cells.Replace what:="* 00:00:00", Replacement:="", lookat:=xlPart, _
        searchorder:=xlByColumns, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False
    Columns("D:D").EntireColumn.AutoFit
    Columns("E:E").EntireColumn.AutoFit
    Columns("F:F").EntireColumn.AutoFit
    Columns("G:G").EntireColumn.AutoFit
    
    Cells.Select
    With Selection.Font
        .Name = "Arial"
        .Size = 9
        .Strikethrough = False
        .Superscript = False
        .Subscript = False
        .OutlineFont = False
        .Shadow = False
        .Underline = xlUnderlineStyleNone
        .ColorIndex = xlAutomatic
    End With
    Cells.EntireColumn.AutoFit
    Cells.EntireColumn.AutoFit
    Cells.EntireColumn.AutoFit
    Cells.EntireColumn.AutoFit
    Cells.EntireColumn.AutoFit
    Cells.EntireColumn.AutoFit
    Cells.EntireColumn.AutoFit
    Range("A1").Select
    ActiveCell.FormulaR1C1 = "Transfer Start Time"
    Range("B1").Select
    ActiveCell.FormulaR1C1 = "Bytes Transferred"
    Range("C1").Select
    ActiveCell.FormulaR1C1 = "Time Elapsed (hh:mm:ss)"
    Range("D1").Select
    ActiveCell.FormulaR1C1 = "File Name"
    Range("E1").Select
    ActiveCell.FormulaR1C1 = "Mainframe File Location"
    Range("F1").Select
    ActiveCell.FormulaR1C1 = "Transfer Type"
    Range("G1").Select
    ActiveCell.FormulaR1C1 = "Source/Destination Server"
    Rows("1:1").Select
    Selection.Font.Bold = True
    Columns("A:A").EntireColumn.AutoFit
    Columns("B:B").EntireColumn.AutoFit
    Columns("C:C").EntireColumn.AutoFit
    Columns("D:D").EntireColumn.AutoFit
    Columns("E:E").EntireColumn.AutoFit
    Columns("F:F").EntireColumn.AutoFit
    Columns("G:G").EntireColumn.AutoFit
    Range("A:C,E:E,F:F,G:G").Select
    Range("G1").Activate
    With Selection
        .HorizontalAlignment = xlCenter
        .VerticalAlignment = xlBottom
        .WrapText = False
        .Orientation = 0
        .AddIndent = False
        .IndentLevel = 0
        .ShrinkToFit = False
        .ReadingOrder = xlContext
        .MergeCells = False
    End With
    Range("D1").Select
    With Selection
        .HorizontalAlignment = xlCenter
        .VerticalAlignment = xlBottom
        .WrapText = False
        .Orientation = 0
        .AddIndent = False
        .IndentLevel = 0
        .ShrinkToFit = False
        .ReadingOrder = xlContext
        .MergeCells = False
    End With
    Range("A1:G1").Select
    Selection.Borders(xlDiagonalDown).LineStyle = xlNone
    Selection.Borders(xlDiagonalUp).LineStyle = xlNone
    With Selection.Borders(xlEdgeLeft)
        .LineStyle = xlContinuous
        .Weight = xlThin
        .ColorIndex = xlAutomatic
    End With
    With Selection.Borders(xlEdgeTop)
        .LineStyle = xlContinuous
        .Weight = xlThin
        .ColorIndex = xlAutomatic
    End With
    With Selection.Borders(xlEdgeBottom)
        .LineStyle = xlContinuous
        .Weight = xlThin
        .ColorIndex = xlAutomatic
    End With
    With Selection.Borders(xlEdgeRight)
        .LineStyle = xlContinuous
        .Weight = xlThin
        .ColorIndex = xlAutomatic
    End With
    With Selection.Borders(xlInsideVertical)
        .LineStyle = xlContinuous
        .Weight = xlThin
        .ColorIndex = xlAutomatic
    End With
    With Selection.Interior
        .ColorIndex = 37
        .Pattern = xlSolid
        .PatternColorIndex = xlAutomatic
    End With
    Range("A2").Select
    With ActiveWindow
        .SplitColumn = 0
        .SplitRow = 1
    End With

    ActiveWindow.FreezePanes = True
    Columns("D:D").Select
    Selection.Insert Shift:=xlToRight
    Range("D1").Select
    ActiveCell.FormulaR1C1 = "Transfer Rate (Kbps)"
    
End Sub
Sub Format2()

Range("B15:B18").Select
Selection.Delete Shift:=xlUp
    
Range("C15:C22").Select
Selection.Delete Shift:=xlUp
  
End Sub

Public Sub DeleteRowOnCell()

On Error Resume Next
Selection.SpecialCells(xlCellTypeBlanks).EntireRow.Delete
ActiveSheet.UsedRange

End Sub






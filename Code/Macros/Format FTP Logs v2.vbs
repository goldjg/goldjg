Sub Format_FTP_Logs(Optional WorksheetName As Variant)
'
' Format_FTP_Logs Macro
' Macro recorded 25/04/2007 by Graham Gold
'
' Keyboard Shortcut: Ctrl+f
'

    Dim s
    Dim RefColl As Collection
    Dim RowNum As Long
    Dim Prec As Range
    Dim Rng As Range
    Dim DeleteRange As Range
    Dim LastRow As Long
    Dim FormulaCells As Range
    Dim Test As Long
    Dim WS As Worksheet
    Dim PrecCell As Range

    ChDrive "c:"
    ChDir "c:\"
    s = Application.GetOpenFilename("Text Files (*.txt), *.txt", , "Open FTP Log File")
    If s <> False Then ' user pressed cancel
        Workbooks.OpenText (s)
    End If
    
    Workbooks.OpenText Filename:=s, Origin:=xlMSDOS, StartRow:= _
        1, DataType:=xlDelimited, TextQualifier:=xlDoubleQuote, _
        ConsecutiveDelimiter:=False, Tab:=True, Semicolon:=False, Comma:=False _
        , Space:=False, Other:=False, FieldInfo:=Array(1, 1), _
        TrailingMinusNumbers:=True

    Range("A1").Select
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
    Cells.Replace What:="DISK:*", Replacement:="", LookAt:=xlPart, _
        SearchOrder:=xlByColumns, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False
    Cells.Replace What:="ELAPSED", Replacement:="", LookAt:=xlWhole, _
        SearchOrder:=xlByColumns, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False
    Cells.Replace What:="FTP", Replacement:="", LookAt:=xlWhole, SearchOrder _
        :=xlByColumns, MatchCase:=False, SearchFormat:=False, ReplaceFormat:= _
        False
    Cells.Replace What:="TIME:*", Replacement:="", LookAt:=xlPart, _
        SearchOrder:=xlByColumns, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False
    Cells.Replace What:="TO", Replacement:="OUTBOUND", LookAt:=xlWhole, _
        SearchOrder:=xlByColumns, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False
    Cells.Replace What:="FROM", Replacement:="INBOUND", LookAt:=xlWhole, _
        SearchOrder:=xlByColumns, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False
    Columns("D:D").Select
    Selection.Delete Shift:=xlToLeft
    Columns("E:E").Select
    Selection.Delete Shift:=xlToLeft
    Range("A1").Select
    Cells.Replace What:="Octets,", Replacement:="", LookAt:=xlPart, _
        SearchOrder:=xlByColumns, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False
    Cells.Replace What:="I/Os", Replacement:="", LookAt:=xlPart, SearchOrder _
        :=xlByColumns, MatchCase:=False, SearchFormat:=False, ReplaceFormat:= _
        False
    Columns("A:A").Select
    Selection.NumberFormat = "h:mm:ss"
    Columns("B:B").Select
    Selection.NumberFormat = "0"
    Columns("C:C").Select
    Selection.NumberFormat = "h:mm:ss"
    Range("B7").Select
    Selection.Delete Shift:=xlUp
    Range("C7").Select
    Selection.Delete Shift:=xlUp
    Selection.Delete Shift:=xlUp
    Columns("A:A").EntireColumn.AutoFit
    Cells.Replace What:="*day,", Replacement:="", LookAt:=xlPart, _
        SearchOrder:=xlByColumns, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False
    Cells.Replace What:="~*", Replacement:="", LookAt:=xlPart, _
        SearchOrder:=xlByColumns, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False
    Range("A1").Select
    Columns("A:A").EntireColumn.AutoFit
    Columns("B:B").EntireColumn.AutoFit
    Columns("C:C").EntireColumn.AutoFit
    Cells.Replace What:="* 00:00:00", Replacement:="", LookAt:=xlPart, _
        SearchOrder:=xlByColumns, MatchCase:=False, SearchFormat:=False, _
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
    Range("D7").Select
        


If IsMissing(WorksheetName) = True Then
    Set WS = ActiveSheet
Else
    On Error Resume Next
    Set WS = ActiveWorkbook.Worksheets(WorksheetName)
    If Err.Number <> 0 Then
        '''''''''''''''''''''''''''''''
        ' Invalid worksheet name.
        '''''''''''''''''''''''''''''''
        Exit Sub
    End If
End If
    

If Application.WorksheetFunction.CountA(WS.UsedRange.Cells) = 0 Then
    ''''''''''''''''''''''''''''''
    ' Worksheet is blank. Get Out.
    ''''''''''''''''''''''''''''''
    Exit Sub
End If

''''''''''''''''''''''''''''''''''''''
' Find the last used cell on the
' worksheet.
''''''''''''''''''''''''''''''''''''''
Set Rng = WS.Cells.Find(what:="*", after:=WS.Cells(WS.Rows.Count, WS.Columns.Count), lookat:=xlPart, _
    searchorder:=xlByColumns, searchdirection:=xlPrevious, MatchCase:=False)

LastRow = Rng.Row

Set RefColl = New Collection

'''''''''''''''''''''''''''''''''''''
' We go from bottom to top to keep
' the references intact, preventing
' #REF errors.
'''''''''''''''''''''''''''''''''''''
For RowNum = LastRow To 1 Step -1
    Set FormulaCells = Nothing
    If Application.WorksheetFunction.CountA(WS.Rows(RowNum)) = 0 Then
        ''''''''''''''''''''''''''''''''''''
        ' There are no non-blank cells in
        ' row R. See if R is in the RefColl
        ' reference Collection. If not,
        ' add row R to the DeleteRange.
        ''''''''''''''''''''''''''''''''''''
        On Error Resume Next
        Test = RefColl(CStr(RowNum))
        If Err.Number <> 0 Then
            ''''''''''''''''''''''''''
            ' R is not in the RefColl
            ' collection. Add it to
            ' the DeleteRange variable.
            ''''''''''''''''''''''''''
            If DeleteRange Is Nothing Then
                Set DeleteRange = WS.Rows(RowNum)
            Else
                Set DeleteRange = Application.Union(DeleteRange, WS.Rows(RowNum))
            End If
        Else
            ''''''''''''''''''''''''''
            ' R is in the collection.
            ' Do nothing.
            ''''''''''''''''''''''''''
        End If
        On Error GoTo 0
        Err.Clear
    Else
        '''''''''''''''''''''''''''''''''''''
        ' CountA > 0. Find the cells
        ' containing formula, and for
        ' each cell with a formula, find
        ' its precedents. Add the row number
        ' of each precedent to the RefColl
        ' collection.
        '''''''''''''''''''''''''''''''''''''
        If IsRowClear(RowNum:=RowNum) = True Then
            '''''''''''''''''''''''''''''''''
            ' Row contains nothing but blank
            ' cells or cells with only an
            ' apostrophe. Cells that contain
            ' only an apostrophe are counted
            ' by CountA, so we use IsRowClear
            ' to test for only apostrophes.
            ' Test if this row is in the
            ' RefColl collection. If it is
            ' not in the collection, add it
            ' to the DeleteRange.
            '''''''''''''''''''''''''''''''''
            On Error Resume Next
            Test = RefColl(CStr(RowNum))
            If Err.Number = 0 Then
                ''''''''''''''''''''''''''''''''''''''
                ' Row exists in RefColl. That means
                ' a formula is referencing this row.
                ' Do not delete the row.
                ''''''''''''''''''''''''''''''''''''''
            Else
                If DeleteRange Is Nothing Then
                    Set DeleteRange = WS.Rows(RowNum)
                Else
                    Set DeleteRange = Application.Union(DeleteRange, WS.Rows(RowNum))
                End If
            End If
        Else
            On Error Resume Next
            Set FormulaCells = Nothing
            Set FormulaCells = WS.Rows(RowNum).SpecialCells(xlCellTypeFormulas)
            On Error GoTo 0
            If FormulaCells Is Nothing Then
                '''''''''''''''''''''''''
                ' No formulas found. Do
                ' nothing.
                '''''''''''''''''''''''''
            Else
                '''''''''''''''''''''''''''''''''''''''''''''''''''
                ' Formulas found. Loop through the formula
                ' cells, and for each cell, find its precedents
                ' and add the row number of each precedent cell
                ' to the RefColl collection.
                '''''''''''''''''''''''''''''''''''''''''''''''''''
                On Error Resume Next
                For Each Rng In FormulaCells.Cells
                    For Each Prec In Rng.Precedents.Cells
                        RefColl.Add Item:=Prec.Row, key:=CStr(Prec.Row)
                    Next Prec
                Next Rng
                On Error GoTo 0
            End If
        End If
        
    End If
    
    '''''''''''''''''''''''''
    ' Go to the next row,
    ' moving upwards.
    '''''''''''''''''''''''''
Next RowNum


''''''''''''''''''''''''''''''''''''''''''
' If we have rows to delete, delete them.
''''''''''''''''''''''''''''''''''''''''''

If Not DeleteRange Is Nothing Then
    DeleteRange.EntireRow.Delete shift:=xlShiftUp
End If

End Sub
Function IsRowClear(RowNum As Long) As Boolean
''''''''''''''''''''''''''''''''''''''''''''''''''
' IsRowClear
' This procedure returns True if all the cells
' in the row specified by RowNum as empty or
' contains only a "'" character. It returns False
' if the row contains only data or formulas.
''''''''''''''''''''''''''''''''''''''''''''''''''
Dim ColNdx As Long
Dim Rng As Range
ColNdx = 1
Set Rng = Cells(RowNum, ColNdx)
Do Until ColNdx = Columns.Count
    If (Rng.HasFormula = True) Or (Rng.Value <> vbNullString) Then
        IsRowClear = False
        Exit Function
    End If
    Set Rng = Cells(RowNum, ColNdx).End(xlToRight)
    ColNdx = Rng.Column
Loop

IsRowClear = True

End Function




Sub Macro1()
'
' Macro1 Macro
'

'
    Range("A1:H14").Select
    ActiveSheet.ListObjects.Add(xlSrcRange, Range("$A$1:$H$14"), , xlYes).Name = _
        "Table1"
    Range("Table1[#All]").Select
    ActiveSheet.ListObjects("Table1").TableStyle = "TableStyleMedium19"
    Columns("E:F").Select
    With Selection
        .HorizontalAlignment = xlGeneral
        .VerticalAlignment = xlBottom
        .WrapText = True
        .Orientation = 0
        .AddIndent = False
        .IndentLevel = 0
        .ShrinkToFit = False
        .ReadingOrder = xlContext
        .MergeCells = False
    End With
    Cells.Select
    Range("Table1[[#Headers],[Description]]").Activate
    With Selection
        .HorizontalAlignment = xlGeneral
        .VerticalAlignment = xlTop
        .Orientation = 0
        .AddIndent = False
        .IndentLevel = 0
        .ShrinkToFit = False
        .ReadingOrder = xlContext
        .MergeCells = False
    End With
    With Selection
        .HorizontalAlignment = xlLeft
        .VerticalAlignment = xlTop
        .Orientation = 0
        .AddIndent = False
        .IndentLevel = 0
        .ShrinkToFit = False
        .ReadingOrder = xlContext
        .MergeCells = False
    End With
    Cells.EntireColumn.AutoFit
    Columns("E:E").Select
    Selection.ColumnWidth = 50
    Columns("G:G").Select
    Selection.ColumnWidth = 40
    Selection.ColumnWidth = 25
    Selection.ColumnWidth = 30
    Columns("H:H").Select
    Selection.ColumnWidth = 40
    Range("Table1[[#Headers],[Identifier]]").Select
End Sub
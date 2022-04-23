Sub Format_Tapelists()
'
' Format_Tapelists Macro
' Macro created 07/08/2006 by Graham Gold
'
' Keyboard Shortcut: Ctrl+l
'
    Dim s
    ChDrive "c:"
    ChDir "c:\"
    s = Application.GetOpenFilename("CSV Files (*.csv), *.csv", , "Open Tapelist")
    If s <> False Then ' user pressed cancel
        Workbooks.OpenText (s)
    
    Workbooks.OpenText Filename:=s, Origin:=xlWindows, StartRow:=1, DataType:=xlDelimited, TextQualifier:=xlDoubleQuote, _
        ConsecutiveDelimiter:=False, Tab:=False, Semicolon:=False, Comma:=True _
        , Space:=False, Other:=False, FieldInfo:=Array(Array(1, 1), Array(2, 1), _
        Array(3, 9), Array(4, 9), Array(5, 9), Array(6, 9), Array(7, 1), Array(8, 1), Array(9, 1), _
        Array(10, 9), Array(11, 9))
    Range("A1:AE19139").Select
    With Selection.Font
        .Name = "Arial"
        .Size = 10
        .Strikethrough = False
        .Superscript = False
        .Subscript = False
        .OutlineFont = False
        .Shadow = False
        .Underline = xlUnderlineStyleNone
        .ColorIndex = xlAutomatic
    End With
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
    Rows("1:1").Select
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
    Range("A:A,D:AF").Select
    Range("D1").Activate
    With Selection
        .HorizontalAlignment = xlGeneral
        .VerticalAlignment = xlBottom
        .WrapText = False
        .Orientation = 0
        .AddIndent = False
        .IndentLevel = 0
        .ShrinkToFit = False
        .ReadingOrder = xlContext
        .MergeCells = False
    End With
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
    Columns("B:C").Select
    With Selection
        .HorizontalAlignment = xlLeft
        .VerticalAlignment = xlBottom
        .WrapText = False
        .Orientation = 0
        .AddIndent = False
        .IndentLevel = 0
        .ShrinkToFit = False
        .ReadingOrder = xlContext
        .MergeCells = False
    End With
    Range("B1:C1").Select
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
    Range("A1:AE19139").Select
    Range("B1").Activate
    Selection.Columns.AutoFit
    Rows("1:1").Select
    Selection.Font.Bold = True
    Columns("C:C").Select
    Selection.ColumnWidth = 13.5
    Range("L:L,M:M,O:O,P:P").Select
    Range("P1").Activate
    ActiveWindow.SmallScroll ToRight:=10
    Range("L:L,M:M,O:O,P:P,Q:Q,R:R,U:U,V:V,W:W,X:X,Y:Y").Select
    Range("Y1").Activate
    ActiveWindow.SmallScroll ToRight:=7
    Range("L:L,M:M,O:O,P:P,Q:Q,R:R,U:U,V:V,W:W,X:X,Y:Y,Z:Z,AB:AB,AD:AD,AE:AE"). _
        Select
    Range("AE1").Activate
    Selection.EntireColumn.Hidden = True
    ActiveWindow.LargeScroll ToRight:=-1
    Range("A2").Select
    With ActiveWindow
        .SplitColumn = 0
        .SplitRow = 1
    End With
    ActiveWindow.FreezePanes = True
    Range("A1:AE19139").Select
    Range("A2").Activate
    Selection.Sort Key1:=Range("B2"), Order1:=xlAscending, Key2:=Range("H2") _
        , Order2:=xlAscending, Key3:=Range("I2"), Order3:=xlAscending, Header:= _
        xlGuess, OrderCustom:=1, MatchCase:=False, Orientation:=xlTopToBottom
    Range("A1").Select
    MsgBox "Formatting Complete!"
    End If
End Sub



Sub Format_Movelists()
'
' Format_Movelists Macro
' Macro created 13/12/2004 by Graham Gold
'
' Keyboard Shortcut: Ctrl+l
'
    Dim s
    ChDrive "c:"
    ChDir "c:\"
    s = Application.GetOpenFilename("Text Files (*.txt), *.txt", , "Open Movelist")
    If s <> False Then ' user pressed cancel
        Workbooks.OpenText (s)
    
    Workbooks.OpenText FileName:=s, Origin:=xlWindows, StartRow:=1, DataType:=xlDelimited, TextQualifier:=xlDoubleQuote, _
        ConsecutiveDelimiter:=False, Tab:=False, Semicolon:=False, Comma:=True _
        , Space:=False, Other:=False, FieldInfo:=Array(Array(1, 1), Array(2, 1), _
        Array(3, 9), Array(4, 9), Array(5, 9), Array(6, 9), Array(7, 1), Array(8, 1), Array(9, 1), _
        Array(10, 9), Array(11, 9))
    Columns("A:A").Select
    Selection.ColumnWidth = 17.5
    Columns("B:B").Select
    Selection.ColumnWidth = 15
    Columns("C:C").Select
    Selection.ColumnWidth = 17.5
    Columns("D:D").Select
    Selection.ColumnWidth = 17.5
    Columns("E:E").Select
    Selection.ColumnWidth = 10
    Columns("A:E").Select
    Selection.Sort Key1:=Range("A2"), Order1:=xlAscending, Key2:=Range("B2") _
        , Order2:=xlAscending, Header:=xlGuess, OrderCustom:=1, MatchCase:= _
        False, Orientation:=xlTopToBottom
    Range("A1").Select
    End If
End Sub

Private Declare Sub Sleep Lib "kernel32" (ByVal dwMilliseconds As Long)
Function FileNameFromPath(strFullPath As String) As String
    Dim tmp As String
    tmp = Right(strFullPath, Len(strFullPath) - InStrRev(strFullPath, "\"))
    FileNameFromPath = Left(tmp, ((Len(tmp)) - 4))

End Function
Sub Format_JobStats()
'************************************************************************************
'* Format_JobStats Macro                                                            *
'* =====================                                                            *
'*                                                                                  *
'* Reads in comma separated TXT file from Q: drive produced by                      *
'* ##REDACTED##.                                               *
'*                                                                                  *
'* Strips out data for any entry that is a program, or is a job not matching        *
'* specified criteria.                                                              *
'*                                                                                  *
'* Creates two tab spreadsheet named per original CSV filename.                     *
'*      -LOGSTATS:      Sorted by Begin Date, Job Name, Begin Time.                 *
'*                      Autofilter enabled                                          *
'*      -LOGSTATS(2HR): Sorted by Begin Date, Job Name, Begin Time.                 *
'*                      Autofiltered, show only where elapsed time > 02:00 (HH:MM)  *
'*                                                                                  *
'* VERSION 01 INITIAL IMPLEMENTATION                                 AUG 2010 GXG   *
'* VERSION 02 AMEND PLACEMENT OF RUNTIME PARAMS IN REPORT            AUG 2010 GXG   *
'* VERSION 03 UPDATE FOR OFFICE 2010 COMPATIBILITY                   FEB 2012 GXG   *
'* VERSION 04 UPDATE TO HANDLE DELETION OF READONLY SOURCE FILE      APR 2013 GXG   *
'* VERSION 05 Workaround broken workbooks.opentext in Office 365/                   *
'*            Excel 2016 due to region/international settings for 		    *
'*	      decimal/list separators. (use QueryTables.Add(connection="TEXT;..."   *
'*                                                                   JAN 2017 GXG   *
'************************************************************************************
    Dim s 'Array for file open
    Dim s2 'Array for file save
    Dim sTmp As String 'String for filename extraction
    Dim sName As String 'String for worksheet name
    ChDrive "c:" 'Set drive letter
    ChDir "c:\" 'Set directory
 
    'Launch File Open dialog in directory path set above, showing only .TXT files
    s = Application.GetOpenFilename("Text Files (*.txt), *.txt", , "Open TXT file")
    If s <> False Then ' user pressed cancel
    
    'Open selected file as a comma delimited file,
    'skipping columns for all performance stats except ELAPSED,AVG_ELAPSED
    
    sTmp = CStr(s)
    sName = FileNameFromPath(sTmp)
    sTmp = "TEXT;" + s
    
    Application.CutCopyMode = False
    With ActiveSheet.QueryTables.Add(Connection:= _
        sTmp, Destination:=Range("$A$1"))
        .Name = sName
        .FieldNames = True
        .RowNumbers = False
        .FillAdjacentFormulas = False
        .PreserveFormatting = True
        .RefreshOnFileOpen = False
        .RefreshStyle = xlInsertDeleteCells
        .SavePassword = False
        .SaveData = True
        .AdjustColumnWidth = True
        .RefreshPeriod = 0
        .TextFilePromptOnRefresh = False
        .TextFilePlatform = 850
        .TextFileStartRow = 1
        .TextFileParseType = xlDelimited
        .TextFileTextQualifier = xlTextQualifierDoubleQuote
        .TextFileConsecutiveDelimiter = False
        .TextFileTabDelimiter = False
        .TextFileSemicolonDelimiter = False
        .TextFileCommaDelimiter = True
        .TextFileSpaceDelimiter = False
        .TextFileColumnDataTypes = Array(1, 1, 1, 1, 1, 1, 1, 1, 1, 9, 9, 9, 9, 9, 1, 9, 9, 9, 9, 9, 1, _
        1, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 1)
        .TextFileTrailingMinusNumbers = True
        .Refresh BackgroundQuery:=False
    End With
        
    Else: Exit Sub
    End If

    'Select all cells, set zoom 70%, split at 2nd row, freeze panes (fixed header when scrolling)
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
    
    'Select first row, set Bold font style.
    Rows("1:1").Select
    Selection.Font.Bold = True
    
    'Select all cells, autofit columns to width of cell contents
    Cells.Select
    Cells.EntireColumn.AutoFit
    
    'Disable screen updating while manipulating data. Improves macro performance significantly
    Application.ScreenUpdating = False
    
    'Scan for value of 0 in any cell in Column D (Job number)
    'Indicates that this is a program, not a job
    'For each cell found, add to list for rows to delete.
    Dim rng As Range, cell As Range, del As Range
    Set rng = Intersect(Range("D:D"), ActiveSheet.UsedRange)
    Application.StatusBar = "Stage 1 in progress" 'update status bar to display progress
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
    Application.StatusBar = "Stage 2 in progress" 'update status bar to display progress
    del.EntireRow.Delete 'delete selected rows

    'Scan for value of 0 in any cell in Column E (task number)
    'Indicates that this is a program, not a job
    'For each cell found, add to list for rows to delete.
    Set rng = Intersect(Range("E:E"), ActiveSheet.UsedRange)
    Set cell = Nothing
    Set del = Nothing
    Application.StatusBar = "Stage 3 in progress" 'update status bar to display progress
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
    Application.StatusBar = "Stage 4 in progress" 'update status bar to display progress
    del.EntireRow.Delete 'delete selected rows
    
    'Scan through spreadsheet for cells containing any of a list of search tokens
    'If found, add the row the cell is in to a range for deletion at end of scan
    'This removes entries for jobs not required in the report.
    
    Dim SearchTokens(1 To 3) As String 'Setup array for search tokens
    Dim Token As String
    Dim i As Integer
        
    Set rng = Nothing
    
    'Populate SearchTokens array with tokens to be searched for
    SearchTokens(1) = "##REDACTED##"
    SearchTokens(2) = "##REDACTED##"
    SearchTokens(3) = "##REDACTED##"
    
    'Loop through the SearchTokens array.
    'For each token, scan the sheet for that token, add the row for each found cell into a range.
    For i = 1 To UBound(SearchTokens)
        Token = SearchTokens(i)
        Do
            Application.StatusBar = "Stage 5: Performing scan " & i & " of " & UBound(SearchTokens)
            Application.DisplayStatusBar = True
            Set rng = ActiveSheet.UsedRange.Find(Token)
            If rng Is Nothing Then
                Exit Do
            Else
                Rows(rng.Row).Delete 'When last row searched, delete range of rows that matched current token
            End If
        Loop
    Next i
 
    'Convert time from seconds to fraction of a day (Excel time format)
    'Select column L, for each cell that isn't empty divide the cell by 86400 (60*60*24)
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
    
    'Set cell formats for various columns
    Columns("K:L").Select
    Selection.NumberFormat = "[hh]:mm" 'square brackets mean ignore 24hr clock, just display total hours
    Columns("D:D").Select
    Selection.NumberFormat = "0000" 'show in 4 digit format for hours between midnight and 10am
    Columns("G:G").Select
    Selection.NumberFormat = "0000" 'show in 4 digit format for hours between midnight and 10am
        Columns("I:I").Select
    Selection.NumberFormat = "0000" 'show in 4 digit format for hours between midnight and 10am
    
    'Select all cells and set sort order for sheet.
    'Sort by Begin Date (Ascending), Job Name (Ascending), Begin Time (Ascending)
    Cells.Select
    Range("L1").Activate
    Selection.Sort Key1:=Range("F2"), Order1:=xlAscending, Key2:=Range("C2") _
        , Order2:=xlAscending, Key3:=Range("G2"), Order3:=xlAscending, Header:= _
        xlGuess, OrderCustom:=1, MatchCase:=False, Orientation:=xlTopToBottom, _
        DataOption1:=xlSortNormal, DataOption2:=xlSortNormal, DataOption3:= _
        xlSortNormal
    
    'Insert new column after Usercode (Column B)
    Columns("C:C").Select
    Selection.Insert Shift:=xlToRight
    
    'Find the last used row in the worksheet
    Dim LastRow As Long

    If WorksheetFunction.CountA(Cells) > 0 Then
    LastRow = Cells.Find(what:="*", After:=[A1], _
              SearchOrder:=xlByRows, _
              SearchDirection:=xlPrevious).Row
    End If
    
    'Select all cells in Column C from first row to last used row
    'Set formula in those cells so value becomes first two characters of cell 1 column to the right
    '(Job Suite)
    Range("C2", "C" & LastRow).Select
    Selection.FormulaR1C1 = "=LEFT(RC[1],2)"
    ActiveCell.FormulaR1C1 = "=LEFT(RC[1],2)"

    'Set column header for column C to value "SUITE"
    Range("C1").Select
    Application.CutCopyMode = False
    Selection.ClearContents
    ActiveCell.Value = "SUITE"
    
    'Trim all leading/trailing spaces from cells in columns L, M and N
    Set rng = Intersect(Range("L:N"), ActiveSheet.UsedRange)
    Set cell = Nothing
    Set del = Nothing
    For Each cell In rng
        cell.Value = Trim(cell.Value)
    Next cell
    On Error Resume Next

    'Set cell formats in column N to Text, alignment to left and autofit column to cell value width
    Columns("N:N").Select
    Selection.NumberFormat = "@"
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
    Columns("N:N").EntireColumn.AutoFit

    'Move runtime parameters column after job name column
    Columns("N:N").Select
    Selection.Cut
    Columns("E:E").Select
    Selection.Insert Shift:=xlToRight

    'Select all columns and enable autofilter
    Columns("A:N").Select
    Range("C1").Activate
    Selection.AutoFilter
    Range("A2").Select
    
    'Select current sheet and rename
    Sheets(1).Select
    Sheets(1).Name = "LOGSTATS"
    
    'Copy current sheet and paste as new sheet at end
    Sheets("LOGSTATS").Select
    Sheets("LOGSTATS").Copy After:=Sheets(1)
    Sheets("LOGSTATS (2)").Select
    ActiveWindow.LargeScroll Down:=-8
    
    'Select new sheet, rename
    Sheets("LOGSTATS (2)").Name = "LOGSTATS (2HR)"
    
    'Set auto filter for new sheet, filter on elapsed time greater than 2 hours (02:00)
    Selection.AutoFilter Field:=13, Criteria1:=">02:00", Operator:=xlAnd
    ActiveWindow.SmallScroll Down:=-15
    
    'Select first cell in each sheet, leave first sheet active/in view
    Range("A1").Select
    Range("A2").Activate
    Application.CutCopyMode = False
    ActiveWindow.SmallScroll Down:=-15
    Range("A1").Select
    Sheets("LOGSTATS").Select
    Range("A1").Select
    
    'Enable screen updating, will then show file as it looks now manipulation/formatting complete
    Application.ScreenUpdating = True
    
    'Setup s2 string with original filename, but with extension of .txt removed
    s2 = Left(s, ((Len(s)) - 4))
    
    'Disable display of alerts, so if file already exists, will assume ok to overwrite existing file
    Application.DisplayAlerts = False
    
    'Save as Excel OpenXML Workbook format spreadsheet in same directory as txt file was loaded from.
    ActiveWorkbook.SaveAs Filename:=s2, FileFormat:=xlOpenXMLWorkbook, _
        Password:="", WriteResPassword:="", ReadOnlyRecommended:=False, _
        CreateBackup:=False
        
    'Check if new spreadsheet created, if so delete original file.
    'Application.DisplayAlerts = True
    'Application.StatusBar = "Wait a second..."
    'Sleep 1000
    Application.StatusBar = "Checking new file exists"
    
    'If Dir(s2 & ".xlsx") <> "" Then 'file exists
    '    Application.StatusBar = "New file exists, deleting source file"
    '    Kill (s)
    'End If
        
    With New FileSystemObject
    If .FileExists(s2 & ".xlsx") Then
        Application.StatusBar = "New file exists, deleting source file"
        .DeleteFile s, True
        If Err.Number > 0 Then
            MsgBox ("Error: " & Err.Number & vbCrLf & Err.Description & vbCrLf & "Source: " & Err.Source)
        End If
    End If
    End With
        
    'Re-enable display of alerts and set statusbar to false within macro (passing control of status bar back to excel)
    Application.DisplayAlerts = True
    Application.StatusBar = False
    
    'Display message advising user that processing is complete
    MsgBox ("Processing Complete")
End Sub

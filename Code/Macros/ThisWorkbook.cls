VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ThisWorkbook"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = True
Option Explicit

'declare Function using win32 API GetOpenFileNameA in COMDLG32 DLL
Private Declare Function GetOpenFileName _
  Lib "COMDLG32.DLL" Alias "GetOpenFileNameA" _
  (pOpenfilename As OPENFILENAME) As Long
  
'declare new Type of OPENFILE required by API
Private Type OPENFILENAME
  lStructSize       As Long
  hwndOwner         As Long
  hInstance         As Long
  lpstrFilter       As String
  lpstrCustomFilter As String
  nMaxCustFilter    As Long
  nFilterIndex      As Long
  lpstrFile         As String
  nMaxFile          As Long
  lpstrFileTitle    As String
  nMaxFileTitle     As Long
  lpstrInitialDir   As String
  lpstrTitle        As String
  Flags             As Long
  nFileOffset       As Integer
  nFileExtension    As Integer
  lpstrDefExt       As String
  lCustData         As Long
  lpfnHook          As Long
  lpTemplateName    As String
End Type
Sub OpenZeFile(sTitle As String, sFilter As String, sPath As String, sOldFile As String, sNewFile As String)
Attribute OpenZeFile.VB_ProcData.VB_Invoke_Func = " \n14"

'*******************************************************************************************
'**  sub OpenZeFile
'**  Called from cmd_Reconcile_Click
'**
'**  Calls GetOpenFileName function to display file open dialog and get file selection from user.
'**  Opens selected file as worksheet in new workbook
'**
'** VERSION 01 - Initial Implementation                                       Graham Gold March 2011

'setup variables
Dim OpenFile As OPENFILENAME
Dim lReturn As Long
Dim sFile As String

'initialise OpenFile variables
OpenFile.lStructSize = Len(OpenFile)
OpenFile.nFilterIndex = 1
OpenFile.lpstrFile = String(257, 0)
OpenFile.nMaxFile = Len(OpenFile.lpstrFile) - 1
OpenFile.lpstrFileTitle = OpenFile.lpstrFile
OpenFile.nMaxFileTitle = OpenFile.nMaxFile
OpenFile.lpstrFilter = sFilter
OpenFile.lpstrInitialDir = sPath
OpenFile.lpstrTitle = sTitle
OpenFile.Flags = 0

'Call GetOpenFilename and return result into lReturn
lReturn = GetOpenFileName(OpenFile)

'Check if lReturn true or false, if true open file, if false, end macros.
If lReturn Then
    'Open selected file as a comma delimited file,
    sFile = sPath & "\" & Trim(OpenFile.lpstrFileTitle)
    Workbooks.OpenText Filename:=sFile, DataType:=xlDelimited, Comma:=True
        
    sOldFile = sFile
    sNewFile = Trim(OpenFile.lpstrFileTitle)
        
    Else: 'User pressed cancel
    End
End If

End Sub
Sub CompareWorksheets(ws1 As Worksheet, ws2 As Worksheet)
Attribute CompareWorksheets.VB_ProcData.VB_Invoke_Func = " \n14"

'*******************************************************************************************************
'**  sub CompareWorksheets
'**  Called from cmd_Reconcile_Click
'**
'**  Compares worksheets 2 and 3 of current workbook (opened using OpenZeFile)
'**  Creates new workbook and displays merged report of compared worksheets,
'**  highlighting cells that are different in red and showing baseline and new value in conflicted cells.
'**
'** VERSION 01 - Initial Implementation                                       Graham Gold March 2011

'setup variables
Dim r As Long, c As Integer
Dim lr1 As Long, lr2 As Long, lc1 As Integer, lc2 As Integer
Dim maxR As Long, maxC As Integer, cf1 As String, cf2 As String, sWB As String, sWS As String
Dim lRepBook As Workbook, DiffCount As Long
    
'turn of screenupdating until finished, to speed up processing
Application.ScreenUpdating = False

'display status message on statusbar
Application.StatusBar = "Creating the report..."

'setup names of report workbook and worksheet
sWB = "CMDB_Report_" & CMDB_Recon.MFType & "_" & CMDB_Recon.RepType & "_" & Format(Now, "ddmmyyhhmmss")
sWS = CMDB_Recon.MFType & "_" & CMDB_Recon.RepType

'add new workbook
Set lRepBook = Workbooks.Add

'disable alert displays, so saveas won't generate a popup about overwriting an existing file of same name
Application.DisplayAlerts = False

'Save workbook
lRepBook.SaveAs "\\lgnaspfil08\data_pgds_MAINFRAME\CMDB\Reconciliation\Reports\" & sWB & ".xls"

'enable alerts
Application.DisplayAlerts = True

'rename worksheet
lRepBook.ActiveSheet.Name = sWS

'disable display of alerts while removing extraneous worksheets, so there's only 1 (the report worksheet)
Application.DisplayAlerts = False

'remove extraneous worksheets
While lRepBook.Worksheets.Count > 1
    lRepBook.Worksheets(2).Delete
Wend

'enable alerts
Application.DisplayAlerts = True

'determine number of rows and columes in used range for first worksheet in comparison
With ws1.UsedRange
    lr1 = .Rows.Count
    lc1 = .Columns.Count
End With

'determine number of rows and columes in used range for 2nd worksheet in comparison
With ws2.UsedRange
    lr2 = .Rows.Count
    lc2 = .Columns.Count
End With

'set max rows/columns
maxR = lr1
maxC = lc1
If maxR < lr2 Then maxR = lr2
If maxC < lc2 Then maxC = lc2

'initialise differences counter
DiffCount = 0

'loop through each column in worksheets, comparing each cell in them
For c = 1 To maxC
    'display percentage through the cells on start of each column loop
    Application.StatusBar = "Comparing cells " & Format(c / maxC, "0 %") & "..."
    For r = 1 To maxR
        'initialise comparison strings
        cf1 = ""
        cf2 = ""
        On Error Resume Next
        'set comparison strings to value in current cell in each worksheet
        cf1 = ws1.Cells(r, c).FormulaLocal
        cf2 = ws2.Cells(r, c).FormulaLocal
        On Error GoTo 0
        
        'compare cells
        If cf1 <> cf2 Then
            'if different, increase differences counter, colour cell red and display both baseline and current value in this cell in the report
            DiffCount = DiffCount + 1
            Cells(r, c).Formula = "'Baseline Value: " & vbLf & cf1 & vbLf & vbLf & "Current Value: " & vbLf & cf2
            Cells(r, c).Interior.ColorIndex = 3
        Else
        'if no differences, use value from 2nd worksheet (current CMDB value)
        Cells(r, c).Formula = cf2
        End If
    Next r
Next c

'update statusbar now that we've done the comparison and moving on to formatting
Application.StatusBar = "Formatting the report..."

'Select all cells in report sheet
Cells.Select

'Set alignment, text wrapping
With Selection
    .HorizontalAlignment = xlGeneral
    .VerticalAlignment = xlTop
    .WrapText = True
    .Orientation = 0
    .AddIndent = False
    .IndentLevel = 0
    .ShrinkToFit = False
    .ReadingOrder = xlContext
    .MergeCells = False
End With

'select only used cells in report sheet
lRepBook.ActiveSheet.UsedRange.Select

'set cell borders on selected cells
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
With Selection.Borders(xlInsideHorizontal)
    .LineStyle = xlContinuous
    .Weight = xlThin
    .ColorIndex = xlAutomatic
End With

'set font properties for selected cells
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

'change the zoom
ActiveWindow.Zoom = 85

'select first row and make text bold
Rows("1:1").Select
Selection.Font.Bold = True

'select all cells, autofit(set column width based on contents),
Cells.Select
Cells.EntireColumn.AutoFit

'split.freeze on 2nd row, ensure header row fixed when scrolling
Range("A2").Select
With ActiveWindow
    .SplitColumn = 0
    .SplitRow = 1
    .FreezePanes = True
End With

'save report workbook
lRepBook.Save

'destroy the lRepBook object (good memory management)
Set lRepBook = Nothing

'clear statusbar and re-enable screen updates to display completed report workbook
Application.StatusBar = False
Application.ScreenUpdating = True

'Popup message box giving information on number of differences found
MsgBox DiffCount & " differences found against baseline!", vbInformation, _
    "Compare " & ws1.Name & " with " & ws2.Name
End Sub

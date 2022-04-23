VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "CMDB_Recon"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = True
'setup public variables
Public RepType As String, MFType As String
Sub cmdReconcile_Click()
Attribute cmdReconcile_Click.VB_ProcData.VB_Invoke_Func = " \n14"

'*******************************************************************************************
'**  cmdReconcile_Click
'**  Invoked when Reconcile button pressed in Excel Worksheet
'**
'**  Checks required options selected on form, opens dialogs to select baseline and input csv files
'** (default path is ##REDACTED##.
'**
'** Compares worksheets and creates difference report then moves input files to \Processed directory
'**
'** VERSION 01 - Initial Implementation                                       Graham Gold March 2011

'setup variables for this sub
Dim sFTitle As String, sFFilter As String, sFPath As String, sOldFile As String, sNewFile As String, sTmp As String
Dim iPos As Long

'set report type based on selection in first group of option buttons
If optHW Then RepType = "hardware"
    
If optLPAR Then RepType = "lpar"

If optStorage Then RepType = "storage"

If optCluster Then RepType = "cluster"

If optOS Then RepType = "zos"

If optReln Then RepType = "relationships"

'check for OS report selected for Unisys - not valid
If optOS And optUnisys Then
    MsgBox ("##REDACTED##")
    Exit Sub
    End If
    
'check if no option selected in first group, display error message and exit
If Not (optHW Or optLPAR Or optStorage Or optCluster Or optOS Or optReln) Then
    MsgBox ("You must select a report type!")
    Exit Sub
    End If

'set mainframe type based on selection in 2nd group of option buttons
If optIBM Then MFType = "ibm"
    
If optUnisys Then MFType = "unisys"
    
'check if no option selected in 2nd group, display error message and exit
If Not (optIBM Or optUnisys) Then
    MsgBox ("You must select a mainframe type!")
    Exit Sub
End If

'display information to user in statusbar
Application.StatusBar = "Running " & MFType & " " & RepType & " report"
  
'set path, filter and window title for file open dialog for baseline files
sFPath = "##REDACTED##"
sFFilter = CMDB_Recon.MFType & " files (*.csv)" & Chr(0) & "*" & CMDB_Recon.MFType & "*.csv" & Chr(0)
sFTitle = "Open " & CMDB_Recon.MFType & " " & CMDB_Recon.RepType & " baseline file"

'call OpenZeFile subroutine in ThisWorkbook to display file open dialog
'and get name of selected file then open it.
ThisWorkbook.OpenZeFile sFTitle, sFFilter, sFPath, sOldFile, sTmp

'Move worksheet from new workbook back to CMDB_Reconciler.xls workbook after main report sheet
'Worksheets.Move after:=Workbooks("CMDB_Reconciler.xls").Sheets(Workbooks("CMDB_Reconciler.xls").Worksheets.Count)
Application.DisplayAlerts = False
Application.ScreenUpdating = False
ActiveSheet.UsedRange.Copy
Workbooks("CMDB_Reconciler.xls").Sheets.Add(After:=Workbooks("CMDB_Reconciler.xls").Sheets(1)).Paste
Workbooks("CMDB_Reconciler.xls").Sheets(2).Name = "baseline_" & CMDB_Recon.MFType & "_" & CMDB_Recon.RepType
Workbooks(sTmp).Close SaveChanges:=False
Application.ScreenUpdating = True
Application.DisplayAlerts = True
   
'set path, filter and window title for file open dialog for input files
sFPath = "##REDACTED##"
sFFilter = CMDB_Recon.MFType & " files (*.csv)" & Chr(0) & "*" & CMDB_Recon.MFType & "*.csv" & Chr(0)
sFTitle = "Open " & CMDB_Recon.MFType & " " & CMDB_Recon.RepType & " input file"

'call OpenZeFile subroutine in ThisWorkbook to display file open dialog
'and get name of selected file then open it.
ThisWorkbook.OpenZeFile sFTitle, sFFilter, sFPath, sOldFile, sTmp
   
'Move worksheet from new workbook back to CMDB_Reconciler.xls workbook after main report sheet
'Worksheets.Move After:=Workbooks("CMDB_Reconciler.xls").Sheets(Workbooks("CMDB_Reconciler.xls").Worksheets.Count)
Application.DisplayAlerts = False
Application.ScreenUpdating = False
ActiveSheet.UsedRange.Copy
Workbooks("CMDB_Reconciler.xls").Sheets.Add(After:=Workbooks("CMDB_Reconciler.xls").Sheets(2)).Paste
Workbooks("CMDB_Reconciler.xls").Sheets(3).Name = CMDB_Recon.MFType & "_" & CMDB_Recon.RepType
Workbooks(sTmp).Close SaveChanges:=False
Application.ScreenUpdating = True
Application.DisplayAlerts = True
    
' compare two different worksheets in the active workbook using CompareWorksheets subroutine
ThisWorkbook.CompareWorksheets Worksheets(2), Worksheets(3)

'Disable displaying of alerts while deleting imported worksheets, to delete without asking for confirmation
Application.DisplayAlerts = False

'delete worksheets other than first worksheet
While Workbooks("CMDB_Reconciler.XLS").Worksheets.Count > 1
    Workbooks("CMDB_Reconciler.XLS").Worksheets(2).Delete
Wend

'Find position of period in filename for input file
iPos = InStr(sTmp, ".")

'Keep all chars in input file string up to but not including the period
sTmp = Left$(sTmp, iPos - 1)

'setup new filename with timestamp
sNewFile = "##REDACTED##" & sTmp & "_" & Format(Now, "ddmmyyhhmmss") & ".csv" ' new file location

'Copy input file to \Processed directory using new name.
Name sOldFile As sNewFile ' move the file

'Enable displaying of alerts
Application.DisplayAlerts = True

End Sub
Private Sub cmdResetForm_Click()

'*******************************************************************************************
'**  cmdResetForm_Click
'**  Invoked when Reset Form button pressed in Excel Worksheet
'**
'**  Resets all option button values to false.
'**
'** VERSION 01 - Initial Implementation                                       Graham Gold March 2011

optHW = False
    
optLPAR = False

optStorage = False

optCluster = False

optOS = False

optReln = False

optIBM = False
    
optUnisys = False
End Sub

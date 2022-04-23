$file = (gci $("\\" + $ENV:HomeDataServer + "\" + $env:USERNAME + "\*.html")|sort LastWriteTime -Descending)[0].FullName# | Select -First 1).Fullname
$excel = New-Object -ComObject excel.application

Write-Host "Opening HTML Report"
$workbook = $excel.workbooks.open($file)
#$worksheet = $workbook.Worksheets.item(1)

Write-Host "Adding Columns"
$excel.ActiveSheet.Range('G1:G1').Cells.Value2 = "Action"
$excel.ActiveSheet.Range('H1:H1').Cells.Value2 = "Comments"
$excel.ActiveSheet.UsedRange.ClearFormats()
$excel.ActiveSheet.UsedRange.Select()

Write-Host "Adding Table Formatting"
$excel.ActiveSheet.ListObjects.Add(1,$excel.ActiveSheet.UsedRange,0,1).TableStyle = "TableStyleMedium19"
$workbook.ActiveSheet.Columns.Item('E').WrapText = $true
$workbook.ActiveSheet.Columns.Item('F').WrapText = $true
$workbook.ActiveSheet.Columns.Item('H').WrapText = $true
$excel.ActiveSheet.UsedRange.VerticalAlignment = 1
$workbook.ActiveSheet.Columns.AutoFit()
$workbook.ActiveSheet.Columns.Item('E').ColumnWidth = 60
$workbook.ActiveSheet.Columns.Item('G').ColumnWidth = 25
$workbook.ActiveSheet.Columns.Item('H').ColumnWidth = 60

Write-Host "Pre-Filling answers for Low/Medium-Low criticality PLEs"
$excel.Selection.Columns.Item('G').Cells| foreach {If ($_.Value2 -ne "Action") {$_.Value2 = '=IF(ISERROR(FIND("Low",[@Criticality])),"","No Action")'}}
$workbook.ActiveSheet.Columns.Item('G').Select()|out-null

Write-Host "Adding conditional formatting for 'No Action' entries"
[void]$excel.Selection.FormatConditions.Add([Microsoft.Office.Interop.Excel.XlFormatConditionType]::xlCellValue,[Microsoft.Office.Interop.Excel.XlFormatConditionOperator]::xlEqual,"=""No Action""")
$excel.Selection.FormatConditions.Item(1).Font.Color = -16752384
$excel.Selection.FormatConditions.Item(1).Font.TintAndShade = 0
$excel.Selection.FormatConditions.Item(1).Interior.PatternColorIndex = [Microsoft.Office.Interop.Excel.XlPattern]::xlPatternAutomatic
$excel.Selection.FormatConditions.Item(1).Interior.Color = 13561798
$excel.Selection.FormatConditions.Item(1).Interior.TintAndShade = 0
$excel.Selection.FormatConditions.Item(1).StopIfTrue = $false

Write-Host ("Saving "+ $file.SubString(0,$file.Length-5) + ".xlsx")
$Missing = [System.Reflection.Missing]::Value
$excel.DisplayAlerts = $false
$workbook._SaveAs($file.Substring(0,$file.Length -5),[Microsoft.Office.Interop.Excel.XlFileFormat]::xlOpenXMLWorkbook,$Missing,$Missing,$false,$false,[Microsoft.Office.Interop.Excel.XlSaveAsAccessMode]::xlNoChange,[Microsoft.Office.Interop.Excel.XlSaveConflictResolution]::xlLocalSessionChanges,$true,$Missing,$Missing)
$excel.Quit()
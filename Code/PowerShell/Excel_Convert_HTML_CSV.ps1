$Format = [Microsoft.Office.Interop.Excel.XlFileFormat]::xlCSV
$Conflict = [Microsoft.Office.Interop.Excel.XlSaveConflictResolution]::xlLocalSessionChanges
$SaveMode = [Microsoft.Office.Interop.Excel.XlSaveAction]::xlDoNotSaveChanges
$Excel = New-Object -ComObject Excel.Application
$Excel.Visible = $True
$File = "K:\Weekly PLE Report for the week ending 01_04_2015.html"
$Newfile = ($File.Split(".")[0])+".csv"
$Workbook = $Excel.Workbooks.Open($File)
$Excel.Application.Application.ActiveWorkbook._SaveAs($Newfile,$Format,$null,$null,$null,$null,$null,$Conflict)

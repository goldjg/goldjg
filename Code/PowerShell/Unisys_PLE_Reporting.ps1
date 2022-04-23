<#
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
| Unisys_PLE_Reporting.ps1                                                              |
| Version: 1.0                                                                          |
| Author: Graham Gold                                                                   |
| Description: Process Unisys PLE Weekly Report emails in inbox                         |
|              and for each one, create excel report - pre-populated based on critiality|
|              and if product/feature is in use or not.                                 |
| Run Location: \\##REDACTED##\Patch policy\bin             |
|_______________________________________________________________________________________|
| Version History                                                                       |
| ===============                                                                       |
| Version 1.0 - Initial Implementation                                                  |
|                                                                                       |
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

PATHS
=====
Script Path                          \\##REDACTED##\Patch policy\bin
Primary Output Path                  \\sharepoint\Monthly Patch Reviews\Reviews
Backout Output Path                  \\##REDACTED##\Patch policy\Reports
#>

Function Process-HTML
{
param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$filein
)
#create excel COM object
Write-Host "Creating excel report"
$excel = New-Object -ComObject excel.application

#Disable formula autofill in tables
$excel.AutoCorrect.AutoFillFormulasInLists = $false

#Open html report (filename passed as parameter) as new excel workbook
Write-Host "Opening HTML Report"
$workbook = $excel.workbooks.open($filein)

#Add "PGDS Action" and "Comments" columns to right of workbook after last existing column
Write-Host "Adding Columns"
$excel.ActiveSheet.Range('I1:I1').Cells.Value2 = "Action"
$excel.ActiveSheet.Range('J1:J1').Cells.Value2 = "Comments"
$excel.ActiveSheet.UsedRange.ClearFormats()|out-null
$excel.ActiveSheet.UsedRange.Select()|out-null

#Format all columns as table, and format their width
Write-Host "Adding Table Formatting"
$excel.ActiveSheet.ListObjects.Add(1,$excel.ActiveSheet.UsedRange,0,1).TableStyle = "TableStyleMedium19"
$workbook.ActiveSheet.Columns.Item('E').WrapText = $true
$workbook.ActiveSheet.Columns.Item('F').WrapText = $true
$workbook.ActiveSheet.Columns.Item('H').WrapText = $true
$excel.ActiveSheet.UsedRange.VerticalAlignment = 1
$workbook.ActiveSheet.Columns.AutoFit()|out-null
$workbook.ActiveSheet.Columns.Item('E').ColumnWidth = 60
$workbook.ActiveSheet.Columns.Item('I').ColumnWidth = 25
$workbook.ActiveSheet.Columns.Item('J').ColumnWidth = 60

#Check each row, for each, if we don't use the product, mark as no action
Write-Host "Pre-Filling answers for unused products"
$Missing = [System.Reflection.Missing]::Value

#Load in products CSV as new worksheet, and rename as "Products" sheet
$products = Import-Csv -Path ($ScriptPath + "\products.csv")
$newsheet = $excel.worksheets.Add($Missing,$excel.worksheets.item($excel.worksheets.count))
$newsheet.name = "Products"
$newsheet.activate()|out-null

$products|convertto-csv -delimiter "`t" -notype | clip
$newsheet.cells.item(1,1).Select()|out-null
$newsheet.Paste()|out-null

#Check in each cell, using VLOOKUP excel formula, if product used, if not, populate Action as "No Action" and Comments as "Product Not Used"
$workbook.worksheets.item(1).Activate()|out-null
$excel.ActiveSheet.UsedRange.Select()|out-null
$excel.Selection.Columns.Item('I').Cells| foreach {If ($_.Value2 -ne "Action") {$_.Value2 = '=IF((VLOOKUP([@Product],Products!A:B,2,FALSE) = "N"),"No Action","")'}}
$excel.Selection.Columns.Item('J').Cells| foreach {If ($_.Value2 -ne "Comments") {$_.Value2 = '=IF((VLOOKUP([@Product],Products!A:B,2,FALSE) = "N"),"Product Not Used","")'}}
$workbook.ActiveSheet.Columns.Item('I').Select()|out-null

#Check each row, using excel IF, ISERROR and FIND formulae,  if "Low" is in the Criticality field - if so, mark Action as "No Action" and Comments as "Low Impact"
Write-Host "Pre-Filling answers for Low/Medium-Low criticality PLEs"
$excel.ActiveSheet.UsedRange.Select()|out-null
$excel.Selection.Columns.Item('I').Cells| foreach {If ($_.Value2 -eq "") {$_.Value2 = '=IF(ISERROR(FIND("Low",[@Criticality])),"","No Action")'}}
$excel.Selection.Columns.Item('J').Cells| foreach {If ($_.Value2 -eq "") {$_.Value2 = '=IF(ISERROR(FIND("Low",[@Criticality])),"","Low Impact")'}}
$workbook.ActiveSheet.Columns.Item('I').Select()|out-null

#Check each row for keywords in the PLE description that mean this PLE can be skipped
Write-Host "Pre-Filling answers for descriptions matching keywords"
$Missing = [System.Reflection.Missing]::Value

#Load keywords CSV as new worksheet named "Keywords
$Keywords  = Import-Csv -Path ($ScriptPath + "\keywords.csv")
$newsheet = $excel.worksheets.Add($Missing,$excel.worksheets.item($excel.worksheets.count))
$newsheet.name = "Keywords"
$newsheet.activate()|out-null

$Keywords|convertto-csv -delimiter "`t" -notype | clip
$newsheet.cells.item(1,1).Select()|out-null
$newsheet.Paste()|out-null

#check each row, using excel array formulas to check if any of the keywords on keyword sheet are in the description
#If so, mark PGDS Action as "No Action" and populate Comments with the Reason matching the keyword match
#Needs AutoCorrect.AutoFillFormulasInLists = $false 
$workbook.worksheets.item(1).Activate()|out-null
$excel.ActiveSheet.UsedRange.Select()|out-null
$excel.Selection.Columns.Item('I').Cells| foreach {If ($_.Value2 -eq "") {$_.FormulaArray = '=IFERROR(INDEX(Keywords!C:C,MATCH(TRUE,ISNUMBER(SEARCH(Keywords!A:A,[@Description])),0))&"","Not Found")'}}
$excel.Selection.Columns.Item('J').Cells| foreach {If ($_.Value2 -eq "") {$_.FormulaArray = '=IFERROR(INDEX(Keywords!B:B,MATCH(TRUE,ISNUMBER(SEARCH(Keywords!A:A,[@Description])),0))&"","Not Found")'}}

#Add excel conditional formatting for any cell in Column I that contain "No Action"
Write-Host "Adding conditional formatting for 'No Action' entries"
$workbook.ActiveSheet.Columns.Item('I').Select()|out-null
[void]$excel.Selection.FormatConditions.Add([Microsoft.Office.Interop.Excel.XlFormatConditionType]::xlCellValue,[Microsoft.Office.Interop.Excel.XlFormatConditionOperator]::xlEqual,"=""No Action""")
$excel.Selection.FormatConditions.Item(1).Font.Color = -16752384
$excel.Selection.FormatConditions.Item(1).Font.TintAndShade = 0
$excel.Selection.FormatConditions.Item(1).Interior.PatternColorIndex = [Microsoft.Office.Interop.Excel.XlPattern]::xlPatternAutomatic
$excel.Selection.FormatConditions.Item(1).Interior.Color = 13561798
$excel.Selection.FormatConditions.Item(1).Interior.TintAndShade = 0
$excel.Selection.FormatConditions.Item(1).StopIfTrue = $false

#Set output filename using original name, changing extension to .xlsx
$fileout = $filein.SubString(0,$filein.Length-5) + ".xlsx"

#Check file doesn't already exist - if it does, append "(new)" to end of file title
If (Test-Path $fileout -PathType Leaf) {
    $fileout = $fileout -replace '.xlsx','(new).xlsx'
    Write-Host "File already exists - saving instead as:`r`n$fileout"
    }

#Save excel report and remove input html report
Write-Host ("Saving "+ $fileout)
$excel.DisplayAlerts = $false
$workbook._SaveAs($fileout,[Microsoft.Office.Interop.Excel.XlFileFormat]::xlOpenXMLWorkbook,$Missing,$Missing,$false,$false,[Microsoft.Office.Interop.Excel.XlSaveAsAccessMode]::xlNoChange,[Microsoft.Office.Interop.Excel.XlSaveConflictResolution]::xlLocalSessionChanges,$true,$Missing,$Missing)
$excel.Quit()
remove-item $filein
}

#Initialise path variables
$LANPath = "\\##REDACTED##\Patch policy"
$SharepointPath = "\\sharepoint\Monthly Patch Reviews\Reviews"
$ScriptPath = $LANPath + "\bin"

#Open sharepoint folder in Windows Explorer, if available
explorer $SharepointPath

sleep -s 5

#bring script back into focus
Add-Type @"
  using System;
  using System.Runtime.InteropServices;
  public class Tricks {
     [DllImport("user32.dll")]
     [return: MarshalAs(UnmanagedType.Bool)]
     public static extern bool SetForegroundWindow(IntPtr hWnd);
  }
"@

$parent = Get-Process -id ((gwmi win32_process -Filter "processid='$pid'").parentprocessid)
If ($parent.Name -eq "cmd") {# Being run by via cmd prompt (batch file)
    $h = (Get-Process cmd).MainWindowHandle
    [void] [Tricks]::SetForegroundWindow($h)
    }
    else{# being run in powershell ISE or console
          $h = (Get-Process -id $pid).MainWindowHandle
          [void] [Tricks]::SetForegroundWindow($h)
    }  

#Check sharepoint path reachable - if not, use lan path
If (Test-Path $SharepointPath) {$BasePath = $SharepointPath;write-host "Using sharepoint to save reports"} else {$BasePath = "$LANPath\Reports";write-host "Using LAN to save reports - sharepoint not accessible"}

#Initialise variables for outlook advanced search
$Folder = "Inbox"
$Test = "Subject"
$Compare ="Weekly PLE Report"
$Schema = ("urn:schemas:httpmail:subject LIKE '" + $Compare + "%'")

#Create outlook COM object
Write-Host "Accessing Outlook inbox"
Add-Type -Assembly "Microsoft.Office.Interop.Outlook"
$Outlook = New-Object -ComObject Outlook.Application

#Run Advanced search
Write-Host "Searching for PLE emails"
$SrchRslt = $Outlook.AdvancedSearch($Folder,$Schema,$False,"SubjectSearch").Results

#Wait to ensure we got all results
sleep -s 5

#Filter results to ensure only emails from unisys are processed, not replies
$Bodies = $SrchRslt|where-object {$_.SenderName -eq "Product.Support@unisys.com"}

$bodycount = $Bodies.SenderName.count
Write-Host ("PLE Emails found: " + $bodycount)
$loopcount = 1

#for each email, select subject, body and html body properties
if ($bodycount -ge 1) {$bodies|Select Subject,Body,HTMLBody|foreach {
    If ($bodycount -gt 1) {Write-host ("Handling email " + $loopcount + " of " + $bodycount); $loopcount++}
    
    #Create output filename using base path and email subject, as html
    $OutPath=$BasePath + "\" + $($_.Subject -replace "/","_") + ".html"
    Write-Host ("Begin Processing " + (Split-Path -Leaf $OutPath).Split(".")[0]) -ForegroundColor Yellow
    Write-Host "Exporting HTML email body"
    
    #Write html from email to html output file
    $_|select -expandproperty HTMLBody | Out-File $($BasePath + "\Eml_body.html")
    
    Write-Host "Reformating HTML"
    #create new html comobject to read and process html file
    $html = New-Object -ComObject "HTMLFile";
    $source = Get-Content -Path ($BasePath + "\Eml_body.html") -Raw;
    $html.IHTMLDocument2_write($source);
    
    #Grab the last table in the html and reformat, getting rid of row and column SPAN tags,
    # add new table headers, handle columns that are not always present (security related)
    # then write out as html report named per email subject
    $table=$html.getElementsByTagName("Table")| where {$_.className -eq "standard"} | select -last 1
    (((((((((((((("<TABLE>" + $table.innerHTML + "</TABLE>") `
    -replace " colSpan=3","") `
    -replace " rowSpan=2","") `
    -replace " rowSpan=3","") `
    -replace " rowSpan=4","") `
    -replace "<TH>Criticality</TH>","<TH>Criticality</TH><TH>Description</TH><TH>Affected Levels</TH><TH>Security Type</TH><TH>Security Impact</TH>") `
    -replace "<TR>","") `
    -replace "</TR>","") `
    -replace "<A ","<TR><A ") `
    -replace "</A>","</A></TD>") `
    -replace "<TD><TR>","<TR><TD>") `
    -replace "</SPAN> Security Impact:","</SPAN></TD><TD>") `
    -replace "<TD>Security Type: <SPAN","<TD><SPAN") `
    -replace "</TD></TD>","</TD>") | out-file $OutPath
    
    #Pass html file to Process-HTML file function to create and process as an excel report 
    Process-HTML $OutPath
    Write-Host ("End Processing " + (Split-Path -Leaf $OutPath).Split(".")[0] + "`r`n") -ForegroundColor Green
    
    #Remove tmp html file
    Remove-Item $($BasePath + "\Eml_body.html")
    }
} else {
Write-Host "No PLE emails found in inbox - Nothing to process - exiting..."
}
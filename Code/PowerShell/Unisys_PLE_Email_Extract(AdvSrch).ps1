 [String]$Folder = "Inbox"
 [String]$Test = "Subject"
 [String]$Compare ="Weekly PLE Report"
 [String]$Schema = ("urn:schemas:httpmail:subject LIKE '" + $Compare + "%'")
Add-Type -Assembly "Microsoft.Office.Interop.Outlook"
$Outlook = New-Object -ComObject Outlook.Application
$Bodies = $Outlook.AdvancedSearch($Folder,$Schema,$False,"SubjectSearch").Results
sleep -s 5
$bodies|Select Subject,Body,HTMLBody |Where-Object {$_.Subject -like $($Compare + "*")}|foreach {
    $_|select -expandproperty HTMLBody | Out-File $("\\" + $ENV:CitrixDataServer + "\" + $env:USERNAME + "\Eml_Body.html")
    $OutPath="\\" + $ENV:CitrixDataServer + "\" + $env:USERNAME + "\" + $($_.Subject -replace "/","_") + ".html"
    $html = New-Object -ComObject "HTMLFile";
    $source = Get-Content -Path "K:\Eml_body.html" -Raw;
    $html.IHTMLDocument2_write($source);
    $table=$html.getElementsByTagName("Table")| where {$_.className -eq "standard"} | select -last 1
    (((((((((("<TABLE>" + $table.innerHTML + "</TABLE>") `
    -replace " colSpan=3","") `
    -replace " rowSpan=3","") `
    -replace " rowSpan=4","") `
    -replace "<TH>Criticality</TH>","<TH>Criticality</TH><TH>Description</TH><TH>Affected Levels</TH>") `
    -replace "<TR>","") `
    -replace "</TR>","") `
    -replace "<A ","<TR><A ") `
    -replace "</A>","</A></TD>") `
    -replace "<TD><TR>","<TR><TD>") | out-file $OutPath
    Remove-Item $("\\" + $ENV:HomeDataServer + "\" + $env:USERNAME + "\EML_Body.html")
    }
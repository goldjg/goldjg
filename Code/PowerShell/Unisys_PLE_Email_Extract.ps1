 [String]$Folder = "Inbox"
 [String]$Test = "Subject"
 [String]$Compare ="Weekly PLE Report"
$mesrv = (Get-WmiObject Win32_ComputerSystem).Name;
$medom = (gwmi -class win32_computerSystem).Username.split("\")[0];
$meusr = (gwmi -class win32_computerSystem).Username.split("\")[1];
$acct = (([wmi]("win32_UserAccount.Domain='" + $medom + "',Name='" + $meusr + "'")).fullname.split(" ")[1] + "." + ([wmi]("win32_UserAccount.Domain='" + $medom + "',Name='" + $meusr + "'")).fullname.split(" ")[0])
Add-Type -Assembly "Microsoft.Office.Interop.Outlook"
$Outlook = New-Object -ComObject Outlook.Application
$Namespace = $Outlook.GetNameSpace("MAPI")
$Email = ($Namespace.Folders|Where-Object {$_.Name -like $("$acct*")}).Folders.Item($Folder).Items
# Clear-Host
Write-Host "Trawling through Outlook, please wait ...."
$Bodies = $Email | select-object -property Subject,HTMLBody|Where-Object {$_.$Test -Match $Compare};
foreach ($Body in $Bodies){
    $Body|select -expandproperty HTMLBody | Out-File K:\Eml_Body.html
    $html = New-Object -ComObject "HTMLFile";
    $source = Get-Content -Path "K:\Eml_body.html" -Raw;
    $html.IHTMLDocument2_write($source);
    $table=$html.getElementsByTagName("Table")| where {$_.className -eq "standard"} | select -last 1
    ((((((((("<TABLE>" + $table.innerHTML + "</TABLE>") `
    -replace " colSpan=3","") `
    -replace " rowSpan=3","") `
    -replace "<TH>Criticality</TH>","<TH>Criticality</TH><TH>Description</TH><TH>Affected Levels</TH>") `
    -replace "<TR>","") `
    -replace "</TR>","") `
    -replace "<A ","<TR><A ") `
    -replace "</A>","</A></TD>") `
    -replace "<TD><TR>","<TR><TD>") |out-file $("K:\" + $($Body.Subject -replace "/","_") + ".html")
    }
    Remove-Item K:\EML_Body.html
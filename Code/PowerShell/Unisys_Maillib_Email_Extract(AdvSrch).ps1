$basepath="##REDACTED##"
$outpath=$basepath
#Initialise variables for outlook advanced search
$Folder = "'\\user@domain\Folders\Maillib Logs'"
$Compare ="Host Daily Mail Log"
$Schema = ("urn:schemas:httpmail:subject LIKE '" + $Compare + "%'")

#Create outlook COM object
Write-Host "Accessing Outlook inbox"
Add-Type -Assembly "Microsoft.Office.Interop.Outlook"
$Outlook = New-Object -ComObject Outlook.Application

#Run Advanced search
Write-Host "Searching for emails"
$Bodies = $Outlook.AdvancedSearch($Folder,$Schema,$False,"SubjectSearch").Results

#Wait to ensure we got all results
sleep -s 15

$bodycount = $Bodies.SenderName.count
Write-Host ("Emails found: " + $bodycount)
$loopcount = 1

#for each email, select subject, body and html body properties
if ($bodycount -ge 1) {$bodies|Select Subject,Body,HTMLBody|foreach {
    If ($bodycount -gt 1) {Write-host ("Handling email " + $loopcount + " of " + $bodycount); $loopcount++}
    
    #Create output filename using base path and email subject, as html
    $OutPath=$BasePath + "\" + $($_.Subject -replace "/","_") + ".html"
    Write-Host ("Begin Processing " + (Split-Path -Leaf $OutPath).Split(".")[0]) -ForegroundColor Yellow
    Write-Host "Exporting HTML email body"
    
    #Write html from email to html output file
    $_|select -expandproperty HTMLBody | Out-File $($BasePath + $_.Subject + "\Eml_body.html") 
        }
        $loopcount++
    }
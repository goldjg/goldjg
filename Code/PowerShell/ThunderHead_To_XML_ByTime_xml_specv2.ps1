<#
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
| ThunderHead_To_XML_Convert.ps1                                                        |
| Version: 0.1                                                                          |
| Author: Graham Gold                                                                   |
| Description: Convert ThunderHead batch history logs to RRD XML Manifest format        |
|_______________________________________________________________________________________|
| Version History                                                                       |
| ===============                                                                       |
| Version 0.1 - Initial Implementation/Proof of Concept                                 |
|                                                                                       |
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#>

function New-Xml-ThunderHead
{
<# 
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
| New-Xml-ThunderHead function                                                          |
| Input: Array of string objects in format <datestamp><space><filename>                 |
| Output: RRD XML Manifest (as string) to be output to file                             |
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#>
Begin {
#Create static start of file (same for every run)
$file_number=1
$total_files_today=3
$cutoff_time="13:00"
$now=get-date -f 'dd-MM-yyyy'
$xml = "<?xml version=$('"')1.0$('"') ?>"
$xml = $xml+"`n<manifest total_files_today=$('"')$total_files_today$('"') "
$xml = $xml+            "file_number=$('"')$file_number$('"') "
$xml = $xml+            "date_generated=$('"')$now$('"') "
$xml = $xml+            "cutoff_time=$('"')$cutoff_time$('"')> "
$xml = $xml+"`n<customer>"
$xml = $xml+"`n<customerName>CUSTOMER01</customerName>`n"
}


Process {
#This code repeated for every string object passed in, to create XML structure for each file per the schema
    $line = $_ -split ' ' #split the line into two objects
    $xml += "<fileGroup>`n" #Open the fileGroup tag
        $xml += "<groupJobNumber>$($line[1])</groupJobNumber>`n" #create groupJobNumber tag with filename from object
        $xml += "<groupDocumentCount>1</groupDocumentCount>`n" #create groupDocumentCount - static value - 1 doc per group
        $xml += "<fileDetail>`n" #open the fileDetail tag
            $xml += "<fileJobNumber>$($line[1])</fileJobNumber>`n" #create fileJobNumber tag with filename from object
            $xml += "<customerFilename>$($line[1])</customerFilename>`n" #create customerFilename tag with filename from object
            $xml += "<rrdFilename>$($line[1])</rrdFilename>`n" #create rrdFilename tag with filename from object
            $xml += "<fileDocumentCount>1</fileDocumentCount>`n" #create fileDocumentCount tag static value - 1 doc per file
            $xml += "<transferDateTime>$($line[0])</transferDateTime>`n" #create transferDateTime tag with datestamp from object
            $xml += "<size>0</size>`n" #create size tag - static size of 0 as we don't have size information in history log
        $xml += "</fileDetail>`n" #close fileDetail tag
    $xml += "</fileGroup>`n" #fileGroup tag
}

End {
#create static end of file (Same for every run)
$xml += "</customer>`n</manifest>`n"

#echo the xml string as output
$xml
}
} 

Function DisplayIt
{
<# 
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
| DisplayIt function                                                                    |
| Input: String message                                                                 |
| Output: Timestamped message written to console                                        |
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#>
param (
        [Parameter(Mandatory=$true)]
        [string]$msg
)
Write-Host "[$(Get-Date -f 'yyyyMMddHHmmss')]: $($msg)"
}

Function In-Time-Range
{
<# 
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
| InWindow function                                                                     |
| Input: Start and end timestamp plus timestamp to be checked is in window              |
| Output: Returns true or false                                                         |
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#>
param (
        [Parameter(Mandatory=$true)]
        [Int64]$entry_date,
        
        [Parameter(Mandatory=$true)]
        [Int64]$winStart,

        [Parameter(Mandatory=$true)]
        [Int64]$winEnd        
)
If ($entry_date -ge $winStart -and $entry_date -le $winEnd){
    return $true
    }
    else
    {
    return $false
    }
}

$logstart = 20150317110000
$logend   = 20150318105959


#Read in the history log
$x = Get-Content K:\History.log|select -skip 1
DisplayIt "Log Read OK"

#merge datestamp and filename for each file to single line, separated by pipe character
$x = (($x -join "|") -split "\|\|")
DisplayIt "Date/Filename merged to same line for each file in log"

#convert the date formats and ensure new format of each line is `yyyyMMddHHmmss <filename>`
$converted = $x |foreach {
  $i = ($_ -split '\|') #split the line on the pipe character so you get a 2 object array
  
  #convert date format of object 1 if in required time range
  $i[0] = Get-Date ($i[0] -replace '^\w+ (\w+ \d+) (\d+:\d+:\d+) (\d+)$', '$1 $3 $2') -f 'yyyyMMddHHmmss' 
  
  If (In-Time-Range -entry_date $([Int64]$i[0]) -winStart $logstart -winEnd $logend){
      
        #return converted timestamp and filename, separated by a space
        $i[0] + ' ' + $i[1]
        }      
}

DisplayIt "Date/Time format converted - starting XML conversion"

#
#Pass to XML function to create XML and pipe to output file
#
$outfl = "K:\MANLTCPYTHBB01$(get-date -f 'ddMMyyyyHHmmss').XML"
$converted|New-Xml-ThunderHead|out-file $outfl

DisplayIt "$($converted.length) files found in history log and converted to XML in file $($outfl)"
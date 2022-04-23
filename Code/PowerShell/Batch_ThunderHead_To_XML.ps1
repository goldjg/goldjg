<#
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
| Batch_ThunderHead_To_XML.ps1                                                          |
| Version: 0.2                                                                          |
| Author: Graham Gold                                                                   |
| Description: Convert ThunderHead batch history logs to RRD XML Manifest format        |
|_______________________________________________________________________________________|
| Version History                                                                       |
| ===============                                                                       |
| Version 0.1 - Initial Implementation/Proof of Concept                                 |
| Version 0.2 - Parameterise and support multiple input files to single output xml      |
|                                                                                       |
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#>

param ( 
        [Parameter(Mandatory=$false,
        HelpMessage="Please supply path to input directory containing logs to be parsed")]
        [Alias("I")]
        [ValidateScript({Test-Path $_ -PathType container})]
        [string]$InPath,
        
        [Parameter(Mandatory=$false,
        HelpMessage="Please supply path to output directory where XML Manifest should be written")]
        [Alias("O")]
        [ValidateScript({Test-Path $_ -PathType container})]
        [string]$OutPath,
        
        [Parameter(Mandatory=$false,
        HelpMessage="Please supply filter text to parse only logs whose name contains the filter text")]
        [Alias("SVC")]
        [ValidatePattern("[a-zA-Z0-9]")]
        [string]$Service,
        
        [Parameter(Mandatory=$false,
        HelpMessage="Please supply start date in format DD/MM/YY")]
        [Alias("SD")]
        [ValidatePattern("\d{2}\/\d{2}\/\d{2}")]
        [string]$StartDate,
        
        [Parameter(Mandatory=$false,
        HelpMessage="Please supply start time in format HH:MM:SS")]
        [Alias("ST")]
        [ValidatePattern("\d{2}:\d{2}:\d{2}")]
        [string]$StartTime,

        [Parameter(Mandatory=$false,
        HelpMessage="Please supply end date in format DD/MM/YY")]
        [Alias("ED")]
        [ValidatePattern("\d{2}\/\d{2}\/\d{2}")]       
        [string]$EndDate,
        
        [Parameter(Mandatory=$false,
        HelpMessage="Please supply end time in format HH:MM:SS")]
        [Alias("ET")]
        [ValidatePattern("\d{2}:\d{2}:\d{2}")]       
        [string]$EndTime
        )

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
$xml = "<?xml version=$('"')1.0$('"') ?>`n<manifest>`n<customer>`n<customerName>CUSTOMER01</customerName>`n"
}


Process {
#This code repeated for every string object passed in, to create XML structure for each file per the schema
    $line = $_ -split ' ' #split the line into two objects
    $xml += "<fileGroup>`n" #Open the fileGroup tag
        $xml += "<groupJobNumber>$($line[1])</groupJobNumber>`n" #create groupJobNumber tag with filename from object
        $xml += "<groupDocumentCount>1</groupDocumentCount>`n" #create groupDocumentCount - static value - 1 doc per group
        $xml += "<fileDetail>`n" #open the fileDetail tag
            $xml += "<fileJobNumber>$($line[1])</fileJobNumber>`n" #create fileJobNumber tag with filename from object
            $xml += "<customerFileName>$($line[1])</customerFileName>`n" #create customerFileName tag with filename from object
            $xml += "<rrdFilename>$($line[1])</rrdFilename>`n" #create rrdFilename tag with filename from object
            $xml += "<fileDocumentCount>1</fileDocumentCount>`n" #create fileDocumentCount tag static value - 1 doc per file
            $xml += "<transferDateTime>$($line[0])</transferDateTime>`n" #create transferDateTime tag with datestamp from object
            $xml += "<size>0</size>`n" #create size tag - static size of 0 as we don't have size information in history log
        $xml += "</fileDetail>`n" #close fileDetail tag
    $xml += "</fileGroup>`n" #fileGroup tag
}

End {
#create static end of file (same for every run)
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
| In-Time-Range function                                                                |
| Input: Start and end timestamp plus timestamp to be checked is in window              |
| Output: Returns true or false                                                         |
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#>
param (
        [Parameter(Mandatory=$true)]
        [ValidatePattern("\d{14}")]
        [Int64]$entry_date,
        
        [Parameter(Mandatory=$true)]
        [ValidatePattern("\d{14}")]
        [Int64]$winStart,

        [Parameter(Mandatory=$true)]
        [ValidatePattern("\d{14}")]
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

If($StartDate -and $StartTime -and $EndDate -and $EndTime){
    $logstart = Get-Date ($StartDate+" "+$StartTime) -f 'yyyyMMddHHmmss'
    $logend   = Get-Date ($EndDate+" "+$EndTime) -f 'yyyyMMddHHmmss'
    }
else
    {
    $logstart = Get-Date $([DateTime]::Today.AddDays(-1).AddHours(11)) -f 'yyyyMMddHHmmss'
    $logend   = Get-Date $([DateTime]::Today.AddHours(11).AddSeconds(-1)) -f 'yyyyMMddHHmmss'
    }

#$logstart = 20150105110000
#$logend   = 20150106105959


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

DisplayIt "$(0 + $converted.length) files found in history log and converted to XML in file $($outfl)"
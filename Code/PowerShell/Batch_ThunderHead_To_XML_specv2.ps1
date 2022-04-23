<#
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
| Batch_ThunderHead_To_XML.ps1                                                          |
| Version: 0.2                                                                          |
| Author: Graham Gold                                                                   |
| Description: Convert ThunderHead batch history logs to RRD XML Manifest format        |
| Run Location: ##REDACTED##								|
|_______________________________________________________________________________________|
| Version History                                                                       |
| ===============                                                                       |
| Version 0.1 - Initial Implementation/Proof of Concept                                 |
| Version 0.2 - Parameterise and support multiple input files to single output xml      |
| Version 0.3 - Fix extraneous single quote in -like pattern for server name match      |
|         ***If ($srv -like "'*BLAH*") {*** changed to ***If ($srv -like "*BLAH*") {*** |
|                                                                                       |
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

PATHS
=====
Script Path                          C:\##REDACTED##\BIN
Non-Prod History Log Input Path	     C:\##REDACTED##\RUN-MANIFEST_UAT\TEMP
Production History Log Input         C:\##REDACTED##\RUN-MANIFEST_PRD\TEMP
Output Path                          C:\##REDACTED##\DATA\OUT

Output File Name Specification
==============================
PROD:     MANLTCPYTHBB01MMDDYYYYHHMMSS.XML
NON-PROD: MANXTCPYTHBB01MMDDYYYYHHMMSS.XML

By default, script will detect environment of the server it is running on, choose input files and output file naming convention accordingly.
However, it can be configured to behave differently by using optional parameters (Documented below).

  
#>

############
#PARAMETERS#
############

param ( 
        [Parameter(Mandatory=$False)]
        [switch]$Live,

        [Parameter(Mandatory=$False)]
        [switch]$Test,      

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

$ErrorActionPreference="SilentlyContinue";
Stop-Transcript | out-null;
$ErrorActionPreference = "Continue"; # or "Stop"
Start-Transcript -Append -Force -Path ("Logs\Summary_" + (get-date -uformat %d_%m_%y) + ".txt");

###########
#FUNCTIONS#
###########

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
$file_number=1;
$total_files_today=3;
$cutoff_time="13:00";
$now=get-date -f 'dd-MM-yyyy';
$xml = "<?xml version=$('"')1.0$('"') ?>";
$xml = $xml+"`n<manifest total_files_today=$('"')$total_files_today$('"') ";
$xml = $xml+            "file_number=$('"')$file_number$('"') ";
$xml = $xml+            "date_generated=$('"')$now$('"') ";
$xml = $xml+            "cutoff_time=$('"')$cutoff_time$('"')> ";
$xml = $xml+"`n<customer>";
$xml = $xml+"`n<customerName>CUSTOMER01</customerName>`n";
}


Process {
If ($_.Length -gt 0) {
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
}

End {
#create static end of file (same for every run)
$xml += "</customer>`n</manifest>`n"

#echo the xml string as output
$xml
};
}; 

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
Write-Host "[$(Get-Date -f 'yyyyMMddHHmmss')]: $($msg)`r`n";
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
    return $true;
    }
    else
    {
    return $false;
    };
};

######################################
#INITIALISATION AND PARAMETER PARSING#
######################################

#If we were supplied all necessary date/time parameters, populate logging date ranges, otherwise, assume 11:00 yesterday until 10:59 today
If($StartDate -and $StartTime -and $EndDate -and $EndTime){
    $logstart = Get-Date ($StartDate+" "+$StartTime) -f 'yyyyMMddHHmmss';
    $logend   = Get-Date ($EndDate+" "+$EndTime) -f 'yyyyMMddHHmmss';
    }
else
    {
    $logstart = Get-Date $([DateTime]::Today.AddDays(-1).AddHours(11)) -f 'yyyyMMddHHmmss';
    $logend   = Get-Date $([DateTime]::Today.AddHours(11).AddSeconds(-1)) -f 'yyyyMMddHHmmss';
    };

DisplayIt ("Start Date/Time - " + $logstart);
DisplayIt ("End Date/Time - " + $logend);

#If neither of the $Live or $Test switches have been set (the default) then work out if we are on a production server or not.
If (!($Live) -and !($Test)) {
    $srv = (Get-WmiObject Win32_ComputerSystem).Name; #find out the name of the server I'm running on from WMI
     
    If ($srv -like "*BLAH*") {
        DisplayIt "Environment not specified but running on a production BLAH server so setting mode to Live";
        $Live = $True;
    }
    else
    {
        DisplayIt "Environment not specified but running on a non-production BLAH server so setting mode to Test";
        $Test = $True;
    };
};

#If both switches set, exit with error code -1, can't process live and test in same run!
If ($Live -and $Test){
    DisplayIt "Not able to process both Live and Test history log files - please re-run choosing one environment"
    Exit -1;
    };


#If input path not specified, set it based on environment.
If ($Live -and ($InPath.Length -eq 0)){
    $InPath = "C:\##REDACTED##\THUND-MANIFEST\DATA\RUN-MANIFEST_PRD\TEMP";
    };

If ($Test -and ($InPath.Length -eq 0)){
    $InPath = "C:\##REDACTED##\THUND-MANIFEST\DATA\RUN-MANIFEST_UAT\TEMP";
    };

If ($OutPath.Length -eq 0) {
    $OutPath = "C:\S##REDACTED##\THUND-MANIFEST\DATA\OUT";
    };

DisplayIt ("Input Path - " + $InPath);
DisplayIt ("Output Path - " + $OutPath);



#Read in the history logs
$FilesRead = Get-ChildItem $InPath\*.log;

If ($FilesRead.Count -gt 0) {
    $x = Get-Content $InPath\*.log|select -skip 1;
    DisplayIt "Logs Read OK: ";
    $FilesRead | ForEach {DisplayIt $_.FullName};
    }
Else
    {
    DisplayIt "No Logs found, producing empty manifest"
    $NoFiles = $True
    $converted = ""
    }

If (!($NoFiles)){
    #merge datestamp and filename for each print file to single line, separated by pipe character
    $x = (($x -join "|") -split "\|\|")
    DisplayIt "Date/Filename merged to same line for each file in log(s)";

    #convert the date formats and ensure new format of each line is `yyyyMMddHHmmss <filename>`
    $converted = $x |foreach {
        $i = ($_ -split '\|'); #split the line on the pipe character so you get a 2 object array
  
        #convert date format of object if in required time range
        $i[0] = Get-Date ($i[0] -replace '^\w+ (\w+ \d+) (\d+:\d+:\d+) (\d+)$', '$1 $3 $2') -f 'yyyyMMddHHmmss'; 
  
        If (In-Time-Range -entry_date $([Int64]$i[0]) -winStart $logstart -winEnd $logend){
      
            #return converted timestamp and filename, separated by a space
            $i[0] + ' ' + $i[1];
            };      
    };

    DisplayIt "Date/Time format converted - starting XML conversion";
}

#
#Pass to XML function to create XML and pipe to output file
#
If ($Live){
    $outfl = "$OutPath\MANLTCPYTHBB01$(get-date -f 'ddMMyyyyHHmmss').XML";
    }
    Else
    {
    $outfl = "$OutPath\MANXTCPYTHBB01$(get-date -f 'ddMMyyyyHHmmss').XML";
    };

DisplayIt "Tidying up previous XML manifests";
Remove-Item $OutPath\*.xml;

$converted|New-Xml-ThunderHead|out-file $outfl;

DisplayIt "$(0 + $converted.length) print files found in history logs and converted to XML in file $($outfl)";
Stop-Transcript;
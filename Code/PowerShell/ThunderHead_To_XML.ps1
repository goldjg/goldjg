function New-Xml-ThunderHead
{

Begin {
$xml = "<?xml version=$('"')1.0$('"') ?>`n<manifest>`n<customer>`n<customerName>CUSTOMER01</customerName>`n"
}


Process {
#$table|foreach{
    $i++
    Write-Progress -Activity "Adding records to XML" -Status "Processing record $($i) of $($table.length)"
    $xml += "<fileGroup>`n"
        $xml += "<groupJobNumber>$($_.groupJobNumber)</groupJobNumber>`n"
        $xml += "<groupDocumentCount>$($_.groupDocumentCount)</groupDocumentCount>`n"
        $xml += "<fileDetail>`n"
            $xml += "<fileJobNumber>$($_.fileJobNumber)</fileJobNumber>`n"
            $xml += "<customerFileName>$($_.customerFileName)</customerFileName>`n"
            $xml += "<rrdFilename>$($_.rrdFilename)</rrdFilename>`n"
            $xml += "<fileDocumentCount>$($_.fileDocumentCount)</fileDocumentCount>`n"
            $xml += "<transferDateTime>$($_.transferDateTime)</transferDateTime>`n"
            $xml += "<size>$($_.size)</size>`n"
        $xml += "</fileDetail>`n"
    $xml += "</fileGroup>`n"
    
#}
}

End {
$xml += "</customer>`n</manifest>`n"
$xml
}
} 

function ConvertFrom-DateString 
{ 
    [OutputType('System.DateTime')] 
    [CmdletBinding(DefaultParameterSetName='Culture')] 

   param( 
        [Parameter( 
            Mandatory=$true, 
            Position=0, 
            ValueFromPipeline=$true, 
            HelpMessage='A string containing a date and time to convert.' 
        )] 
        [System.String]$Value, 

        [Parameter( 
            Mandatory=$true, 
            Position=1, 
            HelpMessage='The required format of the date string value' 
        )] 
        [Alias('format')] 
        [System.String]$FormatString, 
    
        [Parameter(ParameterSetName='Culture')] 
        [System.Globalization.CultureInfo]$Culture=$null, 

        [Parameter(Mandatory=$true,ParameterSetName='InvariantCulture')] 
        [switch]$InvariantCulture 
    ) 

   process 
    { 
       if($PSCmdlet.ParameterSetName -eq ‘InvariantCulture‘) 
        { 
           $Culture = [System.Globalization.CultureInfo]::InvariantCulture 
        } 

       Try 
        {            
                    [System.DateTime]::ParseExact($Value,$FormatString,$Culture) 
        } 
       Catch [System.FormatException] 
        { 
           Write-Error “‘$Value’ is not in the correct format.“ 
        } 
       Catch 
        { 
           Write-Error $_        
        } 
    } 

   <# 
    .NOTES 
        Author: Shay Levy 
        Blog   : http://PowerShay.com 

    .LINK 
        http://msdn.microsoft.com/en-us/library/w2sa9yss.aspx 
   #> 

} 

<#

#Read History Log
$content = [io.file]::ReadAllLines("K:\RUN-THUND-PSPRD_PRD-History.log")

Write-Host "History Log Read [OK]"

#Change the datestamp format:

#first use select-string to get a table of dates using a regex
$dates = $content|select-string -pattern '^[A-Za-z]{3}\ [A-Za-z]{3}\ \d{2}\ \d{2}\:\d{2}\:\d{2}\ \d{4}'

Write-Host "Dates Captured [OK]"

#next go through each match in turn, converting the date string to a DateTime object,
#then use -f to format as string in required format
#then find original date in the imported content and replace with the new format
$dates | foreach {
                $strolddate = $_.Line
                $dtolddate = $strolddate|ConvertFrom-DateString -FormatString 'ddd MMM dd HH:mm:ss yyyy'
                $strnewdate = '{0:yyyyMMddHHmmss}' -f $dtolddate
                $content = $content -replace $strolddate,$strnewdate
                }

Write-Host "Dates Converted [OK]"

#join lines with spaces to get datestamps on same lines as filenames
$content = $content -join ' '

#Replace ".zip" with ".zip" with a newline on the end
$merged = ($content -replace '\ {2,}',' ') -replace ".zip",".zip`r`n"

#Trim Leading Spaces - first write out to temp file as -join made the entire file one string
$merged|Out-File K:\thd_tmp.txt

#remove the merged variable
rv merged

#repopulate $merged from the temp file
$merged = [io.file]::ReadAllLines("K:\thd_tmp.txt")

#Run through file trimming each line
$Trimmed = $merged|foreach {Return $_.TrimStart()}

#Write out file
$Trimmed|Out-File K:\THEAD.txt

Remove-Item K:\thd_tmp.txt

Write-Host "Building Table/Properties"

#
#Okay - now we have one line per file with datestamp in correct format - lets try to make some XML out of it!
#

$table = @()
$Trimmed|foreach {
    
    #Setup table with xml tag values for each file - set static values for the optional params
    
    
    $obj = $null
    $obj = New-Object System.Object
    $obj | Add-Member -type NoteProperty -Name groupJobNumber -Value $_.Split(' ')[1]
    $obj | Add-Member -type NoteProperty -Name groupDocumentCount -Value 1
    $obj | Add-Member -type NoteProperty -Name fileJobNumber -Value $_.Split(' ')[1]
    $obj | Add-Member -type NoteProperty -Name customerFilename -Value $_.Split(' ')[1]
    $obj | Add-Member -type NoteProperty -Name rrdFilename -Value $_.Split(' ')[1]
    $obj | Add-Member -type NoteProperty -Name fileDocumentCount -Value 1
    $obj | Add-Member -type NoteProperty -Name transferDateTime -Value $_.Split(' ')[0]
    $obj | Add-Member -type NoteProperty -Name size -Value 0
    $obj | Add-Member -type NoteProperty -Name fileCount -Value 1
    $table += $obj
    
}

Write-Host "Table Built [OK]"
#>
Write-Host "Creating XML String"

#
#Pass to XML function to create XML
#
$table|New-Xml-ThunderHead|out-file "K:\Manifest.xml"

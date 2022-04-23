<#
This script takes the output of a COMS UTILITY DUMP command (Dump of Trancodes),
as saved in a text file) and extracts only the `AGENDA =` and `TRANCODE_VALUE =` values.
The extracted data is output as a CSV file format for further analysis.

Author: Graham Gold 
Created: 22 January 2014
Last Updated: 23 January 2014 13:15:51

Parameters: None

Requirements:   1. A drive mapped to the letter K
                2. A file called TRANCODES.txt in that drive root folder

#>

Write-Host "Reading Mainframe Extract File"

<#
Format of each trancode record is:

CREATE   TRANCODE   ABC               OF ABC123
AGENDA                   = TZYXINAG
,ANY_SC_LIST              = NONE    ,EVERY_SC_LIST            = NONE
,SECURITY_CATEGORY        = NONE    ,FUNCTION                 = 14
,TRANCODE_VALUE           = "ABC"
,TRANCODE_FUNCTION_MNEMONIC = NONE
,INSTALLATION_DATA        = NONE
;
#>

$Start = gc "K:\TRANCODES.TXT" #read the input file
Write-Host ("Read Complete : " + $Start.Count + " records found")

Write-Host "Filtering records for AGENDA/TRANCODE information"
$Filtered = $Start|Select-String -Pattern "TRANCODE" # extract only lines containing the string "AGENDA" or "TRANCODE_VALUE"
Write-Host ([String]($Filtered.Count/2) + " AGENDA/TRANCODE pairs found")

<#
Format of Select-String output is:
AGENDA                   = TZYXINAG
,TRANCODE_VALUE           = "ABC"
#>

Write-Host "Building table from the filter results" 

#parse the filtered data, building an array of objects, each with 2 properties, TRANCODE and AGENDA
[int]$count = 0 #start a counter to track progress through loop
$CSV = @() #create array object
$sw = [System.Diagnostics.Stopwatch]::StartNew() #start stopwatch object (to ensure Write-Progress not called on every loop iteration)
    

$Filtered|foreach {#If ($_.ToString() -Match 'AGENDA'){
                    #  $obj = New-Object System.Object;    #create new $obj &
                     # $obj | Add-Member -type NoteProperty -name AGENDA -Value $_.ToString().SubString(27)}    #Add AGENDA property/value
                   If ($_.ToString() -Match ' TRANCODE '){# found TRANCODE
                      $obj = New-Object System.Object;                      
                      $obj | Add-Member -type NoteProperty -name TRANCODE -Value ($_.ToString().Split(" ")[6]);    #Add TRANCODE property/value
                      $obj | Add-Member -type NoteProperty -name WINDOW -Value ($_.ToString().SubString(41,10).TrimEnd());
                      $CSV += $obj;    #Add the $obj to the array (in terms of the final CSV, we're adding a row to it)
                      $obj = $null}    #clear the object for use in next loop iteration
                      $count++    #increase the counter    
                      
                      <#Wrap Write-Progress in a timer, because calling it every time round such a 
                      tiny loop makes performance awful!!#>                               
                   If ($sw.Elapsed.TotalMilliseconds -ge 500) {    #been at least 0.5 secs since last progress update so display one
                      Write-Progress `
                      -Activity "Building table of values from filter results" `
                      -Status ("Processed " + $count + " of " + $Filtered.Count + " records") `
                      -Id 1 `
                      -PercentComplete ([int]($count/$Filtered.Count *100));
                      $sw.Reset();
                      $sw.Start()}    #else less than 0.5 secs since last progress update so don't do one
                   }    #end of loop

#Take progress bar off screen with `-Completed` switch since we're done.
Write-Progress `
-Activity "Building table of values from filter results" `
-Status ("Table built : " + $CSV.Count + " rows created") `
-Id 1 `
-Completed

Write-Host ("Table built : " + $CSV.Count + " rows created")

<#
Format of $CSV is:
AGENDA                                            TRANCODE                                        
------                                            --------                                        
TZYXINAG                                          ABC                                             
TXYZINAG                                          CBA                                              
#>

Write-Host "Sorting and Exporting table to CSV file"
            
$CSV|Select TRANCODE,WINDOW|Sort TRANCODE |Export-CSV -notype "K:\TRANCODES.CSV"    #sort the table, then export it to a CSV file

Write-Host "File created - successful run"

rv Start,Filtered,CSV,count,sw    #All done, best tidy up!
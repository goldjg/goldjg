Write-Host "Reading Mainframe Extract File"

<#
Format of each USERCODE record is:

CREATE   USER    USER001                                                00000210          
  DEFAULT_WINDOW           = MARC                                       00000220          
 ,WINDOW_LIST              = USER001WL                                  00000230          
 ,DEFAULT_TRANCODE         = NONE                                       00000240          
 ,STATION_LIST             = ALL     ,SECURITY_CATEGORY_LIST   = ALL    00000250          
 ,STATION_SECURITY_OVERRIDE= N       ,CONTROL                  = Y      00000260          
 ,CLOSE_ACTION             = 4                                          00000270          
 ,CLOSE_WINDOW             = NONE                                       00000280          
 ,INSTALLATION_DATA        = NONE                                       00000290          
;                                                                       00000300  
#>

$Start = gc "K:\USERCODES.TXT" #read the input file
Write-Host ("Read Complete : " + $Start.Count + " records found")

$Start = $Start -replace ' USER ','USER='

Write-Host "Filtering records for USER/WINDOWLIST information"
$Filtered = $Start|Select-String -Pattern "CREATE","MODIFY","WINDOW_LIST" # extract only lines containing the string "USER" or "WINDOW_LIST"
Write-Host ([String]($Filtered.Count/2) + " USER/WINDOWLIST pairs found")

<#
Format of Select-String output is:
USER                   = USER001
,WINDOW_LIST           = "USER001WL"
#>

Write-Host "Building table from the filter results" 

#parse the filtered data, building an array of objects, each with 2 properties, WINDOWLIST and USER
[int]$count = 0 #start a counter to track progress through loop
$CSV = @() #create array object
$sw = [System.Diagnostics.Stopwatch]::StartNew() #start stopwatch object (to ensure Write-Progress not called on every loop iteration)
    

$Filtered|foreach {If ($_.ToString() -Match 'USER'){
                      $obj = New-Object System.Object;    #create new $obj &
                      $obj | Add-Member -type NoteProperty -name USER -Value $_.ToString().Split("=")[1].TrimStart().Split(" ")[0]}    #Add USER property/value
                   If ($_.ToString() -Match 'WINDOW_LIST'){# found WINDOWLIST
                      $obj | Add-Member -type NoteProperty -name WINDOWLIST -Value ($_.ToString().Split("=")[1].TrimStart().Split(" ")[0]);    #Add WINDOWLIST property/value
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
USER                                            WINDOWLIST                                        
------                                            --------                                        
USER001						USER001WL                                             
#>

Write-Host "Sorting and Exporting table to CSV file"
            
$CSV|Select USER,WINDOWLIST|Sort USER |Export-CSV -notype "K:\USERCODES.CSV"    #sort the table, then export it to a CSV file

Write-Host "File created - successful run"

rv Start,Filtered,CSV,count,sw    #All done, best tidy up!
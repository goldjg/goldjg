<#
MCP_QDEF2CSV.ps1
~~~~~~~~~~~~~~~~
Converts MCP QF command output (STored in a file from MARC) to CSV list of Q's and attributes

INPUT: .TXT file on user home drive/K drive (or selected location via file open dialog)
OUTPUT: .CSV file in same location as input file, with same name, but CSV extension.

 QUEUE 0:                                                                       
   MIXLIMIT = 9                                                                
   DEFAULTS:                                                                    
     PRIORITY = 50                                                              
   LIMITS:                                                                      
     PRIORITY = 80                                                              
 QUEUE 1:                                                                       
   MIXLIMIT = 4                                                                 
   DEFAULTS:                                                                    
     PRIORITY = 50                                                              
     PROCESSTIME = 120                                                          
     IOTIME = 240                                                               
     LINES = 12000                                                              
   LIMITS:                                                                      
     PRIORITY = 50                                                              

#>

Function Get-FileName($initialDirectory)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "TXT (*.txt)| *.txt"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
}

$inputfile = Get-FileName("\\$env:homedataserver\$env:username")

If ($inputfile.length -eq 0) {$lastexitcode = -1;Throw "Must select an input file"}
If (!(test-path $inputfile)) {$lastexitcode = -2;Throw "Selected file not present, it may have been removed"}
$Q_raw = (gc $inputfile) -replace ('  ','') -replace (':','') #read input file, removing extra spaces and colons
$Q_raw = $Q_raw|select -skip 5 # strip first 5 lines (MARC header)

[System.Collections.ArrayList]$ary=@() #define array for export to CSV
$obj = New-Object System.Object #create object for first csv record
$obj|Add-Member -MemberType NoteProperty -Name QUEUE -Value $Null #add QUEUE property to create a null record

$Q_raw|foreach { #process Q's
    If (($_.ToString()) -match "^ QUEUE \d{1,3}") {If(($obj|gm -MemberType NoteProperty).Count -eq 0) { #this is the first Q in the file
                                                            $DEF=$LIM=$False; #reset flags, then add Q number to record but don't add record to array as still building it
                                                            $obj|Add-Member -MemberType NoteProperty -Name QUEUE -Value ($_.ToString().Split(' ')[2])} else 
                                                           { #this an additional Q in the file
                                                            $DEF=$LIM=$False; #reset flags 
                                                            $ary += $obj;$obj = New-Object System.Object; #add object to array, create new object, add new queue to new object
                                                            $obj|Add-Member -MemberType NoteProperty -Name QUEUE -Value ($_.ToString().Split(' ')[2])} }                                                    
    If (($_.ToString()) -like '*DEFAULTS*')   {$DEF=$true;$LIM=$false} #If default attribute, set flag to ensure correct column used
    If (($_.ToString()) -like '*LIMITS*')     {$LIM=$true;$DEF=$false} #If limit attribute, set flag to ensure correct column used

    #If any of the following attributes are set, add to object
    If (($_.ToString()) -like '*MIXLIMIT*')   {$obj|Add-Member -MemberType NoteProperty -Name MIXLIMIT -Value ($_.ToString().Split('=')[1].Trim(" "))} 
    If (($_.ToString()) -like '*TURNAROUND*') {$obj|Add-Member -MemberType NoteProperty -Name TURNAROUND -Value ($_.ToString().Split('=')[1].Trim(" "))} 
    If (($_.ToString()) -like '*TASKLIMIT*')  {$obj|Add-Member -MemberType NoteProperty -Name TASKLIMIT -Value ($_.ToString().Split('=')[1].Trim(" "))} 
    If (($_.ToString()) -like '*QUEUELIMIT*') {$obj|Add-Member -MemberType NoteProperty -Name QUEUELIMIT -Value ($_.ToString().Split('=')[1].Trim(" "))} 
    If (($_.ToString()) -like '*FAMILY*')     {$obj|Add-Member -MemberType NoteProperty -Name FAMILY -Value ($_.ToString().Split('=')[1].Trim(" "))} 

    #If any of the following attributes are set, add to object, based on flag setting (defaults vs limits)
    If (($_.ToString()) -like '*PRIORITY*') {If ($DEF) {$obj|Add-Member -MemberType NoteProperty -Name DEFPRIORITY -Value ($_.ToString().Split('=')[1].Trim(" "))} 
                                                       else{$obj|Add-Member -MemberType NoteProperty -Name LIMPRIORITY -Value ($_.ToString().Split('=')[1].Trim(" "))} }

    If (($_.ToString()) -like '*PROCESSTIME*') {If ($DEF) {$obj|Add-Member -MemberType NoteProperty -Name DEFPROCESSTIME -Value ($_.ToString().Split('=')[1].Trim(" "))}
                                                         else{$obj|Add-Member -MemberType NoteProperty -Name LIMPROCESSTIME -Value ($_.ToString().Split('=')[1].Trim(" "))} } 
                                                           
    If (($_.ToString()) -like '*SAVEMEMORYLIMIT*') {If ($DEF) {$obj|Add-Member -MemberType NoteProperty -Name DEFSAVEMEMORYLIMIT -Value ($_.ToString().Split('=')[1].Trim(" "))} 
                                                            else{$obj|Add-Member -MemberType NoteProperty -Name LIMSAVEMEMORYLIMIT -Value ($_.ToString().Split('=')[1].Trim(" "))} }

    If (($_.ToString()) -like '*IOTIME*') {If ($DEF) {$obj|Add-Member -MemberType NoteProperty -Name DEFIOTIME -Value ($_.ToString().Split('=')[1].Trim(" "))} 
                                                     else{$obj|Add-Member -MemberType NoteProperty -Name LIMIOTIME -Value ($_.ToString().Split('=')[1].Trim(" "))} }

    If (($_.ToString()) -like '*LINES*') {If ($DEF) {$obj|Add-Member -MemberType NoteProperty -Name DEFLINES -Value ($_.ToString().Split('=')[1].Trim(" "))} 
                                                    else{$obj|Add-Member -MemberType NoteProperty -Name LIMLINES -Value ($_.ToString().Split('=')[1].Trim(" "))} }

    If (($_.ToString()) -like '*WAITLIMIT*') {If ($DEF) {$obj|Add-Member -MemberType NoteProperty -Name DEFWAITLIMIT -Value ($_.ToString().Split('=')[1].Trim(" "))} 
                                                        else{$obj|Add-Member -MemberType NoteProperty -Name LIMWAITLIMIT -Value ($_.ToString().Split('=')[1].Trim(" "))} }

    If (($_.ToString()) -like '*ELAPSEDLIMIT*') {If ($DEF) {$obj|Add-Member -MemberType NoteProperty -Name DEFELAPSEDLIMIT -Value ($_.ToString().Split('=')[1].Trim(" "))} 
                                                           else{$obj|Add-Member -MemberType NoteProperty -Name LIMELAPSEDLIMIT -Value ($_.ToString().Split('=')[1].Trim(" "))} }
} #end of file

$ary += $obj;rv obj; #ensure last object added to array since loop finished

$ary.RemoveAt(0); #remove null record from array

$ary=$ary|select ($ary|foreach {$_ | get-member -MemberType NoteProperty | Select -ExpandProperty Name} | Select -Unique) #ensure all populated columns selected, not just common columns

$headings=$ary|foreach {$_|Get-Member -MemberType NoteProperty|select -ExpandProperty Name}|select -Unique|sort|where {$_ -ne "QUEUE"} #get list of columns for csv column heading

$header = @() #create header array
$header += "QUEUE" #add QUEUE as first column
$headings|foreach {$header += $_} #Add remaining columns to header

$outfile=$inputfile -replace ".txt",".CSV"

#Sort array numerically by queue number, ascending. Select columns based on header, export to CSV file.
Try {$ary | Sort-Object { [int]$_.QUEUE }|select -Property $header |`
                Export-Csv -NoTypeInformation -Path $outfile -ErrorAction Stop}
Catch {
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    Break    
    }
Finally
    {
        If ($ErrorMessage){ Write-Error ("$ErrorMessage : $FailedItem") }
    }

    Write-Host -ForegroundColor Green "$outfile created successfully"
    exit 0
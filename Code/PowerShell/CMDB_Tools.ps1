#########################################################################################################
#                                                                                                       #
# CMDB_Tools Script by Graham Gold                                                                      #
# --------------------------------                                                                      #
# Used for CMDB functions including database query, reconciliation etc                                  #
#                                                                                                       #
# -Verbose switch can be used to display information at runtime (default is silent)                     #
#                                                                                                       #
# Has 1 required parameter and 6 optional parameters:                                                  #
#   - mode : Required (can be shortened to m)                                                           #
#     Runmode. Defines which functions the script should perform e.g. query, reconcile                  #
#                                                                                                       #
#   - connfile : Required (can be shortened to c)                                                       #
#     Name of a file containing SQL connection string e.g. CMDB_Prod.con                                #
#                                                                                                       #
#   - queryfile : Required (can be shortened to q)                                                      #
#     Name of a file containing a SQL query that is valid for the database                              #
#     referred to in the connection file e.g. Unisys_Cluster.sql                                        #
#                                                                                                       #
#   - outputfile : Required (can be shortened to output)                                                #
#     Name of output file (CSV) to be created with SQL query output                                     #
#                                                                                                       #
#   - pathq : Optional                                                                                  #
#     Path to folder containing query and connection files.                                             #
#     Can use C:\...\ or \\...\...\ UNC format. If not backslash (\) on the                             #
#     end, one will be added e.g. C:\Users\Graham would become C:\Users\Graham\                         #
#                                                                                                       #
#   - pathout : Optional                                                                                #
#     Path to folder to save output file in.                                                            #
#     Can use C:\...\ or \\...\...\ UNC format. If not backslash (\) on the                             #
#     end, one will be added e.g. C:\Users\Graham would become C:\Users\Graham\                         #
#                                                                                                       #
#   - display : Optional (can be shortened to disp)                                                     #
#     Optional flag that, if set, will display database query information if mode = query               #
#                                                                                                       #
# Syntax Examples:                                                                                      #
# .\CMDB_Query.ps1 -c CMDB_Prod.con -q IBM_Relationships.sql -output IBM_Relationships.csv -v           #
#    Returns:                                                                                           #
#    VERBOSE: Query Path not supplied, using current path                                               #
#    VERBOSE: Output Path not supplied, using current path                                              #
#    VERBOSE: 173 records extracted from database CMDB_Prod to file                                     #
#    .\IBM_Relationships.csv using query IBM_Relationships                                              #
#                                                                                                       #
# .\CMDB_Query.ps1 -c CMDB_Prod.con -q Unisys_LPAR.sql -output Unisys_LPAR.csv                          #
# -pathq \\##REDACTED##\Graham\CMDB\Reconciliation\Automation\                                           #
# -pathout \\##REDACTED##\Graham\CMDB\Reconciliation\Automation\ -v                                      #  
#    Returns:                                                                                           #
#    VERBOSE: Query Path supplied: \\##REDACTED##\Graham\CMDB\Reconciliation\Automation\                 #
#    VERBOSE: Output Path supplied: \\##REDACTED##\Graham\CMDB\Reconciliation\Automation\                #
#    VERBOSE: 4 records extracted from database CMDB_Prod to file                                       #
#    \\##REDACTED##\Graham\CMDB\Reconciliation\Automation\Unisys_LPAR.csv using query Unisys_LPAR        #
#                                                                                                       #
#########################################################################################################
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("query","reconcile","querymail","compare")]
        [string]$mode,
        
        [Parameter(Mandatory=$false)]
        [ValidateScript({Test-Path $_ -PathType leaf})]
        [string]$connfile,
        
        [Parameter(Mandatory=$false)]
        [ValidateScript({Test-Path $_ -PathType leaf})]
        [string]$queryfile,
        
        [Parameter(Mandatory=$false)]
        #[ValidateScript({Test-Path $_ -PathType leaf})]
        [string]$outputfile,

        [Parameter(Mandatory=$false)]
        #[ValidateScript({Test-Path $_ -PathType leaf})]
        [string]$CSVInput,

        [Parameter(Mandatory=$false)]
        #[ValidateScript({Test-Path $_ -PathType leaf})]
        [string]$CSVOutput,
        
        [Parameter(Mandatory=$false,
        HelpMessage="Query Path should be in format 'C:\...\' or '\\...\...\'. Default (if not supplied) is current path '.\'")]
        #[ValidateScript({Test-Path $_ -PathType container})]
        [string]$pathq,

        [Parameter(Mandatory=$false,
        HelpMessage="Output Path should be in format 'C:\...\' or '\\...\...\'. Default (if not supplied) is current path '.\'")]
        #[ValidateScript({Test-Path $_ -PathType container})]
        [string]$pathout,

        [Parameter(Mandatory=$false,
        HelpMessage="Baseline Path should be in format 'C:\...\' or '\\...\...\'. Default (if not supplied) is current path '.\'")]
        #[ValidateScript({Test-Path $_ -PathType container})]
        [string]$pathbase,

        [Parameter(Mandatory=$false,
        HelpMessage="Report Path should be in format 'C:\...\' or '\\...\...\'. Default (if not supplied) is current path '.\'")]
        #[ValidateScript({Test-Path $_ -PathType container})]
        [string]$pathrep,

        [Parameter(Mandatory=$false)]
        [switch]$display

    )

#Function to Query the CMDB database and write the result out to a CSV file.
Function CMDB-Query{

    #Setup SQL connection object using .NET       
    $connection = New-Object -TypeName System.Data.SqlClient.SqlConnection
    
    #Get connection string from connection file
    $connString = get-content ($pathq + $connfile)
    
    #Get SQL query from queryfile
    $query = get-content ($pathq + $queryfile)
    
    #Set ConnectionString property of SQL object
    $connection.ConnectionString = $connString
    
    #Create new SQL command
    $command = $connection.CreateCommand()
    
    #Populate CommandText property using query read in from file
    $command.CommandText = $query
    
    #Invoke SQL command using SQL Data Adapter (.NET object)
    $adapter = New-Object -TypeName System.Data.SqlClient.SqlDataAdapter $command
    
    #Setup DataSet object to handle the SQL output/response
    $dataset = New-Object -TypeName System.Data.DataSet
    
    #Fill the dataset with the SQL response. Using [void] redirects console output to null (don't display)
    [void]$adapter.Fill($dataset)
        
    #Pipe the contents of the dataset. Use Select to select all columns/properties excluding those that were created by the DataSet object (not actual data)
    #Pipe to Export-CSV function to create a CSV file, use -notypeinformation flag to skip Object type information from the file (e.g. System.String etc)
    $dataset.Tables[0] | Select *  -ExcludeProperty RowError, RowState, HasErrors, Table, ItemArray | Export-CSV -notypeinformation -path ($pathout + $outputfile)
    
    #Write out a message detailing number of records found, using what database and query, and what the output file name is
    write-verbose ([string]$dataset.tables[0].rows.count + " records extracted from database "+$connfile.substring(0,$connfile.length - 4)+" to file "+$pathout+$outputfile+" using query "+$queryfile.substring(0,$queryfile.length - 4))

    #If display flag is set, also display SQL query results
    If ($display)
        {$dataset.Tables[0] | Select *  -ExcludeProperty RowError, RowState, HasErrors, Table, ItemArray | format-table -auto}
}

Function CMDB-CompareCSV{
    #Setup arrays to store deleted/added records
    $RecordsDeleted = @{}; $RecordsAdded = @{}
    $csv1 = Import-csv ($pathbase + $CSVInput)
    $csv2 = Import-csv ($pathout + $CSVOutput)
        
    $flds = ($csv1[0].psobject.properties | %{$_.Name} )
    $flds2 = ($csv2[0].psobject.properties | %{$_.Name} )

    $Key = $flds[0]

    $NewFields = Compare-Object $flds $flds2 -passthru | Where-Object {$_.SideIndicator -eq "=>"}
    $NumNewFields = $NewFields | Measure-Object | Select -Expand Count

    $DelFields = Compare-Object $flds $flds2 -passthru | Where-Object {$_.SideIndicator -eq "<="}
    $NumDelFields = $DelFields | Measure-Object | Select -Expand Count

    # First, compare the data only comparing key fields, noting records that only 
    # appear in the first file (aka deleted) or only in file 2 (added).
    Compare-Object $csv1 $csv2 -Property $Key -PassThru | %{
        $item = $_ 
        # save the current record in $item as the switch command will overwrite $_   
        # The SideIndicator tells us whether these records are added or missing.
        switch ($_.SideIndicator) {
            '<=' { # These records are missing - save the keys values for comparison later
                $RecordsDeleted[ $item.id ] = 1
                break
            }        
            '=>' {  # These records have been added - save the keys values for comparison later
                $RecordsAdded[ $item.id ] = 1
                break
            }
        }
    }
        
    # Next, define a calculated property that is used in the next Compare test to 
    # note whether a record has been Added, Deleted or has a difference.  If the data is only 
    # found in one file (i.e. the key is only in one file) it's reported as a Deleted or Added 
    # record, respectively.  However, if the key is in both but noted as a difference record,
    # we identify it as such.

    $CompResult = @{
        Label="Reconciliation_Result";  
        Expression={ $item = $_
                Switch ($_.SideIndicator) {
                '<=' { if ( $RecordsDeleted.ContainsKey( $item.$Key ) ) {
                        "Deleted" # Return "Deleted" as the compare result                        
                    } else {
                        "Changed/Baseline"
                     }
                  }                 
                 '=>' { if ( $RecordsAdded.ContainsKey( $item.$Key ) ) {
                        "Added"   # Compare result is "Added"
                    } else {
                        "Changed/Current"
                     }
                  }
               }
            }
         }

    $RsltGrid = Compare-Object $csv1 $csv2 -Property $flds -PassThru |
    Sort-Object -Property @{ Expression = {$_.$Key + $_.SideIndicator }} |                  
    Select-Object -Property $CompResult,*
    
    $flds = ($RsltGrid[0].psobject.properties | %{$_.Name} )
    foreach ($Key2 in $flds) {
        $Values = $RsltGrid | Select * -Exclude SideIndicator| where-object {($_.Reconciliation_Result -like "Changed*") -and ($Key2 -ne "own_resource_uuid") -and ($Key2 -ne "id")} | select -expand $Key
        For ($i = $Values.GetLowerBound(0); $i -lt $Values.GetUpperBound(0); $I=$I+2) {
            If ((($Values[$i]) -ne ($Values[$i+1])) -and $Key2 -ne "Reconciliation_Result"){
                If ($ChangedAtts -notcontains $Key2) {$ChangedAtts += $Key2}
                }
            }
        }
    foreach ($Attrib in $ChangedAtts) {
    $RsltGrid2 = $RsltGrid | Select @{Name=("*** " + $Attrib + " ***");Expression={$_.$Attrib}}, * -Exclude $Attrib, SideIndicator
    }
    
    $RsltGrid | out-gridview
    $RsltGrid2 | out-gridview 
 
    $CSVRep = ($pathrep + ($CSVInput.split(".")[0]) + " Reconciliation Report " + (get-date -uformat "%Y%m%d%_%H%M%S") + ".csv") 
 
    $RsltGrid2 | Select * | Export-CSV -notype $CSVRep

    $Deleted = $RsltGrid2 | Where-Object { $_.Reconciliation_Result -Match "Deleted" } | Measure-Object | Select -Expand Count
    $Added = $RsltGrid2 | Where-Object { $_.Reconciliation_Result -Match "Added" } | Measure-Object | Select -Expand Count
    $Changed = $RsltGrid2 | Where-Object { $_.Reconciliation_Result -Match "Changed/Baseline" } | Measure-Object | Select -Expand Count
    $BaseTotal = $csv1 | Select -Property $Key | Measure-Object | Select -Expand Count
    $NewTotal = $csv2 | Select -Property $Key | Measure-Object | Select -Expand Count

    $Report = ("<H2>" + (($CSVInput.split(".")[0]) -replace "_", " ") + " CMDB Reconciliation Report</H2>" + 
               ($BaseTotal -as [string]) + ' CIs in <a href ="' + ($pathbase + $CSVInput) + '">Baseline</a><BR>' +
               ($NewTotal -as [string]) + ' CIs in <a href ="' + ($pathout + $CSVOutput) + '">database extract</a><BR><BR>' +
               ($Added -as [string]) + " CI(s) added since last baseline taken<BR>" +
               ($Deleted -as [string]) + " CI(s) deleted since last baseline taken<BR>" +
               ($Changed -as [string]) + " CI(s) amended since last baseline taken<BR><BR>")

    If ($NumNewFields -gt 0) {
        $warning = ('<font color="red" <B>' + ($NumNewFields -as [string]) + "`tAttribute(s) added to DB query since last baseline taken.<BR>" + 
                     "Please re-baseline to ensure accurate reconciliation.<BR>" + 
                     "New attributes are :<BR>" + ($NewFields|out-string) + "</B></font><BR><BR>")}
                 
    If ($NumDelFields -gt 0) {
        $Warning =  ('<font color="red" <B>' + ($NumDelFields -as [string]) + "`tAttribute(s) removed from DB query since last baseline taken.<BR>" + 
                    "Please re-baseline to ensure accurate reconciliation.<BR>" + 
                    "Deleted attributes are :<BR>" + ($DelFields|out-string) + "<B></font><BR><BR>")}

    $head = "<style>"
    $head = $head + "TABLE{font-family:Calibri;border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
    $head = $head + "TH{border-width: 1px;padding: 5px;border-style: solid;border-color: black;background-color:PaleGoldenrod}"
    $head = $head + "TD{border-width: 1px;padding: 5px;border-style: solid;border-color: black}"
    $head = $head + "</style>"

    $HTMRep = ($pathrep + ($CSVInput.split(".")[0]) + " Reconciliation Report " + (get-date -uformat "%Y%m%d%_%H%M%S") + ".htm")
    

    If (($Deleted -gt 0) -or ($Added -gt 0) -or ($Changed -gt 0)) { 
        $RsltGrid2 | Select * -ExcludeProperty SideIndicator | 
        ConvertTo-HTML -title "Reconciliation Report" -head $head -body ('<font face="Calibri">' + $Report + $Warning) -post ('
        <B><P>Generated by <font color="Light Blue">CMDB_Tools</font> on <font color="Purple">' + (hostname) + "</font> - 
        " + (get-date -uformat %c) + "</P></B><BR></font>") > $HTMRep
     } else {
        ConvertTo-HTML -title "Reconciliation Report" -head $head -body ('<font face="Calibri">' + $Report + $Warning) -post ('
        <B><P>Generated by <font color="Light Blue">CMDB_Tools</font> on <font color="Purple">' + (hostname) + "</font> - 
        " + (get-date -uformat %c) + "</P></B><BR></font>") > $HTMRep
        }    

    #Invoke-Item $HTMRep

    $smtpServer = "smtp.pru.local"
    $Subject = (($CSVInput.split(".")[0]) -replace "_", " ") + " Reconciliation Report - " + (get-date -uformat "%A, %e %B %Y")

    $msg = new-object Net.Mail.MailMessage
    $smtp = new-object Net.Mail.SmtpClient($smtpServer)
    $att1 = $CSVRep
    $att2 = ($pathbase + $CSVInput)
    $att3 = ($pathout + $CSVOutput)
    
    $msg.From = "CMDB_Tools@domain"
    $msg.To.Add("##REDACTED##")
    $msg.Subject = $Subject
    $msg.IsBodyHTML = $True
    $msg.Body = (gc $HTMRep|out-string)
    $att = new-object Net.Mail.Attachment($att1)
    $msg.Attachments.Add($att)    
    $att = new-object Net.Mail.Attachment($att2)
    $msg.Attachments.Add($att)
    $att = new-object Net.Mail.Attachment($att3)
    $msg.Attachments.Add($att)

    $smtp.Send($msg)
    
}

#Main Processing

#Check if query path was supplied, if not, set it to current path
If ($pathq)
    {write-verbose "Query Path supplied: $pathq"}
    else
    {write-verbose "Query Path not supplied, using default path"
    $pathq = "\\##REDACTED##\CMDB\Reconciliation\Automation\Queries\"}

#Check if query path has a backslash as the right-most character, if not add one
# (for joining path and filename together)        
If ($pathq.substring($pathq.length - 1,1) -ne "\")
    {$pathq=($pathq + "\")}

#Check if output path was supplied, if not, set it to current path    
If ($pathout)
    {write-verbose "Output Path supplied: $pathout"}
    else
    {write-verbose "Output Path not supplied, using default path"
    $pathout = "\\##REDACTED##\CMDB\Reconciliation\Automation\In\"}    

#Check if output path has a backslash as the right-most character, if not add one
# (for joining path and filename together)        
If ($pathout.substring($pathout.length - 1,1) -ne "\")
    {$pathout=($pathout + "\")}
        
#Check if baseline path was supplied, if not, set it to current path    
If ($pathbase)
    {write-verbose "Baseline Path supplied: $pathbase"}
    else
    {write-verbose "Baseline Path not supplied, using default path"
    $pathbase = "\\##REDACTED##\CMDB\Reconciliation\Automation\Baseline\"}    

#Check if baseline path has a backslash as the right-most character, if not add one
# (for joining path and filename together)        
If ($pathbase.substring($pathbase.length - 1,1) -ne "\")
    {$pathbase=($pathbase + "\")}           

#Check if report path was supplied, if not, set it to current path    
If ($pathrep)
    {write-verbose "Report Path supplied: $pathrep"}
    else
    {write-verbose "Report Path not supplied, using default path"
    $pathrep = "\\##REDACTED##\CMDB\Reconciliation\Automation\Reports\"}    

#Check if report path has a backslash as the right-most character, if not add one
# (for joining path and filename together)        
If ($pathrep.substring($pathrep.length - 1,1) -ne "\")
    {$pathrep=($pathrep + "\")}           


#Determine runmode, check required parameters passed for runmode and call the required functions
Write-Verbose ("Running in "+$mode.ToUpper()+" mode.")
If ($mode -eq "query")
    {
    If (-not $connfile) 
        {
        write-error -Category SyntaxError -CategoryReason "Missing Parameter: connfile" -Message "The -connfile parameter is required in query mode and should be the name of an existing connection string file"
        Return (-1)
        Exit
        }
    If (-not $queryfile) 
        {
        write-error -Category SyntaxError -CategoryReason "Missing Parameter: queryfile" -Message "The -queryfile parameter is required in query mode and should be the name of an existing SQL query file"
        Return (-2)
        Exit
        }                
    If (-not $outputfile) 
        {
        write-error -Category SyntaxError -CategoryReason "Missing Parameter: outputfile" -Message "The -outputfile parameter is required in query mode and should be the name of the output file"
        Return (-3)
        Exit
        }                
    CMDB-Query -c $connfile -q $queryfile -output $outputfile -v
    }
If ($mode -eq "compare")
    {
    If (-not $CSVInput) 
        {
        write-error -Category SyntaxError -CategoryReason "Missing Parameter: CSVInput" -Message "The -CSVInput parameter is required in compare mode and should be the name of and existing baseline CSV file"
        Return (-1)
        Exit
        }
    If (-not $CSVOutput) 
        {
        write-error -Category SyntaxError -CategoryReason "Missing Parameter: CSVOutput" -Message "The -CSVOutput parameter is required in compare mode and should be the name of an existing extract CSV file"
        Return (-2)
        Exit
        }                
    If (-not $pathrep) 
        {
        write-error -Category SyntaxError -CategoryReason "Missing Parameter: pathrep" -Message "The -pathrep parameter is required in compare mode and should be the output path for reports"
        Return (-3)
        Exit
        }
    CMDB-CompareCSV -CSVI $CSVInput -CSV $CSVOutput                
    }
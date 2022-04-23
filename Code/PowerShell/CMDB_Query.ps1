#########################################################################################################
#                                                                                                       #
# CMDB_Query Script by Graham Gold                                                                      #
# --------------------------------                                                                      #
# Used to query a SQL database given a connection string and a sql query and                            #
# write the query output to a CSV file.                                                                 #
#                                                                                                       #
# Intended to be used for CMDB Queries but can be used for any database                                 #
# if given a valid connection string file and sql query file.                                           #
#                                                                                                       #
# -Verbose switch can be used to display information at runtime (default is silent)                     #
#                                                                                                       #
# Has 3 required parameters and 3 optional parameters:                                                  #
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
#   - setglobal : Optional (can be shortened to s)                                                      #
#     Optional flag that, if set, will export information in global variables for use by parent script  #
#                                                                                                       #
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
        [Parameter(Mandatory=$true,
        HelpMessage="A mode is required")]
        [ValidateSet("query")]
        [string]$mode,
        
        [Parameter(Mandatory=$true,
        HelpMessage="The name of an existing connection string file is required")]
        #[ValidateScript({Test-Path $_ -PathType leaf})]
        [string]$connfile,
        
        [Parameter(Mandatory=$true,
        HelpMessage="The name of an existing SQL query file is required")]
        #[ValidateScript({Test-Path $_ -PathType leaf})]
        [string]$queryfile,
        
        [Parameter(Mandatory=$true,
        HelpMessage="The name of the output file is required")]
        [ValidateScript({Test-Path $_ -PathType leaf})]
        [string]$outputfile,
        
        [Parameter(Mandatory=$false,
        HelpMessage="Query Path should be in format 'C:\...\' or '\\...\...\'. Default (if not supplied) is current path '.\'")]
        [ValidateScript({Test-Path $_ -PathType container})]
        [string]$pathq,

        [Parameter(Mandatory=$false,
        HelpMessage="Output Path should be in format 'C:\...\' or '\\...\...\'. Default (if not supplied) is current path '.\'")]
        [ValidateScript({Test-Path $_ -PathType container})]
        [string]$pathout
    )

Function CMDB-Query{
    #Check if query path was supplied, if not, set it to current path
    If ($pathq)
        {write-verbose "Query Path supplied: $pathq"}
        else
        {write-verbose "Query Path not supplied, using current path"
         $pathq = ".\"}

    #Check if query path has a backslash as the right-most character, if not add one
    # (for joining path and filename together)        
    If ($pathq.substring($pathq.length - 1,1) -ne "\")
        {$pathq=($pathq + "\")}

    #Check if output path was supplied, if not, set it to current path    
    If ($pathout)
        {write-verbose "Output Path supplied: $pathout"}
        else
        {write-verbose "Output Path not supplied, using current path"
         $pathout = ".\"}    

    #Check if output path has a backslash as the right-most character, if not add one
    # (for joining path and filename together)        
    If ($pathout.substring($pathout.length - 1,1) -ne "\")
        {$pathout=($pathout + "\")}  

    #Setup SQL connection object using .NET       
    $connection = New-Object -TypeName System.Data.SqlClient.SqlConnection
    
    #Get connection string from connection file
    $connString = gc ($pathq + $connfile)
    
    #Get SQL query from queryfile
    $query = gc ($pathq + $queryfile)
    
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
}
If ($mode -eq "query")
    {CMDB-Query -c $connfile -q $queryfile -output $outputfile -v}
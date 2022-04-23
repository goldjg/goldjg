############################
##### Get Docs from DB #####
############################

    #Setup SQL connection object using .NET       
    $connection = New-Object -TypeName System.Data.OleDb.OleDbConnection

    #set connection string
    $connString = "Provider=Microsoft.Jet.OLEDB.4.0; Data Source=K:\MCP_17_0.mdb"

    #Set SQL query
    $query = "SELECT * FROM [Document Information] ;"

    #Set ConnectionString property of SQL object
    $connection.ConnectionString = $connString

    #Create new SQL command
    $command = $connection.CreateCommand()

    #Populate CommandText property using query read in from file
    $command.CommandText = $query

    #Invoke SQL command using SQL Data Adapter (.NET object)
    $adapter = New-Object -TypeName System.Data.OleDb.OleDbDataAdapter $command

    #Setup DataSet object to handle the SQL output/response
    $dataset = New-Object -TypeName System.Data.DataSet

    #Fill the dataset with the SQL response. Using [void] redirects console output to null (don't display)
    [void]$adapter.Fill($dataset)

    $docs = $dataset.Tables[0]|Select "Part Number", "Part Number Suffix", "Published Title", "Published File Name", "PDF"
    
    rv adapter,dataset

############################
##### Get Cats from DB #####
############################

    #Setup SQL connection object using .NET       
    $connection = New-Object -TypeName System.Data.OleDb.OleDbConnection

    #set connection string
    $connString = "Provider=Microsoft.Jet.OLEDB.4.0; Data Source=K:\MCP_15_0.mdb"

    #Set SQL query
    $query = "SELECT * FROM [Category Information] ;"

    #Set ConnectionString property of SQL object
    $connection.ConnectionString = $connString

    #Create new SQL command
    $command = $connection.CreateCommand()

    #Populate CommandText property using query read in from file
    $command.CommandText = $query

    #Invoke SQL command using SQL Data Adapter (.NET object)
    $adapter = New-Object -TypeName System.Data.OleDb.OleDbDataAdapter $command

    #Setup DataSet object to handle the SQL output/response
    $dataset = New-Object -TypeName System.Data.DataSet

    #Fill the dataset with the SQL response. Using [void] redirects console output to null (don't display)
    [void]$adapter.Fill($dataset)
        
    $cats = $dataset.Tables[0]|Select Key, Category

    rv adapter,dataset

#############################
##### Get Index from DB #####
#############################

    #Setup SQL connection object using .NET       
    $connection = New-Object -TypeName System.Data.OleDb.OleDbConnection

    #set connection string
    $connString = "Provider=Microsoft.Jet.OLEDB.4.0; Data Source=K:\MCP_17_0.mdb"

    #Set SQL query
    $query = "SELECT * FROM [Document By Category] ;"

    #Set ConnectionString property of SQL object
    $connection.ConnectionString = $connString

    #Create new SQL command
    $command = $connection.CreateCommand()

    #Populate CommandText property using query read in from file
    $command.CommandText = $query

    #Invoke SQL command using SQL Data Adapter (.NET object)
    $adapter = New-Object -TypeName System.Data.OleDb.OleDbDataAdapter $command

    #Setup DataSet object to handle the SQL output/response
    $dataset = New-Object -TypeName System.Data.DataSet

    #Fill the dataset with the SQL response. Using [void] redirects console output to null (don't display)
    [void]$adapter.Fill($dataset)
        
    $DocsByCat = $dataset.Tables[0]|Select Key, "Part Number", "Part Number Suffix" 

###########################
##### Build new index #####
###########################
    $index = @()
    
    foreach ($document in $docs){
    
    If ($document.PDF -eq 0) {$doctype = "CHM"} else {$doctype = "PDF"}
    $path = ($doctype + "\" + $document."Published File Name")
    $title = $document."Published Title"
    If ($document.PDF -eq 0) {$texttype = "CHM (HtmlHelp)"} else {$texttype = "PDF"}
    $Pnum = $document."Part Number"
    $PSfx = $document."Part Number Suffix"
    $CurrDocKey = $DocsByCat| where {(($_."Part Number" -eq $PNum) -and ($_."Part Number Suffix" -eq $PSfx))}
    $Key = $Key = ($CurrDocKey|Select -First 1).Key    
    $CurrDocCat = $cats| where {($_.Key -eq $Key)}
    $category = $CurrDocCat.Category
            
    $obj = $null
    $obj = New-Object System.Object
    $obj | Add-Member -type NoteProperty -Name Title -Value ('<a target="_blank" href="file:///' + $path + '">' + $title + '</a>')
    $obj | Add-Member -type NoteProperty -Name Category -Value $category
    $obj | Add-Member -type NoteProperty -Name Type -Value $texttype            
    $title = $null
    $category = $null
    $path = $null
    $texttype = $null
    $key = $null
    $Pnum = $null
    $PSfx = $null
    $doctype = $null
    $index += $obj
    }
    
    #$index|ogv
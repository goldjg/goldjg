#Requires -version 2.0
##
##  Author Richard Siddaway
##    Version 0.1 - Inital Release  December 2009
##
## Connection functions
##
function Open-AccessDatabase {
param (
    [string]$name,
    [string]$path
)     
    $file = Join-Path -Path $path -ChildPath $name 
    if (!(Test-Path $file)){Throw "File Does Not Exists"}

    $connection = New-Object System.Data.OleDb.OleDbConnection("Provider=Microsoft.ACE.OLEDB.12.0; Data Source=$file")
    $connection.Open()
    $connection
}

function Close-AccessDatabase {
param (
    [System.Data.OleDb.OleDbConnection]$connection
)
    $connection.Close()    
}

function Test-AccessConnection {
param (
    [System.Data.OleDb.OleDbConnection]$connection
)   
    if ($connection.State -eq "Open"){$open = $true}
    else {$open = $false}
    $open    
}
##
## data definition functions
##
function New-AccessDatabase {
param (
    [string]$name,
    [string]$path,
    [switch]$acc3
)    

    if (!(Test-Path $path)){Throw "Invalid Folder"}
    $file = Join-Path -Path $path -ChildPath $name 
    if (Test-Path $file){Throw "File Already Exists"}
    
    $cat = New-Object -ComObject 'ADOX.Catalog'
    
    if ($acc3) {$cat.Create("Provider=Microsoft.Jet.OLEDB.4.0; Data Source=$file")}
    else {$cat.Create("Provider=Microsoft.ACE.OLEDB.12.0; Data Source=$file")}

    $cat.ActiveConnection.Close()
}
##
## Tables
##
function New-AccessTable {
## assumes database is open
## add code to check if table exists
param (
    [string]$table,
    [System.Data.OleDb.OleDbConnection]$connection
)
    $sql = " CREATE TABLE $table"
    $cmd = New-Object System.Data.OleDb.OleDbCommand($sql, $connection)
    $cmd.ExecuteNonQuery()
}

function Remove-AccessTable {
[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [string]$table,
    [System.Data.OleDb.OleDbConnection]$connection
)
    $sql = "DROP TABLE $table "
    $cmd = New-Object System.Data.OleDb.OleDbCommand($sql, $connection)
    
    if ($psCmdlet.ShouldProcess("$($connection.DataSource)", "$sql")){$cmd.ExecuteNonQuery()}
}

##
## Columns
##
function New-AccessColumn {
[CmdletBinding()]
param (
    [System.Data.OleDb.OleDbConnection]$connection,
    [string]$table,
    [switch]$notnull,

    [parameter(ParameterSetName="datetime")]  
    [string]$dtname,

    [parameter(ParameterSetName="unique")]  
    [string]$uniquename,

    [parameter(ParameterSetName="binary")]  
    [string]$binname,

    [parameter(ParameterSetName="bit")]  
    [string]$bitname,

    [parameter(ParameterSetName="tinyinteger")]  
    [string]$tnyintname,

    [parameter(ParameterSetName="smallinteger")]  
    [string]$smlintname,
   
    [parameter(ParameterSetName="integer")]  
    [string]$intname,


    [parameter(ParameterSetName="double")]   
    [string]$dblname,

    [parameter(ParameterSetName="real")]  
    [string]$realname,

    [parameter(ParameterSetName="float")]  
    [string]$floatname,
    
    [parameter(ParameterSetName="decimal")]  
    [string]$decname,
    
    [parameter(ParameterSetName="money")]  
    [string]$mnyname,
    
    [parameter(ParameterSetName="char")]  
    [string]$charname,
    
    [parameter(ParameterSetName="text")]  
    [string]$textname,

    [parameter(ParameterSetName="image")]  
    [string]$imgname,
    
    [parameter(ParameterSetName="char")]
    [parameter(ParameterSetName="text")] 
    [int]$size = 10
)    
    switch ($psCmdlet.ParameterSetName){
        datetime     {$sql = "ALTER TABLE $table ADD COLUMN $dtname DATETIME" } 

        binary       {$sql = "ALTER TABLE $table ADD COLUMN $binname BINARY" } 
        bit          {$sql = "ALTER TABLE $table ADD COLUMN $bitname BIT" } 
        
        unique       {$sql = "ALTER TABLE $table ADD COLUMN $uniquename UNIQUEIDENTIFIER" } 

        tinyinteger  {$sql = "ALTER TABLE $table ADD COLUMN $tnyintname TINYINT" } 
        smallinteger {$sql = "ALTER TABLE $table ADD COLUMN $smlintname SMALLINT" } 
        integer      {$sql = "ALTER TABLE $table ADD COLUMN $intname INTEGER" } 

        double       {$sql = "ALTER TABLE $table ADD COLUMN $dblname DOUBLE" } 
        float        {$sql = "ALTER TABLE $table ADD COLUMN $floatname FLOAT" } 
        real         {$sql = "ALTER TABLE $table ADD COLUMN $realname REAL" } 
        decimal      {$sql = "ALTER TABLE $table ADD COLUMN $decname DECIMAL" } 
        money        {$sql = "ALTER TABLE $table ADD COLUMN $mnyname MONEY" } 
        
        char         {$sql = "ALTER TABLE $table ADD COLUMN $charname CHARACTER($size)" }
        text         {$sql = "ALTER TABLE $table ADD COLUMN $textname TEXT($size)" }
        image        {$sql = "ALTER TABLE $table ADD COLUMN $imgname IMAGE" }                 
                
    }
    if ($notnull) {$sql = $sql + " NOT NULL"}
    
    Write-Debug $sql
    $cmd = New-Object System.Data.OleDb.OleDbCommand($sql, $connection)
    $cmd.ExecuteNonQuery()
}

function Add-TablePrimaryKey {
[CmdletBinding()]
param (
    [System.Data.OleDb.OleDbConnection]$connection,
    [string]$table,
    [string]$keyfield

)    
    $sql = "ALTER TABLE $table ADD PRIMARY KEY $keyfield"
    
    Write-Debug $sql
    $cmd = New-Object System.Data.OleDb.OleDbCommand($sql, $connection)
    $cmd.ExecuteNonQuery()
}

function Remove-AccessColumn {
[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [string]$table,
    [string]$column,
    [System.Data.OleDb.OleDbConnection]$connection
)
    $sql = "ALTER TABLE $table DROP COLUMN $column"
    $cmd = New-Object System.Data.OleDb.OleDbCommand($sql, $connection)
    
    if ($psCmdlet.ShouldProcess("$($connection.DataSource)", "$sql")){$cmd.ExecuteNonQuery()}
}

##
##  Data manipulation functions
##
function Add-AccessRecord {
[CmdletBinding()]
param (
    [parameter(ParameterSetName="sql")]
    [string]$sql,
    
    [System.Data.OleDb.OleDbConnection]$connection,
    
    [parameter(ParameterSetName="value")]
    [string]$table,
    
    [parameter(ParameterSetName="value")]
    [string]$values
)
    if($psCmdlet.ParameterSetName -eq "value"){
        $sql = "INSERT INTO $table VALUES ($values)"
    }
    
    $cmd = New-Object System.Data.OleDb.OleDbCommand($sql, $connection)
    $cmd.ExecuteNonQuery()
}

function Get-AccessData {
param (
    [string]$sql,
    [System.Data.OleDb.OleDbConnection]$connection,
    [switch]$grid
)
    
    $cmd = New-Object System.Data.OleDb.OleDbCommand($sql, $connection)
    $reader = $cmd.ExecuteReader()
    
    $dt = New-Object System.Data.DataTable
    $dt.Load($reader)
    
    if ($grid) {$dt | Out-GridView -Title "$sql" }
    else {$dt}

}

function Remove-AccessData {
[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [string]$table,
    [string]$filter,
    [System.Data.OleDb.OleDbConnection]$connection
)
    $sql = "DELETE FROM $table WHERE $filter"
    $cmd = New-Object System.Data.OleDb.OleDbCommand($sql, $connection)
    
    if ($psCmdlet.ShouldProcess("$($connection.DataSource)", "$sql")){$cmd.ExecuteNonQuery()}
}

function Set-AccessData {
[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [string]$table,
    [string]$filter,
    [string]$value,
    [System.Data.OleDb.OleDbConnection]$connection
)
    $sql = "UPDATE $table SET $value WHERE $filter"
    $cmd = New-Object System.Data.OleDb.OleDbCommand($sql, $connection)
    
    if ($psCmdlet.ShouldProcess("$($connection.DataSource)", "$sql")){$cmd.ExecuteNonQuery()}
}
[String]$dbname = "ADA_TESTDB";

# Open ADO.NET Connection with Windows authentification to local SQLEXPRESS.
$con = New-Object Data.SqlClient.SqlConnection;
$con.ConnectionString = "Data Source=.\SQLEXPRESS2;Initial Catalog=master;Integrated Security=True;";
$con.Open();

# Select-Statement for AD group logins
$sql = "SELECT name
        FROM sys.databases
        WHERE name = '$dbname';";

# New command and reader.
$cmd = New-Object Data.SqlClient.SqlCommand $sql, $con;
$rd = $cmd.ExecuteReader();
if ($rd.Read())
{	
	Write-Host "Database $dbname already exists";
	Return;
}

$rd.Close();
$rd.Dispose();

# Create the database.
$sql = "CREATE DATABASE [$dbname];"
$cmd = New-Object Data.SqlClient.SqlCommand $sql, $con;
$cmd.ExecuteNonQuery();		
Write-Host "Database $dbname is created!";


# Close & Clear all objects.
$cmd.Dispose();
$con.Close();
$con.Dispose();
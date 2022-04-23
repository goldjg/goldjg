[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null

$serverName = "localhost"

$server = new-object ('Microsoft.SqlServer.Management.Smo.Server') $serverName

$server.ConnectionContext.LoginSecure=$false;
$credential = Get-Credential
$loginName = $credential.UserName -replace("\\","")
$server.ConnectionContext.set_Login($loginName);
$server.ConnectionContext.set_SecurePassword($credential.Password)
$server.ConnectionContext.ApplicationName="SQLDeploymentScript"

#Create a new database
$db = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database -argumentlist $server, "Test_SMO_Database"
$db.Create()

#Reference the database and display the date when it was created. 
$db = $server.Databases["Test_SMO_Database"]
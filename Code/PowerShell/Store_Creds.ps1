# Store Credentials
$Server = Read-Host("Enter Server Name");
$User = Read-Host("Enter Username e.g PRODUCTION\ABC123");
$Password = Read-Host("Enter Password");
$cmd = ("cmdkey /generic:TERMSRV/" + $Server + " /user:" + $User + " /pass:" + $Password);
	invoke-expression -command $cmd;
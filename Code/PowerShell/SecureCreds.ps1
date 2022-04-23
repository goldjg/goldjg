$UserName = "DOM\usr"
$SecurePassword = Read-Host -Prompt "Enter password" -AsSecureString  

$key = (221,3,25,46,175,1,1,5,96,31,3,4,2,3,56,34,254,222,1,1,2,23,42,54,33,233,1,34,2,7,6,5)

$SecStringPass = ConvertFrom-SecureString $SecurePassword -key $key

$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $UserName, $SecurePassword

$cmd = ("cmdkey /add:TERMSRV/##REDACTED## /user:" + $Username + " /pass:" + $SecurePassword);
	invoke-expression -command $cmd;

$PlainPassword = $Credentials.GetNetworkCredential().Password
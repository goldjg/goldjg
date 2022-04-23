$mesrv = (Get-WmiObject Win32_ComputerSystem).Name;
$medom = (gwmi -class win32_computerSystem).Username.split("\")[0];
$meusr = (gwmi -class win32_computerSystem).Username.split("\")[1];
$sid = ([wmi]("win32_UserAccount.Domain='" + $medom + "',Name='" + $meusr + "'")).sid
[double]$salt = ($sid.Replace("-","").Replace("S","") * ($mesrv.length/2))
clear-item variable:sid -force

#create key
    
[string]$rstring=(($salt.ToString().Split("E")[0]) + $mesrv);
$rlength = $rstring.length;
$rpad = 32-$rlength;
if (($rlength -lt 16) -or ($rlength -gt 32)) {Throw "String must be between 16 and 32 characters"};
$rencoding = New-Object System.Text.ASCIIEncoding;
$rkey = $rencoding.GetBytes($rstring + "0" * $rpad);

$infile = [Io.File]::ReadAllText("\\##REDACTED##\enctest.txt");
$sectext = ConvertTo-SecureString $infile -asplaintext -force;
$enctext = ConvertFrom-SecureString $sectext -key $rkey;

$enctext|out-file \\##REDACTED##\file.enc;

#sleep 5;
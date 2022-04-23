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

[string]$infile = gc \\##REDACTED##\file.enc;
$plntxt=[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR((`
    ConvertTo-SecureString $infile -key $rkey)));

$plntxt|out-file \\##REDACTED##\file.dec;

#sleep 5;
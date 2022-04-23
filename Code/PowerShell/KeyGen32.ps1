$mesrv = (Get-WmiObject Win32_ComputerSystem).Name;
$medom = (Get-WmiObject Win32_LoggedOnUser -computername localhost|`
            select Antecedent -first 1).Antecedent.split(".")[2].split(",")[0].split('"')[1];
$meusr = (Get-WmiObject Win32_LoggedOnUser -computername localhost|`
            select Antecedent -first 1).Antecedent.split(".")[2].split(",")[1].split('"')[1];
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

#    [string]$string=((Get-WmiObject Win32_LoggedOnUser -computername localhost|select __SERVER -first 1).__SERVER`
#            + (get-item env:businessunit).value)`
#            + (Get-WmiObject Win32_LoggedOnUser -computername localhost|`
#                select Antecedent -first 1).Antecedent.split(".")[2].split(",")[1].split('"')[1]`
#            + (get-item env:os).value.split("_")[0];$length = $string.length
#$pad = 32-$length
#if (($length -lt 16) -or ($length -gt 32)) {Throw "String must be between 16 and 32 characters"}
#$encoding = New-Object System.Text.ASCIIEncoding
#$bytes = $encoding.GetBytes($string + "0" * $pad)
#return $bytes
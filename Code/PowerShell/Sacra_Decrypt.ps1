$encrypted = Import-Clixml 'K:\Sacra.xml'            

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
$key = $rencoding.GetBytes($rstring + "0" * $rpad);          

$csp = New-Object System.Security.Cryptography.CspParameters
$csp.KeyContainerName = "Sacra"
$csp.Flags = $csp.Flags -bor [System.Security.Cryptography.CspProviderFlags]::UseMachineKeyStore
$rsa = New-Object System.Security.Cryptography.RSACryptoServiceProvider -ArgumentList 5120,$csp
$rsa.PersistKeyInCsp = $true            

$secpass = [char[]]$rsa.Decrypt($encrypted, $true) -join "" |ConvertTo-SecureString -Key $key

#decrypt the password - will fail if incorrect key (need to add error handling, currently bombs out entire script
$plain=[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($secpass)));      
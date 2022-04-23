$Server = Read-Host("Enter Server Name");

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

    #forcibly remove variables used in key generation and their contents
    clear-item variable:rstring -force;
    clear-item variable:rpad -force;
    clear-item variable:rlength -force;
    clear-item variable:rencoding -force;

                
clear-item variable:sstring -force;
clear-item variable:spad -force;
clear-item variable:slength -force;
clear-item variable:sencoding -force;

$Cred = Get-Credential;

$Dom = $Cred.username.split("\")[0];
$User = $Cred.username.split("\")[1];
$SecPss = ConvertFrom-SecureString $Cred.password -key $rkey;

clear-item variable:skey -force;
clear-item variable:Cred -force;

$line = ($Server + "," + $Dom + "," + $User + "," + $SecPss);

clear-item variable:Server -force;
clear-item variable:Dom -force;
clear-item variable:User -force;
clear-item variable:SecPss -force;

return $line
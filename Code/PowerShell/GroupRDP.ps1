#get rdp group list
$servers = get-content \\##REDACTED##\RDP_Group.txt
$mesrv = (Get-WmiObject Win32_ComputerSystem).Name;
$medom = (gwmi -class win32_computerSystem).Username.split("\")[0];
$meusr = (gwmi -class win32_computerSystem).Username.split("\")[1];
$sid = ([wmi]("win32_UserAccount.Domain='" + $medom + "',Name='" + $meusr + "'")).sid
[double]$salt = ($sid.Replace("-","").Replace("S","") * ($mesrv.length/2))
clear-item variable:sid -force

#for each line in the list, process it...
foreach ($line in $servers) {
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
    
    #split the line into server, domain, user and encrypted password
    $rsrv=$line.split(",")[0];
    $rdom=$line.split(",")[1];
    $rusr=$line.split(",")[2];
    $rencpss=$line.split(",")[3];
    clear-item variable:line -force; #forcibly remove the variable storing line you read in now that it's processed
    
    #decrypt the password - will fail if incorrect key (need to add error handling, currently bombs out entire script
    $rpss=[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR((`
    ConvertTo-SecureString $rencpss -key $rkey)));
    
    #forcibly remove the key variable and encrypted password variable and their contents
    clear-item variable:rkey -force;
    clear-item variable:rencpss -force;
    
    #generate credential for this server/user in windows credentials store
    $cmd = ("cmdkey /generic:TERMSRV/" + $rsrv + " /user:" + $rdom + "\" + $rusr + " /pass:" + $rpss);
    clear-item variable:rpss -force;
	invoke-expression -command $cmd|out-null;
    clear-item variable:cmd -force;
    
    #launch RDP session to server
    mstsc /v:$rsrv /w:1024 /h:768;
    
    #wait 2 seconds to allow mstsc to launch, then delete credential from store (may need to beef up to handle network issues
    sleep 2;
    invoke-expression -command ("cmdkey /delete:TERMSRV/" + $rsrv)|out-null;
    
    #forcible remove server/domain/user variables and contents
    clear-item variable:rsrv -force;
    clear-item variable:rdom -force;
    clear-item variable:rusr -force;
    }

#forcibly remove remaining variables and contents before finishing.#
clear-item variable:servers -force

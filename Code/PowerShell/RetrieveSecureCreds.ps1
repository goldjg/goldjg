[string]$rstring=((get-item env:computername).value + (get-item env:businessunit).value`
                + (get-item env:username).value + (get-item env:os).value.split("_")[0]);
                
$rlength = $rstring.length;
$rpad = 32-$rlength;
if (($rlength -lt 16) -or ($rlength -gt 32)) {Throw "String must be between 16 and 32 characters"};
$rencoding = New-Object System.Text.ASCIIEncoding;
$rkey = $rencoding.GetBytes($rstring + "0" * $rpad);

remove-variable rstring -force;
remove-variable rpad -force;
remove-variable rlength -force;
remove-variable rencoding -force;

$line="SERVER,DOM,usr,76492d1116743f0423413b16050a5345MgB8AGYAWQA2AGsAcwA2AHEANgBOAGsAUQBFAE4AVgBIAFQAWABSAEoAdQBGAGcAP
QA9AHwAZQA5ADYANQAzADkAYgA4ADYANwBmADEAYQBiADMAMgAxADMAZgA5ADQAMgA4ADgAMABlAGMANQA5ADkAYQBlADQANQA5AGMAMQA0ADEANgBjADAAMwAxAGIA
MQBmADkAMgA3AGIAOQA5ADEAOAAyAGQANABiADIAYQA4AGIAYwA="

#$rserver=$line.split(",")[0];
#$rdomain=$line.split(",")[1];
#$rusername=$line.split(",")[2];
$rencpass=$line.split(",")[3];

$rplnpss=[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR((`
    ConvertTo-SecureString $rencpass -key $rkey)));
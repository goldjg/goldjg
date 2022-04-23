$filein=(gc .\Input_RDC\RDC_17Sep.txt | Select -skip 4);
$fix1=[Regex]::Replace($filein,'PC File Name','SERVERDIR');
write-host "Fix1 Complete:" (get-date -uformat %c);

$fix2=[Regex]::Replace($fix1,'Host Name','HOST');
write-host "Fix2 Complete:" (get-date -uformat %c);

$fix3=[Regex]::Replace($fix2,'Logical Pages','LOGICAL');
write-host "Fix3 Complete:" (get-date -uformat %c);

$fix4=[Regex]::Replace($fix3,'Physical Pages','PHYSICAL');
write-host "Fix4 Complete:" (get-date -uformat %c);

$fix5=[Regex]::Replace($fix4,'User Id','USER');
write-host "Fix5 Complete:" (get-date -uformat %c);

$fix6=[Regex]::Replace($fix5,'Run Id','MIXNO');
write-host "Fix6 Complete:" (get-date -uformat %c);

$fix7=[Regex]::Replace($fix6,'Banner Id','BANNER');
write-host "Fix7 Complete:" (get-date -uformat %c);

$fix8=[Regex]::Replace($fix7,'Bytes Printed','SIZE');
write-host "Fix8 Complete:" (get-date -uformat %c);

$fix9=[Regex]::Replace($fix8,'Page Range:','');
write-host "Fix9 Complete:" (get-date -uformat %c);

$fix10=[Regex]::Replace($fix9,'Host Project:','');
write-host "Fix10 Complete:" (get-date -uformat %c);

$fix11=[Regex]::Replace($fix10,'E:\\##REDACTED##\\queues\\','');
write-host "Fix11 Complete:" (get-date -uformat %c);

$fix11a=[Regex]::Replace($fix11,'E:\\##REDACTED##\queues\\','');
write-host "Fix11a Complete:" (get-date -uformat %c);

$fix12=[Regex]::Replace($fix11a,'\\\S+','');
write-host "Fix12 Complete:" (get-date -uformat %c);

$pass1=[Regex]::Replace($fix12,'(?<=:)\s+','='); #convert colons to equals
write-host "Format Pass 1 Complete:" (get-date -uformat %c);

$pass2=[Regex]::Replace($pass1,'\s{1}(?=\s)' ,''); #remove spaces in attribute names
write-host "Format Pass 2 Complete:" (get-date -uformat %c);

$pass3=[Regex]::Replace($pass2,'\s(?=\d+)' ,'_');
write-host "Format Pass 3 Complete:" (get-date -uformat %c);

$pass4=[Regex]::Replace($pass3,'\s+(?=\D+)' ,'^')| % {$_.split("^")}|? {$_ -match ":="};
write-host "Format Pass 4 Complete:" (get-date -uformat %c);

$pass5=[Regex]::Replace($pass4,":=","=")|% {$_.split(" ")}|
    ? {$_ -notmatch "Bytes="}|
    ? {$_ -notmatch "Level="}|
    ? {$_ -notmatch "Type="}|
    ? {$_ -notmatch "Number="}|
    ? {$_ -notmatch "Duration="}|
    ? {$_ -notmatch "File="}|
    ? {$_ -notmatch "Alias="}|
    ? {$_ -notmatch "Attribute="}|
    ? {$_ -notmatch "Name="}|
    ? {$_ -notmatch "Date="}|
    ? {$_ -notmatch "Time="}|out-file .\Output_RDC\Out_RDC_17Sep.txt;
write-host "Format Pass 5 Complete:" (get-date -uformat %c);

#gc testout.txt |% {$_.split("`t") |% {$r = new-object object} {$r | add-Member -memberType noteProperty -Name $_.split('=')[0] -Value $_.split('=')[1]}{$r}}
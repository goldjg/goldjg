write-host "Loading Input File:" (get-date -uformat %c);
$filein=(gc LGEXEDSRV06##REDACTED##_TransfComp_Sep2012.txt | Select -skip 4);
$fix1=[Regex]::Replace($filein,'UTC:',',');
write-host "Fix1 Complete:" (get-date -uformat %c);

$fix2=[Regex]::Replace($fix1,'Log Type:',',');
write-host "Fix2 Complete:" (get-date -uformat %c);

$fix3=[Regex]::Replace($fix2,'Level:',',');
write-host "Fix3 Complete:" (get-date -uformat %c);

$fix4=[Regex]::Replace($fix3,'Bytes:',',');
write-host "Fix4 Complete:" (get-date -uformat %c);

$fix5=[Regex]::Replace($fix4,'Transfer Id:',',');
write-host "Fix5 Complete:" (get-date -uformat %c);

$fix6=[Regex]::Replace($fix5,'Bytes Transferred:',',');
write-host "Fix6 Complete:" (get-date -uformat %c);

$fix7=[Regex]::Replace($fix6,'Completion Type:',',');
write-host "Fix7 Complete:" (get-date -uformat %c);

$fix8=[Regex]::Replace($fix7,'Start Date/Time:',',');
write-host "Fix8 Complete:" (get-date -uformat %c);

$fix9=[Regex]::Replace($fix8,'Duration:',',');
write-host "Fix9 Complete:" (get-date -uformat %c);

$fix10=[Regex]::Replace($fix9,'Path Name:',',');
write-host "Fix10 Complete:" (get-date -uformat %c);

$fix11=[Regex]::Replace($fix10,'Maximum Message Size:',',');
write-host "Fix11 Complete:" (get-date -uformat %c);

$fix12=[Regex]::Replace($fix11,'Transfer Operation:',',');
write-host "Fix12 Complete:" (get-date -uformat %c);

$fix13=[Regex]::Replace($fix12,'Receive	Peer Type:',',');
write-host "Fix13 Complete:" (get-date -uformat %c);

$fix14=[Regex]::Replace($fix13,'Peer Name:',',');
write-host "Fix14 Complete:" (get-date -uformat %c);

$fix15=[Regex]::Replace($fix14,'Host Qualifier:',',');
write-host "Fix15 Complete:" (get-date -uformat %c);

$fix16=[Regex]::Replace($fix15,'Host File Name:',',');
write-host "Fix16 Complete:" (get-date -uformat %c);

$fix17=[Regex]::Replace($fix16,'Host Queue:',',');
write-host "Fix17 Complete:" (get-date -uformat %c);

$fix18=[Regex]::Replace($fix17,'File Name:',',');
write-host "Fix18 Complete:" (get-date -uformat %c);

$fix19=[Regex]::Replace($fix18,'File Type:',',');
write-host "Fix19 Complete:" (get-date -uformat %c);

$fix20=[Regex]::Replace($fix19,'File Date:',',');
write-host "Fix20 Complete:" (get-date -uformat %c);

$fix21=[Regex]::Replace($fix20,'File Time:',',');
write-host "Fix21 Complete:" (get-date -uformat %c);

$fix22=[Regex]::Replace($fix21,'User Id:',',');
write-host "Fix22 Complete:" (get-date -uformat %c);

$fix23=[Regex]::Replace($fix22,'Run Id:',',');
write-host "Fix23 Complete:" (get-date -uformat %c);

$fix24=[Regex]::Replace($fix23,'Account:',',');
write-host "Fix24 Complete:" (get-date -uformat %c);

$fix25=[Regex]::Replace($fix24,'Project:',',');
write-host "Fix25 Complete:" (get-date -uformat %c);

$fix26=[Regex]::Replace($fix25,'Banner Id:',',');
write-host "Fix26 Complete:" (get-date -uformat %c);

$fix27=[Regex]::Replace($fix26,'Job Name:',',');
write-host "Fix27 Complete:" (get-date -uformat %c);

$fix28=[Regex]::Replace($fix27,'Job Classification:',"!");
write-host "Fix28 Complete:" (get-date -uformat %c);

$fix29=[Regex]::Replace($fix28,'(?i)E:\\##REDACTED##\\queues\\','');
write-host "Fix29 Complete:" (get-date -uformat %c);

$fix30=[Regex]::Replace($fix29,'\\\S+','');
write-host "Fix30 Complete:" (get-date -uformat %c);

$fix31=[Regex]::Replace($fix30,'(?<=\d{2}/\d{2}/\d{4})\s{1}',',');
write-host "Fix31 Complete:" (get-date -uformat %c);

$fix32=[Regex]::Replace($fix31,'\s','');
write-host "Fix32 Complete:" (get-date -uformat %c);

$fix33=[Regex]::Replace($fix32,'!',"`n")|% {$_.split("`n")}|? {$_ -match "ficheIBM"}|out-file ##REDACTED##_TransfComp_Sep2012.csv;
write-host "Fix33 Complete, output file written:" (get-date -uformat %c);
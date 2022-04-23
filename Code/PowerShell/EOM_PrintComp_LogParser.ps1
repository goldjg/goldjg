write-host "Loading Input File:" (get-date -uformat %c);
$filein=(gc ##REDACTED##_PrintComp_Sep2012.txt | Select -skip 4);
$fix1=[Regex]::Replace($filein,'UTC:',',');
write-host "Fix1 Complete:" (get-date -uformat %c);

$fix2=[Regex]::Replace($fix1,'Log Type:',',');
write-host "Fix2 Complete:" (get-date -uformat %c);

$fix3=[Regex]::Replace($fix2,'Level:',',');
write-host "Fix3 Complete:" (get-date -uformat %c);

$fix4=[Regex]::Replace($fix3,'Bytes:',',');
write-host "Fix4 Complete:" (get-date -uformat %c);

$fix5=[Regex]::Replace($fix4,'File Number:',',');
write-host "Fix5 Complete:" (get-date -uformat %c);

$fix6=[Regex]::Replace($fix5,'PC File Name:',',');
write-host "Fix6 Complete:" (get-date -uformat %c);

$fix7=[Regex]::Replace($fix6,'Printer Name:',',');
write-host "Fix7 Complete:" (get-date -uformat %c);

$fix8=[Regex]::Replace($fix7,'Completion Type:',',');
write-host "Fix8 Complete:" (get-date -uformat %c);

$fix9=[Regex]::Replace($fix8,'Start Date/Time:',',');
write-host "Fix9 Complete:" (get-date -uformat %c);

$fix10=[Regex]::Replace($fix9,'Duration:',',');
write-host "Fix10 Complete:" (get-date -uformat %c);

$fix11=[Regex]::Replace($fix10,'Paper Type:',',');
write-host "Fix11 Complete:" (get-date -uformat %c);

$fix12=[Regex]::Replace($fix11,'Logical Pages:',',');
write-host "Fix12 Complete:" (get-date -uformat %c);

$fix13=[Regex]::Replace($fix12,'Physical Pages:',',');
write-host "Fix13 Complete:" (get-date -uformat %c);

$fix14=[Regex]::Replace($fix13,'Bytes Printed:',',');
write-host "Fix14 Complete:" (get-date -uformat %c);

$fix15=[Regex]::Replace($fix14,'Print Attribute:',',');
write-host "Fix15 Complete:" (get-date -uformat %c);

$fix16=[Regex]::Replace($fix15,'Page Range:',',');
write-host "Fix16 Complete:" (get-date -uformat %c);

$fix17=[Regex]::Replace($fix16,'User Id:',',');
write-host "Fix17 Complete:" (get-date -uformat %c);

$fix18=[Regex]::Replace($fix17,'Run Id:',',');
write-host "Fix18 Complete:" (get-date -uformat %c);

$fix19=[Regex]::Replace($fix18,'Account:',',');
write-host "Fix19 Complete:" (get-date -uformat %c);

$fix20=[Regex]::Replace($fix19,'Host Project:',',');
write-host "Fix20 Complete:" (get-date -uformat %c);

$fix21=[Regex]::Replace($fix20,'Banner Id:',',');
write-host "Fix21 Complete:" (get-date -uformat %c);

$fix22=[Regex]::Replace($fix21,'Host Queue:',',');
write-host "Fix22 Complete:" (get-date -uformat %c);

$fix23=[Regex]::Replace($fix22,'Host Name:',',');
write-host "Fix23 Complete:" (get-date -uformat %c);

$fix24=[Regex]::Replace($fix23,'File Date:',',');
write-host "Fix24 Complete:" (get-date -uformat %c);

$fix25=[Regex]::Replace($fix24,'File Time:',',');
write-host "Fix25 Complete:" (get-date -uformat %c);

$fix26=[Regex]::Replace($fix25,'File Type:',',');
write-host "Fix26 Complete:" (get-date -uformat %c);

$fix27=[Regex]::Replace($fix26,'Emulation Type:',',');
write-host "Fix27 Complete:" (get-date -uformat %c);

$fix28=[Regex]::Replace($fix27,'Mode Directory Alias:',',');
write-host "Fix28 Complete:" (get-date -uformat %c);

$fix29=[Regex]::Replace($fix28,'Mode Command File:',',');
write-host "Fix29 Complete:" (get-date -uformat %c);

$fix30=[Regex]::Replace($fix29,'Init Directory Alias:',',');
write-host "Fix30 Complete:" (get-date -uformat %c);

$fix31=[Regex]::Replace($fix30,'Init Command File:',',');
write-host "Fix31 Complete:" (get-date -uformat %c);

$fix32=[Regex]::Replace($fix31,'Data Directory Alias:',',');
write-host "Fix32 Complete:" (get-date -uformat %c);

$fix33=[Regex]::Replace($fix32,'Data Command File:',',');
write-host "Fix33 Complete:" (get-date -uformat %c);

$fix34=[Regex]::Replace($fix33,'Page Directory Alias:',',');
write-host "Fix34 Complete:" (get-date -uformat %c);

$fix35=[Regex]::Replace($fix34,'Page Command File:',',');
write-host "Fix35 Complete:" (get-date -uformat %c);

$fix36=[Regex]::Replace($fix35,'Term Directory Alias:',',');
write-host "Fix36 Complete:" (get-date -uformat %c);

$fix37=[Regex]::Replace($fix36,'Term Command File:','!');
write-host "Fix37 Complete:" (get-date -uformat %c);

$fix38=[Regex]::Replace($fix37,'(?i)E:\\##REDACTED##\\queues\\','');
write-host "Fix38 Complete:" (get-date -uformat %c);

$fix39=[Regex]::Replace($fix38,'\\\S+','');
write-host "Fix39 Complete:" (get-date -uformat %c);

$fix40=[Regex]::Replace($fix39,'(?<=\d{2}/\d{2}/\d{4})\s{1}',',');
write-host "Fix40 Complete:" (get-date -uformat %c);

$fix41=[Regex]::Replace($fix40,'\s','');
write-host "Fix41 Complete:" (get-date -uformat %c);

$fix42=[Regex]::Replace($fix41,'!',"`n")|% {$_.split("`n")}|out-file ##REDACTED##_PrintComp_Sep2012.csv;
write-host "Fix42 Complete, output file written:" (get-date -uformat %c);
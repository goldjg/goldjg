$rpl_file = gc ("K:\rplall.txt")

#determine what line in file the tables start
[int]$startln = ((select-string -pattern 'Pch Cyl' K:\rplall.txt)[0]).ToString().Split(":")[2]
       
#determine last line in file
[int]$endln = $rpl_file.Length
#$startln--

$Patch_Tbls = (gc K:\rplall.txt)["$startln".."$endln"]
$Patches = $Patch_Tbls -match '^\d+'
$Patches|where-object {($_.Split(" ")[0] -gt 56.114)}
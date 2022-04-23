$file = gc K:\DPF_20_11_13
$1stpass =foreach ($line in $file){
    if (($line -like "*STAMP*") -or ($line -like "*SRC*") -or ($line -like "*PROTOCOL*") -or ($line -like "*NP *") -or ($line -like "*BIT*")){
        ($line -split ',') -replace '  ',''}
       }
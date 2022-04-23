remove-item K:\DEV_EXTRACT_GUARD_ACC_Locum_Input.txt
$ACC_LIST = (gc K:\DEV_EXTRACT_GUARD_ACCS.txt)
Foreach ($record in $ACC_LIST) {If ($record -match '\w' ) {$newfile += "INQUIRE " + $record.TrimEnd() + " IDENTITY`r`n"}}
$newfile|out-file  -Encoding ASCII K:\DEV_EXTRACT_GUARD_ACC_Locum_Input.txt 
rv ACC_LIST,record,newfile
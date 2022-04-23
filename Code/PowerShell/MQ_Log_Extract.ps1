$TransRaw = Select-String K:\MQ_Trans\*.txt -Pattern TC1,TC2,TC3
write-host "Logs Read"
$TransALPHANums = $TransRaw -replace '[^A-Za-z0-9, /:]',''
write-host "Garbage removed"
$table = @()
write-host "table initialised"
($TransALPHANums -replace 'Line','')`
             -replace ",,",","| `
             Select-String -Pattern '\d{2}\/\d{2}\/\d{4}' | Select Line | foreach {
                    $splitpeas = $_ -split ","
                    $obj = $null
                    $obj = New-Object System.Object
                    $obj | Add-Member -type NoteProperty -Name Date -Value $splitpeas[1].Split(" ")[0]
                    $obj | Add-Member -type NoteProperty -Name Time -Value $splitpeas[1].Split(" ")[1]
                    $obj | Add-Member -type NoteProperty -Name Status -Value $splitpeas[2]
                    $obj | Add-Member -type NoteProperty -Name Trancode -Value $splitpeas[5].SubString(0,6)
                    $table += $obj
                    }
"table populated, exporting to CSV"
$table | Select Date,Time,Status,Trancode | Export-Csv -NoTypeInformation -Path K:\MQ_Trans\MQ_18022015.csv
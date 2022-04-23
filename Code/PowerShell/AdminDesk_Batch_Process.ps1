$Input = gc "\\$Env:HomeDataServer\$Env:USERNAME\Locum_Batch_Query_All_Users.out"
$Trimmed = $Input[1..($Input.count-3)]
$ComSep = $Trimmed -replace 'USERCODE ','USERCODE=' -replace ' LASTLOGON',",LASTLOGON" -replace " ,",'' -replace '\+ ',"`r`n" -replace '\+',''
$ary = @()
$ComSep|foreach {
$obj = New-Object System.Object
$_ -split ','|foreach {
    $obj | Add-Member -MemberType NoteProperty -Name $_.ToString().Split("=")[0] -Value $_.ToString().Split("=")[1]
    }
if($obj.COMSCONTROL -ne "0" -or $obj.PU -ne "0" -or $obj.SECADMIN -ne "0" -or $OBJ.SYSTEMUSER -ne "0"){
  $obj | Add-Member -MemberType NoteProperty -Name PRIVILEGEDUSER -Value "Yes"
} else {
    $obj | Add-Member -MemberType NoteProperty -Name PRIVILEGEDUSER -Value "No" 
}    

if($obj.ACCESSCODENEEDED -eq "1"){
  $obj | Add-Member -MemberType NoteProperty -Name GENERICUSER -Value "No" 
} else {
    $obj | Add-Member -MemberType NoteProperty -Name GENERICUSER -Value "Yes" 
}

$ary += $obj
}


$Input2 = (gc "\\$Env:HomeDataServer\$Env:USERNAME\Locum_Batch_Query_All_Users Identity.out") -join '¬'
$ComSep2 = $Input2 -replace " ,",'' -replace '¬USER',"`r`nUSER" -replace '¬',''
$Trimmed2 = $ComSep2 -split "`r`n"
$Trimmed3 = $Trimmed2|select -skip 1
$Trimmed4 = $Trimmed3 -replace '\d+ Usercodes foundProcessing of batch file complete',''

$ary|foreach {
    $_|Add-Member -MemberType NoteProperty -Name IDENTITY -Value ($Trimmed4|Select-string -Pattern $_.USERCODE).Line.Split('"')[1]
}

$ary | sort -Property USERCODE | Export-Csv -NoTypeInformation -Path "\\$Env:HomeDataServer\$Env:USERNAME\Usercodes.csv"
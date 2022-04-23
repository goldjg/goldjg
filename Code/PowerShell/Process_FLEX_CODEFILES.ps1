$Basedir = "\\$Env:HomeDataServer\\$Env:USERNAME"
$Headers = Get-Content -Path "$Basedir\PROD_CODEFILES.TXT"|Select-String -Pattern "USER"|Select -First 1|Select -Property Line
$INP = (Get-Content -Path "$Basedir\PROD_CODEFILES.TXT"|Select-String -Pattern "S.a r.l."," ","CODEVERSION" -NotMatch).Line
$ary = @()

$INP|foreach{
    $obj = $null
    $obj = New-Object System.Object
    $numheaders = ($Headers.Line -split ",").count
    
    for ($i=0;$i -lt $numheaders; $i++) {
        $obj | Add-Member -type NoteProperty -Name $Headers.Line.Split(",")[$i] -Value $_.Split(",")[$i]
        }
    $ary += $obj
}

$ary|Export-Csv -Path "$Basedir\PROD_CODEFILES.CSV" -NoTypeInformation
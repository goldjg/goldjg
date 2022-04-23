$filein="\\##REDACTED##
$xeroxpath="\\##REDACTED##"
$fullfl=gc($filein) -Encoding Default
$headerend=(($fullfl|select-string -Pattern ¨).LineNumber)[0]
$body=$fullfl[$headerend..($fullfl.Length -2)]
$header=$fullfl[0..($headerend-1)]
$opt_start=($header|select-string ``).LineNumber -1
$opt_end=($header|select-string ~).LineNumber -1
If ($opt_start -lt 0 -or $opt_end -lt 0) {
    $opts = @{"MFUSER" = $header[34];"MFCHARGE" = $header[35]}
    $body|out-file ($xeroxpath + "\" + $opts.MFUSER + "\" + ($filein|split-path -Leaf)) -Encoding default
}else{
    $opt_str=$header[$opt_start..$opt_end] -join '' -replace '`','' -replace '~',''
    $opts=$opt_str -replace '\\','\\' -replace "'",'' -replace ',',"`r`n"|ConvertFrom-StringData
    $opts.Add("MFUSER",$header[$opt_start -1])
    $opts.Add("MFCHARGE",$header[$opt_end   +1])
    $mfcharge=$header[$opt_end +1]
    $body|out-file ($opts.PATH + "\" + $opts.FILENAME) -Encoding default
}
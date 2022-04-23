function Convert-ByteArrayToHexString {
################################################################
#.Synopsis
# Returns a hex representation of a System.Byte[] array as
# one or more strings. Hex format can be changed.
#.Parameter ByteArray
# System.Byte[] array of bytes to put into the file. If you
# pipe this array in, you must pipe the [Ref] to the array.
# Also accepts a single Byte object instead of Byte[].
#.Parameter Width
# Number of hex characters per line of output.
#.Parameter Delimiter
# How each pair of hex characters (each byte of input) will be
# delimited from the next pair in the output. The default
# looks like "0x41,0xFF,0xB9" but you could specify "\x" if
# you want the output like "\x41\xFF\xB9" instead. You do
# not have to worry about an extra comma, semicolon, colon
# or tab appearing before each line of output. The default
# value is ",0x".
#.Parameter Prepend
# An optional string you can prepend to each line of hex
# output, perhaps like '$x += ' to paste into another
# script, hence the single quotes.
#.Parameter AddQuotes
# An switch which will enclose each line in double-quotes.
#.Example
# [Byte[]] $x = 0x41,0x42,0x43,0x44
# Convert-ByteArrayToHexString $x
#
# 0x41,0x42,0x43,0x44
#.Example
# [Byte[]] $x = 0x41,0x42,0x43,0x44
# Convert-ByteArrayToHexString $x -width 2 -delimiter "\x" -addquotes
#
# "\x41\x42"
# "\x43\x44"
################################################################
[CmdletBinding()] Param (
 [Parameter(Mandatory = $True, ValueFromPipeline = $True)] [System.Byte[]] $ByteArray, 
 [Parameter()] [Int] $Width = 10, 
 [Parameter()] [String] $Delimiter = ",0x", 
 [Parameter()] [String] $Prepend = "", 
 [Parameter()] [Switch] $AddQuotes
)

if ($Width -lt 1)
 { $Width = 1 }
if ($ByteArray.Length -eq 0)
 { Return }
$FirstDelimiter = $Delimiter -Replace "^[\,\\:\t]",""
$From = 0
$To = $Width - 1
Do
 { 
  $String = [System.BitConverter]::ToString($ByteArray[$From..$To]) 
  $String = $FirstDelimiter + ($String -replace "\-",$Delimiter) 
  if ($AddQuotes)
   { $String = '"' + $String + '"' } 
  if ($Prepend -ne "")
   { $String = $Prepend + $String } 
  $String 
  $From += $Width 
  $To += $Width
 } While ($From -lt $ByteArray.Length)
}


function Convert-HexStringToByteArray {
################################################################
#.Synopsis
# Convert a string of hex data into a System.Byte[] array. An
# array is always returned, even if it contains only one byte.
#.Parameter String
# A string containing hex data in any of a variety of formats,
# including strings like the following, with or without extra
# tabs, spaces, quotes or other non-hex characters:
# 0x41,0x42,0x43,0x44
# \x41\x42\x43\x44
# 41-42-43-44# 41424344
# The string can be piped into the function too.
################################################################
[CmdletBinding()]Param ( [Parameter(Mandatory = $True, ValueFromPipeline = $True)] [String] $String )

#Clean out whitespaces and any other non-hex crud.
$String = $String.ToLower() -replace '[^a-f0-9\\\,x\-\:]',''

#Try to put into canonical colon-delimited format.
$String = $String -replace '0x|\\x|\-|,',':'

#Remove beginning and ending colons, and other detritus.
$String = $String -replace '^:+|:+$|x|\\',''

#Maybe there's nothing left over to convert...
if ($String.Length -eq 0) { ,@() ; return } 

#Split string with or without colon delimiters.
if ($String.Length -eq 1)
 { ,@([System.Convert]::ToByte($String,16)) }
elseif (($String.Length % 2 -eq 0) -and ($String.IndexOf(":") -eq -1))
 { ,@($String -split '([a-f0-9]{2})' | foreach-object { if ($_) {[System.Convert]::ToByte($_,16)}}) }
elseif ($String.IndexOf(":") -ne -1)
 { ,@($String -split ':+' | foreach-object {[System.Convert]::ToByte($_,16)}) }
else{ ,@() }

#The strange ",@(...)" syntax is needed to force the output into an
#array even if there is only one element in the output (or none).
}


#to list available encodings use [System.Text.Encoding]::GetEncodings() 
function A2E{
    param (
        [Parameter(Mandatory=$false)]
        [ValidateScript({Test-Path $_ -PathType leaf})]
        [string]$infile,
        
        [Parameter(Mandatory=$false)]
        [string]$outfile,
        
        [Parameter(Mandatory=$false)]
        [string]$enctype
    )

write-host "`n`nASCII 2 EBCDIC Translation Start"    
write-host "Reading $infile as byte array"
#$Buffer = Get-Content $infile -Encoding byte
$Buffer = [System.IO.File]::ReadAllBytes($infile)

#$hexbuff = Convert-ByteArrayToHexString $Buffer -Width 1 -Delimiter $null

#rv Buffer

#$mappedbuff = (((((((((($hexbuff  -replace "04","1A") -Replace "06","09") -Replace "06","1A") -Replace "05","09") -Replace "5B","4A") -Replace "5D","5A") -Replace "D5","AD") -Replace "E5","BD") -Replace "21","4F") -Replace "7C","6A")

#byte[]]$Buffer = $hexbuff | Convert-HexStringToByteArray
#$Buffer = $mappedbuff | foreach-object {[System.Convert]::ToByte($_,16)}#>

write-host "Setting Encoding type to $enctype" ([System.Text.Encoding]::GetEncodings()| where-object {$_.Name -match $enctype}).DisplayName
$Encoding = [System.Text.Encoding]::GetEncoding($enctype)

write-host "Translating to $enctype encoding"
$String = $Encoding.GetString($Buffer)

$outfile = $outfile -replace ".mta","_$enctype.mta"
write-host "Writing output to $outfile"
$String | Set-Content $outfile -Encoding Ascii

write-host "Tidying up variables"
#rv buffer,encoding,string,infile,outfile,enctype

write-host "ASCII 2 EBCDIC Translation Complete"
}

#A2E -infile "\\##REDACTED##\Test_Pattern.mta" -outfile "\\##REDACTED##\Test_Pattern.mta" -enctype "IBM037"
#A2E -infile "\\##REDACTED##\test_ascii.mta" -outfile "\\##REDACTED##\test_ebcdic.mta" -enctype "IBM037"
#A2E -infile "\\##REDACTED##\test_ascii.mta" -outfile "\\##REDACTED##\test_ebcdic.mta" -enctype "IBM437"
#A2E -infile "\\##REDACTED##\test_ascii.mta" -outfile "\\##REDACTED##\test_ebcdic.mta" -enctype "IBM500"
#A2E -infile "\\##REDACTED##\test_ascii.mta" -outfile "\\##REDACTED##\test_ebcdic.mta" -enctype "IBM01140"
#A2E -infile "\\##REDACTED##\test_ascii.mta" -outfile "\\##REDACTED##\test_ebcdic.mta" -enctype "IBM01146"
#A2E -infile "\\##REDACTED##\test_ascii.mta" -outfile "\\##REDACTED##\test_ebcdic.mta" -enctype "IBM01148"
#A2E -infile "\\##REDACTED##\test_ascii.mta" -outfile "\\##REDACTED##\test_ebcdic.mta" -enctype "IBM285"

[System.Text.Encoding]::GetEncodings() | foreach {A2E -infile "\\##REDACTED#\FILEPRIVILEGE_CSV" -outfile ("\\##REDACTED##\FILEPRIVILEGE_CSV_" + $_.name + ".CSV") -enctype $_.Name}
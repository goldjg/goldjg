Function New-BigFile {
<#
.Synopsis
  Creates a large dummy file with or without random conntent
.DESCRIPTION
  Creates a large dummy file with or without random conntent 
  Credits for the randome content creation logic goes to Robert Robelo
.PARAMETER Target
   The full path to a folder or file. If the target is a folder a random file name is generated
.PARAMETER MegaByte
   The size of the random file to be genrated. Default is one MB
.PARAMETER Filecontent
  Possible values are <random> or <empty> When <random> is specified the file is filled with
  random values. The value <empty> fills the file with nulls. 
.PARAMETER ShowProgress
 This parameter is optional and shows the progress of the file creation. 
.EXAMPLE
 New-Bigfile -Target C:\Temp\LF -Megabyte 10 -Filecontent random
.EXAMPLE
 New-Bigfile -Target C:\Temp\LF\bigfile.txt -Megabyte 10 -Filecontent random
.EXAMPLE
 New-Bigfile -Target C:\Temp\LF -Megabyte 10 -Filecontent empty
#>;

[CmdletBinding(SupportsShouldProcess=$True)]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [String]$Target,
    [Parameter(Mandatory = $false, Position = 1)]
    [ValidateRange(1, 5120)]
    [UInt16]$MegaByte = 1,
    [Parameter(Mandatory = $true,position = 2)]
    [ValidateSet("random","empty")]
    [string]$FileContent,
    [Switch]$ShowProgress)


If ([string]::IsNullOrEmpty([System.IO.Path]::GetDirectoryName("$target")) -eq $True)
{
    Write-Output "Specify a directory or file including path!"
    Throw
}


If([string]::IsNullOrEmpty([System.IO.Path]::GetExtension("$target")))
{
    Write-Verbose "Provided input $target has no file extension, target is a folder"
    $fname = ("" + ([guid]::NewGuid()) + ".LF")
    Write-Verbose "Random generated filename: $fname"
    $Target = Join-path $Target  $fname
    $folder = [System.IO.Path]::GetDirectoryName($target)

    If ((Test-path $folder) -eq $false)
    {If ($PSCmdlet.ShouldProcess("Directory does not exist, creating directory $folder ")) 
            { New-Item -Path $folder -ItemType Directory | Out-Null}}
}
Else
{
   If ((Test-path -Path $target) -eq $true)
        {Write-verbose "File $Target already exists, exiting to prevent overwrite"
        Break}
    Else
        {Write-Verbose "File $target does not exist yet"}

    # Check if the directory actually exists, if not create it
    $folder = [System.IO.Path]::GetDirectoryName($target)
    If ((Test-path $folder) -eq $false)
    {If ($PSCmdlet.ShouldProcess("Creating folder $folder")) 
            {New-Item -Path $folder -ItemType Directory | Out-Null}}
}

$path = $Target
$total = 1mb * $MegaByte
$strings = $bytes = 0

If ($FileContent -eq "random")
{
If ($PSCmdlet.ShouldProcess("Creating random file $path with $Megabyte MB")) 
{

# create the stream writer
$sw = New-Object IO.streamWriter $path

# get a 64 element Char[]; I added the - and _ to have 64 chars
[char[]]$chars = 'azertyuiopqsdfghjklmwxcvbnAZERTYUIOPQSDFGHJKLMWXCVBN0123456789-_'
1..$MegaByte | ForEach-Object {
# get 1MB of chars from 4 256KB strings
1..4 | ForEach-Object {
# randomize all chars and...
$rndChars = $chars | Get-Random -Count $chars.Count
# ...join them in a string
$str = -join $rndChars
# repeat random string 4096 times to get a 256KB string
$str_ = $str * 4kb
# write 256KB string to file
$sw.Write($str_)
# show progress

    if ($ShowProgress) {
    $strings++
    $bytes += $str_.Length
    Write-Progress -Activity "Writing String #$strings" -Status "$bytes Bytes written" -PercentComplete ($bytes / $total * 100)
    }

# release resources by clearing string variables
Clear-Variable str, str_
}
}
$sw.Close()
$sw.Dispose()
# release resources through garbage collection
[GC]::Collect()
}
}

Else 
{
    If ($PSCmdlet.ShouldProcess("Creating empty file $path with $Megabyte MB")) 
    {
    # write 4K worth of data at a time
    $bufSize = 4096
    $bytes = New-Object byte[] $bufSize
    $file = [System.IO.File]::Create("$path")
    # write the first block out to accommodate integer division truncation
    $file.Write($bytes, 0, $bufSize)
    for ($i = 0; $i -lt $Megabyte*1MB; $i = $i + $bufSize) { $file.Write($bytes, 0, $bufSize) 

    if ($ShowProgress) {
        Write-Progress -Activity "Writing String #$strings" -Status "Bytes written" -PercentComplete ($i/($megabyte*1MB)*100 )
    }
    }
    $file.Close()
} 
} 
} 
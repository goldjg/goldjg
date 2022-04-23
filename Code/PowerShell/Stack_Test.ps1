function Copy-Files {
param([object]$copylist, [string]$src, [string]$dest)

[int]$filecount = 0;
#[long]$totalbytes = 0;
[long]$totalcopied = 0;

foreach($file in $copylist){
    $filecount++
    if ([system.io.file]::Exists($dest+$file.filename)){
                [system.io.file]::Delete($dest+$file.filename)}
    [object]$from = ($src + $file.filename)
    [object]$to = ($dest + $file.filename)

    $ffile = [io.file]::OpenRead($from)
    $tofile = [io.file]::OpenWrite($to)

    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew();
        [byte[]]$buff = new-object byte[] 65536
        [long]$total = [long]$count = 0
        do {
            $count = $ffile.Read($buff, 0, $buff.Length)
            $tofile.Write($buff, 0, $count)
            $total += $count
            $totalcopied += $count
            if ($total % 1mb -eq 0) {
                if ($totalcopied % 1mb -eq 0){
                    if([long]($total/$ffile.Length* 100) -gt 0)`
                        {[long]$secsleft = ([long]$sw.Elapsed.Seconds/([long]($totalcopied/$totalbytes* 100))*100)
                        } else {
                        [long]$secsleft = 0};
                    Write-Progress `
                        -Activity ([string]([long]($totalcopied/$totalbytes* 100)) + "% Copying files ") `
                        -status ([string]$filecount + " of " + $files.count) `
                        -Id 1 `
                        -PercentComplete ([long]($totalcopied/$totalbytes* 100)) `
                        -SecondsRemaining $secsleft
                        }
                Write-Progress `
                    -Activity ([string]([long]($total/$ffile.Length* 100)) + "% Copying file")`
                    -status ($from.Split("\")|select -last 1) `
                    -Id 2 `
                    -ParentId 1 `
                    -PercentComplete ([long]($total/$ffile.Length* 100))
            }
        } while ($count -gt 0)
    $sw.Stop();
    $sw.Reset();
    }
    finally {
        $ffile.Close()
        $tofile.Close()
        Write-Host ($from + " copied as " + $to)
        }
    }
};

$srcdir = "C:\Source";
$destdir = "C:\Dest";

$filestocopy =@();

$files = (Get-ChildItem -recurse $SrcDir | where-object {-not ($_.PSIsContainer)});
$files|foreach($_){
    [long]$totalbytes += $_.length;
    $obj = New-Object System.Object
    $obj | Add-Member -MemberType NoteProperty -Name FileName -Value ($_.fullname).Remove(0,($srcdir.length)) 
    $filestocopy += $obj
    
    #$filestocopy += @(($_.fullname).Remove(0,($srcdir.length)));   
};

Copy-Files -copylist $filestocopy -src $srcdir -dest $destdir
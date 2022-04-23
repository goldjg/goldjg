    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path $_ -PathType container})]
        [string]$dir
        )

dir $dir -recurse|`
?{$_.mode -notlike "d*"}|`
%{$tmpfile = [io.file]::OpenRead($_.fullname);
  [byte[]]$buff = new-object byte[] (4096);
  [long]$count = 0;
  $count = $tmpfile.Read($buff, 0, $buff.Length);
  $count = $buff = $null;
  write-host -object ("Opened or Recovered " + $_.fullname) -foregroundcolor DarkMagenta;
  }
  write-host -object ("All Done!!") -foregroundcolor Green;
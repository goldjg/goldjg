dir ##REDACTED## -recurse|`
?{$_.mode -notlike "d*"}|`
%{$tmpfile = [io.file]::OpenRead($_.fullname);
  [byte[]]$buff = new-object byte[] (4096);
  [long]$count = 0;
  $count = $tmpfile.Read($buff, 0, $buff.Length);
  $count = $buff = $null;
  write-host ("Opened or Recovered " + $_.fullname);
  }
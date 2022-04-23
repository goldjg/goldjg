$RegEx="[a-zA-Z0-9.!£#$%&'^_`{}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*"

Write-Host "Reading export for records with fully qualified email addresses"
$addrs = (select-string -Path '\\##REDACTED##\msgs.txt' -Pattern $RegEx)

Write-Host "Grabbing the addresses"
$addresses=$addrs|foreach{[regex]::match($_,("("+$RegEx+")+")).Groups[1].Value}

Write-Host "Removing duplicates"
$uniq = $addresses|select -Unique

Write-Host "Writing addresses to file"
$uniq|out-file "\\##REDACTED##\uaddrs.txt"
$addresses|out-file "\\##REDACTED##\addrs.txt"

Write-Host "Getting domains"
$domains=@()
$uniq|foreach {$domains+=($_.split('@')[1].ToUpper())}
$udomains=$domains|select -Unique

Write-Host "Writing domains to file"
$udomains|Out-File "\\##REDACTED##\domains.txt"
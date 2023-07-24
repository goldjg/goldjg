Connect-AzureAD
$apps = Get-azureAdApplication -All $true 
$mta = $apps| 
Where-Object {$_.ReplyUrls -match "azurewebsites.net"} | 
Select-Object -ExpandProperty replyurls | Where-Object {$_ -match "azurewebsites.net"}

$list = @()
foreach ($domain  in $mta) {
    if ($domain -match "http://") {
        $list+=($domain -split "http://" -split "/")[1];
    }

    if ($domain -match "https://") {
        $list+=($domain -split "https://" -split "/")[1];
    }
       
}

$results = @()
$ErrorActionPreference = "Stop"
foreach ($parsed in $list) {
    try {
       $s = Resolve-DnsName $parsed;
    }
        catch {
        Write-Host "Subdomain takeover possible for $parsed" -ForegroundColor red
        $ob =  $apps | where {$_.ReplyUrls -match $parsed}
        $ob | Add-Member -NotePropertyName "subdomain_takeOverPlausible" -NotePropertyValue $parsed -Force
        $results += $ob
    }   
}

$results | select -Unique subdomain_takeOverPlausible, *DisplayName*, appid
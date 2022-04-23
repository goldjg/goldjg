param([string]$list1,[string]$list2)
if ($list1 -eq ""){
    Write-Host "Please supply Host-list!!" -ForegroundColor Red
    break
    }
If ($list2 -eq ""){
    Write-Host "Please supply Port-List!!" -ForegroundColor Red
    break
    }
[Array]$hostlist = Get-Content $list1
[Array]$ports = Get-Content $list2
$ErrorActionPreference = "SilentlyContinue"
$ping = new-object System.Net.NetworkInformation.Ping
foreach ($ip in $hostlist) {
    $rslt = $ping.send($ip)
    if (! $?){
        Write-Host "Host: $ip - not found" -ForegroundColor Red
    }
    else {
        if ($rslt.status.tostring() –eq “Success”) {
            write-host "Host: $ip - Ports: " -foregroundColor Green -NoNewline
            write-host
            foreach ($port in $ports){
                $socket = new-object System.Net.Sockets.TcpClient($ip, $port)
                if ($socket –eq $null) {
                    write-host "$port" -ForegroundColor Red #-NoNewline
                    $port >> ("K:\"+$ip+"_blocked_ports.txt")
                }
                else {
                    write-host "$port"-foregroundcolor Green #-NoNewline
                    $port >> ("K:\"+$ip+"_open_ports.txt")
                    $socket = $null
                }
            }
        }
        else {
            write-host "Host: $ip - down" -ForegroundColor Red
        }
    }
Write-Host ""
}
$ping = $null
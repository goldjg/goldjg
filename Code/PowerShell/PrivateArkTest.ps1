[int] $Port = 1858
$IP = ""
$Address = [system.net.IPAddress]::Parse($IP) 

# Create IP Endpoint 
$End = New-Object System.Net.IPEndPoint $address, $port 

# Create Socket 
$Saddrf   = [System.Net.Sockets.AddressFamily]::InterNetwork 
$Stype    = [System.Net.Sockets.SocketType]::Stream 
$Ptype    = [System.Net.Sockets.ProtocolType]::TCP 
$Sock     = New-Object System.Net.Sockets.Socket $saddrf, $stype, $ptype 
$Sock.TTL = 23

Write-Output "Connecting to CyberArk server on port 1838"
# Connect to socket 
$sock.Connect($end) 

write-output "Connected and sleeping for 3 minutes"
Start-Sleep -Second 180
write-output "Exiting after 3 minutes"
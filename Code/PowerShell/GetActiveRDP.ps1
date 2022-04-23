$active_rdp = $null;
$active_host_table = $null;
$IP = $null;

$active_rdp = iex "netstat -ano"|`
              where-object {$_ -like "*ESTABLISHED*"}|`
              where-object {$_ -like "*:3389*"};

if (!($active_rdp -eq $null)) {
                $active_host_table = $active_rdp|`
                foreach {$IP=([regex]::Split($_,"\s\s\s\s")[2]).Split(":")[0];`
                [System.Net.Dns]::Resolve($IP.Trim())|foreach {$_.hostname.Split(".")[0].ToUpper()}};
                return $active_host_table;
            } else {
                write-host ("No active RDP sessions");
                };
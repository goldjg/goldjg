$active_rdp= (iex "netstat -p TCP"| `
                where-object {$_.endswith("ESTABLISHED")}|`
                where-object {$_ -like "*:ms-wbt-server*"}|`
                foreach {([regex]::Split($_,'\s\s\s\s')[2]).Split(":")[0]})
#$active_conn = iex "netstat -p TCP";$active_rdp = $active_conn| where-object {$_.endswith("ESTABLISHED")}| where-object {$_ -like "*:ms-wbt-server*"};$active_rdp|foreach {([regex]::Split($_,'\s\s\s\s')[2]).Split(":")[0]}
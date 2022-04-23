$idx = [io.file]::ReadAllLines("\\##REDACTED##\index1.idx")
$idx_chm = ($idx -match '\[CHM\]') -replace 'Database, Query, and Reporting','Database Query and Reporting'

gci -recurse -filter "*.chm" `
    "\\##REDACTED##\chm\"|`
    foreach ($_){

        $meta = (([io.file]::ReadAllLines($_.fullname)) -match ".htm\S"|select -last 1)
        If ($meta.ToString().Split("")[1] -match '\Stitlepg.htm\S'){
            $title = $meta.ToString().Split("")[2].Split("")[0].SubString(3)
            $title = $title.Substring(0,$title.Length-1)
            If ($title -eq "nxedit"){$title = "Programmer's Workbench for ClearPath MCP Help"}
            
            $category = ($idx_chm -match ($title).ToString() -split 'MCP \d\d\.\d,')[1]
            If ($category -match ','){$category = $category.Split(",")[0]}
            If (($category -eq $null) -and ($category -match 'MCP \d\d\.\d,')){
                $category = ($idx_chm -match ($title.Split(" ")[0-2]).ToString() -split 'MCP \d\d\.\d,')[1]
                If ($category -match ','){$category = $category.Split(",")[0]}
                }
            If ($category -eq $null){
                If ($title -match 'Security'){$category = "Security"}
                If ($title -match 'Java'){$category = "Java Middleware"}
                If ($title -match 'JDBC'){$category = "Java Middleware"}
                If ($title -match 'MCPInfo'){$category = "Application Development"}
                If ($title -match 'NXPipe'){$category = "Application Development"}
                If ($title -match 'Network'){$category = "Communications and Networking"}
                If ($title -match 'Web Enabl'){$category = "Internet and Transaction Processing"}
                If ($title -match 'Web Transaction '){$category = "Java Middleware"}
                If ($title -match 'System Commands'){$category = "Administration"}
                If ($title -match ' Center '){$category = "Administration"}
                If ($title -match 'MQ'){$category = "Internet and Transaction Processing"}
                If ($title -match 'MCP Neighborhood'){$category = "Administration"}
                If ($title -match 'OLE DB'){$category = "Database Query and Reporting"}
                If ($title -match 'ODBC'){$category = "Database Query and Reporting"}
                If ($title -match 'Command Store Utility'){$category = "Database Query and Reporting"}
                }
            }
        else{
            $title = $meta.ToString().Split("")[1].Split("")[0].SubString(3)
            $title = $title.Substring(0,$title.Length-1)
            If ($title -eq "nxedit"){$title = "Programmer's Workbench for ClearPath MCP Help"}

            $category = ($idx_chm -match ($title).ToString() -split 'MCP \d\d\.\d,')[1]
            If ($category -match ','){$category = $category.Split(",")[0]}
            If (($category -eq $null) -and ($category -match 'MCP \d\d\.\d,')){
                $category = ($idx_chm -match ($title.Split(" ")[0-2]).ToString() -split 'MCP \d\d\.\d,')[1]
                If ($category -match ','){$category = $category.Split(",")[0]}
                }
            If ($category -eq $null){
                If ($title -match 'Security'){$category = "Security"}
                If ($title -match 'Java'){$category = "Java Middleware"}
                If ($title -match 'JDBC'){$category = "Java Middleware"}
                If ($title -match 'MCPInfo'){$category = "Application Development"}
                If ($title -match 'NXPipe'){$category = "Application Development"}
                If ($title -match 'Network'){$category = "Communications and Networking"}
                If ($title -match 'Web Enabl'){$category = "Internet and Transaction Processing"}
                If ($title -match 'Web Transaction '){$category = "Java Middleware"}
                If ($title -match 'System Commands'){$category = "Administration"}
                If ($title -match ' Center '){$category = "Administration"}
                If ($title -match 'MQ'){$category = "Internet and Transaction Processing"}
                If ($title -match 'MCP Neighborhood'){$category = "Administration"}
                If ($title -match 'OLE DB'){$category = "Database Query and Reporting"}
                If ($title -match 'ODBC'){$category = "Database Query and Reporting"}
                If ($title -match 'Command Store Utility'){$category = "Database Query and Reporting"}
                }
            }
        write-host ("Title: " + $title)
        write-host ("Category: " + $category)
        write-host ($_.fullname + "`n") -foregroundcolor DarkMagenta
        $title = $null
        $category = $null
    }
gci -recurse -filter "*.pdf" `
    "\\##REDACTED##\PDF\"|`
    foreach ($_){
        $meta = ([io.file]::ReadAllLines($_.fullname) -match "<rdf:li")
        if ($meta.count -gt 2){
            $title = $meta[0].ToString().Split(">")[1].Split("<")[0]
            $meta2 = (($meta[2] -replace 'Database, Query, and Reporting','Database Query and Reporting').ToString().Split(">")[1].Split("<")[0]) -replace ', ',','
            $release = $meta2.ToString().Split(",")[0]
            $category = $meta2.ToString().Split(",")[1]
            write-host ("Title: " + $title)
            write-host ("Release: " + $release)
            write-host ("Category: " + $category)
            write-host ($_.fullname + "`n`n")
            $title = $null
            $category = $null
            }
        else
            {
            $title = $meta[0].ToString().Split(">")[1].Split("<")[0]
            write-host ("Title: " + $title)
            write-host ($_.fullname + "`n`n")
            $title = $null
            $category = $null
            }
    }
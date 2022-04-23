$7zpath = "\\##REDACTED##\CodeSnippets\PowerShell\7z.exe"
$isopath = '"\\##REDACTED##\MCP Upgrade 2013\68698703-009.iso"'
$mcpversion = (& $7zpath l $isopath "*.MDB"|Select-String "MCP_").ToString().Split("_")[1]
$exDir = "-o\\##REDACTED##\MCP_DOC\$mcpversion\"
$sitepath = "\\##REDACTED##\MCP_DOC\$mcpversion\"
$resourcepath = "\\##REDACTED##\CodeSnippets\PowerShell\MCP_DOC_Res\"

cp -rec $resourcepath $sitepath

& $7zpath x $isopath $exDir -yi!chm\*
& $7zpath x $isopath $exDir -yi!PDF\*


$title = $null
$category = $null
$index = @()

        #Counter to track progress
        [int]$count = 0

$PDFFiles = gci -recurse -filter "*.pdf" "$sitepath\PDF\"
$PDFFiles|foreach ($_){
        
        #determine what line in file the xmpmeta string starts
        [int]$startln = (select-string -pattern '^<x:' $_.Fullname).ToString().Split(":")[1]
            
        #determine what line in file the xmpmeta string ends
        [int]$endln = (select-string -pattern '^</x:' $_.Fullname).ToString().Split(":")[1]
        $startln--

        #grab the xmpmeta and cast as type xml
        [xml]$xmp = (gc $_.Fullname)["$startln".."$endln"]
        [xml]$rdf = $xmp.xmpmeta.InnerXml

        #get title/description element text
        [string]$title = ($rdf.GetElementsByTagName('dc:title')|`
            Select -expand Alt|Select -expand li)."#text"
        [string]$Category = (($rdf.GetElementsByTagName('dc:description')|`
            Select -expand Alt|`
            Select -expand li)."#text" -replace 'Database, Query, and Reporting','Database Query and Reporting').Split(",")[1]
        If (!($Category)){$Category = "Documentation Library"}
        #write-host ("Title: " + $title)
        #write-host ("Category: " + $category)
        #write-host ($_.fullname + "`n`n")
        $obj = $null
        $obj = New-Object System.Object
        $obj | Add-Member -type NoteProperty -Name Title -Value ('<a target="_blank" href="file:///' + $_.Directory + "\" + $_.name + '">' + $title + '</a>')
        $obj | Add-Member -type NoteProperty -Name Category -Value $category
        $obj | Add-Member -type NoteProperty -Name Label -Value $title
        $obj | Add-Member -type NoteProperty -Name Type -Value "PDF"            
        #$obj
        $title = $null
        $category = $null
        $index += $obj
        $count++
        Write-Progress `
         -Activity "Extracting PDF Metadata" `
         -Status ("Processed " + $count + " of " + $PDFFiles.Count + " PDF files") `
         -Id 1 `
         -PercentComplete ([int]($count/$PDFFiles.Count *100))
        
        }
        
         Write-Progress `
         -Activity "Extracting PDF Metadata" `
         -Status ("PDF Metadata Extract completed for " + $PDFFiles.Count + " files") `
         -Id 1 `
         -Completed
 
    
$idx = [io.file]::ReadAllLines("C:\MCP 15 Doc Library\PDF\00_HOME\index1.idx")
$idx_chm = ($idx -match '\[CHM\]') -replace 'Database, Query, and Reporting','Database Query and Reporting'

gci -recurse -filter "*.chm" "$sitepath\chm\"|`
    foreach ($_){

        $meta = (([io.file]::ReadAllLines($_.fullname)) -match ".htm\S"|select -last 1)
        If ($meta.ToString().Split("")[1] -match '\Stitlepg.htm\S'){
            $title = $meta.ToString().Split("")[2].Split("")[0].SubString(3)
            $title = $title.Substring(0,$title.Length-1)
            If ($title -eq "nxedit"){$title = "Programmer's Workbench for ClearPath MCP Help"}
            
            $category = ($idx_chm -match ($title).ToString() -split 'MCP \d\d\.\d,')[1]
            If ($category -match ','){$category = $category.Split(",")[0]}
            If (($category.Length -eq 0) -and ($category -match 'MCP \d\d\.\d,')){
                $category = ($idx_chm -match ($title.Split(" ")[0-2]).ToString() -split 'MCP \d\d\.\d,')[1]
                If ($category -match ','){$category = $category.Split(",")[0]}
                }
            If ($category.Length -eq 0){
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
            If (($category.Length -eq 0) -and ($category -match 'MCP \d\d\.\d,')){
                $category = ($idx_chm -match ($title.Split(" ")[0-2]).ToString() -split 'MCP \d\d\.\d,')[1]
                If ($category -match ','){$category = $category.Split(",")[0]}
                }
            If ($category.Length -eq 0){
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
        #write-host ("Title: " + $title)
        #write-host ("Category: " + $category)
        #write-host ($_.fullname + "`n") -foregroundcolor DarkMagenta
        $obj = $null
        $obj = New-Object System.Object
        $obj | Add-Member -type NoteProperty -Name Title -Value ('<a target="_blank" href="file:///' + $_.Directory + "\" + $_.name + '">' + $title + '</a>')
        $obj | Add-Member -type NoteProperty -Name Category -Value $category
        $obj | Add-Member -type NoteProperty -Name Label -Value $title
        $obj | Add-Member -type NoteProperty -Name Type -Value "CHM (HTMLHelp)" 
        #$obj
        $title = $null
        $category = $null
        $index += $obj
    }
    #$index|Sort Title|Export-Csv -notype -Path \\##REDACTED##\Unisys_Docs_Index.csv
    
    $htmlpre = gc $sitepath\test_pre.htm|%{ ($_.Replace("<h2></h2>","<h2>Unisys MCP $mcpversion Documentation Library</h2>"))}
    $htmltab = $index|Sort Label|Select Title,Category,Type|ConvertTo-Html -fragment|% { ($_.Replace("&lt;","<")).Replace("&gt;",">").replace("&quot;",'"').Replace('<table>','<Table id="table1">') }
    $htmlpost = gc $sitepath\test_post.htm

    ($htmlpre + $htmltab + $htmlpost)|out-file ($sitepath + "\MCP_" + $mcpversion + "_Docs.htm")
    
    #$htmltab | % { ($_.Replace("&lt;","<")).Replace("&gt;",">").replace("&quot;",'"') }|out-file \\##REDACTED##\Unisys_Docs_Index_table.htm

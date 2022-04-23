dir 'K:\RRD_Stats\SUMLOG\Rolling 13 Month Aug 15 to Aug 16'|foreach {

$JobsCount = Select-String -Path $_.FullName -Pattern "LINES PRINTED: "|Measure-Object|Select Count
(Select-String -Path $_.FullName -Pattern "LINES PRINTED: ")|foreach {
    $LinesCount += [int]($_.Line.Split(":")[2]).Split(" ")[1]
}
($_.Name +"," + $JobsCount.Count + ","+$LinesCount)|out-file -FilePath 'K:\RRD_Stats\SUMLOG\Rolling 13 Month Aug 15 to Aug 16\Stats.csv' -Append
rv LinesCount
}
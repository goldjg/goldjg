dir 'K:\RRD_Stats\Manifest\Rolling 13 Month Aug 15 to Aug 16'|foreach {

$JobsCount = Select-String -Path $_.FullName -Pattern "</groupDocumentCount>"|Measure-Object|Select Count
(Select-String -Path $_.FullName -Pattern "</groupDocumentCount>")|foreach {
    $FilesCount += [int]($_.Line.Split(">")[1].Split("<")[0])
}
($_.Name +"," + $JobsCount.Count + ","+$FilesCount/3)|out-file -FilePath 'K:\RRD_Stats\Manifest\Rolling 13 Month Aug 15 to Aug 16\Stats.csv' -Append
rv FilesCount
}
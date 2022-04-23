[xml]$xmp = gc K:\xmp.xml
$titles = $xmp.GetElementsByTagName("dc:title")
$title = ($titles|select -first 1).InnerText
Write-Host ("Title: " + $title)

$creators = $xmp.GetElementsByTagName("dc:creator")
$creator = ($creators|select -first 1).InnerText
Write-Host ("Creator: " + $creator)

$descriptions = $xmp.GetElementsByTagName("dc:description")
$description = ($descriptions|select -first 1).InnerText

$swlevel = $description.Split(",")[0]
$category = $description.Split(",")[1]
Write-Host ("Software Level: " + $swlevel)
Write-Host ("Category: " + $category)
# compare the objects
$f1 = (get-content .\IBM_Relationships.csv)
$f2 = @(get-content .\GG.csv)

$tempnew = @()
foreach ($CI in $f2) {
    if ($f1 -notcontains $CI) {
        $tempnew += $CI}}

$tempdeleted = @()
foreach ($CI in $f1) {
    if ($f2 -notcontains $CI) {
        $tempdeleted += $CI}}

$CINew = @()
$CIOld = @()       

foreach ($line in $tempnew) {
    $ID = $line.split(",")[0]
    foreach ($line2 in $tempdeleted) {
        if ($line2.StartsWith($ID)) {
            $CINew += ($line)
            $CIOld += ($line2)
            }
        }
    }

$NewCIs = @()
$NewCIs += (get-content .\GG.csv -totalcount 1)

$DeletedCIs = @()
$DeletedCIs += (get-content .\GG.csv -totalcount 1)

foreach ($line in $CINew) {
    $ID = $line.split(",")[0]
    foreach ($line2 in $tempnew) {
        if (-not $line2.StartsWith($ID)) {
            $NewCIs += $line2
        }
    }
}

foreach ($line in $CIOld) {
    $ID = $line.split(",")[0]
    foreach ($line2 in $tempdeleted) {
        if (-not $line2.StartsWith($ID)) {
            $DeletedCIs += $line2
        }
    }
}

$CINew = (get-content .\GG.csv -totalcount 1),$CINew
$CIOld = (get-content .\GG.csv -totalcount 1),$CIOld
                

write ("Found " + ($NewCIs.count -1) + " new CI(s)")
$NewCIs;write "`n"
write ("Found " + ($DeletedCIs.count -1) + " Deleted CI(s)")
$DeletedCIs;write "`n"
write ("Found " + ($CIOld.count -1) + " amended CI(s)")
write "The following CI(s) in the baseline: `n"
$CIOld;write "`n"
write "`n now have the following value(s) `n"
$CINew

#$NewCIs#.GetType()
#$f1#.GetType()

$NewCIs | select * | export-csv -notypeinformation -path NewCIs.csv
#[string]$output = $NewCIs| select-object @{n="Item";e={$_.split('"')}}|out-string
#$output|Select *|Export-CSV -notypeinformation -path .\NewCIs.csv
#$DeletedCIs|Select *|Export-CSV -notypeinformation -path .\DeletedCIs.csv
#$CINew|Select *|Export-CSV -notypeinformation -path .\AmendedCIs.csv
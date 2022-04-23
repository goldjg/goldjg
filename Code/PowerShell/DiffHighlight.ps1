$RsltGrid= Import-csv .\DummyDiff.csv
$flds = ($RsltGrid[0].psobject.properties | %{$_.Name} )
foreach ($Key in $flds) {
    $Values = $RsltGrid | Select * | where-object {($_.Reconciliation_Result -like "Changed*") -and ($Key -ne "own_resource_uuid") -and ($Key -ne "id")} | select -expand $Key
    For ($i = $Values.GetLowerBound(0); $i -lt $Values.GetUpperBound(0); $I=$I+2) {
        If ((($Values[$i]) -ne ($Values[$i+1])) -and $Key -ne "Reconciliation_Result"){
            If ($ChangedAtts -notcontains $Key) {$ChangedAtts += $Key}
            }
        }
    }
foreach ($Att in $ChangedAtts) {
    $RsltGrid2 = $RsltGrid | Select @{Name=("*** " + $Att + " ***");Expression={$_.$Att}}, * -Exclude $Att
    }
$RsltGrid2 | ogv
<#
***************************************************************************************
** Populate BatchStats Application Database (V0.1)                                   **
** ===============================================                                   **
**                                                                                   **
** Author: Graham Gold                                                               **
***************************************************************************************
#>

$BasePath="\\" + $ENV:CitrixDataServer + "\" + $env:USERNAME
$cnt=0
Write-Host "Importing Input CSV";
$Inp = Import-Csv -Path $BasePath\LOGSTATS\WorkingDir\GG.CSV;

Write-Host "Importing AccessFunctions module";
import-module $BasePath\CodeSnippets\PowerShell\AccessFunctions.psm1 -force;

Write-Host "Opening DB";
$db=Open-AccessDatabase -name BatchStats.accdb -path $BasePath\

Write-Host "Looping through input file"
$Inp|foreach-object {
remove-variable sql;
Write-Host ("Inserting Record #" + $cnt++)
$StatDay=(get-date $_.Date -uformat "%d-%B-%Y")
$System=$_.System
$SharedJobs=$_."Shared Jobs"
$CP1Jobs=$_."CP1 Jobs"
$CP2Jobs=$_."CP2 Jobs"
$SharedCPU=$_."Shared CPU"
$CP1CPU=$_."CP1 CPU"
$CP2CPU=$_."CP2 CPU"
$CP1Usage=$_."CP1 Usage"
$CP2Usage=$_."CP2 Usage"
Switch($System)
    {
    "PRODUCTION"  {
        $sql = "SELECT * FROM ProdSplit Where [StatDay]=#$StatDay#"
        $qrslt = Get-AccessData -sql $sql -connection $db
        If ($qrslt.ItemArray.Count -gt 0){
            Write-Host "Record already exists in ProdSplit table for $StatDay - record not added"
                }
            else {
            $sql = "INSERT INTO ProdSplit VALUES ('$StatDay','$System','$SharedJobs','$CP1Jobs','$CP2Jobs','$SharedCPU','$CP1CPU','$CP2CPU','$CP1Usage','$CP2Usage')"
            $arslt = Add-AccessRecord -sql $sql -connection $db;
            }
        }
    "DEVELOPMENT"  {
        $sql = "SELECT * FROM DevSplit Where [StatDay]=#$StatDay#"
        $qrslt = Get-AccessData -sql $sql -connection $db
        If ($qrslt.ItemArray.Count -gt 0){
            Write-Host "Record already exists in DevSplit table for $StatDay - record not added"
                }
            else {
            $sql = "INSERT INTO DevSplit VALUES ('$StatDay','$System','$SharedJobs','$CP1Jobs','$CP2Jobs','$SharedCPU','$CP1CPU','$CP2CPU','$CP1Usage','$CP2Usage')"
            $arslt = Add-AccessRecord -sql $sql -connection $db;
            }
        }
    }
Write-Host $sql
}


Write-Host "Closing DB";
Close-AccessDatabase -connection $db;
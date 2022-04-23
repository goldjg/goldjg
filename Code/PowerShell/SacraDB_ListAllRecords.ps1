Write-Host "Importing AccessFunctions module";
import-module \\##REDACTED##\AccessFunctions.psm1 -force;

Write-Host "Opening DB";
$db=Open-AccessDatabase -name Sacra_Test.accdb -path \\##REDACTED##\;

Write-Host "Reading all records in all tables:";
Get-AccessData -sql "SELECT * from Items,Repositories,Creds" -connection $db;

Write-Host "Closing DB";
Close-AccessDatabase -connection $db;
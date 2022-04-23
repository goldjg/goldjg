<#
***************************************************************************************
** Create BatchStats Application Database (V0.1)                                     **
** =============================================                                     **
**                                                                                   **
** Author: Graham Gold                                                               **
***************************************************************************************
#>
Write-Host "Importing AccessFunctions module";
$BasePath="\\" + $ENV:CitrixDataServer + "\" + $env:USERNAME
import-module $BasePath\CodeSnippets\PowerShell\AccessFunctions.psm1 -force;

Write-Host "Creating Database";
New-AccessDatabase -name BatchStats.accdb -path $BasePath;# -acc3;

Write-Host "Opening DB";
$db=Open-AccessDatabase -name BatchStats.accdb -path $BasePath

Write-Host "Creating CompanySplit table";
New-AccessTable -table CompanySplit -connection $db;

Write-Host "Adding columns to CompanySplit table";
New-AccessColumn -connection $db -table CompanySplit -notnull -textname Date -size 36;
New-AccessColumn -connection $db -table CompanySplit -notnull -textname CredUser -size 255;
New-AccessColumn -connection $db -table CompanySplit -notnull -textname CredPass -size 255;
New-AccessColumn -connection $db -table CompanySplit -notnull -textname CredItemUUID -size 36;
New-AccessColumn -connection $db -table CompanySplit -notnull -textname CredRepositoryUUID -size 36;
New-AccessColumn -connection $db -table CompanySplit -notnull -textname CredDesc -size 255;

Write-Host "Adding keys to Creds table";
Add-TablePrimaryKey -connection $db -table Creds -keyfield "(CredUUID,CredItemUUID,CredRepositoryUUID)";

Write-Host "Creating Repositories table";
New-AccessTable -table Repositories -connection $db;

Write-Host "Adding columns to Repositories table";
New-AccessColumn -connection $db -table Repositories -notnull -textname RepositoryUUID -size 36;
New-AccessColumn -connection $db -table Repositories -notnull -textname RepositoryName -size 255;
New-AccessColumn -connection $db -table Repositories -notnull -textname RepositoryDesc -size 255;

Write-Host "Adding keys to Repositories table";
Add-TablePrimaryKey -connection $db -table Repositories -keyfield "(RepositoryUUID)";

[String]$UUID = ([System.Guid]::NewGuid()).ToString();
$sql = "INSERT INTO Repositories VALUES ('$UUID','Default','Default Group')";
Write-Host "Adding Default Repository record:";
Write-Host $sql
Add-AccessRecord -sql $sql -connection $db;
remove-variable sql,uuid;

Write-Host "Record created:";
Get-AccessData -sql "SELECT * from Repositories" -connection $db;

Write-Host "Creating Items table";
New-AccessTable -table Items -connection $db;

Write-Host "Adding columns to Items table";
New-AccessColumn -connection $db -table Items -notnull -textname ItemUUID -size 36;
New-AccessColumn -connection $db -table Items -notnull -textname ItemName -size 255;
New-AccessColumn -connection $db -table Items -notnull -textname ItemDesc -size 255;
New-AccessColumn -connection $db -table Items -notnull -textname ItemRepositoryUUID -size 36;
New-AccessColumn -connection $db -table Items -notnull -textname ItemCredUUID -size 36;

Write-Host "Adding keys to Items table";
Add-TablePrimaryKey -connection $db -table Items -keyfield "(ItemUUID,ItemRepositoryUUID,ItemCredUUID)";

Write-Host "Closing DB";
Close-AccessDatabase -connection $db;
<#
***************************************************************************************
** Create Sacra Application Database (V0.1)                                          **
** ========================================                                          **
**                                                                                   **
** Author: Graham Gold                                                               **
***************************************************************************************
#>
Write-Host "Importing AccessFunctions module";
import-module \\LGRDCPPDT84\m61889\CodeSnippets\PowerShell\AccessFunctions.psm1 -force;

Write-Host "Creating Database";
New-AccessDatabase -name Sacra_Test2.accdb -path \\##REDACTED##\;# -acc3;

Write-Host "Opening DB";
$db=Open-AccessDatabase -name Sacra_Test2.accdb -path \\##REDACTED##\;

Write-Host "Creating Creds table";
New-AccessTable -table Creds -connection $db;

Write-Host "Adding columns to Creds table";
New-AccessColumn -connection $db -table Creds -notnull -textname CredUUID -size 36;
New-AccessColumn -connection $db -table Creds -notnull -textname CredUser -size 255;
New-AccessColumn -connection $db -table Creds -notnull -textname CredPass -size 255;
New-AccessColumn -connection $db -table Creds -notnull -textname CredItemUUID -size 36;
New-AccessColumn -connection $db -table Creds -notnull -textname CredRepositoryUUID -size 36;
New-AccessColumn -connection $db -table Creds -notnull -textname CredDesc -size 255;

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
<#
ScriptName:    CSV_Compare.ps1

ScriptAuthor:  Graham Gold

ScriptVersion: 0.1

ScriptDate:    12/05/2021

Description    Compares two CSV report files and produces report of differences between the reports, for investigation.

Parameters:    BaseDir {String} - Optional base path of script - if not supplied, script determines this at runtime
               
               PrevDir {String} - Optional path for previous baseline report - if not supplied, script assumes it is a child directory under the base path, called Previous. 
               
               CurrDir {String} - Optional path for current report - if not supplied, script assumes it is a child directory under the base path, called Current. 
               
               OutDir  {String} - Optional path for output/results - if not supplied, script assumes it is a child directory under the base path, called Results           

               PrevFile {String} - Mandatory - filename of the baseline file (with a .csv extension)

               CurrFile {String} - Mandatory - filename of the current file to compare with baseline (with a .csv extension)
#>
param([Parameter(Mandatory=$false)]
      [ValidateScript ({Test-Path $_ -PathType Container})]
      [string]$BaseDir,
      
      [Parameter(Mandatory=$false)]
      [ValidateScript ({Test-Path $_ -PathType Container})]
      [string]$PrevDir,
      
      [Parameter(Mandatory=$false)]
      [ValidateScript ({Test-Path $_ -PathType Container})]
      [string]$CurrDir,
    
      [Parameter(Mandatory=$false)]
      [ValidateScript ({Test-Path $_ -PathType Container})]
      [string]$OutDir),

      [Parameter(Mandatory=$true)]
      [ValidateScript ({if($_ -notmatch "(\.csv)"){
        throw "The file specified in the path argument must be either of type CSV"
        }})]
      [string]$PrevFile,

      [Parameter(Mandatory=$true)]
      [ValidateScript ({if($_ -notmatch "(\.csv)"){
        throw "The file specified in the path argument must be either of type CSV"
        }})]
      [string]$CurrFile

#Determine script path
$MyRootPath = Split-Path $MyInvocation.MyCommand.Path

If($BaseDir -eq "") { #If BaseDir parameter was not supplied, set to script path
    $BaseDir = $MyRootPath
}

If($PrevDir -eq "") { #If PrevDir parameter was not supplied, set to child directory under the BaseDir, called Previous
    $PrevDir = "$MyRootPath\Previous"
}

If($CurrDir -eq "") { #If CurrDir parameter was not supplied, set to child directory under the BaseDir, called Current
    $CurrDir = "$MyRootPath\Current"
}

If($OutDir -eq "") { #If OutDir parameter was not supplied, set to child directory under the BaseDir, called Results
    $outDir = "$MyRootPath\Results"
}

#Check for residence of previous month report - exit with an error if not present
If(!(Test-Path -Path $PrevDir\$PrevFile -PathType Leaf)){
    Write-Error "$PrevDir\$PrevFile is not present - please place the previous baseline report file in $PrevDir"
    Exit 1
}

#Check for residence of current month report - exit with an error if not present
If(!(Test-Path -Path $CurrDir\$CurrFile -PathType Leaf)){
    Write-Error "$CurrDir\$CurrFile is not present - please place the current month file in $CurrDir"
    Exit 2
}

$OutFile = $CurrFile -replace '.csv','_diff.csv'

Write-Host -ForegroundColor Green "Script running in $BaseDir"
Write-Host -ForegroundColor Green "Previous Fileprivilege report is $PrevDir\$PrevFile"
Write-Host -ForegroundColor Green "Current Fileprivilege report is $CurrDir\$CurrFile"
Write-Host -ForegroundColor Green "Comparison output will be written to $OutDir\$OutFile"

Write-Host "Comparing reports..."

#Compare files (get-content is required to read in the file first - otherwise compare will just compare the text of the supplied filenames)
$diffrslt = compare-object -ReferenceObject (get-content $PrevDir\$PrevFile) -DifferenceObject (get-content $CurrDir\$CurrFile)

#Find out how many differences were found
$diffcount = $diffrslt.count

If($diffcount -gt 0){ # At least one difference found, display count of differences found, in red text
    Write-Host -ForegroundColor Red "$diffcount differences found between reports.`r`nPlease review $OutDir\$OutFile"
} else { #no differences found, display message to that effect, in green text
    Write-Host -ForegroundColor Green "No differences found between reports.`r`nEmpty $outDir\$OutFile file created"
}

#Write out the compare output to a CSV file
$diffrslt|Export-Csv -NoTypeInformation -Path $OutDir\$OutFile
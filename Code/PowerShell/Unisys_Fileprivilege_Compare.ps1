<#
ScriptName:    Unisys_Fileprivilege_Compare.ps1

ScriptAuthor:  Graham Gold

ScriptVersion: 0.1

ScriptDate:    13th June 2016

Description    Compares two FILEPRIVILEGE CSV report files from Unisys mainframe (Produced by Locum SafeSurvey) and produces report of differences between the reports, for investigation.
               Part of the quarterly Build Compliance reporting.

Parameters:    BaseDir {String} - Optional base path of script - if not supplied, script determines this at runtime
               
               PrevDir {String} - Optional path for previous FILEPRIVILEGE report - if not supplied, script assumes it is a child directory under the base path, called Previous. 
                                  Report must be called FILEPRIVILEGE.CSV
               
               CurrDir {String} - Optional path for current FILEPRIVILEGE report - if not supplied, script assumes it is a child directory under the base path, called Current. 
                                  Report must be called FILEPRIVILEGE.CSV
               
               OutDir  {String} - Optional path for output/results - if not supplied, script assumes it is a child directory under the base path, called Results           
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
      [string]$OutDir)

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
If(!(Test-Path -Path $PrevDir\FILEPRIVILEGE.CSV -PathType Leaf)){
    Write-Error "$PrevDir\FILEPRIVILEGE.CSV is not present - please place the previous month file in $PrevDir named 'FILEPRIVILEGE.CSV'"
    Exit 1
}

#Check for residence of current month report - exit with an error if not present
If(!(Test-Path -Path $CurrDir\FILEPRIVILEGE.CSV -PathType Leaf)){
    Write-Error "$CurrDir\FILEPRIVILEGE.CSV is not present - please place the current month file in $CurrDir named 'FILEPRIVILEGE.CSV'"
    Exit 2
}

Write-Host -ForegroundColor Green "Script running in $BaseDir"
Write-Host -ForegroundColor Green "Previous Fileprivilege report is $PrevDir\FILEPRIVILEGE.CSV"
Write-Host -ForegroundColor Green "Current Fileprivilege report is $CurrDir\FILEPRIVILEGE.CSV"
Write-Host -ForegroundColor Green "Comparison output will be written to $OutDir\RESULTS.CSV"

Write-Host "Comparing reports..."

#Compare files (get-content is required to read in the file first - otherwise compare will just compare the text of the supplied filenames)
$diffrslt = compare-object -ReferenceObject (get-content $PrevDir\FILEPRIVILEGE.CSV) -DifferenceObject (get-content $CurrDir\FILEPRIVILEGE.CSV)

#Find out how many differences were found
$diffcount = $diffrslt.count

If($diffcount -gt 0){ # At least one difference found, display count of differences found, in red text
    Write-Host -ForegroundColor Red "$diffcount differences found between reports.`r`nPlease review $OutDir\RESULTS.CSV"
} else { #no differences found, display message to that effect, in green text
    Write-Host -ForegroundColor Green "No differences found between reports.`r`nEmpty $outDir\RESULTS.CSV file created"
}

#Write out the compare output to a CSV file
$diffrslt|Export-Csv -NoTypeInformation -Path $OutDir\RESULTS.CSV
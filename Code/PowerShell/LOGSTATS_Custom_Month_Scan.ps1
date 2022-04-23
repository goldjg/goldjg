Function DisplayIt{
<# 
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
| DisplayIt function                                                                    |
| Input: String message                                                                 |
| Output: Timestamped message written to console                                        |
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#>
param (
        [Parameter(Mandatory=$true)]
        [string]$msg
)
Write-Host "[$(Get-Date -f 'yyyyMMddHHmmss')]: $($msg)`r`n";
}
Function ProcessCSV{
Param(
        [Parameter(Mandatory=$false,
        HelpMessage="Please supply path to input file to be processed")]
        [Alias("I")]
        [ValidateScript({Test-Path $_ -PathType leaf})]
        [string]$InFile,
        
        [Parameter(Mandatory=$false,
        HelpMessage="Please supply path to working directory where working CSV for stats should be placed")]
        [Alias("W")]
        [ValidateScript({Test-Path $_ -PathType container})]
        [string]$WorkDir,
        
        [Parameter(Mandatory=$false,
        HelpMessage="Please supply path to working directory where processed CSV files should be placed")]
        [Alias("P")]
        [ValidateScript({Test-Path $_ -PathType container})]
        [string]$ProcessedDir
        )
$CP1Split = 0.5
$CP5Split = 0.5

DisplayIt("Removing null chars from "+$Infile)
(Get-Content $InFile -Raw) -replace [string][char]0 | Set-Content $InFile -Force

DisplayIt("Importing converted csv")
$Inp = Import-Csv $InFile

DisplayIt("Building master table")
$Table = $Inp | Select USERCODE,JOBNAME,MIXNUM,TASKNUM,BEGINDATE,BEGINTIME,ENDDATE,ENDTIME,DCKEYIN,MANUAL,JOBSTATUS,JOBTYPE,CPUTIME,IOTIME,ELAPSED,SYSTEM,"RUNTIME PARAMETERS"
rv Inp

$Prod_CP5_Jobs = @()
$Dev_CP5_Jobs = @()
$Prod_CP1_Jobs = @()
$Dev_CP1_Jobs = @()
$Prod_Shared_Jobs = @()
$Dev_Shared_Jobs = @()

DisplayIt("Entering tablescan")
$Table|foreach-object{
If ($_.JOBNAME -like '*CP5*' -or $_.JOBNAME -like '*CP6*' -or $_."RUNTIME_PARAMETERS" -like '*CP5*' -or $_."RUNTIME_PARAMETERS" -like '*CP6*'){
    If ($_.SYSTEM -eq "99999"){
        $Prod_CP5_Jobs+=$_}
        else {
        $Dev_CP5_Jobs+=$_}
        }

If (!($_.JOBNAME -like '*CP5*' -or $_.JOBNAME -like '*CP6*' -or $_."RUNTIME_PARAMETERS" -like '*CP5*' -or $_."RUNTIME_PARAMETERS" -like '*CP6*') -and` 
      ($_.JOBNAME -like '*CP4*' -or $_.JOBNAME -like '*CP2*' -or $_.JOBNAME -like '*CP3*' -or $_."RUNTIME_PARAMETERS" -like '*CP4*' -or $_."RUNTIME_PARAMETERS" -like '*CP2*' -or $_."RUNTIME_PARAMETERS" -like '*CP3*')){
    If ($_.SYSTEM -eq "99999"){
        $Prod_CP1_Jobs+=$_}
        else {
        $Dev_CP1_Jobs+=$_}
        }

If (!($_.JOBNAME -like '*CP5*' -or $_.JOBNAME -like '*CP6*' -or $_."RUNTIME_PARAMETERS" -like '*CP5*' -or $_."RUNTIME_PARAMETERS" -like '*CP6*') -and` 
      !($_.JOBNAME -like '*CP4*' -or $_.JOBNAME -like '*CP2*' -or $_.JOBNAME -like '*CP3*' -or $_."RUNTIME_PARAMETERS" -like '*CP4*' -or $_."RUNTIME_PARAMETERS" -like '*CP2*' -or $_."RUNTIME_PARAMETERS" -like '*CP3*')){
    If ($_.SYSTEM -eq "99999"){
        $Prod_Shared_Jobs+=$_}
        else {
        $Dev_Shared_Jobs+=$_}
        }
}

DisplayIt("Building Report")
$Report = @()
$Prod_Shared_CPU = ($Prod_Shared_Jobs|Measure-Object CPUTIME -Sum).Sum
$Prod_CP1_CPU = ($Prod_CP1_Jobs|Measure-Object CPUTIME -Sum).Sum
$Prod_CP5_CPU = ($Prod_CP5_Jobs|Measure-Object CPUTIME -Sum).Sum
$Prod_Tot_CPU = $Prod_Shared_CPU + $Prod_CP1_CPU + $Prod_CP5_CPU

$Dev_Shared_CPU = ($Dev_Shared_Jobs|Measure-Object CPUTIME -Sum).Sum
$Dev_CP1_CPU = ($Dev_CP1_Jobs|Measure-Object CPUTIME -Sum).Sum
$Dev_CP5_CPU = ($Dev_CP5_Jobs|Measure-Object CPUTIME -Sum).Sum -as [Double]
$Dev_Tot_CPU = $Dev_Shared_CPU + $Dev_CP1_CPU + $Dev_CP5_CPU


$obj = New-Object System.Object
$obj | Add-Member -MemberType NoteProperty -Name Date -Value ([datetime]::ParseExact($Table[0].ENDDATE,"yyyyMMdd",$null)).ToShortDateString()
$obj | Add-Member -MemberType NoteProperty -Name System -Value "PRODUCTION"
$obj | Add-Member -MemberType NoteProperty -Name "Shared Jobs" -Value $Prod_Shared_Jobs.Count
$obj | Add-Member -MemberType NoteProperty -Name "CP1 Jobs" -Value $Prod_CP1_Jobs.Count
$obj | Add-Member -MemberType NoteProperty -Name "CP5 Jobs" -Value $Prod_CP5_Jobs.Count
$obj | Add-Member -MemberType NoteProperty -Name "Shared CPU" -Value $Prod_Shared_CPU
$obj | Add-Member -MemberType NoteProperty -Name "CP1 CPU" -Value $Prod_CP1_CPU
$obj | Add-Member -MemberType NoteProperty -Name "CP5 CPU" -Value $Prod_CP5_CPU
$obj | Add-Member -MemberType NoteProperty -Name "CP1 Usage" -Value (($Prod_CP1_CPU + ($Prod_Shared_CPU*$CP1Split)) / $Prod_Tot_CPU)
$obj | Add-Member -MemberType NoteProperty -Name "CP5 Usage" -Value (($Prod_CP5_CPU + ($Prod_Shared_CPU*$CP5Split)) / $Prod_Tot_CPU)
$Report += $obj

$obj = New-Object System.Object
$obj | Add-Member -MemberType NoteProperty -Name Date -Value ([datetime]::ParseExact($Table[0].ENDDATE,"yyyyMMdd",$null)).ToShortDateString()
$obj | Add-Member -MemberType NoteProperty -Name System -Value "DEVELOPMENT"
$obj | Add-Member -MemberType NoteProperty -Name "Shared Jobs" -Value $Dev_Shared_Jobs.Count
$obj | Add-Member -MemberType NoteProperty -Name "CP1 Jobs" -Value $Dev_CP1_Jobs.Count
$obj | Add-Member -MemberType NoteProperty -Name "CP5 Jobs" -Value $Dev_CP5_Jobs.Count
$obj | Add-Member -MemberType NoteProperty -Name "Shared CPU" -Value $Dev_Shared_CPU
$obj | Add-Member -MemberType NoteProperty -Name "CP1 CPU" -Value $Dev_CP1_CPU
$obj | Add-Member -MemberType NoteProperty -Name "CP5 CPU" -Value $Dev_CP5_CPU
$obj | Add-Member -MemberType NoteProperty -Name "CP1 Usage" -Value (($Dev_CP1_CPU + ($Dev_Shared_CPU*$CP1Split)) / $Dev_Tot_CPU)
$obj | Add-Member -MemberType NoteProperty -Name "CP5 Usage" -Value (($Dev_CP5_CPU + ($Dev_Shared_CPU*$CP5Split)) / $Dev_Tot_CPU)
$Report += $obj

DisplayIt("Writing report file")
If (Test-Path -PathType Leaf $WorkDir\Temp.CSV) {
    $WorkFile = Import-CSV $WorkDir\Temp.CSV
    $NewWorkFile = $WorkFile + $Report
    $NewWorkFile|Export-Csv -NoTypeInformation $WorkDir\Temp.CSV
    }
    else
    {
    $Report|Export-CSV -NoTypeInformation $WorkDir\Temp.CSV
    }
Move-Item $InFile ($ProcessedDir+ "\" + $InFile.Name)

}

dir \\$env:CitrixDataServer\$env:USERNAME\LOGSTATS\In\*.csv|foreach{
    ProcessCSV -InFile $_.FullName -WorkDir \\$env:CitrixDataServer\$env:USERNAME\LOGSTATS\WorkingDir -ProcessedDir \\$env:CitrixDataServer\$env:USERNAME\LOGSTATS\Processed
}
 
<#ProcessCSV -InFile \\##REDACTED##\LOGSTATS\In\LOGSTATS_ALLBATCH_010915.CSV -WorkDir \\##REDACTED##\LOGSTATS\WorkingDir -ProcessedDir \\##REDACTED##\LOGSTATS\Processed
ProcessCSV -InFile \\##REDACTED##\LOGSTATS\In\LOGSTATS_ALLBATCH_020915.CSV -WorkDir \\##REDACTED##\LOGSTATS\WorkingDir -ProcessedDir \\##REDACTED##\LOGSTATS\Processed
ProcessCSV -InFile \\##REDACTED##\LOGSTATS\In\LOGSTATS_ALLBATCH_030915.CSV -WorkDir \\##REDACTED##\LOGSTATS\WorkingDir -ProcessedDir \\##REDACTED##\LOGSTATS\Processed
ProcessCSV -InFile \\##REDACTED##\LOGSTATS\In\LOGSTATS_ALLBATCH_040915.CSV -WorkDir \\##REDACTED##\LOGSTATS\WorkingDir -ProcessedDir \\##REDACTED##\LOGSTATS\Processed
ProcessCSV -InFile \\##REDACTED##\LOGSTATS\In\LOGSTATS_ALLBATCH_050915.CSV -WorkDir \\##REDACTED##\LOGSTATS\WorkingDir -ProcessedDir \\##REDACTED##\LOGSTATS\Processed
ProcessCSV -InFile \\##REDACTED##\LOGSTATS\In\LOGSTATS_ALLBATCH_060915.CSV -WorkDir \\##REDACTED##\LOGSTATS\WorkingDir -ProcessedDir \\##REDACTED##\LOGSTATS\Processed
ProcessCSV -InFile \\##REDACTED##\LOGSTATS\In\LOGSTATS_ALLBATCH_070915.CSV -WorkDir \\##REDACTED##\LOGSTATS\WorkingDir -ProcessedDir \\##REDACTED##\LOGSTATS\Processed
ProcessCSV -InFile \\##REDACTED##\LOGSTATS\In\LOGSTATS_ALLBATCH_080915.CSV -WorkDir \\##REDACTED##\LOGSTATS\WorkingDir -ProcessedDir \\##REDACTED##\LOGSTATS\Processed
ProcessCSV -InFile \\##REDACTED##\LOGSTATS\In\LOGSTATS_ALLBATCH_090915.CSV -WorkDir \\##REDACTED##\LOGSTATS\WorkingDir -ProcessedDir \\##REDACTED##\LOGSTATS\Processed
ProcessCSV -InFile \\##REDACTED##\LOGSTATS\In\LOGSTATS_ALLBATCH_100915.CSV -WorkDir \\##REDACTED##\LOGSTATS\WorkingDir -ProcessedDir \\##REDACTED##\LOGSTATS\Processed
ProcessCSV -InFile \\##REDACTED##\LOGSTATS\In\LOGSTATS_ALLBATCH_110915.CSV -WorkDir \\##REDACTED##\LOGSTATS\WorkingDir -ProcessedDir \\##REDACTED##\LOGSTATS\Processed
ProcessCSV -InFile \\##REDACTED##\LOGSTATS\In\LOGSTATS_ALLBATCH_120915.CSV -WorkDir \\##REDACTED##\LOGSTATS\WorkingDir -ProcessedDir \\##REDACTED##\LOGSTATS\Processed
ProcessCSV -InFile \\##REDACTED##\LOGSTATS\In\LOGSTATS_ALLBATCH_130915.CSV -WorkDir \\##REDACTED##\LOGSTATS\WorkingDir -ProcessedDir \\##REDACTED##\LOGSTATS\Processed
ProcessCSV -InFile \\##REDACTED##\LOGSTATS\In\LOGSTATS_ALLBATCH_140915.CSV -WorkDir \\##REDACTED##\LOGSTATS\WorkingDir -ProcessedDir \\##REDACTED##\LOGSTATS\Processed
ProcessCSV -InFile \\##REDACTED##\LOGSTATS\In\LOGSTATS_ALLBATCH_150915.CSV -WorkDir \\##REDACTED##\LOGSTATS\WorkingDir -ProcessedDir \\##REDACTED##\LOGSTATS\Processed
ProcessCSV -InFile \\##REDACTED##\LOGSTATS\In\LOGSTATS_ALLBATCH_160915.CSV -WorkDir \\##REDACTED##\LOGSTATS\WorkingDir -ProcessedDir \\##REDACTED##\LOGSTATS\Processed
ProcessCSV -InFile \\##REDACTED##\LOGSTATS\In\LOGSTATS_ALLBATCH_170915.CSV -WorkDir \\##REDACTED##\LOGSTATS\WorkingDir -ProcessedDir \\##REDACTED##\LOGSTATS\Processed
ProcessCSV -InFile \\##REDACTED##\LOGSTATS\In\LOGSTATS_ALLBATCH_180915.CSV -WorkDir \\##REDACTED##\LOGSTATS\WorkingDir -ProcessedDir \\##REDACTED##\LOGSTATS\Processed
ProcessCSV -InFile \\##REDACTED##\LOGSTATS\In\LOGSTATS_ALLBATCH_190915.CSV -WorkDir \\##REDACTED##\LOGSTATS\WorkingDir -ProcessedDir \\##REDACTED##\LOGSTATS\Processed
ProcessCSV -InFile \\##REDACTED##\LOGSTATS\In\LOGSTATS_ALLBATCH_200915.CSV -WorkDir \\##REDACTED##\LOGSTATS\WorkingDir -ProcessedDir \\##REDACTED##\LOGSTATS\Processed
ProcessCSV -InFile \\##REDACTED##\LOGSTATS\In\LOGSTATS_ALLBATCH_210915.CSV -WorkDir \\##REDACTED##\LOGSTATS\WorkingDir -ProcessedDir \\##REDACTED##\LOGSTATS\Processed
ProcessCSV -InFile \\##REDACTED##\LOGSTATS\In\LOGSTATS_ALLBATCH_220915.CSV -WorkDir \\##REDACTED##\LOGSTATS\WorkingDir -ProcessedDir \\##REDACTED##\LOGSTATS\Processed
ProcessCSV -InFile \\##REDACTED##\LOGSTATS\In\LOGSTATS_ALLBATCH_230915.CSV -WorkDir \\##REDACTED##\LOGSTATS\WorkingDir -ProcessedDir \\##REDACTED##\LOGSTATS\Processed
ProcessCSV -InFile \\##REDACTED##\LOGSTATS\In\LOGSTATS_ALLBATCH_240915.CSV -WorkDir \\##REDACTED##\LOGSTATS\WorkingDir -ProcessedDir \\##REDACTED##\LOGSTATS\Processed
ProcessCSV -InFile \\##REDACTED##\LOGSTATS\In\LOGSTATS_ALLBATCH_250915.CSV -WorkDir \\##REDACTED##\LOGSTATS\WorkingDir -ProcessedDir \\##REDACTED##\LOGSTATS\Processed
ProcessCSV -InFile \\##REDACTED##\LOGSTATS\In\LOGSTATS_ALLBATCH_260915.CSV -WorkDir \\##REDACTED##\LOGSTATS\WorkingDir -ProcessedDir \\##REDACTED##\LOGSTATS\Processed
ProcessCSV -InFile \\##REDACTED##\LOGSTATS\In\LOGSTATS_ALLBATCH_270915.CSV -WorkDir \\##REDACTED##\LOGSTATS\WorkingDir -ProcessedDir \\##REDACTED##\LOGSTATS\Processed
ProcessCSV -InFile \\##REDACTED##\LOGSTATS\In\LOGSTATS_ALLBATCH_280915.CSV -WorkDir \\##REDACTED##\LOGSTATS\WorkingDir -ProcessedDir \\##REDACTED##\LOGSTATS\Processed
ProcessCSV -InFile \\##REDACTED##\LOGSTATS\In\LOGSTATS_ALLBATCH_290915.CSV -WorkDir \\##REDACTED##\LOGSTATS\WorkingDir -ProcessedDir \\##REDACTED##\LOGSTATS\Processed
ProcessCSV -InFile \\##REDACTED##\LOGSTATS\In\LOGSTATS_ALLBATCH_300915.CSV -WorkDir \\##REDACTED##\LOGSTATS\WorkingDir -ProcessedDir \\##REDACTED##\LOGSTATS\Processed
#>

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
(Get-Content $InFile -Raw) -replace [string][char]0 | Set-Content $InFile -Force
$Inp = Import-Csv $InFile
$Table = $Inp | Select USERCODE,JOBNAME,MIXNUM,TASKNUM,BEGINDATE,BEGINTIME,ENDDATE,ENDTIME,DCKEYIN,MANUAL,JOBSTATUS,JOBTYPE,CPUTIME,IOTIME,ELAPSED,SYSTEM,"RUNTIME PARAMETERS"

$AllStats = $Table|Measure-Object CPUTIME -Sum|select Count,Sum
$ProdAllStats = $Table|Where-Object {$_.SYSTEM -eq "99999"}|Measure-Object CPUTIME -Sum|Select Count,Sum
$DevAllStats = $Table|Where-Object {$_.SYSTEM -eq "99998"}|Measure-Object CPUTIME -Sum|Select Count,Sum 

$CP1_Or_SharedJobs = $Table | Where-Object {!($_.JOBNAME -like '*CP5*' -or $_.JOBNAME -like '*CP6*' -or $_."RUNTIME_PARAMETERS" -like '*CP5*' -or $_."RUNTIME_PARAMETERS" -like '*CP6*')}
$ProdCP1_Or_SharedStats = $CP1_Or_SharedJobs|Where-Object {$_.SYSTEM -eq "99999"}|Measure-Object CPUTIME -Sum|Select Count,Sum
$DevCP1_Or_SharedStats = $CP1_Or_SharedJobs|Where-Object {$_.SYSTEM -eq "99998"}|Measure-Object CPUTIME -Sum|Select Count,Sum

$CP5Jobs = $Table | Where-Object {$_.JOBNAME -like '*CP5*' -or $_.JOBNAME -like '*CP6*' -or $_."RUNTIME_PARAMETERS" -like '*CP5*' -or $_."RUNTIME_PARAMETERS" -like '*CP6*'}
$ProdCP5Stats = $CP5Jobs|Where-Object {$_.SYSTEM -eq "99999"}|Measure-Object CPUTIME -Sum|Select Count,Sum
$DevCP5Stats = $CP5Jobs|Where-Object {$_.SYSTEM -eq "99998"}|Measure-Object CPUTIME -Sum|Select Count,Sum

$Report = @()
If ($ProdAllStats.Count -gt 0){
$obj = New-Object System.Object
$obj | Add-Member -MemberType NoteProperty -Name Date -Value $Table[0].ENDDATE
$obj | Add-Member -MemberType NoteProperty -Name System -Value "PRODUCTION"
$obj | Add-Member -MemberType NoteProperty -Name "Total Batch Jobs" -Value $ProdAllStats.Count
$obj | Add-Member -MemberType NoteProperty -Name "Total CPU Seconds" -Value $ProdAllStats.Sum
$obj | Add-Member -MemberType NoteProperty -Name "CP1/Shared Jobs" -Value $ProdCP1_Or_SharedStats.Count
$obj | Add-Member -MemberType NoteProperty -Name "CP1/Shared CPU" -Value $ProdCP1_Or_SharedStats.Sum
$obj | Add-Member -MemberType NoteProperty -Name "CP5 Jobs" -Value $ProdCP5Stats.Count
$obj | Add-Member -MemberType NoteProperty -Name "CP5 CPU" -Value $ProdCP5Stats.Sum
$obj | Add-Member -MemberType NoteProperty -Name "%CP1/Shared Jobs" -Value (("{0:N2}" -f ($ProdCP1_Or_SharedStats.Count/$ProdAllStats.Count * 100) -As [String])+"%")
$obj | Add-Member -MemberType NoteProperty -Name "%CP1/Shared CPU" -Value (("{0:N2}" -f ($ProdCP1_Or_SharedStats.Sum/$ProdAllStats.Sum * 100) -As [String])+"%")
$obj | Add-Member -MemberType NoteProperty -Name "%CP5 Jobs" -Value (("{0:N2}" -f ($ProdCP5Stats.Count/$ProdAllStats.Count * 100) -As [String])+"%")
$obj | Add-Member -MemberType NoteProperty -Name "%CP5 CPU" -Value (("{0:N2}" -f ($ProdCP5Stats.Sum/$ProdAllStats.Sum * 100) -As [String])+"%")
$Report += $obj
}

If ($DevAllStats.Count -gt 0){
$obj = New-Object System.Object
$obj | Add-Member -MemberType NoteProperty -Name Date -Value $Table[0].ENDDATE
$obj | Add-Member -MemberType NoteProperty -Name System -Value "DEVELOPMENT"
$obj | Add-Member -MemberType NoteProperty -Name "Total Batch Jobs" -Value $DevAllStats.Count
$obj | Add-Member -MemberType NoteProperty -Name "Total CPU Seconds" -Value $DevAllStats.Sum
$obj | Add-Member -MemberType NoteProperty -Name "CP1/Shared Jobs" -Value $DevCP1_Or_SharedStats.Count
$obj | Add-Member -MemberType NoteProperty -Name "CP1/Shared CPU" -Value $DevCP1_Or_SharedStats.Sum
$obj | Add-Member -MemberType NoteProperty -Name "CP5 Jobs" -Value $DevCP5Stats.Count
$obj | Add-Member -MemberType NoteProperty -Name "CP5 CPU" -Value ($DevCP5Stats.Sum -as [double])
$obj | Add-Member -MemberType NoteProperty -Name "%CP1/Shared Jobs" -Value (("{0:N2}" -f ($DevCP1_Or_SharedStats.Count/$DevAllStats.Count * 100) -As [String])+"%")
$obj | Add-Member -MemberType NoteProperty -Name "%CP1/Shared CPU" -Value (("{0:N2}" -f ($DevCP1_Or_SharedStats.Sum/$DevAllStats.Sum * 100) -As [String])+"%")
$obj | Add-Member -MemberType NoteProperty -Name "%CP5 Jobs" -Value (("{0:N2}" -f ($DevCP5Stats.Count/$DevAllStats.Count * 100) -As [String])+"%")
$obj | Add-Member -MemberType NoteProperty -Name "%CP5 CPU" -Value (("{0:N2}" -f ($DevCP5Stats.Sum/$DevAllStats.Sum * 100) -As [String])+"%")
$Report += $obj
}

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

ProcessCSV -InFile \\##REDACTED##\LOGSTATS\In\LOGSTATS_ALLBATCH_160715.CSV -WorkDir \\##REDACTED##\LOGSTATS\WorkingDir -ProcessedDir \\##REDACTED##\LOGSTATS\Processed

<#    
    $htmlpre = (gc K:\batch_pre.htm) -replace 'Unisys Batch Stats','Unisys Batch Stats 02/06/2015'
    $htmltab = $Report|ConvertTo-Html -fragment
    $htmlpost = gc K:\batch_post.htm
    ($htmlpre + $htmltab + $htmlpost)|out-file K:\LOGSTATS_ALLBATCH_20150602165021.HTML
#>
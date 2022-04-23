(Get-Content \\##REDACTED##\LOGSTATS_20150622080511.CSV -Raw) -replace [string][char]0 | Set-Content \\##REDACTED##\LOGSTATS_20150622080511.CSV -Force
$Inp = Import-Csv \\##REDACTED##\LOGSTATS_20150622080511.CSV
$ExcludeStrings = @(
'BLAH',
'BLAH2',
'BLAH3'
)
#$Table = $Inp | where-object {($_.SYSTEM -eq 9999) -and ($_.USERCODE -eq "##REDACTED##")} | Select REFNUM,USERCODE,JOBNAME,"RUNTIME PARAMETERS",MIXNUM,TASKNUM,BEGINDATE,BEGINTIME,ENDDATE,ENDTIME,JOBSTATUS,ELAPSED,AVG_ELAPSED
$Table = $Inp | where-object {($_.MIXNUM -ne "00000") -and ($_.TASKNUM -ne "00000") -and ($_.REFNUM -gt 0)} | Select REFNUM,USERCODE,JOBNAME,"RUNTIME PARAMETERS",MIXNUM,TASKNUM,BEGINDATE,BEGINTIME,ENDDATE,ENDTIME,JOBSTATUS,ELAPSED,AVG_ELAPSED
#$Filtered = $Table|Foreach { $line = $_;Foreach ($pattern in $ExcludeStrings) {If (!($line.JOBNAME -like $pattern)) {$line} else {$null}}}
$Filtered = $Table|Select-String -Pattern $ExcludeStrings -NotMatch -SimpleMatch
$FilteredArray = @()
$Filtered.Line | foreach {$split = $_ -split ';';
                          $tidied = $split -replace '@|{|}|^ ';
                          $obj = New-Object System.Object
                          $tidied|foreach { If ($_ -like 'JOBNAME*'){
                                                     $obj|Add-Member -MemberType NoteProperty -Name "SUITE" -Value ($_.split('=')[1].SubString(0,2))
                                                     $obj|Add-Member -MemberType NoteProperty -Name ($_.split('=')[0]) -Value ($_.split('=')[1])
                                                     }
                                            elseif (($_ -like 'ELAPSED*') -or ($_ -like 'AVG_ELAPSED*')) {
                                                        $timestring=($_.split('=')[1]);
                                                        $obj|Add-Member -MemberType NoteProperty -Name ($_.split('=')[0]) -Value (([TimeSpan]::Parse($timestring).TotalSeconds/86400))
                                                        } 
                                                      else {
                                            $obj|Add-Member -MemberType NoteProperty -Name ($_.split('=')[0]) -Value ($_.split('=')[1])
                                            } }
                          $FilteredArray += $obj  
                            }
$FilteredArray| Sort BEGINDATE,JOBNAME,BEGINTIME | Export-Csv K:\GG_BL_TEST.CSV -NoType

<#
$file = "\\##REDACTED##\GG_BL_TEST.CSV"
$excel = New-Object -ComObject excel.application
$excel.Visible = $true
$workbook = $excel.workbooks.open($file)
$workbook.ActiveSheet.Columns.Item('I').NumberFormat = "0000"
$workbook.ActiveSheet.Columns.Item('K').NumberFormat = "0000"
$workbook.ActiveSheet.Columns.Item('M').NumberFormat = "[hh]:mm"
$workbook.ActiveSheet.Columns.Item('N').NumberFormat = "[hh]:mm"
$excel.ActiveSheet.UsedRange.Select()
$excel.Selection.AutoFilter()
$excel.ActiveSheet.Name = "LOGSTATS"
$workbook.Worksheets.Add()
$workbook.Worksheets.Item(2).Copy($workbook.Worksheets.Item(1))
$workbook.Worksheets.Item(2).Delete()
$workbook.Worksheets.Item(2).Name = "LOGSTATS(2HR)"
$workbook.Worksheets.Item(1).Name = "LOGSTATS"
$workbook.Worksheets.Item(2).Activate()
$excel.Selection.AutoFilter(13,">02:00",0,0,0)
#>

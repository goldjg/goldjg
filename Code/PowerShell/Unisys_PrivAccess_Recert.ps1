<#
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
| Unisys_PrivAccess_Recert.ps1                                                          |
| Version: 1.0                                                                          |
| Author: Graham Gold                                                                   |
| Description: Process output from run of ##REDACTED##.txt         |
|              (run in Locum AdminDesk) and produce reports of members of privileged    |
|              roles:                                                                   |
|                   $ROL_1                                                          |
|                   $ROL_2                                                      |
|                   $ROL_3                                                            |
|                   $ROL_4                                                            |
|              Email report to managers of the teams that own those roles, CCing        |
|              the ##REDACTED## and ##REDACTED## mailboxes.   |
|                                                                                       |
|_______________________________________________________________________________________|
| Version History                                                                       |
| ===============                                                                       |
| Version 1.0 - Initial Implementation                                                  |
|                                                                                       |
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#>

param (
        [Parameter(Mandatory=$false)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$filein="\\$Env:HomeDataServer\$Env:USERNAME\##REDACTED##.out",

        [Parameter(Mandatory=$false)]
        [ValidateScript({$_|foreach{
                            If($_ -match "[a-zA-Z0-9.!£#$%&'^_`{}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*"){$true}else{
                                throw "$_ is not a properly formatted, fully qualified email address (mailbox@domainname)."}}})]
        [string[]]$GRP1Mail=@("##REDACTED##", "##REDACTED##", "##REDACTED##"),

        [Parameter(Mandatory=$false)]
        [ValidateScript({$_|foreach{
                            If($_ -match "[a-zA-Z0-9.!£#$%&'^_`{}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*"){$true}else{
                                throw "$_ is not a properly formatted, fully qualified email address (mailbox@domainname)."}}})]
        [string[]]$GRP4Mail =@("##REDACTED##", "##REDACTED##", "##REDACTED##"),

        [Parameter(Mandatory=$false)]
        [ValidateScript({$_|foreach{
                            If($_ -match "[a-zA-Z0-9.!£#$%&'^_`{}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*"){$true}else{
                                throw "$_ is not a properly formatted, fully qualified email address (mailbox@domainname)."}}})]
        [string[]]$GRP3Mail=@("##REDACTED##", "##REDACTED##","##REDACTED##"),

        [Parameter(Mandatory=$false)]
        [ValidateScript({If($_ -in "GRP3","GRP4","GRP1"){$true}else{
                                throw "$_ is not an available report type - must be one or more of GRP4, GRP3 or GRP1"}})]
        [string[]]$RepsToRun=@("GRP3","GRP4","GRP1")

)
#$ErrorActionPreference="Stop"
Write-Host -ForegroundColor Green "Parameter Validation Successful "
Write-Host "`r`nProcessing input file $filein and filtering out users without ROL_ groups..."

$PrivList = (get-content $filein|select-string -Pattern ROL_).Line

Write-Host -ForegroundColor Green "File read OK, filtered "
$ary=@()

Write-Host "`r`nBuilding assignment table..."
$PrivList|foreach {
    $obj = New-Object System.Object
    $obj| Add-Member -MemberType NoteProperty -Name ID -Value ($_.Split(" ")[1].Split(" ")[0])
    $obj| Add-Member -MemberType NoteProperty -Name Name -Value ($_.Split('"')[1].Split('"')[0])
    $obj| Add-Member -MemberType NoteProperty -Name Email -Value ($_.Split('"')[3].Split('"')[0])
    If (($_.Split("=")[3].Split(",")[0]).TrimStart() -ne "0"){
        $obj| Add-Member -MemberType NoteProperty -Name LastLogon -Value (($_.Split("=")[3].Split(",")[0]).TrimStart())} else{
        $obj| Add-Member -MemberType NoteProperty -Name LastLogon -Value "No recorded logons"}
    If (($_.Split("=")[4].Split(",")[0] -eq 1)){
        $obj| Add-Member -MemberType NoteProperty -Name Suspended -Value Y} else {
        $obj| Add-Member -MemberType NoteProperty -Name Suspended -Value N}
    If ($_.Split("=")[5] -like '*ROL_4*'){
        $obj| Add-Member -MemberType NoteProperty -Name "ROL_4" -Value Y} else {
        $obj| Add-Member -MemberType NoteProperty -Name "ROL_4" -Value N}
    If ($_.Split("=")[5] -like '*ROL_3*'){
        $obj| Add-Member -MemberType NoteProperty -Name "ROL_3" -Value Y} else {
        $obj| Add-Member -MemberType NoteProperty -Name "ROL_3" -Value N}
    If ($_.Split("=")[5] -like '*ROL_1*'){
        $obj| Add-Member -MemberType NoteProperty -Name "ROL_1" -Value Y} else {
        $obj| Add-Member -MemberType NoteProperty -Name "ROL_1" -Value N}
    If ($_.Split("=")[5] -like '*ROL_2*'){
        $obj| Add-Member -MemberType NoteProperty -Name "ROL_2" -Value Y} else {
        $obj| Add-Member -MemberType NoteProperty -Name "ROL_2" -Value N}
    $ary += $obj
}

Write-Host -ForegroundColor Green "Assignment table build complete "
Write-Host "`r`nCreating GRP1, GRP4, GRP3 filtered lists..."
$GRP1List = $ary|where {$_.ROL_1 -like "*Y" -or $_.ROL_2 -like "*Y"}
$GRP4List = $ary|where {$_.ROL_4 -like "*Y"}
$GRP3List = $ary|where {$_.ROL_3 -like "*Y"}

Write-Host -ForegroundColor Green "Filtered lists created "
Write-Host "`r`nInitialising reports..."
$ReportMonth=Get-Date -UFormat "%B %Y"
$ReportProduced=Get-Date -UFormat %c
$ReplyBy=(Get-date).AddDays(14).ToShortDateString()

$Head='<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">'+`
'<html xmlns="http://www.w3.org/1999/xhtml">'+`
'<head><title>Privileged Access Audit - '+$ReportMonth+'</title>'+`
'</head><body>Hi,<BR>'+`
'As part of the monthly ##REDACTED## privileged ID review, can you please confirm that the below members of staff in your teams'+`
' and system IDs owned by your area still require this access? We need a response if you wish to retain the access.<BR><BR>'

$GRP1Body=($GRP1List|Select ID,Name,EMail,LastLogon,Suspended,ROL_1,ROL_2|ConvertTo-Html -Fragment)
$GRP4Body=($GRP4List|Select ID,Name,EMail,LastLogon,Suspended,ROL_4|ConvertTo-Html -Fragment)
$GRP3Body=($GRP3List|Select ID,Name,EMail,LastLogon,Suspended,ROL_3|ConvertTo-Html -Fragment)

$Foot='<BR>If you do not respond within two weeks of this email, we will assume the access is no longer required and the ID will be'+`
' disabled and one week after that, we will delete the ID.<BR><BR>'+`
'If you do still wish to retain an account, we will need a yes and a confirmation of which account/accounts you still need.<BR>'+`
'Please ensure you reply by <B>'+$ReplyBy+'</B>.<BR><BR>If you have any questions please let me know.<BR><BR>'+`
'<B>Report issued '+$ReportProduced+'</B></body></html>'

Write-Host -ForegroundColor Green "Report initialisation complete - finalising and emailing requested reports: $RepsToRun "

If ("GRP1" -in $RepsToRun){Send-MailMessage -To $GRP1Mail -Subject ("Monthly Privileged Access Audit - "+$ReportMonth) `
-From "##REDACTED##" -BodyAsHtml ($Head+$GRP1Body+$Foot) -SmtpServer ##REDACTED##}

If ("GRP4" -in $RepsToRun){Send-MailMessage -To $GRP4Mail -Subject ("Monthly Privileged Access Audit - "+$ReportMonth) `
-From "##REDACTED##" -BodyAsHtml ($Head+$GRP4Body+$Foot) -SmtpServer ##REDACTED##}

If ("GRP3" -in $RepsToRun){Send-MailMessage -To $GRP3Mail -Subject ("Monthly Privileged Access Audit - "+$ReportMonth) `
-From "##REDACTED##" -BodyAsHtml ($Head+$GRP3Body+$Foot) -SmtpServer ##REDACTED##}
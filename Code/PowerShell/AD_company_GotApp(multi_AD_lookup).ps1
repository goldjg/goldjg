$infile = import-csv -Path "K:\blah.CSV"
$outfile = @()
$infile|foreach{
    $obj = New-Object System.Object
    $obj | Add-Member -MemberType NoteProperty -Name "User Id" -Value $_."User Id"
    $obj | Add-Member -MemberType NoteProperty -Name Station   -Value $_.Station
    $obj | Add-Member -MemberType NoteProperty -Name Company   -Value $_.Company
    $obj | Add-Member -MemberType NoteProperty -Name Logon     -Value $_.Logon
    $obj | Add-Member -MemberType NoteProperty -Name Window    -Value $_.Window
    If ($_."User Id" -like '##REDACTED##'){
        If (((Get-ADPrincipalGroupMembership -Identity $_."User Id"|select name|where{$_.name -eq '##REDACTED##'})|Measure-Object).Count -eq 1){
            $APP = "Y"} else {
            $APP = "N"}
        }
        else
        {
            $APP = "N/A - Not ##REDACTED##"
        }
    $obj | Add-Member -MemberType NoteProperty -Name ##REDACTED## -Value $APP
    $outfile += $obj
    }
    $outfile|export-csv -Path "K:\OUT.CSV" -NoTypeInformation

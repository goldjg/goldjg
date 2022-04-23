$infile = import-csv -Path "K:\blah.CSV"
$outfile = @()
$APPUSERs = Get-ADGroupMember -Identity VA_APPCCF|select name
$infile|foreach{
    $obj = New-Object System.Object
    $obj | Add-Member -MemberType NoteProperty -Name "User Id" -Value $_."User Id"
    $obj | Add-Member -MemberType NoteProperty -Name Station   -Value $_.Station
    $obj | Add-Member -MemberType NoteProperty -Name Company   -Value $_.Company
    $obj | Add-Member -MemberType NoteProperty -Name Logon     -Value $_.Logon
    $obj | Add-Member -MemberType NoteProperty -Name Window    -Value $_.Window
    $user = $_."User Id"
        If ($user -like '*'){
        If (($APPUSERs|Where-Object{$_.name -eq $user}|Measure-Object).Count -eq 1){
            $APP = "Y"} else {
            $APP = "N"}
        }
        else
        {
            $APP = "N/A - Not COMP"
        }
    $obj | Add-Member -MemberType NoteProperty -Name APPUser   -Value $APP
    $outfile += $obj
    }
    $outfile|export-csv -Path "K:\COMPTEL_APP.CSV" -NoTypeInformation

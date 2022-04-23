$SrcData = gc K:\HOST_CONNECTIONS.TXT|select-string -Pattern ADDRESS

$out= @()
$SrcData |Select Line -Unique | foreach {
          $obj = New-Object System.Object
          $obj|Add-Member -MemberType NoteProperty -Name "Mainframe IP" -Value $_.Line.ToString().Split(":")[1].Split(" ")[1]
          $obj|Add-Member -MemberType NoteProperty -Name "Client IP"    -Value $_.Line.ToString().Split(":")[2].Split(" ")[1]
          $out += $obj
}
rv SrcData
$out|Export-CSV -Path K:\Host_CONNECTIONS.CSV -NoTypeInformation
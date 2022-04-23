$SrcData = Import-Csv K:\HOST_CONNECTIONS.CSV
$out = @()
$SrcData |foreach {
          $obj = New-Object System.Object
          $obj|Add-Member -MemberType NoteProperty -Name "Mainframe IP"  -Value $_."Mainframe IP"
          $obj|Add-Member -MemberType NoteProperty -Name "Mainframe DNS" -Value (nslookup $_."Mainframe IP"|select-string Name).Line.ToString().Replace(" ","").Split(":")[1]
          $obj|Add-Member -MemberType NoteProperty -Name "Client IP"     -Value $_."Client IP"
          $obj|Add-Member -MemberType NoteProperty -Name "Client DNS"    -Value (nslookup $_."Client IP"|select-string Name).Line.ToString().Replace(" ","").Split(":")[1]

          $out += $obj
}
rv SrcData
$out|Export-CSV -Path K:\HOST_CONNECTIONS_DNS.CSV -NoTypeInformation
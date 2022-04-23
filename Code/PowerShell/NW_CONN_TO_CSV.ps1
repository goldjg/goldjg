<# NW TCPIP CONN OUTPUT Parser - turns below into CSV output
      TCP CONNECTION ID = 10                                                    
      FILENAME = FILE_1                                                  
      MY NAME = 1234                                                           
      YOUR NAME = 45321                                                         
      STATE = ESTABLISHED                                                       
      YOUR IP ADDRESS 1.2.3.3                                                
      PROTOCOL STACK = LEGACY,                                                  
                                                                                
      TCP CONNECTION ID = 11                                                    
      FILENAME = MY_PORT                                                        
      MY NAME = 9999                                                           
      YOUR NAME = 54231                                                         
      STATE = ESTABLISHED                                                       
      YOUR IP ADDRESS 9.8.7.6                                               
      PROTOCOL STACK = LEGACY, 
#>

$srcData = (gc K:\PROD_LIVE_TCP_CONNS.TXT|select -Skip 8) -join ',' `
            -replace ' ','' `
            -replace ',,',"`r`n" `
            -replace ',TCPCONNECTIONID=','' `
            -replace 'TCPCONNECTIONID=',''`
            -replace 'FILENAME=','' `
            -replace 'MYNAME=','' `
            -replace 'YOURNAME=','' `
            -replace 'STATE=','' `
            -replace 'YOURIPADDRESS','' `
            -replace 'PROTOCOLSTACK=','' 
$outfile = @()
$srcdata -split "`r`n"|where-object {$_ -notlike ''}|foreach {
                    $obj = New-Object System.Object
                    $inparr = $_.Split(",")
                    $obj|Add-Member -MemberType NoteProperty   -Name Connection_ID  -Value $inparr[0]
                    $obj|Add-Member -MemberType NoteProperty   -Name Filename       -Value $inparr[1]
                    $obj|Add-Member -MemberType NoteProperty   -Name MCP_Port       -Value $inparr[2]
                    $obj|Add-Member -MemberType NoteProperty   -Name Client_Port    -Value $inparr[3]
                    $obj|Add-Member -MemberType NoteProperty   -Name Port_State     -Value $inparr[4]
                    $obj|Add-Member -MemberType NoteProperty   -Name Client_IP      -Value $inparr[5]
                    $ErrorActionPreference = "Stop"
                    $Client_DNS_V = If ($obj.Port_State -ne "LISTEN") {Try { (NSLOOKUP $inparr[5] |Select-String Name).Line.ToString().Replace(" ","").Split(":")[1]} Catch {}} else {""}
                    $ErrorActionPreference = "SilentlyContinue"
                    $obj|Add-Member -MemberType NoteProperty   -Name Client_DNS     -Value $Client_DNS_V
                    $obj|Add-Member -MemberType NoteProperty   -Name Protocol_Stack -Value $inparr[6]
                    $outfile += $obj
                    rv Client_DNS_V
}

$outfile|Export-Csv -Path K:\PROD_LIVE_TCP_CONNS.CSV -NoTypeInformation
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

$srcData = (gc K:\Dev_LIVE_TCP_CONNS.TXT|select -Skip 8) -join ',' `
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

$outfile = $srcdata -split "[\r\n]" | % {
    $v = $_.Split(",")
    $re = [regex]::match((NSLOOKUP $v[5]), '(?<=Name:\s+)[^\s]+')

    New-Object psobject -Property @{
        Client_DNS = @('', $re.value)[$re.success] 
        Connection_ID = $v[0]
        Filename = $v[1]
        MCP_Port = $v[2]
        Client_Port = $v[3]
        Port_State = $v[4]
        Client_IP = $v[5]
        Protocol_Stack = $v[6]
    }
}
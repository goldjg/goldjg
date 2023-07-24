<# 
.SYNOPSIS 
  Autom8 Service Core API Code
  
.DESCRIPTION 
  Accepts API Calls to download Requested script from Azure DevOps Repo and execute.
  Repo: https://dev.azure.com/myorg/Autom8/_git/Autom8-RUN
  No parameters - script is executed as a service by NSSM service wrapper and thereafter accepts
   input from API calls (either to execute scripts from the above repo or to control the service itself)
#>
# Check https://www.powershellgallery.com/packages/HttpListener/1.0.2/Content/HTTPListener.psm1

$DNS = Get-ComputerInfo -Property CsName,CsDomain
$IPAddr = Get-NetIPAddress -InterfaceAlias Ethernet -AddressFamily IPv4 | Select -ExpandProperty IPAddress
$ListenPort = "22999"
$ListenSchema = "http://"
$ListenURL1 = "$($ListenSchema)$($DNS.CsName).$($DNS.CsDomain):$($ListenPort)/"
$ListenURL2 = "$($ListenSchema)$($IPAddr):$($ListenPort)"
$ListenURL3 = "$($ListenSchema)localhost:$($ListenPort)"

# Create an http listener on port 22999
$Listener = New-Object System.Net.HttpListener
$Listener.Prefixes.Add("$ListenURL1")
$Listener.Prefixes.Add("$ListenURL2")
$Listener.Prefixes.Add("$ListenURL3")
$Listener.Start()
Write-Host "Listening..."

# Run until you send a GET Request to /terminate
While ($True) {
    $Context = $Listener.GetContextAsync() 

    # Capture the details about the request
    $Request = $Context.Request

    # Setup a place to deliver a Response
    $Response = $Context.Response
   
    # Break from loop if GET Request sent to /terminate
    If ($Request.Url -match '/terminate$' -and ($Request.HttpMethod -eq "POST")) { 
        Break 
    } else {

      # Split Request URL to get command and options
      $Requestvars = ([String]$Request.Url).split("/");

      # If a Request is sent to http:// :22999/runScript
      If ($Requestvars[3] -eq "runScript") {

        Start-Process PowerShell -ArgumentList "-File","C:\Autom8\Autom8-Runner.ps1 -ScriptPath $ScriptPath -ScriptID $RunID -ScriptArgs $ScriptArgs"
    
        # Convert the returned data to JSON and set the HTTP content type to JSON
        $Message = $Result | ConvertTo-Json; 
        $Response.ContentType = 'application/json'
        $Response.StatusCode = 200

      } elseif ($Requestvars[3] -eq "runScriptElevated") {
        # If a Request is sent to http:// :22999/runScript

        Start-Process PowerShell -Verb RunAs -ArgumentList "-File","C:\Autom8\Autom8-Runner.ps1 -ScriptPath $ScriptPath -ScriptID $RunID -ScriptArgs $ScriptArgs"

        # Convert the returned data to JSON and set the HTTP content type to JSON
        $Message = $Result | ConvertTo-Json
        $Response.ContentType = 'application/json'
        $Response.StatusCode = 200

      } else {

        # If no matching subdirectory/route is found generate a 404 message
        $Message = "This is not the page you're looking for."
        $Response.ContentType = 'text/html'
        $Response.StatusCode = 404
      }

      # Convert the data to UTF8 bytes
      [byte[]]$Buffer = [System.Text.Encoding]::UTF8.GetBytes($Message)
      
      # Set length of Response
      $Response.ContentLength64 = $Buffer.length
      
      # Write Response out and close
      $Output = $Response.OutputStream
      $Output.Write($Buffer, 0, $Buffer.length)
      $Output.Close()
   }    
}
 
#Terminate the Listener
$Listener.Stop()

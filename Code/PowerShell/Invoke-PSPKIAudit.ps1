Start-Transcript -Path "C:\Users\Public\Autom8_log.txt" -Force
# Get an access token for managed identities for Azure resources
#$response = Invoke-WebRequest -Uri 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' `
#                                -Headers @{Metadata="true"} -UseBasicParsing
#$content =$response.Content | ConvertFrom-Json
#$access_token = $content.access_token

# Define clear text string for username and password

#[string]$userName = 'meh'

#$KVResponse = Invoke-WebRequest -Uri ("https://.vault.azure.net/secrets/$userName/?api-version=7.3") -Method GET -ContentType "application/json" -Headers @{ Authorization ="Bearer $access_token"} -UseBasicParsing

#$userPassword = $KVResponse.Content | ConvertFrom-Json | Select-Object -ExpandProperty value

# Convert to SecureString
#[securestring]$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force

#Create psCredential Object
#[pscredential]$credObject = New-Object System.Management.Automation.PSCredential (("dom\"+$userName), $secStringPassword)

#Remove variables for user\pass
#Remove-Variable userName,userpassword,secStringPassword, KVResponse

$codeBlock = {
Remove-Item C:\Users\Public\PSPKI*.txt -force -ErrorAction SilentlyContinue
Start-Transcript -Path "C:\Users\Public\PSPKI_runlog.txt" -Force

$servers = @{
    "s1" = "ca1"
    "s2" = "ca2"
}

Import-Module "C:\PSPKIAudit-main\PSPKIAudit-main\PSPKIAudit.psm1" -Force

foreach ($server in $servers.GetEnumerator()) {
    Invoke-PKIAudit -CAComputerName $server.Name -CAName $server.Value 2>&1 | Out-File $("C:\Users\Public\PSPKI_$($server.Name)_$($server.Value).txt")
}

Write-Output "Success" | Out-File "C:\Users\Public\trigger.me"

Stop-Transcript}

$codeBlock | Out-File "C:\Users\Public\Autom8_temp.ps1" -Width 4096 -Force

Start-Process powershell.exe -ArgumentList "-File C:\Users\Public\Autom8_temp.ps1" `
    -LoadUserProfile -WindowStyle Hidden -RedirectStandardError "C:\Users\Public\PSPKIErr.txt" -RedirectStandardOutput "C:\Users\Public\PSPKIOut.txt" -Verbose

While (!(Test-Path "C:\Users\Public\trigger.me")) { Start-Sleep 10 }

Remove-Item "C:\Users\Public\trigger.me" -Force

$compress = @{
  Path = "C:\Users\Public\PSPKI*.txt"
  CompressionLevel = "Fastest"
  DestinationPath = "C:\Users\Public\PSPKI.zip"
}
Compress-Archive @compress -Force

Send-MailMessage -SmtpServer srv -Subject PSPKIAuditTest `
        -To "to@to" -From "Autom8@Autom8" `
        -Attachments "C:\Users\Public\PSPKI.zip"

Stop-Transcript
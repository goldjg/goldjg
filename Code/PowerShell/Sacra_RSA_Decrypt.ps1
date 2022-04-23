$encrypted = Import-Clixml 'K:\e875dda5-bbaf-42f6-b3f0-b2cb355b1fe2.xml'            

$csp = New-Object System.Security.Cryptography.CspParameters
$csp.KeyContainerName = "Sacra"
#$csp.Flags = $csp.Flags -bor [System.Security.Cryptography.CspProviderFlags]::UseMachineKeyStore
$rsa = New-Object System.Security.Cryptography.RSACryptoServiceProvider -ArgumentList 5120,$csp
$rsa.PersistKeyInCsp = $true
$key = Import-Clixml 'K:\MySacraRSAKey.xml'
$rsa.FromXmlString($key)            

$enc = New-Object System.Text.ASCIIEncoding

$decbytes = $rsa.Decrypt($encrypted,$true)
$decrypted = $enc.GetString($decbytes)

Write-Host $decrypted
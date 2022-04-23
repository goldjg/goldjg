$csp = New-Object System.Security.Cryptography.CspParameters
$csp.KeyContainerName = "Sacra"
#$csp.Flags = $csp.Flags -bor [System.Security.Cryptography.CspProviderFlags]::UseMachineKeyStore
$rsa = New-Object System.Security.Cryptography.RSACryptoServiceProvider -ArgumentList 5120,$csp
$rsa.PersistKeyInCsp = $true
$rsa.ToXmlString($true)|Export-Clixml 'K:\MySacraRSAKey.xml'

$passin="Th3_8es7_p@5sw0rd-Ev4!"
$enc = New-Object System.Text.ASCIIEncoding
$passinbytes = $enc.GetBytes($passin)
$encpassbytes = $rsa.Encrypt($passinbytes,$true)
$encpassbytes | Export-Clixml 'K:\e875dda5-bbaf-42f6-b3f0-b2cb355b1fe2.xml'
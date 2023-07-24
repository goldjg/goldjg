
<# Define password as a securestring (do this as an input parameter - you pass the plaintext password as parameter to the script doing the encryption, so the plaintext is never in a variable you can forget to flush #>
[securestring]$strP = ConvertTo-SecureString 'MySuperSecurePassword' -AsPlainText -Force
$PasswordFile = "$ENV:USERPROFILE\Documents\rnd.txt" # OutFile Path for encrypted password.
$KeyFile = "$ENV:USERPROFILE\Documents\rnd.key" # Path to Generated AES Key. 

# Create Random AES Key in length specified in $Key variable.
Write-Host -ForegroundColor Yellow "Generating 256-bit AES Key"
[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
Write-Host -ForegroundColor Yellow "Encoding Key"
$bstrKey=[Convert]::ToBase64String($Key)

# Export Generated Key to File
Write-Host -ForegroundColor Yellow "Writing Key File with encoded encryption key"
$bstrKey | out-file $KeyFile 

# Combine Plaintext password with AES key to generate secure Password.
Write-Host -ForegroundColor Yellow "Encrypting password using key and writing to password file"
$strP | ConvertFrom-SecureString -key $Key | Out-File $PasswordFile
Write-Host -ForegroundColor Green "Flushing password variables"
$strP = $bstrKey = $Key = $null

<# Decryption #>
Write-Host -ForegroundColor Yellow "Decrypting password file using encryption key from file"
$inkey=Get-Content $KeyFile
$bkey=[Convert]::FromBase64CharArray($inkey,0,$inkey.Length)
$strPout = $(Get-Content $PasswordFile) | ConvertTo-SecureString -Key $bkey
$strPdec=System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($strPout))
Write-Host -ForegroundColor Magenta "Your password was $strPdec"
$inkey = $bkey = $strPout = $strPdec = $null
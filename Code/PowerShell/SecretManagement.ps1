<# 
.SYNOPSIS 
  Script to securely encrypt/store/decrypt a secret using AES Encryption
  
.DESCRIPTION 
  SecretManagement script in:
  
    - Encrypt mode: Supply a plaintext secret, 
        return an AES 256-bit encrypted string and the base64 string of the AES key

    - Decrypt mode: Supply an AES 265-bit encrypted string, 
        and the base 64 string of the AES key, return the decrypted secret in plaintext
.PARAMETER RunMode
<Mandatory> RunMode     : "Encrypt" or "Decrypt"
.PARAMETER InSecret 
  <Optional> InSecret   : Plaintext encrypted secret to be decrypted in runmode Decrypt
.PARAMETER InKey
  <Optional> InKey      : Plaintext base64 string of AES decryption key to be used in runmode Decrypt
.PARAMETER InPass
  <Optional> InPass     : Plaintext secret to be encrypted in runmode Encrypt
#>
Param
(
	
    [Parameter(Mandatory = $true)]
    [ValidateSet("Encrypt", "Decrypt")]
    [String]$RunMode,

    [Parameter(Mandatory = $False)]
    [String]$InSecret,

    [Parameter(Mandatory = $False)]
    [String]$InKey,

    [Parameter(Mandatory = $False)]
    [String]$InPass

)

Function Encrypt($pIn){
    Write-Verbose $pIn
     # Byte Array for AES Key. Sizes for byte count are 16 (128) 24 (192) 32 (256).
    $Key = New-Object Byte[] 32
    
    Write-Verbose "[INFO] Generating 256-bit AES Key"
    [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
    
    # Encode as base 64 String for easier portability
    Write-Verbose "[INFO] Encoding Key"
    $bstrKey=[Convert]::ToBase64String($Key)
    
    Write-Verbose "[INFO] Encrypting password using key and writing to password file"

    $secstrP = $pIn | ConvertFrom-SecureString -key $Key

    Write-Verbose "[INFO] Exiting and returning encrypted secret and key"

    $EnHash = @{
        'EK' = $bstrKey
        'ES' = $secstrP
    }

    Return $EnHash

}

Function Decrypt($skIn){
    Write-Verbose "[INFO] Decoding Key"
    $b64key=$($skIn.K)
    $key=[Convert]::FromBase64CharArray($b64key,0,$b64key.Length)

    Write-Verbose "[INFO] Decrypting Secret"
    $encP = $($skIn.S)
    $secstrP = $encP | ConvertTo-SecureString -Key $key

    Write-Verbose "[INFO] Converting secret to plaintext for output"
    $strP=[System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secstrP))
    
    $DeHash = @{
        'DS' = $strP
    }

    Return $DeHash
    
}

Switch ($RunMode) {
    "Encrypt" { 
        If ($null -eq $InSecret) {            
            throw "[ERROR] In Decrypt mode but InSecret parameter passed in error"
        }
        If ($null -eq $InKey) {            
            throw "[ERROR] In Decrypt mode but InKey parameter passed in error"
        }
        If ($InPass.Length -le 0) {            
            throw "[ERROR] In Encrypt mode: secret to encrypt must be a string of length greater than 0"
        } else {   
                [securestring]$InPass = ConvertTo-SecureString $InPass -AsPlainText -Force
                Encrypt($InPass) }
        }
    "Decrypt" { 
        If ($null -eq $InPass) {            
            throw "[ERROR] In Decrypt mode but InPass parameter passed in error"
        }
        If ($InSecret.Length -le 0) {
            throw "[ERROR] In Decrypt mode: secret to decrypt must be a string of length greater than 0"
        }
        If ($InKey.Length -le 0) {
            throw "[ERROR] In Decrypt mode: decryption key must be a string of length greater than 0"
        } else {
            $InHash = @{
                'S' = $InSecret
                'K' = $InKey
            }
            Decrypt($InHash) }
    }
}
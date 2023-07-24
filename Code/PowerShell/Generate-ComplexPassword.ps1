function GeneratePassword {
    param(
        [ValidateRange(12, 256)]
        [int] 
        $length = 14
    )
    
    $symbols = '!@#$%^&*'
    $LowAlphas = 'abcdefghijklmnopqrstuvqxyz'
    $HighAlphas = 'ABCDEFGHIJKLMNOPQRSTUVQXYZ'
    $Nums = '0123456789'

    $ValidChars = $symbols+$LowAlphas+$HighAlphas+$Nums


    do {
        $password = -join (0..$length | ForEach-Object { [char](get-random -InputObject $ValidChars.ToCharArray()) })
        [int]$hasLowerChar = $password -cmatch '[a-z]'
        [int]$hasUpperChar = $password -cmatch '[A-Z]'
        [int]$hasDigit = $password -match '[0-9]'
        [int]$hasSymbol = $password.IndexOfAny($symbols) -ne -1
    }
    until (($hasLowerChar + $hasUpperChar + $hasDigit + $hasSymbol) -ge 3)

    $password

}

GeneratePassword(128)

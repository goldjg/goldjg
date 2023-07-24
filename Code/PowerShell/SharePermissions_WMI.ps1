$Shares = (Get-WmiObject -Class Win32_Share)

foreach ($Share in $Shares)
     {
        $ShareSS = Get-WmiObject -Class Win32_LogicalShareSecuritySetting -Filter "Name = '$($Share.Name)'"
        $SecurityDescriptor = $ShareSS.GetSecurityDescriptor()
        $AccessMask=$SecurityDescriptor.Descriptor.DACL.AccessMask
        $Share | Select-Object Name,Path
        $ShareSS | Select-Object PSComputerName
        $AccessMask
     }
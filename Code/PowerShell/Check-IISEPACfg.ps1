Invoke-Command -ComputerName <computer_name> -ScriptBlock { Get-WebConfigurationProperty -Filter "system.webServer/security/authentication/extendedProtection" -Name "flags" -PSPath "IIS:\Sites\Default Web Site\CertSrv" | Select-Object -ExpandProperty Value }
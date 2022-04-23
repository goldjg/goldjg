dir ##REDACTED## -filter *.PDF -recurse|`
?{$_.mode -notlike "d*"}|`
%{$ie = New-Object -ComObject InternetExplorer.Application
    $ie.Visible = $true
    $ie.Navigate($_.fullname)
    $ie = $null
    }
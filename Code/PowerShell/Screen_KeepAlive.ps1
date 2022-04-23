<#param($minutes=60);
$myshell = New-Object -com "Wscript.Shell";
for ($i = 0;$i -lt $minutes; $i++) { 
    Start-Sleep -Seconds 60
    $myshell.sendkeys(".") 
    }
#>

param($minutes=60);
for ($i = 0;$i -lt $minutes; $i++) { 
    Write-Host (60-[int]$i)    
    $Pos = [System.Windows.Forms.Cursor]::Position
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point((($Pos.X) + 5) , $Pos.Y)
    $Pos = [System.Windows.Forms.Cursor]::Position
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point((($Pos.X) - 5) , $Pos.Y)
    Start-Sleep -Seconds 60 
    }
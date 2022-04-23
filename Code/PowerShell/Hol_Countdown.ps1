$pshost = get-host
$pswindow = $pshost.ui.rawui

$pswindow.windowtitle = "My Holidays"
$pswindow.foregroundcolor = "Yellow"
$pswindow.backgroundcolor = "Black"
$newsize = $pswindow.buffersize
$newsize.height = 4
$newsize.width = 30
$pswindow.buffersize = $newsize
$newsize = $pswindow.windowsize
$newsize.height = 4
$newsize.width = 30
$pswindow.windowsize = $newsize


$status="running"
Do {
Clear-Host
$1stHol = New-TimeSpan -Start (get-date) -End 29/03/2015
$2ndHol = New-TimeSpan -Start (get-date) -End 22/05/2015
$3rdHol = New-TimeSpan -Start (get-date) -End 31/10/2015

Write-Host $1stHol.Days "Days Until Lanzarote!!"
Write-Host $2ndHol.Days "Days Until New York!!"
Write-Host $3rdHol.Days "Days Until St Lucia!!"
Start-Sleep -s 300
}
While ($status="running")
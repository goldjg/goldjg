#[int32[]]$ID = @(2000..3332 + 3334..4000)
[int32[]]$ID = @(1..9 + 11..20)
$filter = @{Logname='Application';
            ID=$ID}
Get-WinEvent -FilterHashtable $filter
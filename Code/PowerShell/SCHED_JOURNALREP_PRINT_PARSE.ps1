$inp = gc \\##REDACTED##\JOURNALOUT.TXT
$Filtered = $inp -match '^\d{2}/\d{2}/\d{4}'
$table =@()
$filtered|foreach {
                    $obj = New-Object System.Object
                    $dt = ($_ -split '\s+')[0]
                    $tm = ($_ -split '\s+')[1]
                    $cat = ($_ -split '\s+')[2]
                    $act = ($_ -split '\s+')[3]
                    $usr = ($_ -split '\s+')[4]
                    If (($_ -split '\s+').Count -gt 5){
                        $Det = (($_ -split '\s+')|select -last 4) -join ' '}
                    Else {
                        $Det = ($_ -split '\s+')[5]
                    }
                    $obj|Add-Member -MemberType NoteProperty -Name Date -Value $dt
                    $obj|Add-Member -MemberType NoteProperty -Name Time -Value $tm
                    $obj|Add-Member -MemberType NoteProperty -Name Category -Value $cat
                    $obj|Add-Member -MemberType NoteProperty -Name Action -Value $act
                    $obj|Add-Member -MemberType NoteProperty -Name User -Value $usr
                    $obj|Add-Member -MemberType NoteProperty -Name Details -Value $det
                    $table += $obj
}

#$table|ogv

$users = $table.User|where {$_ -ne ''}|select -unique 
$categories = $table.Category|where {$_ -notlike 'SIGN*' }|select -unique
$actions = $table.Action|select -unique

ForEach($u in $users){
        $useractions = $table|where {($_.User -eq $u) -and ($_.Category -in $categories)}
        $usersummary = $useractions|Group-Object -Property Action|Select Name,Count
        $usersummary|Add-Member -MemberType NoteProperty -Name User -Value $u
        $summary += $usersummary
        }
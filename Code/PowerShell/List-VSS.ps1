$shadowStorageList = @();
$volumeList = Get-WmiObject Win32_Volume -Property SystemName,DriveLetter,DeviceID,Capacity,FreeSpace -Filter "DriveType=3" | Select-Object @{n="DriveLetter";e={$_.DriveLetter.ToUpper()}},DeviceID,@{n="CapacityGB";e={([math]::Round([int64]($_.Capacity)/1GB,2))}},@{n="FreeSpaceGB";e={([math]::Round([int64]($_.FreeSpace)/1GB,2))}} | Sort-Object DriveLetter;
$shadowStorages = Get-WmiObject Win32_ShadowStorage -Property AllocatedSpace,DiffVolume,MaxSpace,UsedSpace,Volume |
                Select-Object @{n="Volume";e={$_.Volume.Replace("\\","\").Replace("Win32_Volume.DeviceID=","").Replace("`"","")}},
                @{n="DiffVolume";e={$_.DiffVolume.Replace("\\","\").Replace("Win32_Volume.DeviceID=","").Replace("`"","")}},
                @{n="AllocatedSpaceGB";e={([math]::Round([int64]($_.AllocatedSpace)/1GB,2))}},
                @{n="MaxSpaceGB";e={([math]::Round([int64]($_.MaxSpace)/1GB,2))}},
                @{n="UsedSpaceGB";e={([math]::Round([int64]($_.UsedSpace)/1GB,2))}}

# Create an array of Customer PSobject
foreach($shStorage in $shadowStorages) {
    $tmpDriveLetter = "";
    foreach($volume in $volumeList) {
        if($shStorage.DiffVolume -eq $volume.DeviceID) {
            $tmpDriveLetter = $volume.DriveLetter;
        }
    }
    $objVolume = New-Object PSObject -Property @{
        Volume = $shStorage.Volume
        AllocatedSpaceGB = $shStorage.AllocatedSpaceGB
        UsedSpaceGB = $shStorage.UsedSpaceGB
        MaxSpaceGB = $shStorage.MaxSpaceGB
        DriveLetter = $tmpDriveLetter
    }
    $shadowStorageList += $objVolume;
}


for($i = 0; $i -lt $shadowStorageList.Count; $i++){
    $objCopyList = Get-WmiObject Win32_ShadowCopy  | Where-Object {$_.VolumeName -eq $shadowStorageList[$i].Volume} | Select-Object DeviceObject, InstallDate }
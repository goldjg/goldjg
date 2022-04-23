$ErrorActionPreference = "SilentlyContinue"
rv *
$ErrorActionPreference = "Default"

$pre=gc("K:\MasterList_080816\BASIC.CSV")
$head=$pre[0]
$pre|select -skip 1|foreach{
$linelen=$_.length

$st  = $_.SubString(0,80)
$mid = $_.SubString(80,36) -replace ',',[char]0x201A #replace comma in description field with suitable replica
$end = $_.SubString(116,($linelen - 116))

$line=$st+$mid+$end
$post += ($line+"`r")
}

($head+"`r"+$post)|set-content "K:\MasterList_080816\BASIC_FIXED.CSV" -Force

$ErrorActionPreference = "SilentlyContinue"
rv *
$ErrorActionPreference = "Default"

$pre=gc("K:\MasterList_080816\PARAMS.CSV")
$head=$pre[0]
$pre|select -skip 1|foreach{
$linelen=$_.length

$st  = $_.SubString(0,89)
$end = $_.SubString(89,($linelen - 89)) -replace '"',[char]0x201C -replace ',',[char]0x201A #replace comma and double quote characters in param text field with suitable replicas

$line=$st+$end

$post += ($line+"`r")
}

($head+"`r"+$post)|set-content "K:\MasterList_080816\PARAMS_FIXED.CSV" -Force
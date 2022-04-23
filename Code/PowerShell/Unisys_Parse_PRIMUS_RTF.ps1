$Imported = gc ("K:\Unisys PLEs Monthly Report 060814.rtf")
$1stPass = (`
 (`
  (`
   ($Imported | where-object {($_ -match "\\charrsid\d{7}" -or ($_ -match "^\\par"))})`
    -replace '^\\par *{','')`
    -replace '^\\par ','')`
    -replace '\\\w+','')
$2ndPass = (((((($1stPass|where-object {($_ -notmatch "^ffff")`
                        -and ($_ -notmatch "shapeType")`
                        -and ($_ -match "\w+")`
                         }) -replace '{','')`
                         -replace '}','')`
                         -replace '\\\*','')`
                         -replace 'HYPERLINK','')`
                         -replace '\s{2,}',' ')`
                         -replace '"',''
#$2ndPass | out-file "K:\PLEs.txt"
$3rdPass = $2ndPass|foreach {If ($_.TrimStart() -match "^NUMBER"){return "`r"};
                             If ($_.TrimStart() -match "\w*\/PLE\/") {If ($_.TrimStart() -notmatch "\s+\d{8}\s+")`
                                {return ("PLE-URL:" + ($_.Split(" ")[1]))} else
                                {return ("PLE-URL:" + ($_.Split(" ")[1]) + "`r`n" + "PLE-NUMBER:" + ($_.Split(" ")[2]))}};
                             If ($_.TrimStart() -match "^HEADLINE"){return "`r"};
                             If ($_.TrimStart() -match "^PRODUCT"){return "`r"};
                             If ($_.TrimStart() -match "\w*PVP")`
                                {return ("PRODUCT-URL:" + ($_.Split(" ")[1]) + "`r`n" + "PRODUCT:" + ($_.Split(" ")[2]))};
                             If ($_.TrimStart() -match "^\d{8}"){return ("PLE-NUMBER:" + $_.TrimStart())};
                             return $_.TrimStart()
                             }
$4thPass = $3rdPass | foreach {
                             If ($_ -match "^\s{1}$"){$line = $null} else {
                                If (!($_ -match "^[A-Z]{3,7}\-{0,1}[^\- .]*:")){$line = ("HEADLINE:" + $_.TrimStart())} else {
                                If ($_ -match "^[A-Z]{1,7}:"){$line = ("HEADLINE:" + $_.TrimStart())} else {
                                $line = $_.TrimStart()}};
                             return $line;
                             rv line
                                }
                            }
                           
$Fixed = $4thPass[0..($4thPass.Count -2)]

$Fixed | out-file K:\Fixed.txt

$index = @()

gc ("K:\Fixed.txt")|foreach ($_){
        
        If ($_.StartsWith("PLE-URL:")){$PLEurl = $_.SubString(8)}
        If ($_.StartsWith("PLE-NUMBER:")){$PLEnum = ('=HYPERLINK("' + $PLEurl + '","' + $_.SubString(11) + '")')}
        If ($_.StartsWith("COMPONENT: ")){$Component = $_.SubString(11)}
        If ($_.StartsWith("DATE-PREPARED: ")){$Date = $_.SubString(15)}
        If ($_.StartsWith("HEADLINE:"))`
            {If (($Headline -ne $null) -and ($_.SubString(9) -ne $Headline)){$Headline += (" " + $_.SubString(9))}
             else {$Headline = $_.SubString(9)}}
        If ($_.StartsWith("PRODUCT-URL:")){$ProductURL = ($_.SubString(12)).Split("`r`n")[0]}
        If ($_.StartsWith("PRODUCT:")){$ProductName = $_.SubString(8);
              
            $obj = $null;
            $obj = New-Object System.Object;
            $obj | Add-Member -type NoteProperty -Name PLEurl -Value $PLEurl;
            $obj | Add-Member -type NoteProperty -Name PLE -Value $PLEnum;
            $obj | Add-Member -type NoteProperty -Name Component -Value $Component;
            $obj | Add-Member -type NoteProperty -Name Date -Value ([datetime]$Date).ToShortDateString();
            $obj | Add-Member -type NoteProperty -Name Headline -Value $Headline;
            $obj | Add-Member -type NoteProperty -Name ProductURL -Value $ProductURL;
            $obj | Add-Member -type NoteProperty -Name Product -Value $ProductName;                   
            #$obj;
            $index += $obj;
            $PLEurl = $null;$PLEnum = $null;$Component= $null;$Date= $null;$Headline = $null;$ProductURL = $null;$ProductName = $null,$obj = $null
            }
         }
         
    $index|Select PLE,Date,Headline,Product,Component|Sort-Object { $_.Date -as [datetime] }|Export-CSV -notype -path "K:\Unisys PLEs Monthly Report 060814.csv"

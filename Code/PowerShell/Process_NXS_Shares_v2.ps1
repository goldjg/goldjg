<#
Convert MCP NX/Services config file output to CSV list of shares

e.g. from this:

BROWSEDOMAINNAME = "DOMAIN";                                          
WINSSERVERIPADDRESS = 010.000.000.001                                   
                      010.000.000.002;                                  
COMMENT = "Server Name";                              
RESTRICTTOSHORTFILENAMES = FALSE;                                       
USEKERBEROS = FALSE;                                                    
KERBEROSONLY = FALSE;                                                   
SHARE _HOME_                                                            
  (TYPE = DISK                                                          
  ,PREFIX = "(<USERCODE>)"                                              
  ,COMMENT = "Private user files"                                       
  ,AREABYTES = 45000                                                    
  ,ACCESS =                                                             
    NONE                                                                
    +USER1                                                      
    +USER1                                                              
  ,FAMILY = "<FAMILY>"                                                  
  ,DOWNSIZEAREA = TRUE                                                  
  );                                                                    
SHARE ADMINCTR                                                          
  (TYPE = PIPE                                                          
  ,COMMENT = "Pipe for NXServices AdminCente"                           
             "r program"                                                
  ,ACCESS =                                                             
    ALL                                                                 
  ,PORTNAME = "ADMINCENTER"                                             
  ,PORTMAXRECSIZE = 50000                                               
  );                                                                    


#>

$shares_in = [io.file]::ReadAllText('\\##REDACTED##\SHARES (2).TXT')
$shares_delim = $shares_in | foreach {if (!($_ -match '^*;$')){$_ -replace '\r\n',''} else {$_}}
$shares_csv = $shares_delim -replace ';',";`r`n"
$shares_csv2 = $shares_csv -replace 'SHARE',''
$shares_norepquotes = $shares_csv2 -replace '""',''
$shares_noquotes = $shares_norepquotes -replace '"',''
$shares_trimspaces = $shares_noquotes -replace ' {2,10}',''
$shares_trimspaces | out-file \\##REDACTED##\SHARES_2.txt

$shares_only = gc \\##REDACTED##\SHARES_2.txt | where {$_ -match '^*TYPE = DISK'}

$share_index = @()

$shares_only |foreach {

    $sharename = ($_.Split("(")[0])
    $_ -match '\([\w\s.,"=<>()\/\*\+\-]*\);'|out-null

    $shareparams = $matches[0]
    
    $paramlist = ($shareparams.Substring(1,($shareparams.Length -3))).Split(",")
   
    $obj = $null
    $obj = New-Object System.Object
 
    $obj | Add-Member -type NoteProperty -Name NAME -Value $sharename.TrimStart()
 
    $paramlist | foreach {
        $obj `
        | Add-Member -type NoteProperty -Name (($_.Split("=")[0]).Split(" ")[0]) -Value (($_.Split("=")[1]).TrimStart())
    }
    $share_index += $obj
}

$fixed_index = $share_index | Sort-Object -Property @{expression={(($_.psobject.Properties)|Measure-Object).count}} -Descending | ConvertTo-CSV -notype
$fixed_index | ConvertFrom-CSV | Sort -Property Name | Export-CSV -notype \\##REDACTED##\SHARES.csv 

Remove-Item \\##REDACTED##\SHARES_2.txt
#Invoke-Item \\##REDACTED##\SHARES.csv
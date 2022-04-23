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

$shares_in = [io.file]::ReadAllText('\\##REDACTED##\SHARES.TXT')
$shares_delim = $shares_in | foreach {if (!($_ -match '^*;$')){$_ -replace '\r\n',''} else {$_}}
$shares_csv = $shares_delim -replace ';',";`r`n"
$shares_csv2 = $shares_csv -replace 'SHARE',''
$shares_removerepeatquotes = $shares_csv2 -replace '" *"',''
$shares_trimspaces = $shares_removerepeatquotes -replace ' {2,5}',' '
$shares_trimspaces | out-file \\l##REDACTED##\SHARES_2.txt

$shares_only = gc \\##REDACTED##\SHARES_2.txt | where {$_ -match '^* = DISK'}
$shares_fixnoperms = $shares_only`
 | foreach {If ( $_ -notmatch ' ,ACCESS = '){$_ -replace ' ,FAMILY = ',' ,ACCESS =  ,FAMILY = '} else {$_}}

$shares_out = $shares_fixnoperms | foreach {
    (((((((((((((($_ -replace ',AREABYTES = \d{1,6} ','')`
     -replace ' \(TYPE = DISK ','')`
      -replace 'PREFIX = ','')`
       -replace ' ,ACCESS = ',',"')`
        -replace ' ,FAMILY = ','",')`
         -replace ' ,DOWNSIZEAREA = TRUE',',')`
          -replace ' \);','')`
           -replace ',COMMENT = "[A-Za-z0-9\s.()]*",','')`
            -replace ' ,ALLOWGUESTACCESS = \w{4,5}','')`
             -replace ' ,SUPPRESSBROWSE = \w{4,5}','')`
              -replace '" "','","')`
               -replace ' "',',"')`
                -replace '""','"')`
                 -replace ' ,PUBLIC = [\w"]{4,5}','')`
                  -replace '",","','",,"'
        }

$share_index = @()

$shares_out -replace '"','' | foreach {
        
        $fields = $_ -split ','
        
        $obj = $null
        $obj = New-Object System.Object
        $obj | Add-Member -type NoteProperty -Name Name -Value $fields[0]
        $obj | Add-Member -type NoteProperty -Name Path -Value $fields[1]
        $obj | Add-Member -type NoteProperty -Name Permissions -Value $fields[2]
        $obj | Add-Member -type NoteProperty -Name Family -Value $fields[3]           
        $title = $null
        $category = $null
        $share_index += $obj
        }

$share_index | Export-CSV -notype \\##REDACTED##\SHARES.csv

Remove-Item \\##REDACTED##\SHARES_2.txt
#Invoke-Item \\##REDACTED##\SHARES.csv
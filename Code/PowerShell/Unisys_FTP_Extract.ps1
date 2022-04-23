select-string -pattern '\(SCOTAM\)' K:\FTP_Logs\*.TXT|`
    select Filename,Line|`
    Export-CSV -notype K:\FTP_Logs\SCOTAM_FTP_COPIES.CSV
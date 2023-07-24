$domains=@()


foreach ($domain in $domains){
    Get-ADUser -server $domain -filter 'displayname -eq ""' -Properties DisplayName,AdminDescription|Select Name,DisplayName,SID,SamAccountName,UserPrincipalName,AdminDescription|FT
    }
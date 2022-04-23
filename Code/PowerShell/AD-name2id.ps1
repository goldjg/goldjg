param ([Parameter(Mandatory=$true)]
       [string]$firstname,
       
       [Parameter(Mandatory=$true)]
       [string]$lastname
        )

$strFilter = "(&(objectCategory=User)(givenname=" + $firstname + ")(sn=" + $lastname + "))"

$objDomain = New-Object System.DirectoryServices.DirectoryEntry

$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.SearchRoot = $objDomain
$objSearcher.PageSize = 1000
$objSearcher.Filter = $strFilter

$objSearcher.SearchScope = "Subtree"

$colProplist = "name","memberof"
foreach ($i in $colPropList){[VOID]$objSearcher.PropertiesToLoad.Add($i)}

$colResults = $objSearcher.FindOne()

$objItem = $colResults.Properties; 
     $Userid=(($objItem.name -as [string]))

write-host ($firstname + " " + $lastname)     
write-host ($Userid)
write-host ($objItem.memberof|select-string 'ORG'|foreach {$_.ToString().Split(",")[0]})
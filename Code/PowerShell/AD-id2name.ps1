param ([Parameter(Mandatory=$true)]
        [string]$userid
        )

$strFilter = "(&(objectCategory=User)(Name=" + $userid + "))"

$objDomain = New-Object System.DirectoryServices.DirectoryEntry

$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.SearchRoot = $objDomain
$objSearcher.PageSize = 1000
$objSearcher.Filter = $strFilter

$objSearcher.SearchScope = "Subtree"

$colProplist = "givenname","sn"
foreach ($i in $colPropList){[VOID]$objSearcher.PropertiesToLoad.Add($i)}

$colResults = $objSearcher.FindOne()

$objItem = $colResults.Properties; 
     $Name=(($objItem.givenname -as [string]) + " " +  ($objitem.sn -as [string]))

write-host ($Userid)     
write-host ($Name)
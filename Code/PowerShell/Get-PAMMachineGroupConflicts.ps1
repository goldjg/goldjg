<# 
.SYNOPSIS 
  Reports on Potential Machine Group conflicts for AD Computer Objects
  
.DESCRIPTION 
  Query Every AD domain (dynamically generated list of active domains) for all computers that
  exist in more than 1 AD group.
.PARAMETER Credential 
  <Mandatory> Credential : PSCredential object with DOM readonly domain credentials to be able to enumerate all domains.
.PARAMETER RepPath
  <Optional> RepPath : Directory to save CSV report file in - defaults to userprofile directory of user running script e.g. C:\Users\<userid>\
#>
Param
(
	
    [Parameter(Mandatory = $true)]
    [ValidateScript({
        If ($_.UserName -like "DOM\*"){
            $true 
        } else {
            throw "[ERROR] $($_.Username) is not a DOM domain account - please provide DOM domain credentials"}
        }
        )]
    [PSCredential] $Credential=(Get-Credential),
    [Parameter(Mandatory = $False)]
    [ValidateScript({
        If (Test-Path $_ -PathType Leaf) {
            $true
        } else {
            throw "[ERROR] $_ is not a valid path from here"
        }
    
    })]
    [String]$RepPath = "$env:USERPROFILE"
)
#Initialise Variables
$RedDom="DOM.local"
$RepDate=Get-Date -format "yyyyMMdd"
Write-Host -ForegroundColor Cyan "[INFO] Getting parent domains list from $RedDom"
#Query red domain for all domains it has trusts with
$ErrorActionPreference = "Stop"
Try {
    $ParentDOMs=(Get-ADTrust -Server $RedDom -Filter * -Credential $Credential).Name
}
Catch { 
    Write-Error "[ERROR] $_"
    break
}
$ErrorActionPreference = "Continue"
$ParentDOMs+=$RedDom
$ErrorActionPreference = "Stop"
#Query each domain to determine its' child domains
Write-Host -ForegroundColor Cyan "[INFO] Getting child domains"
Foreach ($CDOM in $ParentDOMs) {
    If ($CDOM.Length -gt 0) {
        Try {
            $ChildDOMs+=((Get-ADDomain -server $CDOM -Credential $Credential).ChildDomains)
        }
        Catch {
            Write-Host -ForegroundColor DarkYellow "[WARN] $CDOM : $_"
            $ErrorActionPreference = "Stop"
        }
    }
}
$ErrorActionPreference = "Continue"
#Merge parent and child domain lists and remove duplicates
Write-Host -ForegroundColor White "[INFO] Merging Domain Lists"
$AllDOMs=$ChildDOMs+$ParentDOMs | Sort-Object -Unique
Write-Host -ForegroundColor Green "[INFO] $($AllDOMs.Count) Domains Found"
Write-Host -ForegroundColor Green "[INFO] Checking if domains are reachable from here"
$ReachableDoms = @()
<#
Check each domain is reachable, for any that aren't, exclude them from further query 
(use start-job timeouts to enforce short timeout as AD timeout is 2.5 minutes)
#>
ForEach ($Dom in $AllDOMs){
    Try {
    $Job = Start-Job -scriptblock { Get-ADDomain -Server $using:Dom -Credential $using:Credential | Select-Object -ExpandProperty DistinguishedName }
    }
    Catch {
        Write-Host -ForegroundColor DarkYellow "[WARN] $Dom : $_"
    }
    If (Wait-Job $Job -timeout 7) { 
        $DCRslt = Receive-Job $Job
        Write-Host -ForegroundColor Green "[INFO] Response received from : $DCRslt"
        If ( $Job.State -eq "Completed"){
            $ReachableDoms+=$Dom
        }
        Remove-Job -Force $Job
    }  
}
$UnReachableDoms = Compare-Object $AllDOMs $ReachableDoms|Select-Object -ExpandProperty InputObject
Write-Warning "[WARN] Unable to reach the following domain(s): $($UnReachableDoms)"
#Query machine groups in each domain
$i=1
ForEach ($Domain in $ReachableDOMs) {
    Write-Host -ForegroundColor White ("[INFO] Querying PAM Machine Groups for $Domain : Domain $i of " + ($ReachableDoms.Count))
    Try {
        $DomGrps=Get-ADGroup -server $Domain -Properties Members,CanonicalName -Filter { name -like "SRV*_CYB*" } -Credential $Credential -Verbose | Select-Object Name,Members,DistinguishedName,CanonicalName | Where-Object {$_.Members.Count -gt 0} | Select-Object Name,Members,CanonicalName
    }
    Catch {
        Write-Host -ForegroundColor DarkYellow "[WARN] $Domain : $_"
    }
    $AllGrps+=$DomGrps
    $i++
}

#Flush credentials now there are no more AD queries to be executed
$Credential = $null

#Get the list of servers from the groups and remove duplicates
$AllSRV=($AllGrps|ForEach-Object { ((($_.Members -split 'CN=') -Split ',').Trim() -notlike "*=*") -notlike $null } )
$DedupSRV=$AllSRV|Sort-Object -Unique

#Build array of servers, groups and domain where server is in more than one group.
$ReportArray=@()
Foreach ($SRV in $DedupSRV) {
    $obj = New-Object System.Object 
    $GrpCnt=($AllSRV | Where-Object { $_ -eq $SRV}).Count 
    If ($GrpCnt -gt 1) {
        $Grps=$AllGrps|Where-Object {$_.Members -like "*$($SRV)*"} | Select-Object -Expand CanonicalName
        Write-Warning "[WARN] $SRV is in multiple PAM Machine Groups : winning Group Policy may not be as expected."
        $obj|Add-Member -Name "Server" -Value $SRV -Type NoteProperty
        $obj|Add-Member -Name "Member of Groups" -Value ($Grps -as [String] -replace ' ',';')-Type NoteProperty
        $obj|Add-Member -Name "Group Domain" -Value ($Grps[0].Split('/')[0]|Select-Object) -Type NoteProperty
        $ReportArray += $obj
    }
}
#If there is at least one server with multiple groups, output the array to a CSV file.
If ($ReportArray.Count -gt 0) {
    Write-Warning "[WARN] $($ReportArray.Count) servers found in conflict, please review output in $RepPath\PAM_GPO_Conflicts_$RepDate.csv"
    $ReportArray|Export-Csv -Path "$RepPath\PAM_GPO_Conflicts_$RepDate.csv" -NoTypeInformation
} else {
    Write-Host -ForegroundColor Green "[INFO]: No servers found in conflict"
}
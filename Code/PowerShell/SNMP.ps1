function New-GenericObject {
    # Creates an object of a generic type - see http://www.leeholmes.com/blog/2006/08/18/creating-generic-types-in-powershell/
 
    param(
        [string] $typeName = $(throw “Please specify a generic type name”),
        [string[]] $typeParameters = $(throw “Please specify the type parameters”),
        [object[]] $constructorParameters
        )
 
    ## Create the generic type name
    $genericTypeName = $typeName + ‘`’ + $typeParameters.Count
    $genericType = [Type] $genericTypeName
 
    if(-not $genericType)
        {
        throw “Could not find generic type $genericTypeName”
        }
 
    ## Bind the type arguments to it
    [type[]] $typedParameters = $typeParameters
    $closedType = $genericType.MakeGenericType($typedParameters)
    if(-not $closedType)
        {
        throw “Could not make closed type $genericType”
        }
 
    ## Create the closed version of the generic type
    ,[Activator]::CreateInstance($closedType, $constructorParameters)
}

function Invoke-SNMPget ([string]$sIP, $sOIDs, [string]$Community = "public", [int]$UDPport = 161, [int]$TimeOut=3000) {
    # $OIDs can be a single OID string, or an array of OID strings
    # $TimeOut is in msec, 0 or -1 for infinite
 
    # Create OID variable list
    #$vList = New-GenericObject System.Collections.Generic.List Lextm.SharpSnmpLib.Variable                        # PowerShell v1 and v2
    [reflection.assembly]::LoadFrom( (Resolve-Path ".\lib\SharpSnmpLib.dll") )

     $vList = New-Object 'System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]'                          # PowerShell v3
    foreach ($sOID in $sOIDs) {
        $oid = New-Object Lextm.SharpSnmpLib.ObjectIdentifier ($sOID)
        $vList.Add($oid)
    }
 
    # Create endpoint for SNMP server
    $ip = [System.Net.IPAddress]::Parse($sIP)
    $svr = New-Object System.Net.IpEndPoint ($ip, 161)
 
    # Use SNMP v2
    $ver = [Lextm.SharpSnmpLib.VersionCode]::V2
 
    # Perform SNMP Get
    try {
        $msg = [Lextm.SharpSnmpLib.Messaging.Messenger]::Get($ver, $svr, $Community, $vList, $TimeOut)
    } catch {
        Write-Host "SNMP Get error: $_"
        Return $null
    }
 
    $res = @()
    foreach ($var in $msg) {
        $line = "" | Select OID, Data
        $line.OID = $var.Id.ToString()
        $line.Data = $var.Data.ToString()
        $res += $line
    }
 
    $res
}

function Invoke-SnmpWalk ([string]$sIP, $sOIDstart, [string]$Community = "public", [int]$UDPport = 161, [int]$TimeOut=3000) {
    # $sOIDstart
    # $TimeOut is in msec, 0 or -1 for infinite
 
    # Create OID object
    $oid = New-Object Lextm.SharpSnmpLib.ObjectIdentifier ($sOIDstart)
 
    # Create list for results
    #$results = New-GenericObject System.Collections.Generic.List Lextm.SharpSnmpLib.Variable                       # PowerShell v1 and v2
    [reflection.assembly]::LoadFrom( (Resolve-Path ".\lib\SharpSnmpLib.dll") )

     $results = New-Object 'System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]'                         # PowerShell v3
 
    # Create endpoint for SNMP server
    $ip = [System.Net.IPAddress]::Parse($sIP)
    $svr = New-Object System.Net.IpEndPoint ($ip, 161)
 
    # Use SNMP v2 and walk mode WithinSubTree (as opposed to Default)
    $ver = [Lextm.SharpSnmpLib.VersionCode]::V2
    $walkMode = [Lextm.SharpSnmpLib.Messaging.WalkMode]::WithinSubtree
 
    # Perform SNMP Get
    try {
        [Lextm.SharpSnmpLib.Messaging.Messenger]::Walk($ver, $svr, $Community, $oid, $results, $TimeOut, $walkMode)
    } catch {
        Write-Host "SNMP Walk error: $_"
        Return $null
    }
 
    $res = @()
    foreach ($var in $results) {
        $line = "" | Select OID, Data
        $line.OID = $var.Id.ToString()
        $line.Data = $var.Data.ToString()
        $res += $line
    }
 
    $res
}

Invoke-SnmpWalk "10.0.0.1" ".1.3.6.1.2.1.1.5.0"
function New-Xml
{
param($RootTag="ROOT",$ItemTag="ITEM", $ChildItems="*", $Attributes=$Null)

Begin {
$xml = "<$RootTag>`n"
}


Process {
$xml += " <$ItemTag"
if ($Attributes)
{
foreach ($attr in $_ | Get-Member -type *Property $attributes)
{ $name = $attr.Name
$xml += " $Name=`"$($_.$Name)`""
}
}
$xml += ">`n"
foreach ($child in $_ | Get-Member -Type *Property $childItems)
{
$Name = $child.Name
$xml += " <$Name>$($_.$Name)</$Name>`n"
}
$xml += " </$ItemTag>`n"
}

End {
$xml += "</$RootTag>`n"
$xml
}
} 


<#
e.g. for xml list of running processes beginning with letter a:
gps a*|New-Xml -RootTag PROCESSES -ItemTag PROCESS -Attribute=id,ProcessName -ChildItems WS,Handles

gives 
<PROCESSES>
 <PROCESS ProcessName="amswmagt">
 <WS>6197248</WS>
 <Handles>135</Handles>
 </PROCESS>
 <PROCESS ProcessName="armsvc">
 <WS>5115904</WS>
 <Handles>81</Handles>
 </PROCESS>
 <PROCESS ProcessName="atashost">
 <WS>4804608</WS>
 <Handles>86</Handles>
 </PROCESS>
 <PROCESS ProcessName="audiodg">
 <WS>15704064</WS>
 <Handles>121</Handles>
 </PROCESS>
</PROCESSES>


#>
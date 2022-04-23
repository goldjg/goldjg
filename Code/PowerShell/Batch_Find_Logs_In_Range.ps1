Function In-Time-Range
{
<# 
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
| In-Time-Range function                                                                |
| Input: Start and end timestamp plus timestamp to be checked is in window              |
| Output: Returns true or false                                                         |
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#>
param (
        [Parameter(Mandatory=$true)]
        [ValidatePattern("\d{14}")]
        [Int64]$file_date,
        
        [Parameter(Mandatory=$true)]
        [ValidatePattern("\d{14}")]
        [Int64]$winStart,

        [Parameter(Mandatory=$true)]
        [ValidatePattern("\d{14}")]
        [Int64]$winEnd        
)
If ($file_date -ge $winStart -and $file_date -le $winEnd){
    return $true;
    }
    else
    {
    return $false;
    };
};

$winstart = 20160101000000
$winend   = 20160131235959

$files = dir K:\Logstats\Processed -File
$files|foreach {
        $fldate=$_.Name.Split('_')[2].Split('.')[0];
        $fldateint="{0:yyyyMMddHHmmss}" -f [datetime]::ParseExact($fldate,"ddMMyy",[System.Globalization.CultureInfo]::InvariantCulture) -as [Int64]
        
        If (In-Time-Range -file_date $fldateint -winStart $winstart -winEnd $winend){
            #($_.Name + "," + (@(gc $_.Fullname).Length -1))
            $numjobs += (@(gc $_.Fullname).Length -1)
            $_.Name
            };
    }
$numjobs        
rv numjobs,winstart,winend,files,fldate,fldateint  
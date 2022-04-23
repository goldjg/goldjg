#.\PLINK.EXE -v -x -a -T -C -noagent -ssh -L 127.0.0.1:10000:10.0.0.1:3389 User@IP
#mstsc /v:127.0.0.1:10000
$basedir="\\##REDACTED##"
$cfile="UniTunnel.cfg"
$global:mycfg = @()
$global:tunnel_state = @()

Function Build-Config{
$hostfiles=dir $basedir\*.rdp
$tmphosts=($hostfiles.Name.split('.')|select-string -Pattern "rdp" -notmatch).Line
$tmphosts|foreach {
                $obj = $null
                $obj = New-Object System.Object
                $obj | Add-Member -type NoteProperty -Name Hostname -Value $_
                $obj | Add-Member -type NoteProperty -Name RDP_File -Value "$_.rdp"
                $obj | Add-Member -type NoteProperty -Name Address -Value ((Get-Content "$basedir\$_.rdp")|select-string -Pattern "address"|select Line).Line.Split(":")[2]
                $obj | Add-Member -type NoteProperty -Name Username -Value ((Get-Content "$basedir\$_.rdp")|select-string -Pattern "username"|select Line).Line.Split(":")[2]
                $global:mycfg += $obj
                }
Remove-Variable tmphosts,hostfiles
$global:mycfg | Export-Csv "$basedir\$cfile" -NoTypeInformation
}

Function Load-Config{
$global:mycfg = Import-Csv "$basedir\$cfile"
}

Function Build-Form {
Add-Type -AssemblyName System.Windows.Forms

$Form = New-Object system.Windows.Forms.Form
$Form.Text = "UniTunnel v1.0"
#$Form.TopMost = $true
$Form.Width = 310
$Form.Height = 260
$Form.StartPosition=“CenterScreen”

$label1 = New-Object system.windows.Forms.Label
$label1.Text = "Select a host to connect to:"
$label1.AutoSize = $true
$label1.Width = 25
$label1.Height = 10
$label1.location = new-object system.drawing.point(7,14)
$label1.Font = "Microsoft Sans Serif,10,style=Bold"
$Form.controls.Add($label1)

$listBox1 = New-Object system.windows.Forms.ListBox
$listBox1.Text = "listBox"
$listBox1.Width = 275
$listBox1.Height = 140
$listBox1.location = new-object system.drawing.point(7,35)
$global:mycfg.Hostname|foreach{[void]$listbox1.Items.Add($_)}
$listBox1.Add_DoubleClick({&$button1_Click})
$Form.controls.Add($listBox1)

$button1 = New-Object system.windows.Forms.Button
$button1.Text = "Initialise Tunnel"
$button1.Width = 122
$button1.Height = 27
$button1.enabled = $true
$button1.location = new-object system.drawing.point(7,175)
$button1.Font = "Microsoft Sans Serif,10"
$button1.Add_Click({$x=$listbox1.SelectedItem;
                    If ($x.length -eq 0) {
                    [System.Windows.Forms.Messagebox]::Show("Please select a host!",`
                                                            “ERROR”,`
                                                            [System.Windows.Forms.MessageBoxButtons]::OK,`
                                                            [System.Windows.Forms.MessageBoxIcon]::Error)} else
                                    {$connecthost=$global:mycfg|where-object -Property Hostname -eq $x;
                                     Connect-Tunnel($connecthost.Hostname,$session,$logfile)
                                     If ($session -and $logfile) {
                                        $obj = New-Object System.Object
                                        $obj|Add-Member -NotePropertyName Host -NotePropertyValue $connecthost.Hostname
                                        $obj|Add-Member -NotePropertyName Session -NotePropertyValue $session
                                        $obj|Add-Member -NotePropertyName Logfile -NotePropertyValue $logfile
                                        $obj
                                        $global:tunnel_state += $obj
                                        }
                                      }

                                     
})
$Form.controls.Add($button1)

$button2 = New-Object system.windows.Forms.Button
$button2.Text = "Connect to Desktop"
$button2.Width = 150
$button2.Height = 27
$button2.enabled = $false
$button2.location = new-object system.drawing.point(133,175)
$button2.Font = "Microsoft Sans Serif,10"
$button2.Add_Click({$y=$listbox1.SelectedItem;})
$Form.controls.Add($button2)

[void]$Form.ShowDialog()
$Form.Dispose()
}

Function Connect-Tunnel{
    param(
    [Parameter(Mandatory=$true)]
        [Alias("Rem")]
        $RemoteHost,
        
        [Parameter(Mandatory=$false)]
        [Alias("Ses")]
        $Session,
        
        [Parameter(Mandatory=$false)]
        [Alias("Log")]
        $Logfile
        )
       $puttypath="C:\PuTTY"
       $plinkpath="C:\PuTTY\PLINK.EXE"
       $cred=Get-Credential -Message ("Please supply the " + $connecthost.Username + " password for $RemoteHost") -UserName $connecthost.Username 
       If ($cred) {
       $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($cred.Password)
       
       $notinuse=$false
       while (-not $notinuse)
       {$portsinuse=((netstat -ano) -split "\s+"|select-string -SimpleMatch "::1").Line -replace "\[\:\:1\]\:",'' -replace ' ',','
        $tport = get-random -Minimum 13900 -Maximum 13999
        If (($portsinuse|select-string -SimpleMatch $tport).Line.Length -eq 0) {$notinuse = $true}
        }
       $ErrorActionPreference="SilentlyContinue"; remove-item  "$puttypath\ssh$tport.log"; $ErrorActionPreference="Continue"
       $plinkargs="-x -a -T -C -noagent -ssh -L 127.0.0.1:"+$tport+":"+ $connecthost.Address+":3389 " + $connecthost.Username + "@" + $connecthost.Address + `
                                                " -pw " + [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR) + " -sshlog $puttypath\ssh$tport.log"
       Remove-Variable cred,BSTR -Force
       $script:session=Start-Process $plinkpath $plinkargs -NoNewWindow -PassThru
       $script:Logfile="$puttypath\ssh$tport.log"
       } Else {$Form.BringToFront()}
    } 

If (-not(Test-Path -Path "$basedir\$cfile")) {Build-Config} else {Load-Config}

Build-Form


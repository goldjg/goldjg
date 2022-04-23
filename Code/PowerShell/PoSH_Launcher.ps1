Add-Type -AssemblyName System.Windows.Forms 
$Form = New-Object system.Windows.Forms.Form
$Form.Text = "PoSH Launcher"

$Icon = [system.drawing.icon]::ExtractAssociatedIcon($PSHOME + "\powershell.exe")

$Form.Icon = $Icon

#$Image = [system.drawing.image]::FromFile("$($Env:Public)\Pictures\Sample Pictures\Lighthouse.jpg")

#$Form.BackgroundImage = $Image

#$Form.BackgroundImageLayout = "None"

$Form.BackColor = 'White'
    # None, Tile, Center, Stretch, Zoom

$Form.Width = 1024

$Form.Height = 768

$Font = New-Object System.Drawing.Font("Calibri",24,[System.Drawing.FontStyle]::Italic)

    # Font styles are: Regular, Bold, Italic, Underline, Strikeout

$Form.Font = $Font

#$Label = New-Object System.Windows.Forms.Label

#$Label.Text = "PS Script Launcher"

#$Label.BackColor = "Transparent"

#$Label.AutoSize = $True

#$Form.Controls.Add($Label)

$Form.ShowDialog() 


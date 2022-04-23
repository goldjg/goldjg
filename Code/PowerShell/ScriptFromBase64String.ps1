param([string]$inputFile=$null)
$content = Get-Content -LiteralPath ($inputFile) -Encoding UTF8 -ErrorAction SilentlyContinue
if( $content -eq $null ) {
	Write-Host "No data found. May be read error or file protected."
	exit -2
}
$script = [System.Convert]::FromBase64String(([System.Text.Encoding]::UTF8.GetBytes($content)))
$script|set-content ($inputfile.split(".")[0] + ".b64") 
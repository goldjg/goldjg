<#
hilite.me API documentation

GET or POST to http://hilite.me/api with these parameters:

* code: source code to format
* lexer: [lexer](http://pygments.org/docs/lexers/) to use, default it 'python'
* options: optional comma-separated list of lexer options
* style: [style](http://pygments.org/docs/styles/) to use, default is 'colorful'
* linenos: if not empty, the HTML will include line numbers
* divstyles: CSS style to use in the wrapping <div> element, can be empty

The request will return the HTML code in UTF-8 encoding.
#>

#Setup webclient object
$webclient = New-Object System.Net.WebClient

#Use logged on users proxy credentials for internet access.
$webclient.UseDefaultCredentials = $true

#Set URL for hilite.me site
$hiliteURL = "http://hilite.me/api"

#Import script
$code = [System.IO.File]::ReadAllText("\\##REDACTED##\SQL_To_CSV.ps1")

#Set script language to pass to the hilite.me API
$lexer = "powershell"

#Set html output style
$style = "default"

#Create and populate NameValueCollection containing the parameters to be passed to the API
$reqparms = New-Object System.Collections.Specialized.NameValueCollection
$reqparms.Add("code", $code)
$reqparms.Add("lexer", $lexer)
$reqparms.Add("style", $style)

#POST to the API and get response back (as a UTF8 encoded byte array)
$responsebytes = $webclient.UploadValues($hiliteURL, "POST", $reqparms)

#Setup encoding object to decode the byte array
$Decode = New-Object System.Text.UTF8Encoding

#Decode byte array as String
$responsebody = $Decode.GetString($responsebytes)

#Put the string (the HTML generated by the API) into the clipboard.
[Windows.Clipboard]::SetText($responsebody)
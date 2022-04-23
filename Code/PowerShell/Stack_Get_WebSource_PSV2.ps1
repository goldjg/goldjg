$req = [System.Net.WebRequest]::Create("http://www.google.com/")
$resp = $req.GetResponse()
$reqstream = $resp.GetResponseStream()
$stream = new-object System.IO.StreamReader $reqstream
$result = $stream.ReadToEnd()
$result | out-file K:\output2.txt
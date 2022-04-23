''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'This VBScript uses Microsoft® Windows® Collaboration Data Objects (CDO)
'Both VBScript and CDO are integral parts of every Windows series of operating systems
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

'create reference to CDO component.
Set objMessage = CreateObject("CDO.Message")

'fill in subject, sender, receiver, and the text body.
objMessage.Subject = "test"
objMessage.Sender = "you@domain.com"
objMessage.To = "graham.gold@domain"
objMessage.TextBody = "This is a test......" & vbcrlf & "http://www.google.com" & vbcrlf & "file:///##REDACTED##/"
objMessage.AddAttachment("C:\##REDACTED##.txt")

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'define where SMTP service resides
' if the server is remote set this value to 2
' if the server is local set this value to 1
' remember to change to your remote smtp server
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
objMessage.Configuration.Fields.Item _
("http://schemas.microsoft.com/cdo/configuration/sendusing") = 2
'specify the name of the SMTP server that will be used
objMessage.Configuration.Fields.Item _
("http://schemas.microsoft.com/cdo/configuration/smtpserver") = "##REDACTED##"
'specify the port to use which is port 25 by default for SMTP
objMessage.Configuration.Fields.Item _
("http://schemas.microsoft.com/cdo/configuration/smtpserverport") = 25

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'if your smtp server requires authentication with a username and password
' then un-comment the next five objMessage settings.
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'set the authentication method. In this example we use Basic Authentication (clear-text).
'If we want to use NTLM (Windows Authentication), we would change the number to 2 instead of 1.
'objMessage.Configuration.Fields.Item _
'("http://schemas.microsoft.com/cdo/configuration/smtpauthenticate") = 1
'specify the user account to use. A special account is advisable for doing this.
'objMessage.Configuration.Fields.Item _
'("http://schemas.microsoft.com/cdo/configuration/sendusername") = "##REDACTED##"
'specify the password that will be sent
'objMessage.Configuration.Fields.Item _
'("http://schemas.microsoft.com/cdo/configuration/sendpassword") = "##REDACTED##"
'set that we will not use SSL for the communication to the SMTP server.
'objMessage.Configuration.Fields.Item _
'("http://schemas.microsoft.com/cdo/configuration/smtpusessl") = False
'set the timeout to 60 seconds.
'objMessage.Configuration.Fields.Item _
'("http://schemas.microsoft.com/cdo/configuration/smtpconnectiontimeout") = 60

objMessage.Configuration.Fields.Update
objMessage.Send







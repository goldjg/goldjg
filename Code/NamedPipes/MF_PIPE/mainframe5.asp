<!--#INCLUDE FILE="shared.asp"-->
<%

iPipe = Application("PipeNumber")
if Application("PipeNumber")="" then
	Application("PipeNumber")=0
end if
iPipe = cint(Application("PipeNumber"))+1
if iPipe> 20 then
	iPipe= 1
end if
Application("PipeNumber")=iPipe

sWindow = request("window")
if right(sWindow,2) = "01" then 
	sWindow = left(sWindow, len(sWindow)-2) & right("00" & cstr(iPipe),2)
end if

Set Session("MF") = Server.CreateObject("mf.pipe")
if Session("MF") is nothing then
	response.write("Error creating object")
	response.end
end if

Session("MF").sPipeName = "\\host\pipe\coms\coms\" & request("window")
Session("MF").lPipeSize = 10000
Session("MF").lTimeout = 5000
Session("MF").sUser = "##REDACTED##"	 'not including in secured version
Session("MF").sPassword = "##REDACTED##"	 'not including in secured version
Session("MF").sServer = "##REDACTED##"
iTemp = Session("MF").mfOpen

if iTemp = 0 then 'error opening pipe
	set Session("MF")=Nothing
	response.write("Error opening pipe")
	response.end
end if

Session("MF").sBuffer = ""
lTemp = Session("MF").mfRead

while instr(Session("MF").sBuffer,request("Search")) <= 0 and lTemp > 0
	lTemp = Session("MF").mfRead
wend 

if lTemp = 0 then
	Session("MF").mfClose
	set Session("MF")=Nothing
	response.write("Error retrieving mainframe information")
	response.end
end if
	
Session("MF").sBuffer=request("cmdline")
ltemp = Session("MF").mfWrite
if lTemp = 0 then
	Session("MF").mfClose
	set Session("MF")=Nothing
	response.write("Error writing mainframe information")
	response.end
end if

lTemp = Session("MF").mfRead
if lTemp = 0 then
	Session("MF").mfClose
	set Session("MF")=Nothing
	response.write("Error reading mainframe information")
	response.end
end if

sBuffer = Session("MF").sBuffer
Temp = Session("MF").mfClose
set Session("MF") = Nothing

sBuffer = ReplaceChar(sBuffer,"?"," ")
sBuffer = ReplaceChar(sBuffer,"&"," ")
sBuffer = ReplaceChar(sBuffer,""""," ")
sBuffer = ReplaceChar(sBuffer,"          ","_")
sBuffer = ReplaceChar(sBuffer,"__","}")
sBuffer = ReplaceChar(sBuffer,"}}","_")
sBuffer = ReplaceChar(sBuffer,"__","}")
sBuffer = ReplaceChar(sBuffer,"}}","_")'

sBuffer = ReplaceChar(sBuffer,"#","+")
sBuffer = ReplaceChar(sBuffer,"_","+")
sBuffer = ReplaceChar(sBuffer," ","+")
sBuffer = ReplaceChar(sBuffer,chr(13),"+")
sBuffer = ReplaceChar(sBuffer,chr(10),"+")

sParam = request("redirparam")
if sParam <> "" then
	sParam = ReplaceChar(sParam, "|", "=")
	sParam = ReplaceChar(sParam, "@", "&")
end if


%>
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">
<html>

<head>
<meta http-equiv="Content-Type"
content="text/html; charset=iso-8859-1">
<META HTTP-EQUIV="REFRESH" CONTENT="0;URL=<%=request("redirect") & "?response=" & left(sBuffer,2000) & "&" & sParam %>">
<meta name="GENERATOR" content="Microsoft FrontPage 2.0">
<title>mainframe</title>
</head>

<body bgcolor="#FFFFFF">

<p>



</body>
</html>

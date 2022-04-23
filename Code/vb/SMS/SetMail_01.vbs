Dim objConn,objCmd,rs
Dim strSQL
Dim txtServer, txtNewServer

Set objConn = CreateObject("ADODB.Connection")
objConn.Open "DSN=ESRConfig"
		
Set objCmd = CreateObject("ADODB.Command")
			
Set objCmd.ActiveConnection = objConn

txtNewServer = "##REDACTED##"

strSQL = "UPDATE EmailConfig SET Server = '" & txtNewServer & "'"

objCmd.CommandText = strSQL
objCmd.CommandType = 1
objCmd.Execute

objConn.close


Set rs = CreateObject("ADODB.Recordset")
rs.Open "SELECT * FROM EmailConfig", "DSN=ESRConfig"

txtServer = rs("Server")

msgbox "ESR Mail Server is now " & txtServer
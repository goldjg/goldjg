Set rs = CreateObject("ADODB.Recordset")
rs.Open "SELECT * FROM EmailConfig", "DSN=ESRConfig"

txtServer = rs("Server")

msgbox "Current ESR Mail Server is " & txtServer
Option Explicit
On Error Resume Next  
ExcelMacroExample  
Sub ExcelMacroExample()     
	Dim xlApp    
	Dim xlBook
	Dim iText     
	iText = InputBox("Enter colour number","Get User Input")
	If iText >= 0 Then
		Set xlApp = CreateObject("Excel.Application")    
		Set xlBook = xlApp.Workbooks.Open("##REDACTED##.xls", 2, False)    
		xlApp.Visible = True
		xlApp.Run "CMDB_Recon.Auto_RECON_1", iText.Value
		xlApp.DisplayAlerts = False
		xlBook.Save  
		xlApp.Quit    
		Set xlBook = Nothing    
		Set xlApp = Nothing 
	End If
End Sub  
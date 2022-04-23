Option Explicit
On Error Resume Next  
ExcelMacroExample  
Sub ExcelMacroExample()     
	Dim xlApp    
	Dim xlBook
	Dim Result
	Set xlApp = CreateObject("Excel.Application")    
	xlApp.Visible = False
	xlApp.DisplayAlerts = False
	Set xlBook = xlApp.Workbooks.Open("##REDACTED##.xls",False,2)    
	Result = xlApp.Run ("Recon.Reconcile","Unisys","Cluster")
	MsgBox Result
	xlBook.Close False 
	xlApp.Quit
	Set xlBook = Nothing    
	Set xlApp = Nothing 
End Sub  
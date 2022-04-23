'************************************************************************************
'*	Name: Text File Search Script
'*
'*	'*
'*	Author: Graham Gold  2007
'*
'*	Description: Script reads a specified text file and determines if a 
'*		specified search text is in the file. If it is, this script
'*		generates an event in MOM
'*
'*	Modified version of Justin Harter's script
'* 	
'*	Parameters: TextFileName, SearchText
'************************************************************************************

On Error Resume Next

Sub Main()

Const ForReading = 1
Const TEXT_FILE_PARAM_NAME = "TextFileName"
Const SEARCH_PARAM_NAME = "SearchText"

Const EVENT_TYPE_SUCCESS = 0
Const EVENT_TYPE_ERROR   = 1
Const EVENT_TYPE_WARNING = 2
Const EVENT_TYPE_INFORMATION = 4
Const EVENT_TYPE_AUDITSUCCESS = 8
Const EVENT_TYPE_AUDITFAILURE = 16

'Declare Variables
Dim strFileName
Dim objFSO
Dim objFile
Dim strText
Dim strSearchText

	strFileName = ScriptContext.Parameters.Get(TEXT_FILE_PARAM_NAME)
	strSearchText = ScriptContext.Parameters.Get(SEARCH_PARAM_NAME)

	Set objFSO = CreateObject("Scripting.FileSystemObject")
	Set objFile = objFSO.OpenTextFile(strFileName, ForReading)

	strText = objFile.ReadAll
	objFile.close

	If InStr(1, strText, strSearchText, 1) Then
		ThrowScriptSuccessNoAbort "The string '" & StrSearchText & "' WAS found in file " & strFileName
	Else
		ThrowScriptErrorNoAbort "The string '" & StrSearchText & "' was NOT found in file " & strFileName
	End If

End Sub

Function ThrowScriptErrorNoAbort(ByVal sMessage)
' ThrowScriptError :: Creates an error event and sends it back to the mom server

	On Error Resume Next

	Dim oScriptErrorEvent

	Set oScriptErrorEvent = ScriptContext.CreateEvent()
	With oScriptErrorEvent
		.EventNumber = 40001
		.EventType = EVENT_TYPE_ERROR
		.Message = sMessage
            .EventSource = "Check Text Script"
	
	End With
	ScriptContext.Submit oScriptErrorEvent
End Function

Function ThrowScriptSuccessNoAbort(ByVal sMessage)
' ThrowScriptSuccess :: Creates a success event and sends it back to the mom server

	On Error Resume Next

	Dim oScriptErrorEvent

	Set oScriptErrorEvent = ScriptContext.CreateEvent()
	With oScriptErrorEvent
		.EventNumber = 40000
		.EventType = EVENT_TYPE_ERROR
		.Message = sMessage
            .EventSource = "Check Text Script"
	
	End With
	ScriptContext.Submit oScriptErrorEvent
End Function
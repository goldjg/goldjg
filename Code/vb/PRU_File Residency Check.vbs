'********************************************************************************************
'*	Name: File Residency Check
'*
'*  	Author : Graham Gold (##REDACTED##)
'*	
'*	'Highly Modified version of original script by Justin Harter (http://www.momresources.org)
'*	'Added parameters to specify whether to alert if file is missing or if file exists
'*	'Also added validation of parameters
'*	
'*	Description: Checks to see if a specified file exists      
'* 	
'*	Parameters: 	FileName		'Full path name of file on server
'*				AlertMissingFile	'Y or N (Default = Y)
'********************************************************************************************

'Set Constants
Const FILENAME_PARAM_NAME = "FileName"
Const ALERTMISSINGFILE_PARAM_NAME = "AlertMissingFile"

Const EVENT_TYPE_SUCCESS      = 0
Const EVENT_TYPE_ERROR        = 1
Const EVENT_TYPE_WARNING      = 2
Const EVENT_TYPE_INFO         = 4
Const EVENTLOG_AUDIT_SUCCESS  = 8
Const EVENTLOG_AUDIT_FAILURE  = 16

Const EVENT_FILE_FOUND = 15000
Const EVENT_FILE_NOT_FOUND = 15001
Const EVENT_INCORRECT_PARAMETERS = 15002

'Declare Variables
Dim FileToMonitor
Dim AlertMissingFile

'Get the Parameters
FileToMonitor = ScriptContext.Parameters.Get(FILENAME_PARAM_NAME)
AlertMissingFile = ScriptContext.Parameters.Get(ALERTMISSINGFILE_PARAM_NAME)

'Validate Parameters
Select Case AlertMissingFile
Case "Y"
	AlertMissingFile = "Y"
Case "N"
	AlertMissingFile = "N"
Case "y"
	AlertMissingFile = "Y"
Case "n"
	AlertMissingFile = "N"
Case Empty
	strMsg = "AlertMissingFile parameter must have a value of Y or N."
	CreateEvent strMsg, EVENT_INCORRECT_PARAMETERS, EVENT_TYPE_ERROR
Case Null
	strMsg = "AlertMissingFile parameter must have a value of Y or N."
	CreateEvent strMsg, EVENT_INCORRECT_PARAMETERS, EVENT_TYPE_ERROR
Case Else
	strMsg = "AlertMissingFile parameter must have a value of Y or N."
	CreateEvent strMsg, EVENT_INCORRECT_PARAMETERS, EVENT_TYPE_ERROR
End Select

'----------------Main Code--------------

Select Case AlertMissingFile
Case "Y"
	If (NOT FileExists(FileToMonitor)=True) Then
		strMsg = "File: " & FileToMonitor & " does not exist."
		CreateEvent strMsg, EVENT_FILE_NOT_FOUND, EVENT_TYPE_WARNING
	End If
Case "N"
	If FileExists(FileToMonitor) Then
		strMsg = "File: " & FileToMonitor & " exists."
		CreateEvent strMsg, EVENT_FILE_FOUND, EVENT_TYPE_SUCCESS
	End If
End Select

'---------------End Of Main code----------

Function FileExists(strFile)
	'Declare Variables	
	Dim FSO
	Dim FilePath

	'Create File System Object
	set FSO = CreateObject("Scripting.FileSystemObject")

	FilePath = FSO.GetAbsolutePathName(strFile)

	'Check for File Existence
	If FSO.FileExists(FilePath) Then
		FileExists = True
	Else
		FileExists = False
	End If
End Function


Sub CreateEvent(EventMsg, EventNumber, EventType)
   	Dim oEvent

   	'Create a New Event
   	Set oEvent = ScriptContext.CreateEvent

	oEvent.Message = EventMsg
	oEvent.EventNumber = EventNumber
	oEvent.EventType = EventType

   	'Submit the Event to MOM
   	ScriptContext.Submit oEvent

   	Set oEvent = Nothing
End Sub
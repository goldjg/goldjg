VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ThisWorkbook"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = True
Sub Update_Query()
'################################################################################
'#  Update_Query Sub                                                            #
'#  ~~~~~~~~~~~~~~~~                                                            #
'#  Author:      Graham Gold                                                    #
'#  Created:     20th May 2013                                                  #
'#  Parameters:  None                                                           #
'#  Description: Checks Unisys site using Web Query in Query_Res sheet to get a #
'#               list of products and current IC level/date.                    #
'#               Updates appropriate sheets with information.                   #
'################################################################################
'#  VERSION CONTROL                                                             #
'#  ~~~~~~~~~~~~~~~                                                             #
'#  [V1.0.0]    INITIAL IMPLEMENTATION              {Graham Gold - 20/05/2013}  #
'################################################################################
'[Initialise Variables]
Dim Ans As Long
Dim objQuerySheet As Worksheet
Dim iUpd As Integer
Dim sTmp As String

'[Prompt to remind user to login to Unisys support site first and authentication for web query picked up from browser]
Ans = MsgBox("Ensure you have logged in to Unisys Product Support site before continuing with PRIMUS search", vbOKCancel)
If Ans = vbCancel Then
    Exit Sub
End If

'[Select query sheet and refresh the querytable]
Set objQuerySheet = Sheets("Query_Res")
objQuerySheet.QueryTables(1).Refresh

'[Select WHAT_CHANGED sheet]
Set objMainSheet = Sheets("WHAT_CHANGED")

'[Select A1 cell on Query_Res sheet, copy to sTmp, copy data of this sheet to NEW_FIXES sheet]
Sheets("Query_Res").Select
sTmp = Range("A1")
Sheets("Query_Res").Select
Columns("A:C").Select
Selection.Copy
Sheets("NEW_FIXES").Select
Selection.PasteSpecial Paste:=xlPasteValues, Operation:=xlNone, SkipBlanks _
    :=False, Transpose:=False

'[Select WHAT_CHANGED sheet and update iUpd using calculated value in cell E1 for number of updated products.
' Cell counts cells in column E that contain "http" at start of cell]
Sheets("WHAT_CHANGED").Select
iUpd = Range("F1")

'[Check if refresh worked (Query_Res!A1 should contain the word "Product")]
If sTmp = "Product" Then
    '[No updated products]
    Select Case iUpd
    Case 0:
        '[Advise user and prompt to update local datastore]
        MsgBox ("Unisys Primus query successful - No updated products found.")
        Sheets("WHAT_CHANGED").Select
        Range("B2").Value = Date & " " & Time
        Call Hide_NoUpdate
            
    Case Else
        '[more than one updated product, advise user and primpt to update local datastore]
        MsgBox ("Unisys Primus query successful - " & iUpd & " updated products found." & vbCrLf & "Remember to update local datastore once updates are noted")
            Sheets("WHAT_CHANGED").Select
        Range("B2").Value = Date & " " & Time
        Call Hide_NoUpdate
    End Select
    
Else
    '[Update from PRIMUS failed - query returned login screen]
    MsgBox "Please login to Unisys support site before opening this spreadsheet"
    Sheets("WHAT_CHANGED").Select
End If
End Sub

Sub Update_Local()
'################################################################################
'#  Update_Local Sub                                                            #
'#  ~~~~~~~~~~~~~~~~                                                            #
'#  Author:      Graham Gold                                                    #
'#  Created:     20th May 2013                                                  #
'#  Parameters:  None                                                           #
'#  Description: Updates PREV_FIXES sheet with data from NEW_FIXES.             #
'################################################################################
'#  VERSION CONTROL                                                             #
'#  ~~~~~~~~~~~~~~~                                                             #
'#  [V1.0.0]    INITIAL IMPLEMENTATION              {Graham Gold - 20/05/2013}  #
'################################################################################
Dim Answer As Long
'[Prompt to confirm user wants to update local datastore]
Answer = MsgBox("Are you sure you want to update the local datastore?" & vbCrLf & _
    "Once complete there will be no differences between PRIMUS and local IC versions," & _
    " so please save off current Updates/Values first.", vbOKCancel)
If Answer = vbCancel Then
    Exit Sub
End If
'[Select NEW_FIXES sheet and data]
Sheets("NEW_FIXES").Select
Columns("A:C").Select

'[Copy data]
Selection.Copy

'[Select PREV_FIXES and paste in the data]
Sheets("PREV_FIXES").Select
Selection.PasteSpecial Paste:=xlPasteValues, Operation:=xlNone, SkipBlanks _
        :=False, Transpose:=False

'[Select WHAT_CHANGED sheet, update the Datastore update timestamp and call Hide_No_Update]
Sheets("WHAT_CHANGED").Select
Range("B3").Value = Date & " " & Time
Call Hide_NoUpdate
End Sub

Sub Hide_NoUpdate()
'################################################################################
'#  Hide_NoUpdate Sub                                                           #
'#  ~~~~~~~~~~~~~~~~~                                                           #
'#  Author:      Graham Gold                                                    #
'#  Created:     20th May 2013                                                  #
'#  Parameters:  None                                                           #
'#  Description: Re-applies AutoFilter on WHAT_CHANGED sheet and autofits rows. #
'################################################################################
'#  VERSION CONTROL                                                             #
'#  ~~~~~~~~~~~~~~~                                                             #
'#  [V1.0.0]    INITIAL IMPLEMENTATION              {Graham Gold - 20/05/2013}  #
'################################################################################
    ActiveWorkbook.Worksheets("WHAT_CHANGED").ListObjects("Table2").Range.AutoFilter Field:=5, Criteria1:= _
        "=http*", Operator:=xlAnd
    With ActiveWorkbook.Worksheets("WHAT_CHANGED").Range("A:E")
        .Rows.EntireRow.AutoFit
        .Columns.EntireColumn.AutoFit
    End With
    ActiveWindow.SmallScroll Down:=-100
End Sub

Sub Publish_Sharepoint()
'################################################################################
'#  Publish_Sharepoint Sub                                                      #
'#  ~~~~~~~~~~~~~~~~~~~~~~                                                      #
'#  Author:      Graham Gold                                                    #
'#  Created:     3rd June 2013                                                  #
'#  Parameters:  None                                                           #
'#  Description: Selects table and saves as PDF on UK Mainframe sharepoint site.#
'################################################################################
'#  VERSION CONTROL                                                             #
'#  ~~~~~~~~~~~~~~~                                                             #
'#  [V1.0.0]    INITIAL IMPLEMENTATION              {Graham Gold - 03/06/2013}  #
'################################################################################
    Dim sTS As String
  
    sTS = Right(Date, 4) & Mid(Date, 4, 2) & Left(Date, 2)
        
    Range("A4:E108").Select
    Selection.ExportAsFixedFormat Type:=xlTypePDF, Filename:= _
        "##REDACTED##" & sTS & ".pdf" _
        , Quality:=xlQualityStandard, IncludeDocProperties:=True, IgnorePrintAreas _
        :=True, OpenAfterPublish:=True
    Range("A4").Select
End Sub

Sub LogMeIn()
'################################################################################
'#  LogMeIn Sub                                                                 #
'#  ~~~~~~~~~~~                                                                 #
'#  Author:      Graham Gold                                                    #
'#  Created:     4th June 2013                                                  #
'#  Parameters:  Requires username/password textboxes in form to be populated.  #
'#  Description: Connects to Unisys support site via IE and logs user in.       #
'################################################################################
'#  VERSION CONTROL                                                             #
'#  ~~~~~~~~~~~~~~~                                                             #
'#  [V1.0.0]    INITIAL IMPLEMENTATION              {Graham Gold - 04/06/2013}  #
'################################################################################
    
'[Initialise Variables]
    Dim ie As Object
    Dim objCollection As Object
    Dim objElement As Object
    Dim x
    Dim i As Long
    Dim strUser As String
    Dim strPass As String
    
    '[Grab user/pass values]
    strUser = ActiveSheet.txtUser.text
    strPass = ActiveSheet.txtPass.text
     
    '[Create browser object]
    Application.StatusBar = "Initializing Browser Object"
    Set ie = CreateObject("InternetExplorer.Application")
     
    '[Navigate to login page]
    Application.StatusBar = "Loading Login Page"
    ie.navigate "http://www.support.unisys.com/framework/SSOLogin.aspx"
     
    '[Hide browser and wait for page load to complete]
    Application.StatusBar = "Waiting on completion of initial page load"
    ie.Visible = False
    Do While ie.busy: Application.Wait Now + TimeValue("0:0:01"): Loop
    Do While ie.ReadyState <> 4: Application.Wait Now + TimeValue("0:0:01"): Loop
    Do While ie.document.ReadyState <> "complete": Application.Wait Now + TimeValue("0:0:01"): Loop
               
    '[Check where we are, to determine if already logged in or not - if so, alert user, quit IE, tidy up object and exit sub]
    If ie.LocationURL = "https://www.support.unisys.com/common/epa/home.aspx" Or _
        ie.LocationURL = "http://www.support.unisys.com/common/epa/home.aspx" Then
        MsgBox "Already Logged In!", vbInformation
        ie.Quit
        Set ie = Nothing
        Application.StatusBar = False
        Exit Sub
    End If
               
    '[Check credentials entered on form - alert, tidyup and quit if not.]
    If strUser = "" Or strPass = "" Then
        MsgBox "Username and Password must be supplied!", vbExclamation
        ie.Quit
        Set ie = Nothing
        Application.StatusBar = False
        Exit Sub
    End If
               
    '[Check that username is a properly formatted email address]
    If Not IsMail(strUser) Then
        MsgBox "Username must be a valid email address!", vbExclamation
        ie.Quit
        Set ie = Nothing
        Application.StatusBar = False
        Exit Sub
    End If
               
    '[Not already logged in, so grab credentials from form boxes and set the web page fields]
    Application.StatusBar = "Populating credentials"
    ie.document.GetElementByID("ssousername").Value = strUser
    ie.document.GetElementByID("password").Value = strPass
    
    '[Setup collection of input elements in page, to find the Login button since _
        Oracle Single Sign On (SSO) doesn't name the button, so can't call it easily]
    Set objCollection = ie.document.getElementsByTagName("input")
 
    i = 0
    While i < objCollection.Length
            If objCollection(i).Type = "submit" And _
               objCollection(i).Name = "" Then
                ' "Login" button is found
                Set objElement = objCollection(i)
 
            End If
        i = i + 1
    Wend
    
    '[Submit form]
    Application.StatusBar = "Submitting login page"
    objElement.Click    ' click button to Login
    
    '[Wait on page fully loading]
    Application.StatusBar = "Waiting on logged-in page load completion"
    Do While ie.busy: Application.Wait Now + TimeValue("0:0:01"): Loop
    Do While ie.ReadyState <> 4: Application.Wait Now + TimeValue("0:0:01"): Loop
    Do While ie.document.ReadyState <> "complete": Application.Wait Now + TimeValue("0:0:01"): Loop
    
    '[Check where we are to determine if we've logged in OK - alert, tidyup and quit if not]
    If ie.LocationURL = "https://www.support.unisys.com/common/epa/home.aspx" Or _
        ie.LocationURL = "http://www.support.unisys.com/common/epa/home.aspx" Then
        MsgBox "Login Successful!", vbInformation
        ie.Quit
        Set ie = Nothing
        Set objElement = Nothing
        Set objCollection = Nothing
        Application.StatusBar = False
        Exit Sub
    Else
        MsgBox "Login Failed!", vbCritical
        ie.Quit
        Set ie = Nothing
        Set objElement = Nothing
        Set objCollection = Nothing
        Application.StatusBar = False
        Exit Sub
    End If
    
    '[tidyup]
    Set objElement = Nothing
    Set objCollection = Nothing
    Set ie = Nothing
     
End Sub

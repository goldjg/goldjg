Attribute VB_Name = "Module1"
Function UnisysGetICs(LastChecked As String, Newest As String)
'################################################################################
'#  UnisysGetICs Function                                                       #
'#  ~~~~~~~~~~~~~~~~~~~~~                                                       #
'#  Author:      Graham Gold                                                    #
'#  Created:     20th May 2013                                                  #
'#  Parameters:  LastChecked (String) - Last Unisys IC that was checked         #
'#               Newest (String) - Newest available Unisys IC                   #
'#  Description: Finds IC's released since the LastChecked IC, up to and        #
'#               including the current/newest IC and returns a comma seperated  #
'#               list of IC names as a string.                                  #
'################################################################################
'#  VERSION CONTROL                                                             #
'#  ~~~~~~~~~~~~~~~                                                             #
'#  [V1.0.0]    INITIAL IMPLEMENTATION              {Graham Gold - 20/05/2013}  #
'################################################################################

'[Initialise Variables]
Dim sOldBase As String, sOldNode As Integer
Dim sNewBase As String, sNewNode As Integer
Dim sProduct As String
Dim sReturn As String
Dim bDEPCON As Boolean
Dim o
Dim n
Dim strTmp
Dim i As Integer

'[Compare input params, if they are the same, exit, no new versions]
If LastCheck = Newest Then
    UnisysGetICs = "No New ICs"
    Exit Function
End If

'[Get the base IC name from the LastChecked param (split on period)]
o = Split(LastChecked, ".")

'[should split into 3 fields, grab the first 2]
sOldBase = o(0) & "." & o(1) & "."
sNewBase = o(0) & "." & o(1) & "."

'[Grab the product name]
o = InStrRev(LastChecked, "-")
sProduct = Left(LastChecked, o - 1)

'[Check if Product is DEPCON, which requires special handling, set boolean accordingly]
If sProduct = "DEPCON" Then
    bDEPCON = True
Else
    bDEPCON = False
End If

'[grab the old IC node]
o = InStrRev(LastChecked, ".")

'[If product is DEPCON, need to strip the IC text off the end of the node, using a regular expression]
If bDEPCON Then
strTmp = Right(LastChecked, (Len(LastChecked) - o))
    With CreateObject("vbscript.regexp")
        .Pattern = "[^\d]+"
        .Global = True
        sOldNode = Trim(.Replace(strTmp, vbNullString))
    End With
Else
sOldNode = Right(LastChecked, (Len(LastChecked) - o))
End If

'[grab the new IC node]
n = InStrRev(Newest, ".")

'[If product is DEPCON, need to strip the IC text off the end of the node, using a regular expression]
If bDEPCON Then
strTmp = Right(Newest, (Len(Newest) - n))
    With CreateObject("vbscript.regexp")
        .Pattern = "[^\d]+"
        .Global = True
        sNewNode = Trim(.Replace(strTmp, vbNullString))
    End With
Else
sNewNode = Right(Newest, (Len(Newest) - n))
End If

'[Use i to track ICs, incremement the old node by 1, we don't want to include an IC we've already checked before]
i = sOldNode + 1

'[Build list of new ICs, by adding base and i together to get IC name, increment i on each loop until it equals snewnode+1]
While i < (sNewNode + 1)
    sReturn = sReturn & sNewBase & i
    '[If product is DEPCON, add "IC" to end of IC name]
    If bDEPCON Then
        sReturn = sReturn & "IC"
    End If
    
    '[If more than one IC left, add a comma to end of return string]
    If (sNewNode - i > 0) Then
        sReturn = sReturn & ","
    End If
    i = i + 1
Wend

'[Set Function value to return the list of ICs]
UnisysGetICs = sReturn

End Function


VERSION 5.00
Begin VB.Form Form1 
   Caption         =   "Form1"
   ClientHeight    =   3192
   ClientLeft      =   60
   ClientTop       =   348
   ClientWidth     =   4680
   LinkTopic       =   "Form1"
   ScaleHeight     =   3192
   ScaleWidth      =   4680
   StartUpPosition =   3  'Windows Default
   Begin VB.CommandButton Command1 
      Caption         =   "Command1"
      Height          =   855
      Left            =   960
      TabIndex        =   0
      Top             =   720
      Width           =   2295
   End
End
Attribute VB_Name = "Form1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Sub Command1_Click()

Dim o As New mfdll.pipe
Dim bTemp As Boolean
Dim iFile As Integer, iTemp As Integer
Dim sRec As String



'Set o = CreateObject("mfdll.pipe")

o.bDiag = True
o.lPipeSize = 13000
o.lTimeout = 30000
o.sDiagFile = "c:\mf.txt"
o.sUser = "TEAMDY"
o.sPassword = "TDY"
o.sServer = "BETA"
'o.sPipeName = "\\10.224.3.200\pipe\coms\coms\marc"
o.sPipeName = "\\BETA\pipe\coms\coms\PPAQ05\BETAPIPE11"
bTemp = o.mfOpen
o.mfRead
MsgBox o.sBuffer
iFile = FreeFile
o.sBuffer = ""
Open "c:\jan_input.txt" For Input As #iFile
While Not EOF(iFile)
    Line Input #iFile, sRec
    o.sBuffer = o.sBuffer & sRec
Wend
Close #iFile

iTemp = o.mfWrite
iTemp = o.mfRead

o.mfClose
Set o = Nothing

End Sub

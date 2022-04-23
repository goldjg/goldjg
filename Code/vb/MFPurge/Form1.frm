VERSION 5.00
Begin VB.Form Form1 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "Mainframe Cached Connection Purge Utility"
   ClientHeight    =   1080
   ClientLeft      =   45
   ClientTop       =   435
   ClientWidth     =   5715
   Icon            =   "Form1.frx":0000
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   1080
   ScaleWidth      =   5715
   StartUpPosition =   2  'CenterScreen
   Begin VB.CommandButton cmdClearCache 
      Caption         =   "Clear Cache"
      Height          =   375
      Left            =   3000
      TabIndex        =   1
      Top             =   600
      Width           =   2535
   End
   Begin VB.TextBox txtMF 
      Height          =   375
      Left            =   120
      TabIndex        =   0
      Top             =   600
      Width           =   2655
   End
   Begin VB.Label lblDescription 
      Caption         =   $"Form1.frx":08CA
      Height          =   375
      Left            =   120
      TabIndex        =   2
      Top             =   120
      Width           =   5535
   End
End
Attribute VB_Name = "Form1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Declare Function WNetCancelConnection2 Lib "mpr.dll" Alias "WNetCancelConnection2A" (ByVal lpName As String, ByVal dwFlags As Long, ByVal lpszLocalName As Boolean) As Long


Private Sub cmdClearCache_Click()
    
    'Setup Variables
    Dim strIPC As String
    Dim lDisconnect As Long
    
    'Ensure no cached credentials, remove IPC$ share for host if it exists
    strIPC = "\\" & txtMF.Text & "\IPC$"
    lDisconnect = WNetCancelConnection2(strIPC, 0, True)
    
    Select Case lDisconnect
    Case 0
        MsgBox ("Cached credentials successfuly deleted - Error Code = " & lDisconnect)
    Case 2250
        MsgBox ("Cached credentials not deleted, none stored. Error Code = " & lDisconnect)
    Case Else
        MsgBox ("Cached credentials not deleted, error encountered. Error Code = " & lDisconnect)
    End Select
    
End Sub

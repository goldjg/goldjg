VERSION 5.00
Begin VB.Form Form1 
   Caption         =   "Pipe Harness v0.1a"
   ClientHeight    =   5370
   ClientLeft      =   8850
   ClientTop       =   6090
   ClientWidth     =   6480
   LinkTopic       =   "Form1"
   ScaleHeight     =   5370
   ScaleWidth      =   6480
   StartUpPosition =   2  'CenterScreen
   Begin VB.TextBox Text1 
      BackColor       =   &H00FFFFFF&
      Height          =   3495
      Left            =   240
      Locked          =   -1  'True
      ScrollBars      =   3  'Both
      TabIndex        =   0
      TabStop         =   0   'False
      Top             =   1560
      Width           =   6015
   End
   Begin VB.CommandButton Command2 
      Caption         =   "Quit"
      Height          =   1215
      Left            =   5040
      TabIndex        =   8
      Top             =   120
      Width           =   1335
   End
   Begin VB.ComboBox Combo3 
      Height          =   315
      ItemData        =   "Form1.frx":0000
      Left            =   2760
      List            =   "Form1.frx":0013
      TabIndex        =   6
      Top             =   1080
      Width           =   615
   End
   Begin VB.ComboBox Combo2 
      Height          =   315
      ItemData        =   "Form1.frx":0026
      Left            =   2280
      List            =   "Form1.frx":004E
      TabIndex        =   5
      Top             =   600
      Width           =   1095
   End
   Begin VB.ComboBox Combo1 
      Height          =   315
      ItemData        =   "Form1.frx":00A5
      Left            =   2280
      List            =   "Form1.frx":00B2
      Sorted          =   -1  'True
      TabIndex        =   4
      Top             =   120
      Width           =   1095
   End
   Begin VB.CommandButton Command1 
      Caption         =   "Open Pipe"
      Height          =   1215
      Left            =   3480
      TabIndex        =   7
      Top             =   120
      Width           =   1335
   End
   Begin VB.Label Label3 
      Caption         =   "No. of messages to Send/Receive:"
      Height          =   255
      Left            =   120
      TabIndex        =   1
      Top             =   1200
      Width           =   2535
   End
   Begin VB.Label Label2 
      Caption         =   "Message Size (Characters):"
      Height          =   255
      Left            =   120
      TabIndex        =   2
      Top             =   720
      Width           =   2055
   End
   Begin VB.Label Label1 
      Caption         =   "Server Name:"
      Height          =   255
      Left            =   120
      TabIndex        =   3
      Top             =   240
      Width           =   1095
   End
End
Attribute VB_Name = "Form1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False

Private Sub Command1_Click()
OpenPipes
End Sub

Private Sub Command2_Click()
Unload Form1
End Sub

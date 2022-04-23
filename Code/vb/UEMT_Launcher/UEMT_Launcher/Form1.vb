Public Class Form1
    Public Structure RECT
        Dim Left As Long
        Dim Top As Long
        Dim Right As Long
        Dim Bottom As Long
    End Structure

    Public Structure POINTAPI
        Dim x As Long
        Dim y As Long
    End Structure

    Public Structure WINDOWPLACEMENT
        Dim Length As Long
        Dim flags As Long
        Dim showCmd As Long
        Dim ptMinPosition As POINTAPI
        Dim ptMaxPosition As POINTAPI
        Dim rcNormalPosition As RECT
    End Structure


    Declare Auto Function SetParent Lib "user32.dll" (ByVal hWndChild As IntPtr, ByVal hWndNewParent As IntPtr) As Integer
    Declare Auto Function SendMessage Lib "user32.dll" (ByVal hWnd As IntPtr, ByVal Msg As Integer, ByVal wParam As Integer, ByVal lParam As Integer) As Integer
    Declare Function SetWindowPlacement Lib "user32.dll" (ByVal hwnd As Long, lpwndpl As WINDOWPLACEMENT) As Long


    Private Const WM_SYSCOMMAND As Integer = 274
    Private Const SC_MAXIMIZE As Integer = 61488
    Dim proc As Process
    Dim currWinP As WINDOWPLACEMENT

    Private Sub Form1_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        proc = Process.Start("\\sgcfhppdt01\data_shrdlmd\teamdirs\teamv3\BCA\BC_WIN_MGR\BC_WIN_MGR.exe")
        'proc.WaitForInputIdle()
        Threading.Thread.Sleep(1000)
        SetParent(proc.MainWindowHandle, Me.Panel1.Handle)
        currWinP.Length = Len(Me.Panel1.Handle)
        currWinP.rcNormalPosition.Top = Me.Panel1.Top / 2
        currWinP.rcNormalPosition.Left = Me.Panel1.Left / 2
        currWinP.ptMaxPosition.x = Me.Panel1.Left
        currWinP.ptMaxPosition.y = Me.Panel1.Top
        SetWindowPlacement(proc.Handle, currWinP)
        'SendMessage(proc.MainWindowHandle, WM_SYSCOMMAND, SC_MAXIMIZE, 0)
    End Sub

End Class

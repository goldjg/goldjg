'On the next line, edit the path to and name of the workbook the macro will write the results to
 Const FILE_NAME = "c:\DTSearch.xlsx"
 Const MACRO_NAME = "Date/Time Search"

 Private datBeg As Date, datEnd As Date, timBeg As Date, timEnd As Date
 Private excApp As Object, excWkb As Object, excWks As Object, lngRow

Public Sub BeginSearch()
    Dim strRng As String, arrTmp As Variant, arrDat As Variant, arrTim As Variant
    strRng = InputBox("Enter the date/time range to search in the form Date1 to Date2 from Time1 to Time2", MACRO_NAME, "1/1/2014 to 1/31/2014 from 10:00am to 11:00am")
    If strRng = "" Then
        MsgBox "Search cancelled.", vbInformation + vbOKOnly, MACRO_NAME
    Else
        arrTmp = Split(strRng, " from ")
        arrDat = Split(arrTmp(0), " to ")
        arrTim = Split(arrTmp(1), " to ")
        datBeg = arrDat(0)
        datEnd = arrDat(1)
        timBeg = arrTim(0)
        timEnd = arrTim(1)
        If IsDate(datBeg) And IsDate(datEnd) And IsDate(timBeg) And IsDate(timEnd) Then
            Set excApp = CreateObject("Excel.Application")
            Set excWkb = excApp.Workbooks.Add
            excWkb.Worksheets(3).Delete
            excWkb.Worksheets(2).Delete
            Set excWks = excWkb.Worksheets(1)
            excWks.Cells(1, 1) = "Folder"
            excWks.Cells(1, 2) = "Received"
            excWks.Cells(1, 3) = "Sender"
            excWks.Cells(1, 4) = "Subject"
            lngRow = 2
            SearchSub Application.ActiveExplorer.CurrentFolder
            excWks.Columns("A:D").AutoFit
            excWkb.SaveAs FILE_NAME
            excWkb.Close False
            Set excWks = Nothing
            Set excWkb = Nothing
            Set excApp = Nothing
            MsgBox "Search complete.", vbInformation + vbOKOnly, MACRO_NAME
        Else
            MsgBox "The dates/times you entered are invalid or not in the right format.  Please try again.", vbCritical + vbOKOnly, MACRO_NAME
        End If
    End If
End Sub

Private Sub SearchSub(olkFol As Outlook.MAPIFolder)
    Dim olkHit As Outlook.Items, olkItm As Object, olkSub As Outlook.MAPIFolder, datTim As Date
    'If the current folder contains messages, then search it
    If olkFol.DefaultItemType = olMailItem Then
        Set olkHit = olkFol.Items.Restrict("[ReceivedTime] >= '" & Format(datBeg, "ddddd h:nn AMPM") & "' AND [ReceivedTime] <= '" & Format(datEnd, "ddddd h:nn AMPM") & "'")
        For Each olkItm In olkHit
            If olkItm.Class = olMail Then
                datTim = Format(olkItm.ReceivedTime, "h:n:s")
                If datTim >= timBeg And datTim <= timEnd Then
                    excWks.Cells(lngRow, 1) = olkFol.FolderPath
                    excWks.Cells(lngRow, 2) = olkItm.ReceivedTime
                    excWks.Cells(lngRow, 3) = olkItm.SenderName
                    excWks.Cells(lngRow, 4) = olkItm.Subject
                    lngRow = lngRow + 1
                End If
            End If
            DoEvents
        Next
        Set olkHit = Nothing
        Set olkItm = Nothing
    End If
    'Search the subfolders
    For Each olkSub In olkFol.Folders
        SearchSub olkSub
        DoEvents
    Next
    Set olkSub = Nothing
End Sub


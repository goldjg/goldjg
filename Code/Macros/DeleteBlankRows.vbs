Sub DeleteBlankRows(Optional WorksheetName As Variant)
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' DeleteBlankRows
' This function will delete all blank rows on the worksheet
' named by WorksheetName. This will delete rows that are
' completely blank (every cell = vbNullString) or that have
' cells that contain only an apostrophe (special Text control
' character).
' The code will look at each cell that contains a formula,
' then look at the precedents of that formula, and will not
' delete rows that are a precedent to a formula. This will
' prevent deleting precedents of a formula where those
' precedents are in lower numbered rows than the formula
' (e.g., formula in A10 references A1:A5). If a formula
' references cell that are below (higher row number) the
' last used row (e.g, formula in A10 reference A20:A30 and
' last used row is A15), the refences in the formula will
' be changed due to the deletion of rows above the formula.
'
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

Dim RefColl As Collection
Dim RowNum As Long
Dim Prec As Range
Dim Rng As Range
Dim DeleteRange As Range
Dim LastRow As Long
Dim FormulaCells As Range
Dim Test As Long
Dim WS As Worksheet
Dim PrecCell As Range

If IsMissing(WorksheetName) = True Then
    Set WS = ActiveSheet
Else
    On Error Resume Next
    Set WS = ActiveWorkbook.Worksheets(WorksheetName)
    If Err.Number <> 0 Then
        '''''''''''''''''''''''''''''''
        ' Invalid worksheet name.
        '''''''''''''''''''''''''''''''
        Exit Sub
    End If
End If
    

If Application.WorksheetFunction.CountA(WS.UsedRange.Cells) = 0 Then
    ''''''''''''''''''''''''''''''
    ' Worksheet is blank. Get Out.
    ''''''''''''''''''''''''''''''
    Exit Sub
End If

''''''''''''''''''''''''''''''''''''''
' Find the last used cell on the
' worksheet.
''''''''''''''''''''''''''''''''''''''
Set Rng = WS.Cells.Find(what:="*", after:=WS.Cells(WS.Rows.Count, WS.Columns.Count), lookat:=xlPart, _
    searchorder:=xlByColumns, searchdirection:=xlPrevious, MatchCase:=False)

LastRow = Rng.Row

Set RefColl = New Collection

'''''''''''''''''''''''''''''''''''''
' We go from bottom to top to keep
' the references intact, preventing
' #REF errors.
'''''''''''''''''''''''''''''''''''''
For RowNum = LastRow To 1 Step -1
    Set FormulaCells = Nothing
    If Application.WorksheetFunction.CountA(WS.Rows(RowNum)) = 0 Then
        ''''''''''''''''''''''''''''''''''''
        ' There are no non-blank cells in
        ' row R. See if R is in the RefColl
        ' reference Collection. If not,
        ' add row R to the DeleteRange.
        ''''''''''''''''''''''''''''''''''''
        On Error Resume Next
        Test = RefColl(CStr(RowNum))
        If Err.Number <> 0 Then
            ''''''''''''''''''''''''''
            ' R is not in the RefColl
            ' collection. Add it to
            ' the DeleteRange variable.
            ''''''''''''''''''''''''''
            If DeleteRange Is Nothing Then
                Set DeleteRange = WS.Rows(RowNum)
            Else
                Set DeleteRange = Application.Union(DeleteRange, WS.Rows(RowNum))
            End If
        Else
            ''''''''''''''''''''''''''
            ' R is in the collection.
            ' Do nothing.
            ''''''''''''''''''''''''''
        End If
        On Error GoTo 0
        Err.Clear
    Else
        '''''''''''''''''''''''''''''''''''''
        ' CountA > 0. Find the cells
        ' containing formula, and for
        ' each cell with a formula, find
        ' its precedents. Add the row number
        ' of each precedent to the RefColl
        ' collection.
        '''''''''''''''''''''''''''''''''''''
        If IsRowClear(RowNum:=RowNum) = True Then
            '''''''''''''''''''''''''''''''''
            ' Row contains nothing but blank
            ' cells or cells with only an
            ' apostrophe. Cells that contain
            ' only an apostrophe are counted
            ' by CountA, so we use IsRowClear
            ' to test for only apostrophes.
            ' Test if this row is in the
            ' RefColl collection. If it is
            ' not in the collection, add it
            ' to the DeleteRange.
            '''''''''''''''''''''''''''''''''
            On Error Resume Next
            Test = RefColl(CStr(RowNum))
            If Err.Number = 0 Then
                ''''''''''''''''''''''''''''''''''''''
                ' Row exists in RefColl. That means
                ' a formula is referencing this row.
                ' Do not delete the row.
                ''''''''''''''''''''''''''''''''''''''
            Else
                If DeleteRange Is Nothing Then
                    Set DeleteRange = WS.Rows(RowNum)
                Else
                    Set DeleteRange = Application.Union(DeleteRange, WS.Rows(RowNum))
                End If
            End If
        Else
            On Error Resume Next
            Set FormulaCells = Nothing
            Set FormulaCells = WS.Rows(RowNum).SpecialCells(xlCellTypeFormulas)
            On Error GoTo 0
            If FormulaCells Is Nothing Then
                '''''''''''''''''''''''''
                ' No formulas found. Do
                ' nothing.
                '''''''''''''''''''''''''
            Else
                '''''''''''''''''''''''''''''''''''''''''''''''''''
                ' Formulas found. Loop through the formula
                ' cells, and for each cell, find its precedents
                ' and add the row number of each precedent cell
                ' to the RefColl collection.
                '''''''''''''''''''''''''''''''''''''''''''''''''''
                On Error Resume Next
                For Each Rng In FormulaCells.Cells
                    For Each Prec In Rng.Precedents.Cells
                        RefColl.Add Item:=Prec.Row, key:=CStr(Prec.Row)
                    Next Prec
                Next Rng
                On Error GoTo 0
            End If
        End If
        
    End If
    
    '''''''''''''''''''''''''
    ' Go to the next row,
    ' moving upwards.
    '''''''''''''''''''''''''
Next RowNum


''''''''''''''''''''''''''''''''''''''''''
' If we have rows to delete, delete them.
''''''''''''''''''''''''''''''''''''''''''

If Not DeleteRange Is Nothing Then
    DeleteRange.EntireRow.Delete shift:=xlShiftUp
End If

End Sub
Function IsRowClear(RowNum As Long) As Boolean
''''''''''''''''''''''''''''''''''''''''''''''''''
' IsRowClear
' This procedure returns True if all the cells
' in the row specified by RowNum as empty or
' contains only a "'" character. It returns False
' if the row contains only data or formulas.
''''''''''''''''''''''''''''''''''''''''''''''''''
Dim ColNdx As Long
Dim Rng As Range
ColNdx = 1
Set Rng = Cells(RowNum, ColNdx)
Do Until ColNdx = Columns.Count
    If (Rng.HasFormula = True) Or (Rng.Value <> vbNullString) Then
        IsRowClear = False
        Exit Function
    End If
    Set Rng = Cells(RowNum, ColNdx).End(xlToRight)
    ColNdx = Rng.Column
Loop

IsRowClear = True

End Function

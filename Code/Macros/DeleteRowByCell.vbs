Public Sub DeleteRowOnCell()

On Error Resume Next
Selection.SpecialCells(xlCellTypeBlanks).EntireRow.Delete
ActiveSheet.UsedRange

End Sub
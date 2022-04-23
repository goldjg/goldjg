Sub CMDB_Reconcile_Unisys_LPAR()
'
' CMDB_Reconcile_Unisys_LPAR Macro
'

'
Dim rBcells As Range

Dim rAcells As Range, rLoopCells As Range

Sheets("unisys_mf_lpar").Activate

'Set variable to all used cells

Set rAcells = ActiveSheet.UsedRange

rAcells.Select

'Set variable to all blank cells

Set rBcells = rAcells.SpecialCells(xlCellTypeBlanks)

    'Determine which type of numeric data (formulas, constants or none)
    'Loop through needed cells only see if negative

    For Each rLoopCells In rBcells

            With rLoopCells

               .Interior.ColorIndex = 3

            End With

    Next rLoopCells

End Sub

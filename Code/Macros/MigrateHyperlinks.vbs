Sub Migrate_Hyperlinks()
'
' Migrate_Hyperlinks Macro - Graham Gold 29/07/2005
'*************************
'
' Update all hyperlinks in a document to start with ##REDACTED##
' instead of ##REDACTED## by running this macro within the document.
'

'Turn on field codes in document and replace text within field codes
    ActiveWindow.View.ShowFieldCodes = Not ActiveWindow.View.ShowFieldCodes
    Selection.Find.ClearFormatting
    Selection.Find.Replacement.ClearFormatting
    With Selection.Find
        .Text = "##REDACTED##"
        .Replacement.Text = "##REDACTED##"
        .Forward = True
        .Wrap = wdFindContinue
        .Format = False
        .MatchCase = False
        .MatchWholeWord = False
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
    End With
    Selection.Find.Execute Replace:=wdReplaceAll
    
'Turn off field codes and update all fields to reflect changes
    ActiveWindow.View.ShowFieldCodes = Not ActiveWindow.View.ShowFieldCodes
    ActiveWindow.Document.Fields.Update
    
'Replace normal text within document
    Selection.Find.ClearFormatting
    Selection.Find.Replacement.ClearFormatting
    With Selection.Find
        .Text = "##REDACTED##"
        .Replacement.Text = "##REDACTED##"
        .Forward = True
        .Wrap = wdFindContinue
        .Format = False
        .MatchCase = False
        .MatchWholeWord = False
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
    End With
    Selection.Find.Execute Replace:=wdReplaceAll
    
'Open Header/Footer View and select current header
        If ActiveWindow.View.SplitSpecial <> wdPaneNone Then
        ActiveWindow.Panes(2).Close
    End If
    If ActiveWindow.ActivePane.View.Type = wdNormalView Or ActiveWindow. _
        ActivePane.View.Type = wdOutlineView Or ActiveWindow.ActivePane.View.Type _
         = wdMasterView Then
        ActiveWindow.ActivePane.View.Type = wdPageView
    End If
    ActiveWindow.ActivePane.View.SeekView = wdSeekCurrentPageHeader
    
'Replace text in header
    Selection.Find.ClearFormatting
    Selection.Find.Replacement.ClearFormatting
    With Selection.Find
        .Text = "##REDACTED##"
        .Replacement.Text = "##REDACTED##"
        .Forward = True
        .Wrap = wdFindContinue
        .Format = False
        .MatchCase = False
        .MatchWholeWord = False
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
    End With
    Selection.Find.Execute Replace:=wdReplaceAll
    
'Turn on field codes and replace text within fields in header
    ActiveWindow.ActivePane.View.ShowFieldCodes = Not ActiveWindow.ActivePane.View.ShowFieldCodes
    Selection.Find.ClearFormatting
    Selection.Find.Replacement.ClearFormatting
    With Selection.Find
        .Text = "##REDACTED##"
        .Replacement.Text = "##REDACTED##"
        .Forward = True
        .Wrap = wdFindContinue
        .Format = False
        .MatchCase = False
        .MatchWholeWord = False
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
    End With
    Selection.Find.Execute Replace:=wdReplaceAll
    
'Turn off field codes and repeat the search/replace
    ActiveWindow.ActivePane.View.ShowFieldCodes = Not ActiveWindow.ActivePane.View.ShowFieldCodes
    Selection.Find.ClearFormatting
    Selection.Find.Replacement.ClearFormatting
    With Selection.Find
        .Text = "##REDACTED##"
        .Replacement.Text = "##REDACTED##"
        .Forward = True
        .Wrap = wdFindContinue
        .Format = False
        .MatchCase = False
        .MatchWholeWord = False
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
    End With
    Selection.Find.Execute Replace:=wdReplaceAll
    
'Update header fields
    ActiveWindow.ActivePane.Document.Fields.Update
    
'Change to footer view and search/replace
    If Selection.HeaderFooter.IsHeader = True Then
        ActiveWindow.ActivePane.View.SeekView = wdSeekCurrentPageFooter
    Else
        ActiveWindow.ActivePane.View.SeekView = wdSeekCurrentPageHeader
    End If
    
    Selection.Find.ClearFormatting
    Selection.Find.Replacement.ClearFormatting
    With Selection.Find
        .Text = "##REDACTED##"
        .Replacement.Text = "##REDACTED##"
        .Forward = True
        .Wrap = wdFindContinue
        .Format = False
        .MatchCase = False
        .MatchWholeWord = False
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
    End With
    Selection.Find.Execute Replace:=wdReplaceAll
    
'Turn on field codes and repeat search/replace
    ActiveWindow.ActivePane.View.ShowFieldCodes = Not ActiveWindow.ActivePane.View.ShowFieldCodes
    Selection.Find.ClearFormatting
    Selection.Find.Replacement.ClearFormatting
    With Selection.Find
        .Text = "##REDACTED##"
        .Replacement.Text = "##REDACTED##"
        .Forward = True
        .Wrap = wdFindContinue
        .Format = False
        .MatchCase = False
        .MatchWholeWord = False
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
    End With
    Selection.Find.Execute Replace:=wdReplaceAll

'Turn off field codes, update fields and return to document
    ActiveWindow.ActivePane.View.ShowFieldCodes = Not ActiveWindow.ActivePane.View.ShowFieldCodes
    ActiveWindow.ActivePane.Document.Fields.Update
    ActiveWindow.ActivePane.View.SeekView = wdSeekMainDocument
    ActiveWindow.View.ShowFieldCodes = Not ActiveWindow.View.ShowFieldCodes
    ActiveWindow.View.ShowFieldCodes = Not ActiveWindow.View.ShowFieldCodes
   End Sub

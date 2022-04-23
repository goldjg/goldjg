Option Explicit

' Create the MMC Application object.
Dim objMMC
Set objMMC = Wscript.CreateObject("MMC20.Application")

' Load console file for Event Viewer snap-in.

objMMC.Load("eventvwr.msc")
objMMC.UserControl=1
objMMC.Show
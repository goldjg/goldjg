wscript "c:\##REDACTED##\VBRUNAS.VBS" 	dom\user pwd "mmc eventvwr.msc -s /computer=comp"

cscript "\\##REDACTED##\VBRUNAS.VBS" 	dom\user pwd "mmc eventvwr.msc -s /computer='$TargetComputer$'"
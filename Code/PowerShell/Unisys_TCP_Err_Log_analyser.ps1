cd \\$Env:HomeDataServer\$env:USERNAME
[string[]]$patterns = "DELAY SYN FLAG RESET",`
                       "Reset DPF SYN Flag",`
                       "Resets",`
                       "LOG",`
                       "FILE",`
                       "MCP",`
                       "ANALYZ",`
                       "HWERROR",`
                       " 00 ",`
                       "day",`
                       "^ *$",`
                       "\*\*"
Get-ChildItem *TCPERR.TXT | foreach {Select-String -Pattern $patterns -Path $_.Name -NotMatch | ogv}
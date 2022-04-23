Function Get-Focus{
#bring script back into focus
Add-Type @"
  using System;
  using System.Runtime.InteropServices;
  public class Tricks {
     [DllImport("user32.dll")]
     [return: MarshalAs(UnmanagedType.Bool)]
     public static extern bool SetForegroundWindow(IntPtr hWnd);
  }
"@

$parent = Get-Process -id ((gwmi win32_process -Filter "processid='$pid'").parentprocessid)
If ($parent.Name -eq "cmd") {# Being run by via cmd prompt (batch file)
    $h = (Get-Process cmd).MainWindowHandle
    [void] [Tricks]::SetForegroundWindow($h)
    }
    else{# being run in powershell ISE or console
          $h = (Get-Process -id $pid).MainWindowHandle
          [void] [Tricks]::SetForegroundWindow($h)
    }
} 

Export-ModuleMember -Function Get-Focus
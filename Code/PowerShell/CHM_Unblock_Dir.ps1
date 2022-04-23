gci "K:\MS HTML Help Workshop" *.chm -recurse |`
     ? {-not ($_.PSIsContainer)}|foreach {\\live.sysinternals.com\tools\streams -d $_.Fullname}
# TT-HV05-FC Performance

Friday, March 9, 2018
5:57 AM

```Console
del '\\TT-HV05B\C$\NotBackedUp\Products' -Recurse
robocopy C:\NotBackedUp\Products\ '\\TT-HV05B\C$\NotBackedUp\Products' /E /NP

-------------------------------------------------------------------------------
   ROBOCOPY     ::     Robust File Copy for Windows
-------------------------------------------------------------------------------

  Started : Friday, March 9, 2018 5:47:32 AM
   Source : C:\NotBackedUp\Products\
     Dest : \\TT-HV05B\C$\NotBackedUp\Products\

    Files : *.*

  Options : *.* /S /E /DCOPY:DA /COPY:DAT /NP /R:1000000 /W:30

------------------------------------------------------------------------------

          New Dir          0    C:\NotBackedUp\Products\
          New Dir          4    C:\NotBackedUp\Products\Microsoft\
            New File             325.8 m        MDT-Build-x64.iso
            New File             262.1 m        MDT-Build-x86.iso
            New File             311.4 m        MDT-Deploy-x64.iso
            New File             262.1 m        MDT-Deploy-x86.iso
          New Dir          3    C:\NotBackedUp\Products\Microsoft\Windows Server 2016\
            New File               5.5 g        en_windows_server_2016_updated_feb_2018_x64_dvd_11636692.iso
            New File               5.2 g        en_windows_server_2016_x64_dvd_9327751.iso
            New File               5.4 g        en_windows_server_2016_x64_dvd_9718492.iso

------------------------------------------------------------------------------

               Total    Copied   Skipped  Mismatch    FAILED    Extras
    Dirs :         3         3         0         0         0         0
   Files :         7         7         0         0         0         0
   Bytes :  17.473 g  17.473 g         0         0         0         0
   Times :   0:01:21   0:01:21                       0:00:00   0:00:00


   Speed :           231122057 Bytes/sec.
   Speed :           13224.910 MegaBytes/min.
   Ended : Friday, March 9, 2018 5:48:54 AM
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/64/E29A78A1363EB1C6D91F8E52A32BEC4BB72C5164.png)

---

All four network adapters utilized

- average 62KB/s
- ~500 Mbps each adapter

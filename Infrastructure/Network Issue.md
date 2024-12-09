# Network Issue

Tuesday, November 20, 2018\
7:19 AM

## Repro steps

```PowerShell
cls
```

### # Disable jumbo frames on physical network adapter and corresponding virtual switch

```PowerShell
Get-NetAdapter |
    where { $_.Name -like '*LAN*' } |
    foreach {
        Set-NetAdapterAdvancedProperty `
            -Name $_.Name `
            -DisplayName "Jumbo Packet" -RegistryValue 1514
    }

Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*" |
    sort Name |
    select Name, DisplayValue
```

### # Wait a few seconds after disabling jumbo frames (to avoid error in file copy)

```PowerShell
Start-Sleep -Seconds 10
```

### # Copy large file (with jumbo frames disabled)

```PowerShell
del C:\NotBackedUp\Temp\en_windows_server_2019_x64_dvd_3c2cf1202.iso

robocopy "\\TT-HV05C\C`$\NotBackedUp\Temp" C:\NotBackedUp\Temp *.iso
```

### # Enable jumbo frames on physical network adapter and corresponding virtual switch

```PowerShell
Get-NetAdapter |
    where { $_.Name -like '*LAN*' } |
    foreach {
        Set-NetAdapterAdvancedProperty `
            -Name $_.Name `
            -DisplayName "Jumbo Packet" -RegistryValue 9014
    }

Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*" |
    sort Name |
    select Name, DisplayValue
```

### # Wait a few seconds after enabling jumbo frames (to avoid error in file copy)

```PowerShell
Start-Sleep -Seconds 10
```

### # Copy large file (with jumbo frames enabled)

```PowerShell
del C:\NotBackedUp\Temp\en_windows_server_2019_x64_dvd_3c2cf1202.iso

robocopy "\\TT-HV05C\C`$\NotBackedUp\Temp" C:\NotBackedUp\Temp *.iso
```

## Output

```Text
PS C:\NotBackedUp\Temp>
PS C:\NotBackedUp\Temp> # Disable jumbo frames on physical network adapter and corresponding virtual switch
PS C:\NotBackedUp\Temp>
PS C:\NotBackedUp\Temp> Get-NetAdapter |
>>     where { $_.Name -like '*LAN*' } |
>>     foreach {
>>         Set-NetAdapterAdvancedProperty `
>>             -Name $_.Name `
>>             -DisplayName "Jumbo Packet" -RegistryValue 1514
>>     }
PS C:\NotBackedUp\Temp>
PS C:\NotBackedUp\Temp> Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*" |
>>     sort Name |
>>     select Name, DisplayValue

Name                       DisplayValue
----                       ------------
Ethernet                   Disabled
LAN                        Disabled
vEthernet (Default Switch) Disabled
vEthernet (LAN)            Disabled


PS C:\NotBackedUp\Temp>
PS C:\NotBackedUp\Temp> # Wait a few seconds after disabling jumbo frames (to avoid error in file copy)
PS C:\NotBackedUp\Temp>
PS C:\NotBackedUp\Temp> Start-Sleep -Seconds 10
PS C:\NotBackedUp\Temp>
PS C:\NotBackedUp\Temp> # Copy large file (with jumbo frames disabled)
PS C:\NotBackedUp\Temp>
PS C:\NotBackedUp\Temp> del C:\NotBackedUp\Temp\en_windows_server_2019_x64_dvd_3c2cf1202.iso
PS C:\NotBackedUp\Temp>
PS C:\NotBackedUp\Temp> robocopy "\\TT-HV05C\C`$\NotBackedUp\Temp" C:\NotBackedUp\Temp *.iso

-------------------------------------------------------------------------------
   ROBOCOPY     ::     Robust File Copy for Windows
-------------------------------------------------------------------------------

  Started : Tuesday, November 20, 2018 7:14:35 AM
   Source : \\TT-HV05C\C$\NotBackedUp\Temp\
     Dest : C:\NotBackedUp\Temp\

    Files : *.iso

  Options : /DCOPY:DA /COPY:DAT /R:1000000 /W:30

------------------------------------------------------------------------------

                           1    \\TT-HV05C\C$\NotBackedUp\Temp\
100%        New File               4.2 g        en_windows_server_2019_x64_dvd_3c2cf1202.iso

------------------------------------------------------------------------------

               Total    Copied   Skipped  Mismatch    FAILED    Extras
    Dirs :         1         0         1         0         0         0
   Files :         1         1         0         0         0         0
   Bytes :   4.247 g   4.247 g         0         0         0         0
   Times :   0:00:52   0:00:52                       0:00:00   0:00:00


   Speed :            86240642 Bytes/sec.
   Speed :            4934.729 MegaBytes/min.
   Ended : Tuesday, November 20, 2018 7:15:28 AM

PS C:\NotBackedUp\Temp>
PS C:\NotBackedUp\Temp> # Enable jumbo frames on physical network adapter and corresponding virtual switch
PS C:\NotBackedUp\Temp>
PS C:\NotBackedUp\Temp> Get-NetAdapter |
>>     where { $_.Name -like '*LAN*' } |
>>     foreach {
>>         Set-NetAdapterAdvancedProperty `
>>             -Name $_.Name `
>>             -DisplayName "Jumbo Packet" -RegistryValue 9014
>>     }
PS C:\NotBackedUp\Temp>
PS C:\NotBackedUp\Temp> Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*" |
>>     sort Name |
>>     select Name, DisplayValue

Name                       DisplayValue
----                       ------------
Ethernet                   Disabled
LAN                        9014 Bytes
vEthernet (Default Switch) Disabled
vEthernet (LAN)            9014 Bytes


PS C:\NotBackedUp\Temp>
PS C:\NotBackedUp\Temp> # Wait a few seconds after enabling jumbo frames (to avoid error in file copy)
PS C:\NotBackedUp\Temp>
PS C:\NotBackedUp\Temp> Start-Sleep -Seconds 10
PS C:\NotBackedUp\Temp>
PS C:\NotBackedUp\Temp> # Copy large file (with jumbo frames enabled)
PS C:\NotBackedUp\Temp>
PS C:\NotBackedUp\Temp> del C:\NotBackedUp\Temp\en_windows_server_2019_x64_dvd_3c2cf1202.iso
PS C:\NotBackedUp\Temp>
PS C:\NotBackedUp\Temp> robocopy "\\TT-HV05C\C`$\NotBackedUp\Temp" C:\NotBackedUp\Temp *.iso

-------------------------------------------------------------------------------
   ROBOCOPY     ::     Robust File Copy for Windows
-------------------------------------------------------------------------------

  Started : Tuesday, November 20, 2018 7:15:39 AM
   Source : \\TT-HV05C\C$\NotBackedUp\Temp\
     Dest : C:\NotBackedUp\Temp\

    Files : *.iso

  Options : /DCOPY:DA /COPY:DAT /R:1000000 /W:30

------------------------------------------------------------------------------

                           1    \\TT-HV05C\C$\NotBackedUp\Temp\
100%        New File               4.2 g        en_windows_server_2019_x64_dvd_3c2cf1202.iso

------------------------------------------------------------------------------

               Total    Copied   Skipped  Mismatch    FAILED    Extras
    Dirs :         1         0         1         0         0         0
   Files :         1         1         0         0         0         0
   Bytes :   4.247 g   4.247 g         0         0         0         0
   Times :   0:03:17   0:03:17                       0:00:00   0:00:00


   Speed :            23057904 Bytes/sec.
   Speed :            1319.383 MegaBytes/min.
   Ended : Tuesday, November 20, 2018 7:18:57 AM

PS C:\NotBackedUp\Temp>
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E1/A024C5DAF64EDC3CE9FBE88D3038912F1C4621E1.png)

```PowerShell
Get-NetAdapter -Physical | sort MacAddress | select MacAddress, Name, InterfaceDescription, ifIndex
```

---

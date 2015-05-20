# WS2008-R2-STD

Tuesday, July 29, 2014
11:09 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Install Windows Server 2008 R2 Standard Edition with Service Pack 1

## # Remove disk from virtual CD/DVD drive

```PowerShell
$sh = New-Object -ComObject "Shell.Application"
$sh.Namespace(17).Items() |
    Where-Object { $_.Type -eq "CD Drive" } |
        foreach { $_.InvokeVerb("Eject") }
```

Source:

**Ejecting CDs with PowerShell on remote computer**\
[http://www.purgar.net/ejecting-cds-with-powershell-on-remote-computer/](http://www.purgar.net/ejecting-cds-with-powershell-on-remote-computer/)

## # Set time zone

```PowerShell
tzutil /s "Mountain Standard Time"

tzutil /g
```

## # Set MaxPatchCacheSize to 0

```PowerShell
reg add HKLM\Software\Policies\Microsoft\Windows\Installer /v MaxPatchCacheSize /t REG_DWORD /d 0 /f
```

## # Change drive letter for DVD-ROM

### # To change the drive letter for the DVD-ROM using PowerShell

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
```

## # Copy Toolbox content

```PowerShell
net use \\iceman\ipc$ /USER:TECHTOOLBOX\jjameson

robocopy \\iceman\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E
```

## # Create Temp folder

```PowerShell
mkdir C:\NotBackedUp\Temp
```

## Configure custom icons for folders

- C:\\NotBackedUp
- C:\\NotBackedUp\\Public
- C:\\NotBackedUp\\Temp

## # Configure WSUS

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\WSUS\WSUS - colossus.reg'
```

When prompted to add information to the registry, click **Yes**.

```PowerShell
Restart-Service wuauserv
```

## Install patches using Windows Update (round 1)

Note: Windows Update window abruptly disappears (presumably to install a new version of Windows Update). Start Windows Update a second time.

- 165 important updates available
- ~515 MB
- Approximate time: 1 hour 9 minutes (11:10 AM - 12:19 AM)

## Install patches using Windows Update (round 2)

- 1 important update available
- Approximate time: 1 minute

## Install patches using Windows Update (round 3)

- 13 important updates available
- ~36 MB
- Approximate time: 2 minutes

## # Delete C:\\Windows\\SoftwareDistribution folder (894 MB)

```PowerShell
net stop wuauserv
Remove-Item C:\Windows\SoftwareDistribution -Recurse

Restart-Computer
```

## Check for updates using Windows Update (after removing patches folder)

- **Most recent check for updates: Never -> Most recent check for updates: Today at 12:36 PM**
- C:\\Windows\\SoftwareDistribution folder is now 348 MB

## # Reset WSUS

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\WSUS\Reset WSUS for SysPrep Image.cmd'
```

Note that script contains the following statements:

```Console
    @pause

    net start wuauserv

    wuauclt.exe /resetauthorization /detectnow
```

When prompted to **Press any key to continue . . .**, press CTRL+C to terminate script.

## # Shutdown VM

```PowerShell
Stop-Computer
```

## [STORM] Copy VM before running SysPrep (to avoid issues with running SysPrep multiple times)

```Console
robocopy C:\NotBackedUp\VMs\WS2008-R2-STD "D:\Shares\VM Library\WS2008-R2-STD" /E /MIR
```

## SysPrep VM

- Generalize
- Shutdown

## [STORM] Copy VHD to VM Library

```Console
copy "C:\NotBackedUp\VMs\WS2008-R2-STD\Virtual Hard Disks\WS2008-R2-STD.vhdx" \\iceman\VM-Library\VHDs
```

## [STORM] Restore VHD copied before SysPrep

```Console
copy "D:\Shares\VM Library\WS2008-R2-STD\Virtual Hard Disks\WS2008-R2-STD.vhdx" "C:\NotBackedUp\VMs\WS2008-R2-STD\Virtual Hard Disks"
```

# WS2008-R2-ENT

Monday, April 18, 2016
8:16 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Install Windows Server 2008 R2 Enterprise Edition with Service Pack 1

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

```PowerShell
cls
```

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

```PowerShell
cls
```

## # Create Temp folder

```PowerShell
mkdir C:\NotBackedUp\Temp
```

## Configure custom icons for folders

- C:\\NotBackedUp
- C:\\NotBackedUp\\Public
- C:\\NotBackedUp\\Public\\Toolbox
- C:\\NotBackedUp\\Temp

```PowerShell
cls
```

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

- 203 important updates available
- 773.3 MB - 786.3 MB
- Approximate time: 1 hour 37 minutes (8:28 AM - 10:05 AM)

**TODO:**

## Install patches using Windows Update (round 2)

- 10 important updates available
- 45.2 MB
- Approximate time: ~2 minutes

## # Delete C:\\Windows\\SoftwareDistribution folder

```PowerShell
net stop wuauserv
Remove-Item C:\Windows\SoftwareDistribution -Recurse

Restart-Computer
```

## Check for updates using Windows Update (after removing patches folder)

- **Most recent check for updates: Never -> Most recent check for updates: Today at 10:13 AM**
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

## [WOLVERINE] Copy VM before running SysPrep (to avoid issues with running SysPrep multiple times)

```Console
robocopy C:\NotBackedUp\VMs\WS2008-R2-ENT "F:\NotBackedUp\VMs\WS2008-R2-ENT" /E /MIR
```

## SysPrep VM

- Generalize
- Shutdown

## [WOLVERINE] Copy VHD to VM Library

```Console
copy "C:\NotBackedUp\VMs\WS2008-R2-ENT\Virtual Hard Disks\WS2008-R2-ENT.vhdx" \\iceman\VM-Library\VHDs
```

## [WOLVERINE] Restore VHD copied before SysPrep

```Console
copy "F:\NotBackedUp\VMs\WS2008-R2-ENT\Virtual Hard Disks\WS2008-R2-ENT.vhdx" "C:\NotBackedUp\VMs\WS2008-R2-ENT\Virtual Hard Disks"
```

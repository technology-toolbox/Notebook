# WS2012-R2-STD

Saturday, January 03, 2015
2:40 PM

```Console
12345678901234567890123456789012345678901234567890123456789012345678901234567890

PowerShell
```

## # [STORM] Create virtual machine (WS2012-R2-STD)

```PowerShell
$vmName = "WS2012-R2-STD"

New-VM `
    -Name $vmName `
    -Path C:\NotBackedUp\VMs `
    -MemoryStartupBytes 1GB `
    -SwitchName "Virtual LAN 2 - 192.168.10.x"

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VHD -Path $vhdPath -SizeBytes 32GB

Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath

$isoPath = "\\iceman.corp.technologytoolbox.com\Products\Microsoft" `
    + "\Windows Server 2012 R2" `
    + "\en_windows_server_2012_r2_with_update_x64_dvd_4065220.iso"

Set-VMDvdDrive -VMName $vmName -Path $isoPath

Start-VM $vmName
```

## Install Windows Server 2012 R2 Standard Edition with Update

When prompted to select the operating system to install, select **Windows Server 2012 R2 Standard (Server with a GUI)**.

## # Remove disk from virtual CD/DVD drive

```PowerShell
$sh = New-Object -ComObject "Shell.Application"
$sh.Namespace(17).Items() |
    Where-Object { $_.Type -eq "CD Drive" } |
        foreach { $_.InvokeVerb("Eject") }
```

Reference:

**Ejecting CDs with PowerShell on remote computer**\
[http://www.purgar.net/ejecting-cds-with-powershell-on-remote-computer/](http://www.purgar.net/ejecting-cds-with-powershell-on-remote-computer/)

```Console
cls
```

**# Set time zone**

```Console
tzutil /s "Mountain Standard Time"
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

```PowerShell
cls
```

## # Download PowerShell help files

```PowerShell
Update-Help
```

```PowerShell
cls
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

- 67 important updates available
- ~1.6 GB
- Approximate time: 1 hour 32 minutes (6:34 AM - 8:06 AM) - Hyper-V on STORM
- Approximate time: 1 hour 21 minutes (8:43 AM - ) - VirtualBox on WOLVERINE

## Install patches using Windows Update (round 2)

- 3 important updates available
- ~173 MB
- Approximate time: 5 minutes (8:30 AM - 8:33 AM)

## # Delete C:\\Windows\\SoftwareDistribution folder (1.73 GB)

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse

Restart-Computer
```

## Check for updates using Windows Update (after removing patches folder)

- **Most recent check for updates: Never -> Most recent check for updates: Today at 8:45 AM**
- C:\\Windows\\SoftwareDistribution folder is now 43 MB

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

```PowerShell
cls
```

## # [STORM] Copy VM before running SysPrep (to avoid issues with running SysPrep multiple times)

```PowerShell
robocopy C:\NotBackedUp\VMs\WS2012-R2-STD "D:\Shares\VM Library\WS2012-R2-STD" /E /MIR
```

```PowerShell
cls
```

**# [STORM] Start VM**

```PowerShell
Start-VM WS2012-R2-STD
```

## # SysPrep VM

```PowerShell
C:\Windows\system32\Sysprep\sysprep.exe /generalize /oobe /shutdown
```

```PowerShell
cls
```

## # [STORM] Copy VHD to VM Library

```PowerShell
copy "C:\NotBackedUp\VMs\WS2012-R2-STD\Virtual Hard Disks\WS2012-R2-STD.vhdx" \\iceman\VM-Library\VHDs
```

```PowerShell
cls
```

**# [STORM] Restore VHD copied before SysPrep**

```Console
copy "D:\Shares\VM Library\WS2012-R2-STD\Virtual Hard Disks\WS2012-R2-STD.vhdx" "C:\NotBackedUp\VMs\WS2012-R2-STD\Virtual Hard Disks"
```

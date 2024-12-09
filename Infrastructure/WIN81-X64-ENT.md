# WIN81-X64-ENT

Sunday, June 22, 2014\
6:16 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Install Windows 8.1 Enterprise Edition (x64) with Update

## Remove disk from virtual CD/DVD drive

## Start VM

1. Set timezone to **(UTC-07:00) Mountain Time (US & Canada)**
2. Create user - **foo2**
3. Sign out
4. Login as **foo**
5. Delete **foo2** account

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

## # Download PowerShell help files

```PowerShell
Update-Help
```

## # Copy Toolbox content

```PowerShell
net use \\iceman\ipc$ /USER:TECHTOOLBOX\jjameson

robocopy \\iceman\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E
```

## # Configure WSUS

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\WSUS\WSUS - colossus.reg'
```

## Install updates

## # Delete C:\\Windows\\SoftwareDistribution folder

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse

Restart-Computer
```

## Check for updates

## SysPrep VM

- Generalize
- Shutdown

## Copy VHD to VM Library

```Console
copy C:\NotBackedUp\VMs\WIN81-X64-ENT\WIN81-X64-ENT.vhdx \\iceman\VM-Library\VHDs\WIN81-X64-ENT-with-Update_RTM.vhdx
```

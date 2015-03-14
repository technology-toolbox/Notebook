# WIN7-TEST2 (2015-03-13) - Windows 7 Ultimate (x64)

Friday, March 13, 2015
11:59 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## WIN7-TEST2 - Baseline

Windows 7 (64-bit)\
Microsoft Office Professional Plus 2010\
Microsoft SharePoint Designer 2010\
Microsoft Visio Premium 2010\
Adobe Reader 8.3\
Mozilla Firefox 17.0\
Mozilla Thunderbird 17.0\
Google Chrome\
Remote Server Administration Tools for Windows 7 SP1\
Microsoft Security Essentials\
Disk Cleanup\
Internet Explorer 10

## Configure VM settings

- **General**
  - **Advanced**
    - **Shared Clipboard: Bidirectional**
- **Network**
  - **Adapter 1**
    - **Attached to: Bridged adapter**

## Install Windows 7 Ultimate (x64)

## Reduce paging file size

Virtual Memory

- Automatically manage paging file size for all drives: No
- C: drive
  - Custom size
  - Initial size (MB): 512
  - Maximum size (MB): 1024

## Install VirtualBox Guest Additions

## # Set MaxPatchCacheSize to 0

```PowerShell
reg add HKLM\Software\Policies\Microsoft\Windows\Installer /v MaxPatchCacheSize /t REG_DWORD /d 0 /f
```

## # Copy Toolbox content

```PowerShell
net use \\iceman\ipc$ /USER:TECHTOOLBOX\jjameson

robocopy \\iceman\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E
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

## # Join domain

```PowerShell
Add-Computer -DomainName corp.technologytoolbox.com -Credential (Get-Credential)

Restart-Computer
```

## # Enter a product key and activate Windows

```PowerShell
slmgr /ipk {product key}
```

### # Click OK to dismiss dialog box

```PowerShell
slmgr /ato
```

## Install Microsoft Office Professional Plus 2010 (x86)

## Install Microsoft SharePoint Designer 2010 (x86)

## Install Microsoft Visio Premium 2010 (x86)

## Install Adobe Reader 8.3

"[\\\\iceman\\Products\\Adobe\\AdbeRdr830_en_US.msi](\\iceman\Products\Adobe\AdbeRdr830_en_US.msi)"

"[\\\\iceman\\Products\\Adobe\\AdbeRdrUpd831_all_incr.msp](\\iceman\Products\Adobe\AdbeRdrUpd831_all_incr.msp)"

## Install Mozilla Firefox 36.0

## Install Mozilla Thunderbird 31.3

"[\\\\ICEMAN\\Products\\Mozilla\\Thunderbird\\Thunderbird](\\ICEMAN\Products\Mozilla\Thunderbird\Thunderbird) Setup 31.3.0.exe" -ms

## Install Google Chrome

## Install Remote Server Administration Tools for Windows 7 SP1

## Install Microsoft Security Essentials

## Install updates

### # Delete C:\\Windows\\SoftwareDistribution folder

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse

Restart-Computer
```

Check for updates

## Disk Cleanup

## # Shutdown VM

```PowerShell
Stop-Computer
```

## Remove disk from virtual CD/DVD drive

## Snapshot VM - "Baseline"

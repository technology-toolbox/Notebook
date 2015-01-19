# WIN8-DEV1

Monday, January 19, 2015
8:12 AM

12345678901234567890123456789012345678901234567890123456789012345678901234567890

## WIN8-DEV1- Baseline

Windows 8.1 Enterprise with Update (x64)\
Visual Studio 2013 with Update 4\
Web Essentials 2013 for Update 4\
Node.js\
Adobe Reader 8.3\
Mozilla Firefox 35.0\
Google Chrome

## Install Windows 8.1 Enterprise with Update (x64)

## Install VirtualBox Guest Additions

## Configure VM settings

- **General**
  - **Advanced**
    - **Shared Clipboard: Bidirectional**
- **Network**
  - **Adapter 1**
    - **Attached to: Bridged adapter**

## # Set time zone

```PowerShell
tzutil /s "Mountain Standard Time"
```

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

### # To change the drive letter for the DVD-ROM using PowerShell

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
Add-Computer -DomainName corp.technologytoolbox.com -Restart
```

## # Enter a product key and activate Windows

```PowerShell
slmgr /ipk {product key}
```

# Click OK to dismiss dialog box

```Console
slmgr /ato
```

## # Download PowerShell help files

## Update-Help

## Install Microsoft Visual Studio 2013 Ultimate with Update 4

## Install Web Essentials 2013 for Update 4

## Install Node.js

## Install Adobe Reader 8.3

"[\\\\iceman\\Products\\Adobe\\AdbeRdr830_en_US.msi](\\iceman\Products\Adobe\AdbeRdr830_en_US.msi)"

"[\\\\iceman\\Products\\Adobe\\AdbeRdrUpd831_all_incr.msp](\\iceman\Products\Adobe\AdbeRdrUpd831_all_incr.msp)"

## Install Mozilla Firefox

"[\\\\ICEMAN\\Products\\Mozilla\\Firefox\\Firefox](\\ICEMAN\Products\Mozilla\Firefox\Firefox) Setup 35.0.exe" -ms

## Install Google Chrome

## Install updates

## # Delete C:\\Windows\\SoftwareDistribution folder

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse

Restart-Computer
```

## Check for updates

## Disk Cleanup

## Reduce paging file size

**Virtual Memory**

- **Automatically manage paging file size for all drives: No**
- **C: drive**
  - **Custom size**
  - **Initial size (MB): 512**
  - **Maximum size (MB): 1024**

## # Shutdown VM

```PowerShell
Stop-Computer
```

## Remove disk from virtual CD/DVD drive

## Snapshot VM - "Baseline"

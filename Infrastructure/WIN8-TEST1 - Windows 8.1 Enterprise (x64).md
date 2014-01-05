# WIN8-TEST1 (2014-01-05) - Windows 8.1 Enterprise (x64)

Sunday, January 05, 2014
5:20 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Create VM

- Processors: **2**
- Memory: **2048 MB**
- VDI size: **30 GB**

## Configure VM settings

- General
  - Advanced
    - Shared Clipboard:** Bidirectional**
- Network
  - Adapter 1
    - Attached to:** Bridged adapter**

## Install custom Windows 8.1 Enterprise x64 image

- Windows 8.1 Enterprise x64 with Update, build 6.3.9600.17415
- Microsoft .NET Framework 3.5
- Microsoft Office 2013 Professional Plus with Service Pack 1 - x86
- Additional applications:
  - Adobe Reader 8.3.1
  - Google Chrome
  - Microsoft SharePoint Designer 2013 with Service Pack 1 - x86
  - Mozilla Firefox 36.0
  - Mozilla Thunderbird 31.3.0

## Install VirtualBox Guest Additions

```PowerShell
cls
```

## # Set password for local Administrator account

```PowerShell
$adminUser = [ADSI] "WinNT://./Administrator,User"
$adminUser.SetPassword("{password}")
```

## Activate Microsoft Office

1. Start Word 2013
2. Enter product key

```PowerShell
cls
```

## # Delete C:\\Windows\\SoftwareDistribution folder (677 MB)

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse
```

```PowerShell
cls
```

## # Shutdown VM

```PowerShell
Stop-Computer
```

## Remove disk from virtual CD/DVD drive

## Snapshot VM - "Baseline"

Windows 8.1 Enterprise with Update (x64)\
Microsoft Office Professional Plus 2013 with Service Pack 1 - x86\
Microsoft SharePoint Designer 2013 with Service Pack 1 - x86\
Adobe Reader 8.3.1\
Google Chrome\
Mozilla Firefox 36.0\
Mozilla Thunderbird 31.3.0\
Remote Server Administration Tools for Windows 8.1\
Hyper-V Management Tools enabled

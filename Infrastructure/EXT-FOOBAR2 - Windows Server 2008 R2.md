# EXT-FOOBAR2 (2014-12-05) - Windows Server 2008 R2 Standard

Friday, December 05, 2014
11:20 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## # Rename network connection

```PowerShell
Get-NetAdapter -Physical

Get-NetAdapter -InterfaceAlias "Ethernet" |
    Rename-NetAdapter -NewName "LAN 1 - 192.168.10.x"
```

## # Configure static IPv4 address

```PowerShell
$ipAddress = "192.168.10.216"

New-NetIPAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -IPAddress $ipAddress `
    -PrefixLength 24 `
    -DefaultGateway 192.168.10.1

Set-DNSClientServerAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -ServerAddresses 192.168.10.209,192.168.10.210
```

## # Configure static IPv6 address

```PowerShell
$ipAddress = "2601:1:8200:6000::216"

New-NetIPAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -IPAddress $ipAddress `
    -PrefixLength 64

Set-DNSClientServerAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -ServerAddresses 2601:1:8200:6000::209,2601:1:8200:6000::210
```

## # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name "LAN 1 - 192.168.10.x" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

ping EXT-DC01 -f -l 8900
```

## # Rename the server and join domain

```PowerShell
Rename-Computer -NewName EXT-FOOBAR2 -Restart

Add-Computer -DomainName extranet.technologytoolbox.com -Restart
```

## # Download PowerShell help files

```PowerShell
Update-Help
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

## Configure VM storage (Data01, Log01, and Temp01)

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 40 GB       | 4K                   |              |
| 1    | D:           | 2 GB        | 64K                  | Data01       |
| 2    | L:           | 1 GB        | 64K                  | Log01        |
| 3    | T:           | 1 GB        | 64K                  | Temp01       |

**Configure page file**

- **C:**
  - Initial size (MB): **512**
  - Maximum size (MB): **1024**

## Install Windows PowerShell Integrated Scripting Environment

## Install Visual Studio 2013 with Update 4 (failed)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/69/B3EBB83B9ADB3B5EF6CD5739119E0CD66FCDD369.png)

## Install Internet Explorer 10 (using WSUS)

## Install Visual Studio 2013 with Update 4

In the **Optional features to install** list, clear the checkbox for **Microsoft Foundation Classes for C++**

## Install SQL Server 2008 R2

## Install SQL Server 2008 R2 Service Pack 3

## Change databases to Simple recovery model

## Install Prince

## Install Microsoft Office Professional Plus 2013

## Install Microsoft Visio Professional 2013

## Install Microsoft SharePoint Designer 2010

## Install additional service packs and updates (Windows Update)

## Install additional browsers and software

- Mozilla Firefox
- **Mozilla Thunderbird**
- Google Chrome
- Adobe Flash Player
- Adobe Reader

## # Delete C:\\Windows\\SoftwareDistribution folder (> 2.5GB)

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse

Restart-Computer
```

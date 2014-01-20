# FOOBAR12 - Windows Server 2012 R2 Standard

Sunday, January 19, 2014
10:39 AM

```Console
12345678901234567890123456789012345678901234567890123456789012345678901234567890

PowerShell
```

## Create virtual machine (clone WS2012-R2-STD)

## # Set time zone

```PowerShell
tzutil /s "Mountain Standard Time"

tzutil /g
```

## # Rename the server and join domain

```PowerShell
Rename-Computer -NewName FOOBAR12 -Restart

Add-Computer -DomainName corp.technologytoolbox.com -Restart
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

## # Rename network connection

```PowerShell
Get-NetAdapter -Physical

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "LAN 1 - 192.168.10.x"
```

## # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name "LAN 1 - 192.168.10.x" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

ping ICEMAN -f -l 8900
```

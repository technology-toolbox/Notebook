# EXT-GW01B - Windows Server 2016

Friday, January 13, 2017
1:37 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure server infrastructure

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "FORGE"
$vmName = "EXT-GW01B"
$vmPath = "E:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"
$isoPath = "\\ICEMAN\Products\Microsoft\Windows Server 2016" `
    + "\en_windows_server_2016_x64_dvd_9327751.iso"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 2GB `
    -SwitchName "Production"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 2 `
    -DynamicMemory `
    -MemoryMaximumBytes 4GB

Set-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path $isoPath

Start-VM -ComputerName $vmHost -Name $vmName
```

---

## Install Windows Server 2016 Standard ("Core")

```Console
PowerShell
```

```Console
cls
```

## # Set time zone

```PowerShell
tzutil /s "Mountain Standard Time"
```

## # Rename local Administrator account

```PowerShell
$adminUser = [ADSI] 'WinNT://./Administrator,User'
$adminUser.Rename('foo')

logoff
```

## Login as local administrator account

```Console
PowerShell
```

```Console
cls
```

## # Configure network settings

```PowerShell
$interfaceAlias = "Datacenter 1"
```

### # Rename network connection

```PowerShell
Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

### # Configure DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 192.168.10.209,192.168.10.210

Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 2603:300b:802:8900::209,2603:300b:802:8900::210
```

### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping ICEMAN -f -l 8900
```

```PowerShell
cls
```

## # Rename the server and join domain

```PowerShell
Rename-Computer -NewName EXT-GW01B -Restart
```

> **Note**
>
> Wait for the VM to restart.

```Console
PowerShell

Add-Computer -DomainName extranet.technologytoolbox.com -Restart
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Remove disk from virtual CD/DVD drive

```PowerShell
$vmHost = "FORGE"
$vmName = "EXT-GW01B"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

---

---

**EXT-DC01 - Run as EXTRANET\\jjameson-admin**

```PowerShell
cls
```

## # Move computer to "Servers" OU

```PowerShell
$computer = "EXT-GW01B"

$targetPath = ("OU=Servers,OU=Resources,OU=IT" `
    + ",DC=extranet,DC=technologytoolbox,DC=com")

Get-ADComputer $computer | Move-ADObject -TargetPath $targetPath
```

---

## Login as EXTRANET\\jjameson-admin

```Console
PowerShell
```

```Console
cls
```

## # Copy Toolbox content

```PowerShell
$source = "\\ICEMAN.corp.technologytoolbox.com\Public\Toolbox"
$destination = "C:\NotBackedUp\Public\Toolbox"

net use $source /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```Console
robocopy $source $destination  /E /XD "Microsoft SDKs"
```

## # Set MaxPatchCacheSize to 0 (Recommended)

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

## # Select "High performance" power scheme

```PowerShell
powercfg.exe /L
powercfg.exe /S SCHEME_MIN
powercfg.exe /L
```

## # Configure storage

### # Change drive letter for DVD-ROM

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
```

## Issue - Windows Update hangs downloading cumulative update

### Reference

**Windows Update Step hanging - Windows 10 1607**\
From <[https://social.technet.microsoft.com/Forums/en-US/35309dd8-f87a-41e1-8a20-33ffbb2648e2/windows-update-step-hanging-windows-10-1607?forum=mdt](https://social.technet.microsoft.com/Forums/en-US/35309dd8-f87a-41e1-8a20-33ffbb2648e2/windows-update-step-hanging-windows-10-1607?forum=mdt)>

In order for the MDT Windows Update action to work when having a local WSUS (known bug), you really need to slipstream [KB3197954](KB3197954) or later into the image during the WinPE phase. In MDT that is done by adding it as a package in the Deployment Workbench, and create a selection profile for Windows 10 x64 v1607.

From <[http://deploymentresearch.com/Research/Post/540/Building-a-Windows-10-v1607-reference-image-using-MDT-2013-Update-2](http://deploymentresearch.com/Research/Post/540/Building-a-Windows-10-v1607-reference-image-using-MDT-2013-Update-2)>

```PowerShell
cls
```

### # Solution - Install cumulative update for Windows Server 2016

```PowerShell
$source = "\\ICEMAN\Products\Microsoft\Windows 10\Patches"
$destination = "C:\NotBackedUp\Temp"
$patch = "windows10.0-kb3213522-x64_fc88893ff1fbe75cac5f5aae7ff1becee55c89dd.msu"

net use $source /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
robocopy $source $destination $patch

& "$destination\$patch"
```

> **Note**
>
> When prompted, restart the computer to complete the installation.

```PowerShell
PowerShell
```

```PowerShell
cls
Remove-Item ("C:\NotBackedUp\Temp" `
    + "\windows10.0-kb3213522-x64_fc88893ff1fbe75cac5f5aae7ff1becee55c89dd.msu")
```

## # Add VMM administrators domain group to local Administrators group

```PowerShell
$domain = "TECHTOOLBOX"
$domainGroup = "VMM Admins"

([ADSI]"WinNT://./Administrators,group").Add(
    "WinNT://$domain/$domainGroup,group")

logoff
```

## Install RRAS roles

### Login as TECHTOOLBOX\\setup-vmm

```Console
PowerShell
```

```Console
cls

Install-WindowsFeature RemoteAccess -IncludeManagementTools
Install-WindowsFeature DirectAccess-VPN -IncludeManagementTools
Install-WindowsFeature Routing -IncludeManagementTools

Restart-Computer
```

## Install patches using Windows Update

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Update VM baseline

```PowerShell
$vmHost = "FORGE"
$vmName = "EXT-GW01B"

C:\NotBackedUp\Public\Toolbox\PowerShell\Update-VMBaseline `
    -ComputerName $vmHost `
    -Name $vmName `
    -Confirm:$false

Start-VM -ComputerName $vmHost -Name $vmName
```

---

## Configure failover clustering

### Login as TECHTOOLBOX\\setup-vmm

```PowerShell
cls
```

### # Install Failover Clustering feature

```PowerShell
Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools
```

## Configure gateway service

---

**FOOBAR8** - Run as administrator

```PowerShell
cls
```

### # Add a second network adapter for network virtualization

```PowerShell
$vmHost = "FORGE"
$vmName = "EXT-GW01B"

Stop-VM -ComputerName $vmHost -Name $vmName

Add-VMNetworkAdapter -ComputerName $vmHost -VMName $vmName

Start-VM -ComputerName $vmHost -Name $vmName
```

---

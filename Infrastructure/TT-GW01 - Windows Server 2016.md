# TT-GW01 - Windows Server 2016

Sunday, January 15, 2017
5:49 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV01A"
$vmName = "TT-GW01"
$vmPath = "E:\NotBackedUp\VMs"
$vhdFolderPath = "$vmPath\$vmName\Virtual Hard Disks"
$vhdPath = "$vhdFolderPath\$vmName.vhdx"
$sysPrepedImage = "\\ICEMAN\VMM-Library\VHDs\WS2016-Std-Core.vhdx"

$vhdUncPath = "\\$vmHost\" + $vhdPath.Replace(":", "`$")

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 2GB `
    -SwitchName "Tenant vSwitch"

Copy-Item $sysPrepedImage $vhdUncPath

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 2 `
    -DynamicMemory `
    -MemoryMaximumBytes 4GB

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Set password for the local Administrator account

```Console
PowerShell
```

```Console
cls
```

### # Rename local Administrator account

```PowerShell
$adminUser = [ADSI] 'WinNT://./Administrator,User'

$adminUser.Rename('foo')

logoff
```

### Rename server and join domain

#### Login as local administrator account

```Console
PowerShell
```

```Console
cls
```

### # Rename server

```PowerShell
Rename-Computer -NewName TT-GW01 -Restart
```

> **Note**
>
> Wait for the VM to restart.

#### Login as local administrator account

```Console
PowerShell
```

```Console
cls
```

### # Join server to domain

```PowerShell
Add-Computer -DomainName corp.technologytoolbox.com -Restart
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Move computer to different OU

```PowerShell
$vmName = "TT-GW01"
$targetPath = ("OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

### # Add fabric administrators domain group to local Administrators group on gateway server

```PowerShell
$scriptBlock = {
    net localgroup Administrators "TECHTOOLBOX\Fabric Admins" /ADD
}

Invoke-Command -ComputerName $vmName -ScriptBlock $scriptBlock
```

---

## Configure networking

### Login as fabric adminstrator

```Console
PowerShell
```

```Console
cls
```

### # Configure network settings

```PowerShell
$interfaceAlias = "Datacenter 1"
```

#### # Rename network connection

```PowerShell
Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping ICEMAN -f -l 8900
```

---

**FOOBAR8**

```PowerShell
cls
```

### # Add a second network adapter for network virtualization

```PowerShell
$vmHost = "TT-HV01A"
$vmName = "TT-GW01"

Stop-VM -ComputerName $vmHost -Name $vmName

Add-VMNetworkAdapter -ComputerName $vmHost -VMName $vmName

Start-VM -ComputerName $vmHost -Name $vmName
```

---

#### Login as fabric adminstrator

```Console
PowerShell
```

```Console
cls
```

#### # Rename "back end" network adapter used for network virtualization

```PowerShell
Get-NetAdapter |
    ? { $_.Status -eq "Disconnected" } |
    Rename-NetAdapter -NewName "Back end (network virtualization)"
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

## Deploy multitenant gateway

### # Install role services and features

```PowerShell
Install-WindowsFeature `
    -Name RemoteAccess, DirectAccess-VPN, Routing `
    -IncludeManagementTools `
    -Restart
```

### Login using fabric administrator account

```Console
PowerShell
```

```Console
cls
```

### # Install patches using Windows Update

```PowerShell
sconfig
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Update VM baseline

```PowerShell
$vmHost = "TT-HV01A"
$vmName = "TT-GW01"

C:\NotBackedUp\Public\Toolbox\PowerShell\Update-VMBaseline `
    -ComputerName $vmHost `
    -Name $vmName `
    -Confirm:$false

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Login using fabric administrator account

```Console
PowerShell
```

```Console
cls
```

### # Install remote access and enable multitenancy

```PowerShell
Install-RemoteAccess -MultiTenancy
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Add VMM administrators domain group to local Administrators group on gateway server

```PowerShell
$vmName = "TT-GW01"

$scriptBlock = {
    net localgroup Administrators "TECHTOOLBOX\VMM Admins" /ADD
}

Invoke-Command -ComputerName $vmName -ScriptBlock $scriptBlock
```

---

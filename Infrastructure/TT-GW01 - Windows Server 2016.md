# TT-GW01 - Windows Server 2016

Wednesday, February 1, 2017
5:36 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

---

**FOOBAR8** - Run as administrator

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV03"
$vmName = "TT-GW01"
$vmPath = "D:\NotBackedUp\VMs"
$vhdFolderPath = "$vmPath\$vmName\Virtual Hard Disks"
$vhdPath = "$vhdFolderPath\$vmName.vhdx"
$sysPrepedImage = "\\TT-FS01\VM-Library\VHDs\WS2012-R2-Std-Core.vhdx"

$vhdUncPath = "\\$vmHost\" + $vhdPath.Replace(":", "`$")

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 2GB `
    -SwitchName "Tenant Logical Switch"

Copy-Item $sysPrepedImage $vhdUncPath

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 2 `
    -DynamicMemory `
    -MemoryMinimumBytes 2GB `
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

---

**TT-VMM01A** - Run as administrator

```PowerShell
cls
```

### # Configure static IP address using VMM

```PowerShell
$vmName = "TT-GW01"

$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"

$vmNetwork = Get-SCVMNetwork -Name "Management VM Network"

$ipPool = Get-SCStaticIPAddressPool -Name "Tenant Address Pool"

$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName

Stop-SCVirtualMachine $vmName

$macAddress = Grant-SCMACAddress `
    -MACAddressPool $macAddressPool `
    -Description $vmName `
    -VirtualNetworkAdapter $networkAdapter

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -MACAddressType Static `
    -MACAddress $macAddress

$ipAddress = Grant-SCIPAddress `
    -GrantToObjectType VirtualNetworkAdapter `
    -GrantToObjectID $networkAdapter.ID `
    -StaticIPAddressPool $ipPool `
    -Description $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -IPv4AddressType Static `
    -IPv4Addresses $IPAddress.Address

Start-SCVirtualMachine $vmName
```

---

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

**FOOBAR8** - Run as administrator

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

ping TT-FS01 -f -l 8900
```

---

**FOOBAR8** - Run as administrator

```PowerShell
cls
```

### # Add a second network adapter for network virtualization

```PowerShell
$vmHost = "TT-HV03"
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

#### # Rename "front end" network adapter used for gateway

```PowerShell
$interfaceAlias = "Front end (gateway)"
```

#### # Rename network connection

```PowerShell
Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter #2" |
    Rename-NetAdapter -NewName $interfaceAlias
```

#### # Configure static IPv4 addresses

```PowerShell
$ipAddress = "192.168.10.254"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24
```

```PowerShell
cls
```

#### # Rename "back end" network adapter used for network virtualization

```PowerShell
Get-NetAdapter |
    where { $_.Status -eq "Disconnected" } |
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

## # Deploy multitenant gateway

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

### # Add VMM administrators domain group to local Administrators group on gateway server

```PowerShell
net localgroup Administrators "TECHTOOLBOX\VMM Admins" /ADD
```

### # Install remote access and enable multitenancy

```PowerShell
Install-RemoteAccess -MultiTenancy
```

---

**FOOBAR8** - Run as administrator

```PowerShell
cls
```

### # Update VM baseline

```PowerShell
$vmHost = "TT-HV03"
$vmName = "TT-GW01"

C:\NotBackedUp\Public\Toolbox\PowerShell\Update-VMBaseline `
    -ComputerName $vmHost `
    -Name $vmName `
    -Confirm:$false

Start-VM -ComputerName $vmHost -Name $vmName
```

---

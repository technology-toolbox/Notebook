# TT-GW02 - Windows Server 2012 R2

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
$vmName = "TT-GW02"
$vmPath = "E:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"
$isoPath = "C:\NotBackedUp\Temp\MDT-Deploy-x64.iso"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 4GB `
    -SwitchName "Tenant vSwitch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 2 `
    -StaticMemory

Set-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path $isoPath

Start-VM -ComputerName $vmHost -Name $vmName
```

---

## Install custom Windows Server 2012 R2image

- On the **Task Sequence** step, select **Windows Server 2012 R2** and click **Next**.
- On the **Computer Details** step, in the **Computer name** box, type **TT-GW02** and click **Next**.
- On the **Applications** step, do not select any applications, and click **Next**.

```PowerShell
cls
```

## # Rename local Administrator account and set password

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

$password = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted for the secure string, type the password for the Administrator account.

```PowerShell
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

$adminUser = [ADSI] 'WinNT://./Administrator,User'
$adminUser.Rename('foo')
$adminUser.SetPassword($plainPassword)

logoff
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Remove disk from virtual CD/DVD drive

```PowerShell
$vmHost = "TT-HV01A"
$vmName = "TT-GW02"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

### # Move computer to different OU

```PowerShell
$targetPath = ("OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath

Restart-VM -ComputerName $vmHost -VMName $vmName -Force
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
$vmName = "TT-GW02"

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
$vmName = "TT-GW02"

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
$vmName = "TT-GW02"

$scriptBlock = {
    net localgroup Administrators "TECHTOOLBOX\VMM Admins" /ADD
}

Invoke-Command -ComputerName $vmName -ScriptBlock $scriptBlock
```

---

# FAB-DC06 - Windows Server 2019

Monday, May 20, 2019\
11:14 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure infrastructure

---

**FOOBAR18** - Run as administrator

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05B"
$vmName = "FAB-DC06"
$vmPath = "E:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 2GB `
    -SwitchName "Embedded Team Switch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 2 `
    -DynamicMemory `
    -MemoryMinimumBytes 1GB `
    -MemoryMaximumBytes 4GB `
    -AutomaticCheckpointsEnabled $false

Add-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName

$vmDvdDrive = Get-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName

Set-VMFirmware `
    -ComputerName $vmHost `
    -VMName $vmName `
    -EnableSecureBoot Off `
    -FirstBootDevice $vmDvdDrive

Set-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path "\\TT-FS01\Products\Microsoft\Windows Server 2019\en_windows_server_2019_updated_march_2019_x64_dvd_2ae967ab.iso"

Set-VMDvdDrive : Failed to add device 'Virtual CD/DVD Disk'.
User Account does not have permission to open attachment.
'FAB-DC06' failed to add device 'Virtual CD/DVD Disk'. (Virtual machine ID E1B5BCB3-3493-41C3-90AA-92E75EF1FE52)
'FAB-DC06': User account does not have permission required to open attachment '\\TT-FS01\Products\Microsoft\Windows Server
2019\en_windows_server_2019_updated_march_2019_x64_dvd_2ae967ab.iso'. Error: 'General access denied error' (0x80070005). (Virtual
machine ID E1B5BCB3-3493-41C3-90AA-92E75EF1FE52)
At line:1 char:1
+ Set-VMDvdDrive `
+ ~~~~~~~~~~~~~~~~
    + CategoryInfo          : PermissionDenied: (:) [Set-VMDvdDrive], VirtualizationException
    + FullyQualifiedErrorId : AccessDenied,Microsoft.HyperV.PowerShell.Commands.SetVMDvdDrive

$iso = Get-SCISO |
    where {$_.Name -eq "en_windows_server_2019_updated_march_2019_x64_dvd_2ae967ab.iso"}

Get-SCVirtualMachine -Name $vmName | Read-SCVirtualMachine

Get-SCVirtualMachine -Name $vmName |
    Get-SCVirtualDVDDrive |
    Set-SCVirtualDVDDrive -ISO $iso -Link

#Start-VM -ComputerName $vmHost -Name $vmName
Start-SCVirtualMachine -VM $vmName
```

---

### Install Windows Server 2019

1. When prompted, select **Windows Server 2019 Standard (Desktop Experience)**.
2. Specify a password for the local Administrator account.

### # Rename local Administrator account

```PowerShell
$adminUser = [ADSI] 'WinNT://./Administrator,User'
$adminUser.Rename('foo')

logoff
```

---

**FOOBAR18** - Run as administrator

```PowerShell
cls
```

### # Move VM to Fabrikam VM network

```PowerShell
$vmName = "FAB-DC06"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Fabrikam VM Network"

Stop-SCVirtualMachine $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork

Start-SCVirtualMachine $vmName
```

---

### Login as .\\foo

```PowerShell
cls
```

### # Set time zone

```PowerShell
tzutil /s "Mountain Standard Time"
```

### # Rename computer and join domain

```PowerShell
$computerName = "FAB-DC06"

Rename-Computer -NewName $computerName -Restart
```

Wait for the VM to restart and then execute the following command to join the **FABRIKAM** domain:

```PowerShell
Add-Computer -DomainName corp.fabrikam.com -Restart
```

---

**FAB-DC03** - Run as domain administrator

```PowerShell
cls
```

### # Configure Windows Update

#### # Add machine to security group for Windows Update schedule

```PowerShell
Add-ADGroupMember -Identity "Windows Update - Slot 18" -Members "FAB-DC06$"
```

---

### # Copy Toolbox content

```PowerShell
net use \\TT-FS01.corp.technologytoolbox.com\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$source = "\\TT-FS01.corp.technologytoolbox.com\Public\Toolbox"
$destination = "C:\NotBackedUp\Public\Toolbox"

robocopy $source $destination /E /XD git-for-windows "Microsoft SDKs"
```

### # Set MaxPatchCacheSize to 0 (recommended)

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

### Configure storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 32 GB       | 4K                   | OSDisk       |
| 1    | D:           | 5 GB        | 4K                   | Data01       |

```PowerShell
cls
```

#### # Change drive letter for DVD-ROM

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
```

#### Configure separate VHD for Active Directory data

---

**FOOBAR16** - Run as administrator

```PowerShell
cls
```

##### # Add disk for Active Directory data

```PowerShell
$vmHost = "TT-HV05B"
$vmName = "FAB-DC06"

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 5GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path $vhdPath `
    -ControllerType SCSI
```

---

```PowerShell
cls
```

##### # Initialize disks and format volumes

```PowerShell
Get-Disk 1 |
    Initialize-Disk -PartitionStyle GPT -PassThru |
    New-Partition -UseMaximumSize -DriveLetter D |
    Format-Volume `
        -FileSystem NTFS `
        -NewFileSystemLabel "Data01" `
        -Confirm:$false
```

```PowerShell
cls
```

### # Configure networking

```PowerShell
$interfaceAlias = "Management"
```

#### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Start-Sleep -Seconds 5

ping TT-FS01 -f -l 8900
```

---

**FAB-DC04** - Run as domain administrator

```PowerShell
cls
```

#### # Remove old domain controller

##### # Demote domain controller

```PowerShell
Import-Module ADDSDeployment

Uninstall-ADDSDomainController `
    -DemoteOperationMasterRole:$true `
    -RemoveDnsDelegation:$true
```

> **Note**
>
> When prompted, specify the password for the local administrator account.

##### Remove Active Directory Domain Services and DNS roles

> **Note**
>
> Restart the computer to complete the removal of the roles.

##### # Stop server

```PowerShell
Stop-Computer
```

---

```PowerShell
cls
```

#### # Configure static IP addresses

```PowerShell
$interfaceAlias = "Management"
```

##### # Disable DHCP and router discovery

```PowerShell
Set-NetIPInterface `
    -InterfaceAlias $interfaceAlias `
    -Dhcp Disabled `
    -RouterDiscovery Disabled
```

##### # Configure static IPv4 address

```PowerShell
$ipAddress = "10.0.40.3"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24 `
    -DefaultGateway 10.0.40.1
```

##### # Configure IPv4 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 10.0.40.2
```

## Configure domain controller

### Login as FABRIKAM\\jjameson-admin

### # Install Active Directory Domain Services

```PowerShell
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools -Restart
```

> **Note**
>
> A restart was not needed after installing Active Directory Domain Services.

```PowerShell
cls
```

### # Promote server to domain controller

```PowerShell
Import-Module ADDSDeployment

Install-ADDSDomainController `
    -DatabasePath "D:\Windows\NTDS" `
    -DomainName "corp.fabrikam.com" `
    -LogPath "D:\Windows\NTDS" `
    -SysvolPath "D:\Windows\SYSVOL" `
    -Force:$true
```

> **Note**
>
> When prompted, specify the password for the administrator account when the computer is started in Safe Mode or a variant of Safe Mode, such as Directory Services Restore Mode.

### # Configure firewall for cross-forest trust (EXTRANET --> FABRIKAM)

```PowerShell
reg add HKLM\SYSTEM\CurrentControlSet\Services\NTDS\Parameters `
    /v "TCP/IP Port" /t REG_DWORD /d 58349

reg add HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters `
    /v DCTcpipPort /t REG_DWORD /d 51164
```

```PowerShell
Restart-Computer
```

---

**FOOBAR18** - Run as administrator

```PowerShell
cls
```

## # Make virtual machine highly available

### # Migrate VM to shared storage

```PowerShell
$vmName = "FAB-DC06"

$vm = Get-SCVirtualMachine -Name $vmName
$vmHost = $vm.VMHost

Move-SCVirtualMachine `
    -VM $vm `
    -VMHost $vmHost `
    -HighlyAvailable $true `
    -Path "C:\ClusterStorage\iscsi02-Silver-03" `
    -UseDiffDiskOptimization
```

```PowerShell
cls
```

### # Allow migration to host with different processor version

```PowerShell
Stop-SCVirtualMachine -VM $vmName

Set-SCVirtualMachine -VM $vmName -CPULimitForMigration $true

Start-SCVirtualMachine -VM $vmName
```

---

## Configure backups

### Add virtual machine to Hyper-V protection group in DPM

**TODO:**

```PowerShell
cls
```

## # Enter a product key and activate Windows

```PowerShell
slmgr /ipk {product key}
```

> **Note**
>
> When notified that the product key was set successfully, click **OK**.

```Console
slmgr /ato
```

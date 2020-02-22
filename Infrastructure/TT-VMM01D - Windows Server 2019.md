# TT-VMM01D - Windows Server 2019

Wednesday, November 27, 2019
8:41 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure infrastructure

---

**TT-ADMIN02 - Run as administrator**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05B"
$vmName = "TT-VMM01D"
$vmPath = "E:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 35GB `
    -MemoryStartupBytes 4GB `
    -SwitchName "Embedded Team Switch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 2 `
    -AutomaticCheckpointsEnabled $false

Set-VMNetworkAdapterVlan `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Access `
    -VlanId 30

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Install custom Windows Server 2019 image

- On the **Task Sequence** step, select **Windows Server 2019** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **TT-VMM01D**.
  - Click **Next**.
- On the **Applications** step, ensure no items are selected and click **Next**.

```PowerShell
cls
```

### # Rename local Administrator account and set password

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

$password = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted, type the password for the local Administrator account.

```PowerShell
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

$adminUser = [ADSI] 'WinNT://./Administrator,User'
$adminUser.Rename('foo')
$adminUser.SetPassword($plainPassword)

logoff
```

### Configure networking

#### Configure static IP address

---

**TT-ADMIN02 - Run as administrator**

```PowerShell
cls
```

##### # Configure static IP address using VMM

```PowerShell
$vmName = "TT-VMM01D"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Management VM Network"
$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"
$ipPool = Get-SCStaticIPAddressPool -Name "Management-30 Address Pool"

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

**TODO:**

### Login as local administrator account

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

### Configure storage

| **Disk** | **Drive Letter** | **Volume Size** | **Allocation Unit Size** | **Volume Label** |
| -------- | ---------------- | --------------- | ------------------------ | ---------------- |
| 0        | C:               | 35 GB           | 4K                       | OSDisk           |

```PowerShell
cls
```

### # Enable performance counters for Server Manager

```PowerShell
$taskName = "\Microsoft\Windows\PLA\Server Manager Performance Monitor"

Enable-ScheduledTask -TaskName $taskName

logman start "Server Manager Performance Monitor"
```

### # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

> **Note**
>
> PowerShell remoting must be enabled for remote Windows Update using PoshPAIG ([https://github.com/proxb/PoshPAIG](https://github.com/proxb/PoshPAIG)).

---

**TT-ADMIN02 - Run as administrator**

```PowerShell
cls
$vmName = "TT-VMM01D"
```

### # Set first boot device to hard drive

```PowerShell
$vmHost = "TT-HV05B"

$vmHardDiskDrive = Get-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName |
    where { $_.ControllerType -eq "SCSI" `
        -and $_.ControllerNumber -eq 0 `
        -and $_.ControllerLocation -eq 0 }

Set-VMFirmware `
    -ComputerName $vmHost `
    -VMName $vmName `
    -FirstBootDevice $vmHardDiskDrive
```

### # Move computer to different OU

```PowerShell
$targetPath = ("OU=System Center Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

### # Configure Windows Update

#### # Add machine to security group for Windows Update configuration

```PowerShell
Add-ADGroupMember -Identity "Windows Update - Slot 2" -Members ($vmName + '$')
```

---

### Add virtual machine to Hyper-V protection group in DPM

## Prepare server for VMM installation

### Enable setup account for System Center

```PowerShell
cls
```

### # Add VMM service account to local Administrators group

```PowerShell
$localGroup = "Administrators"
$domain = "TECHTOOLBOX"
$serviceAccount = "s-vmm01"

([ADSI]"WinNT://./$localGroup,group").Add(
    "WinNT://$domain/$serviceAccount,user")
```

### # Add VMM administrators domain group to local Administrators group

```PowerShell
$domain = "TECHTOOLBOX"
$domainGroup = "VMM Admins"

([ADSI]"WinNT://./Administrators,group").Add(
    "WinNT://$domain/$domainGroup,group")
```

### Configure failover clustering

---

**TT-ADMIN02 - Run as administrator**

```PowerShell
cls
```

#### # Add a second network adapter for cluster network

```PowerShell
$vmName = "TT-VMM01D"
$vmNetwork = Get-SCVMNetwork -Name "Cluster VM Network"
$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"
$ipAddressPool = Get-SCStaticIPAddressPool -Name "Cluster Address Pool"
$portClassification = Get-SCPortClassification -Name "Host Cluster Workload"

$vm = Get-SCVirtualMachine $vmName

Stop-SCVirtualMachine $vmName

$networkAdapter = New-SCVirtualNetworkAdapter `
    -VM $vm `
    -VMNetwork $vmNetwork `
    -Synthetic `
    -PortClassification $portClassification

$macAddress = Grant-SCMACAddress `
    -MACAddressPool $macAddressPool `
    -Description $vm.Name `
    -VirtualNetworkAdapter $networkAdapter

$ipAddress = Grant-SCIPAddress `
    -GrantToObjectType VirtualNetworkAdapter `
    -GrantToObjectID $networkAdapter.ID `
    -StaticIPAddressPool $ipAddressPool `
    -Description $vm.Name

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -MACAddressType Static `
    -MACAddress $macAddress `
    -IPv4AddressType Static `
    -IPv4Address $ipAddress

Start-SCVirtualMachine $vmName
```

---

```PowerShell
cls
```

#### # Configure cluster network settings

```PowerShell
$interfaceAlias = "Cluster"
```

##### # Rename cluster network adapter

```PowerShell
Get-NetAdapter `
    -InterfaceDescription "Microsoft Hyper-V Network Adapter #2" |
    Rename-NetAdapter -NewName $interfaceAlias
```

#### # Install Failover Clustering feature on second node

```PowerShell
Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools -Restart
```

> **Important**
>
> After the computer restarts, sign in using the domain setup account for System Center (**TECHTOOLBOX\\setup-systemcenter**).

#### # Join cluster

```PowerShell
Get-Cluster -Name TT-VMM01-FC | Add-ClusterNode -Name TT-VMM01C, TT-VMM01D -NoStorage
```

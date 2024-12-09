# TT-VMM01C - Windows Server 2019

Wednesday, November 27, 2019\
8:37 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure infrastructure

---

**TT-ADMIN02** - Run as administrator

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "TT-VMM01C"
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
  - In the **Computer name** box, type **TT-VMM01C**.
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

**TT-ADMIN02** - Run as administrator

```PowerShell
cls
```

##### # Configure static IP address using VMM

```PowerShell
$vmName = "TT-VMM01C"
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
| --- | --- | --- | --- | --- |
| 0 | C: | 35 GB | 4K | OSDisk |

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

**TT-ADMIN02** - Run as administrator

```PowerShell
cls
$vmName = "TT-VMM01C"
```

### # Set first boot device to hard drive

```PowerShell
$vmHost = "TT-HV05A"

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
Add-ADGroupMember -Identity "Windows Update - Slot 5" -Members ($vmName + '$')
```

---

### Add virtual machine to Hyper-V protection group in DPM

## Prepare server for VMM installation

---

**TT-ADMIN02** - Run as administrator

```PowerShell
cls
```

### # Enable setup account for System Center

```PowerShell
Enable-ADAccount -Identity setup-systemcenter
```

---

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

**TT-ADMIN02** - Run as administrator

```PowerShell
cls
```

#### # Add a second network adapter for cluster network

```PowerShell
$vmName = "TT-VMM01C"
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

```PowerShell
cls
```

### # Install Microsoft Assessment and Deployment Kit for Windows 10

#### # Install ADK

```PowerShell
& "\\TT-FS01\Products\Microsoft\Windows Assessment and Deployment Kit\Windows ADK for Windows 10, version 1903\adksetup.exe"
```

On the **Select the features you want to install** step, clear all checkboxes except **Deployment Tools** and then click **Install**.

```PowerShell
cls
```

#### # Install Windows PE Add-ons for ADK

```PowerShell
& "\\TT-FS01\Products\Microsoft\Windows Assessment and Deployment Kit\Windows PE Add-ons for ADK\adkwinpesetup.exe"

Restart-Computer
```

### Remove VMM database from SQL Server availability group

---

**SQL Server Management Studio** - Database Engine - **TT-SQL01**

#### -- Temporarily add VMM installation account to sysadmin role in SQL Server

```SQL
USE [master]
GO
ALTER SERVER ROLE [sysadmin]
ADD MEMBER [TECHTOOLBOX\setup-systemcenter]
GO
```

---

## Install Virtual Machine Manager

### Login as TECHTOOLBOX\\setup-systemcenter

```PowerShell
cls
```

### # Extract VMM setup files

```PowerShell
$imagePath = "\\TT-FS01\Products\Microsoft\System Center 2019" `
    + "\mu_system_center_virtual_machine_manager_2019_x64_dvd_06c18108.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$installer = $imageDriveLetter + ":\SCVMM_2019.exe"

& $installer
```

Destination location: **C:\\NotBackedUp\\Temp\\System Center 2019 Virtual Machine Manager**

```PowerShell
Dismount-DiskImage -ImagePath $imagePath
```

### # Install VMM features

```PowerShell
$installer = "C:\NotBackedUp\Temp\System Center 2019 Virtual Machine Manager\Setup.exe"

& $installer
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/49/8980EE550F999BA601ED161BD50D80AB17A1F149.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/17/F2C93ECC5B6E78397806774C97CEA0C507075217.png)

Select **VMM management server**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/38/A81D34253F981ACA23D73EAEA7B14C97D6AB7E38.png)

Click **Yes**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E2/31FB44CCCAB708DDDB01796586AFA9EA679FB7E2.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3F/A6405A6CC28A7AF0C645C889A5CE25DDE857653F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F7/5770101827A2DF142BEAE80BFE8BD39BB70107F7.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F0/1D293461DB0CB4DD97C94A76C35DC530CA5720F0.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/89/B0A2BAC7B947DCDDC3930DF33813AD2E114D4589.png)

Select **On (recommended)** and then click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1E/17BC0DFE309C354D56D6173B7190807C331A5E1E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/84/B4F0F55A92B3F1CC8AAAC2968E1B611B3E116684.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F8/A6B2F5C7834764A06A7C72EF5FA8DA9FAEA409F8.png)

Click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/76/0E83B9261334D0F8A7844969D0FF65F9B738A976.png)

Click **Yes**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A0/14B7E89B6941504B085A58E005DF5D0EA8A118A0.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1E/D54C91E22022CFD3E01BD0FECE4E366F868B641E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/53/ABDB42DCD38BB178365646890EB6A45904A37F53.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2C/9DD2BDEB4EB56F65D3B9E9CADA2B48089672D92C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9A/A022F4B39CFE4D259668FEC02E96878D7C240C9A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0E/E32DCDD78EDA6828F7DABC82F50CD8A584859E0E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7A/AFCF65D058EA2E8B7B78936087D0D46DB0600B7A.png)

Unable to create or access the Active Directory container 'CN=VMM Distributed Key Management,CN=System,DC=corp,DC=technologytoolbox,DC=com'. Access is denied.\
Specify the distinguished name for the container and verify that you have GenericRead|CreateChild|WriteProperty rights on the container.

> **Note**
>
> The error is due the owner of the container being set to **TECHTOOLBOX\\setup-vmm** (i.e. the setup account used to install VMM 2016). Apparently granting Full Control to the new setup account (**TECHTOOLBOX\\setup-systemcenter**) was not sufficient for installing VMM 2019.

Using ADSI Edit, change the owner on the following container to **TECHTOOLBOX\\setup-systemcenter**:

> **CN=DKM_SCVMM_TT-VMM01A_f4021c4c-ab8a-4c0a-a4a6-ec4cad2ad440,**\
> **CN=VMM Distributed Key Management,CN=System,DC=corp,DC=technologytoolbox,DC=com**

Run the setup process again.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C2/A52646A1176FD3844650763209F3B5AF2EADCAC2.png)

```PowerShell
cls
```

### # Copy VMM setup files to file server (to subsequently install VMM console)

```PowerShell
$source = "C:\NotBackedUp\Temp\System Center 2019 Virtual Machine Manager"
$destination =  "\\TT-FS01\Products\Microsoft\System Center 2019\VMM"

robocopy $source $destination /E
```

```PowerShell
cls
```

### # Remove temporary VMM setup files

```PowerShell
Remove-Item "C:\NotBackedUp\Temp\System Center 2019 Virtual Machine Manager" -Recurse
```

### Install VMM on secondary cluster node

---

**SQL Server Management Studio** - Database Engine - **TT-SQL01**

### -- Remove SCOM installation account from sysadmin role in SQL Server

```SQL
USE [master]
GO
ALTER SERVER ROLE [sysadmin]
DROP MEMBER [TECHTOOLBOX\setup-systemcenter]
GO
```

---

### Failover to VMM 2019 cluster node

### Uninstall VMM 2016 on old cluster nodes

```PowerShell
cls
```

### # Remove VMM 2016 nodes from cluster

```PowerShell
Remove-ClusterNode -Cluster TT-VMM01 -Name TT-VMM01A, TT-VMM01B
```

```PowerShell
cls
```

### # Upgrade cluster functional level

```PowerShell
Get-Cluster | select ClusterFunctionalLevel

ClusterFunctionalLevel
----------------------
                     9


Update-ClusterFunctionalLevel

Updating the functional level for cluster TT-VMM01-FC.
Warning: You cannot undo this operation. Do you want to continue?
[Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "Y"):

Name
----
TT-VMM01-FC


Get-Cluster | select ClusterFunctionalLevel

ClusterFunctionalLevel
----------------------
                    10
```

```PowerShell
cls
```

### # Enter product key for System Center Virtual Machine Manager

#### # Set product key

```PowerShell
Register-SCVMMAccessLicense `
    -VMMServer tt-vmm01 `
    -AcceptEULA `
    -ProductKey {product key}
```

### Update VMM agent on Hyper-V hosts

---

**TT-ADMIN02** - Run as domain administrator

```PowerShell
cls
```

### # Disable setup account for System Center

```PowerShell
Disable-ADAccount -Identity setup-systemcenter
```

---

```PowerShell
cls
```

## # Configure monitoring using System Center Operations Manager

### # Install SCOM agent

```PowerShell
$msiPath = "\\TT-FS01\Products\Microsoft\System Center 2019\SCOM\Agents\AMD64" `
    + "\MOMAgent.msi"

msiexec.exe /i $msiPath `
    MANAGEMENT_GROUP=HQ `
    MANAGEMENT_SERVER_DNS=TT-SCOM01C `
    ACTIONS_USE_COMPUTER_ACCOUNT=1
```

### Approve manual agent install in Operations Manager

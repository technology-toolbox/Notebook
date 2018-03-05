# TT-HV02D - Windows Server 2016

Sunday, March 4, 2018
4:09 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

### Install Windows Server 2016 Datacenter Edition ("Server Core")

### Login as local administrator account

### Install latest patches

#### # Install latest patches using Windows Update

```PowerShell
sconfig
```

### Rename computer and join domain

```Console
sconfig
```

> **Note**
>
> Rename the computer to **TT-HV02D** and join the **corp.technologytoolbox.com** domain.

---

**FOOBAR11**

```PowerShell
cls
```

### # Move computer to "Hyper-V Servers" OU

```PowerShell
$computerName = "TT-HV02D"
$targetPath = ("OU=Hyper-V Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com")
```

### # Add computer to "Hyper-V Servers" domain group

```PowerShell
Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath

Import-Module ActiveDirectory
Add-ADGroupMember -Identity "Hyper-V Servers" -Members TT-HV02D$
```

### # Add fabric administrators domain group to local Administrators group on Hyper-V server

```PowerShell
$scriptBlock = {
    net localgroup Administrators "TECHTOOLBOX\Fabric Admins" /ADD
}

Invoke-Command -ComputerName $computerName -ScriptBlock $scriptBlock
```

---

### Login as fabric administrator account

```Console
PowerShell
```

```Console
cls
```

### # Set time zone

```PowerShell
tzutil /s "Mountain Standard Time"
```

### # Copy Toolbox content

```PowerShell
$source = "\\TT-FS01\Public\Toolbox"
$destination = "C:\NotBackedUp\Public\Toolbox"

robocopy $source $destination  /E /XD "Microsoft SDKs"
```

### # Set MaxPatchCacheSize to 0 (recommended)

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

## Prepare infrastructure for Hyper-V and Storage Spaces Direct

### Enable Virtualization in BIOS

Intel Virtualization Technology: **Enabled**

```PowerShell
cls
```

### # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

### # Add roles for Hyper-V cluster

```PowerShell
Install-WindowsFeature `
    -Name Failover-Clustering, File-Services, Hyper-V `
    -IncludeManagementTools `
    -Restart
```

### Login as fabric administrator account

```Console
PowerShell
```

```Console
cls
```

### # Install latest patches using Windows Update

```PowerShell
sconfig
```

> **Important**
>
> Restart the server to complete the patching.

```PowerShell
cls
```

### # Add server to Hyper-V cluster

```PowerShell
Get-Cluster -Name TT-HV02-FC | Add-ClusterNode -Name TT-HV02D
```

### Import Hyper-V host into VMM

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Add VMM administrators domain group and VMM management service account to Administrators group on Hyper-V servers

```PowerShell
$command = "
net localgroup Administrators 'TECHTOOLBOX\VMM Admins' /ADD

net localgroup Administrators TECHTOOLBOX\s-vmm01-mgmt /ADD
"

$scriptBlock = [ScriptBlock]::Create($command)

@("TT-HV02D") |
    ForEach-Object {
        Invoke-Command -ComputerName $_ -ScriptBlock $scriptBlock
    }
```

```PowerShell
cls
```

### # Configure networking

```PowerShell
$vmHost = Get-SCVMHost -ComputerName TT-HV02D

$networkAdapter = Get-SCVMHostNetworkAdapter `
    -VMHost $vmHost `
    -Name "Realtek PCIe GBE Family Controller"

$uplinkPortProfileSet = Get-SCUplinkPortProfileSet -Name "Trunk Uplink"

Set-SCVMHostNetworkAdapter `
    -VMHostNetworkAdapter $networkAdapter `
    -UplinkPortProfileSet $uplinkPortProfileSet

$logicalSwitch = Get-SCLogicalSwitch -Name "Embedded Team Switch"

New-SCVirtualNetwork `
    -VMHost $vmHost `
    -VMHostNetworkAdapters @($networkAdapter) `
    -LogicalSwitch $logicalSwitch `
    -DeployVirtualNetworkAdapters

Get-SCVirtualNetworkAdapter -VMHost $vmHost |
    where { $_.Name -in @('Storage 1', 'Storage 2') } |
    Remove-SCVirtualNetworkAdapter
```

#### # Configure "Storage 1" logical switch

```PowerShell
$networkAdapter = Get-SCVMHostNetworkAdapter `
    -VMHost $vmHost `
    -Name "Intel(R) Gigabit CT Desktop Adapter"

$uplinkPortProfileSet = Get-SCUplinkPortProfileSet `
    -Name "Storage Uplink - Storage 1"


Set-SCVMHostNetworkAdapter `
    -VMHostNetworkAdapter $networkAdapter `
    -UplinkPortProfileSet $uplinkPortProfileSet

$logicalSwitch = Get-SCLogicalSwitch -Name "Storage 1"

New-SCVirtualNetwork `
    -VMHost $vmHost `
    -VMHostNetworkAdapters @($networkAdapter) `
    -LogicalSwitch $logicalSwitch `
    -DeployVirtualNetworkAdapters
```

#### # Configure "Storage 2" logical switch

```PowerShell
$networkAdapter = Get-SCVMHostNetworkAdapter `
    -VMHost $vmHost `
    -Name "Intel(R) Gigabit CT Desktop Adapter #2"

$uplinkPortProfileSet = Get-SCUplinkPortProfileSet `
    -Name "Storage Uplink - Storage 2"


Set-SCVMHostNetworkAdapter `
    -VMHostNetworkAdapter $networkAdapter `
    -UplinkPortProfileSet $uplinkPortProfileSet

$logicalSwitch = Get-SCLogicalSwitch -Name "Storage 2"

New-SCVirtualNetwork `
    -VMHost $vmHost `
    -VMHostNetworkAdapters @($networkAdapter) `
    -LogicalSwitch $logicalSwitch `
    -DeployVirtualNetworkAdapters
```

---

```PowerShell
cls
```

#### # Fix network adapter name

```PowerShell
Get-NetAdapter "vEthernet (Embedded Team Switch)" |
    Rename-NetAdapter -NewName "vEthernet (Management)"
```

```PowerShell
cls
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name "Ethernet" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Set-NetAdapterAdvancedProperty -Name "Ethernet 2" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Set-NetAdapterAdvancedProperty -Name "Ethernet 3" `
    -DisplayName "Jumbo Frame" -RegistryValue 9216

Set-NetAdapterAdvancedProperty -Name "vEthernet (Management)" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Set-NetAdapterAdvancedProperty -Name "vEthernet (Live Migration)" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Set-NetAdapterAdvancedProperty -Name "vEthernet (Cluster)" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Set-NetAdapterAdvancedProperty -Name "vEthernet (Storage 1)" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Set-NetAdapterAdvancedProperty -Name "vEthernet (Storage 2)" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

ping TT-FS01 -f -l 8900

ping 10.1.10.80 -f -l 8900
```

```PowerShell
cls
```

### # Configure storage

#### # Run all cluster validation tests

```PowerShell
Test-Cluster `
    -Node TT-HV02D `
    -Include "Storage Spaces Direct", "Inventory", "Network", "System Configuration"
```

> **Note**
>
> Wait for the cluster validation tests to complete.

### # Review cluster validation report

```PowerShell
$source = "$env:TEMP\Validation Report 2018.03.04 At 18.13.19.htm"
$destination = "\\TT-FS01\Public"

Copy-Item $source $destination
```

---

**WOLVERINE**

```PowerShell
cls
& "\\TT-FS01\Public\Validation Report 2018.03.04 At 18.13.19.htm"
```

---

#### # Enable Storage Spaces Direct

```PowerShell
Enable-ClusterStorageSpacesDirect -AutoConfig $false -SkipEligibilityChecks

WARNING: 2018/02/28-13:08:12.860 Node TT-SOFS02A: No disks found to be used for cache
WARNING: 2018/02/28-13:08:12.876 C:\Windows\Cluster\Reports\Enable-ClusterS2D on 2018.02.28-13.08.12.860.htm
```

```PowerShell
cls
```

#### # Check media type configuration

```PowerShell
Get-StoragePool "S2D on TT-SOFS02-FC" |
    Get-PhysicalDisk |
    Sort Size |
    ft FriendlyName, Size, MediaType, HealthStatus, OperationalStatus -AutoSize
```

```PowerShell
cls
```

#### # Change fault domain awareness (required for single node cluster)

```PowerShell
Set-StoragePool `
```

    -FriendlyName "S2D on TT-SOFS02-FC" `\
    -FaultDomainAwarenessDefault PhysicalDisk

**Deploying Storage Spaces Direct on a Single Node SOFS Cluster**\
From <[https://www.danielstechblog.info/deploying-storage-spaces-direct-on-a-single-node-sofs-cluster/](https://www.danielstechblog.info/deploying-storage-spaces-direct-on-a-single-node-sofs-cluster/)>

```PowerShell
cls
```

#### # Create cluster shared volume

```PowerShell
New-Volume `
```

    -FriendlyName "Volume1" `\
    -FileSystem CSVFS_ReFS `\
    -StoragePoolFriendlyName S2D* `\
    -UseMaximumSize `\
    -ResiliencySettingName Parity

#### Update AHCI drivers

1. Download the latest AHCI drivers from the Intel website:\
   **Intel® RSTe AHCI & SCU Software RAID driver for Windows**\
   From <[https://downloadcenter.intel.com/download/25393/Intel-RSTe-AHCI-SCU-Software-RAID-driver-for-Windows-](https://downloadcenter.intel.com/download/25393/Intel-RSTe-AHCI-SCU-Software-RAID-driver-for-Windows-)>
2. Extract the drivers (**[\\\\ICEMAN\\Public\\Download\\Drivers\\Intel\\RSTe](\\ICEMAN\Public\Download\Drivers\Intel\RSTe) AHCI & SCU Software RAID driver for Windows**) and copy the files to a temporary location on the server:
3. Install the drivers for the **Intel(R) C600+/C220+ series chipset SATA AHCI Controller (PCI\\VEN_8086&DEV_8D02&...)**:
4. Install the drivers for the **Intel(R) C600+/C220+ series chipset sSATA AHCI Controller (PCI\\VEN_8086&DEV_8D62&...)**:
5. Restart the server.

```Console
    robocopy "\\ICEMAN\Public\Download\Drivers\Intel\RSTe AHCI & SCU Software RAID driver for Windows\Drivers\x64\Win8_10_2K8R2_2K12\AHCI" '\\TT-HV02C\C$\NotBackedUp\Temp\Drivers\Intel\x64\Win8_10_2K8R2_2K12\AHCI' /E
```

```Console
    pnputil -i -a C:\NotBackedUp\Temp\Drivers\Intel\x64\Win8_10_2K8R2_2K12\AHCI\iaAHCI.inf
```

```Console
    pnputil -i -a C:\NotBackedUp\Temp\Drivers\Intel\x64\Win8_10_2K8R2_2K12\AHCI\iaAHCIB.inf
```

#### Physical disks

<table>
<tr>
<td valign='top'>
<p>Disk</p>
</td>
<td valign='top'>
<p>Description</p>
</td>
<td valign='top'>
<p>Capacity</p>
</td>
<td valign='top'>
<p>Drive Letter</p>
</td>
<td valign='top'>
<p>Volume Size</p>
</td>
<td valign='top'>
<p>Allocation Unit Size</p>
</td>
<td valign='top'>
<p>Volume Label</p>
</td>
</tr>
<tr>
<td valign='top'>
<p>0</p>
</td>
<td valign='top'>
<p>Model: Samsung SSD 850 PRO 128GB<br />
Serial number: *********03848M</p>
</td>
<td valign='top'>
<p>128 GB</p>
</td>
<td valign='top'>
<p>C:</p>
</td>
<td valign='top'>
<p>119 GB</p>
</td>
<td valign='top'>
<p>4K</p>
</td>
<td valign='top'>
</td>
</tr>
<tr>
<td valign='top'>
<p>1</p>
</td>
<td valign='top'>
<p>Model: Samsung SSD 850 PRO 512GB<br />
Serial number: *********01139V</p>
</td>
<td valign='top'>
<p>512 GB</p>
</td>
<td valign='top'>
</td>
<td valign='top'>
</td>
<td valign='top'>
</td>
<td valign='top'>
</td>
</tr>
<tr>
<td valign='top'>
<p>2</p>
</td>
<td valign='top'>
<p>Model: Samsung SSD 850 PRO 512GB<br />
Serial number: *********01138P</p>
</td>
<td valign='top'>
<p>512 GB</p>
</td>
<td valign='top'>
</td>
<td valign='top'>
</td>
<td valign='top'>
</td>
<td valign='top'>
</td>
</tr>
<tr>
<td valign='top'>
<p>3</p>
</td>
<td valign='top'>
<p>Model: ST4000NM0033-9ZM170<br />
Serial number: *****58G</p>
</td>
<td valign='top'>
<p>4 TB</p>
</td>
<td valign='top'>
</td>
<td valign='top'>
</td>
<td valign='top'>
</td>
<td valign='top'>
</td>
</tr>
<tr>
<td valign='top'>
<p>4</p>
</td>
<td valign='top'>
<p>Model: ST4000NM0033-9ZM170<br />
Serial number: *****42W</p>
</td>
<td valign='top'>
<p>4 TB</p>
</td>
<td valign='top'>
</td>
<td valign='top'>
</td>
<td valign='top'>
</td>
<td valign='top'>
</td>
</tr>
<tr>
<td valign='top'>
<p>5</p>
</td>
<td valign='top'>
<p>Model: WDC WD1001FALS-00Y6A0<br />
Serial number: WD-******234344</p>
</td>
<td valign='top'>
<p>1 TB</p>
</td>
<td valign='top'>
</td>
<td valign='top'>
</td>
<td valign='top'>
</td>
<td valign='top'>
</td>
</tr>
<tr>
<td valign='top'>
<p>6</p>
</td>
<td valign='top'>
<p>Model: WDC WD1002FAEX-00Y9A0<br />
Serial number: WD-******786376</p>
</td>
<td valign='top'>
<p>1 TB</p>
</td>
<td valign='top'>
</td>
<td valign='top'>
</td>
<td valign='top'>
</td>
<td valign='top'>
</td>
</tr>
<tr>
<td valign='top'>
<p>7</p>
</td>
<td valign='top'>
<p>Model: ST4000NM0033-9ZM170<br />
Serial number: *****EHB</p>
</td>
<td valign='top'>
<p>4 TB</p>
</td>
<td valign='top'>
</td>
<td valign='top'>
</td>
<td valign='top'>
</td>
<td valign='top'>
</td>
</tr>
<tr>
<td valign='top'>
<p>8</p>
</td>
<td valign='top'>
<p>Model: ST4000NM0033-9ZM170<br />
Serial number: *****5AY</p>
</td>
<td valign='top'>
<p>4 TB</p>
</td>
<td valign='top'>
</td>
<td valign='top'>
</td>
<td valign='top'>
</td>
<td valign='top'>
</td>
</tr>
</table>

```PowerShell
Get-PhysicalDisk | sort DeviceId

Get-PhysicalDisk | select DeviceId, Model, SerialNumber, CanPool | sort DeviceId
```

#### Storage pools

<table>
<tr>
<td valign='top'>
<p>Name</p>
</td>
<td valign='top'>
<p>Physical disks</p>
</td>
</tr>
<tr>
<td valign='top'>
<p>Pool 1</p>
</td>
<td valign='top'>
<p>PhysicalDisk1<br />
PhysicalDisk2<br />
PhysicalDisk3<br />
PhysicalDisk4</p>
</td>
</tr>
</table>

#### Virtual disks

| Name   | Layout | Provisioning | Capacity | SSD Tier | HDD Tier | Volume | Volume Label | Write-Back Cache |
| ------ | ------ | ------------ | -------- | -------- | -------- | ------ | ------------ | ---------------- |
| Data01 | Mirror | Fixed        | 200 GB   | 200 GB   |          | D:     | Data01       |                  |
| Data02 | Mirror | Fixed        | 2200 GB  | 200 GB   | 2000 GB  | E:     | Data02       | 5 GB             |
| Data03 | Mirror | Fixed        | 1500 GB  |          | 1500 GB  | F:     | Data03       | 5 GB             |

#### Login as fabric administrator account

```Console
PowerShell
```

```Console
cls
```

#### # Create storage pool

```PowerShell
$storageSubSystemName = "Windows Storage on $env:COMPUTERNAME"

$storageSubSystemUniqueId = `
    Get-StorageSubSystem -FriendlyName $storageSubSystemName |
    select -ExpandProperty UniqueId

$physicalDisks = @(
    (Get-PhysicalDisk -SerialNumber *********01139V),
    (Get-PhysicalDisk -SerialNumber *********01138P),
    (Get-PhysicalDisk -SerialNumber *****58G),
    (Get-PhysicalDisk -SerialNumber *****42W))

New-StoragePool `
    -FriendlyName "Pool 1" `
    -StorageSubSystemUniqueId $storageSubSystemUniqueId `
    -PhysicalDisks $physicalDisks
```

#### # Check media type configuration

```PowerShell
Get-StoragePool "Pool 1" |
    Get-PhysicalDisk |
    Sort Size |
    ft FriendlyName, Size, MediaType, HealthStatus, OperationalStatus -AutoSize
```

> **Important**
>
> Ensure the **MediaType** property for the SSDs is set to **SSD**.

```PowerShell
cls
```

#### # Create storage tiers

```PowerShell
Get-StoragePool "Pool 1" |
    New-StorageTier -FriendlyName "SSD Tier" -MediaType SSD

Get-StoragePool "Pool 1" |
    New-StorageTier -FriendlyName "HDD Tier" -MediaType HDD
```

#### # Create storage spaces

```PowerShell
$ssdTier = Get-StorageTier -FriendlyName "SSD Tier"

Get-StoragePool "Pool 1" |
    New-VirtualDisk `
        -FriendlyName "Data01" `
        -ResiliencySettingName Mirror `
        -StorageTiers $ssdTier `
        -StorageTierSizes 200GB

$hddTier = Get-StorageTier -FriendlyName "HDD Tier"

Get-StoragePool "Pool 1" |
    New-VirtualDisk `
        -FriendlyName "Data02" `
        -ResiliencySettingName Mirror `
        -StorageTiers $ssdTier,$hddTier `
        -StorageTierSizes 200GB,2000GB `
        -WriteCacheSize 5GB

Get-StoragePool "Pool 1" |
    New-VirtualDisk `
        -FriendlyName "Data03" `
        -ResiliencySettingName Mirror `
        -StorageTiers $hddTier `
        -StorageTierSizes 1500GB `
        -WriteCacheSize 5GB
```

```PowerShell
cls
```

#### # Create partitions and volumes

##### # Create volume "D" on Data01

```PowerShell
Get-VirtualDisk "Data01" | Get-Disk | Set-Disk -IsReadOnly 0

Get-VirtualDisk "Data01"| Get-Disk | Set-Disk -IsOffline 0

Get-VirtualDisk "Data01"| Get-Disk | Initialize-Disk -PartitionStyle GPT

Get-VirtualDisk "Data01"| Get-Disk |
    New-Partition -DriveLetter "D" -UseMaximumSize

Initialize-Volume `
    -DriveLetter "D" `
    -FileSystem ReFS `
    -NewFileSystemLabel "Data01" `
    -Confirm:$false
```

##### # Create volume "E" on Data02

```PowerShell
Get-VirtualDisk "Data02" | Get-Disk | Set-Disk -IsReadOnly 0

Get-VirtualDisk "Data02"| Get-Disk | Set-Disk -IsOffline 0

Get-VirtualDisk "Data02"| Get-Disk | Initialize-Disk -PartitionStyle GPT

Get-VirtualDisk "Data02"| Get-Disk |
    New-Partition -DriveLetter "E" -UseMaximumSize

Initialize-Volume `
    -DriveLetter "E" `
    -FileSystem ReFS `
    -NewFileSystemLabel "Data02" `
    -Confirm:$false
```

##### # Create volume "F" on Data03

```PowerShell
Get-VirtualDisk "Data03" | Get-Disk | Set-Disk -IsReadOnly 0

Get-VirtualDisk "Data03"| Get-Disk | Set-Disk -IsOffline 0

Get-VirtualDisk "Data03"| Get-Disk | Initialize-Disk -PartitionStyle GPT

Get-VirtualDisk "Data03"| Get-Disk |
    New-Partition -DriveLetter "F" -UseMaximumSize

Initialize-Volume `
    -DriveLetter "F" `
    -FileSystem ReFS `
    -NewFileSystemLabel "Data03" `
    -Confirm:$false
```

```PowerShell
cls
```

#### # Configure "Storage Tiers Optimization" scheduled task to append to log file

```PowerShell
If ((Test-Path C:\NotBackedUp\Temp) -eq $false)
{
    New-Item -ItemType Directory -Path C:\NotBackedUp\Temp
}

$logFile = "C:\NotBackedUp\Temp\Storage-Tiers-Optimization.log"

$taskPath = "\Microsoft\Windows\Storage Tiers Management\"
$taskName = "Storage Tiers Optimization"

$task = Get-ScheduledTask -TaskPath $taskPath -TaskName $taskName

$task.Actions[0].Execute = "%windir%\system32\cmd.exe"

$task.Actions[0].Arguments = `
    "/C `"%windir%\system32\defrag.exe -c -h -g -# >> $logFile`""

Set-ScheduledTask $task

Enable-ScheduledTask $task
```

> **Important**
>
> Simply appending ">> {log file}" (as described in the "To change the Storage Tiers Optimization task to save a report (Task Scheduler)" section of the [TechNet article](TechNet article)) did not work. Specifically, when running the task, the log file was not created and the task immediately finished without reporting any error.\
> Changing the **Program/script** (i.e. the action's **Execute** property) to launch "%windir%\\system32\\defrag.exe" using "%windir%\\system32\\cmd.exe" resolved the issue.

##### Reference

**Save a report when Storage Tiers Optimization runs**\
From <[https://technet.microsoft.com/en-us/library/dn789160.aspx](https://technet.microsoft.com/en-us/library/dn789160.aspx)>

```PowerShell
cls
```

#### # Benchmark storage performance

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\ATTO Disk Benchmark\Bench32.exe'
```

##### C: (SSD - Samsung 850 Pro 128GB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B3/7CFB0E7273A428A17204FB056012A4935CE1C0B3.png)

##### D: (Mirror SSD storage space - 2x Samsung 850 Pro 512GB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D9/D30106A95D0686B2103C5385E32D030D9B82EDD9.png)

##### E: (Mirror SSD/HDD storage space)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1A/88CD744E0DF7B168A403FA5A8D9C4B362D061E1A.png)

##### F: (Mirror HDD storage space)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B4/C72C0942D26AD3EDE3C46E9F3C4F598828B04AB4.png)

#### Login as fabric administrator account

```Console
PowerShell
```

```Console
cls
```

#### # Delete C:\\Windows\\SoftwareDistribution folder

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse

Start-Service wuauserv
```

```PowerShell
cls
```

## # Deploy Hyper-V

### # Configure Hyper-V virtual switch

#### # Create Hyper-V virtual switch

```PowerShell
New-VMSwitch `
    -Name "Tenant vSwitch" `
    -NetAdapterName "Tenant Team" `
    -AllowManagementOS $true
```

```PowerShell
cls
```

#### # Enable jumbo frames on virtual switch

```PowerShell
$vSwitchIpAddress = Get-NetAdapter -Name "vEthernet (Tenant vSwitch)" |
    Get-NetIPAddress -AddressFamily IPv4 |
    select -ExpandProperty IPAddress

Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*" | select Name, DisplayValue

Name                       DisplayValue
----                       ------------
vEthernet (Tenant vSwitch) Disabled
Datacenter 2               9014 Bytes
Tenant 1                   9014 Bytes
Datacenter 1               9014 Bytes
Tenant 2                   9014 Bytes

Set-NetAdapterAdvancedProperty `
    -Name "vEthernet (Tenant vSwitch)" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*" | select Name, DisplayValue

Name                       DisplayValue
----                       ------------
vEthernet (Tenant vSwitch) 9014 Bytes
Datacenter 2               9014 Bytes
Tenant 1                   9014 Bytes
Datacenter 1               9014 Bytes
Tenant 2                   9014 Bytes


ping ICEMAN -f -l 8900 -S $vSwitchIpAddress
```

```PowerShell
cls
```

### # Configure VM storage

```PowerShell
mkdir C:\ClusterStorage\Volume1\VMs
mkdir D:\NotBackedUp\VMs
mkdir E:\NotBackedUp\VMs
mkdir F:\NotBackedUp\VMs
```

```PowerShell
cls
```

### # Configure server for live migration

```PowerShell
Enable-VMMigration

Add-VMMigrationNetwork 10.1.10.0/24

Set-VMHost -VirtualMachineMigrationAuthenticationType Kerberos
```

---

**FOOBAR8**

```PowerShell
cls
```

### # Configure constrained delegation in Active Directory

#### # Configure constrained delegation to mount ISO images to VMs

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-KCD.ps1 `
    -TrustedComputer TT-HV02D `
    -TrustingComputer TT-FS01 `
    -ServiceType cifs `
    -Add
```

#### # Configure constrained delegation to migrate VMs to other Hyper-V servers

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-KCD.ps1 `
    -TrustedComputer TT-HV02D `
    -TrustingComputer TT-HV02A `
    -ServiceType cifs `
    -Add

C:\NotBackedUp\Public\Toolbox\PowerShell\Set-KCD.ps1 `
    -TrustedComputer TT-HV02D `
    -TrustingComputer TT-HV02A `
    -ServiceType "Microsoft Virtual System Migration Service" `
    -Add

C:\NotBackedUp\Public\Toolbox\PowerShell\Set-KCD.ps1 `
    -TrustedComputer TT-HV02D `
    -TrustingComputer TT-HV02B `
    -ServiceType cifs `
    -Add

C:\NotBackedUp\Public\Toolbox\PowerShell\Set-KCD.ps1 `
    -TrustedComputer TT-HV02D `
    -TrustingComputer TT-HV02B `
    -ServiceType "Microsoft Virtual System Migration Service" `
    -Add
```

#### # Configure constrained delegation for VMs stored on Scale-Out File Server

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-KCD.ps1 `
    -TrustedComputer TT-HV02D `
    -TrustingComputer TT-SOFS01 `
    -ServiceType cifs `
    -Add
```

---

```PowerShell
cls
```

### # Add server to Hyper-V cluster

```PowerShell
Get-Cluster -Name TT-HV02-FC | Add-ClusterNode -Name TT-HV02D
```

## Reconfigure networking (to use logical switch defined in VMM)

### # Shutdown all VMs and disconnect network adapters

```PowerShell
Get-VM | Stop-VM

Get-VM | Get-VMNetworkAdapter | Disconnect-VMNetworkAdapter
```

```PowerShell
cls
```

### # Remove standard Hyper-V switch and NIC team

```PowerShell
Get-VMSwitch | Remove-VMSwitch

Remove-NetLbfoTeam -Name "Tenant Team"
```

```PowerShell
cls
```

### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter -InterfaceDescription "Intel(R) I210 Gigabit Network Connection" |
    Rename-NetAdapter -NewName "Team 1A"

Get-NetAdapter -InterfaceDescription "Intel(R) I210 Gigabit Network Connection #2" |
    Rename-NetAdapter -NewName "Team 1B"

Get-NetAdapter `
    -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter" |
    Rename-NetAdapter -NewName "Team 1C"

Get-NetAdapter `
    -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter #2" |
    Rename-NetAdapter -NewName "Team 1D"
```

### Configure DHCP addresses on all network adapters

```Console
sconfig
```

### Add logical switch in VMM

```PowerShell
cls
```

### # Configure networking

#### # Set affinity between virtual network adapters and physical network adapters

```PowerShell
Set-VMNetworkAdapterTeamMapping `
    -ManagementOS `
    -VMNetworkAdapterName "Storage 1" `
    -PhysicalNetAdapterName "Team 1A"

Set-VMNetworkAdapterTeamMapping `
    -ManagementOS `
    -VMNetworkAdapterName "Storage 2" `
    -PhysicalNetAdapterName "Team 1B"

Set-VMNetworkAdapterTeamMapping `
    -ManagementOS `
    -VMNetworkAdapterName "Live Migration" `
    -PhysicalNetAdapterName "Team 1C"
```

#### # Disable DHCPv6 on storage and live migration networks

```PowerShell
$interfaceAliases = @(
    "vEthernet (Cluster)",
    "vEthernet (Live Migration)"
    "vEthernet (Storage 1)",
    "vEthernet (Storage 2)")

$interfaceAliases |
    % {
        Set-NetIPInterface `
            -InterfaceAlias $_ `
            -Dhcp Disabled `
            -RouterDiscovery Disabled
    }
```

> **Important**
>
> If IPv6 addresses are assigned, failover clustering combines the different network adapters into a single cluster network.

```PowerShell
cls
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

$interfaceAliases = @(
    "vEthernet (Embedded Team Switch)",
    "vEthernet (Storage 1)",
    "vEthernet (Storage 2)",
    "vEthernet (Live Migration)")

$interfaceAliases |
    % {
        Set-NetAdapterAdvancedProperty `
            -Name $_ `
            -DisplayName "Jumbo Packet" `
            -RegistryValue 9014
    }

ping 10.1.10.1 -f -l 8900
ping 10.1.11.1 -f -l 8900
```

```PowerShell
cls
```

#### # Do not allow cluster network communication on the "storage" network (10.1.10.0/24)

```PowerShell
Get-ClusterNetwork | Get-ClusterNetworkInterface

(Get-ClusterNetwork -Name "Cluster Network 4").Role = 0
```

##### Reference

**Network Recommendations for a Hyper-V Cluster in Windows Server 2012**\
From <[https://technet.microsoft.com/en-us/library/dn550728(v=ws.11).aspx](https://technet.microsoft.com/en-us/library/dn550728(v=ws.11).aspx)>

```PowerShell
cls
```

### # Change network binding order for cluster network

```PowerShell
Get-NetIPInterface | sort AddressFamily, InterfaceMetric

Set-NetIPInterface -InterfaceAlias "vEthernet (Cluster)" -InterfaceMetric 15
```

```PowerShell
cls
```

### # Verify SMB Multichannel is working as expected

```PowerShell
$source = "\\TT-HV02A\C$\NotBackedUp\Products\Microsoft\Windows Server 2016"
$destination = "C:\NotBackedUp\Products\Microsoft\Windows Server 2016"

robocopy $source $destination en_windows_server_2016_x64_dvd_9718492.iso
```

### Issue: SMB Multichannel starts off strong, but throughput quickly drops

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3C/FCD0204F25E247CE44526B294F19C51A284F243C.png)

```PowerShell
cls
```

#### # Remove affinity between virtual network adapters and physical network adapters

```PowerShell
Get-VMNetworkAdapterTeamMapping -ManagementOS |
```

    % { Remove-VMNetworkAdapterTeamMapping -Name \$_.Name -ManagementOS }

```PowerShell
cls
```

### # Configure NIC team

#### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter `
    -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter" |
    Rename-NetAdapter -NewName "Storage Team 1A"

Get-NetAdapter `
    -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter #2" |
    Rename-NetAdapter -NewName "Storage Team 1B"
```

#### # Configure network team

```PowerShell
$interfaceAlias = "Storage Team 1"
```

##### # Create NIC team

```PowerShell
$teamMembers = "Storage Team 1A", "Storage Team 1B"

New-NetLbfoTeam `
    -Name $interfaceAlias `
    -TeamMembers $teamMembers `
    -Confirm:$false
```

##### # Verify NIC team status - "Storage Team 1"

```PowerShell
Write-Host "Waiting for NIC team to initialize..."
Start-Sleep -Seconds 5

do {
    If (Get-NetLbfoTeam -Name $interfaceAlias | Where Status -eq "Up")
    {
        return
    }

    Write-Host "." -NoNewline
    Start-Sleep -Seconds 5
```

}  while (\$true)

> **Important**
>
> Ensure the **Status** property of the network team is **Up**.

```PowerShell
cls
```

### # Verify SMB copy achieves ~2 Gbps throughput...

```PowerShell
$source = "\\TT-HV02A\C$\NotBackedUp\Products\Microsoft\Windows Server 2016"
$destination = "C:\NotBackedUp\Products\Microsoft\Windows Server 2016"

robocopy $source $destination en_windows_server_2016_x64_dvd_9718492.iso
```

### ...nope, only 1 Gbps throughput -- so try Switch Embedded Team (SET) instead of LBFO team

#### # Remove teamed switch

```PowerShell
Get-NetLbfoTeam | Remove-NetLbfoTeam
```

#### # Create Hyper-V switch using Switch Embedded Team

```PowerShell
New-VMSwitch -Name "Storage Team" -AllowManagementOS $True -NetAdapterName "Storage Team 1A", "Storage Team 1B" -EnableEmbeddedTeaming $True
```

```PowerShell
cls
```

### # Verify SMB copy achieves ~2 Gbps throughput...

```PowerShell
ipconfig /registerdns
ipconfig /flushdns

$source = "\\TT-HV02A\C$\NotBackedUp\Products\Microsoft\Windows Server 2016"
$destination = "C:\NotBackedUp\Products\Microsoft\Windows Server 2016"

robocopy $source $destination en_windows_server_2016_x64_dvd_9718492.iso
```

### ...nope, only 1 Gbps throughput -- so don't use teaming for "storage" network

#### # Remove teamed switch

```PowerShell
Get-VMSwitch "Storage Team" | Remove-VMSwitch
```

#### # Rename network connections

```PowerShell
Get-NetAdapter `
    -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter" |
    Rename-NetAdapter -NewName "Storage 1"

Get-NetAdapter `
    -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter #2" |
    Rename-NetAdapter -NewName "Storage 2"
```

```PowerShell
cls
```

### # Verify SMB copy achieves ~2 Gbps throughput...

```PowerShell
ipconfig /registerdns
ipconfig /flushdns

$source = "\\TT-HV02B\C$\NotBackedUp\Products\Microsoft\Windows Server 2016"
$destination = "C:\NotBackedUp\Products\Microsoft\Windows Server 2016"

robocopy $source $destination en_windows_server_2016_x64_dvd_9718492.iso
```

### ...yes

```PowerShell
cls
```

#### # Configure static IP addresses on "Storage 1" network

```PowerShell
$interfaceAlias = "Storage 1"
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
$ipAddress = "10.1.10.5"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24
```

##### # Configure static IPv6 address

**# Note:** Private IPv6 address range (fd87:77eb:097e:95a1::/64) generated by [http://simpledns.com/private-ipv6.aspx](http://simpledns.com/private-ipv6.aspx)

```PowerShell
$ipAddress = "fd87:77eb:097e:95a1::5"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 64
```

##### # Configure IPv4 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 192.168.10.103,192.168.10.104
```

##### # Configure IPv6 DNS servers

```PowerShell
Set-DnsClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 2603:300b:802:8900::103, 2603:300b:802:8900::104
```

```PowerShell
cls
```

#### # Configure static IP addresses on "Storage 2" network

```PowerShell
$interfaceAlias = "Storage 2"
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
$ipAddress = "10.1.10.6"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24
```

##### # Configure static IPv6 address

```PowerShell
$ipAddress = "fd87:77eb:097e:95a1::6"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 64
```

##### # Configure IPv4 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 192.168.10.103,192.168.10.104
```

##### # Configure IPv6 DNS servers

```PowerShell
Set-DnsClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 2603:300b:802:8900::103, 2603:300b:802:8900::104
```

---

**TT-VMM01A**

```PowerShell
cls
```

### # Reconnect all VM network adapters

```PowerShell
$vmNetwork = Get-SCVMNetwork -Name "Management VM Network"
$portClassification = Get-SCPortClassification -Name "1 Gbps Tenant vNIC"

Get-SCVirtualMachine -VMHost TT-HV02D |
    % {
        Get-SCVirtualNetworkAdapter -VM $_ |
            Set-SCVirtualNetworkAdapter `
                -VMNetwork $vmNetwork `
                -VirtualNetwork "Embedded Team Switch" `
                -PortClassification $portClassification
    }
```

---

## Install DPM agent

```Console
PowerShell
```

### # Install DPM 2016 agent

```PowerShell
$installer = "\\TT-FS01\Products\Microsoft\System Center 2016" `
    + "\DPM\Agents\DPMAgentInstaller_x64.exe"

& $installer TT-DPM02.corp.technologytoolbox.com
```

Review the licensing agreement. If you accept the Microsoft Software License Terms, select **I accept the license terms and conditions**, and then click **OK**.

Confirm the agent installation completed successfully and the following firewall exceptions have been added:

- Exception for DPMRA.exe in all profiles
- Exception for Windows Management Instrumentation service
- Exception for RemoteAdmin service
- Exception for DCOM communication on port 135 (TCP and UDP) in all profiles

#### Reference

**Installing Protection Agents Manually**\
Pasted from <[http://technet.microsoft.com/en-us/library/hh757789.aspx](http://technet.microsoft.com/en-us/library/hh757789.aspx)>

---

**TT-DPM02 - DPM Management Shell**

```PowerShell
cls
```

### # Attach DPM agent

```PowerShell
$productionServer = 'TT-HV02D'

.\Attach-ProductionServer.ps1 `
    -DPMServerName TT-DPM02 `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `
    -UserName jjameson-admin
```

---

## Issue: Storage tiers do not work with ReFS

From Storage-Tiers-Optimization.log:

```Text
    Microsoft Drive Optimizer
    Copyright (c) 2013 Microsoft Corp.

    Invoking tier optimization on Data01 (D:)...



    The operation requested is not supported by the hardware backing the volume. (0x8900002A)
```

Apparently there are some known issues with storage tiering and ReFS:

"ReFS should be used with Storage Spaces Direct (S2D), and stick with NTFS for all other scenarios."

-- Elden Christensen (MSFT)

**Windows Server 2016 Storage Spaces Tier ReFS**\
From <[https://social.technet.microsoft.com/Forums/windows/en-US/06f07aaf-484c-435e-b655-2761a1dcbb67/windows-server-2016-storage-spaces-tier-refs?forum=winserverfiles](https://social.technet.microsoft.com/Forums/windows/en-US/06f07aaf-484c-435e-b655-2761a1dcbb67/windows-server-2016-storage-spaces-tier-refs?forum=winserverfiles)>

```PowerShell
cls
```

## # Configure monitoring using System Center Operations Manager

### # Install SCOM agent

```PowerShell
$msiPath = "\\TT-FS01\Products\Microsoft\System Center 2016\Agents\SCOM\AMD64" `
    + "\MOMAgent.msi"

msiexec.exe /i $msiPath `
    MANAGEMENT_GROUP=HQ `
    MANAGEMENT_SERVER_DNS=TT-SCOM01 `
    ACTIONS_USE_COMPUTER_ACCOUNT=1
```

### Approve manual agent install in Operations Manager

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

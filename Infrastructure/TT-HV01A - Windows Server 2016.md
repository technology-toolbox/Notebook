# TT-HV01A (2017-01-09) - Windows Server 2016

Monday, January 9, 2017
8:59 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Install Windows Server 2016

## Rename computer and join domain

```Console
sconfig
```

> **Note**
>
> Rename the computer to **TT-HV01** and join the **corp.technologytoolbox.com** domain.

## Move computer to "Hyper-V Servers" OU

---

**FOOBAR8**

```PowerShell
$computerName = "TT-HV01"
$targetPath = ("OU=Hyper-V Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com")

Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath
```

---

## Add computer to "Hyper-V Servers" domain group

---

**FOOBAR8**

```PowerShell
Import-Module ActiveDirectory
Add-ADGroupMember -Identity "Hyper-V Servers" -Members TT-HV01$
```

---

```PowerShell
cls
```

## # Set time zone

```PowerShell
tzutil /s "Mountain Standard Time"
```

## # Download PowerShell help files

```PowerShell
Update-Help
```

```PowerShell
cls
```

## # Copy Toolbox content

```PowerShell
robocopy \\ICEMAN\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E
```

```PowerShell
cls
```

## # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

```PowerShell
cls
```

## # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter `
    -InterfaceDescription "Intel(R) 82579LM Gigabit Network Connection" |
    Rename-NetAdapter -NewName "Datacenter-1"

Get-NetAdapter `
    -InterfaceDescription "Intel(R) 82574L Gigabit Network Connection" |
    Rename-NetAdapter -NewName "Datacenter-2"

Get-NetAdapter -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter" |
    Rename-NetAdapter -NewName "Tenant-1"

Get-NetAdapter -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter #2" |
    Rename-NetAdapter -NewName "Tenant-2"
```

```PowerShell
cls
```

## # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name "Datacenter-1" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Set-NetAdapterAdvancedProperty -Name "Datacenter-2" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Set-NetAdapterAdvancedProperty -Name "Tenant-1" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Set-NetAdapterAdvancedProperty -Name "Tenant-2" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

ping ICEMAN -f -l 8900
```

## Issue - SMB Multichannel works with Intel 82574L but not with Intel 82579LM

```PowerShell
Get-NetAdapter

Name                      InterfaceDescription                    ifIndex Status       LinkSpeed
----                      --------------------                    ------- ------       ---------
Tenant-1                  Intel(R) Gigabit CT Desktop Adapter           9 Up              1 Gbps
Datacenter-1              Intel(R) 82579LM Gigabit Network Con...       4 Up              1 Gbps
Tenant-2                  Intel(R) Gigabit CT Desktop Adapter #2        8 Disconnected     0 bps
Datacenter-2              Intel(R) 82574L Gigabit Network Conn...       6 Up              1 Gbps


Get-NetAdapterRSS


Name                                            : Tenant-1
InterfaceDescription                            : Intel(R) Gigabit CT Desktop Adapter
Enabled                                         : True
NumberOfReceiveQueues                           : 2
Profile                                         : NUMAStatic
BaseProcessor: [Group:Number]                   : 0:0
MaxProcessor: [Group:Number]                    : 0:6
MaxProcessors                                   : 4
...

Name                                            : Datacenter-1
InterfaceDescription                            : Intel(R) 82579LM Gigabit Network Connection
Enabled                                         : True
NumberOfReceiveQueues                           : 1
Profile                                         : Closest
BaseProcessor: [Group:Number]                   : 0:0
MaxProcessor: [Group:Number]                    : 0:6
MaxProcessors                                   : 4
...

Name                                            : Tenant-2
InterfaceDescription                            : Intel(R) Gigabit CT Desktop Adapter #2
Enabled                                         : True
NumberOfReceiveQueues                           : 2
Profile                                         : NUMAStatic
BaseProcessor: [Group:Number]                   : 0:0
MaxProcessor: [Group:Number]                    : 0:6
MaxProcessors                                   : 4
...

Name                                            : Datacenter-2
InterfaceDescription                            : Intel(R) 82574L Gigabit Network Connection
Enabled                                         : True
NumberOfReceiveQueues                           : 2
Profile                                         : NUMAStatic
BaseProcessor: [Group:Number]                   : :0
MaxProcessor: [Group:Number]                    : :63
MaxProcessors                                   : 8
...


Set-NetAdapterRss -Name "Datacenter-1" -Profile NUMAStatic -NumberOfReceiveQueues 2
Set-NetAdapterRss : Failed to set 'NumberOfReceiveQueues' of 'RSS' configuration of adapter 'Datacenter-1'
At line:1 char:1
+ Set-NetAdapterRss -Name "Datacenter-1" -Profile NUMAStatic -NumberOfR ...
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidOperation: (MSFT_NetAdapter...219C6E3D121B}"):ROOT/StandardCi...rRssSettingData)
   [Set-NetAdapterRss], CimException
    + FullyQualifiedErrorId : Windows System Error 50,Set-NetAdapterRss

Get-NetAdapterRSS


Name                                            : Tenant-1
InterfaceDescription                            : Intel(R) Gigabit CT Desktop Adapter
Enabled                                         : True
NumberOfReceiveQueues                           : 2
Profile                                         : NUMAStatic
BaseProcessor: [Group:Number]                   : 0:0
MaxProcessor: [Group:Number]                    : 0:6
MaxProcessors                                   : 4
...

Name                                            : Datacenter-1
InterfaceDescription                            : Intel(R) 82579LM Gigabit Network Connection
Enabled                                         : True
NumberOfReceiveQueues                           : 1
Profile                                         : NUMAStatic
BaseProcessor: [Group:Number]                   : 0:0
MaxProcessor: [Group:Number]                    : 0:6
MaxProcessors                                   : 4
...

Name                                            : Tenant-2
InterfaceDescription                            : Intel(R) Gigabit CT Desktop Adapter #2
Enabled                                         : True
NumberOfReceiveQueues                           : 2
Profile                                         : NUMAStatic
BaseProcessor: [Group:Number]                   : 0:0
MaxProcessor: [Group:Number]                    : 0:6
MaxProcessors                                   : 4
...

Name                                            : Datacenter-2
InterfaceDescription                            : Intel(R) 82574L Gigabit Network Connection
Enabled                                         : True
NumberOfReceiveQueues                           : 2
Profile                                         : NUMAStatic
BaseProcessor: [Group:Number]                   : :0
MaxProcessor: [Group:Number]                    : :63
MaxProcessors                                   : 8
...


Get-NetAdapterAdvancedProperty -Name "Datacenter-1" |
    select DisplayName, DisplayValue

DisplayName                    DisplayValue
-----------                    ------------
Flow Control                   Rx & Tx Enabled
Interrupt Moderation           Enabled
IPv4 Checksum Offload          Rx & Tx Enabled
Jumbo Packet                   9014 Bytes
Large Send Offload V2 (IPv4)   Enabled
Large Send Offload V2 (IPv6)   Enabled
ARP Offload                    Enabled
NS Offload                     Enabled
Packet Priority & VLAN         Packet Priority & VLAN Enabled
Receive Buffers                256
Receive Side Scaling           Enabled
Speed & Duplex                 Auto Negotiation
TCP Checksum Offload (IPv4)    Rx & Tx Enabled
TCP Checksum Offload (IPv6)    Rx & Tx Enabled
Transmit Buffers               512
UDP Checksum Offload (IPv4)    Rx & Tx Enabled
UDP Checksum Offload (IPv6)    Rx & Tx Enabled
Adaptive Inter-Frame Spacing   Disabled
Interrupt Moderation Rate      Adaptive
Log Link State Event           Enabled
Gigabit Master Slave Mode      Auto Detect
Locally Administered Address   --
Wait for Link                  Auto Detect


Set-NetAdapterRss -Name "Datacenter-1" -NumberOfReceiveQueues 2
Set-NetAdapterRss : Failed to set 'NumberOfReceiveQueues' of 'RSS' configuration of adapter 'Datacenter-1'
At line:1 char:1
+ Set-NetAdapterRss -Name "Datacenter-1" -NumberOfReceiveQueues 2
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidOperation: (MSFT_NetAdapter...219C6E3D121B}"):ROOT/StandardCi...rRssSettingData)
   [Set-NetAdapterRss], CimException
    + FullyQualifiedErrorId : Windows System Error 50,Set-NetAdapterRss
```

#### # Revert profile for Intel 82579LM network adapter

```PowerShell
Set-NetAdapterRss -Name "Datacenter-1" -Profile Closest
```

```PowerShell
cls
```

### # Resolution - Use Intel Gigabit CT network adapters for "Datacenter" networks

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter `
    -InterfaceDescription "Intel(R) 82579LM Gigabit Network Connection" |
    Rename-NetAdapter -NewName "Temp-1"

Get-NetAdapter `
    -InterfaceDescription "Intel(R) 82574L Gigabit Network Connection" |
    Rename-NetAdapter -NewName "Temp-2"

Get-NetAdapter -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter" |
    Rename-NetAdapter -NewName "Datacenter-1"

Get-NetAdapter -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter #2" |
    Rename-NetAdapter -NewName "Datacenter-2"

Get-NetAdapter `
    -InterfaceDescription "Intel(R) 82579LM Gigabit Network Connection" |
    Rename-NetAdapter -NewName "Tenant-1"

Get-NetAdapter `
    -InterfaceDescription "Intel(R) 82574L Gigabit Network Connection" |
    Rename-NetAdapter -NewName "Tenant-2"
```

The following screenshot shows 1.5 Gbps throughput when copying a large file from ICEMAN to TT-HYP01:

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BF/23003F17717A47C9DBD69AA186B26F6046296FBF.png)

The following screenshot shows the load spread across two network adapters (729 Mbps and 619 Mbps) on TT-HYP01:

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4F/5154E5668F6139E3AD3699F02EB196B0D026244F.png)

```PowerShell
cls
```

## # Configure tenant network team

#### # Create NIC team

```PowerShell
$interfaceAlias = "Tenant Team"

New-NetLbfoTeam -Name $interfaceAlias -TeamMembers "Tenant-1", "Tenant-2"
```

## Enable Hyper-V role

### Enable Virtualization in BIOS

Intel Virtualization Technology: **Enabled**

```PowerShell
cls
```

### # Add Hyper-V role

```PowerShell
Install-WindowsFeature `
    -Name Hyper-V `
    -IncludeManagementTools `
    -Restart
```

### # Download PowerShell help files (for Hyper-V cmdlets)

```PowerShell
Update-Help
```

```PowerShell
cls
```

## # Configure Hyper-V virtual switch

### # Create Hyper-V virtual switch

```PowerShell
New-VMSwitch `
    -Name "Tenant vSwitch" `
    -NetAdapterName "Tenant Team" `
    -AllowManagementOS $true
```

```PowerShell
cls
```

### # Enable jumbo frames on virtual switches

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name "vEthernet (Tenant vSwitch)" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

ping ICEMAN -f -l 8900 -S 192.168.10.41
```

```PowerShell
cls
```

### # Modify virtual switch to disallow management OS

```PowerShell
Get-VMSwitch "Tenant vSwitch" |
    Set-VMSwitch -AllowManagementOS $false
```

## Configure storage

### Physical disks

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
<p>Model: Samsung SSD 840 Series<br />
Serial number: *********01728J</p>
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
<p>1</p>
</td>
<td valign='top'>
<p>Model: Samsung SSD 840 PRO Series<br />
Serial number: *********03944B</p>
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
<p>Model: Samsung SSD 850 PRO 128GB<br />
Serial number: *********03705D</p>
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
<p>3</p>
</td>
<td valign='top'>
<p>Model: Seagate ST1000NM0033-9ZM173<br />
Serial number: *****4YL</p>
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
<p>4</p>
</td>
<td valign='top'>
<p>Model: Seagate ST1000NM0033-9ZM173<br />
Serial number: *****EMV</p>
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
</table>

```PowerShell
Get-PhysicalDisk | select DeviceId, Model, SerialNumber | sort DeviceId
```

### Storage pools

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
<p>PhysicalDisk0<br />
PhysicalDisk1<br />
PhysicalDisk3<br />
PhysicalDisk4</p>
</td>
</tr>
</table>

### Virtual disks

| Name   | Layout | Provisioning | Capacity | SSD Tier | HDD Tier | Volume | Volume Label | Write-Back Cache |
| ------ | ------ | ------------ | -------- | -------- | -------- | ------ | ------------ | ---------------- |
| Data01 | Mirror | Fixed        | 200 GB   | 200 GB   |          | D:     | Data01       |                  |
| Data02 | Mirror | Fixed        | 900 GB   | 200 GB   | 700 GB   | E:     | Data02       | 5 GB             |
| Data03 | Simple | Fixed        | 200 GB   |          | 200 GB   | F:     | Data03       | 1 GB             |

```PowerShell
cls
```

### # Create storage pool

```PowerShell
$storageSubSystemName = "Windows Storage on $env:COMPUTERNAME"

$storageSubSystemUniqueId = `
    Get-StorageSubSystem -FriendlyName $storageSubSystemName |
    select -ExpandProperty UniqueId

New-StoragePool `
    -FriendlyName "Pool 1" `
    -StorageSubSystemUniqueId $storageSubSystemUniqueId `
    -PhysicalDisks (Get-PhysicalDisk -CanPool $true)
```

### # Check media type configuration

```PowerShell
Get-StoragePool "Pool 1" |
    Get-PhysicalDisk |
    Sort Size |
    ft FriendlyName, Size, MediaType, HealthStatus, OperationalStatus -AutoSize
```

```PowerShell
cls
```

### # Create storage tiers

```PowerShell
Get-StoragePool "Pool 1" |
    New-StorageTier -FriendlyName "SSD Tier" -MediaType SSD

Get-StoragePool "Pool 1" |
    New-StorageTier -FriendlyName "HDD Tier" -MediaType HDD
```

```PowerShell
cls
```

### # Create storage spaces

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
        -StorageTierSizes 200GB,700GB `
        -WriteCacheSize 5GB

Get-StoragePool "Pool 1" |
    New-VirtualDisk `
        -FriendlyName "Data03" `
        -ResiliencySettingName Simple `
        -StorageTiers $hddTier `
        -StorageTierSizes 200GB `
        -WriteCacheSize 1GB
```

```PowerShell
cls
```

### # Create partitions and volumes

#### # Create volume "D" on Data01

```PowerShell
Get-VirtualDisk "Data01" | Get-Disk | Set-Disk -IsReadOnly 0

Get-VirtualDisk "Data01"| Get-Disk | Set-Disk -IsOffline 0

Get-VirtualDisk "Data01"| Get-Disk | Initialize-Disk -PartitionStyle GPT

Get-VirtualDisk "Data01"| Get-Disk |
    New-Partition -DriveLetter "D" -UseMaximumSize

Initialize-Volume `
    -DriveLetter "D" `
    -FileSystem NTFS `
    -NewFileSystemLabel "Data01" `
    -Confirm:$false
```

#### # Create volume "E" on Data02

```PowerShell
Get-VirtualDisk "Data02" | Get-Disk | Set-Disk -IsReadOnly 0

Get-VirtualDisk "Data02"| Get-Disk | Set-Disk -IsOffline 0

Get-VirtualDisk "Data02"| Get-Disk | Initialize-Disk -PartitionStyle GPT

Get-VirtualDisk "Data02"| Get-Disk |
    New-Partition -DriveLetter "E" -UseMaximumSize

Initialize-Volume `
    -DriveLetter "E" `
    -FileSystem NTFS `
    -NewFileSystemLabel "Data02" `
    -Confirm:$false
```

#### # Create volume "F" on Data03

```PowerShell
Get-VirtualDisk "Data03" | Get-Disk | Set-Disk -IsReadOnly 0

Get-VirtualDisk "Data03"| Get-Disk | Set-Disk -IsOffline 0

Get-VirtualDisk "Data03"| Get-Disk | Initialize-Disk -PartitionStyle GPT

Get-VirtualDisk "Data03"| Get-Disk |
    New-Partition -DriveLetter "F" -UseMaximumSize

Initialize-Volume `
    -DriveLetter "F" `
    -FileSystem NTFS `
    -NewFileSystemLabel "Data03" `
    -Confirm:$false
```

```PowerShell
cls
```

### # Configure "Storage Tiers Optimization" scheduled task to append to log file

```PowerShell
New-Item -ItemType Directory -Path C:\NotBackedUp\Temp

$logFile = "C:\NotBackedUp\Temp\Storage-Tiers-Optimization.log"

$taskPath = "\Microsoft\Windows\Storage Tiers Management\"
$taskName = "Storage Tiers Optimization"

$task = Get-ScheduledTask -TaskPath $taskPath -TaskName $taskName

$task.Actions[0].Execute = "%windir%\system32\cmd.exe"

$task.Actions[0].Arguments = `
    "/C `"%windir%\system32\defrag.exe -c -h -g -# >> $logFile`""

Set-ScheduledTask $task
```

> **Important**
>
> Simply appending ">> {log file}" (as described in the "To change the Storage Tiers Optimization task to save a report (Task Scheduler)" section of the [TechNet article](TechNet article)) did not work. Specifically, when running the task, the log file was not created and the task immediately finished without reporting any error.\
> Changing the **Program/script** (i.e. the action's **Execute** property) to launch "%windir%\\system32\\defrag.exe" using "%windir%\\system32\\cmd.exe" resolved the issue.

#### Reference

**Save a report when Storage Tiers Optimization runs**\
From <[https://technet.microsoft.com/en-us/library/dn789160.aspx](https://technet.microsoft.com/en-us/library/dn789160.aspx)>

## Issue - Poor write performance on mirrored Samsung 840 SSDs

### Before

#### C: (SSD - Samsung 850 Pro 128GB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/24/56970BCBD63990C24E3E71C2875C4C9CD3A79B24.png)

#### D: (Mirror SSD storage space - 2x Samsung 840 512GB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/03/9250118972EEF9F8B918E57C9B5E519737AF9703.png)

#### E: (Mirror SSD/HDD storage space)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DC/BA90DE05C35CCD69741C558CC9ED6FB364FC13DC.png)

#### F: (Simple HDD storage space)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D3/849F2F590EE26E94B3B7A48DAA064B00A843AED3.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/ED/654FBE2B044D7E7EB063D5E9CC10B2846778D8ED.png)

### STORM (for comparison)

#### Benchmark C: (SSD - Samsung 850 Pro 128GB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0C/EA8C629095523D0CF0C88B9D6AEB08B729772D0C.png)

#### Benchmark D: (Mirror SSD storage space - 2x Samsung 840 512GB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3C/FA049D8B5BD2DE10A5174B037923D27E07AF0C3C.png)

#### Benchmark E: (Mirror SSD/HDD storage space)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5F/BFEFC0258A705B18A95939C9EB07CCB1A8075D5F.png)

#### Benchmark F: (Simple HDD storage space)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/88/D4BE461147A604A22BD43FE4B4DDAF2597417688.png)

### Solution

#### Update AHCI drivers

1. Download the latest AHCI drivers from the Intel website:\
   **Intel® RSTe AHCI & SCU Software RAID driver for Windows**\
   From <[https://downloadcenter.intel.com/download/25393/Intel-RSTe-AHCI-SCU-Software-RAID-driver-for-Windows-](https://downloadcenter.intel.com/download/25393/Intel-RSTe-AHCI-SCU-Software-RAID-driver-for-Windows-)>
2. Extract the drivers and copy the files to a temporary location on the server:
3. Install the drivers for the **Intel(R) C600 series chipset SATA AHCI Controller (PCI\\VEN_8086&DEV_1D02&...)**:
4. Restart the server.

```Console
    robocopy "C:\NotBackedUp\Temp\Drivers\Intel\RSTe AHCI & SCU Software RAID driver for Windows\Drivers\x64\Win8_10_2K8R2_2K12\AHCI" '\\TT-HV01\C$\NotBackedUp\Temp\Drivers\Intel\x64\Win8_10_2K8R2_2K12\AHCI' /E
```

```Console
    pnputil -i -a C:\NotBackedUp\Temp\Drivers\Intel\x64\Win8_10_2K8R2_2K12\AHCI\iaAHCI.inf
```

#### Swap SATA controllers for SSD drives

Apparently, there is a known issue with the Marvell 88SE9128 controller which caps SSD throughput at just under 400 MB/sec. Consequently, I moved the Samsung 850 128 GB drive to the Marvell controller (since write throughput on that drive is not as important) and moved the two Samsung 840 512 GB drives to the Intel RST controller.

### After

#### Benchmark C: (SSD - Samsung 850 Pro 128GB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/15/519535B0A6F687236645B38D82247E8E34153115.png)

#### Benchmark D: (Mirror SSD storage space - 2x Samsung 840 512GB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F4/308440FA708C0191F113E9861A0D04DD419FF3F4.png)

#### Benchmark E: (Mirror SSD/HDD storage space)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DD/E9B332D01CBB9B3B944ECFC49EF2260280AC28DD.png)

#### Benchmark F: (Simple HDD storage space)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/29/357F84ED3D27DC1E086F6E5B9DDBFDB70AB64629.png)

## # Rename server (so that TT-HV01 can be used as cluster name)

```PowerShell
Rename-Computer -NewName TT-HV01A -Restart
```

## # Configure VM storage

```PowerShell
mkdir D:\NotBackedUp\VMs
mkdir E:\NotBackedUp\VMs
mkdir F:\NotBackedUp\VMs

Set-VMHost -VirtualMachinePath E:\NotBackedUp\VMs
```

## Configure Live Migration (without Failover Clustering)

### Reference

**Configure Live Migration and Migrating Virtual Machines without Failover Clustering**\
Pasted from <[http://technet.microsoft.com/en-us/library/jj134199.aspx](http://technet.microsoft.com/en-us/library/jj134199.aspx)>

### Configure constrained delegation in Active Directory

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8D/3AB56ACC8B218B968CE0C6727BC4E299BC153C8D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DB/41DF2FCE6A360FA1A82E17944B565C52CCE17FDB.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9D/6E149755619C12978D14C0D0A378885865E0419D.png)

Click **Add...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/88/09A60E64FFA9B1ABD7006A7C1CDF2083DFB02388.png)

Click **Users or Computers...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EB/FA75FE5321E1F56B92CE8DB42269E09A121600EB.png)

Click **OK**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/39/06893082035B65F145E934E616B3A6FE4D543E39.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3D/87EA8CE1DA9437014BE88E78125AF40E0EC4113D.png)

Click **OK**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FF/F09D765142F09D6C036F8DD9B1C385318675B4FF.png)

Repeat the previous steps to add the following services to **BEAST** and **FORGE**:

- **cifs - TT-HV01A.corp.technologytoolbox.com**
- **Microsoft Virtual System Migration Service - TT-HV01A.corp.technologytoolbox.com**

### Restart Hyper-V servers

This is necessary to avoid an error when migrating VMs:

```PowerShell
Move-VM : Virtual machine migration operation for 'BANSHEE' failed at migration source 'FORGE'. (Virtual machine ID D46FD5CD-A9CB-40B1-ACFB-5CC8C759E2D5)
The Virtual Machine Management Service failed to establish a connection for a Virtual Machine migration with host 'TT-HV01A': No credentials are available in the security package (0x8009030E).
Failed to authenticate the connection at the source host: no suitable credentials available.
...
```

```PowerShell
cls
```

### # Configure the server for live migration

```PowerShell
Enable-VMMigration

Set-VMHost -UseAnyNetworkForMigration $true

Set-VMHost -VirtualMachineMigrationAuthenticationType Kerberos
```

## Migrate virtual machines to TT-HV01A

---

**FOOBAR8**

**# Note:** Must shutdown the VM first since the processors are not compatible

```PowerShell
Stop-VM -ComputerName FORGE -Name BANSHEE

Move-VM `
    -ComputerName FORGE `
    -Name BANSHEE `
    -DestinationHost TT-HV01A `
    -IncludeStorage `
    -DestinationStoragePath E:\NotBackedUp\VMs\BANSHEE

Start-VM -ComputerName TT-HV01A -Name BANSHEE
```

```PowerShell
cls
```

**# Note:** Must shutdown the VM first since the processors are not compatible

```PowerShell
Stop-VM -ComputerName FORGE -Name EXT-DC01

Move-VM `
    -ComputerName FORGE `
    -Name EXT-DC01 `
    -DestinationHost TT-HV01A `
    -IncludeStorage `
    -DestinationStoragePath E:\NotBackedUp\VMs\EXT-DC01

Start-VM -ComputerName TT-HV01A -Name EXT-DC01
```

```PowerShell
cls
```

**# Note:** Must shutdown the VM first since the processors are not compatible

```PowerShell
Stop-VM -ComputerName FORGE -Name FAB-DC01

Move-VM `
    -ComputerName FORGE `
    -Name FAB-DC01 `
    -DestinationHost TT-HV01A `
    -IncludeStorage `
    -DestinationStoragePath E:\NotBackedUp\VMs\FAB-DC01

Start-VM -ComputerName TT-HV01A -Name FAB-DC01
```

---

```PowerShell
cls
```

## # Configure "Datacenter-2" network adapter

```PowerShell
$interfaceAlias = "Datacenter-2"
```

### # Configure static IPv4 address

```PowerShell
$ipAddress = "10.1.10.102"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24

Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 192.168.10.103,192.168.10.104
```

### # Configure static IPv6 address

**# Note:** Private IPv6 address range (fd66:d7e2:39d6:a4d9::/64) generated by [http://simpledns.com/private-ipv6.aspx](http://simpledns.com/private-ipv6.aspx)

```PowerShell
$ipAddress = "fd66:d7e2:39d6:a4d9::102"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 64
```

**TODO:**

```PowerShell
cls
```

## # Clean up the WinSxS folder

```PowerShell
Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase
```

## # Clean up Windows Update files

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse
```

```PowerShell
cls
```

## # Install and configure System Center Operations Manager monitoring agent

### # Install SCOM agent

```PowerShell
$imagePath = '\\iceman\Products\Microsoft\System Center 2012 R2' `
    + '\en_system_center_2012_r2_operations_manager_x86_and_x64_dvd_2920299.iso'

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$msiPath = $imageDriveLetter + ':\agent\AMD64\MOMAgent.msi'

msiexec.exe /i $msiPath `
    MANAGEMENT_GROUP=HQ `
    MANAGEMENT_SERVER_DNS=JUBILEE `
    ACTIONS_USE_COMPUTER_ACCOUNT=1
```

### # Approve manual agent install in Operations Manager

```PowerShell
cls
```

## # Install and configure Data Protection Manager

### # Install DPM 2012 R2 agent

```PowerShell
$imagePath = "\\iceman\Products\Microsoft\System Center 2012 R2\" `
    + "mu_system_center_2012_r2_data_protection_manager_x86_and_x64_dvd_2945939.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$installer = $imageDriveLetter + ":\SCDPM\Agents\DPMAgentInstaller_x64.exe"

& $installer JUGGERNAUT.corp.technologytoolbox.com
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

### Attach DPM agent

On the DPM server (JUGGERNAUT), open **DPM Management Shell**, and run the following commands:

```PowerShell
$productionServer = "STORM"

.\Attach-ProductionServer.ps1 `
    -DPMServerName JUGGERNAUT `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `-UserName jjameson-admin
```

```PowerShell
cls
```

## # Enter a product key and activate Windows

```PowerShell
slmgr /ipk {product key}
```

**Note:** When notified that the product key was set successfully, click **OK**.

```Console
slmgr /ato
```

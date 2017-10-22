# TT-HV02A - Windows Server 2016

Sunday, March 5, 2017
6:37 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create domain group for fabric administrators

```PowerShell
$fabricAdminsGroup = "Fabric Admins"
$orgUnit = "OU=Groups,OU=IT,DC=corp,DC=technologytoolbox,DC=com"

New-ADGroup `
    -Name $fabricAdminsGroup `
    -Description "Complete and unrestricted access to fabric resources" `
    -GroupScope Global `
    -Path $orgUnit
```

### # Create fabric administrator account

```PowerShell
$displayName = "Jeremy Jameson (fabric admin)"
$defaultUserName = "jjameson-fabric"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@corp.technologytoolbox.com"
$orgUnit = "OU=Admin Accounts,OU=IT,DC=corp,DC=technologytoolbox,DC=com"

New-ADUser `
    -Name $displayName `
    -DisplayName $displayName `
    -SamAccountName $cred.UserName `
    -AccountPassword $cred.Password `
    -UserPrincipalName $userPrincipalName `
    -Path $orgUnit `
    -Enabled:$true
```

### # Add fabric admin account to fabric administrators domain group

```PowerShell
Add-ADGroupMember `
    -Identity $fabricAdminsGroup `
    -Members $cred.UserName
```

```PowerShell
cls
```

### # Create failover cluster objects in Active Directory

#### # Create cluster object for Hyper-V failover cluster and delegate permission to create the cluster to any member of the fabric administrators group

```PowerShell
$failoverClusterName = "TT-HV02-FC"
$delegate = "Fabric Admins"
$orgUnit = "OU=Hyper-V Servers,OU=Servers,OU=Resources,OU=IT," `
    + "DC=corp,DC=technologytoolbox,DC=com"

C:\NotBackedUp\Public\Toolbox\PowerShell\New-ClusterObject.ps1 `
    -Name $failoverClusterName  `
    -Delegate $delegate `
    -Path $orgUnit
```

---

### Install Windows Server 2016 Datacenter Edition ("Server Core")

### Login as local administrator account

```PowerShell
cls
```

### # Install latest patches

#### # Install cumulative update for Windows Server 2016

##### # Copy patch to local storage

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the server.

```PowerShell
$source = "\\TT-FS01\Products\Microsoft\Windows Server 2016\Patches"
$destination = "C:\NotBackedUp\Temp"
$patch = "windows10.0-kb4010672-x64_e12a6da8744518197757d978764b6275f9508692.msu"

robocopy $source $destination $patch
```

##### # Validate local copy of patch

```PowerShell
Get-FileHash -Algorithm SHA1 C:\NotBackedUp\Temp\windows10.0-kb4010672-x64_e12a6da8744518197757d978764b6275f9508692.msu
```

> **Important**
>
> Ensure the checksum matches the expected value (specified in the filename).

##### # Install patch

```PowerShell
& "$destination\$patch"
```

> **Note**
>
> When prompted, restart the computer to complete the installation.

```Console
PowerShell
```

```Console
cls
```

##### # Delete local copy of patch

```PowerShell
Remove-Item ("C:\NotBackedUp\Temp" `
    + "\windows10.0-kb4010672-x64_e12a6da8744518197757d978764b6275f9508692.msu")
```

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
> Rename the computer to **TT-HV02A** and join the **corp.technologytoolbox.com** domain.

---

**FOOBAR10**

```PowerShell
cls
```

### # Move computer to "Hyper-V Servers" OU

```PowerShell
$computerName = "TT-HV02A"
$targetPath = ("OU=Hyper-V Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com")
```

### # Add computer to "Hyper-V Servers" domain group

```PowerShell
Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath

Import-Module ActiveDirectory
Add-ADGroupMember -Identity "Hyper-V Servers" -Members TT-HV02A$
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

```PowerShell
cls
```

### # Configure networking

#### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter -InterfaceDescription "Intel(R) I210 Gigabit Network Connection" |
    Rename-NetAdapter -NewName "Team 1A"

Get-NetAdapter -InterfaceDescription "Intel(R) I210 Gigabit Network Connection #2" |
    Rename-NetAdapter -NewName "Team 1B"

Get-NetAdapter `
    -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter" |
    Rename-NetAdapter -NewName "Storage 1"

Get-NetAdapter `
    -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter #2" |
    Rename-NetAdapter -NewName "Storage 2"
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name "Team 1A" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Set-NetAdapterAdvancedProperty -Name "Team 1B" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Set-NetAdapterAdvancedProperty -Name "Storage 1" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Set-NetAdapterAdvancedProperty -Name "Storage 2" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

ping TT-FS01 -f -l 8900
```

### Configure storage

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
<p>Model: Samsung SSD 850 PRO 512GB<br />
Serial number: *********12260P</p>
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
<p>Model: Samsung SSD 850 PRO 128GB<br />
Serial number: *********03852K</p>
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
<p>2</p>
</td>
<td valign='top'>
<p>Model: Samsung SSD 850 PRO 512GB<br />
Serial number: *********09894X</p>
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
<p>Model: ST2000NM0033-9ZM175<br />
Serial number: *****34P</p>
</td>
<td valign='top'>
<p>2 TB</p>
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
<p>Model: ST2000NM0033-9ZM175<br />
Serial number: *****0FT</p>
</td>
<td valign='top'>
<p>2 TB</p>
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
<p>Model: WDC WD3000F9YZ-09N20L0<br />
Serial number: WD-******357156</p>
</td>
<td valign='top'>
<p>3 TB</p>
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
<p>Model: WDC WD3000F9YZ-09N20L0<br />
Serial number: WD-******FV469C</p>
</td>
<td valign='top'>
<p>3 TB</p>
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
<p>PhysicalDisk0<br />
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
| Data02 | Mirror | Fixed        | 900 GB   | 265 GB   | 1860 GB  | E:     | Data02       | 5 GB             |

#### Update AHCI drivers

1. Download the latest AHCI drivers from the Intel website:\
   **Intel® RSTe AHCI & SCU Software RAID driver for Windows**\
   From <[https://downloadcenter.intel.com/download/25393/Intel-RSTe-AHCI-SCU-Software-RAID-driver-for-Windows-](https://downloadcenter.intel.com/download/25393/Intel-RSTe-AHCI-SCU-Software-RAID-driver-for-Windows-)>
2. Extract the drivers (**[\\\\TT-FS01\\Public\\Download\\Drivers\\Intel\\RSTe](\\TT-FS01\Public\Download\Drivers\Intel\RSTe) AHCI & SCU Software RAID driver for Windows**) and copy the files to a temporary location on the server:
3. Install the drivers for the **Intel(R) C600+/C220+ series chipset SATA AHCI Controller (PCI\\VEN_8086&DEV_8D02&...)**:
4. Install the drivers for the **Intel(R) C600+/C220+ series chipset sSATA AHCI Controller (PCI\\VEN_8086&DEV_8D62&...)**:
5. Restart the server.

```Console
    robocopy "\\TT-FS01\Public\Download\Drivers\Intel\RSTe AHCI & SCU Software RAID driver for Windows\Drivers\x64\Win8_10_2K8R2_2K12\AHCI" '\\TT-HV02A\C$\NotBackedUp\Temp\Drivers\Intel\x64\Win8_10_2K8R2_2K12\AHCI' /E
```

```Console
    pnputil -i -a C:\NotBackedUp\Temp\Drivers\Intel\x64\Win8_10_2K8R2_2K12\AHCI\iaAHCI.inf
```

```Console
    pnputil -i -a C:\NotBackedUp\Temp\Drivers\Intel\x64\Win8_10_2K8R2_2K12\AHCI\iaAHCIB.inf
```

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
    (Get-PhysicalDisk -SerialNumber *********12260P),
    (Get-PhysicalDisk -SerialNumber *********09894X),
    (Get-PhysicalDisk -SerialNumber *****34P),
    (Get-PhysicalDisk -SerialNumber *****0FT))

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
        -FriendlyName "Gold01" `
        -ResiliencySettingName Mirror `
        -StorageTiers $ssdTier `
        -StorageTierSizes 200GB

$hddTier = Get-StorageTier -FriendlyName "HDD Tier"

Get-StoragePool "Pool 1" |
    New-VirtualDisk `
        -FriendlyName "Silver01" `
        -ResiliencySettingName Mirror `
        -StorageTiers $ssdTier,$hddTier `
        -StorageTierSizes 265GB,1860GB `
        -WriteCacheSize 5GB
```

> **Note**
>
> **1860GB** was found by trial and error:
>
> New-VirtualDisk : Not Supported
>
> Extended information:\
> The storage pool does not have sufficient eligible resources for the creation of the specified virtual disk.
>
> Recommended Actions:\
> - Choose a combination of FaultDomainAwareness and NumberOfDataCopies (or PhysicalDiskRedundancy) supported by the\
> storage pool.\
> - Choose a value for NumberOfColumns that is less than or equal to the number of physical disks in the storage fault\
> domain selected for the virtual disk.

```PowerShell
cls
```

#### # Create partitions and volumes

##### # Create volume "D" on Gold01

```PowerShell
Get-VirtualDisk "Gold01" | Get-Disk | Set-Disk -IsReadOnly 0

Get-VirtualDisk "Gold01"| Get-Disk | Set-Disk -IsOffline 0

Get-VirtualDisk "Gold01"| Get-Disk | Initialize-Disk -PartitionStyle GPT

Get-VirtualDisk "Gold01"| Get-Disk |
    New-Partition -DriveLetter "D" -UseMaximumSize

Initialize-Volume `
    -DriveLetter "D" `
    -FileSystem NTFS `
    -NewFileSystemLabel "Gold01" `
    -Confirm:$false
```

##### # Create volume "E" on Silver01

```PowerShell
Get-VirtualDisk "Silver01" | Get-Disk | Set-Disk -IsReadOnly 0

Get-VirtualDisk "Silver01"| Get-Disk | Set-Disk -IsOffline 0

Get-VirtualDisk "Silver01"| Get-Disk | Initialize-Disk -PartitionStyle GPT

Get-VirtualDisk "Silver01"| Get-Disk |
    New-Partition -DriveLetter "E" -UseMaximumSize

Initialize-Volume `
    -DriveLetter "E" `
    -FileSystem NTFS `
    -NewFileSystemLabel "Silver01" `
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

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FE/3465A2348A0AA0D85BA1DA4F94E0EB20A535E8FE.png)

##### D: (Mirror SSD storage space - 2x Samsung 850 Pro 512GB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D3/B5389598508E20EF07BB22D54D800439AF60CCD3.png)

##### E: (Mirror SSD/HDD storage space)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4E/CCF4841BD501B2AEF9EEBB2C26A694E06B72E14E.png)

## Prepare infrastructure for Hyper-V installation

### Enable Virtualization in BIOS

Intel Virtualization Technology: **Enabled**

```PowerShell
cls
```

### # Install Multipath I/O

```PowerShell
Install-WindowsFeature `
    -Name Multipath-IO `
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

### # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

```PowerShell
cls
```

### # Add roles for Hyper-V cluster

```PowerShell
Install-WindowsFeature `
    -Name Failover-Clustering, Hyper-V `
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

### # Join failover cluster

```PowerShell
Add-ClusterNode -Cluster TT-HV02-FC
```

---

**TT-VMM01A**

```PowerShell
cls
```

### # Add logical switches in VMM

#### # Add logical switch - "Embedded Team Switch"

```PowerShell
$vmHost = Get-SCVMHost -ComputerName TT-HV02A.corp.technologytoolbox.com

$logicalSwitch = Get-SCLogicalSwitch -Name "Embedded Team Switch"

$uplinkPortProfileSet = Get-SCUplinkPortProfileSet -Name "Trunk Uplink"

$networkAdapters = @()

$networkAdapters += Get-SCVMHostNetworkAdapter `
    -VMHost $vmHost `
    -Name "Intel(R) I210 Gigabit Network Connection"

$networkAdapters += Get-SCVMHostNetworkAdapter `
    -VMHost $vmHost `
    -Name "Intel(R) I210 Gigabit Network Connection #2"

$networkAdapters |
    % {
        $networkAdapter = $_

        Set-SCVMHostNetworkAdapter `
            -VMHostNetworkAdapter $networkAdapter `
            -UplinkPortProfileSet $uplinkPortProfileSet
    }

New-SCVirtualNetwork `
    -VMHost $vmHost `
    -VMHostNetworkAdapters $networkAdapters `
    -LogicalSwitch $logicalSwitch `
    -DeployVirtualNetworkAdapters
```

#### # Remove storage virtual network adapters

```PowerShell
Get-SCVirtualNetworkAdapter -VMHost $vmHost |
    ? { $_.Name -in $("Storage 1", "Storage 2") } |
    Remove-SCVirtualNetworkAdapter
```

#### # Add logical switches - "Storage 1" and "Storage 2"

```PowerShell
$switchNumber = 1

@("Intel(R) Gigabit CT Desktop Adapter",
    "Intel(R) Gigabit CT Desktop Adapter #2") |
    % {
        $nicName = $_

        $logicalSwitch = Get-SCLogicalSwitch -Name "Storage $switchNumber"

        $uplinkPortProfileSet = Get-SCUplinkPortProfileSet `
            -Name ("Storage Uplink - " + $logicalSwitch.Name)

        $networkAdapter = Get-SCVMHostNetworkAdapter `
            -VMHost $vmHost `
            -Name $nicName

        Set-SCVMHostNetworkAdapter `
            -VMHostNetworkAdapter $networkAdapter `
            -UplinkPortProfileSet $uplinkPortProfileSet

        New-SCVirtualNetwork `
            -VMHost $vmHost `
            -VMHostNetworkAdapters $networkAdapter `
            -LogicalSwitch $logicalSwitch `
            -DeployVirtualNetworkAdapters

        $switchNumber++
    }
```

---

```PowerShell
cls
```

### # Enable jumbo frames on virtual switches

```PowerShell
Get-NetAdapter |
    ? { $_.Name -like 'vEthernet*' } |
    % {
        Set-NetAdapterAdvancedProperty `
            -Name $_.Name `
            -DisplayName "Jumbo Packet" -RegistryValue 9014
    }

Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*" | select Name, DisplayValue

Name                             DisplayValue
----                             ------------
vEthernet (Storage 2)            9014 Bytes
vEthernet (Storage 1)            9014 Bytes
vEthernet (Live Migration)       9014 Bytes
vEthernet (Cluster)              9014 Bytes
vEthernet (Embedded Team Switch) 9014 Bytes
Storage 1                        9014 Bytes
Team 1B                          9014 Bytes
Team 1A                          9014 Bytes
Storage 2                        9014 Bytes

ping TT-FS01 -f -l 8900
```

```PowerShell
cls
```

### # Verify SMB Multichannel is working as expected

```PowerShell
$source = "\\TT-HV02B\C$\NotBackedUp\Temp"
$destination = "C:\NotBackedUp\Temp"

robocopy $source $destination en_windows_server_2016_x64_dvd_9718492.iso
```

```PowerShell
cls
```

### # Configure VM storage

```PowerShell
mkdir D:\NotBackedUp\VMs
mkdir E:\NotBackedUp\VMs

Set-VMHost -VirtualMachinePath E:\NotBackedUp\VMs
```

```PowerShell
cls
```

### # Configure server for live migration

```PowerShell
Enable-VMMigration

Set-VMHost -UseAnyNetworkForMigration $true

Add-VMMigrationNetwork 10.1.10.0/24
Add-VMMigrationNetwork 10.1.11.0/24

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
    -TrustedComputer TT-HV02A `
    -TrustingComputer TT-FS01 `
    -ServiceType cifs `
    -Add
```

#### # Configure constrained delegation to migrate VMs to other Hyper-V servers

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-KCD.ps1 `
    -TrustedComputer TT-HV02A `
    -TrustingComputer TT-HV02B `
    -ServiceType cifs `
    -Add

C:\NotBackedUp\Public\Toolbox\PowerShell\Set-KCD.ps1 `
    -TrustedComputer TT-HV02A `
    -TrustingComputer TT-HV02B `
    -ServiceType "Microsoft Virtual System Migration Service" `
    -Add

C:\NotBackedUp\Public\Toolbox\PowerShell\Set-KCD.ps1 `
    -TrustedComputer TT-HV02A `
    -TrustingComputer TT-HV02C `
    -ServiceType cifs `
    -Add

C:\NotBackedUp\Public\Toolbox\PowerShell\Set-KCD.ps1 `
    -TrustedComputer TT-HV02A `
    -TrustingComputer TT-HV02C `
    -ServiceType "Microsoft Virtual System Migration Service" `
    -Add
```

#### # Configure constrained delegation for VMs stored on Scale-Out File Server

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-KCD.ps1 `
    -TrustedComputer TT-HV02A `
    -TrustingComputer TT-SOFS01 `
    -ServiceType cifs `
    -Add
```

---

## Install DPM agent

```Console
PowerShell
```

### # Install DPM 2016 agent

```PowerShell
$installer = "\\TT-FS01\Products\Microsoft\System Center 2016" `
    + "\Agents\DPMAgentInstaller_x64.exe"

& $installer TT-DPM01.corp.technologytoolbox.com
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

**TT-DPM01 - DPM Management Shell**

```PowerShell
cls
```

### # Attach DPM agent

```PowerShell
$productionServer = 'TT-HV02A'

.\Attach-ProductionServer.ps1 `
    -DPMServerName TT-DPM01 `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `
    -UserName jjameson-admin
```

---

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

```Console
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

## Issue - Incorrect IPv6 DNS server assigned by Comcast router

```Text
PS C:\Users\jjameson-admin> nslookup
Default Server:  cdns01.comcast.net
Address:  2001:558:feed::1
```

> **Note**
>
> Even after reconfiguring the **Primary DNS** and **Secondary DNS** settings on the Comcast router -- and subsequently restarting the server -- the incorrect DNS server is assigned to the network adapter.

### Solution

```PowerShell
Set-DnsClientServerAddress `
    -InterfaceAlias "vEthernet (Embedded Team Switch)" `
    -ServerAddresses 2603:300b:802:8900::103, 2603:300b:802:8900::104

Restart-Computer
```

## Rebuild DPM 2016 server (replace TT-DPM01 with TT-DPM02)

### # Remove DPM agent

```PowerShell
MsiExec.exe /X "{14DD5B44-17CE-4E89-8BEB-2E6536B81B35}"
```

> **Note**
>
> The command to remove the DPM agent can be obtained from the following PowerShell:
>
> ```PowerShell
> Get-ChildItem HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall |
>     Get-ItemProperty |
>     where { $_.DisplayName -eq 'Microsoft System Center 2016  DPM Protection Agent' } |
>     select UninstallString
> ```

Restart the server to complete the removal.

```PowerShell
Restart-Computer
```

> **Note**
>
> Wait for the computer to restart.

```Console
PowerShell
```

### # Install DPM agent

```PowerShell
$installer = "\\TT-FS01\Products\Microsoft\System Center 2016" `
    + "\DPM\Agents\DPMAgentInstaller_x64.exe"

& $installer TT-DPM02.corp.technologytoolbox.com
```

---

**TT-DPM02 - DPM Management Shell**

```PowerShell
cls
```

### # Attach DPM agent

```PowerShell
$productionServer = 'TT-HV02A'

.\Attach-ProductionServer.ps1 `
    -DPMServerName TT-DPM02 `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `
    -UserName jjameson-admin
```

---

## Issue - Incorrect IPv6 DNS servers

```Text
PS C:\Users\jjameson-fabric> nslookup
DNS request timed out.
    timeout was 2 seconds.
Default Server:  UnKnown
Address:  2603:300b:802:8900::103
```

> **Note**
>
> Due to change in network configuration, TT-DC04 and TT-DC05 have addresses of 2603:300b:802:**89e0**::103 and 2603:300b:802:**89e0**::104, respectively.

### Solution

```PowerShell
Set-DnsClientServerAddress `
    -InterfaceAlias "vEthernet (Embedded Team Switch)" `
    -ResetServerAddresses

Restart-Computer
```

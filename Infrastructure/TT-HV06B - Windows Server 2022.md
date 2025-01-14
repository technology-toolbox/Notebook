# TT-HV06B - Windows Server 2022 Hyper-V cluster node

Thursday, January 12, 2025\
8:05 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure server infrastructure

### # Create and configure failover cluster object in Active Directory

### Install Windows Server 2022 Datacenter Edition ("Server Core")

### Login as local administrator account

### Install latest patches using Windows Update

### Rename computer and join domain

> **Note**
>
> Join the **corp.technologytoolbox.com** domain and rename the computer to **TT-HV06B**.

---

**TT-ADMIN05** - Run as administrator

```PowerShell
cls
```

### # Move computer to "Hyper-V Servers" organizational unit

```PowerShell
$computerName = "TT-HV06B"
$targetPath = ("OU=Hyper-V Servers,OU=Servers,OU=Resources," `
    + "OU=Information Technology,DC=corp,DC=technologytoolbox,DC=com")

Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath
```

### # Add computer to "Hyper-V Servers" domain group

```PowerShell
Import-Module ActiveDirectory
Add-ADGroupMember -Identity "Hyper-V Servers" -Members TT-HV06B$
```

### # Add fabric administrators domain group to local administrators group

```PowerShell
$scriptBlock = {
    net localgroup Administrators "TECHTOOLBOX\Fabric Admins" /ADD
}

Invoke-Command -ComputerName $computerName -ScriptBlock $scriptBlock
```

---

### Login as fabric administrator account

```Console
cls
```

### # Stop SConfig from launching at sign-in

```PowerShell
Set-SConfig -AutoLaunch $false
```

### # Set time zone

```PowerShell
tzutil /s "Mountain Standard Time"
```

### # Copy Toolbox content

```PowerShell
$source = "\\TT-FS01\Public\Toolbox"
$destination = "C:\NotBackedUp\Public\Toolbox"

robocopy $source $destination /E /MT /XD git-for-windows "Microsoft SDKs" /NP
```

### # Set MaxPatchCacheSize to 0 (recommended)

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

### # Enable performance counters for Server Manager

```PowerShell
$taskName = "\Microsoft\Windows\PLA\Server Manager Performance Monitor"

Enable-ScheduledTask -TaskName $taskName

logman start "Server Manager Performance Monitor"
```

### # TODO: Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

### Configure networking

#### Update network drivers

1. Download the latest network drivers from the Intel website:\
   [**Intel® Network Adapter Driver for Windows Server 2022**](https://www.intel.com/content/www/us/en/download/706171/intel-network-adapter-driver-for-windows-server-2022.html)
1. Extract the drivers to **\\\\TT-FS01\Products\Drivers\Intel\Network\I210\Windows Server 2022\Wired_driver_29.5_x64**.
1. Copy the files to a temporary location on the server.
1. Install the drivers for the **Intel(R) I210 Gigabit network adapter (PCI\\VEN_8086&DEV_1533&...)**.
1. Restart the server (if necessary).

```PowerShell
$source = "\\TT-FS01\Products\Drivers\Intel\Network\I210" `
    + "\Windows Server 2022\Wired_driver_29.5_x64\PRO1000\Winx64\WS2022"

$destination = "C:\NotBackedUp\Temp\Drivers\Intel\Network\I210" `
    + "\Windows Server 2022\Wired_driver_29.5_x64\PRO1000\Winx64\WS2022"

robocopy $source $destination /E

pushd $destination

pnputil /add-driver *.inf /install /reboot

popd
```

```PowerShell
cls
```

#### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter -InterfaceDescription "Intel(R) I210 Gigabit Network Connection" |
    Rename-NetAdapter -NewName "Team 1A"

Get-NetAdapter -InterfaceDescription "Intel(R) I210 Gigabit Network Connection #2" |
    Rename-NetAdapter -NewName "Team 1B"

Get-NetAdapter |
    where { $_.MacAddress -eq '68-05-CA-19-13-31' } |
    Rename-NetAdapter -NewName "Storage-10"

Get-NetAdapter |
    where { $_.MacAddress -eq '68-05-CA-1A-C8-25' } |
    Rename-NetAdapter -NewName "Storage-13"
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name "Team 1A" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Set-NetAdapterAdvancedProperty -Name "Team 1B" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Set-NetAdapterAdvancedProperty -Name "Storage-10" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Set-NetAdapterAdvancedProperty -Name "Storage-13" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

ping TT-FS01 -f -l 8900
```

```PowerShell
cls
```

#### # Configure iSCSI network adapters

##### # Configure Storage-10 network adapter

```PowerShell
$interfaceAlias = "Storage-10"
```

###### # Disable DHCP and router discovery

```PowerShell
Set-NetIPInterface `
    -InterfaceAlias $interfaceAlias `
    -Dhcp Disabled `
    -RouterDiscovery Disabled
```

###### # Configure static IPv4 address

```PowerShell
$ipAddress = "10.1.10.3"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24
```

> **Note:** A default gateway is not configured on this interface, since it is used exclusively for iSCSI storage.

```PowerShell
cls
```

##### # Configure Storage-13 network adapter

```PowerShell
$interfaceAlias = "Storage-13"
```

###### # Disable DHCP and router discovery

```PowerShell
Set-NetIPInterface `
    -InterfaceAlias $interfaceAlias `
    -Dhcp Disabled `
    -RouterDiscovery Disabled
```

###### # Configure static IPv4 address

```PowerShell
$ipAddress = "10.1.13.3"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24
```

> **Note:** A default gateway is not configured on this interface, since it is used exclusively for iSCSI storage.

```PowerShell
cls
```

### # Configure direct-attached storage

#### # Identify physical disks

```PowerShell
Get-PhysicalDisk | sort DeviceId | select DeviceId, Model, SerialNumber, Size
```

| Disk | Model | Serial Number | Capacity | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 0 | WDC WD4002FYYZ-01B7CB1 | \*\*\*\*\*03Y | 4 TB |  |  |  |  |
| 1 | Samsung SSD 850 PRO 128GB | \*\*\*\*\*\*\*\*\*03705D | 128 GB | C: | 119 GB | 4K |  |
| 2 | Samsung SSD 840 Series | \*\*\*\*\*\*\*\*\*45678J | 512 GB |  |  |  |  |
| 3 | Samsung SSD 840 Series | \*\*\*\*\*\*\*\*\*01728J | 512 GB |  |  |  |  |
| 4 | WDC WD4002FYYZ-01B7CB0 | \*\*\*\*\*ASL | 4 TB |  |  |  |  |

```PowerShell
cls
```

#### # Benchmark performance of physical disks

##### # Clear physical disks

```PowerShell
Get-StoragePool Pool-01 | Get-VirtualDisk | Remove-VirtualDisk -Confirm:$false

Remove-StoragePool Pool-01 -Confirm:$false

Get-PhysicalDisk |
    where { $_.SerialNumber -notlike "*03705D" } |
    foreach {
        $physicalDisk = $_

        $disk = $physicalDisk | Get-Disk

        $disk |
            where { $_.PartitionStyle -ne "RAW" } |
            Clear-Disk -RemoveData -RemoveOEM -Confirm:$false -Verbose

        $disk |
            Initialize-Disk -PartitionStyle GPT |
            Out-Null
    }

Update-StorageProviderCache -DiscoveryLevel Full
```

```PowerShell
cls
```

```PowerShell
Get-PhysicalDisk -CanPool $true |
    select DeviceId, Model, SerialNumber |
    sort Model, DeviceId
```

```Text
DeviceId Model            SerialNumber
-------- -----            ------------
2        Samsung SSD 840  *********45678J
3        Samsung SSD 840  *********01728J
0        WDC WD4002FYYZ-0 *****03Y
4        WDC WD4002FYYZ-0 *****ASL
```

```PowerShell
cls
```

##### # Create temporary partitions and volumes

```PowerShell
$physicalDrives = @(
    [PSCustomObject] @{ DiskNumber = 2; DriveLetter = "D"; Label = "Samsung SSD 840 512GB" },
    [PSCustomObject] @{ DiskNumber = 3; DriveLetter = "E"; Label = "Samsung SSD 840 512GB" },
    [PSCustomObject] @{ DiskNumber = 0; DriveLetter = "F"; Label = "WDC WD4002FYYZ-0" },
    [PSCustomObject] @{ DiskNumber = 4; DriveLetter = "G"; Label = "WDC WD4002FYYZ-0" }
)

$physicalDrives |
    foreach {
        Get-Disk $_.DiskNumber | Set-Disk -IsReadOnly 0
        Get-Disk $_.DiskNumber | Set-Disk -IsOffline 0
        Get-Disk $_.DiskNumber |
            where { $_.PartitionStyle -ne "RAW" } |
            Clear-Disk -RemoveData -RemoveOEM -Confirm:$false -Verbose

        Get-Disk $_.DiskNumber |
            Initialize-Disk -PartitionStyle GPT |
            Out-Null

        Get-Disk $_.DiskNumber |
            New-Partition -DriveLetter $_.DriveLetter -UseMaximumSize

        Initialize-Volume `
            -DriveLetter $_.DriveLetter `
            -FileSystem NTFS `
            -NewFileSystemLabel $_.Label `
            -Confirm:$false
    }
```

```PowerShell
cls
```

##### # Benchmark performance of individual disks

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\ATTO Disk Benchmark\v3\ATTODiskBenchmark.exe'
```

###### C: (SSD - Samsung 850 Pro 128GB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/92/ED0B38F2FA1CA7EF5E9192377EAA1CBE419D5992.png)

###### D: (SSD - Samsung 840 512GB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/64/3EDFCA115BFCC4411B4309C698F7D1DC81F18E64.png)

> Note
>
> According to the following review, the original Samsung 840 series 512GB SSD has a maximum sequential write speed of 330 MB/s.
>
> [Samsung’s 840 Series SSD reviewed](https://arstechnica.com/gadgets/2012/11/samsungs-840-series-ssd-reviewed/#page-2)

###### E: (SSD - Samsung 840 512GB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E6/F8A765C07CD5117F7EEFBF091FBCC4D4BCA639E6.png)

###### F: (HDD - WDC WD4002FYYZ-0)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/66/C4059C6A6B968A1FC5C1E0E1FF6CF59EAF424066.png)

###### G: (HDD - WDC WD4002FYYZ-0)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0E/63881283BD56BB1882BB632CC257B54A8163960E.png)

```PowerShell
cls
```

#### # Configure storage pool

##### # Clear physical disks for storage pool

```PowerShell
Get-PhysicalDisk |
    where { $_.BusType -ne "USB" } |
    where { $_.SerialNumber -notlike "*03705D" } |
    foreach {
        $physicalDisk = $_

        $disk = $physicalDisk | Get-Disk

        $disk |
            where { $_.PartitionStyle -ne "RAW" } |
            Clear-Disk -RemoveData -RemoveOEM -Confirm:$false -Verbose

        $disk |
            Initialize-Disk -PartitionStyle GPT |
            Out-Null
    }

Update-StorageProviderCache -DiscoveryLevel Full
```

```PowerShell
cls
```

##### # Create storage pool

```PowerShell
$storageSubSystemName = "Windows Storage on $env:COMPUTERNAME"

$storageSubSystemUniqueId = `
    Get-StorageSubSystem -FriendlyName $storageSubSystemName |
    select -ExpandProperty UniqueId

$physicalDrives = @(
    [PSCustomObject] @{ DiskNumber = 2; Label = "Samsung SSD 840 512GB" },
    [PSCustomObject] @{ DiskNumber = 3; Label = "Samsung SSD 840 512GB" },
    [PSCustomObject] @{ DiskNumber = 0; Label = "WDC WD4002FYYZ-0" },
    [PSCustomObject] @{ DiskNumber = 4; Label = "WDC WD4002FYYZ-0" }
)

[System.Collections.ArrayList] $physicalDisks = @()

$physicalDrives |
    foreach {
        $diskNumber = $_.DiskNumber

        $physicalDisk = Get-PhysicalDisk |
            where { $_.DeviceId -eq $diskNumber }

        $physicalDisks += $physicalDisk
    }

New-StoragePool `
    -FriendlyName Pool-01 `
    -StorageSubSystemUniqueId $storageSubSystemUniqueId `
    -PhysicalDisks $physicalDisks
```

##### # Verify media type configuration

```PowerShell
$storagePool = Get-StoragePool Pool-01

$storagePool |
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

##### # Create storage tiers

```PowerShell
$storagePool |
    New-StorageTier -FriendlyName "Performance" -MediaType SSD

$storagePool |
    New-StorageTier -FriendlyName "Capacity" -MediaType HDD
```

##### # Create storage spaces

```PowerShell
$performanceTier = Get-StorageTier -FriendlyName "Performance"

$storagePool |
    New-VirtualDisk `
        -FriendlyName Gold-01 `
        -ResiliencySettingName Mirror `
        -StorageTiers $performanceTier `
        -StorageTierSizes 200GB `
        -WriteCacheSize 0

$capacityTier = Get-StorageTier -FriendlyName "Capacity"

$storagePool |
    New-VirtualDisk `
        -FriendlyName Silver-01 `
        -ResiliencySettingName Mirror `
        -StorageTiers $performanceTier, $capacityTier `
        -StorageTierSizes 250GB,2500GB `
        -WriteCacheSize 5GB

$storagePool |
    New-VirtualDisk `
        -FriendlyName Bronze-01 `
        -ResiliencySettingName Mirror `
        -MediaType HDD `
        -UseMaximumSize `
        -WriteCacheSize 5GB
```

```PowerShell
cls
```

##### # Create partitions and volumes

###### # Create volume "D" on Gold-01

```PowerShell
$virtualDiskName = "Gold-01"
$driveLetter = "D"
$fileSystem = "NTFS"

$virtualDisk = Get-VirtualDisk $virtualDiskName

$virtualDisk | Get-Disk | Set-Disk -IsReadOnly 0

$virtualDisk | Get-Disk | Set-Disk -IsOffline 0

$virtualDisk | Get-Disk | Initialize-Disk -PartitionStyle GPT

$virtualDisk | Get-Disk |
    New-Partition -DriveLetter $driveLetter -UseMaximumSize

Initialize-Volume `
    -DriveLetter $driveLetter `
    -FileSystem $fileSystem `
    -NewFileSystemLabel $virtualDiskName `
    -Confirm:$false
```

###### # Create volume "E" on Silver-01

```PowerShell
$virtualDiskName = "Silver-01"
$driveLetter = "E"
$fileSystem = "NTFS"
```

> **Important**
>
> When using storage tiers, format the volume using NTFS (not ReFS). Otherwise, an error occurs when optimizing the storage tiers:
>
> The operation requested is not supported by the hardware backing the volume. (0x8900002A)
>
> Refer to the following resources for more information:
>
> **Resilient File System (ReFS) overview**\
> From <[https://docs.microsoft.com/en-us/windows-server/storage/refs/refs-overview](https://docs.microsoft.com/en-us/windows-server/storage/refs/refs-overview)>
>
> The following features are unavailable on ReFS at this time:
>
> | **Functionality**  | **ReFS** | **NTFS** |
> | ------------------ | -------- | -------- |
> | ...                | ...      | ...      |
> | NTFS storage tiers | No       | Yes      |
>
> **Windows Server 2016 Storage Spaces Tier ReFS**\
> From <[https://social.technet.microsoft.com/Forums/lync/en-US/06f07aaf-484c-435e-b655-2761a1dcbb67/windows-server-2016-storage-spaces-tier-refs?forum=winserverfiles](https://social.technet.microsoft.com/Forums/lync/en-US/06f07aaf-484c-435e-b655-2761a1dcbb67/windows-server-2016-storage-spaces-tier-refs?forum=winserverfiles)>
>
> "ReFS should be used with Storage Spaces Direct (S2D), and stick with NTFS for all other scenarios."
>
> -- Elden Christensen (MSFT)\
> Tuesday, November 01, 2016 2:18 AM

```PowerShell
$virtualDisk = Get-VirtualDisk $virtualDiskName

$virtualDisk | Get-Disk | Set-Disk -IsReadOnly 0

$virtualDisk | Get-Disk | Set-Disk -IsOffline 0

$virtualDisk | Get-Disk | Initialize-Disk -PartitionStyle GPT

$virtualDisk | Get-Disk |
    New-Partition -DriveLetter $driveLetter -UseMaximumSize

Initialize-Volume `
    -DriveLetter $driveLetter `
    -FileSystem $fileSystem `
    -NewFileSystemLabel $virtualDiskName `
    -Confirm:$false
```

###### # Create volume "F" on Bronze-01

```PowerShell
$virtualDiskName = "Bronze-01"
$driveLetter = "F"
$fileSystem = "NTFS"

$virtualDisk = Get-VirtualDisk $virtualDiskName

$virtualDisk | Get-Disk | Set-Disk -IsReadOnly 0

$virtualDisk | Get-Disk | Set-Disk -IsOffline 0

$virtualDisk | Get-Disk | Initialize-Disk -PartitionStyle GPT

$virtualDisk | Get-Disk |
    New-Partition -DriveLetter $driveLetter -UseMaximumSize

Initialize-Volume `
    -DriveLetter $driveLetter `
    -FileSystem $fileSystem `
    -NewFileSystemLabel $virtualDiskName `
    -Confirm:$false
```

```PowerShell
cls
```

#### # Benchmark performance of storage spaces

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\ATTO Disk Benchmark\v3\ATTODiskBenchmark.exe'
```

##### D: (Mirror SSD storage space - Samsung 840 512GB x2)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/86/0ECF3FE75545C45B9D715AEFBAE864DFB9DF2386.png)

##### E: (Mirror SSD/HDD storage space)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DF/F9E951E194B221DB791AC2A6172A817529DEBFDF.png)

##### F: (Mirror HDD storage space with SSD write cache)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/96/379C9B0AA3A999DCC81A1CB196E6D5A136F89396.png)

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
> Simply appending ">> {log file}" (as described in the "To change the Storage Tiers Optimization task to save a report (Task Scheduler)" section of the> [TechNet article](TechNet article)) did not work. Specifically, when running the task, the log file was not created and the task immediately finished without reporting any error.
>
> Changing the **Program/script** (i.e. the action's **Execute** property) to launch "%windir%\\system32\\defrag.exe" using "%windir%\\system32\\cmd.exe" resolved the issue.

###### Reference

**Save a report when Storage Tiers Optimization runs**\
From <[https://technet.microsoft.com/en-us/library/dn789160.aspx](https://technet.microsoft.com/en-us/library/dn789160.aspx)>

### Configure network-attached storage

#### Configure iSCSI client

##### Reference

**Configuring multiple ISCSI Connections for Multipath IO using PowerShell.**\
From <[https://chinnychukwudozie.com/2013/11/11/configuring-multipath-io-with-multiple-iscsi-connections-using-powershell/](https://chinnychukwudozie.com/2013/11/11/configuring-multipath-io-with-multiple-iscsi-connections-using-powershell/)>

```PowerShell
cls
```

#### # Start iSCSI service

```PowerShell
Set-Service msiscsi -StartupType Automatic

Start-Service msiscsi
```

#### # Configure multipath I/O (MPIO) settings

##### # Ensure multipath I/O feature is installed

```PowerShell
Enable-WindowsOptionalFeature -Online -FeatureName MultipathIo

Restart-Computer
```

> **Important**
>
> In Windows Server 2022, the `Enable-WindowsOptionalFeature` cmdlet reports that a restart is _not_ needed after adding the multipath I/O feature. However, attempting to set the default load balancing policy (using the `Set-MSDSMGlobalDefaultLoadBalancePolicy` cmdlet) results in an error ("invalid class") if the computer has not been rebooted. To avoid this error, restart the server to complete the feature installation.

> **Note**
>
> Wait for the computer to restart and then login using a fabric administrator account.

##### # Enable automatic claiming of all iSCSI volumes

```PowerShell
Enable-MSDSMAutomaticClaim -BusType iSCSI
```

##### # Set default load balancing policy

```PowerShell
Set-MSDSMGlobalDefaultLoadBalancePolicy -Policy RR
```

##### # Configure disk timeout

```PowerShell
Set-MPIOSetting -NewDiskTimeout 60

Restart-Computer
```

> **Note**
>
> Wait for the computer to restart and then login using a fabric administrator account.

```PowerShell
cls
```

#### # Connect to iSCSI portal (using multiple paths)

```PowerShell
New-IscsiTargetPortal `
    -TargetPortalAddress 10.1.10.6 `
    -InitiatorPortalAddress 10.1.10.3

New-IscsiTargetPortal `
    -TargetPortalAddress 10.1.13.6 `
    -InitiatorPortalAddress 10.1.13.3

Start-Sleep 30
```

#### # Connect first path to iSCSI target

```PowerShell
Connect-IscsiTarget `
    -NodeAddress "iqn.2005-10.org.freenas.ctl:tt-hv06-fc" `
    -TargetPortalAddress 10.1.10.6 `
    -InitiatorPortalAddress 10.1.10.3 `
    -IsMultipathEnabled $true `
    -IsPersistent $true
```

#### # Connect additional paths to iSCSI target

```PowerShell
Connect-IscsiTarget `
    -NodeAddress "iqn.2005-10.org.freenas.ctl:tt-hv06-fc" `
    -TargetPortalAddress 10.1.13.6 `
    -InitiatorPortalAddress 10.1.13.3 `
    -IsMultipathEnabled $true `
    -IsPersistent $true
```

## Prepare infrastructure for Hyper-V installation

### Enable Virtualization in BIOS

Intel Virtualization Technology: **Enabled**

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

> **Note**
>
> Wait for the computer to restart and then login using a fabric administrator account.

```Console
cls
```

## # Deploy Hyper-V

### # Configure Hyper-V virtual switch

```PowerShell
New-VMSwitch `
    -Name "Embedded Team Switch" `
    -NetAdapterName "Team 1A", "Team 1B" `
    -MinimumBandwidthMode Weight `
    -AllowManagementOS $true `
    -EnableEmbeddedTeaming $true

# Change the default bandwidth weight for the switch from 1 to 0 (to ensure all
# virtual network adapters have a weight)
Set-VMSwitch -Name "Embedded Team Switch" -DefaultFlowMinimumBandwidthWeight 0
```

```PowerShell
cls
```

### # Configure network adapters for Hyper-V cluster

#### # Configure "Management" network adapter

```PowerShell
Add-VMNetworkAdapter `
    -ManagementOS `
    -Name "Management" `
    -SwitchName "Embedded Team Switch"

Set-VMNetworkAdapterVlan `
    -ManagementOS `
    -VMNetworkAdapterName "Management" `
    -Access `
    -VlanId 30

Set-VMNetworkAdapter `
    -ManagementOS `
    -Name "Management" `
    -MinimumBandwidthWeight 10

# Disable/enable network adapter to refresh DHCP address, DNS settings, and
# default gateway for the Management VLAN
Get-NetAdapter -Name "vEthernet (Management)" |
    Disable-NetAdapter -Confirm:$false

Get-NetAdapter -Name "vEthernet (Management)" |
    Enable-NetAdapter
```

#### # Configure "Cluster" network adapter

```PowerShell
Add-VMNetworkAdapter `
    -ManagementOS `
    -Name "Cluster" `
    -SwitchName "Embedded Team Switch"

Set-VMNetworkAdapterVlan `
    -ManagementOS `
    -VMNetworkAdapterName "Cluster" `
    -Access `
    -VlanId 12

Set-VMNetworkAdapter `
    -ManagementOS `
    -Name "Cluster" `
    -MinimumBandwidthWeight 10

New-NetIPAddress `
    -InterfaceAlias "vEthernet (Cluster)" `
    -IPAddress 172.16.12.3 `
    -PrefixLength 24
```

> **Note**
>
> A default gateway is not configured on this interface, since it is used exclusively for cluster traffic.

#### # Configure "Live Migration" network adapter

```PowerShell
Add-VMNetworkAdapter `
    -ManagementOS `
    -Name "Live Migration" `
    -SwitchName "Embedded Team Switch"

Set-VMNetworkAdapterVlan `
    -ManagementOS `
    -VMNetworkAdapterName "Live Migration" `
    -Access `
    -VlanId 11

Set-VMNetworkAdapter `
    -ManagementOS `
    -Name "Live Migration" `
    -MinimumBandwidthWeight 40

New-NetIPAddress `
    -InterfaceAlias "vEthernet (Live Migration)" `
    -IPAddress 10.1.11.3 `
    -PrefixLength 24
```

> **Note**
>
> A default gateway is not configured on this interface, since it is used exclusively for cluster traffic.

```PowerShell
cls
```

#### # Remove default virtual network adapter created for Hyper-V switch

```PowerShell
Remove-VMNetworkAdapter `
    -ManagementOS `
    -Name "Embedded Team Switch" `
    -SwitchName "Embedded Team Switch"
```

```PowerShell
cls
```

### # Enable jumbo frames on virtual switch

```PowerShell
$managementIpAddress = Get-NetAdapter -Name "vEthernet (Management)" |
    Get-NetIPAddress -AddressFamily IPv4 |
    select -ExpandProperty IPAddress

Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*" |
    sort Name |
    select Name, DisplayValue
```

```output
Name                       DisplayValue
----                       ------------
Storage-10                 9014 Bytes
Storage-13                 9014 Bytes
Team 1A                    9014
Team 1B                    9014
vEthernet (Cluster)        Disabled
vEthernet (Live Migration) Disabled
vEthernet (Management)     Disabled
```

```PowerShell
Set-NetAdapterAdvancedProperty `
    -Name "vEthernet (Management)" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Set-NetAdapterAdvancedProperty `
    -Name "vEthernet (Cluster)" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Set-NetAdapterAdvancedProperty `
    -Name "vEthernet (Live Migration)" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*" |
    sort Name |
    select Name, DisplayValue
```

```output
Name                       DisplayValue
----                       ------------
Storage-10                 9014 Bytes
Storage-13                 9014 Bytes
Team 1A                    9014
Team 1B                    9014
vEthernet (Cluster)        9014 Bytes
vEthernet (Live Migration) 9014 Bytes
vEthernet (Management)     9014 Bytes
```

```PowerShell
ping TT-FS01 -f -l 8900 -S $managementIpAddress
```

```PowerShell
cls
```

### # Configure VM storage

```PowerShell
New-Item -ItemType directory -Path D:\NotBackedUp\VMs
New-Item -ItemType directory -Path E:\NotBackedUp\VMs
New-Item -ItemType directory -Path F:\NotBackedUp\VMs

Set-VMHost -VirtualMachinePath E:\NotBackedUp\VMs
```

```PowerShell
cls
```

### # Configure VM migration

```PowerShell
Enable-VMMigration

Set-VMMigrationNetwork 10.1.11.0/24

Set-VMHost -VirtualMachineMigrationAuthenticationType Kerberos
```

---

**TT-ADMIN05** - Run as domain administrator

```PowerShell
cls
```

### # Configure constrained delegation in Active Directory

#### # Configure constrained delegation for VM migration

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-KCD.ps1 `
    -TrustedComputer TT-HV06B `
    -TrustingComputer TT-HV06A `
    -ServiceType cifs `
    -Add

C:\NotBackedUp\Public\Toolbox\PowerShell\Set-KCD.ps1 `
    -TrustedComputer TT-HV06B `
    -TrustingComputer TT-HV06A `
    -ServiceType "Microsoft Virtual System Migration Service" `
    -Add

C:\NotBackedUp\Public\Toolbox\PowerShell\Set-KCD.ps1 `
    -TrustedComputer TT-HV06B `
    -TrustingComputer TT-HV06C `
    -ServiceType cifs `
    -Add

C:\NotBackedUp\Public\Toolbox\PowerShell\Set-KCD.ps1 `
    -TrustedComputer TT-HV06B `
    -TrustingComputer TT-HV06C `
    -ServiceType "Microsoft Virtual System Migration Service" `
    -Add

# Starting with Windows Server 2016, delegation must be configured to allow
# protocol transition (i.e. "Use any authentication protocol"). If the default
# "Use Kerberos only" configuration is used, VM migration fails with error
# 0x8009030E - "No credentials were available in the security package."
Set-ADAccountControl `
    -Identity TT-HV06B$ `
    -TrustedToAuthForDelegation $true
```

##### Reference

[Set up hosts for live migration without Failover Clustering](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/deploy/set-up-hosts-for-live-migration-without-failover-clustering#BKMK_Step1)

[Why Hyper-V Live Migrations Fail with 0x8009030E](https://techcommunity.microsoft.com/blog/coreinfrastructureandsecurityblog/why-hyper-v-live-migrations-fail-with-0x8009030e/2238446)

[Hyper-V – There was an error during move operation](https://evotec.xyz/hyper-v-error-move-operation/)

```PowerShell
cls
```

#### # Configure constrained delegation to mount ISO images to VMs

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-KCD.ps1 `
    -TrustedComputer TT-HV06B `
    -TrustingComputer TT-FS01 `
    -ServiceType cifs `
    -Add
```

---

## # Create and configure Hyper-V failover cluster

### # Run validation tests for failover cluster hardware and settings

#### # Review cluster validation report

### # Create failover cluster

### # Rename cluster disks

### # Configure cluster quorum

### # Add cluster shared volumes

### # Rename cluster shared volumes

### # Rename cluster networks

### # Isolate traffic on live migration network

```PowerShell
cls
```

### # Isolate SMB storage traffic

```PowerShell
New-SmbMultichannelConstraint `
    -ServerName "TT-HV06A" `
    -InterfaceAlias "Storage-10", "Storage-13" `
    -Confirm:$false

New-SmbMultichannelConstraint `
    -ServerName "TT-HV06C" `
    -InterfaceAlias "Storage-10", "Storage-13" `
    -Confirm:$false
```

```PowerShell
cls
```

### # Verify SMB Multichannel works as expected

```PowerShell
$source = "\\TT-HV06A\C$\NotBackedUp\Temp"
$destination = "C:\NotBackedUp\Temp"

robocopy $source $destination en-us_windows_server_2022_x64_dvd_620d7eac.iso
```

### # Add remaining node to failover cluster

```PowerShell
cls
```

## # Restore and configure virtual machines

### # Move virtual machine files to local storage on Hyper-V node

```PowerShell
@(
    "EXT-ADFS03B",
    "EXT-FOOBAR8",
    "EXT-VS2008-DEV1",
    "EXT-VS2012-DEV1",
    "EXT-VS2013-DEV1",
    "EXT-VS2015-DEV1",
    "EXT-VS2017-DEV1",
    "EXT-VS2017-DEV2",
    "EXT-VS2017-DEV3",
    "EXT-VS2019-DEV1",
    "EXT-WAP03B",
    "EXT-WEB03B",
    "K8S-01-CTRL-02",
    "K8S-01-NODE-02",
    "TT-SCOM01D",
    "TT-SP01",
    "TT-W7-TEST-04",
    "TT-W7-TEST-05",
    "TT-W7-TEST-06",
    "TT-W8-TEST-02",
    "TT-WIN10-DEV6",
    "TT-WIN7-TEST1",
    "TT-WIN7-TEST2",
    "TT-WIN7-TEST3",
    "TT-WIN8-TEST1") |
    foreach {
        $source = "\\TT-HV06C\E$\NotBackedUp\VMs\" + $_
        $destination = "E:\NotBackedUp\VMs\" + $_

        robocopy $source $destination /E /MOVE
    }
```

```PowerShell
cls
```

### # Import virtual machines from local storage

```PowerShell
@(
    "D:\NotBackedUp\VMs",
    "E:\NotBackedUp\VMs",
    "F:\NotBackedUp\VMs"
) |
    foreach {
        Get-ChildItem $_ |
            foreach {
                $vmName = $_.Name

                Write-Verbose "vmName: $vmName"

                if ((Get-VM $vmName -ErrorAction SilentlyContinue) -eq $null) {
                    Get-ChildItem -Recurse -Path $_.FullName -Filter *.vmcx |
                        where { $_.FullName -notlike "*\Snapshots\*" } |
                        foreach {
                            $vmPath = $_.FullName

                            Write-Verbose "vmPath: $vmPath"

                            Import-VM -Path $vmPath
                        }
                }
            }
    }
```

```PowerShell
cls
```

### # Import high availability VMs from shared storage

### # Configure anti-affinity for high availability VMs

### # Configure preferred owners for high availability VMs

### # Configure failover properties

```PowerShell
cls
```

## # Test failover of Hyper-V cluster nodes

### # Pause Hyper-V cluster node and drain roles

```PowerShell
Suspend-ClusterNode -Drain -Wait
```

### # Pause running VMs

```PowerShell
Get-VM | where { $_.State -eq "Running" } | Suspend-VM
```

### # Reboot Hyper-V cluster node

```PowerShell
Restart-Computer
```

> **Note**
>
> Wait for the computer to restart and then login using a fabric administrator account.

### # Resume paused VMs

```PowerShell
Get-VM | where { $_.State -eq "Paused" } | Resume-VM
```

### # Resume Hyper-V cluster node and fail roles back

```PowerShell
Resume-ClusterNode -Failback Immediate
```

**TODO:**

```PowerShell
cls
```

## # Enter product key and activate Windows

```PowerShell
slmgr /ipk {product key}
```

> **Note**
>
> When notified that the product key was set successfully, click **OK**.

```Console
slmgr /ato
```

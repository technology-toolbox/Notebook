# TT-HV05A

Thursday, March 8, 2018
5:20 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

---

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create failover cluster objects in Active Directory

#### # Create cluster object for Hyper-V failover cluster and delegate permission to create the cluster to any member of the fabric administrators group

```PowerShell
$failoverClusterName = "TT-HV05-FC"
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

### Install latest patches using Windows Update

```Console
sconfig
```

### Rename computer and join domain

```Console
sconfig
```

> **Note**
>
> Join the **corp.technologytoolbox.com** domain and rename the computer to **TT-HV05A**.

---

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Move computer to "Hyper-V Servers" OU

```PowerShell
$computerName = "TT-HV05A"
$targetPath = ("OU=Hyper-V Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com")
```

### # Add computer to "Hyper-V Servers" domain group

```PowerShell
Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath

Import-Module ActiveDirectory
Add-ADGroupMember -Identity "Hyper-V Servers" -Members TT-HV05A$
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

robocopy $source $destination  /E /XD "Microsoft SDKs" /NP
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
    Rename-NetAdapter -NewName "Storage-10"

Get-NetAdapter `
    -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter #2" |
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
<p>1</p>
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
<tr>
<td valign='top'>
<p>2</p>
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
<p>3</p>
</td>
<td valign='top'>
<p>Model: Samsung SSD 850<br />
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
<p>4</p>
</td>
<td valign='top'>
<p>Model: Samsung SSD 850<br />
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
<p>5</p>
</td>
<td valign='top'>
<p>Model: Samsung SSD 850<br />
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
<p>6</p>
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
</table>

```PowerShell
Get-PhysicalDisk | sort DeviceId

Get-PhysicalDisk | select DeviceId, Model, SerialNumber, CanPool | sort DeviceId
```

#### Update storage drivers

##### Before

![(screenshot)](https://assets.technologytoolbox.com/screenshots/24/A89D23593EE79DDB588A153E1525AB72FE7AF624.png)

Screen clipping taken: 3/7/2018 7:53 AM

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B2/54967F6379AA0D5D9B84F1E87A01B1A99872C5B2.png)

Screen clipping taken: 3/7/2018 7:53 AM

##### Update AHCI drivers

1. Download the latest AHCI drivers from the Intel website:\
   **Intel® RSTe AHCI & SCU Software RAID Driver for Windows**\
   From <[https://downloadcenter.intel.com/download/27308/Intel-RSTe-AHCI-SCU-Software-RAID-Driver-for-Windows-?v=t](https://downloadcenter.intel.com/download/27308/Intel-RSTe-AHCI-SCU-Software-RAID-Driver-for-Windows-?v=t)>
2. Extract the drivers (**[\\\\TT-FS01\\Public\\Download\\Drivers\\Intel\\RSTe](\\TT-FS01\Public\Download\Drivers\Intel\RSTe) AHCI & SCU Software RAID driver for Windows**) and copy the files to a temporary location on the server:
3. Install the drivers for the **Intel(R) C600+/C220+ series chipset SATA AHCI Controller (PCI\\VEN_8086&DEV_8D02&...)**:
4. Install the drivers for the **Intel(R) C600+/C220+ series chipset sSATA AHCI Controller (PCI\\VEN_8086&DEV_8D62&...)**:
5. Install the drivers for the **Intel(R) C600+/C220+ series chipset SATA RAID Controller (PCI\\VEN_8086&DEV_8D62&...)**:
6. Install the drivers for the **Intel(R) C600+/C220+ series chipset sSATA RAID Controller (PCI\\VEN_8086&DEV_8D62&...)**:
7. Restart the server.

```PowerShell
    $source = "\\TT-FS01\Public\Download\Drivers\Intel" `
```

    + "\\RSTe AHCI & SCU Software RAID driver for Windows\\Drivers\\x64" `\
    + "\\AHCI\\Win8_Win10_2K12_2K16"

```PowerShell
    $destination = "C:\NotBackedUp\Temp\Drivers\Intel\x64" `
```

    + "\\AHCI\\Win8_Win10_2K12_2K16"

```Console
    robocopy $source $destination /E
```

```Console
    pnputil -i -a "$destination\iaAHCI.inf"
```

```Console
    pnputil -i -a "$destination\iaAHCIB.inf"
```

```Console
    pnputil -i -a "$destination\iaStorA.inf"
```

```Console
    pnputil -i -a "$destination\iaStorB.inf"
```

##### After

![(screenshot)](https://assets.technologytoolbox.com/screenshots/08/D0FFD390B93EDA82DE325AA0DE6797A75FE68B08.png)

Screen clipping taken: 3/7/2018 8:17 AM

![(screenshot)](https://assets.technologytoolbox.com/screenshots/93/814B2F9032F22EB1A9A24FA56E632B0F116E9393.png)

Screen clipping taken: 3/7/2018 8:18 AM

```PowerShell
cls
```

### # Benchmark storage performance

```PowerShell
Get-PhysicalDisk -CanPool $true |
    select DeviceId, Model, SerialNumber |
    sort Model

DeviceId Model            SerialNumber
-------- -----            ------------
1        Samsung SSD 850  *********09894X
0        Samsung SSD 850  *********12260P
6        ST2000NM0033-9ZM *****0FT
3        ST2000NM0033-9ZM *****34P
4        WDC WD3000F9YZ-0 WD-******357156
5        WDC WD3000F9YZ-0 WD-******FV469C
```

```PowerShell
cls
```

#### # Create temporary partitions and volumes

```PowerShell
$physicalDrives = @(
    [PSCustomObject] @{ DiskNumber = 1; DriveLetter = "D"; Label = "Samsung SSD 850" },
    [PSCustomObject] @{ DiskNumber = 0; DriveLetter = "E"; Label = "Samsung SSD 850" },
    [PSCustomObject] @{ DiskNumber = 6; DriveLetter = "F"; Label = "ST2000NM0033-9ZM" },
    [PSCustomObject] @{ DiskNumber = 3; DriveLetter = "G"; Label = "ST2000NM0033-9ZM" },
    [PSCustomObject] @{ DiskNumber = 4; DriveLetter = "H"; Label = "WDC WD3000F9YZ-0" },
    [PSCustomObject] @{ DiskNumber = 5; DriveLetter = "I"; Label = "WDC WD3000F9YZ-0" }
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

#### # Benchmark performance of individual drives

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\ATTO Disk Benchmark\Bench32.exe'
```

##### C: (SSD - Samsung 850 Pro 128GB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9F/D1FA616824CAAA8E4E60AD530DCB500138FD3C9F.png)

_D: (Samsung SSD 850 512GB)_

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7E/C561B53DD2FEB31306215577F0EDC34F0ECC907E.png)

_E: (Samsung SSD 850 512GB)_

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CA/43F9CEC14A35E90C16B1D200C8B039CCE703D6CA.png)

_F: (ST2000NM0033-9ZM)_

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A9/2F2CEE0AFB369FB57288C860E00C4DED4C8E53A9.png)

_G: (ST2000NM0033-9ZM)_

![(screenshot)](https://assets.technologytoolbox.com/screenshots/29/AFF3D2E298003ECD3CA1FE28CAFA2A51CDA35029.png)

_H: (WDC WD3000F9YZ-0)_

![(screenshot)](https://assets.technologytoolbox.com/screenshots/39/5AB3C4FE23C616258EF59BC929D6090F8482F239.png)

_I: (WDC WD3000F9YZ-0)_

![(screenshot)](https://assets.technologytoolbox.com/screenshots/15/A1C1CDB7FA49300FECFCD5433B68CDDD06C80615.png)

```PowerShell
cls
```

#### # Clear physical disks

```PowerShell
Get-PhysicalDisk |
    where { $_.SerialNumber -ne "*********03852K" } |
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

#### # Create storage pool

```PowerShell
$storageSubSystemName = "Windows Storage on $env:COMPUTERNAME"

$storageSubSystemUniqueId = `
    Get-StorageSubSystem -FriendlyName $storageSubSystemName |
    select -ExpandProperty UniqueId

$physicalDisks = @(
    (Get-PhysicalDisk -SerialNumber *****0FT),
    (Get-PhysicalDisk -SerialNumber *****34P),
    (Get-PhysicalDisk -SerialNumber WD-******357156),
    (Get-PhysicalDisk -SerialNumber WD-******FV469C),
    (Get-PhysicalDisk -SerialNumber *********12260P),
    (Get-PhysicalDisk -SerialNumber *********09894X)
)

New-StoragePool `
    -FriendlyName Pool-01 `
    -StorageSubSystemUniqueId $storageSubSystemUniqueId `
    -PhysicalDisks $physicalDisks
```

#### # Check media type configuration

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

#### # Create storage tiers

```PowerShell
$storagePool |
    New-StorageTier -FriendlyName "Performance" -MediaType SSD

$storagePool |
    New-StorageTier -FriendlyName "Capacity" -MediaType HDD
```

#### # Create storage spaces

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
        -StorageTierSizes 250GB,2250GB `
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

#### # Create partitions and volumes

##### # Create volume "D" on Gold-01

```PowerShell
$virtualDiskName = "Gold-01"
$driveLetter = "D"
$fileSystem = "ReFS"

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

##### # Create volume "E" on Silver-01

```PowerShell
$virtualDiskName = "Silver-01"
$driveLetter = "E"
$fileSystem = "NTFS"
```

> **Important**
>
> When using storage tiers, format the volume using NTFS (not ReFS). Otherwise, an error occurs when optimizing the storage tiers:\
> The operation requested is not supported by the hardware backing the volume. (0x8900002A)\
> Refer to the following resources for more information:\
> **Resilient File System (ReFS) overview**\
> From <[https://docs.microsoft.com/en-us/windows-server/storage/refs/refs-overview](https://docs.microsoft.com/en-us/windows-server/storage/refs/refs-overview)>
>
> The following features are unavailable on ReFS at this time:
>
> | **Functionality**  | **ReFS** | **NTFS** |
> | ------------------ | -------- | -------- |
> | ...                  | ...        | ...        |
> | NTFS storage tiers | No       | Yes      |
>
>
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

##### # Create volume "F" on Bronze-01

```PowerShell
$virtualDiskName = "Bronze-01"
$driveLetter = "F"
$fileSystem = "ReFS"

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

##### D: (Mirror SSD storage space - 2x Samsung 850 Pro 512GB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/06/4A9A0F5B93DD9DD461BBAACAEEE207D9E8F42606.png)

##### E: (Mirror SSD/HDD storage space)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3E/B86F678436ADD9FBBC5AF3F5FFC018425E58833E.png)

##### F: (Mirror HDD storage space)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/26/24541DC85BB305F58FC08D9D26CC6D14CD065426.png)

## Prepare infrastructure for Hyper-V installation

### Enable Virtualization in BIOS

Intel Virtualization Technology: **Enabled**

```PowerShell
cls
```

### # Add roles for Hyper-V cluster

```PowerShell
Install-WindowsFeature `
    -Name Failover-Clustering, Hyper-V, Multipath-IO `
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

### # TODO: Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

```PowerShell
cls
```

### # Create and configure failover cluster

#### # Run cluster validation tests

```PowerShell
Test-Cluster -Node TT-HV05A, TT-HV05B
```

> **Note**
>
> Wait for the cluster validation tests to complete.

#### # Review cluster validation report

```PowerShell
$source = "$env:TEMP\Validation Report 2018.03.08 At 10.06.30.htm"
$destination = "\\TT-FS01\Public"

Copy-Item $source $destination
```

---

**WOLVERINE**

```PowerShell
& "\\TT-FS01\Public\Validation Report 2018.03.08 At 10.06.30.htm"
```

---

```PowerShell
cls
```

#### # Create cluster

```PowerShell
New-Cluster -Name TT-HV05-FC -Node TT-HV05A, TT-HV05B -NoStorage

WARNING: There were issues while creating the clustered role that may prevent it from starting. For more information view the report file below.
WARNING: Report file location: C:\Windows\cluster\Reports\Create Cluster Wizard TT-HV05-FC on 2018.03.08 At 10.09.29.htm

Name
----
TT-HV05-FC
```

#### # Review cluster creation report

```PowerShell
$source = "C:\Windows\cluster\Reports" `
```

    + "\\Create Cluster Wizard TT-HV05-FC on 2018.03.08 At 10.09.29.htm"

```PowerShell
$destination = "\\TT-FS01\Public"

Copy-Item $source $destination
```

---

**WOLVERINE**

```PowerShell
& "\\TT-FS01\Public\Create Cluster Wizard TT-HV05-FC on 2018.03.08 At 10.09.29.htm"
```

---

> **Note**
>
> The cluster creation report contains the following warning:
>
> - **An appropriate disk was not found for configuring a disk witness. The cluster is not configured with a witness. As a best practice, configure a witness to help achieve the highest availability of the cluster. If this cluster does not have shared storage, configure a File Share Witness or a Cloud Witness.**

#### Configure cluster quorum

---

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

##### # Configure file share for cluster quorum witness

```PowerShell
Enter-PSSession TT-FS01
```

---

**TT-FS01**

###### # Create folder for specific failover cluster (TT-HV05-FC)

```PowerShell
$path = "D:\Shares\Witness`$\TT-HV05-FC"

New-Item -Path $path -ItemType Directory
```

###### # Grant permissions for failover cluster service

```PowerShell
icacls $path /grant 'TT-HV05-FC$:(OI)(CI)(F)'

exit
```

---

```PowerShell
cls
```

##### # Set file share as cluster quorum witness

```PowerShell
Set-ClusterQuorum `
    -Cluster TT-HV05-FC `
    -NodeAndFileShareMajority \\TT-FS01\Witness$\TT-HV05-FC
```

---

### Import Hyper-V hosts into VMM

---

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

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

@("TT-HV05A", "TT-HV05B") |
    ForEach-Object {
        Invoke-Command -ComputerName $_ -ScriptBlock $scriptBlock
    }
```

---

---

**TT-VMM01A - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Add Hyper-V compute cluster to VMM

```PowerShell
$runAsAccount = Get-SCRunAsAccount `
    -Name "Service account for VMM - Management (TT-VMM01)"

$hostGroup = Get-SCVMHostGroup -Name Compute

Add-SCVMHostCluster `
    -Name "TT-HV05-FC.corp.technologytoolbox.com" `
    -VMHostGroup $hostGroup `
    -Credential $runAsAccount
```

```PowerShell
cls
```

### # Add logical switches in VMM

#### # Add logical switch - "Embedded Team Switch"

```PowerShell
$computerName = "TT-HV05A.corp.technologytoolbox.com"

$vmHost = Get-SCVMHost -ComputerName $computerName

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

#### Replace storage virtual network adapters with physical network adapters

> **Note**
>
> When using virtual network adapters, SMB Multichannel worked but throughput was substantially below 1 Gpbs on each network adapter. I believe this is due to RSS not being used on the virtual network adapters (even though this is enabled in the corresponding port classification). This speculation is based on the following:
>
> ```PowerShell
> Get-VMNetworkAdapter -ManagementOS |
>     select Name, VrssEnabled, VrssEnabledRequested,
>     VmmqQueuePairs, VmmqQueuePairsRequested
>
> Name                    : ...
> VrssEnabled             : False
> VrssEnabledRequested    : True
> VmmqQueuePairs          : 0
> VmmqQueuePairsRequested : 16
>
> Get-NetAdapter -Physical -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter" |
>     Get-NetAdapterAdvancedProperty -DisplayName "Maximum Number of RSS Queues" |
>     select DisplayValue, RegistryKeyword, RegistryValue
>
> DisplayValue RegistryKeyword RegistryValue
> ------------ --------------- -------------
> 2 Queues     *NumRssQueues   {2}
> ```

##### # Remove storage virtual network adapters

```PowerShell
Get-SCVirtualNetworkAdapter -VMHost $vmHost |
    ? { $_.Name -in $("Storage 1", "Storage 2") } |
    Remove-SCVirtualNetworkAdapter
```

##### # Associate storage network adapters with corresponding VLANs in logical switch

```PowerShell
$logicalNetwork = Get-SCLogicalNetwork -Name "Datacenter"

$networkAdapter = Get-SCVMHostNetworkAdapter `
    -VMHost $vmHost `
    -Name "Intel(R) Gigabit CT Desktop Adapter"

$subnets = @()
$subnets += New-SCSubnetVLan -VLanID 10 -Subnet "10.1.10.0/24"

Set-SCVMHostNetworkAdapter `
    -VMHostNetworkAdapter $networkAdapter `
    -AddOrSetLogicalNetwork $logicalNetwork `
    -SubnetVLan $subnets

$networkAdapter = Get-SCVMHostNetworkAdapter `
    -VMHost $vmHost `
    -Name "Intel(R) Gigabit CT Desktop Adapter #2"

$subnets = @()
$subnets += New-SCSubnetVLan -VLanID 13 -Subnet "10.1.13.0/24"

Set-SCVMHostNetworkAdapter `
    -VMHostNetworkAdapter $networkAdapter `
    -AddOrSetLogicalNetwork $logicalNetwork `
    -SubnetVLan $subnets
```

---

```PowerShell
cls
```

#### # Configure static IP addresses on "Storage-10" network

```PowerShell
$interfaceAlias = "Storage-10"
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
$ipAddress = "10.1.10.2"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -DefaultGateway 10.1.10.1 `
    -PrefixLength 24
```

##### # Configure IPv4 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 192.168.10.103, 192.168.10.104
```

#### # Configure static IP addresses on "Storage-13" network

```PowerShell
$interfaceAlias = "Storage-13"
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
$ipAddress = "10.1.13.2"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -DefaultGateway 10.1.13.1 `
    -PrefixLength 24
```

##### # Configure IPv4 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 192.168.10.103, 192.168.10.104
```

```PowerShell
cls
```

### # Enable jumbo frames on virtual switches

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*" |
    sort Name |
    select Name, DisplayValue

Name                             DisplayValue
----                             ------------
Storage-10                       9014 Bytes
Storage-13                       9014 Bytes
Team 1A                          9014 Bytes
Team 1B                          9014 Bytes
vEthernet (Cluster)              Disabled
vEthernet (Embedded Team Switch) Disabled
vEthernet (Live Migration)       Disabled

Get-NetAdapter |
    ? { $_.Name -like 'vEthernet*' } |
    % {
        Set-NetAdapterAdvancedProperty `
            -Name $_.Name `
            -DisplayName "Jumbo Packet" -RegistryValue 9014
    }

Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*" |
    sort Name |
    select Name, DisplayValue

Name                             DisplayValue
----                             ------------
Storage-10                       9014 Bytes
Storage-13                       9014 Bytes
Team 1A                          9014 Bytes
Team 1B                          9014 Bytes
vEthernet (Cluster)              9014 Bytes
vEthernet (Embedded Team Switch) 9014 Bytes
vEthernet (Live Migration)       9014 Bytes

ping TT-FS01 -f -l 8900
```

```PowerShell
cls
```

### # Verify SMB Multichannel is working as expected

```PowerShell
$source = "C:\NotBackedUp\Products"
$destination = "\\TT-HV05B\C`$\NotBackedUp\Products"
$filter = "en_windows_server_2016_updated_feb_2018_x64_dvd_11636692.iso"

robocopy $source $destination $filter /E /NP
```

```PowerShell
cls
```

## # Install and configure DPM agent

### # Install DPM agent

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
$productionServer = 'TT-HV05A'

.\Attach-ProductionServer.ps1 `
    -DPMServerName TT-DPM02 `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `
    -UserName jjameson-admin
```

---

```PowerShell
cls
```

## # Configure monitoring using System Center Operations Manager

### # Install SCOM agent

```PowerShell
$msiPath = "\\TT-FS01\Products\Microsoft\System Center 2016\SCOM\Agent\AMD64" `
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

## Configure shared storage

### Configure iSCSI client

#### Reference

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

#### # Configure MPIO settings

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

### Login as fabric administrator account

```Console
PowerShell
```

#### # Get iSCSI initiator name

```PowerShell
(Get-InitiatorPort).NodeAddress

iqn.1991-05.com.microsoft:tt-hv05a.corp.technologytoolbox.com
```

#### # Connect to iSCSI portal (using multiple paths)

```PowerShell
New-IscsiTargetPortal `
    -TargetPortalAddress 10.1.10.5 `
    -InitiatorPortalAddress 10.1.10.2

New-IscsiTargetPortal `
    -TargetPortalAddress 10.1.13.5 `
    -InitiatorPortalAddress 10.1.13.2

Start-Sleep 30
```

#### # Connect first path to iSCSI target

```PowerShell
Connect-IscsiTarget `
    -NodeAddress "iqn.2005-10.org.freenas.ctl:tt-hv05-fc" `
    -TargetPortalAddress 10.1.10.5 `
    -InitiatorPortalAddress 10.1.10.2 `
    -IsMultipathEnabled $true `
    -IsPersistent $true
```

#### # Connect additional paths to iSCSI target

```PowerShell
Connect-IscsiTarget `
    -NodeAddress "iqn.2005-10.org.freenas.ctl:tt-hv05-fc" `
    -TargetPortalAddress 10.1.13.5 `
    -InitiatorPortalAddress 10.1.13.2 `
    -IsMultipathEnabled $true `
    -IsPersistent $true
```

```PowerShell
cls
```

#### # Online and initialize disks

```PowerShell
$iscsiDisks = Get-Disk | ? { $_.BusType -eq "iSCSI" }

$iscsiDisks |
    % {
        $disk = $_

        If ($disk.IsOffline -eq $true) {
            Set-Disk -Number $disk.Number -IsOffline $false
        }

        If ($disk.PartitionStyle -eq 'RAW') {
            Initialize-Disk -Number $disk.Number -PartitionStyle GPT -PassThru |
                New-Partition -UseMaximumSize |
                Format-Volume `
                    -FileSystem ReFS `
                    -Confirm:$false
        }
    }
```

```PowerShell
cls
```

#### # Set file system labels for iSCSI disks

```PowerShell
Get-Disk -SerialNumber 6805ca3f1f4a00 |
    Get-Partition |
    Get-Volume |
    Set-Volume -NewFileSystemLabel iscsi01-Gold-01

Get-Disk -SerialNumber 6805ca3f1f4a01 |
    Get-Partition |
    Get-Volume |
    Set-Volume -NewFileSystemLabel iscsi01-Gold-02

Get-Disk -SerialNumber 6805ca3f1f4a02 |
    Get-Partition |
    Get-Volume |
    Set-Volume -NewFileSystemLabel iscsi01-Bronze-01A

Get-Disk -SerialNumber 6805ca3f1f4a03 |
    Get-Partition |
    Get-Volume |
    Set-Volume -NewFileSystemLabel iscsi01-Bronze-01B

Get-Disk -SerialNumber 6805ca3f1f4a04 |
    Get-Partition |
    Get-Volume |
    Set-Volume -NewFileSystemLabel iscsi01-Bronze-02A

Get-Disk -SerialNumber 6805ca3f1f4a05 |
    Get-Partition |
    Get-Volume |
    Set-Volume -NewFileSystemLabel iscsi01-Bronze-02B
```

```PowerShell
cls
```

### # Benchmark shared storage performance

#### # Create temporary partitions and volumes

```PowerShell
Get-Volume -FileSystemLabel iscsi01-Gold-01 |
```

    Get-Partition |\
    Set-Partition -NewDriveLetter G

```PowerShell
Get-Volume -FileSystemLabel iscsi01-Gold-02 |
```

    Get-Partition |\
    Set-Partition -NewDriveLetter H

```PowerShell
Get-Volume -FileSystemLabel iscsi01-Bronze-01A |
```

    Get-Partition |\
    Set-Partition -NewDriveLetter I

```PowerShell
Get-Volume -FileSystemLabel iscsi01-Bronze-01B |
```

    Get-Partition |\
    Set-Partition -NewDriveLetter J

```PowerShell
Get-Volume -FileSystemLabel iscsi01-Bronze-02A |
```

    Get-Partition |\
    Set-Partition -NewDriveLetter K

```PowerShell
Get-Volume -FileSystemLabel iscsi01-Bronze-02B |
```

    Get-Partition |\
    Set-Partition -NewDriveLetter L

```PowerShell
cls
```

#### # Benchmark performance of individual drives

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\ATTO Disk Benchmark\Bench32.exe'
```

##### G: - iscsi01-Gold-01 (SSD - Samsung 850 Pro 512GB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/15/DB35AB739E1370F213C265C4C6F9B00F4F487E15.png)

##### H: - iscsi01-Gold-02 (SSD - Samsung 850 Pro 512GB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CF/9DFAFCFFC15C6557191D146FE767C468020D7FCF.png)

##### I: - iscsi01-Bronze-01A (HDD - ST2000DM001-1CH164)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B0/49E255EA48DCE15715C8776D46F90648E3019AB0.png)

##### J: - iscsi01-Bronze-01B (HDD - ST2000DM001-1CH164)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BC/1A1A05019DC0D5403E3127F40BDB1B83B9A971BC.png)

##### K: - iscsi01-Bronze-02A (HDD - ST3000DM008-2DM166)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/23/DB38ADF34DF95BCFED5DF6ABBD1FBC7D43807F23.png)

##### L: - iscsi01-Bronze-02B (HDD - ST3000DM008-2DM166)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/51/04354D373732F336DE9020D2C6E373EF43F55B51.png)

```PowerShell
cls
```

#### # Clear physical disks

```PowerShell
Get-PhysicalDisk |
    where { $_.BusType -eq "iSCSI" } |
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

### # Configure cluster shared volumes

#### # Run cluster validation tests

```PowerShell
$sharedDisks = @(
    (Get-Disk -SerialNumber 6805ca3f1f4a00),
    (Get-Disk -SerialNumber 6805ca3f1f4a01),
    (Get-Disk -SerialNumber 6805ca3f1f4a02),
    (Get-Disk -SerialNumber 6805ca3f1f4a03),
    (Get-Disk -SerialNumber 6805ca3f1f4a04),
    (Get-Disk -SerialNumber 6805ca3f1f4a05)
)

Test-Cluster -Include "List Disks" -Disk $sharedDisks
```

> **Note**
>
> Wait for the cluster validation tests to complete.

#### # Review cluster validation report

```PowerShell
$source = "$env:TEMP\Validation Report 2018.03.15 At 15.36.19.htm"
$destination = "\\TT-FS01\Public"

Copy-Item $source $destination
```

---

**WOLVERINE**

```PowerShell
& "\\TT-FS01\Public\Validation Report 2018.03.15 At 15.36.19.htm"
```

---

```PowerShell
cls
```

#### # Format iSCSI disks

```PowerShell
Get-PhysicalDisk |
    where { $_.BusType -eq "iSCSI" } |
    foreach {
        $physicalDisk = $_

        $disk = Get-Disk -UniqueId $physicalDisk.UniqueId

        $disk | Set-Disk -IsOffline $false

        $disk |
            where { $_.PartitionStyle -ne "RAW" } |
            Clear-Disk -RemoveData -RemoveOEM -Confirm:$false -Verbose

        Initialize-Disk -InputObject $disk -PartitionStyle GPT -PassThru |
            New-Partition -UseMaximumSize |
            Format-Volume -FileSystem ReFS -Confirm:$false |
            Out-Null
    }

Update-StorageProviderCache -DiscoveryLevel Full
```

```PowerShell
cls
```

#### # Set file system labels for iSCSI disks

```PowerShell
Get-PhysicalDisk -SerialNumber 6805ca3f1f4a00 |
    Set-PhysicalDisk -NewFriendlyName iscsi01-Gold-01
```

```PowerShell
cls
```

#### # Set file system labels for iSCSI disks

```PowerShell
Get-Disk -SerialNumber 6805ca3f1f4a00 |
    Get-Partition |
    Get-Volume |
    Set-Volume -NewFileSystemLabel iscsi01-Gold-01

Get-Disk -SerialNumber 6805ca3f1f4a01 |
    Get-Partition |
    Get-Volume |
    Set-Volume -NewFileSystemLabel iscsi01-Gold-02

Get-Disk -SerialNumber 6805ca3f1f4a02 |
    Get-Partition |
    Get-Volume |
    Set-Volume -NewFileSystemLabel iscsi01-Bronze-01A

Get-Disk -SerialNumber 6805ca3f1f4a03 |
    Get-Partition |
    Get-Volume |
    Set-Volume -NewFileSystemLabel iscsi01-Bronze-01B

Get-Disk -SerialNumber 6805ca3f1f4a04 |
    Get-Partition |
    Get-Volume |
    Set-Volume -NewFileSystemLabel iscsi01-Bronze-02A

Get-Disk -SerialNumber 6805ca3f1f4a05 |
    Get-Partition |
    Get-Volume |
    Set-Volume -NewFileSystemLabel iscsi01-Bronze-02B
```

```PowerShell
cls
```

#### # Add cluster disks for CSV

```PowerShell
Get-ClusterAvailableDisk | Add-ClusterDisk
```

#### # Configure cluster shared volumes

```PowerShell
Add-ClusterSharedVolume -Name "Cluster Disk 1"
Add-ClusterSharedVolume -Name "Cluster Disk 2"
Add-ClusterSharedVolume -Name "Cluster Disk 3"
Add-ClusterSharedVolume -Name "Cluster Disk 4"
Add-ClusterSharedVolume -Name "Cluster Disk 5"
Add-ClusterSharedVolume -Name "Cluster Disk 6"

Get-ClusterSharedVolume |
    foreach {
        $csv = $_

        $diskGuid = $csv |
            Get-ClusterParameter |
            where { $_.Name -eq "DiskGuid" } |
            select -ExpandProperty Value

        $physicalDisk = Get-PhysicalDisk -ObjectId "*$diskGuid*"

        $disk = Get-Disk -UniqueId $physicalDisk.UniqueId

        $volume = $disk | Get-Partition | Get-Volume

        Write-Host ("$($csv.Name) - $($physicalDisk.SerialNumber)" `
            + " - $($volume.FileSystemLabel)")

        $csv.Name = $volume.FileSystemLabel
    }

Cluster Disk 1 - 6805ca3f1f4a03 - iscsi01-Bronze-01B
Cluster Disk 2 - 6805ca3f1f4a01 - iscsi01-Gold-02
Cluster Disk 3 - 6805ca3f1f4a00 - iscsi01-Gold-01
Cluster Disk 4 - 6805ca3f1f4a05 - iscsi01-Bronze-02B
Cluster Disk 5 - 6805ca3f1f4a02 - iscsi01-Bronze-01A
Cluster Disk 6 - 6805ca3f1f4a04 - iscsi01-Bronze-02A


Push-Location C:\ClusterStorage

Move-Item Volume1 iscsi01-Bronze-01B
Move-Item Volume2 iscsi01-Gold-02
Move-Item Volume3 iscsi01-Gold-01
Move-Item Volume4 iscsi01-Bronze-02B
Move-Item Volume5 iscsi01-Bronze-01A
Move-Item Volume6 iscsi01-Bronze-02A

Pop-Location
```

---

**FOOBAR11**

```PowerShell
cls
```

## # Make virtual machine highly available

```PowerShell
$vm = Get-SCVirtualMachine -Name TT-WSUS02
$vmHost = $vm.VMHost

Move-SCVirtualMachine `
    -VM $vm `
    -VMHost $vmHost `
    -HighlyAvailable $true `
    -Path "C:\ClusterStorage\iscsi01-Bronze-01A" `
    -UseDiffDiskOptimization
```

---

## Configure additional shared storage

### Login as fabric administrator account

```Console
PowerShell
```

#### # Connect to iSCSI portal (using multiple paths)

```PowerShell
New-IscsiTargetPortal `
    -TargetPortalAddress 10.1.10.6 `
    -InitiatorPortalAddress 10.1.10.2

New-IscsiTargetPortal `
    -TargetPortalAddress 10.1.13.6 `
    -InitiatorPortalAddress 10.1.13.2

Start-Sleep 30
```

#### # Connect first path to iSCSI target

```PowerShell
Connect-IscsiTarget `
    -NodeAddress "iqn.2005-10.org.freenas.ctl:tt-hv05-fc" `
    -TargetPortalAddress 10.1.10.6 `
    -InitiatorPortalAddress 10.1.10.2 `
    -IsMultipathEnabled $true `
    -IsPersistent $true
```

#### # Connect additional paths to iSCSI target

```PowerShell
Connect-IscsiTarget `
    -NodeAddress "iqn.2005-10.org.freenas.ctl:tt-hv05-fc" `
    -TargetPortalAddress 10.1.13.6 `
    -InitiatorPortalAddress 10.1.13.2 `
    -IsMultipathEnabled $true `
    -IsPersistent $true
```

```PowerShell
cls
```

#### # Online and initialize disks

```PowerShell
$iscsiDisks = Get-Disk | ? { $_.BusType -eq "iSCSI" }

$iscsiDisks |
    % {
        $disk = $_

        If ($disk.IsOffline -eq $true) {
            Set-Disk -Number $disk.Number -IsOffline $false
        }

        If ($disk.PartitionStyle -eq 'RAW') {
            Initialize-Disk -Number $disk.Number -PartitionStyle GPT -PassThru |
                New-Partition -UseMaximumSize |
                Format-Volume `
                    -FileSystem ReFS `
                    -Confirm:$false
        }
    }
```

```PowerShell
cls
```

#### # Set file system labels for iSCSI disks

```PowerShell
Get-Disk -SerialNumber 6805ca19133200 |
    Get-Partition |
    Get-Volume |
    Set-Volume -NewFileSystemLabel iscsi02-Silver-01

Get-Disk -SerialNumber 6805ca19133201 |
    Get-Partition |
    Get-Volume |
    Set-Volume -NewFileSystemLabel iscsi02-Silver-02

Get-Disk -SerialNumber 6805ca19133202 |
    Get-Partition |
    Get-Volume |
    Set-Volume -NewFileSystemLabel iscsi02-Silver-03
```

```PowerShell
cls
```

### # Benchmark shared storage performance

#### # Create temporary partitions and volumes

```PowerShell
Get-Volume -FileSystemLabel iscsi02-Silver-01 |
    Get-Partition |
    Set-Partition -NewDriveLetter G

Get-Volume -FileSystemLabel iscsi02-Silver-02 |
    Get-Partition |
    Set-Partition -NewDriveLetter H

Get-Volume -FileSystemLabel iscsi02-Silver-03 |
    Get-Partition |
    Set-Partition -NewDriveLetter I
```

```PowerShell
cls
```

#### # Benchmark performance of iSCSI volumes on TT-NAS02

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\ATTO Disk Benchmark\Bench32.exe'
```

##### G: - iscsi02-Silver-01 (Seagate 4 TB IronWolf Pro x4 + Intel 280 GB Optane 900 SLOG)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6D/85BCAC0073481F7A1D920DB47C5F664C59646B6D.png)

##### H: - iscsi02-Silver-02 (Seagate 4 TB IronWolf Pro x4 + Intel 280 GB Optane 900 SLOG)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3C/911E2FB1B17E2173A9D8228A022A8ABB15E06D3C.png)

##### I: - iscsi02-Silver-03 (Seagate 4 TB IronWolf Pro x4 + Intel 280 GB Optane 900 SLOG)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B9/A6FBA0F21F530ACC0F744F93AB8F52BFA27557B9.png)

```PowerShell
cls
```

#### # Clear physical disks

```PowerShell
Get-PhysicalDisk |
    where { $_.BusType -eq "iSCSI" } |
    where { $_.SerialNumber -in (
        "6805ca19133200", "6805ca19133201", "6805ca19133202") } |
    foreach {
        $physicalDisk = $_

        $disk = Get-Disk -UniqueId $physicalDisk.UniqueId

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

### # Configure cluster shared volumes

#### # Run cluster validation tests

```PowerShell
$sharedDisks = @(
    (Get-Disk -SerialNumber 6805ca19133200),
    (Get-Disk -SerialNumber 6805ca19133201),
    (Get-Disk -SerialNumber 6805ca19133202))

Test-Cluster -Include "List Disks" -Disk $sharedDisks
```

> **Note**
>
> Wait for the cluster validation tests to complete.

#### # Review cluster validation report

```PowerShell
$source = "$env:TEMP\Validation Report 2018.03.31 At 05.11.40.htm"
$destination = "\\TT-FS01\Public"

Copy-Item $source $destination
```

---

**WOLVERINE**

```PowerShell
& "\\TT-FS01\Public\Validation Report 2018.03.31 At 05.11.40.htm"
```

---

```PowerShell
cls
```

#### # Format iSCSI disks

```PowerShell
Get-PhysicalDisk |
    where { $_.BusType -eq "iSCSI" } |
    where { $_.SerialNumber -in (
        "6805ca19133200", "6805ca19133201", "6805ca19133202") } |
    foreach {
        $physicalDisk = $_

        $disk = Get-Disk -UniqueId $physicalDisk.UniqueId

        $disk | Set-Disk -IsOffline $false

        $disk |
            where { $_.PartitionStyle -ne "RAW" } |
            Clear-Disk -RemoveData -RemoveOEM -Confirm:$false -Verbose

        Initialize-Disk -InputObject $disk -PartitionStyle GPT -PassThru |
            New-Partition -UseMaximumSize |
            Format-Volume -FileSystem ReFS -Confirm:$false |
            Out-Null
    }

Update-StorageProviderCache -DiscoveryLevel Full
```

```PowerShell
cls
```

#### # Set file system labels for iSCSI disks

```PowerShell
Get-Disk -SerialNumber 6805ca19133200 |
    Get-Partition |
    Get-Volume |
    Set-Volume -NewFileSystemLabel iscsi02-Silver-01

Get-Disk -SerialNumber 6805ca19133201 |
    Get-Partition |
    Get-Volume |
    Set-Volume -NewFileSystemLabel iscsi02-Silver-02

Get-Disk -SerialNumber 6805ca19133202 |
    Get-Partition |
    Get-Volume |
    Set-Volume -NewFileSystemLabel iscsi02-Silver-03
```

```PowerShell
cls
```

#### # Add cluster disks for CSV

```PowerShell
Get-ClusterAvailableDisk | Add-ClusterDisk
```

#### # Configure cluster shared volumes

```PowerShell
Add-ClusterSharedVolume -Name "Cluster Disk 1"
Add-ClusterSharedVolume -Name "Cluster Disk 2"
Add-ClusterSharedVolume -Name "Cluster Disk 3"

Get-ClusterSharedVolume |
    foreach {
        $csv = $_

        $diskGuid = $csv |
            Get-ClusterParameter |
            where { $_.Name -eq "DiskGuid" } |
            select -ExpandProperty Value

        $physicalDisk = Get-PhysicalDisk -ObjectId "*$diskGuid*"

        $disk = Get-Disk -UniqueId $physicalDisk.UniqueId

        $volume = $disk | Get-Partition | Get-Volume

        Write-Host ("$($csv.Name) - $($physicalDisk.SerialNumber)" `
            + " - $($volume.FileSystemLabel)")

        $csv.Name = $volume.FileSystemLabel
    }

Cluster Disk 1 - 6805ca19133202 - iscsi02-Silver-03
Cluster Disk 2 - 6805ca19133201 - iscsi02-Silver-02
Cluster Disk 3 - 6805ca19133200 - iscsi02-Silver-01
iscsi01-Bronze-02A - 6805ca3f1f4a04 - iscsi01-Bronze-02A
iscsi01-Bronze-02B - 6805ca3f1f4a05 - iscsi01-Bronze-02B
iscsi01-Gold-01 - 6805ca3f1f4a00 - iscsi01-Gold-01
iscsi01-Gold-02 - 6805ca3f1f4a01 - iscsi01-Gold-02


Push-Location C:\ClusterStorage

Move-Item Volume1 iscsi02-Silver-03
Move-Item Volume2 iscsi02-Silver-02
Move-Item Volume3 iscsi02-Silver-01

Pop-Location
```

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Configure new Management VM network

```PowerShell
$vmHostName = "TT-HV05A"
$networkAdapterName = "Management"
$vlanID = 30
$ipAddressPool = Get-SCStaticIPAddressPool -Name "Management-30 Address Pool"
$vmNetwork = Get-SCVMNetwork -Name "Management VM Network"
$logicalSwitch = Get-SCLogicalSwitch -Name "Embedded Team Switch"
$portClassification = Get-SCPortClassification -Name "Host Management"

$vmHost = Get-SCVMHost -ComputerName $vmHostName

New-SCVirtualNetworkAdapter `
```

    -VMHost \$vmHost `\
    -Name \$networkAdapterName `\
    -VMNetwork \$vmNetwork `\
    -LogicalSwitch \$logicalSwitch `\
    -VLanEnabled \$true `\
    -VLanID \$vlanID `\
    -PortClassification \$portClassification

```PowerShell
$networkAdapter = Get-SCVirtualNetworkAdapter -VMHost $vmHost |
    where { $_.Name -eq $networkAdapterName }

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -IPv4AddressPools $ipAddressPool `
    -IPv4AddressType Static
```

---

## # Disable routing on storage networks

### # Configure iSCSI network adapters

#### # Configure Storage-10 network adapter

```PowerShell
$interfaceAlias = "Storage-10"

Disable-NetAdapterBinding `
    -Name $interfaceAlias `
    -DisplayName "Client for Microsoft Networks"

Disable-NetAdapterBinding `
    -Name $interfaceAlias `
    -DisplayName "File and Printer Sharing for Microsoft Networks"

Disable-NetAdapterBinding `
    -Name $interfaceAlias `
    -DisplayName "Link-Layer Topology Discovery Mapper I/O Driver"

Disable-NetAdapterBinding `
    -Name $interfaceAlias `
    -DisplayName "Link-Layer Topology Discovery Responder"

$adapter = Get-WmiObject `
    -Class "Win32_NetworkAdapter" `
    -Filter "NetConnectionId = '$interfaceAlias'"

$adapterConfig = Get-WmiObject `
    -Class "Win32_NetworkAdapterConfiguration" `
    -Filter "Index= '$($adapter.DeviceID)'"
```

##### # Do not register this connection in DNS

```PowerShell
$adapterConfig.SetDynamicDNSRegistration($false)
```

##### # Disable NetBIOS over TCP/IP

```PowerShell
$adapterConfig.SetTcpipNetbios(2)
```

##### # Remove default gateway

```PowerShell
Remove-NetRoute -InterfaceAlias $interfaceAlias -NextHop 10.1.10.1 -Confirm:$false
```

#### # Configure Storage-13 network adapter

```PowerShell
$interfaceAlias = "Storage-13"

Disable-NetAdapterBinding `
    -Name $interfaceAlias `
    -DisplayName "Client for Microsoft Networks"

Disable-NetAdapterBinding `
    -Name $interfaceAlias `
    -DisplayName "File and Printer Sharing for Microsoft Networks"

Disable-NetAdapterBinding `
    -Name $interfaceAlias `
    -DisplayName "Link-Layer Topology Discovery Mapper I/O Driver"

Disable-NetAdapterBinding `
    -Name $interfaceAlias `
    -DisplayName "Link-Layer Topology Discovery Responder"

$adapter = Get-WmiObject `
    -Class "Win32_NetworkAdapter" `
    -Filter "NetConnectionId = '$interfaceAlias'"

$adapterConfig = Get-WmiObject `
    -Class "Win32_NetworkAdapterConfiguration" `
    -Filter "Index= '$($adapter.DeviceID)'"
```

##### # Do not register this connection in DNS

```PowerShell
$adapterConfig.SetDynamicDNSRegistration($false)
```

##### # Disable NetBIOS over TCP/IP

```PowerShell
$adapterConfig.SetTcpipNetbios(2)
```

##### # Remove default gateway

```PowerShell
Remove-NetRoute -InterfaceAlias $interfaceAlias -NextHop 10.1.13.1 -Confirm:$false
```

### # Refresh DNS

```PowerShell
ipconfig /registerdns

ipconfig /flushdns
```

```PowerShell
cls
```

## # Disable routing on Live Migration network

### # Configure Live Migration network adapter

```PowerShell
$interfaceAlias = "vEthernet (Live Migration)"

$adapter = Get-WmiObject `
    -Class "Win32_NetworkAdapter" `
    -Filter "NetConnectionId = '$interfaceAlias'"

$adapterConfig = Get-WmiObject `
    -Class "Win32_NetworkAdapterConfiguration" `
    -Filter "Index= '$($adapter.DeviceID)'"
```

##### # Do not register this connection in DNS

```PowerShell
$adapterConfig.SetDynamicDNSRegistration($false)
```

##### # Remove default gateway

```PowerShell
Remove-NetRoute -InterfaceAlias $interfaceAlias -NextHop 10.1.11.1 -Confirm:$false
```

### # Refresh DNS

```PowerShell
ipconfig /registerdns

ipconfig /flushdns
```

## Issue - Redirected I/O on Cluster Shared Volumes formatted as ReFS

```PowerShell
Get-ClusterSharedVolumeState | select Name, Node, FileSystemRedirectedIOReason

Name              Node     FileSystemRedirectedIOReason
----              ----     ----------------------------
iscsi02-Silver-01 TT-HV05B               FileSystemReFs
iscsi02-Silver-01 TT-HV05A               FileSystemReFs
iscsi02-Silver-01 TT-HV05C               FileSystemReFs
iscsi02-Silver-02 TT-HV05B               FileSystemReFs
iscsi02-Silver-02 TT-HV05A               FileSystemReFs
iscsi02-Silver-02 TT-HV05C               FileSystemReFs
iscsi02-Silver-03 TT-HV05B               FileSystemReFs
iscsi02-Silver-03 TT-HV05A               FileSystemReFs
iscsi02-Silver-03 TT-HV05C               FileSystemReFs
```

### References

**When using ReFS for Cluster Shared Volumes it always runs in file system redirection mode #2051**\
From <[https://github.com/MicrosoftDocs/windowsserverdocs/issues/2051](https://github.com/MicrosoftDocs/windowsserverdocs/issues/2051)>

**NTFS or ReFS with Cluster Shared Volumes in Windows Server 2016**\
From <[https://www.itprotoday.com/windows-8/ntfs-or-refs-cluster-shared-volumes-windows-server-2016](https://www.itprotoday.com/windows-8/ntfs-or-refs-cluster-shared-volumes-windows-server-2016)>

Always use NTFS for your Cluster Shared Volumes even though Hyper-V VMs are now supported on ReFS in Windows Server 2016. The only exception is when using Storage Spaces Direct in which case you should use ReFS. A big reason for using NTFS is that when using ReFS for Cluster Shared Volumes it always runs in file system redirection mode which means all I/O is sent over the cluster network to the coordinator node for the volume (this is why RDMA network adapters are recommended with Storage Spaces Direct for the cluster network) rather than nodes using Direct IO to access disks directly.

**Windows Server 2016 Hyper-V ReFS vs NTFS**\
From <[https://www.vembu.com/blog/windows-server-2016-hyper-v-refs-vs-ntfs/](https://www.vembu.com/blog/windows-server-2016-hyper-v-refs-vs-ntfs/)>

...there is a major reason not to use ReFS in cluster shared volumes. In CSV Hyper-V architecture, you always want to use NTFS as the file system. Why? Even though ReFS is supported in Windows Server 2016 Hyper-V, when it is used for Cluster Shared Volumes it always runs in file system redirection mode which sends all I/O over the cluster network to the coordinator node for the volume. In deployments utilizing NAS or SAN, this can dramatically impact CSV performance. When utilizing cluster shared volumes you want to always make use of NTFS as the preferred file system in production environments in this configuration.

### Reformat Cluster Shared Volume - iscsi02-Silver-03

#### Move all data off Cluster Shared Volume

```PowerShell
cls
```

#### # Remove Cluster Shared Volume

```PowerShell
Get-Disk -SerialNumber 6805ca19133202 | Get-Partition | Get-Volume

... FileSystem DriveType HealthStatus OperationalStatus SizeRemaining       Size
... ---------- --------- ------------ ----------------- -------------       ----
... CSVFS      Fixed     Healthy      OK                   1023.65 GB 1023.87 GB

Get-ClusterSharedVolume -Name iscsi02-Silver-03 | Remove-ClusterSharedVolume
```

```PowerShell
cls
```

#### # Confirm iSCSI disk is formatted as ReFS

```PowerShell
Get-Disk -SerialNumber 6805ca19133202 | Get-Partition | Get-Volume

... FileSystem DriveType HealthStatus OperationalStatus SizeRemaining       Size
... ---------- --------- ------------ ----------------- -------------       ----
... ReFS       Fixed     Healthy      OK                   1023.65 GB 1023.87 GB
```

```PowerShell
cls
```

#### # Take cluster disk offline

```PowerShell
Stop-ClusterResource -Name iscsi02-Silver-01
```

#### # Remove cluster disk

```PowerShell
Remove-ClusterResource -Name iscsi02-Silver-01 -Force
```

#### # Format iSCSI disk

```PowerShell
Get-PhysicalDisk |
    where { $_.BusType -eq "iSCSI" } |
    where { $_.SerialNumber -eq "6805ca19133202" } |
    foreach {
        $physicalDisk = $_

        $disk = Get-Disk -UniqueId $physicalDisk.UniqueId

        $disk | Set-Disk -IsReadOnly $false
        $disk | Set-Disk -IsOffline $false

        $disk |
            where { $_.PartitionStyle -ne "RAW" } |
            Clear-Disk -RemoveData -RemoveOEM -Confirm:$false -Verbose

        Initialize-Disk -InputObject $disk -PartitionStyle GPT -PassThru |
            New-Partition -UseMaximumSize |
            Format-Volume -FileSystem NTFS -Confirm:$false |
            Out-Null
    }
```

```PowerShell
cls
```

#### # Confirm iSCSI disk is formatted as NTFS

```PowerShell
Get-Disk -SerialNumber 6805ca19133202 | Get-Partition | Get-Volume

... FileSystem DriveType HealthStatus OperationalStatus SizeRemaining       Size
... ---------- --------- ------------ ----------------- -------------       ----
... NTFS       Fixed     Healthy      OK                   1023.65 GB 1023.87 GB
```

```PowerShell
cls
```

#### # Set file system label for iSCSI disk

```PowerShell
Get-Disk -SerialNumber 6805ca19133202 |
    Get-Partition |
    Get-Volume |
    Set-Volume -NewFileSystemLabel iscsi02-Silver-03
```

```PowerShell
cls
```

#### # Add cluster disk for CSV

```PowerShell
Get-ClusterAvailableDisk | Add-ClusterDisk
```

#### # Add Cluster Shared Volume

```PowerShell
Add-ClusterSharedVolume -Name "Cluster Disk 1"
```

```PowerShell
cls
```

#### # Rename Cluster Shared Volume ("Cluster Disk 1" --> "iscsi02-Silver-03")

```PowerShell
Get-ClusterSharedVolume -Name "Cluster Disk 1" |
    foreach {
        $csv = $_

        $diskGuid = $csv |
            Get-ClusterParameter |
            where { $_.Name -eq "DiskGuid" } |
            select -ExpandProperty Value

        $physicalDisk = Get-PhysicalDisk -ObjectId "*$diskGuid*"

        $disk = Get-Disk -UniqueId $physicalDisk.UniqueId

        $volume = $disk | Get-Partition | Get-Volume

        Write-Host ("$($csv.Name) - $($physicalDisk.SerialNumber)" `
            + " - $($volume.FileSystemLabel)")

        $csv.Name = $volume.FileSystemLabel
    }
```

```PowerShell
cls
```

#### # Rename CSV junction point ("C:\\ClusterStorage\\Volume1" --> "C:\\ClusterStorage\\iscsi02-Silver-03")

```PowerShell
Push-Location C:\ClusterStorage

Move-Item Volume1 iscsi02-Silver-03

Pop-Location
```

```PowerShell
cls
```

#### # Confirm CSV is no longer using redirected I/O

```PowerShell
Get-ClusterSharedVolumeState | select Name, Node, FileSystemRedirectedIOReason

Name              Node     FileSystemRedirectedIOReason
----              ----     ----------------------------
iscsi02-Silver-01 TT-HV05B               FileSystemReFs
iscsi02-Silver-01 TT-HV05A               FileSystemReFs
iscsi02-Silver-01 TT-HV05C               FileSystemReFs
iscsi02-Silver-02 TT-HV05B               FileSystemReFs
iscsi02-Silver-02 TT-HV05A               FileSystemReFs
iscsi02-Silver-02 TT-HV05C               FileSystemReFs
iscsi02-Silver-03 TT-HV05B      NotFileSystemRedirected
iscsi02-Silver-03 TT-HV05A      NotFileSystemRedirected
iscsi02-Silver-03 TT-HV05C      NotFileSystemRedirected
```

### Reformat Cluster Shared Volume - iscsi02-Silver-01

#### Move all data off Cluster Shared Volume

---

**FOOBAR18**

```PowerShell
cls
```

##### # Move VMs from iscsi02-Silver-01 to iscsi02-Silver-03

```PowerShell
Get-SCVirtualMachine |
    where { $_.Location -like "C:\ClusterStorage\iscsi02-Silver-01\*" } |
    foreach {
        $vm = $_

        Get-SCVirtualMachine -Name $vm.Name |
            where { $_.VirtualMachineState -eq 'Running' } |
            Stop-SCVirtualMachine |
            select Name, MostRecentTask, MostRecentTaskUIState

        Move-SCVirtualMachine `
            -VM $vm `
            -VMHost $vm.HostName `
            -HighlyAvailable $true `
            -Path "C:\ClusterStorage\iscsi02-Silver-03" `
            -UseDiffDiskOptimization `
            -UseLAN
    }
```

---

```PowerShell
cls
```

#### # Remove Cluster Shared Volume

```PowerShell
Get-Disk -SerialNumber 6805ca19133200 | Get-Partition | Get-Volume

... FileSystem DriveType HealthStatus OperationalStatus SizeRemaining       Size
... ---------- --------- ------------ ----------------- -------------       ----
... CSVFS      Fixed     Healthy      OK                   1012.21 GB 1023.81 GB

Get-ClusterSharedVolume -Name iscsi02-Silver-01 | Remove-ClusterSharedVolume
```

```PowerShell
cls
```

#### # Confirm iSCSI disk is formatted as ReFS

```PowerShell
Get-Disk -SerialNumber 6805ca19133200 | Get-Partition | Get-Volume

... FileSystem DriveType HealthStatus OperationalStatus SizeRemaining       Size
... ---------- --------- ------------ ----------------- -------------       ----
... ReFS       Fixed     Healthy      OK                   1012.21 GB 1023.81 GB
```

```PowerShell
cls
```

#### # Take cluster disk offline

```PowerShell
Stop-ClusterResource -Name iscsi02-Silver-01
```

#### # Remove cluster disk

```PowerShell
Remove-ClusterResource -Name iscsi02-Silver-01 -Force
```

#### # Format iSCSI disk

```PowerShell
Get-PhysicalDisk |
    where { $_.BusType -eq "iSCSI" } |
    where { $_.SerialNumber -eq "6805ca19133200" } |
    foreach {
        $physicalDisk = $_

        $disk = Get-Disk -UniqueId $physicalDisk.UniqueId

        $disk | Set-Disk -IsReadOnly $false
        $disk | Set-Disk -IsOffline $false

        $disk |
            where { $_.PartitionStyle -ne "RAW" } |
            Clear-Disk -RemoveData -RemoveOEM -Confirm:$false -Verbose

        Initialize-Disk -InputObject $disk -PartitionStyle GPT -PassThru |
            New-Partition -UseMaximumSize |
            Format-Volume -FileSystem NTFS -Confirm:$false |
            Out-Null
    }
```

```PowerShell
cls
```

#### # Confirm iSCSI disk is formatted as NTFS

```PowerShell
Get-Disk -SerialNumber 6805ca19133200 | Get-Partition | Get-Volume

... FileSystem DriveType HealthStatus OperationalStatus SizeRemaining       Size
... ---------- --------- ------------ ----------------- -------------       ----
... NTFS       Fixed     Healthy      OK                   1023.67 GB 1023.87 GB
```

```PowerShell
cls
```

#### # Set file system label for iSCSI disk

```PowerShell
Get-Disk -SerialNumber 6805ca19133200 |
    Get-Partition |
    Get-Volume |
    Set-Volume -NewFileSystemLabel iscsi02-Silver-01
```

```PowerShell
cls
```

#### # Add cluster disk for CSV

```PowerShell
Get-ClusterAvailableDisk | Add-ClusterDisk
```

```PowerShell
cls
```

#### # Add Cluster Shared Volume

```PowerShell
Add-ClusterSharedVolume -Name "Cluster Disk 1"
```

```PowerShell
cls
```

#### # Rename Cluster Shared Volume ("Cluster Disk 1" --> "iscsi02-Silver-01")

```PowerShell
Get-ClusterSharedVolume -Name "Cluster Disk 1" |
    foreach {
        $csv = $_

        $diskGuid = $csv |
            Get-ClusterParameter |
            where { $_.Name -eq "DiskGuid" } |
            select -ExpandProperty Value

        $physicalDisk = Get-PhysicalDisk -ObjectId "*$diskGuid*"

        $disk = Get-Disk -UniqueId $physicalDisk.UniqueId

        $volume = $disk | Get-Partition | Get-Volume

        Write-Host ("$($csv.Name) - $($physicalDisk.SerialNumber)" `
            + " - $($volume.FileSystemLabel)")

        $csv.Name = $volume.FileSystemLabel
    }
```

```PowerShell
cls
```

#### # Rename CSV junction point ("C:\\ClusterStorage\\Volume1" --> "C:\\ClusterStorage\\iscsi02-Silver-01")

```PowerShell
Push-Location C:\ClusterStorage

Move-Item Volume1 iscsi02-Silver-01

Pop-Location
```

```PowerShell
cls
```

#### # Confirm CSV is no longer using redirected I/O

```PowerShell
Get-ClusterSharedVolumeState | select Name, Node, FileSystemRedirectedIOReason

Name              Node     FileSystemRedirectedIOReason
----              ----     ----------------------------
iscsi02-Silver-01 TT-HV05B      NotFileSystemRedirected
iscsi02-Silver-01 TT-HV05A      NotFileSystemRedirected
iscsi02-Silver-01 TT-HV05C      NotFileSystemRedirected
iscsi02-Silver-02 TT-HV05B               FileSystemReFs
iscsi02-Silver-02 TT-HV05A               FileSystemReFs
iscsi02-Silver-02 TT-HV05C               FileSystemReFs
iscsi02-Silver-03 TT-HV05B      NotFileSystemRedirected
iscsi02-Silver-03 TT-HV05A      NotFileSystemRedirected
iscsi02-Silver-03 TT-HV05C      NotFileSystemRedirected
```

### Reformat Cluster Shared Volume - iscsi02-Silver-02

#### Move all data off Cluster Shared Volume

---

**FOOBAR18**

```PowerShell
cls
```

##### # Move VMs from iscsi02-Silver-02 to iscsi02-Silver-01

```PowerShell
Get-SCVirtualMachine |
    where { $_.Location -like "C:\ClusterStorage\iscsi02-Silver-02\*" } |
    where { $_.Name -ne "FOOBAR18" } |
    foreach {
        $vm = $_

        Get-SCVirtualMachine -Name $vm.Name |
            where { $_.VirtualMachineState -eq 'Running' } |
            Stop-SCVirtualMachine |
            select Name, MostRecentTask, MostRecentTaskUIState |
            Format-List

        Move-SCVirtualMachine `
            -VM $vm `
            -VMHost $vm.HostName `
            -HighlyAvailable $true `
            -Path "C:\ClusterStorage\iscsi02-Silver-01" `
            -UseDiffDiskOptimization `
            -UseLAN |
            select Name, MostRecentTask, MostRecentTaskUIState |
            Format-List
    }
```

```PowerShell
cls

Get-SCVirtualMachine -Name "FOOBAR18" |
    foreach {
        $vm = $_

        Move-SCVirtualMachine `
            -VM $vm `
            -VMHost $vm.HostName `
            -HighlyAvailable $true `
            -Path "C:\ClusterStorage\iscsi02-Silver-01" `
            -UseDiffDiskOptimization `
            -UseLAN |
            select Name, MostRecentTask, MostRecentTaskUIState |
            Format-List
    }
```

---

```PowerShell
cls
```

#### # Remove Cluster Shared Volume

```PowerShell
Get-Disk -SerialNumber 6805ca19133201 | Get-Partition | Get-Volume

... FileSystem DriveType HealthStatus OperationalStatus SizeRemaining       Size
... ---------- --------- ------------ ----------------- -------------       ----
... CSVFS      Fixed     Healthy      OK                   1012.18 GB 1023.81 GB

Get-ClusterSharedVolume -Name iscsi02-Silver-02 | Remove-ClusterSharedVolume
```

```PowerShell
cls
```

#### # Confirm iSCSI disk is formatted as ReFS

```PowerShell
Get-Disk -SerialNumber 6805ca19133201 | Get-Partition | Get-Volume

... FileSystem DriveType HealthStatus OperationalStatus SizeRemaining       Size
... ---------- --------- ------------ ----------------- -------------       ----
... ReFS       Fixed     Healthy      OK                   1012.18 GB 1023.81 GB
```

```PowerShell
cls
```

#### # Take cluster disk offline

```PowerShell
Stop-ClusterResource -Name iscsi02-Silver-02
```

#### # Remove cluster disk

```PowerShell
Remove-ClusterResource -Name iscsi02-Silver-02 -Force
```

#### # Format iSCSI disk

```PowerShell
Get-PhysicalDisk |
    where { $_.BusType -eq "iSCSI" } |
    where { $_.SerialNumber -eq "6805ca19133201" } |
    foreach {
        $physicalDisk = $_

        $disk = Get-Disk -UniqueId $physicalDisk.UniqueId

        $disk | Set-Disk -IsReadOnly $false
        $disk | Set-Disk -IsOffline $false

        $disk |
            where { $_.PartitionStyle -ne "RAW" } |
            Clear-Disk -RemoveData -RemoveOEM -Confirm:$false -Verbose

        Initialize-Disk -InputObject $disk -PartitionStyle GPT -PassThru |
            New-Partition -UseMaximumSize |
            Format-Volume -FileSystem NTFS -Confirm:$false |
            Out-Null
    }
```

```PowerShell
cls
```

#### # Confirm iSCSI disk is formatted as NTFS

```PowerShell
Get-Disk -SerialNumber 6805ca19133201 | Get-Partition | Get-Volume

... FileSystem DriveType HealthStatus OperationalStatus SizeRemaining       Size
... ---------- --------- ------------ ----------------- -------------       ----
... NTFS       Fixed     Healthy      OK                   1023.67 GB 1023.87 GB
```

```PowerShell
cls
```

#### # Set file system label for iSCSI disk

```PowerShell
Get-Disk -SerialNumber 6805ca19133201 |
    Get-Partition |
    Get-Volume |
    Set-Volume -NewFileSystemLabel iscsi02-Silver-02
```

#### # Add cluster disk for CSV

```PowerShell
Get-ClusterAvailableDisk | Add-ClusterDisk
```

#### # Add Cluster Shared Volume

```PowerShell
Add-ClusterSharedVolume -Name "Cluster Disk 1"
```

```PowerShell
cls
```

#### # Rename Cluster Shared Volume ("Cluster Disk 1" --> "iscsi02-Silver-02")

```PowerShell
Get-ClusterSharedVolume -Name "Cluster Disk 1" |
    foreach {
        $csv = $_

        $diskGuid = $csv |
            Get-ClusterParameter |
            where { $_.Name -eq "DiskGuid" } |
            select -ExpandProperty Value

        $physicalDisk = Get-PhysicalDisk -ObjectId "*$diskGuid*"

        $disk = Get-Disk -UniqueId $physicalDisk.UniqueId

        $volume = $disk | Get-Partition | Get-Volume

        Write-Host ("$($csv.Name) - $($physicalDisk.SerialNumber)" `
            + " - $($volume.FileSystemLabel)")

        $csv.Name = $volume.FileSystemLabel
    }
```

```PowerShell
cls
```

#### # Rename CSV junction point ("C:\\ClusterStorage\\Volume1" --> "C:\\ClusterStorage\\iscsi02-Silver-02")

```PowerShell
Push-Location C:\ClusterStorage

Move-Item Volume1 iscsi02-Silver-02

Pop-Location
```

```PowerShell
cls
```

#### # Confirm CSV is no longer using redirected I/O

```PowerShell
Get-ClusterSharedVolumeState | select Name, Node, FileSystemRedirectedIOReason

Name              Node     FileSystemRedirectedIOReason
----              ----     ----------------------------
iscsi02-Silver-01 TT-HV05B      NotFileSystemRedirected
iscsi02-Silver-01 TT-HV05A      NotFileSystemRedirected
iscsi02-Silver-01 TT-HV05C      NotFileSystemRedirected
iscsi02-Silver-02 TT-HV05B      NotFileSystemRedirected
iscsi02-Silver-02 TT-HV05A      NotFileSystemRedirected
iscsi02-Silver-02 TT-HV05C      NotFileSystemRedirected
iscsi02-Silver-03 TT-HV05B      NotFileSystemRedirected
iscsi02-Silver-03 TT-HV05A      NotFileSystemRedirected
iscsi02-Silver-03 TT-HV05C      NotFileSystemRedirected
```

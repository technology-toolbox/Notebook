# TT-HV05C

Wednesday, March 14, 2018
3:37 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

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
> Join the **corp.technologytoolbox.com** domain and rename the computer to **TT-HV05C**.

---

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Move computer to "Hyper-V Servers" OU

```PowerShell
$computerName = "TT-HV05C"
$targetPath = ("OU=Hyper-V Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com")
```

### # Add computer to "Hyper-V Servers" domain group

```PowerShell
Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath

Import-Module ActiveDirectory
Add-ADGroupMember -Identity "Hyper-V Servers" -Members TT-HV05C$
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
<p>1</p>
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
<p>2</p>
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
<p>3</p>
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
<tr>
<td valign='top'>
<p>4</p>
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
<p>5</p>
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
<p>6</p>
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
<p>7</p>
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
<p>8</p>
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
1        Samsung SSD 850  *********01139V
2        Samsung SSD 850  *********01138P
4        ST4000NM0033-9ZM *****42W
3        ST4000NM0033-9ZM *****58G
5        WDC WD1001FALS-0 WD-******234344
6        WDC WD1002FAEX-0 WD-******786376
```

```PowerShell
cls
```

#### # Create temporary partitions and volumes

```PowerShell
$physicalDrives = @(
    [PSCustomObject] @{ DiskNumber = 1; DriveLetter = "D"; Label = "Samsung SSD 850" },
    [PSCustomObject] @{ DiskNumber = 2; DriveLetter = "E"; Label = "Samsung SSD 850" },
    [PSCustomObject] @{ DiskNumber = 4; DriveLetter = "F"; Label = "ST4000NM0033-9ZM" },
    [PSCustomObject] @{ DiskNumber = 3; DriveLetter = "G"; Label = "ST4000NM0033-9ZM" },
    [PSCustomObject] @{ DiskNumber = 5; DriveLetter = "H"; Label = "WDC WD1001FALS-0" },
    [PSCustomObject] @{ DiskNumber = 6; DriveLetter = "I"; Label = "WDC WD1002FAEX-0" }
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

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E2/5E9F7D8C9D22E71DAE38020FD83FD184B34CA9E2.png)

##### D: (Samsung SSD 850 Pro 512GB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D2/0ACBCA9BDB605344D46F9F20341C9E8B57FF2AD2.png)

##### E: (Samsung SSD 850 Pro 512GB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6E/D1E8D5FE4BAAC8D648A1259EAC682D6AA80DD46E.png)

##### F: (ST4000NM0033-9ZM)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/01/9A1ADC1FB6A1437FBC39E96F990B8EF831516C01.png)

##### G: (ST4000NM0033-9ZM)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C2/BBC998707C27B8C55017A8EAB80294E258248EC2.png)

##### H: (WDC WD1001FALS-0)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/83/E1449B5B2247AF9463489A10C1758F1437A38283.png)

##### I: (WDC WD1002FAEX-0)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/38/BD323A719AF9795C8EA1B82D85B1639406B38538.png)

```PowerShell
cls
```

#### # Clear physical disks

```PowerShell
Get-PhysicalDisk |
    where { $_.BusType -ne "USB" } |
    where { $_.SerialNumber -notin ("*********03848M", "*****5AY", "*****EHB") } |
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
    (Get-PhysicalDisk -SerialNumber *********01139V),
    (Get-PhysicalDisk -SerialNumber *********01138P),
    (Get-PhysicalDisk -SerialNumber *****42W),
    (Get-PhysicalDisk -SerialNumber *****58G)
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
        -StorageTierSizes 250GB,2000GB `
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

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C9/495242496E20A430D5368BA29BCB08DDE28268C9.png)

##### E: (Mirror SSD/HDD storage space)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DD/24B5FAA1ADC5D96A04CE3C6F0B8E3A4DFF7651DD.png)

##### F: (Mirror HDD storage space)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/16/3B37202738BE4EEFBA746B62F77A415E8BA34816.png)

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

### # Join failover cluster

```PowerShell
Add-ClusterNode -Cluster TT-HV05-FC
```

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

Invoke-Command -ComputerName TT-HV05C -ScriptBlock $scriptBlock
```

---

## Deploy Hyper-V

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Add logical switches in VMM

#### # Add logical switch - "Embedded Team Switch"

```PowerShell
$computerName = "TT-HV05C.corp.technologytoolbox.com"

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
$ipAddress = "10.1.10.4"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
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
$ipAddress = "10.1.13.4"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
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
$source = "\\TT-HV05A\C$\NotBackedUp\Temp"
$destination = "C:\NotBackedUp\Temp"

robocopy $source $destination en_windows_server_2016_x64_dvd_9718492.iso
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
$productionServer = 'TT-HV05C'

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

#### # Connect to iSCSI portal (using multiple paths)

```PowerShell
New-IscsiTargetPortal `
    -TargetPortalAddress 10.1.10.5 `
    -InitiatorPortalAddress 10.1.10.4

New-IscsiTargetPortal `
    -TargetPortalAddress 10.1.13.5 `
    -InitiatorPortalAddress 10.1.13.4

Start-Sleep 30
```

#### # Connect first path to iSCSI target

```PowerShell
Connect-IscsiTarget `
    -NodeAddress "iqn.2005-10.org.freenas.ctl:tt-hv05-fc" `
    -TargetPortalAddress 10.1.10.5 `
    -InitiatorPortalAddress 10.1.10.4 `
    -IsMultipathEnabled $true `
    -IsPersistent $true
```

#### # Connect additional paths to iSCSI target

```PowerShell
Connect-IscsiTarget `
    -NodeAddress "iqn.2005-10.org.freenas.ctl:tt-hv05-fc" `
    -TargetPortalAddress 10.1.13.5 `
    -InitiatorPortalAddress 10.1.13.4 `
    -IsMultipathEnabled $true `
    -IsPersistent $true
```

## Configure additional shared storage

### Login as fabric administrator account

```Console
PowerShell
```

#### # Connect to iSCSI portal (using multiple paths)

```PowerShell
New-IscsiTargetPortal `
    -TargetPortalAddress 10.1.10.6 `
    -InitiatorPortalAddress 10.1.10.4

New-IscsiTargetPortal `
    -TargetPortalAddress 10.1.13.6 `
    -InitiatorPortalAddress 10.1.13.4

Start-Sleep 30
```

#### # Connect first path to iSCSI target

```PowerShell
Connect-IscsiTarget `
    -NodeAddress "iqn.2005-10.org.freenas.ctl:tt-hv05-fc" `
    -TargetPortalAddress 10.1.10.6 `
    -InitiatorPortalAddress 10.1.10.4 `
    -IsMultipathEnabled $true `
    -IsPersistent $true
```

#### # Connect additional paths to iSCSI target

```PowerShell
Connect-IscsiTarget `
    -NodeAddress "iqn.2005-10.org.freenas.ctl:tt-hv05-fc" `
    -TargetPortalAddress 10.1.13.6 `
    -InitiatorPortalAddress 10.1.13.4 `
    -IsMultipathEnabled $true `
    -IsPersistent $true
```

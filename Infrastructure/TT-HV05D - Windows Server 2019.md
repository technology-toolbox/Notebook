# TT-HV05D

Monday, April 6, 2020\
6:15 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

### Install Windows Server 2019 Datacenter Edition ("Server Core")

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
> Join the **corp.technologytoolbox.com** domain and rename the computer to
> **TT-HV05D**.

---

**TT-ADMIN03** - Run as administrator

```PowerShell
cls
```

### # Move computer to "Hyper-V Servers" OU

```PowerShell
$computerName = "TT-HV05D"
$targetPath = ("OU=Hyper-V Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com")
```

### # Add computer to "Hyper-V Servers" domain group

```PowerShell
Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath

Import-Module ActiveDirectory
Add-ADGroupMember -Identity "Hyper-V Servers" -Members TT-HV05D$
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

robocopy $source $destination  /E /XD git-for-windows "Microsoft SDKs" /NP
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

Get-NetAdapter |
    where { $_.MacAddress -eq '68-05-CA-19-13-26' } |
    Rename-NetAdapter -NewName "Storage-10"

Get-NetAdapter |
    where { $_.MacAddress -eq '68-05-CA-1A-C9-E3' } |
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
    -PrefixLength 24
```

> **Note:** A default gateway is not configured on this interface, since it is
> used exclusively for iSCSI storage.

##### # Configure network settings for iSCSI

```PowerShell
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

###### # Do not register this connection in DNS

```PowerShell
$adapterConfig.SetDynamicDNSRegistration($false)
```

###### # Disable NetBIOS over TCP/IP

```PowerShell
$adapterConfig.SetTcpipNetbios(2)
```

```PowerShell
cls
```

##### # Configure Storage-13 network adapter

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
    -PrefixLength 24
```

> **Note:** A default gateway is not configured on this interface, since it is
> used exclusively for iSCSI storage.

##### # Configure network settings for iSCSI

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

###### # Do not register this connection in DNS

```PowerShell
$adapterConfig.SetDynamicDNSRegistration($false)
```

###### # Disable NetBIOS over TCP/IP

```PowerShell
$adapterConfig.SetTcpipNetbios(2)
```

```PowerShell
cls
```

#### # Refresh DNS

```PowerShell
ipconfig /registerdns

ipconfig /flushdns
```

### Configure storage

#### Physical disks

| Disk | Model                  | Serial Number            | Capacity | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ---------------------- | ------------------------ | -------- | ------------ | ----------- | -------------------- | ------------ |
| 0    | WDC WD3000F9YZ-09N20L0 | WD-\*\*\*\*\*\*357156    | 3 TB     |              |             |                      |              |
| 1    | WDC WD3000F9YZ-09N20L0 | WD-\*\*\*\*\*\*FV469C    | 3 TB     |              |             |                      |              |
| 2    | ST2000NM0033-9ZM175    | \*\*\*\*\*0FT            | 2 TB     |              |             |                      |              |
| 3    | Samsung SSD 850        | \*\*\*\*\*\*\*\*\*12260P | 512 GB   |              |             |                      |              |
| 4    | Samsung SSD 850        | \*\*\*\*\*\*\*\*\*09894X | 512 GB   |              |             |                      |              |
| 5    | Samsung SSD 850        | \*\*\*\*\*\*\*\*\*03852K | 128 GB   | C:           | 119 GB      | 4K                   |              |
| 6    | ST2000NM0033-9ZM175    | \*\*\*\*\*34P            | 2 TB     |              |             |                      |              |

```PowerShell
Get-PhysicalDisk | sort DeviceId

Get-PhysicalDisk | select DeviceId, Model, SerialNumber, CanPool | sort DeviceId
```

#### Update storage drivers

##### Before

![(screenshot)](https://assets.technologytoolbox.com/screenshots/28/CE0F0C2F7CC0EB8BFE9C75CBD8A8A83C72F18C28.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/69/4203E8C718D08A1F77D3D520BB1F7C534C3CC669.png)

##### Update AHCI drivers

1. Download the latest AHCI drivers from the Intel website:\
   **Intel® RSTe AHCI & SCU Software RAID Driver for Windows**\
   From
   <[https://downloadcenter.intel.com/download/27308/Intel-RSTe-AHCI-SCU-Software-RAID-Driver-for-Windows-?v=t](https://downloadcenter.intel.com/download/27308/Intel-RSTe-AHCI-SCU-Software-RAID-Driver-for-Windows-?v=t)>
2. Extract the drivers
   (**[\\\\TT-FS01\\Public\\Download\\Drivers\\Intel\\RSTe](\TT-FS01\Public\Download\Drivers\Intel\RSTe)
   AHCI & SCU Software RAID driver for Windows**) and copy the files to a
   temporary location on the server:
3. Install the drivers for the **Intel(R) C600+/C220+ series chipset SATA AHCI
   Controller (PCI\\VEN_8086&DEV_8D02&...)**:
4. Install the drivers for the **Intel(R) C600+/C220+ series chipset sSATA AHCI
   Controller (PCI\\VEN_8086&DEV_8D62&...)**:
5. Install the drivers for the **Intel(R) C600+/C220+ series chipset SATA RAID
   Controller (PCI\\VEN_8086&DEV_8D62&...)**:
6. Install the drivers for the **Intel(R) C600+/C220+ series chipset sSATA RAID
   Controller (PCI\\VEN_8086&DEV_8D62&...)**:
7. Restart the server.

```PowerShell
$source = "\\TT-FS01\Public\Download\Drivers\Intel" `
    + "\RSTe AHCI & SCU Software RAID driver for Windows\F6-drivers" `
    + "\RSTe_4.7.0.1119_F6-drivers\iaStorA.free.win8.64bit.4.7.0.1098"

$destination = "C:\NotBackedUp\Temp\Drivers\Intel\" `
    + "iaStorA.free.win8.64bit.4.7.0.1098"

robocopy $source $destination /E

pnputil -i -a "$destination\iaAHCI.inf"

pnputil -i -a "$destination\iaAHCIB.inf"

pnputil -i -a "$destination\iaStorA.inf"

pnputil -i -a "$destination\iaStorB.inf"
```

##### After

![(screenshot)](https://assets.technologytoolbox.com/screenshots/05/AC3F4EEF1A93AF9CA78112EB09668F4AC1AB7805.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/62/AB65E39DDB47490C71809C89980006B43AD22D62.png)

```PowerShell
cls
```

### # Benchmark storage performance

#### # Clear physical disks

```PowerShell
Get-StoragePool Pool-01 | Get-VirtualDisk | Remove-VirtualDisk -Confirm:$false

Remove-StoragePool Pool-01 -Confirm:$false

Get-PhysicalDisk |
    where { $_.SerialNumber -notlike "*03852K" } |
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
0        Samsung SSD 850  *********12260P
1        Samsung SSD 850  *********09894X
3        ST2000NM0033-9ZM *****34P
6        ST2000NM0033-9ZM *****0FT
4        WDC WD3000F9YZ-0 WD-******357156
5        WDC WD3000F9YZ-0 WD-******FV469C
```

```PowerShell
cls
```

#### # Create temporary partitions and volumes

```PowerShell
$physicalDrives = @(
    [PSCustomObject] @{ DiskNumber = 0; DriveLetter = "D"; Label = "Samsung SSD 850" },
    [PSCustomObject] @{ DiskNumber = 1; DriveLetter = "E"; Label = "Samsung SSD 850" },
    [PSCustomObject] @{ DiskNumber = 3; DriveLetter = "F"; Label = "ST2000NM0033-9ZM" },
    [PSCustomObject] @{ DiskNumber = 6; DriveLetter = "G"; Label = "ST2000NM0033-9ZM" },
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
& 'C:\NotBackedUp\Public\Toolbox\ATTO Disk Benchmark\v3\ATTODiskBenchmark.exe'
```

##### C: (Samsung 850 Pro 128 GB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BB/B6C6736460040D08DA3F8DEBA56D9D9DB9B3F1BB.png)

##### D: (Samsung SSD 850 512 GB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DE/020BFE2BCDBA4427B8116F08CEC6678DD44751DE.png)

##### E: (Samsung SSD 850 512 GB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/49/B480B0C0EF2A342889309EA0DE2570BB3EF56049.png)

##### F: (Seagate Constellation ES.3 2TB 7200 RPM - ST2000NM0033-9ZM)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D5/3884A942A8B1FD20EC6CFC88B67BF40F96E965D5.png)

##### G: (Seagate Constellation ES.3 2TB 7200 RPM - ST2000NM0033-9ZM)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/06/317488E91E48CEEA7F72D2A8693E3ABDD829F806.png)

##### H: (Western Digital SE 3TB 7200 RPM - WDC WD3000F9YZ-0)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C1/41355A70351FD91155BACB48D9B22792EAEEC9C1.png)

##### I: (Western Digital SE 3TB 7200 RPM - WDC WD3000F9YZ-0)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/85/C02F09F08325863825425B6FC58622297565F385.png)

```PowerShell
cls
```

#### # Clear physical disks

```PowerShell
Get-PhysicalDisk |
    where { $_.SerialNumber -notlike "*03852K" } |
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

$physicalDrives = @(
    [PSCustomObject] @{ DiskNumber = 0; Label = "Samsung SSD 850" },
    [PSCustomObject] @{ DiskNumber = 1; Label = "Samsung SSD 850" },
    [PSCustomObject] @{ DiskNumber = 3; Label = "ST2000NM0033-9ZM" },
    [PSCustomObject] @{ DiskNumber = 6; Label = "ST2000NM0033-9ZM" },
    [PSCustomObject] @{ DiskNumber = 4; Label = "WDC WD3000F9YZ-0" },
    [PSCustomObject] @{ DiskNumber = 5; Label = "WDC WD3000F9YZ-0" }
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

#### # Create partitions and volumes

##### # Create volume "D" on Gold-01

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

##### # Create volume "E" on Silver-01

```PowerShell
$virtualDiskName = "Silver-01"
$driveLetter = "E"
$fileSystem = "NTFS"
```

> **Important**
>
> When using storage tiers, format the volume using NTFS (not ReFS). Otherwise,
> an error occurs when optimizing the storage tiers:
>
> The operation requested is not supported by the hardware backing the volume.
> (0x8900002A)
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
> "ReFS should be used with Storage Spaces Direct (S2D), and stick with NTFS for
> all other scenarios."
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
> Simply appending ">> {log file}" (as described in the "To change the Storage
> Tiers Optimization task to save a report (Task Scheduler)" section of the>
> [TechNet article](TechNet article)) did not work. Specifically, when running
> the task, the log file was not created and the task immediately finished
> without reporting any error.
>
> Changing the **Program/script** (i.e. the action's **Execute** property) to
> launch "%windir%\\system32\\defrag.exe" using "%windir%\\system32\\cmd.exe"
> resolved the issue.

##### Reference

**Save a report when Storage Tiers Optimization runs**\
From <[https://technet.microsoft.com/en-us/library/dn789160.aspx](https://technet.microsoft.com/en-us/library/dn789160.aspx)>

```PowerShell
cls
```

#### # Benchmark storage performance

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\ATTO Disk Benchmark\v3\ATTODiskBenchmark.exe'
```

##### D: (Mirror SSD storage space - 2x Samsung 850 Pro 512GB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/39/1978A12F7822A042ACE4BAF9ABEAFFDD3FF19339.png)

##### E: (Mirror SSD/HDD storage space)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/20/CD078624571F1E8F5E1F73220C291770A7311520.png)

##### F: (Mirror HDD storage space)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3C/21A84708D736CD5CAF983E4F206568BFC000313C.png)

### Configure shared storage

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

#### # Configure MPIO settings

##### # Ensure multipath I/O feature is installed

```PowerShell
Enable-WindowsOptionalFeature -Online -FeatureName MultipathIo
```

> **Important:** If necessary, restart the server to complete the feature
> installation.

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

```PowerShell
cls
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

## # Deploy Hyper-V

### # Add cluster node using VMM

#### # Add VMM administrators domain group and VMM management service account to Administrators group on Hyper-V servers

```PowerShell
net localgroup Administrators 'TECHTOOLBOX\VMM Admins' /ADD

net localgroup Administrators TECHTOOLBOX\s-vmm01-mgmt /ADD
```

### # Add cluster node

#### # Add node to failover cluster

```PowerShell
Add-ClusterNode -Cluster TT-HV05-FC
```

---

**TT-ADMIN03** - Run as administrator

#### Add cluster node in Virtual Machine Manager

##### Refresh host cluster in Virtual Machine Manager

> **Note:** At this point, the new cluster node should appear in VMM with a
> "pending" status.

---

##### # Restart cluster node to complete enabling Network Virtualization Feature

```PowerShell
Restart-Computer
```

---

**TT-ADMIN03** - Run as administrator

```PowerShell
cls
```

### # Add logical switches in VMM

#### # Add logical switch - "Embedded Team Switch"

```PowerShell
$computerName = "TT-HV05D.corp.technologytoolbox.com"

$vmHost = Get-SCVMHost -ComputerName $computerName

$logicalSwitch = Get-SCLogicalSwitch -Name "Embedded Team Switch"

$uplinkPortProfileSet = Get-SCUplinkPortProfileSet -Name "Trunk Uplink"

$networkAdapters = @()

$networkAdapters += Get-SCVMHostNetworkAdapter `
    -VMHost $vmHost `
    -Name "Intel(R) I210 Gigabit Network Connection"

#$networkAdapters += Get-SCVMHostNetworkAdapter `
#    -VMHost $vmHost `
#    -Name "Intel(R) I210 Gigabit Network Connection #2"

$networkAdapters |
    foreach {
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
> When using virtual network adapters, SMB Multichannel worked but throughput
> was substantially below 1 Gbps on each network adapter. I believe this is due
> to RSS not being used on the virtual network adapters (even though this is
> enabled in the corresponding port classification). This speculation is based
> on the following:
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
    where { $_.Name -in $("Storage 1", "Storage 2") } |
    Remove-SCVirtualNetworkAdapter
```

##### # Associate storage network adapters with corresponding VLANs in logical switch

```PowerShell
$logicalNetwork = Get-SCLogicalNetwork -Name "Datacenter"

#$networkAdapter = Get-SCVMHostNetworkAdapter `
#    -VMHost $vmHost `
#    -Name "Intel(R) Gigabit CT Desktop Adapter"

$networkAdapter = Get-SCVMHostNetworkAdapter -VMHost $vmHost |
    where { $_.MacAddress -eq '68:05:CA:19:13:26' }

$subnets = @()
$subnets += New-SCSubnetVLan -VLanID 10 -Subnet "10.1.10.0/24"

Set-SCVMHostNetworkAdapter `
    -VMHostNetworkAdapter $networkAdapter `
    -AddOrSetLogicalNetwork $logicalNetwork `
    -SubnetVLan $subnets

#$networkAdapter = Get-SCVMHostNetworkAdapter `
#    -VMHost $vmHost `
#    -Name "Intel(R) Gigabit CT Desktop Adapter #2"

$networkAdapter = Get-SCVMHostNetworkAdapter -VMHost $vmHost |
    where { $_.MacAddress -eq '68:05:CA:1A:C9:E3' }

$subnets = @()
$subnets += New-SCSubnetVLan -VLanID 13 -Subnet "10.1.13.0/24"

Set-SCVMHostNetworkAdapter `
    -VMHostNetworkAdapter $networkAdapter `
    -AddOrSetLogicalNetwork $logicalNetwork `
    -SubnetVLan $subnets
```

```PowerShell
cls
```

#### # Add second network adapter to logical switch - "Embedded Team Switch"

```PowerShell
$computerName = "TT-HV05D.corp.technologytoolbox.com"

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
    foreach {
        $networkAdapter = $_

        Set-SCVMHostNetworkAdapter `
            -VMHostNetworkAdapter $networkAdapter `
            -UplinkPortProfileSet $uplinkPortProfileSet
    }

$virtualNetwork = Get-SCVirtualNetwork -VMHost $vmHost

Set-SCVirtualNetwork `
    -VirtualNetwork $virtualNetwork `
    -VMHostNetworkAdapters $networkAdapters `
    -LogicalSwitch $logicalSwitch
```

---

```PowerShell
cls
```

### # Enable jumbo frames on virtual switches

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*" |
    sort Name |
    select Name, DisplayValue
```

```Text
Name                       DisplayValue
----                       ------------
Storage-10                 9014 Bytes
Storage-13                 9014 Bytes
Team 1A                    9014 Bytes
Team 1B                    9014 Bytes
vEthernet (Cluster)        Disabled
vEthernet (Live Migration) Disabled
vEthernet (Management)     Disabled
```

```PowerShell
Get-NetAdapter |
    where { $_.Name -like 'vEthernet*' } |
    foreach {
        Set-NetAdapterAdvancedProperty `
            -Name $_.Name `
            -DisplayName "Jumbo Packet" -RegistryValue 9014
    }

Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*" |
    sort Name |
    select Name, DisplayValue
```

```Text
Name                       DisplayValue
----                       ------------
Storage-10                 9014 Bytes
Storage-13                 9014 Bytes
Team 1A                    9014 Bytes
Team 1B                    9014 Bytes
vEthernet (Cluster)        9014 Bytes
vEthernet (Live Migration) 9014 Bytes
vEthernet (Management)     9014 Bytes
```

```PowerShell
ping TT-FS01 -f -l 8900
```

```PowerShell
cls
```

### # Verify SMB Multichannel is working as expected

```PowerShell
$source = "\\TT-HV05E\C$\NotBackedUp\Temp"
$destination = "C:\NotBackedUp\Temp"

robocopy $source $destination en_windows_server_2019_x64_dvd_3c2cf1202.iso
```

```PowerShell
cls
```

## # Install and configure DPM agent

### # Install DPM agent

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\System Center 2019" `
    + "\DPM\Agents\DPMAgentInstaller_x64.exe"

$installerArguments = "TT-DPM05.corp.technologytoolbox.com"

Start-Process `
    -FilePath $installerPath `
    -ArgumentList "$installerArguments" `
    -Wait
```

Review the licensing agreement. If you accept the Microsoft Software License
Terms, select **I accept the license terms and conditions**, and then click
**OK**.

Confirm the agent installation completed successfully and the following firewall
exceptions have been added:

- Exception for DPMRA.exe in all profiles
- Exception for Windows Management Instrumentation service
- Exception for RemoteAdmin service
- Exception for DCOM communication on port 135 (TCP and UDP) in all profiles

#### Reference

**Installing Protection Agents Manually**\
Pasted from <[http://technet.microsoft.com/en-us/library/hh757789.aspx](http://technet.microsoft.com/en-us/library/hh757789.aspx)>

---

**TT-ADMIN03** - DPM Management Shell

```PowerShell
cls
```

### # Attach DPM agent

```PowerShell
$productionServer = 'TT-HV05D'

.\Attach-ProductionServer.ps1 `
    -DPMServerName TT-DPM05 `
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
$msiPath = "\\TT-FS01\Products\Microsoft\System Center 2019\SCOM\agent\AMD64" `
    + "\MOMAgent.msi"

msiexec.exe /i $msiPath `
    MANAGEMENT_GROUP=HQ `
    MANAGEMENT_SERVER_DNS=TT-SCOM01C `
    ACTIONS_USE_COMPUTER_ACCOUNT=1
```

### Approve manual agent install in Operations Manager

```PowerShell
cls
```

---

**TT-HV05E**

## # Move virtual machines

```PowerShell
$virtualMachines = Get-VM | select -ExpandProperty Name

Push-Location D:\NotBackedUp\VMs

Get-ChildItem |
where { $_.Name -notin $virtualMachines } |
foreach {
    robocopy "$($_.Name)" "\\TT-HV05D\D`$\NotBackedUp\VMs\$($_.Name)" /E /MOVE
}

Pop-Location

Push-Location E:\NotBackedUp\VMs

Get-ChildItem |
where { $_.Name -notin $virtualMachines } |
foreach {
    robocopy "$($_.Name)" "\\TT-HV05D\E`$\NotBackedUp\VMs\$($_.Name)" /E /MOVE
}

Pop-Location

Push-Location F:\NotBackedUp\VMs

Get-ChildItem |
where { $_.Name -notin $virtualMachines } |
foreach {
    robocopy "$($_.Name)" "\\TT-HV05D\F`$\NotBackedUp\VMs\$($_.Name)" /E /MOVE
}

Pop-Location
```

---

## Replace DPM server (TT-DPM05 --> TT-DPM06)

```PowerShell
cls
```

### # Update DPM server

```PowerShell
cd 'C:\Program Files\Microsoft Data Protection Manager\DPM\bin\'

.\SetDpmServer.exe -dpmServerName TT-DPM06.corp.technologytoolbox.com
```

---

**TT-ADMIN04** - DPM Management Shell

```PowerShell
cls
```

### # Attach DPM agent

```PowerShell
$productionServer = 'TT-HV05D'

.\Attach-ProductionServer.ps1 `
    -DPMServerName TT-DPM06 `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `
    -UserName jjameson-admin
```

---

That doesn't work...

> Error:\
> Data Protection Manager Error ID: 307\
> The protection agent operation failed because DPM detected an unknown DPM
> protection agent on tt-hv05d.corp.technologytoolbox.com.
>
> Recommended action:\
> Use Add or Remove Programs in Control Panel to uninstall the protection agent from
> tt-hv05d.corp.technologytoolbox.com, then reinstall the protection agent and perform
> the operation again.

### # Remove DPM 2019 Agent Coordinator

```PowerShell
cls
```

```PowerShell
msiexec /x `{356B3986-6B7D-4513-B72D-81EB4F43ADE6`}
```

### # Remove DPM 2019 Protection Agent

```PowerShell
cls
```

```PowerShell
msiexec /x `{CC6B6758-3A68-4BBA-9D61-1F3278D6A7EA`}
```

> **Important**
>
> Restart the computer to complete the removal of the DPM agent.

```PowerShell
Suspend-ClusterNode -Drain -Wait

Get-VM | where {$_.State -eq 'Running'} | Stop-VM

Restart-Computer
```

```PowerShell
Start-VM TT-SQL01C
Start-Sleep -Seconds 30
Start-VM TT-VMM01C
Start-Sleep -Seconds 30
Start-VM TT-SQL03
Start-Sleep -Seconds 30
Start-VM TT-SCOM01C
Start-Sleep -Seconds 30
Start-VM EXT-APP03A
Start-Sleep -Seconds 30
Start-VM EXT-WEB03A
Start-Sleep -Seconds 30
Start-VM EXT-ADFS03A
Start-Sleep -Seconds 30
Start-VM EXT-WAP03A
Start-Sleep -Seconds 30
Start-VM CON-ADFS01
Start-Sleep -Seconds 30

Resume-ClusterNode -Failback Immediate
```

### # Install DPM 2019 agent

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\System Center 2019" `
    + "\DPM\Agents\DPMAgentInstaller_x64.exe"

$installerArguments = "TT-DPM06.corp.technologytoolbox.com"

Start-Process `
    -FilePath $installerPath `
    -ArgumentList "$installerArguments" `
    -Wait
```

---

**TT-ADMIN04** - DPM Management Shell

```PowerShell
cls
```

### # Attach DPM agent

```PowerShell
$productionServer = 'TT-HV05D'

.\Attach-ProductionServer.ps1 `
    -DPMServerName TT-DPM06 `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `
    -UserName jjameson-admin
```

---

### Add virtual machines to protection group in DPM

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

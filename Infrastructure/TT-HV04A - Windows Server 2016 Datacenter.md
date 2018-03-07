# TT-HV04A - Windows Server 2016 Datacenter

Wednesday, March 7, 2018
7:34 AM

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
$failoverClusterName = "TT-HV04-FC"
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
> Join the **corp.technologytoolbox.com** domain and rename the computer to **TT-HV04A**.

---

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Move computer to "Hyper-V Servers" OU

```PowerShell
$computerName = "TT-HV04A"
$targetPath = ("OU=Hyper-V Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com")
```

### # Add computer to "Hyper-V Servers" domain group

```PowerShell
Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath

Import-Module ActiveDirectory
Add-ADGroupMember -Identity "Hyper-V Servers" -Members TT-HV04A$
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
<p>Model: WDC WD4002FYYZ-01B7CB0<br />
Serial number: *****0RY</p>
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
<p>Model: Samsung SSD 850<br />
Serial number: *********19550Z</p>
</td>
<td valign='top'>
<p>256 GB</p>
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
<p>4</p>
</td>
<td valign='top'>
<p>Model: ST2000NM0033-9ZM<br />
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

#### # Create temporary partitions and volumes

```PowerShell
$physicalDrives = @(
    [PSCustomObject] @{ DiskNumber = 0; DriveLetter = "D"; Label = "WD Gold 4TB" },
    [PSCustomObject] @{ DiskNumber = 1; DriveLetter = "E"; Label = "WD SE 3TB" },
    [PSCustomObject] @{ DiskNumber = 2; DriveLetter = "F"; Label = "Samsung 850 Pro 256GB" },
    [PSCustomObject] @{ DiskNumber = 4; DriveLetter = "G"; Label = "Seagate ES.3 2TB" }
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

#### # Benchmark performance of individual drives

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\ATTO Disk Benchmark\Bench32.exe'
```

##### C: (SSD - Samsung 850 Pro 128GB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/66/C72940A9A25578F77AC4BB364F218C1CA7A7D166.png)

##### D: (HDD - WD Gold 4TB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/75/4A26CCC5121677149EE12BC69C5EAF7E29D90675.png)

##### E: (HDD - WD SE 3TB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7D/41DDE8F9592C5AE2CD05C9E697DB42BF51794A7D.png)

##### F: (SSD - Samsung 850 Pro 256GB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3E/9BAA70D21BAC283B43DBB1E1A3828BADF5AE763E.png)

##### G: (HDD - Seagate ES.3 2TB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0E/5C68D4701C583F45CA17BA7C2BFD6529F63A600E.png)

## Issue - Bad hard drive

Replace WD 4TB Gold with Seagate 3 TB Constellation

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
<p>Model: ST3000NM0033-9ZM178<br />
Serial number: *****3DD</p>
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
<p>Model: Samsung SSD 850<br />
Serial number: *********19550Z</p>
</td>
<td valign='top'>
<p>256 GB</p>
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
<p>4</p>
</td>
<td valign='top'>
<p>Model: ST2000NM0033-9ZM<br />
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

```PowerShell
cls
```

### # Benchmark storage performance

#### # Create temporary partitions and volumes

```PowerShell
$physicalDrives = @(
    [PSCustomObject] @{ DiskNumber = 0; DriveLetter = "D"; Label = "Seagate ES.3 3TB" }
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

#### # Benchmark performance of individual drives

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\ATTO Disk Benchmark\Bench32.exe'
```

##### D: (HDD - Seagate ES.3 3TB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A3/89D9FB0B0A4DEB71684D548337615F3DAC8329A3.png)

## Prepare infrastructure for Hyper-V installation

### Enable Virtualization in BIOS

Intel Virtualization Technology: **Enabled**

```PowerShell
cls
```

### # Add roles for Storage Spaces Direct and Hyper-V cluster

```PowerShell
Install-WindowsFeature `
    -Name File-Services, Failover-Clustering, Hyper-V, Multipath-IO `
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

#### # Remove pagefile from D: drive

```PowerShell
$cs = gwmi Win32_ComputerSystem -EnableAllPrivileges
$cs.AutomaticManagedPagefile = $false
$cs.Put()

Restart-Computer
```

> **Note**
>
> Wait for the computer to restart.

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

#### # Enable system-managed pagefile

```PowerShell
$cs = gwmi Win32_ComputerSystem -EnableAllPrivileges
$cs.AutomaticManagedPagefile = $true
$cs.Put()

Restart-Computer
```

> **Note**
>
> Wait for the computer to restart.

```PowerShell
cls
```

#### # Run cluster validation tests

```PowerShell
Test-Cluster `
    -Node TT-HV04A, TT-HV04B `
    -Include "Storage Spaces Direct", Inventory, Network, "System Configuration"
```

> **Note**
>
> Wait for the cluster validation tests to complete.

#### # Review cluster validation report

```PowerShell
$source = "$env:TEMP\Validation Report 2018.03.07 At 10.25.04.htm"
$destination = "\\TT-FS01\Public"

Copy-Item $source $destination
```

---

**WOLVERINE**

```PowerShell
& "\\TT-FS01\Public\Validation Report 2018.03.07 At 10.25.04.htm"
```

---

```PowerShell
cls
```

#### # Create cluster

```PowerShell
New-Cluster -Name TT-HV04-FC -Node TT-HV04A, TT-HV04B -NoStorage

WARNING: There were issues while creating the clustered role that may prevent it from starting. For more information view the report file below.
WARNING: Report file location: C:\Windows\cluster\Reports\Create Cluster Wizard TT-HV04-FC on 2018.03.07 At 10.31.49.htm

Name
----
TT-HV04-FC
```

#### # Review cluster creation report

```PowerShell
$source = "C:\Windows\cluster\Reports" `
```

    + "\\Create Cluster Wizard TT-HV04-FC on 2018.03.07 At 10.31.49.htm"

```PowerShell
$destination = "\\TT-FS01\Public"

Copy-Item $source $destination
```

---

**WOLVERINE**

```PowerShell
& "\\TT-FS01\Public\Create Cluster Wizard TT-HV04-FC on 2018.03.07 At 10.31.49.htm"
```

---

> **Note**
>
> The cluster creation report contains the following warning:
>
> - **An appropriate disk was not found for configuring a disk witness. The cluster is not configured with a witness. As a best practice, configure a witness to help achieve the highest availability of the cluster. If this cluster does not have shared storage, configure a File Share Witness or a Cloud Witness.**

```PowerShell
cls
```

#### # Configure cluster quorum

---

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Configure file share for cluster quorum witness

```PowerShell
Enter-PSSession TT-FS01
```

---

**TT-FS01**

##### # Create folder for specific failover cluster (TT-HV04-FC)

```PowerShell
$path = "D:\Shares\Witness`$\TT-HV04-FC"

New-Item -Path $path -ItemType Directory
```

##### # Grant permissions for failover cluster service

```PowerShell
icacls $path /grant 'TT-HV04-FC$:(OI)(CI)(F)'

exit
```

---

---

```PowerShell
cls
```

#### # Set file share as cluster quorum witness

```PowerShell
Set-ClusterQuorum -NodeAndFileShareMajority \\TT-FS01\Witness$\TT-HV04-FC
```

```PowerShell
cls
```

### # Enable and configure Storage Spaces Direct

```Text
Enable-ClusterS2D -Verbose

VERBOSE: 2018/03/07-10:39:30.417 Ensuring that all nodes support S2D
VERBOSE: 2018/03/07-10:39:30.433 Querying storage information
VERBOSE: 2018/03/07-10:39:34.325 Sorted disk types present (fast to slow): SSD,HDD. Number of types present: 2
VERBOSE: 2018/03/07-10:39:34.325 Checking that nodes support the desired cache state
VERBOSE: 2018/03/07-10:39:34.341 Checking that all disks support the desired cache state
```

> **Note**
>
> Review the verbose messages and confirm the operation.

```Text
VERBOSE: 2018/03/07-10:40:00.966 Creating health resource
VERBOSE: 2018/03/07-10:40:01.372 Setting cluster property
VERBOSE: 2018/03/07-10:40:01.372 Setting default fault domain awareness on clustered storage subsystem
VERBOSE: 2018/03/07-10:40:02.544 Waiting until physical disks are claimed
VERBOSE: 2018/03/07-10:40:05.559 Number of claimed disks on node 'TT-HV04B': 4/4
VERBOSE: 2018/03/07-10:40:05.575 Number of claimed disks on node 'TT-HV04A': 4/4
VERBOSE: 2018/03/07-10:40:05.591 Node 'TT-HV04B': Waiting until cache reaches desired state (HDD:'ReadWrite'
SSD:'WriteOnly')
VERBOSE: 2018/03/07-10:40:05.591 SBL disks initialized in cache on node 'TT-HV04B': 4 (4 on all nodes)
VERBOSE: 2018/03/07-10:40:05.591 SBL disks initialized in cache on node 'TT-HV04A': 4 (8 on all nodes)
VERBOSE: 2018/03/07-10:40:05.606 Cache reached desired state on TT-HV04B
VERBOSE: 2018/03/07-10:40:05.606 Node 'TT-HV04A': Waiting until cache reaches desired state (HDD:'ReadWrite'
SSD:'WriteOnly')
VERBOSE: 2018/03/07-10:40:05.622 Cache reached desired state on TT-HV04A
VERBOSE: 2018/03/07-10:40:05.622 Waiting until SBL disks are surfaced
VERBOSE: 2018/03/07-10:40:08.653 Disks surfaced on node 'TT-HV04B': 8/8
VERBOSE: 2018/03/07-10:40:08.669 Disks surfaced on node 'TT-HV04A': 8/8
VERBOSE: 2018/03/07-10:40:12.159 Waiting until all physical disks are reported by clustered storage subsystem
VERBOSE: 2018/03/07-10:40:15.574 Physical disks in clustered storage subsystem: 8
VERBOSE: 2018/03/07-10:40:15.574 Querying pool information
VERBOSE: 2018/03/07-10:40:16.246 Starting health providers
VERBOSE: 2018/03/07-10:41:32.929 Creating S2D pool
VERBOSE: 2018/03/07-10:41:38.385 Checking that all disks support the desired cache state
WARNING: 2018/03/07-10:41:38.510 C:\Windows\Cluster\Reports\Enable-ClusterS2D on 2018.03.07-10.41.38.495.htm
```

```Console
cls
```

#### # Review storage tiers and resiliency settings

```PowerShell
Get-StoragePool "S2D on TT-HV04-FC"

FriendlyName      OperationalStatus HealthStatus IsPrimordial IsReadOnly
------------      ----------------- ------------ ------------ ----------
S2D on TT-HV04-FC OK                Healthy      False        False


Get-StoragePool "S2D on TT-HV04-FC" | Get-PhysicalDisk

FriendlyName           SerialNumber    CanPool OperationalStatus HealthStatus Usage            Size
------------           ------------    ------- ----------------- ------------ -----            ----
ATA Samsung SSD 850    *********19553B False   OK                Healthy      Journal     238.25 GB
WDC WD3000F9YZ-09N20L0 WD-******FV469C False   OK                Healthy      Auto-Select   2.73 TB
ATA ST2000NM0033-9ZM   *****34P        False   OK                Healthy      Auto-Select   1.82 TB
ATA WDC WD4002FYYZ-0   *****03Y        False   OK                Healthy      Auto-Select   3.64 TB
ST3000NM0033-9ZM178    *****3DD        False   OK                Healthy      Auto-Select   2.73 TB
ATA Samsung SSD 850    *********19550Z False   OK                Healthy      Journal     238.25 GB
ATA ST2000NM0033-9ZM   *****0FT        False   OK                Healthy      Auto-Select   1.82 TB
ATA WDC WD3000F9YZ-0   WD-******357156 False   OK                Healthy      Auto-Select   2.73 TB

Get-StorageTier | ft FriendlyName, ResiliencySettingName

FriendlyName ResiliencySettingName
------------ ---------------------
Capacity     Mirror
```

```PowerShell
cls
```

#### # Create virtual disks

```PowerShell
New-Volume `
    -StoragePoolFriendlyName "S2D on TT-HV04-FC" `
    -FriendlyName "S2D-Silver01" `
    -FileSystem CSVFS_ReFS `
    -StorageTierfriendlyNames Capacity `
    -StorageTierSizes 2TB

New-Volume `
    -StoragePoolFriendlyName "S2D on TT-HV04-FC" `
    -FriendlyName "S2D-Silver02" `
    -FileSystem CSVFS_ReFS `
    -StorageTierfriendlyNames Capacity `
    -StorageTierSizes 2TB
```

```PowerShell
cls
```

## # Deploy Hyper-V

### # Configure VM storage

```PowerShell
mkdir C:\ClusterStorage\Volume1\VMs
mkdir C:\ClusterStorage\Volume2\VMs

Set-VMHost -VirtualMachinePath C:\ClusterStorage\Volume1\VMs
```

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

Set-VMHost -VirtualMachinePath C:\ClusterStorage\Volume1\VMs
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

## Remove shared storage

### Reconfigure cluster quorum

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Configure file share for cluster quorum witness

```PowerShell
Enter-PSSession TT-FS01
```

---

**TT-FS01**

##### # Create folder

```PowerShell
$folderName = "Witness`$"
$path = "D:\Shares\$folderName"

New-Item -Path $path -ItemType Directory
```

##### # Remove "BUILTIN\\Users" permissions

```PowerShell
icacls $path /inheritance:d
icacls $path /remove:g "BUILTIN\Users"
```

##### # Share folder

```PowerShell
New-SmbShare `
    -Name $folderName `
    -Path $path `
    -CachingMode None `
    -ChangeAccess Everyone
```

##### # Grant permissions for fabric administrators

```PowerShell
icacls $path /grant '"Fabric Admins":(OI)(CI)(RX)'
```

##### # Create folder for specific failover cluster (TT-HV02-FC)

```PowerShell
$path = "$path\TT-HV02-FC"

New-Item -Path $path -ItemType Directory
```

##### # Grant permissions for failover cluster service

```PowerShell
icacls $path /grant 'TT-HV02-FC$:(OI)(CI)(F)'

exit
```

---

---

```PowerShell
cls
```

#### # Set file share as cluster quorum witness

```PowerShell
Set-ClusterQuorum -NodeAndFileShareMajority \\TT-FS01\Witness$\TT-HV02-FC
```

```PowerShell
cls
```

### # Remove cluster shared volume

```PowerShell
Get-ClusterSharedVolume | Remove-ClusterSharedVolume
```

### Remove cluster disks (using Failover Cluster Manager)

```PowerShell
cls
```

### # Disconnect iSCSI storage

```PowerShell
Disconnect-IscsiTarget

Get-IscsiTargetPortal | Remove-IscsiTargetPortal
```

```PowerShell
cls
```

### # Stop iSCSI client service

```PowerShell
Stop-Service msiscsi

Set-Service msiscsi -StartupType Manual
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

- **cifs - TT-HV02A.corp.technologytoolbox.com**
- **Microsoft Virtual System Migration Service - TT-HV02A.corp.technologytoolbox.com**

### Restart Hyper-V servers

This is necessary to avoid an error when migrating VMs:

```PowerShell
Move-VM : Virtual machine migration operation for 'BANSHEE' failed at migration source 'FORGE'. (Virtual machine ID D46FD5CD-A9CB-40B1-ACFB-5CC8C759E2D5)
The Virtual Machine Management Service failed to establish a connection for a Virtual Machine migration with host 'TT-HV02A': No credentials are available in the security package (0x8009030E).
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

#### Virtual disks

| Name   | Layout | Provisioning | Capacity | SSD Tier | HDD Tier | Volume | Volume Label | Write-Back Cache |
| ------ | ------ | ------------ | -------- | -------- | -------- | ------ | ------------ | ---------------- |
| Data01 | Mirror | Fixed        | 200 GB   | 200 GB   |          | D:     | Data01       |                  |
| Data02 | Mirror | Fixed        | 900 GB   | 265 GB   | 1860 GB  | E:     | Data02       | 5 GB             |

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
Add-ClusterNode -Cluster TT-HV04-FC
```

---

**TT-VMM01A**

```PowerShell
cls
```

### # Add logical switches in VMM

#### # Add logical switch - "Embedded Team Switch"

```PowerShell
$vmHost = Get-SCVMHost -ComputerName TT-HV04A.corp.technologytoolbox.com

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
    -TrustedComputer TT-HV04A `
    -TrustingComputer TT-FS01 `
    -ServiceType cifs `
    -Add
```

#### # Configure constrained delegation to migrate VMs to other Hyper-V servers

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-KCD.ps1 `
    -TrustedComputer TT-HV04A `
    -TrustingComputer TT-HV04B `
    -ServiceType cifs `
    -Add

C:\NotBackedUp\Public\Toolbox\PowerShell\Set-KCD.ps1 `
    -TrustedComputer TT-HV04A `
    -TrustingComputer TT-HV04B `
    -ServiceType "Microsoft Virtual System Migration Service" `
    -Add

C:\NotBackedUp\Public\Toolbox\PowerShell\Set-KCD.ps1 `
    -TrustedComputer TT-HV04A `
    -TrustingComputer TT-HV04C `
    -ServiceType cifs `
    -Add

C:\NotBackedUp\Public\Toolbox\PowerShell\Set-KCD.ps1 `
    -TrustedComputer TT-HV04A `
    -TrustingComputer TT-HV04C `
    -ServiceType "Microsoft Virtual System Migration Service" `
    -Add
```

#### # Configure constrained delegation for VMs stored on Scale-Out File Server

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-KCD.ps1 `
    -TrustedComputer TT-HV04A `
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

**TT-DPM01 - DPM Management Shell**

```PowerShell
cls
```

### # Attach DPM agent

```PowerShell
$productionServer = 'TT-HV04A'

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

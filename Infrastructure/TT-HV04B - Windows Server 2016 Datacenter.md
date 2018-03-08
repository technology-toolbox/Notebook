# TT-HV04B - Windows Server 2016 Datacenter

Wednesday, March 7, 2018
8:09 AM

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
> Join the **corp.technologytoolbox.com** domain and rename the computer to **TT-HV04B**.

---

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Move computer to "Hyper-V Servers" OU

```PowerShell
$computerName = "TT-HV04B"
$targetPath = ("OU=Hyper-V Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com")
```

### # Add computer to "Hyper-V Servers" domain group

```PowerShell
Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath

Import-Module ActiveDirectory
Add-ADGroupMember -Identity "Hyper-V Servers" -Members TT-HV04B$
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

```PowerShell
cls
```

#### # Configure storage network adapters

##### # Configure static IPv4 addresses

```PowerShell
$interfaceAlias = "Storage 1"
$ipAddress = "10.1.4.3"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24

$interfaceAlias = "Storage 2"
$ipAddress = "10.1.4.4"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24
```

#### # Disable DHCPv6 on storage network adapters

```PowerShell
$interfaceAliases = @(
    "Storage 1",
    "Storage 2")

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

```Console
ipconfig /registerdns
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
    [PSCustomObject] @{ DiskNumber = 2; DriveLetter = "D"; Label = "WD Gold 4TB" },
    [PSCustomObject] @{ DiskNumber = 3; DriveLetter = "E"; Label = "WD SE 3TB" },
    [PSCustomObject] @{ DiskNumber = 1; DriveLetter = "F"; Label = "Samsung 850 Pro 256GB" },
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

![(screenshot)](https://assets.technologytoolbox.com/screenshots/67/037F76D5B111082EC01DB0C049570F9C58319067.png)

##### D: (HDD - WD Gold 4TB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6D/B40FF616BA7D187890384A1FA7908E41F716976D.png)

##### E: (HDD - WD SE 3TB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A1/478AE08EAF7DEC6CD9834CE3965FD59BFA5949A1.png)

##### F: (SSD - Samsung 850 Pro 256GB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B9/6065170A83BB8424AF93E064DF8808601D7AB5B9.png)

##### G: (HDD - Seagate ES.3 2TB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DF/A835A313B5C71C67E4F8FF1377B6474F125143DF.png)

## Prepare infrastructure for Hyper-V installation

### Enable Virtualization in BIOS

Intel Virtualization Technology: **Enabled**

```PowerShell
cls
```

### # Add roles for Hyper-V cluster

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
    where { $_.SerialNumber -ne "*********03705D" } |
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

## # Deploy Hyper-V

### # Configure VM storage

```PowerShell
mkdir C:\ClusterStorage\Volume2\VMs

Set-VMHost -VirtualMachinePath C:\ClusterStorage\Volume2\VMs
```

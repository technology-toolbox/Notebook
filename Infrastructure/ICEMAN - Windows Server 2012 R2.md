# ICEMAN - Windows Server 2012 R2 Standard

Saturday, March 12, 2016
2:54 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Install Windows Server 2012 R2

## Join domain (corp.technologytoolbox.com) and rename computer (TEMP)

```Console
sconfig
```

## Move computer to "Servers" OU

---

**FOOBAR8**

```PowerShell
$computerName = "TEMP"
$targetPath = ("OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com")

Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath
```

---

```Console
PowerShell
```

```Console
cls
```

## # Set time zone

```PowerShell
tzutil /s "Mountain Standard Time"
```

## # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

## # Change drive letter for DVD-ROM

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
```

## # Download PowerShell help files

```PowerShell
Update-Help
```

## # Copy Toolbox content

```PowerShell
robocopy \\ICEMAN\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E
```

```PowerShell
cls
```

## # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter `
    -InterfaceDescription "Realtek PCIe GBE Family Controller" |
    Rename-NetAdapter -NewName "Management"

Get-NetAdapter `
    -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter" |
    Rename-NetAdapter -NewName "Production"

Get-NetAdapter -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter #2" |
    Rename-NetAdapter -NewName "Storage"
```

```PowerShell
cls
```

## # Configure "Management" network adapter

### # Configure static IPv4 address

```PowerShell
$ipAddress = "192.168.10.107"

New-NetIPAddress `
    -InterfaceAlias "Management" `
    -IPAddress $ipAddress `
    -PrefixLength 24 `
    -DefaultGateway 192.168.10.1

Set-DNSClientServerAddress `
    -InterfaceAlias "Management" `
    -ServerAddresses 192.168.10.103,192.168.10.104
```

### # Configure static IPv6 address

```PowerShell
$ipAddress = "2601:282:4201:e500::107"

New-NetIPAddress `
    -InterfaceAlias "Management" `
    -IPAddress $ipAddress `
    -PrefixLength 64

Set-DNSClientServerAddress `
    -InterfaceAlias "Management" `
    -ServerAddresses 2601:282:4201:e500::103,2601:282:4201:e500::104
```

```PowerShell
cls
```

## # Configure "Storage" network adapter

```PowerShell
$ipAddress = "10.1.10.107"

New-NetIPAddress `
    -InterfaceAlias "Storage" `
    -IPAddress $ipAddress `
    -PrefixLength 24

Disable-NetAdapterBinding -Name "Storage" `
    -DisplayName "Client for Microsoft Networks"

Disable-NetAdapterBinding -Name "Storage" `
    -DisplayName "File and Printer Sharing for Microsoft Networks"

Disable-NetAdapterBinding -Name "Storage" `
    -DisplayName "Link-Layer Topology Discovery Mapper I/O Driver"

Disable-NetAdapterBinding -Name "Storage" `
    -DisplayName "Link-Layer Topology Discovery Responder"

$adapter = Get-WmiObject -Class "Win32_NetworkAdapter" `
    -Filter "NetConnectionId = 'Storage'"

$adapterConfig = Get-WmiObject -Class "Win32_NetworkAdapterConfiguration" `
    -Filter "Index= '$($adapter.DeviceID)'"
```

### # Do not register this connection in DNS

```PowerShell
$adapterConfig.SetDynamicDNSRegistration($false)
```

### # Disable NetBIOS over TCP/IP

```PowerShell
$adapterConfig.SetTcpipNetbios(2)
```

```PowerShell
cls
```

## # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name "Management" `
    -DisplayName "Jumbo Frame" -RegistryValue 9216

Set-NetAdapterAdvancedProperty -Name "Production" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Set-NetAdapterAdvancedProperty -Name "Storage" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

ping ICEMAN -f -l 8900
ping 10.1.10.106 -f -l 8900
```

```PowerShell
cls
```

## # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

## # Configure firewall rules for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
New-NetFirewallRule `
    -Name 'Remote Windows Update (Dynamic RPC)' `
    -DisplayName 'Remote Windows Update (Dynamic RPC)' `
    -Description 'Allows remote auditing and installation of Windows updates via POSHPAIG (http://poshpaig.codeplex.com/)' `
    -Group 'Technology Toolbox (Custom)' `
    -Program '%windir%\system32\dllhost.exe' `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort RPC `
    -Profile Domain `
    -Action Allow
```

## # Disable firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
Disable-NetFirewallRule -Name 'Remote Windows Update (Dynamic RPC)'
```

```PowerShell
cls
```

## # Configure storage

### # Physical disks

```PowerShell
Get-PhysicalDisk | select DeviceId, Model, SerialNumber | sort DeviceId
```

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
<p>Model: Samsung Samsung SSD 850 PRO 512GB<br />
Serial number: *********16434V</p>
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
<p>Model: Samsung Samsung SSD 850 PRO 512GB<br />
Serial number: *********14877L</p>
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
<p>3</p>
</td>
<td valign='top'>
<p>Model: ST3000NC002-1DY166<br />
Serial number: *****72Z</p>
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
<p>4</p>
</td>
<td valign='top'>
<p>Model: Seagate WDC WD6401AALS-00E8B0<br />
Serial number: WD-******723459</p>
</td>
<td valign='top'>
<p>640 GB</p>
</td>
<td valign='top'>
<p>C:</p>
</td>
<td valign='top'>
<p>595 GB</p>
</td>
<td valign='top'>
<p>4K</p>
</td>
<td valign='top'>
</td>
</tr>
</table>

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
PhysicalDisk2<br />
PhysicalDisk3</p>
</td>
</tr>
</table>

### Virtual disks

| Name   | Layout | Provisioning | Capacity | SSD Tier | HDD Tier | Volume | Volume Label | Write-Back Cache |
| ------ | ------ | ------------ | -------- | -------- | -------- | ------ | ------------ | ---------------- |
| Data01 | Mirror | Fixed        | 125 GB   | 125 GB   |          | D:     | Data01       |                  |
| Data02 | Mirror | Fixed        | 2.2 TB   | 200 GB   | 2 TB     | E:     | Data02       | 5 GB             |
| Data03 | Simple | Fixed        | 500 GB   |          | 500 GB   | F:     | Data03       | 1 GB             |

```PowerShell
cls
```

### # Create storage pool

```PowerShell
$storageSubSystemUniqueId = Get-StorageSubSystem `
    -FriendlyName "Storage Spaces on TEMP" | select -ExpandProperty UniqueId

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
        -StorageTierSizes 125GB

$hddTier = Get-StorageTier -FriendlyName "HDD Tier"

Get-StoragePool "Pool 1" |
    New-VirtualDisk `
        -FriendlyName "Data02" `
        -ResiliencySettingName Mirror `
        -StorageTiers $ssdTier,$hddTier `
        -StorageTierSizes 200GB,2TB `
        -WriteCacheSize 5GB

Get-StoragePool "Pool 1" |
    New-VirtualDisk `
        -FriendlyName "Data03" `
        -ResiliencySettingName Simple `
        -StorageTiers $hddTier `
        -StorageTierSizes 500GB `
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

## Benchmark storage performance

### Benchmark C: (HDD - Western Digital Black 640 GB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4C/ED5214A23EE875F3B31D882056C920A5724BE84C.png)

### Benchmark D: (Mirror SSD storage space - 2x Samsung 850 512GB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/66/5103A628D1569C3A26F94EC0B3A88B993A54CA66.png)

### Benchmark E: (Mirror SSD/HDD storage space)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DF/2E3575AC866E68D3288200140AB207E826BE47DF.png)

### Benchmark F: (Simple HDD storage space)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2B/1631E433D3FBF90EF8B69895326BFEBD58DEE42B.png)

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

---

**JUGGERNAUT - DPM Management Shell**

### # Attach DPM agent

```PowerShell
$productionServer = "TEMP"

.\Attach-ProductionServer.ps1 `
    -DPMServerName JUGGERNAUT `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `
    -UserName jjameson-admin
```

---

### Reference

**Installing Protection Agents Manually**\
Pasted from <[http://technet.microsoft.com/en-us/library/hh757789.aspx](http://technet.microsoft.com/en-us/library/hh757789.aspx)>

## Copy content from ICEMAN

### Restore Profiles\$ and Users\$ content from DPM backup

| **Recovery setting** | **Value**                                                     |
| -------------------- | ------------------------------------------------------------- |
| Recovery type        | **Recover to alternate location**                             |
| Alternate location   | **E:\\ on TEMP**                                              |
| Restore security     | **Apply the security settings of the recovery point version** |

```PowerShell
cls
```

### # Copy other content from ICEMAN

```PowerShell
robocopy \\ICEMAN\D$\ E:\ /COPYALL /E /NP `
    /XD RECYCLER Recycled "System Volume Information" Profiles$ Users$
```

### Copy registry entries for files shares

---

**ICEMAN**

#### # Export registry entries for file shares on "old" server

```PowerShell
reg export `
    HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Shares `
    C:\NotBackedUp\Temp\LanmanServer-Shares-ICEMAN.reg
```

#### # Copy to "new" server

```PowerShell
copy C:\NotBackedUp\Temp\LanmanServer-Shares-ICEMAN.reg `
    \\TEMP\C$\NotBackedUp\Temp
```

---

#### # Backup registry entries for file shares on "new" server

```PowerShell
reg export `
    HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Shares `
    \NotBackedUp\Temp\LanmanServer-Shares-TEMP.reg
```

#### # Import registry entries for file shares

```PowerShell
reg import C:\NotBackedUp\Temp\LanmanServer-Shares-ICEMAN.reg
```

> **Important**
>
> Using Registry Editor, update drive letters for file shares (e.g. change "Path=**D:**\\Shares\\Archive" to "Path=**E:**\\Shares\\Archive").

## Change IP addresses and rename servers

### Change static IPv4 addresses for "Management" and "Storage" network adapters

> **Note**
>
> New "Management" IP address: **192.168.10.106**\
> New "Storage" IP address: **10.1.10.106**

```Console
sconfig
```

### # Change static IPv6 address for "Management" network adapter

```PowerShell
$oldIpAddress = "2601:282:4201:e500::107"
$newIpAddress = "2601:282:4201:e500::106"
$ifIndex = Get-NetAdapter -InterfaceAlias "Management" |
    Select -ExpandProperty InterfaceIndex

New-NetIPAddress `
    -InterfaceIndex $ifIndex `
    -IPAddress $newIpAddress

Remove-NetIPAddress `
    -InterfaceIndex $ifIndex `
    -IPAddress $oldIpAddress
```

### Rename server

> **Note**
>
> New server name: **ICEMAN**

```Console
sconfig

Restart-Server
```

```Console
cls
```

## # Add DHCP feature

```PowerShell
Install-WindowsFeature DHCP -IncludeManagementTools

Set-DhcpServerv4OptionValue `
    -DNSServer 192.168.10.103,192.168.10.104 `
    -DNSDomain corp.technologytoolbox.com `
    -Router 192.168.10.1

Add-DhcpServerSecurityGroup

Add-DhcpServerv4Scope `
    -Name "Default Scope" `
    -StartRange 192.168.10.2 `
    -EndRange 192.168.10.100 `
    -SubnetMask 255.255.255.0
```

```PowerShell
cls
```

## # Add iSCSI Target feature

```PowerShell
Add-WindowsFeature FS-iSCSITarget-Server -IncludeManagementTools
```

## Install patches using Windows Update

## Resolve DHCP issue with "Production" network adapter

### # Configure "Production" network adapter

#### # Configure static IPv4 address

```PowerShell
$ipAddress = "192.168.10.109"

New-NetIPAddress `
    -InterfaceAlias "Production" `
    -IPAddress $ipAddress `
    -PrefixLength 24 `
    -DefaultGateway 192.168.10.1

Set-DNSClientServerAddress `
    -InterfaceAlias "Production" `
    -ServerAddresses 192.168.10.103,192.168.10.104
```

#### # Configure static IPv6 address

```PowerShell
$ipAddress = "2601:282:4201:e500::109"

New-NetIPAddress `
    -InterfaceAlias "Production" `
    -IPAddress $ipAddress `
    -PrefixLength 64

Set-DNSClientServerAddress `
    -InterfaceAlias "Production" `
    -ServerAddresses 2601:282:4201:e500::103,2601:282:4201:e500::104
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

## Create SMB shares for VM storage

### Create file shares for VM storage

> **Important**
>
> There is a bug in Windows Server 2012 that prevents migrating VM storage when the Everyone group is granted permissions on the share. To avoid this issue, grant **Change Access** on the share to the **TECHTOOLBOX\\Hyper-V Servers** group (instead of **Everyone**).\
> Reference:\
> **Failed Storage Migration - HyperV 2012**\
> From <[https://www.reddit.com/r/HyperV/comments/2xnim4/failed_storage_migration_hyperv_2012/](https://www.reddit.com/r/HyperV/comments/2xnim4/failed_storage_migration_hyperv_2012/)>

```PowerShell
Function CreateVirtualMachineStorageShare($shareName, $path)
{
    $ErrorPreference = "Stop"

    $serverGroup = "TECHTOOLBOX\Hyper-V Servers"

    New-Item -ItemType Directory -Path $path

    # Remove "BUILTIN\Users" permissions

    icacls $path /inheritance:d
    icacls $path /remove:g "BUILTIN\Users"

    # Grant "Hyper-V Servers" group full access to share

    icacls $path /grant ($serverGroup + ':(OI)(CI)(F)')

    New-SmbShare `
        -Name $shareName `
        -Path $path `
        -CachingMode None `
        -FullAccess Administrators, $serverGroup
}
```

#### # Create share for "Gold" storage

```PowerShell
$shareName = "VM-Storage-Gold"
$path = "D:\NotBackedUp\$shareName"

CreateVirtualMachineStorageShare $shareName $path
```

#### # Create share for "Silver" storage

```PowerShell
$shareName = "VM-Storage-Silver"
$path = "E:\NotBackedUp\$shareName"

CreateVirtualMachineStorageShare $shareName $path
```

#### # Create share for "Bronze" storage

```PowerShell
$shareName = "VM-Storage-Bronze"
$path = "F:\NotBackedUp\$shareName"

CreateVirtualMachineStorageShare $shareName $path
```

### Configure constrained delegation

---

**FOOBAR8**

```PowerShell
Enable-SmbDelegation -SmbServer ICEMAN -SmbClient STORM
```

---

```PowerShell
cls
```

## # Migrate VM storage

---

**FOOBAR8**

```PowerShell
cls
```

### # Migrate storage for VM - CYCLOPS-TEST

```PowerShell
$storagePath = '\\ICEMAN.corp.technologytoolbox.com\VM-Storage-Silver'

Move-VMStorage `
    -ComputerName STORM `
    -VMName CYCLOPS-TEST `
    -DestinationStoragePath ($storagePath + '\CYCLOPS-TEST')
```

### # Migrate storage for VM - DEVOPS2012

```PowerShell
Move-VMStorage `
    -ComputerName STORM `
    -VMName DEVOPS2012 `
    -DestinationStoragePath ($storagePath + '\DEVOPS2012')
```

### # Migrate storage for VM - EXT-DC01

```PowerShell
Move-VMStorage `
    -ComputerName STORM `
    -VMName EXT-DC01 `
    -DestinationStoragePath ($storagePath + '\EXT-DC01')
```

### # Migrate storage for VM - FAB-DC01

```PowerShell
Move-VMStorage `
    -ComputerName STORM `
    -VMName FAB-DC01 `
    -DestinationStoragePath ($storagePath + '\FAB-DC01')
```

### # Migrate storage for VM - FAB-WEB01

```PowerShell
Move-VMStorage `
    -ComputerName STORM `
    -VMName FAB-WEB01 `
    -DestinationStoragePath ($storagePath + '\FAB-WEB01')
```

### # Migrate storage for VM - FOOBAR

```PowerShell
Move-VMStorage `
    -ComputerName STORM `
    -VMName FOOBAR `
    -DestinationStoragePath ($storagePath + '\FOOBAR')
```

### # Migrate storage for VM - POLARIS-DEV

```PowerShell
Move-VMStorage `
    -ComputerName STORM `
    -VMName POLARIS-DEV `
    -DestinationStoragePath ($storagePath + '\POLARIS-DEV')
```

### # Migrate storage for VM - CIPHER01

```PowerShell
Move-VMStorage `
    -ComputerName BEAST `
    -VMName CIPHER01 `
    -DestinationStoragePath ($storagePath + '\CIPHER01')
```

### # Migrate storage for VM - EXT-RRAS1

```PowerShell
Move-VMStorage `
    -ComputerName BEAST `
    -VMName EXT-RRAS1 `
    -DestinationStoragePath ($storagePath + '\EXT-RRAS1')
```

### # Migrate storage for VM - FAB-FOOBAR4

```PowerShell
Move-VMStorage `
    -ComputerName BEAST `
    -VMName FAB-FOOBAR4 `
    -DestinationStoragePath ($storagePath + '\FAB-FOOBAR4')
```

### # Migrate storage for VM - FOOBAR7

```PowerShell
Move-VMStorage `
    -ComputerName BEAST `
    -VMName FOOBAR7 `
    -DestinationStoragePath ($storagePath + '\FOOBAR7')
```

---

**TODO:**

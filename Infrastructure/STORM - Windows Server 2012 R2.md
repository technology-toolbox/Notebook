﻿# STORM - Windows Server 2012 R2 Standard

Monday, January 25, 2016
2:54 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Install Windows Server 2012 R2

## Rename computer and join domain

```Console
sconfig
```

## Move computer to "Hyper-V Servers" OU

---

**FOOBAR8**

```PowerShell
$computerName = "STORM"
$targetPath = ("OU=Hyper-V Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com")

Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath
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

## # Change drive letter for DVD-ROM

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
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
    -InterfaceDescription "Intel(R) 82574L Gigabit Network Connection" |
    Rename-NetAdapter -NewName "Management"

Get-NetAdapter `
    -InterfaceDescription "Intel(R) 82579LM Gigabit Network Connection" |
    Rename-NetAdapter -NewName "Production"

Get-NetAdapter -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter" |
    Rename-NetAdapter -NewName "Storage"
```

```PowerShell
cls
```

## # Configure "Management" network adapter

### # Configure static IPv4 address

```PowerShell
$ipAddress = "192.168.10.108"

New-NetIPAddress `
    -InterfaceAlias "Management" `
    -IPAddress $ipAddress `
    -PrefixLength 24 `
    -DefaultGateway 192.168.10.1

Set-DNSClientServerAddress `
    -InterfaceAlias "Management" `
    -ServerAddresses 192.168.10.104,192.168.10.103
```

### # Configure static IPv6 address

```PowerShell
$ipAddress = "2601:282:4201:e500::108"

New-NetIPAddress `
    -InterfaceAlias "Management" `
    -IPAddress $ipAddress `
    -PrefixLength 64

Set-DNSClientServerAddress `
    -InterfaceAlias "Management" `
    -ServerAddresses 2601:282:4201:e500::104,2601:282:4201:e500::103
```

```PowerShell
cls
```

## # Configure "Management" network adapter

```PowerShell
Disable-NetAdapterBinding -Name "Production" `
    -DisplayName "Client for Microsoft Networks"

Disable-NetAdapterBinding -Name "Production" `
    -DisplayName "File and Printer Sharing for Microsoft Networks"

Disable-NetAdapterBinding -Name "Production" `
    -DisplayName "Link-Layer Topology Discovery Mapper I/O Driver"

Disable-NetAdapterBinding -Name "Production" `
    -DisplayName "Link-Layer Topology Discovery Responder"

$adapter = Get-WmiObject -Class "Win32_NetworkAdapter" `
    -Filter "NetConnectionId = 'Production'"

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

## # Configure "Storage" network adapter

```PowerShell
$ipAddress = "10.1.10.108"

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
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Set-NetAdapterAdvancedProperty -Name "Production" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Set-NetAdapterAdvancedProperty -Name "Storage" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

ping ICEMAN -f -l 8900
ping 10.1.10.106 -f -l 8900
```

Note: Trying to ping ICEMAN or the iSCSI network adapter on ICEMAN with a 9000 byte packet from BEAST resulted in an error (suggesting that jumbo frames were not configured). It also worked with 8970 bytes.

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

## Enable Virtualization in BIOS

Intel Virtualization Technology: **Enabled**

```PowerShell
cls
```

## # Add Hyper-V role

```PowerShell
Install-WindowsFeature `
    -Name Hyper-V `
    -IncludeManagementTools `
    -Restart
```

## # Download PowerShell help files (for Hyper-V cmdlets)

```PowerShell
Update-Help
```

```PowerShell
cls
```

## # Create virtual switches

```PowerShell
New-VMSwitch `
    -Name "Production" `
    -NetAdapterName "Production" `
    -AllowManagementOS $true

New-VMSwitch `
    -Name "Storage" `
    -NetAdapterName "Storage" `
    -AllowManagementOS $true
```

```PowerShell
cls
```

## # Enable jumbo frames on virtual switches

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name "vEthernet (Production)" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Set-NetAdapterAdvancedProperty `
    -Name "vEthernet (Storage)" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

ping ICEMAN -f -l 8900
ping 10.1.10.106 -f -l 8900
```

```PowerShell
cls
```

## # Modify "Production" and "Storage" virtual switches to disallow management OS

```PowerShell
Get-VMSwitch "Production" |
    Set-VMSwitch -AllowManagementOS $false

Get-VMSwitch "Storage" |
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
<p>1</p>
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
| Data01 | Mirror | Fixed        | 125 GB   | 125 GB   |          | D:     | Data01       |                  |
| Data02 | Mirror | Fixed        | 700 GB   | 200 GB   | 500 GB   | E:     | Data02       | 5 GB             |
| Data03 | Simple | Fixed        | 200 GB   |          | 200 GB   | F:     | Data03       | 1 GB             |

```PowerShell
cls
```

### # Create storage pool

```PowerShell
$storageSubSystemUniqueId = Get-StorageSubSystem `
    -FriendlyName "Storage Spaces on STORM" | select -ExpandProperty UniqueId

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
        -StorageTierSizes 200GB,500GB `
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

## Benchmark storage performance

### Benchmark C: (SSD - Samsung 850 Pro 128GB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0C/EA8C629095523D0CF0C88B9D6AEB08B729772D0C.png)

### Benchmark D: (Mirror SSD storage space - 2x Samsung 840 512GB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3C/FA049D8B5BD2DE10A5174B037923D27E07AF0C3C.png)

### Benchmark E: (Mirror SSD/HDD storage space)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5F/BFEFC0258A705B18A95939C9EB07CCB1A8075D5F.png)

### Benchmark F: (Simple HDD storage space)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/88/D4BE461147A604A22BD43FE4B4DDAF2597417688.png)

```PowerShell
cls
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

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5E/AD85D8814AE85E1B2E8FC6544B7F10881939535E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C0/7D57372A9F2C4599B1E8C9C68FED9A6D2D6DD1C0.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/97/A795AEE3AF6234B0FCCDB35A944B7B9C9D7ACA97.png)

Click Add...

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8D/18818661BC0C359C33EE49E6F3341FAAF867998D.png)

Click Users or Computers...

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A9/8654E4EB4BCDED7D97C922ACD01D131EE50A9FA9.png)

Click OK.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/65/014B30411E0CCCA9773E8A8F094CB221AAEEC465.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B2/8ADDCBFE162FE1FEC1348BD0F8E59018BA685DB2.png)

Click OK.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7F/5C396AC2F25DB666ABDBBA361383898FBAD04F7F.png)

### # Configure the server for live migration

```PowerShell
Enable-VMMigration

Add-VMMigrationNetwork 192.168.10.108

Set-VMHost -VirtualMachineMigrationAuthenticationType Kerberos
```

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

## Migrate virtual machines to STORM

---

**FOOBAR**

### # Note: BANSHEE was already shutdown

```PowerShell
Move-VM `
    -ComputerName ROGUE `
    -Name BANSHEE `
    -DestinationHost STORM `
    -IncludeStorage `
    -DestinationStoragePath E:\NotBackedUp\VMs\BANSHEE
```

```PowerShell
cls
```

### # Note: Must shutdown the VM first since the processors are not compatible

```PowerShell
Stop-VM -ComputerName ROGUE -Name EXT-DC01

Move-VM `
    -ComputerName ROGUE `
    -Name EXT-DC01 `
    -DestinationHost STORM `
    -IncludeStorage `
    -DestinationStoragePath E:\NotBackedUp\VMs\EXT-DC01

Start-VM -ComputerName STORM -Name EXT-DC01
```

```PowerShell
cls
```

### # Note: Must shutdown the VM first since the processors are not compatible

```PowerShell
Stop-VM -ComputerName ROGUE -Name EXT-SQL01A

Move-VM `
    -ComputerName ROGUE `
    -Name EXT-SQL01A `
    -DestinationHost STORM `
    -IncludeStorage `
    -DestinationStoragePath E:\NotBackedUp\VMs\EXT-SQL01A

Start-VM -ComputerName STORM -Name EXT-SQL01A
```

```PowerShell
cls
```

### # Note: Must shutdown the VM first since the processors are not compatible

```PowerShell
Stop-VM -ComputerName ROGUE -Name FAB-DC01

Move-VM `
    -ComputerName ROGUE `
    -Name FAB-DC01 `
    -DestinationHost STORM `
    -IncludeStorage `
    -DestinationStoragePath E:\NotBackedUp\VMs\FAB-DC01

Start-VM -ComputerName STORM -Name FAB-DC01
```

```PowerShell
cls
```

### # Note: FOOBAR was already shutdown

```PowerShell
Move-VM `
    -ComputerName ROGUE `
    -Name FOOBAR `
    -DestinationHost STORM `
    -IncludeStorage `
    -DestinationStoragePath E:\NotBackedUp\VMs\FOOBAR
```

```PowerShell
cls
```

### # Note: Must shutdown the VM first since the processors are not compatible

```PowerShell
Stop-VM -ComputerName ROGUE -Name XAVIER1

Move-VM `
    -ComputerName ROGUE `
    -Name XAVIER1 `
    -DestinationHost STORM `
    -IncludeStorage `
    -DestinationStoragePath E:\NotBackedUp\VMs\XAVIER1

Start-VM -ComputerName STORM -Name XAVIER1
```

---

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

```Console
cls
```

## # Enable SMB Multichannel

### # Modify "Production" virtual switch to allow management OS

```PowerShell
Get-VMSwitch "Production" |
    Set-VMSwitch -AllowManagementOS $true
```

## # Configure NIC teaming

```PowerShell
Get-NetAdapter -Physical

Get-NetIPAddress | select InterfaceIndex, InterfaceAlias, IPAddress | sort InterfaceIndex
```

```PowerShell
cls
```

### # Disconnect virtual switches from network adapters

```PowerShell
Get-VMSwitch | Set-VMSwitch -AllowManagementOS:$false

Get-VMSwitch | Set-VMSwitch -SwitchType Private
```

### # Rename network connections

```PowerShell
Get-NetAdapter `
    -InterfaceDescription "Intel(R) 82574L Gigabit Network Connection" |
        Rename-NetAdapter -NewName "Ethernet"

Get-NetAdapter `
    -InterfaceDescription "Intel(R) 82579LM Gigabit Network Connection" |
        Rename-NetAdapter -NewName "Ethernet 2"
```

```PowerShell
cls
```

### # Configure "Ethernet" network adapter

```PowerShell
$interfaceAlias = "Ethernet"
```

#### # Remove static IP addresses

```PowerShell
Get-NetAdapter $interfaceAlias | Remove-NetIPAddress -Confirm:$false
```

#### # Enable DHCP

```PowerShell
@("IPv4", "IPv6") | ForEach-Object {
    $addressFamily = $_

    $interface = Get-NetAdapter $interfaceAlias |
        Get-NetIPInterface -AddressFamily $addressFamily

    If ($interface.Dhcp -eq "Disabled")
    {
        # Remove existing gateway
        $ipConfig = $interface | Get-NetIPConfiguration

        If ($ipConfig.Ipv4DefaultGateway -or $ipConfig.Ipv6DefaultGateway)
        {
            $interface | Remove-NetRoute -Confirm:$false
        }

        # Enable DHCP
        $interface | Set-NetIPInterface -DHCP Enabled

        # Configure the  DNS Servers automatically
        $interface | Set-DnsClientServerAddress -ResetServerAddresses
    }
}

ipconfig /renew
```

```PowerShell
cls
```

#### # Configure network adapter properties

```PowerShell
Enable-NetAdapterBinding `
    -Name $interfaceAlias `
    -DisplayName "Client for Microsoft Networks"

Enable-NetAdapterBinding `
    -Name $interfaceAlias `
    -DisplayName "File and Printer Sharing for Microsoft Networks"

Enable-NetAdapterBinding `
    -Name $interfaceAlias `
    -DisplayName "Link-Layer Topology Discovery Mapper I/O Driver"

Enable-NetAdapterBinding `
    -Name $interfaceAlias `
    -DisplayName "Link-Layer Topology Discovery Responder"

$adapter = Get-WmiObject `
    -Class "Win32_NetworkAdapter" `
    -Filter ("NetConnectionId = '" + $interfaceAlias + "'")

$adapterConfig = Get-WmiObject `
    -Class "Win32_NetworkAdapterConfiguration" `
    -Filter "Index= '$($adapter.DeviceID)'"

# Register this connection in DNS
$adapterConfig.SetDynamicDNSRegistration($true)

# Use NetBIOS setting from the DHCP server
$adapterConfig.SetTcpipNetbios(0)
```

```PowerShell
cls
```

### # Configure "Ethernet 2" network adapter

```PowerShell
$interfaceAlias = "Ethernet 2"
```

#### # Remove static IP addresses

```PowerShell
Get-NetAdapter $interfaceAlias | Remove-NetIPAddress -Confirm:$false
```

#### # Enable DHCP

```PowerShell
@("IPv4", "IPv6") | ForEach-Object {
    $addressFamily = $_

    $interface = Get-NetAdapter $interfaceAlias |
        Get-NetIPInterface -AddressFamily $addressFamily

    If ($interface.Dhcp -eq "Disabled")
    {
        # Remove existing gateway
        If (($interface | Get-NetIPConfiguration).Ipv4DefaultGateway)
        {
            $interface | Remove-NetRoute -Confirm:$false
        }

        If (($interface | Get-NetIPConfiguration).Ipv6DefaultGateway)
        {
            $interface | Remove-NetRoute -Confirm:$false
        }

        # Enable DHCP
        $interface | Set-NetIPInterface -DHCP Enabled

        # Configure the  DNS Servers automatically
        $interface | Set-DnsClientServerAddress -ResetServerAddresses
    }
}

ipconfig /renew
```

```PowerShell
cls
```

#### # Configure network adapter properties

```PowerShell
Enable-NetAdapterBinding `
    -Name $interfaceAlias `
    -DisplayName "Client for Microsoft Networks"

Enable-NetAdapterBinding `
    -Name $interfaceAlias `
    -DisplayName "File and Printer Sharing for Microsoft Networks"

Enable-NetAdapterBinding `
    -Name $interfaceAlias `
    -DisplayName "Link-Layer Topology Discovery Mapper I/O Driver"

Enable-NetAdapterBinding `
    -Name $interfaceAlias `
    -DisplayName "Link-Layer Topology Discovery Responder"

$adapter = Get-WmiObject `
    -Class "Win32_NetworkAdapter" `
    -Filter ("NetConnectionId = '" + $interfaceAlias + "'")

$adapterConfig = Get-WmiObject `
    -Class "Win32_NetworkAdapterConfiguration" `
    -Filter "Index= '$($adapter.DeviceID)'"

# Register this connection in DNS
$adapterConfig.SetDynamicDNSRegistration($true)

# Use NetBIOS setting from the DHCP server
$adapterConfig.SetTcpipNetbios(0)
```

```PowerShell
cls
```

### # Configure "Storage" network adapter

```PowerShell
$interfaceAlias = "Storage"
```

#### # Configure static IPv4 address

```PowerShell
$ipAddress = "10.1.10.108"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24
```

#### # Configure network adapter properties

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
    -Filter ("NetConnectionId = '" + $interfaceAlias + "'")

$adapterConfig = Get-WmiObject `
    -Class "Win32_NetworkAdapterConfiguration" `
    -Filter "Index= '$($adapter.DeviceID)'"

# Do not register this connection in DNS
$adapterConfig.SetDynamicDNSRegistration($false)

# Disable NetBIOS over TCP/IP
$adapterConfig.SetTcpipNetbios(2)
```

```PowerShell
cls
```

### # Create and configure NIC team

#### # Create NIC team

```PowerShell
$interfaceAlias = "Production"

New-NetLbfoTeam -Name $interfaceAlias -TeamMembers "Ethernet", "Ethernet 2"
```

```PowerShell
cls
```

#### # Configure static IPv4 address

```PowerShell
$ipAddress = "192.168.10.108"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24 `
    -DefaultGateway 192.168.10.1

Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 192.168.10.104,192.168.10.103
```

#### # Configure static IPv6 address

```PowerShell
$ipAddress = "2601:282:4201:e500::108"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress

Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 2601:282:4201:e500::104, 2601:282:4201:e500::103
```

```PowerShell
cls
```

### # Connect virtual switches to network adapters

```PowerShell
Get-VMSwitch Storage | Set-VMSwitch -NetAdapterName Storage -AllowManagementOS $true

Get-VMSwitch Production |
    Set-VMSwitch -NetAdapterName Production -AllowManagementOS $true
```

```PowerShell
cls
```

### # Enable jumbo frames on virtual switches

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name "vEthernet (Production)" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Set-NetAdapterAdvancedProperty `
    -Name "vEthernet (Storage)" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

ping ICEMAN -f -l 8900
ping 10.1.10.106 -f -l 8900
```

## Swap "Production" Team NIC

> **Note**
>
> Port statistics on Netgear GS724T show a high number of **Packets received with Errors** on port **g15** (i.e. **Intel 82579LM**) -- so disconnect the motherboard network adapter and replace it with an Intel Gigabit CT Desktop Adapter.

```PowerShell
Get-NetAdapter -Physical
```

### # Rename network connections

```PowerShell
Get-NetAdapter `
    -InterfaceDescription "Intel(R) 82579LM Gigabit Network Connection" |
        Rename-NetAdapter -NewName "Questionable NIC"

Get-NetAdapter `
    -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter #2" |
        Rename-NetAdapter -NewName "Ethernet 2"
```

```PowerShell
cls
```

### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name "Ethernet 2" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014
```

```PowerShell
cls
```

### # Replace NIC team member

#### # Remove "bad" NIC

```PowerShell
$interfaceAlias = "Production"

Get-NetLbfoTeam -Name $interfaceAlias |
    Get-NetLbfoTeamMember |
    ? { $_.Name -eq "Questionable NIC" } |
    Remove-NetLbfoTeamMember
```

```PowerShell
cls
```

#### # Add replacement NIC to team

```PowerShell
Add-NetLbfoTeamMember -Name "Ethernet 2" -Team $interfaceAlias
```

**TODO:**
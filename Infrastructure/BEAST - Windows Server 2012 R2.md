# BEAST - Windows Server 2012 R2 Standard

Saturday, January 30, 2016
4:30 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Install Windows Server 2012 R2

## Configure static IPv4 address

```Console
sconfig
```

Interface Description: **Intel(R) I210 Gigabit Network Connection**\
IP Address: **192.168.10.101**\
Subnet Mask: **255.255.255.0**\
Default Gateway: **192.168.10.1**\
Primary DNS Server: **192.168.10.103**\
Secondary DNS Server: **192.168.10.104**

## Join domain and rename computer

```Console
sconfig
```

## Move computer to "Hyper-V Servers" OU

---

**FOOBAR8**

```PowerShell
$computerName = "BEAST"
$targetPath = ("OU=Hyper-V Servers,OU=Servers,OU=Resources,OU=IT" `
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

## # Download PowerShell help files

```PowerShell
Update-Help
```

## # Copy Toolbox content

```PowerShell
robocopy \\ICEMAN\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E
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
Get-NetAdapter `
    -InterfaceDescription "Intel(R) I210 Gigabit Network Connection" |
    Rename-NetAdapter -NewName "Production"

Get-NetAdapter `
    -InterfaceDescription "Intel(R) I210 Gigabit Network Connection #2" |
    Rename-NetAdapter -NewName "Storage"

Get-NetAdapter -Physical
```

```PowerShell
cls
```

## # Configure static IPv6 address

```PowerShell
$ipAddress = "2601:282:4201:e500::101"

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

## # Configure iSCSI network adapter

```PowerShell
$ipAddress = "10.1.10.101"

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

Intel Virtualization Technology: **Enable**

```Console
PowerShell
```

```Console
cls
```

## # Add Hyper-V role

```PowerShell
Install-WindowsFeature `
    -Name Hyper-V `
    -IncludeManagementTools `
    -Restart

PowerShell
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
<p>3</p>
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
<p>4</p>
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
    -FriendlyName "Storage Spaces on BEAST" | select -ExpandProperty UniqueId

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

### # Set media type on HDD drives

```PowerShell
Get-StoragePool "Pool 1" |
    Get-PhysicalDisk |
    ? { $_.MediaType -eq 'UnSpecified' } |
    Set-PhysicalDisk -MediaType HDD
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

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0B/6BB9B0DD6AEEBAFB164687BBE2CCB1758D657B0B.png)

### Benchmark D: (Mirror SSD storage space - 2x Samsung 850 Pro 512GB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7E/E9B61883FBDCEC86AECCF6E3929F3B4819B6167E.png)

### Benchmark E: (Mirror SSD/HDD storage space)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D2/155079652545841BA61131793D45DF8EA64903D2.png)

### Benchmark F: (Simple HDD storage space)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/77/0062D8E9B43A59AF1250F05BA0C9948154721377.png)

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

### Configure constrained delegation in Active Directory

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3C/E9A44C534EBF2F82D4B589C8ADA77606660D633C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9A/AD77A31B7028F9A29019A98041708C4476B8219A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F8/A8AD54C8C867D0C401D142BA636275E4BF2A38F8.png)

Click Add...

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8D/18818661BC0C359C33EE49E6F3341FAAF867998D.png)

Click Users or Computers...

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D9/8C4D5407890ED0A5291966F89368D6967C2B76D9.png)

Click OK.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C3/C8723FDA8328DE8756E01D9D50B4036435F276C3.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7E/D1A6D847BA13DB0490AD482B992ED18E64F5B57E.png)

Click OK.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AF/BA474ABE58D25D0AEA7E9D1D2C3CFB4627C4C1AF.png)

### # Configure the server for live migration

```PowerShell
Enable-VMMigration

Add-VMMigrationNetwork 192.168.10.101

Set-VMHost -VirtualMachineMigrationAuthenticationType Kerberos
```

### Reference

**Configure Live Migration and Migrating Virtual Machines without Failover Clustering**\
Pasted from <[http://technet.microsoft.com/en-us/library/jj134199.aspx](http://technet.microsoft.com/en-us/library/jj134199.aspx)>

```PowerShell
cls
```

## # Install and configure System Center Operations Manager

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
$productionServer = "BEAST"

.\Attach-ProductionServer.ps1 `
    -DPMServerName JUGGERNAUT `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `-UserName jjameson-admin
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

## Poor write performance on mirrored Samsung 850 SSDs

### Before

#### BEAST

- C: (128 GB Samsung 850 SSD) - Write Transfer Rate 27,000 - 476,000 MB/s
- D: (2x 512 GB Samsung 850 SSDs) - Write Transfer Rate 200 - 209,000 MB/s

![(screenshot)](https://assets.technologytoolbox.com/screenshots/13/2815E2C89342511750F81704256C9103786C5813.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E2/AA392A1B9D02D8C42A2DD588D5AED6378678D8E2.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/21/7430280DD491F23732D5F8E0658B11B7BC105C21.png)

#### STORM (for comparison)

- C: (128 GB Samsung 850 SSD) - Write Transfer Rate 29,000 - 475,000 MB/s
- D: (2x 512 GB Samsung 840 SSDs) - Write Transfer Rate 11,000 - 155,000 MB/s

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B9/5F016E2CE7959A13764661F53F7FA50CAB4FC8B9.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/92/E85DBFF5ED3F4E88CA202F1E7A016EF74635D492.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/93/FCF2AE9EFC523E15210AF594B30E390CE352FD93.png)

### Update AHCI drivers

1. Download the latest AHCI drivers from the Intel website:\
   **Intel® RSTe AHCI & SCU Software RAID driver for Windows**\
   From <[https://downloadcenter.intel.com/download/25393/Intel-RSTe-AHCI-SCU-Software-RAID-driver-for-Windows-](https://downloadcenter.intel.com/download/25393/Intel-RSTe-AHCI-SCU-Software-RAID-driver-for-Windows-)>
2. Extract the drivers and copy the files to a temporary location on the server:
3. Install the drivers for the **Intel(R) C600+/C220+ series chipset SATA AHCI Controller (PCI\\VEN_8086&DEV_8D02&...)**:
4. Install the drivers for the **Intel(R) C600+/C220+ series chipset sSATA AHCI Controller (PCI\\VEN_8086&DEV_8D62&...)**:
5. Restart the server.

```Console
    robocopy "C:\NotBackedUp\Temp\Drivers\Intel\RSTe AHCI & SCU Software RAID driver for Windows\Drivers\x64\Win8_10_2K8R2_2K12\AHCI" '\\BEAST\C$\NotBackedUp\Temp\Drivers\Intel\x64\Win8_10_2K8R2_2K12\AHCI' /E
```

```Console
    pnputil -i -a C:\NotBackedUp\Temp\Drivers\Intel\x64\Win8_10_2K8R2_2K12\AHCI\iaAHCI.inf
```

```Console
    pnputil -i -a C:\NotBackedUp\Temp\Drivers\Intel\x64\Win8_10_2K8R2_2K12\AHCI\iaAHCIB.inf
```

### After

#### BEAST

- C: (128 GB Samsung 850 SSD) - Write Transfer Rate 46,000 - 476,000 MB/s
- D: (2x 512 GB Samsung 850 SSDs) - Write Transfer Rate 200 - 209,000 MB/s

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1F/CB6B49C5DD99A0FFD035DB8F5249FBB515ADA61F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/65/D7AB59E2302364312BED56884C383F61AF8DAA65.png)

### Summary

| Transfer Size [KB] | Before  | (Microsoft driver) | After   | (Intel driver) | %     | Change |
| ------------------ | ------- | ------------------ | ------- | -------------- | ----- | ------ |
|                    | Write   | Read               | Write   | Read           | Write | Read   |
| 0.5                | 198     | 8,320              | 19,359  | 10,163         | 9,677 | 22     |
| 1                  | 424     | 12,298             | 41,984  | 22,415         | 9,802 | 82     |
| 2                  | 886     | 29,329             | 74,926  | 44,943         | 8,357 | 53     |
| 4                  | 2,021   | 67,108             | 179,400 | 83,887         | 8,777 | 25     |
| 8                  | 2,995   | 128,548            | 256,745 | 192,168        | 8,472 | 49     |
| 16                 | 4,641   | 227,721            | 332,309 | 281,999        | 7,060 | 24     |
| 32                 | 7,820   | 413,863            | 349,308 | 475,576        | 4,367 | 15     |
| 64                 | 15,240  | 574,532            | 316,007 | 531,313        | 1,974 | -8     |
| 128                | 29,454  | 693,454            | 285,500 | 713,437        | 869   | 3      |
| 256                | 53,173  | 901,876            | 333,138 | 849,602        | 527   | -6     |
| 512                | 107,589 | 1,055,274          | 357,913 | 977,313        | 233   | -7     |
| 1024               | 153,684 | 1,061,256          | 357,913 | 1,004,122      | 133   | -5     |
| 2048               | 189,483 | 1,107,622          | 359,511 | 1,020,182      | 90    | -8     |
| 4096               | 201,452 | 1,089,117          | 387,166 | 967,916        | 92    | -11    |
| 8192               | 209,306 | 1,102,271          | 375,434 | 982,080        | 79    | -11    |

**TODO:**

# TT-HV03 - Windows Server 2016

Monday, January 30, 2017
4:39 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

### Install Windows Server 2016 Datacenter Edition ("Server Core")

### Login as local administrator account

### Rename computer and join domain

```Console
sconfig
```

> **Note**
>
> Rename the computer to **TT-HV03** and join the **corp.technologytoolbox.com** domain.

### Install latest patches using Windows Update

```Console
sconfig
```

---

**FOOBAR8** - Run as administrator

```PowerShell
cls
```

### # Move computer to "Hyper-V Servers" OU

```PowerShell
$computerName = "TT-HV03"
$targetPath = ("OU=Hyper-V Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com")
```

### # Add computer to "Hyper-V Servers" domain group

```PowerShell
Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath

Import-Module ActiveDirectory
Add-ADGroupMember -Identity "Hyper-V Servers" -Members TT-HV03$
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

Get-NetAdapter -InterfaceDescription "Realtek PCIe GBE Family Controller" |
    Rename-NetAdapter -NewName "Management"

Get-NetAdapter `
    -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter" |
    Rename-NetAdapter -NewName "Team 1A"

Get-NetAdapter `
    -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter #2" |
    Rename-NetAdapter -NewName "Team 1B"
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name "Management" `
    -DisplayName "Jumbo Frame" -RegistryValue 9216

Set-NetAdapterAdvancedProperty -Name "Team 1A" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Set-NetAdapterAdvancedProperty -Name "Team 1B" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

ping TT-FS01 -f -l 8900
```

```PowerShell
cls
```

#### # Verify SMB Multichannel is working as expected

```PowerShell
$source = "\\TT-FS01\Products\Microsoft\Windows Server 2016"
$destination = "C:\NotBackedUp\Products\Microsoft\Windows Server 2016"

robocopy $source $destination en_windows_server_2016_x64_dvd_9718492.iso
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
<p>Model: Samsung SSD 850 PRO 512GB<br />
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
<p>Model: WDC WD4002FYYZ-01B7CB0<br />
Serial number: *****03Y</p>
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
<p>Model: WDC WD6401AALS-00E8B0<br />
Serial number: WD-******723459</p>
</td>
<td valign='top'>
<p>640 GB</p>
</td>
<td valign='top'>
<p>C:</p>
</td>
<td valign='top'>
<p>596 GB</p>
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
PhysicalDisk1<br />
PhysicalDisk3<br />
PhysicalDisk4</p>
</td>
</tr>
</table>

#### Virtual disks

| Name   | Layout | Provisioning | Capacity | SSD Tier | HDD Tier | Volume | Volume Label | Write-Back Cache |
| ------ | ------ | ------------ | -------- | -------- | -------- | ------ | ------------ | ---------------- |
| Data01 | Mirror | Fixed        | 4.1 TB   | 470 GB   | 3724 GB  | D:     | Data01       | 5 GB             |

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
    (Get-PhysicalDisk -SerialNumber *********16434V),
    (Get-PhysicalDisk -SerialNumber *********14877L),
    (Get-PhysicalDisk -SerialNumber *****03Y),
    (Get-PhysicalDisk -SerialNumber *****0RY))

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
$hddTier = Get-StorageTier -FriendlyName "HDD Tier"

Get-StoragePool "Pool 1" |
    New-VirtualDisk `
        -FriendlyName "Data01" `
        -ResiliencySettingName Mirror `
        -StorageTiers $ssdTier, $hddTier `
        -StorageTierSizes 470GB, 3724GB `
        -WriteCacheSize 5GB
```

```PowerShell
cls
```

#### # Create partitions and volumes

##### # Create volume "D" on Data01

```PowerShell
Get-VirtualDisk "Data01" | Get-Disk | Set-Disk -IsReadOnly 0

Get-VirtualDisk "Data01"| Get-Disk | Set-Disk -IsOffline 0

Get-VirtualDisk "Data01"| Get-Disk | Initialize-Disk -PartitionStyle GPT

Get-VirtualDisk "Data01"| Get-Disk |
    New-Partition -DriveLetter "D" -UseMaximumSize

Initialize-Volume `
    -DriveLetter "D" `
    -FileSystem ReFS `
    -NewFileSystemLabel "Data01" `
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

##### C: (HDD - Western Digital 640 GB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6F/D3394F70F2011A00BB61F6B1C975AF2235740C6F.png)

##### D: (Mirror SSD/HDD storage space)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/59/14C906ADCEF453E8FC8786FAC1FF3D233B6C2359.png)

## Prepare infrastructure for Hyper-V installation

### Enable Virtualization in BIOS

Intel Virtualization Technology: **Enabled**

```PowerShell
cls
```

### # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

### # Add Hyper-V role

```PowerShell
Install-WindowsFeature `
    -Name Hyper-V `
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

## # Deploy Hyper-V

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
Tenant 1                   9014 Bytes
Datacenter 1               9KB MTU
Tenant 2                   9014 Bytes

Set-NetAdapterAdvancedProperty `
    -Name "vEthernet (Tenant vSwitch)" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*" | select Name, DisplayValue

Name                       DisplayValue
----                       ------------
vEthernet (Tenant vSwitch) 9014 Bytes
Tenant 1                   9014 Bytes
Datacenter 1               9KB MTU
Tenant 2                   9014 Bytes


ping TT-FS01 -f -l 8900 -S $vSwitchIpAddress
```

```PowerShell
cls
```

### # Configure VM storage

```PowerShell
mkdir D:\NotBackedUp\VMs

Set-VMHost -VirtualMachinePath D:\NotBackedUp\VMs
```

---

**FOOBAR8** - Run as administrator

```PowerShell
cls
```

### # Configure constrained delegation in Active Directory

#### # Configure constrained delegation to mount ISO images to VMs

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-KCD.ps1 `
    -TrustedComputer TT-HV03 `
    -TrustingComputer TT-FS01 `
    -ServiceType cifs `
    -Add
```

---

```PowerShell
cls
```

## # Prepare infrastructure for scale-out file server installation

### # Add iSCSI Target feature

```PowerShell
Install-WindowsFeature FS-iSCSITarget-Server -IncludeManagementTools
```

```PowerShell
cls
```

### # Create Hyper-V virtual switches for iSCSI storage

```PowerShell
New-VMSwitch -Name "Internal vSwitch 1" -SwitchType Internal
New-VMSwitch -Name "Internal vSwitch 2" -SwitchType Internal
```

### # Configure "Internal vSwitch 1" network adapter

```PowerShell
$interfaceAlias = "vEthernet (Internal vSwitch 1)"
```

#### # Configure static IPv4 address

```PowerShell
$ipAddress = "10.1.12.2"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" -RegistryValue 9014
```

### # Configure "Internal vSwitch 2" network adapter

```PowerShell
$interfaceAlias = "vEthernet (Internal vSwitch 2)"
```

#### # Configure static IPv4 address

```PowerShell
$ipAddress = "10.1.13.2"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" -RegistryValue 9014
```

```PowerShell
cls
```

### # Configure shared storage for scale-out file server

#### # Configure iSCSI server

---

**FOOBAR8** - Run as administrator

```PowerShell
cls
```

##### # Create DNS records for iSCSI server

```PowerShell
Add-DnsServerResourceRecordA `
    -ComputerName XAVIER1 `
    -Name "iscsi01" `
    -IPv4Address 10.1.12.2 `
    -ZoneName "corp.technologytoolbox.com"

Add-DnsServerResourceRecordA `
    -ComputerName XAVIER1 `
    -Name "iscsi01" `
    -IPv4Address 10.1.13.2 `
    -ZoneName "corp.technologytoolbox.com"
```

---

##### # Create iSCSI target

```PowerShell
$iScsiTargetName = "TT-SOFS01"

$initiatorIds = @(
    "IQN:iqn.1991-05.com.microsoft:tt-sofs01a.corp.technologytoolbox.com",
    "IQN:iqn.1991-05.com.microsoft:tt-sofs01b.corp.technologytoolbox.com")

New-IscsiServerTarget `
    -TargetName $iScsiTargetName `
    -InitiatorIds $initiatorIds
```

##### # Create iSCSI disks

```PowerShell
New-IscsiVirtualDisk `
    -Path ("D:\iSCSIVirtualDisks\" + $iScsiTargetName + "_Quorum.vhdx") `
    -SizeBytes 512MB

New-IscsiVirtualDisk `
    -Path ("D:\iSCSIVirtualDisks\" + $iScsiTargetName + "_CSV01.vhdx") `
    -SizeBytes 2.5TB `
    -UseFixed
```

##### # Map iSCSI disks to target

```PowerShell
Add-IscsiVirtualDiskTargetMapping `
    -TargetName $iScsiTargetName `
    -Path ("D:\iSCSIVirtualDisks\" + $iScsiTargetName + "_Quorum.vhdx")

Add-IscsiVirtualDiskTargetMapping `
    -TargetName $iScsiTargetName `
    -Path ("D:\iSCSIVirtualDisks\" + $iScsiTargetName + "_CSV01.vhdx")
```

## Configure file shares

---

**FOOBAR8** - Run as administrator

```PowerShell
cls
```

### # Create DNS record - "TT-FS02"

```PowerShell
Add-DnsServerResourceRecordA `
    -ComputerName XAVIER1 `
    -Name "TT-FS02" `
    -IPv4Address 10.1.10.8 `
    -ZoneName "corp.technologytoolbox.com"
```

---

> **Important**
>
> A DNS Host (A) record must be used -- due to Kerberos issues with CNAME records.

```PowerShell
cls
```

### # Configure file share - "Products"

#### # Create folder

```PowerShell
$folderName = "Products"
$path = "D:\Shares\$folderName"

New-Item -Path $path -ItemType Directory
```

#### # Remove "BUILTIN\\Users" permissions

```PowerShell
icacls $path /inheritance:d
icacls $path /remove:g "BUILTIN\Users"
```

#### # Share folder

```PowerShell
New-SmbShare `
    -Name $folderName `
    -Path $path `
    -CachingMode None `
    -FullAccess Everyone
```

#### # Grant read-only permissions to users and Hyper-V servers

```PowerShell
icacls $path /grant '"BUILTIN\Users":(OI)(CI)(RX)'
icacls $path /grant '"Hyper-V Servers":(OI)(CI)(RX)'
```

## Reconfigure networking (to use logical switch defined in VMM)

### # Shutdown all VMs and disconnect network adapters

```PowerShell
Get-VM | Stop-VM

Get-VM | Get-VMNetworkAdapter | Disconnect-VMNetworkAdapter
```

```PowerShell
cls
```

### # Remove standard Hyper-V switch and NIC team

```PowerShell
Get-VMSwitch "Tenant vSwitch" | Remove-VMSwitch

Remove-NetLbfoTeam -Name "Tenant Team"
```

```PowerShell
cls
```

### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter `
    -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter" |
    Rename-NetAdapter -NewName "Storage 1"

Get-NetAdapter `
    -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter #2" |
    Rename-NetAdapter -NewName "Storage 2"
```

### Configure DHCP addresses on all network adapters

```Console
Sconfig
```

```Console
cls
```

### # Configure Hyper-V virtual switches for "storage" network

#### # Create Hyper-V virtual switches

```PowerShell
New-VMSwitch `
    -Name "Management" `
    -NetAdapterName "Management" `
    -AllowManagementOS $true

New-VMSwitch `
    -Name "Storage 1" `
    -NetAdapterName "Storage 1" `
    -AllowManagementOS $true

New-VMSwitch `
    -Name "Storage 2" `
    -NetAdapterName "Storage 2" `
    -AllowManagementOS $true
```

```PowerShell
cls
```

### # Configure storage network adapters

#### # Configure static IP addresses on "Storage 1" network

```PowerShell
$interfaceAlias = "vEthernet (Storage 1)"
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
$ipAddress = "10.1.10.7"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24
```

##### # Configure static IPv6 address

**# Note:** Private IPv6 address range (fd87:77eb:097e:95a1::/64) generated by [http://simpledns.com/private-ipv6.aspx](http://simpledns.com/private-ipv6.aspx)

```PowerShell
$ipAddress = "fd87:77eb:097e:95a1::7"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 64
```

##### # Configure IPv4 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 192.168.10.103,192.168.10.104
```

##### # Configure IPv6 DNS servers

```PowerShell
Set-DnsClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 2603:300b:802:8900::103, 2603:300b:802:8900::104
```

```PowerShell
cls
```

#### # Configure static IP addresses on "Storage 2" network

```PowerShell
$interfaceAlias = "vEthernet (Storage 2)"
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
$ipAddress = "10.1.10.8"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24
```

##### # Configure static IPv6 address

```PowerShell
$ipAddress = "fd87:77eb:097e:95a1::8"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 64
```

##### # Configure IPv4 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 192.168.10.103,192.168.10.104
```

##### # Configure IPv6 DNS servers

```PowerShell
Set-DnsClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 2603:300b:802:8900::103, 2603:300b:802:8900::104
```

```PowerShell
cls
```

### # Verify SMB Multichannel is working as expected

```PowerShell
$source = "\\TT-HV02B\C$\NotBackedUp\Products\Microsoft\Windows Server 2016"
$destination = "C:\NotBackedUp\Products\Microsoft\Windows Server 2016"

robocopy $source $destination en_windows_server_2016_x64_dvd_9718492.iso
```

---

**TT-VMM01A** - Run as administrator

```PowerShell
cls
```

### # Reconnect all VM network adapters

```PowerShell
$vmNetwork = Get-SCVMNetwork -Name "Management VM Network"
$portClassification = Get-SCPortClassification -Name "1 Gbps Tenant vNIC"

Get-SCVirtualMachine -VMHost TT-HV03 |
    % {
        Get-SCVirtualNetworkAdapter -VM $_ |
            Set-SCVirtualNetworkAdapter `
                -VMNetwork $vmNetwork `
                -VirtualNetwork "Embedded Team Switch" `
                -PortClassification $portClassification
    }
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

**TT-DPM01** - DPM Management Shell

```PowerShell
cls
```

### # Attach DPM agent

```PowerShell
$productionServer = 'TT-HV03'

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

## Issue: Storage tiers do not work with ReFS

From Storage-Tiers-Optimization.log:

```Text
    Microsoft Drive Optimizer
    Copyright (c) 2013 Microsoft Corp.

    Invoking tier optimization on Data01 (D:)...



    The operation requested is not supported by the hardware backing the volume. (0x8900002A)
```

Apparently there are some known issues with storage tiering and ReFS:

"ReFS should be used with Storage Spaces Direct (S2D), and stick with NTFS for all other scenarios."

-- Elden Christensen (MSFT)

**Windows Server 2016 Storage Spaces Tier ReFS**\
From <[https://social.technet.microsoft.com/Forums/windows/en-US/06f07aaf-484c-435e-b655-2761a1dcbb67/windows-server-2016-storage-spaces-tier-refs?forum=winserverfiles](https://social.technet.microsoft.com/Forums/windows/en-US/06f07aaf-484c-435e-b655-2761a1dcbb67/windows-server-2016-storage-spaces-tier-refs?forum=winserverfiles)>

### Workaround

#### Move virtual machines to different hypervisor

#### Login as fabric administrator account

```Console
PowerShell
```

#### # Delete virtual disks

```PowerShell
Get-VirtualDisk | Remove-VirtualDisk
```

```PowerShell
cls
```

#### # Recreate mirrored virtual disk (and format using NTFS)

```PowerShell
$ssdTier = Get-StorageTier -FriendlyName "SSD Tier"
$hddTier = Get-StorageTier -FriendlyName "HDD Tier"

Get-StoragePool "Pool 1" |
    New-VirtualDisk `
        -FriendlyName "Data01" `
        -ResiliencySettingName Mirror `
        -StorageTiers $ssdTier, $hddTier `
        -StorageTierSizes 470GB, 3724GB `
        -WriteCacheSize 5GB
```

> **Note**
>
> **3724GB** was found by trial and error:
>
> New-VirtualDisk : Not Supported
>
> Extended information:\
> The storage pool does not have sufficient eligible resources for the creation of the specified virtual disk.
>
> Recommended Actions:
>
> - Choose a combination of FaultDomainAwareness and NumberOfDataCopies (or PhysicalDiskRedundancy) supported by the storage pool.
> - Choose a value for NumberOfColumns that is less than or equal to the number of physical disks in the storage fault domain selected for the virtual disk.

```PowerShell
cls
```

#### # Create partitions and volumes

##### # Create volume "D" on Data01

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

```PowerShell
cls
```

#### # Configure VM storage

```PowerShell
mkdir D:\NotBackedUp\VMs

Set-VMHost -VirtualMachinePath D:\NotBackedUp\VMs
```

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
    -InterfaceAlias "vEthernet (Management)" `
    -ServerAddresses 2603:300b:802:8900::103, 2603:300b:802:8900::104

Restart-Computer
```

## Rebuild DPM 2016 server (replace TT-DPM01 with TT-DPM02)

```Console
PowerShell
```

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

**TT-DPM02** - DPM Management Shell

```PowerShell
cls
```

### # Attach DPM agent

```PowerShell
$productionServer = 'TT-HV03'

.\Attach-ProductionServer.ps1 `
    -DPMServerName TT-DPM02 `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `
    -UserName jjameson-admin
```

---

## Issue - Poor write performance on D: drive (tiered storage pool)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/27/92AD79946E869E7EE199D69FF682AC28D3950627.png)

Screen clipping taken: 2/16/2018 3:21 PM

![(screenshot)](https://assets.technologytoolbox.com/screenshots/93/5FE0D64D7B2E7DFEAC548790049D3EE07C151F93.png)

Screen clipping taken: 2/16/2018 3:22 PM

| Item          | Value                                                                                                        |
| ------------- | ------------------------------------------------------------------------------------------------------------ |
| PNP Device ID | PCI\\VEN_8086&DEV_1E02&SUBSYS_84CA1043&REV_04\\3&11583659&0&FA                                               |
| Driver        | c:\\windows\\system32\\drivers\\storahci.sys (10.0.14393.953, 127.84 KB (130,912 bytes), 3/21/2017 10:05 AM) |

### Update AHCI drivers

1. Download the latest AHCI drivers from the Intel website:\
   **Intel® Rapid Storage Technology (Intel® RST) User Interface and Driver**\
   From <[https://downloadcenter.intel.com/download/23496/Intel-Rapid-Storage-Technology-Intel-RST-User-Interface-and-Driver](https://downloadcenter.intel.com/download/23496/Intel-Rapid-Storage-Technology-Intel-RST-User-Interface-and-Driver)>
2. Extract the drivers (**[\\\\TT-FS01\\Public\\Download\\Drivers\\Intel\\RST](\\TT-FS01\Public\Download\Drivers\Intel\RST) Driver for ASUS P8Z77-V**) and copy the files to a temporary location on the server:
3. Install the drivers for the **Intel(R) 7 Series/C216 Chipset Family SATA AHCI Controller (PCI\\VEN_8086&DEV_1E02&...)**:
4. Restart the server.

> **Note**
>
> Version 12.x contains the drivers for the Intel C216 chipset (a.k.a. "1E02") -- newer versions do not.

```PowerShell
robocopy "\\TT-FS01\Public\Download\Drivers\Intel\RST Driver for ASUS P8Z77-V" '\\TT-HV03\C$\NotBackedUp\Temp\Drivers\Intel\RST' /E

pnputil -i -a C:\NotBackedUp\Temp\Drivers\Intel\RST\iaAHCIC.inf
```

### Reconfigure storage

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
$hddTier = Get-StorageTier -FriendlyName "HDD Tier"

Get-StoragePool "Pool 1" |
    New-VirtualDisk `
        -FriendlyName "Data01" `
        -ResiliencySettingName Mirror `
        -ProvisioningType Fixed `
        -StorageTiers $ssdTier, $hddTier `
        -StorageTierSizes 470GB, 3724GB `
        -WriteCacheSize 5GB
```

```PowerShell
cls
```

#### # Create partitions and volumes

##### # Create volume "D" on Data01

```PowerShell
Get-VirtualDisk "Data01" | Get-Disk | Set-Disk -IsReadOnly 0

Get-VirtualDisk "Data01"| Get-Disk | Set-Disk -IsOffline 0

Get-VirtualDisk "Data01"| Get-Disk | Initialize-Disk -PartitionStyle GPT

Get-VirtualDisk "Data01"| Get-Disk |
    New-Partition -DriveLetter "D" -UseMaximumSize

Initialize-Volume `
    -DriveLetter "D" `
    -FileSystem ReFS `
    -NewFileSystemLabel "Data01" `
    -Confirm:$false
```

```PowerShell
cls
```

#### # Benchmark storage performance

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\ATTO Disk Benchmark\Bench32.exe'
```

##### C: (HDD - Western Digital 640 GB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1C/4E4FF1D27A05B6573DC99739EB15379BBBE64C1C.png)

Screen clipping taken: 3/3/2018 10:48 AM

##### D: (Mirror SSD/HDD storage space)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/22/CE52951231D7017E63D6FF0775C2FCB3EA0B4F22.png)

Screen clipping taken: 3/3/2018 10:57 AM

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B6/0981D178ECB7617FC6E16B930C70AF20EA3D11B6.png)

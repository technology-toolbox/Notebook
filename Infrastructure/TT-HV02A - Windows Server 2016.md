# TT-HV02A - Windows Server 2016

Tuesday, January 17, 2017
3:15 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create domain group for fabric administrators

```PowerShell
$fabricAdminsGroup = "Fabric Admins"
$orgUnit = "OU=Groups,OU=IT,DC=corp,DC=technologytoolbox,DC=com"

New-ADGroup `
    -Name $fabricAdminsGroup `
    -Description "Complete and unrestricted access to fabric resources" `
    -GroupScope Global `
    -Path $orgUnit
```

### # Create fabric administrator account

```PowerShell
$displayName = "Jeremy Jameson (fabric admin)"
$defaultUserName = "jjameson-fabric"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@corp.technologytoolbox.com"
$orgUnit = "OU=Admin Accounts,OU=IT,DC=corp,DC=technologytoolbox,DC=com"

New-ADUser `
    -Name $displayName `
    -DisplayName $displayName `
    -SamAccountName $cred.UserName `
    -AccountPassword $cred.Password `
    -UserPrincipalName $userPrincipalName `
    -Path $orgUnit `
    -Enabled:$true
```

### # Add fabric admin account to fabric administrators domain group

```PowerShell
Add-ADGroupMember `
    -Identity $fabricAdminsGroup `
    -Members $cred.UserName
```

```PowerShell
cls
```

### # Create failover cluster objects in Active Directory

#### # Create cluster object for Hyper-V failover cluster and delegate permission to create the cluster to any member of the fabric administrators group

```PowerShell
$failoverClusterName = "TT-HV02-FC"
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

```PowerShell
cls
```

### # Install latest patches

#### # Install cumulative update for Windows Server 2016

##### # Copy patch to local storage

```PowerShell
net use \\ICEMAN\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the server.

```PowerShell
$source = "\\ICEMAN\Products\Microsoft\Windows 10\Patches"
$destination = "C:\NotBackedUp\Temp"
$patch = "windows10.0-kb3213522-x64_fc88893ff1fbe75cac5f5aae7ff1becee55c89dd.msu"

robocopy $source $destination $patch
```

##### # Validate local copy of patch

```PowerShell
robocopy \\ICEMAN\Public\Toolbox\FCIV \NotBackedUp\Public\Toolbox\FCIV

C:\NotBackedUp\Public\Toolbox\FCIV\fciv.exe -sha1 `
C:\NotBackedUp\Temp\windows10.0-kb3213522-x64_fc88893ff1fbe75cac5f5aae7ff1becee55c89dd.msu
```

> **Important**
>
> Ensure the checksum matches the expected value (specified in the filename).

##### # Install patch

```PowerShell
& "$destination\$patch"
```

> **Note**
>
> When prompted, restart the computer to complete the installation.

```Console
PowerShell
```

```Console
cls
```

##### # Delete local copy of patch

```PowerShell
Remove-Item ("C:\NotBackedUp\Temp" `
    + "\windows10.0-kb3213522-x64_fc88893ff1fbe75cac5f5aae7ff1becee55c89dd.msu")
```

#### # Install latest patches using Windows Update

```PowerShell
sconfig
```

### Rename computer and join domain

```Console
sconfig
```

> **Note**
>
> Rename the computer to **TT-HV02A** and join the **corp.technologytoolbox.com** domain.

---

**FOOBAR8**

```PowerShell
cls
```

### # Move computer to "Hyper-V Servers" OU

```PowerShell
$computerName = "TT-HV02A"
$targetPath = ("OU=Hyper-V Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com")
```

### # Add computer to "Hyper-V Servers" domain group

```PowerShell
Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath

Import-Module ActiveDirectory
Add-ADGroupMember -Identity "Hyper-V Servers" -Members TT-HV02A$
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
$source = "\\ICEMAN\Public\Toolbox"
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
    Rename-NetAdapter -NewName "Datacenter 1"

Get-NetAdapter -InterfaceDescription "Intel(R) I210 Gigabit Network Connection #2" |
    Rename-NetAdapter -NewName "Datacenter 2"

Get-NetAdapter `
    -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter" |
    Rename-NetAdapter -NewName "Tenant 1"

Get-NetAdapter `
    -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter #2" |
    Rename-NetAdapter -NewName "Tenant 2"
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name "Datacenter 1" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Set-NetAdapterAdvancedProperty -Name "Datacenter 2" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Set-NetAdapterAdvancedProperty -Name "Tenant 1" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Set-NetAdapterAdvancedProperty -Name "Tenant 2" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

ping ICEMAN -f -l 8900
```

#### Verify SMB Multichannel is working as expected

The following screenshot shows 1.4 Gbps throughput when copying a large file from ICEMAN to TT-HV02A:

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7E/62DE5D269AFFB5AF99EE6F7A2A3CB648D668BF7E.png)

The following screenshot shows the load spread across all four network adapters on TT-HV02A:

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BE/BE04CBF74A7F6118545B3E4239EC9510348359BE.png)

```PowerShell
cls
```

#### # Configure network team

##### # Create NIC team

```PowerShell
$interfaceAlias = "Tenant Team"
$teamMembers = "Tenant 1", "Tenant 2"

New-NetLbfoTeam `
    -Name $interfaceAlias `
    -TeamMembers $teamMembers `
    -Confirm:$false
```

##### # Verify NIC team status - "Tenant Team"

```PowerShell
Write-Host "Waiting for NIC team to initialize..."
Start-Sleep -Seconds 5

do {
    If (Get-NetLbfoTeam -Name $interfaceAlias | Where Status -eq "Up")
    {
        return
    }

    Write-Host "." -NoNewline
    Start-Sleep -Seconds 5
```

}  while (\$true)

> **Important**
>
> Ensure the **Status** property of the network team is **Up**.

```PowerShell
cls
```

#### # Configure static IP addresses on "Datacenter 1" network

```PowerShell
$interfaceAlias = "Datacenter 1"
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

##### # Configure static IPv6 address

**# Note:** Private IPv6 address range (fd87:77eb:097e:95a1::/64) generated by [http://simpledns.com/private-ipv6.aspx](http://simpledns.com/private-ipv6.aspx)

```PowerShell
$ipAddress = "fd87:77eb:097e:95a1::2"

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

#### # Configure static IP addresses on "Datacenter 2" network

```PowerShell
$interfaceAlias = "Datacenter 2"
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
$ipAddress = "10.1.10.3"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24
```

##### # Configure static IPv6 address

```PowerShell
$ipAddress = "fd87:77eb:097e:95a1::3"

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
<p>Model: Samsung SSD 850 PRO 512GB<br />
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
<p>3</p>
</td>
<td valign='top'>
<p>Model: Samsung SSD 850 PRO 128GB<br />
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
<p>Model: Samsung SSD 850 PRO 512GB<br />
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
<tr>
<td valign='top'>
<p>6</p>
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
<p>PhysicalDisk2<br />
PhysicalDisk4<br />
PhysicalDisk5<br />
PhysicalDisk6</p>
</td>
</tr>
</table>

#### Virtual disks

| Name   | Layout | Provisioning | Capacity | SSD Tier | HDD Tier | Volume | Volume Label | Write-Back Cache |
| ------ | ------ | ------------ | -------- | -------- | -------- | ------ | ------------ | ---------------- |
| Data01 | Mirror | Fixed        | 200 GB   | 200 GB   |          | D:     | Data01       |                  |
| Data02 | Mirror | Fixed        | 900 GB   | 200 GB   | 1200 GB  | E:     | Data02       | 5 GB             |
| Data03 | Mirror | Fixed        | 600 GB   |          | 600 GB   | F:     | Data03       | 5 GB             |

#### Update AHCI drivers

1. Download the latest AHCI drivers from the Intel website:\
   **Intel® RSTe AHCI & SCU Software RAID driver for Windows**\
   From <[https://downloadcenter.intel.com/download/25393/Intel-RSTe-AHCI-SCU-Software-RAID-driver-for-Windows-](https://downloadcenter.intel.com/download/25393/Intel-RSTe-AHCI-SCU-Software-RAID-driver-for-Windows-)>
2. Extract the drivers (**[\\\\ICEMAN\\Public\\Download\\Drivers\\Intel\\RSTe](\\ICEMAN\Public\Download\Drivers\Intel\RSTe) AHCI & SCU Software RAID driver for Windows**) and copy the files to a temporary location on the server:
3. Install the drivers for the **Intel(R) C600+/C220+ series chipset SATA AHCI Controller (PCI\\VEN_8086&DEV_8D02&...)**:
4. Install the drivers for the **Intel(R) C600+/C220+ series chipset sSATA AHCI Controller (PCI\\VEN_8086&DEV_8D62&...)**:
5. Restart the server.

```Console
    robocopy "\\ICEMAN\Public\Download\Drivers\Intel\RSTe AHCI & SCU Software RAID driver for Windows\Drivers\x64\Win8_10_2K8R2_2K12\AHCI" '\\TT-HV02A\C$\NotBackedUp\Temp\Drivers\Intel\x64\Win8_10_2K8R2_2K12\AHCI' /E
```

```Console
    pnputil -i -a C:\NotBackedUp\Temp\Drivers\Intel\x64\Win8_10_2K8R2_2K12\AHCI\iaAHCI.inf
```

```Console
    pnputil -i -a C:\NotBackedUp\Temp\Drivers\Intel\x64\Win8_10_2K8R2_2K12\AHCI\iaAHCIB.inf
```

#### Login as fabric administrator account

```Console
PowerShell
```

```Console
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
        -FriendlyName "Data01" `
        -ResiliencySettingName Mirror `
        -StorageTiers $ssdTier `
        -StorageTierSizes 200GB

$hddTier = Get-StorageTier -FriendlyName "HDD Tier"

Get-StoragePool "Pool 1" |
    New-VirtualDisk `
        -FriendlyName "Data02" `
        -ResiliencySettingName Mirror `
        -StorageTiers $ssdTier,$hddTier `
        -StorageTierSizes 200GB,1200GB `
        -WriteCacheSize 5GB

Get-StoragePool "Pool 1" |
    New-VirtualDisk `
        -FriendlyName "Data03" `
        -ResiliencySettingName Mirror `
        -StorageTiers $hddTier `
        -StorageTierSizes 600GB `
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

##### # Create volume "E" on Data02

```PowerShell
Get-VirtualDisk "Data02" | Get-Disk | Set-Disk -IsReadOnly 0

Get-VirtualDisk "Data02"| Get-Disk | Set-Disk -IsOffline 0

Get-VirtualDisk "Data02"| Get-Disk | Initialize-Disk -PartitionStyle GPT

Get-VirtualDisk "Data02"| Get-Disk |
    New-Partition -DriveLetter "E" -UseMaximumSize

Initialize-Volume `
    -DriveLetter "E" `
    -FileSystem ReFS `
    -NewFileSystemLabel "Data02" `
    -Confirm:$false
```

##### # Create volume "F" on Data03

```PowerShell
Get-VirtualDisk "Data03" | Get-Disk | Set-Disk -IsReadOnly 0

Get-VirtualDisk "Data03"| Get-Disk | Set-Disk -IsOffline 0

Get-VirtualDisk "Data03"| Get-Disk | Initialize-Disk -PartitionStyle GPT

Get-VirtualDisk "Data03"| Get-Disk |
    New-Partition -DriveLetter "F" -UseMaximumSize

Initialize-Volume `
    -DriveLetter "F" `
    -FileSystem ReFS `
    -NewFileSystemLabel "Data03" `
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

##### F: (Mirror HDD storage space)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/05/DE18812F789E34DA6C78D302716BFA0B00FD8305.png)

## Prepare infrastructure for Hyper-V installation

### Enable Virtualization in BIOS

Intel Virtualization Technology: **Enabled**

### Configure shared storage for Hyper-V cluster

#### Configure iSCSI server

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

##### # Create iSCSI target

```PowerShell
$initiatorIds = @(
    "IQN:iqn.1991-05.com.microsoft:tt-hv02a.corp.technologytoolbox.com",
    "IQN:iqn.1991-05.com.microsoft:tt-hv02b.corp.technologytoolbox.com"
)

New-IscsiServerTarget `
    -ComputerName ICEMAN `
    -TargetName TT-HV02 `
    -InitiatorIds $initiatorIds
```

##### # Create iSCSI disks

```PowerShell
New-IscsiVirtualDisk `
    -ComputerName ICEMAN `
    -Path E:\iSCSIVirtualDisks\TT-HV02_Quorum.vhdx `
    -SizeBytes 512MB

New-IscsiVirtualDisk `
    -ComputerName ICEMAN `
    -Path E:\iSCSIVirtualDisks\TT-HV02_CSV01.vhdx `
    -SizeBytes 800GB
```

##### # Map iSCSI disks to target

```PowerShell
Add-IscsiVirtualDiskTargetMapping `
    -ComputerName ICEMAN `
    -TargetName TT-HV02 `
    -Path E:\iSCSIVirtualDisks\TT-HV02_Quorum.vhdx

Add-IscsiVirtualDiskTargetMapping `
    -ComputerName ICEMAN `
    -TargetName TT-HV02 `
    -Path E:\iSCSIVirtualDisks\TT-HV02_CSV01.vhdx
```

---

```PowerShell
cls
```

#### # Install Multipath I/O

```PowerShell
Install-WindowsFeature `
    -Name Multipath-IO `
    -IncludeManagementTools `
    -Restart
```

#### Login as fabric administrator account

```Console
PowerShell
```

```Console
cls
```

#### # Configure iSCSI client

##### # Start iSCSI service

```PowerShell
Set-Service msiscsi -StartupType Automatic

Start-Service msiscsi
```

##### # Connect to iSCSI Portal

```PowerShell
New-IscsiTargetPortal -TargetPortalAddress iscsi-01

Start-Sleep 30

Connect-IscsiTarget `
    -NodeAddress "iqn.1991-05.com.microsoft:iceman-tt-hv02-target" `
    -IsPersistent $true
```

##### # Online and initialize disks

```PowerShell
$iscsiDisks = Get-Disk | ? {$_.FriendlyName -eq "MSFT Virtual HD"}

$quorumDiskNumber = $iscsiDisks |
    sort Size |
    select -First 1 |
    select -ExpandProperty Number

$iscsiDisks |
    % {
        $disk = $_

        If ($disk.IsOffline -eq $true) {
            Set-Disk -Number $disk.Number -IsOffline $false
        }

        If ($disk.PartitionStyle -eq 'RAW') {
            If ($disk.Number -eq $quorumDiskNumber) {
                # Note: ReFS cannot be used on small disks (e.g. 512 MB)

                Initialize-Disk -Number $disk.Number -PartitionStyle GPT -PassThru |
                    New-Partition -UseMaximumSize |
                    Format-Volume `
                        -FileSystem NTFS `
                        -NewFileSystemLabel "Quorum" `
                        -Confirm:$false
            }
            Else {
                Initialize-Disk -Number $disk.Number -PartitionStyle GPT -PassThru |
                    New-Partition -UseMaximumSize |
                    Format-Volume `
                        -FileSystem ReFS `
                        -NewFileSystemLabel "CSV01" `
                        -Confirm:$false
            }
        }
    }
```

```PowerShell
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

### # Create and configure failover cluster

#### # Run all cluster validation tests

```PowerShell
Test-Cluster -Node TT-HV02A, TT-HV02B
```

> **Note**
>
> Wait for the cluster validation tests to complete.

#### # Review cluster validation report

```PowerShell
$source = "$env:TEMP\Validation Report 2017.01.20 At 04.00.56.htm"
$destination = "\\ICEMAN.corp.technologytoolbox.com\Public"

Copy-Item $source $destination
```

---

**WOLVERINE**

```PowerShell
& "\\ICEMAN\Public\Validation Report 2017.01.20 At 04.00.56.htm"
```

---

```PowerShell
cls
```

#### # Create cluster

```PowerShell
New-Cluster -Name TT-HV02-FC -Node TT-HV02A, TT-HV02B -NoStorage

WARNING: There were issues while creating the clustered role that may prevent it from starting. For more information view the report file below.
WARNING: Report file location: C:\Windows\cluster\Reports\Create Cluster Wizard TT-HV02-FC on 2017.01.20 At 04.04.59.htm

Name
----
TT-HV02-FC
```

#### # Review cluster creation report

```PowerShell
$source = "C:\Windows\cluster\Reports\Create Cluster Wizard TT-HV02-FC on 2017.01.20 At 04.04.59.htm"
$destination = "\\ICEMAN.corp.technologytoolbox.com\Public"

Copy-Item $source $destination
```

---

**WOLVERINE**

```PowerShell
& "\\ICEMAN\Public\Create Cluster Wizard TT-HV02-FC on 2017.01.20 At 04.04.59.htm"
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

##### # Add cluster disk for quorum

```PowerShell
Get-ClusterAvailableDisk | sort Size | select -First 1 | Add-ClusterDisk
```

##### # Set quorum configuration and disk witness

```PowerShell
Set-ClusterQuorum -NodeAndDiskMajority "Cluster Disk 1"
```

```PowerShell
cls
```

#### # Configure cluster shared volumes

##### # Add cluster disk for CSV

```PowerShell
Get-ClusterAvailableDisk | Add-ClusterDisk
```

##### # Add cluster shared volume

```PowerShell
Add-ClusterSharedVolume -Name "Cluster Disk 2"
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
Get-VMSwitch | Remove-VMSwitch

Remove-NetLbfoTeam -Name "Tenant Team"
```

```PowerShell
cls
```

### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter -InterfaceDescription "Intel(R) I210 Gigabit Network Connection" |
    Rename-NetAdapter -NewName "Team 1A"

Get-NetAdapter -InterfaceDescription "Intel(R) I210 Gigabit Network Connection #2" |
    Rename-NetAdapter -NewName "Team 1B"

Get-NetAdapter `
    -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter" |
    Rename-NetAdapter -NewName "Team 1C"

Get-NetAdapter `
    -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter #2" |
    Rename-NetAdapter -NewName "Team 1D"
```

### Configure DHCP addresses on all network adapters

```Console
sconfig
```

### Add logical switch in VMM

```PowerShell
cls
```

### # Configure networking

#### # Set affinity between virtual network adapters and physical network adapters

```PowerShell
Set-VMNetworkAdapterTeamMapping `
    -ManagementOS `
    -VMNetworkAdapterName "Storage 1" `
    -PhysicalNetAdapterName "Team 1A"

Set-VMNetworkAdapterTeamMapping `
    -ManagementOS `
    -VMNetworkAdapterName "Storage 2" `
    -PhysicalNetAdapterName "Team 1B"

Set-VMNetworkAdapterTeamMapping `
    -ManagementOS `
    -VMNetworkAdapterName "Live Migration" `
    -PhysicalNetAdapterName "Team 1C"
```

#### # Disable DHCPv6 on storage and live migration networks

```PowerShell
$interfaceAliases = @(
    "vEthernet (Cluster)",
    "vEthernet (Live Migration)"
    "vEthernet (Storage 1)",
    "vEthernet (Storage 2)")

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

```PowerShell
cls
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

$interfaceAliases = @(
    "vEthernet (Embedded Team Switch)",
    "vEthernet (Storage 1)",
    "vEthernet (Storage 2)",
    "vEthernet (Live Migration)")

$interfaceAliases |
    % {
        Set-NetAdapterAdvancedProperty `
            -Name $_ `
            -DisplayName "Jumbo Packet" `
            -RegistryValue 9014
    }

ping 10.1.10.1 -f -l 8900
ping 10.1.11.1 -f -l 8900
```

```PowerShell
cls
```

#### # Do not allow cluster network communication on the "storage" network (10.1.10.0/24)

```PowerShell
Get-ClusterNetwork | Get-ClusterNetworkInterface

(Get-ClusterNetwork -Name "Cluster Network 4").Role = 0
```

##### Reference

**Network Recommendations for a Hyper-V Cluster in Windows Server 2012**\
From <[https://technet.microsoft.com/en-us/library/dn550728(v=ws.11).aspx](https://technet.microsoft.com/en-us/library/dn550728(v=ws.11).aspx)>

```PowerShell
cls
```

### # Change network binding order for cluster network

```PowerShell
Get-NetIPInterface | sort AddressFamily, InterfaceMetric

Set-NetIPInterface -InterfaceAlias "vEthernet (Cluster)" -InterfaceMetric 15
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

### Issue: SMB Multichannel starts off strong, but throughput quickly drops

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3C/FCD0204F25E247CE44526B294F19C51A284F243C.png)

```PowerShell
cls
```

#### # Remove affinity between virtual network adapters and physical network adapters

```PowerShell
Get-VMNetworkAdapterTeamMapping -ManagementOS |
```

    % { Remove-VMNetworkAdapterTeamMapping -Name \$_.Name -ManagementOS }

```PowerShell
cls
```

### # Configure NIC team

#### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter `
    -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter" |
    Rename-NetAdapter -NewName "Storage Team 1A"

Get-NetAdapter `
    -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter #2" |
    Rename-NetAdapter -NewName "Storage Team 1B"
```

#### # Configure network team

```PowerShell
$interfaceAlias = "Storage Team 1"
```

##### # Create NIC team

```PowerShell
$teamMembers = "Storage Team 1A", "Storage Team 1B"

New-NetLbfoTeam `
    -Name $interfaceAlias `
    -TeamMembers $teamMembers `
    -Confirm:$false
```

##### # Verify NIC team status - "Storage Team 1"

```PowerShell
Write-Host "Waiting for NIC team to initialize..."
Start-Sleep -Seconds 5

do {
    If (Get-NetLbfoTeam -Name $interfaceAlias | Where Status -eq "Up")
    {
        return
    }

    Write-Host "." -NoNewline
    Start-Sleep -Seconds 5
```

}  while (\$true)

> **Important**
>
> Ensure the **Status** property of the network team is **Up**.

```PowerShell
cls
```

### # Verify SMB copy achieves ~2 Gbps throughput...

```PowerShell
$source = "\\TT-HV02B\C$\NotBackedUp\Products\Microsoft\Windows Server 2016"
$destination = "C:\NotBackedUp\Products\Microsoft\Windows Server 2016"

robocopy $source $destination en_windows_server_2016_x64_dvd_9718492.iso
```

### ...nope, only 1 Gbps throughput -- so try Switch Embedded Team (SET) instead of LBFO team

#### # Remove teamed switch

```PowerShell
Get-NetLbfoTeam | Remove-NetLbfoTeam
```

#### # Create Hyper-V switch using Switch Embedded Team

```PowerShell
New-VMSwitch -Name "Storage Team" -AllowManagementOS $True -NetAdapterName "Storage Team 1A", "Storage Team 1B" -EnableEmbeddedTeaming $True
```

```PowerShell
cls
```

### # Verify SMB copy achieves ~2 Gbps throughput...

```PowerShell
ipconfig /registerdns
ipconfig /flushdns

$source = "\\TT-HV02B\C$\NotBackedUp\Products\Microsoft\Windows Server 2016"
$destination = "C:\NotBackedUp\Products\Microsoft\Windows Server 2016"

robocopy $source $destination en_windows_server_2016_x64_dvd_9718492.iso
```

### ...nope, only 1 Gbps throughput -- so don't use teaming for "storage" network

#### # Remove teamed switch

```PowerShell
Get-VMSwitch "Storage Team" | Remove-VMSwitch
```

```PowerShell
cls
```

### # Verify SMB copy achieves ~2 Gbps throughput...

```PowerShell
ipconfig /registerdns
ipconfig /flushdns

$source = "\\TT-HV02B\C$\NotBackedUp\Products\Microsoft\Windows Server 2016"
$destination = "C:\NotBackedUp\Products\Microsoft\Windows Server 2016"

robocopy $source $destination en_windows_server_2016_x64_dvd_9718492.iso
```

### ...yes

```PowerShell
cls
```

#### # Rename network connections

```PowerShell
Get-NetAdapter `
    -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter" |
    Rename-NetAdapter -NewName "Storage 1"

Get-NetAdapter `
    -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter #2" |
    Rename-NetAdapter -NewName "Storage 2"
```

```PowerShell
cls
```

#### # Configure static IP addresses on "Storage 1" network

```PowerShell
$interfaceAlias = "Storage 1"
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
$ipAddress = "10.1.10.1"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24
```

##### # Configure static IPv6 address

**# Note:** Private IPv6 address range (fd87:77eb:097e:95a1::/64) generated by [http://simpledns.com/private-ipv6.aspx](http://simpledns.com/private-ipv6.aspx)

```PowerShell
$ipAddress = "fd87:77eb:097e:95a1::1"

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
$interfaceAlias = "Storage 2"
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

##### # Configure static IPv6 address

```PowerShell
$ipAddress = "fd87:77eb:097e:95a1::2"

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

---

**TT-VMM01A**

```PowerShell
cls
```

### # Configure "storage" logical switches in VMM (for storage network adapters with no teaming)

#### # Create "storage" uplink port profile

```PowerShell
$networkSites = @()
$networkSites += Get-SCLogicalNetworkDefinition -Name "Storage - VLAN 10"

New-SCNativeUplinkPortProfile `
    -Name "Storage Uplink" `
    -Description "" `
    -LogicalNetworkDefinition $networkSites `
    -LBFOLoadBalancingAlgorithm HostDefault `
    -LBFOTeamMode SwitchIndependent
```

#### # Create logical switches ("Storage 1" and "Storage 2")

```PowerShell
1..2 |
    % {
        $switchNumber = $_

        # Create logical switch

        $virtualSwitchExtensions = @()
        $virtualSwitchExtensions += Get-SCVirtualSwitchExtension `
            -Name "Microsoft Windows Filtering Platform"

        $logicalSwitch = New-SCLogicalSwitch `
            -Name "Storage $switchNumber" `
            -Description "" `
            -MinimumBandwidthMode Weight `
            -VirtualSwitchExtensions $virtualSwitchExtensions

        # Add virtual ports to logical switch

        $portClassification = Get-SCPortClassification -Name "SMB workload"

        $networkAdapterPortProfile = Get-SCVirtualNetworkAdapterNativePortProfile `
            -Name "SMB"

        New-SCVirtualNetworkAdapterPortProfileSet `
            -Name $portClassification.Name `
            -PortClassification $portClassification `
            -LogicalSwitch $logicalSwitch `
            -IsDefaultPortProfileSet $true `
            -VirtualNetworkAdapterNativePortProfile $networkAdapterPortProfile

        # Add virtual network adapters

        $uplinkPortProfile = Get-SCNativeUplinkPortProfile -Name "Storage Uplink"

        $uplinkPortProfileSet = New-SCUplinkPortProfileSet `
            -Name ("Storage Uplink - " + $logicalSwitch.Name) `
            -LogicalSwitch $logicalSwitch `
            -NativeUplinkPortProfile $uplinkPortProfile

        $vmNetwork = Get-SCVMNetwork "Storage VM Network"
        $vmSubnet = Get-SCVMSubnet -Name "Storage VM Network_0"
        $portClassification = Get-SCPortClassification -Name "SMB workload"
        $ipV4Pool = Get-SCStaticIPAddressPool -Name "Storage Address Pool"

        New-SCLogicalSwitchVirtualNetworkAdapter `
            -Name "Storage $switchNumber" `
            -UplinkPortProfileSet $uplinkPortProfileSet `
            -VMNetwork $vmNetwork `
            -VMSubnet $vmSubnet `
            -PortClassification $portClassification `
            -IPv4AddressType Static `
            -IPv4AddressPool $ipV4Pool
    }
```

#### # Add virtual switches to each Hyper-V host

```PowerShell
@("TT-HV02A.corp.technologytoolbox.com",
    "TT-HV02B.corp.technologytoolbox.com",
    "TT-HV02C.corp.technologytoolbox.com") |
    % {
        $vmHost = Get-SCVMHost -ComputerName $_

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
    }
```

---

#### # Disable DHCPv6 and enable jumbo frames on storage networks

```PowerShell
$interfaceAliases = @(
    "vEthernet (Storage 1)",
    "vEthernet (Storage 2)")

$interfaceAliases |
    % {
        $interfaceAlias = $_

        Set-NetIPInterface `
            -InterfaceAlias $interfaceAlias `
            -Dhcp Disabled `
            -RouterDiscovery Disabled

        Set-NetAdapterAdvancedProperty `
            -Name $interfaceAlias `
            -DisplayName "Jumbo Packet" `
            -RegistryValue 9014
    }

Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"
```

```PowerShell
cls
```

### # Verify SMB copy achieves ~2 Gbps throughput...

```PowerShell
ipconfig /registerdns
ipconfig /flushdns

$source = "\\TT-HV02B\C$\NotBackedUp\Products\Microsoft\Windows Server 2016"
$destination = "C:\NotBackedUp\Products\Microsoft\Windows Server 2016"

robocopy $source $destination en_windows_server_2016_x64_dvd_9718492.iso
```

### ...nope, throughput dropped from ~1.84 Gbps to ~1.51 Gbps (due to virtual switch)

```PowerShell
$interfaceAliases = @(
    "Storage 1",
    "Storage 2")

$interfaceAliases |
    % {
        $interfaceAlias = $_

        Set-NetAdapter -Name $interfaceAlias -VlanID 10
    }
```

---

**TT-VMM01A**

```PowerShell
cls
```

### # Reconnect all VM network adapters

```PowerShell
$vmNetwork = Get-SCVMNetwork -Name "Management VM Network"
$portClassification = Get-SCPortClassification -Name "1 Gbps Tenant vNIC"

Get-SCVirtualMachine -VMHost TT-HV02A |
    % {
        Get-SCVirtualNetworkAdapter -VM $_ |
            Set-SCVirtualNetworkAdapter `
                -VMNetwork $vmNetwork `
                -VirtualNetwork "Embedded Team Switch" `
                -PortClassification $portClassification
    }
```

---

**TODO:**

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

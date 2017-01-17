# TT-HV02C - Windows Server 2016

Tuesday, January 17, 2017
3:15 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

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
> Rename the computer to **TT-HV02C** and join the **corp.technologytoolbox.com** domain.

---

**FOOBAR8**

```PowerShell
cls
```

### # Move computer to "Hyper-V Servers" OU

```PowerShell
$computerName = "TT-HV02C"
$targetPath = ("OU=Hyper-V Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com")
```

### # Add computer to "Hyper-V Servers" domain group

```PowerShell
Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath

Import-Module ActiveDirectory
Add-ADGroupMember -Identity "Hyper-V Servers" -Members TT-HV02C$
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
$ipAddress = "10.1.10.6"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24
```

##### # Configure static IPv6 address

**# Note:** Private IPv6 address range (fd87:77eb:097e:95a1::/64) generated by [http://simpledns.com/private-ipv6.aspx](http://simpledns.com/private-ipv6.aspx)

```PowerShell
$ipAddress = "fd87:77eb:097e:95a1::6"

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
$ipAddress = "10.1.10.7"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24
```

##### # Configure static IPv6 address

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

### Configure storage

#### Update AHCI drivers

1. Download the latest AHCI drivers from the Intel website:\
   **Intel® RSTe AHCI & SCU Software RAID driver for Windows**\
   From <[https://downloadcenter.intel.com/download/25393/Intel-RSTe-AHCI-SCU-Software-RAID-driver-for-Windows-](https://downloadcenter.intel.com/download/25393/Intel-RSTe-AHCI-SCU-Software-RAID-driver-for-Windows-)>
2. Extract the drivers (**[\\\\ICEMAN\\Public\\Download\\Drivers\\Intel\\RSTe](\\ICEMAN\Public\Download\Drivers\Intel\RSTe) AHCI & SCU Software RAID driver for Windows**) and copy the files to a temporary location on the server:
3. Install the drivers for the **Intel(R) C600+/C220+ series chipset SATA AHCI Controller (PCI\\VEN_8086&DEV_8D02&...)**:
4. Install the drivers for the **Intel(R) C600+/C220+ series chipset sSATA AHCI Controller (PCI\\VEN_8086&DEV_8D62&...)**:
5. Restart the server.

```Console
    robocopy "\\ICEMAN\Public\Download\Drivers\Intel\RSTe AHCI & SCU Software RAID driver for Windows\Drivers\x64\Win8_10_2K8R2_2K12\AHCI" '\\TT-HV02C\C$\NotBackedUp\Temp\Drivers\Intel\x64\Win8_10_2K8R2_2K12\AHCI' /E
```

```Console
    pnputil -i -a C:\NotBackedUp\Temp\Drivers\Intel\x64\Win8_10_2K8R2_2K12\AHCI\iaAHCI.inf
```

```Console
    pnputil -i -a C:\NotBackedUp\Temp\Drivers\Intel\x64\Win8_10_2K8R2_2K12\AHCI\iaAHCIB.inf
```

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
<p>1</p>
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
<p>2</p>
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
<p>3</p>
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
<p>4</p>
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
<tr>
<td valign='top'>
<p>5</p>
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
<p>6</p>
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
<p>7</p>
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
<p>8</p>
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
<p>PhysicalDisk1<br />
PhysicalDisk2<br />
PhysicalDisk3<br />
PhysicalDisk4</p>
</td>
</tr>
</table>

#### Virtual disks

| Name   | Layout | Provisioning | Capacity | SSD Tier | HDD Tier | Volume | Volume Label | Write-Back Cache |
| ------ | ------ | ------------ | -------- | -------- | -------- | ------ | ------------ | ---------------- |
| Data01 | Mirror | Fixed        | 200 GB   | 200 GB   |          | D:     | Data01       |                  |
| Data02 | Mirror | Fixed        | 2200 GB  | 200 GB   | 2000 GB  | E:     | Data02       | 5 GB             |
| Data03 | Mirror | Fixed        | 1500 GB  |          | 1500 GB  | F:     | Data03       | 5 GB             |

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
    (Get-PhysicalDisk -SerialNumber *********01139V),
    (Get-PhysicalDisk -SerialNumber *********01138P),
    (Get-PhysicalDisk -SerialNumber *****58G),
    (Get-PhysicalDisk -SerialNumber *****42W))

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
        -StorageTierSizes 200GB,2000GB `
        -WriteCacheSize 5GB

Get-StoragePool "Pool 1" |
    New-VirtualDisk `
        -FriendlyName "Data03" `
        -ResiliencySettingName Mirror `
        -StorageTiers $hddTier `
        -StorageTierSizes 1500GB `
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

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B3/7CFB0E7273A428A17204FB056012A4935CE1C0B3.png)

##### D: (Mirror SSD storage space - 2x Samsung 850 Pro 512GB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D9/D30106A95D0686B2103C5385E32D030D9B82EDD9.png)

##### E: (Mirror SSD/HDD storage space)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1A/88CD744E0DF7B168A403FA5A8D9C4B362D061E1A.png)

##### F: (Mirror HDD storage space)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B4/C72C0942D26AD3EDE3C46E9F3C4F598828B04AB4.png)

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
    -TrustedComputer TT-HV02C `
    -TrustingComputer TT-FS01 `
    -ServiceType cifs `
    -Add
```

#### # Configure constrained delegation to migrate VMs to other Hyper-V servers

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-KCD.ps1 `
    -TrustedComputer TT-HV02C `
    -TrustingComputer TT-HV02A `
    -ServiceType cifs `
    -Add

C:\NotBackedUp\Public\Toolbox\PowerShell\Set-KCD.ps1 `
    -TrustedComputer TT-HV02C `
    -TrustingComputer TT-HV02A `
    -ServiceType "Microsoft Virtual System Migration Service" `
    -Add

C:\NotBackedUp\Public\Toolbox\PowerShell\Set-KCD.ps1 `
    -TrustedComputer TT-HV02C `
    -TrustingComputer TT-HV02B `
    -ServiceType cifs `
    -Add

C:\NotBackedUp\Public\Toolbox\PowerShell\Set-KCD.ps1 `
    -TrustedComputer TT-HV02C `
    -TrustingComputer TT-HV02B `
    -ServiceType "Microsoft Virtual System Migration Service" `
    -Add
```

---

```PowerShell
cls
```

### # Add server to Hyper-V cluster

```PowerShell
Get-Cluster -Name TT-HV02-FC | Add-ClusterNode -Name TT-HV02C
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

### # Examine network adapter properties to confirm identical configuration settings for Switch Embedded Team (SET)

```PowerShell
Get-NetAdapterAdvancedProperty | sort DisplayName, Name
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

### # Verify SMB Multichannel is working as expected

```PowerShell
$source = "\\TT-HV02B\C$\NotBackedUp\Products\Microsoft\Windows Server 2016"
$destination = "C:\NotBackedUp\Products\Microsoft\Windows Server 2016"

robocopy $source $destination en_windows_server_2016_x64_dvd_9718492.iso
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

Get-SCVirtualMachine -VMHost TT-HV02C |
    % {
        Get-SCVirtualNetworkAdapter -VM $_ |
            Set-SCVirtualNetworkAdapter `
                -VMNetwork $vmNetwork `
                -VirtualNetwork "Team Switch" `
                -PortClassification $portClassification
    }
```

---

**TODO:**

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

# TT-HV01A - Windows Server 2016

Monday, January 9, 2017
8:59 AM

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

---

### Install Windows Server 2016 ("Server Core")

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
> Rename the computer to **TT-HV01A** and join the **corp.technologytoolbox.com** domain.

---

**FOOBAR8**

```PowerShell
cls
```

### # Move computer to "Hyper-V Servers" OU

```PowerShell
$computerName = "TT-HV01A"
$targetPath = ("OU=Hyper-V Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com")
```

### # Add computer to "Hyper-V Servers" domain group

```PowerShell
Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath

Import-Module ActiveDirectory
Add-ADGroupMember -Identity "Hyper-V Servers" -Members TT-HV01A$
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

Get-NetAdapter -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter" |
    Rename-NetAdapter -NewName "Datacenter 1"

Get-NetAdapter -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter #2" |
    Rename-NetAdapter -NewName "Datacenter 2"

Get-NetAdapter `
    -InterfaceDescription "Intel(R) 82579LM Gigabit Network Connection" |
    Rename-NetAdapter -NewName "Tenant 1"

Get-NetAdapter `
    -InterfaceDescription "Intel(R) 82574L Gigabit Network Connection" |
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

#### Ensure SMB Multichannel is working as expected

The following screenshot shows 1.5 Gbps throughput when copying a large file from ICEMAN to TT-HV01A:

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BF/23003F17717A47C9DBD69AA186B26F6046296FBF.png)

The following screenshot shows the load spread across two network adapters (729 Mbps and 619 Mbps) on TT-HV01A:

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4F/5154E5668F6139E3AD3699F02EB196B0D026244F.png)

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
<p>1</p>
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
| Data01 | Mirror | Fixed        | 200 GB   | 200 GB   |          | D:     | Data01       |                  |
| Data02 | Mirror | Fixed        | 900 GB   | 200 GB   | 700 GB   | E:     | Data02       | 5 GB             |
| Data03 | Simple | Fixed        | 200 GB   |          | 200 GB   | F:     | Data03       | 1 GB             |

```PowerShell
cls
```

#### # Create storage pool

```PowerShell
$storageSubSystemName = "Windows Storage on $env:COMPUTERNAME"

$storageSubSystemUniqueId = `
    Get-StorageSubSystem -FriendlyName $storageSubSystemName |
    select -ExpandProperty UniqueId

New-StoragePool `
    -FriendlyName "Pool 1" `
    -StorageSubSystemUniqueId $storageSubSystemUniqueId `
    -PhysicalDisks (Get-PhysicalDisk -CanPool $true)
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

```PowerShell
cls
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
        -StorageTierSizes 200GB,700GB `
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

##### # Create volume "E" on Data02

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

##### # Create volume "F" on Data03

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

#### # Configure "Storage Tiers Optimization" scheduled task to append to log file

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

##### Reference

**Save a report when Storage Tiers Optimization runs**\
From <[https://technet.microsoft.com/en-us/library/dn789160.aspx](https://technet.microsoft.com/en-us/library/dn789160.aspx)>

#### Benchmark storage performance

##### C: (SSD - Samsung 850 Pro 128GB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/46/D4C4253F58688B819E4D813F52FCC5E3CC1FD946.png)

##### D: (Mirror SSD storage space - 2x Samsung 840 512GB)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/74/21009D0FDBFF029C7F5D4B8272BCB948088EB674.png)

##### E: (Mirror SSD/HDD storage space)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/47/5DFF257B071ABB458985BCE5E6899A7E324C4847.png)

##### F: (Simple HDD storage space)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C0/FC4CCC37839C4681B6D00593FC8D919764C722C0.png)

## Deploy Hyper-V

```PowerShell
cls
```

### # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

### # Configure tenant network team

#### # Create NIC team

```PowerShell
$interfaceAlias = "Tenant Team"
$teamMembers = "Tenant 1", "Tenant 2"

New-NetLbfoTeam `
    -Name $interfaceAlias `
    -TeamMembers $teamMembers `
    -Confirm:$false
```

### Enable Virtualization in BIOS

Intel Virtualization Technology: **Enabled**

```PowerShell
cls
```

### # Add Hyper-V role

```PowerShell
Install-WindowsFeature `
    -Name Hyper-V `
    -IncludeManagementTools `
    -Restart
```

### Login as fabric administrator account

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

## # Configure Hyper-V virtual switch

### # Create Hyper-V virtual switch

```PowerShell
New-VMSwitch `
    -Name "Tenant vSwitch" `
    -NetAdapterName "Tenant Team" `
    -AllowManagementOS $true
```

```PowerShell
cls
```

### # Enable jumbo frames on virtual switch

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

### # Modify virtual switch to disallow management OS

```PowerShell
Get-VMSwitch "Tenant vSwitch" |
    Set-VMSwitch -AllowManagementOS $false
```

```PowerShell
cls
```

### # Configure VM storage

```PowerShell
mkdir D:\NotBackedUp\VMs
mkdir E:\NotBackedUp\VMs
mkdir F:\NotBackedUp\VMs

Set-VMHost -VirtualMachinePath E:\NotBackedUp\VMs
```

**TODO:**

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

- **cifs - TT-HV01A.corp.technologytoolbox.com**
- **Microsoft Virtual System Migration Service - TT-HV01A.corp.technologytoolbox.com**

### Restart Hyper-V servers

This is necessary to avoid an error when migrating VMs:

```PowerShell
Move-VM : Virtual machine migration operation for 'BANSHEE' failed at migration source 'FORGE'. (Virtual machine ID D46FD5CD-A9CB-40B1-ACFB-5CC8C759E2D5)
The Virtual Machine Management Service failed to establish a connection for a Virtual Machine migration with host 'TT-HV01A': No credentials are available in the security package (0x8009030E).
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

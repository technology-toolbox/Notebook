# TT-SQL01B - Windows Server 2016 Standard Edition

Thursday, January 12, 2017
7:47 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "BEAST"
$vmName = "TT-SQL01B"
$vmPath = "E:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 8GB `
    -SwitchName "Production"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 2 `
    -StaticMemory

Set-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path \\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso

Start-VM -ComputerName $vmHost -Name $vmName
```

---

## Install custom Windows Server 2016 image

- On the **Task Sequence** step, select **Windows Server 2016** and click **Next**.
- On the **Computer Details** step, in the **Computer name** box, type **TT-SQL01B** and click **Next**.
- On the **Applications** step, do not select any applications, and click **Next**.

```PowerShell
cls
```

## # Rename local Administrator account and set password

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

$password = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted for the secure string, type the password for the Administrator account.

```PowerShell
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

$adminUser = [ADSI] 'WinNT://./Administrator,User'
$adminUser.Rename('foo')
$adminUser.SetPassword($plainPassword)

logoff
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Remove disk from virtual CD/DVD drive

```PowerShell
$vmHost = "BEAST"
$vmName = "TT-SQL01B"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

## # Move computer to "SQL Servers" OU

```PowerShell
$targetPath = ("OU=SQL Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath

Restart-VM -ComputerName $vmHost -VMName $vmName -Force
```

---

## Login as TECHTOOLBOX\\jjameson-admin

```PowerShell
cls
```

## # Configure network settings

### # Rename network connection

```PowerShell
$interfaceAlias = "Datacenter 1"

Get-NetAdapter -Physical

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping ICEMAN -f -l 8900
```

```PowerShell
cls
```

## # Set MaxPatchCacheSize to 0 (Recommended)

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

## # Select "High performance" power scheme

```PowerShell
powercfg.exe /L
powercfg.exe /S SCHEME_MIN
powercfg.exe /L
```

## # Configure storage

### # Change drive letter for DVD-ROM

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
```

---

**FOOBAR8**

```PowerShell
cls
```

### # Add disks for SQL Server storage (Data01, Log01, Temp01, and Backup01)

```PowerShell
$vmHost = "BEAST"
$vmName = "TT-SQL01B"

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Fixed -SizeBytes 40GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path $vhdPath `
    -ControllerType SCSI

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Log01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Fixed -SizeBytes 10GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path $vhdPath `
    -ControllerType SCSI

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Temp01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Fixed -SizeBytes 2GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path $vhdPath `
    -ControllerType SCSI

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Backup01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 50GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path $vhdPath `
    -ControllerType SCSI
```

---

```PowerShell
cls
```

### # Initialize disks and format volumes

```PowerShell
Get-Disk 1 |
    Initialize-Disk -PartitionStyle GPT -PassThru |
    New-Partition -UseMaximumSize -DriveLetter D |
    Format-Volume `
        -FileSystem NTFS `
        -AllocationUnitSize 64KB `
        -NewFileSystemLabel "Data01" `
        -Confirm:$false

Get-Disk 2 |
    Initialize-Disk -PartitionStyle GPT -PassThru |
    New-Partition -UseMaximumSize -DriveLetter L |
    Format-Volume `
        -FileSystem NTFS `
        -AllocationUnitSize 64KB `
        -NewFileSystemLabel "Log01" `
        -Confirm:$false

Get-Disk 3 |
    Initialize-Disk -PartitionStyle GPT -PassThru |
    New-Partition -UseMaximumSize -DriveLetter T |
    Format-Volume `
        -FileSystem NTFS `
        -AllocationUnitSize 64KB `
        -NewFileSystemLabel "Temp01" `
        -Confirm:$false

Get-Disk 4 |
    Initialize-Disk -PartitionStyle GPT -PassThru |
    New-Partition -UseMaximumSize -DriveLetter Z |
    Format-Volume `
        -FileSystem NTFS `
        -AllocationUnitSize 64KB `
        -NewFileSystemLabel "Backup01" `
        -Confirm:$false
```

## Benchmark storage performance

### Benchmark C: (Mirror SSD/HDD storage space)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D8/C308DB0BA5EC11EC8CFA23253375E8EE477C24D8.png)

### Benchmark D: (Mirror SSD/HDD storage space)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B4/97DE202E5F143418AAF3EA9F7336BF2F426156B4.png)

## Prepare server for SQL Server installation

```PowerShell
cls
```

### # Add SQL Server Admins domain group to local Administrators group

```PowerShell
$domain = "TECHTOOLBOX"
$domainGroup = "SQL Server Admins"

([ADSI]"WinNT://./Administrators,group").Add(
    "WinNT://$domain/$domainGroup,group")

logoff
```

### Login as TECHTOOLBOX\\setup-sql

```Console
PowerShell
```

```Console
cls
```

### # Set MaxPatchCacheSize to 0 (Recommended)

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

### # Select "High performance" power scheme

```PowerShell
powercfg.exe /L
powercfg.exe /S SCHEME_MIN
powercfg.exe /L
```

### Enable instant file initialization

To grant the service account for SQL Server permission to instantly initialize files:

1. Open the **Local Security Policy** application (secpol.msc).
2. In the **Local Security Policy** window:
   1. In the left pane, expand **Local Policies**, and then click **User Rights Assignment**.
   2. In the right pane, double-click **Perform volume maintenance tasks**.
   3. In the **Perform volume maintenance tasks Properties** window:
      1. Click **Add User or Group...**
      2. In the **Select Users, Computers, Service Accounts, or Groups** window, specify the service account for SQL Server (**TECHTOOLBOX\\s-sql01**) and click **OK**.
      3. Click **OK**.

#### Reference

**Database Instant File Initialization**\
From <[https://msdn.microsoft.com/en-us/library/ms175935.aspx](https://msdn.microsoft.com/en-us/library/ms175935.aspx)>

### Configure failover clustering (for SQL Server AlwaysOn Availability Group)

---

**FOOBAR8**

```PowerShell
cls
```

#### # Add a second network adapter for cluster network

```PowerShell
$vmHost = "BEAST"
$vmName = "TT-SQL01B"

Stop-VM -ComputerName $vmHost -Name $vmName

Add-VMNetworkAdapter -ComputerName $vmHost -VMName $vmName -SwitchName "Production"

Start-VM -ComputerName $vmHost -Name $vmName
```

---

#### Login as TECHTOOLBOX\\setup-sql

```PowerShell
cls
```

#### # Configure cluster network settings

```PowerShell
$interfaceAlias = "Cluster"
```

##### # Rename cluster network adapter

```PowerShell
Get-NetAdapter `
    -InterfaceDescription "Microsoft Hyper-V Network Adapter #2" |
    Rename-NetAdapter -NewName $interfaceAlias
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
$ipAddress = "172.16.0.2"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24
```

##### # Configure static IPv6 address

**# Note:** Private IPv6 address range (fd66:d7e2:39d6:a4d9::/64) generated by [http://simpledns.com/private-ipv6.aspx](http://simpledns.com/private-ipv6.aspx)

```PowerShell
$ipAddress = "fd66:d7e2:39d6:a4d9::2"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 64
```

```PowerShell
cls
```

#### # Install Failover Clustering feature on second node

```PowerShell
Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools
```

## Install SQL Server 2016

### Reference

**Set up SQL Server for TFS**\
Pasted from <[http://msdn.microsoft.com/en-us/library/jj620927.aspx](http://msdn.microsoft.com/en-us/library/jj620927.aspx)>

### # Install SQL Server 2016

---

**FOOBAR8**

```PowerShell
cls
```

#### # Insert the SQL Server 2016 installation media

```PowerShell
$vmHost = "BEAST"
$vmName = "TT-SQL01B"

$isoPath = "\\ICEMAN\Products\Microsoft\SQL Server 2016\" `
    + "\en_sql_server_2016_enterprise_with_service_pack_1_x64_dvd_9542382.iso"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $isoPath
```

---

```PowerShell
cls
# Create folder for TempDB data files

New-Item `
    -Path "T:\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Data" `
    -ItemType Directory
```

#### # Launch SQL Server setup

```PowerShell
& X:\Setup.exe
```

On the **Feature Selection** step, select the following checkboxes:

- **Database Engine Services**
  - **Full-Text and Semantic Extractions for Search**
- **Analysis Services**

> **Important**
>
> Do not select **Reporting Services - Native**. This will be installed on the TFS App Tier server.

On the **Server Configuration** step:

- For the **SQL Server Agent** service, change the **Startup Type** to **Automatic**.
- For the **SQL Server Database Engine** service, change the **Account Name **to **TECHTOOLBOX\\s-sql01**.
- For the **SQL Server Browser** service, leave the **Startup Type** as **Disabled**.

On the **Database Engine Configuration** step:

- On the **Server Configuration** tab, in the **Specify SQL Server administrators** section, click **Add...** and then add the domain group for SQL Server administrators.
- On the **Data Directories** tab:
  - In the **Data root directory** box, type **D:\\Microsoft SQL Server\\**.
  - In the **User database log directory** box, change the drive letter to **L:** (the value should be **L:\\Microsoft SQL Server\\MSSQL13.MSSQLSERVER\\MSSQL\\Data**).
  - In the **Backup directory** box, change the drive letter to **Z:** (the value should be **Z:\\Microsoft SQL Server\\MSSQL13.MSSQLSERVER\\MSSQL\\Backup**).
- On the **TempDB **tab:
  - In the **TempDB data files** section:
    - Click **Remove** to remove the default data directory.
    - Click **Add...**
    - In the **Browse For Folder** window, select **T:\\Microsoft SQL Server\\MSSQL13.MSSQLSERVER\\MSSQL\\Data** and click **OK**.
  - In the **TempDB log file** section:
    - In the **Log directory** box, change the drive letter to **T:** (the value should be **T:\\Microsoft SQL Server\\MSSQL13.MSSQLSERVER\\MSSQL\\Data**).

On the **Analysis Services Configuration** step:

- On the **Server Configuration** tab, in the **Specify SQL Server administrators** section, click **Add...** and then add the domain group for SQL Server administrators.
- On the **Data Directories** tab:
  - In the **Data directory** box, type **D:\\Microsoft SQL Server\\MSAS13.MSSQLSERVER\\OLAP\\Data**.
  - In the **Log file directory** box, type **L:\\Microsoft SQL Server\\MSAS13.MSSQLSERVER\\OLAP\\Log**.
  - In the **Temp directory** box, type **T:\\Microsoft SQL Server\\MSAS13.MSSQLSERVER\\OLAP\\Temp**.
  - In the **Backup directory** box, type **Z:\\Microsoft SQL Server\\MSAS13.MSSQLSERVER\\OLAP\\Backup**.

```PowerShell
cls
```

### # Install SQL Server Management Studio

```PowerShell
& "\\ICEMAN\Products\Microsoft\SQL Server 2016\SSMS-Setup-ENU.exe"
```

```PowerShell
cls
```

## # Configure firewall rules for SQL Server

```PowerShell
New-NetFirewallRule `
    -Name "SQL Server Analysis Services" `
    -DisplayName "SQL Server Analysis Services" `
    -Group 'Technology Toolbox (Custom)' `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 2383 `
    -Action Allow

New-NetFirewallRule `
    -Name "SQL Server Database Engine" `
    -DisplayName "SQL Server Database Engine" `
    -Group 'Technology Toolbox (Custom)' `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 1433 `    -Action Allow

New-NetFirewallRule `
    -Name "SQL Server High Availability" `
    -DisplayName "SQL Server High Availability" `
    -Group 'Technology Toolbox (Custom)' `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 5022 `
    -Action Allow
```

> **Note**
>
> Port 5022 is used for database mirroring (e.g. AlwaysOn Availability Groups).

```PowerShell
cls
```

## # Fix permissions to avoid "ESENT" errors in event log

```PowerShell
icacls C:\Windows\System32\LogFiles\Sum\Api.chk /grant 'TECHTOOLBOX\s-sql01:(M)'

icacls C:\Windows\System32\LogFiles\Sum\Api.log /grant 'TECHTOOLBOX\s-sql01:(M)'

icacls C:\Windows\System32\LogFiles\Sum\SystemIdentity.mdb /grant 'TECHTOOLBOX\s-sql01:(M)'

icacls C:\Windows\System32\LogFiles\Sum\Api.chk /grant 'NT Service\MSSQLServerOLAPService:(M)'

icacls C:\Windows\System32\LogFiles\Sum\Api.log /grant 'NT Service\MSSQLServerOLAPService:(M)'

icacls C:\Windows\System32\LogFiles\Sum\SystemIdentity.mdb /grant 'NT Service\MSSQLServerOLAPService:(M)'
```

### Reference

**Error 1032 messages in the Application log in Windows Server 2012**\
Pasted from <[http://support.microsoft.com/kb/2811566](http://support.microsoft.com/kb/2811566)>

```PowerShell
cls
```

## # Configure AlwaysOn Availability Group

### # Enable AlwaysOn Availability Groups

```PowerShell
Enable-SqlAlwaysOn -ServerInstance $env:COMPUTERNAME -Force
```

```PowerShell
cls
```

## # Install DPM agent

### # Install DPM 2016 agent

```PowerShell
$installer = "\\TT-FS01\Products\Microsoft\System Center 2016" `
    + "\Agents\DPMAgentInstaller_x64.exe"

& $installer TT-DPM01.corp.technologytoolbox.com
```

---

**TT-DPM01 - DPM Management Shell**

```PowerShell
cls
```

### # Attach DPM agent

```PowerShell
$productionServer = 'TT-SQL01B'

.\Attach-ProductionServer.ps1 `
    -DPMServerName TT-DPM01 `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `
    -UserName jjameson-admin
```

---

---

**TT-SQL01B - SQL Server Management Studio**

### -- Add "Local System" account to SQL Server sysadmin role

```SQL
ALTER SERVER ROLE [sysadmin] ADD MEMBER [NT AUTHORITY\SYSTEM]
GO
```

### -- Add failover cluster account to SQL Server sysadmin role

```SQL
USE master
GO
CREATE LOGIN [TECHTOOLBOX\TT-SQL01-FC$]
FROM WINDOWS WITH DEFAULT_DATABASE=master
GO
ALTER SERVER ROLE sysadmin ADD MEMBER [TECHTOOLBOX\TT-SQL01-FC$]
GO
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

---

**TT-VMM01**

## # Reconfigure "Cluster" network adapter

```PowerShell
$vm = Get-SCVirtualMachine TT-SQL01B

Stop-SCVirtualMachine $vm

$networkAdapter =  Get-SCVirtualNetworkAdapter -VM $vm |
    ? { $_.SlotId -eq 1 }
```

### # Connect network adapter to Cluster VM Network

```PowerShell
$vmNetwork = Get-SCVMNetwork -Name "Cluster VM Network"

$vmSubnet = $vmNetwork.VMSubnet[0]

$portClassification = Get-SCPortClassification -Name "Host Cluster Workload"

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VirtualNetwork "Embedded Team Switch" `
    -PortClassification $portClassification `
    -VMNetwork $vmNetwork `
    -VMSubnet $vmSubnet
```

### # Assign static IP address to network adapter for cluster traffic

```PowerShell
$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"

$ipAddressPool = Get-SCStaticIPAddressPool -Name "Cluster Address Pool"

$macAddress = Grant-SCMACAddress `
    -MACAddressPool $macAddressPool `
    -Description $vm.Name `
    -VirtualNetworkAdapter $networkAdapter

$ipAddress = Grant-SCIPAddress `
    -GrantToObjectType VirtualNetworkAdapter `
    -GrantToObjectID $networkAdapter.ID `
    -StaticIPAddressPool $ipAddressPool `
    -Description $vm.Name

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -MACAddressType Static `
    -MACAddress $macAddress `
    -IPv4AddressType Static `
    -IPv4Address $ipAddress

Start-SCVirtualMachine $vm
```

---

## Issue - Incorrect IPv6 DNS server assigned by Comcast router

```Text
PS C:\Users\jjameson-admin> nslookup
Default Server:  cdns01.comcast.net
Address:  2001:558:feed::1
```

> **Note**
>
> Even after reconfiguring the **Primary DNS** and **Secondary DNS** settings on the Comcast router -- and subsequently restarting the VM -- the incorrect DNS server is assigned to the network adapter.

### Solution

```PowerShell
Set-DnsClientServerAddress `
    -InterfaceAlias Management `
    -ServerAddresses 2603:300b:802:8900::103, 2603:300b:802:8900::104

Restart-Computer
```

## Rebuild DPM 2016 server (replace TT-DPM01 with TT-DPM02)

### Remove DPM agent

Restart the server to complete the removal.

### # Install DPM agent

```PowerShell
$installer = "\\TT-FS01\Products\Microsoft\System Center 2016" `
    + "\DPM\Agents\DPMAgentInstaller_x64.exe"

& $installer TT-DPM02.corp.technologytoolbox.com
```

---

**TT-DPM02 - DPM Management Shell**

```PowerShell
cls
```

### # Attach DPM agent

```PowerShell
$productionServer = 'TT-SQL01B'

.\Attach-ProductionServer.ps1 `
    -DPMServerName TT-DPM02 `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `
    -UserName jjameson-admin
```

---

## Issue - Database backup failing in DPM

Affected area:	TT-SQL01\\OperationsManagerDW\
Occurred since:	8/14/2017 6:16:23 PM\
Description:	Recovery point creation jobs for SQL Server 2016 database TT-SQL01\\OperationsManagerDW on TT-SQL01.TT-SQL01-FC.corp.technologytoolbox.com have been failing. The number of failed recovery point creation jobs = 35.\
 If the data source protected has some dependent data sources (like a SharePoint Farm), then click on the Error Details to view the list of dependent data sources for which recovery point creation failed. (ID 3114)\
Execution of SQL command failed for SQL Server 2016 database TT-SQL01\\OperationsManagerDW on TT-SQL01.TT-SQL01-FC.corp.technologytoolbox.com with reason : BACKUP LOG is terminating abnormally.\
Write on "L:\\Microsoft SQL Server\\MSSQL13.MSSQLSERVER\\MSSQL\\Data\\DPM_SQL_PROTECT\\TT-SQL01B\\OperationsManagerDW.ldf\\Backup\\Current.log" failed: 112(There is not enough space on the disk.)\
Write on "L:\\Microsoft SQL Server\\MSSQL13.MSSQLSERVER\\MSSQL\\Data\\DPM_SQL_PROTECT\\TT-SQL01B\\OperationsManagerDW.ldf\\Backup\\Current.log" failed: 112(There is not enough space on the disk.)\
. (ID 30173 Details: Internal error code: 0x80990D18)\
More information\
Recommended action:	Check the Application Event Viewer logs on the SQL Server for entries posted by the SQL Server service to find out why the SQL command may have failed. For more details, look at the SQL Server error logs.\
Create a recovery point...\
Resolution:	To dismiss the alert, click below\
Inactivate

> **Note**
>
> There is currently 1.5 GB of free space on the Log01 drive, but apparently DPM needs more for this particular database.

### Expand L: (Log01) drive

---

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Increase the size of "Data01" VHD

```PowerShell
$vmHost = "TT-HV02B"
$vmName = "TT-SQL01B"

Resize-VHD `
    -ComputerName $vmHost `
    -Path ("E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
        + $vmName + "_Log01.vhdx") `
    -SizeBytes 15GB
```

---

```PowerShell
cls
```

#### # Extend partition

```PowerShell
$driveLetter = "L"

$partition = Get-Partition -DriveLetter $driveLetter |
    where { $_.DiskNumber -ne $null }

$size = (Get-PartitionSupportedSize `
    -DiskNumber $partition.DiskNumber `
    -PartitionNumber $partition.PartitionNumber)

Resize-Partition `
    -DiskNumber $partition.DiskNumber `
    -PartitionNumber $partition.PartitionNumber `
    -Size $size.SizeMax
```

## Issue - Not enough free space to install patches (Windows Update)

6.66 GB of free space (after removing **C:\\Windows\\SoftwareDistribution**), but still unable to install **2017-10 Cumulative Update for Windows Server 2016 for x64-based Systems (KB4041691)**.

### Expand C:

---

**FOOBAR10**

```PowerShell
cls
```

#### # Increase size of VHD

```PowerShell
$vmHost = "TT-HV02B"
$vmName = "TT-SQL01B"

Stop-VM -ComputerName $vmHost -Name $vmName

Resize-VHD `
    -ComputerName $vmHost `
    -Path ("E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
        + $vmName + ".vhdx") `
    -SizeBytes 35GB

Start-VM -ComputerName $vmHost -Name $vmName
```

---

#### # Extend partition

```PowerShell
$size = (Get-PartitionSupportedSize -DiskNumber 0 -PartitionNumber 2)
Resize-Partition -DiskNumber 0 -PartitionNumber 2 -Size $size.SizeMax

Resize-Partition : Size Not Supported

Extended information:
The partition is already the requested size.

Activity ID: {a0136363-f246-47b5-9ca4-2824b3adf236}
At line:1 char:1
+ Resize-Partition -DiskNumber 0 -PartitionNumber 2 -Size $size.SizeMax
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (StorageWMI:ROOT/Microsoft/.../MSFT_Partition) [Resize-Partition], CimException
    + FullyQualifiedErrorId : StorageWMI 4097,Resize-Partition
```

The error is due to the recovery partition:

![(screenshot)](https://assets.technologytoolbox.com/screenshots/59/D5F36F57939457DC81F72838629E8FEBE2DC3A59.png)

#### # Delete recovery partition

```PowerShell
Get-Partition -DiskNumber 0 -PartitionNumber 3


   DiskPath:
\\?\ide#diskvirtual_hd______________________________1.1.0___#5&1278c138&0&0.0.0#{53f56307-b6bf-11d0-94f2-00a0c91efb8b}

PartitionNumber  DriveLetter Offset                              Size Type
---------------  ----------- ------                              ---- ----
3                            34018951168                       324 MB Unknown


Get-Partition -DiskNumber 0 -PartitionNumber 3 | Remove-Partition -Confirm:$false
```

```PowerShell
cls
```

#### # Extend partition

```PowerShell
$size = (Get-PartitionSupportedSize -DiskNumber 0 -PartitionNumber 2)
Resize-Partition -DiskNumber 0 -PartitionNumber 2 -Size $size.SizeMax
```

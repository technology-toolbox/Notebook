# TT-SQL01A - Windows Server 2016 Standard Edition

Thursday, January 12, 2017
7:47 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create and configure setup account for SQL Server

#### # Create setup account for SQL Server

```PowerShell
$displayName = "Setup account for SQL Server"
$defaultUserName = "setup-sql"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@corp.technologytoolbox.com"
$orgUnit = "OU=Setup Accounts,OU=IT,DC=corp,DC=technologytoolbox,DC=com"

New-ADUser `
    -Name $displayName `
    -DisplayName $displayName `
    -SamAccountName $cred.UserName `
    -AccountPassword $cred.Password `
    -UserPrincipalName $userPrincipalName `
    -Path $orgUnit `
    -Enabled:$true `
    -CannotChangePassword:$true `
    -PasswordNeverExpires:$true
```

#### # Add setup account to SQL Server Admins domain group

```PowerShell
Add-ADGroupMember `
    -Identity "SQL Server Admins" `
    -Members "setup-sql"
```

```PowerShell
cls
```

### # Create service account for SQL Server cluster

#### # Create service account for SQL Server cluster (TT-SQL01)

```PowerShell
$displayName = "Service account for SQL Server cluster (TT-SQL01)"
$defaultUserName = "s-sql01"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@corp.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=IT,DC=corp,DC=technologytoolbox,DC=com"

New-ADUser `
    -Name $displayName `
    -DisplayName $displayName `
    -SamAccountName $cred.UserName `
    -AccountPassword $cred.Password `
    -UserPrincipalName $userPrincipalName `
    -Path $orgUnit `
    -Enabled:$true `
    -CannotChangePassword:$true `
    -PasswordNeverExpires:$true
```

```PowerShell
cls
```

### # Create failover cluster objects in Active Directory

#### # Create cluster object for SQL Server failover cluster and delegate permission to create the cluster to any member of the SQL Server administrators group

```PowerShell
$failoverClusterName = "TT-SQL01-FC"
$delegate = "SQL Server Admins"
$orgUnit = "OU=SQL Servers,OU=Servers,OU=Resources,OU=IT," `
    + "DC=corp,DC=technologytoolbox,DC=com"

C:\NotBackedUp\Public\Toolbox\PowerShell\New-ClusterObject.ps1 `
    -Name $failoverClusterName  `
    -Delegate $delegate `
    -Path $orgUnit
```

#### # Create failover cluster name for SQL Server availability group listener and delegate permission to create the listener name to the failover cluster service (TT-SQL01-FC\$)

```PowerShell
$failoverClusterName = "TT-SQL01"
$delegate = "TT-SQL01-FC$"
$description = "Failover cluster name for SQL Server availability group"

C:\NotBackedUp\Public\Toolbox\PowerShell\New-ClusterObject.ps1 `
    -Name $failoverClusterName  `
    -Delegate $delegate `
    -Description $description `
    -Path $orgUnit
```

---

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "FORGE"
$vmName = "TT-SQL01A"
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
- On the **Computer Details** step, in the **Computer name** box, type **TT-SQL01A** and click **Next**.
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
$vmHost = "FORGE"
$vmName = "TT-SQL01A"

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
$vmHost = "FORGE"
$vmName = "TT-SQL01A"

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

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\ATTO Disk Benchmark\Bench32.exe'
```

### Benchmark C: (Mirror SSD/HDD storage space)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/09/EDBA5D7BF9BBE74ECDD28A13055454EBAE487109.png)

### Benchmark D: (Mirror SSD/HDD storage space)

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

```PowerShell
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
$vmHost = "FORGE"
$vmName = "TT-SQL01A"

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
$ipAddress = "172.16.0.1"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24
```

##### # Configure static IPv6 address

**# Note:** Private IPv6 address range (fd66:d7e2:39d6:a4d9::/64) generated by [http://simpledns.com/private-ipv6.aspx](http://simpledns.com/private-ipv6.aspx)

```PowerShell
$ipAddress = "fd66:d7e2:39d6:a4d9::1"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 64
```

```PowerShell
cls
```

#### # Install Failover Clustering feature on first node

```PowerShell
Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools
```

#### Install Failover Clustering feature on second node

```PowerShell
cls
```

#### # Run all cluster validation tests

```PowerShell
Test-Cluster -Node TT-SQL01A, TT-SQL01B
```

> **Note**
>
> Wait for the cluster validation tests to complete.

```PowerShell
& "$env:TEMP\Validation Report 2017.01.17 At 06.12.14.htm"
```

```PowerShell
cls
```

#### # Create cluster

```PowerShell
New-Cluster -Name TT-SQL01-FC -Node TT-SQL01A, TT-SQL01B -NoStorage

WARNING: There were issues while creating the clustered role that may prevent it from starting. For more information view the report file below.
WARNING: Report file location: C:\windows\cluster\Reports\Create Cluster Wizard TT-SQL01-FC on 2017.01.17 At 09.47.48.htm

Name
----
TT-SQL01-FC


& "C:\windows\cluster\Reports\Create Cluster Wizard TT-SQL01-FC on 2017.01.17 At 09.47.48.htm"
```

> **Note**
>
> The cluster creation report contains the following warning:
>
> - **An appropriate disk was not found for configuring a disk witness. The cluster is not configured with a witness. As a best practice, configure a witness to help achieve the highest availability of the cluster. If this cluster does not have shared storage, configure a File Share Witness or a Cloud Witness.**

#### Configure cluster quorum

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

##### # Configure file share for cluster quorum witness

```PowerShell
Enter-PSSession ICEMAN
```

---

**TT-FS01**

###### # Create folder

```PowerShell
$folderName = "Witness`$"
$path = "D:\Shares\$folderName"

New-Item -Path $path -ItemType Directory
```

###### # Remove "BUILTIN\\Users" permissions

```PowerShell
icacls $path /inheritance:d
icacls $path /remove:g "BUILTIN\Users"
```

###### # Share folder

```PowerShell
New-SmbShare `
    -Name $folderName `
    -Path $path `
    -CachingMode None `
    -ChangeAccess Everyone
```

###### # Grant permissions for SQL Server administrators

```PowerShell
icacls $path /grant '"SQL Server Admins":(OI)(CI)(RX)'
```

###### # Create folder for specific failover cluster (TT-SQL01-FC)

```PowerShell
$path = "$path\TT-SQL01-FC"

New-Item -Path $path -ItemType Directory
```

###### # Grant permissions for failover cluster service

```PowerShell
icacls $path /grant 'TT-SQL01-FC$:(OI)(CI)(F)'

exit
```

---

---

```PowerShell
cls
```

##### # Set file share as cluster quorum witness

```PowerShell
Set-ClusterQuorum -NodeAndFileShareMajority \\TT-FS01\Witness$\TT-SQL01-FC
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
$vmHost = "FORGE"
$vmName = "TT-SQL01A"

$isoPath = "\\ICEMAN\Products\Microsoft\SQL Server 2016\" `
    + "\en_sql_server_2016_enterprise_with_service_pack_1_x64_dvd_9542382.iso"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $isoPath
```

---

```PowerShell
cls
```

#### # Create folder for TempDB data files

```PowerShell
New-Item `
```

    -Path "T:\\Microsoft SQL Server\\MSSQL13.MSSQLSERVER\\MSSQL\\Data" `\
    -ItemType Directory

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
    -Name "SQL Server Mirroring" `
    -DisplayName "SQL Server Mirroring" `
    -Group 'Technology Toolbox (Custom)' `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 5022 `
    -Action Allow
```

> **Note**
>
> Port 5022 is required for AlwaysOn Availability Groups.

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

### # Create file share (for initial synchronization of databases)

```PowerShell
New-SmbShare `
    -Name SQL-Backups `
    -Path 'Z:\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup' `
    -CachingMode None `
    -FullAccess "NT AUTHORITY\Authenticated Users"
```

```PowerShell
cls
```

### # Create AlwaysOn Availability Group

---

**SQL Server Management Studio (TT-SQL01A)**

#### -- Create initial database for Availability Group

```SQL
CREATE DATABASE AlwaysOn
GO
```

#### -- Create full backup of database

```SQL
DECLARE @backupFilePath VARCHAR(255) =
    'Z:\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\'
        + 'AlwaysOn.bak'

BACKUP DATABASE AlwaysOn
    TO DISK = @backupFilePath
    WITH NOFORMAT, NOINIT, NAME = N'AlwaysOn-Full Database Backup',
        SKIP, NOREWIND, NOUNLOAD, STATS = 10

GO
```

#### Create Availability Group

1. In **Object Explorer**, expand **AlwaysOn High Availability**.
2. Right-click **Availability Groups**, and select **New Availability Group Wizard...**
3. In the **New Availability Group** window:
   1. On the **Introduction** page, click **Next**.
   2. On the **Specify Name** page, in the **Availability group name** box, type **TT-SQL01**, and click **Next**.
   3. On the **Select Databases** page, select the checkbox for **AlwaysOn**, and click **Next**.
   4. On the **Specify Replicas** page:
      1. Click **Add Replica...**
      2. In the **Connect to Server** window, in the **Server name** box, type **TT-SQL01B**, and click **Connect**.
      3. For the **TT-SQL01A** and **TT-SQL01B** server instances, select the **Automatic Failover **checkbox. This will automatically select the checkbox for synchronous replication for each SQL Server instance.
      4. On the **Listener** tab:
         1. Select the **Create an availability group listener** option.
         2. In the **Listener DNS Name** box, type **TT-SQL01**.
         3. In the **Port **box, type **1433**.
         4. In the **Network Mode **dropdown, select **DHCP**.
         5. Ensure the **Subnet** dropdown is set to **192.168.10.0/24**.
      5. Click **Next**.
   5. On the **Select Data Synchronization** page:
      1. Ensure the **Full** option is selected. The wizard subsequently triggers a full backup of the database, logs to a location you specify, and restores this backup to the secondary SQL Server instance, in this case, TT-SQL01B. From there, replication begins synchronously between TT-SQL01A and TT-SQL01B.
      2. In the **Specify a shared network location accessible by all replicas** box, type **[\\\\TT-SQL01A\\SQL-Backups](\\TT-SQL01A\SQL-Backups)**.
      3. Click **Next** to begin validation.
   6. After validation is complete, review the results, and click **Next**.
   7. On the **Summary** page, review all of your selections, and click **Finish** to begin the process. This will take a few moments to complete. When the process is complete, close SQL Server Management Studio.
4. Open Failover Cluster Manager.
5. Expand **TT-SQL01-FC.corp.technologytoolbox.com**, and then click **Roles**. A new role named **TT-SQL01** will be running.

---

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
$productionServer = 'TT-SQL01A'

.\Attach-ProductionServer.ps1 `
    -DPMServerName TT-DPM01 `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `
    -UserName jjameson-admin
```

---

---

**SQL Server Management Studio**

### -- Add "Local System" account to SQL Server sysadmin role

```SQL
ALTER SERVER ROLE [sysadmin] ADD MEMBER [NT AUTHORITY\SYSTEM]
GO
```

---

#### Reference

**Protection agent jobs may fail for SQL Server 2012 databases**\
Pasted from <[http://technet.microsoft.com/en-us/library/dn281948.aspx](http://technet.microsoft.com/en-us/library/dn281948.aspx)>

### Issue: Databases do not appear in DPM under Availability Group name

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2F/574107C32DB76899B1FA19A1FFE34DADDCA7072F.png)

#### Solution

Install Update Rollup 2 for Data Protection Manager 2016 and upgrade the DPM agents on the SQL cluster nodes

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EC/A985CF8C9B9251239E4790A23210E37FD95E7EEC.png)

### Issue: "Replica is inconstent" for all databases in Availability Group

The backups initially succeed, but then switch to "Replica is inconsistent"

#### Error detail

Affected area:	TT-SQL01\\VirtualManagerDB\
Occurred since:	2/20/2017 11:24:02 AM\
Description:	The replica of SQL Server 2016 database TT-SQL01\\VirtualManagerDB on TT-SQL01.TT-SQL01-FC.corp.technologytoolbox.com is inconsistent with the protected data source. All protection activities for data source will fail until the replica is synchronized with consistency check. You can recover data from existing recovery points, but new recovery points cannot be created until the replica is consistent.

For SharePoint farm, recovery points will continue getting created with the databases that are consistent. To backup inconsistent databases, run a consistency check on the farm. (ID 3106)\
The DPM job failed for SQL Server 2016 database TT-SQL01\\VirtualManagerDB on TT-SQL01.TT-SQL01-FC.corp.technologytoolbox.com because the SQL Server instance refused a connection to the protection agent. (ID 30172 Details: Internal error code: 0x80990F75)\
More information\
Recommended action:	This can happen if the SQL Server process is overloaded, or running short of memory. Please ensure that you are able to successfully run transactions against the SQL database in question and then retry the failed job.\
Synchronize with consistency check.\
Run a synchronization job with consistency check...\
Resolution:	To dismiss the alert, click below\
Inactivate

#### Solution

---

**TT-SQL01 - SQL Server Management Studio**

##### -- Change "Readable Secondary" property from "No" (default) to "Yes" (since backup preference defaults to "Prefer Secondary")

```SQL
USE [master]
GO
ALTER AVAILABILITY GROUP [TT-SQL01]
MODIFY REPLICA ON N'TT-SQL01A'
WITH (SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL))
GO
ALTER AVAILABILITY GROUP [TT-SQL01]
MODIFY REPLICA ON N'TT-SQL01B'
WITH (SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL))
GO
```

---

#### Reference

**SQL 2012 AlwaysOn protection in Data Protection Manager fails with Internal error code 0x80990F75**\
From <[https://support.microsoft.com/en-us/help/2769094/sql-2012-alwayson-protection-in-data-protection-manager-fails-with-internal-error-code-0x80990f75](https://support.microsoft.com/en-us/help/2769094/sql-2012-alwayson-protection-in-data-protection-manager-fails-with-internal-error-code-0x80990f75)>

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
$vm = Get-SCVirtualMachine TT-SQL01A

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
$productionServer = 'TT-SQL01A'

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
$vmHost = "TT-HV02A"
$vmName = "TT-SQL01A"

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

7.53 GB of free space (after removing **C:\\Windows\\SoftwareDistribution**), but still unable to install **2017-10 Cumulative Update for Windows Server 2016 for x64-based Systems (KB4041691)**.

### Expand C

---

**FOOBAR10**

```PowerShell
cls
```

#### # Increase size of VHD

```PowerShell
$vmHost = "TT-HV02A"
$vmName = "TT-SQL01A"

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

Activity ID: {a09377cd-ea73-4153-9181-8bde75e37ce6}
At line:1 char:1
+ Resize-Partition -DiskNumber 0 -PartitionNumber 2 -Size $size.SizeMax
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (StorageWMI:ROOT/Microsoft/.../MSFT_Partition) [Resize-Partition], CimException
    + FullyQualifiedErrorId : StorageWMI 4097,Resize-Partition
```

The error is due to the recovery partition:

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2C/1E25643576BE277481FD4BA80E6E3F16141A042C.png)

#### # Delete recovery partition

```PowerShell
Get-Partition -DiskNumber 0


   DiskPath:
\\?\ide#diskvirtual_hd______________________________1.1.0___#5&1278c138&0&0.0.0#{53f56307-b6bf-11d0-94f2-00a0c91efb8b}

PartitionNumber  DriveLetter Offset                              Size Type
---------------  ----------- ------                              ---- ----
1                            1048576                           499 MB IFS
2                C           524288000                       31.19 GB IFS
3                            34018951168                       324 MB Unknown


Get-Partition -DiskNumber 0 -PartitionNumber 3


   DiskPath:
\\?\ide#diskvirtual_hd______________________________1.1.0___#5&1278c138&0&0.0.0#{53f56307-b6bf-11d0-94f2-00a0c91efb8b}

PartitionNumber  DriveLetter Offset                              Size Type
---------------  ----------- ------                              ---- ----
3                            34018951168                       324 MB Unknown


Get-Partition -DiskNumber 0 -PartitionNumber 3 | Remove-Partition
```

```PowerShell
cls
```

#### # Extend partition

```PowerShell
$size = (Get-PartitionSupportedSize -DiskNumber 0 -PartitionNumber 2)
Resize-Partition -DiskNumber 0 -PartitionNumber 2 -Size $size.SizeMax
```

## Configure SQL Server maintenance plans

### Create cleanup maintenance plan

<table>
<thead>
<th>
<p><strong>Name</strong></p>
</th>
<th>
<p><strong>Frequency</strong></p>
</th>
<th>
<p><strong>Daily Frequency</strong></p>
</th>
<th>
<p><strong>Maintenance Cleanup Task Settings</strong></p>
</th>
</thead>
<tr>
<td valign='top'>
<p>Remove Old Database Backups</p>
</td>
<td valign='top'>
<p>Occurs: <strong>Weekly</strong><br />
Recurs every: <strong>1</strong> week on</p>
<ul>
<li><strong>Saturday</strong></li>
</ul>
</td>
<td valign='top'>
<p>Occurs once at: <strong>11:55:00 AM</strong></p>
</td>
<td valign='top'>
<p><strong>History Cleanup Task</strong></p>
<p><strong>Delete historical data:</strong></p>
<ul>
<li><strong>Backup and restore history</strong></li>
<li><strong>SQL Server Agent job history</strong></li>
<li><strong>Maintenance plan history</strong></li>
</ul>
<p><strong>Remove historical data older than: 4 Week(s)</strong></p>
</td>
</tr>
</table>

#### Create maintenance plan to remove old historical data

1. Open **SQL Server Management Studio**.
2. In **Object Explorer**, expand **Management**, right-click **Maintenance Plans**, and click **Maintenance Plan Wizard**.
3. In the **Maintenance Plan Wizard** window:
   1. On the starting page, click **Next**.
   2. On the **Select Plan Properties** page:
      1. In the **Name** box, type **History Cleanup**.
      2. In the **Schedule** section, click **Change...**
      3. In the **New Job Schedule** window, configure the settings according to the configuration specified above, and click **OK**.
      4. Click **Next**.
   3. On the **Select Maintenance Tasks** page, in the list of maintenance tasks, select **Clean Up History**, and click **Next**.
   4. On the **Select Maintenance Task Order** page, click **Next**.
   5. On the **Define History Cleanup Task** window:
      1. Ensure the **Backup and restore history** checkbox is selected.
      2. Ensure the **SQL Server Agent job history** checkbox is selected.
      3. Ensure the **Maintenance plan history** checkbox is selected.
      4. Ensure the default timespan -- **4 Week(s)** -- is specified.
      5. Click **Next**.
   6. On the **Select Report Options **page, click **Next**.
   7. On the **Complete the Wizard **page, click **Finish**.

### Execute maintenance plan to remove historical data

Right-click **History Cleanup** and click **Execute**.

## Configure DCOM permissions for SQL Server

### Issue

Source: DCOM\
Event ID: 10016\
Event Category: 0\
User: NT SERVICE\\SQLSERVERAGENT\
Computer: TT-SQL01A.corp.technologytoolbox.com\
Event Description: The application-specific permission settings do not grant Local Activation permission for the COM Server application with CLSID\
{2DC39BD2-9CFF-405D-A2FE-D246C976278C}\
and APPID\
{DB336D8E-32E5-42B9-B14B-58AAA87CEB06}\
to the user NT SERVICE\\SQLSERVERAGENT SID (S-1-5-80-344959196-2060754871-2302487193-2804545603-1466107430) from address LocalHost (Using LRPC) running in the application container Unavailable SID (Unavailable). This security permission can be modified using the Component Services administrative tool.

> **Note**
>
> **DB336D8E-32E5-42B9-B14B-58AAA87CEB06** is the ID for **Microsoft SQL Server Integration Services 13.0**.

### Solution

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\SQL\Configure DCOM Permissions.ps1'
```

## Configure SQL Server maintenance

### Create SqlMaintenance database

### Create maintenance table, stored procedures, and jobs

#### Download MaintenanceSolution.sql

**SQL Server Backup, Integrity Check, and Index and Statistics Maintenance**\
From <[https://ola.hallengren.com/](https://ola.hallengren.com/)>

#### Apply customizations to SQL script

```Console
USE SqlMaintenance -- Specify the database in which the objects will be created.

...

EXEC master.dbo.xp_instance_regread
    N'HKEY_LOCAL_MACHINE'
    , N'Software\Microsoft\MSSQLServer\MSSQLServer'
    , N'BackupDirectory'
    , @BackupDirectory OUTPUT

SET @BackupDirectory     = N'C:\Backup' -- Specify the backup root directory.
```

### -- Configure schedules for SqlMaintenance jobs

```SQL
USE [msdb]
GO

EXEC msdb.dbo.sp_add_jobschedule
    @job_name = N'CommandLog Cleanup',
    @name = N'CommandLog Cleanup',
    @enabled = 1,
    @freq_type = 16, -- Monthly
    @freq_interval = 1, -- First day of the month
    @freq_subday_type = 1, -- At the specified time
    @freq_subday_interval = 0,
    @freq_relative_interval = 0,
    @freq_recurrence_factor = 1, -- Number of months between executions
    @active_start_date = 20170101,
    @active_end_date = 99991231,
    @active_start_time = 000100, -- 12:01 AM
    @active_end_time = 235959

GO

EXEC msdb.dbo.sp_add_jobschedule
    @job_name = N'DatabaseIntegrityCheck - SYSTEM_DATABASES',
    @name = N'DatabaseIntegrityCheck - SYSTEM_DATABASES',
    @enabled = 1,
    @freq_type = 8, -- Weekly
    @freq_interval = 64, -- Saturday
    @freq_subday_type = 1, -- At the specified time
    @freq_subday_interval = 0,
    @freq_relative_interval = 0,
    @freq_recurrence_factor = 1, -- Number of weeks between executions
    @active_start_date = 20170101,
    @active_end_date = 99991231,
    @active_start_time = 010500, -- 1:05 AM
    @active_end_time = 235959

GO

EXEC msdb.dbo.sp_add_jobschedule
    @job_name = N'DatabaseIntegrityCheck - USER_DATABASES',
    @name = N'DatabaseIntegrityCheck - USER_DATABASES',
    @enabled = 1,
    @freq_type = 8, -- Weekly
    @freq_interval = 64, -- Saturday
    @freq_subday_type = 1, -- At the specified time
    @freq_subday_interval = 0,
    @freq_relative_interval = 0,
    @freq_recurrence_factor = 1, -- Number of weeks between executions
    @active_start_date = 20170101,
    @active_end_date = 99991231,
    @active_start_time = 011000, -- 1:10 AM
    @active_end_time = 235959

GO

EXEC msdb.dbo.sp_add_jobschedule
    @job_name = N'IndexOptimize - USER_DATABASES',
    @name = N'IndexOptimize - USER_DATABASES',
    @enabled = 1,
    @freq_type = 8, -- Weekly
    @freq_interval = 32, -- Friday
    @freq_subday_type = 1, -- At the specified time
    @freq_subday_interval = 0,
    @freq_relative_interval = 0,
    @freq_recurrence_factor = 1, -- Number of weeks between executions
    @active_start_date = 20170101,
    @active_end_date = 99991231,
    @active_start_time = 220500, -- 10:05 PM
    @active_end_time = 235959

GO

EXEC msdb.dbo.sp_add_jobschedule
    @job_name = N'Output File Cleanup',
    @name = N'Output File Cleanup',
    @enabled = 1,
    @freq_type = 16, -- Monthly
    @freq_interval = 1, -- First day of the month
    @freq_subday_type = 1, -- At the specified time
    @freq_subday_interval = 0,
    @freq_relative_interval = 0,
    @freq_recurrence_factor = 1, -- Number of months between executions
    @active_start_date = 20170101,
    @active_end_date = 99991231,
    @active_start_time = 000200, -- 12:02 AM
    @active_end_time = 235959

GO

EXEC msdb.dbo.sp_add_jobschedule
    @job_name = N'sp_purge_jobhistory',
    @name = N'sp_purge_jobhistory',
    @enabled = 1,
    @freq_type = 16, -- Monthly
    @freq_interval = 1, -- First day of the month
    @freq_subday_type = 1, -- At the specified time
    @freq_subday_interval = 0,
    @freq_relative_interval = 0,
    @freq_recurrence_factor = 1, -- Number of months between executions
    @active_start_date = 20170101,
    @active_end_date = 99991231,
    @active_start_time = 000300, -- 12:03 AM
    @active_end_time = 235959

GO
```

## Issue: Error installing latest Cumulative Update

**2018-07 Cumulative Update for Windows Server 2016 for x64-based Systems (KB4345418)**

### # Restore WinSxS folder

```PowerShell
$wimSource = '\\TT-FS01\MDT-Build$\Operating Systems\WS2016-Feb-2018' `
    + '\sources\install.wim'

Dism.exe /Online /Cleanup-Image /RestoreHealth /Source:$wimSource
```

```PowerShell
cls
```

### # Reboot

```PowerShell
Restart-Computer
```

```PowerShell
cls
```

### # Clean up WinSxS folder

```PowerShell
Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase
```

### # Clean up Windows Update files

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse
```

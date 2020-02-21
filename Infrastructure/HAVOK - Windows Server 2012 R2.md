# HAVOK - Windows Server 2012 R2 Standard

Tuesday, September 8, 2015
1:30 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

---

**FOOBAR8**

## # Create virtual machine

```PowerShell
$vmHost = 'BEAST'
$vmName = 'HAVOK'

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path C:\NotBackedUp\VMs `
    -MemoryStartupBytes 8GB `
    -SwitchName "Virtual LAN 2 - 192.168.10.x"

Set-VMProcessor -ComputerName $vmHost -VMName $vmName -Count 4

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 25GB

Add-VMHardDiskDrive -ComputerName $vmHost -VMName $vmName -Path $vhdPath

$imagePath = '\\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso'

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $imagePath

Start-VM -ComputerName $vmHost -VMName $vmName
```

---

## Install custom Windows Server 2012 R2 image

- On the **Task Sequence** step, select **Windows Server 2012 R2** and click **Next**.
- On the **Computer Details** step, in the **Computer name** box, type **HAVOK** and click **Next**.
- On the **Applications** step, do not select any applications, and click **Next**.

## # Rename local Administrator account and set password

```PowerShell
$adminUser = [ADSI] 'WinNT://./Administrator,User'
$adminUser.Rename('foo')
$adminUser.SetPassword('{password}')

logoff
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

## # Rename network connection

```PowerShell
Get-NetAdapter -Physical

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "LAN 1 - 192.168.10.x"
```

## # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name "LAN 1 - 192.168.10.x" `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping ICEMAN -f -l 8900
```

```PowerShell
cls
```

## # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

## # Configure firewall rule for [http://poshpaig.codeplex.com/](POSHPAIG)

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

## # Add disks for SQL Server storage (Data01, Log01, Temp01, and Backup01)

---

**FOOBAR8**

## # Add disks to virtual machine

```PowerShell
$vmHost = "BEAST"
$vmName = "HAVOK"

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Fixed -SizeBytes 35GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path $vhdPath `
    -ControllerType SCSI

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Log01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Fixed -SizeBytes 8GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path $vhdPath `
    -ControllerType SCSI

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Temp01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Fixed -SizeBytes 2GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path $vhdPath `
    -ControllerType SCSI

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
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

## # Initialize disks and format volumes

```PowerShell
Get-Disk 1 |
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -UseMaximumSize -DriveLetter D |
    Format-Volume `
        -FileSystem NTFS `
        -AllocationUnitSize 64KB `
        -NewFileSystemLabel "Data01" `
        -Confirm:$false

Get-Disk 2 |
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -UseMaximumSize -DriveLetter L |
    Format-Volume `
        -FileSystem NTFS `
        -AllocationUnitSize 64KB `
        -NewFileSystemLabel "Log01" `
        -Confirm:$false

Get-Disk 3 |
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -UseMaximumSize -DriveLetter T |
    Format-Volume `
        -FileSystem NTFS `
        -AllocationUnitSize 64KB `
        -NewFileSystemLabel "Temp01" `
        -Confirm:$false

Get-Disk 4 |
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -UseMaximumSize -DriveLetter Z |
    Format-Volume `
        -FileSystem NTFS `
        -AllocationUnitSize 64KB `
        -NewFileSystemLabel "Backup01" `
        -Confirm:$false
```

## Install SQL Server 2014

### Reference

**Set up SQL Server for TFS**\
Pasted from <[http://msdn.microsoft.com/en-us/library/jj620927.aspx](http://msdn.microsoft.com/en-us/library/jj620927.aspx)>

**Note: **.NET Framework 3.5 is required for SQL Server 2014 Management Tools.

```PowerShell
cls
```

### # Install .NET Framework 3.5

```PowerShell
$sourcePath = "\\ICEMAN\Products\Microsoft\Windows Server 2012 R2\Sources\SxS"

Install-WindowsFeature NET-Framework-Core -Source $sourcePath
```

### # Install SQL Server 2014

---

**FOOBAR8**

#### # Insert the SQL Server 2014 installation media

```PowerShell
$vmHost = "BEAST"
$vmName = "HAVOK"

$isoPath = '\\ICEMAN\Products\Microsoft\SQL Server 2014\en_sql_server_2014_enterprise_edition_x64_dvd_3932700.iso'

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $isoPath
```

---

```PowerShell
cls
```

#### # Launch SQL Server setup

```PowerShell
& X:\Setup.exe
```

On the **Feature Selection** step, select the following checkboxes:

- **Database Engine Services**
  - **Full-Text and Semantic Extractions for Search**
- **Analysis Services**
- **Management Tools - Basic**
  - **Management Tools - Complete**

> **Important**
>
> Do not select **Reporting Services - Native**. This will be installed on the TFS App Tier server.

On the **Server Configuration** step:

- For the **SQL Server Agent** service, change the **Startup Type** to **Automatic**.
- For the **SQL Server Browser** service, leave the **Startup Type** as **Disabled**.

On the **Database Engine Configuration** step:

- On the **Server Configuration** tab, in the **Specify SQL Server administrators** section, click **Add...** and then add the domain group for SQL Server administrators.
- On the **Data Directories** tab:
  - In the **Data root directory** box, type **D:\\Microsoft SQL Server\\**.
  - In the **User database log directory** box, change the drive letter to **L:** (the value should be **L:\\Microsoft SQL Server\\MSSQL12.MSSQLSERVER\\MSSQL\\Data**).
  - In the **Temp DB directory** box, change the drive letter to **T:** (the value should be **T:\\Microsoft SQL Server\\MSSQL12.MSSQLSERVER\\MSSQL\\Data**).
  - In the **Backup directory** box, change the drive letter to **Z:** (the value should be **Z:\\Microsoft SQL Server\\MSSQL12.MSSQLSERVER\\MSSQL\\Backup**).

On the **Analysis Services Configuration** step:

- On the **Server Configuration** tab, in the **Specify SQL Server administrators** section, click **Add...** and then add the domain group for SQL Server administrators.
- On the **Data Directories** tab:
  - In the **Data directory** box, type **D:\\Microsoft SQL Server\\MSAS12.MSSQLSERVER\\OLAP\\Data**.
  - In the **Log file directory** box, type **L:\\Microsoft SQL Server\\MSAS12.MSSQLSERVER\\OLAP\\Log**.
  - In the **Temp directory** box, type **T:\\Microsoft SQL Server\\MSAS12.MSSQLSERVER\\OLAP\\Temp**.
  - In the **Backup directory** box, type **Z:\\Microsoft SQL Server\\MSAS12.MSSQLSERVER\\OLAP\\Backup**.

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
    -LocalPort 1433 `
    -Action Allow
```

## Configure Max Degree of Parallelism for SharePoint

### -- Set Max Degree of Parallelism to 1

```Console
EXEC sys.sp_configure N'show advanced options', N'1'  RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'max degree of parallelism', N'1'
GO
RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'show advanced options', N'0'  RECONFIGURE WITH OVERRIDE
GO
```

```Console
cls
```

### # Restart SQL Server

```PowerShell
Stop-Service SQLSERVERAGENT

Restart-Service MSSQLSERVER

Start-Service SQLSERVERAGENT
```

### Reference

Ensure the Max degree of parallelism is set to 1. For additional information about max degree of parallelism see, [Configure the max degree of parallism Server Configuration option](Configure the max degree of parallism Server Configuration option) and [Degree of Parallelism](Degree of Parallelism).

Pasted from <[http://technet.microsoft.com/en-us/library/ee805948.aspx](http://technet.microsoft.com/en-us/library/ee805948.aspx)>

```PowerShell
cls
```

## # Fix permissions to avoid "ESENT" errors in event log

```PowerShell
icacls C:\Windows\System32\LogFiles\Sum\Api.chk /grant 'NT Service\MSSQLSERVER:(M)'

icacls C:\Windows\System32\LogFiles\Sum\Api.log /grant 'NT Service\MSSQLSERVER:(M)'

icacls C:\Windows\System32\LogFiles\Sum\SystemIdentity.mdb /grant 'NT Service\MSSQLSERVER:(M)'

icacls C:\Windows\System32\LogFiles\Sum\Api.chk /grant 'NT Service\MSSQLServerOLAPService:(M)'

icacls C:\Windows\System32\LogFiles\Sum\Api.log /grant 'NT Service\MSSQLServerOLAPService:(M)'

icacls C:\Windows\System32\LogFiles\Sum\SystemIdentity.mdb /grant 'NT Service\MSSQLServerOLAPService:(M)'
```

### Reference

**Error 1032 messages in the Application log in Windows Server 2012**\
Pasted from <[http://support.microsoft.com/kb/2811566](http://support.microsoft.com/kb/2811566)>

## -- Configure TempDB

```SQL
DECLARE @dataPath VARCHAR(300);

SELECT
    @dataPath = REPLACE([filename], '.mdf','')
FROM
    sysaltfiles s
WHERE
    name = 'tempdev';

ALTER DATABASE [tempdb]
    MODIFY FILE
    (
        NAME = N'tempdev'
        , SIZE = 256MB
        , MAXSIZE = 512MB
        , FILEGROWTH = 128MB
    );

DECLARE @sqlStatement NVARCHAR(500);

SELECT @sqlStatement =
    N'ALTER DATABASE [tempdb]'
    + 'ADD FILE'
    + '('
        + 'NAME = N''tempdev2'''
        + ', FILENAME = ''' + @dataPath + '2.mdf'''
        + ', SIZE = 256MB'
        + ', MAXSIZE = 512MB'
        + ', FILEGROWTH = 128MB'
    + ')';

EXEC sp_executesql @sqlStatement;

SELECT @sqlStatement =
    N'ALTER DATABASE [tempdb]'
    + 'ADD FILE'
    + '('
        + 'NAME = N''tempdev3'''
        + ', FILENAME = ''' + @dataPath + '3.mdf'''
        + ', SIZE = 256MB'
        + ', MAXSIZE = 512MB'
        + ', FILEGROWTH = 128MB'
    + ')';

EXEC sp_executesql @sqlStatement;

SELECT @sqlStatement =
    N'ALTER DATABASE [tempdb]'
    + 'ADD FILE'
    + '('
        + 'NAME = N''tempdev4'''
        + ', FILENAME = ''' + @dataPath + '4.mdf'''
        + ', SIZE = 256MB'
        + ', MAXSIZE = 512MB'
        + ', FILEGROWTH = 128MB'
    + ')';

EXEC sp_executesql @sqlStatement;

ALTER DATABASE [tempdb]
    MODIFY FILE (
        NAME = N'templog',
        SIZE = 50MB,
        FILEGROWTH = 10MB
    )
```

## -- Restore database logins

```SQL
USE [master]
GO

CREATE LOGIN [TECHTOOLBOX\COLOSSUS$]
FROM WINDOWS WITH DEFAULT_DATABASE=[master]

CREATE LOGIN [TECHTOOLBOX\CYCLOPS$]
FROM WINDOWS WITH DEFAULT_DATABASE=[master]

CREATE LOGIN [TECHTOOLBOX\JUBILEE$]
FROM WINDOWS WITH DEFAULT_DATABASE=[master]

CREATE LOGIN [TECHTOOLBOX\s-scom-action]
FROM WINDOWS WITH DEFAULT_DATABASE=[master]

CREATE LOGIN [TECHTOOLBOX\s-scom-config-das]
FROM WINDOWS WITH DEFAULT_DATABASE=[master]

CREATE LOGIN [TECHTOOLBOX\s-scom-data-reader]
FROM WINDOWS WITH DEFAULT_DATABASE=[master]

CREATE LOGIN [TECHTOOLBOX\s-scom-data-writer]
FROM WINDOWS WITH DEFAULT_DATABASE=[master]

CREATE LOGIN [TECHTOOLBOX\svc-vmm]
FROM WINDOWS WITH DEFAULT_DATABASE=[master]
```

## -- Restore OLTP databases

```Console
RESTORE DATABASE AdventureWorks2012
FROM DISK = N'\\ICEMAN\Backups\HAVOK\AdventureWorks2012.bak'
WITH FILE = 1, NOUNLOAD, STATS = 5,
    MOVE N'AdventureWorks2012_Data' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\AdventureWorks2012.mdf',
    MOVE N'AdventureWorks2012_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\AdventureWorks2012.LDF'

RESTORE DATABASE AdventureWorksLT2012
FROM DISK = N'\\ICEMAN\Backups\HAVOK\AdventureWorksLT2012.bak'
WITH FILE = 1, NOUNLOAD, STATS = 5,
    MOVE N'AdventureWorksLT2008_Data' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\AdventureWorksLT2012.mdf',
    MOVE N'AdventureWorksLT2008_Log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\AdventureWorksLT2012.LDF'

RESTORE DATABASE Caelum
FROM DISK = N'\\ICEMAN\Backups\HAVOK\Caelum.bak'
WITH FILE = 1, NOUNLOAD, STATS = 5,
    MOVE N'DB_29334_caelum_data' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\Caelum.mdf',
    MOVE N'DB_29334_caelum_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Caelum.LDF'

RESTORE DATABASE Caelum_Warehouse
FROM DISK = N'\\ICEMAN\Backups\HAVOK\Caelum_Warehouse.bak'
WITH FILE = 1, NOUNLOAD, STATS = 5,
    MOVE N'Caelum_Warehouse' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\Caelum_Warehouse.mdf',
    MOVE N'Caelum_Warehouse_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Caelum_Warehouse.LDF'

RESTORE DATABASE LoadTest2010
FROM DISK = N'\\ICEMAN\Backups\HAVOK\LoadTest2010.bak'
WITH FILE = 1, NOUNLOAD, STATS = 5,
    MOVE N'LoadTest2010' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\LoadTest2010.mdf',
    MOVE N'LoadTest2010_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\LoadTest2010.LDF'

RESTORE DATABASE ManagedMetadataService
FROM DISK = N'\\ICEMAN\Backups\HAVOK\ManagedMetadataService.bak'
WITH FILE = 1, NOUNLOAD, STATS = 5,
    MOVE N'ManagedMetadataService' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\ManagedMetadataService.mdf',
    MOVE N'ManagedMetadataService_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\ManagedMetadataService.LDF'

RESTORE DATABASE OperationsManager
FROM DISK = N'\\ICEMAN\Backups\HAVOK\OperationsManager.bak'
WITH FILE = 1, NOUNLOAD, STATS = 5,
    MOVE N'MOM_DATA' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\OperationsManager.mdf',
    MOVE N'MOM_LOG' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\OperationsManager.LDF'

RESTORE DATABASE OperationsManagerDW
FROM DISK = N'\\ICEMAN\Backups\HAVOK\OperationsManagerDW.bak'
WITH FILE = 1, NOUNLOAD, STATS = 5,
    MOVE N'MOM_DATA' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\OperationsManagerDW.mdf',
    MOVE N'MOM_LOG' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\OperationsManagerDW.LDF'

RESTORE DATABASE ReportServer_SCOM
FROM DISK = N'\\ICEMAN\Backups\HAVOK\ReportServer_SCOM.bak'
WITH FILE = 1, NOUNLOAD, STATS = 5,
    MOVE N'ReportServer_SCOM' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\ReportServer_SCOM.mdf',
    MOVE N'ReportServer_SCOM_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\ReportServer_SCOM.LDF'

RESTORE DATABASE ReportServer_SCOMTempDB
FROM DISK = N'\\ICEMAN\Backups\HAVOK\ReportServer_SCOMTempDB.bak'
WITH FILE = 1, NOUNLOAD, STATS = 5,
    MOVE N'ReportServer_SCOMTempDB' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\ReportServer_SCOMTempDB.mdf',
    MOVE N'ReportServer_SCOMTempDB_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\ReportServer_SCOMTempDB.LDF'

RESTORE DATABASE ReportServer_TFS
FROM DISK = N'\\ICEMAN\Backups\HAVOK\ReportServer_TFS.bak'
WITH FILE = 1, NOUNLOAD, STATS = 5,
    MOVE N'ReportServer' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\ReportServer_TFS.mdf',
    MOVE N'ReportServer_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\ReportServer_TFS.LDF'

RESTORE DATABASE ReportServer_TFSTempDB
FROM DISK = N'\\ICEMAN\Backups\HAVOK\ReportServer_TFSTempDB.bak'
WITH FILE = 1, NOUNLOAD, STATS = 5,
    MOVE N'ReportServerTempDB' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\ReportServer_TFSTempDB.mdf',
    MOVE N'ReportServerTempDB_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\ReportServer_TFSTempDB.LDF'

RESTORE DATABASE SecureStoreService
FROM DISK = N'\\ICEMAN\Backups\HAVOK\SecureStoreService.bak'
WITH FILE = 1, NOUNLOAD, STATS = 5,
    MOVE N'Secure_Store_Service_DB' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\SecureStoreService.mdf',
    MOVE N'Secure_Store_Service_DB_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\SecureStoreService.LDF'

RESTORE DATABASE SqlMaintenance
FROM DISK = N'\\ICEMAN\Backups\HAVOK\SqlMaintenance.bak'
WITH FILE = 1, NOUNLOAD, STATS = 5,
    MOVE N'SqlMaintenance' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\SqlMaintenance.mdf',
    MOVE N'SqlMaintenance_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\SqlMaintenance.LDF'

RESTORE DATABASE SUSDB
FROM DISK = N'\\ICEMAN\Backups\HAVOK\SUSDB.bak'
WITH FILE = 1, NOUNLOAD, STATS = 5,
    MOVE N'SUSDB' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\SUSDB.mdf',
    MOVE N'SUSDB_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\SUSDB.LDF'

RESTORE DATABASE Tfs_Configuration
FROM DISK = N'\\ICEMAN\Backups\HAVOK\Tfs_Configuration.bak'
WITH FILE = 1, NOUNLOAD, STATS = 5,
    MOVE N'Tfs_Configuration' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\Tfs_Configuration.mdf',
    MOVE N'Tfs_Configuration_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Tfs_Configuration.LDF'

RESTORE DATABASE Tfs_DefaultCollection
FROM DISK = N'\\ICEMAN\Backups\HAVOK\Tfs_DefaultCollection.bak'
WITH FILE = 1, NOUNLOAD, STATS = 5,
    MOVE N'Tfs_DefaultCollection' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\Tfs_DefaultCollection.mdf',
    MOVE N'Tfs_DefaultCollection_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Tfs_DefaultCollection.ldf'

RESTORE DATABASE Tfs_IntegrationPlatform
FROM DISK = N'\\ICEMAN\Backups\HAVOK\Tfs_IntegrationPlatform.bak'
WITH FILE = 1, NOUNLOAD, STATS = 5,
    MOVE N'Tfs_IntegrationPlatform' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\Tfs_IntegrationPlatform.mdf',
    MOVE N'Tfs_IntegrationPlatform_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Tfs_IntegrationPlatform.LDF'

RESTORE DATABASE Tfs_Warehouse
FROM DISK = N'\\ICEMAN\Backups\HAVOK\Tfs_Warehouse.bak'
WITH FILE = 1, NOUNLOAD, STATS = 5,
    MOVE N'Tfs_Warehouse' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\Tfs_Warehouse.mdf',
    MOVE N'Tfs_Warehouse_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Tfs_Warehouse.LDF'

RESTORE DATABASE UserProfileService_Profile
FROM DISK = N'\\ICEMAN\Backups\HAVOK\UserProfileService_Profile.bak'
WITH FILE = 1, NOUNLOAD, STATS = 5,
    MOVE N'ProfileDB' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\UserProfileService_Profile.mdf',
    MOVE N'ProfileDB_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\UserProfileService_Profile.LDF'

RESTORE DATABASE UserProfileService_Social
FROM DISK = N'\\ICEMAN\Backups\HAVOK\UserProfileService_Social.bak'
WITH FILE = 1, NOUNLOAD, STATS = 5,
    MOVE N'SocialDB' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\UserProfileService_Social.mdf',
    MOVE N'SocialDB_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\UserProfileService_Social.LDF'

RESTORE DATABASE UserProfileService_Sync
FROM DISK = N'\\ICEMAN\Backups\HAVOK\UserProfileService_Sync.bak'
WITH FILE = 1, NOUNLOAD, STATS = 5,
    MOVE N'SyncDB' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\UserProfileService_Sync.mdf',
    MOVE N'SyncDB_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\UserProfileService_Sync.LDF'

RESTORE DATABASE VirtualManagerDB
FROM DISK = N'\\ICEMAN\Backups\HAVOK\VirtualManagerDB.bak'
WITH FILE = 1, NOUNLOAD, STATS = 5,
    MOVE N'VirtualManagerDB' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\VirtualManagerDB.mdf',
    MOVE N'VirtualManagerDB_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\VirtualManagerDB.LDF'

RESTORE DATABASE WSS_Content_MySites
FROM DISK = N'\\ICEMAN\Backups\HAVOK\WSS_Content_MySites.bak'
WITH FILE = 1, NOUNLOAD, STATS = 5,
    MOVE N'WSS_Content_MySites' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\WSS_Content_MySites.mdf',
    MOVE N'WSS_Content_MySites_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\WSS_Content_MySites.LDF'

RESTORE DATABASE WSS_Content_Team1
FROM DISK = N'\\ICEMAN\Backups\HAVOK\WSS_Content_Team1.bak'
WITH FILE = 1, NOUNLOAD, STATS = 5,
    MOVE N'WSS_Content_Team1' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\WSS_Content_Team1.mdf',
    MOVE N'WSS_Content_Team1_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\WSS_Content_Team1.LDF'

RESTORE DATABASE WSS_Content_ttweb
FROM DISK = N'\\ICEMAN\Backups\HAVOK\WSS_Content_ttweb.bak'
WITH FILE = 1, NOUNLOAD, STATS = 5,
    MOVE N'WSS_Content_ttweb' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\WSS_Content_ttweb.mdf',
    MOVE N'WSS_Content_ttweb_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\WSS_Content_ttweb.LDF'
```

## Restore TFS OLAP database

```XML
<Restore xmlns="http://schemas.microsoft.com/analysisservices/2003/engine">
  <File>\\ICEMAN\Backups\HAVOK\Tfs_Analysis.abf</File>
  <Password>{guess}</Password>
</Restore>
```

## Replace service account in TFS_Warehouse database

---

**FOOBAR8**

### # Create the "TFS reporting" service account

```PowerShell
$displayName = 'Service account for Team Foundation Server (Reports)'
$defaultUserName = 's-tfs-reports'

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

---

### -- Create database login for TFS reporting service account

```SQL
USE [master]
GO
CREATE LOGIN [TECHTOOLBOX\s-tfs-reports]
FROM WINDOWS WITH DEFAULT_DATABASE=[master]
GO
USE [Tfs_Warehouse]
GO
CREATE USER [TECHTOOLBOX\s-tfs-reports]
FOR LOGIN [TECHTOOLBOX\s-tfs-reports]
GO
ALTER ROLE [TfsWarehouseDataReader]
ADD MEMBER [TECHTOOLBOX\s-tfs-reports]
GO
```

### Add service account to role in TFS OLAP database

In the **Tfs_Analysis** database, add **TECHTOOLBOX\\s-tfs-reports** to **TfsWarehouseDataReader** role.

```XML
<Alter AllowCreate="true" ObjectExpansion="ObjectProperties" xmlns="http://schemas.microsoft.com/analysisservices/2003/engine">
  <Object>
    <DatabaseID>Tfs_Analysis</DatabaseID>
    <RoleID>TfsWarehouseDataReader</RoleID>
  </Object>
  <ObjectDefinition>
    <Role xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:ddl2="http://schemas.microsoft.com/analysisservices/2003/engine/2" xmlns:ddl2_2="http://schemas.microsoft.com/analysisservices/2003/engine/2/2" xmlns:ddl100_100="http://schemas.microsoft.com/analysisservices/2008/engine/100/100" xmlns:ddl200="http://schemas.microsoft.com/analysisservices/2010/engine/200" xmlns:ddl200_200="http://schemas.microsoft.com/analysisservices/2010/engine/200/200" xmlns:ddl300="http://schemas.microsoft.com/analysisservices/2011/engine/300" xmlns:ddl300_300="http://schemas.microsoft.com/analysisservices/2011/engine/300/300" xmlns:ddl400="http://schemas.microsoft.com/analysisservices/2012/engine/400" xmlns:ddl400_400="http://schemas.microsoft.com/analysisservices/2012/engine/400/400">
      <ID>TfsWarehouseDataReader</ID>
      <Name>TfsWarehouseDataReader</Name>
      <Members>
        <Member>
          <Name>TECHTOOLBOX\s-tfs-reports</Name>
        </Member>
      </Members>
    </Role>
  </ObjectDefinition>
</Alter>
```

### Update data source in TFS OLAP database

Modify **Tfs_AnalysisDataSource** to change the service account specified in the **Impersonation Info** property to **TECHTOOLBOX\\s-tfs-reports**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E7/B92862848EBC745B9D14CB14B584CD827511D7E7.png)

Process the **Tfs_Analysis** database.

```PowerShell
cls
```

## # Install DPM 2012 R2 agent

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

### Reference

**Installing Protection Agents Manually**\
Pasted from <[http://technet.microsoft.com/en-us/library/hh757789.aspx](http://technet.microsoft.com/en-us/library/hh757789.aspx)>

## Attach DPM agent

On the DPM server (JUGGERNAUT), open **DPM Management Shell**, and run the following commands:

---

**JUGGERNAUT**

```PowerShell
$productionServer = 'HAVOK'

.\Attach-ProductionServer.ps1 `
    -DPMServerName JUGGERNAUT `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `
    -UserName jjameson-admin
```

---

## Add "Local System" account to SQL Server sysadmin role

On the SQL Server (HAVOK), open SQL Server Management Studio and execute the following:

```SQL
ALTER SERVER ROLE [sysadmin] ADD MEMBER [NT AUTHORITY\SYSTEM]
GO
```

### Reference

**Protection agent jobs may fail for SQL Server 2012 databases**\
Pasted from <[http://technet.microsoft.com/en-us/library/dn281948.aspx](http://technet.microsoft.com/en-us/library/dn281948.aspx)>

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

## # Install SCOM agent

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

## # Approve manual agent install in Operations Manager

## Upgrade to DPM 2016

### Uninstall previous version of DPM agent

Restart the server to complete the removal.

### # Install new version of DPM agent

```PowerShell
$installer = "\\TT-FS01\Products\Microsoft\System Center 2016" `
    + "\Agents\DPMAgentInstaller_x64.exe"

& $installer TT-DPM01.corp.technologytoolbox.com
```

### Attach DPM agent

## Expand C: drive

---

**FOOBAR10**

### # Expand primary VHD for virtual machine

```PowerShell
$vmName = "HAVOK"
$vmHost = "TT-HV02C"

Stop-VM -ComputerName $vmHost -Name $vmName

$vhdPath = "D:\NotBackedUp\VMs\$vmName\$vmName.vhdx"

Resize-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 27GB

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### # Expand C: partition

```PowerShell
$maxSize = (Get-PartitionSupportedSize -DriveLetter C).SizeMax

Resize-Partition -DriveLetter C -Size $maxSize
```

## Expand L: (Log01) drive

---

**FOOBAR8**

### # Increase the size of "Log01" VHD

```PowerShell
$vmHost = "BEAST"
$vmName = "HAVOK"

Resize-VHD `
    -ComputerName $vmHost `
    -Path ("D:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
        + $vmName + "_Log01.vhdx") `
    -SizeBytes 10GB
```

---

### # Extend partition

```PowerShell
$size = (Get-PartitionSupportedSize -DiskNumber 2 -PartitionNumber 1)
Resize-Partition -DiskNumber 2 -PartitionNumber 1 -Size $size.SizeMax
```

## Upgrade to System Center Operations Manager 2016

### Uninstall SCOM 2012 R2 agent

```Console
msiexec /x `{786970C5-E6F6-4A41-B238-AE25D4B91EEA`}

Restart-Computer
```

### Install SCOM 2016 agent (using Operations Console)

## # Resolve low disk space on C

### # Clean up WinSxS folder

```PowerShell
Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase
```

### # Clean up Windows Update files

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse

Start-Service wuauserv
```

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

## Configure Data Collection

---

**SQL Server Management Studio**

### -- Create SqlManagement database

```SQL
CREATE DATABASE SqlManagement
ON PRIMARY
(
    NAME = N'SqlManagement'
    , FILENAME = N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\SqlManagement.mdf'
    , SIZE = 102400KB
    , FILEGROWTH = 102400KB
)
LOG ON
(
    NAME = N'SqlManagement_log'
    , FILENAME = N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\SqlManagement_log.ldf'
    , SIZE = 20480KB
    , FILEGROWTH = 10%
)
```

---

### Configure management data warehouse

### Configure data collection

#### Configure default data collection

#### Stop data collection for query statistics and server activity

## Rebuild DPM 2016 server (replace TT-DPM01 with TT-DPM02)

### Remove DPM agent

Restart the server to complete the removal.

### # Install DPM agent

```PowerShell
$installer = "\\TT-FS01\Products\Microsoft\System Center 2016" `
    + "\DPM\Agents\DPMAgentInstaller_x64.exe"

& $installer TT-DPM02.corp.technologytoolbox.com
```

## Expand C: drive

---

**FOOBAR10**

```PowerShell
cls
```

### # Expand primary VHD for virtual machine

```PowerShell
$vmName = "HAVOK"
$vmHost = "TT-HV02C"

Stop-VM -ComputerName $vmHost -Name $vmName

$vhdPath = "D:\NotBackedUp\VMs\$vmName\$vmName.vhdx"

Resize-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 30GB

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### # Expand C: partition

```PowerShell
$maxSize = (Get-PartitionSupportedSize -DriveLetter C).SizeMax

Resize-Partition -DriveLetter C -Size $maxSize
```

## Expand C: drive to 32 GB

### Before

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A7/2AA29D5C835DC5D321A03122A10772AAA4F986A7.png)

Screen clipping taken: 11/18/2017 2:21 PM

### Expand primary VHD for virtual machine

---

**FOOBAR10**

```PowerShell
cls
```

#### # Increase size of VHD

```PowerShell
$vmName = "HAVOK"
$vmHost = "TT-HV02C"

Stop-VM -ComputerName $vmHost -Name $vmName

$vhdPath = "D:\NotBackedUp\VMs\$vmName\$vmName.vhdx"

Resize-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 32GB

Start-VM -ComputerName $vmHost -Name $vmName
```

---

#### # Extend partition

```PowerShell
$size = (Get-PartitionSupportedSize -DiskNumber 0 -PartitionNumber 2)
Resize-Partition -DiskNumber 0 -PartitionNumber 2 -Size $size.SizeMax
```

### After

![(screenshot)](https://assets.technologytoolbox.com/screenshots/23/116AFC969938D10DCACA70A3EB8FE69BDB023723.png)

Screen clipping taken: 11/18/2017 2:52 PM

## Expand C: drive to 34 GB

### Before

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8D/849BD17720CFF9CDDD9D8BBF000D5D66661DFE8D.png)

Screen clipping taken: 3/27/2018 5:51 AM

---

**FOOBAR11**

```PowerShell
cls
```

### # Increase size of VHD

```PowerShell
$vmName = "HAVOK"
$vmHost = "TT-HV05A"

Stop-VM -ComputerName $vmHost -Name $vmName

$vhdPath = "E:\NotBackedUp\VMs\$vmName\$vmName.vhdx"

Resize-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 34GB

Start-VM -ComputerName $vmHost -Name $vmName
```

---

```PowerShell
cls
```

### # Extend partition

```PowerShell
$driveLetter = "C"

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

### After

![(screenshot)](https://assets.technologytoolbox.com/screenshots/88/2C9CE6418BF1348A4A5E8AF6F78E77F78D99EB88.png)

Screen clipping taken: 3/27/2018 5:56 AM

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

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Move VM to new Production VM network

```PowerShell
$vmName = "HAVOK"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Production VM Network"

Stop-SCVirtualMachine $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -MACAddressType Dynamic `
    -IPv4AddressType Dynamic

Start-SCVirtualMachine $vmName
```

---

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Move VM to new Management VM network

```PowerShell
$vmName = "HAVOK"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Management VM Network"
$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"
$ipAddressPool = Get-SCStaticIPAddressPool -Name "Management-30 Address Pool"

Stop-SCVirtualMachine $vmName

$macAddress = Grant-SCMACAddress `
    -MACAddressPool $macAddressPool `
    -Description $vmName `
    -VirtualNetworkAdapter $networkAdapter

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -MACAddressType Static `
    -MACAddress $macAddress `
    -IPv4AddressPools $ipAddressPool `
    -IPv4AddressType Static

Start-SCVirtualMachine $vmName
```

---

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Move VM back to new Production VM network

```PowerShell
$vmName = "HAVOK"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Production VM Network"

Stop-SCVirtualMachine $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -MACAddressType Dynamic `
    -IPv4AddressType Dynamic

Start-SCVirtualMachine $vmName
```

---

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Move VM to new Management VM network

```PowerShell
$vmName = "HAVOK"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Management VM Network"

Stop-SCVirtualMachine $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -MACAddressType Dynamic `
    -IPv4AddressType Dynamic

Start-SCVirtualMachine $vmName
```

---

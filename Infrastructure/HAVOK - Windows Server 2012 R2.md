# HAVOK - Windows Server 2012 R2 Standard

Saturday, January 04, 2014
4:16 PM

```Console
12345678901234567890123456789012345678901234567890123456789012345678901234567890

PowerShell
```

## # Create virtual machine

```PowerShell
$vmName = "HAVOK"

New-VM `
    -Name $vmName `
    -Path C:\NotBackedUp\VMs `
    -MemoryStartupBytes 8GB `
    -SwitchName "Virtual LAN 2 - 192.168.10.x"

Set-VMProcessor -VMName $vmName -Count 4

$sysPrepedImage =
    "\\ICEMAN\VM Library\ws2012std-r2\Virtual Hard Disks\ws2012std-r2.vhd"

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

Convert-VHD `
    -Path $sysPrepedImage `
    -DestinationPath $vhdPath

Set-VHD $vhdPath -PhysicalSectorSizeBytes 4096

Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath

Start-VM $vmName
```

## # Rename the server and join domain

```PowerShell
Rename-Computer -NewName HAVOK -Restart

Add-Computer -DomainName corp.technologytoolbox.com -Restart
```

## # Download PowerShell help files

```PowerShell
Update-Help
```

## # Change drive letter for DVD-ROM

### # To change the drive letter for the DVD-ROM using PowerShell

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
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

Set-NetAdapterAdvancedProperty -Name "LAN 1 - 192.168.10.x" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

ping ICEMAN -f -l 8900
```

## # Add disks for SQL Server storage (Data01, Log01, Temp01, and Backup01)

```PowerShell
$vmName = "HAVOK"

Stop-VM $vmName

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Data01.vhdx"

New-VHD -Path $vhdPath -Fixed -SizeBytes 30GB
Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath -ControllerType SCSI

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Log01.vhdx"

New-VHD -Path $vhdPath -Fixed -SizeBytes 5GB
Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath -ControllerType SCSI

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Temp01.vhdx"

New-VHD -Path $vhdPath -Fixed -SizeBytes 2GB
Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath -ControllerType SCSI

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Backup01.vhdx"

New-VHD -Path $vhdPath -Dynamic -SizeBytes 50GB
Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath -ControllerType SCSI

Start-VM $vmName
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

## # Install .NET Framework 3.5

```PowerShell
Install-WindowsFeature `
    NET-Framework-Core `
    -Source '\\ICEMAN\Products\Microsoft\Windows Server 2012 R2\Sources\SxS'
```

## # Install SQL Server 2012 with SP1

**# Note: .NET Framework 3.5 is required for SQL Server 2012 Management Tools.**

### Reference

**Set up SQL Server for TFS**\
Pasted from <[http://msdn.microsoft.com/en-us/library/jj620927.aspx](http://msdn.microsoft.com/en-us/library/jj620927.aspx)>

On the **Feature Selection** step:

- Do not select **Reporting Services - Native**.
- Select **Management Tools - Complete**.

On the **Server Configuration** step:

- For the **SQL Server Agent** service, change the **Startup Type** to **Automatic**.
- For the **SQL Server Browser** service, leave the **Startup Type** as **Disabled**.

On the **Database Engine Configuration** step:

- On the **Server Configuration** tab, in the **Specify SQL Server administrators** section, click **Add...** and then add the domain group for SQL Server administrators.
- On the **Data Directories** tab:
  - In the **Data root directory** box, type **D:\\Microsoft SQL Server\\**.
  - In the **User database log directory** box, change the drive letter to **L:** (the value should be **L:\\Microsoft SQL Server\\MSSQL11.MSSQLSERVER\\MSSQL\\Data**).
  - In the **Temp DB directory** box, change the drive letter to **T:** (the value should be **T:\\Microsoft SQL Server\\MSSQL11.MSSQLSERVER\\MSSQL\\Data**).
  - In the **Backup directory** box, change the drive letter to **Z:** (the value should be **Z:\\Microsoft SQL Server\\MSSQL11.MSSQLSERVER\\MSSQL\\Backup**).

On the **Analysis Services Configuration** step:

- On the **Server Configuration** tab, in the **Specify SQL Server administrators** section, click **Add...** and then add the domain group for SQL Server administrators.
- On the **Data Directories** tab:
  - In the **Data directory** box, type **D:\\Microsoft SQL Server\\MSAS11.MSSQLSERVER\\OLAP\\Data**.
  - In the **Log file directory** box, type **L:\\Microsoft SQL Server\\MSAS11.MSSQLSERVER\\OLAP\\Log**.
  - In the **Temp directory** box, type **T:\\Microsoft SQL Server\\MSAS11.MSSQLSERVER\\OLAP\\Temp**.
  - In the **Backup directory** box, type **Z:\\Microsoft SQL Server\\MSAS11.MSSQLSERVER\\OLAP\\Backup**.

## # Configure firewall rules for SQL Server

```PowerShell
New-NetFirewallRule `
    -DisplayName "SQL Server Analysis Services" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 2383 `-Action Allow

New-NetFirewallRule `
    -DisplayName "SQL Server Database Engine" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 1433 `-Action Allow
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

```PowerShell
$productionServer = "HAVOK"

.\Attach-ProductionServer.ps1 `
    -DPMServerName JUGGERNAUT `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `-UserName jjameson-admin
```

## Add "Local System" account to SQL Server sysadmin role

On the SQL Server (HAVOK), open SQL Server Management Studio and execute the following:

```SQL
ALTER SERVER ROLE [sysadmin] ADD MEMBER [NT AUTHORITY\SYSTEM]
GO
```

### Reference

**Protection agent jobs may fail for SQL Server 2012 databases**\
Pasted from <[http://technet.microsoft.com/en-us/library/dn281948.aspx](http://technet.microsoft.com/en-us/library/dn281948.aspx)>

## Configure Max Degree of Parallelism

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EF/926CAFE390C10D8FF48C952CAC315CA44236DCEF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/26/59828C332CD5C2E93579D7FCCDE90E7176BCC826.png)

### Reference

Ensure the Max degree of parallelism is set to 1. For additional information about max degree of parallelism see, [Configure the max degree of parallism Server Configuration option](Configure the max degree of parallism Server Configuration option) and [Degree of Parallelism](Degree of Parallelism).

Pasted from <[http://technet.microsoft.com/en-us/library/ee805948.aspx](http://technet.microsoft.com/en-us/library/ee805948.aspx)>

## Fix permissions to avoid "ESENT" errors in event log

```Console
icacls C:\Windows\System32\LogFiles\Sum\Api.chk /grant "NT Service\MSSQLSERVER":(M)

icacls C:\Windows\System32\LogFiles\Sum\Api.log /grant "NT Service\MSSQLSERVER":(M)

icacls C:\Windows\System32\LogFiles\Sum\SystemIdentity.mdb /grant "NT Service\MSSQLSERVER":(M)

icacls C:\Windows\System32\LogFiles\Sum\Api.chk /grant "NT Service\MSSQLServerOLAPService":(M)

icacls C:\Windows\System32\LogFiles\Sum\Api.log /grant "NT Service\MSSQLServerOLAPService":(M)

icacls C:\Windows\System32\LogFiles\Sum\SystemIdentity.mdb /grant "NT Service\MSSQLServerOLAPService":(M)
```

### Reference

**Error 1032 messages in the Application log in Windows Server 2012**\
Pasted from <[http://support.microsoft.com/kb/2811566](http://support.microsoft.com/kb/2811566)>

## -- Configure TempDB

```SQL
ALTER DATABASE [tempdb]
    MODIFY FILE
    (
        NAME = N'tempdev'
        , SIZE = 256MB
        , MAXSIZE = 512MB
        , FILEGROWTH = 128MB
    );

DECLARE @dataPath VARCHAR(300);

SELECT
    @dataPath = REPLACE([filename], '.mdf','')
FROM
    sysaltfiles s
WHERE
    name = 'tempdev';

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
```

## -- Restore content database for intranet Web application

```SQL
RESTORE DATABASE [WSS_Content_ttweb] FROM  DISK = N'\\iceman\Archive\BEAST\NotBackedUp\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\Full\WSS_Content_ttweb_backup_2014_01_04_064316_3783309.bak' WITH  FILE = 1,  MOVE N'WSS_Content_ttweb' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\WSS_Content_ttweb.mdf',  MOVE N'WSS_Content_ttweb_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\WSS_Content_ttweb_log.LDF',  NOUNLOAD,  STATS = 5
```

## -- Restore content database for team sites

```SQL
RESTORE DATABASE [WSS_Content_Team1] FROM  DISK = N'\\iceman\Archive\BEAST\NotBackedUp\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\Full\WSS_Content_Team1_backup_2014_01_04_064316_3627095.bak' WITH  FILE = 1,  MOVE N'WSS_Content_Team1' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\WSS_Content_Team1.mdf',  MOVE N'WSS_Content_Team1_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\WSS_Content_Team1_1.LDF',  NOUNLOAD,  STATS = 5
```

## -- Restore content database for My Sites

```SQL
RESTORE DATABASE [WSS_Content_MySites] FROM  DISK = N'\\iceman\Archive\BEAST\NotBackedUp\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\Full\WSS_Content_MySites_backup_2014_01_04_064316_3627095.bak' WITH  FILE = 1,  MOVE N'WSS_Content_MySites' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\WSS_Content_MySites.mdf',  MOVE N'WSS_Content_MySites_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\WSS_Content_MySites_log.LDF',  NOUNLOAD,  STATS = 5
```

## -- Restore the Managed Metadata Service database

```SQL
RESTORE DATABASE [ManagedMetadataService] FROM  DISK = N'\\iceman\Archive\BEAST\NotBackedUp\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\Full\ManagedMetadataService_backup_2014_01_04_064316_3314531.bak' WITH  FILE = 1,  MOVE N'ManagedMetadataService' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\ManagedMetadataService.mdf',  MOVE N'ManagedMetadataService_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\ManagedMetadataService_log.ldf',  NOUNLOAD,  STATS = 5
```

## -- Restore the User Profile Service databases

```SQL
RESTORE DATABASE [ProfileDB] FROM  DISK = N'\\iceman\Archive\BEAST\NotBackedUp\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\Full\ProfileDB_backup_2014_01_04_064316_4095824.bak' WITH  FILE = 1,  MOVE N'ProfileDB' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\ProfileDB.mdf',  MOVE N'ProfileDB_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\ProfileDB_log.ldf',  NOUNLOAD,  STATS = 5

RESTORE DATABASE [SocialDB] FROM  DISK = N'\\iceman\Archive\BEAST\NotBackedUp\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\Full\SocialDB_backup_2014_01_04_064316_4252085.bak' WITH  FILE = 1,  MOVE N'SocialDB' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\SocialDB.mdf',  MOVE N'SocialDB_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\SocialDB_log.ldf',  NOUNLOAD,  STATS = 5

RESTORE DATABASE [SyncDB] FROM  DISK = N'\\iceman\Archive\BEAST\NotBackedUp\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\Full\SyncDB_backup_2014_01_04_064316_4095824.bak' WITH  FILE = 1,  MOVE N'SyncDB' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\SyncDB.mdf',  MOVE N'SyncDB_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\SyncDB_log.ldf',  NOUNLOAD,  STATS = 5
```

## -- Restore the Secure Store Service database

```SQL
RESTORE DATABASE [Secure_Store_Service_DB] FROM  DISK = N'\\iceman\Archive\BEAST\NotBackedUp\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\Full\Secure_Store_Service_DB_backup_2014_01_04_064316_4252085.bak' WITH  FILE = 1,  MOVE N'Secure_Store_Service_DB' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\Secure_Store_Service_DB.mdf',  MOVE N'Secure_Store_Service_DB_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\Secure_Store_Service_DB_log.ldf',  NOUNLOAD,  STATS = 5
```

## -- Restore TFS databases (OLTP)

```SQL
RESTORE DATABASE [ReportServer_TFS]
 FROM  DISK = N'\\iceman\Archive\BEAST\NotBackedUp\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\Full\ReportServer_TFS_backup_2014_01_04_064316_4095824.bak' WITH  FILE = 1,  NOUNLOAD,  STATS = 5

RESTORE DATABASE [ReportServer_TFSTempDB]
 FROM  DISK = N'\\iceman\Archive\BEAST\NotBackedUp\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\Full\ReportServer_TFSTempDB_backup_2014_01_04_064316_4095824.bak' WITH  FILE = 1,  NOUNLOAD,  STATS = 5

RESTORE DATABASE [Tfs_Configuration]
 FROM  DISK = N'\\iceman\Archive\BEAST\NotBackedUp\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\Full\Tfs_Configuration_backup_2014_01_04_064316_3470811.bak' WITH  FILE = 1,  MOVE N'Tfs_Configuration' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\Tfs_Configuration.mdf',  MOVE N'Tfs_Configuration_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\Tfs_Configuration_1.LDF',  NOUNLOAD,  STATS = 5

RESTORE DATABASE [Tfs_DefaultCollection]
 FROM  DISK = N'\\iceman\Archive\BEAST\NotBackedUp\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\Full\Tfs_DefaultCollection_backup_2014_01_04_064316_3470811.bak' WITH  FILE = 1,  MOVE N'Tfs_DefaultCollection' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\Tfs_DefaultCollection.mdf',  MOVE N'Tfs_DefaultCollection_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\Tfs_DefaultCollection_1.ldf',  NOUNLOAD,  STATS = 5

RESTORE DATABASE [Tfs_IntegrationPlatform]
 FROM  DISK = N'\\iceman\Archive\BEAST\NotBackedUp\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\Full\Tfs_IntegrationPlatform_backup_2014_01_04_064316_3470811.bak' WITH  FILE = 1,  MOVE N'Tfs_IntegrationPlatform' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\Tfs_IntegrationPlatform.mdf',  MOVE N'Tfs_IntegrationPlatform_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\Tfs_IntegrationPlatform_log.LDF',  NOUNLOAD,  STATS = 5

RESTORE DATABASE [Tfs_Warehouse]
 FROM  DISK = N'\\iceman\Archive\BEAST\NotBackedUp\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\Full\Tfs_Warehouse_backup_2014_01_04_064316_3470811.bak' WITH  FILE = 1,  MOVE N'Tfs_Warehouse' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\Tfs_Warehouse.mdf',  MOVE N'Tfs_Warehouse_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\Tfs_Warehouse_1.LDF',  NOUNLOAD,  STATS = 5

GO

USE [master]
GO
CREATE LOGIN [TECHTOOLBOX\svc-tfsreports]
FROM WINDOWS WITH DEFAULT_DATABASE=[master]
GO
```

## Restore TFS Analysis Services database

```XML
<Restore xmlns="http://schemas.microsoft.com/analysisservices/2003/engine">
  <File>\\iceman\Archive\BEAST\NotBackedUp\Microsoft SQL Server\MSAS11.MSSQLSERVER\OLAP\Backup\Tfs_Analysis.abf</File>
  <Password>{guess}</Password>
</Restore>
```

In the **Tfs_Analysis** database, add **TECHTOOLBOX\\svc-tfsreports-test** to **TfsWarehouseDataReader** role.

Modify **Tfs_AnalysisDataSource** to:

1. Change the database server in the **Connection String** property to **HAVOK-TEST**.
2. Change the service account specified in the **Impersonation Info** property to **TECHTOOLBOX\\svc-tfsreports**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AE/332D19548A7AFCD5082D1680B0D784F69F804CAE.png)

Process the **Tfs_Analysis** database.

## -- Restore additional SQL Server databases

```SQL
RESTORE DATABASE [AdventureWorks2012] FROM  DISK = N'\\iceman\Archive\BEAST\NotBackedUp\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\Full\AdventureWorks2012_backup_2014_01_04_064316_3627095.bak' WITH  FILE = 1,  MOVE N'AdventureWorks2012_Data' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\AdventureWorks2012_Data.mdf',  MOVE N'AdventureWorks2012_Log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\AdventureWorks2012_log.ldf',  NOUNLOAD,  STATS = 5

RESTORE DATABASE [AdventureWorksLT2012]
 FROM  DISK = N'\\iceman\Archive\BEAST\NotBackedUp\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\Full\AdventureWorksLT2012_backup_2014_01_04_064316_3158285.bak' WITH  FILE = 1,  MOVE N'AdventureWorksLT2008_Data' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\AdventureWorksLT2012_Data.mdf',  MOVE N'AdventureWorksLT2008_Log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\AdventureWorksLT2012_log.ldf',  NOUNLOAD,  STATS = 5

RESTORE DATABASE [Caelum]
 FROM  DISK = N'\\iceman\Archive\BEAST\NotBackedUp\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\Full\Caelum_backup_2014_01_04_064316_3158285.bak' WITH  FILE = 1,  MOVE N'DB_29334_caelum_data' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\Caelum.mdf',  MOVE N'DB_29334_caelum_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\Caelum.ldf',  NOUNLOAD,  STATS = 5

RESTORE DATABASE [Caelum_Warehouse] FROM  DISK = N'\\iceman\Archive\BEAST\NotBackedUp\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\Full\Caelum_Warehouse_backup_2014_01_04_064316_3314531.bak' WITH  FILE = 1,  MOVE N'Caelum_Warehouse' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\Caelum_Warehouse.mdf',  MOVE N'Caelum_Warehouse_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\Caelum_Warehouse_log.LDF',  NOUNLOAD,  STATS = 5

RESTORE DATABASE [LoadTest2010]
 FROM  DISK = N'\\iceman\Archive\BEAST\NotBackedUp\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\Full\LoadTest2010_backup_2014_01_04_064316_3314531.bak' WITH  FILE = 1,  MOVE N'LoadTest2010' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\LoadTest2010.mdf',  MOVE N'LoadTest2010_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\LoadTest2010_log.LDF',  NOUNLOAD,  STATS = 5

RESTORE DATABASE [SqlMaintenance]
 FROM  DISK = N'\\iceman\Archive\BEAST\NotBackedUp\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\Full\SqlMaintenance_backup_2014_01_04_064316_3314531.bak' WITH  FILE = 1,  MOVE N'SqlMaintenance' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\SqlMaintenance.mdf',  MOVE N'SqlMaintenance_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\SqlMaintenance_log.ldf',  NOUNLOAD,  STATS = 5
```

## # Expand "Log01" VHD

```PowerShell
$vmName = "HAVOK"

Stop-VM $vmName

Resize-VHD `
    ("C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
        + $vmName + "_Log01.vhdx") `
    -SizeBytes 8GB

Start-VM $vmName
```

## # Expand L: drive

```PowerShell
$size = (Get-PartitionSupportedSize -DiskNumber 2 -PartitionNumber 1)
Resize-Partition -DiskNumber 2 -PartitionNumber 1 -Size $size.SizeMax
```

## -- Shrink transaction log for Tfs_Warehouse database

```SQL
USE [Tfs_Warehouse]
GO
DBCC SHRINKFILE (N'Tfs_Warehouse_log' , 100)
GO
```

## Resolve SCOM alerts due to disk fragmentation

### Alert Name

Logical Disk Fragmentation Level is high

### Alert Description

The disk T: (T:) on computer HAVOK.corp.technologytoolbox.com has high fragmentation level. File Percent Fragmentation value is 27%. Defragmentation recommended: true.

### Resolution

##### # Copy Toolbox content

```PowerShell
robocopy \\iceman\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E
```

##### # Create scheduled task to optimize drives

```PowerShell
[string] $xml = Get-Content `
  'C:\NotBackedUp\Public\Toolbox\Scheduled Tasks\Optimize Drives.xml'

Register-ScheduledTask -TaskName "Optimize Drives" -Xml $xml
```

## # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

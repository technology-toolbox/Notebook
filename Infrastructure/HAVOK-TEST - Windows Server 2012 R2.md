# HAVOK-TEST - Windows Server 2012 R2 Standard

Saturday, January 04, 2014
1:43 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

---

**FOOBAR8**

## Create VM using Virtual Machine Manager

- Processors: **2**
- Memory: **4 GB**
- VHD size (GB): **25**
- VHD file name:** HAVOK-TEST**
- Virtual DVD drive: **[\\\\ICEMAN\\Products\\Microsoft\\MDT-Deploy-x86.iso](\\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso)**
- Network Adapter 1:** Virtual LAN 2 - 192-168.10.x**
- Host:** ROGUE**
- Automatic actions
  - **Turn on the virtual machine if it was running with the physical server stopped**
  - **Save State**
  - Operating system: **Windows Server 2012 R2 Standard**

---

## Install custom Windows Server 2012 R2 image

- On the **Task Sequence** step, select **Windows Server 2012 R2** and click **Next**.
- On the **Computer Details** step, in the **Computer name** box, type **HAVOK-TEST** and click **Next**.
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

## # Configure firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

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
$vmHost = "ROGUE"
$vmName = "HAVOK-TEST"

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Fixed -SizeBytes 30GB
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
$vmHost = "ROGUE"
$vmName = "HAVOK-TEST"

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
    -LocalPort 2383 `-Action Allow

New-NetFirewallRule `
    -Name "SQL Server Database Engine" `
    -DisplayName "SQL Server Database Engine" `
    -Group 'Technology Toolbox (Custom)' `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 1433 `-Action Allow
```

```PowerShell
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

```PowerShell
$productionServer = "HAVOK-TEST"

.\Attach-ProductionServer.ps1 `
    -DPMServerName JUGGERNAUT `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `-UserName jjameson-admin
```

## Add "Local System" account to SQL Server sysadmin role

On the SQL Server (HAVOK-TEST), open SQL Server Management Studio and execute the following:

```SQL
ALTER SERVER ROLE [sysadmin] ADD MEMBER [NT AUTHORITY\SYSTEM]
GO
```

### Reference

**Protection agent jobs may fail for SQL Server 2012 databases**\
Pasted from <[http://technet.microsoft.com/en-us/library/dn281948.aspx](http://technet.microsoft.com/en-us/library/dn281948.aspx)>

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
        , SIZE = 512MB
        , MAXSIZE = 1024MB
        , FILEGROWTH = 128MB
    );

DECLARE @sqlStatement NVARCHAR(500);

SELECT @sqlStatement =
    N'ALTER DATABASE [tempdb]'
    + 'ADD FILE'
    + '('
        + 'NAME = N''tempdev2'''
        + ', FILENAME = ''' + @dataPath + '2.mdf'''
        + ', SIZE = 512MB'
        + ', MAXSIZE = 1024MB'
        + ', FILEGROWTH = 128MB'
    + ')';

EXEC sp_executesql @sqlStatement;
```

### -- Backup TFS OLTP databases

---

**HAVOK**

```SQL
BACKUP DATABASE [ReportServer_TFS]
TO DISK = N'\\ICEMAN\Backups\HAVOK\ReportServer_TFS.bak'
WITH NOFORMAT, NOINIT
    , NAME = N'ReportServer_TFS-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY

BACKUP DATABASE [ReportServer_TFSTempDB]
TO DISK = N'\\ICEMAN\Backups\HAVOK\ReportServer_TFSTempDB.bak'
WITH NOFORMAT, NOINIT
    , NAME = N'ReportServer_TFSTempDB-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY

BACKUP DATABASE [Tfs_Configuration]
TO DISK = N'\\ICEMAN\Backups\HAVOK\Tfs_Configuration.bak'
WITH NOFORMAT, NOINIT
    , NAME = N'Tfs_Configuration-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY

BACKUP DATABASE [Tfs_DefaultCollection]
TO DISK = N'\\ICEMAN\Backups\HAVOK\Tfs_DefaultCollection.bak'
WITH NOFORMAT, NOINIT
    , NAME = N'Tfs_DefaultCollection-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY

BACKUP DATABASE [Tfs_IntegrationPlatform]
TO DISK = N'\\ICEMAN\Backups\HAVOK\Tfs_IntegrationPlatform.bak'
WITH NOFORMAT, NOINIT
    , NAME = N'Tfs_IntegrationPlatform-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY

BACKUP DATABASE [Tfs_Warehouse]
TO DISK = N'\\ICEMAN\Backups\HAVOK\Tfs_Warehouse.bak'
WITH NOFORMAT, NOINIT
    , NAME = 'Tfs_Warehouse-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY
```

---

### -- Backup TFS OLAP database

---

**HAVOK**

```XML
<Backup xmlns="http://schemas.microsoft.com/analysisservices/2003/engine">
  <Object>
    <DatabaseID>Tfs_Analysis</DatabaseID>
  </Object>
  <File>\\ICEMAN\Backups\HAVOK\Tfs_Analysis.abf</File>
  <Password>{guess}</Password>
</Backup>
```

---

## -- Restore TFS OLTP databases

```Console
RESTORE DATABASE [ReportServer_TFS]
FROM DISK = N'\\ICEMAN\Backups\HAVOK\ReportServer_TFS.bak'
WITH FILE = 1, NOUNLOAD, STATS = 5,
    MOVE N'ReportServer' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\ReportServer_TFS.mdf',
    MOVE N'ReportServer_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\ReportServer_TFS_1.LDF'

RESTORE DATABASE [ReportServer_TFSTempDB]
FROM  DISK = N'\\ICEMAN\Backups\HAVOK\ReportServer_TFSTempDB.bak'
WITH FILE = 1, NOUNLOAD, STATS = 5,
    MOVE N'ReportServerTempDB' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\ReportServer_TFSTempDB.mdf',
    MOVE N'ReportServerTempDB_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\ReportServer_TFSTempDB_1.LDF'

RESTORE DATABASE [Tfs_Configuration]
FROM DISK = N'\\ICEMAN\Backups\HAVOK\Tfs_Configuration.bak'
WITH FILE = 1, NOUNLOAD, STATS = 5,
    MOVE N'Tfs_Configuration' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\Tfs_Configuration.mdf',
    MOVE N'Tfs_Configuration_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Tfs_Configuration_1.LDF'

RESTORE DATABASE [Tfs_DefaultCollection]
FROM DISK = N'\\ICEMAN\Backups\HAVOK\Tfs_DefaultCollection.bak'
WITH FILE = 1, NOUNLOAD, STATS = 5,
    MOVE N'Tfs_DefaultCollection' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\Tfs_DefaultCollection.mdf',
    MOVE N'Tfs_DefaultCollection_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Tfs_DefaultCollection_1.ldf'

RESTORE DATABASE [Tfs_IntegrationPlatform]
FROM DISK = N'\\ICEMAN\Backups\HAVOK\Tfs_IntegrationPlatform.bak'
WITH FILE = 1, NOUNLOAD, STATS = 5,
    MOVE N'Tfs_IntegrationPlatform' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\Tfs_IntegrationPlatform.mdf',
    MOVE N'Tfs_IntegrationPlatform_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Tfs_IntegrationPlatform_log.LDF'

RESTORE DATABASE [Tfs_Warehouse]
FROM DISK = N'\\ICEMAN\Backups\HAVOK\Tfs_Warehouse.bak'
WITH FILE = 1, NOUNLOAD, STATS = 5,
    MOVE N'Tfs_Warehouse' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\Tfs_Warehouse.mdf',
    MOVE N'Tfs_Warehouse_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\Tfs_Warehouse_1.LDF'

GO
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
$displayName = 'Service account for Team Foundation Server (Reports) (TEST)'
$defaultUserName = 's-tfs-reports-test'

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@corp.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=Quality Assurance,DC=corp,DC=technologytoolbox,DC=com"

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
CREATE LOGIN [TECHTOOLBOX\s-tfs-reports-test]
FROM WINDOWS WITH DEFAULT_DATABASE=[master]
GO
USE [Tfs_Warehouse]
GO
CREATE USER [TECHTOOLBOX\s-tfs-reports-test]
FOR LOGIN [TECHTOOLBOX\s-tfs-reports-test]
GO
ALTER ROLE [TfsWarehouseDataReader]
ADD MEMBER [TECHTOOLBOX\s-tfs-reports-test]
GO
```

### Add service account to role in TFS OLAP database

In the **Tfs_Analysis** database, add **TECHTOOLBOX\\s-tfs-reports-test** to **TfsWarehouseDataReader** role.

### Update data source in TFS OLAP database

Modify **Tfs_AnalysisDataSource** to:

1. Change the database server in the **Connection String** property to **HAVOK-TEST**.
2. Change the service account specified in the **Impersonation Info** property to **TECHTOOLBOX\\s-tfs-reports-test**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E7/B92862848EBC745B9D14CB14B584CD827511D7E7.png)

Process the **Tfs_Analysis** database.

## -- Restore content database for intranet Web application

```SQL
RESTORE DATABASE [WSS_Content_ttweb]
 FROM  DISK = N'\\ICEMAN\Backups\HAVOK\WSS_Content_ttweb.bak'
 WITH  FILE = 1
 ,  MOVE N'WSS_Content_ttweb' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\WSS_Content_ttweb.mdf'
 ,  MOVE N'WSS_Content_ttweb_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\WSS_Content_ttweb_log.LDF'
 ,  NOUNLOAD
 ,  STATS = 5
```

## -- Restore content database for team sites

```SQL
RESTORE DATABASE [WSS_Content_Team1]
 FROM  DISK = N'\\ICEMAN\Backups\HAVOK\WSS_Content_Team1.bak'
 WITH  FILE = 1
 ,  MOVE N'WSS_Content_Team1' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\WSS_Content_Team1.mdf'
 ,  MOVE N'WSS_Content_Team1_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\WSS_Content_Team1_1.LDF'
 ,  NOUNLOAD
 ,  STATS = 5
```

## -- Restore content database for My Sites

```SQL
RESTORE DATABASE [WSS_Content_MySites]
 FROM  DISK = N'\\ICEMAN\Backups\HAVOK\WSS_Content_MySites.bak'
 WITH  FILE = 1
 ,  MOVE N'WSS_Content_MySites' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\WSS_Content_MySites.mdf'
 ,  MOVE N'WSS_Content_MySites_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\WSS_Content_MySites_log.LDF'
 ,  NOUNLOAD
 ,  STATS = 5
```

## -- Restore the Managed Metadata Service database

```SQL
RESTORE DATABASE [ManagedMetadataService]
 FROM  DISK = N'\\ICEMAN\Backups\HAVOK\ManagedMetadataService.bak'
 WITH  FILE = 1
 ,  MOVE N'ManagedMetadataService' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\ManagedMetadataService.mdf'
 ,  MOVE N'ManagedMetadataService_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\ManagedMetadataService_log.ldf'
 ,  NOUNLOAD
 ,  STATS = 5
```

## -- Restore the User Profile Service databases

```SQL
RESTORE DATABASE [ProfileDB]
 FROM  DISK = N'\\ICEMAN\Backups\HAVOK\ProfileDB.bak'
 WITH  FILE = 1
 ,  MOVE N'ProfileDB' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\ProfileDB.mdf'
 ,  MOVE N'ProfileDB_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\ProfileDB_log.ldf'
 ,  NOUNLOAD
 ,  STATS = 5

RESTORE DATABASE [SocialDB]
 FROM  DISK = N'\\ICEMAN\Backups\HAVOK\SocialDB.bak'
 WITH  FILE = 1,  MOVE N'SocialDB' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\SocialDB.mdf'
 ,  MOVE N'SocialDB_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\SocialDB_log.ldf'
 ,  NOUNLOAD
 ,  STATS = 5

RESTORE DATABASE [SyncDB]
 FROM  DISK = N'\\ICEMAN\Backups\HAVOK\SyncDB.bak'
 WITH  FILE = 1
 ,  MOVE N'SyncDB' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\SyncDB.mdf'
 ,  MOVE N'SyncDB_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\SyncDB_log.ldf'
 ,  NOUNLOAD
 ,  STATS = 5
```

## -- Restore the Secure Store Service database

```SQL
RESTORE DATABASE [Secure_Store_Service_DB]
 FROM  DISK = N'\\ICEMAN\Backups\HAVOK\Secure_Store_Service_DB.bak'
 WITH  FILE = 1
 ,  MOVE N'Secure_Store_Service_DB' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\Secure_Store_Service_DB.mdf'
 ,  MOVE N'Secure_Store_Service_DB_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\Secure_Store_Service_DB_log.ldf'
 ,  NOUNLOAD
 ,  STATS = 5

GO

USE [Secure_Store_Service_DB]
GO
CREATE USER [TECHTOOLBOX\svc-spserviceapp-tst]
GO
ALTER ROLE [SPDataAccess] ADD MEMBER [TECHTOOLBOX\svc-spserviceapp-tst]
GO
```

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

## -- Shrink transaction log for Tfs_Warehouse database

```Console
USE [Tfs_Warehouse]
GO
DBCC SHRINKFILE (N'Tfs_Warehouse_log' , 100)
GO
```

```Console
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

**TT-HV02B**

### # Expand primary VHD for virtual machine

```PowerShell
$vmName = "HAVOK-TEST"

Stop-VM -Name $vmName

$vhdPath = "\\TT-SOFS01.corp.technologytoolbox.com\VM-Storage-Silver" `
    + "\$vmName\$vmName.vhdx"

Resize-VHD -Path $vhdPath -SizeBytes 27GB

Start-VM -Name $vmName
```

---

### # Expand C: partition

```PowerShell
$maxSize = (Get-PartitionSupportedSize -DriveLetter C).SizeMax

Resize-Partition -DriveLetter C -Size $maxSize
```

## Upgrade to System Center Operations Manager 2016

### Uninstall SCOM 2012 R2 agent

```Console
msiexec /x `{786970C5-E6F6-4A41-B238-AE25D4B91EEA`}

Restart-Computer
```

### Install SCOM 2016 agent (using Operations Console)

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

```Console
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

GO

ALTER DATABASE SqlManagement
SET ALLOW_SNAPSHOT_ISOLATION OFF

ALTER DATABASE SqlManagement
SET READ_COMMITTED_SNAPSHOT OFF

ALTER DATABASE SqlManagement
SET DISABLE_BROKER

GO
```

---

### Configure management data warehouse

### Configure data collection

#### Configure default data collection

#### Stop data collection for query statistics and server activity

## Rebuild DPM 2016 server (replace TT-DPM01 with TT-DPM02)

### Uninstall previous version of DPM agent

Restart the server to complete the removal.

### # Install new version of DPM agent

```PowerShell
$installer = "\\TT-FS01\Products\Microsoft\System Center 2016" `
    + "\DPM\Agents\DPMAgentInstaller_x64.exe"

& $installer TT-DPM02.corp.technologytoolbox.com
```

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Make virtual machine highly available

```PowerShell
$vmName = "HAVOK-TEST"

$vm = Get-SCVirtualMachine -Name $vmName
$vmHost = $vm.VMHost

Move-SCVirtualMachine `
    -VM $vm `
    -VMHost $vmHost `
    -HighlyAvailable $true `
    -Path "\\TT-SOFS01.corp.technologytoolbox.com\VM-Storage-Silver" `
    -UseDiffDiskOptimization
```

---

## Expand C: drive

---

**TT-HV02A**

```PowerShell
cls
```

### # Expand primary VHD for virtual machine

```PowerShell
$vmName = "HAVOK-TEST"

Stop-VM -Name $vmName

$vhdPath = "\\TT-SOFS01.corp.technologytoolbox.com\VM-Storage-Silver" `
    + "\$vmName\$vmName.vhdx"

Resize-VHD -Path $vhdPath -SizeBytes 30GB

Start-VM -Name $vmName
```

---

### # Expand C: partition

```PowerShell
$maxSize = (Get-PartitionSupportedSize -DriveLetter C).SizeMax

Resize-Partition -DriveLetter C -Size $maxSize
```

## Expand C: drive to 32 GB

### Before

![(screenshot)](https://assets.technologytoolbox.com/screenshots/55/6BE528730B32CF63F1FC200B30C20BB59C110855.png)

Screen clipping taken: 11/17/2017 4:41 AM

---

**FOOBAR10**

```PowerShell
cls
```

#### # Increase size of VHD

```PowerShell
$vmName = "HAVOK-TEST"

# Note: VHD is stored on SOFS -- so expand using VMM cmdlet

Stop-SCVirtualMachine -VM $vmName

Get-SCVirtualDiskDrive -VM $vmName |
    where { $_.BusType -eq "IDE" -and $_.Bus -eq 0 } |
    Expand-SCVirtualDiskDrive -VirtualHardDiskSizeGB 32

Start-SCVirtualMachine -VM $vmName
```

---

#### # Extend partition

```PowerShell
$size = (Get-PartitionSupportedSize -DiskNumber 0 -PartitionNumber 2)
Resize-Partition -DiskNumber 0 -PartitionNumber 2 -Size $size.SizeMax
```

### After

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FA/998B034A9532A882E6613BEF5CBEEC60C2DE06FA.png)

Screen clipping taken: 11/17/2017 4:45 AM

## Expand L: (Log01) drive

---

**FOOBAR10**

```PowerShell
cls
```

#### # Increase size of VHD

```PowerShell
$vmName = "HAVOK-TEST"

# Note: VHD is stored on SOFS -- so expand using VMM cmdlet

Stop-SCVirtualMachine -VM $vmName

Get-SCVirtualDiskDrive -VM $vmName |
    where { $_.BusType -eq "SCSI" -and $_.Bus -eq 0 -and $_.Lun -eq 1 } |
    Expand-SCVirtualDiskDrive -VirtualHardDiskSizeGB 10

Start-SCVirtualMachine -VM $vmName
```

---

---

**FOOBAR8**

### # Increase the size of "Log01" VHD

```PowerShell
$vmHost = "TT-HV02A"
$vmName = "HAVOK-TEST"

Resize-VHD `
    -ComputerName $vmHost `
    -Path ("D:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
        + $vmName + "_Log01.vhdx") `
    -SizeBytes 10GB
```

---

### # Extend partition

```PowerShell
$maxSize = (Get-PartitionSupportedSize -DriveLetter L).SizeMax
Resize-Partition -DriveLetter L -Size $maxSize
```

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Make virtual machine highly available

### # Migrate VM to shared storage

```PowerShell
$vmName = "HAVOK-TEST"

$vm = Get-SCVirtualMachine -Name $vmName
$vmHost = $vm.VMHost

Move-SCVirtualMachine `
    -VM $vm `
    -VMHost $vmHost `
    -HighlyAvailable $true `
    -Path "C:\ClusterStorage\iscsi01-Gold-02" `
    -UseDiffDiskOptimization
```

### # Allow migration to host with different processor version

```PowerShell
Stop-SCVirtualMachine -VM $vmName

Set-SCVirtualMachine -VM $vmName -CPULimitForMigration $true

Start-SCVirtualMachine -VM $vmName
```

---

## Expand C: drive to 34 GB

### Before

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FD/64BA619418419BFEB13B2FEA54FE602F1A0725FD.png)

Screen clipping taken: 3/27/2018 5:45 AM

---

**FOOBAR11**

```PowerShell
cls
```

### # Increase size of VHD

```PowerShell
$vmName = "HAVOK-TEST"

# Note: VHD is stored on SOFS -- so expand using VMM cmdlet

Stop-SCVirtualMachine -VM $vmName

Get-SCVirtualDiskDrive -VM $vmName |
    where { $_.BusType -eq "IDE" -and $_.Bus -eq 0 } |
    Expand-SCVirtualDiskDrive -VirtualHardDiskSizeGB 34

Start-SCVirtualMachine -VM $vmName
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

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7F/69E07321F070A57523E3AE1A9FCBE498B21C457F.png)

Screen clipping taken: 3/27/2018 5:49 AM

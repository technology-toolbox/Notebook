# TT-SQL03 - Windows Server 2019 Standard Edition

Monday, September 23, 2019\
7:37 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy SQL Server 2017

### Deploy and configure the server infrastructure

---

**TT-ADMIN02** - Run as administrator

```PowerShell
cls
```

#### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "TT-SQL03"
$vmPath = "E:\NotBackedUp\VMs\$vmName"
$vhdPath = "$vmPath\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 40GB `
    -MemoryStartupBytes 8GB `
    -SwitchName "Embedded Team Switch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 4

Set-VMNetworkAdapterVlan `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Access `
    -VlanId 30

Start-VM -ComputerName $vmHost -Name $vmName
```

---

#### Install custom Windows Server 2019 image

- On the **Task Sequence** step, select **Windows Server 2019** and click
  **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **TT-SQL03**.
  - Click **Next**.
- On the **Applications** step, do not select any applications, and click
  **Next**.

---

**TT-ADMIN02** - Run as administrator

```PowerShell
cls
```

#### # Move computer to different OU

```PowerShell
$vmName = "TT-SQL03"

$targetPath = "OU=SQL Servers,OU=Servers" `
    + ",OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com"

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

#### # Set first boot device to hard drive

```PowerShell
$vmHost = "TT-HV05A"

$vmHardDiskDrive = Get-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName |
    where { $_.ControllerType -eq "SCSI" `
        -and $_.ControllerNumber -eq 0 `
        -and $_.ControllerLocation -eq 0 }

Set-VMFirmware `
    -ComputerName $vmHost `
    -VMName $vmName `
    -FirstBootDevice $vmHardDiskDrive
```

#### # Configure Windows Update

##### # Add machine to security group for Windows Update schedule

```PowerShell
Add-ADGroupMember -Identity "Windows Update - Slot 2" -Members ($vmName + '$')
```

---

### # Rename local Administrator account and set password

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

$password = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted, type the password for the local Administrator account.

```PowerShell
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

$adminUser = [ADSI] 'WinNT://./Administrator,User'
$adminUser.Rename('foo')
$adminUser.SetPassword($plainPassword)

logoff
```

### Login as .\\foo

### # Copy Toolbox content

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$source = "\\TT-FS01\Public\Toolbox"
$destination = "C:\NotBackedUp\Public\Toolbox"

robocopy $source $destination /E /XD "Microsoft SDKs" git-for-windows
```

### # Enable performance counters for Server Manager

```PowerShell
$taskName = "\Microsoft\Windows\PLA\Server Manager Performance Monitor"

Enable-ScheduledTask -TaskName $taskName

logman start "Server Manager Performance Monitor"
```

### Configure networking

---

**TT-ADMIN02** - Run as administrator

```PowerShell
cls
```

#### # Move VM to Production VM network and configure static IP address

```PowerShell
$vmName = "TT-SQL03"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Production VM Network"
$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"
$ipPool = Get-SCStaticIPAddressPool -Name "Production-15 Address Pool"

Stop-SCVirtualMachine $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork

$macAddress = Grant-SCMACAddress `
    -MACAddressPool $macAddressPool `
    -Description $vmName `
    -VirtualNetworkAdapter $networkAdapter

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -MACAddressType Static `
    -MACAddress $macAddress

$ipAddress = Grant-SCIPAddress `
    -GrantToObjectType VirtualNetworkAdapter `
    -GrantToObjectID $networkAdapter.ID `
    -StaticIPAddressPool $ipPool `
    -Description $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -IPv4AddressType Static `
    -IPv4Addresses $IPAddress.Address

Start-SCVirtualMachine $vmName
```

---

```PowerShell
$interfaceAlias = "Production"
```

#### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Start-Sleep -Seconds 5

ping TT-FS01 -f -l 8900
```

### Configure storage

| Disk | Drive Letter | Volume Size | VHD Type | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------- | -------------------- | ------------ |
| 0    | C:           | 45 GB       | Dynamic  | 4K                   | OSDisk       |
| 1    | D:           | 40 GB       | Fixed    | 64K                  | Data01       |
| 2    | L:           | 10 GB       | Fixed    | 64K                  | Log01        |
| 3    | T:           | 2 GB        | Fixed    | 64K                  | Temp01       |
| 4    | Z:           | 50 GB       | Dynamic  | 4K                   | Backup01     |

---

**TT-ADMIN02** - Run as administrator

```PowerShell
cls
```

#### # Configure storage for the SQL Server

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "TT-SQL03"
$vmPath = "E:\NotBackedUp\VMs\$vmName"
```

##### # Add "Data01" VHD

```PowerShell
$vhdPath = $vmPath + "\Virtual Hard Disks\$vmName" + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Fixed -SizeBytes 40GB
Add-VMHardDiskDrive `
  -ComputerName $vmHost `
  -VMName $vmName `
  -Path $vhdPath `
  -ControllerType SCSI
```

##### # Add "Log01" VHD

```PowerShell
$vhdPath = $vmPath + "\Virtual Hard Disks\$vmName" + "_Log01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Fixed -SizeBytes 10GB
Add-VMHardDiskDrive `
  -ComputerName $vmHost `
  -VMName $vmName `
  -Path $vhdPath `
  -ControllerType SCSI
```

##### # Add "Temp01" VHD

```PowerShell
$vhdPath = $vmPath + "\Virtual Hard Disks\$vmName" + "_Temp01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Fixed -SizeBytes 2GB
Add-VMHardDiskDrive `
  -ComputerName $vmHost `
  -VMName $vmName `
  -Path $vhdPath `
  -ControllerType SCSI
```

##### # Add "Backup01" VHD

```PowerShell
$vhdPath = $vmPath + "\Virtual Hard Disks\$vmName" + "_Backup01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 50GB
Add-VMHardDiskDrive `
  -ComputerName $vmHost `
  -VMName $vmName `
  -Path $vhdPath `
  -ControllerType SCSI
```

---

##### # Format Data01 drive

```PowerShell
Get-Disk 1 |
  Initialize-Disk -PartitionStyle GPT -PassThru |
  New-Partition -DriveLetter D -UseMaximumSize |
  Format-Volume `
    -AllocationUnitSize 64KB `
    -FileSystem NTFS `
    -NewFileSystemLabel "Data01" `
    -Confirm:$false
```

##### # Format Log01 drive

```PowerShell
Get-Disk 2 |
  Initialize-Disk -PartitionStyle GPT -PassThru |
  New-Partition -DriveLetter L -UseMaximumSize |
  Format-Volume `
    -AllocationUnitSize 64KB `
    -FileSystem NTFS `
    -NewFileSystemLabel "Log01" `
    -Confirm:$false
```

##### # Format Temp01 drive

```PowerShell
Get-Disk 3 |
  Initialize-Disk -PartitionStyle GPT -PassThru |
  New-Partition -DriveLetter T -UseMaximumSize |
  Format-Volume `
    -AllocationUnitSize 64KB `
    -FileSystem NTFS `
    -NewFileSystemLabel "Temp01" `
    -Confirm:$false
```

##### # Format Backup01 drive

```PowerShell
Get-Disk 4 |
  Initialize-Disk -PartitionStyle GPT -PassThru |
  New-Partition -DriveLetter Z -UseMaximumSize |
  Format-Volume `
    -FileSystem NTFS `
    -NewFileSystemLabel "Backup01" `
    -Confirm:$false
```

```PowerShell
cls
```

### # Install and configure SQL Server 2017

#### # Prepare server for SQL Server installation

##### # Add setup account to local Administrators group

```PowerShell
$domain = "TECHTOOLBOX"
$username = "setup-sql"

([ADSI]"WinNT://./Administrators,group").Add(
    "WinNT://$domain/$username,user")
```

> **Important**
>
> Sign out and then sign in using the setup account for SQL Server.

##### # Create folder for TempDB data files

```PowerShell
New-Item `
    -Path "T:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Data" `
    -ItemType Directory
```

#### # Install SQL Server 2017

```PowerShell
$imagePath = ("\\TT-FS01\Products\Microsoft\SQL Server 2017" `
    + "\en_sql_server_2017_standard_x64_dvd_11294407.iso")

$imageDriveLetter = (Mount-DiskImage -ImagePath $ImagePath -PassThru |
    Get-Volume).DriveLetter
```

& ("\$imageDriveLetter" + ":\\setup.exe")

On the **Feature Selection** step, select the following checkbox:

- **Database Engine Services**

On the **Server Configuration** step:

- For the **SQL Server Agent** service, change the **Startup Type** to
  **Automatic**.
- For the **SQL Server Browser** service, leave the **Startup Type** as
  **Disabled**.

On the **Database Engine Configuration** step:

- On the **Server Configuration** tab, in the **Specify SQL Server
  administrators** section, click **Add...** and then add the domain group for
  SQL Server administrators.
- On the **Data Directories** tab:
  - In the **Data root directory** box, type **D:\\Microsoft SQL Server\\**.
  - In the **User database log directory** box, change the drive letter to
    **L:** (the value should be **L:\\Microsoft SQL
    Server\\MSSQL14.MSSQLSERVER\\MSSQL\\Data**).
  - In the **Backup directory** box, change the drive letter to **Z:** (the
    value should be **Z:\\Microsoft SQL
    Server\\MSSQL14.MSSQLSERVER\\MSSQL\\Backup**).
- On the **TempDB** tab:
  - Remove the default data directory (**D:\\Microsoft SQL
    Server\\MSSQL14.MSSQLSERVER\\MSSQL\\Data**).
  - Add the data directory on the **Temp01** volume (**T:\\Microsoft SQL
    Server\\MSSQL14.MSSQLSERVER\\MSSQL\\Data**).
  - Ensure the **Log directory** is set to **T:\\Microsoft SQL
    Server\\MSSQL14.MSSQLSERVER\\MSSQL\\Data**.

> **Important**
>
> Wait for the installation to complete.

```PowerShell
cls
```

#### # Install SQL Server Management Studio

```PowerShell
& "\\TT-FS01\Products\Microsoft\SQL Server Management Studio\18.2\SSMS-Setup-ENU.exe"
```

> **Important**
>
> Wait for the installation to complete.

```PowerShell
cls
```

#### # Configure firewall rules for SQL Server

```PowerShell
New-NetFirewallRule `
    -Name "SQL Server Database Engine" `
    -DisplayName "SQL Server Database Engine" `
    -Group "Technology Toolbox (Custom)" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 1433 `
    -Action Allow
```

```PowerShell
cls
```

#### # Configure permissions for Software Usage Metrics feature

```PowerShell
icacls C:\Windows\System32\LogFiles\Sum\Api.chk `
    /grant "NT Service\MSSQLSERVER:(M)"

icacls C:\Windows\System32\LogFiles\Sum\Api.log `
    /grant "NT Service\MSSQLSERVER:(M)"

icacls C:\Windows\System32\LogFiles\Sum\SystemIdentity.mdb `
    /grant "NT Service\MSSQLSERVER:(M)"
```

##### Reference

**Error 1032 messages in the Application log in Windows Server 2012**\
From <[https://support.microsoft.com/en-us/help/2811566/error-1032-messages-in-the-application-log-in-windows-server-2012](https://support.microsoft.com/en-us/help/2811566/error-1032-messages-in-the-application-log-in-windows-server-2012)>

```PowerShell
cls
```

#### # Configure DCOM permissions for SQL Server

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\SQL\Configure DCOM Permissions.ps1' -Verbose
```

```PowerShell
cls
```

#### # Install cumulative update for SQL Server

```PowerShell
& "\\TT-FS01\Products\Microsoft\SQL Server 2017\Patches\CU16\SQLServer2017-KB4508218-x64.exe"
```

#### Configure settings for SQL Server Agent job history log

##### Reference

**SQL SERVER - Dude, Where is the SQL Agent Job History? - Notes from the Field
#017**\
From <[https://blog.sqlauthority.com/2014/02/27/sql-server-dude-where-is-the-sql-agent-job-history-notes-from-the-field-017/](https://blog.sqlauthority.com/2014/02/27/sql-server-dude-where-is-the-sql-agent-job-history-notes-from-the-field-017/)>

---

**SQL Server Management Studio** - Database Engine

##### -- Do not limit size of SQL Server Agent job history log

```SQL
USE [msdb]
GO
EXEC msdb.dbo.sp_set_sqlagent_properties @jobhistory_max_rows=-1,
    @jobhistory_max_rows_per_job=-1
GO
```

---

#### Configure SQL Server maintenance

##### Reference

**SQL Server Backup, Integrity Check, and Index and Statistics Maintenance**\
From <[https://ola.hallengren.com/](https://ola.hallengren.com/)>

---

**TT-ADMIN02** - Run as administrator

```PowerShell
cls
```

##### # Download SQL Server maintenance solution files

```PowerShell
New-Item -ItemType Directory -Path C:\NotBackedUp\GitHub
New-Item -ItemType Directory -Path C:\NotBackedUp\GitHub\technology-toolbox

Push-Location C:\NotBackedUp\GitHub\technology-toolbox

git clone https://github.com/technology-toolbox/sql-server-maintenance-solution.git

Pop-Location
```

---

---

**SQL Server Management Studio** - Database Engine

##### -- Create SqlMaintenance database

```SQL
CREATE DATABASE SqlMaintenance
GO
```

---

##### Create maintenance table, stored procedures, and jobs

Execute script in SQL Server Management Studio: **MaintenanceSolution.sql**

##### Configure schedules for SqlMaintenance jobs

Execute script in SQL Server Management Studio: **JobSchedules.sql**

## Configure Max Degree of Parallelism for SharePoint

### Reference

Set max degree of parallelism (MAXDOP) to 1 for instances of SQL Server that
host SharePoint databases to make sure that a single SQL Server process serves
each request.

From
<[https://docs.microsoft.com/en-us/sharepoint/administration/best-practices-for-sql-server-in-a-sharepoint-server-farm](https://docs.microsoft.com/en-us/sharepoint/administration/best-practices-for-sql-server-in-a-sharepoint-server-farm)>

---

**SQL Server Management Studio** - Database Engine

### -- Set Max Degree of Parallelism to 1

```SQL
EXEC sys.sp_configure N'show advanced options', N'1'  RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'max degree of parallelism', N'1'
GO
RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'show advanced options', N'0'  RECONFIGURE WITH OVERRIDE
GO
```

---

```PowerShell
cls
```

### # Restart SQL Server

```PowerShell
Stop-Service SQLSERVERAGENT

Restart-Service MSSQLSERVER

Start-Service SQLSERVERAGENT
```

## Baseline virtual machine

---

**TT-ADMIN02** - Run as administrator

```PowerShell
cls
```

### # Checkpoint VM

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "TT-SQL03"
$checkpointName = "Baseline"

Stop-VM -ComputerName $vmHost -Name $vmName

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName $checkpointName
```

---

## Back up virtual machine

```PowerShell
cls
```

## # Configure monitoring

### # Install Operations Manager agent

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\System Center 2016\SCOM\Agent\AMD64" `
    + "\MOMAgent.msi"

$installerArguments = "MANAGEMENT_GROUP=HQ" `
    + " MANAGEMENT_SERVER_DNS=TT-SCOM03" `
    + " ACTIONS_USE_COMPUTER_ACCOUNT=1"

Start-Process `
    -FilePath msiexec.exe `
    -ArgumentList "/i `"$installerPath`" $installerArguments" `
    -Wait
```

### Approve manual agent install in Operations Manager

## Configure Data Collection

---

**SQL Server Management Studio** - Database Engine

### -- Create SqlManagement database

```SQL
CREATE DATABASE SqlManagement
ON PRIMARY
(
    NAME = N'SqlManagement'
    , FILENAME = N'D:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Data\SqlManagement.mdf'
    , SIZE = 102400KB
    , FILEGROWTH = 102400KB
)
LOG ON
(
    NAME = N'SqlManagement_log'
    , FILENAME = N'L:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Data\SqlManagement_log.ldf'
    , SIZE = 20480KB
    , FILEGROWTH = 10%
)
```

---

### Configure management data warehouse

### Configure data collection

#### Configure default data collection

#### Stop data collection for query statistics and server activity

```PowerShell
cls
```

## # Configure database backups

### # Install DPM agent

```PowerShell
$installer = "\\TT-FS01\Products\Microsoft\System Center 2016" `
    + "\DPM\Agents\DPMAgentInstaller_x64.exe"

& $installer TT-DPM02.corp.technologytoolbox.com
```

### Attach DPM agent

---

**TT-ADMIN02** - DPM Management Shell

```PowerShell
$productionServer = 'TT-SQL03'

.\Attach-ProductionServer.ps1 `
    -DPMServerName TT-DPM02 `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `
    -UserName jjameson-admin
```

---

### Add "Local System" account to SQL Server sysadmin role

---

**SQL Server Management Studio** - Database Engine - **TT-SQL03**

```SQL
ALTER SERVER ROLE [sysadmin] ADD MEMBER [NT AUTHORITY\SYSTEM]
GO
```

---

#### Reference

**Protection agent jobs may fail for SQL Server 2012 databases**\
Pasted from <[http://technet.microsoft.com/en-us/library/dn281948.aspx](http://technet.microsoft.com/en-us/library/dn281948.aspx)>

### Configure backups

#### Add server to SQL Server protection group in DPM

---

**TT-ADMIN02** - Run as administrator

```PowerShell
cls
```

## # Delete VM checkpoint - "Baseline"

```PowerShell
$vmHost = 'TT-HV05A'
$vmName = 'TT-SQL03'

Remove-VMSnapshot `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Name 'Baseline'

# Wait a few seconds for merge to start...
Start-Sleep -Seconds 5

while (Get-VM -ComputerName $vmHost -VMName $vmName |
    Where Status -eq "Merging disks") {
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 5
}

Write-Host
Write-Host "VM checkpoint deleted"
```

---

## Copy databases from SQL Server 2014 environment

---

**SQL Server Management Studio** - Database Engine - **HAVOK**

### -- Backup databases in SQL Server 2014 environment

```SQL
DECLARE @backupPath NVARCHAR(255) = N'\\TT-FS01\Backups\HAVOK'

DECLARE @backupFilePath NVARCHAR(255)
```

#### -- Backup database - AdventureWorks2012

```Console
SET @backupFilePath = @backupPath + N'\AdventureWorks2012.bak'

BACKUP DATABASE [AdventureWorks2012]
TO DISK = @backupFilePath
WITH NOFORMAT, NOINIT
    , NAME = N'AdventureWorks2012-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10, COPY_ONLY
```

#### -- Backup database - AdventureWorksLT2012

```Console
SET @backupFilePath = @backupPath + N'\AdventureWorksLT2012.bak'

BACKUP DATABASE [AdventureWorksLT2012]
TO DISK = @backupFilePath
WITH NOFORMAT, NOINIT
    , NAME = N'AdventureWorksLT2012-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10, COPY_ONLY
```

#### -- Backup database - Caelum

```Console
SET @backupFilePath = @backupPath + N'\Caelum.bak'

BACKUP DATABASE [Caelum]
TO DISK = @backupFilePath
WITH NOFORMAT, NOINIT
    , NAME = N'Caelum-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10, COPY_ONLY
```

#### -- Backup database - Caelum_Warehouse

```Console
SET @backupFilePath = @backupPath + N'\Caelum_Warehouse.bak'

BACKUP DATABASE [Caelum_Warehouse]
TO DISK = @backupFilePath
WITH NOFORMAT, NOINIT
    , NAME = N'Caelum_Warehouse-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10, COPY_ONLY
```

#### -- Backup database - LoadTest2010

```Console
SET @backupFilePath = @backupPath + N'\LoadTest2010.bak'

BACKUP DATABASE [LoadTest2010]
TO DISK = @backupFilePath
WITH NOFORMAT, NOINIT
    , NAME = N'LoadTest2010-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10, COPY_ONLY
```

#### -- Backup database - Tfs_IntegrationPlatform

```Console
SET @backupFilePath = @backupPath + N'\Tfs_IntegrationPlatform.bak'

BACKUP DATABASE [Tfs_IntegrationPlatform]
TO DISK = @backupFilePath
WITH NOFORMAT, NOINIT
    , NAME = N'Tfs_IntegrationPlatform-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10, COPY_ONLY
```

---

---

**TT-SQL03** - Run as administrator

```PowerShell
cls
```

### # Copy backup files to SQL Server 2017 environment

```PowerShell
robocopy `
    '\\TT-FS01\Backups\HAVOK' `
    'Z:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\Full'
```

---

---

**SQL Server Management Studio** - Database Engine - **TT-SQL03**

### -- Restore databases in SQL Server 2017 environment

```Console
DECLARE @backupPath AS NVARCHAR(255)
SET @backupPath =
    N'Z:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\Full'

DECLARE @dataPath AS NVARCHAR(255)
SET @dataPath = N'D:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Data'

DECLARE @logPath AS NVARCHAR(255)
SET @logPath = N'L:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Data'

DECLARE @backupFile AS NVARCHAR(255)
DECLARE @dataFile AS NVARCHAR(255)
DECLARE @logFile AS NVARCHAR(255)
```

#### -- Restore database - AdventureWorks2012

```Console
SET @backupFile = @backupPath + N'\AdventureWorks2012.bak'
SET @dataFile = @dataPath + N'\AdventureWorks2012.mdf'
SET @logFile = @logPath + N'\AdventureWorks2012.ldf'

RESTORE DATABASE AdventureWorks2012
FROM DISK = @backupFile
WITH
  FILE = 1
  , MOVE N'AdventureWorks2012_Data' TO @dataFile
  , MOVE N'AdventureWorks2012_Log' TO @logFile
  , NOUNLOAD, STATS = 5
```

#### -- Restore database - AdventureWorksLT2012

```Console
SET @backupFile = @backupPath + N'\AdventureWorksLT2012.bak'
SET @dataFile = @dataPath + N'\AdventureWorksLT2012.mdf'
SET @logFile = @logPath + N'\AdventureWorksLT2012.ldf'

RESTORE DATABASE AdventureWorksLT2012
FROM DISK = @backupFile
WITH
  FILE = 1
  , MOVE N'AdventureWorksLT2008_Data' TO @dataFile
  , MOVE N'AdventureWorksLT2008_Log' TO @logFile
  , NOUNLOAD, STATS = 5
```

#### -- Restore database - Caelum

```Console
SET @backupFile = @backupPath + N'\Caelum.bak'
SET @dataFile = @dataPath + N'\Caelum.mdf'
SET @logFile = @logPath + N'\Caelum.ldf'

RESTORE DATABASE Caelum
FROM DISK = @backupFile
WITH
  FILE = 1
  , MOVE N'Caelum_Data' TO @dataFile
  , MOVE N'Caelum_Log' TO @logFile
  , NOUNLOAD, STATS = 5
```

#### -- Restore database - Caelum_Warehouse

```Console
SET @backupFile = @backupPath + N'\Caelum_Warehouse.bak'
SET @dataFile = @dataPath + N'\Caelum_Warehouse.mdf'
SET @logFile = @logPath + N'\Caelum_Warehouse.ldf'

RESTORE DATABASE Caelum_Warehouse
FROM DISK = @backupFile
WITH
  FILE = 1
  , MOVE N'Caelum_Warehouse' TO @dataFile
  , MOVE N'Caelum_Warehouse_log' TO @logFile
  , NOUNLOAD, STATS = 5
```

#### -- Restore database - LoadTest2010

```Console
SET @backupFile = @backupPath + N'\LoadTest2010.bak'
SET @dataFile = @dataPath + N'\LoadTest2010.mdf'
SET @logFile = @logPath + N'\LoadTest2010.ldf'

RESTORE DATABASE LoadTest2010
FROM DISK = @backupFile
WITH
  FILE = 1
  , MOVE N'LoadTest2010' TO @dataFile
  , MOVE N'LoadTest2010_log' TO @logFile
  , NOUNLOAD, STATS = 5
```

#### -- Restore database - Tfs_IntegrationPlatform

```Console
SET @backupFile = @backupPath + N'\Tfs_IntegrationPlatform.bak'
SET @dataFile = @dataPath + N'\Tfs_IntegrationPlatform.mdf'
SET @logFile = @logPath + N'\Tfs_IntegrationPlatform.ldf'

RESTORE DATABASE Tfs_IntegrationPlatform
FROM DISK = @backupFile
WITH
  FILE = 1
  , MOVE N'Tfs_IntegrationPlatform' TO @dataFile
  , MOVE N'Tfs_IntegrationPlatform_log' TO @logFile
  , NOUNLOAD, STATS = 5
```

---

## Upgrade to Data Protection Manager 2019

```PowerShell
cls
```

### # Remove DPM 2016 agent

```PowerShell
msiexec /x `{14DD5B44-17CE-4E89-8BEB-2E6536B81B35`}
```

> **Important**
>
> Restart the computer to complete the removal of the DPM agent.

```PowerShell
Restart-Computer
```

### # Install DPM 2019 agent

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\System Center 2019" `
    + "\DPM\Agents\DPMAgentInstaller_x64.exe"

$installerArguments = "TT-DPM05.corp.technologytoolbox.com"

Start-Process `
    -FilePath $installerPath `
    -ArgumentList "$installerArguments" `
    -Wait
```

Review the licensing agreement. If you accept the Microsoft Software License
Terms, select **I accept the license terms and conditions**, and then click
**OK**.

Confirm the agent installation completed successfully and the following firewall
exceptions have been added:

- Exception for DPMRA.exe in all profiles
- Exception for Windows Management Instrumentation service
- Exception for RemoteAdmin service
- Exception for DCOM communication on port 135 (TCP and UDP) in all profiles

#### Reference

**Installing Protection Agents Manually**\
Pasted from <[http://technet.microsoft.com/en-us/library/hh757789.aspx](http://technet.microsoft.com/en-us/library/hh757789.aspx)>

---

**TT-ADMIN02** - DPM Management Shell

```PowerShell
cls
```

### # Attach DPM agent

```PowerShell
$productionServer = 'TT-SQL03'

.\Attach-ProductionServer.ps1 `
    -DPMServerName TT-DPM05 `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `
    -UserName jjameson-admin
```

---

### Add virtual machine to DPM protection group

## Upgrade to Operations Manager 2019

```PowerShell
cls
```

### # Remove SCOM 2016 agent

```PowerShell
msiexec /x `{742D699D-56EB-49CC-A04A-317DE01F31CD`}
```

```PowerShell
cls
```

### # Install SCOM agent

```PowerShell
$msiPath = "\\TT-FS01\Products\Microsoft\System Center 2019\SCOM\agent\AMD64" `
    + "\MOMAgent.msi"

msiexec.exe /i $msiPath `
    MANAGEMENT_GROUP=HQ `
    MANAGEMENT_SERVER_DNS=TT-SCOM01C `
    ACTIONS_USE_COMPUTER_ACCOUNT=1
```

### Approve manual agent install in Operations Manager

## Move DPM folder for SQL Server backups to different volume

```PowerShell
Push-Location "L:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Data"

New-Item -ItemType SymbolicLink -Name DPM_SQL_PROTECT -Target Z:\DPM_SQL_PROTECT

Pop-Location
```

**TODO:**

---

**TT-ADMIN02** - Run as administrator

```PowerShell
cls
```

## # Make virtual machine highly available

### # Migrate VM to shared storage

```PowerShell
$vmName = "TT-SQL03"

$vm = Get-SCVirtualMachine -Name $vmName
$vmHost = $vm.VMHost

Move-SCVirtualMachine `
    -VM $vm `
    -VMHost $vmHost `
    -HighlyAvailable $true `
    -Path "C:\ClusterStorage\iscsi01-Gold-01" `
    -UseDiffDiskOptimization
```

### # Allow migration to host with different processor version

```PowerShell
Stop-SCVirtualMachine -VM $vmName

Set-SCVirtualMachine -VM $vmName -CPULimitForMigration $true

Start-SCVirtualMachine -VM $vmName
```

---

**TODO:**

```PowerShell
cls
```

## Replace DPM server (TT-DPM05 --> TT-DPM06)

```PowerShell
cls
```

### # Update DPM server

```PowerShell
cd 'C:\Program Files\Microsoft Data Protection Manager\DPM\bin\'

.\SetDpmServer.exe -dpmServerName TT-DPM06.corp.technologytoolbox.com
```

---

**TT-ADMIN04** - DPM Management Shell

```PowerShell
cls
```

### # Attach DPM agent

```PowerShell
$productionServer = 'TT-SQL03'

.\Attach-ProductionServer.ps1 `
    -DPMServerName TT-DPM06 `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `
    -UserName jjameson-admin
```

---

That doesn't work...

> Error:\
> Data Protection Manager Error ID: 307\
> The protection agent operation failed because DPM detected an unknown DPM
> protection agent on tt-sql03.corp.technologytoolbox.com.
>
> Recommended action:\
> Use Add or Remove Programs in Control Panel to uninstall the protection agent from
> tt-sql03.corp.technologytoolbox.com, then reinstall the protection agent and perform
> the operation again.

```PowerShell
cls
```

### # Remove DPM 2019 Agent Coordinator

```PowerShell
msiexec /x `{356B3986-6B7D-4513-B72D-81EB4F43ADE6`}
```

```PowerShell
cls
```

### # Remove DPM 2019 Protection Agent

```PowerShell
msiexec /x `{CC6B6758-3A68-4BBA-9D61-1F3278D6A7EA`}
```

> **Important**
>
> Restart the computer to complete the removal of the DPM agent.

```PowerShell
Restart-Computer
```

### # Install DPM 2019 agent

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\System Center 2019" `
    + "\DPM\Agents\DPMAgentInstaller_x64.exe"

$installerArguments = "TT-DPM06.corp.technologytoolbox.com"

Start-Process `
    -FilePath $installerPath `
    -ArgumentList "$installerArguments" `
    -Wait
```

---

**TT-ADMIN04** - DPM Management Shell

```PowerShell
cls
```

### # Attach DPM agent

```PowerShell
$productionServer = 'TT-SQL03'

.\Attach-ProductionServer.ps1 `
    -DPMServerName TT-DPM06 `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `
    -UserName jjameson-admin
```

---

### Add databases to protection group in DPM

```PowerShell
cls
```

### # Configure antivirus on DPM protected server

#### # Disable real-time monitoring by Windows Defender for DPM server

```PowerShell
[array] $excludeProcesses = Get-MpPreference | select -ExpandProperty ExclusionProcess

$excludeProcesses +=
   "$env:ProgramFiles\Microsoft Data Protection Manager\DPM\bin\DPMRA.exe"

Set-MpPreference -ExclusionProcess $excludeProcesses
```

#### # Configure antivirus software to delete infected files

```PowerShell
Set-MpPreference -LowThreatDefaultAction Remove
Set-MpPreference -ModerateThreatDefaultAction Remove
Set-MpPreference -HighThreatDefaultAction Remove
Set-MpPreference -SevereThreatDefaultAction Remove
```

#### Reference

**Run antivirus software on the DPM server**\
From <[https://docs.microsoft.com/en-us/system-center/dpm/run-antivirus-server?view=sc-dpm-2019](https://docs.microsoft.com/en-us/system-center/dpm/run-antivirus-server?view=sc-dpm-2019)>

**TODO:**

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

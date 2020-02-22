# TT-SQL2017-DEV - Windows Server 2016

Saturday, February 3, 2018
6:28 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

### Install Windows Server 2016

---

**FOOBAR11** - Run as administrator

```PowerShell
cls
```

#### # Create virtual machine

```PowerShell
$vmHost = "WOLVERINE"
$vmName = "TT-SQL2017-DEV"
$vmPath = "D:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 2GB `
    -SwitchName "Management"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 2 `
    -StaticMemory

Start-VM -ComputerName $vmHost -Name $vmName
```

---

#### Install custom Windows Server 2016 image

- On the **Task Sequence** step, select **Windows Server 2016** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **TT-SQL2017-DEV**.
  - Click **Next**.
- On the **Applications** step, do not select any applications, and click **Next**.

#### # Rename local Administrator account and set password

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

---

**FOOBAR11** - Run as administrator

```PowerShell
cls
```

#### # Move computer to different OU

```PowerShell
$vmName = "TT-SQL2017-DEV"

$targetPath = "OU=SQL Servers,OU=Servers" `
    + ",OU=Resources,OU=Development" `
    + ",DC=corp,DC=technologytoolbox,DC=com"

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

---

#### Login as .\\foo

#### # Copy Toolbox content

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$source = "\\TT-FS01\Public\Toolbox"
$destination = "C:\NotBackedUp\Public\Toolbox"

robocopy $source $destination /E /XD "Microsoft SDKs"
```

#### # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

#### # Configure networking

```PowerShell
$interfaceAlias = "Management"
```

##### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

##### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Start-Sleep -Seconds 5

ping TT-FS01 -f -l 8900
```

---

**FOOBAR11** - Run as administrator

```PowerShell
cls
```

#### # Set first boot device to hard drive

```PowerShell
$vmHost = "WOLVERINE"
$vmName = "TT-SQL2017-DEV"

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

---

```PowerShell
cls
```

#### # Add SQL setup account to local Administrators group

```PowerShell
$domain = "TECHTOOLBOX"
$username = "setup-sql"

([ADSI]"WinNT://./Administrators,group").Add(
    "WinNT://$domain/$username,user")
```

### Configure VM processors, memory, and storage

---

**FOOBAR11** - Run as administrator

```PowerShell
cls
```

#### # Configure storage for the SQL Server VM

```PowerShell
$vmHost = "WOLVERINE"
$vmName = "TT-SQL2017-DEV"

$vmPath = "D:\NotBackedUp\VMs\$vmName"

# Add "Data01" VHD

$vhdPath = $vmPath + "\Virtual Hard Disks\$vmName" + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 40GB
Add-VMHardDiskDrive `
  -ComputerName $vmHost `
  -VMName $vmName `
  -Path $vhdPath `
  -ControllerType SCSI

# Add "Log01" VHD

$vhdPath = $vmPath + "\Virtual Hard Disks\$vmName" + "_Log01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 8GB
Add-VMHardDiskDrive `
  -ComputerName $vmHost `
  -VMName $vmName `
  -Path $vhdPath `
  -ControllerType SCSI

# Add "Temp01" VHD

$vhdPath = $vmPath + "\Virtual Hard Disks\$vmName" + "_Temp01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 2GB
Add-VMHardDiskDrive `
  -ComputerName $vmHost `
  -VMName $vmName `
  -Path $vhdPath `
  -ControllerType SCSI

# Add "Backup01" VHD

$vhdPath = $vmPath + "\Virtual Hard Disks\$vmName" + "_Backup01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 50GB
Add-VMHardDiskDrive `
  -ComputerName $vmHost `
  -VMName $vmName `
  -Path $vhdPath `
  -ControllerType SCSI
```

---

#### Login as TECHTOOLBOX\\setup-sql

##### # Format Data01 drive

```PowerShell
Get-Disk 1 |
  Initialize-Disk -PartitionStyle MBR -PassThru |
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
  Initialize-Disk -PartitionStyle MBR -PassThru |
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
  Initialize-Disk -PartitionStyle MBR -PassThru |
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
  Initialize-Disk -PartitionStyle MBR -PassThru |
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

> **Important**
>
> Wait for the installation to complete.

```PowerShell
cls
```

#### # Install SQL Server Management Studio

```PowerShell
& "\\TT-FS01\Products\Microsoft\SQL Server 2017\SSMS-Setup-ENU-14.0.17213.0.exe"
```

```PowerShell
cls
```

#### # Configure firewall rules for SQL Server

```PowerShell
New-NetFirewallRule `
    -Name "SQL Server Analysis Services" `
    -DisplayName "SQL Server Analysis Services" `
    -Group "Technology Toolbox (Custom)" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 2383 `
    -Action Allow

New-NetFirewallRule `
    -Name "SQL Server Database Engine" `
    -DisplayName "SQL Server Database Engine" `
    -Group "Technology Toolbox (Custom)" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 1433 `
    -Action Allow
```

#### # Configure permissions on \\Windows\\System32\\LogFiles\\Sum files

```PowerShell
icacls C:\Windows\System32\LogFiles\Sum\Api.chk `
    /grant "NT Service\MSSQLSERVER:(M)"

icacls C:\Windows\System32\LogFiles\Sum\Api.log `
    /grant "NT Service\MSSQLSERVER:(M)"

icacls C:\Windows\System32\LogFiles\Sum\SystemIdentity.mdb `
    /grant "NT Service\MSSQLSERVER:(M)"

icacls C:\Windows\System32\LogFiles\Sum\Api.chk `
    /grant "NT Service\MSSQLServerOLAPService:(M)"

icacls C:\Windows\System32\LogFiles\Sum\Api.log `
    /grant "NT Service\MSSQLServerOLAPService:(M)"

icacls C:\Windows\System32\LogFiles\Sum\SystemIdentity.mdb `
    /grant "NT Service\MSSQLServerOLAPService:(M)"
```

```PowerShell
cls
```

## # Copy data from TFS 2015 environment

### # Restore databases to TFS 2018 environment

#### # Copy database backups

```PowerShell
net use \\HAVOK\Z$ /USER:TECHTOOLBOX\jjameson-admin
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$source = '\\HAVOK\Z$\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full'
$destination = 'Z:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup'

robocopy $source $destination

$source = '\\HAVOK\Z$\Microsoft SQL Server\MSAS12.MSSQLSERVER\OLAP\Backup'
$destination = 'Z:\Microsoft SQL Server\MSAS14.MSSQLSERVER\OLAP\Backup'

robocopy $source $destination
```

---

**SQL Server Management Studio** - Database Engine

#### -- Restore Reporting Services and TFS 2015 OLTP databases

```Console
DECLARE @backupPath AS NVARCHAR(255)
SET @backupPath =
    N'Z:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup'

DECLARE @dataPath AS NVARCHAR(255)
SET @dataPath = N'D:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Data'

DECLARE @logPath AS NVARCHAR(255)
SET @logPath = N'L:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Data'

DECLARE @backupFile AS NVARCHAR(255)
DECLARE @dataFile AS NVARCHAR(255)
DECLARE @logFile AS NVARCHAR(255)

-- Restore "ReportServer" database

SET @backupFile = @backupPath + N'\ReportServer_Tfs.bak'
SET @dataFile = @dataPath + N'\ReportServer_Tfs.mdf'
SET @logFile = @logPath + N'\ReportServer_Tfs_log.ldf'

RESTORE DATABASE ReportServer_Tfs
FROM DISK = @backupFile
WITH
  FILE = 1
  , MOVE N'ReportServer' TO @dataFile
  , MOVE N'ReportServer_log' TO @logFile
  , NOUNLOAD
  , STATS = 5

-- Restore "ReportServer_TfsTempDB" database

SET @backupFile = @backupPath + N'\ReportServer_TfsTempDB.bak'
SET @dataFile = @dataPath + N'\ReportServer_TfsTempDB.mdf'
SET @logFile = @logPath + N'\ReportServer_TfsTempDB_log.ldf'

RESTORE DATABASE ReportServer_TfsTempDB
FROM DISK = @backupFile
WITH
  FILE = 1
  , MOVE N'ReportServerTempDB' TO @dataFile
  , MOVE N'ReportServerTempDB_log' TO @logFile
  , NOUNLOAD
  , STATS = 5

-- Restore "Tfs_Configuration" database

SET @backupFile = @backupPath + N'\Tfs_Configuration.bak'
SET @dataFile = @dataPath + N'\Tfs_Configuration.mdf'
SET @logFile = @logPath + N'\Tfs_Configuration_log.ldf'

RESTORE DATABASE Tfs_Configuration
FROM DISK = @backupFile
WITH
  FILE = 1
  , MOVE N'Tfs_Configuration' TO @dataFile
  , MOVE N'Tfs_Configuration_log' TO @logFile
  , NOUNLOAD
  , STATS = 5

-- Restore "Tfs_DefaultCollection" database

SET @backupFile = @backupPath + N'\Tfs_DefaultCollection.bak'
SET @dataFile = @dataPath + N'\Tfs_DefaultCollection.mdf'
SET @logFile = @logPath + N'\Tfs_DefaultCollection_log.ldf'

RESTORE DATABASE Tfs_DefaultCollection
FROM DISK = @backupFile
WITH
  FILE = 1
  , MOVE N'Tfs_DefaultCollection' TO @dataFile
  , MOVE N'Tfs_DefaultCollection_log' TO @logFile
  , NOUNLOAD
  , STATS = 5

-- Restore "Tfs_Warehouse" database

SET @backupFile = @backupPath + N'\Tfs_Warehouse.bak'
SET @dataFile = @dataPath + N'\Tfs_Warehouse.mdf'
SET @logFile = @logPath + N'\Tfs_Warehouse_log.ldf'

RESTORE DATABASE Tfs_Warehouse
FROM DISK = @backupFile
WITH
  FILE = 1
  , MOVE N'Tfs_Warehouse' TO @dataFile
  , MOVE N'Tfs_Warehouse_log' TO @logFile
  , NOUNLOAD
  , STATS = 5
```

---

#### TODO: Restore SQL Server login for TFS reporting service account

CREATE LOGIN [PNKUS\\Srvc-TFSReports] FROM WINDOWS\
WITH DEFAULT_DATABASE = master\
GO\
USE Tfs_Warehouse\
GO\
CREATE USER [PNKUS\\Srvc-TFSReports]\
FOR LOGIN [PNKUS\\Srvc-TFSReports]

ALTER ROLE TfsWarehouseDataReader\
ADD MEMBER [PNKUS\\Srvc-TFSReports]

#### Restore the TFS 2015 OLAP database

---

**SQL Server Management Studio** - Analysis Services

#### <!-- Restore Reporting Services and TFS 2015 OLTP databases -->

```XML
<Restore xmlns="http://schemas.microsoft.com/analysisservices/2003/engine">
  <File>Z:\Microsoft SQL Server\MSAS14.MSSQLSERVER\OLAP\Backup\Tfs_Analysis.abf</File>
  <Password>{password}</Password>
</Restore>
```

---

> **Important**
>
> Be sure to replace the {password} placeholder in the MDX script with a secure password before backing up the OLAP database.

```PowerShell
cls
```

### # Configure TFS backups and backup TFS

#### # Configure Backup share

```PowerShell
$backupPath = "Z:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup"

New-SmbShare `
  -Name Backup `
  -Path $backupPath `
  -CachingMode None `
  -FullAccess "NT AUTHORITY\Authenticated Users"
```

#### # Remove "BUILTIN\\Users" permissions

```PowerShell
icacls $backupPath /inheritance:d
icacls $backupPath /remove:g "BUILTIN\Users"
```

#### # Grant permissions for configuring TFS backups

```PowerShell
icacls $backupPath /grant '"TECHTOOLBOX\setup-tfs":(OI)(CI)(F)'
```

#### # Grant TFS App Tier computer account modify access to Backup folder

```PowerShell
icacls $backupPath /grant 'TT-TFS2018-DEV$:(OI)(CI)(M)'
```

#### # Grant TFS Data Tier computer account modify access to Backup folder

```PowerShell
icacls $backupPath /grant 'TT-SQL2017-DEV$:(OI)(CI)(M)'
```

#### # Grant TFS administrators full control to Backups folder

```PowerShell
icacls $backupPath /grant '"TECHTOOLBOX\Team Foundation Server Admins":(OI)(CI)(F)'
```

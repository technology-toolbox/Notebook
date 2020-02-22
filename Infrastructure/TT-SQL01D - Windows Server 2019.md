# TT-SQL01D - Windows Server 2019

Tuesday, November 26, 2019
8:32 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure infrastructure

---

**TT-ADMIN02** - Run as administrator

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05B"
$vmName = "TT-SQL01D"
$vmPath = "E:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

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
    -ProcessorCount 2 `
    -AutomaticCheckpointsEnabled $false

Set-VMNetworkAdapterVlan `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Access `
    -VlanId 30

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Install custom Windows Server 2019 image

- On the **Task Sequence** step, select **Windows Server 2019** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **TT-SQL01D**.
  - Click **Next**.
- On the **Applications** step, ensure no items are selected and click **Next**.

```PowerShell
cls
```

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

---

**TT-ADMIN02** - Run as administrator

```PowerShell
cls
```

### # Move computer to different OU

```PowerShell
$vmName = "TT-SQL01D"

$targetPath = ("OU=SQL Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

### # Configure Windows Update

#### # Add machine to security group for Windows Update configuration

```PowerShell
Add-ADGroupMember -Identity "Windows Update - Slot 1" -Members ($vmName + '$')
```

---

### Login as local administrator account

```PowerShell
cls
```

### # Enable performance counters for Server Manager

```PowerShell
$taskName = "\Microsoft\Windows\PLA\Server Manager Performance Monitor"

Enable-ScheduledTask -TaskName $taskName

logman start "Server Manager Performance Monitor"
```

### # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

> **Note**
>
> PowerShell remoting must be enabled for remote Windows Update using PoshPAIG ([https://github.com/proxb/PoshPAIG](https://github.com/proxb/PoshPAIG)).

```PowerShell
cls
```

### # Configure networking

```PowerShell
$interfaceAlias = "Management"
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

#### Configure storage for SQL Server

| Disk | Drive Letter | Volume Size | VHD Type | Allocation Unit Size | Volume Label | Storage Level |
| ---- | ------------ | ----------- | -------- | -------------------- | ------------ | ------------- |
| 0    | C:           | 40 GB       | Dynamic  | 4K                   | OSDisk       | Silver        |
| 1    | D:           | 40 GB       | Fixed    | 64K                  | Data01       | Gold          |
| 2    | L:           | 15 GB       | Fixed    | 64K                  | Log01        | Gold          |
| 3    | T:           | 2 GB        | Fixed    | 64K                  | Temp01       | Gold          |
| 4    | Z:           | 50 GB       | Dynamic  | 4K                   | Backup01     | Silver        |

---

**TT-ADMIN02** - Run as administrator

```PowerShell
cls
```

#### # Add virtual disks for SQL Server

```PowerShell
$vmHost = "TT-HV05B"
$vmName = "TT-SQL01D"
$goldStoragePath = "D:\NotBackedUp\VMs\$vmName\Virtual Hard Disks"
$silverStoragePath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks"
```

##### # Add "Data01" VHD

```PowerShell
$vhdPath = $goldStoragePath + "\$vmName" + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Fixed -SizeBytes 40GB
Add-VMHardDiskDrive `
  -ComputerName $vmHost `
  -VMName $vmName `
  -Path $vhdPath `
  -ControllerType SCSI
```

##### # Add "Log01" VHD

```PowerShell
$vhdPath = $goldStoragePath + "\$vmName" + "_Log01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Fixed -SizeBytes 15GB
Add-VMHardDiskDrive `
  -ComputerName $vmHost `
  -VMName $vmName `
  -Path $vhdPath `
  -ControllerType SCSI
```

##### # Add "Temp01" VHD

```PowerShell
$vhdPath = $goldStoragePath + "\$vmName" + "_Temp01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Fixed -SizeBytes 2GB
Add-VMHardDiskDrive `
  -ComputerName $vmHost `
  -VMName $vmName `
  -Path $vhdPath `
  -ControllerType SCSI
```

##### # Add "Backup01" VHD

```PowerShell
$vhdPath = $silverStoragePath + "\$vmName" + "_Backup01.vhdx"

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

#### # Format virtual disks

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

## Prepare server for SQL Server 2017 installation

### Configure failover clustering (for SQL Server AlwaysOn Availability Group)

---

**TT-ADMIN02** - Run as administrator

```PowerShell
cls
```

#### # Add a second network adapter for cluster network

```PowerShell
$vmName = "TT-SQL01D"
$vmNetwork = Get-SCVMNetwork -Name "Cluster VM Network"
$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"
$ipAddressPool = Get-SCStaticIPAddressPool -Name "Cluster Address Pool"
$portClassification = Get-SCPortClassification -Name "Host Cluster Workload"

$vm = Get-SCVirtualMachine $vmName

Stop-SCVirtualMachine $vmName

$networkAdapter = New-SCVirtualNetworkAdapter `
    -VM $vm `
    -VMNetwork $vmNetwork `
    -Synthetic `
    -PortClassification $portClassification

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

Start-SCVirtualMachine $vmName
```

---

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

#### # Install Failover Clustering feature on second node

```PowerShell
Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools -Restart
```

> **Important**
>
> After the computer restarts, sign in using the domain setup account for SQL Server (**TECHTOOLBOX\\setup-sql**).

#### Join cluster

(completed on TT-SQL01C)

```PowerShell
cls
```

### # Create folder for TempDB data files

```PowerShell
New-Item `
    -Path "T:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Data" `
    -ItemType Directory
```

## # Install and configure SQL Server 2017

### # Install SQL Server 2017

```PowerShell
$imagePath = ("\\TT-FS01\Products\Microsoft\SQL Server 2017" `
    + "\en_sql_server_2017_enterprise_x64_dvd_11293666.iso")

$imageDriveLetter = (Mount-DiskImage -ImagePath $ImagePath -PassThru |
    Get-Volume).DriveLetter
```

& ("\$imageDriveLetter" + ":\\setup.exe")

On the **Feature Selection** step, select the following checkboxes:

- **Database Engine Services**
  - **Full-Text and Semantic Extractions for Search**

> **Note**
>
> System Center Operations Manager 2019 requires the Full-Text Search component to be installed.

On the **Server Configuration** step:

- For the **SQL Server Agent** service, change the **Startup Type** to **Automatic**.
- For the **SQL Server Database Engine** service, change the **Account Name **to **TECHTOOLBOX\\s-sql01**.
- For the **SQL Server Browser** service, leave the **Startup Type** as **Disabled**.
- Select the **Grant Perform Volume Maintenance Task privilege to SQL Server Database Engine Service** checkbox.

On the **Database Engine Configuration** step:

- On the **Server Configuration** tab, in the **Specify SQL Server administrators** section, click **Add...** and then add the domain group for SQL Server administrators (**TECHTOOLBOX\\SQL Server Admins**).
- On the **Data Directories** tab:
  - In the **Data root directory** box, type **D:\\Microsoft SQL Server\\**.
  - In the **User database log directory** box, change the drive letter to **L:** (the value should be **L:\\Microsoft SQL Server\\MSSQL14.MSSQLSERVER\\MSSQL\\Data**).
  - In the **Backup directory** box, change the drive letter to **Z:** (the value should be **Z:\\Microsoft SQL Server\\MSSQL14.MSSQLSERVER\\MSSQL\\Backup**).
- On the **TempDB** tab:
  - Remove the default data directory (**D:\\Microsoft SQL Server\\MSSQL14.MSSQLSERVER\\MSSQL\\Data**).
  - Add the data directory on the **Temp01** volume (**T:\\Microsoft SQL Server\\MSSQL14.MSSQLSERVER\\MSSQL\\Data**).
  - Ensure the **Log directory** is set to **T:\\Microsoft SQL Server\\MSSQL14.MSSQLSERVER\\MSSQL\\Data**.

> **Important**
>
> Wait for the installation to complete.

```PowerShell
cls
```

### # Install SQL Server Management Studio

```PowerShell
& "\\TT-FS01\Products\Microsoft\SQL Server Management Studio\18.4\SSMS-Setup-ENU.exe"
```

> **Important**
>
> Wait for the installation to complete and restart the computer.

```PowerShell
cls
```

### # Install cumulative update for SQL Server

```PowerShell
& "\\TT-FS01\Products\Microsoft\SQL Server 2017\Patches\CU17\SQLServer2017-KB4515579-x64.exe"
```

> **Important**
>
> Wait for the installation to complete.

```PowerShell
cls
```

### # Configure firewall rules for SQL Server

```PowerShell
New-NetFirewallRule `
    -Name "SQL Server Database Engine" `
    -DisplayName "SQL Server Database Engine" `
    -Group "Technology Toolbox (Custom)" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 1433 `
    -Action Allow

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
> Port 5022 is used for database mirroring (e.g. AlwaysOn availability groups).

```PowerShell
cls
```

### # Configure permissions for Software Usage Metrics feature

```PowerShell
icacls C:\Windows\System32\LogFiles\Sum\Api.chk `
    /grant "TECHTOOLBOX\s-sql01:(M)"

icacls C:\Windows\System32\LogFiles\Sum\Api.log `
    /grant "TECHTOOLBOX\s-sql01:(M)"

icacls C:\Windows\System32\LogFiles\Sum\SystemIdentity.mdb `
    /grant "TECHTOOLBOX\s-sql01:(M)"
```

#### Reference

**Error 1032 messages in the Application log in Windows Server 2012**\
From <[https://support.microsoft.com/en-us/help/2811566/error-1032-messages-in-the-application-log-in-windows-server-2012](https://support.microsoft.com/en-us/help/2811566/error-1032-messages-in-the-application-log-in-windows-server-2012)>

```PowerShell
cls
```

### # Configure DCOM permissions for SQL Server

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\SQL\Configure DCOM Permissions.ps1' -Verbose
```

### # Configure settings for SQL Server Agent job history log

#### # Do not limit size of SQL Server Agent job history log

```PowerShell
$sqlcmd = @"
EXEC msdb.dbo.sp_set_sqlagent_properties @jobhistory_max_rows=-1,
    @jobhistory_max_rows_per_job=-1
```

"@

```PowerShell
Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

##### Reference

**SQL SERVER - Dude, Where is the SQL Agent Job History? - Notes from the Field #017**\
From <[https://blog.sqlauthority.com/2014/02/27/sql-server-dude-where-is-the-sql-agent-job-history-notes-from-the-field-017/](https://blog.sqlauthority.com/2014/02/27/sql-server-dude-where-is-the-sql-agent-job-history-notes-from-the-field-017/)>

```PowerShell
cls
```

#### # Configure SQL Server maintenance

##### # Create database for SQL Server maintenance

```PowerShell
$sqlcmd = "CREATE DATABASE SqlMaintenance"

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

##### # Create maintenance table, stored procedures, and jobs

```PowerShell
$url = "https://raw.githubusercontent.com/technology-toolbox" `
    + "/sql-server-maintenance-solution/master/MaintenanceSolution.sql"

$tempFileName = [System.IO.Path]::GetTempFileName()

Invoke-WebRequest -Uri $url -OutFile $tempFileName

Invoke-Sqlcmd -InputFile $tempFileName -Verbose -Debug:$false

Set-Location C:

Remove-Item $tempFileName
```

##### # Configure schedules for SQL Server maintenance jobs

```PowerShell
$url = "https://raw.githubusercontent.com/technology-toolbox" `
    + "/sql-server-maintenance-solution/master/JobSchedules.sql"

$tempFileName = [System.IO.Path]::GetTempFileName()

Invoke-WebRequest -Uri $url -OutFile $tempFileName

Invoke-Sqlcmd -InputFile $tempFileName -Verbose -Debug:$false

Set-Location C:

Remove-Item $tempFileName
```

##### Reference

**SQL Server Backup, Integrity Check, and Index and Statistics Maintenance**\
From <[https://ola.hallengren.com/](https://ola.hallengren.com/)>

```PowerShell
cls
```

## # Configure AlwaysOn availability groups

### # Enable AlwaysOn availability groups

```PowerShell
Enable-SqlAlwaysOn -ServerInstance $env:COMPUTERNAME -Force
```

## Add first SQL Server 2017 replica to availability group

## Add second SQL Server 2017 replica to availability group

---

**SQL Server Management Studio** - Database Engine - **TT-SQL01D**

### -- Create logins for databases in availability group

```SQL
USE [master]
GO

CREATE LOGIN [TECHTOOLBOX\s-scom-action] FROM WINDOWS
CREATE LOGIN [TECHTOOLBOX\s-scom-das] FROM WINDOWS
CREATE LOGIN [TECHTOOLBOX\s-scom-data-reader] FROM WINDOWS
CREATE LOGIN [TECHTOOLBOX\s-scom-data-writer] FROM WINDOWS
CREATE LOGIN [TECHTOOLBOX\s-vmm01] FROM WINDOWS
CREATE LOGIN [TECHTOOLBOX\TT-SCOM03$] FROM WINDOWS
CREATE LOGIN [TECHTOOLBOX\TT-WSUS03$] FROM WINDOWS
GO
```

### -- Restore databases on secondary SQL Server 2017 replica

```Console
DECLARE @backupPath AS NVARCHAR(255)
SET @backupPath = N'\\TT-SQL01A\SQL-Backups'

DECLARE @dataPath AS NVARCHAR(255)
SET @dataPath = N'D:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Data'

DECLARE @logPath AS NVARCHAR(255)
SET @logPath = N'L:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Data'

DECLARE @backupFile AS NVARCHAR(255)
DECLARE @dataFile AS NVARCHAR(255)
DECLARE @logFile AS NVARCHAR(255)
```

#### -- Restore database - AlwaysOn

```Console
SET @backupFile = @backupPath + N'\AlwaysOn.bak'
SET @dataFile = @dataPath + N'\AlwaysOn.mdf'
SET @logFile = @logPath + N'\AlwaysOn.ldf'

RESTORE DATABASE AlwaysOn
FROM DISK = @backupFile
WITH
  NORECOVERY, STATS = 5
  , MOVE N'AlwaysOn' TO @dataFile
  , MOVE N'AlwaysOn_log' TO @logFile
```

#### -- Restore database - OperationsManager

```Console
SET @backupFile = @backupPath + N'\OperationsManager.bak'
SET @dataFile = @dataPath + N'\OperationsManager.mdf'
SET @logFile = @logPath + N'\OperationsManager.ldf'

RESTORE DATABASE OperationsManager
FROM DISK = @backupFile
WITH
  NORECOVERY, STATS = 5
  , MOVE N'MOM_Data' TO @dataFile
  , MOVE N'MOM_Log' TO @logFile
```

#### -- Restore database - OperationsManagerDW

```Console
SET @backupFile = @backupPath + N'\OperationsManagerDW.bak'
SET @dataFile = @dataPath + N'\OperationsManagerDW.mdf'
SET @logFile = @logPath + N'\OperationsManagerDW.ldf'

RESTORE DATABASE OperationsManagerDW
FROM DISK = @backupFile
WITH
  NORECOVERY, STATS = 5
  , MOVE N'MOM_Data' TO @dataFile
  , MOVE N'MOM_Log' TO @logFile
```

#### -- Restore database - ReportServer_SCOM

```Console
SET @backupFile = @backupPath + N'\ReportServer_SCOM.bak'
SET @dataFile = @dataPath + N'\ReportServer_SCOM.mdf'
SET @logFile = @logPath + N'\ReportServer_SCOM.ldf'

RESTORE DATABASE ReportServer_SCOM
FROM DISK = @backupFile
WITH
  NORECOVERY, STATS = 5
  , MOVE N'ReportServer_SCOM' TO @dataFile
  , MOVE N'ReportServer_SCOM_log' TO @logFile
```

#### -- Restore database - ReportServer_SCOMTempDB

```Console
SET @backupFile = @backupPath + N'\ReportServer_SCOMTempDB.bak'
SET @dataFile = @dataPath + N'\ReportServer_SCOMTempDB.mdf'
SET @logFile = @logPath + N'\ReportServer_SCOMTempDB.ldf'

RESTORE DATABASE ReportServer_SCOMTempDB
FROM DISK = @backupFile
WITH
  NORECOVERY, STATS = 5
  , MOVE N'ReportServer_SCOMTempDB' TO @dataFile
  , MOVE N'ReportServer_SCOMTempDB_log' TO @logFile
```

#### -- Restore database - SUSDB

```Console
SET @backupFile = @backupPath + N'\SUSDB.bak'
SET @dataFile = @dataPath + N'\SUSDB.mdf'
SET @logFile = @logPath + N'\SUSDB.ldf'

RESTORE DATABASE SUSDB
FROM DISK = @backupFile
WITH
  NORECOVERY, STATS = 5
  , MOVE N'SUSDB' TO @dataFile
  , MOVE N'SUSDB_log' TO @logFile
```

#### -- Restore database - VirtualManagerDB

```Console
SET @backupFile = @backupPath + N'\VirtualManagerDB.bak'
SET @dataFile = @dataPath + N'\VirtualManagerDB.mdf'
SET @logFile = @logPath + N'\VirtualManagerDB.ldf'

RESTORE DATABASE VirtualManagerDB
FROM DISK = @backupFile
WITH
  NORECOVERY, STATS = 5
  , MOVE N'VirtualManagerDB' TO @dataFile
  , MOVE N'VirtualManagerDB_log' TO @logFile
```

#### -- Restore transaction log - AlwaysOn

```Console
SET @backupFile = @backupPath + N'\AlwaysOn.trn'

RESTORE LOG AlwaysOn
FROM DISK = @backupFile
WITH FILE = 1, NORECOVERY
```

#### -- Restore transaction log - OperationsManager

```Console
SET @backupFile = @backupPath + N'\OperationsManager.trn'

RESTORE LOG OperationsManager
FROM DISK = @backupFile
WITH FILE = 1, NORECOVERY
```

#### -- Restore transaction log - OperationsManagerDW

```Console
SET @backupFile = @backupPath + N'\OperationsManagerDW.trn'

RESTORE LOG OperationsManagerDW
FROM DISK = @backupFile
WITH FILE = 1, NORECOVERY
```

#### -- Restore transaction log - ReportServer_SCOM

```Console
SET @backupFile = @backupPath + N'\ReportServer_SCOM.trn'

RESTORE LOG ReportServer_SCOM
FROM DISK = @backupFile
WITH FILE = 1, NORECOVERY
```

#### -- Restore transaction log - ReportServer_SCOMTempDB

```Console
SET @backupFile = @backupPath + N'\ReportServer_SCOMTempDB.trn'

RESTORE LOG ReportServer_SCOMTempDB
FROM DISK = @backupFile
WITH FILE = 1, NORECOVERY
```

#### -- Restore transaction log - SUSDB

```Console
SET @backupFile = @backupPath + N'\SUSDB.trn'

RESTORE LOG SUSDB
FROM DISK = @backupFile
WITH FILE = 1, NORECOVERY
```

#### -- Restore transaction log - VirtualManagerDB

```Console
SET @backupFile = @backupPath + N'\VirtualManagerDB.trn'

RESTORE LOG VirtualManagerDB
FROM DISK = @backupFile
WITH FILE = 1, NORECOVERY
```

---

> **Note**
>
> Expect the previous operation to complete in approximately 13 minutes.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/27/CAFEDA3A094DE3086A07603DCA0FFA128756E427.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7D/7CE781DD1E21CEA41AF933AD02C576595683457D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A9/B5765C022C97DF6A396B52A94E5E5C8129A990A9.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DE/ECE41673EE95BA9E2DEABD9295D117124DDBD4DE.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/24/BE54AABD5278FB0F5ECA150B3DA3018718D93924.png)

Click **Add Replica...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CC/D53C814035094311DB429B6026A26966978C19CC.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B8/A08BF50D1B7D192AC47E2277C8012644E14865B8.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3A/1CF3C0A930C223B9B86E107A3013C83086A8073A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FF/7222180AA2ECF6CDF7D1DC0F9EE4675A67F61FFF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C6/C4D84F819F8F117EEB2D258C205B523475439CC6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CB/A5DB20DAAE27A3403F98430631E9FF647C6CABCB.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E2/04167D4DAF5F09DED5ACF3578238240C5FD6AAE2.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D5/3EDF24BE50BEE779173ABA00D59DDE33E28E49D5.png)

## Upgrade databases in availability group to SQL Server 2017

## Complete cluster upgrade to SQL Server 2017

### Remove SQL Server 2016 cluster nodes

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AB/D34E0697581A9D90F3E695E471197127837496AB.png)

Right-click each SQL Server 2016 node and click **Remove from Availability Group...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7E/4DE6A3D3A9216E7D0E17F88A842E03D639B54E7E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/46/7DBD37D19E93A2B11D06FE9B161C632E799C3C46.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7C/F9D8174CEDC6EE73FA2B0982B58996FB921FD07C.png)

### Configure secondary replicate to use synchronous replication

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7B/973D45E3CDAC6218F4A7F077E8F361617336257B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A2/9CDCADEF084100FE68D07CE79B9BC44C8FA112A2.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/35/0188895AC57E2F26470DC5370F35B4DF4F5B5335.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C7/47D6DFB157B07D1E5370BB886583221E8CDD56C7.png)

### Remove SQL Server 2016 nodes from cluster

### Upgrade cluster functional level

```PowerShell
cls
```

## # Install DPM agent

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

Review the licensing agreement. If you accept the Microsoft Software License Terms, select **I accept the license terms and conditions**, and then click **OK**.

Confirm the agent installation completed successfully and the following firewall exceptions have been added:

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
$productionServer = 'TT-SQL01D'

.\Attach-ProductionServer.ps1 `
    -DPMServerName TT-DPM05 `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `
    -UserName jjameson-admin
```

---

### Add virtual machine to DPM protection group

---

**SQL Server Management Studio** - Database Engine - **TT-SQL01D**

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

## Update protection groups in DPM

## Resolve issues with SCOM and new SQL Server 2017 instances

---

**TT-SCOM03** - Run as administrator

```PowerShell
cls
```

### # Stop services on SCOM server

```PowerShell
Stop-Service HealthService
Stop-Service cshost
Stop-Service OMSDK
```

---

```PowerShell
cls
```

### # Enable CLR integration (required for SCOM)

```PowerShell
$sqlcmd = @"
EXEC sp_configure 'clr enabled', 1;
RECONFIGURE;
GO
```

"@

```PowerShell
Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

```PowerShell
cls
```

### # Enable service broker on SCOM database

```PowerShell
$sqlcmd = @"
ALTER DATABASE OperationsManager SET SINGLE_USER WITH ROLLBACK IMMEDIATE
ALTER DATABASE OperationsManager SET ENABLE_BROKER
ALTER DATABASE OperationsManager SET MULTI_USER
```

"@

```PowerShell
Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Invoke-Sqlcmd : The operation cannot be performed on database "OperationsManager" because it is involved in a database mirroring session or an availability group. Some operations are not allowed on a database that is participating in a database mirroring session or in an availability group.
```

Remove database from availability group, enable service broker, and then add back to availability group

---

**SQL Server Management Studio** - Database Engine - **TT-SQL01D**

### -- Configure trusted assemblies for SCOM

```SQL
USE master;
GO

DECLARE @clrName1 nvarchar(4000) = 'Microsoft.EnterpriseManagement.Sql.DataAccessLayer'
DECLARE @hash1 varbinary(64) = 0xEC312664052DE020D0F9631110AFB4DCDF14F477293E1C5DE8C42D3265F543C92FCF8BC1648FC28E9A0731B3E491BCF1D4A8EB838ED9F0B24AE19057BDDBF6EC;

EXEC sys.sp_add_trusted_assembly @hash = @hash1,
    @description = @clrName1;

DECLARE @clrName2 nvarchar(4000) = 'Microsoft.EnterpriseManagement.Sql.UserDefinedDataType'

DECLARE @hash2 varbinary(64) = 0xFAC2A8ECA2BE6AD46FBB6EDFB53321240F4D98D199A5A28B4EB3BAD412BEC849B99018D9207CEA045D186CF67B8D06507EA33BFBF9A7A132DC0BB1D756F4F491;

EXEC sys.sp_add_trusted_assembly @hash = @hash2,
    @description = @clrName2;

USE OperationsManager;
GO

SELECT * FROM sys.assemblies
SELECT * FROM sys.trusted_assemblies
```

---

---

**TT-SCOM03** - Run as administrator

```PowerShell
cls
```

### # Start services on SCOM server

```PowerShell
Start-Service OMSDK
Start-Service cshost
Start-Service HealthService
```

---

### References

**How to move the Operational database**\
From <[https://docs.microsoft.com/en-us/system-center/scom/manage-move-opsdb?view=sc-om-2019](https://docs.microsoft.com/en-us/system-center/scom/manage-move-opsdb?view=sc-om-2019)>

**Could not load file or assembly 'microsoft.enterprisemanagement.sql.userdefineddatatype' in an AlwaysOn Availability Group configuration.**\
From <[https://social.technet.microsoft.com/Forums/en-US/195c0bd5-115c-4cff-8ae3-4109f59c9b1e/could-not-load-file-or-assembly-microsoftenterprisemanagementsqluserdefineddatatype-in-an?forum=operationsmanagerdeployment](https://social.technet.microsoft.com/Forums/en-US/195c0bd5-115c-4cff-8ae3-4109f59c9b1e/could-not-load-file-or-assembly-microsoftenterprisemanagementsqluserdefineddatatype-in-an?forum=operationsmanagerdeployment)>

```PowerShell
cls
```

## # Update PowerShell help

```PowerShell
Update-Help
```

## Install updates using Windows Update

> **Note**
>
> Repeat until there are no updates available for the computer.

```PowerShell
cls
```

## # Configure monitoring using System Center Operations Manager

### # Install SCOM agent

```PowerShell
$msiPath = "\\TT-FS01\Products\Microsoft\System Center 2019\SCOM\Agents\AMD64" `
    + "\MOMAgent.msi"

msiexec.exe /i $msiPath `
    MANAGEMENT_GROUP=HQ `
    MANAGEMENT_SERVER_DNS=TT-SCOM01C `
    ACTIONS_USE_COMPUTER_ACCOUNT=1
```

### Approve manual agent install in Operations Manager

## Increase CPU count

---

**TT-ADMIN02** - Run as administrator

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05B"
$vmName = "TT-SQL01D"

Stop-VM -ComputerName $vmHost -Name $vmName

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 4

Start-VM -ComputerName $vmHost -Name $vmName
```

---

---

**SQL Server Management Studio** - Database Engine - **TT-SQL01D**

### -- Add TempDB data files (to match CPU count)

```SQL
USE [master]
GO

ALTER DATABASE [tempdb]
ADD FILE
(
  NAME = N'temp3'
  , FILENAME = N'T:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Data\tempdb_mssql_3.ndf'
  , SIZE = 8192KB
  , FILEGROWTH = 65536KB
)
GO

ALTER DATABASE [tempdb]
ADD FILE
(
  NAME = N'temp4'
  , FILENAME = N'T:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Data\tempdb_mssql_4.ndf'
  , SIZE = 8192KB
  , FILEGROWTH = 65536KB
)
GO
```

---

**TODO:**

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

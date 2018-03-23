# TT-SQL02 - Windows Server 2016 Standard Edition

Thursday, March 22, 2018
5:34 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy SQL Server 2017

### Deploy and configure the server infrastructure

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "TT-SQL02"
$vmPath = "E:\NotBackedUp\VMs\$vmName"
$vhdPath = "$vmPath\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 8GB `
    -SwitchName "Embedded Team Switch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 4

Start-VM -ComputerName $vmHost -Name $vmName
```

---

#### Install custom Windows Server 2016 image

- On the **Task Sequence** step, select **Windows Server 2016** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **TT-SQL02**.
  - Click **Next**.
- On the **Applications** step, do not select any applications, and click **Next**.

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

Logoff
```

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Move computer to different OU

```PowerShell
$vmName = "TT-SQL02"

$targetPath = "OU=SQL Servers,OU=Servers" `
    + ",OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com"

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

---

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

robocopy $source $destination /E /XD "Microsoft SDKs"
```

### # Set MaxPatchCacheSize to 0 (recommended)

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

### # Enable performance counters for Server Manager

```PowerShell
$taskName = "\Microsoft\Windows\PLA\Server Manager Performance Monitor"

Enable-ScheduledTask -TaskName $taskName

logman start "Server Manager Performance Monitor"
```

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Set first boot device to hard drive

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "TT-SQL02"

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

#### Configure static IP address

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

##### # Configure static IP address using VMM

```PowerShell
$vmName = "TT-SQL02"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Management VM Network"
$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"
$ipPool = Get-SCStaticIPAddressPool -Name "Management Address Pool"

Stop-SCVirtualMachine $vmName

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
    -VMNetwork $vmNetwork `
    -IPv4AddressType Static `
    -IPv4Addresses $IPAddress.Address

Start-SCVirtualMachine $vmName
```

---

### Configure storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 32 GB       | 4K                   | OSDisk       |
| 1    | D:           | 40 GB       | 64K                  | Data01       |
| 2    | L:           | 10 GB       | 64K                  | Log01        |
| 3    | T:           | 2 GB        | 64K                  | Temp01       |
| 4    | Z:           | 50 GB       | 4K                   | Backup01     |

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Configure storage for the SQL Server

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "TT-SQL02"
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

> **Important**
>
> Wait for the installation to complete.

```PowerShell
cls
```

#### # Install SQL Server Management Studio

```PowerShell
& "\\TT-FS01\Products\Microsoft\SQL Server 2017\SSMS-Setup-ENU-14.0.17230.0.exe"
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

**SQL Server Management Studio - Database Engine**

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
icacls $backupPath /grant 'TT-TFS02$:(OI)(CI)(M)'
```

#### # Grant TFS Data Tier computer account modify access to Backup folder

```PowerShell
icacls $backupPath /grant 'TT-SQL02$:(OI)(CI)(M)'
```

#### # Grant TFS administrators full control to Backups folder

```PowerShell
icacls $backupPath /grant '"TECHTOOLBOX\Team Foundation Server Admins":(OI)(CI)(F)'
```

---

**FOOBAR11**

```PowerShell
cls
```

## # Make virtual machine highly available

### # Migrate VM to shared storage

```PowerShell
$vmName = "TT-SQL02"

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

### Configure backup

#### Add virtual machine to Hyper-V protection group in DPM

## # Install SCOM agent

```PowerShell
$imagePath = '\\ICEMAN\Products\Microsoft\System Center 2012 R2' `
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

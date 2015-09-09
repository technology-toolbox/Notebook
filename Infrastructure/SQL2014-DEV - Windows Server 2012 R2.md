# SQL2014-DEV - Windows Server 2012 R2 Standard

Wednesday, September 9, 2015
8:25 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

---

**FOOBAR8**

## # Create virtual machine

```PowerShell
$vmHost = 'WOLVERINE'
$vmName = 'SQL2014-DEV'

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path D:\NotBackedUp\VMs `
    -MemoryStartupBytes 2GB `
    -SwitchName "Virtual LAN 2 - 192.168.10.x"

Set-VMMemory `
    -ComputerName $vmHost `
    -VMName $vmName `
    -DynamicMemoryEnabled $true `
    -MaximumBytes 4GB

Set-VMProcessor -ComputerName $vmHost -VMName $vmName -Count 4

$vhdPath = "D:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 32GB

Add-VMHardDiskDrive -ComputerName $vmHost -VMName $vmName -Path $vhdPath

$imagePath = '\\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso'

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $imagePath

Start-VM -ComputerName $vmHost -VMName $vmName
```

---

Insert DVD image: [\\\\ICEMAN\\Products\\Microsoft\\MDT-Deploy-x86.iso](\\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso)

## Install custom Windows Server 2012 R2 image

- On the **Task Sequence** step, select **Windows Server 2012 R2** and click **Next**.
- On the **Computer Details** step, in the **Computer name** box, type **SQL2014-DEV** and click **Next**.
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

Get-NetAdapter -InterfaceDescription 'Microsoft Hyper-V Network Adapter' |
    Rename-NetAdapter -NewName 'LAN 1 - 192.168.10.x'
```

## # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName 'Jumbo*'

Set-NetAdapterAdvancedProperty `
    -Name 'LAN 1 - 192.168.10.x' `
    -DisplayName 'Jumbo Packet' `
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

## Configure VM storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 45 GB       | 4K                   | OSDisk       |
| 1    | D:           | 10 GB       | 64K                  | Data01       |
| 2    | L:           | 2 GB        | 64K                  | Log01        |
| 3    | T:           | 1 GB        | 64K                  | Temp01       |
| 4    | Z:           | 10 GB       | 64K                  | Backup01     |

---

**FOOBAR8**

### # Add disks to virtual machine

```PowerShell
$vmHost = 'WOLVERINE'
$vmName = 'SQL2014-DEV'

$vhdPath = "D:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 10GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path $vhdPath `
    -ControllerType SCSI

$vhdPath = "D:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Log01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 2GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path $vhdPath `
    -ControllerType SCSI

$vhdPath = "D:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Temp01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 1GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path $vhdPath `
    -ControllerType SCSI

$vhdPath = "D:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Backup01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 10GB
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

#### # Format Data01 drive

```PowerShell
Get-Disk 1 |
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -UseMaximumSize -DriveLetter D |
    Format-Volume `
        -FileSystem NTFS `
        -AllocationUnitSize 64KB `
        -NewFileSystemLabel "Data01" `
        -Confirm:$false
```

#### # Format Log01 drive

```PowerShell
Get-Disk 2 |
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -UseMaximumSize -DriveLetter L |
    Format-Volume `
        -FileSystem NTFS `
        -AllocationUnitSize 64KB `
        -NewFileSystemLabel "Log01" `
        -Confirm:$false
```

#### # Format Log01 drive

```PowerShell
Get-Disk 3 |
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -UseMaximumSize -DriveLetter T |
    Format-Volume `
        -FileSystem NTFS `
        -AllocationUnitSize 64KB `
        -NewFileSystemLabel "Temp01" `
        -Confirm:$false
```

#### # Format Log01 drive

```PowerShell
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

**WOLVERINE**

#### # Insert the SQL Server 2014 installation media

```PowerShell
$vmName = 'SQL2014-DEV'

$isoPath = '\\ICEMAN\Products\Microsoft\SQL Server 2014\en_sql_server_2014_enterprise_edition_x64_dvd_3932700.iso'

Set-VMDvdDrive -VMName $vmName -Path $isoPath
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
> Do not select **Reporting Services - Native**. If necessary, this will be installed on another server (e.g. TFS App Tier).

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
        , SIZE = 25MB
        , MAXSIZE = 250MB
        , FILEGROWTH = 25MB
    );

DECLARE @sqlStatement NVARCHAR(500);

SELECT @sqlStatement =
    N'ALTER DATABASE [tempdb]'
    + 'ADD FILE'
    + '('
        + 'NAME = N''tempdev2'''
        + ', FILENAME = ''' + @dataPath + '2.mdf'''
        + ', SIZE = 25MB'
        + ', MAXSIZE = 250MB'
        + ', FILEGROWTH = 25MB'
    + ')';

EXEC sp_executesql @sqlStatement;

SELECT @sqlStatement =
    N'ALTER DATABASE [tempdb]'
    + 'ADD FILE'
    + '('
        + 'NAME = N''tempdev3'''
        + ', FILENAME = ''' + @dataPath + '3.mdf'''
        + ', SIZE = 25MB'
        + ', MAXSIZE = 250MB'
        + ', FILEGROWTH = 25MB'
    + ')';

EXEC sp_executesql @sqlStatement;

SELECT @sqlStatement =
    N'ALTER DATABASE [tempdb]'
    + 'ADD FILE'
    + '('
        + 'NAME = N''tempdev4'''
        + ', FILENAME = ''' + @dataPath + '4.mdf'''
        + ', SIZE = 25MB'
        + ', MAXSIZE = 250MB'
        + ', FILEGROWTH = 25MB'
    + ')';

EXEC sp_executesql @sqlStatement;

ALTER DATABASE [tempdb]
    MODIFY FILE (
        NAME = N'templog',
        SIZE = 25MB,
        FILEGROWTH = 10MB
    )
```

## Snapshot VM before configuring SharePoint

---

**FOOBAR8**

### # Checkpoint VM

```PowerShell
$snapshotName = 'Baseline SQL Server 2014 configuration'
$vmHost = 'WOLVERINE'
$vmName = 'SQL2014-DEV'

Stop-VM -ComputerName $vmHost -VMName $vmName

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName $snapshotName

Start-VM -ComputerName $vmHost -VMName $vmName
```

---

# TT-DPM01 - Windows Server 2016

Saturday, January 21, 2017
7:37 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create domain group for DPM administrators

```PowerShell
$dpmAdminsGroup = "DPM Admins"
$orgUnit = "OU=Groups,OU=IT,DC=corp,DC=technologytoolbox,DC=com"

New-ADGroup `
    -Name $dpmAdminsGroup `
    -Description "Complete and unrestricted access to Data Protection Manager" `
    -GroupScope Global `
    -Path $orgUnit
```

### # Add DPM administrators to group

```PowerShell
Add-ADGroupMember -Identity $dpmAdminsGroup -Members jjameson-fabric
```

```PowerShell
cls
```

### # Create service account for DPM SQL Server instance

```PowerShell
$displayName = "Service account for SQL Server instance on TT-DPM01"
$defaultUserName = "s-sql-dpm01"

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

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV02C"
$vmName = "TT-DPM01"
$vmPath = "E:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"
$sysPrepedImage = "\\TT-FS01\VM-Library\VHDs\WS2016-Std.vhdx"

$vhdUncPath = $vhdPath.Replace("E:", "\\TT-HV02C\E$")

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 4GB `
    -SwitchName "Tenant vSwitch"

Copy-Item $sysPrepedImage $vhdUncPath

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 2

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Set password for the local Administrator account

```PowerShell
cls
```

### # Rename local Administrator account

```PowerShell
$adminUser = [ADSI] 'WinNT://./Administrator,User'

$adminUser.Rename('foo')

logoff
```

### Rename server and join domain

#### Login as local administrator account

```PowerShell
cls
```

### # Rename server

```PowerShell
Rename-Computer -NewName TT-DPM01 -Restart
```

> **Note**
>
> Wait for the VM to restart.

#### Login as local administrator account

```PowerShell
cls
```

### # Join server to domain

```PowerShell
Add-Computer -DomainName corp.technologytoolbox.com -Restart
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Move computer to different OU

```PowerShell
$vmName = "TT-DPM01"

$targetPath = ("OU=System Center Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

---

```PowerShell
cls
```

### # Set time zone

```PowerShell
tzutil /s "Mountain Standard Time"
```

### # Copy Toolbox content

```PowerShell
$source = "\\TT-FS01\Public\Toolbox"
$destination = "C:\NotBackedUp\Public\Toolbox"

robocopy $source $destination  /E /XD "Microsoft SDKs"
```

### # Set MaxPatchCacheSize to 0 (recommended)

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

```PowerShell
cls
```

### # Configure networking

#### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "Datacenter 1"
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name "Datacenter 1" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

ping ICEMAN -f -l 8900
```

## Configure storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 32 GB       | 4K                   | OSDisk       |
| 1    | D:           | 3 GB        | 64K                  | Data01       |
| 2    | L:           | 1 GB        | 64K                  | Log01        |
| 3    | T:           | 1 GB        | 64K                  | Temp01       |
| 4    | Z:           | 20 GB       | 4K                   | Backup01     |

```PowerShell
cls
```

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
$vmHost = "TT-HV02C"
$vmName = "TT-DPM01"

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Fixed -SizeBytes 3GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path $vhdPath `
    -ControllerType SCSI

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Log01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Fixed -SizeBytes 1GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path $vhdPath `
    -ControllerType SCSI

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Temp01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Fixed -SizeBytes 1GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path $vhdPath `
    -ControllerType SCSI

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Backup01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 20GB
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

### Add pass-through disks for DPM backups

---

**FOOBAR8**

```PowerShell
cls
```

#### # Add SCSI controller for pass-through disks

```PowerShell
$vmHost = "TT-HV02C"
$vmName = "TT-DPM01"

Stop-VM -ComputerName $vmHost -VMName $vmName

Add-VMScsiController -ComputerName $vmHost -VMName $vmName

Start-VM -ComputerName $vmHost -VMName $vmName
```

#### # Add pass-through disks to SCSI controller

```PowerShell
Get-VMScsiController -ComputerName $vmHost -VMName $vmName -ControllerNumber 1 |
    Add-VMHardDiskDrive -DiskNumber 7

Get-VMScsiController -ComputerName $vmHost -VMName $vmName -ControllerNumber 1 |
    Add-VMHardDiskDrive -DiskNumber 8
```

---

```PowerShell
cls
```

### # Initialize pass-through disks and format volumes

```PowerShell
Get-Disk 5 |
    Initialize-Disk -PartitionStyle GPT -PassThru |
    New-Partition -UseMaximumSize -DriveLetter E |
    Format-Volume `
        -FileSystem ReFS `
        -NewFileSystemLabel "Data02" `
        -Confirm:$false

Get-Disk 6 |
    Initialize-Disk -PartitionStyle GPT -PassThru |
    New-Partition -UseMaximumSize -DriveLetter F |
    Format-Volume `
        -FileSystem ReFS `
        -NewFileSystemLabel "Data03" `
        -Confirm:$false
```

## Prepare for DPM installation

### Reference

**Get DPM installed**\
From <[https://technet.microsoft.com/en-us/system-center-docs/dpm/get-started/get-dpm-installed](https://technet.microsoft.com/en-us/system-center-docs/dpm/get-started/get-dpm-installed)>

```PowerShell
cls
```

### # Add DPM administrators domain group to local Administrators group

```PowerShell
$domain = "TECHTOOLBOX"
$domainGroup = "DPM Admins"

([ADSI]"WinNT://./Administrators,group").Add(
    "WinNT://$domain/$domainGroup,group")
```

### Login as TECHTOOLBOX\\jjameson-fabric

### Install SQL Server 2014

#### Install .NET Framework 3.5 (required for SQL Server features)

---

**FOOBAR8**

```PowerShell
cls
```

##### # Insert the Windows Server 2016 installation media

```PowerShell
$vmHost = "TT-HV02C"
$vmName = "TT-DPM01"

$isoPath = "\\TT-FS01\Products\Microsoft\Windows Server 2016" `
```

    + "\\en_windows_server_2016_x64_dvd_9327751.iso"

```PowerShell
Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $isoPath
```

---

```PowerShell
cls
```

##### # Install .NET Framework 3.5

```PowerShell
Install-WindowsFeature Net-Framework-Core -Source 'X:\Sources\SxS'
```

#### Install SQL Server

---

**FOOBAR8**

```PowerShell
cls
```

##### # Insert the SQL Server 2014 installation media

```PowerShell
$vmHost = "TT-HV02C"
$vmName = "TT-DPM01"

$isoPath = "\\TT-FS01\Products\Microsoft\SQL Server 2014\" `
    + "\en_sql_server_2014_standard_edition_with_service_pack_2_x86_dvd_8961302.iso"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $isoPath
```

---

```PowerShell
cls
```

##### # Launch SQL Server setup

```PowerShell
& X:\Setup.exe
```

On the **Feature Selection** step, select the following checkboxes:

- **Database Engine Services**
- **Reporting Services - Native**
- **Management Tools - Basic**
  - **Management Tools - Complete**

On the **Server Configuration** step:

- For the **SQL Server Agent** service, change the **Startup Type** to **Automatic**.

On the **Database Engine Configuration** step:

- On the **Server Configuration** tab, in the **Specify SQL Server administrators** section, click **Add...** and then add the domain groups for DPM administrators and SQL Server administrators.
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

On the **Reporting Services Configuration** step:

- In the **Reporting Services Native Mode** section, ensure **Install and configure** is selected.
- Click **Next**.

#### -- Configure TempDB

```Console
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

ALTER DATABASE [tempdb]
    MODIFY FILE (
        NAME = N'templog',
        SIZE = 25MB,
        FILEGROWTH = 25MB
    )
```

```Console
cls
```

#### # Configure firewall rule for SQL Server (e.g. to connect to SQL Server Database Engine and DPM reporting from FOOBAR8)

```PowerShell
New-NetFirewallRule `
    -Name "SQL Server Database Engine" `
    -DisplayName "SQL Server Database Engine" `
    -Group 'Technology Toolbox (Custom)' `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 1433 `
    -Action Allow

New-NetFirewallRule `
    -Name "SQL Server Reporting Services" `
    -DisplayName "SQL Server Reporting Services" `
    -Group 'Technology Toolbox (Custom)' `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 80 `
    -Action Allow
```

```PowerShell
cls
```

#### # Fix permissions to avoid "ESENT" errors in event log

```PowerShell
icacls C:\Windows\System32\LogFiles\Sum\Api.chk /grant 'TECHTOOLBOX\s-sql-dpm01:(M)'

icacls C:\Windows\System32\LogFiles\Sum\Api.log /grant 'TECHTOOLBOX\s-sql-dpm01:(M)'

icacls C:\Windows\System32\LogFiles\Sum\SystemIdentity.mdb /grant 'TECHTOOLBOX\s-sql-dpm01:(M)'
```

##### Reference

**Error 1032 messages in the Application log in Windows Server 2012**\
Pasted from <[http://support.microsoft.com/kb/2811566](http://support.microsoft.com/kb/2811566)>

```PowerShell
cls
```

#### # Configure DCOM permissions for SQL Server Integration Services

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\SQL\Configure DCOM Permissions.ps1' -Verbose
```

This will avoid DCOM errors like the following:

Log Name:      System\
Source:        Microsoft-Windows-DistributedCOM\
Date:          1/23/2017 3:12:28 PM\
Event ID:      10016\
Task Category: None\
Level:         Error\
Keywords:      Classic\
User:          TECHTOOLBOX\\s-sql-dpm01\
Computer:      TT-DPM01.corp.technologytoolbox.com\
Description:\
The application-specific permission settings do not grant Local Activation permission for the COM Server application with CLSID\
{806835AE-FD04-4870-A1E8-D65535358293}\
 and APPID\
{EE4171E6-C37E-4D04-AF4C-8617BC7D4914}\
 to the user TECHTOOLBOX\\s-sql-dpm01 SID (S-1-5-21-3914637029-2275272621-3670275343-12160) from address LocalHost (Using LRPC) running in the application container Unavailable SID (Unavailable). This security permission can be modified using the Component Services administrative tool.

> **Note**
>
> Application ID** {EE4171E6-C37E-4D04-AF4C-8617BC7D4914}** corresponds to **Microsoft SQL Server Integration Services 12.0**.

## Install Data Protection Manager

---

**FOOBAR8**

```PowerShell
cls
```

#### # Insert the DPM 2016 installation media

```PowerShell
$vmHost = "TT-HV02C"
$vmName = "TT-DPM01"

$isoPath = "\\TT-FS01\Products\Microsoft\System Center 2016" `
    + "\mu_system_center_2016_data_protection_manager_x64_dvd_9231242.iso"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $isoPath
```

---

```PowerShell
cls
```

### # Extract DPM setup files

```PowerShell
X:\SC2016_SCDPM.EXE
```

Destination location: **C:\\NotBackedUp\\Temp\\System Center 2016 Data Protection Manager**

```PowerShell
cls
```

### # Install DPM 2016

```PowerShell
& "C:\NotBackedUp\Temp\System Center 2016 Data Protection Manager\setup.exe"
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/92/432EC1891FBC165A71F89DA669A38E84051A6F92.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6A/F9CB1F26D7FDAD34FF41957265E7665B19908C6A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/30/6EDC65789D8BC5133BD5296F8E3581BA68F9DA30.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/27/C791554377D1B570AC95910F63DD7E08B42DDF27.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7C/85951ED1CCF7DBD8E8AD098E5980CDF59EED237C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/51/44318252EEC0BDD139496492605488F138A1E251.png)

Restart-Computer

#### # Restart DPM setup

```PowerShell
& "C:\NotBackedUp\Temp\System Center 2016 Data Protection Manager\setup.exe"
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/92/432EC1891FBC165A71F89DA669A38E84051A6F92.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6A/F9CB1F26D7FDAD34FF41957265E7665B19908C6A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/30/6EDC65789D8BC5133BD5296F8E3581BA68F9DA30.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/52/82D1A2292C06DA05635A527276C9FD778A6AAD52.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7C/85951ED1CCF7DBD8E8AD098E5980CDF59EED237C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/82/F87AB1FC29E8655A803FBF6518919D8B66705F82.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/77/1095B7AA77565757B68CDCA921CCEA61BB41AC77.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/04/1824C09BC440B2396CD658B62A082C6D0C844D04.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/26/D686ADF2A9FAE881D6C5F62BE5DDBD2F23F31D26.png)

Click **Use Microsoft Update when I check for updates (recommended)** and then click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/44/6FA03319ECFC8441C331D01CDB0481C7EBCC5B44.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DC/43FCF34E6D6BE1F8E193D1C236AD7F27B0923CDC.png)

```PowerShell
cls
```

### # Copy DPM agent installers to file share

```PowerShell
$source = "C:\NotBackedUp\Temp\System Center 2016 Data Protection Manager\Agents"
$destination = "\\TT-FS01\Products\Microsoft\System Center 2016\Agents"

robocopy $source $destination
```

```PowerShell
cls
```

## # Move log file for DPM database from D: to L

### # Stop the DPM service

```PowerShell
Stop-Service DPM
Stop-Service DpmWriter
```

### -- Detach the DPM database

```Console
USE [master]
GO
EXEC master.dbo.sp_detach_db @dbname = N'DPMDB_TT_DPM01'
GO
```

```Console
cls
```

### # Move the log file for the DPM database

```PowerShell
move "D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\MSDPM2012`$DPMDB_TT_DPM01_log.ldf" "L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data"
```

### -- Attach the DPM database

```Console
USE [master]
GO
CREATE DATABASE [DPMDB_TT_DPM01] ON
( FILENAME = N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\MSDPM2012$DPMDB_TT_DPM01.mdf' ),
( FILENAME = N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\MSDPM2012$DPMDB_TT_DPM01_log.ldf' )
 FOR ATTACH
GO
```

```Console
cls
```

### # Start the DPM services

```PowerShell
Start-Service DpmWriter
Start-Service DPM
```

## Configure database file growth

```Console
ALTER DATABASE [DPMDB_TT_DPM01]
    MODIFY FILE (
        NAME = N'MSDPM2012$DPMDB_TT_DPM01_dat',
        FILEGROWTH = 100MB
    )

ALTER DATABASE [DPMDB_TT_DPM01]
    MODIFY FILE (
        NAME = N'MSDPM2012$DPMDB_TT_DPM01Log_dat',
        FILEGROWTH = 25MB
    )
```

```Console
cls
```

## # Configure SQL Server backups

### # Create folders for backups

```PowerShell
$backupPath = "Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup"

New-Item -ItemType Directory -Path "$backupPath\Differential"
New-Item -ItemType Directory -Path "$backupPath\Full"
New-Item -ItemType Directory -Path "$backupPath\Transaction Log"
```

### Create backup maintenance plans

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
<p><strong>Backup compression</strong></p>
</th>
</thead>
<tr>
<td valign='top'>
<p>Full Backup of All Databases</p>
</td>
<td valign='top'>
<p>Occurs: <strong>Weekly</strong><br />
Recurs every: <strong>1</strong> week on</p>
<ul>
<li><strong>Sunday</strong></li>
</ul>
</td>
<td valign='top'>
<p>Occurs once at: <strong>12:00:00 AM</strong></p>
</td>
<td valign='top'>
<p><strong>Compress backup</strong></p>
</td>
</tr>
<tr>
<td valign='top'>
<p>Differential Backup of All Databases</p>
</td>
<td valign='top'>
<p>Occurs: <strong>Daily</strong><br />
Recurs every: <strong>1</strong> day</p>
</td>
<td valign='top'>
<p>Occurs once at: <strong>11:30:00 PM</strong></p>
</td>
<td valign='top'>
<p><strong>Compress backup</strong></p>
</td>
</tr>
<tr>
<td valign='top'>
<p>Transaction Log Backup of All Databases</p>
</td>
<td valign='top'>
<p>Occurs: <strong>Daily</strong><br />
Recurs every: <strong>1</strong> day</p>
</td>
<td valign='top'>
<p>Occurs every: <strong>30 minutes</strong><br />
Starting at:<strong> 12:25:00 AM</strong><br />
Ending at:<strong> 11:59:59 PM</strong></p>
</td>
<td valign='top'>
<p><strong>Compress backup</strong></p>
</td>
</tr>
</table>

#### Create maintenance plan for full backup of all databases

1. Open **SQL Server Management Studio**.
2. In **Object Explorer**, expand **Management**, right-click **Maintenance Plans**, and click **Maintenance Plan Wizard**.
3. In the **Maintenance Plan Wizard** window:
   1. On the starting page, click **Next**.
   2. On the **Select Plan Properties** page:
      1. In the **Name** box, type **Full Backup of All Databases**.
      2. In the **Schedule** section, click **Change...**
      3. In the **New Job Schedule** window, configure the settings according to the configuration specified above, and click **OK**.
      4. Click **Next**.
   3. On the **Select Maintenance Tasks** page, in the list of maintenance tasks, select **Back Up Database (Full)**, and click **Next**.
   4. On the **Select Maintenance Task Order** page, click **Next**.
   5. On the **Define Back Up Database (Full) Task** page:
      1. On the **General** tab, In the **Database(s) **dropdown, select **All databases**.
      2. On the **Destination** tab, in the Folder box, type **Z:\\Microsoft SQL Server\\MSSQL12.MSSQLSERVER\\MSSQL\\Backup\\Full**.
      3. On the **Options** tab, in the **Set backup compression** dropdown, select **Compress backup**.
      4. Click **Next**.
   6. On the **Select Report Options **page, click **Next**.
   7. On the **Complete the Wizard **page, click **Finish**.

#### Create maintenance plan for differential backup of all databases

1. Open **SQL Server Management Studio**.
2. In **Object Explorer**, expand **Management**, right-click **Maintenance Plans**, and click **Maintenance Plan Wizard**.
3. In the **Maintenance Plan Wizard** window:
   1. On the starting page, click **Next**.
   2. On the **Select Plan Properties** page:
      1. In the **Name** box, type **Differential Backup of All Databases**.
      2. In the **Schedule** section, click **Change...**
      3. In the **New Job Schedule** window, configure the settings according to the configuration specified above, and click **OK**.
      4. Click **Next**.
   3. On the **Select Maintenance Tasks** page, in the list of maintenance tasks, select **Back Up Database (Differential)**, and click **Next**.
   4. On the **Select Maintenance Task Order** page, click **Next**.
   5. On the **Define Back Up Database (Differential) Task** page:
      1. On the **General** tab, In the **Database(s) **dropdown, select **All databases**.
      2. On the **Destination** tab, in the Folder box, type **Z:\\Microsoft SQL Server\\MSSQL12.MSSQLSERVER\\MSSQL\\Backup\\Differential**.
      3. On the **Options** tab, in the **Set backup compression** dropdown, select **Compress backup**.
      4. Click **Next**.
   6. On the **Select Report Options **page, click **Next**.
   7. On the **Complete the Wizard **page, click **Finish**.

#### Create maintenance plan for transaction log backup of all databases

1. Open **SQL Server Management Studio**.
2. In **Object Explorer**, expand **Management**, right-click **Maintenance Plans**, and click **Maintenance Plan Wizard**.
3. In the **Maintenance Plan Wizard** window:
   1. On the starting page, click **Next**.
   2. On the **Select Plan Properties** page:
      1. In the **Name** box, type **Transaction Log Backup of All Databases**.
      2. In the **Schedule** section, click **Change...**
      3. In the **New Job Schedule** window, configure the settings according to the configuration specified above, and click **OK**.
      4. Click **Next**.
   3. On the **Select Maintenance Tasks** page, in the list of maintenance tasks, select **Back Up Database (Transaction Log)**, and click **Next**.
   4. On the **Select Maintenance Task Order** page, click **Next**.
   5. On the **Define Back Up Database (Full) Task** page:
      1. On the **General** tab, In the **Database(s) **dropdown, select **All databases**.
      2. On the **Destination** tab, in the Folder box, type **Z:\\Microsoft SQL Server\\MSSQL12.MSSQLSERVER\\MSSQL\\Backup\\Transaction Log**.
      3. On the **Options** tab, in the **Set backup compression** dropdown, select **Compress backup**.
      4. Click **Next**.
   6. On the **Select Report Options **page, click **Next**.
   7. On the **Complete the Wizard **page, click **Finish**.

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
<p>Occurs once at: <strong>11:55:00 PM</strong></p>
</td>
<td valign='top'>
<p><strong>First Task (Remove Full and Differential Backups)</strong></p>
<p><strong>Delete files of the following type:</strong></p>
<ul>
<li><strong>Backup files</strong></li>
</ul>
<p><strong>File location:</strong></p>
<ul>
<li><strong>Search folder and delete files based on an extension</strong>
<ul>
<li><strong>Folder: Z:\\Microsoft SQL Server\\MSSQL12.MSSQLSERVER\\MSSQL\\Backup\\</strong></li>
<li><strong>File Extension: bak</strong></li>
<li><strong>Include first-level subfolders: Yes (checked)</strong></li>
</ul>
</li>
</ul>
<p><strong>File age:</strong></p>
<ul>
<li><strong>Delete files based on the age of the file at task run time</strong></li>
<li><strong>Delete files older than the following: 2 Week(s)</strong></li>
</ul>
<p><strong>Second Task (Remove Transaction Log Backups)</strong></p>
<p><strong>Delete files of the following type:</strong></p>
<ul>
<li><strong>Backup files</strong></li>
</ul>
<p><strong>File location:</strong></p>
<ul>
<li><strong>Search folder and delete files based on an extension</strong>
<ul>
<li><strong>Folder: Z:\\Microsoft SQL Server\\MSSQL12.MSSQLSERVER\\MSSQL\\Backup\\Transaction Log\\</strong></li>
<li><strong>File Extension: trn</strong></li>
<li><strong>Include first-level subfolders: No (unchecked)</strong></li>
</ul>
</li>
</ul>
<p><strong>File age:</strong></p>
<ul>
<li><strong>Delete files based on the age of the file at task run time</strong></li>
<li><strong>Delete files older than the following: 2 Week(s)</strong></li>
</ul>
<p><strong>Third Task (History Cleanup Task)</strong></p>
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

#### Create maintenance plan to remove old Full and Differential backups

1. Open **SQL Server Management Studio**.
2. In **Object Explorer**, expand **Management**, right-click **Maintenance Plans**, and click **Maintenance Plan Wizard**.
3. In the **Maintenance Plan Wizard** window:
   1. On the starting page, click **Next**.
   2. On the **Select Plan Properties** page:
      1. In the **Name** box, type **Remove Old Database Backups**.
      2. In the **Schedule** section, click **Change...**
      3. In the **New Job Schedule** window, configure the settings according to the configuration specified above, and click **OK**.
      4. Click **Next**.
   3. On the **Select Maintenance Tasks** page, in the list of maintenance tasks, select **Maintenance Cleanup Task**, and click **Next**.
   4. On the **Select Maintenance Task Order** page, click **Next**.
   5. On the **Define Maintenance Cleanup Task** page:
      1. In the **Folder** box, type **Z:\\Microsoft SQL Server\\MSSQL12.MSSQLSERVER\\MSSQL\\Backup\\**.
      2. In the **File extension **box, type **bak**.
      3. Select the **Include first-level subfolders** checkbox.
      4. In the **File age** section, configure the settings to delete files older than **2 Week(s)**.
      5. Click **Next**.
   6. On the **Select Report Options **page, click **Next**.
   7. On the **Complete the Wizard **page, click **Finish**.

#### Modify maintenance plan to remove old Transaction Log backups

1. Open **SQL Server Management Studio**.
2. In **Object Explorer**, expand **Management**, expand **Maintenance Plans**, right-click **Remove Old Database Backups** and click **Modify**.
3. In the Maintenance Plan designer:
   1. Right-click **Maintenance Cleanup Task** and click **Properties**.
   2. In the **Properties** window:
      1. If necessary, expand the **Identification** section.
      2. In the **Name** box, type **Remove Full and Differential Backups**.
   3. Use the **Toolbox** to add a new **Maintenance Cleanup Task**.
   4. Right-click the new task and click **Properties**.
   5. In the **Properties** window:
      1. If necessary, expand the **Identification** section.
      2. In the **Name** box, type **Remove Transaction Log Backups**.
   6. Right-click the **Remove Transaction Log Backups** task and click **Edit...**
   7. In the **Maintenance Cleanup Task** window:
      1. In the **Folder** box, type **Z:\\Microsoft SQL Server\\MSSQL12.MSSQLSERVER\\MSSQL\\Backup\\Transaction Log\\**.
      2. In the **File extension **box, type **trn**.
      3. In the **File age** section, configure the settings to delete files older than **2 Week(s)**.
      4. Click **OK**.
4. On the **File** menu, click **Save Selected Items**.

#### Modify maintenance plan to remove historical data

1. Open **SQL Server Management Studio**.
2. In **Object Explorer**, expand **Management**, expand **Maintenance Plans**, right-click **Remove Old Database Backups** and click **Modify**.
3. In the Maintenance Plan designer:
   1. Use the **Toolbox** to add a new **History Cleanup Task**.
   2. Right-click **History Cleanup Task** and click **Edit...**
   3. In the **History Cleanup Task** window:
      1. Ensure the **Backup and restore history** checkbox is selected.
      2. Ensure the **SQL Server Agent job history** checkbox is selected.
      3. Ensure the **Maintenance plan history** checkbox is selected.
      4. Ensure the default timespan -- **4 Week(s)** -- is specified.
      5. Click **OK**.
4. On the **File** menu, click **Save Selected Items**.

### Execute maintenance plan to backup all databases

Right-click **Full Backup of All Databases** and click **Execute**.

## Configure DPM

### Enable DPM Administration Console to connect remotely (e.g. from FOOBAR11)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F6/E2E6646BEB92A9C477BED5E3CAF347F06F21A5F6.png)

#### # Configure firewall rule for SQL Server Database Engine

```PowerShell
New-NetFirewallRule `
    -Name "SQL Server Database Engine" `
    -DisplayName "SQL Server Database Engine" `
    -Group 'Technology Toolbox (Custom)' `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 1433 `
    -Action Allow
```

### Configure SMTP server for DPM

#### Configure spam filter in Office 365

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F5/09FEF23706EA73B094C68CD75E08DEDC2FDCEFF5.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/24/9957ADC6F7B4F58B9BE77304D1EA2F084F16A424.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/31/5ED7F2CE8F519924C92C61C0E3E17F6613ADEC31.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/69/7267C9530745145BE7CAF41FAF09A40102F55D69.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F7/DA5991FA2272153F9F786460CECDFD202E6C02F7.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0A/81CEF0E05B62EE1B9540BB58BB24FB837527020A.png)

#### Configure SMTP server in DPM

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9A/16A95681615397E1BCC3DE4515BAFA174F818F9A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/55/BB6153E0286B508C3856C91808E1F406CC290F55.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/93/D06CE81485A2E900457EB1950C5A913EEDBA8A93.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CB/E6CE454D49FFC1BB5E2C5509D3F72BD3AB57E1CB.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2E/9AFAE7B9770AD9B260ED4E385115DD6AC63E682E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/23/8676604790EC531B9E509098FC6926D352A67E23.png)

## Add disks to the storage pool

**To add disks to the storage pool**

1. In DPM Administrator Console, click **Management**, and then click the **Disk Storage**.
2. Click **Add** on the tool ribbon.
The **Add Disks to Storage Pool** dialog box appears. The **Available disks** section lists the disks that you can add to the storage pool.
3. Select one or more disks, click **Add**, and then click **OK**.

Pasted from <[http://technet.microsoft.com/en-us/library/hh758075.aspx](http://technet.microsoft.com/en-us/library/hh758075.aspx)>

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6B/AE05684B5544D5EB4823E3C0F0073475D8CC636B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2D/39C115FF3A1A089CC814336165ED8DA106E8EE2D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CC/A71368BA6B705BE213D2F3D2E99B6617763CBBCC.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/08/352F9FF4B71D11EF453E4A662FE867E1E978EA08.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/79/77E6DD12BAEA1C4B7B646B9971B67CACBF737979.png)

## Upgrade DPM agents to DPM 2016

## Create protection group for domain controllers

Protection group name: **Domain Controllers**\
Retention range: **5 days**\
Application recovery points:

- Express Full Backup: **8:00 PM Everyday**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/36/9C0C8B0D8D9705FD8AE4397C369B4DF556BD8B36.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0B/C22FA29FF04593DB64533E6D8CFBDCFDAD618E0B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/62/DB1CB0B5F336A11FA8833BD545DF9D01267BB762.png)

Ensure **Servers** is selected and then click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/79/869ABED58761D11A2D100669763146BF37923979.png)

Expand **XAVIER1**, then expand **System Protection**, and then select **System State (includes Active Directory)**.

Repeat the previous step for **XAVIER2**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A8/7764618414276B8092704CFB1BC07CBE53A9D9A8.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1D/332E3C26D952C632368F91F552E60AB5275C591D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/63/AA7017D6A2204F620A5C1E432AFE5046420B5763.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F3/02B08A4189FC4E49439A08087F734EDCE50E00F3.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D8/04CBD78FDEA2C8CF2E4DEA7E438C25C90F22EFD8.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/05/F0FD6A216EBD58913D1D6DD29C04BA1C58525905.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BF/465917A3A49BF499D73183BEE6225881CE991EBF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F6/B1757B5A95B3F193195903333B3E3CE8C3CBA5F6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/45/FBA2A7BF4496E96D8D030350691B58A878E82145.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/95/D6C8FA6D13EFD3F657DC292D9EC2F9E587709395.png)

## Create protection group for SQL Server databases (TEST)

Protection group name: **SQL Server Databases (TEST)**\
Retention range: **10 days**\
Synchronization frequency: **Every 4 hours**\
Application recovery points:

- Express Full Backup: **7:00 PM Everyday**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/97/7F023F96DC64041835D5F5CD8938A651DA1E8B97.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0B/C22FA29FF04593DB64533E6D8CFBDCFDAD618E0B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/62/DB1CB0B5F336A11FA8833BD545DF9D01267BB762.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/36/66BFF324B75BF3086C00D5DBA165FD71E042E936.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/68/B49F87E99D0140D1162D9833BDA12C5795016F68.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DF/29F0A43E47D472812BB17639EE37903B16DA40DF.png)

For **Retention range**, specify **10 days**.

For **Synchronization frequency**, specify **Every 4 hour(s)**.

In the **Application recovery points** section, click **Modify...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/41/5CE4741107AEC9C91CCA39B35B8F0AAEBB65AB41.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0A/03C01D2196416D9E79A974E147ECF777C06A220A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/50/3F7FE548DA878306A10405EB6EA5DA393DAC6150.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/45/5FF1FB60E40A5804240C95EA3C332BB28E4BFE45.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BF/465917A3A49BF499D73183BEE6225881CE991EBF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/89/D609F34EF336604CD869647462BDCAFACCD8AC89.png)

### Add "Local System" account to SQL Server sysadmin role

On the SQL Server (HAVOK-TEST), open SQL Server Management Studio and execute the following:

```SQL
ALTER SERVER ROLE [sysadmin] ADD MEMBER [NT AUTHORITY\SYSTEM]
GO
```

#### Reference

**Protection agent jobs may fail for SQL Server 2012 databases**\
Pasted from <[http://technet.microsoft.com/en-us/library/dn281948.aspx](http://technet.microsoft.com/en-us/library/dn281948.aspx)>

## Create protection group for SQL Server databases

Protection group name: **SQL Server Databases**\
Retention range: **10 days**\
Synchronization frequency: **Every 15 minutes**\
Application recovery points:

- Express Full Backup: **6:00 PM Everyday**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A3/EE55A972C7E5543C3244EFEF874536A8FEDE7BA3.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0B/C22FA29FF04593DB64533E6D8CFBDCFDAD618E0B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/62/DB1CB0B5F336A11FA8833BD545DF9D01267BB762.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/06/E2479C40C060844D7EBC217E51E7F01CBED9E706.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/23/75299A5EA94F39C78FF917D54B36E4BD9FBEF923.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A1/0B5CF3330797DBA3AC5C144B5A71DEB4A719A6A1.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8D/EC3D53CE76EDB1C5F05EEF3C33EC20C467F4498D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/22/1D7C4A9BC81D72698A87659325F08A1E058E6222.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BF/465917A3A49BF499D73183BEE6225881CE991EBF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/12/4BA70FCF9F9FE098BED9F547000B9A935A8D6112.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A9/0061E9550C33C86432F6A42F3770698DFDD2EBA9.png)

## Create protection group for critical files

Protection group name: **Critical Files**\
Retention range: **10 days**\
Synchronization frequency: **Just before a recovery point**\
File recovery points:

- Recovery points for files: **7:00 AM, 12:00 PM, 5:00 PM Everyday**

## Create protection group for Hyper-V

Protection group name: **Hyper-V**\
Retention range: **5 days**\
Application recovery points:

- Express Full Backup: **11:00 PM Everyday**

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

## Set up protection for live migration

### Reference

**Set up protection for live migration**\
From <[https://technet.microsoft.com/en-us/library/jj656643.aspx](https://technet.microsoft.com/en-us/library/jj656643.aspx)>

```PowerShell
cls
```

### # Install VMM console on DPM server

---

**TT-VMM01 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Insert the VMM 2016 installation media

```PowerShell
$isoName = "mu_system_center_2016_virtual_machine_manager_x64_dvd_9368503.iso"
$vmName = "TT-DPM01"

$iso = Get-SCISO | where { $_.Name -eq $isoName }

$dvdDrive = Get-SCVirtualDVDDrive -VM $vmName

Set-SCVirtualDVDDrive -VirtualDVDDrive $dvdDrive -ISO $iso -Link
```

---

```PowerShell
cls
```

#### # Extract VMM setup files

```PowerShell
X:\SC2016_SCVMM.EXE
```

Destination location: **C:\\NotBackedUp\\Temp\\System Center 2016 Virtual Machine Manager**

---

**TT-VMM01 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Remove the VMM 2016 installation media

```PowerShell
$vmName = "TT-DPM01"

$dvdDrive = Get-SCVirtualDVDDrive -VM $vmName

Set-SCVirtualDVDDrive -VirtualDVDDrive $dvdDrive -NoMedia
```

---

```PowerShell
cls
```

#### # Install VMM console

**To install the VMM console:**

1. To start the Virtual Machine Manager Setup Wizard, on your installation media, right-click **setup.exe**, and then click **Run as administrator**.
2. On the main setup page, click **Install**.
3. On the **Select features to install** page, select the **VMM console** check box, and click **Next**.
4. On the **Please read this notice** page, review the license agreement, select the **I agree with the terms of this notice** check box, and then click **Next**.
5. On the **Diagnostic and Usage Data** page, review the data collection and usage policy and then click **Next**.
6. On the **Installation location** page, ensure the default path is specified (**C:\\Program Files\\Microsoft System Center 2016\\Virtual Machine Manager**), and then click **Next**.
7. On the **Port configuration** page, ensure the default port number (**8100**) is specified for communication with the VMM management server, and click **Next**.
8. On the **Installation summary** page, review your selections and do one of the following:
9. On the **Setup completed... **page:
   1. Review any warnings that occurred.
   2. Clear the **Check for the latest Virtual Machine Manager updates** checkbox.
   3. Clear the **Open the VMM console when this wizard closes** checkbox.
   4. Click **Close** to finish the installation.

```PowerShell
    & "C:\NotBackedUp\Temp\System Center 2016 Virtual Machine Manager\setup.exe"
```

- Click **Previous** to change any selections.
- Click **Install** to install the VMM console.

After you click **Install**, the **Installing features** page appears and installation progress is displayed.

> **Important**
>
> During Setup, VMM enables the following firewall rules, which remain in effect even if you later uninstall VMM:
>
> - File Server Remote Management
> - Windows Standards-Based Storage Management firewall rules

```PowerShell
cls
```

#### # Remove temporary VMM setup files

```PowerShell
Remove-Item "C:\NotBackedUp\Temp\System Center 2016 Virtual Machine Manager" -Recurse
```

### Update VMM using Windows Update

**Update Rollup 2.1 for Microsoft System Center 2016 - Virtual Machine Manager Administrator Console (KB4011492)**

### Add DPM machine account as Read-Only Administrator in VMM

**How to Create a Read-Only Administrator User Role in VMM**\
From <[https://technet.microsoft.com/en-us/library/hh356036.aspx](https://technet.microsoft.com/en-us/library/hh356036.aspx)>

---

**TT-VMM01 - Run as TECHTOOLBOX\\jjameson-admin**

1. Open **Virtual Machine Manager**.
2. In the **Settings** workspace, on the **Home** tab in the **Create** group, click **Create User Role**.
3. In the **Create User Role Wizard**:
   1. On the **Name and description** page, in the **Name** box, type **DPM Servers** and click **Next**.
   2. On the **Profile** page, select **Read-Only Administrator** and then click **Next**.
   3. On the **Members** page, click **Add** to add **TECHTOOLBOX\\TT-DPM01\$** to the user role with the **Select Users, Computers, or Groups** dialog box. After you have added the members, click **Next**.
   4. On the **Scope** page, select **All Hosts** and click **Next**.
   5. On the **Library servers** page, click **Next**.
   6. On the **Run As accounts** page, click **Next**.
   7. On the **Summary** page, review the settings you have entered and then click **Finish** to create the Read-Only Administrator user role.

---

```PowerShell
cls
```

### # Connect DPM server to VMM server

```PowerShell
Set-DPMGlobalProperty -DPMServerName TT-DPM01 -KnownVMMServers TT-VMM01
```

```PowerShell
cls
```

## # Configure monitoring using System Center Operations Manager

### # Install SCOM agent

```PowerShell
$msiPath = "\\TT-FS01\Products\Microsoft\System Center 2016\Agents\SCOM\AMD64" `
    + "\MOMAgent.msi"

msiexec.exe /i $msiPath `
    MANAGEMENT_GROUP=HQ `
    MANAGEMENT_SERVER_DNS=TT-SCOM01 `
    ACTIONS_USE_COMPUTER_ACCOUNT=1
```

### Approve manual agent install in Operations Manager

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

## Issue - Server running out of memory

Log Name:      Application\
Source:        MSSQLSERVER\
Event ID:      8645\
Task Category: Server\
Level:         Error\
Keywords:      Classic\
User:          SYSTEM\
Computer:      TT-DPM01.corp.technologytoolbox.com\
Description:\
A timeout occurred while waiting for memory resources to execute the query in resource pool 'internal' (1). Rerun the query.

### Enable Dynamic Memory and set Maximum RAM to 6 GB

> **Note**
>
> The problem still occurs, despite increasing the maximum memory for the VM.

---

**SQL Server Management Studio**

### -- Constrain maximum memory for SQL Server

```SQL
EXEC sys.sp_configure N'show advanced options', N'1'
RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'max server memory (MB)', N'2048'
GO
EXEC sys.sp_configure N'show advanced options', N'0'
RECONFIGURE WITH OVERRIDE
GO
```

---

```PowerShell
Restart-Computer
```

> **Note**
>
> The problem still occurs, despite constraining the maximum memory for SQL Server.

### Troubleshooting

![(screenshot)](https://assets.technologytoolbox.com/screenshots/42/445C9D09C8B29D70B1ED957F1DA347D9CBBD3E42.png)

### Increase startup RAM and minimum RAM from 4 GB to 5 GB

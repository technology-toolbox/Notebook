# EXT-SQL03 - Windows Server 2012 R2 Standard

Monday, March 26, 2018
1:50 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

Install SecuritasConnect v4.0

## Deploy and configure server infrastructure

### Copy Windows Server installation files to file share

(skipped)

### Install Windows Server 2012 R2

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "EXT-SQL03"
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

#### Install custom Windows Server 2012 R2 image

- On the **Task Sequence** step, select **Windows Server 2012 R2** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **EXT-SQL03**.
  - Select **Join a workgroup**.
  - In the **Workgroup **box, type **WORKGROUP**.
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

robocopy $source $destination /E /XD "Microsoft SDKs" /MIR
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
$vmName = "EXT-SQL03"

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
$interfaceAlias = "Extranet-20"
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
$vmName = "EXT-SQL03"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Extranet-20 VM Network"
$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"
$ipPool = Get-SCStaticIPAddressPool -Name "Extranet-20 Address Pool"

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
| 1    | D:           | 235 GB      | 64K                  | Data01       |
| 2    | L:           | 25 GB       | 64K                  | Log01        |
| 3    | T:           | 4 GB        | 64K                  | Temp01       |
| 4    | Z:           | 450 GB      | 4K                   | Backup01     |

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Configure storage for the SQL Server

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "EXT-SQL03"
$vmPath = "E:\NotBackedUp\VMs\$vmName"
```

##### # Add "Data01" VHD

```PowerShell
$vhdPath = $vmPath + "\Virtual Hard Disks\$vmName" + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 235GB
Add-VMHardDiskDrive `
  -ComputerName $vmHost `
  -VMName $vmName `
  -Path $vhdPath `
  -ControllerType SCSI
```

##### # Add "Log01" VHD

```PowerShell
$vhdPath = $vmPath + "\Virtual Hard Disks\$vmName" + "_Log01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 25GB
Add-VMHardDiskDrive `
  -ComputerName $vmHost `
  -VMName $vmName `
  -Path $vhdPath `
  -ControllerType SCSI
```

##### # Add "Temp01" VHD

```PowerShell
$vhdPath = $vmPath + "\Virtual Hard Disks\$vmName" + "_Temp01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 4GB
Add-VMHardDiskDrive `
  -ComputerName $vmHost `
  -VMName $vmName `
  -Path $vhdPath `
  -ControllerType SCSI
```

##### # Add "Backup01" VHD

```PowerShell
$vhdPath = $vmPath + "\Virtual Hard Disks\$vmName" + "_Backup01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 450GB
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

#### # Initialize disks and format volumes

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

### # Join member server to domain

```PowerShell
Add-Computer `
    -DomainName extranet.technologytoolbox.com `
    -Credential (Get-Credential EXTRANET\jjameson-admin) `
    -Restart
```

---

**EXT-DC08 - Run as EXTRANET\\jjameson-admin**

```PowerShell
cls
```

##### # Move computer to different OU

```PowerShell
$computerName = "EXT-SQL03"

$targetPath = ("OU=SQL Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=extranet,DC=technologytoolbox,DC=com")

Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath
```

##### # Configure Windows Update

###### # Add machine to security group for Windows Update schedule

```PowerShell
$domainGroupName = "Windows Update - Slot 3"

Add-ADGroupMember -Identity $domainGroupName -Members ($computerName + '$')
```

---

```PowerShell
cls
```

### # Install and configure SQL Server 2014

#### # Prepare server for SQL Server installation

##### # Add SQL Server administrators domain group to local Administrators group

```PowerShell
$domain = "EXTRANET"
$groupName = "SQL Server Admins"

([ADSI]"WinNT://./Administrators,group").Add(
    "WinNT://$domain/$groupName,group")
```

---

**EXT-DC08 - Run as EXTRANET\\jjameson-admin**

```PowerShell
cls
```

##### # Enable setup account for SQL Server

```PowerShell
Enable-ADAccount -Identity setup-sql
```

---

> **Important**
>
> Login as **EXTRANET\\setup-sql** to install SQL Server.

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Mount SQL Server 2014 installation media

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "EXT-SQL03"
$isoName = "en_sql_server_2014_developer_edition_with_service_pack_2_x64_dvd_8967821.iso"
```

##### # Add virtual DVD drive

```PowerShell
Add-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName
```

##### # Refresh virtual machine in VMM

```PowerShell
Read-SCVirtualMachine -VM $vmName
```

##### # Mount installation media in virtual DVD drive

```PowerShell
$iso = Get-SCISO | where { $_.Name -eq $isoName }

Get-SCVirtualDVDDrive -VM $vmName |
    Set-SCVirtualDVDDrive -ISO $iso -Link
```

---

```PowerShell
& E:\setup.exe
```

> **Important**
>
> Wait for the installation to complete and restart the computer (if necessary).

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Dismount SQL Server 2014 installation media

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "EXT-SQL03"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

---

```PowerShell
cls
```

### # Configure permissions on \\Windows\\System32\\LogFiles\\Sum files

```PowerShell
icacls C:\Windows\System32\LogFiles\Sum\Api.chk `
    /grant "NT Service\MSSQLSERVER:(M)"

icacls C:\Windows\System32\LogFiles\Sum\Api.log `
    /grant "NT Service\MSSQLSERVER:(M)"

icacls C:\Windows\System32\LogFiles\Sum\SystemIdentity.mdb `
    /grant "NT Service\MSSQLSERVER:(M)"
```

---

**SQL Server Management Studio**

### -- Configure TempDB data and log files

```SQL
ALTER DATABASE [tempdb]
  MODIFY FILE
  (
    NAME = N'tempdev'
    , SIZE = 512MB
    , MAXSIZE = 768MB
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
      + ', SIZE = 512MB'
      + ', MAXSIZE = 768MB'
      + ', FILEGROWTH = 128MB'
    + ')';

EXEC sp_executesql @sqlStatement;

SELECT @sqlStatement =
  N'ALTER DATABASE [tempdb]'
    + 'ADD FILE'
    + '('
      + 'NAME = N''tempdev3'''
      + ', FILENAME = ''' + @dataPath + '3.mdf'''
      + ', SIZE = 512MB'
      + ', MAXSIZE = 768MB'
      + ', FILEGROWTH = 128MB'
    + ')';

EXEC sp_executesql @sqlStatement;

SELECT @sqlStatement =
  N'ALTER DATABASE [tempdb]'
    + 'ADD FILE'
    + '('
      + 'NAME = N''tempdev4'''
      + ', FILENAME = ''' + @dataPath + '4.mdf'''
      + ', SIZE = 512MB'
      + ', MAXSIZE = 768MB'
      + ', FILEGROWTH = 128MB'
    + ')';

EXEC sp_executesql @sqlStatement;
ALTER DATABASE [tempdb]
  MODIFY FILE (
    NAME = N'templog',
    SIZE = 50MB,
    FILEGROWTH = 10MB
  )

GO
```

### -- Configure "Max Degree of Parallelism" for SharePoint

```SQL
EXEC sys.sp_configure N'show advanced options', N'1'
RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'max degree of parallelism', N'1'
RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'show advanced options', N'0'
RECONFIGURE WITH OVERRIDE
GO
```

---

```PowerShell
cls
```

### # Configure firewall rule for SQL Server

```PowerShell
New-NetFirewallRule `
    -Name 'SQL Server Database Engine' `
    -DisplayName 'SQL Server Database Engine' `
    -Description 'Allows remote access to SQL Server Database Engine' `
    -Group 'SQL Server' `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 1433 `
    -Profile Domain `
    -Action Allow
```

### # Enable TCP/IP protocol for SharePoint 2013 connections (SQL Server 2008 drivers)

```PowerShell
[Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")
[Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlWmiManagement")

$wmi = New-Object ('Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer').

$uri = "ManagedComputer[@Name='" + $env:COMPUTERNAME + "']" `
    + "/ServerInstance[@Name='MSSQLSERVER']" `
    + "/ServerProtocol[@Name='Tcp']"

$tcpProtocol = $wmi.GetSmoObject($uri)
$tcpProtocol.IsEnabled = $true
$tcpProtocol.Alter()

Stop-Service SQLSERVERAGENT

Restart-Service MSSQLSERVER

Start-Sleep -Seconds 15

Start-Service SQLSERVERAGENT
```

```PowerShell
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
<p>Occurs every: <strong>5 minutes</strong><br />
Starting at:<strong> 12:05:00 AM</strong><br />
Ending at:<strong> 11:59:59 PM</strong></p>
</td>
<td valign='top'>
<p><strong>Do not compress backup</strong></p>
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
      3. On the **Options** tab, in the **Set backup compression** dropdown, select **Do not compress backup**.
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
<li><strong>Delete files older than the following: 2  Week(s)</strong></li>
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
<li><strong>Delete files older than the following: 2  Week(s)</strong></li>
</ul>
<p><strong>Third Task (History Cleanup Task)</strong></p>
<p><strong>Historical data to delete:</strong></p>
<ul>
<li><strong>Backup and restore history</strong></li>
<li><strong>SQL Server Agent job history</strong></li>
<li><strong>Maintenance plan history</strong></li>
</ul>
<p><strong>Remove historical data older than 4 Week(s).</strong></p>
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
      4. In the **File age** section, configure the settings to delete files older than **3 Week(s)**.
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
      3. In the **File age** section, configure the settings to delete files older than **3 Week(s)**.
      4. Click **OK**.
   8. Use the **Toolbox** to add a new **History Cleanup Task**.
   9. Right-click the new task and click **Edit...**
   10. In the **History Cleanup Task **window, click **OK**.
4. On the **File** menu, click **Save Selected Items**.

### Execute maintenance plan - Full Backup of All Databases

## Configure DCOM permissions for SQL Server

### Issue

Source: DCOM\
Event ID: 10016\
Event Category: 0\
User: NT SERVICE\\SQLSERVERAGENT\
Computer: EXT-SQL02.extranet.technologytoolbox.com\
Event Description: The application-specific permission settings do not grant Local Activation permission for the COM Server application with CLSID\
{806835AE-FD04-4870-A1E8-D65535358293}\
and APPID\
{EE4171E6-C37E-4D04-AF4C-8617BC7D4914}\
to the user NT SERVICE\\SQLSERVERAGENT SID (S-1-5-80-344959196-2060754871-2302487193-2804545603-1466107430) from address LocalHost (Using LRPC) running in the application container Unavailable SID (Unavailable). This security permission can be modified using the Component Services administrative tool.

> **Note**
>
> **EE4171E6-C37E-4D04-AF4C-8617BC7D4914** is the ID for **Microsoft SQL Server Integration Services 12.0**.

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

---

**EXT-DC08 - Run as EXTRANET\\jjameson-admin**

```PowerShell
cls
```

### # Disable setup account for SQL Server

```PowerShell
Disable-ADAccount -Identity setup-sql
```

---

### Configure backup

#### Add virtual machine to Hyper-V protection group in DPM

```PowerShell
cls
```

## # Configure monitoring

### # Create certificate for Operations Manager

#### # Create request for Operations Manager certificate

```PowerShell
& "C:\NotBackedUp\Public\Toolbox\Operations Manager\Scripts\New-OperationsManagerCertificateRequest.ps1"
```

#### # Submit certificate request to the Certification Authority

##### # Add Active Directory Certificate Services site to the "Trusted sites" zone and browse to the site

```PowerShell
[Uri] $adcsUrl = [Uri] "https://cipher01.corp.technologytoolbox.com"

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-InternetSecurityZoneMapping.ps1 `
    -Zone LocalIntranet `
    -Patterns $adcsUrl.AbsoluteUri

Start-Process $adcsUrl.AbsoluteUri
```

##### # Submit the certificate request to an enterprise CA

> **Note**
>
> Copy the certificate request to the clipboard.

**To submit the certificate request to an enterprise CA:**

1. On the computer hosting the Operations Manager feature for which you are requesting a certificate, start Internet Explorer, and browse to Active Directory Certificate Services site ([https://cipher01.corp.technologytoolbox.com/](https://cipher01.corp.technologytoolbox.com/)).
2. On the **Welcome** page, click **Request a certificate**.
3. On the **Advanced Certificate Request** page, click **Submit a certificate request by using a base-64-encoded CMC or PKCS #10 file, or submit a renewal request by using a base-64-encoded PKCS #7 file.**
4. On the **Submit a Certificate Request or Renewal Request** page, in the **Saved Request** text box, paste the contents of the certificate request generated in the previous procedure.
5. In the **Certificate Template** section, select the Operations Manager certificate template (**Technology Toolbox Operations Manager**), and then click **Submit**. When prompted to allow the digital certificate operation to be performed, click **Yes**.
6. On the **Certificate Issued** page, click **Download certificate** and save the certificate.

```PowerShell
cls
```

#### # Import the certificate into the certificate store

```PowerShell
$certFile = "C:\Users\jjameson-admin\Downloads\certnew.cer"

CertReq.exe -Accept $certFile
```

```PowerShell
cls
```

#### # Delete the certificate file

```PowerShell
Remove-Item $certFile
```

---

**FOOBAR11**

```PowerShell
cls
```

### # Copy SCOM agent installation files

```PowerShell
$computerName = "EXT-SQL03.extranet.technologytoolbox.com"

net use "\\$computerName\IPC`$" /USER:EXTRANET\jjameson-admin
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$source = "\\TT-FS01\Products\Microsoft\System Center 2016\SCOM\Agent\AMD64"
$destination = "\\$computerName\C`$\NotBackedUp\Temp\SCOM\Agent\AMD64"

robocopy $source $destination /E

$source = "\\TT-FS01\Products\Microsoft\System Center 2016\SCOM" `
    + "\SupportTools\AMD64"

$destination = "\\$computerName\C`$\NotBackedUp\Temp\SCOM\SupportTools\AMD64"

robocopy $source $destination /E
```

---

```PowerShell
cls
```

### # Install SCOM agent

```PowerShell
$installerPath = "C:\NotBackedUp\Temp\SCOM\Agent\AMD64\MOMAgent.msi"

$installerArguments = "MANAGEMENT_GROUP=HQ" `
    + " MANAGEMENT_SERVER_DNS=tt-scom03.corp.technologytoolbox.com" `
    + " ACTIONS_USE_COMPUTER_ACCOUNT=1"

Start-Process `
    -FilePath msiexec.exe `
    -ArgumentList "/i `"$installerPath`" $installerArguments" `
    -Wait
```

> **Important**
>
> Wait for the installation to complete.

```PowerShell
cls
```

### # Import the certificate into Operations Manager using MOMCertImport

```PowerShell
$hostName = ([System.Net.Dns]::GetHostByName(($env:computerName))).HostName

$certImportToolPath = "C:\NotBackedUp\Temp\SCOM\SupportTools\AMD64"

Push-Location "$certImportToolPath"

.\MOMCertImport.exe /SubjectName $hostName

Pop-Location
```

```PowerShell
cls
```

#### # Remove Operations Manager installation files

```PowerShell
Remove-Item C:\NotBackedUp\Temp\SCOM -Recurse
```

### Approve manual agent install in Operations Manager

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

## Configure settings for SQL Server Agent job history log

### Reference

**SQL SERVER - Dude, Where is the SQL Agent Job History? - Notes from the Field #017**\
From <[https://blog.sqlauthority.com/2014/02/27/sql-server-dude-where-is-the-sql-agent-job-history-notes-from-the-field-017/](https://blog.sqlauthority.com/2014/02/27/sql-server-dude-where-is-the-sql-agent-job-history-notes-from-the-field-017/)>

---

**SQL Server Management Studio**

### -- Do not limit size of SQL Server Agent job history log

```SQL
USE [msdb]
GO
EXEC msdb.dbo.sp_set_sqlagent_properties @jobhistory_max_rows=-1,
    @jobhistory_max_rows_per_job=-1
GO
```

---

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
$msiPath = "\\EXT-FS01\Products\Microsoft\System Center 2019\SCOM\agent\AMD64" `
    + "\MOMAgent.msi"

msiexec.exe /i $msiPath `
    MANAGEMENT_GROUP=HQ `
    MANAGEMENT_SERVER_DNS=TT-SCOM01C.corp.technologytoolbox.com `
    ACTIONS_USE_COMPUTER_ACCOUNT=1
```

**TODO:**

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Make virtual machine highly available

### # Migrate VM to shared storage

```PowerShell
$vmName = "EXT-SQL03"

$vm = Get-SCVirtualMachine -Name $vmName
$vmHost = $vm.VMHost

Move-SCVirtualMachine `
    -VM $vm `
    -VMHost $vmHost `
    -HighlyAvailable $true `
    -Path "C:\ClusterStorage\iscsi01-Silver-01" `
    -UseDiffDiskOptimization
```

### # Allow migration to host with different processor version

```PowerShell
Stop-SCVirtualMachine -VM $vmName

Set-SCVirtualMachine -VM $vmName -CPULimitForMigration $true

Start-SCVirtualMachine -VM $vmName
```

---

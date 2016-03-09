# EXT-SP2013-DEV - Windows Server 2012 Standard

Tuesday, February 23, 2016
5:55 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Install Windows Server 2012

---

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmName = "EXT-SP2013-DEV"
$vmPath = "D:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"
$isoPath = "\\ICEMAN\Products\Microsoft\Windows Server 2012" `
    + "\en_windows_server_2012_x64_dvd_915478.iso"

New-VM `
    -Name $vmName `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 8GB `
    -SwitchName "Production"

Set-VM `
    -Name $vmName `
    -ProcessorCount 4 `
    -StaticMemory

Set-VMDvdDrive `
    -VMName $vmName `
    -Path $isoPath

Start-VM -Name $vmName
```

---

### Install Windows Server 2012

```PowerShell
cls
```

### # Rename network connection

```PowerShell
Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "LAN 1 - 192.168.10.x"
```

### # Enable jumbo frames

```PowerShell
Set-NetAdapterAdvancedProperty `
    -Name "LAN 1 - 192.168.10.x" `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping ICEMAN -f -l 8900
```

```PowerShell
cls
```

### # Configure static IPv4 address

```PowerShell
$ipAddress = "192.168.10.221"

New-NetIPAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -IPAddress $ipAddress `
    -PrefixLength 24 `
    -DefaultGateway 192.168.10.1

Set-DNSClientServerAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -ServerAddresses 192.168.10.209,192.168.10.210
```

### # Configure static IPv6 address

```PowerShell
$ipAddress = "2601:282:4201:e500::221"

New-NetIPAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -IPAddress $ipAddress `
    -PrefixLength 64

Set-DNSClientServerAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -ServerAddresses 2601:282:4201:e500::209,2601:282:4201:e500::210
```

```PowerShell
cls
```

### # Rename the server and join domain

```PowerShell
Rename-Computer -NewName EXT-SP2013-DEV -Restart
```

Wait for the VM to restart and then execute the following command to join the **EXTRANET **domain:

```PowerShell
Add-Computer -DomainName extranet.technologytoolbox.com -Restart
```

### Move computer to "SharePoint Servers" OU

---

**EXT-DC01**

```PowerShell
$computerName = "EXT-SP2013-DEV"
$targetPath = ("OU=SharePoint Servers,OU=Servers,OU=Resources,OU=Development" `
    + ",DC=extranet,DC=technologytoolbox,DC=com")

Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath
```

---

---

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
$vmName = "EXT-SP2013-DEV"

Restart-VM $vmName -Force
```

---

### Remove disk from virtual CD/DVD drive

---

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
$vmName = "EXT-SP2013-DEV"

Set-VMDvdDrive -VMName $vmName -Path $null
```

---

### Login as EXTRANET\\setup-sharepoint-dev

```PowerShell
cls
```

### # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
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

### # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

### # Configure firewall rules for POSHPAIG (http://poshpaig.codeplex.com/)

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

### # Disable firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
Disable-NetFirewallRule -Name 'Remote Windows Update (Dynamic RPC)'
```

### DEV - Configure VM storage, processors, and memory

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 50 GB       | 4K                   |              |
| 1    | D:           | 3 GB        | 64K                  | Data01       |
| 2    | L:           | 1 GB        | 64K                  | Log01        |
| 3    | T:           | 1 GB        | 64K                  | Temp01       |
| 4    | Z:           | 10 GB       | 4K                   | Backup01     |

---

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Expand primary VHD for virtual machine

```PowerShell
$vmHost = "WOLVERINE"
$vmName = "EXT-SP2013-DEV"

$vmPath = "D:\NotBackedUp\VMs\$vmName"

Stop-VM -ComputerName $vmHost -VMName $vmName

$vhdPath = "$vmPath\Virtual Hard Disks\$vmName.vhdx"

Resize-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 80GB
```

#### # Create Data01, Log01, Temp01, and Backup01 VHDs

##### # Create VHD - "Data01"

```PowerShell
$vhdPath = "$vmPath\Virtual Hard Disks\$vmName" `
    + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 3GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ControllerType SCSI `
    -Path $vhdPath
```

##### # Create VHD - "Log01"

```PowerShell
$vhdPath = "$vmPath\Virtual Hard Disks\$vmName" `
    + "_Log01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 1GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ControllerType SCSI `
    -Path $vhdPath
```

##### # Create VHD - "Temp01"

```PowerShell
$vhdPath = "$vmPath\Virtual Hard Disks\$vmName" `
    + "_Temp01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 1GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ControllerType SCSI `
    -Path $vhdPath
```

##### # Create VHD - "Backup01"

```PowerShell
$vhdPath = "$vmPath\Virtual Hard Disks\$vmName" `
    + "_Backup01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 10GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ControllerType SCSI `
    -Path $vhdPath

Start-VM -ComputerName $vmHost -VMName $vmName
```

---

# Expand C: partition

```PowerShell
$maxSize = (Get-PartitionSupportedSize -DriveLetter C).SizeMax

Resize-Partition -DriveLetter C -Size $maxSize
```

#### # Format Data01 drive

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

#### # Format Log01 drive

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

#### # Format Temp01 drive

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

#### # Format Backup01 drive

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

### # Copy Toolbox content

```PowerShell
net use \\iceman.corp.technologytoolbox.com\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```Console
robocopy \\iceman.corp.technologytoolbox.com\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E
```

```Console
cls
```

### # Set MaxPatchCacheSize to 0 (Recommended)

```PowerShell
Set-ExecutionPolicy RemoteSigned

C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

### Install latest service pack and updates

### DEV - Install Visual Studio 2012

---

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Mount Visual Studio 2012 installation media

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\Visual Studio 2012" `
    + "\en_visual_studio_ultimate_2012_x86_dvd_920947.iso"

Set-VMDvdDrive -VMName EXT-SP2013-DEV -Path $imagePath
```

---

```PowerShell
& X:\vs_ultimate.exe
```

### Install SQL Server 2012

---

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Mount SQL Server installation media

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\SQL Server 2012" `
    + "\en_sql_server_2012_developer_edition_with_sp1_x64_dvd_1228540.iso"

Set-VMDvdDrive -VMName EXT-SP2013-DEV -Path $imagePath
```

---

```PowerShell
& X:\setup.exe
```

### -- DEV - Change databases to Simple recovery model

```SQL
IF OBJECT_ID('tempdb..#CommandQueue') IS NOT NULL DROP TABLE #CommandQueue

CREATE TABLE #CommandQueue
(
    ID INT IDENTITY ( 1, 1 )
    , SqlStatement VARCHAR(1000)
)

INSERT INTO #CommandQueue
(
    SqlStatement
)
SELECT
    'ALTER DATABASE [' + name + '] SET RECOVERY SIMPLE'
FROM
    sys.databases
WHERE
    name NOT IN ( 'master', 'msdb', 'tempdb' )

DECLARE @id INT

SELECT @id = MIN(ID)
FROM #CommandQueue

WHILE @id IS NOT NULL
BEGIN
    DECLARE @sqlStatement VARCHAR(1000)

    SELECT
        @sqlStatement = SqlStatement
    FROM
        #CommandQueue
    WHERE
        ID = @id

    PRINT 'Executing ''' + @sqlStatement + '''...'

    EXEC (@sqlStatement)

    DELETE FROM #CommandQueue
    WHERE ID = @id

    SELECT @id = MIN(ID)
    FROM #CommandQueue
END
```

### -- DEV - Constrain maximum memory for SQL Server

```SQL
EXEC sys.sp_configure N'show advanced options', N'1'  RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'max server memory (MB)', N'1024'
GO
RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'show advanced options', N'0'  RECONFIGURE WITH OVERRIDE
GO
```

### -- DEV - Configure TempDB data and log files

```SQL
ALTER DATABASE [tempdb]
  MODIFY FILE
  (
    NAME = N'tempdev'
    , SIZE = 128MB
    , FILEGROWTH = 10MB
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
      + ', SIZE = 128MB'
      + ', FILEGROWTH = 10MB'
    + ')';

EXEC sp_executesql @sqlStatement;

SELECT @sqlStatement =
  N'ALTER DATABASE [tempdb]'
    + 'ADD FILE'
    + '('
      + 'NAME = N''tempdev3'''
      + ', FILENAME = ''' + @dataPath + '3.mdf'''
      + ', SIZE = 128MB'
      + ', FILEGROWTH = 10MB'
    + ')';

EXEC sp_executesql @sqlStatement;

SELECT @sqlStatement =
  N'ALTER DATABASE [tempdb]'
    + 'ADD FILE'
    + '('
      + 'NAME = N''tempdev4'''
      + ', FILENAME = ''' + @dataPath + '4.mdf'''
      + ', SIZE = 128MB'
      + ', FILEGROWTH = 10MB'
    + ')';

EXEC sp_executesql @sqlStatement;
ALTER DATABASE [tempdb]
  MODIFY FILE (
    NAME = N'templog',
    SIZE = 50MB,
    FILEGROWTH = 10MB
  )
```

### -- Configure "Max Degree of Parallelism" for SharePoint

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

### # Configure permissions on \\Windows\\System32\\LogFiles\\Sum files

```PowerShell
icacls C:\Windows\System32\LogFiles\Sum\Api.chk `
    /grant "NT Service\MSSQLSERVER:(M)"

icacls C:\Windows\System32\LogFiles\Sum\Api.log `
    /grant "NT Service\MSSQLSERVER:(M)"

icacls C:\Windows\System32\LogFiles\Sum\SystemIdentity.mdb `
    /grant "NT Service\MSSQLSERVER:(M)"
```

### DEV - Install Microsoft Office 2013 (Recommended)

---

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Mount Office Professional Plus 2013 with SP1 installation media

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\Office 2013" `
    + "\en_office_professional_plus_2013_with_sp1_x86_and_x64_dvd_3928186.iso"

Set-VMDvdDrive -VMName EXT-SP2013-DEV -Path $imagePath
```

---

```PowerShell
& X:\setup.exe
```

```PowerShell
cls
```

### # DEV - Install Microsoft SharePoint Designer 2013 (Recommended)

```PowerShell
net use \\ICEMAN\Products /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
& "\\ICEMAN\Products\Microsoft\SharePoint Designer 2013\en_sharepoint_designer_2013_with_sp1_x86_3948134.exe"
```

### DEV - Install Microsoft Visio 2013 (Recommended)

---

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Mount Visio Professional 2013 with SP1 installation media

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\Visio 2013" `
    + "\en_visio_professional_2013_with_sp1_x86_and_x64_dvd_3910950.iso"

Set-VMDvdDrive -VMName EXT-SP2013-DEV -Path $imagePath
```

---

```PowerShell
& X:\setup.exe
```

```PowerShell
cls
```

### # DEV - Install additional browsers and software (Recommended)

```PowerShell
cls
```

#### # Install Mozilla Firefox

```PowerShell
& "\\ICEMAN\Products\Mozilla\Firefox\Firefox Setup 44.0.2.exe"
```

```PowerShell
cls
```

#### # Install Google Chrome

```PowerShell
& "\\ICEMAN\Products\Google\Chrome\ChromeStandaloneSetup64.exe"
```

### Install additional service packs and updates

#### Pass 1

- 96 important updates available
- ~4 GB
- Approximate time: 15 minutes (9:22 AM - 9:37 AM)

#### Pass 2

- 1 important updates available
- ~174 MB
- Approximate time: 2 minutes (9:37 AM - 9:39 AM)

## Install and configure SharePoint Server 2013

```PowerShell
cls
```

### # Install SharePoint 2013 prerequisites on the farm servers

---

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Insert the SharePoint 2013 installation media into the DVD drive for the SharePoint VM

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\SharePoint 2013\" `
    + "en_sharepoint_server_2013_with_sp1_x64_dvd_3823428.iso"

Set-VMDvdDrive -Path $imagePath -VMName EXT-SP2013-DEV
```

---

```Console
net use \\ICEMAN\Products /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$sourcePath = `
    "\\ICEMAN\Products\Microsoft\SharePoint 2013\PrerequisiteInstallerFiles_SP1"

$prereqPath = "C:\NotBackedUp\Temp\PrerequisiteInstallerFiles_SP1"

robocopy $sourcePath $prereqPath /E

& X:\PrerequisiteInstaller.exe `
    /SQLNCli:"$prereqPath\sqlncli.msi" `
    /PowerShell:"$prereqPath\Windows6.1-KB2506143-x64.msu" `
    /NETFX:"$prereqPath\dotNetFx45_Full_setup.exe" `
    /IDFX:"$prereqPath\Windows6.1-KB974405-x64.msu" `
    /Sync:"$prereqPath\Synchronization.msi" `
    /AppFabric:"$prereqPath\WindowsServerAppFabricSetup_x64.exe" `
    /IDFX11:"$prereqPath\MicrosoftIdentityExtensions-64.msi" `
    /MSIPCClient:"$prereqPath\setup_msipc_x64.msi" `
    /WCFDataServices:"$prereqPath\WcfDataServices.exe" `
    /KB2671763:"$prereqPath\AppFabric1.1-RTM-KB2671763-x64-ENU.exe" `
    /WCFDataServices56:"$prereqPath\WcfDataServices-5.6.exe"

Remove-Item $prereqPath
```

```PowerShell
cls
```

### # Install SharePoint Server 2013 on the farm servers

```PowerShell
& X:\setup.exe
```

```PowerShell
cls
```

### # Install Cumulative Update for SharePoint Server 2013

```PowerShell
net use \\ICEMAN\Products /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$patch = "15.0.4701.1001 - SharePoint 2013 March 2015 CU"

robocopy `
    "\\ICEMAN\Products\Microsoft\SharePoint 2013\Patches\$patch" `
    "C:\NotBackedUp\Temp\$patch" `
    /E

& "C:\NotBackedUp\Temp\$patch\*.exe"
```

> **Important**
>
> Wait for the patch to be installed.

```PowerShell
Remove-Item "C:\NotBackedUp\Temp\$patch" -Recurse
```

```PowerShell
cls
```

### # Add the SharePoint bin folder to the PATH environment variable

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-PathFolders.ps1 `
    ("C:\Program Files\Common Files\Microsoft Shared\web server extensions" `
        + "\15\BIN") `
    -EnvironmentVariableTarget "Machine"
```

> **Important**
>
> Restart PowerShell for environment variable change to take effect.

---

**FOOBAR8**

### # Checkpoint VM

```PowerShell
$vmHost = "WOLVERINE"
$vmName = "EXT-SP2013-DEV"

Stop-VM -ComputerName $vmHost -Name $vmName

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName "6.5 Copy SecuritasConnect build to SharePoint server"

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Copy SecuritasConnect build to SharePoint server

---

**Developer Command Prompt for VS2013 - Run as administrator**

```Console
mkdir C:\NotBackedUp\Securitas
tf workfold /decloak "$/Securitas ClientPortal/Dev/Lab2"
tf get C:\NotBackedUp\Securitas\ClientPortal\Dev\Lab2 /recursive /force
tf get "$/Securitas ClientPortal/Main/Code/Securitas.Portal.ruleset" /force
cd C:\NotBackedUp\Securitas\ClientPortal\Dev\Lab2\Code
msbuild SecuritasClientPortal.sln /p:IsPackaging=true
```

---

```PowerShell
cls
```

### # Create and configure the farm

```PowerShell
cd C:\NotBackedUp\Securitas\ClientPortal\Dev\Lab2\Code\DeploymentFiles\Scripts

& '.\Create Farm.ps1' -CentralAdminAuthProvider NTLM -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-spfarm-dev**.\
> Expect the previous operation to complete in approximately 4 minutes.

### Add Web servers to the farm

(skipped)

```PowerShell
cls
```

### # Add SharePoint Central Administration to the "Local intranet" zone

```PowerShell
[string] $registryKey = ("HKCU:\Software\Microsoft\Windows" `
    + "\CurrentVersion\Internet Settings\ZoneMap\EscDomains" `
    + "\$env:COMPUTERNAME")

If ((Test-Path $registryKey) -eq $false)
{
    New-Item $registryKey | Out-Null
}

Set-ItemProperty -Path $registryKey -Name http -Value 1
```

### # Grant permissions on DCOM applications for SharePoint

```PowerShell
& '.\Configure DCOM Permissions.ps1' -Verbose
```

### # Configure diagnostic logging

```PowerShell
Set-SPDiagnosticConfig -DaysToKeepLogs 3

Set-SPDiagnosticConfig -LogDiskSpaceUsageGB 1 -LogMaxDiskSpaceUsageEnabled:$true
```

### # Configure usage and health data collection

```PowerShell
Set-SPUsageService -LoggingEnabled 1

New-SPUsageApplication
```

### # Configure outgoing e-mail settings

```PowerShell

$smtpServer = "smtp-test.technologytoolbox.com"
$fromAddress = "s-spfarm-dev@technologytoolbox.com"
$replyAddress = "no-reply@technologytoolbox.com"
$characterSet = 65001 # Unicode (UTF-8)

$centralAdmin = Get-SPWebApplication -IncludeCentralAdministration |
	Where-Object { $_.IsAdministrationWebApplication -eq $true }

$centralAdmin.UpdateMailSettings(
	$smtpServer,
	$fromAddress,
	$replyAddress,
	$characterSet)
```

### # DEV - Configure timer job history

```PowerShell
Set-SPTimerJob "job-delete-job-history" -Schedule "Daily between 12:00:00 and 13:00:00"
```

## Backup SharePoint 2010 environment

### Backup databases in SharePoint 2010 environment

---

**EXT-FOOBAR**

```Console
DECLARE @backupPath NVARCHAR(255) =
    N'Z:\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Backup'

DECLARE @backupFilePath NVARCHAR(255)

-- Backup database for Managed Metadata Service

SET @backupFilePath = @backupPath + N'\Securitas_CP_MMS.bak'

BACKUP DATABASE [Securitas_CP_MMS]
TO DISK = @backupFilePath
WITH NOFORMAT, NOINIT
    , NAME = N'Securitas_CP_MMS-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY

-- Backup databases for User Profile Service

SET @backupFilePath = @backupPath + N'\Securitas_CP_ProfileDB.bak'

BACKUP DATABASE [Securitas_CP_ProfileDB]
TO DISK = @backupFilePath
WITH NOFORMAT, NOINIT
    , NAME = N'Securitas_CP_ProfileDB-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY

SET @backupFilePath = @backupPath + N'\Securitas_CP_SocialDB.bak'

BACKUP DATABASE [Securitas_CP_SocialDB]
TO DISK = @backupFilePath
WITH NOFORMAT, NOINIT
    , NAME = N'Securitas_CP_SocialDB-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY

SET @backupFilePath = @backupPath + N'\Securitas_CP_SyncDB.bak'

BACKUP DATABASE [Securitas_CP_SyncDB]
TO DISK = @backupFilePath
WITH NOFORMAT, NOINIT
    , NAME = N'Securitas_CP_SyncDB-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY

-- Backup "domain model" database

SET @backupFilePath = @backupPath + N'\SecuritasPortal.bak'

BACKUP DATABASE [SecuritasPortal]
TO DISK = @backupFilePath
WITH NOFORMAT, NOINIT
    , NAME = N'SecuritasPortal-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY

-- Backup content database for SecuritasConnect Web application

SET @backupFilePath = @backupPath + N'\WSS_Content_SecuritasPortal.bak'

BACKUP DATABASE [WSS_Content_SecuritasPortal]
TO DISK = @backupFilePath
WITH NOFORMAT, NOINIT
    , NAME = N'WSS_Content_SecuritasPortal-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY
```

---

```PowerShell
cls
```

#### # Copy the backup files to the SQL Server for the SharePoint 2013 farm

```PowerShell
robocopy `
    '\\EXT-FOOBAR\Z$\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Backup' `
    "Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup"
```

### Export the User Profile Synchronization encryption key

---

**EXT-FOOBAR**

#### REM Export MIIS encryption key

```Console
cd "C:\Program Files\Microsoft Office Servers\14.0\Synchronization Service\Bin\"

miiskmu.exe /e C:\Users\%USERNAME%\Desktop\miiskeys-1.bin ^
    /u:EXTRANET\svc-sharepoint-dev *
```

> **Note**
>
> When prompted for the password, type the password for the SharePoint 2010 service account.

Copy file to SharePoint 2013 server.

---

```PowerShell
cls
```

## # Configure SharePoint services and service applications

### # Change the service account for the Distributed Cache

```PowerShell
cd C:\NotBackedUp\Securitas\ClientPortal\Dev\Lab2\Code\DeploymentFiles\Scripts

& '.\Configure Distributed Cache.ps1' -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-spserviceapp-dev**.\
> Expect the previous operation to complete in approximately 7-8 minutes.

```PowerShell
cls
```

### # DEV - Constrain the Distributed Cache

```PowerShell
Update-SPDistributedCacheSize -CacheSizeInMB 150
```

### # Configure the State Service

```PowerShell
& '.\Configure State Service.ps1' -Verbose
```

### # Configure the SharePoint ASP.NET Session State service

```PowerShell
Enable-SPSessionStateService -DatabaseName SessionStateService
```

### # Create application pool for SharePoint service applications

```PowerShell
& '.\Configure Service Application Pool.ps1' -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-spserviceapp-dev**.

```PowerShell
cls
```

### # Configure the Managed Metadata Service

#### # Restore the database backup from the SharePoint 2010 Managed Metadata Service

```PowerShell
$sqlcmd = @"
DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\'
    + 'Securitas_CP_MMS.bak'

DECLARE @dataFilePath VARCHAR(255) =
  'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'ManagedMetadataService.mdf'

DECLARE @logFilePath VARCHAR(255) =
  'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'ManagedMetadataService_log.LDF'

RESTORE DATABASE ManagedMetadataService
  FROM DISK = @backupFilePath
  WITH FILE = 1,
    MOVE 'Securitas_CP_MMS' TO @dataFilePath,
    MOVE 'Securitas_CP_MMS_log' TO @logFilePath,
    NOUNLOAD,
    STATS = 5
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

```PowerShell
cls
```

#### # Create the Managed Metadata Service

```PowerShell
& '.\Configure Managed Metadata Service.ps1' -Verbose
```

##### Issue

The Managed Metadata Service or Connection is currently not available. The Application Pool or Managed Metadata Web Service may not have been started. Please Contact your Administrator.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AD/842C730D649A89B242ACCBE96F13BFCD25B184AD.png)

##### Solution

1. Edit the MMS properties to temporarily change the database name (**ManagedMetadataService2**).
2. Edit the MMS properties to revert to the restored database (**ManagedMetadataService**).
3. Reset IIS.
4. Delete temporary database (**ManagedMetadataService2**).

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9A/C56BF926C02F6DDAD8650DC9907B7E22B6DC039A.png)

##### Reference

**The Managed Metadata Service or Connection is currently not available in SharePoint 2013**\
From <[http://blog.areflyen.no/2014/08/21/the-managed-metadata-service-or-connection-is-currently-not-available-in-sharepoint-2013/](http://blog.areflyen.no/2014/08/21/the-managed-metadata-service-or-connection-is-currently-not-available-in-sharepoint-2013/)>

```PowerShell
cls
```

### # Configure the User Profile Service Application

#### # Restore the database backup from the SharePoint 2010 User Profile Service Application

```PowerShell
$sqlcmd = @"
```

##### -- Restore profile database

```Console
DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\'
    + 'Securitas_CP_ProfileDB.bak'

DECLARE @dataFilePath VARCHAR(255) =
  'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'UserProfileService_Profile.mdf'

DECLARE @logFilePath VARCHAR(255) =
  'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'UserProfileService_Profile_log.LDF'

RESTORE DATABASE UserProfileService_Profile
  FROM DISK = @backupFilePath
  WITH FILE = 1,
    MOVE 'Securitas_CP_ProfileDB' TO @dataFilePath,
    MOVE 'Securitas_CP_ProfileDB_log' TO @logFilePath,
    NOUNLOAD,
    STATS = 5
```

##### -- Restore synchronization database

```Console
SET @backupFilePath =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\'
    + 'Securitas_CP_SyncDB.bak'

SET @dataFilePath =
  'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'UserProfileService_Sync.mdf'

SET @logFilePath =
  'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'UserProfileService_Sync_log.LDF'

RESTORE DATABASE UserProfileService_Sync
  FROM DISK = @backupFilePath
  WITH FILE = 1,
    MOVE 'Securitas_CP_SyncDB' TO @dataFilePath,
    MOVE 'Securitas_CP_SyncDB_log' TO @logFilePath,
    NOUNLOAD,
    STATS = 5
```

##### -- Restore social tagging database

```Console
SET @backupFilePath =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\'
    + 'Securitas_CP_SocialDB.bak'

SET @dataFilePath =
  'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'UserProfileService_Social.mdf'

SET @logFilePath =
  'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'UserProfileService_Social_log.LDF'

RESTORE DATABASE UserProfileService_Social
  FROM DISK = @backupFilePath
  WITH FILE = 1,
    MOVE 'Securitas_CP_SocialDB' TO @dataFilePath,
    MOVE 'Securitas_CP_SocialDB_log' TO @logFilePath,
    NOUNLOAD,
    STATS = 5

GO
```

#### -- Add new SharePoint farm account to db_owner role in restored databases

```Console
USE [UserProfileService_Profile]
GO

CREATE USER [EXTRANET\s-spfarm-dev] FOR LOGIN [EXTRANET\s-spfarm-dev]

ALTER ROLE [db_owner] ADD MEMBER [EXTRANET\s-spfarm-dev]
GO

USE [UserProfileService_Social]
GO

CREATE USER [EXTRANET\s-spfarm-dev] FOR LOGIN [EXTRANET\s-spfarm-dev]

ALTER ROLE [db_owner] ADD MEMBER [EXTRANET\s-spfarm-dev]
GO

USE [UserProfileService_Sync]
GO

CREATE USER [EXTRANET\s-spfarm-dev] FOR LOGIN [EXTRANET\s-spfarm-dev]

ALTER ROLE [db_owner] ADD MEMBER [EXTRANET\s-spfarm-dev]
GO
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

```Console
cls
```

#### # Create the User Profile Service Application

# Create User Profile Service Application as EXTRANET\\s-spfarm-dev:

```PowerShell
$farmCredential = Get-Credential (Get-SPFarm).DefaultServiceAccount.Name
```

> **Note**
>
> When prompted for the service account credentials, type the password for the SharePoint farm service account.

```PowerShell
net localgroup Administrators /add $farmCredential.UserName

Restart-Service SPTimerV4

Start-Process $PSHOME\powershell.exe `
    -Credential $farmCredential `
    -ArgumentList "-Command Start-Process PowerShell.exe -Verb Runas" `
    -Wait
```

---

**PowerShell -- running as EXTRANET\\s-spfarm-dev**

```PowerShell
cd C:\NotBackedUp\Securitas\ClientPortal\Dev\Lab2\Code\DeploymentFiles\Scripts

& '.\Configure User Profile Service.ps1' -Verbose
```

> **Important**
>
> Wait for the service application to be configured.

```Console
exit
```

---

```Console
net localgroup Administrators /delete $farmCredential.UserName

Restart-Service SPTimerV4
```

#### Disable social features

(skipped)

#### Disable newsfeed

(skipped)

```PowerShell
cls
```

### # Configure User Profile Synchronization (UPS)

#### # Configure NETWORK SERVICE permissions

```PowerShell
$path = "$env:ProgramFiles\Microsoft Office Servers\15.0"
icacls $path /grant "NETWORK SERVICE:(OI)(CI)(RX)"
```

#### # Temporarily add SharePoint farm account to local Administrators group

```PowerShell
net localgroup Administrators /add EXTRANET\s-spfarm-dev

Restart-Service SPTimerV4
```

#### Start the User Profile Synchronization Service

```PowerShell
cls
```

#### # Import MIIS encryption key

```PowerShell
# Note: NullReferenceException occurs if you attempt to perform this step before starting the User Profile Synchronization Service.
```

# Import MIIS encryption key as EXTRANET\\s-spfarm-dev:

```PowerShell
$farmCredential = Get-Credential (Get-SPFarm).DefaultServiceAccount.Name

Start-Process $PSHOME\powershell.exe `
    -Credential $farmCredential `
    -ArgumentList "-Command Start-Process cmd.exe -Verb Runas" `
    -Wait
```

---

**Command Prompt -- running as EXTRANET\\s-spfarm-dev**

```Console
cd "C:\Program Files\Microsoft Office Servers\15.0\Synchronization Service\Bin\"

miiskmu.exe /i "C:\Users\setup-sharepoint-dev\Desktop\miiskeys-1.bin" ^
    {0E19E162-827E-4077-82D4-E6ABD531636E}
```

> **Important**
>
> Verify the encryption key was successfully imported.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/15/D84BBCED6D8E21D847E4083A3BAD42DDDFDCA615.png)

Wait a little bit...and then try again.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AD/CE6D63A59418127C0445938FB7EFDF6FE45231AD.png)

```Console
exit
```

---

```PowerShell
cls
```

#### # Remove SharePoint farm account from local Administrators group

```PowerShell
net localgroup Administrators /delete EXTRANET\s-spfarm-dev

Restart-Service SPTimerV4
```

#### Configure synchronization connections and import data from Active Directory

Verified the following connections are already configured (from database restored from SharePoint 2010 environment).

| **Connection Name** | **Forest Name**            | **Account Name**            |
| ------------------- | -------------------------- | --------------------------- |
| TECHTOOLBOX         | corp.technologytoolbox.com | TECHTOOLBOX\\svc-sp-ups-dev |
| FABRIKAM            | corp.fabrikam.com          | FABRIKAM\\s-sp-ups-dev      |

```PowerShell
cls
```

### # Create and configure the search service application

```PowerShell
& '.\Configure SharePoint Search.ps1' -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-index-dev**.\
> Expect the previous operation to complete in approximately 5-6 minutes.

```PowerShell
cls
```

### # DEV - Configure performance level for the search crawl component

```PowerShell
Set-SPEnterpriseSearchService -PerformanceLevel Reduced

Restart-Service SPSearchHostController
```

### # Configure people search in SharePoint

```PowerShell
$mySiteHostLocation = "http://client-local.securitasinc.com/sites/my"

Add-PSSnapin Microsoft.SharePoint.PowerShell

$searchApp = Get-SPEnterpriseSearchServiceApplication `
    -Identity "Search Service Application"
```

#### # Grant permissions to default content access account

```PowerShell
$content = New-Object `
    -TypeName Microsoft.Office.Server.Search.Administration.Content `
    -ArgumentList $searchApp

$principal = New-SPClaimsPrincipal `
    -Identity $content.DefaultGatheringAccount `
    -IdentityType WindowsSamAccountName

$userProfileServiceApp = Get-SPServiceApplication `
    -Name "User Profile Service Application"

$security = Get-SPServiceApplicationSecurity `
    -Identity $userProfileServiceApp `
    -Admin

Grant-SPObjectSecurity `
    -Identity $security `
    -Principal $principal `
    -Rights "Retrieve People Data for Search Crawlers"

Set-SPServiceApplicationSecurity `
    -Identity $userProfileServiceApp `
    -ObjectSecurity $security `
    -Admin
```

#### # Create content source for crawling user profiles

```PowerShell
$mySiteHostUri = [System.Uri] $mySiteHostLocation

If ($mySiteHostUri.Scheme -eq "http")
{
    $startAddress = "sps3://" + $mySiteHostUri.Authority
}
ElseIf ($mySiteHostUri.Scheme -eq "https")
{
    $startAddress = "sps3s://" + $mySiteHostUri.Authority
}
Else
{
    Throw "The specified scheme ($($mySiteHostUri.Scheme)) is not supported."
}

New-SPEnterpriseSearchCrawlContentSource `
    -SearchApplication $searchapp `
    -Type SharePoint `
    -Name "User profiles" `
    -StartAddresses $startAddress
```

```PowerShell
cls
```

### # Configure the search crawl schedules

#### # Configure crawl schedule for "Local SharePoint sites"

```PowerShell
$searchApp = Get-SPEnterpriseSearchServiceApplication `
    -Identity "Search Service Application"

$contentSource = Get-SPEnterpriseSearchCrawlContentSource `
    -SearchApplication $searchApp `
    -Identity "Local SharePoint sites"

Set-SPEnterpriseSearchCrawlContentSource `
    -Identity $contentSource `
    -ScheduleType Full `
    -WeeklyCrawlSchedule `
    -CrawlScheduleStartDateTime "12:00 AM" `
    -CrawlScheduleDaysOfWeek Sunday `
    -CrawlScheduleRunEveryInterval 1

Set-SPEnterpriseSearchCrawlContentSource `
    -Identity $contentSource `
    -ScheduleType Incremental `
    -DailyCrawlSchedule `
    -CrawlScheduleStartDateTime "4:00 AM" `
    -CrawlScheduleRepeatInterval 60 `
    -CrawlScheduleRepeatDuration 1080
```

#### # Configure crawl schedule for "User profiles"

```PowerShell
$contentSource = Get-SPEnterpriseSearchCrawlContentSource `
    -SearchApplication $searchApp `
    -Identity "User profiles"

Set-SPEnterpriseSearchCrawlContentSource `
    -Identity $contentSource `
    -ScheduleType Full `
    -WeeklyCrawlSchedule `
    -CrawlScheduleStartDateTime "12:00 AM" `
    -CrawlScheduleDaysOfWeek Saturday `
    -CrawlScheduleRunEveryInterval 1

Set-SPEnterpriseSearchCrawlContentSource `
    -Identity $contentSource `
    -ScheduleType Incremental `
    -DailyCrawlSchedule `
    -CrawlScheduleStartDateTime "6:00 AM"
```

## TODO: Install and configure Office Web Apps

```PowerShell
cls
```

## # Create and configure the Web application

### # Set environment variables

```PowerShell
[Environment]::SetEnvironmentVariable(
  "SECURITAS_CLIENT_PORTAL_URL",
  "http://client-local.securitasinc.com",
  "Machine")

[Environment]::SetEnvironmentVariable(
  "SECURITAS_BUILD_CONFIGURATION",
  "Debug",
  "Machine")
```

> **Important**
>
> Restart PowerShell for environment variables to take effect.

```Console
cd C:\NotBackedUp\Securitas\ClientPortal\Dev\Lab2\Code\DeploymentFiles\Scripts
```

```Console
cls
```

### # Add the URL for the SecuritasConnect Web site to the "Local intranet" zone

```PowerShell
[string] $registryKey = ("HKCU:\Software\Microsoft\Windows" `
    + "\CurrentVersion\Internet Settings\ZoneMap\EscDomains" `
    + "\client-local.securitasinc.com")

If ((Test-Path $registryKey) -eq $false)
{
    New-Item $registryKey | Out-Null
}

Set-ItemProperty -Path $registryKey -Name http -Value 1
```

### DEV - Snapshot VM

---

**FOOBAR8**

#### # Checkpoint VM

```PowerShell
$checkpointName = "Baseline SharePoint Server 2013 configuration"
$vmHost = "WOLVERINE"
$vmName = "EXT-SP2013-DEV"

Stop-VM -ComputerName $vmHost -Name $vmName

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName $checkpointName

Start-VM -ComputerName $vmHost -Name $vmName
```

---

```Console
cd C:\NotBackedUp\Securitas\ClientPortal\Dev\Lab2\Code\DeploymentFiles\Scripts
```

### # Create the Web application

```PowerShell
& '.\Create Web Application.ps1'
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-web-client-dev**.

```PowerShell
cls
```

### # Restore content database or create initial site collections

#### # Remove content database created with Web application

```PowerShell
Remove-SPContentDatabase WSS_Content_SecuritasPortal -Confirm:$false -Force
```

##### # Restore database backup

```PowerShell
$sqlcmd = @"
DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\'
    + 'WSS_Content_SecuritasPortal.bak'

DECLARE @dataFilePath VARCHAR(255) =
  'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'WSS_Content_SecuritasPortal.mdf'

DECLARE @logFilePath VARCHAR(255) =
  'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'WSS_Content_SecuritasPortal_log.LDF'

RESTORE DATABASE WSS_Content_SecuritasPortal
  FROM DISK = @backupFilePath
  WITH FILE = 1,
    MOVE 'WSS_Content_SecuritasPortal' TO @dataFilePath,
    MOVE 'WSS_Content_SecuritasPortal_log' TO @logFilePath,
    NOUNLOAD,
    STATS = 5
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

```PowerShell
cls
```

##### # Install SecuritasConnect v3.0 solution

```PowerShell
net use \\ICEMAN\Builds /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$build = "3.0.647.0"

robocopy `
    \\ICEMAN\Builds\Securitas\ClientPortal\$build `
    C:\NotBackedUp\Builds\Securitas\ClientPortal\$build /E

cd C:\NotBackedUp\Builds\Securitas\ClientPortal\$build\DeploymentFiles\Scripts

& '.\Add Solutions.ps1'

& '.\Deploy Solutions.ps1'
```

```PowerShell
cls
```

##### # Test content database

```PowerShell
Test-SPContentDatabase `
    -Name WSS_Content_SecuritasPortal `
    -WebApplication http://client-local.securitasinc.com
```

```PowerShell
cls
```

##### # Attach content database

```PowerShell
Mount-SPContentDatabase `
    -Name WSS_Content_SecuritasPortal `
    -WebApplication http://client-local.securitasinc.com
```

```PowerShell
cls
```

### # Configure machine key for Web application

```PowerShell
& '.\Configure Machine Key.ps1'
```

### # Configure object cache user accounts

# TODO: Resolve "Access Denied" issue when object cache user accounts are set

```PowerShell
# & '.\Configure Object Cache User Accounts.ps1'

# iisreset
```

### # Configure the People Picker to support searches across one-way trust

#### # Set the application password used for encrypting credentials

```PowerShell
$appPassword = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted for the secure string, type the password for encrypting sensitive data in SharePoint applications.

```PowerShell
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($appPassword))

stsadm -o setapppassword -password $plainPassword
```

```PowerShell
cls
```

#### # Specify the credentials for accessing the trusted forest

```PowerShell
stsadm -o setproperty -pn peoplepicker-searchadforests -pv "domain:extranet.technologytoolbox.com,EXTRANET\s-web-client-dev,{password};domain:corp.fabrikam.com,FABRIKAM\s-sp-ups-dev,{password};domain:corp.technologytoolbox.com,TECHTOOLBOX\svc-sp-ups-dev,{password}" -url http://client-local.securitasinc.com
```

```PowerShell
cls
```

#### # Modify the permissions on the registry key where the encrypted credentials are stored

```PowerShell
$regPath = `
    "HKLM:\SOFTWARE\Microsoft\Shared Tools\Web Server Extensions\15.0\Secure"

$acl = Get-Acl $regPath

$rule = New-Object System.Security.AccessControl.RegistryAccessRule(
    "$env:COMPUTERNAME\WSS_WPG",
    "ReadKey",
    "ContainerInherit",
    "None",
    "Allow")

$acl.SetAccessRule($rule)
Set-Acl -Path $regPath -AclObject $acl
```

{TODO: bunch o' stuff skipped here}

## Deploy the SecuritasConnect solution

```Console
cls
```

### REM DEV - Build Visual Studio solution and package SharePoint projects

---

**Developer Command Prompt for VS2013 - Run as administrator**

```Console
cd C:\NotBackedUp\Securitas\ClientPortal\Dev\Lab2\Code
msbuild SecuritasClientPortal.sln /p:IsPackaging=true
```

---

```PowerShell
cls
```

### # Create or restore the SecuritasPortal database

```PowerShell
$sqlcmd = @"
```

#### -- Restore backup of SecuritasPortal database

```Console
DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\'
    + 'SecuritasPortal.bak'

DECLARE @dataFilePath VARCHAR(255) =
  'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + '_SecuritasPortal.mdf'

DECLARE @logFilePath VARCHAR(255) =
  'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'SecuritasPortal_log.LDF'

RESTORE DATABASE SecuritasPortal
  FROM DISK = @backupFilePath
  WITH FILE = 1,
    MOVE 'SecuritasPortal' TO @dataFilePath,
    MOVE 'SecuritasPortal_log' TO @logFilePath,
    NOUNLOAD,
    STATS = 5

GO
```

#### -- Configure permissions for the SecuritasPortal database

```Console
USE [SecuritasPortal]
GO

CREATE USER [EXTRANET\s-spfarm-dev] FOR LOGIN [EXTRANET\s-spfarm-dev]
GO
ALTER ROLE [aspnet_Membership_BasicAccess] ADD MEMBER [EXTRANET\s-spfarm-dev]
GO
ALTER ROLE [aspnet_Membership_ReportingAccess] ADD MEMBER [EXTRANET\s-spfarm-dev]
GO
ALTER ROLE [aspnet_Roles_BasicAccess] ADD MEMBER [EXTRANET\s-spfarm-dev]
GO
ALTER ROLE [aspnet_Roles_ReportingAccess] ADD MEMBER [EXTRANET\s-spfarm-dev]
GO

CREATE USER [EXTRANET\s-web-client-dev] FOR LOGIN [EXTRANET\s-web-client-dev]
GO
ALTER ROLE [aspnet_Membership_FullAccess] ADD MEMBER [EXTRANET\s-web-client-dev]
GO
ALTER ROLE [aspnet_Profile_BasicAccess] ADD MEMBER [EXTRANET\s-web-client-dev]
GO
ALTER ROLE [aspnet_Roles_BasicAccess] ADD MEMBER [EXTRANET\s-web-client-dev]
GO
ALTER ROLE [aspnet_Roles_ReportingAccess] ADD MEMBER [EXTRANET\s-web-client-dev]
GO
ALTER ROLE [Customer_Reader] ADD MEMBER [EXTRANET\s-web-client-dev]
GO
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

```Console
cls
```

### # Configure logging

```PowerShell
cd C:\NotBackedUp\Securitas\ClientPortal\Dev\Lab2\Code\DeploymentFiles\Scripts

& '.\Add Event Log Sources.ps1'
```

### # Configure claims-based authentication

```PowerShell
Notepad "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\WebServices\SecurityToken\web.config"
```

**{copy/paste Web.config entries from browser -- to avoid issue when copy/pasting from OneNote}**

```PowerShell
cls
```

### # Install SecuritasConnect solutions and activate the features

```PowerShell
pushd \NotBackedUp\Securitas\ClientPortal\Main\Code\DeploymentFiles\Scripts

& '.\Deactivate Features.ps1' -Verbose

& '.\Retract Solutions.ps1' -Verbose

& '.\Delete Solutions.ps1' -Verbose

& '.\Add Solutions.ps1' -Verbose

& '.\Deploy Solutions.ps1' -Verbose

& '.\Activate Features.ps1' -Verbose

popd
```

#### Activate the "Securitas - Application Settings" feature

(skipped)

### Import template site content

(skipped)

### Create users in the SecuritasPortal database

#### Create users for Securitas clients

(skipped)

#### Create users for Securitas Branch Managers

(skipped)

#### Associate client users to Branch Managers

(skipped)

```PowerShell
cls
```

### # Configure trusted root authorities in SharePoint

```PowerShell
& '.\Configure Trusted Root Authorities.ps1'
```

### Configure application settings (e.g. Web service URLs)

(skipped)

### Configure the SSO credentials for a user

(skipped)

### Configure C&C landing site

{Begin skipped sections}

#### Grant Branch Managers permissions to the C&C landing site

#### Hide the Search navigation item on the C&C landing site

[http://client-local.securitasinc.com/sites/cc](http://client-local.securitasinc.com/sites/cc)

#### Configure the search settings for the C&C landing site

## Create and configure C&C site collections

### Create site collection for a Securitas client

### Apply the "Securitas Client Site" template to the top-level site

### Modify the site title, description, and logo

### Update the client site home page

### Create a blog site (optional)

### Create a wiki site (optional)

{End skipped sections}

```PowerShell
cls
```

## # Configure Web application policy for SharePoint administrators group

```PowerShell
Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

$groupName = "EXTRANET\SharePoint Admins (DEV)"

$principal = New-SPClaimsPrincipal -Identity $groupName `
    -IdentityType WindowsSecurityGroupName

$claim = "c:0+.w|" + $principal.Value.ToLower()

$webApp = Get-SPWebApplication http://client-local.securitasinc.com

$policyRole = $webApp.PolicyRoles.GetSpecialRole(
    [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl)

$policy = $webApp.Policies.Add($claim, $groupName)
$policy.PolicyRoleBindings.Add($policyRole)

$webApp.Update()
```

**TODO:**

```PowerShell
cls
```

## # Start full crawl

```PowerShell
Get-SPEnterpriseSearchServiceApplication |
    Get-SPEnterpriseSearchCrawlContentSource |
    % { $_.StartFullCrawl() }
```

```PowerShell
cls
```

### # Delete C:\\Windows\\SoftwareDistribution folder (2.79 GB)

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse

Restart-Computer
```

### Check for updates using Windows Update (after removing patches folder)

- **Most recent check for updates: Never -> Most recent check for updates: Today at 7:08 PM**
- C:\\Windows\\SoftwareDistribution folder is now 55 MB

```PowerShell
cls
```

### # Clean up the WinSxS folder

```PowerShell
Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase
```

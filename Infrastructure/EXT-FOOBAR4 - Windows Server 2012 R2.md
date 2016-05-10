# EXT-FOOBAR4 - Windows Server 2012 R2 Standard

Tuesday, February 23, 2016
5:55 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

### Install Windows Server 2012 R2

---

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Create virtual machine

```PowerShell
$vmName = "EXT-FOOBAR4"

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -Name $vmName `
    -Path C:\NotBackedUp\VMs `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 10GB `
    -SwitchName "Production"

Set-VM `
    -Name $vmName `
    -ProcessorCount 4 `
    -StaticMemory

Set-VMDvdDrive `
    -VMName $vmName `
    -Path \\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso

Start-VM -Name $vmName
```

---

#### Install custom Windows Server 2012 R2 image

- Start-up disk: [\\\\ICEMAN\\Products\\Microsoft\\MDT-Deploy-x86.iso](\\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso)
- On the **Task Sequence** step, select **Windows Server 2012 R2** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **EXT-FOOBAR4**.
  - In the **Domain to join **box, type **extranet.technologytoolbox.com**.
  - Specify the credentials to join the domain.
  - Click **Next**.
- On the Applications step:
  - Select the following items:
    - Adobe
      - **Adobe Reader 8.3.1**
  - Click **Next**.

```PowerShell
cls
```

#### # Rename local Administrator account and set password

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

$password = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted for the secure string, type the password for the local Administrator account.

```PowerShell
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

$adminUser = [ADSI] 'WinNT://./Administrator,User'
$adminUser.Rename('foo')
$adminUser.SetPassword($plainPassword)

logoff
```

#### Move computer to "SharePoint Servers" OU

---

**EXT-DC01**

```PowerShell
$computerName = "EXT-FOOBAR4"
$targetPath = ("OU=SharePoint Servers,OU=Servers,OU=Resources,OU=Development" `
    + ",DC=extranet,DC=technologytoolbox,DC=com")

Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath
```

---

---

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
$vmName = "EXT-FOOBAR4"

Restart-VM $vmName -Force
```

---

#### Remove disk from virtual CD/DVD drive

---

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
$vmName = "EXT-FOOBAR4"

Set-VMDvdDrive -VMName $vmName -Path $null
```

---

#### Login as EXTRANET\\setup-sharepoint-dev

```PowerShell
cls
```

#### # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

```PowerShell
cls
```

#### # Change drive letter for DVD-ROM

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

#### # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

#### # Configure firewall rules for POSHPAIG (http://poshpaig.codeplex.com/)

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

#### # Disable firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
Disable-NetFirewallRule -Name 'Remote Windows Update (Dynamic RPC)'
```

```PowerShell
cls
```

#### # Rename network connection

```PowerShell
Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "LAN 1 - 192.168.10.x"
```

#### # Enable jumbo frames

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

#### # Configure static IPv4 address

```PowerShell
$ipAddress = "192.168.10.218"

New-NetIPAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -IPAddress $ipAddress `
    -PrefixLength 24 `
    -DefaultGateway 192.168.10.1

Set-DNSClientServerAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -ServerAddresses 192.168.10.209,192.168.10.210
```

#### # Configure static IPv6 address

```PowerShell
$ipAddress = "2601:282:4201:e500::218"

New-NetIPAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -IPAddress $ipAddress `
    -PrefixLength 64

Set-DNSClientServerAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -ServerAddresses 2601:282:4201:e500::209,2601:282:4201:e500::210
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
$vmName = "EXT-FOOBAR4"

$vmPath = "C:\NotBackedUp\VMs\$vmName"

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

### # Set MaxPatchCacheSize to 0 (Recommended)

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

### Install latest service pack and updates

### Create service accounts

(skipped)

### Create Active Directory container to track SharePoint 2013 installations

(skipped)

### DEV - Install Visual Studio 2013 with Update 4

---

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Mount Visual Studio 2013 with Update 4 installation media

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\Visual Studio 2013" `
    + "\en_visual_studio_ultimate_2013_with_update_4_x86_dvd_5935075.iso"

Set-VMDvdDrive -VMName EXT-FOOBAR4 -Path $imagePath
```

---

```PowerShell
& X:\vs_ultimate.exe
```

### DEV - Install update for Office developer tools in Visual Studio

**Note:** Microsoft Office Developer Tools for Visual Studio 2013 - August 2015 Update

Add **[https://www.microsoft.com](https://www.microsoft.com)** to **Trusted sites** zone

### DEV - Install update for SQL Server database projects in Visual Studio

Add **[http://download.microsoft.com](http://download.microsoft.com)** to **Trusted sites** zone

### DEV - Install Productivity Power Tools for Visual Studio

### TODO: DEV - Install TFS Power Tools

### Install SQL Server 2014

---

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Mount SQL Server 2014 installation media

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\SQL Server 2014" `
    + "\en_sql_server_2014_developer_edition_x64_dvd_3940406.iso"

Set-VMDvdDrive -VMName EXT-FOOBAR4 -Path $imagePath
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
EXEC sys.sp_configure N'show advanced options', N'1'
RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'max server memory (MB)', N'1024'
GO
RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'show advanced options', N'0'
RECONFIGURE WITH OVERRIDE
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

```PowerShell
cls
```

### # Install Prince on front-end Web servers

```PowerShell
net use \\ICEMAN\Products /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
& "\\ICEMAN\Products\Prince\prince-7.1-setup.exe"
```

> **Important**
>
> Wait for the software to be installed.

```PowerShell
cls
```

#### # Configure Prince license

```PowerShell
Copy-Item `
    \\ICEMAN\Products\Prince\Prince-license.dat `
    'C:\Program Files (x86)\Prince\Engine\license\license.dat'
```

1. In the **Prince** window, click the **Help** menu and then click **License**.
2. In the **Prince License** window:
   1. Click **Open** and then locate the license file (**[\\\\ICEMAN\\Products\\Prince\\Prince-license.dat](\\ICEMAN\Products\Prince\Prince-license.dat)**).
   2. Click **Accept** to save the license information.
   3. Verify the license information and then click **Close**.
3. Close the Prince application.

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

Set-VMDvdDrive -VMName EXT-FOOBAR4 -Path $imagePath
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

Set-VMDvdDrive -VMName EXT-FOOBAR4 -Path $imagePath
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

### Download SharePoint 2013 prerequisites to a file share

(skipped)

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

Set-VMDvdDrive -Path $imagePath -VMName EXT-FOOBAR4
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
$vmName = "EXT-FOOBAR4"

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
> When prompted for the service account, specify **EXTRANET\\s-sp-farm-dev**.\
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
$fromAddress = "s-sp-farm-dev@technologytoolbox.com"
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

```PowerShell
cls
```

## # Install and configure Office Web Apps

#### # Configure the SharePoint 2013 farm to use Office Web Apps

```PowerShell
New-SPWOPIBinding -ServerName wac.fabrikam.com

Set-SPWOPIZone -zone "external-https"
```

## Backup SharePoint 2010 environment

### Backup databases in SharePoint 2010 environment

---

**EXT-FOOBAR - SQL Server Management Studio**

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

### # Export the User Profile Synchronization encryption key

---

**EXT-FOOBAR - Command Prompt**

#### REM Export MIIS encryption key

```Console
cd "C:\Program Files\Microsoft Office Servers\14.0\Synchronization Service\Bin\"

miiskmu.exe /e C:\Users\%USERNAME%\Desktop\miiskeys-1.bin ^
    /u:EXTRANET\svc-sharepoint-dev *
```

> **Note**
>
> When prompted for the password, type the password for the SharePoint 2010 service account.

---

#### # Copy MIIS encryption key file to SharePoint 2013 server

```PowerShell
Copy-Item `
    "\\EXT-FOOBAR\C$\Users\jjameson\Desktop\miiskeys-1.bin" `
    "C:\Users\setup-sharepoint-dev\Desktop\miiskeys-1.bin"
```

## # Configure SharePoint services and service applications

### # Change the service account for the Distributed Cache

```PowerShell
cd C:\NotBackedUp\Securitas\ClientPortal\Dev\Lab2\Code\DeploymentFiles\Scripts

& '.\Configure Distributed Cache.ps1' -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-sp-serviceapp-dev**.\
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
> When prompted for the service account, specify **EXTRANET\\s-sp-serviceapp-dev**.

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

1. Edit the MMS properties to temporarily change the database name (**ManagedMetadataService_tmp**).
2. Edit the MMS properties to revert to the restored database (**ManagedMetadataService**).
3. Reset IIS.
4. Delete temporary database (**ManagedMetadataService_tmp**).

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

CREATE USER [EXTRANET\s-sp-farm-dev] FOR LOGIN [EXTRANET\s-sp-farm-dev]

ALTER ROLE [db_owner] ADD MEMBER [EXTRANET\s-sp-farm-dev]
GO

USE [UserProfileService_Social]
GO

CREATE USER [EXTRANET\s-sp-farm-dev] FOR LOGIN [EXTRANET\s-sp-farm-dev]

ALTER ROLE [db_owner] ADD MEMBER [EXTRANET\s-sp-farm-dev]
GO

USE [UserProfileService_Sync]
GO

CREATE USER [EXTRANET\s-sp-farm-dev] FOR LOGIN [EXTRANET\s-sp-farm-dev]

ALTER ROLE [db_owner] ADD MEMBER [EXTRANET\s-sp-farm-dev]
GO
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

```Console
cls
```

#### # Create the User Profile Service Application

# Create User Profile Service Application as EXTRANET\\s-sp-farm-dev:

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

**PowerShell -- running as EXTRANET\\s-sp-farm-dev**

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
net localgroup Administrators /add EXTRANET\s-sp-farm-dev

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

# Import MIIS encryption key as EXTRANET\\s-sp-farm-dev:

```PowerShell
$farmCredential = Get-Credential (Get-SPFarm).DefaultServiceAccount.Name

Start-Process $PSHOME\powershell.exe `
    -Credential $farmCredential `
    -ArgumentList "-Command Start-Process cmd.exe -Verb Runas" `
    -Wait
```

---

**Command Prompt -- running as EXTRANET\\s-sp-farm-dev**

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
net localgroup Administrators /delete EXTRANET\s-sp-farm-dev

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

#### # Create the Search Service Application

```PowerShell
& '.\Configure SharePoint Search.ps1' -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-sp-crawler-dev**.\
> Expect the previous operation to complete in approximately 5-6 minutes.

#### Modify search topology

(skipped)

#### # Configure people search in SharePoint

```PowerShell
$mySiteHostLocation = "http://client-local.securitasinc.com/sites/my"

$searchApp = Get-SPEnterpriseSearchServiceApplication `
    -Identity "Search Service Application"
```

##### # Grant permissions to default content access account

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

##### # Create content source for crawling user profiles

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

#### # Configure the search crawl schedules

##### # Configure crawl schedule for "Local SharePoint sites"

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

##### # Configure crawl schedule for "User profiles"

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

```PowerShell
cls
```

#### # DEV - Configure performance level for the search crawl component

```PowerShell
Set-SPEnterpriseSearchService -PerformanceLevel Reduced

Restart-Service SPSearchHostController
```

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
$vmName = "EXT-FOOBAR4"

Stop-VM -ComputerName $vmHost -Name $vmName

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName $checkpointName

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Get latest version of Client Portal solution and build WSP packages

---

**Developer Command Prompt for VS2013 - Run as administrator**

```Console
tf get C:\NotBackedUp\Securitas\ClientPortal\Dev\Lab2 /recursive /force
tf get "$/Securitas ClientPortal/Main/Code/Securitas.Portal.ruleset" /force
cd C:\NotBackedUp\Securitas\ClientPortal\Dev\Lab2\Code
msbuild SecuritasClientPortal.sln /p:IsPackaging=true
```

---

```Console
cd C:\NotBackedUp\Securitas\ClientPortal\Dev\Lab2\Code\DeploymentFiles\Scripts
```

### # Create the Web application

```PowerShell
& '.\Create Web Application.ps1' -Verbose
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
$build = "3.0.648.0"

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

##### # Remove SecuritasConnect v3.0 solution

```PowerShell
$build = "3.0.648.0"

cd C:\NotBackedUp\Builds\Securitas\ClientPortal\$build\DeploymentFiles\Scripts

& '.\Deactivate Features.ps1'

& '.\Retract Solutions.ps1'

& '.\Delete Solutions.ps1'
```

```PowerShell
cls
```

### # Configure machine key for Web application

```PowerShell
cd C:\NotBackedUp\Securitas\ClientPortal\Dev\Lab2\Code\DeploymentFiles\Scripts

& '.\Configure Machine Key.ps1' -Verbose
```

### # Configure object cache user accounts

```PowerShell
& '.\Configure Object Cache User Accounts.ps1' -Verbose

iisreset
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
$cred1 = Get-Credential "EXTRANET\s-web-client-dev"

$cred2 = Get-Credential "TECHTOOLBOX\svc-sp-ups"

$peoplePickerCredentials = $cred1, $cred2

& '.\Configure People Picker Forests.ps1' `
    -ServiceCredentials $peoplePickerCredentials `
    -Confirm:$false `
    -Verbose
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

### Configure My Site settings in User Profile service application

(skipped -- since the expected value is set by database restore)

## Deploy the SecuritasConnect solution

---

**Developer Command Prompt for VS2013 - Run as administrator**

### REM DEV - Build Visual Studio solution and package SharePoint projects

```Console
cd C:\NotBackedUp\Securitas\ClientPortal\Dev\Lab2\Code
msbuild SecuritasClientPortal.sln /p:IsPackaging=true
```

---

```PowerShell
cls
```

### # Create and configure the SecuritasPortal database

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

CREATE USER [EXTRANET\s-sp-farm-dev] FOR LOGIN [EXTRANET\s-sp-farm-dev]
GO
ALTER ROLE [aspnet_Membership_BasicAccess] ADD MEMBER [EXTRANET\s-sp-farm-dev]
GO
ALTER ROLE [aspnet_Membership_ReportingAccess] ADD MEMBER [EXTRANET\s-sp-farm-dev]
GO
ALTER ROLE [aspnet_Roles_BasicAccess] ADD MEMBER [EXTRANET\s-sp-farm-dev]
GO
ALTER ROLE [aspnet_Roles_ReportingAccess] ADD MEMBER [EXTRANET\s-sp-farm-dev]
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

& '.\Add Event Log Sources.ps1' -Verbose
```

### # Configure claims-based authentication

```PowerShell
Push-Location "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\WebServices\SecurityToken"

copy .\web.config ".\web - Copy.config"

notepad web.config
```

---

**Web.config**

```XML
  <connectionStrings>
    <add
      name="SecuritasPortal"
      connectionString="Server=.;Database=SecuritasPortal;Integrated Security=true" />
  </connectionStrings>

  <system.web>
    <membership>
      <providers>
        <add
          name="SecuritasSqlMembershipProvider"
          type="System.Web.Security.SqlMembershipProvider, System.Web, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a"
          applicationName="Securitas Portal"
          connectionStringName="SecuritasPortal"
          passwordFormat="Hashed" />
      </providers>
    </membership>
    <roleManager>
      <providers>
        <add
          name="SecuritasSqlRoleProvider"
          type="System.Web.Security.SqlRoleProvider, System.Web, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a"
          applicationName="Securitas Portal"
          connectionStringName="SecuritasPortal" />
      </providers>
    </roleManager>
  </system.web>
```

---

```PowerShell
Pop-Location
```

```PowerShell
cls
```

### # Upgrade core site collections

```PowerShell
$webAppUrl = "http://client-local.securitasinc.com"

@("/" , "/sites/cc", "/sites/my", "/sites/Search") |
    ForEach-Object {
        Upgrade-SPSite ($webAppUrl + $_) -VersionUpgrade -Unthrottled
    }
```

```PowerShell
cls
```

### # Install SecuritasConnect solutions and activate the features

#### # Deploy v4.0 solutions

```PowerShell
& '.\Add Solutions.ps1' -Verbose

& '.\Deploy Solutions.ps1' -Verbose

& '.\Activate Features.ps1' -Verbose
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

#### Grant Branch Managers permissions to the C&C landing site

(skipped)

```PowerShell
cls
```

#### # Hide the Search navigation item on the C&C landing site

```PowerShell
Start-Process "http://client-local.securitasinc.com/sites/cc"
```

```PowerShell
cls
```

#### # Configure the search settings for the C&C landing site

```PowerShell
Start-Process "http://client-local.securitasinc.com/sites/cc"
```

### Configure Google Analytics on the SecuritasConnect Web application

Tracking ID: **UA-25949832-4**

{Begin skipped sections}

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

### # Upgrade C&C site collections

```PowerShell
$webAppUrl = "http://client-local.securitasinc.com"

@("/sites/A123-Systems",
    "/sites/ABC-Company",
    "/sites/DCM-Group",
    "/sites/TE-Connectivity",
    "/sites/Talha-Connect-Test") |
    ForEach-Object {
        $siteUrl = $webAppUrl + $_

        Write-Host "Upgrading site ($siteUrl)..."

        Upgrade-SPSite $siteUrl -VersionUpgrade -Unthrottled

        Disable-SPFeature `
            -Identity Securitas.Portal.Web_SecuritasDefaultMasterPage `
            -Url $siteUrl `
            -Confirm:$false

        Disable-SPFeature `
            -Identity Securitas.Portal.Web_PublishingLayouts `
            -Url $siteUrl `
            -Confirm:$false

        Enable-SPFeature `
            -Identity Securitas.Portal.Web_PublishingLayouts `
            -Url $siteUrl

        Enable-SPFeature `
            -Identity Securitas.Portal.Web_SecuritasDefaultMasterPage `
            -Url $siteUrl
    }
```

```PowerShell
cls
```

## # Configure Web application policy for SharePoint administrators group

```PowerShell
Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

$groupName = "EXTRANET\SharePoint Admins (DEV)"

$principal = New-SPClaimsPrincipal -Identity $groupName `
    -IdentityType WindowsSecurityGroupName

$claim = $principal.ToEncodedString()

$webApp = Get-SPWebApplication http://client-local.securitasinc.com

$policyRole = $webApp.PolicyRoles.GetSpecialRole(
    [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl)

$policy = $webApp.Policies.Add($claim, $groupName)
$policy.PolicyRoleBindings.Add($policyRole)

$webApp.Update()
```

## Backup Cloud Portal in SharePoint 2010 environment

---

**EXT-FOOBAR - SQL Server Management Studio**

```Console
DECLARE @backupPath NVARCHAR(255) =
    N'Z:\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Backup'

DECLARE @backupFilePath NVARCHAR(255)

-- Backup content database for Cloud Portal Web application

SET @backupFilePath = @backupPath + N'\WSS_Content_CloudPortal.bak'

BACKUP DATABASE [WSS_Content_CloudPortal]
TO DISK = @backupFilePath
WITH NOFORMAT, NOINIT
    , NAME = N'WSS_Content_CloudPortal-Full Database Backup'
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

```PowerShell
cls
```

## # Create and configure the Cloud Portal Web application

### # Set environment variables

```PowerShell
[Environment]::SetEnvironmentVariable(
  "SECURITAS_CLOUD_PORTAL_URL",
  "http://cloud-local.securitasinc.com",
  "Machine")
```

> **Important**
>
> Restart PowerShell for environment variable to take effect.

### Copy Cloud Portal build to SharePoint server

---

**Developer Command Prompt for VS2013 - Run as administrator**

```Console
tf get C:\NotBackedUp\Securitas\CloudPortal\Dev\Lab2 /recursive /force
tf get "$/Securitas CloudPortal/Main/Code/Securitas.Portal.ruleset" /force
```

---

### # Create the Web application

```PowerShell
cd C:\NotBackedUp\Securitas\CloudPortal\Dev\Lab2\Code\DeploymentFiles\Scripts

& '.\Create Web Application.ps1' -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-web-cloud-dev**.

```PowerShell
cls
```

### # Restore content database or create initial site collections

#### # Restore content database

##### # Remove content database created with Web application

```PowerShell
Remove-SPContentDatabase WSS_Content_CloudPortal -Confirm:$false -Force
```

##### # Restore database backup

```PowerShell
$sqlcmd = @"
DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\'
    + 'WSS_Content_CloudPortal.bak'

DECLARE @dataFilePath VARCHAR(255) =
  'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'WSS_Content_CloudPortal.mdf'

DECLARE @logFilePath VARCHAR(255) =
  'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'WSS_Content_CloudPortal_log.LDF'

RESTORE DATABASE WSS_Content_CloudPortal
  FROM DISK = @backupFilePath
  WITH FILE = 1,
    MOVE 'WSS_Content_CloudPortal' TO @dataFilePath,
    MOVE 'WSS_Content_CloudPortal_log' TO @logFilePath,
    NOUNLOAD,
    STATS = 5
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

```PowerShell
cls
```

##### # Install Cloud Portal v1.0 solution

```PowerShell
net use \\ICEMAN\Builds /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$build = "1.0.111.0"

robocopy `
    \\ICEMAN\Builds\Securitas\CloudPortal\$build `
    C:\NotBackedUp\Builds\Securitas\CloudPortal\$build /E

cd C:\NotBackedUp\Builds\Securitas\CloudPortal\$build\DeploymentFiles\Scripts

& '.\Add Solutions.ps1'

& '.\Deploy Solutions.ps1'
```

```PowerShell
cls
```

##### # Test content database

```PowerShell
Test-SPContentDatabase `
    -Name WSS_Content_CloudPortal `
    -WebApplication http://cloud-local.securitasinc.com
```

```PowerShell
cls
```

##### # Attach content database

```PowerShell
Mount-SPContentDatabase `
    -Name WSS_Content_CloudPortal `
    -WebApplication http://cloud-local.securitasinc.com
```

```PowerShell
cls
```

##### # Remove Cloud Portal v1.0 solution

```PowerShell
$build = "1.0.111.0"

cd C:\NotBackedUp\Builds\Securitas\CloudPortal\$build\DeploymentFiles\Scripts

& '.\Deactivate Features.ps1'

& '.\Retract Solutions.ps1'

& '.\Delete Solutions.ps1'
```

```PowerShell
cls
```

### # Configure object cache user accounts

```PowerShell
cd C:\NotBackedUp\Securitas\CloudPortal\Dev\Lab2\Code\DeploymentFiles\Scripts

& '.\Configure Object Cache User Accounts.ps1' -Verbose

iisreset
```

```PowerShell
cls
```

### # Configure the People Picker to support searches across one-way trusts

#### # Specify the credentials for accessing the trusted forest

```PowerShell
$cred1 = Get-Credential "EXTRANET\s-web-cloud-dev"

$cred2 = Get-Credential "TECHTOOLBOX\svc-sp-ups"

$cred3 = Get-Credential "FABRIKAM\s-sp-ups"

& '.\Configure People Picker Forests.ps1' `
    -ServiceCredentials $cred1, $cred2, $cred3 `
    -Confirm:$false `
    -Verbose
```

### Expand content database files

(skipped)

### DEV - Map Web application to loopback address in Hosts file

(skipped)

### Allow specific host names mapped to 127.0.0.1

(skipped)

### Configure SSL on the Internet zone

(skipped)

### Enable anonymous access to the site

(skipped)

```PowerShell
cls
```

### # Configure claims-based authentication

#### # Add Web.config modifications for claims-based authentication

```PowerShell
Push-Location C:\inetpub\wwwroot\wss\VirtualDirectories\cloud-local.securitasinc.com80

Copy-Item Web.config "Web - Copy.config"

#Notepad Web.config
#copy .\web.config 'C:\NotBackedUp\Temp\web - cloud-local.securitasinc.com.config'

C:\NotBackedUp\Public\Toolbox\DiffMerge\DiffMerge.exe `
    'C:\NotBackedUp\Temp\web - cloud-local.securitasinc.com.config' `
    .\web.config
```

**{copy/paste Web.config entries from browser -- to avoid issue when copy/pasting from OneNote}**

```PowerShell
Pop-Location
```

#### Validate claims authentication configuration

(skipped)

### Enable disk-based caching for the Web application

(skipped)

### Configure SharePoint groups

(skipped)

## Deploy the Cloud Portal solution

---

**Developer Command Prompt for VS2013 - Run as administrator**

### REM DEV - Build Visual Studio solution and package SharePoint projects

```Console
tf get C:\NotBackedUp\Securitas\CloudPortal\Dev\Lab2 /recursive /force
tf get "$/Securitas CloudPortal/Main/Code/Securitas.Portal.ruleset" /force
cd C:\NotBackedUp\Securitas\CloudPortal\Dev\Lab2\Code
msbuild Securitas.CloudPortal.sln /p:IsPackaging=true
```

---

```Console
cls
```

### TODO: # Configure the SecuritasPortal database

```PowerShell
$sqlcmd = @"
```

#### -- Configure permissions for the SecuritasPortal database

```Console
USE [SecuritasPortal]
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
cd C:\NotBackedUp\Securitas\CloudPortal\Dev\Lab2\Code\DeploymentFiles\Scripts

& '.\Add Event Log Sources.ps1' -Verbose
```

```PowerShell
cls
```

### # Upgrade core site collections

```PowerShell
$webAppUrl = "http://cloud-local.securitasinc.com"

@("/") |
    ForEach-Object {
        Upgrade-SPSite ($webAppUrl + $_) -VersionUpgrade -Unthrottled
    }
```

### # Install Cloud Portal solutions and activate the features

#### # Deploy v2.0 solutions

```PowerShell
& '.\Add Solutions.ps1' -Verbose

& '.\Deploy Solutions.ps1' -Verbose

& '.\Activate Features.ps1' -Verbose
```

### Create and configure the custom sign-in page

#### Create the custom sign-in page

(skipped)

#### Configure the custom sign-in page on the Web application

/Pages/Sign-In.aspx

```PowerShell
cls
```

### # Configure the search settings for the Cloud Portal

#### # Hide the Search navigation item on the Cloud Portal top-level site

```PowerShell
Start-Process "http://client-local.securitasinc.com/sites/cc"
```

```PowerShell
cls
```

#### # Configure the search settings for the Cloud Portal top-level site

```PowerShell
Start-Process "http://client-local.securitasinc.com/sites/cc"
```

### Configure redirect for single-site users

(skipped)

### Configure "Online Provisioning"

(skipped)

### Configure Google Analytics on the Cloud Portal Web application

Tracking ID: **UA-25949832-5**

{Begin skipped sections}

## Create and configure C&C site collections

### Create "Collaboration & Community" site collection

### Apply the "Securitas Client Site" template to the top-level site

### Modify the site title, description, and logo

### Update the C&C site home page

### Create a team collaboration site (optional)

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

$claim = $principal.ToEncodedString()

$webApp = Get-SPWebApplication http://cloud-local.securitasinc.com

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

```PowerShell
cls
```

## # Rebuild Web application

#### # Specify the credentials for accessing the trusted forest

```PowerShell
$cred1 = Get-Credential "EXTRANET\s-web-client-dev"

$cred2 = Get-Credential "TECHTOOLBOX\svc-sp-ups"

$peoplePickerCredentials = $cred1, $cred2

cd C:\NotBackedUp\Securitas\ClientPortal\Dev\Lab2\Code\DeploymentFiles\Scripts

& '.\Deactivate Features.ps1'

& '.\Retract Solutions.ps1'

& '.\Delete Solutions.ps1'

& '.\Delete Web Application.ps1' -Confirm:$false
```

```PowerShell
cls
```

### # Create the Web application

```PowerShell
& '.\Create Web Application.ps1' -Verbose
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

##### # Install SecuritasConnect v3.0 solution

```PowerShell
$build = "3.0.648.0"

cd C:\NotBackedUp\Builds\Securitas\ClientPortal\$build\DeploymentFiles\Scripts

& '.\Add Solutions.ps1'

& '.\Deploy Solutions.ps1'
```

##### # Test content database

```PowerShell
Test-SPContentDatabase `
    -Name WSS_Content_SecuritasPortal `
    -WebApplication http://client-local.securitasinc.com
```

##### # Attach content database

```PowerShell
Mount-SPContentDatabase `
    -Name WSS_Content_SecuritasPortal `
    -WebApplication http://client-local.securitasinc.com
```

##### # Remove SecuritasConnect v3.0 solution

```PowerShell
$build = "3.0.648.0"

cd C:\NotBackedUp\Builds\Securitas\ClientPortal\$build\DeploymentFiles\Scripts

& '.\Deactivate Features.ps1'

& '.\Retract Solutions.ps1'

& '.\Delete Solutions.ps1'
```

### # Configure machine key for Web application

```PowerShell
cd C:\NotBackedUp\Securitas\ClientPortal\Dev\Lab2\Code\DeploymentFiles\Scripts

& '.\Configure Machine Key.ps1' -Verbose
```

### # Configure object cache user accounts

```PowerShell
& '.\Configure Object Cache User Accounts.ps1' -Verbose

iisreset
```

### # Configure the People Picker to support searches across one-way trust

```PowerShell
& '.\Configure People Picker Forests.ps1' `
    -ServiceCredentials $peoplePickerCredentials `
    -Confirm:$false `
    -Verbose
```

### # Configure logging

```PowerShell
& '.\Add Event Log Sources.ps1' -Verbose
```

### # Upgrade core site collections

```PowerShell
$webAppUrl = "http://client-local.securitasinc.com"

@("/" , "/sites/cc", "/sites/my", "/sites/Search") |
    ForEach-Object {
        Upgrade-SPSite ($webAppUrl + $_) -VersionUpgrade -Unthrottled
    }
```

### # Install SecuritasConnect solutions and activate the features

#### # Deploy v4.0 solutions

```PowerShell
& '.\Add Solutions.ps1' -Verbose

& '.\Deploy Solutions.ps1' -Verbose

& '.\Activate Features.ps1' -Verbose
& '.\Activate Features.ps1' -Verbose
```

### # Configure trusted root authorities in SharePoint

```PowerShell
& '.\Configure Trusted Root Authorities.ps1' -Verbose
```

### # Configure Web application policy for SharePoint administrators group

```PowerShell
$groupName = "EXTRANET\SharePoint Admins (DEV)"

$principal = New-SPClaimsPrincipal -Identity $groupName `
    -IdentityType WindowsSecurityGroupName

$claim = $principal.ToEncodedString()

$webApp = Get-SPWebApplication http://client-local.securitasinc.com

$policyRole = $webApp.PolicyRoles.GetSpecialRole(
    [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl)

$policy = $webApp.Policies.Add($claim, $groupName)
$policy.PolicyRoleBindings.Add($policyRole)

$webApp.Update()
```

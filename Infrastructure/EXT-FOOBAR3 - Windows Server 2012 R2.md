# EXT-FOOBAR3 - Windows Server 2012 R2 Standard

Tuesday, July 26, 2016
8:03 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

Install SecuritasConnect v4.0

## Deploy and configure server infrastructure

### Copy Windows Server installation files to file share

(skipped)

### Install Windows Server 2012 R2

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "STORM"
$vmName = "EXT-FOOBAR3"
$vmPath = "E:\NotBackedUp\VMs"

$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 60GB `
    -MemoryStartupBytes 10GB `
    -SwitchName "Production"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 4 `
    -StaticMemory

Set-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path \\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso

Start-VM -ComputerName $vmHost -Name $vmName
```

---

#### Install custom Windows Server 2012 R2 image

- Start-up disk: [\\\\ICEMAN\\Products\\Microsoft\\MDT-Deploy-x86.iso](\\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso)
- On the **Task Sequence** step, select **Windows Server 2012 R2** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **EXT-FOOBAR3**.
  - Select **Join a workgroup**.
  - In the **Workgroup **box, type **WORKGROUP**.
  - Click **Next**.
- On the **Applications** step, ensure no items are selected and click **Next**.

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

#### Login as EXT-FOOBAR3\\foo

#### # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

#### # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

```PowerShell
cls
```

#### # Configure network settings

##### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select Name, InterfaceDescription

Get-NetAdapter `
    -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "Production"
```

##### # Configure "Production" network adapter

```PowerShell
$interfaceAlias = "Production"
```

###### # Disable DHCP

```PowerShell
@("IPv4", "IPv6") | ForEach-Object {
    $addressFamily = $_

    $interface = Get-NetAdapter $interfaceAlias |
        Get-NetIPInterface -AddressFamily $addressFamily

    If ($interface.Dhcp -eq "Enabled")
    {
        # Remove existing gateway
        $ipConfig = $interface | Get-NetIPConfiguration

        If ($ipConfig.Ipv4DefaultGateway -or $ipConfig.Ipv6DefaultGateway)
        {
            $interface |
                Remove-NetRoute -AddressFamily $addressFamily -Confirm:$false
        }

        # Disable DHCP
        $interface | Set-NetIPInterface -DHCP Disabled
    }
}
```

```PowerShell
cls
```

###### # Configure static IPv4 address

```PowerShell
$ipAddress = "192.168.10.217"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24 `
    -DefaultGateway 192.168.10.1
```

###### # Configure IPv4 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 192.168.10.209,192.168.10.210
```

###### # Configure static IPv6 address

```PowerShell
$ipAddress = "2601:282:4201:e500::217"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 64
```

###### # Configure IPv6 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 2601:282:4201:e500::209,2601:282:4201:e500::210
```

###### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping iceman.corp.technologytoolbox.com -f -l 8900
```

```PowerShell
cls
```

### # Join member server to domain

#### # Add computer to domain

```PowerShell
Add-Computer `
    -DomainName extranet.technologytoolbox.com `
    -Credential (Get-Credential EXTRANET\jjameson-admin) `
    -Restart
```

#### Move computer to "SharePoint Servers" OU

---

**EXT-DC01**

```PowerShell
$computerName = "EXT-FOOBAR3"
$targetPath = ("OU=SharePoint Servers,OU=Servers,OU=Resources,OU=Development" `
    + ",DC=extranet,DC=technologytoolbox,DC=com")

Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath

Restart-Computer $computerName

Restart-Computer : Failed to restart the computer EXT-FOOBAR3 with the following error message: Call was canceled by the message filter. (Exception from HRESULT: 0x80010002 (RPC_E_CALL_CANCELED)).
At line:1 char:1
+ Restart-Computer $computerName
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (EXT-FOOBAR3:String) [Restart-Computer], InvalidOperationException
    + FullyQualifiedErrorId : RestartcomputerFailed,Microsoft.PowerShell.Commands.RestartComputerCommand
```

---

### Login as EXTRANET\\setup-sharepoint-dev

### # Set MaxPatchCacheSize to 0 (Recommended)

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

## DEV - Configure VM storage, processors, and memory

| Disk | Drive Letter | Volume Size | VHD Type | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------- | -------------------- | ------------ |
| 0    | C:           | 50 GB       | Dynamic  | 4K                   | OSDisk       |
| 1    | D:           | 3 GB        | Dynamic  | 64K                  | Data01       |
| 2    | L:           | 1 GB        | Dynamic  | 64K                  | Log01        |
| 3    | T:           | 1 GB        | Dynamic  | 64K                  | Temp01       |
| 4    | Z:           | 10 GB       | Dynamic  | 4K                   | Backup01     |

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

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create Data01, Log01, Temp01, and Backup01 VHDs

```PowerShell
$vmHost = "STORM"
$vmName = "EXT-FOOBAR3"
$vmPath = "E:\NotBackedUp\VMs\$vmName"

$vhdPath = "$vmPath\Virtual Hard Disks\$vmName" `
    + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 3GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ControllerType SCSI `
    -Path $vhdPath

$vhdPath = "$vmPath\Virtual Hard Disks\$vmName" `
    + "_Log01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 1GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ControllerType SCSI `
    -Path $vhdPath

$vhdPath = "$vmPath\Virtual Hard Disks\$vmName" `
    + "_Temp01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 1GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ControllerType SCSI `
    -Path $vhdPath

$vhdPath = "$vmPath\Virtual Hard Disks\$vmName" `
    + "_Backup01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 10GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ControllerType SCSI `
    -Path $vhdPath
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

### Install latest service pack and updates

### Create service accounts

(skipped)

### Create Active Directory container to track SharePoint 2013 installations

(skipped)

### Install and configure SQL Server 2014

#### Install SQL Server 2014

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Mount SQL Server 2014 installation media

```PowerShell
$vmHost = "STORM"
$vmName = "EXT-FOOBAR3"

$imagePath = "\\ICEMAN\Products\Microsoft\SQL Server 2014" `
    + "\en_sql_server_2014_developer_edition_with_service_pack_2_x64_dvd_8967821.iso"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $imagePath
```

---

```PowerShell
cls
& X:\setup.exe
```

> **Important**
>
> Wait for the installation to complete.

```PowerShell
cls
```

#### # Configure permissions on \\Windows\\System32\\LogFiles\\Sum files

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

#### -- Configure TempDB data and log files

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

GO
```

#### -- Configure "Max Degree of Parallelism" for SharePoint

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

#### -- DEV - Change databases to Simple recovery model

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

GO
```

#### -- DEV - Constrain maximum memory for SQL Server

```SQL
EXEC sys.sp_configure N'show advanced options', N'1'
RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'max server memory (MB)', N'1024'
RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'show advanced options', N'0'
RECONFIGURE WITH OVERRIDE
GO
```

---

## Install SharePoint Server 2013

### Download SharePoint 2013 prerequisites to file share

(skipped)

```PowerShell
cls
```

### # Install SharePoint 2013 prerequisites on farm servers

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Mount SharePoint 2013 installation media

```PowerShell
$vmHost = "STORM"
$vmName = "EXT-FOOBAR3"

$imagePath = "\\ICEMAN\Products\Microsoft\SharePoint 2013\" `
    + "en_sharepoint_server_2013_with_sp1_x64_dvd_3823428.iso"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $imagePath
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
```

> **Important**
>
> Wait for the prerequisites to be installed. When prompted, restart the server to continue the installation.

```PowerShell
Remove-Item "C:\NotBackedUp\Temp\PrerequisiteInstallerFiles_SP1" -Recurse
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Checkpoint VM

```PowerShell
$vmHost = "STORM"
$vmName = "EXT-FOOBAR3"
$snapshotName = "Before - Install SharePoint Server 2013 on farm servers"

Stop-VM -ComputerName $vmHost -Name $vmName

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName $snapshotName

Start-VM -ComputerName $vmHost -Name $vmName
```

---

```PowerShell
cls
```

### # Install SharePoint Server 2013 on farm servers

```PowerShell
& X:\setup.exe
```

> **Important**
>
> Wait for the installation to complete.

```PowerShell
cls
```

### # Add SharePoint bin folder to PATH environment variable

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-PathFolders.ps1 `
    ("C:\Program Files\Common Files\Microsoft Shared\web server extensions" `
        + "\15\BIN") `
    -EnvironmentVariableTarget "Machine"
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Update VM snapshot

```PowerShell
$vmHost = "STORM"
$vmName = "EXT-FOOBAR3"

Stop-VM -ComputerName $vmHost -Name $vmName
```

#### # Delete previous VM snapshot

```PowerShell
Write-Host "Deleting snapshot..." -NoNewline

Remove-VMSnapshot -ComputerName $vmHost -VMName $vmName

Write-Host "Waiting a few seconds for merge to start..."
Start-Sleep -Seconds 5

while (Get-VM -ComputerName $vmHost -Name $vmName |
    Where Status -eq "Merging disks") {
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 5
}

Write-Host
```

```PowerShell
cls
```

#### # Create new VM snapshot

```PowerShell
$snapshotName = "Before - Install Cumulative Update for SharePoint Server 2013"

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName $snapshotName

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### # Install Cumulative Update for SharePoint Server 2013

#### # Download update

```PowerShell
net use \\ICEMAN\Products /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$patch = "15.0.4833.1000 - SharePoint 2013 June 2016 CU"

robocopy `
    "\\ICEMAN\Products\Microsoft\SharePoint 2013\Patches\$patch" `
    "C:\NotBackedUp\Temp\$patch" `
    /E
```

#### # Install update

```PowerShell
& "C:\NotBackedUp\Temp\$patch\*.exe"
```

> **Important**
>
> Wait for the update to be installed.

```Console
cls
Remove-Item "C:\NotBackedUp\Temp\$patch" -Recurse
```

### # Install Cumulative Update for AppFabric 1.1

#### # Download update

```PowerShell
$patch = "Cumulative Update 7"

robocopy `
    "\\ICEMAN\Products\Microsoft\AppFabric 1.1\Patches\$patch" `
    "C:\NotBackedUp\Temp\$patch" `
    /E
```

#### # Install update

```PowerShell
& "C:\NotBackedUp\Temp\$patch\*.exe"
```

> **Important**
>
> Wait for the update to be installed.

```Console
cls
Remove-Item "C:\NotBackedUp\Temp\$patch" -Recurse
```

#### # Enable non-blocking garbage collection for Distributed Cache Service

```PowerShell
Notepad ($env:ProgramFiles `
    + "\AppFabric 1.1 for Windows Server\DistributedCacheService.exe.config")
```

---

**DistributedCacheService.exe.config**

```XML
  <appSettings>
    <add key="backgroundGC" value="true"/>
  </appSettings>
```

---

```PowerShell
cls
```

## # Install and configure additional software

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

### DEV - Install Visual Studio 2015 with Update 3

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Mount Visual Studio 2015 with Update 3 installation media

```PowerShell
$vmHost = "STORM"
$vmName = "EXT-FOOBAR3"

$imagePath = "\\ICEMAN\Products\Microsoft\Visual Studio 2015" `
    + "\en_visual_studio_enterprise_2015_with_update_3_x86_x64_dvd_8923288.iso"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $imagePath
```

---

```PowerShell
& X:\vs_enterprise.exe
```

**Custom** installation option:

- **Microsoft Office Developer Tools**
- **Microsoft SQL Server Data Tools**
- **Microsoft Web Developer Tools**

### DEV - Enter product key for Visual Studio

1. Start Visual Studio.
2. On the **Help** menu, click **Register Product**.
3. In the **Sign in to Visual Studio** window, click **Unlock with a Product Key**.
4. In the **Enter a product key** window, type the product key and click **Apply**.
5. In the **Sign in to Visual Studio** window, click **Close**.

### DEV - Install update for Office developer tools in Visual Studio

> **Note**
>
> Add **[https://www.microsoft.com](https://www.microsoft.com)** to **Trusted sites** zone.

Update:** Microsoft Office Developer Tools Update 2 for Visual Studio 2015**\
File: **OfficeToolsForVS2015.3f.3fen.exe**

### DEV - Install update for SQL Server database projects in Visual Studio

> **Note**
>
> Add **[http://download.microsoft.com](http://download.microsoft.com)** to **Trusted sites** zone.

Update:** Microsoft SQL Server Data Tools (SSDT) Update**\
File: **SSDTSetup.exe**

> **Important**
>
> Wait for the installation to complete and restart the computer if prompted to do so.

### DEV - Install Productivity Power Tools for Visual Studio

### DEV - Install Microsoft Office 2016 (Recommended)

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Mount Office Professional Plus 2016 installation media

```PowerShell
$vmHost = "STORM"
$vmName = "EXT-FOOBAR3"

$imagePath = "\\ICEMAN\Products\Microsoft\Office 2016" `
    + "\en_office_professional_plus_2016_x86_x64_dvd_6962141.iso"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $imagePath
```

---

```Console
X:
.\setup.exe /AUTORUN
```

```Console
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

### DEV - Install Microsoft Visio 2016 (Recommended)

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Mount Visio Professional 2016 installation media

```PowerShell
$vmHost = "STORM"
$vmName = "EXT-FOOBAR3"

$imagePath = "\\ICEMAN\Products\Microsoft\Visio 2016" `
    + "\en_visio_professional_2016_x86_x64_dvd_6962139.iso"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $imagePath
```

---

```Console
X:
.\setup.exe /AUTORUN

C:
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Eject media from virtual DVD drive

```PowerShell
$vmHost = "STORM"
$vmName = "EXT-FOOBAR3"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

---

```PowerShell
cls
```

### # DEV - Install additional browsers and software (recommended)

#### # Install Mozilla Firefox

```PowerShell
& "\\ICEMAN\Products\Mozilla\Firefox\Firefox Setup 47.0.1.exe"
```

```PowerShell
cls
```

#### # Install Google Chrome

```PowerShell
& "\\ICEMAN\Products\Google\Chrome\ChromeStandaloneSetup64.exe"
```

```PowerShell
cls
```

#### # Install Adobe Reader

```PowerShell
& "\\ICEMAN\Products\Adobe\AdbeRdr830_en_US.msi"
```

> **Important**
>
> Wait for the software to be installed.

```PowerShell
& "\\ICEMAN\Products\Adobe\AdbeRdrUpd831_all_incr.msp"
```

### Install additional service packs and updates

> **Important**
>
> Wait for the updates to be installed and restart the server.

### # Clean up Windows Update files

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse
```

### # Enter product key and activate Windows

```PowerShell
slmgr /ipk {product key}
```

> **Note**
>
> When notified that the product key was set successfully, click **OK**.

```Console
slmgr /ato
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Update VM snapshot

```PowerShell
$vmHost = "STORM"
$vmName = "EXT-FOOBAR3"

Stop-VM -ComputerName $vmHost -Name $vmName
```

#### # Delete previous VM snapshot

```PowerShell
Write-Host "Deleting snapshot..." -NoNewline

Remove-VMSnapshot -ComputerName $vmHost -VMName $vmName

Write-Host "Waiting a few seconds for merge to start..."
Start-Sleep -Seconds 5

while (Get-VM -ComputerName $vmHost -Name $vmName |
    Where Status -eq "Merging disks") {
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 5
}

Write-Host
```

#### # Create new VM snapshot

```PowerShell
$snapshotName = "Before - Create and configure SharePoint farm"

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName $snapshotName

Start-VM -ComputerName $vmHost -Name $vmName
```

---

## # Create and configure SharePoint farm

### # Copy SecuritasConnect build to SharePoint server

```PowerShell
net use \\ICEMAN\Builds /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
robocopy `
    "\\ICEMAN\Builds\Securitas\ClientPortal\4.0.670.0" `
    "C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.670.0" `
    /E
```

### # Create SharePoint farm

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.670.0\DeploymentFiles\Scripts

$currentUser = whoami

If ($currentUser -eq 'EXTRANET\setup-sharepoint-dev')
{
    & '.\Create Farm.ps1' -CentralAdminAuthProvider NTLM -Verbose
}
Else
{
    Throw "Incorrect user"
}
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-sp-farm-dev**.\
> Expect the previous operation to complete in approximately 5-1/2 minutes.

### Add Web servers to SharePoint farm

(skipped)

### Add SharePoint Central Administration to "Local intranet" zone

(skipped -- since the "Create Farm.ps1" script configures this)

**TODO**: Add the following to install guide

```PowerShell
cls
```

### # Configure PowerShell access for SharePoint administrators group

```PowerShell
Get-SPDatabase |
    Where-Object {$_.WebApplication -like "SPAdministrationWebApplication"} |
    Add-SPShellAdmin "EXTRANET\SharePoint Admins (DEV)"
```

###
# Grant permissions on DCOM applications for SharePoint

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.670.0\DeploymentFiles\Scripts

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

#### # Configure SharePoint 2013 farm to use Office Web Apps

```PowerShell
New-SPWOPIBinding -ServerName wac.fabrikam.com

Set-SPWOPIZone -zone "external-https"
```

#### # Configure name resolution on Office Web Apps farm

---

**EXT-WAC02A**

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    -IPAddress 192.168.10.217 `
    -Hostnames EXT-FOOBAR3, client-local-3.securitasinc.com
```

---

## Backup SharePoint 2010 environment

(skipped)

```PowerShell
cls
```

## # Configure SharePoint services and service applications

### # Change service account for Distributed Cache

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.670.0\DeploymentFiles\Scripts

& '.\Configure Distributed Cache.ps1' -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-sp-serviceapp-dev**.\
> Expect the previous operation to complete in approximately 7-8 minutes.

```PowerShell
cls
```

### # DEV - Constrain Distributed Cache

```PowerShell
Update-SPDistributedCacheSize -CacheSizeInMB 400
```

### # Configure State Service

```PowerShell
& '.\Configure State Service.ps1' -Verbose
```

### # Configure SharePoint ASP.NET Session State service

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

### Configure Managed Metadata Service

#### Restore database backup from SharePoint 2010 Managed Metadata Service

(skipped)

```PowerShell
cls
```

#### # Create Managed Metadata Service

```PowerShell
& '.\Configure Managed Metadata Service.ps1' -Confirm:$false -Verbose
```

### Configure User Profile Service Application

#### Restore database backup from SharePoint 2010 User Profile Service Application

(skipped)

```PowerShell
cls
```

#### # Create User Profile Service Application

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
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.670.0\DeploymentFiles\Scripts

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

**TODO**: Add step to installation guide to remove permissions to create personal sites

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
$farmAccount = (Get-SPFarm).DefaultServiceAccount.Name

net localgroup Administrators /add $farmAccount

Restart-Service SPTimerV4
```

#### Start User Profile Synchronization Service

#### Import MIIS encryption key

(skipped)

#### Wait for User Profile Synchronization Service to finish starting

> **Important**
>
> Wait until the status of **User Profile Synchronization Service** shows **Started** before proceeding.

```PowerShell
cls
```

#### # Remove SharePoint farm account from local Administrators group

```PowerShell
$farmAccount = (Get-SPFarm).DefaultServiceAccount.Name

net localgroup Administrators /delete $farmAccount

Restart-Service SPTimerV4
```

#### Configure synchronization connections and import data from Active Directory

| **Connection Name** | **Forest Name**            | **Account Name**        |
| ------------------- | -------------------------- | ----------------------- |
| TECHTOOLBOX         | corp.technologytoolbox.com | TECHTOOLBOX\\svc-sp-ups |
| FABRIKAM            | corp.fabrikam.com          | FABRIKAM\\s-sp-ups      |

```PowerShell
cls
```

### # Create and configure Search Service Application

#### # Create Search Service Application

```PowerShell
& '.\Configure SharePoint Search.ps1' -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-sp-crawler-dev**.\
> Expect the previous operation to complete in approximately 5-6 minutes.

```PowerShell
cls
```

#### # Pause Search Service Application

```PowerShell
Get-SPEnterpriseSearchServiceApplication "Search Service Application" |
    Suspend-SPEnterpriseSearchServiceApplication
```

#### # Configure people search in SharePoint

##### # Grant permissions to default content access account

```PowerShell
$searchApp = Get-SPEnterpriseSearchServiceApplication `
    -Identity "Search Service Application"

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
$startAddress = "sps3://client-local-3.securitasinc.com"

$searchApp = Get-SPEnterpriseSearchServiceApplication `
    -Identity "Search Service Application"

New-SPEnterpriseSearchCrawlContentSource `
    -SearchApplication $searchapp `
    -Type SharePoint `
    -Name "User profiles" `
    -StartAddresses $startAddress
```

#### # Configure search crawl schedules

```PowerShell
$searchApp = Get-SPEnterpriseSearchServiceApplication `
    -Identity "Search Service Application"
```

##### # Enable continuous crawls for "Local SharePoint sites"

```PowerShell
$searchApp = Get-SPEnterpriseSearchServiceApplication `
    -Identity "Search Service Application"

$contentSource = Get-SPEnterpriseSearchCrawlContentSource `
    -SearchApplication $searchApp `
    -Identity "Local SharePoint sites"

Set-SPEnterpriseSearchCrawlContentSource `
    -Identity $contentSource `
    -EnableContinuousCrawls $true
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
    -CrawlScheduleStartDateTime "11:00 PM" `
    -CrawlScheduleDaysOfWeek Saturday `
    -CrawlScheduleRunEveryInterval 1

Set-SPEnterpriseSearchCrawlContentSource `
    -Identity $contentSource `
    -ScheduleType Incremental `
    -DailyCrawlSchedule `
    -CrawlScheduleStartDateTime "4:00 AM"
```

#### # DEV - Configure performance level for search crawl component

```PowerShell
Set-SPEnterpriseSearchService -PerformanceLevel Reduced

Restart-Service SPSearchHostController
```

```PowerShell
cls
```

## # Create and configure Web application

### # Set environment variables

```PowerShell
[Environment]::SetEnvironmentVariable(
  "SECURITAS_CLIENT_PORTAL_URL",
  "http://client-local-3.securitasinc.com",
  "Machine")

[Environment]::SetEnvironmentVariable(
  "SECURITAS_BUILD_CONFIGURATION",
  "Debug",
  "Machine")

exit
```

> **Important**
>
> Restart PowerShell for environment variables to take effect.

### # Add URL for SecuritasConnect website to "Local intranet" zone

```PowerShell
[Uri] $url = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL

[string[]] $domainParts = $url.Host -split '\.'

[string] $subdomain = $domainParts[0]
[string] $domain = $domainParts[1..2] -join '.'

[string] $registryKey = ("HKCU:\Software\Microsoft\Windows" `
    + "\CurrentVersion\Internet Settings\ZoneMap\EscDomains" `
    + "\$domain")

If ((Test-Path $registryKey) -eq $false)
{
    New-Item $registryKey | Out-Null
}

[string] $registryKey = $registryKey + "\$subdomain"

If ((Test-Path $registryKey) -eq $false)
{
    New-Item $registryKey | Out-Null
}

Set-ItemProperty -Path $registryKey -Name http -Value 1
```

### DEV - Snapshot VM

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Checkpoint VM

```PowerShell
$vmHost = "STORM"
$vmName = "EXT-FOOBAR3"
$snapshotName = "Baseline SharePoint Server 2013 configuration"

Stop-VM -ComputerName $vmHost -Name $vmName

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName $snapshotName

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### # Create Web application

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.670.0\DeploymentFiles\Scripts

& '.\Create Web Application.ps1' -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-web-client-dev**.\
> Expect the previous operation to complete in approximately 1 minute.

### Restore content database or create initial site collections

#### Restore content database

(skipped)

```PowerShell
cls
```

#### # Create initial site collections

```PowerShell
& '.\Create Site Collections.ps1' -Verbose
```

### # Configure machine key for Web application

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.670.0\DeploymentFiles\Scripts

& '.\Configure Machine Key.ps1' -Verbose
```

### # Configure object cache user accounts

```PowerShell
& '.\Configure Object Cache User Accounts.ps1' -Verbose

iisreset
```

### # Configure People Picker to support searches across one-way trust

#### # Set application password used for encrypting credentials

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

#### # Specify credentials for accessing trusted forest

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

#### # Modify permissions on registry key where encrypted credentials are stored

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

```PowerShell
cls
```

### # Configure Web application policy for SharePoint administrators group

```PowerShell
$webAppUrl = $env:SECURITAS_CLIENT_PORTAL_URL
$adminsGroup = "EXTRANET\SharePoint Admins (DEV)"

$principal = New-SPClaimsPrincipal -Identity $adminsGroup `
    -IdentityType WindowsSecurityGroupName

$claim = $principal.ToEncodedString()

$webApp = Get-SPWebApplication $webAppUrl

$policyRole = $webApp.PolicyRoles.GetSpecialRole(
    [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl)

$policy = $webApp.Policies.Add($claim, $adminsGroup)
$policy.PolicyRoleBindings.Add($policyRole)

$webApp.Update()
```

### Configure My Site settings in User Profile Service Application

**[http://client-local-3.securitasinc.com/sites/my](http://client-local-3.securitasinc.com/sites/my)**

## Deploy SecuritasConnect solution

### DEV - Build Visual Studio solution and package SharePoint projects

(skipped)

```PowerShell
cls
```

### # Create and configure SecuritasPortal database

#### # Create SecuritasPortal database

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.670.0\BusinessModel\Database\Deployment

.\Install.cmd
```

### # Configure logging

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.670.0\DeploymentFiles\Scripts

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

```Console
cls
Pop-Location
```

### # Upgrade core site collections

```PowerShell
$webAppUrl = $env:SECURITAS_CLIENT_PORTAL_URL

@("/" , "/sites/cc", "/sites/my", "/sites/Search") |
    ForEach-Object {
        Upgrade-SPSite ($webAppUrl + $_) -VersionUpgrade -Unthrottled
    }
```

### # Install SecuritasConnect solutions and activate features

#### # Deploy v4.0 solutions

```PowerShell
& '.\Add Solutions.ps1' -Verbose

& '.\Deploy Solutions.ps1' -Verbose

& '.\Activate Features.ps1' -Verbose
```

> **Note**
>
> Expect the previous operation to complete in approximately 4-1/2 minutes.

```PowerShell
cls
```

#### # Activate "Securitas - Application Settings" feature

```PowerShell
Start-Process "$env:SECURITAS_CLIENT_PORTAL_URL/"
```

```PowerShell
cls
```

### # Import template site content

```PowerShell
& '.\Import Template Site Content.ps1'
```

> **Note**
>
> Expect the previous operation to complete in approximately 4-1/2 minutes.

### Create users in SecuritasPortal database

#### Create users for Securitas clients

| **User**   | **E-mail**                       |
| ---------- | -------------------------------- |
| test-abc1  | test-abc1@technologytoolbox.com  |
| test-lite1 | test-lite1@technologytoolbox.com |

#### Create users for Securitas Branch Managers

| **User** | **E-mail**                     |
| -------- | ------------------------------ |
| test-bm1 | test-bm1@technologytoolbox.com |

#### Associate client users to Branch Managers

(skipped -- since the demo client users are already associated with the demo Branch Manager user)

```PowerShell
cls
```

### # Configure trusted root authorities in SharePoint

```PowerShell
& '.\Configure Trusted Root Authorities.ps1'
```

```PowerShell
cls
```

### # Configure application settings (e.g. Web service URLs)

```PowerShell
net use \\ICEMAN\Archive /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
.\Get-AppSetting.ps1 |
    Sort-Object Key |
    Export-Csv C:\NotBackedUp\Temp\AppSettings.csv

C:\NotBackedUp\Public\Toolbox\DiffMerge\DiffMerge.exe `
    \\ICEMAN\Archive\Clients\Securitas\AppSettings-UAT_2016-04-19.csv `
    C:\NotBackedUp\Temp\AppSettings.csv
```

> **Note**
>
> Update CSV file to contain desired application settings .

```PowerShell
Import-Csv C:\NotBackedUp\Temp\AppSettings.csv |
    ForEach-Object {
        .\Set-AppSetting.ps1 $_.Key $_.Value $_.Description -Force -Verbose
    }
```

```PowerShell
cls
```

### # Configure SSO credentials for users

```PowerShell
Start-Process ("$env:SECURITAS_CLIENT_PORTAL_URL" `
    + "/_layouts/Securitas/EditProfile.aspx")
```

> **Note**
>
> Login as **test-abc1**.and set the passwords for **CapSure**, **Iverify**, **PatrolLIVE**, and **TrackTik**.

```PowerShell
cls
```

### # Configure C&C landing site

#### # Grant Branch Managers permissions to C&C landing site

```PowerShell
$site = Get-SPSite ($env:SECURITAS_CLIENT_PORTAL_URL + "/sites/cc")
$group = $site.RootWeb.SiteGroups["Collaboration & Community Visitors"]
$group.AddUser(
    "c:0-.f|securitassqlroleprovider|branch managers",
    $null,
    "Branch Managers",
    $null)

$claim = New-SPClaimsPrincipal -Identity "Branch Managers" `
    -IdentityType WindowsSecurityGroupName

$branchManagersUser = $site.RootWeb.EnsureUser($claim.ToEncodedString())
$group.AddUser($branchManagersUser)
$site.Dispose()
```

#### Hide Search navigation item on C&C landing site

(skipped -- since SharePoint 2013 does not create a Search subsite)

```PowerShell
cls
```

#### # Configure search settings for C&C landing site

```PowerShell
Start-Process "$env:SECURITAS_CLIENT_PORTAL_URL/sites/cc"
```

### Configure Google Analytics on SecuritasConnect Web application

Tracking ID: **UA-25949832-4**

### Upgrade C&C site collections

(skipped -- since no C&C site collections have been created

### Defragment SharePoint databases

### Change recovery model for content database to Full

(skipped)

### Configure SQL Server backups

(skipped)

### Resume Search Service Application and start full crawl of all content sources

(skipped)

{Begin skipped sections}

## Create and configure C&C site collections

### Create site collection for Securitas client

### Apply "Securitas Client Site" template to top-level site

### Modify site title, description, and logo

### Update client site home page

### Create blog site (optional)

### Create wiki site (optional)

{End skipped sections}

Install Cloud Portal v2.0

## Backup SharePoint 2010 environment

(skipped)

```PowerShell
cls
```

## # Create and configure Cloud Portal Web application

### # Set environment variables

```PowerShell
[Environment]::SetEnvironmentVariable(
  "SECURITAS_CLOUD_PORTAL_URL",
  "http://cloud-local-3.securitasinc.com",
  "Machine")

exit
```

> **Important**
>
> Restart PowerShell for environment variable to take effect.

### # Add URL for Cloud Portal website to "Local intranet" zone

```PowerShell
[Uri] $url = [Uri] $env:SECURITAS_CLOUD_PORTAL_URL

[string[]] $domainParts = $url.Host -split '\.'

[string] $subdomain = $domainParts[0]
[string] $domain = $domainParts[1..2] -join '.'

[string] $registryKey = ("HKCU:\Software\Microsoft\Windows" `
    + "\CurrentVersion\Internet Settings\ZoneMap\EscDomains" `
    + "\$domain")

If ((Test-Path $registryKey) -eq $false)
{
    New-Item $registryKey | Out-Null
}

[string] $registryKey = $registryKey + "\$subdomain"

If ((Test-Path $registryKey) -eq $false)
{
    New-Item $registryKey | Out-Null
}

Set-ItemProperty -Path $registryKey -Name http -Value 1
```

### # Copy Cloud Portal build to SharePoint server

```PowerShell
net use \\ICEMAN\Builds /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
robocopy `
    "\\ICEMAN\Builds\Securitas\CloudPortal\2.0.118.0" `
    "C:\NotBackedUp\Builds\Securitas\CloudPortal\2.0.118.0" `
    /E
```

### # Create Web application

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\CloudPortal\2.0.118.0\DeploymentFiles\Scripts

& '.\Create Web Application.ps1' -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-web-cloud-dev**.\
> Expect the previous operation to complete in approximately 1 minute.

```PowerShell
cls
```

### # Install third-party SharePoint solutions

```PowerShell
net use \\ICEMAN\Products /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$tempPath = "C:\NotBackedUp\Temp\Boost Solutions"

robocopy `
    "\\ICEMAN\Products\Boost Solutions" `
    $tempPath /E

Push-Location $tempPath

Add-Type -assembly "System.Io.Compression.FileSystem"

$zipFile = Resolve-Path "ListCollectionSetup.zip"

mkdir ".\ListCollectionSetup"
$destination = Resolve-Path "ListCollectionSetup"

[Io.Compression.ZipFile]::ExtractToDirectory($zipFile, $destination)

cd $destination

& ".\Setup.exe"
```

> **Important**
>
> Wait for the installation to complete.

```Console
cls
Pop-Location

Remove-Item $tempPath -Recurse
```

### # Restore content database or create initial site collections

### # Create initial site collections

```PowerShell
& '.\Create Site Collections.ps1' -Verbose
```

### # Configure object cache user accounts

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\CloudPortal\2.0.118.0\DeploymentFiles\Scripts

& '.\Configure Object Cache User Accounts.ps1' -Verbose

iisreset
```

### # Configure People Picker to support searches across one-way trusts

#### # Specify credentials for accessing trusted forests

```PowerShell
$cred1 = Get-Credential "EXTRANET\s-web-cloud-dev"

$cred2 = Get-Credential "TECHTOOLBOX\svc-sp-ups"

$cred3 = Get-Credential "FABRIKAM\s-sp-ups"

& '.\Configure People Picker Forests.ps1' `
    -ServiceCredentials $cred1, $cred2, $cred3 `
    -Confirm:$false `
    -Verbose
```

### DEV - Map Web application to loopback address in Hosts file

(skipped)

### Allow specific host names mapped to 127.0.0.1

(skipped)

### Configure SSL on Internet zone

(skipped)

```PowerShell
cls
```

### # Enable anonymous access to website

```PowerShell
& '.\Enable Anonymous Access.ps1' -Verbose
```

### Enable disk-based caching for Web application

(skipped)

```PowerShell
cls
```

### # Configure Web application policy for SharePoint administrators group

```PowerShell
$webAppUrl = $env:SECURITAS_CLOUD_PORTAL_URL
$adminsGroup = "EXTRANET\SharePoint Admins (DEV)"

$principal = New-SPClaimsPrincipal -Identity $adminsGroup `
    -IdentityType WindowsSecurityGroupName

$claim = $principal.ToEncodedString()

$webApp = Get-SPWebApplication $webAppUrl

$policyRole = $webApp.PolicyRoles.GetSpecialRole(
    [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl)

$policy = $webApp.Policies.Add($claim, $adminsGroup)
$policy.PolicyRoleBindings.Add($policyRole)

$webApp.Update()
```

### # Configure SharePoint groups

```PowerShell
Start-Process "$env:SECURITAS_CLOUD_PORTAL_URL/"
```

## Deploy Cloud Portal solution

### DEV - Build Visual Studio solution and package SharePoint projects

(skipped)

```PowerShell
cls
```

### # Configure permissions for SecuritasPortal database

```PowerShell
$sqlcmd = @"
USE [SecuritasPortal]
GO

CREATE USER [EXTRANET\s-web-cloud-dev] FOR LOGIN [EXTRANET\s-web-cloud-dev]
GO
ALTER ROLE [aspnet_Membership_FullAccess] ADD MEMBER [EXTRANET\s-web-cloud-dev]
GO
ALTER ROLE [aspnet_Profile_BasicAccess] ADD MEMBER [EXTRANET\s-web-cloud-dev]
GO
ALTER ROLE [aspnet_Roles_BasicAccess] ADD MEMBER [EXTRANET\s-web-cloud-dev]
GO
ALTER ROLE [aspnet_Roles_ReportingAccess] ADD MEMBER [EXTRANET\s-web-cloud-dev]
GO
ALTER ROLE [Customer_Provisioner] ADD MEMBER [EXTRANET\s-web-cloud-dev]
GO
ALTER ROLE [Customer_Reader] ADD MEMBER [EXTRANET\s-web-cloud-dev]
GO
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

### # Configure logging

```PowerShell
& '.\Add Event Log Sources.ps1' -Verbose
```

### Upgrade main site collection

(skipped)

```PowerShell
cls
```

### # Install Cloud Portal solutions and activate features

#### # Deploy v2.0 solutions

```PowerShell
& '.\Add Solutions.ps1' -Verbose

& '.\Deploy Solutions.ps1' -Verbose

& '.\Activate Features.ps1' -Verbose
```

### Create and configure custom sign-in page

#### Create custom sign-in page

```PowerShell
cls
```

#### # Configure custom sign-in page on Web application

```PowerShell
Set-SPWebApplication `
    -Identity $env:SECURITAS_CLOUD_PORTAL_URL `
    -Zone Default `
    -SignInRedirectURL "/Pages/Sign-In.aspx"
```

### # Configure search settings for Cloud Portal

#### # Hide Search navigation item on top-level site

```PowerShell
Start-Process $env:SECURITAS_CLOUD_PORTAL_URL
```

##### Issue

Unable to hide the Search navigation item -- click **OK** but changes are not saved (no error reported).

07/22/2016 09:45:12.65	w3wp.exe (0x30EC)	0x0B48	Web Content Management	Publishing Provisioning	6wzd	Medium	Adding key-value pair <'__GlobalNavigationExcludes','70100f2c-9f52-420e-99b8-4f56945435b2;'> to the web-property-bag for '[http://cloud-local.securitasinc.com](http://cloud-local.securitasinc.com)'	5057929d-2053-c02f-8599-442468e79b96\
07/22/2016 09:45:12.65	w3wp.exe (0x30EC)	0x0B48	Web Content Management	Publishing Provisioning	6wze	Medium	Finished adding key-value pair <'__GlobalNavigationExcludes','70100f2c-9f52-420e-99b8-4f56945435b2;'> to the web-property-bag for '[http://cloud-local.securitasinc.com](http://cloud-local.securitasinc.com)'	5057929d-2053-c02f-8599-442468e79b96\
07/22/2016 09:45:12.67	w3wp.exe (0x30EC)	0x0B48	Web Content Management	Publishing Provisioning	6wzd	Medium	Adding key-value pair <'__GlobalNavigationExcludes','70100f2c-9f52-420e-99b8-4f56945435b2;50a50edf-612b-49d1-a971-0f5a31d1d21b;'> to the web-property-bag for '[http://cloud-local.securitasinc.com](http://cloud-local.securitasinc.com)'	5057929d-2053-c02f-8599-442468e79b96\
07/22/2016 09:45:12.67	w3wp.exe (0x30EC)	0x0B48	Web Content Management	Publishing Provisioning	6wze	Medium	Finished adding key-value pair <'__GlobalNavigationExcludes','70100f2c-9f52-420e-99b8-4f56945435b2;50a50edf-612b-49d1-a971-0f5a31d1d21b;'> to the web-property-bag for '[http://cloud-local.securitasinc.com](http://cloud-local.securitasinc.com)'	5057929d-2053-c02f-8599-442468e79b96\
07/22/2016 09:45:12.70	w3wp.exe (0x30EC)	0x0B48	Web Content Management	Publishing Provisioning	6wzd	Medium	Adding key-value pair <'__GlobalNavigationExcludes','70100f2c-9f52-420e-99b8-4f56945435b2;50a50edf-612b-49d1-a971-0f5a31d1d21b;'> to the web-property-bag for '[http://cloud-local.securitasinc.com](http://cloud-local.securitasinc.com)'	5057929d-2053-c02f-8599-442468e79b96\
07/22/2016 09:45:12.70	w3wp.exe (0x30EC)	0x0B48	Web Content Management	Publishing Provisioning	6wze	Medium	Finished adding key-value pair <'__GlobalNavigationExcludes','70100f2c-9f52-420e-99b8-4f56945435b2;50a50edf-612b-49d1-a971-0f5a31d1d21b;'> to the web-property-bag for '[http://cloud-local.securitasinc.com](http://cloud-local.securitasinc.com)'	5057929d-2053-c02f-8599-442468e79b96\
07/22/2016 09:45:12.71	w3wp.exe (0x30EC)	0x0B48	Web Content Management	Publishing Provisioning	6wzd	Medium	Adding key-value pair <'__GlobalNavigationExcludes','70100f2c-9f52-420e-99b8-4f56945435b2;50a50edf-612b-49d1-a971-0f5a31d1d21b;'> to the web-property-bag for '[http://cloud-local.securitasinc.com](http://cloud-local.securitasinc.com)'	5057929d-2053-c02f-8599-442468e79b96\
07/22/2016 09:45:12.71	w3wp.exe (0x30EC)	0x0B48	Web Content Management	Publishing Provisioning	6wze	Medium	Finished adding key-value pair <'__GlobalNavigationExcludes','70100f2c-9f52-420e-99b8-4f56945435b2;50a50edf-612b-49d1-a971-0f5a31d1d21b;'> to the web-property-bag for '[http://cloud-local.securitasinc.com](http://cloud-local.securitasinc.com)'	5057929d-2053-c02f-8599-442468e79b96\
07/22/2016 09:45:12.76	w3wp.exe (0x30EC)	0x0B48	Web Content Management	Publishing Provisioning	6wzd	Medium	Adding key-value pair <'__CurrentNavigationExcludes','70100f2c-9f52-420e-99b8-4f56945435b2;'> to the web-property-bag for '[http://cloud-local.securitasinc.com](http://cloud-local.securitasinc.com)'	5057929d-2053-c02f-8599-442468e79b96\
07/22/2016 09:45:12.76	w3wp.exe (0x30EC)	0x0B48	Web Content Management	Publishing Provisioning	6wze	Medium	Finished adding key-value pair <'__CurrentNavigationExcludes','70100f2c-9f52-420e-99b8-4f56945435b2;'> to the web-property-bag for '[http://cloud-local.securitasinc.com](http://cloud-local.securitasinc.com)'	5057929d-2053-c02f-8599-442468e79b96\
07/22/2016 09:45:12.77	w3wp.exe (0x30EC)	0x0B48	Web Content Management	Publishing Provisioning	6wzd	Medium	Adding key-value pair <'__CurrentNavigationExcludes','70100f2c-9f52-420e-99b8-4f56945435b2;50a50edf-612b-49d1-a971-0f5a31d1d21b;'> to the web-property-bag for '[http://cloud-local.securitasinc.com](http://cloud-local.securitasinc.com)'	5057929d-2053-c02f-8599-442468e79b96\
07/22/2016 09:45:12.77	w3wp.exe (0x30EC)	0x0B48	Web Content Management	Publishing Provisioning	6wze	Medium	Finished adding key-value pair <'__CurrentNavigationExcludes','70100f2c-9f52-420e-99b8-4f56945435b2;50a50edf-612b-49d1-a971-0f5a31d1d21b;'> to the web-property-bag for '[http://cloud-local.securitasinc.com](http://cloud-local.securitasinc.com)'	5057929d-2053-c02f-8599-442468e79b96\
07/22/2016 09:45:12.79	w3wp.exe (0x30EC)	0x0B48	Web Content Management	Publishing Provisioning	6wzd	Medium	Adding key-value pair <'__CurrentNavigationExcludes','70100f2c-9f52-420e-99b8-4f56945435b2;50a50edf-612b-49d1-a971-0f5a31d1d21b;'> to the web-property-bag for '[http://cloud-local.securitasinc.com](http://cloud-local.securitasinc.com)'	5057929d-2053-c02f-8599-442468e79b96\
07/22/2016 09:45:12.79	w3wp.exe (0x30EC)	0x0B48	Web Content Management	Publishing Provisioning	6wze	Medium	Finished adding key-value pair <'__CurrentNavigationExcludes','70100f2c-9f52-420e-99b8-4f56945435b2;50a50edf-612b-49d1-a971-0f5a31d1d21b;'> to the web-property-bag for '[http://cloud-local.securitasinc.com](http://cloud-local.securitasinc.com)'	5057929d-2053-c02f-8599-442468e79b96\
07/22/2016 09:45:12.82	w3wp.exe (0x30EC)	0x0B48	Web Content Management	Publishing Provisioning	6wzd	Medium	Adding key-value pair <'__CurrentNavigationExcludes','70100f2c-9f52-420e-99b8-4f56945435b2;50a50edf-612b-49d1-a971-0f5a31d1d21b;'> to the web-property-bag for '[http://cloud-local.securitasinc.com](http://cloud-local.securitasinc.com)'	5057929d-2053-c02f-8599-442468e79b96\
07/22/2016 09:45:12.82	w3wp.exe (0x30EC)	0x0B48	Web Content Management	Publishing Provisioning	6wze	Medium	Finished adding key-value pair <'__CurrentNavigationExcludes','70100f2c-9f52-420e-99b8-4f56945435b2;50a50edf-612b-49d1-a971-0f5a31d1d21b;'> to the web-property-bag for '[http://cloud-local.securitasinc.com](http://cloud-local.securitasinc.com)'	5057929d-2053-c02f-8599-442468e79b96

```PowerShell
cls
```

#### # Configure search settings for top-level site

```PowerShell
Start-Process $env:SECURITAS_CLOUD_PORTAL_URL
```

### Configure redirect for single-site users

(skipped)

### Configure "Online Provisioning"

(skipped)

### Configure Google Analytics on Web application

Tracking ID: **UA-25949832-5**

{Begin skipped sections}

## Create and configure C&C site collections

### Create "Collaboration & Community" site collection

### Apply "Securitas Client Site" template to top-level site

### Modify site title, description, and logo

### Update C&C site home page

### Create team collaboration site (optional)

### Create blog site (optional)

### Create wiki site (optional)

{End skipped sections}

### Upgrade C&C site collections

(skipped)

### Defragment SharePoint databases

### Change content database to Full recovery model

(skipped)

### Resume Search Service Application and start full crawl on all content sources

(skipped)

```Console
cls
```

# Install Employee Portal

## # Extend SecuritasConnect and Cloud Portal web applications

### # Extend web applications to Intranet zone

```PowerShell
[CmdletBinding()]
Param(
    [switch] $SecureSocketsLayer)

Begin
{
    Set-StrictMode -Version Latest
    $ErrorActionPreference = "Stop"

    If ((Get-PSSnapin Microsoft.SharePoint.PowerShell `
        -ErrorAction SilentlyContinue) -eq $null)
    {
        $ver = $host | select version

        If ($ver.Version.Major -gt 1)
        {
            $Host.Runspace.ThreadOptions = "ReuseThread"
        }

        Write-Debug "Adding snapin (Microsoft.SharePoint.PowerShell)..."

        Add-PSSnapin Microsoft.SharePoint.PowerShell
    }

    Function ExtendWebAppToIntranetZone(
        [Uri] $DefaultUrl = $(Throw "Default URL must be specified."),
        [Uri] $IntranetUrl = $(Throw "Intranet URL must be specified."))
    {
        $webApp = Get-SPWebApplication `
            -Identity $DefaultUrl.AbsoluteUri `
            -Debug:$false `
            -Verbose:$false

        Write-Verbose ("Extending Web application $(($DefaultUrl.AbsoluteUri))" `
            + " to Intranet zone $(($IntranetUrl.AbsoluteUri))...")

        $hostHeader = $IntranetUrl.Host

        $windowsAuthProvider = New-SPAuthenticationProvider `
            -Debug:$false `
            -Verbose:$false

        If ($IntranetUrl.Scheme -eq "http")
        {
            $webAppName = "SharePoint - " + $hostHeader + "80"

            $webApp | New-SPWebApplicationExtension `
                -Name $webAppName `
                -Zone Intranet `
                -AuthenticationProvider $windowsAuthProvider `
                -HostHeader $hostHeader `
                -Port 80 `
                -Debug:$false `
                -Verbose:$false

        }
        ElseIf ($IntranetUrl.Scheme -eq "https")
        {
            $webAppName = "SharePoint - " + $hostHeader + "443"

            $webApp | New-SPWebApplicationExtension `
                -Name $webAppName `
                -Zone Intranet `
                -AuthenticationProvider $windowsAuthProvider `
                -HostHeader $hostHeader `
                -Port 443 `
                -SecureSocketsLayer `
                -Debug:$false `
                -Verbose:$false
        }
        Else
        {
            Throw "The specified scheme ($($IntranetUrl.Scheme)) is not supported."
        }

        Write-Verbose ("Successfully extended Web application" `
            + " $(($DefaultUrl.AbsoluteUri)) to Intranet zone" `
            + " $(($IntranetUrl.AbsoluteUri))...")
    }
}

Process
{
    $clientWebAppDefaultUrl = $env:SECURITAS_CLIENT_PORTAL_URL
    $cloudWebAppDefaultUrl = $env:SECURITAS_CLOUD_PORTAL_URL

    $clientWebAppIntranetUrl = $clientWebAppDefaultUrl.Replace(
        "client",
        "client2")

    $cloudWebAppIntranetUrl = $cloudWebAppDefaultUrl.Replace(
        "cloud",
        "cloud2")

    If ($SecureSocketsLayer -eq $true)
    {
        $clientWebAppIntranetUrl = $clientWebAppIntranetUrl.Replace(
            "http://",
            "https://")

        $cloudWebAppIntranetUrl = $cloudWebAppIntranetUrl.Replace(
            "http://",
            "https://")
    }

    ExtendWebAppToIntranetZone `
        -DefaultUrl $clientWebAppDefaultUrl `
        -IntranetUrl $clientWebAppIntranetUrl

    ExtendWebAppToIntranetZone `
        -DefaultUrl $cloudWebAppDefaultUrl `
        -IntranetUrl $cloudWebAppIntranetUrl
}
```

### Enable disk-based caching for "intranet" websites

(skipped)

```PowerShell
cls
```

### # Map intranet URLs to loopback address in Hosts file

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    127.0.0.1 client2-local-3.securitasinc.com, cloud2-local-3.securitasinc.com
```

### # Allow specific host names mapped to 127.0.0.1

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-BackConnectionHostnames.ps1 `
    client2-local-3.securitasinc.com, cloud2-local-3.securitasinc.com
```

## Install Web Deploy 3.6

### Download Web Platform Installer

(skipped)

### Install Web Deploy

(skipped -- since this is installed with Visual Studio 2015)

## Install .NET Framework 4.5

(skipped -- since this is installed with Visual Studio 2015)

```PowerShell
cls
```

## # Install Employee Portal

### # Copy Employee Portal build to SharePoint server

```PowerShell
net use \\ICEMAN\Builds /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
robocopy `
    "\\ICEMAN\Builds\Securitas\EmployeePortal\1.0.28.0" `
    "C:\NotBackedUp\Builds\Securitas\EmployeePortal\1.0.28.0" `
    /E
```

### # Add Employee Portal URL to "Local intranet" zone

```PowerShell
[Uri] $url = [Uri] "http://employee-local-3.securitasinc.com"

[string[]] $domainParts = $url.Host -split '\.'

[string] $subdomain = $domainParts[0]
[string] $domain = $domainParts[1..2] -join '.'

[string] $registryKey = ("HKCU:\Software\Microsoft\Windows" `
    + "\CurrentVersion\Internet Settings\ZoneMap\EscDomains" `
    + "\$domain")

If ((Test-Path $registryKey) -eq $false)
{
    New-Item $registryKey | Out-Null
}

[string] $registryKey = $registryKey + "\$subdomain"

If ((Test-Path $registryKey) -eq $false)
{
    New-Item $registryKey | Out-Null
}

Set-ItemProperty -Path $registryKey -Name http -Value 1
```

```PowerShell
cls
```

### # Create Employee Portal SharePoint site

```PowerShell
cd 'C:\NotBackedUp\Builds\Securitas\EmployeePortal\1.0.28.0\Deployment Files\Scripts'

& '.\Configure Employee Portal SharePoint Site.ps1' `
    -SupportedDomains FABRIKAM, TECHTOOLBOX `
    -Confirm:$false `
    -Verbose
```

```PowerShell
cls
```

### # Create Employee Portal website

#### # Create Employee Portal website on SharePoint Central Administration server

```PowerShell
cd 'C:\NotBackedUp\Builds\Securitas\EmployeePortal\1.0.28.0\Deployment Files\Scripts'

& '.\Configure Employee Portal Website.ps1' `
    -SiteName employee-local-3.securitasinc.com `
    -Confirm:$false `
    -Verbose
```

#### Configure SSL bindings on Employee Portal website

(skipped)

#### Create Employee Portal website on other web servers in farm

(skipped)

```PowerShell
cls
```

### # Deploy Employee Portal website

#### # Deploy Employee Portal website on SharePoint Central Administration server

```PowerShell
Push-Location C:\NotBackedUp\Builds\Securitas\EmployeePortal\1.0.28.0\Debug\_PublishedWebsites\Web_Package

attrib -r .\Web.SetParameters.xml

Notepad .\Web.SetParameters.xml
```

---

**Web.SetParameters.xml**

```XML
<?xml version="1.0" encoding="utf-8"?>
<parameters>
  <setParameter
    name="IIS Web Application Name"
    value="employee-local-3.securitasinc.com" />
  <setParameter
    name="SecuritasPortal-Web.config Connection String"
    value="Server=.; Database=SecuritasPortal; Integrated Security=true" />
  <setParameter
    name="SecuritasPortalDbContext-Web.config Connection String"
    value="Data Source=.; Initial Catalog=SecuritasPortal; Integrated Security=True; MultipleActiveResultSets=True;" />
</parameters>
```

---

```Console
.\Web.deploy.cmd /y
```

```Console
cls
Pop-Location
```

#### # Configure application settings and web service URLs

```PowerShell
Notepad C:\inetpub\wwwroot\employee-local-3.securitasinc.com\Web.config
```

Set the value of the **GoogleAnalytics.TrackingId** application setting to **UA-25949832-3**.

#### Deploy Employee Portal website content to other web servers in farm

(skipped)

```PowerShell
cls
```

### # Configure database logins and permissions for Employee Portal

```PowerShell
$sqlcmd = @"
USE [master]
GO
CREATE LOGIN [IIS APPPOOL\employee-local-3.securitasinc.com]
FROM WINDOWS
WITH DEFAULT_DATABASE=[master]
GO
USE [SecuritasPortal]
GO
CREATE USER [IIS APPPOOL\employee-local-3.securitasinc.com]
FOR LOGIN [IIS APPPOOL\employee-local-3.securitasinc.com]
GO
EXEC sp_addrolemember N'Employee_FullAccess', N'IIS APPPOOL\employee-local-3.securitasinc.com'
GO
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false
```

### Grant PNKCAN and PNKUS users permissions on Cloud Portal website

(skipped)

### Install additional service packs and updates

```PowerShell
cls
```

### # Map Employee Portal URL to loopback address in Hosts file

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    127.0.0.1 employee-local-3.securitasinc.com
```

### # Allow specific host names mapped to 127.0.0.1

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-BackConnectionHostnames.ps1 `
    employee-local-3.securitasinc.com
```

```PowerShell
cls
```

### # Resume Search Service Application and start full crawl on all content sources

```PowerShell
Get-SPEnterpriseSearchServiceApplication "Search Service Application" |
    Resume-SPEnterpriseSearchServiceApplication

Get-SPEnterpriseSearchServiceApplication "Search Service Application" |
    Get-SPEnterpriseSearchCrawlContentSource |
    ForEach-Object { $_.StartFullCrawl() }
```

> **Note**
>
> Expect the crawl to complete in approximately 2-3 minutes.

```PowerShell
cls
```

## # Checkpoint VM

### # Prepare for snapshot

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts\Prepare for Snapshot.cmd'
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Remove media from DVD drive

```PowerShell
$vmHost = "STORM"
$vmName = "EXT-FOOBAR3"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

### # Checkpoint VM

```PowerShell
$snapshotName = "Baseline Client Portal 4.0.670.0 / Cloud Portal 2.0.118.0 / Employee Portal 1.0.28.0"

Stop-VM -ComputerName $vmHost -Name $vmName

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName $snapshotName

Start-VM -ComputerName $vmHost -Name $vmName
```

---

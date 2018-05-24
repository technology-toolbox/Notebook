# EXT-FOOBAR4 - Windows Server 2012 R2 Standard

Tuesday, July 26, 2016
8:03 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

Install SecuritasConnect v4.0

## Deploy and configure the server infrastructure

### Copy Windows Server installation files to a file share

(skipped)

### Install Windows Server 2012 R2

---

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Create virtual machine

```PowerShell
$vmName = "EXT-FOOBAR4"
$vmPath = "D:\NotBackedUp\VMs"

$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -Name $vmName `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 60GB `
    -MemoryStartupBytes 12GB `
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

#### Login as EXT-FOOBAR4\\foo

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

        If ($addressFamily -eq "IPv4" -and $ipConfig.Ipv4DefaultGateway)
        {
            $interface |
                Remove-NetRoute -AddressFamily $addressFamily -Confirm:$false
        }
        ElseIf ($addressFamily -eq "IPv6" -and $ipConfig.Ipv6DefaultGateway)
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
$ipAddress = "192.168.10.218"

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
$ipAddress = "2601:282:4201:e500::218"

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
$computerName = "EXT-FOOBAR4"
$targetPath = ("OU=SharePoint Servers,OU=Servers,OU=Resources,OU=Development" `
    + ",DC=extranet,DC=technologytoolbox,DC=com")

Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath

Restart-Computer $computerName

Restart-Computer : Failed to restart the computer EXT-FOOBAR4 with the following error message: Call was canceled by the message filter. (Exception from HRESULT: 0x80010002 (RPC_E_CALL_CANCELED)).
At line:1 char:1
+ Restart-Computer $computerName
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (EXT-FOOBAR4:String) [Restart-Computer], InvalidOperationException
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
$vmHost = "WOLVERINE"
$vmName = "EXT-FOOBAR4"
$vmPath = "D:\NotBackedUp\VMs\$vmName"

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

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Mount SQL Server 2014 installation media

```PowerShell
$vmName = "EXT-FOOBAR4"

$imagePath = "\\ICEMAN\Products\Microsoft\SQL Server 2014" `
    + "\en_sql_server_2014_developer_edition_with_service_pack_2_x64_dvd_8967821.iso"

Set-VMDvdDrive -VMName $vmName -Path $imagePath
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

### Download SharePoint 2013 prerequisites to a file share

(skipped)

```PowerShell
cls
```

### # Install SharePoint 2013 prerequisites on farm servers

---

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Mount SharePoint 2013 installation media

```PowerShell
$vmName = "EXT-FOOBAR4"

$imagePath = "\\ICEMAN\Products\Microsoft\SharePoint 2013\" `
    + "en_sharepoint_server_2013_with_sp1_x64_dvd_3823428.iso"

Set-VMDvdDrive -VMName $vmName -Path $imagePath
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
$vmHost = "WOLVERINE"
$vmName = "EXT-FOOBAR4"
$snapshotName = "Before - Install SharePoint Server 2013 on farm servers"

Stop-VM -ComputerName $vmHost -Name $vmName

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName $snapshotName

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### # HACK: Enable Windows Installer verbose logging (to avoid "ArpWrite timing" bug in SharePoint installation)

```PowerShell
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v Debug /t REG_DWORD /d 7 /f

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v Logging /t REG_SZ /d voicewarmup! /f

Restart-Service msiserver
```

> **Note**
>
> The **x** logging option ("Extra debugging information") does not appear to be necessary to avoid the bug. However, the **!** option ("Flush each line to the log") is definitely required. Without it (i.e. specifying **voicewarmup**) the ArpWrite error was still encountered.

#### References

**Sharepoint Server 2013 installation: why ArpWrite action fails?**\
Pasted from <[http://sharepoint.stackexchange.com/questions/68620/sharepoint-server-2013-installation-why-arpwrite-action-fails](http://sharepoint.stackexchange.com/questions/68620/sharepoint-server-2013-installation-why-arpwrite-action-fails)>

**How to enable Windows Installer logging**\
From <[https://support.microsoft.com/en-us/kb/223300](https://support.microsoft.com/en-us/kb/223300)>

"...steps you can use to gather a Windows Installer verbose log file..."\
Pasted from <[http://blogs.msdn.com/b/astebner/archive/2005/03/29/403575.aspx](http://blogs.msdn.com/b/astebner/archive/2005/03/29/403575.aspx)>

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

### # HACK: Disable Windows Installer verbose logging

```PowerShell
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v Debug /f

reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v Logging /f

Restart-Service msiserver
```

### # Add the SharePoint bin folder to the PATH environment variable

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
$vmHost = "WOLVERINE"
$vmName = "EXT-FOOBAR4"

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

#### # Enable nonblocking garbage collection for Distributed Cache Service

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

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Mount Visual Studio 2015 with Update 3 installation media

```PowerShell
$vmName = "EXT-FOOBAR4"

$imagePath = "\\ICEMAN\Products\Microsoft\Visual Studio 2015" `
    + "\en_visual_studio_enterprise_2015_with_update_3_x86_x64_dvd_8923288.iso"

Set-VMDvdDrive -VMName $vmName -Path $imagePath
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

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Mount Office Professional Plus 2016 installation media

```PowerShell
$vmName = "EXT-FOOBAR4"

$imagePath = "\\ICEMAN\Products\Microsoft\Office 2016" `
    + "\en_office_professional_plus_2016_x86_x64_dvd_6962141.iso"

Set-VMDvdDrive -VMName $vmName -Path $imagePath
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

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Mount Visio Professional 2016 installation media

```PowerShell
$vmName = "EXT-FOOBAR4"

$imagePath = "\\ICEMAN\Products\Microsoft\Visio 2016" `
    + "\en_visio_professional_2016_x86_x64_dvd_6962139.iso"

Set-VMDvdDrive -VMName $vmName -Path $imagePath
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
$vmHost = "WOLVERINE"
$vmName = "EXT-FOOBAR4"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

---

```PowerShell
cls
```

### # DEV - Install additional browsers and software (Recommended)

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

### # Enter a product key and activate Windows

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
$vmHost = "WOLVERINE"
$vmName = "EXT-FOOBAR4"

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
    "\\ICEMAN\Builds\Securitas\ClientPortal\4.0.675.0" `
    "C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.675.0" `
    /E
```

### # Create SharePoint farm

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.675.0\DeploymentFiles\Scripts

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
> Expect the previous operation to complete in approximately 4 minutes.

### Add Web servers to SharePoint farm

(skipped)

### Add SharePoint Central Administration to "Local intranet" zone

(skipped -- since the "Create Farm.ps1" script configures this)

```PowerShell
cls
```

### # Configure PowerShell access for SharePoint administrators group

```PowerShell
$adminsGroup = "EXTRANET\SharePoint Admins (DEV)"

Get-SPDatabase |
    Where-Object {$_.WebApplication -like "SPAdministrationWebApplication"} |
    Add-SPShellAdmin $adminsGroup
```

### # Grant permissions on DCOM applications for SharePoint

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.675.0\DeploymentFiles\Scripts

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

#### # Configure name resolution on Office Web Apps farm

---

**EXT-WAC02A**

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    -IPAddress 192.168.10.218 `
    -Hostnames EXT-FOOBAR4, client-local-4.securitasinc.com
```

---

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
    "Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full"
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

```PowerShell
cls
```

#### # Copy MIIS encryption key file to SharePoint 2013 server

```PowerShell
Copy-Item `
    "\\EXT-FOOBAR\C$\Users\jjameson\Desktop\miiskeys-1.bin" `
    "C:\Users\setup-sharepoint-dev\Desktop"
```

## # Configure SharePoint services and service applications

### # Change the service account for the Distributed Cache

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.675.0\DeploymentFiles\Scripts

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
Update-SPDistributedCacheSize -CacheSizeInMB 400
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
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\'
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

#### # Create the Managed Metadata Service

```PowerShell
& '.\Configure Managed Metadata Service.ps1' -Confirm:$false -Verbose
```

##### Issue

The Managed Metadata Service or Connection is currently not available. The Application Pool or Managed Metadata Web Service may not have been started. Please Contact your Administrator.

##### Solution

1. Edit the MMS properties to temporarily change the database name (**ManagedMetadataService_tmp**).
2. Edit the MMS properties to revert to the restored database (**ManagedMetadataService**).
3. Reset IIS.
4. Delete temporary database (**ManagedMetadataService_tmp**).

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
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\'
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
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\'
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
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\'
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

```SQL
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
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.675.0\DeploymentFiles\Scripts

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

(skipped -- since the database was restored from SharePoint 2010)

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
If ($farmCredential -eq $null)
{
    $farmCredential = Get-Credential (Get-SPFarm).DefaultServiceAccount.Name
}
```

> **Note**
>
> If prompted for the service account credentials, type the password for the SharePoint farm service account.

```PowerShell
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

```Console
exit
```

---

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

Verify the following connections are already configured (since the database was restored from a SharePoint 2010 environment).

| **Connection Name** | **Forest Name**            | **Account Name**        |
| ------------------- | -------------------------- | ----------------------- |
| TECHTOOLBOX         | corp.technologytoolbox.com | TECHTOOLBOX\\svc-sp-ups |
| FABRIKAM            | corp.fabrikam.com          | FABRIKAM\\s-sp-ups      |

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
$startAddress = "sps3://client-local-4.securitasinc.com"

$searchApp = Get-SPEnterpriseSearchServiceApplication `
    -Identity "Search Service Application"

New-SPEnterpriseSearchCrawlContentSource `
    -SearchApplication $searchapp `
    -Type SharePoint `
    -Name "User profiles" `
    -StartAddresses $startAddress
```

#### # Configure the search crawl schedules

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

Set-SPEnterpriseSearchCrawlContentSource `
    -Identity $contentSource `
    -ScheduleType Incremental `
    -DailyCrawlSchedule `
    -CrawlScheduleStartDateTime "12:00 AM" `
    -CrawlScheduleRepeatInterval 240 `
    -CrawlScheduleRepeatDuration 1440
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
  "http://client-local-4.securitasinc.com",
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

### # Add the URL for the SecuritasConnect Web site to the "Local intranet" zone

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-InternetSecurityZoneMapping.ps1 `
    -Zone LocalIntranet `
    -Patterns $env:SECURITAS_CLIENT_PORTAL_URL
```

### DEV - Snapshot VM

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Checkpoint VM

```PowerShell
$vmHost = "WOLVERINE"
$vmName = "EXT-FOOBAR4"
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
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.675.0\DeploymentFiles\Scripts

& '.\Create Web Application.ps1' -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-web-client-dev**.\
> Expect the previous operation to complete in approximately 1 minute.

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
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\'
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

GO

ALTER DATABASE [WSS_Content_SecuritasPortal]
SET RECOVERY SIMPLE WITH NO_WAIT
GO
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

##### # Install SecuritasConnect v3.0 solution

```PowerShell
net use \\ICEMAN\Builds /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
cls
$build = "3.0.648.0"

robocopy `
    \\ICEMAN\Builds\Securitas\ClientPortal\$build `
    C:\NotBackedUp\Builds\Securitas\ClientPortal\$build /E

cd C:\NotBackedUp\Builds\Securitas\ClientPortal\$build\DeploymentFiles\Scripts

& '.\Add Solutions.ps1'

& '.\Deploy Solutions.ps1'
```

##### # Test content database

```PowerShell
Test-SPContentDatabase `
    -Name WSS_Content_SecuritasPortal `
    -WebApplication $env:SECURITAS_CLIENT_PORTAL_URL |
    Out-File C:\NotBackedUp\Temp\Test-SPContentDatabase-SecuritasConnect.txt
```

##### # Attach content database

```PowerShell
$stopwatch = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-Stopwatch.ps1

Mount-SPContentDatabase `
    -Name WSS_Content_SecuritasPortal `
    -WebApplication $env:SECURITAS_CLIENT_PORTAL_URL `
    -MaxSiteCount 6000

$stopwatch.Stop()
C:\NotBackedUp\Public\Toolbox\PowerShell\Write-ElapsedTime.ps1 $stopwatch
```

> **Note**
>
> Expect the previous operation to complete in approximately 1-1/2 minutes.

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

### # Configure machine key for Web application

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.675.0\DeploymentFiles\Scripts

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

{bunch o' stuff skipped here}

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

### Configure My Site settings in User Profile service application

**[http://client-local-4.securitasinc.com/sites/my](http://client-local-4.securitasinc.com/sites/my)**

## Deploy SecuritasConnect solution

### DEV - Build Visual Studio solution and package SharePoint projects

(skipped)

```PowerShell
cls
```

### # Create and configure SecuritasPortal database

```PowerShell
$sqlcmd = @"
```

#### -- Restore backup of SecuritasPortal database

```Console
DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\'
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

```SQL
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

### # Configure logging

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.675.0\DeploymentFiles\Scripts

& '.\Add Event Log Sources.ps1' -Verbose
```

### # Configure claims-based authentication

```PowerShell
Push-Location "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\WebServices\SecurityToken"

copy .\web.config ".\web - Copy.config"

Notepad web.config
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
Start-Process "$env:SECURITAS_CLIENT_PORTAL_URL/sites/cc"
```

##### Issue

Unable to hide the Search navigation item -- click **OK** but changes are not saved (no error reported).

07/22/2016 05:20:23.91	w3wp.exe (0x1408)	0x04A0	Web Content Management	Publishing Provisioning	6wzd	Medium	Adding key-value pair <'__GlobalNavigationExcludes','ee88efd2-ace8-4432-861d-9919b1c36394;'> to the web-property-bag for '[http://client-local.securitasinc.com/sites/cc](http://client-local.securitasinc.com/sites/cc)'	2948929d-0039-c02f-8599-463ceeb79f88\
07/22/2016 05:20:23.91	w3wp.exe (0x1408)	0x04A0	Web Content Management	Publishing Provisioning	6wze	Medium	Finished adding key-value pair <'__GlobalNavigationExcludes','ee88efd2-ace8-4432-861d-9919b1c36394;'> to the web-property-bag for '[http://client-local.securitasinc.com/sites/cc](http://client-local.securitasinc.com/sites/cc)'	2948929d-0039-c02f-8599-463ceeb79f88\
07/22/2016 05:20:23.93	w3wp.exe (0x1408)	0x04A0	Web Content Management	Publishing Provisioning	6wzd	Medium	Adding key-value pair <'__GlobalNavigationExcludes','ee88efd2-ace8-4432-861d-9919b1c36394;899fb9b6-159f-4a9d-a3e1-ed65eb1642f3;'> to the web-property-bag for '[http://client-local.securitasinc.com/sites/cc](http://client-local.securitasinc.com/sites/cc)'	2948929d-0039-c02f-8599-463ceeb79f88\
07/22/2016 05:20:23.93	w3wp.exe (0x1408)	0x04A0	Web Content Management	Publishing Provisioning	6wze	Medium	Finished adding key-value pair <'__GlobalNavigationExcludes','ee88efd2-ace8-4432-861d-9919b1c36394;899fb9b6-159f-4a9d-a3e1-ed65eb1642f3;'> to the web-property-bag for '[http://client-local.securitasinc.com/sites/cc](http://client-local.securitasinc.com/sites/cc)'	2948929d-0039-c02f-8599-463ceeb79f88\
07/22/2016 05:20:23.96	w3wp.exe (0x1408)	0x04A0	Web Content Management	Publishing Provisioning	6wzd	Medium	Adding key-value pair <'__GlobalNavigationExcludes','ee88efd2-ace8-4432-861d-9919b1c36394;899fb9b6-159f-4a9d-a3e1-ed65eb1642f3;'> to the web-property-bag for '[http://client-local.securitasinc.com/sites/cc](http://client-local.securitasinc.com/sites/cc)'	2948929d-0039-c02f-8599-463ceeb79f88\
07/22/2016 05:20:23.96	w3wp.exe (0x1408)	0x04A0	Web Content Management	Publishing Provisioning	6wze	Medium	Finished adding key-value pair <'__GlobalNavigationExcludes','ee88efd2-ace8-4432-861d-9919b1c36394;899fb9b6-159f-4a9d-a3e1-ed65eb1642f3;'> to the web-property-bag for '[http://client-local.securitasinc.com/sites/cc](http://client-local.securitasinc.com/sites/cc)'	2948929d-0039-c02f-8599-463ceeb79f88\
07/22/2016 05:20:23.97	w3wp.exe (0x1408)	0x04A0	Web Content Management	Publishing Provisioning	6wzd	Medium	Adding key-value pair <'__CurrentNavigationExcludes','ee88efd2-ace8-4432-861d-9919b1c36394;'> to the web-property-bag for '[http://client-local.securitasinc.com/sites/cc](http://client-local.securitasinc.com/sites/cc)'	2948929d-0039-c02f-8599-463ceeb79f88\
07/22/2016 05:20:23.97	w3wp.exe (0x1408)	0x04A0	Web Content Management	Publishing Provisioning	6wze	Medium	Finished adding key-value pair <'__CurrentNavigationExcludes','ee88efd2-ace8-4432-861d-9919b1c36394;'> to the web-property-bag for '[http://client-local.securitasinc.com/sites/cc](http://client-local.securitasinc.com/sites/cc)'	2948929d-0039-c02f-8599-463ceeb79f88\
07/22/2016 05:20:23.99	OWSTIMER.EXE (0x1888)	0x0DA4	SharePoint Foundation	Monitoring	nasq	Medium	Entering monitored scope (Timer Job job-upgrade-sites). Parent No	96036634-e6fd-4301-af28-9901ed6e9442\
07/22/2016 05:20:23.99	OWSTIMER.EXE (0x1888)	0x0DA4	SharePoint Foundation	Logging Correlation Data	xmnv	Medium	Name=Timer Job job-upgrade-sites	2948929d-904b-c02f-8599-44f3f974847b\
07/22/2016 05:20:24.00	w3wp.exe (0x1408)	0x04A0	Web Content Management	Publishing Provisioning	6wzd	Medium	Adding key-value pair <'__CurrentNavigationExcludes','ee88efd2-ace8-4432-861d-9919b1c36394;899fb9b6-159f-4a9d-a3e1-ed65eb1642f3;'> to the web-property-bag for '[http://client-local.securitasinc.com/sites/cc](http://client-local.securitasinc.com/sites/cc)'	2948929d-0039-c02f-8599-463ceeb79f88\
07/22/2016 05:20:24.00	w3wp.exe (0x1408)	0x04A0	Web Content Management	Publishing Provisioning	6wze	Medium	Finished adding key-value pair <'__CurrentNavigationExcludes','ee88efd2-ace8-4432-861d-9919b1c36394;899fb9b6-159f-4a9d-a3e1-ed65eb1642f3;'> to the web-property-bag for '[http://client-local.securitasinc.com/sites/cc](http://client-local.securitasinc.com/sites/cc)'	2948929d-0039-c02f-8599-463ceeb79f88\
07/22/2016 05:20:24.04	w3wp.exe (0x1408)	0x04A0	Web Content Management	Publishing Provisioning	6wzd	Medium	Adding key-value pair <'__CurrentNavigationExcludes','ee88efd2-ace8-4432-861d-9919b1c36394;899fb9b6-159f-4a9d-a3e1-ed65eb1642f3;'> to the web-property-bag for '[http://client-local.securitasinc.com/sites/cc](http://client-local.securitasinc.com/sites/cc)'	2948929d-0039-c02f-8599-463ceeb79f88\
07/22/2016 05:20:24.04	w3wp.exe (0x1408)	0x04A0	Web Content Management	Publishing Provisioning	6wze	Medium	Finished adding key-value pair <'__CurrentNavigationExcludes','ee88efd2-ace8-4432-861d-9919b1c36394;899fb9b6-159f-4a9d-a3e1-ed65eb1642f3;'> to the web-property-bag for '[http://client-local.securitasinc.com/sites/cc](http://client-local.securitasinc.com/sites/cc)'	2948929d-0039-c02f-8599-463ceeb79f88

```PowerShell
cls
```

#### # Configure the search settings for the C&C landing site

```PowerShell
Start-Process "$env:SECURITAS_CLIENT_PORTAL_URL/sites/cc"
```

### Configure Google Analytics on the SecuritasConnect Web application

Tracking ID: **UA-25949832-4**

```PowerShell
cls
```

### # Upgrade C&C site collections

```PowerShell
$stopwatch = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-Stopwatch.ps1

$webAppUrl = $env:SECURITAS_CLIENT_PORTAL_URL

Get-SPSite ($webAppUrl + "/sites/*") -Limit ALL |
    ? { $_.CompatibilityLevel -lt 15 } |
    ForEach-Object {
        $siteUrl = $_.Url

        Write-Host "Upgrading site ($siteUrl)..."

        Disable-SPFeature `
            -Identity Securitas.Portal.Web_SecuritasDefaultMasterPage `
            -Url $siteUrl `
            -Confirm:$false

        Disable-SPFeature `
            -Identity Securitas.Portal.Web_PublishingLayouts `
            -Url $siteUrl `
            -Confirm:$false

        Upgrade-SPSite $siteUrl -VersionUpgrade -Unthrottled

        Enable-SPFeature `
            -Identity Securitas.Portal.Web_PublishingLayouts `
            -Url $siteUrl

        Enable-SPFeature `
            -Identity Securitas.Portal.Web_SecuritasDefaultMasterPage `
            -Url $siteUrl
    }

$stopwatch.Stop()
C:\NotBackedUp\Public\Toolbox\PowerShell\Write-ElapsedTime.ps1 $stopwatch
```

> **Note**
>
> Expect the previous operation to complete in approximately 1 minute.

### Defragment SharePoint databases

### Change recovery model for content database to Full

(skipped)

### Configure SQL Server backups

(skipped)

### Resume Search Service Application and start a full crawl of all content sources

(skipped)

{Begin skipped sections}

## Create and configure C&C site collections

### Create site collection for a Securitas client

### Apply the "Securitas Client Site" template to the top-level site

### Modify the site title, description, and logo

### Update the client site home page

### Create a blog site (optional)

### Create a wiki site (optional)

{End skipped sections}

Install Cloud Portal v2.0

## Backup SharePoint 2010 environment

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
    "Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full"
```

## # Create and configure Cloud Portal Web application

### # Set environment variables

```PowerShell
[Environment]::SetEnvironmentVariable(
  "SECURITAS_CLOUD_PORTAL_URL",
  "http://cloud-local-4.securitasinc.com",
  "Machine")

exit
```

> **Important**
>
> Restart PowerShell for environment variable to take effect.

### # Add URL for Cloud Portal Web site to "Local intranet" zone

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-InternetSecurityZoneMapping.ps1 `
    -Zone LocalIntranet `
    -Patterns $env:SECURITAS_CLOUD_PORTAL_URL
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
    "\\ICEMAN\Builds\Securitas\CloudPortal\2.0.122.0" `
    "C:\NotBackedUp\Builds\Securitas\CloudPortal\2.0.122.0" `
    /E
```

### # Create the Web application

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\CloudPortal\2.0.122.0\DeploymentFiles\Scripts

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

#### # Restore content database

##### # Remove content database created with Web application

```PowerShell
Remove-SPContentDatabase WSS_Content_CloudPortal -Confirm:$false -Force
```

##### # Restore database backup

```PowerShell
$sqlcmd = @"
DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\'
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

GO

ALTER DATABASE [WSS_Content_CloudPortal]
SET RECOVERY SIMPLE WITH NO_WAIT
GO
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

##### # Install Cloud Portal v1.0 solution

```PowerShell
net use \\ICEMAN\Builds /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
cls
$build = "1.0.111.0"

robocopy `
    \\ICEMAN\Builds\Securitas\CloudPortal\$build `
    C:\NotBackedUp\Builds\Securitas\CloudPortal\$build /E

cd C:\NotBackedUp\Builds\Securitas\CloudPortal\$build\DeploymentFiles\Scripts

& '.\Add Solutions.ps1'

& '.\Deploy Solutions.ps1'
```

##### # Test content database

```PowerShell
Test-SPContentDatabase `
    -Name WSS_Content_CloudPortal `
    -WebApplication $env:SECURITAS_CLOUD_PORTAL_URL |
    Out-File C:\NotBackedUp\Temp\Test-SPContentDatabase-CloudPortal.txt
```

##### # Attach content database

```PowerShell
$stopwatch = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-Stopwatch.ps1

Mount-SPContentDatabase `
    -Name WSS_Content_CloudPortal `
    -WebApplication $env:SECURITAS_CLOUD_PORTAL_URL

$stopwatch.Stop()
C:\NotBackedUp\Public\Toolbox\PowerShell\Write-ElapsedTime.ps1 $stopwatch
```

> **Note**
>
> Expect the previous operation to complete in approximately 1 minute.

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

### # Configure object cache user accounts

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\CloudPortal\2.0.122.0\DeploymentFiles\Scripts

& '.\Configure Object Cache User Accounts.ps1' -Verbose

iisreset
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

### DEV - Map Web application to loopback address in Hosts file

(skipped)

### Allow specific host names mapped to 127.0.0.1

(skipped)

### Configure SSL on the Internet zone

(skipped)

### Enable anonymous access to the site

(skipped)

### Enable disk-based caching for the Web application

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

### Configure SharePoint groups

(skipped)

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

### # Upgrade main site collection

```PowerShell
Upgrade-SPSite $env:SECURITAS_CLOUD_PORTAL_URL -VersionUpgrade -Unthrottled
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

### # Configure search settings for the Cloud Portal

#### # Hide the Search navigation item on the Cloud Portal top-level site

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

#### # Configure the search settings for the Cloud Portal top-level site

```PowerShell
Start-Process $env:SECURITAS_CLOUD_PORTAL_URL
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

### # Upgrade C&C site collections

```PowerShell
$stopwatch = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-Stopwatch.ps1

$webAppUrl = $env:SECURITAS_CLOUD_PORTAL_URL

Get-SPSite ($webAppUrl + "/sites/*") -Limit ALL |
    Where-Object { $_.CompatibilityLevel -lt 15 } |
    ForEach-Object {
        $siteUrl = $_.Url

        Write-Host "Upgrading site ($siteUrl)..."

        Get-SPWeb -Site $siteUrl |
            ForEach-Object {
                $webUrl = $_.Url

                Disable-SPFeature `
-Identity Securitas.CloudPortal.Web_SecuritasDefaultMasterPage `
                    -Url $webUrl `
                    -Confirm:$false
            }

        Disable-SPFeature `
            -Identity Securitas.CloudPortal.Web_PublishingLayouts `
            -Url $siteUrl `
            -Confirm:$false

        Upgrade-SPSite $siteUrl -VersionUpgrade -Unthrottled

        Enable-SPFeature `
            -Identity Securitas.CloudPortal.Web_PublishingLayouts `
            -Url $siteUrl

        Get-SPWeb -Site $siteUrl |
            ForEach-Object {
                $webUrl = $_.Url

                Enable-SPFeature `
                    -Identity Securitas.CloudPortal.Web_CloudPortalBranding `
                    -Url $webUrl
            }
    }

$stopwatch.Stop()
C:\NotBackedUp\Public\Toolbox\PowerShell\Write-ElapsedTime.ps1 $stopwatch
```

> **Note**
>
> Expect the previous operation to complete in approximately 2 minutes.

### Defragment SharePoint databases

### Change recovery model of content database to Full

(skipped)

### Resume Search Service Application and start full crawl on all content sources

(skipped)

```Console
cls
```

# Install Employee Portal

## # DEV - Install build dependencies for Employee Portal solution

### # Install and configure Python

#### # Install Python

```PowerShell
net use \\ICEMAN\Products /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```Console
\\ICEMAN\Products\Python\python-2.7.12.amd64.msi
```

```Console
cls
```

#### # Add Python to PATH environment variable

```PowerShell
$path = [Environment]::GetEnvironmentVariable("Path", "Machine")

$path = "$path;C:\Python27\;C:\Python27\Scripts"

[Environment]::SetEnvironmentVariable("Path", $path, "Machine")
```

### # Install and configure Git

#### # Install Git

```PowerShell
\\ICEMAN\Products\Git\Git-2.10.1-64-bit.exe
```

```PowerShell
cls
```

#### # Add Git to PATH environment variable

```PowerShell
$path = [Environment]::GetEnvironmentVariable("Path", "Machine")

$path = "$path;C:\Program Files\Git\cmd"

[Environment]::SetEnvironmentVariable("Path", $path, "Machine")
```

#### Configure Git to use https:// URLs (instead of git:// URLS)

(skipped)

```PowerShell
cls
```

### # Install and configure Node.js

#### # Install Node.js

```PowerShell
\\ICEMAN\Products\node.js\node-v4.6.0-x64.msi

exit
```

> **Important**
>
> Restart PowerShell for the changes to the PATH environment variable to take effect.

#### # Change npm file locations to avoid issues with redirected folders

```PowerShell
Notepad "C:\Program Files\nodejs\node_modules\npm\npmrc"
```

---

**npmrc**

```Text
;prefix=${APPDATA}\npm
prefix=${LOCALAPPDATA}\npm
cache=${LOCALAPPDATA}\npm-cache
```

---

```PowerShell
cls
```

#### # Change npm "global" locations to shared location for all users

```PowerShell
mkdir "$env:ALLUSERSPROFILE\npm-cache"

mkdir "$env:ALLUSERSPROFILE\npm\node_modules"

npm config --global set prefix "$env:ALLUSERSPROFILE\npm"

npm config --global set cache "$env:ALLUSERSPROFILE\npm-cache"

# Add npm "global" location to PATH environment variable

$path = [Environment]::GetEnvironmentVariable("Path", "Machine")

$path = "$path;$env:ALLUSERSPROFILE\npm"

[Environment]::SetEnvironmentVariable("Path", $path, "Machine")
```

```PowerShell
cls
```

### # Install global npm packages

#### # Install Grunt CLI

```PowerShell
npm install --global grunt-cli
```

#### # Install Gulp

```PowerShell
npm install --global gulp
```

#### # Install Bower

```PowerShell
npm install --global bower
```

#### # Install Karma CLI

```PowerShell
npm install --global karma-cli
```

#### # Install rimraf

```PowerShell
npm install --global rimraf
```

## # Extend SecuritasConnect and Cloud Portal web applications

### # Copy Employee Portal build to SharePoint server

```PowerShell
net use \\ICEMAN\Builds /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$build = "1.0.29.0"

$sourcePath = "\\ICEMAN\Builds\Securitas\EmployeePortal\$build"
$destPath = "C:\NotBackedUp\Builds\Securitas\EmployeePortal\$build"

robocopy $sourcePath $destPath /E
```

### # Extend web applications to Intranet zone

```PowerShell
cd 'C:\NotBackedUp\Builds\Securitas\EmployeePortal\1.0.29.0\Deployment Files\Scripts'

& '.\Extend Web Applications.ps1' -Confirm:$false -Verbose
```

### Enable disk-based caching for the "intranet" websites

(skipped)

```PowerShell
cls
```

### # Map intranet URLs to loopback address in Hosts file

```PowerShell
[Uri] $clientPortalUrl = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL
[Uri] $cloudPortalUrl = [Uri] $env:SECURITAS_CLOUD_PORTAL_URL

[String] $clientPortalIntranetHostHeader = $clientPortalUrl.Host.Replace(
    "client",
    "client2")

[String] $cloudPortalIntranetHostHeader = $cloudPortalUrl.Host.Replace(
    "cloud",
    "cloud2")

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    127.0.0.1 $clientPortalIntranetHostHeader, $cloudPortalIntranetHostHeader
```

### # Allow specific host names mapped to 127.0.0.1

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-BackConnectionHostnames.ps1 `
    $clientPortalIntranetHostHeader, $cloudPortalIntranetHostHeader
```

## Install Web Deploy 3.6

(skipped -- since this is installed with Visual Studio 2015)

## Install .NET Framework 4.5

(skipped -- since this is installed with Visual Studio 2015)

```PowerShell
cls
```

## # Install Employee Portal

### # Add the Employee Portal URL to the "Local intranet" zone

```PowerShell
[Uri] $employeePortalUrl = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL.Replace(
    "client",
    "employee")

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-InternetSecurityZoneMapping.ps1 `
    -Zone LocalIntranet `
    -Patterns $employeePortalUrl.AbsoluteUri
```

### Create Employee Portal SharePoint site

(skipped)

```PowerShell
cls
```

### # Create Employee Portal website

#### # Create Employee Portal website on SharePoint Central Administration server

```PowerShell
[String] $employeePortalHostHeader = $employeePortalUrl.Host

Push-Location ("C:\NotBackedUp\Builds\Securitas\EmployeePortal\$build" `
    + "\Deployment Files\Scripts")

& '.\Configure Employee Portal Website.ps1' `
    -SiteName $employeePortalHostHeader `
    -Confirm:$false `
    -Verbose

Pop-Location
```

#### Configure SSL binding on Employee Portal website

(skipped)

#### Create Employee Portal website on other web servers in the farm

(skipped)

```PowerShell
cls
```

### # Deploy Employee Portal website

#### # Deploy Employee Portal website on SharePoint Central Administration server

```PowerShell
Push-Location ("C:\NotBackedUp\Builds\Securitas\EmployeePortal\$build" `
    + "\Debug\_PublishedWebsites\Web_Package")

attrib -r .\Web.SetParameters.xml

$config = Get-Content Web.SetParameters.xml

$config = $config -replace `
    "Default Web Site/Web_deploy", $employeePortalHostHeader

$configXml = [xml] $config

$configXml.Save("$pwd\Web.SetParameters.xml")

.\Web.deploy.cmd /t

.\Web.deploy.cmd /y

Pop-Location
```

#### # Configure application settings and web service URLs

```PowerShell
Push-Location ("C:\inetpub\wwwroot\" + $employeePortalHostHeader)

(Get-Content Web.config) `
    -replace '<add key="GoogleAnalytics.TrackingId" value="" />',
        '<add key="GoogleAnalytics.TrackingId" value="UA-25949832-3" />' `
    -replace 'http://client2-local', 'http://client2-local-4' `
    -replace 'http://cloud2-local', 'http://cloud-local-4' |
    Set-Content Web.config

Pop-Location
```

#### Deploy Employee Portal website content to other web servers in the farm

(skipped)

```PowerShell
cls
```

### # Configure database logins and permissions for Employee Portal

```PowerShell
$sqlcmd = @"
USE [master]
GO
CREATE LOGIN [IIS APPPOOL\$employeePortalHostHeader]
FROM WINDOWS
WITH DEFAULT_DATABASE=[master]
GO
USE [SecuritasPortal]
GO
CREATE USER [IIS APPPOOL\$employeePortalHostHeader]
FOR LOGIN [IIS APPPOOL\$employeePortalHostHeader]
GO
EXEC sp_addrolemember N'Employee_FullAccess',
    N'IIS APPPOOL\$employeePortalHostHeader'

GO
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

### Grant PNKCAN and PNKUS users permissions on Cloud Portal site

(skipped)

### Replace absolute URLs in "User Sites" list

(skipped)

### Install additional service packs and updates

```PowerShell
cls
```

### # Map Employee Portal URL to loopback address in Hosts file

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    127.0.0.1 $employeePortalHostHeader
```

### # Allow specific host names mapped to 127.0.0.1

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-BackConnectionHostnames.ps1 `
    $employeePortalHostHeader
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
> Expect the crawl to complete in approximately 5-1/2 minutes.

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
$vmHost = "WOLVERINE"
$vmName = "EXT-FOOBAR4"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

### # Checkpoint VM

```PowerShell
$snapshotName = "Baseline Client Portal 4.0.675.0 / Cloud Portal 2.0.122.0 / Employee Portal 1.0.29.0"

Stop-VM -ComputerName $vmHost -Name $vmName

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName $snapshotName
```

### # Delete old VM checkpoint

```PowerShell
$snapshotName = "Baseline SharePoint Server 2013 configuration"

Remove-VMSnapshot -ComputerName $vmHost -VMName $vmName -Name $snapshotName

while (Get-VM -ComputerName $vmHost -Name $vmName | Where Status -eq "Merging disks") {
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 5
}

Write-Host

Start-VM -ComputerName $vmHost -Name $vmName
```

---

```PowerShell
cls
```

## # Upgrade Post Orders to SharePoint 2013 UI version

### # Prep - copy script used to upgrade Post Orders

```PowerShell
Notepad "C:\NotBackedUp\Temp\Upgrade Post Orders.ps1"
```

> **Note**
>
> Copy the script content from TFS.

```PowerShell
cls
```

### # Prep - generate input files

```PowerShell
If ((Get-PSSnapin Microsoft.SharePoint.PowerShell `
    -ErrorAction SilentlyContinue) -eq $null)
{
    Write-Debug "Adding snapin (Microsoft.SharePoint.PowerShell)..."

    $ver = $host | select version

    If ($ver.Version.Major -gt 1)
    {
        $Host.Runspace.ThreadOptions = "ReuseThread"
    }

    Add-PSSnapin Microsoft.SharePoint.PowerShell
}
```

#### # Create input file - Post-Orders.csv (all Post Orders)

```PowerShell
Get-SPSite "$env:SECURITAS_CLIENT_PORTAL_URL/Post-Orders/*" -Limit ALL |
    ? { $_.CompatibilityLevel -lt 15 } |
    Select-Object `
        Url,
        @{Name="Created"; Expression={$_.RootWeb.Created}},
        @{Name="ServerRelativeUrl"; Expression={$_.RootWeb.ServerRelativeUrl}},
        CompatibilityLevel,
        @{Name="ContentDatabase"; Expression={$_.ContentDatabase.Name}} |
    sort Created |
    Export-Csv -Path C:\NotBackedUp\Temp\Post-Orders.csv -Encoding UTF8
```

#### # Create input file - Post-Orders-Filtered.csv (exclude specific Post Orders)

```PowerShell
$excludeList = @()

Import-Csv C:\NotBackedUp\Temp\Post-Orders.csv |
    ? { $excludeList -notcontains $_.ServerRelativeUrl } |
    Export-Csv -Path C:\NotBackedUp\Temp\Post-Orders-Filtered.csv -Encoding UTF8
```

#### # Create input file - Post-Orders-Batched.csv (add batch number to each URL)

```PowerShell
$batch = 0
$maxBatch = 4

Import-Csv C:\NotBackedUp\Temp\Post-Orders-Filtered.csv |
    ForEach-Object {
        $batch++

        If ($batch -gt $maxBatch)
        {
            $batch = 1
        }

        New-Object `
            -TypeName PSObject `
            -Property @{
                Batch=$batch;
                Url=$_.Url;
            }
    } |
    Export-Csv -Path C:\NotBackedUp\Temp\Post-Orders-Batched.csv -Encoding UTF8
```

#### # Split "batched" file into individual files

```PowerShell
1..$maxBatch |
    % {
        $batch = $_

        Import-Csv C:\NotBackedUp\Temp\Post-Orders-Batched.csv |
            ? { $_.Batch -eq $batch } |
            Export-Csv `
                -Path C:\NotBackedUp\Temp\Post-Orders-Batch-$batch.csv `
                -Encoding UTF8
    }
```

### # Prep - pause Search Service Application

```PowerShell
Get-SPEnterpriseSearchServiceApplication "Search Service Application" |
    Suspend-SPEnterpriseSearchServiceApplication
```

```PowerShell
cls
```

### # Upgrade Post Orders

```PowerShell
cd C:\NotBackedUp\Temp

$ErrorActionPreference = "Stop"

Function UpgradePostOrders
{
    Param(
        [int] $Batch = 1)

    $stopwatch = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-Stopwatch.ps1

    Import-Csv C:\NotBackedUp\Temp\Post-Orders-Batch-$Batch.csv |
        ForEach-Object {
            $siteUrl = $_.Url

            & '.\Upgrade Post Orders.ps1' -Url $siteUrl -Verbose

            #Start-Process $siteUrl
    }

    $stopwatch.Stop()
    C:\NotBackedUp\Public\Toolbox\PowerShell\Write-ElapsedTime.ps1 `
        -StopWatch $stopwatch `
        -Prefix "Batch ($batch) completed. (" `
        -Suffix ")"
}

UpgradePostOrders -Batch 1
```

> **Note**
>
> Start additional instances of PowerShell to upgrade other batches of Post Orders concurrently.

```PowerShell
cls
```

### # Resume Search Service Application

```PowerShell
Get-SPEnterpriseSearchServiceApplication "Search Service Application" |
    Resume-SPEnterpriseSearchServiceApplication
```

### # Reset search index and perform full crawl

```PowerShell
$serviceApp = Get-SPEnterpriseSearchServiceApplication
```

#### # Reset search index

```PowerShell
$serviceApp.Reset($false, $false)
```

#### # Start full crawl

```PowerShell
$serviceApp |
    Get-SPEnterpriseSearchCrawlContentSource |
    % { $_.StartFullCrawl() }
```

```PowerShell
cls
```

## # Update VM snapshot

### # Prepare for snapshot

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts\Prepare for Snapshot.cmd'
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Update VM baseline

```PowerShell
$vmHost = "WOLVERINE"
$vmName = "EXT-FOOBAR4"

C:\NotBackedUp\Public\Toolbox\PowerShell\Update-VMBaseline `
    -ComputerName $vmHost `
    -Name $vmName
```

---

## Issue - IPv6 address range changed by Comcast

### # Remove static IPv6 address

```PowerShell
Remove-NetIPAddress 2601:282:4201:e500::218 -Confirm:$false
```

### # Enable DHCP on IPv6 interface

```PowerShell
$interfaceAlias = "Production"

@("IPv6") | ForEach-Object {
    $addressFamily = $_

    $interface = Get-NetAdapter $interfaceAlias |
        Get-NetIPInterface -AddressFamily $addressFamily

    If ($interface.Dhcp -eq "Disabled")
    {
        # Remove existing gateway
        $ipConfig = $interface | Get-NetIPConfiguration

        If ($addressFamily -eq "IPv4" -and $ipConfig.Ipv4DefaultGateway)
        {
            $interface |
                Remove-NetRoute -AddressFamily $addressFamily -Confirm:$false
        }

        If ($addressFamily -eq "IPv6" -and $ipConfig.Ipv6DefaultGateway)
        {
            $interface |
                Remove-NetRoute -AddressFamily $addressFamily -Confirm:$false
        }

        # Enable DHCP
        $interface | Set-NetIPInterface -DHCP Enabled

        # Configure the  DNS Servers automatically
        $interface | Set-DnsClientServerAddress -ResetServerAddresses
    }
}
```

### # Configure IPv4 DNS servers (since "ResetServerAddresses" removes IPv4 and IPv6)

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 192.168.10.209,192.168.10.210
```

## Update client secret for LMS

```Console
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.675.0\DeploymentFiles\Scripts

net use \\ICEMAN\Archive /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
Import-Csv "\\ICEMAN\Archive\Clients\Securitas\AppSettings-UAT_2016-10-06.csv" |
    ForEach-Object {
        .\Set-AppSetting.ps1 $_.Key $_.Value $_.Description -Force -Verbose
    }
```

## Upgrade SecuritasConnect to "v4.0 Sprint-26" release

### # Copy new build from TFS drop location

```PowerShell
net use \\ICEMAN\Builds /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$newBuild = "4.0.677.0"

$sourcePath = "\\ICEMAN\Builds\Securitas\ClientPortal\$newBuild"
$destPath = "C:\NotBackedUp\Builds\Securitas\ClientPortal\$newBuild"

robocopy $sourcePath $destPath /E
```

### # Remove previous versions of SecuritasConnect WSPs

```PowerShell
$oldBuild = "4.0.675.0"

Push-Location ("C:\NotBackedUp\Builds\Securitas\ClientPortal\$oldBuild" `
    + "\DeploymentFiles\Scripts")

& '.\Deactivate Features.ps1' -Verbose

& '.\Retract Solutions.ps1' -Verbose

& '.\Delete Solutions.ps1' -Verbose

Pop-Location
```

```PowerShell
cls
```

### # Install new versions of SecuritasConnect WSPs

```PowerShell
Push-Location ("C:\NotBackedUp\Builds\Securitas\ClientPortal\$newBuild" `
    + "\DeploymentFiles\Scripts")

& '.\Add Solutions.ps1' -Verbose

& '.\Deploy Solutions.ps1' -Verbose

& '.\Activate Features.ps1' -Verbose

Pop-Location
```

```PowerShell
cls
```

### # Configure application settings for TEKWave integration

```PowerShell
Start-Process $env:SECURITAS_CLIENT_PORTAL
```

```PowerShell
cls
```

### # Configure TEKWave in SecuritasPortal database

```PowerShell
$sqlcmd = @"
USE [SecuritasPortal]
GO

-- Add TEKWave services

SET IDENTITY_INSERT Customer.Services ON

INSERT INTO Customer.Services
(
    ServiceId
    , ServiceName
    , Description
)
VALUES
(
    9
    , 'TEKWave - Commercial'
    , 'Visitor Management - Commercial & Logistics'
)

INSERT INTO Customer.Services
(
    ServiceId
    , ServiceName
    , Description
)
VALUES
(
    10
    , 'TEKWave - Community'
    , 'Visitor Management - Community'
)

SET IDENTITY_INSERT Customer.Services OFF
GO

-- Remove CapSure from all sites

DELETE SiteServices
FROM
    Customer.SiteServices
    INNER JOIN Customer.Services
    ON SiteServices.ServiceId = Services.ServiceId
WHERE
    Services.ServiceName = 'CapSure'

-- Add TEKWave to "ABC Company" sites

INSERT INTO Customer.SiteServices
(
    SiteId
    , ServiceId
)
SELECT
    SiteId
    , Services.ServiceId
FROM
    Customer.Sites
    INNER JOIN Customer.Clients
    ON Sites.ClientId = Clients.ClientId
    INNER JOIN Customer.Services
    ON Services.ServiceName = 'TEKWave - Commercial'
WHERE
    Clients.ClientName = 'ABC Company'
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

### Edit user profiles to add credentials for TEKWave

```PowerShell
cls
```

### # Delete old build

```PowerShell
Remove-Item C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.675.0 `
   -Recurse -Force
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Update VM baseline

```PowerShell
$vmHost = "WOLVERINE"
$vmName = "EXT-FOOBAR4"

C:\NotBackedUp\Public\Toolbox\PowerShell\Update-VMBaseline `
    -ComputerName $vmHost `
    -Name $vmName `
    -Confirm:$false

$newSnapshotName = ("Baseline Client Portal 4.0.677.0" `
```

    + " / Cloud Portal 2.0.122.0" `\
    + " / Employee Portal 1.0.29.0")

```PowerShell
Get-VMSnapshot -ComputerName $vmHost -VMName $vmName |
```

    Rename-VMSnapshot -NewName \$newSnapshotName

---

## Upgrade SecuritasConnect to "v4.0 Sprint-27" release

### # Copy new build from TFS drop location

```PowerShell
net use \\ICEMAN\Builds /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$newBuild = "4.0.678.0"

$sourcePath = "\\ICEMAN\Builds\Securitas\ClientPortal\$newBuild"
$destPath = "C:\NotBackedUp\Builds\Securitas\ClientPortal\$newBuild"

robocopy $sourcePath $destPath /E
```

### # Remove previous versions of SecuritasConnect WSPs

```PowerShell
$oldBuild = "4.0.677.0"

Push-Location ("C:\NotBackedUp\Builds\Securitas\ClientPortal\$oldBuild" `
    + "\DeploymentFiles\Scripts")

& '.\Deactivate Features.ps1' -Verbose

& '.\Retract Solutions.ps1' -Verbose

& '.\Delete Solutions.ps1' -Verbose

Pop-Location
```

```PowerShell
cls
```

### # Install new versions of SecuritasConnect WSPs

```PowerShell
Push-Location ("C:\NotBackedUp\Builds\Securitas\ClientPortal\$newBuild" `
    + "\DeploymentFiles\Scripts")

& '.\Add Solutions.ps1' -Verbose

& '.\Deploy Solutions.ps1' -Verbose

& '.\Activate Features.ps1' -Verbose

Pop-Location
```

```PowerShell
cls
```

### # Delete old build

```PowerShell
Remove-Item C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.677.0 `
   -Recurse -Force
```

## Upgrade Employee Portal to "v1.0 Sprint-5" release

### # Copy new build from TFS drop location

```PowerShell
net use \\TT-FS01\Builds /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$build = "1.0.32.0"

$sourcePath = "\\TT-FS01\Builds\Securitas\EmployeePortal\$build"
$destPath = "C:\NotBackedUp\Builds\Securitas\EmployeePortal\$build"

robocopy $sourcePath $destPath /E
```

### # Backup Employee Portal Web.config file

```PowerShell
[Uri] $employeePortalUrl = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL.Replace(
    "client",
    "employee")

[String] $employeePortalHostHeader = $employeePortalUrl.Host

copy C:\inetpub\wwwroot\$employeePortalHostHeader\Web.config `
    "C:\NotBackedUp\Temp\Web - $employeePortalHostHeader.config"
```

### # Deploy Employee Portal website on Central Administration server

```PowerShell
Push-Location ("C:\NotBackedUp\Builds\Securitas\EmployeePortal\$build" `
    + "\Debug\_PublishedWebsites\Web_Package")

attrib -r .\Web.SetParameters.xml

$config = Get-Content Web.SetParameters.xml

$config = $config -replace `
    "Default Web Site/Web_deploy", $employeePortalHostHeader

$configXml = [xml] $config

$configXml.Save("$pwd\Web.SetParameters.xml")

.\Web.deploy.cmd /t

.\Web.deploy.cmd /y

Pop-Location
```

### # Configure application settings and web service URLs

```PowerShell
Push-Location ("C:\inetpub\wwwroot\" + $employeePortalHostHeader)

(Get-Content Web.config) `
    -replace '<add key="GoogleAnalytics.TrackingId" value="" />',
        '<add key="GoogleAnalytics.TrackingId" value="UA-25949832-3" />' `
    -replace 'http://client2-local', 'http://client2-local-4' `
    -replace 'http://cloud2-local', 'http://cloud-local-4' |
    Set-Content Web.config

Pop-Location

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    "C:\NotBackedUp\Temp\Web - $employeePortalHostHeader.config" `
    C:\inetpub\wwwroot\$employeePortalHostHeader\Web.config
```

### Deploy website content to other web servers in the farm

(skipped)

```PowerShell
cls
```

### # Configure Employee Portal navigation items

```PowerShell
Push-Location ("C:\NotBackedUp\Builds\Securitas\EmployeePortal\$build" `
    + "\Deployment Files\Scripts")

.\Set-Navigation.ps1 -State app.search -Title Search -Icon fa-search -Label New

.\Set-Navigation.ps1 -State app.directory -Label "" -Force

Pop-Location
```

```PowerShell
cls
```

### # Delete old build

```PowerShell
Remove-Item `
    C:\NotBackedUp\Builds\Securitas\EmployeePortal\1.0.29.0 `
    -Recurse -Force
```

---

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Update VM baseline

```PowerShell
$vmHost = "WOLVERINE"
$vmName = "EXT-FOOBAR4"

C:\NotBackedUp\Public\Toolbox\PowerShell\Update-VMBaseline `
    -ComputerName $vmHost `
    -Name $vmName `
    -Confirm:$false

$newSnapshotName = ("Baseline Client Portal 4.0.678.0" `
```

    + " / Cloud Portal 2.0.122.0" `\
    + " / Employee Portal 1.0.32.0")

```PowerShell
Get-VMSnapshot -ComputerName $vmHost -VMName $vmName |
```

    Rename-VMSnapshot -NewName \$newSnapshotName

---

## Upgrade SecuritasConnect to "v4.0 Sprint-28" release

### Login as EXTRANET\\setup-sharepoint-dev

### # Copy new build from TFS drop location

```PowerShell
net use \\TT-FS01\Builds /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$newBuild = "4.0.681.0"

$sourcePath = "\\TT-FS01\Builds\Securitas\ClientPortal\$newBuild"
$destPath = "C:\NotBackedUp\Builds\Securitas\ClientPortal\$newBuild"

robocopy $sourcePath $destPath /E
```

### # Remove previous versions of SecuritasConnect WSPs

```PowerShell
$oldBuild = "4.0.678.0"

Push-Location ("C:\NotBackedUp\Builds\Securitas\ClientPortal\$oldBuild" `
    + "\DeploymentFiles\Scripts")

& '.\Deactivate Features.ps1' -Verbose

& '.\Retract Solutions.ps1' -Verbose

& '.\Delete Solutions.ps1' -Verbose

Pop-Location
```

```PowerShell
cls
```

### # Install new versions of SecuritasConnect WSPs

```PowerShell
Push-Location ("C:\NotBackedUp\Builds\Securitas\ClientPortal\$newBuild" `
    + "\DeploymentFiles\Scripts")

& '.\Add Solutions.ps1' -Verbose

& '.\Deploy Solutions.ps1' -Verbose

& '.\Activate Features.ps1' -Verbose

Pop-Location
```

```PowerShell
cls
```

### # Delete old build

```PowerShell
Remove-Item C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.678.0 `
   -Recurse -Force
```

### # HACK: Grant "Everyone" read access to /Branch-Management site

```PowerShell
$web = Get-SPWeb "$env:SECURITAS_CLIENT_PORTAL_URL/Branch-Management"

$claim = `
[Microsoft.SharePoint.Administration.Claims.SPAllUserClaimProvider `
    ]::CreateAuthenticatedUserClaim($true)

$user = $web.Site.RootWeb.EnsureUser($claim.ToEncodedString())

$readPermission = $web.RoleDefinitions["Read"]

$roleAssignment = New-Object Microsoft.SharePoint.SPRoleAssignment($user)

$roleAssignment.RoleDefinitionBindings.Add($readPermission)

$web.RoleAssignments.Add($roleAssignment)

$web.Dispose()
```

## Refresh SecuritasPortal database from Production

### # Restore SecuritasPortal database backup

#### # Extract database backups from zip file

```PowerShell
net use \\TT-FS01\Archive /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$backupFile = "SecuritasPortal.bak"

$sourcePath = "\\TT-FS01\Archive\Clients\Securitas\Backups"

$destPath = "Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full"

robocopy $sourcePath $destPath $backupFile
```

#### # Restore database backup from Production

```PowerShell
$sqlcmd = @"
DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\$backupFile'

DECLARE @dataFilePath VARCHAR(255) =
  'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'SecuritasPortal.mdf'

DECLARE @logFilePath VARCHAR(255) =
  'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'SecuritasPortal_log.LDF'

RESTORE DATABASE SecuritasPortal
  FROM DISK = @backupFilePath
  WITH FILE = 1,
    MOVE 'SecuritasPortal' TO @dataFilePath,
    MOVE 'SecuritasPortal_log' TO @logFilePath,
    NOUNLOAD,
    REPLACE,
    STATS = 5

GO

ALTER DATABASE SecuritasPortal
SET RECOVERY SIMPLE WITH NO_WAIT
GO
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
```

#### # Configure permissions for SecuritasPortal database

```PowerShell
[Uri] $employeePortalUrl = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL.Replace(
    "client",
    "employee")

[String] $employeePortalHostHeader = $employeePortalUrl.Host

$sqlcmd = @"
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

CREATE USER [IIS APPPOOL\$employeePortalHostHeader]
FOR LOGIN [IIS APPPOOL\$employeePortalHostHeader]
GO
EXEC sp_addrolemember N'Employee_FullAccess',
    N'IIS APPPOOL\$employeePortalHostHeader'

GO

DROP USER [SEC\258521-VM4$]
DROP USER [SEC\424642-SP$]
DROP USER [SEC\424646-SP$]
DROP USER [SEC\784806-SPWFE1$]
DROP USER [SEC\784807-SPWFE2$]
DROP USER [SEC\784810-SPAPP$]
DROP USER [SEC\s-sp-farm]
DROP USER [SEC\s-web-client]
DROP USER [SEC\s-web-cloud]
DROP USER [SEC\svc-sharepoint-2010]
DROP USER [SEC\svc-web-securitas]
DROP USER [SEC\svc-web-securitas-20]
GO
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
```

#### # Associate users to TECHTOOLBOX\\smasters

```PowerShell
$sqlcmd = @"
USE [SecuritasPortal]
GO

INSERT INTO Customer.BranchManagerAssociatedUsers
SELECT 'TECHTOOLBOX\smasters', AssociatedUserName
FROM Customer.BranchManagerAssociatedUsers
WHERE BranchManagerUserName = 'PNKUS\jjameson'
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
```

---

**WOLVERINE**

#### Configure TrackTik credentials for Branch Manager

Branch Manager: **TECHTOOLBOX\\smasters**\
TrackTik username:** opanduro2m**

#### HACK: Update TrackTik password for Angela.Parks

[http://client-local-4.securitasinc.com/_layouts/Securitas/EditProfile.aspx](http://client-local-4.securitasinc.com/_layouts/Securitas/EditProfile.aspx)

#### HACK: Update TrackTik password for bbarthelemy-demo

[http://client-local-4.securitasinc.com/_layouts/Securitas/EditProfile.aspx](http://client-local-4.securitasinc.com/_layouts/Securitas/EditProfile.aspx)

---

---

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Update VM baseline

```PowerShell
$vmHost = "WOLVERINE"
$vmName = "EXT-FOOBAR4"

C:\NotBackedUp\Public\Toolbox\PowerShell\Update-VMBaseline `
    -ComputerName $vmHost `
    -Name $vmName `
    -Confirm:$false

$newSnapshotName = ("Baseline Client Portal 4.0.681.0" `
```

    + " / Cloud Portal 2.0.122.0" `\
    + " / Employee Portal 1.0.32.0")

```PowerShell
Get-VMSnapshot -ComputerName $vmHost -VMName $vmName |
    Rename-VMSnapshot -NewName $newSnapshotName
```

---

## Refresh SecuritasPortal database from Production

---

**784837-SQLCLUS1**

```PowerShell
cls
```

### # Create "copy-only" database backup

```PowerShell
$databaseName = "SecuritasPortal"

$sqlcmd = @"
DECLARE @databaseName VARCHAR(50) = '$databaseName'

DECLARE @backupDirectory VARCHAR(255)

EXEC master.dbo.xp_instance_regread
    N'HKEY_LOCAL_MACHINE'
    , N'Software\Microsoft\MSSQLServer\MSSQLServer'
    , N'BackupDirectory'
    , @backupDirectory OUTPUT

DECLARE @backupFilePath VARCHAR(255) =
    @backupDirectory + '\Full\' + @databaseName + '.bak'

DECLARE @backupName VARCHAR(100) = @databaseName + '-Full Database Backup'

BACKUP DATABASE @databaseName
    TO DISK = @backupFilePath
    WITH COMPRESSION
        , COPY_ONLY
        , INIT
        , NAME = @backupName
        , STATS = 10

GO
"@

Invoke-Sqlcmd `
    -ServerInstance 784837-SQLCLUS1 `
    -Query $sqlcmd `
    -QueryTimeout 0 `
    -Verbose `
    -Debug:$false

Set-Location C:
```

---

### Copy database backup to file server

[\\\\TT-FS01\\Archive\\Clients\\Securitas\\Backups](\\TT-FS01\Archive\Clients\Securitas\Backups)

### Restore SecuritasPortal database backup

---

**WOLVERINE**

```PowerShell
cls
```

#### # Copy database backup from Production

```PowerShell
$backupFile = "SecuritasPortal.bak"

$sourcePath = "\\TT-FS01\Archive\Clients\Securitas\Backups"

$destPath = "\\EXT-FOOBAR4.extranet.technologytoolbox.com\Z$" `
    + "\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full"

robocopy $sourcePath $destPath $backupFile
```

---

```PowerShell
cls
```

#### # Stop IIS

```PowerShell
iisreset /stop
```

#### # Restore database backup

```PowerShell
$backupFile = "SecuritasPortal.bak"

$sqlcmd = @"
DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\$backupFile'

RESTORE DATABASE SecuritasPortal
  FROM DISK = @backupFilePath
  WITH
    REPLACE,
    STATS = 10

GO
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
```

#### # Configure security on SecuritasPortal database

```PowerShell
[Uri] $clientPortalUrl = $null

If ($env:COMPUTERNAME -eq "784816-UATSQL")
{
    $clientPortalUrl = [Uri] "http://client-qa.securitasinc.com"
}
Else
{
    # Development environment is assumed to have SECURITAS_CLIENT_PORTAL_URL
    # environment variable set (since SQL Server is installed on same server as
    # SharePoint)
    $clientPortalUrl = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL
}

[Uri] $employeePortalUrl = [Uri] $clientPortalUrl.AbsoluteUri.Replace(
    "client",
    "employee")

[String] $employeePortalHostHeader = $employeePortalUrl.Host

[String] $farmServiceAccount = "EXTRANET\s-sp-farm-dev"
[String] $clientPortalServiceAccount = "EXTRANET\s-web-client-dev"
[String] $cloudPortalServiceAccount = "EXTRANET\s-web-cloud-dev"
[String[]] $employeePortalAccounts = "IIS APPPOOL\$employeePortalHostHeader"

If ($employeePortalHostHeader -eq "employee-qa.securitasinc.com")
{
    $farmServiceAccount = "SEC\s-sp-farm-qa"
    $clientPortalServiceAccount = "SEC\s-web-client-qa"
    $cloudPortalServiceAccount = "SEC\s-web-cloud-qa"
    $employeePortalAccounts = @(
        'SEC\784813-UATSPAPP$',
        'SEC\784815-UATSPWFE$')
}

[String] $sqlcmd = @"
USE SecuritasPortal
GO

CREATE USER [$farmServiceAccount]
FOR LOGIN [$farmServiceAccount]
GO
ALTER ROLE aspnet_Membership_BasicAccess
ADD MEMBER [$farmServiceAccount]
GO
ALTER ROLE aspnet_Membership_ReportingAccess
ADD MEMBER [$farmServiceAccount]
GO
ALTER ROLE aspnet_Roles_BasicAccess
ADD MEMBER [$farmServiceAccount]
GO
ALTER ROLE aspnet_Roles_ReportingAccess
ADD MEMBER [$farmServiceAccount]
GO

CREATE USER [$clientPortalServiceAccount]
FOR LOGIN [$clientPortalServiceAccount]
GO
ALTER ROLE aspnet_Membership_FullAccess
ADD MEMBER [$clientPortalServiceAccount]
GO
ALTER ROLE aspnet_Profile_BasicAccess
ADD MEMBER [$clientPortalServiceAccount]
GO
ALTER ROLE aspnet_Roles_BasicAccess
ADD MEMBER [$clientPortalServiceAccount]
GO
ALTER ROLE aspnet_Roles_ReportingAccess
ADD MEMBER [$clientPortalServiceAccount]
GO
ALTER ROLE Customer_Reader
ADD MEMBER [$clientPortalServiceAccount]
GO

CREATE USER [$cloudPortalServiceAccount]
FOR LOGIN [$cloudPortalServiceAccount]
GO
ALTER ROLE Customer_Provisioner
ADD MEMBER [$cloudPortalServiceAccount]
GO
"@

$employeePortalAccounts |
    ForEach-Object {
        $employeePortalAccount = $_

        $sqlcmd += [System.Environment]::NewLine

        $sqlcmd += @"
CREATE USER [$employeePortalAccount]
FOR LOGIN [$employeePortalAccount]
GO
ALTER ROLE Employee_FullAccess
ADD MEMBER [$employeePortalAccount]
GO
"@
    }

$sqlcmd += [System.Environment]::NewLine
$sqlcmd += @"
DROP USER [SEC\258521-VM4$]
DROP USER [SEC\424642-SP$]
DROP USER [SEC\424646-SP$]
DROP USER [SEC\784806-SPWFE1$]
DROP USER [SEC\784807-SPWFE2$]
DROP USER [SEC\784810-SPAPP$]
DROP USER [SEC\s-sp-farm]
DROP USER [SEC\s-web-client]
DROP USER [SEC\s-web-cloud]
DROP USER [SEC\svc-sharepoint-2010]
DROP USER [SEC\svc-web-securitas]
DROP USER [SEC\svc-web-securitas-20]
GO
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose

Set-Location C:
```

#### # Start IIS

```PowerShell
iisreset /start
```

#### # Associate users to TECHTOOLBOX\\smasters

```PowerShell
$sqlcmd = @"
USE [SecuritasPortal]
GO

INSERT INTO Customer.BranchManagerAssociatedUsers
SELECT 'TECHTOOLBOX\smasters', AssociatedUserName
FROM Customer.BranchManagerAssociatedUsers
WHERE BranchManagerUserName = 'PNKUS\jjameson'
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
```

---

**WOLVERINE**

#### Configure SSO credentials for users

##### Configure TrackTik credentials for Branch Manager

[http://client-local-4.securitasinc.com/_layouts/Securitas/EditProfile.aspx](http://client-local-4.securitasinc.com/_layouts/Securitas/EditProfile.aspx)

Branch Manager: **TECHTOOLBOX\\smasters**\
TrackTik username:** opanduro2m**

##### HACK: Update TrackTik password for Angela.Parks

[http://client-local-4.securitasinc.com/_layouts/Securitas/EditProfile.aspx](http://client-local-4.securitasinc.com/_layouts/Securitas/EditProfile.aspx)

##### HACK: Update TrackTik password for bbarthelemy-demo

[http://client-local-4.securitasinc.com/_layouts/Securitas/EditProfile.aspx](http://client-local-4.securitasinc.com/_layouts/Securitas/EditProfile.aspx)

---

## Upgrade SecuritasConnect to "v4.0 Sprint-28" QFE release

---

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Copy new build from TFS drop location

```PowerShell
$newBuild = "4.0.681.1"

$sourcePath = "\\TT-FS01\Builds\Securitas\ClientPortal\$newBuild"

$destPath = "\\EXT-FOOBAR4.extranet.technologytoolbox.com\C$" `
    + "\NotBackedUp\Builds\Securitas\ClientPortal\$newBuild"

robocopy $sourcePath $destPath /E
```

---

```PowerShell
cls
```

### # Upgrade SecuritasConnect WSPs

```PowerShell
$newBuild = "4.0.681.1"

Push-Location ("C:\NotBackedUp\Builds\Securitas\ClientPortal\$newBuild" `
    + "\DeploymentFiles\Scripts")

& '.\Upgrade Solutions.ps1' -Verbose

Pop-Location
```

```PowerShell
cls
```

### # Delete old build

```PowerShell
Remove-Item C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.681.0 `
   -Recurse -Force
```

---

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Update VM baseline

```PowerShell
$vmHost = "WOLVERINE"
$vmName = "EXT-FOOBAR4"

C:\NotBackedUp\Public\Toolbox\PowerShell\Update-VMBaseline `
    -ComputerName $vmHost `
    -Name $vmName `
    -Confirm:$false

$newSnapshotName = ("Baseline Client Portal 4.0.681.1" `
```

    + " / Cloud Portal 2.0.122.0" `\
    + " / Employee Portal 1.0.32.0")

```PowerShell
Get-VMSnapshot -ComputerName $vmHost -VMName $vmName |
    Rename-VMSnapshot -NewName $newSnapshotName
```

---

## # Move VM to extranet VLAN

### # Enable DHCP

```PowerShell
$interfaceAlias = Get-NetAdapter `
    -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    select -ExpandProperty Name

@("IPv4", "IPv6") | ForEach-Object {
    $addressFamily = $_

    $interface = Get-NetAdapter $interfaceAlias |
        Get-NetIPInterface -AddressFamily $addressFamily

    If ($interface.Dhcp -eq "Disabled")
    {
        # Remove existing gateway
        $ipConfig = $interface | Get-NetIPConfiguration

        If ($addressFamily -eq "IPv4" -and $ipConfig.Ipv4DefaultGateway)
        {
            $interface |
                Remove-NetRoute -AddressFamily $addressFamily -Confirm:$false
        }

        If ($addressFamily -eq "IPv6" -and $ipConfig.Ipv6DefaultGateway)
        {
            $interface |
                Remove-NetRoute -AddressFamily $addressFamily -Confirm:$false
        }

        # Enable DHCP
        $interface | Set-NetIPInterface -DHCP Enabled

        # Configure the  DNS Servers automatically
        $interface | Set-DnsClientServerAddress -ResetServerAddresses
    }
}
```

### # Rename network connection

```PowerShell
$interfaceAlias = "Extranet"

Get-NetAdapter `
    -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

### # Disable jumbo frames

```PowerShell
Set-NetAdapterAdvancedProperty `
    -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 1514

Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"
```

### Set VLAN ID on network adapter

#### Shutdown VM

#### Set VLAN ID to 20 on network adapter

---

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Update VM baseline

```PowerShell
$vmHost = "WOLVERINE"
$vmName = "EXT-FOOBAR4"

C:\NotBackedUp\Public\Toolbox\PowerShell\Update-VMBaseline `
    -ComputerName $vmHost `
    -Name $vmName `
    -Confirm:$false
```

---

## Expand D: (Data01) drive

### Delete checkpoint

---

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Increase the size of "Data01" VHD

```PowerShell
$vmHost = "WOLVERINE"
$vmName = "EXT-FOOBAR4"

Resize-VHD `
    -ComputerName $vmHost `
    -Path ("D:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
        + $vmName + "_Data01.vhdx") `
    -SizeBytes 5GB
```

---

```PowerShell
cls
```

### # Extend partition

```PowerShell
$size = (Get-PartitionSupportedSize -DiskNumber 1 -PartitionNumber 1)
Resize-Partition -DiskNumber 1 -PartitionNumber 1 -Size $size.SizeMax
```

---

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Update VM baseline

```PowerShell
$vmHost = "WOLVERINE"
$vmName = "EXT-FOOBAR4"

C:\NotBackedUp\Public\Toolbox\PowerShell\Update-VMBaseline `
    -ComputerName $vmHost `
    -Name $vmName `
    -Confirm:$false
```

---

## Copy "Solutions" site from Production

---

**784810-SPAPP - Run as SEC\\jjameson-admin**

```PowerShell
Enable-SharePointCmdlets
```

```PowerShell
cls
```

### # Export site

```PowerShell
$cloudPortalUrl = "http://cloud.securitasinc.com"

$urlName = "Solutions"

$tempPath = "C:\NotBackedUp\Temp\$urlName"

New-Item -ItemType Directory -Path $tempPath

Push-Location $tempPath

Export-SPWeb `
    -Identity ("$cloudPortalUrl/sites/" + $urlName) `
    -Path "$urlName.cmp" `
    -IncludeUserSecurity `
    -IncludeVersions All

Pop-Location

Compress-Archive -Path $tempPath -DestinationPath $tempPath

Remove-Item -Path $tempPath -Recurse -Confirm:$true
```

---

### Copy site export to internal file server

**[\\\\TT-FS01\\Archive\\Clients\\Securitas\\Backups\\Cloud-Sites](\\TT-FS01\Archive\Clients\Securitas\Backups\Cloud-Sites)**

---

**WOLVERINE**

```PowerShell
cls
```

### # Copy site export from internal file server

```PowerShell
$zipFile = "Solutions.zip"

$sourcePath = "\\TT-FS01\Archive\Clients\Securitas\Backups\Cloud-Sites"

$destPath = "\\EXT-FOOBAR4.extranet.technologytoolbox.com" `
    + "\C$\NotBackedUp\Temp"

Copy-Item "$sourcePath\$zipFile" $destPath
```

---

```PowerShell
cls
```

### # Import site

```PowerShell
Enable-SharePointCmdlets

$urlName = "Solutions"
$ownerAlias = "EXTRANET\setup-sharepoint-dev"

$tempPath = "C:\NotBackedUp\Temp"
$zipFile = "$tempPath\$urlName" + ".zip"

Add-Type -AssemblyName System.IO.Compression.FileSystem

[System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $tempPath)

Push-Location "$tempPath\$urlName"

$site = New-SPSite `
    -Url ("$env:SECURITAS_CLOUD_PORTAL_URL/sites/" + $urlName) `
    -OwnerAlias $ownerAlias

Import-SPWeb `
    -Identity ("$env:SECURITAS_CLOUD_PORTAL_URL/sites/" + $urlName) `
    -Path (Resolve-Path "$urlName.cmp") `
    -IncludeUserSecurity

Pop-Location

Remove-Item -Path "$tempPath\$urlName" -Recurse -Confirm:$false
Remove-Item -Path $zipFile -Confirm:$false
```

---

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Update VM baseline

```PowerShell
$vmHost = "WOLVERINE"
$vmName = "EXT-FOOBAR4"

C:\NotBackedUp\Public\Toolbox\PowerShell\Update-VMBaseline `
    -ComputerName $vmHost `
    -Name $vmName `
    -Confirm:$false
```

---

## Deploy federated authentication in SecuritasConnect

### Login as EXTRANET\\setup-sharepoint-dev

### # Pause Search Service Application

```PowerShell
Enable-SharePointCmdlets

Get-SPEnterpriseSearchServiceApplication "Search Service Application" |
    Suspend-SPEnterpriseSearchServiceApplication
```

### # Configure SSL in development environments

#### # Install certificate for secure communication with SecuritasConnect

---

**WOLVERINE**

```PowerShell
cls
```

##### # Copy certificate from internal file server

```PowerShell
$certFile = "securitasinc.com.pfx"

$sourcePath = "\\TT-FS01\Archive\Clients\Securitas"

$destPath = "\\EXT-FOOBAR4.extranet.technologytoolbox.com" `
    + "\C$\NotBackedUp\Temp"

Copy-Item "$sourcePath\$certFile" $destPath
```

---

```PowerShell
cls
```

##### # Install certificate

```PowerShell
$certPassword = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted for the secure string, type the password for the exported certificate.

```PowerShell
$certFile = "C:\NotBackedUp\Temp\securitasinc.com.pfx"

Import-PfxCertificate `
    -FilePath $certFile `
    -CertStoreLocation Cert:\LocalMachine\My `
    -Password $certPassword

If ($? -eq $true)
{
    Remove-Item $certFile -Verbose
}
```

#### Add public URLs for HTTPS

| **Alternate Access Mapping Collection**        | **Zone** | **Public URL**                                                                       |
| ---------------------------------------------- | -------- | ------------------------------------------------------------------------------------ |
| SharePoint - client-local-4.securitasinc.com80 | Default  | [http://client-local-4.securitasinc.com](http://client-local-4.securitasinc.com)     |
|                                                | Intranet | [https://client2-local-4.securitasinc.com](https://client2-local-4.securitasinc.com) |
|                                                | Internet | [https://client-local-4.securitasinc.com](https://client-local-4.securitasinc.com)   |
|                                                | Custom   |                                                                                      |
|                                                | Extranet |                                                                                      |
| SharePoint - cloud-local-4.securitasinc.com80  | Default  | [http://cloud-local-4.securitasinc.com](http://cloud-local-4.securitasinc.com)       |
|                                                | Intranet | [https://cloud2-local-4.securitasinc.com](https://cloud2-local-4.securitasinc.com)   |
|                                                | Internet | [https://cloud-local-4.securitasinc.com](https://cloud-local-4.securitasinc.com)     |
|                                                | Custom   |                                                                                      |
|                                                | Extranet |                                                                                      |

```PowerShell
cls
If ((Get-PSSnapin Microsoft.SharePoint.PowerShell `
    -ErrorAction SilentlyContinue) -eq $null)
{
    Write-Debug "Adding snapin (Microsoft.SharePoint.PowerShell)..."

    $ver = $host | select version

    If ($ver.Version.Major -gt 1)
    {
        $Host.Runspace.ThreadOptions = "ReuseThread"
    }

    Add-PSSnapin Microsoft.SharePoint.PowerShell
}

[String] $webAppUrl = $env:SECURITAS_CLIENT_PORTAL_URL

New-SPAlternateUrl `
    -Url $webAppUrl.Replace("http://", "https://") `
    -WebApplication $webAppUrl `
    -Zone Internet

$webAppUrl = $env:SECURITAS_CLOUD_PORTAL_URL

New-SPAlternateUrl `
    -Url $webAppUrl.Replace("http://", "https://") `
    -WebApplication $webAppUrl `
    -Zone Internet
```

#### # Unextend web applications

```PowerShell
$webAppUrl = $env:SECURITAS_CLIENT_PORTAL_URL

Remove-SPWebApplication `
    -Identity $webAppUrl `
    -Zone Intranet `
    -DeleteIISSite `
    -Confirm:$false

$webAppUrl = $env:SECURITAS_CLOUD_PORTAL_URL

Remove-SPWebApplication `
    -Identity $webAppUrl `
    -Zone Intranet `
    -DeleteIISSite `
    -Confirm:$false
```

#### # Extend web applications to Intranet zone using SSL

```PowerShell
Push-Location ('C:\NotBackedUp\Builds\Securitas\EmployeePortal\1.0.32.0' `
    + '\Deployment Files\Scripts')

& '.\Extend Web Applications.ps1' -SecureSocketsLayer -Confirm:$false

Pop-Location
```

#### # Add HTTPS bindings to IIS websites

##### # Add HTTPS binding to SecuritasConnect website

```PowerShell
[Uri] $clientPortalUrl = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL

$cert = Get-ChildItem -Path Cert:\LocalMachine\My |
    Where { $_.Subject -like "CN=`*.securitasinc.com,*" }

New-WebBinding `
    -Name ("SharePoint - " + $clientPortalUrl.Host + "80") `
    -Protocol https `
    -Port 443 `
    -HostHeader $clientPortalUrl.Host `
    -SslFlags 0

$cert |
    New-Item `
        -Path ("IIS:\SslBindings\0.0.0.0!443!" + $clientPortalUrl.Host)
```

##### # Add HTTPS binding to Cloud Portal website

```PowerShell
[Uri] $cloudPortalUrl = [Uri] $env:SECURITAS_CLOUD_PORTAL_URL

New-WebBinding `
    -Name ("SharePoint - " + $cloudPortalUrl.Host + "80") `
    -Protocol https `
    -Port 443 `
    -HostHeader $cloudPortalUrl.Host `
    -SslFlags 0
```

##### # Add HTTPS binding to Employee Portal website

```PowerShell
[Uri] $employeePortalUrl = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL.Replace(
    "client",
    "employee")

New-WebBinding `
    -Name $employeePortalUrl.Host `
    -Protocol https `
    -Port 443 `
    -HostHeader $employeePortalUrl.Host `
    -SslFlags 0
```

#### # Change web service URLs (from HTTP to HTTPS) in Employee Portal

```PowerShell
Push-Location ("C:\inetpub\wwwroot\" + $employeePortalUrl.Host)

(Get-Content Web.config) `
    -replace 'http://client2', 'https://client2' `
    -replace 'http://cloud2', 'https://cloud2' `
    -replace 'TransportCredentialOnly', 'Transport' |
    Set-Content Web.config

Pop-Location
```

#### # Enable disk-based caching for Web applications

##### # Enable disk-based caching for SecuritasConnect

```PowerShell
[Uri] $clientPortalUrl = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL

Push-Location ("C:\inetpub\wwwroot\wss\VirtualDirectories\" `
    + $clientPortalUrl.Host + "80")

copy Web.config "Web - Copy.config"

Notepad Web.config
```

---

**Web.config**

```XML
    <BlobCache
      location="D:\BlobCache\14"
      path="\.(gif|jpg|jpeg|jpe|jfif|bmp|dib|tif|tiff|themedbmp|themedcss|themedgif|themedjpg|themedpng|ico|png|wdp|hdp|css|js|asf|avi|flv|m4v|mov|mp3|mp4|mpeg|mpg|rm|rmvb|wma|wmv|ogg|ogv|oga|webm|xap)$"
      maxSize="2"
      enabled="true" />
```

---

```PowerShell
Pop-Location

Push-Location ("C:\inetpub\wwwroot\wss\VirtualDirectories\" `
    + $clientPortalUrl.Host.Replace("client", "client2") + "443")

copy Web.config "Web - Copy.config"

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    ("..\" + $clientPortalUrl.Host + "80\Web.config") `
    Web.config

Pop-Location
```

##### # Enable disk-based caching for Cloud Portal

```PowerShell
[Uri] $cloudPortalUrl = [Uri] $env:SECURITAS_CLOUD_PORTAL_URL

Push-Location ("C:\inetpub\wwwroot\wss\VirtualDirectories\" `
    + $cloudPortalUrl.Host + "80")

copy Web.config "Web - Copy.config"

Notepad Web.config
```

---

**Web.config**

```XML
    <BlobCache
      location="D:\BlobCache\14"
      path="\.(gif|jpg|jpeg|jpe|jfif|bmp|dib|tif|tiff|themedbmp|themedcss|themedgif|themedjpg|themedpng|ico|png|wdp|hdp|css|js|asf|avi|flv|m4v|mov|mp3|mp4|mpeg|mpg|rm|rmvb|wma|wmv|ogg|ogv|oga|webm|xap)$"
      maxSize="2"
      enabled="true" />
```

---

```PowerShell
Pop-Location

Push-Location ("C:\inetpub\wwwroot\wss\VirtualDirectories\" `
    + $cloudPortalUrl.Host.Replace("cloud", "cloud2") + "443")

copy Web.config "Web - Copy.config"

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    ("..\" + $cloudPortalUrl.Host + "80\Web.config") `
    Web.config

Pop-Location
```

---

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Checkpoint VM

```PowerShell
$vmHost = "WOLVERINE"
$vmName = "EXT-FOOBAR4"
$snapshotName = "Configure SSL on all websites and enable BlobCache"

Stop-VM -ComputerName $vmHost -Name $vmName

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName $snapshotName

Start-VM -ComputerName $vmHost -Name $vmName
```

---

---

**EXT-ADFS02A - Run as EXTRANET\\jjameson-admin**

```PowerShell
cls
```

### # Configure relying party in AD FS for SecuritasConnect

#### # Create relying party in AD FS

```PowerShell
$clientPortalUrl = [Uri] "http://client-local-4.securitasinc.com"

$relyingPartyDisplayName = $clientPortalUrl.Host
$wsFedEndpointUrl = "https://" + $clientPortalUrl.Host + "/_trust/"
$additionalIdentifier = "urn:sharepoint:securitas:" `
    + ($clientPortalUrl.Host -split '\.' | select -First 1)

$identifiers = $wsFedEndpointUrl, $additionalIdentifier

Add-AdfsRelyingPartyTrust `
    -Name $relyingPartyDisplayName `
    -Identifier $identifiers `
    -WSFedEndpoint $wsFedEndpointUrl `
    -AccessControlPolicyName "Permit everyone"
```

#### # Configure claim issuance policy for relying party

```PowerShell
$clientPortalUrl = [Uri] "http://client-local-4.securitasinc.com"

$relyingPartyDisplayName = $clientPortalUrl.Host

$claimRules = `
'@RuleTemplate = "LdapClaims"
@RuleName = "Active Directory Claims"
c:[Type ==
  "http://schemas.microsoft.com/ws/2008/06/identity/claims/windowsaccountname",
  Issuer == "AD AUTHORITY"]
=> issue(
  store = "Active Directory",
  types = (
    "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress",
    "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name",
    "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn",
    "http://schemas.microsoft.com/ws/2008/06/identity/claims/primarysid",
    "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"),
  query = ";mail,displayName,userPrincipalName,objectSid,tokenGroups;{0}",
  param = c.Value);

@RuleTemplate = "PassThroughClaims"
@RuleName = "Pass through E-mail Address"
c:[Type ==
  "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"]
=> issue(claim = c);

@RuleTemplate = "PassThroughClaims"
@RuleName = "Pass through Branch Managers Role"
c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/role",
  Value =~ "^(?i)Branch\ Managers$"]
=> issue(claim = c);'

$tempFile = [System.IO.Path]::GetTempFileName()

Set-Content -Value $claimRules -LiteralPath $tempFile

Set-AdfsRelyingPartyTrust `
    -TargetName $relyingPartyDisplayName `
    -IssuanceTransformRulesFile $tempFile
```

### # Configure trust relationship from SharePoint farm to AD FS farm

#### # Export token-signing certificate from AD FS farm

```PowerShell
$serviceCert = Get-AdfsCertificate -CertificateType Token-Signing

$certBytes = $serviceCert.Certificate.Export(
    [System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)

$certName = $serviceCert.Certificate.Subject.Replace("CN=", "")

[System.IO.File]::WriteAllBytes(
    "C:\" + $certName + ".cer",
    $certBytes)
```

#### # Copy token-signing certificate to SharePoint server

```PowerShell
$source = "C:\ADFS Signing - fs.technologytoolbox.com.cer"
$destination = "\\EXT-FOOBAR4.extranet.technologytoolbox.com\C$"

net use $destination `
    /USER:EXTRANET\setup-sharepoint-dev
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
Copy-Item $source $destination
```

---

```PowerShell
cls
```

#### # Import token-signing certificate to SharePoint farm

```PowerShell
If ((Get-PSSnapin Microsoft.SharePoint.PowerShell `
    -ErrorAction SilentlyContinue) -eq $null)
{
    Write-Debug "Adding snapin (Microsoft.SharePoint.PowerShell)..."

    $ver = $host | select version

    If ($ver.Version.Major -gt 1)
    {
        $Host.Runspace.ThreadOptions = "ReuseThread"
    }

    Add-PSSnapin Microsoft.SharePoint.PowerShell
}

$certPath = "C:\ADFS Signing - fs.technologytoolbox.com.cer"

$cert = `
    New-Object System.Security.Cryptography.X509Certificates.X509Certificate2(
        $certPath)

$certName = $cert.Subject.Replace("CN=", "")

New-SPTrustedRootAuthority -Name $certName -Certificate $cert
```

#### # Create authentication provider for AD FS

##### # Define claim mappings and unique identifier claim

```PowerShell
$emailClaimMapping = New-SPClaimTypeMapping `
    -IncomingClaimType `
        "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress" `
    -IncomingClaimTypeDisplayName "EmailAddress" `
    -SameAsIncoming

$nameClaimMapping = New-SPClaimTypeMapping `
    -IncomingClaimType `
        "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name" `
    -IncomingClaimTypeDisplayName "Name" `
    -LocalClaimType `
        "http://schemas.securitasinc.com/ws/2017/01/identity/claims/name"

$sidClaimMapping = New-SPClaimTypeMapping `
    -IncomingClaimType `
        "http://schemas.microsoft.com/ws/2008/06/identity/claims/primarysid" `
    -IncomingClaimTypeDisplayName "SID" `
    -SameAsIncoming

$upnClaimMapping = New-SPClaimTypeMapping `
    -IncomingClaimType `
        "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn" `
    -IncomingClaimTypeDisplayName "UPN" `
    -SameAsIncoming

$roleClaimMapping = New-SPClaimTypeMapping `
    -IncomingClaimType `
        "http://schemas.microsoft.com/ws/2008/06/identity/claims/role" `
    -IncomingClaimTypeDisplayName "Role" `
    -SameAsIncoming

$claimsMappings = @(
    $emailClaimMapping,
    $nameClaimMapping,
    $sidClaimMapping,
    $upnClaimMapping,
    $roleClaimMapping)

$identifierClaim = $emailClaimMapping.InputClaimType
```

##### # Create authentication provider for AD FS

```PowerShell
$realm = "urn:sharepoint:securitas"
$signInURL = "https://fs.technologytoolbox.com/adfs/ls"

$cert = Get-SPTrustedRootAuthority |
    where { $_.Name -eq "ADFS Signing - fs.technologytoolbox.com" } |
    select -ExpandProperty Certificate

$authProvider = New-SPTrustedIdentityTokenIssuer `
    -Name "ADFS" `
    -Description "Active Directory Federation Services provider" `
    -Realm $realm `
    -ImportTrustCertificate $cert `
    -ClaimsMappings $claimsMappings `
    -SignInUrl $signInURL `
    -IdentifierClaim $identifierClaim
```

#### # Configure AD FS authentication provider for SecuritasConnect

```PowerShell
$clientPortalUrl = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL

$secureClientPortalUrl = "https://" + $clientPortalUrl.Host

$realm = "urn:sharepoint:securitas:" `
    + ($clientPortalUrl.Host -split '\.' | select -First 1)

$authProvider.ProviderRealms.Add($secureClientPortalUrl, $realm)
$authProvider.Update()
```

### # Configure SecuritasConnect to use AD FS trusted identity provider

```PowerShell
$clientPortalUrl = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL

$trustedIdentityProvider = Get-SPTrustedIdentityTokenIssuer -Identity ADFS

Set-SPWebApplication `
    -Identity $clientPortalUrl.AbsoluteUri `
    -Zone Default `
    -AuthenticationProvider $trustedIdentityProvider `
    -SignInRedirectURL ""

$webApp = Get-SPWebApplication $clientPortalUrl.AbsoluteUri

$defaultZone = [Microsoft.SharePoint.Administration.SPUrlZone]::Default

$webApp.IisSettings[$defaultZone].AllowAnonymous = $false
$webApp.Update()
```

### # Upgrade to "v4.0 Sprint-29" build

---

**WOLVERINE**

```PowerShell
cls
```

#### # Copy new build from TFS drop location

```PowerShell
$newBuild = "4.0.697.0"

$sourcePath = "\\TT-FS01\Builds\Securitas\ClientPortal\$newBuild"

$destPath = "\\EXT-FOOBAR4.extranet.technologytoolbox.com\C$" `
    + "\NotBackedUp\Builds\Securitas\ClientPortal\$newBuild"

robocopy $sourcePath $destPath /E /NP
```

---

```PowerShell
cls
```

#### # Remove previous versions of SecuritasConnect WSPs

```PowerShell
$oldBuild = "4.0.681.1"

Push-Location ("C:\NotBackedUp\Builds\Securitas\ClientPortal\$oldBuild" `
    + "\DeploymentFiles\Scripts")

& '.\Deactivate Features.ps1' -Verbose

& '.\Retract Solutions.ps1' -Verbose

& '.\Delete Solutions.ps1' -Verbose

Pop-Location
```

#### # Install new versions of SecuritasConnect WSPs

```PowerShell
$newBuild = "4.0.697.0"

Push-Location ("C:\NotBackedUp\Builds\Securitas\ClientPortal\$newBuild" `
    + "\DeploymentFiles\Scripts")

& '.\Add Solutions.ps1' -Verbose

& '.\Deploy Solutions.ps1' -Verbose

& '.\Activate Features.ps1' -Verbose
```

> **Important**
>
> If an error occurs when activating the **Securitas.Portal.Web_ClaimsAuthenticationConfiguration** feature, restart the SharePoint services to reload the ADFS claims provider from the new version of **Securitas.Portal.Web** assembly:
>
> ```PowerShell
> & 'C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts\Restart SharePoint Services.cmd'
> ```
>
> After restarting the services, activate the features again:
>
> ```PowerShell
> & '.\Activate Features.ps1' -Verbose
> ```

```PowerShell
Pop-Location
```

#### # Delete old build

```PowerShell
Remove-Item C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.681.1 `
   -Recurse -Force
```

### # Install and configure identity provider for client users

---

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Configure name resolution for identity provider website

```PowerShell
Add-DnsServerResourceRecordA `
    -ComputerName TT-DC04 `
    -Name idp-local-4 `
    -IPv4Address 10.1.20.25 `
    -ZoneName technologytoolbox.com
```

---

#### Deploy identity provider website to front-end web servers

##### Install certificate for secure communication with idp.technologytoolbox.com

---

**WOLVERINE**

```PowerShell
cls
```

###### # Copy certificate from internal file server

```PowerShell
$certFile = "idp-local-4.technologytoolbox.com.pfx"

$sourcePath = "\\TT-FS01\Users$\jjameson\My Documents\Technology Toolbox LLC" `
    + "\Certificates"

$destPath = "\\EXT-FOOBAR4.extranet.technologytoolbox.com" `
    + "\C$\NotBackedUp\Temp"

Copy-Item "$sourcePath\$certFile" $destPath
```

---

```PowerShell
cls
```

###### # Install certificate

```PowerShell
$certPassword = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted for the secure string, type the password for the exported certificate.

```PowerShell
[Uri] $idpUrl = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL.Replace(
    "client",
    "idp")

$idpUrl = [Uri] $idpUrl.AbsoluteUri.Replace(
    "securitasinc.com",
    "technologytoolbox.com")

$certFile = "C:\NotBackedUp\Temp\" + $idpUrl.Host + ".pfx"

Import-PfxCertificate `
    -FilePath $certFile `
    -CertStoreLocation Cert:\LocalMachine\My `
    -Password $certPassword

If ($? -eq $true)
{
    Remove-Item $certFile -Verbose
}
```

##### # Deploy identity provider website to first front-end web server

```PowerShell
Push-Location C:\NotBackedUp\Builds\Securitas\ClientPortal\$newBuild\DeploymentFiles\Scripts

& '.\Configure Identity Provider Website.ps1' `
    -SiteName $idpUrl.Host `
    -Confirm:$false

Pop-Location
```

###### # Add HTTPS binding to identity provider website

```PowerShell
New-WebBinding `
    -Name $idpUrl.Host `
    -Protocol https `
    -Port 443 `
    -HostHeader $idpUrl.Host `
    -SslFlags 1

$cert = Get-ChildItem -Path Cert:\LocalMachine\My |
    Where { $_.Subject -like "CN=$($idpUrl.Host),*" }

New-Item `
    -Path ("IIS:\SslBindings\0.0.0.0!443!" + $idpUrl.Host) `
    -Value $cert `
    -SSLFlags 1
```

###### # Deploy content to identity provider website

```PowerShell
Push-Location C:\NotBackedUp\Builds\Securitas\ClientPortal\$newBuild\Release\_PublishedWebsites\Securitas.Portal.IdentityProvider_Package

attrib -r .\Securitas.Portal.IdentityProvider.SetParameters.xml

$config = Get-Content Securitas.Portal.IdentityProvider.SetParameters.xml

$config = $config -replace `
    "Default Web Site/Securitas.Portal.IdentityProvider_deploy", $idpUrl.Host

$configXml = [xml] $config

$configXml.Save("$pwd\Securitas.Portal.IdentityProvider.SetParameters.xml")

.\Securitas.Portal.IdentityProvider.deploy.cmd /t

.\Securitas.Portal.IdentityProvider.deploy.cmd /y

Pop-Location
```

##### Deploy identity provider website to second web server in farm

(skipped)

```PowerShell
cls
```

#### # Configure database permissions for identity provider website

```PowerShell
$idpHostHeader = $idpUrl.Host

$sqlcmd = @"
USE [master]
GO
CREATE LOGIN [IIS APPPOOL\$idpHostHeader]
FROM WINDOWS
WITH DEFAULT_DATABASE=[master]
GO
USE [SecuritasPortal]
GO
CREATE USER [IIS APPPOOL\$idpHostHeader]
FOR LOGIN [IIS APPPOOL\$idpHostHeader]
GO
EXEC sp_addrolemember N'aspnet_Membership_BasicAccess',
    N'IIS APPPOOL\$idpHostHeader'

EXEC sp_addrolemember N'aspnet_Membership_ReportingAccess',
    N'IIS APPPOOL\$idpHostHeader'

EXEC sp_addrolemember N'aspnet_Roles_BasicAccess',
    N'IIS APPPOOL\$idpHostHeader'

EXEC sp_addrolemember N'aspnet_Roles_ReportingAccess',
    N'IIS APPPOOL\$idpHostHeader'

GO
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

#### # Install and configure token-signing certificate

##### # Install token-signing certificate

```PowerShell
$certPassword = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted for the secure string, type the password for the exported certificate.

```PowerShell
Push-Location ("C:\NotBackedUp\Builds\Securitas\ClientPortal\$newBuild" `
    + "\DeploymentFiles\Certificates")

Import-PfxCertificate `
    -FilePath "Token-signing - idp.securitasinc.com.pfx" `
    -CertStoreLocation Cert:\LocalMachine\My `
    -Password $certPassword

Pop-Location
```

##### # Configure permissions on token-signing certificate

```PowerShell
$serviceAccount = "IIS APPPOOL\$idpHostHeader"
$certThumbprint = "3907EFB9E1B4D549C22200E560D3004778594DDF"

$cert = Get-ChildItem -Path cert:\LocalMachine\My |
    where { $_.ThumbPrint -eq $certThumbprint }

$keyPath = [System.IO.Path]::Combine(
    "$env:ProgramData\Microsoft\Crypto\RSA\MachineKeys",
    $cert.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName)

$acl = Get-Acl -Path $keyPath

$accessRule = New-Object `
```

    -TypeName System.Security.AccessControl.FileSystemAccessRule `\
    -ArgumentList \$serviceAccount, "Read", "Allow"

```PowerShell
$acl.AddAccessRule($accessRule)

Set-Acl -Path $keyPath -AclObject $acl
```

---

**EXT-ADFS02A - Run as EXTRANET\\jjameson-admin**

```PowerShell
cls
```

#### # Configure claims provider trust in AD FS for identity provider

##### # Create claims provider trust in AD FS

```PowerShell
$idpHostHeader = "idp-local-4.technologytoolbox.com"

Add-AdfsClaimsProviderTrust `
    -Name $idpHostHeader `
    -MetadataURL "https://$idpHostHeader/core/wsfed/metadata" `
    -MonitoringEnabled $true `
    -AutoUpdateEnabled $true `
    -SignatureAlgorithm http://www.w3.org/2000/09/xmldsig#rsa-sha1
```

##### # Configure claim acceptance rules for claims provider trust

```PowerShell
$claimsProviderTrustName = $idpHostHeader

$claimRules = `
'@RuleTemplate = "PassThroughClaims"
@RuleName = "Pass through E-mail Address"
c:[Type ==
  "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"]
=> issue(claim = c);

@RuleTemplate = "PassThroughClaims"
@RuleName = "Pass through Role"
c:[Type ==
  "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"]
=> issue(claim = c);'

$tempFile = [System.IO.Path]::GetTempFileName()

Set-Content -Value $claimRules -LiteralPath $tempFile

Set-AdfsClaimsProviderTrust `
    -TargetName $claimsProviderTrustName `
    -AcceptanceTransformRulesFile $tempFile
```

---

```PowerShell
cls
```

### # Associate client email domains with claims provider trust

#### # Update email addresses for non-Production environments

##### # Add environment-specific prefix to domain names in email addresses

```PowerShell
$environmentPrefix = "local-4"

$sqlcmd = @"
USE SecuritasPortal
GO

UPDATE dbo.aspnet_Membership
SET
  Email =
    LEFT(Email, CHARINDEX('@', Email, 0) - 1)
      + '@$environmentPrefix.'
      + RIGHT(Email, LEN(Email) - CHARINDEX('@', Email, 0))
WHERE
  Email NOT LIKE '%securitasinc.com'

UPDATE dbo.aspnet_Membership
SET LoweredEmail = LOWER(Email)
WHERE Email NOT LIKE '%securitasinc.com'
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

##### # Update Branch Manager mapping file

```PowerShell
Push-Location ("C:\NotBackedUp\Builds\Securitas\ClientPortal\$newBuild" `
    + "\DeploymentFiles\Scripts")

attrib -r .\Branch-Manager-Mapping.csv

$branchManagerMapping = Import-Csv .\Branch-Manager-Mapping.csv

$branchManagerMapping |
    ForEach-Object {
        $email = $_.EmailAddress

        If (($email.EndsWith("securitasinc.com") -eq $false) `
            -and ($email.EndsWith("technologytoolbox.com") -eq $false))
        {
            $email = $email.Replace("@", "@$environmentPrefix.")
        }

        $output = New-Object -TypeName PSObject

        $output | Add-Member `
            -MemberType NoteProperty `
            -Name BranchManagerUserName `
            -Value $_.BranchManagerUserName

        $output | Add-Member `
            -MemberType NoteProperty `
            -Name EmailAddress `
            -Value $email

        $output
    } |
    Export-Csv `
        -Path .\Branch-Manager-Mapping.csv `
        -Encoding UTF8 `
        -NoTypeInformation

Pop-Location
```

##### # Create input file for synchronizing SharePoint user email addresses

```PowerShell
Push-Location ("C:\NotBackedUp\Builds\Securitas\ClientPortal\$newBuild" `
    + "\DeploymentFiles\Scripts")

$sqlcmd = @"
USE SecuritasPortal
GO

SELECT
    Username AS LoginName
    , Email
FROM
    dbo.aspnet_Users U
    INNER JOIN dbo.aspnet_Membership M
    ON U.UserId = M.UserId
WHERE
    Email NOT LIKE '%securitasinc.com'
ORDER BY
    Username
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false |
    Export-Csv -Path User-Email.csv -Encoding UTF8 -NoTypeInformation

Set-Location C:
```

##### # Synchronize SharePoint user email addresses

```PowerShell
.\Sync-SPUserEmail.ps1 | Format-Table -AutoSize

Pop-Location
```

#### # Create configuration file for AD FS claims provider trust

```PowerShell
$sqlcmd = @"
USE SecuritasPortal
GO

SELECT DISTINCT
  LOWER(
    REVERSE(
      SUBSTRING(
        REVERSE(Email),
        0,
        CHARINDEX('@', REVERSE(Email))))) AS OrganizationalAccountSuffix,
  '$($idpUrl.Host)' AS TargetName
FROM
  dbo.aspnet_Membership
WHERE
  Email NOT LIKE '%securitasinc.com'
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false |
    Export-Csv C:\NotBackedUp\Temp\ADFS-Claims-Provider-Trust-Configuration.csv

Set-Location C:

Notepad C:\NotBackedUp\Temp\ADFS-Claims-Provider-Trust-Configuration.csv
```

---

**EXT-ADFS02A - Run as EXTRANET\\jjameson-admin**

```PowerShell
cls
```

#### # Set organizational account suffixes on AD FS claims provider trust

```PowerShell
$configFile = "ADFS-Claims-Provider-Trust-Configuration.csv"
$source = ("\\EXT-FOOBAR4.extranet.technologytoolbox.com\C$" `
    + "\NotBackedUp\Temp")

$destination = "C:\NotBackedUp\Temp"

net use $source `
    /USER:EXTRANET\setup-sharepoint-dev
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
If ((Test-Path $destination) -eq $false)
{
    New-Item -ItemType Directory -Path $destination
}

Push-Location $destination

copy "$source\$configFile" .

$claimsProviderTrustName = Import-Csv -Path ".\$configFile" |
    select -First 1 -ExpandProperty TargetName

$orgAccountSuffixes = `
    Import-Csv ".\$configFile" |
        where { $_.TargetName -eq $claimsProviderTrustName } |
        select -ExpandProperty OrganizationalAccountSuffix

Set-AdfsClaimsProviderTrust `
    -TargetName $claimsProviderTrustName `
    -OrganizationalAccountSuffix $orgAccountSuffixes

Pop-Location
```

---

```PowerShell
cls
```

### # Migrate users

#### # Backup content database for Cloud Portal

```PowerShell
$sqlcmd = @"
-- Create copy-only database backup

DECLARE @databaseName VARCHAR(50) = 'WSS_Content_CloudPortal'

DECLARE @backupDirectory VARCHAR(255)

EXEC master.dbo.xp_instance_regread
    N'HKEY_LOCAL_MACHINE'
    , N'Software\Microsoft\MSSQLServer\MSSQLServer'
    , N'BackupDirectory'
    , @backupDirectory OUTPUT

DECLARE @backupFilePath VARCHAR(255) =
    @backupDirectory + '\Full\' + @databaseName + '.bak'

DECLARE @backupName VARCHAR(100) = @databaseName + '-Full Database Backup'

BACKUP DATABASE @databaseName
    TO DISK = @backupFilePath
    WITH COMPRESSION
        , COPY_ONLY
        , FORMAT
        , INIT
        , NAME = @backupName
        , STATS = 5

GO
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

#### # Migrate users in SharePoint to AD FS trusted identity provider

```PowerShell
Push-Location C:\NotBackedUp\Builds\Securitas\ClientPortal\$newBuild\DeploymentFiles\Scripts

$stopwatch = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-Stopwatch.ps1

& '.\Migrate Users.ps1' -Verbose

$stopwatch.Stop()
C:\NotBackedUp\Public\Toolbox\PowerShell\Write-ElapsedTime.ps1 $stopwatch
```

> **Note**
>
> Expect the previous operation to complete in approximately 10 seconds.

> **Important**
>
> Restart PowerShell to ensure database connections are closed.

```Console
exit
```

#### # Restore content database for Cloud Portal

##### # Stop SharePoint services

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts\Stop SharePoint Services.cmd'
```

##### # Restore content database

```PowerShell
$sqlcmd = @"
DECLARE @databaseName VARCHAR(50) = 'WSS_Content_CloudPortal'

DECLARE @backupDirectory VARCHAR(255)

EXEC master.dbo.xp_instance_regread
    N'HKEY_LOCAL_MACHINE'
    , N'Software\Microsoft\MSSQLServer\MSSQLServer'
    , N'BackupDirectory'
    , @backupDirectory OUTPUT

DECLARE @backupFilePath VARCHAR(255) =
    @backupDirectory + '\Full\' + @databaseName + '.bak'

RESTORE DATABASE @databaseName
    FROM DISK = @backupFilePath
    WITH REPLACE
        , STATS = 5

GO
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

##### # Start SharePoint services

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts\Start SharePoint Services.cmd'
```

```PowerShell
cls
```

#### # Update user names in SecuritasPortal database

```PowerShell
Push-Location ("C:\NotBackedUp\Builds\Securitas\ClientPortal\$newBuild" `
    + "\DeploymentFiles\Scripts")

& '.\Update SecuritasPortal UserNames.ps1'

& "C:\Program Files (x86)\Microsoft SQL Server\120\Tools\Binn\ManagementStudio\Ssms.exe" '.\Update SecuritasPortal UserNames.sql'
```

> **Note**
>
> Execute the SQL script to update the user names in the database.

```Console
cls
Pop-Location
```

### # Update permissions on template sites

```PowerShell
$clientPortalUrl = $env:SECURITAS_CLIENT_PORTAL_URL

$sites = @(
    "/Template-Sites/Post-Orders-en-US",
    "/Template-Sites/Post-Orders-en-CA",
    "/Template-Sites/Post-Orders-fr-CA")

$sites |
    % {
        $siteUrl = $clientPortalUrl + $_

        $site = Get-SPSite -Identity $siteUrl

        $group = $site.RootWeb.AssociatedVisitorGroup

        $group.Users | % { $group.Users.Remove($_) }

        $group.AddUser(
            "c:0-.t|adfs|Branch Managers",
            $null,
            "Branch Managers",
            $null)
    }
```

### # Configure AD FS claim provider

```PowerShell
$tokenIssuer = Get-SPTrustedIdentityTokenIssuer -Identity ADFS
$tokenIssuer.ClaimProviderName = "Securitas ADFS Claim Provider"
$tokenIssuer.Update()
```

---

**EXT-ADFS02A - Run as EXTRANET\\jjameson-admin**

```PowerShell
cls
```

### # Customize AD FS login pages

#### # Customize text and image on login pages for SecuritasConnect relying party

```PowerShell
$clientPortalUrl = [Uri] "http://client-local-4.securitasinc.com"

$idpHostHeader = "idp-local-4.technologytoolbox.com"

$relyingPartyDisplayName = $clientPortalUrl.Host

Set-AdfsRelyingPartyWebContent `
    -TargetRelyingPartyName $relyingPartyDisplayName `
    -CompanyName "SecuritasConnect®" `
    -OrganizationalNameDescriptionText `
        "Enter your Securitas e-mail address and password below." `
    -SignInPageDescription $null `
    -HomeRealmDiscoveryOtherOrganizationDescriptionText `
        "Enter your e-mail address below."

$tempFile = [System.Io.Path]::GetTempFileName()
$tempFile = $tempFile.Replace(".tmp", ".jpg")

Invoke-WebRequest `
    -Uri https://$idpHostHeader/images/illustration.jpg `
    -OutFile $tempFile

Set-AdfsRelyingPartyWebTheme `
    -TargetRelyingPartyName $relyingPartyDisplayName `
    -Illustration @{ path = $tempFile }

Remove-Item $tempFile
```

#### # Configure custom CSS and JavaScript files for additional customizations

```PowerShell
$relyingPartyDisplayName = $clientPortalUrl.Host

$tempCssFile = [System.Io.Path]::GetTempFileName()
$tempCssFile = $tempCssFile.Replace(".tmp", ".css")

$tempJsFile = [System.Io.Path]::GetTempFileName()
$tempJsFile = $tempJsFile.Replace(".tmp", ".js")

Invoke-WebRequest `
    -Uri https://$idpHostHeader/css/styles.css `
    -OutFile $tempCssFile

Invoke-WebRequest `
    -Uri https://$idpHostHeader/js/onload.js `
    -OutFile $tempJsFile

Set-AdfsRelyingPartyWebTheme `
    -TargetRelyingPartyName $relyingPartyDisplayName `
    -OnLoadScriptPath $tempJsFile `
    -StyleSheet @{ path = $tempCssFile }

Remove-Item $tempCssFile
Remove-Item $tempJsFile
```

---

### # Upgrade Cloud Portal to "v2.0 Sprint-21" release

---

**WOLVERINE**

```PowerShell
cls
```

#### # Copy new build from TFS drop location

```PowerShell
$newBuild = "2.0.125.0"

$sourcePath = "\\TT-FS01\Builds\Securitas\CloudPortal\$newBuild"

$destPath = "\\EXT-FOOBAR4.extranet.technologytoolbox.com\C$" `
    + "\NotBackedUp\Builds\Securitas\CloudPortal\$newBuild"

robocopy $sourcePath $destPath /E /NP
```

---

```PowerShell
cls
```

#### # Remove previous versions of Cloud Portal WSP

```PowerShell
$oldBuild = "2.0.122.0"

Push-Location ("C:\NotBackedUp\Builds\Securitas\CloudPortal\$oldBuild" `
    + "\DeploymentFiles\Scripts")

& '.\Deactivate Features.ps1' -Verbose

& '.\Retract Solutions.ps1' -Verbose

& '.\Delete Solutions.ps1' -Verbose

Pop-Location
```

#### # Install new versions of Cloud Portal WSP

```PowerShell
$newBuild = "2.0.125.0"

Push-Location ("C:\NotBackedUp\Builds\Securitas\CloudPortal\$newBuild" `
    + "\DeploymentFiles\Scripts")

& '.\Add Solutions.ps1' -Verbose

& '.\Deploy Solutions.ps1' -Verbose

& '.\Activate Features.ps1' -Verbose

Pop-Location
```

```PowerShell
cls
```

#### # Delete old build

```PowerShell
Remove-Item C:\NotBackedUp\Builds\Securitas\CloudPortal\2.0.122.0 `
   -Recurse -Force
```

### # Upgrade Employee Portal to "v1.0 Sprint-6" release

---

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Copy new build from TFS drop location

```PowerShell
$build = "1.0.38.0"

$sourcePath = "\\TT-FS01\Builds\Securitas\EmployeePortal\$build"

$destPath = "\\EXT-FOOBAR4.extranet.technologytoolbox.com\C$" `
    + "\NotBackedUp\Builds\Securitas\EmployeePortal\$build"

robocopy $sourcePath $destPath /E
```

---

```PowerShell
$build = "1.0.38.0"
```

#### # Backup Employee Portal Web.config file

```PowerShell
[Uri] $employeePortalUrl = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL.Replace(
    "client",
    "employee")

[String] $employeePortalHostHeader = $employeePortalUrl.Host

Copy-Item C:\inetpub\wwwroot\$employeePortalHostHeader\Web.config `
    "C:\NotBackedUp\Temp\Web - $employeePortalHostHeader.config"
```

#### # Deploy Employee Portal website on Central Administration server

```PowerShell
Push-Location ("C:\NotBackedUp\Builds\Securitas\EmployeePortal\$build" `
    + "\Debug\_PublishedWebsites\Web_Package")

attrib -r .\Web.SetParameters.xml

$config = Get-Content Web.SetParameters.xml

$config = $config -replace `
    "Default Web Site/Web_deploy", $employeePortalHostHeader

$configXml = [xml] $config

$configXml.Save("$pwd\Web.SetParameters.xml")

.\Web.deploy.cmd /t

.\Web.deploy.cmd /y

Pop-Location
```

#### # Configure application settings and web service URLs

```PowerShell
Push-Location ("C:\inetpub\wwwroot\" + $employeePortalHostHeader)

(Get-Content Web.config) `
    -replace '<add key="GoogleAnalytics.TrackingId" value="" />',
        '<add key="GoogleAnalytics.TrackingId" value="UA-25949832-3" />' `
    -replace 'https://client-local', 'https://client-local-4' `
    -replace 'https://cloud2-local', 'https://cloud2-local-4' |
    Set-Content Web.config

Pop-Location

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    "C:\NotBackedUp\Temp\Web - $employeePortalHostHeader.config" `
    C:\inetpub\wwwroot\$employeePortalHostHeader\Web.config
```

#### Deploy website content to other web servers in the farm

(skipped)

```PowerShell
cls
```

#### # Update Post Orders URLs in Employee Portal

##### # Update Post Orders URL in Employee Portal SharePoint site

```PowerShell
Start-Process ($env:SECURITAS_CLOUD_PORTAL_URL `
```

    + "/sites/Employee-Portal/Lists/Shortcuts")

```PowerShell
cls
```

##### # Update Post Orders URLs in SecuritasPortal database

```PowerShell
$clientPortalUrl = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL

$secureClientPortalUrl = "https://" + $clientPortalUrl.Host

$newPostOrdersUrl = "$secureClientPortalUrl/Branch-Management/Post-Orders"

$sqlcmd = @"
USE SecuritasPortal
GO

UPDATE Employee.UserShortcuts
SET UrlValue = '$newPostOrdersUrl'
WHERE UrlValue =
    'https://client2.securitasinc.com/Branch-Management/Post-Orders'
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

#### # Delete old build

```PowerShell
Remove-Item C:\NotBackedUp\Builds\Securitas\EmployeePortal\1.0.32.0 -Recurse -Force
```

```PowerShell
cls
```

### # Resume Search Service Application

```PowerShell
Get-SPEnterpriseSearchServiceApplication "Search Service Application" |
    Resume-SPEnterpriseSearchServiceApplication
```

---

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Update VM baseline

```PowerShell
$vmHost = "WOLVERINE"
$vmName = "EXT-FOOBAR4"

C:\NotBackedUp\Public\Toolbox\PowerShell\Update-VMBaseline `
    -ComputerName $vmHost `
    -Name $vmName `
    -Confirm:$false

$newSnapshotName = ("Baseline Client Portal 4.0.697.0" `
```

    + " / Cloud Portal 2.0.125.0" `\
    + " / Employee Portal 1.0.38.0")

```PowerShell
Get-VMSnapshot -ComputerName $vmHost -VMName $vmName |
    Rename-VMSnapshot -NewName $newSnapshotName
```

---

## Expand C: drive

### Delete checkpoint

### Expand primary VHD for virtual machine

New size: 65 GB

### # Extend partition

```PowerShell
$driveLetter = "C"

$partition = Get-Partition -DriveLetter $driveLetter |
    where { $_.DiskNumber -ne $null }

$size = (Get-PartitionSupportedSize `
    -DiskNumber $partition.DiskNumber `
    -PartitionNumber $partition.PartitionNumber)

Resize-Partition `
    -DiskNumber $partition.DiskNumber `
    -PartitionNumber $partition.PartitionNumber `
    -Size $size.SizeMax
```

## Upgrade SecuritasConnect to "v4.0 Sprint-30" release

---

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Copy new build from TFS drop location

```PowerShell
$newBuild = "4.0.701.0"

$sourcePath = "\\TT-FS01\Builds\Securitas\ClientPortal\$newBuild"

$destPath = "\\EXT-FOOBAR4.extranet.technologytoolbox.com\C$" `
    + "\NotBackedUp\Builds\Securitas\ClientPortal\$newBuild"

robocopy $sourcePath $destPath /E
```

---

```PowerShell
cls
```

### # Upgrade SecuritasConnect WSPs

#### # Remove previous versions of SecuritasConnect WSPs

```PowerShell
$oldBuild = "4.0.697.0"

Push-Location ("C:\NotBackedUp\Builds\Securitas\ClientPortal\$oldBuild" `
    + "\DeploymentFiles\Scripts")

& '.\Deactivate Features.ps1' -Verbose

& '.\Retract Solutions.ps1' -Verbose

& '.\Delete Solutions.ps1' -Verbose

Pop-Location
```

```PowerShell
cls
```

#### # Install new versions of SecuritasConnect WSPs

```PowerShell
$newBuild = "4.0.701.0"

Push-Location ("C:\NotBackedUp\Builds\Securitas\ClientPortal\$newBuild" `
    + "\DeploymentFiles\Scripts")

& '.\Add Solutions.ps1' -Verbose

& '.\Deploy Solutions.ps1' -Verbose

& '.\Activate Features.ps1' -Verbose

Pop-Location
```

```PowerShell
cls
```

### # Delete old build

```PowerShell
Remove-Item C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.697.0 `
   -Recurse -Force
```

## Refresh SecuritasPortal database

### Restore SecuritasPortal database backup from Production

---

**WOLVERINE**

```PowerShell
cls
```

#### # Copy database backup from Production

```PowerShell
$backupFile = "SecuritasPortal_backup_2017_10_01_000021_4616418.bak"

$source = "\\TT-FS01\Archive\Clients\Securitas\Backups"

$destination = "\\EXT-FOOBAR4.extranet.technologytoolbox.com\Z$" `
    + "\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full"

robocopy $source $destination $backupFile
```

---

```PowerShell
cls
```

#### # Stop IIS

```PowerShell
iisreset /stop
```

#### # Restore database backup

```PowerShell
$backupFile = "SecuritasPortal_backup_2017_10_01_000021_4616418.bak"

$sqlcmd = @"
DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\$backupFile'

RESTORE DATABASE SecuritasPortal
  FROM DISK = @backupFilePath
  WITH
    REPLACE,
    STATS = 10

GO
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
```

#### # Configure security on SecuritasPortal database

```PowerShell
[Uri] $clientPortalUrl = $null

If ($env:COMPUTERNAME -eq "784816-UATSQL")
{
    $clientPortalUrl = [Uri] "http://client-qa.securitasinc.com"
}
Else
{
    # Development environment is assumed to have SECURITAS_CLIENT_PORTAL_URL
    # environment variable set (since SQL Server is installed on same server as
    # SharePoint)
    $clientPortalUrl = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL
}

[Uri] $employeePortalUrl = [Uri] $clientPortalUrl.AbsoluteUri.Replace(
    "client",
    "employee")

[String] $employeePortalHostHeader = $employeePortalUrl.Host

[String] $farmServiceAccount = "EXTRANET\s-sp-farm-dev"
[String] $clientPortalServiceAccount = "EXTRANET\s-web-client-dev"
[String] $cloudPortalServiceAccount = "EXTRANET\s-web-cloud-dev"
[String[]] $employeePortalAccounts = "IIS APPPOOL\$employeePortalHostHeader"

If ($employeePortalHostHeader -eq "employee-qa.securitasinc.com")
{
    $farmServiceAccount = "SEC\s-sp-farm-qa"
    $clientPortalServiceAccount = "SEC\s-web-client-qa"
    $cloudPortalServiceAccount = "SEC\s-web-cloud-qa"
    $employeePortalAccounts = @(
        'SEC\784813-UATSPAPP$',
        'SEC\784815-UATSPWFE$')
}

[String] $sqlcmd = @"
USE SecuritasPortal
GO

CREATE USER [$farmServiceAccount]
FOR LOGIN [$farmServiceAccount]
GO
ALTER ROLE aspnet_Membership_BasicAccess
ADD MEMBER [$farmServiceAccount]
GO
ALTER ROLE aspnet_Membership_ReportingAccess
ADD MEMBER [$farmServiceAccount]
GO
ALTER ROLE aspnet_Roles_BasicAccess
ADD MEMBER [$farmServiceAccount]
GO
ALTER ROLE aspnet_Roles_ReportingAccess
ADD MEMBER [$farmServiceAccount]
GO

CREATE USER [$clientPortalServiceAccount]
FOR LOGIN [$clientPortalServiceAccount]
GO
ALTER ROLE aspnet_Membership_FullAccess
ADD MEMBER [$clientPortalServiceAccount]
GO
ALTER ROLE aspnet_Profile_BasicAccess
ADD MEMBER [$clientPortalServiceAccount]
GO
ALTER ROLE aspnet_Roles_BasicAccess
ADD MEMBER [$clientPortalServiceAccount]
GO
ALTER ROLE aspnet_Roles_ReportingAccess
ADD MEMBER [$clientPortalServiceAccount]
GO
ALTER ROLE Customer_Reader
ADD MEMBER [$clientPortalServiceAccount]
GO

CREATE USER [$cloudPortalServiceAccount]
FOR LOGIN [$cloudPortalServiceAccount]
GO
ALTER ROLE Customer_Provisioner
ADD MEMBER [$cloudPortalServiceAccount]
GO
"@

$employeePortalAccounts |
    ForEach-Object {
        $employeePortalAccount = $_

        $sqlcmd += [System.Environment]::NewLine

        $sqlcmd += @"
CREATE USER [$employeePortalAccount]
FOR LOGIN [$employeePortalAccount]
GO
ALTER ROLE Employee_FullAccess
ADD MEMBER [$employeePortalAccount]
GO
"@
    }

$sqlcmd += [System.Environment]::NewLine
$sqlcmd += @"
DROP USER [SEC\258521-VM4$]
DROP USER [SEC\424642-SP$]
DROP USER [SEC\424646-SP$]
DROP USER [SEC\784806-SPWFE1$]
DROP USER [SEC\784807-SPWFE2$]
DROP USER [SEC\784810-SPAPP$]
DROP USER [SEC\s-sp-farm]
DROP USER [SEC\s-web-client]
DROP USER [SEC\s-web-cloud]
DROP USER [SEC\svc-sharepoint-2010]
DROP USER [SEC\svc-web-securitas]
DROP USER [SEC\svc-web-securitas-20]
GO
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose

Set-Location C:
```

#### # Start IIS

```PowerShell
iisreset /start
```

#### # Associate users to TECHTOOLBOX\\smasters

```PowerShell
$sqlcmd = @"
USE [SecuritasPortal]
GO

INSERT INTO Customer.BranchManagerAssociatedUsers
SELECT 'smasters@technologytoolbox.com', AssociatedUserName
FROM Customer.BranchManagerAssociatedUsers
WHERE BranchManagerUserName = 'Jeremy.Jameson@securitasinc.com'
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
```

---

**WOLVERINE**

#### Configure SSO credentials for users

##### Configure TrackTik credentials for Branch Manager

[https://client-local-4.securitasinc.com/_layouts/Securitas/EditProfile.aspx](https://client-local-4.securitasinc.com/_layouts/Securitas/EditProfile.aspx)

Branch Manager: **smasters@technologytoolbox.com**\
TrackTik username:** opanduro2m**

##### HACK: Update TrackTik password for Angela.Parks

[https://client-local-4.securitasinc.com/_layouts/Securitas/EditProfile.aspx](https://client-local-4.securitasinc.com/_layouts/Securitas/EditProfile.aspx)

##### HACK: Update TrackTik password for bbarthelemy-demo

[https://client-local-4.securitasinc.com/_layouts/Securitas/EditProfile.aspx](https://client-local-4.securitasinc.com/_layouts/Securitas/EditProfile.aspx)

---

## Upgrade Cloud Portal to "v2.0 Sprint-22" release

---

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Copy new build from TFS drop location

```PowerShell
$newBuild = "2.0.131.0"

$sourcePath = "\\TT-FS01\Builds\Securitas\CloudPortal\$newBuild"

$destPath = "\\EXT-FOOBAR4.extranet.technologytoolbox.com\C$" `
    + "\NotBackedUp\Builds\Securitas\CloudPortal\$newBuild"

robocopy $sourcePath $destPath /E
```

---

```PowerShell
cls
```

### # Upgrade Cloud Portal WSPs

#### # Remove previous versions of Cloud Portal WSPs

```PowerShell
$oldBuild = "2.0.125.0"

Push-Location ("C:\NotBackedUp\Builds\Securitas\CloudPortal\$oldBuild" `
    + "\DeploymentFiles\Scripts")

& '.\Deactivate Features.ps1' -Verbose

& '.\Retract Solutions.ps1' -Verbose

& '.\Delete Solutions.ps1' -Verbose

Pop-Location
```

```PowerShell
cls
```

#### # Install new versions of Cloud Portal WSPs

```PowerShell
$newBuild = "2.0.131.0"

Push-Location ("C:\NotBackedUp\Builds\Securitas\CloudPortal\$newBuild" `
    + "\DeploymentFiles\Scripts")

& '.\Add Solutions.ps1' -Verbose

& '.\Deploy Solutions.ps1' -Verbose

& '.\Activate Features.ps1' -Verbose

Pop-Location
```

```PowerShell
cls
```

### # Delete old build

```PowerShell
Remove-Item C:\NotBackedUp\Builds\Securitas\CloudPortal\2.0.125.0 `
   -Recurse -Force
```

---

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Update VM baseline

```PowerShell
$vmHost = "WOLVERINE"
$vmName = "EXT-FOOBAR4"

C:\NotBackedUp\Public\Toolbox\PowerShell\Update-VMBaseline `
    -ComputerName $vmHost `
    -Name $vmName `
    -Confirm:$false

$newSnapshotName = ("Baseline Client Portal 4.0.701.0" `
```

    + " / Cloud Portal 2.0.131.0" `\
    + " / Employee Portal 1.0.38.0")

```PowerShell
Get-VMSnapshot -ComputerName $vmHost -VMName $vmName |
    Rename-VMSnapshot -NewName $newSnapshotName
```

---

## Issue - "Access Denied" error with SharePoint Trace Service

### Symptom

Numerous ULS log entries:

Process: wsstracing.exe\
Produce: SharePoint Foundation\
Category: Unified Logging Service\
EventID: adr4q\
Level: Unexpected\
Message: Trace Service encountered an unexpected exception when processing usage event. Detail exception message: Create store file error.. Win32 error code=5.

### Problem

**Local Service** account has **Write** permission on Trace Log folder but does not have **Read** permission:

```PowerShell
$logsFolder = ("C:\Program Files\Common Files\microsoft shared" `
    + "\Web Server Extensions\15\LOGS")

icacls $logsFolder

C:\...\15\LOGS BUILTIN\Administrators:(OI)(CI)(F)
               NT AUTHORITY\LOCAL SERVICE:(OI)(CI)(W,Rc,RD,DC)
               ...
```

### Solution

Grant** Local Service** account **Read** permission on Trace Log folder (in addition to **Write** permission):

```PowerShell
$logsFolder = ("C:\Program Files\Common Files\microsoft shared" `
    + "\Web Server Extensions\15\LOGS")

icacls $logsFolder /grant "NT AUTHORITY\LOCAL SERVICE:(OI)(CI)(R,W,DC)"
```

```PowerShell
cls
```

## # Clean up WinSxS folder

```PowerShell
Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase
```

## # Clean up Windows Update files

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse
```

## Upgrade Employee Portal to "v1.0 Sprint-7" release

DEV - Upgrade and reconfigure Node.js

#### Upgrade Node.js

---

**WOLVERINE**

```PowerShell
cls
```

##### # Copy installer from internal file server

```PowerShell
$installer = "node-v8.9.1-x64.msi"

$source = "\\TT-FS01\Products\node.js"
$destination = '\\EXT-FOOBAR4\C$\NotBackedUp\Temp'

robocopy $source $destination $installer
```

---

```PowerShell
cls
```

##### # Install new version of Node.js

```PowerShell
Start-Process `
    -FilePath C:\NotBackedUp\Temp\node-v8.9.1-x64.msi `
    -Wait
```

#### # Change NPM file locations to avoid issues with redirected folders

```PowerShell
notepad "C:\Program Files\nodejs\node_modules\npm\npmrc"
```

---

**C:\\Program Files\\nodejs\\node_modules\\npm\\npmrc**

```Text
;prefix=${APPDATA}\npm
prefix=${LOCALAPPDATA}\npm
cache=${LOCALAPPDATA}\npm-cache
```

---

```PowerShell
cls
```

#### # Change NPM "global" locations to shared location for all users

```PowerShell
npm config --global set prefix "$env:ALLUSERSPROFILE\npm"

npm config --global set cache "$env:ALLUSERSPROFILE\npm-cache"
```

#### # Clear NPM cache

```PowerShell
npm cache clean --force
```

```PowerShell
cls
```

### # DEV - Remove obsolete global NPM packages

```PowerShell
npm uninstall --global grunt-cli

npm uninstall --global gulp

npm uninstall --global bower

npm uninstall --global karma-cli

npm uninstall --global rimraf
```

### # DEV - Install new global NPM packages

```PowerShell
npm install --global --no-optional @angular/cli@1.4.9

npm install --global rimraf@2.6.2
```

### DEV - Install TypeScript 2.6.2 for Visual Studio 2015

---

**WOLVERINE**

```PowerShell
cls
```

##### # Copy installer from internal file server

```PowerShell
$installer = "TypeScript_Dev14Full.exe"

$source = ("\\TT-FS01\Products\Microsoft\Visual Studio 2015" `
     + "\TypeScript 2.6.2 for Visual Studio 2015")

$destination = '\\EXT-FOOBAR4\C$\NotBackedUp\Temp'

robocopy $source $destination $installer
```

---

```PowerShell
cls
```

##### # Install new version of TypeScript for Visual Studio 2015

```PowerShell
Start-Process `
    -FilePath C:\NotBackedUp\Temp\TypeScript_Dev14Full.exe `
    -Wait
```

---

**WOLVERINE**

```PowerShell
cls
```

### # Copy new build from TFS drop location

```PowerShell
$build = "1.0.49.0"

$sourcePath = "\\TT-FS01\Builds\Securitas\EmployeePortal\$build"

$destPath = "\\EXT-FOOBAR4.extranet.technologytoolbox.com\C$" `
    + "\NotBackedUp\Builds\Securitas\EmployeePortal\$build"

robocopy $sourcePath $destPath /E
```

---

```PowerShell
$build = "1.0.49.0"
```

### # Backup Employee Portal Web.config file

```PowerShell
[Uri] $employeePortalUrl = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL.Replace(
    "client",
    "employee")

[String] $employeePortalHostHeader = $employeePortalUrl.Host

Copy-Item C:\inetpub\wwwroot\$employeePortalHostHeader\Web.config `
    "C:\NotBackedUp\Temp\Web - $employeePortalHostHeader.config"
```

### # Deploy Employee Portal website on Central Administration server

```PowerShell
Push-Location ("C:\NotBackedUp\Builds\Securitas\EmployeePortal\$build" `
    + "\Debug\_PublishedWebsites\Web_Package")

attrib -r .\Web.SetParameters.xml

$config = Get-Content Web.SetParameters.xml

$config = $config -replace `
    "Default Web Site/Web_deploy", $employeePortalHostHeader

$configXml = [xml] $config

$configXml.Save("$pwd\Web.SetParameters.xml")

.\Web.deploy.cmd /t

.\Web.deploy.cmd /y

Pop-Location
```

### # Configure application settings and web service URLs

```PowerShell
Push-Location ("C:\inetpub\wwwroot\" + $employeePortalHostHeader)

(Get-Content Web.config) `
    -replace '<add key="GoogleAnalytics.TrackingId" value="" />',
        '<add key="GoogleAnalytics.TrackingId" value="UA-25949832-3" />' `
    -replace 'https://client-local', 'https://client-local-4' `
    -replace 'https://cloud2-local', 'https://cloud2-local-4' |
    Set-Content Web.config

Pop-Location

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    "C:\NotBackedUp\Temp\Web - $employeePortalHostHeader.config" `
    C:\inetpub\wwwroot\$employeePortalHostHeader\Web.config
```

### Deploy website content to other web servers in the farm

(skipped)

### # Delete old build

```PowerShell
Remove-Item C:\NotBackedUp\Builds\Securitas\EmployeePortal\1.0.38.0 -Recurse -Force
```

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Update VM baseline

```PowerShell
$vmHost = "WOLVERINE"
$vmName = "EXT-FOOBAR4"

C:\NotBackedUp\Public\Toolbox\PowerShell\Update-VMBaseline `
    -ComputerName $vmHost `
    -Name $vmName `
    -Confirm:$false

$newSnapshotName = ("Baseline Client Portal 4.0.701.0" `
```

    + " / Cloud Portal 2.0.131.0" `\
    + " / Employee Portal 1.0.49.0")

```PowerShell
Get-VMSnapshot -ComputerName $vmHost -VMName $vmName |
    Rename-VMSnapshot -NewName $newSnapshotName
```

---

## Upgrade Employee Portal to "v1.0 Sprint-8" release

---

**WOLVERINE**

```PowerShell
cls
```

### # Copy new build from TFS drop location

```PowerShell
$build = "1.0.58.0"

$sourcePath = "\\TT-FS01\Builds\Securitas\EmployeePortal\$build"

$destPath = "\\EXT-FOOBAR4.extranet.technologytoolbox.com\C$" `
    + "\NotBackedUp\Builds\Securitas\EmployeePortal\$build"

robocopy $sourcePath $destPath /E
```

---

```PowerShell
$build = "1.0.58.0"
```

### # Backup Employee Portal Web.config file

```PowerShell
[Uri] $employeePortalUrl = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL.Replace(
    "client",
    "employee")

[String] $employeePortalHostHeader = $employeePortalUrl.Host

Copy-Item C:\inetpub\wwwroot\$employeePortalHostHeader\Web.config `
    "C:\NotBackedUp\Temp\Web - $employeePortalHostHeader.config"
```

### # Deploy Employee Portal website on Central Administration server

```PowerShell
Push-Location ("C:\NotBackedUp\Builds\Securitas\EmployeePortal\$build" `
    + "\Debug\_PublishedWebsites\Web_Package")

attrib -r .\Web.SetParameters.xml

$config = Get-Content Web.SetParameters.xml

$config = $config -replace `
    "Default Web Site/Web_deploy", $employeePortalHostHeader

$configXml = [xml] $config

$configXml.Save("$pwd\Web.SetParameters.xml")

.\Web.deploy.cmd /t

.\Web.deploy.cmd /y

Pop-Location
```

### # Configure application settings and web service URLs

```PowerShell
Push-Location ("C:\inetpub\wwwroot\" + $employeePortalHostHeader)

(Get-Content Web.config) `
    -replace '<add key="GoogleAnalytics.TrackingId" value="" />',
        '<add key="GoogleAnalytics.TrackingId" value="UA-25949832-3" />' `
    -replace 'https://client-local', 'https://client-local-4' `
    -replace 'https://cloud2-local', 'https://cloud2-local-4' |
    Set-Content Web.config

Pop-Location

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    "C:\NotBackedUp\Temp\Web - $employeePortalHostHeader.config" `
    C:\inetpub\wwwroot\$employeePortalHostHeader\Web.config
```

### Deploy website content to other web servers in the farm

(skipped)

### # Delete old build

```PowerShell
Remove-Item C:\NotBackedUp\Builds\Securitas\EmployeePortal\1.0.49.0 -Recurse -Force
```

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Update VM baseline

```PowerShell
$vmHost = "WOLVERINE"
$vmName = "EXT-FOOBAR4"

C:\NotBackedUp\Public\Toolbox\PowerShell\Update-VMBaseline `
    -ComputerName $vmHost `
    -Name $vmName `
    -Confirm:$false

$newSnapshotName = ("Baseline Client Portal 4.0.701.0" `
```

    + " / Cloud Portal 2.0.131.0" `\
    + " / Employee Portal 1.0.58.0")

```PowerShell
Get-VMSnapshot -ComputerName $vmHost -VMName $vmName |
    Rename-VMSnapshot -NewName $newSnapshotName
```

---

## Upgrade SecuritasConnect to "v4.0 Sprint-31" release

### # Remove missing features from SharePoint sites

```PowerShell
Enable-SharePointCmdlets

Function CreateOutputObject($FeatureId, $SPObject, $Action) {
    $result = New-Object -TypeName PSObject

    $result | Add-Member `
        -MemberType NoteProperty `
        -Name FeatureId `
        -Value $FeatureId

    $result | Add-Member `
        -MemberType NoteProperty `
        -Name Url `
        -Value $SPObject.Url

    $type = $SPObject.GetType()

    $result | Add-Member `
        -MemberType NoteProperty `
        -Name Type `
        -Value $type.Name

    If ($type.Name -eq "SPWeb")
    {
        $result | Add-Member `
            -MemberType NoteProperty `
            -Name CompatibilityLevel `
            -Value $SPObject.Site.CompatibilityLevel
    }
    Else
    {
        $result | Add-Member `
            -MemberType NoteProperty `
            -Name CompatibilityLevel `
            -Value $SPObject.CompatibilityLevel
    }

    $result | Add-Member `
        -MemberType NoteProperty `
        -Name Action `
        -Value $Action

    $result
}

$clientPortalUrl = $env:SECURITAS_CLIENT_PORTAL_URL
$cloudPortalUrl = $env:SECURITAS_CLOUD_PORTAL_URL

If ([string]::IsNullOrEmpty($clientPortalUrl) -eq $true)
{
    # default to Production
    $clientPortalUrl = "http://client.securitasinc.com"
}

If ([string]::IsNullOrEmpty($cloudPortalUrl) -eq $true)
{
    # default to Production
    $cloudPortalUrl = "http://cloud.securitasinc.com"
}

# Deactivate deprecated feature ("Securitas.CloudPortal.Web_EnsureEwikiSiteFeatures")
$featureId = "d4199cf7-e11c-4adf-a300-eb0785a8a9f0"

@(
    "$cloudPortalUrl/sites/2020-Collaboration/Wiki",
    "$cloudPortalUrl/sites/Cloud-Demo/DemoWiki",
    "$cloudPortalUrl/sites/Healthcare/Special Projects Wiki",
    "$cloudPortalUrl/sites/Hyperion-Planning/Wiki",
    "$cloudPortalUrl/sites/IT-Systems-Training-And-Support/enterprisewiki",
    "$cloudPortalUrl/sites/IT-Web-Test/ourwiki",
    "$cloudPortalUrl/sites/My-Training/My Training Wiki",
    "$cloudPortalUrl/sites/Online-Provisioning/Wiki",
    "$cloudPortalUrl/sites/Turning-Point-Solutions/Wiki"
) |
    foreach {
        $web = Get-SPWeb -Identity $_ -ErrorAction SilentlyContinue

        If ($web)
        {
            $feature = $web.Features[$featureId]

            If ($feature)
            {
                CreateOutputObject $featureId $web "Report"

                $web.Features.Remove($featureId, $true)

                CreateOutputObject $featureId $web "Remove"
            }

            $web.Dispose()
        }
    }

# Deactivate Boost site collection feature
# ("Brandysoft.SharePoint.ListCollection") on "Compatibility Level 14" sites

$featureId = "a6204a2f-00c2-40a2-b2dd-fb06c9f87b78"

@(
    "$clientPortalUrl/Template-Sites/Post-Orders-en-CA",
    "$clientPortalUrl/Template-Sites/Post-Orders-en-US",
    "$clientPortalUrl/Template-Sites/Post-Orders-fr-CA"
) |
    foreach {
        $site = Get-SPSite -Identity $_ -ErrorAction SilentlyContinue

        If ($site)
        {
            $feature = $site.Features[$featureId]

            If ($feature)
            {
                CreateOutputObject $featureId $site "Report"

                $site.Features.Remove($featureId, $true)

                CreateOutputObject $featureId $site "Remove"
            }

            $site.Dispose()
        }
    }

# Deactivate Boost site (SPWeb) features on "Compatibility Level 14" sites

$webFeatures = @(
    "3e56c540-af03-4111-a734-f8ff8d903d12",
    "6d9369be-f0ee-429f-b400-5d6be257bc6b"
)

@(
    "$clientPortalUrl/Template-Sites/Post-Orders-en-CA",
    "$clientPortalUrl/Template-Sites/Post-Orders-en-CA/search",
    "$clientPortalUrl/Template-Sites/Post-Orders-en-US",
    "$clientPortalUrl/Template-Sites/Post-Orders-en-US/search",
    "$clientPortalUrl/Template-Sites/Post-Orders-fr-CA",
    "$clientPortalUrl/Template-Sites/Post-Orders-fr-CA/search"
) |
    foreach {
        $web = Get-SPWeb -Identity $_ -ErrorAction SilentlyContinue

        If ($web)
        {
            $webFeatures |
                foreach {
                    $featureId = $_

                    $feature = $web.Features[$featureId]

                    If ($feature)
                    {
                        CreateOutputObject $featureId $web "Report"

                        $web.Features.Remove($featureId, $true)

                        CreateOutputObject $featureId $web "Remove"
                    }
                }

            $web.Dispose()
        }
    }
```

### Install September 12, 2017, cumulative update for SharePoint Server 2013

---

**WOLVERINE**

```PowerShell
cls
```

#### # Download update

```PowerShell
$patch = "15.0.4963.1001 - SharePoint 2013 September 2017 CU"
$computerName = "EXT-FOOBAR4.extranet.technologytoolbox.com"

$sourcePath = "\\TT-FS01\Products\Microsoft\SharePoint 2013\Patches\$patch"
$destPath = "\\$computerName\C`$\NotBackedUp\Temp\$patch"

robocopy $sourcePath $destPath /E
```

---

```PowerShell
cls
```

#### # Install update

```PowerShell
$patch = "15.0.4963.1001 - SharePoint 2013 September 2017 CU"

Push-Location "C:\NotBackedUp\Temp\$patch"

& "C:\NotBackedUp\Temp\$patch\Install.ps1"
```

> **Note**
>
> When prompted, type **1** to pause the Search Service Application.

> **Important**
>
> Wait for the update to be installed.

```PowerShell
Pop-Location
```

```PowerShell
cls
Push-Location ("C:\Program Files\Common Files\microsoft shared" `
```

    + "\\Web Server Extensions\\15\\BIN")

```PowerShell
.\PSConfig.exe `
     -cmd upgrade `
     -inplace b2b `
     -wait `
     -cmd applicationcontent `
     -install `
     -cmd installfeatures `
     -cmd secureresources

Pop-Location
```

```PowerShell
cls
Remove-Item "C:\NotBackedUp\Temp\$patch" -Recurse
```

---

**WOLVERINE**

```PowerShell
cls
```

### # Copy new build from TFS drop location

```PowerShell
$newBuild = "4.0.705.0"
$computerName = "EXT-FOOBAR4.extranet.technologytoolbox.com"

$sourcePath = "\\TT-FS01\Builds\Securitas\ClientPortal\$newBuild"

$destPath = "\\$computerName\C$" `
    + "\NotBackedUp\Builds\Securitas\ClientPortal\$newBuild"

robocopy $sourcePath $destPath /E
```

---

```PowerShell
cls
```

### # Remove previous versions of SecuritasConnect WSPs

```PowerShell
$oldBuild = "4.0.701.0"

Push-Location ("C:\NotBackedUp\Builds\Securitas\ClientPortal\$oldBuild" `
    + "\DeploymentFiles\Scripts")

& '.\Deactivate Features.ps1' -Verbose

& '.\Retract Solutions.ps1' -Verbose

& '.\Delete Solutions.ps1' -Verbose

Pop-Location
```

```PowerShell
cls
```

### # Install new versions of SecuritasConnect WSPs

```PowerShell
$newBuild = "4.0.705.0"

Push-Location ("C:\NotBackedUp\Builds\Securitas\ClientPortal\$newBuild" `
    + "\DeploymentFiles\Scripts")

& '.\Add Solutions.ps1' -Verbose

& '.\Deploy Solutions.ps1' -Verbose

& '.\Activate Features.ps1' -Verbose

Pop-Location
```

```PowerShell
cls
```

### # Delete old build

```PowerShell
Remove-Item C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.701.0 `
   -Recurse -Force
```

### Install September 12, 2017, security update for Office Web Apps Server 2013

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Update VM baseline

```PowerShell
$vmHost = "WOLVERINE"
$vmName = "EXT-FOOBAR4"

C:\NotBackedUp\Public\Toolbox\PowerShell\Update-VMBaseline `
    -ComputerName $vmHost `
    -Name $vmName `
    -Confirm:$false

$newSnapshotName = ("Baseline Client Portal 4.0.705.0" `
```

    + " / Cloud Portal 2.0.131.0" `\
    + " / Employee Portal 1.0.58.0")

```PowerShell
Get-VMSnapshot -ComputerName $vmHost -VMName $vmName |
    Rename-VMSnapshot -NewName $newSnapshotName
```

---

## Issue - "Access Denied" error with SharePoint Trace Service

### Symptom

Numerous ULS log entries:

Process: wsstracing.exe\
Produce: SharePoint Foundation\
Category: Unified Logging Service\
EventID: adr4q\
Level: Unexpected\
Message: Trace Service encountered an unexpected exception when processing usage event. Detail exception message: Create store file error.. Win32 error code=5.

### Problem

**Local Service** account has **Write** permission on Trace Log folder but does not have **Read** permission:

```PowerShell
$logsFolder = ("C:\Program Files\Common Files\microsoft shared" `
    + "\Web Server Extensions\15\LOGS")

icacls $logsFolder

C:\...\15\LOGS BUILTIN\Administrators:(OI)(CI)(F)
               NT AUTHORITY\LOCAL SERVICE:(OI)(CI)(W,Rc,RD,DC)
               ...
```

### Solution

Grant** Local Service** account **Read** permission on Trace Log folder (in addition to **Write** permission):

```PowerShell
$logsFolder = ("C:\Program Files\Common Files\microsoft shared" `
    + "\Web Server Extensions\15\LOGS")

icacls $logsFolder /grant "NT AUTHORITY\LOCAL SERVICE:(OI)(CI)(R,W,DC)"
```

## Upgrade SecuritasConnect to "v4.0 Sprint-32" release

### Install Cumulative Update 11 for SQL Server 2014 SP2

---

**WOLVERINE**

```PowerShell
cls
```

#### # Copy installation file to server

```PowerShell
$filter = "SQLServer2014-KB4077063-x64.exe"
$computerName = "EXT-FOOBAR4.extranet.technologytoolbox.com"

$sourcePath = "\\TT-FS01\Products\Microsoft\SQL Server 2014\Patches" `
```

    + "\\12.0.5579.0 - Cumulative Update 11 for SQL Server 2014 SP2"

```PowerShell
$destPath = "\\$computerName\C$" `
    + "\NotBackedUp\Temp"

robocopy $sourcePath $destPath $filter
```

---

```PowerShell
cls
```

#### # Install update

```PowerShell
$installerPath = "C:\NotBackedUp\Temp\SQLServer2014-KB4077063-x64.exe"

Start-Process `
    -FilePath $installerPath `
    -Wait
```

```PowerShell
cls
```

#### # Remove installation file

```PowerShell
Remove-Item $installerPath
```

---

**WOLVERINE**

```PowerShell
cls
```

### # Copy new build from TFS drop location

```PowerShell
$newBuild = "4.0.711.0"
$computerName = "EXT-FOOBAR4.extranet.technologytoolbox.com"

$sourcePath = "\\TT-FS01\Builds\Securitas\ClientPortal\$newBuild"

$destPath = "\\$computerName\C$" `
    + "\NotBackedUp\Builds\Securitas\ClientPortal\$newBuild"

robocopy $sourcePath $destPath /E
```

---

```PowerShell
cls
```

### # Remove previous versions of SecuritasConnect WSPs

```PowerShell
$oldBuild = "4.0.705.0"

Push-Location C:\Shares\Builds\ClientPortal\$oldBuild\DeploymentFiles\Scripts

& '.\Deactivate Features.ps1' -Verbose
& '.\Retract Solutions.ps1' -Verbose
& '.\Delete Solutions.ps1' -Verbose

Pop-Location
```

### # Install new versions of SecuritasConnect WSPs

```PowerShell
$newBuild = "4.0.711.0"

Push-Location C:\Shares\Builds\ClientPortal\$newBuild\DeploymentFiles\Scripts

& '.\Add Solutions.ps1' -Verbose

& '.\Deploy Solutions.ps1' -Verbose

& '.\Activate Features.ps1' -Verbose
```

> **Important**
>
> If an error occurs when activating the **Securitas.Portal.Web_ClaimsAuthenticationConfiguration** feature, restart the SharePoint services to reload the ADFS claims provider from the new version of **Securitas.Portal.Web** assembly:
>
> ```PowerShell
> & 'C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts\Restart SharePoint Services.cmd'
> ```
>
> After restarting the services, activate the features again:
>
> ```PowerShell
> & '.\Activate Features.ps1' -Verbose
> ```

```PowerShell
Pop-Location
```

### # Delete old build

```PowerShell
Remove-Item C:\Shares\Builds\ClientPortal\4.0.705.0 -Recurse -Force
```

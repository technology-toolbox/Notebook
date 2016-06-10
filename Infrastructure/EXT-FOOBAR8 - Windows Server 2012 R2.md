# EXT-FOOBAR8 - Windows Server 2012 R2 Standard

Friday, June 3, 2016
8:26 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

### Install Windows Server 2012 R2

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "FORGE"
$vmName = "EXT-FOOBAR8"
$vmPath = "E:\NotBackedUp\VMs"

$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 60GB `
    -MemoryStartupBytes 24GB `
    -SwitchName "Production"

Set-VM `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ProcessorCount 4

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
  - In the **Computer name** box, type **EXT-FOOBAR8**.
  - Select **Join a workgroup**.
  - In the **Workgroup **box, type **WORKGROUP**.
  - Click **Next**.
- On the **Applications** step, ensure no items are selected and click **Next**.

#### # Copy latest Toolbox content

```PowerShell
net use \\iceman.corp.technologytoolbox.com\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```Console
robocopy \\iceman.corp.technologytoolbox.com\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E /MIR
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

### Login as EXT-FOOBAR8\\foo

```PowerShell
cls
```

### # Configure network settings

#### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select Name, InterfaceDescription

Get-NetAdapter `
    -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "Production"
```

#### # Configure "Production" network adapter

```PowerShell
$interfaceAlias = "Production"
```

#### # Disable DHCP

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

#### # Configure static IPv4 address

```PowerShell
$ipAddress = "192.168.10.223"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24 `
    -DefaultGateway 192.168.10.1
```

##### # Configure IPv4 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 192.168.10.209,192.168.10.210
```

#### # Configure static IPv6 address

```PowerShell
$ipAddress = "2601:282:4201:e500::223"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 64
```

##### # Configure IPv6 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 2601:282:4201:e500::209,2601:282:4201:e500::210
```

##### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping ICEMAN -f -l 8900
```

```PowerShell
cls
```

### # Join domain

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
$computerName = "EXT-FOOBAR8"
$targetPath = ("OU=SharePoint Servers,OU=Servers,OU=Resources,OU=Development" `
    + ",DC=extranet,DC=technologytoolbox,DC=com")

Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath

Restart-Computer $computerName

Restart-Computer : Failed to restart the computer EXT-FOOBAR8 with the following error message: The RPC server is
unavailable. (Exception from HRESULT: 0x800706BA).
At line:1 char:1
+ Restart-Computer $computerName
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (EXT-FOOBAR8:String) [Restart-Computer], InvalidOperationException
    + FullyQualifiedErrorId : RestartcomputerFailed,Microsoft.PowerShell.Commands.RestartComputerCommand
```

---

### Login as EXTRANET\\setup-sharepoint-dev

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
C:\NotBackedUp\Public\Toolbox\PowerShell\Enable-RemoteWindowsUpdate.ps1 -Verbose
```

### # Disable firewall rules for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Disable-RemoteWindowsUpdate.ps1 -Verbose
```

## Configure VM storage

| Disk | Drive Letter | Volume Size | VHD Type | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------- | -------------------- | ------------ |
| 0    | C:           | 60 GB       | Dynamic  | 4K                   | OSDisk       |
| 1    | D:           | 150 GB      | Dynamic  | 64K                  | Data01       |
| 2    | L:           | 25 GB       | Dynamic  | 64K                  | Log01        |
| 3    | T:           | 4 GB        | Dynamic  | 64K                  | Temp01       |
| 4    | Z:           | 400 GB      | Dynamic  | 4K                   | Backup01     |

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create Data01, Log01, and Backup01 VHDs

```PowerShell
$vmHost = "FORGE"
$vmName = "EXT-FOOBAR8"

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName" `
    + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 150GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ControllerType SCSI `
    -Path $vhdPath

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName" `
    + "_Log01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 25GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ControllerType SCSI `
    -Path $vhdPath

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName" `
    + "_Temp01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 4GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ControllerType SCSI `
    -Path $vhdPath

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName" `
    + "_Backup01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 400GB
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

### # Set MaxPatchCacheSize to 0 (Recommended)

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

### Install latest service pack and updates

### Create service accounts

(skipped)

### Create Active Directory container to track SharePoint 2013 installations

(skipped)

### TODO: DEV - Install Visual Studio 2013 with Update 4

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Mount Visual Studio 2013 with Update 4 installation media

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\Visual Studio 2013" `
    + "\en_visual_studio_ultimate_2013_with_update_4_x86_dvd_5935075.iso"

Set-VMDvdDrive -VMName EXT-FOOBAR8 -Path $imagePath
```

---

```PowerShell
& X:\vs_ultimate.exe
```

### TODO: DEV - Install update for Office developer tools in Visual Studio

**Note:** Microsoft Office Developer Tools for Visual Studio 2013 - August 2015 Update

Add **[https://www.microsoft.com](https://www.microsoft.com)** to **Trusted sites** zone

### TODO: DEV - Install update for SQL Server database projects in Visual Studio

Add **[http://download.microsoft.com](http://download.microsoft.com)** to **Trusted sites** zone

### TODO: DEV - Install Productivity Power Tools for Visual Studio

### Install SQL Server 2014

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Mount SQL Server 2014 installation media

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\SQL Server 2014" `
    + "\en_sql_server_2014_developer_edition_with_service_pack_1_x64_dvd_6668542.iso"

Set-VMDvdDrive -ComputerName FORGE -VMName EXT-FOOBAR8 -Path $imagePath
```

---

```PowerShell
& X:\setup.exe
```

---

**SQL Server Management Studio**

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

---

---

**SQL Server Management Studio**

### -- DEV - Constrain maximum memory for SQL Server

```SQL
EXEC sys.sp_configure N'show advanced options', N'1'
RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'max server memory (MB)', N'4096'
RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'show advanced options', N'0'
RECONFIGURE WITH OVERRIDE
GO
```

---

---

**SQL Server Management Studio**

### -- Configure TempDB data and log files

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

---

---

**SQL Server Management Studio**

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

### # Configure permissions on \\Windows\\System32\\LogFiles\\Sum files

```PowerShell
icacls C:\Windows\System32\LogFiles\Sum\Api.chk `
    /grant "NT Service\MSSQLSERVER:(M)"

icacls C:\Windows\System32\LogFiles\Sum\Api.log `
    /grant "NT Service\MSSQLSERVER:(M)"

icacls C:\Windows\System32\LogFiles\Sum\SystemIdentity.mdb `
    /grant "NT Service\MSSQLSERVER:(M)"
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

### DEV - Install Microsoft Office 2016 (Recommended)

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Mount Office Professional Plus 2016 installation media

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\Office 2016" `
    + "\en_office_professional_plus_2016_x86_x64_dvd_6962141.iso"

Set-VMDvdDrive -ComputerName FORGE -VMName EXT-FOOBAR8 -Path $imagePath
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
$imagePath = "\\ICEMAN\Products\Microsoft\Visio 2016" `
    + "\en_visio_professional_2016_x86_x64_dvd_6962139.iso"

Set-VMDvdDrive -ComputerName FORGE -VMName EXT-FOOBAR8 -Path $imagePath
```

---

```Console
X:
.\setup.exe /AUTORUN
```

```Console
cls
```

### # DEV - Install additional browsers and software (Recommended)

#### # Install Mozilla Firefox

```PowerShell
& "\\ICEMAN\Products\Mozilla\Firefox\Firefox Setup 46.0.1.exe"
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

## Install and configure SharePoint Server 2013

### Download SharePoint 2013 prerequisites to a file share

(skipped)

```PowerShell
cls
```

### # Install SharePoint 2013 prerequisites on the farm servers

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Insert the SharePoint 2013 installation media into the DVD drive for the SharePoint VM

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\SharePoint 2013\" `
    + "en_sharepoint_server_2013_with_sp1_x64_dvd_3823428.iso"

Set-VMDvdDrive -ComputerName FORGE -VMName EXT-FOOBAR8 -Path $imagePath
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

**FOOBAR8**

```PowerShell
cls
```

### # Checkpoint VM

```PowerShell
$vmHost = "FORGE"
$vmName = "EXT-FOOBAR8"
$snapshotName = "Before - Install SharePoint Server 2013 on the farm servers"

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

"...steps you can use to gather a Windows Installer verbose log file.."\
Pasted from <[http://blogs.msdn.com/b/astebner/archive/2005/03/29/403575.aspx](http://blogs.msdn.com/b/astebner/archive/2005/03/29/403575.aspx)>

```PowerShell
cls
```

### # Install SharePoint Server 2013 on the farm servers

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

---

**FOOBAR8**

```PowerShell
cls
```

### # Update VM snapshot

```PowerShell
$vmHost = "FORGE"
$vmName = "EXT-FOOBAR8"

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

```PowerShell
net use \\ICEMAN\Products /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$patch = "15.0.4727.1000 - SharePoint 2013 June 2015 CU"

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

exit
```

> **Important**
>
> Restart PowerShell for environment variable change to take effect.

### DEV - Install Visual Studio 2015 with Update 2

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Mount Visual Studio 2012 with Update 2 installation media

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\Visual Studio 2015" `
    + "\en_visual_studio_enterprise_2015_with_update_2_x86_x64_dvd_8510142.iso"

Set-VMDvdDrive -ComputerName FORGE -VMName EXT-FOOBAR8 -Path $imagePath
```

---

```PowerShell
& X:\vs_enterprise.exe
```

In the Visual Studio installation wizard:

1. Select the **Custom** installation option and click **Next**.
2. In the list of features, select the following items:
3. **Microsoft Office Developer Tools**
4. **Microsoft SQL Server Data Tools**
5. **Microsoft Web Developer Tools**
6. Click **Next**.
7. Review the list of selected features and click **Install**.

### DEV - Enter product key for Visual Studio

1. Start Visual Studio.
2. On the **Help** menu, click **Register Product**.
3. In the **Sign in to Visual Studio** window, click **Unlock with a Product Key**.
4. In the **Enter a product key** window, type the product key and click **Apply**.
5. In the **Sign in to Visual Studio** window, click **Close**.

### DEV - Install update for Office developer tools in Visual Studio

**Note: **Microsoft Office Developer Tools Update 2 for Visual Studio 2015

Add **[https://www.microsoft.com](https://www.microsoft.com)** to **Trusted sites** zone

File: OfficeToolsForVS2015.3f.3fen.exe

### TODO: DEV - Install Productivity Power Tools for Visual Studio

---

**FOOBAR8**

```PowerShell
cls
```

### # Update VM snapshot

```PowerShell
$vmHost = "FORGE"
$vmName = "EXT-FOOBAR8"

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
$snapshotName = "Before - Copy SecuritasConnect build to SharePoint server"

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName $snapshotName

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### # Copy SecuritasConnect build to SharePoint server

```PowerShell
net use \\ICEMAN\Builds /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
robocopy `
    "\\ICEMAN\Builds\Securitas\ClientPortal\4.0.661.0" `
    "C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.661.0" `
    /E
```

### # Create and configure the farm

> **Important**
>
> Login as **EXTRANET\\setup-sharepoint**

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.661.0\DeploymentFiles\Scripts

& '.\Create Farm.ps1' -CentralAdminAuthProvider NTLM -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-sp-farm-dev**.\
> Expect the previous operation to complete in approximately 5-1/2 minutes.

### Add Web servers to the farm

(skipped)

### Add SharePoint Central Administration to the "Local intranet" zone

(skipped -- since the "Create Farm.ps1" script configures this)

```PowerShell
cls
```

### # Grant permissions on DCOM applications for SharePoint

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.661.0\DeploymentFiles\Scripts

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
    -IPAddress 192.168.10.223 `
    -Hostnames EXT-FOOBAR8, client-local.securitasinc.com
```

---

## Backup SharePoint 2010 environment

### Backup databases in SharePoint 2010 environment

(Download backup files from PROD)

[\\\\ICEMAN\\Archive\\Clients\\Securitas\\Backups](\\ICEMAN\Archive\Clients\Securitas\Backups)

### # Copy the backup files to the SQL Server for the SharePoint 2013 farm

```PowerShell
$destination = 'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full'

mkdir $destination

net use \\iceman.corp.technologytoolbox.com\Archive /USER:TECHTOOLBOX\jjameson

robocopy `
    \\iceman.corp.technologytoolbox.com\Archive\Clients\Securitas\Backups `
    $destination `
    *.bak

$zipFile = `
    "\\iceman.corp.technologytoolbox.com\Archive\Clients\Securitas\Backups\" `
    + "WSS_Content_CloudPortal_backup_2016_05_15_010003_8391000.zip"

Add-Type -assembly "System.Io.Compression.FileSystem"

[Io.Compression.ZipFile]::ExtractToDirectory($zipFile, $destination)
```

#### Issue

```Text
Exception calling "ExtractToDirectory" with "2" argument(s): "The archive entry was compressed using an unsupported
compression method."
At line:1 char:1
+ [Io.Compression.ZipFile]::ExtractToDirectory($zipFile, $destination)
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [], MethodInvocationException
    + FullyQualifiedErrorId : InvalidDataException
```

#### Workaround

Unzip the files using Windows Explorer.

```PowerShell
cls
```

#### # Rename backup files

```PowerShell
ren `
    ($destination + '\Profile DB New_backup_2016_05_15_010003_7610970.bak') `
    'Profile DB New.bak'

ren `
    ($destination + '\SecuritasPortal_backup_2016_05_15_010003_7298958.bak') `
    'SecuritasPortal.bak'

ren `
    ($destination + '\Securitas_CP_MMS_backup_2016_05_15_010003_7454964.bak') `
    'Securitas_CP_MMS.bak'

ren `
    ($destination + '\Social DB New_backup_2016_05_15_010003_8078988.bak') `
    'Social DB New.bak'

ren `
    ($destination + '\Sync DB New_backup_2016_05_15_010003_7610970.bak') `
    'Sync DB New.bak'

ren `
    ($destination + '\WSS_Content_CloudPortal_backup_2016_05_15_010003_8391000.bak') `
    'WSS_Content_CloudPortal.bak'

ren `
    ($destination + '\WSS_Content_SecuritasPortal_backup_2016_05_15_010003_7298958.bak') `
    'WSS_Content_SecuritasPortal.bak'
```

### # Export the User Profile Synchronization encryption key

---

**258521-VM4 - Command Prompt**

#### REM Export MIIS encryption key

```Console
cd "C:\Program Files\Microsoft Office Servers\14.0\Synchronization Service\Bin\"

miiskmu.exe /e C:\Users\%USERNAME%\Desktop\miiskeys-1.bin ^
    /u:SEC\svc-sharepoint-2010 *
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
copy `
    "\\ICEMAN\Archive\Clients\Securitas\Backups\miiskeys-1.bin" `
    "C:\Users\setup-sharepoint-dev\Desktop"
```

## # Configure SharePoint services and service applications

### # Change the service account for the Distributed Cache

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.661.0\DeploymentFiles\Scripts

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

```PowerShell
cls
```

### # Configure the User Profile Service Application

#### # Restore the database backup from the SharePoint 2010 User Profile Service Application

```PowerShell
$sqlcmd = @"
```

#### -- Restore profile database

```Console
DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\'
    + 'Profile DB New.bak'

DECLARE @dataFilePath VARCHAR(255) =
  'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'UserProfileService_Profile.mdf'

DECLARE @logFilePath VARCHAR(255) =
  'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'UserProfileService_Profile_log.LDF'

RESTORE DATABASE UserProfileService_Profile
  FROM DISK = @backupFilePath
  WITH FILE = 1,
    MOVE 'Profile DB New' TO @dataFilePath,
    MOVE 'Profile DB New_log' TO @logFilePath,
    NOUNLOAD,
    STATS = 5
```

#### -- Restore synchronization database

```Console
SET @backupFilePath =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\'
    + 'Sync DB New.bak'

SET @dataFilePath =
  'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'UserProfileService_Sync.mdf'

SET @logFilePath =
  'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'UserProfileService_Sync_log.LDF'

RESTORE DATABASE UserProfileService_Sync
  FROM DISK = @backupFilePath
  WITH FILE = 1,
    MOVE 'Sync DB New' TO @dataFilePath,
    MOVE 'Sync DB New_log' TO @logFilePath,
    NOUNLOAD,
    STATS = 5
```

#### -- Restore social tagging database

```Console
SET @backupFilePath =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\'
    + 'Social DB New.bak'

SET @dataFilePath =
  'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'UserProfileService_Social.mdf'

SET @logFilePath =
  'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'UserProfileService_Social_log.LDF'

RESTORE DATABASE UserProfileService_Social
  FROM DISK = @backupFilePath
  WITH FILE = 1,
    MOVE 'Social DB New' TO @dataFilePath,
    MOVE 'Social DB New_log' TO @logFilePath,
    NOUNLOAD,
    STATS = 5

GO

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
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.661.0\DeploymentFiles\Scripts

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
```

> **Note**
>
> When prompted for the service account credentials, type the password for the SharePoint farm service account.

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
net localgroup Administrators /delete EXTRANET\s-sp-farm-dev

Restart-Service SPTimerV4
```

#### Configure synchronization connections and import data from Active Directory

##### Create synchronization connections to Active Directory

| **Connection Name** | **Forest Name**            | **Account Name**        |
| ------------------- | -------------------------- | ----------------------- |
| TECHTOOLBOX         | corp.technologytoolbox.com | TECHTOOLBOX\\svc-sp-ups |
| FABRIKAM            | corp.fabrikam.com          | FABRIKAM\\s-sp-ups      |

**TODO:** Delete **PNKCAN** and **PNKUS **connections.

[Issue configuring User Profile Synchronization in TEST](Issue configuring User Profile Synchronization in TEST)

##### Start profile synchronization

Number of user profiles (before import): 11,776\
Number of user profiles (after import): 12,268

```PowerShell
Start-Process `
    ("C:\Program Files\Microsoft Office Servers\15.0\Synchronization Service" `
        + "\UIShell\miisclient.exe") `
    -Credential $farmCredential
```

Start time: 1:34:23 PM\
End time:  1:42:55 PM

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
> Expect the previous operation to complete in approximately 6-1/2 minutes.

#### Modify search topology

(skipped)

```PowerShell
cls
```

#### # Pause Search Service Application

```PowerShell
Get-SPEnterpriseSearchServiceApplication "Search Service Application" |
    Suspend-SPEnterpriseSearchServiceApplication
```

```PowerShell
cls
```

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

exit
```

> **Important**
>
> Restart PowerShell for environment variables to take effect.

### # Add the URL for the SecuritasConnect Web site to the "Local intranet" zone

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

---

**FOOBAR8**

```PowerShell
cls
```

### # DEV - Snapshot VM

```PowerShell
$vmHost = "FORGE"
$vmName = "EXT-FOOBAR8"

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
$snapshotName = "Baseline SharePoint Server 2013 configuration"

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName $snapshotName

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### # Create the Web application

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.661.0\DeploymentFiles\Scripts

& '.\Create Web Application.ps1' -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-web-client-dev**.\
> Expect the previous operation to complete in approximately 1-1/2 minutes.

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
$stopwatch = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-Stopwatch.ps1

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

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:

$stopwatch.Stop()
C:\NotBackedUp\Public\Toolbox\PowerShell\Write-ElapsedTime.ps1 $stopwatch
```

> **Note**
>
> Expect the previous operation to complete in approximately 12 minutes.\
> RESTORE DATABASE successfully processed 4262140 pages in 684.137 seconds (48.671 MB/sec).

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

##### # Test content database

```PowerShell
Test-SPContentDatabase `
    -Name WSS_Content_SecuritasPortal `
    -WebApplication $env:SECURITAS_CLIENT_PORTAL_URL |
    Out-File C:\NotBackedUp\Temp\Test-SPContentDatabase-SecuritasConnect.txt
```

```PowerShell
cls
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
> Expect the previous operation to complete in approximately 3 hours 46 minutes.

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
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.661.0\DeploymentFiles\Scripts

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

### Configure My Site settings in User Profile service application

[http://client-local.securitasinc.com/sites/my](http://client-local.securitasinc.com/sites/my)

## Deploy the SecuritasConnect solution

### DEV - Build Visual Studio solution and package SharePoint projects

(skipped)

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
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.661.0\DeploymentFiles\Scripts

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

```PowerShell
cls
```

#### # Associate client users to Branch Managers

```PowerShell
$sqlcmd = @"
USE SecuritasPortal
GO

UPDATE Customer.BranchManagerAssociatedUsers
SET BranchManagerUserName = 'TECHTOOLBOX\jjameson'
WHERE BranchManagerUserName = 'PNKUS\jjameson'
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

### # Configure trusted root authorities in SharePoint

```PowerShell
& '.\Configure Trusted Root Authorities.ps1'
```

### # Configure application settings (e.g. Web service URLs)

```PowerShell
net use \\ICEMAN\Archive /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
Import-Csv "\\ICEMAN\Archive\Clients\Securitas\AppSettings-UAT_2016-04-19.csv" |
    ForEach-Object {
        .\Set-AppSetting.ps1 $_.Key $_.Value $_.Description -Force -Verbose
    }
```

### Configure the SSO credentials for a user

(skipped)

```PowerShell
cls
```

### # Configure C&C landing site

#### # Grant Branch Managers permissions to the C&C landing site

```PowerShell
Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

$site = Get-SPSite "$env:SECURITAS_CLIENT_PORTAL_URL/sites/cc"
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

#### Hide the Search navigation item on the C&C landing site

(skipped)

```PowerShell
cls
```

#### # Configure the search settings for the C&C landing site

```PowerShell
Start-Process "$env:SECURITAS_CLIENT_PORTAL_URL/sites/cc"
```

```PowerShell
cls
```

### # Upgrade C&C site collections

```PowerShell
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
```

### Configure Google Analytics on the SecuritasConnect Web application

Tracking ID: **UA-25949832-4**

```PowerShell
cls
```

### # Add index to Personal Links list on /Branch-Management/Post-Orders site

```PowerShell
$web = Get-SPWeb "$env:SECURITAS_CLIENT_PORTAL_URL/Branch-Management/Post-Orders"

$list = $web.Lists["My Links"]

$list.Fields["Created By"].Indexed = $true

$list.Fields["Created By"].Update()
```

### # Add Branch Managers domain group to Post Orders template site

```PowerShell
Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

$site = Get-SPSite "$env:SECURITAS_CLIENT_PORTAL_URL/Template-Sites/Post-Orders-en-US"

$group = $site.RootWeb.SiteGroups["Post Orders Template Site (en-US) Visitors"]

$claim = New-SPClaimsPrincipal -Identity "Branch Managers" `
    -IdentityType WindowsSecurityGroupName

$branchManagersUser = $site.RootWeb.EnsureUser($claim.ToEncodedString())
$group.AddUser($branchManagersUser)
$site.Dispose()
```

```PowerShell
cls
```

### # Replace site collection administrators

```PowerShell
$stopwatch = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-Stopwatch.ps1

Function ReplaceSiteCollectionAdministrators(
    $site)
{
    Write-Host `
        "Replacing site collection administrators on site ($($site.Url))..."

    For ($i = 0; $i -lt $site.RootWeb.SiteAdministrators.Count; $i++)
    {
        $siteAdmin = $site.RootWeb.SiteAdministrators[$i]

        Write-Debug "siteAdmin: $($siteAdmin.LoginName)"

        If ($siteAdmin.DisplayName -eq "SEC\SharePoint Admins")
        {
            Write-Verbose "Removing administrator ($($siteAdmin.DisplayName))..."
            $site.RootWeb.SiteAdministrators.Remove($i)
            $i--;
        }
    }

    Write-Debug `
        "Adding SharePoint Admins on site ($($site.Url))..."

    $user = $site.RootWeb.EnsureUser("EXTRANET\SharePoint Admins (DEV)");
    $user.IsSiteAdmin = $true;
    $user.Update();
}

Get-SPSite -WebApplication $env:SECURITAS_CLIENT_PORTAL_URL -Limit ALL |
    select Url |
    Export-Csv SecuritasConnect-sites.csv

Import-Csv SecuritasConnect-sites.csv |
    ForEach-Object {
        Start-SPAssignment -Global

        $site = Get-SPSite $_.Url

        Write-Host `
            "Processing site ($($site.Url))..."

        ReplaceSiteCollectionAdministrators $site

        Stop-SPAssignment -Global
    }

$stopwatch.Stop()
C:\NotBackedUp\Public\Toolbox\PowerShell\Write-ElapsedTime.ps1 $stopwatch
```

> **Note**
>
> Expect the previous operation to complete in approximately 30 minutes.

### Defragment SharePoint databases

Defragmentation took 29 minutes

```PowerShell
cls
```

### # Shrink log file for content database

```PowerShell
$sqlcmd = @"
USE [WSS_Content_SecuritasPortal]
GO
DBCC SHRINKFILE (N'WSS_Content_SecuritasPortal_log' , 0, TRUNCATEONLY)
GO
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

```PowerShell
cls
```

### # Shrink content database

```PowerShell
$stopwatch = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-Stopwatch.ps1

$sqlcmd = @"
USE [WSS_Content_SecuritasPortal]
GO
DBCC SHRINKFILE (N'WSS_Content_SecuritasPortal' , 26000)
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:

$stopwatch.Stop()
C:\NotBackedUp\Public\Toolbox\PowerShell\Write-ElapsedTime.ps1 $stopwatch
```

#### Issue

```PowerShell
Invoke-Sqlcmd : Could not locate file 'WSS_Content_SecuritasPortal' for database 'master' in sys.database_files. The file either does not exist, or was dropped.
At line:1 char:1
+ Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidOperation: (:) [Invoke-Sqlcmd], SqlPowerShellSqlExecutionException
    + FullyQualifiedErrorId : SqlError,Microsoft.SqlServer.Management.PowerShell.GetScriptCommand
```

#### Workaround

Shrink database using SQL Server Management Studio

> **Note**
>
> Expect the previous operation to complete in approximately 6 minutes.

Size before: 34 GB

Size after: 25.4 GB

```PowerShell
cls
```

### # Change recovery model for content database to Full

```PowerShell
$sqlcmd = @"
ALTER DATABASE [WSS_Content_SecuritasPortal]
SET RECOVERY FULL WITH NO_WAIT
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

### Configure SQL Server backups

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

```PowerShell
cls
```

### # Upgrade C&C site collections

```PowerShell
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
    "Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full"
```

## # Create and configure the Cloud Portal Web application

### # Set environment variables

```PowerShell
[Environment]::SetEnvironmentVariable(
  "SECURITAS_CLOUD_PORTAL_URL",
  "http://cloud-local.securitasinc.com",
  "Machine")

exit
```

> **Important**
>
> Restart PowerShell for environment variable to take effect.

**TODO:** Add the following section to the install guide

### # Add the URL for the Cloud Portal Web site to the "Local intranet" zone

```PowerShell
[Uri] $url = [Uri] "http://cloud-local.securitasinc.com"

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
    "\\ICEMAN\Builds\Securitas\CloudPortal\2.0.114.0" `
    "C:\NotBackedUp\Builds\Securitas\CloudPortal\2.0.114.0" `
    /E
```

### # Create the Web application

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\CloudPortal\2.0.114.0\DeploymentFiles\Scripts

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
robocopy `
    '\\ICEMAN\Products\Boost Solutions' `
    'C:\NotBackedUp\Temp\Boost Solutions' /E
```

Extract zip and start **Setup.exe**

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
cd C:\NotBackedUp\Builds\Securitas\CloudPortal\2.0.114.0\DeploymentFiles\Scripts

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

### Configure SharePoint groups

(skipped)

## Deploy the Cloud Portal solution

### DEV - Build Visual Studio solution and package SharePoint projects

(skipped)

```PowerShell
cls
```

### # Configure database permissions for "Online Provisioning"

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
Upgrade-SPSite http://cloud-local.securitasinc.com/ -VersionUpgrade -Unthrottled
```

```PowerShell
cls
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

| Section              | Setting                 | Value                   |
| -------------------- | ----------------------- | ----------------------- |
| **Sign In Page URL** | **Custom Sign In Page** | **/Pages/Sign-In.aspx** |

```PowerShell
cls
```

### # Configure search settings for the Cloud Portal

#### # Hide the Search navigation item on the Cloud Portal top-level site

```PowerShell
Start-Process "http://cloud-local.securitasinc.com"
```

```PowerShell
cls
```

#### # Configure the search settings for the Cloud Portal top-level site

```PowerShell
Start-Process "http://cloud-local.securitasinc.com"
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

```PowerShell
cls
```

## # Install Employee Portal

## # Extend SecuritasConnect and Cloud Portal web applications

### # Extend web applications to Intranet zone

```PowerShell
$ErrorActionPreference = "Stop"

Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

Function ExtendWebAppToIntranetZone(
    [string] $DefaultUrl,
    [string] $IntranetUrl)
{
    $webApp = Get-SPWebApplication -Identity $DefaultUrl -Debug:$false

    Write-Host ("Extending Web application ($DefaultUrl) to Intranet zone" `
        + " ($IntranetUrl)...")

    $hostHeader = $IntranetUrl.Substring("http://".Length)

    $webAppName = "SharePoint - " + $hostHeader + "80"

    $windowsAuthProvider = New-SPAuthenticationProvider -Debug:$false

    $webApp | New-SPWebApplicationExtension `
        -Name $webAppName `
        -Zone Intranet `
        -AuthenticationProvider $windowsAuthProvider `
        -HostHeader $hostHeader `
        -Port 80
}

ExtendWebAppToIntranetZone `
    -DefaultUrl "http://client-local.securitasinc.com" `
    -IntranetUrl "http://client2-local.securitasinc.com"

ExtendWebAppToIntranetZone `
    -DefaultUrl "http://cloud-local.securitasinc.com" `
    -IntranetUrl "http://cloud2-local.securitasinc.com"
```

### Add SecuritasPortal connection string to Cloud Portal configuration file

(skipped)

**TODO:** Remove this section from the installation guide (since the bug has been fixed)

### Enable disk-based caching for the "intranet" websites

(skipped)

```PowerShell
cls
```

### # Map intranet URLs to loopback address in Hosts file

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    127.0.0.1 client2-local.securitasinc.com, cloud2-local.securitasinc.com
```

### # Allow specific host names mapped to 127.0.0.1

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-BackConnectionHostnames.ps1 `
    client2-local.securitasinc.com, cloud2-local.securitasinc.com
```

## Upgrade SecuritasConnect to "v3.0 Sprint-22" release

(skipped)

**TODO:** Remove this section from the installation guide

## Install Web Deploy 3.6

### Download Web Platform Installer

### Install Web Deploy

**TODO:** This was already installed at this point. Find out why (and remove from install guide if possible)

```PowerShell
cls
```

## # Install .NET Framework 4.5

### # Download .NET Framework 4.5.2 installer

```PowerShell
net use \\ICEMAN\Products /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
Copy-Item `
    ("\\ICEMAN\Products\Microsoft\.NET Framework 4.5\.NET Framework 4.5.2\" `
        + "NDP452-KB2901907-x86-x64-AllOS-ENU.exe") `
    C:\NotBackedUp\Temp
```

### # Install .NET Framework 4.5.2

```PowerShell
& C:\NotBackedUp\Temp\NDP452-KB2901907-x86-x64-AllOS-ENU.exe
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7E/00EEF0B1702AA3D8D0B31ED97CBDB43D9E94D37E.png)

> **Important**
>
> When prompted, restart the computer to complete the installation.

```PowerShell
Remove-Item C:\NotBackedUp\Temp\NDP452-KB2901907-x86-x64-AllOS-ENU.exe
```

### Install updates

> **Important**
>
> When prompted, restart the computer to complete the process of installing the updates.

### Restart computer (if not restarted since installing .NET Framework 4.5)

(skipped -- since a restart was required after installing updates)

### Ensure ASP.NET v4.0 ISAPI filters are enabled

(skipped -- since the ISAPI filters were already enabled)

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

### # Add the Employee Portal URL to the "Local intranet" zone

```PowerShell
[Uri] $url = [Uri] "http://employee-local.securitasinc.com"

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

### Create Employee Portal SharePoint site

(skipped)

```PowerShell
cls
```

### # Create Employee Portal website

#### # Create Employee Portal website on SharePoint Central Administration server

```PowerShell
cd 'C:\NotBackedUp\Builds\Securitas\EmployeePortal\1.0.28.0\Deployment Files\Scripts'

& '.\Configure Employee Portal Website.ps1' `
    -SiteName employee-local.securitasinc.com `
    -Confirm:$false `
    -Verbose
```

#### Configure SSL bindings on Employee Portal website

(skipped)

#### Create Employee Portal website on other web servers in the farm

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
    value="employee-local.securitasinc.com" />
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
Notepad C:\inetpub\wwwroot\employee-local.securitasinc.com\Web.config
```

Set the value of the **GoogleAnalytics.TrackingId** application setting to **UA-25949832-3**.

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
CREATE LOGIN [IIS APPPOOL\employee-local.securitasinc.com]
FROM WINDOWS
WITH DEFAULT_DATABASE=[master]
GO
USE [SecuritasPortal]
GO
CREATE USER [IIS APPPOOL\employee-local.securitasinc.com]
FOR LOGIN [IIS APPPOOL\employee-local.securitasinc.com]
GO
EXEC sp_addrolemember N'Employee_FullAccess', N'IIS APPPOOL\employee-local.securitasinc.com'
GO
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false
```

#### Issue

```PowerShell
Invoke-Sqlcmd : Cannot alter the role 'Employee_FullAccess', because it does not exist or you do not have permission.
At line:1 char:1
+ Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidOperation: (:) [Invoke-Sqlcmd], SqlPowerShellSqlExecutionException
    + FullyQualifiedErrorId : SqlError,Microsoft.SqlServer.Management.PowerShell.GetScriptCommand
```

#### Workaround

---

**SQL Server Management Studio**

```SQL
USE [SecuritasPortal]
GO
EXEC sp_addrolemember N'Employee_FullAccess', N'IIS APPPOOL\employee-local.securitasinc.com'
GO
```

---

### Grant PNKCAN and PNKUS users permissions on Cloud Portal site

(skipped)

### Replace absolute URLs in "User Sites" list

(skipped)

### DEV - Install Visual Studio 2015 with Update 1

(skipped)

### Install additional service packs and updates

```PowerShell
cls
```

### # Map Employee Portal URL to loopback address in Hosts file

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    127.0.0.1 employee-local.securitasinc.com
```

### # Allow specific host names mapped to 127.0.0.1

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-BackConnectionHostnames.ps1 `
    employee-local.securitasinc.com
```

```PowerShell
cls
```

## # Reset search index and perform full crawl

```PowerShell
$serviceApp = Get-SPEnterpriseSearchServiceApplication
```

### # Reset search index

```PowerShell
$serviceApp.Reset($false, $false)
```

### # Start full crawl

```PowerShell
$serviceApp |
    Get-SPEnterpriseSearchCrawlContentSource |
    % { $_.StartFullCrawl() }
```

> **Note**
>
> Expect the crawl to complete in approximately 5 minutes.

```PowerShell
cls
```

## # Prepare for snapshot

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts\Prepare for Snapshot.cmd'
```

---

**FOOBAR8**

```PowerShell
cls
```

### # Checkpoint VM

```PowerShell
$vmHost = "FORGE"
$vmName = "EXT-FOOBAR8"
$snapshotName = "Baseline Client Portal 4.0.661.0 / Cloud Portal 2.0.114.0 / Employee Portal 1.0.28.0"

Stop-VM -ComputerName $vmHost -Name $vmName

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName $snapshotName

Start-VM -ComputerName $vmHost -Name $vmName
```

---

**TODO:**

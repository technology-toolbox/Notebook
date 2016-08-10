# EXT-FOOBAR4 (2016-07-15) - Windows Server 2012 R2 Standard

Friday, July 15, 2016
8:38 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

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

ping ICEMAN -f -l 8900
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

## DEV - Configure VM storage, processors, and memory

| Disk | Drive Letter | Volume Size | VHD Type | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------- | -------------------- | ------------ |
| 0    | C:           | 50 GB       | Dynamic  | 4K                   | OSDisk       |
| 1    | D:           | 3 GB        | Dynamic  | 64K                  | Data01       |
| 2    | L:           | 1 GB        | Dynamic  | 64K                  | Log01        |
| 3    | T:           | 1 GB        | Dynamic  | 64K                  | Temp01       |
| 4    | Z:           | 10 GB       | Dynamic  | 4K                   | Backup01     |

---

**WOLVERINE- Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create Data01, Log01, Temp01, and Backup01 VHDs

```PowerShell
$vmName = "EXT-FOOBAR4"
$vmPath = "D:\NotBackedUp\VMs\$vmName"

$vhdPath = "$vmPath\Virtual Hard Disks\$vmName" `
    + "_Data01.vhdx"

New-VHD -Path $vhdPath -SizeBytes 3GB
Add-VMHardDiskDrive `
    -VMName $vmName `
    -ControllerType SCSI `
    -Path $vhdPath

$vhdPath = "$vmPath\Virtual Hard Disks\$vmName" `
    + "_Log01.vhdx"

New-VHD -Path $vhdPath -SizeBytes 1GB
Add-VMHardDiskDrive `
    -VMName $vmName `
    -ControllerType SCSI `
    -Path $vhdPath

$vhdPath = "$vmPath\Virtual Hard Disks\$vmName" `
    + "_Temp01.vhdx"

New-VHD -Path $vhdPath -SizeBytes 1GB
Add-VMHardDiskDrive `
    -VMName $vmName `
    -ControllerType SCSI `
    -Path $vhdPath

$vhdPath = "$vmPath\Virtual Hard Disks\$vmName" `
    + "_Backup01.vhdx"

New-VHD -Path $vhdPath -SizeBytes 10GB
Add-VMHardDiskDrive `
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

### TODO: DEV - Install update for Office developer tools in Visual Studio

**Note:** Microsoft Office Developer Tools for Visual Studio 2013 - August 2015 Update

Add **[https://www.microsoft.com](https://www.microsoft.com)** to **Trusted sites** zone

### TODO: DEV - Install update for SQL Server database projects in Visual Studio

Add **[http://download.microsoft.com](http://download.microsoft.com)** to **Trusted sites** zone

### TODO: DEV - Install Productivity Power Tools for Visual Studio

### Install SQL Server 2014

---

**WOLVERINE- Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Mount SQL Server 2014 installation media

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\SQL Server 2014" `
    + "\en_sql_server_2014_developer_edition_with_service_pack_1_x64_dvd_6668542.iso"

Set-VMDvdDrive -VMName EXT-FOOBAR4 -Path $imagePath
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
EXEC sys.sp_configure N'max server memory (MB)', N'1024'
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

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Mount Office Professional Plus 2016 installation media

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\Office 2016" `
    + "\en_office_professional_plus_2016_x86_x64_dvd_6962141.iso"

Set-VMDvdDrive -VMName EXT-FOOBAR4 -Path $imagePath
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
$imagePath = "\\ICEMAN\Products\Microsoft\Visio 2016" `
    + "\en_visio_professional_2016_x86_x64_dvd_6962139.iso"

Set-VMDvdDrive -VMName EXT-FOOBAR4 -Path $imagePath
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

Set-VMDvdDrive -VMName EXT-FOOBAR4 -Path $imagePath
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
$vmHost = "WOLVERINE"
$vmName = "EXT-FOOBAR4"
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

"...steps you can use to gather a Windows Installer verbose log file..."\
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

### DEV - Install Visual Studio 2015 with Update 3

---

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Mount Visual Studio 2015 with Update 3 installation media

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\Visual Studio 2015" `
    + "\en_visual_studio_enterprise_2015_with_update_3_x86_x64_dvd_8923288.iso"

Set-VMDvdDrive -VMName EXT-FOOBAR4 -Path $imagePath
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

> **Important**
>
> Wait for the installation to complete and restart the computer if prompted to do so.

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

### DEV - Install update for SQL Server database projects in Visual Studio

**Note: **Microsoft SQL Server Update for database tooling

Add **[http://download.microsoft.com](http://download.microsoft.com)** to **Trusted sites** zone

File: SSDTSetup.exe

> **Important**
>
> Wait for the installation to complete and restart the computer if prompted to do so.

### TODO: DEV - Install Productivity Power Tools for Visual Studio

---

**FOOBAR8**

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
    "\\ICEMAN\Builds\Securitas\ClientPortal\4.0.664.0" `
    "C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.664.0" `
    /E
```

### # Create and configure the farm

> **Important**
>
> Login as **EXTRANET\\setup-sharepoint-dev**

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.664.0\DeploymentFiles\Scripts

& '.\Create Farm.ps1' -CentralAdminAuthProvider NTLM -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-sp-farm-dev**.\
> Expect the previous operation to complete in approximately 4 minutes.

### Add Web servers to the farm

(skipped)

### Add SharePoint Central Administration to the "Local intranet" zone

(skipped -- since the "Create Farm.ps1" script configures this)

```PowerShell
cls
```

### # Grant permissions on DCOM applications for SharePoint

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.664.0\DeploymentFiles\Scripts

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
    -Hostnames EXT-FOOBAR4, client-local.securitasinc.com
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
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.664.0\DeploymentFiles\Scripts

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
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.664.0\DeploymentFiles\Scripts

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
If ($farmCredential -eq $null)
{
    $farmCredential = Get-Credential (Get-SPFarm).DefaultServiceAccount.Name
}
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

![(screenshot)](https://assets.technologytoolbox.com/screenshots/15/D84BBCED6D8E21D847E4083A3BAD42DDDFDCA615.png)

Wait a little bit...and then try again.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AD/CE6D63A59418127C0445938FB7EFDF6FE45231AD.png)

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
$mySiteHostLocation = "http://client-local.securitasinc.com/sites/my"

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

$searchApp = Get-SPEnterpriseSearchServiceApplication `
    -Identity "Search Service Application"

New-SPEnterpriseSearchCrawlContentSource `
    -SearchApplication $searchapp `
    -Type SharePoint `
    -Name "User profiles" `
    -StartAddresses $startAddress
```

#### # Configure the search crawl schedules

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

### DEV - Snapshot VM

---

**FOOBAR8**

```PowerShell
cls
```

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

### # Create the Web application

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.664.0\DeploymentFiles\Scripts

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
Mount-SPContentDatabase `
    -Name WSS_Content_SecuritasPortal `
    -WebApplication $env:SECURITAS_CLIENT_PORTAL_URL
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

### # Configure machine key for Web application

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.664.0\DeploymentFiles\Scripts

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

(skipped -- since the expected value is set by database restore)

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
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.664.0\DeploymentFiles\Scripts

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

07/15/2016 13:15:32.08	w3wp.exe (0x19C8)	0x1638	Web Content Management	Publishing Provisioning	6wzd	Medium	Adding key-value pair <'__GlobalNavigationExcludes','1fb4b851-8b7a-466c-b5e9-25a2f8145e00;'> to the web-property-bag for '[http://client-local.securitasinc.com/sites/cc](http://client-local.securitasinc.com/sites/cc)'	9122909d-6105-60fc-c36a-478fb3afe6e8\
07/15/2016 13:15:32.08	w3wp.exe (0x19C8)	0x1638	Web Content Management	Publishing Provisioning	6wze	Medium	Finished adding key-value pair <'__GlobalNavigationExcludes','1fb4b851-8b7a-466c-b5e9-25a2f8145e00;'> to the web-property-bag for '[http://client-local.securitasinc.com/sites/cc](http://client-local.securitasinc.com/sites/cc)'	9122909d-6105-60fc-c36a-478fb3afe6e8\
07/15/2016 13:15:32.08	w3wp.exe (0x19C8)	0x1638	Web Content Management	Publishing Provisioning	6wzd	Medium	Adding key-value pair <'__GlobalNavigationExcludes','1fb4b851-8b7a-466c-b5e9-25a2f8145e00;899fb9b6-159f-4a9d-a3e1-ed65eb1642f3;'> to the web-property-bag for '[http://client-local.securitasinc.com/sites/cc](http://client-local.securitasinc.com/sites/cc)'	9122909d-6105-60fc-c36a-478fb3afe6e8\
07/15/2016 13:15:32.08	w3wp.exe (0x19C8)	0x1638	Web Content Management	Publishing Provisioning	6wze	Medium	Finished adding key-value pair <'__GlobalNavigationExcludes','1fb4b851-8b7a-466c-b5e9-25a2f8145e00;899fb9b6-159f-4a9d-a3e1-ed65eb1642f3;'> to the web-property-bag for '[http://client-local.securitasinc.com/sites/cc](http://client-local.securitasinc.com/sites/cc)'	9122909d-6105-60fc-c36a-478fb3afe6e8\
07/15/2016 13:15:32.08	w3wp.exe (0x19C8)	0x1638	Web Content Management	Publishing Provisioning	6wzd	Medium	Adding key-value pair <'__GlobalNavigationExcludes','1fb4b851-8b7a-466c-b5e9-25a2f8145e00;899fb9b6-159f-4a9d-a3e1-ed65eb1642f3;'> to the web-property-bag for '[http://client-local.securitasinc.com/sites/cc](http://client-local.securitasinc.com/sites/cc)'	9122909d-6105-60fc-c36a-478fb3afe6e8\
07/15/2016 13:15:32.08	w3wp.exe (0x19C8)	0x1638	Web Content Management	Publishing Provisioning	6wze	Medium	Finished adding key-value pair <'__GlobalNavigationExcludes','1fb4b851-8b7a-466c-b5e9-25a2f8145e00;899fb9b6-159f-4a9d-a3e1-ed65eb1642f3;'> to the web-property-bag for '[http://client-local.securitasinc.com/sites/cc](http://client-local.securitasinc.com/sites/cc)'	9122909d-6105-60fc-c36a-478fb3afe6e8\
07/15/2016 13:15:32.10	w3wp.exe (0x19C8)	0x1638	Web Content Management	Publishing Provisioning	6wzd	Medium	Adding key-value pair <'__CurrentNavigationExcludes','1fb4b851-8b7a-466c-b5e9-25a2f8145e00;'> to the web-property-bag for '[http://client-local.securitasinc.com/sites/cc](http://client-local.securitasinc.com/sites/cc)'	9122909d-6105-60fc-c36a-478fb3afe6e8\
07/15/2016 13:15:32.10	w3wp.exe (0x19C8)	0x1638	Web Content Management	Publishing Provisioning	6wze	Medium	Finished adding key-value pair <'__CurrentNavigationExcludes','1fb4b851-8b7a-466c-b5e9-25a2f8145e00;'> to the web-property-bag for '[http://client-local.securitasinc.com/sites/cc](http://client-local.securitasinc.com/sites/cc)'	9122909d-6105-60fc-c36a-478fb3afe6e8\
07/15/2016 13:15:32.10	w3wp.exe (0x19C8)	0x1638	Web Content Management	Publishing Provisioning	6wzd	Medium	Adding key-value pair <'__CurrentNavigationExcludes','1fb4b851-8b7a-466c-b5e9-25a2f8145e00;899fb9b6-159f-4a9d-a3e1-ed65eb1642f3;'> to the web-property-bag for '[http://client-local.securitasinc.com/sites/cc](http://client-local.securitasinc.com/sites/cc)'	9122909d-6105-60fc-c36a-478fb3afe6e8\
07/15/2016 13:15:32.10	w3wp.exe (0x19C8)	0x1638	Web Content Management	Publishing Provisioning	6wze	Medium	Finished adding key-value pair <'__CurrentNavigationExcludes','1fb4b851-8b7a-466c-b5e9-25a2f8145e00;899fb9b6-159f-4a9d-a3e1-ed65eb1642f3;'> to the web-property-bag for '[http://client-local.securitasinc.com/sites/cc](http://client-local.securitasinc.com/sites/cc)'	9122909d-6105-60fc-c36a-478fb3afe6e8\
07/15/2016 13:15:32.10	w3wp.exe (0x19C8)	0x1638	Web Content Management	Publishing Provisioning	6wzd	Medium	Adding key-value pair <'__CurrentNavigationExcludes','1fb4b851-8b7a-466c-b5e9-25a2f8145e00;899fb9b6-159f-4a9d-a3e1-ed65eb1642f3;'> to the web-property-bag for '[http://client-local.securitasinc.com/sites/cc](http://client-local.securitasinc.com/sites/cc)'	9122909d-6105-60fc-c36a-478fb3afe6e8\
07/15/2016 13:15:32.10	w3wp.exe (0x19C8)	0x1638	Web Content Management	Publishing Provisioning	6wze	Medium	Finished adding key-value pair <'__CurrentNavigationExcludes','1fb4b851-8b7a-466c-b5e9-25a2f8145e00;899fb9b6-159f-4a9d-a3e1-ed65eb1642f3;'> to the web-property-bag for '[http://client-local.securitasinc.com/sites/cc](http://client-local.securitasinc.com/sites/cc)'	9122909d-6105-60fc-c36a-478fb3afe6e8

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
> Expect the previous operation to complete in approximately 3 minutes.

### Configure Google Analytics on the SecuritasConnect Web application

Tracking ID: **UA-25949832-4**

### Defragment SharePoint databases

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
$sqlcmd = @"
USE [WSS_Content_SecuritasPortal]
GO
DBCC SHRINKFILE (N'WSS_Content_SecuritasPortal')
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
```

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
    "\\ICEMAN\Builds\Securitas\CloudPortal\2.0.115.0" `
    "C:\NotBackedUp\Builds\Securitas\CloudPortal\2.0.115.0" `
    /E
```

### # Create the Web application

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\CloudPortal\2.0.115.0\DeploymentFiles\Scripts

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
robocopy `
    '\\ICEMAN\Products\Boost Solutions' `
    'C:\NotBackedUp\Temp\Boost Solutions' /E
```

Extract **ListCollectionSetup.zip** and start **Setup.exe**

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

GO

-- TODO: Add the following step to the install guide

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

```PowerShell
cls
```

##### # Attach content database

```PowerShell
Mount-SPContentDatabase `
    -Name WSS_Content_CloudPortal `
    -WebApplication $env:SECURITAS_CLOUD_PORTAL_URL
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

### # Configure object cache user accounts

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\CloudPortal\2.0.115.0\DeploymentFiles\Scripts

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
Upgrade-SPSite $env:SECURITAS_CLOUD_PORTAL_URL -VersionUpgrade -Unthrottled
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

## # Configure Web application policy for SharePoint administrators group

```PowerShell
Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

$groupName = "EXTRANET\SharePoint Admins (DEV)"

$principal = New-SPClaimsPrincipal -Identity $groupName `
    -IdentityType WindowsSecurityGroupName

$claim = $principal.ToEncodedString()

$webApp = Get-SPWebApplication $env:SECURITAS_CLOUD_PORTAL_URL

$policyRole = $webApp.PolicyRoles.GetSpecialRole(
    [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl)

$policy = $webApp.Policies.Add($claim, $groupName)
$policy.PolicyRoleBindings.Add($policyRole)

$webApp.Update()
```

### # Configure search settings for the Cloud Portal

#### # Hide the Search navigation item on the Cloud Portal top-level site

```PowerShell
Start-Process $env:SECURITAS_CLOUD_PORTAL_URL
```

##### Issue

Unable to hide the Search navigation item -- click **OK** but changes are not saved (no error reported).

07/15/2016 14:13:44.31	w3wp.exe (0x1EB0)	0x1178	Web Content Management	Publishing Provisioning	6wzd	Medium	Adding key-value pair <'__GlobalNavigationExcludes','9e19998e-0d20-46d5-98af-6c6dd6c92810;'> to the web-property-bag for '[http://cloud-local.securitasinc.com](http://cloud-local.securitasinc.com)'	e525909d-d192-60fc-c36a-4345422289fb\
07/15/2016 14:13:44.31	w3wp.exe (0x1EB0)	0x1178	Web Content Management	Publishing Provisioning	6wze	Medium	Finished adding key-value pair <'__GlobalNavigationExcludes','9e19998e-0d20-46d5-98af-6c6dd6c92810;'> to the web-property-bag for '[http://cloud-local.securitasinc.com](http://cloud-local.securitasinc.com)'	e525909d-d192-60fc-c36a-4345422289fb\
07/15/2016 14:13:44.32	w3wp.exe (0x1EB0)	0x1178	Web Content Management	Publishing Provisioning	6wzd	Medium	Adding key-value pair <'__GlobalNavigationExcludes','9e19998e-0d20-46d5-98af-6c6dd6c92810;50a50edf-612b-49d1-a971-0f5a31d1d21b;'> to the web-property-bag for '[http://cloud-local.securitasinc.com](http://cloud-local.securitasinc.com)'	e525909d-d192-60fc-c36a-4345422289fb\
07/15/2016 14:13:44.32	w3wp.exe (0x1EB0)	0x1178	Web Content Management	Publishing Provisioning	6wze	Medium	Finished adding key-value pair <'__GlobalNavigationExcludes','9e19998e-0d20-46d5-98af-6c6dd6c92810;50a50edf-612b-49d1-a971-0f5a31d1d21b;'> to the web-property-bag for '[http://cloud-local.securitasinc.com](http://cloud-local.securitasinc.com)'	e525909d-d192-60fc-c36a-4345422289fb\
07/15/2016 14:13:44.34	w3wp.exe (0x1EB0)	0x1178	Web Content Management	Publishing Provisioning	6wzd	Medium	Adding key-value pair <'__GlobalNavigationExcludes','9e19998e-0d20-46d5-98af-6c6dd6c92810;50a50edf-612b-49d1-a971-0f5a31d1d21b;'> to the web-property-bag for '[http://cloud-local.securitasinc.com](http://cloud-local.securitasinc.com)'	e525909d-d192-60fc-c36a-4345422289fb\
07/15/2016 14:13:44.34	w3wp.exe (0x1EB0)	0x1178	Web Content Management	Publishing Provisioning	6wze	Medium	Finished adding key-value pair <'__GlobalNavigationExcludes','9e19998e-0d20-46d5-98af-6c6dd6c92810;50a50edf-612b-49d1-a971-0f5a31d1d21b;'> to the web-property-bag for '[http://cloud-local.securitasinc.com](http://cloud-local.securitasinc.com)'	e525909d-d192-60fc-c36a-4345422289fb\
07/15/2016 14:13:44.35	w3wp.exe (0x1EB0)	0x1178	Web Content Management	Publishing Provisioning	6wzd	Medium	Adding key-value pair <'__GlobalNavigationExcludes','9e19998e-0d20-46d5-98af-6c6dd6c92810;50a50edf-612b-49d1-a971-0f5a31d1d21b;'> to the web-property-bag for '[http://cloud-local.securitasinc.com](http://cloud-local.securitasinc.com)'	e525909d-d192-60fc-c36a-4345422289fb\
07/15/2016 14:13:44.35	w3wp.exe (0x1EB0)	0x1178	Web Content Management	Publishing Provisioning	6wze	Medium	Finished adding key-value pair <'__GlobalNavigationExcludes','9e19998e-0d20-46d5-98af-6c6dd6c92810;50a50edf-612b-49d1-a971-0f5a31d1d21b;'> to the web-property-bag for '[http://cloud-local.securitasinc.com](http://cloud-local.securitasinc.com)'	e525909d-d192-60fc-c36a-4345422289fb\
07/15/2016 14:13:44.40	w3wp.exe (0x1EB0)	0x1178	Web Content Management	Publishing Provisioning	6wzd	Medium	Adding key-value pair <'__CurrentNavigationExcludes','9e19998e-0d20-46d5-98af-6c6dd6c92810;'> to the web-property-bag for '[http://cloud-local.securitasinc.com](http://cloud-local.securitasinc.com)'	e525909d-d192-60fc-c36a-4345422289fb\
07/15/2016 14:13:44.40	w3wp.exe (0x1EB0)	0x1178	Web Content Management	Publishing Provisioning	6wze	Medium	Finished adding key-value pair <'__CurrentNavigationExcludes','9e19998e-0d20-46d5-98af-6c6dd6c92810;'> to the web-property-bag for '[http://cloud-local.securitasinc.com](http://cloud-local.securitasinc.com)'	e525909d-d192-60fc-c36a-4345422289fb\
07/15/2016 14:13:44.42	w3wp.exe (0x1EB0)	0x1178	Web Content Management	Publishing Provisioning	6wzd	Medium	Adding key-value pair <'__CurrentNavigationExcludes','9e19998e-0d20-46d5-98af-6c6dd6c92810;50a50edf-612b-49d1-a971-0f5a31d1d21b;'> to the web-property-bag for '[http://cloud-local.securitasinc.com](http://cloud-local.securitasinc.com)'	e525909d-d192-60fc-c36a-4345422289fb\
07/15/2016 14:13:44.42	w3wp.exe (0x1EB0)	0x1178	Web Content Management	Publishing Provisioning	6wze	Medium	Finished adding key-value pair <'__CurrentNavigationExcludes','9e19998e-0d20-46d5-98af-6c6dd6c92810;50a50edf-612b-49d1-a971-0f5a31d1d21b;'> to the web-property-bag for '[http://cloud-local.securitasinc.com](http://cloud-local.securitasinc.com)'	e525909d-d192-60fc-c36a-4345422289fb\
07/15/2016 14:13:44.45	w3wp.exe (0x1EB0)	0x1178	Web Content Management	Publishing Provisioning	6wzd	Medium	Adding key-value pair <'__CurrentNavigationExcludes','9e19998e-0d20-46d5-98af-6c6dd6c92810;50a50edf-612b-49d1-a971-0f5a31d1d21b;'> to the web-property-bag for '[http://cloud-local.securitasinc.com](http://cloud-local.securitasinc.com)'	e525909d-d192-60fc-c36a-4345422289fb\
07/15/2016 14:13:44.45	w3wp.exe (0x1EB0)	0x1178	Web Content Management	Publishing Provisioning	6wze	Medium	Finished adding key-value pair <'__CurrentNavigationExcludes','9e19998e-0d20-46d5-98af-6c6dd6c92810;50a50edf-612b-49d1-a971-0f5a31d1d21b;'> to the web-property-bag for '[http://cloud-local.securitasinc.com](http://cloud-local.securitasinc.com)'	e525909d-d192-60fc-c36a-4345422289fb\
07/15/2016 14:13:44.46	w3wp.exe (0x1EB0)	0x1178	Web Content Management	Publishing Provisioning	6wzd	Medium	Adding key-value pair <'__CurrentNavigationExcludes','9e19998e-0d20-46d5-98af-6c6dd6c92810;50a50edf-612b-49d1-a971-0f5a31d1d21b;'> to the web-property-bag for '[http://cloud-local.securitasinc.com](http://cloud-local.securitasinc.com)'	e525909d-d192-60fc-c36a-4345422289fb\
07/15/2016 14:13:44.46	w3wp.exe (0x1EB0)	0x1178	Web Content Management	Publishing Provisioning	6wze	Medium	Finished adding key-value pair <'__CurrentNavigationExcludes','9e19998e-0d20-46d5-98af-6c6dd6c92810;50a50edf-612b-49d1-a971-0f5a31d1d21b;'> to the web-property-bag for '[http://cloud-local.securitasinc.com](http://cloud-local.securitasinc.com)'	e525909d-d192-60fc-c36a-4345422289fb

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

### # Upgrade Cloud Portal Sites

```PowerShell
$stopwatch = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-Stopwatch.ps1

Get-SPSite -WebApplication $env:SECURITAS_CLOUD_PORTAL_URL -Limit ALL |
    ? { $_.CompatibilityLevel -lt 15 } |
    % {
        $siteUrl = $_.Url

        Write-Host "Upgrading site ($siteUrl)..."

        Get-SPWeb -Site $siteUrl |
            % {
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
            % {
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

### Change recovery model of content database from Simple to Full

(skipped)

```PowerShell
cls
```

### # Resume Search Service Application

# **TODO:** Add this step to the installation guide

```PowerShell
$serviceApp = Get-SPEnterpriseSearchServiceApplication `
    "Search Service Application"

Resume-SPEnterpriseSearchServiceApplication $serviceApp
```

### # Start full crawl of user profiles

```PowerShell
$contentSource = Get-SPEnterpriseSearchCrawlContentSource `
    -SearchApplication $serviceApp `
    -Identity "User profiles"

$contentSource.StartFullCrawl()
```

> **Note**
>
> Expect the crawl to complete in approximately 5 minutes.

| **Started**       | **Completed**     | **Duration** | **Successes** | **Warnings** | **Errors** | **Crawl Rate (dps)** | **Repository Latency (ms)** |
| ----------------- | ----------------- | ------------ | ------------- | ------------ | ---------- | -------------------- | --------------------------- |
| 7/15/2016 2:22 PM | 7/15/2016 2:27 PM | 00:05:00     | 2,234         | 140          | 6          | [7.9](7.9)           | [325](325)                  |

From <[http://ext-foobar4:22812/_admin/search/CrawlLogCrawls.aspx?appid={756661dc-8a93-4740-9fd0-2b971ae0580d}&csid=1](http://ext-foobar4:22812/_admin/search/CrawlLogCrawls.aspx?appid={756661dc-8a93-4740-9fd0-2b971ae0580d}&csid=1)>

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

## # Checkpoint VM

### # Delete C:\\Windows\\SoftwareDistribution folder (2.24 GB)

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse
```

### # Prepare for snapshot

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts\Prepare for Snapshot.cmd'
```

---

**FOOBAR8**

```PowerShell
cls
```

### # Remove media from DVD drive

```PowerShell
Set-VMDvdDrive -ComputerName WOLVERINE -VMName EXT-FOOBAR4 -Path $null
```

### # Checkpoint VM

```PowerShell
$vmHost = "WOLVERINE"
$vmName = "EXT-FOOBAR4"
$snapshotName = "Baseline Client Portal 4.0.664.0 / Cloud Portal 2.0.115.0 / Employee Portal 1.0.28.0"

Stop-VM -ComputerName $vmHost -Name $vmName

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName $snapshotName

Start-VM -ComputerName $vmHost -Name $vmName
```

---

**TODO:**

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

cd C:\NotBackedUp\Securitas\ClientPortal\Main\Code\DeploymentFiles\Scripts

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
cd C:\NotBackedUp\Securitas\ClientPortal\Main\Code\DeploymentFiles\Scripts

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

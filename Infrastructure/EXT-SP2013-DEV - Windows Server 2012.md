# EXT-SP2013-DEV - Windows Server 2012 Standard

Tuesday, February 23, 2016\
5:55 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Install Windows Server 2012

---

**WOLVERINE** - Run as administrator

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

#### # Set time zone

```PowerShell
tzutil /s "Mountain Standard Time"
```

#### # Configure networking

##### # Rename network connection

```PowerShell
Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "LAN 1 - 192.168.10.x"
```

##### # Enable jumbo frames

```PowerShell
Set-NetAdapterAdvancedProperty `
    -Name "LAN 1 - 192.168.10.x" `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping ICEMAN -f -l 8900
```

##### # Configure static IPv4 address

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

##### # Configure static IPv6 address

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

**EXT-DC01** - Run as administrator

```PowerShell
$computerName = "EXT-SP2013-DEV"
$targetPath = ("OU=SharePoint Servers,OU=Servers,OU=Resources,OU=Development" `
    + ",DC=extranet,DC=technologytoolbox,DC=com")

Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath
```

---

---

**WOLVERINE** - Run as administrator

```PowerShell
$vmName = "EXT-SP2013-DEV"

Restart-VM $vmName -Force
```

---

### Remove disk from virtual CD/DVD drive

---

**WOLVERINE** - Run as administrator

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

### # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

### # Configure firewall rules for [http://poshpaig.codeplex.com/](POSHPAIG)

```PowerShell
Set-ExecutionPolicy RemoteSigned -Force

C:\NotBackedUp\Public\Toolbox\PowerShell\Enable-RemoteWindowsUpdate.ps1 -Verbose
```

### # Disable firewall rules for [http://poshpaig.codeplex.com/](POSHPAIG)

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Disable-RemoteWindowsUpdate.ps1 -Verbose
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

**WOLVERINE** - Run as administrator

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

#### Expand C: partition

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

### DEV - Install Visual Studio 2012

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

#### # Mount Visual Studio 2012 installation media

```PowerShell
$isoPath = "\\ICEMAN\Products\Microsoft\Visual Studio 2012" `
    + "\en_visual_studio_ultimate_2012_x86_dvd_920947.iso"

Set-VMDvdDrive -VMName EXT-SP2013-DEV -Path $isoPath
```

---

```PowerShell
& X:\vs_ultimate.exe
```

### Install SQL Server 2012

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

#### # Mount Windows Server 2012 installation media

```PowerShell
$isoPath = "\\ICEMAN\Products\Microsoft\Windows Server 2012" `
    + "\en_windows_server_2012_x64_dvd_915478.iso"

Set-VMDvdDrive -VMName EXT-SP2013-DEV -Path $isoPath
```

---

```PowerShell
cls
```

#### # Install .NET Framework 3.5

```PowerShell
$sourcePath = "X:\sources\sxs"

Install-WindowsFeature NET-Framework-Core -Source $sourcePath
```

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

#### # Mount SQL Server installation media

```PowerShell
$isoPath = "\\ICEMAN\Products\Microsoft\SQL Server 2012" `
    + "\en_sql_server_2012_developer_edition_with_sp1_x64_dvd_1228540.iso"

Set-VMDvdDrive -VMName EXT-SP2013-DEV -Path $isoPath
```

---

```PowerShell
& X:\setup.exe
```

(install SQL Server)

```PowerShell
Restart-Computer
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

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

#### # Mount Office Professional Plus 2013 with SP1 installation media

```PowerShell
$isoPath = "\\ICEMAN\Products\Microsoft\Office 2013" `
    + "\en_office_professional_plus_2013_with_sp1_x86_and_x64_dvd_3928186.iso"

Set-VMDvdDrive -VMName EXT-SP2013-DEV -Path $isoPath
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

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

#### # Mount Visio Professional 2013 with SP1 installation media

```PowerShell
$isoPath = "\\ICEMAN\Products\Microsoft\Visio 2013" `
    + "\en_visio_professional_2013_with_sp1_x86_and_x64_dvd_3910950.iso"

Set-VMDvdDrive -VMName EXT-SP2013-DEV -Path $isoPath
```

---

```PowerShell
& X:\setup.exe
```

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

> **Note**
>
> Wait for the installation to complete.

```PowerShell
& "\\ICEMAN\Products\Adobe\AdbeRdrUpd831_all_incr.msp"
```

## Install and configure SharePoint Server 2013

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

### # Checkpoint VM

```PowerShell
$vmName = "EXT-SP2013-DEV"
$snapshotName = "Before - Install SharePoint 2013 prerequisites"

Stop-VM -Name $vmName

Checkpoint-VM `
    -Name $vmName `
    -SnapshotName $snapshotName

Start-VM -Name $vmName
```

---

```PowerShell
cls
```

### # Install SharePoint 2013 prerequisites on the farm servers

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

#### # Insert the SharePoint 2013 installation media into the DVD drive for the SharePoint VM

```PowerShell
$isoPath = "\\ICEMAN\Products\Microsoft\SharePoint 2013" `
    + "\en_sharepoint_server_2013_x64_dvd_1121447.iso"

Set-VMDvdDrive -Path $isoPath -VMName EXT-SP2013-DEV
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
    "\\ICEMAN\Products\Microsoft\SharePoint 2013\PrerequisiteInstallerFiles"

$prereqPath = "C:\NotBackedUp\Temp\PrerequisiteInstallerFiles"

robocopy $sourcePath $prereqPath /E

& X:\PrerequisiteInstaller.exe `
    /SQLNCli:"$prereqPath\sqlncli.msi" `
    /PowerShell:"$prereqPath\Windows6.1-KB2506143-x64.msu" `
    /NETFX:"$prereqPath\netfx_full_x64.msi" `
    /IDFX:"$prereqPath\Windows6.1-KB974405-x64.msu" `
    /Sync:"$prereqPath\Synchronization.msi" `
    /AppFabric:"$prereqPath\WindowsServerAppFabricSetup_x64.exe" `
    /IDFX11:"$prereqPath\MicrosoftIdentityExtensions-64.msi" `
    /MSIPCClient:"$prereqPath\setup_msipc_x64.msi" `
    /WCFDataServices:"$prereqPath\WcfDataServices.exe" `
    /KB2671763:"$prereqPath\AppFabric1.1-RTM-KB2671763-x64-ENU.exe"
```

> **Note**
>
> The server will need to be restarted several times to complete the installation of the SharePoint prerequisites.

```PowerShell
Remove-Item "C:\NotBackedUp\Temp\PrerequisiteInstallerFiles" -Recurse
```

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

### # Delete VM checkpoints

```PowerShell
$vmName = "EXT-SP2013-DEV"

Stop-VM -Name $vmName

Remove-VMSnapshot -VMName $vmName

while (Get-VM -Name $vmName | Where Status -eq "Merging disks") {
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 5
}

Write-Host
```

```PowerShell
cls
```

### # Checkpoint VM

```PowerShell
$snapshotName = "Before - Install SharePoint Server 2013"

Checkpoint-VM `
    -Name $vmName `
    -SnapshotName $snapshotName

Start-VM -Name $vmName
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

> **Important**
>
> Restart PowerShell for environment variable change to take effect.

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

### # Delete VM checkpoints

```PowerShell
$vmName = "EXT-SP2013-DEV"

Stop-VM -Name $vmName

Remove-VMSnapshot -VMName $vmName

while (Get-VM -Name $vmName | Where Status -eq "Merging disks") {
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 5
}

Write-Host
```

### # Checkpoint VM

```PowerShell
$snapshotName = "Before - Create and configure the farm"

Checkpoint-VM `
    -Name $vmName `
    -SnapshotName $snapshotName

Start-VM -Name $vmName
```

---

```PowerShell
cls
```

### # Create and configure the farm

```PowerShell
cd C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts

& '.\Create Farm.ps1' -CentralAdminAuthProvider NTLM -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-spfarm-dev**.\
> Expect the previous operation to complete in approximately 4 minutes.

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

New-SPUsageApplication -Name "Usage and Health Data Collection Service"
```

### # Configure outgoing e-mail settings

```PowerShell

$smtpServer = "smtp-test.technologytoolbox.com"
$fromAddress = "s-spfarm-dev@technologytoolbox.com"
$replyAddress = "no-reply@technologytoolbox.com"
$characterSet = 65001 # Unicode (UTF-8)

$centralAdmin = Get-SPWebApplication -IncludeCentralAdministration |
    where { $_.IsAdministrationWebApplication -eq $true }

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

## # Configure SharePoint services and service applications

### # Change the service account for the Distributed Cache

```PowerShell
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

#### # Create the Managed Metadata Service

```PowerShell
& '.\Configure Managed Metadata Service.ps1' -Verbose
```

### # Configure the User Profile Service Application

#### # Create the User Profile Service Application

```PowerShell
# Create User Profile Service Application as EXTRANET\\s-spfarm-dev

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

**PowerShell** -- running as **EXTRANET\\s-spfarm-dev**

```PowerShell
cd C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts

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

### # Create and configure the search service application

```PowerShell
& '.\Configure SharePoint 2013 Search.ps1' -Verbose
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

## TODO: Configure Office Web Apps

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

### # DEV - Checkpoint VM

```PowerShell
$vmName = "EXT-SP2013-DEV"
$snapshotName = "Baseline SharePoint Server 2013 configuration"

Stop-VM -Name $vmName

Checkpoint-VM `
    -Name $vmName `
    -SnapshotName $snapshotName

Start-VM -Name $vmName
```

---

**TODO:**

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

#### # Remove SharePoint farm account from local Administrators group

```PowerShell
net localgroup Administrators /delete EXTRANET\s-spfarm-dev

Restart-Service SPTimerV4
```

#### Configure synchronization connections and import data from Active Directory

| **Connection Name** | **Forest Name**            | **Account Name**            |
| ------------------- | -------------------------- | --------------------------- |
| TECHTOOLBOX         | corp.technologytoolbox.com | TECHTOOLBOX\\svc-sp-ups-dev |
| FABRIKAM            | corp.fabrikam.com          | FABRIKAM\\s-sp-ups-dev      |

### # Configure people search in SharePoint

```PowerShell
$mySiteHostLocation = "http://my-local.fabrikam.com/"

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

```PowerShell
cls
```

## # Start full crawl

```PowerShell
Get-SPEnterpriseSearchServiceApplication |
    Get-SPEnterpriseSearchCrawlContentSource |
    foreach { $_.StartFullCrawl() }
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

### Install latest service pack and updates

```PowerShell
cls
```

### # Delete C:\\Windows\\SoftwareDistribution folder (1.72 GB)

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse

Restart-Computer
```

### Check for updates using Windows Update (after removing patches folder)

- **Most recent check for updates: Never -> Most recent check for updates: Today at 11:41 AM**
- C:\\Windows\\SoftwareDistribution folder is now 120 MB

```PowerShell
cls
```

### # Clean up the WinSxS folder

```PowerShell
Dism.exe /Online /Cleanup-Image /StartComponentCleanup
```

## Issue - IPv6 address range changed by Comcast

### # Remove static IPv6 address

```PowerShell
Remove-NetIPAddress 2601:282:4201:e500::221 -Confirm:$false
```

### # Enable DHCP on IPv6 interface

```PowerShell
$interfaceAlias = "LAN 1 - 192.168.10.x"

@("IPv6") | foreach {
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

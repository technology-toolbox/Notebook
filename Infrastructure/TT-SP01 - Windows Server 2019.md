# TT-SP01 - Windows Server 2019 Standard Edition

Monday, September 23, 2019
10:39 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

### Install Windows Server 2019

---

**TT-ADMIN02** - Run as administrator

```PowerShell
cls
```

#### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05B"
$vmName = "TT-SP01"
$vmPath = "E:\NotBackedUp\VMs\$vmName"
$vhdPath = "$vmPath\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 45GB `
    -MemoryStartupBytes 12GB `
    -SwitchName "Embedded Team Switch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 4

Set-VMNetworkAdapterVlan `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Access `
    -VlanId 30

Start-VM -ComputerName $vmHost -Name $vmName
```

---

#### Install custom Windows Server 2019 image

- On the **Task Sequence** step, select **Windows Server 2019** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **TT-SP01**.
  - Click **Next**.
- On the **Applications** step, do not select any applications, and click **Next**.

---

**TT-ADMIN02** - Run as administrator

```PowerShell
cls
```

#### # Move computer to different OU

```PowerShell
$vmName = "TT-SP01"

$targetPath = "OU=SharePoint Servers,OU=Servers" `
    + ",OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com"

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

#### # Set first boot device to hard drive

```PowerShell
$vmHost = "TT-HV05B"

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

#### # Configure Windows Update

##### # Add machine to security group for Windows Update schedule

```PowerShell
Add-ADGroupMember -Identity "Windows Update - Slot 3" -Members ($vmName + '$')
```

---

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

robocopy $source $destination /E /XD "Microsoft SDKs" git-for-windows
```

### # Enable performance counters for Server Manager

```PowerShell
$taskName = "\Microsoft\Windows\PLA\Server Manager Performance Monitor"

Enable-ScheduledTask -TaskName $taskName

logman start "Server Manager Performance Monitor"
```

### Configure networking

---

**TT-ADMIN02** - Run as administrator

```PowerShell
cls
```

#### # Move VM to Production VM network and configure static IP address

```PowerShell
$vmName = "TT-SP01"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Production VM Network"
$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"
$ipPool = Get-SCStaticIPAddressPool -Name "Production-15 Address Pool"

Stop-SCVirtualMachine $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork

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
    -IPv4AddressType Static `
    -IPv4Addresses $IPAddress.Address

Start-SCVirtualMachine $vmName
```

---

```PowerShell
$interfaceAlias = "Production"
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

### Configure storage

| Disk | Drive Letter | Volume Size | VHD Type | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------- | -------------------- | ------------ |
| 0    | C:           | 45 GB       | Dynamic  | 4K                   | OSDisk       |
| 1    | D:           | 15 GB       | Dynamic  | 4K                   | Data01       |
| 2    | L:           | 15 GB       | Dynamic  | 4K                   | Log01        |

---

**TT-ADMIN02** - Run as administrator

```PowerShell
cls
```

#### # Configure storage for SharePoint Server

```PowerShell
$vmHost = "TT-HV05B"
$vmName = "TT-SP01"
$vmPath = "E:\NotBackedUp\VMs\$vmName"
```

##### # Add "Data01" VHD

```PowerShell
$vhdPath = $vmPath + "\Virtual Hard Disks\$vmName" + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 15GB
Add-VMHardDiskDrive `
  -ComputerName $vmHost `
  -VMName $vmName `
  -Path $vhdPath `
  -ControllerType SCSI
```

##### # Add "Log01" VHD

```PowerShell
$vhdPath = $vmPath + "\Virtual Hard Disks\$vmName" + "_Log01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 15GB
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

##### # Format Data01 drive

```PowerShell
Get-Disk 1 |
  Initialize-Disk -PartitionStyle GPT -PassThru |
  New-Partition -DriveLetter D -UseMaximumSize |
  Format-Volume `
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
    -FileSystem NTFS `
    -NewFileSystemLabel "Log01" `
    -Confirm:$false
```

## Configure Max Degree of Parallelism for SharePoint

## Create setup and service accounts for SharePoint

---

**TT-ADMIN02** - Run as administrator

```PowerShell
cls
```

### # Create setup account for SharePoint

```PowerShell
$displayName = "Setup account for SharePoint"
$defaultUserName = "setup-sharepoint"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@corp.technologytoolbox.com"
$orgUnit = "OU=Setup Accounts,OU=IT,DC=corp,DC=technologytoolbox,DC=com"

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

### # Create service account for SharePoint user profile synchronization

```PowerShell
$displayName = "Service account for SharePoint user profile synchronization"
$defaultUserName = "s-sp-ups"

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

### # Grant Replicate Directory Changes permission to UPS service account

```PowerShell
$serviceAccount = "TECHTOOLBOX\s-sp-ups"

$rootDSE = [ADSI]"LDAP://RootDSE"
$defaultNamingContext = $rootDse.defaultNamingContext
$configurationNamingContext = $rootDse.configurationNamingContext
$userPrincipal = New-Object Security.Principal.NTAccount($serviceAccount)

dsacls.exe "$defaultNamingContext" /G "$($userPrincipal):CA;Replicating Directory Changes"
dsacls.exe "$configurationNamingContext" /G "$($userPrincipal):CA;Replicating Directory Changes"
```

> **Important**
>
> When the NetBIOS domain name is different than the FQDN, the Replicating Directory Changes permission must be granted on the Configuration Naming Context (as well as the domain itself).\
> Reference:
>
> **How to grant the Replicate Directory Change on the domain configuration partition**\
> From <[http://blogs.technet.com/b/steve_chen/archive/2010/09/20/user-profile-sync-sharepoint-2010.aspx](http://blogs.technet.com/b/steve_chen/archive/2010/09/20/user-profile-sync-sharepoint-2010.aspx)>

---

## Baseline virtual machine

---

**TT-ADMIN02** - Run as administrator

```PowerShell
cls
```

### # Checkpoint VM

```PowerShell
$vmHost = "TT-HV05B"
$vmName = "TT-SP01"
$checkpointName = "Baseline"

Stop-VM -ComputerName $vmHost -Name $vmName

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName $checkpointName
```

---

## Back up virtual machine

## Install SharePoint 2016

### Download SharePoint 2016 prerequisites to a file share

### Prepare server for SharePoint installation

#### Add SharePoint setup account to sysadmin role on SQL Server

---

**SQL Server Management Studio** - Database Engine - **TT-SQL03**

```SQL
USE [master]
GO
CREATE LOGIN [TECHTOOLBOX\setup-sharepoint]
FROM WINDOWS WITH DEFAULT_DATABASE=[master]
GO
ALTER SERVER ROLE [sysadmin]
ADD MEMBER [TECHTOOLBOX\setup-sharepoint]
GO
```

---

#### # Add setup account to local Administrators group

```PowerShell
$domain = "TECHTOOLBOX"
$username = "setup-sharepoint"

([ADSI]"WinNT://./Administrators,group").Add(
    "WinNT://$domain/$username,user")
```

> **Important**
>
> Sign out and then sign in using the setup account for SharePoint.

### # Install SharePoint 2016 prerequisites on farm servers

#### # Install prerequisites for SharePoint 2016

```PowerShell
$imagePath = ('\\TT-FS01\Products\Microsoft\SharePoint 2016\' `
    + 'en_sharepoint_server_2016_x64_dvd_8419458.iso')

$imageDriveLetter = (Mount-DiskImage -ImagePath $ImagePath -PassThru |
    Get-Volume).DriveLetter

$sourcePath = `
    "\\TT-FS01\Products\Microsoft\SharePoint 2016\PrerequisiteInstallerFiles"

$prereqPath = "C:\NotBackedUp\Temp\PrerequisiteInstallerFiles"

robocopy $sourcePath $prereqPath /E

& ("$imageDriveLetter" + ":\PrerequisiteInstaller.exe") `
    /SQLNCli:"$prereqPath\sqlncli.msi" `
    /Sync:"$prereqPath\Synchronization.msi" `
    /AppFabric:"$prereqPath\WindowsServerAppFabricSetup_x64.exe" `
    /IDFX11:"$prereqPath\MicrosoftIdentityExtensions-64.msi" `
    /MSIPCClient:"$prereqPath\setup_msipc_x64.exe" `
    /KB3092423:"$prereqPath\AppFabric-KB3092423-x64-ENU.exe" `
    /WCFDataServices56:"$prereqPath\WcfDataServices.exe" `
    /ODBC:"$prereqPath\msodbcsql.msi" `
    /DotNetFx:"$prereqPath\NDP46-KB3045557-x86-x64-AllOS-ENU.exe" `
    /MSVCRT11:"$prereqPath\vcredist_x64-MSVCRT11.exe" `
    /MSVCRT14:"$prereqPath\vc_redist.x64-MSVCRT14.exe"
```

> **Important**
>
> Wait for the prerequisites to be installed. When prompted, restart the server to continue the installation.

```PowerShell
cls
```

### # Install SharePoint Server 2016

```PowerShell
& ("$imageDriveLetter" + ":\setup.cmd")
```

> **Important**
>
> Wait for the installation to complete.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CC/56CFC640FEA4E74AFADD9D7A00EFB9C97D9F51CC.png)

Click **Install SharePoint Server**. UAC, click Yes.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A9/6B4AA8D4347B5E5CE0E3A78681130258A27A59A9.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/79/8B74B8D6D172788F910B0B8DB841DE63A1B92579.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/43/25DAB95A5E67618BF15DD4D18E7AC1C9A909B043.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0D/525DE25E307A8CD379C427766F32964C4621820D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/49/7A7B4A12579D8943D9974D41F94222D9378A3A49.png)

Clear the checkbox and click **Close**.

```PowerShell
cls
```

### # Add the SharePoint bin folder to the PATH environment variable

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-PathFolders.ps1 `
    ("C:\Program Files\Common Files\Microsoft Shared\web server extensions" `
        + "\16\BIN") `
    -EnvironmentVariableTarget "Machine"
```

### # Install Cumulative Update for SharePoint Server 2016

#### # Download update

```PowerShell
$patch = "16.0.4900.1000 - SharePoint 2016 September 2019 CU"

robocopy `
    "\\TT-FS01\Products\Microsoft\SharePoint 2016\Patches\$patch" `
    "C:\NotBackedUp\Temp\$patch" `
    /E
```

#### # Install language independent update

```PowerShell
& "C:\NotBackedUp\Temp\$patch\sts2016-kb4475590-fullfile-x64-glb.exe"
```

> **Important**
>
> Wait for the update to be installed.

#### # Install language dependent update

```PowerShell
& "C:\NotBackedUp\Temp\$patch\wssloc2016-kb4475594-fullfile-x64-glb.exe"
```

> **Important**
>
> Wait for the update to be installed.

```PowerShell
cls
Remove-Item "C:\NotBackedUp\Temp\$patch" -Recurse
```

## Snapshot VM before configuring SharePoint

---

**TT-ADMIN02** - Run as administrator

### # Checkpoint VM

```PowerShell
$snapshotName = 'Before SharePoint Server 2016 configuration'
$vmHost = 'TT-HV05B'
$vmName = 'TT-SP01'

Stop-VM -ComputerName $vmHost -VMName $vmName

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName $snapshotName

Start-VM -ComputerName $vmHost -VMName $vmName
```

---

```PowerShell
cls
```

## # Configure SharePoint Server 2016

### # Create SharePoint farm

```PowerShell
cd C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts

& '.\Create Farm.ps1' -DatabaseServer TT-SQL03 -LocalServerRole SingleServerFarm
```

> **Note**
>
> When prompted for the service account, specify **TECHTOOLBOX\\s-sharepoint**.\
> Expect the previous operation to complete in approximately 18 minutes.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D3/E24650FC6C2E6056BA585A6D5C4C4BE2B21570D3.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5F/C6DC76E4A62A141C1F0E30D11B37BC3FF7A4775F.png)

### Add Web servers to SharePoint farm

(skipped)

### Add SharePoint Central Administration to "Local intranet" zone

(skipped -- since the "Create Farm.ps1" script configures this)

---

**TT-ADMIN02** - Run as administrator

```PowerShell
cls
```

### # Configure Service Principal Names for Central Administration

```PowerShell
setspn -A http/tt-sp01.corp.technologytoolbox.com:22812 s-sharepoint
setspn -A http/tt-sp01:22812 s-sharepoint
```

---

```PowerShell
cls
```

### # Enable nonblocking garbage collection for Distributed Cache Service

```PowerShell
Notepad ($env:ProgramFiles `
    + "\AppFabric 1.1 for Windows Server\DistributedCacheService.exe.config")
```

---

File - **DistributedCacheService.exe.config**

```XML
  <appSettings>
    <add key="backgroundGC" value="true"/>
  </appSettings>
```

---

```PowerShell
cls
```

### # Configure PowerShell access for SharePoint administrators group

```PowerShell
$adminsGroup = "TECHTOOLBOX\SharePoint Admins"

Get-SPDatabase |
    where {$_.WebApplication -like "SPAdministrationWebApplication"} |
    Add-SPShellAdmin $adminsGroup
```

```PowerShell
cls
```

### # Grant permissions on DCOM applications for SharePoint

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts\Configure DCOM Permissions.ps1'
```

#### Reference

**Event ID 10016, KB 920783, and the WSS_WPG Group**\
Pasted from <[http://www.technologytoolbox.com/blog/jjameson/archive/2009/10/17/event-id-10016-kb-920783-and-the-wss-wpg-group.aspx](http://www.technologytoolbox.com/blog/jjameson/archive/2009/10/17/event-id-10016-kb-920783-and-the-wss-wpg-group.aspx)>

```PowerShell
cls
```

### # Configure diagnostic logging

```PowerShell
Add-PSSnapin Microsoft.SharePoint.PowerShell

Set-SPDiagnosticConfig `
    -LogLocation "L:\Microsoft Office Servers\16.0\Logs" `
    -LogDiskSpaceUsageGB 14 `
    -LogMaxDiskSpaceUsageEnabled:$true
```

### # Configure usage and health data collection

```PowerShell
Set-SPUsageService `
    -LoggingEnabled 1 `
    -UsageLogLocation "L:\Microsoft Office Servers\16.0\Logs"

New-SPUsageApplication
```

```PowerShell
cls
```

### # Configure outgoing e-mail settings

```PowerShell
Add-PSSnapin Microsoft.SharePoint.PowerShell

$smtpServer = "smtp.technologytoolbox.com"
$fromAddress = "s-sharepoint@technologytoolbox.com"
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

## Backup SharePoint farm

---

**TT-FS01** - Run as administrator

```PowerShell
cls
```

### # Create share and configure permissions for SharePoint backups

```PowerShell
mkdir 'F:\Shares\Backups\SharePoint - TT-SP01'

icacls 'F:\Shares\Backups\SharePoint - TT-SP01' /grant 'TECHTOOLBOX\setup-sharepoint:(OI)(CI)(F)'

icacls 'F:\Shares\Backups\SharePoint - TT-SP01' /grant 'TECHTOOLBOX\s-sharepoint:(OI)(CI)(F)'

icacls 'F:\Shares\Backups\SharePoint - TT-SP01' /grant 'TECHTOOLBOX\TT-SQL03$:(OI)(CI)(M)'
```

---

```PowerShell
cls
```

### # Backup farm

```PowerShell
Backup-SPFarm `
    -Directory '\\TT-FS01\Backups\SharePoint - TT-SP01' `
    -BackupMethod Full
```

## Backup SharePoint 2013 environment

---

**POLARIS** - Run as administrator

```PowerShell
cls
```

### # Stop SharePoint services

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts\Stop SharePoint Services.cmd'
```

---

---

**SQL Server Management Studio** - Database Engine - **HAVOK**

### -- Backup databases in SharePoint 2013 environment

```SQL
DECLARE @backupPath NVARCHAR(255) = N'\\TT-FS01\Backups\HAVOK'

DECLARE @backupFilePath NVARCHAR(255)

-- Backup database for Managed Metadata Service

SET @backupFilePath = @backupPath + N'\ManagedMetadataService.bak'

BACKUP DATABASE [ManagedMetadataService]
TO DISK = @backupFilePath
WITH NOFORMAT, NOINIT
    , NAME = N'ManagedMetadataService-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY

-- Backup database for Secure Store Service

SET @backupFilePath = @backupPath + N'\SecureStoreService.bak'

BACKUP DATABASE [SecureStoreService]
TO DISK = @backupFilePath
WITH NOFORMAT, NOINIT
    , NAME = N'SecureStoreService-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY

-- Backup databases for User Profile Service

SET @backupFilePath = @backupPath + N'\UserProfileService_Profile.bak'

BACKUP DATABASE [UserProfileService_Profile]
TO DISK = @backupFilePath
WITH NOFORMAT, NOINIT
    , NAME = N'UserProfileService_Profile-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY

SET @backupFilePath = @backupPath + N'\UserProfileService_Social.bak'

BACKUP DATABASE [UserProfileService_Social]
TO DISK = @backupFilePath
WITH NOFORMAT, NOINIT
    , NAME = N'UserProfileService_Social-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY

-- Backup content database for Web applications

SET @backupFilePath = @backupPath + N'\WSS_Content_MySites.bak'

BACKUP DATABASE [WSS_Content_MySites]
TO DISK = @backupFilePath
WITH NOFORMAT, NOINIT
    , NAME = N'WSS_Content_MySites-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY

SET @backupFilePath = @backupPath + N'\WSS_Content_Team1.bak'

BACKUP DATABASE [WSS_Content_Team1]
TO DISK = @backupFilePath
WITH NOFORMAT, NOINIT
    , NAME = N'WSS_Content_Team1-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY


SET @backupFilePath = @backupPath + N'\WSS_Content_ttweb.bak'

BACKUP DATABASE [WSS_Content_ttweb]
TO DISK = @backupFilePath
WITH NOFORMAT, NOINIT
    , NAME = N'WSS_Content_ttweb-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY
```

---

---

**TT-SQL03** - Run as administrator

```PowerShell
cls
```

#### # Copy backup files to SQL Server for SharePoint 2016 farm

```PowerShell
robocopy `
    '\\TT-FS01\Backups\HAVOK' `
    'Z:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\Full'
```

---

```PowerShell
cls
```

## # Configure service applications

### # Change service account for Distributed Cache

```PowerShell
$credential = Get-Credential "TECHTOOLBOX\s-spserviceapp"

$account = New-SPManagedAccount $credential

$farm = Get-SPFarm
$cacheService = $farm.Services | where {$_.Name -eq "AppFabricCachingService"}

$cacheService.ProcessIdentity.CurrentIdentityType = "SpecificUser"
$cacheService.ProcessIdentity.ManagedAccount = $account
$cacheService.ProcessIdentity.Update()
$cacheService.ProcessIdentity.Deploy()
```

> **Note**
>
> When prompted for the service account, specify **TECHTOOLBOX\\s-sp-serviceapp**.\
> Expect the previous operation to complete in approximately 7-8 minutes.

```PowerShell
cls
```

### # Configure State Service

```PowerShell
cd C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts

& '.\Configure State Service.ps1'
```

```PowerShell
cls
```

### # Create application pool for SharePoint service applications

```PowerShell
& '.\Configure Service Application Pool.ps1'
```

When prompted for the credentials to use for SharePoint service applications:

1. In the **User name** box, type **TECHTOOLBOX\\s-spserviceapp**.
2. In the **Password** box, type the password for the service account.

### Restore Managed Metadata Service

---

**SQL Server Management Studio** - Database Engine - **TT-SQL03**

#### -- Restore service application database from SharePoint 2013

```SQL
RESTORE DATABASE [ManagedMetadataService]
    FROM DISK = N'Z:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\Full\ManagedMetadataService.bak'
    WITH FILE = 1
    , MOVE N'ManagedMetadataService' TO N'D:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\ManagedMetadataService.mdf'
    , MOVE N'ManagedMetadataService_log' TO N'L:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Data\ManagedMetadataService_log.LDF'
    , NOUNLOAD, STATS = 5
```

---

```PowerShell
cls
```

#### # Configure the Managed Metadata Service

```PowerShell
& '.\Configure Managed Metadata Service.ps1'
```

### Restore User Profile Service

---

**SQL Server Management Studio** - Database Engine - **TT-SQL03**

#### -- Restore service application database from SharePoint 2013

```SQL
RESTORE DATABASE [UserProfileService_Profile]
    FROM DISK = N'Z:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\Full\UserProfileService_Profile.bak'
    WITH FILE = 1
    , MOVE N'ProfileDB' TO N'D:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\UserProfileService_Profile.mdf'
    , MOVE N'ProfileDB_log' TO N'L:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Data\UserProfileService_Profile_log.LDF'
    , NOUNLOAD, STATS = 5

RESTORE DATABASE [UserProfileService_Social]
    FROM DISK = N'Z:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\Full\UserProfileService_Social.bak'
    WITH FILE = 1
    , MOVE N'SocialDB' TO N'D:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\UserProfileService_Social.mdf'
    , MOVE N'SocialDB_log' TO N'L:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Data\UserProfileService_Social_log.LDF'
    , NOUNLOAD, STATS = 5
```

---

```PowerShell
cls
```

#### # Configure the User Profile Service

```PowerShell
& '.\Configure User Profile Service.ps1'
```

```PowerShell
cls
```

### # Configure User Profile Synchronization (UPS)

#### # Configure synchronization connection

```PowerShell
$cred = Get-Credential -Message "Service account for UPS" -UserName TECHTOOLBOX\s-sp-ups
$forestName = "corp.technologytoolbox.com"
$orgUnit = "DC=corp,DC=technologytoolbox,DC=com"

$userProfileServiceApp = Get-SPServiceApplication `
    -Name "User Profile Service Application"

$connectionDomain = $cred.UserName -split '\\' | select -First 1
$connectionUserName = $cred.UserName -split '\\' | select -Skip 1

Add-SPProfileSyncConnection `
    -ProfileServiceApplication $userProfileServiceApp `
    -ConnectionForestName $forestName `
    -ConnectionDomain $connectionDomain `
    -ConnectionUserName $cred.UserName `
    -ConnectionPassword $cred.Password `
    -ConnectionSynchronizationOU $orgUnit
```

```Text
Add-SPProfileSyncConnection : The supplied credential is invalid.
At line:1 char:1
+ Add-SPProfileSyncConnection `
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidData: (Microsoft.Offic...eSyncConnection:SPCmdletAddProfileSyncConnection) [Add-SPProfileSyncConnection], LdapException
    + FullyQualifiedErrorId : Microsoft.Office.Server.UserProfiles.PowerShell.SPCmdletAddProfileSyncConnection
```

**Workaround:** Configure synchronization connection using SharePoint Central Administration.

#### Import data from Active Directory

### Restore the Secure Store Service

---

**SQL Server Management Studio** - Database Engine - **TT-SQL03**

#### -- Restore service application database from SharePoint 2013

```SQL
RESTORE DATABASE [SecureStoreService]
    FROM DISK = N'Z:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\Full\SecureStoreService.bak'
    WITH FILE = 1
    , MOVE N'Secure_Store_Service_DB' TO N'D:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\SecureStoreService.mdf'
    , MOVE N'Secure_Store_Service_DB_log' TO N'L:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Data\SecureStoreService_log.ldf'
    , NOUNLOAD, STATS = 5

GO
```

#### -- Add service account to database

```SQL
USE [SecureStoreService]
GO
CREATE USER [TECHTOOLBOX\s-spserviceapp]
ALTER ROLE [SPDataAccess] ADD MEMBER [TECHTOOLBOX\s-spserviceapp]
```

---

```PowerShell
cls
```

#### # Configure the Secure Store Service

```PowerShell
Get-SPServiceInstance |
    where { $_.TypeName -eq "Secure Store Service" } |
    Start-SPServiceInstance | Out-Null

$serviceApplicationName = "Secure Store Service"

$serviceApp = New-SPSecureStoreServiceApplication `
    -Name $serviceApplicationName  `
    -ApplicationPool "SharePoint Service Applications" `
    -DatabaseName "SecureStoreService" `
    -AuditingEnabled

$proxy = New-SPSecureStoreServiceApplicationProxy  `
    -Name "$serviceApplicationName Proxy" `
    -ServiceApplication $serviceApp `
    -DefaultProxyGroup
```

```PowerShell
cls
```

#### # Add domain group to Administrators for service application

```PowerShell
$principal = New-SPClaimsPrincipal 'SharePoint Admins' `
    -IdentityType WindowsSecurityGroupName

$security = Get-SPServiceApplicationSecurity $serviceApp -Admin

Grant-SPObjectSecurity $security $principal 'Full Control'

Set-SPServiceApplicationSecurity $serviceApp $security -Admin
```

#### # Set the key for the Secure Store Service

```PowerShell
Update-SPSecureStoreApplicationServerKey `
    -ServiceApplicationProxy $proxy
```

When prompted, type the passphrase for the Secure Store Service.

```PowerShell
cls
```

### # Create and configure search service application

#### # Create the Search Service Application

```PowerShell
& '.\Configure SharePoint 2016 Search.ps1' -Verbose
```

> **Note**
>
> When prompted for the service account, specify **TECHTOOLBOX\\s-index**.\
> Expect the previous operation to complete in approximately 10-11 minutes.

```PowerShell
cls
```

#### # TODO: Configure VSS permissions for SharePoint Search

```PowerShell
$serviceAccount = "TECHTOOLBOX\s-spserviceapp"

New-ItemProperty `
    -Path HKLM:\SYSTEM\CurrentControlSet\Services\VSS\VssAccessControl `
    -Name $serviceAccount `
    -PropertyType DWord `
    -Value 1 | Out-Null

$acl = Get-Acl HKLM:\SYSTEM\CurrentControlSet\Services\VSS\Diag
$rule = New-Object System.Security.AccessControl.RegistryAccessRule(
    $serviceAccount, "FullControl", "ContainerInherit", "None", "Allow")

$acl.SetAccessRule($rule)
Set-Acl -Path HKLM:\SYSTEM\CurrentControlSet\Services\VSS\Diag -AclObject $acl
```

---

**SQL Server Management Studio** - Database Engine - **TT-SQL03**

#### -- Configure permissions on stored procedures in SharePoint_Config database

```SQL
USE [Sharepoint_Config]
GO
GRANT EXECUTE ON [dbo].[proc_GetTimerRunningJobs] TO [WSS_Content_Application_Pools]
GRANT EXECUTE ON [dbo].[proc_GetTimerJobLastRunTime] TO [WSS_Content_Application_Pools]
GRANT EXECUTE ON [dbo].[proc_putObjectTVP] TO [WSS_Content_Application_Pools]
GRANT EXECUTE ON [dbo].[proc_putObject] TO [WSS_Content_Application_Pools]
GRANT EXECUTE ON [dbo].[proc_putDependency] TO [WSS_Content_Application_Pools]
```

---

##### References

**Search account got - Insufficient sql database permissions for user. EXECUTE permission was denied on the object proc_Gettimerrunningjobs**\
From <[https://social.technet.microsoft.com/Forums/en-US/a0d08e98-1fd6-42cf-b738-6ba3df082210/search-account-got-insufficient-sql-database-permissions-for-user-execute-permission-was-denied?forum=sharepointadmin](https://social.technet.microsoft.com/Forums/en-US/a0d08e98-1fd6-42cf-b738-6ba3df082210/search-account-got-insufficient-sql-database-permissions-for-user-execute-permission-was-denied?forum=sharepointadmin)>

**Resolution of SharePoint Event ID 5214: EXECUTE permission was denied on the object ‘proc_putObjectTVP’, database ‘SharePoint_Config’**\
From <[http://sharepointpaul.blogspot.com/2013/09/resolution-of-sharepoint-event-id-5214.html](http://sharepointpaul.blogspot.com/2013/09/resolution-of-sharepoint-event-id-5214.html)>

**EXECUTE permission was denied on the object 'proc_putObjectTVP'**\
From <[https://social.technet.microsoft.com/Forums/office/en-US/88c2c219-e1b0-4ed2-807a-267dba1a2c0b/execute-permission-was-denied-on-the-object-procputobjecttvp?forum=sharepointadmin](https://social.technet.microsoft.com/Forums/office/en-US/88c2c219-e1b0-4ed2-807a-267dba1a2c0b/execute-permission-was-denied-on-the-object-procputobjecttvp?forum=sharepointadmin)>

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
$startAddress = "sps3://my"

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

```PowerShell
cls
```

## # Restore Web application - [http://ttweb](http://ttweb)

### # Create Web application

```PowerShell
$appPoolCredential = Get-Credential "TECHTOOLBOX\s-web-intranet"

$appPoolAccount = New-SPManagedAccount -Credential $appPoolCredential

$authProvider = New-SPAuthenticationProvider

New-SPWebApplication `
    -ApplicationPool "SharePoint - ttweb80" `
    -Name "SharePoint - ttweb80" `
    -ApplicationPoolAccount $appPoolAccount `
    -AuthenticationProvider $authProvider `
    -HostHeader "ttweb" `
    -Port 80
```

---

**SQL Server Management Studio** - Database Engine - **TT-SQL03**

### -- Restore content database from SharePoint 2013

```SQL
RESTORE DATABASE [WSS_Content_ttweb]
    FROM DISK = N'Z:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\Full\WSS_Content_ttweb.bak'
    WITH FILE = 1
    , MOVE N'WSS_Content_ttweb' TO N'D:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\WSS_Content_ttweb.mdf'
    , MOVE N'WSS_Content_ttweb_log' TO N'L:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Data\WSS_Content_ttweb_log.LDF'
    , NOUNLOAD, STATS = 5
```

---

```PowerShell
cls
```

### # Add content database to Web application

```PowerShell
Test-SPContentDatabase -Name WSS_Content_ttweb -WebApplication http://ttweb

Mount-SPContentDatabase -Name WSS_Content_ttweb -WebApplication http://ttweb
```

```PowerShell
cls
```

### # Remove default content database created with Web application

```PowerShell
Get-SPContentDatabase -WebApplication http://ttweb |
    where { $_.Name -ne "WSS_Content_ttweb" } |
    Remove-SPContentDatabase
```

```PowerShell
cls
```

## # Restore Web application - [http://team](http://team)

### # Create Web application

```PowerShell
$appPoolCredential = Get-Credential "TECHTOOLBOX\s-web-my-team"

$appPoolAccount = New-SPManagedAccount -Credential $appPoolCredential

$authProvider = New-SPAuthenticationProvider

New-SPWebApplication `
    -ApplicationPool "SharePoint - my-team80" `
    -Name "SharePoint - team80" `
    -ApplicationPoolAccount $appPoolAccount `
    -AuthenticationProvider $authProvider `
    -HostHeader "team" `
    -Port 80
```

---

**SQL Server Management Studio** - Database Engine - **TT-SQL03**

### -- Restore content database from SharePoint 2013

```SQL
RESTORE DATABASE [WSS_Content_Team1]
    FROM DISK = N'Z:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\Full\WSS_Content_Team1.bak'
    WITH FILE = 1
    , MOVE N'WSS_Content_Team1' TO N'D:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\WSS_Content_Team1.mdf'
    , MOVE N'WSS_Content_Team1_log' TO N'L:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Data\WSS_Content_Team1_log.LDF'
    , NOUNLOAD
    , STATS = 5
```

---

```PowerShell
cls
```

### # Add content database to Web application

```PowerShell
Test-SPContentDatabase -Name WSS_Content_Team1 -WebApplication http://team

Mount-SPContentDatabase -Name WSS_Content_Team1 -WebApplication http://team
```

```PowerShell
cls
```

### # Remove default content database created with Web application

```PowerShell
Get-SPContentDatabase -WebApplication http://team |
    where { $_.Name -ne "WSS_Content_Team1" } |
    Remove-SPContentDatabase
```

```PowerShell
cls
```

## # Restore Web application - [http://my](http://my)

### # Create Web application

```PowerShell
$appPoolAccount = Get-SPManagedAccount "TECHTOOLBOX\s-web-my-team"

$authProvider = New-SPAuthenticationProvider

New-SPWebApplication `
    -ApplicationPool "SharePoint - my-team80" `
    -Name "SharePoint - my80" `
    -AuthenticationProvider $authProvider `
    -HostHeader "my" `
    -Port 80
```

---

**SQL Server Management Studio** - Database Engine - **TT-SQL03**

### -- Restore content database from SharePoint 2013

```SQL
RESTORE DATABASE [WSS_Content_MySites1]
    FROM DISK = N'Z:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\Full\WSS_Content_MySites.bak'
    WITH FILE = 1
    , MOVE N'WSS_Content_MySites' TO N'D:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\WSS_Content_MySites1.mdf'
    , MOVE N'WSS_Content_MySites_log' TO N'L:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Data\WSS_Content_MySites1_log.LDF'
    , NOUNLOAD
    , STATS = 5
```

---

```PowerShell
cls
```

### # Add content database to Web application

```PowerShell
Test-SPContentDatabase -Name WSS_Content_MySites1 -WebApplication http://my

Mount-SPContentDatabase -Name WSS_Content_MySites1 -WebApplication http://my
```

```PowerShell
cls
```

### # Remove default content database created with Web application

```PowerShell
Get-SPContentDatabase -WebApplication http://my |
    where { $_.Name -ne "WSS_Content_MySites1" } |
    Remove-SPContentDatabase
```

```PowerShell
cls
```

### # Set My Site Host location on User Profile Service Application

```PowerShell
$serviceApp = Get-SPServiceApplication -Name "User Profile Service Application"

Set-SPProfileServiceApplication `
    -Identity $serviceApp `
    -MySiteHostLocation "http://my/" `
    -MySiteManagedPath sites
```

---

**TT-ADMIN02** - Run as administrator

```PowerShell
cls
```

## # Delete VM checkpoint - "Before SharePoint Server 2016 configuration"

```PowerShell
$vmHost = 'TT-HV05B'
$vmName = 'TT-SP01'

Stop-VM -ComputerName $vmHost -VMName $vmName

Remove-VMSnapshot `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Name 'Before SharePoint Server 2016 configuration'

# Wait a few seconds for merge to start...
Start-Sleep -Seconds 5

while (Get-VM -ComputerName $vmHost -VMName $vmName |
    Where Status -eq "Merging disks") {
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 5
}

Write-Host
Write-Host "VM checkpoint deleted"

Start-VM -ComputerName $vmHost -VMName $vmName
```

---

### Configure name resolution for SharePoint sites

---

**TT-ADMIN02** - Run as administrator

```PowerShell
cls
```

#### # Remove obsolete CName records for SharePoint sites

```PowerShell
$names = @("my", "team", "ttweb")

$names |
    foreach {
        Remove-DnsServerResourceRecord `
            -ComputerName TT-DC10 `
            -ZoneName corp.technologytoolbox.com `
            -Name $_ `
            -RRType Cname `
            -Force
    }
```

#### # Add CName records for SharePoint sites

```PowerShell
$names |
    foreach {
        Add-DnsServerResourceRecordCName `
            -ComputerName TT-DC10 `
            -ZoneName corp.technologytoolbox.com `
            -Name $_ `
            -HostNameAlias TT-SP01.corp.technologytoolbox.com
    }
```

---

```PowerShell
cls
```

### # Flush DNS cache

```PowerShell
ipconfig /flushdns
```

```PowerShell
cls
```

## # Resume Search Service Application and start full crawl on all content sources

```PowerShell
Add-PSSnapin Microsoft.SharePoint.PowerShell

Get-SPEnterpriseSearchServiceApplication |
    Resume-SPEnterpriseSearchServiceApplication

Get-SPEnterpriseSearchServiceApplication |
    Get-SPEnterpriseSearchCrawlContentSource |
    foreach { $_.StartFullCrawl() }
```

---

**TT-ADMIN02** - Run as administrator

```PowerShell
cls
```

## # Delete VM checkpoint - "Baseline"

```PowerShell
$vmHost = 'TT-HV05B'
$vmName = 'TT-SP01'

Remove-VMSnapshot `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Name 'Baseline'

# Wait a few seconds for merge to start...
Start-Sleep -Seconds 5

while (Get-VM -ComputerName $vmHost -VMName $vmName |
    Where Status -eq "Merging disks") {
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 5
}

Write-Host
Write-Host "VM checkpoint deleted"
```

---

```PowerShell
cls
```

## # Install SCOM agent

### # Install SCOM agent without Application Performance Monitoring (APM)

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\System Center 2016\SCOM\Agent\AMD64" `
    + "\MOMAgent.msi"

$installerArguments = "MANAGEMENT_GROUP=HQ" `
    + " MANAGEMENT_SERVER_DNS=TT-SCOM03" `
    + " ACTIONS_USE_COMPUTER_ACCOUNT=1" `
    + " NOAPM=1"

Start-Process `
    -FilePath msiexec.exe `
    -ArgumentList "/i `"$installerPath`" $installerArguments" `
    -Wait
```

### Approve manual agent install in Operations Manager

**TODO** - Run as administrator

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

```PowerShell
cls
```

## # Configure registry permissions to avoid errors with SharePoint timer jobs

```PowerShell
$identity = "$env:COMPUTERNAME\WSS_WPG"
$registryPath = 'HKLM:SOFTWARE\Microsoft\Office Server\16.0'

$acl = Get-Acl $registryPath
$rule = New-Object System.Security.AccessControl.RegistryAccessRule(
    $identity,
    'ReadKey',
    'ContainerInherit, ObjectInherit',
    'None',
    'Allow')

$acl.SetAccessRule($rule)
Set-Acl -Path $registryPath -AclObject $acl
```

### Reference

Source: Microsoft-SharePoint Products-SharePoint Foundation\
Event ID: 6398\
Event Category: 12\
User: TECHTOOLBOX\\s-sharepoint\
Computer: POLARIS.corp.technologytoolbox.com\
Event Description: The Execute method of job definition Microsoft.SharePoint.Publishing.Internal.PersistedNavigationTermSetSyncJobDefinition (ID ...) threw an exception. More information is included below.

Requested registry access is not allowed.

```PowerShell
cls
```

## # Install and configure Office Web Apps

### # Create the binding between SharePoint 2016 and Office Web Apps Server

```PowerShell
New-SPWOPIBinding -ServerName wac.fabrikam.com
```

```PowerShell
cls
```

### # View the WOPI zone of SharePoint 2016

```PowerShell
Get-SPWOPIZone
```

### # Change the WOPI zone if necessary

```PowerShell
Set-SPWOPIZone -zone "external-https"
```

### Configure name resolution for Office Web Apps

---

**EXT-WAC02A** - Run as administrator

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    -IPAddress 192.168.10.37 `
    -Hostnames POLARIS, my, team, ttweb
```

---

## Upgrade SharePoint after installing latest patches using Windows Update

```PowerShell
cls
Push-Location ("C:\Program Files\Common Files\microsoft shared" `
    + "\Web Server Extensions\16\BIN")

.\PSConfig.exe `
    -cmd upgrade -inplace b2b `
    -wait `
    -cmd applicationcontent -install `
    -cmd installfeatures `
    -cmd secureresources `
    -cmd services -install

Pop-Location
```

### Reference

**Why I prefer PSCONFIGUI.EXE over PSCONFIG.EXE**\
From <[https://blogs.technet.microsoft.com/stefan_gossner/2015/08/20/why-i-prefer-psconfigui-exe-over-psconfig-exe/](https://blogs.technet.microsoft.com/stefan_gossner/2015/08/20/why-i-prefer-psconfigui-exe-over-psconfig-exe/)>

## Upgrade to Operations Manager 2019

```PowerShell
cls
```

### # Remove SCOM 2016 agent

```PowerShell
msiexec /x `{742D699D-56EB-49CC-A04A-317DE01F31CD`}
```

### # Install SCOM agent

```PowerShell
$msiPath = "\\TT-FS01\Products\Microsoft\System Center 2019\SCOM\agent\AMD64" `
    + "\MOMAgent.msi"

msiexec.exe /i $msiPath `
    MANAGEMENT_GROUP=HQ `
    MANAGEMENT_SERVER_DNS=TT-SCOM01C `
    ACTIONS_USE_COMPUTER_ACCOUNT=1
```

### Approve manual agent install in Operations Manager

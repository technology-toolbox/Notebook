# EXT-FOOBAR4 - Windows Server 2012 R2 Standard

Sunday, February 08, 2015
5:27 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

### Install Windows Server 2012

---

**WOLVERINE**

#### Clone VM (WS2012-R2-STD)

---

#### Configure server settings

On the **Settings** page:

1. Ensure the following default values are selected:
   1. **Country or region: United States**
   2. **App language: English (United States)**
   3. **Keyboard layout: US**
2. Click **Next**.
3. Type the product key and then click **Next**.
4. Review the software license terms and then click **I accept**.
5. Type a password for the built-in administrator account and then click **Finish**.

#### # Rename the server and join domain

```PowerShell
Rename-Computer -NewName EXT-FOOBAR4 -Restart
```

Wait for the VM to restart and then execute the following command to join the **EXTRANET** domain:

```PowerShell
Add-Computer -DomainName extranet.technologytoolbox.com -Restart
```

#### # Rename network connection

```PowerShell
Get-NetAdapter -InterfaceDescription "Intel(R) PRO/1000 MT Desktop Adapter" |
    Rename-NetAdapter -NewName "LAN 1 - 192.168.10.x"
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name "LAN 1 - 192.168.10.x" `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping ICEMAN.corp.technologytoolbox.com -f -l 8900
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
$ipAddress = "2601:1:8200:6000::218"

New-NetIPAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -IPAddress $ipAddress `
    -PrefixLength 64

Set-DNSClientServerAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -ServerAddresses 2601:1:8200:6000::209,2601:1:8200:6000::210
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

### Configure VM storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 50 GB       | 4K                   |              |
| 1    | D:           | 3 GB        | 64K                  | Data01       |
| 2    | L:           | 1 GB        | 64K                  | Log01        |
| 3    | T:           | 1 GB        | 64K                  | Temp01       |
| 4    | Z:           | 10 GB       | 4K                   | Backup01     |

---

**WOLVERINE**

#### REM Expand primary VHD for virtual machine

```Console
cd C:\NotBackedUp\VMs\Development\EXT-FOOBAR4

"C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyhd EXT-FOOBAR4.vdi --resize 51200
```

**Note:** 50 GB = 51200 MB

#### Create Data01, Log01, Temp01, and Backup01 VHDs

---

#### # Expand C: partition

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

### Set MaxPatchCacheSize to 0 (Recommended)

### DEV - Install Visual Studio 2013 with Update 4

```PowerShell
cls
```

#### # Install .NET Framework 3.5

```PowerShell
# net use \\iceman\ipc$ /USER:TECHTOOLBOX\jjameson
# $sourcePath = "\\ICEMAN\Products\Microsoft\Windows Server 2012 R2\Sources\SxS"

$sourcePath = "X:\sources\sxs"

Install-WindowsFeature NET-Framework-Core -Source $sourcePath
```

### DEV - Install update for Office developer tools in Visual Studio

### DEV - Install update for SQL Server database projects in Visual Studio

### DEV - Install Productivity Power Tools for Visual Studio

### TODO: DEV - Install TFS Power Tools

### Install SQL Server 2014

...\
Restart the server

### DEV - Change databases to Simple recovery model

### DEV - Constrain maximum memory for SQL Server

### DEV - Configure TempDB data files

### Configure "Max Degree of Parallelism" for SharePoint

### Configure permissions on \\Windows\\System32\\LogFiles\\Sum files

### TODO: Install Prince on front-end Web servers

### DEV - Install Microsoft Office 2013 with SP1

### DEV - Install Microsoft SharePoint Designer 2013 with SP1

### DEV - Install Microsoft Visio 2013 with SP1

### DEV - Install additional browsers and software

### Install additional service packs and updates

- 65 important updates available
- ~1.8 GB
- Approximate time: 19 minutes (3:05 PM - 3:24 PM) - VirtualBox on WOLVERINE

### # Delete C:\\Windows\\SoftwareDistribution folder (1.78 GB)

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse

Restart-Computer
```

### Check for updates using Windows Update (after removing patches folder)

- **Most recent check for updates: Never -> Most recent check for updates: Today at 8:45 AM**
- C:\\Windows\\SoftwareDistribution folder is now 43 MB

### Clean up the WinSxS folder

```Console
Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase
```

## Install and configure SharePoint Server 2013

**Note:** Insert the SharePoint 2013 installation media into the DVD drive for the SharePoint VM

### # Install SharePoint 2013 prerequisites on the farm servers

```PowerShell
$preReqPath = `
    "\\ICEMAN\Products\Microsoft\SharePoint 2013\PrerequisiteInstallerFiles_SP1"

& X:\PrerequisiteInstaller.exe `
    /SQLNCli:"$preReqPath\sqlncli.msi" `
    /PowerShell:"$preReqPath\Windows6.1-KB2506143-x64.msu" `
    /NETFX:"$preReqPath\dotNetFx45_Full_setup.exe" `
    /IDFX:"$preReqPath\Windows6.1-KB974405-x64.msu" `
    /Sync:"$preReqPath\Synchronization.msi" `
    /AppFabric:"$preReqPath\WindowsServerAppFabricSetup_x64.exe" `
    /IDFX11:"$preReqPath\MicrosoftIdentityExtensions-64.msi" `
    /MSIPCClient:"$preReqPath\setup_msipc_x64.msi" `
    /WCFDataServices:"$preReqPath\WcfDataServices.exe" `
    /KB2671763:"$preReqPath\AppFabric1.1-RTM-KB2671763-x64-ENU.exe" `
    /WCFDataServices56:"$preReqPath\WcfDataServices-5.6.exe"
```

### Install SharePoint Server 2013 on the farm servers

### Install Cumulative Update for SharePoint Server 2013

```PowerShell
cls
```

### # Add the SharePoint bin folder to the PATH environment variable

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-PathFolders.ps1 "C:\Program Files\Common Files\Microsoft Shared\web server extensions\15\BIN" -EnvironmentVariableTarget "Machine"
```

> **Important**
>
> Restart PowerShell for environment variable change to take effect.

### Copy SecuritasConnect build to SharePoint server

**Note:** Open elevated Visual Studio 2013 command prompt

```Console
mkdir C:\NotBackedUp\Securitas
tf workfold /decloak "$/Securitas ClientPortal/Dev/Lab2"
tf get C:\NotBackedUp\Securitas\ClientPortal\Dev\Lab2 /recursive /force
tf get "$/Securitas ClientPortal/Main/Code/Securitas.Portal.ruleset" /force
cd C:\NotBackedUp\Securitas\ClientPortal\Dev\Lab2\Code
msbuild SecuritasClientPortal.sln /p:IsPackaging=true
```

### Set variables for automated installation

**Note:** Open elevated PowerShell

```PowerShell
$farmCred = Get-Credential `
    -UserName EXTRANET\s-spfarm-dev `
    -Message "Type the user name and password for the SharePoint farm account."

$servicesCred = Get-Credential `
    -UserName EXTRANET\s-spserviceapp-dev `
    -Message ("Type the user name and password for SharePoint services" `
        + " and service applications.")

$crawlCred = Get-Credential `
    -UserName EXTRANET\s-index-dev `
    -Message "Type the user name and password for indexing content."

$passphrase = Read-Host -Prompt "Passphrase" -AsSecureString

$DebugPreference = "Continue"
```

```PowerShell
cls
```

### # Initialize the farm

```PowerShell
cd C:\NotBackedUp\Securitas\ClientPortal\Dev\Lab2\Code\DeploymentFiles\Scripts

& '.\Initialize Farm.ps1' `
    -FarmCredential $farmCred `
    -ServicesCredential $servicesCred `
    -CrawlCredential $crawlCred `
    -Passphrase $passphrase `
    -Verbose
```

### # TODO: DEV - Configure timer job history

## # Configure service applications

### # Configure the User Profile Service Application

#### # Disable social features

#### # TODO: Disable newsfeed

## # TODO: Install and configure Office Web Apps

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

```PowerShell
cd C:\NotBackedUp\Securitas\ClientPortal\Dev\Lab2\Code\DeploymentFiles\Scripts

$DebugPreference = "Continue"
```

```PowerShell
cls
```

### # Create the Web application and initial site collections

```PowerShell
& '.\Create Web Application.ps1'

& '.\Create Site Collections.ps1'
```

### # Configure machine key for Web application

```PowerShell
& '.\Configure Machine Key.ps1'
```

### # Configure object cache user accounts

```PowerShell
& '.\Configure Object Cache User Accounts.ps1'
```

### REM Configure the People Picker to support searches across one-way trust

#### REM Set the application password used for encrypting credentials

```Console
stsadm -o setapppassword -password {Key}
```

#### REM Specify the credentials for accessing the trusted forest

```Console
stsadm -o setproperty -pn peoplepicker-searchadforests -pv "domain:extranet.technologytoolbox.com,EXTRANET\svc-web-sec-2010-dev,{password};domain:corp.technologytoolbox.com,TECHTOOLBOX\svc-web-sec-2010-dev,{password}" -url http://client-local.securitasinc.com
```

#### # Modify the permissions on the registry key where the encrypted credentials are stored

```PowerShell
$registryPath = `
    "HKLM:\SOFTWARE\Microsoft\Shared Tools\Web Server Extensions\15.0\Secure"

$acl = Get-Acl $registryPath

$rule = New-Object System.Security.AccessControl.RegistryAccessRule(
     "$env:COMPUTERNAME\WSS_WPG", "ReadKey", "Allow")

$acl.SetAccessRule($rule)

Set-Acl -Path $registryPath -AclObject $acl
```

{bunch o' stuff skipped here}

## Deploy the SecuritasConnect solution

### DEV - Build Visual Studio solution and package SharePoint projects

```Console
cd C:\NotBackedUp\Securitas\ClientPortal\Dev\Lab2\Code
msbuild SecuritasClientPortal.sln /p:IsPackaging=true
```

### # Create and configure the SecuritasPortal database

```PowerShell
$sqlcmd = @"
```

#### -- Restore backup of SecuritasPortal database

```Console
DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\'
    + 'SecuritasPortal-EXT-FOOBAR2.bak'

DECLARE @dataFilePath VARCHAR(255) =
  'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'SecuritasPortal.mdf'

DECLARE @logFilePath VARCHAR(255) =
  'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'SecuritasPortal.LDF'

RESTORE DATABASE SecuritasPortal
  FROM DISK = @backupFilePath
  WITH FILE = 1,
    MOVE 'SecuritasPortal' TO @dataFilePath,
    MOVE 'SecuritasPortal_log' TO @logFilePath,
    NOUNLOAD,
    STATS = 5
```

GO

#### -- Configure permissions for the SecuritasPortal database

```SQL
USE [SecuritasPortal]
GO

ALTER ROLE [aspnet_Membership_BasicAccess] ADD MEMBER [EXTRANET\svc-sharepoint-dev]
GO
ALTER ROLE [aspnet_Membership_ReportingAccess] ADD MEMBER [EXTRANET\svc-sharepoint-dev]
GO
ALTER ROLE [aspnet_Roles_BasicAccess] ADD MEMBER [EXTRANET\svc-sharepoint-dev]
GO
ALTER ROLE [aspnet_Roles_ReportingAccess] ADD MEMBER [EXTRANET\svc-sharepoint-dev]
GO

ALTER ROLE [aspnet_Membership_FullAccess] ADD MEMBER [EXTRANET\svc-web-sec-2010-dev]
GO
ALTER ROLE [aspnet_Profile_BasicAccess] ADD MEMBER [EXTRANET\svc-web-sec-2010-dev]
GO
ALTER ROLE [aspnet_Roles_BasicAccess] ADD MEMBER [EXTRANET\svc-web-sec-2010-dev]
GO
ALTER ROLE [aspnet_Roles_ReportingAccess] ADD MEMBER [EXTRANET\svc-web-sec-2010-dev]
GO
ALTER ROLE [Customer_Reader] ADD MEMBER [EXTRANET\svc-web-sec-2010-dev]
GO
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

### # Configure logging

```PowerShell
& '.\Add Event Log Sources.ps1'
```

### # Configure claims-based authentication

```PowerShell
$path = `
    ("C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions" `
        + "\15\WebServices\SecurityToken")

Copy-Item "$path\web.config" "$path\web - Copy.config"

Notepad "$path\web.config"
```

**{copy/paste Web.config entries from browser -- to avoid issue when copy/pasting from OneNote}**

### # Install SecuritasConnect solutions and activate the features

```PowerShell
& '.\Add Solutions.ps1'

& '.\Deploy Solutions.ps1'

& '.\Activate Features.ps1'
```

#### Activate the "Securitas - Application Settings" feature

```PowerShell
cls
```

### # Restore content database

#### # Remove the default content database created with the Web application

```PowerShell
Remove-SPContentDatabase WSS_Content_SecuritasPortal
```

#### -- Restore the backup of the content database

```Console
DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\'
    + 'WSS_Content_SecuritasPortal.bak'

DECLARE @dataFilePath VARCHAR(255) =
  'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'WSS_Content_SecuritasPortal.mdf'

DECLARE @logFilePath VARCHAR(255) =
  'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'WSS_Content_SecuritasPortal.LDF'

RESTORE DATABASE WSS_Content_SecuritasPortal
  FROM DISK = @backupFilePath
  WITH FILE = 1,
    MOVE 'WSS_Content_SecuritasPortal' TO @dataFilePath,
    MOVE 'WSS_Content_SecuritasPortal_log' TO @logFilePath,
    NOUNLOAD,
    STATS = 5
```

#### # Attach content database to Web application

```PowerShell
Test-SPContentDatabase `
    -Name WSS_Content_SecuritasPortal `
    -WebApplication http://client-local.securitasinc.com

Mount-SPContentDatabase -Name WSS_Content_MySites -WebApplication http://my-dev
```

### # Import template site content

```PowerShell
& '.\Import Template Site Content.ps1'
```

### Create users in the SecuritasPortal database

### # Configure trusted root authorities in SharePoint

```PowerShell
& '.\Configure Trusted Root Authorities.ps1'
```

## # Start full crawl

```PowerShell
Get-SPEnterpriseSearchServiceApplication |
    Get-SPEnterpriseSearchCrawlContentSource |
    % { $_.StartFullCrawl() }
```

---

reset

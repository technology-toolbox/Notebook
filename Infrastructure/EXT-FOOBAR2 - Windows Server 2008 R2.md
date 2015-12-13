# EXT-FOOBAR2 - Windows Server 2008 R2 Standard

Wednesday, April 29, 2015
9:33 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

### Install Windows Server 2008

#### Create VM

- Processors: **4**
- Memory: **8192 MB**
- VDI size: **35 GB**

#### Configure VM settings

- General
  - Advanced
    - Shared Clipboard:** Bidirectional**
- System
  - Processor
    - Processor(s): **4**
- Network
  - Adapter 1
    - Attached to:** Bridged adapter**

#### Install custom Windows Server 2008 R2 image

- Start-up disk: [\\\\ICEMAN\\Products\\Microsoft\\MDT-Deploy-x86.iso](\\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso)
- On the **Task Sequence** step, select **Windows Server 2008 R2** and click **Next**.
- On the **Computer Details** step, in the **Computer name** box, type **EXT-FOOBAR2** and click **Next**.
- On the Applications step, click **Next**.

#### Install VirtualBox Guest Additions

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

#### # Set password for local Administrator account

```PowerShell
$adminUser = [ADSI] "WinNT://./Administrator,User"
$adminUser.SetPassword("{password}")
```

#### Rename network connection

"Local Area Connection" -> "LAN 1 - 192.168.10.x"

#### Enable jumbo frames

![(screenshot)](https://assets.technologytoolbox.com/screenshots/30/627387A552E5A1C4E5B253696DFD0AF44E76F530.png)

```Console
ping ICEMAN.corp.technologytoolbox.com -f -l 8900
```

#### Configure static IPv4 address

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B1/27EDED6A67DA9043BCD77EA71B861AE5F460D1B1.png)

#### Configure static IPv6 address

![(screenshot)](https://assets.technologytoolbox.com/screenshots/06/25889C9CFFD2BFC09A990EC8C3847A8559396106.png)

### Configure VM storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 35 GB       | 4K                   |              |
| 1    | D:           | 1 GB        | 64K                  | Data01       |
| 2    | L:           | 500 MB      | 64K                  | Log01        |

### Set MaxPatchCacheSize to 0 (Recommended)

```Console
reg add HKLM\Software\Policies\Microsoft\Windows\Installer /v MaxPatchCacheSize /t REG_DWORD /d 0 /f
```

### DEV - Install Windows PowerShell Integrated Scripting Environment

### DEV - Install Visual Studio 2010

### DEV - Install latest service pack for Visual Studio 2010

### DEV - Install TFS Power Tools

### Install SQL Server 2008

### Install latest service pack for SQL Server 2008

### DEV - Change databases to Simple recovery model

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

### Install Prince on front-end Web servers

### DEV - Install Microsoft Office 2010 (Recommended)

### DEV - Install Microsoft SharePoint Designer 2010 (Recommended)

### DEV - Install Microsoft Visio 2010 (Recommended)

### Install additional service packs and updates

### DEV - Install additional browsers and software (Recommended)

## # Delete Windows Update files (1.4 GB)

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse
```

## # Configure paging file

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3D/65A59940B553562ECE63D0A02BE1F2B3503BFC3D.png)

## Install Internet Explorer 10

## # Delete Windows Update files (470 MB)

```PowerShell
net stop wuauserv
Remove-Item C:\Windows\SoftwareDistribution -Recurse
```

## Install and configure SharePoint Server 2010

### Prepare the farm servers

### Install SharePoint Server 2010 on the farm servers

### Copy SecuritasConnect build to SharePoint server

```Console
net use \\ICEMAN\ipc$ /USER:TECHTOOLBOX\jjameson

robocopy "\\ICEMAN\Builds\Securitas\ClientPortal\3.0.632.0" C:\NotBackedUp\Builds\Securitas\ClientPortal\3.0.632.0 /E
```

### Create and configure the farm

```Console
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\3.0.632.0\DeploymentFiles\Scripts

.\CreateSharePointFarm.ps1 -FarmName Securitas_CP
```

### Add SharePoint Central Administration to the "Local intranet" zone

### # Add the SharePoint bin folder to the PATH environment variable

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-PathFolders.ps1 "C:\Program Files\Common Files\Microsoft Shared\web server extensions\14\BIN" -EnvironmentVariableTarget "Machine"
```

### Grant DCOM permissions on IIS WAMREG admin Service

### # Rename TaxonomyPicker.ascx

```PowerShell
ren "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\14\TEMPLATE\CONTROLTEMPLATES\TaxonomyPicker.ascx" TaxonomyPicker.ascx_broken
```

```PowerShell
cls
```

### # Configure e-mail services

```PowerShell

$smtpServer = "smtp.technologytoolbox.com"
$fromAddress = "svc-sharepoint-dev@technologytoolbox.com"
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

### DEV - Configure timer job history

### Install cumulative update for SharePoint Server 2010

#### Install updates

#### Upgrade the SharePoint farm

## Install and configure Office Web Apps

### Install Office Web Apps

### Install Service Pack 2 for Office Web Apps

### Run PSConfig to register Office Web Apps services

## Configure service applications

### Create and configure SharePoint service applications

### Configure diagnostic logging and usage and health data collection

### # Create and configure the Search service application

```PowerShell
.\ConfigServiceApp_Search.ps1 -FarmName Securitas_CP
```

### Configure the search crawl schedules

### # Start SharePoint services

.\\ConfigureServicesOnServer.ps1 -server EXT-FOOBAR2 -role Single

### Create and configure the User Profile service application

#### Create the User Profile service application

#### Disable social features

#### Disable newsfeed

## Create and configure the Web application

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

### Add the URL for the SecuritasConnect Web site to the "Local intranet" zone

### DEV - Snapshot VM

## Create and configure the Web application

### # Create the Web application and initial site collections

```PowerShell
& '.\Create Web Application.ps1'

& '.\Create Site Collections.ps1'
```

```PowerShell
cls
```

### # Configure machine key for Web application

```PowerShell
& '.\Configure Machine Key.ps1'
```

```PowerShell
cls
```

### # Configure object cache user accounts

```PowerShell
& '.\Configure Object Cache User Accounts.ps1'

iisreset
```

### REM Configure the People Picker to support searches across one-way trust

#### REM Set the application password used for encrypting credentials

```Console
stsadm -o setapppassword -password {Key}
```

#### REM Specify the credentials for accessing the trusted forest

```Console
stsadm -o setproperty -pn peoplepicker-searchadforests -pv "domain:extranet.technologytoolbox.com,EXTRANET\svc-web-sec-2010-dev,{password};domain:corp.fabrikam.com,FABRIKAM\svc-web-sec-2010-dev,{password};domain:corp.technologytoolbox.com,TECHTOOLBOX\svc-web-sec-2010-dev,{password}" -url http://client-local.securitasinc.com
```

#### Modify the permissions on the registry key where the encrypted credentials are stored

```PowerShell
cls
```

### # Configure the Office Web Apps cache

```PowerShell
& '.\Configure Office Web Apps Cache.ps1'

iisreset
```

```PowerShell
cls
```

### # Grant access to the Web application content database for Office Web Apps

```PowerShell
$webApp = Get-SPWebApplication -Identity "http://client-local.securitasinc.com"

$webApp.GrantAccessToProcessIdentity("EXTRANET\svc-spserviceapp-dev")
```

### Configure SharePoint groups

### Configure My Site settings in User Profile service application

## Deploy the SecuritasConnect solution

### Create and configure the SecuritasPortal database

#### Create the SecuritasPortal database (or restore a backup)

```SQL
RESTORE DATABASE [SecuritasPortal]
FROM DISK = N'C:\NotBackedUp\Temp\SecuritasPortal.bak'
    WITH FILE = 1
    , MOVE N'SecuritasPortal' TO N'D:\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\SecuritasPortal.mdf'
    , MOVE N'SecuritasPortal_log' TO N'L:\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Data\SecuritasPortal_1.LDF'
    , NOUNLOAD
    , STATS = 10
GO

USE [SecuritasPortal]
GO

IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'SEC\svc-sharepoint-2010')
DROP USER [SEC\svc-sharepoint-2010]

IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'sec\svc-sharepoint-qa')
DROP USER [sec\svc-sharepoint-qa]

IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'SEC\svc-SP-2010-qa')
DROP USER [SEC\svc-SP-2010-qa]

IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'sec\svc-web-sec-2010-qa')
DROP USER [sec\svc-web-sec-2010-qa]

IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'SEC\svc-web-securitas')
DROP USER [SEC\svc-web-securitas]

IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'SEC\svc-web-securitas-20')
DROP USER [SEC\svc-web-securitas-20]

IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'sec\svc-web-securitas-qa')
DROP USER [sec\svc-web-securitas-qa]
```

#### Configure permissions for the SecuritasPortal database

```SQL
-- Configure permissions for the SecuritasPortal database

USE [SecuritasPortal]
GO

CREATE USER [EXTRANET\svc-sharepoint-dev] FOR LOGIN [EXTRANET\svc-sharepoint-dev]
GO
EXEC sp_addrolemember N'aspnet_Membership_BasicAccess', N'EXTRANET\svc-sharepoint-dev'
GO
EXEC sp_addrolemember N'aspnet_Membership_ReportingAccess', N'EXTRANET\svc-sharepoint-dev'
GO
EXEC sp_addrolemember N'aspnet_Roles_BasicAccess', N'EXTRANET\svc-sharepoint-dev'
GO
EXEC sp_addrolemember N'aspnet_Roles_ReportingAccess', N'EXTRANET\svc-sharepoint-dev'
GO

CREATE USER [EXTRANET\svc-web-sec-2010-dev] FOR LOGIN [EXTRANET\svc-web-sec-2010-dev]
GO
EXEC sp_addrolemember N'aspnet_Membership_FullAccess', N'EXTRANET\svc-web-sec-2010-dev'
GO
EXEC sp_addrolemember N'aspnet_Profile_BasicAccess', N'EXTRANET\svc-web-sec-2010-dev'
GO
EXEC sp_addrolemember N'aspnet_Roles_BasicAccess', N'EXTRANET\svc-web-sec-2010-dev'
GO
EXEC sp_addrolemember N'aspnet_Roles_ReportingAccess', N'EXTRANET\svc-web-sec-2010-dev'
GO
EXEC sp_addrolemember N'Customer_Reader', N'EXTRANET\svc-web-sec-2010-dev'
GO
```

#### -- Associate users to TECHTOOLBOX\\smasters

```Console
INSERT INTO Customer.BranchManagerAssociatedUsers
SELECT 'TECHTOOLBOX\smasters', AssociatedUserName
FROM Customer.BranchManagerAssociatedUsers
WHERE BranchManagerUserName = 'PNKUS\jjameson'
```

```Console
cls
```

### # Configure logging

```PowerShell
& '.\Add Event Log Sources.ps1'
```

```PowerShell
cls
```

### # Configure claims-based authentication

```PowerShell
Notepad "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\14\WebServices\SecurityToken\web.config"
```

**{copy/paste Web.config entries from browser -- to avoid issue when copy/pasting from OneNote}**

```PowerShell
cls
```

### # Install SecuritasConnect solutions and activate the features

```PowerShell
& '.\Add Solutions.ps1'

& '.\Deploy Solutions.ps1'

& '.\Activate Features.ps1'

Activating feature (Securitas.Portal.Web_PublicSiteConfiguration) on site (http://client-local.securitasinc.com/)...
Enable-SPFeature : Cannot import this web part.
At C:\NotBackedUp\Builds\Securitas\ClientPortal\3.0.632.0\DeploymentFiles\Scripts\Activate Features.ps1:95 char:21
+     Enable-SPFeature <<<<  $featureName -Url $siteUrl `
    + CategoryInfo          : InvalidData: (Microsoft.Share...etEnableFeature:SPCmdletEnableFeature) [Enable-SPFeature
   ], WebPartPageUserException
    + FullyQualifiedErrorId : Microsoft.SharePoint.PowerShell.SPCmdletEnableFeature
```

```PowerShell
cls
```

#### # Remove default content database created with Web application

```PowerShell
Get-SPContentDatabase WSS_Content_SecuritasPortal | Remove-SPContentDatabase
```

#### Restore content database from FOOBAR9

```SQL
RESTORE DATABASE [WSS_Content_SecuritasPortal]
    FROM DISK = N'C:\NotBackedUp\Temp\WSS_Content_SecuritasPortal.bak'
    WITH FILE = 1
    , MOVE N'WSS_Content_SecuritasPortal' TO N'D:\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\WSS_Content_SecuritasPortal.mdf'
    , MOVE N'WSS_Content_SecuritasPortal_log' TO N'L:\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Data\WSS_Content_SecuritasPortal_1.LDF'
    , NOUNLOAD
    , STATS = 10
GO

USE [WSS_Content_SecuritasPortal]
GO

IF  EXISTS (SELECT * FROM sys.schemas WHERE name = N'TECHTOOLBOX\svc-sharepoint-dev')
DROP SCHEMA [TECHTOOLBOX\svc-sharepoint-dev]

IF  EXISTS (SELECT * FROM sys.schemas WHERE name = N'TECHTOOLBOX\svc-web-sec-2010-dev')
DROP SCHEMA [TECHTOOLBOX\svc-web-sec-2010-dev]

IF  EXISTS (SELECT * FROM sys.schemas WHERE name = N'TECHTOOLBOX\svc-web-securitasdev')
DROP SCHEMA [TECHTOOLBOX\svc-web-securitasdev]

IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'TECHTOOLBOX\svc-sharepoint-dev')
DROP USER [TECHTOOLBOX\svc-sharepoint-dev]

IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'TECHTOOLBOX\svc-web-sec-2010-dev')
DROP USER [TECHTOOLBOX\svc-web-sec-2010-dev]

IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'TECHTOOLBOX\svc-web-securitasdev')
DROP USER [TECHTOOLBOX\svc-web-securitasdev]
```

#### # Add content database to Web application

```PowerShell
Test-SPContentDatabase -Name WSS_Content_SecuritasPortal `
    -WebApplication http://client-local.securitasinc.com

Mount-SPContentDatabase -Name WSS_Content_SecuritasPortal `
    -WebApplication http://client-local.securitasinc.com
```

\$webApp = Get-SPWebApplication "[http://client-local.securitasinc.com](http://client-local.securitasinc.com)"

\$webApp.GrantAccessToProcessIdentity("EXTRANET\\svc-spserviceapp-dev")

#### # Change site collection owners

```PowerShell
$claim = New-SPClaimsPrincipal -Identity "EXTRANET\jjameson-admin" `
    -IdentityType WindowsSamAccountName

$encodedClaim = $claim.ToEncodedString()

Set-SPSite http://client-local.securitasinc.com/ -OwnerAlias $encodedClaim

Set-SPSite http://client-local.securitasinc.com/sites/ABC-Company `
    -OwnerAlias $encodedClaim

Set-SPSite http://client-local.securitasinc.com/sites/cc `
    -OwnerAlias $encodedClaim

Set-SPSite http://client-local.securitasinc.com/sites/my `
    -OwnerAlias $encodedClaim

Set-SPSite http://client-local.securitasinc.com/sites/Search `
    -OwnerAlias $encodedClaim

Set-SPSite http://client-local.securitasinc.com/sites/TE-Connectivity `
    -OwnerAlias $encodedClaim
```

```PowerShell
cls
```

### # Configure C&C landing site

```PowerShell
$site = Get-SPSite "http://client-local.securitasinc.com/sites/cc"
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

## Resolve issues with PowerPoint service application

### Issue 1: Service application proxy not added to default group

Delete proxy, then create a new one

```PowerShell
Get-SPPowerPointServiceApplication |
    New-SPPowerPointServiceApplicationProxy -Name "PowerPoint Service Application Proxy" `
        -AddToDefaultGroup
```

### Issue 2: Service not started

```PowerShell
Get-SPServiceInstance |
    Where-Object { $_.TypeName -eq "PowerPoint Service" } |
    Start-SPServiceInstance | Out-Null
```

```PowerShell
cls
```

## # Create and configure the "Cloud Portal" Web application

### # Set environment variables

```PowerShell
[Environment]::SetEnvironmentVariable(
    "SECURITAS_CLOUD_PORTAL_URL",
    "http://cloud-local.securitasinc.com",
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
cls
```

### # Copy Securitas Cloud Portal build to SharePoint server

```PowerShell
net use \\ICEMAN\ipc$ /USER:TECHTOOLBOX\jjameson

robocopy \\ICEMAN\Builds\Securitas\CloudPortal\1.0.90.0 C:\NotBackedUp\Builds\Securitas\CloudPortal\1.0.90.0 /E
```

```PowerShell
cls
```

## # Create and configure the Web application

### # Create the Web application and initial site collections

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\CloudPortal\1.0.90.0\DeploymentFiles\Scripts

& '.\Create Web Application.ps1'

& '.\Create Site Collections.ps1'
```

```PowerShell
cls
```

### # Configure object cache user accounts

```PowerShell
& '.\Configure Object Cache User Accounts.ps1'

iisreset
```

### REM Configure the People Picker to support searches across one-way trust

#### REM Specify the credentials for accessing the trusted forest

```Console
stsadm -o setproperty -pn peoplepicker-searchadforests -pv "domain:extranet.technologytoolbox.com,EXTRANET\svc-web-securitasdev,{password};domain:corp.fabrikam.com,FABRIKAM\svc-web-securitasdev,{password};domain:corp.technologytoolbox.com,TECHTOOLBOX\svc-web-securitasdev,{password}" -url http://cloud-local.securitasinc.com
```

```Console
cls
```

### # Enable anonymous access to the site

```PowerShell
& '.\Enable Anonymous Access.ps1'
```

```PowerShell
cls
```

### # Configure claims-based authentication

#### # Add Web.config modifications for claims-based authentication

```PowerShell
copy C:\inetpub\wwwroot\wss\VirtualDirectories\cloud-local.securitasinc.com80\web.config "C:\inetpub\wwwroot\wss\VirtualDirectories\cloud-local.securitasinc.com80\Web - Copy.config"

Notepad C:\inetpub\wwwroot\wss\VirtualDirectories\cloud-local.securitasinc.com80\web.config
```

**{copy/paste Web.config entries from Word -- to avoid issue when copy/pasting from OneNote}**

```PowerShell
cls
```

### # Configure the Office Web Apps cache

```PowerShell
& '.\Configure Office Web Apps Cache.ps1'

iisreset
```

### Configure SharePoint groups

```PowerShell
cls
```

## # Deploy the Securitas Cloud Portal solution

```PowerShell
cls
```

### # Configure logging

```PowerShell
& '.\Add Event Log Sources.ps1'
```

```PowerShell
cls
```

### # Install Securitas Cloud Portal solutions and activate the features

```PowerShell
& '.\Add Solutions.ps1'

& '.\Deploy Solutions.ps1'

& '.\Activate Features.ps1'
```

```PowerShell
cls
```

## # Restore content database from FOOBAR9

```PowerShell
cls
```

#### # Remove default content database created with Web application

```PowerShell
Get-SPContentDatabase WSS_Content_CloudPortal | Remove-SPContentDatabase
```

#### -- Restore content database

```Console
RESTORE DATABASE [WSS_Content_CloudPortal]
    FROM DISK = N'C:\NotBackedUp\Temp\WSS_Content_CloudPortal.bak'
    WITH FILE = 1
    , MOVE N'WSS_Content_CloudPortal' TO N'D:\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\WSS_Content_CloudPortal.mdf'
    , MOVE N'WSS_Content_CloudPortal_log' TO N'L:\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Data\WSS_Content_CloudPortal_1.LDF'
    , NOUNLOAD
    , STATS = 10
GO

USE [WSS_Content_CloudPortal]
GO

IF  EXISTS (SELECT * FROM sys.schemas WHERE name = N'TECHTOOLBOX\svc-sharepoint-dev')
DROP SCHEMA [TECHTOOLBOX\svc-sharepoint-dev]

IF  EXISTS (SELECT * FROM sys.schemas WHERE name = N'TECHTOOLBOX\svc-web-securitasdev')
DROP SCHEMA [TECHTOOLBOX\svc-web-securitasdev]

IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'TECHTOOLBOX\svc-sharepoint-dev')
DROP USER [TECHTOOLBOX\svc-sharepoint-dev]

IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'TECHTOOLBOX\svc-web-securitasdev')
DROP USER [TECHTOOLBOX\svc-web-securitasdev]
```

```Console
cls
```

#### # Add content database to Web application

```PowerShell
Test-SPContentDatabase -Name WSS_Content_CloudPortal `
    -WebApplication http://cloud-local.securitasinc.com

Mount-SPContentDatabase -Name WSS_Content_CloudPortal `
    -WebApplication http://cloud-local.securitasinc.com
```

#### # Grant access to the Web application content database for Office Web Apps

```PowerShell
$webApp = Get-SPWebApplication "http://cloud-local.securitasinc.com"

$webApp.GrantAccessToProcessIdentity("EXTRANET\svc-spserviceapp-dev")
```

#### # Change site collection owners

```PowerShell
$claim = New-SPClaimsPrincipal -Identity "EXTRANET\jjameson-admin" `
    -IdentityType WindowsSamAccountName

$encodedClaim = $claim.ToEncodedString()

Set-SPSite http://cloud-local.securitasinc.com/ -OwnerAlias $encodedClaim

Set-SPSite http://cloud-local.securitasinc.com/sites/Fabrikam-Shipping `
    -OwnerAlias $encodedClaim

Set-SPSite http://cloud-local.securitasinc.com/sites/Online-Provisioning `
    -OwnerAlias $encodedClaim
```

### Configure custom sign-in page

#### Configure permissions for the SecuritasPortal database

## -- Configure permissions for the SecuritasPortal database

```Console
USE [SecuritasPortal]
GO

CREATE USER [EXTRANET\svc-web-securitasdev] FOR LOGIN [EXTRANET\svc-web-securitasdev]
GO
EXEC sp_addrolemember N'aspnet_Membership_FullAccess', N'EXTRANET\svc-web-securitasdev'
GO
EXEC sp_addrolemember N'aspnet_Profile_BasicAccess', N'EXTRANET\svc-web-securitasdev'
GO
EXEC sp_addrolemember N'aspnet_Roles_BasicAccess', N'EXTRANET\svc-web-securitasdev'
GO
EXEC sp_addrolemember N'aspnet_Roles_ReportingAccess', N'EXTRANET\svc-web-securitasdev'
GO
EXEC sp_addrolemember N'Customer_Provisioner', N'EXTRANET\svc-web-securitasdev'
GO
EXEC sp_addrolemember N'Customer_Reader', N'EXTRANET\svc-web-securitasdev'
GO
```

```Console
cls
```

## # Delete Temp files

```PowerShell
Remove-Item C:\Users\jjameson-admin\AppData\Local\Temp\* -Recurse -Force

Remove-Item C:\Windows\Temp\* -Recurse -Force
```

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

## Activate Microsoft Office

1. Start Word 2013
2. Enter product key

## Install updates using Windows Update

**Note:** Repeat until there are no updates available for the computer.

```PowerShell
cls
```

## # Delete C:\\Windows\\SoftwareDistribution folder (? MB)

```PowerShell
net stop wuauserv
Remove-Item C:\Windows\SoftwareDistribution -Recurse
```

```PowerShell
cls
```

## # Shutdown VM

```PowerShell
Stop-Computer
```

## Remove disk from virtual CD/DVD drive

## # Expand C: drive

---

**WOLVERINE**

### # Increase the size of "EXT-FOOBAR2" VHD

```PowerShell
$vmName = "EXT-FOOBAR2"

Resize-VHD `
    ("C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
        + $vmName + ".vhdx") `
    -SizeBytes 37GB
```

---

### # Extend C: partition

```PowerShell
cls
```

## # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

## # Configure firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
# Note: New-NetFirewallRule is not available on Windows Server 2008 R2

netsh advfirewall firewall add rule `
    name="Remote Windows Update (Dynamic RPC)" `
    description="Allows remote auditing and installation of Windows updates via POSHPAIG (http://poshpaig.codeplex.com/)" `
    program="%windir%\system32\dllhost.exe" `
    dir=in `
    protocol=TCP `
    localport=RPC `
    profile=Domain `
    action=Allow
```

## # Disable firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
netsh advfirewall firewall set rule `
    name="Remote Windows Update (Dynamic RPC)" new enable=no
```

## Snapshot VM - "Baseline Client Portal 3.0.633.0 / Cloud Portal 1.0.104.0"

**TODO:**

```PowerShell
cls
```

#### # Configure VSS permissions for SharePoint Search

```PowerShell
$serviceAccount = "EXTRANET\svc-spserviceapp-dev"

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

## REM Configure People Picker for FABRIKAM

### REM Configure the People Picker to support searches across one-way trust

#### REM Specify the credentials for accessing the trusted forest

```Console
stsadm -o setproperty -pn peoplepicker-searchadforests -pv "domain:extranet.technologytoolbox.com,EXTRANET\svc-web-securitasdev,{password};domain:corp.fabrikam.com,FABRIKAM\svc-web-securitasdev,{password};domain:corp.technologytoolbox.com,TECHTOOLBOX\svc-web-securitasdev,{password}" -url http://cloud-local.securitasinc.com
```

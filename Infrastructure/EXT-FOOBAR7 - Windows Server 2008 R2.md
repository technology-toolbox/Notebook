# EXT-FOOBAR7 - Windows Server 2008 R2 Standard

Tuesday, December 15, 2015\
4:16 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure server infrastructure

---

**FOOBAR8** - Run as administrator

### # Create virtual machine (EXT-FOOBAR7)

```PowerShell
$vmHost = "WOLVERINE"
$vmName = "EXT-FOOBAR7"
$vmPath = "D:\NotBackedUp\VMs"

$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 50GB `
    -MemoryStartupBytes 8GB `
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

## Install custom Windows Server 2008 R2 image

- Start-up disk: [\\\\ICEMAN\\Products\\Microsoft\\MDT-Deploy-x86.iso](\\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso)
- On the **Task Sequence** step, select **Windows Server 2008 R2** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **EXT-FOOBAR7**.
  - In the **Domain to join** box, type **extranet.technologytoolbox.com**.
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

## # Rename local Administrator account and set password

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

$password = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1

$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

$adminUser = [ADSI] 'WinNT://./Administrator,User'
$adminUser.Rename('foo')
$adminUser.SetPassword($plainPassword)

logoff
```

---

**FOOBAR8** - Run as administrator

## # Remove disk from virtual CD/DVD drive

```PowerShell
$vmHost = "FORGE"

$vmName = "EXT-FOOBAR7"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

---

```PowerShell
cls
```

## # Change drive letter for DVD-ROM

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

## Configure Windows Update

### # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

### # Configure firewall rules for [http://poshpaig.codeplex.com/](POSHPAIG)

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

### # Disable firewall rule for [http://poshpaig.codeplex.com/](POSHPAIG)

```PowerShell
netsh advfirewall firewall set rule `
    name="Remote Windows Update (Dynamic RPC)" new enable=no
```

### Configure network settings

#### Rename network connection

"Local Area Connection" -> "LAN 1 - 192.168.10.x"

#### Enable jumbo frames

![(screenshot)](https://assets.technologytoolbox.com/screenshots/30/627387A552E5A1C4E5B253696DFD0AF44E76F530.png)

```Console
ping ICEMAN.corp.technologytoolbox.com -f -l 8900
```

#### TODO: Configure static IPv4 address

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B1/27EDED6A67DA9043BCD77EA71B861AE5F460D1B1.png)

#### TODO: Configure static IPv6 address

![(screenshot)](https://assets.technologytoolbox.com/screenshots/06/25889C9CFFD2BFC09A990EC8C3847A8559396106.png)

### Configure VM storage

| Disk | Drive Letter | Volume Size | VHD Type | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------- | -------------------- | ------------ |
| 0    | C:           | 50 GB       | Dynamic  | 4K                   | OSDisk       |
| 1    | D:           | 2 GB        | Fixed    | 64K                  | Data01       |
| 2    | L:           | 1 GB        | Fixed    | 64K                  | Log01        |
| 3    | T:           | 1 GB        | Fixed    | 64K                  | Temp01       |
| 4    | Z:           | 10 GB       | Dynamic  | 4K                   | Backup01     |

---

**FOOBAR8** - Run as administrator

```PowerShell
cls
```

#### # Create Data01, Log01, Temp01, and Backup01 VHDs

```PowerShell
$vmHost = "WOLVERINE"
$vmName = "EXT-FOOBAR7"
$vmPath = "D:\NotBackedUp\VMs"

$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName" `
    + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 2GB -Fixed
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ControllerType SCSI `
    -Path $vhdPath

$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName" `
    + "_Log01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 1GB -Fixed
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ControllerType SCSI `
    -Path $vhdPath

$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName" `
    + "_Temp01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 1GB -Fixed
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ControllerType SCSI `
    -Path $vhdPath

$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName" `
    + "_Backup01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 10GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ControllerType SCSI `
    -Path $vhdPath
```

---

#### Format drives

```PowerShell
cls
```

### # Set MaxPatchCacheSize to 0 (Recommended)

```PowerShell
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

## Install Internet Explorer 10

## # Delete Windows Update files (2.1 GB)

```PowerShell
Stop-Service wuauserv

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

Add-PSSnapin Microsoft.SharePoint.PowerShell

$smtpServer = "smtp-test.technologytoolbox.com"
$fromAddress = "svc-sharepoint-dev@technologytoolbox.com"
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

```PowerShell
cls
```

### # DEV - Configure timer job history

```PowerShell
Set-SPTimerJob "job-delete-job-history" -Schedule "Daily between 12:00:00 and 13:00:00"
```

### Install cumulative update for SharePoint Server 2010

#### Install updates

#### Upgrade the SharePoint farm

## Install and configure Office Web Apps

### Install Office Web Apps

### Install Service Pack 2 for Office Web Apps

### Run PSConfig to register Office Web Apps services

```PowerShell
cls
```

## # Configure service applications

### # Create and configure SharePoint service applications

```PowerShell
.\ConfigServiceApp.ps1 -FarmName Securitas_CP -InstallOWA $true
```

### Configure diagnostic logging and usage and health data collection

### # Create and configure the Search service application

```PowerShell
.\ConfigServiceApp_Search.ps1 -FarmName Securitas_CP
```

### Configure the search crawl schedules

```PowerShell
cls
```

### # Start SharePoint services

```PowerShell
.\ConfigureServicesOnServer.ps1 -server EXT-FOOBAR7 -role Single
```

### Create and configure the User Profile service application

#### Create the User Profile service application

#### Disable social features

#### Disable newsfeed

### Configure User Profile Synchronization (UPS)

#### Grant Active Directory permissions for profile synchronization

#### Enable NetBIOS domain names for user profile synchronization

```PowerShell
$serviceApp = Get-SPServiceApplication |
    where { $_.TypeName -eq 'User Profile Service Application' }

$serviceApp.NetBIOSDomainNamesEnabled = $true
$serviceApp.Update()
```

```PowerShell
cls
```

#### # Configure NETWORK SERVICE permissions

```PowerShell
$path = "$env:ProgramFiles\Microsoft Office Servers\14.0"
icacls $path /grant "NETWORK SERVICE:(OI)(CI)(RX)"
```

```PowerShell
cls
```

#### # Temporarily add SharePoint farm account to local Administrators group

```PowerShell
net localgroup Administrators /add EXTRANET\svc-sharepoint-dev

& 'C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts\Restart SharePoint Services.cmd'
```

#### Start the User Profile Synchronization Service

```PowerShell
cls
```

#### # Remove SharePoint farm account from local Administrators group

```PowerShell
net localgroup Administrators /delete EXTRANET\svc-sharepoint-dev

& 'C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts\Restart SharePoint Services.cmd'
```

#### Configure synchronization connection and import data from Active Directory

### Configure people search in SharePoint

#### Grant permissions to default content access account

#### Create content source for crawling user profiles

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

### Add the URL for the SecuritasConnect Web site to the "Local intranet" zone

### DEV - Snapshot VM

```PowerShell
cls
```

## # Create and configure the Web application

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
```

```PowerShell
cls
```

### # Import template site content

```PowerShell
& '.\Import Template Site Content.ps1'
```

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
Import-Csv \\iceman.corp.technologytoolbox.com\Archive\Clients\Securitas\AppSettings-UAT_2015-12-16.csv |
    foreach {
        .\Set-AppSetting.ps1 $_.Key $_.Value $_.Description -Force
    }
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
    where { $_.TypeName -eq "PowerPoint Service" } |
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

robocopy \\ICEMAN\Builds\Securitas\CloudPortal\1.0.106.0 C:\NotBackedUp\Builds\Securitas\CloudPortal\1.0.106.0 /E
```

```PowerShell
cls
```

## # Create and configure the Web application

### # Create the Web application and initial site collections

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\CloudPortal\1.0.106.0\DeploymentFiles\Scripts

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
Copy-Item `
    C:\inetpub\wwwroot\wss\VirtualDirectories\cloud-local.securitasinc.com80\web.config `
    "C:\inetpub\wwwroot\wss\VirtualDirectories\cloud-local.securitasinc.com80\Web - Copy.config"

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

### Configure custom sign-in page

## Create and configure C&C site collections

---

**EXT-FOOBAR2** - Run as administrator

### # Backup "Fabrikam Shipping" site collection

```PowerShell
cd C:\NotBackedUp\Temp

stsadm -o backup -url http://cloud-local.securitasinc.com/sites/Fabrikam-Shipping -filename Fabrikam-Shipping.dat

copy .\Fabrikam-Shipping.dat '\\EXT-FOOBAR7\c$\NotBackedUp\Temp'
```

---

```PowerShell
cls
```

### # Restore "Fabrikam Shipping" site collection

```PowerShell
cd C:\NotBackedUp\Temp

stsadm -o restore -url http://cloud-local.securitasinc.com/sites/Fabrikam-Shipping -filename Fabrikam-Shipping.dat
```

## Configure redirect for single-site users

### Create the "User Sites" List

### Add items to the "User Sites" list

### Add redirect Web Part to Cloud Portal home page

## Configure "Online Provisioning"

---

**EXT-FOOBAR2** - Run as administrator

### # Backup "Online Provisioning" site collection

```PowerShell
cd C:\NotBackedUp\Temp

stsadm -o backup -url http://cloud-local.securitasinc.com/sites/Online-Provisioning -filename Online-Provisioning.dat

copy .\Online-Provisioning.dat '\\EXT-FOOBAR7\c$\NotBackedUp\Temp'
```

---

```PowerShell
cls
```

### # Restore "Online Provisioning" site collection

```PowerShell
cd C:\NotBackedUp\Temp

stsadm -o restore -url http://cloud-local.securitasinc.com/sites/Online-Provisioning -filename Online Provisioning.dat
```

## -- Configure permissions for the SecuritasPortal database

```SQL
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

## Error viewing PowerPoint presentation in browser

SqlException: Cannot open database "OfficeWebAppsCache_CloudPortal" requested by the login. The login failed. Login failed for user 'EXTRANET\\svc-spserviceapp-dev'.

```PowerShell
cls
```

### # Grant access to the Web application content database for Office Web Apps

```PowerShell
$webApp = Get-SPWebApplication -Identity "http://cloud-local.securitasinc.com"

$webApp.GrantAccessToProcessIdentity("EXTRANET\svc-spserviceapp-dev")
```

## Enter a product key and activate Windows

## Install updates using Windows Update

**Note:** Repeat until there are no updates available for the computer.

```PowerShell
cls
```

## # Delete Windows Update files (2 GB)

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse
```

```PowerShell
cls
```

## # Delete Temp files

```PowerShell
Remove-Item C:\Users\setup-sharepoint-dev\AppData\Local\Temp\* -Recurse -Force

Remove-Item C:\Windows\Temp\* -Recurse -Force
```

## # Configure paging file

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3D/65A59940B553562ECE63D0A02BE1F2B3503BFC3D.png)

## -- Configure TempDB

```Console
DECLARE @dataPath VARCHAR(300);

SELECT
    @dataPath = REPLACE([filename], '.mdf','')
FROM
    sysaltfiles s
WHERE
    name = 'tempdev';

ALTER DATABASE [tempdb]
    MODIFY FILE
    (
        NAME = N'tempdev'
        , SIZE = 128MB
        , MAXSIZE = 256MB
        , FILEGROWTH = 32MB
    );

DECLARE @sqlStatement NVARCHAR(500);

SELECT @sqlStatement =
    N'ALTER DATABASE [tempdb]'
    + 'ADD FILE'
    + '('
        + 'NAME = N''tempdev2'''
        + ', FILENAME = ''' + @dataPath + '2.mdf'''
        + ', SIZE = 128MB'
        + ', MAXSIZE = 256MB'
        + ', FILEGROWTH = 32MB'
    + ')';

EXEC sp_executesql @sqlStatement;

SELECT @sqlStatement =
    N'ALTER DATABASE [tempdb]'
    + 'ADD FILE'
    + '('
        + 'NAME = N''tempdev3'''
        + ', FILENAME = ''' + @dataPath + '3.mdf'''
        + ', SIZE = 128MB'
        + ', MAXSIZE = 256MB'
        + ', FILEGROWTH = 32MB'
        + ')';

EXEC sp_executesql @sqlStatement;

SELECT @sqlStatement =
    N'ALTER DATABASE [tempdb]'
    + 'ADD FILE'
    + '('
        + 'NAME = N''tempdev4'''
        + ', FILENAME = ''' + @dataPath + '4.mdf'''
        + ', SIZE = 128MB'
        + ', MAXSIZE = 256MB'
        + ', FILEGROWTH = 32MB'
        + ')';

EXEC sp_executesql @sqlStatement;

ALTER DATABASE [tempdb]
    MODIFY FILE (
        NAME = N'templog',
        SIZE = 50MB,
        FILEGROWTH = 10MB
    )
```

```Console
cls
```

## # Shutdown VM

```PowerShell
Stop-Computer
```

## Remove disk from virtual CD/DVD drive

```PowerShell
cls
```

## # Configure SharePoint Farm Administrators

```PowerShell
$sharePointAdminsGroup = "EXTRANET\SharePoint Admins (DEV)"
```

### # Add group to "Farm Administrators" group

```PowerShell
Add-PSSnapin Microsoft.SharePoint.PowerShell

$site = Get-SPSite http://ext-foobar7:8888

$group = $site.RootWeb.SiteGroups["Farm Administrators"]

$user = $site.RootWeb.EnsureUser($sharePointAdminsGroup)
$group.AddUser($user)

$site.Dispose()
```

### # Configure "Full Control" permissions on Web apps

```PowerShell
$permissions = "Full Control"

$claim = New-SPClaimsPrincipal -Identity $sharePointAdminsGroup `
    -IdentityType WindowsSecurityGroupName

Get-SPWebApplication | foreach {
    $webApp = $_

    [Microsoft.SharePoint.Administration.SPPolicyRole] $policyRole =
            $webApp.PolicyRoles | where {$_.Name -eq $permissions}

    [Microsoft.SharePoint.Administration.SPPolicyCollection] $policies =
        $webApp.Policies

    [Microsoft.SharePoint.Administration.SPPolicy] $policy = $policies.Add(
        $claim.ToEncodedString(),
        $sharePointAdminsGroup)

    $policy.PolicyRoleBindings.Add($policyRole)
    $webApp.Update()
}
```

## -- Replace PNKUS Branch Manager logins

```Console
UPDATE [SecuritasPortal].[Customer].[BranchManagerAssociatedUsers]
SET BranchManagerUserName = 'TECHTOOLBOX\jjameson'
WHERE BranchManagerUserName = 'PNKUS\jjameson'
```

## Snapshot VM - "Baseline Client Portal 3.0.645.0 / Cloud Portal 1.0.106.0"

## Move VM to extranet VLAN

### Enable DHCP

### Rename network connection

### Disable jumbo frames

### Delete VM snapshot

---

**TT-VMM01A** - Run as administrator

```PowerShell
cls
```

### # Configure static IP address using VMM

```PowerShell
$vmName = "EXT-FOOBAR7"

$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"

$vmNetwork = Get-SCVMNetwork -Name "Extranet-20 VM Network"

$ipAddressPool= Get-SCStaticIPAddressPool -Name "Extranet-20 Address Pool"

$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName |
    where { $_.SlotId -eq 0 }

Stop-SCVirtualMachine $vmName

$macAddress = Grant-SCMACAddress `
    -MACAddressPool $macAddressPool `
    -Description $vmName `
    -VirtualNetworkAdapter $networkAdapter

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -MACAddressType Static `
    -MACAddress $macAddress `
    -IPv4AddressType Static `
    -IPv4AddressPool $ipAddressPool

Start-SCVirtualMachine $vmName
```

---

### Create VM snapshot

Snapshot name: **Baseline Client Portal 3.0.645.0 / Cloud Portal 1.0.106.0**

## Issue - Not enough free space to install patches using Windows Update

### Expand C: drive

#### Delete checkpoint

#### Expand primary VHD for virtual machine

New size: 60 GB

#### Extend partition

#### Create checkpoint

**TODO:**

```PowerShell
cls
```

## # Configure VSS permissions for SharePoint Search

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

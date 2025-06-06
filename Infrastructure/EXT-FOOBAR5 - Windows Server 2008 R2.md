# EXT-FOOBAR5 - Windows Server 2008 R2

Friday, May 15, 2015\
3:17 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

### Install Windows Server 2008 R2

---

**WOLVERINE** - Run as administrator

```PowerShell
$VerbosePreference = "Continue"
```

```PowerShell
cls
```

#### # Get list of Windows Server 2008 R2 images

```PowerShell
Get-AzureVMImage |
    where { $_.Label -like "Windows Server 2008 R2*" } |
    select Label, ImageName
```

#### # Use latest OS image

```PowerShell
$imageName = `
    "a699494373c04fc0bc8f2bb1389d6106__Win2K8R2SP1-Datacenter-201504.01-en.us-127GB.vhd"
```

```PowerShell
cls
```

#### # Create VM

```PowerShell
$localAdminCred = Get-Credential `
    -UserName Administrator `
    -Message "Type the user name and "word for the local Administrator account."

$domainCred = Get-Credential `
    -UserName jjameson-admin `
    -Message "Type the user name and password for joining the domain."

$storageAccount = "techtoolboxdev"
$location = "West US"
$vmName = "EXT-FOOBAR5"
$cloudService = $vmName
$instanceSize = "Standard_D2"
$vhdPath = "https://$storageAccount.blob.core.windows.net/vhds/$vmName"
$localAdminUserName = $localAdminCred.UserName
$localPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR(
        $localAdminCred.Password))

$domainName = "EXTRANET"
$fqdn = "extranet.technologytoolbox.com"
$domainUserName = $domainCred.UserName
$domainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR(
        $domainCred.Password))

$orgUnit = "OU=SharePoint Servers,OU=Servers,OU=Resources,OU=Development," `
    + "DC=extranet,DC=technologytoolbox,DC=com"
$virtualNetwork = "West US VLAN1"
$subnetName = "Azure-Development"

$vmConfig = New-AzureVMConfig `
    -Name $vmName `
    -ImageName $imageName `
    -InstanceSize $instanceSize `
    -MediaLocation ($vhdPath + "/$vmName.vhd") |
    Add-AzureProvisioningConfig `
        -AdminUsername $localAdminUserName `
        -Password $localPassword `
        -WindowsDomain `
        -JoinDomain $fqdn `
        -Domain $domainName `
        -DomainUserName $domainUserName `
        -DomainPassword $domainPassword `
        -MachineObjectOU $orgUnit ` |
    Add-AzureDataDisk `
        -CreateNew `
        -DiskLabel Data01-A `
        -DiskSizeInGB 100 `
        -LUN 0 `
        -HostCaching None `
        -MediaLocation ($vhdPath + "/$vmName" + "_Data01-A.vhd") |
    Add-AzureDataDisk `
        -CreateNew `
        -DiskLabel Data01-B `
        -DiskSizeInGB 100 `
        -LUN 1 `
        -HostCaching None `
        -MediaLocation ($vhdPath + "/$vmName" + "_Data01-B.vhd") |
    Add-AzureDataDisk `
        -CreateNew `
        -DiskLabel Data01-C `
        -DiskSizeInGB 100 `
        -LUN 2 `
        -HostCaching None `
        -MediaLocation ($vhdPath + "/$vmName" + "_Data01-C.vhd") |
    Add-AzureDataDisk `
        -CreateNew `
        -DiskLabel Log01 `
        -DiskSizeInGB 60 `
        -LUN 3 `
        -HostCaching None `
        -MediaLocation ($vhdPath + "/$vmName" + "_Log01.vhd") |
    Add-AzureEndpoint -Name HTTP -LocalPort 80 -PublicPort 80 -Protocol tcp |
    Add-AzureEndpoint -Name HTTPS -LocalPort 443 -PublicPort 443 -Protocol tcp |
    Set-AzureSubnet -SubnetNames $subnetName

New-AzureVM `
    -ServiceName $cloudService `
    -Location $location `
    -VNetName $virtualNetwork `
    -VMs $vmConfig
```

---

#### Configure ACLs on endpoints

##### PowerShell endpoint

| **Order** | **Description**    | **Action** | **Remote Subnet** |
| --------- | ------------------ | ---------- | ----------------- |
| 0         | Technology Toolbox | Permit     | 50.246.207.160/30 |

##### Remote Desktop endpoint

| **Order** | **Description**    | **Action** | **Remote Subnet** |
| --------- | ------------------ | ---------- | ----------------- |
| 0         | Technology Toolbox | Permit     | 50.246.207.160/30 |

---

**WOLVERINE** - Run as administrator

```PowerShell
$vmName = "EXT-FOOBAR5"

$vm = Get-AzureVM -ServiceName $vmName -Name $vmName

$endpointNames = "PowerShell", "RemoteDesktop"

$endpointNames |
    foreach {
        $endpointName = $_

        $endpoint = $vm | Get-AzureEndpoint -Name $endpointName

        $acl = New-AzureAclConfig

        Set-AzureAclConfig `
            -AddRule `
            -ACL $acl `
            -Action Permit `
            -RemoteSubnet "50.246.207.160/30" `
            -Description "Technology Toolbox" `
            -Order 0

        Set-AzureEndpoint -Name $endpointName -VM $vm -ACL $acl |
            Update-AzureVM

    }
```

---

#### Rename network connection

"Local Area Connection 2" -> "LAN 1 - 10.71.4.x"

**Note:** Do not enable jumbo frames on Azure VM (currently, large packets cannot be sent over VPN tunnel).

### Configure VM storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label | Host Cache |
| --- | --- | --- | --- | --- | --- |
| 0 | C: | 127 GB | 4K |  | Read/Write |
| 1 | D: | 100 GB | 4K | Temporary Storage |  |
| 2 | E: | 300 GB<br>(3x100 GB, striped) | 64K | Data01 | None |
| 3 | L: | 60 GB | 64K | Log01 | None |

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4E/4F3728FFAF0E10870250FE284CCD64697C903C4E.png)

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

#### Install Internet Explorer 10

```PowerShell
cls
```

### # Delete Windows Update files

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse

Start-Service wuauserv
```

## Install and configure SharePoint Server 2010

### Prepare the farm servers

### Install SharePoint Server 2010 on the farm servers

```PowerShell
cls
```

### # Copy SecuritasConnect build to SharePoint server

```PowerShell
net use \\ICEMAN.corp.technologytoolbox.com\ipc$ /USER:TECHTOOLBOX\jjameson

robocopy `
"\\ICEMAN.corp.technologytoolbox.com\Builds\Securitas\ClientPortal\3.0.632.0" `
C:\NotBackedUp\Builds\Securitas\ClientPortal\3.0.632.0 /E
```

```PowerShell
cls
```

### # Create and configure the farm

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\3.0.632.0\DeploymentFiles\Scripts

.\CreateSharePointFarm.ps1 -FarmName Securitas_CP
```

### Add SharePoint Central Administration to the "Local intranet" zone

```PowerShell
cls
```

### # Add the SharePoint bin folder to the PATH environment variable

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-PathFolders.ps1 "C:\Program Files\Common Files\Microsoft Shared\web server extensions\14\BIN" -EnvironmentVariableTarget "Machine"
```

> **Important**
>
> Restart PowerShell for environment variable change to take effect.

### Grant DCOM permissions on IIS WAMREG admin Service

```PowerShell
cls
```

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

$smtpServer = "FAB-EX01.corp.fabrikam.com"
$fromAddress = "svc-sharepoint-dev@fabrikam.com"
$replyAddress = "no-reply@fabrikam.com"
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

### Install cumulative update for SharePoint Server 2010

#### Install updates

#### Upgrade the SharePoint farm

## Install and configure Office Web Apps

### Install Office Web Apps

### Install Service Pack 2 for Office Web Apps

### Run PSConfig to register Office Web Apps services

## Configure service applications

```PowerShell
cls
```

### # Create and configure SharePoint service applications

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\3.0.632.0\DeploymentFiles\Scripts

.\ConfigServiceApp.ps1 -FarmName Securitas_CP -InstallOWA $true
```

### Configure diagnostic logging and usage and health data collection

```PowerShell
cls
```

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
.\ConfigureServicesOnServer.ps1 -server EXT-FOOBAR5 -role Single
```

### Create and configure the User Profile service application

#### Create the User Profile service application

#### Disable social features

#### Disable newsfeed

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
> Restart PowerShell for environment variable change to take effect.

### Add the URL for the SecuritasConnect Web site to the "Local intranet" zone

```PowerShell
cls
```

## # Create and configure the Web application

### # Restore content database from EXT-FOOBAR2

```PowerShell
Copy-Item `
    "\\iceman.corp.technologytoolbox.com\Archive\Clients\Securitas\Backups\WSS_Content_SecuritasPortal-EXT-FOOBAR2.bak" `
    "E:\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Backup\Full\WSS_Content_SecuritasPortal.bak"


RESTORE DATABASE [WSS_Content_SecuritasPortal]
    FROM DISK = N'E:\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Backup\Full\WSS_Content_SecuritasPortal.bak'
    WITH FILE = 1
    , MOVE N'WSS_Content_SecuritasPortal' TO N'E:\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\WSS_Content_SecuritasPortal.mdf'
    , MOVE N'WSS_Content_SecuritasPortal_log' TO N'L:\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Data\WSS_Content_SecuritasPortal_1.LDF'
    , NOUNLOAD
    , STATS = 10
GO
```

### # Create the Web application and initial site collections

```PowerShell
cd 'C:\NotBackedUp\Builds\Securitas\ClientPortal\3.0.632.0\DeploymentFiles\Scripts'

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
stsadm -o setproperty -pn peoplepicker-searchadforests -pv "domain:extranet.technologytoolbox.com,EXTRANET\svc-web-sec-2010-dev,{password};domain:corp.fabrikam.com,FABRIKAM\svc-web-sec-2010-dev,{password}" -url http://client-local.securitasinc.com
```

#### Modify the permissions on the registry key where the encrypted credentials are stored

```PowerShell
cls
```

### # Enable disk-based caching for the Web application

```PowerShell
$path = `
    ("C:\inetpub\wwwroot\wss\VirtualDirectories" `
        + "\client-local.securitasinc.com80")

Copy-Item "$path\web.config" "$path\web - Copy.config"

Notepad "$path\web.config"
```

**Note:** Update the `<BlobCache>` element as follows:

```Console
    <BlobCache location="D:\BlobCache\14" path="\.(gif|jpg|jpeg|jpe|jfif|bmp|dib|tif|tiff|ico|png|wdp|hdp|css|js|asf|avi|flv|m4v|mov|mp3|mp4|mpeg|mpg|rm|rmvb|wma|wmv)$" maxSize="10" enabled="true" />
```

```Console
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

```PowerShell
New-Item `
    -Path "E:\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Backup\Full" `
    -ItemType Directory

net use \\iceman.corp.technologytoolbox.com\Archive /USER:TECHTOOLBOX\jjameson

Copy-Item `
    "\\iceman.corp.technologytoolbox.com\Archive\Clients\Securitas\Backups\SecuritasPortal-EXT-FOOBAR2.bak" `
    "E:\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Backup\Full\SecuritasPortal.bak"


RESTORE DATABASE [SecuritasPortal]
FROM DISK = N'E:\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Backup\Full\SecuritasPortal.bak'
    WITH FILE = 1
    , MOVE N'SecuritasPortal' TO N'E:\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\SecuritasPortal.mdf'
    , MOVE N'SecuritasPortal_log' TO N'L:\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Data\SecuritasPortal_1.LDF'
    , NOUNLOAD
    , STATS = 10
GO
```

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

### # Configure claims-based authentication

```PowerShell
$path = `
    ("C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions" `
        + "\14\WebServices\SecurityToken")

Copy-Item "$path\web.config" "$path\web - Copy.config"

Notepad "$path\web.config"
```

**{copy/paste Web.config entries from browser -- to avoid issue with copy/paste from OneNote}**

```Console
cls
```

### Install SecuritasConnect solutions and activate the features

```PowerShell
& '.\Add Solutions.ps1'

& '.\Deploy Solutions.ps1'

& '.\Activate Features.ps1'
```

```PowerShell
cls
```

### # Configure trusted root authorities in SharePoint

```PowerShell
& '.\Configure Trusted Root Authorities.ps1'
```

## Resolve issues with PowerPoint service application

### Issue 1: Service application proxy not added to default group

Delete proxy, then create a new one

```PowerShell
Get-SPPowerPointServiceApplication |
    New-SPPowerPointServiceApplicationProxy `
        -Name "PowerPoint Service Application Proxy" `
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
net use \\iceman.corp.technologytoolbox.com\ipc$ /USER:TECHTOOLBOX\jjameson

robocopy \\iceman.corp.technologytoolbox.com\Builds\Securitas\CloudPortal\1.0.90.0 C:\NotBackedUp\Builds\Securitas\CloudPortal\1.0.90.0 /E
```

```PowerShell
cls
```

## # Create and configure the Web application

```PowerShell
cls
```

### # Restore content database from EXT-FOOBAR2

```PowerShell
Copy-Item `
    "\\iceman.corp.technologytoolbox.com\Archive\Clients\Securitas\Backups\WSS_Content_CloudPortal-EXT-FOOBAR2.bak" `
    "E:\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Backup\Full\WSS_Content_CloudPortal.bak"
```

#### -- Restore content database

```Console
RESTORE DATABASE [WSS_Content_CloudPortal]
    FROM DISK = N'E:\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Backup\Full\WSS_Content_CloudPortal.bak'
    WITH FILE = 1
    , MOVE N'WSS_Content_CloudPortal' TO N'E:\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\WSS_Content_CloudPortal.mdf'
    , MOVE N'WSS_Content_CloudPortal_log' TO N'L:\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Data\WSS_Content_CloudPortal_1.LDF'
    , NOUNLOAD
    , STATS = 10
GO
```

```Console
cls
```

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
stsadm -o setproperty -pn peoplepicker-searchadforests -pv "domain:extranet.technologytoolbox.com,EXTRANET\svc-web-securitasdev,{password};domain:corp.technologytoolbox.com,FABRIKAM\svc-web-securitasdev,{password}" -url http://cloud-local.securitasinc.com
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
$path = `
    ("C:\inetpub\wwwroot\wss\VirtualDirectories" `
        + "\cloud-local.securitasinc.com80")

Copy-Item "$path\web.config" "$path\web - Copy.config"

Notepad "$path\web.config"
```

**{copy/paste Web.config entries from Word -- to avoid issue with copy/paste from OneNote}**

```PowerShell
cls
```

### # Enable disk-based caching for the Web application

```PowerShell
$path = `
    ("C:\inetpub\wwwroot\wss\VirtualDirectories" `
        + "\cloud-local.securitasinc.com80")

Copy-Item "$path\web.config" "$path\web - Copy.config"

Notepad "$path\web.config"
```

**Note:** Update the `<BlobCache>` element as follows:

```Console
    <BlobCache location="D:\BlobCache\14" path="\.(gif|jpg|jpeg|jpe|jfif|bmp|dib|tif|tiff|ico|png|wdp|hdp|css|js|asf|avi|flv|m4v|mov|mp3|mp4|mpeg|mpg|rm|rmvb|wma|wmv)$" maxSize="10" enabled="true" />
```

```Console
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

```PowerShell
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

## # Delete Windows Update files

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse
```

**TODO:**

## Activate Microsoft Office

1. Start Word 2013
2. Enter product key

# EXT-FOOBAR6 - Windows Server 2012 R2

Tuesday, May 26, 2015
5:15 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

### Install Windows Server 2012 R2

---

**WOLVERINE**

```PowerShell
$VerbosePreference = "Continue"
```

```PowerShell
cls
```

#### # Get list of Windows Server 2012 R2 images

```PowerShell
Get-AzureVMImage |
    where { $_.Label -like "Windows Server 2012 R2*" } |
    select Label, ImageName
```

#### # Use latest OS image

```PowerShell
$imageName = `
    "a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-R2-201504.01-en.us-127GB.vhd"
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
$vmName = "EXT-FOOBAR6"
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
$ipAddress = "10.71.4.101"

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
    Set-AzureSubnet -SubnetNames $subnetName |
    Set-AzureStaticVNetIP -IPAddress $ipAddress

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

**WOLVERINE**

```PowerShell
$vmName = "EXT-FOOBAR6"

$vm = Get-AzureVM -ServiceName $vmName -Name $vmName

$endpointNames = "PowerShell", "RemoteDesktop"

$endpointNames |
    ForEach-Object {
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

#### # Change drive letter for DVD-ROM

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
```

#### # Rename network connection

```PowerShell
Get-NetAdapter -Physical

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "LAN 1 - 10.71.4.x"
```

**Note:** Do not enable jumbo frames on Azure VM (currently, large packets cannot be sent over VPN tunnel).

### Configure VM storage

| Disk | Drive Letter | Volume Size                | Allocation Unit Size | Volume Label      | Host Cache |
| ---- | ------------ | -------------------------- | -------------------- | ----------------- | ---------- |
| 0    | C:           | 127 GB                     | 4K                   |                   | Read/Write |
| 1    | D:           | 100 GB                     | 4K                   | Temporary Storage |            |
| 2    | E:           | 300 GB(3x100 GB, striped) | 64K                  | Data01            | None       |
| 3    | L:           | 60 GB                      | 64K                  | Log01             | None       |

#### # Create storage pool and "Data01" drive

```PowerShell
$dataDiskCount = 3

$dataDisks = Get-StorageSubSystem -FriendlyName "Storage Spaces*" |
    Get-PhysicalDisk -CanPool $true |
    Sort-Object -Property FriendlyName |
    Select-Object -First $dataDiskCount

New-StoragePool `
    -StorageSubsystemFriendlyName "Storage Spaces*" `
    -FriendlyName "DataPool01" `
    -PhysicalDisks $dataDisks |
    New-VirtualDisk `
        -Interleave 64KB `
        -NumberOfColumns $dataDisks.Count `
        -ResiliencySettingName Simple `
        -UseMaximumSize `
        -FriendlyName "DataDisk01" |
    Initialize-Disk -PassThru |
    New-Partition -DriveLetter E -UseMaximumSize |
    Format-Volume `
    -AllocationUnitSize 64KB `
    -NewFileSystemLabel "Data01" `
    -Confirm:$false
```

#### # Create "Log01" drive

```PowerShell
Get-Disk 5 |
  Initialize-Disk -PartitionStyle MBR -PassThru |
  New-Partition -DriveLetter L -UseMaximumSize |
  Format-Volume `
    -AllocationUnitSize 64KB `
    -FileSystem NTFS `
    -NewFileSystemLabel "Log01" `
    -Confirm:$false
```

### # Set MaxPatchCacheSize to 0 (Recommended)

```PowerShell
reg add HKLM\Software\Policies\Microsoft\Windows\Installer /v MaxPatchCacheSize /t REG_DWORD /d 0 /f
```

### # Install Firefox (to download software from MSDN)

```PowerShell
mkdir D:\NotBackedUp\Temp

net use "\\iceman.corp.technologytoolbox.com\Products" /USER:TECHTOOLBOX\jjameson

copy "\\iceman.corp.technologytoolbox.com\Products\Mozilla\Firefox\Firefox Setup 36.0.exe" D:\NotBackedUp\Temp

& 'D:\NotBackedUp\Temp\Firefox Setup 36.0.exe'
```

### Change download location in Firefox

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B8/392B34873E861E3C872AB9C2C1716B60210D05B8.png)

### Download products from MSDN

- **Visual Studio 2010 Ultimate (x86) - DVD (English)**
- **Visual Studio 2010 Service Pack 1 (x86) - DVD (Multiple Languages)**
- **SQL Server 2008 R2 Developer (x86, x64, ia64) - DVD (English)**
- **SQL Server 2008 R2 Service Pack 3 (x86 and x64) - DVD (English)**
- **Office Professional Plus 2010 with Service Pack 1 (x86 and x64) - DVD (English)**
- **Office 2010 SP2 (x86) - DVD (Multiple Languages)**
- **SharePoint Designer 2010 (x86) - (English)**
- **Visio 2010 with Service Pack 1 (x86 and x64) - DVD (English)**
- **SharePoint Server 2010 with Service Pack 2 (x64) - DVD (English)**
- **Office Web Apps Server 2010 with Service Pack 2 (x64) - DVD (English)**

### DEV - Install Visual Studio 2010

### DEV - Install latest service pack for Visual Studio 2010

### DEV - Install TFS Power Tools

### Install SQL Server 2008 R2

**Note:** SQL Server 2008 R2 setup will not automatically install .NET Framework 3.5 on Windows Server 2012 R2.

#### Install .NET Framework 3.5 (prerequisite for SQL Server 2008 R2 installation)

```PowerShell
net use "\\iceman.corp.technologytoolbox.com\Products" /USER:TECHTOOLBOX\jjameson

Install-WindowsFeature `
    NET-Framework-Core `
    -Source '\\iceman.corp.technologytoolbox.com\Products\Microsoft\Windows Server 2012 R2\Sources\SxS'

Install-WindowsFeature : The request to add or remove features on the specified server failed.
Installation of one or more roles, role services, or features failed.
The source files could not be downloaded.
Use the "source" option to specify the location of the files that are required to restore the feature. For more
information on specifying a source location, see http://go.microsoft.com/fwlink/?LinkId=243077. Error: 0x800f0906
At line:1 char:1
+ Install-WindowsFeature `
+ ~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidOperation: (@{Vhd=; Credent...Name=localhost}:PSObject) [Install-WindowsFeature],
    Exception
    + FullyQualifiedErrorId : DISMAPI_Error__Cbs_Download_Failure,Microsoft.Windows.ServerManager.Commands.AddWindowsFeatureCommand
```

Reference:

**Attempting to Install .NET Framework 3.5 on Windows Server 2012 R2 Fails with Error Code 0x800F0906 or "the source files could not be downloaded", even when supplying source**\
From <[http://blogs.technet.com/b/askpfeplat/archive/2014/09/29/attempting-to-install-net-framework-3-5-on-windows-server-2012-r2-fails-with-error-code-0x800f0906-or-the-source-files-could-not-be-downloaded-even-when-supplying-source.aspx](http://blogs.technet.com/b/askpfeplat/archive/2014/09/29/attempting-to-install-net-framework-3-5-on-windows-server-2012-r2-fails-with-error-code-0x800f0906-or-the-source-files-could-not-be-downloaded-even-when-supplying-source.aspx)>

Neither of the two workarounds in the "Fix It" KB article (3005628) worked.

Download latest version of Windows Server 2012 R2 ISO from MSDN and then install .NET Framework 3.5 referencing the mounted ISO:

```PowerShell
Install-WindowsFeature `
    NET-Framework-Core `
    -Source F:\Sources\SxS
```

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

```PowerShell
cls
```

### # Delete Windows Update files (1.6 GB)

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse -Force

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
net use \\iceman.corp.technologytoolbox.com\ipc$ /USER:TECHTOOLBOX\jjameson

robocopy `
"\\iceman.corp.technologytoolbox.com\Builds\Securitas\ClientPortal\3.0.632.0" `
C:\NotBackedUp\Builds\Securitas\ClientPortal\3.0.632.0 /E
```

```PowerShell
cls
```

### # Create and configure the farm

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\3.0.632.0\DeploymentFiles\Scripts

.\CreateSharePointFarm.ps1 -FarmName Securitas_CP

C:\NotBackedUp\Builds\Securitas\ClientPortal\3.0.632.0\DeploymentFiles\Scripts\CreateSharePointFarm.ps1 : Microsoft
SharePoint is not supported with version 4.0.30319.34014 of the Microsoft .Net Runtime.
At line:1 char:1
+ .\CreateSharePointFarm.ps1 -FarmName Securitas_CP
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [Write-Error], WriteErrorException
    + FullyQualifiedErrorId : Microsoft.PowerShell.Commands.WriteErrorException,CreateSharePointFarm.ps1
```

Reference:

**SharePoint 2010 Management Shell does not load with Windows PowerShell 3.0**\
From <[https://support.microsoft.com/en-us/kb/2796733](https://support.microsoft.com/en-us/kb/2796733)>

Workaround:

Always use the SharePoint 2010 Management Shell when using Windows Server 2012 R2 -- not a "regular" Windows PowerShell instance.

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
$smtpServer = "fab-ex01.corp.fabrikam.com"
$fromAddress = "svc-sharepoint-dev@fabrikam.com"
$replyAddress = "no-reply@fabrikam.com"
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
.\ConfigureServicesOnServer.ps1 -server EXT-FOOBAR6 -role Single
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
New-Item `
    -Path "E:\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Backup\Full" `
    -ItemType Directory

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

USE SecuritasPortal
GO

UPDATE Customer.BranchManagerAssociatedUsers
SET BranchManagerUserName = 'FABRIKAM\smasters'
WHERE BranchManagerUserName = 'TECHTOOLBOX\smasters'
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

# Install SecuritasConnect solutions and activate the features

```PowerShell
& '.\Add Solutions.ps1'

Invoking script in a new app domain
The local farm is not accessible. Cmdlets with FeatureDependencyId are not registered.
Adding solutions...
Adding farm solution (..\..\Debug\Securitas.Portal.Web.wsp)...
Get-SPSolution : Microsoft SharePoint is not supported with version 4.0.30319.34014 of the Microsoft .Net Runtime.
At C:\NotBackedUp\Builds\Securitas\ClientPortal\3.0.632.0\DeploymentFiles\Scripts\Add Solutions.ps1:38 char:17
+     $solution = Get-SPSolution $solutionName -EA 0
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidData: (Microsoft.Share...dletGetSolution:SPCmdletGetSolution) [Get-SPSolution], P
   latformNotSupportedException
    + FullyQualifiedErrorId : Microsoft.SharePoint.PowerShell.SPCmdletGetSolution

& '.\Add Solutions.ps1' -runInThisAppDomain

& '.\Deploy Solutions.ps1' -runInThisAppDomain

& '.\Activate Features.ps1' -runInThisAppDomain
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
stsadm -o setproperty -pn peoplepicker-searchadforests -pv "domain:extranet.technologytoolbox.com,EXTRANET\svc-web-securitasdev,{password};domain:corp.fabrikam.com,FABRIKAM\svc-web-securitasdev,{password}" -url http://cloud-local.securitasinc.com
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
& '.\Add Solutions.ps1' -runInThisAppDomain

& '.\Deploy Solutions.ps1' -runInThisAppDomain

& '.\Activate Features.ps1' -runInThisAppDomain
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

Remove-Item C:\Windows\SoftwareDistribution -Recurse -Force
```

```PowerShell
cls
```

## # Migrate users

```PowerShell
Get-SPSite -Limit ALL |
    ForEach-Object {
        Write-Host "Migrating users on site ($($_.Url))..."

        Get-SPUser -Web $_.Url -Limit ALL |
        ForEach-Object {
            $newAlias = $_.UserLogin.Replace("techtoolbox\", "fabrikam\")

            If ($newAlias -ne $_.UserLogin)
            {
                Write-Host "Migrating user ($($_.UserLogin))..."

                Move-SPUser `
                    -Identity $_ `
                    -NewAlias $newAlias `
                    -IgnoreSID `
                    -Confirm:$false
            }
        }
    }

Moving user (i:0#.w|techtoolbox\jjameson)...
Move-SPUser : Value cannot be null.
Parameter name: userProfileApplicationProxy
At line:7 char:24
+             Move-SPUser <<<<  `
    + CategoryInfo          : InvalidData: (Microsoft.Share...PCmdletMoveUser:SPCmdletMoveUser) [Move-SPUser], ArgumentNullException
    + FullyQualifiedErrorId : Microsoft.SharePoint.PowerShell.SPCmdletMoveUser
```

Reference:

**SharePoint 2010 - MigrateUser Error "Value cannot be null. Parameter name: userProfileApplicationProxy"**\
From <[http://www.jonthenerd.com/2013/01/22/sharepoint-2010-migrateuser-error-value-cannot-be-null-parameter-name-userprofileapplicationproxy/](http://www.jonthenerd.com/2013/01/22/sharepoint-2010-migrateuser-error-value-cannot-be-null-parameter-name-userprofileapplicationproxy/)>

Workaround:

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B2/3C2ED5DF8DACE53A99AAA665B6BB891E5F7FF6B2.png)

```PowerShell
Migrating users on site (http://cloud-local.securitasinc.com/sites/Fabrikam-Shipping)...
Get-SPUser : Access is denied. (Exception from HRESULT: 0x80070005 (E_ACCESSDENIED))
At line:5 char:23
+             Get-SPUser <<<<  -Web $_.Url -Limit ALL |
    + CategoryInfo          : InvalidData: (Microsoft.Share...SPCmdletGetUser:SPCmdletGetUser) [Get-SPUser], UnauthorizedAccessException
    + FullyQualifiedErrorId : Microsoft.SharePoint.PowerShell.SPCmdletGetUser
```

Workaround:

Run SharePoint 2010 Management Shell as EXTRANET\\svc-sharepoint-dev

## Activate Microsoft Office

1. Start Word 2013
2. Enter product key

```PowerShell
cls
```

## # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

## # Configure firewall rules for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
New-NetFirewallRule `
    -Name 'Remote Windows Update (Dynamic RPC)' `
    -DisplayName 'Remote Windows Update (Dynamic RPC)' `
    -Description 'Allows remote auditing and installation of Windows updates via POSHPAIG (http://poshpaig.codeplex.com/)' `
    -Group 'Technology Toolbox (Custom)' `
    -Program '%windir%\system32\dllhost.exe' `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort RPC `
    -Profile Domain `
    -Action Allow
```

# POLARIS - Windows Server 2012 R2 Standard

Tuesday, April 28, 2015
12:09 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## # Stop SharePoint services

& 'C:\\NotBackedUp\\Public\\Toolbox\\SharePoint\\Scripts\\Stop SharePoint Services.cmd'

## Backup production SharePoint databases

---

**HAVOK**

### -- Backup SharePoint databases

```SQL
BACKUP DATABASE [WSS_Content_ttweb]
TO DISK = N'\\ICEMAN\Backups\HAVOK\WSS_Content_ttweb.bak'
WITH NOFORMAT, NOINIT
    , NAME = N'WSS_Content_ttweb-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY

BACKUP DATABASE [WSS_Content_Team1]
TO DISK = N'\\ICEMAN\Backups\HAVOK\WSS_Content_Team1.bak'
WITH NOFORMAT, NOINIT
    , NAME = N'WSS_Content_Team1-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY

BACKUP DATABASE [WSS_Content_MySites]
TO DISK = N'\\ICEMAN\Backups\HAVOK\WSS_Content_MySites.bak'
WITH NOFORMAT, NOINIT
    , NAME = N'WSS_Content_MySites-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY

BACKUP DATABASE [ManagedMetadataService]
TO DISK = N'\\ICEMAN\Backups\HAVOK\ManagedMetadataService.bak'
WITH NOFORMAT, NOINIT
    , NAME = N'ManagedMetadataService-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY

BACKUP DATABASE [ProfileDB]
TO DISK = N'\\ICEMAN\Backups\HAVOK\ProfileDB.bak'
WITH NOFORMAT, NOINIT
    , NAME = N'ProfileDB-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY

BACKUP DATABASE [SocialDB]
TO DISK = N'\\ICEMAN\Backups\HAVOK\SocialDB.bak'
WITH NOFORMAT, NOINIT
    , NAME = N'SocialDB-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY

BACKUP DATABASE [SyncDB]
TO DISK = N'\\ICEMAN\Backups\HAVOK\SyncDB.bak'
WITH NOFORMAT, NOINIT
    , NAME = N'SyncDB-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY

BACKUP DATABASE [Secure_Store_Service_DB]
TO DISK = N'\\ICEMAN\Backups\HAVOK\Secure_Store_Service_DB.bak'
WITH NOFORMAT, NOINIT
    , NAME = N'Secure_Store_Service_DB-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY
```

---

---

**MOONSTAR**

### # Delete old VM

```PowerShell
Stop-SCVirtualMachine POLARIS

Remove-SCVirtualMachine POLARIS

Remove-Item \\STORM\c$\NotBackedUp\VMs\POLARIS
```

---

## Create VM

- Processors: **4**
- Memory: **12 GB**
- VHD size (GB): **45**
- VHD file name:** POLARIS**

## Install custom Windows Server 2012 R2 image

- Start-up disk: [\\\\ICEMAN\\Products\\Microsoft\\MDT-Deploy-x86.iso](\\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso)
- On the **Task Sequence** step, select **Windows Server 2012 R2** and click **Next**.
- On the **Computer Details** step, in the **Computer name** box, type **POLARIS** and click **Next**.
- On the **Applications** step, click **Next**.

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

## # Set password for local Administrator account

```PowerShell
$adminUser = [ADSI] "WinNT://./Administrator,User"
$adminUser.SetPassword("{password}")
```

```PowerShell
cls
```

## # Rename network connection

```PowerShell
Get-NetAdapter -Physical

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "LAN 1 - 192.168.10.x"
```

## # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name "LAN 1 - 192.168.10.x" `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping ICEMAN -f -l 8900
```

## Configure VM storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 45 GB       | 4K                   | OSDisk       |
| 1    | D:           | 5 GB        | 4K                   | Data01       |
| 2    | L:           | 5 GB        | 4K                   | Log01        |

---

**STORM**

### # Create Data01 and Log01 VHDs

```PowerShell
$vmName = "POLARIS"

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName" `
    + "_Data01.vhdx"

New-VHD -Path $vhdPath -SizeBytes 5GB
Add-VMHardDiskDrive -VMName $vmName -ControllerType SCSI -Path $vhdPath

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName" `
    + "_Log01.vhdx"

New-VHD -Path $vhdPath -SizeBytes 5GB
Add-VMHardDiskDrive -VMName $vmName -ControllerType SCSI -Path $vhdPath
```

---

```PowerShell
cls
```

### # Format Data01 drive

```PowerShell
Get-Disk 1 |
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -DriveLetter D -UseMaximumSize |
    Format-Volume `
        -FileSystem NTFS `
        -NewFileSystemLabel "Data01" `
        -Confirm:$false
```

### # Format Log01 drive

```PowerShell
Get-Disk 2 |
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -DriveLetter L -UseMaximumSize |
    Format-Volume `
        -FileSystem NTFS `
        -NewFileSystemLabel "Log01" `
        -Confirm:$false
```

---

**HAVOK**

## Configure Max Degree of Parallelism for SharePoint

### -- Set Max Degree of Parallelism to 1

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

### # Restart SQL Server

```PowerShell
Stop-Service SQLSERVERAGENT

Restart-Service MSSQLSERVER

Start-Service SQLSERVERAGENT
```

---

## Create service accounts for SharePoint

---

**XAVIER1**

### # Create the SharePoint farm service account

```PowerShell
$displayName = "Service account for SharePoint farm"
$defaultUserName = "s-sharepoint"

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

### # Create the service account for SharePoint service applications

```PowerShell
$displayName = "Service account for SharePoint service applications"
$defaultUserName = "s-spserviceapp"

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

### # Create the service account for indexing content

```PowerShell
$displayName = "Service account for indexing content"
$defaultUserName = "s-index"

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

### # Create the service account for intranet websites

```PowerShell
$displayName = "Service account for intranet websites"
$defaultUserName = "s-web-intranet"

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

### # Create the service account for SharePoint My Sites and Team sites

```PowerShell
$displayName = 'Service account for SharePoint "my" sites and team sites'
$defaultUserName = "s-web-my-team"

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

---

```PowerShell
cls
```

## # Install prerequisites for SharePoint 2013

### # Install Windows features for SharePoint 2013

```PowerShell
Install-WindowsFeature `
    NET-WCF-HTTP-Activation45,`
    NET-WCF-TCP-Activation45, `
    NET-WCF-Pipe-Activation45 `-Source '\\ICEMAN\Products\Microsoft\Windows Server 2012 R2\Sources\SxS'

Install-WindowsFeature `
    Net-Framework-Features,Web-Server,Web-WebServer,Web-Common-Http,
    Web-Static-Content,Web-Default-Doc,Web-Dir-Browsing,Web-Http-Errors,
    Web-App-Dev,Web-Asp-Net,Web-Net-Ext,Web-ISAPI-Ext,Web-ISAPI-Filter,
    Web-Health,Web-Http-Logging,Web-Log-Libraries,Web-Request-Monitor,
    Web-Http-Tracing,Web-Security,Web-Basic-Auth,Web-Windows-Auth,
    Web-Filtering,Web-Digest-Auth,Web-Performance,Web-Stat-Compression,
    Web-Dyn-Compression,Web-Mgmt-Tools,Web-Mgmt-Console,Web-Mgmt-Compat,
    Web-Metabase,Application-Server,AS-Web-Support,AS-TCP-Port-Sharing,
    AS-WAS-Support,AS-HTTP-Activation,AS-TCP-Activation,AS-Named-Pipes,
    AS-Net-Framework,WAS,WAS-Process-Model,WAS-NET-Environment,
    WAS-Config-APIs,Web-Lgcy-Scripting,Windows-Identity-Foundation,
    Server-Media-Foundation,Xps-Viewer `
    -Source '\\ICEMAN\Products\Microsoft\Windows Server 2012 R2\Sources\SxS' `
    -Restart
```

### Reference

**The Products Preparation Tool in SharePoint Server 2013 may not progress past "Configuring Application Server Role, Web Server (IIS) Role"**\
Pasted from <[http://support.microsoft.com/kb/2765260](http://support.microsoft.com/kb/2765260)>

---

**STORM**

### # Insert SharePoint 2013 ISO image into VM

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\SharePoint 2013\" `
    + "en_sharepoint_server_2013_with_sp1_x64_dvd_3823428.iso"

Set-VMDvdDrive -VMName POLARIS -Path $imagePath
```

---

```PowerShell
cls
```

### # Install prerequisites for SharePoint 2013

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

## # Install SharePoint Server 2013

```PowerShell
X:\setup.cmd
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/59/6B1DE3E800C79386E287D5C9C6CE0EDAA054C059.png)

Click **Install SharePoint Server**. UAC, click Yes.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/70/B9728A9EC8B2E461903B5F5CBCA913E8CE475370.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D1/F56DEDCBD96796B1F3701899FBE37FAA568ACCD1.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4D/D1A9D4606736C1E893C47039BC8714A50638994D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/68/CBC9CE76C09F2E586169E4BB1491A72E28310668.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4F/AE6CA3F8549AD45E5467B4EDAB13023C56D0F74F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/51/3699E1E0D221E52F4448A8BBA346E21EED5FB251.png)

Clear the checkbox and click **Close**.

---

**STORM**

## # Checkpoint VM - "Before SharePoint Server 2013 configuration"

```PowerShell
Stop-VM POLARIS

Checkpoint-VM `
    -Name POLARIS `
    -SnapshotName "Before SharePoint Server 2013 configuration"

Start-VM POLARIS
```

---

```PowerShell
cls
```

## # Install SharePoint Cumulative Update

### # Copy patch to local disk

```PowerShell
robocopy "\\ICEMAN\Products\Microsoft\SharePoint 2013\Patches\15.0.4701.1001 - SharePoint 2013 March 2015 CU" C:\NotBackedUp\Temp
```

### # Install patch

```PowerShell
Push-Location C:\NotBackedUp\Temp

.\Install.ps1

Pop-Location
```

### # Remove patch files from local disk

```PowerShell
Remove-Item C:\NotBackedUp\Temp\ubersrv_1.cab
Remove-Item C:\NotBackedUp\Temp\ubersrv_2.cab
Remove-Item C:\NotBackedUp\Temp\ubersrv2013-kb2956166-fullfile-x64-glb.exe
```

```PowerShell
cls
```

## # Mirror Toolbox content

```PowerShell
robocopy \\ICEMAN\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E /MIR
```

```PowerShell
cls
```

## # Configure SharePoint Server 2013

```PowerShell
cls
```

### # Create SharePoint farm

```PowerShell
cd C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts

& '.\Create Farm.ps1' -DatabaseServer HAVOK
```

When prompted for the credentials for the farm service account:

1. In the **User name** box, type **TECHTOOLBOX\\s-sharepoint**.
2. In the **Password** box, type the password for the service account.

When prompted for the **Passphrase**, type a passphrase that meets the following criteria:

- Contains at least eight characters
- Contains at least three of the following four character groups:
  - English uppercase characters (from A through Z)
  - English lowercase characters (from a through z)
  - Numerals (from 0 through 9)
  - Nonalphabetic characters (such as !, \$, #, %)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/49/A6E95D900C3525E3CBD20F294996ED2305036949.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B5/D78807610F83EFF628C315AC43350E8B2CFED8B5.png)

```PowerShell
cls
```

### # Configure Service Principal Names for Central Administration

```PowerShell
setspn -A http/polaris.corp.technologytoolbox.com:22812 s-sharepoint
setspn -A http/polaris:22812 s-sharepoint
```

```PowerShell
cls
```

### # Add the SharePoint bin folder to the PATH environment variable

```PowerShell
$sharePointBinFolder = $env:ProgramFiles +
    "\Common Files\Microsoft Shared\Web Server Extensions\15\BIN"

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-PathFolders.ps1 `
    $sharePointBinFolder `
    -EnvironmentVariableTarget "Machine"
```

```PowerShell
cls
```

### # Grant permissions on DCOM applications for SharePoint

```PowerShell
& '.\Configure DCOM Permissions.ps1'
```

### Reference

**Event ID 10016, KB 920783, and the WSS_WPG Group**\
Pasted from <[http://www.technologytoolbox.com/blog/jjameson/archive/2009/10/17/event-id-10016-kb-920783-and-the-wss-wpg-group.aspx](http://www.technologytoolbox.com/blog/jjameson/archive/2009/10/17/event-id-10016-kb-920783-and-the-wss-wpg-group.aspx)>

```PowerShell
cls
```

### # Configure diagnostic logging

```PowerShell
Set-SPDiagnosticConfig `
    -LogLocation "L:\Microsoft Office Servers\15.0\Logs" `
    -LogDiskSpaceUsageGB 3 `
    -LogMaxDiskSpaceUsageEnabled:$true
```

```PowerShell
cls
```

### # Configure usage and health data collection

```PowerShell
Set-SPUsageService `
    -LoggingEnabled 1 `
    -UsageLogLocation "L:\Microsoft Office Servers\15.0\Logs"

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
    Where-Object { $_.IsAdministrationWebApplication -eq $true }

$centralAdmin.UpdateMailSettings(
    $smtpServer,
    $fromAddress,
    $replyAddress,
    $characterSet)
```

```PowerShell
cls
```

## # Backup SharePoint farm

---

**ICEMAN**

### # Create share and configure permissions for SharePoint backups

```PowerShell
mkdir "D:\Shares\Backups\SharePoint - POLARIS"

icacls "D:\Shares\Backups\SharePoint - POLARIS" /grant "TECHTOOLBOX\s-sharepoint:(OI)(CI)(F)"

icacls "D:\Shares\Backups\SharePoint - POLARIS" /grant "TECHTOOLBOX\POLARIS`$:(OI)(CI)(F)"
```

---

```PowerShell
cls
```

### # Backup farm

```PowerShell
Backup-SPFarm `
    -Directory "\\ICEMAN\Backups\SharePoint - POLARIS" `
    -BackupMethod Full
```

```PowerShell
cls
```

## # Configure service applications

### # Change the service account for the Distributed Cache

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

```PowerShell
cls
```

### # Configure the State Service

```PowerShell
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

```PowerShell
cls
```

### # Configure SharePoint Search

```PowerShell
& '.\Configure SharePoint 2013 Search.ps1'
```

When prompted for the credentials for the default content access account:

1. In the **User name** box, type **TECHTOOLBOX\\s-index**.
2. In the **Password** box, type the password for the service account.

```PowerShell
cls
```

#### # Configure VSS permissions for SharePoint Search

```PowerShell
$serviceAccount = "TECHTOOLBOX\s-spserviceapp"

New-ItemProperty `
    -Path HKLM:\SYSTEM\CurrentControlSet\Services\VSS\VssAccessControl `
    -Name $serviceAccount `
    -PropertyType DWord `
    -Value 1 | Out-Null

$acl = Get-Acl HKLM:\SYSTEM\CurrentControlSet\Services\VSS\Diag
$rule = New-Object System.Security.AccessControl.RegistryAccessRule(
    $serviceAccount, "FullControl", "Allow")

$acl.SetAccessRule($rule)
Set-Acl -Path HKLM:\SYSTEM\CurrentControlSet\Services\VSS\Diag -AclObject $acl
```

---

**HAVOK**

#### -- Configure permissions on stored procedures in SharePoint_Config database

```SQL
USE [Sharepoint_Config]
GO
GRANT EXECUTE ON [dbo].[proc_GetTimerRunningJobs] TO [WSS_Content_Application_Pools]
GRANT EXECUTE ON [dbo].[proc_GetTimerJobLastRunTime] TO [WSS_Content_Application_Pools]
GRANT EXECUTE ON [dbo].[proc_putObjectTVP] TO [WSS_Content_Application_Pools]
GRANT EXECUTE ON [dbo].[proc_putObject] TO [WSS_Content_Application_Pools]
GRANT EXECUTE ON [dbo].[proc_putDependency] TO [WSS_Content_Application_Pools]
GO
```

---

##### References

**Search account got - Insufficient sql database permissions for user. EXECUTE permission was denied on the object proc_Gettimerrunningjobs**\
From <[https://social.technet.microsoft.com/Forums/en-US/a0d08e98-1fd6-42cf-b738-6ba3df082210/search-account-got-insufficient-sql-database-permissions-for-user-execute-permission-was-denied?forum=sharepointadmin](https://social.technet.microsoft.com/Forums/en-US/a0d08e98-1fd6-42cf-b738-6ba3df082210/search-account-got-insufficient-sql-database-permissions-for-user-execute-permission-was-denied?forum=sharepointadmin)>

**Resolution of SharePoint Event ID 5214: EXECUTE permission was denied on the object ‘proc_putObjectTVP’, database ‘SharePoint_Config’**\
From <[http://sharepointpaul.blogspot.com/2013/09/resolution-of-sharepoint-event-id-5214.html](http://sharepointpaul.blogspot.com/2013/09/resolution-of-sharepoint-event-id-5214.html)>

**EXECUTE permission was denied on the object 'proc_putObjectTVP'**\
From <[https://social.technet.microsoft.com/Forums/office/en-US/88c2c219-e1b0-4ed2-807a-267dba1a2c0b/execute-permission-was-denied-on-the-object-procputobjecttvp?forum=sharepointadmin](https://social.technet.microsoft.com/Forums/office/en-US/88c2c219-e1b0-4ed2-807a-267dba1a2c0b/execute-permission-was-denied-on-the-object-procputobjecttvp?forum=sharepointadmin)>

#### # Enable continuous crawls

```PowerShell
Get-SPEnterpriseSearchServiceApplication |
    Get-SPEnterpriseSearchCrawlContentSource |
    Where-Object { $_.Type -eq "SharePoint" } |
    ForEach-Object {
        $_.EnableContinuousCrawls = $true
        $_.Update()
    }
```

```PowerShell
cls
```

### # Restore Managed Metadata Service

---

**HAVOK**

#### -- Restore service application database from production

```SQL
RESTORE DATABASE [ManagedMetadataService]
    FROM DISK = N'\\ICEMAN\Backups\HAVOK\ManagedMetadataService.bak'
    WITH FILE = 1
    , MOVE N'ManagedMetadataService' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\ManagedMetadataService.mdf'
    , MOVE N'ManagedMetadataService_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\ManagedMetadataService_log.LDF'
    , NOUNLOAD
    , STATS = 5
```

---

```PowerShell
cls
```

#### # Configure the Managed Metadata Service

```PowerShell
& '.\Configure Managed Metadata Service.ps1'
```

```PowerShell
cls
```

### # Restore User Profile Service

---

**HAVOK**

#### -- Restore service application databases from production

```SQL
RESTORE DATABASE [UserProfileService_Profile]
    FROM DISK = N'\\ICEMAN\Backups\HAVOK\ProfileDB.bak'
    WITH FILE = 1
    , MOVE N'ProfileDB' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\UserProfileService_Profile.mdf'
    , MOVE N'ProfileDB_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\UserProfileService_Profile_log.LDF'
    , NOUNLOAD
    , STATS = 5

RESTORE DATABASE [UserProfileService_Social]
    FROM DISK = N'\\ICEMAN\Backups\HAVOK\SocialDB.bak'
    WITH FILE = 1
    , MOVE N'SocialDB' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\UserProfileService_Social.mdf'
    , MOVE N'SocialDB_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\UserProfileService_Social_log.LDF'
    , NOUNLOAD
    , STATS = 5

RESTORE DATABASE [UserProfileService_Sync]
    FROM DISK = N'\\ICEMAN\Backups\HAVOK\SyncDB.bak'
    WITH FILE = 1
    , MOVE N'SyncDB' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\UserProfileService_Sync.mdf'
    , MOVE N'SyncDB_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\UserProfileService_Sync_log.LDF'
    , NOUNLOAD
    , STATS = 5
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

### # Restore the Secure Store Service

---

**HAVOK**

#### -- Restore service application database from production

```SQL
RESTORE DATABASE [SecureStoreService]
    FROM DISK = N'\\ICEMAN\Backups\HAVOK\Secure_Store_Service_DB.bak'
    WITH FILE = 1
    , MOVE N'Secure_Store_Service_DB' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\SecureStoreService.mdf'
    , MOVE N'Secure_Store_Service_DB_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\SecureStoreService_log.ldf'
    , NOUNLOAD
    , STATS = 5

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

#### # Configure the Secure Store Service

```PowerShell
Get-SPServiceInstance |
    Where-Object { $_.TypeName -eq "Secure Store Service" } |
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

#### # Add domain group to Administrators for service application

```PowerShell
$principal = New-SPClaimsPrincipal "SharePoint Admins" `
    -IdentityType WindowsSecurityGroupName

$security = Get-SPServiceApplicationSecurity $serviceApp -Admin

Grant-SPObjectSecurity $security $principal "Full Control"

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

## # Restore Web application - http://ttweb

```PowerShell
cls
```

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

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F2/42094FC9AF85C53238C252C896E30AE67973B4F2.png)

---

**HAVOK**

### -- Restore content database from production

```SQL
RESTORE DATABASE [WSS_Content_ttweb]
    FROM DISK = N'\\ICEMAN\Backups\HAVOK\WSS_Content_ttweb.bak'
    WITH FILE = 1
    , MOVE N'WSS_Content_ttweb' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\WSS_Content_ttweb.mdf'
    , MOVE N'WSS_Content_ttweb_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\WSS_Content_ttweb_log.LDF'
    , NOUNLOAD
    , STATS = 5
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
    Where-Object { $_.Name -ne "WSS_Content_ttweb" } |
    Remove-SPContentDatabase
```

```PowerShell
cls
```

## # Restore Web application - http://team

```PowerShell
cls
```

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

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E1/BA22D97D4AF3509A3A450F1751D6938BE8AF1FE1.png)

---

**HAVOK**

### -- Restore content database from production

```SQL
RESTORE DATABASE [WSS_Content_Team1]
    FROM DISK = N'\\ICEMAN\Backups\HAVOK\WSS_Content_Team1.bak'
    WITH FILE = 1
    , MOVE N'WSS_Content_Team1' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\WSS_Content_Team1.mdf'
    , MOVE N'WSS_Content_Team1_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\WSS_Content_Team1_log.LDF'
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
    Where-Object { $_.Name -ne "WSS_Content_Team1" } |
    Remove-SPContentDatabase
```

```PowerShell
cls
```

## # Restore Web application - http://my

```PowerShell
cls
```

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

**HAVOK**

### -- Restore content database from production

```SQL
RESTORE DATABASE [WSS_Content_MySites]
    FROM DISK = N'\\ICEMAN\Backups\HAVOK\WSS_Content_MySites.bak'
    WITH FILE = 1
    , MOVE N'WSS_Content_MySites' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\WSS_Content_MySites.mdf'
    , MOVE N'WSS_Content_MySites_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\WSS_Content_MySites_log.LDF'
    , NOUNLOAD
    , STATS = 5
```

---

```PowerShell
cls
```

### # Add content database to Web application

```PowerShell
Test-SPContentDatabase -Name WSS_Content_MySites -WebApplication http://my

Mount-SPContentDatabase -Name WSS_Content_MySites -WebApplication http://my
```

```PowerShell
cls
```

### # Remove default content database created with Web application

```PowerShell
Get-SPContentDatabase -WebApplication http://my |
    Where-Object { $_.Name -ne "WSS_Content_MySites" } |
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

```PowerShell
cls
```

## # Start full crawl

```PowerShell
Get-SPEnterpriseSearchServiceApplication |
    Get-SPEnterpriseSearchCrawlContentSource |
    % { $_.StartFullCrawl() }
```

---

**STORM**

## # Delete VM checkpoint - "Before SharePoint Server 2013 configuration"

```PowerShell
Remove-VMSnapshot -VMName POLARIS -Name "Before SharePoint Server 2013 configuration"
```

---

## # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
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

## # Install SCOM agent

```PowerShell
$imagePath = '\\ICEMAN\Products\Microsoft\System Center 2012 R2' `
    + '\en_system_center_2012_r2_operations_manager_x86_and_x64_dvd_2920299.iso'

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$msiPath = $imageDriveLetter + ':\agent\AMD64\MOMAgent.msi'

msiexec.exe /i $msiPath `
    MANAGEMENT_GROUP=HQ `
    MANAGEMENT_SERVER_DNS=JUBILEE `
    ACTIONS_USE_COMPUTER_ACCOUNT=1
```

## # Approve manual agent install in Operations Manager

## # Configure firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

---

**FOOBAR8**

```PowerShell
$computer = 'POLARIS'

$command = "New-NetFirewallRule ``
    -Name 'Remote Windows Update (Dynamic RPC)' ``
    -DisplayName 'Remote Windows Update (Dynamic RPC)' ``
    -Description 'Allows remote auditing and installation of Windows updates via POSHPAIG (http://poshpaig.codeplex.com/)' ``
    -Group 'Technology Toolbox (Custom)' ``
    -Program '%windir%\system32\dllhost.exe' ``
    -Direction Inbound ``
    -Protocol TCP ``
    -LocalPort RPC ``
    -Profile Domain ``
    -Action Allow"

$scriptBlock = [scriptblock]::Create($command)

Invoke-Command -ComputerName $computer -ScriptBlock $scriptBlock
```

---

```PowerShell
cls
```

## # Install SharePoint Cumulative Update

### # Copy patch to local disk

```PowerShell
robocopy '\\ICEMAN\Products\Microsoft\SharePoint 2013\Patches\15.0.4727.1001 - SharePoint 2013 June 2015 CU' C:\NotBackedUp\Temp
```

### # Install patch

```PowerShell
Push-Location C:\NotBackedUp\Temp

.\Install.ps1
```

When prompted to pause the Search Service Application or leave it running, specify to pause it.

```PowerShell
Pop-Location
```

### # Remove patch files from local disk

```PowerShell
Remove-Item C:\NotBackedUp\Temp\Install.ps1
Remove-Item C:\NotBackedUp\Temp\ubersrv_1.cab
Remove-Item C:\NotBackedUp\Temp\ubersrv_2.cab
Remove-Item C:\NotBackedUp\Temp\ubersrv2013-kb3054866-fullfile-x64-glb.exe
```

### # Upgrade SharePoint

```PowerShell
PSCONFIG.EXE -cmd upgrade -inplace b2b -wait
```

**TODO:**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/84/87D8F7F00E65C9FE5B09B4D655444EC47AD94D84.png)

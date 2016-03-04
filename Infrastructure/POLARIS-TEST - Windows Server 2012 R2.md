# POLARIS-TEST - Windows Server 2012 R2 Standard

Tuesday, April 28, 2015
4:30 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

---

**FOOBAR8**

## Create VM using Virtual Machine Manager

- Processors: **4**
- Memory: **8 GB**
- VHD size (GB): **45**
- VHD file name:** POLARIS-TEST**
- Virtual DVD drive: **[\\\\ICEMAN\\Products\\Microsoft\\MDT-Deploy-x86.iso](\\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso)**
- Network Adapter 1:** Virtual LAN 2 - 192-168.10.x**
- Host:** ROGUE**
- Automatic actions
  - **Turn on the virtual machine if it was running with the physical server stopped**
  - **Save State**
  - Operating system: **Windows Server 2012 R2 Standard**

---

## Install custom Windows Server 2012 R2 image

- On the **Task Sequence** step, select **Windows Server 2012 R2** and click **Next**.
- On the **Computer Details** step, in the **Computer name** box, type **POLARIS-TEST** and click **Next**.
- On the **Applications** step, do not select any applications, and click **Next**.

## # Rename local Administrator account and set password

```PowerShell
$adminUser = [ADSI] 'WinNT://./Administrator,User'
$adminUser.Rename('foo')
$adminUser.SetPassword('{password}')

logoff
```

```PowerShell
cls
```

## # Select "High performance" power scheme

```PowerShell
powercfg.exe /L
powercfg.exe /S SCHEME_MIN
powercfg.exe /L
```

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

```PowerShell
cls
```

## # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

## # Configure firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

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

## Configure VM storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 45 GB       | 4K                   | OSDisk       |
| 1    | D:           | 5 GB        | 4K                   | Data01       |
| 2    | L:           | 5 GB        | 4K                   | Log01        |

---

**FOOBAR8**

### # Add disks to virtual machine

```PowerShell
$vmHost = "BEAST"
$vmName = "POLARIS-TEST"

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 5GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path $vhdPath `
    -ControllerType SCSI

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Log01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 5GB
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

### # Initialize disks and format volumes

#### # Format Data01 drive

```PowerShell
Get-Disk 1 |
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -UseMaximumSize -DriveLetter D |
    Format-Volume `
        -FileSystem NTFS `
        -NewFileSystemLabel "Data01" `
        -Confirm:$false
```

#### # Format Log01 drive

```PowerShell
Get-Disk 2 |
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -UseMaximumSize -DriveLetter L |
    Format-Volume `
        -FileSystem NTFS `
        -NewFileSystemLabel "Log01" `
        -Confirm:$false
```

## Create service accounts for SharePoint

---

**XAVIER1**

### # Create the SharePoint farm service account (TEST)

```PowerShell
$displayName = "Service account for SharePoint farm (TEST)"
$defaultUserName = "s-sharepoint-test"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@corp.technologytoolbox.com"
$orgUnit = `
    "OU=Service Accounts,OU=Quality Assurance,DC=corp,DC=technologytoolbox,DC=com"

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

### # Create the service account for SharePoint service applications (TEST)

```PowerShell
$displayName = "Service account for SharePoint service applications (TEST)"
$defaultUserName = "s-spserviceapp-test"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@corp.technologytoolbox.com"
$orgUnit = `
    "OU=Service Accounts,OU=Quality Assurance,DC=corp,DC=technologytoolbox,DC=com"

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

### # Create the service account for indexing content (TEST)

```PowerShell
$displayName = "Service account for indexing content (TEST)"
$defaultUserName = "s-index-test"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@corp.technologytoolbox.com"
$orgUnit = `
    "OU=Service Accounts,OU=Quality Assurance,DC=corp,DC=technologytoolbox,DC=com"

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

### # Create the service account for intranet websites (TEST)

```PowerShell
$displayName = "Service account for intranet websites (TEST)"
$defaultUserName = "s-web-intranet-test"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@corp.technologytoolbox.com"
$orgUnit = `
    "OU=Service Accounts,OU=Quality Assurance,DC=corp,DC=technologytoolbox,DC=com"

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

### # Create the service account for SharePoint My Sites and Team sites (TEST)

```PowerShell
$displayName = 'Service account for SharePoint "my" sites and team sites (TEST)'
$defaultUserName = "s-web-my-team-test"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@corp.technologytoolbox.com"
$orgUnit = `
    "OU=Service Accounts,OU=Quality Assurance,DC=corp,DC=technologytoolbox,DC=com"

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

## [HAVOK-TEST] Configure Max Degree of Parallelism for SharePoint

```PowerShell
cls
```

## # Install prerequisites for SharePoint 2013

### # Install Windows features for SharePoint 2013

```PowerShell
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
    WAS-Config-APIs,Web-Lgcy-Scripting,NET-WCF-HTTP-Activation45,
    NET-WCF-TCP-Activation45,NET-WCF-Pipe-Activation45,
    Windows-Identity-Foundation,Server-Media-Foundation,Xps-Viewer `
    -Source '\\ICEMAN\Products\Microsoft\Windows Server 2012 R2\Sources\SxS' `
    -Restart
```

#### Reference

**The Products Preparation Tool in SharePoint Server 2013 may not progress past "Configuring Application Server Role, Web Server (IIS) Role"**\
Pasted from <[http://support.microsoft.com/kb/2765260](http://support.microsoft.com/kb/2765260)>

## Install SharePoint 2013 with Service Pack 1

---

**FOOBAR8**

### # Insert the SharePoint 2013 installation media

```PowerShell
$vmHost = "BEAST"
$vmName = "POLARIS-TEST"

$isoPath = '\\ICEMAN\Products\Microsoft\SharePoint 2013\' `
    + 'en_sharepoint_server_2013_with_sp1_x64_dvd_3823428.iso'

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $isoPath
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

```PowerShell
cls
```

### # Install SharePoint Server 2013

```PowerShell
& X:\setup.cmd
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

## Snapshot VM before configuring SharePoint

---

**FOOBAR8**

## # Checkpoint VM

```PowerShell
$snapshotName = 'Before SharePoint Server 2013 configuration'
$vmHost = 'BEAST'
$vmName = 'POLARIS-TEST'

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

## # Install SharePoint Cumulative Update

### # Copy patch to local disk

```PowerShell
robocopy "\\ICEMAN\Products\Microsoft\SharePoint 2013\Patches\15.0.4701.1001 - SharePoint 2013 March 2015 CU" C:\NotBackedUp\Temp
```

### # Install patch

```PowerShell
Add-PSSnapin Microsoft.SharePoint.PowerShell

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

## # Configure SharePoint Server 2013

```PowerShell
cls
```

### # Create SharePoint farm

```PowerShell
cd C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts

& '.\Create Farm.ps1' -DatabaseServer HAVOK-TEST
```

When prompted for the credentials for the farm service account:

1. In the **User name** box, type **TECHTOOLBOX\\s-sharepoint-test**.
2. In the **Password** box, type the password for the service account.

When prompted for the **Passphrase**, type a passphrase that meets the following criteria:

- Contains at least eight characters
- Contains at least three of the following four character groups:
  - English uppercase characters (from A through Z)
  - English lowercase characters (from a through z)
  - Numerals (from 0 through 9)
  - Nonalphabetic characters (such as !, \$, #, %)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CF/EBA2B44FEDD93940FCC035C8F2D3462BAD9673CF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6E/E713F4F7DD238AD32EA382E1A65749A44B8CC56E.png)

```PowerShell
cls
```

### # Configure Service Principal Names for Central Administration

```PowerShell
setspn -A http/polaris-test.corp.technologytoolbox.com:22812 s-sharepoint-test
setspn -A http/polaris-test:22812 s-sharepoint-test
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

$smtpServer = "smtp-test.technologytoolbox.com"
$fromAddress = "s-sharepoint-test@technologytoolbox.com"
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

```Console
PowerShell
```

### # Create share and configure permissions for SharePoint backups

```PowerShell
mkdir 'D:\Shares\Backups\SharePoint - POLARIS-TEST'

icacls 'D:\Shares\Backups\SharePoint - POLARIS-TEST' /grant 'TECHTOOLBOX\s-sharepoint-test:(OI)(CI)(F)'

icacls 'D:\Shares\Backups\SharePoint - POLARIS-TEST' /grant 'TECHTOOLBOX\POLARIS-TEST`$:(OI)(CI)(F)'
```

---

```PowerShell
cls
```

### # Backup farm

```PowerShell
Backup-SPFarm `
    -Directory "\\ICEMAN\Backups\SharePoint - POLARIS-TEST" `
    -BackupMethod Full
```

## Backup production SharePoint databases

---

**ICEMAN**

### # Create share for production backups

```PowerShell
mkdir D:\Shares\Backups\HAVOK
```

---

---

**HAVOK (connect SQL Server Management Studio from FOOBAR8)**

### -- Backup SharePoint databases

```SQL
BACKUP DATABASE [ManagedMetadataService]
TO DISK = N'\\ICEMAN\Backups\HAVOK\ManagedMetadataService.bak'
WITH NOFORMAT, NOINIT
    , NAME = N'ManagedMetadataService-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY

BACKUP DATABASE [SecureStoreService]
TO DISK = N'\\ICEMAN\Backups\HAVOK\SecureStoreService.bak'
WITH NOFORMAT, NOINIT
    , NAME = N'SecureStoreService-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY

BACKUP DATABASE [UserProfileService_Profile]
TO DISK = N'\\ICEMAN\Backups\HAVOK\UserProfileService_Profile.bak'
WITH NOFORMAT, NOINIT
    , NAME = N'UserProfileService_Profile-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY

BACKUP DATABASE [UserProfileService_Social]
TO DISK = N'\\ICEMAN\Backups\HAVOK\UserProfileService_Social.bak'
WITH NOFORMAT, NOINIT
    , NAME = N'UserProfileService_Social-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY

BACKUP DATABASE [UserProfileService_Sync]
TO DISK = N'\\ICEMAN\Backups\HAVOK\UserProfileService_Sync.bak'
WITH NOFORMAT, NOINIT
    , NAME = N'UserProfileService_Sync-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY

BACKUP DATABASE [WSS_Content_MySites]
TO DISK = N'\\ICEMAN\Backups\HAVOK\WSS_Content_MySites.bak'
WITH NOFORMAT, NOINIT
    , NAME = N'WSS_Content_MySites-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY

BACKUP DATABASE [WSS_Content_Team1]
TO DISK = N'\\ICEMAN\Backups\HAVOK\WSS_Content_Team1.bak'
WITH NOFORMAT, NOINIT
    , NAME = N'WSS_Content_Team1-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY

BACKUP DATABASE [WSS_Content_ttweb]
TO DISK = N'\\ICEMAN\Backups\HAVOK\WSS_Content_ttweb.bak'
WITH NOFORMAT, NOINIT
    , NAME = N'WSS_Content_ttweb-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY
```

---

```PowerShell
cls
```

## # Configure service applications

### # Change the service account for the Distributed Cache

```PowerShell
$credential = Get-Credential "TECHTOOLBOX\s-spserviceapp-test"

$account = New-SPManagedAccount $credential

$farm = Get-SPFarm
$cacheService = $farm.Services | where {$_.Name -eq "AppFabricCachingService"}

$cacheService.ProcessIdentity.CurrentIdentityType = "SpecificUser"
$cacheService.ProcessIdentity.ManagedAccount = $account
$cacheService.ProcessIdentity.Update()
$cacheService.ProcessIdentity.Deploy()
```

## # DEV - Constrain the Distributed Cache

```PowerShell
Update-SPDistributedCacheSize -CacheSizeInMB 300
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

1. In the **User name** box, type **TECHTOOLBOX\\s-spserviceapp-test**.
2. In the **Password** box, type the password for the service account.

```PowerShell
cls
```

### # Configure SharePoint Search

```PowerShell
& '.\Configure SharePoint 2013 Search.ps1'
```

When prompted for the credentials for the default content access account:

1. In the **User name** box, type **TECHTOOLBOX\\s-index-test**.
2. In the **Password** box, type the password for the service account.

```PowerShell
cls
```

#### # Configure VSS permissions for SharePoint Search

```PowerShell
$serviceAccount = "TECHTOOLBOX\s-spserviceapp-test"

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

**HAVOK-TEST (connect SQL Server Management Studio from FOOBAR8)**

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

**HAVOK-TEST (connect SQL Server Management Studio from FOOBAR8)**

#### -- Restore service application database from production

```SQL
RESTORE DATABASE [ManagedMetadataService]
    FROM DISK = N'\\ICEMAN\Backups\HAVOK\ManagedMetadataService.bak'
    WITH FILE = 1
    , MOVE N'ManagedMetadataService' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\ManagedMetadataService.mdf'
    , MOVE N'ManagedMetadataService_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\ManagedMetadataService_log.LDF'
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

```PowerShell
cls
```

### # Restore User Profile Service

---

**HAVOK-TEST (connect SQL Server Management Studio from FOOBAR8)**

#### -- Restore service application databases from production

```SQL
RESTORE DATABASE [UserProfileService_Profile]
    FROM DISK = N'\\ICEMAN\Backups\HAVOK\UserProfileService_Profile.bak'
    WITH FILE = 1
    , MOVE N'ProfileDB' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\UserProfileService_Profile.mdf'
    , MOVE N'ProfileDB_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\UserProfileService_Profile_log.LDF'
    , NOUNLOAD, STATS = 5

RESTORE DATABASE [UserProfileService_Social]
    FROM DISK = N'\\ICEMAN\Backups\HAVOK\UserProfileService_Social.bak'
    WITH FILE = 1
    , MOVE N'SocialDB' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\UserProfileService_Social.mdf'
    , MOVE N'SocialDB_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\UserProfileService_Social_log.LDF'
    , NOUNLOAD, STATS = 5

RESTORE DATABASE [UserProfileService_Sync]
    FROM DISK = N'\\ICEMAN\Backups\HAVOK\UserProfileService_Sync.bak'
    WITH FILE = 1
    , MOVE N'SyncDB' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\UserProfileService_Sync.mdf'
    , MOVE N'SyncDB_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\UserProfileService_Sync_log.LDF'
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

### # Restore the Secure Store Service

---

**HAVOK-TEST (connect SQL Server Management Studio from FOOBAR8)**

#### -- Restore service application database from production

```SQL
RESTORE DATABASE [SecureStoreService]
    FROM DISK = N'\\ICEMAN\Backups\HAVOK\SecureStoreService.bak'
    WITH FILE = 1
    , MOVE N'Secure_Store_Service_DB' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\SecureStoreService.mdf'
    , MOVE N'Secure_Store_Service_DB_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\SecureStoreService_log.ldf'
    , NOUNLOAD, STATS = 5

GO
```

#### -- Add service account to database

```SQL
USE [SecureStoreService]
GO
CREATE USER [TECHTOOLBOX\s-spserviceapp-test]
ALTER ROLE [SPDataAccess] ADD MEMBER [TECHTOOLBOX\s-spserviceapp-test]
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
$principal = New-SPClaimsPrincipal "SharePoint Admins (TEST)" `
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

## # Restore Web application - http://ttweb-test

```PowerShell
cls
```

### # Create Web application

```PowerShell
$appPoolCredential = Get-Credential "TECHTOOLBOX\s-web-intranet-test"

$appPoolAccount = New-SPManagedAccount -Credential $appPoolCredential

$authProvider = New-SPAuthenticationProvider

New-SPWebApplication `
    -ApplicationPool "SharePoint - ttweb-test80" `
    -Name "SharePoint - ttweb-test80" `
    -ApplicationPoolAccount $appPoolAccount `
    -AuthenticationProvider $authProvider `
    -HostHeader "ttweb-test" `
    -Port 80
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F2/42094FC9AF85C53238C252C896E30AE67973B4F2.png)

---

**HAVOK-TEST (connect SQL Server Management Studio from FOOBAR8)**

### -- Restore content database from production

```SQL
RESTORE DATABASE [WSS_Content_ttweb]
    FROM DISK = N'\\ICEMAN\Backups\HAVOK\WSS_Content_ttweb.bak'
    WITH FILE = 1
    , MOVE N'WSS_Content_ttweb' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\WSS_Content_ttweb.mdf'
    , MOVE N'WSS_Content_ttweb_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\WSS_Content_ttweb_log.LDF'
    , NOUNLOAD, STATS = 5
```

---

```PowerShell
cls
```

### # Add content database to Web application

```PowerShell
Test-SPContentDatabase -Name WSS_Content_ttweb -WebApplication http://ttweb-test

Mount-SPContentDatabase -Name WSS_Content_ttweb -WebApplication http://ttweb-test
```

```PowerShell
cls
```

### # Remove default content database created with Web application

```PowerShell
Get-SPContentDatabase -WebApplication http://ttweb-test |
    Where-Object { $_.Name -ne "WSS_Content_ttweb" } |
    Remove-SPContentDatabase
```

```PowerShell
cls
```

## # Restore Web application - http://team-test

```PowerShell
cls
```

### # Create Web application

```PowerShell
$appPoolCredential = Get-Credential "TECHTOOLBOX\s-web-my-team-test"

$appPoolAccount = New-SPManagedAccount -Credential $appPoolCredential

$authProvider = New-SPAuthenticationProvider

New-SPWebApplication `
    -ApplicationPool "SharePoint - my-team-test80" `
    -Name "SharePoint - team-test80" `
    -ApplicationPoolAccount $appPoolAccount `
    -AuthenticationProvider $authProvider `
    -HostHeader "team-test" `
    -Port 80
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E1/BA22D97D4AF3509A3A450F1751D6938BE8AF1FE1.png)

---

**HAVOK-TEST (connect SQL Server Management Studio from FOOBAR8)**

### -- Restore content database from production

```SQL
RESTORE DATABASE [WSS_Content_Team1]
    FROM DISK = N'\\ICEMAN\Backups\HAVOK\WSS_Content_Team1.bak'
    WITH FILE = 1
    , MOVE N'WSS_Content_Team1' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\WSS_Content_Team1.mdf'
    , MOVE N'WSS_Content_Team1_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\WSS_Content_Team1_log.LDF'
    , NOUNLOAD
    , STATS = 5
```

---

```PowerShell
cls
```

### # Add content database to Web application

```PowerShell
Test-SPContentDatabase -Name WSS_Content_Team1 -WebApplication http://team-test

Mount-SPContentDatabase -Name WSS_Content_Team1 -WebApplication http://team-test
```

```PowerShell
cls
```

### # Remove default content database created with Web application

```PowerShell
Get-SPContentDatabase -WebApplication http://team-test |
    Where-Object { $_.Name -ne "WSS_Content_Team1" } |
    Remove-SPContentDatabase
```

```PowerShell
cls
```

## # Restore Web application - http://my-test

```PowerShell
cls
```

### # Create Web application

```PowerShell
$appPoolAccount = Get-SPManagedAccount "TECHTOOLBOX\s-web-my-team-test"

$authProvider = New-SPAuthenticationProvider

New-SPWebApplication `
    -ApplicationPool "SharePoint - my-team-test80" `
    -Name "SharePoint - my-test80" `
    -AuthenticationProvider $authProvider `
    -HostHeader "my-test" `
    -Port 80
```

---

**HAVOK-TEST (connect SQL Server Management Studio from FOOBAR8)**

### -- Restore content database from production

```SQL
RESTORE DATABASE [WSS_Content_MySites]
    FROM DISK = N'\\ICEMAN\Backups\HAVOK\WSS_Content_MySites.bak'
    WITH FILE = 1
    , MOVE N'WSS_Content_MySites' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\WSS_Content_MySites.mdf'
    , MOVE N'WSS_Content_MySites_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\WSS_Content_MySites_log.LDF'
    , NOUNLOAD
    , STATS = 5
```

---

```PowerShell
cls
```

### # Add content database to Web application

```PowerShell
Test-SPContentDatabase -Name WSS_Content_MySites -WebApplication http://my-test

Mount-SPContentDatabase -Name WSS_Content_MySites -WebApplication http://my-test
```

```PowerShell
cls
```

### # Remove default content database created with Web application

```PowerShell
Get-SPContentDatabase -WebApplication http://my-test |
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
    -MySiteHostLocation "http://my-test/" `
    -MySiteManagedPath sites
```

---

**FOOBAR8**

## # Delete VM checkpoint - "Before SharePoint Server 2013 configuration"

```PowerShell
$vmHost = 'BEAST'
$vmName = 'POLARIS-TEST'

Stop-VM -ComputerName $vmHost -VMName $vmName

Remove-VMSnapshot `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Name 'Before SharePoint Server 2013 configuration'

while (Get-VM -ComputerName $vmHost -VMName $vmName |
    Where Status -eq "Merging disks") {
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 5
}

Write-Host

Start-VM -ComputerName $vmHost -VMName $vmName
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

```Console
cls
```

## # Install SCOM agent

```PowerShell
$imagePath = '\\iceman\Products\Microsoft\System Center 2012 R2' `
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

```PowerShell
cls
```

## # Configure registry permissions to avoid errors with SharePoint timer jobs

```PowerShell
$identity = "$env:COMPUTERNAME\WSS_WPG"
$registryPath = 'HKLM:SOFTWARE\Microsoft\Office Server\15.0'

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
User: TECHTOOLBOX\\s-sharepoint-test\
Computer: POLARIS-TEST.corp.technologytoolbox.com\
Event Description: The Execute method of job definition Microsoft.SharePoint.Publishing.Internal.PersistedNavigationTermSetSyncJobDefinition (ID ...) threw an exception. More information is included below.

Requested registry access is not allowed.

```PowerShell
cls
```

## # Install SharePoint Cumulative Update

### # Copy patch to local disk

```PowerShell
robocopy "\\ICEMAN\Products\Microsoft\SharePoint 2013\Patches\15.0.4763.1000 - SharePoint 2013 October 2015 CU" C:\NotBackedUp\Temp
```

### # Install patch

```PowerShell
Push-Location C:\NotBackedUp\Temp

.\Install.ps1

Pop-Location
```

### # Remove patch files from local disk

```PowerShell
Remove-Item C:\NotBackedUp\Temp\Install.ps1
Remove-Item C:\NotBackedUp\Temp\ubersrv_1.cab
Remove-Item C:\NotBackedUp\Temp\ubersrv_2.cab
Remove-Item C:\NotBackedUp\Temp\ubersrv2013-kb3085492-fullfile-x64-glb.exe
```

### # Upgrade SharePoint

```PowerShell
PSCONFIG.EXE -cmd upgrade -inplace b2b -wait
```

```PowerShell
cls
```

## # Configure registry permissions to avoid errors with SharePoint timer jobs

```PowerShell
$identity = "$env:COMPUTERNAME\WSS_WPG"
$registryPath = 'HKLM:SOFTWARE\Microsoft\Office Server\15.0'

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
User: TECHTOOLBOX\\s-sharepoint-test\
Computer: POLARIS-TEST.corp.technologytoolbox.com\
Event Description: The Execute method of job definition Microsoft.SharePoint.Publishing.Internal.PersistedNavigationTermSetSyncJobDefinition (ID ...) threw an exception. More information is included below.

Requested registry access is not allowed.

**TODO:**

## Resolve SCOM alerts due to disk fragmentation

### Alert Name

Logical Disk Fragmentation Level is high

### Alert Description

The disk C: (C:) on computer CYCLOPS.corp.technologytoolbox.com has high fragmentation level. File Percent Fragmentation value is 15%. Defragmentation recommended: true.

### Resolution

#### # Copy Toolbox content

```PowerShell
robocopy \\iceman\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E
```

#### # Create scheduled task to optimize drives

```PowerShell
[string] $xml = Get-Content `
  'C:\NotBackedUp\Public\Toolbox\Scheduled Tasks\Optimize Drives.xml'

Register-ScheduledTask -TaskName "Optimize Drives" -Xml $xml
```

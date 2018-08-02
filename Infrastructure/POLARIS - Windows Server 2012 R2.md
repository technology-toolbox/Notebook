# POLARIS - Windows Server 2012 R2 Standard

Tuesday, September 8, 2015
5:20 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## # Stop SharePoint services

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts\Stop SharePoint Services.cmd'
```

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

BACKUP DATABASE [UserProfileService_Profile]
TO DISK = N'\\ICEMAN\Backups\HAVOK\UserProfileService_Profile.bak'
WITH NOFORMAT, NOINIT
    , NAME = N'UserProfileService_Profile-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY

BACKUP DATABASE [UserProfileService_Social]
TO DISK = N'\\ICEMAN\Backups\HAVOK\UserProfileService_Social_.bak'
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

BACKUP DATABASE [SecureStoreService]
TO DISK = N'\\ICEMAN\Backups\HAVOK\SecureStoreService.bak'
WITH NOFORMAT, NOINIT
    , NAME = N'SecureStoreService-Full Database Backup'
    , SKIP, NOREWIND, NOUNLOAD, STATS = 10
    , COPY_ONLY
```

---

---

**FOOBAR8**

## # Delete old VM

```PowerShell
Stop-SCVirtualMachine POLARIS

Remove-SCVirtualMachine POLARIS

Remove-Item \\STORM\c$\NotBackedUp\VMs\POLARIS
```

---

---

**FOOBAR8**

## Create VM using Virtual Machine Manager

- Processors: **4**
- Memory: **12 GB**
- VHD size (GB): **45**
- VHD file name:** POLARIS**
- Virtual DVD drive: **[\\\\ICEMAN\\Products\\Microsoft\\MDT-Deploy-x86.iso](\\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso)**
- Network Adapter 1:** Virtual LAN 2 - 192-168.10.x**
- Host:** STORM**
- Automatic actions
  - **Turn on the virtual machine if it was running with the physical server stopped**
  - **Save State**
  - Operating system: **Windows Server 2012 R2 Standard**

---

## Install custom Windows Server 2012 R2 image

- On the **Task Sequence** step, select **Windows Server 2012 R2** and click **Next**.
- On the **Computer Details** step, in the **Computer name** box, type **POLARIS** and click **Next**.
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
$vmHost = 'STORM'
$vmName = 'POLARIS'

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

---

**HAVOK**

## Configure Max Degree of Parallelism for SharePoint

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
$vmHost = 'STORM'
$vmName = 'POLARIS'

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
    '\\ICEMAN\Products\Microsoft\SharePoint 2013\PrerequisiteInstallerFiles_SP1'

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

> **Important**
>
> Wait for the update to be installed before proceeding.

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

## Snapshot VM before configuring SharePoint

---

**FOOBAR8**

### # Checkpoint VM

```PowerShell
$snapshotName = 'Before SharePoint Server 2013 configuration'
$vmHost = 'STORM'
$vmName = 'POLARIS'

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
& 'C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts\Configure DCOM Permissions.ps1'
```

### Reference

**Event ID 10016, KB 920783, and the WSS_WPG Group**\
Pasted from <[http://www.technologytoolbox.com/blog/jjameson/archive/2009/10/17/event-id-10016-kb-920783-and-the-wss-wpg-group.aspx](http://www.technologytoolbox.com/blog/jjameson/archive/2009/10/17/event-id-10016-kb-920783-and-the-wss-wpg-group.aspx)>

```PowerShell
cls
```

### # Configure diagnostic logging

```PowerShell
Add-PSSnapin Microsoft.SharePoint.PowerShell

Set-SPDiagnosticConfig `
    -LogLocation "L:\Microsoft Office Servers\15.0\Logs" `
    -LogDiskSpaceUsageGB 3 `
    -LogMaxDiskSpaceUsageEnabled:$true
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

```Console
PowerShell
```

### # Create share and configure permissions for SharePoint backups

```PowerShell
mkdir 'D:\Shares\Backups\SharePoint - POLARIS'

icacls 'D:\Shares\Backups\SharePoint - POLARIS' /grant 'TECHTOOLBOX\s-sharepoint:(OI)(CI)(F)'

icacls 'D:\Shares\Backups\SharePoint - POLARIS' /grant 'TECHTOOLBOX\POLARIS$:(OI)(CI)(F)'
```

---

```PowerShell
cls
```

### # Backup farm

```PowerShell
Backup-SPFarm `
    -Directory '\\ICEMAN\Backups\SharePoint - POLARIS' `
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
    $serviceAccount, "FullControl", "ContainerInherit", "None", "Allow")

$acl.SetAccessRule($rule)
Set-Acl -Path HKLM:\SYSTEM\CurrentControlSet\Services\VSS\Diag -AclObject $acl
```

---

**HAVOK (connect SQL Server Management Studio from FOOBAR8)**

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

#### # Configure search crawl schedules

```PowerShell
$searchApp = Get-SPEnterpriseSearchServiceApplication `
    -Identity "Search Service Application"
```

##### # Enable continuous crawls for "Local SharePoint sites"

```PowerShell
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

```PowerShell
cls
```

### # Restore Managed Metadata Service

---

**HAVOK (connect SQL Server Management Studio from FOOBAR8)**

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

**HAVOK (connect SQL Server Management Studio from FOOBAR8)**

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

**HAVOK (connect SQL Server Management Studio from FOOBAR8)**

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

**HAVOK (connect SQL Server Management Studio from FOOBAR8)**

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

**HAVOK (connect SQL Server Management Studio from FOOBAR8)**

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

**HAVOK (connect SQL Server Management Studio from FOOBAR8)**

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

---

**FOOBAR8**

## # Delete VM checkpoint - "Before SharePoint Server 2013 configuration"

```PowerShell
$vmHost = 'STORM'
$vmName = 'POLARIS'

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

## # Start full crawl

```PowerShell
Add-PSSnapin Microsoft.SharePoint.PowerShell

Get-SPEnterpriseSearchServiceApplication |
    Get-SPEnterpriseSearchCrawlContentSource |
    % { $_.StartFullCrawl() }
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

#### Reference

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

## # Install and configure Office Web Apps

##### # Create the binding between SharePoint 2013 and Office Web Apps Server

```PowerShell
New-SPWOPIBinding -ServerName wac.fabrikam.com
```

```PowerShell
cls
```

##### # View the WOPI zone of SharePoint 2013

```PowerShell
Get-SPWOPIZone
```

##### # Change the WOPI zone if necessary

```PowerShell
Set-SPWOPIZone -zone "external-https"
```

### Configure name resolution for Office Web Apps

---

**EXT-WAC02A**

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    -IPAddress 192.168.10.37 `
    -Hostnames POLARIS, my, team, ttweb
```

---

## Upgrade to System Center Operations Manager 2016

### Uninstall SCOM 2012 R2 agent

```Console
msiexec /x `{786970C5-E6F6-4A41-B238-AE25D4B91EEA`}

Restart-Computer
```

### Install SCOM 2016 agent (using Operations Console)

## Issue - Incorrect IPv6 DNS server assigned by Comcast router

```Text
PS C:\Users\jjameson-admin> nslookup
Default Server:  cdns01.comcast.net
Address:  2001:558:feed::1
```

> **Note**
>
> Even after reconfiguring the **Primary DNS** and **Secondary DNS** settings on the Comcast router -- and subsequently restarting the VM -- the incorrect DNS server is assigned to the network adapter.

### Solution

```PowerShell
Set-DnsClientServerAddress `
    -InterfaceAlias Management `
    -ServerAddresses 2603:300b:802:8900::103, 2603:300b:802:8900::104

Restart-Computer
```

## Issue - Error accessing SharePoint sites (e.g. http://my)

Log Name:      Application\
Source:        ASP.NET 4.0.30319.0\
Date:          3/30/2017 8:54:11 AM\
Event ID:      1309\
Task Category: Web Event\
Level:         Warning\
Keywords:      Classic\
User:          N/A\
Computer:      POLARIS.corp.technologytoolbox.com\
Description:\
Event code: 3005\
Event message: An unhandled exception has occurred.\
Event time: 3/30/2017 8:54:11 AM\
Event time (UTC): 3/30/2017 2:54:11 PM\
Event ID: b452e7abc2a24d149df03c8a173bf075\
Event sequence: 2\
Event occurrence: 1\
Event detail code: 0\
\
Application information:\
    Application domain: /LM/W3SVC/1935782112/ROOT-2-131353347788774382\
    Trust level: Full\
    Application Virtual Path: /\
    Application Path: C:\\inetpub\\wwwroot\\wss\\VirtualDirectories\\my80\\\
    Machine name: POLARIS\
\
Process information:\
    Process ID: 9412\
    Process name: w3wp.exe\
    Account name: TECHTOOLBOX\\s-web-my-team\
\
Exception information:\
    Exception type: FileLoadException\
    Exception message: Loading this assembly would produce a different grant set from other instances. (Exception from HRESULT: 0x80131401)\
   at System.Linq.Enumerable.Count[TSource](IEnumerable`1 source)\
   at Microsoft.SharePoint.IdentityModel.SPChunkedCookieHandler.ReadCore(String name, HttpContext context)\
   at Microsoft.IdentityModel.Web.SessionAuthenticationModule.TryReadSessionTokenFromCookie(SessionSecurityToken& sessionToken)\
   at Microsoft.IdentityModel.Web.SessionAuthenticationModule.OnAuthenticateRequest(Object sender, EventArgs eventArgs)\
   at Microsoft.SharePoint.IdentityModel.SPSessionAuthenticationModule.OnAuthenticateRequest(Object sender, EventArgs eventArgs)\
   at System.Web.HttpApplication.SyncEventExecutionStep.System.Web.HttpApplication.IExecutionStep.Execute()\
   at System.Web.HttpApplication.ExecuteStep(IExecutionStep step, Boolean& completedSynchronously)

### References

**Loading this assembly would produce a different grant set from other instances. (Exception from HRESULT: 0x80131401)**\
From <[http://blog.bugrapostaci.com/2017/02/08/loading-this-assembly-would-produce-a-different-grant-set-from-other-instances-exception-from-hresult-0x80131401/](http://blog.bugrapostaci.com/2017/02/08/loading-this-assembly-would-produce-a-different-grant-set-from-other-instances-exception-from-hresult-0x80131401/)>

**Monitoring SharePoint 2010 Applications in System Center 2012 SP1**\
From <[https://technet.microsoft.com/en-us/library/jj614617.aspx?tduid=(1dfb939b69d4a5ed09b44f51992a8b97)(256380)(2459594)(TnL5HPStwNw-v0X_tBOK3jzpbtaadMW8RA)()](https://technet.microsoft.com/en-us/library/jj614617.aspx?tduid=(1dfb939b69d4a5ed09b44f51992a8b97)(256380)(2459594)(TnL5HPStwNw-v0X_tBOK3jzpbtaadMW8RA)())>

**SCOM 2016 Sharepoint 2013 PerfMon64.dll crash W3wp.exe**\
From <[https://social.technet.microsoft.com/Forums/en-US/24b4d768-57a2-42c9-8e18-1ef8c075913a/scom-2016-sharepoint-2013-perfmon64dll-crash-w3wpexe?forum=scomapm](https://social.technet.microsoft.com/Forums/en-US/24b4d768-57a2-42c9-8e18-1ef8c075913a/scom-2016-sharepoint-2013-perfmon64dll-crash-w3wpexe?forum=scomapm)>

**SCOM 2016 Agent Crashing Legacy IIS Application Pools**\
From <[http://kevingreeneitblog.blogspot.ie/2017/03/scom-2016-agent-crashing-legacy-iis.html](http://kevingreeneitblog.blogspot.ie/2017/03/scom-2016-agent-crashing-legacy-iis.html)>

**APM feature in SCOM 2016 Agent may cause a crash for the IIS Application Pool running under .NET 2.0 runtime**\
From <[https://blogs.technet.microsoft.com/momteam/2017/03/21/apm-feature-in-scom-2016-agent-may-cause-a-crash-for-the-iis-application-pool-running-under-net-2-0-runtime/](https://blogs.technet.microsoft.com/momteam/2017/03/21/apm-feature-in-scom-2016-agent-may-cause-a-crash-for-the-iis-application-pool-running-under-net-2-0-runtime/)>

### Solution

Remove SCOM agent and reinstall without Application Performance Monitoring (APM).

#### Remove SCOM agent using Operations Console

#### # Clean up SCOM agent folder

```PowerShell
Restart-Computer
```

> **Note**
>
> Wait for the server to restart.

```PowerShell
Remove-Item "C:\Program Files\Microsoft Monitoring Agent" -Recurse -Force
```

#### # Install SCOM agent without Application Performance Monitoring (APM)

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

#### Approve manual agent install in Operations Manager

## Upgrade SharePoint after installing latest patches using Windows Update

```PowerShell
cls
Push-Location ("C:\Program Files\Common Files\microsoft shared" `
    + "\Web Server Extensions\15\BIN")

.\PSConfig.exe `
```

    -cmd upgrade -inplace b2b `\
    -wait `\
    -cmd applicationcontent -install `\
    -cmd installfeatures `\
    -cmd secureresources `\
    -cmd services -install

```PowerShell
Pop-Location
```

### Reference

**Why I prefer PSCONFIGUI.EXE over PSCONFIG.EXE**\
From <[https://blogs.technet.microsoft.com/stefan_gossner/2015/08/20/why-i-prefer-psconfigui-exe-over-psconfig-exe/](https://blogs.technet.microsoft.com/stefan_gossner/2015/08/20/why-i-prefer-psconfigui-exe-over-psconfig-exe/)>

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Move VM to new Production VM network

```PowerShell
$vmName = "POLARIS"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Production VM Network"
$ipPool = Get-SCStaticIPAddressPool -Name "Production-15 Address Pool"

Stop-SCVirtualMachine $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -IPv4AddressPools $ipPool `
    -IPv4AddressType Static

Start-SCVirtualMachine $vmName
```

---

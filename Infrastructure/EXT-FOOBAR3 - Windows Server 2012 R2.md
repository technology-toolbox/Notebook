# EXT-FOOBAR3 - Windows Server 2012 R2 Standard

Sunday, February 08, 2015
5:27 AM

```Console
12345678901234567890123456789012345678901234567890123456789012345678901234567890

PowerShell
```

## # [FORGE] Create virtual machine (EXT-FOOBAR3)

```PowerShell
$vmName = "EXT-FOOBAR3"

New-VM `
    -Name $vmName `
    -Path C:\NotBackedUp\VMs `
    -MemoryStartupBytes 8GB `
    -SwitchName "Virtual LAN 2 - 192.168.10.x"

Set-VM -VMName $vmName -ProcessorCount 4

New-Item -ItemType Directory "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks"

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

$sysPrepedImage = "\\ICEMAN\VM-Library\VHDs\WS2012-R2-STD.vhdx"

Copy-Item $sysPrepedImage $vhdPath

Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath

Start-VM $vmName
```

Configure server settings

On the **Settings** page:

1. Ensure the following default values are selected:
   1. **Country or region: United States**
   2. **App language: English (United States)**
   3. **Keyboard layout: US**
2. Click **Next**.
3. Type the product key and then click **Next**.
4. Review the software license terms and then click **I accept**.
5. Type a password for the built-in administrator account and then click **Finish**.

## # Rename the server and join domain

```PowerShell
Rename-Computer -NewName EXT-FOOBAR3 -Restart
```

Wait for the VM to restart and then execute the following command to join the **EXTRANET** domain:

```PowerShell
Add-Computer -DomainName extranet.technologytoolbox.com -Restart
```

## Login as TECHTOOLBOX\\jjameson

## # Rename network connection

```PowerShell
Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "LAN 1 - 192.168.10.x"
```

## # Enable jumbo frames

```PowerShell
Set-NetAdapterAdvancedProperty `
    -Name "LAN 1 - 192.168.10.x" `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping ICEMAN -f -l 8900
```

```PowerShell
cls
```

## # Configure static IPv4 address

```PowerShell
$ipAddress = "192.168.10.217"

New-NetIPAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -IPAddress $ipAddress `
    -PrefixLength 24 `
    -DefaultGateway 192.168.10.1

Set-DNSClientServerAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -ServerAddresses 192.168.10.209,192.168.10.210
```

## # Configure static IPv6 address

```PowerShell
$ipAddress = "2601:1:8200:6000::217"

New-NetIPAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -IPAddress $ipAddress `
    -PrefixLength 64

Set-DNSClientServerAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -ServerAddresses 2601:1:8200:6000::209,2601:1:8200:6000::210
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

## # Disable firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
Disable-NetFirewallRule -Name 'Remote Windows Update (Dynamic RPC)'
```

## Create service accounts for SharePoint

---

**EXT-DC01**

### # Create service account for SharePoint 2013 farm (DEV)

```PowerShell
$displayName = "Service account for SharePoint 2013 farm (DEV)"
$defaultUserName = "s-sp-farm-dev"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@extranet.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=Development,DC=extranet,DC=technologytoolbox,DC=com"

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

### # Create service account for SharePoint 2013 service applications (DEV)

```PowerShell
$displayName = "Service account for SharePoint 2013 service applications (DEV)"
$defaultUserName = "s-sp-serviceapp-dev"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@extranet.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=Development,DC=extranet,DC=technologytoolbox,DC=com"

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

### # Create service account for indexing content (DEV)

```PowerShell
$displayName = "Service account for indexing content (DEV)"
$defaultUserName = "s-sp-index-dev"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@extranet.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=Development,DC=extranet,DC=technologytoolbox,DC=com"

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

### # Create service account for SecuritasConnect web app

```PowerShell
$displayName = "Service account for SecuritasConnect web app (DEV)"
$defaultUserName = "s-web-client-dev"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@extranet.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=Development,DC=extranet,DC=technologytoolbox,DC=com"

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

### # Create service account for SharePoint 2013 "Portal Super User"

```PowerShell
$displayName = "Service account for SharePoint 2013 `"Portal Super User`" (DEV)"
$defaultUserName = "s-sp-psu-dev"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@extranet.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=Development,DC=extranet,DC=technologytoolbox,DC=com"

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

### # Create service account for SharePoint 2013 "Portal Super Reader"

```PowerShell
$displayName = "Service account for SharePoint 2013 `"Portal Super Reader`" (DEV)"
$defaultUserName = "s-sp-psr-dev"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@extranet.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=Development,DC=extranet,DC=technologytoolbox,DC=com"

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

## Configure VM storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 50 GB       | 4K                   |              |
| 1    | D:           | 2 GB        | 64K                  | Data01       |
| 2    | L:           | 1 GB        | 64K                  | Log01        |
| 3    | T:           | 1 GB        | 64K                  | Temp01       |
| 4    | Z:           | 10 GB       | 4K                   | Backup01     |

### # [FORGE] Expand primary VHD for virtual machine

```PowerShell
$vmName = "EXT-FOOBAR3"

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

Resize-VHD -Path $vhdPath -SizeBytes 50GB
```

### # [FORGE] Create Data01, Log01, Temp01, and Backup01 VHDs

```PowerShell
$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName" `
    + "_Data01.vhdx"

New-VHD -Path $vhdPath -SizeBytes 3GB
Add-VMHardDiskDrive -VMName $vmName -ControllerType SCSI -Path $vhdPath

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName" `
    + "_Log01.vhdx"

New-VHD -Path $vhdPath -SizeBytes 1GB
Add-VMHardDiskDrive -VMName $vmName -ControllerType SCSI -Path $vhdPath

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName" `
    + "_Temp01.vhdx"

New-VHD -Path $vhdPath -SizeBytes 1GB
Add-VMHardDiskDrive -VMName $vmName -ControllerType SCSI -Path $vhdPath

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName" `
    + "_Backup01.vhdx"

New-VHD -Path $vhdPath -SizeBytes 10GB
Add-VMHardDiskDrive -VMName $vmName -ControllerType SCSI -Path $vhdPath
```

### # Expand C: partition

```PowerShell
$maxSize = (Get-PartitionSupportedSize -DriveLetter C).SizeMax

Resize-Partition -DriveLetter C -Size $maxSize
```

### # Format Data01 drive

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

### # Format Log01 drive

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

### # Format Temp01 drive

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

### # Format Backup01 drive

```PowerShell
Get-Disk 4 |
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -DriveLetter Z -UseMaximumSize |
    Format-Volume `
        -FileSystem NTFS `
        -NewFileSystemLabel "Backup01" `
        -Confirm:$false
```

## Install Visual Studio 2013 with Update 4

```PowerShell
cls
```

### # Install .NET Framework 3.5

```PowerShell
# net use \\iceman\ipc$ /USER:TECHTOOLBOX\jjameson
# $sourcePath = "\\ICEMAN\Products\Microsoft\Windows Server 2012 R2\Sources\SxS"

$sourcePath = "X:\sources\sxs"

Install-WindowsFeature NET-Framework-Core -Source $sourcePath
```

## Install SQL Server 2014

...\
Restart the server

## DEV - Change databases to Simple recovery model

```PowerShell
cls
```

## # Install Prince on front-end Web servers

```PowerShell
& "\\ICEMAN\Products\Prince\prince-7.1-setup.exe"
```

> **Important**
>
> Wait for the software to be installed.

```PowerShell
cls
```

#### # Configure Prince license

```PowerShell
Copy-Item `
    \\ICEMAN\Products\Prince\Prince-license.dat `
    'C:\Program Files (x86)\Prince\Engine\license\license.dat'
```

1. In the **Prince** window, click the **Help** menu and then click **License**.
2. In the **Prince License** window:
   1. Click **Open** and then locate the license file (**[\\\\ICEMAN\\Products\\Prince\\Prince-license.dat](\\ICEMAN\Products\Prince\Prince-license.dat)**).
   2. Click **Accept** to save the license information.
   3. Verify the license information and then click **Close**.
3. Close the Prince application.

## DEV - Install Microsoft Office 2013 with SP1

## DEV - Install Microsoft SharePoint Designer 2013 with SP1

## DEV - Install Microsoft Visio 2013 with SP1

## Install additional service packs and updates

- 65 important updates available
- ~1.8 GB
- Approximate time: 23 minutes (2:56 PM - 3:19 PM) - Hyper-V on FORGE

### # Delete C:\\Windows\\SoftwareDistribution folder (1.78 GB)

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse

Restart-Computer
```

### Check for updates using Windows Update (after removing patches folder)

- **Most recent check for updates: Never -> Most recent check for updates: Today at 8:45 AM**
- C:\\Windows\\SoftwareDistribution folder is now 43 MB

## DEV - Install additional browsers and software

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

### # Install Cumulative Update for SharePoint Server 2013

```PowerShell
net use \\ICEMAN\Products /USER:TECHTOOLBOX\jjameson

$patch = "15.0.4701.1001 - SharePoint 2013 March 2015 CU"

robocopy `
    "\\ICEMAN\Products\Microsoft\SharePoint 2013\Patches\$patch" `
    "C:\NotBackedUp\Temp\$patch" `
    /E

& "C:\NotBackedUp\Temp\$patch\*.exe"
```

> **Important**
>
> Wait for the patch to be installed.

```PowerShell
Remove-Item "C:\NotBackedUp\Temp\$patch" -Recurse
```

```PowerShell
cls
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

**FOOBAR8**

### # Checkpoint VM

```PowerShell
$vmHost = "STORM"
$vmName = "EXT-FOOBAR3"

Stop-VM -ComputerName $vmHost -Name $vmName

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName "6.5 Copy SecuritasConnect build to SharePoint server"

Start-VM -ComputerName $vmHost -Name $vmName
```

---

```PowerShell
cls
```

### # Install Cumulative Update for SharePoint Server 2013

```PowerShell
net use \\ICEMAN\Products /USER:TECHTOOLBOX\jjameson

$patch = "15.0.4727.1000 - SharePoint 2013 June 2015 CU"

robocopy `
    "\\ICEMAN\Products\Microsoft\SharePoint 2013\Patches\$patch" `
    "C:\NotBackedUp\Temp\$patch" `
    /E

& "C:\NotBackedUp\Temp\$patch\*.exe"
```

> **Important**
>
> Wait for the patch to be installed.

```PowerShell
Remove-Item "C:\NotBackedUp\Temp\$patch" -Recurse
```

---

**FOOBAR8**

### # Checkpoint VM

```PowerShell
$vmHost = "STORM"
$vmName = "EXT-FOOBAR3"

Stop-VM -ComputerName $vmHost -Name $vmName

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName "15.0.4727.1000 - SharePoint 2013 June 2015 CU"

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Copy SecuritasConnect build to SharePoint server

---

**Developer Command Prompt for VS2013 - Run as administrator**

```Console
mkdir C:\NotBackedUp\Securitas
tf workfold /decloak "$/Securitas ClientPortal/Dev/Lab2"
tf get C:\NotBackedUp\Securitas\ClientPortal\Dev\Lab2 /recursive /force
tf get "$/Securitas ClientPortal/Main/Code/Securitas.Portal.ruleset" /force
cd C:\NotBackedUp\Securitas\ClientPortal\Dev\Lab2\Code
msbuild SecuritasClientPortal.sln /p:IsPackaging=true
```

---

```PowerShell
cls
```

### # Create and configure the farm

```PowerShell
cd C:\NotBackedUp\Securitas\ClientPortal\Dev\Lab2\Code\DeploymentFiles\Scripts

& '.\Create Farm.ps1' -CentralAdminAuthProvider NTLM -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-sp-farm-dev**.\
> Expect the previous operation to complete in approximately 7 minutes.

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

New-SPUsageApplication
```

### # Configure outgoing e-mail settings

```PowerShell

$smtpServer = "smtp-test.technologytoolbox.com"
$fromAddress = "s-sp-farm-dev@technologytoolbox.com"
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
cd C:\NotBackedUp\Securitas\ClientPortal\Dev\Lab2\Code\DeploymentFiles\Scripts

& '.\Configure Distributed Cache.ps1' -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-sp-serviceapp-dev**.\
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

```PowerShell
cls
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
> When prompted for the service account, specify **EXTRANET\\s-sp-serviceapp-dev**.

```PowerShell
cls
```

### # Configure the Managed Metadata Service

#### # Create the Managed Metadata Service

```PowerShell
& '.\Configure Managed Metadata Service.ps1' -Verbose
```

```PowerShell
cls
```

### # Create and configure the search service application

```PowerShell
& '.\Configure SharePoint Search.ps1' -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-sp-crawler-dev**.\
> Expect the previous operation to complete in approximately 6 minutes.

```PowerShell
cls
```

### # Configure the search crawl schedules

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

### # DEV - Configure performance level for the search crawl component

```PowerShell
Set-SPEnterpriseSearchService -PerformanceLevel Reduced

Restart-Service SPSearchHostController
```

```PowerShell
cls
```

### # Configure the User Profile Service Application

#### # Create the User Profile Service Application

##### Issue

Error starting UPS service (when User Profile Service Application is created by TECHTOOLBOX\\jjameson):

UserProfileApplication.SynchronizeMIIS: Failed to configure ILM, will attempt during next rerun. Exception: System.Data.SqlClient.SqlException (0x80131904): Specified collection 'StringSchemaCollection' cannot be dropped because it is used by object 'EXTRANET\\s-sp-farm-dev.GetObjectCurrent'.\
 at System.Data.SqlClient.SqlConnection.OnError(SqlException exception, Boolean breakConnection, Action`1 wrapCloseInAction)\
 at System.Data.SqlClient.TdsParser.ThrowExceptionAndWarning(TdsParserStateObject stateObj, Boolean callerHasConnectionLock, Boolean asyncClose)\
 at System.Data.SqlClient.TdsParser.TryRun(RunBehavior runBehavior, SqlCommand cmdHandler, SqlDataReader dataStream, BulkCopySimpleResultSet bulkCopyHandler, TdsParserStateObject stateObj, Boolean& dataReady)\
 at System.Data.SqlClient.SqlCommand.RunExecuteNonQueryTds(String methodName, Boolean async, Int32 timeout, Boolean asyncWrite)\
 at System.Data.SqlClient.SqlCommand.InternalExecuteNonQuery(TaskCompletionSource`1 completion, String methodName, Boolean sendToPipe, Int32 timeout, Boolean asyncWrite)\
 at System.Data.SqlClient.SqlCommand.ExecuteNonQuery()\
 at Microsoft.IdentityManagement.SetupUtils.IlmWSSetup.ExecuteSQL(String queryString)\
 at Microsoft.IdentityManagement.SetupUtils.IlmWSSetup.LoadSQLFile(String FileName)\
 at Microsoft.IdentityManagement.SetupUtils.IlmWSSetup.IlmBuildDatabase()\
 at Microsoft.Office.Server.UserProfiles.Synchronization.ILMPostSetupConfiguration.ConfigureIlmWebService(Boolean existingDatabase)\
 at Microsoft.Office.Server.Administration.UserProfileApplication.SetupSynchronizationService(ProfileSynchronizationServiceInstance profileSyncInstance)  ClientConnectionId:56b025c1-09f1-42f4-b8af-b86dfad9010d.

##### Reference

**Avoiding the Default Schema issue when creating the User Profile Service Application using Windows PowerShell**\
From <[http://www.harbar.net/archive/2010/10/30/avoiding-the-default-schema-issue-when-creating-the-user-profile.aspx](http://www.harbar.net/archive/2010/10/30/avoiding-the-default-schema-issue-when-creating-the-user-profile.aspx)>

##### Solution

Create User Profile Service Application as EXTRANET\\s-sp-farm-dev:

```PowerShell
$farmCredential = Get-Credential (Get-SPFarm).DefaultServiceAccount.Name

net localgroup Administrators /add $farmCredential.UserName
Restart-Service SPTimerV4

Start-Process $PSHOME\powershell.exe `
    -Credential $farmCredential `
    -ArgumentList "-Command Start-Process PowerShell.exe -Verb Runas" `
    -Wait
```

---

**PowerShell -- running as EXTRANET\\s-sp-farm-dev**

```PowerShell
cd C:\NotBackedUp\Securitas\ClientPortal\Dev\Lab2\Code\DeploymentFiles\Scripts

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

#### Disable social features

#### Disable newsfeed

##### Issue

![(screenshot)](https://assets.technologytoolbox.com/screenshots/91/3DE06A92091421CC8FFB13C7FD80B353E9DD0091.png)

From ULS log:

EditSection.ButtonOK_Click(): Microsoft.Office.Server.UserProfiles.CommitFailedException: Property update's Stored Procedure call returned an error. Error Code: 4. Errors removing properties: 1. Errors updating or creating properties: 0.\
 at Microsoft.Office.Server.UserProfiles.PropertyBase.Update(UserProfileApplicationProxy userProfileApplicationProxy, Guid partitionID, IEnumerable addPropertyList, IEnumerable updatePropertyList, IEnumerable removePropertyList)\
 at Microsoft.Office.Server.UserProfiles.PropertyBaseManager`1.Remove(T property)\
 at Microsoft.Office.Server.UserProfiles.ProfileSubtypePropertyManager.Remove(String propertyURI, String propertyName, String sectionName)\
 at Microsoft.Office.Server.UserProfiles.PropertyBaseManager`1.RemoveSectionByName(String sectionName)\
 at Microsoft.SharePoint.Portal.UserProfiles.AdminUI.EditSection._MakeTypeChangesToSection(CoreProperty section, ProfileTypeProperty sectionTypeProperty)\
 at Microsoft.SharePoint.Portal.UserProfiles.AdminUI.EditSection._CommitUpdatedSection()\
 at Microsoft.SharePoint.Portal.UserProfiles.AdminUI.EditSection.ButtonOK_Click(Object sender, EventArgs e).

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
net localgroup Administrators /add EXTRANET\s-sp-farm-dev

& 'C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts\Restart SharePoint Services.cmd'
```

#### Start the User Profile Synchronization Service

```PowerShell
cls
```

#### # Remove SharePoint farm account from local Administrators group

```PowerShell
net localgroup Administrators /delete EXTRANET\s-sp-farm-dev

& 'C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts\Restart SharePoint Services.cmd'
```

#### Configure synchronization connections and import data from Active Directory

| **Connection Name** | **Forest Name**            | **Account Name**            |
| ------------------- | -------------------------- | --------------------------- |
| TECHTOOLBOX         | corp.technologytoolbox.com | TECHTOOLBOX\\svc-sp-ups-dev |
| FABRIKAM            | corp.fabrikam.com          | FABRIKAM\\s-sp-ups-dev      |

```PowerShell
cls
```

### # Configure people search in SharePoint

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

#### # Configure content source for crawling user profiles

##### # Create content source

```PowerShell
$searchApp = Get-SPEnterpriseSearchServiceApplication `
    -Identity "Search Service Application"

$contentSource = New-SPEnterpriseSearchCrawlContentSource `
    -SearchApplication $searchapp `
    -Name "User profiles" `
    -Type SharePoint `
    -StartAddresses sps3://client-local.securitasinc.com
```

##### # Configure search crawl schedules

```PowerShell
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

## TODO: Install and configure Office Web Apps

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
> Restart PowerShell for environment variables to take effect.

```Console
cd C:\NotBackedUp\Securitas\ClientPortal\Dev\Lab2\Code\DeploymentFiles\Scripts
```

```Console
cls
```

### # Add the URL for the SecuritasConnect Web site to the "Local intranet" zone

```PowerShell
[string] $registryKey = ("HKCU:\Software\Microsoft\Windows" `
    + "\CurrentVersion\Internet Settings\ZoneMap\EscDomains" `
    + "\client-local.securitasinc.com")

If ((Test-Path $registryKey) -eq $false)
{
    New-Item $registryKey | Out-Null
}

Set-ItemProperty -Path $registryKey -Name http -Value 1
```

### DEV - Snapshot VM

---

**FOOBAR8**

### # Checkpoint VM

```PowerShell
$vmHost = "STORM"
$vmName = "EXT-FOOBAR3"

Stop-VM -ComputerName $vmHost -Name $vmName

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName "Baseline SharePoint Server 2013 configuration"

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Get latest version of Client Portal solution and build WSP packages

---

**Developer Command Prompt for VS2013 - Run as administrator**

```Console
tf get C:\NotBackedUp\Securitas\ClientPortal\Dev\Lab2 /recursive /force
tf get "$/Securitas ClientPortal/Main/Code/Securitas.Portal.ruleset" /force
cd C:\NotBackedUp\Securitas\ClientPortal\Dev\Lab2\Code
msbuild SecuritasClientPortal.sln /p:IsPackaging=true
```

---

### # Create the Web application and initial site collections

```PowerShell
cd C:\NotBackedUp\Securitas\ClientPortal\Dev\Lab2\Code\DeploymentFiles\Scripts

& '.\Create Web Application.ps1' -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-web-client-dev**.\
> Expect the previous operation to complete in approximately 2 minutes.

```PowerShell
cls
```

### # Restore content database or create initial site collections

#### # Create initial site collections

```PowerShell
& '.\Create Site Collections.ps1' -Verbose
```

> **Note**
>
> Expect the previous operation to complete in approximately 3 minutes.

```PowerShell
cls
```

### # Configure machine key for Web application

```PowerShell
& '.\Configure Machine Key.ps1' -Verbose
```

### # Configure object cache user accounts

```PowerShell
& '.\Configure Object Cache User Accounts.ps1' -Verbose

iisreset
```

### # Configure the People Picker to support searches across one-way trust

#### # Set the application password used for encrypting credentials

```PowerShell
$appPassword = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted for the secure string, type the password for encrypting sensitive data in SharePoint applications.

```PowerShell
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($appPassword))

stsadm -o setapppassword -password $plainPassword
```

```PowerShell
cls
```

#### # Specify the credentials for accessing the trusted forest

```PowerShell
$cred1 = Get-Credential "EXTRANET\s-web-client-dev"

$cred2 = Get-Credential "TECHTOOLBOX\svc-sp-ups"

$peoplePickerCredentials = $cred1, $cred2

& '.\Configure People Picker Forests.ps1' `
    -ServiceCredentials $peoplePickerCredentials `
    -Verbose
```

```PowerShell
cls
```

#### # Modify the permissions on the registry key where the encrypted credentials are stored

```PowerShell
$regPath = `
    "HKLM:\SOFTWARE\Microsoft\Shared Tools\Web Server Extensions\15.0\Secure"

$acl = Get-Acl $regPath

$rule = New-Object System.Security.AccessControl.RegistryAccessRule(
    "$env:COMPUTERNAME\WSS_WPG",
    "ReadKey",
    "ContainerInherit",
    "None",
    "Allow")

$acl.SetAccessRule($rule)
Set-Acl -Path $regPath -AclObject $acl
```

{TODO: bunch o' stuff skipped here}

### Configure My Site settings in User Profile service application

## Deploy the SecuritasConnect solution

---

**Developer Command Prompt for VS2013 - Run as administrator**

```Console
cls
```

### REM DEV - Build Visual Studio solution and package SharePoint projects

```Console
cd C:\NotBackedUp\Securitas\ClientPortal\Dev\Lab2\Code
msbuild SecuritasClientPortal.sln /p:IsPackaging=true
```

```Console
cls
```

### REM Create and configure the SecuritasPortal database

#### REM Create the SecuritasPortal database (or restore a backup)

```Console
pushd C:\NotBackedUp\Securitas\ClientPortal\Dev\Lab2\Code\BusinessModel\Database\Deployment

Install.cmd

popd
```

---

```PowerShell
cls
$sqlcmd = @"
```

#### -- Configure permissions for the SecuritasPortal database

```Console
USE [SecuritasPortal]
GO

CREATE USER [EXTRANET\s-sp-farm-dev] FOR LOGIN [EXTRANET\s-sp-farm-dev]
GO
ALTER ROLE [aspnet_Membership_BasicAccess] ADD MEMBER [EXTRANET\s-sp-farm-dev]
GO
ALTER ROLE [aspnet_Membership_ReportingAccess] ADD MEMBER [EXTRANET\s-sp-farm-dev]
GO
ALTER ROLE [aspnet_Roles_BasicAccess] ADD MEMBER [EXTRANET\s-sp-farm-dev]
GO
ALTER ROLE [aspnet_Roles_ReportingAccess] ADD MEMBER [EXTRANET\s-sp-farm-dev]
GO

CREATE USER [EXTRANET\s-web-client-dev] FOR LOGIN [EXTRANET\s-web-client-dev]
GO
ALTER ROLE [aspnet_Membership_FullAccess] ADD MEMBER [EXTRANET\s-web-client-dev]
GO
ALTER ROLE [aspnet_Profile_BasicAccess] ADD MEMBER [EXTRANET\s-web-client-dev]
GO
ALTER ROLE [aspnet_Roles_BasicAccess] ADD MEMBER [EXTRANET\s-web-client-dev]
GO
ALTER ROLE [aspnet_Roles_ReportingAccess] ADD MEMBER [EXTRANET\s-web-client-dev]
GO
ALTER ROLE [Customer_Reader] ADD MEMBER [EXTRANET\s-web-client-dev]
GO
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

```Console
cls
```

### # Configure logging

```PowerShell
cd C:\NotBackedUp\Securitas\ClientPortal\Dev\Lab2\Code\DeploymentFiles\Scripts

& '.\Add Event Log Sources.ps1' -Verbose
```

### # Configure claims-based authentication

```PowerShell
Notepad "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\WebServices\SecurityToken\web.config"
```

**{copy/paste Web.config entries from browser -- to avoid issue when copy/pasting from OneNote}**

```PowerShell
cls
```

### # Install SecuritasConnect solutions and activate the features

```PowerShell
& '.\Add Solutions.ps1' -Verbose

& '.\Deploy Solutions.ps1' -Verbose

& '.\Activate Features.ps1' -Verbose
```

> **Note**
>
> Expect the previous operations to complete in approximately 4.5 minutes.

```PowerShell
cls
```

#### # Activate the "Securitas - Application Settings" feature

```PowerShell
Start-Process `
    "http://client-local.securitasinc.com/_layouts/15/ManageFeatures.aspx"
```

```PowerShell
cls
```

### # Import template site content

```PowerShell
& '.\Import Template Site Content.ps1' -Verbose
```

> **Note**
>
> Expect the previous operations to complete in approximately 4 minutes.

### Create users in the SecuritasPortal database

#### Create users for Securitas clients

| **User Name** | **E-mail**            |
| ------------- | --------------------- |
| test-abc1     | test-abc1@foobar.com  |
| test-lite1    | test-lite1@foobar.com |

#### Create users for Securitas Branch Managers

| **User Name** | **E-mail**                     |
| ------------- | ------------------------------ |
| test-bm1      | test-bm1@technologytoolbox.com |

```PowerShell
cls
```

#### # Associate client users to Branch Managers

```PowerShell
$sqlcmd = @"
USE SecuritasPortal
GO

INSERT INTO Customer.BranchManagerAssociatedUsers
VALUES ('TECHTOOLBOX\jjameson', 'test-abc1')

INSERT INTO Customer.BranchManagerAssociatedUsers
VALUES ('TECHTOOLBOX\jjameson', 'test-lite1')

INSERT INTO Customer.BranchManagerAssociatedUsers
VALUES ('TECHTOOLBOX\smasters', 'test-abc1')

INSERT INTO Customer.BranchManagerAssociatedUsers
VALUES ('TECHTOOLBOX\smasters', 'test-lite1')
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

```PowerShell
cls
```

### # Configure trusted root authorities in SharePoint

```PowerShell
& '.\Configure Trusted Root Authorities.ps1' -Verbose
```

### Configure application settings (e.g. Web service URLs)

### Configure the SSO credentials for a user

Browse to the site and login as **test-abc1**.

Edit profile to set SSO credentials:

[http://client-local.securitasinc.com/_layouts/Securitas/EditProfile.aspx](http://client-local.securitasinc.com/_layouts/Securitas/EditProfile.aspx)

| **System** | **User Name**      |
| ---------- | ------------------ |
| CapSure    | jane               |
| Iverify    | scabc              |
| PatrolLIVE | robert@example.com |
| TrackTik   | jane.doe@abc.com   |

```PowerShell
cls
```

### # Configure C&C landing site

#### # Grant Branch Managers permissions to the C&C landing site

```PowerShell
Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

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

{Begin skipped sections}

#### Hide the Search navigation item on the C&C landing site

[http://client-local.securitasinc.com/sites/cc](http://client-local.securitasinc.com/sites/cc)

#### Configure the search settings for the C&C landing site

{End skipped sections}

```PowerShell
cls
```

## # Create and configure C&C site collections

### # Create site collection for a Securitas client

```PowerShell
& '.\Create Client Site Collection.ps1' "ABC Company"
```

{Begin skipped sections}

### Apply the "Securitas Client Site" template to the top-level site

### Modify the site title, description, and logo

### Update the client site home page

### Create a blog site (optional)

### Create a wiki site (optional)

{End skipped sections}

```PowerShell
cls
```

## # Configure Web application policy for SharePoint administrators group

```PowerShell
Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

$groupName = "EXTRANET\SharePoint Admins (DEV)"

$principal = New-SPClaimsPrincipal -Identity $groupName `
    -IdentityType WindowsSecurityGroupName

$claim = "c:0+.w|" + $principal.Value.ToLower()

$webApp = Get-SPWebApplication http://client-local.securitasinc.com

$policyRole = $webApp.PolicyRoles.GetSpecialRole(
    [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl)

$policy = $webApp.Policies.Add($claim, $groupName)
$policy.PolicyRoleBindings.Add($policyRole)

$webApp.Update()
```

## Remove extraneous VM snapshots

---

**FORGE**

### # Delete VM checkpoint - "6.5 Copy SecuritasConnect build to SharePoint server"

```PowerShell
$vmHost = "STORM"
$vmName = "POLARIS-DEV"

Stop-VM -ComputerName $vmHost -Name $vmName

Remove-VMSnapshot -VMName $vmName -Name "6.5 Copy SecuritasConnect build to SharePoint server"

while (Get-VM $vmName | Where Status -eq "Merging disks") {
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 5
}

Write-Host
```

### # Delete VM checkpoint - "15.0.4727.1000 - SharePoint 2013 June 2015 CU"

```PowerShell
Remove-VMSnapshot -VMName $vmName -Name "15.0.4727.1000 - SharePoint 2013 June 2015 CU"

while (Get-VM $vmName | Where Status -eq "Merging disks") {
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 5
}

Write-Host

Start-VM -ComputerName $vmHost -Name $vmName
```

---

**TODO:**

```PowerShell
cls
```

## # Start full crawl

```PowerShell
Get-SPEnterpriseSearchServiceApplication |
    Get-SPEnterpriseSearchCrawlContentSource |
    % { $_.StartFullCrawl() }
```

```PowerShell
cls
```

## # Suspend Search Service Application

```PowerShell
Get-SPEnterpriseSearchServiceApplication "Search Service Application" |
    Suspend-SPEnterpriseSearchServiceApplication
```

```PowerShell
cls
```

### # Delete C:\\Windows\\SoftwareDistribution folder (2.79 GB)

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse

Restart-Computer
```

### Check for updates using Windows Update (after removing patches folder)

- **Most recent check for updates: Never -> Most recent check for updates: Today at 7:08 PM**
- C:\\Windows\\SoftwareDistribution folder is now 55 MB

```PowerShell
cls
```

### # Clean up the WinSxS folder

```PowerShell
Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase
```

```PowerShell
cls
```

## # Rebuild SecuritasConnect web application

```PowerShell
cd C:\NotBackedUp\Securitas\ClientPortal\Dev\Lab2\Code\DeploymentFiles\Scripts

$cred1 = Get-Credential "EXTRANET\s-web-client-dev"

$cred2 = Get-Credential "TECHTOOLBOX\svc-sp-ups"

& '.\Rebuild Web Application.ps1' $cred1, $cred2 -Confirm:$false -Verbose
```

```PowerShell
cls
```

### # Activate the "Securitas - Application Settings" feature

```PowerShell
Start-Process `
    "http://client-local.securitasinc.com/_layouts/15/ManageFeatures.aspx"
```

```PowerShell
cls
```

### # Remove object cache user accounts

```PowerShell
$webApp = Get-SPWebApplication http://client-local.securitasinc.com

$webApp.Properties.Remove("portalsuperuseraccount")
$webApp.Properties.Remove("portalsuperreaderaccount")
$webApp.Update()

iisreset
```

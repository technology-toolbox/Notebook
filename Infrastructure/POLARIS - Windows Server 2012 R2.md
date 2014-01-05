# POLARIS (2014-01-05) - Windows Server 2012 R2 Standard

Sunday, January 05, 2014
5:06 AM

```Console
12345678901234567890123456789012345678901234567890123456789012345678901234567890

PowerShell
```

## # Create virtual machine

```PowerShell
$vmName = "POLARIS"

New-VM `
    -Name $vmName `
    -Path C:\NotBackedUp\VMs `
    -MemoryStartupBytes 12GB `
    -SwitchName "Virtual LAN 2 - 192.168.10.x"

Set-VMProcessor -VMName $vmName -Count 4

$sysPrepedImage =
    "\\ICEMAN\VM Library\ws2012std-r2\Virtual Hard Disks\ws2012std-r2.vhd"

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

Convert-VHD `
    -Path $sysPrepedImage `
    -DestinationPath $vhdPath

Set-VHD $vhdPath -PhysicalSectorSizeBytes 4096

Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath

Start-VM $vmName
```

## # Rename the server and join domain

```PowerShell
Rename-Computer -NewName POLARIS -Restart

Add-Computer -DomainName corp.technologytoolbox.com -Restart
```

## # Download PowerShell help files

```PowerShell
Update-Help
```

## # Change drive letter for DVD-ROM

### # To change the drive letter for the DVD-ROM using PowerShell

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
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

Set-NetAdapterAdvancedProperty -Name "LAN 1 - 192.168.10.x" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

ping ICEMAN -f -l 8900
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

## # Add disks for SharePoint storage (Data01 and Log01)

```PowerShell
$vmName = "POLARIS"

Stop-VM $vmName

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Data01.vhdx"

New-VHD -Path $vhdPath -Dynamic -SizeBytes 5GB
Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath -ControllerType SCSI

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Log01.vhdx"

New-VHD -Path $vhdPath -Dynamic -SizeBytes 5GB
Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath -ControllerType SCSI

Start-VM $vmName
```

## # Initialize disks and format volumes

```PowerShell
Get-Disk 1 |
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -UseMaximumSize -DriveLetter D |
    Format-Volume `
        -FileSystem NTFS `
        -NewFileSystemLabel "Data01" `
        -Confirm:$false

Get-Disk 2 |
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -UseMaximumSize -DriveLetter L |
    Format-Volume `
        -FileSystem NTFS `
        -NewFileSystemLabel "Log01" `
        -Confirm:$false
```

## # [STORM] Checkpoint VM - "Baseline Windows Server 2012 R2"

```PowerShell
Checkpoint-VM -Name POLARIS -SnapshotName "Baseline Windows Server 2012 R2"
```

## # Install Windows features for SharePoint 2013

```PowerShell
Install-WindowsFeature `
    NET-WCF-HTTP-Activation45,`
    NET-WCF-TCP-Activation45, `
    NET-WCF-Pipe-Activation45 `
    -Source '\\ICEMAN\Products\Microsoft\Windows Server 2012 R2\Sources\SxS'

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

## # Install prerequisites for SharePoint 2013

```PowerShell
$preReqFiles = `
    "\\iceman\Products\Microsoft\SharePoint 2013\PrerequisiteInstallerFiles"

# SQL Server 2008 R2 SP1 Native Client
& ($preReqFiles + "\sqlncli.msi")

# Microsoft WCF Data Services 5.0
& ($preReqFiles + "\WcfDataServices.exe")

# Microsoft Information Protection and Control Client (MSIPC)
& ($preReqFiles + "\setup_msipc_x64.msi")

# Microsoft Sync Framework Runtime v1.0 SP1 (x64)
& ($preReqFiles + "\Synchronization.msi")

# Windows Identity Extensions
& ($preReqFiles + "\MicrosoftIdentityExtensions-64.msi")
```

If prompted for an alternate path to a folder containing the installation page, in the **Use source** box, type **[\\\\iceman\\Products\\Microsoft\\SharePoint 2013\\PrerequisiteInstallerFiles\\MicrosoftIdentityExtensions-64.msi](\\iceman\Products\Microsoft\SharePoint 2013\PrerequisiteInstallerFiles\MicrosoftIdentityExtensions-64.msi)**.

```PowerShell
# Windows Identity Foundation (KB974405)
#& ($preReqFiles + "\Windows6.1-KB974405-x64.msu")
```

**Attempting to install WIF using the ".msu" file results in an error:**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/93/F12DCE4D04AB5A99AB0E5C1EEEA1DA7E8792A993.png)

**...it turns out the feature is already installed:**

```PowerShell
Get-WindowsFeature Windows-Identity-Foundation

# Windows Server AppFabric
& ($preReqFiles + "\WindowsServerAppFabricSetup_x64.exe") `
    /i CacheClient","CachingService","CacheAdmin /gac

# CU 1 for AppFabric 1.1 (KB2671763)
& ($preReqFiles + "\AppFabric1.1-RTM-KB2671763-x64-ENU.exe")
```

Wait for the AppFabric update to be installed and then restart the computer.

```PowerShell
Restart-Computer
```

### Reference

**How to install SharePoint 2013 on Windows Server 2012 R2**\
Pasted from <[http://iouchkov.wordpress.com/2013/10/19/how-to-install-sharepoint-2013-on-windows-server-2012-r2/](http://iouchkov.wordpress.com/2013/10/19/how-to-install-sharepoint-2013-on-windows-server-2012-r2/)>

## # Checkpoint VM - "Install SharePoint Server 2013"

## # Enable Windows Installer verbose logging (for SharePoint installation)

```PowerShell
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v Debug /t REG_DWORD /d 7 /f

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v Logging /t REG_SZ /d voicewarmupx! /f
```

### References

**Sharepoint Server 2013 installation: why ArpWrite action fails?**\
Pasted from <[http://sharepoint.stackexchange.com/questions/68620/sharepoint-server-2013-installation-why-arpwrite-action-fails](http://sharepoint.stackexchange.com/questions/68620/sharepoint-server-2013-installation-why-arpwrite-action-fails)>

"...steps you can use to gather a Windows Installer verbose log file.."\
Pasted from <[http://blogs.msdn.com/b/astebner/archive/2005/03/29/403575.aspx](http://blogs.msdn.com/b/astebner/archive/2005/03/29/403575.aspx)>

## # Install SharePoint Server 2013

```PowerShell
$imagePath = ("\\iceman\Products\Microsoft\SharePoint 2013\" `
    + "en_sharepoint_server_2013_x64_dvd_1121447.iso")

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$installer = $imageDriveLetter + ':\setup.cmd'

& $installer
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

## # Disable Windows Installer verbose logging

```PowerShell
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v Debug /f

reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v Logging /f
```

## # Delete VM checkpoint subtree - "Baseline Windows Server 2012 R2"

## # Checkpoint VM - "Create SharePoint farm"

## # Create SharePoint farm

```PowerShell
C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts\New-SPFarm.ps1 `
    -DatabaseServer HAVOK
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/64/C5BBCEA497236DC42BBDAF373F73BAD7108E2C64.png)

...

## Configure Service Principal Names for Central Administration

```Console
setspn -A http/polaris.corp.technologytoolbox.com:22182 svc-sharepoint
setspn -A http/polaris:22182 svc-sharepoint
```

**# HACK: Internet Explorer does not specify port number when requesting Kerberos ticket, so add the following SPNs as well:**

```Console
setspn -A http/polaris.corp.technologytoolbox.com svc-sharepoint
setspn -A http/polaris svc-sharepoint
```

**# However, this breaks Server Manager...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5C/4CFE12CC2CBF8CA85DC60BD87437A42EDE98475C.png)

**# ...so remove the SPNs that don't specify a port number (and just browse to Central Admin locally)**

```Console
setspn -D http/polaris.corp.technologytoolbox.com svc-sharepoint
setspn -D http/polaris svc-sharepoint
```

## # Add the SharePoint bin folder to the PATH environment variable

```PowerShell
$sharePointBinFolder = $env:ProgramFiles +
    "\Common Files\Microsoft Shared\web server extensions\15\BIN"

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-PathFolders.ps1 `
    $sharePointBinFolder `
    -EnvironmentVariableTarget "Machine"
```

## Grant DCOM permissions on IIS WAMREG admin Service

### Reference

**Event ID 10016, KB 920783, and the WSS_WPG Group**\
Pasted from <[http://www.technologytoolbox.com/blog/jjameson/archive/2009/10/17/event-id-10016-kb-920783-and-the-wss-wpg-group.aspx](http://www.technologytoolbox.com/blog/jjameson/archive/2009/10/17/event-id-10016-kb-920783-and-the-wss-wpg-group.aspx)>

## Grant DCOM permissions on MSIServer (000C101C-0000-0000-C000-000000000046)

Using the steps in the previous section, grant **Local Launch** and **Local Activation** permissions to the **WSS_ADMIN_WPG** group on the MSIServer application:

**{000C101C-0000-0000-C000-000000000046}**

## # Configure outgoing e-mail settings

```PowerShell
Add-PSSnapin Microsoft.SharePoint.PowerShell

$smtpServer = "smtp.technologytoolbox.com"
$fromAddress = "svc-sharepoint@technologytoolbox.com"
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

## Configure diagnostic logging

![(screenshot)](https://assets.technologytoolbox.com/screenshots/27/0D5793AAB42D036FB5BCC8EFE720E4744F02C627.png)

In the **Trace Log** section, in the **Path** box, type **L:\\Microsoft Shared\\Web Server Extensions\\15\\LOGS\\**.

## Configure usage and health data collection

In the **Usage Data Collection **section, select **Enable usage data collection**.

In the **Usage Data Collection Settings** section, in the **Log file location **box, type **L:\\Microsoft Shared\\Web Server Extensions\\15\\LOGS\\** .

In the **Health Data Collection **section, select **Enable health data collection**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F5/E9F7781E652315847818F0AB52DB84FCB17981F5.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/30/267CF1BCE7FFCB75348074B3B955DA4BFB59FE30.png)

## # Configure State Service

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts\Configure State Service.ps1'
```

## # Create share and configure permissions for SharePoint backups

On ICEMAN, run the following in an elevated command prompt (not PowerShell):

```Console
mkdir "D:\Shares\Backups\SharePoint - POLARIS"

icacls "D:\Shares\Backups\SharePoint - POLARIS" /grant TECHTOOLBOX\svc-sharepoint:(OI)(CI)(F)

icacls "D:\Shares\Backups\SharePoint - POLARIS" /grant TECHTOOLBOX\POLARIS$:(OI)(CI)(F)
```

## # Backup Farm

```PowerShell
Backup-SPFarm `
    -Directory "\\ICEMAN\Backups\SharePoint - POLARIS" `
    -BackupMethod Full
```

## # Delete VM checkpoint - "Create SharePoint farm"

## -- Restore content database for intranet Web application (HAVOK)

## # Restore intranet Web application

```PowerShell
$appPoolCredential = Get-Credential "TECHTOOLBOX\svc-ttweb"

$appPoolAccount = New-SPManagedAccount -Credential $appPoolCredential

$authProvider = New-SPAuthenticationProvider

New-SPWebApplication `
    -ApplicationPool "SharePoint - ttweb80" `-Name "SharePoint - ttweb80" `-ApplicationPoolAccount $appPoolAccount `-AuthenticationProvider $authProvider `-HostHeader "ttweb" `-Port 80

Test-SPContentDatabase -Name WSS_Content_ttweb -WebApplication http://ttweb

Mount-SPContentDatabase -Name WSS_Content_ttweb -WebApplication http://ttweb

Get-SPContentDatabase -WebApplication http://ttweb |
    Where-Object { $_.Name -ne "WSS_Content_ttweb" } |
    Remove-SPContentDatabase
```

## -- Restore content database for team sites (HAVOK)

## # Restore team sites

```PowerShell
$appPoolCredential = Get-Credential "TECHTOOLBOX\svc-web-my-team"

$appPoolAccount = New-SPManagedAccount -Credential $appPoolCredential

$authProvider = New-SPAuthenticationProvider

New-SPWebApplication `
    -ApplicationPool "SharePoint - team80" `-Name "SharePoint - team80" `-ApplicationPoolAccount $appPoolAccount `-AuthenticationProvider $authProvider `-HostHeader "team" `-Port 80

Test-SPContentDatabase -Name WSS_Content_Team1 -WebApplication http://team

Mount-SPContentDatabase -Name WSS_Content_Team1 -WebApplication http://team

Get-SPContentDatabase -WebApplication http://team |
    Where-Object { $_.Name -ne "WSS_Content_Team1" } |
    Remove-SPContentDatabase
```

## -- Restore content database for My Sites (HAVOK)

## # Restore My Sites

```PowerShell
$appPoolAccount = Get-SPManagedAccount "TECHTOOLBOX\svc-web-my-team"

$authProvider = New-SPAuthenticationProvider

New-SPWebApplication `
    -ApplicationPool "SharePoint - my80" `-Name "SharePoint - my80" `-ApplicationPoolAccount $appPoolAccount `-AuthenticationProvider $authProvider `-HostHeader "my" `-Port 80

Test-SPContentDatabase -Name WSS_Content_MySites -WebApplication http://my

Mount-SPContentDatabase -Name WSS_Content_MySites -WebApplication http://my

Get-SPContentDatabase -WebApplication http://my |
    Where-Object { $_.Name -ne "WSS_Content_MySites" } |
    Remove-SPContentDatabase
```

## # Expand VHD

```PowerShell
$vmName = "POLARIS"

Stop-VM $vmName

Resize-VHD `
    "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx" `
    -SizeBytes 45GB

Start-VM $vmName
```

## # Expand C: drive

```PowerShell
$size = (Get-PartitionSupportedSize -DiskNumber 0 -PartitionNumber 2)
Resize-Partition -DiskNumber 0 -PartitionNumber 2 -Size $size.SizeMax
```

## # Create application pool for SharePoint service applications

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts\Configure Service Application Pool.ps1'
```

When prompted for the credentials for the application pool:

1. In the **User name** box, type **TECHTOOLBOX\\svc-spserviceapp**.
2. In the **Password** box, type the password for the service account.

## -- Restore the Managed Metadata Service database (HAVOK)

## # Restore the Managed Metadata Service

```PowerShell
Get-SPServiceInstance |
    Where-Object { $_.TypeName -eq "Managed Metadata Web Service" } |
    Start-SPServiceInstance | Out-Null

$serviceApplicationName = "Managed Metadata Service"

$serviceApp = New-SPMetadataServiceApplication `
    -Name $serviceApplicationName  `
    -ApplicationPool "SharePoint Service Applications" `
    -DatabaseName "ManagedMetadataService"

New-SPMetadataServiceApplicationProxy `
    -Name "$serviceApplicationName Proxy" `
    -ServiceApplication $serviceApp `
    -DefaultProxyGroup
```

## -- Restore the User Profile Service databases (HAVOK)

## # Restore the User Profile Service Application

```PowerShell
Get-SPServiceInstance |
    Where-Object { $_.TypeName -eq "User Profile Service" } |
    Start-SPServiceInstance | Out-Null

$serviceApplicationName = "User Profile Service Application"

$serviceApp = New-SPProfileServiceApplication `
    -Name $serviceApplicationName `
    -ApplicationPool "SharePoint Service Applications" `-ProfileDBName "ProfileDB" `-SocialDBName "SocialDB" `-ProfileSyncDBName "SyncDB"

New-SPProfileServiceApplicationProxy  `
    -Name "$serviceApplicationName Proxy" `
    -ServiceApplication $serviceApp `-DefaultProxyGroup
```

## -- Restore the Secure Store Service database (HAVOK)

## # Restore the Secure Store Service

```PowerShell
Get-SPServiceInstance |
    Where-Object { $_.TypeName -eq "Secure Store Service" } |
    Start-SPServiceInstance | Out-Null

$serviceApplicationName = "Secure Store Service"

$serviceApp = New-SPSecureStoreServiceApplication `
    -Name $serviceApplicationName  `
    -ApplicationPool "SharePoint Service Applications" `
    -DatabaseName "Secure_Store_Service_DB" `-AuditingEnabled

$proxy = New-SPSecureStoreServiceApplicationProxy  `
    -Name "$serviceApplicationName Proxy" `
    -ServiceApplication $serviceApp `
    -DefaultProxyGroup

Update-SPSecureStoreApplicationServerKey `
    -ServiceApplicationProxy $proxy
```

When prompted, type the passphrase for the Secure Store Service.

## # Create Search Service Application

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts\Configure SharePoint 2013 Search.ps1'
```

When prompted for the **Indexing Service Account**, specify the user name (**TECHTOOLBOX\\svc-index**) and corresponding password, and then click **OK**.

## Resolve SCOM alerts due to disk fragmentation

### Alert Name

Logical Disk Fragmentation Level is high

### Alert Description

The disk L: (L:) on computer POLARIS.corp.technologytoolbox.com has high fragmentation level. File Percent Fragmentation value is 100%. Defragmentation recommended: true.

### Resolution

##### # Copy Toolbox content

```PowerShell
robocopy \\iceman\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E
```

##### # Create scheduled task to optimize drives

```PowerShell
[string] $xml = Get-Content `
  'C:\NotBackedUp\Public\Toolbox\Scheduled Tasks\Optimize Drives.xml'

Register-ScheduledTask -TaskName "Optimize Drives" -Xml $xml
```

## Reinstall SharePoint 2013 Service Pack 1 (SP1 rereleased)

## Microsoft bloat (2015-04-28)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FF/8A70280F48E1F90C54FB53AEE04FC6767DC1DCFF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DE/F0CB1430E34364CDDE1FC656B1049D80F5312CDE.png)

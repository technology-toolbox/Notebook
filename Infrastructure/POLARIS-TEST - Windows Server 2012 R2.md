# POLARIS-TEST (2014-01-05) - Windows Server 2012 R2 Standard

Sunday, January 05, 2014
5:06 AM

```Console
12345678901234567890123456789012345678901234567890123456789012345678901234567890

PowerShell
```

## # Create virtual machine

```PowerShell
$vmName = "POLARIS-TEST"

New-VM `
    -Name $vmName `
    -Path C:\NotBackedUp\VMs `
    -MemoryStartupBytes 8GB `
    -SwitchName "Virtual LAN 2 - 192.168.10.x"

Set-VMProcessor -VMName $vmName -Count 4

$sysPrepedImage =
    "\\ICEMAN\VM-Library\VHDs\WS2012-R2-STD.vhdx"

mkdir "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks"

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

Copy-Item $sysPrepedImage $vhdPath

Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath

Start-VM $vmName
```

## # Rename the server and join domain

```PowerShell
Rename-Computer -NewName POLARIS-TEST -Restart

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

![(screenshot)](https://assets.technologytoolbox.com/screenshots/06/37E3980F82E21B260ABBA2EA5CC5232317A21C06.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F5/62817D225C9E0B77EC7D2FFA156A5697866162F5.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EC/A32CEADD7C65691693F1C743BC2329F308411FEC.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/37/D5877113F7713D57FF7BEE522316769EE3681A37.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/94/B6FC333D9F4009163A8D40E990C6098EBA440894.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6F/BE8191D4800C23D900F4311E5A7DA30953D0B76F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3D/4D59965EF1EE04026200372D58F1A9D935E8643D.png)

## Approve manual agent install in Operations Manager

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FA/C14D8B6A59E45CBAF239ACB399ED61EDDA3248FA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FF/63192D56B04BF6CEFF8E673EF7FBE5F779271BFF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/81/74CE9B6DC7A0922F9948D0FF005DB6C56198E981.png)

## # [ROGUE] Add disks for SharePoint storage (Data01 and Log01)

```PowerShell
$vmName = "POLARIS-TEST"

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

## # [ROGUE] Checkpoint VM - "Baseline Windows Server 2012 R2"

```PowerShell
Checkpoint-VM -Name POLARIS-TEST -SnapshotName "Baseline Windows Server 2012 R2"
```

## # Install Windows features for SharePoint 2013

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
    Server-Media-Foundation,Xps-Viewer `-Source '\\ICEMAN\Products\Microsoft\Windows Server 2012 R2\Sources\SxS' `-Restart
```

### Reference

**The Products Preparation Tool in SharePoint Server 2013 may not progress past "Configuring Application Server Role, Web Server (IIS) Role"**\
Pasted from <[http://support.microsoft.com/kb/2765260](http://support.microsoft.com/kb/2765260)>

## # [ROGUE] Insert SharePoint 2013 ISO image into VM

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\SharePoint 2013\" `
    + "en_sharepoint_server_2013_with_sp1_x64_dvd_3823428.iso"

Set-VMDvdDrive -VMName POLARIS-TEST -Path $imagePath
```

## # Install prerequisites for SharePoint 2013

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

## # [ROGUE] Checkpoint VM - "Install SharePoint Server 2013"

```PowerShell
Checkpoint-VM -Name POLARIS-TEST -SnapshotName "Install SharePoint Server 2013"
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

## # [ROGUE] Delete VM checkpoint subtree - "Baseline Windows Server 2012 R2"

```PowerShell
Remove-VMSnapshot `
    -VMName POLARIS-TEST `
    -Name "Baseline Windows Server 2012 R2" `
    -IncludeAllChildSnapshots
```

## # [ROGUE] Checkpoint VM - "Create SharePoint farm"

```PowerShell
Checkpoint-VM -Name POLARIS-TEST -SnapshotName "Create SharePoint farm"
```

## # Copy Toolbox content

```PowerShell
robocopy \\iceman\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E
```

## # Create SharePoint farm

```PowerShell
C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts\New-SPFarm.ps1 `
    -DatabaseServer HAVOK-TEST
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F0/DC948D86544AD34498BB1A233E2A26EC0F6E1DF0.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D5/63A41BB761C5A6E225307ACBFE8657131DDBDAD5.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F4/3C3B831F2536C7B2A662437DEB335DF99B05B4F4.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BE/03DDBB8FBE0422ACA1D7EDF0BE14D79FA9FED7BE.png)

## # Configure Service Principal Names for Central Administration

```PowerShell
setspn -A http/polaris-test.corp.technologytoolbox.com:22182 svc-sharepoint-test
setspn -A http/polaris-test:22182 svc-sharepoint-test
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
$fromAddress = "svc-sharepoint-test@technologytoolbox.com"
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

In the **Trace Log** section, in the **Path** box, type **L:\\Microsoft Shared\\Web Server Extensions\\15\\LOGS\\** .

## Configure usage and health data collection

In the **Usage Data Collection **section, select **Enable usage data collection**.

In the **Event Selection** section, select the following items:\

- **Analytics Usage**
- **App Monitoring**
- **App Statistics.**
- **~~Bandwidth Monitoring~~**
- **Content Export Usage**
- **Content Import Usage**
- **Definition of usage fields for Education telemetry**
- **Definition of usage fields for microblog telemetry**
- **Definition of usage fields for service calls**
- **Definition of usage fields for SPDistributedCache calls**
- **Definition of usage fields for workflow telemetry**
- **Feature Use**
- **File IO**
- **Page Requests**
- **REST and Client API Action Usage**
- **REST and Client API Request Usage**
- **Sandbox Request Resource Measures**
- **Sandbox Requests**
- **~~SQL Exceptions Usage~~**
- **~~SQL IO Usage~~**
- **~~SQL Latency Usage~~**
- **Task Use**
- **~~Tenant Logging~~**
- **Timer Jobs**
- **User Profile ActiveDirectory Import Usage**
- **User Profile to SharePoint Synchronization Usage**\
  \
  In the **Usage Data Collection Settings** section, in the **Log file location **box, type **L:\\Microsoft Shared\\Web Server Extensions\\15\\LOGS\\** .

In the **Health Data Collection **section, select **Enable health data collection**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F5/E9F7781E652315847818F0AB52DB84FCB17981F5.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/61/9DC08D27EA37D0824920E72DC82325D234408161.png)

## # Configure State Service

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts\Configure State Service.ps1'
```

## # Create share and configure permissions for SharePoint backups

On ICEMAN, run the following in an elevated command prompt (not PowerShell):

```Console
mkdir "D:\Shares\Backups\SharePoint - POLARIS-TEST"

icacls "D:\Shares\Backups\SharePoint - POLARIS-TEST" /grant TECHTOOLBOX\svc-sharepoint-test:(OI)(CI)(F)

icacls "D:\Shares\Backups\SharePoint - POLARIS-TEST" /grant TECHTOOLBOX\POLARIS-TEST$:(OI)(CI)(F)
```

## # Backup Farm

```PowerShell
Backup-SPFarm `
    -Directory "\\ICEMAN\Backups\SharePoint - POLARIS-TEST" `
    -BackupMethod Full
```

## # [ROGUE] Delete VM checkpoint - "Create SharePoint farm"

```PowerShell
Remove-VMSnapshot -VMName POLARIS-TEST -Name "Create SharePoint farm"
```

## -- [HAVOK-TEST] Restore content database for intranet Web application

```SQL
RESTORE DATABASE [WSS_Content_ttweb]
 FROM  DISK = N'\\ICEMAN\Backups\HAVOK\WSS_Content_ttweb.bak'
 WITH  FILE = 1
 ,  MOVE N'WSS_Content_ttweb' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\WSS_Content_ttweb.mdf'
 ,  MOVE N'WSS_Content_ttweb_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\WSS_Content_ttweb_log.LDF'
 ,  NOUNLOAD
 ,  STATS = 5
```

## # Restore intranet Web application

```PowerShell
$appPoolCredential = Get-Credential "TECHTOOLBOX\svc-ttweb-test"

$appPoolAccount = New-SPManagedAccount -Credential $appPoolCredential

$authProvider = New-SPAuthenticationProvider

New-SPWebApplication `
    -ApplicationPool "SharePoint - ttweb-test80" `-Name "SharePoint - ttweb-test80" `-ApplicationPoolAccount $appPoolAccount `-AuthenticationProvider $authProvider `-HostHeader "ttweb-test" `-Port 80

Test-SPContentDatabase -Name WSS_Content_ttweb -WebApplication http://ttweb-test

Mount-SPContentDatabase -Name WSS_Content_ttweb -WebApplication http://ttweb-test

Get-SPContentDatabase -WebApplication http://ttweb-test |
    Where-Object { $_.Name -ne "WSS_Content_ttweb" } |
    Remove-SPContentDatabase
```

## -- [HAVOK-TEST] Restore content database for team sites

## # Restore team sites

```PowerShell
$appPoolCredential = Get-Credential "TECHTOOLBOX\svc-web-my-team-test"

$appPoolAccount = New-SPManagedAccount -Credential $appPoolCredential

$authProvider = New-SPAuthenticationProvider

New-SPWebApplication `
    -ApplicationPool "SharePoint - team-test80" `-Name "SharePoint - team-test80" `-ApplicationPoolAccount $appPoolAccount `-AuthenticationProvider $authProvider `-HostHeader "team-test" `-Port 80

Test-SPContentDatabase -Name WSS_Content_Team1 -WebApplication http://team-test

Mount-SPContentDatabase -Name WSS_Content_Team1 -WebApplication http://team-test

Get-SPContentDatabase -WebApplication http://team-test |
    Where-Object { $_.Name -ne "WSS_Content_Team1" } |
    Remove-SPContentDatabase
```

## -- [HAVOK-TEST] Restore content database for My Sites

## # Restore My Sites

```PowerShell
$appPoolAccount = Get-SPManagedAccount "TECHTOOLBOX\svc-web-my-team-test"

$authProvider = New-SPAuthenticationProvider

New-SPWebApplication `
    -ApplicationPool "SharePoint - my-test80" `-Name "SharePoint - my-test80" `-ApplicationPoolAccount $appPoolAccount `-AuthenticationProvider $authProvider `-HostHeader "my-test" `-Port 80

Test-SPContentDatabase -Name WSS_Content_MySites -WebApplication http://my-test

Mount-SPContentDatabase -Name WSS_Content_MySites -WebApplication http://my-test

Get-SPContentDatabase -WebApplication http://my-test |
    Where-Object { $_.Name -ne "WSS_Content_MySites" } |
    Remove-SPContentDatabase
```

## # Create application pool for SharePoint service applications

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts\Configure Service Application Pool.ps1'
```

When prompted for the credentials for the application pool:

1. In the **User name** box, type **TECHTOOLBOX\\svc-spserviceapp-tst**.
2. In the **Password** box, type the password for the service account.

## -- [HAVOK-TEST] Restore the Managed Metadata Service database

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
    -DefaultProxyGroup | Out-Null
```

## -- [HAVOK-TEST] Restore the User Profile Service databases

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
    -ServiceApplication $serviceApp `-DefaultProxyGroup | Out-Null
```

## -- [HAVOK-TEST] Restore the Secure Store Service database

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
```

### Add group to Administrators for service application

![(screenshot)](https://assets.technologytoolbox.com/screenshots/98/7E813613FDA5FC707894B5B17E9FB2D33AA53E98.png)

### Set the key for the Secure Store Service

```PowerShell
Update-SPSecureStoreApplicationServerKey `
    -ServiceApplicationProxy $proxy
```

When prompted, type the passphrase for the Secure Store Service.

## # [ROGUE] Checkpoint VM - "Create Search Service Application"

```PowerShell
Checkpoint-VM `
    -Name POLARIS-TEST `
    -SnapshotName "Create Search Service Application"
```

## # Create Search Service Application

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts\Configure SharePoint 2013 Search.ps1'
```

When prompted for the **Indexing Service Account**, specify the user name (**TECHTOOLBOX\\svc-index-test**) and corresponding password, and then click **OK**.

## # [ROGUE] Delete VM checkpoint - "Create Search Service Application"

```PowerShell
Remove-VMSnapshot -VMName POLARIS-TEST -Name "Create Search Service Application"
```

## # [ROGUE] Expand VHD

```PowerShell
$vmName = "POLARIS-TEST"

Stop-VM $vmName

Resize-VHD `
    "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx" `
    -SizeBytes 40GB

Start-VM $vmName
```

## # Expand C: drive

```PowerShell
$size = (Get-PartitionSupportedSize -DiskNumber 0 -PartitionNumber 2)
Resize-Partition -DiskNumber 0 -PartitionNumber 2 -Size $size.SizeMax
```

## Install Team Foundation Server Extensions for SharePoint Products

Mount the TFS 2013 installation image and open the **Remote SharePoint Extensions** folder.\
Open **tfs_sharePointExtensions.exe**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2C/29D202847FF727FA81F40C8C82CEDBFB7B665C2C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6D/257CEBCB04E29C6DE4DAE4A99A7D5352DFA4FD6D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BC/15F71E41A0278958EB176C85BD5893670B2FE3BC.png)

UAC, click **Yes**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/79/3FDFF5F241662E89F758BAAE8544F604A8050779.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C4/21CF1DADAA03CF99EA0E81842A092457D02E9BC4.png)

## Resolve SCOM alerts due to disk fragmentation

### Alert Name

Logical Disk Fragmentation Level is high

### Alert Description

The disk L: (L:) on computer POLARIS-TEST.corp.technologytoolbox.com has high fragmentation level. File Percent Fragmentation value is 100%. Defragmentation recommended: true.

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

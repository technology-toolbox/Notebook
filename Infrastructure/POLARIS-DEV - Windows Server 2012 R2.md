# POLARIS-DEV (2014-01-04) - Windows Server 2012 R2 Standard

Saturday, January 04, 2014
4:16 PM

```Console
12345678901234567890123456789012345678901234567890123456789012345678901234567890

PowerShell
```

## # Create virtual machine

```PowerShell
$vmName = "POLARIS-DEV"

New-VM `
    -Name $vmName `
    -Path C:\NotBackedUp\VMs `
    -MemoryStartupBytes 8GB `
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
Rename-Computer -NewName POLARIS-DEV -Restart

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

## # Add disks for SQL Server storage (Data01, Log01, Temp01, and Backup01)

```PowerShell
$vmName = "POLARIS-DEV"

Stop-VM $vmName

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Data01.vhdx"

New-VHD -Path $vhdPath -Dynamic -SizeBytes 5GB
Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath -ControllerType SCSI

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Log01.vhdx"

New-VHD -Path $vhdPath -Dynamic -SizeBytes 5GB
Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath -ControllerType SCSI

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Temp01.vhdx"

New-VHD -Path $vhdPath -Dynamic -SizeBytes 2GB
Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath -ControllerType SCSI

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Backup01.vhdx"

New-VHD -Path $vhdPath -Dynamic -SizeBytes 10GB
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
        -AllocationUnitSize 64KB `
        -NewFileSystemLabel "Data01" `
        -Confirm:$false

Get-Disk 2 |
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -UseMaximumSize -DriveLetter L |
    Format-Volume `
        -FileSystem NTFS `
        -AllocationUnitSize 64KB `
        -NewFileSystemLabel "Log01" `
        -Confirm:$false

Get-Disk 3 |
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -UseMaximumSize -DriveLetter T |
    Format-Volume `
        -FileSystem NTFS `
        -AllocationUnitSize 64KB `
        -NewFileSystemLabel "Temp01" `
        -Confirm:$false

Get-Disk 4 |
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -UseMaximumSize -DriveLetter Z |
    Format-Volume `
        -FileSystem NTFS `
        -AllocationUnitSize 64KB `
        -NewFileSystemLabel "Backup01" `
        -Confirm:$false
```

## # Install .NET Framework 3.5

```PowerShell
Install-WindowsFeature `
    NET-Framework-Core `
    -Source '\\ICEMAN\Products\Microsoft\Windows Server 2012 R2\Sources\SxS'
```

## # Install SQL Server 2012 with SP1

**Note: .NET Framework 3.5 is required for SQL Server 2012 Management Tools.**

On the **Feature Selection** step, select:

- **Database Engine Services**
- **Management Tools - Complete**

On the **Server Configuration** step:

- For the **SQL Server Agent** service, change the **Startup Type** to **Automatic**.
- For the **SQL Server Browser** service, leave the **Startup Type** as **Disabled**.

On the **Database Engine Configuration** step:

- On the **Server Configuration** tab, in the **Specify SQL Server administrators** section, click **Add...** and then add the domain group for SQL Server administrators.
- On the **Data Directories** tab:
  - In the **Data root directory** box, type **D:\\Microsoft SQL Server\\**.
  - In the **User database log directory** box, change the drive letter to **L:** (the value should be **L:\\Microsoft SQL Server\\MSSQL11.MSSQLSERVER\\MSSQL\\Data**).
  - In the **Temp DB directory** box, change the drive letter to **T:** (the value should be **T:\\Microsoft SQL Server\\MSSQL11.MSSQLSERVER\\MSSQL\\Data**).
  - In the **Backup directory** box, change the drive letter to **Z:** (the value should be **Z:\\Microsoft SQL Server\\MSSQL11.MSSQLSERVER\\MSSQL\\Backup**).

## # Configure firewall rule for SQL Server

```PowerShell
New-NetFirewallRule `
    -DisplayName "SQL Server Database Engine" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 1433 `-Action Allow
```

## -- Change databases to Simple recovery model

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

### Reference

**Using the Simple Recovery Model for SharePoint Development Environments**\
Pasted from <[http://www.technologytoolbox.com/blog/jjameson/archive/2011/03/19/using-the-simple-recovery-model-for-sharepoint-development-environments.aspx](http://www.technologytoolbox.com/blog/jjameson/archive/2011/03/19/using-the-simple-recovery-model-for-sharepoint-development-environments.aspx)>

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

## # Install DPM 2012 R2 agent

```PowerShell
$imagePath = "\\iceman\Products\Microsoft\System Center 2012 R2\" `
    + "mu_system_center_2012_r2_data_protection_manager_x86_and_x64_dvd_2945939.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$installer = $imageDriveLetter + ":\SCDPM\Agents\DPMAgentInstaller_x64.exe"

& $installer JUGGERNAUT.corp.technologytoolbox.com
```

Review the licensing agreement. If you accept the Microsoft Software License Terms, select **I accept the license terms and conditions**, and then click **OK**.

Confirm the agent installation completed successfully and the following firewall exceptions have been added:

- Exception for DPMRA.exe in all profiles
- Exception for Windows Management Instrumentation service
- Exception for RemoteAdmin service
- Exception for DCOM communication on port 135 (TCP and UDP) in all profiles

### Reference

**Installing Protection Agents Manually**\
Pasted from <[http://technet.microsoft.com/en-us/library/hh757789.aspx](http://technet.microsoft.com/en-us/library/hh757789.aspx)>

## Attach DPM agent

On the DPM server (JUGGERNAUT), open **DPM Management Shell**, and run the following commands:

```PowerShell
$productionServer = "POLARIS-DEV"

.\Attach-ProductionServer.ps1 `
    -DPMServerName JUGGERNAUT `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `-UserName jjameson-admin
```

## Add "Local System" account to SQL Server sysadmin role

On the SQL Server (HAVOK), open SQL Server Management Studio and execute the following:

```SQL
ALTER SERVER ROLE [sysadmin] ADD MEMBER [NT AUTHORITY\SYSTEM]
GO
```

### Reference

**Protection agent jobs may fail for SQL Server 2012 databases**\
Pasted from <[http://technet.microsoft.com/en-us/library/dn281948.aspx](http://technet.microsoft.com/en-us/library/dn281948.aspx)>

## Configure Max Degree of Parallelism

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EF/926CAFE390C10D8FF48C952CAC315CA44236DCEF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/26/59828C332CD5C2E93579D7FCCDE90E7176BCC826.png)

### Reference

Ensure the Max degree of parallelism is set to 1. For additional information about max degree of parallelism see, [Configure the max degree of parallism Server Configuration option](Configure the max degree of parallism Server Configuration option) and [Degree of Parallelism](Degree of Parallelism).

Pasted from <[http://technet.microsoft.com/en-us/library/ee805948.aspx](http://technet.microsoft.com/en-us/library/ee805948.aspx)>

## # [STORM] Checkpoint VM - "Baseline Windows Server 2012 R2/SQL Server 2012 SP1"

```PowerShell
Checkpoint-VM `
    -Name POLARIS-DEV `
    -SnapshotName "Baseline Windows Server 2012 R2/SQL Server 2012 SP1"
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

## # Delete VM checkpoint subtree - "Baseline Windows Server 2012 R2/SQL Server 2012 SP1"

## # Checkpoint VM - "Create SharePoint farm"

## # Copy Toolbox content

```PowerShell
robocopy \\iceman\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E
```

## # Create SharePoint farm

```PowerShell
C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts\New-SPFarm.ps1 `
    -DatabaseServer POLARIS-DEV
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D6/073B5DFE8AAA57BB4B7814099FC81A378C594DD6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/11/3B5BD7C7FBA44A0EDDD9663F5BD03A3DE9854011.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A8/354DCE8D25BAB4A37705BD272CD798E5F8E7A1A8.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FC/299903BC1C111059B1542212127423BD60B877FC.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/97/4434E9CFB4215766A140F5FB5F5AF302DAABA797.png)

## # Configure Service Principal Names for Central Administration

```PowerShell
setspn -A http/polaris-dev.corp.technologytoolbox.com:22182 svc-sharepoint-dev
setspn -A http/polaris-dev:22182 svc-sharepoint-dev
```

**# HACK: Internet Explorer does not specify port number when requesting Kerberos ticket, so add the following SPNs as well:**

```Console
setspn -A http/polaris-dev.corp.technologytoolbox.com svc-sharepoint-dev
setspn -A http/polaris-dev svc-sharepoint-dev
```

**# However, this breaks Server Manager...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E3/6199F08A5792638E861C6410D206B37DB5F4FDE3.png)

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

## Configure diagnostic logging

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1B/0A705BB3E6F86829674CBF5E80E97E6C7A77E61B.png)

In the **Trace Log** section:

- In the **Path** box, type **L:\\Microsoft Shared\\Web Server Extensions\\15\\LOGS\\**.
- In the **Number of days** to store log files box, type **7**.

## Configure usage and health data collection

In the **Usage Data Collection **section, select **Enable usage data collection**.

In the **Usage Data Collection Settings** section, in the **Log file location **box, type **L:\\Microsoft Shared\\Web Server Extensions\\15\\LOGS\\**.

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
mkdir "D:\Shares\Backups\SharePoint - POLARIS-DEV"

icacls "D:\Shares\Backups\SharePoint - POLARIS-DEV" /grant TECHTOOLBOX\svc-sharepoint-dev:(OI)(CI)(F)

icacls "D:\Shares\Backups\SharePoint - POLARIS-DEV" /grant TECHTOOLBOX\POLARIS-DEV$:(OI)(CI)(F)
```

## # Backup Farm

```PowerShell
Backup-SPFarm `
    -Directory "\\ICEMAN\Backups\SharePoint - POLARIS-DEV" `
    -BackupMethod Full
```

## # Delete VM checkpoint - "Create SharePoint farm"

## Fix permissions to avoid "ESENT" errors in event log

Log Name:      Application\
Source:        ESENT\
Date:          1/11/2014 12:04:33 PM\
Event ID:      490\
Task Category: General\
Level:         Error\
Keywords:      Classic\
User:          N/A\
Computer:      POLARIS-DEV.corp.technologytoolbox.com\
Description:\
sqlservr (1472) An attempt to open the file "C:\\Windows\\system32\\LogFiles\\Sum\\Api.chk" for read / write access failed with system error 5 (0x00000005): "Access is denied. ".  The open file operation will fail with error -1032 (0xfffffbf8).\
Event Xml:\
<Event xmlns="[http://schemas.microsoft.com/win/2004/08/events/event](http://schemas.microsoft.com/win/2004/08/events/event)">\
  `<System>`\
    `<Provider Name="ESENT" />`\
    `<EventID Qualifiers="0">`490`</EventID>`\
    `<Level>`2`</Level>`\
    `<Task>`1`</Task>`\
    `<Keywords>`0x80000000000000`</Keywords>`\
    `<TimeCreated SystemTime="2014-01-14T19:04:33.000000000Z" />`\
    `<EventRecordID>`2181`</EventRecordID>`\
    `<Channel>`Application`</Channel>`\
    `<Computer>`POLARIS-DEV.corp.technologytoolbox.com`</Computer>`\
    `<Security />`\
  `</System>`\
  `<EventData>`\
    `<Data>`sqlservr`</Data>`\
    `<Data>`1472`</Data>`\
    `<Data>`\
    `</Data>`\
    `<Data>`C:\\Windows\\system32\\LogFiles\\Sum\\Api.chk`</Data>`\
    `<Data>`-1032 (0xfffffbf8)`</Data>`\
    `<Data>`5 (0x00000005)`</Data>`\
    `<Data>`Access is denied. `</Data>`\
  `</EventData>`\
`</Event>`

```Console
icacls C:\Windows\System32\LogFiles\Sum\Api.chk /grant "NT Service\MSSQLSERVER":(M)

icacls C:\Windows\System32\LogFiles\Sum\Api.log /grant "NT Service\MSSQLSERVER":(M)

icacls C:\Windows\System32\LogFiles\Sum\SystemIdentity.mdb /grant "NT Service\MSSQLSERVER":(M)

icacls C:\Windows\System32\LogFiles\Sum\Api.chk /grant "NT Service\MSSQLServerOLAPService":(M)

icacls C:\Windows\System32\LogFiles\Sum\Api.log /grant "NT Service\MSSQLServerOLAPService":(M)

icacls C:\Windows\System32\LogFiles\Sum\SystemIdentity.mdb /grant "NT Service\MSSQLServerOLAPService":(M)
```

### Reference

**Error 1032 messages in the Application log in Windows Server 2012**\
Pasted from <[http://support.microsoft.com/kb/2811566](http://support.microsoft.com/kb/2811566)>

## -- Restore content database for intranet Web application

```SQL
RESTORE DATABASE [WSS_Content_ttweb] FROM  DISK = N'\\iceman\Archive\BEAST\NotBackedUp\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\Full\WSS_Content_ttweb_backup_2014_01_04_064316_3783309.bak' WITH  FILE = 1,  MOVE N'WSS_Content_ttweb' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\WSS_Content_ttweb.mdf',  MOVE N'WSS_Content_ttweb_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\WSS_Content_ttweb_log.LDF',  NOUNLOAD,  STATS = 5
```

## # Restore intranet Web application

```PowerShell
$appPoolCredential = Get-Credential "TECHTOOLBOX\svc-ttweb-dev"

$appPoolAccount = New-SPManagedAccount -Credential $appPoolCredential

$authProvider = New-SPAuthenticationProvider

New-SPWebApplication `
    -ApplicationPool "SharePoint - ttweb-dev80" `-Name "SharePoint - ttweb-dev80" `-ApplicationPoolAccount $appPoolAccount `-AuthenticationProvider $authProvider `-HostHeader "ttweb-dev" `-Port 80

Test-SPContentDatabase -Name WSS_Content_ttweb -WebApplication http://ttweb-dev

Mount-SPContentDatabase -Name WSS_Content_ttweb -WebApplication http://ttweb-dev

Get-SPContentDatabase -WebApplication http://ttweb-dev |
    Where-Object { $_.Name -ne "WSS_Content_ttweb" } |
    Remove-SPContentDatabase
```

## -- Restore content database for team sites

```SQL
RESTORE DATABASE [WSS_Content_Team1] FROM  DISK = N'\\iceman\Archive\BEAST\NotBackedUp\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\Full\WSS_Content_Team1_backup_2014_01_04_064316_3627095.bak' WITH  FILE = 1,  MOVE N'WSS_Content_Team1' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\WSS_Content_Team1.mdf',  MOVE N'WSS_Content_Team1_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\WSS_Content_Team1_1.LDF',  NOUNLOAD,  STATS = 5

RESTORE DATABASE [WSS_Content_TFS] FROM  DISK = N'\\iceman\Archive\BEAST\NotBackedUp\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\Full\WSS_Content_TFS_backup_2014_01_04_064316_3627095.bak' WITH  FILE = 1,  MOVE N'STS_Content_TFS' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\WSS_Content_TFS.mdf',  MOVE N'ftrow_ix_STS_Content_TFS' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\WSS_Content_TFS_1.ndf',  MOVE N'STS_Content_TFS_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\WSS_Content_TFS_2.ldf',  NOUNLOAD,  STATS = 5
```

## # Restore team sites

```PowerShell
$appPoolCredential = Get-Credential "TECHTOOLBOX\svc-web-my-team-dev"

$appPoolAccount = New-SPManagedAccount -Credential $appPoolCredential

$authProvider = New-SPAuthenticationProvider

New-SPWebApplication `
    -ApplicationPool "SharePoint - team-dev80" `-Name "SharePoint - team-dev80" `-ApplicationPoolAccount $appPoolAccount `-AuthenticationProvider $authProvider `-HostHeader "team-dev" `-Port 80

Test-SPContentDatabase -Name WSS_Content_Team1 -WebApplication http://team-dev

Mount-SPContentDatabase -Name WSS_Content_Team1 -WebApplication http://team-dev

Get-SPContentDatabase -WebApplication http://team-dev |
    Where-Object { $_.Name -ne "WSS_Content_Team1" } |
    Remove-SPContentDatabase

Test-SPContentDatabase -Name WSS_Content_TFS -WebApplication http://team-dev

Mount-SPContentDatabase -Name WSS_Content_TFS -WebApplication http://team-dev
```

## -- Restore content database for My Sites

```SQL
RESTORE DATABASE [WSS_Content_MySites] FROM  DISK = N'\\iceman\Archive\BEAST\NotBackedUp\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\Full\WSS_Content_MySites_backup_2014_01_04_064316_3627095.bak' WITH  FILE = 1,  MOVE N'WSS_Content_MySites' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\WSS_Content_MySites.mdf',  MOVE N'WSS_Content_MySites_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\WSS_Content_MySites_log.LDF',  NOUNLOAD,  STATS = 5
```

## # Restore My Sites

```PowerShell
$appPoolAccount = Get-SPManagedAccount "TECHTOOLBOX\svc-web-my-team-dev"

$authProvider = New-SPAuthenticationProvider

New-SPWebApplication `
    -ApplicationPool "SharePoint - my-dev80" `-Name "SharePoint - my-dev80" `-ApplicationPoolAccount $appPoolAccount `-AuthenticationProvider $authProvider `-HostHeader "my-dev" `-Port 80

Test-SPContentDatabase -Name WSS_Content_MySites -WebApplication http://my-dev

Mount-SPContentDatabase -Name WSS_Content_MySites -WebApplication http://my-dev

Get-SPContentDatabase -WebApplication http://my-dev |
    Where-Object { $_.Name -ne "WSS_Content_MySites" } |
    Remove-SPContentDatabase
```

## # Expand VHD

```PowerShell
$vmName = "POLARIS-DEV"

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

1. In the **User name** box, type **TECHTOOLBOX\\svc-spserviceapp-dev**.
2. In the **Password** box, type the password for the service account.

## -- Restore the Managed Metadata Service database

```SQL
RESTORE DATABASE [ManagedMetadataService] FROM  DISK = N'\\iceman\Archive\BEAST\NotBackedUp\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\Full\ManagedMetadataService_backup_2014_01_04_064316_3314531.bak' WITH  FILE = 1,  MOVE N'ManagedMetadataService' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\ManagedMetadataService.mdf',  MOVE N'ManagedMetadataService_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\ManagedMetadataService_log.ldf',  NOUNLOAD,  STATS = 5
```

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

## -- Restore the User Profile Service databases

```SQL
RESTORE DATABASE [ProfileDB] FROM  DISK = N'\\iceman\Archive\BEAST\NotBackedUp\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\Full\ProfileDB_backup_2014_01_04_064316_4095824.bak' WITH  FILE = 1,  MOVE N'ProfileDB' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\ProfileDB.mdf',  MOVE N'ProfileDB_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\ProfileDB_log.ldf',  NOUNLOAD,  STATS = 5

RESTORE DATABASE [SocialDB] FROM  DISK = N'\\iceman\Archive\BEAST\NotBackedUp\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\Full\SocialDB_backup_2014_01_04_064316_4252085.bak' WITH  FILE = 1,  MOVE N'SocialDB' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\SocialDB.mdf',  MOVE N'SocialDB_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\SocialDB_log.ldf',  NOUNLOAD,  STATS = 5

RESTORE DATABASE [SyncDB] FROM  DISK = N'\\iceman\Archive\BEAST\NotBackedUp\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\Full\SyncDB_backup_2014_01_04_064316_4095824.bak' WITH  FILE = 1,  MOVE N'SyncDB' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\SyncDB.mdf',  MOVE N'SyncDB_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\SyncDB_log.ldf',  NOUNLOAD,  STATS = 5
```

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

## -- Restore the Secure Store Service database

```SQL
RESTORE DATABASE [Secure_Store_Service_DB] FROM  DISK = N'\\iceman\Archive\BEAST\NotBackedUp\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\Full\Secure_Store_Service_DB_backup_2014_01_04_064316_4252085.bak' WITH  FILE = 1,  MOVE N'Secure_Store_Service_DB' TO N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\Secure_Store_Service_DB.mdf',  MOVE N'Secure_Store_Service_DB_log' TO N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\Secure_Store_Service_DB_log.ldf',  NOUNLOAD,  STATS = 5

GO

USE [Secure_Store_Service_DB]
GO
CREATE USER [TECHTOOLBOX\svc-spserviceapp-dev]
GO
ALTER ROLE [SPDataAccess] ADD MEMBER [TECHTOOLBOX\svc-spserviceapp-dev]
GO
```

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

## # Checkpoint VM - "Create Search Service Application"

## # Create Search Service Application

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts\Configure SharePoint 2013 Search.ps1'
```

When prompted for the **Indexing Service Account**, specify the user name (**TECHTOOLBOX\\svc-index-dev**) and corresponding password, and then click **OK**.

## # Change retention period for Usage and Health Data Collection service application

```PowerShell
Get-SPUsageDefinition  |
    ForEach-Object { Set-SPUsageDefinition $_ -DaysRetained 3 }

Get-SPTimerJob | Where-Object { $_.Title -like "*usage data*" } |
    Start-SPTimerJob
```

### Reference

**How to tame your WSS_Logging database size on a test SharePoint 2013 server**\
Pasted from <[http://www.toddklindt.com/blog/Lists/Posts/Post.aspx?ID=400](http://www.toddklindt.com/blog/Lists/Posts/Post.aspx?ID=400)>

## -- Shrink WSS_Logging database

```SQL
USE [WSS_Logging]
GO
DBCC SHRINKDATABASE(N'WSS_Logging' )
GO
```

## Resolve SCOM alerts due to disk fragmentation

### Alert Name

Logical Disk Fragmentation Level is high

### Alert Description

The disk C: (C:) on computer POLARIS-DEV.corp.technologytoolbox.com has high fragmentation level. File Percent Fragmentation value is 12%. Defragmentation recommended: true.

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

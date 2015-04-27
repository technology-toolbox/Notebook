# POLARIS-DEV (2015-04-26) - Windows Server 2012 R2 Standard

Sunday, April 26, 2015
2:00 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Create VM

- Processors: **4**
- Memory: **8 GB**
- VHD size (GB): **50**
- VHD file name:** POLARIS-DEV**

## Install custom SharePoint 2013 development image

- Start-up disk: [\\\\ICEMAN\\Products\\Microsoft\\MDT-Deploy-x86.iso](\\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso)
- On the **Task Sequence** step, select **SharePoint Server 2013 - Development** and click **Next**.
- On the **Computer Details** step, in the **Computer name** box, type **POLARIS-DEV** and click **Next**.
- On the Applications step:
  - Select the following items:
    - Adobe
      - **Adobe Reader 8.3.1**
    - Google
      - **Chrome**
    - Mozilla
      - **Firefox 36.0**
      - **Thunderbird 31.3.0**
  - Click **Next**.

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
| 0    | C:           | 50 GB       | 4K                   | OSDisk       |
| 1    | D:           | 2 GB        | 64K                  | Data01       |
| 2    | L:           | 1 GB        | 64K                  | Log01        |
| 3    | T:           | 1 GB        | 64K                  | Temp01       |
| 4    | Z:           | 10 GB       | 4K                   | Backup01     |

---

**FORGE**

### # Create Data01, Log01, Temp01, and Backup01 VHDs

```PowerShell
$vmName = "POLARIS-DEV"

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName" `
    + "_Data01.vhdx"

New-VHD -Path $vhdPath -SizeBytes 2GB
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

## Complete installation of SQL Server 2014 installation

> **Important**
>
> If you attempt to complete the installation of SQL Server using the shortcut provided on the start menu, the product key is not specified by default. To ensure the MSDN product key is specified, complete the SQL Server installation from the corresponding MSDN media.

1. Insert the installation ISO for SQL Server 2014 into the virtual DVD drive and launch the setup program.
2. When prompted by UAC to allow the program to make changes to the computer, click **Yes**.
3. In the **SQL Server Installation Center** window, on the **Advanced** page, click **Image completion of a prepared stand-alone instance of SQL Server**.
4. In the **Complete Image of SQL Server 2014** window:
   1. On the **Product Key** step, ensure **Enter the product key** is selected and a product key is specified by default, and click **Next**.
   2. On the **License Terms** step, review the software license terms, click **I accept the license terms**, and click **Next**.
   3. On the **Microsoft Update** step, select **Use Microsoft Update to check for updates (recommended)**, and click **Next**.
   4. On the **Complete Image Rules** step, ensure the only warning is for Windows Firewall, and click **Next**.
   5. On the **Select Prepared Features** step, ensure **Complete a prepared instance of SQL Server 2014** is selected, and click **Next**.
   6. On the **Feature Review** step:
      1. Ensure the following items are selected:
         - **Database Engine Services**
         - **Management Tools - Complete**
           - **Management Tools - Complete**
         - **SQL Client Connectivity SDK**
      2. Click** Next**.
   7. On the **Instance Configuration** step, select **Default instance**, and click **Next**.
   8. On the **Server Configuration** step:
      - For the **SQL Server Agent** service, change the **Startup Type** to **Automatic**.
      - For the **SQL Server Browser** service, leave the **Startup Type** as **Disabled**.
      - Click **Next**.
   9. On the **Database Engine Configuration** step:
      - On the **Server Configuration** tab, in the **Specify SQL Server administrators** section, click **Add...** and then add the domain group for SQL Server administrators.
      - On the **Data Directories** tab:
        - In the **Data root directory** box, type **D:\\Microsoft SQL Server\\**.
        - In the **User database log directory** box, change the drive letter to **L:** (the value should be **L:\\Microsoft SQL Server\\MSSQL11.MSSQLSERVER\\MSSQL\\Data**).
        - In the **Temp DB directory** box, change the drive letter to **T:** (the value should be **T:\\Microsoft SQL Server\\MSSQL11.MSSQLSERVER\\MSSQL\\Data**).
        - In the **Backup directory** box, change the drive letter to **Z:** (the value should be **Z:\\Microsoft SQL Server\\MSSQL11.MSSQLSERVER\\MSSQL\\Backup**).
      - Click **Next**.
   10. On the **Read to Complete Image** step, click **Complete**.

```PowerShell
cls
```

## # Configure firewall rule for SQL Server

```PowerShell
New-NetFirewallRule `
    -DisplayName "SQL Server Database Engine" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 1433 `-Action Allow
```

## Fix permissions to avoid "ESENT" errors in event log

```Console
icacls C:\Windows\System32\LogFiles\Sum\Api.chk /grant "NT Service\MSSQLSERVER":(M)

icacls C:\Windows\System32\LogFiles\Sum\Api.log /grant "NT Service\MSSQLSERVER":(M)

icacls C:\Windows\System32\LogFiles\Sum\SystemIdentity.mdb /grant "NT Service\MSSQLSERVER":(M)
```

---

**Example**

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

---

### Reference

**Error 1032 messages in the Application log in Windows Server 2012**\
Pasted from <[http://support.microsoft.com/kb/2811566](http://support.microsoft.com/kb/2811566)>

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

## DEV - Constrain maximum memory for SQL Server

### -- Set maximum memory for SQL Server to 1 GB

```Console
EXEC sys.sp_configure N'show advanced options', N'1'  RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'max server memory (MB)', N'1024'
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

---

**FORGE**

## # Checkpoint VM - "Baseline SharePoint Server 2013 configuration"

```PowerShell
Stop-VM POLARIS-DEV

Checkpoint-VM `
    -Name POLARIS-DEV `
    -SnapshotName "Baseline SharePoint Server 2013 configuration"

Start-VM POLARIS-DEV
```

---

## Create service accounts for SharePoint

---

**XAVIER1**

### # Create the SharePoint farm service account (DEV)

```PowerShell
$displayName = "Service account for SharePoint farm (DEV)"
$defaultUserName = "s-sharepoint-dev"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@corp.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=Development,DC=corp,DC=technologytoolbox,DC=com"

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

### # Create the service account for SharePoint service applications (DEV)

```PowerShell
$displayName = "Service account for SharePoint service applications (DEV)"
$defaultUserName = "s-spserviceapp-dev"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@corp.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=Development,DC=corp,DC=technologytoolbox,DC=com"

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

### # Create the service account for indexing content (DEV)

```PowerShell
$displayName = "Service account for indexing content (DEV)"
$defaultUserName = "s-index-dev"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@corp.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=Development,DC=corp,DC=technologytoolbox,DC=com"

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

### # Create the service account for intranet websites (DEV)

```PowerShell
$displayName = "Service account for intranet websites (DEV)"
$defaultUserName = "s-web-intranet-dev"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@corp.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=Development,DC=corp,DC=technologytoolbox,DC=com"

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

### # Create the service account for SharePoint My Sites and Team sites (DEV)

```PowerShell
$displayName = 'Service account for SharePoint "my" sites and team sites (DEV)'
$defaultUserName = "s-web-my-team-dev"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@corp.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=Development,DC=corp,DC=technologytoolbox,DC=com"

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

& '.\Create Farm.ps1'
```

When prompted for the credentials for the farm service account:

1. In the **User name** box, type **TECHTOOLBOX\\s-sharepoint-dev**.
2. In the **Password** box, type the password for the service account.

When prompted for the **Passphrase**, type a passphrase that meets the following criteria:

- Contains at least eight characters
- Contains at least three of the following four character groups:
- English uppercase characters (from A through Z)
- English lowercase characters (from a through z)
- Numerals (from 0 through 9)
- Nonalphabetic characters (such as !, \$, #, %)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3E/08186F17F60E82A1844B0BD02D0C972BF851333E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A2/FDA1888FC8EA7331AE366E4121596AEDE00F0BA2.png)

```PowerShell
cls
```

### # Configure Service Principal Names for Central Administration

```PowerShell
setspn -A http/polaris-dev.corp.technologytoolbox.com:22812 s-sharepoint-dev
setspn -A http/polaris-dev:22812 s-sharepoint-dev
```

**HACK: Internet Explorer does not specify port number when requesting Kerberos ticket, so add the following SPNs as well:**

```Console
setspn -A http/polaris-dev.corp.technologytoolbox.com s-sharepoint-dev
setspn -A http/polaris-dev s-sharepoint-dev
```

**However, this breaks Server Manager...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E3/6199F08A5792638E861C6410D206B37DB5F4FDE3.png)

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
Set-SPDiagnosticConfig -DaysToKeepLogs 3

Set-SPDiagnosticConfig -LogDiskSpaceUsageGB 1 -LogMaxDiskSpaceUsageEnabled:$true
```

```PowerShell
cls
```

### # Configure usage and health data collection

```PowerShell
Set-SPUsageService -LoggingEnabled 1

New-SPUsageApplication
```

```PowerShell
cls
```

### # Change retention period for Usage and Health Data Collection service application

```PowerShell
Get-SPUsageDefinition  |
    ForEach-Object { Set-SPUsageDefinition $_ -DaysRetained 3 }

Get-SPTimerJob |
    Where-Object {
        $_.Title -eq "Microsoft SharePoint Foundation Usage Data Import" } |
    Start-SPTimerJob
```

### Reference

**How to tame your WSS_Logging database size on a test SharePoint 2013 server**\
Pasted from <[http://www.toddklindt.com/blog/Lists/Posts/Post.aspx?ID=400](http://www.toddklindt.com/blog/Lists/Posts/Post.aspx?ID=400)>

```PowerShell
cls
```

### # Configure outgoing e-mail settings

```PowerShell
Add-PSSnapin Microsoft.SharePoint.PowerShell

$smtpServer = "smtp.technologytoolbox.com"
$fromAddress = "s-sharepoint-dev@technologytoolbox.com"
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
mkdir "D:\Shares\Backups\SharePoint - POLARIS-DEV"

icacls "D:\Shares\Backups\SharePoint - POLARIS-DEV" /grant "TECHTOOLBOX\s-sharepoint-dev:(OI)(CI)(F)"

icacls "D:\Shares\Backups\SharePoint - POLARIS-DEV" /grant "TECHTOOLBOX\POLARIS-DEV`$:(OI)(CI)(F)"
```

---

```PowerShell
cls
```

### # Backup farm

```PowerShell
Backup-SPFarm `
    -Directory "\\ICEMAN\Backups\SharePoint - POLARIS-DEV" `
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

```PowerShell
cls
```

## # Configure service applications

### # DEV - Constrain Distributed Cache service

```PowerShell
Update-SPDistributedCacheSize -CacheSizeInMB 150
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

1. In the **User name** box, type **TECHTOOLBOX\\s-spserviceapp-dev**.
2. In the **Password** box, type the password for the service account.

```PowerShell
cls
```

### # Configure SharePoint Search

```PowerShell
& '.\Configure SharePoint 2013 Search.ps1'
```

When prompted for the credentials for the default content access account:

1. In the **User name** box, type **TECHTOOLBOX\\s-index-dev**.
2. In the **Password** box, type the password for the service account.

```PowerShell
cls
```

### # Restore Managed Metadata Service

#### -- Restore service application database from production

```Console
RESTORE DATABASE [ManagedMetadataService]
    FROM DISK = N'\\ICEMAN\Backups\HAVOK\ManagedMetadataService.bak'
    WITH FILE = 1
    , MOVE N'ManagedMetadataService' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\ManagedMetadataService.mdf'
    , MOVE N'ManagedMetadataService_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\ManagedMetadataService_log.LDF'
    , NOUNLOAD
    , STATS = 5
```

```Console
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

#### -- Restore service application databases from production

```Console
RESTORE DATABASE [UserProfileService_Profile]
    FROM DISK = N'\\ICEMAN\Backups\HAVOK\ProfileDB.bak'
    WITH FILE = 1
    , MOVE N'ProfileDB' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\UserProfileService_Profile.mdf'
    , MOVE N'ProfileDB_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\UserProfileService_Profile_log.LDF'
    , NOUNLOAD
    , STATS = 5

RESTORE DATABASE [UserProfileService_Social]
    FROM DISK = N'\\ICEMAN\Backups\HAVOK\SocialDB.bak'
    WITH FILE = 1
    , MOVE N'SocialDB' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\UserProfileService_Social.mdf'
    , MOVE N'SocialDB_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\UserProfileService_Social_log.LDF'
    , NOUNLOAD
    , STATS = 5

RESTORE DATABASE [UserProfileService_Sync]
    FROM DISK = N'\\ICEMAN\Backups\HAVOK\SyncDB.bak'
    WITH FILE = 1
    , MOVE N'SyncDB' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\UserProfileService_Sync.mdf'
    , MOVE N'SyncDB_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\UserProfileService_Sync_log.LDF'
    , NOUNLOAD
    , STATS = 5
```

```Console
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

#### -- Restore service application database from production

```SQL
RESTORE DATABASE [SecureStoreService]
    FROM DISK = N'\\ICEMAN\Backups\HAVOK\Secure_Store_Service_DB.bak'
    WITH FILE = 1
    , MOVE N'Secure_Store_Service_DB' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\SecureStoreService.mdf'
    , MOVE N'Secure_Store_Service_DB_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\SecureStoreService_log.ldf'
    , NOUNLOAD
    , STATS = 5

GO
```

#### -- Add service account to database

```SQL
USE [SecureStoreService]
GO
CREATE USER [TECHTOOLBOX\s-spserviceapp-dev]
GO
ALTER ROLE [SPDataAccess] ADD MEMBER [TECHTOOLBOX\s-spserviceapp-dev]
GO
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

#### # Add domain group to Administrators for service application

```PowerShell
$principal = New-SPClaimsPrincipal "SharePoint Admins (DEV)" `
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

## # Restore Web application - http://ttweb-dev

```PowerShell
cls
```

### # Create Web application

```PowerShell
$appPoolCredential = Get-Credential "TECHTOOLBOX\s-web-intranet-dev"

$appPoolAccount = New-SPManagedAccount -Credential $appPoolCredential

$authProvider = New-SPAuthenticationProvider

New-SPWebApplication `
    -ApplicationPool "SharePoint - ttweb-dev80" `
    -Name "SharePoint - ttweb-dev80" `
    -ApplicationPoolAccount $appPoolAccount `
    -AuthenticationProvider $authProvider `
    -HostHeader "ttweb-dev" `
    -Port 80
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3C/E41717DE0ABA51E9A18489CF55E181D8BF52E93C.png)

### -- Restore content database from production

```Console
RESTORE DATABASE [WSS_Content_ttweb]
    FROM DISK = N'\\ICEMAN\Backups\HAVOK\WSS_Content_ttweb.bak'
    WITH FILE = 1
    , MOVE N'WSS_Content_ttweb' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\WSS_Content_ttweb.mdf'
    , MOVE N'WSS_Content_ttweb_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\WSS_Content_ttweb_log.LDF'
    , NOUNLOAD
    , STATS = 5
```

```Console
cls
```

### # Add content database to Web application

```PowerShell
Test-SPContentDatabase -Name WSS_Content_ttweb -WebApplication http://ttweb-dev

Mount-SPContentDatabase -Name WSS_Content_ttweb -WebApplication http://ttweb-dev
```

```PowerShell
cls
```

### # Remove default content database created with Web application

```PowerShell
Get-SPContentDatabase -WebApplication http://ttweb-dev |
    Where-Object { $_.Name -ne "WSS_Content_ttweb" } |
    Remove-SPContentDatabase
```

```PowerShell
cls
```

## # Restore Web application - http://team-dev

```PowerShell
cls
```

### # Create Web application

```PowerShell
$appPoolCredential = Get-Credential "TECHTOOLBOX\s-web-my-team-dev"

$appPoolAccount = New-SPManagedAccount -Credential $appPoolCredential

$authProvider = New-SPAuthenticationProvider

New-SPWebApplication `
    -ApplicationPool "SharePoint - my-team-dev80" `
    -Name "SharePoint - team-dev80" `
    -ApplicationPoolAccount $appPoolAccount `
    -AuthenticationProvider $authProvider `
    -HostHeader "team-dev" `
    -Port 80
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5C/1835B3BB4604787F6622E49778F8CB747DFF825C.png)

### -- Restore content database from production

```Console
RESTORE DATABASE [WSS_Content_Team1]
    FROM DISK = N'\\ICEMAN\Backups\HAVOK\WSS_Content_Team1.bak'
    WITH FILE = 1
    , MOVE N'WSS_Content_Team1' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\WSS_Content_Team1.mdf'
    , MOVE N'WSS_Content_Team1_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\WSS_Content_Team1_log.LDF'
    , NOUNLOAD
    , STATS = 5
```

```Console
cls
```

### # Add content database to Web application

```PowerShell
Test-SPContentDatabase -Name WSS_Content_Team1 -WebApplication http://team-dev

Mount-SPContentDatabase -Name WSS_Content_Team1 -WebApplication http://team-dev
```

```PowerShell
cls
```

### # Remove default content database created with Web application

```PowerShell
Get-SPContentDatabase -WebApplication http://team-dev |
    Where-Object { $_.Name -ne "WSS_Content_Team1" } |
    Remove-SPContentDatabase
```

```PowerShell
cls
```

## # Restore Web application - http://my-dev

```PowerShell
cls
```

### # Create Web application

```PowerShell
$appPoolAccount = Get-SPManagedAccount "TECHTOOLBOX\s-web-my-team-dev"

$authProvider = New-SPAuthenticationProvider

New-SPWebApplication `
    -ApplicationPool "SharePoint - my-team-dev80" `
    -Name "SharePoint - my-dev80" `
    -AuthenticationProvider $authProvider `
    -HostHeader "my-dev" `
    -Port 80
```

### -- Restore content database from production

```Console
RESTORE DATABASE [WSS_Content_MySites]
    FROM DISK = N'\\ICEMAN\Backups\HAVOK\WSS_Content_MySites.bak'
    WITH FILE = 1
    , MOVE N'WSS_Content_MySites' TO N'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\WSS_Content_MySites.mdf'
    , MOVE N'WSS_Content_MySites_log' TO N'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\WSS_Content_MySites_log.LDF'
    , NOUNLOAD
    , STATS = 5
```

```Console
cls
```

### # Add content database to Web application

```PowerShell
Test-SPContentDatabase -Name WSS_Content_MySites -WebApplication http://my-dev

Mount-SPContentDatabase -Name WSS_Content_MySites -WebApplication http://my-dev
```

```PowerShell
cls
```

### # Remove default content database created with Web application

```PowerShell
Get-SPContentDatabase -WebApplication http://my-dev |
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
    -MySiteHostLocation "http://my-dev/" `
    -MySiteManagedPath sites
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

```PowerShell
cls
```

## # Start full crawl

```PowerShell
Get-SPEnterpriseSearchServiceApplication |
    Get-SPEnterpriseSearchCrawlContentSource |
    % { $_.StartFullCrawl() }
```

## Out of memory

Log Name:      System\
Source:        Microsoft-Windows-Resource-Exhaustion-Detector\
Date:          4/26/2015 4:30:59 PM\
Event ID:      2004\
Task Category: Resource Exhaustion Diagnosis Events\
Level:         Warning\
Keywords:      Events related to exhaustion of system commit limit (virtual memory).\
User:          SYSTEM\
Computer:      POLARIS-DEV.corp.technologytoolbox.com\
Description:\
Windows successfully diagnosed a low virtual memory condition. The following programs consumed the most virtual memory: w3wp.exe (5128) consumed 1095385088 bytes, w3wp.exe (8476) consumed 923058176 bytes, and noderunner.exe (2328) consumed 912764928 bytes.\
Event Xml:\
<Event xmlns="[http://schemas.microsoft.com/win/2004/08/events/event](http://schemas.microsoft.com/win/2004/08/events/event)">\
  `<System>`\
    `<Provider Name="Microsoft-Windows-Resource-Exhaustion-Detector" Guid="{9988748E-C2E8-4054-85F6-0C3E1CAD2470}" />`\
    `<EventID>`2004`</EventID>`\
    `<Version>`0`</Version>`\
    `<Level>`3`</Level>`\
    `<Task>`3`</Task>`\
    `<Opcode>`33`</Opcode>`\
    `<Keywords>`0x8000000020000000`</Keywords>`\
    `<TimeCreated SystemTime="2015-04-26T22:30:59.914186600Z" />`\
    `<EventRecordID>`3529`</EventRecordID>`\
    `<Correlation ActivityID="{862DE20D-1BB8-4D2E-9F3F-B46BCBED3AAA}" />`\
    `<Execution ProcessID="1676" ThreadID="5608" />`\
    `<Channel>`System`</Channel>`\
    `<Computer>`POLARIS-DEV.corp.technologytoolbox.com`</Computer>`\
    `<Security UserID="S-1-5-18" />`\
  `</System>`\
  `<UserData>`\
    <MemoryExhaustionInfo xmlns="[http://www.microsoft.com/Windows/Resource/Exhaustion/Detector/Events](http://www.microsoft.com/Windows/Resource/Exhaustion/Detector/Events)">\
      `<SystemInfo>`\
        `<SystemCommitLimit>`11810689024`</SystemCommitLimit>`\
        `<SystemCommitCharge>`11708403712`</SystemCommitCharge>`\
        `<ProcessCommitCharge>`10322837504`</ProcessCommitCharge>`\
        `<PagedPoolUsage>`315576320`</PagedPoolUsage>`\
        `<PhysicalMemorySize>`8589463552`</PhysicalMemorySize>`\
        `<PhysicalMemoryUsage>`8277946368`</PhysicalMemoryUsage>`\
        `<NonPagedPoolUsage>`110288896`</NonPagedPoolUsage>`\
        `<Processes>`77`</Processes>`\
      `</SystemInfo>`\
      ...\
    `</MemoryExhaustionInfo>`\
  `</UserData>`\
`</Event>`

Log Name:      Application\
Source:        MSSQLSERVER\
Date:          4/26/2015 4:35:30 PM\
Event ID:      701\
Task Category: Server\
Level:         Error\
Keywords:      Classic\
User:          TECHTOOLBOX\\jjameson-admin\
Computer:      POLARIS-DEV.corp.technologytoolbox.com\
Description:\
There is insufficient system memory in resource pool 'internal' to run this query.\
Event Xml:\
<Event xmlns="[http://schemas.microsoft.com/win/2004/08/events/event](http://schemas.microsoft.com/win/2004/08/events/event)">\
  `<System>`\
    `<Provider Name="MSSQLSERVER" />`\
    `<EventID Qualifiers="49152">`701`</EventID>`\
    `<Level>`2`</Level>`\
    `<Task>`2`</Task>`\
    `<Keywords>`0x80000000000000`</Keywords>`\
    `<TimeCreated SystemTime="2015-04-26T22:35:30.000000000Z" />`\
    `<EventRecordID>`5707`</EventRecordID>`\
    `<Channel>`Application`</Channel>`\
    `<Computer>`POLARIS-DEV.corp.technologytoolbox.com`</Computer>`\
    `<Security UserID="S-1-5-21-3914637029-2275272621-3670275343-10610" />`\
  `</System>`\
  `<EventData>`\
    `<Data>`internal`</Data>`\
    `<Binary>`BD020000110000000C00000050004F004C0041005200490053002D004400450056000000070000006D00610073007400650072000000`</Binary>`\
  `</EventData>`\
`</Event>`

Log Name:      Application\
Source:        MSSQLSERVER\
Date:          4/26/2015 4:35:30 PM\
Event ID:      701\
Task Category: Server\
Level:         Error\
Keywords:      Classic\
User:          TECHTOOLBOX\\s-web-my-team-dev\
Computer:      POLARIS-DEV.corp.technologytoolbox.com\
Description:\
There is insufficient system memory in resource pool 'default' to run this query.\
Event Xml:\
<Event xmlns="[http://schemas.microsoft.com/win/2004/08/events/event](http://schemas.microsoft.com/win/2004/08/events/event)">\
  `<System>`\
    `<Provider Name="MSSQLSERVER" />`\
    `<EventID Qualifiers="49152">`701`</EventID>`\
    `<Level>`2`</Level>`\
    `<Task>`2`</Task>`\
    `<Keywords>`0x80000000000000`</Keywords>`\
    `<TimeCreated SystemTime="2015-04-26T22:35:30.000000000Z" />`\
    `<EventRecordID>`5708`</EventRecordID>`\
    `<Channel>`Application`</Channel>`\
    `<Computer>`POLARIS-DEV.corp.technologytoolbox.com`</Computer>`\
    `<Security UserID="S-1-5-21-3914637029-2275272621-3670275343-10642" />`\
  `</System>`\
  `<EventData>`\
    `<Data>`default`</Data>`\
    `<Binary>`BD020000110000000C00000050004F004C0041005200490053002D004400450056000000120000005700530053005F0043006F006E00740065006E0074005F005400650061006D0031000000`</Binary>`\
  `</EventData>`\
`</Event>`

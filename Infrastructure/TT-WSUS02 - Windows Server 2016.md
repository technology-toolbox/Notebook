# TT-WSUS02 - Windows Server 2016

Friday, February 23, 2018
2:12 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy Windows Server Update Services

### Reference

**Deploy Windows Server Update Services**\
From <[https://docs.microsoft.com/en-us/windows-server/administration/windows-server-update-services/deploy/deploy-windows-server-update-services](https://docs.microsoft.com/en-us/windows-server/administration/windows-server-update-services/deploy/deploy-windows-server-update-services)>

### Plan WSUS deployment

| Setting          | Value                                  |
| ---------------- | -------------------------------------- |
| Content location | [\\\\TT-FS01\\WSUS\$](\\TT-FS01\WSUS$) |
| Current size     | 40.4 GB (3,705 files, 258 folders)     |

### Deploy and configure the server infrastructure

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Create virtual machine

```PowerShell
$vmHost = "TT-HV02C"
$vmName = "TT-WSUS02"
$vmPath = "D:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 2GB `
    -SwitchName "Embedded Team Switch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -DynamicMemory `
    -MemoryMinimumBytes 2GB `
    -MemoryMaximumBytes 4GB `
    -ProcessorCount 2

Start-VM -ComputerName $vmHost -Name $vmName
```

---

#### Install custom Windows Server 2016 image

- On the **Task Sequence** step, select **Windows Server 2016** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **TT-WSUS02**.
  - Click **Next**.
- On the **Applications** step, do not select any applications, and click **Next**.

### # Rename local Administrator account and set password

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

$password = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted, type the password for the local Administrator account.

```PowerShell
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

$adminUser = [ADSI] 'WinNT://./Administrator,User'
$adminUser.Rename('foo')
$adminUser.SetPassword($plainPassword)

logoff
```

### Login as .\\foo

### # Copy Toolbox content

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$source = "\\TT-FS01\Public\Toolbox"
$destination = "C:\NotBackedUp\Public\Toolbox"

robocopy $source $destination /E /XD "Microsoft SDKs"
```

### # Set MaxPatchCacheSize to 0 (recommended)

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Set first boot device to hard drive

```PowerShell
$vmHost = "TT-HV02C"
$vmName = "TT-WSUS02"

$vmHardDiskDrive = Get-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName |
    where { $_.ControllerType -eq "SCSI" `
        -and $_.ControllerNumber -eq 0 `
        -and $_.ControllerLocation -eq 0 }

Set-VMFirmware `
    -ComputerName $vmHost `
    -VMName $vmName `
    -FirstBootDevice $vmHardDiskDrive
```

---

### # Configure networking

```PowerShell
$interfaceAlias = "Management"
```

#### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Start-Sleep -Seconds 5

ping TT-FS01 -f -l 8900
```

#### Configure static IP address

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

##### # Configure static IP address using VMM

```PowerShell
$vmName = "TT-WSUS02"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Management VM Network"
$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"
$ipPool = Get-SCStaticIPAddressPool -Name "Management Address Pool"

Stop-SCVirtualMachine $vmName

$macAddress = Grant-SCMACAddress `
    -MACAddressPool $macAddressPool `
    -Description $vmName `
    -VirtualNetworkAdapter $networkAdapter

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -MACAddressType Static `
    -MACAddress $macAddress

$ipAddress = Grant-SCIPAddress `
    -GrantToObjectType VirtualNetworkAdapter `
    -GrantToObjectID $networkAdapter.ID `
    -StaticIPAddressPool $ipPool `
    -Description $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -IPv4AddressType Static `
    -IPv4Addresses $IPAddress.Address

Start-SCVirtualMachine $vmName
```

---

### Configure storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 32 GB       | 4K                   | OSDisk       |
| 1    | D:           | 80 GB       | 4K                   | Data01       |

#### Configure separate VHD for WSUS content

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

##### # Add disk for WSUS content

```PowerShell
$vmHost = "TT-HV02C"
$vmName = "TT-WSUS02"

$vhdPath = "D:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 80GB
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

##### # Initialize disks and format volumes

```PowerShell
Get-Disk 1 |
    Initialize-Disk -PartitionStyle GPT -PassThru |
    New-Partition -UseMaximumSize -DriveLetter D |
    Format-Volume `
        -FileSystem NTFS `
        -NewFileSystemLabel "Data01" `
        -Confirm:$false
```

### Configure backup

#### Add virtual machine to Hyper-V protection group in DPM

### Install and configure prerequisites for WSUS

#### Install System CLR Types for SQL Server 2012

> **Note**
>
> Report Viewer 2012 requires System CLR Types for SQL Server 2012.

```PowerShell
& ("\\TT-FS01\Products\Microsoft\System Center 2012 R2" `
    + "\Microsoft System CLR Types for SQL Server 2012\SQLSysClrTypes.msi")
```

```PowerShell
cls
```

#### # Install Report Viewer 2012

```PowerShell
& "\\TT-FS01\Products\Microsoft\Report Viewer 2012 Runtime\ReportViewer.msi"
```

### Install WSUS

#### Reference

**Step 1: Install the WSUS Server Role**\
From <[https://docs.microsoft.com/en-us/windows-server/administration/windows-server-update-services/deploy/1-install-the-wsus-server-role](https://docs.microsoft.com/en-us/windows-server/administration/windows-server-update-services/deploy/1-install-the-wsus-server-role)>

#### Install WSUS server role

**To install the WSUS server role:**

1. In **Server Manager**, click **Manage**, and then click **Add Roles and Features**.
2. On the **Before you begin** page, click **Next**.
3. On the **Select installation type** page, confirm the **Role-based or feature-based installation** option is selected and click **Next**.
4. On the **Select destination server** page:
   1. Ensure the **Select a server from the server pool** option is selected.
   2. In the **Server Pool** list, select the server for the WSUS server role.
   3. Click **Next**.
5. On the **Select server roles** page:
   1. Select **Windows Server Update Services**.
   2. A dialog window opens for adding the features required for WSUS. Click **Add Features**.
   3. Click **Next**.
6. On the **Select features **page, click **Next**.
7. On the **Windows Server Update Services** page, click **Next**.
8. On the **Select role services** page:
   1. Clear the **WID Connectivity** checkbox.
   2. Ensure the **WSUS Services** checkbox is selected.
   3. Select the **SQL Server Connectivity** checkbox.
   4. Click **Next**.
9. On the **Content location selection** page:
   1. Ensure the **Store updates in the following location **checkbox is selected.
   2. In the location box, type **D:\\WSUS**.
   3. Click **Next**.
10. On the **Database Instance Selection** page:
    1. In the **Specify an existing database server** box, type **HAVOK**.
    2. Click **Check connection** and confirm the wizard is able to successfully connect to the server.
    3. Click **Next**.
11. On the **Web Server Role (IIS)** page, review the information, and then click **Next**.
12. On the **Select roles services** page, click **Next**.
13. On the **Confirm installation selections** page, review the selected options, and click **Install**. The WSUS installation wizard runs. This might take several minutes to complete.
14. Wait for the WSUS installation to complete.
15. In the summary window on the **Installation progress** page, click **Launch Post-Installation tasks**. The text changes to: **Please wait while your server is configured**.
16. When the task has finished, the text changes to: **Configuration successfully completed**. Click **Close**.
17. In **Server Manager**, verify if a notification appears to inform you that a restart is required. This can vary according to the installed server role. If it requires a restart make sure to restart the server to complete the installation.

### Configure WSUS

#### Reference

**Configure WSUS by using the WSUS Configuration Wizard**\
From <[https://docs.microsoft.com/en-us/windows-server/administration/windows-server-update-services/deploy/2-configure-wsus](https://docs.microsoft.com/en-us/windows-server/administration/windows-server-update-services/deploy/2-configure-wsus)>

#### Configure WSUS database

---

**HAVOK - SQL Server Management Studio**

#### -- Change auto-grow increment on SUSDB.mdf from 1 MB to 100 MB

```SQL
ALTER DATABASE [SUSDB]
MODIFY FILE ( NAME = N'SUSDB', FILEGROWTH = 102400KB )
```

---

#### Configure memory limit for WSUS application pool in IIS

Modify the properties for **WsusPool** to increase the **Private Memory Limit (KB)** to **2500000**.

##### Issue - WSUS crashing due to memory constraint

Windows Update failing on clients:

- HRESULT: 0x80244022
- HRESULT: 0x8024400A

###### Troubleshooting

Log Name:      System\
Source:        Microsoft-Windows-WAS\
Date:          10/14/2016 9:32:42 AM\
Event ID:      5117\
Task Category: None\
Level:         Information\
Keywords:      Classic\
User:          N/A\
Computer:      COLOSSUS.corp.technologytoolbox.com\
Description:\
A worker process serving application pool 'WsusPool' has requested a recycle because it reached its private bytes memory limit.

Log Name:      System\
Source:        Microsoft-Windows-WAS\
Date:          10/14/2016 9:33:42 AM\
Event ID:      5002\
Task Category: None\
Level:         Error\
Keywords:      Classic\
User:          N/A\
Computer:      COLOSSUS.corp.technologytoolbox.com\
Description:\
Application pool 'WsusPool' is being automatically disabled due to a series of failures in the process(es) serving that application pool.

### Configure WSUS by using the WSUS Configuration Wizard

**To configure WSUS:**

1. In the **Server Manager** navigation pane, select **WSUS**.
2. In the servers list, right-click the WSUS server (**TT-WSUS02**) and then click **Windows Server Update Services**. The **Windows Server Update Services Wizard** opens.
3. On the **Before You Begin** page, review the information, and then click **Next**.
4. On the **Join the Microsoft Update Improvement Program** page, click **Next**.
5. On the **Choose Upstream Server** page, ensure the **Synchronize from Microsoft Update** option is selected and click **Next**.
6. On the **Specify Proxy Server** page, ensure the **Use a proxy server when synchronizing** checkbox is not selected, and click **Next**.
7. On the **Connect to Upstream Server** page, click **Start Connecting**.
8. Wait for the information to be downloaded and then click **Next**.
9. On the **Choose Languages** page:
   1. Select the **Download updates in only these languages** option.
   2. In the list of languages, select **English**.
   3. Click **Next**.
10. After selecting the appropriate language options for your deployment, click **Next** to continue.
11. On the **Choose Products** page:
    1. Select the following products:\
       **Microsoft**\
       **Developer Tools, Runtimes, and Redistributables**\
       **Visual Studio 2010**\
       **Visual Studio 2012**\
       **Visual Studio 2013**\
       **Expression**\
       **Expression Design 4**\
       **Expression Web 4**\
       **Office**\
       **Silverlight**\
       **SQL Server**\
       **System Center**\
       **System Center 2016 - Data Protection Manager**\
       **System Center 2016 - Operations Manager**\
       **System Center 2016 - Orchestrator**\
       **System Center 2016 - Virtual Machine Manager**\
       **Windows**
    2. Click **Next**.
12. On the **Choose Classifications **page:
    1. Select the following classifications:\
       **All Classifications**\
       **Critical Updates**\
       **Definition Updates**\
       **Drivers Sets**\
       **Drivers**\
       **Feature Packs**\
       **Security Updates**\
       **Service Packs**\
       **Tools**\
       **Update Rollups**\
       **Updates**\
       **Upgrades**
    2. Click **Next**.
13. On the **Set Sync Schedule** page:
    1. Select the **Synchronize automatically** option.
    2. In the **First synchronization** box, specify **11:10:00 PM**.
    3. Click **Next**.
14. On the **Finished** page:
    1. Select the **Begin initial synchronization** checkbox.
    2. Click **Finish**. The WSUS Management Console appears.
    3. ~~Wait for the initial synchronization to complete before proceeding.~~

### Configure WSUS computer groups

**To create a computer group:**

1. In the **Update Services** console, in the navigation pane, expand **Computers**, and then select **All Computers**.
2. In the **Actions** pane, click **Add Computer Group...**
3. In the **Add Computer Group** window, in the **Name** box, type the name for the new computer group and click **OK**.

Computers

- **All Computers**
  - **Unassigned Computers**
  - .**NET Framework 3.5**
  - **.NET Framework 4**
  - **.NET Framework 4 Client Profile**
  - **.NET Framework 4.5**
  - **Contoso**
  - **Fabrikam**
    - **Fabrikam - Development**
    - **Fabrikam - Quality Assurance**
      - **Fabrikam - Beta Testing**
  - **Internet Explorer 10**
  - **Internet Explorer 11**
  - **Internet Explorer 7**
  - **Internet Explorer 8**
  - **Internet Explorer 9**
  - **Silverlight**
  - **Technology Toolbox**
    - **Development**
    - **Quality Assurance**
      - **Beta Testing**
    - **WSUS Servers**

### Secure WSUS with Secure Sockets Layer protocol

#### Configure name resolution for WSUS

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
Add-DNSServerResourceRecordCName `
    -ComputerName TT-DC06 `
    -ZoneName technologytoolbox.com `
    -Name wsus `
    -HostNameAlias TT-WSUS02.corp.technologytoolbox.com
```

---

#### Install SSL certificate

Friendly name: **wsus.technologytoolbox.com**

```PowerShell
cls
```

#### # Configure SSL on WSUS server

```PowerShell
Push-Location 'C:\Program Files\Update Services\Tools\'

.\WsusUtil.exe ConfigureSSL wsus.technologytoolbox.com

Pop-Location
```

#### Configure HTTPS binding on IIS website

![(screenshot)](https://assets.technologytoolbox.com/screenshots/20/D40B6EF7536FD41FFB3A935DEFA6C78603DBB320.png)

1. Click **Edit**.
2. In the **Edit Site Binding** window:
   1. In the **SSL certificate** dropdown, select **wsus.technologytoolbox.com**.
   2. Click **OK**.
3. Click **Close**.

#### Validate SSL configuration

[http://wsus.technologytoolbox.com:8530/Content/anonymousCheckFile.txt](http://wsus.technologytoolbox.com:8530/Content/anonymousCheckFile.txt)

[https://wsus.technologytoolbox.com:8531/Content/anonymousCheckFile.txt](https://wsus.technologytoolbox.com:8531/Content/anonymousCheckFile.txt)

### WSUS database maintenance (rebuild/reorganize indexes)

C:\\NotBackedUp\\Public\\Toolbox\\WSUS\\WsusDBMaintenance.sql

```PowerShell
cls
```

### # Decline unwanted updates

```PowerShell
Get-WsusUpdate -Approval AnyExceptDeclined |
    where {
        # Superseded updates
        ($_.UpdatesSupersedingThisUpdate -ne 'None') -or `
        # Language Packs
        ($_.Products -match 'Language Interface Packs') -or `
        ($_.Products -match 'Language Packs')

    } |
    Deny-WsusUpdate -Verbose
```

### Approve and deploy updates in WSUS

#### Reference

**Approve and Deploy Updates in WSUS**\
From <[https://docs.microsoft.com/en-us/windows-server/administration/windows-server-update-services/deploy/3-approve-and-deploy-updates-in-wsus](https://docs.microsoft.com/en-us/windows-server/administration/windows-server-update-services/deploy/3-approve-and-deploy-updates-in-wsus)>

**To approve and deploy WSUS updates:**

1. In the **Update Services** console, click **Updates**. In the right pane, an update status summary is displayed for **All Updates**, **Critical Updates**, **Security Updates**, and **WSUS Updates**.
2. In the **All Updates** section, click **Updates needed by computers**.
3. In the list of updates, select the updates that you want to approve for installation. Information about a selected update is available in the bottom pane of the **Updates** panel. To select multiple contiguous updates, hold down the **shift** key while clicking the update names. To select multiple noncontiguous updates, press down the **CTRL** key while clicking the update names.
4. Right-click the selection, and then click **Approve**.
5. In the **Approve Updates** dialog box:
   1. Select the desired computer group, click the down arrow, and click **Approved for Install**.
   2. Click **OK**.
6. The **Approval Progress** window appears, which shows the progress of the tasks that affect update approval. When the approval process is complete, click **Close**.

#### Configure automatic approval rules

**To configure automatic approval rules:**

1. Open the **Update Services** console.
2. In the left navigation pane, expand the WSUS server and select **Options**.
3. In the **Options** pane, select **Automatic Approvals**.
4. In the **Automatic Approvals** window, on the **Update Rules** tab, select **Default Automatic Approval Rule**.
5. In the **Rule properties** section, click **Critical Updates, Security Updates**.
6. In the **Choose Update Classifications** window:
   1. Select **Definition Updates**.
   2. Clear the checkboxes for all other update classifications.
   3. Click** OK**.
7. Confirm the **Rule properties** for the **Default Automatic Approval Rule** are configured as follows:**When an update is in Definition UpdatesApprove the update for all computers**
8. Select the **Default Automatic Approval Rule** checkbox.
9. Click **New Rule...**
10. In the **Add Rule** window:
    1. In the **Step 1: Select properties** section, select** When an update is in a specific classification**.
    2. In the **Step 2: Edit the properties** section:
       1. Click **any classification**.
          1. In the **Choose Update Classifications **window:
             1. Clear the **All Classifications **checkbox.
             2. Select the following checkboxes:
                - **Critical Updates**
                - **Security Updates**
          2. Click **OK**.
       2. Click **all computers**
          1. In the **Choose Computer Groups** window:
             1. Clear the **All Computers** checkbox.
             2. Select the following checkboxes:
                - **Fabrikam / Fabrikam - Quality Assurance / Fabrikam - Beta Testing**
                - **Technology Toolbox / Quality Assurance / Beta Testing**
          2. Click **OK**.
    3. In the **Step 3: Specify a name **box, type **Beta Testing Approval Rule**.
    4. Click **OK**.
11. In the **Automatic Approvals** window:
    1. Confirm the **Rule properties** for the **Beta Testing Approval Rule** are configured as follows:**When an update is in Critical Updates, Security UpdatesApprove the update for Fabrikam - Beta Testing, Beta Testing**
    2. Click **OK**.

### Configure client updates

#### Configure group policies for Windows Update

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FF/90D027F45985EDDE45459FFE24B90162DB4EC7FF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3D/6E21C9B289F9BA9956C626E0233D90918321943D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/70/30DD2864E090A114EA8533C7805470816BC07470.png)

#### Configure firewall rules for Windows Update

## Import scheduled task to cleanup WSUS

"C:\\NotBackedUp\\Public\\Toolbox\\WSUS\\WSUS Server Cleanup.xml"

## Create SQL job for WSUS database maintenance

Name: **WsusDBMaintenance**\
Steps:

- Step 1
  - Step name: **Defragment database and update statistics**
  - Type: **Transact-SQL script (T-SQL)**
  - Command: (click **Open...** and then select script - **"C:\\NotBackedUp\\Public\\Toolbox\\WSUS\\WsusDBMaintenance.sql"**)
  - Database: **SUSDB**\
    Schedule:

- Schedule 1
  - Name: **Weekly**
  - Frequency:
    - Occurs: **Weekly**
    - Recurs every: **1 week on Sunday**
  - Daily frequency:
    - Occurs once at: **10:00 AM**

**TODO:**

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

## Move WSUS database from HAVOK to TT-SQL01

### # Stop WSUS services

```PowerShell
Stop-Service wuauserv
Stop-Service W3SVC
Stop-Service WsusService
```

### Backup database

> **Note**
>
> Use backup/restore -- instead of database detach/attach -- due to different versions of SQL Server running on HAVOK and TT-SQL01. Initially, detach/attach was attempted but it did not restore the log file due to different file location (i.e. "L:\\Microsoft SQL Server\\MSSQL12.MSSQLSERVER\\..." vs. "L:\\Microsoft SQL Server\\MSSQL13.MSSQLSERVER\\...").

---

**HAVOK - SQL Server Management Studio**

#### -- Create copy-only database backup on source server

```SQL
DECLARE @databaseName VARCHAR(50) = 'SUSDB'

DECLARE @backupDirectory VARCHAR(255)

EXEC master.dbo.xp_instance_regread
    N'HKEY_LOCAL_MACHINE'
    , N'Software\Microsoft\MSSQLServer\MSSQLServer'
    , N'BackupDirectory'
    , @backupDirectory OUTPUT

DECLARE @backupFilePath VARCHAR(255) =
    @backupDirectory + '\' + @databaseName + '.bak'

DECLARE @backupName VARCHAR(100) = @databaseName + '-Full Database Backup'

BACKUP DATABASE @databaseName
    TO DISK = @backupFilePath
    WITH COMPRESSION
        , COPY_ONLY
        , INIT
        , NAME = @backupName
        , STATS = 10

GO
```

---

### Move database backup to destination server

---

**HAVOK**

```PowerShell
cls
```

#### # Move database backup

```PowerShell
Move-Item `
    -Path "Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\SUSDB.bak" `
    -Destination "\\TT-SQL01A\Z$\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup"
```

---

### Restore database on destination server

---

**TT-SQL01A - SQL Server Management Studio**

#### -- Restore database backup

```SQL
DECLARE @databaseName VARCHAR(50) = 'SUSDB'

DECLARE @dataFile VARCHAR(25) = @databaseName
DECLARE @logFile VARCHAR(25) = @databaseName + '_log'

DECLARE @backupDirectory VARCHAR(255)
DECLARE @dataDirectory VARCHAR(255) = CONVERT(
    VARCHAR(255),
    SERVERPROPERTY('instancedefaultdatapath'))

DECLARE @logDirectory VARCHAR(255) = CONVERT(
    VARCHAR(255),
    SERVERPROPERTY('instancedefaultlogpath'))

EXEC master.dbo.xp_instance_regread
    N'HKEY_LOCAL_MACHINE'
    , N'Software\Microsoft\MSSQLServer\MSSQLServer'
    , N'BackupDirectory'
    , @backupDirectory OUTPUT

DECLARE @backupFilePath VARCHAR(255) =
    @backupDirectory + '\' + @databaseName + '.bak'

DECLARE @dataFilePath VARCHAR(255) =
    @dataDirectory + '\' + @databaseName + '.mdf'

DECLARE @logFilePath VARCHAR(255) =
    @logDirectory + '\' + @databaseName + '.ldf'

RESTORE DATABASE @databaseName
    FROM DISK = @backupFilePath
    WITH REPLACE
        , MOVE @dataFile TO @dataFilePath
        , MOVE @logFile TO @logFilePath
        , STATS = 5

GO
```

#### -- Create login used by WSUS database

```SQL
USE master
GO

CREATE LOGIN [TECHTOOLBOX\TT-WSUS02$] FROM WINDOWS
WITH DEFAULT_DATABASE=master, DEFAULT_LANGUAGE=us_english
GO
```

---

### Add SUSDB database to AlwaysOn Availability Group

---

**SQL Server Management Studio (TT-SQL01A)**

#### -- Change recovery model for WSUS database from Simple to Full

```SQL
USE master
GO
ALTER DATABASE SUSDB SET RECOVERY FULL WITH NO_WAIT
GO
```

#### -- Backup WSUS database

```SQL
DECLARE @backupFilePath VARCHAR(255) =
    'Z:\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\'
        + 'SUSDB.bak'

BACKUP DATABASE SUSDB
    TO DISK = @backupFilePath
    WITH FORMAT, INIT, SKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 5
GO
```

#### -- Backup WSUS transaction log

```SQL
DECLARE @backupFilePath VARCHAR(255) =
    'Z:\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\'
        + 'SUSDB.trn'

BACKUP LOG SUSDB
    TO DISK = @backupFilePath
    WITH NOFORMAT, NOINIT, NOSKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 5
GO
```

#### -- Add WSUS database to Availability Group

```SQL
ALTER AVAILABILITY GROUP [TT-SQL01] ADD DATABASE SUSDB
GO
```

---

---

**SQL Server Management Studio (TT-SQL01B)**

#### -- Create login used by WSUS database

```SQL
USE master
GO

CREATE LOGIN [TECHTOOLBOX\TT-WSUS02$] FROM WINDOWS
WITH DEFAULT_DATABASE=master, DEFAULT_LANGUAGE=us_english
GO
```

#### -- Restore WSUS database from backup

```SQL
DECLARE @backupFilePath VARCHAR(255) =
    '\\TT-SQL01A\SQL-Backups\SUSDB.bak'

RESTORE DATABASE SUSDB
    FROM DISK = @backupFilePath
    WITH  NORECOVERY,  NOUNLOAD,  STATS = 5

GO
```

#### -- Restore WSUS transaction log from backup

```SQL
DECLARE @backupFilePath VARCHAR(255) =
    '\\TT-SQL01A\SQL-Backups\SUSDB.trn'

RESTORE DATABASE SUSDB
    FROM DISK = @backupFilePath
    WITH  NORECOVERY,  NOUNLOAD,  STATS = 5

GO
```

#### -- Wait for the replica to start communicating

```Console
begin try
    declare @conn bit
    declare @count int
    declare @replica_id uniqueidentifier
    declare @group_id uniqueidentifier
    set @conn = 0
    set @count = 30 -- wait for 5 minutes

    if (serverproperty('IsHadrEnabled') = 1)
        and (isnull(
            (select member_state from master.sys.dm_hadr_cluster_members where upper(member_name COLLATE Latin1_General_CI_AS) = upper(cast(serverproperty('ComputerNamePhysicalNetBIOS') as nvarchar(256)) COLLATE Latin1_General_CI_AS)), 0) <> 0)
        and (isnull((select state from master.sys.database_mirroring_endpoints), 1) = 0)
    begin
        select @group_id = ags.group_id
        from master.sys.availability_groups as ags
        where name = N'TT-SQL01'

        select @replica_id = replicas.replica_id
        from master.sys.availability_replicas as replicas
        where
            upper(replicas.replica_server_name COLLATE Latin1_General_CI_AS) =
                upper(@@SERVERNAME COLLATE Latin1_General_CI_AS)
            and group_id = @group_id

    while @conn <> 1 and @count > 0
        begin
            set @conn = isnull(
                (select connected_state
                from master.sys.dm_hadr_availability_replica_states as states
                where states.replica_id = @replica_id), 1)

        if @conn = 1
            begin
                -- exit loop when the replica is connected,
                -- or if the query cannot find the replica status
                break
            end

            waitfor delay '00:00:10'
            set @count = @count - 1
        end
    end
end try
begin catch
    -- If the wait loop fails, do not stop execution of the alter database statement
end catch
GO

ALTER DATABASE [SUSDB] SET HADR AVAILABILITY GROUP = [TT-SQL01]
GO
```

---

---

**SQL Server Management Studio (TT-SQL01)**

### -- Create SQL job for WSUS database maintenance

```Console
USE [msdb]
GO

/****** Object:  Job [WsusDBMaintenance]    Script Date: 8/15/2017 9:40:04 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 8/15/2017 9:40:04 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'WsusDBMaintenance',
    @enabled=1,
    @notify_level_eventlog=0,
    @notify_level_email=0,
    @notify_level_netsend=0,
    @notify_level_page=0,
    @delete_level=0,
    @description=N'No description available.',
    @category_name=N'[Uncategorized (Local)]',
    @owner_login_name=N'TECHTOOLBOX\jjameson-admin', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Defragment database and update statistics]    Script Date: 8/15/2017 9:40:04 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Defragment database and update statistics',
    @step_id=1,
    @cmdexec_success_code=0,
    @on_success_action=1,
    @on_success_step_id=0,
    @on_fail_action=2,
    @on_fail_step_id=0,
    @retry_attempts=0,
    @retry_interval=0,
    @os_run_priority=0, @subsystem=N'TSQL',
    @command=N'/******************************************************************************
This sample T-SQL script performs basic maintenance tasks on SUSDB
1. Identifies indexes that are fragmented and defragments them. For certain
   tables, a fill-factor is set in order to improve insert performance.
   Based on MSDN sample at http://msdn2.microsoft.com/en-us/library/ms188917.aspx
   and tailored for SUSDB requirements
2. Updates potentially out-of-date table statistics.
******************************************************************************/

USE SUSDB;
GO
SET NOCOUNT ON;

-- Rebuild or reorganize indexes based on their fragmentation levels
DECLARE @work_to_do TABLE (
    objectid int
    , indexid int
    , pagedensity float
    , fragmentation float
    , numrows int
)

DECLARE @objectid int;
DECLARE @indexid int;
DECLARE @schemaname nvarchar(130);
DECLARE @objectname nvarchar(130);
DECLARE @indexname nvarchar(130);
DECLARE @numrows int
DECLARE @density float;
DECLARE @fragmentation float;
DECLARE @command nvarchar(4000);
DECLARE @fillfactorset bit
DECLARE @numpages int

-- Select indexes that need to be defragmented based on the following
-- * Page density is low
-- * External fragmentation is high in relation to index size
PRINT ''Estimating fragmentation: Begin. '' + convert(nvarchar, getdate(), 121)
INSERT @work_to_do
SELECT
    f.object_id
    , index_id
    , avg_page_space_used_in_percent
    , avg_fragmentation_in_percent
    , record_count
FROM
    sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL , NULL, ''SAMPLED'') AS f
WHERE
    (f.avg_page_space_used_in_percent < 85.0 and f.avg_page_space_used_in_percent/100.0 * page_count < page_count - 1)
    or (f.page_count > 50 and f.avg_fragmentation_in_percent > 15.0)
    or (f.page_count > 10 and f.avg_fragmentation_in_percent > 80.0)

PRINT ''Number of indexes to rebuild: '' + cast(@@ROWCOUNT as nvarchar(20))

PRINT ''Estimating fragmentation: End. '' + convert(nvarchar, getdate(), 121)

SELECT @numpages = sum(ps.used_page_count)
FROM
    @work_to_do AS fi
    INNER JOIN sys.indexes AS i ON fi.objectid = i.object_id and fi.indexid = i.index_id
    INNER JOIN sys.dm_db_partition_stats AS ps on i.object_id = ps.object_id and i.index_id = ps.index_id

-- Declare the cursor for the list of indexes to be processed.
DECLARE curIndexes CURSOR FOR SELECT * FROM @work_to_do

-- Open the cursor.
OPEN curIndexes

-- Loop through the indexes
WHILE (1=1)
BEGIN
    FETCH NEXT FROM curIndexes
    INTO @objectid, @indexid, @density, @fragmentation, @numrows;
    IF @@FETCH_STATUS < 0 BREAK;

    SELECT
        @objectname = QUOTENAME(o.name)
        , @schemaname = QUOTENAME(s.name)
    FROM
        sys.objects AS o
        INNER JOIN sys.schemas as s ON s.schema_id = o.schema_id
    WHERE
        o.object_id = @objectid;

    SELECT
        @indexname = QUOTENAME(name)
        , @fillfactorset = CASE fill_factor WHEN 0 THEN 0 ELSE 1 END
    FROM
        sys.indexes
    WHERE
        object_id = @objectid AND index_id = @indexid;

    IF ((@density BETWEEN 75.0 AND 85.0) AND @fillfactorset = 1) OR (@fragmentation < 30.0)
        SET @command = N''ALTER INDEX '' + @indexname + N'' ON '' + @schemaname + N''.'' + @objectname + N'' REORGANIZE'';
    ELSE IF @numrows >= 5000 AND @fillfactorset = 0
        SET @command = N''ALTER INDEX '' + @indexname + N'' ON '' + @schemaname + N''.'' + @objectname + N'' REBUILD WITH (FILLFACTOR = 90)'';
    ELSE
        SET @command = N''ALTER INDEX '' + @indexname + N'' ON '' + @schemaname + N''.'' + @objectname + N'' REBUILD'';
    PRINT convert(nvarchar, getdate(), 121) + N'' Executing: '' + @command;
    EXEC (@command);
    PRINT convert(nvarchar, getdate(), 121) + N'' Done.'';
END

-- Close and deallocate the cursor.
CLOSE curIndexes;
DEALLOCATE curIndexes;


IF EXISTS (SELECT * FROM @work_to_do)
BEGIN
    PRINT ''Estimated number of pages in fragmented indexes: '' + cast(@numpages as nvarchar(20))
    SELECT @numpages = @numpages - sum(ps.used_page_count)
    FROM
        @work_to_do AS fi
        INNER JOIN sys.indexes AS i ON fi.objectid = i.object_id and fi.indexid = i.index_id
        INNER JOIN sys.dm_db_partition_stats AS ps on i.object_id = ps.object_id and i.index_id = ps.index_id

    PRINT ''Estimated number of pages freed: '' + cast(@numpages as nvarchar(20))
END
GO


--Update all statistics
PRINT ''Updating all statistics.'' + convert(nvarchar, getdate(), 121)
EXEC sp_updatestats
PRINT ''Done updating statistics.'' + convert(nvarchar, getdate(), 121)
GO',
    @database_name=N'SUSDB',
    @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Weekly',
    @enabled=1,
    @freq_type=8,
    @freq_interval=1,
    @freq_subday_type=1,
    @freq_subday_interval=0,
    @freq_relative_interval=0,
    @freq_recurrence_factor=1,
    @active_start_date=20161217,
    @active_end_date=99991231,
    @active_start_time=100000,
    @active_end_time=235959,
    @schedule_uid=N'e0a9c6bf-b402-47df-97c8-c70aeeb6d42b'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO
```

---

---

**HAVOK - SQL Server Management Studio**

### -- Delete database on source server

```SQL
USE master
GO
DROP DATABASE SUSDB
GO
```

### -- Delete SQL job for WSUS database maintenance

```SQL
USE msdb
GO
EXEC msdb.dbo.sp_delete_job @job_name=N'WsusDBMaintenance',
    @delete_unused_schedule=1

GO
```

---

```PowerShell
cls
```

### # Configure WSUS server for new database server

```PowerShell
Set-ItemProperty `
    -Path 'HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup' `
    -Name SqlServerName `
    -Value TT-SQL01

Get-ItemProperty `
    -Path 'HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup' `
    -Name SqlServerName
```

```PowerShell
cls
```

### # Start WSUS services

```PowerShell
Start-Service WsusService
Start-Service W3SVC
Start-Service wuauserv
```

---

**FOOBAR11**

```PowerShell
cls
```

## # Make virtual machine highly available

```PowerShell
$vm = Get-SCVirtualMachine -Name TT-WSUS02
$vmHost = $vm.VMHost

Move-SCVirtualMachine `
    -VM $vm `
    -VMHost $vmHost `
    -HighlyAvailable $true `
    -Path "\\TT-SOFS01.corp.technologytoolbox.com\VM-Storage-Silver" `
    -UseDiffDiskOptimization
```

---

## WSUS update approvals

```PowerShell
Get-WsusUpdate -Approval AnyExceptDeclined |
    #select -First 5 |
    foreach {
        New-Object -TypeName PSObject -Property @{
          'UpdateId' = $_.UpdateId;
          'Title' = $_.Update.Title;
          'Classification' = $_.Classification;
          'Approved' = $_.Approved;
        }
    } |
    Export-Csv `
        -Path C:\NotBackedUp\Temp\WSUS-Updates.csv `
        -NoTypeInformation `
        -Encoding UTF8

Get-WsusUpdate -Approval Declined |
    #select -First 5 |
    foreach {
        New-Object -TypeName PSObject -Property @{
          'UpdateId' = $_.UpdateId;
          'Title' = $_.Update.Title;
          'Classification' = $_.Classification;
          'Approved' = $_.Approved;
        }
    } |
    Export-Csv `
        -Path C:\NotBackedUp\Temp\WSUS-Updates.csv `
        -NoTypeInformation `
        -Encoding UTF8 `
        -Append


$wsusServer = Get-WsusServer

$wsusServer.GetComputerTargetGroups() |
    foreach {
        $computerGroup = $_

        $updateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope

        $updateScope.ApprovedStates = "Any"
        $updateScope.ApprovedComputerTargetGroups.Add($computerGroup) | Out-Null

        $wsusServer.GetUpdateApprovals($updateScope) |
            foreach {
                New-Object -TypeName PSObject -Property @{
                    'ComputerGroup' = $computerGroup.Name;
                    'UpdateId' = $_.Id;
                    'Action' = $_.Action;
                }
            }
    } |
    Export-Csv `
        -Path C:\NotBackedUp\Temp\WSUS-Updates-By-Computer-Group.csv `
        -NoTypeInformation `
        -Encoding UTF8
```

## Issue: Windows Update (KB3159706) broke WSUS console

### Issue

WSUS clients started failing with error 0x8024401C

Attempting to open WSUS console generated errors, which led to the discovery of the following errors in the event log:

Log Name:      Application\
Source:        Windows Server Update Services\
Date:          5/13/2016 8:39:56 AM\
Event ID:      507\
Task Category: 1\
Level:         Error\
Keywords:      Classic\
User:          N/A\
Computer:      COLOSSUS.corp.technologytoolbox.com\
Description:\
Update Services failed its initialization and stopped.

Log Name:      System\
Source:        Service Control Manager\
Date:          5/13/2016 8:39:56 AM\
Event ID:      7031\
Task Category: None\
Level:         Error\
Keywords:      Classic\
User:          N/A\
Computer:      COLOSSUS.corp.technologytoolbox.com\
Description:\
The WSUS Service service terminated unexpectedly.  It has done this 1 time(s).  The following corrective action will be taken in 300000 milliseconds: Restart the service.

### References

**Update enables ESD decryption provision in WSUS in Windows Server 2012 and Windows Server 2012 R2**\
From <[https://support.microsoft.com/en-us/kb/3159706](https://support.microsoft.com/en-us/kb/3159706)>

**The long-term fix for KB3148812 issues**\
From <[https://blogs.technet.microsoft.com/wsus/2016/05/05/the-long-term-fix-for-kb3148812-issues/](https://blogs.technet.microsoft.com/wsus/2016/05/05/the-long-term-fix-for-kb3148812-issues/)>

### Solution

Manual steps required to complete the installation of this update

1. Open an elevated Command Prompt window, and then run the following command (case sensitive, assume "C" as the system volume):
"C:\\Program Files\\Update Services\\Tools\\wsusutil.exe" postinstall /servicing
2. Select **HTTP Activation **under **.NET Framework 4.5 Features** in the Server Manager Add Roles and Features wizard.
3. Restart the WSUS service.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7D/06E6407CAFFDA2F33739002CABD4137317C46E7D.jpg)

From <[https://support.microsoft.com/en-us/kb/3159706](https://support.microsoft.com/en-us/kb/3159706)>

# TT-WSUS03 - Windows Server 2016 Standard Edition

Thursday, March 22, 2018
4:00 PM

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
$vmHost = "TT-HV05C"
$vmName = "TT-WSUS03"
$vmPath = "E:\NotBackedUp\VMs"
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
  - In the **Computer name** box, type **TT-WSUS03**.
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

### # Enable performance counters for Server Manager

```PowerShell
$taskName = "\Microsoft\Windows\PLA\Server Manager Performance Monitor"

Enable-ScheduledTask -TaskName $taskName

logman start "Server Manager Performance Monitor"
```

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls

$vmName = "TT-WSUS03"
```

### # Move computer to different OU

```PowerShell
$targetPath = ("OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

### # Set first boot device to hard drive

```PowerShell
$vmHost = "TT-HV05C"

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

### # Configure Windows Update

##### # Add machine to security group for Windows Update schedule

```PowerShell
Add-ADGroupMember -Identity "Windows Update - Slot 9" -Members ($vmName + '$')
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
$vmName = "TT-WSUS03"
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
$vmHost = "TT-HV05C"
$vmName = "TT-WSUS03"

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
$installerPath = "\\TT-FS01\Products\Microsoft\System Center 2012 R2" `
    + "\Microsoft System CLR Types for SQL Server 2012\SQLSysClrTypes.msi"

Start-Process `
    -FilePath $installerPath `
    -Wait
```

```PowerShell
cls
```

#### # Install Report Viewer 2012

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\Report Viewer 2012 Runtime" `
```

    + "\\ReportViewer.msi"

```PowerShell
Start-Process `
    -FilePath $installerPath `
    -Wait
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
2. In the servers list, right-click the WSUS server (**TT-WSUS03**) and then click **Windows Server Update Services**. The **Windows Server Update Services Wizard** opens.
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

> **Note**
>
> The initial synchronization should complete in approximately 26 minutes.

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
    -HostNameAlias TT-WSUS03.corp.technologytoolbox.com
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

---

**FOOBAR11**

```PowerShell
cls
```

## # Make virtual machine highly available

### # Migrate VM to shared storage

```PowerShell
$vmName = "TT-WSUS03"

$vm = Get-SCVirtualMachine -Name $vmName
$vmHost = $vm.VMHost

Move-SCVirtualMachine `
    -VM $vm `
    -VMHost $vmHost `
    -HighlyAvailable $true `
    -Path "C:\ClusterStorage\iscsi01-Silver-02" `
    -UseDiffDiskOptimization
```

### # Allow migration to host with different processor version

```PowerShell
Stop-SCVirtualMachine -VM $vmName

Set-SCVirtualMachine -VM $vmName -CPULimitForMigration $true

Start-SCVirtualMachine -VM $vmName
```

---

```PowerShell
cls
```

## # Configure monitoring

### # Install Operations Manager agent

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\System Center 2016\SCOM\Agent\AMD64" `
    + "\MOMAgent.msi"

$installerArguments = "MANAGEMENT_GROUP=HQ" `
    + " MANAGEMENT_SERVER_DNS=TT-SCOM03" `
    + " ACTIONS_USE_COMPUTER_ACCOUNT=1"

Start-Process `
    -FilePath msiexec.exe `
    -ArgumentList "/i `"$installerPath`" $installerArguments" `
    -Wait
```

### Approve manual agent install in Operations Manager

## Issue - Synchronizations view in WSUS console hangs (then requires console reset)

### Problem

**spSearchUpdates** sproc returns more than 24,000 rows

### Solution

---

**HAVOK - SQL Server Management Studio**

#### -- Clear the synchronization history

```SQL
USE SUSDB
GO

DELETE FROM tbEventInstance
WHERE EventNamespaceID = '2'
    AND EventID IN ('381', '382', '384', '386', '387', '389')
```

---

### References

**Synchronization Tab crashes the WSUS console**\
From <[https://conexiva.wordpress.com/2016/02/23/synchronization-tab-crashes-the-wsus-console/](https://conexiva.wordpress.com/2016/02/23/synchronization-tab-crashes-the-wsus-console/)>

**Clearing the Synchronization history in the WSUS console**\
From <[https://blogs.technet.microsoft.com/sus/2009/03/04/clearing-the-synchronization-history-in-the-wsus-console/](https://blogs.technet.microsoft.com/sus/2009/03/04/clearing-the-synchronization-history-in-the-wsus-console/)>

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

CREATE LOGIN [TECHTOOLBOX\TT-WSUS03$] FROM WINDOWS
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

**TT-SQL01B**

```PowerShell
cls
```

#### # Copy backup file

```PowerShell
$source = "\\TT-SQL01A\SQL-Backups"
$destination = "Z:\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup"

robocopy $source $destination SUSDB.bak
```

---

---

**SQL Server Management Studio (TT-SQL01B)**

#### -- Create login used by WSUS database

```SQL
USE master
GO

CREATE LOGIN [TECHTOOLBOX\TT-WSUS03$] FROM WINDOWS
WITH DEFAULT_DATABASE=master, DEFAULT_LANGUAGE=us_english
GO
```

#### -- Restore WSUS database from backup

```SQL
DECLARE @backupFilePath VARCHAR(255) =
    'Z:\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\SUSDB.bak'

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

**HAVOK - SQL Server Management Studio**

### -- Delete database on source server

```SQL
USE master
GO
DROP DATABASE SUSDB
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

## Import scheduled task to cleanup WSUS

"C:\\NotBackedUp\\Public\\Toolbox\\WSUS\\WSUS Server Cleanup.xml"

## Expand D: (Data01) drive

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C9/A27048AE900ECB08EF24C0D23F50EEA94B5EAEC9.png)

Screen clipping taken: 5/11/2018 6:29 AM

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Increase the size of "Data01" VHD

```PowerShell
$vmName = "TT-WSUS03"

# Note: VHD is stored on Cluster Shared Volume -- so expand using VMM cmdlet

Stop-SCVirtualMachine -VM $vmName

Get-SCVirtualDiskDrive -VM $vmName |
    where { $_.BusType -eq "SCSI" -and $_.Bus -eq 0 -and $_.Lun -eq 1 } |
    Expand-SCVirtualDiskDrive -VirtualHardDiskSizeGB 100

Start-SCVirtualMachine -VM $vmName
```

---

```PowerShell
cls
```

### # Extend partition

```PowerShell
$driveLetter = "D"

$partition = Get-Partition -DriveLetter $driveLetter |
    where { $_.DiskNumber -ne $null }

$size = (Get-PartitionSupportedSize `
    -DiskNumber $partition.DiskNumber `
    -PartitionNumber $partition.PartitionNumber)

Resize-Partition `
    -DiskNumber $partition.DiskNumber `
    -PartitionNumber $partition.PartitionNumber `
    -Size $size.SizeMax
```

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Move VM to new Production VM network

```PowerShell
$vmName = "TT-WSUS03"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Production VM Network"
$ipAddressPool = Get-SCStaticIPAddressPool -Name "Production-15 Address Pool"

Stop-SCVirtualMachine $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -IPv4AddressPools $ipAddressPool `
    -IPv4AddressType Static

Start-SCVirtualMachine $vmName
```

---

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Move VM to new Management VM network

```PowerShell
$vmName = "TT-WSUS03"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Management VM Network"
$ipAddressPool = Get-SCStaticIPAddressPool -Name "Management-30 Address Pool"

Stop-SCVirtualMachine $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -IPv4AddressPools $ipAddressPool `
    -IPv4AddressType Static

Start-SCVirtualMachine $vmName
```

---

**TODO:**

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

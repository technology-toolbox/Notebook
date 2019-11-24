# TT-DPM04 (FAIL) - Windows Server 2019

Saturday, November 23, 2019
11:57 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure infrastructure

---

**TT-ADMIN02 - Run as administrator**

```PowerShell
cls
```

### # Create domain group for DPM administrators

```PowerShell
$dpmAdminsGroup = "DPM Admins"
$orgUnit = "OU=Groups,OU=IT,DC=corp,DC=technologytoolbox,DC=com"

New-ADGroup `
    -Name $dpmAdminsGroup `
    -Description "Complete and unrestricted access to Data Protection Manager" `
    -GroupScope Global `
    -Path $orgUnit
```

### # Add setup account to DPM administrators domain group

```PowerShell
Add-ADGroupMember -Identity $dpmAdminsGroup -Members setup-systemcenter
```

```PowerShell
cls
```

### # Create service account for DPM SQL Server instance

```PowerShell
$displayName = "Service account for SQL Server instance on TT-DPM04"
$defaultUserName = "s-sql-dpm04"

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

---

**TT-ADMIN02 - Run as administrator**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "TT-DPM04"
$vmPath = "E:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 55GB `
    -MemoryStartupBytes 6GB `
    -SwitchName "Embedded Team Switch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 4 `
    -AutomaticCheckpointsEnabled $false

Set-VMNetworkAdapterVlan `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Access `
    -VlanId 30

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Install custom Windows Server 2019 image

- On the **Task Sequence** step, select **Windows Server 2019** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **TT-DPM04**.
  - Click **Next**.
- On the **Applications** step, ensure no items are selected and click **Next**.

```PowerShell
cls
```

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

---

**TT-ADMIN02 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Move computer to different OU

```PowerShell
$vmName = "TT-DPM04"

$targetPath = ("OU=System Center Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

### # Configure Windows Update

##### # Add machine to security group for Windows Update configuration

```PowerShell
Add-ADGroupMember -Identity "Manual Windows Update" -Members ($vmName + '$')
```

---

### Login as local administrator account

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

### Configure storage

#### Configure storage for SQL Server

| Disk | Drive Letter | Volume Size | VHD Type | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------- | -------------------- | ------------ |
| 0    | C:           | 55 GB       | Dynamic  | 4K                   | OSDisk       |
| 1    | D:           | 3 GB        | Dynamic  | 64K                  | Data01       |
| 2    | L:           | 1 GB        | Dynamic  | 64K                  | Log01        |
| 3    | T:           | 1 GB        | Dynamic  | 64K                  | Temp01       |
| 4    | Z:           | 10 GB       | Dynamic  | 4K                   | Backup01     |

---

**TT-ADMIN02 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Add virtual disks for SQL Server

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "TT-DPM04"
$vmPath = "E:\NotBackedUp\VMs\$vmName"
```

##### # Add "Data01" VHD

```PowerShell
$vhdPath = $vmPath + "\Virtual Hard Disks\$vmName" + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 3GB
Add-VMHardDiskDrive `
  -ComputerName $vmHost `
  -VMName $vmName `
  -Path $vhdPath `
  -ControllerType SCSI
```

##### # Add "Log01" VHD

```PowerShell
$vhdPath = $vmPath + "\Virtual Hard Disks\$vmName" + "_Log01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 1GB
Add-VMHardDiskDrive `
  -ComputerName $vmHost `
  -VMName $vmName `
  -Path $vhdPath `
  -ControllerType SCSI
```

##### # Add "Temp01" VHD

```PowerShell
$vhdPath = $vmPath + "\Virtual Hard Disks\$vmName" + "_Temp01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 1GB
Add-VMHardDiskDrive `
  -ComputerName $vmHost `
  -VMName $vmName `
  -Path $vhdPath `
  -ControllerType SCSI
```

##### # Add "Backup01" VHD

```PowerShell
$vhdPath = $vmPath + "\Virtual Hard Disks\$vmName" + "_Backup01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 10GB
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

#### # Format virtual disks

##### # Format Data01 drive

```PowerShell
Get-Disk 1 |
  Initialize-Disk -PartitionStyle GPT -PassThru |
  New-Partition -DriveLetter D -UseMaximumSize |
  Format-Volume `
    -AllocationUnitSize 64KB `
    -FileSystem NTFS `
    -NewFileSystemLabel "Data01" `
    -Confirm:$false
```

##### # Format Log01 drive

```PowerShell
Get-Disk 2 |
  Initialize-Disk -PartitionStyle GPT -PassThru |
  New-Partition -DriveLetter L -UseMaximumSize |
  Format-Volume `
    -AllocationUnitSize 64KB `
    -FileSystem NTFS `
    -NewFileSystemLabel "Log01" `
    -Confirm:$false
```

##### # Format Temp01 drive

```PowerShell
Get-Disk 3 |
  Initialize-Disk -PartitionStyle GPT -PassThru |
  New-Partition -DriveLetter T -UseMaximumSize |
  Format-Volume `
    -AllocationUnitSize 64KB `
    -FileSystem NTFS `
    -NewFileSystemLabel "Temp01" `
    -Confirm:$false
```

##### # Format Backup01 drive

```PowerShell
Get-Disk 4 |
  Initialize-Disk -PartitionStyle GPT -PassThru |
  New-Partition -DriveLetter Z -UseMaximumSize |
  Format-Volume `
    -FileSystem NTFS `
    -NewFileSystemLabel "Backup01" `
    -Confirm:$false
```

```PowerShell
cls
```

## # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

> **Note**
>
> PowerShell remoting must be enabled for remote Windows Update using PoshPAIG ([https://github.com/proxb/PoshPAIG](https://github.com/proxb/PoshPAIG)).

## Prepare for DPM installation

### Reference

**Get DPM installed**\
From <[https://docs.microsoft.com/en-us/system-center/dpm/install-dpm?view=sc-dpm-2019](https://docs.microsoft.com/en-us/system-center/dpm/install-dpm?view=sc-dpm-2019)>

```PowerShell
cls
```

### # Add DPM administrators domain group to local Administrators group

```PowerShell
$domain = "TECHTOOLBOX"
$domainGroup = "DPM Admins"

([ADSI]"WinNT://./Administrators,group").Add(
    "WinNT://$domain/$domainGroup,group")
```

### # Install and configure SQL Server 2017

#### # Prepare server for SQL Server installation

##### # Add setup account to local Administrators group

```PowerShell
$domain = "TECHTOOLBOX"
$username = "setup-sql"

([ADSI]"WinNT://./Administrators,group").Add(
    "WinNT://$domain/$username,user")
```

> **Important**
>
> Sign out and then sign in using the setup account for SQL Server.

##### # Create folder for TempDB data files

```PowerShell
New-Item `
    -Path "T:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Data" `
    -ItemType Directory
```

#### # Install SQL Server 2017

```PowerShell
$imagePath = ("\\TT-FS01\Products\Microsoft\SQL Server 2017" `
    + "\en_sql_server_2017_standard_x64_dvd_11294407.iso")

$imageDriveLetter = (Mount-DiskImage -ImagePath $ImagePath -PassThru |
    Get-Volume).DriveLetter
```

& ("\$imageDriveLetter" + ":\\setup.exe")

On the **Feature Selection** step, select the following checkbox:

- **Database Engine Services**

On the **Server Configuration** step:

- For the **SQL Server Agent** service:
  - Change the **Account Name** to **TECHTOOLBOX\\s-sql-dpm04**.
  - Change the **Startup Type** to **Automatic**.
- For the **SQL Server Database Engine **service:
  - Change the **Account Name** to **TECHTOOLBOX\\s-sql-dpm04**.
  - Ensure the **Startup Type** is set to **Automatic**.
- For the **SQL Server Browser** service, ensure the **Startup Type** is set to **Disabled**.

On the **Database Engine Configuration** step:

- On the **Server Configuration** tab, in the **Specify SQL Server administrators** section, click **Add...** and then add the domain group for SQL Server administrators (**TECHTOOLBOX\\SQL Server Admins**) and the domain group for DPM administrators (**TECHTOOLBOX\\DPM Admins**).
- On the **Data Directories** tab:
  - In the **Data root directory** box, type **D:\\Microsoft SQL Server\\**.
  - In the **User database log directory** box, change the drive letter to **L:** (the value should be **L:\\Microsoft SQL Server\\MSSQL14.MSSQLSERVER\\MSSQL\\Data**).
  - In the **Backup directory** box, change the drive letter to **Z:** (the value should be **Z:\\Microsoft SQL Server\\MSSQL14.MSSQLSERVER\\MSSQL\\Backup**).
- On the **TempDB** tab:
  - Remove the default data directory (**D:\\Microsoft SQL Server\\MSSQL14.MSSQLSERVER\\MSSQL\\Data**).
  - Add the data directory on the **Temp01** volume (**T:\\Microsoft SQL Server\\MSSQL14.MSSQLSERVER\\MSSQL\\Data**).
  - Ensure the **Log directory** is set to **T:\\Microsoft SQL Server\\MSSQL14.MSSQLSERVER\\MSSQL\\Data**.

> **Important**
>
> Wait for the installation to complete.

```PowerShell
cls
```

#### # Install and configure SQL Server Reporting Services

##### # Install SQL Server Reporting Services

```PowerShell
& "\\TT-FS01\Products\Microsoft\SQL Server 2017\SQLServerReportingServices.exe"
```

> **Important**
>
> When prompted for which edition of Reporting Services to install, enter a product key for SQL Server Standard Edition. The Express Edition cannot use a database server running SQL Server 2017 Standard Edition.
>
> Wait for the installation to complete and restart the computer.

##### Configure SQL Server Reporting Services

1. Start **Report Server Configuration Manager**. If prompted by User Account Control to allow the program to make changes to the computer, click **Yes**.
2. In the **Report Server Configuration Connection** window, ensure the name of the server and SQL Server instance are both correct, and then click **Connect**.
3. In the **Report Server Status** pane, click **Start** if the server is not already started.
4. In the navigation pane, click **Service Account**.
5. In the **Service Account** pane, ensure **Use built-in account** is selected, select **Network Service** from the dropdown list, and click **Apply**.
6. In the navigation pane, click **Web Service URL**.
7. In the **Web Service URL **pane:
   1. Confirm the following warning message appears:
   2. Click **Apply**.
8. In the navigation pane, click **Database**.
9. In the **Report Server Database** pane, click **Change Database**.
10. In the **Report Server Database Configuration Wizard** window:
    1. In the **Action** pane, ensure **Create a new report server database** is selected, and then click **Next**.
    2. In the **Database Server** pane, ensure the local computer name is in the **Server Name** box, click **Test Connection** and confirm the test succeeded, and then click **Next**.
    3. In the **Database **pane, ensure the **Database Name** is set to **ReportServer**, and click **Next**.
    4. In the **Credentials **pane, ensure **Authentication Type** is set to **Service Credentials** and then click **Next**.
    5. On the **Summary** page, verify the information is correct, and then click **Next**.
    6. Click **Finish** to close the wizard.
11. In the navigation pane, click **Web Portal URL**.
12. In the **Web Portal URL **pane:
    1. Confirm the following warning message appears:
    2. Click **Apply**.
13. In the navigation pane, click **E-mail Settings**.
14. In the **E-mail Settings**:
    1. In the **Sender Address** box, type **s-backup@technologytoolbox.com**.
    2. In the **SMTP Server** box, type **smtp.technologytoolbox.com**.
    3. Click **Apply**.
15. In the navigation pane, click **Encryption Keys**.
16. In the **Encryption Keys **pane, click **Backup**.
17. In the **Backup Encryption Key** window:
    1. Specify the location of the file that will contain a copy of the key.
    2. Specify the password used to lock and unlock the file.
    3. Click **OK**.
18. Click **Exit** to close **Report Server Configuration Manager**.

Report Server Web Service is not configured. Default values have been provided to you. To accept these defaults simply press the Apply button, else change them and then press Apply.

The Web Portal virtual directory name is not configured. To configure the directory, enter a name or use the default value that is provided, and then click Apply.

```PowerShell
cls
```

#### # Install SQL Server Management Studio

```PowerShell
& "\\TT-FS01\Products\Microsoft\SQL Server Management Studio\18.4\SSMS-Setup-ENU.exe"
```

> **Important**
>
> Wait for the installation to complete and restart the computer.

```PowerShell
cls
```

#### # Install cumulative update for SQL Server

```PowerShell
& "\\TT-FS01\Products\Microsoft\SQL Server 2017\Patches\CU17\SQLServer2017-KB4515579-x64.exe"
```

> **Important**
>
> Wait for the installation to complete.

```PowerShell
cls
```

#### # Configure firewall rules for SQL Server

```PowerShell
New-NetFirewallRule `
    -Name "SQL Server Database Engine" `
    -DisplayName "SQL Server Database Engine" `
    -Group "Technology Toolbox (Custom)" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 1433 `
    -Action Allow

New-NetFirewallRule `
    -Name "SQL Server Reporting Services" `
    -DisplayName "SQL Server Reporting Services" `
    -Group 'Technology Toolbox (Custom)' `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 80 `
    -Action Allow
```

#### # TODO: Configure permissions on \\Windows\\System32\\LogFiles\\Sum files

```PowerShell
icacls C:\Windows\System32\LogFiles\Sum\Api.chk `
    /grant "NT Service\MSSQLSERVER:(M)"

icacls C:\Windows\System32\LogFiles\Sum\Api.log `
    /grant "NT Service\MSSQLSERVER:(M)"

icacls C:\Windows\System32\LogFiles\Sum\SystemIdentity.mdb `
    /grant "NT Service\MSSQLSERVER:(M)"
```

#### Configure settings for SQL Server Agent job history log

##### Reference

**SQL SERVER - Dude, Where is the SQL Agent Job History? - Notes from the Field #017**\
From <[https://blog.sqlauthority.com/2014/02/27/sql-server-dude-where-is-the-sql-agent-job-history-notes-from-the-field-017/](https://blog.sqlauthority.com/2014/02/27/sql-server-dude-where-is-the-sql-agent-job-history-notes-from-the-field-017/)>

---

**SQL Server Management Studio**

##### -- Do not limit size of SQL Server Agent job history log

```SQL
USE [msdb]
GO
EXEC msdb.dbo.sp_set_sqlagent_properties @jobhistory_max_rows=-1,
    @jobhistory_max_rows_per_job=-1
GO
```

---

#### Configure SQL Server maintenance

##### Reference

**SQL Server Backup, Integrity Check, and Index and Statistics Maintenance**\
From <[https://ola.hallengren.com/](https://ola.hallengren.com/)>

---

**SQL Server Management Studio**

##### -- Create SqlMaintenance database

```SQL
CREATE DATABASE SqlMaintenance
GO
```

---

##### Create maintenance table, stored procedures, and jobs

Execute script in SQL Server Management Studio:

[https://raw.githubusercontent.com/technology-toolbox/sql-server-maintenance-solution/master/MaintenanceSolution.sql](https://raw.githubusercontent.com/technology-toolbox/sql-server-maintenance-solution/master/MaintenanceSolution.sql)

##### Configure schedules for SqlMaintenance jobs

Execute script in SQL Server Management Studio:

[https://raw.githubusercontent.com/technology-toolbox/sql-server-maintenance-solution/master/JobSchedules.sql](https://raw.githubusercontent.com/technology-toolbox/sql-server-maintenance-solution/master/JobSchedules.sql)

### Configure server after SQL Server installation

#### Login as .\\foo

```PowerShell
cls
```

#### # Remove setup account from local Administrators group

```PowerShell
$domain = "TECHTOOLBOX"
$username = "setup-sql"

([ADSI]"WinNT://./Administrators,group").Remove(
    "WinNT://$domain/$username,user")
```

```PowerShell
cls
```

## # Install Data Protection Manager

### # Insert DPM 2019 installation media and extract setup files

```PowerShell
$imagePath = ("\\TT-FS01\Products\Microsoft\System Center 2019" `
    + "\mu_system_center_data_protection_manager_2019_x64_dvd_b9964d9f.iso")

$imageDriveLetter = (Mount-DiskImage -ImagePath $ImagePath -PassThru |
    Get-Volume).DriveLetter
```

& ("\$imageDriveLetter" + ":\\SCDPM_2019.exe")

Destination location: **C:\\NotBackedUp\\Temp\\System Center 2019 Data Protection Manager**

> **Important**
>
> Sign out and then sign in using the setup account for System Center.

### Login as TECHTOOLBOX\\setup-systemcenter

```PowerShell
cls
```

### # Install DPM 2019

```PowerShell
& "C:\NotBackedUp\Temp\System Center 2019 Data Protection Manager\setup.exe"
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E0/425DE962318315F055035081F946D87BE67C09E0.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B9/42D95212B3D0E18439BA413D21265C250A26DCB9.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/93/9984D7236AB79246561263B84A44EF8E7A6F6793.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F4/87DE5C0FB2B235434DC4A33995406C01B2BEB8F4.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/40/D6D356DB09DDC634628C6603249A5058AE695640.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B6/BC4048F9237335F0D9A774B0668B174B39956EB6.png)

In the **Instance of SQL Server** box, type **TT-DPM04** and click **Check and Install**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E8/0A074769F504C6B37DD2428F15EA9C75F90B50E8.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/47/CB963B0DC907A4C5939EBE689CB76A516C0EC347.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A1/8E6238FE66BE0033A48133D66536596F7E7DA2A1.png)

Wait for the DPM prerequisites to be installed and then restart the server.

```PowerShell
Restart-Computer
```

#### Login as TECHTOOLBOX\\setup-systemcenter

#### # Restart DPM setup

```PowerShell
& "C:\NotBackedUp\Temp\System Center 2019 Data Protection Manager\setup.exe"
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E0/425DE962318315F055035081F946D87BE67C09E0.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B9/42D95212B3D0E18439BA413D21265C250A26DCB9.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D2/32C0FC74CDB24FB848267B56004DD52C2A9E5AD2.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7D/563529A99B000095C6131878345CF54B9DB39F7D.png)

In the **Instance of SQL Server** box, type **TT-DPM04** and click **Check and Install**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/79/58181F4C37EE1D7322B3D5237C620FFA5C362C79.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/15/1A69776F26BB9A89B6B66CD58AC0D2E37A1F9C15.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AF/68DA6BF8D3CD74E98789147BC044694821FA9EAF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/11/9A84D192257012A3A90E52FCD6DEC70E91349811.png)

Click **Use Microsoft Update when I check for updates (recommended)** and then click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1D/6CB5019A8EAC748C88D36EAB10FB7FFBB238691D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/53/DC803ADD6AC295E6238BD5B8D75ED84048B5B453.png)

---

**C:\\Program Files\\Microsoft System Center\\DPM\\DPMLogs\\DpmSetup.log**

```Console
...
MSI (s) (48:24) [14:03:43:444]: Note: 1: 1707
MSI (s) (48:24) [14:03:43:444]: Product: Microsoft System Center  Data Protection Manager -- Installation completed successfully.

MSI (s) (48:24) [14:03:43:444]: Windows Installer installed the product. Product Name: Microsoft System Center  Data Protection Manager. Product Version: 10.19.58.0. Product Language: 1033. Manufacturer: Microsoft Corporation. Installation success or error status: 0.

MSI (s) (48:24) [14:03:43:491]: Closing MSIHANDLE (1) of type 790542 for thread 4644
MSI (s) (48:24) [14:03:43:741]: Deferring clean up of packages/files, if any exist
MSI (s) (48:24) [14:03:43:741]: MainEngineThread is returning 0
MSI (s) (48:28) [14:03:43:741]: RESTART MANAGER: Session closed.
MSI (s) (48:28) [14:03:43:741]: No System Restore sequence number for this installation.
=== Logging stopped: 11/23/2019  14:03:43 ===
MSI (s) (48:28) [14:03:43:756]: User policy value 'DisableRollback' is 0
MSI (s) (48:28) [14:03:43:756]: Machine policy value 'DisableRollback' is 0
MSI (s) (48:28) [14:03:43:756]: Incrementing counter to disable shutdown. Counter after increment: 0
MSI (s) (48:28) [14:03:43:756]: Note: 1: 1402 2: HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Installer\Rollback\Scripts 3: 2
MSI (s) (48:28) [14:03:43:756]: Note: 1: 2265 2:  3: -2147287035
MSI (s) (48:28) [14:03:43:756]: Note: 1: 1402 2: HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Installer\Rollback\Scripts 3: 2
MSI (s) (48:28) [14:03:43:756]: Decrementing counter to disable shutdown. If counter >= 0, shutdown will be denied.  Counter after decrement: -1
MSI (s) (48:28) [14:03:43:756]: Destroying RemoteAPI object.
MSI (s) (48:B8) [14:03:43:756]: Custom Action Manager thread ending.
MSI (c) (A8:6C) [14:03:43:772]: Decrementing counter to disable shutdown. If counter >= 0, shutdown will be denied.  Counter after decrement: -1
MSI (c) (A8:6C) [14:03:43:772]: MainEngineThread is returning 0
=== Verbose logging stopped: 11/23/2019  14:03:43 ===

[11/23/2019 2:03:43 PM] Information : MsiInstallProduct returned 0.
[11/23/2019 2:03:43 PM] Information : End install.
[11/23/2019 2:03:43 PM] Information : **************************************************************************************
[11/23/2019 2:03:43 PM] Information : **************************************************************************************
[11/23/2019 2:03:43 PM] Information : Start configuration.
[11/23/2019 2:03:43 PM] Information : Starting Service:MSSQLSERVER on machine:TT-DPM04 flag restart:False
[11/23/2019 2:03:43 PM] Information : Starting Service:SQLSERVERAGENT on machine:TT-DPM04 flag restart:False
[11/23/2019 2:04:43 PM] *** Error : CurrentDomain_UnhandledException
[11/23/2019 2:05:23 PM] * Exception : Invoking Watson with Exception:  => System.ComponentModel.Win32Exception (0x80004005): Unable to Configure the service: MSDPM
   at Microsoft.Internal.EnterpriseStorage.Dls.Utils.Win32ServiceHelper.SetFailureActions(String serviceName, SERVICE_FAILURE_ACTIONS& sfa)
   at Microsoft.Internal.EnterpriseStorage.Dls.Setup.Wizard.Configurator.ConfigureServices(String instanceName)
   at Microsoft.Internal.EnterpriseStorage.Dls.Setup.Wizard.BackEnd.Configure(Boolean existingDB, Boolean upgrading, String databaseLocation, String sqlServerMachineName, String sqlInstanceName, String reportingMachineName, String reportingInstanceName, Boolean oemSetup)
   at Microsoft.Internal.EnterpriseStorage.Dls.Setup.Wizard.DpmInstaller.Configure()
   at Microsoft.Internal.EnterpriseStorage.Dls.Setup.Wizard.ProgressPage.InstallerThreadEntry()
   at System.Threading.ExecutionContext.RunInternal(ExecutionContext executionContext, ContextCallback callback, Object state, Boolean preserveSyncCtx)
   at System.Threading.ExecutionContext.Run(ExecutionContext executionContext, ContextCallback callback, Object state, Boolean preserveSyncCtx)
   at System.Threading.ExecutionContext.Run(ExecutionContext executionContext, ContextCallback callback, Object state)
   at System.Threading.ThreadHelper.ThreadStart()
```

---

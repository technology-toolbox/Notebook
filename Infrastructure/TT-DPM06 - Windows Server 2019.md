# TT-DPM06 - Windows Server 2019

Sunday, April 11, 2021\
6:50 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure infrastructure

---

**TT-ADMIN04** - Run as administrator

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
$displayName = "Service account for SQL Server instance on TT-DPM06"
$defaultUserName = "s-sql-dpm06"

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

```PowerShell
cls
```

### # Create service account for backup processes (e.g. sending emails related to backups)

```PowerShell
$displayName = "Service account for backup processes"
$defaultUserName = "s-backup"

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

**TT-ADMIN04** - Run as administrator

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05F"
$vmName = "TT-DPM06"
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

- On the **Task Sequence** step, select **Windows Server 2019** and click
  **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **TT-DPM06**.
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

**TT-ADMIN04** - Run as administrator

```PowerShell
cls
```

### # Move computer to different OU

```PowerShell
$vmName = "TT-DPM06"

$targetPath = ("OU=System Center Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

### # Configure Windows Update

#### # Add machine to security group for Windows Update configuration

```PowerShell
Add-ADGroupMember -Identity "Manual Windows Update" -Members ($vmName + '$')
```

---

### Login as local administrator account

## # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

> **Note**
>
> PowerShell remoting must be enabled for remote Windows Update using PoshPAIG
> ([https://github.com/proxb/PoshPAIG](https://github.com/proxb/PoshPAIG)).

```PowerShell
cls
```

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

**TT-ADMIN04** - Run as administrator

```PowerShell
cls
```

#### # Add virtual disks for SQL Server

```PowerShell
$vmHost = "TT-HV05F"
$vmName = "TT-DPM06"
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

#### # Add virtual disks for Data Protection Manager

##### # Add "Data02" VHD

```PowerShell
$vhdPath = "Z:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName" `
    + "_Data02.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Fixed -SizeBytes 3690GB
Add-VMHardDiskDrive `
  -ComputerName $vmHost `
  -VMName $vmName `
  -Path $vhdPath `
  -ControllerType SCSI
```

##### # Add "Data03" VHD

```PowerShell
$vhdPath = "Y:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName" `
    + "_Data03.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Fixed -SizeBytes 3690GB
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

##### # Format Data02 drive

```PowerShell
Get-Disk 5 |
  Initialize-Disk -PartitionStyle GPT -PassThru |
  New-Partition -DriveLetter E -UseMaximumSize |
  Format-Volume `
    -FileSystem NTFS `
    -NewFileSystemLabel "Data02" `
    -Confirm:$false
```

##### # Format Data03 drive

```PowerShell
Get-Disk 6 |
  Initialize-Disk -PartitionStyle GPT -PassThru |
  New-Partition -DriveLetter F -UseMaximumSize |
  Format-Volume `
    -FileSystem NTFS `
    -NewFileSystemLabel "Data03" `
    -Confirm:$false
```

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

### # Install and configure SQL Server 2019

---

**TT-ADMIN04** - Run as administrator

```PowerShell
cls
```

#### # Enable setup account for SQL Server

```PowerShell
Enable-ADAccount -Identity setup-sql
```

---

#### # Prepare server for SQL Server installation

##### # Add setup account to local Administrators group

```PowerShell
$domain = "TECHTOOLBOX"
$username = "setup-sql"

([ADSI]"WinNT://./Administrators,group").Add(
    "WinNT://$domain/$username,user")

logoff
```

> **Important**
>
> Sign out and then sign in using the setup account for SQL Server.

##### # Create folder for TempDB data files

```PowerShell
New-Item `
    -Path "T:\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Data" `
    -ItemType Directory
```

#### # Install SQL Server 2019

```PowerShell
$imagePath = ("\\TT-FS01\Products\Microsoft\SQL Server 2019" `
    + "\en_sql_server_2019_standard_x64_dvd_46f0ba38.iso")

$imageDriveLetter = (Mount-DiskImage -ImagePath $ImagePath -PassThru |
    Get-Volume).DriveLetter

& ($imageDriveLetter + ":\setup.exe")
```

On the **Feature Selection** step, select the following checkbox:

- **Database Engine Services**

On the **Server Configuration** step:

- For the **SQL Server Agent** service:
  - Change the **Account Name** to **TECHTOOLBOX\\s-sql-dpm06**.
  - Change the **Startup Type** to **Automatic**.
- For the **SQL Server Database Engine** service:
  - Change the **Account Name** to **TECHTOOLBOX\\s-sql-dpm06**.
  - Ensure the **Startup Type** is set to **Automatic**.
- For the **SQL Server Browser** service, ensure the **Startup Type** is set to
  **Disabled**.

> **Important**
>
> DPM 2019 does not support the default service accounts for SQL Server. The
> service accounts must be domain accounts.

On the **Database Engine Configuration** step:

- On the **Server Configuration** tab, in the **Specify SQL Server
  administrators** section, click **Add...** and then add the domain group for
  SQL Server administrators (**TECHTOOLBOX\\SQL Server Admins**) and the domain
  group for DPM administrators (**TECHTOOLBOX\\DPM Admins**).
- On the **Data Directories** tab:
  - In the **Data root directory** box, type **D:\\Microsoft SQL Server\\**.
  - In the **User database log directory** box, change the drive letter to
    **L:** (the value should be **L:\\Microsoft SQL
    Server\\MSSQL15.MSSQLSERVER\\MSSQL\\Data**).
  - In the **Backup directory** box, change the drive letter to **Z:** (the
    value should be **Z:\\Microsoft SQL
    Server\\MSSQL15.MSSQLSERVER\\MSSQL\\Backup**).
- On the **TempDB** tab:
  - Remove the default data directory (**D:\\Microsoft SQL
    Server\\MSSQL15.MSSQLSERVER\\MSSQL\\Data**).
  - Add the data directory on the **Temp01** volume (**T:\\Microsoft SQL
    Server\\MSSQL15.MSSQLSERVER\\MSSQL\\Data**).
  - Ensure the **Log directory** is set to **T:\\Microsoft SQL
    Server\\MSSQL15.MSSQLSERVER\\MSSQL\\Data**.

> **Important**
>
> Wait for the installation to complete.

```PowerShell
cls
```

#### # Install and configure SQL Server Reporting Services

##### # Install SQL Server Reporting Services

```PowerShell
& "\\TT-FS01\Products\Microsoft\SQL Server 2019\SQLServerReportingServices.exe"
```

> **Important**
>
> When prompted for which edition of Reporting Services to install, enter a
> product key for SQL Server Standard Edition. Note the Express Edition cannot
> use a database server running SQL Server 2019 Standard Edition.
>
> Wait for the installation to complete and restart the computer.

##### Configure SQL Server Reporting Services

1. Start **Report Server Configuration Manager**. If prompted by User Account
   Control to allow the program to make changes to the computer, click **Yes**.
2. In the **Report Server Configuration Connection** window, ensure the name of
   the server and SQL Server instance are both correct, and then click
   **Connect**.
3. In the **Report Server Status** pane, click **Start** if the server is not
   already started.
4. In the navigation pane, click **Service Account**.
5. In the **Service Account** pane, ensure **Use built-in account** is selected,
   select **Network Service** from the dropdown list, and click **Apply**.

   > **Important**
   >
   > DPM 2019 does not support the default service account (**Virtual Service
   > Account**).

6. In the navigation pane, click **Web Service URL**.
7. In the **Web Service URL** pane:

   1. Confirm the following warning message appears:

      > Report Server Web Service is not configured. Default values have been
      > provided to you. To accept these defaults simply press the Apply button,
      > else change them and then press Apply.

   2. Click **Apply**.

8. In the navigation pane, click **Database**.
9. In the **Report Server Database** pane, click **Change Database**.
10. In the **Report Server Database Configuration Wizard** window:
    1. In the **Action** pane, ensure **Create a new report server database** is
       selected, and then click **Next**.
    2. In the **Database Server** pane, ensure the local computer name is in the
       **Server Name** box, click **Test Connection** and confirm the test
       succeeded, and then click **Next**.
    3. In the **Database** pane, ensure the **Database Name** is set to
       **ReportServer**, and click **Next**.
    4. In the **Credentials** pane, ensure **Authentication Type** is set to
       **Service Credentials** and then click **Next**.
    5. On the **Summary** page, verify the information is correct, and then
       click **Next**.
    6. Wait for the database to be created and then click **Finish** to close
       the wizard.
11. In the navigation pane, click **Web Portal URL**.
12. In the **Web Portal URL** pane:

    1. Confirm the following warning message appears:

       > The Web Portal virtual directory name is not configured. To configure
       > the directory, enter a name or use the default value that is provided,
       > and then click Apply.

    2. Click **Apply**.

13. In the navigation pane, click **E-mail Settings**.
14. In the **E-mail Settings**:
    1. In the **Sender Address** box, type **s-backup@technologytoolbox.com**.
    2. In the **SMTP Server** box, type **smtp.technologytoolbox.com**.
    3. Click **Apply**.
15. In the navigation pane, click **Encryption Keys**.
16. In the **Encryption Keys** pane, click **Backup**.
17. In the **Backup Encryption Key** window:
    1. Specify the location of the file that will contain a copy of the key.
    2. Specify the password used to lock and unlock the file.
    3. Click **OK**.
18. Click **Exit** to close **Report Server Configuration Manager**.

```PowerShell
cls
```

#### # Install SQL Server Management Studio

```PowerShell
& "\\TT-FS01\Products\Microsoft\SQL Server Management Studio\18.8\SSMS-Setup-ENU.exe"
```

> **Important**
>
> Wait for the installation to complete and restart the computer.

```PowerShell
cls
```

#### # Install cumulative update for SQL Server

```PowerShell
& "\\TT-FS01\Products\Microsoft\SQL Server 2019\Patches\CU10\SQLServer2019-KB5001090-x64.exe"
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

#### # Configure permissions for Software Usage Metrics feature

```PowerShell
icacls C:\Windows\System32\LogFiles\Sum\Api.chk `
    /grant "NT Service\MSSQLSERVER:(M)"

icacls C:\Windows\System32\LogFiles\Sum\Api.log `
    /grant "NT Service\MSSQLSERVER:(M)"

icacls C:\Windows\System32\LogFiles\Sum\SystemIdentity.mdb `
    /grant "NT Service\MSSQLSERVER:(M)"
```

##### Reference

**Error 1032 messages in the Application log in Windows Server 2012**\
From <[https://support.microsoft.com/en-us/help/2811566/error-1032-messages-in-the-application-log-in-windows-server-2012](https://support.microsoft.com/en-us/help/2811566/error-1032-messages-in-the-application-log-in-windows-server-2012)>

```PowerShell
cls
```

#### # Configure DCOM permissions for SQL Server

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\SQL\Configure DCOM Permissions.ps1' -Verbose
```

```PowerShell
cls
```

#### # Configure settings for SQL Server Agent job history log

```PowerShell
$sqlcmd = @"
-- Do not limit size of SQL Server Agent job history log

EXEC msdb.dbo.sp_set_sqlagent_properties @jobhistory_max_rows=-1,
    @jobhistory_max_rows_per_job=-1
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

##### Reference

**SQL SERVER - Dude, Where is the SQL Agent Job History? - Notes from the Field
#017**\
From <[https://blog.sqlauthority.com/2014/02/27/sql-server-dude-where-is-the-sql-agent-job-history-notes-from-the-field-017/](https://blog.sqlauthority.com/2014/02/27/sql-server-dude-where-is-the-sql-agent-job-history-notes-from-the-field-017/)>

```PowerShell
cls
```

#### # Configure SQL Server maintenance

##### # Create database for SQL Server maintenance

```PowerShell
$sqlcmd = "CREATE DATABASE SqlMaintenance"

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

##### # Create maintenance table, stored procedures, and jobs

```PowerShell
$url = "https://raw.githubusercontent.com/technology-toolbox" `
    + "/sql-server-maintenance-solution/master/MaintenanceSolution.sql"

$tempFileName = [System.IO.Path]::GetTempFileName()

Invoke-WebRequest -Uri $url -OutFile $tempFileName

Invoke-Sqlcmd -InputFile $tempFileName -Verbose -Debug:$false

Set-Location C:

Remove-Item $tempFileName
```

##### # Configure schedules for SQL Server maintenance jobs

```PowerShell
$url = "https://raw.githubusercontent.com/technology-toolbox" `
    + "/sql-server-maintenance-solution/master/JobSchedules.sql"

$tempFileName = [System.IO.Path]::GetTempFileName()

Invoke-WebRequest -Uri $url -OutFile $tempFileName

Invoke-Sqlcmd -InputFile $tempFileName -Verbose -Debug:$false

Set-Location C:

Remove-Item $tempFileName
```

##### Reference

**SQL Server Backup, Integrity Check, and Index and Statistics Maintenance**\
From <[https://ola.hallengren.com/](https://ola.hallengren.com/)>

```PowerShell
cls
```

#### # Constrain maximum memory for SQL Server

```PowerShell
$sqlcmd = @"
EXEC sys.sp_configure N'show advanced options', N'1'
RECONFIGURE WITH OVERRIDE
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

$sqlcmd = @"
EXEC sys.sp_configure N'max server memory (MB)', N'1024'
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

$sqlcmd = @"
EXEC sys.sp_configure N'show advanced options', N'0'
RECONFIGURE WITH OVERRIDE
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

---

**TT-ADMIN04** - Run as administrator

```PowerShell
cls
```

### # Disable setup account for SQL Server

```PowerShell
Disable-ADAccount -Identity setup-sql
```

---

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

---

**TT-ADMIN04** - Run as administrator

```PowerShell
cls
```

### # Enable setup account for System Center

```PowerShell
Enable-ADAccount -Identity setup-systemcenter
```

---

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

& ($imageDriveLetter + ":\\SCDPM_2019.exe")
```

Destination location: **C:\\NotBackedUp\\Temp\\System Center 2019 Data
Protection Manager**

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

In the **Instance of SQL Server** box, type **TT-DPM06** and click **Check and
Install**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B1/0E2BD8540196FC70693D57670A6B5B1FD8A5D6B1.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/90/D08C7617E9266E3E04952852EE8971F5479E2D90.png)

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

In the **Instance of SQL Server** box, type **TT-DPM06** and click **Check and
Install**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/17/63CEDD13EF1DF6912384DBD489C568FFB7492317.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/15/1A69776F26BB9A89B6B66CD58AC0D2E37A1F9C15.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AF/68DA6BF8D3CD74E98789147BC044694821FA9EAF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/11/9A84D192257012A3A90E52FCD6DEC70E91349811.png)

Click **Use Microsoft Update when I check for updates (recommended)** and then
click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EC/8E07D63F2E2B3923985C12E85EA73AE1E45DF6EC.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/22/BEEA665C22A58537D51329105F21E1A363284A22.png)

Data Protection Manager installation has completed successfully.

Please click on the link to check for the latest DPM updates:\
[http://go.microsoft.com/fwlink/?linkid=820914](http://go.microsoft.com/fwlink/?linkid=820914)

DPM Setup has created the following firewall exceptions:\

- Exception for DCOM communication on port 135 (TCP and UDP) in all profiles.\
- Exception for Msdpm.exe in all profiles.\
- Exception for DPMRA.exe in all profiles.\
- Exception for AMSvcHost.exe in all profiles.\
- Exception for DPMAMService communication on port 6075 (TCP and UDP) in all
  profiles.

```PowerShell
cls
```

### # Configure antivirus on DPM server

#### # Disable real-time monitoring by Windows Defender for DPM server

```PowerShell
$excludeFolders = `
    "E:\",
    "F:\",
    "$env:ProgramFiles\Microsoft System Center\DPM\DPM\Temp\MTA",
    "$env:ProgramFiles\Microsoft System Center\DPM\DPM\XSD"

$excludeProcesses =
   "$env:windir\Microsoft.NET\Framework\v2.0.50727\csc.exe",
   "$env:windir\Microsoft.NET\Framework64\v2.0.50727\csc.exe",
   "$env:windir\Microsoft.NET\Framework\v4.0.30319\csc.exe",
   "$env:windir\Microsoft.NET\Framework64\v4.0.30319\csc.exe",
   "$env:ProgramFiles\Microsoft System Center\DPM\DPM\bin\DPMRA.exe"

Set-MpPreference -ExclusionPath $excludeFolders
Set-MpPreference -ExclusionProcess $excludeProcesses
```

#### # Configure antivirus software to delete infected files

```PowerShell
Set-MpPreference -LowThreatDefaultAction Remove
Set-MpPreference -ModerateThreatDefaultAction Remove
Set-MpPreference -HighThreatDefaultAction Remove
Set-MpPreference -SevereThreatDefaultAction Remove
```

#### References

**Run antivirus software on the DPM server**\
From <[https://docs.microsoft.com/en-us/system-center/dpm/run-antivirus-server?view=sc-dpm-2019](https://docs.microsoft.com/en-us/system-center/dpm/run-antivirus-server?view=sc-dpm-2019)>

**Antivirus exclusions for DPM 2016/2019**\
From <[https://social.technet.microsoft.com/Forums/en-US/60b02401-a47b-4738-a497-5f3ebe6c82e6/antivirus-exclusions-for-dpm-20162019?forum=dataprotectionmanager](https://social.technet.microsoft.com/Forums/en-US/60b02401-a47b-4738-a497-5f3ebe6c82e6/antivirus-exclusions-for-dpm-20162019?forum=dataprotectionmanager)>

**Configure Data Protection Manager 2016 AntiVirus Exclusions on Windows Server
2016**\
From <[https://www.normanbauer.com/2018/02/28/configure-data-protection-manager-2016-antivirus-exclusions-on-windows-server-2016/](https://www.normanbauer.com/2018/02/28/configure-data-protection-manager-2016-antivirus-exclusions-on-windows-server-2016/)>

```PowerShell
cls
```

### # Copy DPM setup files to file share

```PowerShell
$source = "C:\NotBackedUp\Temp\System Center 2019 Data Protection Manager"
$destination = "\\TT-FS01\Products\Microsoft\System Center 2019\DPM"

robocopy $source $destination /E /NP
```

```PowerShell
cls
```

### # Remove temporary DPM setup files

```PowerShell
Remove-Item `
    -Path "C:\NotBackedUp\Temp\System Center 2019 Data Protection Manager" `
    -Recurse
```

## Configure DPM database

### Move log file for DPM database from D: to L:

> **Note**
>
> DPM 2019 does not honor the default path for SQL Server log files.

```PowerShell
cls
```

#### # Stop DPM services

```PowerShell
$dpmServices = @(
    "DPM",
    "DPMAMService",
    "DpmWriter")

$dpmServices | foreach { Stop-Service $_ }
```

```PowerShell
cls
```

#### # Detach DPM database

```PowerShell
$sqlcmd = @"
EXEC master.dbo.sp_detach_db @dbname = N'DPMDB_TT_DPM06'
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

#### # Move the log file for the DPM database

```PowerShell
$dataPath = "D:\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA"
$logPath = "L:\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Data"

Move-Item "$dataPath\MSDPM2012`$DPMDB_TT_DPM06_log.ldf" $logPath
```

#### # Attach DPM database

```PowerShell
$sqlcmd = @"
CREATE DATABASE [DPMDB_TT_DPM06] ON
    (FILENAME = N'$dataPath\MSDPM2012`$DPMDB_TT_DPM06.mdf'),
    (FILENAME = N'$logPath\MSDPM2012`$DPMDB_TT_DPM06_log.ldf')
    FOR ATTACH
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

```PowerShell
cls
```

#### # Start DPM services

```PowerShell
# Start services in the reverse order in which they are stopped
[Array]::Reverse($dpmServices)

$dpmServices | foreach { Start-Service $_ }
```

### # Configure database file growth

```PowerShell
$sqlcmd = @"
ALTER DATABASE [DPMDB_TT_DPM06]
    MODIFY FILE (
        NAME = N'MSDPM2012`$DPMDB_TT_DPM06_dat',
        FILEGROWTH = 100MB
    )

ALTER DATABASE [DPMDB_TT_DPM06]
    MODIFY FILE (
        NAME = N'MSDPM2012`$DPMDB_TT_DPM06Log_dat',
        FILEGROWTH = 25MB
    )
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

## # Configure SQL Server backups

### # Create folders for backups

```PowerShell
$backupPath = "Z:\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup"

New-Item -ItemType Directory -Path "$backupPath\Differential"
New-Item -ItemType Directory -Path "$backupPath\Full"
New-Item -ItemType Directory -Path "$backupPath\Transaction Log"
```

### Create backup maintenance plans

<table>
<thead>
<th>
<p><strong>Name</strong></p>
</th>
<th>
<p><strong>Frequency</strong></p>
</th>
<th>
<p><strong>Daily Frequency</strong></p>
</th>
<th>
<p><strong>Backup compression</strong></p>
</th>
</thead>
<tr>
<td valign='top'>
<p>Full Backup of All Databases</p>
</td>
<td valign='top'>
<p>Occurs: <strong>Weekly</strong><br />
Recurs every: <strong>1</strong> week on</p>
<ul>
<li><strong>Sunday</strong></li>
</ul>
</td>
<td valign='top'>
<p>Occurs once at: <strong>12:00:00 AM</strong></p>
</td>
<td valign='top'>
<p><strong>Compress backup</strong></p>
</td>
</tr>
<tr>
<td valign='top'>
<p>Differential Backup of All Databases</p>
</td>
<td valign='top'>
<p>Occurs: <strong>Daily</strong><br />
Recurs every: <strong>1</strong> day</p>
</td>
<td valign='top'>
<p>Occurs once at: <strong>11:30:00 PM</strong></p>
</td>
<td valign='top'>
<p><strong>Compress backup</strong></p>
</td>
</tr>
<tr>
<td valign='top'>
<p>Transaction Log Backup of All Databases</p>
</td>
<td valign='top'>
<p>Occurs: <strong>Daily</strong><br />
Recurs every: <strong>1</strong> day</p>
</td>
<td valign='top'>
<p>Occurs every: <strong>30 minutes</strong><br />
Starting at:<strong> 12:25:00 AM</strong><br />
Ending at:<strong> 11:59:59 PM</strong></p>
</td>
<td valign='top'>
<p><strong>Compress backup</strong></p>
</td>
</tr>
</table>

```PowerShell
cls
```

#### # Configure database settings to compress backups by default

```PowerShell
$sqlcmd = @"
EXEC sys.sp_configure N'backup compression default', N'1'
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

$sqlcmd = @"
RECONFIGURE WITH OVERRIDE
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

#### Create maintenance plan for full backup of all databases

1. Open **SQL Server Management Studio**.
2. In **Object Explorer**, expand **Management**, right-click **Maintenance
   Plans**, and click **Maintenance Plan Wizard**.
3. In the **Maintenance Plan Wizard** window:
   1. On the starting page, click **Next**.
   2. On the **Select Plan Properties** page:
      1. In the **Name** box, type **Full Backup of All Databases**.
      2. In the **Schedule** section, click **Change...**
      3. In the **New Job Schedule** window, configure the settings according to
         the configuration specified above, and click **OK**.
      4. Click **Next**.
   3. On the **Select Maintenance Tasks** page, in the list of maintenance
      tasks, select **Back Up Database (Full)**, and click **Next**.
   4. On the **Select Maintenance Task Order** page, click **Next**.
   5. On the **Define Back Up Database (Full) Task** page:
      1. On the **General** tab, In the **Database(s)** dropdown, select **All
         databases**.
      2. On the **Destination** tab, in the Folder box, type **Z:\\Microsoft SQL
         Server\\MSSQL15.MSSQLSERVER\\MSSQL\\Backup\\Full**.
      3. On the **Options** tab, in the **Set backup compression** dropdown,
         ensure **Use the default server setting** is selected.
      4. Click **Next**.
   6. On the **Select Report Options** page, click **Next**.
   7. On the **Complete the Wizard** page, click **Finish**.

#### Create maintenance plan for differential backup of all databases

1. Open **SQL Server Management Studio**.
2. In **Object Explorer**, expand **Management**, right-click **Maintenance
   Plans**, and click **Maintenance Plan Wizard**.
3. In the **Maintenance Plan Wizard** window:
   1. On the starting page, click **Next**.
   2. On the **Select Plan Properties** page:
      1. In the **Name** box, type **Differential Backup of All Databases**.
      2. In the **Schedule** section, click **Change...**
      3. In the **New Job Schedule** window, configure the settings according to
         the configuration specified above, and click **OK**.
      4. Click **Next**.
   3. On the **Select Maintenance Tasks** page, in the list of maintenance
      tasks, select **Back Up Database (Differential)**, and click **Next**.
   4. On the **Select Maintenance Task Order** page, click **Next**.
   5. On the **Define Back Up Database (Differential) Task** page:
      1. On the **General** tab, In the **Database(s)** dropdown, select **All
         databases**.
      2. On the **Destination** tab, in the Folder box, type **Z:\\Microsoft SQL
         Server\\MSSQL15.MSSQLSERVER\\MSSQL\\Backup\\Differential**.
      3. On the **Options** tab, in the **Set backup compression** dropdown,
         ensure **Use the default server setting** is selected.
      4. Click **Next**.
   6. On the **Select Report Options** page, click **Next**.
   7. On the **Complete the Wizard** page, click **Finish**.

#### Create maintenance plan for transaction log backup of all databases

1. Open **SQL Server Management Studio**.
2. In **Object Explorer**, expand **Management**, right-click **Maintenance
   Plans**, and click **Maintenance Plan Wizard**.
3. In the **Maintenance Plan Wizard** window:
   1. On the starting page, click **Next**.
   2. On the **Select Plan Properties** page:
      1. In the **Name** box, type **Transaction Log Backup of All Databases**.
      2. In the **Schedule** section, click **Change...**
      3. In the **New Job Schedule** window, configure the settings according to
         the configuration specified above, and click **OK**.
      4. Click **Next**.
   3. On the **Select Maintenance Tasks** page, in the list of maintenance
      tasks, select **Back Up Database (Transaction Log)**, and click **Next**.
   4. On the **Select Maintenance Task Order** page, click **Next**.
   5. On the **Define Back Up Database (Full) Task** page:
      1. On the **General** tab, In the **Database(s) **dropdown, select **All
         databases**.
      2. On the **Destination** tab, in the Folder box, type **Z:\\Microsoft SQL
         Server\\MSSQL15.MSSQLSERVER\\MSSQL\\Backup\\Transaction Log**.
      3. On the **Options** tab, in the **Set backup compression** dropdown,
         ensure **Use the default server setting** is selected.
      4. Click **Next**.
   6. On the **Select Report Options** page, click **Next**.
   7. On the **Complete the Wizard** page, click **Finish**.

### Create cleanup maintenance plan

<table>
<thead>
<th>
<p><strong>Name</strong></p>
</th>
<th>
<p><strong>Frequency</strong></p>
</th>
<th>
<p><strong>Daily Frequency</strong></p>
</th>
<th>
<p><strong>Maintenance Cleanup Task Settings</strong></p>
</th>
</thead>
<tr>
<td valign='top'>
<p>Remove Old Database Backups</p>
</td>
<td valign='top'>
<p>Occurs: <strong>Weekly</strong><br />
Recurs every: <strong>1</strong> week on</p>
<ul>
<li><strong>Saturday</strong></li>
</ul>
</td>
<td valign='top'>
<p>Occurs once at: <strong>11:55:00 PM</strong></p>
</td>
<td valign='top'>
<p><strong>First Task (Remove Full and Differential Backups)</strong></p>
<p><strong>Delete files of the following type:</strong></p>
<ul>
<li><strong>Backup files</strong></li>
</ul>
<p><strong>File location:</strong></p>
<ul>
<li><strong>Search folder and delete files based on an extension</strong>
<ul>
<li><strong>Folder: Z:\\Microsoft SQL Server\\MSSQL15.MSSQLSERVER\\MSSQL\\Backup\\</strong></li>
<li><strong>File Extension: bak</strong></li>
<li><strong>Include first-level subfolders: Yes (checked)</strong></li>
</ul>
</li>
</ul>
<p><strong>File age:</strong></p>
<ul>
<li><strong>Delete files based on the age of the file at task run time</strong></li>
<li><strong>Delete files older than the following: 2 Week(s)</strong></li>
</ul>
<p><strong>Second Task (Remove Transaction Log Backups)</strong></p>
<p><strong>Delete files of the following type:</strong></p>
<ul>
<li><strong>Backup files</strong></li>
</ul>
<p><strong>File location:</strong></p>
<ul>
<li><strong>Search folder and delete files based on an extension</strong>
<ul>
<li><strong>Folder: Z:\\Microsoft SQL Server\\MSSQL15.MSSQLSERVER\\MSSQL\\Backup\\Transaction Log\\</strong></li>
<li><strong>File Extension: trn</strong></li>
<li><strong>Include first-level subfolders: No (unchecked)</strong></li>
</ul>
</li>
</ul>
<p><strong>File age:</strong></p>
<ul>
<li><strong>Delete files based on the age of the file at task run time</strong></li>
<li><strong>Delete files older than the following: 2 Week(s)</strong></li>
</ul>
<p><strong>Third Task (History Cleanup Task)</strong></p>
<p><strong>Delete historical data:</strong></p>
<ul>
<li><strong>Backup and restore history</strong></li>
<li><strong>SQL Server Agent job history</strong></li>
<li><strong>Maintenance plan history</strong></li>
</ul>
<p><strong>Remove historical data older than: 4 Week(s)</strong></p>
</td>
</tr>
</table>

#### Create maintenance plan to remove old Full and Differential backups

1. Open **SQL Server Management Studio**.
2. In **Object Explorer**, expand **Management**, right-click **Maintenance
   Plans**, and click **Maintenance Plan Wizard**.
3. In the **Maintenance Plan Wizard** window:
   1. On the starting page, click **Next**.
   2. On the **Select Plan Properties** page:
      1. In the **Name** box, type **Remove Old Database Backups**.
      2. In the **Schedule** section, click **Change...**
      3. In the **New Job Schedule** window, configure the settings according to
         the configuration specified above, and click **OK**.
      4. Click **Next**.
   3. On the **Select Maintenance Tasks** page, in the list of maintenance
      tasks, select **Maintenance Cleanup Task**, and click **Next**.
   4. On the **Select Maintenance Task Order** page, click **Next**.
   5. On the **Define Maintenance Cleanup Task** page:
      1. In the **Folder** box, type **Z:\\Microsoft SQL
         Server\\MSSQL15.MSSQLSERVER\\MSSQL\\Backup\\**.
      2. In the **File extension** box, type **bak**.
      3. Select the **Include first-level subfolders** checkbox.
      4. In the **File age** section, configure the settings to delete files
         older than **2 Week(s)**.
      5. Click **Next**.
   6. On the **Select Report Options** page, click **Next**.
   7. On the **Complete the Wizard** page, click **Finish**.

#### Modify maintenance plan to remove old Transaction Log backups

1. Open **SQL Server Management Studio**.
2. In **Object Explorer**, expand **Management**, expand **Maintenance Plans**,
   right-click **Remove Old Database Backups** and click **Modify**.
3. In the Maintenance Plan designer:
   1. Right-click **Maintenance Cleanup Task** and click **Properties**.
   2. In the **Properties** window:
      1. If necessary, expand the **Identification** section.
      2. In the **Name** box, type **Remove Full and Differential Backups**.
   3. Use the **Toolbox** to add a new **Maintenance Cleanup Task**.
   4. Right-click the new task and click **Properties**.
   5. In the **Properties** window:
      1. If necessary, expand the **Identification** section.
      2. In the **Name** box, type **Remove Transaction Log Backups**.
   6. Right-click the **Remove Transaction Log Backups** task and click
      **Edit...**
   7. In the **Maintenance Cleanup Task** window:
      1. In the **Folder** box, type **Z:\\Microsoft SQL
         Server\\MSSQL15.MSSQLSERVER\\MSSQL\\Backup\\Transaction Log\\**.
      2. In the **File extension** box, type **trn**.
      3. In the **File age** section, configure the settings to delete files
         older than **2 Week(s)**.
      4. Click **OK**.
4. On the **File** menu, click **Save Selected Items**.

#### Modify maintenance plan to remove historical data

1. Open **SQL Server Management Studio**.
2. In **Object Explorer**, expand **Management**, expand **Maintenance Plans**,
   right-click **Remove Old Database Backups** and click **Modify**.
3. In the Maintenance Plan designer:
   1. Use the **Toolbox** to add a new **History Cleanup Task**.
   2. Right-click **History Cleanup Task** and click **Edit...**
   3. In the **History Cleanup Task** window:
      1. Ensure the **Backup and restore history** checkbox is selected.
      2. Ensure the **SQL Server Agent job history** checkbox is selected.
      3. Ensure the **Maintenance plan history** checkbox is selected.
      4. Ensure the default timespan -- **4 Week(s)** -- is specified.
      5. Click **OK**.
4. On the **File** menu, click **Save Selected Items**.

### Execute maintenance plan to backup all databases

Right-click **Full Backup of All Databases** and click **Execute**.

## Configure DPM

### Configure SMTP server for DPM

#### Configure SMTP server in DPM

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F6/E51173C49C68578735C26A4014119C2F61DBB1F6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B6/5A11E744DEA74BA4352505ED7637774E1F5F46B6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8D/7D96607EC1ADB828DE5384AAC494D42677D67C8D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/39/286112B581EC44A519DCB215AE0DE763A62DC739.png)

#### Configure spam filter in Office 365

![(screenshot)](https://assets.technologytoolbox.com/screenshots/32/82E077425AC6F28A41271EAD613AA3BA71791532.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/70/7FA4D747662F00480D7D9F1B45CC3D3404B40D70.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CF/8036CBE7D9E4D24BDFF23F58703AA7573A1AD6CF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F4/D4830AFAD42D6CA84F83E7547825EB67BC1F3CF4.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/88/CFE2C943457EE17E13F409415D70BF607C01C188.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C3/C452ADD0D18F810A65E2E3089AC0EFA6D91DB6C3.png)

### Configure DPM notifications

![(screenshot)](https://assets.technologytoolbox.com/screenshots/28/CE1A7614F53D267EE0938B5DB3A202FBD98B9428.png)

## Add disks to the storage pool

1. In DPM Administrator Console, click **Management**, and then click the **Disk
   Storage**.
2. Click **Add** on the tool ribbon. The **Add Disks to Storage Pool** dialog
   box appears. The **Available disks** section lists the disks that you can add
   to the storage pool.
3. Select one or more disks, click **Add**, and then click **OK**.

Pasted from
<[http://technet.microsoft.com/en-us/library/hh758075.aspx](http://technet.microsoft.com/en-us/library/hh758075.aspx)>

![(screenshot)](https://assets.technologytoolbox.com/screenshots/12/F7E834EC19125F786E5CA09DF4554BC44455D212.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/39/4159548686D6B8E77AE3C534B73BF3D7952DC339.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/10/C5B9986DADAF55100015FA9B5125DC210B9A1710.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1E/3F06B80EF78A3A40F653DE31DD865FD6D6CD9F1E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4A/77C4C32AFC7A433A484441173DA3F850273F2B4A.png)

## Upgrade DPM agents to DPM 2019

## Create protection group for domain controllers

Protection group name: **Domain Controllers**\
Retention range: **5 days**\
Application recovery points:

- Express Full Backup: **8:00 PM Everyday**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/41/2990BCEE38D3AF1136E0168D3A02EC8CC8DFEE41.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/06/5D5C5F73D37B3F4227C5DD8587FE8DDC70234F06.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/74/B646345DCB55B30A515DF41940973B8A8D5B4F74.png)

Ensure **Servers** is selected and then click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B9/3928FC7352E65E5B26387001B6D0EAA3781D12B9.png)

Expand **TT-DC10**, then expand **System Protection**, and then select **System
State (includes Active Directory)**.

Repeat the previous step for **TT-DC11**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4D/CE14CCEE84424D98586BE462E0A07CE834FD944D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9F/1005417D40057B5AF5352C5595801B899E9E1B9F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/91/A7AC3CC9D35DE9358FC22DBAE88EA34915AA8F91.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/31/BA7C105F9C9B334C2504D7371D9F80A826D55C31.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3B/9D4CB62169FA336A124BCB70C8E53064A4BA153B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A4/C102548568779FE5D6D328F0178DEAE47C06F7A4.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A5/62F056A6FD15F04C274A710DC70C4527955265A5.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A4/D1BEA07D2E33B60AA61AE042E26BD3105C39ECA4.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/82/7EDFEF7B758A9BFB15E930BC42D8575B807C1D82.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BA/1AC3A63E2414F10A2342C6D696AC1B46B5B41EBA.png)

## Create protection group for SQL Server databases (TEST)

Protection group name: **SQL Server Databases (TEST)**\
Retention range: **10 days**\
Synchronization frequency: **Every 4 hours**\
Application recovery points:

- Express Full Backup: **7:00 PM Everyday**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CE/E332F82552FE4C711D2E687B28EE1169427AE2CE.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/64/2FCB901232ED512BD305BCE0D08582DA8672BC64.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/80/B678373417117E40108C346679C8F330048C2880.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/08/ECAA9557048D6DC7F053F3595B0F6F7A2D8F2208.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5A/546C97814C22CBF7C69BB1F12D54A173A1E6DC5A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AA/7304968C775A559CB763324A467D86610A215DAA.png)

For **Retention range**, specify **10 days**.

For **Synchronization frequency**, specify **Every 4 hour(s)**.

In the **Application recovery points** section, click **Modify...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/65/2F292830A07D7DE7753059EB66CD5EF77ACF3365.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/47/F41BB7037633C1D36BA70947848B2B501C1BC247.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A5/E7D3A39889A4F0A0264D896B027CA831477C65A5.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/69/411F7B4DE7B998D4EE55796B17BB7F8E27BDDC69.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FB/682A84E45970EA42899318F5C68BF8F08180E7FB.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E1/0725D28E72009F997074B92C3BC2C6AA67A804E1.png)

### Add "Local System" account to SQL Server sysadmin role

On the SQL Server (HAVOK-TEST), open SQL Server Management Studio and execute
the following:

```SQL
ALTER SERVER ROLE [sysadmin] ADD MEMBER [NT AUTHORITY\SYSTEM]
GO
```

#### Reference

**Protection agent jobs may fail for SQL Server 2012 databases**\
Pasted from <[http://technet.microsoft.com/en-us/library/dn281948.aspx](http://technet.microsoft.com/en-us/library/dn281948.aspx)>

## Create protection group for SQL Server databases

Protection group name: **SQL Server Databases**\
Retention range: **10 days**\
Synchronization frequency: **Every 15 minutes**\
Application recovery points:

- Express Full Backup: **6:00 PM Everyday**

## Create protection group for file servers

Protection group name: **Critical Files**\
Retention range: **10 days**\
Synchronization frequency: **Every 30 minutes**\
File recovery points:

- Recovery points for files: **7:00 AM, 9:00 AM, 11:00 AM, 1:00 PM, 3:00, 5:00
  PM Everyday**

## Create protection group for client computers

Protection group name: **Clients - Gold**\
Retention range: **10 days**\
Synchronization frequency: **Every 1 hour(s)**\
Client computer recovery points:

- Recovery points: **8:00 AM, 10:00 AM, 12:00 PM, 2:00 PM, 4:00 PM, 6:00 PM
  Everyday**

## Create protection group for Hyper-V

Protection group name: **Hyper-V**\
Retention range: **5 days**\
Application recovery points:

- Express Full Backup: **11:00 PM Everyday**

## Set up protection for live migration

### Reference

**Set up protection for live migration**\
From <[https://docs.microsoft.com/en-us/system-center/dpm/back-up-hyper-v-virtual-machines?view=sc-dpm-2019](https://docs.microsoft.com/en-us/system-center/dpm/back-up-hyper-v-virtual-machines?view=sc-dpm-2019)>

### Install VMM console on DPM server

```PowerShell
cls
```

#### # Extract VMM setup files

```PowerShell
$imagePath = "\\TT-FS01\Products\Microsoft\System Center 2019" `
    + "\mu_system_center_virtual_machine_manager_2019_x64_dvd_06c18108.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$installer = $imageDriveLetter + ":\SCVMM_2019.exe"

& $installer
```

Destination location: **C:\\NotBackedUp\\Temp\\System Center 2019 Virtual
Machine Manager**

```PowerShell
Dismount-DiskImage -ImagePath $imagePath
```

#### Install VMM console

**To install the VMM console:**

1. Start the Virtual Machine Manager Setup Wizard.

   ```PowerShell
   & "C:\NotBackedUp\Temp\System Center 2019 Virtual Machine Manager\Setup.exe"
   ```

2. On the main setup page, click **Install**.
3. On the **Select features to install** page, select the **VMM console** check
   box, and click **Next**.
4. On the **Please read this notice** page, review the license agreement, select
   the **I agree with the terms of this notice** check box, and then click
   **Next**.
5. On the **Diagnostic and Usage Data** page, review the data collection and
   usage policy and then click **Next**.
6. On the **Installation location** page, ensure the default path is specified
   (**C:\\Program Files\\Microsoft System Center\\Virtual Machine Manager**),
   and then click **Next**.
7. On the **Port configuration** page, ensure the default port number (**8100**)
   is specified for communication with the VMM management server, and click
   **Next**.
8. On the **Installation summary** page, review your selections and do one of
   the following:

   - Click **Previous** to change any selections.
   - Click **Install** to install the VMM console.

   After you click **Install**, the **Installing features** page appears and
   installation progress is displayed.

   > **Important**
   >
   > During setup, VMM enables the following firewall rules, which remain in
   > effect even if you later uninstall VMM:
   >
   > - File Server Remote Management
   > - Windows Standards-Based Storage Management firewall rules

9. On the **Setup completed...** page:
   1. Review any warnings that occurred.
   2. Clear the **Check for the latest Virtual Machine Manager updates**
      checkbox.
   3. Clear the **Open the VMM console when this wizard closes** checkbox.
   4. Click **Close** to finish the installation.

```PowerShell
cls
```

#### # Remove temporary VMM setup files

```PowerShell
Remove-Item `
    -Path "C:\NotBackedUp\Temp\System Center 2019 Virtual Machine Manager" `
    -Recurse
```

### Update VMM using Windows Update

---

**TT-VMM01** - Run as administrator

```PowerShell
cls
```

### # Add DPM machine account as Read-Only Administrator in VMM

```PowerShell
$userRole = Get-SCUserRole -Name "DPM Servers"

Set-SCUserRole -UserRole $userRole -AddMember @("TECHTOOLBOX\TT-DPM06`$")
```

---

```PowerShell
cls
```

### # Connect DPM server to VMM server

```PowerShell
Set-DPMGlobalProperty -DPMServerName TT-DPM06 -KnownVMMServers TT-VMM01
```

```PowerShell
cls
```

## # Configure monitoring using System Center Operations Manager

### # Install SCOM agent

```PowerShell
$msiPath = "\\TT-FS01\Products\Microsoft\System Center 2019\SCOM\agent\AMD64" `
    + "\MOMAgent.msi"

msiexec.exe /i $msiPath `
    MANAGEMENT_GROUP=HQ `
    MANAGEMENT_SERVER_DNS=TT-SCOM01C `
    ACTIONS_USE_COMPUTER_ACCOUNT=1
```

### Approve manual agent install in Operations Manager

```PowerShell
logoff
```

---

**TT-ADMIN04** - Run as administrator

```PowerShell
cls
```

### # Disable setup account for System Center

```PowerShell
Disable-ADAccount -Identity setup-systemcenter
```

---

```PowerShell
cls
```

## # Update PowerShell help

```PowerShell
Update-Help
```

## Install updates using Windows Update

> **Note**
>
> Repeat until there are no updates available for the computer.

## Expand L: (Log01) drive

---

**TT-ADMIN04** - Run as administrator

```PowerShell
cls
```

### # Increase size of "Log01" VHD

```PowerShell
$vmHost = "TT-HV05F"
$vmName = "TT-DPM06"

Resize-VHD `
    -ComputerName $vmHost `
    -Path ("E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
        + $vmName + "_Log01.vhdx") `
    -SizeBytes 2GB
```

---

```PowerShell
cls
```

### # Extend partition

```PowerShell
$driveLetter = "L"

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

## Expand T: (Temp01) drive

---

**TT-ADMIN04** - Run as administrator

```PowerShell
cls
```

### # Increase size of "Temp01" VHD

```PowerShell
$vmHost = "TT-HV05F"
$vmName = "TT-DPM06"

Resize-VHD `
    -ComputerName $vmHost `
    -Path ("E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
        + $vmName + "_Temp01.vhdx") `
    -SizeBytes 2GB
```

---

```PowerShell
cls
```

### # Extend partition

```PowerShell
$driveLetter = "T"

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

**TODO:**

```PowerShell
cls
```

## # Enter a product key and activate Windows

```PowerShell
slmgr /ipk {product key}
```

> **Note**
>
> When notified that the product key was set successfully, click **OK**.

```Console
slmgr /ato
```

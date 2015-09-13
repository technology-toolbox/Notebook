# CYCLOPS - Windows Server 2012 R2 Standard

Wednesday, September 9, 2015
4:53 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Backup SQL Server Reporting Services encryption key

---

**CYCLOPS**

```PowerShell
$path = '\\ICEMAN\Users$\jjameson-admin\Documents\Reporting Services - CYCLOPS.snk'

& 'C:\Program Files (x86)\Microsoft SQL Server\110\Tools\Binn\RSKeyMgmt.exe' `
    -e -f $path -p {password}
```

---

## Backup TFS databases

---

**FOOBAR8**

## # Delete old VM

```PowerShell
Stop-SCVirtualMachine CYCLOPS

Remove-SCVirtualMachine CYCLOPS

Remove-Item \\BEAST\C$\NotBackedUp\VMs\CYCLOPS
```

---

---

**FOOBAR8**

## Create VM using Virtual Machine Manager

- Processors: **2**
- Memory: **Dynamic**
- Startup memory: **2 GB**
- Minimum memory: **512 GB**
- Maximum memory: **4 GB**
- VHD size (GB): **25**
- VHD file name:** CYCLOPS**
- Virtual DVD drive: **[\\\\ICEMAN\\Products\\Microsoft\\MDT-Deploy-x86.iso](\\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso)**
- Network Adapter 1:** Virtual LAN 2 - 192-168.10.x**
- Host:** BEAST**
- Automatic actions
  - **Turn on the virtual machine if it was running with the physical server stopped**
  - **Save State**
  - Operating system: **Windows Server 2012 R2 Standard**

---

## Install custom Windows Server 2012 R2 image

- On the **Task Sequence** step, select **Windows Server 2012 R2** and click **Next**.
- On the **Computer Details** step, in the **Computer name** box, type **CYCLOPS** and click **Next**.
- On the **Applications** step, do not select any applications, and click **Next**.

## # Rename local Administrator account and set password

```PowerShell
$adminUser = [ADSI] 'WinNT://./Administrator,User'
$adminUser.Rename('foo')
$adminUser.SetPassword('{password}')

logoff
```

## # Select "High performance" power scheme

```PowerShell
powercfg.exe /L
powercfg.exe /S SCHEME_MIN
powercfg.exe /L
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

## # Rename network connection

```PowerShell
Get-NetAdapter -Physical

Get-NetAdapter -InterfaceDescription 'Microsoft Hyper-V Network Adapter' |
    Rename-NetAdapter -NewName 'LAN 1 - 192.168.10.x'
```

## # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName 'Jumbo*'

Set-NetAdapterAdvancedProperty `
    -Name 'LAN 1 - 192.168.10.x' `
    -DisplayName 'Jumbo Packet' `
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

## # Enable firewall rules for inbound "ping" requests (required for POSHPAIG)

```PowerShell
$profile = Get-NetFirewallProfile "Domain"

Get-NetFirewallRule -AssociatedNetFirewallProfile $profile |
    Where-Object { $_.DisplayName -eq "File and Printer Sharing (Echo Request - ICMPv4-In)" `
        -or $_.DisplayName -eq "File and Printer Sharing (Echo Request - ICMPv6-In)" } |
    Enable-NetFirewallRule
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
| 0    | C:           | 25 GB       | 4K                   | OSDisk       |
| 1    | D:           | 51 GB       | 4K                   | Data01       |

---

**FOOBAR8**

### # Add disks to virtual machine

```PowerShell
$vmHost = 'BEAST'
$vmName = 'CYCLOPS'

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 51GB
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

## Create service accounts for TFS

---

**FOOBAR8**

### # Create the "TFS Reports" service account

```PowerShell
$displayName = 'Service account for Team Foundation Server (Reports)'
$defaultUserName = 's-tfs-reports'

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

### # Create the "TFS Build" service account

```PowerShell
$displayName = 'Service account for Team Foundation Server (Build)'
$defaultUserName = 's-tfs-build'

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

## Install SQL Server Reporting Services

### Reference

**Set up SQL Server for TFS**\
Pasted from <[http://msdn.microsoft.com/en-us/library/jj620927.aspx](http://msdn.microsoft.com/en-us/library/jj620927.aspx)>

**Note: **.NET Framework 3.5 is required for SQL Server Reporting Services.

```PowerShell
cls
```

### # Install .NET Framework 3.5

```PowerShell
$sourcePath = '\\ICEMAN\Products\Microsoft\Windows Server 2012 R2\Sources\SxS'

Install-WindowsFeature NET-Framework-Core -Source $sourcePath
```

### # Install SQL Server Reporting Services

---

**FOOBAR8**

#### # Insert the SQL Server 2014 installation media

```PowerShell
$vmHost = 'BEAST'
$vmName = 'CYCLOPS'

$isoPath = '\\ICEMAN\Products\Microsoft\SQL Server 2014\en_sql_server_2014_enterprise_edition_x64_dvd_3932700.iso'

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $isoPath
```

---

```PowerShell
cls
```

### # Launch SQL Server setup

```PowerShell
& X:\Setup.exe
```

On the **Feature Selection** step, select **Reporting Services - Native**.

On the **Server Configuration** step, on the **Service Accounts** tab:

- In the **Account Name** column for **SQL Server Reporting Services**, type **NT AUTHORITY\\NETWORK SERVICE**.
- In the **Startup Type** column for **SQL Server Reporting Services**, ensure **Automatic** is selected.

## [HAVOK] Restore TFS databases (OLTP)

## [HAVOK] Restore TFS Analysis Services database

[HAVOK]

USE [master]\
GO\
DROP USER [TECHTOOLBOX\\CYCLOPS\$]\
GO\
USE [msdb]\
GO\
DROP SCHEMA [TECHTOOLBOX\\CYCLOPS\$]\
GO\
DROP USER [TECHTOOLBOX\\CYCLOPS\$]\
GO\
USE [Tfs_Configuration]\
GO\
DROP USER [TECHTOOLBOX\\CYCLOPS\$]\
GO\
USE [ReportServer_TFS]\
GO\
DROP SCHEMA [TECHTOOLBOX\\CYCLOPS\$]\
GO\
DROP USER [TECHTOOLBOX\\CYCLOPS\$]\
GO\
USE [ReportServer_TFSTempDB]\
GO\
DROP SCHEMA [TECHTOOLBOX\\CYCLOPS\$]\
GO\
DROP USER [TECHTOOLBOX\\CYCLOPS\$]\
GO\
USE [Tfs_Configuration]\
GO\
DROP USER [TECHTOOLBOX\\CYCLOPS\$]\
GO\
USE [Tfs_DefaultCollection]\
GO\
DROP USER [TECHTOOLBOX\\CYCLOPS\$]\
GO\
USE [Tfs_Warehouse]\
GO\
DROP USER [TECHTOOLBOX\\CYCLOPS\$]\
GO\
USE [master]\
GO\
DROP LOGIN [TECHTOOLBOX\\CYCLOPS\$]\
GO

USE [master]\
GO\
CREATE LOGIN [TECHTOOLBOX\\CYCLOPS\$] FROM WINDOWS WITH DEFAULT_DATABASE=[master]\
GO\
USE [ReportServer_TFS]\
GO\
CREATE USER [TECHTOOLBOX\\CYCLOPS\$] FOR LOGIN [TECHTOOLBOX\\CYCLOPS\$]\
GO\
USE [ReportServer_TFS]\
GO\
ALTER ROLE [db_owner] ADD MEMBER [TECHTOOLBOX\\CYCLOPS\$]\
GO\
USE [ReportServer_TFS]\
GO\
ALTER ROLE [RSExecRole] ADD MEMBER [TECHTOOLBOX\\CYCLOPS\$]\
GO\
USE [ReportServer_TFSTempDB]\
GO\
CREATE USER [TECHTOOLBOX\\CYCLOPS\$] FOR LOGIN [TECHTOOLBOX\\CYCLOPS\$]\
GO\
USE [ReportServer_TFSTempDB]\
GO\
ALTER ROLE [db_owner] ADD MEMBER [TECHTOOLBOX\\CYCLOPS\$]\
GO\
USE [ReportServer_TFSTempDB]\
GO\
ALTER ROLE [RSExecRole] ADD MEMBER [TECHTOOLBOX\\CYCLOPS\$]\
GO

## Configure Reporting Services for TFS (using restored database)

1. Start **Reporting Services Configuration Manager**. If prompted by User Account Control to allow the program to make changes to the computer, click **Yes**.
2. In the **Reporting Services Configuration Connection** dialog box, ensure the name of the server and SQL Server instance are both correct, and then click **Connect**.
3. In the **Report Server Status** pane, click **Start** if the server is not already started.
4. In the navigation pane, click **Service Account**.
5. In the **Service Account** pane, ensure **Use built-in account** is selected and the account is set to **Network Service**.
6. In the navigation pane, click **Web Service URL**.
7. In the **Web Service URL **pane:
   1. Confirm the following warning message appears:
   2. Click **Apply**.
8. In the navigation pane, click **Database**.
9. In the **Report Server Database** pane, click **Change Database**.
10. In the **Report Server Database Configuration Wizard** window:
    1. In the **Action** pane, ensure **Choose an existing report server database** is selected, and then click **Next**.
    2. In the **Database Server** pane, type the name of the database server (**HAVOK**) in the **Server Name** box, click **Test Connection** and confirm the test succeeded, and then click **Next**.
    3. In the **Database **pane, in the **Report Server Database** list, select the restored database (**ReportServer_TFS**) and then click **Next**.
    4. In the **Credentials **pane, ensure **Authentication Type** is set to **Service Credentials** and then click **Next**.
    5. On the **Summary** page, verify the information is correct, and then click **Next**.
    6. Click **Finish** to close the wizard.
11. In the navigation pane, click **Report Manager URL**.
12. In the **Report Manager URL **pane:
    1. Confirm the following warning message appears:
    2. Click **Apply**.
13. In the navigation pane, click **Encryption Keys**.
14. In the **Encryption Keys **pane, click **Restore**.
15. In the **Restore Encryption Key** window:
    1. In the **File Location **box, specify the location of the backup file for the encryption key.
    2. In the **Password** box, type the password for the backup file.
    3. Click **OK**.
16. In the navigation pane, click **Scale-out Deployment**.
17. In the **Scale-out Deployment** pane, choose the previous report server from the scale-out deployment status page and click **Remove Server**. When prompted to confirm removing the selected server, click **OK**.

Report Server Web Service is not configured. Default values have been provided to you. To accept these defaults simply press the Apply button, else change them and then press Apply.

The Report Manager virtual directory name is not configured. To configure the directory, enter a name or use the default value that is provided, and then click Apply.

**[\\\\ICEMAN\\Users\$\\jjameson-admin\\Documents\\Reporting Services - CYCLOPS.snk](\\ICEMAN\Users$\jjameson-admin\Documents\Reporting Services - CYCLOPS.snk)**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F4/DA46661DC05ACB4806905D2FD15883565D069DF4.png)

**Workaround:**

```Console
    cd "\Program Files (x86)\Microsoft SQL Server\120\Tools\Binn"
    .\RSKeyMgmt.exe -l
    .\RSKeyMgmt.exe -r e56831c8-61ef-44f7-9295-c8a49acf417f
```

### Reference

**Fix up the report server**\
Pasted from <[http://msdn.microsoft.com/en-us/library/jj620932.aspx](http://msdn.microsoft.com/en-us/library/jj620932.aspx)>

## Fix permissions for SQL Server Reporting Services

---

**HAVOK**

```SQL
USE master
GO
GRANT EXECUTE ON master.dbo.xp_sqlagent_notify TO RSExecRole
GO
GRANT EXECUTE ON master.dbo.xp_sqlagent_enum_jobs TO RSExecRole
GO
GRANT EXECUTE ON master.dbo.xp_sqlagent_is_starting TO RSExecRole
GO
USE msdb
GO
-- Permissions for SQL Agent objects
GRANT EXECUTE ON msdb.dbo.sp_add_category TO RSExecRole
GO
GRANT EXECUTE ON msdb.dbo.sp_add_job TO RSExecRole
GO
GRANT EXECUTE ON msdb.dbo.sp_add_jobschedule TO RSExecRole
GO
GRANT EXECUTE ON msdb.dbo.sp_add_jobserver TO RSExecRole
GO
GRANT EXECUTE ON msdb.dbo.sp_add_jobstep TO RSExecRole
GO
GRANT EXECUTE ON msdb.dbo.sp_delete_job TO RSExecRole
GO
GRANT EXECUTE ON msdb.dbo.sp_help_category TO RSExecRole
GO
GRANT EXECUTE ON msdb.dbo.sp_help_job TO RSExecRole
GO
GRANT EXECUTE ON msdb.dbo.sp_help_jobschedule TO RSExecRole
GO
GRANT EXECUTE ON msdb.dbo.sp_verify_job_identifiers TO RSExecRole
GO
GRANT SELECT ON msdb.dbo.syscategories TO RSExecRole
GO
GRANT SELECT ON msdb.dbo.sysjobs TO RSExecRole
GO
USE [master]
GO
```

---

### Reference

**Reporting Errors with TFS Migration/Upgrade**\
From <[http://www.technologytoolbox.com/blog/jjameson/archive/2010/05/20/reporting-errors-with-tfs-migration-upgrade.aspx](http://www.technologytoolbox.com/blog/jjameson/archive/2010/05/20/reporting-errors-with-tfs-migration-upgrade.aspx)>

## Update data sources in SQL Server Reporting Services

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0A/E057A31E0B941D84F7E621C21405B89E43377F0A.png)

Change the credentials to use the new service account (**TECHTOOLBOX\\s-tfs-reports**).

Repeat for the **Tfs2010ReportDS **data source.

## Install TFS 2015

---

**FOOBAR8**

### # Insert the TFS 2015 installation media

```PowerShell
$vmHost = 'BEAST'
$vmName = 'CYCLOPS'

$isoPath = '\\ICEMAN\Products\Microsoft\Team Foundation Server 2015\en_visual_studio_team_foundation_server_2015_x86_x64_dvd_6909713.iso'

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $isoPath
```

---

```PowerShell
cls
```

### # Launch TFS setup

```PowerShell
& X:\tfs_server.exe
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EA/6D39BC62E175B233B1441C7C6FB65024A2604FEA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D4/4DA3F24CA364993CF60A7D5B90046260FBA7A3D4.png)

Wait for the installation to finish. The Team Foundation Server Configuration Center appears.

## Upgrade TFS

In the **Team Foundation Server Configuration Center**, click **Upgrade** and then click **Start Wizard**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F2/4A2A32469EDCDCFF3F754A01CF39F6224EE23FF2.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AC/025AC21DDB979B642E4269FEE285FD42DA760BAC.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9B/82664C2D9B59736471CC319DD5BDCB72784DDC9B.png)

In the **SQL Server Instance** box, type **HAVOK** and then click **List Available Databases**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5B/7C115E191D9DB9A19EB85B59A427AEBC8A34465B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CC/4D35842C657B19C45280B37EC1D1E169D04128CC.png)

On the **File Cache Folder** page, ensure the specified folder refers to the Data01 drive (**D:\\TfsData\\ApplicationTier\\_fileCache**).

![(screenshot)](https://assets.technologytoolbox.com/screenshots/13/F832002897E40E6E38F2A99B3A68E74F84C07D13.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/05/B10F6AE06641C5EF006E5CF9844D24429FBDEE05.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/08/0B970249C5BC06E3BFDE8C36C697FC9983FE8408.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A5/747F9EF044979304487AE79B870A5B18466170A5.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CD/F9F6CF11DAB349696B8F3EF4D2B849D942C446CD.png)

In the **SQL Server Instance** box, type the name of the database server and then click **Test**.

Click **List Available Databases**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B0/50D27C24BAB638F122E3AF46545647113AC34FB0.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E5/B17CE655A08D3D7C3E5E000C5263A698705E73E5.png)

In the **SQL Server Analysis Services Instance** box, type **HAVOK** and then click **Test**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E7/360610CA0F336BF7CD2B27828CB04C6C9050FEE7.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/98/BF8B972C4DAAE4664EB79955EFE0C4E9846AA998.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/36/379546B700170E1CB3A4885C3650C975DC8B1836.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BF/C8B35BC6B1C8CEA42EBC9BE2DD549EB48917BFBF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C6/8F50C2056D8537F0B8106A925FB8B0BEA8B295C6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/27/C98A4546E3112409BB89368ED8D20EBE742BA427.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3B/8FB9410E48A0CC3251B4A35AC390C34BE5D1D23B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AB/15E87EE93F8864E5287D10B6FE29C2B94D7B98AB.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D6/1E86B8B4EC0B141701DC74018F86AAC43A87CBD6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1B/1148210CEE251AE7D531A0A0BC2808498FA4571B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/00/BAEC0807EA9070552CB3066BA09A55E56BFEE000.png)

As part of TFS configuration IIS dynamic compression was enabled to improve performance. This is a system-wide setting for IIS. See this link for additional details [http://go.microsoft.com/fwlink/?LinkId=534011](http://go.microsoft.com/fwlink/?LinkId=534011)\
\
Firewall exception added for port 8080\
\
The time allowed for Windows services to start was increased from 30 seconds to 600 seconds. This affects all Windows services on this server. (The registry value set is HKLM\\SYSTEM\\CurrentControlSet\\Control\\!ServicesPipeTimeout.)\
\
TF255450: The notification URL for this instance of Team Foundation Server is [http://cyclops:8080/tfs/](http://cyclops:8080/tfs/) and might need to be updated. You can modify the notification URL in the Team Foundation Administration Console by using the Change URLs command.\
\
To configure new features for team projects, follow the steps in [https://msdn.microsoft.com/library/ff432837(v=vs.140).aspx](https://msdn.microsoft.com/library/ff432837(v=vs.140).aspx)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8D/308EEE7CC67DF31631D1AB73D1E2F4B37401A08D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/96/5D97A10BC50561FE05645FEC3723DE275800B596.png)

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

**TODO:**

## Resolve SCOM alerts due to disk fragmentation

### Alert Name

Logical Disk Fragmentation Level is high

### Alert Description

The disk C: (C:) on computer CYCLOPS.corp.technologytoolbox.com has high fragmentation level. File Percent Fragmentation value is 15%. Defragmentation recommended: true.

### Resolution

#### # Copy Toolbox content

```PowerShell
robocopy \\iceman\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E
```

#### # Create scheduled task to optimize drives

```PowerShell
[string] $xml = Get-Content `
  'C:\NotBackedUp\Public\Toolbox\Scheduled Tasks\Optimize Drives.xml'

Register-ScheduledTask -TaskName "Optimize Drives" -Xml $xml
```

# CYCLOPS-TEST - Windows Server 2012 R2 Standard

Sunday, January 05, 2014
4:56 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

---

**FOOBAR8**

## Create VM using Virtual Machine Manager

- Processors: **2**
- Memory: **4 GB**
- Startup memory: **2 GB**
- Minimum memory: **512 GB**
- Maximum memory: **4 GB**
- VHD size (GB): **25**
- VHD file name:** CYCLOPS-TEST**
- Virtual DVD drive: **[\\\\ICEMAN\\Products\\Microsoft\\MDT-Deploy-x86.iso](\\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso)**
- Network Adapter 1:** Virtual LAN 2 - 192-168.10.x**
- Host:** ROGUE**
- Automatic actions
  - **Turn on the virtual machine if it was running with the physical server stopped**
  - **Save State**
  - Operating system: **Windows Server 2012 R2 Standard**

---

## Install custom Windows Server 2012 R2 image

- On the **Task Sequence** step, select **Windows Server 2012 R2** and click **Next**.
- On the **Computer Details** step, in the **Computer name** box, type **CYCLOPS-TEST** and click **Next**.
- On the **Applications** step, do not select any applications, and click **Next**.

## # Rename local Administrator account and set password

```PowerShell
$adminUser = [ADSI] 'WinNT://./Administrator,User'
$adminUser.Rename('foo')
$adminUser.SetPassword('{password}')

logoff
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

```PowerShell
cls
```

## # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
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
$sourcePath = "\\ICEMAN\Products\Microsoft\Windows Server 2012 R2\Sources\SxS"

Install-WindowsFeature NET-Framework-Core -Source $sourcePath
```

### # Install SQL Server Reporting Services

---

**FOOBAR8**

### # Insert the SQL Server 2014 installation media

```PowerShell
$vmHost = "ROGUE"
$vmName = "CYCLOPS-TEST"

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

## [HAVOK-TEST] Restore TFS databases (OLTP)

## [HAVOK-TEST] Restore TFS Analysis Services database

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
    2. In the **Database Server** pane, type the name of the database server (**HAVOK-TEST**) in the **Server Name** box, click **Test Connection** and confirm the test succeeded, and then click **Next**.
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

## -- Fix permissions for SQL Server Reporting Services

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
-- Permissions for SQL Agent SP's
GRANT EXECUTE ON msdb.dbo.sp_help_category TO RSExecRole
GO
GRANT EXECUTE ON msdb.dbo.sp_add_category TO RSExecRole
GO
GRANT EXECUTE ON msdb.dbo.sp_add_job TO RSExecRole
GO
GRANT EXECUTE ON msdb.dbo.sp_add_jobserver TO RSExecRole
GO
GRANT EXECUTE ON msdb.dbo.sp_add_jobstep TO RSExecRole
GO
GRANT EXECUTE ON msdb.dbo.sp_add_jobschedule TO RSExecRole
GO
GRANT EXECUTE ON msdb.dbo.sp_help_job TO RSExecRole
GO
GRANT EXECUTE ON msdb.dbo.sp_delete_job TO RSExecRole
GO
GRANT EXECUTE ON msdb.dbo.sp_help_jobschedule TO RSExecRole
GO
GRANT EXECUTE ON msdb.dbo.sp_verify_job_identifiers TO RSExecRole
GO
GRANT SELECT ON msdb.dbo.sysjobs TO RSExecRole
GO
GRANT SELECT ON msdb.dbo.syscategories TO RSExecRole
GO
```

### Reference

**Reporting Errors with TFS Migration/Upgrade**\
From <[http://www.technologytoolbox.com/blog/jjameson/archive/2010/05/20/reporting-errors-with-tfs-migration-upgrade.aspx](http://www.technologytoolbox.com/blog/jjameson/archive/2010/05/20/reporting-errors-with-tfs-migration-upgrade.aspx)>

## Update data sources in SQL Server Reporting Services

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C9/1B7BAB9A4311EC788D03CF1A1C17D5C476D984C9.png)

Repeat for the remaining data sources:

- **Tfs2010ReportDS**
- **TfsOlapReportDS**
- **TfsReportDS**

## Install TFS 2015

---

**FOOBAR8**

### # Insert the TFS 2015 installation media

```PowerShell
$vmHost = "ROGUE"
$vmName = "CYCLOPS-TEST"

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

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F2/4A2A32469EDCDCFF3F754A01CF39F6224EE23FF2.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AC/025AC21DDB979B642E4269FEE285FD42DA760BAC.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B9/68F65E532E77C24D3887873A477B6D69DF7AAFB9.png)

In the **SQL Server Instance** box, type **HAVOK-TEST** and then click **List Available Databases**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8A/A2DF0B335515AE0CE5DD7E05260BEE1919140D8A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C6/5339A5353F91CB4A787C2484E8C6136EA9EE66C6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2F/7FB3C911AE85A76BC95FF7ACD3CD875D58D0772F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C4/5764BF7BE6CA7438E7FEA2B3F0EF242ECBBA5FC4.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/08/0B970249C5BC06E3BFDE8C36C697FC9983FE8408.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/05/A4B01A5428A882E6A0CFC59AEF0E9F3FE6EA8005.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8B/A3E6619EBC99E5E7FD74A0559F7269A0E0EFEC8B.png)

In the **SQL Server Instance** box, type the name of the database server and then click **Test**.

Click **List Available Databases**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/84/B283B78A85597F4E9F940004E46277BF90985084.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/65/147580D91919D84ABB6C0BDAC15ECAA7C8CA7B65.png)

In the **SQL Server Analysis Services Instance** box, type **HAVOK-TEST** and then click **Test**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/98/BF8B972C4DAAE4664EB79955EFE0C4E9846AA998.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3C/DD886632C13B26036C3A206FE9DA45290E2A6E3C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BF/C8B35BC6B1C8CEA42EBC9BE2DD549EB48917BFBF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/23/1D89F2C14D7E0B47C1C71350B8F31325B66CAF23.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/60/165976ACFA5FA6A023943DD604C05890323AF660.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3B/8FB9410E48A0CC3251B4A35AC390C34BE5D1D23B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AB/15E87EE93F8864E5287D10B6FE29C2B94D7B98AB.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/51/D8F594A4DBD08489E60503E6DA6CCAD66C3BAF51.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DB/C70B35BECEE42A03FC506228D81198F6411216DB.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A3/D54C17E7B19D145CD710F6C63740052A15566BA3.png)

As part of TFS configuration IIS dynamic compression was enabled to improve performance. This is a system-wide setting for IIS. See this link for additional details [http://go.microsoft.com/fwlink/?LinkId=534011](http://go.microsoft.com/fwlink/?LinkId=534011)\
\
Firewall exception added for port 8080\
\
The time allowed for Windows services to start was increased from 30 seconds to 600 seconds. This affects all Windows services on this server. (The registry value set is HKLM\\SYSTEM\\CurrentControlSet\\Control\\!ServicesPipeTimeout.)\
\
TF255450: The notification URL for this instance of Team Foundation Server is [http://cyclops:8080/tfs/](http://cyclops:8080/tfs/) and might need to be updated. You can modify the notification URL in the Team Foundation Administration Console by using the Change URLs command.\
\
To configure new features for team projects, follow the steps in [https://msdn.microsoft.com/library/ff432837(v=vs.140).aspx](https://msdn.microsoft.com/library/ff432837(v=vs.140).aspx)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/33/8E046CB51EEB8A019E927C3CE35282363C2EEF33.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7B/70B89591DA425152ABF5E703E62FE6BF4C1E127B.png)

## Update Notification URL

![(screenshot)](https://assets.technologytoolbox.com/screenshots/89/1D7314F9A61DBDCE755DC40E9CADC77819134E89.png)

Click **Change URLs**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AB/FFF373F549B7236156BA3BAD0622504256DA4CAB.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/32/20BAA402F0C4296CD996686BFABB70AADD865B32.png)

## Configure e-mail alert settings for TFS

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4D/C2E6B7A25589320B29588F538DCF1FA4C8B53A4D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/80/B0562BF81825626FC272B6C57ACBC70BF0A73080.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2C/EE966409F83C631F2849D5A4A344A503A8E22E2C.png)

In the **Email Alert Settings** section, click **Send Test Email**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D4/8952F39687F5E0BDDD0AF1FE8111711D5BB056D4.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/27/FD7C5983AEB099CF0FB38CC5C48B97DC7B141627.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E8/FBD6EBD44D68A24D2AE46EA62D1EFF2C99B733E8.png)

```PowerShell
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

The disk C: (C:) on computer CYCLOPS-TEST.corp.technologytoolbox.com has high fragmentation level. File Percent Fragmentation value is 15%. Defragmentation recommended: true.

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

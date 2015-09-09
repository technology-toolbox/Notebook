# TFS2015-DEV - Windows Server 2012 R2 Standard

Wednesday, September 9, 2015
9:16 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

---

**FOOBAR8**

## # Create virtual machine

```PowerShell
$vmHost = 'WOLVERINE'
$vmName = 'TFS2015-DEV'

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path D:\NotBackedUp\VMs `
    -MemoryStartupBytes 2GB `
    -SwitchName "Virtual LAN 2 - 192.168.10.x"

Set-VMMemory `
    -ComputerName $vmHost `
    -VMName $vmName `
    -DynamicMemoryEnabled $true `
    -MaximumBytes 4GB

Set-VMProcessor -ComputerName $vmHost -VMName $vmName -Count 4

$vhdPath = "D:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 25GB

Add-VMHardDiskDrive -ComputerName $vmHost -VMName $vmName -Path $vhdPath

Start-VM -ComputerName $vmHost -VMName $vmName
```

---

## Install custom Windows Server 2012 R2 image

Insert DVD image: [\\\\ICEMAN\\Products\\Microsoft\\MDT-Deploy-x86.iso](\\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso)

- On the **Task Sequence** step, select **Windows Server 2012 R2** and click **Next**.
- On the **Computer Details** step, in the **Computer name** box, type **TFS2015-DEV** and click **Next**.
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
| 0    | C:           | 45 GB       | 4K                   | OSDisk       |
| 1    | D:           | 51 GB       | 4K                   | Data01       |

---

**FOOBAR8**

### # Add disks to virtual machine

```PowerShell
$vmHost = 'WOLVERINE'
$vmName = 'TFS2015-DEV'

$vhdPath = "D:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
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

---

**FOOBAR8**

### # Create the "TFS reporting" service account

```PowerShell
$displayName = 'Service account for Team Foundation Server (Reports) (DEV)'
$defaultUserName = 's-tfs-reports-dev'

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

**WOLVERINE**

#### # Insert the SQL Server 2014 installation media

```PowerShell
$vmName = 'TFS2015-DEV'

$isoPath = '\\ICEMAN\Products\Microsoft\SQL Server 2014\en_sql_server_2014_enterprise_edition_x64_dvd_3932700.iso'

Set-VMDvdDrive -VMName $vmName -Path $isoPath
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

## Configure Reporting Services for TFS

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
    1. In the **Action** pane, ensure **Create a new report server database** is selected, and then click **Next**.
    2. In the **Database Server** pane, type the name of the database server (**SQL2014-DEV**) in the **Server Name** box, click **Test Connection** and confirm the test succeeded, and then click **Next**.
    3. In the **Database **pane, in the **Database Name** box, type **ReportServer_TFS**, and then click **Next**.
    4. In the **Credentials **pane, ensure **Authentication Type** is set to **Service Credentials** and then click **Next**.
    5. On the **Summary** page, verify the information is correct, and then click **Next**.
    6. Click **Finish** to close the wizard.
11. In the navigation pane, click **Report Manager URL**.
12. In the **Report Manager URL **pane:
    1. Confirm the following warning message appears:
    2. Click **Apply**.
13. In the navigation pane, click **Encryption Keys**.
14. In the **Encryption Keys **pane, click **Backup**.
15. In the **Backup Encryption Key** window:
    1. In the **File Location **box, specify the location of the backup file for the encryption key.
    2. Type the password for the backup file and click **OK**.

Report Server Web Service is not configured. Default values have been provided to you. To accept these defaults simply press the Apply button, else change them and then press Apply.

The Report Manager virtual directory name is not configured. To configure the directory, enter a name or use the default value that is provided, and then click Apply.

**[\\\\ICEMAN\\Users\$\\jjameson-admin\\Documents\\Reporting Services - TFS2015-DEV.snk](\\ICEMAN\Users$\jjameson-admin\Documents\Reporting Services - TFS2015-DEV.snk)**

## Install TFS 2015

---

**WOLVERINE**

### # Insert the TFS 2015 installation media

```PowerShell
$vmName = 'TFS2015-DEV'

$isoPath = '\\ICEMAN\Products\Microsoft\Team Foundation Server 2015\en_visual_studio_team_foundation_server_2015_x86_x64_dvd_6909713.iso'

Set-VMDvdDrive -VMName $vmName -Path $isoPath
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

## Install TFS App Tier

In the **Team Foundation Server Configuration Center**, click **Full Server** and then click **Start Wizard**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B3/B2CCBBE222349E48BD2250D9712CC63F5DE17BB3.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D8/B8C328FC5E035901933E06C4DE7899FB70E75AD8.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1F/F9C47EF4E420CBAB535CD7287A7597C7259D2F1F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/54/E960A3B8CF22076BA3E94FEF89717BEA09384E54.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FC/3366F53186404C2F6D212FB8CDBDB1C7BD4B79FC.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DE/2587C56D19E17A1862894ECC0EADA30A46E58DDE.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E1/AE36526E4C2EC79C154715776FFC9D232EEF43E1.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/34/A3ABD53E05BABE45B22FA902CF5002C1FE3FEA34.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/43/4EEC16FB4A7A57901B4C1A81D52CAC29B1D35043.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/12/A3B2661C816B67A6CAD158BB2A4B58D0E5FE3E12.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/03/DC7997237BD305094C2E854F2A9FDFA0A44F0003.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/57/3BAD16F09557EEE78C62676747EB19943820B657.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7B/96B3BAAFAE8844F93CC402E58F3035D48C9FF87B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/01/11A4D061DC007308252BFD9C881221558B84D801.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BC/66A9FFC1C5125A5DD38D3760E0A313CFC82C19BC.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/68/CFE3E99318BE029196E34DE651AAE8E159E2B868.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/78/CD73ACBB4CE798C9FDC1077D384FE342FC6A2178.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/61/115C11B3E20AAC6CBCF754D3B2A23AF54BEF7D61.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B7/63CF824AA6BF094641C66F1949A2152CF5CC40B7.png)

Click **Configure**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8D/F49B7259AF6D23CF5AC2AFE6852028F7975A9A8D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9A/132E0EDFC3ACBDB9370783EEE54B50E13AFEE09A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/81/D4A6BB4003EFE48572C57A596E0A0802DFB24F81.png)

Click **Close**. The **Team Foundation Server Administration Console** appears.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DD/0A1E209DFCC4D1ECF4295A2ECCCE4EEE6DA6DBDD.png)

## SQL Server user mapping for login TECHTOOLBOX\\TFS2015-DEV\$

<table>
<thead>
<th>
<p><strong>Database</strong></p>
</th>
<th>
<p><strong>User</strong></p>
</th>
<th>
<p><strong>Default Schema</strong></p>
</th>
<th>
<p><strong>Role Membership</strong></p>
</th>
</thead>
<tr>
<td valign='top'>
<p>master</p>
</td>
<td valign='top'>
<p>TECHTOOLBOX\\TFS2015-DEV\$</p>
</td>
<td valign='top'>
<p>dbo</p>
</td>
<td valign='top'>
<ul>
<li>public</li>
<li>RSExecRole</li>
<li>TFSEXECROLE</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>msdb</p>
</td>
<td valign='top'>
<p>TECHTOOLBOX\\TFS2015-DEV\$</p>
</td>
<td valign='top'>
<p>TECHTOOLBOX\\TFS2015-DEV\$</p>
</td>
<td valign='top'>
<ul>
<li>public</li>
<li>RSExecRole</li>
<li>SQLAgentOperatorRole</li>
<li>SQLAgentReaderRole</li>
<li>SQLAgentUserRole</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>ReportServer_TFS</p>
</td>
<td valign='top'>
<p>TECHTOOLBOX\\TFS2015-DEV\$</p>
</td>
<td valign='top'>
<p>TECHTOOLBOX\\TFS2015-DEV\$</p>
</td>
<td valign='top'>
<ul>
<li>db_owner</li>
<li>public</li>
<li>RSExecRole</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>ReportServer_TFSTempDB</p>
</td>
<td valign='top'>
<p>TECHTOOLBOX\\TFS2015-DEV\$</p>
</td>
<td valign='top'>
<p>TECHTOOLBOX\\TFS2015-DEV\$</p>
</td>
<td valign='top'>
<ul>
<li>db_owner</li>
<li>public</li>
<li>RSExecRole</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Tfs_Analysis</p>
</td>
<td valign='top'>
<p>N/A</p>
</td>
<td valign='top'>
<p>N/A</p>
</td>
<td valign='top'>
<p>TfsWarehouseAdministrator</p>
</td>
</tr>
<tr>
<td valign='top'>
<p>Tfs_Configuration</p>
</td>
<td valign='top'>
<p>TECHTOOLBOX\\TFS2015-DEV\$</p>
</td>
<td valign='top'>
<p>dbo</p>
</td>
<td valign='top'>
<ul>
<li>db_owner</li>
<li>public</li>
<li>TFSEXECROLE</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Tfs_DefaultCollection</p>
</td>
<td valign='top'>
<p>TECHTOOLBOX\\TFS2015-DEV\$</p>
</td>
<td valign='top'>
<p>dbo</p>
</td>
<td valign='top'>
<ul>
<li>db_owner</li>
<li>public</li>
<li>TFSEXECROLE</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Tfs_Warehouse</p>
</td>
<td valign='top'>
<p>TECHTOOLBOX\\TFS2015-DEV\$</p>
</td>
<td valign='top'>
<p>dbo</p>
</td>
<td valign='top'>
<ul>
<li>public</li>
<li>TFSEXECROLE</li>
</ul>
</td>
</tr>
</table>

## SQL Server user mapping for login TECHTOOLBOX\\s-tfs-reports-dev

| **Database**  | **User**                       | **Default Schema** | **Role Membership**    |
| ------------- | ------------------------------ | ------------------ | ---------------------- |
| Tfs_Analysis  | N/A                            | N/A                | TfsWarehouseDataReader |
| Tfs_Warehouse | TECHTOOLBOX\\s-tfs-reports-dev | dbo                | public                 |

# TT-SCOM03A - Windows Server 2016

Wednesday, November 27, 2019
9:41 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure infrastructure

---

**TT-ADMIN02 - Run as administrator**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "TT-SCOM03A"
$vmPath = "E:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 35GB `
    -MemoryStartupBytes 8GB `
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

### Install custom Windows Server 2016 image

- On the **Task Sequence** step, select **Windows Server 2016** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **TT-SCOM03A**.
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

### Configure networking

#### Configure static IP address

---

**TT-ADMIN02 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

##### # Configure static IP address using VMM

```PowerShell
$vmName = "TT-SCOM03A"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Management VM Network"
$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"
$ipPool = Get-SCStaticIPAddressPool -Name "Management-30 Address Pool"

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

| **Disk** | **Drive Letter** | **Volume Size** | **Allocation Unit Size** | **Volume Label** |
| -------- | ---------------- | --------------- | ------------------------ | ---------------- |
| 0        | C:               | 35 GB           | 4K                       | OSDisk           |

```PowerShell
cls
```

### # Enable performance counters for Server Manager

```PowerShell
$taskName = "\Microsoft\Windows\PLA\Server Manager Performance Monitor"

Enable-ScheduledTask -TaskName $taskName

logman start "Server Manager Performance Monitor"
```

### # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

> **Note**
>
> PowerShell remoting must be enabled for remote Windows Update using PoshPAIG ([https://github.com/proxb/PoshPAIG](https://github.com/proxb/PoshPAIG)).

---

**TT-ADMIN02 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
$vmName = "TT-SCOM03A"
```

### # Set first boot device to hard drive

```PowerShell
$vmHost = "TT-HV05A"

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

### # Move computer to different OU

```PowerShell
$targetPath = ("OU=System Center Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

### # Configure Windows Update

##### # Add machine to security group for Windows Update configuration

```PowerShell
Add-ADGroupMember -Identity "Windows Update - Slot 22" -Members ($vmName + '$')
```

---

### Add virtual machine to Hyper-V protection group in DPM

## Prepare for SCOM installation

### Reference

**System requirements for System Center 2016 - Operations Manager**\
From <[https://technet.microsoft.com/en-us/system-center-docs/om/plan/system-requirements](https://technet.microsoft.com/en-us/system-center-docs/om/plan/system-requirements)>

### Create SCOM service accounts

### Login as local administrator

```PowerShell
cls
```

### # Add SCOM "Data Access" service account to local Administrators group

```PowerShell
$localGroup = "Administrators"
$domain = "TECHTOOLBOX"
$serviceAccount = "s-scom-das"

([ADSI]"WinNT://./$localGroup,group").Add(
    "WinNT://$domain/$serviceAccount,user")
```

### # Add SCOM administrators domain group to local Administrators group

```PowerShell
$localGroup = "Administrators"
$domain = "TECHTOOLBOX"
$domainGroup = "SCOM Admins"

([ADSI]"WinNT://./$localGroup,group").Add(
    "WinNT://$domain/$domainGroup,group")
```

```PowerShell
cls
```

### # Install SSL certificate

##### # Install certificate for Reporting Services and Operations Manager web console

```PowerShell
$certPassword = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted for the secure string, type the password for the exported certificate.

```PowerShell
$certFile = "\\TT-FS01\Backups\Certificates\Internal" `
    + "\systemcenter.technologytoolbox.com.pfx"

Import-PfxCertificate `
    -FilePath $certFile `
    -CertStoreLocation Cert:\LocalMachine\My `
    -Password $certPassword
```

---

**TT-ADMIN02 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Enable setup account for System Center

```PowerShell
Enable-ADAccount -Identity setup-systemcenter
```

---

### Login as TECHTOOLBOX\\setup-systemcenter

```PowerShell
cls
```

### # Install and configure SQL Server Reporting Services

#### # Install SQL Server 2016 Reporting Services

```PowerShell
$imagePath = "\\TT-FS01\Products\Microsoft\SQL Server 2016" `
    + "\en_sql_server_2016_standard_with_service_pack_1_x64_dvd_9540929.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$installer = $imageDriveLetter + ":\setup.exe"

& $installer
```

On the **Feature Selection** step, select **Reporting Services - Native**.

On the **Server Configuration** step, on the **Service Accounts** tab:

- In the **Account Name** column for **SQL Server Reporting Services**, type **NT AUTHORITY\\NETWORK SERVICE**.
- In the **Startup Type** column for **SQL Server Reporting Services**, ensure **Automatic** is selected.

#### Install SQL Server 2016 Service Pack 2

---

**SQL Server Management Studio - TT-SQL01**

#### -- Temporarily add SCOM installation account to sysadmin role in SQL Server

```SQL
USE [master]
GO
CREATE LOGIN [TECHTOOLBOX\setup-systemcenter] FROM WINDOWS
GO
ALTER SERVER ROLE [sysadmin]
ADD MEMBER [TECHTOOLBOX\setup-systemcenter]
GO
```

---

#### Configure SQL Server Reporting Services

1. Start **Reporting Services Configuration Manager**. If prompted by User Account Control to allow the program to make changes to the computer, click **Yes**.
2. In the **Reporting Services Configuration Connection** dialog box, ensure the name of the server and SQL Server instance are both correct, and then click **Connect**.
3. In the **Report Server Status** pane, click **Start** if the server is not already started.
4. In the navigation pane, click **Service Account**.
5. In the **Service Account** pane, ensure **Use built-in account** is selected and the account is set to **Network Service**.
6. In the navigation pane, click **Web Service URL**.
7. In the **Web Service URL **pane:
   1. Confirm the following warning message appears:
   2. In the **Report Server Web Service Site identification** section, in the **HTTPS Certificate** dropdown list, select the SSL certificate installed previously for System Center (**systemcenter.technologytoolbox.com**).
   3. Click **Apply**.
8. In the navigation pane, click **Database**.
9. In the **Report Server Database** pane, click **Change Database**.
10. In the **Report Server Database Configuration Wizard** window:
    1. In the **Action** pane, ensure **Choose an existing report server database** is selected, and then click **Next**.
    2. In the **Database Server** pane, type the name of the database server (**TT-SQL01**) in the **Server Name** box, click **Test Connection** and confirm the test succeeded, and then click **Next**.
    3. In the **Database **pane, in the **Report Server Database** list, select the restored database (**ReportServer_SCOM**) and then click **Next**.
    4. In the **Credentials **pane, ensure **Authentication Type** is set to **Service Credentials** and then click **Next**.
    5. On the **Summary** page, verify the information is correct, and then click **Next**.
    6. Click **Finish** to close the wizard.
11. In the navigation pane, click **Web Portal URL**.
12. In the **Web Portal URL **pane:
    1. Confirm the following warning message appears:
    2. Click **Apply**.
13. In the navigation pane, click **Encryption Keys**.
14. In the **Encryption Keys **pane, click **Restore**.
15. In the **Restore Encryption Key** window:
    1. In the **File Location **box, specify the location of the backup file for the encryption key.
    2. In the **Password** box, type the password for the backup file.
    3. Click **OK**.

Report Server Web Service is not configured. Default values have been provided to you. To accept these defaults simply press the Apply button, else change them and then press Apply.

The Web Portal virtual directory name is not configured. To configure the directory, enter a name or use the default value that is provided, and then click Apply.

**[\\\\TT-FS01\\Backups\\Encryption Keys\\Reporting Services - SCOM.snk](\\TT-FS01\Backups\Encryption Keys\Reporting Services - SCOM.snk)**

##### Remove previous server from Reporting Services

DELETE FROM dbo.Keys\
WHERE MachineName = 'TT-SCOM03'

### Reference

**Fix up the report server**\
Pasted from <[http://msdn.microsoft.com/en-us/library/jj620932.aspx](http://msdn.microsoft.com/en-us/library/jj620932.aspx)>

---

**SQL Server Management Studio - TT-SQL01**

#### -- Remove SCOM installation account from sysadmin role in SQL Server

```SQL
USE [master]
GO
ALTER SERVER ROLE [sysadmin]
DROP MEMBER [TECHTOOLBOX\setup-systemcenter]
GO
```

---

```PowerShell
cls
```

#### # Remove SQL Server installation media

```PowerShell
Dismount-DiskImage -ImagePath $imagePath
```

```PowerShell
cls
```

### # Install IIS

```PowerShell
Install-WindowsFeature `
    NET-WCF-HTTP-Activation45, `
    Web-Static-Content, `
    Web-Default-Doc, `
    Web-Dir-Browsing, `
    Web-Http-Errors, `
    Web-Http-Logging, `
    Web-Request-Monitor, `
    Web-Filtering, `
    Web-Stat-Compression, `
    Web-Mgmt-Console, `
    Web-Metabase, `
    Web-Asp-Net, `
    Web-Windows-Auth `
    -Source '\\TT-FS01\Products\Microsoft\Windows Server 2016\Sources\SxS' `
    -Restart
```

> **Note**
>
> HTTP Activation is required but is not included in the list of prerequisites on TechNet.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/85/5AF94B5986A5DFD2414DAE2DC8D3BF3145BE7D85.png)

#### Reference

**System requirements for System Center Operations Manager**\
From <[https://docs.microsoft.com/en-us/system-center/scom/system-requirements?view=sc-om-2016](https://docs.microsoft.com/en-us/system-center/scom/system-requirements?view=sc-om-2016)>

```PowerShell
cls
```

### # Configure website for Operations Manager web console

#### # Create IIS website for Operations Manager web console

```PowerShell
$hostHeader = "systemcenter"
$siteName = "System Center Web Site"
$sitePath = "C:\inetpub\wwwroot\SystemCenter"

$appPool = New-WebAppPool -Name $siteName

New-Item -Type Directory -Path $sitePath | Out-Null

New-Website `
    -Name $siteName `
    -HostHeader $hostHeader `
    -PhysicalPath $sitePath `
    -ApplicationPool $siteName | Out-Null
```

#### # Add HTTPS binding to website

```PowerShell
$cert = Get-ChildItem -Path Cert:\LocalMachine\My |
    Where { $_.Subject -like "CN=`systemcenter*" }

New-WebBinding `
    -Name $siteName `
    -Protocol https `
    -Port 443 `
    -HostHeader systemcenter `
    -SslFlags 0

(Get-WebBinding `
    -Name $siteName `
    -Protocol https).AddSslCertificate($cert.Thumbprint, "my")
```

#### TODO: Configure name resolution for Operations Manager web console

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
Add-DNSServerResourceRecordCName `
    -ComputerName TT-DC10 `
    -ZoneName technologytoolbox.com `
    -Name systemcenter `
    -HostNameAlias TT-SCOM03A.corp.technologytoolbox.com
```

---

```PowerShell
cls
```

### # Install Microsoft System CLR Types for SQL Server 2014

```PowerShell
& "\\TT-FS01\Products\Microsoft\System Center 2016\Microsoft CLR Types for SQL Server 2014\SQLSysClrTypes.msi"
```

```PowerShell
cls
```

### # Install Microsoft Report Viewer 2015 Runtime

```PowerShell
& "\\TT-FS01\Products\Microsoft\System Center 2016\Microsoft Report Viewer 2015 Runtime\ReportViewer.msi"
```

```PowerShell
cls
```

## # Install Operations Manager

### Configure database server for SCOM 2016 installation

---

**TT-SQL01A**

#### # Create temporary firewall rules for SCOM 2016 installation

```PowerShell
New-NetFirewallRule `
    -Name "SCOM 2016 Installation - TCP" `
    -DisplayName "SCOM 2016 Installation - TCP" `
    -Group 'Technology Toolbox (Custom)' `
    -Protocol "TCP" `
    -LocalPort "135", "445", "49152-65535" `
    -Profile Domain `
    -Direction Inbound `
    -Action Allow

New-NetFirewallRule `
    -Name "SCOM 2016 Installation - UDP" `
    -DisplayName "SCOM 2016 Installation - UDP" `
    -Group 'Technology Toolbox (Custom)' `
    -Protocol "UDP" `
    -LocalPort "137" `
    -Profile Domain `
    -Direction Inbound `
    -Action Allow
```

---

##### Reference

**SCOM 2012 - Installing Operations Manager Database on server behind a firewall**\
Pasted from <[http://social.technet.microsoft.com/Forums/systemcenter/en-US/6c3dc8ff-4f66-4c73-9c9e-4ca948cde3ff/scom-2012-installing-operations-manager-database-on-server-behind-a-firewall?forum=operationsmanagerdeployment](http://social.technet.microsoft.com/Forums/systemcenter/en-US/6c3dc8ff-4f66-4c73-9c9e-4ca948cde3ff/scom-2012-installing-operations-manager-database-on-server-behind-a-firewall?forum=operationsmanagerdeployment)>

---

**TT-SQL01A**

```PowerShell
cls
```

#### # Temporarily add SCOM installation account to local Administrators group on SQL Server

```PowerShell
$localGroup = "Administrators"
$domain = "TECHTOOLBOX"
$domainUser = "setup-systemcenter"

([ADSI]"WinNT://./$localGroup,group").Add(
    "WinNT://$domain/$domainUser,user")
```

---

[08:19:16]:        Error:        :GetRemoteOSVersion(): Threw Exception.Type: System.UnauthorizedAccessException, Exception Error Code: 0x80070005, Exception.Message: Access is denied. (Exception from HRESULT: 0x80070005 (E_ACCESSDENIED))\
[08:19:16]:        Error:        :StackTrace:   at System.Runtime.InteropServices.Marshal.ThrowExceptionForHRInternal(Int32 errorCode, IntPtr errorInfo)\
   at System.Management.ManagementScope.InitializeGuts(Object o)\
   at System.Management.ManagementScope.Initialize()\
   at System.Management.ManagementObjectSearcher.Initialize()\
   at System.Management.ManagementObjectSearcher.Get()\
   at Microsoft.EnterpriseManagement.OperationsManager.Setup.Common.SetupValidationHelpers.GetRemoteOSVersion(String remoteComputer)

---

**SQL Server Management Studio - TT-SQL01A**

#### -- Temporarily add SCOM installation account to sysadmin role in SQL Server

```SQL
USE [master]
GO
ALTER SERVER ROLE [sysadmin]
ADD MEMBER [TECHTOOLBOX\setup-systemcenter]
GO
```

---

```PowerShell
cls
```

### # Extract SCOM setup files

```PowerShell
$imagePath = "\\TT-FS01\Products\Microsoft\System Center 2016" `
    + "\en_system_center_2016_operations_manager_x64_dvd_9216830.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$installer = $imageDriveLetter + ":\SC2016_SCOM_EN.exe"

& $installer
```

Destination location: **C:\\NotBackedUp\\Temp\\System Center 2016 Operations Manager**

```PowerShell
Dismount-DiskImage -ImagePath $imagePath

$installer = "C:\NotBackedUp\Temp\System Center 2016 Operations Manager\Setup.exe"

& $installer
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/73/01E21318903E12D73885F9A2BF35D2DDC483C073.png)

Select **Download the latest updates to the setup program** and then click **Install**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/82/0CDBEA77CD9496C194CD9E86C1CF1355F67C1D82.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7C/D9C16BB3304B86686DCDFA06AAD892DF12A77B7C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6D/78A2009EEAC4229FEF104752118BA5760471526D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9F/537D1F6557104135F99304BFBF14A48BF1C2B79F.png)

Click **Next**.

On the **Specify an installation option** step, select **Add a Management server to an existing management group**, and click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F3/5E57BBEB23924B734C13B44521E4D7838495D6F3.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7F/33CD91DF2185870D95DE8A547566530325C23D7F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/56/60AAD15A2669E7A0616FCE219AEEB56899C2AD56.png)

The installed version of SQL Server could not be verified or is not supported. Verify that the computer and the installed version of SQL Server meet the minimum requirements for installation, and that the firewall settings are correct. See the Supported Configurations document for further information.

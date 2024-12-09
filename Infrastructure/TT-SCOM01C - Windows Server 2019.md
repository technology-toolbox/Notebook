# TT-SCOM01C - Windows Server 2019

Wednesday, November 27, 2019\
2:17 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure infrastructure

---

**TT-ADMIN02** - Run as administrator

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "TT-SCOM01C"
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

### Install custom Windows Server 2019 image

- On the **Task Sequence** step, select **Windows Server 2019** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **TT-SCOM01C**.
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

**TT-ADMIN02** - Run as administrator

```PowerShell
cls
```

##### # Configure static IP address using VMM

```PowerShell
$vmName = "TT-SCOM01C"
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

**TT-ADMIN02** - Run as administrator

```PowerShell
cls
$vmName = "TT-SCOM01C"
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

#### # Add machine to security group for Windows Update configuration

```PowerShell
Add-ADGroupMember -Identity "Windows Update - Slot 22" -Members ($vmName + '$')
```

---

### Add virtual machine to Hyper-V protection group in DPM

## Prepare for SCOM installation

### Reference

**System requirements for System Center Operations Manager**\
From <[https://docs.microsoft.com/en-us/system-center/scom/system-requirements?view=sc-om-2019](https://docs.microsoft.com/en-us/system-center/scom/system-requirements?view=sc-om-2019)>

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

### # Install SSL certificate

#### # Install certificate for Reporting Services and Operations Manager web console

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
    -Restart
```

> **Note**
>
> HTTP Activation is required but is not included in the list of prerequisites on TechNet.

#### Reference

**System requirements for System Center Operations Manager**\
From <[https://docs.microsoft.com/en-us/system-center/scom/system-requirements?view=sc-om-2019](https://docs.microsoft.com/en-us/system-center/scom/system-requirements?view=sc-om-2019)>

### Configure website for Operations Manager web console

> **Note**
>
> Use **Default Web Site** bound to both port 80 and port 443 (instead of custom website with host header) due to issues with Web Console installation. Specifically, the setup adds entries to the registry with [https://localhost/...](https://localhost/...) (which assume HTTPS binding is \*:443).
>
> References:
>
> **BUG in the installation process of SCOM 1801 Web Console (WORKAROUND)**\
> From <[https://systemcenterom.uservoice.com/forums/293064-general-operations-manager-feedback/suggestions/33941455-bug-in-the-installation-process-of-scom-1801-web-c](https://systemcenterom.uservoice.com/forums/293064-general-operations-manager-feedback/suggestions/33941455-bug-in-the-installation-process-of-scom-1801-web-c)>
>
> **SCOM 1801 - Web Console Installation issue**\
> From <[https://social.technet.microsoft.com/Forums/en-US/aa088cb8-f3c0-4486-ac9a-26a78a7277fe/scom-1801-web-console-installation-issue?forum=operationsmanagerdeployment](https://social.technet.microsoft.com/Forums/en-US/aa088cb8-f3c0-4486-ac9a-26a78a7277fe/scom-1801-web-console-installation-issue?forum=operationsmanagerdeployment)>

```PowerShell
cls
```

#### # Add HTTPS binding to website

```PowerShell
$siteName = "Default Web Site"

$cert = Get-ChildItem -Path Cert:\LocalMachine\My |
    Where { $_.Subject -like "CN=`systemcenter.technologytoolbox.com,*" }

New-WebBinding `
    -Name $siteName `
    -Protocol https `
    -Port 443 `
    -SslFlags 0

(Get-WebBinding `
    -Name $siteName `
    -Protocol https).AddSslCertificate($cert.Thumbprint, "my")
```

#### Configure name resolution for Operations Manager web console

---

**TT-ADMIN02** - Run as administrator

```PowerShell
cls
```

##### # Remove existing CName record

```PowerShell
Remove-DnsServerResourceRecord `
    -ComputerName TT-DC10 `
    -ZoneName technologytoolbox.com `
    -Name systemcenter `
    -RRType CName `
    -Force
```

##### # Add new CName record

```PowerShell
Add-DNSServerResourceRecordCName `
    -ComputerName TT-DC10 `
    -ZoneName technologytoolbox.com `
    -Name systemcenter `
    -HostNameAlias TT-SCOM01C.corp.technologytoolbox.com
```

---

```PowerShell
cls
```

### # Install Microsoft System CLR Types for SQL Server 2014

```PowerShell
& "\\TT-FS01\Products\Microsoft\System Center 2019\Microsoft CLR Types for SQL Server 2014\SQLSysClrTypes.msi"
```

```PowerShell
cls
```

### # Install Microsoft Report Viewer 2015 Runtime

```PowerShell
& "\\TT-FS01\Products\Microsoft\System Center 2019\Microsoft Report Viewer 2015 Runtime\ReportViewer.msi"
```

---

**TT-ADMIN02** - Run as administrator

```PowerShell
cls
```

### # Enable setup account for System Center

```PowerShell
Enable-ADAccount -Identity setup-systemcenter
```

---

## Install Operations Manager

### Login as TECHTOOLBOX\\setup-systemcenter

### Configure database server for SCOM 2019 installation

---

**TT-SQL01C** - Run as administrator

```PowerShell
cls
```

#### # Create temporary firewall rules for SCOM installation

```PowerShell
New-NetFirewallRule `
    -Name "SCOM 2019 Installation - TCP" `
    -DisplayName "SCOM 2019 Installation - TCP" `
    -Group 'Technology Toolbox (Custom)' `
    -Protocol "TCP" `
    -LocalPort "135", "445", "49152-65535" `
    -Profile Domain `
    -Direction Inbound `
    -Action Allow

New-NetFirewallRule `
    -Name "SCOM 2019 Installation - UDP" `
    -DisplayName "SCOM 2019 Installation - UDP" `
    -Group 'Technology Toolbox (Custom)' `
    -Protocol "UDP" `
    -LocalPort "137" `
    -Profile Domain `
    -Direction Inbound `
    -Action Allow
```

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

---

**SQL Server Management Studio** - Database Engine - **TT-SQL01**

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
$imagePath = "\\TT-FS01\Products\Microsoft\System Center 2019" `
    + "\mu_system_center_operations_manager_2019_x64_dvd_b3488f5c.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$installer = $imageDriveLetter + ":\SCOM_2019.exe"

& $installer
```

Destination location: **C:\\NotBackedUp\\Temp\\System Center 2019 Operations Manager**

```PowerShell
Dismount-DiskImage -ImagePath $imagePath
```

### # Install SCOM features

```PowerShell
$installer = "C:\NotBackedUp\Temp\System Center 2019 Operations Manager\Setup.exe"

& $installer
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/90/9D0ACEA121DCC6B8392B2293966ACD8B70168690.png)

Select **Download the latest updates to the setup program** and then click **Install**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C3/69E51AF74AEFF1F18F2BDD99ECBC41937E8313C3.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2C/C26E900F8AC5746A7B593DBF1E443E382084F82C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/14/F717A65FECCFC0E233BE0ACC05C332CF607A2714.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DA/50980880FF09A8326AFD27D4401A3FBE9BD85EDA.png)

Click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A9/F4171C51626FF785F36E63BDB90B89B9144310A9.png)

On the **Specify an installation option** step, select **Add a Management server to an existing management group**, and click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BC/E62E4D05FE244C71525142E78D10A3C63F4E38BC.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8F/D70264AD5813CF07F1EB9408170AF3A84E3F968F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5D/4A0151F5621475ABC552E9D18BA9AB39B70B605D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/11/6CF9044E99C924947F02CD40A277819AB86FDA11.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9F/B3F0599D66B0E6EFA33987977DD41C04A260639F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/64/06F98E3B6C813787F2FA3FCD4A30738B7788D864.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B1/30C30287D53FC4D5E1C823AB168634F4213D68B1.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C6/0C0149237B10B4B1085C9D6A4C403214720A18C6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C6/16D8C77E85FC93A0DC4FEA4A0C75EA8CE48376C6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/99/F8D01F0B713EB4C2BC06C3944E3AADD8B4F9E699.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A4/2C5185042A006E12E9B7152FD78FAE9794E99BA4.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D9/D27F63E136DB3BC0D2998E2E9F535E2BA289D2D9.png)

## Complete post-installation tasks

### Configure database server after SCOM 2019 installation

---

**SQL Server Management Studio** - Database Engine - **TT-SQL01**

#### -- Remove SCOM installation account from sysadmin role in SQL Server

```SQL
USE [master]
GO
ALTER SERVER ROLE [sysadmin]
DROP MEMBER [TECHTOOLBOX\setup-systemcenter]
GO
```

---

---

**TT-SQL01C** - Run as administrator

```PowerShell
cls
```

#### # Remove SCOM installation account from local Administrators group on SQL Server

```PowerShell
$localGroup = "Administrators"
$domain = "TECHTOOLBOX"
$domainUser = "setup-systemcenter"

([ADSI]"WinNT://./$localGroup,group").Remove(
    "WinNT://$domain/$domainUser,user")
```

#### # Delete firewall rules for SCOM installation

```PowerShell
Remove-NetFirewallRule `
    -Name "SCOM 2019 Installation - TCP"

Remove-NetFirewallRule `
    -Name "SCOM 2019 Installation - UDP"
```

---

### Add custom SCOM error messages to secondary SQL instance

Download the SQL scripts for adding SCOM error messages:

**SQL scripts to fix 18054 events in SQL application log - SCOM 2016 and 2019**\
From <[https://gallery.technet.microsoft.com/SQL-to-fix-event-18054-4d6d9ec1](https://gallery.technet.microsoft.com/SQL-to-fix-event-18054-4d6d9ec1)>

Execute the following scripts using SQL Server Management Studio for the secondary SQL instance (**TT-SQL01D**):

- **OperationsManager SysMessages SCOM2016_SCOM2019.txt**
- **OperationsManagerDW SysMessages SCOM2016_SCOM2019.txt**

---

**TT-ADMIN02** - Run as domain administrator

```PowerShell
cls
```

### # Add Service Principal Names for SCOM to service account

```PowerShell
setspn -A MSOMSdkSvc/TT-SCOM01C.corp.technologytoolbox.com s-scom-das
setspn -A MSOMSdkSvc/TT-SCOM01C s-scom-das
setspn -A MSOMSdkSvc/TT-SCOM01D.corp.technologytoolbox.com s-scom-das
setspn -A MSOMSdkSvc/TT-SCOM01D s-scom-das
```

---

```PowerShell
cls
```

### # Add recommended registry settings for SCOM Management Servers

```PowerShell
reg add "HKLM\SYSTEM\CurrentControlSet\services\HealthService\Parameters" `
    /v "State Queue Items" /t REG_DWORD /d 20480 /f

reg add "HKLM\SYSTEM\CurrentControlSet\services\HealthService\Parameters" `
    /v "Persistence Checkpoint Depth Maximum" /t REG_DWORD /d 104857600 /f

reg add "HKLM\SOFTWARE\Microsoft\System Center\2010\Common\DAL" `
    /v "DALInitiateClearPool" /t REG_DWORD /d 1 /f

reg add "HKLM\SOFTWARE\Microsoft\System Center\2010\Common\DAL" `
    /v "DALInitiateClearPoolSeconds" /t REG_DWORD /d 60 /f

reg add "HKLM\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0" `
    /v "GroupCalcPollingIntervalMilliseconds" /t REG_DWORD /d 900000 /f

reg add "HKLM\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Data Warehouse" `
    /v "Command Timeout Seconds" /t REG_DWORD /d 1800 /f

reg add "HKLM\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Data Warehouse" `
    /v "Deployment Command Timeout Seconds" /t REG_DWORD /d 86400 /f
```

#### Reference

**Recommended registry tweaks for SCOM 2016 and 2019 management servers**\
From <[https://kevinholman.com/2017/03/08/recommended-registry-tweaks-for-scom-2016-management-servers/](https://kevinholman.com/2017/03/08/recommended-registry-tweaks-for-scom-2016-management-servers/)>

```PowerShell
cls
```

### # Copy SCOM setup files to file share

```PowerShell
$source = "C:\NotBackedUp\Temp\System Center 2019 Operations Manager"
$destination = "\\TT-FS01\Products\Microsoft\System Center 2019\SCOM"

robocopy $source $destination /E /NP
```

```PowerShell
cls
```

### # Remove temporary SCOM setup files

```PowerShell
Remove-Item `
    -Path "C:\NotBackedUp\Temp\System Center 2019 Operations Manager" `
    -Recurse
```

```PowerShell
cls
```

### # Configure certificate for Operations Manager

#### # Create certificate for Operations Manager

##### # Create request for Operations Manager certificate

```PowerShell
& "C:\NotBackedUp\Public\Toolbox\Operations Manager\Scripts\New-OperationsManagerCertificateRequest.ps1"
```

##### # Submit certificate request to Certification Authority

```PowerShell
$adcsUrl = [Uri] "https://cipher01.corp.technologytoolbox.com"

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-InternetSecurityZoneMapping.ps1 `
    -Zone LocalIntranet `
    -Patterns $adcsUrl.AbsoluteUri

Start-Process $adcsUrl.AbsoluteUri
```

> **Note**
>
> Copy the certificate request to the clipboard.

**To submit the certificate request to an enterprise CA:**

1. On the computer hosting the Operations Manager feature for which you are requesting a certificate, start Internet Explorer, and browse to Active Directory Certificate Services site ([https://cipher01.corp.technologytoolbox.com/](https://cipher01.corp.technologytoolbox.com/)).
2. On the **Welcome** page, click **Request a certificate**.
3. On the **Advanced Certificate Request** page, click **Submit a certificate request by using a base-64-encoded CMC or PKCS #10 file, or submit a renewal request by using a base-64-encoded PKCS #7 file.**
4. On the **Submit a Certificate Request or Renewal Request** page, in the **Saved Request** text box, paste the contents of the certificate request generated in the previous procedure.
5. In the **Certificate Template** section, select the Operations Manager certificate template (**Technology Toolbox Operations Manager**), and then click **Submit**. When prompted to allow the digital certificate operation to be performed, click **Yes**.
6. On the **Certificate Issued** page, click **Download certificate** and save the certificate.

```PowerShell
cls
```

##### # Import the certificate into the certificate store

```PowerShell
$certFile = "C:\Users\$env:USERNAME\Downloads\certnew.cer"

CertReq.exe -Accept $certFile

If ($? -eq $true)
{
    Remove-Item $certFile
}
```

#### # Import the certificate into Operations Manager using MOMCertImport

```PowerShell
$hostName = ([System.Net.Dns]::GetHostByName(($env:computerName))).HostName

$certImportToolPath = "\\TT-FS01\Products\Microsoft" `
    + "\System Center 2019\SCOM\SupportTools\AMD64\MOMCertImport.exe"

& $certImportToolPath /SubjectName $hostName
```

### Upgrade SCOM agents

```PowerShell
cls
```

### # Configure primary and failover management servers for all SCOM agents

```PowerShell
$primaryServer = Get-SCOMManagementServer -Name TT-SCOM01C.corp.technologytoolbox.com
$failoverServer = Get-SCOMManagementServer -Name TT-SCOM01D.corp.technologytoolbox.com

Get-SCOMAgent |
    foreach {
        $agent = $_
        Set-SCOMParentManagementServer -Agent $agent -FailoverServer $failoverServer
    }

Get-SCOMAgent |
    foreach {
        $agent = $_
        Set-SCOMParentManagementServer -Agent $agent -PrimaryServer $primaryServer
    }
```

```PowerShell
cls
```

### # Moves RMS Emulator role to new management server

```PowerShell
Get-SCOMManagementServer -Name TT-SCOM01C.corp.technologytoolbox.com |
    Set-SCOMRMSEmulator
```

```PowerShell
cls
```

### # Enter product key for System Center Operations Manager

#### # Set product key

```PowerShell
Set-SCOMLicense `
    -ManagementServer TT-SCOM01C `
    -Credential (Get-Credential TECHTOOLBOX\setup-systemcenter) `
    -ProductId {product key}
```

```PowerShell
cls
```

#### # Restart data access service

```PowerShell
Restart-Service OMSDK
```

#### # Confirm license SKU

```PowerShell
Get-SCOMManagementGroup | Format-Table SkuForLicense, TimeOfExpiration -AutoSize

SkuForLicense TimeOfExpiration
------------- ----------------
       Retail 12/31/9999 11:59:59 PM
```

```PowerShell
cls
```

## # Install SCOM reporting server

### # Install and configure SQL Server Reporting Services

#### # Install SQL Server 2017 Reporting Services

```PowerShell
$installer = "\\TT-FS01\Products\Microsoft\SQL Server 2017" `
    + "\SQLServerReportingServices.exe"

& $installer
```

---

**SQL Server Management Studio** - Database Engine - **TT-SQL01**

#### -- Temporarily add SCOM installation account to sysadmin role in SQL Server

```SQL
USE [master]
GO
ALTER SERVER ROLE [sysadmin]
ADD MEMBER [TECHTOOLBOX\setup-systemcenter]
GO
```

---

#### Configure SQL Server Reporting Services

1. Start **Report Server Configuration Manager**. If prompted by User Account Control to allow the program to make changes to the computer, click **Yes**.
2. In the **Report Server Configuration Connection** dialog box, ensure the name of the server and SQL Server instance are both correct, and then click **Connect**.
3. In the **Report Server Status** pane, click **Start** if the server is not already started.
4. In the navigation pane, click **Service Account**.
5. In the **Service Account** pane:
   1. Select the **Use another account** option.
   2. In the **Account (Domain\\user)** box, type **TECHTOOLBOX\\s-scom-data-reader**.
   3. In the **Password** box, types the password for the service account.
   4. Click **Apply**.
6. In the navigation pane, click **Web Service URL**.
7. In the **Web Service URL** pane:

   1. Confirm the following warning message appears:

      > Report Server Web Service is not configured. Default values have been provided to you. To accept these defaults simply press the Apply button, else change them and then press Apply.

   2. In the **Report Server Web Service Site identification** section, in the **HTTPS Certificate** dropdown list, select the SSL certificate installed previously for System Center (**systemcenter.technologytoolbox.com**).
   3. Click **Apply**.
   4. The following warning message appears:

      > The specified url was unexpectedly reserved. The previous reservation has been overridden.\
      > The specified url may have been reserved by another product.

   5. Click **OK**.

8. In the navigation pane, click **Database**.
9. In the **Report Server Database** pane, click **Change Database**.
10. In the **Report Server Database Configuration Wizard** window:
    1. In the **Action** pane, ensure **Choose an existing report server database** is selected, and then click **Next**.
    2. In the **Database Server** pane, type the name of the database server (**TT-SQL01**) in the **Server Name** box, click **Test Connection** and confirm the test succeeded, and then click **Next**.
    3. In the **Database** pane, in the **Report Server Database** list, select the reporting services database (**ReportServer_SCOM**) and then click **Next**.
    4. In the **Credentials** pane, ensure **Authentication Type** is set to **Service Credentials** and then click **Next**.
    5. On the **Summary** page, verify the information is correct, and then click **Next**.
    6. Click **Finish** to close the wizard.
11. In the navigation pane, click **Web Portal URL**.
12. In the **Web Portal URL** pane:

    1. Confirm the following warning message appears:

       > The Web Portal virtual directory name is not configured. To configure the directory, enter a name or use the default value that is provided, and then click Apply.

    2. Click **Apply**.
    3. The following warning message appears:

       > The specified url was unexpectedly reserved. The previous reservation has been overridden.\
       > The specified url may have been reserved by another product.

    4. Click **OK**.

13. In the navigation pane, click **Encryption Keys**.
14. In the **Encryption Keys** pane, click **Restore**.
15. In the **Restore Encryption Key** window:

    1. In the **File Location** box, specify the location of the backup file for the encryption key.

       **\\TT-FS01\Backups\Encryption Keys\Reporting Services - SCOM.snk**

    2. In the **Password** box, type the password for the backup file.
    3. Click **OK**.

#### Remove previous server from Reporting Services

---

**TT-SCOM03** - Run as administrator

##### Stop Reporting Services on previous server

1. Start **Report Server Configuration Manager**. If prompted by User Account Control to allow the program to make changes to the computer, click **Yes**.
2. In the **Report Server Configuration Connection** dialog box, ensure the name of the server and SQL Server instance are both correct, and then click **Connect**.
3. In the **Report Server Status** pane, click **Stop**.

---

---

**SQL Server Management Studio** - Database Engine - **TT-SQL01**

##### -- Remove previous server from Reporting Services database

```SQL
USE [ReportServer_SCOM]
GO
DELETE FROM dbo.Keys
WHERE MachineName = 'TT-SCOM03'
GO
```

---

```PowerShell
cls
```

##### # Restart Reporting Services on new server

```PowerShell
Restart-Service SQLServerReportingServices
```

```PowerShell
cls
```

### # Install SCOM feature - Reporting server

```PowerShell
$installer = "C:\NotBackedUp\Temp\System Center 2019 Operations Manager\Setup.exe"

& $installer
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/90/9D0ACEA121DCC6B8392B2293966ACD8B70168690.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AE/74713DE162C94F271190288BD9E697B7D15AF0AE.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/29/2D5906DEEA47CA879D7FE2A9DDCF1A2D77266A29.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DA/50980880FF09A8326AFD27D4401A3FBE9BD85EDA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DB/DF92B4E77BC58494F34FA4B6C4F8E0564C78A2DB.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9A/5237CFCC6DBEBE4910D04ABB3AAD5BDD15352F9A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7A/B12C8A3653FA03B873A6145933F3F680BCB0107A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/35/85E1E77B6EF1EF20AF90DEDA68292E9388385735.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7F/327F48D7331882639314E3270635D964BCE9587F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8B/5FD07C8A2B1BEB25037FD134ED8AAEC42FF00C8B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F7/4F4E0ED2F0A5C135814443B958F09DBDEFAC7DF7.png)

---

**SQL Server Management Studio** - Database Engine - **TT-SQL01**

#### -- Remove SCOM installation account from sysadmin role in SQL Server

```SQL
USE [master]
GO
ALTER SERVER ROLE [sysadmin]
DROP MEMBER [TECHTOOLBOX\setup-systemcenter]
GO
```

---

### Issue - Missing reports in SCOM

```Text
Log Name:      Operations Manager
Source:        Health Service Modules
Event ID:      31567
Task Category: Data Warehouse
Level:         Error
Keywords:      Classic
User:          N/A
Computer:      TT-SCOM03.corp.technologytoolbox.com
Description:
Failed to deploy reporting component to the SQL Server Reporting Services server. The operation will be retried.
Exception 'DeploymentException': Failed to deploy reports for management pack with version dependent id '1cdbe0c8-cde6-77a3-f024-4a1a2970b24c'. Uploading or saving files with .PerformanceBySystem extension is not allowed. Contact your administrator if you have any questions. ---> Microsoft.ReportingServices.Diagnostics.Utilities.ResourceFileFormatNotAllowedException: Uploading or saving files with .PerformanceBySystem extension is not allowed. Contact your administrator if you have any questions.
```

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

1. Start SQL Server Management Studio and connect to the report server instance that Operations Manager uses.
2. Right-click the report server name, select **Properties**, and then select **Advanced**.
3. Locate the **AllowedResourceExtensionsForUpload** setting and specify the following value to allow any extension:\
   \
   **\*,\*.\***

4. Click **OK**.
5. Restart SQL Server Reporting Services.

#### References

**Operations Manager 2019 and 1807 reports fail to deploy**\
From <[https://support.microsoft.com/en-us/help/4519161/operations-manager-2019-and-1807-reports-fail-to-deploy](https://support.microsoft.com/en-us/help/4519161/operations-manager-2019-and-1807-reports-fail-to-deploy)>

**SCOM 2019 - Blank Reports Tab**\
From <[https://social.technet.microsoft.com/Forums/en-US/96e6a495-74ac-4be0-932e-aeb3c4bb2311/scom-2019-blank-reports-tab?forum=operationsmanagermgmtpacks](https://social.technet.microsoft.com/Forums/en-US/96e6a495-74ac-4be0-932e-aeb3c4bb2311/scom-2019-blank-reports-tab?forum=operationsmanagermgmtpacks)>

**Known issues in SCOM 2019 GA**\
From <[https://kevinholman.com/2019/03/07/scom-2019-news/](https://kevinholman.com/2019/03/07/scom-2019-news/)>

---

**TT-ADMIN02** - Run as domain administrator

```PowerShell
cls
```

### # Disable setup account for System Center

```PowerShell
Disable-ADAccount -Identity setup-systemcenter
```

---

**TODO:**

# TT-SCOM01D - Windows Server 2019

Wednesday, November 27, 2019\
2:18 PM

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
$vmHost = "TT-HV05B"
$vmName = "TT-SCOM01D"
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
  - In the **Computer name** box, type **TT-SCOM01D**.
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
$vmName = "TT-SCOM01D"
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
| --- | --- | --- | --- | --- |
| 0 | C: | 35 GB | 4K | OSDisk |

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
$vmName = "TT-SCOM01D"
```

### # Set first boot device to hard drive

```PowerShell
$vmHost = "TT-HV05B"

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
Add-ADGroupMember -Identity "Windows Update - Slot 6" -Members ($vmName + '$')
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

#### TODO: Configure name resolution for Operations Manager web console

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

### Enable setup account for System Center

### Login as TECHTOOLBOX\\setup-systemcenter

## Install Operations Manager

### Configure database server for SCOM 2019 installation

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

### Configure database server after SCOM 2019 installation

## Configure SCOM 2019

### Add Service Principal Names for SCOM to service account

### Copy SCOM agent installers to file share

### Copy SCOM support tools to file share

```PowerShell
cls
```

## # Configure certificate for Operations Manager

### # Create certificate for Operations Manager

#### # Create request for Operations Manager certificate

```PowerShell
& "C:\NotBackedUp\Public\Toolbox\Operations Manager\Scripts\New-OperationsManagerCertificateRequest.ps1"
```

#### # Submit certificate request to Certification Authority

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

#### # Import the certificate into the certificate store

```PowerShell
$certFile = "C:\Users\$env:USERNAME\Downloads\certnew.cer"

CertReq.exe -Accept $certFile

If ($? -eq $true)
{
    Remove-Item $certFile
}
```

### # Import the certificate into Operations Manager using MOMCertImport

```PowerShell
$hostName = ([System.Net.Dns]::GetHostByName(($env:computerName))).HostName

$certImportToolPath = "\\TT-FS01\Products\Microsoft" `
    + "\System Center 2019\SCOM\SupportTools\AMD64\MOMCertImport.exe"

& $certImportToolPath /SubjectName $hostName
```

**TODO:**

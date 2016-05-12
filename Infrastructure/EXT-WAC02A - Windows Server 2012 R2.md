# EXT-WAC02A - Windows Server 2012 R2 Standard

Friday, April 15, 2016
2:00 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

### # Create virtual machine

```PowerShell
$vmHost = "STORM"
$vmName = "EXT-WAC02A"

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path E:\NotBackedUp\VMs `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 40GB `
    -MemoryStartupBytes 8GB `
    -SwitchName "Production"

Set-VM `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ProcessorCount 4

Set-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path \\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso

Start-VM -ComputerName $vmHost -Name $vmName
```

---

## Install custom Windows Server 2012 R2 image

- Start-up disk: [\\\\ICEMAN\\Products\\Microsoft\\MDT-Deploy-x86.iso](\\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso)
- On the **Task Sequence** step, select **Windows Server 2012 R2** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **EXT-WAC02A**.
  - Select **Join a workgroup**.
  - In the **Workgroup **box, type **WORKGROUP**.
  - Click **Next**.
- On the **Applications** step, ensure no items are selected and click **Next**.

```PowerShell
cls
```

## # Rename local Administrator account and set password

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

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

## # Remove disk from virtual CD/DVD drive

```PowerShell
$vmHost = "STORM"
$vmName = "EXT-WAC02A"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

---

## Login as EXT-WAC02A\\foo

```PowerShell
cls
```

## # Configure network settings

### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select Name, InterfaceDescription

Get-NetAdapter `
    -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "Production"
```

```PowerShell
cls
```

### # Configure "Production" network adapter

```PowerShell
$interfaceAlias = "Production"
```

#### # Configure static IPv4 address

```PowerShell
$ipAddress = "192.168.10.222"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24 `
    -DefaultGateway 192.168.10.1
```

#### # Configure IPv4 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 192.168.10.209,192.168.10.210
```

#### # Configure static IPv6 address

```PowerShell
$ipAddress = "2601:282:4201:e500::222"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 64
```

#### # Configure IPv6 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 2601:282:4201:e500::209,2601:282:4201:e500::210
```

```PowerShell
cls
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping ICEMAN -f -l 8900
```

```PowerShell
cls
```

## # Join domain

```PowerShell
Add-Computer -DomainName extranet.technologytoolbox.com -Restart
```

## Move computer to "SharePoint Servers" OU

---

**EXT-DC01**

```PowerShell
$computerName = "EXT-WAC02A"
$targetPath = ("OU=SharePoint Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=extranet,DC=technologytoolbox,DC=com")

Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath
```

---

## Login as EXT-WAC02A\\foo

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

## # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

## # Configure firewall rules for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
New-NetFirewallRule `
    -Name 'Remote Windows Update (DCOM-In)' `
    -DisplayName 'Remote Windows Update (DCOM-In)' `
    -Description 'Allows remote auditing and installation of Windows updates via POSHPAIG (http://poshpaig.codeplex.com/)' `
    -Group 'Remote Windows Update' `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 135 `
    -Profile Domain `
    -Action Allow

New-NetFirewallRule `
    -Name 'Remote Windows Update (Dynamic RPC)' `
    -DisplayName 'Remote Windows Update (Dynamic RPC)' `
    -Description 'Allows remote auditing and installation of Windows updates via POSHPAIG (http://poshpaig.codeplex.com/)' `
    -Group 'Remote Windows Update' `
    -Program '%windir%\system32\dllhost.exe' `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort RPC `
    -Profile Domain `
    -Action Allow

Enable-NetFirewallRule `
    -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)"

Enable-NetFirewallRule `
    -DisplayName "File and Printer Sharing (Echo Request - ICMPv6-In)"
```

## # Disable firewall rules for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
Disable-NetFirewallRule -Group 'Remote Windows Update'
```

```PowerShell
cls
```

## # Install and configure System Center Operations Manager

### # Create certificate for Operations Manager

#### # Create request for Operations Manager certificate

```PowerShell
& "C:\NotBackedUp\Public\Toolbox\Operations Manager\Scripts\New-OperationsManagerCertificateRequest.ps1"
```

#### # Submit certificate request to the Certification Authority

##### # Add Active Directory Certificate Services site to the "Trusted sites" zone and browse to the site

```PowerShell
$adcsUrl = [Uri] "https://cipher01.corp.technologytoolbox.com"

[string] $registryKey = ("HKCU:\Software\Microsoft\Windows" `
    + "\CurrentVersion\Internet Settings\ZoneMap\EscDomains" `
    + "\$($adcsUrl.Host)")

If ((Test-Path $registryKey) -eq $false)
{
    New-Item $registryKey | Out-Null
}

Set-ItemProperty -Path $registryKey -Name $adcsUrl.Scheme -Value 2

Start-Process $adcsUrl.AbsoluteUri
```

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
$certFile = "C:\Users\Administrator\Downloads\certnew.cer"

CertReq.exe -Accept $certFile

Remove-Item $certFile
```

```PowerShell
cls
```

### # Install SCOM agent

---

**FOOBAR8**

```PowerShell
cls
```

#### # Mount the Operations Manager installation media

```PowerShell
$imagePath = `
    '\\ICEMAN\Products\Microsoft\System Center 2012 R2' `
    + '\en_system_center_2012_r2_operations_manager_x86_and_x64_dvd_2920299.iso'

Set-VMDvdDrive -ComputerName STORM -VMName EXT-WAC02A -Path $imagePath
```

---

```PowerShell
$msiPath = 'X:\agent\AMD64\MOMAgent.msi'

msiexec.exe /i $msiPath `
    MANAGEMENT_GROUP=HQ `
    MANAGEMENT_SERVER_DNS=jubilee.corp.technologytoolbox.com `
    ACTIONS_USE_COMPUTER_ACCOUNT=1
```

```PowerShell
cls
```

### # Import the certificate into Operations Manager using MOMCertImport

```PowerShell
$hostName = ([System.Net.Dns]::GetHostByName(($env:computerName))).HostName

$certImportToolPath = 'X:\SupportTools\AMD64'

Push-Location "$certImportToolPath"

.\MOMCertImport.exe /SubjectName $hostName

Pop-Location
```

---

**FOOBAR8**

```PowerShell
cls
```

### # Remove the Operations Manager installation media

```PowerShell
Set-VMDvdDrive -ComputerName STORM -VMName EXT-WAC02A -Path $null
```

---

### # Approve manual agent install in Operations Manager

## # Enter a product key and activate Windows

```PowerShell
slmgr /ipk {product key}
```

**Note:** When notified that the product key was set successfully, click **OK**.

```Console
slmgr /ato
```

## Configure VM storage

| Disk | Drive Letter | Volume Size | VHD Type | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------- | -------------------- | ------------ |
| 0    | C:           | 40 GB       | Dynamic  | 4K                   | OSDisk       |
| 1    | D:           | 10 GB       | Dynamic  | 4K                   | Data01       |
| 2    | L:           | 10 GB       | Dynamic  | 4K                   | Log01        |

---

**FOOBAR8**

### # Create Data01, Log01, and Backup01 VHDs

```PowerShell
$vmHost = "STORM"
$vmName = "EXT-WAC02A"

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName" `
    + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 10GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ControllerType SCSI `
    -Path $vhdPath

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName" `
    + "_Log01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 10GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ControllerType SCSI `
    -Path $vhdPath
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
    New-Partition -DriveLetter D -UseMaximumSize |
    Format-Volume `
        -FileSystem NTFS `
        -NewFileSystemLabel "Data01" `
        -Confirm:$false
```

#### # Format Log01 drive

```PowerShell
Get-Disk 2 |
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -DriveLetter L -UseMaximumSize |
    Format-Volume `
        -FileSystem NTFS `
        -NewFileSystemLabel "Log01" `
        -Confirm:$false
```

## Install and configure Office Web Apps

### Reference

**Deploy Office Web Apps Server**\
From <[https://technet.microsoft.com/en-us/library/jj219455.aspx](https://technet.microsoft.com/en-us/library/jj219455.aspx)>

### Create DNS record for Office Web Apps

---

**FAB-DC01**

#### # Create A record - "wac.fabrikam.com"

```PowerShell
Add-DnsServerResourceRecordA `
    -Name "wac" `
    -IPv4Address "192.168.10.222" `
    -ZoneName "fabrikam.com"
```

---

```PowerShell
cls
```

### # Install prerequisite software for Office Web Apps Server

#### # Install .NET Framework 4.5.2

net use [\\\\ICEMAN\\Products](\\ICEMAN\Products) /USER:TECHTOOLBOX\\jjameson

& "[\\\\ICEMAN\\Products\\Microsoft\\.NET Framework 4.5\\.NET Framework 4.5.2\\NDP452-KB2901907-x86-x64-AllOS-ENU.exe](\\ICEMAN\Products\Microsoft\.NET Framework 4.5\.NET Framework 4.5.2\NDP452-KB2901907-x86-x64-AllOS-ENU.exe)"

> **Note**
>
> Restart the server to complete the installation of .NET Framework 4.5.2.

#### Login as EXT-WAC02A\\foo

#### # Install the required roles and services

```PowerShell
Add-WindowsFeature Web-Server, Web-Mgmt-Tools, Web-Mgmt-Console,Web-WebServer, `
    Web-Common-Http, Web-Default-Doc, Web-Static-Content, Web-Performance,`
    Web-Stat-Compression, Web-Dyn-Compression, Web-Security, Web-Filtering,`
    Web-Windows-Auth, Web-App-Dev, Web-Net-Ext45, Web-Asp-Net45, Web-ISAPI-Ext,`
    Web-ISAPI-Filter, Web-Includes, InkandHandwritingServices,`
    NET-Framework-Features, NET-Framework-Core, NET-HTTP-Activation,`
    NET-Non-HTTP-Activ, NET-WCF-HTTP-Activation45 -Restart
```

#### Login as EXT-WAC02A\\foo

### Install Office Web Apps Server and related updates

---

**FOOBAR8**

```PowerShell
cls
```

#### # Mount the Office Web Apps installation media

```PowerShell
$imagePath = `
    "\\ICEMAN\Products\Microsoft\Office Web Apps 2013" `
        + "\en_office_web_apps_server_2013_with_sp1_x64_dvd_3833121.iso"

Set-VMDvdDrive -ComputerName STORM -VMName EXT-WAC02A -Path $imagePath
```

---

```PowerShell
& X:\setup.exe
```

```PowerShell
cls
```

### # Deploy the Office Web Apps Server farm

#### # Install SSL certificate

##### # Create request for Web Server certificate

```PowerShell
& "C:\NotBackedUp\Public\Toolbox\PowerShell\New-CertificateRequest.ps1" `
    -Subject "CN=wac.fabrikam.com,OU=IT,O=Fabrikam Technologies,L=Denver,S=CO,C=US"
```

##### # Submit certificate request to the Certification Authority

```PowerShell
Start-Process "https://cipher01.corp.technologytoolbox.com"
```

**To submit the certificate request to an enterprise CA:**

1. Start Internet Explorer, and browse to Active Directory Certificate Services site ([https://cipher01.corp.technologytoolbox.com/](https://cipher01.corp.technologytoolbox.com/)).
2. On the **Welcome** page, click **Request a certificate**.
3. On the **Advanced Certificate Request** page, click **Submit a certificate request by using a base-64-encoded CMC or PKCS #10 file, or submit a renewal request by using a base-64-encoded PKCS #7 file.**
4. On the **Submit a Certificate Request or Renewal Request** page, in the **Saved Request** text box, paste the contents of the certificate request generated in the previous procedure.
5. In the **Certificate Template** section, select the appropriate certificate template (**Technology Toolbox Web Server - Exportable**), and then click **Submit**. When prompted to allow the digital certificate operation to be performed, click **Yes**.
6. On the **Certificate Issued** page, click **Download certificate** and save the certificate.

```PowerShell
cls
```

##### # Import the certificate into the certificate store

```PowerShell
$certFile = "C:\Users\Administrator\Downloads\certnew.cer"

CertReq.exe -Accept $certFile

Remove-Item $certFile
```

```PowerShell
cls
```

##### # Set friendly name for the imported certificate

```PowerShell
$cert = Get-ChildItem cert:\LocalMachine\My |
    Where-Object { $_.Subject -like "CN=wac.fabrikam.com,*" }

$cert.FriendlyName = "OfficeWebApps Certificate"
```

```PowerShell
cls
```

#### # Create the Office Web Apps Server farm

```PowerShell
New-OfficeWebAppsFarm `
    -CacheLocation "D:\Microsoft\OfficeWebApps\Working\d" `
    -CacheSizeInGB 5 `
    -CertificateName "OfficeWebApps Certificate" `
    -EditingEnabled `
    -ExternalUrl "https://wac.fabrikam.com" `
    -LogLocation "L:\Microsoft\OfficeWebApps\Data\Logs\ULS" `
    -RenderingLocalCacheLocation "D:\Microsoft\OfficeWebApps\Working\waccache"
```

#### Issue

![(screenshot)](https://assets.technologytoolbox.com/screenshots/61/9EDCF85C481207094C603DB0641238783C2DC161.png)

#### Solution

Login as **EXTRANET\\jjameson-admin** and create the Office Web Apps farm

![(screenshot)](https://assets.technologytoolbox.com/screenshots/ED/4F0BA0F2647568F8E881AC8EE712D89C0B404EED.png)

#### # Verify that the Office Web Apps Server farm was created successfully

```PowerShell
Start-Process "https://wac.fabrikam.com/hosting/discovery"
```

```PowerShell
cls
```

#### # Prevent unwanted hosts from connecting to Office Web Apps Server

```PowerShell
New-OfficeWebAppsHost -Domain my-dev
New-OfficeWebAppsHost -Domain my-test
New-OfficeWebAppsHost -Domain my

New-OfficeWebAppsHost -Domain team-dev
New-OfficeWebAppsHost -Domain team-test
New-OfficeWebAppsHost -Domain team

New-OfficeWebAppsHost -Domain ttweb-dev
New-OfficeWebAppsHost -Domain ttweb-test
New-OfficeWebAppsHost -Domain ttweb

New-OfficeWebAppsHost -Domain securitasinc.com
```

#### # Add hosts entries for name resolution

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    -IPAddress 192.168.10.55 `
    -Hostnames POLARIS-DEV, my-dev, team-dev, ttweb-dev

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    -IPAddress 192.168.10.6 `
    -Hostnames POLARIS-TEST, my-test, team-test, ttweb-test

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    -IPAddress 192.168.10.37 `
    -Hostnames POLARIS, my, team, ttweb

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    -IPAddress 192.168.10.217 `
    -Hostnames EXT-FOOBAR3, client-local.securitasinc.com
```

#### Configure the host

---

**EXT-FOOBAR3 - SharePoint 2013 Management Shell**

##### # Create the binding between SharePoint 2013 and Office Web Apps Server

```PowerShell
New-SPWOPIBinding -ServerName wac.fabrikam.com
```

```PowerShell
cls
```

##### # View the WOPI zone of SharePoint 2013

```PowerShell
Get-SPWOPIZone
```

##### # Change the WOPI zone if necessary

```PowerShell
Set-SPWOPIZone -zone "external-https"
```

---

## Reduce memory (to free up memory for other VMs)

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

### # Set memory to 4 GB

```PowerShell
$vmHost = "STORM"
$vmName = "EXT-WAC02A"

Stop-VM -ComputerName $vmHost -Name $vmName

Set-VM -ComputerName $vmHost -Name $vmName -MemoryStartupBytes 4GB

Start-VM -ComputerName $vmHost -Name $vmName
```

---

**TODO:**

﻿# EXT-DC08 - Windows Server 2016 Domain Controller

Tuesday, March 13, 2018
5:53 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "EXT-DC08"
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
    -MemoryMinimumBytes 1GB `
    -MemoryMaximumBytes 2GB `
    -ProcessorCount 2

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Install custom Windows Server 2016 image

- On the **Task Sequence** step, select **Windows Server 2016** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **EXT-DC08**.
  - Select **Join a workgroup**.
  - In the **Workgroup **box, type **WORKGROUP**.
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

### Login as local administrator

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

### Configure networking

---

**TT-VMM01A**

```PowerShell
cls
```

#### # Change VM network

```PowerShell
$vmName = "EXT-DC08"

$vmNetwork = Get-SCVMNetwork -Name "Extranet-20 VM Network"

$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName |
    ? { $_.SlotId -eq 0 }

Stop-SCVirtualMachine $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork

Start-SCVirtualMachine $vmName
```

---

```PowerShell
$interfaceAlias = "Extranet-20"
```

#### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

#### # Configure static IPv4 address

```PowerShell
New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress 10.1.20.103 `
    -PrefixLength 24 `
    -DefaultGateway 10.1.20.1
```

#### # Configure IPv4 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 10.1.20.104
```

### # Join server to domain

```PowerShell
Add-Computer -DomainName extranet.technologytoolbox.com -Restart
```

---

**EXT-DC05 - Run as EXTRANET\\jjameson-admin**

```PowerShell
cls
```

### # Configure Windows Update

#### # Add machine to security group for Windows Update schedule

```PowerShell
Add-ADGroupMember -Identity "Windows Update - Slot 1" -Members "EXT-DC08$"
```

---

### Login as domain administrator account

### Configure storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 32 GB       | 4K                   | OSDisk       |
| 1    | D:           | 5 GB        | 4K                   | Data01       |

#### Configure separate VHD for Active Directory data

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

##### # Add disk for Active Directory data

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "EXT-DC08"

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 5GB
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

## # Configure domain controller

### # Install Active Directory Domain Services

```PowerShell
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools -Restart
```

> **Note**
>
> A restart was not needed after installing Active Directory Domain Services.

```PowerShell
cls
```

### # Promote server to domain controller

```PowerShell
Import-Module ADDSDeployment

Install-ADDSDomainController `
    -DatabasePath "D:\Windows\NTDS" `
    -DomainName "extranet.technologytoolbox.com" `
    -LogPath "D:\Windows\NTDS" `
    -SysvolPath "D:\Windows\SYSVOL" `
    -Force:$true
```

> **Note**
>
> When prompted, specify the password for the administrator account when the computer is started in Safe Mode or a variant of Safe Mode, such as Directory Services Restore Mode.

## Configure NTP

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Disable Hyper-V time synchronization service

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "EXT-DC08"

Disable-VMIntegrationService `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Name "Time Synchronization"
```

---

### # Configure NTP settings

```PowerShell
w32tm /config /syncfromflags:DOMHIER /update

Restart-service w32time
```

#### # Change the server type to NTP

```PowerShell
Set-ItemProperty `
    -Path HKLM:SYSTEM\CurrentControlSet\Services\W32Time\Parameters `
    -Name Type `
    -Value NTP
```

#### # Set AnnounceFlags to 5

```PowerShell
Set-ItemProperty `
    -Path HKLM:SYSTEM\CurrentControlSet\Services\W32Time\Config `
    -Name AnnounceFlags `
    -Value 5
```

#### # Enable NTPServer

```PowerShell
Set-ItemProperty `
    -Path HKLM:SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpServer `
    -Name Enabled `
    -Value 1
```

#### # Specify the time sources

```PowerShell
Set-ItemProperty `
    -Path HKLM:SYSTEM\CurrentControlSet\Services\W32Time\Parameters `
    -Name NtpServer `
    -Value ("time.windows.com,0x1 time-nw.nist.gov,0x1 time-b.nist.gov,0x1" `
        + " time.nist.gov,0x1 time-a.nist.gov,0x1")
```

#### # Set poll interval to every 15 minutes (900 seconds)

```PowerShell
Set-ItemProperty `
    -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpClient `
    -Name SpecialPollInterval `
    -Value 900
```

#### # Configure time correction settings

```PowerShell
Set-ItemProperty `
    -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config `
    -Name MaxPosPhaseCorrection `
    -Value 3600

Set-ItemProperty `
    -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config `
    -Name MaxNegPhaseCorrection `
    -Value 3600

Restart-Service w32time

w32tm /resync /rediscover
```

```PowerShell
cls
```

#### # Configure DNS record for NTP (ntp.extranet.technologytoolbox.com)

```PowerShell
Add-DnsServerResourceRecordCName `
    -ZoneName "extranet.technologytoolbox.com" `
    -Name "ntp" `
    -HostNameAlias "EXT-DC08.extranet.technologytoolbox.com"
```

```PowerShell
cls
```

## # Configure backups

### # Add Windows Server Backup feature (DPM dependency for System State backups)

```PowerShell
Add-WindowsFeature Windows-Server-Backup
```

---

**FOOBAR11 - DPM Management Shell**

```PowerShell
cls
```

### # Copy DPM agent installation files

```PowerShell
net use \\EXT-DC08.extranet.technologytoolbox.com\C$ /USER:EXTRANET\jjameson-admin

$source = "\\TT-FS01\Products\Microsoft\System Center 2016\DPM\Agents"
$destination = "\\EXT-DC08.extranet.technologytoolbox.com\C`$\NotBackedUp\Temp" `
    + "\DPM\Agents"

$filter = "DPMAgentInstaller_x64.exe"

robocopy $source $destination $filter /E
```

---

```PowerShell
cls
```

### # Install DPM agent

```PowerShell
$installer = "C:\NotBackedUp\Temp\DPM\Agents\DPMAgentInstaller_x64.exe"

& $installer
```

Review the licensing agreement. If you accept the Microsoft Software License Terms, select **I accept the license terms and conditions**, and then click **OK**.

Confirm the agent installation completed successfully and the following firewall exceptions have been added:

- Exception for DPMRA.exe in all profiles
- Exception for Windows Management Instrumentation service
- Exception for RemoteAdmin service
- Exception for DCOM communication on port 135 (TCP and UDP) in all profiles

```PowerShell
cls
```

#### # Remove Operations Manager installation files

```PowerShell
Remove-Item C:\NotBackedUp\Temp\DPM -Recurse
```

#### Reference

**Installing Protection Agents Manually**\
Pasted from <[http://technet.microsoft.com/en-us/library/hh757789.aspx](http://technet.microsoft.com/en-us/library/hh757789.aspx)>

---

**FOOBAR11 - DPM Management Shell**

```PowerShell
cls
```

### # Attach DPM agent

```PowerShell
$productionServer = 'EXT-DC08.extranet.technologytoolbox.com'

.\Attach-ProductionServer.ps1 `
    -DPMServerName TT-DPM02 `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `
    -UserName jjameson-admin
```

---

```PowerShell
cls
```

## # Configure monitoring

### # Create certificate for Operations Manager

#### # Create request for Operations Manager certificate

```PowerShell
& "C:\NotBackedUp\Public\Toolbox\Operations Manager\Scripts\New-OperationsManagerCertificateRequest.ps1"
```

#### # Submit certificate request to the Certification Authority

##### # Add Active Directory Certificate Services site to the "Trusted sites" zone and browse to the site

```PowerShell
[Uri] $adcsUrl = [Uri] "https://cipher01.corp.technologytoolbox.com"

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-InternetSecurityZoneMapping.ps1 `
    -Zone LocalIntranet `
    -Patterns $adcsUrl.AbsoluteUri

Start-Process $adcsUrl.AbsoluteUri
```

##### # Submit the certificate request to an enterprise CA

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
$certFile = "C:\Users\jjameson-admin\Downloads\certnew.cer"

CertReq.exe -Accept $certFile
```

```PowerShell
cls
```

#### # Delete the certificate file

```PowerShell
Remove-Item $certFile
```

---

**FOOBAR11 - DPM Management Shell**

```PowerShell
cls
```

### # Copy SCOM agent installation files

```PowerShell
net use \\EXT-DC08.extranet.technologytoolbox.com\C$ /USER:EXTRANET\jjameson-admin
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$source = "\\TT-FS01\Products\Microsoft\System Center 2016\SCOM\Agent\AMD64"
$destination = "\\EXT-DC08.extranet.technologytoolbox.com\C`$\NotBackedUp\Temp" `
    + "\SCOM\Agent"

robocopy $source $destination /E

$source = "\\TT-FS01\Products\Microsoft\System Center 2016\SCOM\SupportTools\AMD64"
$destination = "\\EXT-DC08.extranet.technologytoolbox.com\C`$\NotBackedUp\Temp" `
    + "\SCOM\SupportTools"

robocopy $source $destination /E
```

---

```PowerShell
cls
```

### # Install SCOM agent

```PowerShell
$msiPath = "C:\NotBackedUp\Temp\SCOM\agent\MOMAgent.msi"

msiexec.exe /i $msiPath `
    MANAGEMENT_GROUP=HQ `
    MANAGEMENT_SERVER_DNS=tt-scom01.corp.technologytoolbox.com `
    ACTIONS_USE_COMPUTER_ACCOUNT=1
```

> **Important**
>
> Wait for the installation to complete.

```PowerShell
cls
```

### # Import the certificate into Operations Manager using MOMCertImport

```PowerShell
$hostName = ([System.Net.Dns]::GetHostByName(($env:computerName))).HostName

$certImportToolPath = "C:\NotBackedUp\Temp\SCOM\SupportTools"

Push-Location "$certImportToolPath"

.\MOMCertImport.exe /SubjectName $hostName

Pop-Location
```

```PowerShell
cls
```

#### # Remove Operations Manager installation files

```PowerShell
Remove-Item C:\NotBackedUp\Temp\SCOM -Recurse
```

### Approve manual agent install in Operations Manager

### Configure SCOM agent for domain controller

#### Enable agent proxy

In the **Agent Properties** window, on the **Security** tab, select **Allow this agent to act as a proxy and discover managed objects on other computers** and then click **OK**.

```PowerShell
cls
```

#### # Enable SCOM agent to run as LocalSystem on domain controller

```PowerShell
Push-Location "C:\Program Files\Microsoft Monitoring Agent\Agent"

.\HSLockdown.exe HQ /R "NT AUTHORITY\SYSTEM"

Pop-Location

Restart-Service HealthService
```

##### Reference

**Deploying SCOM 2016 Agents to Domain controllers - some assembly required**\
From <[https://blogs.technet.microsoft.com/kevinholman/2016/11/04/deploying-scom-2016-agents-to-domain-controllers-some-assembly-required/](https://blogs.technet.microsoft.com/kevinholman/2016/11/04/deploying-scom-2016-agents-to-domain-controllers-some-assembly-required/)>

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
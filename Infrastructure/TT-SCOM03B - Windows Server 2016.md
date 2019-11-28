# TT-SCOM03B - Windows Server 2016

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
$vmHost = "TT-HV05B"
$vmName = "TT-SCOM03B"
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
  - In the **Computer name** box, type **TT-SCOM03B**.
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
$vmName = "TT-SCOM03B"
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
$vmName = "TT-SCOM03B"
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

##### # Add machine to security group for Windows Update configuration

```PowerShell
Add-ADGroupMember -Identity "Windows Update - Slot 6" -Members ($vmName + '$')
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

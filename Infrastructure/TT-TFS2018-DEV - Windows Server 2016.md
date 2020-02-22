# TT-TFS2018-DEV - Windows Server 2016

Saturday, February 3, 2018
8:27 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

### Install Windows Server 2016

---

**FOOBAR11** - Run as administrator

```PowerShell
cls
```

#### # Create virtual machine

```PowerShell
$vmHost = "WOLVERINE"
$vmName = "TT-TFS2018-DEV"
$vmPath = "D:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 4GB `
    -SwitchName "Management"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 2 `
    -StaticMemory

Start-VM -ComputerName $vmHost -Name $vmName
```

---

#### Install custom Windows Server 2016 image

- On the **Task Sequence** step, select **Windows Server 2016** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **TT-TFS2018-DEV**.
  - Click **Next**.
- On the **Applications** step, do not select any applications, and click **Next**.

#### # Rename local Administrator account and set password

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

**FOOBAR11** - Run as administrator

```PowerShell
cls
```

#### # Move computer to different OU

```PowerShell
$vmName = "TT-TFS2018-DEV"

$targetPath = "OU=Team Foundation Servers,OU=Servers" `
    + ",OU=Resources,OU=Development" `
    + ",DC=corp,DC=technologytoolbox,DC=com"

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

---

#### Login as .\\foo

#### # Copy Toolbox content

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

#### # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

#### # Configure networking

```PowerShell
$interfaceAlias = "Management"
```

##### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

##### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Start-Sleep -Seconds 5

ping TT-FS01 -f -l 8900
```

---

**FOOBAR11** - Run as administrator

```PowerShell
cls
```

#### # Set first boot device to hard drive

```PowerShell
$vmHost = "WOLVERINE"
$vmName = "TT-TFS2018-DEV"

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

---

```PowerShell
cls
```

#### # Add TFS setup account to local Administrators group

```PowerShell
$domain = "TECHTOOLBOX"
$username = "setup-tfs"

([ADSI]"WinNT://./Administrators,group").Add(
    "WinNT://$domain/$username,user")
```

### Configure VM processors, memory, and storage

---

**FOOBAR11** - Run as administrator

```PowerShell
cls
```

#### # Configure storage for the TFS App Tier VM

```PowerShell
$vmHost = "WOLVERINE"
$vmName = "TT-TFS2018-DEV"

$vmPath = "D:\NotBackedUp\VMs\$vmName"

$vhdPath = $vmPath + "\Virtual Hard Disks\$vmName" + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 60GB
Add-VMHardDiskDrive `
  -ComputerName $vmHost `
  -VMName $vmName `
  -Path $vhdPath `
  -ControllerType SCSI
```

---

##### # Format Data01 drive

```PowerShell
Get-Disk 1 |
  Initialize-Disk -PartitionStyle MBR -PassThru |
  New-Partition -DriveLetter D -UseMaximumSize |
  Format-Volume `
    -FileSystem NTFS `
    -NewFileSystemLabel "Data01" `
    -Confirm:$false
```

## Install TFS 2018 App Tier, upgrade TFS databases, and configure TFS resources

---

**FOOBAR11** - Run as domain administrator

```PowerShell
cls
```

### # Configure name resolution for TFS 2018 URLs

```PowerShell
Add-DnsServerResourceRecordCName `
    -ZoneName "technologytoolbox.com" `
    -Name "tfs-dev" `
    -HostNameAlias "TT-TFS2018-DEV.corp.technologytoolbox.com" `
    -ComputerName TT-DC04
```

---

#### Login as TECHTOOLBOX\\setup-tfs

### # Install SSL certificate

#### # Create request for Web Server certificate

```PowerShell
$hostname = "tfs-dev.technologytoolbox.com"

& "C:\NotBackedUp\Public\Toolbox\PowerShell\New-CertificateRequest.ps1" `
    -Subject ("CN=$hostname,OU=Development" `
        + ",O=Technology Toolbox,L=Parker,S=CO,C=US") `
    -SANs $hostname
```

#### # Submit certificate request to Certification Authority

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

#### # Import certificate into certificate store

```PowerShell
$certFile = "C:\Users\setup-tfs\Downloads\certnew.cer"

CertReq.exe -Accept $certFile

Remove-Item $certFile
```

### Temporarily grant administrator permissions in SQL Server to TFS setup account

---

**SQL Server Management Studio** - Database Engine - **USWVTFS007**

#### -- Add TFS setup account to sysadmin role in Database Engine instance

```SQL
CREATE LOGIN [TECHTOOLBOX\setup-tfs]
FROM WINDOWS
WITH DEFAULT_DATABASE=master
GO

ALTER SERVER ROLE sysadmin
ADD MEMBER [TECHTOOLBOX\setup-tfs]
```

---

#### Add TFS setup account to server administrator role in Analysis Services instance

```PowerShell
cls
```

### # Install and configure SQL Server Reporting Services

#### # Install SQL Server Reporting Services

```PowerShell
& '\\TT-FS01\Products\Microsoft\SQL Server 2017\SQLServerReportingServices.exe'
```

#### Configure SQL Server Reporting Services (using restored database)

#### Configure TFS administrators in SQL Server Reporting Services

```PowerShell
cls
```

### # Install TFS 2018 on new App Tier VM

```PowerShell
$imagePath = ("\\TT-FS01\Products\Microsoft\Team Foundation Server 2018" `
    + "\mu_team_foundation_server_2018_x64_dvd_100268668.iso")

$imageDriveLetter = (Mount-DiskImage -ImagePath $ImagePath -PassThru |
    Get-Volume).DriveLetter
```

& ("\$imageDriveLetter" + ":\\Tfs2018.exe")

> **Important**
>
> Wait for the installation to complete and restart the server.

```PowerShell
cls
```

#### # Configure TFS Builds share

##### # Create and share the Builds folder

```PowerShell
New-Item -Path D:\Shares\Builds -ItemType Directory

New-SmbShare `
  -Name Builds `
  -Path D:\Shares\Builds `
  -CachingMode None `
  -FullAccess "NT AUTHORITY\Authenticated Users"
```

##### # Remove "BUILTIN\\Users" permissions

```PowerShell
icacls D:\Shares\Builds /inheritance:d
icacls D:\Shares\Builds /remove:g "BUILTIN\Users"
```

##### # Grant "TFS Build" service account read/write access to the Builds folder

```PowerShell
icacls D:\Shares\Builds /grant '"TECHTOOLBOX\s-tfs-build":(OI)(CI)(M)'
```

##### # Grant "Developers" group read-only access to the Builds folder

```PowerShell
icacls D:\Shares\Builds /grant '"TECHTOOLBOX\All Developers":(OI)(CI)(RX)'
```

## Install Team Foundation Server 2018 Update 1

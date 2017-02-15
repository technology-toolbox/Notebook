# EXT-WAP02A - Windows Server 2016

Wednesday, February 15, 2017
4:49 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

---

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

##### # Create virtual machine

```PowerShell
$vmHost = "TT-HV02A"
$vmName = "EXT-WAP02A"
$vmPath = "E:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 2GB `
    -SwitchName "Embedded Team Switch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -DynamicMemory `
    -MemoryMinimumBytes 2GB `
    -MemoryMaximumBytes 4GB `
    -ProcessorCount 2

Set-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path C:\NotBackedUp\Products\Microsoft\MDT-Deploy-x64.iso

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Set password for the local Administrator account

```PowerShell
cls
```

### # Rename local Administrator account

```PowerShell
$adminUser = [ADSI] 'WinNT://./Administrator,User'

$adminUser.Rename('foo')

logoff
```

```PowerShell
cls
```

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

#### # Configure static IPv4 address

```PowerShell
$ipAddress = "192.168.10.244"

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

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping TT-FS01.corp.technologytoolbox.com -f -l 8900
```

### Rename server and join domain

#### Login as local administrator account

```PowerShell
cls
```

### # Rename server

```PowerShell
Rename-Computer -NewName EXT-WAP02A -Restart
```

> **Note**
>
> Wait for the VM to restart.

#### Login as local administrator account

```PowerShell
cls
```

### # Join server to domain

```PowerShell
$cred = Get-Credential EXTRANET\jjameson-admin

Add-Computer -DomainName extranet.technologytoolbox.com -Credential $cred -Restart
```

---

**EXT-DC04 - Run as EXTRANET\\jjameson-admin**

```PowerShell
cls
```

### # Move computer to different OU

```PowerShell
$vmName = "EXT-WAP02A"

$targetPath = ("OU=Servers,OU=Resources,OU=IT" `
    + ",DC=extranet,DC=technologytoolbox,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

---

```PowerShell
cls
```

### # Copy Toolbox content

```PowerShell
$source = "\\TT-FS01\Public\Toolbox"
$destination = "C:\NotBackedUp\Public\Toolbox"

net use $source /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```Console
robocopy $source $destination  /E /XD "Microsoft SDKs"
```

### # Set MaxPatchCacheSize to 0 (recommended)

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

```PowerShell
cls
```

## # Configure storage

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

## # AD FS prerequisites

### # Import certificate for secure communication with AD FS

```PowerShell
net use \\TT-FS01\Users$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$certFilePath = "\\TT-FS01\Users$\jjameson\My Documents\Technology Toolbox LLC" `
    + "\Certificates\fs.technologytoolbox.com.pfx"

$certPassword = `
    C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1

Import-PfxCertificate `
    -FilePath $certFilePath `
    -CertStoreLocation Cert:\LocalMachine\My `
    -Password $certPassword
```

```PowerShell
cls
```

#### # Add Remote Access - Web Application Proxy server role

```PowerShell
Install-WindowsFeature Web-Application-Proxy -IncludeManagementTools
```

```PowerShell
cls
```

#### # Configure Web Application Proxy

```PowerShell
$cert = Get-ChildItem -Path Cert:\LocalMachine\My |
    Where { $_.Subject -like "CN=fs.technologytoolbox.com,*" }

$federationServiceTrustCred = Get-Credential EXTRANET\jjameson-admin
```

> **Note**
>
> When prompted, type the username and password for an account with administrator privileges on the servers with the AD FS role installed.

```PowerShell
Install-WebApplicationProxy `
    -CertificateThumbprint $cert.Thumbprint `
    -FederationServiceTrustCredential $federationServiceTrustCred `
    -FederationServiceName fs.technologytoolbox.com


WARNING: A machine restart is required to complete ADFS service configuration. For more information, see:
http://go.microsoft.com/fwlink/?LinkId=798725

Message                                   Context              Status
-------                                   -------              ------
The configuration completed successfully. DeploymentSucceeded Success


Restart-Computer
```

# EXT-WAP01A

Tuesday, January 24, 2017
5:49 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV02A"
$vmName = "EXT-WAP01A"
$vmPath = "E:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"
$sysPrepedImage = "\\TT-FS01\VM-Library\VHDs\WS2016-Std.vhdx"

$vhdUncPath = $vhdPath.Replace("E:", "\\TT-HV02A\E$")

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 2GB `
    -SwitchName "Tenant vSwitch"

Copy-Item $sysPrepedImage $vhdUncPath

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 2 `
    -DynamicMemory `
    -MemoryMaximumBytes 4GB

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
$interfaceAlias = "Datacenter"
```

#### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

#### # Configure static IPv4 address

```PowerShell
$ipAddress = "192.168.10.227"

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

#### # Configure IPv6 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 2603:300b:802:8900::209, 2603:300b:802:8900::210
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping iceman.corp.technologytoolbox.com -f -l 8900
```

### Rename server and join domain

#### Login as local administrator account

```PowerShell
cls
```

### # Rename server

```PowerShell
Rename-Computer -NewName EXT-WAP01A -Restart
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
Add-Computer -DomainName extranet.technologytoolbox.com -Restart
```

---

**EXT-DC01 - Run as EXTRANET\\jjameson-admin**

```PowerShell
cls
```

### # Move computer to different OU

```PowerShell
$vmName = "EXT-WAP01A"

$targetPath = ("OU=Servers,OU=Resources,OU=IT" `
    + ",DC=extranet,DC=technologytoolbox,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

---

```PowerShell
cls
```

### # Set time zone

```PowerShell
tzutil /s "Mountain Standard Time"
```

### # Copy Toolbox content

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson

$source = "\\TT-FS01\Public\Toolbox"
$destination = "C:\NotBackedUp\Public\Toolbox"

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

## WAP prerequisites

### Reference

**Install and Configure the Web Application Proxy Server**\
From <[https://technet.microsoft.com/en-us/library/dn383662(v=ws.11).aspx](https://technet.microsoft.com/en-us/library/dn383662(v=ws.11).aspx)>

```PowerShell
cls
```

### # Add Remote Access - Web Application Proxy server role

```PowerShell
Install-WindowsFeature Web-Application-Proxy -IncludeManagementTools
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Checkpoint VM

```PowerShell
$vmHost = "TT-HV02A"
$vmName = "EXT-WAP01A"
$snapshotName = "Before - Configure Web Application Proxy"

Stop-VM -ComputerName $vmHost -Name $vmName

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName $snapshotName

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Install certificate - fs.technologytoolbox.com

```PowerShell
cls
```

### # Configure Web Application Proxy

```PowerShell
$cert = Get-ChildItem -Path Cert:\LocalMachine\My |
    Where { $_.Subject -like "CN=fs.technologytoolbox.com,*" }

$cert

$federationServiceTrustCredential = Get-Credential EXTRANET\jjameson-admin
```

> **Note**
>
> When prompted, type the password for the domain administrator account.

```PowerShell
Install-WebApplicationProxy `
    -CertificateThumbprint $cert.Thumbprint `
    -FederationServiceTrustCredential $federationServiceTrustCredential `
    -FederationServiceName fs.technologytoolbox.com


WARNING: A machine restart is required to complete ADFS service configuration. For more information, see:
http://go.microsoft.com/fwlink/?LinkId=798725

Message                                   Context              Status
-------                                   -------              ------
The configuration completed successfully. DeploymentSucceeded Success


Restart-Computer
```

## Publish applications using ADFS preauthentication

### Install certificates

#### Install certificate - \*.securitasinc.com

#### Install certificate - idp.technologytoolbox.com

```PowerShell
cls
```

### # Publish applications

#### # Add hostnames - EXT-FOOBAR4

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    -IPAddress 192.168.10.218 `
    -Hostnames `
        ext-foobar4,
        client-local-4.securitasinc.com,
        idp.technologytoolbox.com
```

#### # Publish https://idp.technologytoolbox.com

```PowerShell
$cert = Get-ChildItem -Path Cert:\LocalMachine\My |
    Where { $_.Subject -like "CN=idp.technologytoolbox.com,*" }

$cert

Add-WebApplicationProxyApplication `
    -BackendUrl 'https://idp.technologytoolbox.com' `
    -ExternalUrl 'https://idp.technologytoolbox.com' `
    -Name 'idp.technologytoolbox.com' `
    -ExternalCertificateThumbprint $cert.Thumbprint `
    -ExternalPreAuthentication PassThrough
```

#### # Publish https://client-local-4.securitasinc.com

```PowerShell
$cert = Get-ChildItem -Path Cert:\LocalMachine\My |
    Where { $_.Subject -like "CN=`*.securitasinc.com,*" }

$cert

Add-WebApplicationProxyApplication `
    -BackendUrl 'https://client-local-4.securitasinc.com' `
    -ExternalUrl 'https://client-local-4.securitasinc.com' `
    -Name 'client-local-4.securitasinc.com' `
    -ExternalCertificateThumbprint $cert.Thumbprint `
    -ExternalPreAuthentication PassThrough

TODO:

Add-WebApplicationProxyApplication `
    -BackendServerUrl 'https://client2-local-4.securitasinc.com' `
    -ExternalCertificateThumbprint '36D400C0B1B36F085340C1BE33B23A18046B764F' `
    -EnableHTTPRedirect:$true `
    -ExternalUrl 'https://client-local-4.securitasinc.com' `
    -Name 'client-local-4.securitasinc.com' `
    -ExternalPreAuthentication ADFS `
    -ADFSRelyingPartyName 'client-local-4.securitasinc.com'
```

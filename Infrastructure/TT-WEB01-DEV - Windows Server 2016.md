# TT-WEB01-DEV - Windows Server 2016

Friday, June 29, 2018\
10:49 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy web server

### Deploy and configure the server infrastructure

---

**FOOBAR16** - Run as administrator

```PowerShell
cls
```

#### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "TT-WEB01-DEV"
$vmPath = "E:\NotBackedUp\VMs\$vmName"
$vhdPath = "$vmPath\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 50GB `
    -MemoryStartupBytes 2GB `
    -SwitchName "Embedded Team Switch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -CheckpointType Standard `
    -DynamicMemory `
    -MemoryMinimumBytes 1GB `
    -MemoryMaximumBytes 4GB `
    -ProcessorCount 2

Start-VM -ComputerName $vmHost -Name $vmName
```

---

#### Install custom Windows Server 2016 image

- On the **Task Sequence** step, select **Windows Server 2016** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **TT-WEB01-DEV**.
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

---

**FOOBAR16** - Run as administrator

```PowerShell
cls
```

#### # Move computer to different OU

```PowerShell
$vmName = "TT-WEB01-DEV"

$targetPath = "OU=Web Servers,OU=Servers" `
    + ",OU=Resources,OU=Development" `
    + ",DC=corp,DC=technologytoolbox,DC=com"

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

#### # Configure Windows Update

##### # Add machine to security group for Windows Update schedule

```PowerShell
Add-ADGroupMember -Identity "Windows Update - Slot 17" -Members ($vmName + '$')
```

---

### Login as .\\foo

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

---

**FOOBAR16** - Run as administrator

```PowerShell
cls
```

### # Set first boot device to hard drive

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "TT-WEB01-DEV"

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

#### Configure static IP address

---

**FOOBAR16** - Run as administrator

```PowerShell
cls
```

##### # Configure static IP address using VMM

```PowerShell
$vmName = "TT-WEB01-DEV"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Management VM Network"
$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"
$ipPool = Get-SCStaticIPAddressPool -Name "Management Address Pool"

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

### Configure storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 50 GB       | 4K                   | OSDisk       |

### Add virtual machine to Hyper-V protection group in DPM

```PowerShell
cls
```

## # Install and configure IIS

### # Enable role - Web Server (IIS)

```PowerShell
Enable-WindowsOptionalFeature `
    -Online `
    -FeatureName `
        IIS-CommonHttpFeatures,
        IIS-DefaultDocument,
        IIS-DirectoryBrowsing,
        IIS-HealthAndDiagnostics,
        IIS-HttpCompressionStatic,
        IIS-HttpErrors,
        IIS-HttpLogging,
        IIS-ManagementConsole,
        IIS-Performance,
        IIS-RequestFiltering,
        IIS-Security,
        IIS-StaticContent,
        IIS-WebServer,
        IIS-WebServerManagementTools,
        IIS-WebServerRole,
        IIS-WindowsAuthentication
```

```PowerShell
cls
```

## # Install Visual Studio 2017

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$setupPath = "\\TT-FS01\Products\Microsoft\Visual Studio 2017\Enterprise" `
    + "\vs_setup.exe"

Start-Process `
    -FilePath $setupPath `
    -Wait
```

Select the following workloads:

- **.NET desktop development**
- **ASP.NET and web development**
- **Office/SharePoint development**

> **Note**
>
> When prompted, restart the computer to complete the installation.

```PowerShell
cls
```

## # Install and configure Securitas Client Portal web service

```PowerShell
Add-WindowsFeature NET-Framework-Core `
    -Source "\\TT-FS01\Products\Microsoft\Windows Server 2016\Sources\SxS"

Enable-WindowsOptionalFeature `
    -Online `
    -FeatureName `
        IIS-ASPNET,
        IIS-ISAPIExtensions,
        IIS-ISAPIFilter,
        IIS-NetFxExtensibility,
        WAS-ConfigurationAPI,
        WAS-NetFxEnvironment,
        WAS-ProcessModel,
        WAS-WindowsActivationService,
        WCF-HTTP-Activation,
        WCF-HTTP-Activation

$hostHeader = "clientportalws-dev.securitasinc.com"

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    -IPAddress 127.0.0.1 `
    -Hostnames $hostHeader


Import-Module WebAdministration

$appPoolName = $hostHeader

New-WebAppPool -Name $appPoolName

$appPool = Get-Item IIS:\AppPools\$appPoolName

$appPool.processModel.identityType = "NetworkService"
$appPool | Set-Item

Set-ItemProperty IIS:\AppPools\$appPoolName managedRuntimeVersion v2.0

New-Item -ItemType Directory -Path "C:\inetpub\wwwroot\$hostHeader"

$site = New-WebSite `
    -name $hostHeader `
    -PhysicalPath "C:\inetpub\wwwroot\$hostHeader" `
    -HostHeader $hostHeader `
    -ApplicationPool $appPoolName
```

```PowerShell
cls
```

### # Configure SSL

#### # Install certificate for secure communication

##### # Copy certificate

```PowerShell
$certFile = "securitasinc.com.pfx"

$sourcePath = "\\TT-FS01\Archive\Clients\Securitas"

$destPath = "C:\NotBackedUp\Temp"

New-Item -ItemType Directory -Path $destPath

Copy-Item "$sourcePath\$certFile" $destPath
```

##### # Install certificate

```PowerShell
$certPassword = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted for the secure string, type the password for the exported certificate.

```PowerShell
$certFile = "C:\NotBackedUp\Temp\securitasinc.com.pfx"

Import-PfxCertificate `
    -FilePath $certFile `
    -CertStoreLocation Cert:\LocalMachine\My `
    -Password $certPassword

If ($? -eq $true)
{
    Remove-Item $certFile -Verbose
}
```

```PowerShell
cls
```

#### # Add HTTPS binding to IIS website

```PowerShell
$cert = Get-ChildItem -Path Cert:\LocalMachine\My |
    Where { $_.Subject -like "CN=`*.securitasinc.com,*" }

New-WebBinding `
    -Name $hostHeader `
    -Protocol https `
    -Port 443 `
    -HostHeader $hostHeader `
    -SslFlags 0

$cert |
    New-Item `
        -Path ("IIS:\SslBindings\0.0.0.0!443!" + $hostHeader)
```

---

**FOOBAR16** - Run as administrator

```PowerShell
cls
```

## # Move VM to new Production VM network

```PowerShell
$vmName = "TT-WEB01-DEV"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Production VM Network"
$ipAddressPool = Get-SCStaticIPAddressPool -Name "Production-15 Address Pool"

Stop-SCVirtualMachine $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -IPv4AddressPools $ipAddressPool `
    -IPv4AddressType Static

Start-SCVirtualMachine $vmName
```

---

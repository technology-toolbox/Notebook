# EXT-WEB03B

Monday, March 26, 2018
4:03 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

Install SecuritasConnect v4.0

## Deploy and configure server infrastructure

### Install Windows Server 2012 R2

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05B"
$vmName = "EXT-WEB03B"
$vmPath = "E:\NotBackedUp\VMs\$vmName"
$vhdPath = "$vmPath\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 45GB `
    -MemoryStartupBytes 12GB `
    -SwitchName "Embedded Team Switch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 4

Start-VM -ComputerName $vmHost -Name $vmName
```

---

#### Install custom Windows Server 2012 R2 image

- On the **Task Sequence** step, select **Windows Server 2012 R2** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **EXT-WEB03B**.
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

robocopy $source $destination /E /XD "Microsoft SDKs" /MIR
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

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Set first boot device to hard drive

```PowerShell
$vmHost = "TT-HV05B"
$vmName = "EXT-WEB03B"

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
$interfaceAlias = "Extranet-20"
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

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

##### # Configure static IP address using VMM

```PowerShell
$vmName = "EXT-WEB03B"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Extranet-20 VM Network"
$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"
$ipPool = Get-SCStaticIPAddressPool -Name "Extranet-20 Address Pool"

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
| 0    | C:           | 45 GB       | 4K                   | OSDisk       |
| 1    | D:           | 40 GB       | 4K                   | Data01       |
| 2    | L:           | 20 GB       | 4K                   | Log01        |

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Configure storage for the SQL Server

```PowerShell
$vmHost = "TT-HV05B"
$vmName = "EXT-WEB03B"
$vmPath = "E:\NotBackedUp\VMs\$vmName"
```

##### # Add "Data01" VHD

```PowerShell
$vhdPath = $vmPath + "\Virtual Hard Disks\$vmName" + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 40GB
Add-VMHardDiskDrive `
  -ComputerName $vmHost `
  -VMName $vmName `
  -Path $vhdPath `
  -ControllerType SCSI
```

##### # Add "Log01" VHD

```PowerShell
$vhdPath = $vmPath + "\Virtual Hard Disks\$vmName" + "_Log01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 20GB
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

#### # Initialize disks and format volumes

##### # Format Data01 drive

```PowerShell
Get-Disk 1 |
  Initialize-Disk -PartitionStyle GPT -PassThru |
  New-Partition -DriveLetter D -UseMaximumSize |
  Format-Volume `
    -FileSystem NTFS `
    -NewFileSystemLabel "Data01" `
    -Confirm:$false
```

##### # Format Log01 drive

```PowerShell
Get-Disk 2 |
  Initialize-Disk -PartitionStyle GPT -PassThru |
  New-Partition -DriveLetter L -UseMaximumSize |
  Format-Volume `
    -FileSystem NTFS `
    -NewFileSystemLabel "Log01" `
    -Confirm:$false
```

### # Join member server to domain

```PowerShell
Add-Computer `
    -DomainName extranet.technologytoolbox.com `
    -Credential (Get-Credential EXTRANET\jjameson-admin) `
    -Restart
```

---

**EXT-DC08 - Run as EXTRANET\\jjameson-admin**

```PowerShell
cls
```

##### # Move computer to different OU

```PowerShell
$computerName = "EXT-WEB03B"

$targetPath = ("OU=SharePoint Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=extranet,DC=technologytoolbox,DC=com")

Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath
```

##### # Configure Windows Update

###### # Add machine to security group for Windows Update schedule

```PowerShell
$domainGroupName = "Windows Update - Slot 3"

Add-ADGroupMember -Identity $domainGroupName -Members ($computerName + '$')
```

---

### Install latest service pack and updates

```PowerShell
cls
```

## # Install and configure SharePoint Server 2013

### # Temporarily enable firewall rule to allow files to be copied to server

```PowerShell
Enable-NetFirewallRule -DisplayName "File and Printer Sharing (SMB-in)"
```

### # Install SharePoint 2013 prerequisites on farm servers

#### # Add SQL Server administrators domain group to local Administrators group

```PowerShell
$domain = "EXTRANET"
$groupName = "SharePoint Admins"

([ADSI]"WinNT://./Administrators,group").Add(
    "WinNT://$domain/$groupName,group")
```

> **Important**
>
> Login as **EXTRANET\\setup-sharepoint** to install SharePoint.

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Mount SharePoint Server 2013 installation media

```PowerShell
$vmHost = "TT-HV05B"
$vmName = "EXT-WEB03B"
$isoName = "en_sharepoint_server_2013_with_sp1_x64_dvd_3823428.iso"
```

##### # Add virtual DVD drive

```PowerShell
Add-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName
```

##### # Refresh virtual machine in VMM

```PowerShell
Read-SCVirtualMachine -VM $vmName
```

##### # Mount installation media in virtual DVD drive

```PowerShell
$iso = Get-SCISO | where { $_.Name -eq $isoName }

Get-SCVirtualDVDDrive -VM $vmName |
    Set-SCVirtualDVDDrive -ISO $iso -Link
```

#### # Copy SharePoint Server 2013 prerequisite files to SharePoint server

```PowerShell
$source = "\\TT-FS01\Products\Microsoft\SharePoint 2013" `
    + "\PrerequisiteInstallerFiles_SP1"

$destination = '\\EXT-WEB03B.extranet.technologytoolbox.com' `
    + '\C$\NotBackedUp\Temp\PrerequisiteInstallerFiles_SP1'

robocopy $source $destination /E
```

---

#### # Install SharePoint Server 2013 prerequisites

```PowerShell
$prereqPath = "C:\NotBackedUp\Temp\PrerequisiteInstallerFiles_SP1"

& E:\PrerequisiteInstaller.exe `
    /SQLNCli:"$prereqPath\sqlncli.msi" `
    /PowerShell:"$prereqPath\Windows6.1-KB2506143-x64.msu" `
    /NETFX:"$prereqPath\dotNetFx45_Full_setup.exe" `
    /IDFX:"$prereqPath\Windows6.1-KB974405-x64.msu" `
    /Sync:"$prereqPath\Synchronization.msi" `
    /AppFabric:"$prereqPath\WindowsServerAppFabricSetup_x64.exe" `
    /IDFX11:"$prereqPath\MicrosoftIdentityExtensions-64.msi" `
    /MSIPCClient:"$prereqPath\setup_msipc_x64.msi" `
    /WCFDataServices:"$prereqPath\WcfDataServices.exe" `
    /KB2671763:"$prereqPath\AppFabric1.1-RTM-KB2671763-x64-ENU.exe" `
    /WCFDataServices56:"$prereqPath\WcfDataServices-5.6.exe"
```

> **Important**
>
> Wait for the prerequisites to be installed. When prompted, restart the server to continue the installation.

```PowerShell
Remove-Item "C:\NotBackedUp\Temp\PrerequisiteInstallerFiles_SP1" -Recurse
```

### # Install SharePoint Server 2013 on farm servers

```PowerShell
& E:\setup.exe
```

> **Important**
>
> Wait for the installation to complete.

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Dismount SharePoint Server 2013 installation media

```PowerShell
$vmHost = "TT-HV05B"
$vmName = "EXT-WEB03B"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

---

### # Add SharePoint bin folder to PATH environment variable

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-PathFolders.ps1 `
    ("C:\Program Files\Common Files\Microsoft Shared\web server extensions" `
        + "\15\BIN") `
    -EnvironmentVariableTarget "Machine"

exit
```

> **Important**
>
> Restart PowerShell for environment variable change to take effect.

### Install Cumulative Update for SharePoint Server 2013

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Download update

```PowerShell
$patch = "15.0.4833.1000 - SharePoint 2013 June 2016 CU"

$source = ("\\TT-FS01\Products\Microsoft\SharePoint 2013" `
    + "\Patches\$patch")

$destination = "\\EXT-WEB03B.extranet.technologytoolbox.com" `
    + "\C`$\NotBackedUp\Temp\$patch"

robocopy $source $destination /E
```

---

```PowerShell
cls
```

#### # Install update

```PowerShell
$patch = "15.0.4833.1000 - SharePoint 2013 June 2016 CU"

& "C:\NotBackedUp\Temp\$patch\*.exe"
```

> **Important**
>
> Wait for the update to be installed.

```Console
cls
Remove-Item "C:\NotBackedUp\Temp\$patch" -Recurse
```

### # Install Cumulative Update for AppFabric 1.1

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Download update

```PowerShell
$patch = "Cumulative Update 7"

$source = ("\\TT-FS01\Products\Microsoft\AppFabric 1.1" `
    + "\Patches\$patch")

$destination = "\\EXT-WEB03B.extranet.technologytoolbox.com" `
    + "\C`$\NotBackedUp\Temp\$patch"

robocopy $source $destination /E
```

---

```PowerShell
cls
```

#### # Install update

```PowerShell
$patch = "Cumulative Update 7"

& "C:\NotBackedUp\Temp\$patch\*.exe"
```

> **Important**
>
> Wait for the update to be installed.

```Console
cls
Remove-Item "C:\NotBackedUp\Temp\$patch" -Recurse
```

#### # Enable nonblocking garbage collection for Distributed Cache Service

```PowerShell
Notepad ($env:ProgramFiles `
    + "\AppFabric 1.1 for Windows Server\DistributedCacheService.exe.config")
```

---

**DistributedCacheService.exe.config**

```XML
  <appSettings>
    <add key="backgroundGC" value="true"/>
  </appSettings>
```

---

```PowerShell
cls
```

## # Install and configure additional software

### # Install Prince on front-end Web servers

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Copy installation files

```PowerShell
$source = "\\TT-FS01\Products\Prince"

$destination = "\\EXT-WEB03B.extranet.technologytoolbox.com" `
    + "\C`$\NotBackedUp\Temp\Prince"

robocopy $source $destination /E
```

---

```PowerShell
cls
```

#### # Install Prince

```PowerShell
& "C:\NotBackedUp\Temp\Prince\prince-7.1-setup.exe"
```

> **Important**
>
> Wait for the software to be installed.

```PowerShell
cls
```

#### # Configure Prince license

```PowerShell
Copy-Item `
    C:\NotBackedUp\Temp\Prince\Prince-license.dat `
    'C:\Program Files (x86)\Prince\Engine\license\license.dat'
```

1. In the **Prince** window, click the **Help** menu and then click **License**.
2. In the **Prince License** window:
   1. Click **Open** and then locate the license file (**C:\\NotBackedUp\\Temp\\Prince\\Prince-license.dat**).
   2. Click **Accept** to save the license information.
   3. Verify the license information and then click **Close**.
3. Close the Prince application.

```PowerShell
cls
```

#### # Remove installation files

```PowerShell
Remove-Item "C:\NotBackedUp\Temp\Prince" -Recurse
```

### # Disable firewall rule previously enabled to allow files to be copied to server

```PowerShell
Disable-NetFirewallRule -DisplayName "File and Printer Sharing (SMB-in)"
```

### Install additional service packs and updates

> **Important**
>
> Wait for the updates to be installed and restart the server (if necessary).

### Add Web servers to the farm

```PowerShell
cls
```

### # Grant permissions on DCOM applications for SharePoint

```PowerShell
$tempScript = [Io.Path]::GetTempFileName().Replace(".tmp", ".ps1")

$sourceScript = "\\EXT-APP03A\Builds\ClientPortal\4.0.701.0" `
    + "\DeploymentFiles\Scripts\Configure DCOM Permissions.ps1"

Get-Content $sourceScript | Out-File $tempScript

& $tempScript -Verbose

Remove-Item $tempScript
```

```PowerShell
cls
```

### # Configure People Picker to support searches across one-way trust

#### # Set application password used for encrypting credentials

```PowerShell
$appPassword = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted for the secure string, type the password for encrypting sensitive data in SharePoint applications.

```PowerShell
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($appPassword))

stsadm -o setapppassword -password $plainPassword
```

#### # Modify permissions on registry key where encrypted credentials are stored

```PowerShell
$regPath = `
    "HKLM:\SOFTWARE\Microsoft\Shared Tools\Web Server Extensions\15.0\Secure"

$acl = Get-Acl $regPath

$rule = New-Object System.Security.AccessControl.RegistryAccessRule(
    "$env:COMPUTERNAME\WSS_WPG",
    "ReadKey",
    "ContainerInherit",
    "None",
    "Allow")

$acl.SetAccessRule($rule)
Set-Acl -Path $regPath -AclObject $acl
```

```PowerShell
cls
```

### # Map Web application to loopback address in Hosts file

```PowerShell
& C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    -IPAddress 127.0.0.1 `
    -Hostnames client-test.securitasinc.com `
    -Verbose
```

### # Allow specific host names mapped to 127.0.0.1

```PowerShell
& C:\NotBackedUp\Public\Toolbox\PowerShell\Add-BackConnectionHostNames.ps1 `
    -HostNames client-test.securitasinc.com `
    -Verbose
```

### # Configure SSL on Internet zone

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Copy SSL certificate to SharePoint 2013 server

```PowerShell
$source = "\\TT-FS01\Archive\Clients\Securitas\securitasinc.com.pfx"
$destination = "\\EXT-WEB03B.extranet.technologytoolbox.com" `
    + "\C`$\Users\setup-sharepoint\Desktop"

Copy-Item $source $destination
```

---

#### # Install SSL certificate

```PowerShell
$certPassword = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted for the secure string, type the password for the exported certificate.

```PowerShell
Import-PfxCertificate `
    -FilePath "C:\Users\setup-sharepoint\Desktop\securitasinc.com.pfx" `
    -CertStoreLocation Cert:\LocalMachine\My `
    -Password $certPassword
```

#### Add HTTPS binding to site in IIS

```PowerShell
cls
```

### # Enable disk-based caching for Web application

```PowerShell
Push-Location ("C:\inetpub\wwwroot\wss\VirtualDirectories\" `
    + "client-test.securitasinc.com80")

copy web.config "web - Copy.config"

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    '\\EXT-APP03A\C$\inetpub\wwwroot\wss\VirtualDirectories\client-test.securitasinc.com80\web.config' `
    .\web.config

Pop-Location
```

```PowerShell
cls
```

### # Configure logging

```PowerShell
$tempScript = [Io.Path]::GetTempFileName().Replace(".tmp", ".ps1")

$sourceScript = "\\EXT-APP03A\Builds\ClientPortal\4.0.701.0" `
    + "\DeploymentFiles\Scripts\Add Event Log Sources.ps1"

Get-Content $sourceScript | Out-File $tempScript

& $tempScript -Verbose

Remove-Item $tempScript
```

```PowerShell
cls
```

### # Configure claims-based authentication

```PowerShell
$target = "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions" `
    + "\15\WebServices\SecurityToken\web.config"

$targetItem = Get-Item $target

Push-Location $targetItem.Directory

Copy-Item `
    -Path $targetItem.Name `
    -Destination ($targetItem.BaseName + " - Copy" + $targetItem.Extension)

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    $target.Replace("C:\", "\\EXT-APP03A\C`$\") `
    $target

Pop-Location
```

## Create and configure media website

### Install IIS Media Services 4.1

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Download Web Platform Installer

```PowerShell
$source = "\\TT-FS01\Products\Microsoft\Web Platform Installer 5.0" `
    + "\wpilauncher.exe"

$destination = "\\EXT-WEB03B.extranet.technologytoolbox.com" `
    + "\C`$\NotBackedUp\Temp"

Copy-Item $source $destination
```

---

```PowerShell
cls
```

#### # Install IIS Media Services

```PowerShell
& "C:\NotBackedUp\Temp\wpilauncher.exe"
```

```PowerShell
cls
```

### # Install Web Deploy 3.6

#### # Install Web Deploy

```PowerShell
& "C:\NotBackedUp\Temp\wpilauncher.exe"
```

## Create and configure the Cloud Portal Web application

### Configure SSL on the Internet zone

#### Add HTTPS binding to site in IIS

```PowerShell
cls
```

### # Enable disk-based caching for Web application

```PowerShell
Push-Location ("C:\inetpub\wwwroot\wss\VirtualDirectories\" `
    + "cloud-test.securitasinc.com80")

copy web.config "web - Copy.config"

C:\NotBackedUp\Public\Toolbox\DiffMerge\DiffMerge.exe `
    '\\EXT-APP02A\C$\inetpub\wwwroot\wss\VirtualDirectories\cloud-test.securitasinc.com80\web.config' `
    .\web.config

Pop-Location
```

```PowerShell
cls
```

### # Configure logging

```PowerShell
$tempScript = [Io.Path]::GetTempFileName().Replace(".tmp", ".ps1")

$sourceScript = "\\EXT-APP02A\Builds\CloudPortal\2.0.122.0" `
    + "\DeploymentFiles\Scripts\Add Event Log Sources.ps1"

Get-Content $sourceScript | Out-File $tempScript

& $tempScript -Verbose

Remove-Item $tempScript
```

```PowerShell
cls
```

# Install Employee Portal

## # Extend SecuritasConnect and Cloud Portal web applications

```PowerShell
cls
```

### # Enable disk-based caching for "intranet" websites

#### # Enable disk-based caching for SecuritasConnect "intranet" website

```PowerShell
Push-Location ("C:\inetpub\wwwroot\wss\VirtualDirectories\" `
    + "client2-test.securitasinc.com443")

copy web.config "web - Copy.config"

C:\NotBackedUp\Public\Toolbox\DiffMerge\DiffMerge.exe `
    '..\client-test.securitasinc.com80\web.config' `
    .\web.config

Pop-Location
```

#### # Enable disk-based caching for Cloud Portal "intranet" website

```PowerShell
Push-Location ("C:\inetpub\wwwroot\wss\VirtualDirectories\" `
    + "cloud2-test.securitasinc.com443")

copy web.config "web - Copy.config"

C:\NotBackedUp\Public\Toolbox\DiffMerge\DiffMerge.exe `
    '..\cloud-test.securitasinc.com80\web.config' `
    .\web.config

Pop-Location
```

```PowerShell
cls
```

### # Map intranet URLs to loopback address in Hosts file

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    127.0.0.1 client2-test.securitasinc.com, cloud2-test.securitasinc.com
```

### # Allow specific host names mapped to 127.0.0.1

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-BackConnectionHostnames.ps1 `
    client2-test.securitasinc.com, cloud2-test.securitasinc.com
```

## Install Web Deploy 3.6

### Install Web Deploy

(skipped -- since this was completed earlier)

```PowerShell
cls
```

## # Install .NET Framework 4.5

### # Download .NET Framework 4.5.2 installer

```PowerShell
net use \\ICEMAN\Products /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
Copy-Item `
    ("\\ICEMAN\Products\Microsoft\.NET Framework 4.5\.NET Framework 4.5.2\" `
        + "NDP452-KB2901907-x86-x64-AllOS-ENU.exe") `
    C:\NotBackedUp\Temp
```

### # Install .NET Framework 4.5.2

```PowerShell
& C:\NotBackedUp\Temp\NDP452-KB2901907-x86-x64-AllOS-ENU.exe
```

> **Important**
>
> When prompted, restart the computer to complete the installation.

```PowerShell
Remove-Item C:\NotBackedUp\Temp\NDP452-KB2901907-x86-x64-AllOS-ENU.exe
```

### Install updates

> **Important**
>
> When prompted, restart the computer to complete the process of installing the updates.

## # Upgrade to System Center Operations Manager 2016

### # Uninstall SCOM 2012 R2 agent

```PowerShell
msiexec /x `{786970C5-E6F6-4A41-B238-AE25D4B91EEA`}

Restart-Computer
```

### # Install SCOM 2016 agent

```PowerShell
net use \\tt-fs01.corp.technologytoolbox.com\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$msiPath = "\\tt-fs01.corp.technologytoolbox.com\Products\Microsoft" `
    + "\System Center 2016\Agents\SCOM\AMD64\MOMAgent.msi"

msiexec.exe /i $msiPath `
    MANAGEMENT_GROUP=HQ `
    MANAGEMENT_SERVER_DNS=tt-scom01.corp.technologytoolbox.com `
    ACTIONS_USE_COMPUTER_ACCOUNT=1
```

> **Important**
>
> Wait for the installation to complete.

### Approve manual agent install in Operations Manager

## # Move VM to extranet VLAN

### # Enable DHCP

```PowerShell
$interfaceAlias = Get-NetAdapter `
    -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    select -ExpandProperty Name

@("IPv4", "IPv6") | ForEach-Object {
    $addressFamily = $_

    $interface = Get-NetAdapter $interfaceAlias |
        Get-NetIPInterface -AddressFamily $addressFamily

    If ($interface.Dhcp -eq "Disabled")
    {
        # Remove existing gateway
        $ipConfig = $interface | Get-NetIPConfiguration

        If ($addressFamily -eq "IPv4" -and $ipConfig.Ipv4DefaultGateway)
        {
            $interface |
                Remove-NetRoute -AddressFamily $addressFamily -Confirm:$false
        }

        If ($addressFamily -eq "IPv6" -and $ipConfig.Ipv6DefaultGateway)
        {
            $interface |
                Remove-NetRoute -AddressFamily $addressFamily -Confirm:$false
        }

        # Enable DHCP
        $interface | Set-NetIPInterface -DHCP Enabled

        # Configure the  DNS Servers automatically
        $interface | Set-DnsClientServerAddress -ResetServerAddresses
    }
}
```

### # Rename network connection

```PowerShell
$interfaceAlias = "Extranet"

Get-NetAdapter `
    -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

### # Disable jumbo frames

```PowerShell
Set-NetAdapterAdvancedProperty `
    -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 1514

Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"
```

---

**TT-VMM01A**

```PowerShell
cls
```

### # Configure static IP address using VMM

```PowerShell
$vmName = "EXT-WEB02B"

$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"

$vmNetwork = Get-SCVMNetwork -Name "Extranet VM Network"

$ipPool = Get-SCStaticIPAddressPool -Name "Extranet Address Pool"

$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName |
    ? { $_.SlotId -eq 0 }

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

## Issue - Error accessing SharePoint sites (e.g. http://client-test.securitasinc.com)

Log Name:      Application\
Source:        ASP.NET 4.0.30319.0\
Date:          5/18/2017 11:06:29 AM\
Event ID:      1309\
Task Category: Web Event\
Level:         Warning\
Keywords:      Classic\
User:          N/A\
Computer:      EXT-WEB02B.extranet.technologytoolbox.com\
Description:\
Event code: 3005\
Event message: An unhandled exception has occurred.\
Event time: 5/18/2017 11:06:29 AM\
Event time (UTC): 5/18/2017 5:06:29 PM\
Event ID: 0fd660226e724958bba36b1cb4e17992\
Event sequence: 8\
Event occurrence: 1\
Event detail code: 0\
\
Application information:\
    Application domain: /LM/W3SVC/762047535/ROOT-1-131396007128500689\
    Trust level: Full\
    Application Virtual Path: /\
    Application Path: C:\\inetpub\\wwwroot\\wss\\VirtualDirectories\\client-test.securitasinc.com80\\\
    Machine name: EXT-WEB02B\
\
Process information:\
    Process ID: 4496\
    Process name: w3wp.exe\
    Account name: EXTRANET\\s-web-client\
\
Exception information:\
    Exception type: FileLoadException\
    Exception message: Loading this assembly would produce a different grant set from other instances. (Exception from HRESULT: 0x80131401)\
   at System.Linq.Enumerable.Count[TSource](IEnumerable`1 source)\
   at Microsoft.SharePoint.IdentityModel.SPChunkedCookieHandler.ReadCore(String name, HttpContext context)\
   at Microsoft.IdentityModel.Web.SessionAuthenticationModule.TryReadSessionTokenFromCookie(SessionSecurityToken& sessionToken)\
   at Microsoft.IdentityModel.Web.SessionAuthenticationModule.OnAuthenticateRequest(Object sender, EventArgs eventArgs)\
   at Microsoft.SharePoint.IdentityModel.SPSessionAuthenticationModule.OnAuthenticateRequest(Object sender, EventArgs eventArgs)\
   at System.Web.HttpApplication.SyncEventExecutionStep.System.Web.HttpApplication.IExecutionStep.Execute()\
   at System.Web.HttpApplication.ExecuteStep(IExecutionStep step, Boolean& completedSynchronously)

\
\
Request information:\
    Request URL: [https://client-test.securitasinc.com:443/favicon.ico](https://client-test.securitasinc.com:443/favicon.ico)\
    Request path: /favicon.ico\
    User host address: 127.0.0.1\
    User:\
    Is authenticated: False\
    Authentication Type:\
    Thread account name: EXTRANET\\s-web-client\
\
Thread information:\
    Thread ID: 20\
    Thread account name: EXTRANET\\s-web-client\
    Is impersonating: False\
    Stack trace:    at System.Linq.Enumerable.Count[TSource](IEnumerable`1 source)\
   at Microsoft.SharePoint.IdentityModel.SPChunkedCookieHandler.ReadCore(String name, HttpContext context)\
   at Microsoft.IdentityModel.Web.SessionAuthenticationModule.TryReadSessionTokenFromCookie(SessionSecurityToken& sessionToken)\
   at Microsoft.IdentityModel.Web.SessionAuthenticationModule.OnAuthenticateRequest(Object sender, EventArgs eventArgs)\
   at Microsoft.SharePoint.IdentityModel.SPSessionAuthenticationModule.OnAuthenticateRequest(Object sender, EventArgs eventArgs)\
   at System.Web.HttpApplication.SyncEventExecutionStep.System.Web.HttpApplication.IExecutionStep.Execute()\
   at System.Web.HttpApplication.ExecuteStep(IExecutionStep step, Boolean& completedSynchronously)\

### References

**Loading this assembly would produce a different grant set from other instances. (Exception from HRESULT: 0x80131401)**\
From <[http://blog.bugrapostaci.com/2017/02/08/loading-this-assembly-would-produce-a-different-grant-set-from-other-instances-exception-from-hresult-0x80131401/](http://blog.bugrapostaci.com/2017/02/08/loading-this-assembly-would-produce-a-different-grant-set-from-other-instances-exception-from-hresult-0x80131401/)>

**Monitoring SharePoint 2010 Applications in System Center 2012 SP1**\
From <[https://technet.microsoft.com/en-us/library/jj614617.aspx?tduid=(1dfb939b69d4a5ed09b44f51992a8b97)(256380)(2459594)(TnL5HPStwNw-v0X_tBOK3jzpbtaadMW8RA)()](https://technet.microsoft.com/en-us/library/jj614617.aspx?tduid=(1dfb939b69d4a5ed09b44f51992a8b97)(256380)(2459594)(TnL5HPStwNw-v0X_tBOK3jzpbtaadMW8RA)())>

**SCOM 2016 Sharepoint 2013 PerfMon64.dll crash W3wp.exe**\
From <[https://social.technet.microsoft.com/Forums/en-US/24b4d768-57a2-42c9-8e18-1ef8c075913a/scom-2016-sharepoint-2013-perfmon64dll-crash-w3wpexe?forum=scomapm](https://social.technet.microsoft.com/Forums/en-US/24b4d768-57a2-42c9-8e18-1ef8c075913a/scom-2016-sharepoint-2013-perfmon64dll-crash-w3wpexe?forum=scomapm)>

**SCOM 2016 Agent Crashing Legacy IIS Application Pools**\
From <[http://kevingreeneitblog.blogspot.ie/2017/03/scom-2016-agent-crashing-legacy-iis.html](http://kevingreeneitblog.blogspot.ie/2017/03/scom-2016-agent-crashing-legacy-iis.html)>

**APM feature in SCOM 2016 Agent may cause a crash for the IIS Application Pool running under .NET 2.0 runtime**\
From <[https://blogs.technet.microsoft.com/momteam/2017/03/21/apm-feature-in-scom-2016-agent-may-cause-a-crash-for-the-iis-application-pool-running-under-net-2-0-runtime/](https://blogs.technet.microsoft.com/momteam/2017/03/21/apm-feature-in-scom-2016-agent-may-cause-a-crash-for-the-iis-application-pool-running-under-net-2-0-runtime/)>

### Solution

Remove SCOM agent and reinstall without Application Performance Monitoring (APM).

#### Remove SCOM agent

> **Note**
>
> When prompted, restart the server.

#### # Clean up SCOM agent folder

```PowerShell
Remove-Item "C:\Program Files\Microsoft Monitoring Agent" -Recurse -Force
```

#### Install SCOM agent without Application Performance Monitoring (APM)

---

**FOOBAR10**

```PowerShell
cls
```

##### # Copy SCOM agent setup files from file server

```PowerShell
$source = "\\TT-FS01.corp.technologytoolbox.com\Products\Microsoft" `
```

    + "\\System Center 2016\\SCOM\\agent\\AMD64"

```PowerShell
$destination = "\\EXT-WEB02B.extranet.technologytoolbox.com\C$\NotBackedUp\Temp" `
```

    + "\\System Center 2016\\SCOM\\agent\\AMD64"

```Console
robocopy $source $destination /E /MIR
```

---

```PowerShell
cls
```

##### # Install SCOM agent

```PowerShell
$msiPath = "C:\NotBackedUp\Temp\System Center 2016\SCOM\agent\AMD64\MOMAgent.msi"

msiexec.exe /i $msiPath `
    MANAGEMENT_GROUP=HQ `
    MANAGEMENT_SERVER_DNS=TT-SCOM01.corp.technologytoolbox.com `
    ACTIONS_USE_COMPUTER_ACCOUNT=1 `
    NOAPM=1
```

```PowerShell
cls
```

##### # Delete SCOM agent setup files

```PowerShell
Remove-Item "C:\NotBackedUp\Temp\System Center 2016" -Recurse
```

#### Approve manual agent install in Operations Manager

## Deploy federated authentication in SecuritasConnect

### Install and configure identity provider for client users

#### Deploy identity provider website to front-end web servers

##### Install certificate for secure communication with idp.technologytoolbox.com

---

**WOLVERINE - Run as TECHTOOLBOX\\jjameson**

```PowerShell
cls
```

###### # Copy certificate from internal file server

```PowerShell
$computerName = "EXT-WEB03B.extranet.technologytoolbox.com"
$certFile = "idp.technologytoolbox.com.pfx"

$source = "\\TT-FS01\Users$\jjameson\My Documents\Technology Toolbox LLC" `
    + "\Certificates\Internal"

$destination = "\\$computerName\C$\NotBackedUp\Temp"

net use "\\$computerName\C`$" /USER:EXTRANET\jjameson-admin
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```Console
robocopy $source $destination $certFile
```

---

```PowerShell
cls
```

###### # Install certificate

```PowerShell
$certPassword = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted for the secure string, type the password for the exported certificate.

```PowerShell
cls
```

###### # Import the certificate into the certificate store

```PowerShell
$certFile = "C:\NotBackedUp\Temp\idp.technologytoolbox.com.pfx"

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

##### # Install .NET Framework 4.5

---

**WOLVERINE - Run as TECHTOOLBOX\\jjameson**

```PowerShell
cls
```

###### # Download .NET Framework 4.5.2 installer

```PowerShell
$computerName = "EXT-WEB03B.extranet.technologytoolbox.com"

$source = "\\TT-FS01\Products\Microsoft\.NET Framework 4.5\.NET Framework 4.5.2\" `
        + "NDP452-KB2901907-x86-x64-AllOS-ENU.exe"

$destination = "\\$computerName\C$\NotBackedUp\Temp"

net use "\\$computerName\C`$" /USER:EXTRANET\jjameson-admin
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
Copy-Item $source $destination
```

---

```PowerShell
cls
```

###### # Install .NET Framework 4.5.2

```PowerShell
& C:\NotBackedUp\Temp\NDP452-KB2901907-x86-x64-AllOS-ENU.exe
```

> **Important**
>
> When prompted, restart the computer to complete the installation.

```PowerShell
Remove-Item C:\NotBackedUp\Temp\NDP452-KB2901907-x86-x64-AllOS-ENU.exe
```

###### Install updates

> **Important**
>
> When prompted, restart the computer to complete the process of installing the updates.

```PowerShell
cls
```

#### # Install and configure token-signing certificate

##### # Install token-signing certificate

```PowerShell
$certPassword = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted for the secure string, type the password for the exported certificate.

```PowerShell
$newBuild = "4.0.701.0"

Push-Location ("\\EXT-APP03A\Builds\ClientPortal\$newBuild" `
    + "\DeploymentFiles\Certificates")

Import-PfxCertificate `
    -FilePath "Token-signing - idp.securitasinc.com.pfx" `
    -CertStoreLocation Cert:\LocalMachine\My `
    -Password $certPassword

Pop-Location
```

##### # Configure permissions on token-signing certificate

```PowerShell
$idpHostHeader = "idp.technologytoolbox.com"

$serviceAccount = "IIS APPPOOL\$idpHostHeader"
$certThumbprint = "3907EFB9E1B4D549C22200E560D3004778594DDF"

$cert = Get-ChildItem -Path cert:\LocalMachine\My |
    where { $_.ThumbPrint -eq $certThumbprint }

$keyPath = [System.IO.Path]::Combine(
    "$env:ProgramData\Microsoft\Crypto\RSA\MachineKeys",
    $cert.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName)

$acl = Get-Acl -Path $keyPath

$accessRule = New-Object `
```

    -TypeName System.Security.AccessControl.FileSystemAccessRule `\
    -ArgumentList \$serviceAccount, "Read", "Allow"

```PowerShell
$acl.AddAccessRule($accessRule)

Set-Acl -Path $keyPath -AclObject $acl
```

## Issue - Firewall log contains numerous entries for UDP 137 broadcast

### Solution

```PowerShell
cls
```

#### # Disable NetBIOS over TCP/IP

```PowerShell
Get-NetAdapter |
    foreach {
        $interfaceAlias = $_.Name

        Write-Host ("Disabling NetBIOS over TCP/IP on interface" `
            + " ($interfaceAlias)...")

        $adapter = Get-WmiObject -Class "Win32_NetworkAdapter" `
            -Filter "NetConnectionId = '$interfaceAlias'"

        $adapterConfig = `
            Get-WmiObject -Class "Win32_NetworkAdapterConfiguration" `
                -Filter "Index= '$($adapter.DeviceID)'"

        # Disable NetBIOS over TCP/IP
        $adapterConfig.SetTcpipNetbios(2)
    }
```

**TODO:**

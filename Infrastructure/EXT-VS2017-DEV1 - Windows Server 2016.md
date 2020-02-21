# EXT-VS2017-DEV1 - Windows Server 2016

Monday, June 3, 2019
7:23 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure infrastructure

---

**FOOBAR18 - Run as administrator**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "EXT-VS2017-DEV1"
$vmPath = "E:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 100GB `
    -MemoryStartupBytes 4GB `
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
  - In the **Computer name** box, type **EXT-VS2017-DEV1**.
  - Specify **WORKGROUP**.
  - Click **Next**.
- On the **Applications** step:
  - Select the following applications:
    - **Adobe**
      - **Adobe Reader 8.3.1**
    - **Chrome**
      - **Chrome (64-bit)**
    - **Mozilla**
      - **Firefox (64-bit)**
      - **Thunderbird**
  - Click **Next**.

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

### Login as .\\foo

```PowerShell
cls
```

### # Configure storage

#### # Set MaxPatchCacheSize to 0 (recommended)

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

### Configure networking

---

**FOOBAR18 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Move VM to Extranet VM network

```PowerShell
$vmName = "EXT-VS2017-DEV1"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Extranet-20 VM Network"

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

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Start-Sleep -Seconds 5

ping EXT-DC10 -f -l 8900
```

```PowerShell
cls
```

### # Join domain

```PowerShell
Add-Computer -DomainName extranet.technologytoolbox.com -Restart
```

---

**EXT-DC10 - Run as domain administrator**

```PowerShell
cls

$vmName = "EXT-VS2017-DEV1"
```

### # Move computer to different OU

```PowerShell
$targetPath = ("OU=Workstations,OU=Resources,OU=Development" `
    + ",DC=extranet,DC=technologytoolbox,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

### # Configure Windows Update

#### # Add machine to security group for Windows Update schedule

```PowerShell
Add-ADGroupMember -Identity "Windows Update - Slot 20" -Members ($vmName + '$')
```

---

```PowerShell
cls
```

## # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

> **Note**
>
> PowerShell remoting must be enabled for remote Windows Update using PoshPAIG ([https://github.com/proxb/PoshPAIG](https://github.com/proxb/PoshPAIG)).

```PowerShell
cls
```

## # Install and configure Visual Studio 2017

### # Launch Visual Studio 2017 setup

```PowerShell
net use \\EXT-FS01\IPC$ /USER:EXTRANET\jjameson-admin
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$setupPath = "\\EXT-FS01\Products\Microsoft\Visual Studio 2017\Enterprise" `
    + "\vs_setup.exe"

Start-Process -FilePath $setupPath -Wait
```

### # Install Visual Studio 2017

Select the following workloads:

- **.NET desktop development**
- **Desktop development with C++**
- **Universal Windows Platform development**
- **ASP.NET and web development**
- **Azure development**
- **Python development**
- **Node.js development**
- **Data storage and processing**
- **Data science and analytical applications**
- **Office/SharePoint development**
- **Mobile development with .NET**
- **Game development with Unity**
- **Mobile development with JavaScript**
- **Mobile development with C++**
- **Game development with C++**
- **Visual Studio extension development**
- **Linux development with C++**
- **.NET Core cross-platform development**

```PowerShell
cls
```

### # Add items to Trusted Sites in Internet Explorer for Visual Studio login

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-InternetSecurityZoneMapping.ps1 `
    -Zone TrustedSites `
    -Patterns https://login.microsoftonline.com, https://aadcdn.msauth.net, `
        https://aadcdn.msftauth.net
```

```PowerShell
cls
```

## # Install and configure Git

### # Install Git

```PowerShell
net use \\EXT-FS01\IPC$ /USER:EXTRANET\jjameson-admin
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$setupPath = "\\EXT-FS01\Products\Git\Git-2.21.0-64-bit.exe"

Start-Process -FilePath $setupPath -Wait
```

On the **Choosing the default editor used by Git** step, select **Use the Nano editor by default**.

> **Important**
>
> Wait for the installation to complete and restart PowerShell for environment changes to take effect.

```Console
exit
```

```Console
cls
```

### # Configure symbolic link (e.g. for bash shell)

```PowerShell
Push-Location C:\NotBackedUp\Public\Toolbox\cmder\vendor

cmd /c mklink /J git-for-windows "C:\Program Files\Git"

Pop-Location
```

### # Configure Git to use SourceGear DiffMerge

```PowerShell
git config --global diff.tool diffmerge

git config --global difftool.diffmerge.cmd  '"C:/NotBackedUp/Public/Toolbox/DiffMerge/x64/sgdm.exe \"$LOCAL\" \"$REMOTE\"'
```

#### Reference

**Git for Windows (MSysGit) or Git Cmd**\
From <[https://sourcegear.com/diffmerge/webhelp/sec__git__windows__msysgit.html](https://sourcegear.com/diffmerge/webhelp/sec__git__windows__msysgit.html)>

## Install GitHub Desktop

```PowerShell
cls
```

## # Install PowerShell modules

### # Install posh-git module (e.g. for Powerline Git prompt customization)

#### # Install NuGet package provider (to bypass prompt when installing posh-git module)

```PowerShell
Install-PackageProvider NuGet -MinimumVersion '2.8.5.201' -Force
```

#### # Trust PSGallery repository (to bypass prompt when installing posh-git module)

```PowerShell
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
```

#### # Install posh-git module

```PowerShell
Install-Module -Name 'posh-git'
```

### Upgrade Azure PowerShell module

#### Remove AzureRM module

1. Open **Programs and Features**
2. Uninstall **Microsoft Azure PowerShell - April 2018**

```PowerShell
cls
```

#### # Install new Azure PowerShell module

```PowerShell
Install-Module -Name Az -AllowClobber -Scope AllUsers
```

## Install updates using Windows Update

> **Note**
>
> Repeat until there are no updates available for the computer.

```PowerShell
cls
```

## # Add developers to local Administrators group

```PowerShell
$domain = "EXTRANET"
$groupName = "All Developers"

([ADSI]"WinNT://./Administrators,group").Add(
    "WinNT://$domain/$groupName,group")
```

## Baseline virtual machine

---

**FOOBAR18 - Run as administrator**

```PowerShell
cls
```

### # Checkpoint VM

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "EXT-VS2017-DEV1"
$checkpointName = "Baseline"

Stop-VM -ComputerName $vmHost -Name $vmName

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName $checkpointName
```

---

## Back up virtual machine

**TODO:**

```PowerShell
cls
```

## # Copy cmder configuration

### # Temporarily enable firewall rule for copying files to server

```PowerShell
Enable-NetFirewallRule -DisplayName "File and Printer Sharing (SMB-In)"
```

---

**STORM - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Copy cmder configuration

```PowerShell
$computer = "EXT-VS2017-DEV1.extranet.technologytoolbox.com"
$source = "C:\NotBackedUp\Public\Toolbox\cmder"
$destination = "\\$computer\C$\NotBackedUp\Public\Toolbox\cmder"

robocopy $source $destination /E /XD git-for-windows /MIR /NP
```

---

```PowerShell
cls
```

### # Disable firewall rule for copying files to server

```PowerShell
Disable-NetFirewallRule -DisplayName "File and Printer Sharing (SMB-In)"
```

```PowerShell
cls
```

## # Configure e-mail and name for Git

```PowerShell
git config --global user.email "jjameson@technologytoolbox.com"
git config --global user.name "Jeremy Jameson"
```

```PowerShell
cls
```

## # Clone repo for Pluralsight course

```PowerShell
mkdir C:\NotBackedUp\GitHub\jeremy-jameson

Push-Location C:\NotBackedUp\GitHub\jeremy-jameson

git clone https://github.com/jeremy-jameson/SecuringAspNetCore2WithOAuth2AndOIDC.git

Pop-Location
```

```PowerShell
cls
```

## # Clone repo for IdentityServer4.Admin

```PowerShell
mkdir C:\NotBackedUp\GitHub\skoruba

Push-Location C:\NotBackedUp\GitHub\skoruba

git clone https://github.com/skoruba/IdentityServer4.Admin.git

Pop-Location
```

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

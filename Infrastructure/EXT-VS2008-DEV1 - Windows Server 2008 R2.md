# EXT-VS2008-DEV1 - Windows Server 2008 R2

Wednesday, November 13, 2019
3:51 AM

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
$vmHost = "TT-HV05C"
$vmName = "EXT-VS2008-DEV1"
$vmPath = "E:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"
$isoPath = "\\TT-FS01\Products\Microsoft\MDT-Deploy-x64.iso"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 60GB `
    -MemoryStartupBytes 4GB `
    -SwitchName "Embedded Team Switch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 4 `
    -AutomaticCheckpointsEnabled $false

Set-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path $isoPath

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Install custom Windows Server 2008 R2 image

- On the **Task Sequence** step, select **Windows Server 2008 R2** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **EXT-VS2008-DEV1**.
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

---

**TT-ADMIN02 - Run as administrator**

```PowerShell
cls
```

### # Remove disk from virtual CD/DVD drive

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "EXT-VS2008-DEV1"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

---

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

#### # Change drive letter for DVD-ROM

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
```

### Configure networking

---

**TT-ADMIN02 - Run as administrator**

```PowerShell
cls
```

#### # Move VM to Extranet VM network

```PowerShell
$vmName = "EXT-VS2008-DEV1"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Extranet-20 VM Network"

Stop-SCVirtualMachine $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork

Start-SCVirtualMachine $vmName
```

---

#### Rename network connection

Rename **Local Area Connection** to **Extranet-20**.

### Join domain

---

**EXT-DC10** - Run as domain administrator

```PowerShell
cls

$vmName = "EXT-VS2008-DEV1"
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
Add-ADGroupMember -Identity "Windows Update - Slot 2" -Members ($vmName + '$')
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

## # Add developers to local Administrators group

```PowerShell
$domain = "EXTRANET"
$groupName = "All Developers"

([ADSI]"WinNT://./Administrators,group").Add(
    "WinNT://$domain/$groupName,group")
```

```PowerShell
cls
```

## # Install SQL Server 2008 R2 Express

```PowerShell
net use \\EXT-FS01\IPC$ /USER:EXTRANET\jjameson-admin
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$setupPath = "\\EXT-FS01\Products\Microsoft\SQL Server 2008 R2\Express\x64\SQLEXPRWT_x64_ENU.exe"

Start-Process -FilePath $setupPath -Wait
```

> **Important**
>
> Wait for the installation to complete and restart the computer.

## Install Visual Studio 2008

---

**TT-ADMIN02 - Run as administrator**

```PowerShell
cls
```

### # Insert Visual Studio 2008 installation media

```PowerShell
$vmName = "EXT-VS2008-DEV1"
$vmHost = "TT-HV05C"

Get-SCVirtualMachine -Name $vmName | Read-SCVirtualMachine

$iso = Get-SCISO |
    where {$_.Name -eq "en_visual_studio_team_system_2008_team_suite_x86_dvd_x14-26461.iso"}

Get-SCVirtualMachine -Name $vmName |
    Get-SCVirtualDVDDrive |
    Set-SCVirtualDVDDrive -ISO $iso -Link
```

---

### Install Visual Studio 2008

Select all features except **SQL Server 2005 Express Edition**.

> **Note**
>
> When prompted, restart the computer to complete the installation.

### Install Visual Studio 2008 Service Pack 1

---

**TT-ADMIN02 - Run as administrator**

```PowerShell
cls
```

#### # Insert Visual Studio 2008 Service Pack 1 installation media

```PowerShell
$vmName = "EXT-VS2008-DEV1"
$vmHost = "TT-HV05C"

Get-SCVirtualMachine -Name $vmName | Read-SCVirtualMachine

$iso = Get-SCISO |
    where {$_.Name -eq "en_visual_studio_2008_service_pack_1_x86_dvd_x15-12962.iso"}

Get-SCVirtualMachine -Name $vmName |
    Get-SCVirtualDVDDrive |
    Set-SCVirtualDVDDrive -ISO $iso -Link
```

---

### Install ASP.NET MVC 1.0

**ASP.NET MVC 1.0**\
From <[https://www.microsoft.com/en-us/download/details.aspx?id=5388](https://www.microsoft.com/en-us/download/details.aspx?id=5388)>

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
$setupPath = "\\EXT-FS01\Products\Git\Git-2.24.0-64-bit.exe"

Start-Process -FilePath $setupPath -Wait
```

On the **Choosing the default editor used by Git** step, select **Use the Nano editor by default**.

> **Important**
>
> Wait for the installation to complete and restart PowerShell for environment changes to take effect.

```Console
exit
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

> **Note**
>
> GitHub Desktop requires .NET Framework 4.5 to be installed (and will automatically install it, if necessary).

```PowerShell
cls
```

## # Install MbUnit test runner

```PowerShell
net use \\EXT-FS01\IPC$ /USER:EXTRANET\jjameson-admin
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$setupPath = "\\EXT-FS01\Products\Gallio\MbUnit-2.4.2.355-Setup.exe"

Start-Process -FilePath $setupPath -Wait
```

> **Important**
>
> Wait for the installation to complete.

## Install Windows Management Framework 5.1

**Windows Management Framework 5.1**\
From <[https://www.microsoft.com/en-us/download/details.aspx?id=54616](https://www.microsoft.com/en-us/download/details.aspx?id=54616)>

> **Note**
>
> Windows Management Framework 5.1 installs Windows PowerShell 5 (which includes new cmdlets like **Install-PackageProvider**).

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

```PowerShell
cls
```

## # Update PowerShell help

```PowerShell
Update-Help
```

## Install updates using Windows Update

> **Note**
>
> Repeat until there are no updates available for the computer.

```PowerShell
cls
```

### # Delete C:\\Windows\\SoftwareDistribution folder (1.6 GB)

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse

Restart-Computer
```

```PowerShell
cls
```

## # Copy cmder configuration

```PowerShell
$source = "\\EXT-FS01\Public\cmder-config"
$destination = "C:\NotBackedUp\Public\Toolbox\cmder"

robocopy $source $destination /E
```

## Configure profile for TECHTOOLBOX\\jjameson

> **Important**
>
> Login as TECHTOOLBOX\\jjameson

```PowerShell
cls
```

### # Add items to Trusted Sites in Internet Explorer for Visual Studio login

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-InternetSecurityZoneMapping.ps1 `
    -Zone TrustedSites `
    -Patterns https://login.microsoftonline.com, https://aadcdn.msauth.net, `
        https://aadcdn.msftauth.net, https://spsprodcus3.vssps.visualstudio.com
```

```PowerShell
cls
```

### # Configure e-mail and name for Git

```PowerShell
git config --global user.email "jjameson@technologytoolbox.com"
git config --global user.name "Jeremy Jameson"
```

## Baseline virtual machine

---

**TT-ADMIN02 - Run as administrator**

```PowerShell
cls
```

### # Remove installation media from DVD drive

```PowerShell
$vmName = "EXT-VS2008-DEV1"

Get-SCVirtualMachine -Name $vmName |
    Get-SCVirtualDVDDrive |
    Set-SCVirtualDVDDrive -NoMedia
```

---

---

**TT-ADMIN02 - Run as administrator**

```PowerShell
cls
```

### # Checkpoint VM

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "EXT-VS2008-DEV1"
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

# EXT-VS2010-DEV1 - Windows Server 2008 R2

Friday, May 31, 2019
8:54 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure infrastructure

---

**STORM - Run as administrator**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmName = "EXT-VS2010-DEV1"
$vmPath = "D:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"
$isoPath = "\\TT-FS01\Products\Microsoft\MDT-Deploy-x64.iso"

New-VM `
    -Name $vmName `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 60GB `
    -MemoryStartupBytes 4GB `
    -SwitchName "LAN"

Set-VM `
    -Name $vmName `
    -ProcessorCount 4 `
    -AutomaticCheckpointsEnabled $false

Set-VMDvdDrive `
    -VMName $vmName `
    -Path $isoPath

Start-VM -Name $vmName
```

---

### Install custom Windows Server 2008 R2 image

- On the **Task Sequence** step, select **Windows Server 2008 R2** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **EXT-VS2010-DEV1**.
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

**STORM - Run as administrator**

```PowerShell
cls
```

### # Remove disk from virtual CD/DVD drive

```PowerShell
$vmName = "EXT-VS2010-DEV1"

Set-VMDvdDrive -VMName $vmName -Path $null
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

#### # Set MaxPatchCacheSize to 0 (recommended)

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

### Configure networking

---

**STORM - Run as administrator**

```PowerShell
cls
```

#### # Move VM to Extranet VM network

```PowerShell
$vmName = "EXT-VS2010-DEV1"

Stop-VM $vmName

Set-VMNetworkAdapterVlan `
    -VMName $vmName `
    -Access `
    -VlanId 20

Start-VM $vmName
```

---

#### Rename network connection

Rename **Local Area Connection** to **Extranet-20**.

### Join domain

---

**EXT-DC10 - Run as domain administrator**

```PowerShell
cls

$vmName = "EXT-VS2010-DEV1"
```

### # Move computer to different OU

```PowerShell
$targetPath = ("OU=Workstations,OU=Resources,OU=Development" `
    + ",DC=extranet,DC=technologytoolbox,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

### # Configure Windows Update

##### # Add machine to security group for Windows Update schedule

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

## # Install Visual Studio 2010

---

**STORM - Run as administrator**

```PowerShell
cls
```

### # Insert Visual Studio 2010 installation media

```PowerShell
$vmName = "EXT-VS2010-DEV1"
$isoPath = "\\TT-FS01\Products\Microsoft\Visual Studio 2010\en_visual_studio_2010_ultimate_x86_dvd_509116.iso"

Set-VMDvdDrive -VMName $vmName -Path $isoPath
```

---

### Install Visual Studio 2010

> **Note**
>
> When prompted, restart the computer to complete the installation.

### Install ASP.NET MVC 3.0

**ASP.NET MVC 3 RTM**\
From <[https://www.microsoft.com/en-us/download/details.aspx?id=4211](https://www.microsoft.com/en-us/download/details.aspx?id=4211)>

```PowerShell
cls
```

### # Add items to Trusted Sites in Internet Explorer for Visual Studio login

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-InternetSecurityZoneMapping.ps1 `
    -Zone TrustedSites `
    -Patterns https://login.microsoftonline.com, https://aadcdn.msauth.net, `
        https://aadcdn.msftauth.net, https://spsprodcus3.vssps.visualstudio.com
```

```PowerShell
cls
```

## # Install SQL Server 2008 Management Studio Express

```PowerShell
net use \\EXT-FS01\IPC$ /USER:EXTRANET\jjameson-admin
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$setupPath = "\\EXT-FS01\Products\Microsoft\SQL Server 2008 R2\Express\x64\SQLManagementStudio_x64_ENU.exe"

Start-Process -FilePath $setupPath -Wait
```

> **Important**
>
> Wait for the installation to complete.

## Install and configure Git

### Download Git for Windows

[https://git-scm.com/download/win](https://git-scm.com/download/win)

```PowerShell
cls
```

### # Install Git

```PowerShell
$setupPath = "C:\Users\Administrator\Downloads\Git-2.21.0-64-bit.exe"

Start-Process -FilePath $setupPath -Wait
```

On the **Choosing the default editor used by Git** step, select **Use the Nano editor by default**.

> **Important**
>
> Wait for the installation to complete and restart PowerShell for environment changes to take effect.

```Console
exit
```

### # Remove Git setup file

```PowerShell
Remove-Item "C:\Users\Administrator\Downloads\Git-2.21.0-64-bit.exe"
```

```PowerShell
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

> **Note**
>
> GitHub Desktop requires .NET Framework 4.5 to be installed (and will automatically install it, if necessary).

```PowerShell
cls
```

## # Install MbUnit test runners

### # Install MbUnit test runner for .NET 3.5

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

```PowerShell
cls
```

### # Install MbUnit test runner for .NET 4

```PowerShell
$setupPath = "\\EXT-FS01\Products\Gallio\GallioBundle-3.4.14.0-Setup-x64.msi"

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

### # Delete C:\\Windows\\SoftwareDistribution folder

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

**STORM - Run as administrator**

```PowerShell
cls
```

### # Checkpoint VM

```PowerShell
$vmName = "EXT-VS2010-DEV1"
$checkpointName = "Baseline"

Stop-VM -Name $vmName

Checkpoint-VM `
    -Name $vmName `
    -SnapshotName $checkpointName

Start-VM -Name $vmName
```

---

## Back up virtual machine

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

**TODO:**

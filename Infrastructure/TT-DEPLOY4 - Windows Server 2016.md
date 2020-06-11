# TT-DEPLOY4 - Windows Server 2016

Friday, November 17, 2017
6:08 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

### Install Windows Server 2016

---

**FOOBAR10** - Run as administrator

```PowerShell
cls
```

#### # Create virtual machine

```PowerShell
$vmHost = "TT-HV02B"
$vmName = "TT-DEPLOY4"
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
    -ProcessorCount 2

Add-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName

$vmDvdDrive = Get-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName

Set-VMFirmware `
    -ComputerName $vmHost `
    -VMName $vmName `
    -EnableSecureBoot Off `
    -FirstBootDevice $vmDvdDrive

Set-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path C:\NotBackedUp\Products\Microsoft\MDT-Deploy-x64.iso

Start-VM -ComputerName $vmHost -Name $vmName
```

---

#### Install custom Windows Server 2016 image

- On the **Task Sequence** step, select **Windows Server 2016** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **TT-DEPLOY4**.
  - Click **Next**.
- On the **Applications** step, do not select any applications, and click **Next**.

---

**FOOBAR10** - Run as administrator

```PowerShell
cls
```

#### # Remove disk from virtual CD/DVD drive

```PowerShell
$vmHost = "TT-HV02B"
$vmName = "TT-DEPLOY4"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

---

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

**FOOBAR10** - Run as administrator

```PowerShell
cls
```

### # Move computer to different OU

```PowerShell
$vmName = "TT-DEPLOY4"

$targetPath = "OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com"

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

### # Configure Windows Update

#### # Add machine to security group for Windows Update schedule

```PowerShell
Add-ADGroupMember -Identity "Windows Update - Slot 1" -Members ($vmName + '$')
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

### # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
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

### Configure storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 32 GB       | 4K                   | OSDisk       |
| 1    | D:           | 50 GB       | 4K                   | Data01       |

```PowerShell
cls
```

#### # Change drive letter for DVD-ROM

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
```

---

**FOOBAR10** - Run as administrator

```PowerShell
cls
```

### # Add disks to virtual machine

```PowerShell
$vmHost = "TT-HV02B"
$vmName = "TT-DEPLOY4"
$vmPath = "E:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\" + $vmName + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 50GB
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

### # Initialize disks and format volumes

#### # Format Data01 drive

```PowerShell
Get-Disk 1 |
    Initialize-Disk -PartitionStyle GPT -PassThru |
    New-Partition -UseMaximumSize -DriveLetter D |
    Format-Volume `
        -FileSystem NTFS `
        -NewFileSystemLabel "Data01" `
        -Confirm:$false
```

---

**FOOBAR10** - Run as administrator

```PowerShell
cls
```

### # Enable Secure Boot and set first boot device to hard drive

```PowerShell
$vmHost = "TT-HV02B"
$vmName = "TT-DEPLOY4"

$vmHardDiskDrive = Get-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName |
    where { $_.ControllerType -eq "SCSI" `
        -and $_.ControllerNumber -eq 0 `
        -and $_.ControllerLocation -eq 0 }

Stop-VM `
    -ComputerName $vmHost `
    -VMName $vmName

Set-VMFirmware `
    -ComputerName $vmHost `
    -VMName $vmName `
    -EnableSecureBoot On `
    -FirstBootDevice $vmHardDiskDrive

Start-VM `
    -ComputerName $vmHost `
    -VMName $vmName
```

---

## Add virtual machine to Hyper-V protection group in DPM

## Install and configure Microsoft Deployment Toolkit

### Reference

**Prepare for deployment with MDT 2013 Update 2**\
From <[https://technet.microsoft.com/en-us/itpro/windows/deploy/prepare-for-windows-deployment-with-mdt-2013](https://technet.microsoft.com/en-us/itpro/windows/deploy/prepare-for-windows-deployment-with-mdt-2013)>

### Login as TECHTOOLBOX\\jjameson-admin

```PowerShell
cls
```

### # Install Windows Assessment and Deployment Kit (Windows ADK) for Windows 10

```PowerShell
& ("\\TT-FS01\Products\Microsoft\Windows Assessment and Deployment Kit" `
    + "\Windows ADK for Windows 10, version 1709\adksetup.exe")
```

1. On the **Specify Location** page, click **Next**.
2. On the **Windows Kits Privacy** page, click **Next**.
3. On the **License Agreement** page:
   1. Review the software license terms.
   2. If you agree to the terms, click **Accept**.
4. On the **Select the features you want to install** page:
   1. Select the following items:
      - **Deployment Tools**
      - **Windows Preinstallation Environment (Windows PE)**
      - **User State Migration Tool (USMT)**
   2. Click **Install**.

```PowerShell
cls
```

### # Install Microsoft Deployment Toolkit

```PowerShell
& ("\\TT-FS01\Products\Microsoft\Microsoft Deployment Toolkit" `
    + "\MDT - build 8443\MicrosoftDeploymentToolkit_x64.msi")
```

### Update MDT deployment shares and regenerate boot images

#### Change monitoring host to TT-DEPLOY4

1. Open **Deployment Workbench** and expand **Deployment Shares**.
2. Right-click **MDT Build Lab ([\\\\TT-FS01\\MDT-Build\$](\\TT-FS01\MDT-Build$))** and then click **Properties**.
3. In the **MDT Build Lab ([\\\\TT-FS01\\MDT-Build\$](\\TT-FS01\MDT-Build$)) Properties** window:
   1. On the **Monitoring** tab, in the **Monitoring host** box, type **TT-DEPLOY4**.
   2. Click **OK**.
4. Repeat the previous steps to update the **MDT Deployment ([\\\\TT-FS01\\MDT-Deploy\$](\\TT-FS01\MDT-Deploy$))** deployment share.

#### Update MDT deployment shares (to regenerate the boot images)

1. Open **Deployment Workbench** and expand **Deployment Shares**.
2. Right-click **MDT Build Lab ([\\\\TT-FS01\\MDT-Build\$](\\TT-FS01\MDT-Build$))** and then click **Update Deployment Share**.
3. In the **Update Deployment Share Wizard**:
   1. On the **Options** step, select **Completely regenerate the boot images**, and then click **Next**.
   2. On the **Summary** step, click **Next**.
   3. Wait for the deployment share to be updated, verify no errors occurred during the update, and then click **Finish**.
4. Repeat the previous steps to update the **MDT Deployment ([\\\\TT-FS01\\MDT-Deploy\$](\\TT-FS01\MDT-Deploy$))** deployment share.

```PowerShell
cls
```

#### # Copy boot images to file server

```PowerShell
@(
'\\TT-FS01\MDT-Build$\Boot\MDT-Build-x64.iso',
'\\TT-FS01\MDT-Build$\Boot\MDT-Build-x86.iso',
'\\TT-FS01\MDT-Deploy$\Boot\MDT-Deploy-x64.iso',
'\\TT-FS01\MDT-Deploy$\Boot\MDT-Deploy-x86.iso') |
    foreach {
        Copy-Item $_ "\\TT-FS01\Products\Microsoft"
    }
```

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

#### # Update files in TFS

##### # Sync files

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

$source = '\\TT-FS01\MDT-Build$'
$destination = '.\Main\MDT-Build$'

robocopy $source $destination /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools

$source = '\\TT-FS01\MDT-Deploy$'
$destination = '.\Main\MDT-Deploy$'

robocopy $source $destination /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools
```

##### Check-in files

---

```PowerShell
cls
```

### # Install System Center 2012 R2 Configuration Manager Toolkit (for log viewer)

```PowerShell
& ("\\TT-FS01\Products\Microsoft\System Center 2012 R2" `
    + "\System Center 2012 R2 Configuration Manager Toolkit\ConfigMgrTools.msi")
```

## Install and configure Windows Deployment Services

### Reference

**Windows Deployment Services Getting Started Guide for Windows Server 2012**\
From <[https://technet.microsoft.com/en-us/library/jj648426.aspx](https://technet.microsoft.com/en-us/library/jj648426.aspx)>

```PowerShell
cls
```

### # Install Windows Deployment Services

```PowerShell
Install-WindowsFeature -Name WDS -IncludeManagementTools
```

```PowerShell
cls
```

### # Configure Windows Deployment Services integrated with Active Directory

```PowerShell
WDSUTIL /Initialize-Server /RemInst:"D:\RemoteInstall"
```

```PowerShell
cls
```

### # Configure WDS PXE response policy

```PowerShell
WDSUTIL /Set-Server /AnswerClients:All
```

```PowerShell
cls
```

### # Add boot images

```PowerShell
Import-WdsBootImage `
    -Path "\\TT-FS01\MDT-Build$\Boot\LiteTouchPE_x86.wim" `
    -NewImageName "MDT Build (x86)" `
    -NewDescription "Choose this image to create a reference build using MDT" `
    -NewFileName "MDT-Build-x86-boot.wim"

Import-WdsBootImage `
    -Path "\\TT-FS01\MDT-Build$\Boot\LiteTouchPE_x64.wim" `
    -NewImageName "MDT Build (x64)" `
    -NewDescription "Choose this image to create a reference build using MDT" `
    -NewFileName "MDT-Build-x64-boot.wim"

Import-WdsBootImage `
    -Path "\\TT-FS01\MDT-Deploy$\Boot\LiteTouchPE_x86.wim" `
    -NewImageName "MDT Deploy (x86)" `
    -NewDescription "Choose this image to deploy a reference build" `
    -NewFileName "MDT-Deploy-x86-boot.wim"
```

#### Issue

```PowerShell
Import-WdsBootImage : Access is denied.
At line:1 char:1
+ Import-WdsBootImage `
+ ~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (MSFT_WdsBootImage:root/cimv2/MSFT_WdsBootImage) [Import-WdsBootImage], Ci
   mException
    + FullyQualifiedErrorId : 0x5,Import-WdsBootImage
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/21/035C7B5933D61C9098E622B937DCB65347ED8221.png)

#### Reference

**WDS : GUI or cmdlet : Access is denied**\
From <[https://social.technet.microsoft.com/Forums/en-US/f3d9c5ef-f63a-4991-a72d-22850b5c2ec6/wds-gui-or-cmdlet-access-is-denied?forum=winserversetup](https://social.technet.microsoft.com/Forums/en-US/f3d9c5ef-f63a-4991-a72d-22850b5c2ec6/wds-gui-or-cmdlet-access-is-denied?forum=winserversetup)>

#### Workaround

Copy the WIM file locally and then call **Import-WdsBootImage**:

```PowerShell
mkdir C:\NotBackedUp\Temp

Copy-Item "\\TT-FS01\MDT-Deploy$\Boot\LiteTouchPE_x86.wim" C:\NotBackedUp\Temp

Import-WdsBootImage `
    -Path "C:\NotBackedUp\Temp\LiteTouchPE_x86.wim" `
    -NewImageName "MDT Deploy (x86)" `
    -NewDescription "Choose this image to deploy a reference build" `
    -NewFileName "MDT-Deploy-x86-boot.wim"

Remove-Item "C:\NotBackedUp\Temp\LiteTouchPE_x86.wim"

Copy-Item "\\TT-FS01\MDT-Deploy$\Boot\LiteTouchPE_x64.wim" C:\NotBackedUp\Temp

Import-WdsBootImage `
    -Path "C:\NotBackedUp\Temp\LiteTouchPE_x64.wim" `
    -NewImageName "MDT Deploy (x64)" `
    -NewDescription "Choose this image to deploy a reference build" `
    -NewFileName "MDT-Deploy-x64-boot.wim"

Remove-Item "C:\NotBackedUp\Temp\LiteTouchPE_x64.wim"
```

```PowerShell
cls
```

### # Configure display order for boot images

```PowerShell
Set-WdsBootImage -Architecture x64 -ImageName "MDT Deploy (x64)" -DisplayOrder 10
Set-WdsBootImage -Architecture x86 -ImageName "MDT Deploy (x86)" -DisplayOrder 100
Set-WdsBootImage -Architecture x64 -ImageName "MDT Build (x64)" -DisplayOrder 200
Set-WdsBootImage -Architecture x86 -ImageName "MDT Build (x86)" -DisplayOrder 300
```

## Configure WDS to use PXELinux

### Reference

**Booting Alternative Images from WDS using PXELinux**\
From <[https://www.mikeslab.net/?p=504](https://www.mikeslab.net/?p=504)>

---

**FOOBAR10** - Run as administrator

### Download syslinux

[https://www.kernel.org/pub/linux/utils/boot/syslinux/4.xx/syslinux-4.07.zip](https://www.kernel.org/pub/linux/utils/boot/syslinux/4.xx/syslinux-4.07.zip)

### Install PXELinux files

#### Extract files

Extract the following files to [\\\\TT-DEPLOY4\\C\$\\NotBackedUp\\Temp\\PXELinux](\\TT-DEPLOY4\C$\NotBackedUp\Temp\PXELinux):

- **core/pxelinux.0**
- **com32/menu/vesamenu.c32**

---

```PowerShell
cls
```

#### # Rename PXELinux boot program to use the required file extension

```PowerShell
Push-Location C:\NotBackedUp\Temp\PXELinux

Rename-Item pxelinux.0 pxelinux.com

Pop-Location
```

#### # Configure PXELinux

```PowerShell
$pxeLinuxPath = "D:\RemoteInstall\Boot\PXELinux"

robocopy C:\NotBackedUp\Temp\PXELinux $pxeLinuxPath

$pxeLinuxConfigPath = "$pxeLinuxPath\pxelinux.cfg"

mkdir $pxeLinuxConfigPath

$pxeLinuxMenuFile = "$pxeLinuxConfigPath\default"

New-Item -ItemType File -Path $pxeLinuxMenuFile

Notepad $pxeLinuxMenuFile
```

---

File - **D:\\RemoteInstall\\Boot\\PXELinux\\pxelinux.cfg\\default**

```INI
# Set the default command line
DEFAULT vesamenu.c32

# Time out and use the default menu option. Defined as tenths of a second.
TIMEOUT 300

# Prompt the user. Set to '1' to automatically choose the default option. This
# is really meant for files matched to MAC addresses.
PROMPT 0

# Menu configuration
#
# Reference: http://www.syslinux.org/wiki/index.php?title=Menu

MENU COLOR screen       37;44    #ffffffff #ff1e4173 none
MENU COLOR border       37;44    #ff3c78c3 #ffeeeeee none
MENU COLOR scrollbar    37;44    #40000000 #ff959595 std
MENU COLOR tabmsg       30;47    #ff4f4f4f #ffffffff none
MENU COLOR title        34;47    #ff1e4173 #ffffffff none
MENU COLOR sel          7;37;40  #ff000000 #ffffff99 none
MENU COLOR unsel        30;47    #ff4f4f4f #ffffffff none
MENU COLOR timeout_msg  30;47    #ff3c78c3 #ffffffff none
MENU COLOR timeout      30;47    #ffbd1c1c #ffffffff none

MENU TITLE Technology Toolbox PXE Boot

# Menu option

#---
LABEL local
    MENU DEFAULT
    MENU LABEL Boot from hard disk
    LOCALBOOT 0
    APPEND type 0x80
#---
LABEL wds
    MENU LABEL Windows Deployment Services
    KERNEL pxeboot.0
#---
LABEL abortpxe
    MENU LABEL Abort PXE
    KERNEL abortpxe.0
```

---

```PowerShell
cls
```

#### # Configure symbolic links for PXELinux

```PowerShell
Push-Location D:\RemoteInstall\Boot\x86

cmd /c mklink pxelinux.com $pxeLinuxPath\pxelinux.com
cmd /c mklink vesamenu.c32 $pxeLinuxPath\vesamenu.c32

cmd /c mklink /J pxelinux.cfg $pxeLinuxConfigPath

cmd /c mklink abortpxe.0 abortpxe.com
cmd /c mklink pxeboot.0 pxeboot.n12

Pop-Location

Push-Location D:\RemoteInstall\Boot\x64

cmd /c mklink pxelinux.com $pxeLinuxPath\pxelinux.com
cmd /c mklink vesamenu.c32 $pxeLinuxPath\vesamenu.c32

cmd /c mklink /J pxelinux.cfg $pxeLinuxConfigPath

cmd /c mklink abortpxe.0 abortpxe.com
cmd /c mklink pxeboot.0 pxeboot.n12

Pop-Location
```

```PowerShell
cls
```

#### # Configure WDS to use PXELinux as the boot program (for x86 and x64 -- but not for UEFI)

```PowerShell
WDSUTIL /Set-Server /BootProgram:Boot\x86\pxelinux.com /Architecture:x86
WDSUTIL /Set-Server /N12BootProgram:Boot\x86\pxelinux.com /Architecture:x86

WDSUTIL /Set-Server /BootProgram:Boot\x64\pxelinux.com /Architecture:x64
WDSUTIL /Set-Server /N12BootProgram:Boot\x64\pxelinux.com /Architecture:x64
```

> **Note**
>
> For troubleshooting purposes, the following commands can be used to revert WDS to use the default boot programs:
>
> ```Console
> WDSUTIL /Set-Server /BootProgram:boot\x86\pxeboot.com /Architecture:x86
> WDSUTIL /Set-Server /N12BootProgram:boot\x86\pxeboot.n12 /Architecture:x86
> WDSUTIL /Set-Server /BootProgram:boot\x64\pxeboot.com /Architecture:x64
> WDSUTIL /Set-Server /N12BootProgram:boot\x64\pxeboot.n12 /Architecture:x64
> ```

## Add custom (PXELinux) Windows Deployment Services files to TFS

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

### # Sync files

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

$source = '\\TT-DEPLOY4\D$\RemoteInstall\Boot\PXELinux'
$destination = '.\Main\Windows Deployment Services\RemoteInstall\Boot\PXELinux'

robocopy $source $destination /E
```

### # Add files to TFS

```PowerShell
$tf = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE" `
    + "\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\TF.exe"

& $tf add Main /r
```

### Check-in files

---

## Resolve issues with LOCALBOOT and some BIOS versions

### Reference

**Hardware Compatibility**\
From <[http://www.syslinux.org/wiki/index.php?title=Hardware_Compatibility#LOCALBOOT](http://www.syslinux.org/wiki/index.php?title=Hardware_Compatibility#LOCALBOOT)>

---

**FOOBAR10** - Run as administrator

### Install chain.c32

#### Extract file from syslinux-4.07.zip

Extract the following file to [\\\\TT-DEPLOY4\\C\$\\NotBackedUp\\Temp\\PXELinux](\\TT-DEPLOY4\C$\NotBackedUp\Temp\PXELinux):

- **com32/chain/chain.c32**

---

```PowerShell
cls
```

#### # Copy chain.c32 to PXELinux folder

```PowerShell
$filename = "chain.c32"
$pxeLinuxPath = "D:\RemoteInstall\Boot\PXELinux"

robocopy C:\NotBackedUp\Temp\PXELinux $pxeLinuxPath $filename
```

#### # Configure symbolic links for chain.c32

```PowerShell
Push-Location D:\RemoteInstall\Boot\x86

cmd /c mklink $filename $pxeLinuxPath\$filename

Pop-Location

Push-Location D:\RemoteInstall\Boot\x64

cmd /c mklink $filename $pxeLinuxPath\$filename

Pop-Location
```

### # Update "Boot from hard disk" menu option to use chain.c32 (instead of LOCALBOOT)

```PowerShell
$pxeLinuxMenuFile = "$pxeLinuxPath\pxelinux.cfg\default"

Notepad $pxeLinuxMenuFile
```

---

File - **D:\\RemoteInstall\\Boot\\PXELinux\\pxelinux.cfg\\default**

```INI
...
# Menu items

#---
LABEL local
    MENU DEFAULT
    MENU LABEL Boot from hard disk
    COM32 chain.c32
    APPEND hd0
...
```

---

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

### # Update custom (PXELinux) Windows Deployment Services files in TFS

#### # Sync files

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

$source = '\\TT-DEPLOY4\D$\RemoteInstall\Boot\PXELinux'
$destination = '.\Main\Windows Deployment Services\RemoteInstall\Boot\PXELinux'

robocopy $source $destination /E
```

#### # Add files to TFS

```PowerShell
$tf = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE" `
    + "\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\TF.exe"

& $tf add Main /r
```

#### Check-in files

---

## Add boot option - Hardware Detection Tool

---

**FOOBAR10** - Run as administrator

### Install hdt.c32

#### Extract file from syslinux-4.07.zip

Extract the following file to [\\\\TT-DEPLOY4\\C\$\\NotBackedUp\\Temp\\PXELinux](\\TT-DEPLOY4\C$\NotBackedUp\Temp\PXELinux):

- **com32/hdt/hdt.c32**

---

```PowerShell
cls
```

#### # Copy hdt.c32 to PXELinux folder

```PowerShell
$pxeLinuxPath = "D:\RemoteInstall\Boot\PXELinux"

robocopy C:\NotBackedUp\Temp\PXELinux $pxeLinuxPath hdt.c32
```

#### # Configure symbolic links for hdt.c32

```PowerShell
$filename = "hdt.c32"

Push-Location D:\RemoteInstall\Boot\x86

cmd /c mklink $filename $pxeLinuxPath\$filename

Pop-Location

Push-Location D:\RemoteInstall\Boot\x64

cmd /c mklink $filename $pxeLinuxPath\$filename

Pop-Location
```

### # Add "Hardware Detection Tool" menu option

```PowerShell
$pxeLinuxMenuFile = "$pxeLinuxPath\pxelinux.cfg\default"

Notepad $pxeLinuxMenuFile
```

---

File - **D:\\RemoteInstall\\Boot\\PXELinux\\pxelinux.cfg\\default**

```INI
...
#---
LABEL hdt
    MENU LABEL Run Hardware Detection Tool
    COM32 hdt.c32
...
```

---

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

### # Update custom (PXELinux) Windows Deployment Services files in TFS

#### # Sync files

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

$source = '\\TT-DEPLOY4\D$\RemoteInstall\Boot\PXELinux'
$destination = '.\Main\Windows Deployment Services\RemoteInstall\Boot\PXELinux'

robocopy $source $destination /E
```

#### # Add files to TFS

```PowerShell
$tf = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE" `
    + "\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\TF.exe"

& $tf add Main /r
```

#### Check-in files

---

## Add boot option - Reboot

---

**FOOBAR10** - Run as administrator

### Install reboot.c32

#### Extract file from syslinux-4.07.zip

Extract the following file to [\\\\TT-DEPLOY4\\C\$\\NotBackedUp\\Temp\\PXELinux](\\TT-DEPLOY4\C$\NotBackedUp\Temp\PXELinux):

- **com32/modules/reboot.c32**

---

```PowerShell
cls
```

#### # Copy reboot.c32 to PXELinux folder

```PowerShell
$filename = "reboot.c32"
$pxeLinuxPath = "D:\RemoteInstall\Boot\PXELinux"

robocopy C:\NotBackedUp\Temp\PXELinux $pxeLinuxPath $filename
```

#### # Configure symbolic links for reboot.c32

```PowerShell
Push-Location D:\RemoteInstall\Boot\x86

cmd /c mklink $filename $pxeLinuxPath\$filename

Pop-Location

Push-Location D:\RemoteInstall\Boot\x64

cmd /c mklink $filename $pxeLinuxPath\$filename

Pop-Location
```

### # Add "Reboot" menu option

```PowerShell
$pxeLinuxMenuFile = "$pxeLinuxPath\pxelinux.cfg\default"

Notepad $pxeLinuxMenuFile
```

---

File - **D:\\RemoteInstall\\Boot\\PXELinux\\pxelinux.cfg\\default**

```INI
...
#---
LABEL reboot
    MENU LABEL Reboot
    COM32 reboot.c32
...
```

---

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

### # Update custom (PXELinux) Windows Deployment Services files in TFS

#### # Sync files

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

$source = '\\TT-DEPLOY4\D$\RemoteInstall\Boot\PXELinux'
$destination = '.\Main\Windows Deployment Services\RemoteInstall\Boot\PXELinux'

robocopy $source $destination /E
```

#### # Add files to TFS

```PowerShell
$tf = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE" `
    + "\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\TF.exe"

& $tf add Main /r
```

#### Check-in files

---

## Add boot option - Power off

---

**FOOBAR10** - Run as administrator

### Install poweroff.com

#### Extract file from syslinux-4.07.zip

Extract the following file to [\\\\TT-DEPLOY4\\C\$\\NotBackedUp\\Temp\\PXELinux](\\TT-DEPLOY4\C$\NotBackedUp\Temp\PXELinux):

- **modules/poweroff.com**

---

```PowerShell
cls
```

#### # Copy poweroff.com to PXELinux folder

```PowerShell
$filename = "poweroff.com"
$pxeLinuxPath = "D:\RemoteInstall\Boot\PXELinux"

robocopy C:\NotBackedUp\Temp\PXELinux $pxeLinuxPath $filename
```

#### # Configure symbolic links for reboot.c32

```PowerShell
Push-Location D:\RemoteInstall\Boot\x86

cmd /c mklink $filename $pxeLinuxPath\$filename

Pop-Location

Push-Location D:\RemoteInstall\Boot\x64

cmd /c mklink $filename $pxeLinuxPath\$filename

Pop-Location
```

### # Add "Power off" menu option

```PowerShell
$pxeLinuxMenuFile = "$pxeLinuxPath\pxelinux.cfg\default"

Notepad $pxeLinuxMenuFile
```

---

File - **D:\\RemoteInstall\\Boot\\PXELinux\\pxelinux.cfg\\default**

```INI
...
#---
LABEL poweroff
    MENU LABEL Power off
    COMBOOT poweroff.com
...
```

---

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

### # Update custom (PXELinux) Windows Deployment Services files in TFS

#### # Sync files

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

$source = '\\TT-DEPLOY4\D$\RemoteInstall\Boot\PXELinux'
$destination = '.\Main\Windows Deployment Services\RemoteInstall\Boot\PXELinux'

robocopy $source $destination /E
```

#### # Add files to TFS

```PowerShell
$tf = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE" `
    + "\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\TF.exe"

& $tf add Main /r
```

#### Check-in files

---

```PowerShell
cls
```

## # Configure Linux boot/installation images

```PowerShell
$linuxImagesPath = "D:\RemoteInstall\Images\Linux"

mkdir $linuxImagesPath

Push-Location D:\RemoteInstall\Boot\x86\Images

cmd /c mklink /J Linux $linuxImagesPath

Pop-Location

Push-Location D:\RemoteInstall\Boot\x64\Images

cmd /c mklink /J Linux $linuxImagesPath

Pop-Location
```

## Add boot option - Memtest86+

---

**FOOBAR10** - Run as administrator

### Install Memtest86+

#### Download Memtest86+

[http://www.memtest.org/download/5.01/memtest86+-5.01.zip](http://www.memtest.org/download/5.01/memtest86+-5.01.zip)

#### Extract file

Extract the file to [\\\\TT-DEPLOY4\\C\$\\NotBackedUp\\Temp\\Images\\Linux](\\TT-DEPLOY4\C$\NotBackedUp\Temp\Images\Linux).

---

```PowerShell
cls
```

#### # Rename Memtest86 boot program

```PowerShell
Push-Location "C:\NotBackedUp\Temp\Images\Linux"

Rename-Item memtest86+-5.01.bin memtest86+

Pop-Location
```

#### # Copy memtest86+ to Linux images folder

```PowerShell
$filename = "memtest86+"
$linuxImagesPath = "D:\RemoteInstall\Images\Linux"

robocopy C:\NotBackedUp\Temp\Images\Linux $linuxImagesPath $filename
```

### # Add "Memtest86+" menu option

```PowerShell
$pxeLinuxMenuFile = "$pxeLinuxPath\pxelinux.cfg\default"

Notepad $pxeLinuxMenuFile
```

---

File - **D:\\RemoteInstall\\Boot\\PXELinux\\pxelinux.cfg\\default**

```INI
...
#---
LABEL memtest
    MENU LABEL Run Memtest86+
    LINUX /Images/Linux/memtest86+
...
```

---

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

### # Update custom (PXELinux) Windows Deployment Services files in TFS

#### # Sync files

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

$source = '\\TT-DEPLOY4\D$\RemoteInstall\Boot\PXELinux'
$destination = '.\Main\Windows Deployment Services\RemoteInstall\Boot\PXELinux'

robocopy $source $destination /E
```

#### Check-in files

---

## Add boot option - Parted Magic 2013_08_01

---

**FOOBAR10** - Run as administrator

### Install memdisk

#### Extract file from syslinux-4.07.zip

Extract the following file to [\\\\TT-DEPLOY4\\C\$\\NotBackedUp\\Temp\\PXELinux](\\TT-DEPLOY4\C$\NotBackedUp\Temp\PXELinux):

- **memdisk/memdisk**

---

```PowerShell
cls
```

#### # Copy memdisk to PXELinux folder

```PowerShell
$filename = "memdisk"
$pxeLinuxPath = "D:\RemoteInstall\Boot\PXELinux"

robocopy C:\NotBackedUp\Temp\PXELinux $pxeLinuxPath $filename
```

#### # Configure symbolic links for memdisk

```PowerShell
Push-Location D:\RemoteInstall\Boot\x86

cmd /c mklink $filename $pxeLinuxPath\$filename

Pop-Location

Push-Location D:\RemoteInstall\Boot\x64

cmd /c mklink $filename $pxeLinuxPath\$filename

Pop-Location
```

---

**FOOBAR10** - Run as administrator

### Install Parted Magic 2013_08_01

#### Download Parted Magic 2013_08_01

Download the ISO to [\\\\TT-DEPLOY4\\C\$\\NotBackedUp\\Temp\\Images\\Linux](\\TT-DEPLOY4\C$\NotBackedUp\Temp\Images\Linux).

---

```PowerShell
cls
```

#### # Copy ISO to Linux images folder

```PowerShell
$filename = "pmagic_2013_08_01.iso"
$linuxImagesPath = "D:\RemoteInstall\Images\Linux"

robocopy C:\NotBackedUp\Temp\Images\Linux $linuxImagesPath $filename
```

### # Add "Parted Magic 2013_08_01" menu option

```PowerShell
$pxeLinuxMenuFile = "$pxeLinuxPath\pxelinux.cfg\default"

Notepad $pxeLinuxMenuFile
```

---

File - **D:\\RemoteInstall\\Boot\\PXELinux\\pxelinux.cfg\\default**

```INI
...
#---
LABEL partedmagic
    MENU LABEL Parted Magic 2013_08_01
    KERNEL memdisk
    INITRD /Images/Linux/pmagic_2013_08_01.iso
    APPEND iso
...
```

---

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

### # Update custom (PXELinux) Windows Deployment Services files in TFS

#### # Sync files

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

$source = '\\TT-DEPLOY4\D$\RemoteInstall\Boot\PXELinux'
$destination = '.\Main\Windows Deployment Services\RemoteInstall\Boot\PXELinux'

robocopy $source $destination /E
```

#### # Add files to TFS

```PowerShell
$tf = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE" `
    + "\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\TF.exe"

& $tf add Main /r
```

#### Check-in files

---

## Add custom background to boot screen

### Copy image to PXELinux folder

---

**FOOBAR10** - Run as administrator

Copy background image to [\\\\TT-DEPLOY4\\C\$\\NotBackedUp\\Temp\\PXELinux](\\TT-DEPLOY4\C$\NotBackedUp\Temp\PXELinux):

- **Technology-Toolbox-Background-640x480.png**

---

```PowerShell
cls
$filename = "Technology-Toolbox-Background-640x480.png"
$pxeLinuxPath = "D:\RemoteInstall\Boot\PXELinux"

robocopy C:\NotBackedUp\Temp\PXELinux $pxeLinuxPath $filename
```

#### # Configure symbolic links for background image

```PowerShell
Push-Location D:\RemoteInstall\Boot\x86

cmd /c mklink $filename $pxeLinuxPath\$filename

Pop-Location

Push-Location D:\RemoteInstall\Boot\x64

cmd /c mklink $filename $pxeLinuxPath\$filename

Pop-Location
```

### # Configure background image in PXELinux menu

```PowerShell
$pxeLinuxMenuFile = "$pxeLinuxPath\pxelinux.cfg\default"

Notepad $pxeLinuxMenuFile
```

---

File - **D:\\RemoteInstall\\Boot\\PXELinux\\pxelinux.cfg\\default**

```INI
...
#---
LABEL partedmagic
    MENU LABEL Parted Magic 2013_08_01
    KERNEL memdisk
    INITRD /Images/Linux/pmagic_2013_08_01.iso
    APPEND iso
...
```

---

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

### # Update custom (PXELinux) Windows Deployment Services files in TFS

#### # Sync files

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

$source = '\\TT-DEPLOY4\D$\RemoteInstall\Boot\PXELinux'
$destination = '.\Main\Windows Deployment Services\RemoteInstall\Boot\PXELinux'

robocopy $source $destination /E
```

#### # Add files to TFS

```PowerShell
$tf = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE" `
    + "\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\TF.exe"

& $tf add Main /r
```

#### Check-in files

---

## Install SCOM 2016 agent (using Operations Console)

## Configure virtual machine

---

**FOOBAR10** - Run as administrator

```PowerShell
cls
```

### # Make virtual machine highly available

```PowerShell
$vmName = "TT-DEPLOY4"

$vm = Get-SCVirtualMachine -Name $vmName

$vmHost = Get-SCVMHost -ID $vm.HostId

Move-SCVirtualMachine `
    -VM $vm `
    -VMHost $vmHost `
    -HighlyAvailable $true `
    -Path "\\TT-SOFS01.corp.technologytoolbox.com\VM-Storage-Silver" `
    -UseDiffDiskOptimization

Start-SCVirtualMachine -VM $vmName
```

```PowerShell
cls
```

### # Enable Dynamic Memory

```PowerShell
Stop-SCVirtualMachine -VM $vmName

Set-SCVirtualMachine `
    -VM $vmName `
    -MemoryMB 2048 `
    -DynamicMemoryEnabled $true `
    -DynamicMemoryMaximumMB 2048

Start-SCVirtualMachine -VM $vmName
```

---

```PowerShell
cls
```

## # Enter a product key and activate Windows

```PowerShell
slmgr /ipk {product key}
```

**Note:** When notified that the product key was set successfully, click **OK**.

```Console
slmgr /ato
```

```Console
cls
```

## Build baseline images

---

**TT-HV02A** / **TT-HV02B** / **TT-HV02C**

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows 7 Ultimate (x86) - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\TT-FS01\Products\Microsoft\MDT-Build-x86.iso `
    -SwitchName "Embedded Team Switch" `
    -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows 7 Ultimate (x64) - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\TT-FS01\Products\Microsoft\MDT-Build-x86.iso `
    -SwitchName "Embedded Team Switch" `
    -VhdSize 40GB `
    -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows Server 2008 R2 - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\TT-FS01\Products\Microsoft\MDT-Build-x86.iso `
    -SwitchName "Embedded Team Switch" `
    -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows 8.1 Enterprise (x64) - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\TT-FS01\Products\Microsoft\MDT-Build-x86.iso `
    -SwitchName "Embedded Team Switch" `
    -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows Server 2012 R2 Standard - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\TT-FS01\Products\Microsoft\MDT-Build-x86.iso `
    -SwitchName "Embedded Team Switch" `
    -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image - "SharePoint Server 2013 - Development"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\TT-FS01\Products\Microsoft\MDT-Build-x86.iso `
    -SwitchName "Embedded Team Switch" `
    -VhdSize 50GB `
    -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows 10 Enterprise (x64) - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\TT-FS01\Products\Microsoft\MDT-Build-x86.iso `
    -SwitchName "Embedded Team Switch" `
    -VhdSize 40GB `
    -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows Server 2016 - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\TT-FS01\Products\Microsoft\MDT-Build-x86.iso `
    -SwitchName "Embedded Team Switch" `
    -VhdSize 40GB `
    -Force
```

---

```PowerShell
cls
```

## # Update MDT production deployment images

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure\Main\Scripts

& '.\Update Deployment Images.ps1'
```

---

## Import new version (December 2017) of Windows 10

```PowerShell
Add-PSSnapin Microsoft.BDD.PSSnapIn

New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root \\TT-FS01\MDT-Build$
```

### # Import operating system - "Windows 10 Enterprise, Version 1709 (x64)"

#### # Mount the installation image

```PowerShell
$imagePath = "\\TT-FS01\Products\Microsoft\Windows 10" `
  + "\en_windows_10_multi-edition_vl_version_1709_updated_dec_2017_x64_dvd_100406172.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$sourcePath = $imageDriveLetter + ":\"
```

#### # Import operating system

```PowerShell
$destinationFolder = "W10Ent-1709-Dec-2017-x64"

$os = Import-MDTOperatingSystem `
    -Path "DS001:\Operating Systems\Windows 10" `
    -SourcePath $sourcePath `
    -DestinationFolder $destinationFolder
```

#### # Dismount the installation image

```PowerShell
Dismount-DiskImage -ImagePath $imagePath
```

### Modify task sequence to use Windows 10 Enterprise, Version 1709

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    \\TT-FS01\MDT-Build$ '.\Main\MDT-Build$'
```

#### # Sync files

```PowerShell
robocopy \\TT-FS01\MDT-Build$ Main\MDT-Build$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Packages Servicing Tools
```

#### Check-in files

---

## Import new version (February 2018) of Windows Server 2016

```PowerShell
Add-PSSnapin Microsoft.BDD.PSSnapIn

New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root \\TT-FS01\MDT-Build$
```

### # Import operating system - "Windows Server 2016"

#### # Mount the installation image

```PowerShell
$imagePath = "\\TT-FS01\Products\Microsoft\Windows Server 2016" `
    + "\en_windows_server_2016_updated_feb_2018_x64_dvd_11636692.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$sourcePath = $imageDriveLetter + ":\"
```

#### # Import operating system

```PowerShell
$destinationFolder = "WS2016-Feb-2018"

$os = Import-MDTOperatingSystem `
    -Path "DS001:\Operating Systems\Windows Server 2016" `
    -SourcePath $sourcePath `
    -DestinationFolder $destinationFolder
```

#### # Dismount the installation image

```PowerShell
Dismount-DiskImage -ImagePath $imagePath
```

### Modify task sequence to use latest version of Windows Server 2016

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    \\TT-FS01\MDT-Build$ '.\Main\MDT-Build$'
```

#### # Sync files

```PowerShell
robocopy \\TT-FS01\MDT-Build$ Main\MDT-Build$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Packages Servicing Tools
```

#### Check-in files

---

## Import new version (March 2018) of Windows 10

```PowerShell
Add-PSSnapin Microsoft.BDD.PSSnapIn

New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root \\TT-FS01\MDT-Build$
```

### # Import operating system - "Windows 10 Enterprise, Version 1803 (x64)"

#### # Mount the installation image

```PowerShell
$imagePath = "\\TT-FS01\Products\Microsoft\Windows 10" `
  + "\en_windows_10_business_editions_version_1803_updated_march_2018_x64_dvd_12063333.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$sourcePath = $imageDriveLetter + ":\"
```

#### # Import operating system

```PowerShell
$destinationFolder = "W10Ent-1803-Mar-2018-x64"

$os = Import-MDTOperatingSystem `
    -Path "DS001:\Operating Systems\Windows 10" `
    -SourcePath $sourcePath `
    -DestinationFolder $destinationFolder
```

#### # Dismount the installation image

```PowerShell
Dismount-DiskImage -ImagePath $imagePath
```

### Modify task sequence to use Windows 10 Enterprise, Version 1803

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    \\TT-FS01\MDT-Build$ '.\Main\MDT-Build$'
```

#### # Sync files

```PowerShell
robocopy \\TT-FS01\MDT-Build$ Main\MDT-Build$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Packages Servicing Tools
```

#### Check-in files

---

## Create additional applications in MDT deployment share

```PowerShell
Add-PSSnapin Microsoft.BDD.PSSnapIn

New-PSDrive -Name "DS002" -PSProvider MDTProvider -Root \\TT-FS01\MDT-DEPLOY$
```

```PowerShell
cls
```

### # Create task sequence to test installing applications

```PowerShell
New-Item -Path "DS002:\Task Sequences" -Name "Other" -ItemType Folder

Import-MDTTaskSequence `
    -Path "DS002:\Task Sequences\Other" `
    -Name "Install Applications" `
    -Template "Custom.xml" `
    -ID "Install-Apps" `
    -Version "1.0"
```

```PowerShell
cls
```

### # Create application: Remote Server Administration Tools for Windows 10

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft" `
    + "\Remote Server Administration Tools for Windows 10" `
    + "\WindowsTH-RSAT_WS2016-x64.msu"

$appName = "Remote Server Administration Tools for Windows 10"
$appShortName = "RSAT_WS2016-x64"
$commandLine = 'wusa.exe "' + $installerPath + '" /quiet /norestart'

Import-MDTApplication `
    -Path "DS002:\Applications\Microsoft" `
    -Name $appName `
    -ShortName $appShortName `
    -NoSource `
    -CommandLine $commandLine
```

### # Create application: Microsoft System CLR Types for SQL Server 2012

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\SQL Server 2012\Feature Pack" `
    + "\System CLR Types for SQL Server 2012\x64\SQLSysClrTypes.msi"

$appName = "Microsoft System CLR Types for SQL Server 2012"
$appShortName = "SQL2012-SysClrTypes"
$commandLine = 'msiexec.exe /i "' + $installerPath + '" /qr'

Import-MDTApplication `
    -Path "DS002:\Applications\Microsoft" `
    -Name $appName `
    -ShortName $appShortName `
    -NoSource `
    -CommandLine $commandLine
```

### # Create application: Microsoft Report Viewer 2012

```PowerShell
$installerPath = '\\TT-FS01\Products\Microsoft\Report Viewer 2012 Runtime' `
    + '\ReportViewer.msi'

$appName = "Microsoft Report Viewer 2012"
$appShortName = "Report-Viewer-2012"
$commandLine = 'msiexec.exe /i "' + $installerPath + '" /qr'

Import-MDTApplication `
    -Path "DS002:\Applications\Microsoft" `
    -Name $appName `
    -ShortName $appShortName `
    -NoSource `
    -CommandLine $commandLine `
    -Hide "True"
```

### # Create application bundle: Microsoft Report Viewer 2012 (bundle)

#### # Add application bundle - Microsoft Report Viewer 2012 (bundle)

```PowerShell
$appName = "Microsoft Report Viewer 2012 (bundle)"
$appShortName = "Report-Viewer-2012-bundle"

Import-MDTApplication `
    -Path "DS002:\Applications\Microsoft" `
    -Name $appName `
    -ShortName $appShortName `
    -Bundle
```

#### # Configure application bundle - Microsoft Report Viewer 2012 (bundle)

1. Open **Deployment Workbench**, expand **Deployment Shares / MDT Deployment ([\\\\TT-FS01\\MDT-Deploy\$](\\TT-FS01\MDT-Deploy$)) / Applications / Microsoft**, right-click **Microsoft Report Viewer 2012 (bundle)**, and click **Properties**.
2. In the **Microsoft Report Viewer 2012 (bundle) Properties** window:
   1. On the **Dependencies** tab:
      1. Add the following applications:
         1. **Microsoft System CLR Types for SQL Server 2012**
         2. **Microsoft Report Viewer 2012**
      2. Ensure the applications in the previous step are listed in the specified order. Use the **Up** or **Down** buttons to reorder the applications as necessary.
   2. Click **OK**.

```PowerShell
cls
```

### # Create application: SQL Server 2016 Management Studio

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\SQL Server 2016" `
    + "\SSMS-Setup-ENU-13.0.16106.4.exe"

$appName = "SQL Server 2016 Management Studio"
$appShortName = "SSMS-2016"
$commandLine = '"' + $installerPath + '" /install /quiet /norestart'

Import-MDTApplication `
    -Path "DS002:\Applications\Microsoft" `
    -Name $appName `
    -ShortName $appShortName `
    -NoSource `
    -CommandLine $commandLine
```

### # Create application: SQL Server 2017 Management Studio

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\SQL Server 2017" `
    + "\SSMS-Setup-ENU-14.0.17254.0.exe"

$appName = "SQL Server 2017 Management Studio"
$appShortName = "SSMS-2017"
$commandLine = '"' + $installerPath + '" /install /quiet /norestart'

Import-MDTApplication `
    -Path "DS002:\Applications\Microsoft" `
    -Name $appName `
    -ShortName $appShortName `
    -NoSource `
    -CommandLine $commandLine
```

### # Create applications for System Center 2016 management tools

#### # Create applications for SCOM 2016 Operations console

##### # Create application: Microsoft System CLR Types for SQL Server 2014

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\System Center 2016" `
    + "\Microsoft CLR Types for SQL Server 2014\SQLSysClrTypes.msi"

$appName = "Microsoft System CLR Types for SQL Server 2014"
$appShortName = "SQL2014-SysClrTypes"
$commandLine = 'msiexec.exe /i "' + $installerPath + '" /qr'

Import-MDTApplication `
    -Path "DS002:\Applications\Microsoft" `
    -Name $appName `
    -ShortName $appShortName `
    -NoSource `
    -CommandLine $commandLine
```

##### # Create application: Microsoft Report Viewer 2015

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\System Center 2016" `
    + "\Microsoft Report Viewer 2015 Runtime\ReportViewer.msi"

$appName = "Microsoft Report Viewer 2015"
$appShortName = "Report-Viewer-2015"
$commandLine = 'msiexec.exe /i "' + $installerPath + '" /qr'

Import-MDTApplication `
    -Path "DS002:\Applications\Microsoft" `
    -Name $appName `
    -ShortName $appShortName `
    -NoSource `
    -CommandLine $commandLine `
    -Hide "True"
```

##### # Create application: System Center Operations Manager 2016 - Operations console

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\System Center 2016\SCOM\Setup.exe"

$arguments = "/silent /install /components:OMConsole" `
    + " /AcceptEndUserLicenseAgreement:1 /EnableErrorReporting:Always" `
    + " /SendCEIPReports:1 /UseMicrosoftUpdate:1"

$appName = "System Center Operations Manager 2016 - Operations console"
$appShortName = "SCOM-2016-console"
$commandLine = '"' + $installerPath + '" ' + $arguments

Import-MDTApplication `
    -Path "DS002:\Applications\Microsoft" `
    -Name $appName `
    -ShortName $appShortName `
    -NoSource `
    -CommandLine $commandLine `
    -Hide "True"
```

#### # Create application bundle: System Center Operations Manager 2016 - Operations console (bundle)

##### # Add application bundle - System Center Operations Manager 2016 - Operations console (bundle)

```PowerShell
$appName = "System Center Operations Manager 2016 - Operations console (bundle)"
$appShortName = "SCOM-2016-console-bundle"

Import-MDTApplication `
    -Path "DS002:\Applications\Microsoft" `
    -Name $appName `
    -ShortName $appShortName `
    -Bundle
```

##### # Configure application bundle - System Center Operations Manager 2016 - Operations console (bundle)

1. Open **Deployment Workbench**, expand **Deployment Shares / MDT Deployment ([\\\\TT-FS01\\MDT-Deploy\$](\\TT-FS01\MDT-Deploy$)) / Applications / Microsoft**, right-click **System Center Operations Manager 2016 - Operations console (bundle)**, and click **Properties**.
2. In the **System Center Operations Manager 2016 - Operations console (bundle) Properties** window:
   1. On the **Dependencies** tab:
      1. Add the following applications:
         1. **Microsoft System CLR Types for SQL Server 2014**
         2. **Microsoft Report Viewer 2015**
         3. **System Center Operations Manager 2016 - Operations console**
      2. Ensure the applications in the previous step are listed in the specified order. Use the **Up** or **Down** buttons to reorder the applications as necessary.
   2. Click **OK**.

```PowerShell
cls
```

#### # Create applications for DPM Central Console

##### # Create application: Visual C++ 2008 Redistributable

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\System Center 2016\DPM\Redist\vcredist" `
    + "\vcredist2008_x64.exe"

$appName = "Visual C++ 2008 Redistributable"
$appShortName = "vcredist2008_x64"
$commandLine = '"' + $installerPath + '" /q'

Import-MDTApplication `
    -Path "DS002:\Applications\Microsoft" `
    -Name $appName `
    -ShortName $appShortName `
    -NoSource `
    -CommandLine $commandLine
```

##### # Create application: Visual C++ 2010 Redistributable

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\System Center 2016\DPM\Redist\vcredist" `
    + "\vcredist2010_x64.exe"

$appName = "Visual C++ 2010 Redistributable"
$appShortName = "vcredist2010_x64"
$commandLine = '"' + $installerPath + '" /q'

Import-MDTApplication `
    -Path "DS002:\Applications\Microsoft" `
    -Name $appName `
    -ShortName $appShortName `
    -NoSource `
    -CommandLine $commandLine
```

##### # Create application: System Center Data Protection Manager 2016 - Central Console

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\System Center 2016\DPM\Setup.exe"
$arguments = '/i /cc /client'

$appName = "System Center Data Protection Manager 2016 - Central Console"
$appShortName = "DPM-2016-console"
$commandLine = '"' + $installerPath + '" ' + $arguments

Import-MDTApplication `
    -Path "DS002:\Applications\Microsoft" `
    -Name $appName `
    -ShortName $appShortName `
    -NoSource `
    -CommandLine $commandLine `
    -Hide "True"
```

#### # Create application bundle: System Center Data Protection Manager 2016 - Central Console (bundle)

##### # Add application bundle - System Center Data Protection Manager 2016 - Central Console (bundle)

```PowerShell
$appName = "System Center Data Protection Manager 2016 - Central Console (bundle)"
$appShortName = "DPM-2016-console-bundle"

Import-MDTApplication `
    -Path "DS002:\Applications\Microsoft" `
    -Name $appName `
    -ShortName $appShortName `
    -Bundle
```

##### # Configure application bundle - System Center Data Protection Manager 2016 - Central Console (bundle)

1. Open **Deployment Workbench**, expand **Deployment Shares / MDT Deployment ([\\\\TT-FS01\\MDT-Deploy\$](\\TT-FS01\MDT-Deploy$)) / Applications / Microsoft**, right-click **System Center Data Protection Manager 2016 - Central Console (bundle)**, and click **Properties**.
2. In the **System Center Data Protection Manager 2016 - Central Console (bundle) Properties** window:
   1. On the **Dependencies** tab:
      1. Add the following applications:
         1. **Visual C++ 2008 Redistributable**
         2. **Visual C++ 2010 Redistributable**
         3. **System Center Data Protection Manager 2016 - Central Console**
      2. Ensure the applications in the previous step are listed in the specified order. Use the **Up** or **Down** buttons to reorder the applications as necessary.
   2. Click **OK**.

```PowerShell
cls
```

##### # Create application: System Center Virtual Machine Manager 2016 - Console

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\System Center 2016\VMM\setup.exe"
$arguments = '/client /i /IACCEPTSCEULA'

$appName = "System Center Virtual Machine Manager 2016 - Console"
$appShortName = "VMM-2016-console"
$commandLine = '"' + $installerPath + '" ' + $arguments

Import-MDTApplication `
    -Path "DS002:\Applications\Microsoft" `
    -Name $appName `
    -ShortName $appShortName `
    -NoSource `
    -CommandLine $commandLine
```

##### # Create application: System Center 2012 R2 Configuration Manager Toolkit

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\System Center 2012 R2" `
    + "\System Center 2012 R2 Configuration Manager Toolkit" `
    + "\ConfigMgrTools.msi"

$appName = "System Center 2012 R2 Configuration Manager Toolkit"
$appShortName = "ConfigMgrTools"
$commandLine = 'msiexec.exe /i "' + $installerPath + '" /qr'

Import-MDTApplication `
    -Path "DS002:\Applications\Microsoft" `
    -Name $appName `
    -ShortName $appShortName `
    -NoSource `
    -CommandLine $commandLine
```

---

## Baseline Windows 10 VM

```Console
cls
```

### REM Test application installation

```Console
cscript \\TT-FS01\MDT-Deploy$\Scripts\LiteTouch.vbs
```

---

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    \\TT-FS01\MDT-Deploy$ '.\Main\MDT-Deploy$'
```

#### # Sync files

```PowerShell
robocopy \\TT-FS01\MDT-Deploy$ Main\MDT-Deploy$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Packages Servicing
```

#### Check-in files

---

## Upgrade Chrome, Firefox, and Thunderbird to latest versions

### Download latest versions of Chrome, Firefox, and Thunderbird

### Update applications in MDT Deployment share

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    \\TT-FS01\MDT-Deploy$ '.\Main\MDT-Deploy$'
```

#### # Sync files

```PowerShell
robocopy \\TT-FS01\MDT-Deploy$ Main\MDT-Deploy$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools
```

#### Check-in files

---

---

**FOOBAR16** - Run as administrator

```PowerShell
cls
```

## # Move VM to new Production VM network

```PowerShell
$vmName = "TT-DEPLOY4"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Production VM Network"
$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"
$ipPool = Get-SCStaticIPAddressPool -Name "Production-15 Address Pool"

Stop-SCVirtualMachine $vmName

$macAddress = Grant-SCMACAddress `
    -MACAddressPool $macAddressPool `
    -Description $vmName `
    -VirtualNetworkAdapter $networkAdapter

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -MACAddressType Static `
    -MACAddress $macAddress `
    -IPv4AddressPools $ipPool `
    -IPv4AddressType Static

Start-SCVirtualMachine $vmName
```

---

---

**FOOBAR16** - Run as administrator

```PowerShell
cls
```

## # Move VM to new Management VM network

```PowerShell
$vmName = "TT-DEPLOY4"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Management VM Network"
$ipAddressPool = Get-SCStaticIPAddressPool -Name "Management-30 Address Pool"

Stop-SCVirtualMachine $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -IPv4AddressPools $ipAddressPool `
    -IPv4AddressType Static

Start-SCVirtualMachine $vmName
```

---

## Issue - PXE boot only works from Management VLAN

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DD/83C753A25F16B02A79BC6A8CB0200AB63E5277DD.png)

Screen clipping taken: 8/6/2018 5:56 PM

**PXEClient, dhcp options 60, 66 and 67, what are they for? Can I use PXE without it ?**\
From <[https://www.experts-exchange.com/articles/2978/PXEClient-dhcp-options-60-66-and-67-what-are-they-for-Can-I-use-PXE-without-it.html](https://www.experts-exchange.com/articles/2978/PXEClient-dhcp-options-60-66-and-67-what-are-they-for-Can-I-use-PXE-without-it.html)>

**PXE Boot files in RemoteInstall folder explained (UEFI)**\
From <[http://henkhoogendoorn.blogspot.com/2014/03/pxe-boot-files-in-remoteinstall-folder.html](http://henkhoogendoorn.blogspot.com/2014/03/pxe-boot-files-in-remoteinstall-folder.html)>

## Import new version (July 2018) of Windows 10

```PowerShell
Add-PSSnapin Microsoft.BDD.PSSnapIn

New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root \\TT-FS01\MDT-Build$
```

### # Import operating system - "Windows 10 Enterprise, Version 1803 (x64)"

#### # Mount the installation image

```PowerShell
$imagePath = "\\TT-FS01\Products\Microsoft\Windows 10" `
  + "\en_windows_10_business_edition_version_1803_updated_jul_2018_x64_dvd_12612769.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$sourcePath = $imageDriveLetter + ":\"
```

#### # Import operating system

```PowerShell
$destinationFolder = "W10Ent-1803-Jul-2018-x64"

$os = Import-MDTOperatingSystem `
    -Path "DS001:\Operating Systems\Windows 10" `
    -SourcePath $sourcePath `
    -DestinationFolder $destinationFolder
```

#### # Dismount the installation image

```PowerShell
Dismount-DiskImage -ImagePath $imagePath
```

### Modify task sequence to use new version of Windows 10 Enterprise, Version 1803

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    \\TT-FS01\MDT-Build$ '.\Main\MDT-Build$'
```

#### # Sync files

```PowerShell
robocopy \\TT-FS01\MDT-Build$ Main\MDT-Build$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Packages Servicing Tools
```

#### Check-in files

---

## # Import new version (September 2018) of Windows 10

```PowerShell
Add-PSSnapin Microsoft.BDD.PSSnapIn

New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root \\TT-FS01\MDT-Build$
```

### # Import operating system - "Windows 10 Enterprise, Version 1809 (x64)"

#### # Mount the installation image

```PowerShell
$imagePath = "\\TT-FS01\Products\Microsoft\Windows 10" `
  + "\en_windows_10_business_edition_version_1809_updated_sept_2018_x64_dvd_d57f2c0d.iso"

$imageDriveLetter = Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume |
    select -ExpandProperty DriveLetter

$sourcePath = $imageDriveLetter + ":\"
```

#### # Import operating system

```PowerShell
$destinationFolder = "W10Ent-1809-Sep-2018-x64"

Import-MDTOperatingSystem `
    -Path "DS001:\Operating Systems\Windows 10" `
    -SourcePath $sourcePath `
    -DestinationFolder $destinationFolder
```

```PowerShell
cls
```

#### # Dismount the installation image

```PowerShell
Dismount-DiskImage -ImagePath $imagePath
```

### Modify task sequence to use new version of Windows 10 Enterprise, Version 1809

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    \\TT-FS01\MDT-Build$ '.\Main\MDT-Build$'
```

#### # Sync files

```PowerShell
robocopy \\TT-FS01\MDT-Build$ Main\MDT-Build$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Packages Servicing Tools
```

#### Check-in files

---

## Add application - Office Professional Plus 2019 (x64)

### Reference

**Use the Office offline installer**\
From <[https://support.office.com/en-us/article/use-the-office-offline-installer-f0a85fe7-118f-41cb-a791-d59cef96ad1c](https://support.office.com/en-us/article/use-the-office-offline-installer-f0a85fe7-118f-41cb-a791-d59cef96ad1c)>

---

**WIN10-DEV1** - Run as administrator

```PowerShell
cls
```

### # Download and install the Office Deployment Tool

```PowerShell
mkdir C:\ODT
```

Download the Office Deployment Tool:

**Office Deployment Tool**\
From <[https://www.microsoft.com/en-us/download/confirmation.aspx?id=49117](https://www.microsoft.com/en-us/download/confirmation.aspx?id=49117)>

Run the Office Deployment Tool and extract the files to the **C:\\ODT** folder.

```PowerShell
cls
```

### # Download Office offline installation files

```PowerShell
Push-Location C:\ODT

.\setup.exe /download configuration-Office365-x64.xml

Pop-Location
```

```PowerShell
cls
```

### # Configure installation settings for Office 2019

```PowerShell
Notepad C:\ODT\configuration-Office365-x64.xml
```

---

File - **C:\\ODT\\configuration-Office365-x64.xml**

```XML
<Configuration>

  <Add OfficeClientEdition="64" Channel="Monthly">
    <Product ID="O365ProPlusRetail">
      <Language ID="en-us" />
    </Product>
    <Product ID="VisioProRetail">
      <Language ID="en-us" />
    </Product>
  </Add>

  <!--  <Updates Enabled="TRUE" Channel="Monthly" /> -->

  <Display Level="None" AcceptEULA="TRUE" />

  <!--  <Property Name="AUTOACTIVATE" Value="1" />  -->

</Configuration>
```

---

```PowerShell
cls
```

### # Copy installation files to MDT Applications folder

```PowerShell
robocopy C:\ODT '\\TT-FS01\MDT-Build$\Applications\Office2019ProPlus-x64' /E /MOV
```

---

```PowerShell
cls
```

### # Create application - "Office Professional Plus 2019 (x64)"

```PowerShell
$appName = "Office Professional Plus 2019 (x64)"
$appShortName = "Office2019ProPlus-x64"
$appSetupFolder = $appShortName
$commandLine = "setup.exe /configure configuration-Office365-x64.xml"

Import-MDTApplication `
    -Path "DS001:\Applications\Microsoft" `
    -Name $appName `
    -ShortName $appShortName `
    -NoSource `
    -CommandLine $commandLine `
    -WorkingDirectory ".\Applications\$appSetupFolder"
```

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

### # Update files in TFS

#### # Sync files

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

$source = '\\TT-FS01\MDT-Build$'
$destination = '.\Main\MDT-Build$'

robocopy $source $destination /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools

robocopy `
    "$source\Applications\Office2016ProPlus-x86" `
    "$destination\Applications\Office2016ProPlus-x86" `
    configuration.xml
```

#### # Add files to TFS

```PowerShell
$tf = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE" `
    + "\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\TF.exe"

& $tf add Main /r
```

#### Check-in files

---

## # Import new version (December 2018) of Windows 10

```PowerShell
Add-PSSnapin Microsoft.BDD.PSSnapIn

New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root \\TT-FS01\MDT-Build$
```

### # Import operating system - "Windows 10 Enterprise, Version 1809 (x64)"

#### # Mount the installation image

```PowerShell
$imagePath = "\\TT-FS01\Products\Microsoft\Windows 10" `
  + "\en_windows_10_business_editions_version_1809_updated_dec_2018_x64_dvd_f03937a3.iso"

$imageDriveLetter = Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume |
    select -ExpandProperty DriveLetter

$sourcePath = $imageDriveLetter + ":\"
```

#### # Import operating system

```PowerShell
$destinationFolder = "W10Ent-1809-Dec-2018-x64"

Import-MDTOperatingSystem `
    -Path "DS001:\Operating Systems\Windows 10" `
    -SourcePath $sourcePath `
    -DestinationFolder $destinationFolder
```

```PowerShell
cls
```

#### # Dismount the installation image

```PowerShell
Dismount-DiskImage -ImagePath $imagePath
```

### Modify task sequence to use new version of Windows 10 Enterprise, Version 1809

---

**STORM** - Run as administrator

```PowerShell
cls
```

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    \\TT-FS01\MDT-Build$ '.\Main\MDT-Build$'
```

#### # Sync files

```PowerShell
robocopy \\TT-FS01\MDT-Build$ Main\MDT-Build$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Packages Servicing Tools
```

#### Check-in files

---

## Upgrade Chrome, Firefox, and Thunderbird to latest versions

### Download latest versions of Chrome, Firefox, and Thunderbird

### Update applications in MDT Deployment share

---

**STORM** - Run as administrator

```PowerShell
cls
```

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    \\TT-FS01\MDT-Deploy$ '.\Main\MDT-Deploy$'
```

#### # Sync files

```PowerShell
robocopy \\TT-FS01\MDT-Deploy$ Main\MDT-Deploy$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools
```

#### Check-in files

---

## Upgrade SQL Server 2017 Management Studio to latest version

### Download latest version of SSMS 2017

### Update application in MDT Deployment share

---

**STORM** - Run as administrator

```PowerShell
cls
```

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    \\TT-FS01\MDT-Deploy$ '.\Main\MDT-Deploy$'
```

#### # Sync files

```PowerShell
robocopy \\TT-FS01\MDT-Deploy$ Main\MDT-Deploy$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools
```

#### Check-in files

---

## Remove MDT application - RSAT for Windows 10

### Remove application in MDT Deployment share

---

**STORM** - Run as administrator

```PowerShell
cls
```

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    \\TT-FS01\MDT-Deploy$ '.\Main\MDT-Deploy$'
```

#### # Sync files

```PowerShell
robocopy \\TT-FS01\MDT-Deploy$ Main\MDT-Deploy$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools
```

#### Check-in files

---

## Add application - Microsoft Security Essentials

```PowerShell
Add-PSSnapin Microsoft.BDD.PSSnapIn

New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root \\TT-FS01\MDT-Build$
```

```PowerShell
cls
```

### # Create application - "Microsoft Security Essentials (x64)"

```PowerShell
$appName = "Microsoft Security Essentials (x64)"
$appShortName = "MSE-x64"
$appSetupFolder = $appShortName
$appSourcePath = "\\TT-FS01\Products\Microsoft\Security Essentials\Windows 7 (x64)"
$commandLine = "MSEInstall.exe /s /runwgacheck /o"

Import-MDTApplication `
    -Path "DS001:\Applications\Microsoft" `
    -Name $appName `
    -ShortName $appShortName `
    -ApplicationSourcePath $appSourcePath `
    -DestinationFolder $appSetupFolder `
    -CommandLine $commandLine `
    -WorkingDirectory ".\Applications\$appSetupFolder"
```

```PowerShell
cls
```

### # Create application - "Microsoft Security Essentials (x86)"

```PowerShell
$appName = "Microsoft Security Essentials (x86)"
$appShortName = "MSE-x86"
$appSetupFolder = $appShortName
$appSourcePath = "\\TT-FS01\Products\Microsoft\Security Essentials\Windows 7 (x86)"
$commandLine = "MSEInstall.exe /s /runwgacheck /o"

Import-MDTApplication `
    -Path "DS001:\Applications\Microsoft" `
    -Name $appName `
    -ShortName $appShortName `
    -ApplicationSourcePath $appSourcePath `
    -DestinationFolder $appSetupFolder `
    -CommandLine $commandLine `
    -WorkingDirectory ".\Applications\$appSetupFolder"
```

---

**STORM** - Run as administrator

```PowerShell
cls
```

### # Update files in TFS

#### # Sync files

```PowerShell
cd C:\NotBackedUp\techtoolbox\Infrastructure

$source = '\\TT-FS01\MDT-Build$'
$destination = '.\Main\MDT-Build$'

robocopy $source $destination /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools
```

#### # Add files to TFS

```PowerShell
$tf = "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\Common7\IDE" `
    + "\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\TF.exe"

& $tf add Main /r
```

#### Check-in files

---

## Issue - Error installing operating system using WDS

### Symptom

The network boot starts but stalls during the "Loading files" step. A short time later, the following error message is displayed:

Status: 0xc0000001\
Info: A required device isn't connected or can't be accessed.

### Solution

This is due to a patch installed from Windows Update (KB4489882).

The solution is to disable **Variable Window Extension** in Windows Deployment Services:

```Console
wdsutil /Set-TransportServer /EnableTftpVariableWindowExtension:No

Restart-Service WDSServer
```

1. Open the **Windows Deployment Services** console.
2. Expand the **Servers** node, right-click the server name, and click **Properties**.
3. In the **Properties** window:
   1. Select the **TFTP** tab.
   2. In the **Variable Window Extension** section, clear the **Enable Variable Window Extension** checkbox.
   3. Click **OK**.
4. Restart the server.

### References

**Windows Update (KB4489882) broke WDS and MDT**\
From <[https://social.technet.microsoft.com/Forums/en-US/46e30b31-590e-47b4-b123-faf3776cfe74/windows-update-kb4489882-broke-wds-and-mdt?forum=mdt](https://social.technet.microsoft.com/Forums/en-US/46e30b31-590e-47b4-b123-faf3776cfe74/windows-update-kb4489882-broke-wds-and-mdt?forum=mdt)>

After installing this update, there may be issues using the Preboot Execution Environment (PXE) to start a device from a Windows Deployment Services (WDS) server configured to use Variable Window Extension. This may cause the connection to the WDS server to terminate prematurely while downloading the image.

To mitigate the issue, disable the Variable Window Extension on WDS server using one of the following options:

Open an Administrator Command prompt and type the following:

Wdsutil /Set-TransportServer /EnableTftpVariableWindowExtension:No

Restart the WDSServer service after disabling the Variable Window Extension.

**March 12, 2019—KB4489882 (OS Build 14393.2848)**\
From <[https://support.microsoft.com/en-us/help/4489882/windows-10-update-kb4489882](https://support.microsoft.com/en-us/help/4489882/windows-10-update-kb4489882)>

## Issue - Not enough free space to install patches using Windows Update

8.5 GB of free space, but unable to install **2019-05 Cumulative Update for Windows Server 2016 for x64-based Systems (KB4494440)**.

### Expand C: volume

---

**FOOBAR18** - Run as administrator

```PowerShell
cls
```

#### # Increase size of VHD

```PowerShell
$vmName = "TT-DEPLOY4"

# Note: VHD is stored on Cluster Shared Volume -- so expand using VMM cmdlet

Stop-SCVirtualMachine -VM $vmName

Get-SCVirtualDiskDrive -VM $vmName |
    where { $_.BusType -eq "SCSI" -and $_.Bus -eq 0 -and $_.Lun -eq 0 } |
    Expand-SCVirtualDiskDrive -VirtualHardDiskSizeGB 35

Start-SCVirtualMachine -VM $vmName
```

---

```PowerShell
cls
```

#### # Extend partition

```PowerShell
$driveLetter = "C"

$partition = Get-Partition -DriveLetter $driveLetter |
    where { $_.DiskNumber -ne $null }

$size = (Get-PartitionSupportedSize `
    -DiskNumber $partition.DiskNumber `
    -PartitionNumber $partition.PartitionNumber)

Resize-Partition `
    -DiskNumber $partition.DiskNumber `
    -PartitionNumber $partition.PartitionNumber `
    -Size $size.SizeMax
```

```PowerShell
cls
```

## # Import new version (June 2019) of Windows 10

```PowerShell
Add-PSSnapin Microsoft.BDD.PSSnapIn

New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root \\TT-FS01\MDT-Build$
```

### # Import operating system - "Windows 10 Enterprise, Version 1903 (x64)"

#### # Mount the installation image

```PowerShell
$imagePath = "\\TT-FS01\Products\Microsoft\Windows 10" `
  + "\en_windows_10_business_edition_version_1903_updated_june_2019_x64_dvd_1f290297.iso"

$imageDriveLetter = Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume |
    select -ExpandProperty DriveLetter

$sourcePath = $imageDriveLetter + ":\"
```

#### # Import operating system

```PowerShell
$destinationFolder = "W10Ent-1903-Jun-2019-x64"

Import-MDTOperatingSystem `
    -Path "DS001:\Operating Systems\Windows 10" `
    -SourcePath $sourcePath `
    -DestinationFolder $destinationFolder
```

```PowerShell
cls
```

#### # Dismount the installation image

```PowerShell
Dismount-DiskImage -ImagePath $imagePath
```

### Modify task sequence to use new version of Windows 10 Enterprise, Version 1903

---

**STORM** - Run as administrator

```PowerShell
cls
```

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\techtoolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    \\TT-FS01\MDT-Build$ '.\Main\MDT-Build$'
```

#### # Sync files

```PowerShell
robocopy \\TT-FS01\MDT-Build$ Main\MDT-Build$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Packages Servicing Tools
```

#### Check-in files

---

## Issue - Not enough free space to install patches using Windows Update

4.5 GB of free space, but unable to install **2019-07 Cumulative Update for Windows Server 2016 for x64-based Systems (KB4507460)**.

### Expand C: volume

---

**FOOBAR21** - Run as administrator

```PowerShell
cls
```

#### # Increase size of VHD

```PowerShell
$vmName = "TT-DEPLOY4"

# Note: VHD is stored on Cluster Shared Volume -- so expand using VMM cmdlet

Stop-SCVirtualMachine -VM $vmName

Get-SCVirtualDiskDrive -VM $vmName |
    where { $_.BusType -eq "SCSI" -and $_.Bus -eq 0 -and $_.Lun -eq 0 } |
    Expand-SCVirtualDiskDrive -VirtualHardDiskSizeGB 40

Start-SCVirtualMachine -VM $vmName
```

---

```PowerShell
cls
```

#### # Extend partition

```PowerShell
$driveLetter = "C"

$partition = Get-Partition -DriveLetter $driveLetter |
    where { $_.DiskNumber -ne $null }

$size = (Get-PartitionSupportedSize `
    -DiskNumber $partition.DiskNumber `
    -PartitionNumber $partition.PartitionNumber)

Resize-Partition `
    -DiskNumber $partition.DiskNumber `
    -PartitionNumber $partition.PartitionNumber `
    -Size $size.SizeMax
```

```PowerShell
cls
```

## # Import operating system - Windows Server 2019

### # Create folder - "Operating Systems\\Windows Server 2019"

```PowerShell
Add-PSSnapin Microsoft.BDD.PSSnapIn

New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root \\TT-FS01\MDT-Build$

New-Item `
    -Path "DS001:\Operating Systems" `
    -Name "Windows Server 2019" `
    -ItemType Folder
```

### # Import operating system - "Windows Server 2019"

#### # Mount the installation image

```PowerShell
$imagePath = "\\TT-FS01\Products\Microsoft\Windows Server 2019" `
    + "\en_windows_server_2019_updated_march_2019_x64_dvd_2ae967ab.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$sourcePath = $imageDriveLetter + ":\"
```

#### # Import operating system

```PowerShell
$destinationFolder = "WS2019-Mar-2019"

Import-MDTOperatingSystem `
    -Path "DS001:\Operating Systems\Windows Server 2019" `
    -SourcePath $sourcePath `
    -DestinationFolder $destinationFolder
```

#### # Dismount the installation image

```PowerShell
Dismount-DiskImage -ImagePath $imagePath
```

---

**STORM** - Run as administrator

```PowerShell
cls
```

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\techtoolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    \\TT-FS01\MDT-Build$ '.\Main\MDT-Build$'
```

#### # Sync files

```PowerShell
robocopy \\TT-FS01\MDT-Build$ Main\MDT-Build$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Packages Servicing Tools
```

#### Check-in files

---

```PowerShell
cls
```

## # Create task sequence for building Windows Server 2019 baseline image

### # Create folder - "Task Sequences\\Windows Server 2019"

```PowerShell
New-Item `
    -Path "DS001:\Task Sequences" `
    -Name "Windows Server 2019" `
    -ItemType Folder
```

### # Create task sequence - "Windows Server 2019 - Baseline"

```PowerShell
$osPath = "DS001:\Operating Systems\Windows Server 2019" `
    + "\Windows Server 2019 SERVERSTANDARD in WS2019-Mar-2019 install.wim"

Import-MDTTaskSequence `
    -Path "DS001:\Task Sequences\Windows Server 2019" `
    -ID "WS2019-REF" `
    -Name "Windows Server 2019 - Baseline" `
    -Comments "Reference image" `
    -Version "1.0" `
    -Template "Server.xml" `
    -OperatingSystemPath $osPath `
    -FullName "Windows User" `
    -OrgName "Technology Toolbox" `
    -HomePage "about:blank" `
    -ProductKey "N69G4-B89J2-4G8F4-WWYCC-J464C"
```

> **Important**
>
> The MSDN version of Windows Server 2019 does not honor the `SkipProductKey=YES` entry in the MDT CustomSettings.ini file. In other words, if no product key is specified in the task sequence, when building the reference image it will prompt to enter a product key (but provide an option to do this later).
>
> The product key specified above was obtained from the following:
>
> **KMS client setup keys**\
> From <[https://docs.microsoft.com/en-us/windows-server/get-started/kmsclientkeys](https://docs.microsoft.com/en-us/windows-server/get-started/kmsclientkeys)>

---

**STORM** - Run as administrator

```PowerShell
cls
```

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\techtoolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    \\TT-FS01\MDT-Build$ '.\Main\MDT-Build$'
```

#### # Sync files

```PowerShell
robocopy \\TT-FS01\MDT-Build$ Main\MDT-Build$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Packages Servicing Tools
```

#### # Add files to TFS

```PowerShell
& "C:\Program Files (x86)\Microsoft Visual Studio\2019\TeamExplorer\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\TF.exe" add Main /r
```

#### Check-in files

---

Build baseline image

---

**TT-HV05A** - Run as administrator

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows Server 2019 - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\TT-FS01\Products\Microsoft\MDT-Build-x86.iso `
    -SwitchName "Embedded Team Switch" `
    -Force
```

---

## Customize Windows Server 2019 baseline image

### Configure task sequence - "Windows Server 2019"

Edit the task sequence to include the actions required to update the reference image with the latest updates from WSUS, copy Toolbox content from TT-FS01, and easily suspend the deployment process after installing applications.

1. Open **Deployment Workbench**, expand **Deployment Shares / MDT Build Lab ([\\\\TT-FS01\\MDT-Build\$](\\TT-FS01\MDT-Build$)) / Task Sequences / Windows Server 2019**, right-click **Windows Server 2019 - Baseline**, and click **Properties**.
2. In the **Windows Server 2019 - Baseline Properties** window:
   1. On the **General** tab, configure the following settings:
      1. Comments: **Reference image - Toolbox content and latest patches**
   2. On the **Task Sequence** tab, configure the following settings:
      1. **State Restore**
         1. Enable the **Windows Update (Pre-Application Installation)** action.
         2. Clear the **Continue on error** checkbox for the **Windows Update (Pre-Application Installation)** action.
         3. Enable the **Windows Update (Post-Application Installation)** action.
         4. Clear the **Continue on error** checkbox for the **Windows Update (Post-Application Installation)** action.
         5. After the **Tattoo** action, add a new **Group** action with the following setting:
            1. Name: **Custom Tasks (Pre-Windows Update)**
         6. After the **Windows Update (Post-Application Installation)** action, rename the **Custom Tasks** group to **Custom Tasks (Post-Windows Update)**.
         7. Select the **Custom Tasks (Pre-Windows Update)** group and add a new **Run Command Line** action with the following settings:
            1. Name: **Copy Toolbox content from TT-FS01**
            2. Command line: **robocopy [\\\\TT-FS01\\Public\\Toolbox](\\TT-FS01\Public\Toolbox) C:\\NotBackedUp\\Public\\Toolbox /E**
            3. Success codes: **0 1 2 3 4 5 6 7 8 16**
         8. After the **Install Applications** action, add a new **Run Command Line** action with the following settings:
            1. Name: **Suspend**
            2. Command line: **cscript.exe "%SCRIPTROOT%\\LTISuspend.wsf"**
            3. Disable this step:** Yes (checked)**
   3. Click **OK**.

> **Note**
>
> The reason for adding the applications after the Tattoo action but before running Windows Update is simply to save time during the deployment. This way we can add all applications that will upgrade some of the built-in components and avoid unnecessary updating.

---

**STORM** - Run as administrator

```PowerShell
cls
```

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\techtoolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    \\TT-FS01\MDT-Build$ '.\Main\MDT-Build$'
```

#### # Sync files

```PowerShell
robocopy \\TT-FS01\MDT-Build$ Main\MDT-Build$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Packages Servicing Tools
```

#### Check-in files

---

Build baseline images

---

**TT-HV05A** - Run as administrator

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows Server 2019 - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\TT-FS01\Products\Microsoft\MDT-Build-x86.iso `
    -SwitchName "Embedded Team Switch" `
    -Force
```

---

```PowerShell
cls
```

## # Add custom Windows Server 2019 image to MDT production deployment share

### # Create folder - "Operating Systems\\Windows Server 2019"

```PowerShell
Import-Module 'C:\Program Files\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1'

New-PSDrive -Name "DS002" -PSProvider MDTProvider -Root \\TT-FS01\MDT-Deploy$

New-Item `
    -Path "DS002:\Operating Systems" `
    -Name "Windows Server 2019" `
    -ItemType Folder
```

```PowerShell
cls
```

### # Import operating system - "Windows Server 2019 Standard - Baseline"

```PowerShell
$imagePath = "\\TT-FS01\MDT-Build$\Captures\WS2019-REF_8-12-2019-9-55-07-AM.wim"

$destinationFolder = "WS2019"

$os = Import-MDTOperatingSystem `
    -Path "DS002:\Operating Systems\Windows Server 2019" `
    -SourceFile $imagePath `
    -DestinationFolder $destinationFolder `
    -Move

$os.RenameItem("Windows Server 2019 Standard - Baseline")
```

---

**STORM** - Run as administrator

```PowerShell
cls
```

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\techtoolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    \\TT-FS01\MDT-Deploy$ '.\Main\MDT-Deploy$'
```

#### # Sync files

```PowerShell
robocopy \\TT-FS01\MDT-Deploy$ Main\MDT-Deploy$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Packages Servicing Tools
```

#### # Add files to TFS

```PowerShell
& "C:\Program Files (x86)\Microsoft Visual Studio\2019\TeamExplorer\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\TF.exe" add Main /r
```

#### Check-in files

---

```PowerShell
cls
```

## # Create task sequence for Windows Server 2019 deployment

### # Create folder - "Task Sequences\\Windows Server 2019"

```PowerShell
New-Item `
    -Path "DS002:\Task Sequences" `
    -Name "Windows Server 2019" `
    -ItemType Folder
```

### # Create task sequence - "Windows Server 2019"

```PowerShell
$osPath = "DS002:\Operating Systems\Windows Server 2019" `
    + "\Windows Server 2019 Standard - Baseline"

Import-MDTTaskSequence `
    -Path "DS002:\Task Sequences\Windows Server 2019" `
    -ID "WS2019" `
    -Name "Windows Server 2019" `
    -Comments "Production image" `
    -Version "1.0" `
    -Template "Server.xml" `
    -OperatingSystemPath $osPath `
    -FullName "Windows User" `
    -OrgName "Technology Toolbox" `
    -HomePage "about:blank" `
    -ProductKey "N69G4-B89J2-4G8F4-WWYCC-J464C"
```

> **Important**
>
> The MSDN version of Windows Server 2019 does not honor the `SkipProductKey=YES` entry in the MDT CustomSettings.ini file. In other words, if no product key is specified in the task sequence, when deploying the baseline image it will prompt to enter a product key (but provide an option to do this later).
>
> The product key specified above was obtained from the following:
>
> **KMS client setup keys**\
> From <[https://docs.microsoft.com/en-us/windows-server/get-started/kmsclientkeys](https://docs.microsoft.com/en-us/windows-server/get-started/kmsclientkeys)>

---

**STORM** - Run as administrator

```PowerShell
cls
```

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\techtoolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    \\TT-FS01\MDT-Deploy$ '.\Main\MDT-Deploy$'
```

#### # Sync files

```PowerShell
robocopy \\TT-FS01\MDT-Deploy$ Main\MDT-Deploy$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Packages Servicing Tools
```

#### # Add files to TFS

```PowerShell
& "C:\Program Files (x86)\Microsoft Visual Studio\2019\TeamExplorer\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\TF.exe" add Main /r
```

#### Check-in files

---

## Customize Windows Server 2019 baseline image to minimize image size

### Configure task sequence - "Windows Server 2019"

Edit the task sequence to include actions to set MaxPatchCacheSize to 0 and clean up the image after patching.

1. Open **Deployment Workbench**, expand **Deployment Shares / MDT Build Lab ([\\\\TT-FS01\\MDT-Build\$](\\TT-FS01\MDT-Build$)) / Task Sequences / Windows Server 2019**, right-click **Windows Server 2019 - Baseline**, and click **Properties**.
2. In the **Windows Server 2019 - Baseline Properties** window:
   1. On the **General** tab, configure the following settings:
      1. Comments: **Reference image - MaxPatchCacheSize = 0, Toolbox content, latest patches, and cleanup before Sysprep**
   2. On the **Task Sequence** tab, configure the following settings:
      1. **State Restore**
         1. Select the **Custom Tasks (Pre-Windows Update)** group and add a new **Run Command Line** action with the following settings:
            1. Name: **Set MaxPatchCacheSize to 0**
            2. Command line: **PowerShell.exe -Command "& { New-Item -Path 'HKLM:\\Software\\Policies\\Microsoft\\Windows\\Installer'; New-ItemProperty -Path 'HKLM:\\Software\\Policies\\Microsoft\\Windows\\Installer' -Name MaxPatchCacheSize -PropertyType DWord -Value 0 | Out-Null }"**
         2. After the **Apply Local GPO Package** action, add a new group with the following setting:
            1. Name: **Cleanup before Sysprep**
         3. Select the **Cleanup before Sysprep** group created in the previous step and add a new group with the following setting:
            1. Name: **Compress the image**
         4. Select the **Compress the image** group and add a new **Restart computer** action.
         5. After the new **Restart computer** action added in the previous step, add a new **Install Application** action with the following settings:
            1. Name: **Action - Cleanup before Sysprep**
            2. **Install a single application**
            3. Application to install: **Action - Cleanup before Sysprep**
         6. After the action added in the previous step, add a new **Restart computer** action.
   3. Click **OK**.

---

**STORM** - Run as administrator

```PowerShell
cls
```

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\techtoolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    \\TT-FS01\MDT-Build$ '.\Main\MDT-Build$'
```

#### # Sync files

```PowerShell
robocopy \\TT-FS01\MDT-Build$ Main\MDT-Build$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Packages Servicing Tools
```

#### Check-in files

---

Build baseline images

---

**TT-HV05A** - Run as administrator

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows Server 2019 - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\TT-FS01\Products\Microsoft\MDT-Build-x86.iso `
    -SwitchName "Embedded Team Switch" `
    -Force
```

---

```PowerShell
cls
```

## # Upgrade to latest version of Windows 10 (August 2019)

```PowerShell
Add-PSSnapin Microsoft.BDD.PSSnapIn

New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root \\TT-FS01\MDT-Build$
```

### # Import operating system - "Windows 10 Enterprise, Version 1903 (x64)"

#### # Mount the installation image

```PowerShell
$imagePath = "\\TT-FS01\Products\Microsoft\Windows 10" `
  + "\en_windows_10_business_editions_version_1903_updated_aug_2019_x64_dvd_f50487e6.iso"

$imageDriveLetter = Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume |
    select -ExpandProperty DriveLetter

$sourcePath = $imageDriveLetter + ":\"
```

#### # Import operating system

```PowerShell
$destinationFolder = "W10Ent-1903-Aug-2019-x64"

Import-MDTOperatingSystem `
    -Path "DS001:\Operating Systems\Windows 10" `
    -SourcePath $sourcePath `
    -DestinationFolder $destinationFolder
```

```PowerShell
cls
```

#### # Dismount the installation image

```PowerShell
Dismount-DiskImage -ImagePath $imagePath
```

### Modify task sequence to use new version of Windows 10 Enterprise, Version 1903

### Delete old version of Windows 10 Enterprise, Version 1903

---

**STORM** - Run as administrator

```PowerShell
cls
```

### # Update files in GitHub

#### # Sync files

```PowerShell
robocopy \\TT-FS01\MDT-Build$ F:\NotBackedUp\MDT-Build /E /MIR
```

#### Format XML files using Visual Studio

```PowerShell
cls
```

#### # Check-in files

```PowerShell
Push-Location F:\NotBackedUp\MDT-Build

git add Control/*

git commit -m "Upgrade to latest version of Windows 10 (August 2019)"

Pop-Location
```

---

```PowerShell
cls
```

## # Upgrade to latest version of Windows Server 2019 (August 2019)

```PowerShell
Add-PSSnapin Microsoft.BDD.PSSnapIn

New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root \\TT-FS01\MDT-Build$
```

### # Import operating system - "Windows Server 2019"

#### # Mount the installation image

```PowerShell
$imagePath = "\\TT-FS01\Products\Microsoft\Windows Server 2019" `
    + "\en_windows_server_2019_updated_aug_2019_x64_dvd_cdf24600.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$sourcePath = $imageDriveLetter + ":\"
```

#### # Import operating system

```PowerShell
$destinationFolder = "WS2019-Aug-2019"

Import-MDTOperatingSystem `
    -Path "DS001:\Operating Systems\Windows Server 2019" `
    -SourcePath $sourcePath `
    -DestinationFolder $destinationFolder
```

```PowerShell
cls
```

#### # Dismount the installation image

```PowerShell
Dismount-DiskImage -ImagePath $imagePath
```

### Modify task sequence to use new version of Windows Server 2019

### Delete old version of Windows Server 2019

---

**STORM** - Run as administrator

```PowerShell
cls
```

### # Update files in GitHub

#### # Sync files

```PowerShell
robocopy \\TT-FS01\MDT-Build$ F:\NotBackedUp\MDT-Build /E /MIR
```

#### Format XML files using Visual Studio

```PowerShell
cls
```

#### # Check-in files

```PowerShell
Push-Location F:\NotBackedUp\MDT-Build

git add Control/*

git commit -m "Upgrade to latest version of Windows Server 2019 (August 2019)"

git push

Pop-Location
```

---

## Issue - Errors building Windows 7 and Windows Server 2008 baseline images

Error 0x80092004 occurred when installing updates due to missing SHA-1 signatures (starting with updates released in August 2019).

### References

**If you get Windows Update error 0x80092004 on Windows 7 or Server 2008 R2 do this**\
From <[https://www.ghacks.net/2019/08/15/if-you-get-windows-update-error-0x80092004-on-windows-7-or-server-2008-r2-do-this/](https://www.ghacks.net/2019/08/15/if-you-get-windows-update-error-0x80092004-on-windows-7-or-server-2008-r2-do-this/)>

```PowerShell
cls
```

### # Add Servicing Stack Updates to MDT

```PowerShell
Add-PSSnapin Microsoft.BDD.PSSnapIn

New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root \\TT-FS01\MDT-Build$
```

### # Create folder - "Packages\\Windows 7 and Windows Server 2008 R2"

```PowerShell
New-Item `
    -Path "DS001:\Packages" `
    -Name "Windows 7 and Windows Server 2008 R2" `
    -ItemType Folder

Import-MdtPackage `
    -Path "DS001:\Packages\Windows 7 and Windows Server 2008 R2" `
    -SourcePath "\\TT-FS01\Products\Microsoft\Windows 7\SSU"

Remove-Item -Path ("DS001:\Packages\Windows 7 and Windows Server 2008 R2\" `
    + "Package_for_KB4516655 neutral amd64 6.1.1.1")

Remove-Item -Path ("DS001:\Packages\Windows 7 and Windows Server 2008 R2\" `
    + "Package_for_KB4516655 neutral x86 6.1.1.1")
```

---

**STORM** - Run as administrator

```PowerShell
cls
```

### # Update files in GitHub

#### # Sync files

```PowerShell
robocopy \\TT-FS01\MDT-Build$ F:\NotBackedUp\MDT-Build /E /MIR
```

#### Format XML files using Visual Studio

```PowerShell
cls
```

#### # Check-in files

```PowerShell
Push-Location F:\NotBackedUp\MDT-Build

git add Control/*

git commit -m "Add Servicing Stack Update for Windows 7 and Windows Server 2008 R2 (#1)"

Pop-Location
```

---

```PowerShell
cls
```

## # Upgrade to latest version of Windows 10 (Version 1909)

```PowerShell
Add-PSSnapin Microsoft.BDD.PSSnapIn

New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root \\TT-FS01\MDT-Build$
```

### # Import operating system - "Windows 10 Enterprise, Version 1909 (x64)"

#### # Mount the installation image

```PowerShell
$imagePath = "\\TT-FS01\Products\Microsoft\Windows 10" `
  + "\en_windows_10_business_editions_version_1909_x64_dvd_ada535d0.iso"

$imageDriveLetter = Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume |
    select -ExpandProperty DriveLetter

$sourcePath = $imageDriveLetter + ":\"
```

#### # Import operating system

```PowerShell
$destinationFolder = "W10Ent-1909-x64"

Import-MDTOperatingSystem `
    -Path "DS001:\Operating Systems\Windows 10" `
    -SourcePath $sourcePath `
    -DestinationFolder $destinationFolder
```

```PowerShell
cls
```

#### # Dismount the installation image

```PowerShell
Dismount-DiskImage -ImagePath $imagePath
```

### Modify task sequence to use new version of Windows 10 Enterprise, Version 1909

### Delete old version of Windows 10 Enterprise, Version 1903

---

**STORM** - Run as administrator

```PowerShell
cls
```

### # Update files in GitHub

#### # Sync files

```PowerShell
robocopy \\TT-FS01\MDT-Build$ F:\NotBackedUp\MDT-Build /E /MIR
```

#### Format XML files using Visual Studio

```PowerShell
cls
```

#### # Check-in files

```PowerShell
Push-Location F:\NotBackedUp\MDT-Build

git add Control/*

git commit -m "Upgrade to latest version of Windows 10 (Version 1909)"

Pop-Location
```

---

```PowerShell
cls
```

## # Upgrade to latest version of Windows Server 2019 (September 2019)

```PowerShell
Add-PSSnapin Microsoft.BDD.PSSnapIn

New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root \\TT-FS01\MDT-Build$
```

### # Import operating system - "Windows Server 2019"

#### # Mount the installation image

```PowerShell
$imagePath = "\\TT-FS01\Products\Microsoft\Windows Server 2019" `
    + "\en_windows_server_2019_updated_sept_2019_x64_dvd_199664ce.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$sourcePath = $imageDriveLetter + ":\"
```

#### # Import operating system

```PowerShell
$destinationFolder = "WS2019-Sep-2019"

Import-MDTOperatingSystem `
    -Path "DS001:\Operating Systems\Windows Server 2019" `
    -SourcePath $sourcePath `
    -DestinationFolder $destinationFolder
```

```PowerShell
cls
```

#### # Dismount the installation image

```PowerShell
Dismount-DiskImage -ImagePath $imagePath
```

### Modify task sequence to use new version of Windows Server 2019

### Delete old version of Windows Server 2019

---

**STORM** - Run as administrator

```PowerShell
cls
```

### # Update files in GitHub

#### # Sync files

```PowerShell
robocopy \\TT-FS01\MDT-Build$ F:\NotBackedUp\MDT-Build /E /MIR
```

#### Format XML files using Visual Studio

```PowerShell
cls
```

#### # Check-in files

```PowerShell
Push-Location F:\NotBackedUp\MDT-Build

git add Control/*

git commit -m "Upgrade to latest version of Windows Server 2019 (September 2019)"

git push

Pop-Location
```

---

## Upgrade to Operations Manager 2019

```PowerShell
cls
```

### # Remove SCOM 2016 agent

```PowerShell
msiexec /x `{742D699D-56EB-49CC-A04A-317DE01F31CD`}
```

```PowerShell
cls
```

### # Install SCOM agent

```PowerShell
$msiPath = "\\TT-FS01\Products\Microsoft\System Center 2019\SCOM\agent\AMD64" `
    + "\MOMAgent.msi"

msiexec.exe /i $msiPath `
    MANAGEMENT_GROUP=HQ `
    MANAGEMENT_SERVER_DNS=TT-SCOM01C `
    ACTIONS_USE_COMPUTER_ACCOUNT=1
```

### Approve manual agent install in Operations Manager

```PowerShell
cls
```

## # Upgrade to latest version of Windows 10 (Version 2004)

```PowerShell
Add-PSSnapin Microsoft.BDD.PSSnapIn

New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root \\TT-FS01\MDT-Build$
```

### # Import operating system - "Windows 10 Enterprise, Version 2004 (x64)"

#### # Mount the installation image

```PowerShell
$imagePath = "\\TT-FS01\Products\Microsoft\Windows 10" `
  + "\en_windows_10_business_editions_version_2004_x64_dvd_d06ef8c5.iso"

$imageDriveLetter = Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume |
    select -ExpandProperty DriveLetter

$sourcePath = $imageDriveLetter + ":\"
```

#### # Import operating system

```PowerShell
$destinationFolder = "W10Ent-2004-x64"

Import-MDTOperatingSystem `
    -Path "DS001:\Operating Systems\Windows 10" `
    -SourcePath $sourcePath `
    -DestinationFolder $destinationFolder
```

```PowerShell
cls
```

#### # Dismount the installation image

```PowerShell
Dismount-DiskImage -ImagePath $imagePath
```

### Modify task sequence to use new version of Windows 10 Enterprise, Version 2004

### Delete old version of Windows 10 Enterprise, Version 1909

---

**STORM** - Run as administrator

```PowerShell
cls
```

### # Update files in GitHub

#### # Sync files

```PowerShell
robocopy \\TT-FS01\MDT-Build$ Z:\NotBackedUp\MDT-Build /E /MIR /XD .git
```

#### Format XML files using Visual Studio

```PowerShell
cls
```

#### # Check-in files

```PowerShell
Push-Location Z:\NotBackedUp\MDT-Build

git add Control/*

git commit -m "Upgrade to latest version of Windows 10 (Version 2004)"

Pop-Location
```

---

### Apply updates to avoid issues with MDT and Windows 10 Version 2004

> **Important**
>
> There are known issues when using the Microsoft Deployment Toolkit to build
> images for Windows 10 Version 2004. For example, after running SysPrep and
> restarting, the VM fails to boot (it loops through the "Loading files..."
> screen several times and then shuts down).
>
> To avoid these issues, it is necessary to
> overwrite the **Microsoft.BDD.Utility.dll** files on the MDT server and update
> the deployment share.
>
> Refer to the following:
>
> **Windows 10 deployments fail with Microsoft Deployment Toolkit on computers with BIOS type firmware**\
> From <[https://support.microsoft.com/en-us/help/4564442/windows-10-deployments-fail-with-microsoft-deployment-toolkit](https://support.microsoft.com/en-us/help/4564442/windows-10-deployments-fail-with-microsoft-deployment-toolkit)>

#### Download patch for MDT and Windows 10 Version 2004

Download the patch (**MDT_KB4564442.exe**) from Microsoft KB article 4564442 and
extract the contents.

#### Update Microsoft.BDD.Utility.dll files on MDT server

1. Close **Deployment Workbench**.
2. Backup the existing versions of the Microsoft.BDD.Utility.dll
   file in the following locations:\
   %ProgramFiles%\Microsoft Deployment Toolkit\Templates\Distribution\Tools\x86\
   %ProgramFiles%\Microsoft Deployment Toolkit\Templates\Distribution\Tools\x64\
3. Copy the new files extracted from MDT_KB4564442.exe over the old versions.

```PowerShell
cls
```

#### # Update Microsoft.BDD.Utility.dll files on MDT deployment shares

```PowerShell
$mdtPath = "$env:ProgramFiles\Microsoft Deployment Toolkit"
$filename = 'Microsoft.BDD.Utility.dll'

Copy-Item `
    "$mdtPath\Templates\Distribution\Tools\x64\$filename" `
    '\\TT-FS01\MDT-Build$\Tools\x64'

Copy-Item `
    "$mdtPath\Templates\Distribution\Tools\x86\$filename" `
    '\\TT-FS01\MDT-Build$\Tools\x86'

Copy-Item `
    "$mdtPath\Templates\Distribution\Tools\x64\$filename" `
    '\\TT-FS01\MDT-Deploy$\Tools\x64'

Copy-Item `
    "$mdtPath\Templates\Distribution\Tools\x86\$filename" `
    '\\TT-FS01\MDT-Deploy$\Tools\x86'
```

#### Update MDT deployment share

1. Open **Deployment Workbench**.
2. Select the **MDT Build Lab (\\\\TT-FS01\MDT-Build\$)** deployment share.
3. On the **Action** menu, click **Update Deployment Share**.
4. In the **Update Deployment Share Wizard**, select the
   **Completely regenerate the boot images** option.
5. Repeat the previous steps for the
   **MDT Deployment (\\\\TT-FS01\MDT-Deploy\$)** deployment share.

```PowerShell
cls
```

#### # Copy MDT boot images to file server

```PowerShell
Copy-Item `
    "\\TT-FS01\MDT-Build$\Boot\MDT-Build-x64.iso" `
    \\TT-FS01\Products\Microsoft

Copy-Item `
    "\\TT-FS01\MDT-Build$\Boot\MDT-Build-x86.iso" `
    \\TT-FS01\Products\Microsoft

Copy-Item `
    "\\TT-FS01\MDT-Deploy$\Boot\MDT-Deploy-x64.iso" `
    \\TT-FS01\Products\Microsoft

Copy-Item `
    "\\TT-FS01\MDT-Deploy$\Boot\MDT-Deploy-x64.iso" `
    \\TT-FS01\Products\Microsoft
```

---

**STORM** - Run as administrator

```PowerShell
cls
```

### # Update MDT Build Lab files in GitHub

#### # Sync files

```PowerShell
robocopy \\TT-FS01\MDT-Build$ Z:\NotBackedUp\MDT-Build /E /MIR /XD .git
```

```PowerShell
cls
```

#### # Check-in files

```PowerShell
Push-Location Z:\NotBackedUp\MDT-Build

git add Tools/*

git commit -m "Apply updates to avoid issues with MDT and Windows 10 Version 2004"

Pop-Location
```

```PowerShell
cls
```

### # Update MDT Deployment files in GitHub

#### # Sync files

```PowerShell
robocopy \\TT-FS01\MDT-Deploy$ Z:\NotBackedUp\MDT-Deploy /E /MIR /XD .git
```

```PowerShell
cls
```

#### # Check-in files

```PowerShell
Push-Location Z:\NotBackedUp\MDT-Deploy

git add Tools/*

git commit -m "Apply updates to avoid issues with MDT and Windows 10 Version 2004"

Pop-Location
```

---


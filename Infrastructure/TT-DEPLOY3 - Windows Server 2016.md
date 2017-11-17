# TT-DEPLOY3 - Windows Server 2016

Tuesday, November 14, 2017
8:20 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

### Install Windows Server 2016

---

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Create virtual machine

```PowerShell
$vmHost = "TT-HV02B"
$vmName = "TT-DEPLOY3"
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
  - In the **Computer name** box, type **TT-DEPLOY3**.
  - Click **Next**.
- On the **Applications** step, do not select any applications, and click **Next**.

---

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Remove disk from virtual CD/DVD drive

```PowerShell
$vmHost = "TT-HV02B"
$vmName = "TT-DEPLOY3"

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

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Move computer to different OU

```PowerShell
$vmName = "TT-DEPLOY3"

$targetPath = "OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com"

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
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

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Add disks to virtual machine

```PowerShell
$vmHost = "TT-HV02B"
$vmName = "TT-DEPLOY3"
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
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -UseMaximumSize -DriveLetter D |
    Format-Volume `
        -FileSystem NTFS `
        -NewFileSystemLabel "Data01" `
        -Confirm:$false
```

---

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Enable Secure Boot and set first boot device to hard drive

```PowerShell
$vmHost = "TT-HV02B"
$vmName = "TT-DEPLOY3"

$vmHardDiskDrive = Get-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName

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
```

    + "\\Windows ADK for Windows 10, version 1709\\adksetup.exe")

1. On the **Specify Location** page, click **Next**.
2. On the **Windows Kits Privacy **page, click **Next**.
3. On the **License Agreement** page:
   1. Review the software license terms.
   2. If you agree to the terms, click **Accept**.
4. On the **Select the features you want to install **page:
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

#### Change monitoring host from MIMIC2 to TT-DEPLOY3

1. Open **Deployment Workbench** and expand **Deployment Shares**.
2. Right-click **MDT Build Lab ([\\\\TT-FS01\\MDT-Build\$](\\TT-FS01\MDT-Build$))** and then click **Properties**.
3. In the **MDT Build Lab ([\\\\TT-FS01\\MDT-Build\$](\\TT-FS01\MDT-Build$)) Properties** window:
   1. On the **Monitoring** tab, in the **Monitoring host** box, type **TT-DEPLOY3**.
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

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

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

### Configure Windows Deployment Services integrated with Active Directory

To configure Windows Deployment Services integrated with Active Directory:

1. Log on to the server as a member of the Domain Administrators group.
2. Server Manager will start automatically. If it does not automatically start, click **Start**, type **servermanager.exe**, and then click **Server Manager**.
3. Click **Tools**, and then click **Windows Deployment Services** to launch the Windows Deployment Services MMC-snap (or console).
4. In the left pane of the Windows Deployment Services MMC snap-in, expand the list of servers.
5. Right-click the desired server, click **Configure Server**.
6. On the **Before You Begin** page, click **Next**.
7. On the **Install Options** page, choose **Integrated with Active Directory**.
8. On the **Remote Installation Folder Location** page:
   1. In the **Path** box, type **D:\\RemoteInstall**.
   2. Click **Next**.
9. On the **PXE Server Initial Settings** page:
   1. Select **Respond to all client computers (known and unknown)**.
   2. Click **Next**. This will complete the
10. Wait for the configuration of Windows Deployment Services to complete.
11. On the **Operation Complete** page, clear the **Add images to the server now** checkbox and click **Finish**.

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

## Configure WDS to use PXELinux

### Reference

**Booting Alternative Images from WDS using PXELinux**\
From <[https://www.mikeslab.net/?p=504](https://www.mikeslab.net/?p=504)>

### Download syslinux

[https://www.kernel.org/pub/linux/utils/boot/syslinux/4.xx/syslinux-4.07.zip](https://www.kernel.org/pub/linux/utils/boot/syslinux/4.xx/syslinux-4.07.zip)

### Install PXELinux files

#### Extract files

Extract the following files to C:\\NotBackedUp\\Temp:

- **core/pxelinux.0**
- **com32/menu/vesamenu.c32**
- **com32/chain/chain.c32**
- **memdisk/memdisk**

```PowerShell
cls
```

#### # Rename and copy files

```PowerShell
Push-Location C:\NotBackedUp\Temp

Rename-Item pxelinux.0 pxelinux.com

robocopy . D:\RemoteInstall\Boot\x86 chain.c32 memdisk pxelinux.com vesamenu.c32

Pop-Location

Push-Location D:\RemoteInstall\Boot\x86

Copy-Item .\abortpxe.com .\abortpxe.0
Copy-Item .\pxeboot.n12 .\pxeboot.0

Pop-Location

Push-Location C:\NotBackedUp\Temp

robocopy . D:\RemoteInstall\Boot\x64 chain.c32 memdisk pxelinux.com vesamenu.c32

Pop-Location

Push-Location D:\RemoteInstall\Boot\x64

Copy-Item .\abortpxe.com .\abortpxe.0
Copy-Item .\pxeboot.n12 .\pxeboot.0

Pop-Location
```

```PowerShell
cls
```

#### # Configure PXELinux

```PowerShell
mkdir D:\RemoteInstall\Boot\pxelinux.cfg

Push-Location D:\RemoteInstall\Boot\x86

cmd /c mklink /J pxelinux.cfg D:\RemoteInstall\Boot\pxelinux.cfg

Pop-Location

Push-Location D:\RemoteInstall\Boot\x64

cmd /c mklink /J pxelinux.cfg D:\RemoteInstall\Boot\pxelinux.cfg

Pop-Location

New-Item -ItemType File -Path D:\RemoteInstall\Boot\pxelinux.cfg\default

Notepad D:\RemoteInstall\Boot\pxelinux.cfg\default
```

---

**D:\\RemoteInstall\\Boot\\pxelinux.cfg\\default**

```INI
DEFAULT      vesamenu.c32

NOESCAPE     0
ALLOWOPTIONS 0

# Time out and use the default menu option. Defined as tenths of a second.
TIMEOUT 300

# Prompt the user. Set to '1' to automatically choose the default option. This
# is really meant for files matched to MAC addresses.
PROMPT 0

MENU BACKGROUND Technology-Toolbox-Background-640x480.png
MENU MARGIN 10
MENU ROWS 16
MENU TABMSGROW 21
MENU TIMEOUTROW 25
MENU COLOR border       37;44    #ff3c78c3 #ffeeeeee none
MENU COLOR scrollbar    37;44    #40000000 #ff959595 std
MENU COLOR title        34;47    #ff1e4173 #ffffffff none
MENU COLOR sel          7;37;40  #ff000000 #ffffff99 none
MENU COLOR unsel        30;47    #ff4f4f4f #ffffffff none
MENU COLOR timeout_msg  30;47    #ff3c78c3 #ffffffff none
MENU COLOR timeout      30;47    #ffbd1c1c #ffffffff none
MENU TITLE Technology Toolbox PXE Boot
#---
LABEL local
    MENU DEFAULT
    MENU LABEL Boot from hard disk
    LOCALBOOT 0
    Type 0x80
#---
LABEL memtest
MENU LABEL Run Memtest86+
LINUX /Linux/memtest86+
#---
LABEL WDS
    MENU LABEL Windows Deployment Services
    KERNEL pxeboot.0
#---
LABEL Abort
    MENU LABEL Abort PXE
    KERNEL abortpxe.0
#---
LABEL hdt
MENU LABEL Run Hardware Detection Tool
COM32 pxelinux.cfg/arch/hdt.c32

LABEL partedmagic
MENU LABEL Boot Parted Magic
LINUX /images/memdisk
INITRD /images/pmagic.iso
APPEND iso raw

LABEL reboot
MENU LABEL Reboot
COM32 pxelinux.cfg/arch/reboot.c32

LABEL poweroff
MENU LABEL Power off
COMBOOT pxelinux.cfg/arch/poweroff.com
```

---

```PowerShell
$imageFile = "Technology-Toolbox-Background-640x480.png"
$imagePath = "D:\RemoteInstall\Boot\x64\pxelinux.cfg\$imageFile"

Push-Location D:\RemoteInstall\Boot\x86

cmd /c mklink $imageFile $imagePath

Pop-Location

Push-Location D:\RemoteInstall\Boot\x64

cmd /c mklink $imageFile $imagePath

Pop-Location
```

```PowerShell
cls
```

#### # Configure WDS to use PXELinux as the boot program

```PowerShell
WDSUTIL /Set-Server /BootProgram:Boot\x86\pxelinux.com /Architecture:x86
WDSUTIL /Set-Server /N12BootProgram:Boot\x86\pxelinux.com /Architecture:x86
WDSUTIL /Set-Server /BootProgram:Boot\x64\pxelinux.com /Architecture:x64
WDSUTIL /Set-Server /N12BootProgram:Boot\x64\pxelinux.com /Architecture:x64
```

```PowerShell
cls
```

#### # Configure Linux installation images

```PowerShell
mkdir D:\RemoteInstall\Images\Linux

Push-Location D:\RemoteInstall\Boot\x86

cmd /c mklink /J Linux D:\RemoteInstall\Images\Linux

Pop-Location

Push-Location D:\RemoteInstall\Boot\x64

cmd /c mklink /J Linux D:\RemoteInstall\Images\Linux

Pop-Location
```

```PowerShell
cls
```

#### # Configure WDS to use default boot programs

```PowerShell
WDSUTIL /Set-Server /BootProgram:boot\x86\pxeboot.com /Architecture:x86
WDSUTIL /Set-Server /N12BootProgram:boot\x86\pxeboot.n12 /Architecture:x86
WDSUTIL /Set-Server /BootProgram:boot\x64\pxeboot.com /Architecture:x64
WDSUTIL /Set-Server /N12BootProgram:boot\x64\pxeboot.n12 /Architecture:x64
```

## Upgrade to System Center Operations Manager 2016

### Uninstall SCOM 2012 R2 agent

```Console
msiexec /x `{786970C5-E6F6-4A41-B238-AE25D4B91EEA`}

Restart-Computer
```

## # Install SCOM agent

```PowerShell
$imagePath = '\\iceman\Products\Microsoft\System Center 2012 R2' `
    + '\en_system_center_2012_r2_operations_manager_x86_and_x64_dvd_2920299.iso'

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$msiPath = $imageDriveLetter + ':\agent\AMD64\MOMAgent.msi'

msiexec.exe /i $msiPath `
    MANAGEMENT_GROUP=HQ `
    MANAGEMENT_SERVER_DNS=JUBILEE `
    ACTIONS_USE_COMPUTER_ACCOUNT=1
```

## # Approve manual agent install in Operations Manager

### Install SCOM 2016 agent (using Operations Console)

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

# Build baseline images

---

**TT-HV02A / TT-HV02B / TT-HV02C**

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

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure\Main\Scripts

& '.\Update Deployment Images.ps1'
```

---

## Modify task sequences to fail when errors occur installing patches via Windows Update

### Reference

Bug 4274 - Error installing patches via Windows Update are not reported when building reference images

---

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

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
```

##### Check-in files

---

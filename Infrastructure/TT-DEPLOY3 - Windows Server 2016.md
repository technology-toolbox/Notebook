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

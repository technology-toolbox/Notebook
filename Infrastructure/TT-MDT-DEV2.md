# TT-MDT-DEV2

Friday, August 30, 2019
7:21 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure infrastructure

---

**FOOBAR21 - Run as administrator**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "TT-MDT-DEV2"
$vmPath = "E:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 4GB `
    -SwitchName "Embedded Team Switch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 2 `
    -AutomaticCheckpointsEnabled $false

Set-VMNetworkAdapterVlan `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Access `
    -VlanId 30

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Install custom Windows Server 2019 image

- On the **Task Sequence** step, select **Windows Server 2019** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **TT-MDT-DEV2**.
  - Click **Next**.
- On the **Applications** step:
  - Select the following applications:
    - **Adobe**
      - **Adobe Reader 8.3.1**
    - **Chrome**
      - **Chrome (64-bit)**
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

### Configure storage

```PowerShell
cls
```

### # Configure networking

```PowerShell
$interfaceAlias = "Production"
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

ping TT-DC10 -f -l 8900
```

---

**FOOBAR21 - Run as domain administrator**

```PowerShell
cls

$vmName = "TT-MDT-DEV2"
```

### # Move computer to different OU

```PowerShell
$targetPath = ("OU=Servers,OU=Resources,OU=Development" `
    + ",DC=corp,DC=technologytoolbox,DC=com")

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

## # Install and configure Git

### # Install Git

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$setupPath = "\\TT-FS01\Products\Git\Git-2.23.0-64-bit.exe"

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

## Install updates using Windows Update

> **Note**
>
> Repeat until there are no updates available for the computer.

## Baseline virtual machine

---

**FOOBAR21 - Run as administrator**

```PowerShell
cls
```

### # Checkpoint VM

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "TT-MDT-DEV2"
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
    + "\Windows ADK for Windows 10, version 1903\adksetup.exe")
```

1. On the **Specify Location** page, click **Next**.
2. On the **Windows Kits Privacy** page, click **Next**.
3. On the **License Agreement** page:
   1. Review the software license terms.
   2. If you agree to the terms, click **Accept**.
4. On the **Select the features you want to install** page:
   1. Select the following items:
      - **Deployment Tools**
      - **User State Migration Tool (USMT)**
   2. Click **Install**.

```PowerShell
cls
```

### # Install Windows PE Add-ons for ADK

```PowerShell
& ("\\TT-FS01\Products\Microsoft\Windows Assessment and Deployment Kit" `
    + "\Windows PE Add-ons for ADK\adkwinpesetup.exe")
```

1. On the **Specify Location** page, click **Next**.
2. On the **Windows Kits Privacy** page, click **Next**.
3. On the **License Agreement** page:
   1. Review the software license terms.
   2. If you agree to the terms, click **Accept**.
4. On the **Select the features you want to install** page:
   1. Select the following items:
      - **Deployment Tools**
      - **User State Migration Tool (USMT)**
   2. Click **Install**.

```PowerShell
cls
```

### # Install Microsoft Deployment Toolkit

```PowerShell
& ("\\TT-FS01\Products\Microsoft\Microsoft Deployment Toolkit" `
    + "\MDT - build 8456\MicrosoftDeploymentToolkit_x64.msi")
```

```PowerShell
cls
```

### # Clone MDT deployment share from GitHub

```PowerShell
Push-Location C:\

git clone https://github.com/technology-toolbox/MDT.git

Pop-Location

New-SmbShare `
    -Name MDT$ `
    -Path C:\MDT `
    -CachingMode None `
    -ChangeAccess Everyone
```

#### # Remove "BUILTIN\\Users" permissions

```PowerShell
icacls C:\MDT /inheritance:d
icacls C:\MDT /remove:g "BUILTIN\Users"
```

### Update MDT deployment shares and regenerate boot images

#### Change monitoring host to TT-MDT-DEV2

1. Open **Deployment Workbench** and expand **Deployment Shares**.
2. Right-click **MDT Build Lab ([\\\\TT-FS01\\MDT-Build\$](\\TT-FS01\MDT-Build$))** and then click **Properties**.
3. In the **MDT Build Lab ([\\\\TT-FS01\\MDT-Build\$](\\TT-FS01\MDT-Build$)) Properties** window:
   1. On the **Monitoring** tab, in the **Monitoring host** box, type **TT-MDT-DEV2**.
   2. Click **OK**.

#### Update MDT deployment shares (to regenerate the boot images)

1. Open **Deployment Workbench** and expand **Deployment Shares**.
2. Right-click **MDT ([\\\\TT-FS01\\MDT-Build\$](\\TT-FS01\MDT-Build$))** and then click **Update Deployment Share**.
3. In the **Update Deployment Share Wizard**:
   1. On the **Options** step, select **Completely regenerate the boot images**, and then click **Next**.
   2. On the **Summary** step, click **Next**.
   3. Wait for the deployment share to be updated, verify no errors occurred during the update, and then click **Finish**.

---

**WOLVERINE - Run as administrator**

```PowerShell
cls
```

#### # Update files in GitHub

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

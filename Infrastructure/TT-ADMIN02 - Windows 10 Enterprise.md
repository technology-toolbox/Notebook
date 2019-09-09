# TT-ADMIN02 - Windows 10 Enterprise

Monday, September 9, 2019
8:22 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure infrastructure

---

**FOOBAR22 - Run as local administrator**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05B"
$vmName = "TT-ADMIN02"
$vmPath = "D:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 60GB `
    -MemoryStartupBytes 2GB `
    -SwitchName "Embedded Team Switch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 2 `
    -DynamicMemory `
    -MemoryMinimumBytes 1GB `
    -MemoryMaximumBytes 4GB `
    -AutomaticCheckpointsEnabled $false

Set-VMNetworkAdapterVlan `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Access `
    -VlanId 30

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Install custom Windows 10 image

- On the **Task Sequence** step, select **Windows 10 Enterprise (x64)** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **TT-ADMIN02**.
  - Click **Next**.
- On the **Applications** step:
  - Select the following applications:
    - **Adobe**
      - **Adobe Reader 8.3.1**
    - **Chrome**
      - **Chrome (64-bit)**
    - **Microsoft**
      - **Microsoft Report Viewer 2012 (bundle)**
      - **SQL Server 2017 Management Studio**
      - **System Center 2012 R2 Configuration Manager Toolkit**
      - **System Center Data Protection Manager 2016 - Central Console (bundle)**
      - **System Center Operations Manager 2016 - Operations Console (bundle)**
      - **System Center Virtual Machine Manager 2016 - Console**
    - **Mozilla**
      - **Firefox (64-bit)**
      - **Thunderbird**
  - Click **Next**.

> **Note**
>
> After the custom Windows 10 image is installed, the following message is displayed:\
> This user can't sign in because this account is currently disabled.\
> Click **OK** to acknowledge the local Administrator account is disabled by default in Windows 10.

### Login as TECHTOOLBOX\\jjameson-admin

> **Important**
>
> Wait for the "Install Applications" and other remaining deployment steps to complete before proceeding.

---

**FOOBAR22 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls

$vmName = "TT-ADMIN02"
```

### # Move computer to different OU

```PowerShell
$targetPath = ("OU=Workstations,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

### # Set first boot device to hard drive

```PowerShell
$vmHost = "TT-HV05B"

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

### # Configure Windows Update

##### # Add machine to security group for Windows Update schedule

```PowerShell
Add-ADGroupMember -Identity "Windows Update - Slot 0" -Members ($vmName + '$')
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
```

### # Enable local Administrator account

```PowerShell
$Disabled = 0x0002
$adminUser.UserFlags.Value = $adminUser.UserFlags.Value -bxor $Disabled
$adminUser.SetInfo()
```

#### Reference

**Managing Local User Accounts with PowerShell**\
From <[https://mcpmag.com/articles/2015/05/07/local-user-accounts-with-powershell.aspx](https://mcpmag.com/articles/2015/05/07/local-user-accounts-with-powershell.aspx)>

### Login as .\\foo

### Configure storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 60 GB       | 4K                   | OSDisk       |

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

ping TT-DC10 -f -l 8900
```

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

## # Install Remote Server Administration Tools for Windows 10

```PowerShell
Get-WindowsCapability -Name Rsat* -Online | select DisplayName, State

Get-WindowsCapability -Name Rsat* -Online |
  where { $_.DisplayName -in @(
      "RSAT: Active Directory Domain Services and Lightweight Directory Services Tools",
      "RSAT: DNS Server Tools",
      "RSAT: Failover Clustering Tools",
      "RSAT: File Services Tools",
      "RSAT: Group Policy Management Tools",
      "RSAT: Server Manager",
      "RSAT: Windows Server Update Services Tools"
    ) } |
  Add-WindowsCapability -Online

Get-WindowsCapability -Name Rsat* -Online | select DisplayName, State
```

#### Reference

**Use PowerShell to Install the Remote Server Administration Tools (RSAT) on Windows 10 version 1809**\
From <[https://mikefrobbins.com/2018/10/03/use-powershell-to-install-the-remote-server-administration-tools-rsat-on-windows-10-version-1809/](https://mikefrobbins.com/2018/10/03/use-powershell-to-install-the-remote-server-administration-tools-rsat-on-windows-10-version-1809/)>

```PowerShell
cls
```

## # Turn on Hyper-V Management Tools

```PowerShell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Tools-All

Enable-WindowsOptionalFeature : One or several parent features are disabled so current
feature can not be enabled.
At line:1 char:1
+ Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V- ...
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [Enable-WindowsOptionalFeature], COMException
    + FullyQualifiedErrorId : Microsoft.Dism.Commands.EnableWindowsOptionalFeatureCommand
```

**Workaround:**

1. Open the **Start** menu and search for **Turn Windows features on or off**.
2. In the **Windows Features** dialog, expand **Hyper-V** and then select **Hyper-V Management Tools** and click **OK**.

```PowerShell
cls
```

## # Enable firewall rules for Disk Management

```PowerShell
Enable-NetFirewallRule -DisplayGroup "Remote Volume Management"
```

```PowerShell
cls
```

## # Install SharePoint Online Management Shell

```PowerShell
$installerPath = "\\TT-FS01\Public\Download\Microsoft\SharePoint\Online" `
    + "\SharePointOnlineManagementShell_9119-1200_x64_en-us.msi"

Start-Process `
    -FilePath msiexec.exe `
    -ArgumentList "/i `"$installerPath`"" `
    -Wait
```

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

```PowerShell
cls
```

## # Install Visual Studio Code

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$setupPath = "\\TT-FS01\Products\Microsoft\Visual Studio Code" `
    + "\VSCodeSetup-x64-1.37.1.exe"

$arguments = "/silent" `
    + " /mergetasks='!runcode,addcontextmenufiles,addcontextmenufolders" `
        + ",addtopath'"

Start-Process `
    -FilePath $setupPath `
    -ArgumentList $arguments `
    -Wait
```

> **Important**
>
> Wait for the installation to complete.

### Issue

**Installer doesn't disable launch of VScode even when installing with /mergetasks=!runcode**\
From <[https://github.com/Microsoft/vscode/issues/46350](https://github.com/Microsoft/vscode/issues/46350)>

### TODO: Modify Visual Studio Code shortcut to use custom extension and user data locations

```Console
"C:\Program Files\Microsoft VS Code\Code.exe" --extensions-dir "C:\NotBackedUp\vscode-data\extensions" --user-data-dir "C:\NotBackedUp\vscode-data\user-data"
```

## Install updates using Windows Update

> **Note**
>
> Repeat until there are no updates available for the computer.

## Baseline virtual machine

---

**FOOBAR22 - Run as administrator**

```PowerShell
cls
```

### # Checkpoint VM

```PowerShell
$vmHost = "TT-HV05B"
$vmName = "TT-ADMIN02"
$checkpointName = "Baseline"

Stop-VM -ComputerName $vmHost -Name $vmName

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName $checkpointName

Start-VM -ComputerName $vmHost -Name $vmName
```

---

```PowerShell
cls
```

## # Deploy Windows Admin Center

### # Download installation file for Windows Admin Center

```PowerShell
$installerPath = "$env:USERPROFILE\Downloads\WindowsAdminCenter.msi"

Invoke-WebRequest `
    -UseBasicParsing `
    -Uri https://aka.ms/WACDownload `
    -OutFile $installerPath
```

```PowerShell
cls
```

### # Install Windows Admin Center

```PowerShell
Start-Process -FilePath $installerPath -Wait
```

> **Important**
>
> Wait for the installation to complete.

---

**FOOBAR22 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Make virtual machine highly available

### # Migrate VM to shared storage

```PowerShell
$vmName = "TT-ADMIN02"

$vm = Get-SCVirtualMachine -Name $vmName
$vmHost = $vm.VMHost

Move-SCVirtualMachine `
    -VM $vm `
    -VMHost $vmHost `
    -HighlyAvailable $true `
    -Path "C:\ClusterStorage\iscsi02-Silver-01" `
    -UseDiffDiskOptimization
```

```PowerShell
cls
```

### # Allow migration to host with different processor version

```PowerShell
Stop-SCVirtualMachine -VM $vmName

Set-SCVirtualMachine -VM $vmName -CPULimitForMigration $true

Start-SCVirtualMachine -VM $vmName
```

---

## Configure backups

### Add virtual machine to Hyper-V protection group in DPM

## Delete VM baseline

```PowerShell
cls
```

## # Install Azure CLI

```PowerShell
Push-Location C:\NotBackedUp\Temp

Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi

Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'

Pop-Location
```

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

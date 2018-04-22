# FOOBAR16 - Windows 10 Enterprise (x64)

Sunday, April 22, 2018
10:00 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure workstation

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "FOOBAR16"
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
    -MemoryMinimumBytes 2GB `
    -MemoryMaximumBytes 4GB

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Install custom Windows 10 image

- On the **Task Sequence** step, select **Windows 10 Enterprise (x64)** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **FOOBAR16**.
  - Click **Next**.
- On the **Applications** step:
  - Select the following applications:
    - **Adobe Reader 8.3.1**
    - **Chrome (64-bit)**
    - **Firefox (64-bit)**
  - Click **Next**.

> **Note**
>
> After the custom Windows 10 image is installed, the following message is displayed:\
> This user can't sign in because this account is currently disabled.\
> Click **OK** to acknowledge the local Administrator account is disabled by default in Windows 10.

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls

$vmName = "FOOBAR16"
```

### # Move computer to different OU

```PowerShell
$targetPath = ("OU=Workstations,OU=Resources,OU=Development" `
    + ",DC=corp,DC=technologytoolbox,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

### # Set first boot device to hard drive

```PowerShell
$vmHost = "TT-HV05C"

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
Add-ADGroupMember -Identity "Windows Update - Slot 21" -Members ($vmName + '$')
```

---

### Login as TECHTOOLBOX\\jjameson-admin

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

## # Install Remote Server Administration Tools for Windows 10

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$installerPath = "\\TT-FS01\Public\Download\Microsoft" `
    + "\Remote Server Administration Tools for Windows 10" `
    + "\WindowsTH-RSAT_WS2016-x64.msu"

Start-Process `
    -FilePath $installerPath `
    -Wait
```

> **Note**
>
> If prompted to restart the computer, click **Restart now**.

```PowerShell
cls
```

## # Turn on Hyper-V Management Tools

```PowerShell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Tools-All

Enable-WindowsOptionalFeature : One or several parent features are disabled so current
feature can not be enabled.
At line:4 char:1
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

## # Install Microsoft .NET Framework 3.5

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
Enable-WindowsOptionalFeature `
    -Online `
    -FeatureName NetFx3 `
    -All `
    -LimitAccess `
    -Source "\\TT-FS01\Products\Microsoft\Windows 10\Sources\SxS"
```

## # Install Microsoft Report Viewer 2012 (for WSUS console)

#### # Install Microsoft System CLR Types for SQL Server 2012 (dependency for Report Viewer 2012)

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\SQL Server 2012\Feature Pack" `
    + "\System CLR Types for SQL Server 2012\x64\SQLSysClrTypes.msi"

$arguments = "/i `"$installerPath`" /qr"

Start-Process `
    -FilePath 'msiexec.exe' `
    -ArgumentList $arguments `
    -Wait
```

#### # Install Microsoft Report Viewer 2012

```PowerShell
$installerPath = '\\TT-FS01\Products\Microsoft\Report Viewer 2012 Runtime' `
    + '\ReportViewer.msi'

$arguments = "/i `"$installerPath`" /qr"

Start-Process `
    -FilePath 'msiexec.exe' `
    -ArgumentList $arguments `
    -Wait
```

## # Install SQL Server 2016 Management Studio

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\SQL Server 2016" `
    + "\SSMS-Setup-ENU-13.0.16106.4.exe"

Start-Process `
    -FilePath $installerPath `
    -Wait
```

## # Install SQL Server 2017 Management Studio

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\SQL Server 2017" `
    + "\SSMS-Setup-ENU-14.0.17230.0.exe"

Start-Process `
    -FilePath $installerPath `
    -Wait
```

## # Install System Center 2016 management tools

### # Install prerequisites for Operations console

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
cls
```

#### # Install Microsoft System CLR Types for SQL Server 2014

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\System Center 2016" `
    + "\Microsoft CLR Types for SQL Server 2014\SQLSysClrTypes.msi"

$arguments = "/i `"$installerPath`" /qr"

Start-Process `
    -FilePath 'msiexec.exe' `
    -ArgumentList $arguments `
    -Wait
```

#### # Install Microsoft Report Viewer 2015 Runtime

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\System Center 2016" `
    + "\Microsoft Report Viewer 2015 Runtime\ReportViewer.msi"

$arguments = "/i `"$installerPath`" /qr"

Start-Process `
    -FilePath 'msiexec.exe' `
    -ArgumentList $arguments `
    -Wait
```

### # Install Operations Manager - Operations console

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\System Center 2016\SCOM\Setup.exe"

$arguments = "/silent /install /components:OMConsole" `
    + " /AcceptEndUserLicenseAgreement:1 /EnableErrorReporting:Always" `
    + " /SendCEIPReports:1 /UseMicrosoftUpdate:1"

Start-Process `
    -FilePath $installerPath `
    -ArgumentList $arguments `
    -Wait
```

### # Install prerequisites for DPM Central Console

#### # Install Visual C++ 2008 Redistributable

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\System Center 2016\DPM\Redist\vcredist" `
    + "\vcredist2008_x64.exe"

$arguments = '/q'

Start-Process `
    -FilePath $installerPath `
    -ArgumentList $arguments `
    -Wait
```

#### # Install Visual C++ 2010 Redistributable

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\System Center 2016\DPM\Redist\vcredist" `
    + "\vcredist2010_x64.exe"

$arguments = '/q'

Start-Process `
    -FilePath $installerPath `
    -ArgumentList $arguments `
    -Wait
```

### Install DPM Central Console

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3B/1B4982EC38A2F66781A20AA9CF06F7BE9446B13B.png)

```PowerShell
cls
```

#### # Add setup account to local Administrators group

```PowerShell
$domain = "TECHTOOLBOX"
$username = "setup-systemcenter"

([ADSI]"WinNT://./Administrators,group").Add(
    "WinNT://$domain/$username,user")

logoff
```

---

**FOOBAR11**

```PowerShell
cls
```

##### # Enable domain account for System Center setup

```PowerShell
Enable-ADAccount setup-systemcenter
```

---

#### Login as TECHTOOLBOX\\setup-systemcenter

#### # Install DPM Central Console

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\System Center 2016\DPM\Setup.exe"

$arguments = '/i /cc /client'

Start-Process `
    -FilePath $installerPath `
    -ArgumentList $arguments `
    -Wait

# logoff
```

#### # Login as .\\foo

### Install Virtual Machine Manager console

![(screenshot)](https://assets.technologytoolbox.com/screenshots/29/11C45DCF357EF83E15D23091430EFBA9AA3A8629.png)

#### Login as TECHTOOLBOX\\setup-systemcenter

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\System Center 2016\VMM\setup.exe"

$arguments = '/client /i /IACCEPTSCEULA'

Start-Process `
    -FilePath $installerPath `
    -ArgumentList $arguments `
    -Wait

logoff
```

---

**FOOBAR11**

```PowerShell
cls
```

##### # Disable domain account for System Center setup

```PowerShell
Disable-ADAccount setup-systemcenter
```

---

## Install System Center Configuration Manager Toolkit

### Login as .\\foo

### # Install Configuration Manager Toolkit

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\System Center 2012 R2" `
    + "\System Center 2012 R2 Configuration Manager Toolkit" `
    + "\ConfigMgrTools.msi"

$arguments = "/i `"$installerPath`" /qr"

Start-Process `
    -FilePath 'msiexec.exe' `
    -ArgumentList $arguments `
    -Wait
```

```PowerShell
cls
```

## # Install Visual Studio 2017

### # Launch Visual Studio 2017 setup

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
cls
$installerPath = "\\TT-FS01\Products\Microsoft\Visual Studio 2017\Enterprise" `
    + "\vs_enterprise__118076627.1524070032.exe"

Start-Process `
    -FilePath $installerPath `
    -Wait
```

Select the following workloads:

- **.NET desktop development**
- **ASP.NET and web development**
- **Office/SharePoint development**

## Install updates using Windows Update

> **Note**
>
> Repeat until there are no updates available for the computer.

## Make virtual machine highly available

---

**FOOBAR11**

```PowerShell
cls
$vm = Get-SCVirtualMachine -Name "FOOBAR16"

Stop-SCVirtualMachine -VM $vm

Move-SCVirtualMachine `
    -VM $vm `
    -VMHost $vm.HostName `
    -HighlyAvailable $true `
    -Path "C:\ClusterStorage\iscsi02-Silver-02" `
    -UseDiffDiskOptimization

Start-SCVirtualMachine -VM $vm
```

---

## Add virtual machine to Hyper-V protection group in DPM

**TODO:**

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

## Activate Microsoft Office

1. Start Word 2016
2. Enter product key

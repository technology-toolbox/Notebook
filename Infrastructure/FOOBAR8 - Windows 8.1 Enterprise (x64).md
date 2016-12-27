# FOOBAR8 - Windows 8.1 Enterprise (x64)

Monday, December 26, 2016
9:24 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

---

**BEAST - Run as TECHTOOLBOX\\jjameson-admin**

### # Create virtual machine (FOOBAR8)

```PowerShell
$vmHost = "BEAST"
$vmName = "FOOBAR8"

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path C:\NotBackedUp\VMs `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 35GB `
    -MemoryStartupBytes 2GB `
    -SwitchName "Production"

Set-VM `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ProcessorCount 2 `
    -DynamicMemory `
    -MemoryMinimumBytes 256MB `
    -MemoryMaximumBytes 4GB

Set-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path \\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Install custom Windows 8.1 image

- Start-up disk: [\\\\ICEMAN\\Products\\Microsoft\\MDT-Deploy-x86.iso](\\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso)
- On the **Task Sequence** step, select **Windows 8.1 Enterprise (x64)** and click **Next**.
- On the **Computer Details** step, in the **Computer name** box, type **FOOBAR8** and click **Next**.
- On the Applications step:
  - Select the following items:
    - Adobe
      - **Adobe Reader 8.3.1**
    - Google
      - **Chrome**
    - Mozilla
      - **Firefox 50.1.0**
      - **Thunderbird 38.7.0**
  - Click **Next**.

#### # Copy latest Toolbox content

```PowerShell
net use \\ICEMAN\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```Console
robocopy \\ICEMAN\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E /MIR
```

#### # Rename local Administrator account and set password

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

#### Login as FOOBAR8\\foo

---

**BEAST - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Remove disk from virtual CD/DVD drive

```PowerShell
Set-VMDvdDrive -ComputerName BEAST -VMName FOOBAR8 -Path $null
```

---

```PowerShell
cls
```

## # Change drive letter for DVD-ROM

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
```

## # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

## # Install Remote Server Administration Tools for Windows 8.1

```PowerShell
net use \\ICEMAN\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
& '\\ICEMAN\Public\Download\Microsoft\Remote Server Administration Tools for Windows 8.1\Windows8.1-KB2693643-x64.msu'
```

> **Note**
>
> When prompted to install the update, click **Yes**.

```PowerShell
cls
```

## # Turn on Hyper-V Management Tools

```PowerShell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Tools-All

Enable-WindowsOptionalFeature : One or several parent features are disabled so current feature can not be enabled.
At line:1 char:1
+ Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Tools-All
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

## # Install Microsoft Report Viewer 2008 (for WSUS console)

```PowerShell
$installerPath = '\\ICEMAN\Public\Download\Microsoft\Report Viewer 2008 SP1' `
    + '\ReportViewer.exe'

$arguments = "/q"

Start-Process `
    -FilePath $installerPath `
    -ArgumentList $arguments `
    -Wait
```

```PowerShell
cls
```

## # Install SQL Server 2014 Management Tools - Complete

```PowerShell
$imagePath = '\\ICEMAN\Products\Microsoft\SQL Server 2014' `
    + '\en_sql_server_2014_enterprise_edition_x64_dvd_3932700.iso'

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$arguments = '/Q /ACTION=Install /FEATURES=ADV_SSMS' `
    + ' /IACCEPTSQLSERVERLICENSETERMS'

Start-Process `
    -FilePath "$imageDriveLetter`:\Setup.exe" `
    -ArgumentList $arguments `
    -Wait
```

> **Note**
>
> It may take several minutes for the installation to complete

```PowerShell
Restart-Computer
```

## # Install Systems Center 2012 R2 management tools

### # Install prerequisites for Operations console

```PowerShell
net use \\ICEMAN\ipc$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

#### # Microsoft System CLR Types for SQL Server 2012

```PowerShell
$msiPath = '\\ICEMAN\Products\Microsoft\SQL Server 2012\Feature Pack' `
    + '\System CLR Types for SQL Server 2012\x64\SQLSysClrTypes.msi'

$arguments = "/i `"$msiPath`" /qr"

Start-Process `
    -FilePath 'msiexec.exe' `
    -ArgumentList $arguments `
    -Wait
```

```PowerShell
cls
```

#### # Install Microsoft Report Viewer 2012 Runtime

```PowerShell
$msiPath = '\\ICEMAN\Public\Download\Microsoft\Report Viewer 2012 Runtime' `
    + '\ReportViewer.msi'

$arguments = "/i `"$msiPath`" /qr"

Start-Process `
    -FilePath 'msiexec.exe' `
    -ArgumentList $arguments `
    -Wait
```

```PowerShell
cls
```

### # Install Operations Manager - Operations console

```PowerShell
$imagePath = '\\ICEMAN\Products\Microsoft\System Center 2012 R2' `
    + '\en_system_center_2012_r2_operations_manager_x86_and_x64_dvd_2920299.iso'

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$arguments = '/silent /install /components:OMConsole' `
    + ' /AcceptEndUserLicenseAgreement:1 /EnableErrorReporting:Always' `
    + ' /SendCEIPReports:1 /UseMicrosoftUpdate:1'

Start-Process `
    -FilePath ("$imageDriveLetter`:\Setup.exe") `
    -ArgumentList $arguments `
    -Wait

Dismount-DiskImage -ImagePath $imagePath
```

```PowerShell
cls
```

### # Install prerequisites for DPM Central Console

#### # Install Visual C++ 2008 Redistributable

```PowerShell
$imagePath = '\\ICEMAN\Products\Microsoft\System Center 2012 R2' `
    + '\mu_system_center_2012_r2_data_protection_manager_x86_and_x64_dvd_2945939.iso'

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$arguments = '/q'

Start-Process `
    -FilePath ("$imageDriveLetter`:\SCDPM\Redist\vcredist" `
        + '\vcredist2008_x64.exe') `
    -ArgumentList $arguments `
    -Wait

Dismount-DiskImage -ImagePath $imagePath
```

### Install DPM Central Console

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3B/1B4982EC38A2F66781A20AA9CF06F7BE9446B13B.png)

#### Create domain account for System Center setup

---

**XAVIER1**

##### # Create OU for setup accounts

```PowerShell
New-ADOrganizationalUnit `
    -Name "Setup Accounts" `
    -Path "OU=IT,DC=corp,DC=technologytoolbox,DC=com"
```

##### # Create setup account

```PowerShell
$displayName = "Setup account for Microsoft System Center"
$defaultUserName = "setup-systemcenter"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@corp.technologytoolbox.com"
$orgUnit = "OU=Setup Accounts,OU=IT,DC=corp,DC=technologytoolbox,DC=com"

New-ADUser `
    -Name $displayName `
    -DisplayName $displayName `
    -SamAccountName $cred.UserName `
    -AccountPassword $cred.Password `
    -UserPrincipalName $userPrincipalName `
    -Path $orgUnit `
    -Enabled:$true `
    -CannotChangePassword:$true `
    -PasswordNeverExpires:$true
```

---

#### # Add setup account to local Administrators group

```PowerShell
net localgroup Administrators /add TECHTOOLBOX\setup-systemcenter
```

#### Login as TECHTOOLBOX\\setup-systemcenter

#### # Install DPM Central Console

```PowerShell
$imagePath = '\\ICEMAN\Products\Microsoft\System Center 2012 R2' `
    + '\mu_system_center_2012_r2_data_protection_manager_x86_and_x64_dvd_2945939.iso'

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$arguments = '/i /cc /client'

Start-Process `
    -FilePath ("$imageDriveLetter`:\SCDPM\Setup.exe") `
    -ArgumentList $arguments `
    -Wait

Dismount-DiskImage -ImagePath $imagePath

logoff
```

#### Login as FOOBAR8\\foo

### Install Virtual Machine Manager console

![(screenshot)](https://assets.technologytoolbox.com/screenshots/29/11C45DCF357EF83E15D23091430EFBA9AA3A8629.png)

#### Login as TECHTOOLBOX\\setup-systemcenter

```PowerShell
cls

$imagePath = '\\ICEMAN\Products\Microsoft\System Center 2012 R2' `
    + '\mu_system_center_2012_r2_virtual_machine_manager_x86_and_x64_dvd_2913737.iso'

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$arguments = '/client /i /IACCEPTSCEULA'

Start-Process `
    -FilePath ("$imageDriveLetter`:\Setup.exe") `
    -ArgumentList $arguments `
    -Wait

Dismount-DiskImage -ImagePath $imagePath

logoff
```

#### Login as FOOBAR8\\foo

## Update Hyper-V Integration Services

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

1. Start Word 2013
2. Enter product key

## Install updates using Windows Update

> **Note**
>
> Repeat until there are no updates available for the computer.

## # Clean up the WinSxS folder

### Before

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8B/336E49D02E6DA4755F19A87F5CE065FEF9A1E58B.png)

```Console
Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase
```

### After

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C2/10147AC453583CC4386ACAB4BCAA7C8BD0C03DC2.png)

```PowerShell
cls
```

## # Delete C:\\Windows\\SoftwareDistribution folder (2.87 GB)

### # Before

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C2/10147AC453583CC4386ACAB4BCAA7C8BD0C03DC2.png)

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse
```

### After

![(screenshot)](https://assets.technologytoolbox.com/screenshots/52/502088C36C9B45D0354CB76EC1B4993B0252C452.png)

## Snapshot VM

---

**BEAST - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
$vmHost = "BEAST"
$vmName = "FOOBAR8"
```

### # Specify configuration in VM notes

```PowerShell
$notes = Get-VM -ComputerName $vmHost -VMName $vmName |
    select -ExpandProperty Notes

$newNotes = `
"Windows 8.1 Enterprise (x64)
Microsoft Office Professional Plus 2013 (x86)
Adobe Reader 8.3.1
Google Chrome
Mozilla Firefox 50.1.0
Mozilla Thunderbird 38.7.0
Remote Server Administration Tools for Windows 8.1
Hyper-V Management Tools enabled
SQL Server 2014 Management Tools - Complete
System Center 2012 R2 Operations Manager - Operations console
System Center 2012 R2 Data Protection Manager Central Console
System Center 2012 R2 Virtual Machine Manager console" `
    + [System.Environment]::NewLine `
    + [System.Environment]::NewLine `
    + $notes

Set-VM `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Notes $newNotes
```

### # Shutdown VM

```PowerShell
Stop-VM -ComputerName $vmHost -VMName $vmName
```

### # Remove disk from virtual CD/DVD drive

```PowerShell
Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

### # Snapshot VM - "Baseline"

```PowerShell
$snapshotName = "Baseline"

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName $snapshotName
```

---

**TODO:**

## Fix issue with VMM console

### Issue

When you open the VMM console, you receive the following error message:

Could not update managed code add-in pipeline due to the following error:

The required folder "C:\\Program Files\\Microsoft System Center 2012\\Virtual Machine Manager\\bin\\AddInPipeline\\HostSideAdapters" does not exist.

### Reference

**Description of Update Rollup 1 for System Center 2012 Service Pack 1**\
From <[https://support.microsoft.com/en-us/kb/2785682](https://support.microsoft.com/en-us/kb/2785682)>

### Resolution

To resolve the issue, follow these steps:

1. Locate the following folder:

**C:\\Program Files\\Microsoft System Center 2012 R2\\Virtual Machine Manager\\bin**
2. Right-click the **AddInPipeline** folder, and then click **Properties**.
3. On the **Security** tab, click **Advanced**, and then click **Continue**.
4. Select the **BUILTIN** group, and then click **Edit**.
5. Click the **Select a principal** link, type **Authenticated Users**, and then click **OK**.
6. Click **OK** to close each dialog box that is associated with the properties.

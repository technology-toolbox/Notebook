# FOOBAR10 - Windows 10 Enterprise (x64)

Tuesday, March 28, 2017
12:53 PM

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
$vmHost = "TT-HV02C"
$vmName = "FOOBAR10"
$vmPath = "C:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 50GB `
    -MemoryStartupBytes 4GB `
    -SwitchName "Embedded Team Switch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 2

Set-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path C:\NotBackedUp\Products\Microsoft\MDT-Deploy-x64.iso

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Install custom Windows 10 image

- On the **Task Sequence** step, select **Windows 10 Enterprise (x64)** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **FOOBAR10**.
  - Click **Next**.
- On the **Applications** step:
  - Select the following applications:
    - **Adobe Reader 8.3.1**
    - **Chrome**
    - **Firefox 50.1.0**
  - Click **Next**.

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Remove disk from virtual CD/DVD drive

```PowerShell
$vmHost = "TT-HV02C"
$vmName = "FOOBAR10"

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

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Move computer to different OU

```PowerShell
$vmName = "FOOBAR10"

$targetPath = ("OU=Workstations,OU=Resources,OU=Development" `
    + ",DC=corp,DC=technologytoolbox,DC=com")

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
| 0    | C:           | 50 GB       | 4K                   | OSDisk       |

```PowerShell
cls
```

### # Change drive letter for DVD-ROM

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
```

## # Install Remote Server Administration Tools for Windows 10

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
& "\\TT-FS01\Public\Download\Microsoft\Remote Server Administration Tools for Windows 10\WindowsTH-RSAT_WS2016-x64.msu"
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
$msiPath = "\\TT-FS01\Products\Microsoft\SQL Server 2012\Feature Pack" `
    + "\System CLR Types for SQL Server 2012\x64\SQLSysClrTypes.msi"

$arguments = "/i `"$msiPath`" /qr"

Start-Process `
    -FilePath 'msiexec.exe' `
    -ArgumentList $arguments `
    -Wait
```

#### # Install Microsoft Report Viewer 2012

```PowerShell
$msiPath = '\\TT-FS01\Public\Download\Microsoft\Report Viewer 2012 Runtime' `
    + '\ReportViewer.msi'

$arguments = "/i `"$msiPath`" /qr"

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
$installerPath = "\\TT-FS01\Products\Microsoft\SQL Server 2016\SSMS-Setup-ENU.exe"

Start-Process `
    -FilePath $installerPath `
    -Wait
```

## # Install Systems Center 2016 management tools

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
$msiPath = "\\TT-FS01\Products\Microsoft\System Center 2016" `
    + "\Microsoft CLR Types for SQL Server 2014\SQLSysClrTypes.msi"

$arguments = "/i `"$msiPath`" /qr"

Start-Process `
    -FilePath 'msiexec.exe' `
    -ArgumentList $arguments `
    -Wait
```

#### # Install Microsoft Report Viewer 2015 Runtime

```PowerShell
$msiPath = "\\TT-FS01\Products\Microsoft\System Center 2016" `
    + "\Microsoft Report Viewer 2015 Runtime\ReportViewer.msi"

$arguments = "/i `"$msiPath`" /qr"

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

```PowerShell
cls
```

#### # Add setup account to local Administrators group

```PowerShell
$domain = "TECHTOOLBOX"
$username = "setup-systemcenter"

([ADSI]"WinNT://./Administrators,group").Add(
    "WinNT://$domain/$username,user")
```

#### Login as TECHTOOLBOX\\setup-systemcenter

#### # Install DPM Central Console

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\System Center 2016\DPM\Setup.exe"

$arguments = '/i /cc /client'

Start-Process `
    -FilePath $installerPath `
    -ArgumentList $arguments `
    -Wait

logoff
```

#### Login as .\\foo

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

#### Login as .\\foo

## # Install Microsoft Office 2016

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
cls
$imagePath = "\\TT-FS01\Products\Microsoft\Office 2016" `
    + "\en_office_professional_plus_2016_x86_x64_dvd_6962141.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$installerPath = "$imageDriveLetter`:\setup.exe"

Push-Location "$imageDriveLetter`:\"

Start-Process `
    -FilePath $installerPath `
    -Wait

Pop-Location

Dismount-DiskImage -ImagePath $imagePath
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
    + "\vs_enterprise__1167797576.1490649074.exe"

Start-Process `
    -FilePath $installerPath `
    -Wait
```

Select the following workloads:

- **.NET desktop development**
- **ASP.NET and web development**
- **Office/SharePoint development**

```PowerShell
cls
```

## # Install Check Point VPN client

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$msiPath = "\\TT-FS01\Archive\Clients\Securitas\Check_Point_VPN_client" `
    + "\Securitas USA VPN E80.62 Build 452.msi"

$arguments = "/i `"$msiPath`" /qr"

Start-Process `
    -FilePath 'msiexec.exe' `
    -ArgumentList $arguments `
    -Wait
```

> **Note**
>
> When prompted, restart the computer to complete the installation.

## Login as .\\foo

## # Install Team Foundation Server Integration Tools (March 2012 Release)

### # Add TFS service account to the local Administrators group

```PowerShell
$domain = "TECHTOOLBOX"
$username = "svc-tfs"

([ADSI]"WinNT://./Administrators,group").Add(
    "WinNT://$domain/$username,user")
```

### # Install Team Explorer 2010

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$imagePath = '\\TT-FS01\Products\Microsoft\Visual Studio 2010' `
    + '\en_visual_studio_team_explorer_2010_x86_dvd_509698.iso'

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

Start-Process `
    -FilePath "$imageDriveLetter`:\setup.exe" `
    -Wait

Dismount-DiskImage -ImagePath $imagePath
```

### # Install Team Explorer 2012

```PowerShell
$imagePath = '\\TT-FS01\Products\Microsoft\Visual Studio 2012' `
    + '\en_team_explorer_for_visual_studio_2012_x86_dvd_921038.iso'

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

Start-Process `
    -FilePath "$imageDriveLetter`:\vs_teamExplorer.exe" `
    -Wait
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/02/DC91550586E4CF6143806056086329E222598802.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DD/4FEA005C13861DA4BFFFE3D7D551BCBB028B13DD.png)

Click **INSTALL**.

UAC -> click **OK**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F0/4AC9DE14AC57036C04C831C1C69235CFFB53DFF0.png)

Click **LAUNCH**.

```PowerShell
Dismount-DiskImage -ImagePath $imagePath
```

### Install Visual Studio 2012 Update 5

1. Open Visual Studio.
2. On the **TOOLS** menu, click **Extensions and Updates**.
3. In the **Extensions and Updates** window, click **Updates**.
4. In the **Visual Studio 2012 Update 5** item, click **Update**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/46/1BAE0D9BCF48AAC0178C64847226746215A9D446.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EE/B70BBF35264EF6FCF30733542A8F65B591CB1EEE.png)

> **Note**
>
> If prompted to restart the computer, click **Restart now**.

### Login as TECHTOOLBOX\\svc-tfs

```PowerShell
cls
```

### # Install TFS Integation Tools

```PowerShell
$msiPath = "\\TT-FS01\Public\Download\Microsoft" `
    + "\TFS Integration Tools (March 2012)\TFSIntegrationTools.msi"

$arguments = "/i `"$msiPath`""

Start-Process `
    -FilePath 'msiexec.exe' `
    -ArgumentList $arguments `
    -Wait
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2E/D74C9ED403CF4A1C9AFD266FB33B551290809D2E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8E/77A9F6C6C496EB60F62B649CDE236D6854D11B8E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4B/941E1A768BB914C23C54769C6197964C26DC3F4B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3E/F2CA6164A62CDEF045C9D1E6D17128F2320F913E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/74/D0C32112954749D82BB0E39B353D741B2D889574.png)

#### Issue

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BC/9C6C1B725C38F6A5583DE67F594F70E9E39030BC.png)

#### Solution

---

**HAVOK - SQL Server Management Studio**

##### -- Temporarily add TECHTOOLBOX\\svc-tfs to db

```SQL
ALTER SERVER ROLE [dbcreator] ADD MEMBER [TECHTOOLBOX\svc-tfs]
```

---

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E9/405B71E89649E7720F589C7533774CA436F018E9.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/33/3DCF1D2C6C58DCDB7A6726E7DE6BF08094E6F433.png)

---

**HAVOK - SQL Server Management Studio**

##### -- Remove TECHTOOLBOX\\svc-tfs from dbcreator role

```SQL
ALTER SERVER ROLE [dbcreator] DROP MEMBER [TECHTOOLBOX\svc-tfs]
```

---

```Console
logoff
```

### Login as .\\foo

## Fix permissions issue with TFS Integration

### Issue

System.UnauthorizedAccessException: Access to the path 'C:\\Program Files (x86)\\Microsoft Team Foundation Server Integration Tools\\17559.txt' is denied.\
   at System.IO.__Error.WinIOError(Int32 errorCode, String maybeFullPath)\
   at System.IO.FileStream.Init(String path, FileMode mode, FileAccess access, Int32 rights, Boolean useRights, FileShare share, Int32 bufferSize, FileOptions options, SECURITY_ATTRIBUTES secAttrs, String msgPath, Boolean bFromProxy)\
   at System.IO.FileStream..ctor(String path, FileMode mode, FileAccess access, FileShare share, Int32 bufferSize, FileOptions options)\
   at System.IO.StreamWriter.CreateFile(String path, Boolean append)\
   at System.IO.StreamWriter..ctor(String path, Boolean append, Encoding encoding, Int32 bufferSize)\
   at System.IO.StreamWriter..ctor(String path)\
   at Microsoft.TeamFoundation.Migration.Tfs2010VCAdapter.TfsVCMigrationProvider.codeReview(IEnumerable`1 pendChanges, Int32 changeset, HashSet`1 implicitRenames, HashSet`1 implicitAdds, HashSet`1 skippedActions, Int32& changeCount, Boolean autoResolve)\
   at Microsoft.TeamFoundation.Migration.Tfs2010VCAdapter.TfsVCMigrationProvider.Checkin(ChangeGroup group, HashSet`1 implicitRenames, HashSet`1 implicitAdds, HashSet`1 skippedActions, Int32& changesetId)\
   at Microsoft.TeamFoundation.Migration.Tfs2010VCAdapter.TfsVCMigrationProvider.ProcessChangeGroup(ChangeGroup group)

### Solution

#### # Grant "Modify" permissions to service account used to run TFS Integration

```PowerShell
icacls 'C:\Program Files (x86)\Microsoft Team Foundation Server Integration Tools' `
    /grant TECHTOOLBOX\svc-tfs:`(OI`)`(CI`)`(M`)
```

## Install updates using Windows Update

**Note:** Repeat until there are no updates available for the computer.

## # Enter a product key and activate Windows

```PowerShell
slmgr /ipk {product key}
```

**Note:** When notified that the product key was set successfully, click **OK**.

```Console
slmgr /ato
```

## Activate Microsoft Office

1. Start Word 2016
2. Enter product key

## Make virtual machine highly available

---

**TT-VMM01A**

```PowerShell
$vm = Get-SCVirtualMachine -Name "FOOBAR10"
$vmHost = Get-SCVMHost -ComputerName "TT-HV02C.corp.technologytoolbox.com"

Stop-SCVirtualMachine -VM $vm

Move-SCVirtualMachine `
    -VM $vm `
    -VMHost $vmHost `
    -HighlyAvailable $true `
    -Path "\\TT-SOFS01.corp.technologytoolbox.com\VM-Storage-Silver" `
    -UseDiffDiskOptimization

Start-SCVirtualMachine -VM $vm
```

---

## Add virtual machine to Hyper-V protection group in DPM

**TODO:**

## Install dependencies for building SharePoint solutions

### Install reference assemblies

```Console
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```Console
robocopy `
    '\\TT-FS01\Builds\Reference Assemblies' `
    'C:\Program Files\Reference Assemblies' /E

& 'C:\Program Files\Reference Assemblies\Microsoft\SharePoint v4\AssemblyFoldersEx - x64.reg'

& 'C:\Program Files\Reference Assemblies\Microsoft\SharePoint v5\AssemblyFoldersEx - x64.reg'
```

**TODO:**

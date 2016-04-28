# FOOBAR10 - Windows 10 Enterprise (x64)

Wednesday, April 27, 2016
12:58 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

### # Create virtual machine

```PowerShell
$vmHost = "WOLVERINE"
$vmName = "FOOBAR10"

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path C:\NotBackedUp\VMs `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 50GB `
    -MemoryStartupBytes 8GB `
    -SwitchName "Production"

Set-VM `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ProcessorCount 4

Set-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path ("\\ICEMAN\Products\Microsoft\Windows 10" `
        + "\en_windows_10_enterprise_version_1511_x64_dvd_7224901.iso")

Start-VM -ComputerName $vmHost -Name $vmName
```

---

## Install Windows 10

### Customize settings

Turn all options off _except_:

- **Browser, protection, and update**

### Join a domain

### Çreate an account for this PC

In the **Who's going to use this PC?** box, type **foo**.

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

## # Remove disk from virtual CD/DVD drive

```PowerShell
$vmHost = "WOLVERINE"
$vmName = "FOOBAR10"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

---

## Login as FOOBAR10\\foo

## # Set time zone

```PowerShell
tzutil /s "Mountain Standard Time"
```

```PowerShell
cls
```

## # Configure network settings

### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select Name, InterfaceDescription

Get-NetAdapter `
    -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "Production"
```

```PowerShell
cls
```

### # Configure "Production" network adapter

```PowerShell
$interfaceAlias = "Production"
```

```PowerShell
cls
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping ICEMAN -f -l 8900
```

```PowerShell
cls
```

## # Rename the computer and join domain

```PowerShell
Rename-Computer -NewName FOOBAR10 -Restart
```

Wait for the VM to restart and then execute the following command to join the **TECHTOOLBOX **domain:

```PowerShell
Add-Computer -DomainName corp.technologytoolbox.com -Restart
```

## Move computer to "Workstations" OU

---

**FOOBAR8 - TECHTOOLBOX\\jjameson-admin**

```PowerShell
$computerName = "FOOBAR10"
$targetPath = ("OU=Workstations,OU=Resources,OU=Development" `
    + ",DC=corp,DC=technologytoolbox,DC=com")

Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath
```

---

## Login as FOOBAR10\\foo

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

## # Configure firewall rules for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
New-NetFirewallRule `
    -Name 'Remote Windows Update (Dynamic RPC)' `
    -DisplayName 'Remote Windows Update (Dynamic RPC)' `
    -Description 'Allows remote auditing and installation of Windows updates via POSHPAIG (http://poshpaig.codeplex.com/)' `
    -Group 'Technology Toolbox (Custom)' `
    -Program '%windir%\system32\dllhost.exe' `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort RPC `
    -Profile Domain `
    -Action Allow
```

## # Disable firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
Disable-NetFirewallRule -Name 'Remote Windows Update (Dynamic RPC)'
```

```PowerShell
cls
```

## # Copy Toolbox content

```PowerShell
net use \\ICEMAN\ipc$ /USER:TECHTOOLBOX\jjameson

robocopy \\ICEMAN\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E
```

```PowerShell
cls
```

## # Install Remote Server Administration Tools for Windows 10

```PowerShell
net use \\ICEMAN\ipc$ /USER:TECHTOOLBOX\jjameson

& "\\ICEMAN\Public\Download\Microsoft\Remote Server Administration Tools for Windows 10\WindowsTH-KB2693643-x64.msu"
```

**Note:** If prompted to restart the computer, click **Restart now**.

## Login as FOOBAR10\\foo

```PowerShell
cls
```

## # Turn on Hyper-V Management Tools

```PowerShell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Tools-All

Enable-WindowsOptionalFeature : One or several parent features are disabled so current
feature can not be enabled.
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

## # Install Microsoft .NET Framework 3.5

```PowerShell
Enable-WindowsOptionalFeature `
    -Online `
    -FeatureName NetFx3 `
    -All `
    -LimitAccess `
    -Source X:\sources\sxs
```

```PowerShell
cls
```

## # Install Microsoft Report Viewer 2008 (for WSUS console)

```PowerShell
net use \\ICEMAN\ipc$ /USER:TECHTOOLBOX\jjameson

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

**# Note:** It may take several minutes for the installation to complete

```PowerShell
Restart-Computer
```

## Login as FOOBAR10\\foo

## # Install Systems Center 2012 R2 management tools

### # Install prerequisites for Operations console

```PowerShell
net use \\ICEMAN\ipc$ /USER:TECHTOOLBOX\jjameson
```

```PowerShell
cls
```

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

#### Login as FOOBAR10\\foo

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

#### Login as FOOBAR10\\foo

```PowerShell
cls
```

## # Install Visual Studio 2015 with Update 2

**Note:** Windows Identity Foundation is a prerequisite for installing the Microsoft Office Developer Tools feature in Visual Studio 2015.

### # Install Windows Identity Foundation 3.5

```PowerShell
Enable-WindowsOptionalFeature -Online -FeatureName Windows-Identity-Foundation
```

---

**FOOBAR8**

### # Insert the Visual Studio 2015 installation media

```PowerShell
$vmHost = 'WOLVERINE'
$vmName = 'FOOBAR10'

$isoPath = ("\\ICEMAN\Products\Microsoft\Visual Studio 2015" `
    + "\en_visual_studio_enterprise_2015_with_update_2_x86_x64_dvd_8510142.iso")

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $isoPath
```

---

```PowerShell
cls
```

### # Launch Visual Studio 2015 with Update 2 setup

```PowerShell
& X:\vs_enterprise.exe
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C0/DFFBADD26A6DC71AE8E8001D97D10C37E681F0C0.png)

In the **Choose the type of installation** section, select **Custom**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/56/BE2D87F87D8B4AFDEBAAB83CAEC3295C8D37AB56.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1C/9C6F865F6F2574D97A92461A0B252256237DA41C.png)

Select the following features:

- Windows and Web Development
  - **Microsoft Office Developer Tools**
  - **Microsoft Web Developer Tools**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/62/4EF5EA0A0C129903C4279D1A8FC029B531F64062.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BA/03C15F9ECE8A7F66999273933327B34E641A1FBA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/33/4682FDA783F5F9335BACB5D1A4DB0094A9D85133.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/11/7C35627252E0711AA60751ED8892781237680711.png)

Click **LAUNCH**.

## Install Microsoft Office 2016

Insert installation media:

[\\\\ICEMAN\\Products\\Microsoft\\Office 2016\\en_office_professional_plus_2016_x86_x64_dvd_6962141.iso](\\ICEMAN\Products\Microsoft\Office 2016\en_office_professional_plus_2016_x86_x64_dvd_6962141.iso)

```PowerShell
cls
```

## # Install Adobe Reader 8.3.1

```PowerShell
net use \\ICEMAN\ipc$ /USER:TECHTOOLBOX\jjameson

& "\\ICEMAN\Products\Adobe\AdbeRdr830_en_US.msi"

& "\\ICEMAN\Products\Adobe\AdbeRdrUpd831_all_incr.msp"
```

```PowerShell
cls
```

## # Install Google Chrome

```PowerShell
& "\\ICEMAN\Products\Google\Chrome\ChromeStandaloneSetup64.exe"
```

```PowerShell
cls
```

## # Install Mozilla Firefox

```PowerShell
& "\\ICEMAN\Products\Mozilla\Firefox\Firefox Setup 46.0.exe" -ms
```

## Install updates using Windows Update

**Note:** Repeat until there are no updates available for the computer.

## Examine disk usage

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C5/B5102804865E764F95035C1DBDC89A3DE69603C5.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D7/E7259BF109597F294635D72CCBBFF7948F09FED7.png)

## # Clean up the WinSxS folder

### Before

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C5/B5102804865E764F95035C1DBDC89A3DE69603C5.png)

```Console
Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase
```

### After

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D9/E5DD31AAC2432F3B070FA53CC499BF3363308ED9.png)

```PowerShell
cls
```

## # Delete C:\\Windows\\SoftwareDistribution folder (3.2 GB)

### # Before

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D9/E5DD31AAC2432F3B070FA53CC499BF3363308ED9.png)

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse
```

### After

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F7/0CCCF21AB8382943FD7123C043143A06DCB9ACF7.png)

```PowerShell
cls
```

## # Shutdown VM

```PowerShell
Stop-Computer
```

## Checkpoint VM - "Baseline"

Windows 10 Enterprise (x64)\
Remote Server Administration Tools for Windows 10\
Hyper-V Management Tools enabled\
SQL Server 2014 Management Tools - Complete\
System Center 2012 R2 Operations Manager - Operations console\
System Center 2012 R2 Data Protection Manager Central Console\
System Center 2012 R2 Virtual Machine Manager console\
Visual Studio 2015 with Update 2\
Microsoft Office Professional Plus 2016 (x86)\
Adobe Reader 8.3.1\
Google Chrome\
Mozilla Firefox 46.0

```PowerShell
cls
```

## # Install Check Point VPN client

```PowerShell
net use \\ICEMAN\ipc$ /USER:TECHTOOLBOX\jjameson

& "\\ICEMAN\Archive\Clients\Securitas\Check_Point_VPN_client\Securitas USA VPN E80.62 Build 452.msi"
```

When prompted, restart the computer to complete the installation.

## Login as FOOBAR\\foo

## # Install Team Foundation Server Integration Tools (March 2012 Release)

### # Add TFS service account to the local Administrators group

```PowerShell
net localgroup Administrators /add TECHTOOLBOX\svc-tfs
```

### # Install Team Explorer 2010

```PowerShell
net use \\ICEMAN\ipc$ /USER:TECHTOOLBOX\jjameson

$imagePath = '\\ICEMAN\Products\Microsoft\Visual Studio 2010' `
    + '\en_visual_studio_team_explorer_2010_x86_dvd_509698.iso'

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

Start-Process `
    -FilePath "$imageDriveLetter`:\setup.exe" `
    -Wait

Dismount-DiskImage -ImagePath $imagePath
```

```PowerShell
cls
```

### # Install Team Explorer 2012

```PowerShell
$imagePath = '\\ICEMAN\Products\Microsoft\Visual Studio 2012' `
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

UAT -> click **OK**.

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

### Login as TECHTOOLBOX\\svc-tfs

```PowerShell
cls
```

### # Install TFS Integation Tools

```PowerShell
& "\\ICEMAN\Public\Download\Microsoft\TFS Integration Tools (March 2012)\TFSIntegrationTools.msi"
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

---

**FOOBAR8**

### # Delete VM checkpoint

```PowerShell
$checkpointName = "Baseline"
$vmHost = "WOLVERINE"
$vmName = "FOOBAR10"

Remove-VMSnapshot -ComputerName $vmHost -VMName $vmName -Name $checkpointName
```

---

### Login as FOOBAR10\\foo

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

## Move VM from WOLVERINE to BEAST

### Issue

Note that trying to use **Move-VM** (from FOOBAR8) did not work:

```PowerShell
Move-VM : The source host is not configured for live migration. Use the Enable-VMMigration cmdlet to modify the Hyper-V settings on the source host to enable migration.
```

Similarly, attempting to use Export-VM directly to [\\\\BEAST\\E\$\\NotBackedUp\\VMs](\\BEAST\E$\NotBackedUp\VMs) resulted in an "access denied" error.

### Workaround

Export the VM locally, copy the folder, and then import.

---

**WOLVERINE - TECHTOOLBOX\\jjameson-admin**

```PowerShell
Stop-VM -Name FOOBAR10

Export-VM FOOBAR10 -Path C:\NotBackedUp\VMs\Exports

robocopy C:\NotBackedUp\VMs\Exports\FOOBAR10 '\\BEAST\E$\NotBackedUp\VMs\FOOBAR10\' /E

Import-VM -ComputerName BEAST -Path E:\NotBackedUp\VMs\FOOBAR10 -Register
Import-VM : The Hyper-V module used in this Windows PowerShell session cannot be used for remote management of the server 'BEAST'. Load a compatible version of the Hyper-V module, or use Powershell remoting to connect directly to the remote server. For more information, see http://go.microsoft.com/fwlink/p/?LinkID=532650.
```

---

---

**FOOBAR8 - TECHTOOLBOX\\jjameson-admin**

```PowerShell
Import-VM -ComputerName BEAST -Path E:\NotBackedUp\VMs\FOOBAR10 -Register
Import-VM : The operation failed because the file was not found.
```

Ugh...just create a new VM and overwrite the VHD:

```PowerShell
Rename-Item '\\BEAST\E$\NotBackedUp\VMs\FOOBAR10' FOOBAR10-temp
```

### # Create virtual machine

```PowerShell
$vmHost = "BEAST"
$vmName = "FOOBAR10"

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path E:\NotBackedUp\VMs `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 50GB `
    -MemoryStartupBytes 4GB `
    -SwitchName "Production"

Set-VM `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ProcessorCount 2

Enter-PSSession BEAST
```

---

**BEAST**

```PowerShell
cd 'E:\NotBackedUp\VMs\FOOBAR10\Virtual Hard Disks'

icacls .\FOOBAR10.vhdx /save AclFile

Move-Item 'E:\NotBackedUp\VMs\FOOBAR10-temp\Virtual Hard Disks\FOOBAR10.vhdx' `
    'E:\NotBackedUp\VMs\FOOBAR10\Virtual Hard Disks' -Force

icacls . /restore AclFile

Start-VM FOOBAR10

Exit-PSSession
```

---

---

## Add FOOBAR10 to Hyper-V protection group in DPM

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

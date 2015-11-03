# FOOBAR10 - Windows 10 Enterprise (x64) LTSB

Tuesday, October 20, 2015
6:23 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Create VM

- Processors: **2**
- Startup memory: **2 GB**
- Minimum memory: **512 MB**
- Maximum memory: **4 GB**
- VHD size: 50** GB**
- VHD File name:** FOOBAR10**
- Virtual DVD drive: **[\\\\ICEMAN\\Products\\Microsoft\\Windows 10\\en_windows_10_enterprise_2015_ltsb_x64_dvd_6848446.iso](\\ICEMAN\Products\Microsoft\Windows 10\en_windows_10_enterprise_2015_ltsb_x64_dvd_6848446.iso)**

## # Set time zone

```PowerShell
tzutil /s "Mountain Standard Time"
```

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

## # Configure firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
Get-NetFirewallRule |
  Where-Object { `
    $_.Profile -eq 'Domain' `
      -and $_.DisplayName -like 'File and Printer Sharing (Echo Request *-In)' } |
  Enable-NetFirewallRule

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
Disable-NetFirewallRule -DisplayName 'Remote Windows Update (Dynamic RPC)'
```

```PowerShell
cls
```

## # Install Remote Server Administration Tools for Windows 10

```PowerShell
net use \\ICEMAN\ipc$ /USER:TECHTOOLBOX\jjameson

& "\\ICEMAN\Public\Download\Microsoft\Remote Server Administration Tools for Windows 10\WindowsTH-KB2693643-x64.msu"
```

**Note:** When prompted to restart the computer, click **Restart now**.

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

## # Install Visual Studio 2015

**Note:** Windows Identity Foundation is a prerequisite for installing the Microsoft Office Developer Tools feature in Visual Studio 2015.

### # Install Windows Identity Foundation 3.5

```PowerShell
Enable-WindowsOptionalFeature -Online -FeatureName Windows-Identity-Foundation
```

---

**FOOBAR8**

### # Insert the Visual Studio 2015 installation media

```PowerShell
$vmHost = 'STORM'
$vmName = 'FOOBAR10'

$isoPath = '\\ICEMAN\Products\Microsoft\Visual Studio 2015\en_visual_studio_enterprise_2015_x86_x64_dvd_6850497.iso'

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $isoPath
```

---

```PowerShell
cls
```

### # Launch Visual Studio 2015 setup

```PowerShell
& X:\vs_enterprise.exe
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4D/CB8D2970754D88629E3E6D51F1E4BDCAB8A0FD4D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/93/FECD5CD3DB25CEF8B7E376A92F71B45AC6C4EC93.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/30/6AB2199E908EAA655850B6D365791212FCDD3130.png)

Select the following features:

- Windows and Web Development
  - **Microsoft Office Developer Tools**
  - **Microsoft Web Developer Tools**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CA/65B2F28CB988A0CF60367E1CCF3606394A8CDFCA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4B/7F1B8CBAB3901BD011BBE30EE4C900CEC7D40D4B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2B/FA482E8FD5C26A618DAE0445EC9BF7B7C5F2172B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/37/B88BC8416B3FF3FFACACF45FD5FB4BC306EE0437.png)

## Install Microsoft Office 2016

## Install updates using Windows Update

**Note:** Repeat until there are no updates available for the computer.

## # Clean up the WinSxS folder

### Before

![(screenshot)](https://assets.technologytoolbox.com/screenshots/63/B89E8811E7DED1D9A0AC642C5445364502A77363.png)

```Console
Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase
```

### After

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1C/54143530574ED72F553DA0623F6D01F856F2FE1C.png)

```PowerShell
cls
```

## # Delete C:\\Windows\\SoftwareDistribution folder (1.6 GB)

### # Before

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1C/54143530574ED72F553DA0623F6D01F856F2FE1C.png)

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse
```

### After

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D8/BC704F355BDA6DEFCC7A88A2AC933E27788C53D8.png)

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

Cls
```

## # Install Mozilla Firefox

```PowerShell
& "\\ICEMAN\Products\Mozilla\Firefox\Firefox Setup 40.0.2.exe" -ms
```

```PowerShell
cls
```

## # Shutdown VM

```PowerShell
Stop-Computer
```

## Checkpoint VM - "Baseline"

Windows 10 Enterprise (x64) LTSB\
Visual Studio 2015\
Microsoft Office Professional Plus 2016 (x86)\
Adobe Reader 8.3.1\
Google Chrome\
Mozilla Firefox 40.0.2\
Remote Server Administration Tools for Windows 10\
Hyper-V Management Tools enabled\
SQL Server 2014 Management Tools - Complete\
System Center 2012 R2 Operations Manager - Operations console\
System Center 2012 R2 Data Protection Manager Central Console\
System Center 2012 R2 Virtual Machine Manager console

#CLUSTER-INVARIANT#:{75b301bd-e052-43cc-aec4-048d0e4c273e}

**TODO:**

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

## Activate Microsoft Office

1. Start Word 2016
2. Enter product key

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

# MIMIC2 - Windows Server 2016

Tuesday, December 27, 2016
5:30 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

### Install Windows Server 2016

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Create virtual machine

```PowerShell
$vmHost = "STORM"
$vmName = "MIMIC2"
$vmPath = "E:\NotBackedUp\VMs"
$isoPath = ("\\ICEMAN\Products\Microsoft\Windows Server 2016" `
    + "\en_windows_server_2016_x64_dvd_9327751.iso")

$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 2GB `
    -SwitchName "Production"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 2

Set-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path $isoPath

Start-VM -ComputerName $vmHost -Name $vmName
```

---

#### Install Windows Server 2016

When prompted to select an operating system to install, select **Windows Server 2016 Standard (Desktop Experience)**.

#### # Set time zone

```PowerShell
tzutil /s "Mountain Standard Time"
```

#### # Copy latest Toolbox content

```PowerShell
net use \\ICEMAN\Public /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```Console
robocopy \\ICEMAN\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E /MIR
```

#### # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

#### # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

```PowerShell
cls
```

### # Configure network settings

#### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select Name, InterfaceDescription

Get-NetAdapter `
    -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "Production"
```

#### # Configure "Production" network adapter

```PowerShell
$interfaceAlias = "Production"
```

##### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping iceman.corp.technologytoolbox.com -f -l 8900
```

```PowerShell
cls
```

### # Rename computer

```PowerShell
Rename-Computer -NewName MIMIC2 -Restart
```

> **Note**
>
> Wait for the server to restart and then login using the local Administrator account.

### # Join member server to domain

#### # Add computer to domain

```PowerShell
Add-Computer `
    -DomainName corp.technologytoolbox.com `
    -Credential (Get-Credential TECHTOOLBOX\jjameson-admin) `
    -Restart
```

#### Move computer to "Servers" OU

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
$computerName = "MIMIC2"
$targetPath = "OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com"

Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath
```

---

### # Set MaxPatchCacheSize to 0 (Recommended)

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
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

## Install Microsoft Deployment Toolkit

### Reference

**Prepare for deployment with MDT 2013 Update 2**\
From <[https://technet.microsoft.com/en-us/itpro/windows/deploy/prepare-for-windows-deployment-with-mdt-2013](https://technet.microsoft.com/en-us/itpro/windows/deploy/prepare-for-windows-deployment-with-mdt-2013)>

```PowerShell
cls
```

### # Install Windows Assessment and Deployment Kit (Windows ADK) for Windows 10

```PowerShell
& ("\\ICEMAN\Public\Download\Microsoft\Windows Assessment and Deployment Kit" `
```

    + "\\Windows ADK for Windows 10, version 1607\\adksetup.exe")

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
& ("\\ICEMAN\Public\Download\Microsoft\Microsoft Deployment Toolkit" `
    + "\MDT - build 8443\MicrosoftDeploymentToolkit_x64.msi")
```

## Upgrade MDT deployment shares and regenerate boot images

### Upgrade MDT deployment shares

1. Open **Deployment Workbench** and expand **Deployment Shares**.
2. Right-click **[\\\\ICEMAN\\MDT-Build\$](\\ICEMAN\MDT-Build$)** and then click **Upgrade Deployment Share**.
3. In the **Upgrade Deployment Share Wizard**:
   1. On the **Summary** step, click **Next**.
   2. Wait for the deployment share to be upgraded, verify no errors occurred during the upgrade, and then click **Finish**.
4. Repeat the previous steps to upgrade the **[\\\\ICEMAN\\MDT-Deploy\$](\\ICEMAN\MDT-Deploy$)** deployment share.

### Change monitoring host from MIMIC to MIMIC2

1. Open **Deployment Workbench** and expand **Deployment Shares**.
2. Right-click **MDT Build Lab ([\\\\ICEMAN\\MDT-Build\$](\\ICEMAN\MDT-Build$))** and then click **Properties**.
3. In the **MDT Build Lab ([\\\\ICEMAN\\MDT-Build\$](\\ICEMAN\MDT-Build$)) Properties** window:
   1. On the **Monitoring** tab, in the **Monitoring host** box, type **MIMIC2**.
   2. Click **OK**.
4. Repeat the previous steps to update the **MDT Deployment ([\\\\ICEMAN\\MDT-Deploy\$](\\ICEMAN\MDT-Deploy$))** deployment share.

### Update MDT deployment shares (to regenerate the boot images)

1. Open **Deployment Workbench** and expand **Deployment Shares**.
2. Right-click **MDT Build Lab ([\\\\ICEMAN\\MDT-Build\$](\\ICEMAN\MDT-Build$))** and then click **Update Deployment Share**.
3. In the **Update Deployment Share Wizard**:
   1. On the **Options** step, select **Completely regenerate the boot images**, and then click **Next**.
   2. On the **Summary** step, click **Next**.
   3. Wait for the deployment share to be updated, verify no errors occurred during the update, and then click **Finish**.
4. Repeat the previous steps to update the **MDT Deployment ([\\\\ICEMAN\\MDT-Deploy\$](\\ICEMAN\MDT-Deploy$))** deployment share.

```PowerShell
cls
```

### # Copy boot images to file server

```PowerShell
@(
'\\ICEMAN\MDT-Build$\Boot\MDT-Build-x64.iso',
'\\ICEMAN\MDT-Build$\Boot\MDT-Build-x86.iso',
'\\ICEMAN\MDT-Deploy$\Boot\MDT-Deploy-x64.iso',
'\\ICEMAN\MDT-Deploy$\Boot\MDT-Deploy-x86.iso') |
    ForEach-Object {
        Copy-Item $_ "\\ICEMAN\Products\Microsoft"
    }
```

---

**WOLVERINE**

```PowerShell
cls
```

## # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    \\ICEMAN\MDT-Build$ '.\Main\MDT-Build$'
```

#### # Sync files

```PowerShell
robocopy \\ICEMAN\MDT-Build$ Main\MDT-Build$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools

robocopy \\ICEMAN\MDT-Deploy$ Main\MDT-Deploy$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools
```

#### # Add files to TFS

```PowerShell
& "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\TF.exe" add Main /r
```

#### Check-in files

---

```PowerShell
cls
```

## # Upgrade Firefox and Thunderbird applications

```PowerShell
Add-PSSnapin Microsoft.BDD.PSSnapIn

New-PSDrive -Name "DS002" -PSProvider MDTProvider -Root \\ICEMAN\MDT-Deploy$
```

```PowerShell
cls
```

### # Remove obsolete Firefox application

```PowerShell
Remove-Item -Path "DS002:\Applications\Mozilla\Firefox 45.0.1"
```

```PowerShell
cls
```

### # Create application: Mozilla Firefox 50.1.0

\$appName = "Firefox 50.1.0"

```PowerShell
$appShortName = "Firefox"
$commandLine = `
    '"\\ICEMAN\Products\Mozilla\Firefox\Firefox Setup 50.1.0.exe" -ms'

Import-MDTApplication `
    -Path "DS002:\Applications\Mozilla" `
    -Name $appName `
    -ShortName $appShortName `
    -NoSource `
    -CommandLine $commandLine
```

```PowerShell
cls
```

### # Remove obsolete Thunderbird application

```PowerShell
Remove-Item -Path "DS002:\Applications\Mozilla\Thunderbird 38.7.0"
```

### # Create application: Mozilla Thunderbird 38.8.0

\$appName = "Thunderbird 38.8.0"

```PowerShell
$appShortName = "Thunderbird"
$commandLine = `
    '"\\ICEMAN\Products\Mozilla\Thunderbird\Thunderbird Setup 38.8.0.exe" -ms'

Import-MDTApplication `
    -Path "DS002:\Applications\Mozilla" `
    -Name $appName `
    -ShortName $appShortName `
    -NoSource `
    -CommandLine $commandLine
```

---

**WOLVERINE**

```PowerShell
cls
```

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    \\ICEMAN\MDT-Deploy$ '.\Main\MDT-Deploy$'
```

#### # Sync files

```PowerShell
robocopy \\ICEMAN\MDT-Deploy$ Main\MDT-Deploy$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools
```

#### Check-in files

---

```PowerShell
cls
```

## # Import operating systems - Windows 10 and Windows Server 2016

### # Create folder - "Operating Systems\\Windows 10"

```PowerShell
Add-PSSnapin Microsoft.BDD.PSSnapIn

New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root \\ICEMAN\MDT-Build$

New-Item -Path "DS001:\Operating Systems" -Name "Windows 10" -ItemType Folder
```

### # Import operating system - "Windows 10 Enterprise, Version 1607 (x64)"

#### # Mount the installation image

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\Windows 10" `
    + "\en_windows_10_enterprise_version_1607_updated_jul_2016_x64_dvd_9054264.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$sourcePath = $imageDriveLetter + ":\"
```

#### # Import operating system

```PowerShell
$destinationFolder = "W10Ent-1607-x64"

$os = Import-MDTOperatingSystem `
    -Path "DS001:\Operating Systems\Windows 10" `
    -SourcePath $sourcePath `
    -DestinationFolder $destinationFolder

$os.RenameItem("Windows 10 Enterprise, Version 1607 (x64)")
```

#### # Dismount the installation image

```PowerShell
Dismount-DiskImage -ImagePath $imagePath
```

```PowerShell
cls
```

### # Create folder - "Operating Systems\\Windows Server 2016"

```PowerShell
New-Item `
    -Path "DS001:\Operating Systems" `
    -Name "Windows Server 2016" `
    -ItemType Folder
```

### # Import operating system - "Windows Server 2016"

#### # Mount the installation image

```PowerShell
$imagePath = "\\iceman\Products\Microsoft\Windows Server 2016" `
    + "\en_windows_server_2016_x64_dvd_9327751.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$sourcePath = $imageDriveLetter + ":\"
```

#### # Import operating system

```PowerShell
$destinationFolder = "WS2016"

$os = Import-MDTOperatingSystem `
    -Path "DS001:\Operating Systems\Windows Server 2016" `
    -SourcePath $sourcePath `
    -DestinationFolder $destinationFolder

$os[0].RenameItem("Windows Server 2016 Standard (Server Core Installation)")
$os[1].RenameItem("Windows Server 2016 Standard")
$os[2].RenameItem("Windows Server 2016 Datacenter (Server Core Installation)")
$os[3].RenameItem("Windows Server 2016 Datacenter")
```

#### # Dismount the installation image

```PowerShell
Dismount-DiskImage -ImagePath $imagePath
```

---

**WOLVERINE**

```PowerShell
cls
```

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    \\ICEMAN\MDT-Build$ '.\Main\MDT-Build$'
```

#### # Sync files

```PowerShell
robocopy \\ICEMAN\MDT-Build$ Main\MDT-Build$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools
```

#### Check-in files

---

```PowerShell
cls
```

## # Create task sequence for building Windows 10 baseline image

### # Create folder - "Task Sequences\\Window 10"

```PowerShell
New-Item -Path "DS001:\Task Sequences" -Name "Windows 10" -ItemType Folder
```

### # Create task sequence - "Windows 10 Enterprise (x64) - Baseline"

```PowerShell
$osPath = "DS001:\Operating Systems\Windows 10" `
    + "\Windows 10 Enterprise, Version 1607 (x64)"

Import-MDTTaskSequence `
    -Path "DS001:\Task Sequences\Windows 10" `
    -ID "W10ENT-X64-REF" `
    -Name "Windows 10 Enterprise (x64) - Baseline" `
    -Comments "Reference image" `
    -Version "1.0" `
    -Template "Client.xml" `
    -OperatingSystemPath $osPath `
    -FullName "Windows User" `
    -OrgName "Technology Toolbox" `
    -HomePage "about:blank"
```

```PowerShell
cls
```

## # Create task sequence for building Windows Server 2016 baseline image

### # Create folder - "Task Sequences\\Windows Server 2016"

```PowerShell
New-Item `
    -Path "DS001:\Task Sequences" `
    -Name "Windows Server 2016" `
    -ItemType Folder
```

### # Create task sequence - "Windows Server 2016 - Baseline"

```PowerShell
$osPath = "DS001:\Operating Systems\Windows Server 2016" `
    + "\Windows Server 2016 Standard"

Import-MDTTaskSequence `
    -Path "DS001:\Task Sequences\Windows Server 2016" `
    -ID "WS2016-REF" `
    -Name "Windows Server 2016 - Baseline" `
    -Comments "Reference image" `
    -Version "1.0" `
    -Template "Server.xml" `
    -OperatingSystemPath $osPath `
    -FullName "Windows User" `
    -OrgName "Technology Toolbox" `
    -HomePage "about:blank" `
    -ProductKey "WC2BQ-8NRM3-FDDYY-2BFGV-KHKQY"
```

> **Important**
>
> The MSDN version of Windows Server 2016 will prompt to enter a product key (but provide an option to skip this step). It does not honor the SkipProductKey=YES entry in the MDT CustomSettings.ini file.The product key specified above was obtained from the following:
>
> **Appendix A: KMS Client Setup Keys**\
> From <[https://technet.microsoft.com/en-us/library/jj612867(v=ws.11).aspx](https://technet.microsoft.com/en-us/library/jj612867(v=ws.11).aspx)>

---

**WOLVERINE**

```PowerShell
cls
```

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    \\ICEMAN\MDT-Build$ '.\Main\MDT-Build$'
```

#### # Sync files

```PowerShell
robocopy \\ICEMAN\MDT-Build$ Main\MDT-Build$ /E /XD `$OEM`$ Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools
```

#### # Add files to TFS

```PowerShell
& "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\TF.exe" add Main /r
```

#### Check-in files

---

```Console
cls
```

# Build baseline images

---

**STORM**

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows 10 Enterprise (x64) - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Build-x64.iso -Force
```

---

---

**BEAST**

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows Server 2016 - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Build-x64.iso -Force
```

---

## Customize Windows 10 and Windows Server 2016 baseline images

### Configure task sequence - "Windows 10 Enterprise (x64) - Baseline"

Edit the task sequence to include the actions required to update the reference image with the latest updates from WSUS, copy Toolbox content from ICEMAN, install .NET Framework 3.5, and easily suspend the deployment process after installing applications.

1. Open **Deployment Workbench**, expand **Deployment Shares / MDT Build Lab ([\\\\ICEMAN\\MDT-Build\$](\\ICEMAN\MDT-Build$)) / Task Sequences / Windows 10**, right-click **Windows 10 Enterprise (x64) - Baseline**, and click **Properties**.
2. In the **Windows 10 Enterprise (x64) - Baseline Properties** window:
   1. On the **General **tab, configure the following settings:
      1. Comments: **Reference image - Toolbox content, .NET Framework 3.5, and latest patches**
   2. On the **Task Sequence** tab, configure the following settings:
      1. **State Restore**
         1. Enable the **Windows Update (Pre-Application Installation)** action.
         2. Enable the **Windows Update (Post-Application Installation)** action.
         3. After the **Tattoo** action, add a new **Group** action with the following setting:
            1. Name: **Custom Tasks (Pre-Windows Update)**
         4. After the **Windows Update (Post-Application Installation)** action, rename the **Custom Tasks** group to **Custom Tasks (Post-Windows Update)**.
         5. Select the **Custom Tasks (Pre-Windows Update)** group and add a new **Run Command Line** action with the following settings:
            1. Name: **Copy Toolbox content from ICEMAN**
            2. Command line: **robocopy [\\\\ICEMAN\\Public\\Toolbox](\\ICEMAN\Public\Toolbox) C:\\NotBackedUp\\Public\\Toolbox /E**
            3. Success codes: **0 1 2 3 4 5 6 7 8 16**
         6. Select the **Custom Tasks (Pre-Windows Update)** group and add a new **Install Roles and Features** action with the following settings:
            1. Name: **Install Microsoft .NET Framework 3.5**
            2. Select the operating system for which roles are to be installed: **Windows 10**
            3. Select the roles and features that should be installed: **.NET Framework 3.5 (includes .NET 2.0 and 3.0)**
         7. After the **Install Applications** action, add a new **Run Command Line** action with the following settings:
            1. Name: **Suspend**
            2. Command line: **cscript.exe "%SCRIPTROOT%\\LTISuspend.wsf"**
            3. Disable this step:** Yes (checked)**
   3. Click **OK**.

> **Note**
>
> The reason for adding the applications after the Tattoo action but before running Windows Update is simply to save time during the deployment. This way we can add all applications that will upgrade some of the built-in components and avoid unnecessary updating.

### Configure task sequence - "Windows Server 2016"

Edit the task sequence to include the actions required to update the reference image with the latest updates from WSUS, copy Toolbox content from ICEMAN and easily suspend the deployment process after installing applications.

1. Open **Deployment Workbench**, expand **Deployment Shares / MDT Build Lab ([\\\\ICEMAN\\MDT-Build\$](\\ICEMAN\MDT-Build$)) / Task Sequences / Windows Server 2016**, right-click **Windows Server 2016 - Baseline**, and click **Properties**.
2. In the **Windows Server 2016 - Baseline Properties** window:
   1. On the **General **tab, configure the following settings:
      1. Comments: **Reference image - Toolbox content and latest patches**
   2. On the **Task Sequence** tab, configure the following settings:
      1. **State Restore**
         1. Enable the **Windows Update (Pre-Application Installation)** action.
         2. Enable the **Windows Update (Post-Application Installation)** action.
         3. After the **Tattoo** action, add a new **Group** action with the following setting:
            1. Name: **Custom Tasks (Pre-Windows Update)**
         4. After the **Windows Update (Post-Application Installation)** action, rename the **Custom Tasks** group to **Custom Tasks (Post-Windows Update)**.
         5. Select the **Custom Tasks (Pre-Windows Update)** group and add a new **Run Command Line** action with the following settings:
            1. Name: **Copy Toolbox content from ICEMAN**
            2. Command line: **robocopy [\\\\ICEMAN\\Public\\Toolbox](\\ICEMAN\Public\Toolbox) C:\\NotBackedUp\\Public\\Toolbox /E**
            3. Success codes: **0 1 2 3 4 5 6 7 8 16**
         6. After the **Install Applications** action, add a new **Run Command Line** action with the following settings:
            1. Name: **Suspend**
            2. Command line: **cscript.exe "%SCRIPTROOT%\\LTISuspend.wsf"**
            3. Disable this step:** Yes (checked)**
   3. Click **OK**.

> **Note**
>
> The reason for adding the applications after the Tattoo action but before running Windows Update is simply to save time during the deployment. This way we can add all applications that will upgrade some of the built-in components and avoid unnecessary updating.

---

**WOLVERINE**

```PowerShell
cls
```

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    \\ICEMAN\MDT-Build$ '.\Main\MDT-Build$'
```

#### # Sync files

```PowerShell
robocopy \\ICEMAN\MDT-Build$ Main\MDT-Build$ /E /XD `$OEM`$ Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools
```

#### Check-in files

---

```Console
cls
```

# Build baseline images

---

**STORM**

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows 10 Enterprise (x64) - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Build-x64.iso -Force
```

---

---

**BEAST**

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows Server 2016 - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Build-x64.iso -Force
```

---

### Bug - Windows Update hangs downloading cumulative update

#### Reference

**Windows Update Step hanging - Windows 10 1607**\
From <[https://social.technet.microsoft.com/Forums/en-US/35309dd8-f87a-41e1-8a20-33ffbb2648e2/windows-update-step-hanging-windows-10-1607?forum=mdt](https://social.technet.microsoft.com/Forums/en-US/35309dd8-f87a-41e1-8a20-33ffbb2648e2/windows-update-step-hanging-windows-10-1607?forum=mdt)>

In order for the MDT Windows Update action to work when having a local WSUS (known bug), you really need to slipstream [KB3197954](KB3197954) or later into the image during the WinPE phase. In MDT that is done by adding it as a package in the Deployment Workbench, and create a selection profile for Windows 10 x64 v1607.

From <[http://deploymentresearch.com/Research/Post/540/Building-a-Windows-10-v1607-reference-image-using-MDT-2013-Update-2](http://deploymentresearch.com/Research/Post/540/Building-a-Windows-10-v1607-reference-image-using-MDT-2013-Update-2)>

#### Download latest CU from Microsoft Update Catalog

Source: [http://www.catalog.update.microsoft.com/Search.aspx?q=KB3213522](http://www.catalog.update.microsoft.com/Search.aspx?q=KB3213522)

Destination: [\\\\ICEMAN\\Products\\Microsoft\\Windows 10\\Patches](\\ICEMAN\Products\Microsoft\Windows 10\Patches)

```PowerShell
cls
```

#### # Slipstream latest CU into the image during the WinPE phase

```PowerShell
New-Item `
    -Path "DS001:\Packages" `
    -Name "Windows 10 (x64)" `
    -ItemType Folder

Import-MDTPackage `
    -Path "DS001:\Packages\Windows 10 (x64)" `
    -SourcePath "\\ICEMAN\Products\Microsoft\Windows 10\Patches"

New-Item `
    -Path "DS001:\Selection Profiles" `
    -Enable "True" `
    -Name "Windows 10 (x64)" `
    -Comments "Slipstream patches during the WinPE phase" `
    -Definition (
        "<SelectionProfile>" `
            + "<Include path=`"Packages\Windows 10 (x64)`" />" `
        + "</SelectionProfile>") `
    -ReadOnly $false
```

---

**WOLVERINE**

```PowerShell
cls
```

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    \\ICEMAN\MDT-Build$ '.\Main\MDT-Build$'
```

#### # Sync files

```PowerShell
robocopy \\ICEMAN\MDT-Build$ Main\MDT-Build$ /E /XD `$OEM`$ Applications Backup Boot Captures Logs "Operating Systems" Packages Servicing Tools
```

#### Check-in files

---

## # Add custom Windows 10 and Windows Server 2016 images to MDT production deployment share

### # Create folder - "Operating Systems\\Windows 10"

```PowerShell
Import-Module 'C:\Program Files\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1'

New-PSDrive -Name "DS002" -PSProvider MDTProvider -Root \\ICEMAN\MDT-Deploy$

New-Item -Path "DS002:\Operating Systems" -Name "Windows 10" -ItemType Folder
```

```PowerShell
cls
```

### # Import operating system - "Windows 10 Enterprise (x64) - Baseline"

```PowerShell
$imagePath = "\\ICEMAN\MDT-Build$\Captures\W10ENT-X64-REF_12-28-2016-6-00-09-AM.wim"

$destinationFolder = "W10Ent-x64"

$os = Import-MDTOperatingSystem `
    -Path "DS002:\Operating Systems\Windows 10" `
    -SourceFile $imagePath `
    -DestinationFolder $destinationFolder `
    -Move

$os.RenameItem("Windows 10 Enterprise (x64) - Baseline")
```

```PowerShell
cls
```

### # Create folder - "Operating Systems\\Windows Server 2016"

```PowerShell
New-Item `
    -Path "DS002:\Operating Systems" `
    -Name "Windows Server 2016" `
    -ItemType Folder
```

```PowerShell
cls
```

### # Import operating system - "Windows Server 2016 Standard - Baseline"

```PowerShell
$imagePath = "\\ICEMAN\MDT-Build$\Captures\WS2016-REF_1-10-2017-10-35-31-AM.wim"

$destinationFolder = "WS2016"

$os = Import-MDTOperatingSystem `
    -Path "DS002:\Operating Systems\Windows Server 2016" `
    -SourceFile $imagePath `
    -DestinationFolder $destinationFolder `
    -Move

$os.RenameItem("Windows Server 2016 Standard - Baseline")
```

---

**WOLVERINE**

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

robocopy \\ICEMAN\MDT-Deploy$ Main\MDT-Deploy$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools
```

#### # Add files to TFS

```PowerShell
& "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\TF.exe" add Main /r
```

##### Check-in files

---

```PowerShell
cls
```

## # Create task sequences for Windows 10 and Windows Server 2016 deployments

### # Create folder - "Task Sequences\\Windows 10"

```PowerShell
New-Item -Path "DS002:\Task Sequences" -Name "Windows 10" -ItemType Folder
```

### # Create task sequence - "Windows 10 Enterprise (x64)"

```PowerShell
$osPath = "DS002:\Operating Systems\Windows 10\Windows 10 Enterprise (x64) - Baseline"

Import-MDTTaskSequence `
    -Path "DS002:\Task Sequences\Windows 10" `
    -ID "W10ENT-X64" `
    -Name "Windows 10 Enterprise (x64)" `
    -Comments "Production image" `
    -Version "1.0" `
    -Template "Client.xml" `
    -OperatingSystemPath $osPath `
    -FullName "Windows User" `
    -OrgName "Technology Toolbox" `
    -HomePage "about:blank"
```

```PowerShell
cls
```

### # Create folder - "Task Sequences\\Windows Server 2016"

```PowerShell
New-Item `
    -Path "DS002:\Task Sequences" `
    -Name "Windows Server 2016" `
    -ItemType Folder
```

### # Create task sequence - "Windows Server 2016"

```PowerShell
$osPath = "DS002:\Operating Systems\Windows Server 2016" `
    + "\Windows Server 2016 Standard - Baseline"

Import-MDTTaskSequence `
    -Path "DS002:\Task Sequences\Windows Server 2016" `
    -ID "WS2016" `
    -Name "Windows Server 2016" `
    -Comments "Production image" `
    -Version "1.0" `
    -Template "Server.xml" `
    -OperatingSystemPath $osPath `
    -FullName "Windows User" `
    -OrgName "Technology Toolbox" `
    -HomePage "about:blank" `
    -ProductKey "WC2BQ-8NRM3-FDDYY-2BFGV-KHKQY"
```

> **Important**
>
> The MSDN version of Windows Server 2016 will prompt to enter a product key (but provide an option to skip this step). It does not honor the SkipProductKey=YES entry in the MDT CustomSettings.ini file.The product key specified above was obtained from the following:
>
> **Appendix A: KMS Client Setup Keys**\
> From <[https://technet.microsoft.com/en-us/library/jj612867(v=ws.11).aspx](https://technet.microsoft.com/en-us/library/jj612867(v=ws.11).aspx)>

---

**WOLVERINE**

```PowerShell
cls
```

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

robocopy \\ICEMAN\MDT-Deploy$ Main\MDT-Deploy$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools
```

#### # Add files to TFS

```PowerShell
& "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\TF.exe" add Main /r
```

##### Check-in files

---

```PowerShell
cls
```

## # Import new versions (January 2017) of Windows 10 and Windows Server 2016

```PowerShell
Add-PSSnapin Microsoft.BDD.PSSnapIn

New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root \\TT-FS01\MDT-Build$
```

### # Import operating system - "Windows 10 Enterprise, Version 1607 (x64)"

#### # Mount the installation image

```PowerShell
$imagePath = "\\TT-FS01\Products\Microsoft\Windows 10" `
    + "\en_windows_10_enterprise_version_1607_updated_jan_2017_x64_dvd_9714415.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$sourcePath = $imageDriveLetter + ":\"
```

#### # Import operating system

```PowerShell
$destinationFolder = "W10Ent-1607-x64"

$os = Import-MDTOperatingSystem `
    -Path "DS001:\Operating Systems\Windows 10" `
    -SourcePath $sourcePath `
    -DestinationFolder $destinationFolder

$os.RenameItem("Windows 10 Enterprise, Version 1607 (x64)")
```

#### # Dismount the installation image

```PowerShell
Dismount-DiskImage -ImagePath $imagePath
```

```PowerShell
cls
```

### # Import operating system - "Windows Server 2016"

#### # Mount the installation image

```PowerShell
$imagePath = "\\TT-FS01\Products\Microsoft\Windows Server 2016" `
    + "\en_windows_server_2016_x64_dvd_9718492.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$sourcePath = $imageDriveLetter + ":\"
```

#### # Import operating system

```PowerShell
$destinationFolder = "WS2016"

$os = Import-MDTOperatingSystem `
    -Path "DS001:\Operating Systems\Windows Server 2016" `
    -SourcePath $sourcePath `
    -DestinationFolder $destinationFolder

$os[0].RenameItem("Windows Server 2016 Standard (Server Core Installation)")
$os[1].RenameItem("Windows Server 2016 Standard")
$os[2].RenameItem("Windows Server 2016 Datacenter (Server Core Installation)")
$os[3].RenameItem("Windows Server 2016 Datacenter")
```

#### # Dismount the installation image

```PowerShell
Dismount-DiskImage -ImagePath $imagePath
```

---

**WOLVERINE**

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

## Upgrade to System Center Operations Manager 2016

### Uninstall SCOM 2012 R2 agent

```Console
msiexec /x `{786970C5-E6F6-4A41-B238-AE25D4B91EEA`}

Restart-Computer
```

### Install SCOM 2016 agent (using Operations Console)

## Issue - Incorrect IPv6 DNS server assigned by Comcast router

```Text
PS C:\Users\jjameson-admin> nslookup
Default Server:  cdns01.comcast.net
Address:  2001:558:feed::1
```

> **Note**
>
> Even after reconfiguring the **Primary DNS** and **Secondary DNS** settings on the Comcast router -- and subsequently restarting the VM -- the incorrect DNS server is assigned to the network adapter.

### Solution

```PowerShell
Set-DnsClientServerAddress `
    -InterfaceAlias Management `
    -ServerAddresses 2603:300b:802:8900::103, 2603:300b:802:8900::104

Restart-Computer
```

## Import new version (March 2017) of Windows 10

```PowerShell
Add-PSSnapin Microsoft.BDD.PSSnapIn

New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root \\TT-FS01\MDT-Build$
```

### # Import operating system - "Windows 10 Enterprise, Version 1703 (x64)"

#### # Mount the installation image

```PowerShell
$imagePath = "\\TT-FS01\Products\Microsoft\Windows 10" `
```

    + "\\en_windows_10_enterprise_version_1703_updated_march_2017_x64_dvd_10189290.iso"

```PowerShell
$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$sourcePath = $imageDriveLetter + ":\"
```

#### # Import operating system

```PowerShell
$destinationFolder = "W10Ent-1703-x64"

$os = Import-MDTOperatingSystem `
    -Path "DS001:\Operating Systems\Windows 10" `
    -SourcePath $sourcePath `
    -DestinationFolder $destinationFolder

$os.RenameItem("Windows 10 Enterprise, Version 1703 (x64)")
```

#### # Dismount the installation image

```PowerShell
Dismount-DiskImage -ImagePath $imagePath
```

### Modify task sequence to use Windows 10 Enterprise, Version 1703

---

**WOLVERINE**

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

# VS2015

Thursday, November 9, 2017\
8:11 AM

```PowerShell
cls
```

## # Add application - Visual Studio 2015 with Update 3

```PowerShell
Import-Module ("C:\Program Files\Microsoft Deployment Toolkit\Bin" `
    + "\MicrosoftDeploymentToolkit.psd1")

New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root \\TT-FS01\MDT-Build$
```

### # Create application - "Visual Studio 2015 with Update 3 - Default"

#### # Mount the installation image

```PowerShell
$imagePath = "\\TT-FS01\Products\Microsoft\Visual Studio 2015" `
    + "\en_visual_studio_enterprise_2015_with_update_3_x86_x64_dvd_8923288.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$appSourcePath = $imageDriveLetter + ":\"
```

#### # Import application

```PowerShell
$appName = "Visual Studio 2015 with Update 3 - Default"
$appShortName = "VS2015-Update3"
$appSetupFolder = $appShortName
$commandLine = "vs_enterprise.exe /Quiet /NoRestart"

Import-MDTApplication `
    -Path "DS001:\Applications\Microsoft" `
    -Name $appName `
    -ShortName $appShortName `
    -ApplicationSourcePath $appSourcePath `
    -DestinationFolder $appSetupFolder `
    -CommandLine $commandLine `
    -WorkingDirectory ".\Applications\$appSetupFolder"
```

#### # Dismount the installation image

```PowerShell
Dismount-DiskImage -ImagePath $imagePath
```

```PowerShell
cls
```

### # Create application - "Visual Studio 2015 with Update 3 - SP2013 Development"

#### # Create baseline "AdminFile" for unattended Visual Studio 2015 installation

```PowerShell
$path = "\\TT-FS01\MDT-Build$\Applications\VS2015-Update3"

Start-Process `
    -FilePath "$path\vs_enterprise.exe" `
    -ArgumentList @("/CreateAdminFile", "$path\AdminDeployment.xml") `
    -Wait
```

#### # Create custom deployment file for unattended Visual Studio 2015 installation for SP2013 development

```PowerShell
$xml = [xml] (Get-Content "$path\AdminDeployment.xml")
```

##### # In the `<BundleCustomizations>` element, change the NoWeb attribute to "yes"

```PowerShell
$xml.AdminDeploymentCustomizations.BundleCustomizations.NoWeb = "yes"
```

##### # Change the "Selected" attributes for `<SelectableItemCustomization>` elements

```PowerShell
$xml.AdminDeploymentCustomizations.SelectableItemCustomizations.SelectableItemCustomization |
    foreach {
        If ($_.Id -eq "OfficeDeveloperToolsV1")
        {
            $_.Selected = "yes"
        }
    }

$xml.Save("$path\AdminDeployment-SP2013-Dev.xml")
```

#### # Import application

\$appName = "Visual Studio 2015 with Update 3 - SP2013 Development"

```PowerShell
$appShortName = "VS2015-Update3-SP2013-Dev"
$appSetupFolder = "VS2015-Update3"
$commandLine = "vs_enterprise.exe /Quiet /NoRestart" `
    + " /AdminFile Z:\Applications\$appSetupFolder\AdminDeployment-SP2013-Dev.xml"
```

> **Important**
>
> You must specify the full path for the **AdminFile** parameter or else vs_enterprise.exe terminates with an error.

```PowerShell
Import-MDTApplication `
    -Path "DS001:\Applications\Microsoft" `
    -Name $appName `
    -ShortName $appShortName `
    -NoSource `
    -CommandLine $commandLine `
    -WorkingDirectory ".\Applications\$appSetupFolder"
```

---

**WOLVERINE** - Run as administrator

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

$source = '\\TT-FS01\MDT-Build$'
$destination = '.\Main\MDT-Build$'

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe $source $destination
```

#### # Sync files

```PowerShell
robocopy $source $destination /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools

robocopy `
    "$source\Applications\VS2015-Update3" `
    "$destination\Applications\VS2015-Update3" `
    AdminDeployment.xml AdminDeployment-SP2013-Dev.xml
```

#### # Add files to TFS

```PowerShell
$tf = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE" `
    + "\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\TF.exe"

& $tf add Main /r
```

#### Check-in files

---

```PowerShell
cls
```

### # Create application - "Microsoft Office Developer Tools for Visual Studio 2013 - November 2014 Update"

#### Download update using Web Platform Installer

- Folder: [\\\\TT-FS01\\Products\\Microsoft\\Visual Studio 2015\\Office](\\TT-FS01\Products\Microsoft\Visual Studio 2015\Office) Developer Tools Update 2 for Visual Studio 2015

#### # Add application

```PowerShell
$appName = "Office Developer Tools Update 2 for Visual Studio 2015"

$appShortName = "OfficeToolsForVS2015Update2"
$appSourcePath = "\\TT-FS01\Products\Microsoft\Visual Studio 2015" `
    + "\Office Developer Tools Update 2 for Visual Studio 2015"

$appSetupFolder = $appShortName
$commandLine = "cba_bundle.exe /Quiet /NoRestart"

Import-MDTApplication `
    -Path "DS001:\Applications\Microsoft" `
    -Name $appName `
    -ShortName $appShortName `
    -ApplicationSourcePath $appSourcePath `
    -DestinationFolder $appSetupFolder `
    -CommandLine $commandLine `
    -WorkingDirectory ".\Applications\$appSetupFolder"
```

### # Create application: Microsoft SQL Server Update for database tooling

#### Download ISO for SQL Server Database Tools (SSDT_14.0.61709.290_EN.iso)

- Download link:\
  **Download SQL Server Data Tools (SSDT)**\
  From <[https://docs.microsoft.com/en-us/sql/ssdt/download-sql-server-data-tools-ssdt](https://docs.microsoft.com/en-us/sql/ssdt/download-sql-server-data-tools-ssdt)>
- Destination folder: [\\\\TT-FS01\\Products\\Microsoft\\Visual Studio 2015\\SQL](\\TT-FS01\Products\Microsoft\Visual Studio 2015\SQL) Server Data Tools Update

#### # Mount the installation image

```PowerShell
$imagePath = "\\TT-FS01\Products\Microsoft\Visual Studio 2015" `
    + "\SQL Server Data Tools Update\SSDT_14.0.61709.290_EN.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$appSourcePath = $imageDriveLetter + ":\"
```

#### # Import application

\$appName = "Microsoft SQL Server Update for database tooling (VS2015)"

```PowerShell
$appShortName = "SSDT-VS2015"
$appSetupFolder = $appShortName
$commandLine = "SSDTSETUP.EXE /q /norestart"

Import-MDTApplication `
    -Path "DS001:\Applications\Microsoft" `
    -Name $appName `
    -ShortName $appShortName `
    -ApplicationSourcePath $appSourcePath `
    -DestinationFolder $appSetupFolder `
    -CommandLine $commandLine `
    -WorkingDirectory ".\Applications\$appSetupFolder"
```

#### # Dismount the installation image

```PowerShell
Dismount-DiskImage -ImagePath $imagePath
```

```PowerShell
cls
```

### # Create application bundle - "Visual Studio 2015 for SP2013 Development"

#### # Add application bundle

\$appName = "Visual Studio 2015 for SP2013 Development"

```PowerShell
$appShortName = "VS2015-SP2013"

Import-MDTApplication `
    -Path "DS001:\Applications\Microsoft" `
    -Name $appName `
    -ShortName $appShortName `
    -Bundle
```

#### # Configure application bundle

1. Open **Deployment Workbench**, expand **Deployment Shares / MDT Build Lab ([\\\\TT-FS01\\MDT-Build\$](\\TT-FS01\MDT-Build$)) / Applications / Microsoft**, right-click **Visual Studio 2015 for SP2013 Development**, and click **Properties**.
2. In the **Visual Studio 2015 for SP2013 Development Properties** window:
   1. On the **Dependencies** tab:
      1. Add the following applications:
         1. **Visual Studio 2015 with Update 3 - SP2013 Development**
         2. **Office Developer Tools Update 2 for Visual Studio 2015**
         3. **Microsoft SQL Server Update for database tooling (VS2015)**
      2. Ensure the applications in the previous step are listed in the specified order. Use the **Up** or **Down** buttons to reorder the applications as necessary.
   2. Click **OK**.

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

### # Update files in TFS

#### # Sync files

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

$source = '\\TT-FS01\MDT-Build$'
$destination = '.\Main\MDT-Build$'

robocopy $source $destination /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools
```

#### Check-in files

---

## Add application - Office Professional Plus 2016 (x86)

### Reference

**Use the Office 2016 offline installer**\
From <[https://support.office.com/en-us/article/Use-the-Office-2016-offline-installer-f0a85fe7-118f-41cb-a791-d59cef96ad1c](https://support.office.com/en-us/article/Use-the-Office-2016-offline-installer-f0a85fe7-118f-41cb-a791-d59cef96ad1c)>

---

**WIN10-DEV1** - Run as administrator

```PowerShell
cls
```

### # Download and install the Office 2016 Deployment Tool

```PowerShell
mkdir C:\ODT
```

Download the Office 2016 Deployment Tool:

**Office 2016 Deployment Tool**\
From <[https://www.microsoft.com/en-us/download/confirmation.aspx?id=49117](https://www.microsoft.com/en-us/download/confirmation.aspx?id=49117)>

Run the Office 2016 Deployment Tool and extract the files to the **C:\\ODT** folder.

```PowerShell
cls
```

### # Download Office 2016 offline installation files

```PowerShell
Push-Location C:\ODT

.\setup.exe /download configuration.xml

Pop-Location
```

```PowerShell
cls
```

### # Configure installation settings for Office 2016

```PowerShell
Notepad C:\ODT\configuration.xml
```

---

File - **C:\\ODT\\configuration.xml**

```XML
<Configuration>

  <Add OfficeClientEdition="32" Channel="Monthly">
    <Product ID="O365ProPlusRetail">
      <Language ID="en-us" />
    </Product>
    <Product ID="VisioProRetail">
      <Language ID="en-us" />
    </Product>
  </Add>

  <!--  <Updates Enabled="TRUE" Channel="Monthly" /> -->
  <Display Level="None" AcceptEULA="TRUE" />
  <!--  <Property Name="AUTOACTIVATE" Value="1" />  -->

</Configuration>
```

---

```PowerShell
cls
```

### # Copy installation files to MDT Applications folder

```PowerShell
robocopy C:\ODT '\\TT-FS01\MDT-Build$\Applications\Office2016ProPlus-x86' /E /MOV
```

---

```PowerShell
cls
```

### # Create application - "Office Professional Plus 2016 (x86)"

```PowerShell
$appName = "Office Professional Plus 2016 (x86)"
$appShortName = "Office2016ProPlus-x86"
$appSetupFolder = $appShortName
$commandLine = "setup.exe /configure configuration.xml"

Import-MDTApplication `
    -Path "DS001:\Applications\Microsoft" `
    -Name $appName `
    -ShortName $appShortName `
    -NoSource `
    -CommandLine $commandLine `
    -WorkingDirectory ".\Applications\$appSetupFolder"
```

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

### # Update files in TFS

#### # Sync files

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

$source = '\\TT-FS01\MDT-Build$'
$destination = '.\Main\MDT-Build$'

robocopy $source $destination /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools

robocopy `
    "$source\Applications\Office2016ProPlus-x86" `
    "$destination\Applications\Office2016ProPlus-x86" `
    configuration.xml
```

#### # Add files to TFS

```PowerShell
$tf = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE" `
    + "\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\TF.exe"

& $tf add Main /r
```

#### Check-in files

---

## Update task sequence for SharePoint 2013 development image

### Modify task sequence to install Office 2016 and Visual Studio 2015

1. Open **Deployment Workbench**, expand **Deployment Shares / MDT Build Lab ([\\\\TT-FS01\\MDT-Build\$](\\TT-FS01\MDT-Build$)) / Task Sequences / Windows Server 2012 R2**, right-click **SharePoint Server 2013 - Development**, and click **Properties**.
2. In the **SharePoint Server 2013 - Development Properties** window:
   1. On the **General** tab, configure the following settings:
      1. Comments: **Reference image - Windows Server 2012 R2, MaxPatchCacheSize = 0, Toolbox content, Windows features for SharePoint 2013, PowerShell help files, SQL Server 2014, SharePoint Designer 2013, Office 2016, SharePoint Server 2013, Visual Studio 2015 with Update 3, latest patches, and cleanup before Sysprep**
   2. On the **Task Sequence** tab:
      1. Modify the task previously created to install Office 2013 to now install Office 2016.
      2. Move the Office 2016 installation task after the task to install SharePoint Designer 2013.
      3. Modify the task previously created to install Visual Studio 2013 to now install Visual Studio 2015.
   3. Click **OK**.

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

### # Update files in TFS

#### # Sync files

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

$source = '\\TT-FS01\MDT-Build$'
$destination = '.\Main\MDT-Build$'

robocopy $source $destination /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools
```

#### Check-in files

---

## Update task sequence for Windows 10 baseline image

### Add action to task sequence to install Office 2016

1. Open **Deployment Workbench**, expand **Deployment Shares / MDT Build Lab ([\\\\TT-FS01\\MDT-Build\$](\\TT-FS01\MDT-Build$)) / Task Sequences / Windows 10**, right-click **Windows 10 Enterprise (x64) - Baseline**, and click **Properties**.
2. In the **Windows 10 Enterprise (x64) - Baseline Properties** window:
   1. On the **General** tab, configure the following settings:
      1. Comments: **Reference image - Toolbox content, .NET Framework 3.5, Office 2016, and latest patches**
   2. On the **Task Sequence** tab, configure the following settings:
      1. **State Restore**
         1. Select the **Custom Tasks (Pre-Windows Update)** group and add a new **Install Application** action with the following settings:
            1. Name: **Install Microsoft Office 2016 Professional Plus (x86)**
            2. **Install a single application**
            3. Application to install: **Applications / Microsoft / Office 2016 Professional Plus (x86)**
   3. Click **OK**.

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

### # Update files in TFS

#### # Sync files

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

$source = '\\TT-FS01\MDT-Build$'
$destination = '.\Main\MDT-Build$'

robocopy $source $destination /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools
```

#### Check-in files

---

```Console
cls
```

## Build baseline images

---

**TT-HV02A** / **TT-HV02B** / **TT-HV02C**

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

---

```PowerShell
cls
```

## # Update MDT production deployment images

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure\Main\Scripts

& '.\Update Deployment Images.ps1'
```

---

## Update task sequence for Windows 10 baseline image to set MaxPatchCacheSize

### Add action to set MaxPatchCacheSize to 0

1. Open **Deployment Workbench**, expand **Deployment Shares / MDT Build Lab ([\\\\TT-FS01\\MDT-Build\$](\\TT-FS01\MDT-Build$)) / Task Sequences / Windows 10**, right-click **Windows 10 Enterprise (x64) - Baseline**, and click **Properties**.
2. In the **Windows 10 Enterprise (x64) - Baseline Properties** window:
   1. On the **General** tab, configure the following settings:
      1. Comments: **Reference image - MaxPatchCacheSize = 0, Toolbox content, .NET Framework 3.5, Office 2016, and latest patches**
   2. On the **Task Sequence** tab, configure the following settings:
      1. **State Restore**
         1. In the **Custom Tasks (Pre-Windows Update)** group, add a new **Run Command Line** action with the following settings:
            1. Name: **Set MaxPatchCacheSize to 0**
            2. Command Line: **PowerShell.exe -Command "& { New-Item -Path 'HKLM:\\Software\\Policies\\Microsoft\\Windows\\Installer'; New-ItemProperty -Path 'HKLM:\\Software\\Policies\\Microsoft\\Windows\\Installer' -Name MaxPatchCacheSize -PropertyType DWord -Value 0 | Out-Null }"**
         2. Move **Set MaxPatchCache to 0** to be the first action in the **Custom Tasks (Pre-Windows Update)** group.
   3. Click **OK**.

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

### # Update files in TFS

#### # Sync files

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

$source = '\\TT-FS01\MDT-Build$'
$destination = '.\Main\MDT-Build$'

robocopy $source $destination /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools
```

#### Check-in files

---

```Console
cls
```

## Build baseline images

---

**TT-HV02A** / **TT-HV02B** / **TT-HV02C**

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

---

```PowerShell
cls
```

## # Update MDT production deployment images

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure\Main\Scripts

& '.\Update Deployment Images.ps1'
```

---

## Update task sequence for Windows 10 baseline image to cleanup image

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

### # Update files in TFS

#### # Sync files

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

$source = '\\TT-FS01\MDT-Build$'
$destination = '.\Main\MDT-Build$'

robocopy `
    "$source\Applications\Action - Cleanup before Sysprep" `
    "$destination\Applications\Action - Cleanup before Sysprep"
```

#### # Add files to TFS

```PowerShell
$tf = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE" `
    + "\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\TF.exe"

& $tf add Main /r
```

#### Check-in files

---

### Add action to cleanup image before Sysprep

1. Open **Deployment Workbench**, expand **Deployment Shares / MDT Build Lab ([\\\\TT-FS01\\MDT-Build\$](\\TT-FS01\MDT-Build$)) / Task Sequences / Windows 8.1**, right-click **Windows 8.1 Enterprise (x64) - Baseline**, and click **Properties**.
2. In the **Windows 8.1 Enterprise (x64) - Baseline Properties** window, on the **Task Sequence** tab:
   1. Right-click the **Cleanup before Sysprep **group and click **Copy**.
   2. Click **Cancel**.
3. Expand **Deployment Shares / MDT Build Lab ([\\\\TT-FS01\\MDT-Build\$](\\TT-FS01\MDT-Build$)) / Task Sequences / Windows 10**, right-click **Windows 10 Enterprise (x64) - Baseline**, and click **Properties**.
4. In the **Windows 10 Enterprise (x64) - Baseline Properties** window:
   1. On the **General** tab, configure the following settings:
      1. Comments: **Reference image - MaxPatchCacheSize = 0, Toolbox content, .NET Framework 3.5, Office 2016, latest patches, and cleanup before Sysprep**
   2. On the **Task Sequence** tab, add the cleanup action to the task sequence(right-click the **Apply Local GPO Package** action and then click **Paste**).
   3. Click **OK**.

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

### # Update files in TFS

#### # Sync files

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

$source = '\\TT-FS01\MDT-Build$'
$destination = '.\Main\MDT-Build$'

robocopy $source $destination /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools
```

#### Check-in files

---

```Console
cls
```

## Build baseline images

---

**TT-HV02A** / **TT-HV02B** / **TT-HV02C**

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

---

```PowerShell
cls
```

## # Update MDT production deployment images

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure\Main\Scripts

& '.\Update Deployment Images.ps1'
```

---

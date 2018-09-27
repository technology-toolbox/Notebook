# MIMIC - Windows Server 2012 R2 Standard

Wednesday, March 25, 2015
8:05 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## VM settings

Processors: **2**\
Startup RAM: **512 MB**\
Maximum RAM: **2048 MB**

Configure server settings

On the **Settings** page:

1. Ensure the following default values are selected:
   1. **Country or region: United States**
   2. **App language: English (United States)**
   3. **Keyboard layout: US**
2. Click **Next**.
3. Type the product key and then click **Next**.
4. Review the software license terms and then click **I accept**.
5. Type a password for the built-in administrator account and then click **Finish**.

## # Rename computer and join domain

```PowerShell
$computerName = "MIMIC"

Rename-Computer -NewName $computerName -Restart
```

Wait for the VM to restart and then execute the following command to join the **TECHTOOLBOX **domain:

```PowerShell
Add-Computer -DomainName corp.technologytoolbox.com -Restart
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

## # Rename network connection

```PowerShell
Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "LAN 1 - 192.168.10.x"
```

## # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name "LAN 1 - 192.168.10.x" `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping ICEMAN -f -l 8900
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

## Prepare for Deployment with MDT 2013

From <[https://technet.microsoft.com/en-us/library/dn744278.aspx](https://technet.microsoft.com/en-us/library/dn744278.aspx)>

### # Install Windows Assessment and Deployment Kit (Windows ADK) for Windows 8.1

```PowerShell
& "\\ICEMAN\Public\Download\Microsoft\Windows Assessment and Deployment Kit" `
    + "\Windows ADK for Windows 8.1 Update\adksetup.exe"
```

On the **Select the features you want to install **page:

- Select the following items:
  - **Deployment Tools**
  - **Windows Preinstallation Environment (Windows PE)**
  - **User State Migration Tool (USMT)**
- Click **Install**.

### # Install MDT 2013

```PowerShell
& "\\ICEMAN\Public\Download\Microsoft\Microsoft Deployment Toolkit\MDT 2013" `
    + "\MicrosoftDeploymentToolkit2013_x64.msi"
```

---

**XAVIER1**

### # Create the "MDT - Build" service account

```PowerShell
$displayName = "Service account for Microsoft Deployment Toolkit - Build"
$defaultUserName = "s-mdt-build"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@corp.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=IT,DC=corp,DC=technologytoolbox,DC=com"

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

---

**ICEMAN**

### # Create and share the MDT-Build\$ folder

```PowerShell
New-Item -Path D:\Shares\MDT-Build$ -ItemType Directory
New-SmbShare `
    -Name MDT-Build$ `
    -Path D:\Shares\MDT-Build$ `
    -CachingMode None `
    -ChangeAccess Everyone
```

#### # Remove "BUILTIN\\Users" permissions

```PowerShell
icacls D:\Shares\MDT-Build$ /inheritance:d
icacls D:\Shares\MDT-Build$ /remove:g "BUILTIN\Users"
```

#### # Grant "MDT - Build" service account read access to MDT share

```PowerShell
icacls D:\Shares\MDT-Build$ /grant '"s-mdt-build":(OI)(CI)(RX)'
```

---

## Set up the MDT build lab deployment share

### Reference

**Create a Windows 8.1 Reference Image**\
From <[https://technet.microsoft.com/en-us/library/dn744290.aspx](https://technet.microsoft.com/en-us/library/dn744290.aspx)>

### Create MDT deployment share - "MDT Build Lab (\\\\ICEMAN\\MDT-Build\$)"

1. Open **Deployment Workbench**, right-click **Deployment Shares** and click **New Deployment Share**.
2. Use the following settings for the **New Deployment Share Wizard**:
   1. Path
      - Deployment share path: **[\\\\ICEMAN\\MDT-Build\$](\\ICEMAN\MDT-Build$)**
   2. Descriptive Name
      - Deployment share description: **MDT Build Lab**
   3. Options
      - **Ask if a computer backup should be performed.**
      - **Ask if an image should be captured.**
3. Verify that you can access the [\\\\ICEMAN\\MDT-Build\$](\\ICEMAN\MDT-Build$) share.

---

**WOLVERINE**

### # Baseline the MDT build lab deployment files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

robocopy \\ICEMAN\MDT-Build$ Main\MDT-Build$ /E /XD Backup
```

#### # Add files to TFS

```PowerShell
& "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\TF.exe" add Main /r
```

##### Check-in files

---

---

**ICEMAN**

### # Create the MDT Logs folder

```PowerShell
New-Item -Path D:\Shares\MDT-Build$\Logs -ItemType Directory
```

### # Grant "MDT - Build" service account write access to Captures and Logs folders

```PowerShell
icacls D:\Shares\MDT-Build$\Captures /grant '"s-mdt-build":(OI)(CI)(M)'

icacls D:\Shares\MDT-Build$\Logs /grant '"s-mdt-build":(OI)(CI)(M)'
```

---

```PowerShell
cls
```

## # Import operating systems - Windows 7 and Windows Server 2008 R2

### # Create folder - "Operating Systems\\Window 7"

```PowerShell
Import-Module 'C:\Program Files\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1'

New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root \\ICEMAN\MDT-Build$

New-Item -Path "DS001:\Operating Systems" -Name "Windows 7" -ItemType Folder
```

### # Import operating system - "Windows 7 Ultimate with Service Pack 1 (x86)"

#### # Mount the installation image

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\Windows 7" `
    + "\en_windows_7_ultimate_with_sp1_x86_dvd_u_677460.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$sourcePath = $imageDriveLetter + ":\"
```

#### # Import operating system

```PowerShell
$destinationFolder = "W7Ult-x86-SP1"

$os = Import-MDTOperatingSystem `
    -Path "DS001:\Operating Systems\Windows 7" `
    -SourcePath $sourcePath `
    -DestinationFolder $destinationFolder

$os[0].RenameItem("Windows 7 Starter with Service Pack 1 (x86)")
$os[1].RenameItem("Windows 7 Home Basic with Service Pack 1 (x86)")
$os[2].RenameItem("Windows 7 Home Premium with Service Pack 1 (x86)")
$os[3].RenameItem("Windows 7 Professional with Service Pack 1 (x86)")
$os[4].RenameItem("Windows 7 Ultimate with Service Pack 1 (x86)")
```

#### # Dismount the installation image

```PowerShell
Dismount-DiskImage -ImagePath $imagePath
```

```PowerShell
cls
```

### # Import operating system - "Windows 7 Ultimate with Service Pack 1 (x64)"

#### # Mount the installation image

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\Windows 7" `
    + "\en_windows_7_ultimate_with_sp1_x64_dvd_u_677332.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$sourcePath = $imageDriveLetter + ":\"
```

#### # Import operating system

```PowerShell
$destinationFolder = "W7Ult-x64-SP1"

$os = Import-MDTOperatingSystem `
    -Path "DS001:\Operating Systems\Windows 7" `
    -SourcePath $sourcePath `
    -DestinationFolder $destinationFolder

$os[0].RenameItem("Windows 7 Home Basic with Service Pack 1 (x64)")
$os[1].RenameItem("Windows 7 Home Premium with Service Pack 1 (x64)")
$os[2].RenameItem("Windows 7 Professional with Service Pack 1 (x64)")
$os[3].RenameItem("Windows 7 Ultimate with Service Pack 1 (x64)")
```

#### # Dismount the installation image

```PowerShell
Dismount-DiskImage -ImagePath $imagePath
```

```PowerShell
cls
```

### # Create folder - "Operating Systems\\Windows Server 2008 R2"

```PowerShell
New-Item -Path "DS001:\Operating Systems" -Name "Windows Server 2008 R2" -ItemType Folder
```

### # Import operating system - "Windows Server 2008 R2"

#### # Mount the installation image

```PowerShell
$imagePath = "\\iceman\Products\Microsoft\Windows Server 2008 R2" `
    + "\en_windows_server_2008_r2_with_sp1_x64_dvd_617601.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$sourcePath = $imageDriveLetter + ":\"
```

#### # Import operating system

```PowerShell
$destinationFolder = "WS2008-R2-SP1"

$os = Import-MDTOperatingSystem `
    -Path "DS001:\Operating Systems\Windows Server 2008 R2" `
    -SourcePath $sourcePath `
    -DestinationFolder $destinationFolder

$os[0].RenameItem("Windows Server 2008 R2 Standard with Service Pack 1")
$os[1].RenameItem("Windows Server 2008 R2 Standard (Server Core Installation) with Service Pack 1")
$os[2].RenameItem("Windows Server 2008 R2 Enterprise with Service Pack 1")
$os[3].RenameItem("Windows Server 2008 R2 Enterprise (Server Core Installation) with Service Pack 1")
$os[4].RenameItem("Windows Server 2008 R2 Datacenter with Service Pack 1")
$os[5].RenameItem("Windows Server 2008 R2 Datacenter (Server Core Installation) with Service Pack 1")
$os[6].RenameItem("Windows Server 2008 R2 Web Edition with Service Pack 1")
$os[7].RenameItem("Windows Server 2008 R2 Web Edition (Server Core Installation) with Service Pack 1")
```

#### # Dismount the installation image

```PowerShell
Dismount-DiskImage -ImagePath $imagePath
```

---

**WOLVERINE**

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\DiffMerge.exe \\ICEMAN\MDT-Build$ '.\Main\MDT-Build$'
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

## # Create task sequences for building Windows 7 baseline images

```PowerShell
cls
```

### # Create folder - "Task Sequences\\Window 7"

```PowerShell
New-Item -Path "DS001:\Task Sequences" -Name "Windows 7" -ItemType Folder
```

### # Create task sequence - "Windows 7 Ultimate (x86) - Baseline"

```PowerShell
$osPath = "DS001:\Operating Systems\Windows 7" `
    + "\Windows 7 Ultimate with Service Pack 1 (x86)"

Import-MDTTaskSequence `
    -Path "DS001:\Task Sequences\Windows 7" `
    -ID "W7ULT-X86-REF" `
    -Name "Windows 7 Ultimate (x86) - Baseline" `
    -Comments "Reference image" `
    -Version "1.0" `
    -Template "Client.xml" `
    -OperatingSystemPath $osPath `
    -FullName "Windows User" `
    -OrgName "Technology Toolbox" `
    -HomePage "about:blank" `
    -ProductKey "6VR38-H4DQY-2WGBQ-GBH9X-FVRFQ"
```

> **Important**
>
> The MSDN version of Windows 7 will prompt to enter a product key (but provide an option to skip this step). It does not honor the SkipProductKey=YES entry in the MDT CustomSettings.ini file.

### # Create task sequence - "Windows 7 Ultimate (x64) - Baseline"

```PowerShell
$osPath = "DS001:\Operating Systems\Windows 7" `
    + "\Windows 7 Ultimate with Service Pack 1 (x64)"

Import-MDTTaskSequence `
    -Path "DS001:\Task Sequences\Windows 7" `
    -ID "W7ULT-X64-REF" `
    -Name "Windows 7 Ultimate (x64) - Baseline" `
    -Comments "Reference image" `
    -Version "1.0" `
    -Template "Client.xml" `
    -OperatingSystemPath $osPath `
    -FullName "Windows User" `
    -OrgName "Technology Toolbox" `
    -HomePage "about:blank" `
    -ProductKey "6VR38-H4DQY-2WGBQ-GBH9X-FVRFQ"
```

> **Important**
>
> The MSDN version of Windows 7 will prompt to enter a product key (but provide an option to skip this step). It does not honor the SkipProductKey=YES entry in the MDT CustomSettings.ini file.

```PowerShell
cls
```

## # Create task sequence for building Windows Server 2008 R2 baseline image

### # Create folder - "Task Sequences\\Windows Server 2008 R2"

```PowerShell
New-Item -Path "DS001:\Task Sequences" -Name "Windows Server 2008 R2" -ItemType Folder
```

### # Create task sequence - "Windows Server 2008 R2 - Baseline"

```PowerShell
$osPath = "DS001:\Operating Systems\Windows Server 2008 R2" `
    + "\Windows Server 2008 R2 Standard with Service Pack 1"

Import-MDTTaskSequence `
    -Path "DS001:\Task Sequences\Windows Server 2008 R2" `
    -ID "WS2008-R2-REF" `
    -Name "Windows Server 2008 R2 - Baseline" `
    -Comments "Reference image" `
    -Version "1.0" `
    -Template "Server.xml" `
    -OperatingSystemPath $osPath `
    -FullName "Windows User" `
    -OrgName "Technology Toolbox" `
    -HomePage "about:blank" `
    -ProductKey "MC7YT-29JPW-24MFT-7F968-JCM9W"
```

> **Important**
>
> The MSDN version of Windows Server 2008 R2 will prompt to enter a product key (but provide an option to skip this step). It does not honor the SkipProductKey=YES entry in the MDT CustomSettings.ini file.

---

**WOLVERINE**

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\DiffMerge.exe \\ICEMAN\MDT-Build$ '.\Main\MDT-Build$'
```

#### # Sync files

```PowerShell
robocopy \\ICEMAN\MDT-Build$ Main\MDT-Build$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools
```

#### # Add files to TFS

```PowerShell
& "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\TF.exe" add Main /r
```

#### Check-in files

---

## Create Windows PE boot images for MDT build lab deployment share

### Configure MDT deployment settings

1. Open **Deployment Workbench**, expand **Deployment Shares**, right-click **MDT Build Lab ([\\\\ICEMAN\\MDT-Build\$](\\ICEMAN\MDT-Build$))**, and click **Properties.**
2. On the **Rules** tab:
   1. Specify the following rules:
   2. Click **Edit Bootstrap.ini** and specify the following information:
3. On the **Windows PE** tab:
   1. In the **Platform** drop-down list, click **x86**.
   2. In the **Lite Touch Boot Image Settings** section, configure the following settings:
      1. Image description: **MDT Build Lab (x86)**
      2. ISO file name: **MDT-Build-x86.iso**
   3. In the **Platform** drop-down list, click **x64**.
   4. In the **Lite Touch Boot Image Settings** section, configure the following settings:
      1. Image description: **MDT Build Lab (x64)**
      2. ISO file name: **MDT-Build-x64.iso**
4. Click **OK**.

```INI
        [Settings]
        Priority=Default

        [Default]
        _SMSTSORGNAME=Technology Toolbox
        UserDataLocation=NONE
        DoCapture=YES
        BackupFile=%TaskSequenceID%_# Replace(Replace(Replace(FormatDateTime(Now,0),"/","-"), " ", "-"), ":", "-") #.wim
        OSInstall=Y
        TimeZoneName=Mountain Standard Time
        JoinWorkgroup=WORKGROUP
        HideShell=YES
        FinishAction=SHUTDOWN
        DoNotCreateExtraPartition=YES
        WSUSServer=http://colossus:8530
        ApplyGPOPack=NO
        SLSHARE=\\ICEMAN\MDT-Build$\Logs

        SkipAdminPassword=YES
        SkipProductKey=YES
        SkipComputerName=YES
        SkipDomainMembership=YES
        SkipUserData=YES
        SkipLocaleSelection=YES
        SkipTaskSequence=NO
        SkipTimeZone=YES
        SkipApplications=YES
        SkipBitLocker=YES
        SkipSummary=YES
        SkipRoles=YES
        SkipCapture=NO
        SkipFinalSummary=YES
```

```INI
        [Settings]
        Priority=Default

        [Default]
        DeployRoot=\\ICEMAN\MDT-Build$
        UserDomain=TECHTOOLBOX
        UserID=s-mdt-build
        SkipBDDWelcome=YES
```

---

**WOLVERINE**

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\DiffMerge.exe \\ICEMAN\MDT-Build$ '.\Main\MDT-Build$'
```

#### # Sync files

```PowerShell
robocopy \\ICEMAN\MDT-Build$ Main\MDT-Build$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools
```

#### Check-in files

---

### Update the deployment share

After the deployment share has been configured, it needs to be updated. This will create the Windows PE boot images.

1. Open **Deployment Workbench**, right-click the **MDT Build Lab ([\\\\ICEMAN\\MDT-Build\$](\\ICEMAN\MDT-Build$))** and click **Update Deployment Share**.
2. Use the default options for the **Update Deployment Share Wizard**.

| **Note**                                                 |
| -------------------------------------------------------- |
| The update process may take 5 to 10 minutes to complete. |
|                                                          |

```Console
cls
```

# Build baseline images

### # Copy MDT boot images to Products file share

```PowerShell
robocopy '\\ICEMAN\MDT-Build$\Boot' '\\ICEMAN\Products\Microsoft' *.iso
```

---

**STORM**

### # Create temporary VM to build image - "Windows 7 Ultimate (x86) - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Build-x86.iso -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows 7 Ultimate (x64) - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Build-x86.iso -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows Server 2008 R2 - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Build-x86.iso -Force
```

---

<table>
<thead>
<th>
<p><strong>Task Sequence</strong></p>
</th>
<th>
<p><strong>Start</strong></p>
</th>
<th>
<p><strong>End</strong></p>
</th>
<th>
<p><strong>Duration[HH:MM:SS]</strong></p>
</th>
<th>
<p><strong>Image Size [KB]</strong></p>
</th>
<th>
<p><strong>Comments</strong></p>
</th>
</thead>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x86) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 07:42</p>
</td>
<td valign='top'>
<p>2015-04-13 08:01</p>
</td>
<td valign='top'>
<p>00:18:45</p>
</td>
<td valign='top'>
<p>2,069,449</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 08:01</p>
</td>
<td valign='top'>
<p>2015-04-13 08:24</p>
</td>
<td valign='top'>
<p>00:22:36</p>
</td>
<td valign='top'>
<p>2,754,165</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2008 R2 - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 08:42</p>
</td>
<td valign='top'>
<p>2015-04-13 09:04</p>
</td>
<td valign='top'>
<p>00:21:14</p>
</td>
<td valign='top'>
<p>2,477,925</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
</table>

## Customize Windows 7 and Windows Server 2008 R2 baseline images

### Configure task sequence - "Windows 7 Ultimate (x86) - Baseline"

Edit the task sequence to include the actions required to update the reference image with the latest updates from WSUS, copy Toolbox content from ICEMAN, install .NET Framework 3.5, and easily suspend the deployment process after installing applications.

1. Open **Deployment Workbench**, expand **Deployment Shares / MDT Build Lab ([\\\\ICEMAN\\MDT-Build\$](\\ICEMAN\MDT-Build$)) / Task Sequences / Windows 7**, right-click **Windows 7 Ultimate (x86) - Baseline**, and click **Properties**.
2. In the **Windows 7 Ultimate (x86) - Baseline Properties** window:
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
            2. Select the operating system for which roles are to be installed: **Windows 7**
            3. Select the roles and features that should be installed: **.NET Framework 3.5.1**
         7. After the **Install Applications** action, add a new **Run Command Line** action with the following settings:
            1. Name: **Suspend**
            2. Command line: **cscript.exe "%SCRIPTROOT%\\LTISuspend.wsf"**
            3. Disable this step:** Yes (checked)**
   3. Click **OK**.

> **Note**
>
> The reason for adding the applications after the Tattoo action but before running Windows Update is simply to save time during the deployment. This way we can add all applications that will upgrade some of the built-in components and avoid unnecessary updating.

### Configure task sequence - "Windows 7 Ultimate (x64) - Baseline"

Repeat the steps in the previous section for the **Windows 7 Ultimate (x64) - Baseline** task sequence.

### Configure task sequence - "Windows Server 2008 R2 - Baseline"

Edit the task sequence to include the actions required to update the reference image with the latest updates from WSUS, copy Toolbox content from ICEMAN, install .NET Framework 3.5, and easily suspend the deployment process after installing applications.

1. Open **Deployment Workbench**, expand **Deployment Shares / MDT Build Lab ([\\\\ICEMAN\\MDT-Build\$](\\ICEMAN\MDT-Build$)) / Task Sequences / Windows Server 2008 R2**, right-click **Windows Server 2008 R2 - Baseline**, and click **Properties**.
2. In the **Windows Server 2008 R2 - Baseline Properties** window:
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
            2. Select the operating system for which roles are to be installed: **Windows Server 2008 R2**
            3. Select the roles and features that should be installed: **.NET Framework 3.5.1**
         7. After the **Install Applications** action, add a new **Run Command Line** action with the following settings:
            1. Name: **Suspend**
            2. Command line: **cscript.exe "%SCRIPTROOT%\\LTISuspend.wsf"**
            3. Disable this step:** Yes (checked)**
   3. Click **OK**.

> **Note**
>
> The reason for adding the applications after the Tattoo action but before running Windows Update is simply to save time during the deployment. This way we can add all applications that will upgrade some of the built-in components and avoid unnecessary updating.

```PowerShell
cls
```

## # Add Office 2013 to Windows 7 baseline images

### # Create folder - "Applications\\Microsoft"

```PowerShell
Import-Module 'C:\Program Files\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1'

New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root \\ICEMAN\MDT-Build$

New-Item -Path "DS001:\Applications" -Name "Microsoft" -ItemType Folder
```

### # Import application - "Office Professional Plus 2013 (x86)"

#### # Mount the installation image

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\Office 2013\" `
    + "en_office_professional_plus_2013_with_sp1_x86_and_x64_dvd_3928186.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$appSourcePath = $imageDriveLetter + ":\x86"
```

#### # Import application

\$appName = "Office Professional Plus 2013 (x86)"

```PowerShell
$appShortName = "Office2013ProPlus-x86"
$appSetupFolder = $appShortName
$commandLine = "setup.exe /config ProPlusr.ww\Config.xml"

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

### Configure installation settings for Office 2013

1. Open **Deployment Workbench**, expand **Deployment Shares / MDT Build Lab ([\\\\ICEMAN\\MDT-Build\$](\\ICEMAN\MDT-Build$)) / Applications / Microsoft**, right-click **Office 2013 Professional Plus (x86)**, and click **Properties**.
2. In the **Office 2013 Professional Plus (x86) Properties** window:
   1. On the **Office Products** tab:
      1. In the **Office product to install** dropdown, click **ProPlusr**.
      2. In the **Config.xml settings** section:
         1. Click **Customer name** and then type **Technology Toolbox**.
         2. Click **Display level** and then select **None**.
         3. Click **Accept EULA**.
         4. Click **Always suppress reboot**.
   2. Click **OK**.

### Add action to "Windows 7 Ultimate (x86) - Baseline" task sequence to install Office 2013

1. Open **Deployment Workbench**, expand **Deployment Shares / MDT Build Lab ([\\\\ICEMAN\\MDT-Build\$](\\ICEMAN\MDT-Build$)) / Task Sequences / Windows 7**, right-click **Windows 7 Ultimate (x86) - Baseline**, and click **Properties**.
2. In the **Windows 7 Ultimate (x86) - Baseline Properties** window:
   1. On the **General **tab, configure the following settings:
      1. Comments: **Reference image - Toolbox content, .NET Framework 3.5, Office 2013, and latest patches**
   2. On the **Task Sequence** tab, configure the following settings:
      1. **State Restore**
         1. Select the **Custom Tasks (Pre-Windows Update)** group and add a new **Install Application** action with the following settings:
            1. Name: **Install Microsoft Office 2013 Professional Plus (x86)**
            2. **Install a single application**
            3. Application to install: **Applications / Microsoft / Office 2013 Professional Plus (x86)**
         2. After the **Install Microsoft Office 2013 Professional Plus (x86)** action, add a new **Restart computer** action.
   3. Click **OK**.

### Add action to "Windows 7 Ultimate (x64) - Baseline" task sequence to install Office 2013

Repeat the steps in the previous section for the **Windows 7 Ultimate (x64) - Baseline** task sequence.

---

**WOLVERINE**

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\DiffMerge.exe \\ICEMAN\MDT-Build$ '.\Main\MDT-Build$'
```

#### # Sync files

```PowerShell
robocopy \\ICEMAN\MDT-Build$ Main\MDT-Build$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools
```

#### Check-in files

---

```Console
cls
```

# Build baseline images

---

**STORM**

### # Create temporary VM to build image - "Windows 7 Ultimate (x86) - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Build-x86.iso -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows 7 Ultimate (x64) - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Build-x86.iso -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows Server 2008 R2 - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Build-x86.iso -Force
```

---

<table>
<thead>
<th>
<p><strong>Task Sequence</strong></p>
</th>
<th>
<p><strong>Start</strong></p>
</th>
<th>
<p><strong>End</strong></p>
</th>
<th>
<p><strong>Duration[HH:MM:SS]</strong></p>
</th>
<th>
<p><strong>Image Size [KB]</strong></p>
</th>
<th>
<p><strong>Comments</strong></p>
</th>
</thead>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x86) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 07:42</p>
</td>
<td valign='top'>
<p>2015-04-13 08:01</p>
</td>
<td valign='top'>
<p>00:18:45</p>
</td>
<td valign='top'>
<p>2,069,449</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 08:01</p>
</td>
<td valign='top'>
<p>2015-04-13 08:24</p>
</td>
<td valign='top'>
<p>00:22:36</p>
</td>
<td valign='top'>
<p>2,754,165</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2008 R2 - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 08:42</p>
</td>
<td valign='top'>
<p>2015-04-13 09:04</p>
</td>
<td valign='top'>
<p>00:21:14</p>
</td>
<td valign='top'>
<p>2,477,925</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x86) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 09:30</p>
</td>
<td valign='top'>
<p>2015-04-13 13:22</p>
</td>
<td valign='top'>
<p>03:51:50</p>
</td>
<td valign='top'>
<p>6,006,079</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 13:35</p>
</td>
<td valign='top'>
<p>2015-04-13 20:42</p>
</td>
<td valign='top'>
<p>07:06:52</p>
</td>
<td valign='top'>
<p>7,942,451</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2008 R2 - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 21:32</p>
</td>
<td valign='top'>
<p>2015-04-14 02:47</p>
</td>
<td valign='top'>
<p>05:14:50</p>
</td>
<td valign='top'>
<p>3,740,460</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
</table>

## Set up the MDT production deployment share

From <[https://technet.microsoft.com/en-us/library/dn744279.aspx](https://technet.microsoft.com/en-us/library/dn744279.aspx)>

---

**XAVIER1**

### # Create the "MDT - Deploy" service account

```PowerShell
$displayName = "Service account for Microsoft Deployment Toolkit - Deploy"
$defaultUserName = "s-mdt-deploy"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@corp.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=IT,DC=corp,DC=technologytoolbox,DC=com"

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

---

**ICEMAN**

### # Create and share the MDT-Deploy\$ folder

```PowerShell
New-Item -Path D:\Shares\MDT-Deploy$ -ItemType Directory
New-SmbShare `
    -Name MDT-Deploy$ `
    -Path D:\Shares\MDT-Deploy$ `
    -CachingMode None `
    -ChangeAccess Everyone
```

#### # Remove "BUILTIN\\Users" permissions

```PowerShell
icacls D:\Shares\MDT-Deploy$ /inheritance:d
icacls D:\Shares\MDT-Deploy$ /remove:g "BUILTIN\Users"
```

#### # Grant "MDT - Deploy" service account read access to MDT share

```PowerShell
icacls D:\Shares\MDT-Deploy$ /grant '"s-mdt-deploy":(OI)(CI)(RX)'
```

---

### Create the MDT production deployment share

1. Open **Deployment Workbench**, right-click **Deployment Shares** and click **New Deployment Share**.
2. Use the following settings for the **New Deployment Share Wizard**:
   1. Path
      - Deployment share path: **[\\\\ICEMAN\\MDT-Deploy\$](\\ICEMAN\MDT-Deploy$)**
   2. Descriptive Name
      - Deployment share description: **MDT Deployment**
   3. Options
      - **Ask if a computer backup should be performed.**
3. Verify that you can access the [\\\\ICEMAN\\MDT-Deploy\$](\\ICEMAN\MDT-Deploy$) share.

---

**WOLVERINE**

### # Baseline the MDT production deployment files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

robocopy \\ICEMAN\MDT-Deploy$ Main\MDT-Deploy$ /E /XD Backup
```

#### # Add files to TFS

```PowerShell
& "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\TF.exe" add Main /r
```

##### Check-in files

---

---

**ICEMAN**

### # Create the MDT Logs folder

```PowerShell
New-Item -Path D:\Shares\MDT-Deploy$\Logs -ItemType Directory
```

### # Grant "MDT - Deploy" service account write access to Logs folder

```PowerShell
icacls D:\Shares\MDT-Deploy$\Logs /grant '"s-mdt-deploy":(OI)(CI)(M)'
```

---

## # Add custom images to MDT production deployment share

### # Create folder - "Operating Systems\\Window 7"

```PowerShell
Import-Module 'C:\Program Files\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1'

New-PSDrive -Name "DS002" -PSProvider MDTProvider -Root \\ICEMAN\MDT-Deploy$

New-Item -Path "DS002:\Operating Systems" -Name "Windows 7" -ItemType Folder
```

```PowerShell
cls
```

### # Import operating system - "Windows 7 Ultimate (x86) - Baseline"

```PowerShell
$imagePath = "\\ICEMAN\MDT-Build$\Captures\W7ULT-X86-REF_4-13-2015-9-31-28-AM.wim"

$destinationFolder = "W7Ult-x86"

$os = Import-MDTOperatingSystem `
    -Path "DS002:\Operating Systems\Windows 7" `
    -SourceFile $imagePath `
    -DestinationFolder $destinationFolder `
    -Move

$os.RenameItem("Windows 7 Ultimate (x86) - Baseline")
```

```PowerShell
cls
```

### # Import operating system - "Windows 7 Ultimate (x64) - Baseline"

```PowerShell
$imagePath = "\\ICEMAN\MDT-Build$\Captures\W7ULT-X64-REF_4-13-2015-1-36-13-PM.wim"

$destinationFolder = "W7Ult-x64"

$os = Import-MDTOperatingSystem `
    -Path "DS002:\Operating Systems\Windows 7" `
    -SourceFile $imagePath `
    -DestinationFolder $destinationFolder `
    -Move

$os.RenameItem("Windows 7 Ultimate (x64) - Baseline")
```

```PowerShell
cls
```

### # Create folder - "Operating Systems\\Windows Server 2008 R2"

```PowerShell
New-Item -Path "DS002:\Operating Systems" -Name "Windows Server 2008 R2" -ItemType Folder
```

```PowerShell
cls
```

### # Import operating system - "Windows Server 2008 R2 Standard - Baseline"

```PowerShell
$imagePath = "\\ICEMAN\MDT-Build$\Captures\WS2008-R2-REF_4-13-2015-9-33-14-PM.wim"

$destinationFolder = "WS2008-R2"

$os = Import-MDTOperatingSystem `
    -Path "DS002:\Operating Systems\Windows Server 2008 R2" `
    -SourceFile $imagePath `
    -DestinationFolder $destinationFolder `
    -Move

$os.RenameItem("Windows Server 2008 R2 Standard - Baseline")
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
& "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\TF.exe" add Main /r
```

##### Check-in files

---

```PowerShell
cls
```

## # Create task sequences for deployments

### # Create folder - "Task Sequences\\Window 7"

```PowerShell
New-Item -Path "DS002:\Task Sequences" -Name "Windows 7" -ItemType Folder
```

### # Create task sequence - "Windows 7 Ultimate (x86)"

```PowerShell
$osPath = "DS002:\Operating Systems\Windows 7\Windows 7 Ultimate (x86) - Baseline"

Import-MDTTaskSequence `
    -Path "DS002:\Task Sequences\Windows 7" `
    -ID "W7ULT-X86" `
    -Name "Windows 7 Ultimate (x86)" `
    -Comments "Production image" `
    -Version "1.0" `
    -Template "Client.xml" `
    -OperatingSystemPath $osPath `
    -FullName "Windows User" `
    -OrgName "Technology Toolbox" `
    -HomePage "about:blank" `
    -ProductKey "6VR38-H4DQY-2WGBQ-GBH9X-FVRFQ"
```

> **Important**
>
> The MSDN version of Windows 7 will prompt to enter a product key (but provide an option to skip this step). It does not honor the SkipProductKey=YES entry in the MDT CustomSettings.ini file.

```PowerShell
cls
```

### # Create task sequence - "Windows 7 Ultimate (x64)"

```PowerShell
$osPath = "DS002:\Operating Systems\Windows 7\Windows 7 Ultimate (x64) - Baseline"

Import-MDTTaskSequence `
    -Path "DS002:\Task Sequences\Windows 7" `
    -ID "W7ULT-X64" `
    -Name "Windows 7 Ultimate (x64)" `
    -Comments "Production image" `
    -Version "1.0" `
    -Template "Client.xml" `
    -OperatingSystemPath $osPath `
    -FullName "Windows User" `
    -OrgName "Technology Toolbox" `
    -HomePage "about:blank" `
    -ProductKey "6VR38-H4DQY-2WGBQ-GBH9X-FVRFQ"
```

> **Important**
>
> The MSDN version of Windows 7 will prompt to enter a product key (but provide an option to skip this step). It does not honor the SkipProductKey=YES entry in the MDT CustomSettings.ini file.

```PowerShell
cls
```

### # Create folder - "Task Sequences\\Windows Server 2008 R2"

```PowerShell
New-Item -Path "DS002:\Task Sequences" -Name "Windows Server 2008 R2" -ItemType Folder
```

### # Create task sequence - "Windows Server 2008 R2"

```PowerShell
$osPath = "DS002:\Operating Systems\Windows Server 2008 R2" `
    + "\Windows Server 2008 R2 Standard - Baseline"

Import-MDTTaskSequence `
    -Path "DS002:\Task Sequences\Windows Server 2008 R2" `
    -ID "WS2008-R2" `
    -Name "Windows Server 2008 R2" `
    -Comments "Production image" `
    -Version "1.0" `
    -Template "Server.xml" `
    -OperatingSystemPath $osPath `
    -FullName "Windows User" `
    -OrgName "Technology Toolbox" `
    -HomePage "about:blank" `
    -ProductKey "MC7YT-29JPW-24MFT-7F968-JCM9W"
```

> **Important**
>
> The MSDN version of Windows Server 2008 R2 will prompt to enter a product key (but provide an option to skip this step). It does not honor the SkipProductKey=YES entry in the MDT CustomSettings.ini file.

---

**WOLVERINE**

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

robocopy \\ICEMAN\MDT-Deploy$ Main\MDT-Deploy$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools
```

#### # Add files to TFS

```PowerShell
& "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\TF.exe" add Main /r
```

##### Check-in files

---

## Create Windows PE boot images for MDT production deployment share

### Configure MDT deployment settings

1. Open **Deployment Workbench**, expand **Deployment Shares**, right-click **MDT Deployment ([\\\\ICEMAN\\MDT-Deploy\$](\\ICEMAN\MDT-Deploy$))**, and click **Properties.**
2. On the **Rules** tab:
   1. Specify the following rules:
   2. Click **Edit Bootstrap.ini** and specify the following information:
3. On the **Windows PE** tab:
   1. In the **Platform** drop-down list, click **x86**.
   2. In the **Lite Touch Boot Image Settings** section, configure the following settings:
      1. Image description: **MDT Deploy (x86)**
      2. ISO file name: **MDT-Deploy-x86.iso**
   3. In the **Platform** drop-down list, click **x64**.
   4. In the **Lite Touch Boot Image Settings** section, configure the following settings:
      1. Image description: **MDT Deploy (x64)**
      2. ISO file name: **MDT-Deploy-x64.iso**
4. On the **Monitoring** tab, configure the following settings:
   1. Enable monitoring for this deployment share: **Yes (checked)**
   2. Monitoring host: **MIMIC**
   3. Event port:** 9800**
   4. Data port: **9801**
5. Click **OK**.

```INI
        [Settings]
        Priority=Default

        [Default]
        _SMSTSORGNAME=Technology Toolbox
        OSInstall=YES
        TimeZoneName=Mountain Standard Time
        UserDataLocation=AUTO
        JoinDomain=corp.technologytoolbox.com
        HideShell=YES
        WSUSServer=http://colossus:8530
        ApplyGPOPack=NO
        SLSHARE=\\ICEMAN\MDT-Deploy$\Logs
        ScanStateArgs=/ue:*\* /ui:TECHTOOLBOX\*
        USMTMigFiles001=MigApp.xml
        USMTMigFiles002=MigUser.xml

        SkipAdminPassword=YES
        SkipApplications=NO
        SkipAppsOnUpgrade=NO
        SkipBitLocker=YES
        SkipCapture=YES
        SkipComputerName=NO
        SkipDomainMembership=NO
        SkipFinalSummary=NO
        SkipLocaleSelection=YES
        SkipProductKey=YES
        SkipTaskSequence=NO
        SkipTimeZone=YES
        SkipUserData=YES
        SkipSummary=YES
```

```INI
        [Settings]
        Priority=Default

        [Default]
        DeployRoot=\\ICEMAN\MDT-Deploy$
        UserDomain=TECHTOOLBOX
        UserID=s-mdt-deploy
        SkipBDDWelcome=YES
```

```PowerShell
cls
```

### # Create list of organizational units to select from when deploying

```PowerShell
$xml = New-Object XML
$xml.LoadXml(
'<?xml version="1.0" encoding="utf-8"?>
<DomainOUs>
  <DomainOU>OU=Servers,OU=Resources,OU=Development,DC=corp,DC=technologytoolbox,DC=com</DomainOU>
  <DomainOU>OU=Workstations,OU=Resources,OU=Development,DC=corp,DC=technologytoolbox,DC=com</DomainOU>
  <DomainOU>OU=Laptops,OU=Resources,OU=IT,DC=corp,DC=technologytoolbox,DC=com</DomainOU>
  <DomainOU>OU=Servers,OU=Resources,OU=IT,DC=corp,DC=technologytoolbox,DC=com</DomainOU>
  <DomainOU>OU=Workstations,OU=Resources,OU=IT,DC=corp,DC=technologytoolbox,DC=com</DomainOU>
</DomainOUs>')

$xml.Save("\\ICEMAN\MDT-Deploy$\Scripts\DomainOUList.xml")
```

---

**WOLVERINE**

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\DiffMerge.exe \\ICEMAN\MDT-Deploy$ '.\Main\MDT-Deploy$'
```

#### # Sync files

```PowerShell
robocopy \\ICEMAN\MDT-Deploy$ Main\MDT-Deploy$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools
```

#### # Add files to TFS

```PowerShell
& "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\TF.exe" add Main /r
```

#### Check-in files

---

### Update the deployment share

After the deployment share has been configured, it needs to be updated. This is the process when the Windows PE boot images are created.

1. Open **Deployment Workbench**, right-click the **MDT Production ([\\\\ICEMAN\\MDT-Deploy\$](\\ICEMAN\MDT-Deploy$))** and click **Update Deployment Share**.
2. Use the default options for the **Update Deployment Share Wizard**.

> **Note**
>
> The update process will take 5 to 10 minutes.

```Console
cls
```

# Deploy baseline image - "Windows 7 Ultimate (x86)"

### # Copy MDT boot images to Products file share

```PowerShell
robocopy '\\ICEMAN\MDT-Deploy$\Boot' '\\ICEMAN\Products\Microsoft' *.iso
```

---

**STORM**

### # Create temporary VM to build image - "Windows 7 Ultimate (x86)"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso -Force
```

---

<table>
<thead>
<th>
<p><strong>Task Sequence</strong></p>
</th>
<th>
<p><strong>Start</strong></p>
</th>
<th>
<p><strong>End</strong></p>
</th>
<th>
<p><strong>Duration[HH:MM:SS]</strong></p>
</th>
<th>
<p><strong>VHD Size [KB]</strong></p>
</th>
<th>
<p><strong>Comments</strong></p>
</th>
</thead>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x86)</p>
</td>
<td valign='top'>
<p>2015-04-14 08:31</p>
</td>
<td valign='top'>
<p>2015-04-14 08:46</p>
</td>
<td valign='top'>
<p>00:14:53</p>
</td>
<td valign='top'>
<p>13,537,280</p>
</td>
<td valign='top'>
<ul>
<li>Image: W7ULT-X86-REF_4-13-2015-9-31-28-AM.wim</li>
<li>No additional applications or patches installed</li>
</ul>
</td>
</tr>
</table>

```PowerShell
cls
```

## # Add applications

### # Create folder - "Applications\\Adobe"

```PowerShell
Import-Module 'C:\Program Files\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1'

New-PSDrive -Name "DS002" -PSProvider MDTProvider -Root \\ICEMAN\MDT-Deploy$

New-Item -Path "DS002:\Applications" -Name "Adobe" -ItemType Folder
```

### # Create application: Adobe Reader 8.3

\$appName = "Adobe Reader 8.3"

```PowerShell
$appShortName = "Adobe-Reader-83"
$commandLine = 'msiexec /i "\\iceman\Products\Adobe\AdbeRdr830_en_US.msi" /q'

Import-MDTApplication `
    -Path "DS002:\Applications\Adobe" `
    -Name $appName `
    -ShortName $appShortName `
    -NoSource `
    -CommandLine $commandLine `
    -Hide "True"
```

### # Create application: Adobe Reader 8.3.1 Update

\$appName = "Adobe Reader 8.3.1 Update"

```PowerShell
$appShortName = "Adobe-Reader-831-Update"
$commandLine = 'msiexec /update "\\iceman\Products\Adobe\AdbeRdrUpd831_all_incr.msp" /q'

Import-MDTApplication `
    -Path "DS002:\Applications\Adobe" `
    -Name $appName `
    -ShortName $appShortName `
    -NoSource `
    -CommandLine $commandLine `
    -Hide "True"
```

### # Create application bundle: Adobe Reader 8.3.1

#### # Add application bundle - Adobe Reader 8.3.1

\$appName = "Adobe Reader 8.3.1"

```PowerShell
$appShortName = "Adobe-Reader-831"

Import-MDTApplication `
    -Path "DS002:\Applications\Adobe" `
    -Name $appName `
    -ShortName $appShortName `
    -Bundle
```

#### # Configure application bundle - Adobe Reader 8.3.1

1. Open **Deployment Workbench**, expand **Deployment Shares / MDT Deployment ([\\\\ICEMAN\\MDT-Deploy\$](\\ICEMAN\MDT-Deploy$)) / Applications / Adobe**, right-click **Adobe Reader 8.3.1**, and click **Properties**.
2. In the **Adobe Reader 8.3.1 Properties** window:
   1. On the **Dependencies** tab:
      1. Add the following applications:
         1. **Adobe Reader 8.3**
         2. **Adobe Reader 8.3.1 Update**
      2. Ensure the applications in the previous step are listed in the specified order. Use the **Up** or **Down** buttons to reorder the applications as necessary.
   2. Click **OK**.

```PowerShell
cls
```

### # Create folder - "Applications\\Google"

```PowerShell
New-Item -Path "DS002:\Applications" -Name Google -ItemType Folder
```

```PowerShell
cls
```

### # Create application: Google Chrome

\$appName = "Chrome"

```PowerShell
$appShortName = "Chrome"
$commandLine = 'msiexec /i "\\ICEMAN\Products\Google\Chrome\googlechromestandaloneenterprise.msi" /q'

Import-MDTApplication `
    -Path "DS002:\Applications\Google" `
    -Name $appName `
    -ShortName $appShortName `
    -NoSource `
    -CommandLine $commandLine
```

```PowerShell
cls
```

### # Create folder - "Applications\\Microsoft"

```PowerShell
New-Item -Path "DS002:\Applications" -Name Microsoft -ItemType Folder
```

```PowerShell
cls
```

### # Create application: Microsoft SharePoint Designer 2013 with Service Pack 1 (x86)

#### # Extract the content of the setup package

```PowerShell
$packagePath = "\\ICEMAN\Products\Microsoft\SharePoint Designer 2013\" `
    + "en_sharepoint_designer_2013_with_sp1_x86_3948134.exe"

$tempSourcePath = "C:\NotBackedUp\Temp\SPD2013-x86-SP1"

& $packagePath /extract:$tempSourcePath
```

> **Important**
>
> Wait for the package content to be extracted.

```PowerShell
cls
```

#### # Import the application

\$appName = "SharePoint Designer 2013 with Service Pack 1 (x86)"

```PowerShell
$appShortName = "SPD2013-x86-SP1"
$appSetupFolder = $appShortName
$commandLine = "setup.exe /config sharepointdesigner.ww\config.xml"

Import-MDTApplication `
    -Path "DS002:\Applications\Microsoft" `
    -Name $appName `
    -ShortName $appShortName `
    -ApplicationSourcePath $tempSourcePath `
    -DestinationFolder $appSetupFolder `
    -CommandLine $commandLine `
    -WorkingDirectory ".\Applications\$appSetupFolder"
```

#### # Delete the temporary files

```PowerShell
Remove-Item $tempSourcePath -Force -Recurse
```

#### Configure Microsoft SharePoint Designer 2013 installation settings

1. Open **Deployment Workbench**, expand **Deployment Shares / MDT Deployment ([\\\\ICEMAN\\MDT-Deploy\$](\\ICEMAN\MDT-Deploy$)) / Applications / Microsoft**, right-click **SharePoint Designer 2013 with Service Pack 1 (x86)**, and click **Properties**.
2. In the **SharePoint Designer 2013 with Service Pack 1 (x86) Properties** window:
   1. On the **Office Products** tab:
      1. In the **Office product to install** dropdown, ensure **SharePointDesigner** is selected.
      2. In the **Config.xml settings** section:
         1. Click the **Customer name** checkbox and then type **Technology Toolbox **in the corresponding textbox.
         2. Click the **Display level** checkbox and then click **None **in the corresponding dropdown list.
         3. Click the **Accept EULA **checkbox.
         4. Click the **Always suppress reboot **checkbox.
   2. In the **SharePoint Designer 2013 with Service Pack 1 (x86) Properties** window, click **OK**.

```PowerShell
cls
```

### # Create folder - "Applications\\Mozilla"

```PowerShell
New-Item -Path "DS002:\Applications" -Name Mozilla -ItemType Folder
```

```PowerShell
cls
```

### # Create application: Mozilla Firefox 36.0

\$appName = "Firefox 36.0"

```PowerShell
$appShortName = "Firefox"
$commandLine = '"\\ICEMAN\Products\Mozilla\Firefox\Firefox Setup 36.0.exe" -ms'

Import-MDTApplication `
    -Path "DS002:\Applications\Mozilla" `
    -Name $appName `
    -ShortName $appShortName `
    -NoSource `
    -CommandLine $commandLine
```

### # Create application: Mozilla Thunderbird 31.3.0

\$appName = "Thunderbird 31.3.0"

```PowerShell
$appShortName = "Thunderbird"
$commandLine = '"\\ICEMAN\Products\Mozilla\Thunderbird\Thunderbird Setup 31.3.0.exe" -ms'

Import-MDTApplication `
    -Path "DS002:\Applications\Mozilla" `
    -Name $appName `
    -ShortName $appShortName `
    -NoSource `
    -CommandLine $commandLine
```

---

**WOLVERINE**

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\DiffMerge.exe \\ICEMAN\MDT-Deploy$ '.\Main\MDT-Deploy$'
```

#### # Sync files

```PowerShell
robocopy \\ICEMAN\MDT-Deploy$ Main\MDT-Deploy$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools
```

#### Check-in files

---

```Console
cls
```

# Deploy baseline image and additional applications - "Windows 7 Ultimate (x86)"

---

**STORM**

### # Create temporary VM to build image - "Windows 7 Ultimate (x86)"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso -Force
```

---

<table>
<thead>
<th>
<p><strong>Task Sequence</strong></p>
</th>
<th>
<p><strong>Start</strong></p>
</th>
<th>
<p><strong>End</strong></p>
</th>
<th>
<p><strong>Duration[HH:MM:SS]</strong></p>
</th>
<th>
<p><strong>VHD Size [KB]</strong></p>
</th>
<th>
<p><strong>Comments</strong></p>
</th>
</thead>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x86)</p>
</td>
<td valign='top'>
<p>2015-04-14 08:31</p>
</td>
<td valign='top'>
<p>2015-04-14 08:46</p>
</td>
<td valign='top'>
<p>00:14:53</p>
</td>
<td valign='top'>
<p>13,537,280</p>
</td>
<td valign='top'>
<ul>
<li>Image: W7ULT-X86-REF_4-13-2015-9-31-28-AM.wim</li>
<li>No additional applications or patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x86)</p>
</td>
<td valign='top'>
<p>2015-04-14 09:56</p>
</td>
<td valign='top'>
<p>2015-04-14 10:12</p>
</td>
<td valign='top'>
<p>00:16:00</p>
</td>
<td valign='top'>
<p>15,306,752</p>
</td>
<td valign='top'>
<ul>
<li>Image: W7ULT-X86-REF_4-13-2015-9-31-28-AM.wim</li>
<li>Additional applications:
<ul>
<li>Adobe Reader 8.3.1</li>
<li>SharePoint Designer 2013 with Service Pack 1 (x86)</li>
<li>Google Chrome</li>
<li>Mozilla Firefox 36.0</li>
<li>Mozilla Thunderbird 31.3.0</li>
</ul>
</li>
<li>No additional patches installed</li>
</ul>
</td>
</tr>
</table>

```PowerShell
cls
```

## # Import operating systems - Windows 8.1 and Windows Server 2012 R2

### # Create folder - "Operating Systems\\Window 8.1"

```PowerShell
Import-Module 'C:\Program Files\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1'

New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root \\ICEMAN\MDT-Build$

New-Item -Path "DS001:\Operating Systems" -Name "Windows 8.1" -ItemType Folder
```

### # Import operating system - "Windows 8.1 Enterprise with Update (x64)"

#### # Mount the installation image

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\Windows 8.1" `
    + "\en_windows_8.1_enterprise_with_update_x64_dvd_6054382.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$sourcePath = $imageDriveLetter + ":\"
```

#### # Import operating system

```PowerShell
$destinationFolder = "W81Ent-x64-Update"

$os = Import-MDTOperatingSystem `
    -Path "DS001:\Operating Systems\Windows 8.1" `
    -SourcePath $sourcePath `
    -DestinationFolder $destinationFolder

$os.RenameItem("Windows 8.1 Enterprise with Update (x64)")
```

#### # Dismount the installation image

```PowerShell
Dismount-DiskImage -ImagePath $imagePath
```

```PowerShell
cls
```

### # Create folder - "Operating Systems\\Windows Server 2012 R2"

```PowerShell
New-Item -Path "DS001:\Operating Systems" -Name "Windows Server 2012 R2" -ItemType Folder
```

### # Import operating system - "Windows Server 2012 R2"

#### # Mount the installation image

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\Windows Server 2012 R2" `
    + "\en_windows_server_2012_r2_with_update_x64_dvd_6052708.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$sourcePath = $imageDriveLetter + ":\"
```

#### # Import operating system

```PowerShell
$destinationFolder = "WS2012-R2-Update"

$os = Import-MDTOperatingSystem `
    -Path "DS001:\Operating Systems\Windows Server 2012 R2" `
    -SourcePath $sourcePath `
    -DestinationFolder $destinationFolder

$os[0].RenameItem("Windows Server 2012 R2 Standard (Server Core Installation) with Update")

$os[1].RenameItem("Windows Server 2012 R2 Standard with Update")

$os[2].RenameItem("Windows Server 2012 R2 Datacenter (Server Core Installation) with Update")

$os[3].RenameItem("Windows Server 2012 R2 Datacenter with Update")
```

#### # Dismount the installation image

```PowerShell
Dismount-DiskImage -ImagePath $imagePath
```

---

**WOLVERINE**

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\DiffMerge.exe \\ICEMAN\MDT-Build$ '.\Main\MDT-Build$'
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

## # Create task sequences for building Windows 8.1 baseline image

```PowerShell
cls
```

### # Create folder - "Task Sequences\\Window 8.1"

```PowerShell
New-Item -Path "DS001:\Task Sequences" -Name "Windows 8.1" -ItemType Folder
```

### # Create task sequence - "Windows 7 Enterprise (x64) - Baseline"

```PowerShell
$osPath = "DS001:\Operating Systems\Windows 8.1" `
    + "\Windows 8.1 Enterprise with Update (x64)"

Import-MDTTaskSequence `
    -Path "DS001:\Task Sequences\Windows 8.1" `
    -ID "W81ENT-X64-REF" `
    -Name "Windows 8.1 Enterprise (x64) - Baseline" `
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

## # Create task sequence for building Windows Server 2012 R2 baseline image

### # Create folder - "Task Sequences\\Windows Server 2012 R2"

```PowerShell
New-Item -Path "DS001:\Task Sequences" -Name "Windows Server 2012 R2" -ItemType Folder
```

### # Create task sequence - "Windows Server 2008 R2 - Baseline"

```PowerShell
$osPath = "DS001:\Operating Systems\Windows Server 2012 R2" `
    + "\Windows Server 2012 R2 Standard with Update"

Import-MDTTaskSequence `
    -Path "DS001:\Task Sequences\Windows Server 2012 R2" `
    -ID "WS2012-R2-REF" `
    -Name "Windows Server 2012 R2 - Baseline" `
    -Comments "Reference image" `
    -Version "1.0" `
    -Template "Server.xml" `
    -OperatingSystemPath $osPath `
    -FullName "Windows User" `
    -OrgName "Technology Toolbox" `
    -HomePage "about:blank" `
    -ProductKey "NPD6V-MT6HM-C8F3J-4QFH8-HMGPB" `
    -AdminPassword "{redacted}"
```

> **Important**
>
> The MSDN version of Windows Server 2012 R2 will prompt to enter a product key (but provide an option to skip this step). It does not honor the SkipProductKey=YES entry in the MDT CustomSettings.ini file.

> **Important**
>
> Windows Server 2012 R2 with Update requires a password to be specified for the Administrator account (unlike Windows 8.1). If an Administrator password is not specified in the task sequence, the Lite Touch Installation will prompt for a password (which must be subsequently be entered manually when completing the actions specified in the task sequence).

---

**WOLVERINE**

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\DiffMerge.exe \\ICEMAN\MDT-Build$ '.\Main\MDT-Build$'
```

#### # Sync files

```PowerShell
robocopy \\ICEMAN\MDT-Build$ Main\MDT-Build$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools
```

#### # Add files to TFS

```PowerShell
& "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\TF.exe" add Main /r
```

#### Check-in files

---

```Console
cls
```

# Build baseline images

---

**STORM**

### # Create temporary VM to build image - "Windows 8.1 Enterprise (x64) - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Build-x86.iso -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image (Windows Server 2012 R2 Standard - Baseline)

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Build-x86.iso -Force
```

---

<table>
<thead>
<th>
<p><strong>Task Sequence</strong></p>
</th>
<th>
<p><strong>Start</strong></p>
</th>
<th>
<p><strong>End</strong></p>
</th>
<th>
<p><strong>Duration[HH:MM:SS]</strong></p>
</th>
<th>
<p><strong>Image Size [KB]</strong></p>
</th>
<th>
<p><strong>Comments</strong></p>
</th>
</thead>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x86) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 07:42</p>
</td>
<td valign='top'>
<p>2015-04-13 08:01</p>
</td>
<td valign='top'>
<p>00:18:45</p>
</td>
<td valign='top'>
<p>2,069,449</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 08:01</p>
</td>
<td valign='top'>
<p>2015-04-13 08:24</p>
</td>
<td valign='top'>
<p>00:22:36</p>
</td>
<td valign='top'>
<p>2,754,165</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2008 R2 - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 08:42</p>
</td>
<td valign='top'>
<p>2015-04-13 09:04</p>
</td>
<td valign='top'>
<p>00:21:14</p>
</td>
<td valign='top'>
<p>2,477,925</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x86) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 09:30</p>
</td>
<td valign='top'>
<p>2015-04-13 13:22</p>
</td>
<td valign='top'>
<p>03:51:50</p>
</td>
<td valign='top'>
<p>6,006,079</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 13:35</p>
</td>
<td valign='top'>
<p>2015-04-13 20:42</p>
</td>
<td valign='top'>
<p>07:06:52</p>
</td>
<td valign='top'>
<p>7,942,451</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2008 R2 - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 21:32</p>
</td>
<td valign='top'>
<p>2015-04-14 02:47</p>
</td>
<td valign='top'>
<p>05:14:50</p>
</td>
<td valign='top'>
<p>3,740,460</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 8.1 Enterprise (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-14 10:42</p>
</td>
<td valign='top'>
<p>2015-04-14 11:09</p>
</td>
<td valign='top'>
<p>00:27:14</p>
</td>
<td valign='top'>
<p>3,401,446</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2012 R2 Standard - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-14 11:10</p>
</td>
<td valign='top'>
<p>2015-04-14 11:36</p>
</td>
<td valign='top'>
<p>00:26:07</p>
</td>
<td valign='top'>
<p>4,367,639</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
</table>

## Customize Windows 8.1 and Windows Server 2012 R2 baseline images

### Configure task sequence - "Windows 8.1 Enterprise (x64) - Baseline"

Edit the task sequence to include the actions required to update the reference image with the latest updates from WSUS, copy Toolbox content from ICEMAN, install .NET Framework 3.5, update PowerShell help files, and easily suspend the deployment process after installing applications.

1. Open **Deployment Workbench**, expand **Deployment Shares / MDT Build Lab ([\\\\ICEMAN\\MDT-Build\$](\\ICEMAN\MDT-Build$)) / Task Sequences / Windows 8.1**, right-click **Windows 8.1 Enterprise (x64) - Baseline**, and click **Properties**.
2. In the **Windows 8.1 Enterprise (x64) - Baseline Properties** window:
   1. On the **General **tab, configure the following settings:
      1. Comments: **Reference image - Toolbox content, .NET Framework 3.5, PowerShell help files, and latest patches**
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
            2. Select the operating system for which roles are to be installed: **Windows 8.1**
            3. Select the roles and features that should be installed: **.NET Framework 3.5 (includes .NET 2.0 and 3.0)**
         7. Select **Custom Tasks (Pre-Windows Update)** and add a new **Run Command Line** action with the following settings:
            1. Name: **Update PowerShell help files**
            2. Command line: **PowerShell.exe -Command "& { Update-Help }"**
         8. After the **Install Applications** action, add a new **Run Command Line** action with the following settings:
            1. Name: **Suspend**
            2. Command line: **cscript.exe "%SCRIPTROOT%\\LTISuspend.wsf"**
            3. Disable this step:** Yes (checked)**
   3. Click **OK**.

> **Note**
>
> The reason for adding the applications after the Tattoo action but before running Windows Update is simply to save time during the deployment. This way we can add all applications that will upgrade some of the built-in components and avoid unnecessary updating.

### Configure task sequence - "Windows Server 2012 R2 - Baseline"

Repeat the steps in the previous section for the **Windows Server 2012 R2 - Baseline** task sequence.

## Add action to Windows 8.1 task sequence to install Office 2013

1. Open **Deployment Workbench**, expand **Deployment Shares / MDT Build Lab ([\\\\ICEMAN\\MDT-Build\$](\\ICEMAN\MDT-Build$)) / Task Sequences / Windows 8.1**, right-click **Windows 8.1 Enterprise (x64) - Baseline**, and click **Properties**.
2. In the **Windows 8.1 Enterprise (x64) - Baseline Properties** window:
   1. On the **General **tab, configure the following settings:
      1. Comments: **Reference image - Toolbox content, .NET Framework 3.5, PowerShell help files, Office 2013, and latest patches**
   2. On the **Task Sequence** tab, configure the following settings:
      1. **State Restore**
         1. Select the **Custom Tasks (Pre-Windows Update)** group and add a new **Install Application** action with the following settings:
            1. Name: **Install Microsoft Office 2013 Professional Plus (x86)**
            2. **Install a single application**
            3. Application to install: **Applications / Microsoft / Office 2013 Professional Plus (x86)**
         2. After the **Install Microsoft Office 2013 Professional Plus (x86)** action, add a new **Restart computer** action.
   3. Click **OK**.

---

**WOLVERINE**

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\DiffMerge.exe \\ICEMAN\MDT-Build$ '.\Main\MDT-Build$'
```

#### # Sync files

```PowerShell
robocopy \\ICEMAN\MDT-Build$ Main\MDT-Build$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools
```

#### Check-in files

---

```Console
cls
```

# Build baseline images

---

**STORM**

### # Create temporary VM to build image (Windows 8.1 Enterprise x64 - Baseline)

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Build-x86.iso -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image (Windows Server 2012 R2 Standard - Baseline)

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Build-x86.iso -Force
```

---

<table>
<thead>
<th>
<p><strong>Task Sequence</strong></p>
</th>
<th>
<p><strong>Start</strong></p>
</th>
<th>
<p><strong>End</strong></p>
</th>
<th>
<p><strong>Duration[HH:MM:SS]</strong></p>
</th>
<th>
<p><strong>Image Size [KB]</strong></p>
</th>
<th>
<p><strong>Comments</strong></p>
</th>
</thead>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x86) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 07:42</p>
</td>
<td valign='top'>
<p>2015-04-13 08:01</p>
</td>
<td valign='top'>
<p>00:18:45</p>
</td>
<td valign='top'>
<p>2,069,449</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 08:01</p>
</td>
<td valign='top'>
<p>2015-04-13 08:24</p>
</td>
<td valign='top'>
<p>00:22:36</p>
</td>
<td valign='top'>
<p>2,754,165</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2008 R2 - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 08:42</p>
</td>
<td valign='top'>
<p>2015-04-13 09:04</p>
</td>
<td valign='top'>
<p>00:21:14</p>
</td>
<td valign='top'>
<p>2,477,925</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x86) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 09:30</p>
</td>
<td valign='top'>
<p>2015-04-13 13:22</p>
</td>
<td valign='top'>
<p>03:51:50</p>
</td>
<td valign='top'>
<p>6,006,079</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 13:35</p>
</td>
<td valign='top'>
<p>2015-04-13 20:42</p>
</td>
<td valign='top'>
<p>07:06:52</p>
</td>
<td valign='top'>
<p>7,942,451</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2008 R2 - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 21:32</p>
</td>
<td valign='top'>
<p>2015-04-14 02:47</p>
</td>
<td valign='top'>
<p>05:14:50</p>
</td>
<td valign='top'>
<p>3,740,460</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 8.1 Enterprise (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-14 10:42</p>
</td>
<td valign='top'>
<p>2015-04-14 11:09</p>
</td>
<td valign='top'>
<p>00:27:14</p>
</td>
<td valign='top'>
<p>3,401,446</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2012 R2 Standard - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-14 11:10</p>
</td>
<td valign='top'>
<p>2015-04-14 11:36</p>
</td>
<td valign='top'>
<p>00:26:07</p>
</td>
<td valign='top'>
<p>4,367,639</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 8.1 Enterprise (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-14 11:40</p>
</td>
<td valign='top'>
<p>2015-04-14 14:04</p>
</td>
<td valign='top'>
<p>02:22:54</p>
</td>
<td valign='top'>
<p>7,614,960</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2012 R2 Standard - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-14 14:40</p>
</td>
<td valign='top'>
<p>2015-04-14 15:52</p>
</td>
<td valign='top'>
<p>01:12:26</p>
</td>
<td valign='top'>
<p>5,216,299</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
</table>

```PowerShell
cls
```

## # Add applications - SQL Server 2014 Developer Edition and Visual Studio 2013

```PowerShell
Import-Module 'C:\Program Files\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1'

New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root \\ICEMAN\MDT-Build$
```

### # Create application - "SQL Server 2014 Developer Edition (x64) - Complete"

#### # Mount the installation image

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\SQL Server 2014" `
    + "\en_sql_server_2014_developer_edition_x64_dvd_3940406.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$appSourcePath = $imageDriveLetter + ":\"
```

#### # Import application

\$appName = "SQL Server 2014 Developer Edition (x64) - Complete"

```PowerShell
$appShortName = "SQL2014-Dev-x64"
$appSetupFolder = $appShortName
$commandLine = "Setup.exe /Q /IACCEPTSQLSERVERLICENSETERMS /ACTION=PrepareImage" `
    + " /FEATURES=SQL,AS,RS,DQC,IS,MDS,Tools /INSTANCEID=MSSQLSERVER"

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

### # Create application - SQL Server 2014 Developer Edition (x64) - Database Engine and Management Tools

\$appName = "SQL Server 2014 Developer Edition (x64)" `

```PowerShell
    + " - Database Engine and Management Tools"

$appShortName = "SQL2014-Dev-x64-DE-MT"
$appSetupFolder = "SQL2014-Dev-x64"
$commandLine = "Setup.exe /Q /IACCEPTSQLSERVERLICENSETERMS /ACTION=PrepareImage" `
    + " /FEATURES=SQLEngine,ADV_SSMS /INSTANCEID=MSSQLSERVER"

Import-MDTApplication `
    -Path "DS001:\Applications\Microsoft" `
    -Name $appName `
    -ShortName $appShortName `
    -NoSource `
    -CommandLine $commandLine `
    -WorkingDirectory ".\Applications\$appSetupFolder"
```

```PowerShell
cls
```

### # Create application - "Visual Studio 2013 with Update 4 - Default"

#### # Mount the installation image

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\Visual Studio 2013" `
    + "\en_visual_studio_ultimate_2013_with_update_4_x86_dvd_5935075.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$appSourcePath = $imageDriveLetter + ":\"
```

#### # Import application

\$appName = "Visual Studio 2013 with Update 4 - Default"

```PowerShell
$appShortName = "VS2013-Update4"
$appSetupFolder = $appShortName
$commandLine = "vs_ultimate.exe /Quiet /NoRestart" `
    + " /AdminFile Z:\Applications\appSetupFolder\AdminDeployment.xml"
```

> **Important**
>
> You must specify the full path for the **AdminFile** parameter or else vs_ultimate.exe terminates with an error.

```PowerShell
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

### # Create application - "Visual Studio 2013 with Update 4 - SP2013 Development"

#### # Create custom "AdminFile" for unattended Visual Studio 2013 installation for SP2013 development

```PowerShell
$path = "\\ICEMAN\MDT-Build$\Applications\VS2013-Update4"

$xml = [xml] (Get-Content "$path\AdminDeployment.xml")
```

##### # In the <BundleCustomizations> element, change the NoWeb attribute to "yes"

```PowerShell
$xml.AdminDeploymentCustomizations.BundleCustomizations.NoWeb = "yes"
```

##### # Change the Selected attributes for the following <SelectableItemCustomization> elements to "no"

##### # Id="Blend"

##### # Id="LightSwitch"

##### # Id="VC_MFC_Libraries"

##### # Id="SilverLight_Developer_Kit"

```PowerShell
$xml.AdminDeploymentCustomizations.SelectableItemCustomizations.SelectableItemCustomization |
    % {
        If ($_.Id -eq "Blend" `
            -Or $_.Id -eq "LightSwitch" `
            -Or $_.Id -eq "VC_MFC_Libraries" `
            -Or $_.Id -eq "SilverLight_Developer_Kit"
            )
        {
            $_.Selected = "no"
        }
    }

$xml.Save("$path\AdminDeployment-SP2013-Dev.xml")
```

#### # Import application

\$appName = "Visual Studio 2013 with Update 4 - SP2013 Development"

```PowerShell
$appShortName = "VS2013-Update4-SP2013-Dev"
$appSetupFolder = "VS2013-Update4"
$commandLine = "vs_ultimate.exe /Quiet /NoRestart" `
    + " /AdminFile Z:\Applications\$appSetupFolder\AdminDeployment-SP2013-Dev.xml"
```

> **Important**
>
> You must specify the full path for the **AdminFile** parameter or else vs_ultimate.exe terminates with an error.

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

**WOLVERINE**

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\DiffMerge.exe \\ICEMAN\MDT-Build$ '.\Main\MDT-Build$'
```

#### # Sync files

```PowerShell
robocopy \\ICEMAN\MDT-Build$ Main\MDT-Build$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools

robocopy '\\ICEMAN\MDT-Build$\Applications\VS2013-Update4' '.\Main\MDT-Build$\Applications\VS2013-Update4' AdminDeployment-SP2013-Dev.xml
```

#### # Add files to TFS

```PowerShell
& "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\TF.exe" add Main /r
```

#### Check-in files

---

```PowerShell
cls
```

### # Create application - "Microsoft Office Developer Tools for Visual Studio 2013 - November 2014 Update"

#### Download update using Web Platform Installer

- Folder: [\\\\ICEMAN\\Products\\Microsoft\\Visual Studio 2013\\OfficeToolsForVS2013Update1](\\ICEMAN\Products\Microsoft\Visual Studio 2013\OfficeToolsForVS2013Update1)

#### # Add application

\$appName = "Microsoft Office Developer Tools for Visual Studio 2013" `

```PowerShell
    + " - November 2014 Update"

$appShortName = "OfficeToolsForVS2013Update1"
$appSourcePath = "\\ICEMAN\Products\Microsoft\Visual Studio 2013" `
    + "\OfficeToolsForVS2013Update1"

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

```PowerShell
cls
```

### # Create application: Microsoft SQL Server Update for database tooling

#### Download ISO for SQL Server Database Tools (SSDT_12.0.50318.0_EN.iso)

- Download link:\
  **SQL Server database tooling in Visual Studio 2013**\
  From <[https://msdn.microsoft.com/en-us/dn864412](https://msdn.microsoft.com/en-us/dn864412)>
- Destination folder: [\\\\ICEMAN\\Products\\Microsoft\\Visual Studio 2013\\](\\ICEMAN\Products\Microsoft\Visual Studio 2013\)

#### # Mount the installation image

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\Visual Studio 2013\SSDT_12.0.50318.0_EN.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$appSourcePath = $imageDriveLetter + ":\"
```

#### # Import application

\$appName = "Microsoft SQL Server Update for database tooling (VS2013)"

```PowerShell
$appShortName = "SSDT-VS2013"
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

### # Create application bundle - "Visual Studio 2013 for SP2013 Development"

#### # Add application bundle

\$appName = "Visual Studio 2013 for SP2013 Development"

```PowerShell
$appShortName = "VS2013-SP2013"

Import-MDTApplication `
    -Path "DS001:\Applications\Microsoft" `
    -Name $appName `
    -ShortName $appShortName `
    -Bundle
```

#### # Configure application bundle

1. Open **Deployment Workbench**, expand **Deployment Shares / MDT Deployment ([\\\\ICEMAN\\MDT-Deploy\$](\\ICEMAN\MDT-Deploy$)) / Applications / Microsoft**, right-click **Visual Studio 2013 for SP2013 Development**, and click **Properties**.
2. In the **Visual Studio 2013 for SP2013 Development Properties** window:
   1. On the **Dependencies** tab:
      1. Add the following applications:
         1. **Visual Studio 2013 with Update 4 - SP2013 Development**
         2. **Microsoft Office Developer Tools for Visual Studio 2013 - November 2014 Update**
         3. **Microsoft SQL Server Update for database tooling (VS2013)**
      2. Ensure the applications in the previous step are listed in the specified order. Use the **Up** or **Down** buttons to reorder the applications as necessary.
   2. Click **OK**.

---

**WOLVERINE**

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\DiffMerge.exe \\ICEMAN\MDT-Build$ '.\Main\MDT-Build$'
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

### # Create application - "SharePoint Server 2013 with Service Pack 1"

#### # Mount the installation image

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\SharePoint 2013\" `
    + "en_sharepoint_server_2013_with_sp1_x64_dvd_3823428.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$appSourcePath = $imageDriveLetter + ":\"
```

#### # Add application

\$appName = "SharePoint Server 2013 with Service Pack 1"

```PowerShell
$appShortName = "SP2013-SP1"
$appSetupFolder = $appShortName
$commandLine = "setup.exe /config Config.xml"

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

#### # Create configuration file for unattended SharePoint 2013 setup

```PowerShell
$xml = New-Object XML
$xml.LoadXml(
'<Configuration>
  <Package Id="sts">
    <Setting Id="LAUNCHEDFROMSETUPSTS" Value="Yes"/>
  </Package>
  <Package Id="spswfe">
    <Setting Id="SETUPCALLED" Value="1"/>
  </Package>
  <Logging Type="verbose" Path="%temp%" Template="SharePoint Server Setup(*).log"/>
  <!-- Enterprise trial key = NQTMW-K63MQ-39G6H-B2CH9-FRDWJ -->
  <PIDKEY Value="NQTMW-K63MQ-39G6H-B2CH9-FRDWJ"/>
  <Setting Id="SERVERROLE" Value="APPLICATION"/>
  <Setting Id="SETUPTYPE" Value="CLEAN_INSTALL"/>
  <Setting Id="SETUP_REBOOT" Value="Never"/>
  <Display Level="None" AcceptEula="Yes"/>
</Configuration>')

$xml.Save("\\ICEMAN\MDT-Build$\Applications\$appSetupFolder\Config.xml")
```

#### # Create script to install SharePoint 2013 prerequisites

```PowerShell
Notepad.exe "\\ICEMAN\MDT-Build$\Applications\$appSetupFolder\prerequisiteinstaller.cmd"
```

Copy/paste the following into the file:

```Console
setlocal

set SOURCE_PATH=\\ICEMAN\Products\Microsoft\SharePoint 2013\PrerequisiteInstallerFiles_SP1

REM An error occurs if %TEMP% is used to store the prerequisite files when installing
REM via the Microsoft Deployment Toolkit (presumably due to cleanup of temp files during
REM reboot)...
REM
REM set LOCAL_PATH=%TEMP%
REM
REM ...instead copy the files to a custom folder at the root of the C: drive
set LOCAL_PATH=C:\PrerequisiteInstallerFiles_SP1

robocopy "%SOURCE_PATH%" "%LOCAL_PATH%"

PrerequisiteInstaller.exe %* ^
    /SQLNCli:"%LOCAL_PATH%\sqlncli.msi" ^
    /PowerShell:"%LOCAL_PATH%\Windows6.1-KB2506143-x64.msu" ^
    /NETFX:"%LOCAL_PATH%\dotNetFx45_Full_setup.exe" ^
    /IDFX:"%LOCAL_PATH%\Windows6.1-KB974405-x64.msu" ^
    /Sync:"%LOCAL_PATH%\Synchronization.msi" ^
    /AppFabric:"%LOCAL_PATH%\WindowsServerAppFabricSetup_x64.exe" ^
    /IDFX11:"%LOCAL_PATH%\MicrosoftIdentityExtensions-64.msi" ^
    /MSIPCClient:"%LOCAL_PATH%\setup_msipc_x64.msi" ^
    /WCFDataServices:"%LOCAL_PATH%\WcfDataServices.exe" ^
    /KB2671763:"%LOCAL_PATH%\AppFabric1.1-RTM-KB2671763-x64-ENU.exe" ^
    /WCFDataServices56:"%LOCAL_PATH%\WcfDataServices-5.6.exe"
```

> **Important**
>
> The prerequisite files are copied locally to avoid a prompt when running WcfDataServices.exe (despite unblocking that file in the network file share).

```PowerShell
cls
```

### # Create application - "SharePoint Server 2013 with Service Pack 1 - Prerequisites"

\$appName = "SharePoint Server 2013 with Service Pack 1 - Prerequisites"

```PowerShell
$appShortName = "SP2013-SP1-Prereq"
$appSetupFolder = "SP2013-SP1"
$commandLine = "prerequisiteinstaller.cmd /unattended"

Import-MDTApplication `
    -Path "DS001:\Applications\Microsoft" `
    -Name $appName `
    -ShortName $appShortName `
    -NoSource `
    -CommandLine $commandLine `
    -WorkingDirectory ".\Applications\$appSetupFolder"
```

---

**WOLVERINE**

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\DiffMerge.exe \\ICEMAN\MDT-Build$ '.\Main\MDT-Build$'
```

#### # Sync files

```PowerShell
robocopy \\ICEMAN\MDT-Build$ Main\MDT-Build$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools

robocopy '\\ICEMAN\MDT-Build$\Applications\SP2013-SP1' '.\Main\MDT-Build$\Applications\SP2013-SP1' Config.xml prerequisiteinstaller.cmd
```

#### # Add files to TFS

```PowerShell
& "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\TF.exe" add Main /r
```

#### Check-in files

---

```PowerShell
cls
```

## # Create task sequence for SharePoint 2013 development image

### # Create task sequence - "SharePoint Server 2013 - Development"

```PowerShell
$osPath = "DS001:\Operating Systems\Windows Server 2012 R2" `
    + "\Windows Server 2012 R2 Standard with Update"
```

\$comments = "Windows Server 2012 R2, SQL Server 2014, Visual Studio 2013 with Update 4, Office 2013, and SharePoint Server 2013"

```PowerShell
Import-MDTTaskSequence `
    -Path "DS001:\Task Sequences\Windows Server 2012 R2" `
    -ID "SP2013-DEV-REF" `
    -Name "SharePoint Server 2013 - Development" `
    -Comments $comments `
    -Version "1.0" `
    -Template "Server.xml" `
    -OperatingSystemPath $osPath `
    -FullName "Windows User" `
    -OrgName "Technology Toolbox" `
    -HomePage "about:blank" `
    -ProductKey "NPD6V-MT6HM-C8F3J-4QFH8-HMGPB" `
    -AdminPassword "{redacted}"
```

> **Important**
>
> The MSDN version of Windows Server 2012 R2 will prompt to enter a product key (but provide an option to skip this step). It does not honor the SkipProductKey=YES entry in the MDT CustomSettings.ini file.

> **Important**
>
> Windows Server 2012 R2 with Update requires a password to be specified for the Administrator account (unlike Windows 8.1). If an Administrator password is not specified in the task sequence, the Lite Touch Installation will prompt for a password (which must be subsequently be entered manually when completing the actions specified in the task sequence).

---

**WOLVERINE**

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\DiffMerge.exe \\ICEMAN\MDT-Build$ '.\Main\MDT-Build$'
```

#### # Sync files

```PowerShell
robocopy \\ICEMAN\MDT-Build$ Main\MDT-Build$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools
```

#### # Add new files to TFS

```PowerShell
& "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\TF.exe" add Main /r
```

#### Check-in files

---

```PowerShell
cls
```

### # Copy task sequence customizations (from WS2012-R2-REF to SP2013-DEV-REF)

```PowerShell
copy '\\ICEMAN\MDT-Build$\Control\WS2012-R2-REF\ts.xml' '\\ICEMAN\MDT-Build$\Control\SP2013-DEV-REF'
```

---

**WOLVERINE**

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\DiffMerge.exe \\ICEMAN\MDT-Build$ '.\Main\MDT-Build$'
```

#### # Sync files

```PowerShell
robocopy \\ICEMAN\MDT-Build$ Main\MDT-Build$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools
```

#### Check-in files

---

### # Identify Windows features for SharePoint 2013

```PowerShell
$requiredFeatures = "NET-WCF-HTTP-Activation45,NET-WCF-TCP-Activation45,NET-WCF-Pipe-Activation45,Net-Framework-Features,Web-Server,Web-WebServer,Web-Common-Http,Web-Static-Content,Web-Default-Doc,Web-Dir-Browsing,Web-Http-Errors,Web-App-Dev,Web-Asp-Net,Web-Net-Ext,Web-ISAPI-Ext,Web-ISAPI-Filter,Web-Health,Web-Http-Logging,Web-Log-Libraries,Web-Request-Monitor,Web-Http-Tracing,Web-Security,Web-Basic-Auth,Web-Windows-Auth,Web-Filtering,Web-Digest-Auth,Web-Performance,Web-Stat-Compression,Web-Dyn-Compression,Web-Mgmt-Tools,Web-Mgmt-Console,Web-Mgmt-Compat,Web-Metabase,Application-Server,AS-Web-Support,AS-TCP-Port-Sharing,AS-WAS-Support,AS-HTTP-Activation,AS-TCP-Activation,AS-Named-Pipes,AS-Net-Framework,WAS,WAS-Process-Model,WAS-NET-Environment,WAS-Config-APIs,Web-Lgcy-Scripting,Windows-Identity-Foundation,Server-Media-Foundation,Xps-Viewer".Split(",")

$allOosRoles = "AD-Certificate,AD-Domain-Services,ADFS-Federation,ADLDS,ADRMS,Application-Server,DHCP,DNS,Fax,FileAndStorage-Services,Hyper-V,NPAS,Print-Services,RemoteAccess,Remote-Desktop-Services,VolumeActivation,Web-Server,WDS,ServerEssentialsRole,UpdateServices".Split(",")

$allOsRoleServices = "ADCS-Cert-Authority,ADCS-Enroll-Web-Pol,ADCS-Enroll-Web-Svc,ADCS-Web-Enrollment,ADCS-Device-Enrollment,ADCS-Online-Cert,ADRMS-Server,ADRMS-Identity,AS-NET-Framework,AS-Ent-Services,AS-Dist-Transaction,AS-WS-Atomic,AS-Incoming-Trans,AS-Outgoing-Trans,AS-TCP-Port-Sharing,AS-Web-Support,AS-WAS-Support,AS-HTTP-Activation,AS-MSMQ-Activation,AS-Named-Pipes,AS-TCP-Activation,File-Services,FS-FileServer,FS-BranchCache,FS-Data-Deduplication,FS-DFS-Namespace,FS-DFS-Replication,FS-Resource-Manager,FS-VSS-Agent,FS-iSCSITarget-Server,iSCSITarget-VSS-VDS,FS-NFS-Service,Storage-Services,FS-SyncShareService,Storage-Services,NPAS-Health,NPAS-Host-Cred,NPAS-Policy-Server,Print-Server,Print-Scan-Server,Print-Internet,Print-LPD-Service,DirectAccess-VPN,Routing,Web-Application-Proxy,RDS-Connection-Broker,RDS-Gateway,RDS-Licensing,RDS-RD-Server,RDS-Virtualization,RDS-Web-Access,Web-Mgmt-Tools,Web-Mgmt-Console,Web-Mgmt-Compat,Web-Metabase,Web-Lgcy-Mgmt-Console,Web-Lgcy-Scripting,Web-WMI,Web-Scripting-Tools,Web-Mgmt-Service,Web-WebServer,Web-Common-Http,Web-Default-Doc,Web-Dir-Browsing,Web-Http-Errors,Web-Static-Content,Web-Http-Redirect,Web-DAV-Publishing,Web-Health,Web-Http-Logging,Web-Custom-Logging,Web-Log-Libraries,Web-ODBC-Logging,Web-Request-Monitor,Web-Http-Tracing,Web-Performance,Web-Stat-Compression,Web-Dyn-Compression,Web-Security,Web-Filtering,Web-Basic-Auth,Web-CertProvider,Web-Client-Auth,Web-Digest-Auth,Web-Cert-Auth,Web-IP-Security,Web-Url-Auth,Web-Windows-Auth,Web-App-Dev,Web-Net-Ext,Web-Net-Ext45,Web-AppInit,Web-ASP,Web-Asp-Net,Web-Asp-Net45,Web-CGI,Web-ISAPI-Ext,Web-ISAPI-Filter,Web-Includes,Web-WebSockets,Web-Ftp-Server,Web-Ftp-Service,Web-Ftp-Ext,Web-WHC,WDS-Deployment,WDS-Transport,UpdateServices-WidDB,UpdateServices-Services,UpdateServices-DB".Split(",")

$allOsFeatures = "NET-Framework-Features,NET-Framework-Core,NET-HTTP-Activation,NET-Non-HTTP-Activ,NET-Framework-45-Features,NET-Framework-45-Core,NET-Framework-45-ASPNET,NET-WCF-Services45,NET-WCF-HTTP-Activation45,NET-WCF-MSMQ-Activation45,NET-WCF-Pipe-Activation45,NET-WCF-TCP-Activation45,NET-WCF-TCP-PortSharing45,BITS,BITS-IIS-Ext,BITS-Compact-Server,BitLocker,BitLocker-NetworkUnlock,BranchCache,NFS-Client,Data-Center-Bridging,Direct-Play,EnhancedStorage,Failover-Clustering,GPMC,InkAndHandwritingServices,Internet-Print-Client,IPAM,ISNS,LPR-Port-Monitor,ManagementOdata,Server-Media-Foundation,MSMQ,MSMQ-Services,MSMQ-Server,MSMQ-Directory,MSMQ-HTTP-Support,MSMQ-Triggers,MSMQ-Multicasting,MSMQ-Routing,MSMQ-DCOM,Multipath-IO,NLB,PNRP,qWave,CMAK,Remote-Assistance,RDC,RSAT,RSAT-Feature-Tools,RSAT-SMTP,RSAT-Feature-Tools-BitLocker,RSAT-Feature-Tools-BitLocker-RemoteAdminTool,RSAT-Feature-Tools-BitLocker-BdeAducExt,RSAT-Bits-Server,RSAT-Clustering,RSAT-Clustering-Mgmt,RSAT-Clustering-PowerShell,RSAT-Clustering-AutomationServer,RSAT-Clustering-CmdInterface,IPAM-Client-Feature,RSAT-NLB,RSAT-SNMP,RSAT-WINS,RSAT-Role-Tools,RSAT-AD-Tools,RSAT-AD-PowerShell,RSAT-ADDS,RSAT-AD-AdminCenter,RSAT-ADDS-Tools,RSAT-NIS,RSAT-ADLDS,RSAT-Hyper-V-Tools,Hyper-V-Tools,Hyper-V-PowerShell,RSAT-RDS-Tools,RSAT-RDS-Gateway,RSAT-RDS-Licensing-Diagnosis-UI,RDS-Licensing-UI,UpdateServices-RSAT,UpdateServices-API,UpdateServices-UI,RSAT-ADCS,RSAT-ADCS-Mgmt,RSAT-Online-Responder,RSAT-ADRMS,RSAT-DHCP,RSAT-DNS-Server,RSAT-Fax,RSAT-File-Services,RSAT-DFS-Mgmt-Con,RSAT-FSRM-Mgmt,RSAT-NFS-Admin,RSAT-CoreFile-Mgmt,RSAT-NPAS,RSAT-Print-Services,RSAT-RemoteAccess,RSAT-RemoteAccess-Mgmt,RSAT-RemoteAccess-PowerShell,RSAT-VA-Tools,WDS-AdminPack,RPC-over-HTTP-Proxy,Simple-TCPIP,FS-SMB1,FS-SMBBW,SMTP-Server,SNMP-Service,SNMP-WMI-Provider,Telnet-Client,Telnet-Server,TFTP-Client,User-Interfaces-Infra,Server-Gui-Mgmt-Infra,Desktop-Experience,Server-Gui-Shell,Biometric-Framework,WFF,Windows-Identity-Foundation,Windows-Internal-Database,PowerShellRoot,DSC-Service,PowerShell,PowerShell-V2,PowerShell-ISE,WindowsPowerShellWebAccess,WAS,WAS-Process-Model,WAS-NET-Environment,WAS-Config-APIs,Search-Service,Windows-Server-Backup,Migration,WindowsStorageManagementService,Windows-TIFF-IFilter,WinRM-IIS-Ext,WINS,Wireless-Networking,WoW64-Support,XPS-Viewer".Split(",")

$selectedOsRoles = ($allOosRoles | ? { $requiredFeatures.Contains($_) }) -join ","

$selectedOsRoleServices = ($allOsRoleServices | ? { $requiredFeatures.Contains($_) }) -join ","

$selectedOsFeatures = ($allOsFeatures | ? { $requiredFeatures.Contains($_) }) -join ","

"<variable name=`"OSRoles`" property=`"OSRoles`">" + $selectedOsRoles + "</variable>"

"<variable name=`"OSRoleServices`" property=`"OSRoleServices`">" + $selectedOsRoleServices + "</variable>"

"<variable name=`"OSFeatures`" property=`"OSFeatures`">" + $selectedOsFeatures + "</variable>"
```

### Configure task sequence - "SharePoint Server 2013 - Development"

Edit the task sequence to include the actions required to install SQL Server 2014, Visual Studio 2013, Office 2013, and SharePoint Server 2013. Temporarily disable the Windows Update actions (for testing purposes).

1. Open **Deployment Workbench**, expand **Deployment Shares / MDT Build Lab ([\\\\ICEMAN\\MDT-Build\$](\\ICEMAN\MDT-Build$)) / Task Sequences / Windows Server 2012 R2**, right-click **SharePoint Server 2013 - Development** and click **Properties**.
2. In the **SharePoint Server 2013 - Development Properties** window:
   1. On the **General **tab, configure the following settings:
      1. Comments: **Reference image - Windows Server 2012 R2, Toolbox content, Windows features for SharePoint 2013, PowerShell help files, SQL Server 2014, Visual Studio 2013 with Update 4, Office 2013, and SharePoint Server 2013**
   2. On the **Task Sequence** tab, configure the following settings:
      1. **State Restore**
         1. In the **Custom Tasks (Pre-Windows Update)** group, select **Install Microsoft .NET Framework 3.5** and modify the action with the following settings:
            1. Name: **Install Windows features for SharePoint 2013**
            2. Select the operating system for which roles are to be installed: **Windows Server 2012 R2**
            3. Select the roles and features that should be installed:
               - Roles
                 - **Application Server**
                   - **TCP Port Sharing**
                   - **Web Server (IIS) Support**
                   - **Windows Process Activation Service Support**
                     - **HTTP Activation**
                     - **Named Pipes Activation**
                     - **TCP Activation**
                 - **Web Server (IIS)**
                   - **Management Tools**
                     - **IIS Management Console**
                     - **IIS 6 Management Compatibility**
                       - **IIS 6 Metabase Compatibility**
                       - **IIS 6 Scripting Tools**
                   - **Web Server**
                     - **Common HTTP Features**
                       - **Default Document**
                       - **Directory Browsing**
                       - **HTTP Errors**
                       - **Static Content**
                     - **Health and Diagnostics**
                       - **HTTP Logging**
                       - **Logging Tools**
                       - **Request monitor**
                       - **Tracing**
                     - **Performance**
                       - **Static Content Compression**
                       - **Dynamic Content Compression**
                     - **Security**
                       - **Request Filtering**
                       - **Basic Authentication**
                       - **Digest Authentication**
                       - **Windows Authentication**
                     - **Application Development**
                       - **.NET Extensibility 3.5**
                       - **ASP.NET 3.5**
                       - **ISAPI Extensions**
                       - **ISAPI Filters**
               - Features
                 - .NET Framework 4.5 Features
                   - WCF Services
                     - **HTTP Activation**
                     - **Named Pipe Activation**
                     - **TCP Activation**
                 - **Media Foundation**
                 - **Windows Identity Foundation 3.5**
                 - **Windows Process Activation Service**
                   - **Process Model**
                   - **.NET Environment 3.5**
                   - **Configuration APIs**
         2. After the **Install Windows features for SharePoint 2013** action, add a new **Restart computer** action.
         3. Select **Custom Tasks (Pre-Windows Update)** and add a new **Install Application** action with the following settings:
            1. Name: **Install SQL Server 2014 Developer Edition (x64) - Database Engine and Management Tools**
            2. **Install a single application**
            3. Application to install: **SQL Server 2014 Developer Edition (x64) - Database Engine and Management Tools**
         4. Select **Custom Tasks (Pre-Windows Update)** and add a new **Install Application** action with the following settings:
            1. Name: **Install Visual Studio 2013 for SP2013 Development**
            2. **Install a single application**
            3. Application to install: **Visual Studio 2013 for SP2013 Development**
         5. Select the **Custom Tasks (Pre-Windows Update)** group and add a new **Install Application** action with the following settings:
            1. Name: **Install Microsoft Office 2013 Professional Plus (x86)**
            2. **Install a single application**
            3. Application to install: **Applications / Microsoft / Office 2013 Professional Plus (x86)**
         6. Select **Custom Tasks (Pre-Windows Update)** and add a new **Install Application** action with the following settings:
            1. Name: **Install SharePoint Server 2013 with Service Pack 1 - Prerequisites**
            2. **Install a single application**
            3. Application to install: **SharePoint Server 2013 with Service Pack 1 - Prerequisites**
         7. After the **Install SharePoint Server 2013 with Service Pack 1 - Prerequisites** action, add a new **Run Command Line** action with the following settings:
            1. Name: **Remove SharePoint prerequisite files**
            2. Command line: **PowerShell.exe -Command "& { Remove-Item C:\\PrerequisiteInstallerFiles_SP1 -Recurse -Force }"Note: **I originally attempted to use the following command line...rmdir /S /Q C:\\PrerequisiteInstallerFiles_SP1...but encountered numerous issues (despite adding "1" to the list of success codes -- since rmdir was found to return this value when deleting the folder). Consequently I switched to deleting the folder via PowerShell instead.
         8. After the **Remove SharePoint prerequisite files** action, add a new **Restart computer** action.
         9. Select **Custom Tasks (Pre-Windows Update)** and add a new **Install Application** action with the following settings:
            1. Name: **Install SharePoint Server 2013 with Service Pack 1**
            2. **Install a single application**
            3. Application to install: **SharePoint Server 2013 with Service Pack 1**
         10. Disable the **Windows Update (Pre-Application Installation)** action.
         11. Disable the **Windows Update (Post-Application Installation)** action.
   3. Click **OK**.

---

**WOLVERINE**

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\DiffMerge.exe \\ICEMAN\MDT-Build$ '.\Main\MDT-Build$'
```

#### # Sync files

```PowerShell
robocopy \\ICEMAN\MDT-Build$ Main\MDT-Build$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools
```

#### Check-in files

---

## Build baseline image (SharePoint Server 2013 - Development)

---

**STORM**

### # Create temporary VM to build image (SharePoint Server 2013 - Development)

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Build-x86.iso -Force
```

---

<table>
<thead>
<th>
<p><strong>Task Sequence</strong></p>
</th>
<th>
<p><strong>Start</strong></p>
</th>
<th>
<p><strong>End</strong></p>
</th>
<th>
<p><strong>Duration[HH:MM:SS]</strong></p>
</th>
<th>
<p><strong>Image Size [KB]</strong></p>
</th>
<th>
<p><strong>Comments</strong></p>
</th>
</thead>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x86) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 07:42</p>
</td>
<td valign='top'>
<p>2015-04-13 08:01</p>
</td>
<td valign='top'>
<p>00:18:45</p>
</td>
<td valign='top'>
<p>2,069,449</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 08:01</p>
</td>
<td valign='top'>
<p>2015-04-13 08:24</p>
</td>
<td valign='top'>
<p>00:22:36</p>
</td>
<td valign='top'>
<p>2,754,165</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2008 R2 - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 08:42</p>
</td>
<td valign='top'>
<p>2015-04-13 09:04</p>
</td>
<td valign='top'>
<p>00:21:14</p>
</td>
<td valign='top'>
<p>2,477,925</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x86) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 09:30</p>
</td>
<td valign='top'>
<p>2015-04-13 13:22</p>
</td>
<td valign='top'>
<p>03:51:50</p>
</td>
<td valign='top'>
<p>6,006,079</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 13:35</p>
</td>
<td valign='top'>
<p>2015-04-13 20:42</p>
</td>
<td valign='top'>
<p>07:06:52</p>
</td>
<td valign='top'>
<p>7,942,451</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2008 R2 - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 21:32</p>
</td>
<td valign='top'>
<p>2015-04-14 02:47</p>
</td>
<td valign='top'>
<p>05:14:50</p>
</td>
<td valign='top'>
<p>3,740,460</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 8.1 Enterprise (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-14 10:42</p>
</td>
<td valign='top'>
<p>2015-04-14 11:09</p>
</td>
<td valign='top'>
<p>00:27:14</p>
</td>
<td valign='top'>
<p>3,401,446</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2012 R2 Standard - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-14 11:10</p>
</td>
<td valign='top'>
<p>2015-04-14 11:36</p>
</td>
<td valign='top'>
<p>00:26:07</p>
</td>
<td valign='top'>
<p>4,367,639</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 8.1 Enterprise (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-14 11:40</p>
</td>
<td valign='top'>
<p>2015-04-14 14:04</p>
</td>
<td valign='top'>
<p>02:22:54</p>
</td>
<td valign='top'>
<p>7,614,960</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2012 R2 Standard - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-14 14:40</p>
</td>
<td valign='top'>
<p>2015-04-14 15:52</p>
</td>
<td valign='top'>
<p>01:12:26</p>
</td>
<td valign='top'>
<p>5,216,299</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>SharePoint Server 2013 - Development</p>
</td>
<td valign='top'>
<p>2015-04-14 20:09</p>
</td>
<td valign='top'>
<p>2015-04-14 21:58</p>
</td>
<td valign='top'>
<p>01:49:11</p>
</td>
<td valign='top'>
<p>12,877,218</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>SQL Server 2014</li>
<li>Visual Studio 2013</li>
<li>Office 2013</li>
<li>SharePoint Server 2013</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
</table>

### Update task sequence - "SharePoint Server 2013 - Development"

Edit the task sequence to enable the Windows Update actions.

1. Open **Deployment Workbench**, expand **Deployment Shares / MDT Build Lab ([\\\\ICEMAN\\MDT-Build\$](\\ICEMAN\MDT-Build$)) / Task Sequences / Windows Server 2012 R2**, right-click **SharePoint Server 2013 - Development** and click **Properties**.
2. In the **SharePoint Server 2013 - Development Properties** window:
   1. On the **General **tab, configure the following settings:
      1. Comments: **Reference image - Windows Server 2012 R2, Toolbox content, Windows features for SharePoint 2013, PowerShell help files, SQL Server 2014, Visual Studio 2013 with Update 4, Office 2013, SharePoint Server 2013, and latest patches**
   2. On the **Task Sequence** tab, configure the following settings:
      1. **State Restore**
         1. Enable the **Windows Update (Pre-Application Installation)** action.
         2. Enable the **Windows Update (Post-Application Installation)** action.
   3. Click **OK**.

---

**WOLVERINE**

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\DiffMerge.exe \\ICEMAN\MDT-Build$ '.\Main\MDT-Build$'
```

#### # Sync files

```PowerShell
robocopy \\ICEMAN\MDT-Build$ Main\MDT-Build$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools
```

#### Check-in files

---

## Build baseline image (SharePoint Server 2013 - Development)

---

**STORM**

### # Create temporary VM to build image (SharePoint Server 2013 - Development)

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Build-x86.iso -VhdSize 50GB -Force
```

---

<table>
<thead>
<th>
<p><strong>Task Sequence</strong></p>
</th>
<th>
<p><strong>Start</strong></p>
</th>
<th>
<p><strong>End</strong></p>
</th>
<th>
<p><strong>Duration[HH:MM:SS]</strong></p>
</th>
<th>
<p><strong>Image Size [KB]</strong></p>
</th>
<th>
<p><strong>Comments</strong></p>
</th>
</thead>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x86) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 07:42</p>
</td>
<td valign='top'>
<p>2015-04-13 08:01</p>
</td>
<td valign='top'>
<p>00:18:45</p>
</td>
<td valign='top'>
<p>2,069,449</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 08:01</p>
</td>
<td valign='top'>
<p>2015-04-13 08:24</p>
</td>
<td valign='top'>
<p>00:22:36</p>
</td>
<td valign='top'>
<p>2,754,165</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2008 R2 - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 08:42</p>
</td>
<td valign='top'>
<p>2015-04-13 09:04</p>
</td>
<td valign='top'>
<p>00:21:14</p>
</td>
<td valign='top'>
<p>2,477,925</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x86) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 09:30</p>
</td>
<td valign='top'>
<p>2015-04-13 13:22</p>
</td>
<td valign='top'>
<p>03:51:50</p>
</td>
<td valign='top'>
<p>6,006,079</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 13:35</p>
</td>
<td valign='top'>
<p>2015-04-13 20:42</p>
</td>
<td valign='top'>
<p>07:06:52</p>
</td>
<td valign='top'>
<p>7,942,451</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2008 R2 - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 21:32</p>
</td>
<td valign='top'>
<p>2015-04-14 02:47</p>
</td>
<td valign='top'>
<p>05:14:50</p>
</td>
<td valign='top'>
<p>3,740,460</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 8.1 Enterprise (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-14 10:42</p>
</td>
<td valign='top'>
<p>2015-04-14 11:09</p>
</td>
<td valign='top'>
<p>00:27:14</p>
</td>
<td valign='top'>
<p>3,401,446</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2012 R2 Standard - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-14 11:10</p>
</td>
<td valign='top'>
<p>2015-04-14 11:36</p>
</td>
<td valign='top'>
<p>00:26:07</p>
</td>
<td valign='top'>
<p>4,367,639</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 8.1 Enterprise (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-14 11:40</p>
</td>
<td valign='top'>
<p>2015-04-14 14:04</p>
</td>
<td valign='top'>
<p>02:22:54</p>
</td>
<td valign='top'>
<p>7,614,960</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2012 R2 Standard - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-14 14:40</p>
</td>
<td valign='top'>
<p>2015-04-14 15:52</p>
</td>
<td valign='top'>
<p>01:12:26</p>
</td>
<td valign='top'>
<p>5,216,299</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>SharePoint Server 2013 - Development</p>
</td>
<td valign='top'>
<p>2015-04-14 20:09</p>
</td>
<td valign='top'>
<p>2015-04-14 21:58</p>
</td>
<td valign='top'>
<p>01:49:11</p>
</td>
<td valign='top'>
<p>12,877,218</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>SQL Server 2014</li>
<li>Visual Studio 2013</li>
<li>Office 2013</li>
<li>SharePoint Server 2013</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>SharePoint Server 2013 - Development</p>
</td>
<td valign='top'>
<p>2015-04-15 10:31</p>
</td>
<td valign='top'>
<p>2015-04-15 13:26</p>
</td>
<td valign='top'>
<p>02:54:34</p>
</td>
<td valign='top'>
<p>16,455,661</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>SQL Server 2014</li>
<li>Visual Studio 2013</li>
<li>Office 2013</li>
<li>SharePoint Server 2013</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
</table>

## Add custom action to cleanup images before Sysprep

**Reference:**

**Nice to Know - Get rid of all junk before Sysprep and Capture when creating a reference image in MDT**\
From <[https://anothermike2.wordpress.com/2014/06/05/nice-to-know-get-rid-of-all-junk-before-sysprep-and-capture-when-creating-a-reference-image-in-mdt/](https://anothermike2.wordpress.com/2014/06/05/nice-to-know-get-rid-of-all-junk-before-sysprep-and-capture-when-creating-a-reference-image-in-mdt/)>

### Download and extract script

1. Download custom script: [http://1drv.ms/ThvLFE](http://1drv.ms/ThvLFE)
2. Unblock zip file and extract to folder ("C:\\NotBackedUp\\Temp\\Action - Cleanup before Sysprep")

### # Create folder - "Applications\\Actions"

```PowerShell
Import-Module 'C:\Program Files\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1'

New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root \\ICEMAN\MDT-Build$

New-Item -Path "DS001:\Applications" -Name Actions -ItemType Folder
```

### # Add custom action to execute the cleanup script

```PowerShell
$appSourcePath = "C:\NotBackedUp\Temp\Action - Cleanup before Sysprep"
```

\$appName = "Action - Cleanup before Sysprep"

```PowerShell
$appShortName = "Cleanup-image"
$appSetupFolder = "Action - Cleanup before Sysprep"
$commandLine = "cscript.exe Action-CleanupBeforeSysprep.wsf"

Import-MDTApplication `
    -Path "DS001:\Applications\Actions" `
    -Name $appName `
    -ShortName $appShortName `
    -ApplicationSourcePath $appSourcePath `
    -DestinationFolder $appSetupFolder `
    -CommandLine $commandLine `
    -WorkingDirectory ".\Applications\$appSetupFolder"
```

### # Delete temporary folder

```PowerShell
Remove-Item "C:\NotBackedUp\Temp\Action - Cleanup before Sysprep"
```

### Add action to task sequences to cleanup images before Sysprep

1. Open **Deployment Workbench**, expand **Deployment Shares / MDT Build Lab ([\\\\ICEMAN\\MDT-Build\$](\\ICEMAN\MDT-Build$)) / Task Sequences / Windows 7**, right-click **Windows 7 Ultimate (x86) - Baseline** and click **Properties**.
2. In the **Windows 7 Ultimate (x86) - Baseline Properties** window:
   1. On the **General **tab, configure the following settings:
      1. Comments: **Reference image - Toolbox content, .NET Framework 3.5, Office 2013, latest patches, and cleanup before Sysprep**
   2. On the **Task Sequence** tab, configure the following settings:
      1. **State Restore**
         1. After the **Apply Local GPO Package** action, add a new **Group** action with the following setting:
            1. Name: **Cleanup before Sysprep**
         2. In the **Cleanup before Sysprep **group, add a new **Group** action with the following setting:
            1. Name: **Compress the image**
         3. Select **Compress the image** and add a new **Restart computer** action.
         4. Select **Compress the image** and add a new **Install Application** action with the following settings:
            1. Name: **Action - Cleanup before Sysprep**
            2. **Install a single application**
            3. Application to install: **Applications / Actions / Action - Cleanup before Sysprep**
         5. Select **Compress the image** and add a new **Restart computer** action.
   3. Right-click the **Cleanup before Sysprep **group and click **Copy**.
   4. Click **OK**.

Add the cleanup action to the other task sequences in the MDT build lab deployment share (right-click the **Apply Local GPO Package** action in each task sequence and then click **Paste**).

---

**WOLVERINE**

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\DiffMerge.exe \\ICEMAN\MDT-Build$ '.\Main\MDT-Build$'
```

#### # Sync files

```PowerShell
robocopy \\ICEMAN\MDT-Build$ Main\MDT-Build$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools
```

#### Check-in files

---

## Build baseline images

---

**STORM**

### # Create temporary VM to build image - "Windows 7 Ultimate (x86) - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Build-x86.iso -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows 7 Ultimate (x64) - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Build-x86.iso -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows Server 2008 R2 - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Build-x86.iso -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows 8.1 Enterprise (x64) - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Build-x86.iso -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows Server 2012 R2 Standard - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Build-x86.iso -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image - "SharePoint Server 2013 - Development"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Build-x86.iso -VhdSize 50GB -Force
```

---

<table>
<thead>
<th>
<p><strong>Task Sequence</strong></p>
</th>
<th>
<p><strong>Start</strong></p>
</th>
<th>
<p><strong>End</strong></p>
</th>
<th>
<p><strong>Duration[HH:MM:SS]</strong></p>
</th>
<th>
<p><strong>Image Size [KB]</strong></p>
</th>
<th>
<p><strong>Comments</strong></p>
</th>
</thead>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x86) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 07:42</p>
</td>
<td valign='top'>
<p>2015-04-13 08:01</p>
</td>
<td valign='top'>
<p>00:18:45</p>
</td>
<td valign='top'>
<p>2,069,449</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 08:01</p>
</td>
<td valign='top'>
<p>2015-04-13 08:24</p>
</td>
<td valign='top'>
<p>00:22:36</p>
</td>
<td valign='top'>
<p>2,754,165</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2008 R2 - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 08:42</p>
</td>
<td valign='top'>
<p>2015-04-13 09:04</p>
</td>
<td valign='top'>
<p>00:21:14</p>
</td>
<td valign='top'>
<p>2,477,925</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x86) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 09:30</p>
</td>
<td valign='top'>
<p>2015-04-13 13:22</p>
</td>
<td valign='top'>
<p>03:51:50</p>
</td>
<td valign='top'>
<p>6,006,079</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 13:35</p>
</td>
<td valign='top'>
<p>2015-04-13 20:42</p>
</td>
<td valign='top'>
<p>07:06:52</p>
</td>
<td valign='top'>
<p>7,942,451</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2008 R2 - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 21:32</p>
</td>
<td valign='top'>
<p>2015-04-14 02:47</p>
</td>
<td valign='top'>
<p>05:14:50</p>
</td>
<td valign='top'>
<p>3,740,460</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 8.1 Enterprise (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-14 10:42</p>
</td>
<td valign='top'>
<p>2015-04-14 11:09</p>
</td>
<td valign='top'>
<p>00:27:14</p>
</td>
<td valign='top'>
<p>3,401,446</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2012 R2 Standard - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-14 11:10</p>
</td>
<td valign='top'>
<p>2015-04-14 11:36</p>
</td>
<td valign='top'>
<p>00:26:07</p>
</td>
<td valign='top'>
<p>4,367,639</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 8.1 Enterprise (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-14 11:40</p>
</td>
<td valign='top'>
<p>2015-04-14 14:04</p>
</td>
<td valign='top'>
<p>02:22:54</p>
</td>
<td valign='top'>
<p>7,614,960</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2012 R2 Standard - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-14 14:40</p>
</td>
<td valign='top'>
<p>2015-04-14 15:52</p>
</td>
<td valign='top'>
<p>01:12:26</p>
</td>
<td valign='top'>
<p>5,216,299</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>SharePoint Server 2013 - Development</p>
</td>
<td valign='top'>
<p>2015-04-14 20:09</p>
</td>
<td valign='top'>
<p>2015-04-14 21:58</p>
</td>
<td valign='top'>
<p>01:49:11</p>
</td>
<td valign='top'>
<p>12,877,218</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>SQL Server 2014</li>
<li>Visual Studio 2013</li>
<li>Office 2013</li>
<li>SharePoint Server 2013</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>SharePoint Server 2013 - Development</p>
</td>
<td valign='top'>
<p>2015-04-15 10:31</p>
</td>
<td valign='top'>
<p>2015-04-15 13:26</p>
</td>
<td valign='top'>
<p>02:54:34</p>
</td>
<td valign='top'>
<p>16,455,661</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>SQL Server 2014</li>
<li>Visual Studio 2013</li>
<li>Office 2013</li>
<li>SharePoint Server 2013</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x86) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-16 18:05</p>
</td>
<td valign='top'>
<p>2015-04-16 21:48</p>
</td>
<td valign='top'>
<p>03:42:20</p>
</td>
<td valign='top'>
<p>6,103,447</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
<li>Cleanup before Sysprep</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-16 21:51</p>
</td>
<td valign='top'>
<p>2015-04-17 05:20</p>
</td>
<td valign='top'>
<p>07:29:34</p>
</td>
<td valign='top'>
<p>7,995,134</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
<li>Cleanup before Sysprep</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2008 R2 - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-17 05:22</p>
</td>
<td valign='top'>
<p>2015-04-17 10:09</p>
</td>
<td valign='top'>
<p>04:47:14</p>
</td>
<td valign='top'>
<p>3,507,598</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>Latest patches installed</li>
<li>Cleanup before Sysprep</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 8.1 Enterprise (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-17 10:12</p>
</td>
<td valign='top'>
<p>2015-04-17 13:18</p>
</td>
<td valign='top'>
<p>03:06:55</p>
</td>
<td valign='top'>
<p>7,553,906</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
<li>Cleanup before Sysprep</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2012 R2 Standard - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-17 13:26</p>
</td>
<td valign='top'>
<p>2015-04-17 14:55</p>
</td>
<td valign='top'>
<p>01:28:39</p>
</td>
<td valign='top'>
<p>4,483,866</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>Latest patches installed</li>
<li>Cleanup before Sysprep</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>SharePoint Server 2013 - Development</p>
</td>
<td valign='top'>
<p>2015-04-17 15:59</p>
</td>
<td valign='top'>
<p>2015-04-17 19:11</p>
</td>
<td valign='top'>
<p>03:12:09</p>
</td>
<td valign='top'>
<p>15,509,351</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>SQL Server 2014</li>
<li>Visual Studio 2013</li>
<li>Office 2013</li>
<li>SharePoint Server 2013</li>
<li>Latest patches installed</li>
<li>Cleanup before Sysprep</li>
</ul>
</td>
</tr>
</table>

### Add action to task sequences to set MaxPatchCacheSize to 0

1. Open **Deployment Workbench**, expand **Deployment Shares / MDT Build Lab ([\\\\ICEMAN\\MDT-Build\$](\\ICEMAN\MDT-Build$)) / Task Sequences / Windows 7**, right-click **Windows 7 Ultimate (x86) - Baseline** and click **Properties**.
2. In the **Windows 7 Ultimate (x86) - Baseline Properties** window:
   1. On the **General **tab, configure the following settings:
      1. Comments: **Reference image - MaxPatchCacheSize = 0, Toolbox content, .NET Framework 3.5, Office 2013, latest patches, and cleanup before Sysprep**
   2. On the **Task Sequence** tab, configure the following settings:
      1. **State Restore**
         1. In the **Custom Tasks (Pre-Windows Update)** group, add a new **Run Command Line** action with the following settings:
            1. Name: **Set MaxPatchCacheSize to 0**
            2. Command Line: **PowerShell.exe -Command "& { New-Item -Path 'HKLM:\\Software\\Policies\\Microsoft\\Windows\\Installer'; New-ItemProperty -Path 'HKLM:\\Software\\Policies\\Microsoft\\Windows\\Installer' -Name MaxPatchCacheSize -PropertyType DWord -Value 0 | Out-Null }"**
         2. Move **Set MaxPatchCache to 0** to be the first action in the **Custom Tasks (Pre-Windows Update)** group.
   3. Right-click the **Set MaxPatchCacheSize to 0 **group and click **Copy**.
   4. Click **OK**.

Add the copied action to the other task sequences in the MDT build lab deployment share (right-click the **Custom Tasks (Pre-Windows Update)** group in each task sequence, click **Paste**, and then move the action to the first position in the group).

---

**WOLVERINE**

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\DiffMerge.exe \\ICEMAN\MDT-Build$ '.\Main\MDT-Build$'
```

#### # Sync files

```PowerShell
robocopy \\ICEMAN\MDT-Build$ Main\MDT-Build$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools
```

#### Check-in files

---

## Build baseline images

---

**STORM**

### # Create temporary VM to build image - "Windows 7 Ultimate (x86) - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Build-x86.iso -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows 7 Ultimate (x64) - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Build-x86.iso -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows Server 2008 R2 - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Build-x86.iso -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows 8.1 Enterprise (x64) - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Build-x86.iso -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows Server 2012 R2 Standard - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Build-x86.iso -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image - "SharePoint Server 2013 - Development"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Build-x86.iso -VhdSize 50GB -Force
```

---

<table>
<thead>
<th>
<p><strong>Task Sequence</strong></p>
</th>
<th>
<p><strong>Start</strong></p>
</th>
<th>
<p><strong>End</strong></p>
</th>
<th>
<p><strong>Duration[HH:MM:SS]</strong></p>
</th>
<th>
<p><strong>Image Size [KB]</strong></p>
</th>
<th>
<p><strong>Comments</strong></p>
</th>
</thead>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x86) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 07:42</p>
</td>
<td valign='top'>
<p>2015-04-13 08:01</p>
</td>
<td valign='top'>
<p>00:18:45</p>
</td>
<td valign='top'>
<p>2,069,449</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 08:01</p>
</td>
<td valign='top'>
<p>2015-04-13 08:24</p>
</td>
<td valign='top'>
<p>00:22:36</p>
</td>
<td valign='top'>
<p>2,754,165</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2008 R2 - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 08:42</p>
</td>
<td valign='top'>
<p>2015-04-13 09:04</p>
</td>
<td valign='top'>
<p>00:21:14</p>
</td>
<td valign='top'>
<p>2,477,925</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x86) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 09:30</p>
</td>
<td valign='top'>
<p>2015-04-13 13:22</p>
</td>
<td valign='top'>
<p>03:51:50</p>
</td>
<td valign='top'>
<p>6,006,079</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 13:35</p>
</td>
<td valign='top'>
<p>2015-04-13 20:42</p>
</td>
<td valign='top'>
<p>07:06:52</p>
</td>
<td valign='top'>
<p>7,942,451</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2008 R2 - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 21:32</p>
</td>
<td valign='top'>
<p>2015-04-14 02:47</p>
</td>
<td valign='top'>
<p>05:14:50</p>
</td>
<td valign='top'>
<p>3,740,460</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 8.1 Enterprise (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-14 10:42</p>
</td>
<td valign='top'>
<p>2015-04-14 11:09</p>
</td>
<td valign='top'>
<p>00:27:14</p>
</td>
<td valign='top'>
<p>3,401,446</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2012 R2 Standard - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-14 11:10</p>
</td>
<td valign='top'>
<p>2015-04-14 11:36</p>
</td>
<td valign='top'>
<p>00:26:07</p>
</td>
<td valign='top'>
<p>4,367,639</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 8.1 Enterprise (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-14 11:40</p>
</td>
<td valign='top'>
<p>2015-04-14 14:04</p>
</td>
<td valign='top'>
<p>02:22:54</p>
</td>
<td valign='top'>
<p>7,614,960</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2012 R2 Standard - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-14 14:40</p>
</td>
<td valign='top'>
<p>2015-04-14 15:52</p>
</td>
<td valign='top'>
<p>01:12:26</p>
</td>
<td valign='top'>
<p>5,216,299</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>SharePoint Server 2013 - Development</p>
</td>
<td valign='top'>
<p>2015-04-14 20:09</p>
</td>
<td valign='top'>
<p>2015-04-14 21:58</p>
</td>
<td valign='top'>
<p>01:49:11</p>
</td>
<td valign='top'>
<p>12,877,218</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>SQL Server 2014</li>
<li>Visual Studio 2013</li>
<li>Office 2013</li>
<li>SharePoint Server 2013</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>SharePoint Server 2013 - Development</p>
</td>
<td valign='top'>
<p>2015-04-15 10:31</p>
</td>
<td valign='top'>
<p>2015-04-15 13:26</p>
</td>
<td valign='top'>
<p>02:54:34</p>
</td>
<td valign='top'>
<p>16,455,661</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>SQL Server 2014</li>
<li>Visual Studio 2013</li>
<li>Office 2013</li>
<li>SharePoint Server 2013</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x86) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-16 18:05</p>
</td>
<td valign='top'>
<p>2015-04-16 21:48</p>
</td>
<td valign='top'>
<p>03:42:20</p>
</td>
<td valign='top'>
<p>6,103,447</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
<li>Cleanup before Sysprep</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-16 21:51</p>
</td>
<td valign='top'>
<p>2015-04-17 05:20</p>
</td>
<td valign='top'>
<p>07:29:34</p>
</td>
<td valign='top'>
<p>7,995,134</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
<li>Cleanup before Sysprep</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2008 R2 - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-17 05:22</p>
</td>
<td valign='top'>
<p>2015-04-17 10:09</p>
</td>
<td valign='top'>
<p>04:47:14</p>
</td>
<td valign='top'>
<p>3,507,598</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>Latest patches installed</li>
<li>Cleanup before Sysprep</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 8.1 Enterprise (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-17 10:12</p>
</td>
<td valign='top'>
<p>2015-04-17 13:18</p>
</td>
<td valign='top'>
<p>03:06:55</p>
</td>
<td valign='top'>
<p>7,553,906</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
<li>Cleanup before Sysprep</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2012 R2 Standard - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-17 13:26</p>
</td>
<td valign='top'>
<p>2015-04-17 14:55</p>
</td>
<td valign='top'>
<p>01:28:39</p>
</td>
<td valign='top'>
<p>4,483,866</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>Latest patches installed</li>
<li>Cleanup before Sysprep</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>SharePoint Server 2013 - Development</p>
</td>
<td valign='top'>
<p>2015-04-17 15:59</p>
</td>
<td valign='top'>
<p>2015-04-17 19:11</p>
</td>
<td valign='top'>
<p>03:12:09</p>
</td>
<td valign='top'>
<p>15,509,351</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>SQL Server 2014</li>
<li>Visual Studio 2013</li>
<li>Office 2013</li>
<li>SharePoint Server 2013</li>
<li>Latest patches installed</li>
<li>Cleanup before Sysprep</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x86) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-19 17:38</p>
</td>
<td valign='top'>
<p>2015-04-19 21:22</p>
</td>
<td valign='top'>
<p>03:44:31</p>
</td>
<td valign='top'>
<p>5,740,563</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>MaxPatchCacheSize = 0</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
<li>Cleanup before Sysprep</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-19 22:14</p>
</td>
<td valign='top'>
<p>2015-04-20 04:48</p>
</td>
<td valign='top'>
<p>06:34:39</p>
</td>
<td valign='top'>
<p>7,549,271</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>MaxPatchCacheSize = 0</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
<li>Cleanup before Sysprep</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2008 R2 - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-20 05:50</p>
</td>
<td valign='top'>
<p>2015-04-20 11:05</p>
</td>
<td valign='top'>
<p>05:15:29</p>
</td>
<td valign='top'>
<p>3,506,953</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>MaxPatchCacheSize = 0</li>
<li>Latest patches installed</li>
<li>Cleanup before Sysprep</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 8.1 Enterprise (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-20 11:06</p>
</td>
<td valign='top'>
<p>2015-04-20 14:10</p>
</td>
<td valign='top'>
<p>03:03:56</p>
</td>
<td valign='top'>
<p>7,143,736</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>MaxPatchCacheSize = 0</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
<li>Cleanup before Sysprep</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2012 R2 Standard - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-20 14:11</p>
</td>
<td valign='top'>
<p>2015-04-20 15:31</p>
</td>
<td valign='top'>
<p>01:20:33</p>
</td>
<td valign='top'>
<p>4,484,514</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>MaxPatchCacheSize = 0</li>
<li>Latest patches installed</li>
<li>Cleanup before Sysprep</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>SharePoint Server 2013 - Development</p>
</td>
<td valign='top'>
<p>2015-04-20 15:33</p>
</td>
<td valign='top'>
<p>2015-04-20 18:41</p>
</td>
<td valign='top'>
<p>03:08:16</p>
</td>
<td valign='top'>
<p>15,155,477</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>MaxPatchCacheSize = 0</li>
<li>SQL Server 2014</li>
<li>Visual Studio 2013</li>
<li>Office 2013</li>
<li>SharePoint Server 2013</li>
<li>Latest patches installed</li>
<li>Cleanup before Sysprep</li>
</ul>
</td>
</tr>
</table>

```PowerShell
cls
```

## # Update MDT production deployment images

### # Update deployment image - "Windows 7 Ultimate (x86) - Baseline"

```PowerShell
Remove-Item "\\ICEMAN\MDT-Deploy$\Operating Systems\W7Ult-x86\*.wim"

$imageFile = "W7ULT-X86-REF_4-19-2015-5-39-04-PM.wim"

Move-Item "\\ICEMAN\MDT-Build$\Captures\$imageFile" `
    "\\ICEMAN\MDT-Deploy$\Operating Systems\W7Ult-x86\"

$path = "\\ICEMAN\MDT-Deploy$\Control\OperatingSystems.xml"

$xml = [xml] (Get-Content "$path")

$node = $xml.oss.os | ? { $_.Name -eq "Windows 7 Ultimate (x86) - Baseline" }
$node.ImageFile = ".\Operating Systems\W7Ult-x86\$imageFile"

$xml.Save($path)
```

```PowerShell
cls
```

### # Update deployment image - "Windows 7 Ultimate (x64) - Baseline"

```PowerShell
Remove-Item "\\ICEMAN\MDT-Deploy$\Operating Systems\W7Ult-x64\*.wim"

$imageFile = "W7ULT-X64-REF_4-19-2015-10-15-01-PM.wim"

Move-Item "\\ICEMAN\MDT-Build$\Captures\$imageFile" `
    "\\ICEMAN\MDT-Deploy$\Operating Systems\W7Ult-x64\"

$path = "\\ICEMAN\MDT-Deploy$\Control\OperatingSystems.xml"

$xml = [xml] (Get-Content "$path")

$node = $xml.oss.os | ? { $_.Name -eq "Windows 7 Ultimate (x64) - Baseline" }
$node.ImageFile = ".\Operating Systems\W7Ult-x64\$imageFile"

$xml.Save($path)
```

```PowerShell
cls
```

### # Update deployment image - "Windows Server 2008 R2 Standard - Baseline"

```PowerShell
Remove-Item "\\ICEMAN\MDT-Deploy$\Operating Systems\WS2008-R2\*.wim"

$imageFile = "WS2008-R2-REF_4-20-2015-5-51-00-AM.wim"

Move-Item "\\ICEMAN\MDT-Build$\Captures\$imageFile" `
    "\\ICEMAN\MDT-Deploy$\Operating Systems\WS2008-R2\"

$path = "\\ICEMAN\MDT-Deploy$\Control\OperatingSystems.xml"

$xml = [xml] (Get-Content "$path")

$node = $xml.oss.os | ? { $_.Name -eq "Windows Server 2008 R2 Standard - Baseline" }
$node.ImageFile = ".\Operating Systems\WS2008-R2\$imageFile"

$xml.Save($path)
```

```PowerShell
cls
```

## # Add Windows 8.1 and Windows Server 2012 R2 images to MDT production deployment share

### # Create folder - "Operating Systems\\Window 8.1"

```PowerShell
Import-Module 'C:\Program Files\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1'

New-PSDrive -Name "DS002" -PSProvider MDTProvider -Root \\ICEMAN\MDT-Deploy$

New-Item -Path "DS002:\Operating Systems" -Name "Windows 8.1" -ItemType Folder
```

```PowerShell
cls
```

### # Import image - "Windows 8 Enterprise (x64) - Baseline"

```PowerShell
$imagePath = "\\ICEMAN\MDT-Build$\Captures\W81ENT-X64-REF_4-20-2015-11-07-15-AM.wim"

$destinationFolder = "W81Ent-x64"

$os = Import-MDTOperatingSystem `
    -Path "DS002:\Operating Systems\Windows 8.1" `
    -SourceFile $imagePath `
    -DestinationFolder $destinationFolder `
    -Move

$os.RenameItem("Windows 8.1 Enterprise (x64) - Baseline")
```

```PowerShell
cls
```

### # Create folder - "Operating Systems\\Windows Server 2012 R2"

```PowerShell
New-Item -Path "DS002:\Operating Systems" -Name "Windows Server 2012 R2" -ItemType Folder
```

```PowerShell
cls
```

### # Import image - "Windows Server 2012 R2 Standard - Baseline"

```PowerShell
$imagePath = "\\ICEMAN\MDT-Build$\Captures\WS2012-R2-REF_4-20-2015-2-11-42-PM.wim"

$destinationFolder = "WS2012-R2"

$os = Import-MDTOperatingSystem `
    -Path "DS002:\Operating Systems\Windows Server 2012 R2" `
    -SourceFile $imagePath `
    -DestinationFolder $destinationFolder `
    -Move

$os.RenameItem("Windows Server 2012 R2 Standard - Baseline")
```

```PowerShell
cls
```

### # Import image - "SharePoint Server 2013 - Development"

```PowerShell
$imagePath = "\\ICEMAN\MDT-Build$\Captures\SP2013-DEV-REF_4-20-2015-3-33-56-PM.wim"

$destinationFolder = "SP2013-DEV"

$os = Import-MDTOperatingSystem `
    -Path "DS002:\Operating Systems\Windows Server 2012 R2" `
    -SourceFile $imagePath `
    -DestinationFolder $destinationFolder `
    -Move

$os.RenameItem("SharePoint Server 2013 - Development")
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
& "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\TF.exe" add Main /r
```

##### Check-in files

---

```PowerShell
cls
```

## # Create task sequences for Windows 8.1 and Windows Server 2012 R2 deployments

### # Create folder - "Task Sequences\\Window 8.1"

```PowerShell
New-Item -Path "DS002:\Task Sequences" -Name "Windows 8.1" -ItemType Folder
```

### # Create task sequence - "Windows 8.1 Enterprise (x64)"

```PowerShell
$osPath = "DS002:\Operating Systems\Windows 8.1\Windows 8.1 Enterprise (x64) - Baseline"

Import-MDTTaskSequence `
    -Path "DS002:\Task Sequences\Windows 8.1" `
    -ID "W81ENT-X64" `
    -Name "Windows 8.1 Enterprise (x64)" `
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

### # Create folder - "Task Sequences\\Windows Server 2012 R2"

```PowerShell
New-Item -Path "DS002:\Task Sequences" -Name "Windows Server 2012 R2" -ItemType Folder
```

### # Create task sequence - "Windows Server 2012 R2"

```PowerShell
$osPath = "DS002:\Operating Systems\Windows Server 2012 R2" `
    + "\Windows Server 2012 R2 Standard - Baseline"

Import-MDTTaskSequence `
    -Path "DS002:\Task Sequences\Windows Server 2012 R2" `
    -ID "WS2012-R2" `
    -Name "Windows Server 2012 R2" `
    -Comments "Production image" `
    -Version "1.0" `
    -Template "Server.xml" `
    -OperatingSystemPath $osPath `
    -FullName "Windows User" `
    -OrgName "Technology Toolbox" `
    -HomePage "about:blank" `
    -ProductKey "NPD6V-MT6HM-C8F3J-4QFH8-HMGPB" `
    -AdminPassword "{redacted}"
```

> **Important**
>
> The MSDN version of Windows Server 2012 R2 will prompt to enter a product key (but provide an option to skip this step). It does not honor the SkipProductKey=YES entry in the MDT CustomSettings.ini file.

> **Important**
>
> Windows Server 2012 R2 with Update requires a password to be specified for the Administrator account (unlike Windows 8.1). If an Administrator password is not specified in the task sequence, the Lite Touch Installation will prompt for a password (which must be subsequently be entered manually when completing the actions specified in the task sequence).

```PowerShell
cls
```

### # Create task sequence - "SharePoint Server 2013 - Development"

```PowerShell
$osPath = "DS002:\Operating Systems\Windows Server 2012 R2" `
    + "\SharePoint Server 2013 - Development"

Import-MDTTaskSequence `
    -Path "DS002:\Task Sequences\Windows Server 2012 R2" `
    -ID "SP2013-DEV" `
    -Name "SharePoint Server 2013 - Development" `
    -Comments "Production image" `
    -Version "1.0" `
    -Template "Server.xml" `
    -OperatingSystemPath $osPath `
    -FullName "Windows User" `
    -OrgName "Technology Toolbox" `
    -HomePage "about:blank" `
    -ProductKey "NPD6V-MT6HM-C8F3J-4QFH8-HMGPB" `
    -AdminPassword "{redacted}"
```

> **Important**
>
> The MSDN version of Windows Server 2012 R2 will prompt to enter a product key (but provide an option to skip this step). It does not honor the SkipProductKey=YES entry in the MDT CustomSettings.ini file.

> **Important**
>
> Windows Server 2012 R2 with Update requires a password to be specified for the Administrator account (unlike Windows 8.1). If an Administrator password is not specified in the task sequence, the Lite Touch Installation will prompt for a password (which must be subsequently be entered manually when completing the actions specified in the task sequence).

---

**WOLVERINE**

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

robocopy \\ICEMAN\MDT-Deploy$ Main\MDT-Deploy$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools
```

#### # Add files to TFS

```PowerShell
& "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\TF.exe" add Main /r
```

##### Check-in files

---

## Add action to task sequences to create native images for .NET assemblies

1. Open **Deployment Workbench**, expand **Deployment Shares / MDT Production ([\\\\ICEMAN\\MDT-Deploy\$](\\ICEMAN\MDT-Deploy$)) / Task Sequences / Windows 7 **folder, right-click **Windows 7 Ultimate (x86)** and click **Properties**.
2. In the **Windows 7 Ultimate (x86) Properties** window:
   1. On the **General **tab, configure the following settings:
      1. Comments: **Production image - create native images for .NET assemblies**
   2. On the **Task Sequence** tab, configure the following settings:
      1. **State Restore**
         1. In the **Custom Tasks **group, add a new **Run Command Line** action with the following settings:
            1. Name: **Create native images for .NET assemblies**
            2. Command line: **PowerShell.exe -Command "Get-ChildItem \$env:SystemRoot\\Microsoft.NET -Filter Ngen.exe -Recurse | % { & \$_.FullName executeQueuedItems }"**
   3. Right-click the **Create native images for .NET assemblies** action and click **Copy**.
   4. Click **OK**.

Add the copied action to the other task sequences in the MDT production deployment share (right-click the **Custom Tasks **group in each task sequence, and click **Paste**).

## Add SharePoint Designer 2013 to "SharePoint Server 2013 - Development" image

```PowerShell
cls
```

### # Create application - "SharePoint Designer 2013 with Service Pack 1 (x86)"

#### # Extract the content of the setup package

```PowerShell
$packagePath = "\\ICEMAN\Products\Microsoft\SharePoint Designer 2013\" `
    + "en_sharepoint_designer_2013_with_sp1_x86_3948134.exe"

$tempSourcePath = "C:\NotBackedUp\Temp\SPD2013-x86-SP1"

& $packagePath /extract:$tempSourcePath
```

> **Important**
>
> Wait for the package content to be extracted.

```PowerShell
cls
```

#### # Import the application

```PowerShell
Import-Module 'C:\Program Files\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1'

New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root \\ICEMAN\MDT-Build$
```

\$appName = "SharePoint Designer 2013 with Service Pack 1 (x86)"

```PowerShell
$appShortName = "SPD2013-x86-SP1"
$appSetupFolder = $appShortName
$commandLine = "setup.exe /config sharepointdesigner.ww\config.xml"

Import-MDTApplication `
    -Path "DS001:\Applications\Microsoft" `
    -Name $appName `
    -ShortName $appShortName `
    -ApplicationSourcePath $tempSourcePath `
    -DestinationFolder $appSetupFolder `
    -CommandLine $commandLine `
    -WorkingDirectory ".\Applications\$appSetupFolder"
```

#### # Delete the temporary files

```PowerShell
Remove-Item $tempSourcePath -Force -Recurse
```

#### Configure Microsoft SharePoint Designer 2013 installation settings

1. Open **Deployment Workbench**, expand **Deployment Shares / MDT Build Lab ([\\\\ICEMAN\\MDT-Build\$](\\ICEMAN\MDT-Build$)) / Applications / Microsoft**, right-click **SharePoint Designer 2013 with Service Pack 1 (x86)**, and click **Properties**.
2. In the **SharePoint Designer 2013 with Service Pack 1 (x86) Properties** window:
   1. On the **Office Products** tab:
      1. In the **Office product to install** dropdown, ensure **SharePointDesigner** is selected.
      2. In the **Config.xml settings** section:
         1. Click the **Customer name** checkbox and then type **Technology Toolbox **in the corresponding textbox.
         2. Click the **Display level** checkbox and then click **None **in the corresponding dropdown list.
         3. Click the **Accept EULA **checkbox.
         4. Click the **Always suppress reboot **checkbox.
   2. In the **SharePoint Designer 2013 with Service Pack 1 (x86) Properties** window, click **OK**.

### Add action to "SharePoint Server 2013 - Development" task sequence to install SharePoint Designer 2013

1. Open **Deployment Workbench**, expand **Deployment Shares / MDT Build Lab ([\\\\ICEMAN\\MDT-Build\$](\\ICEMAN\MDT-Build$)) / Task Sequences / Windows Server 2012 R2**, right-click **SharePoint Server 2012 - Development**, and click **Properties**.
2. In the **SharePoint Server 2012 - Development** window:
   1. On the **General **tab, configure the following settings:
      1. Comments: **Reference image - Windows Server 2012 R2, MaxPatchCacheSize = 0, Toolbox content, Windows features for SharePoint 2013, PowerShell help files, SQL Server 2014, Visual Studio 2013 with Update 4, Office 2013, SharePoint Designer 2013, SharePoint Server 2013, latest patches, and cleanup before Sysprep**
   2. On the **Task Sequence** tab, configure the following settings:
      1. **State Restore**
         1. Select the **Custom Tasks (Pre-Windows Update)** group and add a new **Install Application** action with the following settings:
            1. Name: **Install SharePoint Designer 2013 with Service Pack 1 (x86)**
            2. **Install a single application**
            3. Application to install: **Applications / Microsoft / SharePoint Designer 2013 with Service Pack 1 (x86)**
         2. Move **Install SharePoint Designer 2013 with Service Pack 1 (x86)** after the **Install Microsoft Office 2013 Professional Plus (x86)** action.
   3. Click **OK**.

```PowerShell
cls
```

### # Delete SharePoint Designer 2013 from MDT production deployment share

```PowerShell
Remove-Item -Path "DS002:\Applications\Microsoft\SharePoint Designer 2013 with Service Pack 1 (x86)" -Force
```

---

**WOLVERINE**

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

robocopy \\ICEMAN\MDT-Build$ Main\MDT-Build$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools

robocopy \\ICEMAN\MDT-Deploy$ Main\MDT-Deploy$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools
```

##### Check-in files

---

## Build baseline image

---

**STORM**

```PowerShell
cls
```

### # Create temporary VM to build image - "SharePoint Server 2013 - Development"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Build-x86.iso -VhdSize 50GB -Force
```

---

<table>
<thead>
<th>
<p><strong>Task Sequence</strong></p>
</th>
<th>
<p><strong>Start</strong></p>
</th>
<th>
<p><strong>End</strong></p>
</th>
<th>
<p><strong>Duration[HH:MM:SS]</strong></p>
</th>
<th>
<p><strong>Image Size [KB]</strong></p>
</th>
<th>
<p><strong>Comments</strong></p>
</th>
</thead>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x86) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 07:42</p>
</td>
<td valign='top'>
<p>2015-04-13 08:01</p>
</td>
<td valign='top'>
<p>00:18:45</p>
</td>
<td valign='top'>
<p>2,069,449</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 08:01</p>
</td>
<td valign='top'>
<p>2015-04-13 08:24</p>
</td>
<td valign='top'>
<p>00:22:36</p>
</td>
<td valign='top'>
<p>2,754,165</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2008 R2 - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 08:42</p>
</td>
<td valign='top'>
<p>2015-04-13 09:04</p>
</td>
<td valign='top'>
<p>00:21:14</p>
</td>
<td valign='top'>
<p>2,477,925</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x86) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 09:30</p>
</td>
<td valign='top'>
<p>2015-04-13 13:22</p>
</td>
<td valign='top'>
<p>03:51:50</p>
</td>
<td valign='top'>
<p>6,006,079</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 13:35</p>
</td>
<td valign='top'>
<p>2015-04-13 20:42</p>
</td>
<td valign='top'>
<p>07:06:52</p>
</td>
<td valign='top'>
<p>7,942,451</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2008 R2 - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-13 21:32</p>
</td>
<td valign='top'>
<p>2015-04-14 02:47</p>
</td>
<td valign='top'>
<p>05:14:50</p>
</td>
<td valign='top'>
<p>3,740,460</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 8.1 Enterprise (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-14 10:42</p>
</td>
<td valign='top'>
<p>2015-04-14 11:09</p>
</td>
<td valign='top'>
<p>00:27:14</p>
</td>
<td valign='top'>
<p>3,401,446</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2012 R2 Standard - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-14 11:10</p>
</td>
<td valign='top'>
<p>2015-04-14 11:36</p>
</td>
<td valign='top'>
<p>00:26:07</p>
</td>
<td valign='top'>
<p>4,367,639</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 8.1 Enterprise (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-14 11:40</p>
</td>
<td valign='top'>
<p>2015-04-14 14:04</p>
</td>
<td valign='top'>
<p>02:22:54</p>
</td>
<td valign='top'>
<p>7,614,960</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2012 R2 Standard - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-14 14:40</p>
</td>
<td valign='top'>
<p>2015-04-14 15:52</p>
</td>
<td valign='top'>
<p>01:12:26</p>
</td>
<td valign='top'>
<p>5,216,299</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>SharePoint Server 2013 - Development</p>
</td>
<td valign='top'>
<p>2015-04-14 20:09</p>
</td>
<td valign='top'>
<p>2015-04-14 21:58</p>
</td>
<td valign='top'>
<p>01:49:11</p>
</td>
<td valign='top'>
<p>12,877,218</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>SQL Server 2014</li>
<li>Visual Studio 2013</li>
<li>Office 2013</li>
<li>SharePoint Server 2013</li>
<li>No patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>SharePoint Server 2013 - Development</p>
</td>
<td valign='top'>
<p>2015-04-15 10:31</p>
</td>
<td valign='top'>
<p>2015-04-15 13:26</p>
</td>
<td valign='top'>
<p>02:54:34</p>
</td>
<td valign='top'>
<p>16,455,661</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>SQL Server 2014</li>
<li>Visual Studio 2013</li>
<li>Office 2013</li>
<li>SharePoint Server 2013</li>
<li>Latest patches installed</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x86) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-16 18:05</p>
</td>
<td valign='top'>
<p>2015-04-16 21:48</p>
</td>
<td valign='top'>
<p>03:42:20</p>
</td>
<td valign='top'>
<p>6,103,447</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
<li>Cleanup before Sysprep</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-16 21:51</p>
</td>
<td valign='top'>
<p>2015-04-17 05:20</p>
</td>
<td valign='top'>
<p>07:29:34</p>
</td>
<td valign='top'>
<p>7,995,134</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
<li>Cleanup before Sysprep</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2008 R2 - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-17 05:22</p>
</td>
<td valign='top'>
<p>2015-04-17 10:09</p>
</td>
<td valign='top'>
<p>04:47:14</p>
</td>
<td valign='top'>
<p>3,507,598</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>Latest patches installed</li>
<li>Cleanup before Sysprep</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 8.1 Enterprise (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-17 10:12</p>
</td>
<td valign='top'>
<p>2015-04-17 13:18</p>
</td>
<td valign='top'>
<p>03:06:55</p>
</td>
<td valign='top'>
<p>7,553,906</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
<li>Cleanup before Sysprep</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2012 R2 Standard - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-17 13:26</p>
</td>
<td valign='top'>
<p>2015-04-17 14:55</p>
</td>
<td valign='top'>
<p>01:28:39</p>
</td>
<td valign='top'>
<p>4,483,866</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>Latest patches installed</li>
<li>Cleanup before Sysprep</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>SharePoint Server 2013 - Development</p>
</td>
<td valign='top'>
<p>2015-04-17 15:59</p>
</td>
<td valign='top'>
<p>2015-04-17 19:11</p>
</td>
<td valign='top'>
<p>03:12:09</p>
</td>
<td valign='top'>
<p>15,509,351</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>SQL Server 2014</li>
<li>Visual Studio 2013</li>
<li>Office 2013</li>
<li>SharePoint Server 2013</li>
<li>Latest patches installed</li>
<li>Cleanup before Sysprep</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x86) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-19 17:38</p>
</td>
<td valign='top'>
<p>2015-04-19 21:22</p>
</td>
<td valign='top'>
<p>03:44:31</p>
</td>
<td valign='top'>
<p>5,740,563</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>MaxPatchCacheSize = 0</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
<li>Cleanup before Sysprep</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 7 Ultimate (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-19 22:14</p>
</td>
<td valign='top'>
<p>2015-04-20 04:48</p>
</td>
<td valign='top'>
<p>06:34:39</p>
</td>
<td valign='top'>
<p>7,549,271</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>MaxPatchCacheSize = 0</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
<li>Cleanup before Sysprep</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2008 R2 - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-20 05:50</p>
</td>
<td valign='top'>
<p>2015-04-20 11:05</p>
</td>
<td valign='top'>
<p>05:15:29</p>
</td>
<td valign='top'>
<p>3,506,953</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.1.7601.17514</li>
<li>MaxPatchCacheSize = 0</li>
<li>Latest patches installed</li>
<li>Cleanup before Sysprep</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows 8.1 Enterprise (x64) - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-20 11:06</p>
</td>
<td valign='top'>
<p>2015-04-20 14:10</p>
</td>
<td valign='top'>
<p>03:03:56</p>
</td>
<td valign='top'>
<p>7,143,736</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>MaxPatchCacheSize = 0</li>
<li>Office 2013</li>
<li>Latest patches installed</li>
<li>Cleanup before Sysprep</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>Windows Server 2012 R2 Standard - Baseline</p>
</td>
<td valign='top'>
<p>2015-04-20 14:11</p>
</td>
<td valign='top'>
<p>2015-04-20 15:31</p>
</td>
<td valign='top'>
<p>01:20:33</p>
</td>
<td valign='top'>
<p>4,484,514</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>MaxPatchCacheSize = 0</li>
<li>Latest patches installed</li>
<li>Cleanup before Sysprep</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>SharePoint Server 2013 - Development</p>
</td>
<td valign='top'>
<p>2015-04-20 15:33</p>
</td>
<td valign='top'>
<p>2015-04-20 18:41</p>
</td>
<td valign='top'>
<p>03:08:16</p>
</td>
<td valign='top'>
<p>15,155,477</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>MaxPatchCacheSize = 0</li>
<li>SQL Server 2014</li>
<li>Visual Studio 2013</li>
<li>Office 2013</li>
<li>SharePoint Server 2013</li>
<li>Latest patches installed</li>
<li>Cleanup before Sysprep</li>
</ul>
</td>
</tr>
<tr>
<td valign='top'>
<p>SharePoint Server 2013 - Development</p>
</td>
<td valign='top'>
<p>2015-04-21 11:06</p>
</td>
<td valign='top'>
<p>2015-04-21 14:20</p>
</td>
<td valign='top'>
<p>03:14:21</p>
</td>
<td valign='top'>
<p>15,560,045</p>
</td>
<td valign='top'>
<ul>
<li>Build 6.3.9600.17415</li>
<li>MaxPatchCacheSize = 0</li>
<li>SQL Server 2014</li>
<li>Visual Studio 2013</li>
<li>Office 2013</li>
<li>SharePoint Designer 2013</li>
<li>SharePoint Server 2013</li>
<li>Latest patches installed</li>
<li>Cleanup before Sysprep</li>
</ul>
</td>
</tr>
</table>

```PowerShell
cls
```

## # Update MDT production deployment image

### # Update deployment image - "SharePoint Server 2013 - Development"

```PowerShell
Remove-Item "\\ICEMAN\MDT-Deploy$\Operating Systems\SP2013-DEV\*.wim"

$imageFile = "SP2013-DEV-REF_4-21-2015-11-06-45-AM.wim"

Move-Item "\\ICEMAN\MDT-Build$\Captures\$imageFile" `
    "\\ICEMAN\MDT-Deploy$\Operating Systems\SP2013-DEV\"

$path = "\\ICEMAN\MDT-Deploy$\Control\OperatingSystems.xml"

$xml = [xml] (Get-Content "$path")

$node = $xml.oss.os | ? { $_.Name -eq "SharePoint Server 2013 - Development" }
$node.ImageFile = ".\Operating Systems\SP2013-DEV\$imageFile"

$xml.Save($path)
```

TODO:

#### Enable action to run Windows Update after installing applications

1. Open **Deployment Workbench**, expand **Deployment Shares / MDT Production ([\\\\ICEMAN\\MDT-Deploy\$](\\ICEMAN\MDT-Deploy$)) / Task Sequences / Windows 8.1 **folder, right-click **Windows 8.1 Enterprise x64** and click **Properties**.
2. On the **Task Sequence** tab, configure the following settings:
   1. **State Restore**
      1. Enable the **Windows Update (Post-Application Installation)** action.
3. Click **OK**.

## Install System Center 2012 R2 Configuration Manager Toolkit (for log file viewer)

**System Center 2012 R2 Configuration Manager Toolkit**\
From <[https://www.microsoft.com/en-us/download/details.aspx?id=36213](https://www.microsoft.com/en-us/download/details.aspx?id=36213)>

## Update baseline images

---

**STORM**

```Console
PowerShell
```

```Console
cls
```

### # Create temporary VM to build image - "Windows 7 Ultimate (x86) - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Build-x86.iso -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows 7 Ultimate (x64) - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Build-x86.iso -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows Server 2008 R2 - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Build-x86.iso -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows 8.1 Enterprise (x64) - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Build-x86.iso -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows Server 2012 R2 Standard - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Build-x86.iso -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image - "SharePoint Server 2013 - Development"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\ICEMAN\Products\Microsoft\MDT-Build-x86.iso -VhdSize 50GB -Force
```

---

```PowerShell
cls
```

## # Update MDT production deployment images

---

**WOLVERINE**

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure\Main\Scripts

& '.\Update Deployment Images.ps1'
```

---

## # Configure firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

---

**FOOBAR8**

```PowerShell
$computer = 'MIMIC'

$command = "New-NetFirewallRule ``
    -Name 'Remote Windows Update (Dynamic RPC)' ``
    -DisplayName 'Remote Windows Update (Dynamic RPC)' ``
    -Description 'Allows remote auditing and installation of Windows updates via POSHPAIG (http://poshpaig.codeplex.com/)' ``
    -Group 'Technology Toolbox (Custom)' ``
    -Program '%windir%\system32\dllhost.exe' ``
    -Direction Inbound ``
    -Protocol TCP ``
    -LocalPort RPC ``
    -Profile Domain ``
    -Action Allow"

$scriptBlock = [ScriptBlock]::Create($command)

Invoke-Command -ComputerName $computer -ScriptBlock $scriptBlock
```

---

## Upgrade to Visual Studio 2013 with Update 5

```PowerShell
cls
```

### # Create application - "Visual Studio 2013 with Update 5 - Default"

#### # Mount the installation image

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\Visual Studio 2013" `
    + "\en_visual_studio_ultimate_2013_with_update_5_x86_dvd_6815896.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$appSourcePath = $imageDriveLetter + ":\"
```

#### # Import application

\$appName = "Visual Studio 2013 with Update 5 - Default"

```PowerShell
$appShortName = "VS2013-Update5"
$appSetupFolder = $appShortName
$commandLine = "vs_ultimate.exe /Quiet /NoRestart" `
    + " /AdminFile Z:\Applications\appSetupFolder\AdminDeployment.xml"
```

> **Important**
>
> You must specify the full path for the **AdminFile** parameter or else vs_ultimate.exe terminates with an error.

```PowerShell
Import-Module 'C:\Program Files\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1'

New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root \\ICEMAN\MDT-Build$

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

### # Create application - "Visual Studio 2013 with Update 5 - SP2013 Development"

#### # Create custom "AdminFile" for unattended Visual Studio 2013 installation for SP2013 development

```PowerShell
$path = "\\ICEMAN\MDT-Build$\Applications\VS2013-Update5"

$xml = [xml] (Get-Content "$path\AdminDeployment.xml")
```

##### # In the <BundleCustomizations> element, change the NoWeb attribute to "yes"

```PowerShell
$xml.AdminDeploymentCustomizations.BundleCustomizations.NoWeb = "yes"
```

##### # Change the Selected attributes for the following <SelectableItemCustomization> elements to "no"

##### # Id="Blend"

##### # Id="LightSwitch"

##### # Id="VC_MFC_Libraries"

##### # Id="SilverLight_Developer_Kit"

```PowerShell
$xml.AdminDeploymentCustomizations.SelectableItemCustomizations.SelectableItemCustomization |
    % {
        If ($_.Id -eq "Blend" `
            -Or $_.Id -eq "LightSwitch" `
            -Or $_.Id -eq "VC_MFC_Libraries" `
            -Or $_.Id -eq "SilverLight_Developer_Kit"
            )
        {
            $_.Selected = "no"
        }
    }

$xml.Save("$path\AdminDeployment-SP2013-Dev.xml")
```

#### # Import application

\$appName = "Visual Studio 2013 with Update 5 - SP2013 Development"

```PowerShell
$appShortName = "VS2013-Update5-SP2013-Dev"
$appSetupFolder = "VS2013-Update5"
$commandLine = "vs_ultimate.exe /Quiet /NoRestart" `
    + " /AdminFile Z:\Applications\$appSetupFolder\AdminDeployment-SP2013-Dev.xml"
```

> **Important**
>
> You must specify the full path for the **AdminFile** parameter or else vs_ultimate.exe terminates with an error.

```PowerShell
Import-MDTApplication `
    -Path "DS001:\Applications\Microsoft" `
    -Name $appName `
    -ShortName $appShortName `
    -NoSource `
    -CommandLine $commandLine `
    -WorkingDirectory ".\Applications\$appSetupFolder"
```

#### Replace application dependency

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5B/20DBE2F9F7F30CED09B3359BDFD561FE0FAD085B.png)

```PowerShell
cls
```

## # Upgrade Firefox and Thunderbird to latest versions

```PowerShell
New-PSDrive -Name "DS002" -PSProvider MDTProvider -Root \\ICEMAN\MDT-Deploy$
```

```PowerShell
cls
```

### # Remove obsolete Firefox application

```PowerShell
Remove-Item -Path "DS002:\Applications\Mozilla\Firefox 36.0"
```

```PowerShell
cls
```

### # Create application: Mozilla Firefox 40.0.2

\$appName = "Firefox 40.0.2"

```PowerShell
$appShortName = "Firefox"
$commandLine = '"\\ICEMAN\Products\Mozilla\Firefox\Firefox Setup 40.0.2.exe" -ms'

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
Remove-Item -Path "DS002:\Applications\Mozilla\Thunderbird 31.3.0"
```

### # Create application: Mozilla Thunderbird 38.2.0

\$appName = "Thunderbird 38.2.0"

```PowerShell
$appShortName = "Thunderbird"
$commandLine = '"\\ICEMAN\Products\Mozilla\Thunderbird\Thunderbird Setup 38.2.0.exe" -ms'

Import-MDTApplication `
    -Path "DS002:\Applications\Mozilla" `
    -Name $appName `
    -ShortName $appShortName `
    -NoSource `
    -CommandLine $commandLine
```

---

**WOLVERINE**

### # Update files in TFS

```PowerShell
cd C:\NotBackedUp\TechnologyToolbox\Infrastructure

C:\NotBackedUp\Public\Toolbox\DiffMerge\DiffMerge.exe \\ICEMAN\MDT-Build$ '.\Main\MDT-Build$'
```

#### # Sync files

```PowerShell
robocopy \\ICEMAN\MDT-Build$ Main\MDT-Build$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools

robocopy '\\ICEMAN\MDT-Build$\Applications\VS2013-Update5' '.\Main\MDT-Build$\Applications\VS2013-Update5' AdminDeployment-SP2013-Dev.xml

robocopy \\ICEMAN\MDT-Deploy$ Main\MDT-Deploy$ /E /XD Applications Backup Boot Captures Logs "Operating Systems" Servicing Tools
```

#### # Add files to TFS

```PowerShell
& "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\TF.exe" add Main /r
```

#### Check-in files

---

## Install Azure Active Directory Connect

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EC/428AD7FCE7641926C4151DA1BDC20AF9AE8813EC.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/37/6BE3FA2F5E0A130A80D237DE3947B9FE3C5DCE37.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/95/32FBEB5B4929E9C4F61E4C2897D987380BBB2695.png)

{missing screenshot - click **Install**}

![(screenshot)](https://assets.technologytoolbox.com/screenshots/58/EE2C173BA729BA90B43F2C082ECC031DEBB26958.png)

```PowerShell
cls
```

## # Install SMTP Server

```PowerShell
cls
```

### # Install IIS dependencies for SMTP Server

```PowerShell
Install-WindowsFeature `
    Web-ODBC-Logging, `
    Web-Mgmt-Console, `
    Web-Lgcy-Mgmt-Console, `
    Web-Metabase `
    -Source '\\ICEMAN\Products\Microsoft\Windows Server 2012 R2\Sources\SxS' `
    -Restart
```

```PowerShell
cls
```

### # Install SMTP Server

```PowerShell
Install-WindowsFeature `
    Smtp-Server `
    -IncludeManagementTools `
    -Source '\\ICEMAN\Products\Microsoft\Windows Server 2012 R2\Sources\SxS' `
    -Restart
```

### Configure SMTP Server

1. Open **Server Manager**, select **Tools**, and then select **Internet Information Services (IIS) 6.0 Manager**.
2. Expand the current server, right-click the **SMTP Virtual Server**, and then click **Properties**.
3. In the **SMTP Virtual Server Properties** window:
   1. On the **Access** tab:
      1. In the **Access control **section, click **Authentication...**
      2. In the **Authentication **window:
         1. Select **Integrated Windows Authentication**.
         2. Click **OK**.
      3. In the **Relay restrictions **section, click **Relay...**
      4. In the **Relay Restrictions **window:
         1. Ensure the **Only the list below** option is selected.
         2. Ensure **Allow all computers which successfully authenticate to relay, regardless of the list above** is selected.
         3. Click **OK**.
   2. Click **OK**.
4. Expand the **SMTP Virtual Server** node, right-click **Domains**, point to **New**, and select **Domain...**
5. In the **New SMTP Domain Wizard**:
   1. On the welcome page, ensure the **Remote** option is selected, and click **Next**.
   2. On the **Domain Name** page, in the **Name** box, type **technologytoolbox.com**, and click **Finish**.

### # Configure SMTP service to start automatically

```PowerShell
Set-Service -Name SMTPSVC -StartupType Automatic

Start-Service -Name SMTPSVC
```

## Grant "MDT - Deploy" service account permission to join computers to the domain

### Issue

After joining 20 computers to the domain, MDT deployments started failing to join the computers to the domain.

### Resolution

Grant the service account (TECHTOOLBOX\\s-mdt-deploy) the appropriate permission on the domain:

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3C/27467670E4C2D22984F1B8E5126C058A684B803C.png)

## Update baseline images

---

**STORM**

```Console
PowerShell
```

```Console
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

---

**FOOBAR11**

```PowerShell
cls
```

## # Make virtual machine highly available

### # Migrate VM to shared storage

```PowerShell
$vmName = "MIMIC"

$vm = Get-SCVirtualMachine -Name $vmName
$vmHost = $vm.VMHost

Move-SCVirtualMachine `
    -VM $vm `
    -VMHost $vmHost `
    -HighlyAvailable $true `
    -Path "\\TT-SOFS01.corp.technologytoolbox.com\VM-Storage-Silver" `
    -UseDiffDiskOptimization
```

### # Allow migration to host with different processor version

```PowerShell
Stop-SCVirtualMachine -VM $vmName

Set-SCVirtualMachine -VM $vmName -CPULimitForMigration $true

Start-SCVirtualMachine -VM $vmName
```

---

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Move VM to new Production VM network

```PowerShell
$vmName = "MIMIC"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Production VM Network"

Stop-SCVirtualMachine $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -MACAddressType Dynamic `
    -IPv4AddressType Dynamic

Start-SCVirtualMachine $vmName
```

---

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Move VM to new Management VM network

```PowerShell
$vmName = "MIMIC"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Management VM Network"
$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"
$ipAddressPool = Get-SCStaticIPAddressPool -Name "Management-30 Address Pool"

Stop-SCVirtualMachine $vmName

$macAddress = Grant-SCMACAddress `
    -MACAddressPool $macAddressPool `
    -Description $vmName `
    -VirtualNetworkAdapter $networkAdapter

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -MACAddressType Static `
    -MACAddress $macAddress `
    -IPv4AddressPools $ipAddressPool `
    -IPv4AddressType Static

Start-SCVirtualMachine $vmName
```

---

### # Rename network connection

```PowerShell
$interfaceAlias = "Management"

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

## Upgrade Azure Active Directory Connect

Download

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E6/16E98AA5E46B1B4495FDE0176A04B7F957A37BE6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/03/4643EED1C1F1434208E0A03BB494EED94767C303.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D4/A1DBF1E3AE8BF21D9EB0AA7DE8BA68C30E9166D4.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/62/1009CB1B7A6446A5AC874DC87EB88667E73EF362.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/97/D3AEB5873F70A365CD0745A119E4FFF178C24E97.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/84/F67F7AA640308BC779B2702CE1BAF798E8044984.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AC/B01727CF66D3D146A64B7131C628EC5519D933AC.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FF/ADB8557ECF919D8B61FD07ECB5A78FF0895F00FF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/54/E87D0A010848FA04D05B3B15F37AB27B14AB4754.png)

Learn more - [https://go.microsoft.com/fwlink/?linkid=850962](https://go.microsoft.com/fwlink/?linkid=850962)

If you have a single forest on-premises, then the attribute you should use is objectGUID. This is also the attribute used when you use express settings in Azure AD Connect and also the attribute used by DirSync.\
If you have multiple forests and do not move users between forests and domains, then objectGUID is a good attribute to use even in this case.

From <[https://docs.microsoft.com/en-us/azure/active-directory/hybrid/plan-connect-design-concepts](https://docs.microsoft.com/en-us/azure/active-directory/hybrid/plan-connect-design-concepts)>

[https://go.microsoft.com/fwlink/?linkid=862773](https://go.microsoft.com/fwlink/?linkid=862773)\
smasters@technologytoolbox.com

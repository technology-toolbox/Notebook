# STORM - Windows 10 Enterprise x64

Monday, July 2, 2018
11:20 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Install Windows 10 Enterprise (x64)

#### Install custom Windows 10 image

- On the **Task Sequence** step, select **Windows 10 Enterprise (x64)** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **STORM**.
  - Specify **WORKGROUP**.
  - Click **Next**.
- On the **Applications** step:
  - Select the following applications:
    - **Adobe**
      - **Adobe Reader 8.3.1**
    - **Chrome**
      - **Chrome (64-bit)**
    - **Mozilla**
      - **Firefox (64-bit)**
      - **Thunderbird**
  - Click **Next**.

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

Install DaVinci Resolve

# Rename computer and join domain

```PowerShell
$computerName = "STORM"

Rename-Computer -NewName $computerName -Restart
```

Wait for the VM to restart and then execute the following command to join the **TECHTOOLBOX **domain:

```PowerShell
Add-Computer -DomainName corp.technologytoolbox.com -Restart
```

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Move computer to different OU

```PowerShell
$vmName = "STORM"

$targetPath = ("OU=Workstations,OU=Resources,OU=Development" `
    + ",DC=corp,DC=technologytoolbox,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

---

### Login as local administrator account

### # Install NVIDIA display driver

```PowerShell
$setupPath = "\\TT-FS01\Products\Drivers\NVIDIA\GT-1030" `
    + "\416.34-desktop-win10-64bit-international-whql.exe"

Start-Process -FilePath $setupPath -Wait
```

> **Important**
>
> Wait for the installation to complete.

### # Install Intel network drivers

```PowerShell
$setupPath = "\\TT-FS01\Products\Drivers\Intel\Network\82579LM" `
    + "\Windows 10\PROWinx64.exe"

Start-Process -FilePath $setupPath -Wait
```

> **Important**
>
> Wait for the installation to complete.

```PowerShell
Restart-Computer
```

### # Configure networking

```PowerShell
$interfaceAlias = "LAN"
```

#### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

$interfaceDescription = "Intel(R) 82579LM Gigabit Network Connection"

Get-NetAdapter -InterfaceDescription $interfaceDescription |
    Rename-NetAdapter -NewName $interfaceAlias
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Start-Sleep -Seconds 5

ping TT-FS01 -f -l 8900
```

```PowerShell
cls
```

### # Disable 'Automatically detect proxy settings' in Internet Explorer

```PowerShell
Function Disable-AutomaticallyDetectProxySettings {
    # Read connection settings from Internet Explorer.
    $regKeyPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Connections\"
    $conSet = $(Get-ItemProperty $regKeyPath).DefaultConnectionSettings

    # Index into DefaultConnectionSettings where the relevant flag resides.
    $flagIndex = 8

    # Bit inside the relevant flag which indicates whether or not to enable automatically detect proxy settings.
    $autoProxyFlag = 8

    if ($($conSet[$flagIndex] -band $autoProxyFlag) -eq $autoProxyFlag)
    {
        # 'Automatically detect proxy settings' was enabled, adding one disables it.
        Write-Host "Disabling 'Automatically detect proxy settings'."
        $mask = -bnot $autoProxyFlag
        $conSet[$flagIndex] = $conSet[$flagIndex] -band $mask
        $conSet[4]++
        Set-ItemProperty -Path $regKeyPath -Name DefaultConnectionSettings -Value $conSet
    }

    $conSet = $(Get-ItemProperty $regKeyPath).DefaultConnectionSettings
    if ($($conSet[$flagIndex] -band $autoProxyFlag) -ne $autoProxyFlag)
    {
    	Write-Host "'Automatically detect proxy settings' is disabled."
    }
}

Disable-AutomaticallyDetectProxySettings
```

#### Reference

**Disable-AutomaticallyDetectSettings.ps1**\
From <[https://gist.github.com/ReubenBond/1387620](https://gist.github.com/ReubenBond/1387620)>

```PowerShell
cls
```

### # Configure storage

#### # Change drive letter for DVD-ROM

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
```

#### Physical disks

<table>
<tr>
<td valign='top'>
<p>Disk</p>
</td>
<td valign='top'>
<p>Description</p>
</td>
<td valign='top'>
<p>Capacity</p>
</td>
<td valign='top'>
<p>Drive Letter</p>
</td>
<td valign='top'>
<p>Volume Size</p>
</td>
<td valign='top'>
<p>Allocation Unit Size</p>
</td>
<td valign='top'>
<p>Volume Label</p>
</td>
</tr>
<tr>
<td valign='top'>
<p>0</p>
</td>
<td valign='top'>
<p>Model: Samsung SSD 850 PRO 256GB<br />
Serial number: *********19550Z</p>
</td>
<td valign='top'>
<p>256 GB</p>
</td>
<td valign='top'>
<p>C:</p>
</td>
<td valign='top'>
<p>235 GB</p>
</td>
<td valign='top'>
<p>4K</p>
</td>
<td valign='top'>
<p>System</p>
</td>
</tr>
<tr>
<td valign='top'>
<p>1</p>
</td>
<td valign='top'>
<p>Model: Samsung Samsung SSD 860 EVO 1TB<br />
Serial number: *********26709R</p>
</td>
<td valign='top'>
<p>1 TB</p>
</td>
<td valign='top'>
<p>E:</p>
</td>
<td valign='top'>
<p>931 GB</p>
</td>
<td valign='top'>
<p>4K</p>
</td>
<td valign='top'>
<p>Gold01</p>
</td>
</tr>
<tr>
<td valign='top'>
<p>2</p>
</td>
<td valign='top'>
<p>Model: WDC WD1001FALS-00E3A0<br />
Serial number: WD-******283566</p>
</td>
<td valign='top'>
<p>1 TB</p>
</td>
<td valign='top'>
<p>Z:</p>
</td>
<td valign='top'>
<p>931 GB</p>
</td>
<td valign='top'>
<p>4K</p>
</td>
<td valign='top'>
<p>Backup01</p>
</td>
</tr>
<tr>
<td valign='top'>
<p>3</p>
</td>
<td valign='top'>
<p>Model: WDC WD1002FAEX-00Y9A0<br />
Serial number: WD-******201582</p>
</td>
<td valign='top'>
<p>1 TB</p>
</td>
<td valign='top'>
<p>F:</p>
</td>
<td valign='top'>
<p>931 GB</p>
</td>
<td valign='top'>
<p>4K</p>
</td>
<td valign='top'>
<p>Bronze01</p>
</td>
</tr>
<tr>
<td valign='top'>
<p>4</p>
</td>
<td valign='top'>
<p>Model: ST1000NM0033-9ZM173<br />
Serial number: *****EMV</p>
</td>
<td valign='top'>
<p>1 TB</p>
</td>
<td valign='top'>
</td>
<td valign='top'>
</td>
<td valign='top'>
</td>
<td valign='top'>
</td>
</tr>
<tr>
<td valign='top'>
<p>5</p>
</td>
<td valign='top'>
<p>Model: ST1000NM0033-9ZM173<br />
Serial number: *****4YL</p>
</td>
<td valign='top'>
<p>1 TB</p>
</td>
<td valign='top'>
</td>
<td valign='top'>
</td>
<td valign='top'>
</td>
<td valign='top'>
</td>
</tr>
<tr>
<td valign='top'>
<p>6</p>
</td>
<td valign='top'>
<p>Model: Samsung SSD 970 PRO 512GB<br />
Serial number: *********_81B1_6431.</p>
</td>
<td valign='top'>
<p>512 GB</p>
</td>
<td valign='top'>
<p>D:</p>
</td>
<td valign='top'>
</td>
<td valign='top'>
<p>4K</p>
</td>
<td valign='top'>
<p>Platinum01</p>
</td>
</tr>
</table>

```PowerShell
Get-PhysicalDisk | sort DeviceId

Get-PhysicalDisk | select DeviceId, Model, SerialNumber, CanPool |
    sort DeviceId | Format-Table -AutoSize
```

```PowerShell
cls
```

#### # Configure partitions and volumes

##### # Rename "Windows" volume to "System"

```PowerShell
Get-Volume -DriveLetter C | Set-Volume -NewFileSystemLabel System
```

##### # Create "Gold01" volume (D:)

```PowerShell
Get-PhysicalDisk |    where { $_.SerialNumber -eq '*********26709R' } |    Get-Disk |    Clear-Disk -RemoveData -Confirm:$false -PassThru |    Initialize-Disk -PartitionStyle GPT -PassThru |    New-Partition -DriveLetter "E" -UseMaximumSize |    Format-Volume `        -FileSystem NTFS `        -NewFileSystemLabel "Gold01" `        -Confirm:$false
```

```PowerShell
cls
```

### # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

### # Configure firewall rules for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
Set-ExecutionPolicy RemoteSigned -Scope Process -Force

C:\NotBackedUp\Public\Toolbox\PowerShell\Enable-RemoteWindowsUpdate.ps1 -Verbose
C:\NotBackedUp\Public\Toolbox\PowerShell\Disable-RemoteWindowsUpdate.ps1 `
    -Verbose
```

### Create default folders

> **Important**
>
> Run the following commands using a non-elevated command prompt (to avoid issues with customizing the folder icons).

---

**Command Prompt**

```Console
mkdir C:\NotBackedUp\Public\Symbols
mkdir C:\NotBackedUp\Temp
```

---

```PowerShell
cls
```

### # Configure cmder shortcut in Windows Explorer ("Cmder Here")

```PowerShell
C:\NotBackedUp\Public\Toolbox\cmder\Cmder.exe /REGISTER ALL
```

## Install and configure Hyper-V

### Enable Hyper-V

```PowerShell
cls
```

### # Configure VM storage

```PowerShell
mkdir D:\NotBackedUp\VMs

Set-VMHost -VirtualMachinePath D:\NotBackedUp\VMs
```

### # Create virtual switches

```PowerShell
$interfaceAlias = "LAN"

New-VMSwitch `
    -Name $interfaceAlias `
    -NetAdapterName $interfaceAlias `
    -AllowManagementOS $true
```

### # Enable jumbo frames on virtual switches

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name "vEthernet ($interfaceAlias)" `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

Start-Sleep -Seconds 5

ping TT-FS01 -f -l 8900
```

```PowerShell
cls
```

## # Install and configure Microsoft Money

### # Install Microsoft Money

```PowerShell
net use \\TT-FS01\Products /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$setupPath = "\\TT-FS01\Products\Microsoft\Money 2008\USMoneyBizSunset.exe"

Start-Process -FilePath $setupPath -Wait
```

> **Important**
>
> Wait for the installation to complete.

### Patch Money DLL to avoid crash when importing transactions

1. Open DLL in hex editor:
2. Make the following changes:

```Console
    C:\NotBackedUp\Public\Toolbox\HxD\HxD.exe "C:\Program Files (x86)\Microsoft Money Plus\MNYCoreFiles\mnyob99.dll"
```

    File offset **003FACE8**: Change **85** to **8D**\
    File offset **003FACED**: Change **50** to **51**\
    File offset **003FACF0**: Change **FF** to **85**\
    File offset **003FACF6**: Change **E8** to **B9**

#### Reference

**Microsoft Money crashes during import of account transactions or when changing a payee of a downloaded transaction**\
From <[http://blogs.msdn.com/b/oldnewthing/archive/2012/11/13/10367904.aspx](http://blogs.msdn.com/b/oldnewthing/archive/2012/11/13/10367904.aspx)>

```PowerShell
cls
```

### # Create custom invoice template

```PowerShell
& "C:\Program Files (x86)\Microsoft Money Plus\MNYCoreFiles\tmplbldr.exe"
```

In the **New Template** window:

1. Ensure **Create new template** is selected and click **Next**.
2. In the **Name** box, type **Technology Toolbox** and click **Next**.
3. Ensure **Portrait **is selected and click **Finish**.
4. On the **File** menu, click **Save**.

> **Note**
>
> The new invoice template is created in the following folder:
>
> C:\\Users\\All Users\\Microsoft\\Money\\17.0\\Invoice

```PowerShell
cls
```

#### # Overwrite file with custom template

```PowerShell
Copy-Item `
    '\\TT-FS01\Users$\jjameson\My Documents\Technology Toolbox LLC\InvoiceTemplate.htm' `
    'C:\Users\All Users\Microsoft\Money\17.0\Invoice\usr19.htm'
```

#### Configure default invoice template

Edit invoice listing (2008Invoice.ntd) to move the "Technology Toolbox" invoice to the top (so it is selected by default).

```Console
Notepad "C:\Users\All Users\Microsoft\Money\17.0\Invoice\2008Invoice.ntd"
```

#### Reference

**Sunset Home & Business - Invoice issues**\
From <[https://microsoftmoneyoffline.wordpress.com/sunset-home-business-invoices/](https://microsoftmoneyoffline.wordpress.com/sunset-home-business-invoices/)>

### Install and configure MSMoneyQuotes

```PowerShell
cls
```

### # Install Python 2 (dependency for PocketSense)

#### # Install Python (using default options)

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$setupPath = "\\TT-FS01\Products\Python\python-2.7.15.amd64.msi"

Start-Process -FilePath $setupPath -Wait
```

> **Important**
>
> Wait for the installation to complete.

```PowerShell
cls
```

#### # Add Python folders to PATH environment variable

```PowerShell
Set-ExecutionPolicy RemoteSigned -Scope Process -Force

$pythonPathFolders = 'C:\Python27\', 'C:\Python27\Scripts'

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-PathFolders.ps1 `
    -Folders $pythonPathFolders `
    -EnvironmentVariableTarget Machine
```

### # Copy PocketSense files

```PowerShell
$source = "\\TT-FS01\Users$\jjameson\My Documents\Finances\MS Money\PocketSense"
$destination = "C:\BackedUp\MS Money\PocketSense"

robocopy $source $destination /E
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
$setupPath = "\\TT-FS01\Products\Git\Git-2.19.1-64-bit.exe"

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

```PowerShell
cls
```

## # Install GitHub Desktop

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$setupPath = "\\TT-FS01\Products\GitHub\GitHubDesktopSetup.exe"

Start-Process -FilePath $setupPath -Wait
```

> **Important**
>
> Wait for the installation to complete.

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
$setupPath = "\\TT-FS01\Products\Microsoft\Visual Studio 2017\Enterprise" `
    + "\vs_setup.exe"

Start-Process -FilePath $setupPath -Wait
```

Select the following workloads:

- **.NET desktop development**
- **Desktop development with C++**
- **ASP.NET and web development**
- **Azure development**
- **Python development**
- **Node.js development**
- **Data storage and processing**
- **Data science and analytical applications**
- **Office/SharePoint development**
- **.NET Core cross-platform development**

> **Note**
>
> When prompted, restart the computer to complete the installation.

```PowerShell
cls
```

## # Install Microsoft SQL Server 2017

### # Create folders for Distributed Replay Client

```PowerShell
mkdir "D:\NotBackedUp\Microsoft SQL Server\DReplayClient\WorkingDir\"
mkdir "D:\NotBackedUp\Microsoft SQL Server\DReplayClient\ResultDir\"
```

### # Install SQL Server

```PowerShell
net use \\TT-FS01\Products /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$sourcePath = "\\TT-FS01\Products\Microsoft\SQL Server 2017"
$destPath = "C:\NotBackedUp\Temp"
$isoFilename = "en_sql_server_2017_developer_x64_dvd_11296168.iso"

robocopy $sourcePath $destPath $isoFilename

$imagePath = "$destPath\$isoFilename"

Function Ensure-MountedDiskImage
{
    [CmdletBinding()]
    Param(
        [Parameter(Position = 1, Mandatory = $true)]
        [string] $ImagePath)

    $imageDriveLetter = (Get-DiskImage -ImagePath $ImagePath|
        Get-Volume).DriveLetter

    If ($imageDriveLetter -eq $null)
    {
        Write-Verbose "Mounting disk image ($ImagePath)..."
        $imageDriveLetter = (Mount-DiskImage -ImagePath $ImagePath -PassThru |
            Get-Volume).DriveLetter
    }

    return $imageDriveLetter
}

$imageDriveLetter = Ensure-MountedDiskImage $imagePath

If ((Get-Process -Name "setup" -ErrorAction SilentlyContinue) -eq $null)
{
    $setupPath = $imageDriveLetter + ':\setup.exe'

    Write-Verbose "Starting setup..."

    & $setupPath

    Start-Sleep -Seconds 15
}
```

On the **Feature Selection** step, click **Select All** and then clear the checkbox for **PolyBase Query Service for External Data **(since this requires the Java Runtime Environment to be installed).

On the **Server Configuration** page:

- For **SQL Server Database Engine**, change the **Startup Type** to **Manual**.
- For **SQL Server Analysis Services**, change the **Startup Type** to **Manual**.
- For **SQL Server Integration Services 14.0**, change the **Startup Type** to **Manual**.
- For **SQL Server Integration Services Scale Out Master 14.0**, change the **Startup Type** to **Manual**.
- For **SQL Server Integration Services Scale Out Worker 14.0**, change the **Startup Type** to **Manual**.

On the **Database Engine Configuration** page:

- On the **Server Configuration** tab, click **Add Current User**.
- On the **Data Directories** tab:
  - Change the **Data root directory** to **D:\\NotBackedUp\\Microsoft SQL Server\\**
  - Change the **Backup directory** to **Z:\\Microsoft SQL Server\\MSSQL14.MSSQLSERVER\\MSSQL\\Backup**

On the **Analysis Services Configuration** page:

- On the **Server Configuration** tab, click **Add Current User**.
- On the **Data Directories** tab:
  - Change the **Data directory** to **D:\\NotBackedUp\\Microsoft SQL Server\\MSAS14.MSSQLSERVER\\OLAP\\Data.**
  - Change the **Log file directory** to **D:\\NotBackedUp\\Microsoft SQL Server\\MSAS14.MSSQLSERVER\\OLAP\\Log.**
  - Change the **Temp directory** to **D:\\NotBackedUp\\Microsoft SQL Server\\MSAS14.MSSQLSERVER\\OLAP\\Temp.**
  - Change the **Backup directory** to **Z:\\NotBackedUp\\Microsoft SQL Server\\MSAS14.MSSQLSERVER\\OLAP\\Backup**.

On the **Distributed Replay Controller **page, click **Add Current User**.

On the **Distributed Replay Client **page:

- On the **Server Configuration** tab, click **Add Current User**.
  - Change the **Working Directory** to **D:\\NotBackedUp\\Microsoft SQL Server\\DReplayClient\\WorkingDir\\.**
  - Change the **Result Directory** to **D:\\NotBackedUp\\Microsoft SQL Server\\DReplayClient\\ResultDir\\.**

```PowerShell
cls
```

### # Remove installation media

```PowerShell
Dismount-DiskImage $imagePath

Remove-Item $imagePath -Confirm:$true
```

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
    + "\VSCodeSetup-x64-1.31.1.exe"

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

### Modify Visual Studio Code shortcut to use custom extension and user data locations

```Console
"C:\Program Files\Microsoft VS Code\Code.exe" --extensions-dir "C:\NotBackedUp\vscode-data\extensions" --user-data-dir "C:\NotBackedUp\vscode-data\user-data"
```

### Install Visual Studio Code extensions

#### Install extension: Azure Resource Manager Tools

#### Install extension: Beautify

#### Install extension: C#

#### Install extension: Debugger for Chrome

#### Install extension: ESLint

#### Install extension: GitLens - Git supercharged

#### Install extension: markdownlint

#### Install extension: Prettier - Code formatter

#### Install extension: TSLint

#### Install extension: vscode-icons

---

**Notes**

Potential issue when using both Beautify and Prettier extensions:\
**Prettier & Beautify**\
From <[https://css-tricks.com/prettier-beautify/](https://css-tricks.com/prettier-beautify/)>

HTML formatting issue with Prettier:

**Add the missing option to disable crappy Prettier VSCode HTML formatter #636**\
From <[https://github.com/prettier/prettier-vscode/issues/636](https://github.com/prettier/prettier-vscode/issues/636)>

---

#### Configure Visual Studio Code settings

1. Press **Ctrl+Shift+P**
2. Select **Preferences: Open Settings (JSON)**

---

**settings.json**

```Console
{
    "editor.formatOnSave": true,
    "editor.renderWhitespace": "boundary",
    "editor.rulers": [80],
    "files.trimTrailingWhitespace": true,
    "git.autofetch": true,
    "html.format.wrapLineLength": 80,
    "prettier.disableLanguages": ["html"],
    "terminal.integrated.shell.windows":
        "C:\\windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe",
    "workbench.iconTheme": "vscode-icons"
}
```

---

```PowerShell
cls
```

## # Install and configure Node.js

### # Install Node.js

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$setupPath = "\\TT-FS01\Products\node.js\node-v10.13.0-x64.msi"

Start-Process -FilePath $setupPath -Wait
```

> **Important**
>
> Wait for the installation to complete. Restart PowerShell for the change to PATH environment variable to take effect.

```Console
exit
```

### Change NPM file locations to avoid issues with redirected folders

#### Reference

**npm on windows, install with -g flag should go into appdata/local rather than current appdata/roaming?**\
From <[https://github.com/npm/npm/issues/4564](https://github.com/npm/npm/issues/4564)>

**`npm install -g bower` goes into infinite loop on windows with %appdata% being a UNC path**\
From <[https://github.com/npm/npm/issues/8814](https://github.com/npm/npm/issues/8814)>

> **Note**
>
> As illustrated in the following screenshot, the latest version of NPM (3.10.10) successfully installs the latest version of Bower (1.8.0) when %APPDATA% refers to a network location -- so it appears this problem has been fixed.
>
> ![(screenshot)](https://assets.technologytoolbox.com/screenshots/50/023FB51E49C5E086909FFCCD50D6AB5E5426CF50.png)
>
> ```Text
> PS C:\Users\jjameson> $env:APPDATA
> \\TT-FS01\Users$\jjameson\Application Data
> PS C:\Users\jjameson> npm install -g bower
> npm WARN deprecated bower@1.8.0: ..psst! While Bower is maintained, we recommend Yarn and Webpack for *new* front-end projects! Yarn's advantage is security and reliability, and Webpack's is support for both CommonJS and AMD projects. Currently there's no migration path, but please help to create it: https://github.com/bower/bower/issues/2467
> \\TT-FS01\Users$\jjameson\Application Data\npm\bower -> \\TT-FS01\Users$\jjameson\Application Data\npm\node_modules\bower\bin\bower
> \\TT-FS01\Users$\jjameson\Application Data\npm
> `-- bower@1.8.0
> ```
>
> However, it still seems like a good idea to install global packages to %LOCALAPPDATA% instead of %APPDATA%:\
> **npm on windows, install with -g flag should go into appdata/local rather than current appdata/roaming?**\
> From <[https://github.com/npm/npm/issues/17325](https://github.com/npm/npm/issues/17325)>

```PowerShell
cls
```

#### # Configure installed version of npm to avoid issues with redirected folders

```PowerShell
notepad "C:\Program Files\nodejs\node_modules\npm\npmrc"
```

---

**C:\\Program Files\\nodejs\\node_modules\\npm\\npmrc**

```Text
;prefix=${APPDATA}\npm
prefix=${LOCALAPPDATA}\npm
cache=${LOCALAPPDATA}\npm-cache
```

---

```PowerShell
cls
```

### # Change NPM "global" locations to shared location for all users

```PowerShell
mkdir "$env:ALLUSERSPROFILE\npm-cache"

mkdir "$env:ALLUSERSPROFILE\npm\node_modules"

npm config --global set prefix "$env:ALLUSERSPROFILE\npm"

npm config --global set cache "$env:ALLUSERSPROFILE\npm-cache"

Set-ExecutionPolicy RemoteSigned -Scope Process -Force

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-PathFolders.ps1 `
    -Folders "$env:ALLUSERSPROFILE\npm" `
    -EnvironmentVariableTarget Machine
```

```PowerShell
cls
```

## # Install global NPM packages

### # Install Angular CLI

```PowerShell
npm install --global --no-optional @angular/cli@6.2.6
```

```PowerShell
cls
```

### # Install rimraf

```PowerShell
npm install --global rimraf@2.6.2
```

## TODO: Configure NPM locations for TECHTOOLBOX\\jjameson account

---

**runas /USER:TECHTOOLBOX\\jjameson PowerShell.exe**

```PowerShell
npm config --global set prefix "$env:ALLUSERSPROFILE\npm"

npm config --global set cache "$env:ALLUSERSPROFILE\npm-cache"
```

---

## Configure Visual Studio 2017 to use newer versions of Node.js and NPM

### Before

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0F/3B5712D6462D49CC17DB1EFE2DDAF657FB52E00F.png)

### After

![(screenshot)](https://assets.technologytoolbox.com/screenshots/58/51CCEAA9A97B80142D704A7789E6919ADBFF7258.png)

### Reference

**Synchronizing node version with your environment in Visual Studio 2017**\
From <[https://www.domstamand.com/synchronizing-node-version-with-your-environment-in-visual-studio-2017/](https://www.domstamand.com/synchronizing-node-version-with-your-environment-in-visual-studio-2017/)>

```PowerShell
cls
```

## # Configure development environment

### # Install IIS

```PowerShell
Enable-WindowsOptionalFeature `
    -Online `
    -All `
    -FeatureName IIS-ManagementConsole, `
        IIS-ASPNET45, `
        IIS-DefaultDocument, `
        IIS-DirectoryBrowsing, `
        IIS-HttpErrors, `
        IIS-StaticContent, `
        IIS-HttpLogging, `
        IIS-HttpCompressionStatic, `
        IIS-RequestFiltering, `
        IIS-WindowsAuthentication
```

### # Configure symbol path for debugging

```PowerShell
$symbolPath = "SRV*C:\NotBackedUp\Public\Symbols" `
     + "*\\TT-FS01\Public\Symbols" `
     + "*https://msdl.microsoft.com/download/symbols"

[Environment]::SetEnvironmentVariable("_NT_SYMBOL_PATH", $symbolPath, "Machine")
```

```PowerShell
cls
```

### # Install reference assemblies

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$source = '\\TT-FS01\Builds\Reference Assemblies'
$destination = 'C:\Program Files\Reference Assemblies'

robocopy $source $destination /E

& "$destination\Microsoft\SharePoint v4\AssemblyFoldersEx - x64.reg"
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/62/DE96621F16BC51A75B6410BE1B94F33F9B8A0F62.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5E/06DBAE68F16F7F83442A5F1916BFBEFEFC0DD15E.png)

```PowerShell
& "$destination\Microsoft\SharePoint v5\AssemblyFoldersEx - x64.reg"
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AE/E9FD2601E62121DA76E1227B4436C7ED8F069CAE.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BB/9A7DF5FF756E44DAC0D8F600AA2D457598370EBB.png)

```PowerShell
cls
```

## # Install PowerShell modules

```PowerShell
Install-PackageProvider NuGet -MinimumVersion '2.8.5.201' -Force

Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

Install-Module -Name 'posh-git'
```

```PowerShell
cls
```

## # Install Chocolatey

```PowerShell
((New-Object System.Net.WebClient).DownloadString(
    'https://chocolatey.org/install.ps1')) |
    Invoke-Expression
```

> **Important**
>
> Restart PowerShell for environment changes to take effect.

```Console
exit
```

### Reference

**Installing Chocolatey**\
From <[https://chocolatey.org/install](https://chocolatey.org/install)>

## # Install HTML Tidy

```PowerShell
choco install html-tidy -y
```

```PowerShell
cls
```

## # Install Fiddler

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$setupPath = "\\TT-FS01\Products\Telerik\FiddlerSetup.exe"

$arguments = "/S /D=C:\Program Files\Telerik\Fiddler"

Start-Process `
    -FilePath $setupPath `
    -ArgumentList $arguments `
    -Wait
```

### Reference

**Default Install Path**\
[https://www.telerik.com/forums/default-install-path#t8qFEfoMnUWlg50zptFlHQ](https://www.telerik.com/forums/default-install-path#t8qFEfoMnUWlg50zptFlHQ)

```PowerShell
cls
```

## # Install Microsoft Message Analyzer

```PowerShell
$setupPath = "\\TT-FS01\Products\Microsoft\Message Analyzer 1.4\MessageAnalyzer64.msi"

Start-Process -FilePath $setupPath -Wait
```

> **Important**
>
> Wait for the installation to complete.

"Windows blocked the installation of a digitally unsigned driver..."

**Microsoft Message Anlayzer 1.4 - 'A Digitally Signed Driver Is Required'**From <[https://social.technet.microsoft.com/Forums/windows/en-US/48b4c226-fc3d-4793-b544-3440ed13424a/microsoft-message-anlayzer-14-a-digitally-signed-driver-is-required?forum=messageanalyzer](https://social.technet.microsoft.com/Forums/windows/en-US/48b4c226-fc3d-4793-b544-3440ed13424a/microsoft-message-anlayzer-14-a-digitally-signed-driver-is-required?forum=messageanalyzer)>

```PowerShell
cls
```

## # Install Wireshark

```PowerShell
$setupPath = "\\TT-FS01\Products\Wireshark\Wireshark-win64-2.6.4.exe"

Start-Process -FilePath $setupPath -Wait
```

> **Important**
>
> Wait for the installation to complete.

```PowerShell
cls
```

## # Install Microsoft Log Parser 2.2

```PowerShell
$setupPath = "\\TT-FS01\Public\Download\Microsoft\LogParser 2.2\LogParser.msi"

Start-Process -FilePath $setupPath -Wait
```

> **Important**
>
> Wait for the installation to complete.

```PowerShell
cls
```

## # Install Remote Desktop Connection Manager

```PowerShell
$setupPath = "\\TT-FS01\Products\Microsoft" `
    + "\Remote Desktop Connection Manager\rdcman.msi"

Start-Process -FilePath $setupPath -Wait
```

> **Important**
>
> Wait for the installation to complete.

```PowerShell
cls
```

## # Install Microsoft Expression Studio 4

### # Copy installation media from internal file server

```PowerShell
$isoFile = "en_expression_studio_4_ultimate_x86_dvd_537032.iso"

$source = "\\TT-FS01\Products\Microsoft\Expression Studio"

$destination = "C:\NotBackedUp\Temp"

robocopy $source $destination $isoFile
```

### Install Expression Studio

Use the "Toolbox" script to install Expression Studio

```PowerShell
cls
```

## # Install Paint.NET

```PowerShell
& "\\TT-FS01\Products\Paint.NET\paint.net.4.1.3.install.zip"
```

> **Important**
>
> Wait for the installation to complete.

```PowerShell
cls
```

## # Download PowerShell help files

```PowerShell
Update-Help
```

```PowerShell
cls
```

## # Install software for HP Photosmart 6515

```PowerShell
$setupPath = "\\TT-FS01\Products\HP\Photosmart 6515\PS6510_1315-1.exe"

Start-Process -FilePath $setupPath -Wait
```

On the **Software Selections** step:

1. Click **Customize Software Selections**.
2. Clear the checkboxes for the following items:
   - **HP Update**
   - **HP Photosmart 6510 series Product Improvement**
   - **Bing Bar for HP (includes HP Smart Print)**
   - **HP Photosmart 6510 series Help**
   - **HP Photo Creations**

[http://support.hp.com/us-en/drivers/selfservice/HP-Photosmart-6510-e-All-in-One-Printer-series---B2/5058334/model/5191793](http://support.hp.com/us-en/drivers/selfservice/HP-Photosmart-6510-e-All-in-One-Printer-series---B2/5058334/model/5191793)

```PowerShell
cls
```

## # Install SharePoint Online Management Shell

```PowerShell
$installerPath = "\\TT-FS01\Public\Download\Microsoft\SharePoint\Online" `
    + "\SharePointOnlineManagementShell_8316-1200_x64_en-us.msi"

$arguments = "/i `"$installerPath`""

Start-Process `
    -FilePath 'msiexec.exe' `
    -ArgumentList $arguments `
    -Wait
```

```PowerShell
cls
```

## # Configure name resolution for development environments

```PowerShell
notepad C:\Windows\system32\drivers\etc\hosts
```

---

**C:\\Windows\\system32\\drivers\\etc\\hosts**

```Text
...

# Securitas (Development)
10.1.20.41	ext-foobar9 client-local-9.securitasinc.com client2-local-9.securitasinc.com cloud-local-9.securitasinc.com cloud2-local-9.securitasinc.com employee-local-9.securitasinc.com media-local-9.securitasinc.com
```

---

```PowerShell
cls
```

## # Install NuGet package provider

```PowerShell
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
```

```PowerShell
cls
```

## # Install SharePoint PnP cmdlets

```PowerShell
Install-Module SharePointPnPPowerShellOnline
```

## Disable background apps

1. Open **Windows Settings**.
2. In the **Windows Setttings** window, select **Privacy**.
3. On the **Privacy** page, select **Background apps**.
4. On the **Background apps** page, disable the following apps from running in the background:
   - **3D Viewer**
   - **Calculator**
   - **Camera**
   - **Feedback Hub**
   - **Get Help**
   - **Maps**
   - **Microsoft Photos**
   - **Microsoft Solitaire Collection**
   - **Microsoft Store**
   - **Mobile Plans**
   - **Movies & TV**
   - **Office**
   - **OneNote**
   - **Paint 3D**
   - **People**
   - **Print 3D**
   - **Snip & Sketch**
   - **Sticky Notes**
   - **Tips**
   - **Voice Recorder**
   - **Xbox**
   - **Your Phone**

### Issue: Photos app consumes high CPU

```PowerShell
cls
```

## # Install Visual Studio 2019

### # Launch Visual Studio 2019 setup

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$setupPath = "\\TT-FS01\Products\Microsoft\Visual Studio 2019\Enterprise" `
    + "\vs_setup.exe"

Start-Process -FilePath $setupPath -Wait
```

Select the following workloads:

- **ASP.NET and web development**
- **Azure development**
- **Python development**
- **Node.js development**
- **.NET desktop development**
- **Desktop development with C++**
- **Universal Windows Platform development**
- **Data storage and processing**
- **Data science and analytical applications**
- **Office/SharePoint development**
- **.NET Core cross-platform development**

> **Note**
>
> When prompted, restart the computer to complete the installation.

```PowerShell
cls
```

## # Upgrade Angular CLI

### # Remove old version of Angular CLI

```PowerShell
npm uninstall --global @angular/cli
```

### # Install Angular CLI

```PowerShell
npm install --global --no-optional @angular/cli@7.3.8
```

```PowerShell
cls
```

## # Install SQL Server Management Studio

```PowerShell
& "\\TT-FS01\Products\Microsoft\SQL Server 2017\SSMS-Setup-ENU-14.0.17289.0.exe"
```

> **Important**
>
> Wait for the installation to complete.

```PowerShell
cls
```

## # Create and configure Caelum website

### # Set environment variables

```PowerShell
[Environment]::SetEnvironmentVariable(
  "CAELUM_URL",
  "http://www-local.technologytoolbox.com",
  "Machine")
```

> **Important**
>
> Restart PowerShell for environment variable to be available.

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    -IPAddress 127.0.0.1 `
    -Hostnames www-local.technologytoolbox.com
```

### # Rebuild website

```PowerShell
cd "C:\NotBackedUp\techtoolbox\Caelum\Main\Source\Deployment Files\Scripts"

& '.\Rebuild Website.ps1'
```

```PowerShell
cls
```

## # Install Bitwarden CLI

```PowerShell
npm install -g @bitwarden/cli
```

```PowerShell
cls
```

## # Install OpenCV

```PowerShell
setx -m OPENCV_DIR "C:\Program Files\OpenCV-3.4.6\opencv\build\x64\vc15"
```

#### # Add OpenCV bin folder to PATH environment variable

```PowerShell
Set-ExecutionPolicy RemoteSigned -Scope Process -Force

$openCVPathFolder = "%OPENCV_DIR%\bin"

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-PathFolders.ps1 `
    -Folders $openCVPathFolder `
    -EnvironmentVariableTarget Machine
```

**TODO:**\

## Share printer

![(screenshot)](https://assets.technologytoolbox.com/screenshots/01/2EDCC101189FC9A8E4E5FD9205D12E8EB82B2F01.png)

Click **Change Sharing Options**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/94/39D600ED528C73CAE3772FDA8A9E263E29CBF094.png)

## Install DPM agent

### # Install DPM 2016 agent

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$installer = "\\TT-FS01\Products\Microsoft\System Center 2016" `
    + "\DPM\Agents\DPMAgentInstaller_x64.exe"

& $installer TT-DPM02.corp.technologytoolbox.com
```

Review the licensing agreement. If you accept the Microsoft Software License Terms, select **I accept the license terms and conditions**, and then click **OK**.

Confirm the agent installation completed successfully and the following firewall exceptions have been added:

- Exception for DPMRA.exe in all profiles
- Exception for Windows Management Instrumentation service
- Exception for RemoteAdmin service
- Exception for DCOM communication on port 135 (TCP and UDP) in all profiles

#### Reference

**Installing Protection Agents Manually**\
Pasted from <[http://technet.microsoft.com/en-us/library/hh757789.aspx](http://technet.microsoft.com/en-us/library/hh757789.aspx)>

---

**TT-DPM02 - DPM Management Shell**

```PowerShell
cls
```

### # Attach DPM agent

```PowerShell
$productionServer = 'STORM'

.\Attach-ProductionServer.ps1 `
    -DPMServerName TT-DPM02 `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `
    -UserName jjameson-admin
```

---

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

### # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

## Install updates using Windows Update

**Note:** Repeat until there are no updates available for the computer.

```PowerShell
cls
```

### # Delete C:\\Windows\\SoftwareDistribution folder (4.7 GB)

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse
```

## Disk Cleanup

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

## # Configure e-mail and name for Git

```PowerShell
git config --global user.email "jjameson@technologytoolbox.com"
git config --global user.name "Jeremy Jameson"
```

## # Configure credential helper for Git

```PowerShell
git config --global credential.helper !"C:\\NotBackedUp\\Public\\Toolbox\\git-credential-winstore.exe"
```

## Other stuff that may need to be done

```PowerShell
cls
```

## # Install Microsoft InfoPath 2013

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$setupPath = "\\TT-FS01\Products\Microsoft\Office 2013" `
    + "\infopath_4753-1001_x86_en-us.exe"

Start-Process `
    -FilePath $setupPath `
    -Wait
```

> **Important**
>
> Wait for the installation to complete.

### Install Android SDK (for debugging Chrome on Samsung Galaxy)

#### Reference

[http://stackoverflow.com/a/24410867](http://stackoverflow.com/a/24410867)

#### Install Samsung USB driver

#### Install Java SE Development Kit 8u66

[http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html](http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html)

#### Install Android "SDK Tools Only"

[http://developer.android.com/sdk/index.html#Other](http://developer.android.com/sdk/index.html#Other)

#### Install Android SDK Platform-tools

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1E/75601D9C9EF795A16D815FE580D6571F20B23C1E.png)

#### Detect devices

```Console
cd C:\Program Files (x86)\Android\android-sdk\platform-tools

adb.exe devices
```

### Install Chutzpah Test Adapter

1. Open Visual Studio.
2. In the **Tools** menu, click **Extensions and Updates...**
3. In the **Extensions and Updates** dialog window:
   1. Select the **Online** pane.
   2. In the search box, type **Chutzpah**.
   3. In the list of items, select **Chutzpah Test Adapter for the Test Explorer**, and click **Download**.
   4. Review the license terms, and click **Install**.
   5. Wait for the extension to be installed.
   6. Click **Restart Now**.

### Install Chutzpah Test Runner

1. Open Visual Studio.
2. In the **Tools** menu, click **Extensions and Updates...**
3. In the **Extensions and Updates** dialog window:
   1. Select the **Online** pane.
   2. In the search box, type **Chutzpah**.
   3. In the list of items, select **Chutzpah Test Runner Context Menu Extension**, and click **Download**.
   4. Review the license terms, and click **Install**.
   5. Wait for the extension to be installled.
   6. Click **Restart Now**.

### Install Apple iTunes

### Install Sandcastle

#### Sandcastle Documentation Compiler Tools

#### Sandcastle Help File Builder

### Install MSBuild Community Tasks

### Install ASP.NET ViewState Helper 2.0.1

### Install Inkscape 0.48

### # Clone repository - Training

```PowerShell
mkdir src\Repos

cd src\Repos

git clone https://techtoolbox.visualstudio.com/DefaultCollection/_git/Training
```

### # Install ng-demos

#### # Install package dependencies

```PowerShell
npm install -g node-inspector
```

#### # Clone repo

```PowerShell
cd Training

git clone https://github.com/johnpapa/ng-demos.git
```

#### # Install packages

```PowerShell
cd ng-demos\modular

npm install
```

#### # Run dev build

```PowerShell
gulp serve-dev-debug
```

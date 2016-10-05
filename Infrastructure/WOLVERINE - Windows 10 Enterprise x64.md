# WOLVERINE - Windows 10 Enterprise x64

Tuesday, October 4, 2016
4:41 AM

## Install Windows 10 Enterprise (x64)

### # Rename computer

```PowerShell
Rename-Computer -NewName WOLVERINE -Restart
```

### # Join domain

```PowerShell
Add-Computer -DomainName corp.technologytoolbox.com -Restart
```

### # Create default folders

> **Important**
>
> Run the following commands using a non-elevated PowerShell window (to avoid issues with customizing the folder icons).

```Console
mkdir C:\NotBackedUp\Public
mkdir C:\NotBackedUp\Temp
```

### # Set time zone

```PowerShell
tzutil /s "Mountain Standard Time"
```

### # Set MaxPatchCacheSize to 0

```PowerShell
reg add HKLM\Software\Policies\Microsoft\Windows\Installer /v MaxPatchCacheSize /t REG_DWORD /d 0 /f
```

```PowerShell
cls
```

### # Configure network settings

#### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select Name, InterfaceDescription

Get-NetAdapter `
    -Name "Ethernet" |
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

ping ICEMAN -f -l 8900
```

> **Note**
>
> Trying to ping ICEMAN or the iSCSI network adapter on ICEMAN with a 9000 byte packet from FORGE resulted in an error (suggesting that jumbo frames were not configured). It also worked with 8970 bytes.

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

### # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

### # Copy Toolbox content

```PowerShell
net use \\ICEMAN\ipc$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```Console
robocopy \\ICEMAN\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E
```

```Console
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

```PowerShell
cls
```

### # Download PowerShell help files

```PowerShell
Update-Help
```

### # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

### # Configure firewall rules for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
Set-ExecutionPolicy RemoteSigned -Scope Process

C:\NotBackedUp\Public\Toolbox\PowerShell\Enable-RemoteWindowsUpdate.ps1 -Verbose
C:\NotBackedUp\Public\Toolbox\PowerShell\Disable-RemoteWindowsUpdate.ps1  -Verbose
```

```PowerShell
cls
```

## # Install Microsoft Money

```PowerShell
net use \\ICEMAN\Products /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
& "\\ICEMAN\Products\Microsoft\Money 2008\USMoneyBizSunset.exe"
```

### Create custom invoice template

Folder - C:\\Users\\All Users\\Microsoft\\Money\\17.0\\Invoice

Edit invoice listing (2008Invoice.ntd) to move "Technology Toolbox" invoice to top so it is selected by default

```Console
cd "C:\Users\All Users\Microsoft\Money\17.0\Invoice"
notepad .\2008Invoice.ntd
```

#### Reference

**Sunset Home & Business - Invoice issues**\
From <[https://microsoftmoneyoffline.wordpress.com/sunset-home-business-invoices/](https://microsoftmoneyoffline.wordpress.com/sunset-home-business-invoices/)>

### Patch Money DLL to avoid crash when importing transactions

1. Open DLL in hex editor:
2. Make the following changes:

    File offset **003FACE8**: Change **85** to **8D**\
    File offset **003FACED**: Change **50** to **51**\
    File offset **003FACF0**: Change **FF** to **85**\
    File offset **003FACF6**: Change **E8** to **B9**

#### Reference

**Microsoft Money crashes during import of account transactions or when changing a payee of a downloaded transaction**\
From <[http://blogs.msdn.com/b/oldnewthing/archive/2012/11/13/10367904.aspx](http://blogs.msdn.com/b/oldnewthing/archive/2012/11/13/10367904.aspx)>

## Install Microsoft Office Professional Plus 2016

```PowerShell
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

$isoFilename = "en_office_professional_plus_2016_x86_x64_dvd_6962141.iso"

$destFolder = "E:\NotBackedUp\Temp"

mkdir $destFolder

$sourcePath = "\\ICEMAN\Products\Microsoft\Office 2016" `
    + "\$isoFilename"

Copy $sourcePath $destFolder

$imagePath = "$destFolder\$isoFilename"
```

## Install Microsoft Visio Professional 2016

```PowerShell
cls
```

## # Install Microsoft InfoPath 2013

```PowerShell
& "\\ICEMAN\Products\Microsoft\Office 2013\infopath_4753-1001_x86_en-us.exe"
```

```PowerShell
cls
```

## # Install Adobe Reader

### # Install Adobe Reader 8.3

```PowerShell
& "\\ICEMAN\Products\Adobe\AdbeRdr830_en_US.msi"
```

> **Important**
>
> Wait for the installation to complete.

### # Install update for Adobe Reader

```PowerShell
& "\\ICEMAN\Products\Adobe\AdbeRdrUpd831_all_incr.msp"
```

```PowerShell
cls
```

## # Install Mozilla Firefox

```PowerShell
& "\\ICEMAN\Products\Mozilla\Firefox\Firefox Setup 49.0.1.exe" -ms
```

```PowerShell
cls
```

## # Install Google Chrome

```PowerShell
& \\ICEMAN\Products\Google\Chrome\googlechromestandaloneenterprise64.msi
```

```PowerShell
cls
```

## # Install FileZilla

```PowerShell
& \\ICEMAN\Products\FileZilla\FileZilla_3.22.1_win64-setup.exe
```

```PowerShell
cls
```

## # Install Paint.NET

```PowerShell
& "\\ICEMAN\Products\Paint.NET\paint.net.4.0.12.install.zip"
```

## Install Microsoft Expression Studio 4

```PowerShell
cls
```

## # Install Microsoft Visual Studio 2015 Enterprise with Update 2

```PowerShell
$sourcePath = "\\ICEMAN\Products\Microsoft\Visual Studio 2015"
$destPath = "E:\NotBackedUp\Temp"
$isoFilename = "en_visual_studio_enterprise_2015_with_update_3_x86_x64_dvd_8923288.iso"

robocopy $sourcePath $destPath $isoFilename

$imagePath = "$destPath\$isoFilename"

$imageDriveLetter = Ensure-MountedDiskImage $imagePath

If ((Get-Process -Name "vs_enterprise" -ErrorAction SilentlyContinue) -eq $null)
{
    $setupPath = $imageDriveLetter + ':\vs_enterprise.exe'

    Write-Verbose "Starting setup..."

    & $setupPath

    Start-Sleep -Seconds 15
}
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9A/ACDA391F5D951BCC223707F0D0AF2DF01F6ED49A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/69/3D184DB58FB449B09BA3A8C96808BE56AFE0AC69.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BD/7DA9EE2C35C29A126B4BAA3835DB28DC7EF69ABD.png)

Select the following features:

- Windows and Web Development
  - **Microsoft Office Developer Tools**
  - **Microsoft Web Developer Tools**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/83/92B19D856F2778744C00F8799038082A88EB9D83.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EC/7BEC5B0BCF7DD4693FB012016FFC95B9ADFC9FEC.png)

### Install Microsoft Azure SDK 2.9.5

### Install Microsoft Office Developer Tools Update 2 for Visual Studio 2015

```PowerShell
cls
```

### # Install reference assemblies

```PowerShell
net use \\ICEMAN\ipc$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$source = '\\ICEMAN\Builds\Reference Assemblies'
$dest = 'C:\Program Files\Reference Assemblies'

robocopy $source $dest /E

& "$dest\Microsoft\SharePoint v4\AssemblyFoldersEx - x64.reg"
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/62/DE96621F16BC51A75B6410BE1B94F33F9B8A0F62.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5E/06DBAE68F16F7F83442A5F1916BFBEFEFC0DD15E.png)

```PowerShell
& "$dest\Microsoft\SharePoint v5\AssemblyFoldersEx - x64.reg"
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AE/E9FD2601E62121DA76E1227B4436C7ED8F069CAE.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BB/9A7DF5FF756E44DAC0D8F600AA2D457598370EBB.png)

```PowerShell
cls
```

### # Configure symbol path for debugging

```PowerShell
$symbolPath = "SRV*C:\NotBackedUp\Public\Symbols*\\ICEMAN\Public\Symbols*http://msdl.microsoft.com/download/symbols"
[Environment]::SetEnvironmentVariable("_NT_SYMBOL_PATH", $symbolPath, "Machine")
```

```PowerShell
cls
```

## # Install Python (dependency for many node.js packages)

### # Install Python (using default options)

```PowerShell
net use \\iceman\ipc$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
& "\\ICEMAN\Products\Python\python-2.7.11.amd64.msi"
```

### # Add Python folders to PATH environment variable

```PowerShell
Set-ExecutionPolicy RemoteSigned -Force

$pythonPathFolders = 'C:\Python27\', 'C:\Python27\Scripts'

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-PathFolders.ps1 `
    -Folders $pythonPathFolders `
    -EnvironmentVariableTarget Machine
```

```PowerShell
cls
```

## # Install Git (required by npm to download packages from GitHub)

### # Install Git (using default options)

```PowerShell
& \\ICEMAN\Products\Git\Git-2.8.3-64-bit.exe
```

### # Add Git folder to PATH environment variable

```PowerShell
$gitPathFolder = 'C:\Program Files\Git\cmd'

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-PathFolders.ps1 `
    -Folders $gitPathFolder `
    -EnvironmentVariableTarget Machine
```

```PowerShell
cls
```

## # Install and configure Node.js

### # Install Node.js

```PowerShell
& \\ICEMAN\Products\node.js\node-v4.4.7-x64.msi
```

> **Important**
>
> Restart PowerShell for change to PATH environment variable to take effect.

### Change NPM file locations to avoid issues with redirected folders

#### Reference

**npm on windows, install with -g flag should go into appdata/local rather than current appdata/roaming?**\
From <[https://github.com/npm/npm/issues/4564](https://github.com/npm/npm/issues/4564)>

**`npm install -g bower` goes into infinite loop on windows with %appdata% being a UNC path**\
From <[https://github.com/npm/npm/issues/8814](https://github.com/npm/npm/issues/8814)>

#### # Configure installed version of npm to avoid issues with redirected folders

```PowerShell
notepad "C:\Program Files\nodejs\node_modules\npm\npmrc"
```

In Notepad, change:

```Text
    prefix=${APPDATA}\npm
```

...to:

```Text
    ;prefix=${APPDATA}\npm
    prefix=${LOCALAPPDATA}\npm
    cache=${LOCALAPPDATA}\npm-cache
```

#### # Configure Visual Studio version of npm to avoid issues with redirected folders

```PowerShell
& "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\Extensions\Microsoft\Web Tools\External\npm.cmd" config set -g cache '${LOCALAPPDATA}\npm-cache'

& : The term 'C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\Extensions\Microsoft\WebTools\External\npm.cmd' is not recognized as the name of a cmdlet, function, script file, or operable program. Checkthe spelling of the name, or if a path was included, verify that the path is correct and try again.At line:1 char:3+ & "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\Ex ...+   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    + CategoryInfo          : ObjectNotFound: (C:\Program File...xternal\npm.cmd:String) [], CommandNotFoundException    + FullyQualifiedErrorId : CommandNotFoundException


notepad "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\Extensions\Microsoft\Web Tools\External\node\etc\npmrc"
```

##### Issue

The system cannot find the path specified.

**TODO:**

In Notepad, change:

```Text
    cache = C:\Users\foo\AppData\Local\npm-cache
```

...to:

```Text
    cache = ${LOCALAPPDATA}\npm-cache
```

```Console
cls
```

### # Change NPM "global" locations to shared location for all users

```PowerShell
mkdir "$env:ALLUSERSPROFILE\npm-cache"

mkdir "$env:ALLUSERSPROFILE\npm\node_modules"

npm config --global set prefix "$env:ALLUSERSPROFILE\npm"

npm config --global set cache "$env:ALLUSERSPROFILE\npm-cache"

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-PathFolders.ps1 `
    -Folders "$env:ALLUSERSPROFILE\npm" `
    -EnvironmentVariableTarget Machine
```

**TODO:**

```PowerShell
& "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\Extensions\Microsoft\Web Tools\External\npm.cmd" config set -g cache "$env:ALLUSERSPROFILE\npm-cache"
```

#### Reference

**How to use npm with node.exe?**\
http://stackoverflow.com/a/9366416

## Install global NPM packages

### Reference

**Install the Yeoman toolset**\
From <[http://yeoman.io/codelab/setup.html](http://yeoman.io/codelab/setup.html)>

```PowerShell
cls
```

### # Install Grunt CLI

```PowerShell
npm install --global grunt-cli
```

```PowerShell
cls
```

### # Install Gulp

```PowerShell
npm install --global gulp
```

```PowerShell
cls
```

### # Install Bower

```PowerShell
npm install --global bower
```

```PowerShell
cls
```

### # Install Karma CLI

```PowerShell
npm install --global karma-cli
```

```PowerShell
cls
```

### # Install Yeoman

```PowerShell
npm install --global yo
```

```PowerShell
cls
```

### # Install Yeoman generators

```PowerShell
npm install --global generator-karma

npm install --global generator-angular
```

```PowerShell
cls
```

### # Install rimraf

```PowerShell
npm install --global rimraf
```

## TODO: # Configure npm locations for TECHTOOLBOX\\jjameson account

---

**runas /USER:TECHTOOLBOX\\jjameson PowerShell.exe**

```PowerShell
npm config --global set prefix "$env:ALLUSERSPROFILE\npm"

npm config --global set cache "$env:ALLUSERSPROFILE\npm-cache"

& "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\Extensions\Microsoft\Web Tools\External\npm.cmd" config set cache '${LOCALAPPDATA}\npm-cache'
```

---

## TODO: "Upgrade NPM" version in Visual Studio 2015

### Before

![(screenshot)](https://assets.technologytoolbox.com/screenshots/65/16ED937A4EC8A4D914E16BDF0D7F6EC115CC2965.png)

### After

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9F/FD14463E819276232A1137CA4609DAE9E4FDB99F.png)

### Reference

**Upgrading NPM in Visual Studio 2015**\
From <[http://jameschambers.com/2015/09/upgrading-npm-in-visual-studio-2015/](http://jameschambers.com/2015/09/upgrading-npm-in-visual-studio-2015/)>

```PowerShell
cls
```

## # Install Chocolatey

```PowerShell
iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex

exit
```

> **Important**
>
> Restart PowerShell for environment changes to take effect.

### Reference

**Installing Chocolatey**\
From <[https://chocolatey.org/install](https://chocolatey.org/install)>

## # Install HTML Tidy

```PowerShell
choco install html-tidy
```

## Install GitHub Desktop

[https://desktop.github.com/](https://desktop.github.com/)

## Install Microsoft SQL Server 2016

```PowerShell
$sourcePath = "\\ICEMAN\Products\Microsoft\SQL Server 2016"
$destPath = "E:\NotBackedUp\Temp"
$isoFilename = "en_sql_server_2016_developer_x64_dvd_8777069.iso"

robocopy $sourcePath $destPath $isoFilename

$imagePath = "$destPath\$isoFilename"

$imageDriveLetter = Ensure-MountedDiskImage $imagePath

If ((Get-Process -Name "setup" -ErrorAction SilentlyContinue) -eq $null)
{
    $setupPath = $imageDriveLetter + ':\setup.exe'

    Write-Verbose "Starting setup..."

    & $setupPath

    Start-Sleep -Seconds 15
}
```

On the **Server Configuration** page, for **SQL Server Database Engine**, change the **Startup Type** to **Manual**

On the **Database Engine Configuration** page, on the **Data Directories** tab:

- Change the **Data root directory** to **D:\\NotBackedUp\\Microsoft SQL Server\\**
- Change the **Backup directory** to **Z:\\Microsoft SQL Server\\MSSQL13.MSSQLSERVER\\MSSQL\\Backup**

```PowerShell
Dismount-DiskImage $imagePath
```

```PowerShell
cls
```

## # Install Microsoft SQL Server Management Studio

```PowerShell
& '\\ICEMAN\Products\Microsoft\SQL Server 2016\SSMS-Setup-ENU.exe'
```

## Install Fiddler

```PowerShell
cls
```

## # Install Microsoft Message Analyzer

```PowerShell
& "\\ICEMAN\Products\Microsoft\Message Analyzer 1.4\MessageAnalyzer64.msi"
```

```PowerShell
cls
```

## # Install Microsoft Log Parser 2.2

```PowerShell
& "\\ICEMAN\Public\Download\Microsoft\LogParser 2.2\LogParser.msi"
```

```PowerShell
cls
```

## # Install Remote Desktop Connection Manager

```PowerShell
& "\\ICEMAN\Products\Microsoft\Remote Desktop Connection Manager\rdcman.msi"
```

## Install software for HP Photosmart 6515

[http://support.hp.com/us-en/drivers/selfservice/HP-Photosmart-6510-e-All-in-One-Printer-series---B2/5058334/model/5191793](http://support.hp.com/us-en/drivers/selfservice/HP-Photosmart-6510-e-All-in-One-Printer-series---B2/5058334/model/5191793)

## Share printer

![(screenshot)](https://assets.technologytoolbox.com/screenshots/01/2EDCC101189FC9A8E4E5FD9205D12E8EB82B2F01.png)

Click **Change Sharing Options**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/94/39D600ED528C73CAE3772FDA8A9E263E29CBF094.png)

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

```PowerShell
cls
```

### # Create virtual switches

```PowerShell
New-VMSwitch `
    -Name "Production" `
    -NetAdapterName "Production" `
    -AllowManagementOS $true
```

### # Enable jumbo frames on virtual switches

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name "vEthernet (Production)" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

ping ICEMAN -f -l 8900
```

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

## # Configure credential helper for Git

```PowerShell
git config --global credential.helper !"C:\\NotBackedUp\\Public\\Toolbox\\git-credential-winstore.exe"
```

## # Configure e-mail and name for Git

```PowerShell
git config --global user.email "jeremy_jameson@live.com"
git config --global user.name "Jeremy Jameson"
```

## TODO: Other stuff that may need to be done

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

### Install Web Essentials 2015

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

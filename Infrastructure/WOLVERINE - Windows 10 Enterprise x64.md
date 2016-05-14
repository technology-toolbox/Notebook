# WOLVERINE - Windows 10 Enterprise x64

Saturday, December 12, 2015
4:41 AM

## Install Windows 10 Enterprise (x64)

## # Rename computer

```PowerShell
Rename-Computer -NewName WOLVERINE -Restart
```

## # Join domain

```PowerShell
Add-Computer -DomainName corp.technologytoolbox.com -Restart
```

## # Create default folders

> **Important**
>
> Run the following commands using a non-elevated PowerShell window (to avoid issues with customizing the folder icons).

```Console
mkdir C:\NotBackedUp\Public
mkdir C:\NotBackedUp\Temp
```

## # Set time zone

```PowerShell
tzutil /s "Mountain Standard Time"
```

## # Set MaxPatchCacheSize to 0

```PowerShell
reg add HKLM\Software\Policies\Microsoft\Windows\Installer /v MaxPatchCacheSize /t REG_DWORD /d 0 /f
```

```PowerShell
cls
```

## # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

## # Copy Toolbox content

```PowerShell
net use \\ICEMAN\ipc$ /USER:TECHTOOLBOX\jjameson

robocopy \\ICEMAN\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E
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

```PowerShell
cls
```

## # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name "Ethernet 2" `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping ICEMAN -f -l 8900
```

```PowerShell
cls
```

## # Disable proxy auto-detect

### # Disable 'Automatically detect proxy settings' in Internet Explorer

```PowerShell
function Disable-AutomaticallyDetectProxySettings {
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

### Reference

**Disable-AutomaticallyDetectSettings.ps1**\
From <[https://gist.github.com/ReubenBond/1387620](https://gist.github.com/ReubenBond/1387620)>

```PowerShell
cls
```

## # Download PowerShell help files

```PowerShell
Update-Help
```

## # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

## # Configure firewall rules for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
New-NetFirewallRule `
    -Name 'Remote Windows Update (DCOM-In)' `
    -DisplayName 'Remote Windows Update (DCOM-In)' `
    -Description 'Allows remote auditing and installation of Windows updates via POSHPAIG (http://poshpaig.codeplex.com/)' `
    -Group 'Remote Windows Update' `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 135 `
    -Profile Domain `
    -Action Allow

New-NetFirewallRule `
    -Name 'Remote Windows Update (Dynamic RPC)' `
    -DisplayName 'Remote Windows Update (Dynamic RPC)' `
    -Description 'Allows remote auditing and installation of Windows updates via POSHPAIG (http://poshpaig.codeplex.com/)' `
    -Group 'Remote Windows Update' `
    -Program '%windir%\system32\dllhost.exe' `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort RPC `
    -Profile Domain `
    -Action Allow

New-NetFirewallRule `
    -Name 'Remote Windows Update (SMB-In)' `
    -DisplayName 'Remote Windows Update (SMB-In)' `
    -Description 'Allows remote auditing and installation of Windows updates via POSHPAIG (http://poshpaig.codeplex.com/)' `
    -Group 'Remote Windows Update' `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 445 `
    -Profile Domain `
    -Action Allow

New-NetFirewallRule `
    -Name 'Remote Windows Update (WMI-In)' `
    -DisplayName 'Remote Windows Update (WMI-In)' `
    -Description 'Allows remote auditing and installation of Windows updates via POSHPAIG (http://poshpaig.codeplex.com/)' `
    -Group 'Remote Windows Update' `
    -Program "$env:windir\system32\svchost.exe" `
    -Service winmgmt `
    -Direction Inbound `
    -Protocol TCP `
    -Profile Domain `
    -Action Allow

Get-NetFirewallRule |
  Where-Object { `
    $_.Profile -eq 'Domain' `
      -and $_.DisplayName -like 'File and Printer Sharing (Echo Request *-In)' } |
  Enable-NetFirewallRule
```

## # Disable firewall rules for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
Disable-NetFirewallRule -Group 'Remote Windows Update'
```

```PowerShell
cls
```

## # Install Microsoft Money

```PowerShell
& "\\ICEMAN\Products\Microsoft\Money 2008\USMoneyBizSunset.exe"
```

> **Important**
>
> Registry hack for MS Money on Windows 10:
>
> ```INI
> [HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Internet Explorer]
> "Version"="9.11.10240.0"
> ```

### Reference

**Microsoft Money Sunset Version Stopped Working on Windows 10 with Edge, Asks for IE 6.0**\
From <[http://answers.microsoft.com/en-us/insider/forum/insider_internet-insider_ie/microsoft-money-sunset-version-stopped-working-on/052c7b34-08d6-4017-a602-97e113063a33?auth=1](http://answers.microsoft.com/en-us/insider/forum/insider_internet-insider_ie/microsoft-money-sunset-version-stopped-working-on/052c7b34-08d6-4017-a602-97e113063a33?auth=1)>

### Create custom invoice template

Folder - C:\\Users\\All Users\\Microsoft\\Money\\17.0\\Invoice

Move "Technology Toolbox" invoice to top of list (2008Invoice.ntd) so it is selected by default

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

## Install Microsoft Visio Professional 2016

```PowerShell
cls
```

## # Install Adobe Reader 8.3

```PowerShell
& "\\ICEMAN\Products\Adobe\AdbeRdr830_en_US.msi"

& "\\ICEMAN\Products\Adobe\AdbeRdrUpd831_all_incr.msp"
```

```PowerShell
cls
```

## # Install Mozilla Firefox 42.0

```PowerShell
& "\\ICEMAN\Products\Mozilla\Firefox\Firefox Setup 42.0.exe" -ms
```

```PowerShell
cls
```

## # Install Google Chrome

```PowerShell
& "\\ICEMAN\Products\Google\Chrome\ChromeStandaloneSetup64.exe"
```

## Install FileZilla 3.14.1

## Install Paint.NET 4.0.6

## Install Microsoft Expression Studio 4

## Install Microsoft SQL Server 2014

#### # Install .NET Framework 3.5

```PowerShell
$sourcePath = "G:\sources\sxs"

Enable-WindowsOptionalFeature -FeatureName NetFx3 -Source $sourcePath -Online
```

#### # Create folders for Distributed Replay Client

mkdir "C:\\NotBackedUp\\Microsoft SQL Server\\DReplayClient\\WorkingDir"\
mkdir "C:\\NotBackedUp\\Microsoft SQL Server\\DReplayClient\\ResultDir"

### Install SQL Server

- Select all features
- Change Startup Type on all services to Manual except SQL Server Browser (leave Disabled)
- Add TECHTOOLBOX\\SQL Server Admins (DEV) to the list of SQL Server administrators
- Set Data root directory to "C:\\NotBackedUp\\Microsoft SQL Server"
- On **Reporting Service Configuration** step, for **Reporting Services Native Mode**, select **Install only**.
- For Distributed Replay Client, change paths to "C:\\NotBackedUp\\Microsoft SQL Server\\..."

## Install Microsoft Visual Studio 2015 Enterprise with Update 1

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9A/ACDA391F5D951BCC223707F0D0AF2DF01F6ED49A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/69/3D184DB58FB449B09BA3A8C96808BE56AFE0AC69.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BD/7DA9EE2C35C29A126B4BAA3835DB28DC7EF69ABD.png)

Select the following features:

- Windows and Web Development
  - **Microsoft Office Developer Tools**
  - **Microsoft Web Developer Tools**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/83/92B19D856F2778744C00F8799038082A88EB9D83.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EC/7BEC5B0BCF7DD4693FB012016FFC95B9ADFC9FEC.png)

## Install Chutzpah Test Adapter

1. Open Visual Studio.
2. In the **Tools** menu, click **Extensions and Updates...**
3. In the **Extensions and Updates** dialog window:
   1. Select the **Online** pane.
   2. In the search box, type **Chutzpah**.
   3. In the list of items, select **Chutzpah Test Adapter for the Test Explorer**, and click **Download**.
   4. Review the license terms, and click **Install**.
   5. Wait for the extension to be installed.
   6. Click **Restart Now**.

## Install Chutzpah Test Runner

1. Open Visual Studio.
2. In the **Tools** menu, click **Extensions and Updates...**
3. In the **Extensions and Updates** dialog window:
   1. Select the **Online** pane.
   2. In the search box, type **Chutzpah**.
   3. In the list of items, select **Chutzpah Test Runner Context Menu Extension**, and click **Download**.
   4. Review the license terms, and click **Install**.
   5. Wait for the extension to be installled.
   6. Click **Restart Now**.

```PowerShell
cls
```

## # Install reference assemblies

```PowerShell
net use \\ICEMAN\ipc$ /USER:TECHTOOLBOX\jjameson

robocopy `
    '\\ICEMAN\Builds\Reference Assemblies' `
    'C:\Program Files\Reference Assemblies' /E

& 'C:\Program Files\Reference Assemblies\Microsoft\SharePoint v4\AssemblyFoldersEx - x64.reg'
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/62/DE96621F16BC51A75B6410BE1B94F33F9B8A0F62.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5E/06DBAE68F16F7F83442A5F1916BFBEFEFC0DD15E.png)

```PowerShell
& 'C:\Program Files\Reference Assemblies\Microsoft\SharePoint v5\AssemblyFoldersEx - x64.reg'
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AE/E9FD2601E62121DA76E1227B4436C7ED8F069CAE.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BB/9A7DF5FF756E44DAC0D8F600AA2D457598370EBB.png)

```PowerShell
cls
```

## # Configure symbol path for debugging

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

& "\\ICEMAN\Products\Python\python-2.7.10.amd64.msi"
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
& \\ICEMAN\Products\Git\Git-2.5.3-64-bit.exe
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
# & \\ICEMAN\Products\node.js\node-v0.12.5-x64.msi

& \\ICEMAN\Products\node.js\node-v4.1.1-x64.msi
```

> **Important**
>
> Restart PowerShell for change to PATH environment variable to take effect.

### # Change NPM file locations to avoid issues with redirected folders

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

notepad "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\Extensions\Microsoft\Web Tools\External\node\etc\npmrc"
```

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

& "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\Extensions\Microsoft\Web Tools\External\npm.cmd" config set -g cache "$env:ALLUSERSPROFILE\npm-cache"
```

#### Reference

**How to use npm with node.exe?**\
http://stackoverflow.com/a/9366416

```PowerShell
cls
```

## # Install global NPM packages

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

## # Configure npm locations for TECHTOOLBOX\\jjameson account

---

**runas /USER:TECHTOOLBOX\\jjameson PowerShell.exe**

```PowerShell
npm config --global set prefix "$env:ALLUSERSPROFILE\npm"

npm config --global set cache "$env:ALLUSERSPROFILE\npm-cache"

& "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\Extensions\Microsoft\Web Tools\External\npm.cmd" config set cache '${LOCALAPPDATA}\npm-cache'
```

---

## "Upgrade NPM" version in Visual Studio 2015

### Before

![(screenshot)](https://assets.technologytoolbox.com/screenshots/65/16ED937A4EC8A4D914E16BDF0D7F6EC115CC2965.png)

### After

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9F/FD14463E819276232A1137CA4609DAE9E4FDB99F.png)

### Reference

**Upgrading NPM in Visual Studio 2015**\
From <[http://jameschambers.com/2015/09/upgrading-npm-in-visual-studio-2015/](http://jameschambers.com/2015/09/upgrading-npm-in-visual-studio-2015/)>

## Install GitHub Desktop

[https://desktop.github.com/](https://desktop.github.com/)

```PowerShell
cls
```

## # Install Microsoft Azure PowerShell

```PowerShell
& "\\ICEMAN\Products\Microsoft\Azure\azure-powershell.1.0.1.msi"
```

```PowerShell
cls
```

## # Install Microsoft Message Analyzer

```PowerShell
& "\\ICEMAN\Products\Microsoft\Message Analyzer 1.3\MessageAnalyzer64.msi"
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

& "C:\\Users\\foo\\Downloads\\Remote Desktop Connection Manager 2.2\\RDCMan.msi"

## # Install Fiddler

## Install software for HP Photosmart 6515

[http://support.hp.com/us-en/drivers/selfservice/HP-Photosmart-6510-e-All-in-One-Printer-series---B2/5058334/model/5191793](http://support.hp.com/us-en/drivers/selfservice/HP-Photosmart-6510-e-All-in-One-Printer-series---B2/5058334/model/5191793)

## Share printer

![(screenshot)](https://assets.technologytoolbox.com/screenshots/01/2EDCC101189FC9A8E4E5FD9205D12E8EB82B2F01.png)

Click **Change Sharing Options**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/94/39D600ED528C73CAE3772FDA8A9E263E29CBF094.png)

## Enable Hyper-V

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

## # Delete C:\\Windows\\SoftwareDistribution folder (4.7 GB)

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

## Install Android SDK (for debugging Chrome on Samsung Galaxy)

### Reference

[http://stackoverflow.com/a/24410867](http://stackoverflow.com/a/24410867)

### Install Samsung USB driver

### Install Java SE Development Kit 8u66

[http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html](http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html)

### Install Android "SDK Tools Only"

[http://developer.android.com/sdk/index.html#Other](http://developer.android.com/sdk/index.html#Other)

### Install Android SDK Platform-tools

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1E/75601D9C9EF795A16D815FE580D6571F20B23C1E.png)

### Detect devices

cd C:\\Program Files (x86)\\Android\\android-sdk\\platform-tools

adb.exe devices

## TODO: Other stuff that may need to be done

Apple iTunes

Virtual Account Numbers

Sandcastle Documentation Compiler Tools\
Sandcastle Help File Builder

MSBuild Community Tasks

## # Install ASP.NET ViewState Helper 2.0.1

## Install Inkscape 0.48

## Install Web Essentials 2015

## # Clone repository - Training

```PowerShell
mkdir src\Repos

cd src\Repos

git clone https://techtoolbox.visualstudio.com/DefaultCollection/_git/Training
```

## # Install ng-demos

### # Install package dependencies

```PowerShell
npm install -g node-inspector
```

### # Clone repo

```PowerShell
cd Training

git clone https://github.com/johnpapa/ng-demos.git
```

### # Install packages

```PowerShell
cd ng-demos\modular

npm install
```

### # Run dev build

```PowerShell
gulp serve-dev-debug
```

# WOLVERINE - Windows 10 Enterprise x64

Friday, July 31, 2015
3:00 PM

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

## # Copy Toolbox content

```PowerShell
net use \\iceman\ipc$ /USER:TECHTOOLBOX\jjameson

robocopy \\iceman\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E
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

## # Download PowerShell help files

```PowerShell
Update-Help
```

## Install Microsoft Office Professional Plus 2013 with Service Pack 1

## Install Microsoft SharePoint Designer 2013 with Service Pack 1

## Install Microsoft Visio Professional 2013 with Service Pack 1

```PowerShell
cls
```

## # Install Adobe Reader 8.3

```PowerShell
& "\\iceman\Products\Adobe\AdbeRdr830_en_US.msi"

& "\\iceman\Products\Adobe\AdbeRdrUpd831_all_incr.msp"
```

```PowerShell
cls
```

## # Install Mozilla Firefox 39.0

```PowerShell
& "\\ICEMAN\Products\Mozilla\Firefox\Firefox Setup 39.0.exe" -ms
```

```PowerShell
cls
```

## # Install Google Chrome

```PowerShell
& "\\ICEMAN\Products\Google\Chrome\ChromeStandaloneSetup64.exe"
```

## Install FileZilla 3.12.0.2

## Install Paint.NET 4.0.3

## Install Microsoft Money

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

1. Open DLL in hex editor:"C:\\Program Files (x86)\\Microsoft Money Plus\\MNYCoreFiles\\mnyob99.dll"
2. Make the following changes:

    File offset **003FACE8**: Change **85** to **8D**\
    File offset **003FACED**: Change **50** to **51**\
    File offset **003FACF0**: Change **FF** to **85**\
    File offset **003FACF6**: Change **E8** to **B9**

#### Reference

**Microsoft Money crashes during import of account transactions or when changing a payee of a downloaded transaction**\
From <[http://blogs.msdn.com/b/oldnewthing/archive/2012/11/13/10367904.aspx](http://blogs.msdn.com/b/oldnewthing/archive/2012/11/13/10367904.aspx)>

## Install Oracle VM VirtualBox

## Install Microsoft Expression Studio 4

## Install Microsoft SQL Server 2014

#### # Install .NET Framework 3.5

```PowerShell
$sourcePath = "X:\sources\sxs"

Enable-WindowsOptionalFeature -FeatureName NetFx3 -Source $sourcePath -Online
```

### Install SQL Server

- Change Startup Type on all services to Manual
- Add TECHTOOLBOX\\SQL Server Admins (DEV) to the list of SQL Server administrators
- Set Data root directory to "C:\\NotBackedUp\\Microsoft SQL Server"
- For Distributed Replay Client, change paths to "C:\\NotBackedUp\\Microsoft SQL Server\\..."

## Install Microsoft Visual Studio 2015 Enterprise

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4D/CB8D2970754D88629E3E6D51F1E4BDCAB8A0FD4D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/93/FECD5CD3DB25CEF8B7E376A92F71B45AC6C4EC93.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/30/6AB2199E908EAA655850B6D365791212FCDD3130.png)

Select the following features:

- Windows and Web Development
  - **Microsoft Office Developer Tools**
  - **Microsoft Web Developer Tools**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CA/65B2F28CB988A0CF60367E1CCF3606394A8CDFCA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4B/7F1B8CBAB3901BD011BBE30EE4C900CEC7D40D4B.png)

## Install Chutzpah Test Adapter

1. Open Visual Studio.
2. In the **Tools** menu, click **Extensions and Updates...**
3. In the **Extensions and Updates** dialog window:
   1. Select the **Online** pane.
   2. In the search box, type **Chutzpah**.
   3. In the list of items, select **Chutzpah Test Adapter for the Test Explorer**, and click **Download**.
   4. Review the license terms, and click **Install**.
   5. Wait for the extension to be installled.
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

## # Install reference assemblies

```PowerShell
robocopy `
    '\\ICEMAN\Public\Reference Assemblies' `
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

## # Configure symbol path for debugging

```PowerShell
setx _NT_SYMBOL_PATH SRV*C:\NotBackedUp\Public\Symbols*\\ICEMAN\Public\Symbols*http://msdl.microsoft.com/download/symbols /M
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

## # Install Git (required by npm to download packages from GitHub)

### # Install Git (using default options)

```PowerShell
& "\\ICEMAN\Products\Git\Git-1.9.5-preview20150319.exe"
```

### # Add Git folder to PATH environment variable

```PowerShell
$gitPathFolder = 'C:\Program Files (x86)\Git\cmd'

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
& \\ICEMAN\Products\node.js\node-v0.12.5-x64.msi
```

> **Important**
>
> Restart PowerShell for change to PATH environment variable to take effect.

### # Change NPM file locations to avoid issues with redirected folders

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

#### Reference

**npm on windows, install with -g flag should go into appdata/local rather than current appdata/roaming?**\
From <[https://github.com/npm/npm/issues/4564](https://github.com/npm/npm/issues/4564)>

**`npm install -g bower` goes into infinite loop on windows with %appdata% being a UNC path**\
From <[https://github.com/npm/npm/issues/8814](https://github.com/npm/npm/issues/8814)>

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

#### Reference

**How to use npm with node.exe?**\
http://stackoverflow.com/a/9366416

### # Configure NPM to use HTTP instead of HTTPS

```PowerShell
npm config --global set registry http://registry.npmjs.org/
```

#### Reference

**npm not working - "read ECONNRESET"**\
From <[http://stackoverflow.com/questions/18419144/npm-not-working-read-econnreset](http://stackoverflow.com/questions/18419144/npm-not-working-read-econnreset)>

```PowerShell
cls
```

## # Install Yeoman and other global NPM packages

### Reference

**Install the Yeoman toolset**\
From <[http://yeoman.io/codelab/setup.html](http://yeoman.io/codelab/setup.html)>

### # Install Grunt CLI

```PowerShell
npm install --global grunt-cli
```

### # Install Gulp

```PowerShell
npm install --global gulp
```

### # Install Bower

```PowerShell
npm install --global bower
```

### # Install Karma CLI

```PowerShell
npm install --global karma-cli
```

### # Install Yeoman

```PowerShell
npm install --global yo
```

### # Install Yeoman generators

```PowerShell
npm install --global generator-karma

npm install --global generator-angular
```

### # Install rimraf

```PowerShell
npm install --global rimraf
```

```PowerShell
cls
```

## # Configure NPM for TECHTOOLBOX\\jjameson account

---

```Console
runas /USER:TECHTOOLBOX\jjameson PowerShell.exe
```

### # Set NPM "global" locations to shared location for all users

```PowerShell
npm config --global set prefix "$env:LOCALAPPDATA\npm"

npm config --global set cache "$env:LOCALAPPDATA\npm-cache"
```

### # Configure NPM to use HTTP instead of HTTPS

```PowerShell
npm config --global set registry http://registry.npmjs.org/
```

---

### Reference

**npm not working - "read ECONNRESET"**\
From <[http://stackoverflow.com/questions/18419144/npm-not-working-read-econnreset](http://stackoverflow.com/questions/18419144/npm-not-working-read-econnreset)>

## # Install ASP.NET ViewState Helper 2.0.1

## # Install Microsoft Message Analyzer

## # Install Microsoft Log Parser 2.2

## # Install Fiddler

## Install Remote Desktop Connection Manager

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

## # Delete C:\\Windows\\SoftwareDistribution folder (3.5 GB)

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse
```

## Disk Cleanup

## Enable Hyper-V

**Note:** Even after enabling Intel Virtualization Technology and DEP in BIOS (and rebooting/restarting numerous times), Windows 10 would not allow the Hyper-V role to be enabled.

Here's what finally did the trick:

```Console
bcdedit /set hypervisorlaunchtype auto
```

### Reference

**Hyper-V won't enable in Windows 8 Pro: "Virtualization support is disabled in the firmware"**\
From <[http://superuser.com/questions/530379/hyper-v-wont-enable-in-windows-8-pro-virtualization-support-is-disabled-in-th](http://superuser.com/questions/530379/hyper-v-wont-enable-in-windows-8-pro-virtualization-support-is-disabled-in-th)>

## Share printer

![(screenshot)](https://assets.technologytoolbox.com/screenshots/01/2EDCC101189FC9A8E4E5FD9205D12E8EB82B2F01.png)

Click **Change Sharing Options**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/94/39D600ED528C73CAE3772FDA8A9E263E29CBF094.png)

## # Configure credential helper for Git

```PowerShell
git config --global credential.helper !"C:\\NotBackedUp\\Public\\Toolbox\\git-credential-winstore.exe"
```

## # Configure e-mail and name for Git

```PowerShell
git config --global user.email "jeremy_jameson@live.com"
git config --global user.name "Jeremy Jameson"
```

## Install GitHub Desktop

[https://desktop.github.com/](https://desktop.github.com/)

## # Install Microsoft Azure PowerShell

```PowerShell
& \\iceman\Products\Microsoft\Azure\azure-powershell.0.9.6.msi
```

## # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

## # Configure firewall rules for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
Get-NetFirewallRule |
    Where-Object { $_.Profile -eq 'Domain' `
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
Disable-NetFirewallRule -Name 'Remote Windows Update (Dynamic RPC)'
```

## TODO: Other stuff that may need to be done

Apple iTunes

Virtual Account Numbers

Sandcastle Documentation Compiler Tools\
Sandcastle Help File Builder

MSBuild Community Tasks

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

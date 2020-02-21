# WIN8-DEV2

Friday, July 24, 2015
2:48 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Create VM

- Processors: **4**
- Memory: **8192 MB**
- VDI size: **50 GB**

## Configure VM settings

- General
  - Advanced
    - Shared Clipboard:** Bidirectional**
- Network
  - Adapter 1
    - Attached to:** Bridged adapter**

## Install custom Windows 8.1 image

- Start-up disk: [\\\\ICEMAN\\Products\\Microsoft\\MDT-Deploy-x86.iso](\\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso)
- On the **Task Sequence** step, select **Windows 8 Enterprise (x64)** and click **Next**.
- On the **Computer Details** step, in the **Computer name** box, type **WIN8-DEV2** and click **Next**.
- On the Applications step:
  - Select the following items:
    - Adobe
      - **Adobe Reader 8.3.1**
    - Google
      - **Chrome**
    - Mozilla
      - **Firefox 36.0**
      - **Thunderbird 31.3.0**
  - Click **Next**.

## Install VirtualBox Guest Additions

```PowerShell
cls
```

## # Set password for local Administrator account

```PowerShell
$adminUser = [ADSI] "WinNT://./Administrator,User"
$adminUser.SetPassword("{password}")

cls
# Set MaxPatchCacheSize to 0

reg add HKLM\Software\Policies\Microsoft\Windows\Installer /v MaxPatchCacheSize /t REG_DWORD /d 0 /f
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

## # Copy Toolbox content

```PowerShell
net use \\iceman\ipc$ /USER:TECHTOOLBOX\jjameson

robocopy \\iceman\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E
```

## Reduce paging file size

Configure **Virtual Memory**

- **Automatically manage paging file size for all drives: No**
- **C: drive**
  - **Custom size**
  - **Initial size (MB): 512**
  - **Maximum size (MB): 1024**

## Install Microsoft Visual Studio 2015

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
& \\ICEMAN\Products\node.js\node-v0.12.7-x64.msi
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
[http://stackoverflow.com/a/9366416](http://stackoverflow.com/a/9366416)

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

1. Start Word 2013
2. Enter product key

## Install updates using Windows Update

**Note:** Repeat until there are no updates available for the computer.

```PowerShell
cls
```

## # Delete C:\\Windows\\SoftwareDistribution folder

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse
```

## Disk Cleanup

```PowerShell
cls
```

## # Shutdown VM

```PowerShell
Stop-Computer
```

## Remove disk from virtual CD/DVD drive

## # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

## # Configure firewall rule for [http://poshpaig.codeplex.com/](POSHPAIG)

## # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

## # Configure firewall rule for [http://poshpaig.codeplex.com/](POSHPAIG)

---

**FOOBAR8**

```PowerShell
$computer = 'WIN8-DEV2'

$command = "Get-NetFirewallRule |
    Where-Object { `$_.Profile -eq 'Domain' ``
        -and `$_.DisplayName -like 'File and Printer Sharing (Echo Request *-In)' } |
    Enable-NetFirewallRule"

$scriptBlock = [ScriptBlock]::Create($command)

Invoke-Command -ComputerName $computer -ScriptBlock $scriptBlock

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

$scriptBlock = [scriptblock]::Create($command)

Invoke-Command -ComputerName $computer -ScriptBlock $scriptBlock
```

---

## # Disable firewall rule for [http://poshpaig.codeplex.com/](POSHPAIG)

---

**FOOBAR8**

```PowerShell
$computer = 'WIN8-DEV2'

$command = "Disable-NetFirewallRule ``
    -DisplayName 'Remote Windows Update (Dynamic RPC)'"

$scriptBlock = [scriptblock]::Create($command)

Invoke-Command -ComputerName $computer -ScriptBlock $scriptBlock
```

---

## Snapshot VM - "Baseline"

Windows 8.1 Enterprise (x64)\
Microsoft Office Professional Plus 2013 (x86)\
Adobe Reader 8.3.1\
Google Chrome\
Mozilla Firefox 36.0\
Mozilla Thunderbird 31.3.0\
Microsoft Visual Studio 2015\
Python 2.7.10
Git 1.9.5\
Node.js v0.12.5

## Configure NPM to use HTTP instead of HTTPS

### Reference

**npm not working - "read ECONNRESET"**\
From <[http://stackoverflow.com/questions/18419144/npm-not-working-read-econnreset](http://stackoverflow.com/questions/18419144/npm-not-working-read-econnreset)>

```Console
npm config set registry http://registry.npmjs.org/
```

```Console
cls
```

## # Install global NPM packages

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

**TODO:**

## Install Web Essentials 2015

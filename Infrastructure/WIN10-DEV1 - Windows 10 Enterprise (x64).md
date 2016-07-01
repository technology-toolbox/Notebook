# WIN10-DEV1 - Windows 10 Enterprise (x64)

Friday, July 1, 2016
4:07 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

---

**WOLVERINE**

### # Create virtual machine

```PowerShell
$vmName = "WIN10-DEV1"

$vmPath = "C:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -Name $vmName `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 50GB `
    -MemoryStartupBytes 4GB `
    -SwitchName "Production"

Set-VM `
    -VMName $vmName `
    -ProcessorCount 4

$isoPath = ("\\ICEMAN\Products\Microsoft\Windows 10\" `
    + "en_windows_10_enterprise_version_1511_updated_apr_2016_x64_dvd_8711771.iso")

Set-VMDvdDrive `
    -VMName $vmName `
    -Path $isoPath

Start-VM -Name $vmName
```

---

## Install Windows 10 Enterprise (x64)

## # Create default folders

```PowerShell
mkdir C:\NotBackedUp\Public
mkdir C:\NotBackedUp\Temp
```

## # Set time zone

```PowerShell
tzutil /s "Mountain Standard Time"
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

## # Copy Toolbox content

```PowerShell
net use \\iceman\ipc$ /USER:TECHTOOLBOX\jjameson

robocopy \\iceman\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E
```

## # Rename computer

```PowerShell
Rename-Computer -NewName WIN10-DEV1 -Restart
```

```PowerShell
cls
```

### # Join domain

```PowerShell
Add-Computer `
    -DomainName corp.technologytoolbox.com `
    -Credential (Get-Credential TECHTOOLBOX\jjameson-admin) `
    -Restart
```

### # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

### # Configure firewall rules for POSHPAIG (http://poshpaig.codeplex.com/)

Set-ExecutionPolicy RemoteSigned -Scope Process -Force

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Enable-RemoteWindowsUpdate.ps1 -Verbose
```

### # Disable firewall rules for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Disable-RemoteWindowsUpdate.ps1 -Verbose
```

### # Set MaxPatchCacheSize to 0 (Recommended)

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

### Install latest service pack and updates

## Disable proxy auto-detect

### Reference

**Disable-AutomaticallyDetectSettings.ps1**\
From <[https://gist.github.com/ReubenBond/1387620](https://gist.github.com/ReubenBond/1387620)>

```PowerShell
# Disable 'Automatically detect proxy settings' in Internet Explorer.
function Disable-AutomaticallyDetectProxySettings
{
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

## # Download PowerShell help files

```PowerShell
Update-Help
```

## TODO: Reduce paging file size

**Virtual Memory**

- **Automatically manage paging file size for all drives: No**
- **C: drive**
  - **Custom size**
  - **Initial size (MB): 512**
  - **Maximum size (MB): 1024**

## Install Microsoft Visual Studio 2015 Enterprise

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

## # Install Node.js

```PowerShell
& \\ICEMAN\Products\node.js\node-v0.12.5-x64.msi
```

> **Important**
>
> Restart PowerShell for change to PATH environment variable to take effect.

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

## # Install Mozilla Firefox

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

## # Delete C:\\Windows\\SoftwareDistribution folder (314 MB)

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

## # Configure firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

---

**FOOBAR8**

```PowerShell
$computer = 'WIN10-DEV1'

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

## # Disable firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

---

**FOOBAR8**

```PowerShell
$computer = 'WIN10-DEV1'

$command = "Disable-NetFirewallRule ``
    -DisplayName 'Remote Windows Update (Dynamic RPC)'"

$scriptBlock = [scriptblock]::Create($command)

Invoke-Command -ComputerName $computer -ScriptBlock $scriptBlock
```

---

## Snapshot VM - "Baseline"

Windows 10 Enterprise (x64)\
Microsoft Visual Studio 2015 Enterprise\
Python 2.7.10
Git 1.9.5\
Node.js v0.12.5\
Adobe Reader 8.3.1\
Google Chrome\
Mozilla Firefox 39.0

**TODO:**

## Install Web Essentials 2015

## Configure NPM to use HTTP instead of HTTPS

### Reference

**npm not working - "read ECONNRESET"**\
From <[http://stackoverflow.com/questions/18419144/npm-not-working-read-econnreset](http://stackoverflow.com/questions/18419144/npm-not-working-read-econnreset)>

```Console
npm config set registry http://registry.npmjs.org/
```

## Install Yeoman

### Reference

**Install the Yeoman toolset**\
From <[http://yeoman.io/codelab/setup.html](http://yeoman.io/codelab/setup.html)>

```PowerShell
cls
```

### # Install Grunt CLI

```PowerShell
npm install -g grunt-cli
```

### # Install Gulp

```PowerShell
npm install -g gulp
```

### # Install Bower

```PowerShell
npm install -g bower
```

### # Install Yeoman

```PowerShell
npm install -g yo
```

## # Install AngularJS generator

```PowerShell
npm install -g generator-angular
```

## # Configure credential helper for Git

```PowerShell
git config --global credential.helper !"C:\\NotBackedUp\\Public\\Toolbox\\git-credential-winstore.exe"
```

## # Configure e-mail and name for Git

```PowerShell
git config --global user.email "jeremy_jameson@live.com"
git config --global user.name "Jeremy Jameson"
```

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

## Install custom Windows 7 image

- Start-up disk: [\\\\ICEMAN\\Products\\Microsoft\\MDT-Deploy-x86.iso](\\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso)
- On the **Task Sequence** step, select **Windows 7 Ultimate (x86)** and click **Next**.
- On the **Computer Details** step, in the **Computer name** box, type **WIN7-TEST1** and click **Next**.
- On the Applications step:
  - Select the following items:
    - Adobe
      - **Adobe Reader 8.3.1**
    - Google
      - **Chrome**
    - Mozilla
      - **Firefox 45.0.1**
      - **Thunderbird 38.7.0**
  - Click **Next**.

```PowerShell
cls
```

## # Rename local Administrator account and set password

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

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

## # Remove disk from virtual CD/DVD drive

```PowerShell
$vmHost = "STORM"
$vmName = "WIN7-TEST1"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

---

## Login as WIN7-TEST1\\foo

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

## # Configure firewall rules for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
netsh advfirewall firewall set rule `
    name="File and Printer Sharing (Echo Request - ICMPv4-In)" profile=domain `
    new enable=yes

netsh advfirewall firewall set rule `
    name="File and Printer Sharing (Echo Request - ICMPv6-In)" profile=domain `
    new enable=yes

netsh advfirewall firewall add rule `
    name="Remote Windows Update (Dynamic RPC)" `
    description="Allows remote auditing and installation of Windows updates via POSHPAIG (http://poshpaig.codeplex.com/)" `
    program="%windir%\system32\dllhost.exe" `
    dir=in `
    protocol=TCP `
    localport=RPC `
    profile=Domain `
    action=Allow

netsh advfirewall firewall add rule `
    name="Remote Windows Update (SMB-In)" `
    description="Allows remote auditing and installation of Windows updates via POSHPAIG (http://poshpaig.codeplex.com/)" `
    dir=in `
    protocol=TCP `
    localport=445 `
    profile=Domain `
    action=Allow

netsh advfirewall firewall add rule `
    name="Remote Windows Update (WMI-In)" `
    description="Allows remote auditing and installation of Windows updates via POSHPAIG (http://poshpaig.codeplex.com/)" `
    program="%windir%\system32\svchost.exe" `
    service=winmgmt `
    dir=in `
    protocol=TCP `
    profile=Domain `
    action=Allow
```

## # Disable firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
netsh advfirewall firewall set rule `
    name="Remote Windows Update (Dynamic RPC)" new enable=no

netsh advfirewall firewall set rule `
    name="Remote Windows Update (SMB-In)" new enable=no

netsh advfirewall firewall set rule `
    name="Remote Windows Update (WMI-In)" new enable=no
```

```PowerShell
cls
```

## # Install Remote Server Administration Tools for Windows 7 SP1

```PowerShell
net use \\ICEMAN\ipc$ /USER:TECHTOOLBOX\jjameson

& '\\ICEMAN\Public\Download\Microsoft\Remote Server Administration Tools for Windows 7 SP1\Windows6.1-KB958830-x86-RefreshPkg.msu'
```

## Enable feature to add "netdom" command-line tool

- **Remote Server Administration Tools**
  - **AD DS and AD LDA Tools**
    - **AD DS Tools**
      - **AD DS Snap-ins and Command-line Tools**

```PowerShell
cls
```

## # Install Microsoft Security Essentials

```PowerShell
& "\\ICEMAN\Products\Microsoft\Security Essentials\Windows 7 (x86)\MSEInstall.exe"
```

## Install updates using Windows Update

> **Note**
>
> Repeat until there are no updates available for the computer.

```PowerShell
cls
```

## # Delete C:\\Windows\\SoftwareDistribution folder

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse
```

```PowerShell
cls
```

## # Enter a product key and activate Windows

```PowerShell
slmgr /ipk {product key}
```

> **Note**
>
> When notified that the product key was set successfully, click **OK**.

```Console
slmgr /ato
```

## Activate Microsoft Office

1. Start Word 2013
2. Enter product key

```PowerShell
cls
```

## # Shutdown VM

```PowerShell
Stop-Computer
```

## Snapshot VM - "Baseline"

Windows 7 Ultimate (x86)\
Microsoft Office Professional Plus 2013 (x86)\
Adobe Reader 8.3.1\
Google Chrome\
Mozilla Firefox 45.0.1\
Mozilla Thunderbird 38.7.0\
Remote Server Administration Tools for Windows 7 SP1\
Microsoft Security Essentials\
Internet Explorer 10

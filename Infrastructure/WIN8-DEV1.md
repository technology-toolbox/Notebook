# WIN8-DEV1

Friday, July 24, 2015\
2:29 PM

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

- Start-up disk: [\\\\ICEMAN\\Products\\Microsoft\\MDT-Deploy-x86.iso](\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso)
- On the **Task Sequence** step, select **Windows 8 Enterprise (x64)** and click **Next**.
- On the **Computer Details** step, in the **Computer name** box, type **WIN8-DEV1** and click **Next**.
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

## Install Microsoft Visual Studio 2013 Ultimate with Update 5

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

## # Delete C:\\Windows\\SoftwareDistribution folder (338 MB)

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

## # Configure firewall rules for [http://poshpaig.codeplex.com/](POSHPAIG)

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

Enable-NetFirewallRule `
    -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)"

Enable-NetFirewallRule `
    -DisplayName "File and Printer Sharing (Echo Request - ICMPv6-In)"
```

## # Disable firewall rules for [http://poshpaig.codeplex.com/](POSHPAIG)

```PowerShell
Disable-NetFirewallRule -Group 'Remote Windows Update'
```

## Snapshot VM - "Baseline"

Windows 8.1 Enterprise (x64)\
Microsoft Office Professional Plus 2013 (x86)\
Adobe Reader 8.3.1\
Google Chrome\
Mozilla Firefox 36.0\
Mozilla Thunderbird 31.3.0\
Microsoft Visual Studio 2013 with Update 5\
Python 2.7.10 Git 1.9.5\
Node.js v0.12.5

**TODO:**

## Install Web Essentials 2013

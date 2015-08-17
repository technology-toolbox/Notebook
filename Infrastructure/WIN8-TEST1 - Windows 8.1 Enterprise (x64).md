# WIN8-TEST1 - Windows 8.1 Enterprise (x64)

Monday, April 20, 2015
3:47 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Create VM

- Processors: **2**
- Memory: **2048 MB**
- VDI size: **25 GB**

## Configure VM settings

- General
  - Advanced
    - Shared Clipboard:** Bidirectional**
- System
  - Processor
    - Enable PAE/NX: **Yes (checked)**
- Network
  - Adapter 1
    - Attached to:** Bridged adapter**

## Install custom Windows 8.1 image

- Start-up disk: [\\\\ICEMAN\\Products\\Microsoft\\MDT-Deploy-x86.iso](\\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso)
- On the **Task Sequence** step, select **Windows 8.1 Enterprise (x64)** and click **Next**.
- On the **Computer Details** step, in the **Computer name** box, type **WIN8-TEST1** and click **Next**.
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

## # Set password for local Administrator account

```PowerShell
$adminUser = [ADSI] "WinNT://./Administrator,User"
$adminUser.SetPassword("{password}")
```

```PowerShell
cls
```

## # Install Remote Server Administration Tools for Windows 8.1

```PowerShell
net use \\ICEMAN\ipc$ /USER:TECHTOOLBOX\jjameson

& '\\ICEMAN\Public\Download\Microsoft\Remote Server Administration Tools for Windows 8.1\Windows8.1-KB2693643-x64.msu'
```

```PowerShell
cls
```

## # Turn on Hyper-V Management Tools

```PowerShell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Tools-All

Enable-WindowsOptionalFeature : One or several parent features are disabled so current
feature can not be enabled.
At line:1 char:1
+ Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Tools-All
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [Enable-WindowsOptionalFeature], COMException
    + FullyQualifiedErrorId : Microsoft.Dism.Commands.EnableWindowsOptionalFeatureCommand
```

**Workaround:**

1. Open the **Start** menu and search for **Turn Windows features on or off**.
2. In the **Windows Features** dialog, expand **Hyper-V** and then select **Hyper-V Management Tools** and click **OK**.

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

## # Delete C:\\Windows\\SoftwareDistribution folder (1.8 GB)

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse
```

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
$computer = 'WIN8-TEST1'

$command = "Get-NetFirewallRule |
    Where-Object { `$_.Profile -eq 'Domain' ``
        -and `$_.DisplayName -like 'File and Printer Sharing (Echo Request *-In)' } |
    Enable-NetFirewallRule"

$scriptBlock = [scriptblock]::Create($command)

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
$computer = 'WIN8-TEST1'

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
Remote Server Administration Tools for Windows 8.1\
Hyper-V Management Tools enabled

**TODO:**

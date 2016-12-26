# WIN8-TEST1 - Windows 8.1 Enterprise (x64)

Monday, December 26, 2016
5:43 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

### # Create virtual machine (WIN8-TEST1)

```PowerShell
$vmHost = "FORGE"
$vmName = "WIN8-TEST1"

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path C:\NotBackedUp\VMs `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 2GB `
    -SwitchName "Production"

Set-VM `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ProcessorCount 2 `
    -DynamicMemory `
    -MemoryMinimumBytes 256MB `
    -MemoryMaximumBytes 4GB

Set-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path \\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso

Start-VM -ComputerName $vmHost -Name $vmName
```

---

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
      - **Firefox 45.0.1**
      - **Thunderbird 38.7.0**
  - Click **Next**.

#### # Copy latest Toolbox content

```PowerShell
net use \\ICEMAN\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```Console
robocopy \\ICEMAN\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E /MIR
```

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

#### Login as WIN8-TEST1\\foo

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

## # Remove disk from virtual CD/DVD drive

```PowerShell
Set-VMDvdDrive -ComputerName FORGE -VMName WIN8-TEST1 -Path $null
```

---

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

```PowerShell
cls
```

## # Install Remote Server Administration Tools for Windows 8.1

```PowerShell
net use \\ICEMAN\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
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

> **Note**
>
> When notified that the product key was set successfully, click **OK**.

```Console
slmgr /ato
```

## Activate Microsoft Office

1. Start Word 2013
2. Enter product key

## Install updates using Windows Update

> **Note**
>
> Repeat until there are no updates available for the computer.

```PowerShell
cls
```

## # Delete C:\\Windows\\SoftwareDistribution folder (2.11 GB)

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse
```

## Update Hyper-V Integration Services

## Update Google Chrome

## Update Mozilla Firefox

## Snapshot VM

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
$vmHost = "FORGE"
$vmName = "WIN8-TEST1"
```

### # Specify configuration in VM notes

```PowerShell
$notes = Get-VM -ComputerName $vmHost -VMName $vmName |
    select -ExpandProperty Notes

$newNotes = `
"Windows 8.1 Enterprise (x64)
Microsoft Office Professional Plus 2013 (x86)
Adobe Reader 8.3.1
Google Chrome
Mozilla Firefox 50.1.0
Mozilla Thunderbird 38.7.0
Remote Server Administration Tools for Windows 8.1
Hyper-V Management Tools enabled" `
    + [System.Environment]::NewLine `
    + [System.Environment]::NewLine `
    + $notes

Set-VM `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Notes $newNotes
```

### # Shutdown VM

```PowerShell
Stop-VM -ComputerName $vmHost -VMName $vmName
```

### # Remove disk from virtual CD/DVD drive

```PowerShell
Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

### # Snapshot VM - "Baseline"

```PowerShell
$snapshotName = "Baseline"

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName $snapshotName
```

---

**TODO:**

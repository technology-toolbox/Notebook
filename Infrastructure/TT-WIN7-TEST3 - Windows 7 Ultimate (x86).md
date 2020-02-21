# TT-WIN7-TEST3 - Windows 7 Ultimate (x86)

Tuesday, November 21, 2017
8:28 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure workstation

---

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV02B"
$vmName = "TT-WIN7-TEST3"
$vmPath = "E:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 2GB `
    -SwitchName "Embedded Team Switch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 2

Set-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path C:\NotBackedUp\Products\Microsoft\MDT-Deploy-x86.iso

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Install custom Windows 7 image

- On the **Task Sequence** step, select **Windows 7 Ultimate (x86)** and click **Next**.
- On the **Computer Details** step, in the **Computer name** box, type **TT-WIN7-TEST3** and click **Next**.
- On the Applications step:
  - Select the following items:
    - Adobe
      - **Adobe Reader 8.3.1**
    - Google
      - **Chrome (32-bit)**
    - Mozilla
      - **Firefox (32-bit)**
      - **Thunderbird**
  - Click **Next**.

```PowerShell
cls
```

### # Rename local Administrator account and set password

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

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

### # Remove disk from virtual CD/DVD drive

```PowerShell
$vmHost = "TT-HV02B"
$vmName = "TT-WIN7-TEST3"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

### # Move computer to different OU

```PowerShell
$vmName = "TT-WIN7-TEST3"

$targetPath = "OU=Workstations,OU=Resources,OU=Quality Assurance" `
    + ",DC=corp,DC=technologytoolbox,DC=com"

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

---

### Login as .\\foo

### # Copy Toolbox content

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$source = "\\TT-FS01\Public\Toolbox"
$destination = "C:\NotBackedUp\Public\Toolbox"

robocopy $source $destination /E /XD "Microsoft SDKs"
```

### # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

### Configure storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 32 GB       | 4K                   | OSDisk       |

```PowerShell
cls
```

#### # Change drive letter for DVD-ROM

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
```

## # Install and configure Remote Server Administration Tools

### # Install Remote Server Administration Tools for Windows 7 SP1

```PowerShell
net use \\TT-FS01\ipc$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
& '\\TT-FS01\Public\Download\Microsoft\Remote Server Administration Tools for Windows 7 SP1\Windows6.1-KB958830-x86-RefreshPkg.msu'
```

### Enable feature to add "netdom" command-line tool

- **Remote Server Administration Tools**
  - **Role Administration Tools**
    - **AD DS and AD LDS Tools**
      - **AD DS Tools**
        - **AD DS Snap-ins and Command-line Tools**

```PowerShell
cls
```

## # Install Microsoft Money

```PowerShell
& "\\TT-FS01\Products\Microsoft\Money 2008\USMoneyBizSunset.exe"
```

```PowerShell
cls
```

## # Install Microsoft Security Essentials

```PowerShell
& "\\TT-FS01\Products\Microsoft\Security Essentials\Windows 7 (x86)\MSEInstall.exe"
```

## Install updates using Windows Update

> **Note**
>
> Repeat until there are no updates available for the computer.

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

## # Snapshot VM - "Baseline"

### # Delete C:\\Windows\\SoftwareDistribution folder

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse
```

```PowerShell
cls
```

### # Shutdown VM

```PowerShell
Stop-Computer
```

### Snapshot VM - "Baseline"

Windows 7 Ultimate (x86)\
Microsoft Office Professional Plus 2013 (x86)\
Adobe Reader 8.3.1\
Google Chrome\
Mozilla Firefox\
Mozilla Thunderbird\
Remote Server Administration Tools for Windows 7 SP1\
Microsoft Money 2008 Biz Sunset\
Microsoft Security Essentials\
Internet Explorer 10

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Move VM to new Management VM network

```PowerShell
$vmName = "TT-WIN7-TEST3"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Management VM Network"

$vm = Get-SCVirtualMachine $vmName

Get-SCVMCheckpoint -VM $vm | Restore-SCVMCheckpoint

Get-SCVMCheckpoint -VM $vm | Remove-SCVMCheckpoint

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -MACAddressType Dynamic `
    -IPv4AddressType Dynamic

New-SCVMCheckpoint -VM $vm -Name Baseline
```

---

## Issue - Not enough free space to install patches using Windows Update

### Expand C: volume

---

**FOOBAR18**

```PowerShell
cls
```

#### # Increase size of VHD

```PowerShell
$vmHost = "TT-HV05B"
$vmName = "TT-WIN7-TEST3"

Stop-VM -ComputerName $vmHost -Name $vmName

Resize-VHD `
    -ComputerName $vmHost `
    -Path ("F:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName" + ".vhdx") `
    -SizeBytes 40GB

Start-VM -ComputerName $vmHost -Name $vmName
```

---

#### Extend partition using Disk Management console

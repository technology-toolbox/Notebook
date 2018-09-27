# TT-WIN10-TEST7 - Windows 10 Enterprise (x64)

Thursday, September 27, 2018
5:11 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure workstation

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "WOLVERINE"
$vmName = "TT-WIN10-TEST7"
$vmPath = "H:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 4GB `
    -SwitchName "Management"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 2 `
    -AutomaticCheckpointsEnabled $false

Set-VMNetworkAdapterVlan `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Access `
    -VlanId 30

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Install custom Windows 10 image

- On the **Task Sequence** step, select **Windows 10 Enterprise (x64)** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **TT-WIN10-TEST7**.
  - Click **Next**.
- On the **Applications** step:
  - Select the following applications:
    - Adobe
      - **Adobe Reader 8.3.1**
    - Google
      - **Chrome (64-bit)**
    - Mozilla
      - **Firefox (64-bit)**
      - **Thunderbird**
  - Click **Next**.

### Login as TECHTOOLBOX\\jjameson-admin

> **Note**
>
> The local Administrator account is disabled when a new Windows 10 machine is joined to a domain:\
> This user can't sign in because this account is currently disabled.

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
```

### # Enable local Administrator account

```PowerShell
$Disabled = 0x0002
$adminUser.UserFlags.Value = $adminUser.UserFlags.Value -bxor $Disabled
$adminUser.SetInfo()
```

#### Reference

**Managing Local User Accounts with PowerShell**\
From <[https://mcpmag.com/articles/2015/05/07/local-user-accounts-with-powershell.aspx](https://mcpmag.com/articles/2015/05/07/local-user-accounts-with-powershell.aspx)>

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Move computer to different OU

```PowerShell
$vmName = "TT-WIN10-TEST7"

$targetPath = ("OU=Workstations,OU=Resources,OU=Quality Assurance" `
    + ",DC=corp,DC=technologytoolbox,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

```PowerShell
cls
```

### # Enable Secure Boot and set first boot device to hard drive

```PowerShell
$vmHost = "WOLVERINE"
$vmName = "TT-WIN10-TEST7"

$vmHardDiskDrive = Get-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName

Stop-VM `
    -ComputerName $vmHost `
    -VMName $vmName

Set-VMFirmware `
    -ComputerName $vmHost `
    -VMName $vmName `
    -EnableSecureBoot On `
    -FirstBootDevice $vmHardDiskDrive

Start-VM `
    -ComputerName $vmHost `
    -VMName $vmName
```

```PowerShell
cls
```

### # Set VM notes

```PowerShell
$vmHost = "WOLVERINE"
$vmName = "TT-WIN10-TEST7"

$notes = "Windows 10 Enterprise (x64)
Microsoft Office Professional Plus 2016 (x86)
Adobe Reader 8.3.1
Google Chrome
Mozilla Firefox
Thunderbird"

Set-VM -ComputerName $vmHost -VMName $vmName -Notes $notes
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

### # Set MaxPatchCacheSize to 0 (recommended)

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

### # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

### # Configure networking

```PowerShell
$interfaceAlias = "Management"
```

#### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Start-Sleep -Seconds 5

ping TT-FS01 -f -l 8900
```

### Configure storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 50 GB       | 4K                   | OSDisk       |

## Login as .\\foo

## Install updates using Windows Update

> **Note**
>
> Repeat until there are no updates available for the computer.

## Examine disk usage

![(screenshot)](https://assets.technologytoolbox.com/screenshots/55/E3387B3E35E03D7948A5E98A987FCA28E8515055.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9F/4212A44E45BFC41CAB9CC7CB3913B4A414ED619F.png)

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Checkpoint VM

```PowerShell
$checkpointName = "Baseline"
$vmHost = "WOLVERINE"
$vmName = "TT-WIN10-TEST7"

Stop-VM -ComputerName $vmHost -Name $vmName

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName $checkpointName

Start-VM -ComputerName $vmHost -Name $vmName
```

---

**TODO:**

## Add virtual machine to Hyper-V protection group in DPM

## # Clean up the WinSxS folder

### Before

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C5/B5102804865E764F95035C1DBDC89A3DE69603C5.png)

```Console
Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase
```

### After

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D9/E5DD31AAC2432F3B070FA53CC499BF3363308ED9.png)

```PowerShell
cls
```

## # Delete C:\\Windows\\SoftwareDistribution folder (3.2 GB)

### # Before

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D9/E5DD31AAC2432F3B070FA53CC499BF3363308ED9.png)

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse
```

### After

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F7/0CCCF21AB8382943FD7123C043143A06DCB9ACF7.png)

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

1. Start Word 2016
2. Enter product key

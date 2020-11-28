# TT-W7-TEST-06 - Windows 7 Ultimate (x86)

Monday, November 23, 2020
3:48 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure workstation

---

**TT-ADMIN04** - Run as administrator

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05E"
$vmName = "TT-W7-TEST-06"
$vmPath = "E:\NotBackedUp\VMs\$vmName"
$vhdPath = "$vmPath\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 40GB `
    -MemoryStartupBytes 2GB `
    -SwitchName "Embedded Team Switch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 2

$isoName = "MDT-Deploy-x86.iso"

Start-Sleep -Seconds 10
$dvdDrive = Get-SCVirtualDVDDrive -VM $vmName

$iso = Get-SCISO | where {$_.Name -eq $isoName}

Set-SCVirtualDVDDrive -VirtualDVDDrive $dvdDrive -ISO $iso -Link

Start-SCVirtualMachine $vmName
```

---

### Install custom Windows 7 image

- On the **Task Sequence** step, select **Windows 7 Ultimate (x86)** and click
  **Next**.
- On the **Computer Details** step, in the **Computer name** box, type
  **TT-W7-TEST-06** and click **Next**.
- On the **Applications** step:
  - Select the following items:
    - Adobe
      - **Adobe Reader 8.3.1**
    - Google
      - **Chrome (32-bit)**
    - Mozilla
      - **Firefox (32-bit)**
      - **Thunderbird (32-bit)**
  - Click **Next**.

### # Rename local Administrator account and set password

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

$password = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted, type the password to use for the local Administrator account.

```PowerShell
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

$adminUser = [ADSI] 'WinNT://./Administrator,User'
$adminUser.Rename('foo')
$adminUser.SetPassword($plainPassword)

logoff
```

---

**TT-ADMIN04** - Run as administrator

```PowerShell
cls
```

### # Remove disk from virtual CD/DVD drive

```PowerShell
$vmHost = "TT-HV05E"
$vmName = "TT-W7-TEST-06"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

### # Set first boot device to hard drive

```PowerShell
Stop-VM -ComputerName $vmHost -VMName $vmName

Set-VMBios `
    -ComputerName $vmHost `
    -VMName $vmName `
    -StartupOrder IDE, CD, LegacyNetworkAdapter, Floppy

Start-VM -ComputerName $vmHost -VMName $vmName
```

---

### Configure network settings

#### Login as .\\foo

#### # Configure network adapter

```PowerShell
$interfaceAlias = "Management"
```

##### # Rename network connection

```PowerShell
# Note: Get-NetAdapter is not available on Windows 7

netsh interface show interface

netsh interface set interface name="Local Area Connection" `
  newname="$interfaceAlias"
```

##### Enable jumbo frames

**Note:** Get-NetAdapterAdvancedProperty is not available on Windows 7

1. Open **Network and Sharing Center**.
2. In the **Network and Sharing Center** window, click **Management**.
3. In the **Management Status** window, click **Properties**.
4. In the **Management Properties** window, on the **Networking** tab, click
   **Configure**.
5. In the **Microsoft Hyper-V Network Adapter Properties** window:
   1. On the **Advanced** tab:
      1. In the **Property** list, select **Jumbo Packet**.
      2. In the **Value** dropdown, select **9014 Bytes**.
   2. Click **OK**.

```PowerShell
cls
```

##### # Verify jumbo packets work as expected

```PowerShell
ping TT-DC10 -f -l 8900
```

```PowerShell
cls
```

##### # Disable NetBIOS over TCP/IP

**Note:** Get-NetAdapter is not available on Windows 7

1. Open **Network and Sharing Center**.
2. In the **Network and Sharing Center** window, click **Management**.
3. In the **Management Status** window, click **Properties**.
4. In the **Management Properties** window, on the **Networking** tab,
   select **Internet Protocol Version 4 (TCP/IPv4)**, and click **Properties**.
5. In the **Internet Protocol Version 4 (TCP/IPv4) Properties** window, click
   **Advanced...**:
6. In the **Advanced TCP/IP Settings** window:
   1. On the **NetBIOS setting** section, select
      **Disable NetBIOS over TCP/IP**.
   2. Click **OK**.
7. In the **Internet Protocol Version 4 (TCP/IPv4) Properties** window, click
   **OK**.

### Configure storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 40 GB       | 4K                   | OSDisk       |

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

---

**TT-ADMIN04** - Run as domain administrator

```PowerShell
cls
```

#### # Move computer to different organizational unit

```PowerShell
$computerName = "TT-W7-TEST-06"
$targetPath = "OU=Workstations,OU=Resources,OU=Quality Assurance" `
    + ",DC=corp,DC=technologytoolbox,DC=com"

Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath
```

### # Configure Windows Update

#### # Add computer to security group for Windows Update schedule

```PowerShell
Add-ADGroupMember `
  -Identity "Windows Update - Slot 21" `
  -Members "$computerName`$"
```

---

```PowerShell
cls
```

#### # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

> **Note**
>
> PowerShell remoting must be enabled for remote Windows Update using PoshPAIG
> ([https://github.com/proxb/PoshPAIG](https://github.com/proxb/PoshPAIG)).

```PowerShell
cls
```

### # Install and configure Remote Server Administration Tools

#### # Install Remote Server Administration Tools for Windows 7 SP1

```PowerShell
net use \\TT-FS01\ipc$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
& "\\TT-FS01\Products\Microsoft\Remote Server Administration Tools for Windows 7 SP1\Windows6.1-KB958830-x86-RefreshPkg.msu"
```

#### Enable feature to add "netdom" command-line tool

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

### Install Internet Explorer 11

> **Note**
>
> It appears Internet Explorer 11 can no longer be installed using Windows
> Server Update Services (WSUS).

```PowerShell
cls
```

```PowerShell
& '\\TT-FS01\Products\Microsoft\Internet Explorer 11\Windows 7\x86\EIE11_EN-US_WOL_WIN7.EXE'
```

#### Reference

**Internet Explorer Downloads**\
Pasted from <[https://support.microsoft.com/en-US/topic/internet-explorer-downloads-d49e1f0d-571c-9a7b-d97e-be248806ca70](https://support.microsoft.com/en-US/topic/internet-explorer-downloads-d49e1f0d-571c-9a7b-d97e-be248806ca70)>

```PowerShell
cls
```

### # Allow domain users to logon remotely

```PowerShell
$domain = "TECHTOOLBOX"
$groupName = "Domain Users"

([ADSI]"WinNT://./Remote Desktop Users,group").Add(
    "WinNT://$domain/$groupName,group")
```

### Install updates using Windows Update

> **Note**
>
> Repeat until there are no updates available for the computer.

```PowerShell
cls
```

### # Enter product key and activate Windows

```PowerShell
slmgr /ipk {product key}
```

> **Note**
>
> When notified that the product key was set successfully, click **OK**.

```Console
slmgr /ato
```

### Activate Microsoft Office

1. Start Word 2013
2. Enter product key

```PowerShell
cls
```

## # Snapshot VM

### # Delete C:\\Windows\\SoftwareDistribution folder

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse

Start-Service wuauserv
```

```PowerShell
cls
```

### # Shutdown VM

```PowerShell
Stop-Computer
```

### Snapshot VM - "Baseline"

---

**TT-ADMIN04** - Run as administrator

```PowerShell
cls
```

```PowerShell
$vmHost = "TT-HV05E"
$vmName = "TT-W7-TEST-06"
```

#### # Specify configuration in VM notes

```PowerShell
$notes = Get-VM -ComputerName $vmHost -VMName $vmName |
    select -ExpandProperty Notes

$newNotes = `
"Windows 7 Ultimate (x86)
Microsoft Office Professional Plus 2013 (x86)
Microsoft Security Essentials
Adobe Reader 8.3.1
Google Chrome (32-bit)
Mozilla Firefox (32-bit)
Mozilla Thunderbird (32-bit)
Remote Server Administration Tools for Windows 7 SP1
Microsoft Money 2008 Biz Sunset
Internet Explorer 11" `
    + [System.Environment]::NewLine `
    + [System.Environment]::NewLine `
    + $notes

Set-VM `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Notes $newNotes
```

#### # Snapshot VM - "Baseline"

```PowerShell
$snapshotName = "Baseline"

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName $snapshotName
```

---

### Configure backup

#### Add virtual machine to Hyper-V protection group in DPM

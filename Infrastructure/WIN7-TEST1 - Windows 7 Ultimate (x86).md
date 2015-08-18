# WIN7-TEST1 - Windows 7 Ultimate (x86)

Monday, August 17, 2015
5:56 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

---

**WOLVERINE**

### # Create virtual machine (WIN7-TEST1)

```PowerShell
$vmName = "WIN7-TEST1"

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -Name $vmName `
    -Path C:\NotBackedUp\VMs `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 25GB `
    -MemoryStartupBytes 2GB `
    -SwitchName "Virtual LAN 2 - 192.168.10.x"

Set-VMMemory `
    -VMName $vmName `
    -DynamicMemoryEnabled $true `
    -MinimumBytes 256MB `
    -MaximumBytes 4GB

#Set-VMDvdDrive -VMName $vmName -Path \\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso

Start-VM $vmName
```

---

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
      - **Firefox 40.0.2**
      - **Thunderbird 38.2.0**
  - Click **Next**.

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

## # Install Remote Server Administration Tools for Windows 7 SP1

```PowerShell
net use \\ICEMAN\ipc$ /USER:TECHTOOLBOX\jjameson

& '\\ICEMAN\Public\Download\Microsoft\Remote Server Administration Tools for Windows 7 SP1\Windows6.1-KB958830-x86-RefreshPkg.msu'
```

```PowerShell
cls
```

## # Install Microsoft Security Essentials

```PowerShell
& "\\ICEMAN\Products\Microsoft\Security Essentials\Windows 7 (x86)\MSEInstall.exe"
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

## # Delete C:\\Windows\\SoftwareDistribution folder (739 MB)

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

## Snapshot VM - "Baseline"

Windows 7 Ultimate (x86)\
Microsoft Office Professional Plus 2013 (x86)\
Adobe Reader 8.3.1\
Google Chrome\
Mozilla Firefox 40.0.2\
Mozilla Thunderbird 38.2.0\
Remote Server Administration Tools for Windows 7 SP1\
Microsoft Security Essentials\
Internet Explorer 10

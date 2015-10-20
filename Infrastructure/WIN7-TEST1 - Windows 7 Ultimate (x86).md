# WIN7-TEST1 - Windows 7 Ultimate (x86)

Monday, October 19, 2015
5:00 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

---

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

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

Set-VMDvdDrive -VMName $vmName -Path \\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso

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

## # Rename local Administrator account and set password

```PowerShell
$adminUser = [ADSI] 'WinNT://./Administrator,User'
$adminUser.Rename('foo')
$adminUser.SetPassword('{password}')

logoff
```

---

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

## # Remove disk from virtual CD/DVD drive

```PowerShell
Set-VMDvdDrive -VMName WIN7-TEST1 -Path $null
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

## # Configure firewall rules for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
netsh advfirewall firewall set rule `
    name="File and Printer Sharing (Echo Request - ICMPv4-In)" profile=domain `
    new enable=yes

netsh advfirewall firewall set rule `
    name="File and Printer Sharing (Echo Request - ICMPv6-In)" profile=domain `
    new enable=yes

netsh advfirewall firewall set rule `
    name="File and Printer Sharing (SMB-In)" profile=domain `
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
```

## # Disable firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
netsh advfirewall firewall set rule `
    name="Remote Windows Update (Dynamic RPC)" new enable=no
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

## Install updates using Windows Update

**Note:** Repeat until there are no updates available for the computer.

```PowerShell
cls
```

## # Delete C:\\Windows\\SoftwareDistribution folder (1.02 GB)

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

**Note:** When notified that the product key was set successfully, click **OK**.

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
Mozilla Firefox 40.0.2\
Mozilla Thunderbird 38.2.0\
Remote Server Administration Tools for Windows 7 SP1\
Microsoft Security Essentials\
Internet Explorer 10

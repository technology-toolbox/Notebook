# WIN7-TEST1 - Windows 7 Ultimate (x86)

Monday, March 21, 2016
5:48 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

### # Create virtual machine

```PowerShell
$vmHost = "STORM"
$vmName = "WIN7-TEST1"

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path C:\NotBackedUp\VMs `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 25GB `
    -MemoryStartupBytes 2GB `
    -SwitchName "Production"

Set-VM `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ProcessorCount 2 `
    -DynamicMemory `
    -MemoryMinimumBytes 512MB `
    -MemoryMaximumBytes 4GB

Set-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path \\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso

Start-VM -ComputerName $vmHost -Name $vmName
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

## Expand C: drive to 27 GB

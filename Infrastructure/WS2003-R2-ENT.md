# WS2003-R2-ENT

Friday, August 24, 2018
5:39 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure infrastructure

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "WS2003-R2-Ent"
$vmPath = "C:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"
$isoName = "EnglishWindowsServer2003R2withSP2Enterprise64bitDISC1.iso"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 20GB `
    -MemoryStartupBytes 4GB `
    -SwitchName "Embedded Team Switch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -AutomaticCheckpointsEnabled $false `
    -ProcessorCount 4 `
    -StaticMemory

$iso = Get-SCISO | where {$_.Name -eq $isoName}

Get-SCVirtualMachine -Name $vmName |
    Get-SCVirtualDVDDrive |
    Set-SCVirtualDVDDrive -ISO $iso -Link

#Start-VM -ComputerName $vmHost -Name $vmName
Start-SCVirtualMachine -VM $vmName
```

---

### Install Windows Server 2003 R2 Enterprise

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Install Windows Server 2003 R2 features (disc 2)

```PowerShell
$vmName = "WS2003-R2-Ent"
$isoName = "EnglishWindowsServer2003R2withSP2Enterprise64bitDISC2.iso"

$iso = Get-SCISO | where {$_.Name -eq $isoName}

Get-SCVirtualMachine -Name $vmName |
    Get-SCVirtualDVDDrive |
    Set-SCVirtualDVDDrive -ISO $iso -Link
```

---

> **Note**
>
> Follow the steps in the Windows Server 2003 R2 Setup Wizard to complete the installation.

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Install Hyper-V Integration Services

```PowerShell
$vmName = "WS2003-R2-Ent"
$isoName = "vmguest-6.3.9600.18692.iso"

$iso = Get-SCISO | where {$_.Name -eq $isoName}

Get-SCVirtualMachine -Name $vmName |
    Get-SCVirtualDVDDrive |
    Set-SCVirtualDVDDrive -ISO $iso -Link
```

---

> **Note**
>
> When prompted, restart the computer to complete the installation.

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Remove disk from virtual CD/DVD drive

```PowerShell
$vmName = "WS2003-R2-Ent"

Get-SCVirtualMachine -Name $vmName |
    Get-SCVirtualDVDDrive |
    Set-SCVirtualDVDDrive -NoMedia
```

---

### REM Copy Toolbox content

```Console
net use \\TT-FS01\Public\Toolbox /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```Console
mkdir C:\NotBackedUp\Public\Toolbox

xcopy \\TT-FS01\Public\Toolbox\robocopy.exe C:\NotBackedUp\Public\Toolbox

pushd C:\NotBackedUp\Public\Toolbox

robocopy \\TT-FS01\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E /XD git-for-windows "Microsoft SDKs"
```

## REM Install latest patches

### REM Install Windows Server 2003 Service Pack 2

```Console
"\\TT-FS01\Products\Microsoft\Windows Server 2003 R2\WindowsServer2003.WindowsXP-KB914961-SP2-x64-ENU.exe"
```

> **Note**
>
> Follow the steps in the Software Update Installation Wizard to complete the installation.

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Snapshot VM

```PowerShell
$vmName = "WS2003-R2-Ent"
```

#### # Shutdown VM

```PowerShell
Stop-SCVirtualMachine -VM $vmName
```

#### # Snapshot VM - "Baseline"

```PowerShell
$snapshotName = "Baseline"

New-SCVMCheckpoint `
    -VM $vmName `
    -Name $snapshotName
```

#### # Start VM

```PowerShell
Start-SCVirtualMachine -VM $vmName
```

---

### Configure Automatic Updates

![(screenshot)](https://assets.technologytoolbox.com/screenshots/56/8C1B99C77A8B2E904A298E353F363590FD5ED956.png)

```Console
cls
```

### REM Install latest patches using Windows Update

```Console
wuauclt /detectnow
```

> **Note**
>
> Restart the computer to complete the installation and repeat until there are not more updates available.

### Install optional updates using Windows Update

- ~~Microsoft .NET Framework 3.5 Service Pack 1 and .NET Framework 3.5 Family Update (KB951847) x64~~
- Remote Desktop Connection (Terminal Services Client 6.0) for Windows Server 2003 x64 Edition (KB925876)
- Update for Internet Explorer 8 Compatibility View List for Windows Server 2003 x64 Edition (KB982632)
- Update for Windows Server 2003 x64 Edition (KB2492386)
- Update for Windows Server 2003 x64 Edition (KB2808679)
- Update for Windows Server 2003 x64 Edition (KB3013410)
- Update for Windows Server 2003 x64 Edition (KB3020338)
- ~~Windows Search 4.0 for Windows Server 2003 x64 Edition (KB940157)~~

> **Note**
>
> Remote Desktop Connection (Terminal Services Client 6.0) must be installed separately from other updates.

```Console
cls
```

### REM Install latest patches using Windows Update (after installing optional updates)

```Console
wuauclt /detectnow
```

> **Note**
>
> This step is necessary to install security updates after installing Remote Desktop Connection (Terminal Services Client 6.0).

```Console
cls
```

### REM Delete C:\\Windows\\SoftwareDistribution folder

```Console
net stop wuauserv

rmdir C:\Windows\SoftwareDistribution /S /Q
```

```Console
cls
```

## REM Prepare to run SysPrep

### REM Install SysPrep utility

```Console
net use \\TT-FS01\Products /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```Console
"\\TT-FS01\Products\Microsoft\Windows Server 2003 R2\SysPrep\WindowsServer2003.WindowsXP-KB926028-v3-x64-ENU.exe" /X
```

Extract file to **C:\\NotBackedUp\\Temp\\Sysprep**.

Copy contents of **C:\\NotBackedUp\\Temp\\Sysprep\\SP2QFE\\deploy.cab** to **C:\\Windows\\System32\\Sysprep**.

```Console
cls
```

#### REM Remove temporary folder

```Console
rmdir C:\NotBackedUp\Temp\SysPrep /S /Q
```

### Backup VHD

Backup VHD before running SysPrep (to avoid issues with running SysPrep multiple times)

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Remove VM checkpoint

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "WS2003-R2-Ent"
```

##### # Shutdown VM

```PowerShell
Stop-SCVirtualMachine -VM $vmName
```

##### # Remove VM snapshot

```PowerShell
Get-SCVMCheckpoint -VM $vmName |
    Remove-SCVMCheckpoint
```

```PowerShell
cls
```

#### # Copy VHD

```PowerShell
$vmPath = "C:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"
$vhdCopyPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName-Before-SysPrep.vhdx"

$script = "
    Write-Host `"Copying file ($vhdPath)...`"

    Copy-Item `"$vhdPath`" `"$vhdCopyPath`"
"

$scriptBlock = [ScriptBlock]::Create($script)

Invoke-Command -ComputerName $vmHost -ScriptBlock $scriptBlock
```

```PowerShell
cls
```

#### # Start VM

```PowerShell
Start-SCVirtualMachine -VM $vmName
```

---

## Create SysPrep VHD

### Remove password for Administrator account

> **Important**
>
> This is necessary to avoid a bug in Sysprep where the Administrator password specified during mini-setup is ignored.\
> Reference:\
> **Microsoft’s Greatest Glitches: Sysprep Admin Passwords**\
> From <[https://mcpmag.com/articles/2006/05/09/microsofts-greatest-glitches-sysprep-admin-passwords.aspx](https://mcpmag.com/articles/2006/05/09/microsofts-greatest-glitches-sysprep-admin-passwords.aspx)>

### REM SysPrep VM

```Console
C:\Windows\System32\SysPrep\sysprep.exe -forceshutdown -reseal -mini
```

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Copy VHD to VM Library

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "WS2003-R2-Ent"
$vmPath = "C:\NotBackedUp\VMs"

$vhdFolderPath = "$vmPath\$vmName\Virtual Hard Disks"
$vhdUncFolderPath = "\\$vmHost\" + $vhdFolderPath.Replace(":", "`$")

$destination = "\\TT-FS01\VM-Library\VHDs"

robocopy $vhdUncFolderPath $destination ($vmName + ".vhdx")
```

```PowerShell
cls
```

### # Restore VHD copied before SysPrep

```PowerShell
$vhdCopyPath = "$vhdFolderPath\$vmName-Before-SysPrep.vhdx"
$vhdPath = "$vhdFolderPath\$vmName.vhdx"

$script = "
    Write-Host `"Restoring VHD copy ($vhdCopyPath)...`"

    Move-Item `"$vhdCopyPath`" `"$vhdPath`" -Force
"

$scriptBlock = [ScriptBlock]::Create($script)

Invoke-Command -ComputerName $vmHost -ScriptBlock $scriptBlock
```

---

## Create SysPrep VHD

### Remove password for Administrator account

> **Important**
>
> This is necessary to avoid a bug in Sysprep where the Administrator password specified during mini-setup is ignored.\
> Reference:\
> **Microsoft’s Greatest Glitches: Sysprep Admin Passwords**\
> From <[https://mcpmag.com/articles/2006/05/09/microsofts-greatest-glitches-sysprep-admin-passwords.aspx](https://mcpmag.com/articles/2006/05/09/microsofts-greatest-glitches-sysprep-admin-passwords.aspx)>

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Move VM to "Bronze" storage

### # Copy VM to new location

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "WS2003-R2-Ent"
$source = "C:\NotBackedUp\VMs\$vmName"
$destination = "F:\NotBackedUp\VMs\$vmName"

$script = "
    Write-Host `"Copying VM ($vmName)...`"

    robocopy `"$source`" `"$destination`" /E /NP
"

$scriptBlock = [ScriptBlock]::Create($script)

Invoke-Command -ComputerName $vmHost -ScriptBlock $scriptBlock
```

```PowerShell
cls
```

### # Remove VM

```PowerShell
Remove-SCVirtualMachine -VM $vmName
```

```PowerShell
cls
```

### # Import VM from new location

```PowerShell
$script = "
    Write-Host `"Importing VM ($vmName)...`"

    `$vmPath = Get-ChildItem `"$destination\Virtual Machines\*.vmcx`" -Recurse

    Import-VM -Path `$vmPath -Register
"

$scriptBlock = [ScriptBlock]::Create($script)

Invoke-Command -ComputerName $vmHost -ScriptBlock $scriptBlock
```

---

# WS2012-R2-Std

Thursday, February 2, 2017
1:09 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

---

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV02B"
$vmName = "WS2012-R2-Std"
$vmPath = "C:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"
$isoPath = "\\TT-FS01.corp.technologytoolbox.com\Products\Microsoft" `
    + "\Windows Server 2012 R2" `
    + "\en_windows_server_2012_r2_with_update_x64_dvd_6052708.iso"

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
    -ProcessorCount 2 `
    -DynamicMemory `
    -MemoryMinimumBytes 2GB `
    -MemoryMaximumBytes 4GB

Set-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path $isoPath

Set-VMDvdDrive : Failed to add device 'Virtual CD/DVD Disk'.
User Account does not have permission to open attachment.
'WS2012-R2-Std' failed to add device 'Virtual CD/DVD Disk'. (Virtual machine ID 942DF038-D1CC-4723-BE8F-32EA0EEC9010)
'WS2012-R2-Std': User account does not have permission required to open attachment
'\\TT-FS01.corp.technologytoolbox.com\Products\Microsoft\Windows Server 2012
R2\en_windows_server_2012_r2_with_update_x64_dvd_6052708.iso'. Error: 'General access denied error' (0x80070005).
(Virtual machine ID 942DF038-D1CC-4723-BE8F-32EA0EEC9010)
At line:1 char:1
+ Set-VMDvdDrive `
+ ~~~~~~~~~~~~~~~~
    + CategoryInfo          : PermissionDenied: (:) [Set-VMDvdDrive], VirtualizationException
    + FullyQualifiedErrorId : AccessDenied,Microsoft.HyperV.PowerShell.Commands.SetVMDvdDrive

$iso = Get-SCISO |
    where {$_.Name -eq "en_windows_server_2012_r2_with_update_x64_dvd_6052708.iso"}

Get-SCVirtualMachine -Name "WS2012-R2-Std" |
    Get-SCVirtualDVDDrive |
    Set-SCVirtualDVDDrive -ISO $iso -Link

#Start-VM -ComputerName $vmHost -Name $vmName
Start-SCVirtualMachine -VM $vmName
```

---

### Install Windows Server 2012 R2 Standard (Server with a GUI)

Product key: **NPD6V-MT6HM-C8F3J-4QFH8-HMGPB**

### Set password for the local Administrator account

---

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Remove disk from virtual CD/DVD drive

```PowerShell
$vmHost = "TT-HV02B"
$vmName = "WS2012-R2-Std"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

---

```PowerShell
cls
```

### # Set time zone

```PowerShell
tzutil /s "Mountain Standard Time"
```

### # Copy Toolbox content

```PowerShell
$source = "\\TT-FS01\Public\Toolbox"
$destination = "C:\NotBackedUp\Public\Toolbox"

net use $source /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```Console
robocopy $source $destination  /E /XD "Microsoft SDKs"
```

### # Set MaxPatchCacheSize to 0 (recommended)

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

```PowerShell
cls
```

## # Install latest patches

### # Configure WSUS intranet location

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\WSUS\WSUS - colossus.reg'
```

> **Note**
>
> When prompted to make changes to the registry, click **Yes**.

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\WSUS\Reset WSUS.cmd'
```

### # Install latest patches using Windows Update

```PowerShell
sconfig
```

```PowerShell
cls
```

### # Delete C:\\Windows\\SoftwareDistribution folder

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse

Start-Service wuauserv
```

### # Reset WSUS

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\WSUS\Reset WSUS for SysPrep Image.cmd'
```

Note that script contains the following statements:

```Console
    @pause

    net start wuauserv

    wuauclt.exe /resetauthorization /detectnow
```

When prompted to **Press any key to continue . . .**, press CTRL+C to terminate script.

## Prepare to run SysPrep

Copy VM before running SysPrep (to avoid issues with running SysPrep multiple times)

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Shutdown VM

```PowerShell
$vmHost = "TT-HV02B"
$vmName = "WS2012-R2-Std"

Stop-VM -ComputerName $vmHost -VMName $vmName
```

### # Copy VHD

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

### # Start VM

```PowerShell
Start-VM -ComputerName $vmHost -VMName $vmName
```

---

## Create SysPrep VHD

```Console
PowerShell
```

```Console
cls
```

### # SysPrep VM

```PowerShell
C:\Windows\System32\Sysprep\sysprep.exe /generalize /oobe /shutdown
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Copy VHD to VM Library

```PowerShell
$vmHost = "TT-HV02B"
$vmName = "WS2012-R2-Std"
$vmPath = "C:\NotBackedUp\VMs"
$vhdFolderPath = "$vmPath\$vmName\Virtual Hard Disks"
$vhdUncFolderPath = "\\$vmHost\" + $vhdFolderPath.Replace(":", "`$")

$destination = "\\TT-FS01\VM-Library\VHDs"

robocopy $vhdUncFolderPath $destination ($vmName + ".vhdx")
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

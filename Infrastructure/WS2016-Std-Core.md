# WS2016-Std-Core

Saturday, January 14, 2017
1:29 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "FORGE"
$vmName = "WS2016-Std-Core"
$vmPath = "C:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"
$isoPath = "\\ICEMAN\Products\Microsoft\Windows Server 2016" `
    + "\en_windows_server_2016_x64_dvd_9327751.iso"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 2GB

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 2 `
    -DynamicMemory `
    -MemoryMaximumBytes 4GB

Set-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path $isoPath

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Install Windows Server 2016 Standard ("Server Core")

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Remove disk from virtual CD/DVD drive

```PowerShell
$vmHost = "FORGE"
$vmName = "WS2016-Std-Core"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

---

### Set password for the local Administrator account

```Console
PowerShell
```

```Console
cls
```

### # Set time zone

```PowerShell
tzutil /s "Mountain Standard Time"
```

### # Copy Toolbox content

```PowerShell
$source = "\\ICEMAN\Public\Toolbox"
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

### # Install cumulative update for Windows Server 2016

#### # Copy patch to local storage

```PowerShell
$source = "\\ICEMAN\Products\Microsoft\Windows 10\Patches"
$destination = "C:\NotBackedUp\Temp"
$patch = "windows10.0-kb3213522-x64_fc88893ff1fbe75cac5f5aae7ff1becee55c89dd.msu"

net use $source /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```Console
robocopy $source $destination $patch
```

#### # Install patch

```PowerShell
& "$destination\$patch"
```

> **Note**
>
> When prompted, restart the computer to complete the installation.

```Console
PowerShell
```

```Console
cls
```

#### # Delete local copy of patch

```PowerShell
Remove-Item ("C:\NotBackedUp\Temp" `
    + "\windows10.0-kb3213522-x64_fc88893ff1fbe75cac5f5aae7ff1becee55c89dd.msu")
```

### # Install latest patches using Windows Update

```PowerShell
sconfig

PowerShell
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
$vmHost = "FORGE"
$vmName = "WS2016-Std-Core"

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
$vmHost = "FORGE"
$vmName = "WS2016-Std-Core"
$vmPath = "C:\NotBackedUp\VMs"
$vhdFolderPath = "$vmPath\$vmName\Virtual Hard Disks"
$vhdUncFolderPath = "\\$vmHost\" + $vhdFolderPath.Replace(":", "`$")

$destination = "\\ICEMAN\VMM-Library\VHDs"

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

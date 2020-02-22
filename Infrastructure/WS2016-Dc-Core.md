# WS2016-Dc-Core

Saturday, January 14, 2017
1:29 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

---

**FOOBAR10 - Run as administrator**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "WS2016-Dc-Core"
$vmPath = "C:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"
$isoName = "en_windows_server_2016_updated_feb_2018_x64_dvd_11636692.iso"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 4GB `
    -SwitchName "Embedded Team Switch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 2

Add-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName

$vmDvdDrive = Get-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName

Set-VMFirmware `
    -ComputerName $vmHost `
    -VMName $vmName `
    -EnableSecureBoot Off `
    -FirstBootDevice $vmDvdDrive

$iso = Get-SCISO | where {$_.Name -eq $isoName}

Get-SCVirtualMachine -Name $vmName |
    Get-SCVirtualDVDDrive |
    Set-SCVirtualDVDDrive -ISO $iso -Link

#Start-VM -ComputerName $vmHost -Name $vmName
Start-SCVirtualMachine -VM $vmName
```

---

### Install Windows Server 2016 Datacenter ("Server Core")

### Set password for the local Administrator account

---

**FOOBAR10 - Run as administrator**

```PowerShell
cls
```

### # Remove disk from virtual CD/DVD drive

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "WS2016-Dc-Core"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

---

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
$source = "\\TT-FS01\Public\Toolbox"
$destination = "C:\NotBackedUp\Public\Toolbox"

net use $source /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```Console
robocopy $source $destination  /E /XD git-for-windows "Microsoft SDKs" /NP
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
& 'C:\NotBackedUp\Public\Toolbox\WSUS\WSUS - wsus.technologytoolbox.com.reg'
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

> **Note**
>
> When prompted to restart the computer to complete Windows Updates, click **Yes**.

> **Important**
>
> Repeat the previous steps until there are no more updates to install.

```Console
PowerShell
```

```Console
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

**FOOBAR10 - Run as administrator**

```PowerShell
cls
```

### # Shutdown VM

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "WS2016-Dc-Core"

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

**FOOBAR10 - Run as administrator**

```PowerShell
cls
```

### # Copy VHD to VM Library

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "WS2016-Dc-Core"
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

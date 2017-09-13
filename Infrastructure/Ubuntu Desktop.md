# Ubuntu Desktop

Tuesday, September 12, 2017
2:02 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Install Ubuntu 16.04.3 Desktop

---

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmName = "Ubuntu-Desktop"
$vmPath = "C:\NotBackedUp\VMs"

$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -Name $vmName `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 20GB `
    -MemoryStartupBytes 4GB `
    -SwitchName "Management"

Set-VM `
    -Name $vmName `
    -ProcessorCount 4 `
    -StaticMemory

$isoPath = "\\TT-FS01\Products\Ubuntu\ubuntu-16.04.3-desktop-amd64.iso"

Set-VMDvdDrive `
    -VMName $vmName `
    -Path $isoPath

Start-VM -Name $vmName
```

---

### Install and configure operating system

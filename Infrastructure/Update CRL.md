# Update Certificate Revocation List (CRL)

Monday, August 17, 2015\
9:42 AM

---

**TT-ADMIN05** - Run as administrator

```PowerShell
cls
```

## # Start offline root CA (CRYPTID) and attach new virtual floppy disk

```PowerShell
$vmHost = 'TT-HV06A'

Invoke-Command -ComputerName $vmHost -ScriptBlock {
    $rootCA = 'CRYPTID'

    Start-VM $rootCA

    $vfdFolder = "C:\NotBackedUp\VMs\$rootCA\Virtual Floppy Disks"

    If ((Test-Path $vfdFolder) -eq $false)
    {
        New-Item -ItemType Directory -Path $vfdFolder | Out-Null
    }

    $vfdFile = "$vfdFolder\$rootCA.vfd"

    If ((Test-Path $vfdFile) -eq $true)
    {
        Remove-Item $vfdFile
    }

    New-VFD -Path $vfdFile | Out-Null

    Set-VMFloppyDiskDrive -VMName $rootCA -Path $vfdFile
}
```

---

## # Republish CRL on root CA and copy it to virtual floppy disk

---

**CRYPTID** - Run as administrator

```Console
PowerShell
```

### # Republish the CRL

```PowerShell
certutil -CRL
```

### # Format virtual floppy disk

```PowerShell
format A:
```

When prompted for the volume label, press **Enter**.

When prompted to format another disk, type **N** and then press **Enter**.

### # Copy certificate file and CRL for root CA to floppy disk

```PowerShell
copy C:\Windows\system32\CertSrv\CertEnroll\*.crl A:\
```

### # Verify CRL for root CA was copied to floppy disk

```PowerShell
dir A:\
```

---

---

**TT-ADMIN05** - Run as administrator

```PowerShell
cls
```

## # Remove virtual floppy disk from root CA virtual machine

```PowerShell
$vmHost = 'TT-HV06A'
$rootCA = 'CRYPTID'

Set-VMFloppyDiskDrive -ComputerName $vmHost -VMName $rootCA -Path $null
```

```PowerShell
cls
```

## # Copy CRL to file server (TT-FS01)

```PowerShell
$vmHost = 'TT-HV06A'
$rootCA = 'CRYPTID'

$vfdPath = `
    "\\$vmHost\C$\NotBackedUp\VMs\$rootCA\Virtual Floppy Disks\$rootCA.vfd"

Move-Item $vfdPath '\\TT-FS01\Public\'
```

```PowerShell
cls
```

### # Shutdown root CA

```PowerShell
$vmHost = 'TT-HV06A'
$rootCA = 'CRYPTID'

Stop-VM -ComputerName $vmHost -VMName $rootCA
```

```PowerShell
cls
```

## # Copy CRL to Hyper-V server (TT-HV06C) for issuing CA virtual machine (CIPHER01)

```PowerShell
$vmHost = 'TT-HV06C'
$issuingCA = 'CIPHER01'
$rootCA = 'CRYPTID'

$vfdFolder = "\\$vmHost\C`$\NotBackedUp\VMs\$issuingCA\Virtual Floppy Disks"

If ((Test-Path $vfdFolder) -eq $false)
{
    New-Item -ItemType Directory -Path $vfdFolder | Out-Null
}

$vfdFile = "$vfdFolder\$rootCA.vfd"

If ((Test-Path $vfdFile) -eq $true)
{
    Remove-Item $vfdFile
}

Move-Item "\\TT-FS01\Public\$rootCA.vfd" $vfdFolder
```

```PowerShell
cls
```

## # Attach virtual floppy disk containing CRL from root CA to issuing CA

```PowerShell
$vmHost = 'TT-HV06C'

Invoke-Command -ComputerName $vmHost -ScriptBlock {
    $rootCA = 'CRYPTID'
    $issuingCA = 'CIPHER01'

    $vfdFolder = "C:\NotBackedUp\VMs\$issuingCA\Virtual Floppy Disks"
    $vfdPath = "$vfdFolder\$rootCA.vfd"

    Set-VMFloppyDiskDrive -VMName $issuingCA -Path $vfdPath
}
```

```PowerShell
cls
```

## # Publish CRL from root CA to issuing CA (CIPHER01)

```PowerShell
Invoke-Command -ComputerName CIPHER01 -ScriptBlock {
    A:

    certutil -addstore -f `
        root "Technology Toolbox Root Certificate Authority.crl"

    Start-Service CertSvc
}
```

```PowerShell
cls
```

## # Remove virtual floppy disk from issuing CA and delete it

```PowerShell
$vmHost = 'TT-HV06C'

Invoke-Command -ComputerName $vmHost -ScriptBlock {
    $rootCA = 'CRYPTID'
    $issuingCA = 'CIPHER01'

    Set-VMFloppyDiskDrive -VMName $issuingCA -Path $null

    $vfdFolder = "C:\NotBackedUp\VMs\$issuingCA\Virtual Floppy Disks"

    $vfdFile = "$vfdFolder\$rootCA.vfd"

    Remove-Item $vfdFile
}
```

---

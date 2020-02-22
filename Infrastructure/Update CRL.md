# Update CRL

Monday, August 17, 2015
9:42 AM

---

**FOOBAR8** - Run as administrator

## # On the Hyper-V host (STORM), start the offline root CA (CRYPTID) and attach a new virtual floppy disk

```PowerShell
Invoke-Command -ComputerName STORM -ScriptBlock {
    $rootCA = 'CRYPTID'

    Start-VM $rootCA

    $vfdFolder = "C:\NotBackedUp\VMs\$rootCA\Virtual Floppy Disks"

    If ((Test-Path $vfdFolder) -eq $false)
    {
        New-Item -ItemType Directory -Path $vfdFolder > $null
    }

    $vfdFile = "$vfdFolder\$rootCA.vfd"

    If ((Test-Path $vfdFile) -eq $true)
    {
        Remove-Item $vfdFile
    }

    New-VFD -Path $vfdFile > $null

    Set-VMFloppyDiskDrive -VMName $rootCA -Path $vfdFile
}
```

---

## # Republish the CRL on the root CA and copy it to the virtual floppy disk

---

**CRYPTID** - Run as administrator

```Console
PowerShell
```

### # Republish the CRL

```PowerShell
certutil -CRL
```

### # Format virtual floppy disk in VM

```PowerShell
format A:
```

When prompted for the volume label, press Enter.

When prompted to format another disk, type **N** and then press Enter.

### # Copy the certificate file and CRL for root CA to floppy disk

```PowerShell
copy C:\Windows\system32\CertSrv\CertEnroll\*.crl A:\
```

### # Verify the CRL for root CA was copied to the floppy disk

```PowerShell
dir A:\
```

---

---

**FOOBAR8** - Run as administrator

## # Remove virtual floppy disk from root CA VM and copy the CRL to a file server (ICEMAN)

```PowerShell
Invoke-Command -ComputerName STORM -ScriptBlock {
    $rootCA = 'CRYPTID'

    Set-VMFloppyDiskDrive -VMName $rootCA -Path $null

    $vfdPath = "C:\NotBackedUp\VMs\$rootCA\Virtual Floppy Disks\$rootCA.vfd"

    Move-Item $vfdPath '\\ICEMAN\Public\'
```

### # Shutdown root CA

```PowerShell
    Stop-VM $rootCA
}
```

## # Attach virtual floppy disk containing CRL from root CA to issuing CA

```PowerShell
Invoke-Command -ComputerName BEAST -ScriptBlock {
    $rootCA = 'CRYPTID'
    $issuingCA = 'CIPHER01'

    $vfdFolder = "C:\NotBackedUp\VMs\$issuingCA\Virtual Floppy Disks"

    If ((Test-Path $vfdFolder) -eq $false)
    {
        New-Item -ItemType Directory -Path $vfdFolder > $null
    }

    $vfdFile = "$vfdFolder\$rootCA.vfd"

    If ((Test-Path $vfdFile) -eq $true)
    {
        Remove-Item $vfdFile
    }

    Move-Item "\\ICEMAN\Public\$rootCA.vfd" $vfdFolder

    $vfdPath = "$vfdFolder\$rootCA.vfd"

    Set-VMFloppyDiskDrive -VMName $issuingCA -Path $vfdPath
}
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

## # Remove virtual floppy disk from issuing CA and delete it

```PowerShell
Invoke-Command -ComputerName BEAST -ScriptBlock {
    $rootCA = 'CRYPTID'
    $issuingCA = 'CIPHER01'

    Set-VMFloppyDiskDrive -VMName $issuingCA -Path $null

    $vfdFolder = "C:\NotBackedUp\VMs\$issuingCA\Virtual Floppy Disks"

    $vfdFile = "$vfdFolder\$rootCA.vfd"

    Remove-Item $vfdFile
}
```

---

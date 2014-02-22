# CRYPTID - Windows Server 2012 R2 Standard

Saturday, February 22, 2014
6:05 AM

```Console
12345678901234567890123456789012345678901234567890123456789012345678901234567890

PowerShell
```

## # [STORM] Create virtual machine (CRYPTID)

```PowerShell
$vmName = "CRYPTID"
```

> **Important**
>
> Do not connect this computer to a network.

```PowerShell
New-VM `
    -Name $vmName `
    -Path C:\NotBackedUp\VMs `
    -MemoryStartupBytes 1024MB

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VHD `
    -Path $vhdPath `
    -SizeBytes 32GB `-Dynamic

Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath

$isoPath = "\\iceman\Products\Microsoft\Windows Server 2012 R2" `
    + "\en_windows_server_2012_r2_x64_dvd_2707946.iso"

Set-VMDvdDrive `
    -VMName $vmName `-Path $isoPath

Start-VM $vmName
```

## # Rename the server

```PowerShell
Rename-Computer -NewName CRYPTID -Restart
```

## # Set time zone

```PowerShell
tzutil /s "Mountain Standard Time"

tzutil /g
```

## Prepare the CAPolicy.inf for the standalone root CA

1. At the command prompt, type the following:
2. When prompted to create a new file, click **Yes**.
3. Enter the following as the contents of the file:
4. On the **File** menu, click **Save As**.
5. In the **Save As** window:
   1. Ensure the following:
   2. **File name** is set to **CAPolicy.inf**
   3. **Save as type** is set to **All Files**
   4. **Encoding** is set to **ANSI**
   5. Click **Save**.
6. When you are prompted to replace the file, click **Yes**.
7. Close Notepad.

```Console
    notepad C:\Windows\CAPolicy.inf
```

```INI
    [Version]
    Signature="$Windows NT$"
    ; Configuration for root CA

    [PolicyStatementExtension]
    Policies=CertificatePolicy

    [CertificatePolicy]
    OID=1.3.6.1.4.1.42625.1.1.1
    URL=http://pki.technologytoolbox.com/cps

    [Certsrv_Server]
    RenewalKeyLength=4096
    RenewalValidityPeriod=Years
    RenewalValidityPeriodUnits=20
    CRLPeriod=Months
    CRLPeriodUnits=6
    CRLDeltaPeriod=Days
    CRLDeltaPeriodUnits=0
    LoadDefaultTemplates=0
    AlternateSignatureAlgorithm=1

    [BasicConstraintsExtension]
    PathLength=1
    Critical=Yes
```

## # [STORM] Checkpoint the VM

```PowerShell
Checkpoint-VM CRYPTID
```

## # Install ADCS feature on the standalone root CA

```PowerShell
Install-WindowsFeature Adcs-Cert-Authority -IncludeManagementTools
```

## # Install Certification Authority role on the standalone root CA

```PowerShell
Install-AdcsCertificationAuthority `
    -CAType StandaloneRootCA `-CACommonName "Technology Toolbox Root Certificate Authority" `-KeyLength 4096 `-HashAlgorithmName SHA256 `-CryptoProviderName "RSA#Microsoft Software Key Storage Provider" `
    -ValidityPeriod Years `
    -ValidityPeriodUnits 20
```

## # Configure the root CA settings

### # CA configuration script for a Windows Server 2012 R2 root CA

```PowerShell
certutil -setreg CA\DSConfigDN `
    "CN=Configuration,DC=corp,DC=technologytoolbox,DC=com"
```

#### # Configure CRL and AIA CDP

```PowerShell
certutil -setreg CA\CRLPublicationURLs `
    ("1:C:\Windows\System32\CertSrv\CertEnroll\%3%8.crl\n" `
    + "2:http://pki.technologytoolbox.com/crl/%3%8.crl")

certutil -setreg CA\CACertPublicationURLs `
    "2:http://pki.technologytoolbox.com/certs/%3%4.crt"
```

#### # Configure CRL publication

```PowerShell
certutil -setreg CA\CRLOverlapPeriodUnits 12
certutil -setreg CA\CRLOverlapPeriod "Hours"
```

#### # Set the validity period for issued certificates

```PowerShell
certutil -setreg CA\ValidityPeriodUnits 10
certutil -setreg CA\ValidityPeriod "Years"
```

#### # Enable all auditing on the CA

```PowerShell
certutil -setreg CA\AuditFilter 127
```

#### # Restart the CA server service

```PowerShell
Restart-Service certsvc
```

#### # Republish the CRL

```PowerShell
certutil -CRL
```

## # Copy the root CA certificate and CRL to removable media

### # Rename certificate for root CA to remove server name

```PowerShell
Rename-Item `
    ("C:\Windows\System32\CertSrv\CertEnroll\" `
        + "CRYPTID_Technology Toolbox Root Certificate Authority.crt") `
    "Technology Toolbox Root Certificate Authority.crt"
```

### # [STORM] Create virtual floppy disk on Hyper-V host

```PowerShell
$vmName = "CRYPTID"

mkdir "C:\NotBackedUp\VMs\$vmName\Virtual Floppy Disks"

$vfdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Floppy Disks\$vmName.vfd"

New-VFD -Path $vfdPath

Set-VMFloppyDiskDrive -VMName $vmName -Path $vfdPath
```

### # Format virtual floppy disk in VM

```PowerShell
format A:
```

When prompted for the volume label, press Enter.

When prompted to format another disk, type **N** and then press Enter.

### # Copy the certificate file and CRL for root CA to floppy disk

```PowerShell
copy C:\Windows\system32\CertSrv\CertEnroll\*.cr* A:\
```

### # Verify the certificate file and CRL for root CA were copied to the floppy disk

```PowerShell
dir A:\
```

## # [CIPHER01] Distribute the root CA certificate

## # [STORM] Shutdown root CA (CRYPTID)

```PowerShell
Stop-VM CRYPTID
```

## # [STORM] Delete the checkpoint for root CA VM

```PowerShell
Remove-VMSnapshot CRYPTID
```

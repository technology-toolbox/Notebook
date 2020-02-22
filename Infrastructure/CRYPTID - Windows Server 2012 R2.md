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
    -SizeBytes 32GB `
    -Dynamic

Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath

$isoPath = "\\iceman\Products\Microsoft\Windows Server 2012 R2" `
    + "\en_windows_server_2012_r2_x64_dvd_2707946.iso"

Set-VMDvdDrive `
    -VMName $vmName `
    -Path $isoPath

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
    -CAType StandaloneRootCA `
    -CACommonName "Technology Toolbox Root Certificate Authority" `
    -KeyLength 4096 `
    -HashAlgorithmName SHA256 `
    -CryptoProviderName "RSA#Microsoft Software Key Storage Provider" `
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

## Issue - ADCS certificates do not work in Linux environments

---

**FOOBAR18** - Run as administrator

```PowerShell
cls
```

### # Start root CA (CRYPTID)

```PowerShell
Start-VM -ComputerName TT-HV05A -Name CRYPTID
```

---

### Modify CAPolicy.inf for root CA

1. At the command prompt, type the following:
2. Locate the following line:
3. Set **AlternateSignatureAlgorithm** to **0**:
4. On the **File** menu, click **Save**.
5. Close Notepad.

```Console
notepad C:\Windows\CAPolicy.inf
```

```Text
    AlternateSignatureAlgorithm=1
```

```Text
    AlternateSignatureAlgorithm=0
```

```Console
PowerShell
```

```Console
cls
```

### # Disable AlternateSignatureAlgorithm in registry

```PowerShell
certutil -getreg ca\csp\AlternateSignatureAlgorithm
HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\CertSvc\Configuration\Technology Toolbox Root Certificate Authority\csp:

  AlternateSignatureAlgorithm REG_DWORD = 1
CertUtil: -getreg command completed successfully.
```

```PowerShell
cls
certutil -setreg ca\csp\AlternateSignatureAlgorithm 0
HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\CertSvc\Configuration\Technology Toolbox Root Certificate Authority\csp:

Old Value:
  AlternateSignatureAlgorithm REG_DWORD = 1

New Value:
  AlternateSignatureAlgorithm REG_DWORD = 0
CertUtil: -setreg command completed successfully.
The CertSvc service may need to be restarted for the changes to take effect.
```

```PowerShell
cls
Restart-Service "Active Directory Certificate Services"
```

```PowerShell
cls
```

### # Renew certification authority

```PowerShell
certutil -renewCert ReuseKeys
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3A/134E75A60266C88C119A85BE34A2A17C3333563A.png)

**Error renewing standalone root CA certificate**\
From <[https://social.technet.microsoft.com/Forums/en-US/cd841a4e-f44f-440c-ab35-d72da737f286/error-renewing-standalone-root-ca-certificate?forum=winserversecurity](https://social.technet.microsoft.com/Forums/en-US/cd841a4e-f44f-440c-ab35-d72da737f286/error-renewing-standalone-root-ca-certificate?forum=winserversecurity)>

```Console
certutil -getreg ca\CACertFileName
HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\CertSvc\Configuration\Technology Toolbox Root Certificate Authority\CACertFileName:

  CACertFileName REG_SZ = \\CRYPTID\CertConfig\%1_%3%4.crt
CertUtil: -getreg command completed successfully.
```

```Console
cls
certutil -setreg ca\CACertFileName C:\CAConfig\%1_%3%4.crt
HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\CertSvc\Configuration\Technology Toolbox Root Certificate Authority\CACertFileName:

Old Value:
  CACertFileName REG_SZ = \\CRYPTID\CertConfig\%1_%3%4.crt

New Value:
  CACertFileName REG_SZ = C:\CAConfig\%1_%3%4.crt
CertUtil: -setreg command completed successfully.
The CertSvc service may need to be restarted for the changes to take effect.
```

```Console
cls
Restart-Service "Active Directory Certificate Services"
```

```Console
cls
certutil -renewCert ReuseKeys
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3D/453968EA6405D6AF4CD840C0E9E64D99F54D2E3D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FE/112ED769FA60CEA3B865D5D6805F8D28E49A3FFE.png)

```PowerShell
cls
```

### # Copy the root CA certificate and CRL to removable media

#### # Rename certificate for root CA to remove server name

```PowerShell
Remove-Item `
    ("C:\Windows\System32\CertSrv\CertEnroll\" `
        + "Technology Toolbox Root Certificate Authority.crt")

Rename-Item `
    ("C:\Windows\System32\CertSrv\CertEnroll\" `
        + "CRYPTID_Technology Toolbox Root Certificate Authority(3).crt") `
    "Technology Toolbox Root Certificate Authority.crt"
```

#### Copy the root CA certificate and CRL to removable media

---

**FOOBAR18** - Run as administrator

```PowerShell
cls
```

##### # Create virtual floppy disk on Hyper-V host

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "CRYPTID"
$vmPath = "F:\NotBackedUp\VMs\$vmName"

mkdir "$vmPath\Virtual Floppy Disks"

$vfdPath = "$vmPath\Virtual Floppy Disks\$vmName.vfd"

New-VFD -ComputerName $vmHost -Path $vfdPath

Set-VMFloppyDiskDrive -ComputerName $vmHost -VMName $vmName -Path $vfdPath
```

---

```PowerShell
cls
```

##### # Format virtual floppy disk

```PowerShell
format A:
```

> **Note**
>
> When prompted for the volume label, press Enter.
>
> When prompted to format another disk, type **N** and then press Enter.

```PowerShell
cls
```

##### # Copy the root CA certificate and CRL to floppy disk

```PowerShell
Push-Location C:\Windows\system32\CertSrv\CertEnroll

copy 'Technology Toolbox Root Certificate Authority.crl' A:\
copy 'Technology Toolbox Root Certificate Authority.crt' A:\

Pop-Location
```

##### # Verify the root CA certificate and CRL were copied to the floppy disk

```PowerShell
dir A:\
```

### Distribute the root CA certificate and CRL

---

**FOOBAR18** - Run as administrator

```PowerShell
cls
```

#### # Remove virtual floppy disk from root CA

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "CRYPTID"

Set-VMFloppyDiskDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

#### # Shutdown root CA (CRYPTID)

```PowerShell
Stop-VM -ComputerName $vmHost -Name $vmName
```

```PowerShell
cls
```

#### # Copy virtual floppy disk to intermediate CA

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "CIPHER01"

$scriptBlock = [ScriptBlock]::Create(
    "copy '$vfdPath' 'C:\ClusterStorage\iscsi02-Silver-01\$vmName'")

Invoke-Command -ComputerName $vmHost -ScriptBlock $scriptBlock
```

```PowerShell
cls
```

#### # Configure virtual floppy disk containing CRL from root CA

```PowerShell
$vfdPath = "C:\ClusterStorage\iscsi02-Silver-01\$vmName" `
    + "\CRYPTID.vfd"

Set-VMFloppyDiskDrive -ComputerName $vmHost -VMName $vmName -Path $vfdPath
```

---

---

**CIPHER01** - Run as administrator

```PowerShell
cls
```

#### # Publish root CA certificate and CRL to Active Directory and CIPHER01

```PowerShell
Push-Location A:

certutil -dspublish -f `
    "Technology Toolbox Root Certificate Authority.crt" RootCA

certutil -addstore -f `
    root "Technology Toolbox Root Certificate Authority.crt"

certutil -addstore -f `
    root "Technology Toolbox Root Certificate Authority.crl"
```

> **Note**
>
> The first command places the root CA public certificate into the Configuration
> container of Active Directory. Doing so allows domain client computers to
> automatically trust the root CA certificate and there is no additional need to
> distribute that certificate in Group Policy. The second and third commands
> place the root CA certificate and CRL into the local store of CIPHER01. This
> provides CIPHER01 immediate trust of root CA public certificate and knowledge
> of the root CA CRL.

```PowerShell
cls
```

#### # Copy root CA certificate and CRL to PKI website

```PowerShell
Copy-Item `
    "A:\Technology Toolbox Root Certificate Authority.crt" `
    "\\CIPHER01\PKI$\certs"

Copy-Item `
    "A:\Technology Toolbox Root Certificate Authority.crl" `
    "\\CIPHER01\PKI$\crl"

Pop-Location
```

---

---

**FOOBAR18** - Run as administrator

```PowerShell
cls
```

#### # Delete virtual floppy disk containing CRL from root CA

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "CIPHER01"

Set-VMFloppyDiskDrive -ComputerName $vmHost -VMName $vmName -Path $null

$scriptBlock = [ScriptBlock]::Create("Remove-Item '$vfdPath'")

Invoke-Command -ComputerName $vmHost -ScriptBlock $scriptBlock
```

---

---

**CIPHER01** - Run as administrator

```PowerShell
cls
```

### # Modify CAPolicy.inf for issuing CA

1. At the command prompt, type the following:
2. Locate the following line:
3. Set **AlternateSignatureAlgorithm** to **0**:
4. On the **File** menu, click **Save**.
5. Close Notepad.

```Console
notepad C:\Windows\CAPolicy.inf
```

```Text
    AlternateSignatureAlgorithm=1
```

```Text
    AlternateSignatureAlgorithm=0
```

```PowerShell
cls
```

### # Disable AlternateSignatureAlgorithm in registry

```PowerShell
certutil -getreg ca\csp\AlternateSignatureAlgorithm
HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\CertSvc\Configuration\Technology Toolbox Issuing Certificate Authority 01\csp:

  AlternateSignatureAlgorithm REG_DWORD = 1
CertUtil: -getreg command completed successfully.
```

```PowerShell
cls
certutil -setreg ca\csp\AlternateSignatureAlgorithm 0
HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\CertSvc\Configuration\Technology Toolbox Issuing Certificate Authority 01\csp:

Old Value:
  AlternateSignatureAlgorithm REG_DWORD = 1

New Value:
  AlternateSignatureAlgorithm REG_DWORD = 0
CertUtil: -setreg command completed successfully.
The CertSvc service may need to be restarted for the changes to take effect.
```

```PowerShell
cls
Restart-Service "Active Directory Certificate Services"
```

```PowerShell
cls
```

### # Renew certification authority

```PowerShell
certutil -renewCert ReuseKeys
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/56/A4B35B7E30248CC9F74FD980F6FB565C4C8E8C56.png)

Click **Cancel**.

```PowerShell
cls
```

### # Submit certificate request to root CA

#### # Copy certificate request to root CA (via floppy disk)

##### # Copy certificate request to floppy disk

```PowerShell
copy 'C:\CIPHER01.corp.technologytoolbox.com_Technology Toolbox Issuing Certificate Authority 01(1).req' A:
```

---

**FOOBAR18** - Run as administrator

```PowerShell
cls
```

##### # Remove virtual floppy disk containing certificate request from issuing CA

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "CIPHER01"

Set-VMFloppyDiskDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

```PowerShell
cls
```

##### # Copy virtual floppy disk containing certificate request to root CA

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "CRYPTID"
$vmPath = "F:\NotBackedUp\VMs\$vmName"

$vfdPath = "$vmPath\Virtual Floppy Disks\$vmName.vfd"

$scriptBlock = [ScriptBlock]::Create(
    "copy 'C:\ClusterStorage\iscsi02-Silver-01\CIPHER01\$vmName.vfd' '$vfdPath'")

Invoke-Command -ComputerName $vmHost -ScriptBlock $scriptBlock
```

```PowerShell
cls
```

#### # Configure virtual floppy disk containing CRL on root CA

```PowerShell
Set-VMFloppyDiskDrive -ComputerName $vmHost -VMName $vmName -Path $vfdPath
```

---

---

```PowerShell
cls
```

#### # Submit certificate request from issuing CA to root CA

```PowerShell
certreq.exe -submit 'A:\CIPHER01.corp.technologytoolbox.com_Technology Toolbox Issuing Certificate Authority 01(1).req'
```

1. In the **Certification Authority List** window, ensure that **Technology Toolbox Root Certificate Authority (Kerberos)** CA is selected and then click **OK**.
2. Note that the certificate request is pending. Make a note of the request ID number.
3. To approve the request using certutil, enter:\
   \
   Certutil -resubmit _`<RequestId>`_

   Replace the actual request number for `<RequestId>`. For example, if the Request ID is 6, you would enter:

   ```Console
   certutil.exe -resubmit 6
   ```

4. From the command prompt, retrieve the issued certificate by running the command:

   ```Console
   certreq.exe -retrieve 6 'A:\\Technology Toolbox Issuing Certificate Authority 01(1).crt'
   ```

5. In the **Certification Authority List** window, ensure that **Technology Toolbox Root Certificate Authority (Kerberos)** CA is selected and then click **OK**.

```PowerShell
cls
```

#### # Verify the certificate

```PowerShell
certutil.exe -verify 'A:\Technology Toolbox Issuing Certificate Authority 01(1).crt'
```

#### Copy certificate to issuing CA

---

**FOOBAR18** - Run as administrator

```PowerShell
cls
```

##### # Remove virtual floppy disk from root CA

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "CRYPTID"

Set-VMFloppyDiskDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

```PowerShell
cls
```

#### # Copy virtual floppy disk to intermediate CA

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "CIPHER01"

$scriptBlock = [ScriptBlock]::Create(
    "copy '$vfdPath' 'C:\ClusterStorage\iscsi02-Silver-01\$vmName'")

Invoke-Command -ComputerName $vmHost -ScriptBlock $scriptBlock
```

```PowerShell
cls
```

#### # Configure virtual floppy disk containing CRL from root CA

```PowerShell
$vfdPath = "C:\ClusterStorage\iscsi02-Silver-01\$vmName" `
    + "\CRYPTID.vfd"

Set-VMFloppyDiskDrive -ComputerName $vmHost -VMName $vmName -Path $vfdPath
```

---

---

**CIPHER01** - Run as administrator

#### Install new certificate for issuing CA

1. Open **Certification Authority**.
2. In the console tree, click the name of the CA.
3. On the **Action** menu, point to **All Tasks**, and then click **Install CA Certificate**.
4. Select the certificate file received from the parent certification authority and then click **Open**.

---

---

**FOOBAR18** - Run as administrator

```PowerShell
cls
```

#### # Delete virtual floppy disk containing root CA certificate and CRL

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "CIPHER01"

Set-VMFloppyDiskDrive -ComputerName $vmHost -VMName $vmName -Path $null

$vfdPath = "C:\ClusterStorage\iscsi02-Silver-01\$vmName" `
    + "\CRYPTID.vfd"

$scriptBlock = [ScriptBlock]::Create("Remove-Item '$vfdPath'")

Invoke-Command -ComputerName $vmHost -ScriptBlock $scriptBlock
```

```PowerShell
cls
```

##### # Shutdown root CA (CRYPTID)

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "CRYPTID"

Stop-VM -ComputerName $vmHost -Name $vmName
```

---

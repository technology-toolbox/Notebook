# FAB-ADMIN01

Wednesday, May 22, 2019\
9:56 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure infrastructure

---

**FOOBAR18** - Run as administrator

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "FAB-ADMIN01"
$vmPath = "D:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Generation 2 `
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
    -MemoryMinimumBytes 1GB `
    -MemoryMaximumBytes 4GB `
    -AutomaticCheckpointsEnabled $false

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

Set-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path "\\TT-FS01\Products\Microsoft\Windows Server 2019\en_windows_server_2019_updated_march_2019_x64_dvd_2ae967ab.iso"

Set-VMDvdDrive : Failed to add device 'Virtual CD/DVD Disk'.
User Account does not have permission to open attachment.
'FAB-ADMIN01' failed to add device 'Virtual CD/DVD Disk'. (Virtual machine ID 986572FB-ACEE-4A34-B3D2-4E177CFBC7F4)
'FAB-ADMIN01': User account does not have permission required to open attachment '\\TT-FS01\Products\Microsoft\Windows Server
2019\en_windows_server_2019_updated_march_2019_x64_dvd_2ae967ab.iso'. Error: 'General access denied error' (0x80070005). (Virtual
machine ID 986572FB-ACEE-4A34-B3D2-4E177CFBC7F4)
At line:1 char:1
+ Set-VMDvdDrive `
+ ~~~~~~~~~~~~~~~~
    + CategoryInfo          : PermissionDenied: (:) [Set-VMDvdDrive], VirtualizationException
    + FullyQualifiedErrorId : AccessDenied,Microsoft.HyperV.PowerShell.Commands.SetVMDvdDrive

$iso = Get-SCISO |
    where {$_.Name -eq "en_windows_server_2019_updated_march_2019_x64_dvd_2ae967ab.iso"}

Get-SCVirtualMachine -Name $vmName | Read-SCVirtualMachine

Get-SCVirtualMachine -Name $vmName |
    Get-SCVirtualDVDDrive |
    Set-SCVirtualDVDDrive -ISO $iso -Link

#Start-VM -ComputerName $vmHost -Name $vmName
Start-SCVirtualMachine -VM $vmName
```

---

### Install Windows Server 2019

1. When prompted, select **Windows Server 2019 Standard**.
2. Specify a password for the local Administrator account.

```Console
PowerShell
```

### # Rename local Administrator account

```PowerShell
$adminUser = [ADSI] 'WinNT://./Administrator,User'
$adminUser.Rename('foo')

logoff
```

### Login as .\\foo

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
net use \\TT-FS01.corp.technologytoolbox.com\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$source = "\\TT-FS01.corp.technologytoolbox.com\Public\Toolbox"
$destination = "C:\NotBackedUp\Public\Toolbox"

robocopy $source $destination /E /XD git-for-windows "Microsoft SDKs" /NP
```

### # Set MaxPatchCacheSize to 0 (recommended)

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

---

**FOOBAR18** - Run as administrator

```PowerShell
cls
```

### # Move VM to Fabrikam VM network

```PowerShell
$vmName = "FAB-ADMIN01"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Fabrikam VM Network"

Stop-SCVirtualMachine $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork

Start-SCVirtualMachine $vmName
```

---

### Login as .\\foo

```Console
PowerShell
```

```Console
cls
```

### # Rename computer and join domain

#### # Rename computer

```PowerShell
$computerName = "FAB-ADMIN01"

Rename-Computer -NewName $computerName -Restart
```

> **Note**
>
> Wait for the VM to restart.

```Console
PowerShell
```

```Console
cls
```

#### # Join domain

```PowerShell
Add-Computer -DomainName corp.fabrikam.com -Restart
```

> **Note**
>
> Wait for the VM to restart.

### Login as FABRIKAM\\jjameson-admin

---

**FAB-DC05** - Run as domain administrator

```PowerShell
cls
```

### # Move computer to different OU

```PowerShell
$vmName = "FAB-ADMIN01"

$targetPath = ("OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=fabrikam,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

### # Configure Windows Update

#### # Add machine to security group for Windows Update schedule

```PowerShell
Add-ADGroupMember -Identity "Windows Update - Slot 2" -Members "FAB-ADMIN01$"
```

---

### Configure storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 32 GB       | 4K                   | OSDisk       |

```Console
PowerShell
```

```Console
cls
```

#### # Change drive letter for DVD-ROM

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
```

```PowerShell
cls
```

### # Configure networking

```PowerShell
$interfaceAlias = "Management"
```

#### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Start-Sleep -Seconds 5

ping TT-FS01.corp.technologytoolbox.com -f -l 8900
```

## Deploy Windows Admin Center

### Install certificate for Windows Admin Center

---

**FAB-TEST1** - Run as domain administrator

```PowerShell
cls
```

#### # Create certificate for Windows Admin Center

##### # Create certificate request

```PowerShell
& "C:\NotBackedUp\Public\Toolbox\PowerShell\New-CertificateRequest.ps1" `
    -Subject "CN=admin.fabrikam.com,OU=IT,O=Fabrikam Technologies,L=Denver,S=CO,C=US" `
    -SANs admin.fabrikam.com
```

##### # Submit certificate request to the Certification Authority

###### # Add Active Directory Certificate Services site to the "Trusted sites" zone and browse to the site

```PowerShell
[Uri] $adcsUrl = [Uri] "https://cipher01.corp.technologytoolbox.com"

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-InternetSecurityZoneMapping.ps1 `
    -Zone LocalIntranet `
    -Patterns $adcsUrl.AbsoluteUri

Start-Process $adcsUrl.AbsoluteUri
```

###### # Submit the certificate request to an enterprise CA

> **Note**
>
> Copy the certificate request to the clipboard.

**To submit the certificate request to an enterprise CA:**

1. On the computer hosting the Operations Manager feature for which you are requesting a certificate, start Internet Explorer, and browse to Active Directory Certificate Services site ([https://cipher01.corp.technologytoolbox.com/](https://cipher01.corp.technologytoolbox.com/)).
2. On the **Welcome** page, click **Request a certificate**.
3. On the **Advanced Certificate Request** page, click **Submit a certificate request by using a base-64-encoded CMC or PKCS #10 file, or submit a renewal request by using a base-64-encoded PKCS #7 file.**
4. On the **Submit a Certificate Request or Renewal Request** page, in the **Saved Request** text box, paste the contents of the certificate request generated in the previous procedure.
5. In the **Certificate Template** section, select the Operations Manager certificate template (**Technology Toolbox Operations Manager**), and then click **Submit**. When prompted to allow the digital certificate operation to be performed, click **Yes**.
6. On the **Certificate Issued** page, click **Download certificate** and save the certificate.

```PowerShell
cls
```

##### # Import the certificate into the certificate store

```PowerShell
$certFile = "C:\Users\jjameson-admin\Downloads\certnew.cer"

CertReq.exe -Accept $certFile
```

```PowerShell
cls
```

##### # Delete the certificate file

```PowerShell
Remove-Item $certFile
```

##### Export certificate

Filename: **[\\\\FAB-DC01\\Users\$\\jjameson-admin\\Documents\\Certificates\\admin.fabrikam.com.pfx](\FAB-DC01\Users$\jjameson-admin\Documents\Certificates\admin.fabrikam.com.pfx)**

---

```PowerShell
cls
```

#### # Import certificate for Windows Admin Center

```PowerShell
$certFile = "\\FAB-DC01\Users$\jjameson-admin\Documents\Certificates\admin.fabrikam.com.pfx"

Set-ExecutionPolicy RemoteSigned -Scope Process -Force

$certPassword = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1

Import-PfxCertificate `
    -Password $certPassword `
    -FilePath $certFile `
    -CertStoreLocation Cert:\LocalMachine\My



   PSParentPath: Microsoft.PowerShell.Security\Certificate::LocalMachine\My

Thumbprint                                Subject
----------                                -------
696E6DB5D28CA2C8062A75607321EA736868C142  CN=admin.fabrikam.com, OU=IT, O=Fabrikam Technologies, L=Denver, S=CO, C=US
```

```PowerShell
cls
```

### # Download installation file for Windows Admin Center

```PowerShell
$installerPath = "$env:USERPROFILE\Downloads\WindowsAdminCenter.msi"

Invoke-WebRequest `
    -UseBasicParsing -Uri https://aka.ms/WACDownload `
    -OutFile $installerPath
```

```PowerShell
cls
```

### # Install Windows Admin Center

```PowerShell
$certThumbprint = "696E6DB5D28CA2C8062A75607321EA736868C142"

$installerArguments = "/qn /L*v log.txt SME_PORT=443 SME_THUMBPRINT=$certThumbprint SSL_CERTIFICATE_OPTION=installed"
```

Specifying **REGISTRY_REDIRECT_PORT_80=1** when installing Windows Admin Center results in the following HTTP header being added to any request that specifies http:// as the protocol:

Upgrade-Insecure-Requests: 1

However, the initial authentication (using NTLM) still takes place over HTTP (not HTTPS). After the initial authentication succeeds, the browser redirects to HTTPS -- which results in a second authentication prompt.

When **REGISTRY_REDIRECT_PORT_80=1** is not specified, users must explicitly connect using HTTPS (i.e. specifying http://... causes the browser to timeout).

```PowerShell
Start-Process `
    -FilePath $installerPath `
    -ArgumentList "$installerArguments" `
    -Wait
```

### Configure name resolution for Windows Admin Center

---

**FAB-DC05** - Run as domain administrator

```PowerShell
Add-DNSServerResourceRecordCName `
    -ZoneName fabrikam.com `
    -Name admin `
    -HostNameAlias FAB-ADMIN01.corp.fabrikam.com
```

---

---

**FOOBAR18** - Run as administrator

```PowerShell
cls
```

## # Make virtual machine highly available

### # Migrate VM to shared storage

```PowerShell
$vmName = "FAB-ADMIN01"

$vm = Get-SCVirtualMachine -Name $vmName
$vmHost = $vm.VMHost

Move-SCVirtualMachine `
    -VM $vm `
    -VMHost $vmHost `
    -HighlyAvailable $true `
    -Path "C:\ClusterStorage\iscsi02-Silver-01" `
    -UseDiffDiskOptimization
```

```PowerShell
cls
```

### # Allow migration to host with different processor version

```PowerShell
Stop-SCVirtualMachine -VM $vmName

Set-SCVirtualMachine -VM $vmName -CPULimitForMigration $true

Start-SCVirtualMachine -VM $vmName
```

---

## Configure backups

### Add virtual machine to Hyper-V protection group in DPM

**TODO:**

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

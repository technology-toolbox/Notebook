# TT-ADMIN01 - Windows Server 2019

Monday, September 9, 2019\
5:38 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure infrastructure

---

**FOOBAR22** - Run as administrator

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "TT-ADMIN01"
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

Set-VMNetworkAdapterVlan `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Access `
    -VlanId 30

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Install custom Windows Server 2019 image

- On the **Task Sequence** step, select **Windows Server 2019** and click
  **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **TT-ADMIN01**.
  - Click **Next**.
- On the **Applications** step:
  - Select the following applications:
    - **Chrome**
      - **Chrome (64-bit)**
  - Click **Next**.

```Console
PowerShell
```

```Console
cls
```

### # Rename local Administrator account and set password

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

$password = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted, type the password for the local Administrator account.

```PowerShell
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

$adminUser = [ADSI] 'WinNT://./Administrator,User'
$adminUser.Rename('foo')
$adminUser.SetPassword($plainPassword)

logoff
```

### Login as .\\foo

### Configure storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 32 GB       | 4K                   | OSDisk       |

---

**FOOBAR22** - Run as administrator

```PowerShell
cls
```

### # Move VM to Production VM network

```PowerShell
$vmName = "TT-ADMIN01"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Production VM Network"
$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"
$ipPool = Get-SCStaticIPAddressPool -Name "Production-15 Address Pool"

Stop-SCVirtualMachine $vmName

$macAddress = Grant-SCMACAddress `
    -MACAddressPool $macAddressPool `
    -Description $vmName `
    -VirtualNetworkAdapter $networkAdapter

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -MACAddressType Static `
    -MACAddress $macAddress `
    -IPv4AddressPools $ipPool `
    -IPv4AddressType Static

Start-SCVirtualMachine $vmName
```

---

```PowerShell
cls
```

### # Configure networking

```PowerShell
$interfaceAlias = "Production"
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

ping TT-DC10 -f -l 8900
```

---

**FOOBAR22** - Run as domain administrator

```PowerShell
cls

$vmName = "TT-ADMIN01"
```

### # Move computer to different OU

```PowerShell
$targetPath = ("OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

### # Configure Windows Update

#### # Add machine to security group for Windows Update schedule

```PowerShell
Add-ADGroupMember -Identity "Windows Update - Slot 20" -Members ($vmName + '$')
```

---

```PowerShell
cls
```

## # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

> **Note**
>
> PowerShell remoting must be enabled for remote Windows Update using PoshPAIG
> ([https://github.com/proxb/PoshPAIG](https://github.com/proxb/PoshPAIG)).

## Install updates using Windows Update

> **Note**
>
> Repeat until there are no updates available for the computer.

## Baseline virtual machine

---

**FOOBAR22** - Run as administrator

```PowerShell
cls
```

### # Checkpoint VM

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "TT-ADMIN01"
$checkpointName = "Baseline"

Stop-VM -ComputerName $vmHost -Name $vmName

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName $checkpointName

Start-VM -ComputerName $vmHost -Name $vmName
```

---

## Deploy Windows Admin Center

### Install certificate for Windows Admin Center

---

**FOOBAR22** - Run as administrator

```PowerShell
cls
```

#### # Create certificate for Windows Admin Center

##### # Create certificate request

```PowerShell
& "C:\NotBackedUp\Public\Toolbox\PowerShell\New-CertificateRequest.ps1" `
    -Subject ("CN=admin.technologytoolbox.com,OU=IT,O=Technology Toolbox," `
        + "L=Parker,S=CO,C=US") `
    -SANs admin.technologytoolbox.com
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

1. Start Internet Explorer, and browse to the Active Directory Certificate
   Services site
   ([https://cipher01.corp.technologytoolbox.com/](https://cipher01.corp.technologytoolbox.com/)).
2. On the **Welcome** page, click **Request a certificate**.
3. On the **Advanced Certificate Request** page, click **Submit a certificate
   request by using a base-64-encoded CMC or PKCS #10 file, or submit a renewal
   request by using a base-64-encoded PKCS #7 file.**
4. On the **Submit a Certificate Request or Renewal Request** page, in the
   **Saved Request** text box, paste the contents of the certificate request
   generated in the previous procedure.
5. In the **Certificate Template** section, select the certificate template
   (**Technology Toolbox Web Server - Exportable**), and then click **Submit**.
   When prompted to allow the digital certificate operation to be performed,
   click **Yes**.
6. On the **Certificate Issued** page, click **Download certificate** and save
   the certificate.

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

Filename: **[\\\\TT-FS01\\Users\$\\jjameson-admin\\My
Documents\\Certificates\\admin.technologytoolbox.com.pfx](\\TT-FS01\Users\$\jjameson-admin\My
Documents\Certificates\admin.technologytoolbox.com.pfx)**

---

```PowerShell
cls
```

#### # Import certificate for Windows Admin Center

```PowerShell
$certFile = "\\TT-FS01\Users$\jjameson-admin\My Documents\Certificates\admin.technologytoolbox.com.pfx"

Set-ExecutionPolicy RemoteSigned -Scope Process -Force

$certPassword = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1

Import-PfxCertificate `
    -Password $certPassword `
    -FilePath $certFile `
    -CertStoreLocation Cert:\LocalMachine\My



   PSParentPath: Microsoft.PowerShell.Security\Certificate::LocalMachine\My

Thumbprint                                Subject
----------                                -------
33C8527E6BBA5BDA794471E9B617C88DA31206DA  CN=admin.technologytoolbox.com, OU=IT, O=Technology Toolbox, L=Parker, S=C...
```

```PowerShell
cls
```

### # Download installation file for Windows Admin Center

```PowerShell
$installerPath = "$env:USERPROFILE\Downloads\WindowsAdminCenter.msi"

Invoke-WebRequest `
    -UseBasicParsing `
    -Uri https://aka.ms/WACDownload `
    -OutFile $installerPath
```

```PowerShell
cls
```

### # Install Windows Admin Center

```PowerShell
$certThumbprint = "33C8527E6BBA5BDA794471E9B617C88DA31206DA"

$installerArguments = "/qn /L*v log.txt SME_PORT=443 SME_THUMBPRINT=$certThumbprint SSL_CERTIFICATE_OPTION=installed"
```

> **Note**
>
> Specifying **REGISTRY_REDIRECT_PORT_80=1** when installing Windows Admin
> Center results in the following HTTP header being added to any request that
> specifies http:// as the protocol:
>
> Upgrade-Insecure-Requests: 1
>
> However, the initial authentication (using NTLM) still takes place over HTTP
> (not HTTPS). After the initial authentication succeeds, the browser redirects
> to HTTPS -- which results in a second authentication prompt.
>
> When **REGISTRY_REDIRECT_PORT_80=1** is not specified, users must explicitly
> connect using HTTPS (i.e. specifying http://... causes the browser to
> timeout).

```PowerShell
Start-Process `
    -FilePath $installerPath `
    -ArgumentList "$installerArguments" `
    -Wait
```

---

**FOOBAR22** - Run as administrator

```PowerShell
cls
```

### # Configure name resolution for Windows Admin Center

```PowerShell
Add-DNSServerResourceRecordCName `
    -ComputerName TT-DC10 `
    -ZoneName technologytoolbox.com `
    -Name admin `
    -HostNameAlias TT-ADMIN01.corp.technologytoolbox.com
```

```PowerShell
cls
```

## # Make virtual machine highly available

### # Migrate VM to shared storage

```PowerShell
$vmName = "TT-ADMIN01"

$vm = Get-SCVirtualMachine -Name $vmName
$vmHost = $vm.VMHost

Move-SCVirtualMachine `
    -VM $vm `
    -VMHost $vmHost `
    -HighlyAvailable $true `
    -Path "C:\ClusterStorage\iscsi02-Silver-02" `
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

## Delete VM baseline

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

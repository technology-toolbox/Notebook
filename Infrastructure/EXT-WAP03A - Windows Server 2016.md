# EXT-WAP03A - Windows Server 2016

Thursday, March 29, 2018
1:27 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy federated authentication

### Install and configure federation server farm

#### Install Windows Server 2016 on AD FS and WAP servers

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

##### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "EXT-WAP03A"
$vmPath = "E:\NotBackedUp\VMs\$vmName"
$vhdPath = "$vmPath\Virtual Hard Disks\$vmName.vhdx"

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
    -DynamicMemory `
    -MemoryMinimumBytes 2GB `
    -MemoryMaximumBytes 4GB `
    -ProcessorCount 2

Start-VM -ComputerName $vmHost -Name $vmName
```

---

##### Install custom Windows Server 2016 image

- On the **Task Sequence** step, select **Windows Server 2016** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **EXT-WAP03A**.
  - Select **Join a workgroup**.
  - In the **Workgroup **box, type **WORKGROUP**.
  - Click **Next**.
- On the **Applications** step, ensure no items are selected and click **Next**.

##### # Rename local Administrator account and set password

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

##### Configure networking

---

**TT-VMM01A**

```PowerShell
cls
```

###### # Configure static IP address using VMM

```PowerShell
$vmName = "EXT-WAP03A"

$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"

$vmNetwork = Get-SCVMNetwork -Name "Extranet-20 VM Network"

$ipPool = Get-SCStaticIPAddressPool -Name "Extranet-20 Address Pool"

$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName |
    ? { $_.SlotId -eq 0 }

Stop-SCVirtualMachine $vmName

$macAddress = Grant-SCMACAddress `
    -MACAddressPool $macAddressPool `
    -Description $vmName `
    -VirtualNetworkAdapter $networkAdapter

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -MACAddressType Static `
    -MACAddress $macAddress

$ipAddress = Grant-SCIPAddress `
    -GrantToObjectType VirtualNetworkAdapter `
    -GrantToObjectID $networkAdapter.ID `
    -StaticIPAddressPool $ipPool `
    -Description $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -IPv4AddressType Static `
    -IPv4Addresses $IPAddress.Address

Start-SCVirtualMachine $vmName
```

---

###### Login as .\\foo

###### # Rename network connections

```PowerShell
$interfaceAlias = "Extranet-20"

Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

##### # Configure storage

###### # Set MaxPatchCacheSize to 0 (recommended)

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

#### # Join servers to domain

```PowerShell
$cred = Get-Credential EXTRANET\jjameson-admin

Add-Computer -DomainName extranet.technologytoolbox.com -Credential $cred -Restart
```

---

**EXT-DC08 - Run as EXTRANET\\jjameson-admin**

```PowerShell
cls
```

##### # Move computer to different OU

```PowerShell
$computerName = "EXT-WAP03A"

$targetPath = ("OU=Servers,OU=Resources,OU=IT" `
    + ",DC=extranet,DC=technologytoolbox,DC=com")

Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath
```

##### # Configure Windows Update

###### # Add machine to security group for Windows Update schedule

```PowerShell
$domainGroupName = "Windows Update - Slot 3"

Add-ADGroupMember -Identity $domainGroupName -Members ($computerName + '$')
```

---

### Configure backup

#### Add virtual machine to Hyper-V protection group in DPM

```PowerShell
cls
```

### # Configure monitoring

#### # Create certificate for Operations Manager

##### # Create request for Operations Manager certificate

```PowerShell
& "C:\NotBackedUp\Public\Toolbox\Operations Manager\Scripts\New-OperationsManagerCertificateRequest.ps1"
```

##### # Submit certificate request to the Certification Authority

###### # Add Active Directory Certificate Services site to the "Trusted sites" zone and browse to the site

```PowerShell
[Uri] $adcsUrl = [Uri] "https://cipher01.corp.technologytoolbox.com"

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-InternetSecurityZoneMapping.ps1 `
    -Zone TrustedSites `
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
$certFile = "C:\Users\Administrator\Downloads\certnew.cer"

CertReq.exe -Accept $certFile
```

```PowerShell
cls
```

##### # Delete the certificate file

```PowerShell
Remove-Item $certFile
```

#### # Copy SCOM agent installation files

##### # Temporarily enable firewall rule for copying files to server

```PowerShell
Enable-NetFirewallRule -DisplayName "File and Printer Sharing (SMB-In)"
```

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

##### # Copy SCOM agent installation files from internal file server

```PowerShell
$computerName = "EXT-WAP03A.extranet.technologytoolbox.com"

net use "\\$computerName\C`$" /USER:EXTRANET\jjameson-admin
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$source = "\\TT-FS01\Products\Microsoft\System Center 2016\SCOM\Agent\AMD64"
$destination = "\\$computerName\C`$\NotBackedUp\Temp\SCOM\Agent\AMD64"

robocopy $source $destination /E

$source = "\\TT-FS01\Products\Microsoft\System Center 2016\SCOM" `
    + "\SupportTools\AMD64"

$destination = "\\$computerName\C`$\NotBackedUp\Temp\SCOM\SupportTools\AMD64"

robocopy $source $destination /E
```

---

```PowerShell
cls
```

##### # Disable firewall rule for copying files to server

```PowerShell
Disable-NetFirewallRule -DisplayName "File and Printer Sharing (SMB-In)"
```

#### # Install SCOM agent

```PowerShell
$installerPath = "C:\NotBackedUp\Temp\SCOM\Agent\AMD64\MOMAgent.msi"

$installerArguments = "MANAGEMENT_GROUP=HQ" `
    + " MANAGEMENT_SERVER_DNS=tt-scom03.corp.technologytoolbox.com" `
    + " ACTIONS_USE_COMPUTER_ACCOUNT=1" `
    + " NOAPM=1"

Start-Process `
    -FilePath msiexec.exe `
    -ArgumentList "/i `"$installerPath`" $installerArguments" `
    -Wait
```

> **Important**
>
> Wait for the installation to complete.

```PowerShell
cls
```

#### # Import the certificate into Operations Manager using MOMCertImport

```PowerShell
$hostName = ([System.Net.Dns]::GetHostByName(($env:computerName))).HostName

$certImportToolPath = "C:\NotBackedUp\Temp\SCOM\SupportTools\AMD64"

Push-Location "$certImportToolPath"

.\MOMCertImport.exe /SubjectName $hostName

Pop-Location
```

```PowerShell
cls
```

#### # Remove Operations Manager installation files

```PowerShell
Remove-Item C:\NotBackedUp\Temp\SCOM -Recurse
```

#### Approve manual agent install in Operations Manager

```PowerShell
cls
```

## # Install and configure AD FS

### # Import certificate for secure communication with AD FS

#### # Copy certificate

##### # Temporarily enable firewall rule for copying files to server

```PowerShell
Enable-NetFirewallRule -DisplayName "File and Printer Sharing (SMB-In)"
```

---

**WOLVERINE - Run as TECHTOOLBOX\\jjameson**

```PowerShell
cls
```

##### # Copy certificate from internal file server

```PowerShell
$computerName = "EXT-WAP03A.extranet.technologytoolbox.com"
$certFile = "fs.technologytoolbox.com.pfx"

$source = "\\TT-FS01\Users$\jjameson\My Documents\Technology Toolbox LLC" `
    + "\Certificates\Internal"

$destination = "\\$computerName\C$\NotBackedUp\Temp"

net use "\\$computerName\C`$" /USER:EXTRANET\jjameson-admin
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```Console
robocopy $source $destination $certFile
```

---

```PowerShell
cls
```

#### # Disable firewall rule for copying files to server

```PowerShell
Disable-NetFirewallRule -DisplayName "File and Printer Sharing (SMB-In)"
```

#### # Install certificate

```PowerShell
$certPassword = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted for the secure string, type the password for the exported certificate.

```PowerShell
$certFile = "C:\NotBackedUp\Temp\fs.technologytoolbox.com.pfx"

Import-PfxCertificate `
    -FilePath $certFile `
    -CertStoreLocation Cert:\LocalMachine\My `
    -Password $certPassword

If ($? -eq $true)
{
    Remove-Item $certFile
}
```

```PowerShell
cls
```

### # Add Remote Access - Web Application Proxy server role

```PowerShell
Install-WindowsFeature Web-Application-Proxy -IncludeManagementTools
```

```PowerShell
cls
```

#### # Configure Web Application Proxy

```PowerShell
$cert = Get-ChildItem -Path Cert:\LocalMachine\My |
    Where { $_.Subject -like "CN=fs.technologytoolbox.com,*" }

$federationServiceTrustCred = Get-Credential EXTRANET\jjameson-admin
```

> **Note**
>
> When prompted, type the username and password for an account with administrator privileges on the servers with the AD FS role installed.

```PowerShell
Install-WebApplicationProxy `
    -CertificateThumbprint $cert.Thumbprint `
    -FederationServiceTrustCredential $federationServiceTrustCred `
    -FederationServiceName fs.technologytoolbox.com


WARNING: A machine restart is required to complete ADFS service configuration. For more information, see:
http://go.microsoft.com/fwlink/?LinkId=798725

Message                                   Context              Status
-------                                   -------              ------
The configuration completed successfully. DeploymentSucceeded Success


Restart-Computer
```

## Issue - Firewall log contains numerous entries for UDP 137 broadcast

### Solution

```PowerShell
cls
```

#### # Disable NetBIOS over TCP/IP

```PowerShell
Get-NetAdapter |
    foreach {
        $interfaceAlias = $_.Name

        Write-Host ("Disabling NetBIOS over TCP/IP on interface" `
            + " ($interfaceAlias)...")

        $adapter = Get-WmiObject -Class "Win32_NetworkAdapter" `
            -Filter "NetConnectionId = '$interfaceAlias'"

        $adapterConfig = `
            Get-WmiObject -Class "Win32_NetworkAdapterConfiguration" `
                -Filter "Index= '$($adapter.DeviceID)'"

        # Disable NetBIOS over TCP/IP
        $adapterConfig.SetTcpipNetbios(2)
    }
```

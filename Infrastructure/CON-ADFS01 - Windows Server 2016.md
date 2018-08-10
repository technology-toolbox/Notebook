# CON-ADFS01 - Windows Server 2016

Tuesday, August 7, 2018
7:26 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "CON-ADFS01"
$vmPath = "E:\NotBackedUp\VMs\$vmName"
$vhdPath = "$vmPath\Virtual Hard Disks\$vmName.vhdx"

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

$vmNetwork = Get-SCVMNetwork -Name "Management VM Network"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork

Start-SCVirtualMachine $vmName
```

---

### Install Windows Server 2016

#### Install Windows Server 2016

- On the **Task Sequence** step, select **Windows Server 2016** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **CON-ADFS01**.
  - Select **Join a workgroup**.
  - In the **Workgroup **box, type **WORKGROUP**.
  - Click **Next**.
- On the **Applications** step, ensure no items are selected and click **Next**.

#### # Rename local Administrator account and set password

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

#### # Set MaxPatchCacheSize to 0 (recommended)

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

#### # Enable performance counters for Server Manager

```PowerShell
$taskName = "\Microsoft\Windows\PLA\Server Manager Performance Monitor"

Enable-ScheduledTask -TaskName $taskName

logman start "Server Manager Performance Monitor"
```

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Set first boot device to hard drive

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "CON-ADFS01"

$vmHardDiskDrive = Get-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName |
    where { $_.ControllerType -eq "SCSI" `
        -and $_.ControllerNumber -eq 0 `
        -and $_.ControllerLocation -eq 0 }

Set-VMFirmware `
    -ComputerName $vmHost `
    -VMName $vmName `
    -FirstBootDevice $vmHardDiskDrive
```

---

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

ping TT-FS01 -f -l 8900
```

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Configure static IP address using VMM

```PowerShell
$vmName = "CON-ADFS01"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Contoso VM Network"
$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"
$ipAddressPool = Get-SCStaticIPAddressPool -Name "Contoso-60 Address Pool"

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
    -IPv4AddressType Static `
    -IPv4AddressPools $ipAddressPool

Start-SCVirtualMachine $vmName
```

---

### Login as .\\foo

### Configure storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 32 GB       | 4K                   | OSDisk       |

### # Join member server to domain

#### # Add computer to domain

```PowerShell
Add-Computer `
    -DomainName corp.contoso.com `
    -Credential (Get-Credential CONTOSO\Administrator) `
    -Restart
```

#### Move computer to different OU

---

**CON-DC1 - Run as CONTOSO\\Administrator**

```PowerShell
$computerName = "CON-ADFS01"
$targetPath = "OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=contoso,DC=com"

Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath
```

---

### Add virtual machine to Hyper-V protection group in DPM

---

**CON-DC1 - Run as CONTOSO\\Administrator**

```PowerShell
cls
```

### # Configure Windows Update

#### # Add machine to security group for Windows Update schedule

```PowerShell
Add-ADGroupMember -Identity "Windows Update - Slot 22" -Members "CON-ADFS01$"
```

---

## AD FS prerequisites

### Enable the creation of group Managed Service Accounts

**Note:** Not explicitly required, but recommended

- A group Managed Service Account (gMSA) can be used across multiple servers
- The password for a gMSA is maintained by the Key Distribution Service (KDS) running on a Windows Server 2012 domain controller
- The KDS Root Key must be created using PowerShell

#### Create the KDS Root Key

Before any gMSA accounts can be created the KDS Root Key must be generated using PowerShell:

```PowerShell
Add-KdsRootKey -EffectiveImmediately
```

However, there is an enforced delay of 10 hours before a gMSA can be created after running the command. This is to "guarantee" that the key has propagated to all 2012 DCs

For lab work the delay can be overridden using the EffectiveTime parameter.

---

**CON-DC1**

```PowerShell
Add-KdsRootKey -EffectiveTime (Get-Date).AddHours(-10)
```

---

```PowerShell
cls
```

### # Enroll SSL certificate for AD FS

#### # Create certificate request

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\New-CertificateRequest.ps1 `
    -Subject "CN=fs.contoso.com,OU=IT,O=Contoso Pharmaceuticals,L=Denver,S=CO,C=US" `
    -SANs fs.contoso.com,enterpriseregistration.corp.contoso.com
```

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

#### Submit certificate request to Active Directory Certificate Services

1. Browse to **[https://cipher01.corp.technologytoolbox.com](https://cipher01.corp.technologytoolbox.com)**.
2. On the **Welcome** page of the Active Directory Certificate Services site, in the **Select a task** section, click **Request a certificate**.
3. On the **Advanced Certificate Request** page, click **Submit a certificate request by using a base-64-encoded CMC or PKCS #10 file, or submit a renewal request by using a base-64-encoded PKCS #7 file.**
4. On the **Submit a Certificate Request or Renewal Request** page:
   1. In the **Saved Request** box, copy/paste the certificate request generated previously.
   2. In the **Certificate Template** dropdown list, select **Technology Toolbox Web Server**.
   3. Click **Submit >**.
5. When prompted to allow the Web site to perform a digital certificate operation on your behalf, click **Yes**.
6. On the **Certificate Issued** page, ensure the **DER encoded** option is selected and click **Download certificate**. When prompted to save the certificate file, click **Save**.
7. After the file is saved, open the download location in Windows Explorer and copy the certificate file to the AD FS server.

---

```PowerShell
cls
```

#### # Import certificate

```PowerShell
$certFile = "C:\Users\Administrator.CONTOSO\Downloads\certnew.cer"

Import-Certificate `
    -FilePath $certFile `
    -CertStoreLocation Cert:\LocalMachine\My

If ($? -eq $true)
{
    Remove-Item $certFile -Verbose
}
```

## Deploy federation server farm

**Deploying a Federation Server Farm**\
From <[https://technet.microsoft.com/en-us/library/dn486775.aspx](https://technet.microsoft.com/en-us/library/dn486775.aspx)>

```PowerShell
cls
```

### # Add AD FS server role

```PowerShell
Install-WindowsFeature ADFS-Federation -IncludeManagementTools
```

### Create AD FS farm

1. On the Server Manager **Dashboard** page, click the **Notifications** flag, and then click **Configure the federation service on the server**.
The **Active Directory Federation Service Configuration Wizard** opens.
2. On the **Welcome** page, select **Create the first federation server in a federation server farm**, and then click **Next**.
3. On the **Connect to Active Directory Domain Services** page, specify an account with domain administrator permissions for the Active Directory domain to which this computer is joined, and then click **Next**.
4. On the **Specify Service Properties** page:
   1. In the **SSL Certificate** dropdown list, select **fs.contoso.com**.
   2. In the **Federation Service Display Name** box, type **Contoso Pharmaceuticals**.
   3. Click **Next**.
5. On the **Specify Service Account** page:
   1. Ensure **Create a Group Managed Service Account** is selected.
   2. In the **Account Name** box, type **s-adfs**.
   3. Click **Next**.
6. On the **Specify Configuration Database** page:
   1. Ensure **Create a database on this server using Windows Internal Database **is selected.
   2. Click **Next**.
7. On the **Review Options** page, verify your configuration selections, and then click **Next**.
8. On the **Pre-requisite Checks** page, verify that all prerequisite checks are successfully completed, and then click **Configure**.
9. On the **Results** page:
   1. Review the results and verify the configuration completed successfully.
   2. Click **Next steps required for completing your federation service deployment**.
   3. Click **Close** to exit the wizard.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/58/DD52C95FC9552A750F9087C85FB26CC83F8AF958.png)

A machine restart is required to complete ADFS service configuration. For more information, see: [http://go.microsoft.com/fwlink/?LinkId=798725](http://go.microsoft.com/fwlink/?LinkId=798725)

The SSL certificate subject alternative names do not support host name 'certauth.fs.contoso.com'. Configuring certificate authentication binding on port '49443' and hostname 'fs.contoso.com'.

#### # Restart the machine

```PowerShell
Restart-Computer
```

### Configure name resolution for AD FS services

---

**CON-DC1**

#### # Create A record - "fs.contoso.com"

```PowerShell
Add-DnsServerResourceRecordA `
    -Name "fs" `
    -IPv4Address 10.1.60.101 `
    -ZoneName "contoso.com"
```

---

> **Important**
>
> A DNS Host (A) record must be used. There are known issues if you attempt to use a CNAME record with AD FS.
>
> #### References
>
> **A federated user is repeatedly prompted for credentials during sign-in to Office 365, Azure, or Intune**\
> From <[https://support.microsoft.com/en-us/kb/2461628](https://support.microsoft.com/en-us/kb/2461628)>
>
> "...if you create a CNAME and point that to the server hosting ADFS chances are that you will run into a never ending authentication prompt situation."
>
> From <[http://blogs.technet.com/b/rmilne/archive/2014/04/28/how-to-install-adfs-2012-r2-for-office-365.aspx](http://blogs.technet.com/b/rmilne/archive/2014/04/28/how-to-install-adfs-2012-r2-for-office-365.aspx)>

```PowerShell
cls
```

### # Extend validity period for self-signed certificates in AD FS

```PowerShell
Set-AdfsProperties -CertificateDuration (365*5)

Update-AdfsCertificate -Urgent
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

## Install Wireshark

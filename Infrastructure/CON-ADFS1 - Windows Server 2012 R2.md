# CON-ADFS1 - Windows Server 2012 R2

Tuesday, December 6, 2016
10:18 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "STORM"
$vmName = "CON-ADFS1"
$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path C:\NotBackedUp\VMs `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 2GB `
    -SwitchName "Production"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 2 `
    -StaticMemory

Set-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path \\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso

Start-VM -ComputerName $vmHost -Name $vmName
```

---

## Install custom Windows Server 2012 R2 image

- Start-up disk: [\\\\ICEMAN\\Products\\Microsoft\\MDT-Deploy-x86.iso](\\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso)
- On the **Task Sequence** step, select **Windows Server 2012 R2** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **CON-ADFS1**.
  - Select **Join a workgroup**.
  - In the **Workgroup** box, type **WORKGROUP**.
  - Click **Next**.
- On the Applications step:
  - Click **Next**.

```PowerShell
cls
```

## # Rename local Administrator account and set password

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

$password = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted for the secure string, type the password for the Administrator account.

```PowerShell
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

$adminUser = [ADSI] 'WinNT://./Administrator,User'
$adminUser.Rename('foo')
$adminUser.SetPassword($plainPassword)

logoff
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Remove disk from virtual CD/DVD drive

```PowerShell
$vmHost = "STORM"
$vmName = "CON-ADFS1"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

---

```PowerShell
cls
```

## # Change drive letter for DVD-ROM

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
```

## # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

```PowerShell
cls
```

## # Configure network settings

### # Rename network connection

```PowerShell
$interfaceAlias = "Production"

Get-NetAdapter -Physical

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

### # Configure static IP addresses

#### # Configure static IPv4 address

```PowerShell
$ipAddress = "192.168.10.233"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24 `
    -DefaultGateway 192.168.10.1
```

> **Note**
>
> After changing the IP address, Windows prompts for the network type (i.e. public or private).
>
> ![(screenshot)](https://assets.technologytoolbox.com/screenshots/7C/BCBC2F0342930D979E1DCC74C4230476C06C727C.png)

```PowerShell
cls
```

#### # Configure IPv4 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 192.168.10.231, 192.168.10.232
```

#### # Configure static IPv6 address

```PowerShell
$ipAddress = "2603:300b:802:8900::233"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress
```

##### # Configure IPv6 DNS server

```PowerShell
Set-DnsClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 2603:300b:802:8900::231, 2603:300b:802:8900::232
```

### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

ping CON-DC1 -f -l 8900
```

```PowerShell
cls
```

### # Join member server to domain

```PowerShell
Add-Computer `
    -DomainName corp.contoso.com `
    -Credential (Get-Credential CONTOSO\Administrator) `
    -Restart
```

> **Note**
>
> Wait for the machine to restart and then login as **CON-ADFS1\\foo**.

### # Enable remote desktop

```PowerShell
Set-ItemProperty `
    -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" `
    -Name fDenyTSConnections `
    -Value 0

Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
```

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

### Enroll SSL certificate for AD FS

#### # Create certificate request

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\New-CertificateRequest.ps1 `
    -Subject "CN=fs.contoso.com,OU=IT,O=Contoso Pharmaceuticals,L=San Diego,S=CA,C=US" `
    -SANs fs.contoso.com,enterpriseregistration.corp.contoso.com
```

#### # Submit certificate request to Active Directory Certificate Services

##### # Add ADCS website to the "Trusted sites" zone in Internet Explorer

```PowerShell
[string] $adcsUrl = "https://cipher01.corp.technologytoolbox.com"

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-InternetSecurityZoneMapping.ps1 `
    -Zone LocalIntranet `
    -Patterns $adcsUrl
```

##### # Open Internet Explorer and browse to the ADCS site

```PowerShell
& 'C:\Program Files (x86)\Internet Explorer\iexplore.exe' $adcsUrl
```

##### Request certificate

1. On the **Welcome** page of the Active Directory Certificate Services site, in the **Select a task** section, click **Request a certificate**.
2. On the **Advanced Certificate Request** page, click **Submit a certificate request by using a base-64-encoded CMC or PKCS #10 file, or submit a renewal request by using a base-64-encoded PKCS #7 file.**
3. On the **Submit a Certificate Request or Renewal Request** page:
   1. In the **Saved Request** box, copy/paste the certificate request generated previously.
   2. In the **Certificate Template** dropdown list, select **Technology Toolbox Web Server**.
   3. Click **Submit >**.
4. When prompted to allow the Web site to perform a digital certificate operation on your behalf, click **Yes**.
5. On the **Certificate Issued** page, ensure the **DER encoded** option is selected and click **Download certificate**. When prompted to save the certificate file, click **Save**.
6. After the file is saved, open the download location in Windows Explorer and copy the path to the certificate file.

#### # Import certificate

```PowerShell
Import-Certificate `
    -FilePath "C:\Users\Administrator\Downloads\certnew.cer" `
    -CertStoreLocation Cert:\LocalMachine\My
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

```PowerShell
cls
```

### # Create AD FS farm

```PowerShell
$cert = Get-ChildItem -Path Cert:\LocalMachine\My |
    Where { $_.Subject -like "CN=fs.contoso.com,*" }

Import-Module ADFS

$installationCredential = Get-Credential CONTOSO\Administrator
```

> **Note**
>
> When prompted, type the password for the domain administrator account.

```PowerShell
Install-AdfsFarm `
    -CertificateThumbprint $cert.Thumbprint `
    -Credential $installationCredential `
    -FederationServiceDisplayName "Contoso Pharmaceuticals" `
    -FederationServiceName fs.contoso.com `
    -GroupServiceAccountIdentifier "CONTOSO\s-adfs`$"
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AB/3E9659DFEDD2CB880B2B5F0F9CFFA0F43C68A7AB.png)

#### # Restart the machine

```PowerShell
Restart-Computer
```

### Configure name resolution for AD FS services

---

**CON-DC1**

#### # Create zone - "contoso.com"

```PowerShell
Add-DnsServerPrimaryZone -Name contoso.com -ReplicationScope Forest
```

#### # Create A record - "fs.contoso.com"

```PowerShell
Add-DnsServerResourceRecordA -Name fs -IPv4Address 192.168.10.233 -ZoneName contoso.com
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

## Configure SAML-based claims authentication for SecuritasConnect

**Configure SAML-based claims authentication with AD FS in SharePoint 2013**\
From <[https://technet.microsoft.com/en-us/library/hh305235.aspx](https://technet.microsoft.com/en-us/library/hh305235.aspx)>

### Configure AD FS for a relying party

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A9/1A2A9B693602AB83AE70679E3C6E4BC5C3A897A9.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7C/CE5D2ACA15130FEC1DDD92DA2C28DECDE352177C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/66/E6497979EDB38928014DEEF533DFB62A249EE166.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B8/02E7438C9F6E14297E4A6595326DE0C7A15FCDB8.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3F/64C20D03B780955F8AB6A9F55EA0177DE28EAD3F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AD/0FFEE9494D540725C2F33F5145CA0DE6AC7997AD.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A3/BA79737A135A1EED5342EDA34067AF7FF03373A3.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3B/C41A7C4C86AF64FD877A2A0FFCEBFD3F3E6FDA3B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/77/E2B838567E091651F687403CD36F154B1AF5B377.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/12/B293139B7A93C06EA0E18AC44103D1CC515AEC12.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A8/B6878427FB8AA53BE2169485DBA667A25607B4A8.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/62/729A6CBF4D96F35A769D95FDD65D6C4F9930C162.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C2/5C1FE5B7AE6BF64E1FE4B0DABC2923F96F5646C2.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CD/F02F79505BCC37987CFDD0F35917A89DDE9CA9CD.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A6/9909B3C6417B41A8D43EEE9DD2E755AFF6E883A6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/00/640C5A26709C6B67B324E316490CB543ACAD8A00.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FC/9E8947EA5FA0239F551589CFB7DC2D6504A5A4FC.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/19/5571D6DDB146A08922B431E4E099050139F53019.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/92/0E9806DC1C1AA31A13AC573DA5BBA1A716360F92.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/76/7C955DD1216A40FB7613888A0CE47449DB142276.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/86/C46725540493066144301F683FEBB07D45DB7986.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/13/7259248996C177CDD8C0EBB6336A92DE3C234113.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/25/CBF0F4077D13F74D804451D4E9EA197CF265B925.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/40/F84B50F5FA5DB6DA2E75242E1C69FA4B6B044340.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B8/5BF0F650BD7D2AB0E1C2B5170CFADE0A22C3C4B8.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/78/DAF1F2DA87F20F1C0CD1CDA468BDBB46A3B73A78.png)

### Configure the claim rule

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B3/CFC39B63E9BEE272E4619B77D0C05447885708B3.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AF/9CD55FF1E32816DEA162B52EAFB08E2FA9B70CAF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A7/F9CB924E85465B86523D537A4F9EFB73DC2ED1A7.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/12/960CB969CBE54CCEF60AE3FD696490CB9B061412.png)

## # Configure alternate login ID

```PowerShell
Set-AdfsClaimsProviderTrust `
    -TargetIdentifier "AD AUTHORITY" `
    -AlternateLoginID mail `
    -LookupForests corp.contoso.com
```

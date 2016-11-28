# FAB-ADFS02 - Windows Server 2016

Monday, November 28, 2016
6:13 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

### Install Windows Server 2016

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Create virtual machine

```PowerShell
$vmHost = "STORM"
$vmName = "FAB-ADFS02"
$vmPath = "E:\NotBackedUp\VMs"
$isoPath = ("\\ICEMAN\Products\Microsoft\Windows Server 2016" `
    + "\en_windows_server_2016_x64_dvd_9327751.iso")

$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 2GB `
    -SwitchName "Production"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 2

Set-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path $isoPath

Start-VM -ComputerName $vmHost -Name $vmName
```

---

#### Install Windows Server 2016

- On the **Task Sequence** step, select **Windows Server 2012 R2** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **EXT-APP02A**.
  - Select **Join a workgroup**.
  - In the **Workgroup **box, type **WORKGROUP**.
  - Click **Next**.
- On the **Applications** step, ensure no items are selected and click **Next**.

#### # Set time zone

```PowerShell
tzutil /s "Mountain Standard Time"
```

#### # Copy latest Toolbox content

```PowerShell
net use \\ICEMAN\Public /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```Console
robocopy \\ICEMAN\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E /MIR
```

#### # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

#### # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

```PowerShell
cls
```

### # Configure network settings

#### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select Name, InterfaceDescription

Get-NetAdapter `
    -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "Production"
```

#### # Configure "Production" network adapter

```PowerShell
$interfaceAlias = "Production"
```

##### # Configure IPv4 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 192.168.10.201,192.168.10.202
```

##### # Configure IPv6 DNS servers

```PowerShell
Set-DnsClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 2603:300b:802:8900::201, 2603:300b:802:8900::202
```

##### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping iceman.corp.technologytoolbox.com -f -l 8900
```

```PowerShell
cls
```

### # Rename computer

```PowerShell
Rename-Computer -NewName FAB-ADFS02 -Restart
```

### # Join member server to domain

#### # Add computer to domain

```PowerShell
Add-Computer `
    -DomainName corp.fabrikam.com `
    -Credential (Get-Credential FABRIKAM\jjameson-admin) `
    -Restart
```

#### Move computer to "SharePoint Servers" OU

---

**EXT-DC01 - Run as EXTRANET\\jjameson-admin**

```PowerShell
$computerName = "FAB-ADFS02"
$targetPath = "OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=fabrikam,DC=com"

Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath
```

---

### # Set MaxPatchCacheSize to 0 (Recommended)

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

### # Change drive letter for DVD-ROM

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
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

**FAB-DC01**

```PowerShell
Add-KdsRootKey -EffectiveTime (Get-Date).AddHours(-10)
```

---

### Enroll SSL certificate for AD FS

#### # Create certificate request

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\New-CertificateRequest.ps1 `
    -Subject "CN=fs.fabrikam.com,OU=IT,O=Fabrikam Technologies,L=Denver,S=CO,C=US" `
    -SANs fs.fabrikam.com,enterpriseregistration.corp.fabrikam.com
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
    -FilePath "C:\Users\jjameson-admin\Downloads\certnew.cer" `
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

### Create AD FS farm

1. On the Server Manager **Dashboard** page, click the **Notifications** flag, and then click **Configure the federation service on the server**.
The **Active Directory Federation Service Configuration Wizard** opens.
2. On the **Welcome** page, select **Create the first federation server in a federation server farm**, and then click **Next**.
3. On the **Connect to Active Directory Domain Services** page, specify an account with domain administrator permissions for the Active Directory domain to which this computer is joined, and then click **Next**.
4. On the **Specify Service Properties** page:
   1. In the **SSL Certificate** dropdown list, select **fs.fabrikam.com**.
   2. In the **Federation Service Display Name** box, type **Fabrikam Technologies**.
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

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D1/EB015E9716674544DD5685FA012F1DBEB7E113D1.png)

A machine restart is required to complete ADFS service configuration. For more information, see: [http://go.microsoft.com/fwlink/?LinkId=798725](http://go.microsoft.com/fwlink/?LinkId=798725)

The SSL certificate subject alternative names do not support host name 'certauth.fs.fabrikam.com'. Configuring certificate authentication binding on port '49443' and hostname 'fs.fabrikam.com'.

#### # Restart the machine

```PowerShell
Restart-Computer
```

### Configure name resolution for AD FS services

---

**FAB-DC01**

#### # Create A record - "fs.fabrikam.com"

```PowerShell
Add-DnsServerResourceRecordA `
    -Name "fs" `
    -IPv4Address 192.168.10.9 `
    -ZoneName "fabrikam.com"
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

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CE/1CE81C0CAE3EC1F6A643131C4ED51AE9358121CE.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/87/87B390B4AEAAF22508DB60C9A3B4CDA21BA08B87.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1A/607DDDAA50B46B27153E2BB51ED8B7734C7BE51A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F9/38966C2EFD06871ECBC1DCEA7AF65BEC194854F9.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7C/8E04895733FD0BAECEE2770B27723F14F37C7A7C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4F/423F04CC7771D3C5B35C0FF48A8FFE2D76BD9A4F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/96/B95B1102917C746060E159EA5FAC209696BA2F96.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DE/60BCD48E917176CFA3EEC31AFCF5C7ECF2758FDE.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EF/1FDE3196C20F8C93ECA3D13C0FDB3A1A8FBACCEF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/63/557FC9D3A85D2AA0D21F9462FB843043059B1563.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5C/C65655E9DBC535699682257CEA205428928B605C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D1/C0253CA6E945C90C7BCF8AE3C260A99F80DC1ED1.png)

### Configure the claim rule

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1B/10331D0987D56CD40E5C27E3B117A1C5F771511B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3B/E23AEBFCB13328E48526648AC47449717E94E73B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DB/C3495D2B2A755FC7668669A00DDEAB904258CEDB.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/15/83B89CF9AC1D679C1BDA5615E0AB0C1186ED0B15.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/19/4AA3A16D9E765C8B5E3E53EDA948D6B67C32E219.png)

### Export the token signing certificate

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9D/8EF0047F9B3F5EC7D08458B8C0064D68EEDE0C9D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/00/5676B027D7ACCED5273B6437253F4DFDD2C38D00.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6F/CB7F64E55C60E8968AA90A038364DAA01189676F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EF/3EDC2106856C070AF5E6D3ED610E30EF76EA5DEF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E6/54A9EDD43268EEED727857568498FE867D78ACE6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/96/578BB84AE2DD0BB2AF0B085251006565E45C8C96.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0E/F393492A8E78D4A9F5376C17164DED9B30F4B80E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6A/59FF9A0B43CDB1F9B3FA385EEC89D94AB63A3C6A.png)

### Phase 3: Configure SharePoint 2013 to trust AD FS as an identity provider

#### # Copy token-signing certificate from ADFS server

```PowerShell
net use \\ext-foobar9.extranet.technologytoolbox.com\C$ `
    /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
copy `
    'C:\Users\jjameson-admin\Desktop\ADFS Signing - fs.fabrikam.com.cer' `
    \\ext-foobar9.extranet.technologytoolbox.com\C$\Users\jjameson\Desktop `
```

---

**EXT-FOOBAR9 - Run as TECHTOOLBOX\\jjameson-admin**

#### # Import token signing certificate

```PowerShell
Enable-SharePointCmdlets

$cert = `
    New-Object System.Security.Cryptography.X509Certificates.X509Certificate2(
        "C:\Users\jjameson\Desktop\ADFS Signing - fs.fabrikam.com.cer")

New-SPTrustedRootAuthority `
    -Name "ADFS Signing - fs.fabrikam.com" `
    -Certificate $cert
```

```PowerShell
cls
```

#### # Define claim mappings and identifier claim

```PowerShell
$emailClaimMapping = New-SPClaimTypeMapping `
    -IncomingClaimType "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress" `
    -IncomingClaimTypeDisplayName "EmailAddress" `
    -SameAsIncoming

$upnClaimMapping = New-SPClaimTypeMapping `
    -IncomingClaimType "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn" `
    -IncomingClaimTypeDisplayName "UPN" `
    -SameAsIncoming

$roleClaimMapping = New-SPClaimTypeMapping `
    -IncomingClaimType "http://schemas.xmlsoap.org/ws/2008/06/identity/claims/role" `
    -IncomingClaimTypeDisplayName "Role" `
    -SameAsIncoming

$sidClaimMapping = New-SPClaimTypeMapping `
    -IncomingClaimType "http://schemas.microsoft.com/ws/2008/06/identity/claims/primarysid" `
    -IncomingClaimTypeDisplayName "SID" `
    -SameAsIncoming

$claimsMappings = @(
    $emailClaimMapping,
    $upnClaimMapping,
    $roleClaimMapping,
    $sidClaimMapping)

$identifierClaim = $emailClaimMapping.InputClaimType
```

```PowerShell
cls
```

#### # Create authentication provider

```PowerShell
$realm = "urn:sharepoint:securitas:client-local-9"
$signInURL = "https://fs.fabrikam.com/adfs/ls"

$authProvider = New-SPTrustedIdentityTokenIssuer `
    -Name "SAML Provider for client-local-9.securitasinc.com" `
    -Description "AD FS provider for SecuritasConnect" `
    -Realm $realm `
    -ImportTrustCertificate $cert `
    -ClaimsMappings  $claimsMappings `
    -SignInUrl $signInURL `
    -IdentifierClaim $identifierClaim
```

---

### Phase 4: Configure web applications to use claims-based authentication and AD FS as the trusted identity provider

---

**EXT-FOOBAR9 - Run as TECHTOOLBOX\\jjameson-admin**

#### # Configure SSL on SecuritasConnect Web application

##### # Install SSL certificate

```PowerShell
net use \\ICEMAN\Archive /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$certPassword = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted for the secure string, type the password for the exported certificate.

```PowerShell
Import-PfxCertificate `
    -FilePath "\\ICEMAN\Archive\Clients\Securitas\securitasinc.com.pfx" `
    -CertStoreLocation Cert:\LocalMachine\My `
    -Password $certPassword
```

##### Add public URL for HTTPS

##### Add HTTPS binding to site in IIS

Site: **SharePoint - client2-local-9.securitasinc.com**\
Host name: **client2-local-9.securitasinc.com**\
SSL certificate: **\*.securitasinc.com**

#### # Associate an existing web application with the AD FS identity provider

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D8/7F642FAA44021E95DB1A7A6FD9F2677B23C0BDD8.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1E/A24CA7BB784A301C0B2F807A037A4A6A11DD241E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D7/261788A78C597B7B328B3AA6A02A1D0BCDE47DD7.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5F/01BB4D5580C26AE349696606E5DF0FD68E8D2D5F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C8/080412076DB3F2C0DDDF29CB285C35D7535912C8.png)

---

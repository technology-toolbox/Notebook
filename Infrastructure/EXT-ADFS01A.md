# EXT-ADFS01A

Tuesday, January 24, 2017
5:48 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create service account for ADFS

```PowerShell
$displayName = "Service account for ADFS farm (EXT-ADFS01)"
$defaultUserName = "s-adfs01"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@corp.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=IT,DC=corp,DC=technologytoolbox,DC=com"

New-ADUser `
    -Name $displayName `
    -DisplayName $displayName `
    -SamAccountName $cred.UserName `
    -AccountPassword $cred.Password `
    -UserPrincipalName $userPrincipalName `
    -Path $orgUnit `
    -Enabled:$true `
    -CannotChangePassword:$true `
    -PasswordNeverExpires:$true
```

---

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV02A"
$vmName = "EXT-ADFS01A"
$vmPath = "E:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"
$sysPrepedImage = "\\TT-FS01\VM-Library\VHDs\WS2016-Std.vhdx"

$vhdUncPath = $vhdPath.Replace("E:", "\\TT-HV02A\E$")

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 2GB `
    -SwitchName "Tenant vSwitch"

Copy-Item $sysPrepedImage $vhdUncPath

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 2 `
    -DynamicMemory `
    -MemoryMaximumBytes 4GB

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Set password for the local Administrator account

```PowerShell
cls
```

### # Rename local Administrator account

```PowerShell
$adminUser = [ADSI] 'WinNT://./Administrator,User'

$adminUser.Rename('foo')

logoff
```

```PowerShell
cls
```

### # Configure networking

```PowerShell
$interfaceAlias = "Datacenter"
```

#### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

#### # Configure static IPv4 address

```PowerShell
$ipAddress = "192.168.10.226"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24 `
    -DefaultGateway 192.168.10.1
```

#### # Configure IPv4 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 192.168.10.209,192.168.10.210
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping iceman.corp.technologytoolbox.com -f -l 8900
```

### Rename server and join domain

#### Login as local administrator account

```PowerShell
cls
```

### # Rename server

```PowerShell
Rename-Computer -NewName EXT-ADFS01A -Restart
```

> **Note**
>
> Wait for the VM to restart.

#### Login as local administrator account

```PowerShell
cls
```

### # Join server to domain

```PowerShell
Add-Computer -DomainName extranet.technologytoolbox.com -Restart
```

---

**EXT-DC01 - Run as EXTRANET\\jjameson-admin**

```PowerShell
cls
```

### # Move computer to different OU

```PowerShell
$vmName = "EXT-ADFS01A"

$targetPath = ("OU=Servers,OU=Resources,OU=IT" `
    + ",DC=extranet,DC=technologytoolbox,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

---

```PowerShell
cls
```

### # Set time zone

```PowerShell
tzutil /s "Mountain Standard Time"
```

### # Copy Toolbox content

```PowerShell
$source = "\\TT-FS01\Public\Toolbox"
$destination = "C:\NotBackedUp\Public\Toolbox"

robocopy $source $destination  /E /XD "Microsoft SDKs"
```

### # Set MaxPatchCacheSize to 0 (recommended)

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

```PowerShell
cls
```

## # Configure storage

## # Change drive letter for DVD-ROM

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
```

## AD FS prerequisites

### Enroll SSL certificate for AD FS

#### # Create certificate request

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\New-CertificateRequest.ps1 `
    -Subject "CN=fs.technologytoolbox.com,OU=IT,O=Technology Toolbox,L=Denver,S=CO,C=US" `
    -SANs fs.technologytoolbox.com, certauth.fs.technologytoolbox.com, `
        enterpriseregistration.corp.technologytoolbox.com
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
   2. In the **Certificate Template** dropdown list, select **Technology Toolbox Web Server - Exportable**.
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

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Checkpoint VM

```PowerShell
$vmHost = "TT-HV02A"
$vmName = "EXT-ADFS01A"
$snapshotName = "Before - Create AD FS farm"

Stop-VM -ComputerName $vmHost -Name $vmName

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName $snapshotName

Start-VM -ComputerName $vmHost -Name $vmName
```

---

```PowerShell
cls
```

### # Create AD FS farm

```PowerShell
$cert = Get-ChildItem -Path Cert:\LocalMachine\My |
    Where { $_.Subject -like "CN=fs.technologytoolbox.com,*" }

$cert

$installationCredential = Get-Credential EXTRANET\jjameson-admin
```

> **Note**
>
> When prompted, type the password for the domain administrator account.

```PowerShell
$serviceAccountCredential = Get-Credential TECHTOOLBOX\s-adfs01
```

> **Note**
>
> When prompted, type the password for the service account.

```PowerShell
Import-Module ADFS

Install-AdfsFarm `
    -CertificateThumbprint $cert.Thumbprint `
    -Credential $installationCredential `
    -FederationServiceDisplayName "Technology Toolbox" `
    -FederationServiceName fs.technologytoolbox.com `
    -ServiceAccountCredential $serviceAccountCredential

WARNING: A machine restart is required to complete ADFS service configuration. For more information, see:
http://go.microsoft.com/fwlink/?LinkId=798725
WARNING: An error occurred during an attempt to set the SPN for the specified service account. Set the SPN for the service account manually.  For more information about setting the SPN of the service account manually, see the AD FS
Deployment Guide.  Error message: An error occurred during an attempt to set the SPN for the specified service account. You do not have sufficient privileges in the domain to set the SPN.
WARNING: Failed to register SSL bindings for Device Registration Service: An item with the same key has already been added..

Message                                   Context              Status
-------                                   -------              ------
The configuration completed successfully. DeploymentSucceeded Success


Restart-Computer
```

### Configure name resolution for AD FS services

---

**XAVIER1**

#### # Create A record - "fs.technologytoolbox.com"

```PowerShell
Add-DnsServerResourceRecordA `
    -Name "fs" `
    -IPv4Address 192.168.10.226 `
    -ZoneName "technologytoolbox.com"
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

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7B/A16AB91610692D28A559185A07D333733976B07B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/06/3B82A4FBB3CF98086964CA3A129EB5FC52F00C06.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1A/607DDDAA50B46B27153E2BB51ED8B7734C7BE51A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/94/79B44DF8E26EC90116977EE25B53BA9422A33394.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8D/1228BE2E28904129FBEB695F0174255C58720A8D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4F/423F04CC7771D3C5B35C0FF48A8FFE2D76BD9A4F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/89/AB9809C0B2A76FDB40A6657A2E53D6E85258C489.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2D/7603A9E53CEDB1518C4883C2B94080942869662D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/41/6FC109AE140703A81EA1FE9F8DC3F75CB79DAC41.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/63/557FC9D3A85D2AA0D21F9462FB843043059B1563.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5C/C65655E9DBC535699682257CEA205428928B605C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D1/C0253CA6E945C90C7BCF8AE3C260A99F80DC1ED1.png)

### Configure the claim rule

![(screenshot)](https://assets.technologytoolbox.com/screenshots/72/9B60C13031E10F293F11B4F35250E1B692DE0D72.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3B/E23AEBFCB13328E48526648AC47449717E94E73B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DB/C3495D2B2A755FC7668669A00DDEAB904258CEDB.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/15/83B89CF9AC1D679C1BDA5615E0AB0C1186ED0B15.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EE/0F85DE69F6F6CFD7638A808C73CD97B93C7406EE.png)

### Export the token signing certificate

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B3/24EBAD90C8316D653F0CCDE0490E84E4BF150BB3.png)

Right-click the token-signing certificate and click **View Certificate...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AA/B9B444EED6A05F37890FEB5690388DDC7FEBBCAA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5C/16F6DFD269EEEA7B194497276BF5F57D648D985C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EF/3EDC2106856C070AF5E6D3ED610E30EF76EA5DEF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E6/54A9EDD43268EEED727857568498FE867D78ACE6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/86/2B96A5526809347461B44BF394BB759CA2CFFC86.png)

In the **Save As** window:

1. In the **File name** box, type **ADFS Signing - fs.technologytoolbox.com**.
2. Click **Save**.

In the **Certificate Export Wizard**, click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0E/F393492A8E78D4A9F5376C17164DED9B30F4B80E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6A/59FF9A0B43CDB1F9B3FA385EEC89D94AB63A3C6A.png)

### Phase 3: Configure SharePoint 2013 to trust AD FS as an identity provider

#### # Copy token-signing certificate to SharePoint server

```PowerShell
net use \\ext-foobar4.extranet.technologytoolbox.com\C$ `
    /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
copy `
    'C:\Users\jjameson-admin\Desktop\ADFS Signing - fs.technologytoolbox.com.cer' `
    \\ext-foobar4.extranet.technologytoolbox.com\C$\Users\jjameson\Desktop
```

---

**EXT-FOOBAR4 - Run as TECHTOOLBOX\\jjameson**

#### # Import token signing certificate

```PowerShell
Enable-SharePointCmdlets

$cert = `
    New-Object System.Security.Cryptography.X509Certificates.X509Certificate2(
        "C:\Users\jjameson\Desktop\ADFS Signing - fs.technologytoolbox.com.cer")

New-SPTrustedRootAuthority `
    -Name "ADFS Signing - fs.technologytoolbox.com" `
    -Certificate $cert
```

#### # Define claim mappings and identifier claim

```PowerShell
$emailClaimMapping = New-SPClaimTypeMapping `
    -IncomingClaimType "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress" `
    -IncomingClaimTypeDisplayName "EmailAddress" `
    -SameAsIncoming

# Note: http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name is a reserved claim
```

# type in SharePoint

```PowerShell
$nameClaimMapping = New-SPClaimTypeMapping `
    -IncomingClaimType "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name" `
    -IncomingClaimTypeDisplayName "Name" `
    -LocalClaimType "http://schemas.technologytoolbox.com/ws/2017/01/identity/claims/name"

$upnClaimMapping = New-SPClaimTypeMapping `
    -IncomingClaimType "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn" `
    -IncomingClaimTypeDisplayName "UPN" `
    -SameAsIncoming

$roleClaimMapping = New-SPClaimTypeMapping `
    -IncomingClaimType "http://schemas.microsoft.com/ws/2008/06/identity/claims/role" `
    -IncomingClaimTypeDisplayName "Role" `
    -SameAsIncoming

$claimsMappings = @(
    $emailClaimMapping,
    $nameClaimMapping,
    $upnClaimMapping,
    $roleClaimMapping)

$identifierClaim = $emailClaimMapping.InputClaimType
```

#### # Create authentication provider

```PowerShell
$realm = "urn:sharepoint:securitas"
$signInURL = "https://fs.technologytoolbox.com/adfs/ls"

$authProvider = New-SPTrustedIdentityTokenIssuer `
    -Name "ADFS" `
    -Description "Active Directory Federation Services provider" `
    -Realm $realm `
    -ImportTrustCertificate $cert `
    -ClaimsMappings  $claimsMappings `
    -SignInUrl $signInURL `
    -IdentifierClaim $identifierClaim
```

#### # Configure authentication provider for SecuritasConnect

```PowerShell
$uri = New-Object System.Uri("https://client-local-4.securitasinc.com")
$realm = "urn:sharepoint:securitas:client-local-4"

$authProvider.ProviderRealms.Add($uri, $realm)
$authProvider.Update()
```

---

### Phase 4: Configure web applications to use claims-based authentication and AD FS as the trusted identity provider

---

**EXT-FOOBAR4 - Run as TECHTOOLBOX\\jjameson**

#### Associate web applications with the ADFS identity provider

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A7/E1DE75F7C1D3037A4F0AABCEBEE6BA0A5778DCA7.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/84/620022B90B3B71CAA21A62FD140FF018E7504A84.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/31/B4243F052D0EBEC99B73A0F15027860A1C42FA31.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/38/D1B9B666C17685E74483BCBD71FC46558F4DA838.png)

In the **Authentication Providers** window, click **Default**.

In the **Anonymous Access** section, clear the **Enable anonymous access** checkbox.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/12/568902A53BE28048858B9DF152BF9674E8FB1812.png)

In the **Claims Authentication Types** section:

1. Clear the **Enable Windows Authentication** checkbox.
2. Clear the **Enable Forms Based Authentication (FBA)** checkbox.
3. Select the **Trusted Identity provider** checkbox.
4. Select the checkbox for the **ADFS** Trusted Identity Provider.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/07/F372189109BBA6E860CE65D9569C2323B892E907.png)

In the **Sign In Page URL** section, select **Default Sign In Page**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/61/4CF5C3C8C5B9401ED71A66A8947853CE5C8FB561.png)

Click **Save**.

---

### Customize the AD FS sign-in pages

#### Reference

**Customizing the AD FS Sign-in Pages**\
From <[https://technet.microsoft.com/library/dn280950.aspx](https://technet.microsoft.com/library/dn280950.aspx)>

```PowerShell
cls
```

#### # Customize the AD FS sign-in page for SecuritasConnect

```PowerShell
$relyingPartyTrustName = "client-local-4.securitasinc.com"
$companyName = "SecuritasConnect"
$organizationalNameDescriptionText = "Sign in with your SecuritasConnect credentials or your organizational account (if supported)"

$signInPageDescription = "<p>SecuritasConnect is a powerful tool that can improve the efficiency of your security program and enhance the performance of your team. No paper logbooks or handwritten reports. Everything is recorded and available online.</p><p>&nbsp;</p><p>SecuritasConnect is your direct link to key and relevant information needed to manage your security program. Accessible through any internet connection, the features and tools in Connect help you stay on top of what's happening down the hall or around the world, allowing you to monitor and protect your interests day and night.</p>"

#$illustrationPath = "C:\NotBackedUp\Temp\SecuritasConnect-1420x1080.png"
$illustrationPath = "C:\NotBackedUp\Temp\ADFS_splash_v1-01.jpg"

Set-AdfsRelyingPartyWebContent `
    -TargetRelyingPartyName $relyingPartyTrustName `
    -CompanyName $companyName `
    -OrganizationalNameDescriptionText $organizationalNameDescriptionText `
    -SignInPageDescription $signInPageDescription

Set-AdfsRelyingPartyWebTheme `
    -TargetRelyingPartyName $relyingPartyTrustName `
    -Illustration @{path=$illustrationPath}
```

#### # Revert customizations for SecuritasConnect (demo)

```PowerShell
$relyingPartyTrustName = "client-local-4.securitasinc.com"
$companyName = $null
$organizationalNameDescriptionText = $null
$signInPageDescription = $null
$illustrationPath = $null

Set-AdfsRelyingPartyWebContent `
    -TargetRelyingPartyName $relyingPartyTrustName `
    -CompanyName $companyName `
    -OrganizationalNameDescriptionText $organizationalNameDescriptionText `
    -SignInPageDescription $signInPageDescription

Set-AdfsRelyingPartyWebTheme `
    -TargetRelyingPartyName $relyingPartyTrustName `
    -Illustration @{path=$illustrationPath}
```

```PowerShell
cls
```

## # Configure claims provider trust for Contoso

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    -IPAddress 192.168.10.233 `
    -Hostnames fs.contoso.com
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6D/CB602CAE1566470CA8F3BC2E9EAB6132D6008C6D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2F/DD1910BA8F6AE78C00C82B20593CB41D8B8BD02F.png)

**[https://fs.contoso.com/federationmetadata/2007-06/federationmetadata.xml](https://fs.contoso.com/federationmetadata/2007-06/federationmetadata.xml)**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/86/D8B080A53B0B76217A471071215F2F877885B686.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/ED/4421084548D03A492CC5DF11D18922B4CAEDF8ED.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9E/5A0A7D524A794F1DB169C4C6FA26D88FAA7CA29E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E2/38DA58BC55EEF13586F819A3E5F95C553D0B4CE2.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/34/F51DA62281CC644464C0D0F7524CC3521420DD34.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/46/A154911313189EF6DC96A8ADCEBC49EF70695E46.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3B/E23AEBFCB13328E48526648AC47449717E94E73B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/67/87BDA6F851FB8A53FF87EAC9AF424ADDE3566267.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/20/4C46FB0D6BA4B19551431471C451F99141AA7B20.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6F/D6EC718CB995FE61ACC2B2F5B892B419B934A76F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A9/C22BAB8B2EDF42FA2B7325D7FFEBDA366C048EA9.png)

[https://fs.contoso.com/adfs/ls/?wa=wsignin1.0&wtrealm=http%3a%2f%2ffs.fabrikam.com%2fadfs%2fservices%2ftrust&wctx=9ab97163-e20c-45e5-840f-6f14462d6356](https://fs.contoso.com/adfs/ls/?wa=wsignin1.0&wtrealm=http%3a%2f%2ffs.fabrikam.com%2fadfs%2fservices%2ftrust&wctx=9ab97163-e20c-45e5-840f-6f14462d6356)

```PowerShell
cls
```

## # Customize home realm discovery

```PowerShell
Set-AdfsClaimsProviderTrust `
    -TargetName "Contoso Pharmaceuticals" `
    -OrganizationalAccountSuffix @("contoso.com")
```

### Reference

**Customize the Home Realm Discovery page to ask for UPN right away**\
From <[https://blogs.technet.microsoft.com/pie/2015/10/18/customize-the-home-realm-discovery-page-to-ask-for-upn-right-away/](https://blogs.technet.microsoft.com/pie/2015/10/18/customize-the-home-realm-discovery-page-to-ask-for-upn-right-away/)>

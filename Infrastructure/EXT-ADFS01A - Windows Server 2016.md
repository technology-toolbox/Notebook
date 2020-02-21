# EXT-ADFS01A - Windows Server 2016

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

### # Create and configure service account for ADFS

#### # Create service account for ADFS

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

#### # Configure Service Principal Name for ADFS service account

```PowerShell
setspn -S host/fs.technologytoolbox.com $cred.UserName
```

#### Reference

**Manually Configure a Service Account for a Federation Server Farm**\
From <[https://technet.microsoft.com/en-us/library/dd807078(v=ws.11).aspx](https://technet.microsoft.com/en-us/library/dd807078(v=ws.11).aspx)>

---

---

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

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

### Configure networking

---

**TT-VMM01A**

```PowerShell
cls
```

#### # Configure static IP address using VMM

```PowerShell
$vmName = "EXT-ADFS01A"

$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"

$vmNetwork = Get-SCVMNetwork -Name "Extranet VM Network"

$ipPool = Get-SCStaticIPAddressPool -Name "Extranet Address Pool"

$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName |
    ? { $_.SlotId -eq 0 }

Stop-SCVirtualMachine $vmName

$macAddress = Grant-SCMACAddress `
    -MACAddressPool $macAddressPool `
    -Description $vmName `
    -VirtualNetworkAdapter $networkAdapter

Set-SCVirtualNetworkAdapte
$inter
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

#### # Rename network connections

```PowerShell
$interfaceAlias = "Extranet-20"

Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
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

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7F/983BF1918905BAE459E22149D16968191BA3337F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EE/0F85DE69F6F6CFD7638A808C73CD97B93C7406EE.png)

### Export the token signing certificate

![(screenshot)](https://assets.technologytoolbox.com/screenshots/75/0ECB37338DC24D1C97BD8CB04A1D2F1539EF5675.png)

Right-click the token-signing certificate and click **View Certificate...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F8/12A2A8DF665D7B16A552AD7793C8B4BBDA88C4F8.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C3/572AEB343EFACC4B9125498ED10653CF52C8B4C3.png)

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
    /USER:EXTRANET\setup-sharepoint-dev
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
copy `
    'C:\Users\jjameson-admin\Desktop\ADFS Signing - fs.technologytoolbox.com.cer' `
    \\ext-foobar4.extranet.technologytoolbox.com\C$\Users\setup-sharepoint-dev\Desktop
```

---

**EXT-FOOBAR4** - Run as **EXTRANET\\setup-sharepoint-dev**

```PowerShell
cls
```

#### # Import token signing certificate

```PowerShell
If ((Get-PSSnapin Microsoft.SharePoint.PowerShell `
    -ErrorAction SilentlyContinue) -eq $null)
{
    Write-Debug "Adding snapin (Microsoft.SharePoint.PowerShell)..."

    $ver = $host | select version

    If ($ver.Version.Major -gt 1)
    {
        $Host.Runspace.ThreadOptions = "ReuseThread"
    }

    Add-PSSnapin Microsoft.SharePoint.PowerShell
}

$certPath = "C:\Users\setup-sharepoint-dev\Desktop" `
    + "\ADFS Signing - fs.technologytoolbox.com.cer"

$cert = `
    New-Object System.Security.Cryptography.X509Certificates.X509Certificate2(
        $certPath)

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

# Note: http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name is a reserved
# claim type in SharePoint
```

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

## Customize the AD FS sign-in pages

### References

**Customizing the AD FS Sign-in Pages**\
From <[https://technet.microsoft.com/library/dn280950.aspx](https://technet.microsoft.com/library/dn280950.aspx)>

**Customize the Home Realm Discovery page to ask for UPN right away**\
From <[https://blogs.technet.microsoft.com/pie/2015/10/18/customize-the-home-realm-discovery-page-to-ask-for-upn-right-away/](https://blogs.technet.microsoft.com/pie/2015/10/18/customize-the-home-realm-discovery-page-to-ask-for-upn-right-away/)>

```PowerShell
cls
```

### # Customize the AD FS sign-in page for SecuritasConnect

```PowerShell
$relyingPartyName = "client-local-4.securitasinc.com"
$companyName = "SecuritasConnect"
$organizationalNameDescriptionText = "Enter your Securitas e-mail address and password below."

#$signInPageDescription = "<p>{Placeholder text for employee login page}</p>"
$signInPageDescription = $null

#$illustrationPath = "C:\NotBackedUp\Temp\SecuritasConnect-1420x1080.png"
$illustrationPath = "C:\NotBackedUp\Temp\ADFS_splash_v1-01.jpg"

Set-AdfsRelyingPartyWebContent `
    -TargetRelyingPartyName $relyingPartyName `
    -CompanyName $companyName `
    -OrganizationalNameDescriptionText $organizationalNameDescriptionText `
    -SignInPageDescription $signInPageDescription `
    -HomeRealmDiscoveryOtherOrganizationDescriptionText "Enter your e-mail address below."

Set-AdfsRelyingPartyWebTheme `
    -TargetRelyingPartyName $relyingPartyName `
    -Illustration @{path=$illustrationPath}
```

```PowerShell
cls
```

#### # Create a custom theme

```PowerShell
$themeName = "SecuritasConnect"

New-AdfsWebTheme -Name $themeName -SourceName Default

mkdir "C:\NotBackedUp\Temp\$themeName-Theme"

Export-AdfsWebTheme `
    -Name $themeName `
    -DirectoryPath "C:\NotBackedUp\Temp\$themeName-Theme"

Notepad "C:\NotBackedUp\Temp\$themeName-Theme\script\onload.js"
```

---

File content - **onload.js**

```JavaScript
// -- Begin custom code

var docCookies = {
  getItem: function (sKey) {
    if (!sKey) { return null; }
    return decodeURIComponent(document.cookie.replace(new RegExp("(?:(?:^|.*;)\\s*" + encodeURIComponent(sKey).replace(/[\-\.\+\*]/g, "\\$&") + "\\s*\\=\\s*([^;]*).*$)|^.*$"), "$1")) || null;
  },
  setItem: function (sKey, sValue, vEnd, sPath, sDomain, bSecure) {
    if (!sKey || /^(?:expires|max\-age|path|domain|secure)$/i.test(sKey)) { return false; }
    var sExpires = "";
    if (vEnd) {
      switch (vEnd.constructor) {
        case Number:
          sExpires = vEnd === Infinity ? "; expires=Fri, 31 Dec 9999 23:59:59 GMT" : "; max-age=" + vEnd;
          break;
        case String:
          sExpires = "; expires=" + vEnd;
          break;
        case Date:
          sExpires = "; expires=" + vEnd.toUTCString();
          break;
      }
    }
    document.cookie = encodeURIComponent(sKey) + "=" + encodeURIComponent(sValue) + sExpires + (sDomain ? "; domain=" + sDomain : "") + (sPath ? "; path=" + sPath : "") + (bSecure ? "; secure" : "");
    return true;
  },
  removeItem: function (sKey, sPath, sDomain) {
    if (!this.hasItem(sKey)) { return false; }
    document.cookie = encodeURIComponent(sKey) + "=; expires=Thu, 01 Jan 1970 00:00:00 GMT" + (sDomain ? "; domain=" + sDomain : "") + (sPath ? "; path=" + sPath : "");
    return true;
  },
  hasItem: function (sKey) {
    if (!sKey) { return false; }
    return (new RegExp("(?:^|;\\s*)" + encodeURIComponent(sKey).replace(/[\-\.\+\*]/g, "\\$&") + "\\s*\\=")).test(document.cookie);
  },
  keys: function () {
    var aKeys = document.cookie.replace(/((?:^|\s*;)[^\=]+)(?=;|$)|^\s*|\s*(?:\=[^;]*)?(?:\1|$)/g, "").split(/\s*(?:\=[^;]*)?;\s*/);
    for (var nLen = aKeys.length, nIdx = 0; nIdx < nLen; nIdx++) { aKeys[nIdx] = decodeURIComponent(aKeys[nIdx]); }
    return aKeys;
  }
};

function getParameterByName(name, url) {
  if (!url) {
    url = window.location.href;
  }
  name = name.replace(/[\[\]]/g, "\\$&");
  var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"),
    results = regex.exec(url);

  if (!results) return null;
  if (!results[2]) return '';
  return decodeURIComponent(results[2].replace(/\+/g, " "));
}

// http://stackoverflow.com/questions/1634748/how-can-i-delete-a-query-string-parameter-in-javascript
function removeUrlParameter(url, parameter) {
    //prefer to use l.search if you have a location/link object
    var urlparts= url.split('?');
    if (urlparts.length>=2) {

        var prefix= encodeURIComponent(parameter)+'=';
        var pars= urlparts[1].split(/[&;]/g);

        //reverse iteration as may be destructive
        for (var i= pars.length; i-- > 0;) {
            //idiom for string.startsWith
            if (pars[i].lastIndexOf(prefix, 0) !== -1) {
                pars.splice(i, 1);
            }
        }

        url= urlparts[0] + (pars.length > 0 ? '?' + pars.join('&') : "");
        return url;
    } else {
        return url;
    }
}

function resetLogin() {
    docCookies.removeItem('SecuritasConnectUserName');
    var redirectUrl = window.location.href;

    redirectUrl = removeUrlParameter(redirectUrl, 'RedirectToIdentityProvider');
    redirectUrl = removeUrlParameter(redirectUrl, 'userName');

    window.location.href = redirectUrl;
}

var copyright = document.getElementById("copyright");

copyright.innerHTML = '&copy; 2017 Securitas Security Services USA, Inc.';

var identityProviders = document.querySelectorAll("div[class='idp']");

var childNode;

if (identityProviders) {
    if (identityProviders.length > 0) {
        childNode = identityProviders[0].childNodes[1].childNodes[0];

        if (childNode.innerText === 'Active Directory') {
            childNode.innerText = 'Securitas login';
        }
    }

    if (identityProviders.length > 1) {
        childNode = identityProviders[1].childNodes[1].childNodes[0];

        if (childNode.innerText === 'Other organization') {
            childNode.innerText = 'Client login';
        }
    }
}

var currentUrl = window.location.href;

var hrdAreaElement = document.getElementById('hrdArea');
if (hrdAreaElement) {
    // Immediately show the email input form
    HRD.showEmailInput();

     //Remove the image and the login description message
     //document.getElementsByClassName('groupMargin')[1].innerHTML = "" ;
     //document.getElementsByClassName('groupMargin')[2].innerHTML = "Enter your credentials:" ;

     var userName = docCookies.getItem('SecuritasConnectUserName');

     if (userName) {
        var errorTextElement = document.getElementById('errorText');
        var emailInputAreaElement = document.getElementById('emailInputArea');
        var emailIntroductionElement = document.getElementById('emailIntroduction');

        if (errorTextElement && errorTextElement.innerHTML) {
            // An error occurred in the HRD process (most likely due to email domain not recognized)
        }
        else {
            if (emailInputAreaElement) {
                emailInputAreaElement.innerHTML =
'<div class="idp" tabindex="1">' +
'<img class="largeIcon float" src="/adfs/portal/images/idp/idp.png" alt="User">' +
'<div class="idpDescription float"><span class="largeTextNoWrap indentNonCollapsible">' + userName + '</span></div>' +
'</div>' +
'<input type="HIDDEN" id="emailInput" name="Email" value="' + userName + '" />' +
'<div class="idp" tabindex="1" onkeypress="if (event &amp;&amp; (event.keyCode == 32 || event.keyCode == 13)) resetLogin();" onclick="resetLogin(); return false;">' +
'<img class="largeIcon float" src="/adfs/portal/images/idp/idp.png" alt="User">' +
'<div class="idpDescription float"><span class="largeTextNoWrap indentNonCollapsible">Use another account</span></div>' +
'</div>';
            }
        }
    }

     //Override of the submitEmail function
     HRD.submitEmail = function () {
           var u = new InputUtil() ;
           var e = new HRDErrors() ;
           var email = document.getElementById(HRD.emailInput);

           //Detect if the user typed the AD suffix
           if (email.value.toLowerCase().match('(@technologytoolbox.com)$')) {
                //Calculate the URL to redirect the user to the AD form
                var redirectUrl = currentUrl;

                //Check if the URL has an empty username
                if (redirectUrl.indexOf("username=") != -1 ) {
                     //Discard the old name
                     redirectUrl = redirectUrl.replace("username=","userNameOld=") ;
                }

                if (redirectUrl.indexOf("?") != -1 ) {
                    redirectUrl += "&RedirectToIdentityProvider=AD+AUTHORITY&userName=" + email.value ;
                }
                else {
                    redirectUrl += "?RedirectToIdentityProvider=AD+AUTHORITY&userName=" + email.value ;
                }

                window.location.href = redirectUrl;
                return false ;
           }
           if (!email.value || !email.value.match('[@]')) {
                u.setError(email, e.invalidSuffix) ;
                return false ;
           }

           docCookies.setItem('SecuritasConnectUserName', email.value, Infinity);

           return true ;
     };
}

var userNameAreaElement = document.getElementById('userNameArea') ;
if (userNameAreaElement) {
    var userName = getParameterByName("userName", currentUrl);

    if (userName) {
        docCookies.setItem('SecuritasConnectUserName', userName, Infinity);
    }
    else {
        userName = docCookies.getItem('SecuritasConnectUserName');
    }

    if (userName) {
        var userNameInputElement = document.getElementById('userNameInput');
        userNameInputElement.value = userName;

        var u = new InputUtil();
        u.setInitialFocus(Login.passwordInput);

        userNameAreaElement.innerHTML =
'<div class="idp" tabindex="1">' +
'<img class="largeIcon float" src="/adfs/portal/images/idp/localsts.png" alt="Employee badge">' +
'<div class="idpDescription float"><span class="largeTextNoWrap indentNonCollapsible">' + userName + '</span></div>' +
'</div>' +
'<input type="HIDDEN" id="userNameInput" name="userName" value="' + userName + '" />';

        var submissionAreaElement = document.getElementById('submissionArea') ;
        if (submissionAreaElement) {
            var newElement = document.createElement("div");
            submissionAreaElement.parentElement.insertBefore(newElement, submissionAreaElement);

            newElement.outerHTML = '<div class="idp" tabindex="1" onkeypress="if (event &amp;&amp; (event.keyCode == 32 || event.keyCode == 13)) resetLogin();" onclick="resetLogin(); return false;">' +
'<img class="largeIcon float" src="/adfs/portal/images/idp/idp.png" alt="User">' +
'<div class="idpDescription float"><span class="largeTextNoWrap indentNonCollapsible">Use another account</span></div>' +
'</div>';
        }
    }
}
```

---

```PowerShell
Set-AdfsRelyingPartyWebTheme `
    -TargetRelyingPartyName $relyingPartyName `
    -OnLoadScriptPath "C:\NotBackedUp\Temp\$themeName-Theme\script\onload.js"
```

#### Disable HRD cookie (due to issue with toggling between "Securitas login" and "Client login")

```PowerShell
Set-ADFSWebConfig -HRDCookieEnabled $false
```

#### TODO

Incorrect user ID or password. Type the correct user ID and password, and try again.

### # Revert customizations for SecuritasConnect (demo)

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

### -- Migrate Securitas users

```Console
USE [SecuritasPortal]
GO

UPDATE [Customer].[BranchManagerAssociatedUsers]
SET BranchManagerUserName = 'smasters@technologytoolbox.com'
WHERE BranchManagerUserName = 'TECHTOOLBOX\smasters'
```

```Console
cls
```

### # Enable Securitas employees to login using e-mail address (instead of UPN or SAM Account Name)

```PowerShell
net localgroup Administrators TECHTOOLBOX\jjameson /ADD

runas /USER:TECHTOOLBOX\jjameson cmd
```

---

**Command Prompt** - running as **TECHTOOLBOX\\jjameson**

```Console
PowerShell
```

---

**PowerShell** - running as **TECHTOOLBOX\\jjameson**

```PowerShell
Start-Process PowerShell -Verb runAs
```

---

**Administrator PowerShell** - running as **TECHTOOLBOX\\jjameson**

```PowerShell
Set-AdfsClaimsProviderTrust `
    -TargetIdentifier "AD AUTHORITY" `
    -AlternateLoginID mail `
    -LookupForests corp.technologytoolbox.com

exit
```

---

```Console
exit
```

---

```Console
exit
```

---

```Console
net localgroup Administrators TECHTOOLBOX\jjameson /DELETE
```

```Console
cls
```

## # Configure claims provider trust for Contoso

### Configure relying party on Contoso ADFS server

![(screenshot)](https://assets.technologytoolbox.com/screenshots/33/2B5216F84AAFB3DFC63888F3DE30598319C3AE33.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/37/6AC72383753C7437044F9BB0237657795084FC37.png)

[https://fs.technologytoolbox.com/federationmetadata/2007-06/federationmetadata.xml](https://fs.technologytoolbox.com/federationmetadata/2007-06/federationmetadata.xml)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/66/E6497979EDB38928014DEEF533DFB62A249EE166.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E2/ABDC199E6C277A1EF4CA199E47798EFAD80B1AE2.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/87/C4A976ECD7C04A54FA053713E58F6FE464114B87.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AD/0FFEE9494D540725C2F33F5145CA0DE6AC7997AD.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D4/E9DCC7042E274A8C238E56F02A9519603057E1D4.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A0/DE335A5D02CFB34A2894BC08697FDEDA10CFF3A0.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B4/E4D6C1557280E6BC69A073A2D6D0AA7578BDEFB4.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F0/F8F1A92198DB69F6D9E1061056FA507DE12932F0.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A8/B6878427FB8AA53BE2169485DBA667A25607B4A8.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DB/C3495D2B2A755FC7668669A00DDEAB904258CEDB.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C2/5C1FE5B7AE6BF64E1FE4B0DABC2923F96F5646C2.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CD/F02F79505BCC37987CFDD0F35917A89DDE9CA9CD.png)

### Export the token-signing certificate from Contoso ADFS server

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B2/1F44EDD0EFECD117B9FFC90CCBE7516AA22C0FB2.png)

Right-click the token-signing certificate and click **View Certificate...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/98/C5A23A82A2B602C450373A9E87E41CD44749FB98.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AD/5731B10ABF95185DBC39E1831215E4452287A2AD.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EF/3EDC2106856C070AF5E6D3ED610E30EF76EA5DEF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E6/54A9EDD43268EEED727857568498FE867D78ACE6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/86/2B96A5526809347461B44BF394BB759CA2CFFC86.png)

In the **Save As** window:

1. In the **File name** box, type **Token-signing - fs.contoso.com**.
2. Click **Save**.

In the **Certificate Export Wizard**, click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/57/3659B355327C8EAA4FD9D76C233D8506286D5A57.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6A/59FF9A0B43CDB1F9B3FA385EEC89D94AB63A3C6A.png)

### Copy token-signing certificate to ADFS server

### Create claims provider trust

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6D/CB602CAE1566470CA8F3BC2E9EAB6132D6008C6D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2F/DD1910BA8F6AE78C00C82B20593CB41D8B8BD02F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/35/64DF815A9BF1E186343EEE877D80614D0E410835.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4C/E239513A36451D9ED73962CC7304536510F7E94C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0C/570761A2B8CA8649785F855F82F2A09DE6AC1F0C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DA/B4FC297A36F47CCF3604927A95F45AAC589126DA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CD/F462EFC0354B8DED4FDFED6D0F96ED09F3BAF3CD.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EA/388850787F014AA82125D1779C4EA576006E25EA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AF/A1AEDF452D1CA129380FA55AECF614602CDF4BAF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9E/372A04FF18E2AF7D5DB54606AE5D13AD18E5829E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BC/2804A8A9D2E7C330F0A21BB1D9955BF73A697BBC.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E2/38DA58BC55EEF13586F819A3E5F95C553D0B4CE2.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5C/9BAC5EACAF3B3AF7519BB6FD8B1D6E44746F555C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/67/87BDA6F851FB8A53FF87EAC9AF424ADDE3566267.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/20/4C46FB0D6BA4B19551431471C451F99141AA7B20.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6F/D6EC718CB995FE61ACC2B2F5B892B419B934A76F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A9/C22BAB8B2EDF42FA2B7325D7FFEBDA366C048EA9.png)

Repeat the previous steps to pass through the following additional claims:

- **Name (pass through all claim values)**
- **UPN (pass through only claim values that match a specific email suffix value - contoso.com)**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A2/C88F2C430D53FF49358980D8366A732772C01FA2.png)

```PowerShell
cls
```

### # Customize home realm discovery

```PowerShell
Set-AdfsClaimsProviderTrust `
    -TargetName "Contoso Pharmaceuticals" `
    -OrganizationalAccountSuffix @("contoso.com")
```

#### Reference

**Customize the Home Realm Discovery page to ask for UPN right away**\
From <[https://blogs.technet.microsoft.com/pie/2015/10/18/customize-the-home-realm-discovery-page-to-ask-for-upn-right-away/](https://blogs.technet.microsoft.com/pie/2015/10/18/customize-the-home-realm-discovery-page-to-ask-for-upn-right-away/)>

### Configure relying party trust to pass through claims from claims providers other than Active Directory

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7E/1572A7C9C2707DF78789E0281A1E3C7542005D7E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/57/17005CBFCC144AFD425E923F44D26D4F52AF9857.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/67/87BDA6F851FB8A53FF87EAC9AF424ADDE3566267.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A6/099A594E54CE56397B0E5662FF033594B92690A6.png)

Repeat the previous steps to pass through the following additional claims:

- **Name (pass through all claim values)**
- **UPN (pass through all claim values)**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/10/BA6D2707162F6AD3897B147198B2B6C23FD5BA10.png)

### -- Migrate federated users

```SQL
USE [SecuritasPortal]
GO
```

#### -- Migrate "Angela.Parks" --> "aparks@contoso.com"

```Console
UPDATE [Customer].[ClientUsers]
SET UserName = 'aparks@contoso.com'
WHERE UserName = 'Angela.Parks'

UPDATE [Customer].SitePermissions
SET UserName = 'aparks@contoso.com'
WHERE UserName = 'Angela.Parks'

UPDATE dbo.aspnet_Users
SET
    UserName = 'aparks@contoso.com'
    , LoweredUserName = 'aparks@contoso.com'
WHERE UserName = 'Angela.Parks'

UPDATE [Customer].[BranchManagerAssociatedUsers]
SET AssociatedUserName = 'aparks@contoso.com'
WHERE AssociatedUserName = 'Angela.Parks'
```

#### -- Migrate "Ian.Lunn" --> "ilunn@woodgrove.com"

```PowerShell
UPDATE [Customer].[ClientUsers]
SET UserName = 'ilunn@woodgrove.com'
WHERE UserName = 'Ian.Lunn'

UPDATE [Customer].SitePermissions
SET UserName = 'ilunn@woodgrove.com'
WHERE UserName = 'Ian.Lunn'

UPDATE dbo.aspnet_Users
SET
    UserName = 'ilunn@woodgrove.com'
    , LoweredUserName = 'ilunn@woodgrove.com'
WHERE UserName = 'Ian.Lunn'

UPDATE [Customer].[BranchManagerAssociatedUsers]
SET AssociatedUserName = 'ilunn@woodgrove.com'
WHERE AssociatedUserName = 'Ian.Lunn'





Set-AdfsClaimsProviderTrust `
    -TargetName "idp-local-4.securitasinc.com" `
    -OrganizationalAccountSuffix @("woodgrove.com")

Foo
```

# EXT-ADFS02A - Windows Server 2016

Tuesday, February 14, 2017
2:22 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy federated authentication in SecuritasConnect

### Configure SSL in development environments

#### Install certificate for secure communication with SecuritasConnect

#### Add public URLs for HTTPS

#### Unextend web applications

#### Extend web applications to Intranet zone using SSL

#### Add HTTPS bindings to IIS websites

#### Change web service URLs (from HTTP to HTTPS) in Employee Portal

### Install and configure federation server farm

---

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Create and configure service account for AD FS farm

##### # Create service account for AD FS

```PowerShell
$displayName = "Service account for ADFS farm (EXT-ADFS02)"
$defaultUserName = "s-adfs"

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

##### # Configure Service Principal Name for AD FS service account

```PowerShell
setspn -S host/fs.technologytoolbox.com $cred.UserName
```

#### Reference

**Manually Configure a Service Account for a Federation Server Farm**\
From <[https://technet.microsoft.com/en-us/library/dd807078(v=ws.11).aspx](https://technet.microsoft.com/en-us/library/dd807078(v=ws.11).aspx)>

---

#### Install Windows Server 2016 on AD FS and WAP servers

---

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

##### # Create virtual machine

```PowerShell
$vmHost = "TT-HV02A"
$vmName = "EXT-ADFS02A"
$vmPath = "E:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"
$sysPrepedImage = "\\TT-FS01\VM-Library\VHDs\WS2016-Std.vhdx"

$vhdUncPath = "\\$vmHost\" + $vhdPath.Replace(":", "`$")

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 2GB `
    -SwitchName "Embedded Team Switch"

Copy-Item $sysPrepedImage $vhdUncPath

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 2 `
    -DynamicMemory `
    -MemoryMinimumBytes 2GB `
    -MemoryMaximumBytes 4GB

Start-VM -ComputerName $vmHost -Name $vmName
```

---

##### Set password for the local Administrator account

```PowerShell
cls
```

##### # Rename local Administrator account

```PowerShell
$adminUser = [ADSI] 'WinNT://./Administrator,User'

$adminUser.Rename('foo')

logoff
```

```PowerShell
cls
```

##### # Configure networking

```PowerShell
$interfaceAlias = "Management"
```

###### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

###### # Configure static IPv4 address

```PowerShell
$ipAddress = "192.168.10.241"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24 `
    -DefaultGateway 192.168.10.1
```

###### # Configure IPv4 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 192.168.10.209,192.168.10.210
```

###### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping TT-FS01.corp.technologytoolbox.com -f -l 8900
```

#### Login as local administrator account

```PowerShell
cls
```

##### # Rename server

```PowerShell
Rename-Computer -NewName EXT-ADFS02A -Restart
```

> **Note**
>
> Wait for the VM to restart.

##### Login as local administrator account

#### Join servers to domain

```PowerShell
$cred = Get-Credential EXTRANET\jjameson-admin

Add-Computer -DomainName extranet.technologytoolbox.com -Credential $cred -Restart
```

---

**EXT-DC04 - Run as EXTRANET\\jjameson-admin**

```PowerShell
cls
```

##### # Move computer to different OU

```PowerShell
$vmName = "EXT-ADFS02A"

$targetPath = ("OU=Servers,OU=Resources,OU=IT" `
    + ",DC=extranet,DC=technologytoolbox,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

---

```PowerShell
cls
```

#### # Configure storage

##### # Change drive letter for DVD-ROM

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
```

##### # Copy Toolbox content

```PowerShell
$source = "\\TT-FS01\Public\Toolbox"
$destination = "C:\NotBackedUp\Public\Toolbox"

net use $source /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```Console
robocopy $source $destination  /E /XD "Microsoft SDKs"
```

##### # Set MaxPatchCacheSize to 0 (recommended)

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

#### # Import certificate for secure communication with AD FS

```PowerShell
net use \\TT-FS01\Users$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$certFilePath =
    "\\TT-FS01\Users$\jjameson\My Documents\Technology Toolbox LLC" `
    + "\Certificates\fs.technologytoolbox.com.pfx"

$certPassword = `
    C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1

Import-PfxCertificate `
    -FilePath $certFilePath `
    -CertStoreLocation Cert:\LocalMachine\My `
    -Password $certPassword
```

```PowerShell
cls
```

#### # Add AD FS server role

```PowerShell
Install-WindowsFeature ADFS-Federation -IncludeManagementTools
```

---

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

##### # Checkpoint VM

```PowerShell
$vmHost = "TT-HV02A"
$vmName = "EXT-ADFS02A"
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

#### # Create AD FS farm

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
$serviceAccountCredential = Get-Credential TECHTOOLBOX\s-adfs
```

> **Note**
>
> When prompted, type the password for the service account.

```PowerShell
$databaseHostName = "EXT-SQL02"

Import-Module ADFS

Install-AdfsFarm `
    -CertificateThumbprint $cert.Thumbprint `
    -Credential $installationCredential `
    -FederationServiceDisplayName "Technology Toolbox" `
    -FederationServiceName fs.technologytoolbox.com `
    -ServiceAccountCredential $serviceAccountCredential `
    -SQLConnectionString ("Data Source=" + $databaseHostName + ";" `
        + "Initial Catalog=ADFSConfiguration;" `
        + "Integrated Security=True;" `
        + "Min Pool Size=20")



WARNING: A machine restart is required to complete ADFS service configuration. For more information, see:
http://go.microsoft.com/fwlink/?LinkId=798725
WARNING: An error occurred during an attempt to set the SPN for the specified service account. Set the SPN for the service account manually.  For more information about setting the SPN of the service account manually, see the AD FS
Deployment Guide.  Error message: An error occurred during an attempt to set the SPN for the specified service account. You do not have sufficient privileges in the domain to set the SPN.
WARNING: Failed to register SSL bindings for Device Registration Service: An item with the same key has already been added..

Message                                   Context              Status
-------                                   -------              ------
The configuration completed successfully. DeploymentSucceeded Success
```

> **Note**
>
> Although the connection string specifies **ADFSConfiguration** for the database name, AD FS in Windows Server 2016 creates the database as **AdfsConfigurationV3**. Also note the connection string is updated accordingly -- which can be verified by the following:
>
> ```PowerShell
> Get-WmiObject -Namespace root/ADFS -Class SecurityTokenService |
>     select ConfigurationDatabaseConnectionString
> ```

```PowerShell
Restart-Computer
```

---

**EXT-SQL02 - SQL Server Management Studio**

#### -- Backup AD FS databases

```SQL
BACKUP DATABASE AdfsArtifactStore
TO DISK = N'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\AdfsArtifactStore.bak'
WITH NOFORMAT, NOINIT,
    NAME = N'AdfsArtifactStore-Full Database Backup',
    SKIP, NOREWIND, NOUNLOAD,  STATS = 10

GO

BACKUP DATABASE AdfsConfigurationV3
TO DISK = N'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\AdfsConfigurationV3.bak'
WITH NOFORMAT, NOINIT,
    NAME = N'AdfsConfigurationV3-Full Database Backup',
    SKIP, NOREWIND, NOUNLOAD,  STATS = 10

GO
```

---

#### Add second federation server to AD FS farm

```PowerShell
cls
```

#### # Enable Securitas employees to login using their e-mail addresses

```PowerShell
net localgroup Administrators TECHTOOLBOX\jjameson /ADD

runas /USER:TECHTOOLBOX\jjameson cmd
```

---

**Command Prompt - running as TECHTOOLBOX\\jjameson**

```Console
PowerShell
```

---

**PowerShell - running as TECHTOOLBOX\\jjameson**

```PowerShell
Start-Process PowerShell -Verb runAs
```

---

**Administrator PowerShell - running as TECHTOOLBOX\\jjameson**

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

#### # Extend validity period for self-signed certificates in AD FS

```PowerShell
Set-AdfsProperties -CertificateDuration (365*5)

Update-AdfsCertificate -Urgent
```

#### Configure federation service name resolution

##### Configure federation service name resolution on WAP servers

(skipped)

##### Create internal DNS records for AD FS services

---

**XAVIER1**

#### # Create A records - "fs.technologytoolbox.com"

```PowerShell
Add-DnsServerResourceRecordA `
    -Name "fs" `
    -IPv4Address 192.168.10.241 `
    -ZoneName "technologytoolbox.com"

Add-DnsServerResourceRecordA `
    -Name "fs" `
    -IPv4Address 192.168.10.242 `
    -ZoneName "technologytoolbox.com"
```

---

##### Create external DNS record for AD FS services

(skipped)

#### Add Web Application Proxy role

#### Configure Web Application Proxy role

```PowerShell
cls
```

### # Configure relying party in AD FS for SecuritasConnect

#### # Create relying party in AD FS

```PowerShell
$clientPortalUrl = [Uri] "http://client-local-9.securitasinc.com"

$relyingPartyDisplayName = $clientPortalUrl.Host
$wsFedEndpointUrl = "https://" + $clientPortalUrl.Host + "/_trust/"
$additionalIdentifier = "urn:sharepoint:securitas:" `
    + ($clientPortalUrl.Host -split '\.' | select -First 1)

$identifiers = $wsFedEndpointUrl, $additionalIdentifier

Add-AdfsRelyingPartyTrust `
    -Name $relyingPartyDisplayName `
    -Identifier $identifiers `
    -WSFedEndpoint $wsFedEndpointUrl `
    -AccessControlPolicyName "Permit everyone"
```

#### # Configure claim issuance policy for relying party

```PowerShell
$clientPortalUrl = [Uri] "http://client-local-9.securitasinc.com"

$relyingPartyDisplayName = $clientPortalUrl.Host

$claimRules = `
'@RuleTemplate = "LdapClaims"
@RuleName = "Active Directory Claims"
c:[Type ==
    "http://schemas.microsoft.com/ws/2008/06/identity/claims/windowsaccountname",
    Issuer == "AD AUTHORITY"]
 => issue(
      store = "Active Directory",
      types = (
        "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress",
        "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name",
        "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn",
        "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"),
      query = ";mail,displayName,userPrincipalName,tokenGroups;{0}",
      param = c.Value);

@RuleTemplate = "PassThroughClaims"
@RuleName = "Pass through E-mail Address"
c:[Type ==
"http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"]
 => issue(claim = c);'

$tempFile = [System.IO.Path]::GetTempFileName()

Set-Content -Value $claimRules -LiteralPath $tempFile

Set-AdfsRelyingPartyTrust `
    -TargetName $relyingPartyDisplayName `
    -IssuanceTransformRulesFile $tempFile
```

```PowerShell
cls
```

### # Configure trust relationship from SharePoint farm to AD FS farm

#### # Export token-signing certificate from AD FS farm

```PowerShell
$serviceCert = Get-AdfsCertificate -CertificateType Token-Signing

$certBytes = $serviceCert.Certificate.Export(
    [System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)

$certName = $serviceCert.Certificate.Subject.Replace("CN=", "")

[System.IO.File]::WriteAllBytes(
    "C:\" + $certName + ".cer",
    $certBytes)
```

#### # Copy token-signing certificate to SharePoint server

```PowerShell
$source = "C:\ADFS Signing - fs.technologytoolbox.com.cer"
$destination = "\\EXT-FOOBAR9.extranet.technologytoolbox.com\C$"

net use $destination `
    /USER:EXTRANET\setup-sharepoint-dev
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```Console
copy $source $destination
```

---

**EXT-FOOBAR9 - Run as EXTRANET\\setup-sharepoint-dev**

```PowerShell
cls
```

#### # Import token-signing certificate to SharePoint farm

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

$certPath = "C:\ADFS Signing - fs.technologytoolbox.com.cer"

$cert = `
    New-Object System.Security.Cryptography.X509Certificates.X509Certificate2(
        $certPath)

New-SPTrustedRootAuthority `
    -Name "ADFS Signing - fs.technologytoolbox.com" `
    -Certificate $cert
```

#### # Create authentication provider for AD FS

##### # Define claim mappings and identifier claim

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

##### # Create authentication provider

```PowerShell
$realm = "urn:sharepoint:securitas"
$signInURL = "https://fs.technologytoolbox.com/adfs/ls"

$cert = Get-SPTrustedRootAuthority |
    where { $_.Name -eq "ADFS Signing - fs.technologytoolbox.com" } |
    select -ExpandProperty Certificate

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
$clientPortalUrl = [Uri] "http://client-local-9.securitasinc.com"

$secureClientPortalUrl = "https://" + $clientPortalUrl.Host

$realm = "urn:sharepoint:securitas:" `
    + ($clientPortalUrl.Host -split '\.' | select -First 1)

$authProvider.ProviderRealms.Add($secureClientPortalUrl, $realm)
$authProvider.Update()
```

### # Configure SecuritasConnect to use AD FS trusted identity provider

```PowerShell
$clientPortalUrl = [Uri] "http://client-local-9.securitasinc.com"

$trustedIdentityProvider = Get-SPTrustedIdentityTokenIssuer -Identity ADFS

Set-SPWebApplication `
    -Identity $clientPortalUrl.AbsoluteUri `
    -Zone Default `
    -AuthenticationProvider $trustedIdentityProvider `
    -SignInRedirectURL ""

$webApp = Get-SPWebApplication $clientPortalUrl.AbsoluteUri

$defaultZone = [Microsoft.SharePoint.Administration.SPUrlZone]::Default

$webApp.IisSettings[$defaultZone].AllowAnonymous = $false
$webApp.Update()
```

---

### Upgrade to "v4.0 Sprint-29" build

#### Copy new build from TFS drop location

#### Remove previous versions of SecuritasConnect WSPs

#### Install new versions of SecuritasConnect WSPs

### Migrate users

### Install and configure identity provider for client users

```PowerShell
cls
```

##### # Configure name resolution for identity provider website

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    -IPAddress 192.168.10.224 `
    -Hostnames idp.technologytoolbox.com
```

#### # Configure claims provider trust in ADFS

```PowerShell
Add-AdfsClaimsProviderTrust `
    -Name idp.technologytoolbox.com `
    -MetadataURL https://idp.technologytoolbox.com/core/wsfed/metadata `
    -MonitoringEnabled $true `
    -AutoUpdateEnabled $true `
    -SignatureAlgorithm http://www.w3.org/2000/09/xmldsig#rsa-sha1
```

#### # Configure claim acceptance rules for claims provider trust

```PowerShell
$claimsProviderTrustName = "idp.technologytoolbox.com"

$claimRules = `
'@RuleTemplate = "PassThroughClaims"
@RuleName = "Pass through E-mail Address"
c:[Type ==
"http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"]
 => issue(claim = c);'

$tempFile = [System.IO.Path]::GetTempFileName()

Set-Content -Value $claimRules -LiteralPath $tempFile

Set-AdfsClaimsProviderTrust `
    -TargetName $claimsProviderTrustName `
    -AcceptanceTransformRulesFile $tempFile
```

### Associate client email domains with claims provider trust

---

**EXT-FOOBAR9 - SQL Server Management Studio**

#### -- Create configuration file for AD FS claims provider trust

```SQL
USE SecuritasPortal
GO

SELECT DISTINCT
  LOWER(
    REVERSE(
      SUBSTRING(
        REVERSE(Email),
        0,
        CHARINDEX('@', REVERSE(Email))))) AS OrganizationalAccountSuffix,
  'idp.technologytoolbox.com' AS TargetName
FROM
  dbo.aspnet_Membership
WHERE
  Email NOT LIKE '%securitasinc.com'

-- Save results to file
-- C:\NotBackedUp\Temp\ADFS-Claims-Provider-Trust-Configuration.csv
--
-- Insert headers:
-- OrganizationalAccountSuffix,TargetName
```

---

```PowerShell
cls

$source = '\\EXT-FOOBAR9\C$\NotBackedUp\Temp' `
    + '\ADFS-Claims-Provider-Trust-Configuration.csv'

$destination = 'C:\NotBackedUp\Temp'

copy $source $destination
```

#### # Set organizational account suffixes on AD FS claims provider trust

```PowerShell
Push-Location $destination

$claimsProviderTrustName = "idp.technologytoolbox.com"

$orgAccountSuffixes = `
    Import-Csv .\ADFS-Claims-Provider-Trust-Configuration.csv |
        where { $_.TargetName -eq $claimsProviderTrustName } |
        select -ExpandProperty OrganizationalAccountSuffix

Set-AdfsClaimsProviderTrust `
    -TargetName $claimsProviderTrustName `
    -OrganizationalAccountSuffix $orgAccountSuffixes

Pop-Location
```

## Customize AD FS login pages

### References

**Customizing the AD FS Sign-in Pages**\
From <[https://technet.microsoft.com/library/dn280950.aspx](https://technet.microsoft.com/library/dn280950.aspx)>

**Customize the Home Realm Discovery page to ask for UPN right away**\
From <[https://blogs.technet.microsoft.com/pie/2015/10/18/customize-the-home-realm-discovery-page-to-ask-for-upn-right-away/](https://blogs.technet.microsoft.com/pie/2015/10/18/customize-the-home-realm-discovery-page-to-ask-for-upn-right-away/)>

```PowerShell
cls
```

### # Customize AD FS login pages

#### # Customize text and image on login pages for SecuritasConnect relying party

```PowerShell
$clientPortalUrl = [Uri] "http://client-local-9.securitasinc.com"

$relyingPartyDisplayName = $clientPortalUrl.Host

Set-AdfsRelyingPartyWebContent `
    -TargetRelyingPartyName $relyingPartyDisplayName `
    -CompanyName "SecuritasConnect" `
    -OrganizationalNameDescriptionText `
        "Enter your Securitas e-mail address and password below." `
    -SignInPageDescription $null `
    -HomeRealmDiscoveryOtherOrganizationDescriptionText `
        "Enter your e-mail address below."

$tempFile = [System.Io.Path]::GetTempFileName()
$tempFile = $tempFile.Replace(".tmp", ".jpg")

Invoke-WebRequest `
    -Uri https://idp.technologytoolbox.com/images/illustration.jpg `
    -OutFile $tempFile

Set-AdfsRelyingPartyWebTheme `
    -TargetRelyingPartyName $relyingPartyDisplayName `
    -Illustration @{ path = $tempFile }

Remove-Item $tempFile
```

#### # Configure custom JavaScript file for additional customizations

```PowerShell
$clientPortalUrl = [Uri] "http://client-local-9.securitasinc.com"

$relyingPartyDisplayName = $clientPortalUrl.Host

$tempFile = [System.Io.Path]::GetTempFileName()
$tempFile = $tempFile.Replace(".tmp", ".js")

Invoke-WebRequest `
    -Uri https://idp.technologytoolbox.com/js/onload.js `
    -OutFile $tempFile

Set-AdfsRelyingPartyWebTheme `
    -TargetRelyingPartyName $relyingPartyDisplayName `
    -OnLoadScriptPath $tempFile

Remove-Item $tempFile
```

#### Disable HRD cookie (due to issue with toggling between "Securitas login" and "Client login")

```PowerShell
Set-ADFSWebConfig -HRDCookieEnabled $false
```

## Configure claims provider trust for Contoso

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

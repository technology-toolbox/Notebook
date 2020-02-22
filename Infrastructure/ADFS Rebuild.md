# ADFS Rebuild

Tuesday, April 3, 2018
11:03 AM

---

**EXT-ADFS03A** - Run as domain administrator

```PowerShell
cls
```

## # Configure relying party in AD FS for SecuritasConnect

### # Create relying party in AD FS

```PowerShell
$clientPortalUrl = [Uri] "http://client-local-2.securitasinc.com"

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

### # Configure claim issuance policy for relying party

```PowerShell
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
    "http://schemas.microsoft.com/ws/2008/06/identity/claims/primarysid",
    "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"),
  query = ";mail,displayName,userPrincipalName,objectSid,tokenGroups;{0}",
  param = c.Value);

@RuleTemplate = "PassThroughClaims"
@RuleName = "Pass through E-mail Address"
c:[Type ==
  "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"]
=> issue(claim = c);

@RuleTemplate = "PassThroughClaims"
@RuleName = "Pass through Branch Managers Role"
c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/role",
  Value =~ "^(?i)Branch\ Managers$"]
=> issue(claim = c);'

$tempFile = [System.IO.Path]::GetTempFileName()

Set-Content -Value $claimRules -LiteralPath $tempFile

Set-AdfsRelyingPartyTrust `
    -TargetName $relyingPartyDisplayName `
    -IssuanceTransformRulesFile $tempFile
```

## # Configure trust relationship from SharePoint farm to AD FS farm

### # Export token-signing certificate from AD FS farm

```PowerShell
$serviceCert = Get-AdfsCertificate -CertificateType Token-Signing

$certBytes = $serviceCert.Certificate.Export(
    [System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)

$certName = $serviceCert.Certificate.Subject.Replace("CN=", "")

[System.IO.File]::WriteAllBytes(
    "C:\" + $certName + ".cer",
    $certBytes)
```

### # Copy token-signing certificate to SharePoint server

```PowerShell
$source = "C:\ADFS Signing - fs.technologytoolbox.com.cer"
$destination = "\\EXT-FOOBAR2.extranet.technologytoolbox.com\C$"

net use $destination `
    /USER:EXTRANET\setup-sharepoint-dev
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
Copy-Item $source $destination
```

---

```PowerShell
cls
```

### # Import token-signing certificate to SharePoint farm

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

Get-SPTrustedRootAuthority -Identity "ADFS Signing - fs.technologytoolbox.com" |
    Set-SPTrustedRootAuthority -Certificate $cert
```

#### # Update authentication provider for AD FS

```PowerShell
$cert = Get-SPTrustedRootAuthority |
    where { $_.Name -eq "ADFS Signing - fs.technologytoolbox.com" } |
    select -ExpandProperty Certificate

Get-SPTrustedIdentityTokenIssuer -Identity "ADFS" |
    Set-SPTrustedIdentityTokenIssuer -ImportTrustCertificate $cert
```

---

**EXT-ADFS03A** - Run as domain administrator

```PowerShell
cls
```

### # Configure claims provider trust in AD FS for identity provider

#### # Create claims provider trust in AD FS

```PowerShell
$idpHostHeader = "idp.technologytoolbox.com"

Add-AdfsClaimsProviderTrust `
    -Name $idpHostHeader `
    -MetadataURL "https://$idpHostHeader/core/wsfed/metadata" `
    -MonitoringEnabled $true `
    -AutoUpdateEnabled $true `
    -SignatureAlgorithm http://www.w3.org/2000/09/xmldsig#rsa-sha1
```

#### # Configure claim acceptance rules for claims provider trust

```PowerShell
$claimsProviderTrustName = $idpHostHeader

$claimRules = `
'@RuleTemplate = "PassThroughClaims"
@RuleName = "Pass through E-mail Address"
c:[Type ==
  "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"]
=> issue(claim = c);

@RuleTemplate = "PassThroughClaims"
@RuleName = "Pass through Role"
c:[Type ==
  "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"]
=> issue(claim = c);'

$tempFile = [System.IO.Path]::GetTempFileName()

Set-Content -Value $claimRules -LiteralPath $tempFile

Set-AdfsClaimsProviderTrust `
    -TargetName $claimsProviderTrustName `
    -AcceptanceTransformRulesFile $tempFile
```

```PowerShell
cls
```

## # Customize AD FS login pages

### # Customize text and image on login pages for SecuritasConnect relying party

```PowerShell
$clientPortalUrl = [Uri] "http://client-local-2.securitasinc.com"

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

### # Configure custom CSS and JavaScript files for additional customizations

```PowerShell
$relyingPartyDisplayName = $clientPortalUrl.Host

$tempCssFile = [System.Io.Path]::GetTempFileName()
$tempCssFile = $tempCssFile.Replace(".tmp", ".css")

$tempJsFile = [System.Io.Path]::GetTempFileName()
$tempJsFile = $tempJsFile.Replace(".tmp", ".js")

Invoke-WebRequest `
    -Uri https://idp.technologytoolbox.com/css/styles.css `
    -OutFile $tempCssFile

Invoke-WebRequest `
    -Uri https://idp.technologytoolbox.com/js/onload.js `
    -OutFile $tempJsFile

Set-AdfsRelyingPartyWebTheme `
    -TargetRelyingPartyName $relyingPartyDisplayName `
    -OnLoadScriptPath $tempJsFile `
    -StyleSheet @{ path = $tempCssFile }

Remove-Item $tempCssFile
Remove-Item $tempJsFile
```

---

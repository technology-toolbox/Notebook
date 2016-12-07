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

![(screenshot)](https://assets.technologytoolbox.com/screenshots/44/FD08E4C03F8CFB90803760AEE7A2EFD639808C44.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4F/423F04CC7771D3C5B35C0FF48A8FFE2D76BD9A4F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1C/6F91E83F2F92D0518F130C2E8F4822DB557CDF1C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/89/27BCA18D6F15FF15ADD4452B3578C4459F18CD89.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D6/8EA9EBB91D184C4B18977FE2C0E45598292FDCD6.png)

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

#### # Copy token-signing certificate to SharePoint server

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
    \\ext-foobar9.extranet.technologytoolbox.com\C$\Users\jjameson\Desktop
```

---

**EXT-FOOBAR9 - Run as TECHTOOLBOX\\jjameson**

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
    -IncomingClaimType "http://schemas.microsoft.com/ws/2008/06/identity/claims/role" `
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

#### # Create authentication provider

```PowerShell
$realm = "urn:sharepoint:securitas"
$signInURL = "https://fs.fabrikam.com/adfs/ls"

$authProvider = New-SPTrustedIdentityTokenIssuer `
    -Name "AD FS Provider for SharePoint" `
    -Description "AD FS provider for Securitas web applications" `
    -Realm $realm `
    -ImportTrustCertificate $cert `
    -ClaimsMappings  $claimsMappings `
    -SignInUrl $signInURL `
    -IdentifierClaim $identifierClaim
```

#### # Configure authentication provider for SecuritasConnect

```PowerShell
$uri = New-Object System.Uri("https://client3-local-9.securitasinc.com")
$realm = "urn:sharepoint:securitas:client3-local-9"

$authProvider.ProviderRealms.Add($uri, $realm)
$authProvider.Update()
```

#### # Configure authentication provider for Cloud Portal

```PowerShell
$uri = New-Object System.Uri("https://cloud3-local-9.securitasinc.com")
$realm = "urn:sharepoint:securitas:cloud3-local-9"

$authProvider.ProviderRealms.Add($uri, $realm)
$authProvider.Update()
```

---

### Phase 4: Configure web applications to use claims-based authentication and AD FS as the trusted identity provider

---

**EXT-FOOBAR9 - Run as TECHTOOLBOX\\jjameson-admin**

#### # Configure SSL on web applications

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

##### Add public URLs for HTTPS

##### Add HTTPS bindings to sites in IIS

Site: **SharePoint - client-local-9.securitasinc.com**\
Host name: **client-local-9.securitasinc.com**\
SSL certificate: **\*.securitasinc.com**

Site: **SharePoint - cloud2-local-9.securitasinc.com**\
Host name: **cloud2-local-9.securitasinc.com**\
SSL certificate: **\*.securitasinc.com**

Site: **employee-local-9.securitasinc.com**\
Host name: **employee-local-9.securitasinc.com**\
SSL certificate: **\*.securitasinc.com**

---

---

**EXT-FOOBAR9 - Run as TECHTOOLBOX\\jjameson**

#### # Extend web applications to Extranet zone

```PowerShell
Notepad "C:\NotBackedUp\Temp\Extend Web Applications.ps1"
```

---

**Extend Web Applications.ps1**

```PowerShell
[CmdletBinding(
    SupportsShouldProcess = $true,
    ConfirmImpact = "High")]
Param(
    [switch] $SecureSocketsLayer)

Begin
{
    Set-StrictMode -Version Latest
    $ErrorActionPreference = "Stop"

    If ((Get-PSSnapin Microsoft.SharePoint.PowerShell `
        -ErrorAction SilentlyContinue) -eq $null)
    {
        $ver = $host | select version

        If ($ver.Version.Major -gt 1)
        {
            $Host.Runspace.ThreadOptions = "ReuseThread"
        }

        Write-Debug "Adding snapin (Microsoft.SharePoint.PowerShell)..."

        Add-PSSnapin Microsoft.SharePoint.PowerShell
    }

    Function ExtendWebAppToExtranetZone(
        [Uri] $DefaultUrl = $(Throw "Default URL must be specified."),
        [Uri] $ExtranetUrl = $(Throw "Extranet URL must be specified."))
    {
        $webApp = Get-SPWebApplication `
            -Identity $DefaultUrl.AbsoluteUri `
            -Debug:$false `
            -Verbose:$false

        Write-Debug ("Extending Web application $(($DefaultUrl.AbsoluteUri))" `
            + " to Extranet zone $(($ExtranetUrl.AbsoluteUri))...")

        $hostHeader = $ExtranetUrl.Host

        $windowsAuthProvider = New-SPAuthenticationProvider `
            -Debug:$false `
            -Verbose:$false

        If ($ExtranetUrl.Scheme -eq "http")
        {
            $webAppName = "SharePoint - " + $hostHeader + "80"

            $webApp | New-SPWebApplicationExtension `
                -Name $webAppName `
                -Zone Extranet `
                -AuthenticationProvider $windowsAuthProvider `
                -HostHeader $hostHeader `
                -Port 80 `
                -Debug:$false `
                -Verbose:$false

        }
        ElseIf ($ExtranetUrl.Scheme -eq "https")
        {
            $webAppName = "SharePoint - " + $hostHeader + "443"

            $webApp | New-SPWebApplicationExtension `
                -Name $webAppName `
                -Zone Extranet `
                -AuthenticationProvider $windowsAuthProvider `
                -HostHeader $hostHeader `
                -Port 443 `
                -SecureSocketsLayer `
                -Debug:$false `
                -Verbose:$false
        }
        Else
        {
            Throw "The specified scheme ($($ExtranetUrl.Scheme)) is not supported."
        }

        Write-Debug ("Successfully extended Web application" `
            + " ($(($DefaultUrl.AbsoluteUri))) to Extranet zone" `
            + " ($(($ExtranetUrl.AbsoluteUri))).")
    }

    Function GetTimestamp
    {
        Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    }

    Function LogActivity(
        [string] $activity,
        [string] $status,
        [switch] $completed,
        [System.Diagnostics.Stopwatch] $stopwatch)
    {
        Write-Progress `
            -Activity $activity `
            -Status $status `
            -Completed:([bool]::Parse($completed))

        If ($completed)
        {
            If ($stopwatch -eq $null)
            {
                Write-Host -Fore Green "[$(GetTimestamp)] $status"
            }
            Else
            {
                Write-Host -Fore Green "[$(GetTimestamp)] $status " -NoNewLine
                WriteElapsedTime $stopwatch
            }
        }
        Else
        {
            Write-Verbose "[$(GetTimestamp)] $status"
        }
    }

    Function WriteElapsedTime(
        [System.Diagnostics.Stopwatch] $stopwatch =
            $(Throw "Value cannot be null: stopwatch"))
    {
        $timespan = $stopwatch.Elapsed

        $formattedTime = [string]::Format(
            "{0:00}:{1:00}",
            $timespan.Minutes,
            $timespan.Seconds)

        Write-Host -Fore Cyan "(Elapsed time: $formattedTime)"
    }
}

Process
{
    $clientWebAppDefaultUrl = $env:SECURITAS_CLIENT_PORTAL_URL

    If ([string]::IsNullOrEmpty($clientWebAppDefaultUrl) -eq $true)
    {
        # default to Production
        $clientWebAppDefaultUrl = "http://client.securitasinc.com"
    }

    $cloudWebAppDefaultUrl = $env:SECURITAS_CLOUD_PORTAL_URL

    If ([string]::IsNullOrEmpty($cloudWebAppDefaultUrl) -eq $true)
    {
        # default to Production
        $cloudWebAppDefaultUrl = "http://cloud.securitasinc.com"
    }

    $clientWebAppExtranetUrl = $clientWebAppDefaultUrl.Replace(
        "client",
        "client3")

    $cloudWebAppExtranetUrl = $cloudWebAppDefaultUrl.Replace(
        "cloud",
        "cloud3")

    If ($SecureSocketsLayer -eq $true)
    {
        $clientWebAppExtranetUrl = $clientWebAppExtranetUrl.Replace(
            "http://",
            "https://")

        $cloudWebAppExtranetUrl = $cloudWebAppExtranetUrl.Replace(
            "http://",
            "https://")
    }

    Write-Host "Extend web applications -"
    Write-Host
    Write-Host "  SecuritasConnect extranet URL: $clientWebAppExtranetUrl"
    Write-Host "  Cloud Portal extranet URL: $cloudWebAppExtranetUrl"

    If ($PSCmdlet.ShouldProcess($env:COMPUTERNAME))
    {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        [string] $activity = "Extend Web Applications"

        LogActivity $activity ("Extending Web application " `
            + " ($clientWebAppDefaultUrl) to Extranet zone" `
            + " ($clientWebAppExtranetUrl)...")

        ExtendWebAppToExtranetZone `
            -DefaultUrl $clientWebAppDefaultUrl `
            -ExtranetUrl $clientWebAppExtranetUrl

        LogActivity $activity ("Extending Web application " `
            + " ($cloudWebAppDefaultUrl) to Extranet zone" `
            + " ($cloudWebAppExtranetUrl)...")

        ExtendWebAppToExtranetZone `
            -DefaultUrl $cloudWebAppDefaultUrl `
            -ExtranetUrl $cloudWebAppExtranetUrl

        LogActivity `
            $activity `
            "Successfully extended web applications." `
            -Complete `
            $stopwatch
    }
}
```

---

```PowerShell
& "C:\NotBackedUp\Temp\Extend Web Applications.ps1" -SecureSocketsLayer
```

---

---

**EXT-FOOBAR9 - Run as TECHTOOLBOX\\jjameson-admin**

#### # Associate web applications with the AD FS identity provider

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D8/7F642FAA44021E95DB1A7A6FD9F2677B23C0BDD8.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1E/A24CA7BB784A301C0B2F807A037A4A6A11DD241E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D7/261788A78C597B7B328B3AA6A02A1D0BCDE47DD7.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5E/3961FD8DDEC896049CABAED6C8AE3A3699790C5E.png)

In the **Authentication Providers** window, click **Extranet**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AC/186F5C73F0D1F5C63212C085C66949AA49270FAC.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FD/83C8A40ECDDE81D2D1EFFCFC960CEA62C08ABBFD.png)

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
$relyingPartyTrustName = "client3-local-9.securitasinc.com"
$companyName = "SecuritasConnect"
$organizationalNameDescriptionText = "Sign in with your SecuritasConnect credentials or your organizational account (if supported)"

$signInPageDescription = "<p>SecuritasConnect is a powerful tool that can improve the efficiency of your security program and enhance the performance of your team. No paper logbooks or handwritten reports. Everything is recorded and available online.</p><p>&nbsp;</p><p>SecuritasConnect is your direct link to key and relevant information needed to manage your security program. Accessible through any internet connection, the features and tools in Connect help you stay on top of what's happening down the hall or around the world, allowing you to monitor and protect your interests day and night.</p>"

$illustrationPath = "C:\NotBackedUp\Temp\SecuritasConnect-1420x1080.png"

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
$relyingPartyTrustName = "client3-local-9.securitasinc.com"
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

#### # Customize the AD FS sign-in page for Cloud Portal

```PowerShell
$relyingPartyTrustName = "cloud3-local-9.securitasinc.com"
$companyName = "Collaboration & Community"
$organizationalNameDescriptionText = $null

$signInPageDescription = "<p>This system is restricted solely for Securitas Security Services USA, Inc. authorized users for legitimate business purposes only.  If you are not a legitimate Securitas USA user or an authorized business associate, do not attempt to access this system.</p><p>&nbsp;</p><p>The actual or attempted unauthorized access, use, or modification of this system is strictly prohibited.  Unauthorized users are subject to company disciplinary proceedings and/or criminal and civil penalties under applicable state, federal, or applicable domestic and foreign laws.  The user of this system may be monitored and recorded for administrative and security reasons.  Anyone accessing this system expressly consents to such monitoring and is advised that if monitoring reveals possible evidence of criminal activity, Securitas Security Services USA, Inc. may provide information of such activity to law enforcement officials.</p><p>&nbsp;</p><p>Authorized users are not permitted to store PII (Personal Identity Information) on laptop or desktop computers and this data may not be exchanged with or transmitted to unsecured email or fax machines (PII includes, but is not limited to, credit card, bank account, and Social Security Number information).  Securitas Security Services USA, Inc. reserves the right to review and monitor all PII information usage.  A copy of the complete PII Protection Policy is available on the Portal under Operational Support Services/Company Information/Company Policies & Procedures.</p>"

$illustrationPath = "C:\NotBackedUp\Temp\Securitas-Cloud-Portal-1420x1080.jpg"

Set-AdfsRelyingPartyWebContent `
    -TargetRelyingPartyName $relyingPartyTrustName `
    -CompanyName $companyName `
    -OrganizationalNameDescriptionText $organizationalNameDescriptionText `
    -SignInPageDescription $signInPageDescription

Set-AdfsRelyingPartyWebTheme `
    -TargetRelyingPartyName $relyingPartyTrustName `
    -Illustration @{path=$illustrationPath}
```

#### # Revert customizations for Cloud Portal (demo)

```PowerShell
$relyingPartyTrustName = "cloud3-local-9.securitasinc.com"
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

## Configure claims provider trust for Contoso

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    -IPAddress 192.168.10.233 `
    -Hostnames fs.contoso.com
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6D/CB602CAE1566470CA8F3BC2E9EAB6132D6008C6D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2F/DD1910BA8F6AE78C00C82B20593CB41D8B8BD02F.png)

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

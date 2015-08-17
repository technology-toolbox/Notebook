# FAB-ADFS01 - Windows Server 2012 R2

Thursday, May 28, 2015
8:28 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

### Install Windows Server 2012 R2

---

**WOLVERINE**

```PowerShell
$VerbosePreference = "Continue"
```

```PowerShell
cls
```

#### # Get list of Windows Server 2012 R2 images

```PowerShell
Get-AzureVMImage |
    where { $_.Label -like "Windows Server 2012 R2*" } |
    select Label, ImageName
```

#### # Use latest OS image

```PowerShell
$imageName = `
    "a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-R2-201505.01-en.us-127GB.vhd"
```

```PowerShell
cls
```

#### # Create VM

```PowerShell
$localAdminCred = Get-Credential `
    -UserName Administrator `
    -Message "Type the user name and password for the local Administrator account."

$domainCred = Get-Credential `
    -UserName jjameson-admin `
    -Message "Type the user name and password for joining the domain."

$storageAccount = "fabrikam3"
$location = "West US"
$vmName = "FAB-ADFS01"
$cloudService = "fab-adfs"
$instanceSize = "Basic_A1"
$vhdPath = "https://$storageAccount.blob.core.windows.net/vhds/$vmName"
$localAdminUserName = $localAdminCred.UserName
$localPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR(
        $localAdminCred.Password))

$dns1 = New-AzureDns -Name FAB-DC01 -IPAddress 192.168.10.201
$dns2 = New-AzureDns -Name FAB-DC02 -IPAddress 192.168.10.202
$domainName = "FABRIKAM"
$fqdn = "corp.fabrikam.com"
$domainUserName = $domainCred.UserName
$domainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR(
        $domainCred.Password))

$orgUnit = "OU=Azure,OU=Servers,OU=Resources,OU=IT,DC=corp,DC=fabrikam,DC=com"
$virtualNetwork = "West US VLAN1"
$subnetName = "Azure-Production"
$ipAddress = "10.71.2.101"

$vmConfig = New-AzureVMConfig `
    -Name $vmName `
    -ImageName $imageName `
    -InstanceSize $instanceSize `
    -MediaLocation ($vhdPath + "/$vmName.vhd") |
    Add-AzureProvisioningConfig `
        -AdminUsername $localAdminUserName `
        -Password $localPassword `
        -WindowsDomain `
        -JoinDomain $fqdn `
        -Domain $domainName `
        -DomainUserName $domainUserName `
        -DomainPassword $domainPassword `
        -MachineObjectOU $orgUnit |
    Set-AzureSubnet -SubnetNames $subnetName |
    Set-AzureStaticVNetIP -IPAddress $ipAddress

New-AzureVM `
    -ServiceName $cloudService `
    -Location $location `
    -VNetName $virtualNetwork `
    -DnsSettings $dns1, $dns2 `    -VMs $vmConfig
```

---

#### Configure ACLs on endpoints

##### PowerShell endpoint

| **Order** | **Description**    | **Action** | **Remote Subnet** |
| --------- | ------------------ | ---------- | ----------------- |
| 0         | Technology Toolbox | Permit     | 50.246.207.160/30 |

##### Remote Desktop endpoint

| **Order** | **Description**    | **Action** | **Remote Subnet** |
| --------- | ------------------ | ---------- | ----------------- |
| 0         | Technology Toolbox | Permit     | 50.246.207.160/30 |

---

**WOLVERINE**

```PowerShell
$vmName = "FAB-ADFS01"
$cloudService = "fab-adfs"

$vm = Get-AzureVM -ServiceName $cloudService -Name $vmName

$endpointNames = "PowerShell", "RemoteDesktop"

$endpointNames |
    ForEach-Object {
        $endpointName = $_

        $endpoint = $vm | Get-AzureEndpoint -Name $endpointName

        $acl = New-AzureAclConfig

        Set-AzureAclConfig `
            -AddRule `
            -ACL $acl `
            -Action Permit `
            -RemoteSubnet "50.246.207.160/30" `
            -Description "Technology Toolbox" `
            -Order 0

        Set-AzureEndpoint -Name $endpointName -VM $vm -ACL $acl |
            Update-AzureVM

    }
```

---

### # Disable Azure BGInfo extension (conflicts with FABRIKAM logon script)

---

**WOLVERINE**

```PowerShell
$vmName = "FAB-ADFS01"
$cloudService = "fab-adfs"

Get-AzureVM -ServiceName $cloudService -Name $vmName |
    Set-AzureVMBGInfoExtension -Disable |
    Update-AzureVM
```

---

### # Copy Toolbox content

```PowerShell
net use \\ext-dc03.extranet.technologytoolbox.com\IPC$ /USER:EXTRANET\jjameson-admin

Robocopy `
    \\ext-dc03.extranet.technologytoolbox.com\C$\NotBackedUp\Public\Toolbox `
    C:\NotBackedUp\Public\Toolbox /E
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
[string] $adcsHostname = "cipher01.corp.technologytoolbox.com"

[string] $adcsDomainName = $adcsHostname.Split('.')[-2..-1] -join '.'

[string] $adcsHost = $adcsHostname.Substring(
    0,
    $adcsHostName.Length - $adcsDomainName.Length -1)

[string] $registryKey = ("HKCU:\Software\Microsoft\Windows" `
    + "\CurrentVersion\Internet Settings\ZoneMap\EscDomains" `
    + "\" + $adcsDomainName)

If ((Test-Path $registryKey) -eq $false)
{
    New-Item $registryKey | Out-Null
}

$registryKey = $registryKey + "\" + $adcsHost

If ((Test-Path $registryKey) -eq $false)
{
    New-Item $registryKey | Out-Null
}

Set-ItemProperty -Path $registryKey -Name https -Value 2
```

##### # Open Internet Explorer and browse to the ADCS site

```PowerShell
& 'C:\Program Files (x86)\Internet Explorer\iexplore.exe' ("https://" + $adcsHostname)
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

### # Add AD FS server role

```PowerShell
Install-WindowsFeature ADFS-Federation -IncludeManagementTools
```

### Create AD FS farm

1. On the Server Manager **Dashboard** page, click the **Notifications** flag, and then click **Configure the federation service on the server**.
The **Active Directory Federation Service Configuration Wizard** opens.
2. On the **Welcome** page, select **Create the first federation server in a federation server farm**, and then click **Next**.
3. On the **Connect to AD DS** page, specify an account with domain administrator permissions for the Active Directory domain to which this computer is joined, and then click **Next**.
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

### Configure name resolution for AD FS services

---

**FAB-DC01**

#### # Create A record - "fs.fabrikam.com"

```PowerShell
Add-DnsServerResourceRecordA `
    -Name "fs" `
    -IPv4Address 10.71.2.101 `
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

## Publish Outlook Web App using AD FS and preauthentication

### Reference

**Secure Extranet Publication of Exchange 2010 OWA via Server 2012 R2 Web Application Proxy**\
From <[http://blogs.technet.com/b/askpfeplat/archive/2014/05/05/secure-extranet-publication-of-exchange-2010-owa-via-server-2012-r2-web-application-proxy.aspx](http://blogs.technet.com/b/askpfeplat/archive/2014/05/05/secure-extranet-publication-of-exchange-2010-owa-via-server-2012-r2-web-application-proxy.aspx)>

### Configure relying party in AD FS

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5F/3E873E22F6C22320F336B9F04D21265884CA8C5F.png)

1. In the AD FS console, expand **Trust Relationships** and select **Relying Party Trusts**.
2. In the **Actions** pane, click **Add Non-Claims-Aware Relying Party Trust...**
3. In the** Add Non-Claims-Aware Relying Party Trust Wizard**:
   1. On the **Welcome** step, click **Start**.
   2. On the **Specify Display Name** step:
      1. In the **Display name** box, type **Exchange 2010 OWA**.
      2. Click **Next**.
   3. On the **Configure Identifiers** step:
      1. In the **Non-claims-aware relying party trust identifier** box, type **urn:adfs:mail.fabrikam.com** and click **Add**.
      2. Click **Next**.
   4. On the **Configure Multi-factor Authentication Now?** step, ensure **I do not want to configure multi-factor authentication settings for this relying party trust at this time** is selected and click **Next**.
   5. On the **Ready to Add Trust** step, review the specified settings and click **Next**.
   6. Wait for the relying party trust to be configured.
   7. On the **Finish** step, ensure **Open the Edit Issuance Authorization Rules dialog for this non-claims-aware relying party trust when the wizard closes** is selected and click **Close**.
4. In the **Edit Claims Rules for Exchange 2010 OWA** window:
   1. Click **Add Rule...**
   2. In the **Add Issuance Authorization Claim Rule Wizard**:
      1. On the **Select Rule Template** step:
         1. In the **Claim rule template** dropdown list, select **Permit All Users**.
         2. Click **Next**.
      2. On the **Configure Rule** step, click **Finish**.
   3. Click **OK**.

### Configure Kerberos authentication for Exchange Client Access servers

#### Reference

**Configuring Kerberos Authentication for Load-Balanced Client Access Servers**\
From <[https://technet.microsoft.com/en-us/library/ff808312(v=exchg.141).aspx](https://technet.microsoft.com/en-us/library/ff808312(v=exchg.141).aspx)>

#### Create the Alternate Service Account in Active Directory

---

**FAB-DC01**

```PowerShell
$computerName = "EXCHANGE-CAS"
$orgUnit = "OU=Service Accounts,OU=IT,DC=corp,DC=fabrikam,DC=com"

New-ADComputer `
    -Name $computerName `
    -SAMAccountName $computerName `
    -Description "Alternate Service Account (ASA) for Exchange Client Access servers" `
    -Path $orgUnit
```

---

#### Configure Service Principal Names for the Alternate Service Account

---

**FAB-DC01**

```Console
setspn -S http/mail.fabrikam.com EXCHANGE-CAS$
setspn -S http/autodiscover.fabrikam.com EXCHANGE-CAS$
setspn -S exchangeMDB/mail.fabrikam.com EXCHANGE-CAS$
setspn -S exchangeRFR/mail.fabrikam.com EXCHANGE-CAS$
setspn -S exchangeAB/mail.fabrikam.com EXCHANGE-CAS$
```

---

#### Convert the Offline Address Book virtual directory to an application

---

**FAB-EX01**

```Console
cd "C:\Program Files\Microsoft\Exchange Server\V14\Scripts"
```

.\\ConvertOABVDir.ps1

---

#### Deploy the Alternate Service Account to Exchange Client Access servers

---

**FAB-EX01**

Error launching Exchange Management Shell:

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DB/73E5A8DFEBABE26EF7F679852EEDD9470ECC81DB.png)

```PowerShell
Import-Module : There were errors in loading the format data file:
Microsoft.PowerShell, , \\fab-dc01\Users$\jjameson-admin\AppData\Roaming\Microsoft\Exchange\RemotePowerShell\fab-ex01.corp.fabrikam.com\fab-ex01.corp.fabrikam.com.format.ps1xml : File skipped because of the following validation exception:
 File \\fab-dc01\Users$\jjameson-admin\AppData\Roaming\Microsoft\Exchange\RemotePowerShell\fab-ex01.corp.fabrikam.com\fab-ex01.corp.fabrikam.com.format.ps1xml cannot be loaded. The file \\fab-dc01\Users$\jjameson-admin\AppData\Roaming\Microsoft\Exchange\RemotePowerShell\fab-ex01.corp.fabrikam.com\fab-ex01.corp.fabrikam.com.format.ps1xml is not digitally signed. The script will not execute on the system. Please see "get-help about_signing" for more details...
At line:3 char:30
+                 Import-Module <<<<  -Name $name -Alias * -Function * -Prefix $prefix -DisableNameChecking:$disableNam
eChecking -PassThru -ArgumentList @($session)
    + CategoryInfo          : InvalidOperation: (:) [Import-Module], RuntimeException
    + FullyQualifiedErrorId : FormatXmlUpateException,Microsoft.PowerShell.Commands.ImportModuleCommand
```

##### Reference

**PowerShell fomat.ps1xml not reachable**\
From <[http://serverfault.com/questions/214951/powershell-fomat-ps1xml-not-reachable](http://serverfault.com/questions/214951/powershell-fomat-ps1xml-not-reachable)>

##### # HACK: Temporarily change PowerShell execution policy

```PowerShell
Set-ExecutionPolicy -ExecutionPolicy Unrestricted
```

Restart Exchange Management Shell

![(screenshot)](https://assets.technologytoolbox.com/screenshots/94/4F2453E997B4D30D9CDFEFB4B01457AD6595F894.png)

```PowerShell
cd "C:\Program Files\Microsoft\Exchange Server\V14\Scripts"

.\RollAlternateServiceAccountPassword.ps1 `
    -ToSpecificServers FAB-EX01 `
    -GenerateNewPasswordFor FABRIKAM\EXCHANGE-CAS$
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C6/253ABD1D6E91260B93546FAFDBBE315867F16FC6.png)

##### # HACK: Revert PowerShell execution policy

```PowerShell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
```

---

### Publish Outlook Web App

#### Reference

**Publish Applications using AD FS Preauthentication**\
From <[https://technet.microsoft.com/en-us/library/dn383640.aspx](https://technet.microsoft.com/en-us/library/dn383640.aspx)>

#### Enroll SSL certificate for Outlook Web App

##### # Create certificate request

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\New-CertificateRequest.ps1 `
    -Subject "CN=mail.fabrikam.com,OU=IT,O=Fabrikam Technologies,L=Denver,S=CO,C=US" `
    -SANs mail.fabrikam.com,autodiscover.fabrikam.com
```

##### # Submit certificate request to Active Directory Certificate Services

###### # Open Internet Explorer and browse to the ADCS site

```PowerShell
[string] $adcsHostname = "cipher01.corp.technologytoolbox.com"

& 'C:\Program Files (x86)\Internet Explorer\iexplore.exe' ("https://" + $adcsHostname)
```

###### Request certificate

1. On the **Welcome** page of the Active Directory Certificate Services site, in the **Select a task** section, click **Request a certificate**.
2. On the **Advanced Certificate Request** page, click **Submit a certificate request by using a base-64-encoded CMC or PKCS #10 file, or submit a renewal request by using a base-64-encoded PKCS #7 file.**
3. On the **Submit a Certificate Request or Renewal Request** page:
   1. In the **Saved Request** box, copy/paste the certificate request generated previously.
   2. In the **Certificate Template** dropdown list, select **Technology Toolbox Web Server**.
   3. Click **Submit >**.
4. When prompted to allow the Web site to perform a digital certificate operation on your behalf, click **Yes**.
5. On the **Certificate Issued** page, ensure the **DER encoded** option is selected and click **Download certificate**. When prompted to save the certificate file, click **Save**.
6. After the file is saved, open the download folder in Windows Explorer and rename the certificate file to match the subject name (i.e. **mail.fabrikam.com.cer**).

##### # Import certificate

```PowerShell
Import-Certificate `
    -FilePath "C:\Users\jjameson-admin\Downloads\mail.fabrikam.com.cer" `
    -CertStoreLocation Cert:\LocalMachine\My
```

#### Publish the Outlook Web App

```PowerShell
$cert = Get-ChildItem -Path Cert:\LocalMachine\My |
    Where { $_.Subject -like "CN=mail.fabrikam.com,*" }

Add-WebApplicationProxyApplication `
    -ADFSRelyingPartyName 'Exchange 2010 OWA' `
    -Name 'mail.fabrikam.com' `
    -ExternalPreAuthentication ADFS `
    -ExternalUrl 'https://mail.fabrikam.com/' `
    -ExternalCertificateThumbprint $cert.Thumbprint `
    -BackendServerUrl 'https://mail.fabrikam.com/' `
    -BackendServerAuthenticationSpn 'HTTP/mail.fabrikam.com'
```

#### Configure delegation

1. Open the Active Directory Users and Computers console.
2. Locate the organizational unit containing the Web Application Proxy server (**FAB-WAP01**).
3. Right-click the Web Application Proxy server (**FAB-WAP01**) and click **Properties**.
4. In the properties window for the Web Application Proxy server, select the **Delegation** tab.
5. Select **Trust this computer for delegation to specified services only** and then select **Use any authentication protocol**.
6. Click Add...
7. In the **Add Services** window:
   1. Click **Users or Computers...**
   2. In the **Select Users or Computers** window, type **EXCHANGE-CAS** and then click **OK**.
   3. In the Available services list, select the item where **Service Type** is **http** and **User or Computer** is **mail.fabrikam.com**.
   4. Click **OK**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/13/FC040259C6DA486C9AABECB2834BDDB1E8B28213.png)

#### Configure DNS records

---

**WOLVERINE**

#### # Add hostname entries (i.e. FAB-EX01 -> FAB-WAP01 and FAB-ADFS01 -> FAB-WAP01)

```PowerShell
notepad C:\Windows\system32\drivers\etc\hosts
```

Copy/paste the following:

```Text
10.71.2.5	FAB-WAP01 fs.fabrikam.com mail.fabrikam.com
```

---

#### Configure Outlook Web App to use Windows Authentication

![(screenshot)](https://assets.technologytoolbox.com/screenshots/45/8CA90FB280E1EEEE64CA7CADCFA98AAD8E5F7D45.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AB/5E9A44A073FD551340684F7F33A5960D42BE47AB.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C1/2BB3662FE179E79FFE6365FF47A131EFF9BF4EC1.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7C/82845E225FDA75277B7EB427DFD0B3F870E4597C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/04/D42FDF1502170D411C7037FEC2B2CDAE8A0D0504.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/81/258C5C9D9FAA38B168E089D59ED7866679459D81.png)

## Configure SAML-based claims authentication for Fabrikam Portal

**Configure SAML-based claims authentication with AD FS in SharePoint 2013**\
From <[https://technet.microsoft.com/en-us/library/hh305235.aspx](https://technet.microsoft.com/en-us/library/hh305235.aspx)>

### Configure AD FS for a relying party

![(screenshot)](https://assets.technologytoolbox.com/screenshots/22/03263866048CFF92097FCEEB05B68C26F9421722.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5B/5599C7A39BBE6C46AA4483D01DD41D04D0BE275B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FA/505347B3BDC6E11C14C2030320BB87AC1D61E7FA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A7/03EBE8EDE645D27FD5AACBE062E8328E8BC1ACA7.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BD/66B3D2EFE26D057E342D2A24599C03EF53C7C4BD.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/13/44E436F8ED1DCD76D13ECE0F3ACA2907B1E3A913.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/01/F0F45BE740AE55D9AC3237C46BAC0E2BC3BEC101.png)

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

### Export the token signing certificate

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4C/906D8FB6C02086DDA420C82758E414681CFB754C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F7/13DADBC26AF79120B8EE435200836464C5B311F7.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/79/0CA9DDA0EA9473641EECDC1981F92152A24E8779.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7B/2B509DE6154A7B58CC7405E3E9673B4413ED337B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/61/4EBF5EE12B774B2EFE88C04598F22A6FEABD1761.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/57/868C171AC838B07CBE811CF5B43577EC36C66757.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D7/0860970E1874F4574B7106B61197D1637AF905D7.png)

### Phase 3: Configure SharePoint 2013 to trust AD FS as an identity provider

\$emailClaimMap = New-SPClaimTypeMapping -IncomingClaimType "[http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress](http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress)" -IncomingClaimTypeDisplayName "EmailAddress" -SameAsIncoming

\$upnClaimMap = New-SPClaimTypeMapping -IncomingClaimType "[http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn](http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn)" -IncomingClaimTypeDisplayName "UPN" -SameAsIncoming

\$roleClaimMap = New-SPClaimTypeMapping -IncomingClaimType "[http://schemas.microsoft.com/ws/2008/06/identity/claims/role](http://schemas.microsoft.com/ws/2008/06/identity/claims/role)" -IncomingClaimTypeDisplayName "Role" -SameAsIncoming

\$sidClaimMap = New-SPClaimTypeMapping -IncomingClaimType "[http://schemas.microsoft.com/ws/2008/06/identity/claims/primarysid](http://schemas.microsoft.com/ws/2008/06/identity/claims/primarysid)" -IncomingClaimTypeDisplayName "SID" -SameAsIncoming

\$realm = "urn:sharepoint:fabrikam"\
\$signInURL = "[https://fs.fabrikam.com/adfs/ls](https://fs.fabrikam.com/adfs/ls)"\
\$ap = New-SPTrustedIdentityTokenIssuer -Name  -realm \$realm -ImportTrustCertificate \$cert -ClaimsMappi

\$ap = New-SPTrustedIdentityTokenIssuer -Name "SAML Provider" -Description "Fabrikam AD FS" -realm \$realm -ImportTrustCertificate \$cert -ClaimsMappings \$emailClaimMap,\$upnClaimMap,\$roleClaimMap,\$sidClaimMap -SignInUrl \$signInURL -IdentifierClaim \$emailClaimmap.InputClaimType

## # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

## # Configure firewall rules for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
Get-NetFirewallRule |
    Where-Object { $_.Profile -eq 'Domain' `
        -and $_.DisplayName -like 'File and Printer Sharing (Echo Request *-In)' } |
    Enable-NetFirewallRule

New-NetFirewallRule `
    -Name 'Remote Windows Update (Dynamic RPC)' `
    -DisplayName 'Remote Windows Update (Dynamic RPC)' `
    -Description 'Allows remote auditing and installation of Windows updates via POSHPAIG (http://poshpaig.codeplex.com/)' `
    -Group 'Technology Toolbox (Custom)' `
    -Program '%windir%\system32\dllhost.exe' `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort RPC `
    -Profile Domain `
    -Action Allow
```

## # Disable firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
Disable-NetFirewallRule -Name 'Remote Windows Update (Dynamic RPC)'
```

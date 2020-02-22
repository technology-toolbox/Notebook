# FAB-EX01 - Windows Server 2008 R2

Wednesday, May 13, 2015
1:55 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

### Install Windows Server 2008 R2

---

**WOLVERINE** - Run as administrator

```PowerShell
$VerbosePreference = "Continue"
```

#### # Create Azure storage account

```PowerShell
$storageAccount = "fabrikam4"
$location = "West US"

New-AzureStorageAccount `
    -StorageAccountName $storageAccount `
    -Location $location `
    -Type Standard_LRS ` # Replication: Locally Redundant
```

#### # Get list of Windows Server 2008 R2 images

```PowerShell
Get-AzureVMImage |
    where { $_.Label -like "Windows Server 2008 R2*" } |
    select Label, ImageName

# Use latest OS image

$imageName = "a699494373c04fc0bc8f2bb1389d6106__Win2K8R2SP1-Datacenter-201504.01-en.us-127GB.vhd"
```

#### # Create VM

```PowerShell
$localAdminCred = Get-Credential `
    -UserName Administrator `
    -Message "Type the user name and password for the local Administrator account."

$domainCred = Get-Credential `
    -UserName jjameson-admin `
    -Message "Type the user name and password for joining the domain."

$cloudService = "fabrikam-extranet"
$vmName = "FAB-EX01"
$instanceSize = "Standard_D1"
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

$orgUnit = "OU=Servers,OU=Resources,OU=IT,DC=corp,DC=fabrikam,DC=com"
$virtualNetwork = "West US VLAN1"
$subnetName = "Azure-Production"

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
        -MachineObjectOU $orgUnit ` |
    Add-AzureDataDisk `
        -CreateNew `
        -DiskLabel Data01 `
        -DiskSizeInGB 25 `
        -LUN 0 `
        -HostCaching ReadOnly `
        -MediaLocation ($vhdPath + "/$vmName" + "_Data01.vhd") |
    Add-AzureDataDisk `
        -CreateNew `
        -DiskLabel Log01 `
        -DiskSizeInGB 5 `
        -LUN 1 `
        -HostCaching ReadOnly `
        -MediaLocation ($vhdPath + "/$vmName" + "_Log01.vhd") |
    Add-AzureEndpoint -Name SMTP -LocalPort 25 -PublicPort 25 -Protocol tcp |
    Add-AzureEndpoint -Name HTTP -LocalPort 80 -PublicPort 80 -Protocol tcp |
    Add-AzureEndpoint -Name HTTPS -LocalPort 443 -PublicPort 443 -Protocol tcp |
    Set-AzureSubnet -SubnetNames $subnetName

New-AzureVM `
    -ServiceName $cloudService `
    -Location $location `
    -VNetName $virtualNetwork `
    -DnsSettings $dns1, $dns2 `
    -VMs $vmConfig
```

---

### Configure ACLs on endpoints

#### PowerShell endpoint

| **Order** | **Description**    | **Action** | **Remote Subnet** |
| --------- | ------------------ | ---------- | ----------------- |
| 0         | Technology Toolbox | Permit     | 50.246.207.160/30 |

#### Remote Desktop endpoint

| **Order** | **Description**    | **Action** | **Remote Subnet** |
| --------- | ------------------ | ---------- | ----------------- |
| 0         | Technology Toolbox | Permit     | 50.246.207.160/30 |

---

**WOLVERINE** - Run as administrator

#### # Configure endpoint ACLS

```PowerShell
$vm = Get-AzureVM -ServiceName fabrikam-extranet -Name FAB-EX01

$endpointNames = "PowerShell", "Remote Desktop"

$endpointNames |
    foreach {
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

**WOLVERINE** - Run as administrator

```PowerShell
Get-AzureVM -ServiceName fabrikam-extranet -Name FAB-EX01 |
    Set-AzureVMBGInfoExtension -Disable |
    Update-AzureVM
```

---

### # Change drive letter for DVD-ROM

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
```

### Configure VM storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label      | Host Cache |
| ---- | ------------ | ----------- | -------------------- | ----------------- | ---------- |
| 0    | C:           | 127 GB      | 4K                   |                   | Read/Write |
| 1    | D:           | 50 GB       | 4K                   | Temporary Storage |            |
| 2    | E:           | 25 GB       | 64K                  | Data01            | Read Only  |
| 3    | L:           | 5 GB        | 64K                  | Log01             | Read Only  |

### Install Firefox (to download software from MSDN)

```PowerShell
mkdir D:\NotBackedUp\Temp

net use "\\iceman.corp.technologytoolbox.com\Products" /USER:TECHTOOLBOX\jjameson

copy "\\iceman.corp.technologytoolbox.com\Products\Mozilla\Firefox\Firefox Setup 36.0.exe" D:\NotBackedUp\Temp

& 'D:\NotBackedUp\Temp\Firefox Setup 36.0.exe'
```

### Download Exchange Server 2010 ISO from MSDN

### Install Slysoft Virtual CloneDrive (for mounting ISO files)

### Create DNS records for Fabrikam e-mail services

---

**FAB-DC01** - Run as administrator

#### # Create CNAME record - "autodiscover.fabrikam.com"

```PowerShell
Add-DnsServerResourceRecordCName `
    -Name "autodiscover" `
    -HostNameAlias "FAB-EX01.corp.fabrikam.com" `
    -ZoneName "fabrikam.com"
```

#### # Create CNAME record - "mail.fabrikam.com"

```PowerShell
Add-DnsServerResourceRecordCName `
    -Name "mail" `
    -HostNameAlias "FAB-EX01.corp.fabrikam.com" `
    -ZoneName "fabrikam.com"
```

#### # Create CNAME record - "smtp.fabrikam.com"

```PowerShell
Add-DnsServerResourceRecordCName `
    -Name "smtp" `
    -HostNameAlias "FAB-EX01.corp.fabrikam.com" `
    -ZoneName "fabrikam.com"
```

#### # Create MX record - "mail.fabrikam.com"

```PowerShell
Add-DnsServerResourceRecordMX `
    -MailExchange mail.fabrikam.com `
    -Name . `
    -Preference 10 `
    -ZoneName fabrikam.com
```

---

## Install Exchange 2010 prerequisites

### Install Office 2010 Filter Packs

[http://go.microsoft.com/fwlink/?LinkID=191548](http://go.microsoft.com/fwlink/?LinkID=191548)

### Mount Exchange Server 2010 ISO

### Install prerequisites

```Console
F:

cd Scripts

ServerManagerCmd -ip Exchange-Typical.xml -Restart
```

### # Configure the Net.Tcp Port Sharing Service for automatic startup

```PowerShell
Set-Service NetTcpPortSharing -StartupType Automatic
```

## Prepare Active Directory and domains

From <[https://technet.microsoft.com/en-us/library/bb125224(v=exchg.141).aspx](https://technet.microsoft.com/en-us/library/bb125224(v=exchg.141).aspx)>

### Prepare schema

```Console
F:

setup /PrepareSchema

setup /PrepareAD /OrganizationName:"Fabrikam Technologies"

setup /PrepareAllDomains
```

## Install Exchange Server 2010

F:\\SETUP.EXE

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DE/881EE1346305F68CA506E610C028C55AE734ADDE.png)

## # Restart server

Restart-Computer

## Install Exchange Server 2010 Service Pack 2

```Console
D:

cd \NotBackedUp\Temp

"D:\NotBackedUp\Products\Microsoft\Exchange 2010\Patches\Microsoft Exchange Server 2010 Service Pack 2 (SP2)\mu_exchange_server_2010_service_pack_2_x64.exe"
```

> **Important**
>
> Wait for the files to be extracted.

```Console
D:\NotBackedUp\Temp\Setup.exe
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/94/FC18CB793AFB5F0E8A7C4F76DAF576CDAB6E8494.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4E/C0E95168C903840BD30CF6BE55D4DAEA213E214E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/38/4C601777DC382B6D65173DE4EFEE28BB20600838.png)

## Enter product key

## Change default domain from "corp.fabrikam.com" to "fabrikam.com"

```PowerShell
New-AcceptedDomain `
    -Name fabrikam.com `
    -DomainName fabrikam.com `
    -DomainType Authoritative |
    Set-AcceptedDomain -MakeDefault $true

Get-EmailAddressPolicy -Identity "Default Policy" |
    Set-EmailAddressPolicy -EnabledEmailAddressTemplates 'SMTP:@fabrikam.com'

Update-EmailAddressPolicy -Identity "Default Policy"

Remove-AcceptedDomain -Identity corp.fabrikam.com
```

## Rename default mailbox database

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BE/BE28B8430A590038A5A4953C6582EE3032F966BE.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/18/C7FD439D6D2559A6101707A21A3CB1776FDC7C18.png)

## # Move default mailbox database files

```PowerShell
Get-MailboxDatabase |
    Move-DatabasePath `
        -EdbFilePath "E:\Exchange Server\V14\Mailbox\DB1\DB1.edb" `
        -LogFolderPath "L:\Exchange Server\V14\Mailbox\DB1"
```

## Configure certificate

### Reference

**Managing Certificates in Exchange Server 2010 (Part 1)**\
From <[http://www.msexchange.org/articles-tutorials/exchange-server-2010/management-administration/managing-certificates-exchange-server-2010-part1.html](http://www.msexchange.org/articles-tutorials/exchange-server-2010/management-administration/managing-certificates-exchange-server-2010-part1.html)>

### Create certificate request

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CB/5AD55BF825A3F7F170D92A35C4BDA065B2F4F8CB.png)

Click **New Exchange Certificate...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A9/AAC4DF663194086BA6BE5D2570F224B60F3AC2A9.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/30/4AF18B8264AA3BF3769B4DF5017DF5008E06A530.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/05/3F87DA956149B03EDF6720CE6826A27530FF1805.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/86/76C5CCE93ABAD3C59484F8272FCD05B94D1FC786.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/01/CDF575E9B26624B53C1008AA7EB7F1072A062E01.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6D/2AB8DB9C44B3AED46840CD80390E600482E5F66D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/52/078211E16928F1DB6980F94341E1671B3D8F1152.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4F/9BED43AF0EA4EC1A4BC46C35FEC47E60D198804F.png)

Click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B0/3BBF2997639B787A02C7BE65235D91F411EBF7B0.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/07/F5986FF2F25895BD37579EA8A943320574676407.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B6/C052D4851F5224A5A63CFF8B16699B7252D7BFB6.png)

```PowerShell
New-ExchangeCertificate -FriendlyName 'Fabrikam E-mail' -GenerateRequest -PrivateKeyExportable $true -KeySize '2048' -SubjectName 'C=US,S="CO",L="Denver",O="Fabrikam Technologies",OU="IT",CN=mail.fabrikam.com' -DomainName 'fab-ex01.corp.fabrikam.com','mail.fabrikam.com','fabrikam.com','autodiscover.fabrikam.com' -Server 'FAB-EX01'
```

Step 1: Based on the information you provided, you must use a [Unified Communications certificate](Unified Communications certificate). Please get the certificate from a certification authority.

Step 2: Use the Complete Pending Request wizard to map the certificate to the certificate request created on the server.

Step 3: Assign the Exchange services to the certificate using the Assign Services to Certificate wizard.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E4/E02A55E7ACC554D4E81D03C4E1B18CEFBC0F1CE4.png)

### Create certificate

#### # Create certificate using Active Directory Certificate Services

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

Browse to [https://cipher01.corp.technologytoolbox.com](https://cipher01.corp.technologytoolbox.com).

![(screenshot)](https://assets.technologytoolbox.com/screenshots/10/6F890F12858D8A278B214CC8082EFEB48E583510.png)

Click **Request a certificate**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B2/F2C70E2873CA5FBC949F4E308B4863EBC084D8B2.png)

Click **Submit a certificate request by using a base-64-encoded CMC or PKCS #10 file, or submit a renewal request by using a base-64-encoded PKCS #7 file.**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DE/35FA6C3C953425DBF7A844268D48F099F6E601DE.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/97/05800E882A75A3D9A01B1512998DE8FB734FFE97.png)

Click **Submit**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/65/1FEE9498AE08C24EBCEB1E5EDD965FA72D96EA65.png)

Click **Yes**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FE/2D4884D0AD83D74E046E1CD52E61876AAF95D3FE.png)

Click **Download certificate**.

Copy certificate to FAB-EX01.

### Import certificate

![(screenshot)](https://assets.technologytoolbox.com/screenshots/03/46CEFE2EE46C4E6A7D41E35CFC4C4E213CEBD603.png)

In the Exchange Certificates tab, select the **Fabrikam E-mail** pending request.\
Click **Complete Pending Request...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DD/0B52766AB0C39D8F70DBDA91AD18EA409CD6E8DD.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B9/A1CAC30152B9476A4A38F12B05DAC276704927B9.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A2/861FEC6357D4C54096E8CAFB8905F861F83A7EA2.png)

```PowerShell
Import-ExchangeCertificate -Server 'FAB-EX01' -FileData '<Binary Data>'
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6F/9328AACAC797C95F211A0480DDD9535C8E42046F.png)

Click **Assign Services to Certificate...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/20/104B8D06AF821416B5761629489B52A5622A3520.png)

Click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CE/0CC3DE0FEC916B31780F5C2E2A4EB7A34C553DCE.png)

On the **Select Services** step:

1. Select:
   1. **Internet Message Access Protocol (IMAP)**
   2. **Post Office Protocol (POP)**
   3. **Simple Mail Transfer Protocol (SMTP)**
   4. **Internet Information Services (IIS)**
2. Click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3D/E0FDF558813E9E8479964955DF6405DB18EB9E3D.png)

Click **Assign**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0B/C0F68E1BFA3FDBE0F3FA41F714BB025567C0A30B.png)

Click **Yes**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6E/4C6ACB7D1CEF68818441C99875CC62896D43706E.png)

```PowerShell
Enable-ExchangeCertificate -Server 'FAB-EX01' -Services 'IMAP, POP, IIS, SMTP' -Thumbprint '4AE773744C7CDE6552EC41F66BC8F860369F8AC4'
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/85/FFBB2F162B3FDC57E6E6869702EDEFEEC8389685.png)

## # Create mailboxes for existing users

```PowerShell
Enable-Mailbox -Identity FABRIKAM\agiordano
Enable-Mailbox -Identity FABRIKAM\amason
Enable-Mailbox -Identity FABRIKAM\jjameson
Enable-Mailbox -Identity FABRIKAM\mmeyers
Enable-Mailbox -Identity FABRIKAM\nvelez
Enable-Mailbox -Identity FABRIKAM\rdai
Enable-Mailbox -Identity FABRIKAM\sadams
Enable-Mailbox -Identity FABRIKAM\test1
Enable-Mailbox -Identity FABRIKAM\test2
Enable-Mailbox -Identity FABRIKAM\smasters
```

## Simplify the Outlook Web App URL

From <[https://technet.microsoft.com/en-us/library/aa998359(v=exchg.141).aspx](https://technet.microsoft.com/en-us/library/aa998359(v=exchg.141).aspx)>

### Use IIS Manager to simplify the Outlook Web App URL when SSL is required

1. Start IIS Manager.
2. Expand the local computer, expand **Sites**, and then click **Default Web Site**.
3. At the bottom of the **Default Web Site Home** pane, click **Features View** if this option isn't already selected.
4. In the **IIS** section, double-click **HTTP Redirect**.
5. Select the **Redirect requests to this destination** check box.
6. Type the absolute path of the /owa virtual directory - **[https://mail.fabrikam.com/owa](https://mail.fabrikam.com/owa)**.
7. Under **Redirect Behavior**, select the **Only redirect requests to content in this directory (not subdirectories)** check box.
8. In the **Status code** list, click **Found (302)**.
9. In the **Actions** pane, click **Apply**.
10. Click **Default Web Site**.
11. In the **Default Web Site Home** pane, double-click **SSL Settings**.
12. In the **SSL Settings** pane, clear the **Require SSL** checkbox.
13. In the **Actions** pane, click **Apply**.

### Test Outlook Web App

1. Open Internet Explorer and browse to [http://mail.fabrikam.com](http://mail.fabrikam.com)
2. Confirm the browser automatically redirects to [https://mail.fabrikam.com/owa](https://mail.fabrikam.com/owa)
3. On the Outlook Web App login page, type the user credentials and click **Sign in**.
4. Confirm the Exchange inbox is displayed.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/84/9F398A16AECB05A9372BB8B0186CC38DA2CD1484.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B8/40CB412BD3DB7DF4888C14A0F119B659E2776DB8.png)

## Create SMTP send connector (for outbound mail)

**Create an SMTP Send Connector**\
From <[https://technet.microsoft.com/en-us/library/aa997285(v=exchg.141).aspx](https://technet.microsoft.com/en-us/library/aa997285(v=exchg.141).aspx)>

```PowerShell
New-SendConnector `
    -Name "Internet" `
    -Usage Internet `
    -AddressSpaces "*" `
    -SourceTransportServers "FAB-EX01" `
    -DNSRoutingEnabled:$true `
    -UseExternalDNSServersEnabled:$false
```

## Allow anonymous access on receive connector (for inbound mail)

**Configure Internet Mail Flow Directly Through a Hub Transport Server**\
From <[https://technet.microsoft.com/en-us/library/bb738138(v=exchg.141).aspx](https://technet.microsoft.com/en-us/library/bb738138(v=exchg.141).aspx)>

```PowerShell
Set-ReceiveConnector `
    -Identity "FAB-EX01\Default FAB-EX01" `
    -PermissionGroups AnonymousUsers,
        ExchangeUsers,
        ExchangeServers,
        ExchangeLegacyServers
```

## Install Exchange Server 2010 Service Pack 3

```Console
D:

cd \NotBackedUp\Temp

"D:\NotBackedUp\Products\Microsoft\Exchange 2010\Patches\Microsoft Exchange Server 2010 Service Pack 3 (SP3)\Exchange2010-SP3-x64.exe"
```

> **Important**
>
> Wait for the files to be extracted.

```Console
D:\NotBackedUp\Temp\Patch\Setup.exe
```

## Install Update Rollup 6 for Exchange Server 2010 Service Pack 3

```Console
D:

cd \NotBackedUp\Temp

"D:\NotBackedUp\Products\Microsoft\Exchange 2010\Patches\Update Rollup 6 For Exchange 2010 SP3 (KB2936871)\Exchange2010-KB2936871-x64-en.msp"
```

## Fix the Outlook Web App

Applying Exchange Server SP3 reverts the configuration change made previously in IIS Manager to clear the **Require SSL** option on the Outlook Web App.

1. Start IIS Manager.
2. Expand the local computer, expand **Sites**, and then click **Default Web Site**.
3. At the bottom of the **Default Web Site Home** pane, click **Features View** if this option isn't already selected.
4. In the **Default Web Site Home** pane, double-click **SSL Settings**.
5. In the **SSL Settings** pane, clear the **Require SSL** checkbox.
6. In the **Actions** pane, click **Apply**.

## Security vulnerability - credentials may be sent in clear text over HTTP

### Repro steps

1. Open Internet Explorer and browse to [http://mail.fabrikam.com/owa](http://mail.fabrikam.com/owa)
   > **Note:** In this case, IIS does not redirect to [https://mail.fabrikam.com/owa](https://mail.fabrikam.com/owa).
2. On the Outlook Web App login page, type the user credentials and click **Sign in**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/78/912114981A271CBDF9338BC9589B358FFE92C378.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4E/91924AC40EEF3261400A3580F0F10C6C8F93EF4E.png)

### Resolution

Revert the configuration change made previously in IIS Manager to clear the **Require SSL** option on the Outlook Web App.

1. Start IIS Manager.
2. Expand the local computer, expand **Sites**, and then click **Default Web Site**.
3. At the bottom of the **Default Web Site Home** pane, click **Features View** if this option isn't already selected.
4. In the **Default Web Site Home** pane, double-click **SSL Settings**.
5. In the **SSL Settings** pane, select the **Require SSL** checkbox.
6. In the **Actions** pane, click **Apply**.

### Test Outlook Web App

1. Open Internet Explorer and browse to [http://mail.fabrikam.com](http://mail.fabrikam.com)
2. Confirm an HTTP 403 error is returned.
3. Open Internet Explorer and browse to [https://mail.fabrikam.com](https://mail.fabrikam.com)
4. Confirm the browser automatically redirects to [https://mail.fabrikam.com/owa](https://mail.fabrikam.com/owa)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/07/B208EDB561A2DB31D53F5F83C3B6E900E23FA107.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/39/62019D5D9B08A4030580056173DB44F4B61FA539.png)

### Test Exchange control panel

1. Open Internet Explorer and browse to [http://mail.fabrikam.com/ecp](http://mail.fabrikam.com/ecp)
2. Confirm an HTTP 403 error is returned.
3. Open Internet Explorer and browse to [https://mail.fabrikam.com/ecp](https://mail.fabrikam.com/ecp)
4. Confirm the browser automatically redirects to the OWA login form.
5. On the Outlook Web App login page, type the user credentials and click **Sign in**.
6. Confirm the Exchange control panel is displayed.
7. Click **sign out**.
8. Close Internet Explorer and then open a new instance.
9. Browse to [https://mail.fabrikam.com/ecp](https://mail.fabrikam.com/ecp) and login using credentials for an Exchange administrator.
10. Confirm the Exchange control panel is displayed as expected.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B9/287C255A38614093A5EA8B28801D5919CC3591B9.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/84/9F398A16AECB05A9372BB8B0186CC38DA2CD1484.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/19/8106C36C72E3E5E05963BD0E90B23FE37857F619.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DA/AEB8F34BDC0F028909E2AD3A2DD9BBEEB7FB94DA.png)

## Simplify the Outlook Web App URL

### Use IIS Manager to simplify the Outlook Web App URL when SSL is required

1. Start IIS Manager.
2. In the **Connections** pane, expand the local computer, expand **Sites**, and then click **Default Web Site**.
3. At the bottom of the **Default Web Site Home** pane, click **Features View** if this option isn't already selected.
4. In the **IIS** section, double-click **HTTP Redirect**.
5. Select the **Redirect requests to this destination** check box.
6. Type the absolute path of the /owa virtual directory - **[https://mail.fabrikam.com/owa](https://mail.fabrikam.com/owa)**.
7. Under **Redirect Behavior**, select the **Only redirect requests to content in this directory (not subdirectories)** check box.
8. In the **Status code** list, click **Found (302)**.
9. In the **Actions** pane, click **Apply**.
10. In the **Connections** pane, select **Default Web Site**.
11. In the **Default Web Site Home** pane, double-click **SSL Settings**.
12. In the **SSL Settings** pane, clear the **Require SSL** checkbox.
13. In the **Actions** pane, click **Apply**.
14. In the **Connections** pane, expand **Default Web Site**, and then select **owa**.
15. In the **/owa Home** pane, double-click **SSL Settings**.
16. In the **SSL Settings** pane, select the **Require SSL** checkbox.
17. In the **Actions** pane, click **Apply**.
18. In the **Connections** pane, expand **Default Web Site**, and then select **ecp**.
19. In the **/ecp Home** pane, double-click **SSL Settings**.
20. In the **SSL Settings** pane, select the **Require SSL** checkbox.
21. In the **Actions** pane, click **Apply**.

### Test Outlook Web App

1. Open Internet Explorer and browse to [http://mail.fabrikam.com](http://mail.fabrikam.com)
2. Confirm the browser automatically redirects to [https://mail.fabrikam.com/owa](https://mail.fabrikam.com/owa)
3. On the Outlook Web App login page, type the user credentials and click **Sign in**.
4. Confirm the Exchange inbox is displayed.
5. Restart Internet Explorer and browse to [http://mail.fabrikam.com/owa](http://mail.fabrikam.com/owa).
6. Confirm an HTTP 403 error is returned.
7. Open Internet Explorer and browse to [https://mail.fabrikam.com/ecp](https://mail.fabrikam.com/ecp).
8. Confirm an HTTP 403 error is returned.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/84/9F398A16AECB05A9372BB8B0186CC38DA2CD1484.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B8/40CB412BD3DB7DF4888C14A0F119B659E2776DB8.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9D/3BAE92BE5C4E4D2BB659BF709299459DFACCB89D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/74/9856A066F686690FFE37FAF30EB4D5525AD53474.png)

## Resolve EdgeSync initialization issue

### Issue

```Text
Log Name:      Application
Source:        MSExchange EdgeSync
Date:          6/19/2015 6:31:53 PM
Event ID:      1045
Task Category: Initialization
Level:         Warning
Keywords:      Classic
User:          N/A
Computer:      FAB-EX01.corp.fabrikam.com
Description:
Initialization failed with exception: Microsoft.Exchange.EdgeSync.Common.EdgeSyncServiceConfigNotFoundException: Couldn't find EdgeSync service configuration object for the site Azure-West-US. If the configuration object doesn't exist in the Active Directory location CN=EdgeSyncService,CN=Azure-West-US,CN=Sites,CN=Configuration,DC=corp,DC=fabrikam,DC=com, create it using the New-EdgeSyncServiceConfig cmdlet. If the object does exist, check its permissions.. If this warning frequently occurs, contact Microsoft Product Support.
```

### # Resolution

```PowerShell
New-EdgeSyncServiceConfig
```

## Configure conference rooms

---

**FAB-DC01** - Run as administrator

### # Create OU for conference rooms

```PowerShell
New-ADOrganizationalUnit -Name 'Resources'

New-ADOrganizationalUnit `
    -Name 'Conference Rooms' `
    -Path 'OU=Resources,DC=corp,DC=fabrikam,DC=com'
```

---

### # Create mailboxes for conference rooms

```PowerShell
$orgUnit = 'corp.fabrikam.com/Resources/Conference Rooms'

New-Mailbox `
    -Name 'Blanca Peak (Conference Room)' `
    -Room `
    -OrganizationalUnit $orgUnit `
    -ResourceCapacity 8 `
    -SamAccountName 'r-blancapeak' `
    -UserPrincipalName 'r-blancapeak@corp.fabrikam.com'

Organizational unit "corp.fabrikam.com/Resources/Conference Rooms" was not found. Please make sure you have typed it correctly.
    + CategoryInfo          : NotSpecified: (:) [], ManagementObjectNotFoundException
    + FullyQualifiedErrorId : 382C1DB8
```

**Workaround:** Force replication from FAB-DC01 to FAB-DC02 using Active Directory Sites and Services.

```PowerShell
New-Mailbox `
    -Name 'Blanca Peak (Conference Room)' `
    -Room `
    -OrganizationalUnit $orgUnit `
    -ResourceCapacity 8 `
    -SamAccountName 'r-blancapeak' `
    -UserPrincipalName 'r-blancapeak@corp.fabrikam.com'

New-Mailbox `
    -Name 'Crestone Peak (Conference Room)' `
    -Room `
    -OrganizationalUnit $orgUnit `
    -ResourceCapacity 12 `
    -SamAccountName 'r-crestonepeak' `
    -UserPrincipalName 'r-crestonepeak@corp.fabrikam.com'

New-Mailbox `
    -Name 'Longs Peak (Conference Room)' `
    -Room `
    -OrganizationalUnit $orgUnit `
    -ResourceCapacity 22 `
    -SamAccountName 'r-longspeak' `
    -UserPrincipalName 'r-longspeak@corp.fabrikam.com'

New-Mailbox `
    -Name 'Mount Elbert (Conference Room)' `
    -Room `
    -OrganizationalUnit $orgUnit `
    -ResourceCapacity 50 `
    -SamAccountName 'r-mtelbert' `
    -UserPrincipalName 'r-mtelbert@corp.fabrikam.com'

New-Mailbox `
    -Name 'Mount Evans(Conference Room)' `
    -Room `
    -OrganizationalUnit $orgUnit `
    -ResourceCapacity 16 `
    -SamAccountName 'r-mtevans' `
    -UserPrincipalName 'r-mtevans@corp.fabrikam.com'

New-Mailbox `
    -Name 'Mount Shavano (Conference Room)' `
    -Room `
    -OrganizationalUnit $orgUnit `
    -ResourceCapacity 12 `
    -SamAccountName 'r-mtshavano' `
    -UserPrincipalName 'r-mtshavano@corp.fabrikam.com'

$rooms = Get-Mailbox -RecipientTypeDetails RoomMailbox

$rooms |
    foreach {
        Set-CalendarProcessing `
            -Identity $_.Name `
            -AutomateProcessing AutoAccept
    }

$rooms |
    foreach {
        Set-MailboxFolderPermission `
            -Identity $_":\Calendar" `
            -User Default `
            -AccessRights Reviewer
    }

Enable-DistributionGroup "Account Managers" `
    -PrimarySmtpAddress "sales-accountmanagers@fabrikam.com"

Enable-DistributionGroup "Sales Management" `
    -PrimarySmtpAddress "sales-management@fabrikam.com"

Enable-DistributionGroup "Sales Support" `
    -PrimarySmtpAddress "sales-Support@fabrikam.com"

Enable-DistributionGroup "All Sales Staff" `
    -PrimarySmtpAddress "sales-all@fabrikam.com"
```

## # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

## # Configure firewall rules for [http://poshpaig.codeplex.com/](POSHPAIG)

```PowerShell
netsh advfirewall firewall add rule `
    name="Remote Windows Update (Dynamic RPC)" `
    description="Allows remote auditing and installation of Windows updates via POSHPAIG (http://poshpaig.codeplex.com/)" `
    program="%windir%\system32\dllhost.exe" `
    dir=in `
    protocol=TCP `
    localport=RPC `
    profile=Domain `
    action=Allow
```

## # Disable firewall rule for [http://poshpaig.codeplex.com/](POSHPAIG)

```PowerShell
netsh advfirewall firewall set rule `
    name="Remote Windows Update (Dynamic RPC)" new enable=no
```

## Restart All Services Exchange Server 2010

**Restart All Exchange 2007/2010 Services With PowerShell Script**\
From <[http://heresjaken.com/restart-exchange-services-with-script/](http://heresjaken.com/restart-exchange-services-with-script/)>

```PowerShell
Stop-Service MSExchangeAB
Stop-Service MSExchangeAntispamUpdate
Stop-Service MSExchangeEdgeSync
Stop-Service MSExchangeFBA
Stop-Service MSExchangeFDS
Stop-Service MSExchangeIS
Stop-Service MSExchangeMailboxAssistants
Stop-Service MSExchangeMailboxReplication
Stop-Service MSExchangeMailSubmission
Stop-Service MSExchangeProtectedServiceHost
Stop-Service MSExchangeRepl
Stop-Service MSExchangeRPC
Stop-Service MSExchangeSA
Stop-Service MSExchangeSearch
Stop-Service MSExchangeServiceHost
Stop-Service MSExchangeThrottling
Stop-Service MSExchangeTransport
Stop-Service MSExchangeTransportLogSearch
Stop-Service MSExchangeADTopology -Force

Start-Service MSExchangeADTopology
Start-Service MSExchangeAB
Start-Service MSExchangeAntispamUpdate
Start-Service MSExchangeEdgeSync
Start-Service MSExchangeFBA
Start-Service MSExchangeFDS
Start-Service MSExchangeIS
Start-Service MSExchangeMailboxAssistants
Start-Service MSExchangeMailboxReplication
Start-Service MSExchangeMailSubmission
Start-Service MSExchangeProtectedServiceHost
Start-Service MSExchangeRepl
Start-Service MSExchangeRPC
Start-Service MSExchangeSA
Start-Service MSExchangeSearch
Start-Service MSExchangeServiceHost
Start-Service MSExchangeThrottling
Start-Service MSExchangeTransport
Start-Service MSExchangeTransportLogSearch
```

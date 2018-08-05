# CIPHER01 - Windows Server 2012 R2 Standard

Sunday, February 23, 2014
5:52 PM

```Console
12345678901234567890123456789012345678901234567890123456789012345678901234567890

PowerShell
```

---

**STORM**

### # Create virtual machine (CIPHER01)

```PowerShell
$vmName = "CIPHER01"

New-VM `
    -Name $vmName `
    -Path C:\NotBackedUp\VMs `
    -MemoryStartupBytes 1GB `
    -SwitchName "Virtual LAN 2 - 192.168.10.x"

$sysPrepedImage =
    "\\ICEMAN\VM-Library\VHDs\ws2012std-r2.vhd"

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

Convert-VHD `
    -Path $sysPrepedImage `
    -DestinationPath $vhdPath

Set-VHD $vhdPath -PhysicalSectorSizeBytes 4096

Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath

Start-VM $vmName
```

---

## # Rename the server and join domain

```PowerShell
Rename-Computer -NewName CIPHER01 -Restart

Add-Computer -DomainName corp.technologytoolbox.com -Restart
```

## # Download PowerShell help files

```PowerShell
Update-Help -SourcePath \\iceman\Public\Download\Microsoft\PowerShell\Help

# Error downloading help file

Update-Help
```

## # Change drive letter for DVD-ROM

### # To change the drive letter for the DVD-ROM using PowerShell

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
```

## # Rename network connection

```PowerShell
Get-NetAdapter -Physical

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "LAN 1 - 192.168.10.x"
```

## # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name "LAN 1 - 192.168.10.x" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

ping ICEMAN -f -l 8900
```

## # Install SCOM agent

```PowerShell
$imagePath = '\\iceman\Products\Microsoft\System Center 2012 R2' `
    + '\en_system_center_2012_r2_operations_manager_x86_and_x64_dvd_2920299.iso'

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$msiPath = $imageDriveLetter + ':\agent\AMD64\MOMAgent.msi'

msiexec.exe /i $msiPath `
    MANAGEMENT_GROUP=HQ `
    MANAGEMENT_SERVER_DNS=JUBILEE `
    ACTIONS_USE_COMPUTER_ACCOUNT=1
```

## # Approve manual agent install in Operations Manager

## # Distribute the root CA certificate

### # [STORM] Remove virtual floppy disk from root CA VM

```PowerShell
$vmName = "CRYPTID"

Set-VMFloppyDiskDrive -VMName $vmName -Path $null
```

### # [STORM] Configure virtual floppy disk containing offline root CA files

```PowerShell
$vmName = "CIPHER01"

$vfdPath = "C:\NotBackedUp\VMs\CRYPTID\Virtual Floppy Disks\CRYPTID.vfd"

Set-VMFloppyDiskDrive -VMName $vmName -Path $vfdPath
```

### # Publish root CA to Active Directory and CIPHER01

```PowerShell
A:

certutil -dspublish -f `
    "Technology Toolbox Root Certificate Authority.crt" RootCA

certutil -addstore -f `
    root "Technology Toolbox Root Certificate Authority.crt"

certutil -addstore -f `
    root "Technology Toolbox Root Certificate Authority.crl"
```

**Note**

The first command places the root CA public certificate into the Configuration container of Active Directory. Doing so allows domain client computers to automatically trust the root CA certificate and there is no additional need to distribute that certificate in Group Policy. The second and third commands place the root CA certificate and CRL into the local store of CIPHER01. This provides CIPHER01 immediate trust of root CA public certificate and knowledge of the root CA CRL. CIPHER01 could obtain the certificate from Group Policy and the CRL from the CDP location, but publishing these two items to the local store on CIPHER01 is helpful to speed the configuration of CIPHER01 as a subordinate CA.

## Prepare the CAPolicy.inf for the issuing CA

1. At the command prompt, type the following:
2. When prompted to create a new file, click **Yes**.
3. Enter the following as the contents of the file:
4. On the **File** menu, click **Save As**.
5. In the **Save As** window:
   1. Ensure the following:
   2. **File name** is set to **CAPolicy.inf**
   3. **Save as type** is set to **All Files**
   4. **Encoding** is set to **ANSI**
   5. Click **Save**.
6. When you are prompted to replace the file, click **Yes**.
7. Close Notepad.

```Console
    notepad C:\Windows\CAPolicy.inf
```

```INI
    [Version]
    Signature="$Windows NT$"
    ; Configuration for issuing CA

    [PolicyStatementExtension]
    Policies=CertificatePolicy

    [CertificatePolicy]
    OID=1.3.6.1.4.1.42625.1.1.1
    URL=http://pki.technologytoolbox.com/cps

    [Certsrv_Server]
    RenewalKeyLength=2048
    RenewalValidityPeriod=Years
    RenewalValidityPeriodUnits=5
    LoadDefaultTemplates=0
    AlternateSignatureAlgorithm=1
```

## # [STORM] Checkpoint VM

```PowerShell
Checkpoint-VM CIPHER01
```

## # Install ADCS and IIS features on the issuing CA

```PowerShell
Install-WindowsFeature `
    Adcs-Cert-Authority, Adcs-Web-Enrollment, Web-Mgmt-Console `
    -IncludeManagementTools
```

## # Configure Web server to distribute certificates and CRLs

### # [WIN8-TEST1] Add DNS record for pki.technologytoolbox.com

```PowerShell
Add-DNSServerResourceRecordCName `
    -ComputerName XAVIER1 `
    -ZoneName technologytoolbox.com `
    -Name pki `
    -HostNameAlias CIPHER01.corp.technologytoolbox.com
```

### # Create Web site (pki.technologytoolbox.com)

```PowerShell
$siteName = "pki.technologytoolbox.com"

$sitePath = "C:\inetpub\wwwroot\" + $siteName
$appPoolIdentity = "IIS APPPOOL\" + $siteName

Write-Host "Creating application pool ($siteName)..."
$appPool = New-WebAppPool -Name $siteName
Write-Host "Successfully created application pool ($siteName)."

Write-Host "Creating website folder ($sitePath)..."
New-Item -Type Directory -Path $sitePath > $null
Write-Host "Successfully created website folder ($sitePath)."

Write-Host "Creating website ($sitePath)..."
New-Website `
    -Name $siteName `
    -HostHeader $siteName `
    -PhysicalPath $sitePath `
    -ApplicationPool $siteName > $null

Write-Host "Successfully created website ($sitePath)."
```

### # Allow double escaping for publishing Delta CRLs to IIS (because the Delta CRL file contains a '+'

### # symbol)

```PowerShell
Set-WebConfiguration `
    -Filter system.webServer/security/requestFiltering `
    -PSPath ('IIS:\sites\' + $siteName) `
    -Value @{allowDoubleEscaping = $true}
```

### # Create folders for PKI files

```PowerShell
New-Item -Type Directory -Path "$sitePath\certs" > $null
New-Item -Type Directory -Path "$sitePath\cps" > $null
New-Item -Type Directory -Path "$sitePath\crl" > $null
```

### # Create file share for copying certificate and CRL files

```PowerShell
New-SmbShare `
    -Name "PKI$" `
    -Path $sitePath `
    -CachingMode None `
    -ChangeAccess SYSTEM `
    -FullAccess Administrators
```

### # Create default pages

```PowerShell
Set-Content `
    -Path ($sitePath + "\default.htm") `
    "<html><body><h1>Technology Toolbox PKI</h1></body></html>"

Set-Content `
    -Path ($sitePath + "\cps\default.htm") `
    "<html><body><h1>Technology Toolbox Certification Practice Statement (CPS)</h1></body></html>"
```

## # Install Certification Authority role on the issuing CA

```PowerShell
Install-AdcsCertificationAuthority `
    -CAType EnterpriseSubordinateCA `-CACommonName "Technology Toolbox Issuing Certificate Authority 01" `-KeyLength 2048 `-HashAlgorithmName SHA256 `-CryptoProviderName "RSA#Microsoft Software Key Storage Provider"
```

WARNING: The Active Directory Certificate Services installation is incomplete. To complete the installation, use the request file "C:\\CIPHER01.corp.technologytoolbox.com_Technology Toolbox Issuing Certificate Authority 01.req" to obtain a certificate from the parent CA. Then, use the Certification Authority snap-in to install the certificate. To complete this procedure, right-click the node with the name of the CA, and then click Install CA Certificate. The operation completed successfully. 0x0 (WIN32: 0)

```PowerShell
Move-Item C:\*.req A:
```

### # [STORM] Remove virtual floppy disk from CIPHER01

```PowerShell
$vmName = "CIPHER01"

Set-VMFloppyDiskDrive -VMName $vmName -Path $null
```

### # [STORM] Insert virtual floppy disk into CRYPTID

```PowerShell
$vmName = "CRYPTID"

Set-VMFloppyDiskDrive -VMName $vmName -Path $vfdPath
```

- On CRYPTID, from Windows PowerShell, submit the request using the following command:
- In the **Certification Authority List **window, ensure that **Technology Toolbox Root Certificate Authority (Kerberos)** CA is selected and then click **OK**.
- Note that the certificate request is pending. Make a note of the request ID number.
- On ORCA1, you must approve the request. You can do this using Server Manager or by using certutil from the command line.
  - To use certutil, enter Certutil -resubmit _`<RequestId>`_, replace the actual request number for `<RequestId>`. For example, if the Request ID is 2, you would enter:
- From the command prompt on ORCA1, retrieve the issued certificate by running the command
- In the **Certification Authority List **window, ensure that **Technology Toolbox Root Certificate Authority (Kerberos)** CA is selected and then click **OK**.

```Console
certreq.exe -submit 'A:\CIPHER01.corp.technologytoolbox.com_Technology Toolbox Issuing Certificate Authority 01.req'
```

```Console
certutil.exe -resubmit 2
```

```Console
certreq.exe -retrieve 2 'A:\Technology Toolbox Issuing Certificate Authority 01.crt'
```

### # Verify the certificate

```PowerShell
certutil.exe -verify 'A:\Technology Toolbox Issuing Certificate Authority 01.crt'
```

### # [STORM] Remove virtual floppy disk from root CA VM

```PowerShell
$vmName = "CRYPTID"

Set-VMFloppyDiskDrive -VMName $vmName -Path $null
```

### # [STORM] Configure virtual floppy disk containing offline root CA files

```PowerShell
$vmName = "CIPHER01"

$vfdPath = "C:\NotBackedUp\VMs\CRYPTID\Virtual Floppy Disks\CRYPTID.vfd"

Set-VMFloppyDiskDrive -VMName $vmName -Path $vfdPath
```

### # Copy CRL for root CA to PKI website

```PowerShell
Copy-Item `
    "A:\Technology Toolbox Root Certificate Authority.crl" `
    "\\CIPHER01\PKI$\crl"
```

### # Copy certificate for root CA to PKI website

```PowerShell
Copy-Item `
    "A:\Technology Toolbox Root Certificate Authority.crt" `
    "\\CIPHER01\PKI$\certs"
```

### # Install the issuing CA certificate

```PowerShell
certutil.exe -installcert 'A:\Technology Toolbox Issuing Certificate Authority 01.crt'
```

### # Start the certificate service

```PowerShell
Start-Service certsvc
```

### # Rename certificate for issuing CA to remove server name

```PowerShell
Rename-Item `
    ("C:\Windows\System32\certsrv\CertEnroll\" `
        + "CIPHER01.corp.technologytoolbox.com" `
        + "_Technology Toolbox Issuing Certificate Authority 01.crt") `
    "Technology Toolbox Issuing Certificate Authority 01.crt"
```

### # [STORM] Remove virtual floppy disk from issuing CA VM

```PowerShell
$vmName = "CIPHER01"

Set-VMFloppyDiskDrive -VMName $vmName -Path $null
```

### # [STORM] Delete virtual floppy disk

```PowerShell
Remove-Item $vfdPath
```

## # [STORM] Shutdown root CA (CRYPTID)

## # Configure the issuing CA settings

### # CA configuration script for a Windows Server 2012 R2 issuing CA

#### # Configure CRL and AIA CDP

```PowerShell
certutil -setreg CA\CRLPublicationURLs `
    ("65:C:\Windows\System32\CertSrv\CertEnroll\%3%8%9.crl\n" `
    + "2:http://pki.technologytoolbox.com/crl/%3%8%9.crl\n" `
    + "65:file://CIPHER01\PKI$\crl\%3%8%9.crl")

certutil -setreg CA\CACertPublicationURLs `
    ("2:http://pki.technologytoolbox.com/certs/%3%4.crt\n" `
    + "1:file://CIPHER01\PKI$\certs\%3%4.crt")
```

#### # Configure CRL publication

```PowerShell
certutil -setreg CA\CRLPeriodUnits 2
certutil -setreg CA\CRLPeriod "Weeks"
```

#### # Configure delta CRL publication

```PowerShell
certutil -setreg CA\CRLDeltaPeriodUnits 1
certutil -setreg CA\CRLDeltaPeriod "Days"
```

#### # Configure CRL publication

```PowerShell
certutil -setreg CA\CRLOverlapPeriodUnits 12
certutil -setreg CA\CRLOverlapPeriod "Hours"
```

#### # Set the validity period for issued certificates

```PowerShell
certutil -setreg CA\ValidityPeriodUnits 5
certutil -setreg CA\ValidityPeriod "Years"
```

#### # Enable all auditing on the CA

```PowerShell
certutil -setreg CA\AuditFilter 127
```

#### # Restart the CA server service

```PowerShell
Restart-Service certsvc
```

#### # Republish the CRL

```PowerShell
certutil -CRL
```

#### # Rename certificate for issuing CA to remove server name

```PowerShell
Remove-Item `
    ("C:\Windows\System32\certsrv\CertEnroll\" `
        + "Technology Toolbox Issuing Certificate Authority 01.crt")

Rename-Item `
    ("C:\Windows\System32\certsrv\CertEnroll\" `
        + "CIPHER01.corp.technologytoolbox.com" `
        + "_Technology Toolbox Issuing Certificate Authority 01.crt") `
    "Technology Toolbox Issuing Certificate Authority 01.crt"
```

#### # Copy the issuing CA certificate the PKI website

```PowerShell
Copy-Item C:\Windows\System32\certsrv\CertEnroll\*.crt `
    "\\CIPHER01\PKI$\certs"
```

## # Install ADCS Web Enrollment on issuing CA

```PowerShell
Install-AdcsWebEnrollment
```

## # Enable SSL on ADCS Web Enrollment site

### Reference

**Installing a Two Tier PKI Hierarchy in Windows Server 2012: Part VII, Enabling SSL on the Web Enrollment Website**\
Pasted from <[http://blogs.technet.com/b/xdot509/archive/2013/03/07/installing-a-two-tier-pki-hierarchy-in-windows-server-2012-part-vii-enabling-ssl-on-the-web-enrollment-website.aspx](http://blogs.technet.com/b/xdot509/archive/2013/03/07/installing-a-two-tier-pki-hierarchy-in-windows-server-2012-part-vii-enabling-ssl-on-the-web-enrollment-website.aspx)>

### # [WIN8-TEST1] Create security group for Web servers

```PowerShell
New-ADGroup `
    -Name "Web Servers" `
    -GroupScope Global `
    -Path "OU=Groups,OU=IT,DC=corp,DC=technologytoolbox,DC=com"
```

### # [WIN8-TEST1] Adding issuing CA to security group for Web Servers

```PowerShell
Add-ADGroupMember "Web Servers" CIPHER01$
```

### # Duplicate the Web Server certificate template

A best practice is to duplicate certificate templates instead of using the out-of-the-box templates.  This allows you to retain the original templates, without modification.

Start the **Certification Authority** console (certsrv.msc).

![(screenshot)](https://assets.technologytoolbox.com/screenshots/00/7FE4B8CAA6245B8D17CDCB2161A2D998C7A81400.png)

Expand the CA, right-click **Certificate Templates**, and click **Manage**.

In the **Certificate Templates Console** window, in the list of certificate templates, right-click **Web Server** and then click **Duplicate Template**.

In Windows Server 2012 you will first be presented with the Compatibility tab.  The idea is that you select the OS Version of your Certification Authority and the OS Version of clients that will be enrolling for certificates based on this template.  This will then only allow you to select options in the Certificate Template that are supported by both the CA and the client/enrollee.  In my example, I am going to leave the defaults.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BD/1F9F5A27A6C716142B0A6ADC0DCB988B9FFDF2BD.png)

On the **General** tab, in the **Template display name** box, type **Technology Toolbox Web Server**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CD/F923336BA1295707A0A950457A96694B67115CCD.png)

Next, I have to give the CA the proper permissions for the template, so that it can enroll for a certificate.

On the **Security** tab, click **Add...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/13/A8DC697A0C40B9F1B7C2A961E932E302F445A313.png)

In the **Select Users, Computers, Service Accounts, or Groups** window, type **Web Servers**, click **Check Names**, and then click **OK**.

In the **Technology Toolbox Web Server Properties** window:

1. In the **Permissions for Web Servers** list, click the **Allow** checkbox for **Enroll**.
2. Click **OK**.

### Enable the certificate template on the issuing CA

So, now the CA has proper permission to the Certificate Template.  Next, I have to make the Certificate Template available on the CA.

Start the **Certification Authority** console (certsrv.msc).

![(screenshot)](https://assets.technologytoolbox.com/screenshots/00/7FE4B8CAA6245B8D17CDCB2161A2D998C7A81400.png)

Expand the CA, right-click **Certificate Templates**, select **New**, then **Certificate Template to Issue**.

In the **Enable Certificate Templates** window, select** Technology Toolbox Web Server**, and then click **OK**.

### Enroll for the Certificate

I could enroll for the Certificate through IIS.  However, I prefer to use the **Certificates** MMC as that gives me more control over the configuration of my request.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/41/6E27C890278FEE4140766E30B3F0E30E63F26841.png)

On the **File** menu, click **Add/Remove Snap-in...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8C/431720C5C9979258661708A53BDC8269D7AB9F8C.png)

In the **Available snap-ins** list, select **Certificates**, and then click **Add >**.

In the **Certificates snap-in** window, select to manage certificates for **Computer account**, and click **Next**.\
In the **Select Computer** window, ensure **Local computer** is selected and click **Finish**.

In the **Add or Remove Snap-ins** window, click **OK**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/73/AD565EFF2ADABE0C8FC3802C2CA9508239E56A73.png)

Expand **Certificates (Local Computer)**, right-click **Personal**, select **All Tasks**, and then click **Request New Certificate...**

The **Certificate Enrollment** wizard opens.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/19/4359CCCE1C716C836452CA9311EEE9A40F53F119.png)

On the **Before You Begin** step, click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C1/5D634D14B0BC22FCE577CCA0F45D5482C78F0FC1.png)

On the **Select Certificate Enrollment Policy** step, ensure **Active Directory Enrollment Policy** is selected, and click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D1/7C51F7F1ED83F32762FF1A3CFE2000789F06F2D1.png)

On the **Request Certificates** step, select the checkbox for **Technology Toolbox Web Server**, expand **Details**, and click **Properties**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3A/C669DB3F22681C2ECCC620DB8D74FFB7D075503A.png)

In the **Certificate Properties** window:

1. On the **Subject** tab:
   1. In the **Alternative Name **section:
      1. In the **Type** list, select **DNS**.
      2. In the **Value** box, type the short name for the issuing CA server.
      3. Click **Add >**.
      4. Repeat the previous steps to add the FQDN for the issuing CA server.
   2. Click **Apply**.
2. On the **General** tab:
   1. In the **Friendly name** box, type **SSL Cert - cipher01**.
   2. Click **OK**.
3. On the **Request Certificates** step, click **Enroll**.
4. On the **Certificate Installation Results** step, ensure the certificate enrollment succeeded and click **Finish**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C7/58C74CEAD59BF58AAF3367574BB4912D02ED3EC7.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D9/6C24B981CDEAF366B692FC7C255385BE0BA53DD9.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E5/83AE504A53E4A474CB4D236F7133018C67C3F3E5.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B3/DC1C7B402EE1D242A6201D1FB7948F26C37864B3.png)

### Configure SSL certificate in IIS

![(screenshot)](https://assets.technologytoolbox.com/screenshots/55/E90206A71CDAEB62B2320D0BACC2A337731F8555.png)

In Internet Information Services (IIS) Manager:\
Expand the server node.\
Expand **Sites**.\
Click **Default Web Site**.\
In the **Actions** pane, in the **Edit Site** section, click **Bindings...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/73/578D41E4E5C085D89DB329F5531369CDD114BB73.png)

In the **Site Bindings** window, **Add...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/52/864E8F12888F31247338AC431C80816D73DB9A52.png)

In the **Add Site Binding** window:

1. In the **Type** drop-down, select **https**.
2. In the **SSL certificate** drop-down, select **SSL Cert - CIPHER01**.
3. Click **OK**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/50/9EA42566CF2139EEB41FF8CA8F4704648A384150.png)

In the **Site Bindings** window, click **Close**.

Expand **Default Web Site** and click the **CertSrv** virtual directory.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AA/C96E9319FE9F44B75EFBF5310A43D338962FF4AA.png)

Double-click **SSL Settings**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/58/D5FA9B070C78C8839BB60011375DB23D18C42458.png)

In the **SSL Settings** view:

1. Select the **Require SSL** checkbox.
2. In the **Actions** pane, click **Apply**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7C/7E99A3A8719E6763F83DCF49BD328BBDCA531C7C.png)

### [WIN8-TEST1] Verify the Web Enrollment site is now configured with SSL

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3C/EEAB5120F16941CE0E671748BA43B99363FCF93C.png)

## # [STORM] Delete the checkpoint for issuing CA VM

```PowerShell
Remove-VMSnapshot CIPHER01
```

## Configure user and computer certificate autoenrollment

### References

**AD CS: User autoenrollment should be enabled when an enterprise CA is installed**\
Pasted from <[http://technet.microsoft.com/en-us/library/dd379539(v=ws.10).aspx](http://technet.microsoft.com/en-us/library/dd379539(v=ws.10).aspx)>

**AD CS: Computer autoenrollment should be enabled when an enterprise CA is installed**\
Pasted from <[http://technet.microsoft.com/en-us/library/dd379529.aspx](http://technet.microsoft.com/en-us/library/dd379529.aspx)>

**Test Lab Guide: Deploying an AD CS Two-Tier PKI Hierarchy**\
Pasted from <[http://technet.microsoft.com/en-us/library/hh831348.aspx](http://technet.microsoft.com/en-us/library/hh831348.aspx)>

To automatically enroll users and client computers for certificates in a domain environment, you must:

- Configure an autoenrollment policy for the domain.
- Configure certificate templates for autoenrollment.
- Configure an enterprise CA.

Membership in **Domain Admins** or **Enterprise Admins** is required to complete these procedures.

### [WIN8-TEST1] To configure autoenrollment Group Policy for a domain

1. In Server Manager, click **Tools**, and then click **Group Policy Management**.
2. In the console tree, expand the following objects: **Forest: corp.technologytoolbox.com**, **Domains**, **corp.technologytoolbox.com**.
3. Right-click the** Default Domain Policy** GPO, and then click **Edit**...
4. In the console tree of the **Group Policy Management Editor** window, under **User Configuration**, expand the following objects: **Policies**, **Windows Settings**, **Security Settings**, and then click **Public Key Policies**.
5. In the details pane, double-click **Certificate Services Client - Auto-Enrollment**.
6. In the **Certificate Services Client - Auto-Enrollment Properties** window:
   1. In the **Configuration Model** drop-down, select **Enabled**.
   2. Select the **Renew expired certificates, update pending certificates, and remove revoked certificates** checkbox.
   3. Select the **Update certificates that use certificate templates** checkbox.
   4. Select the **Display user notifications for expiring certificates in user and machine MY store **checkbox.
   5. Click **OK**.
7. In the console tree of the **Group Policy Management Editor** window, under **Computer Configuration**, expand the following objects: **Policies**, **Windows Settings**, **Security Settings**, and then click **Public Key Policies**.
8. In the details pane, double-click **Certificate Services Client - Auto-Enrollment**.
9. In the **Certificate Services Client - Auto-Enrollment Properties** window:
   1. In the **Configuration Model** drop-down, select **Enabled**.
   2. Select the **Renew expired certificates, update pending certificates, and remove revoked certificates** checkbox.
   3. Select the **Update certificates that use certificate templates** checkbox.
   4. Click **OK**.
10. Close Group Policy Management Editor and Group Policy Management Console.

### To configure user and client computer certificate templates for autoenrollment

1. Start the **Certification Authority** console (certsrv.msc).
2. In the console tree, expand the CA, right-click **Certificate Templates**, and click **Manage**.
3. In the **Certificate Templates Console** window:
   1. In the details pane, right-click **User** and then click **Duplicate Template**.
   2. In the **Properties of New Template** window:
      1. On the **General** tab, in **Template display name**, type **Technology Toolbox User**.
      2. On the **Security** tab, in the **Group or user names **section, click **Domain Users (TECHTOOLBOX\\Domain Users)**.
      3. In the **Permissions for Domain Users **section, in the **Autoenroll** row, select the **Allow** checkbox. This will cause all domain users to automatically enroll for certificates using this template.
      4. Click **OK**.
   3. In the details pane, right-click **Workstation Authentication** and then click **Duplicate Template**.
   4. In the **Properties of New Template** window:
      1. On the **General** tab, in **Template display name**, type **Technology Toolbox Workstation Authentication**.
      2. On the click the **Security** tab, in the **Group or user names **section, click **Domain Computers (TECHTOOLBOX\\Domain Computers)**.
      3. In the **Permissions for Domain Computers** section, in the **Autoenroll** row, select the **Allow** checkbox. This will cause all domain computers to automatically enroll for certificates using this template.
      4. Click **OK**.

> **Note**
>
> The users also need **Read** permission for the template in order to enroll. However, this permission is already granted to the **Authenticated Users** group. All users in the domain are members of **Authenticated Users**, so they already have the permission to **Read** the template.

> **Note**
>
> The computers also need **Read** permission for the template in order to enroll. However, this permission is already granted to the **Authenticated Users** group. All computer accounts in the domain are members of **Authenticated Users**, so they already have the permission to **Read** the template.

The certificate templates that you have enabled for autoenrollment must be assigned to the CA before users and client computers can automatically enroll for those certificates.

### To assign certificate templates to an enterprise CA

1. Start the **Certification Authority** console (certsrv.msc).
2. In the console tree, right-click **Certificate Templates**, point to **New**, and click **Certificate Template to Issue**.
3. In the **Enable Certificate Templates** window:
   1. Select the following certificates:
      1. **Technology Toolbox User**
      2. **Technology Toolbox Workstation Authentication**
   2. Click **OK**.

## Resolve SCOM alerts due to disk fragmentation

### Alert Name

Logical Disk Fragmentation Level is high

### Alert Description

The disk C: (C:) on computer CIPHER01.corp.technologytoolbox.com has high fragmentation level. File Percent Fragmentation value is 20%. Defragmentation recommended: true.

### Resolution

##### # Copy Toolbox content

```PowerShell
robocopy \\iceman\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E
```

##### # Create scheduled task to optimize drives

```PowerShell
[string] $xml = Get-Content `
  'C:\NotBackedUp\Public\Toolbox\Scheduled Tasks\Optimize Drives.xml'

Register-ScheduledTask -TaskName "Optimize Drives" -Xml $xml
```

## Configure code signing certificate template

### Duplicate the Code Signing certificate template

1. Start the **Certification Authority** console (certsrv.msc).
2. Expand the CA, right-click **Certificate Templates**, and click **Manage**.
3. In the **Certificate Templates Console** window, in the list of certificate templates, right-click **Code Signing** and then click **Duplicate Template**.
4. In the **Properties of New Template** window:
   1. On the **General** tab, in the **Template display name** box, type **Technology Toolbox Code Signing**.
   2. On the **Security** tab, click **Add...**
   3. In the **Select Users, Computers, Service Accounts, or Groups** window, type **All Developers**, click **Check Names**, and then click **OK**.
   4. On the **Security** tab of the template properties window, in the **Permissions for All Developers **list, click the **Allow** checkbox for **Enroll**.
   5. Click **OK**.
5. Close or minimize the **Certificate Templates Console** window.

### Enable the custom code signing certificate template on the issuing CA

#### To make the code signing certificate available on the CA

1. Start the **Certification Authority** console (certsrv.msc).
2. Expand the CA, right-click **Certificate Templates**, select **New**, then **Certificate Template to Issue**.
3. In the **Enable Certificate Templates** window, select** Technology Toolbox Code Signing**, and then click **OK**.

## Request code signing certificate

![(screenshot)](https://assets.technologytoolbox.com/screenshots/25/EAEB0AA7043E887232F3EE16314935472DDFBD25.png)

Click **Request a certificate**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7C/4005E083BB18F200FDFDAE6D33C4BE9D9634667C.png)

Click **Create and submit a request to this CA**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/14/DBA5EF4538B42D223DC70E83C09D2CEEC3C33214.png)

Click **Yes**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3D/289DDF7BE327F085403F9747B7D02E57A3ED123D.png)

In the **Certificate Template** dropdown, select **Technology Toolbox Code Signing**.

In the **Key Options** section, select the **Enable strong private key protection** checkbox.

Click **Submit >**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5F/A0F9E512808FE79FC27694D982840923C82DFC5F.png)

Click **Set Security Level...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F4/83DFBF124361EAACECA3865E1B769796A03CD3F4.png)

Select the **High** option and then click **Next >**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B8/9519E3D0C9C2EF25F0AFBFD8C90BDF50167B5EB8.png)

In the **Password** and **Confirm** boxes, type the password to secure the private key for the certificate and then click **Finish**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/79/33E8A286E35D4FF7E0BCC6146852B87B2E612279.png)

Click **OK**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B2/EAC403299086FE51F5F400419D69FD597919F0B2.png)

Click **Yes**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/65/39DE2165522BDBA5643D160E60ECCD92303AE865.png)

Click **Install this certificate**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D8/F85CB3D1E7492F03A7624E60440816F693FB44D8.png)

## Clean Up the WinSxS Folder

From <[https://technet.microsoft.com/en-us/library/dn251565.aspx](https://technet.microsoft.com/en-us/library/dn251565.aspx)>

**Before:**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/44/72B3999D6568E2587BD7119DB91433E0BF867944.png)

```INI
C:\Windows\system32>dism /Online /Cleanup-Image /AnalyzeComponentStore

Deployment Image Servicing and Management tool
Version: 6.3.9600.17031

Image Version: 6.3.9600.17031

[==========================100.0%==========================]

Component Store (WinSxS) information:

Windows Explorer Reported Size of Component Store : 6.94 GB

Actual Size of Component Store : 6.84 GB

    Shared with Windows : 3.82 GB
    Backups and Disabled Features : 2.66 GB
    Cache and Temporary Data : 366.85 MB

Date of Last Cleanup : 2015-03-19 04:01:38

Number of Reclaimable Packages : 11
Component Store Cleanup Recommended : Yes

The operation completed successfully.

C:\Windows\system32>dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase

Deployment Image Servicing and Management tool
Version: 6.3.9600.17031

Image Version: 6.3.9600.17031

[==========================100.0%==========================]
The operation completed successfully.
```

**After (a little better - but not much):**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9E/3027AFCFB03D768E11C88AE56E7DB86B3853659E.png)

```INI
C:\Windows\system32>dism /Online /Cleanup-Image /AnalyzeComponentStore

Deployment Image Servicing and Management tool
Version: 6.3.9600.17031

Image Version: 6.3.9600.17031

[==========================100.0%==========================]

Component Store (WinSxS) information:

Windows Explorer Reported Size of Component Store : 6.26 GB

Actual Size of Component Store : 6.17 GB

    Shared with Windows : 3.82 GB
    Backups and Disabled Features : 1.99 GB
    Cache and Temporary Data : 373.43 MB

Date of Last Cleanup : 2015-03-23 14:37:50

Number of Reclaimable Packages : 0
Component Store Cleanup Recommended : No

The operation completed successfully.

C:\Windows\system32>dism /Online /Cleanup-Image /SPSuperseded

Deployment Image Servicing and Management tool
Version: 6.3.9600.17031

Image Version: 6.3.9600.17031

Service Pack Cleanup cannot proceed: No Service Pack backup files were found.
The operation completed successfully.
```

## # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

## Configure certificate for https://pki.technologytoolbox.com

**Modify binding on Default Web Site to require Server Name Indication**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0E/79AAC9816660F91CED604BE98430152AA061FF0E.png)

Click **Edit...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A6/EA956C8F869E7DCFE6545BB256F16074556672A6.png)

In the **Edit Site Binding** window:

1. In the **Host name** box, type **cipher01.corp.technologytoolbox.com**.
2. Select **Require Server Name Indication**.
3. Click **OK**.

### Configure redirect from http://cipher01 to https://cipher01.corp.technologytoolbox.com/certsrv

In IIS Manager, select **Default Web Site**.\
In the **Features View**, in the **IIS** section, double-click **HTTP Redirect**.\
On the **HTTP Redirect** page:

1. Select **Redirect requests to this destination** and type **[https://cipher01.corp.technologytoolbox.com/certsrv](https://cipher01.corp.technologytoolbox.com/certsrv)** in the corresponding box.
2. In the **Redirect Behavior** section, select **Only redirect requests to content in this directory (not subdirectories)**.
3. In the **Actions** pane, click **Apply**.

### Verify http://cipher01 automatically redirects to https://cipher01.corp.technologytoolbox.com/certsrv

![(screenshot)](https://assets.technologytoolbox.com/screenshots/62/E528CDD0C1C3A327336DEE614172D9163DFD3062.png)

### Enroll certificate for https://pki.technologytoolbox.com

1. Open MMC.
2. Add **Certificates** snap-in for **Computer account** (**Local computer**).
3. Expand **Certificates (Local Computer)**, right-click **Personal**, select **All Tasks**, and then click **Request New Certificate...**

The **Certificate Enrollment** wizard opens.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/19/4359CCCE1C716C836452CA9311EEE9A40F53F119.png)

On the **Before You Begin** step, click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C1/5D634D14B0BC22FCE577CCA0F45D5482C78F0FC1.png)

On the **Select Certificate Enrollment Policy** step, ensure **Active Directory Enrollment Policy** is selected, and click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D1/7C51F7F1ED83F32762FF1A3CFE2000789F06F2D1.png)

On the **Request Certificates** step, select the checkbox for **Technology Toolbox Web Server**, expand **Details**, and click **Properties**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3A/C669DB3F22681C2ECCC620DB8D74FFB7D075503A.png)

In the **Certificate Properties** window:

1. On the **Subject** tab:
   1. In the **Alternative Name **section:
      1. In the **Type** list, select **DNS**.
      2. In the **Value** box, type **pki.technologytoolbox.com**.
   2. Click **Apply**.
2. On the **General** tab:
   1. In the **Friendly name** box, type **pki.technologytoolbox.com**.
   2. Click **OK**.
3. On the **Request Certificates** step, click **Enroll**.
4. On the **Certificate Installation Results** step, ensure the certificate enrollment succeeded and click **Finish**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/71/BB57659E31164B4A154F9089D50CB7DCC1802A71.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/21/CE4BEE4BB7C73937952426A819072E1F8EA60521.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E5/83AE504A53E4A474CB4D236F7133018C67C3F3E5.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B3/DC1C7B402EE1D242A6201D1FB7948F26C37864B3.png)

### Configure SSL certificate in IIS

![(screenshot)](https://assets.technologytoolbox.com/screenshots/55/E90206A71CDAEB62B2320D0BACC2A337731F8555.png)

In Internet Information Services (IIS) Manager:\
Expand the server node.\
Expand **Sites**.\
Click **pki.technologytoolbox.com**.\
In the **Actions** pane, in the **Edit Site** section, click **Bindings...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/73/578D41E4E5C085D89DB329F5531369CDD114BB73.png)

In the **Site Bindings** window, **Add...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/52/864E8F12888F31247338AC431C80816D73DB9A52.png)

In the **Add Site Binding** window:

1. In the **Type** drop-down, select **https**.
2. In the **Host name** box, type **pki.technologytoolbox.com**.
3. Select **Require Server Name Indication**.
4. In the **SSL certificate** drop-down, select **pki.technologytoolbox.com**.
5. Click **OK**.

In the **Site Bindings** window, click **Close**.

### Verify the PKI site supports both HTTP and HTTPS

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CC/5351EB2C6B82149463B1CD39B1E20C9C45B929CC.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/90/F4A5ED6163638B3A56B837E1D9BAA681E47A3E90.png)

## Configure Web Server certificate template with exportable private key

### Create certificate template

1. Start the **Certification Authority** console (certsrv.msc).
2. Expand the CA, right-click **Certificate Templates**, and click **Manage**.
3. In the **Certificate Templates Console** window, in the list of certificate templates, right-click **Web Server** and then click **Duplicate Template**.
4. On the **General** tab, in the **Template display name** box, type **Technology Toolbox Web Server - Exportable**.
5. On the **Request Handling **tab, select **Allow private key to be exported**.
6. On the **Security** tab:
   1. Click **Add...**
   2. In the **Select Users, Computers, Service Accounts, or Groups** window, type **Web Servers**, click **Check Names**, and then click **OK**.
   3. In the **Permissions for Web Servers** list, click the **Allow** checkbox for **Enroll**.
7. Click **OK**.

### Enable the certificate template on the issuing CA

1. Start the **Certification Authority** console (certsrv.msc).
2. Expand the CA, right-click **Certificate Templates**, select **New**, then **Certificate Template to Issue**.
3. In the **Enable Certificate Templates** window, select** Technology Toolbox Web Server - Exportable**, and then click **OK**.

## # Configure firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

---

**FOOBAR8**

```PowerShell
$computer = 'CIPHER01'

$command = "New-NetFirewallRule ``
    -Name 'Remote Windows Update (Dynamic RPC)' ``
    -DisplayName 'Remote Windows Update (Dynamic RPC)' ``
    -Description 'Allows remote auditing and installation of Windows updates via POSHPAIG (http://poshpaig.codeplex.com/)' ``
    -Group 'Technology Toolbox (Custom)' ``
    -Program '%windir%\system32\dllhost.exe' ``
    -Direction Inbound ``
    -Protocol TCP ``
    -LocalPort RPC ``
    -Profile Domain ``
    -Action Allow"

$scriptBlock = [ScriptBlock]::Create($command)

Invoke-Command -ComputerName $computer -ScriptBlock $scriptBlock
```

---

## Configure Operations Manager certificate template

### Reference

**How to Obtain a Certificate Using Windows Server 2008 Enterprise CA**\
From <[https://technet.microsoft.com/en-US/library/hh467900.aspx](https://technet.microsoft.com/en-US/library/hh467900.aspx)>

**Create a certificate template**\
From <[https://technet.microsoft.com/en-US/library/hh467900.aspx#BKMK_CreateTemplate](https://technet.microsoft.com/en-US/library/hh467900.aspx#BKMK_CreateTemplate)>

### Create certificate template

1. Start the **Certification Authority** console (certsrv.msc).
2. Expand the CA, right-click **Certificate Templates**, and click **Manage**.
3. In the **Certificate Templates Console** window, in the list of certificate templates, right-click **IPsec (Offline request)** and then click **Duplicate Template**.
4. In the **Properties of New Template** window:
   1. On the **Compatibility **tab, in the **Compatibility Settings **section, click the **Certification Authority** dropdown and select **Windows Server 2008**.
   2. On the **General** tab, in the **Template display name** box, type **Technology Toolbox Operations Manager**.
   3. On the **Request Handling **tab, select **Allow private key to be exported**.
   4. On the **Extensions **tab:
      1. In the **Extensions included in this template** list, select **Application Policies**.
      2. Click **Edit...**
      3. In the **Edit Application Policies Extension** window:
         1. In the **Application policies** list, select **IP security IKE intermediate**.
         2. Click **Remove**.
         3. Click **Add...**
         4. In the **Add Application Policy** window, select **Client Authentication** and **Server Authentication** and then click **OK**.
      4. Click **OK**.
   5. **TODO:** On the **Security** tab:
      1. Click **Add...**
      2. In the **Select Users, Computers, Service Accounts, or Groups** window, type **Web Servers**, click **Check Names**, and then click **OK**.
      3. In the **Permissions for Web Servers** list, click the **Allow** checkbox for **Enroll**.
   6. Click **OK**.

### Enable the certificate template on the issuing CA

1. Start the **Certification Authority** console (certsrv.msc).
2. Expand the CA, right-click **Certificate Templates**, select **New**, then **Certificate Template to Issue**.
3. In the **Enable Certificate Templates** window, select** Technology Toolbox Operations Manager**, and then click **OK**.

## Resolve issue with Active Directory Certificate Services

### Alert

Source: Microsoft-Windows-CertificationAuthority\
Event ID: 100\
Event Category: 0\
User: NT AUTHORITY\\SYSTEM\
Computer: CIPHER01.corp.technologytoolbox.com\
Event Description: Active Directory Certificate Services did not start: Could not load or verify the current CA certificate. Technology Toolbox Issuing Certificate Authority 01 The revocation function was unable to check revocation because the revocation server was offline. 0x80092013 (-2146885613 CRYPT_E_REVOCATION_OFFLINE).

### Solution

#### Update CRL on root CA

---

**ICEMAN**

##### # Start root CA (CRYPTID)

```PowerShell
Start-VM CRYPTID
```

---

---

**CRYPTID**

##### # Republish the CRL

```PowerShell
certutil -CRL
```

---

#### Copy the CRL to removable media

---

**ICEMAN**

##### # Create virtual floppy disk on Hyper-V host

```PowerShell
$vmName = "CRYPTID"

mkdir "C:\NotBackedUp\VMs\$vmName\Virtual Floppy Disks"

$vfdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Floppy Disks\$vmName.vfd"

New-VFD -Path $vfdPath

Set-VMFloppyDiskDrive -VMName $vmName -Path $vfdPath
```

---

---

**CRYPTID**

##### # Format virtual floppy disk

```PowerShell
format A:
```

> **Note**
>
> When prompted for the volume label, press Enter.
>
> When prompted to format another disk, type **N** and then press Enter.

##### # Copy the CRL to floppy disk

```PowerShell
copy C:\Windows\system32\CertSrv\CertEnroll\*.crl A:\
```

##### # Verify the CRL was copied to the floppy disk

```PowerShell
dir A:\
```

---

#### Distribute the CRL for the root CA

---

**ICEMAN**

##### # Remove virtual floppy disk from root CA

```PowerShell
$vmName = "CRYPTID"

Set-VMFloppyDiskDrive -VMName $vmName -Path $null
```

##### # Shutdown root CA (CRYPTID)

```PowerShell
Stop-VM $vmName
```

---

---

**BEAST**

##### # Configure virtual floppy disk containing CRL from root CA

```PowerShell
$vmName = "CIPHER01"

$vfdPath = "F:\NotBackedUp\VMs\$vmName\Virtual Floppy Disks"

mkdir $vfdPath

move `
    "\\ICEMAN\C$\NotBackedUp\VMs\CRYPTID\Virtual Floppy Disks\CRYPTID.vfd" `
    $vfdPath

Set-VMFloppyDiskDrive -VMName $vmName -Path ($vfdPath + "\CRYPTID.vfd")
```

---

##### # Publish CRL for root CA to Active Directory

```PowerShell
A:

certutil -addstore -f `
    root "Technology Toolbox Root Certificate Authority.crl"
```

##### # Copy CRL for root CA to PKI website

```PowerShell
Copy-Item `
    "A:\Technology Toolbox Root Certificate Authority.crl" `
    "\\CIPHER01\PKI$\crl"
```

```PowerShell
cls
```

#### # Restart the server and ensure Active Directory Certificate Services starts successfully

```PowerShell
Restart-Computer
```

---

**BEAST**

```PowerShell
cls
```

##### # Delete virtual floppy disk containing CRL from root CA

```PowerShell
$vmName = "CIPHER01"

Set-VMFloppyDiskDrive -VMName $vmName -Path $null

$vfdPath = "F:\NotBackedUp\VMs\$vmName\Virtual Floppy Disks\CRYPTID.vfd"

del $vfdPath
```

---

## Avoid warning from Active Directory Certificate Services with TFS service account

### Warning

Log Name:      Application\
Source:        Microsoft-Windows-CertificationAuthority\
Date:          3/10/2016 1:12:53 AM\
Event ID:      53\
Task Category: None\
Level:         Warning\
Keywords:\
User:          SYSTEM\
Computer:      CIPHER01.corp.technologytoolbox.com\
Description:\
Active Directory Certificate Services denied request 1295 because The EMail name is unavailable and cannot be added to the Subject or Subject Alternate name. 0x80094812 (-2146875374 CERTSRV_E_SUBJECT_EMAIL_REQUIRED).  The request was for TECHTOOLBOX\\svc-tfs.  Additional information: Denied by Policy Module

### Solution

Create mailbox on BANSHEE (svc-tfs@technologytoolbox.com)

## Resolve issue with Active Directory Certificate Services

### Alert

Source: Microsoft-Windows-CertificationAuthority\
Event ID: 22\
Event Category: 0\
User: NT AUTHORITY\\SYSTEM\
Computer: CIPHER01.corp.technologytoolbox.com\
Event Description: Active Directory Certificate Services could not process request 1370 due to an error: The revocation function was unable to check revocation because the revocation server was offline. 0x80092013 (-2146885613 CRYPT_E_REVOCATION_OFFLINE). The request was for TECHTOOLBOX\\FOOBAR8\$. Additional information: Error Verifying Request Signature or Signing Certificate

### Solution

#### Update CRL on root CA

---

**FORGE**

##### # Start root CA (CRYPTID)

```PowerShell
Start-VM CRYPTID
```

---

---

**CRYPTID**

##### # Republish the CRL

```PowerShell
certutil -CRL
```

---

#### Copy the CRL to removable media

---

**FORGE**

##### # Create virtual floppy disk on Hyper-V host

```PowerShell
$vmName = "CRYPTID"

mkdir "E:\NotBackedUp\VMs\$vmName\Virtual Floppy Disks"

$vfdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Floppy Disks\$vmName.vfd"

New-VFD -Path $vfdPath

Set-VMFloppyDiskDrive -VMName $vmName -Path $vfdPath
```

---

---

**CRYPTID**

##### # Format virtual floppy disk

```PowerShell
format A:
```

> **Note**
>
> When prompted for the volume label, press Enter.
>
> When prompted to format another disk, type **N** and then press Enter.

##### # Copy the CRL to floppy disk

```PowerShell
copy C:\Windows\system32\CertSrv\CertEnroll\*.crl A:\
```

##### # Verify the CRL was copied to the floppy disk

```PowerShell
dir A:\
```

---

#### Distribute the CRL for the root CA

---

**FORGE**

##### # Remove virtual floppy disk from root CA

```PowerShell
$vmName = "CRYPTID"

Set-VMFloppyDiskDrive -VMName $vmName -Path $null
```

##### # Shutdown root CA (CRYPTID)

```PowerShell
Stop-VM $vmName
```

---

---

**BEAST**

##### # Configure virtual floppy disk containing CRL from root CA

```PowerShell
$vmName = "CIPHER01"

$vfdPath = "F:\NotBackedUp\VMs\$vmName\Virtual Floppy Disks"

mkdir $vfdPath

move `
    "\\FORGE\E$\NotBackedUp\VMs\CRYPTID\Virtual Floppy Disks\CRYPTID.vfd" `
    $vfdPath

Set-VMFloppyDiskDrive -VMName $vmName -Path ($vfdPath + "\CRYPTID.vfd")
```

---

##### # Publish CRL for root CA to Active Directory

```PowerShell
A:

certutil -addstore -f `
    root "Technology Toolbox Root Certificate Authority.crl"
```

##### # Copy CRL for root CA to PKI website

```PowerShell
Copy-Item `
    "A:\Technology Toolbox Root Certificate Authority.crl" `
    "\\CIPHER01\PKI$\crl"
```

```PowerShell
cls
```

#### # Restart the server and ensure Active Directory Certificate Services starts successfully

```PowerShell
Restart-Computer
```

---

**BEAST**

```PowerShell
cls
```

##### # Delete virtual floppy disk containing CRL from root CA

```PowerShell
$vmName = "CIPHER01"

Set-VMFloppyDiskDrive -VMName $vmName -Path $null

$vfdPath = "F:\NotBackedUp\VMs\$vmName\Virtual Floppy Disks\CRYPTID.vfd"

del $vfdPath
```

---

## # Rename network connection

```PowerShell
Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "Production"
```

## Resolve issue with Active Directory Certificate Services

### Alert

Alert: Application Event Log Error\
Source: CIPHER01.corp.technologytoolbox.com\
Path: Not Present\
Last modified by: System\
Last modified time: 3/16/2017 8:24:51 PM Alert description: Source: Microsoft-Windows-CertificationAuthority\
Event ID: 22\
Event Category: 0\
User: NT AUTHORITY\\SYSTEM\
Computer: CIPHER01.corp.technologytoolbox.com\
Event Description: Active Directory Certificate Services could not process request 2207 due to an error: The revocation function was unable to check revocation because the revocation server was offline. 0x80092013 (-2146885613 CRYPT_E_REVOCATION_OFFLINE).  The request was for TECHTOOLBOX\\FOOBAR10\$.  Additional information: Error Verifying Request Signature or Signing Certificate

### Solution

#### Update CRL on root CA

---

**TT-HV02B**

##### # Start root CA (CRYPTID)

```PowerShell
Start-VM CRYPTID
```

---

---

**CRYPTID**

##### # Republish the CRL

```PowerShell
certutil -CRL
```

---

#### Copy the CRL to removable media

---

**TT-HV02B**

##### # Create virtual floppy disk on Hyper-V host

```PowerShell
$vmName = "CRYPTID"
$vmPath = "\\TT-SOFS01.corp.technologytoolbox.com\VM-Storage-Silver\$vmName"

mkdir "$vmPath\Virtual Floppy Disks"

$vfdPath = "$vmPath\Virtual Floppy Disks\$vmName.vfd"

New-VFD -Path $vfdPath

Set-VMFloppyDiskDrive -VMName $vmName -Path $vfdPath
```

---

---

**CRYPTID**

##### # Format virtual floppy disk

```PowerShell
format A:
```

> **Note**
>
> When prompted for the volume label, press Enter.
>
> When prompted to format another disk, type **N** and then press Enter.

##### # Copy the CRL to floppy disk

```PowerShell
copy C:\Windows\system32\CertSrv\CertEnroll\*.crl A:\
```

##### # Verify the CRL was copied to the floppy disk

```PowerShell
dir A:\
```

---

#### Distribute the CRL for the root CA

---

**TT-HV02B**

```PowerShell
cls
```

##### # Remove virtual floppy disk from root CA

```PowerShell
$vmName = "CRYPTID"

Set-VMFloppyDiskDrive -VMName $vmName -Path $null
```

##### # Shutdown root CA (CRYPTID)

```PowerShell
Stop-VM $vmName
```

##### # Configure virtual floppy disk containing CRL from root CA

```PowerShell
$vmName = "CIPHER01"

$vfdPath = "\\TT-SOFS01.corp.technologytoolbox.com\VM-Storage-Silver\CRYPTID" `
    + "\Virtual Floppy Disks\CRYPTID.vfd"

Set-VMFloppyDiskDrive -VMName $vmName -Path $vfdPath
```

---

##### # Publish CRL for root CA to Active Directory

```PowerShell
A:

certutil -addstore -f `
    root "Technology Toolbox Root Certificate Authority.crl"
```

##### # Copy CRL for root CA to PKI website

```PowerShell
Copy-Item `
    "A:\Technology Toolbox Root Certificate Authority.crl" `
    "\\CIPHER01\PKI$\crl"
```

```PowerShell
cls
```

#### # Restart the server and ensure Active Directory Certificate Services starts successfully

```PowerShell
Restart-Computer
```

---

**TT-HV02B**

```PowerShell
cls
```

##### # Delete virtual floppy disk containing CRL from root CA

```PowerShell
$vmName = "CIPHER01"

Set-VMFloppyDiskDrive -VMName $vmName -Path $null

$vfdPath = "\\TT-SOFS01.corp.technologytoolbox.com\VM-Storage-Silver\CRYPTID" `
    + "\Virtual Floppy Disks\CRYPTID.vfd"

del $vfdPath
```

---

## Upgrade to System Center Operations Manager 2016

### Uninstall SCOM 2012 R2 agent

```Console
msiexec /x `{786970C5-E6F6-4A41-B238-AE25D4B91EEA`}

Restart-Computer
```

### Install SCOM 2016 agent (using Operations Console)

## Issue - Incorrect IPv6 DNS server assigned by Comcast router

```Text
PS C:\Users\jjameson-admin> nslookup
Default Server:  cdns01.comcast.net
Address:  2001:558:feed::1
```

> **Note**
>
> Even after reconfiguring the **Primary DNS** and **Secondary DNS** settings on the Comcast router -- and subsequently restarting the VM -- the incorrect DNS server is assigned to the network adapter.

### Solution

```PowerShell
Set-DnsClientServerAddress `
    -InterfaceAlias Management `
    -ServerAddresses 2603:300b:802:8900::103, 2603:300b:802:8900::104

Restart-Computer
```

---

**FOOBAR11**

```PowerShell
cls
```

## # Make virtual machine highly available

### # Migrate VM to shared storage

```PowerShell
$vmName = "CIPHER01"

$vm = Get-SCVirtualMachine -Name $vmName
$vmHost = $vm.VMHost

Move-SCVirtualMachine `
    -VM $vm `
    -VMHost $vmHost `
    -HighlyAvailable $true `
    -Path "\\TT-SOFS01.corp.technologytoolbox.com\VM-Storage-Silver" `
    -UseDiffDiskOptimization
```

### # Allow migration to host with different processor version

```PowerShell
Stop-SCVirtualMachine -VM $vmName

Set-SCVirtualMachine -VM $vmName -CPULimitForMigration $true

Start-SCVirtualMachine -VM $vmName
```

---

## Resolve issue with Active Directory Certificate Services

### Alert

Log Name:      Application\
Source:        Microsoft-Windows-CertificationAuthority\
Date:          6/9/2018 9:25:45 PM\
Event ID:      22\
Task Category: None\
Level:         Error\
Keywords:\
User:          SYSTEM\
Computer:      CIPHER01.corp.technologytoolbox.com\
Description:\
Active Directory Certificate Services could not process request 2790 due to an error: The revocation function was unable to check revocation because the revocation server was offline. 0x80092013 (-2146885613 CRYPT_E_REVOCATION_OFFLINE).  The request was for TECHTOOLBOX\\TT-DPM02\$.  Additional information: Error Verifying Request Signature or Signing Certificate

### Solution

#### Update CRL on root CA

---

**TT-HV02A**

##### # Start root CA (CRYPTID)

```PowerShell
Start-VM CRYPTID
```

---

---

**CRYPTID**

##### # Republish the CRL

```PowerShell
certutil -CRL
```

---

#### Copy the CRL to removable media

---

**TT-HV02A**

##### # Create virtual floppy disk on Hyper-V host

```PowerShell
$vmName = "CRYPTID"
$vmPath = "F:\NotBackedUp\VMs\$vmName"

mkdir "$vmPath\Virtual Floppy Disks"

$vfdPath = "$vmPath\Virtual Floppy Disks\$vmName.vfd"

New-VFD -Path $vfdPath

Set-VMFloppyDiskDrive -VMName $vmName -Path $vfdPath
```

---

---

**CRYPTID**

##### # Format virtual floppy disk

```PowerShell
format A:
```

> **Note**
>
> When prompted for the volume label, press Enter.
>
> When prompted to format another disk, type **N** and then press Enter.

##### # Copy the CRL to floppy disk

```PowerShell
copy C:\Windows\system32\CertSrv\CertEnroll\*.crl A:\
```

##### # Verify the CRL was copied to the floppy disk

```PowerShell
dir A:\
```

---

#### Distribute the CRL for the root CA

---

**TT-HV02A**

```PowerShell
cls
```

##### # Remove virtual floppy disk from root CA

```PowerShell
$vmName = "CRYPTID"

Set-VMFloppyDiskDrive -VMName $vmName -Path $null
```

##### # Shutdown root CA (CRYPTID)

```PowerShell
Stop-VM $vmName
```

##### # Copy virtual floppy disk to intermediate CA

```PowerShell
$vmName = "CIPHER01"

copy $vfdPath "C:\ClusterStorage\iscsi02-Silver-02\$vmName"
```

---

---

**TT-HV02B**

```PowerShell
cls
```

##### # Configure virtual floppy disk containing CRL from root CA

```PowerShell
$vmName = "CIPHER01"

$vfdPath = "C:\ClusterStorage\iscsi02-Silver-02\$vmName" `
    + "\CRYPTID.vfd"

Set-VMFloppyDiskDrive -VMName $vmName -Path $vfdPath
```

---

##### # Publish CRL for root CA to Active Directory

```PowerShell
A:

certutil -addstore -f `
    root "Technology Toolbox Root Certificate Authority.crl"
```

##### # Copy CRL for root CA to PKI website

```PowerShell
Copy-Item `
    "A:\Technology Toolbox Root Certificate Authority.crl" `
    "\\CIPHER01\PKI$\crl"
```

```PowerShell
cls
```

#### # Restart the server and ensure Active Directory Certificate Services starts successfully

```PowerShell
Restart-Computer
```

---

**TT-HV02B**

```PowerShell
cls
```

##### # Delete virtual floppy disk containing CRL from root CA

```PowerShell
$vmName = "CIPHER01"

Set-VMFloppyDiskDrive -VMName $vmName -Path $null

$vfdPath = "C:\ClusterStorage\iscsi02-Silver-02\$vmName" `
    + "\CRYPTID.vfd"

del $vfdPath
```

---

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Move VM to new Production VM network

```PowerShell
$vmName = "CIPHER01"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Production VM Network"
$ipAddressPool = Get-SCStaticIPAddressPool -Name "Production-15 Address Pool"

Stop-SCVirtualMachine $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -IPv4AddressPools $ipAddressPool `
    -IPv4AddressType Static

Start-SCVirtualMachine $vmName
```

---

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Move VM to new Management VM network

```PowerShell
$vmName = "CIPHER01"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Management VM Network"
$ipAddressPool = Get-SCStaticIPAddressPool -Name "Management-30 Address Pool"

Stop-SCVirtualMachine $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -IPv4AddressPools $ipAddressPool `
    -IPv4AddressType Static

Start-SCVirtualMachine $vmName
```

---

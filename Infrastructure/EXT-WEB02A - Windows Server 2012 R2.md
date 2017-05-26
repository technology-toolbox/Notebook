# EXT-WEB02A - Windows Server 2012 R2 Standard

Tuesday, October 4, 2016
5:13 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

Install SecuritasConnect v4.0

## Deploy and configure the server infrastructure

### Install Windows Server 2012 R2

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "FORGE"
$vmName = "EXT-WEB02A"
$vmPath = "E:\NotBackedUp\VMs"

$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 45GB `
    -MemoryStartupBytes 12GB `
    -SwitchName "Production"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 4

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
  - In the **Computer name** box, type **EXT-WEB02A**.
  - Select **Join a workgroup**.
  - In the **Workgroup **box, type **WORKGROUP**.
  - Click **Next**.
- On the **Applications** step, ensure no items are selected and click **Next**.

#### # Copy latest Toolbox content

```PowerShell
net use \\iceman.corp.technologytoolbox.com\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```Console
robocopy \\iceman.corp.technologytoolbox.com\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E /MIR
```

### # Rename local Administrator account and set password

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

$password = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted, type the password for the local Administrator account.

```PowerShell
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

$adminUser = [ADSI] 'WinNT://./Administrator,User'
$adminUser.Rename('foo')
$adminUser.SetPassword($plainPassword)

logoff
```

### Login as EXT-WEB02A\\foo

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
    -ServerAddresses 192.168.10.209,192.168.10.210
```

##### # Configure IPv6 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 2601:282:4201:e500::209,2601:282:4201:e500::210
```

##### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping ICEMAN -f -l 8900
```

```PowerShell
cls
```

### # Join member server to domain

```PowerShell
Add-Computer `
    -DomainName extranet.technologytoolbox.com `
    -Credential (Get-Credential EXTRANET\jjameson-admin) `
    -Restart
```

#### Move computer to "SharePoint Servers" OU

---

**EXT-DC01**

```PowerShell
$computerName = "EXT-WEB02A"
$targetPath = ("OU=SharePoint Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=extranet,DC=technologytoolbox,DC=com")

Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath

Restart-Computer $computerName
```

---

### Login as EXTRANET\\setup-sharepoint

### # Set MaxPatchCacheSize to 0 (Recommended)

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

### # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
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

### # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

### # Configure firewall rules for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Enable-RemoteWindowsUpdate.ps1 -Verbose
```

### # Disable firewall rules for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Disable-RemoteWindowsUpdate.ps1 -Verbose
```

```PowerShell
cls
```

### # Install and configure System Center Operations Manager

#### # Create certificate for Operations Manager

##### # Create request for Operations Manager certificate

```PowerShell
& "C:\NotBackedUp\Public\Toolbox\Operations Manager\Scripts\New-OperationsManagerCertificateRequest.ps1"
```

##### # Submit certificate request to Certification Authority

###### # Add Active Directory Certificate Services site to the "Trusted sites" zone and browse to the site

```PowerShell
$adcsUrl = [Uri] "https://cipher01.corp.technologytoolbox.com"

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-InternetSecurityZoneMapping.ps1 `
    -Zone LocalIntranet `
    -Patterns $adcsUrl.AbsoluteUri

Start-Process $adcsUrl.AbsoluteUri
```

> **Note**
>
> Copy the certificate request to the clipboard.

**To submit the certificate request to an enterprise CA:**

1. On the computer hosting the Operations Manager feature for which you are requesting a certificate, start Internet Explorer, and browse to Active Directory Certificate Services site ([https://cipher01.corp.technologytoolbox.com/](https://cipher01.corp.technologytoolbox.com/)).
2. On the **Welcome** page, click **Request a certificate**.
3. On the **Advanced Certificate Request** page, click **Submit a certificate request by using a base-64-encoded CMC or PKCS #10 file, or submit a renewal request by using a base-64-encoded PKCS #7 file.**
4. On the **Submit a Certificate Request or Renewal Request** page, in the **Saved Request** text box, paste the contents of the certificate request generated in the previous procedure.
5. In the **Certificate Template** section, select the Operations Manager certificate template (**Technology Toolbox Operations Manager**), and then click **Submit**. When prompted to allow the digital certificate operation to be performed, click **Yes**.
6. On the **Certificate Issued** page, click **Download certificate** and save the certificate.

```PowerShell
cls
```

##### # Import the certificate into the certificate store

```PowerShell
$certFile = "C:\Users\setup-sharepoint\Downloads\certnew.cer"

CertReq.exe -Accept $certFile

Remove-Item $certFile
```

#### # Install SCOM agent

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

##### # Mount the Operations Manager installation media

```PowerShell
$imagePath = `
    '\\ICEMAN\Products\Microsoft\System Center 2012 R2' `
    + '\en_system_center_2012_r2_operations_manager_x86_and_x64_dvd_2920299.iso'

Set-VMDvdDrive -ComputerName FORGE -VMName EXT-WEB02A -Path $imagePath
```

---

```PowerShell
$msiPath = 'X:\agent\AMD64\MOMAgent.msi'

msiexec.exe /i $msiPath `
    MANAGEMENT_GROUP=HQ `
    MANAGEMENT_SERVER_DNS=jubilee.corp.technologytoolbox.com `
    ACTIONS_USE_COMPUTER_ACCOUNT=1
```

```PowerShell
cls
```

#### # Import the certificate into Operations Manager using MOMCertImport

```PowerShell
$hostName = ([System.Net.Dns]::GetHostByName(($env:computerName))).HostName

$certImportToolPath = 'X:\SupportTools\AMD64'

Push-Location "$certImportToolPath"

.\MOMCertImport.exe /SubjectName $hostName

Pop-Location
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Remove the Operations Manager installation media

```PowerShell
Set-VMDvdDrive -ComputerName FORGE -VMName EXT-WEB02A -Path $null
```

---

#### # Approve manual agent install in Operations Manager

### # Enter a product key and activate Windows

```PowerShell
slmgr /ipk {product key}
```

> **Note**
>
> When notified that the product key was set successfully, click **OK**.

```Console
slmgr /ato
```

## Configure VM storage

| Disk | Drive Letter | Volume Size | VHD Type | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------- | -------------------- | ------------ |
| 0    | C:           | 45 GB       | Dynamic  | 4K                   | OSDisk       |
| 1    | D:           | 40 GB       | Dynamic  | 4K                   | Data01       |
| 2    | L:           | 20 GB       | Dynamic  | 4K                   | Log01        |

---

**FOOBAR8**

```PowerShell
cls
```

### # Create Data01 and Log01 VHDs

```PowerShell
$vmHost = "FORGE"
$vmName = "EXT-WEB02A"
$vmPath = "E:\NotBackedUp\VMs\$vmName"

$vhdPath = "$vmPath\Virtual Hard Disks\$vmName" `
    + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 40GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ControllerType SCSI `
    -Path $vhdPath

$vhdPath = "$vmPath\Virtual Hard Disks\$vmName" `
    + "_Log01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 20GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ControllerType SCSI `
    -Path $vhdPath
```

---

```PowerShell
cls
```

### # Initialize disks and format volumes

#### # Format Data01 drive

```PowerShell
Get-Disk 1 |
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -DriveLetter D -UseMaximumSize |
    Format-Volume `
        -FileSystem NTFS `
        -NewFileSystemLabel "Data01" `
        -Confirm:$false
```

#### # Format Log01 drive

```PowerShell
Get-Disk 2 |
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -DriveLetter L -UseMaximumSize |
    Format-Volume `
        -FileSystem NTFS `
        -NewFileSystemLabel "Log01" `
        -Confirm:$false
```

### Install latest service pack and updates

## Install and configure SharePoint Server 2013

### Install SharePoint 2013 prerequisites on farm servers

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Mount SharePoint Server 2013 installation media

```PowerShell
$vmHost = "FORGE"
$vmName = "EXT-WEB02A"
$imagePath = "\\ICEMAN\Products\Microsoft\SharePoint 2013\" `
    + "en_sharepoint_server_2013_with_sp1_x64_dvd_3823428.iso"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $imagePath
```

---

```Console
net use \\ICEMAN\Products /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$sourcePath = "\\ICEMAN\Products\Microsoft\SharePoint 2013" `
    + "\PrerequisiteInstallerFiles_SP1"

$prereqPath = "C:\NotBackedUp\Temp\PrerequisiteInstallerFiles_SP1"

robocopy $sourcePath $prereqPath /E

& X:\PrerequisiteInstaller.exe `
    /SQLNCli:"$prereqPath\sqlncli.msi" `
    /PowerShell:"$prereqPath\Windows6.1-KB2506143-x64.msu" `
    /NETFX:"$prereqPath\dotNetFx45_Full_setup.exe" `
    /IDFX:"$prereqPath\Windows6.1-KB974405-x64.msu" `
    /Sync:"$prereqPath\Synchronization.msi" `
    /AppFabric:"$prereqPath\WindowsServerAppFabricSetup_x64.exe" `
    /IDFX11:"$prereqPath\MicrosoftIdentityExtensions-64.msi" `
    /MSIPCClient:"$prereqPath\setup_msipc_x64.msi" `
    /WCFDataServices:"$prereqPath\WcfDataServices.exe" `
    /KB2671763:"$prereqPath\AppFabric1.1-RTM-KB2671763-x64-ENU.exe" `
    /WCFDataServices56:"$prereqPath\WcfDataServices-5.6.exe"
```

> **Important**
>
> Wait for the prerequisites to be installed. When prompted, restart the server to continue the installation.

```PowerShell
Remove-Item "C:\NotBackedUp\Temp\PrerequisiteInstallerFiles_SP1" -Recurse
```

### # Install SharePoint Server 2013 on farm servers

```PowerShell
& X:\setup.exe
```

> **Important**
>
> Wait for the installation to complete.

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Dismount SharePoint Server 2013 installation media

```PowerShell
$vmHost = "FORGE"
$vmName = "EXT-WEB02A"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

---

### # Add SharePoint bin folder to PATH environment variable

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-PathFolders.ps1 `
    ("C:\Program Files\Common Files\Microsoft Shared\web server extensions" `
        + "\15\BIN") `
    -EnvironmentVariableTarget "Machine"

exit
```

> **Important**
>
> Restart PowerShell for environment variable change to take effect.

### # Install Cumulative Update for SharePoint Server 2013

#### # Download update

```PowerShell
net use \\ICEMAN\Products /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$patch = "15.0.4833.1000 - SharePoint 2013 June 2016 CU"

$sourcePath = ("\\ICEMAN\Products\Microsoft\SharePoint 2013" `
    + "\Patches\$patch")

$destPath = "C:\NotBackedUp\Temp\$patch"

robocopy $sourcePath $destPath /E
```

#### # Install update

```PowerShell
& "$destPath\*.exe"
```

> **Important**
>
> Wait for the update to be installed.

```Console
cls
Remove-Item "C:\NotBackedUp\Temp\$patch" -Recurse
```

### # Install Cumulative Update for AppFabric 1.1

#### # Download update

```PowerShell
$patch = "Cumulative Update 7"

$sourcePath = ("\\ICEMAN\Products\Microsoft\AppFabric 1.1" `
    + "\Patches\$patch")

$destPath = "C:\NotBackedUp\Temp\$patch"

robocopy $sourcePath $destPath /E
```

#### # Install update

```PowerShell
& "$destPath\*.exe"
```

> **Important**
>
> Wait for the update to be installed.

```Console
cls
Remove-Item "C:\NotBackedUp\Temp\$patch" -Recurse
```

#### # Enable nonblocking garbage collection for Distributed Cache Service

```PowerShell
Notepad ($env:ProgramFiles `
    + "\AppFabric 1.1 for Windows Server\DistributedCacheService.exe.config")
```

---

**DistributedCacheService.exe.config**

```XML
  <appSettings>
    <add key="backgroundGC" value="true"/>
  </appSettings>
```

---

```PowerShell
cls
```

## # Install and configure additional software

### # Install Prince on front-end Web servers

```PowerShell
& "\\ICEMAN\Products\Prince\prince-7.1-setup.exe"
```

> **Important**
>
> Wait for the software to be installed.

```PowerShell
cls
```

#### # Configure Prince license

```PowerShell
Copy-Item `
    \\ICEMAN\Products\Prince\Prince-license.dat `
    'C:\Program Files (x86)\Prince\Engine\license\license.dat'
```

1. In the **Prince** window, click the **Help** menu and then click **License**.
2. In the **Prince License** window:
   1. Click **Open** and then locate the license file (**[\\\\ICEMAN\\Products\\Prince\\Prince-license.dat](\\ICEMAN\Products\Prince\Prince-license.dat)**).
   2. Click **Accept** to save the license information.
   3. Verify the license information and then click **Close**.
3. Close the Prince application.

### Install additional service packs and updates

> **Important**
>
> Wait for the updates to be installed and restart the server (if necessary).

### Add Web servers to the farm

### # Grant permissions on DCOM applications for SharePoint

```PowerShell
$tempScript = [Io.Path]::GetTempFileName().Replace(".tmp", ".ps1")

$sourceScript = "\\EXT-APP02A\Builds\ClientPortal\4.0.675.0" `
    + "\DeploymentFiles\Scripts\Configure DCOM Permissions.ps1"

Get-Content $sourceScript | Out-File $tempScript

& $tempScript -Verbose

Remove-Item $tempScript
```

```PowerShell
cls
```

### # Configure People Picker to support searches across one-way trust

#### # Set application password used for encrypting credentials

```PowerShell
$appPassword = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted for the secure string, type the password for encrypting sensitive data in SharePoint applications.

```PowerShell
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($appPassword))

stsadm -o setapppassword -password $plainPassword
```

#### # Modify permissions on registry key where encrypted credentials are stored

```PowerShell
$regPath = `
    "HKLM:\SOFTWARE\Microsoft\Shared Tools\Web Server Extensions\15.0\Secure"

$acl = Get-Acl $regPath

$rule = New-Object System.Security.AccessControl.RegistryAccessRule(
    "$env:COMPUTERNAME\WSS_WPG",
    "ReadKey",
    "ContainerInherit",
    "None",
    "Allow")

$acl.SetAccessRule($rule)
Set-Acl -Path $regPath -AclObject $acl
```

```PowerShell
cls
```

### # Map Web application to loopback address in Hosts file

```PowerShell
& C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    -IPAddress 127.0.0.1 `
    -Hostnames client-test.securitasinc.com `
    -Verbose
```

### # Allow specific host names mapped to 127.0.0.1

```PowerShell
& C:\NotBackedUp\Public\Toolbox\PowerShell\Add-BackConnectionHostNames.ps1 `
    -HostNames client-test.securitasinc.com `
    -Verbose
```

```PowerShell
cls
```

### # Configure SSL on Internet zone

#### # Install SSL certificate

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

#### Add HTTPS binding to site in IIS

```PowerShell
cls
```

### # Enable disk-based caching for Web application

```PowerShell
Push-Location ("C:\inetpub\wwwroot\wss\VirtualDirectories\" `
    + "client-test.securitasinc.com80")

copy web.config "web - Copy.config"

C:\NotBackedUp\Public\Toolbox\DiffMerge\DiffMerge.exe `
    '\\EXT-APP02A\C$\inetpub\wwwroot\wss\VirtualDirectories\client-test.securitasinc.com80\web.config' `
    .\web.config

Pop-Location
```

```PowerShell
cls
```

### # Configure logging

```PowerShell
$tempScript = [Io.Path]::GetTempFileName().Replace(".tmp", ".ps1")

$sourceScript = "\\EXT-APP02A\Builds\ClientPortal\4.0.675.0" `
    + "\DeploymentFiles\Scripts\Add Event Log Sources.ps1"

Get-Content $sourceScript | Out-File $tempScript

& $tempScript -Verbose

Remove-Item $tempScript
```

```PowerShell
cls
```

### # Configure claims-based authentication

```PowerShell
Push-Location "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\WebServices\SecurityToken"

copy .\web.config ".\web - Copy.config"

notepad web.config
```

---

**Web.config**

```XML
  <connectionStrings>
    <add
      name="SecuritasPortal"
      connectionString="Server=EXT-SQL02;Database=SecuritasPortal;Integrated Security=true" />
  </connectionStrings>

  <system.web>
    <membership>
      <providers>
        <add
          name="SecuritasSqlMembershipProvider"
          type="System.Web.Security.SqlMembershipProvider, System.Web, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a"
          applicationName="Securitas Portal"
          connectionStringName="SecuritasPortal"
          passwordFormat="Hashed" />
      </providers>
    </membership>
    <roleManager>
      <providers>
        <add
          name="SecuritasSqlRoleProvider"
          type="System.Web.Security.SqlRoleProvider, System.Web, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a"
          applicationName="Securitas Portal"
          connectionStringName="SecuritasPortal" />
      </providers>
    </roleManager>
  </system.web>
```

---

```PowerShell
Pop-Location
```

## Create and configure media website

### Install IIS Media Services 4.1

#### Download Web Platform Installer

(skipped)

```PowerShell
cls
```

#### # Install IIS Media Services

```PowerShell
net use \\ICEMAN\Products /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
& ('\\ICEMAN\Products\Microsoft' `
    + '\Web Platform Installer 5.0\wpilauncher.exe')
```

```PowerShell
cls
```

### # Install Web Deploy 3.6

#### # Install Web Deploy

```PowerShell
& ("\\ICEMAN\Products\Microsoft" `
    + "\Web Platform Installer 5.0\wpilauncher.exe")
```

```PowerShell
cls
```

### # Create media website on front-end Web servers

#### # Create media website on first front-end Web server

```PowerShell
$tempScript = [Io.Path]::GetTempFileName().Replace(".tmp", ".ps1")

$sourceScript = "\\EXT-APP02A\Builds\ClientPortal\4.0.675.0" `
    + "\DeploymentFiles\Scripts\Configure Media Website.ps1"

Get-Content $sourceScript | Out-File $tempScript

& $tempScript -SiteName media-test.securitasinc.com -Verbose

Remove-Item $tempScript
```

#### Configure SSL bindings on media website

```PowerShell
cls
```

#### # Create media website on other web servers in farm

```PowerShell
Push-Location "C:\Program Files\IIS\Microsoft Web Deploy V3"

$websiteName = "media-test.securitasinc.com"

.\msdeploy.exe -verb:sync `
    -source:apppoolconfig="$websiteName" `
    -dest:apppoolconfig="$websiteName"`,computername=EXT-WEB02B
```

.\\msdeploy.exe -verb:sync `

```PowerShell
    -source:apphostconfig="$websiteName" `
    -dest:apphostconfig="$websiteName"`,computername=EXT-WEB02B
```

```PowerShell
cls
Pop-Location
```

### # Copy media website to front-end Web servers

#### # Copy media website content from Production

```PowerShell
net use \\ICEMAN\Archive /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$websiteName = "media-test.securitasinc.com"

robocopy `
```

    '[\\\\ICEMAN\\Archive\\Clients\\Securitas\\Media](\\ICEMAN\Archive\Clients\Securitas\Media)' C:\\inetpub\\wwwroot\\\$websiteName /E

```PowerShell
cls
```

#### # Copy media website content to other front-end Web server in farm

```PowerShell
$websiteName = "media-test.securitasinc.com"

$contentPath = "C:\inetpub\wwwroot\$websiteName"

Push-Location "C:\Program Files\IIS\Microsoft Web Deploy V3"

.\msdeploy.exe -verb:sync `
    -source:contentPath="$contentPath" `
    -dest:contentPath="$contentPath"`,computername=EXT-WEB02B

Pop-Location
```

## Create and configure the Cloud Portal Web application

### Configure SSL on the Internet zone

#### Add HTTPS binding to site in IIS

```PowerShell
cls
```

### # Enable disk-based caching for Web application

```PowerShell
Push-Location ("C:\inetpub\wwwroot\wss\VirtualDirectories\" `
    + "cloud-test.securitasinc.com80")

copy web.config "web - Copy.config"

C:\NotBackedUp\Public\Toolbox\DiffMerge\DiffMerge.exe `
    '\\EXT-APP02A\C$\inetpub\wwwroot\wss\VirtualDirectories\cloud-test.securitasinc.com80\web.config' `
    .\web.config

Pop-Location
```

```PowerShell
cls
```

### # Configure logging

```PowerShell
$tempScript = [Io.Path]::GetTempFileName().Replace(".tmp", ".ps1")

$sourceScript = "\\EXT-APP02A\Builds\CloudPortal\2.0.122.0" `
    + "\DeploymentFiles\Scripts\Add Event Log Sources.ps1"

Get-Content $sourceScript | Out-File $tempScript

& $tempScript -Verbose

Remove-Item $tempScript
```

```PowerShell
cls
```

# Install Employee Portal

## # Extend SecuritasConnect and Cloud Portal web applications

```PowerShell
cls
```

### # Enable disk-based caching for "intranet" websites

#### # Enable disk-based caching for SecuritasConnect "intranet" website

```PowerShell
Push-Location ("C:\inetpub\wwwroot\wss\VirtualDirectories\" `
    + "client2-test.securitasinc.com443")

copy web.config "web - Copy.config"

C:\NotBackedUp\Public\Toolbox\DiffMerge\DiffMerge.exe `
    '..\client-test.securitasinc.com80\web.config' `
    .\web.config

Pop-Location
```

#### # Enable disk-based caching for Cloud Portal "intranet" website

```PowerShell
Push-Location ("C:\inetpub\wwwroot\wss\VirtualDirectories\" `
    + "cloud2-test.securitasinc.com443")

copy web.config "web - Copy.config"

C:\NotBackedUp\Public\Toolbox\DiffMerge\DiffMerge.exe `
    '..\cloud-test.securitasinc.com80\web.config' `
    .\web.config

Pop-Location
```

```PowerShell
cls
```

### # Map intranet URLs to loopback address in Hosts file

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    127.0.0.1 client2-test.securitasinc.com, cloud2-test.securitasinc.com
```

### # Allow specific host names mapped to 127.0.0.1

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-BackConnectionHostnames.ps1 `
    client2-test.securitasinc.com, cloud2-test.securitasinc.com
```

## Install Web Deploy 3.6

### Install Web Deploy

(skipped -- since this was completed earlier)

```PowerShell
cls
```

## # Install .NET Framework 4.5

### # Download .NET Framework 4.5.2 installer

```PowerShell
net use \\ICEMAN\Products /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
Copy-Item `
    ("\\ICEMAN\Products\Microsoft\.NET Framework 4.5\.NET Framework 4.5.2\" `
        + "NDP452-KB2901907-x86-x64-AllOS-ENU.exe") `
    C:\NotBackedUp\Temp
```

### # Install .NET Framework 4.5.2

```PowerShell
& C:\NotBackedUp\Temp\NDP452-KB2901907-x86-x64-AllOS-ENU.exe
```

> **Important**
>
> When prompted, restart the computer to complete the installation.

```PowerShell
Remove-Item C:\NotBackedUp\Temp\NDP452-KB2901907-x86-x64-AllOS-ENU.exe
```

### Install updates

> **Important**
>
> When prompted, restart the computer to complete the process of installing the updates.

## # Upgrade to System Center Operations Manager 2016

### # Uninstall SCOM 2012 R2 agent

```PowerShell
msiexec /x `{786970C5-E6F6-4A41-B238-AE25D4B91EEA`}

Restart-Computer
```

### # Install SCOM 2016 agent

```PowerShell
net use \\tt-fs01.corp.technologytoolbox.com\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$msiPath = "\\tt-fs01.corp.technologytoolbox.com\Products\Microsoft" `
    + "\System Center 2016\Agents\SCOM\AMD64\MOMAgent.msi"

msiexec.exe /i $msiPath `
    MANAGEMENT_GROUP=HQ `
    MANAGEMENT_SERVER_DNS=tt-scom01.corp.technologytoolbox.com `
    ACTIONS_USE_COMPUTER_ACCOUNT=1
```

> **Important**
>
> Wait for the installation to complete.

### Approve manual agent install in Operations Manager

## # Move VM to extranet VLAN

### # Enable DHCP

```PowerShell
$interfaceAlias = Get-NetAdapter `
    -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    select -ExpandProperty Name

@("IPv4", "IPv6") | ForEach-Object {
    $addressFamily = $_

    $interface = Get-NetAdapter $interfaceAlias |
        Get-NetIPInterface -AddressFamily $addressFamily

    If ($interface.Dhcp -eq "Disabled")
    {
        # Remove existing gateway
        $ipConfig = $interface | Get-NetIPConfiguration

        If ($addressFamily -eq "IPv4" -and $ipConfig.Ipv4DefaultGateway)
        {
            $interface |
                Remove-NetRoute -AddressFamily $addressFamily -Confirm:$false
        }

        If ($addressFamily -eq "IPv6" -and $ipConfig.Ipv6DefaultGateway)
        {
            $interface |
                Remove-NetRoute -AddressFamily $addressFamily -Confirm:$false
        }

        # Enable DHCP
        $interface | Set-NetIPInterface -DHCP Enabled

        # Configure the  DNS Servers automatically
        $interface | Set-DnsClientServerAddress -ResetServerAddresses
    }
}
```

### # Rename network connection

```PowerShell
$interfaceAlias = "Extranet"

Get-NetAdapter `
    -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

### # Disable jumbo frames

```PowerShell
Set-NetAdapterAdvancedProperty `
    -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 1514

Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"
```

---

**TT-VMM01A**

```PowerShell
cls
```

### # Configure static IP address using VMM

```PowerShell
$vmName = "EXT-WEB02A"

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

Set-SCVirtualNetworkAdapter `
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

## Issue - Error accessing SharePoint sites (e.g. http://client-test.securitasinc.com)

Log Name:      Application\
Source:        ASP.NET 4.0.30319.0\
Date:          5/18/2017 10:25:38 AM\
Event ID:      1309\
Task Category: Web Event\
Level:         Warning\
Keywords:      Classic\
User:          N/A\
Computer:      EXT-WEB02A.extranet.technologytoolbox.com\
Description:\
Event code: 3005\
Event message: An unhandled exception has occurred.\
Event time: 5/18/2017 10:25:38 AM\
Event time (UTC): 5/18/2017 4:25:38 PM\
Event ID: 53a12e3e19af46f19c73e78673fc5163\
Event sequence: 8\
Event occurrence: 1\
Event detail code: 0\
\
Application information:\
    Application domain: /LM/W3SVC/762047535/ROOT-1-131395983088891094\
    Trust level: Full\
    Application Virtual Path: /\
    Application Path: C:\\inetpub\\wwwroot\\wss\\VirtualDirectories\\client-test.securitasinc.com80\\\
    Machine name: EXT-WEB02A\
\
Process information:\
    Process ID: 6056\
    Process name: w3wp.exe\
    Account name: EXTRANET\\s-web-client\
\
Exception information:\
    Exception type: FileLoadException\
    Exception message: Loading this assembly would produce a different grant set from other instances. (Exception from HRESULT: 0x80131401)\
   at System.Linq.Enumerable.Count[TSource](IEnumerable`1 source)\
   at Microsoft.SharePoint.IdentityModel.SPChunkedCookieHandler.ReadCore(String name, HttpContext context)\
   at Microsoft.IdentityModel.Web.SessionAuthenticationModule.TryReadSessionTokenFromCookie(SessionSecurityToken& sessionToken)\
   at Microsoft.IdentityModel.Web.SessionAuthenticationModule.OnAuthenticateRequest(Object sender, EventArgs eventArgs)\
   at Microsoft.SharePoint.IdentityModel.SPSessionAuthenticationModule.OnAuthenticateRequest(Object sender, EventArgs eventArgs)\
   at System.Web.HttpApplication.SyncEventExecutionStep.System.Web.HttpApplication.IExecutionStep.Execute()\
   at System.Web.HttpApplication.ExecuteStep(IExecutionStep step, Boolean& completedSynchronously)

\
\
Request information:\
    Request URL: [https://client-test.securitasinc.com:443/favicon.ico](https://client-test.securitasinc.com:443/favicon.ico)\
    Request path: /favicon.ico\
    User host address: 127.0.0.1\
    User:\
    Is authenticated: False\
    Authentication Type:\
    Thread account name: EXTRANET\\s-web-client\
\
Thread information:\
    Thread ID: 18\
    Thread account name: EXTRANET\\s-web-client\
    Is impersonating: False\
    Stack trace:    at System.Linq.Enumerable.Count[TSource](IEnumerable`1 source)\
   at Microsoft.SharePoint.IdentityModel.SPChunkedCookieHandler.ReadCore(String name, HttpContext context)\
   at Microsoft.IdentityModel.Web.SessionAuthenticationModule.TryReadSessionTokenFromCookie(SessionSecurityToken& sessionToken)\
   at Microsoft.IdentityModel.Web.SessionAuthenticationModule.OnAuthenticateRequest(Object sender, EventArgs eventArgs)\
   at Microsoft.SharePoint.IdentityModel.SPSessionAuthenticationModule.OnAuthenticateRequest(Object sender, EventArgs eventArgs)\
   at System.Web.HttpApplication.SyncEventExecutionStep.System.Web.HttpApplication.IExecutionStep.Execute()\
   at System.Web.HttpApplication.ExecuteStep(IExecutionStep step, Boolean& completedSynchronously)\

### References

**Loading this assembly would produce a different grant set from other instances. (Exception from HRESULT: 0x80131401)**\
From <[http://blog.bugrapostaci.com/2017/02/08/loading-this-assembly-would-produce-a-different-grant-set-from-other-instances-exception-from-hresult-0x80131401/](http://blog.bugrapostaci.com/2017/02/08/loading-this-assembly-would-produce-a-different-grant-set-from-other-instances-exception-from-hresult-0x80131401/)>

**Monitoring SharePoint 2010 Applications in System Center 2012 SP1**\
From <[https://technet.microsoft.com/en-us/library/jj614617.aspx?tduid=(1dfb939b69d4a5ed09b44f51992a8b97)(256380)(2459594)(TnL5HPStwNw-v0X_tBOK3jzpbtaadMW8RA)()](https://technet.microsoft.com/en-us/library/jj614617.aspx?tduid=(1dfb939b69d4a5ed09b44f51992a8b97)(256380)(2459594)(TnL5HPStwNw-v0X_tBOK3jzpbtaadMW8RA)())>

**SCOM 2016 Sharepoint 2013 PerfMon64.dll crash W3wp.exe**\
From <[https://social.technet.microsoft.com/Forums/en-US/24b4d768-57a2-42c9-8e18-1ef8c075913a/scom-2016-sharepoint-2013-perfmon64dll-crash-w3wpexe?forum=scomapm](https://social.technet.microsoft.com/Forums/en-US/24b4d768-57a2-42c9-8e18-1ef8c075913a/scom-2016-sharepoint-2013-perfmon64dll-crash-w3wpexe?forum=scomapm)>

**SCOM 2016 Agent Crashing Legacy IIS Application Pools**\
From <[http://kevingreeneitblog.blogspot.ie/2017/03/scom-2016-agent-crashing-legacy-iis.html](http://kevingreeneitblog.blogspot.ie/2017/03/scom-2016-agent-crashing-legacy-iis.html)>

**APM feature in SCOM 2016 Agent may cause a crash for the IIS Application Pool running under .NET 2.0 runtime**\
From <[https://blogs.technet.microsoft.com/momteam/2017/03/21/apm-feature-in-scom-2016-agent-may-cause-a-crash-for-the-iis-application-pool-running-under-net-2-0-runtime/](https://blogs.technet.microsoft.com/momteam/2017/03/21/apm-feature-in-scom-2016-agent-may-cause-a-crash-for-the-iis-application-pool-running-under-net-2-0-runtime/)>

### Solution

Remove SCOM agent and reinstall without Application Performance Monitoring (APM).

#### Remove SCOM agent

> **Note**
>
> When prompted, restart the server.

#### # Clean up SCOM agent folder

```PowerShell
Remove-Item "C:\Program Files\Microsoft Monitoring Agent" -Recurse -Force
```

#### Install SCOM agent without Application Performance Monitoring (APM)

---

**FOOBAR10**

```PowerShell
cls
```

##### # Copy SCOM agent setup files from file server

```PowerShell
$source = "\\TT-FS01.corp.technologytoolbox.com\Products\Microsoft" `
```

    + "\\System Center 2016\\SCOM\\agent\\AMD64"

```PowerShell
$destination = "\\EXT-WEB02A.extranet.technologytoolbox.com\C$\NotBackedUp\Temp" `
```

    + "\\System Center 2016\\SCOM\\agent\\AMD64"

```Console
robocopy $source $destination /E /MIR
```

---

```PowerShell
cls
```

##### # Install SCOM agent

```PowerShell
$msiPath = "C:\NotBackedUp\Temp\System Center 2016\SCOM\agent\AMD64\MOMAgent.msi"

msiexec.exe /i $msiPath `
    MANAGEMENT_GROUP=HQ `
    MANAGEMENT_SERVER_DNS=TT-SCOM01.corp.technologytoolbox.com `
    ACTIONS_USE_COMPUTER_ACCOUNT=1 `
    NOAPM=1
```

```PowerShell
cls
```

##### # Delete SCOM agent setup files

```PowerShell
Remove-Item "C:\NotBackedUp\Temp\System Center 2016" -Recurse
```

#### Approve manual agent install in Operations Manager

**TODO:**

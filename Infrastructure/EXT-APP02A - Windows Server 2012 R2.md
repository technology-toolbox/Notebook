# EXT-APP02A - Windows Server 2012 R2 Standard

Tuesday, October 4, 2016
5:10 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

Install SecuritasConnect v4.0

## Deploy and configure server infrastructure

### Install Windows Server 2012 R2

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Create virtual machine

```PowerShell
$vmHost = "BEAST"
$vmName = "EXT-APP02A"
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

#### Install custom Windows Server 2012 R2 image

- Start-up disk: [\\\\ICEMAN\\Products\\Microsoft\\MDT-Deploy-x86.iso](\\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso)
- On the **Task Sequence** step, select **Windows Server 2012 R2** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **EXT-APP02A**.
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

#### # Rename local Administrator account and set password

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

#### Login as EXT-APP02A\\foo

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
    -ServerAddresses 192.168.10.209,192.168.10.210
```

##### # Configure IPv6 DNS servers

```PowerShell
Set-DnsClientServerAddress `
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

ping iceman.corp.technologytoolbox.com -f -l 8900
```

```PowerShell
cls
```

### # Join member server to domain

#### # Add computer to domain

```PowerShell
Add-Computer `
    -DomainName extranet.technologytoolbox.com `
    -Credential (Get-Credential EXTRANET\jjameson-admin) `
    -Restart
```

#### Move computer to "SharePoint Servers" OU

---

**EXT-DC01 - Run as EXTRANET\\jjameson-admin**

```PowerShell
$computerName = "EXT-APP02A"
$targetPath = "OU=SharePoint Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=extranet,DC=technologytoolbox,DC=com"

Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath

Restart-Computer $computerName

Restart-Computer : Failed to restart the computer EXT-FOOBAR8 with the following error message: The RPC server is
unavailable. (Exception from HRESULT: 0x800706BA).
At line:1 char:1
+ Restart-Computer $computerName
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (EXT-FOOBAR8:String) [Restart-Computer], InvalidOperationException
    + FullyQualifiedErrorId : RestartcomputerFailed,Microsoft.PowerShell.Commands.RestartComputerCommand
```

---

---

**EXT-DC01 - Run as EXTRANET\\jjameson-admin**

### # Create and configure setup account for SharePoint

#### # Create setup account for SharePoint

```PowerShell
$displayName = "Setup account for SharePoint"
$defaultUserName = "setup-sharepoint"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@extranet.technologytoolbox.com"
$orgUnit = "OU=Setup Accounts,OU=IT,DC=extranet,DC=technologytoolbox,DC=com"

New-ADUser `
    -Name $displayName `
    -DisplayName $displayName `
    -SamAccountName $cred.UserName `
    -AccountPassword $cred.Password `
    -UserPrincipalName $userPrincipalName `
    -Path $orgUnit `
    -Enabled:$true `
    -CannotChangePassword:$true
```

#### # Add setup account to SharePoint Admins domain group

```PowerShell
Add-ADGroupMember `
    -Identity "SharePoint Admins" `
    -Members "setup-sharepoint"
```

---

### Login as EXTRANET\\setup-sharepoint

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

Set-VMDvdDrive -ComputerName BEAST -VMName EXT-APP02A -Path $imagePath
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
Set-VMDvdDrive -ComputerName BEAST -VMName EXT-APP02A -Path $null
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
$vmHost = "BEAST"
$vmName = "EXT-APP02A"
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

### Create service accounts

---

**EXT-DC01 - Run as EXTRANET\\jjameson-admin**

```PowerShell
cls
```

### # Create service account for SharePoint 2013 farm

```PowerShell
$displayName = "Service account for SharePoint 2013 farm"
$defaultUserName = "s-sp-farm"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@extranet.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=IT,DC=extranet,DC=technologytoolbox,DC=com"

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

### # Create service account for SharePoint 2013 service applications

```PowerShell
$displayName = "Service account for SharePoint 2013 service applications"
$defaultUserName = "s-sp-serviceapp"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@extranet.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=IT,DC=extranet,DC=technologytoolbox,DC=com"

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

### # Create service account for SharePoint 2013 crawler

```PowerShell
$displayName = "Service account for SharePoint 2013 crawler"
$defaultUserName = "s-sp-crawler"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@extranet.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=IT,DC=extranet,DC=technologytoolbox,DC=com"

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

### # Create service account for SecuritasConnect Web application

```PowerShell
$displayName = "Service account for SecuritasConnect Web application"
$defaultUserName = "s-web-client"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@extranet.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=IT,DC=extranet,DC=technologytoolbox,DC=com"

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

### # Create service account for SharePoint 2013 "Portal Super User"

```PowerShell
$displayName = "Service account for SharePoint 2013 `"Portal Super User`""
$defaultUserName = "s-sp-psu"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@extranet.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=IT,DC=extranet,DC=technologytoolbox,DC=com"

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

### # Create service account for SharePoint 2013 "Portal Super Reader"

```PowerShell
$displayName = "Service account for SharePoint 2013 `"Portal Super Reader`""
$defaultUserName = "s-sp-psr"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@extranet.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=IT,DC=extranet,DC=technologytoolbox,DC=com"

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

### Create Active Directory container to track SharePoint 2013 installations

(skipped - since this was completed previously)

### Install and configure SQL Server 2014

## Install SharePoint Server 2013

### Download SharePoint 2013 prerequisites to file share

(skipped - since this was completed previously)

### Install SharePoint 2013 prerequisites on farm servers

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Mount SharePoint Server 2013 installation media

```PowerShell
$vmHost = "BEAST"
$vmName = "EXT-APP02A"
$imagePath = "\\ICEMAN\Products\Microsoft\SharePoint 2013\" `
    + "en_sharepoint_server_2013_with_sp1_x64_dvd_3823428.iso"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $imagePath
```

---

#### # Copy SharePoint Server 2013 prerequisite files to SharePoint server

```PowerShell
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
$vmHost = "BEAST"
$vmName = "EXT-APP02A"

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

## Create and configure SharePoint farm

---

**EXT-SQL02 - SQL Server Management Studio**

### -- Add setup account to dbcreator and securityadmin server roles

```SQL
USE [master]
GO
CREATE LOGIN [EXTRANET\setup-sharepoint]
FROM WINDOWS
WITH DEFAULT_DATABASE=[master]
GO
ALTER SERVER ROLE [dbcreator]
ADD MEMBER [EXTRANET\setup-sharepoint]
GO
ALTER SERVER ROLE [securityadmin]
ADD MEMBER [EXTRANET\setup-sharepoint]
GO
```

---

### # Copy SecuritasConnect build to SharePoint server

#### # Create file share for builds

```PowerShell
New-Item -ItemType Directory -Path C:\Shares\Builds

New-SmbShare `
  -Name Builds `
  -Path C:\Shares\Builds `
  -CachingMode None `
  -ChangeAccess Everyone

New-Item -ItemType Directory -Path C:\Shares\Builds\ClientPortal
```

#### # Copy build to SharePoint server

```PowerShell
net use \\ICEMAN\Builds /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$build = "4.0.675.0"

$sourcePath = "\\ICEMAN\Builds\ClientPortal\$build"
$destPath = "\\EXT-APP02A\Builds\ClientPortal\$build"

robocopy $sourcePath $destPath /E
```

#### # Create SharePoint farm

```PowerShell
cd C:\Shares\Builds\ClientPortal\4.0.675.0\DeploymentFiles\Scripts

$currentUser = whoami

If ($currentUser -eq "EXTRANET\setup-sharepoint")
{
    & '.\Create Farm.ps1' `
        -DatabaseServer EXT-SQL02 `
        -CentralAdminAuthProvider NTLM `
        -Verbose
}
Else
{
    Throw "Incorrect user"
}
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-sp-farm**.\
> Expect the previous operation to complete in approximately 7 minutes.

### Add Web servers to SharePoint farm

### Add SharePoint Central Administration to "Local intranet" zone

(skipped -- since the "Create Farm.ps1" script configures this)

```PowerShell
cls
```

### # Configure PowerShell access for SharePoint administrators group

```PowerShell
$adminsGroup = "EXTRANET\SharePoint Admins"

Get-SPDatabase |
    Where-Object {$_.WebApplication -like "SPAdministrationWebApplication"} |
    Add-SPShellAdmin $adminsGroup
```

```PowerShell
cls
```

### # Grant permissions on DCOM applications for SharePoint

```PowerShell
cd C:\Shares\Builds\ClientPortal\4.0.675.0\DeploymentFiles\Scripts

& '.\Configure DCOM Permissions.ps1' -Verbose
```

### Configure diagnostic logging

### Configure usage and health data collection

```PowerShell
cls
```

### # Configure outgoing e-mail settings

```PowerShell

$smtpServer = "smtp-test.technologytoolbox.com"
$fromAddress = "s-sp-farm@technologytoolbox.com"
$replyAddress = "no-reply@technologytoolbox.com"
$characterSet = 65001 # Unicode (UTF-8)

$centralAdmin = Get-SPWebApplication -IncludeCentralAdministration |
    Where-Object { $_.IsAdministrationWebApplication -eq $true }

$centralAdmin.UpdateMailSettings(
    $smtpServer,
    $fromAddress,
    $replyAddress,
    $characterSet)
```

## Install and configure Office Web Apps

### Create DNS record for Office Web Apps

(skipped -- since this was done previously)

### Deploy Office Web Apps farm

```PowerShell
cls
```

#### # Configure SharePoint 2013 farm to use Office Web Apps

```PowerShell
New-SPWOPIBinding -ServerName wac.fabrikam.com

Set-SPWOPIZone -zone external-https
```

#### Configure name resolution on Office Web Apps farm

---

**EXT-WAC02A**

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    -IPAddress 192.168.10.34 `
    -Hostnames EXT-APP02A, client-test.securitasinc.com
```

---

## Backup SharePoint 2010 environment

### Backup databases in SharePoint 2010 environment

(Download backup files from PROD to [\\\\ICEMAN\\Archive\\Clients\\Securitas\\Backups](\\ICEMAN\Archive\Clients\Securitas\Backups))

---

**EXT-SQL02**

```PowerShell
cls
```

#### # Copy the backup files to the SQL Server for the SharePoint 2013 farm

```PowerShell
$destination = 'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full'

mkdir $destination

net use \\ICEMAN\Archive /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
robocopy `
    \\ICEMAN\Archive\Clients\Securitas\Backups `
    $destination `
    *.bak /XF WSS_Content_CloudPortal*
```

#### # Rename backup files

```PowerShell
ren `
    ($destination + '\ManagedMetadataService_backup_2016_09_29_084517_2036824.bak') `
    'ManagedMetadataService.bak'

ren `
    ($destination + '\SecuritasPortal_backup_2016_09_29_084517_2505600.bak') `
    'SecuritasPortal.bak'

ren `
    ($destination + '\UserProfileService_Profile_backup_2016_09_29_084517_2193209.bak') `
    'UserProfileService_Profile.bak'

ren `
    ($destination + '\UserProfileService_Social_backup_2016_09_29_084517_2193209.bak') `
    'UserProfileService_Social.bak'

ren `
    ($destination + '\UserProfileService_Sync_backup_2016_09_29_084517_2193209.bak') `
    'UserProfileService_Sync.bak'

ren `
    ($destination + '\WSS_Content_SecuritasPortal_backup_2016_09_29_084517_2349669.bak') `
    'WSS_Content_SecuritasPortal.bak'

ren `
    ($destination + '\WSS_Content_SecuritasPortal2_backup_2016_09_29_084517_2505600.bak') `
    'WSS_Content_SecuritasPortal2.bak'
```

---

### Export User Profile Synchronization encryption key

---

**258521-VM4 - Command Prompt**

#### REM Export MIIS encryption key

```Console
cd "C:\Program Files\Microsoft Office Servers\14.0\Synchronization Service\Bin\"

miiskmu.exe /e C:\Users\%USERNAME%\Desktop\miiskeys-1.bin ^
    /u:SEC\svc-sharepoint-2010 *
```

> **Note**
>
> When prompted for the password, type the password for the SharePoint 2010 service account.

---

```PowerShell
cls
```

#### # Copy MIIS encryption key file to SharePoint 2013 server

```PowerShell
net use \\ICEMAN\Archive /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
copy `
    "\\ICEMAN\Archive\Clients\Securitas\Backups\miiskeys-1.bin" `
    "C:\Users\setup-sharepoint\Desktop"
```

## # Configure SharePoint services and service applications

### # Change service account for Distributed Cache

```PowerShell
cd C:\Shares\Builds\ClientPortal\4.0.675.0\DeploymentFiles\Scripts

& '.\Configure Distributed Cache.ps1' -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-sp-serviceapp**.\
> Expect the previous operation to complete in approximately 7-8 minutes.

#### Issue

Service account was changed on EXT-APP02A, but not on EXT-WEB02A nor EXT-WEB02B

```Text
PS C:\Shares\Builds\ClientPortal\4.0.675.0\DeploymentFiles\Scripts> Use-CacheCluster
PS C:\Shares\Builds\ClientPortal\4.0.675.0\DeploymentFiles\Scripts> Get-CacheHost
Get-CacheHost : ErrorCode<ERRCAdmin039>:SubStatus<ES0001>:Cache host EXT-WEB02A.extranet.technologytoolbox.com is not reachable.
At line:1 char:1
+ Get-CacheHost
+ ~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [Get-AFCacheHostStatus], DataCacheException
    + FullyQualifiedErrorId : ERRCAdmin039,Microsoft.ApplicationServer.Caching.Commands.GetAFCacheHostStatusCommand

Get-CacheHost : ErrorCode<ERRCAdmin039>:SubStatus<ES0001>:Cache host EXT-WEB02B.extranet.technologytoolbox.com is not reachable.
At line:1 char:1
+ Get-CacheHost
+ ~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [Get-AFCacheHostStatus], DataCacheException
    + FullyQualifiedErrorId : ERRCAdmin039,Microsoft.ApplicationServer.Caching.Commands.GetAFCacheHostStatusCommand


HostName : CachePort                            Service Name            Service Status Version Info
--------------------                            ------------            -------------- ------------
EXT-APP02A.extranet.technologytoolbox.com:22233 AppFabricCachingService UP             3 [3,3][1,3]
EXT-WEB02A.extranet.technologytoolbox.com:22233 AppFabricCachingService UNKNOWN        0 [0,0][0,0]
EXT-WEB02B.extranet.technologytoolbox.com:22233 AppFabricCachingService UNKNOWN        0 [0,0][0,0]
```

#### Solution

```PowerShell
Remove-SPDistributedCacheServiceInstance

Enable-NetFirewallRule `
    -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)"

Enable-NetFirewallRule `
    -DisplayName "File and Printer Sharing (Echo Request - ICMPv6-In)"
```

---

**EXT-WEB02A**

```PowerShell
Remove-SPDistributedCacheServiceInstance

Enable-NetFirewallRule `
    -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)"

Enable-NetFirewallRule `
    -DisplayName "File and Printer Sharing (Echo Request - ICMPv6-In)"
```

---

---

**EXT-WEB02B**

```PowerShell
Remove-SPDistributedCacheServiceInstance

Enable-NetFirewallRule `
    -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)"

Enable-NetFirewallRule `
    -DisplayName "File and Printer Sharing (Echo Request - ICMPv6-In)"
```

---

```PowerShell
Get-SPServiceInstance | ? {($_.service.tostring()) -eq "SPDistributedCacheService Name=AppFabricCachingService"}

$s = Get-SPServiceInstance {GUID}
$s.Delete()

Add-SPDistributedCacheServiceInstance
```

---

**EXT-WEB02A**

```PowerShell
Add-SPDistributedCacheServiceInstance
```

---

---

**EXT-WEB02B**

```PowerShell
Add-SPDistributedCacheServiceInstance
```

---

```PowerShell
cls
```

### # Configure State Service

```PowerShell
& '.\Configure State Service.ps1' -Verbose
```

### # Configure SharePoint ASP.NET Session State service

```PowerShell
Enable-SPSessionStateService -DatabaseName SessionStateService
```

### # Create application pool for SharePoint service applications

```PowerShell
& '.\Configure Service Application Pool.ps1' -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-sp-serviceapp**.

### Configure Managed Metadata Service

---

**EXT-SQL02 - SQL Server Management Studio**

#### -- Restore database backup from Production

```Console
DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\'
    + 'ManagedMetadataService.bak'

DECLARE @dataFilePath VARCHAR(255) =
  'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'ManagedMetadataService.mdf'

DECLARE @logFilePath VARCHAR(255) =
  'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'ManagedMetadataService_log.LDF'

RESTORE DATABASE ManagedMetadataService
  FROM DISK = @backupFilePath
  WITH FILE = 1,
    MOVE 'Securitas_CP_MMS' TO @dataFilePath,
    MOVE 'Securitas_CP_MMS_log' TO @logFilePath,
    NOUNLOAD,
    STATS = 5

GO
```

##### -- Add SharePoint setup account to db_owner role in restored databases

```SQL
USE [ManagedMetadataService]
GO

CREATE USER [EXTRANET\setup-sharepoint] FOR LOGIN [EXTRANET\setup-sharepoint]

ALTER ROLE [db_owner] ADD MEMBER [EXTRANET\setup-sharepoint]
GO
```

---

```PowerShell
cls
```

#### # Create Managed Metadata Service

```PowerShell
& '.\Configure Managed Metadata Service.ps1' -Confirm:$false -Verbose
```

##### Issue

The Managed Metadata Service or Connection is currently not available. The Application Pool or Managed Metadata Web Service may not have been started. Please Contact your Administrator.

##### Solution

1. Edit the MMS properties to temporarily change the database name (**ManagedMetadataService_tmp**).
2. Edit the MMS properties to revert to the restored database (**ManagedMetadataService**).
3. Reset IIS.
4. Delete temporary database (**ManagedMetadataService_tmp**).

##### Reference

**The Managed Metadata Service or Connection is currently not available in SharePoint 2013**\
From <[http://blog.areflyen.no/2014/08/21/the-managed-metadata-service-or-connection-is-currently-not-available-in-sharepoint-2013/](http://blog.areflyen.no/2014/08/21/the-managed-metadata-service-or-connection-is-currently-not-available-in-sharepoint-2013/)>

### Configure User Profile Service Application

---

**EXT-SQL02 - SQL Server Management Studio**

#### -- Restore database backups from Production

##### -- Restore profile database

```Console
DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\'
    + 'UserProfileService_Profile.bak'

DECLARE @dataFilePath VARCHAR(255) =
  'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'UserProfileService_Profile.mdf'

DECLARE @logFilePath VARCHAR(255) =
  'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'UserProfileService_Profile_log.LDF'

RESTORE DATABASE UserProfileService_Profile
  FROM DISK = @backupFilePath
  WITH FILE = 1,
    MOVE 'Profile DB New' TO @dataFilePath,
    MOVE 'Profile DB New_log' TO @logFilePath,
    NOUNLOAD,
    STATS = 5
```

##### -- Restore synchronization database

```Console
SET @backupFilePath =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\'
    + 'UserProfileService_Sync.bak'

SET @dataFilePath =
  'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'UserProfileService_Sync.mdf'

SET @logFilePath =
  'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'UserProfileService_Sync_log.LDF'

RESTORE DATABASE UserProfileService_Sync
  FROM DISK = @backupFilePath
  WITH FILE = 1,
    MOVE 'Sync DB New' TO @dataFilePath,
    MOVE 'Sync DB New_log' TO @logFilePath,
    NOUNLOAD,
    STATS = 5
```

##### -- Restore social tagging database

```Console
SET @backupFilePath =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\'
    + 'UserProfileService_Social.bak'

SET @dataFilePath =
  'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'UserProfileService_Social.mdf'

SET @logFilePath =
  'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'UserProfileService_Social_log.LDF'

RESTORE DATABASE UserProfileService_Social
  FROM DISK = @backupFilePath
  WITH FILE = 1,
    MOVE 'Social DB New' TO @dataFilePath,
    MOVE 'Social DB New_log' TO @logFilePath,
    NOUNLOAD,
    STATS = 5

GO
```

##### -- Add SharePoint setup account to db_owner role in restored databases

```SQL
USE [UserProfileService_Profile]
GO
CREATE USER [EXTRANET\setup-sharepoint]
FOR LOGIN [EXTRANET\setup-sharepoint]

ALTER ROLE [db_owner] ADD MEMBER [EXTRANET\setup-sharepoint]
GO

USE [UserProfileService_Social]
GO
CREATE USER [EXTRANET\setup-sharepoint]
FOR LOGIN [EXTRANET\setup-sharepoint]

ALTER ROLE [db_owner] ADD MEMBER [EXTRANET\setup-sharepoint]
GO

USE [UserProfileService_Sync]
GO
CREATE USER [EXTRANET\setup-sharepoint]
FOR LOGIN [EXTRANET\setup-sharepoint]

ALTER ROLE [db_owner] ADD MEMBER [EXTRANET\setup-sharepoint]
GO
```

##### -- Add new SharePoint farm account to db_owner role in restored databases

```SQL
USE [UserProfileService_Profile]
GO

CREATE USER [EXTRANET\s-sp-farm] FOR LOGIN [EXTRANET\s-sp-farm]

ALTER ROLE [db_owner] ADD MEMBER [EXTRANET\s-sp-farm]
GO

USE [UserProfileService_Social]
GO

CREATE USER [EXTRANET\s-sp-farm] FOR LOGIN [EXTRANET\s-sp-farm]

ALTER ROLE [db_owner] ADD MEMBER [EXTRANET\s-sp-farm]
GO

USE [UserProfileService_Sync]
GO

CREATE USER [EXTRANET\s-sp-farm] FOR LOGIN [EXTRANET\s-sp-farm]

ALTER ROLE [db_owner] ADD MEMBER [EXTRANET\s-sp-farm]
GO
```

---

```PowerShell
cls
```

#### # Create User Profile Service Application

# Use SharePoint farm service account to create User Profile Service Application:

```PowerShell
$farmCredential = Get-Credential (Get-SPFarm).DefaultServiceAccount.Name
```

> **Note**
>
> When prompted for the service account credentials, type the password for the SharePoint farm service account.

```PowerShell
net localgroup Administrators /add $farmCredential.UserName

Restart-Service SPTimerV4

Start-Process $PSHOME\powershell.exe `
    -Credential $farmCredential `
    -ArgumentList "-Command Start-Process PowerShell.exe -Verb Runas" `
    -Wait
```

---

**PowerShell -- running as EXTRANET\\s-sp-farm**

```PowerShell
cd C:\Shares\Builds\ClientPortal\4.0.675.0\DeploymentFiles\Scripts

& '.\Configure User Profile Service.ps1' -Verbose
```

> **Important**
>
> Wait for the service application to be configured.

```Console
exit
```

---

```Console
net localgroup Administrators /delete $farmCredential.UserName

Restart-Service SPTimerV4
```

#### Disable social features

(skipped -- since database was restored from Production)

```PowerShell
cls
```

### # Configure User Profile Synchronization (UPS)

#### # Configure NETWORK SERVICE permissions

```PowerShell
$path = "$env:ProgramFiles\Microsoft Office Servers\15.0"
icacls $path /grant "NETWORK SERVICE:(OI)(CI)(RX)"
```

#### # Temporarily add SharePoint farm account to local Administrators group

```PowerShell
$farmAccount = (Get-SPFarm).DefaultServiceAccount.Name

net localgroup Administrators /add $farmAccount

Restart-Service SPTimerV4
```

#### Start User Profile Synchronization Service

```PowerShell
cls
```

#### # Import MIIS encryption key

# Note: NullReferenceException occurs if you attempt to perform this step before starting the User Profile Synchronization Service.

# Import MIIS encryption key as the SharePoint farm service account:

```PowerShell
If ($farmCredential -eq $null)
{
    $farmCredential = Get-Credential (Get-SPFarm).DefaultServiceAccount.Name
}
```

> **Note**
>
> If prompted for the service account credentials, type the password for the SharePoint farm service account.

```PowerShell
Start-Process $PSHOME\powershell.exe `
    -Credential $farmCredential `
    -ArgumentList "-Command Start-Process cmd.exe -Verb Runas" `
    -Wait
```

---

**Command Prompt -- running as EXTRANET\\s-sp-farm**

```Console
cd "C:\Program Files\Microsoft Office Servers\15.0\Synchronization Service\Bin\"

miiskmu.exe /i "C:\Users\setup-sharepoint\Desktop\miiskeys-1.bin" ^
    {0E19E162-827E-4077-82D4-E6ABD531636E}
```

> **Important**
>
> Verify the encryption key was successfully imported.

```Console
exit
```

---

#### Wait for User Profile Synchronization Service to finish starting

> **Important**
>
> Wait until the status of **User Profile Synchronization Service** shows **Started** before proceeding.

```PowerShell
cls
```

#### # Remove SharePoint farm account from local Administrators group

```PowerShell
$farmAccount = (Get-SPFarm).DefaultServiceAccount.Name

net localgroup Administrators /delete $farmAccount

Restart-Service SPTimerV4
```

#### Grant the SharePoint farm service account the Remote Enable permission to Forefront Identity Manager

1. On the server that is running the synchronization service, click **Start**.
2. Type **wmimgmt.msc**, and then press Enter.
3. Right click **WMI Control**, and then click **Properties**.
4. In the **WMI Control Properties** window:
   1. Click the **Security** tab.
   2. Expand the **Root** list, and then select **MicrosoftIdentityIntegrationServer**.
   3. Click the **Security** button.
   4. In the **Security for ROOT\\MicrosoftIdentityIntegrationServer** window:
      1. Add the SharePoint farm service account to the list of groups and users.
      2. In the **Group or user names** list, select the SharePoint farm service account.
      3. In the **Permissions **section, select the **Allow** checkbox for the **Remote Enable** permission.
      4. Click **OK**.
   5. Click **OK**.
5. Close the WmiMgmt console.

##### Reference

[http://technet.microsoft.com/en-us/library/ee721049.aspx#RemovePermsProc](http://technet.microsoft.com/en-us/library/ee721049.aspx#RemovePermsProc)

#### Configure synchronization connections and import data from Active Directory

##### Create synchronization connections to Active Directory

| **Connection Name** | **Forest Name**            | **Account Name**        |
| ------------------- | -------------------------- | ----------------------- |
| TECHTOOLBOX         | corp.technologytoolbox.com | TECHTOOLBOX\\svc-sp-ups |
| FABRIKAM            | corp.fabrikam.com          | FABRIKAM\\s-sp-ups      |

[Issue configuring User Profile Synchronization in TEST](Issue configuring User Profile Synchronization in TEST)

##### Start profile synchronization

Number of user profiles (before import): 11,443\
Number of user profiles (after import): 11,936

```PowerShell
Start-Process `
    ("C:\Program Files\Microsoft Office Servers\15.0\Synchronization Service" `
        + "\UIShell\miisclient.exe") `
    -Credential $farmCredential
```

Start time: 11:42:51 AM\
End time: 12:01:35 PM

### Create and configure search service application

---

**EXT-SQL02 - SQL Server Management Studio**

#### -- Add SharePoint setup account to db_owner role in Usage and Health Data Collection database

```SQL
USE [WSS_Logging]
GO

CREATE USER [EXTRANET\setup-sharepoint]
FOR LOGIN [EXTRANET\setup-sharepoint]

ALTER ROLE [db_owner] ADD MEMBER [EXTRANET\setup-sharepoint]
GO
```

---

#### # Create Search Service Application

**TODO:** Update deployment script to create the Search Index folder

```PowerShell
New-Item `
    -ItemType Directory `
    -Path "D:\Microsoft Office Servers\15.0\Data\Office Server\Search Index"

& '.\Configure SharePoint Search.ps1' -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-sp-crawler**.\
> Expect the previous operation to complete in approximately 12 minutes.

```PowerShell
cls
```

#### # Pause Search Service Application

```PowerShell
Get-SPEnterpriseSearchServiceApplication "Search Service Application" |
    Suspend-SPEnterpriseSearchServiceApplication
```

#### # Configure people search in SharePoint

##### # Grant permissions to default content access account

```PowerShell
$searchApp = Get-SPEnterpriseSearchServiceApplication `
    -Identity "Search Service Application"

$content = New-Object `
    -TypeName Microsoft.Office.Server.Search.Administration.Content `
    -ArgumentList $searchApp

$principal = New-SPClaimsPrincipal `
    -Identity $content.DefaultGatheringAccount `
    -IdentityType WindowsSamAccountName

$userProfileServiceApp = Get-SPServiceApplication `
    -Name "User Profile Service Application"

$security = Get-SPServiceApplicationSecurity `
    -Identity $userProfileServiceApp `
    -Admin

Grant-SPObjectSecurity `
    -Identity $security `
    -Principal $principal `
    -Rights "Retrieve People Data for Search Crawlers"

Set-SPServiceApplicationSecurity `
    -Identity $userProfileServiceApp `
    -ObjectSecurity $security `
    -Admin
```

##### # Create content source for crawling user profiles

```PowerShell
$startAddress = "sps3://client-test.securitasinc.com"

$searchApp = Get-SPEnterpriseSearchServiceApplication `
    -Identity "Search Service Application"

New-SPEnterpriseSearchCrawlContentSource `
    -SearchApplication $searchapp `
    -Type SharePoint `
    -Name "User profiles" `
    -StartAddresses $startAddress
```

#### # Configure search crawl schedules

```PowerShell
$searchApp = Get-SPEnterpriseSearchServiceApplication `
    -Identity "Search Service Application"
```

##### # Enable continuous crawls for "Local SharePoint sites"

```PowerShell
$searchApp = Get-SPEnterpriseSearchServiceApplication `
    -Identity "Search Service Application"

$contentSource = Get-SPEnterpriseSearchCrawlContentSource `
    -SearchApplication $searchApp `
    -Identity "Local SharePoint sites"

Set-SPEnterpriseSearchCrawlContentSource `
    -Identity $contentSource `
    -EnableContinuousCrawls $true

Set-SPEnterpriseSearchCrawlContentSource `
    -Identity $contentSource `
    -ScheduleType Incremental `
    -DailyCrawlSchedule `
    -CrawlScheduleStartDateTime "12:00 AM" `
    -CrawlScheduleRepeatInterval 240 `
    -CrawlScheduleRepeatDuration 1440
```

##### # Configure crawl schedule for "User profiles"

```PowerShell
$contentSource = Get-SPEnterpriseSearchCrawlContentSource `
    -SearchApplication $searchApp `
    -Identity "User profiles"

Set-SPEnterpriseSearchCrawlContentSource `
    -Identity $contentSource `
    -ScheduleType Full `
    -WeeklyCrawlSchedule `
    -CrawlScheduleStartDateTime "11:00 PM" `
    -CrawlScheduleDaysOfWeek Saturday `
    -CrawlScheduleRunEveryInterval 1

Set-SPEnterpriseSearchCrawlContentSource `
    -Identity $contentSource `
    -ScheduleType Incremental `
    -DailyCrawlSchedule `
    -CrawlScheduleStartDateTime "4:00 AM"
```

```PowerShell
cls
```

## # Create and configure Web application

### # Set environment variables

```PowerShell
[Environment]::SetEnvironmentVariable(
  "SECURITAS_CLIENT_PORTAL_URL",
  "http://client-test.securitasinc.com",
  "Machine")

exit
```

> **Important**
>
> Restart PowerShell for environment variables to take effect.

### # Add SecuritasConnect URL to "Local intranet" zone

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-InternetSecurityZoneMapping.ps1 `
    -Zone LocalIntranet `
    -Patterns http://client-test.securitasinc.com,
        https://client-test.securitasinc.com
```

### # Create Web application

```PowerShell
cd C:\Shares\Builds\ClientPortal\4.0.675.0\DeploymentFiles\Scripts

& '.\Create Web Application.ps1' -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-web-client**.\
> Expect the previous operation to complete in approximately 3 minutes.

```PowerShell
cls
```

### # Restore content database or create initial site collections

#### # Remove content database created with Web application

```PowerShell
Remove-SPContentDatabase WSS_Content_SecuritasPortal -Confirm:$false -Force
```

---

**EXT-SQL02 - SQL Server Management Studio**

#### -- Restore database backups from Production

```Console
DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\'
    + 'WSS_Content_SecuritasPortal.bak'

DECLARE @dataFilePath VARCHAR(255) =
  'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'WSS_Content_SecuritasPortal.mdf'

DECLARE @logFilePath VARCHAR(255) =
  'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'WSS_Content_SecuritasPortal_log.LDF'

RESTORE DATABASE WSS_Content_SecuritasPortal
  FROM DISK = @backupFilePath
  WITH FILE = 1,
    MOVE 'WSS_Content_SecuritasPortal' TO @dataFilePath,
    MOVE 'WSS_Content_SecuritasPortal_log' TO @logFilePath,
    NOUNLOAD,
    STATS = 5

GO

DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\'
    + 'WSS_Content_SecuritasPortal2.bak'

DECLARE @dataFilePath VARCHAR(255) =
  'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'WSS_Content_SecuritasPortal2.mdf'

DECLARE @logFilePath VARCHAR(255) =
  'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'WSS_Content_SecuritasPortal2_log.LDF'

RESTORE DATABASE WSS_Content_SecuritasPortal2
  FROM DISK = @backupFilePath
  WITH FILE = 1,
    MOVE 'WSS_Content_SecuritasPortal2' TO @dataFilePath,
    MOVE 'WSS_Content_SecuritasPortal2_log' TO @logFilePath,
    NOUNLOAD,
    STATS = 5

GO
```

##### -- Add SharePoint setup account to db_owner role in restored databases

```SQL
USE [WSS_Content_SecuritasPortal]
GO
CREATE USER [EXTRANET\setup-sharepoint]
FOR LOGIN [EXTRANET\setup-sharepoint]
GO
ALTER ROLE [db_owner]
ADD MEMBER [EXTRANET\setup-sharepoint]
GO

USE [WSS_Content_SecuritasPortal2]
GO
CREATE USER [EXTRANET\setup-sharepoint]
FOR LOGIN [EXTRANET\setup-sharepoint]
GO
ALTER ROLE [db_owner]
ADD MEMBER [EXTRANET\setup-sharepoint]
GO
```

#### -- Set databases to use Simple recovery model

```Console
ALTER DATABASE [WSS_Content_SecuritasPortal]
SET RECOVERY SIMPLE WITH NO_WAIT
GO

ALTER DATABASE [WSS_Content_SecuritasPortal2]
SET RECOVERY SIMPLE WITH NO_WAIT
GO
```

---

> **Note**
>
> Expect the previous operations to complete in approximately 22 minutes.\
> RESTORE DATABASE successfully processed 3720520 pages in 167.635 seconds (173.391 MB/sec).\
> ...\
> RESTORE DATABASE successfully processed 3606878 pages in 838.072 seconds (33.623 MB/sec).

##### Install SecuritasConnect v3.0 solution

(skipped)

##### Test content database

(skipped)

```PowerShell
cls
```

##### # Attach content database

```PowerShell
$stopwatch = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-Stopwatch.ps1

Mount-SPContentDatabase `
    -Name WSS_Content_SecuritasPortal `
    -WebApplication $env:SECURITAS_CLIENT_PORTAL_URL

Mount-SPContentDatabase `
    -Name WSS_Content_SecuritasPortal2 `
    -WebApplication $env:SECURITAS_CLIENT_PORTAL_URL

$stopwatch.Stop()
C:\NotBackedUp\Public\Toolbox\PowerShell\Write-ElapsedTime.ps1 $stopwatch
```

> **Note**
>
> Expect the previous operation to complete in approximately 5-1/2 minutes.

##### Remove SecuritasConnect v3.0 solution

(skipped)

```PowerShell
cls
```

### # Configure machine key for Web application

```PowerShell
cd C:\Shares\Builds\ClientPortal\4.0.675.0\DeploymentFiles\Scripts

& '.\Configure Machine Key.ps1' -Verbose
```

### # Configure object cache user accounts

```PowerShell
& '.\Configure Object Cache User Accounts.ps1' -Verbose

iisreset
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

#### # Specify credentials for accessing trusted forest

```PowerShell
$cred1 = Get-Credential "EXTRANET\s-web-client"

$cred2 = Get-Credential "TECHTOOLBOX\svc-sp-ups"

$peoplePickerCredentials = $cred1, $cred2

& '.\Configure People Picker Forests.ps1' `
    -ServiceCredentials $peoplePickerCredentials `
    -Confirm:$false `
    -Verbose
```

```PowerShell
cls
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

#### Add public URL for HTTPS

#### Add HTTPS binding to site in IIS

```PowerShell
cls
```

### # Enable disk-based caching for Web application

```PowerShell
[Uri] $tempUri = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL

Push-Location ("C:\inetpub\wwwroot\wss\VirtualDirectories\" `
    + $tempUri.Host + "80")

copy web.config "web - Copy.config"

Notepad web.config
```

---

**Web.config**

```XML
    <BlobCache
      location="D:\BlobCache\14"
      path="\.(gif|jpg|jpeg|jpe|jfif|bmp|dib|tif|tiff|themedbmp|themedcss|themedgif|themedjpg|themedpng|ico|png|wdp|hdp|css|js|asf|avi|flv|m4v|mov|mp3|mp4|mpeg|mpg|rm|rmvb|wma|wmv|ogg|ogv|oga|webm|xap)$"
      maxSize="2"
      enabled="true" />
```

---

```Console
cls
Pop-Location
```

### # Configure Web application policy for SharePoint administrators group

```PowerShell
$webAppUrl = $env:SECURITAS_CLIENT_PORTAL_URL
$adminsGroup = "EXTRANET\SharePoint Admins"

$principal = New-SPClaimsPrincipal -Identity $adminsGroup `
    -IdentityType WindowsSecurityGroupName

$claim = $principal.ToEncodedString()

$webApp = Get-SPWebApplication $webAppUrl

$policyRole = $webApp.PolicyRoles.GetSpecialRole(
    [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl)

$policy = $webApp.Policies.Add($claim, $adminsGroup)
$policy.PolicyRoleBindings.Add($policyRole)

$webApp.Update()
```

### Configure SharePoint groups

(skipped -- since database was restored from Production)

### Configure My Site settings in User Profile service application

My Site Host location: **[http://client-test.securitasinc.com/sites/my](http://client-test.securitasinc.com/sites/my)**

## Deploy SecuritasConnect solution

### DEV - Build Visual Studio solution and package SharePoint projects

(skipped)

### Create and configure SecuritasPortal database

---

**EXT-SQL02 - SQL Server Management Studio**

#### -- Restore backup of SecuritasPortal database from Production

```Console
DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\'
    + 'SecuritasPortal.bak'

DECLARE @dataFilePath VARCHAR(255) =
  'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + '_SecuritasPortal.mdf'

DECLARE @logFilePath VARCHAR(255) =
  'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'SecuritasPortal_log.LDF'

RESTORE DATABASE SecuritasPortal
  FROM DISK = @backupFilePath
  WITH FILE = 1,
    MOVE 'SecuritasPortal' TO @dataFilePath,
    MOVE 'SecuritasPortal_log' TO @logFilePath,
    NOUNLOAD,
    STATS = 5

GO
```

#### -- Configure permissions for SecuritasPortal database

```SQL
USE [SecuritasPortal]
GO

CREATE USER [EXTRANET\s-sp-farm] FOR LOGIN [EXTRANET\s-sp-farm]
GO
ALTER ROLE [aspnet_Membership_BasicAccess] ADD MEMBER [EXTRANET\s-sp-farm]
GO
ALTER ROLE [aspnet_Membership_ReportingAccess] ADD MEMBER [EXTRANET\s-sp-farm]
GO
ALTER ROLE [aspnet_Roles_BasicAccess] ADD MEMBER [EXTRANET\s-sp-farm]
GO
ALTER ROLE [aspnet_Roles_ReportingAccess] ADD MEMBER [EXTRANET\s-sp-farm]
GO

CREATE USER [EXTRANET\s-web-client] FOR LOGIN [EXTRANET\s-web-client]
GO
ALTER ROLE [aspnet_Membership_FullAccess] ADD MEMBER [EXTRANET\s-web-client]
GO
ALTER ROLE [aspnet_Profile_BasicAccess] ADD MEMBER [EXTRANET\s-web-client]
GO
ALTER ROLE [aspnet_Roles_BasicAccess] ADD MEMBER [EXTRANET\s-web-client]
GO
ALTER ROLE [aspnet_Roles_ReportingAccess] ADD MEMBER [EXTRANET\s-web-client]
GO
ALTER ROLE [Customer_Reader] ADD MEMBER [EXTRANET\s-web-client]
GO
```

---

### Create Branch Managers domain group and add members

(skipped)

### Create PODS Support domain group and add members

(skipped)

```PowerShell
cls
```

### # Configure logging

```PowerShell
cd C:\Shares\Builds\ClientPortal\4.0.675.0\DeploymentFiles\Scripts

& '.\Add Event Log Sources.ps1' -Verbose
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

### Upgrade core site collections

(skipped)

```PowerShell
cls
```

### # Install SecuritasConnect solutions and activate features

#### # Deploy v4.0 solutions

```PowerShell
& '.\Add Solutions.ps1' -Verbose

& '.\Deploy Solutions.ps1' -Verbose
```

> **Note**
>
> Expect the previous operation to complete in approximately 12 minutes.

```PowerShell
& '.\Activate Features.ps1' -Verbose
```

##### Activate "Securitas - Application Settings" feature

(skipped)

### Import template site content

(skipped)

### Create users in SecuritasPortal database

#### Create users for Securitas clients

(skipped)

#### Create users for Securitas Branch Managers

(skipped)

#### Associate client users to Branch Managers

---

**EXT-SQL02 - SQL Server Management Studio**

```Console
USE SecuritasPortal
GO

UPDATE Customer.BranchManagerAssociatedUsers
SET BranchManagerUserName = 'TECHTOOLBOX\jjameson'
WHERE BranchManagerUserName = 'PNKUS\jjameson'
```

---

```PowerShell
cls
```

### # Configure trusted root authorities in SharePoint

```PowerShell
& '.\Configure Trusted Root Authorities.ps1'
```

### # Configure application settings (e.g. Web service URLs)

```PowerShell
net use \\ICEMAN\Archive /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
Import-Csv "\\ICEMAN\Archive\Clients\Securitas\AppSettings-UAT_2016-10-06.csv" |
    ForEach-Object {
        .\Set-AppSetting.ps1 $_.Key $_.Value $_.Description -Force -Verbose
    }
```

**TODO:** Refine logging in scripts

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7C/F61C88AD4A258360459625CA6FE0C0859D3A9F7C.png)

### Configure SSO credentials for a user

(skipped)

```PowerShell
cls
```

### # Configure C&C landing site

#### # Grant Branch Managers permissions to C&C landing site

```PowerShell
Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

$site = Get-SPSite "$env:SECURITAS_CLIENT_PORTAL_URL/sites/cc"
$group = $site.RootWeb.SiteGroups["Collaboration & Community Visitors"]
$group.AddUser(
    "c:0-.f|securitassqlroleprovider|branch managers",
    $null,
    "Branch Managers",
    $null)

$claim = New-SPClaimsPrincipal -Identity "Branch Managers" `
    -IdentityType WindowsSecurityGroupName

$branchManagersUser = $site.RootWeb.EnsureUser($claim.ToEncodedString())
$group.AddUser($branchManagersUser)
$site.Dispose()
```

#### Hide Search navigation item on C&C landing site

(skipped -- since database was restored from Production)

#### Configure search settings for C&C landing site

(skipped -- since database was restored from Production)

### Configure Google Analytics on SecuritasConnect Web application

Tracking ID: **UA-25899478-2**

### Upgrade C&C site collections

(skipped -- since database was restored from Production)

### Defragment SharePoint databases

> **Note**
>
> Expect the defragmentation job to complete in approximately 2-1/2 hours.

---

**EXT-SQL02 - SQL Server Management Studio**

### -- Shrink log files for content database

```SQL
USE [WSS_Content_SecuritasPortal]
GO
DBCC SHRINKFILE (N'WSS_Content_SecuritasPortal_log' , 0, TRUNCATEONLY)
GO
USE [WSS_Content_SecuritasPortal2]
GO
DBCC SHRINKFILE (N'WSS_Content_SecuritasPortal2_log' , 0, TRUNCATEONLY)
GO
```

---

### Shrink content database

(skipped)

---

**EXT-SQL02 - SQL Server Management Studio**

### -- Change recovery model of content databases from Simple to Full

```Console
ALTER DATABASE [WSS_Content_SecuritasPortal]
SET RECOVERY FULL WITH NO_WAIT
GO

ALTER DATABASE [WSS_Content_SecuritasPortal2]
SET RECOVERY FULL WITH NO_WAIT
GO
```

---

### Add content database and partition Post Orders site collections

(skipped)

### Resume Search Service Application and start a full crawl of all content sources

(skipped)

## Create and configure media website

```PowerShell
cls
```

## # Create and configure C&C site collections

### # Create site collection for a Securitas client

```PowerShell
& '.\Create Client Site Collection.ps1' "Jeremy - Test 2 - Sprint-25"
```

### Apply "Securitas Client Site" template to top-level site

### Modify site title, description, and logo

### Update client site home page

### Create team collaboration site (optional)

### Create blog site (optional)

```PowerShell
cls
```

## # Add Branch Managers domain group to Post Orders template site

```PowerShell
Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

$site = Get-SPSite "$env:SECURITAS_CLIENT_PORTAL_URL/Template-Sites/Post-Orders-en-US"

$group = $site.RootWeb.SiteGroups["Post Orders Template Site (en-US) Visitors"]

$claim = New-SPClaimsPrincipal -Identity "Branch Managers" `
    -IdentityType WindowsSecurityGroupName

$branchManagersUser = $site.RootWeb.EnsureUser($claim.ToEncodedString())
$group.AddUser($branchManagersUser)
$site.Dispose()
```

```PowerShell
cls
```

## # Replace site collection administrators

```PowerShell
$stopwatch = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-Stopwatch.ps1

Function ReplaceSiteCollectionAdministrators(
    $site)
{
    Write-Host `
        "Replacing site collection administrators on site ($($site.Url))..."

    For ($i = 0; $i -lt $site.RootWeb.SiteAdministrators.Count; $i++)
    {
        $siteAdmin = $site.RootWeb.SiteAdministrators[$i]

        Write-Debug "siteAdmin: $($siteAdmin.LoginName)"

        If ($siteAdmin.DisplayName -eq "SEC\SharePoint Admins")
        {
            Write-Verbose "Removing administrator ($($siteAdmin.DisplayName))..."
            $site.RootWeb.SiteAdministrators.Remove($i)
            $i--;
        }
    }

    Write-Debug `
        "Adding SharePoint Admins on site ($($site.Url))..."

    $user = $site.RootWeb.EnsureUser("EXTRANET\SharePoint Admins");
    $user.IsSiteAdmin = $true;
    $user.Update();
}

Get-SPSite -WebApplication $env:SECURITAS_CLIENT_PORTAL_URL -Limit ALL |
    ForEach-Object {
        $site = $_

        Write-Host `
            "Processing site ($($site.Url))..."

        ReplaceSiteCollectionAdministrators $site

        $site.Dispose()
    }

$stopwatch.Stop()
C:\NotBackedUp\Public\Toolbox\PowerShell\Write-ElapsedTime.ps1 $stopwatch
```

> **Note**
>
> Expect the previous operation to complete in approximately 1-1/2 hours.

Install Cloud Portal v2.0

## Installation prerequisites

### Create Cloud Portal service account

---

**EXT-DC01**

```PowerShell
cls
```

#### # Create service account for Cloud Portal Web application

```PowerShell
$displayName = "Service account for Cloud Portal Web application"
$defaultUserName = "s-web-cloud"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@extranet.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=IT,DC=extranet,DC=technologytoolbox,DC=com"

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

## Backup SharePoint 2010 environment

### Backup databases in SharePoint 2010 environment

(Download backup files from PROD to [\\\\ICEMAN\\Archive\\Clients\\Securitas\\Backups](\\ICEMAN\Archive\Clients\Securitas\Backups))

---

**EXT-SQL02**

```PowerShell
cls
```

#### # Copy the backup files to the SQL Server for the SharePoint 2013 farm

```PowerShell
$destination = 'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full'

net use \\ICEMAN\Archive /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
robocopy `
    \\ICEMAN\Archive\Clients\Securitas\Backups `
    $destination `
    WSS_Content_CloudPortal*.bak
```

#### # Rename backup files

```PowerShell
ren `
    ($destination `
        + '\WSS_Content_CloudPortal_backup_2016_09_29_084517_2505600.bak') `
    'WSS_Content_CloudPortal.bak'
```

---

```PowerShell
cls
```

## # Create and configure Cloud Portal Web application

### # Set environment variables

```PowerShell
[Environment]::SetEnvironmentVariable(
  "SECURITAS_CLOUD_PORTAL_URL",
  "http://cloud-test.securitasinc.com",
  "Machine")

exit
```

> **Important**
>
> Restart PowerShell for environment variable to take effect.

**TODO:** Add the following section to the install guide

### # Add Cloud Portal URLs to "Local intranet" zone

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-InternetSecurityZoneMapping.ps1 `
    -Zone LocalIntranet `
    -Patterns http://cloud-test.securitasinc.com,
        https://cloud-test.securitasinc.com
```

### # Copy Cloud Portal build to SharePoint server

```PowerShell
net use \\ICEMAN\Builds /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$build = "2.0.122.0"

$sourcePath = "\\ICEMAN\Builds\Securitas\CloudPortal\$build"
$destPath = "\\EXT-APP02A\Builds\CloudPortal\$build"

robocopy $sourcePath $destPath /E
```

### # Create Web application

```PowerShell
cd C:\Shares\Builds\CloudPortal\2.0.122.0\DeploymentFiles\Scripts

& '.\Create Web Application.ps1' -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-web-cloud**.\
> Expect the previous operation to complete in approximately 1-1/2 minutes.

```PowerShell
cls
```

### # Install third-party SharePoint solutions

```PowerShell
net use \\ICEMAN\Products /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$tempPath = "C:\NotBackedUp\Temp\Boost Solutions"

robocopy `
    "\\ICEMAN\Products\Boost Solutions" `
    $tempPath /E

Push-Location $tempPath

Add-Type -assembly "System.Io.Compression.FileSystem"

$zipFile = Resolve-Path "ListCollectionSetup.zip"

mkdir ".\ListCollectionSetup"
$destination = Resolve-Path "ListCollectionSetup"

[Io.Compression.ZipFile]::ExtractToDirectory($zipFile, $destination)

cd $destination

& ".\Setup.exe"
```

> **Important**
>
> Wait for the installation to complete.

> **Note**
>
> Expect the installation of BoostSolutions List Collection to complete in approximately 25 minutes (since it appears to query Active Directory for each user that has ever accessed the web application).

```Console
cls
Pop-Location

Remove-Item $tempPath -Recurse
```

### # Restore content database or create initial site collections

#### # Restore content database

##### # Remove content database created with Web application

```PowerShell
Remove-SPContentDatabase WSS_Content_CloudPortal -Confirm:$false -Force
```

---

**EXT-SQL02 - SQL Server Management Studio**

##### -- Restore database backup from Production

```Console
DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\'
    + 'WSS_Content_CloudPortal.bak'

DECLARE @dataFilePath VARCHAR(255) =
  'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'WSS_Content_CloudPortal.mdf'

DECLARE @logFilePath VARCHAR(255) =
  'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'WSS_Content_CloudPortal_log.LDF'

RESTORE DATABASE WSS_Content_CloudPortal
  FROM DISK = @backupFilePath
  WITH FILE = 1,
    MOVE 'WSS_Content_CloudPortal' TO @dataFilePath,
    MOVE 'WSS_Content_CloudPortal_log' TO @logFilePath,
    NOUNLOAD,
    STATS = 5

GO
```

##### -- Add SharePoint setup account to db_owner role in restored database

```SQL
USE [WSS_Content_CloudPortal]
GO
CREATE USER [EXTRANET\setup-sharepoint]
FOR LOGIN [EXTRANET\setup-sharepoint]

ALTER ROLE [db_owner] ADD MEMBER [EXTRANET\setup-sharepoint]
GO
```

#### -- Set database to use Simple recovery model

```Console
ALTER DATABASE [WSS_Content_CloudPortal]
SET RECOVERY SIMPLE WITH NO_WAIT
GO
```

---

> **Note**
>
> Expect the previous operation to complete in approximately 39 minutes.\
> RESTORE DATABASE successfully processed 7351620 pages in 2004.379 seconds (28.654 MB/sec).

##### Install Cloud Portal v1.0 solution

(skipped)

##### Test content database

(skipped)

```PowerShell
cls
```

##### # Attach content database

```PowerShell
$stopwatch = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-Stopwatch.ps1

Mount-SPContentDatabase `
    -Name WSS_Content_CloudPortal `
    -WebApplication $env:SECURITAS_CLOUD_PORTAL_URL

$stopwatch.Stop()
C:\NotBackedUp\Public\Toolbox\PowerShell\Write-ElapsedTime.ps1 $stopwatch
```

> **Note**
>
> Expect the previous operation to complete in approximately 4 seconds.

##### Remove Cloud Portal v1.0 solution

(skipped)

```PowerShell
cls
```

### # Configure object cache user accounts

```PowerShell
cd C:\Shares\Builds\CloudPortal\2.0.122.0\DeploymentFiles\Scripts

& '.\Configure Object Cache User Accounts.ps1' -Verbose

iisreset
```

### # Configure People Picker to support searches across one-way trusts

#### # Specify credentials for accessing trusted forests

```PowerShell
$cred1 = Get-Credential "EXTRANET\s-web-cloud"

$cred2 = Get-Credential "TECHTOOLBOX\svc-sp-ups"

$cred3 = Get-Credential "FABRIKAM\s-sp-ups"

& '.\Configure People Picker Forests.ps1' `
    -ServiceCredentials $cred1, $cred2, $cred3 `
    -Confirm:$false `
    -Verbose
```

```PowerShell
cls
```

### # Map Web application to loopback address in Hosts file

```PowerShell
& C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    -IPAddress 127.0.0.1 `
    -Hostnames cloud-test.securitasinc.com `
    -Verbose
```

### # Allow specific host names mapped to 127.0.0.1

```PowerShell
& C:\NotBackedUp\Public\Toolbox\PowerShell\Add-BackConnectionHostNames.ps1 `
    -HostNames cloud-test.securitasinc.com `
    -Verbose
```

### Configure SSL on Internet zone

#### Add public URL for HTTPS

#### Add HTTPS binding to site in IIS

### Enable anonymous access to site

(skipped)

```PowerShell
cls
```

### # Enable disk-based caching for Web application

```PowerShell
[Uri] $tempUri = [Uri] "http://cloud-test.securitasinc.com"

Push-Location ("C:\inetpub\wwwroot\wss\VirtualDirectories\" `
    + $tempUri.Host + "80")

copy web.config "web - Copy.config"

Notepad web.config
```

---

**Web.config**

```XML
    <BlobCache
      location="D:\BlobCache\14"
      path="\.(gif|jpg|jpeg|jpe|jfif|bmp|dib|tif|tiff|themedbmp|themedcss|themedgif|themedjpg|themedpng|ico|png|wdp|hdp|css|js|asf|avi|flv|m4v|mov|mp3|mp4|mpeg|mpg|rm|rmvb|wma|wmv|ogg|ogv|oga|webm|xap)$"
      maxSize="2"
      enabled="true" />
```

---

```Console
cls
Pop-Location
```

### # Configure Web application policy for SharePoint administrators group

```PowerShell
$webAppUrl = $env:SECURITAS_CLOUD_PORTAL_URL
$adminsGroup = "EXTRANET\SharePoint Admins"

$principal = New-SPClaimsPrincipal -Identity $adminsGroup `
    -IdentityType WindowsSecurityGroupName

$claim = $principal.ToEncodedString()

$webApp = Get-SPWebApplication $webAppUrl

$policyRole = $webApp.PolicyRoles.GetSpecialRole(
    [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl)

$policy = $webApp.Policies.Add($claim, $adminsGroup)
$policy.PolicyRoleBindings.Add($policyRole)

$webApp.Update()
```

### Configure SharePoint groups

(skipped)

## Deploy Cloud Portal solution

### DEV - Build Visual Studio solution and package SharePoint projects

(skipped)

---

**EXT-SQL02 - SQL Server Management Studio**

### -- Configure permissions for SecuritasPortal database

```SQL
USE [SecuritasPortal]
GO

CREATE USER [EXTRANET\s-web-cloud] FOR LOGIN [EXTRANET\s-web-cloud]
GO
ALTER ROLE [aspnet_Membership_FullAccess] ADD MEMBER [EXTRANET\s-web-cloud]
GO
ALTER ROLE [aspnet_Profile_BasicAccess] ADD MEMBER [EXTRANET\s-web-cloud]
GO
ALTER ROLE [aspnet_Roles_BasicAccess] ADD MEMBER [EXTRANET\s-web-cloud]
GO
ALTER ROLE [aspnet_Roles_ReportingAccess] ADD MEMBER [EXTRANET\s-web-cloud]
GO
ALTER ROLE [Customer_Provisioner] ADD MEMBER [EXTRANET\s-web-cloud]
GO
ALTER ROLE [Customer_Reader] ADD MEMBER [EXTRANET\s-web-cloud]
GO
```

---

```PowerShell
cls
```

### # Configure logging

```PowerShell
& '.\Add Event Log Sources.ps1' -Verbose
```

### Upgrade main site collection

(skipped)

```PowerShell
cls
```

### # Install Cloud Portal solutions and activate features

#### # Deploy v2.0 solutions

```PowerShell
& '.\Add Solutions.ps1' -Verbose

& '.\Deploy Solutions.ps1' -Verbose
```

```PowerShell
cls
& '.\Activate Features.ps1' -Verbose
```

### Create and configure custom sign-in page

#### Create custom sign-in page

(skipped)

```PowerShell
cls
```

#### # Configure custom sign-in page on Web application

```PowerShell
Set-SPWebApplication `
    -Identity $env:SECURITAS_CLOUD_PORTAL_URL `
    -Zone Default `
    -SignInRedirectURL "/Pages/Sign-In.aspx"
```

### Configure search settings for Cloud Portal

#### Hide Search navigation item on Cloud Portal top-level site

(skipped -- since this is already hidden in PROD)

#### Configure search settings for Cloud Portal top-level site

(skipped)

### Configure redirect for single-site users

(skipped)

### Configure "Online Provisioning"

(skipped)

### Configure Google Analytics on Cloud Portal Web application

Tracking ID: **UA-25899478-3**

### Upgrade C&C site collections

(skipped)

### Defragment SharePoint databases

---

**EXT-SQL02 - SQL Server Management Studio**

### -- Change recovery model of content database from Simple to Full

```Console
ALTER DATABASE [WSS_Content_CloudPortal]
SET RECOVERY FULL WITH NO_WAIT
GO
```

---

### Resume Search Service Application and start full crawl on all content sources

(skipped)

### Remove obsolete web app policies

For each web application, delete the **Search Crawling Account** corresponding to **EXTRANET\\s-sp-serviceapp**.

```PowerShell
cls
```

## # Create and configure C&C site collections

### # Create "Collaboration & Community" site collection

```PowerShell
& '.\Create Client Site Collection.ps1' "Jeremy - Test 2 - Sprint-20"
```

### Apply "Securitas Client Site" template to top-level site

### Modify site title, description, and logo

### Update C&C site home page

### Create team collaboration site (optional)

### Create blog site (optional)

```Console
cls
```

# Install Employee Portal

## # Extend SecuritasConnect and Cloud Portal web applications

### # Copy Employee Portal build to SharePoint server

```PowerShell
net use \\ICEMAN\Builds /USER:PNKUS\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$build = "1.0.29.0"

$sourcePath = "\\ICEMAN\Builds\Securitas\EmployeePortal\$build"
$destPath = "\\EXT-APP02A\Builds\EmployeePortal\$build"

robocopy $sourcePath $destPath /E
```

### # Extend web applications to Intranet zone

```PowerShell
cd 'C:\Shares\Builds\EmployeePortal\1.0.29.0\Deployment Files\Scripts'

& '.\Extend Web Applications.ps1' -SecureSocketsLayer -Confirm:$false -Verbose
```

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

### Download Web Platform Installer

(skipped)

```PowerShell
cls
```

### # Install Web Deploy

```PowerShell
net use \\ICEMAN\Products /USER:PNKUS\jjameson
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

### Restart computer (if not restarted since installing .NET Framework 4.5)

(skipped)

### Ensure ASP.NET v4.0 ISAPI filters are enabled

(skipped -- since the ISAPI filters were already enabled)

```PowerShell
cls
```

## # Install Employee Portal

### # Add Employee Portal URLs to "Local intranet" zone

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-InternetSecurityZoneMapping.ps1 `
    -Zone LocalIntranet `
    -Patterns http://employee-test.securitasinc.com,
        https://employee-test.securitasinc.com
```

### Create Employee Portal SharePoint site

(skipped)

```PowerShell
cls
```

### # Create Employee Portal website

#### # Create Employee Portal website on SharePoint Central Administration server

```PowerShell
cd 'C:\Shares\Builds\EmployeePortal\1.0.29.0\Deployment Files\Scripts'

& '.\Configure Employee Portal Website.ps1' `
    -SiteName employee-test.securitasinc.com `
    -Confirm:$false `
    -Verbose
```

#### Configure SSL bindings on Employee Portal website

```PowerShell
cls
```

#### # Create Employee Portal website on other web servers in farm

```PowerShell
Push-Location "C:\Program Files\IIS\Microsoft Web Deploy V3"

$websiteName = "employee-test.securitasinc.com"

.\msdeploy.exe -verb:sync `
    -source:apppoolconfig="$websiteName" `
    -dest:apppoolconfig="$websiteName"`,computername=EXT-WEB02A

.\msdeploy.exe -verb:sync `
    -source:apppoolconfig="$websiteName" `
    -dest:apppoolconfig="$websiteName"`,computername=EXT-WEB02B

.\msdeploy.exe -verb:sync `
    -source:apphostconfig="$websiteName" `
    -dest:apphostconfig="$websiteName"`,computername=EXT-WEB02A

.\msdeploy.exe -verb:sync `
    -source:apphostconfig="$websiteName" `
    -dest:apphostconfig="$websiteName"`,computername=EXT-WEB02B

Pop-Location
```

```PowerShell
cls
```

### # Deploy Employee Portal website

#### # Deploy Employee Portal website on SharePoint Central Administration server

```PowerShell
Push-Location C:\Shares\Builds\EmployeePortal\1.0.29.0\Release\_PublishedWebsites\Web_Package

attrib -r .\Web.SetParameters.xml

Notepad .\Web.SetParameters.xml
```

---

**Web.SetParameters.xml**

```XML
<?xml version="1.0" encoding="utf-8"?>
<parameters>
  <setParameter
    name="IIS Web Application Name"
    value="employee-test.securitasinc.com" />
  <setParameter
    name="SecuritasPortal-Web.config Connection String"
    value="Server=EXT-SQL02; Database=SecuritasPortal; Integrated Security=true" />
  <setParameter
    name="SecuritasPortalDbContext-Web.config Connection String"
    value="Data Source=EXT-SQL02; Initial Catalog=SecuritasPortal; Integrated Security=True; MultipleActiveResultSets=True;" />
</parameters>
```

---

```Console
.\Web.deploy.cmd /y
```

```Console
cls
Pop-Location
```

#### # Configure application settings and web service URLs

```PowerShell
Notepad C:\inetpub\wwwroot\employee-test.securitasinc.com\Web.config
```

1. Set the value of the **Environment** application setting to **Test**.
2. Set the value of the **GoogleAnalytics.TrackingId** application setting to **UA-25899478-4**.
3. In the **`<errorMail>`** element, change the **smtpServer** attribute to **smtp-test.technologytoolbox.com**.
4. Replace all instances of **[http://client2-local](http://client2-local)** with **[https://client2-test](https://client2-test)**.
5. Replace all instances of **[http://cloud2-local](http://cloud2-local)** with **[https://cloud2-test](https://cloud2-test)**.
6. Replace all instances of **TransportCredentialOnly** with **Transport**.

```PowerShell
cls
```

#### # Deploy Employee Portal website content to other web servers in farm

```PowerShell
Push-Location "C:\Program Files\IIS\Microsoft Web Deploy V3"

$websiteName = "employee-test.securitasinc.com"

.\msdeploy.exe -verb:sync `
    -source:contentPath="C:\inetpub\wwwroot\$websiteName" `
    -dest:contentPath="C:\inetpub\wwwroot\$websiteName"`,computername=EXT-WEB02A

.\msdeploy.exe -verb:sync `
    -source:contentPath="C:\inetpub\wwwroot\$websiteName" `
    -dest:contentPath="C:\inetpub\wwwroot\$websiteName"`,computername=EXT-WEB02B

Pop-Location
```

---

**EXT-SQL02 - SQL Server Management Studio**

### -- Configure database logins and permissions for Employee Portal

```SQL
USE [master]
GO
CREATE LOGIN [EXTRANET\EXT-APP02A$]
FROM WINDOWS
WITH DEFAULT_DATABASE=[master]
GO
CREATE LOGIN [EXTRANET\EXT-WEB02A$]
FROM WINDOWS
WITH DEFAULT_DATABASE=[master]
GO
CREATE LOGIN [EXTRANET\EXT-WEB02B$]
FROM WINDOWS
WITH DEFAULT_DATABASE=[master]
GO

USE [SecuritasPortal]
GO
CREATE USER [EXTRANET\EXT-APP02A$] FOR LOGIN [EXTRANET\EXT-APP02A$]
GO
CREATE USER [EXTRANET\EXT-WEB02A$] FOR LOGIN [EXTRANET\EXT-WEB02A$]
GO
CREATE USER [EXTRANET\EXT-WEB02B$] FOR LOGIN [EXTRANET\EXT-WEB02B$]
GO
EXEC sp_addrolemember N'Employee_FullAccess', N'EXTRANET\EXT-APP02A$'
GO
EXEC sp_addrolemember N'Employee_FullAccess', N'EXTRANET\EXT-WEB02A$'
GO
EXEC sp_addrolemember N'Employee_FullAccess', N'EXTRANET\EXT-WEB02B$'
GO
```

---

```PowerShell
cls
```

### # Grant PNKCAN and PNKUS users permissions on Cloud Portal site

```PowerShell
Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

$supportedDomains = ("FABRIKAM", "TECHTOOLBOX")

$web = Get-SPWeb "$env:SECURITAS_CLOUD_PORTAL_URL/"

$group = $web.Groups["Cloud Portal Visitors"]

$supportedDomains |
    ForEach-Object {
        $claim = New-SPClaimsPrincipal `
            -Identity "$_\Domain Users" `
            -IdentityType WindowsSecurityGroupName

        $user = $web.EnsureUser($claim.ToEncodedString())
        $group.AddUser($user)
    }

$web.Dispose()

$web = Get-SPWeb "$env:SECURITAS_CLOUD_PORTAL_URL/sites/Employee-Portal"

$group = $web.SiteGroups["Viewers"]

$supportedDomains |
    ForEach-Object {
        $claim = New-SPClaimsPrincipal `
            -Identity "$_\Domain Users" `
            -IdentityType WindowsSecurityGroupName

        $user = $web.EnsureUser($claim.ToEncodedString())
        $group.AddUser($user)
    }

$web.Dispose()

$web = Get-SPWeb "$env:SECURITAS_CLOUD_PORTAL_URL/sites/Employee-Portal/Profiles"

$list = $web.Lists["Profile Pictures"]

$contributeRole = $web.RoleDefinitions['Contribute']

$supportedDomains |
    ForEach-Object {
        $domainUsers = $web.EnsureUser($_ + '\Domain Users')

        $assignment = New-Object Microsoft.SharePoint.SPRoleAssignment(
            $domainUsers)

        $assignment.RoleDefinitionBindings.Add($contributeRole)
        $list.RoleAssignments.Add($assignment)
    }

$web.Dispose()
```

### Replace absolute URLs in "User Sites" list

(skipped)

### Install additional service packs and updates

```PowerShell
cls
```

### # Map Employee Portal URL to loopback address in Hosts file

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    127.0.0.1 employee-test.securitasinc.com
```

### # Allow specific host names mapped to 127.0.0.1

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-BackConnectionHostnames.ps1 `
    employee-test.securitasinc.com
```

```PowerShell
cls
```

### # Resume Search Service Application and start full crawl on all content sources

```PowerShell
Get-SPEnterpriseSearchServiceApplication "Search Service Application" |
    Resume-SPEnterpriseSearchServiceApplication

Get-SPEnterpriseSearchServiceApplication "Search Service Application" |
    Get-SPEnterpriseSearchCrawlContentSource |
    ForEach-Object { $_.StartFullCrawl() }
```

> **Note**
>
> Expect the crawl to complete in approximately 4 hours and 40 minutes.

```PowerShell
cls
```

## # Clean up WinSxS folder

```PowerShell
Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase
```

## Disable setup accounts

---

**EXT-DC01**

```PowerShell
Disable-ADAccount -Identity setup-sharepoint
Disable-ADAccount -Identity setup-sql
```

---

## Upgrade SecuritasConnect to "v4.0 Sprint-26" release

### # Copy new build from TFS drop location

```PowerShell
net use \\ICEMAN\Builds /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$newBuild = "4.0.677.0"

$sourcePath = "\\ICEMAN\Builds\Securitas\ClientPortal\$newBuild"
$destPath = "C:\Shares\Builds\ClientPortal\$newBuild"

robocopy $sourcePath $destPath /E
```

### # Remove previous versions of SecuritasConnect WSPs

```PowerShell
$oldBuild = "4.0.675.0"

Push-Location ("C:\Shares\Builds\ClientPortal\$oldBuild" `
    + "\DeploymentFiles\Scripts")

& '.\Deactivate Features.ps1' -Verbose

& '.\Retract Solutions.ps1' -Verbose

& '.\Delete Solutions.ps1' -Verbose

Pop-Location
```

```PowerShell
cls
```

### # Install new versions of SecuritasConnect WSPs

```PowerShell
Push-Location ("C:\Shares\Builds\ClientPortal\$newBuild" `
    + "\DeploymentFiles\Scripts")

& '.\Add Solutions.ps1' -Verbose

& '.\Deploy Solutions.ps1' -Verbose

& '.\Activate Features.ps1' -Verbose

Pop-Location
```

```PowerShell
cls
```

### # Configure application settings for TEKWave integration

```PowerShell
Start-Process "http://client-test.securitasinc.com"
```

---

**EXT-SQL02 - SQL Server Management Studio**

### -- Configure TEKWave in SecuritasPortal database

```SQL
USE [SecuritasPortal]
GO
```

#### -- Add TEKWave services

```Console
SET IDENTITY_INSERT Customer.Services ON

INSERT INTO Customer.Services
(
    ServiceId
    , ServiceName
    , Description
)
VALUES
(
    9
    , 'TEKWave - Commercial'
    , 'Visitor Management - Commercial & Logistics'
)

INSERT INTO Customer.Services
(
    ServiceId
    , ServiceName
    , Description
)
VALUES
(
    10
    , 'TEKWave - Community'
    , 'Visitor Management - Community'
)

SET IDENTITY_INSERT Customer.Services OFF
GO
```

#### -- Remove CapSure from all sites

```SQL
DELETE SiteServices
FROM
    Customer.SiteServices
    INNER JOIN Customer.Services
    ON SiteServices.ServiceId = Services.ServiceId
WHERE
    Services.ServiceName = 'CapSure'
```

#### -- Add TEKWave to "ABC Company" sites

```SQL
INSERT INTO Customer.SiteServices
(
    SiteId
    , ServiceId
)
SELECT
    SiteId
    , Services.ServiceId
FROM
    Customer.Sites
    INNER JOIN Customer.Clients
    ON Sites.ClientId = Clients.ClientId
    INNER JOIN Customer.Services
    ON Services.ServiceName = 'TEKWave - Commercial'
WHERE
    Clients.ClientName = 'ABC Company'
```

---

### Edit user profiles to add credentials for TEKWave

```PowerShell
cls
```

### # Delete old build

```PowerShell
Remove-Item C:\Shares\Builds\ClientPortal\4.0.675.0 -Recurse -Force
```

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

## Issue - Error accessing SharePoint sites (e.g. http://client-test.securitasinc.com)

Log Name:      Application\
Source:        ASP.NET 4.0.30319.0\
Date:          4/19/2017 5:56:51 PM\
Event ID:      1325\
Task Category: None\
Level:         Error\
Keywords:      Classic\
User:          N/A\
Computer:      EXT-APP02A.extranet.technologytoolbox.com\
Description:\
An unhandled exception occurred and the process was terminated.

Application ID: /LM/W3SVC/762047535/ROOT

Process ID: 6000

Exception: System.IO.FileLoadException

Message: Loading this assembly would produce a different grant set from other instances. (Exception from HRESULT: 0x80131401)

StackTrace:    at System.Linq.Enumerable.Sum(IEnumerable`1 source)\
   at System.Web.Caching.SRefMultiple.get_ApproximateSize()\
   at System.Web.Caching.CacheMemorySizePressure.GetCurrentPressure()\
   at System.Web.Caching.CacheMemoryPressure.Update()\
   at System.Web.Caching.CacheCommon.CacheManagerThread(Int32 minPercent)\
   at System.Threading.ExecutionContext.RunInternal(ExecutionContext executionContext, ContextCallback callback, Object state, Boolean preserveSyncCtx)\
   at System.Threading.ExecutionContext.Run(ExecutionContext executionContext, ContextCallback callback, Object state, Boolean preserveSyncCtx)\
   at System.Threading.TimerQueueTimer.CallCallback()\
   at System.Threading.TimerQueueTimer.Fire()\
   at System.Threading.TimerQueue.FireNextTimers()

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

```PowerShell
cls
```

#### # Install SCOM agent without Application Performance Monitoring (APM)

```PowerShell
net use \\TT-FS01.corp.technologytoolbox.com\IPC$ /USER:TECHTOOLBOX\jjameson

$msiPath = "\\TT-FS01.corp.technologytoolbox.com\Products\Microsoft" `
```

    + "\\System Center 2016\\SCOM\\agent\\AMD64\\MOMAgent.msi"

```PowerShell
msiexec.exe /i $msiPath `
    MANAGEMENT_GROUP=HQ `
    MANAGEMENT_SERVER_DNS=TT-SCOM01 `
    ACTIONS_USE_COMPUTER_ACCOUNT=1 `
    NOAPM=1
```

#### Approve manual agent install in Operations Manager

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
$vmName = "EXT-APP02A"

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

**TODO:**

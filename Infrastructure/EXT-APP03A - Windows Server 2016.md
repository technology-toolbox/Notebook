# EXT-APP03A

Monday, March 26, 2018
4:03 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

Install SecuritasConnect v4.0

## Deploy and configure server infrastructure

### Install Windows Server 2012 R2

---

**FOOBAR11** - Run as administrator

```PowerShell
cls
```

#### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "EXT-APP03A"
$vmPath = "E:\NotBackedUp\VMs\$vmName"
$vhdPath = "$vmPath\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 45GB `
    -MemoryStartupBytes 12GB `
    -SwitchName "Embedded Team Switch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 4

Start-VM -ComputerName $vmHost -Name $vmName
```

---

#### Install custom Windows Server 2012 R2 image

- On the **Task Sequence** step, select **Windows Server 2012 R2** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **EXT-APP03A**.
  - Select **Join a workgroup**.
  - In the **Workgroup** box, type **WORKGROUP**.
  - Click **Next**.
- On the **Applications** step, do not select any applications, and click **Next**.

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

### Login as .\\foo

### # Copy Toolbox content

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$source = "\\TT-FS01\Public\Toolbox"
$destination = "C:\NotBackedUp\Public\Toolbox"

robocopy $source $destination /E /XD "Microsoft SDKs" /MIR
```

### # Set MaxPatchCacheSize to 0 (recommended)

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

### # Enable performance counters for Server Manager

```PowerShell
$taskName = "\Microsoft\Windows\PLA\Server Manager Performance Monitor"

Enable-ScheduledTask -TaskName $taskName

logman start "Server Manager Performance Monitor"
```

---

**FOOBAR11** - Run as administrator

```PowerShell
cls
```

### # Set first boot device to hard drive

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "EXT-APP03A"

$vmHardDiskDrive = Get-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName |
    where { $_.ControllerType -eq "SCSI" `
        -and $_.ControllerNumber -eq 0 `
        -and $_.ControllerLocation -eq 0 }

Set-VMFirmware `
    -ComputerName $vmHost `
    -VMName $vmName `
    -FirstBootDevice $vmHardDiskDrive
```

---

```PowerShell
cls
```

### # Configure networking

```PowerShell
$interfaceAlias = "Extranet-20"
```

#### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Start-Sleep -Seconds 5

ping TT-FS01 -f -l 8900
```

#### Configure static IP address

---

**FOOBAR11** - Run as administrator

```PowerShell
cls
```

##### # Configure static IP address using VMM

```PowerShell
$vmName = "EXT-APP03A"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Extranet-20 VM Network"
$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"
$ipPool = Get-SCStaticIPAddressPool -Name "Extranet-20 Address Pool"

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

### Configure storage

| **Disk** | **Drive Letter** | **Volume Size** | **Allocation Unit Size** | **Volume Label** |
| -------- | ---------------- | --------------- | ------------------------ | ---------------- |
| 0        | C:               | 45 GB           | 4K                       | OSDisk           |
| 1        | D:               | 40 GB           | 4K                       | Data01           |
| 2        | L:               | 20 GB           | 4K                       | Log01            |

---

**FOOBAR11** - Run as administrator

```PowerShell
cls
```

#### # Configure storage for the SQL Server

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "EXT-APP03A"
$vmPath = "E:\NotBackedUp\VMs\$vmName"
```

##### # Add "Data01" VHD

```PowerShell
$vhdPath = $vmPath + "\Virtual Hard Disks\$vmName" + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 40GB
Add-VMHardDiskDrive `
  -ComputerName $vmHost `
  -VMName $vmName `
  -Path $vhdPath `
  -ControllerType SCSI
```

##### # Add "Log01" VHD

```PowerShell
$vhdPath = $vmPath + "\Virtual Hard Disks\$vmName" + "_Log01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 20GB
Add-VMHardDiskDrive `
  -ComputerName $vmHost `
  -VMName $vmName `
  -Path $vhdPath `
  -ControllerType SCSI
```

---

```PowerShell
cls
```

#### # Initialize disks and format volumes

##### # Format Data01 drive

```PowerShell
Get-Disk 1 |
  Initialize-Disk -PartitionStyle GPT -PassThru |
  New-Partition -DriveLetter D -UseMaximumSize |
  Format-Volume `
    -FileSystem NTFS `
    -NewFileSystemLabel "Data01" `
    -Confirm:$false
```

##### # Format Log01 drive

```PowerShell
Get-Disk 2 |
  Initialize-Disk -PartitionStyle GPT -PassThru |
  New-Partition -DriveLetter L -UseMaximumSize |
  Format-Volume `
    -FileSystem NTFS `
    -NewFileSystemLabel "Log01" `
    -Confirm:$false
```

### # Join member server to domain

```PowerShell
Add-Computer `
    -DomainName extranet.technologytoolbox.com `
    -Credential (Get-Credential EXTRANET\jjameson-admin) `
    -Restart
```

---

**EXT-DC08** - Run as domain administrator

```PowerShell
cls
```

#### # Move computer to different OU

```PowerShell
$computerName = "EXT-APP03A"

$targetPath = ("OU=SharePoint Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=extranet,DC=technologytoolbox,DC=com")

Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath
```

### # Configure Windows Update

#### # Add machine to security group for Windows Update schedule

```PowerShell
$domainGroupName = "Windows Update - Slot 1"

Add-ADGroupMember -Identity $domainGroupName -Members ($computerName + '$')
```

---

### Install latest service pack and updates

### Create service accounts

---

**EXT-DC01** - Run as domain administrator

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

```PowerShell
cls
```

## # Install and configure SharePoint Server 2013

### # Temporarily enable firewall rule to allow files to be copied to server

```PowerShell
Enable-NetFirewallRule -DisplayName "File and Printer Sharing (SMB-in)"
```

### Download SharePoint 2013 prerequisites to file share

(skipped - since this was completed previously)

```PowerShell
cls
```

### # Install SharePoint 2013 prerequisites on farm servers

#### # Add SQL Server administrators domain group to local Administrators group

```PowerShell
$domain = "EXTRANET"
$groupName = "SharePoint Admins"

([ADSI]"WinNT://./Administrators,group").Add(
    "WinNT://$domain/$groupName,group")
```

---

**EXT-DC08** - Run as domain administrator

```PowerShell
cls
```

##### # Enable setup account for SharePoint

```PowerShell
Enable-ADAccount -Identity setup-sharepoint
```

---

> **Important**
>
> Login as **EXTRANET\\setup-sharepoint** to install SharePoint.

---

**FOOBAR11** - Run as administrator

```PowerShell
cls
```

#### # Mount SharePoint Server 2013 installation media

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "EXT-APP03A"
$isoName = "en_sharepoint_server_2013_with_sp1_x64_dvd_3823428.iso"
```

##### # Add virtual DVD drive

```PowerShell
Add-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName
```

##### # Refresh virtual machine in VMM

```PowerShell
Read-SCVirtualMachine -VM $vmName
```

##### # Mount installation media in virtual DVD drive

```PowerShell
$iso = Get-SCISO | where { $_.Name -eq $isoName }

Get-SCVirtualDVDDrive -VM $vmName |
    Set-SCVirtualDVDDrive -ISO $iso -Link
```

#### # Copy SharePoint Server 2013 prerequisite files to SharePoint server

```PowerShell
$source = "\\TT-FS01\Products\Microsoft\SharePoint 2013" `
    + "\PrerequisiteInstallerFiles_SP1"

$destination = '\\EXT-APP03A.extranet.technologytoolbox.com' `
    + '\C$\NotBackedUp\Temp\PrerequisiteInstallerFiles_SP1'

robocopy $source $destination /E
```

---

#### # Install SharePoint Server 2013 prerequisites

```PowerShell
$prereqPath = "C:\NotBackedUp\Temp\PrerequisiteInstallerFiles_SP1"

& E:\PrerequisiteInstaller.exe `
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
& E:\setup.exe
```

> **Important**
>
> Wait for the installation to complete.

---

**FOOBAR8** - Run as administrator

```PowerShell
cls
```

#### # Dismount SharePoint Server 2013 installation media

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "EXT-APP03A"

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

### Install Cumulative Update for SharePoint Server 2013

---

**FOOBAR11** - Run as administrator

```PowerShell
cls
```

#### # Download update

```PowerShell
$patch = "15.0.4833.1000 - SharePoint 2013 June 2016 CU"

$source = ("\\TT-FS01\Products\Microsoft\SharePoint 2013" `
    + "\Patches\$patch")

$destination = "\\EXT-APP03A.extranet.technologytoolbox.com" `
    + "\C`$\NotBackedUp\Temp\$patch"

robocopy $source $destination /E
```

---

```PowerShell
cls
```

#### # Install update

```PowerShell
$patch = "15.0.4833.1000 - SharePoint 2013 June 2016 CU"

& "C:\NotBackedUp\Temp\$patch\*.exe"
```

> **Important**
>
> Wait for the update to be installed.

```Console
cls
Remove-Item "C:\NotBackedUp\Temp\$patch" -Recurse
```

### # Install Cumulative Update for AppFabric 1.1

---

**FOOBAR11** - Run as administrator

```PowerShell
cls
```

#### # Download update

```PowerShell
$patch = "Cumulative Update 7"

$source = ("\\TT-FS01\Products\Microsoft\AppFabric 1.1" `
    + "\Patches\$patch")

$destination = "\\EXT-APP03A.extranet.technologytoolbox.com" `
    + "\C`$\NotBackedUp\Temp\$patch"

robocopy $source $destination /E
```

---

```PowerShell
cls
```

#### # Install update

```PowerShell
$patch = "Cumulative Update 7"

& "C:\NotBackedUp\Temp\$patch\*.exe"
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

File - **DistributedCacheService.exe.config**

```XML
  <appSettings>
    <add key="backgroundGC" value="true"/>
  </appSettings>
```

---

## Install and configure additional software

### Install Prince on front-end Web servers

```PowerShell
cls
```

### # Disable firewall rule previously enabled to allow files to be copied to server

```PowerShell
Disable-NetFirewallRule -DisplayName "File and Printer Sharing (SMB-in)"
```

### Install additional service packs and updates

> **Important**
>
> Wait for the updates to be installed and restart the server (if necessary).

## Create and configure SharePoint farm

---

**SQL Server Management Studio** - Database Engine - **EXT-SQL03**

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

```PowerShell
cls
```

### # Copy SecuritasConnect build to SharePoint server

#### # Create file share for builds

```PowerShell
$buildsPath = "D:\Shares\Builds"

New-Item -ItemType Directory -Path $buildsPath

New-SmbShare `
  -Name Builds `
  -Path $buildsPath `
  -CachingMode None `
  -ChangeAccess Everyone

New-Item -ItemType Directory -Path "$buildsPath\ClientPortal"
```

---

**FOOBAR11** - Run as administrator

```PowerShell
cls
```

#### # Copy build to SharePoint server

```PowerShell
$build = "4.0.701.0"

$source = "\\TT-FS01\Builds\Securitas\ClientPortal\$build"
$destination = "\\EXT-APP03A.extranet.technologytoolbox.com\Builds" `
    + "\ClientPortal\$build"

robocopy $source $destination /E /NP
```

---

```PowerShell
cls
```

#### # Create SharePoint farm

```PowerShell
cd D:\Shares\Builds\ClientPortal\4.0.701.0\DeploymentFiles\Scripts

$currentUser = whoami

If ($currentUser -eq "EXTRANET\setup-sharepoint")
{
    & '.\Create Farm.ps1' `
        -DatabaseServer EXT-SQL03 `
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
> Expect the previous operation to complete in approximately 12 minutes.

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
    where {$_.WebApplication -like "SPAdministrationWebApplication"} |
    Add-SPShellAdmin $adminsGroup
```

```PowerShell
cls
```

### # Grant permissions on DCOM applications for SharePoint

```PowerShell
cd D:\Shares\Builds\ClientPortal\4.0.701.0\DeploymentFiles\Scripts

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
    where { $_.IsAdministrationWebApplication -eq $true }

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

**EXT-WAC02A** - Run as administrator

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    -IPAddress 10.1.20.151 `
    -Hostnames EXT-APP03A, client-test.securitasinc.com
```

---

## Backup SharePoint 2010 environment

### Backup databases in SharePoint 2010 environment

(Download backup files from PROD to [\\\\TT-FS01\\Archive\\Clients\\Securitas\\Backups](\\TT-FS01\Archive\Clients\Securitas\Backups))

#### Copy backup files to SQL Server for SharePoint 2013 farm

---

**EXT-SQL03** - Run as administrator

```PowerShell
cls
```

##### # Temporarily enable firewall rule to allow files to be copied to server

```PowerShell
Enable-NetFirewallRule -DisplayName "File and Printer Sharing (SMB-in)"
```

---

---

**FOOBAR11** - Run as administrator

```PowerShell
cls
```

##### # Copy backup files

```PowerShell
$source = "\\TT-FS01\Archive\Clients\Securitas\Backups"
$destination = "\\EXT-SQL03.extranet.technologytoolbox.com" `
    + "\Z$\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full"

$filter = "*2018_03_25*"

robocopy $source $destination $filter /XF "WSS_Content_CloudPortal_*"
```

---

---

**EXT-SQL03** - Run as administrator

```PowerShell
cls
```

##### # Disable firewall rule previously enabled to allow files to be copied to server

```PowerShell
Disable-NetFirewallRule -DisplayName "File and Printer Sharing (SMB-in)"
```

#### # Rename backup files

```PowerShell
Push-Location "Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full"

ren `
    ManagedMetadataService_backup_2018_03_25_000009_9469973.bak `
    ManagedMetadataService.bak

ren `
    SecuritasPortal_backup_2018_03_25_000010_0095019.bak `
    SecuritasPortal.bak

ren `
    UserProfileService_Profile_backup_2018_03_25_000009_9627340.bak `
    UserProfileService_Profile.bak

ren `
    UserProfileService_Social_backup_2018_03_25_000009_9782717.bak `
    UserProfileService_Social.bak

ren `
    UserProfileService_Sync_backup_2018_03_25_000009_9627340.bak `
    UserProfileService_Sync.bak

ren `
    WSS_Content_SecuritasPortal_backup_2018_03_25_000009_9939327.bak `
    WSS_Content_SecuritasPortal.bak

ren `
    WSS_Content_SecuritasPortal2_backup_2018_03_25_000010_0095019.bak `
    WSS_Content_SecuritasPortal2.bak

Pop-Location
```

---

### Export User Profile Synchronization encryption key

---

**258521-VM4** - Command Prompt

#### REM Export MIIS encryption key

```Console
cd "C:\Program Files\Microsoft Office Servers\15.0\Synchronization Service\Bin\"

miiskmu.exe /e C:\Users\%USERNAME%\Desktop\miiskeys-1.bin ^
    /u:SEC\s-sp-farm *
```

> **Note**
>
> When prompted for the password, type the password for the SharePoint farm service account.

---

---

**FOOBAR11** - Run as administrator

```PowerShell
cls
```

#### # Copy MIIS encryption key file to SharePoint 2013 server

```PowerShell
$source = "\\TT-FS01\Archive\Clients\Securitas\Backups\miiskeys-1.bin"
$destination = "\\EXT-APP03A.extranet.technologytoolbox.com" `
    + "\C`$\Users\setup-sharepoint\Desktop"

Copy-Item $source $destination
```

---

```PowerShell
cls
```

## # Configure SharePoint services and service applications

### # Change service account for Distributed Cache

```PowerShell
cd D:\Shares\Builds\ClientPortal\4.0.701.0\DeploymentFiles\Scripts

& '.\Configure Distributed Cache.ps1' -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-sp-serviceapp**.\
> Expect the previous operation to complete in approximately 7-8 minutes.

#### Issue

Service account was changed on EXT-APP03A, but not on EXT-WEB03A nor EXT-WEB03B

```Text
PS D:\Shares\Builds\ClientPortal\4.0.701.0\DeploymentFiles\Scripts> Use-CacheCluster
PS D:\Shares\Builds\ClientPortal\4.0.701.0\DeploymentFiles\Scripts> Get-CacheHost
Get-CacheHost : ErrorCode<ERRCAdmin039>:SubStatus<ES0001>:Cache host EXT-WEB03A.extranet.technologytoolbox.com is not reachable.
At line:1 char:1
+ Get-CacheHost
+ ~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [Get-AFCacheHostStatus], DataCacheException
    + FullyQualifiedErrorId : ERRCAdmin039,Microsoft.ApplicationServer.Caching.Commands.GetAFCacheHostStatusCommand

Get-CacheHost : ErrorCode<ERRCAdmin039>:SubStatus<ES0001>:Cache host EXT-WEB03B.extranet.technologytoolbox.com is not reachable.
At line:1 char:1
+ Get-CacheHost
+ ~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [Get-AFCacheHostStatus], DataCacheException
    + FullyQualifiedErrorId : ERRCAdmin039,Microsoft.ApplicationServer.Caching.Commands.GetAFCacheHostStatusCommand


HostName : CachePort                            Service Name            Service Status Version Info
--------------------                            ------------            -------------- ------------
EXT-APP03A.extranet.technologytoolbox.com:22233 AppFabricCachingService UP             3 [3,3][1,3]
EXT-WEB03A.extranet.technologytoolbox.com:22233 AppFabricCachingService UNKNOWN        0 [0,0][0,0]
EXT-WEB03B.extranet.technologytoolbox.com:22233 AppFabricCachingService UNKNOWN        0 [0,0][0,0]
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

**EXT-WEB03A** - Run as administrator

```PowerShell
Remove-SPDistributedCacheServiceInstance

Enable-NetFirewallRule `
    -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)"

Enable-NetFirewallRule `
    -DisplayName "File and Printer Sharing (Echo Request - ICMPv6-In)"
```

---

---

**EXT-WEB03B** - Run as administrator

```PowerShell
Remove-SPDistributedCacheServiceInstance

Enable-NetFirewallRule `
    -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)"

Enable-NetFirewallRule `
    -DisplayName "File and Printer Sharing (Echo Request - ICMPv6-In)"
```

---

```PowerShell
Get-SPServiceInstance |
    where {($_.service.ToString()) -eq "SPDistributedCacheService Name=AppFabricCachingService"}
```

```PowerShell
$s = Get-SPServiceInstance {GUID}
$s.Delete()

Add-SPDistributedCacheServiceInstance
```

---

**EXT-WEB03A** - Run as administrator

```PowerShell
Add-SPDistributedCacheServiceInstance
```

---

---

**EXT-WEB03B** - Run as administrator

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

**SQL Server Management Studio** - Database Engine - **EXT-SQL03**

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

#### Resolve issue when upgrading Managed Metadata Service database

(skipped -- since the issue did not occur in this environment)

### Configure User Profile Service Application

---

**SQL Server Management Studio** - Database Engine - **EXT-SQL03**

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

```PowerShell
# Use SharePoint farm service account to create User Profile Service Application

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

**PowerShell** -- running as **EXTRANET\\s-sp-farm**

```PowerShell
cd D:\Shares\Builds\ClientPortal\4.0.701.0\DeploymentFiles\Scripts

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

```PowerShell
# Note: NullReferenceException occurs if you attempt to perform this step before starting the User Profile Synchronization Service.

# Import MIIS encryption key as the SharePoint farm service account

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

**Command Prompt** -- running as **EXTRANET\\s-sp-farm**

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
| PNKUS               | us.pinkertons.com          | PNKUS\\svc-sp-ups       |
| PNKCAN              | local.securitas.ca         | PNKCAN\\svc-sp-ups      |
| TECHTOOLBOX         | corp.technologytoolbox.com | TECHTOOLBOX\\svc-sp-ups |
| FABRIKAM            | corp.fabrikam.com          | FABRIKAM\\s-sp-ups      |

##### Start profile synchronization

Number of user profiles (before import): 12,869\
Number of user profiles (after import): 13,411

```PowerShell
Start-Process `
    ("C:\Program Files\Microsoft Office Servers\15.0\Synchronization Service" `
        + "\UIShell\miisclient.exe") `
    -Credential $farmCredential
```

Start time: 8:39:09 AM\
End time: 10:42:03 AM

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2D/3D42ED13B66022BF88AD7E9F79000F1EBF6ED82D.png)

### Create and configure search service application

---

**SQL Server Management Studio** - Database Engine - **EXT-SQL03**

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
> Expect the previous operation to complete in approximately 13-1/2 minutes.

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
cd D:\Shares\Builds\ClientPortal\4.0.701.0\DeploymentFiles\Scripts

& '.\Create Web Application.ps1' -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-web-client**.\
> Expect the previous operation to complete in approximately 4 minutes.

```PowerShell
cls
```

### # Restore content database or create initial site collections

#### # Remove content database created with Web application

```PowerShell
Remove-SPContentDatabase WSS_Content_SecuritasPortal -Confirm:$false -Force
```

---

**SQL Server Management Studio** - Database Engine - **EXT-SQL03**

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
> Expect the previous operations to complete in approximately 42 minutes.\
> RESTORE DATABASE successfully processed 4250867 pages in 1284.494 seconds (25.854 MB/sec).\
> ...\
> RESTORE DATABASE successfully processed 4117527 pages in 1129.271 seconds (28.485 MB/sec).

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
> Expect the previous operation to complete in approximately 9 minutes.

##### Remove SecuritasConnect v3.0 solution

(skipped)

```PowerShell
cls
```

### # Configure machine key for Web application

```PowerShell
cd D:\Shares\Builds\ClientPortal\4.0.701.0\DeploymentFiles\Scripts

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

---

**FOOBAR11** - Run as administrator

```PowerShell
cls
```

#### # Copy SSL certificate to SharePoint 2013 server

```PowerShell
$source = "\\TT-FS01\Archive\Clients\Securitas\securitasinc.com.pfx"
$destination = "\\EXT-APP03A.extranet.technologytoolbox.com" `
    + "\C`$\Users\setup-sharepoint\Desktop"

Copy-Item $source $destination
```

---

#### # Install SSL certificate

```PowerShell
$certPassword = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted for the secure string, type the password for the exported certificate.

```PowerShell
Import-PfxCertificate `
    -FilePath "C:\Users\setup-sharepoint\Desktop\securitasinc.com.pfx" `
    -CertStoreLocation Cert:\LocalMachine\My `
    -Password $certPassword
```

```PowerShell
cls
```

#### # Add public URL for HTTPS

```PowerShell
[Uri] $clientPortalUrl = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL

[String] $clientPortalHostHeader = $clientPortalUrl.Host

New-SPAlternateUrl `
    -Url "https://$clientPortalHostHeader" `
    -WebApplication $clientPortalUrl.AbsoluteUri `
    -Zone Internet
```

#### # Add HTTPS binding to site in IIS

```PowerShell
$cert = Get-ChildItem -Path Cert:\LocalMachine\My |
    Where { $_.Subject -like "CN=`*.securitasinc.com,*" }

New-WebBinding `
    -Name ("SharePoint - $clientPortalHostHeader" + "80") `
    -Protocol https `
    -Port 443 `
    -HostHeader $clientPortalHostHeader `
    -SslFlags 0
```

---

**EXT-WEB03A** - Run as administrator

```PowerShell
cls
```

#### # Add HTTPS binding to site in IIS

```PowerShell
[String] $clientPortalHostHeader = "client-test.securitasinc.com"

$cert = Get-ChildItem -Path Cert:\LocalMachine\My |
    Where { $_.Subject -like "CN=`*.securitasinc.com,*" }

New-WebBinding `
    -Name ("SharePoint - $clientPortalHostHeader" + "80") `
    -Protocol https `
    -Port 443 `
    -HostHeader $clientPortalHostHeader `
    -SslFlags 0
```

---

---

**EXT-WEB03B** - Run as administrator

```PowerShell
cls
```

#### # Add HTTPS binding to site in IIS

```PowerShell
[String] $clientPortalHostHeader = "client-test.securitasinc.com"

$cert = Get-ChildItem -Path Cert:\LocalMachine\My |
    Where { $_.Subject -like "CN=`*.securitasinc.com,*" }

New-WebBinding `
    -Name ("SharePoint - $clientPortalHostHeader" + "80") `
    -Protocol https `
    -Port 443 `
    -HostHeader $clientPortalHostHeader `
    -SslFlags 0
```

---

```PowerShell
cls
```

### # Extend web application to Intranet zone

```PowerShell
$intranetHostHeader = $clientPortalHostHeader -replace "client", "client2"

$webApp = Get-SPWebApplication -Identity $clientPortalUrl.AbsoluteUri

$windowsAuthProvider = New-SPAuthenticationProvider

$webAppName = "SharePoint - " + $intranetHostHeader + "443"

$webApp | New-SPWebApplicationExtension `
    -Name $webAppName `
    -Zone Intranet `
    -AuthenticationProvider $windowsAuthProvider `
    -HostHeader $intranetHostHeader `
    -Port 443 `
    -SecureSocketsLayer
```

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

File - **Web.config**

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

**EXT-SQL03** - Run as administrator

```PowerShell
cls
```

#### # Restore database backup

```PowerShell
$backupFile = "SecuritasPortal.bak"

$sqlcmd = @"
DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\$backupFile'

RESTORE DATABASE SecuritasPortal
  FROM DISK = @backupFilePath
  WITH
    REPLACE,
    STATS = 10

GO
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
```

#### # Configure security on SecuritasPortal database

```PowerShell
[Uri] $clientPortalUrl = $null

If ($env:COMPUTERNAME -eq "EXT-SQL02")
{
    $clientPortalUrl = [Uri] "http://client-test.securitasinc.com"
}
Else
{
    # Development environment is assumed to have SECURITAS_CLIENT_PORTAL_URL
    # environment variable set (since SQL Server is installed on same server as
    # SharePoint)
    $clientPortalUrl = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL
}

[String] $farmServiceAccount = "EXTRANET\s-sp-farm"
[String] $clientPortalServiceAccount = "EXTRANET\s-web-client"

[String] $sqlcmd = @"
USE SecuritasPortal
GO

CREATE USER [$farmServiceAccount]
FOR LOGIN [$farmServiceAccount]
GO
ALTER ROLE aspnet_Membership_BasicAccess
ADD MEMBER [$farmServiceAccount]
GO
ALTER ROLE aspnet_Membership_ReportingAccess
ADD MEMBER [$farmServiceAccount]
GO
ALTER ROLE aspnet_Roles_BasicAccess
ADD MEMBER [$farmServiceAccount]
GO
ALTER ROLE aspnet_Roles_ReportingAccess
ADD MEMBER [$farmServiceAccount]
GO

CREATE USER [$clientPortalServiceAccount]
FOR LOGIN [$clientPortalServiceAccount]
GO
ALTER ROLE aspnet_Membership_FullAccess
ADD MEMBER [$clientPortalServiceAccount]
GO
ALTER ROLE aspnet_Profile_BasicAccess
ADD MEMBER [$clientPortalServiceAccount]
GO
ALTER ROLE aspnet_Roles_BasicAccess
ADD MEMBER [$clientPortalServiceAccount]
GO
ALTER ROLE aspnet_Roles_ReportingAccess
ADD MEMBER [$clientPortalServiceAccount]
GO
ALTER ROLE Customer_Reader
ADD MEMBER [$clientPortalServiceAccount]
GO
"@

$sqlcmd += [System.Environment]::NewLine
$sqlcmd += @"
DROP USER [SEC\258521-VM4$]
DROP USER [SEC\424642-SP$]
DROP USER [SEC\424646-SP$]
DROP USER [SEC\784806-SPWFE1$]
DROP USER [SEC\784807-SPWFE2$]
DROP USER [SEC\784810-SPAPP$]
DROP USER [SEC\s-sp-farm]
DROP USER [SEC\s-web-client]
DROP USER [SEC\s-web-cloud]
DROP USER [SEC\svc-sharepoint-2010]
DROP USER [SEC\svc-web-securitas]
DROP USER [SEC\svc-web-securitas-20]
GO
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose

Set-Location C:
```

#### # Associate users to TECHTOOLBOX\\jjameson

```PowerShell
$sqlcmd = @"
USE [SecuritasPortal]
GO

INSERT INTO Customer.BranchManagerAssociatedUsers
SELECT 'jjameson@technologytoolbox.com', AssociatedUserName
FROM Customer.BranchManagerAssociatedUsers
WHERE BranchManagerUserName = 'Jeremy.Jameson@securitasinc.com'
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
```

#### # Replace shortcuts for PNKUS\\jjameson

```PowerShell
$sqlcmd = @"
USE [SecuritasPortal]
GO

UPDATE Employee.PortalUsers
SET UserName = 'TECHTOOLBOX\jjameson'
WHERE UserName = 'PNKUS\jjameson'
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
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
cd D:\Shares\Builds\ClientPortal\4.0.701.0\DeploymentFiles\Scripts

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

File - **Web.config**

```XML
  <connectionStrings>
    <add
      name="SecuritasPortal"
      connectionString="Server=EXT-SQL03;Database=SecuritasPortal;Integrated Security=true" />
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

(skipped)

```PowerShell
cls
```

### # Configure trusted root authorities in SharePoint

```PowerShell
& '.\Configure Trusted Root Authorities.ps1'
```

### # Configure application settings (e.g. Web service URLs)

---

**FOOBAR11** - Run as administrator

```PowerShell
cls
```

#### # Copy application settings file to SharePoint server

```PowerShell
$source = "\\TT-FS01\Archive\Clients\Securitas\Configuration" `
    + "\AppSettings-UAT_2018-01-19.csv"

$destination = "\\EXT-APP03A.extranet.technologytoolbox.com" `
    + "\C`$\Users\setup-sharepoint\Desktop"

Copy-Item $source $destination
```

---

```PowerShell
Import-Csv "C:\Users\setup-sharepoint\Desktop\AppSettings-UAT_2018-01-19.csv" |
    foreach {
        .\Set-AppSetting.ps1 $_.Key $_.Value $_.Description -Force -Verbose
    }
```

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

(skipped)

### Shrink content database

(skipped)

### Change recovery model of content databases from Simple to Full

(skipped)

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

### # Deploy federated authentication in SecuritasConnect

#### # Configure relying party in AD FS for SecuritasConnect

##### # Import token-signing certificate to SharePoint farm

```PowerShell
$certPath = "C:\ADFS Signing - fs.technologytoolbox.com.cer"

$cert = `
    New-Object System.Security.Cryptography.X509Certificates.X509Certificate2(
        $certPath)

$certName = $cert.Subject.Replace("CN=", "")

New-SPTrustedRootAuthority -Name $certName -Certificate $cert
```

##### # Create authentication provider for AD FS

###### # Delete ADFS trusted identity token issuer

```PowerShell
Get-SPTrustedIdentityTokenIssuer -Identity ADFS |
    Remove-SPTrustedIdentityTokenIssuer -Confirm:$false
```

###### # Define claim mappings and unique identifier claim

```PowerShell
$emailClaimMapping = New-SPClaimTypeMapping `
    -IncomingClaimType `
        "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress" `
    -IncomingClaimTypeDisplayName "EmailAddress" `
    -SameAsIncoming

$nameClaimMapping = New-SPClaimTypeMapping `
    -IncomingClaimType `
        "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name" `
    -IncomingClaimTypeDisplayName "Name" `
    -LocalClaimType `
        "http://schemas.securitasinc.com/ws/2017/01/identity/claims/name"

$sidClaimMapping = New-SPClaimTypeMapping `
    -IncomingClaimType `
        "http://schemas.microsoft.com/ws/2008/06/identity/claims/primarysid" `
    -IncomingClaimTypeDisplayName "SID" `
    -SameAsIncoming

$upnClaimMapping = New-SPClaimTypeMapping `
    -IncomingClaimType `
        "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn" `
    -IncomingClaimTypeDisplayName "UPN" `
    -SameAsIncoming

$roleClaimMapping = New-SPClaimTypeMapping `
    -IncomingClaimType `
        "http://schemas.microsoft.com/ws/2008/06/identity/claims/role" `
    -IncomingClaimTypeDisplayName "Role" `
    -SameAsIncoming

$claimsMappings = @(
    $emailClaimMapping,
    $nameClaimMapping,
    $sidClaimMapping,
    $upnClaimMapping,
    $roleClaimMapping)

$identifierClaim = $emailClaimMapping.InputClaimType
```

###### # Create authentication provider for AD FS

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
    -ClaimsMappings $claimsMappings `
    -SignInUrl $signInURL `
    -IdentifierClaim $identifierClaim
```

##### # Configure AD FS authentication provider for SecuritasConnect

```PowerShell
$clientPortalUrl = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL

$secureClientPortalUrl = "https://" + $clientPortalUrl.Host

$realm = "urn:sharepoint:securitas:" `
    + ($clientPortalUrl.Host -split '\.' | select -First 1)

$authProvider.ProviderRealms.Add($secureClientPortalUrl, $realm)
$authProvider.Update()
```

#### # Configure SecuritasConnect to use AD FS trusted identity provider

```PowerShell
$clientPortalUrl = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL

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

```PowerShell
cls
```

### # Update permissions on template sites

```PowerShell
$clientPortalUrl = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL

$sites = @(
    "Template-Sites/Post-Orders-en-US",
    "Template-Sites/Post-Orders-en-CA",
    "Template-Sites/Post-Orders-fr-CA")

$sites |
    foreach {
        $siteUrl = $clientPortalUrl.AbsoluteUri + $_

        $site = Get-SPSite -Identity $siteUrl

        $group = $site.RootWeb.AssociatedVisitorGroup

        $group.Users | foreach { $group.Users.Remove($_) }

        $group.AddUser(
            "c:0-.t|adfs|Branch Managers",
            $null,
            "Branch Managers",
            $null)
    }
```

### # Configure AD FS claim provider

```PowerShell
$tokenIssuer = Get-SPTrustedIdentityTokenIssuer -Identity ADFS
$tokenIssuer.ClaimProviderName = "Securitas ADFS Claim Provider"
$tokenIssuer.Update()
```

---

**EXT-SQL03** - Run as administrator

```PowerShell
cls
```

#### # Associate users to TECHTOOLBOX\\smasters

```PowerShell
$sqlcmd = @"
USE [SecuritasPortal]
GO

INSERT INTO Customer.BranchManagerAssociatedUsers
SELECT 'smasters@technologytoolbox.com', AssociatedUserName
FROM Customer.BranchManagerAssociatedUsers
WHERE BranchManagerUserName = 'Jeremy.Jameson@securitasinc.com'
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
```

---

**TODO:**

---

**WOLVERINE** - Run as administrator

#### Configure SSO credentials for users

##### Configure TrackTik credentials for Branch Manager

[https://client-test.securitasinc.com/\_layouts/Securitas/EditProfile.aspx](https://client-test.securitasinc.com/_layouts/Securitas/EditProfile.aspx)

Branch Manager: **smasters@technologytoolbox.com**\
TrackTik username:** opanduro2m**

##### HACK: Update TrackTik password for Angela.Parks

[https://client-local-2.securitasinc.com/\_layouts/Securitas/EditProfile.aspx](https://client-local-2.securitasinc.com/_layouts/Securitas/EditProfile.aspx)

##### HACK: Update TrackTik password for bbarthelemy-demo

[https://client-local-2.securitasinc.com/\_layouts/Securitas/EditProfile.aspx](https://client-local-2.securitasinc.com/_layouts/Securitas/EditProfile.aspx)

---

### # Restore content database backups from Production

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

#### # Copy database backups from Production

```PowerShell
$backupFile1 =
    "WSS_Content_SecuritasPortal_backup_2018_02_13_053955_4308109.bak"

$backupFile2 =
    "WSS_Content_SecuritasPortal2_backup_2018_02_13_053955_4464040.bak"

$source = "\\TT-FS01\Archive\Clients\Securitas\Backups"
$destination = "\\EXT-SQL03.extranet.technologytoolbox.com\Z$" `
    + "\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full"

robocopy $source $destination $backupFile1 $backupFile2
```

> **Note**
>
> Expect the previous operation to complete in approximately 7-1/2 minutes.

---

#### Export application settings from UAT environment

#### DEV - Copy application settings file from UAT environment

```PowerShell
cls
```

#### # Restore content database backups

##### # Remove existing content databases

```PowerShell
Enable-SharePointCmdlets

Get-SPContentDatabase -WebApplication $env:SECURITAS_CLIENT_PORTAL_URL |
    Remove-SPContentDatabase -Confirm:$false -Force
```

---

**EXT-SQL03** - Run as administrator

```PowerShell
cls
```

##### # Restore database backups

```PowerShell
$backupFile1 =
    "WSS_Content_SecuritasPortal_backup_2018_02_13_053955_4308109.bak"

$backupFile2 =
    "WSS_Content_SecuritasPortal2_backup_2018_02_13_053955_4464040.bak"

$stopwatch = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-Stopwatch.ps1

$sqlcmd = @"
DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\$backupFile1'

RESTORE DATABASE WSS_Content_SecuritasPortal
  FROM DISK = @backupFilePath
  WITH
    STATS = 5

GO

DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\$backupFile2'

RESTORE DATABASE WSS_Content_SecuritasPortal2
  FROM DISK = @backupFilePath
  WITH
    STATS = 5

GO
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose

Set-Location C:

$stopwatch.Stop()
C:\NotBackedUp\Public\Toolbox\PowerShell\Write-ElapsedTime.ps1 $stopwatch
```

> **Note**
>
> Expect the previous operation to complete in approximately 1 hour and 40 minutes.\
> RESTORE DATABASE successfully processed 4136619 pages in 1286.118 seconds (25.127 MB/sec).\
> ...\
> RESTORE DATABASE successfully processed 4038557 pages in 1304.904 seconds (24.178 MB/sec).

---

```PowerShell
cls
```

##### # Attach content databases to web application

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
> Expect the previous operation to complete in approximately 7-1/2 minutes.

```PowerShell
cls
```

### # Configure web application policy for SharePoint administrators

```PowerShell
[Uri] $clientPortalUrl = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL

[String] $adminGroup

If ($clientPortalUrl.Host -eq "client-qa.securitasinc.com")
{
    $adminGroup = "SEC\SharePoint Admins (QA)"
}
ElseIf ($clientPortalUrl.Host -eq "client-test.securitasinc.com")
{
    $adminGroup = "EXTRANET\SharePoint Admins"
}
Else
{
    $adminGroup = "EXTRANET\SharePoint Admins (DEV)"
}

$principal = New-SPClaimsPrincipal -Identity $adminGroup `
    -IdentityType WindowsSecurityGroupName

$claim = $principal.ToEncodedString()

$webApp = Get-SPWebApplication $clientPortalUrl.AbsoluteUri

$policyRole = $webApp.PolicyRoles.GetSpecialRole(
    [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl)

$policy = $webApp.Policies.Add($claim, $adminGroup)
$policy.PolicyRoleBindings.Add($policyRole)

$webApp.Update()
```

### # Import application settings from UAT environment

```PowerShell
$build = "4.0.701.0"

Push-Location C:\Shares\Builds\ClientPortal\$build\DeploymentFiles\Scripts

Import-Csv C:\NotBackedUp\Temp\AppSettings-UAT_2018-01-19.csv |
    foreach {
        .\Set-AppSetting.ps1 $_.Key $_.Value $_.Description -Force -Verbose
    }

Pop-Location
```

```PowerShell
cls
```

### # DEV - Replace site collection administrators

```PowerShell
Push-Location C:\Shares\Builds\ClientPortal\$build\DeploymentFiles\Scripts

$claim = New-SPClaimsPrincipal `
    -Identity "EXTRANET\SharePoint Admins" `
    -IdentityType WindowsSecurityGroupName

$stopwatch = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-Stopwatch.ps1

$tempFileName = [System.Io.Path]::GetTempFileName()
$tempFileName = $tempFileName.Replace(".tmp", ".csv")

Get-SPSite -WebApplication $env:SECURITAS_CLIENT_PORTAL_URL -Limit ALL |
    select Url |
    Export-Csv -Path $tempFileName -Encoding UTF8 -NoTypeInformation

Import-Csv $tempFileName |
    select -ExpandProperty Url |
    C:\NotBackedUp\Public\Toolbox\PowerShell\Run-CommandMultiThreaded.ps1 `
        -Command '.\Set-SiteAdministrator.ps1' `
        -AddParam @{"Claim" = $claim} `
        -SnapIns 'Microsoft.SharePoint.PowerShell'

$stopwatch.Stop()
C:\NotBackedUp\Public\Toolbox\PowerShell\Write-ElapsedTime.ps1 $stopwatch

Pop-Location
```

> **Note**
>
> Expect the previous operation to complete in approximately 56 minutes.

**TODO:**

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
    foreach {
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

**EXT-DC01** - Run as administrator

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

**EXT-SQL03** - Run as administrator

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
$destPath = "\\EXT-APP03A\Builds\CloudPortal\$build"

robocopy $sourcePath $destPath /E
```

### # Create Web application

```PowerShell
cd D:\Shares\Builds\CloudPortal\2.0.122.0\DeploymentFiles\Scripts

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

**SQL Server Management Studio** - Database Engine - **EXT-SQL03**

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
cd D:\Shares\Builds\CloudPortal\2.0.122.0\DeploymentFiles\Scripts

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

File - **Web.config**

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

**SQL Server Management Studio** - Database Engine - **EXT-SQL03**

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

**SQL Server Management Studio** - Database Engine - **EXT-SQL03**

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

## Install Employee Portal

### # Extend SecuritasConnect and Cloud Portal web applications

#### # Copy Employee Portal build to SharePoint server

```PowerShell
net use \\ICEMAN\Builds /USER:PNKUS\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$build = "1.0.29.0"

$sourcePath = "\\ICEMAN\Builds\Securitas\EmployeePortal\$build"
$destPath = "\\EXT-APP03A\Builds\EmployeePortal\$build"

robocopy $sourcePath $destPath /E
```

#### # Extend web applications to Intranet zone

```PowerShell
cd 'D:\Shares\Builds\EmployeePortal\1.0.29.0\Deployment Files\Scripts'

& '.\Extend Web Applications.ps1' -SecureSocketsLayer -Confirm:$false -Verbose
```

```PowerShell
cls
```

#### # Enable disk-based caching for "intranet" websites

##### # Enable disk-based caching for SecuritasConnect "intranet" website

```PowerShell
Push-Location ("C:\inetpub\wwwroot\wss\VirtualDirectories\" `
    + "client2-test.securitasinc.com443")

copy web.config "web - Copy.config"

C:\NotBackedUp\Public\Toolbox\DiffMerge\DiffMerge.exe `
    '..\client-test.securitasinc.com80\web.config' `
    .\web.config

Pop-Location
```

##### # Enable disk-based caching for Cloud Portal "intranet" website

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

#### # Map intranet URLs to loopback address in Hosts file

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    127.0.0.1 client2-test.securitasinc.com, cloud2-test.securitasinc.com
```

#### # Allow specific host names mapped to 127.0.0.1

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-BackConnectionHostnames.ps1 `
    client2-test.securitasinc.com, cloud2-test.securitasinc.com
```

### Install Web Deploy 3.6

#### Download Web Platform Installer

(skipped)

```PowerShell
cls
```

#### # Install Web Deploy

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

### # Install .NET Framework 4.5

#### # Download .NET Framework 4.5.2 installer

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

#### # Install .NET Framework 4.5.2

```PowerShell
& C:\NotBackedUp\Temp\NDP452-KB2901907-x86-x64-AllOS-ENU.exe
```

> **Important**
>
> When prompted, restart the computer to complete the installation.

```PowerShell
Remove-Item C:\NotBackedUp\Temp\NDP452-KB2901907-x86-x64-AllOS-ENU.exe
```

#### Install updates

> **Important**
>
> When prompted, restart the computer to complete the process of installing the updates.

#### Restart computer (if not restarted since installing .NET Framework 4.5)

(skipped)

#### Ensure ASP.NET v4.0 ISAPI filters are enabled

(skipped -- since the ISAPI filters were already enabled)

```PowerShell
cls
```

### # Install Employee Portal

#### # Add Employee Portal URLs to "Local intranet" zone

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-InternetSecurityZoneMapping.ps1 `
    -Zone LocalIntranet `
    -Patterns http://employee-test.securitasinc.com,
        https://employee-test.securitasinc.com
```

#### Create Employee Portal SharePoint site

(skipped)

```PowerShell
cls
```

#### # Create Employee Portal website

##### # Create Employee Portal website on SharePoint Central Administration server

```PowerShell
cd 'D:\Shares\Builds\EmployeePortal\1.0.29.0\Deployment Files\Scripts'

& '.\Configure Employee Portal Website.ps1' `
    -SiteName employee-test.securitasinc.com `
    -Confirm:$false `
    -Verbose
```

##### Configure SSL bindings on Employee Portal website

```PowerShell
cls
```

##### # Create Employee Portal website on other web servers in farm

```PowerShell
Push-Location "C:\Program Files\IIS\Microsoft Web Deploy V3"

$websiteName = "employee-test.securitasinc.com"

.\msdeploy.exe -verb:sync `
    -source:apppoolconfig="$websiteName" `
    -dest:apppoolconfig="$websiteName"`,computername=EXT-WEB03A

.\msdeploy.exe -verb:sync `
    -source:apppoolconfig="$websiteName" `
    -dest:apppoolconfig="$websiteName"`,computername=EXT-WEB03B

.\msdeploy.exe -verb:sync `
    -source:apphostconfig="$websiteName" `
    -dest:apphostconfig="$websiteName"`,computername=EXT-WEB03A

.\msdeploy.exe -verb:sync `
    -source:apphostconfig="$websiteName" `
    -dest:apphostconfig="$websiteName"`,computername=EXT-WEB03B

Pop-Location
```

```PowerShell
cls
```

#### # Deploy Employee Portal website

##### # Deploy Employee Portal website on SharePoint Central Administration server

```PowerShell
Push-Location D:\Shares\Builds\EmployeePortal\1.0.29.0\Release\_PublishedWebsites\Web_Package

attrib -r .\Web.SetParameters.xml

Notepad .\Web.SetParameters.xml
```

---

File - **Web.SetParameters.xml**

```XML
<?xml version="1.0" encoding="utf-8"?>
<parameters>
  <setParameter
    name="IIS Web Application Name"
    value="employee-test.securitasinc.com" />
  <setParameter
    name="SecuritasPortal-Web.config Connection String"
    value="Server=EXT-SQL03; Database=SecuritasPortal; Integrated Security=true" />
  <setParameter
    name="SecuritasPortalDbContext-Web.config Connection String"
    value="Data Source=EXT-SQL03; Initial Catalog=SecuritasPortal; Integrated Security=True; MultipleActiveResultSets=True;" />
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

##### # Configure application settings and web service URLs

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

##### # Deploy Employee Portal website content to other web servers in farm

```PowerShell
Push-Location "C:\Program Files\IIS\Microsoft Web Deploy V3"

$websiteName = "employee-test.securitasinc.com"

.\msdeploy.exe -verb:sync `
    -source:contentPath="C:\inetpub\wwwroot\$websiteName" `
    -dest:contentPath="C:\inetpub\wwwroot\$websiteName"`,computername=EXT-WEB03A

.\msdeploy.exe -verb:sync `
    -source:contentPath="C:\inetpub\wwwroot\$websiteName" `
    -dest:contentPath="C:\inetpub\wwwroot\$websiteName"`,computername=EXT-WEB03B

Pop-Location
```

---

**SQL Server Management Studio** - Database Engine - **EXT-SQL03**

#### -- Configure database logins and permissions for Employee Portal

```SQL
USE [master]
GO
CREATE LOGIN [EXTRANET\EXT-APP03A$]
FROM WINDOWS
WITH DEFAULT_DATABASE=[master]
GO
CREATE LOGIN [EXTRANET\EXT-WEB03A$]
FROM WINDOWS
WITH DEFAULT_DATABASE=[master]
GO
CREATE LOGIN [EXTRANET\EXT-WEB03B$]
FROM WINDOWS
WITH DEFAULT_DATABASE=[master]
GO

USE [SecuritasPortal]
GO
CREATE USER [EXTRANET\EXT-APP03A$] FOR LOGIN [EXTRANET\EXT-APP03A$]
GO
CREATE USER [EXTRANET\EXT-WEB03A$] FOR LOGIN [EXTRANET\EXT-WEB03A$]
GO
CREATE USER [EXTRANET\EXT-WEB03B$] FOR LOGIN [EXTRANET\EXT-WEB03B$]
GO
EXEC sp_addrolemember N'Employee_FullAccess', N'EXTRANET\EXT-APP03A$'
GO
EXEC sp_addrolemember N'Employee_FullAccess', N'EXTRANET\EXT-WEB03A$'
GO
EXEC sp_addrolemember N'Employee_FullAccess', N'EXTRANET\EXT-WEB03B$'
GO
```

---

```PowerShell
cls
```

#### # Grant PNKCAN and PNKUS users permissions on Cloud Portal site

```PowerShell
Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

$supportedDomains = ("FABRIKAM", "TECHTOOLBOX")

$web = Get-SPWeb "$env:SECURITAS_CLOUD_PORTAL_URL/"

$group = $web.Groups["Cloud Portal Visitors"]

$supportedDomains |
    foreach {
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
    foreach {
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
    foreach {
        $domainUsers = $web.EnsureUser($_ + '\Domain Users')

        $assignment = New-Object Microsoft.SharePoint.SPRoleAssignment(
            $domainUsers)

        $assignment.RoleDefinitionBindings.Add($contributeRole)
        $list.RoleAssignments.Add($assignment)
    }

$web.Dispose()
```

#### Replace absolute URLs in "User Sites" list

(skipped)

#### Install additional service packs and updates

```PowerShell
cls
```

#### # Map Employee Portal URL to loopback address in Hosts file

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    127.0.0.1 employee-test.securitasinc.com
```

#### # Allow specific host names mapped to 127.0.0.1

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-BackConnectionHostnames.ps1 `
    employee-test.securitasinc.com
```

```PowerShell
cls
```

#### # Resume Search Service Application and start full crawl on all content sources

```PowerShell
Get-SPEnterpriseSearchServiceApplication "Search Service Application" |
    Resume-SPEnterpriseSearchServiceApplication

Get-SPEnterpriseSearchServiceApplication "Search Service Application" |
    Get-SPEnterpriseSearchCrawlContentSource |
    foreach { $_.StartFullCrawl() }
```

> **Note**
>
> Expect the crawl to complete in approximately 4 hours and 40 minutes.

```PowerShell
cls
```

### # Clean up WinSxS folder

```PowerShell
Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase
```

### Disable setup accounts

---

**EXT-DC01** - Run as administrator

```PowerShell
Disable-ADAccount -Identity setup-sharepoint
Disable-ADAccount -Identity setup-sql
```

---

```PowerShell
cls
```

## # Configure monitoring

### # Create certificate for Operations Manager

#### # Create request for Operations Manager certificate

```PowerShell
& "C:\NotBackedUp\Public\Toolbox\Operations Manager\Scripts\New-OperationsManagerCertificateRequest.ps1"
```

#### # Submit certificate request to the Certification Authority

##### # Add Active Directory Certificate Services site to the "Trusted sites" zone and browse to the site

```PowerShell
[Uri] $adcsUrl = [Uri] "https://cipher01.corp.technologytoolbox.com"

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-InternetSecurityZoneMapping.ps1 `
    -Zone TrustedSites `
    -Patterns $adcsUrl.AbsoluteUri

Start-Process $adcsUrl.AbsoluteUri
```

##### # Submit the certificate request to an enterprise CA

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

#### # Import the certificate into the certificate store

```PowerShell
$certFile = "C:\Users\jjameson-admin\Downloads\certnew.cer"

CertReq.exe -Accept $certFile
```

```PowerShell
cls
```

#### # Delete the certificate file

```PowerShell
Remove-Item $certFile
```

---

**FOOBAR11** - Run as administrator

```PowerShell
cls
```

### # Copy SCOM agent installation files

```PowerShell
$computerName = "EXT-APP03A.extranet.technologytoolbox.com"

net use "\\$computerName\IPC`$" /USER:EXTRANET\jjameson-admin
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$source = "\\TT-FS01\Products\Microsoft\System Center 2016\SCOM\Agent\AMD64"
$destination = "\\$computerName\C`$\NotBackedUp\Temp\SCOM\Agent\AMD64"

robocopy $source $destination /E

$source = "\\TT-FS01\Products\Microsoft\System Center 2016\SCOM" `
    + "\SupportTools\AMD64"

$destination = "\\$computerName\C`$\NotBackedUp\Temp\SCOM\SupportTools\AMD64"

robocopy $source $destination /E
```

---

```PowerShell
cls
```

### # Install SCOM agent

```PowerShell
$installerPath = "C:\NotBackedUp\Temp\SCOM\Agent\AMD64\MOMAgent.msi"

$installerArguments = "MANAGEMENT_GROUP=HQ" `
    + " MANAGEMENT_SERVER_DNS=tt-scom03.corp.technologytoolbox.com" `
    + " ACTIONS_USE_COMPUTER_ACCOUNT=1" `
    + " NOAPM=1"

Start-Process `
    -FilePath msiexec.exe `
    -ArgumentList "/i `"$installerPath`" $installerArguments" `
    -Wait
```

> **Important**
>
> Wait for the installation to complete.

```PowerShell
cls
```

### # Import the certificate into Operations Manager using MOMCertImport

```PowerShell
$hostName = ([System.Net.Dns]::GetHostByName(($env:computerName))).HostName

$certImportToolPath = "C:\NotBackedUp\Temp\SCOM\SupportTools\AMD64"

Push-Location "$certImportToolPath"

.\MOMCertImport.exe /SubjectName $hostName

Pop-Location
```

```PowerShell
cls
```

#### # Remove Operations Manager installation files

```PowerShell
Remove-Item C:\NotBackedUp\Temp\SCOM -Recurse
```

### Approve manual agent install in Operations Manager

## Deploy federated authentication in SecuritasConnect

### Login as EXTRANET\\setup-sharepoint-dev

### # Pause Search Service Application

```PowerShell
Enable-SharePointCmdlets

Get-SPEnterpriseSearchServiceApplication "Search Service Application" |
    Suspend-SPEnterpriseSearchServiceApplication
```

### Configure SSL in development environments

(skipped)

---

**EXT-ADFS02A** - Run as domain administrator

```PowerShell
cls
```

### # Configure relying party in AD FS for SecuritasConnect

#### # Create relying party in AD FS

```PowerShell
$clientPortalUrl = [Uri] "http://client-test.securitasinc.com"

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
$destination = "\\EXT-APP03A.extranet.technologytoolbox.com\C$"

Copy-Item $source $destination
```

---

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

$certName = $cert.Subject.Replace("CN=", "")

New-SPTrustedRootAuthority -Name $certName -Certificate $cert
```

#### # Create authentication provider for AD FS

##### # Define claim mappings and unique identifier claim

```PowerShell
$emailClaimMapping = New-SPClaimTypeMapping `
    -IncomingClaimType `
        "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress" `
    -IncomingClaimTypeDisplayName "EmailAddress" `
    -SameAsIncoming

$nameClaimMapping = New-SPClaimTypeMapping `
    -IncomingClaimType `
        "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name" `
    -IncomingClaimTypeDisplayName "Name" `
    -LocalClaimType `
        "http://schemas.securitasinc.com/ws/2017/01/identity/claims/name"

$sidClaimMapping = New-SPClaimTypeMapping `
    -IncomingClaimType `
        "http://schemas.microsoft.com/ws/2008/06/identity/claims/primarysid" `
    -IncomingClaimTypeDisplayName "SID" `
    -SameAsIncoming

$upnClaimMapping = New-SPClaimTypeMapping `
    -IncomingClaimType `
        "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn" `
    -IncomingClaimTypeDisplayName "UPN" `
    -SameAsIncoming

$roleClaimMapping = New-SPClaimTypeMapping `
    -IncomingClaimType `
        "http://schemas.microsoft.com/ws/2008/06/identity/claims/role" `
    -IncomingClaimTypeDisplayName "Role" `
    -SameAsIncoming

$claimsMappings = @(
    $emailClaimMapping,
    $nameClaimMapping,
    $sidClaimMapping,
    $upnClaimMapping,
    $roleClaimMapping)

$identifierClaim = $emailClaimMapping.InputClaimType
```

##### # Create authentication provider for AD FS

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
    -ClaimsMappings $claimsMappings `
    -SignInUrl $signInURL `
    -IdentifierClaim $identifierClaim
```

#### # Configure AD FS authentication provider for SecuritasConnect

```PowerShell
$clientPortalUrl = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL

$secureClientPortalUrl = "https://" + $clientPortalUrl.Host

$realm = "urn:sharepoint:securitas:" `
    + ($clientPortalUrl.Host -split '\.' | select -First 1)

$authProvider.ProviderRealms.Add($secureClientPortalUrl, $realm)
$authProvider.Update()
```

### # Configure SecuritasConnect to use AD FS trusted identity provider

```PowerShell
$clientPortalUrl = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL

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

### Install and configure identity provider for client users

#### Deploy identity provider website to front-end web servers

---

**EXT-ADFS02A** - Run as domain administrator

```PowerShell
cls
```

#### # Configure claims provider trust in AD FS for identity provider

##### # Create claims provider trust in AD FS

```PowerShell
$idpHostHeader = "idp.technologytoolbox.com"

Add-AdfsClaimsProviderTrust `
    -Name $idpHostHeader `
    -MetadataURL "https://$idpHostHeader/core/wsfed/metadata" `
    -MonitoringEnabled $true `
    -AutoUpdateEnabled $true `
    -SignatureAlgorithm http://www.w3.org/2000/09/xmldsig#rsa-sha1
```

##### # Configure claim acceptance rules for claims provider trust

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

---

### Associate client email domains with claims provider trust

#### Update email addresses for non-Production environments

(skipped)

---

**EXT-SQL03** - Run as administrator

```PowerShell
cls
```

#### # Create configuration file for AD FS claims provider trust

```PowerShell
$sqlcmd = @"
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
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false |
    Export-Csv C:\NotBackedUp\Temp\ADFS-Claims-Provider-Trust-Configuration.csv

Set-Location C:

Notepad C:\NotBackedUp\Temp\ADFS-Claims-Provider-Trust-Configuration.csv
```

---

---

**EXT-ADFS02A** - Run as domain administrator

```PowerShell
cls
```

#### # Set organizational account suffixes on AD FS claims provider trust

```PowerShell
$configFile = "ADFS-Claims-Provider-Trust-Configuration.csv"
$source = ("\\EXT-SQL02A.extranet.technologytoolbox.com\C$" `
    + "\NotBackedUp\Temp")

$destination = "C:\NotBackedUp\Temp"

If ((Test-Path $destination) -eq $false)
{
    New-Item -ItemType Directory -Path $destination
}

Push-Location $destination

copy "$source\$configFile" .

$claimsProviderTrustName = Import-Csv -Path ".\$configFile" |
    select -First 1 -ExpandProperty TargetName

$orgAccountSuffixes = `
    Import-Csv ".\$configFile" |
        where { $_.TargetName -eq $claimsProviderTrustName } |
        select -ExpandProperty OrganizationalAccountSuffix

Set-AdfsClaimsProviderTrust `
    -TargetName $claimsProviderTrustName `
    -OrganizationalAccountSuffix $orgAccountSuffixes

Pop-Location
```

---

```PowerShell
cls
```

### # Migrate users

#### # Backup content database for Cloud Portal

```PowerShell
$sqlcmd = @"
-- Create copy-only database backup

DECLARE @databaseName VARCHAR(50) = 'WSS_Content_CloudPortal'

DECLARE @backupDirectory VARCHAR(255)

EXEC master.dbo.xp_instance_regread
    N'HKEY_LOCAL_MACHINE'
    , N'Software\Microsoft\MSSQLServer\MSSQLServer'
    , N'BackupDirectory'
    , @backupDirectory OUTPUT

DECLARE @backupFilePath VARCHAR(255) =
    @backupDirectory + '\Full\' + @databaseName + '.bak'

DECLARE @backupName VARCHAR(100) = @databaseName + '-Full Database Backup'

BACKUP DATABASE @databaseName
    TO DISK = @backupFilePath
    WITH COMPRESSION
        , COPY_ONLY
        , FORMAT
        , INIT
        , NAME = @backupName
        , STATS = 5

GO
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

#### # Migrate users in SharePoint to AD FS trusted identity provider

```PowerShell
Push-Location D:\Shares\Builds\ClientPortal\$newBuild\DeploymentFiles\Scripts

$stopwatch = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-Stopwatch.ps1

& '.\Migrate Users.ps1' -Verbose

$stopwatch.Stop()
C:\NotBackedUp\Public\Toolbox\PowerShell\Write-ElapsedTime.ps1 $stopwatch
```

> **Note**
>
> Expect the previous operation to complete in approximately 1 hour.

> **Important**
>
> Restart PowerShell to ensure database connections are closed.

```Console
exit
```

#### # Restore content database for Cloud Portal

##### # Stop SharePoint services

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts\Stop SharePoint Services.cmd'
```

##### # Restore content database

```PowerShell
$sqlcmd = @"
DECLARE @databaseName VARCHAR(50) = 'WSS_Content_CloudPortal'

DECLARE @backupDirectory VARCHAR(255)

EXEC master.dbo.xp_instance_regread
    N'HKEY_LOCAL_MACHINE'
    , N'Software\Microsoft\MSSQLServer\MSSQLServer'
    , N'BackupDirectory'
    , @backupDirectory OUTPUT

DECLARE @backupFilePath VARCHAR(255) =
    @backupDirectory + '\Full\' + @databaseName + '.bak'

RESTORE DATABASE @databaseName
    FROM DISK = @backupFilePath
    WITH REPLACE
        , STATS = 5

GO
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

##### # Start SharePoint services

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts\Start SharePoint Services.cmd'
```

```PowerShell
cls
```

#### # Update user names in SecuritasPortal database

```PowerShell
Push-Location ("D:\Shares\Builds\ClientPortal\$newBuild" `
    + "\DeploymentFiles\Scripts")

& '.\Update SecuritasPortal UserNames.ps1'

& "C:\Program Files (x86)\Microsoft SQL Server\120\Tools\Binn\ManagementStudio\Ssms.exe" '.\Update SecuritasPortal UserNames.sql'
```

> **Note**
>
> Execute the SQL script to update the user names in the database.

```Console
cls
Pop-Location
```

### # Update permissions on template sites

```PowerShell
$clientPortalUrl = $env:SECURITAS_CLIENT_PORTAL_URL

$sites = @(
    "/Template-Sites/Post-Orders-en-US",
    "/Template-Sites/Post-Orders-en-CA",
    "/Template-Sites/Post-Orders-fr-CA")

$sites |
    foreach {
        $siteUrl = $clientPortalUrl + $_

        $site = Get-SPSite -Identity $siteUrl

        $group = $site.RootWeb.AssociatedVisitorGroup

        $group.Users | foreach { $group.Users.Remove($_) }

        $group.AddUser(
            "c:0-.t|adfs|Branch Managers",
            $null,
            "Branch Managers",
            $null)
    }
```

### # Configure AD FS claim provider

```PowerShell
$tokenIssuer = Get-SPTrustedIdentityTokenIssuer -Identity ADFS
$tokenIssuer.ClaimProviderName = "Securitas ADFS Claim Provider"
$tokenIssuer.Update()
```

---

**EXT-ADFS02A** - Run as domain administrator

```PowerShell
cls
```

### # Customize AD FS login pages

#### # Customize text and image on login pages for SecuritasConnect relying party

```PowerShell
$clientPortalUrl = [Uri] "http://client-test.securitasinc.com"

$idpHostHeader = "idp.technologytoolbox.com"

$relyingPartyDisplayName = $clientPortalUrl.Host

Set-AdfsRelyingPartyWebContent `
    -TargetRelyingPartyName $relyingPartyDisplayName `
    -CompanyName "SecuritasConnect®" `
    -OrganizationalNameDescriptionText `
        "Enter your Securitas e-mail address and password below." `
    -SignInPageDescription $null `
    -HomeRealmDiscoveryOtherOrganizationDescriptionText `
        "Enter your e-mail address below."

$tempFile = [System.Io.Path]::GetTempFileName()
$tempFile = $tempFile.Replace(".tmp", ".jpg")

Invoke-WebRequest `
    -Uri https://$idpHostHeader/images/illustration.jpg `
    -OutFile $tempFile

Set-AdfsRelyingPartyWebTheme `
    -TargetRelyingPartyName $relyingPartyDisplayName `
    -Illustration @{ path = $tempFile }

Remove-Item $tempFile
```

#### # Configure custom CSS and JavaScript files for additional customizations

```PowerShell
$relyingPartyDisplayName = $clientPortalUrl.Host

$tempCssFile = [System.Io.Path]::GetTempFileName()
$tempCssFile = $tempCssFile.Replace(".tmp", ".css")

$tempJsFile = [System.Io.Path]::GetTempFileName()
$tempJsFile = $tempJsFile.Replace(".tmp", ".js")

Invoke-WebRequest `
    -Uri https://$idpHostHeader/css/styles.css `
    -OutFile $tempCssFile

Invoke-WebRequest `
    -Uri https://$idpHostHeader/js/onload.js `
    -OutFile $tempJsFile

Set-AdfsRelyingPartyWebTheme `
    -TargetRelyingPartyName $relyingPartyDisplayName `
    -OnLoadScriptPath $tempJsFile `
    -StyleSheet @{ path = $tempCssFile }

Remove-Item $tempCssFile
Remove-Item $tempJsFile
```

---

### # Upgrade Cloud Portal to "v2.0 Sprint-21" release

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

#### # Copy new build from TFS drop location

```PowerShell
$newBuild = "2.0.125.0"

$sourcePath = "\\TT-FS01\Builds\Securitas\CloudPortal\$newBuild"

$destPath = "\\EXT-FOOBAR2.extranet.technologytoolbox.com\Builds" `
    + "\CloudPortal\$newBuild"

robocopy $sourcePath $destPath /E /NP
```

---

```PowerShell
cls
```

#### # Remove previous versions of Cloud Portal WSP

```PowerShell
$oldBuild = "2.0.122.0"

Push-Location ("D:\Shares\Builds\CloudPortal\$oldBuild" `
    + "\DeploymentFiles\Scripts")

& '.\Deactivate Features.ps1' -Verbose

& '.\Retract Solutions.ps1' -Verbose

& '.\Delete Solutions.ps1' -Verbose

Pop-Location
```

#### # Install new versions of Cloud Portal WSP

```PowerShell
$newBuild = "2.0.125.0"

Push-Location ("D:\Shares\Builds\CloudPortal\$newBuild" `
    + "\DeploymentFiles\Scripts")

& '.\Add Solutions.ps1' -Verbose

& '.\Deploy Solutions.ps1' -Verbose

& '.\Activate Features.ps1' -Verbose

Pop-Location
```

```PowerShell
cls
```

#### # Delete old build

```PowerShell
Remove-Item D:\Shares\Builds\CloudPortal\2.0.122.0 `
   -Recurse -Force
```

### # Upgrade Employee Portal to "v1.0 Sprint-6" release

---

**FOOBAR10** - Run as administrator

```PowerShell
cls
```

#### # Copy new build from TFS drop location

```PowerShell
$build = "1.0.38.0"

$sourcePath = "\\TT-FS01\Builds\Securitas\EmployeePortal\$build"

$destPath = "\\EXT-APP03A.extranet.technologytoolbox.com\Builds" `
    + "\EmployeePortal\$build"

robocopy $sourcePath $destPath /E
```

---

```PowerShell
$build = "1.0.38.0"
```

#### # Backup Employee Portal Web.config file

```PowerShell
[Uri] $employeePortalUrl = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL.Replace(
    "client",
    "employee")

[String] $employeePortalHostHeader = $employeePortalUrl.Host

Copy-Item C:\inetpub\wwwroot\$employeePortalHostHeader\Web.config `
    "C:\NotBackedUp\Temp\Web - $employeePortalHostHeader.config"
```

#### # Deploy Employee Portal website on Central Administration server

```PowerShell
Push-Location ("D:\Shares\Builds\EmployeePortal\$build" `
    + "\Release\_PublishedWebsites\Web_Package")

attrib -r .\Web.SetParameters.xml

$config = Get-Content Web.SetParameters.xml

$config = $config -replace `
    "Default Web Site/Web_deploy", $employeePortalHostHeader

$config = $config -replace `
    "Server=.; Database=SecuritasPortal",
    "Server=EXT-SQL03; Database=SecuritasPortal"

$config = $config -replace `
    "Data Source=.; Initial Catalog=SecuritasPortal",
    "Data Source=EXT-SQL03; Initial Catalog=SecuritasPortal"

$configXml = [xml] $config

$configXml.Save("$pwd\Web.SetParameters.xml")

.\Web.deploy.cmd /t

.\Web.deploy.cmd /y

Pop-Location
```

#### # Configure application settings and web service URLs

```PowerShell
Push-Location ("C:\inetpub\wwwroot\" + $employeePortalHostHeader)

(Get-Content Web.config) `
    -replace '<add key="Environment" value="Local" />',
        '<add key="Environment" value="Test" />' `
    -replace '<add key="GoogleAnalytics.TrackingId" value="" />',
        '<add key="GoogleAnalytics.TrackingId" value="UA-25899478-4" />' `
    -replace 'https://client-local', 'https://client-test' `
    -replace 'https://cloud2-local', 'https://cloud2-test' `
    -replace 'smtpServer="technologytoolbox-com.mail.protection.outlook.com"',
        'smtpServer="smtp-test.technologytoolbox.com"' |
    Set-Content Web.config

Pop-Location

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    "C:\NotBackedUp\Temp\Web - $employeePortalHostHeader.config" `
    C:\inetpub\wwwroot\$employeePortalHostHeader\Web.config
```

```PowerShell
cls
```

#### # Deploy Employee Portal website content to other web servers in farm

```PowerShell
Push-Location "C:\Program Files\IIS\Microsoft Web Deploy V3"

$websiteName = "employee-test.securitasinc.com"

.\msdeploy.exe -verb:sync `
    -source:contentPath="C:\inetpub\wwwroot\$websiteName" `
    -dest:contentPath="C:\inetpub\wwwroot\$websiteName"`,computername=EXT-WEB03A

.\msdeploy.exe -verb:sync `
    -source:contentPath="C:\inetpub\wwwroot\$websiteName" `
    -dest:contentPath="C:\inetpub\wwwroot\$websiteName"`,computername=EXT-WEB03B

Pop-Location
```

```PowerShell
cls
```

#### # Update Post Orders URLs in Employee Portal

##### # Update Post Orders URL in Employee Portal SharePoint site

```PowerShell
Start-Process ($env:SECURITAS_CLOUD_PORTAL_URL `
    + "/sites/Employee-Portal/Lists/Shortcuts")
```

```PowerShell
cls
```

##### # Update Post Orders URLs in SecuritasPortal database

```PowerShell
$clientPortalUrl = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL

$secureClientPortalUrl = "https://" + $clientPortalUrl.Host

$newPostOrdersUrl = "$secureClientPortalUrl/Branch-Management/Post-Orders"

$sqlcmd = @"
USE SecuritasPortal
GO

UPDATE Employee.UserShortcuts
SET UrlValue = '$newPostOrdersUrl'
WHERE UrlValue =
    'https://client2.securitasinc.com/Branch-Management/Post-Orders'
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

#### # Delete old build

```PowerShell
Remove-Item D:\Shares\Builds\EmployeePortal\1.0.32.0 -Recurse -Force
```

```PowerShell
cls
```

### # Resume Search Service Application

```PowerShell
Get-SPEnterpriseSearchServiceApplication "Search Service Application" |
    Resume-SPEnterpriseSearchServiceApplication
```

```PowerShell
cls
```

## # Configure monitoring

### # Create certificate for Operations Manager

#### # Create request for Operations Manager certificate

```PowerShell
& "C:\NotBackedUp\Public\Toolbox\Operations Manager\Scripts\New-OperationsManagerCertificateRequest.ps1"
```

#### # Submit certificate request to the Certification Authority

##### # Add Active Directory Certificate Services site to the "Trusted sites" zone and browse to the site

```PowerShell
[Uri] $adcsUrl = [Uri] "https://cipher01.corp.technologytoolbox.com"

Start-Process $adcsUrl.AbsoluteUri
```

##### # Submit the certificate request to an enterprise CA

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

#### # Import the certificate into the certificate store

```PowerShell
$certFile = "C:\Users\$env:USERNAME\Downloads\certnew.cer"

CertReq.exe -Accept $certFile

If ($? -eq $true)
{
    Remove-Item $certFile
}
```

### # Install SCOM agent

```PowerShell
$installerPath = "\\EXT-FS01\Products\Microsoft\System Center 2019\SCOM\Agents\AMD64" `
    + "\MOMAgent.msi"

$installerArguments = "MANAGEMENT_GROUP=HQ" `
    + " MANAGEMENT_SERVER_DNS=TT-SCOM01C.corp.technologytoolbox.com" `
    + " ACTIONS_USE_COMPUTER_ACCOUNT=1"

Start-Process `
    -FilePath msiexec.exe `
    -ArgumentList "/i `"$installerPath`" $installerArguments" `
    -Wait
```

> **Important**
>
> Wait for the installation to complete.

```PowerShell
cls
```

### # Import the certificate into Operations Manager using MOMCertImport

```PowerShell
$hostName = ([System.Net.Dns]::GetHostByName(($env:computerName))).HostName

$certImportToolPath = "\\EXT-FS01\Products\Microsoft" `
    + "\System Center 2019\SCOM\SupportTools\AMD64\MOMCertImport.exe"

& $certImportToolPath /SubjectName $hostName
```

### Approve manual agent install in Operations Manager

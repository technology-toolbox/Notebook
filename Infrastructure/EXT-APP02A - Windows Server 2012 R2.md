# EXT-APP02A - Windows Server 2012 R2 Standard

Tuesday, April 19, 2016
10:14 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

### # Create virtual machine

```PowerShell
$vmHost = "BEAST"
$vmName = "EXT-APP02A"

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path E:\NotBackedUp\VMs `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 45GB `
    -MemoryStartupBytes 8GB `
    -SwitchName "Production"

Set-VM `
    -ComputerName $vmHost `
    -VMName $vmName `
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
  - In the **Computer name** box, type **EXT-APP02A**.
  - Select **Join a workgroup**.
  - In the **Workgroup **box, type **WORKGROUP**.
  - Click **Next**.
- On the **Applications** step, ensure no items are selected and click **Next**.

```PowerShell
cls
```

## # Rename local Administrator account and set password

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

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

## # Remove disk from virtual CD/DVD drive

```PowerShell
$vmHost = "BEAST"
$vmName = "EXT-APP02A"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

---

## Login as EXT-APP02A\\foo

```PowerShell
cls
```

## # Configure network settings

### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select Name, InterfaceDescription

Get-NetAdapter `
    -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "Production"
```

### # Configure "Production" network adapter

```PowerShell
$interfaceAlias = "Production"
```

#### # Configure IPv4 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 192.168.10.209,192.168.10.210
```

#### # Configure IPv6 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 2601:282:4201:e500::209,2601:282:4201:e500::210
```

#### # Enable jumbo frames

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

### # Restart computer to avoid potential issue when joining domain

```PowerShell
Restart-Computer
```

```PowerShell
cls
```

## # Join domain

```PowerShell
Add-Computer `
    -DomainName extranet.technologytoolbox.com `
    -Credential (Get-Credential EXTRANET\jjameson-admin) `
    -Restart
```

## Move computer to "SharePoint Servers" OU

---

**EXT-DC01**

```PowerShell
$computerName = "EXT-APP02A"
$targetPath = ("OU=SharePoint Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=extranet,DC=technologytoolbox,DC=com")

Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath
```

---

## Login as EXT-APP02A\\foo

## # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

## # Change drive letter for DVD-ROM

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
```

## # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

## # Configure firewall rules for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
New-NetFirewallRule `
    -Name 'Remote Windows Update (DCOM-In)' `
    -DisplayName 'Remote Windows Update (DCOM-In)' `
    -Description 'Allows remote auditing and installation of Windows updates via POSHPAIG (http://poshpaig.codeplex.com/)' `
    -Group 'Remote Windows Update' `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 135 `
    -Profile Domain `
    -Action Allow

New-NetFirewallRule `
    -Name 'Remote Windows Update (Dynamic RPC)' `
    -DisplayName 'Remote Windows Update (Dynamic RPC)' `
    -Description 'Allows remote auditing and installation of Windows updates via POSHPAIG (http://poshpaig.codeplex.com/)' `
    -Group 'Remote Windows Update' `
    -Program '%windir%\system32\dllhost.exe' `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort RPC `
    -Profile Domain `
    -Action Allow

New-NetFirewallRule `
    -Name 'Remote Windows Update (SMB-In)' `
    -DisplayName 'Remote Windows Update (SMB-In)' `
    -Description 'Allows remote auditing and installation of Windows updates via POSHPAIG (http://poshpaig.codeplex.com/)' `
    -Group 'Remote Windows Update' `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 445 `
    -Profile Domain `
    -Action Allow

Enable-NetFirewallRule `
    -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)"

Enable-NetFirewallRule `
    -DisplayName "File and Printer Sharing (Echo Request - ICMPv6-In)"
```

## # Disable firewall rules for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
Disable-NetFirewallRule -Group 'Remote Windows Update'
```

## Configure VM storage

| Disk | Drive Letter | Volume Size | VHD Type | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------- | -------------------- | ------------ |
| 0    | C:           | 45 GB       | Dynamic  | 4K                   | OSDisk       |
| 1    | D:           | 20 GB       | Dynamic  | 4K                   | Data01       |
| 2    | L:           | 10 GB       | Dynamic  | 4K                   | Log01        |

---

**FOOBAR8**

### # Create Data01, Log01, and Backup01 VHDs

```PowerShell
$vmHost = "BEAST"
$vmName = "EXT-APP02A"

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName" `
    + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 20GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ControllerType SCSI `
    -Path $vhdPath

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName" `
    + "_Log01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 10GB
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

```PowerShell
cls
```

### # Set MaxPatchCacheSize to 0 (Recommended)

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

### Install latest service pack and updates

### Create service accounts

---

**EXT-DC01**

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

(skipped)

### Install SQL Server 2014

### Configure TempDB data and log files

### Configure "Max Degree of Parallelism" for SharePoint

### Configure permissions on \\Windows\\System32\\LogFiles\\Sum files

```PowerShell
cls
```

### # Install Prince on front-end Web servers

```PowerShell
net use \\ICEMAN\Products /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

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

## Install and configure SharePoint Server 2013

### Download SharePoint 2013 prerequisites to a file share

(skipped)

```PowerShell
cls
```

### # Install SharePoint 2013 prerequisites on the farm servers

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Insert the SharePoint 2013 installation media into the DVD drive for the SharePoint VM

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\SharePoint 2013\" `
    + "en_sharepoint_server_2013_with_sp1_x64_dvd_3823428.iso"

Set-VMDvdDrive -ComputerName BEAST -VMName EXT-APP02A -Path $imagePath
```

---

```Console
net use \\ICEMAN\Products /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$sourcePath = `
    "\\ICEMAN\Products\Microsoft\SharePoint 2013\PrerequisiteInstallerFiles_SP1"

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
> Wait for the prerequisites to be installed.

```PowerShell
Remove-Item "C:\NotBackedUp\Temp\PrerequisiteInstallerFiles_SP1" -Recurse
```

```PowerShell
cls
```

### # Install SharePoint Server 2013 on the farm servers

```PowerShell
& X:\setup.exe
```

```PowerShell
cls
```

### # Install Cumulative Update for SharePoint Server 2013

```PowerShell
net use \\ICEMAN\Products /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$patch = "15.0.4727.1000 - SharePoint 2013 June 2015 CU"

robocopy `
    "\\ICEMAN\Products\Microsoft\SharePoint 2013\Patches\$patch" `
    "C:\NotBackedUp\Temp\$patch" `
    /E

& "C:\NotBackedUp\Temp\$patch\*.exe"
```

> **Important**
>
> Wait for the patch to be installed.

```PowerShell
Remove-Item "C:\NotBackedUp\Temp\$patch" -Recurse
```

```PowerShell
cls
```

### # Add the SharePoint bin folder to the PATH environment variable

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

### Copy SecuritasConnect build to SharePoint server

```Console
net use \\ICEMAN\Builds /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
robocopy `
    "\\ICEMAN\Builds\Securitas\ClientPortal\4.0.661.0" `
    "C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.661.0" `
    /E
```

### Create and configure setup account for SharePoint

#### Create setup account for SharePoint

---

**EXT-DC01**

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
    -CannotChangePassword:$true `
    -PasswordNeverExpires:$true
```

---

---

**EXT-SQL02 - SQL Server Management Studio**

#### -- Add setup account to dbcreator and securityadmin server roles

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

#### Add setup account to SharePoint Admins domain group

### # Create and configure the farm

> **Important**
>
> Login as **EXTRANET\\setup-sharepoint**

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.661.0\DeploymentFiles\Scripts

& '.\Create Farm.ps1' -CentralAdminAuthProvider NTLM -DatabaseServer EXT-SQL02 -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-sp-farm**.\
> Expect the previous operation to complete in approximately 6 minutes.

### Add Web servers to the farm

```PowerShell
cls
```

### # Add SharePoint Central Administration to the "Local intranet" zone

```PowerShell
[string] $registryKey = ("HKCU:\Software\Microsoft\Windows" `
    + "\CurrentVersion\Internet Settings\ZoneMap\EscDomains" `
    + "\$env:COMPUTERNAME")

If ((Test-Path $registryKey) -eq $false)
{
    New-Item $registryKey | Out-Null
}

Set-ItemProperty -Path $registryKey -Name http -Value 1
```

### # Grant permissions on DCOM applications for SharePoint

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.661.0\DeploymentFiles\Scripts

& '.\Configure DCOM Permissions.ps1' -Verbose
```

```PowerShell
cls
```

### # Configure diagnostic logging

```PowerShell
Set-SPDiagnosticConfig -LogLocation "L:\Microsoft Office Servers\15.0\Logs"
```

### # Configure usage and health data collection

```PowerShell
Set-SPUsageService -LoggingEnabled 1

Set-SPUsageService -UsageLogLocation "L:\Microsoft Office Servers\15.0\Logs"

New-SPUsageApplication
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

```PowerShell
cls
```

## # Install and configure Office Web Apps

#### # Configure the SharePoint 2013 farm to use Office Web Apps

```PowerShell
New-SPWOPIBinding -ServerName wac.fabrikam.com

Set-SPWOPIZone -zone "external-https"
```

#### # Configure name resolution on Office Web Apps farm

---

**EXT-WAC02A**

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    -IPAddress 192.168.10.59 `
    -Hostnames EXT-APP02A, client-test.securitasinc.com
```

---

## Backup SharePoint 2010 environment

### Backup databases in SharePoint 2010 environment

(Download backup files from PROD)

#### Copy the backup files to the SQL Server for the SharePoint 2013 farm

[\\\\ICEMAN\\Archive\\Clients\\Securitas\\Backups](\\ICEMAN\Archive\Clients\Securitas\Backups)

### # Export the User Profile Synchronization encryption key

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

#### Copy MIIS encryption key file to SharePoint 2013 server

## Snapshot SharePoint farm

---

**FOOBAR8**

### # Define list of VMs used in "EXT02" SharePoint farm

```PowerShell
$ext02Servers = @(
    [PSCustomObject] @{ BootOrder = 1;
        VMName = 'EXT-SQL02'; VMHost = 'STORM'; },
    [PSCustomObject] @{ BootOrder = 2;
        VMName = 'EXT-APP02A'; VMHost = 'BEAST'; },
    [PSCustomObject] @{ BootOrder = 3;
        VMName = 'EXT-WEB02A'; VMHost = 'BEAST'; },
    [PSCustomObject] @{ BootOrder = 4;
        VMName = 'EXT-WEB02B'; VMHost = 'STORM'; })
```

### # Shutdown VMs

```PowerShell
$ext02Servers |
    sort BootOrder -Descending |
    ForEach-Object {
        $vmHost = $_.VMHost
        $vmName = $_.VMName

        Write-Host "Stopping virtual machine ($vmName)..."
        Stop-VM -ComputerName $vmHost -VMName $vmName
    }
```

```PowerShell
cls
```

### # Snapshot VMs

```PowerShell
$snapshotName = `
    "Before - Configure SharePoint services and service applications"

$ext02Servers |
    ForEach-Object {
        $vmHost = $_.VMHost
        $vmName = $_.VMName

        Checkpoint-VM `
            -ComputerName $vmHost `
            -Name $vmName `
            -SnapshotName $snapshotName
    }
```

```PowerShell
cls
```

### # Start VMs

```PowerShell
$ext02Servers |
    sort BootOrder |
    ForEach-Object {
        $vmHost = $_.VMHost
        $vmName = $_.VMName

        Write-Host "Starting virtual machine ($vmName)..."
        Start-VM -ComputerName $vmHost -VMName $vmName

        Write-Host "Waiting for virtual machine ($vmName) to start..."
        Start-Sleep -Seconds 60
    }
```

```PowerShell
cls
```

### # Revert VMs to most recent checkpoint

```PowerShell
$ext02Servers |
    sort BootOrder -Descending |
    ForEach-Object {
        $vmHost = $_.VMHost
        $vmName = $_.VMName

        Write-Host "Reverting virtual machine ($vmName)..."

        Get-VMSnapshot -ComputerName $vmHost -VMName $vmName |
            Sort-Object CreationTime |
            Select-Object -Last 1 |
            Restore-VMSnapshot -Confirm:$false
    }
```

---

## # Configure SharePoint services and service applications

### # Change the service account for the Distributed Cache

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.661.0\DeploymentFiles\Scripts

& '.\Configure Distributed Cache.ps1' -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-sp-serviceapp**.\
> Expect the previous operation to complete in approximately 7-8 minutes.

```PowerShell
cls
```

### # Configure the State Service

```PowerShell
& '.\Configure State Service.ps1' -Verbose
```

### # Configure the SharePoint ASP.NET Session State service

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

```PowerShell
cls
```

### # Configure the Managed Metadata Service

---

**EXT-SQL02 - SQL Server Management Studio**

#### -- Restore the database backup from the SharePoint 2010 Managed Metadata Service

```Console
DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\'
    + 'Securitas_CP_MMS.bak'

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

USE [ManagedMetadataService]
GO
CREATE USER [EXTRANET\setup-sharepoint]
FOR LOGIN [EXTRANET\setup-sharepoint]
GO
ALTER ROLE [db_owner]
ADD MEMBER [EXTRANET\setup-sharepoint]
GO
```

---

```PowerShell
cls
```

#### # Create the Managed Metadata Service

```PowerShell
& '.\Configure Managed Metadata Service.ps1' -Verbose
```

```PowerShell
cls
```

### # Configure the User Profile Service Application

---

**EXT-SQL02 - SQL Server Management Studio**

#### -- Restore profile database

```Console
DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\'
    + 'Profile DB New.bak'

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

#### -- Restore synchronization database

```Console
SET @backupFilePath =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\'
    + 'Sync DB New.bak'

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

#### -- Restore social tagging database

```Console
SET @backupFilePath =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\'
    + 'Social DB New.bak'

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

USE [UserProfileService_Profile]
GO
CREATE USER [EXTRANET\setup-sharepoint]
FOR LOGIN [EXTRANET\setup-sharepoint]
GO
ALTER ROLE [db_owner] ADD MEMBER [EXTRANET\setup-sharepoint]
GO

USE [UserProfileService_Social]
GO
CREATE USER [EXTRANET\setup-sharepoint]
FOR LOGIN [EXTRANET\setup-sharepoint]
GO
ALTER ROLE [db_owner] ADD MEMBER [EXTRANET\setup-sharepoint]
GO

USE [UserProfileService_Sync]
GO
CREATE USER [EXTRANET\setup-sharepoint]
FOR LOGIN [EXTRANET\setup-sharepoint]
GO
ALTER ROLE [db_owner] ADD MEMBER [EXTRANET\setup-sharepoint]
GO

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

#### # Create the User Profile Service Application

# Create User Profile Service Application as EXTRANET\\s-sp-farm:

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
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.661.0\DeploymentFiles\Scripts

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

(skipped)

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
net localgroup Administrators /add EXTRANET\s-sp-farm

Restart-Service SPTimerV4
```

#### Start the User Profile Synchronization Service

```PowerShell
cls
```

#### # Import MIIS encryption key

```PowerShell
# Note: NullReferenceException occurs if you attempt to perform this step before starting the User Profile Synchronization Service.
```

# Import MIIS encryption key as EXTRANET\\s-sp-farm:

```PowerShell
$farmCredential = Get-Credential (Get-SPFarm).DefaultServiceAccount.Name
```

> **Note**
>
> When prompted for the service account credentials, type the password for the SharePoint farm service account.

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
net localgroup Administrators /delete EXTRANET\s-sp-farm

Restart-Service SPTimerV4
```

#### Configure synchronization connections and import data from Active Directory

Delete **PNKCAN** and **PNKUS **connections.

> **Note**
>
> An error occurs when deleting the **PNKUS** connection (due to a timeout after 5 minutes). However, the connection is eventually deleted as expected.

##### Create synchronization connections to Active Directory

| **Connection Name** | **Forest Name**            | **Account Name**        |
| ------------------- | -------------------------- | ----------------------- |
| TECHTOOLBOX         | corp.technologytoolbox.com | TECHTOOLBOX\\svc-sp-ups |
| FABRIKAM            | corp.fabrikam.com          | FABRIKAM\\s-sp-ups      |

##### Start profile synchronization

Error running profile import job

05/18/2016 09:41:51.64	OWSTIMER.EXE (0x0A38)	0x0AFC	SharePoint Foundation	Timer	ca2m	Unexpected	An internal error occurred while running a timer job: Value was either too large or too small for an Int16.    at System.Convert.ToInt16(Int32 value)     at Microsoft.SharePoint.Administration.SPTimerJobUsageMonitoredScope.OnDisposing()     at Microsoft.SharePoint.Utilities.SPMonitoredScope.Dispose(Boolean disposing)     at Microsoft.SharePoint.Administration.SPTimerJobInvokeInternal.Invoke(SPJobDefinition jd, Guid targetInstanceId, Boolean isTimerService, Int32& result)	3f8c7eb3-4e19-416f-94bb-2b119912b77c

05/18/2016 09:41:51.64	OWSTIMER.EXE (0x0A38)	0x0AFC	SharePoint Foundation	Timer	6772	Critical	There was an internal error invoking the timer job '{0DC6F7F2-06E9-4F09-851C-727981951EA8}' for service '{2FA9FF8A-5B66-4D2E-9208-B760633B685F}'.	3f8c7eb3-4e19-416f-94bb-2b119912b77c

05/18/2016 09:41:51.64	OWSTIMER.EXE (0x0A38)	0x0AFC	SharePoint Foundation	General	8e2s	Medium	Unknown SPRequest error occurred. More information: 0x80131516	3f8c7eb3-4e19-416f-94bb-2b119912b77c

```C#
namespace Microsoft.SharePoint.Administration
{
    internal sealed class SPTimerJobUsageMonitoredScope : SPMonitoredScope
    {
...
        protected override void OnDisposing()
        {
...
                    ISPScopedPerformanceMonitor monitor = base.GetMonitor<SPExecutionTimeCounter>();
...
                    this.m_UsageEntry.ServiceCallCount = System.Convert.ToInt16(monitor.Value, System.Globalization.CultureInfo.InvariantCulture);
...
        }
    }
}
```

...which causes profile synchronization to hang. I clicked on the **Stop** link, but that only results in **Profile Synchronization Status** changing from **Synchronizing** to **Stopping**).

I attempted several solutions to stop the profile import job, including:

1. Disabling/enabling the Synchronization Timer Job
2. Stopping and starting the User Profile Synchronization service through Central Admin -- after adding the farm account to the local Administrators group -- and

Nothing worked, so **PUNT!!!**

#### Delete the User Profile Service Application (via Central Admin)

```PowerShell
cls
```

#### # Create the User Profile Service Application

# Create User Profile Service Application as EXTRANET\\s-sp-farm:

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
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.661.0\DeploymentFiles\Scripts

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

(skipped)

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
net localgroup Administrators /add EXTRANET\s-sp-farm

Restart-Service SPTimerV4
```

#### Start the User Profile Synchronization Service

#### Wait for User Profile Synchronization Service to finish starting

> **Important**
>
> Wait until the status of **User Profile Synchronization Service** shows **Started** before proceeding.

```PowerShell
cls
```

#### # Remove SharePoint farm account from local Administrators group

```PowerShell
net localgroup Administrators /delete EXTRANET\s-sp-farm

Restart-Service SPTimerV4
```

#### Configure synchronization connections and import data from Active Directory

##### Create synchronization connections to Active Directory

| **Connection Name** | **Forest Name**            | **Account Name**        |
| ------------------- | -------------------------- | ----------------------- |
| TECHTOOLBOX         | corp.technologytoolbox.com | TECHTOOLBOX\\svc-sp-ups |
| FABRIKAM            | corp.fabrikam.com          | FABRIKAM\\s-sp-ups      |

##### Start profile synchronization

```PowerShell
cls
```

### # Create and configure the search service application

#### # Create the Search Service Application

```PowerShell
& '.\Configure SharePoint Search.ps1' -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-sp-crawler**.\
> Expect the previous operation to complete in approximately 5-6 minutes.

```Text
[2016-05-08 06:22:10] Configure SharePoint Search -

  Service application name: Search Service Application
  Service application pool: SharePoint Service Applications
  Default content access account: EXTRANET\s-sp-crawler
  Index location: D:\Microsoft Office Servers\15.0\Data\Office Server\Search Index
  Database server: EXT-SQL02
  Database name: SearchService

Confirm
Are you sure you want to perform this action?
Performing the operation "Configure SharePoint Search.ps1" on target "EXT-APP02A".
[Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "Y"):
ForEach-Object : Exception calling "Deploy" with "0" argument(s): "An object of the type Microsoft.SharePoint.Administration.SPWindowsServiceCredentialDeploymentJobDefinition named "windows-service-credentials-SPSearchHostController" already exists under the parent Microsoft.Office.Server.Search.Administration.SearchRuntimeService named "SPSearchHostController".  Rename your object or delete the existing object."
At C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.661.0\DeploymentFiles\Scripts\Configure SharePoint Search.ps1:337 char:13
+             ForEach-Object {
+             ~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [ForEach-Object], MethodInvocationException
    + FullyQualifiedErrorId : SPDuplicateObjectException,Microsoft.PowerShell.Commands.ForEachObjectCommand
```

#### Modify search topology

```PowerShell
cls
```

#### # Configure people search in SharePoint

```PowerShell
$mySiteHostLocation = "http://client-test.securitasinc.com/sites/my"

$searchApp = Get-SPEnterpriseSearchServiceApplication `
    -Identity "Search Service Application"
```

##### # Grant permissions to default content access account

```PowerShell
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
$mySiteHostUri = [Uri] $mySiteHostLocation

If ($mySiteHostUri.Scheme -eq "http")
{
    $startAddress = "sps3://" + $mySiteHostUri.Authority
}
ElseIf ($mySiteHostUri.Scheme -eq "https")
{
    $startAddress = "sps3s://" + $mySiteHostUri.Authority
}
Else
{
    Throw "The specified scheme ($($mySiteHostUri.Scheme)) is not supported."
}

New-SPEnterpriseSearchCrawlContentSource `
    -SearchApplication $searchapp `
    -Type SharePoint `
    -Name "User profiles" `
    -StartAddresses $startAddress
```

```PowerShell
cls
```

#### # Configure the search crawl schedules

##### # Configure crawl schedule for "Local SharePoint sites"

```PowerShell
$searchApp = Get-SPEnterpriseSearchServiceApplication `
    -Identity "Search Service Application"

$contentSource = Get-SPEnterpriseSearchCrawlContentSource `
    -SearchApplication $searchApp `
    -Identity "Local SharePoint sites"

Set-SPEnterpriseSearchCrawlContentSource `
    -Identity $contentSource `
    -ScheduleType Full `
    -WeeklyCrawlSchedule `
    -CrawlScheduleStartDateTime "12:00 AM" `
    -CrawlScheduleDaysOfWeek Sunday `
    -CrawlScheduleRunEveryInterval 1

Set-SPEnterpriseSearchCrawlContentSource `
    -Identity $contentSource `
    -ScheduleType Incremental `
    -DailyCrawlSchedule `
    -CrawlScheduleStartDateTime "4:00 AM" `
    -CrawlScheduleRepeatInterval 60 `
    -CrawlScheduleRepeatDuration 1080
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
    -CrawlScheduleStartDateTime "12:00 AM" `
    -CrawlScheduleDaysOfWeek Saturday `
    -CrawlScheduleRunEveryInterval 1

Set-SPEnterpriseSearchCrawlContentSource `
    -Identity $contentSource `
    -ScheduleType Incremental `
    -DailyCrawlSchedule `
    -CrawlScheduleStartDateTime "6:00 AM"
```

```PowerShell
cls
```

## # Create and configure the Web application

### # Set environment variables

```PowerShell
[Environment]::SetEnvironmentVariable(
  "SECURITAS_CLIENT_PORTAL_URL",
  "http://client-test.securitasinc.com",
  "Machine")
```

> **Important**
>
> Restart PowerShell for environment variables to take effect.

```PowerShell
cls
```

### # Add the URL for the SecuritasConnect Web site to the "Local intranet" zone

```PowerShell
[Uri] $uri = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL

[string] $registryKey = ("HKCU:\Software\Microsoft\Windows" `
    + "\CurrentVersion\Internet Settings\ZoneMap\EscDomains\" + $uri.Host)

If ((Test-Path $registryKey) -eq $false)
{
    New-Item $registryKey | Out-Null
}

Set-ItemProperty -Path $registryKey -Name http -Value 1
```

### # Create the Web application

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.661.0\DeploymentFiles\Scripts

& '.\Create Web Application.ps1' -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-web-client**.\
> Expect the previous operation to complete in approximately 1.5 minutes.

```PowerShell
cls
```

### # Restore content database or create initial site collections

#### # Remove content database created with Web application

```PowerShell
Remove-SPContentDatabase WSS_Content_SecuritasPortal -Confirm:$false -Force
```

##### Restore database backup

---

**EXT-SQL02 - SQL Server Management Studio**

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

ALTER DATABASE [WSS_Content_SecuritasPortal]
SET RECOVERY SIMPLE WITH NO_WAIT
GO

USE [WSS_Content_SecuritasPortal]
GO
CREATE USER [EXTRANET\setup-sharepoint]
FOR LOGIN [EXTRANET\setup-sharepoint]
GO
ALTER ROLE [db_owner]
ADD MEMBER [EXTRANET\setup-sharepoint]
GO
```

---

```PowerShell
cls
```

##### # Install SecuritasConnect v3.0 solution

```PowerShell
net use \\ICEMAN\Builds /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$build = "3.0.648.0"

robocopy `
    \\ICEMAN\Builds\Securitas\ClientPortal\$build `
    C:\NotBackedUp\Builds\Securitas\ClientPortal\$build /E

cd C:\NotBackedUp\Builds\Securitas\ClientPortal\$build\DeploymentFiles\Scripts

& '.\Add Solutions.ps1'

& '.\Deploy Solutions.ps1'
```

```PowerShell
cls
```

##### # Test content database

```PowerShell
Test-SPContentDatabase `
    -Name WSS_Content_SecuritasPortal `
    -WebApplication http://client-test.securitasinc.com
```

```PowerShell
cls
```

##### # Attach content database

```PowerShell
Mount-SPContentDatabase `
    -Name WSS_Content_SecuritasPortal `
    -WebApplication http://client-test.securitasinc.com `
    -MaxSiteCount 6000

100.00% : SPContentDatabase Name=WSS_Content_SecuritasPortal
Mount-SPContentDatabase : Upgrade completed with errors.  Review the upgrade log file located in L:\Microsoft Office Servers\15.0\Logs\Upgrade-20160508-155702-832.log.  The number of errors and warnings is listed at the end of the upgrade log file.
At line:1 char:1
+ Mount-SPContentDatabase `
+ ~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidData: (Microsoft.Share...ContentDatabase:SPCmdletMountContentDatabase) [Mount-SPContentDatabase], SPUpgradeException
    + FullyQualifiedErrorId : Microsoft.SharePoint.PowerShell.SPCmdletMountContentDatabase
```

---

**EXT-SQL02 - SQL Server Management Studio**

```Console
ALTER DATABASE [WSS_Content_SecuritasPortal]
SET RECOVERY FULL WITH NO_WAIT
GO
```

---

```PowerShell
cls
```

##### # Remove SecuritasConnect v3.0 solution

```PowerShell
$build = "3.0.648.0"

cd C:\NotBackedUp\Builds\Securitas\ClientPortal\$build\DeploymentFiles\Scripts

& '.\Deactivate Features.ps1'

& '.\Retract Solutions.ps1'

& '.\Delete Solutions.ps1'
```

```PowerShell
cls
```

### # Configure machine key for Web application

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.661.0\DeploymentFiles\Scripts

& '.\Configure Machine Key.ps1' -Verbose
```

### # Configure object cache user accounts

```PowerShell
& '.\Configure Object Cache User Accounts.ps1' -Verbose

iisreset
```

### # Configure the People Picker to support searches across one-way trust

#### # Set the application password used for encrypting credentials

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

```PowerShell
cls
```

#### # Specify the credentials for accessing the trusted forest

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

#### # Modify the permissions on the registry key where the encrypted credentials are stored

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

### # Configure SSL on the Internet zone

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

#### Add a public URL for HTTPS

#### Add an HTTPS binding to the site in IIS

```PowerShell
cls
```

### # Enable disk-based caching for the Web application

```PowerShell
Push-Location C:\inetpub\wwwroot\wss\VirtualDirectories\client-test.securitasinc.com80

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

```PowerShell
Pop-Location
```

### Configure SharePoint groups

(skipped)

### Configure My Site settings in User Profile service application

[http://client-test.securitasinc.com/sites/my](http://client-test.securitasinc.com/sites/my)

```PowerShell
cls
```

## # Deploy the SecuritasConnect solution

### # Create and configure the SecuritasPortal database

---

**EXT-SQL02 - SQL Server Management Studio**

#### -- Restore backup of SecuritasPortal database

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

#### -- Configure permissions for the SecuritasPortal database

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

CREATE USER [EXTRANET\setup-sharepoint]
FOR LOGIN [EXTRANET\setup-sharepoint]
GO
ALTER ROLE [db_owner]
ADD MEMBER [EXTRANET\setup-sharepoint]
GO
```

---

### Create the Branch Managers domain group and add members

(skipped)

### Create the PODS Support domain group and add members

(skipped)

```PowerShell
cls
```

### # Configure logging

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.661.0\DeploymentFiles\Scripts

& '.\Add Event Log Sources.ps1' -Verbose
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

```PowerShell
cls
```

### # Upgrade core site collections

```PowerShell
$webAppUrl = "http://client-test.securitasinc.com"

@("/" , "/sites/cc", "/sites/my", "/sites/Search") |
    ForEach-Object {
        Upgrade-SPSite ($webAppUrl + $_) -VersionUpgrade -Unthrottled
    }
```

```PowerShell
cls
```

### # Install SecuritasConnect solutions and activate the features

#### # Deploy v4.0 solutions

```PowerShell
& '.\Add Solutions.ps1' -Verbose

& '.\Deploy Solutions.ps1' -Verbose

& '.\Activate Features.ps1' -Verbose
```

##### Issue

```PowerShell
Enable-SPFeature : <nativehr>0x80070005</nativehr><nativestack></nativestack>Access denied.
At C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.661.0\DeploymentFiles\Scripts\Activate Features.ps1:115 char:9
+         Enable-SPFeature `
+         ~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidData: (Microsoft.Share...etEnableFeature:SPCmdletEnableFeature) [Enable-SPFeature], UnauthorizedAccessException
    + FullyQualifiedErrorId : Microsoft.SharePoint.PowerShell.SPCmdletEnableFeature
```

##### # Workaround: Configure Web application policy for SharePoint administrators group

```PowerShell
$groupName = "EXTRANET\SharePoint Admins"

$principal = New-SPClaimsPrincipal -Identity $groupName `
    -IdentityType WindowsSecurityGroupName

$claim = $principal.ToEncodedString()

$webApp = Get-SPWebApplication http://client-test.securitasinc.com

$policyRole = $webApp.PolicyRoles.GetSpecialRole(
    [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl)

$policy = $webApp.Policies.Add($claim, $groupName)
$policy.PolicyRoleBindings.Add($policyRole)

$webApp.Update()
```

#### Activate the "Securitas - Application Settings" feature

(skipped)

### Import template site content

(skipped)

### Create users in the SecuritasPortal database

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

```PowerShell
cls
```

### # Configure application settings (e.g. Web service URLs)

```PowerShell
net use \\ICEMAN\Archive /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
Import-Csv "\\ICEMAN\Archive\Clients\Securitas\AppSettings-UAT_2016-04-19.csv" |
    ForEach-Object {.\Set-AppSetting.ps1 $_.Key $_.Value $_.Description -Force}
```

### Configure the SSO credentials for a user

(skipped)

```PowerShell
cls
```

### # Configure C&C landing site

#### # Grant Branch Managers permissions to the C&C landing site

```PowerShell
Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

$site = Get-SPSite "http://client-test.securitasinc.com/sites/cc"
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

#### Hide the Search navigation item on the C&C landing site

(skipped)

```PowerShell
cls
```

#### # Configure the search settings for the C&C landing site

```PowerShell
Start-Process "http://client-test.securitasinc.com/sites/cc"
```

### Configure Google Analytics on the SecuritasConnect Web application

Tracking ID: **UA-25899478-2**

{Begin skipped sections}

## Create and configure C&C site collections

### Create site collection for a Securitas client

### Apply the "Securitas Client Site" template to the top-level site

### Modify the site title, description, and logo

### Update the client site home page

### Create a blog site (optional)

### Create a wiki site (optional)

{End skipped sections}

```PowerShell
cls
```

### # Upgrade C&C site collections

```PowerShell
$webAppUrl = "http://client-test.securitasinc.com"

@("/sites/A123-Systems",
    "/sites/ABC-Company",
    "/sites/DCM-Group",
    "/sites/TE-Connectivity",
    "/sites/Talha-Connect-Test") |
    ForEach-Object {
        $siteUrl = $webAppUrl + $_

        Write-Host "Upgrading site ($siteUrl)..."

        Upgrade-SPSite $siteUrl -VersionUpgrade -Unthrottled

        Disable-SPFeature `
            -Identity Securitas.Portal.Web_SecuritasDefaultMasterPage `
            -Url $siteUrl `
            -Confirm:$false

        Disable-SPFeature `
            -Identity Securitas.Portal.Web_PublishingLayouts `
            -Url $siteUrl `
            -Confirm:$false

        Enable-SPFeature `
            -Identity Securitas.Portal.Web_PublishingLayouts `
            -Url $siteUrl

        Enable-SPFeature `
            -Identity Securitas.Portal.Web_SecuritasDefaultMasterPage `
            -Url $siteUrl
    }
```

```PowerShell
cls
```

## # Configure Web application policy for SharePoint administrators group

```PowerShell
Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

$groupName = "EXTRANET\SharePoint Admins"

$principal = New-SPClaimsPrincipal -Identity $groupName `
    -IdentityType WindowsSecurityGroupName

$claim = $principal.ToEncodedString()

$webApp = Get-SPWebApplication http://client-test.securitasinc.com

$policyRole = $webApp.PolicyRoles.GetSpecialRole(
    [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl)

$policy = $webApp.Policies.Add($claim, $groupName)
$policy.PolicyRoleBindings.Add($policyRole)

$webApp.Update()
```

## Installation prerequisites - Cloud Portal

---

**EXT-DC01**

### # Create service account for Cloud Portal Web application

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

## Backup Cloud Portal in SharePoint 2010 environment

(Download backup files from PROD)

#### Copy the backup files to the SQL Server for the SharePoint 2013 farm

[\\\\ICEMAN\\Archive\\Clients\\Securitas\\Backups](\\ICEMAN\Archive\Clients\Securitas\Backups)

```PowerShell
cls
```

## # Create and configure the Cloud Portal Web application

### # Set environment variables

```PowerShell
[Environment]::SetEnvironmentVariable(
  "SECURITAS_CLOUD_PORTAL_URL",
  "http://cloud-test.securitasinc.com",
  "Machine")
```

> **Important**
>
> Restart PowerShell for environment variable to take effect.

### Copy Cloud Portal build to SharePoint server

### # Create the Web application

```PowerShell
cd C:\NotBackedUp\Securitas\CloudPortal\Dev\Lab2\Code\DeploymentFiles\Scripts

& '.\Create Web Application.ps1' -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-web-cloud**.

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
robocopy `
    '\\ICEMAN\Products\Boost Solutions' `
    'C:\NotBackedUp\Temp\Boost Solutions' /E
```

Extract zip and start **Setup.exe**

```PowerShell
cls
```

### # Restore content database or create initial site collections

#### # Restore content database

##### # Remove content database created with Web application

```PowerShell
Remove-SPContentDatabase WSS_Content_CloudPortal -Confirm:$false -Force
```

##### # Restore database backup

---

**EXT-SQL02 - SQL Server Management Studio**

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

ALTER DATABASE [WSS_Content_CloudPortal]
SET RECOVERY SIMPLE WITH NO_WAIT
GO

USE [WSS_Content_CloudPortal]
GO
CREATE USER [EXTRANET\setup-sharepoint]
FOR LOGIN [EXTRANET\setup-sharepoint]
GO
ALTER ROLE [db_owner]
ADD MEMBER [EXTRANET\setup-sharepoint]
GO
```

---

```PowerShell
cls
```

##### # Install Cloud Portal v1.0 solution

```PowerShell
net use \\ICEMAN\Builds /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$build = "1.0.111.0"

robocopy `
    \\ICEMAN\Builds\Securitas\CloudPortal\$build `
    C:\NotBackedUp\Builds\Securitas\CloudPortal\$build /E

cd C:\NotBackedUp\Builds\Securitas\CloudPortal\$build\DeploymentFiles\Scripts

& '.\Add Solutions.ps1'

& '.\Deploy Solutions.ps1'
```

```PowerShell
cls
```

##### # Test content database

```PowerShell
Test-SPContentDatabase `
    -Name WSS_Content_CloudPortal `
    -WebApplication http://cloud-test.securitasinc.com
```

```PowerShell
cls
```

##### # Attach content database

```PowerShell
Mount-SPContentDatabase `
    -Name WSS_Content_CloudPortal `
    -WebApplication http://cloud-test.securitasinc.com
```

```PowerShell
cls
```

##### # Remove Cloud Portal v1.0 solution

```PowerShell
$build = "1.0.111.0"

cd C:\NotBackedUp\Builds\Securitas\CloudPortal\$build\DeploymentFiles\Scripts

& '.\Deactivate Features.ps1'

& '.\Retract Solutions.ps1'

& '.\Delete Solutions.ps1'
```

```PowerShell
cls
```

### # Configure object cache user accounts

```PowerShell
cd C:\NotBackedUp\Securitas\CloudPortal\Dev\Lab2\Code\DeploymentFiles\Scripts

& '.\Configure Object Cache User Accounts.ps1' -Verbose

iisreset
```

### # Configure the People Picker to support searches across one-way trusts

#### # Specify the credentials for accessing the trusted forest

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

### Configure SSL on the Internet zone

#### Add a public URL for HTTPS

#### Add an HTTPS binding to the site in IIS

```PowerShell
cls
```

### # Enable anonymous access to the site

```PowerShell
& '.\Enable Anonymous Access.ps1'
```

```PowerShell
cls
```

### # Enable disk-based caching for the Web application

```PowerShell
Push-Location C:\inetpub\wwwroot\wss\VirtualDirectories\cloud-test.securitasinc.com80

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

```PowerShell
Pop-Location
```

### Configure SharePoint groups

(skipped)

## Deploy the Cloud Portal solution

### Configure permissions for the SecuritasPortal database

---

**EXT-SQL02 - SQL Server Management Studio**

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

### # Configure logging

```PowerShell
cd C:\NotBackedUp\Securitas\CloudPortal\Dev\Lab2\Code\DeploymentFiles\Scripts

& '.\Add Event Log Sources.ps1' -Verbose
```

```PowerShell
cls
```

### # Upgrade main site collection

```PowerShell
Upgrade-SPSite http://cloud-test.securitasinc.com/ -VersionUpgrade -Unthrottled
```

```PowerShell
cls
```

### # Install Cloud Portal solutions and activate the features

#### # Deploy v2.0 solutions

```PowerShell
& '.\Add Solutions.ps1' -Verbose

& '.\Deploy Solutions.ps1' -Verbose

& '.\Activate Features.ps1' -Verbose
```

### Create and configure the custom sign-in page

#### Create the custom sign-in page

(skipped)

#### Configure the custom sign-in page on the Web application

| Section              | Setting                 | Value                   |
| -------------------- | ----------------------- | ----------------------- |
| **Sign In Page URL** | **Custom Sign In Page** | **/Pages/Sign-In.aspx** |

```PowerShell
cls
```

### # Configure search settings for the Cloud Portal

#### # Hide the Search navigation item on the Cloud Portal top-level site

```PowerShell
Start-Process "http://cloud-test.securitasinc.com"
```

```PowerShell
cls
```

#### # Configure the search settings for the Cloud Portal top-level site

```PowerShell
Start-Process "http://cloud-test.securitasinc.com"
```

##### Issue

Settings menu is not available

##### # Workaround: Configure Web application policy for SharePoint administrators group

```PowerShell
$groupName = "EXTRANET\SharePoint Admins"

$principal = New-SPClaimsPrincipal -Identity $groupName `
    -IdentityType WindowsSecurityGroupName

$claim = $principal.ToEncodedString()

$webApp = Get-SPWebApplication http://cloud-test.securitasinc.com

$policyRole = $webApp.PolicyRoles.GetSpecialRole(
    [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl)

$policy = $webApp.Policies.Add($claim, $groupName)
$policy.PolicyRoleBindings.Add($policyRole)

$webApp.Update()
```

##### Issue

```Text
System.Data.SqlClient.SqlException: Cannot open database "UserProfileService_Profile" requested by the login. The login failed.  Login failed for user 'EXTRANET\s-web-cloud'.
```

##### # Workaround: Configure Web application policy for SharePoint administrators group

---

**EXT-SQL02 - SQL Server Management Studio**

```SQL
USE [UserProfileService_Profile]
GO
CREATE USER [EXTRANET\s-web-cloud] FOR LOGIN [EXTRANET\s-web-cloud]
GO
ALTER ROLE [SPDataAccess] ADD MEMBER [EXTRANET\s-web-cloud]
GO
```

---

### Configure redirect for single-site users

(skipped)

### Create and configure "Online Provisioning" site

(skipped)

### Configure Google Analytics on the Cloud Portal Web application

Tracking ID: **UA-25899478-3**

{Begin skipped sections}

## Create and configure C&C site collections

### Create "Collaboration & Community" site collection

### Apply the "Securitas Client Site" template to the top-level site

### Modify the site title, description, and logo

### Update the C&C site home page

### Create a team collaboration site (optional)

### Create a blog site (optional)

### Create a wiki site (optional)

{End skipped sections}

**TODO:**

```PowerShell
cls
```

## # Install and configure System Center Operations Manager

### # Create certificate for Operations Manager

#### # Create request for Operations Manager certificate

```PowerShell
& "C:\NotBackedUp\Public\Toolbox\Operations Manager\Scripts\New-OperationsManagerCertificateRequest.ps1"
```

#### # Submit certificate request to the Certification Authority

##### # Add Active Directory Certificate Services site to the "Trusted sites" zone and browse to the site

```PowerShell
$adcsUrl = [Uri] "https://cipher01.corp.technologytoolbox.com"

[string] $registryKey = ("HKCU:\Software\Microsoft\Windows" `
    + "\CurrentVersion\Internet Settings\ZoneMap\EscDomains" `
    + "\$($adcsUrl.Host)")

If ((Test-Path $registryKey) -eq $false)
{
    New-Item $registryKey | Out-Null
}

Set-ItemProperty -Path $registryKey -Name $adcsUrl.Scheme -Value 2

Start-Process $adcsUrl.AbsoluteUri
```

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
$certFile = "C:\Users\Administrator\Downloads\certnew.cer"

CertReq.exe -Accept $certFile

Remove-Item $certFile
```

```PowerShell
cls
```

### # Install SCOM agent

---

**FOOBAR8**

```PowerShell
cls
```

#### # Mount the Operations Manager installation media

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

### # Import the certificate into Operations Manager using MOMCertImport

```PowerShell
$hostName = ([System.Net.Dns]::GetHostByName(($env:computerName))).HostName

$certImportToolPath = 'X:\SupportTools\AMD64'

Push-Location "$certImportToolPath"

.\MOMCertImport.exe /SubjectName $hostName

Pop-Location
```

---

**FOOBAR8**

```PowerShell
cls
```

### # Remove the Operations Manager installation media

```PowerShell
Set-VMDvdDrive -ComputerName BEAST -VMName EXT-APP02A -Path $null
```

---

### # Approve manual agent install in Operations Manager

## # Enter a product key and activate Windows

```PowerShell
slmgr /ipk {product key}
```

**Note:** When notified that the product key was set successfully, click **OK**.

```Console
slmgr /ato
```

# EXT-VS2017-DEV3 - Windows Server 2019

Tuesday, November 5, 2019
9:44 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure infrastructure

---

**TT-ADMIN02 - Run as administrator**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "EXT-VS2017-DEV3"
$vmPath = "E:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 100GB `
    -MemoryStartupBytes 4GB `
    -SwitchName "Embedded Team Switch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 4 `
    -AutomaticCheckpointsEnabled $false

Set-VMNetworkAdapterVlan `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Access `
    -VlanId 30

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Install custom Windows Server 2019 image

- On the **Task Sequence** step, select **Windows Server 2019** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **EXT-VS2017-DEV3**.
  - Specify **WORKGROUP**.
  - Click **Next**.
- On the **Applications** step:
  - Select the following applications:
    - **Adobe**
      - **Adobe Reader 8.3.1**
    - **Chrome**
      - **Chrome (64-bit)**
    - **Mozilla**
      - **Firefox (64-bit)**
      - **Thunderbird**
  - Click **Next**.

```PowerShell
cls
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

### Login as .\\foo

```PowerShell
cls
```

### # Configure storage

#### # Set MaxPatchCacheSize to 0 (recommended)

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

| Disk | Drive Letter | Volume Size | VHD Type | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------- | -------------------- | ------------ |
| 0    | C:           | 100 GB      | Dynamic  | 4K                   | OSDisk       |
| 1    | D:           | 20 GB       | Dynamic  | 64K                  | Data01       |
| 2    | L:           | 5 GB        | Dynamic  | 64K                  | Log01        |
| 3    | T:           | 2 GB        | Dynamic  | 64K                  | Temp01       |
| 4    | Z:           | 20 GB       | Dynamic  | 4K                   | Backup01     |

---

**TT-ADMIN02 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Configure storage for the SQL Server

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "EXT-VS2017-DEV3"
$vmPath = "E:\NotBackedUp\VMs\$vmName"
```

##### # Add "Data01" VHD

```PowerShell
$vhdPath = $vmPath + "\Virtual Hard Disks\$vmName" + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 20GB
Add-VMHardDiskDrive `
  -ComputerName $vmHost `
  -VMName $vmName `
  -Path $vhdPath `
  -ControllerType SCSI
```

##### # Add "Log01" VHD

```PowerShell
$vhdPath = $vmPath + "\Virtual Hard Disks\$vmName" + "_Log01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 5GB
Add-VMHardDiskDrive `
  -ComputerName $vmHost `
  -VMName $vmName `
  -Path $vhdPath `
  -ControllerType SCSI
```

##### # Add "Temp01" VHD

```PowerShell
$vhdPath = $vmPath + "\Virtual Hard Disks\$vmName" + "_Temp01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 2GB
Add-VMHardDiskDrive `
  -ComputerName $vmHost `
  -VMName $vmName `
  -Path $vhdPath `
  -ControllerType SCSI
```

##### # Add "Backup01" VHD

```PowerShell
$vhdPath = $vmPath + "\Virtual Hard Disks\$vmName" + "_Backup01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 20GB
Add-VMHardDiskDrive `
  -ComputerName $vmHost `
  -VMName $vmName `
  -Path $vhdPath `
  -ControllerType SCSI
```

---

##### # Format Data01 drive

```PowerShell
Get-Disk 1 |
  Initialize-Disk -PartitionStyle GPT -PassThru |
  New-Partition -DriveLetter D -UseMaximumSize |
  Format-Volume `
    -AllocationUnitSize 64KB `
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
    -AllocationUnitSize 64KB `
    -FileSystem NTFS `
    -NewFileSystemLabel "Log01" `
    -Confirm:$false
```

##### # Format Temp01 drive

```PowerShell
Get-Disk 3 |
  Initialize-Disk -PartitionStyle GPT -PassThru |
  New-Partition -DriveLetter T -UseMaximumSize |
  Format-Volume `
    -AllocationUnitSize 64KB `
    -FileSystem NTFS `
    -NewFileSystemLabel "Temp01" `
    -Confirm:$false
```

##### # Format Backup01 drive

```PowerShell
Get-Disk 4 |
  Initialize-Disk -PartitionStyle GPT -PassThru |
  New-Partition -DriveLetter Z -UseMaximumSize |
  Format-Volume `
    -FileSystem NTFS `
    -NewFileSystemLabel "Backup01" `
    -Confirm:$false
```

### Configure networking

---

**TT-ADMIN02 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Move VM to Extranet VM network

```PowerShell
$vmName = "EXT-VS2017-DEV3"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Extranet-20 VM Network"

Stop-SCVirtualMachine $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork

Start-SCVirtualMachine $vmName
```

---

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

ping EXT-DC10 -f -l 8900
```

```PowerShell
cls
```

### # Join domain

```PowerShell
Add-Computer -DomainName extranet.technologytoolbox.com -Restart
```

---

**EXT-DC10 - Run as domain administrator**

```PowerShell
cls

$vmName = "EXT-VS2017-DEV3"
```

### # Move computer to different OU

```PowerShell
$targetPath = ("OU=Workstations,OU=Resources,OU=Development" `
    + ",DC=extranet,DC=technologytoolbox,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

### # Configure Windows Update

##### # Add machine to security group for Windows Update schedule

```PowerShell
Add-ADGroupMember -Identity "Windows Update - Slot 20" -Members ($vmName + '$')
```

---

```PowerShell
cls
```

## # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

> **Note**
>
> PowerShell remoting must be enabled for remote Windows Update using PoshPAIG ([https://github.com/proxb/PoshPAIG](https://github.com/proxb/PoshPAIG)).

```PowerShell
cls
```

## # Add developers to local Administrators group

```PowerShell
$domain = "EXTRANET"
$groupName = "All Developers"

([ADSI]"WinNT://./Administrators,group").Add(
    "WinNT://$domain/$groupName,group")
```

```PowerShell
cls
```

### # Install and configure SQL Server 2017

#### # Prepare server for SQL Server installation

##### # Add setup account to local Administrators group

```PowerShell
$domain = "EXTRANET"
$username = "setup-sql"

([ADSI]"WinNT://./Administrators,group").Add(
    "WinNT://$domain/$username,user")
```

> **Important**
>
> Sign out and then sign in using the setup account for SQL Server.

##### # Create folder for TempDB data files

```PowerShell
New-Item `
    -Path "T:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Data" `
    -ItemType Directory
```

#### # Install SQL Server 2017

```PowerShell
$imagePath = ("\\EXT-FS01\Products\Microsoft\SQL Server 2017" `
    + "\en_sql_server_2017_developer_x64_dvd_11296168.iso")

$imageDriveLetter = (Mount-DiskImage -ImagePath $ImagePath -PassThru |
    Get-Volume).DriveLetter
```

& ("\$imageDriveLetter" + ":\\setup.exe")

On the **Feature Selection** step, select the following checkbox:

- **Database Engine Services**

On the **Server Configuration** step:

- For the **SQL Server Agent** service, change the **Startup Type** to **Automatic**.
- For the **SQL Server Browser** service, leave the **Startup Type** as **Disabled**.

On the **Database Engine Configuration** step:

- On the **Server Configuration** tab, in the **Specify SQL Server administrators** section, click **Add...** and then add the domain group for SQL Server administrators.
- On the **Data Directories** tab:
  - In the **Data root directory** box, type **D:\\Microsoft SQL Server\\**.
  - In the **User database log directory** box, change the drive letter to **L:** (the value should be **L:\\Microsoft SQL Server\\MSSQL14.MSSQLSERVER\\MSSQL\\Data**).
  - In the **Backup directory** box, change the drive letter to **Z:** (the value should be **Z:\\Microsoft SQL Server\\MSSQL14.MSSQLSERVER\\MSSQL\\Backup**).
- On the **TempDB** tab:
  - Remove the default data directory (**D:\\Microsoft SQL Server\\MSSQL14.MSSQLSERVER\\MSSQL\\Data**).
  - Add the data directory on the **Temp01** volume (**T:\\Microsoft SQL Server\\MSSQL14.MSSQLSERVER\\MSSQL\\Data**).
  - Ensure the **Log directory** is set to **T:\\Microsoft SQL Server\\MSSQL14.MSSQLSERVER\\MSSQL\\Data**.

> **Important**
>
> Wait for the installation to complete.

```PowerShell
cls
```

#### # Install SQL Server Management Studio

```PowerShell
& "\\EXT-FS01\Products\Microsoft\SQL Server Management Studio\18.4\SSMS-Setup-ENU.exe"
```

> **Important**
>
> Wait for the installation to complete.

```PowerShell
cls
```

#### # Configure firewall rules for SQL Server

```PowerShell
New-NetFirewallRule `
    -Name "SQL Server Database Engine" `
    -DisplayName "SQL Server Database Engine" `
    -Group "Technology Toolbox (Custom)" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 1433 `
    -Action Allow
```

#### # Configure permissions on \\Windows\\System32\\LogFiles\\Sum files

```PowerShell
icacls C:\Windows\System32\LogFiles\Sum\Api.chk `
    /grant "NT Service\MSSQLSERVER:(M)"

icacls C:\Windows\System32\LogFiles\Sum\Api.log `
    /grant "NT Service\MSSQLSERVER:(M)"

icacls C:\Windows\System32\LogFiles\Sum\SystemIdentity.mdb `
    /grant "NT Service\MSSQLSERVER:(M)"
```

```PowerShell
cls
```

#### # Install cumulative update for SQL Server

```PowerShell
& "\\EXT-FS01\Products\Microsoft\SQL Server 2017\Patches\CU17\SQLServer2017-KB4515579-x64.exe"
```

#### Configure settings for SQL Server Agent job history log

##### Reference

**SQL SERVER - Dude, Where is the SQL Agent Job History? - Notes from the Field #017**\
From <[https://blog.sqlauthority.com/2014/02/27/sql-server-dude-where-is-the-sql-agent-job-history-notes-from-the-field-017/](https://blog.sqlauthority.com/2014/02/27/sql-server-dude-where-is-the-sql-agent-job-history-notes-from-the-field-017/)>

---

**SQL Server Management Studio**

##### -- Do not limit size of SQL Server Agent job history log

```SQL
USE [msdb]
GO
EXEC msdb.dbo.sp_set_sqlagent_properties @jobhistory_max_rows=-1,
    @jobhistory_max_rows_per_job=-1
GO
```

---

#### Configure SQL Server maintenance

##### Reference

**SQL Server Backup, Integrity Check, and Index and Statistics Maintenance**\
From <[https://ola.hallengren.com/](https://ola.hallengren.com/)>

---

**TT-ADMIN02 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

##### # Download SQL Server maintenance solution files

```PowerShell
New-Item -ItemType Directory -Path C:\NotBackedUp\GitHub
New-Item -ItemType Directory -Path C:\NotBackedUp\GitHub\technology-toolbox

Push-Location C:\NotBackedUp\GitHub\technology-toolbox

git clone https://github.com/technology-toolbox/sql-server-maintenance-solution.git

Pop-Location
```

---

---

**SQL Server Management Studio**

##### -- Create SqlMaintenance database

```SQL
CREATE DATABASE SqlMaintenance
GO
```

---

##### Create maintenance table, stored procedures, and jobs

Execute script in SQL Server Management Studio: **MaintenanceSolution.sql**

##### Configure schedules for SqlMaintenance jobs

Execute script in SQL Server Management Studio: **JobSchedules.sql**

### Configure server after SQL Server installation

#### Login as .\\foo

```PowerShell
cls
```

#### # Remove setup account from local Administrators group

```PowerShell
$domain = "EXTRANET"
$username = "setup-sql"

([ADSI]"WinNT://./Administrators,group").Remove(
    "WinNT://$domain/$username,user")
```

```PowerShell
cls
```

## # Install Visual Studio Code

```PowerShell
net use \\EXT-FS01\IPC$ /USER:EXTRANET\jjameson-admin
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$setupPath = "\\EXT-FS01\Products\Microsoft\Visual Studio Code" `
    + "\VSCodeSetup-x64-1.39.2.exe"

$arguments = "/silent" `
    + " /mergetasks='!runcode,addcontextmenufiles,addcontextmenufolders" `
        + ",addtopath'"

Start-Process `
    -FilePath $setupPath `
    -ArgumentList $arguments `
    -Wait
```

> **Important**
>
> Wait for the installation to complete.

### Issue

**Installer doesn't disable launch of VScode even when installing with /mergetasks=!runcode**\
From <[https://github.com/Microsoft/vscode/issues/46350](https://github.com/Microsoft/vscode/issues/46350)>

### Modify Visual Studio Code shortcut to use custom extension and user data locations

```Console
"C:\Program Files\Microsoft VS Code\Code.exe" --extensions-dir "C:\NotBackedUp\vscode-data\extensions" --user-data-dir "C:\NotBackedUp\vscode-data\user-data"
```

```Console
cls
```

### # Install Visual Studio Code extensions

##### # Temporarily enable firewall rule for copying files to server

```PowerShell
Enable-NetFirewallRule -DisplayName "File and Printer Sharing (SMB-In)"
```

---

**STORM - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Copy extensions and user data for Visual Studio Code

```PowerShell
$computer = "EXT-VS2017-DEV3.extranet.technologytoolbox.com"
$source = "C:\NotBackedUp\vscode-data"
$destination = "\\$computer\C$\NotBackedUp\vscode-data"

robocopy $source $destination /E /XD git-for-windows /MIR /NP
```

---

```PowerShell
cls
```

##### # Disable firewall rule for copying files to server

```PowerShell
Disable-NetFirewallRule -DisplayName "File and Printer Sharing (SMB-In)"
```

## Install and configure Visual Studio 2017

### Login as .\\foo

### # Launch Visual Studio 2017 setup

```PowerShell
net use \\EXT-FS01\IPC$ /USER:EXTRANET\jjameson-admin
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$setupPath = "\\EXT-FS01\Products\Microsoft\Visual Studio 2017\Enterprise" `
    + "\vs_setup.exe"

Start-Process -FilePath $setupPath -Wait
```

### Install Visual Studio 2017

Select the following workloads:

- **.NET desktop development**
- **Desktop development with C++**
- **Universal Windows Platform development**
- **ASP.NET and web development**
- **Azure development**
- **Python development**
- **Node.js development**
- **Data storage and processing**
- **Data science and analytical applications**
- **Office/SharePoint development**
- **Mobile development with .NET**
- **Game development with Unity**
- **Mobile development with JavaScript**
- **Mobile development with C++**
- **Game development with C++**
- **Visual Studio extension development**
- **Linux development with C++**
- **.NET Core cross-platform development**

```PowerShell
cls
```

### # Add items to Trusted Sites in Internet Explorer for Visual Studio login

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-InternetSecurityZoneMapping.ps1 `
    -Zone TrustedSites `
    -Patterns https://login.microsoftonline.com, https://aadcdn.msauth.net, `
        https://aadcdn.msftauth.net
```

### Install .NET Core 2.2 SDK

[https://dotnet.microsoft.com/download/thank-you/dotnet-sdk-2.2.109-windows-x64-installer](https://dotnet.microsoft.com/download/thank-you/dotnet-sdk-2.2.109-windows-x64-installer)

#### Reference

**Download .NET Core 2.2**\
From <[https://dotnet.microsoft.com/download/dotnet-core/2.2](https://dotnet.microsoft.com/download/dotnet-core/2.2)>

```PowerShell
cls
```

## # Install and configure Git

### # Install Git

```PowerShell
net use \\EXT-FS01\IPC$ /USER:EXTRANET\jjameson-admin
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$setupPath = "\\EXT-FS01\Products\Git\Git-2.24.0-64-bit.exe"

Start-Process -FilePath $setupPath -Wait
```

On the **Choosing the default editor used by Git** step, select **Use the Nano editor by default**.

> **Important**
>
> Wait for the installation to complete and restart PowerShell for environment changes to take effect.

```Console
exit
```

### # Configure symbolic link (e.g. for bash shell)

```PowerShell
Push-Location C:\NotBackedUp\Public\Toolbox\cmder\vendor

cmd /c mklink /J git-for-windows "C:\Program Files\Git"

Pop-Location
```

### # Configure Git to use SourceGear DiffMerge

```PowerShell
git config --global diff.tool diffmerge

git config --global difftool.diffmerge.cmd  '"C:/NotBackedUp/Public/Toolbox/DiffMerge/x64/sgdm.exe \"$LOCAL\" \"$REMOTE\"'
```

#### Reference

**Git for Windows (MSysGit) or Git Cmd**\
From <[https://sourcegear.com/diffmerge/webhelp/sec__git__windows__msysgit.html](https://sourcegear.com/diffmerge/webhelp/sec__git__windows__msysgit.html)>

## Install GitHub Desktop

```PowerShell
cls
```

## # Install and configure Node.js

### # Install Node.js

```PowerShell
net use \\EXT-FS01\IPC$ /USER:EXTRANET\jjameson-admin
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$setupPath = "\\EXT-FS01\Products\node.js\node-v12.13.0-x64.msi"

Start-Process -FilePath $setupPath -Wait
```

> **Important**
>
> Wait for the installation to complete. Restart PowerShell for the change to PATH environment variable to take effect.

```Console
exit
```

### # Change NPM file locations to avoid issues with redirected folders

```PowerShell
notepad "C:\Program Files\nodejs\node_modules\npm\npmrc"
```

---

**C:\\Program Files\\nodejs\\node_modules\\npm\\npmrc**

```Text
;prefix=${APPDATA}\npm
prefix=${LOCALAPPDATA}\npm
cache=${LOCALAPPDATA}\npm-cache
```

---

```PowerShell
cls
```

## # Install PowerShell modules

### # Install posh-git module (e.g. for Powerline Git prompt customization)

#### # Install NuGet package provider (to bypass prompt when installing posh-git module)

```PowerShell
Install-PackageProvider NuGet -MinimumVersion '2.8.5.201' -Force
```

#### # Trust PSGallery repository (to bypass prompt when installing posh-git module)

```PowerShell
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
```

#### # Install posh-git module

```PowerShell
Install-Module -Name 'posh-git'
```

### Upgrade Azure PowerShell module

#### Remove AzureRM module

1. Open **Programs and Features**
2. Uninstall **Microsoft Azure PowerShell - April 2018**

```PowerShell
cls
```

#### # Install new Azure PowerShell module

```PowerShell
Install-Module -Name Az -AllowClobber -Scope AllUsers
```

```PowerShell
cls
```

## # Update PowerShell help

```PowerShell
Update-Help
```

## Install updates using Windows Update

> **Note**
>
> Repeat until there are no updates available for the computer.

```PowerShell
cls
```

## # Copy cmder configuration

##### # Temporarily enable firewall rule for copying files to server

```PowerShell
Enable-NetFirewallRule -DisplayName "File and Printer Sharing (SMB-In)"
```

---

**STORM - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Copy cmder configuration

```PowerShell
$computer = "EXT-VS2017-DEV3.extranet.technologytoolbox.com"
$source = "C:\NotBackedUp\Public\Toolbox\cmder"
$destination = "\\$computer\C$\NotBackedUp\Public\Toolbox\cmder"

robocopy $source $destination /E /XD git-for-windows /MIR /NP
```

---

```PowerShell
cls
```

##### # Disable firewall rule for copying files to server

```PowerShell
Disable-NetFirewallRule -DisplayName "File and Printer Sharing (SMB-In)"
```

## Configure profile for TECHTOOLBOX\\jjameson

> **Important**
>
> Login as TECHTOOLBOX\\jjameson

```PowerShell
cls
```

### # Add items to Trusted Sites in Internet Explorer for Visual Studio login

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-InternetSecurityZoneMapping.ps1 `
    -Zone TrustedSites `
    -Patterns https://login.microsoftonline.com, https://aadcdn.msauth.net, `
        https://aadcdn.msftauth.net
```

```PowerShell
cls
```

### # Configure e-mail and name for Git

```PowerShell
git config --global user.email "jjameson@technologytoolbox.com"
git config --global user.name "Jeremy Jameson"
```

```PowerShell
cls
```

### # Add NPM "global" location to PATH environment variable

```PowerShell
Set-ExecutionPolicy RemoteSigned -Scope Process -Force

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-PathFolders.ps1 `
    -Folders "$env:LOCALAPPDATA\npm" `
    -EnvironmentVariableTarget User
```

> **Important**
>
> Restart PowerShell for the change to PATH environment variable to take effect.

```Console
exit
```

### Install global NPM packages

> **Important**
>
> Install global NPM packages using a non-elevated instance of PowerShell (to avoid issues when subsequently running the npm install command as a "normal" user).

---

**Non-elevated PowerShell instance**

```PowerShell
cls
```

### # Install Angular CLI

```PowerShell
npm install --global --no-optional @angular/cli@7.3.9
```

### # Install Create React App

```PowerShell
npm install --global --no-optional create-react-app@3.2.0
```

### # Install rimraf

```PowerShell
npm install --global --no-optional rimraf@3.0.0
```

### # Install Yeoman, Gulp, and web app generator

```PowerShell
npm install --global --no-optional yo gulp-cli generator-webapp
```

---

#### Reference

**Web app generator**\
From <[https://www.npmjs.com/package/generator-webapp](https://www.npmjs.com/package/generator-webapp)>

## Baseline virtual machine

---

**TT-ADMIN02 - Run as administrator**

```PowerShell
cls
```

### # Checkpoint VM

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "EXT-VS2017-DEV3"
$checkpointName = "Baseline"

Stop-VM -ComputerName $vmHost -Name $vmName

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName $checkpointName
```

---

## Back up virtual machine

**TODO:**

```PowerShell
cls
```

## # Clone repo for Pluralsight course

```PowerShell
mkdir C:\NotBackedUp\GitHub\jeremy-jameson

Push-Location C:\NotBackedUp\GitHub\jeremy-jameson

git clone https://github.com/jeremy-jameson/SecuringAspNetCore2WithOAuth2AndOIDC.git

Pop-Location
```

```PowerShell
cls
```

## # Clone repo for IdentityServer4.Admin

```PowerShell
mkdir C:\NotBackedUp\GitHub\skoruba

Push-Location C:\NotBackedUp\GitHub\skoruba

git clone https://github.com/skoruba/IdentityServer4.Admin.git

Pop-Location
```

```PowerShell
cls
```

## # Enter a product key and activate Windows

```PowerShell
slmgr /ipk {product key}
```

> **Note**
>
> When notified that the product key was set successfully, click **OK**.

```Console
slmgr /ato
```

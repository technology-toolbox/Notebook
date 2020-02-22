# EXT-FOOBAR2

Tuesday, May 1, 2018
5:41 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

Install SecuritasConnect v4.0

## Deploy and configure server infrastructure

### Copy Windows Server installation files to file share

(skipped)

### Install Windows Server 2012 R2

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "EXT-FOOBAR2"
$vmPath = "E:\NotBackedUp\VMs\$vmName"
$vhdPath = "$vmPath\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 80GB `
    -MemoryStartupBytes 24GB `
    -SwitchName "Embedded Team Switch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 2

Start-VM -ComputerName $vmHost -Name $vmName
```

---

#### Install custom Windows Server 2012 R2 image

- On the **Task Sequence** step, select **Windows Server 2012 R2** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **EXT-FOOBAR2**.
  - Select **Join a workgroup**.
  - In the **Workgroup** box, type **WORKGROUP**.
  - Click **Next**.
- On the **Applications** step, ensure no items are selected and click **Next**.

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

### # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

### # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

### Set MaxPatchCacheSize to 0 (recommended)

(skipped -- since this is configured in the custom Windows Server 2012 R2 image)

### # Enable performance counters for Server Manager

```PowerShell
$taskName = "\Microsoft\Windows\PLA\Server Manager Performance Monitor"

Enable-ScheduledTask -TaskName $taskName

logman start "Server Manager Performance Monitor"
```

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Set first boot device to hard drive

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "EXT-FOOBAR2"

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

#### Configure static IP address

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

##### # Configure static IP address using VMM

```PowerShell
$vmName = "EXT-FOOBAR2"
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

---

**EXT-DC08 - Run as EXTRANET\\jjameson-admin**

```PowerShell
cls
```

### # Move computer to different OU

```PowerShell
$computerName = "EXT-FOOBAR2"
$targetPath = "OU=SharePoint Servers,OU=Servers,OU=Resources,OU=Development" `
    + ",DC=extranet,DC=technologytoolbox,DC=com"

Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath
```

### # Configure Windows Update

#### # Add machine to security group for Windows Update schedule

```PowerShell
Add-ADGroupMember -Identity "Windows Update - Slot 4" -Members ($computerName + '$')
```

---

### DEV - Configure VM storage, processors, and memory

| Disk | Drive Letter | Volume Size | VHD Type | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------- | -------------------- | ------------ |
| 0    | C:           | 80 GB       | Dynamic  | 4K                   | OSDisk       |
| 1    | D:           | 210 GB      | Fixed    | 64K                  | Data01       |
| 2    | L:           | 25 GB       | Fixed    | 64K                  | Log01        |
| 3    | T:           | 4 GB        | Fixed    | 64K                  | Temp01       |
| 4    | Z:           | 150 GB      | Dynamic  | 4K                   | Backup01     |

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Create Data01, Log01, Temp01, and Backup01 VHDs

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "EXT-FOOBAR2"
$vmStoragePath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks"

$vhdPath = "$vmStoragePath\$vmName" + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Fixed -SizeBytes 210GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ControllerType SCSI `
    -Path $vhdPath

$vhdPath = "$vmStoragePath\$vmName" + "_Log01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Fixed -SizeBytes 25GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ControllerType SCSI `
    -Path $vhdPath

$vhdPath = "$vmStoragePath\$vmName" + "_Temp01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Fixed -SizeBytes 4GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ControllerType SCSI `
    -Path $vhdPath

$vhdPath = "$vmStoragePath\$vmName" + "_Backup01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 150GB
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

#### # Initialize disks and format volumes

##### # Format Data01 drive

```PowerShell
Get-Disk 1 |
    Initialize-Disk -PartitionStyle MBR -PassThru |
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
    Initialize-Disk -PartitionStyle MBR -PassThru |
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
    Initialize-Disk -PartitionStyle MBR -PassThru |
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
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -DriveLetter Z -UseMaximumSize |
    Format-Volume `
        -FileSystem NTFS `
        -NewFileSystemLabel "Backup01" `
        -Confirm:$false
```

### Install latest service pack and updates

### Create service accounts

(skipped)

### Create Active Directory container to track SharePoint 2013 installations

(skipped)

```PowerShell
cls
```

### # Install and configure SQL Server 2014

#### # Prepare server for SQL Server installation

##### # Add SharePoint setup account to local Administrators group

```PowerShell
$domain = "EXTRANET"
$username = "setup-sharepoint-dev"

([ADSI]"WinNT://./Administrators,group").Add(
    "WinNT://$domain/$username,user")
```

#### Install SQL Server 2014

> **Important**
>
> Login as **EXTRANET\\setup-sharepoint-dev **to install SQL Server.

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

##### # Mount SQL Server 2014 installation media

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "EXT-FOOBAR2"
$isoName = "en_sql_server_2014_developer_edition_with_service_pack_2_x64_dvd_8967821.iso"
```

###### # Add virtual DVD drive

```PowerShell
Add-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName
```

###### # Refresh virtual machine in VMM

```PowerShell
Read-SCVirtualMachine -VM $vmName
```

###### # Mount installation media in virtual DVD drive

```PowerShell
$iso = Get-SCISO | where { $_.Name -eq $isoName }

Get-SCVirtualDVDDrive -VM $vmName |
    Set-SCVirtualDVDDrive -ISO $iso -Link
```

---

##### # Install SQL Server

```PowerShell
& E:\setup.exe
```

> **Important**
>
> Wait for the installation to complete and restart the computer (if necessary).

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

##### # Dismount SQL Server 2014 installation media

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "EXT-FOOBAR2"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

---

```PowerShell
cls
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

---

**SQL Server Management Studio**

#### -- Configure TempDB data and log files

```SQL
ALTER DATABASE [tempdb]
  MODIFY FILE
  (
    NAME = N'tempdev'
    , SIZE = 512MB
    , MAXSIZE = 768MB
    , FILEGROWTH = 128MB
  );

DECLARE @dataPath VARCHAR(300);

SELECT
  @dataPath = REPLACE([filename], '.mdf','')
FROM
  sysaltfiles s
WHERE
  name = 'tempdev';

DECLARE @sqlStatement NVARCHAR(500);

SELECT @sqlStatement =
  N'ALTER DATABASE [tempdb]'
    + 'ADD FILE'
    + '('
      + 'NAME = N''tempdev2'''
      + ', FILENAME = ''' + @dataPath + '2.mdf'''
      + ', SIZE = 512MB'
      + ', MAXSIZE = 768MB'
      + ', FILEGROWTH = 128MB'
    + ')';

EXEC sp_executesql @sqlStatement;

SELECT @sqlStatement =
  N'ALTER DATABASE [tempdb]'
    + 'ADD FILE'
    + '('
      + 'NAME = N''tempdev3'''
      + ', FILENAME = ''' + @dataPath + '3.mdf'''
      + ', SIZE = 512MB'
      + ', MAXSIZE = 768MB'
      + ', FILEGROWTH = 128MB'
    + ')';

EXEC sp_executesql @sqlStatement;

SELECT @sqlStatement =
  N'ALTER DATABASE [tempdb]'
    + 'ADD FILE'
    + '('
      + 'NAME = N''tempdev4'''
      + ', FILENAME = ''' + @dataPath + '4.mdf'''
      + ', SIZE = 512MB'
      + ', MAXSIZE = 768MB'
      + ', FILEGROWTH = 128MB'
    + ')';

EXEC sp_executesql @sqlStatement;
ALTER DATABASE [tempdb]
  MODIFY FILE (
    NAME = N'templog',
    SIZE = 50MB,
    FILEGROWTH = 10MB
  )

GO
```

#### -- Configure "Max Degree of Parallelism" for SharePoint

```SQL
EXEC sys.sp_configure N'show advanced options', N'1'
RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'max degree of parallelism', N'1'
RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'show advanced options', N'0'
RECONFIGURE WITH OVERRIDE
GO
```

#### -- DEV - Change databases to Simple recovery model

-- (skipped -- since this environment has a full copy of Production)

#### -- DEV - Constrain maximum memory for SQL Server

```SQL
EXEC sys.sp_configure N'show advanced options', N'1'
RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'min server memory (MB)', N'4096'
GO
EXEC sys.sp_configure N'max server memory (MB)', N'8192'
GO
EXEC sys.sp_configure N'show advanced options', N'0'
RECONFIGURE WITH OVERRIDE
GO
```

---

## Install SharePoint Server 2013

### Download SharePoint 2013 prerequisites to file share

(skipped - since this was completed previously)

```PowerShell
cls
```

### # Install SharePoint 2013 prerequisites on farm servers

#### # Copy SharePoint Server 2013 prerequisite files to SharePoint server

#### # Temporarily enable firewall rule to allow files to be copied to server

```PowerShell
Enable-NetFirewallRule -DisplayName "File and Printer Sharing (SMB-in)"
```

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Copy SharePoint Server 2013 prerequisite files

```PowerShell
$computerName = "EXT-FOOBAR2.extranet.technologytoolbox.com"

$source = "\\TT-FS01\Products\Microsoft\SharePoint 2013" `
    + "\PrerequisiteInstallerFiles_SP1"

$destination = "\\$computerName" `
    + "\C`$\NotBackedUp\Temp\PrerequisiteInstallerFiles_SP1"

robocopy $source $destination /E
```

---

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Mount SharePoint Server 2013 installation media

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "EXT-FOOBAR2"
$isoName = "en_sharepoint_server_2013_with_sp1_x64_dvd_3823428.iso"

$iso = Get-SCISO | where { $_.Name -eq $isoName }

Get-SCVirtualDVDDrive -VM $vmName |
    Set-SCVirtualDVDDrive -ISO $iso -Link
```

---

```PowerShell
cls
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

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Checkpoint VM

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "EXT-FOOBAR2"
$snapshotName = "Before - Install SharePoint Server 2013 on farm servers"

Stop-VM -ComputerName $vmHost -Name $vmName

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName $snapshotName

Start-VM -ComputerName $vmHost -Name $vmName
```

---

#### # HACK: Enable Windows Installer verbose logging (to avoid "ArpWrite timing" bug in SharePoint installation)

```PowerShell
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v Debug /t REG_DWORD /d 7 /f

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v Logging /t REG_SZ /d voicewarmup! /f

Restart-Service msiserver
```

> **Note**
>
> The **x** logging option ("Extra debugging information") does not appear to be necessary to avoid the bug. However, the **!** option ("Flush each line to the log") is definitely required. Without it (i.e. specifying **voicewarmup**) the ArpWrite error was still encountered.

##### References

**Sharepoint Server 2013 installation: why ArpWrite action fails?**\
Pasted from <[http://sharepoint.stackexchange.com/questions/68620/sharepoint-server-2013-installation-why-arpwrite-action-fails](http://sharepoint.stackexchange.com/questions/68620/sharepoint-server-2013-installation-why-arpwrite-action-fails)>

**How to enable Windows Installer logging**\
From <[https://support.microsoft.com/en-us/kb/223300](https://support.microsoft.com/en-us/kb/223300)>

"...steps you can use to gather a Windows Installer verbose log file..."\
Pasted from <[http://blogs.msdn.com/b/astebner/archive/2005/03/29/403575.aspx](http://blogs.msdn.com/b/astebner/archive/2005/03/29/403575.aspx)>

```PowerShell
cls
```

#### # Install SharePoint Server 2013 on farm servers

```PowerShell
& E:\setup.exe
```

> **Important**
>
> Wait for the installation to complete.

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Dismount SharePoint Server 2013 installation media

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "EXT-FOOBAR2"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

---

```PowerShell
cls
```

#### # HACK: Disable Windows Installer verbose logging

```PowerShell
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v Debug /f

reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v Logging /f

Restart-Service msiserver
```

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

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Update VM snapshot

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "EXT-FOOBAR2"

Stop-VM -ComputerName $vmHost -Name $vmName
```

#### # Delete previous VM snapshot

```PowerShell
Write-Host "Deleting snapshot..." -NoNewline

Remove-VMSnapshot -ComputerName $vmHost -VMName $vmName

Write-Host "Waiting a few seconds for merge to start..."
Start-Sleep -Seconds 5

while (Get-VM -ComputerName $vmHost -Name $vmName |
    Where Status -eq "Merging disks") {
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 5
}

Write-Host
```

```PowerShell
cls
```

#### # Create new VM snapshot

```PowerShell
$snapshotName = "Before - Install Cumulative Update for SharePoint Server 2013"

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName $snapshotName

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Install Cumulative Update for SharePoint Server 2013

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Download update

```PowerShell
$patch = "15.0.4963.1001 - SharePoint 2013 September 2017 CU"
$computerName = "EXT-FOOBAR2.extranet.technologytoolbox.com"

$source = "\\TT-FS01\Products\Microsoft\SharePoint 2013\Patches\$patch"
$destination = "\\$computerName\C`$\NotBackedUp\Temp\$patch"

robocopy $source $destination /E
```

---

```PowerShell
cls
```

#### # Install update

```PowerShell
$patch = "15.0.4963.1001 - SharePoint 2013 September 2017 CU"

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

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Download update

```PowerShell
$patch = "Cumulative Update 7"
$computerName = "EXT-FOOBAR2.extranet.technologytoolbox.com"

$source = "\\TT-FS01\Products\Microsoft\AppFabric 1.1\Patches\$patch"
$destination = "\\$computerName\C`$\NotBackedUp\Temp\$patch"

robocopy $source $destination /E
```

---

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

```PowerShell
cls
```

## # Install and configure additional software

### # Install Prince on front-end Web servers

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Copy Prince installation files

```PowerShell
$computerName = "EXT-FOOBAR2.extranet.technologytoolbox.com"

$source = "\\TT-FS01\Products\Prince"
$destination = "\\$computerName\C`$\NotBackedUp\Temp\Prince"

robocopy $source $destination /E
```

---

```PowerShell
& "C:\NotBackedUp\Temp\Prince\prince-7.1-setup.exe"
```

> **Important**
>
> Wait for the installation to complete.

```PowerShell
cls
```

#### # Configure Prince license

```PowerShell
Copy-Item `
    C:\NotBackedUp\Temp\Prince\Prince-license.dat `
    'C:\Program Files (x86)\Prince\Engine\license\license.dat'
```

1. In the **Prince** window, click the **Help** menu and then click **License**.
2. In the **Prince License** window:
   1. Click **Open** and then locate the license file (**C:\\NotBackedUp\\Temp\\Prince\\Prince-license.dat**).
   2. Click **Accept** to save the license information.
   3. Verify the license information and then click **Close**.
3. Close the Prince application.

```PowerShell
cls
```

#### # Remove Prince installation files

```PowerShell
Remove-Item "C:\NotBackedUp\Temp\Prince" -Recurse
```

### DEV - Install Visual Studio 2015 with Update 3

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Mount Visual Studio 2015 installation media

```PowerShell
$vmName = "EXT-FOOBAR2"
$isoName = "en_visual_studio_enterprise_2015_with_update_3_x86_x64_dvd_8923288.iso"

$iso = Get-SCISO | where { $_.Name -eq $isoName }

Get-SCVirtualDVDDrive -VM $vmName |
    Set-SCVirtualDVDDrive -ISO $iso -Link
```

---

```PowerShell
& E:\vs_enterprise.exe
```

**Custom** installation option:

- **Microsoft Office Developer Tools**
- **Microsoft SQL Server Data Tools**
- **Microsoft Web Developer Tools**

> **Important**
>
> Wait for the installation to complete and restart the computer if prompted to do so.

TODO:

### DEV - Enter product key for Visual Studio

1. Start Visual Studio.
2. On the **Help** menu, click **Register Product**.
3. In the **Sign in to Visual Studio** window, click **Unlock with a Product Key**.
4. In the **Enter a product key** window, type the product key and click **Apply**.
5. In the **Sign in to Visual Studio** window, click **Close**.

### DEV - Install update for Office developer tools in Visual Studio

> **Note**
>
> Add **[https://www.microsoft.com](https://www.microsoft.com)** and **[https://webpihandler.azurewebsites.net](https://webpihandler.azurewebsites.net)** to **Trusted sites** zone:
>
> ```PowerShell
> C:\NotBackedUp\Public\Toolbox\PowerShell\Add-InternetSecurityZoneMapping.ps1 `
>     -Zone TrustedSites `
>     -Patterns https://www.microsoft.com, https://webpihandler.azurewebsites.net
> ```

Update:** Microsoft Office Developer Tools Update 2 for Visual Studio 2015**\
File: **OfficeToolsForVS2015.3f.3fen.exe**

### DEV - Install update for SQL Server database projects in Visual Studio

> **Note**
>
> Add **[https://download.microsoft.com](https://download.microsoft.com)** to **Trusted sites** zone:
>
> ```PowerShell
> C:\NotBackedUp\Public\Toolbox\PowerShell\Add-InternetSecurityZoneMapping.ps1 `
>     -Zone TrustedSites `
>     -Patterns https://download.microsoft.com
> ```

Update:** Microsoft SQL Server Data Tools (SSDT) Update**\
File: **SSDTSetup.exe**

> **Important**
>
> Wait for the installation to complete and restart the computer if prompted to do so.

### DEV - Install Productivity Power Tools for Visual Studio

### DEV - Install Microsoft Office 2016 (Recommended)

(skipped)

### DEV - Install Microsoft SharePoint Designer 2013 (Recommended)

(skipped)

### DEV - Install Microsoft Visio 2016 (Recommended)

(skipped)

### DEV - Install additional browsers and software (Recommended)

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Copy installation files

```PowerShell
$computerName = "EXT-FOOBAR2.extranet.technologytoolbox.com"
```

##### # Copy installation files for Mozilla Firefox

```PowerShell
$filter = "Firefox Setup 59.0.2.exe"
$source = "\\TT-FS01\Products\Mozilla\Firefox\x64"
$destination = "\\$computerName\C`$\NotBackedUp\Temp"

robocopy $source $destination $filter /E
```

##### # Copy installation files for Google Chrome

```PowerShell
$filter = "GoogleChromeStandaloneEnterprise64.msi"
$source = "\\TT-FS01\Products\Google\Chrome\GoogleChromeEnterpriseBundle64" `
    + "\Installers"

$destination = "\\$computerName\C`$\NotBackedUp\Temp"

robocopy $source $destination $filter /E
```

##### # Copy installation files for Adobe Reader

```PowerShell
$filter = "AdbeRdr*83*"
$source = "\\TT-FS01\Products\Adobe"
$destination = "\\$computerName\C`$\NotBackedUp\Temp"

robocopy $source $destination $filter /E
```

##### # Copy installation files for Microsoft Message Analyzer

```PowerShell
$filter = "MessageAnalyzer64.msi"
$source = "\\TT-FS01\Products\Microsoft\Message Analyzer 1.4"
$destination = "\\$computerName\C`$\NotBackedUp\Temp"

robocopy $source $destination $filter /E
```

---

```PowerShell
cls
```

#### # Install Mozilla Firefox

```PowerShell
$installerPath = "C:\NotBackedUp\Temp\Firefox Setup 59.0.2.exe"
$installerArguments = "-ms"

Start-Process `
    -FilePath $installerPath `
    -ArgumentList $installerArguments `
    -Wait
```

#### # Install Google Chrome

```PowerShell
$installerPath = "C:\NotBackedUp\Temp" `
    + "\GoogleChromeStandaloneEnterprise64.msi"

$installerArguments = "/q"

Start-Process `
    -FilePath msiexec.exe `
    -ArgumentList "/i `"$installerPath`" $installerArguments" `
    -Wait
```

#### # Install Adobe Reader

##### # Install Adobe Reader 8.3

```PowerShell
$installerPath = "C:\NotBackedUp\Temp\AdbeRdr830_en_US.msi"
$installerArguments = "/q"

Start-Process `
    -FilePath msiexec.exe `
    -ArgumentList "/i `"$installerPath`" $installerArguments" `
    -Wait
```

##### # Install Adobe Reader 8.3.1 Update

```PowerShell
$installerPath = "C:\NotBackedUp\Temp\AdbeRdrUpd831_all_incr.msp"
$installerArguments = "/q"

Start-Process `
    -FilePath msiexec.exe `
    -ArgumentList "/update `"$installerPath`" $installerArguments" `
    -Wait
```

#### # Install Microsoft Message Analyzer

```PowerShell
$installerPath = "C:\NotBackedUp\Temp\MessageAnalyzer64.msi"
$installerArguments = "/q"

Start-Process `
    -FilePath msiexec.exe `
    -ArgumentList "/i `"$installerPath`" $installerArguments" `
    -Wait
```

```PowerShell
cls
```

#### # Remove installation files

```PowerShell
Remove-Item "C:\NotBackedUp\Temp\Firefox Setup 59.0.2.exe"
Remove-Item C:\NotBackedUp\Temp\GoogleChromeStandaloneEnterprise64.msi
Remove-Item C:\NotBackedUp\Temp\AdbeRdr*83*
Remove-Item C:\NotBackedUp\Temp\MessageAnalyzer64.msi
```

### Install additional service packs and updates

> **Important**
>
> Wait for the updates to be installed and restart the server (if necessary).

### # Clean up Windows Update files

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse
```

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Eject media from virtual DVD drive

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "EXT-FOOBAR2"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

### # Update VM snapshot

```PowerShell
Stop-VM -ComputerName $vmHost -Name $vmName
```

#### # Delete previous VM snapshot

```PowerShell
Write-Host "Deleting snapshot..." -NoNewline

Remove-VMSnapshot -ComputerName $vmHost -VMName $vmName

Write-Host "Waiting a few seconds for merge to start..."
Start-Sleep -Seconds 5

while (Get-VM -ComputerName $vmHost -Name $vmName |
    Where Status -eq "Merging disks") {
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 5
}

Write-Host
```

#### # Create new VM snapshot

```PowerShell
$snapshotName = "Before - Create and configure SharePoint farm"

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName $snapshotName

Start-VM -ComputerName $vmHost -Name $vmName
```

---

## # Create and configure SharePoint farm

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

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Copy build from TFS drop location

```PowerShell
$newBuild = "4.0.705.0"
$computerName = "EXT-FOOBAR2.extranet.technologytoolbox.com"

$sourcePath = "\\TT-FS01\Builds\Securitas\ClientPortal\$newBuild"
$destPath = "\\$computerName\Builds\ClientPortal\$newBuild"

robocopy $sourcePath $destPath /E
```

---

### # Create SharePoint farm

```PowerShell
cd C:\Shares\Builds\ClientPortal\4.0.705.0\DeploymentFiles\Scripts

$currentUser = whoami

If ($currentUser -eq "EXTRANET\setup-sharepoint-dev")
{
    & '.\Create Farm.ps1' -CentralAdminAuthProvider NTLM -Verbose
}
Else
{
    Throw "Incorrect user"
}
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-sp-farm-dev**.\
> Expect the previous operation to complete in approximately 8 minutes.

### Add Web servers to SharePoint farm

(skipped)

### Add SharePoint Central Administration to "Local intranet" zone

(skipped -- since the "Create Farm.ps1" script configures this)

```PowerShell
cls
```

### # Configure PowerShell access for SharePoint administrators group

```PowerShell
$adminsGroup = "EXTRANET\SharePoint Admins (DEV)"

Get-SPDatabase |
    Where-Object {$_.WebApplication -like "SPAdministrationWebApplication"} |
    Add-SPShellAdmin $adminsGroup
```

### # Grant permissions on DCOM applications for SharePoint

```PowerShell
& '.\Configure DCOM Permissions.ps1' -Verbose

& "C:\NotBackedUp\Public\Toolbox\DcomPerm\x64\dcomperm.exe" `
    -al "IIS WAMREG admin Service" `
    set ($env:COMPUTERNAME + "\WSS_ADMIN_WPG") `
    permit level:ll,la

& "C:\NotBackedUp\Public\Toolbox\DcomPerm\x64\dcomperm.exe" `
    -al "IIS WAMREG admin Service" `
    set ($env:COMPUTERNAME + "\WSS_WPG") `
    permit level:ll,la

& "C:\NotBackedUp\Public\Toolbox\DcomPerm\x64\dcomperm.exe" `
    -al "{000C101C-0000-0000-C000-000000000046}" `
    set ($env:COMPUTERNAME + "\WSS_ADMIN_WPG") `
    permit level:ll,la
```

### # Configure diagnostic logging

```PowerShell
Set-SPDiagnosticConfig -DaysToKeepLogs 3

Set-SPDiagnosticConfig -LogDiskSpaceUsageGB 1 -LogMaxDiskSpaceUsageEnabled:$true
```

### # Configure usage and health data collection

```PowerShell
Set-SPUsageService -LoggingEnabled 1

New-SPUsageApplication
```

### # Configure outgoing e-mail settings

```PowerShell

$smtpServer = "smtp-test.technologytoolbox.com"
$fromAddress = "s-sp-farm-dev@technologytoolbox.com"
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

### # DEV - Configure timer job history

```PowerShell
Set-SPTimerJob "job-delete-job-history" -Schedule "Daily between 12:00:00 and 13:00:00"
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
    -IPAddress 10.1.20.158 `
    -Hostnames EXT-FOOBAR2, client-local-2.securitasinc.com
```

---

## Backup SharePoint databases

### Backup databases in Production environment

(Download backup files from PROD to [\\\\TT-FS01\\Archive\\Clients\\Securitas\\Backups](\\TT-FS01\Archive\Clients\Securitas\Backups))

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

### # Copy database backup from Production

```PowerShell
$backupFile = "SecuritasPortal_backup_2018_04_08_075408_3594374.bak"
$computerName = "EXT-FOOBAR2"

$source = "\\TT-FS01\Archive\Clients\Securitas\Backups"
$destination = "\\$computerName\Z`$\Microsoft SQL Server\MSSQL12.MSSQLSERVER" `
    + "\MSSQL\Backup\Full"

robocopy $source $destination $backupFile
```

---

```PowerShell
cls
```

### # Copy the backup files to the SQL Server for the SharePoint 2013 farm

```PowerShell
$destination = 'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full'

New-Item -ItemType Directory -Path $destination

net use \\ICEMAN\Archive /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
cls
robocopy `
    \\ICEMAN\Archive\Clients\Securitas\Backups `
    $destination `
    *.bak /XF WSS_Content_CloudPortal*
```

#### # Rename backup files

```PowerShell
Push-Location $destination

Rename-Item `
    'ManagedMetadataService_backup_2016_09_29_084517_2036824.bak' `
    'ManagedMetadataService.bak'

Rename-Item `
    'SecuritasPortal_backup_2016_09_29_084517_2505600.bak' `
    'SecuritasPortal.bak'

Rename-Item `
    'UserProfileService_Profile_backup_2016_09_29_084517_2193209.bak' `
    'UserProfileService_Profile.bak'

Rename-Item `
    'UserProfileService_Social_backup_2016_09_29_084517_2193209.bak' `
    'UserProfileService_Social.bak'

Rename-Item `
    'UserProfileService_Sync_backup_2016_09_29_084517_2193209.bak' `
    'UserProfileService_Sync.bak'

Rename-Item `
    'WSS_Content_SecuritasPortal_backup_2016_09_29_084517_2349669.bak' `
    'WSS_Content_SecuritasPortal.bak'

Rename-Item `
    'WSS_Content_SecuritasPortal2_backup_2016_09_29_084517_2505600.bak' `
    'WSS_Content_SecuritasPortal2.bak'

Pop-Location
```

### Export User Profile Synchronization encryption key

---

**258521-VM4** - Command Prompt

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
Copy-Item `
    "\\ICEMAN\Archive\Clients\Securitas\Backups\miiskeys-1.bin" `
    "C:\Users\setup-sharepoint-dev\Desktop"
```

## # Configure SharePoint services and service applications

### # Change service account for Distributed Cache

```PowerShell
& '.\Configure Distributed Cache.ps1' -Confirm:$false -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-sp-serviceapp-dev**.\
> Expect the previous operation to complete in approximately 8 minutes.

### DEV - Constrain Distributed Cache

(skipped -- since this environment is configured with 24 GB of RAM)

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
& '.\Configure Service Application Pool.ps1' -Confirm:$false -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-sp-serviceapp-dev**.

```PowerShell
cls
```

### # Configure Managed Metadata Service

#### # Restore database backup from Production

```PowerShell
$sqlcmd = @"
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
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
```

#### # Create Managed Metadata Service

```PowerShell
& '.\Configure Managed Metadata Service.ps1' -Confirm:$false -Verbose
```

```PowerShell
cls
```

### # Configure User Profile Service Application

#### # Restore the database backup from Production

```PowerShell
$sqlcmd = @"
```

#### -- Restore profile database

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

#### -- Restore synchronization database

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

#### -- Restore social tagging database

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

#### -- Add new SharePoint farm account to db_owner role in restored databases

```SQL
USE [UserProfileService_Profile]
GO

CREATE USER [EXTRANET\s-sp-farm-dev] FOR LOGIN [EXTRANET\s-sp-farm-dev]

ALTER ROLE [db_owner] ADD MEMBER [EXTRANET\s-sp-farm-dev]
GO

USE [UserProfileService_Social]
GO

CREATE USER [EXTRANET\s-sp-farm-dev] FOR LOGIN [EXTRANET\s-sp-farm-dev]

ALTER ROLE [db_owner] ADD MEMBER [EXTRANET\s-sp-farm-dev]
GO

USE [UserProfileService_Sync]
GO

CREATE USER [EXTRANET\s-sp-farm-dev] FOR LOGIN [EXTRANET\s-sp-farm-dev]

ALTER ROLE [db_owner] ADD MEMBER [EXTRANET\s-sp-farm-dev]
GO
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
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

**PowerShell** -- running as **EXTRANET\\s-sp-farm-dev**

```PowerShell
cd C:\Shares\Builds\ClientPortal\4.0.675.0\DeploymentFiles\Scripts

& '.\Configure User Profile Service.ps1' -Confirm:$false -Verbose
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

**Command Prompt** -- running as **EXTRANET\\s-sp-farm-dev**

```Console
cd "C:\Program Files\Microsoft Office Servers\15.0\Synchronization Service\Bin\"

miiskmu.exe /i "C:\Users\setup-sharepoint-dev\Desktop\miiskeys-1.bin" ^
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

##### Start profile synchronization

Number of user profiles (before import): 11,444\
Number of user profiles (after import): 11,937

```PowerShell
Start-Process `
    ("C:\Program Files\Microsoft Office Servers\15.0\Synchronization Service" `
        + "\UIShell\miisclient.exe") `
    -Credential $farmCredential
```

Start time: 8:50:37 AM\
End time: 9:07:52 AM

```PowerShell
cls
```

### # Create and configure search service application

#### # Create Search Service Application

```PowerShell
& '.\Configure SharePoint Search.ps1' -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-sp-crawler-dev**.\
> Expect the previous operation to complete in approximately 9 minutes.

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
$startAddress = "sps3://client-local-2.securitasinc.com"

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
    -CrawlScheduleStartDateTime "2:00 AM" `
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

#### DEV - Configure performance level for search crawl component

(skipped -- since this environment has a full copy of PROD content)

```PowerShell
cls
```

## # Create and configure Web application

### # Set environment variables

```PowerShell
[Environment]::SetEnvironmentVariable(
  "SECURITAS_CLIENT_PORTAL_URL",
  "http://client-local-2.securitasinc.com",
  "Machine")

[Environment]::SetEnvironmentVariable(
  "SECURITAS_BUILD_CONFIGURATION",
  "Debug",
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
    -Patterns http://client-local-2.securitasinc.com,
        https://client-local-2.securitasinc.com
```

### DEV - Snapshot VM

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Delete previous VM snapshot

```PowerShell
$vmHost = "BEAST"
$vmName = "EXT-FOOBAR2"

Stop-VM -ComputerName $vmHost -Name $vmName

Write-Host "Deleting snapshot..." -NoNewline

Remove-VMSnapshot -ComputerName $vmHost -VMName $vmName

Write-Host "Waiting a few seconds for merge to start..."
Start-Sleep -Seconds 5

while (Get-VM -ComputerName $vmHost -Name $vmName |
    Where Status -eq "Merging disks") {
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 5
}

Write-Host

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### # Create Web application

```PowerShell
cd C:\Shares\Builds\ClientPortal\4.0.675.0\DeploymentFiles\Scripts

& '.\Create Web Application.ps1' -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-web-client-dev**.\
> Expect the previous operation to complete in approximately 3 minutes.

```PowerShell
cls
```

### # Restore content database or create initial site collections

#### # Remove content database created with Web application

```PowerShell
Remove-SPContentDatabase WSS_Content_SecuritasPortal -Confirm:$false -Force
```

##### # Restore database backups from Production

```PowerShell
$stopwatch = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-Stopwatch.ps1

$sqlcmd = @"
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

###### -- Set databases to use Simple recovery model

```PowerShell
ALTER DATABASE [WSS_Content_SecuritasPortal]
SET RECOVERY SIMPLE WITH NO_WAIT
GO

ALTER DATABASE [WSS_Content_SecuritasPortal2]
SET RECOVERY SIMPLE WITH NO_WAIT
GO
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:

$stopwatch.Stop()
C:\NotBackedUp\Public\Toolbox\PowerShell\Write-ElapsedTime.ps1 $stopwatch
```

> **Note**
>
> Expect the previous operation to complete in approximately 37 minutes.\
> RESTORE DATABASE successfully processed 3720520 pages in 958.230 seconds (30.333 MB/sec).\
> ...\
> RESTORE DATABASE successfully processed 3606878 pages in 1154.382 seconds (24.410 MB/sec).

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
> Expect the previous operation to complete in approximately 7 minutes.

##### Remove SecuritasConnect v3.0 solution

(skipped)

```PowerShell
cls
```

### # Configure machine key for Web application

```PowerShell
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
$cred1 = Get-Credential "EXTRANET\s-web-client-dev"

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
    -Hostnames client-local-2.securitasinc.com `
    -Verbose
```

### # Allow specific host names mapped to 127.0.0.1

```PowerShell
& C:\NotBackedUp\Public\Toolbox\PowerShell\Add-BackConnectionHostNames.ps1 `
    -HostNames client-local-2.securitasinc.com `
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
$adminsGroup = "EXTRANET\SharePoint Admins (DEV)"

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

My Site Host location: **[http://client-local-2.securitasinc.com/sites/my](http://client-local-2.securitasinc.com/sites/my)**

## Deploy SecuritasConnect solution

### DEV - Build Visual Studio solution and package SharePoint projects

(skipped)

```PowerShell
cls
```

### # Create and configure SecuritasPortal database

```PowerShell
$sqlcmd = @"
```

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

CREATE USER [EXTRANET\s-sp-farm-dev] FOR LOGIN [EXTRANET\s-sp-farm-dev]
GO
ALTER ROLE [aspnet_Membership_BasicAccess] ADD MEMBER [EXTRANET\s-sp-farm-dev]
GO
ALTER ROLE [aspnet_Membership_ReportingAccess] ADD MEMBER [EXTRANET\s-sp-farm-dev]
GO
ALTER ROLE [aspnet_Roles_BasicAccess] ADD MEMBER [EXTRANET\s-sp-farm-dev]
GO
ALTER ROLE [aspnet_Roles_ReportingAccess] ADD MEMBER [EXTRANET\s-sp-farm-dev]
GO

CREATE USER [EXTRANET\s-web-client-dev] FOR LOGIN [EXTRANET\s-web-client-dev]
GO
ALTER ROLE [aspnet_Membership_FullAccess] ADD MEMBER [EXTRANET\s-web-client-dev]
GO
ALTER ROLE [aspnet_Profile_BasicAccess] ADD MEMBER [EXTRANET\s-web-client-dev]
GO
ALTER ROLE [aspnet_Roles_BasicAccess] ADD MEMBER [EXTRANET\s-web-client-dev]
GO
ALTER ROLE [aspnet_Roles_ReportingAccess] ADD MEMBER [EXTRANET\s-web-client-dev]
GO
ALTER ROLE [Customer_Reader] ADD MEMBER [EXTRANET\s-web-client-dev]
GO
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
```

### Create Branch Managers domain group and add members

(skipped)

### Create PODS Support domain group and add members

(skipped)

```PowerShell
cls
```

### # Configure logging

```PowerShell
& '.\Add Event Log Sources.ps1' -Verbose
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
      connectionString="Server=.;Database=SecuritasPortal;Integrated Security=true" />
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

& '.\Activate Features.ps1' -Verbose
```

#### Activate "Securitas - Application Settings" feature

(skipped)

### Import template site content

(skipped)

### Create users in SecuritasPortal database

#### Create users for Securitas clients

(skipped)

#### Create users for Securitas Branch Managers

(skipped)

```PowerShell
cls
```

#### # Associate client users to Branch Managers

```PowerShell
$sqlcmd = @"
USE SecuritasPortal
GO

UPDATE Customer.BranchManagerAssociatedUsers
SET BranchManagerUserName = 'TECHTOOLBOX\jjameson'
WHERE BranchManagerUserName = 'PNKUS\jjameson'
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
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

Tracking ID: **UA-25949832-4**

### Upgrade C&C site collections

(skipped -- since database was restored from Production)

### Defragment SharePoint databases

> **Note**
>
> Expect the defragmentation job to complete in approximately 3 hours and 17 minutes.

```PowerShell
cls
```

#### # Shrink log files for content databases

```PowerShell
$sqlcmd = @"
USE [WSS_Content_SecuritasPortal]
GO
DBCC SHRINKFILE (N'WSS_Content_SecuritasPortal_log' , 0, TRUNCATEONLY)
GO
USE [WSS_Content_SecuritasPortal2]
GO
DBCC SHRINKFILE (N'WSS_Content_SecuritasPortal2_log' , 0, TRUNCATEONLY)
GO
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
```

#### Shrink content database

(skipped)

```PowerShell
cls
```

### # Change recovery model of content databases from Simple to Full

```PowerShell
$sqlcmd = @"
ALTER DATABASE [WSS_Content_SecuritasPortal]
SET RECOVERY FULL WITH NO_WAIT
GO

ALTER DATABASE [WSS_Content_SecuritasPortal2]
SET RECOVERY FULL WITH NO_WAIT
GO
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
```

```PowerShell
cls
```

### # Configure SQL Server backups

#### # Create folders for backups

```PowerShell
$backupPath = "Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup"

New-Item -ItemType Directory -Path "$backupPath\Differential"
New-Item -ItemType Directory -Path "$backupPath\Full"
New-Item -ItemType Directory -Path "$backupPath\Transaction Log"
```

#### Create backup maintenance plans

<table>
<thead>
<th>
<p><strong>Name</strong></p>
</th>
<th>
<p><strong>Frequency</strong></p>
</th>
<th>
<p><strong>Daily Frequency</strong></p>
</th>
<th>
<p><strong>Backup compression</strong></p>
</th>
</thead>
<tr>
<td valign='top'>
<p>Full Backup of All Databases</p>
</td>
<td valign='top'>
<p>Occurs: <strong>Weekly</strong><br />
Recurs every: <strong>1</strong> week on</p>
<ul>
<li><strong>Sunday</strong></li>
</ul>
</td>
<td valign='top'>
<p>Occurs once at: <strong>12:00:00 AM</strong></p>
</td>
<td valign='top'>
<p><strong>Compress backup</strong></p>
</td>
</tr>
<tr>
<td valign='top'>
<p>Differential Backup of All Databases</p>
</td>
<td valign='top'>
<p>Occurs: <strong>Daily</strong><br />
Recurs every: <strong>1</strong> day</p>
</td>
<td valign='top'>
<p>Occurs once at: <strong>11:30:00 PM</strong></p>
</td>
<td valign='top'>
<p><strong>Compress backup</strong></p>
</td>
</tr>
<tr>
<td valign='top'>
<p>Transaction Log Backup of All Databases</p>
</td>
<td valign='top'>
<p>Occurs: <strong>Daily</strong><br />
Recurs every: <strong>1</strong> day</p>
</td>
<td valign='top'>
<p>Occurs every: <strong>30 minutes</strong><br />
Starting at:<strong> 12:25:00 AM</strong><br />
Ending at:<strong> 11:59:59 PM</strong></p>
</td>
<td valign='top'>
<p><strong>Compress backup</strong></p>
</td>
</tr>
</table>

##### Create maintenance plan for full backup of all databases

1. Open **SQL Server Management Studio**.
2. In **Object Explorer**, expand **Management**, right-click **Maintenance Plans**, and click **Maintenance Plan Wizard**.
3. In the **Maintenance Plan Wizard** window:
   1. On the starting page, click **Next**.
   2. On the **Select Plan Properties** page:
      1. In the **Name** box, type **Full Backup of All Databases**.
      2. In the **Schedule** section, click **Change...**
      3. In the **New Job Schedule** window, configure the settings according to the configuration specified above, and click **OK**.
      4. Click **Next**.
   3. On the **Select Maintenance Tasks** page, in the list of maintenance tasks, select **Back Up Database (Full)**, and click **Next**.
   4. On the **Select Maintenance Task Order** page, click **Next**.
   5. On the **Define Back Up Database (Full) Task** page:
      1. On the **General** tab, In the **Database(s) **dropdown, select **All databases**.
      2. On the **Destination** tab, in the Folder box, type **Z:\\Microsoft SQL Server\\MSSQL12.MSSQLSERVER\\MSSQL\\Backup\\Full**.
      3. On the **Options** tab, in the **Set backup compression** dropdown, select **Compress backup**.
      4. Click **Next**.
   6. On the **Select Report Options** page, click **Next**.
   7. On the **Complete the Wizard** page, click **Finish**.

##### Create maintenance plan for differential backup of all databases

1. Open **SQL Server Management Studio**.
2. In **Object Explorer**, expand **Management**, right-click **Maintenance Plans**, and click **Maintenance Plan Wizard**.
3. In the **Maintenance Plan Wizard** window:
   1. On the starting page, click **Next**.
   2. On the **Select Plan Properties** page:
      1. In the **Name** box, type **Differential Backup of All Databases**.
      2. In the **Schedule** section, click **Change...**
      3. In the **New Job Schedule** window, configure the settings according to the configuration specified above, and click **OK**.
      4. Click **Next**.
   3. On the **Select Maintenance Tasks** page, in the list of maintenance tasks, select **Back Up Database (Differential)**, and click **Next**.
   4. On the **Select Maintenance Task Order** page, click **Next**.
   5. On the **Define Back Up Database (Differential) Task** page:
      1. On the **General** tab, In the **Database(s) **dropdown, select **All databases**.
      2. On the **Destination** tab, in the Folder box, type **Z:\\Microsoft SQL Server\\MSSQL12.MSSQLSERVER\\MSSQL\\Backup\\Differential**.
      3. On the **Options** tab, in the **Set backup compression** dropdown, select **Compress backup**.
      4. Click **Next**.
   6. On the **Select Report Options** page, click **Next**.
   7. On the **Complete the Wizard** page, click **Finish**.

##### Create maintenance plan for transaction log backup of all databases

1. Open **SQL Server Management Studio**.
2. In **Object Explorer**, expand **Management**, right-click **Maintenance Plans**, and click **Maintenance Plan Wizard**.
3. In the **Maintenance Plan Wizard** window:
   1. On the starting page, click **Next**.
   2. On the **Select Plan Properties** page:
      1. In the **Name** box, type **Transaction Log Backup of All Databases**.
      2. In the **Schedule** section, click **Change...**
      3. In the **New Job Schedule** window, configure the settings according to the configuration specified above, and click **OK**.
      4. Click **Next**.
   3. On the **Select Maintenance Tasks** page, in the list of maintenance tasks, select **Back Up Database (Transaction Log)**, and click **Next**.
   4. On the **Select Maintenance Task Order** page, click **Next**.
   5. On the **Define Back Up Database (Full) Task** page:
      1. On the **General** tab, In the **Database(s) **dropdown, select **All databases**.
      2. On the **Destination** tab, in the Folder box, type **Z:\\Microsoft SQL Server\\MSSQL12.MSSQLSERVER\\MSSQL\\Backup\\Transaction Log**.
      3. On the **Options** tab, in the **Set backup compression** dropdown, select **Compress backup**.
      4. Click **Next**.
   6. On the **Select Report Options** page, click **Next**.
   7. On the **Complete the Wizard** page, click **Finish**.

##### Create cleanup maintenance plan

<table>
<thead>
<th>
<p><strong>Name</strong></p>
</th>
<th>
<p><strong>Frequency</strong></p>
</th>
<th>
<p><strong>Daily Frequency</strong></p>
</th>
<th>
<p><strong>Maintenance Cleanup Task Settings</strong></p>
</th>
</thead>
<tr>
<td valign='top'>
<p>Remove Old Database Backups</p>
</td>
<td valign='top'>
<p>Occurs: <strong>Weekly</strong><br />
Recurs every: <strong>1</strong> week on</p>
<ul>
<li><strong>Saturday</strong></li>
</ul>
</td>
<td valign='top'>
<p>Occurs once at: <strong>11:55:00 PM</strong></p>
</td>
<td valign='top'>
<p><strong>First Task (Remove Full and Differential Backups)</strong></p>
<p><strong>Delete files of the following type:</strong></p>
<ul>
<li><strong>Backup files</strong></li>
</ul>
<p><strong>File location:</strong></p>
<ul>
<li><strong>Search folder and delete files based on an extension</strong>
<ul>
<li><strong>Folder: Z:\\Microsoft SQL Server\\MSSQL12.MSSQLSERVER\\MSSQL\\Backup\\</strong></li>
<li><strong>File Extension: bak</strong></li>
<li><strong>Include first-level subfolders: Yes (checked)</strong></li>
</ul>
</li>
</ul>
<p><strong>File age:</strong></p>
<ul>
<li><strong>Delete files based on the age of the file at task run time</strong></li>
<li><strong>Delete files older than the following: 1 Hour(s)</strong></li>
</ul>
<p><strong>Second Task (Remove Transaction Log Backups)</strong></p>
<p><strong>Delete files of the following type:</strong></p>
<ul>
<li><strong>Backup files</strong></li>
</ul>
<p><strong>File location:</strong></p>
<ul>
<li><strong>Search folder and delete files based on an extension</strong>
<ul>
<li><strong>Folder: Z:\\Microsoft SQL Server\\MSSQL12.MSSQLSERVER\\MSSQL\\Backup\\Transaction Log\\</strong></li>
<li><strong>File Extension: trn</strong></li>
<li><strong>Include first-level subfolders: No (unchecked)</strong></li>
</ul>
</li>
</ul>
<p><strong>File age:</strong></p>
<ul>
<li><strong>Delete files based on the age of the file at task run time</strong></li>
<li><strong>Delete files older than the following: 1 Hour(s)</strong></li>
</ul>
</td>
</tr>
</table>

##### Create maintenance plan to remove old Full and Differential backups

1. Open **SQL Server Management Studio**.
2. In **Object Explorer**, expand **Management**, right-click **Maintenance Plans**, and click **Maintenance Plan Wizard**.
3. In the **Maintenance Plan Wizard** window:
   1. On the starting page, click **Next**.
   2. On the **Select Plan Properties** page:
      1. In the **Name** box, type **Remove Old Database Backups**.
      2. In the **Schedule** section, click **Change...**
      3. In the **New Job Schedule** window, configure the settings according to the configuration specified above, and click **OK**.
      4. Click **Next**.
   3. On the **Select Maintenance Tasks** page, in the list of maintenance tasks, select **Maintenance Cleanup Task**, and click **Next**.
   4. On the **Select Maintenance Task Order** page, click **Next**.
   5. On the **Define Maintenance Cleanup Task** page:
      1. In the **Folder** box, type **Z:\\Microsoft SQL Server\\MSSQL12.MSSQLSERVER\\MSSQL\\Backup\\**.
      2. In the **File extension** box, type **bak**.
      3. Select the **Include first-level subfolders** checkbox.
      4. In the **File age** section, configure the settings to delete files older than **1 Hour(s)**.
      5. Click **Next**.
   6. On the **Select Report Options** page, click **Next**.
   7. On the **Complete the Wizard** page, click **Finish**.

##### Modify maintenance plan to remove old Transaction Log backups

1. Open **SQL Server Management Studio**.
2. In **Object Explorer**, expand **Management**, expand **Maintenance Plans**, right-click **Remove Old Database Backups** and click **Modify**.
3. In the Maintenance Plan designer:
   1. Right-click **Maintenance Cleanup Task** and click **Properties**.
   2. In the **Properties** window:
      1. If necessary, expand the **Identification** section.
      2. In the **Name** box, type **Remove Full and Differential Backups**.
   3. Use the **Toolbox** to add a new **Maintenance Cleanup Task**.
   4. Right-click the new task and click **Properties**.
   5. In the **Properties** window:
      1. If necessary, expand the **Identification** section.
      2. In the **Name** box, type **Remove Transaction Log Backups**.
   6. Right-click the **Remove Transaction Log Backups** task and click **Edit...**
   7. In the **Maintenance Cleanup Task** window:
      1. In the **Folder** box, type **Z:\\Microsoft SQL Server\\MSSQL12.MSSQLSERVER\\MSSQL\\Backup\\Transaction Log\\**.
      2. In the **File extension** box, type **trn**.
      3. In the **File age** section, configure the settings to delete files older than **1 Hour(s)**.
      4. Click **OK**.
4. On the **File** menu, click **Save Selected Items**.

#### Execute maintenance plan - Full Backup of All Databases

### Add content database and partition Post Orders site collections

(skipped)

### Resume Search Service Application and start a full crawl of all content sources

(skipped)

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

### Install Web Deploy 3.6

(skipped -- since this is installed with Visual Studio 2015)

```PowerShell
cls
```

### # Create media website on front-end Web servers

#### # Create media website on first front-end Web server

```PowerShell
& ".\Configure Media Website.ps1" `
    -SiteName media-local-2.securitasinc.com `
    -Verbose
```

#### Configure SSL bindings on media website

#### Create media website on other web servers in farm

(skipped)

```PowerShell
cls
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
$websiteName = "media-local-2.securitasinc.com"

robocopy `
    '\\ICEMAN\Archive\Clients\Securitas\Media' C:\inetpub\wwwroot\$websiteName /E
```

#### Copy media website content to other front-end Web server in farm

(skipped)

```PowerShell
cls
```

### # Delete extraneous media files

```PowerShell
$websiteName = "media-local-2.securitasinc.com"

@(
    "Connect",
    "Connectold",
    "Innovation",
    "Marketing\ASIS-SecuritasFinal-2015",
    "Marketing\EOC_Relocation",
    "Marketing\ExampleVideoMarketing",
    "Marketing\Henry's Honey",
    "Marketing\MassTextLaunch",
    "Marketing\SCR11_Procedures_20111222-Medium",
    "Marketing\SCR11_Procedures_AE_20120105_H264",
    "Marketing\SCR11_Reporting_AE_20120216_H264",
    "Marketing\SCR11_SecureEntry_AE_20120612_ProRes",
    "Marketing\SCR11_Vision_AE_20120105_H264",
    "Marketing\SecuritasVision2013",
    "Marketing\SecuritasVisitorManagement2013",
    "Marketing\SecuritasVisitorManagementCommercial",
    "Marketing\SecuritasVisitorManagementResidential",
    "Solutions",
    "Training\EmployeePortal",
    "Training\EmployeePortal_LP",
    "Training\LastPass",
    "Training\LastPass_Old",
    "Training\Ops Reports Navigation_w_audio in F4V format_WMV",
    "Training\TAPS",
    "Vigilance"
) |
    % {
        Remove-Item "C:\inetpub\wwwroot\$websiteName\$_" -Recurse -Force
    }
```

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

    $user = $site.RootWeb.EnsureUser("EXTRANET\SharePoint Admins (DEV)");
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
> Expect the previous operation to complete in approximately 2 hours and 15 minutes.

Install Cloud Portal v2.0

## Installation prerequisites

### Create Cloud Portal service account

(skipped)

## Backup SharePoint 2010 environment

### Backup databases in SharePoint 2010 environment

(Download backup files from PROD to [\\\\ICEMAN\\Archive\\Clients\\Securitas\\Backups](\\ICEMAN\Archive\Clients\Securitas\Backups))

```PowerShell
cls
```

### # Copy the backup files to the SQL Server for the SharePoint 2013 farm

```PowerShell
net use \\ICEMAN\Archive /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$source = "\\ICEMAN\Archive\Clients\Securitas\Backups"
$destination = 'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full'

robocopy `
    $source `
    $destination `
    WSS_Content_CloudPortal*.bak
```

#### # Rename backup file

```PowerShell
Push-Location $destination

Rename-Item `
    'WSS_Content_CloudPortal_backup_2016_09_29_084517_2505600.bak' `
    'WSS_Content_CloudPortal.bak'

Pop-Location
```

## # Create and configure Cloud Portal Web application

### # Set environment variables

```PowerShell
[Environment]::SetEnvironmentVariable(
  "SECURITAS_CLOUD_PORTAL_URL",
  "http://cloud-local-2.securitasinc.com",
  "Machine")

exit
```

> **Important**
>
> Restart PowerShell for environment variable to take effect.

### # Add Cloud Portal URLs to "Local intranet" zone

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-InternetSecurityZoneMapping.ps1 `
    -Zone LocalIntranet `
    -Patterns http://cloud-local-2.securitasinc.com,
        https://cloud-local-2.securitasinc.com
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
$destPath = "C:\Shares\Builds\CloudPortal\$build"

robocopy $sourcePath $destPath /E
```

### # Create Web application

```PowerShell
cd C:\Shares\Builds\CloudPortal\2.0.122.0\DeploymentFiles\Scripts

& '.\Create Web Application.ps1' -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-web-cloud-dev**.\
> Expect the previous operation to complete in approximately 3-1/2 minutes.

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

New-Item -ItemType Directory -Path ListCollectionSetup
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
> Expect the installation of BoostSolutions List Collection to complete in approximately 51 minutes (since it appears to query Active Directory for each user that has ever accessed the web application).

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

##### # Restore database backup from Production

```PowerShell
$stopwatch = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-Stopwatch.ps1

$sqlcmd = @"
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

##### -- Set database to use Simple recovery model

```PowerShell
ALTER DATABASE [WSS_Content_CloudPortal]
SET RECOVERY SIMPLE WITH NO_WAIT
GO
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:

$stopwatch.Stop()
C:\NotBackedUp\Public\Toolbox\PowerShell\Write-ElapsedTime.ps1 $stopwatch
```

> **Note**
>
> Expect the previous operation to complete in approximately 1 hour and 5 minutes.\
> RESTORE DATABASE successfully processed 7351620 pages in 3822.000 seconds (15.027 MB/sec).

##### Install Cloud Portal v1.0 solution

(skipped)

##### Test content database

(skipped)

```PowerShell
cls
```

##### # Attach content database

```PowerShell
Mount-SPContentDatabase `
    -Name WSS_Content_CloudPortal `
    -WebApplication $env:SECURITAS_CLOUD_PORTAL_URL
```

##### Remove Cloud Portal v1.0 solution

(skipped)

```PowerShell
cls
```

### # Configure object cache user accounts

```PowerShell
& '.\Configure Object Cache User Accounts.ps1' -Verbose

iisreset
```

### # Configure People Picker to support searches across one-way trusts

#### # Specify credentials for accessing trusted forests

```PowerShell
$cred1 = Get-Credential "EXTRANET\s-web-cloud-dev"

$cred2 = Get-Credential "TECHTOOLBOX\svc-sp-ups"

$cred3 = Get-Credential "FABRIKAM\s-sp-ups"

& '.\Configure People Picker Forests.ps1' `
    -ServiceCredentials $cred1, $cred2, $cred3 `
    -Confirm:$false `
    -Verbose
```

### DEV - Map Web application to loopback address in Hosts file

(skipped)

### Allow specific host names mapped to 127.0.0.1

(skipped)

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
[Uri] $tempUri = [Uri] $env:SECURITAS_CLOUD_PORTAL_URL

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
$adminsGroup = "EXTRANET\SharePoint Admins (DEV)"

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

```PowerShell
cls
```

### # Configure permissions for SecuritasPortal database

```PowerShell
$sqlcmd = @"
USE [SecuritasPortal]
GO

CREATE USER [EXTRANET\s-web-cloud-dev] FOR LOGIN [EXTRANET\s-web-cloud-dev]
GO
ALTER ROLE [aspnet_Membership_FullAccess] ADD MEMBER [EXTRANET\s-web-cloud-dev]
GO
ALTER ROLE [aspnet_Profile_BasicAccess] ADD MEMBER [EXTRANET\s-web-cloud-dev]
GO
ALTER ROLE [aspnet_Roles_BasicAccess] ADD MEMBER [EXTRANET\s-web-cloud-dev]
GO
ALTER ROLE [aspnet_Roles_ReportingAccess] ADD MEMBER [EXTRANET\s-web-cloud-dev]
GO
ALTER ROLE [Customer_Provisioner] ADD MEMBER [EXTRANET\s-web-cloud-dev]
GO
ALTER ROLE [Customer_Reader] ADD MEMBER [EXTRANET\s-web-cloud-dev]
GO
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
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

Tracking ID: **UA-25949832-5**

### Upgrade C&C site collections

(skipped)

### Defragment SharePoint databases

> **Note**
>
> Expect the defragmentation job to complete in approximately 1 hours and 37 minutes.

```PowerShell
cls
```

### # Change recovery model of content database from Simple to Full

```PowerShell
$sqlcmd = @"
ALTER DATABASE [WSS_Content_CloudPortal]
SET RECOVERY FULL WITH NO_WAIT
GO
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
```

### Resume Search Service Application and start full crawl on all content sources

(skipped)

### Remove obsolete web app policies

For each web application, delete the **Search Crawling Account** corresponding to **EXTRANET\\s-sp-serviceapp-dev**.

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
$destPath = "C:\Shares\Builds\EmployeePortal\$build"

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
    + "client2-local-2.securitasinc.com443")

copy web.config "web - Copy.config"

C:\NotBackedUp\Public\Toolbox\DiffMerge\DiffMerge.exe `
    '..\client-local-2.securitasinc.com80\web.config' `
    .\web.config

Pop-Location
```

#### # Enable disk-based caching for Cloud Portal "intranet" website

```PowerShell
Push-Location ("C:\inetpub\wwwroot\wss\VirtualDirectories\" `
    + "cloud2-local-2.securitasinc.com443")

copy web.config "web - Copy.config"

C:\NotBackedUp\Public\Toolbox\DiffMerge\DiffMerge.exe `
    '..\cloud-local-2.securitasinc.com80\web.config' `
    .\web.config

Pop-Location
```

```PowerShell
cls
```

### # Map intranet URLs to loopback address in Hosts file

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    127.0.0.1 client2-local-2.securitasinc.com, cloud2-local-2.securitasinc.com
```

### # Allow specific host names mapped to 127.0.0.1

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-BackConnectionHostnames.ps1 `
    client2-local-2.securitasinc.com, cloud2-local-2.securitasinc.com
```

## Install Web Deploy 3.6

### Download Web Platform Installer

(skipped)

### Install Web Deploy

(skipped -- since this is installed with Visual Studio 2015)

## Install .NET Framework 4.5

(skipped -- since this is installed with Visual Studio 2015)

```PowerShell
cls
```

## # Install Employee Portal

### # Add Employee Portal URLs to "Local intranet" zone

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-InternetSecurityZoneMapping.ps1 `
    -Zone LocalIntranet `
    -Patterns http://employee-local-2.securitasinc.com,
        https://employee-local-2.securitasinc.com
```

### Create Employee Portal SharePoint site

(skipped)

```PowerShell
cls
```

### # Create Employee Portal website

#### # Create Employee Portal website on SharePoint Central Administration server

```PowerShell
& '.\Configure Employee Portal Website.ps1' `
    -SiteName employee-local-2.securitasinc.com `
    -Confirm:$false `
    -Verbose
```

#### Configure SSL bindings on Employee Portal website

#### Create Employee Portal website on other web servers in farm

(skipped)

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

File - **Web.SetParameters.xml**

```XML
<?xml version="1.0" encoding="utf-8"?>
<parameters>
  <setParameter
    name="IIS Web Application Name"
    value="employee-local-2.securitasinc.com" />
  <setParameter
    name="SecuritasPortal-Web.config Connection String"
    value="Server=.; Database=SecuritasPortal; Integrated Security=true" />
  <setParameter
    name="SecuritasPortalDbContext-Web.config Connection String"
    value="Data Source=.; Initial Catalog=SecuritasPortal; Integrated Security=True; MultipleActiveResultSets=True;" />
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
Notepad C:\inetpub\wwwroot\employee-local-2.securitasinc.com\Web.config
```

1. Set the value of the **GoogleAnalytics.TrackingId** application setting to **UA-25949832-3**.
2. In the **`<errorMail>`** element, change the **smtpServer** attribute to **smtp-test.technologytoolbox.com**.
3. Replace all instances of **[http://client2-local](http://client2-local)** with **[https://client2-local-2](https://client2-local-2)**.
4. Replace all instances of **[http://cloud2-local](http://cloud2-local)** with **[https://cloud2-local-2](https://cloud2-local-2)**.
5. Replace all instances of **TransportCredentialOnly** with **Transport**.

#### Deploy Employee Portal website content to other web servers in farm

(skipped)

```PowerShell
cls
```

### # Configure database logins and permissions for Employee Portal

```PowerShell
$sqlcmd = @"
USE [master]
GO
CREATE LOGIN [IIS APPPOOL\employee-local-2.securitasinc.com]
FROM WINDOWS
WITH DEFAULT_DATABASE=[master]
GO
USE [SecuritasPortal]
GO
CREATE USER [IIS APPPOOL\employee-local-2.securitasinc.com]
FOR LOGIN [IIS APPPOOL\employee-local-2.securitasinc.com]
GO
EXEC sp_addrolemember N'Employee_FullAccess', N'IIS APPPOOL\employee-local-2.securitasinc.com'
GO
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
```

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
    127.0.0.1 employee-local-2.securitasinc.com
```

### # Allow specific host names mapped to 127.0.0.1

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-BackConnectionHostnames.ps1 `
    employee-local-2.securitasinc.com
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

## # Configure symbol path for debugging

```PowerShell
[Environment]::SetEnvironmentVariable(
  "_NT_SYMBOL_PATH",
  ("SRV" `
    + "*C:\NotBackedUp\Public\Symbols" `
    + "*\\ICEMAN\Public\Symbols" `
    + "*https://msdl.microsoft.com/download/symbols"),
  "Machine")
```

## # Clean up WinSxS folder

```PowerShell
Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase
```

## Update client secret for LMS

```Console
cd C:\Shares\Builds\ClientPortal\4.0.675.0\DeploymentFiles\Scripts

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
Start-Process "http://client-local-2.securitasinc.com"
```

```PowerShell
cls
```

### # Configure TEKWave in SecuritasPortal database

```PowerShell
$sqlcmd = @"
USE [SecuritasPortal]
GO

-- Add TEKWave services

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

-- Remove CapSure from all sites

DELETE SiteServices
FROM
    Customer.SiteServices
    INNER JOIN Customer.Services
    ON SiteServices.ServiceId = Services.ServiceId
WHERE
    Services.ServiceName = 'CapSure'

-- Add TEKWave to "ABC Company" sites

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
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

### Edit user profiles to add credentials for TEKWave

```PowerShell
cls
```

### # Delete old build

```PowerShell
Remove-Item C:\Shares\Builds\ClientPortal\4.0.675.0 -Recurse -Force
```

## Refresh content from Production

```PowerShell
cls
```

### # Pause Search Service Application

```PowerShell
Enable-SharePointCmdlets

Get-SPEnterpriseSearchServiceApplication "Search Service Application" |
    Suspend-SPEnterpriseSearchServiceApplication
```

### # Restore SecuritasPortal database backup

#### # Extract database backups from zip file

```PowerShell
net use \\ICEMAN\Archive /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$zipFile = `
    "SecuritasPortal_backup_2016_11_20_000009_8804925.zip"

$sourcePath = "\\ICEMAN\Archive\Clients\Securitas\Backups"

$destPath = "Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full"

Add-Type -assembly "System.Io.Compression.FileSystem"

$zipFilePath = $sourcePath + "\" + $zipFile

[Io.Compression.ZipFile]::ExtractToDirectory($zipFilePath, $destPath)
```

#### # Restore database backup from Production

```PowerShell
$backupFile = $zipFile.Replace(".zip", ".bak")

$sqlcmd = @"
DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\$backupFile'

DECLARE @dataFilePath VARCHAR(255) =
  'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'SecuritasPortal.mdf'

DECLARE @logFilePath VARCHAR(255) =
  'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'SecuritasPortal_log.LDF'

RESTORE DATABASE SecuritasPortal
  FROM DISK = @backupFilePath
  WITH FILE = 1,
    MOVE 'SecuritasPortal' TO @dataFilePath,
    MOVE 'SecuritasPortal_log' TO @logFilePath,
    NOUNLOAD,
    REPLACE,
    STATS = 5

GO
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
```

#### # Configure permissions for SecuritasPortal database

```PowerShell
$sqlcmd = @"
USE [SecuritasPortal]
GO

CREATE USER [EXTRANET\s-sp-farm-dev] FOR LOGIN [EXTRANET\s-sp-farm-dev]
GO
ALTER ROLE [aspnet_Membership_BasicAccess] ADD MEMBER [EXTRANET\s-sp-farm-dev]
GO
ALTER ROLE [aspnet_Membership_ReportingAccess] ADD MEMBER [EXTRANET\s-sp-farm-dev]
GO
ALTER ROLE [aspnet_Roles_BasicAccess] ADD MEMBER [EXTRANET\s-sp-farm-dev]
GO
ALTER ROLE [aspnet_Roles_ReportingAccess] ADD MEMBER [EXTRANET\s-sp-farm-dev]
GO

CREATE USER [EXTRANET\s-web-client-dev] FOR LOGIN [EXTRANET\s-web-client-dev]
GO
ALTER ROLE [aspnet_Membership_FullAccess] ADD MEMBER [EXTRANET\s-web-client-dev]
GO
ALTER ROLE [aspnet_Profile_BasicAccess] ADD MEMBER [EXTRANET\s-web-client-dev]
GO
ALTER ROLE [aspnet_Roles_BasicAccess] ADD MEMBER [EXTRANET\s-web-client-dev]
GO
ALTER ROLE [aspnet_Roles_ReportingAccess] ADD MEMBER [EXTRANET\s-web-client-dev]
GO
ALTER ROLE [Customer_Reader] ADD MEMBER [EXTRANET\s-web-client-dev]
GO

CREATE USER [IIS APPPOOL\employee-local-2.securitasinc.com]
FOR LOGIN [IIS APPPOOL\employee-local-2.securitasinc.com]
GO
EXEC sp_addrolemember N'Employee_FullAccess', N'IIS APPPOOL\employee-local-2.securitasinc.com'
GO
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
```

#### # Associate users to TECHTOOLBOX\\smasters

```PowerShell
$sqlcmd = @"
USE [SecuritasPortal]
GO

INSERT INTO Customer.BranchManagerAssociatedUsers
SELECT 'TECHTOOLBOX\smasters', AssociatedUserName
FROM Customer.BranchManagerAssociatedUsers
WHERE BranchManagerUserName = 'PNKUS\jjameson'
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
```

#### HACK: Update TrackTik password for bbarthelemy-demo

```PowerShell
cls
```

### # Restore SecuritasConnect database backups

#### # Extract database backups from zip file

```PowerShell
$zipFile = `
    "WSS_Content_SecuritasPortal_backup_2016_11_20_000009_8804925.zip"

$sourcePath = "\\ICEMAN\Archive\Clients\Securitas\Backups"

$destPath = "Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full"

Add-Type -assembly "System.Io.Compression.FileSystem"

$zipFilePath = $sourcePath + "\" + $zipFile

[Io.Compression.ZipFile]::ExtractToDirectory($zipFilePath, $destPath)

Exception calling "ExtractToDirectory" with "2" argument(s): "The archive entry was compressed using an unsupported compression method."
At line:1 char:1
+ [Io.Compression.ZipFile]::ExtractToDirectory($zipFilePath, $destPath)
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [], MethodInvocationException
    + FullyQualifiedErrorId : InvalidDataException
```

##### Workaround

Extract zip file using Windows Explorer

Path: **Z:\\Microsoft SQL Server\\MSSQL12.MSSQLSERVER\\MSSQL\\Backup\\Full**

```PowerShell
cls
```

#### # Restore content databases for SecuritasConnect

##### # Remove existing content databases

```PowerShell
Remove-SPContentDatabase WSS_Content_SecuritasPortal -Confirm:$false -Force

Remove-SPContentDatabase WSS_Content_SecuritasPortal2 -Confirm:$false -Force
```

##### # Restore database backups from Production

```PowerShell
$backup1 = "WSS_Content_SecuritasPortal_backup_2016_11_20_000009_8804925.bak"
$backup2 = "WSS_Content_SecuritasPortal2_backup_2016_11_20_000009_8960930.bak"

$stopwatch = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-Stopwatch.ps1

$sqlcmd = @"
DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\$backup1'

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
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\$backup2'

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
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:

$stopwatch.Stop()
C:\NotBackedUp\Public\Toolbox\PowerShell\Write-ElapsedTime.ps1 $stopwatch
```

> **Note**
>
> Expect the previous operation to complete in approximately 41 minutes.\
> RESTORE DATABASE successfully processed 4001436 pages in 433.263 seconds (72.152 MB/sec).\
> ...\
> RESTORE DATABASE successfully processed 3396484 pages in 852.291 seconds (31.133 MB/sec).

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
> Expect the previous operation to complete in approximately 5 minutes.

```PowerShell
cls
```

### # Restore application settings from UAT

```PowerShell
cd C:\Shares\Builds\ClientPortal\4.0.677.0\DeploymentFiles\Scripts

Import-Csv "\\ICEMAN\Archive\Clients\Securitas\AppSettings-UAT_2016-11-10.csv" |
    ForEach-Object {
        .\Set-AppSetting.ps1 $_.Key $_.Value $_.Description -Force -Verbose
    }
```

```PowerShell
cls
```

### # Add Branch Managers domain group to Post Orders template site

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

### # Replace site collection administrators

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

    $user = $site.RootWeb.EnsureUser("EXTRANET\SharePoint Admins (DEV)");
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
> Expect the previous operation to complete in approximately 1 hour and 5 minutes.

```PowerShell
cls
```

### # Restore Cloud Portal database backup

#### # Copy database backup

```PowerShell
$backupFile = `
    "WSS_Content_CloudPortal_backup_2016_11_20_000009_8960930.bak"

$sourcePath = "\\ICEMAN\Archive\Clients\Securitas\Backups"

$destPath = "Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full"

robocopy $sourcePath $destPath $backupFile
```

#### # Remove existing content databases

```PowerShell
Remove-SPContentDatabase WSS_Content_CloudPortal -Confirm:$false -Force
```

#### # Restore database backup from Production

```PowerShell
$stopwatch = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-Stopwatch.ps1

$sqlcmd = @"
DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\$backupFile'

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
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:

$stopwatch.Stop()
C:\NotBackedUp\Public\Toolbox\PowerShell\Write-ElapsedTime.ps1 $stopwatch
```

> **Note**
>
> Expect the previous operation to complete in approximately 1 hour and 2 minutes.\
> RESTORE DATABASE successfully processed 7585919 pages in 2789.467 seconds (21.245 MB/sec).

```PowerShell
cls
```

#### # Attach content database

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
> Expect the previous operation to complete in approximately 5 seconds.

```PowerShell
cls
```

#### # Configure permissions for FABRIKAM and TECHTOOLBOX users

```PowerShell
Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

$supportedDomains = ("FABRIKAM", "TECHTOOLBOX")
```

##### # Add domain users to Cloud Portal site

```PowerShell
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
```

##### # Add domain users to Employee Portal SharePoint site

```PowerShell
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
```

##### # Allow domain users to upload profile pictures in Employee Portal

```PowerShell
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

```PowerShell
cls
```

### # Remove old database backups

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Remove-OldBackups.ps1 `
    -NumberOfDaysToKeep 0
```

### # Start job to backup all databases

```PowerShell
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") |
    Out-Null

$sqlServer = New-Object Microsoft.SqlServer.Management.Smo.Server $HostName

$job = ($sqlServer.JobServer.Jobs |
    ? { $_.Name -eq "Full Backup of All Databases.Subplan_1" })

$job.Start()
```

```PowerShell
cls
```

### # Reset search index and perform full crawl

```PowerShell
Enable-SharePointCmdlets

$serviceApp = Get-SPEnterpriseSearchServiceApplication
```

#### # Reset search index

```PowerShell
$serviceApp.Reset($false, $false)
```

#### # Start full crawl

```PowerShell
$serviceApp |
    Get-SPEnterpriseSearchCrawlContentSource |
    % { $_.StartFullCrawl() }
```

> **Note**
>
> Expect the crawl to complete in approximately 6 hours 50 minutes.

## Increase Data01 drive from 150 GB to 185 GB

## Upgrade SecuritasConnect to "v4.0 Sprint-27" release

### # Copy new build from TFS drop location

```PowerShell
net use \\ICEMAN\Builds /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$newBuild = "4.0.678.0"

$sourcePath = "\\ICEMAN\Builds\Securitas\ClientPortal\$newBuild"
$destPath = "C:\Shares\Builds\ClientPortal\$newBuild"

robocopy $sourcePath $destPath /E
```

### # Remove previous versions of SecuritasConnect WSPs

```PowerShell
$oldBuild = "4.0.677.0"

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

### # Delete old build

```PowerShell
Remove-Item C:\Shares\Builds\ClientPortal\4.0.677.0 `
   -Recurse -Force
```

## Upgrade Employee Portal to "v1.0 Sprint-5" release

### # Copy new build from TFS drop location

```PowerShell
net use \\ICEMAN\Builds /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$build = "1.0.32.0"

$sourcePath = "\\ICEMAN\Builds\Securitas\EmployeePortal\$build"
$destPath = "C:\Shares\Builds\EmployeePortal\$build"

robocopy $sourcePath $destPath /E
```

### # Backup Employee Portal Web.config file

```PowerShell
$websiteName = "employee-local-2.securitasinc.com"

copy C:\inetpub\wwwroot\$websiteName\Web.config `
    "C:\NotBackedUp\Temp\Web - $websiteName.config"
```

### # Deploy Employee Portal website on Central Administration server

```PowerShell
Push-Location ("C:\Shares\Builds\EmployeePortal\$build" `
    + "\Release\_PublishedWebsites\Web_Package")

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
    value="employee-local-2.securitasinc.com" />
  <setParameter
    name="SecuritasPortal-Web.config Connection String"
    value="Server=.; Database=SecuritasPortal; Integrated Security=true" />
  <setParameter
    name="SecuritasPortalDbContext-Web.config Connection String"
    value="Data Source=.; Initial Catalog=SecuritasPortal;
 Integrated Security=True; MultipleActiveResultSets=True;" />
</parameters>
```

---

```PowerShell
.\Web.deploy.cmd /t

.\Web.deploy.cmd /y

Pop-Location
```

### # Configure application settings and web service URLs

```PowerShell
$websiteName = "employee-local-2.securitasinc.com"

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    "C:\NotBackedUp\Temp\Web - $websiteName.config" `
    C:\inetpub\wwwroot\$websiteName\Web.config
```

### Deploy website content to other web servers in the farm

(skipped)

```PowerShell
cls
```

### # Configure Employee Portal navigation items

```PowerShell
Push-Location ("C:\Shares\Builds\EmployeePortal\$build" `
    + "\Deployment Files\Scripts")

.\Set-Navigation.ps1 -State app.search -Title Search -Icon fa-search -Label New

.\Set-Navigation.ps1 -State app.directory -Label "" -Force

Pop-Location
```

```PowerShell
cls
```

### # Delete old build

```PowerShell
Remove-Item C:\Shares\Builds\EmployeePortal\1.0.29.0 -Recurse -Force
```

## Upgrade SecuritasConnect to "v4.0 Sprint-28" release

### Login as EXTRANET\\setup-sharepoint-dev

---

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Copy new build from TFS drop location

```PowerShell
$newBuild = "4.0.681.0"

$sourcePath = "\\TT-FS01\Builds\Securitas\ClientPortal\$newBuild"

$destPath = "\\EXT-FOOBAR2.extranet.technologytoolbox.com\Builds" `
    + "\ClientPortal\$newBuild"

robocopy $sourcePath $destPath /E
```

---

```PowerShell
cls
```

### # Remove previous versions of SecuritasConnect WSPs

```PowerShell
$oldBuild = "4.0.678.0"

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
$newBuild = "4.0.681.0"

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

### # Delete old build

```PowerShell
Remove-Item C:\Shares\Builds\ClientPortal\4.0.678.0 `
   -Recurse -Force
```

## Refresh SecuritasPortal database from Production

### # Restore SecuritasPortal database backup

```PowerShell
$backupFile = "SecuritasPortal.bak"
```

#### # Restore database backup from Production

```PowerShell
$sqlcmd = @"
DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\$backupFile'

DECLARE @dataFilePath VARCHAR(255) =
  'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'SecuritasPortal.mdf'

DECLARE @logFilePath VARCHAR(255) =
  'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'SecuritasPortal_log.LDF'

RESTORE DATABASE SecuritasPortal
  FROM DISK = @backupFilePath
  WITH FILE = 1,
    MOVE 'SecuritasPortal' TO @dataFilePath,
    MOVE 'SecuritasPortal_log' TO @logFilePath,
    NOUNLOAD,
    REPLACE,
    STATS = 5

GO
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
```

#### # Configure permissions for SecuritasPortal database

```PowerShell
[string] $employeePortalUrl = $env:SECURITAS_CLIENT_PORTAL_URL.Replace(
    "client", "employee")

[Uri] $tempUri = [Uri] $employeePortalUrl

[string] $employeePortalHostHeader = $tempUri.Host

$sqlcmd = @"
USE [SecuritasPortal]
GO

CREATE USER [EXTRANET\s-sp-farm-dev] FOR LOGIN [EXTRANET\s-sp-farm-dev]
GO
ALTER ROLE [aspnet_Membership_BasicAccess] ADD MEMBER [EXTRANET\s-sp-farm-dev]
GO
ALTER ROLE [aspnet_Membership_ReportingAccess] ADD MEMBER [EXTRANET\s-sp-farm-dev]
GO
ALTER ROLE [aspnet_Roles_BasicAccess] ADD MEMBER [EXTRANET\s-sp-farm-dev]
GO
ALTER ROLE [aspnet_Roles_ReportingAccess] ADD MEMBER [EXTRANET\s-sp-farm-dev]
GO

CREATE USER [EXTRANET\s-web-client-dev] FOR LOGIN [EXTRANET\s-web-client-dev]
GO
ALTER ROLE [aspnet_Membership_FullAccess] ADD MEMBER [EXTRANET\s-web-client-dev]
GO
ALTER ROLE [aspnet_Profile_BasicAccess] ADD MEMBER [EXTRANET\s-web-client-dev]
GO
ALTER ROLE [aspnet_Roles_BasicAccess] ADD MEMBER [EXTRANET\s-web-client-dev]
GO
ALTER ROLE [aspnet_Roles_ReportingAccess] ADD MEMBER [EXTRANET\s-web-client-dev]
GO
ALTER ROLE [Customer_Reader] ADD MEMBER [EXTRANET\s-web-client-dev]
GO

CREATE USER [IIS APPPOOL\$employeePortalHostHeader]
FOR LOGIN [IIS APPPOOL\$employeePortalHostHeader]
GO
EXEC sp_addrolemember N'Employee_FullAccess',
    N'IIS APPPOOL\$employeePortalHostHeader'

GO

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

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
```

#### # Associate users to TECHTOOLBOX\\smasters

```PowerShell
$sqlcmd = @"
USE [SecuritasPortal]
GO

INSERT INTO Customer.BranchManagerAssociatedUsers
SELECT 'TECHTOOLBOX\smasters', AssociatedUserName
FROM Customer.BranchManagerAssociatedUsers
WHERE BranchManagerUserName = 'PNKUS\jjameson'
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
```

#### HACK: Update TrackTik password for Angela.Parks

[https://client-local-2.securitasinc.com/\_layouts/Securitas/EditProfile.aspx](https://client-local-2.securitasinc.com/_layouts/Securitas/EditProfile.aspx)

#### HACK: Update TrackTik password for bbarthelemy-demo

[https://client-local-2.securitasinc.com/\_layouts/Securitas/EditProfile.aspx](https://client-local-2.securitasinc.com/_layouts/Securitas/EditProfile.aspx)

## Expand C: drive

---

**FOOBAR10** - Run as administrator

### # Expand primary VHD for virtual machine

```PowerShell
$vmName = "EXT-FOOBAR2"
$vmHost = "TT-HV02B"

Stop-VM -ComputerName $vmHost -Name $vmName

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

Resize-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 80GB

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### # Expand C: partition

```PowerShell
$maxSize = (Get-PartitionSupportedSize -DriveLetter C).SizeMax

Resize-Partition -DriveLetter C -Size $maxSize
```

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

**TT-VMM01A** - Run as administrator

```PowerShell
cls
```

### # Configure static IP address using VMM

```PowerShell
$vmName = "EXT-FOOBAR2"

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

## Upgrade SecuritasConnect to "v4.0 Sprint-28" QFE release

---

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Copy new build from TFS drop location

```PowerShell
$newBuild = "4.0.681.1"

$sourcePath = "\\TT-FS01\Builds\Securitas\ClientPortal\$newBuild"

$destPath = "\\EXT-FOOBAR2.extranet.technologytoolbox.com\Builds" `
    + "\ClientPortal\$newBuild"

robocopy $sourcePath $destPath /E
```

---

```PowerShell
cls
```

### # Upgrade SecuritasConnect WSPs

```PowerShell
$newBuild = "4.0.681.1"

Push-Location ("C:\Shares\Builds\ClientPortal\$newBuild" `
    + "\DeploymentFiles\Scripts")

& '.\Upgrade Solutions.ps1' -Verbose

Pop-Location
```

```PowerShell
cls
```

### # Delete old build

```PowerShell
Remove-Item C:\Shares\Builds\ClientPortal\4.0.681.0 `
   -Recurse -Force
```

## Expand D: (Data01) drive

---

**FOOBAR10** - Run as administrator

```PowerShell
cls
```

### # Increase the size of "Data01" VHD

```PowerShell
$vmHost = "TT-HV02B"
$vmName = "EXT-FOOBAR2"

Resize-VHD `
    -ComputerName $vmHost `
    -Path ("E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
        + $vmName + "_Data01.vhdx") `
    -SizeBytes 210GB
```

---

```PowerShell
cls
```

### # Extend partition

```PowerShell
$size = (Get-PartitionSupportedSize -DiskNumber 1 -PartitionNumber 1)
Resize-Partition -DiskNumber 1 -PartitionNumber 1 -Size $size.SizeMax
```

## Refresh content from Production

```PowerShell
cls
```

### # Pause Search Service Application

```PowerShell
Enable-SharePointCmdlets

Get-SPEnterpriseSearchServiceApplication "Search Service Application" |
    Suspend-SPEnterpriseSearchServiceApplication
```

### Restore SecuritasPortal database backup

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

#### # Copy database backup

```PowerShell
$backupFile = "SecuritasPortal_backup_2017_06_18_000015_3063449.bak"

$sourcePath = "\\TT-FS01\Archive\Clients\Securitas\Backups"

$destPath = "\\EXT-FOOBAR2.extranet.technologytoolbox.com\Z$" `
    + "\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full"

robocopy $sourcePath $destPath $backupFile
```

---

```PowerShell
cls
```

#### # Stop IIS

```PowerShell
iisreset /stop
```

#### # Restore database backup

```PowerShell
$backupFile = "SecuritasPortal_backup_2017_06_18_000015_3063449.bak"

$sqlcmd = @"
DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\$backupFile'

DECLARE @dataFilePath VARCHAR(255) =
  'D:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'SecuritasPortal.mdf'

DECLARE @logFilePath VARCHAR(255) =
  'L:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data\'
    + 'SecuritasPortal_log.LDF'

RESTORE DATABASE SecuritasPortal
  FROM DISK = @backupFilePath
  WITH FILE = 1,
    MOVE 'SecuritasPortal' TO @dataFilePath,
    MOVE 'SecuritasPortal_log' TO @logFilePath,
    NOUNLOAD,
    REPLACE,
    STATS = 5

GO
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
```

#### # Configure permissions for SecuritasPortal database

```PowerShell
[string] $employeePortalUrl = $env:SECURITAS_CLIENT_PORTAL_URL.Replace(
    "client", "employee")

[Uri] $tempUri = [Uri] $employeePortalUrl

[string] $employeePortalHostHeader = $tempUri.Host

$sqlcmd = @"
USE [SecuritasPortal]
GO

CREATE USER [EXTRANET\s-sp-farm-dev] FOR LOGIN [EXTRANET\s-sp-farm-dev]
GO
ALTER ROLE [aspnet_Membership_BasicAccess] ADD MEMBER [EXTRANET\s-sp-farm-dev]
GO
ALTER ROLE [aspnet_Membership_ReportingAccess] ADD MEMBER [EXTRANET\s-sp-farm-dev]
GO
ALTER ROLE [aspnet_Roles_BasicAccess] ADD MEMBER [EXTRANET\s-sp-farm-dev]
GO
ALTER ROLE [aspnet_Roles_ReportingAccess] ADD MEMBER [EXTRANET\s-sp-farm-dev]
GO

CREATE USER [EXTRANET\s-web-client-dev] FOR LOGIN [EXTRANET\s-web-client-dev]
GO
ALTER ROLE [aspnet_Membership_FullAccess] ADD MEMBER [EXTRANET\s-web-client-dev]
GO
ALTER ROLE [aspnet_Profile_BasicAccess] ADD MEMBER [EXTRANET\s-web-client-dev]
GO
ALTER ROLE [aspnet_Roles_BasicAccess] ADD MEMBER [EXTRANET\s-web-client-dev]
GO
ALTER ROLE [aspnet_Roles_ReportingAccess] ADD MEMBER [EXTRANET\s-web-client-dev]
GO
ALTER ROLE [Customer_Reader] ADD MEMBER [EXTRANET\s-web-client-dev]
GO

CREATE USER [IIS APPPOOL\$employeePortalHostHeader]
FOR LOGIN [IIS APPPOOL\$employeePortalHostHeader]
GO
EXEC sp_addrolemember N'Employee_FullAccess',
    N'IIS APPPOOL\$employeePortalHostHeader'

GO

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

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
```

#### # Associate users to TECHTOOLBOX\\smasters

```PowerShell
$sqlcmd = @"
USE [SecuritasPortal]
GO

INSERT INTO Customer.BranchManagerAssociatedUsers
SELECT 'TECHTOOLBOX\smasters', AssociatedUserName
FROM Customer.BranchManagerAssociatedUsers
WHERE BranchManagerUserName = 'PNKUS\jjameson'
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:
```

#### # Start IIS

```PowerShell
iisreset /start
```

#### Configure TrackTik credentials for Branch Manager

[https://client-local-2.securitasinc.com/\_layouts/Securitas/EditProfile.aspx](https://client-local-2.securitasinc.com/_layouts/Securitas/EditProfile.aspx)

Branch Manager: **TECHTOOLBOX\\smasters**\
TrackTik username:** opanduro2m**

#### HACK: Update TrackTik password for Angela.Parks

[https://client-local-2.securitasinc.com/\_layouts/Securitas/EditProfile.aspx](https://client-local-2.securitasinc.com/_layouts/Securitas/EditProfile.aspx)

#### HACK: Update TrackTik password for bbarthelemy-demo

[https://client-local-2.securitasinc.com/\_layouts/Securitas/EditProfile.aspx](https://client-local-2.securitasinc.com/_layouts/Securitas/EditProfile.aspx)

### Restore SecuritasConnect database backups

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

#### # Copy database backups

```PowerShell
$backupFiles = "WSS_Content_SecuritasPortal*.bak"

$sourcePath = "\\TT-FS01\Archive\Clients\Securitas\Backups"

$destPath = "\\EXT-FOOBAR2.extranet.technologytoolbox.com\Z$" `
    + "\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full"

robocopy $sourcePath $destPath $backupFiles
```

---

```PowerShell
cls
```

#### # Restore content databases for SecuritasConnect

##### # Remove existing content databases

```PowerShell
Remove-SPContentDatabase WSS_Content_SecuritasPortal -Confirm:$false -Force

Remove-SPContentDatabase WSS_Content_SecuritasPortal2 -Confirm:$false -Force
```

##### # Restore database backups from Production

```PowerShell
$backup1 = "WSS_Content_SecuritasPortal_backup_2017_06_18_000015_3063449.bak"
$backup2 = "WSS_Content_SecuritasPortal2_backup_2017_06_18_000015_3063449.bak"

$stopwatch = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-Stopwatch.ps1

$sqlcmd = @"
DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\$backup1'

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
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\$backup2'

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
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:

$stopwatch.Stop()
C:\NotBackedUp\Public\Toolbox\PowerShell\Write-ElapsedTime.ps1 $stopwatch
```

> **Note**
>
> Expect the previous operation to complete in approximately 28 minutes.\
> RESTORE DATABASE successfully processed 3904847 pages in 229.149 seconds (133.130 MB/sec).\
> ...\
> RESTORE DATABASE successfully processed 3679300 pages in 825.713 seconds (34.811 MB/sec).

```PowerShell
cls
```

##### # Attach content databases

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
> Expect the previous operation to complete in approximately 4 minutes.

### Restore application settings from UAT

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

#### # Copy application settings file

```PowerShell
$configFile = "AppSettings-UAT_2017-06-06.csv"

$sourcePath = "\\TT-FS01\Archive\Clients\Securitas\Configuration"

$destPath = "\\EXT-FOOBAR2.extranet.technologytoolbox.com\C$" `
    + "\NotBackedUp\Temp"

robocopy $sourcePath $destPath $configFile
```

---

```PowerShell
cls
```

#### # Import application settings

```PowerShell
Push-Location C:\Shares\Builds\ClientPortal\4.0.681.1\DeploymentFiles\Scripts

Import-Csv "C:\NotBackedUp\Temp\AppSettings-UAT_2017-06-06.csv" |
    ForEach-Object {
        .\Set-AppSetting.ps1 $_.Key $_.Value $_.Description -Force -Verbose
    }

Pop-Location
```

```PowerShell
cls
```

### # Add Branch Managers domain group to Post Orders template site

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

### # Replace site collection administrators

---

File - **C:\\NotBackedUp\\Temp\\Replace Site Collection Administrators.ps1**

```PowerShell
param(
    [parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [String] $Url,
    [String] $AdminUserOrGroup = "EXTRANET\SharePoint Admins (DEV)"
)

begin
{
    Set-StrictMode -Version Latest
    $ErrorActionPreference = "Stop"

    If ((Get-PSSnapin Microsoft.SharePoint.PowerShell `
        -ErrorAction SilentlyContinue) -eq $null)
    {
        Write-Debug "Adding snapin (Microsoft.SharePoint.PowerShell)..."

        $ver = $host | select version

        #If ($ver.Version.Major -gt 1)
        #{
        #    $Host.Runspace.ThreadOptions = "ReuseThread"
        #}

        Add-PSSnapin Microsoft.SharePoint.PowerShell
    }

    Function ReplaceSiteCollectionAdministrators(
        $site,
        $newAdminUserOrGroup)
    {
        Write-Verbose `
            "Replacing site collection administrators on site ($($site.Url))..."

        For ($i = 0; $i -lt $site.RootWeb.SiteAdministrators.Count; $i++)
        {
            $siteAdmin = $site.RootWeb.SiteAdministrators[$i]

            Write-Debug "siteAdmin: $($siteAdmin.LoginName)"

            If ($siteAdmin.DisplayName -eq "SEC\SharePoint Admins")
            {
                Write-Verbose "Removing administrator ($($siteAdmin.DisplayName))..."
                $site.RootWeb.SiteAdministrators.Remove($i)
                $i--
            }
        }

        Write-Debug `
            "Adding SharePoint Admins on site ($($site.Url))..."

        $user = $site.RootWeb.EnsureUser($newAdminUserOrGroup)
        $user.IsSiteAdmin = $true
        $user.Update()

        $output = New-Object PSObject

        $output | Add-Member NoteProperty -Name "Url" `
            -Value $site.Url

        $output | Add-Member NoteProperty -Name "Admin" `
            -Value $newAdminUserOrGroup

        $output
    }
}

process
{
    $site = Get-SPSite -Identity $Url

    Try
    {
        Write-Verbose "Processing site ($($site.Url))..."

        ReplaceSiteCollectionAdministrators $site $AdminUserOrGroup
    }
    Finally
    {
        $site.Dispose()
    }
}
```

---

```PowerShell
Push-Location C:\NotBackedUp\Temp

$stopwatch = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-Stopwatch.ps1

$tempFileName = [System.Io.Path]::GetTempFileName()
$tempFileName = $tempFileName.Replace(".tmp", ".csv")

Get-SPSite -WebApplication $env:SECURITAS_CLIENT_PORTAL_URL -Limit ALL |
    select Url |
    Export-Csv -Path $tempFileName -Encoding UTF8 -NoTypeInformation

Import-Csv $tempFileName |
    select -ExpandProperty Url |
    C:\NotBackedUp\Public\Toolbox\PowerShell\Run-CommandMultiThreaded.ps1 `
        -Command '.\Replace Site Collection Administrators.ps1' `
        -SnapIns 'Microsoft.SharePoint.PowerShell'

$stopwatch.Stop()
C:\NotBackedUp\Public\Toolbox\PowerShell\Write-ElapsedTime.ps1 $stopwatch

Pop-Location
```

> **Note**
>
> Expect the previous operation to complete in approximately 28 minutes.

### Restore Cloud Portal database backup

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

#### # Copy database backups

```PowerShell
$backupFiles = "WSS_Content_CloudPortal*.bak"

$sourcePath = "\\TT-FS01\Archive\Clients\Securitas\Backups"

$destPath = "\\EXT-FOOBAR2.extranet.technologytoolbox.com\Z$" `
    + "\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full"

robocopy $sourcePath $destPath $backupFiles
```

---

```PowerShell
cls
```

#### # Remove existing content databases

```PowerShell
Remove-SPContentDatabase WSS_Content_CloudPortal -Confirm:$false -Force
```

#### # Restore database backup from Production

```PowerShell
$backupFile = `
    "WSS_Content_CloudPortal_backup_2017_06_11_000024_0572930.bak"

$stopwatch = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-Stopwatch.ps1

$sqlcmd = @"
DECLARE @backupFilePath VARCHAR(255) =
  'Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full\$backupFile'

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
"@

Invoke-Sqlcmd $sqlcmd -QueryTimeout 0 -Verbose -Debug:$false

Set-Location C:

$stopwatch.Stop()
C:\NotBackedUp\Public\Toolbox\PowerShell\Write-ElapsedTime.ps1 $stopwatch
```

> **Note**
>
> Expect the previous operation to complete in approximately 46 minutes.\
> RESTORE DATABASE successfully processed 8793457 pages in 2240.932 seconds (30.656 MB/sec).

```PowerShell
cls
```

#### # Attach content database

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
> Expect the previous operation to complete in approximately 6 seconds.

```PowerShell
cls
```

#### # Configure permissions for FABRIKAM and TECHTOOLBOX users

```PowerShell
Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

$supportedDomains = ("FABRIKAM", "TECHTOOLBOX")
```

##### # Add domain users to Cloud Portal site

```PowerShell
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
```

##### # Add domain users to Employee Portal SharePoint site

```PowerShell
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
```

##### # Allow domain users to upload profile pictures in Employee Portal

```PowerShell
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

```PowerShell
cls
```

### # Remove old database backups

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Remove-OldBackups.ps1 `
    -NumberOfDaysToKeep 0
```

### # Backup all databases

```PowerShell
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") |
    Out-Null

$sqlServer = New-Object Microsoft.SqlServer.Management.Smo.Server $HostName

$job = ($sqlServer.JobServer.Jobs |
    ? { $_.Name -eq "Full Backup of All Databases.Subplan_1" })

$job.Start()

Start-Sleep -Seconds 30

Write-Host "Waiting for backup job to complete..."

while ($job.CurrentRunStatus -eq "Executing") {
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 10

    $sqlServer = New-Object Microsoft.SqlServer.Management.Smo.Server $HostName

    $job = ($sqlServer.JobServer.Jobs |
        ? { $_.Name -eq "Full Backup of All Databases.Subplan_1" })
}

Write-Host
```

### # Reset search index and perform full crawl

```PowerShell
Enable-SharePointCmdlets

$serviceApp = Get-SPEnterpriseSearchServiceApplication
```

#### # Reset search index

```PowerShell
$serviceApp.Reset($false, $false)
```

#### # Start full crawl

```PowerShell
$serviceApp |
    Get-SPEnterpriseSearchCrawlContentSource |
    % { $_.StartFullCrawl() }
```

> **Note**
>
> Expect the crawl to complete in approximately 6 hours 45 minutes.

## Deploy federated authentication in SecuritasConnect

### Login as EXTRANET\\setup-sharepoint-dev

### # Pause Search Service Application

```PowerShell
Enable-SharePointCmdlets

Get-SPEnterpriseSearchServiceApplication "Search Service Application" |
    Suspend-SPEnterpriseSearchServiceApplication
```

### # Configure SSL in development environments

#### # Install certificate for secure communication with SecuritasConnect

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

##### # Copy certificate from internal file server

```PowerShell
$certFile = "securitasinc.com.pfx"

$sourcePath = "\\TT-FS01\Archive\Clients\Securitas"

$destPath = "\\EXT-FOOBAR2.extranet.technologytoolbox.com" `
    + "\C$\NotBackedUp\Temp"

Copy-Item "$sourcePath\$certFile" $destPath
```

---

```PowerShell
cls
```

##### # Install certificate

```PowerShell
$certPassword = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted for the secure string, type the password for the exported certificate.

```PowerShell
$certFile = "C:\NotBackedUp\Temp\securitasinc.com.pfx"

Import-PfxCertificate `
    -FilePath $certFile `
    -CertStoreLocation Cert:\LocalMachine\My `
    -Password $certPassword

If ($? -eq $true)
{
    Remove-Item $certFile -Verbose
}
```

#### Add public URLs for HTTPS

| **Alternate Access Mapping Collection**        | **Zone** | **Public URL**                                                                       |
| ---------------------------------------------- | -------- | ------------------------------------------------------------------------------------ |
| SharePoint - client-local-2.securitasinc.com80 | Default  | [http://client-local-2.securitasinc.com](http://client-local-2.securitasinc.com)     |
|                                                | Intranet | [https://client2-local-2.securitasinc.com](https://client2-local-2.securitasinc.com) |
|                                                | Internet | [https://client-local-2.securitasinc.com](https://client-local-2.securitasinc.com)   |
|                                                | Custom   |                                                                                      |
|                                                | Extranet |                                                                                      |
| SharePoint - cloud-local-2.securitasinc.com80  | Default  | [http://cloud-local-2.securitasinc.com](http://cloud-local-2.securitasinc.com)       |
|                                                | Intranet | [https://cloud2-local-2.securitasinc.com](https://cloud2-local-2.securitasinc.com)   |
|                                                | Internet | [https://cloud-local-2.securitasinc.com](https://cloud-local-2.securitasinc.com)     |
|                                                | Custom   |                                                                                      |
|                                                | Extranet |                                                                                      |

```PowerShell
cls
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

[String] $webAppUrl = $env:SECURITAS_CLIENT_PORTAL_URL

New-SPAlternateUrl `
    -Url $webAppUrl.Replace("http://", "https://") `
    -WebApplication $webAppUrl `
    -Zone Internet

$webAppUrl = $env:SECURITAS_CLOUD_PORTAL_URL

New-SPAlternateUrl `
    -Url $webAppUrl.Replace("http://", "https://") `
    -WebApplication $webAppUrl `
    -Zone Internet
```

#### # Unextend web applications

```PowerShell
$webAppUrl = $env:SECURITAS_CLIENT_PORTAL_URL

Remove-SPWebApplication `
    -Identity $webAppUrl `
    -Zone Intranet `
    -DeleteIISSite `
    -Confirm:$false

$webAppUrl = $env:SECURITAS_CLOUD_PORTAL_URL

Remove-SPWebApplication `
    -Identity $webAppUrl `
    -Zone Intranet `
    -DeleteIISSite `
    -Confirm:$false
```

#### # Extend web applications to Intranet zone using SSL

```PowerShell
Push-Location ('C:\Shares\Builds\EmployeePortal\1.0.32.0' `
    + '\Deployment Files\Scripts')

& '.\Extend Web Applications.ps1' -SecureSocketsLayer -Confirm:$false

Pop-Location
```

#### # Add HTTPS bindings to IIS websites

##### # Add HTTPS binding to SecuritasConnect website

```PowerShell
[Uri] $clientPortalUrl = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL

$cert = Get-ChildItem -Path Cert:\LocalMachine\My |
    Where { $_.Subject -like "CN=`*.securitasinc.com,*" }

New-WebBinding `
    -Name ("SharePoint - " + $clientPortalUrl.Host + "80") `
    -Protocol https `
    -Port 443 `
    -HostHeader $clientPortalUrl.Host `
    -SslFlags 0

$cert |
    New-Item `
        -Path ("IIS:\SslBindings\0.0.0.0!443!" + $clientPortalUrl.Host)
```

##### # Add HTTPS binding to Cloud Portal website

```PowerShell
[Uri] $cloudPortalUrl = [Uri] $env:SECURITAS_CLOUD_PORTAL_URL

New-WebBinding `
    -Name ("SharePoint - " + $cloudPortalUrl.Host + "80") `
    -Protocol https `
    -Port 443 `
    -HostHeader $cloudPortalUrl.Host `
    -SslFlags 0
```

##### # Add HTTPS binding to Employee Portal website

```PowerShell
[Uri] $employeePortalUrl = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL.Replace(
    "client",
    "employee")

New-WebBinding `
    -Name $employeePortalUrl.Host `
    -Protocol https `
    -Port 443 `
    -HostHeader $employeePortalUrl.Host `
    -SslFlags 0
```

#### # Change web service URLs (from HTTP to HTTPS) in Employee Portal

```PowerShell
Push-Location ("C:\inetpub\wwwroot\" + $employeePortalUrl.Host)

(Get-Content Web.config) `
    -replace 'http://client2', 'https://client2' `
    -replace 'http://cloud2', 'https://cloud2' `
    -replace 'TransportCredentialOnly', 'Transport' |
    Set-Content Web.config

Pop-Location
```

#### # Enable disk-based caching for Web applications

##### # Enable disk-based caching for SecuritasConnect

```PowerShell
[Uri] $clientPortalUrl = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL

Push-Location ("C:\inetpub\wwwroot\wss\VirtualDirectories\" `
    + $clientPortalUrl.Host + "80")

copy Web.config "Web - Copy.config"

Notepad Web.config
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

```PowerShell
Pop-Location

Push-Location ("C:\inetpub\wwwroot\wss\VirtualDirectories\" `
    + $clientPortalUrl.Host.Replace("client", "client2") + "443")

copy Web.config "Web - Copy.config"

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    ("..\" + $clientPortalUrl.Host + "80\Web.config") `
    Web.config

Pop-Location
```

##### # Enable disk-based caching for Cloud Portal

```PowerShell
[Uri] $cloudPortalUrl = [Uri] $env:SECURITAS_CLOUD_PORTAL_URL

Push-Location ("C:\inetpub\wwwroot\wss\VirtualDirectories\" `
    + $cloudPortalUrl.Host + "80")

copy Web.config "Web - Copy.config"

Notepad Web.config
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

```PowerShell
Pop-Location

Push-Location ("C:\inetpub\wwwroot\wss\VirtualDirectories\" `
    + $cloudPortalUrl.Host.Replace("cloud", "cloud2") + "443")

copy Web.config "Web - Copy.config"

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    ("..\" + $cloudPortalUrl.Host + "80\Web.config") `
    Web.config

Pop-Location
```

---

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Checkpoint VM

```PowerShell
$vmHost = "TT-HV02B"
$vmName = "EXT-FOOBAR2"
$snapshotName = "Configure SSL on all websites and enable BlobCache"

Stop-VM -ComputerName $vmHost -Name $vmName

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName $snapshotName

Start-VM -ComputerName $vmHost -Name $vmName
```

---

---

**EXT-ADFS02A - Run as EXTRANET\\jjameson-admin**

```PowerShell
cls
```

### # Configure relying party in AD FS for SecuritasConnect

#### # Create relying party in AD FS

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
$destination = "\\EXT-FOOBAR2.extranet.technologytoolbox.com\C$"

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

### # Upgrade to "v4.0 Sprint-29" build

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

#### # Copy new build from TFS drop location

```PowerShell
$newBuild = "4.0.697.0"

$sourcePath = "\\TT-FS01\Builds\Securitas\ClientPortal\$newBuild"

$destPath = "\\EXT-FOOBAR2.extranet.technologytoolbox.com\Builds" `
    + "\ClientPortal\$newBuild"

robocopy $sourcePath $destPath /E /NP
```

---

```PowerShell
cls
```

#### # Remove previous versions of SecuritasConnect WSPs

```PowerShell
$oldBuild = "4.0.681.1"

Push-Location ("C:\Shares\Builds\ClientPortal\$oldBuild" `
    + "\DeploymentFiles\Scripts")

& '.\Deactivate Features.ps1' -Verbose

& '.\Retract Solutions.ps1' -Verbose

& '.\Delete Solutions.ps1' -Verbose

Pop-Location
```

#### # Install new versions of SecuritasConnect WSPs

```PowerShell
$newBuild = "4.0.697.0"

Push-Location ("C:\Shares\Builds\ClientPortal\$newBuild" `
    + "\DeploymentFiles\Scripts")

& '.\Add Solutions.ps1' -Verbose

& '.\Deploy Solutions.ps1' -Verbose

& '.\Activate Features.ps1' -Verbose
```

> **Important**
>
> If an error occurs when activating the **Securitas.Portal.Web_ClaimsAuthenticationConfiguration** feature, restart the SharePoint services to reload the ADFS claims provider from the new version of **Securitas.Portal.Web** assembly:
>
> ```PowerShell
> & 'C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts\Restart SharePoint Services.cmd'
> ```
>
> After restarting the services, activate the features again:
>
> ```PowerShell
> & '.\Activate Features.ps1' -Verbose
> ```

```PowerShell
Pop-Location
```

#### # Delete old build

```PowerShell
Remove-Item C:\Shares\Builds\ClientPortal\4.0.681.1 `
   -Recurse -Force
```

### # Install and configure identity provider for client users

---

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Configure name resolution for identity provider website

```PowerShell
Add-DnsServerResourceRecordA `
    -ComputerName TT-DC04 `
    -Name idp-local-2 `
    -IPv4Address 10.1.20.108 `
    -ZoneName technologytoolbox.com
```

---

#### Deploy identity provider website to front-end web servers

##### Install certificate for secure communication with idp.technologytoolbox.com

###### # Create request for Web Server certificate

```PowerShell
& "C:\NotBackedUp\Public\Toolbox\PowerShell\New-CertificateRequest.ps1" `
    -Subject "CN=idp-local-2.technologytoolbox.com,OU=Development,O=Technology Toolbox,L=Parker,S=CO,C=US"
```

###### # Submit certificate request to the Certification Authority

```PowerShell
# Add Active Directory Certificate Services site to the "Trusted sites" zone and browse to the site

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

1. Start Internet Explorer, and browse to Active Directory Certificate Services site ([https://cipher01.corp.technologytoolbox.com/](https://cipher01.corp.technologytoolbox.com/)).
2. On the **Welcome** page, click **Request a certificate**.
3. On the **Advanced Certificate Request** page, click **Submit a certificate request by using a base-64-encoded CMC or PKCS #10 file, or submit a renewal request by using a base-64-encoded PKCS #7 file.**
4. On the **Submit a Certificate Request or Renewal Request** page, in the **Saved Request** text box, paste the contents of the certificate request generated in the previous procedure.
5. In the **Certificate Template** section, select the appropriate certificate template (**Technology Toolbox Web Server**), and then click **Submit**. When prompted to allow the digital certificate operation to be performed, click **Yes**.
6. On the **Certificate Issued** page, click **Download certificate** and save the certificate.

```PowerShell
cls
```

###### # Import the certificate into the certificate store

```PowerShell
$certFile = "C:\Users\setup-sharepoint-dev\Downloads\certnew.cer"

CertReq.exe -Accept $certFile

Remove-Item $certFile
```

##### # Deploy identity provider website to first front-end web server

```PowerShell
Push-Location C:\Shares\Builds\ClientPortal\$newBuild\DeploymentFiles\Scripts

[Uri] $idpUrl = [Uri] $env:SECURITAS_CLIENT_PORTAL_URL.Replace(
    "client",
    "idp")

$idpUrl = [Uri] $idpUrl.AbsoluteUri.Replace(
    "securitasinc.com",
    "technologytoolbox.com")

& '.\Configure Identity Provider Website.ps1' `
    -SiteName $idpUrl.Host `
    -Confirm:$false

Pop-Location
```

###### # Add HTTPS binding to identity provider website

```PowerShell
New-WebBinding `
    -Name $idpUrl.Host `
    -Protocol https `
    -Port 443 `
    -HostHeader $idpUrl.Host `
    -SslFlags 1

$cert = Get-ChildItem -Path Cert:\LocalMachine\My |
    Where { $_.Subject -like "CN=$($idpUrl.Host),*" }

New-Item `
    -Path ("IIS:\SslBindings\0.0.0.0!443!" + $idpUrl.Host) `
    -Value $cert `
    -SSLFlags 1
```

###### # Deploy content to identity provider website

```PowerShell
Push-Location C:\Shares\Builds\ClientPortal\$newBuild\Release\_PublishedWebsites\Securitas.Portal.IdentityProvider_Package

attrib -r .\Securitas.Portal.IdentityProvider.SetParameters.xml

$config = Get-Content Securitas.Portal.IdentityProvider.SetParameters.xml

$config = $config -replace `
    "Default Web Site/Securitas.Portal.IdentityProvider_deploy", $idpUrl.Host

$configXml = [xml] $config

$configXml.Save("$pwd\Securitas.Portal.IdentityProvider.SetParameters.xml")

.\Securitas.Portal.IdentityProvider.deploy.cmd /t

.\Securitas.Portal.IdentityProvider.deploy.cmd /y

Pop-Location
```

##### Deploy identity provider website to second web server in farm

(skipped)

```PowerShell
cls
```

#### # Configure database permissions for identity provider website

```PowerShell
$idpHostHeader = $idpUrl.Host

$sqlcmd = @"
USE [master]
GO
CREATE LOGIN [IIS APPPOOL\$idpHostHeader]
FROM WINDOWS
WITH DEFAULT_DATABASE=[master]
GO
USE [SecuritasPortal]
GO
CREATE USER [IIS APPPOOL\$idpHostHeader]
FOR LOGIN [IIS APPPOOL\$idpHostHeader]
GO
EXEC sp_addrolemember N'aspnet_Membership_BasicAccess',
    N'IIS APPPOOL\$idpHostHeader'

EXEC sp_addrolemember N'aspnet_Membership_ReportingAccess',
    N'IIS APPPOOL\$idpHostHeader'

EXEC sp_addrolemember N'aspnet_Roles_BasicAccess',
    N'IIS APPPOOL\$idpHostHeader'

EXEC sp_addrolemember N'aspnet_Roles_ReportingAccess',
    N'IIS APPPOOL\$idpHostHeader'

GO
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

#### # Install and configure token-signing certificate

##### # Install token-signing certificate

```PowerShell
$certPassword = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted for the secure string, type the password for the exported certificate.

```PowerShell
Push-Location ("C:\Shares\Builds\ClientPortal\$newBuild" `
    + "\DeploymentFiles\Certificates")

Import-PfxCertificate `
    -FilePath "Token-signing - idp.securitasinc.com.pfx" `
    -CertStoreLocation Cert:\LocalMachine\My `
    -Password $certPassword

Pop-Location
```

##### # Configure permissions on token-signing certificate

```PowerShell
$serviceAccount = "IIS APPPOOL\$idpHostHeader"
$certThumbprint = "3907EFB9E1B4D549C22200E560D3004778594DDF"

$cert = Get-ChildItem -Path cert:\LocalMachine\My |
    where { $_.ThumbPrint -eq $certThumbprint }

$keyPath = [System.IO.Path]::Combine(
    "$env:ProgramData\Microsoft\Crypto\RSA\MachineKeys",
    $cert.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName)

$acl = Get-Acl -Path $keyPath

$accessRule = New-Object `
    -TypeName System.Security.AccessControl.FileSystemAccessRule `
    -ArgumentList $serviceAccount, "Read", "Allow"

$acl.AddAccessRule($accessRule)

Set-Acl -Path $keyPath -AclObject $acl
```

---

**EXT-ADFS02A - Run as EXTRANET\\jjameson-admin**

```PowerShell
cls
```

#### # Configure claims provider trust in AD FS for identity provider

##### # Create claims provider trust in AD FS

```PowerShell
$idpHostHeader = "idp-local-2.technologytoolbox.com"

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

```PowerShell
cls
```

### # Associate client email domains with claims provider trust

#### # Update email addresses for non-Production environments

##### # Add environment-specific prefix to domain names in email addresses

```PowerShell
$environmentPrefix = "local-2"

$sqlcmd = @"
USE SecuritasPortal
GO

UPDATE dbo.aspnet_Membership
SET
  Email =
    LEFT(Email, CHARINDEX('@', Email, 0) - 1)
      + '@$environmentPrefix.'
      + RIGHT(Email, LEN(Email) - CHARINDEX('@', Email, 0))
WHERE
  Email NOT LIKE '%securitasinc.com'

UPDATE dbo.aspnet_Membership
SET LoweredEmail = LOWER(Email)
WHERE Email NOT LIKE '%securitasinc.com'
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

##### # Update Branch Manager mapping file

```PowerShell
Push-Location ("C:\Shares\Builds\ClientPortal\$newBuild" `
    + "\DeploymentFiles\Scripts")

attrib -r .\Branch-Manager-Mapping.csv

$branchManagerMapping = Import-Csv .\Branch-Manager-Mapping.csv

$branchManagerMapping |
    ForEach-Object {
        $email = $_.EmailAddress

        If (($email.EndsWith("securitasinc.com") -eq $false) `
            -and ($email.EndsWith("technologytoolbox.com") -eq $false))
        {
            $email = $email.Replace("@", "@$environmentPrefix.")
        }

        $output = New-Object -TypeName PSObject

        $output | Add-Member `
            -MemberType NoteProperty `
            -Name BranchManagerUserName `
            -Value $_.BranchManagerUserName

        $output | Add-Member `
            -MemberType NoteProperty `
            -Name EmailAddress `
            -Value $email

        $output
    } |
    Export-Csv `
        -Path .\Branch-Manager-Mapping.csv `
        -Encoding UTF8 `
        -NoTypeInformation

Pop-Location
```

##### # Create input file for synchronizing SharePoint user email addresses

```PowerShell
Push-Location ("C:\Shares\Builds\ClientPortal\$newBuild" `
    + "\DeploymentFiles\Scripts")

$sqlcmd = @"
USE SecuritasPortal
GO

SELECT
    Username AS LoginName
    , Email
FROM
    dbo.aspnet_Users U
    INNER JOIN dbo.aspnet_Membership M
    ON U.UserId = M.UserId
WHERE
    Email NOT LIKE '%securitasinc.com'
ORDER BY
    Username
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false |
    Export-Csv -Path User-Email.csv -Encoding UTF8 -NoTypeInformation

Set-Location C:
```

##### # Synchronize SharePoint user email addresses

```PowerShell
.\Sync-SPUserEmail.ps1 | Format-Table -AutoSize

Pop-Location
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
  '$($idpUrl.Host)' AS TargetName
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

**EXT-ADFS02A - Run as EXTRANET\\jjameson-admin**

```PowerShell
cls
```

#### # Set organizational account suffixes on AD FS claims provider trust

```PowerShell
$configFile = "ADFS-Claims-Provider-Trust-Configuration.csv"
$source = ("\\EXT-FOOBAR2.extranet.technologytoolbox.com\C$" `
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
Push-Location C:\Shares\Builds\ClientPortal\$newBuild\DeploymentFiles\Scripts

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
Push-Location ("C:\Shares\Builds\ClientPortal\$newBuild" `
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
    % {
        $siteUrl = $clientPortalUrl + $_

        $site = Get-SPSite -Identity $siteUrl

        $group = $site.RootWeb.AssociatedVisitorGroup

        $group.Users | % { $group.Users.Remove($_) }

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

**EXT-ADFS02A - Run as EXTRANET\\jjameson-admin**

```PowerShell
cls
```

### # Customize AD FS login pages

#### # Customize text and image on login pages for SecuritasConnect relying party

```PowerShell
$clientPortalUrl = [Uri] "http://client-local-2.securitasinc.com"

$idpHostHeader = "idp-local-2.technologytoolbox.com"

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

Push-Location ("C:\Shares\Builds\CloudPortal\$oldBuild" `
    + "\DeploymentFiles\Scripts")

& '.\Deactivate Features.ps1' -Verbose

& '.\Retract Solutions.ps1' -Verbose

& '.\Delete Solutions.ps1' -Verbose

Pop-Location
```

#### # Install new versions of Cloud Portal WSP

```PowerShell
$newBuild = "2.0.125.0"

Push-Location ("C:\Shares\Builds\CloudPortal\$newBuild" `
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
Remove-Item C:\Shares\Builds\CloudPortal\2.0.122.0 `
   -Recurse -Force
```

### # Upgrade Employee Portal to "v1.0 Sprint-6" release

---

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Copy new build from TFS drop location

```PowerShell
$build = "1.0.38.0"

$sourcePath = "\\TT-FS01\Builds\Securitas\EmployeePortal\$build"

$destPath = "\\EXT-FOOBAR2.extranet.technologytoolbox.com\Builds" `
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
Push-Location ("C:\Shares\Builds\EmployeePortal\$build" `
    + "\Debug\_PublishedWebsites\Web_Package")

attrib -r .\Web.SetParameters.xml

$config = Get-Content Web.SetParameters.xml

$config = $config -replace `
    "Default Web Site/Web_deploy", $employeePortalHostHeader

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
    -replace '<add key="GoogleAnalytics.TrackingId" value="" />',
        '<add key="GoogleAnalytics.TrackingId" value="UA-25949832-3" />' `
    -replace 'https://client-local', 'https://client-local-2' `
    -replace 'https://cloud2-local', 'https://cloud2-local-2' |
    Set-Content Web.config

Pop-Location

C:\NotBackedUp\Public\Toolbox\DiffMerge\x64\sgdm.exe `
    "C:\NotBackedUp\Temp\Web - $employeePortalHostHeader.config" `
    C:\inetpub\wwwroot\$employeePortalHostHeader\Web.config
```

#### Deploy website content to other web servers in the farm

(skipped)

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
Remove-Item C:\Shares\Builds\EmployeePortal\1.0.32.0 -Recurse -Force
```

```PowerShell
cls
```

### # Resume Search Service Application

```PowerShell
Get-SPEnterpriseSearchServiceApplication "Search Service Application" |
    Resume-SPEnterpriseSearchServiceApplication
```

## Issue - "Access Denied" error with SharePoint Trace Service

### Symptom

Numerous ULS log entries:

Process: wsstracing.exe\
Produce: SharePoint Foundation\
Category: Unified Logging Service\
EventID: adr4q\
Level: Unexpected\
Message: Trace Service encountered an unexpected exception when processing usage event. Detail exception message: Create store file error.. Win32 error code=5.

### Problem

**Local Service** account has **Write** permission on Trace Log folder but does not have **Read** permission:

```PowerShell
$logsFolder = ("C:\Program Files\Common Files\microsoft shared" `
    + "\Web Server Extensions\15\LOGS")

icacls $logsFolder

C:\...\15\LOGS BUILTIN\Administrators:(OI)(CI)(F)
               NT AUTHORITY\LOCAL SERVICE:(OI)(CI)(W,Rc,RD,DC)
               ...
```

### Solution

Grant** Local Service** account **Read** permission on Trace Log folder (in addition to **Write** permission):

```PowerShell
$logsFolder = ("C:\Program Files\Common Files\microsoft shared" `
    + "\Web Server Extensions\15\LOGS")

icacls $logsFolder /grant "NT AUTHORITY\LOCAL SERVICE:(OI)(CI)(R,W,DC)"
```

## Upgrade SecuritasConnect to "v4.0 Sprint-31" release

### # Remove missing features from SharePoint sites

```PowerShell
Enable-SharePointCmdlets

Function CreateOutputObject($FeatureId, $SPObject, $Action) {
    $result = New-Object -TypeName PSObject

    $result | Add-Member `
        -MemberType NoteProperty `
        -Name FeatureId `
        -Value $FeatureId

    $result | Add-Member `
        -MemberType NoteProperty `
        -Name Url `
        -Value $SPObject.Url

    $type = $SPObject.GetType()

    $result | Add-Member `
        -MemberType NoteProperty `
        -Name Type `
        -Value $type.Name

    If ($type.Name -eq "SPWeb")
    {
        $result | Add-Member `
            -MemberType NoteProperty `
            -Name CompatibilityLevel `
            -Value $SPObject.Site.CompatibilityLevel
    }
    Else
    {
        $result | Add-Member `
            -MemberType NoteProperty `
            -Name CompatibilityLevel `
            -Value $SPObject.CompatibilityLevel
    }

    $result | Add-Member `
        -MemberType NoteProperty `
        -Name Action `
        -Value $Action

    $result
}

$clientPortalUrl = $env:SECURITAS_CLIENT_PORTAL_URL
$cloudPortalUrl = $env:SECURITAS_CLOUD_PORTAL_URL

If ([string]::IsNullOrEmpty($clientPortalUrl) -eq $true)
{
    # default to Production
    $clientPortalUrl = "http://client.securitasinc.com"
}

If ([string]::IsNullOrEmpty($cloudPortalUrl) -eq $true)
{
    # default to Production
    $cloudPortalUrl = "http://cloud.securitasinc.com"
}

# Deactivate deprecated feature ("Securitas.CloudPortal.Web_EnsureEwikiSiteFeatures")
$featureId = "d4199cf7-e11c-4adf-a300-eb0785a8a9f0"

@(
    "$cloudPortalUrl/sites/2020-Collaboration/Wiki",
    "$cloudPortalUrl/sites/Cloud-Demo/DemoWiki",
    "$cloudPortalUrl/sites/Healthcare/Special Projects Wiki",
    "$cloudPortalUrl/sites/Hyperion-Planning/Wiki",
    "$cloudPortalUrl/sites/IT-Systems-Training-And-Support/enterprisewiki",
    "$cloudPortalUrl/sites/IT-Web-Test/ourwiki",
    "$cloudPortalUrl/sites/My-Training/My Training Wiki",
    "$cloudPortalUrl/sites/Online-Provisioning/Wiki",
    "$cloudPortalUrl/sites/Turning-Point-Solutions/Wiki"
) |
    foreach {
        $web = Get-SPWeb -Identity $_ -ErrorAction SilentlyContinue

        If ($web)
        {
            $feature = $web.Features[$featureId]

            If ($feature)
            {
                CreateOutputObject $featureId $web "Report"

                $web.Features.Remove($featureId, $true)

                CreateOutputObject $featureId $web "Remove"
            }

            $web.Dispose()
        }
    }

# Deactivate Boost site collection feature
# ("Brandysoft.SharePoint.ListCollection") on "Compatibility Level 14" sites

$featureId = "a6204a2f-00c2-40a2-b2dd-fb06c9f87b78"

@(
    "$clientPortalUrl/Template-Sites/Post-Orders-en-CA",
    "$clientPortalUrl/Template-Sites/Post-Orders-en-US",
    "$clientPortalUrl/Template-Sites/Post-Orders-fr-CA"
) |
    foreach {
        $site = Get-SPSite -Identity $_ -ErrorAction SilentlyContinue

        If ($site)
        {
            $feature = $site.Features[$featureId]

            If ($feature)
            {
                CreateOutputObject $featureId $site "Report"

                $site.Features.Remove($featureId, $true)

                CreateOutputObject $featureId $site "Remove"
            }

            $site.Dispose()
        }
    }

# Deactivate Boost site (SPWeb) features on "Compatibility Level 14" sites

$webFeatures = @(
    "3e56c540-af03-4111-a734-f8ff8d903d12",
    "6d9369be-f0ee-429f-b400-5d6be257bc6b"
)

@(
    "$clientPortalUrl/Template-Sites/Post-Orders-en-CA",
    "$clientPortalUrl/Template-Sites/Post-Orders-en-CA/search",
    "$clientPortalUrl/Template-Sites/Post-Orders-en-US",
    "$clientPortalUrl/Template-Sites/Post-Orders-en-US/search",
    "$clientPortalUrl/Template-Sites/Post-Orders-fr-CA",
    "$clientPortalUrl/Template-Sites/Post-Orders-fr-CA/search"
) |
    foreach {
        $web = Get-SPWeb -Identity $_ -ErrorAction SilentlyContinue

        If ($web)
        {
            $webFeatures |
                foreach {
                    $featureId = $_

                    $feature = $web.Features[$featureId]

                    If ($feature)
                    {
                        CreateOutputObject $featureId $web "Report"

                        $web.Features.Remove($featureId, $true)

                        CreateOutputObject $featureId $web "Remove"
                    }
                }

            $web.Dispose()
        }
    }
```

### Install September 12, 2017, cumulative update for SharePoint Server 2013

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

#### # Download update

```PowerShell
$patch = "15.0.4963.1001 - SharePoint 2013 September 2017 CU"
$computerName = "EXT-FOOBAR2.extranet.technologytoolbox.com"

$sourcePath = "\\TT-FS01\Products\Microsoft\SharePoint 2013\Patches\$patch"
$destPath = "\\$computerName\C`$\NotBackedUp\Temp\$patch"

robocopy $sourcePath $destPath /E
```

---

```PowerShell
cls
```

#### # Install update

```PowerShell
$patch = "15.0.4963.1001 - SharePoint 2013 September 2017 CU"

Push-Location "C:\NotBackedUp\Temp\$patch"

& "C:\NotBackedUp\Temp\$patch\Install.ps1"
```

> **Note**
>
> When prompted, type **1** to pause the Search Service Application.

> **Important**
>
> Wait for the update to be installed.

```PowerShell
Pop-Location
```

```PowerShell
cls
Push-Location ("C:\Program Files\Common Files\microsoft shared" `
    + "\Web Server Extensions\15\BIN")

.\PSConfig.exe `
     -cmd upgrade `
     -inplace b2b `
     -wait `
     -cmd applicationcontent `
     -install `
     -cmd installfeatures `
     -cmd secureresources

Pop-Location
```

```PowerShell
cls
Remove-Item "C:\NotBackedUp\Temp\$patch" -Recurse
```

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

### # Copy new build from TFS drop location

```PowerShell
$newBuild = "4.0.705.0"
$computerName = "EXT-FOOBAR2.extranet.technologytoolbox.com"

$sourcePath = "\\TT-FS01\Builds\Securitas\ClientPortal\$newBuild"
$destPath = "\\$computerName\Builds\ClientPortal\$newBuild"

robocopy $sourcePath $destPath /E
```

---

```PowerShell
cls
```

### # Remove previous versions of SecuritasConnect WSPs

```PowerShell
$oldBuild = "4.0.701.0"

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
$newBuild = "4.0.705.0"

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

### # Delete old build

```PowerShell
Remove-Item C:\Shares\Builds\ClientPortal\4.0.701.0 -Recurse -Force
```

### Install September 12, 2017, security update for Office Web Apps Server 2013

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

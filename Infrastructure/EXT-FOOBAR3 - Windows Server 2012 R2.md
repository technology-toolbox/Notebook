# EXT-FOOBAR3 - Windows Server 2012 R2 Standard

Wednesday, May 25, 2016
4:49 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

### Install Windows Server 2012 R2

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

#### # Create virtual machine

```PowerShell
$vmHost = "STORM"
$vmName = "EXT-FOOBAR3"

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path E:\NotBackedUp\VMs `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 60GB `
    -MemoryStartupBytes 10GB `
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

#### Install custom Windows Server 2012 R2 image

- Start-up disk: [\\\\ICEMAN\\Products\\Microsoft\\MDT-Deploy-x86.iso](\\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso)
- On the **Task Sequence** step, select **Windows Server 2012 R2** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **EXT-FOOBAR3**.
  - Select **Join a workgroup**.
  - In the **Workgroup **box, type **WORKGROUP**.
  - Click **Next**.
- On the **Applications** step, ensure no items are selected and click **Next**.

```PowerShell
cls
```

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

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Remove disk from virtual CD/DVD drive

```PowerShell
$vmHost = "STORM"
$vmName = "EXT-FOOBAR3"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

---

### Login as EXT-FOOBAR3\\foo

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

#### # Disable DHCP

```PowerShell
@("IPv4", "IPv6") | ForEach-Object {
    $addressFamily = $_

    $interface = Get-NetAdapter $interfaceAlias |
        Get-NetIPInterface -AddressFamily $addressFamily

    If ($interface.Dhcp -eq "Enabled")
    {
        # Remove existing gateway
        $ipConfig = $interface | Get-NetIPConfiguration

        If ($ipConfig.Ipv4DefaultGateway -or $ipConfig.Ipv6DefaultGateway)
        {
            $interface |
                Remove-NetRoute -AddressFamily $addressFamily -Confirm:$false
        }

        # Disable DHCP
        $interface | Set-NetIPInterface -DHCP Disabled
    }
}
```

#### # Configure static IPv4 address

```PowerShell
$ipAddress = "192.168.10.217"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24 `
    -DefaultGateway 192.168.10.1
```

##### # Configure IPv4 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 192.168.10.209,192.168.10.210
```

#### # Configure static IPv6 address

```PowerShell
$ipAddress = "2601:282:4201:e500::217"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 64
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

### # Join domain

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
$computerName = "EXT-FOOBAR3"
$targetPath = ("OU=SharePoint Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=extranet,DC=technologytoolbox,DC=com")

Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath

Restart-Computer $computerName
```

---

### Login as EXTRANET\\setup-sharepoint-dev

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

## DEV - Configure VM storage, processors, and memory

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 50 GB       | 4K                   |              |
| 1    | D:           | 3 GB        | 64K                  | Data01       |
| 2    | L:           | 1 GB        | 64K                  | Log01        |
| 3    | T:           | 1 GB        | 64K                  | Temp01       |
| 4    | Z:           | 10 GB       | 4K                   | Backup01     |

---

**FOOBAR8**

```PowerShell
cls
```

### # Create Data01, Log01, Temp01, and Backup01 VHDs

```PowerShell
$vmHost = "STORM"
$vmName = "EXT-FOOBAR3"

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName" `
    + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 3GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ControllerType SCSI `
    -Path $vhdPath

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName" `
    + "_Log01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 1GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ControllerType SCSI `
    -Path $vhdPath

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName" `
    + "_Temp01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 1GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ControllerType SCSI `
    -Path $vhdPath

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName" `
    + "_Backup01.vhdx"

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
        -AllocationUnitSize 64KB `
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
        -AllocationUnitSize 64KB `
        -FileSystem NTFS `
        -NewFileSystemLabel "Log01" `
        -Confirm:$false
```

#### # Format Temp01 drive

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

#### # Format Backup01 drive

```PowerShell
Get-Disk 4 |
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -DriveLetter Z -UseMaximumSize |
    Format-Volume `
        -FileSystem NTFS `
        -NewFileSystemLabel "Backup01" `
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

#### # Create service account for SharePoint 2013 farm (DEV)

```PowerShell
$displayName = "Service account for SharePoint 2013 farm (DEV)"
$defaultUserName = "s-sp-farm-dev"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@extranet.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=Development,DC=extranet,DC=technologytoolbox,DC=com"

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

#### # Create service account for SharePoint 2013 service applications (DEV)

```PowerShell
$displayName = "Service account for SharePoint 2013 service applications (DEV)"
$defaultUserName = "s-sp-serviceapp-dev"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@extranet.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=Development,DC=extranet,DC=technologytoolbox,DC=com"

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

#### # Create service account for indexing content (DEV)

```PowerShell
$displayName = "Service account for indexing content (DEV)"
$defaultUserName = "s-sp-index-dev"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@extranet.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=Development,DC=extranet,DC=technologytoolbox,DC=com"

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

#### # Create service account for SecuritasConnect web app

```PowerShell
$displayName = "Service account for SecuritasConnect Web application (DEV)"
$defaultUserName = "s-web-client-dev"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@extranet.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=Development,DC=extranet,DC=technologytoolbox,DC=com"

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

#### # Create service account for SharePoint 2013 "Portal Super User"

```PowerShell
$displayName = "Service account for SharePoint 2013 `"Portal Super User`" (DEV)"
$defaultUserName = "s-sp-psu-dev"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@extranet.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=Development,DC=extranet,DC=technologytoolbox,DC=com"

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

#### # Create service account for SharePoint 2013 "Portal Super Reader"

```PowerShell
$displayName = "Service account for SharePoint 2013 `"Portal Super Reader`" (DEV)"
$defaultUserName = "s-sp-psr-dev"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@extranet.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=Development,DC=extranet,DC=technologytoolbox,DC=com"

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

#### # Create service account for Cloud Portal web app

```PowerShell
$displayName = "Service account for Cloud Portal Web application (DEV)"
$defaultUserName = "s-web-cloud-dev"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@extranet.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=Development,DC=extranet,DC=technologytoolbox,DC=com"

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

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Mount SQL Server 2014 installation media

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\SQL Server 2014" `
    + "\en_sql_server_2014_developer_edition_with_service_pack_1_x64_dvd_6668542.iso"

Set-VMDvdDrive -ComputerName STORM -VMName EXT-FOOBAR3 -Path $imagePath
```

---

```PowerShell
& X:\setup.exe
```

---

**SQL Server Management Studio**

### -- DEV - Change databases to Simple recovery model

```SQL
IF OBJECT_ID('tempdb..#CommandQueue') IS NOT NULL DROP TABLE #CommandQueue

CREATE TABLE #CommandQueue
(
    ID INT IDENTITY ( 1, 1 )
    , SqlStatement VARCHAR(1000)
)

INSERT INTO #CommandQueue
(
    SqlStatement
)
SELECT
    'ALTER DATABASE [' + name + '] SET RECOVERY SIMPLE'
FROM
    sys.databases
WHERE
    name NOT IN ( 'master', 'msdb', 'tempdb' )

DECLARE @id INT

SELECT @id = MIN(ID)
FROM #CommandQueue

WHILE @id IS NOT NULL
BEGIN
    DECLARE @sqlStatement VARCHAR(1000)

    SELECT
        @sqlStatement = SqlStatement
    FROM
        #CommandQueue
    WHERE
        ID = @id

    PRINT 'Executing ''' + @sqlStatement + '''...'

    EXEC (@sqlStatement)

    DELETE FROM #CommandQueue
    WHERE ID = @id

    SELECT @id = MIN(ID)
    FROM #CommandQueue
END
```

---

---

**SQL Server Management Studio**

### -- DEV - Constrain maximum memory for SQL Server

```SQL
EXEC sys.sp_configure N'show advanced options', N'1'
RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'max server memory (MB)', N'1024'
RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'show advanced options', N'0'
RECONFIGURE WITH OVERRIDE
GO
```

---

---

**SQL Server Management Studio**

### -- Configure TempDB data and log files

```SQL
ALTER DATABASE [tempdb]
  MODIFY FILE
  (
    NAME = N'tempdev'
    , SIZE = 128MB
    , FILEGROWTH = 10MB
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
      + ', SIZE = 128MB'
      + ', FILEGROWTH = 10MB'
    + ')';

EXEC sp_executesql @sqlStatement;

SELECT @sqlStatement =
  N'ALTER DATABASE [tempdb]'
    + 'ADD FILE'
    + '('
      + 'NAME = N''tempdev3'''
      + ', FILENAME = ''' + @dataPath + '3.mdf'''
      + ', SIZE = 128MB'
      + ', FILEGROWTH = 10MB'
    + ')';

EXEC sp_executesql @sqlStatement;

SELECT @sqlStatement =
  N'ALTER DATABASE [tempdb]'
    + 'ADD FILE'
    + '('
      + 'NAME = N''tempdev4'''
      + ', FILENAME = ''' + @dataPath + '4.mdf'''
      + ', SIZE = 128MB'
      + ', FILEGROWTH = 10MB'
    + ')';

EXEC sp_executesql @sqlStatement;
ALTER DATABASE [tempdb]
  MODIFY FILE (
    NAME = N'templog',
    SIZE = 50MB,
    FILEGROWTH = 10MB
  )
```

---

---

**SQL Server Management Studio**

### -- Configure "Max Degree of Parallelism" for SharePoint

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

---

```PowerShell
cls
```

### # Configure permissions on \\Windows\\System32\\LogFiles\\Sum files

```PowerShell
icacls C:\Windows\System32\LogFiles\Sum\Api.chk `
    /grant "NT Service\MSSQLSERVER:(M)"

icacls C:\Windows\System32\LogFiles\Sum\Api.log `
    /grant "NT Service\MSSQLSERVER:(M)"

icacls C:\Windows\System32\LogFiles\Sum\SystemIdentity.mdb `
    /grant "NT Service\MSSQLSERVER:(M)"
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

### DEV - Install Microsoft Office 2016 (Recommended)

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Mount Office Professional Plus 2016 installation media

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\Office 2016" `
    + "\en_office_professional_plus_2016_x86_x64_dvd_6962141.iso"

Set-VMDvdDrive -ComputerName STORM -VMName EXT-FOOBAR3 -Path $imagePath
```

---

```Console
X:
.\setup.exe /AUTORUN
```

```Console
cls
```

### # DEV - Install Microsoft SharePoint Designer 2013 (Recommended)

```PowerShell
net use \\ICEMAN\Products /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
& "\\ICEMAN\Products\Microsoft\SharePoint Designer 2013\en_sharepoint_designer_2013_with_sp1_x86_3948134.exe"
```

### DEV - Install Microsoft Visio 2016 (Recommended)

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Mount Visio Professional 2016 installation media

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\Visio 2016" `
    + "\en_visio_professional_2016_x86_x64_dvd_6962139.iso"

Set-VMDvdDrive -ComputerName STORM -VMName EXT-FOOBAR3 -Path $imagePath
```

---

```Console
X:
.\setup.exe /AUTORUN
```

```Console
cls
```

### # DEV - Install additional browsers and software (Recommended)

#### # Install Mozilla Firefox

```PowerShell
& "\\ICEMAN\Products\Mozilla\Firefox\Firefox Setup 46.0.1.exe"
```

```PowerShell
cls
```

#### # Install Google Chrome

```PowerShell
& "\\ICEMAN\Products\Google\Chrome\ChromeStandaloneSetup.exe"
```

### Install additional service packs and updates

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

Set-VMDvdDrive -ComputerName STORM -VMName EXT-FOOBAR3 -Path $imagePath
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

### DEV - Install Visual Studio 2015 with Update 2

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Mount Visual Studio 2012 with Update 2 installation media

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\Visual Studio 2015" `
    + "\en_visual_studio_enterprise_2015_with_update_2_x86_x64_dvd_8510142.iso"

Set-VMDvdDrive -ComputerName STORM -VMName EXT-FOOBAR3 -Path $imagePath
```

---

```PowerShell
& X:\vs_enterprise.exe
```

In the Visual Studio installation wizard:

1. Select the **Custom** installation option and click **Next**.
2. In the list of features, select the following items:
3. **Microsoft Office Developer Tools**
4. **Microsoft SQL Server Data Tools**
5. **Microsoft Web Developer Tools**
6. Click **Next**.
7. Review the list of selected features and click **Install**.

When prompted to restart the computer, click **Restart Now**.

### DEV - Enter product key for Visual Studio

1. Start Visual Studio.
2. On the **Help** menu, click **Register Product**.
3. In the **Sign in to Visual Studio** window, click **Unlock with a Product Key**.
4. In the **Enter a product key** window, type the product key and click **Apply**.
5. In the **Sign in to Visual Studio** window, click **Close**.

### DEV - Install update for Office developer tools in Visual Studio

**Note: **Microsoft Office Developer Tools Update 2 for Visual Studio 2015

Add **[https://www.microsoft.com](https://www.microsoft.com)** to **Trusted sites** zone

File: OfficeToolsForVS2015.3f.3fen.exe

### TODO: DEV - Install Productivity Power Tools for Visual Studio

### # Copy SecuritasConnect build to SharePoint server

```PowerShell
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

### # Create and configure the farm

> **Important**
>
> Login as **EXTRANET\\setup-sharepoint**

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.661.0\DeploymentFiles\Scripts

& '.\Create Farm.ps1' -CentralAdminAuthProvider NTLM -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-sp-farm-dev**.\
> Expect the previous operation to complete in approximately 5 minutes.

### Add Web servers to the farm

(skipped)

### Add SharePoint Central Administration to the "Local intranet" zone

(skipped -- since the "Create Farm.ps1" script configures this)

```PowerShell
cls
```

### # Grant permissions on DCOM applications for SharePoint

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.661.0\DeploymentFiles\Scripts

& '.\Configure DCOM Permissions.ps1' -Verbose
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

```PowerShell
cls
```

## # Install and configure Office Web Apps

#### # Configure the SharePoint 2013 farm to use Office Web Apps

```PowerShell
New-SPWOPIBinding -ServerName wac.fabrikam.com

Set-SPWOPIZone -zone "external-https"
```

```PowerShell
cls
```

## # Configure SharePoint services and service applications

### # Change the service account for the Distributed Cache

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.661.0\DeploymentFiles\Scripts

& '.\Configure Distributed Cache.ps1' -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-sp-serviceapp-dev**.\
> Expect the previous operation to complete in approximately 7-8 minutes.

```PowerShell
cls
```

### # DEV - Constrain the Distributed Cache

```PowerShell
Update-SPDistributedCacheSize -CacheSizeInMB 150
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
> When prompted for the service account, specify **EXTRANET\\s-sp-serviceapp-dev**.

```PowerShell
cls
```

### # Configure the Managed Metadata Service

#### # Create the Managed Metadata Service

```PowerShell
& '.\Configure Managed Metadata Service.ps1' -Verbose
```

```PowerShell
cls
```

### # Configure the User Profile Service Application

#### # Create the User Profile Service Application

##### Issue

Error starting UPS service (when User Profile Service Application is created by EXTRANET\\setup-sharepoint-dev):

UserProfileApplication.SynchronizeMIIS: Failed to configure ILM, will attempt during next rerun. Exception: System.Data.SqlClient.SqlException (0x80131904): Specified collection 'StringSchemaCollection' cannot be dropped because it is used by object 'EXTRANET\\s-sp-farm-dev.GetObjectCurrent'.\
 at System.Data.SqlClient.SqlConnection.OnError(SqlException exception, Boolean breakConnection, Action`1 wrapCloseInAction)\
 at System.Data.SqlClient.TdsParser.ThrowExceptionAndWarning(TdsParserStateObject stateObj, Boolean callerHasConnectionLock, Boolean asyncClose)\
 at System.Data.SqlClient.TdsParser.TryRun(RunBehavior runBehavior, SqlCommand cmdHandler, SqlDataReader dataStream, BulkCopySimpleResultSet bulkCopyHandler, TdsParserStateObject stateObj, Boolean& dataReady)\
 at System.Data.SqlClient.SqlCommand.RunExecuteNonQueryTds(String methodName, Boolean async, Int32 timeout, Boolean asyncWrite)\
 at System.Data.SqlClient.SqlCommand.InternalExecuteNonQuery(TaskCompletionSource`1 completion, String methodName, Boolean sendToPipe, Int32 timeout, Boolean asyncWrite)\
 at System.Data.SqlClient.SqlCommand.ExecuteNonQuery()\
 at Microsoft.IdentityManagement.SetupUtils.IlmWSSetup.ExecuteSQL(String queryString)\
 at Microsoft.IdentityManagement.SetupUtils.IlmWSSetup.LoadSQLFile(String FileName)\
 at Microsoft.IdentityManagement.SetupUtils.IlmWSSetup.IlmBuildDatabase()\
 at Microsoft.Office.Server.UserProfiles.Synchronization.ILMPostSetupConfiguration.ConfigureIlmWebService(Boolean existingDatabase)\
 at Microsoft.Office.Server.Administration.UserProfileApplication.SetupSynchronizationService(ProfileSynchronizationServiceInstance profileSyncInstance)  ClientConnectionId:56b025c1-09f1-42f4-b8af-b86dfad9010d.

##### Reference

**Avoiding the Default Schema issue when creating the User Profile Service Application using Windows PowerShell**\
From <[http://www.harbar.net/archive/2010/10/30/avoiding-the-default-schema-issue-when-creating-the-user-profile.aspx](http://www.harbar.net/archive/2010/10/30/avoiding-the-default-schema-issue-when-creating-the-user-profile.aspx)>

##### Solution

Create User Profile Service Application as EXTRANET\\s-sp-farm-dev:

```PowerShell
$farmCredential = Get-Credential (Get-SPFarm).DefaultServiceAccount.Name

net localgroup Administrators /add $farmCredential.UserName
Restart-Service SPTimerV4

Start-Process $PSHOME\powershell.exe `
    -Credential $farmCredential `
    -ArgumentList "-Command Start-Process PowerShell.exe -Verb Runas" `
    -Wait
```

---

**PowerShell -- running as EXTRANET\\s-sp-farm-dev**

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
net localgroup Administrators /add EXTRANET\s-sp-farm-dev

Restart-Service SPTimerV4
```

#### Start the User Profile Synchronization Service

```PowerShell
cls
```

#### # Remove SharePoint farm account from local Administrators group

```PowerShell
net localgroup Administrators /delete EXTRANET\s-sp-farm-dev

Restart-Service SPTimerV4
```

#### Configure synchronization connections and import data from Active Directory

| **Connection Name** | **Forest Name**            | **Account Name**        |
| ------------------- | -------------------------- | ----------------------- |
| TECHTOOLBOX         | corp.technologytoolbox.com | TECHTOOLBOX\\svc-sp-ups |
| FABRIKAM            | corp.fabrikam.com          | FABRIKAM\\s-sp-ups      |

### # Create and configure the search service application

```PowerShell
& '.\Configure SharePoint Search.ps1' -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-sp-crawler-dev**.\
> Expect the previous operation to complete in approximately 6 minutes.

```PowerShell
cls
```

#### # Configure people search in SharePoint

```PowerShell
$mySiteHostLocation = "http://client-local.securitasinc.com/sites/my"

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
$mySiteHostUri = [System.Uri] $mySiteHostLocation

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

#### # DEV - Configure performance level for the search crawl component

```PowerShell
Set-SPEnterpriseSearchService -PerformanceLevel Reduced

Restart-Service SPSearchHostController
```

```PowerShell
cls
```

## # Create and configure the Web application

### # Set environment variables

```PowerShell
[Environment]::SetEnvironmentVariable(
  "SECURITAS_CLIENT_PORTAL_URL",
  "http://client-local.securitasinc.com",
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

```PowerShell
cls
```

### # Add the URL for the SecuritasConnect Web site to the "Local intranet" zone

```PowerShell
[string] $registryKey = ("HKCU:\Software\Microsoft\Windows" `
    + "\CurrentVersion\Internet Settings\ZoneMap\EscDomains" `
    + "\client-local.securitasinc.com")

If ((Test-Path $registryKey) -eq $false)
{
    New-Item $registryKey | Out-Null
}

Set-ItemProperty -Path $registryKey -Name http -Value 1
```

---

**FOOBAR8**

### # DEV - Snapshot VM

```PowerShell
$vmHost = "STORM"
$vmName = "EXT-FOOBAR3"

Stop-VM -ComputerName $vmHost -Name $vmName

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName "Baseline SharePoint Server 2013 configuration"

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### # Create the Web application and initial site collections

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\4.0.661.0\DeploymentFiles\Scripts

& '.\Create Web Application.ps1' -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-web-client-dev**.\
> Expect the previous operation to complete in approximately 2 minutes.

```PowerShell
cls
```

### # Restore content database or create initial site collections

#### # Create initial site collections

```PowerShell
& '.\Create Site Collections.ps1' -Verbose
```

> **Note**
>
> Expect the previous operation to complete in approximately 3 minutes.

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

#### # Specify the credentials for accessing the trusted forest

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

{TODO: bunch o' stuff skipped here}

### Configure My Site settings in User Profile service application

[http://client-local.securitasinc.com/sites/my](http://client-local.securitasinc.com/sites/my)

## Deploy the SecuritasConnect solution

---

**Developer Command Prompt for VS2013 - Run as administrator**

```Console
cls
```

### REM DEV - Build Visual Studio solution and package SharePoint projects

```Console
cd C:\NotBackedUp\Securitas\ClientPortal\Main\Code
msbuild SecuritasClientPortal.sln /p:IsPackaging=true
```

```Console
cls
```

### REM Create and configure the SecuritasPortal database

#### REM Create the SecuritasPortal database (or restore a backup)

```Console
pushd C:\NotBackedUp\Securitas\ClientPortal\Main\Code\BusinessModel\Database\Deployment

Install.cmd

popd
```

---

```PowerShell
cls
$sqlcmd = @"
```

#### -- Configure permissions for the SecuritasPortal database

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

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

### # Configure logging

```PowerShell
cd C:\NotBackedUp\Securitas\ClientPortal\Main\Code\DeploymentFiles\Scripts

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

```PowerShell
cls
```

### # Install SecuritasConnect solutions and activate the features

```PowerShell
& '.\Add Solutions.ps1' -Verbose

& '.\Deploy Solutions.ps1' -Verbose

& '.\Activate Features.ps1' -Verbose
```

> **Note**
>
> Expect the previous operations to complete in approximately 4.5 minutes.

```PowerShell
cls
```

#### # Activate the "Securitas - Application Settings" feature

```PowerShell
Start-Process `
    "http://client-local.securitasinc.com/_layouts/15/ManageFeatures.aspx"
```

### # Import template site content

```PowerShell
& '.\Import Template Site Content.ps1' -Verbose
```

> **Note**
>
> Expect the previous operations to complete in approximately 4 minutes.

### Create users in the SecuritasPortal database

```Console
DECLARE @userId UNIQUEIDENTIFIER
SET @userId = '5A7AA105-E6E5-4FA4-987B-9473B0218D8D'

DECLARE @utcTimestamp DATETIME = GETUTCDATE()

EXEC dbo.aspnet_Membership_CreateUser
    @ApplicationName = N'Securitas Portal'
    , @UserName = N'test-abc1'
    , @Password = N'gPMR23Dwxfb9l6tr/ZEbqniDFAM = '
    , @PasswordSalt = N'L0n3JqA8UijqS+If66NxMw =  = '
    , @Email = N'test-abc1@foobar.com'
    , @PasswordQuestion = NULL
    , @PasswordAnswer = NULL
    , @IsApproved = 1
    , @UniqueEmail = 1
    , @PasswordFormat = 1
    , @CurrentTimeUtc = @utcTimestamp
    , @UserId = @userId output

GO

DECLARE @userId UNIQUEIDENTIFIER
SET @userId = 'A11AA014-C7BB-4666-8C8D-2E06A283EFAA'

DECLARE @utcTimestamp DATETIME = GETUTCDATE()

EXEC dbo.aspnet_Membership_CreateUser
    @ApplicationName = N'Securitas Portal'
    , @UserName = N'test-lite1'
    , @Password = N'OJKhTDAoFv9ZkJvdwWq4KhxkE6w = '
    , @PasswordSalt = N'izDNv8bs5M4mpU4WApoPMg =  = '
    , @Email = N'test-lite1@foobar.com'
    , @PasswordQuestion = NULL
    , @PasswordAnswer = NULL
    , @IsApproved = 1
    , @UniqueEmail = 1
    , @PasswordFormat = 1
    , @CurrentTimeUtc = @utcTimestamp
    , @UserId = @userId output

GO

DECLARE @userId UNIQUEIDENTIFIER
SET @userId = '635B2CBE-477E-4BA1-93C3-521477316C0F'

DECLARE @utcTimestamp DATETIME = GETUTCDATE()

EXEC dbo.aspnet_Membership_CreateUser
    @ApplicationName = N'Securitas Portal'
    , @UserName = N'test-bm1'
    , @Password = N'Vv20ry7PAwhbvZiXz5LI9R5fU+o = '
    , @PasswordSalt = N'7s4DV9j94WjMZAZMljBoxA =  = '
    , @Email = N'test-bm1@technologytoolbox.com'
    , @PasswordQuestion = NULL
    , @PasswordAnswer = NULL
    , @IsApproved = 1
    , @UniqueEmail = 1
    , @PasswordFormat = 1
    , @CurrentTimeUtc = @utcTimestamp
    , @UserId = @userId output

GO

DECLARE @utcTimestamp DATETIME = GETUTCDATE()

EXEC dbo.aspnet_UsersInRoles_AddUsersToRoles
    @ApplicationName = N'Securitas Portal'
    , @RoleNames = N'Branch Managers'
    , @UserNames = N'test-bm1'
    , @CurrentTimeUtc = @utcTimestamp

GO
EXEC dbo.aspnet_UsersInRoles_GetUsersInRoles
    @ApplicationName = N'Securitas Portal'
    , @RoleName = N'Branch Managers'
GO
```

#### Create users for Securitas clients

| **User Name** | **E-mail**            |
| ------------- | --------------------- |
| test-abc1     | test-abc1@foobar.com  |
| test-lite1    | test-lite1@foobar.com |

#### Create users for Securitas Branch Managers

| **User Name** | **E-mail**                     |
| ------------- | ------------------------------ |
| test-bm1      | test-bm1@technologytoolbox.com |

```PowerShell
cls
```

#### # Associate client users to Branch Managers

```PowerShell
$sqlcmd = @"
USE SecuritasPortal
GO

INSERT INTO Customer.BranchManagerAssociatedUsers
VALUES ('TECHTOOLBOX\jjameson', 'test-abc1')

INSERT INTO Customer.BranchManagerAssociatedUsers
VALUES ('TECHTOOLBOX\jjameson', 'test-lite1')

INSERT INTO Customer.BranchManagerAssociatedUsers
VALUES ('TECHTOOLBOX\smasters', 'test-abc1')

INSERT INTO Customer.BranchManagerAssociatedUsers
VALUES ('TECHTOOLBOX\smasters', 'test-lite1')
"@

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

### # Configure trusted root authorities in SharePoint

```PowerShell
& '.\Configure Trusted Root Authorities.ps1' -Verbose
```

### Configure application settings (e.g. Web service URLs)

### Configure the SSO credentials for a user

exec dbo.aspnet_Membership_GetUserByName @ApplicationName=N'Securitas Portal',@UserName=N'test-abc1',@UpdateLastActivity=0,@CurrentTimeUtc='2016-05-24 14:57:22.603'\
go\
exec sp_reset_connection\
go\
exec dbo.aspnet_Profile_GetProperties @ApplicationName=N'Securitas Portal',@UserName=N'test-abc1',@CurrentTimeUtc='2016-05-24 14:57:22.603'\
go\
exec sp_reset_connection\
go\
exec dbo.aspnet_Profile_SetProperties @ApplicationName=N'Securitas Portal',@UserName=N'test-abc1',@PropertyNames=N'SsoCredentials:B:0:515:',@PropertyValuesString=N'',@PropertyValuesBinary=0x0001000000FFFFFFFF01000000000000000C020000004953797374656D2C2056657273696F6E3D342E302E302E302C2043756C747572653D6E65757472616C2C205075626C69634B6579546F6B656E3D6237376135633536313933346530383905010000002F53797374656D2E436F6C6C656374696F6E732E5370656369616C697A65642E537472696E6744696374696F6E6172790100000008636F6E74656E7473031C53797374656D2E436F6C6C656374696F6E732E486173687461626C6502000000090300000004030000001C53797374656D2E436F6C6C656374696F6E732E486173687461626C65070000000A4C6F6164466163746F720756657273696F6E08436F6D70617265721048617368436F646550726F7669646572084861736853697A65044B6579730656616C756573000003030005050B081C53797374656D2E436F6C6C656374696F6E732E49436F6D70617265722453797374656D2E436F6C6C656374696F6E732E4948617368436F646550726F766964657208EC51383F010000000A0A0300000009040000000905000000100400000001000000060600000007636170737572651005000000010000000607000000484C7051626438336F3845507871634E7679506F2B444D706F6144655652646859697A366D5379706D7854495979746175766C4754494B393068784A634753754E634238687A413D3D0B,@IsUserAnonymous=0,@CurrentTimeUtc='2016-05-24 14:57:22.617'\
go\
exec sp_reset_connection\
go\
exec dbo.aspnet_Membership_GetUserByName @ApplicationName=N'Securitas Portal',@UserName=N'test-abc1',@UpdateLastActivity=0,@CurrentTimeUtc='2016-05-24 14:57:22.633'\
go\
exec sp_reset_connection\
go\
exec dbo.aspnet_Profile_GetProperties @ApplicationName=N'Securitas Portal',@UserName=N'test-abc1',@CurrentTimeUtc='2016-05-24 14:57:22.633'\
go\
exec sp_reset_connection\
go\
exec dbo.aspnet_Profile_SetProperties @ApplicationName=N'Securitas Portal',@UserName=N'test-abc1',@PropertyNames=N'SsoCredentials:B:0:606:',@PropertyValuesString=N'',@PropertyValuesBinary=0x0001000000FFFFFFFF01000000000000000C020000004953797374656D2C2056657273696F6E3D342E302E302E302C2043756C747572653D6E65757472616C2C205075626C69634B6579546F6B656E3D6237376135633536313933346530383905010000002F53797374656D2E436F6C6C656374696F6E732E5370656369616C697A65642E537472696E6744696374696F6E6172790100000008636F6E74656E7473031C53797374656D2E436F6C6C656374696F6E732E486173687461626C6502000000090300000004030000001C53797374656D2E436F6C6C656374696F6E732E486173687461626C65070000000A4C6F6164466163746F720756657273696F6E08436F6D70617265721048617368436F646550726F7669646572084861736853697A65044B6579730656616C756573000003030005050B081C53797374656D2E436F6C6C656374696F6E732E49436F6D70617265722453797374656D2E436F6C6C656374696F6E732E4948617368436F646550726F766964657208EC51383F020000000A0A030000000904000000090500000010040000000200000006060000000763617073757265060700000007697665726966791005000000020000000608000000484C7051626438336F3845507871634E7679506F2B444D706F6144655652646859697A366D5379706D7854495979746175766C4754494B393068784A634753754E634238687A413D3D0609000000484C7051626438336F3845507871634E7679506F2B444D706F6144644C4446397864675933377363505175465635527157374A38773464436A76543578636F2B366951565752673D3D0B,@IsUserAnonymous=0,@CurrentTimeUtc='2016-05-24 14:57:22.633'\
go\
exec sp_reset_connection\
go\
exec dbo.aspnet_Membership_GetUserByName @ApplicationName=N'Securitas Portal',@UserName=N'test-abc1',@UpdateLastActivity=0,@CurrentTimeUtc='2016-05-24 14:57:22.633'\
go\
exec sp_reset_connection\
go\
exec dbo.aspnet_Profile_GetProperties @ApplicationName=N'Securitas Portal',@UserName=N'test-abc1',@CurrentTimeUtc='2016-05-24 14:57:22.633'\
go\
exec sp_reset_connection\
go\
exec dbo.aspnet_Profile_SetProperties @ApplicationName=N'Securitas Portal',@UserName=N'test-abc1',@PropertyNames=N'SsoCredentials:B:0:740:',@PropertyValuesString=N'',@PropertyValuesBinary=0x0001000000FFFFFFFF01000000000000000C020000004953797374656D2C2056657273696F6E3D342E302E302E302C2043756C747572653D6E65757472616C2C205075626C69634B6579546F6B656E3D6237376135633536313933346530383905010000002F53797374656D2E436F6C6C656374696F6E732E5370656369616C697A65642E537472696E6744696374696F6E6172790100000008636F6E74656E7473031C53797374656D2E436F6C6C656374696F6E732E486173687461626C6502000000090300000004030000001C53797374656D2E436F6C6C656374696F6E732E486173687461626C65070000000A4C6F6164466163746F720756657273696F6E08436F6D70617265721048617368436F646550726F7669646572084861736853697A65044B6579730656616C756573000003030005050B081C53797374656D2E436F6C6C656374696F6E732E49436F6D70617265722453797374656D2E436F6C6C656374696F6E732E4948617368436F646550726F766964657208EC51383F040000000A0A070000000904000000090500000010040000000300000006060000000A706174726F6C6C69766506070000000769766572696679060800000007636170737572651005000000030000000609000000704C7051626438336F3845507871634E7679506F2B444D706F6144635731693155346D326C39333733482B624962336C6D5543545849786D4C3854616144752B71654A6F2F35627666414F526836544D6B564555415874376B5475696E7850523335514154734432424133777039655268060A000000484C7051626438336F3845507871634E7679506F2B444D706F6144644C4446397864675933377363505175465635527157374A38773464436A76543578636F2B366951565752673D3D060B000000484C7051626438336F3845507871634E7679506F2B444D706F6144655652646859697A366D5379706D7854495979746175766C4754494B393068784A634753754E634238687A413D3D0B,@IsUserAnonymous=0,@CurrentTimeUtc='2016-05-24 14:57:22.633'\
go\
exec sp_reset_connection\
go\
exec dbo.aspnet_Membership_GetUserByName @ApplicationName=N'Securitas Portal',@UserName=N'test-abc1',@UpdateLastActivity=0,@CurrentTimeUtc='2016-05-24 14:57:22.633'\
go\
exec sp_reset_connection\
go\
exec dbo.aspnet_Profile_GetProperties @ApplicationName=N'Securitas Portal',@UserName=N'test-abc1',@CurrentTimeUtc='2016-05-24 14:57:22.633'\
go\
exec sp_reset_connection\
go\
exec dbo.aspnet_Profile_SetProperties @ApplicationName=N'Securitas Portal',@UserName=N'test-abc1',@PropertyNames=N'SsoCredentials:B:0:872:',@PropertyValuesString=N'',@PropertyValuesBinary=0x0001000000FFFFFFFF01000000000000000C020000004953797374656D2C2056657273696F6E3D342E302E302E302C2043756C747572653D6E65757472616C2C205075626C69634B6579546F6B656E3D6237376135633536313933346530383905010000002F53797374656D2E436F6C6C656374696F6E732E5370656369616C697A65642E537472696E6744696374696F6E6172790100000008636F6E74656E7473031C53797374656D2E436F6C6C656374696F6E732E486173687461626C6502000000090300000004030000001C53797374656D2E436F6C6C656374696F6E732E486173687461626C65070000000A4C6F6164466163746F720756657273696F6E08436F6D70617265721048617368436F646550726F7669646572084861736853697A65044B6579730656616C756573000003030005050B081C53797374656D2E436F6C6C656374696F6E732E49436F6D70617265722453797374656D2E436F6C6C656374696F6E732E4948617368436F646550726F766964657208EC51383F050000000A0A0700000009040000000905000000100400000004000000060600000008747261636B74696B0607000000076976657269667906080000000A706174726F6C6C69766506090000000763617073757265100500000004000000060A000000704C7051626438336F3845507871634E7679506F2B444D706F614465515247777A74713050516861666E4958394249585A75306C6445672F63717039466449487A6A556E4848716D6641315647786530305A6D3941504C314979616633344E6345724D4F48493232784474303850775974060B000000484C7051626438336F3845507871634E7679506F2B444D706F6144644C4446397864675933377363505175465635527157374A38773464436A76543578636F2B366951565752673D3D060C000000704C7051626438336F3845507871634E7679506F2B444D706F6144635731693155346D326C39333733482B624962336C6D5543545849786D4C3854616144752B71654A6F2F35627666414F526836544D6B564555415874376B5475696E7850523335514154734432424133777039655268060D000000484C7051626438336F3845507871634E7679506F2B444D706F6144655652646859697A366D5379706D7854495979746175766C4754494B393068784A634753754E634238687A413D3D0B,@IsUserAnonymous=0,@CurrentTimeUtc='2016-05-24 14:57:22.633'\
go\
exec sp_reset_connection\
go\
exec dbo.aspnet_Profile_GetProperties @ApplicationName=N'Securitas Portal',@UserName=N'test-abc1',@CurrentTimeUtc='2016-05-24 14:57:22.633'\
go\
exec sp_reset_connection\
go\
exec dbo.aspnet_Profile_SetProperties @ApplicationName=N'Securitas\
Portal',@UserName=N'test-abc1',@PropertyNames=N'FullName:S:0:0:SsoCredentials:B:0:872:SuppressedAnnouncements:B:872:424:',@PropertyValuesString=N'',@PropertyValuesBinary=0x0001000000FFFFFFFF01000000000000000C020000004953797374656D2C2056657273696F6E3D342E302E302E302C2043756C747572653D6E65757472616C2C205075626C69634B6579546F6B656E3D6237376135633536313933346530383905010000002F53797374656D2E436F6C6C656374696F6E732E5370656369616C697A65642E537472696E6744696374696F6E6172790100000008636F6E74656E7473031C53797374656D2E436F6C6C656374696F6E732E486173687461626C6502000000090300000004030000001C53797374656D2E436F6C6C656374696F6E732E486173687461626C65070000000A4C6F6164466163746F720756657273696F6E08436F6D70617265721048617368436F646550726F7669646572084861736853697A65044B6579730656616C756573000003030005050B081C53797374656D2E436F6C6C656374696F6E732E49436F6D70617265722453797374656D2E436F6C6C656374696F6E732E4948617368436F646550726F766964657208EC51383F050000000A0A0700000009040000000905000000100400000004000000060600000008747261636B74696B0607000000076976657269667906080000000A706174726F6C6C69766506090000000763617073757265100500000004000000060A000000704C7051626438336F3845507871634E7679506F2B444D706F614465515247777A74713050516861666E4958394249585A75306C6445672F63717039466449487A6A556E4848716D6641315647786530305A6D3941504C314979616633344E6345724D4F48493232784474303850775974060B000000484C7051626438336F3845507871634E7679506F2B444D706F6144644C4446397864675933377363505175465635527157374A38773464436A76543578636F2B366951565752673D3D060C000000704C7051626438336F3845507871634E7679506F2B444D706F6144635731693155346D326C39333733482B624962336C6D5543545849786D4C3854616144752B71654A6F2F35627666414F526836544D6B564555415874376B5475696E7850523335514154734432424133777039655268060D000000484C7051626438336F3845507871634E7679506F2B444D706F6144655652646859697A366D5379706D7854495979746175766C4754494B393068784A634753754E634238687A413D3D0B0001000000FFFFFFFF01000000000000000C020000004953797374656D2C2056657273696F6E3D342E302E302E302C2043756C747572653D6E65757472616C2C205075626C69634B6579546F6B656E3D6237376135633536313933346530383905010000002F53797374656D2E436F6C6C656374696F6E732E5370656369616C697A65642E537472696E6744696374696F6E6172790100000008636F6E74656E7473031C53797374656D2E436F6C6C656374696F6E732E486173687461626C6502000000090300000004030000001C53797374656D2E436F6C6C656374696F6E732E486173687461626C65070000000A4C6F6164466163746F720756657273696F6E08436F6D70617265721048617368436F646550726F7669646572084861736853697A65044B6579730656616C756573000003030005050B081C53797374656D2E436F6C6C656374696F6E732E49436F6D70617265722453797374656D2E436F6C6C656374696F6E732E4948617368436F646550726F766964657208EC51383F000000000A0A03000000090400000009050000001004000000000000001005000000000000000B,@IsUserAnonymous=0,@CurrentTimeUtc='2016-05-24 14:57:22.633'\
go\
exec sp_reset_connection\
go

Browse to the site and login as **test-abc1**.

Edit profile to set SSO credentials:

[http://client-local.securitasinc.com/_layouts/Securitas/EditProfile.aspx](http://client-local.securitasinc.com/_layouts/Securitas/EditProfile.aspx)

| **System** | **User Name**      |
| ---------- | ------------------ |
| CapSure    | jane               |
| Iverify    | scabc              |
| PatrolLIVE | robert@example.com |
| TrackTik   | jane.doe@abc.com   |

```PowerShell
cls
```

### # Configure C&C landing site

#### # Grant Branch Managers permissions to the C&C landing site

```PowerShell
Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

$site = Get-SPSite "http://client-local.securitasinc.com/sites/cc"
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

(skipped -- since **/sites/cc/Search** subsite does not exist in new SharePoint 2013 environments)

**TODO:** Delete **Search** subsite in environments upgraded from SharePoint 2010

#### Configure the search settings for the C&C landing site

[http://client-local.securitasinc.com/sites/cc](http://client-local.securitasinc.com/sites/cc)

### Configure Google Analytics on the SecuritasConnect Web application

Tracking ID: **UA-25949832-4**

```PowerShell
cls
```

## # Create and configure C&C site collections

### # Create site collection for a Securitas client

```PowerShell
& '.\Create Client Site Collection.ps1' "ABC Company"
```

{Begin skipped sections}

**TODO:** Resolve issues with custom site templates

### Apply the "Securitas Client Site" template to the top-level site

### Modify the site title, description, and logo

### Update the client site home page

### Create a blog site (optional)

### Create a wiki site (optional)

{End skipped sections}

## Configure name resolution for Office Web Apps

---

**EXT-WAC02A**

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    -IPAddress 192.168.10.217 `
    -Hostnames EXT-FOOBAR3, client-local.securitasinc.com, `
        cloud-local.securitasinc.com
```

---

```PowerShell
cls
```

## # Configure Web application policy for SharePoint administrators group

```PowerShell
Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

$groupName = "EXTRANET\SharePoint Admins (DEV)"

$principal = New-SPClaimsPrincipal -Identity $groupName `
    -IdentityType WindowsSecurityGroupName

$claim = "c:0+.w|" + $principal.Value.ToLower()

$webApp = Get-SPWebApplication http://client-local.securitasinc.com

$policyRole = $webApp.PolicyRoles.GetSpecialRole(
    [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl)

$policy = $webApp.Policies.Add($claim, $groupName)
$policy.PolicyRoleBindings.Add($policyRole)

$webApp.Update()
```

## Remove extraneous VM snapshots

---

**FOOBAR8**

### # Delete VM checkpoint - "6.5 Copy SecuritasConnect build to SharePoint server"

```PowerShell
$vmHost = "STORM"
$vmName = "EXT-FOOBAR3"

Stop-VM -ComputerName $vmHost -Name $vmName

Remove-VMSnapshot -VMName $vmName -Name "6.5 Copy SecuritasConnect build to SharePoint server"

while (Get-VM $vmName | Where Status -eq "Merging disks") {
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 5
}

Write-Host
```

### # Delete VM checkpoint - "15.0.4727.1000 - SharePoint 2013 June 2015 CU"

```PowerShell
Remove-VMSnapshot -VMName $vmName -Name "15.0.4727.1000 - SharePoint 2013 June 2015 CU"

while (Get-VM $vmName | Where Status -eq "Merging disks") {
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 5
}

Write-Host

Start-VM -ComputerName $vmHost -Name $vmName
```

---

```PowerShell
cls
```

## # Create and configure the Cloud Portal Web application

### # Set environment variables

```PowerShell
[Environment]::SetEnvironmentVariable(
  "SECURITAS_CLOUD_PORTAL_URL",
  "http://cloud-local.securitasinc.com",
  "Machine")
```

> **Important**
>
> Restart PowerShell for environment variable to take effect.

### Copy Cloud Portal build to SharePoint server

---

**Developer Command Prompt for VS2013 - Run as administrator**

```Console
tf get C:\NotBackedUp\Securitas\CloudPortal\Main /recursive /force
```

---

### # Create the Web application

```PowerShell
cd C:\NotBackedUp\Securitas\CloudPortal\Main\Code\DeploymentFiles\Scripts

& '.\Create Web Application.ps1' -Verbose
```

> **Note**
>
> When prompted for the service account, specify **EXTRANET\\s-web-cloud-dev**.\
> Expect the previous operation to complete in approximately 2 minutes.

### Install third-party SharePoint solutions

```PowerShell
cls
```

### # Restore content database or create initial site collections

#### # Create initial site collections

```PowerShell
& '.\Create Site Collections.ps1' -Verbose
```

> **Note**
>
> Expect the previous operation to complete in approximately 1 minute.

```PowerShell
cls
```

### # Configure object cache user accounts

```PowerShell
& '.\Configure Object Cache User Accounts.ps1' -Verbose

iisreset
```

### # Configure the People Picker to support searches across one-way trust

#### # Specify the credentials for accessing the trusted forest

```PowerShell
$cred1 = Get-Credential "EXTRANET\s-web-cloud-dev"

$cred2 = Get-Credential "TECHTOOLBOX\svc-sp-ups"

$cred3 = Get-Credential "FABRIKAM\s-sp-ups"

$peoplePickerCredentials = $cred1, $cred2, $cred3

& '.\Configure People Picker Forests.ps1' `
    -ServiceCredentials $peoplePickerCredentials `
    -Confirm:$false `
    -Verbose
```

### DEV - Map Web application to loopback address in Hosts file

(skipped)

### Allow specific host names mapped to 127.0.0.1

(skipped)

### Configure SSL on the Internet zone

(skipped)

```PowerShell
cls
```

### # Enable anonymous access to the site

```PowerShell
& '.\Enable Anonymous Access.ps1'
```

### Enable disk-based caching for the Web application

(skipped)

### Configure SharePoint groups

(skipped)

## Deploy the Cloud Portal solution

---

**Developer Command Prompt for VS2013 - Run as administrator**

### REM DEV - Build Visual Studio solution and package SharePoint projects

```Console
cd C:\NotBackedUp\Securitas\CloudPortal\Main\Code
msbuild Securitas.CloudPortal.sln /p:IsPackaging=true
```

---

```PowerShell
cls
```

### # Configure permissions for the SecuritasPortal database

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

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

### # Configure logging

```PowerShell
cd C:\NotBackedUp\Securitas\CloudPortal\Main\Code\DeploymentFiles\Scripts

& '.\Add Event Log Sources.ps1' -Verbose
```

### Upgrade main site collection

(skipped)

```PowerShell
cls
```

### # Install Cloud Portal solutions and activate the features

```PowerShell
& '.\Add Solutions.ps1' -Verbose

& '.\Deploy Solutions.ps1' -Verbose

& '.\Activate Features.ps1' -Verbose
```

### Create and configure the custom sign-in page

#### Create the custom sign-in page

#### Configure the custom sign-in page on the Web application

### Configure search settings for the Cloud Portal

#### Hide the Search navigation item on the top-level site

#### Configure the search settings for the top-level site

### Configure redirect for single-site users

#### Create the "User Sites" List

#### Add items to the "User Sites" list

#### Add redirect Web Part to Cloud Portal home page

### Create and configure "Online Provisioning" site

(skipped)

### Configure Google Analytics on the Cloud Portal Web application

Tracking ID: **UA-25949832-5**

```PowerShell
cls
```

## # Create and configure C&C site collections

### # Create "Collaboration & Community" site collection

```PowerShell
& '.\Create Client Site Collection.ps1' "Fabrikam Shipping"
```

### Apply the "Securitas Client Site" template to the top-level site

[http://cloud-local.securitasinc.com/sites/Fabrikam-Shipping](http://cloud-local.securitasinc.com/sites/Fabrikam-Shipping)

### Modify the site title, description, and logo

(skipped)

### Update the C&C site home page

### Create a team collaboration site (optional)

### Create a blog site (optional)

### Create a wiki site (optional)

**TODO:** Fix bug where master page is not set to SecuritasCloud.master on Wiki site

## Install Employee Portal

```PowerShell
cls
```

## # Extend SecuritasConnect and Cloud Portal web applications

### # Extend web applications to Intranet zone

```PowerShell
$ErrorActionPreference = "Stop"

Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

Function ExtendWebAppToIntranetZone(
    [string] $DefaultUrl,
    [string] $IntranetUrl)
{
    $webApp = Get-SPWebApplication -Identity $DefaultUrl -Debug:$false

    Write-Host ("Extending Web application ($DefaultUrl) to Intranet zone" `
        + " ($IntranetUrl)...")

    $hostHeader = $IntranetUrl.Substring("http://".Length)

    $webAppName = "SharePoint - " + $hostHeader + "80"

    $windowsAuthProvider = New-SPAuthenticationProvider -Debug:$false

    $webApp | New-SPWebApplicationExtension `
        -Name $webAppName `
        -Zone Intranet `
        -AuthenticationProvider $windowsAuthProvider `
        -HostHeader $hostHeader `
        -Port 80
}

ExtendWebAppToIntranetZone `
    -DefaultUrl "http://client-local.securitasinc.com" `
    -IntranetUrl "http://client2-local.securitasinc.com"

ExtendWebAppToIntranetZone `
    -DefaultUrl "http://cloud-local.securitasinc.com" `
    -IntranetUrl "http://cloud2-local.securitasinc.com"
```

### Add SecuritasPortal connection string to Cloud Portal configuration file

(skipped)

**TODO:** Remove this section from the installation guide (since the bug has been fixed)

### Enable disk-based caching for the "intranet" websites

(skipped)

```PowerShell
cls
```

### # Map intranet URLs to loopback address in Hosts file

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    127.0.0.1 client2-local.securitasinc.com, cloud2-local.securitasinc.com
```

### # Allow specific host names mapped to 127.0.0.1

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-BackConnectionHostnames.ps1 `
    client2-local.securitasinc.com, cloud2-local.securitasinc.com
```

## Upgrade SecuritasConnect to "v3.0 Sprint-22" release

(skipped)

**TODO:** Remove this section from the installation guide

## Install Web Deploy 3.6

### Download Web Platform Installer

### Install Web Deploy

```PowerShell
cls
```

## # Install .NET Framework 4.5

### # Download .NET Framework 4.5.2 installer

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

(skipped -- since a restart was required when installing .NET Framework 4.5.2 and after installing updates)

### Ensure ASP.NET v4.0 ISAPI filters are enabled

(skipped -- since the ISAPI filters were already enabled)

## Install Employee Portal

### Copy Employee Portal build to SharePoint server

---

**Developer Command Prompt for VS2013 - Run as administrator**

```Console
tf get C:\NotBackedUp\Securitas\EmployeePortal\Main /recursive /force
```

---

```PowerShell
cls
```

### # Add the Employee Portal URL to the "Local intranet" zone

```PowerShell
[string] $registryKey = ("HKCU:\Software\Microsoft\Windows" `
    + "\CurrentVersion\Internet Settings\ZoneMap\EscDomains" `
    + "\employee-local.securitasinc.com")

If ((Test-Path $registryKey) -eq $false)
{
    New-Item $registryKey | Out-Null
}

Set-ItemProperty -Path $registryKey -Name http -Value 1
```

### # Create Employee Portal SharePoint site

```PowerShell
cd 'C:\NotBackedUp\Securitas\EmployeePortal\Main\Code\Deployment Files\Scripts'

& '.\Configure Employee Portal SharePoint Site.ps1' `
    -SupportedDomains TECHTOOLBOX, FABRIKAM `
    -Confirm:$false `
    -Verbose
```

```PowerShell
cls
```

### # Create Employee Portal website

#### # Create Employee Portal website on SharePoint Central Administration server

```PowerShell
& '.\Configure Employee Portal Website.ps1' `
    -SiteName employee-local.securitasinc.com `
    -Confirm:$false `
    -Verbose
```

#### Configure SSL bindings on Employee Portal website

(skipped)

#### Create Employee Portal website on other web servers in the farm

(skipped)

```PowerShell
cls
```

### # Deploy Employee Portal website

#### # Deploy Employee Portal website on SharePoint Central Administration server

```PowerShell
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
    value="employee-local.securitasinc.com" />
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

#### Configure application settings and web service URLs

#### Deploy Employee Portal website content to other web servers in the farm

### Configure database logins and permissions for Employee Portal

### Grant PNKCAN and PNKUS users permissions on Cloud Portal site

### Replace absolute URLs in "User Sites" list

### DEV - Install Visual Studio 2015 with Update 1

### Install additional service packs and updates

**TODO:**

```PowerShell
cls
```

## # Start full crawl

```PowerShell
Get-SPEnterpriseSearchServiceApplication |
    Get-SPEnterpriseSearchCrawlContentSource |
    % { $_.StartFullCrawl() }
```

```PowerShell
cls
```

## # Suspend Search Service Application

```PowerShell
Get-SPEnterpriseSearchServiceApplication "Search Service Application" |
    Suspend-SPEnterpriseSearchServiceApplication
```

```PowerShell
cls
```

### # Delete C:\\Windows\\SoftwareDistribution folder (2.79 GB)

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse

Restart-Computer
```

### Check for updates using Windows Update (after removing patches folder)

- **Most recent check for updates: Never -> Most recent check for updates: Today at 7:08 PM**
- C:\\Windows\\SoftwareDistribution folder is now 55 MB

```PowerShell
cls
```

### # Clean up the WinSxS folder

```PowerShell
Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase
```

```PowerShell
cls
```

## # Rebuild SecuritasConnect web application

```PowerShell
cd C:\NotBackedUp\Securitas\ClientPortal\Main\Code\DeploymentFiles\Scripts

$cred1 = Get-Credential "EXTRANET\s-web-client-dev"

$cred2 = Get-Credential "TECHTOOLBOX\svc-sp-ups"

& '.\Rebuild Web Application.ps1' $cred1, $cred2 -Confirm:$false -Verbose
```

```PowerShell
cls
```

### # Activate the "Securitas - Application Settings" feature

```PowerShell
Start-Process `
    "http://client-local.securitasinc.com/_layouts/15/ManageFeatures.aspx"
```

### # Grant Branch Managers permissions to the C&C landing site

```PowerShell
Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

$site = Get-SPSite "http://client-local.securitasinc.com/sites/cc"
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

```PowerShell
cls
```

## # Remove object cache user accounts

```PowerShell
$webApp = Get-SPWebApplication http://client-local.securitasinc.com

$webApp.Properties.Remove("portalsuperuseraccount")
$webApp.Properties.Remove("portalsuperreaderaccount")
$webApp.Update()

iisreset
```

## # Enter a product key and activate Windows

```PowerShell
slmgr /ipk {product key}
```

**Note:** When notified that the product key was set successfully, click **OK**.

```Console
slmgr /ato
```

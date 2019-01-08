# TT-TFS02 - TFS 2018 App Tier

Thursday, March 22, 2018
8:08 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy Team Foundation Server 2018

### Deploy and configure the server infrastructure

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "TT-TFS02"
$vmPath = "E:\NotBackedUp\VMs\$vmName"
$vhdPath = "$vmPath\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 4GB `
    -SwitchName "Embedded Team Switch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 2

Start-VM -ComputerName $vmHost -Name $vmName
```

---

#### Install custom Windows Server 2016 image

- On the **Task Sequence** step, select **Windows Server 2016** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **TT-TFS02**.
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

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Move computer to different OU

```PowerShell
$vmName = "TT-TFS02"

$targetPath = "OU=Team Foundation Servers,OU=Servers" `
    + ",OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com"

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

#### # Configure Windows Update

##### # Add machine to security group for Windows Update schedule

```PowerShell
Add-ADGroupMember -Identity "Windows Update - Slot 3" -Members ($vmName + '$')
```

---

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

robocopy $source $destination /E /XD "Microsoft SDKs"
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

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Set first boot device to hard drive

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "TT-TFS02"

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

### # Configure networking

```PowerShell
$interfaceAlias = "Management"
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

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

##### # Configure static IP address using VMM

```PowerShell
$vmName = "TT-TFS02"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Management VM Network"
$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"
$ipPool = Get-SCStaticIPAddressPool -Name "Management Address Pool"

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

### # Add TFS setup account to local Administrators group

```PowerShell
$domain = "TECHTOOLBOX"
$username = "setup-tfs"

([ADSI]"WinNT://./Administrators,group").Add(
    "WinNT://$domain/$username,user")
```

### Configure storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 32 GB       | 4K                   | OSDisk       |
| 1    | D:           | 60 GB       | 4K                   | Data01       |

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Configure storage for the SQL Server

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "TT-TFS02"
$vmPath = "E:\NotBackedUp\VMs\$vmName"
```

##### # Add "Data01" VHD

```PowerShell
$vhdPath = $vmPath + "\Virtual Hard Disks\$vmName" + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 60GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path $vhdPath `
    -ControllerType SCSI
```

---

#### Login as TECHTOOLBOX\\setup-tfs

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

### Add virtual machine to Hyper-V protection group in DPM

```PowerShell
cls
```

### # Configure monitoring

#### # Install Operations Manager agent

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\System Center 2016\SCOM\Agent\AMD64" `
    + "\MOMAgent.msi"

$installerArguments = "MANAGEMENT_GROUP=HQ" `
    + " MANAGEMENT_SERVER_DNS=TT-SCOM03" `
    + " ACTIONS_USE_COMPUTER_ACCOUNT=1"

Start-Process `
    -FilePath msiexec.exe `
    -ArgumentList "/i `"$installerPath`" $installerArguments" `
    -Wait
```

#### Approve manual agent install in Operations Manager

## Copy data from TFS 2015 environment

### Copy builds from TFS 2015 to TFS 2018

(skipped)

### Back up SQL Server Reporting Services encryption key

### Back up TFS 2015 databases

---

**CYCLOPS**

```PowerShell
cls
```

#### # Shutdown the TFS 2015 App Tier

```PowerShell
& "C:\Program Files\Microsoft Team Foundation Server 14.0\Tools\TfsServiceControl.exe" `
    quiesce
```

---

#### Back up Reporting Services and TFS 2015 OLTP databases

---

**SQL Server Management Studio - Database Engine - HAVOK**

```Console
DECLARE @backupDirectory VARCHAR(255)

EXEC master.dbo.xp_instance_regread
    N'HKEY_LOCAL_MACHINE'
    , N'Software\Microsoft\MSSQLServer\MSSQLServer'
    , N'BackupDirectory'
    , @backupDirectory OUTPUT

DECLARE @backupFilePath VARCHAR(255)
DECLARE @databaseName VARCHAR(50)
DECLARE @backupName VARCHAR(100)

SET @databaseName = 'ReportServer_Tfs'
SET @backupFilePath = @backupDirectory + '\Full\' + @databaseName + '.bak'
SET @backupName = @databaseName + '-Full Database Backup'

BACKUP DATABASE @databaseName
    TO DISK = @backupFilePath
    WITH COMPRESSION
        , COPY_ONLY
        , INIT
        , NAME = @backupName
        , STATS = 10

SET @databaseName = 'ReportServer_TfsTempDB'
SET @backupFilePath = @backupDirectory + '\Full\' + @databaseName + '.bak'
SET @backupName = @databaseName + '-Full Database Backup'

BACKUP DATABASE @databaseName
    TO DISK = @backupFilePath
    WITH COMPRESSION
        , COPY_ONLY
        , INIT
        , NAME = @backupName
        , STATS = 10

SET @databaseName = 'Tfs_Configuration'
SET @backupFilePath = @backupDirectory + '\Full\' + @databaseName + '.bak'
SET @backupName = @databaseName + '-Full Database Backup'

BACKUP DATABASE @databaseName
    TO DISK = @backupFilePath
    WITH COMPRESSION
        , COPY_ONLY
        , INIT
        , NAME = @backupName
        , STATS = 10

SET @databaseName = 'Tfs_DefaultCollection'
SET @backupFilePath = @backupDirectory + '\Full\' + @databaseName + '.bak'
SET @backupName = @databaseName + '-Full Database Backup'

BACKUP DATABASE @databaseName
    TO DISK = @backupFilePath
    WITH COMPRESSION
        , COPY_ONLY
        , INIT
        , NAME = @backupName
        , STATS = 10

SET @databaseName = 'Tfs_Warehouse'
SET @backupFilePath = @backupDirectory + '\Full\' + @databaseName + '.bak'
SET @backupName = @databaseName + '-Full Database Backup'

BACKUP DATABASE @databaseName
    TO DISK = @backupFilePath
    WITH COMPRESSION
        , COPY_ONLY
        , INIT
        , NAME = @backupName
        , STATS = 10
```

---

#### Back up TFS 2015 OLAP database

(skipped)

#### Start TFS 2015 App Tier

(skipped)

### Restore databases to TFS 2018 environment

## Install TFS 2018 App Tier, upgrade TFS databases, and configure TFS resources

---

**FOOBAR11 - TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Configure name resolution for TFS 2018 URLs

```PowerShell
Add-DnsServerResourceRecordCName `
    -ZoneName "technologytoolbox.com" `
    -Name "tfs" `
    -HostNameAlias "TT-TFS02.corp.technologytoolbox.com" `
    -ComputerName TT-DC06
```

---

```PowerShell
cls
```

### # Install SSL certificate

#### # Create request for Web Server certificate

```PowerShell
$hostname = "tfs.technologytoolbox.com"

& "C:\NotBackedUp\Public\Toolbox\PowerShell\New-CertificateRequest.ps1" `
    -Subject ("CN=$hostname,OU=IT" `
        + ",O=Technology Toolbox,L=Parker,S=CO,C=US") `
    -SANs $hostname
```

#### # Submit certificate request to Certification Authority

```PowerShell
Start-Process "https://cipher01.corp.technologytoolbox.com"
```

**To submit the certificate request to an enterprise CA:**

1. Start Internet Explorer, and browse to Active Directory Certificate Services site ([https://cipher01.corp.technologytoolbox.com/](https://cipher01.corp.technologytoolbox.com/)).
2. On the **Welcome** page, click **Request a certificate**.
3. On the **Advanced Certificate Request** page, click **Submit a certificate request by using a base-64-encoded CMC or PKCS #10 file, or submit a renewal request by using a base-64-encoded PKCS #7 file.**
4. On the **Submit a Certificate Request or Renewal Request** page, in the **Saved Request** text box, paste the contents of the certificate request generated in the previous procedure.
5. In the **Certificate Template** section, select the appropriate certificate template (**Technology Toolbox Web Server - Exportable**), and then click **Submit**. When prompted to allow the digital certificate operation to be performed, click **Yes**.
6. On the **Certificate Issued** page, click **Download certificate** and save the certificate.

```PowerShell
cls
```

#### # Import certificate into certificate store

```PowerShell
$certFile = "C:\Users\setup-tfs\Downloads\certnew.cer"

CertReq.exe -Accept $certFile

Remove-Item $certFile
```

### Temporarily grant administrator permissions in SQL Server to TFS setup account

---

**SQL Server Management Studio - Database Engine - TT-SQL02**

#### -- Add TFS setup account to sysadmin role in Database Engine instance

```SQL
CREATE LOGIN [TECHTOOLBOX\setup-tfs]
FROM WINDOWS
WITH DEFAULT_DATABASE=master
GO

ALTER SERVER ROLE sysadmin
ADD MEMBER [TECHTOOLBOX\setup-tfs]
```

---

#### Add TFS setup account to server administrator role in Analysis Services instance

```PowerShell
cls
```

### # Install and configure SQL Server Reporting Services

#### # Install SQL Server Reporting Services

```PowerShell
& '\\TT-FS01\Products\Microsoft\SQL Server 2017\SQLServerReportingServices.exe'
```

#### Configure SQL Server Reporting Services (using restored database)

#### Configure TFS administrators in SQL Server Reporting Services

---

**SQL Server Management Studio - Database Engine - TT-SQL02**

#### -- Fix permissions for SQL Server Reporting Services

```SQL
USE master
GO
GRANT EXECUTE ON master.dbo.xp_sqlagent_notify TO RSExecRole
GRANT EXECUTE ON master.dbo.xp_sqlagent_enum_jobs TO RSExecRole
GRANT EXECUTE ON master.dbo.xp_sqlagent_is_starting TO RSExecRole
GO
USE msdb
GO
GRANT EXECUTE ON msdb.dbo.sp_add_category TO RSExecRole
GRANT EXECUTE ON msdb.dbo.sp_add_job TO RSExecRole
GRANT EXECUTE ON msdb.dbo.sp_add_jobschedule TO RSExecRole
GRANT EXECUTE ON msdb.dbo.sp_add_jobserver TO RSExecRole
GRANT EXECUTE ON msdb.dbo.sp_add_jobstep TO RSExecRole
GRANT EXECUTE ON msdb.dbo.sp_delete_job TO RSExecRole
GRANT EXECUTE ON msdb.dbo.sp_help_category TO RSExecRole
GRANT EXECUTE ON msdb.dbo.sp_help_job TO RSExecRole
GRANT EXECUTE ON msdb.dbo.sp_help_jobschedule TO RSExecRole
GRANT EXECUTE ON msdb.dbo.sp_verify_job_identifiers TO RSExecRole
GRANT SELECT ON msdb.dbo.syscategories TO RSExecRole
GRANT SELECT ON msdb.dbo.sysjobs TO RSExecRole
GO
```

---

```PowerShell
cls
```

### # Install TFS 2018 on new App Tier VM

```PowerShell
$imagePath = ("\\TT-FS01\Products\Microsoft\Team Foundation Server 2018" `
    + "\mu_team_foundation_server_2018_x64_dvd_100268668.iso")

$imageDriveLetter = (Mount-DiskImage -ImagePath $ImagePath -PassThru |
    Get-Volume).DriveLetter
```

& ("\$imageDriveLetter" + ":\\Tfs2018.exe")

> **Important**
>
> Wait for the installation to complete and restart the server.

```PowerShell
cls
```

### # Reconfigure TFS to use new instance of SQL Server

```PowerShell
cd "C:\Program Files\Microsoft Team Foundation Server 2018\Tools"

.\TfsConfig.exe RemapDBs `
    /databaseName:"TT-SQL02;Tfs_Configuration" `
    /sqlInstances:TT-SQL02 `
    /analysisInstance:TT-SQL02 `
    /analysisDatabaseName:Tfs_Analysis

Logging sent to file C:\ProgramData\Microsoft\Team Foundation\Server Configuration\Logs\CFG_CFG_AT_0325_123920.log
Microsoft (R) TfsConfig - Team Foundation Server Configuration Tool
Copyright (c) Microsoft Corporation. All rights reserved.

Command: remapDBs
Microsoft (R) TfsConfig - Team Foundation Server Configuration Tool
Copyright (c) Microsoft Corporation. All rights reserved.

The Team Foundation Server configuration could not be reconfigured. The following errors were encountered:

TF400673: Unable to find any compatible SQL Analysis Services database within the specified instance.
'2' hosts have been given updated connection strings.
```

```PowerShell
cls
```

### # Change server identifiers in TFS databases

```PowerShell
cd "C:\Program Files\Microsoft Team Foundation Server 2018\Tools"

.\TfsConfig.exe ChangeServerID `
    /sqlInstance:TT-SQL02 `
    /databaseName:Tfs_Configuration
```

### Upgrade Team Foundation Server

### Configure TFS backups and backup TFS

---

**TT-FS01**

```PowerShell
cls
```

#### # Configure Backup share

##### # Remove "BUILTIN\\Users" permissions

```PowerShell
$backupPath = "F:\Shares\Backups\TFS"

icacls $backupPath /inheritance:d
icacls $backupPath /remove:g "BUILTIN\Users"
```

##### # Grant permissions for configuring TFS backups

```PowerShell
Grant-SmbShareAccess `
    -Name Backups `
    -AccountName "TECHTOOLBOX\setup-tfs" `
    -AccessRight Full `
    -Confirm:$false

icacls $backupPath /grant '"TECHTOOLBOX\setup-tfs":(OI)(CI)(F)'
```

##### # Grant TFS App Tier computer account modify access

```PowerShell
icacls $backupPath /grant 'TT-TFS02$:(OI)(CI)(M)'
```

##### # Grant TFS Data Tier computer account modify access

```PowerShell
icacls $backupPath /grant 'TT-SQL02$:(OI)(CI)(M)'
```

##### # Grant TFS administrators full control

```PowerShell
icacls $backupPath /grant '"TECHTOOLBOX\Team Foundation Server Admins":(OI)(CI)(F)'
```

##### # Remove obsolete share permissions

```PowerShell
Revoke-SmbShareAccess `
    -Name Backups `
    -AccountName "TECHTOOLBOX\jjameson-admin" `
    -Confirm:$false

Revoke-SmbShareAccess `
    -Name Backups `
    -AccountName 'TECHTOOLBOX\CYCLOPS$' `
    -Confirm:$false

Revoke-SmbShareAccess `
    -Name Backups `
    -AccountName 'TECHTOOLBOX\HAVOK$' `
    -Confirm:$false
```

---

#### Configure scheduled backups

#### Backup TFS

### Remove administrator permissions in SQL Server for TFS setup account

---

**SQL Server Management Studio - Database Engine - TT-SQL02**

#### -- Remove TFS setup account from SQL Server sysadmin role

```SQL
ALTER SERVER ROLE sysadmin
DROP MEMBER [TECHTOOLBOX\setup-tfs]
```

---

#### Remove TFS setup account from server administrator role in Analysis Services instance

### Configure TFS resources

#### Configure SMTP settings

```PowerShell
cls
```

### # Configure team projects

#### # Configure test retention policies on existing team projects

```PowerShell
$tfsUrl = 'https://tfs.technologytoolbox.com'
$collectionName = 'DefaultCollection'
$collectionUrl = "$tfsUrl/$collectionName"

# Get the list of team projects
$response = Invoke-RestMethod `
    -Uri "$collectionUrl/_apis/projects" `
    -UseDefaultCredentials

$json = $response.value

$projects = $json | select -ExpandProperty name

# Set the retention policy for automated test runs, results, and attachments
$projects |
    foreach {
        $projectName = $_
        $projectUrl = "$collectionUrl/$projectName"
        $apiUrl = ("$projectUrl/_apis/test/resultretentionsettings" `
            + "?api-version=2.0-preview")

        $response = Invoke-RestMethod `
            -UseDefaultCredentials `
            -Uri $apiUrl

        # Only set the retention policy if it is currently set to
        # "Never delete" (i.e. -1)
        If ($response.automatedResultsRetentionDuration -eq -1)
        {
            Write-Host "Updating project ($projectName)..."

            # Note: When invoking the PATCH method,
            # "manualResultsRetentionDuration" must also be specified (i.e. you
            # cannot specify only "automatedResultsRetentionDuration"). Since we
            # don't want to change the retention policy for manual test runs,
            # results, and attachments, we need to specify the current value in
            # the API call.
            $manualResultsRetentionDuration = `
                $response.manualResultsRetentionDuration

            $patchRequest = "{ " `
                + "automatedResultsRetentionDuration: 60" `
                + ", manualResultsRetentionDuration: " `
                    + $manualResultsRetentionDuration `
                + " }"

            Invoke-RestMethod `
                -Uri $apiUrl `
                -Body $patchRequest `
                -ContentType "application/json" `
                -Method Patch `
                -UseDefaultCredentials |
                Out-Null
        }
    }
```

### Create new team project in TFS

---

**FOOBAR11**

```PowerShell
cls
```

## # Make virtual machine highly available

### # Migrate VM to shared storage

```PowerShell
$vmName = "TT-TFS02"

$vm = Get-SCVirtualMachine -Name $vmName
$vmHost = $vm.VMHost

Move-SCVirtualMachine `
    -VM $vm `
    -VMHost $vmHost `
    -HighlyAvailable $true `
    -Path "C:\ClusterStorage\iscsi01-Gold-02" `
    -UseDiffDiskOptimization
```

### # Allow migration to host with different processor version

```PowerShell
Stop-SCVirtualMachine -VM $vmName

Set-SCVirtualMachine -VM $vmName -CPULimitForMigration $true

Start-SCVirtualMachine -VM $vmName
```

---

## Issue - Error installing Windows Server 2016 CU using Windows Update

There were some problems installing updates, but we'll try again later. If you keep seeing this and want to search the web or contact support for information, this may help: (0x800705b4)

### Solution

```PowerShell
cls
```

#### # Shutdown TFS services

```PowerShell
& "C:\Program Files\Microsoft Team Foundation Server 2018\Tools\TfsServiceControl.exe" `
    quiesce

Stop-Service elasticsearch-service-x64
```

#### Install CU

#### Restart computer

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Move VM to new Production VM network

```PowerShell
$vmName = "TT-TFS02"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Production VM Network"
$ipPool = Get-SCStaticIPAddressPool -Name "Production-15 Address Pool"

Stop-SCVirtualMachine $vmName

$ipAddress = Grant-SCIPAddress `
    -GrantToObjectType VirtualNetworkAdapter `
    -GrantToObjectID $networkAdapter.ID `
    -StaticIPAddressPool $ipPool `
    -Description $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -IPv4AddressType Static `
    -IPv4Addresses $ipAddress.Address

Start-SCVirtualMachine $vmName
```

---

## Issue - Not enough free space to install patches using Windows Update

4 GB of free space, but unable to install **2018-08 Cumulative Update for Windows Server 2016 for x64-based Systems (KB4343887)**.

### Expand C:

---

**FOOBAR16**

```PowerShell
cls
```

#### # Increase size of VHD

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "TT-TFS02"

Stop-VM -ComputerName $vmHost -Name $vmName

Resize-VHD `
    -ComputerName $vmHost `
    -Path ("C:\ClusterStorage\iscsi02-Silver-02\$vmName\" + $vmName + ".vhdx") `
    -SizeBytes 34GB

Start-VM -ComputerName $vmHost -Name $vmName
```

---

#### Delete recovery partition using Disk Management

```PowerShell
cls
```

#### # Extend partition

```PowerShell
$driveLetter = "C"

$partition = Get-Partition -DriveLetter $driveLetter |
    where { $_.DiskNumber -ne $null }

$size = (Get-PartitionSupportedSize `
    -DiskNumber $partition.DiskNumber `
    -PartitionNumber $partition.PartitionNumber)

Resize-Partition `
    -DiskNumber $partition.DiskNumber `
    -PartitionNumber $partition.PartitionNumber `
    -Size $size.SizeMax
```

6 GB of free space, but _still_ unable to install **2018-08 Cumulative Update for Windows Server 2016 for x64-based Systems (KB4343887)**.

### Expand C: (again)

---

**FOOBAR16**

```PowerShell
cls
```

#### # Increase size of VHD

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "TT-TFS02"

Stop-VM -ComputerName $vmHost -Name $vmName

Resize-VHD `
    -ComputerName $vmHost `
    -Path ("C:\ClusterStorage\iscsi02-Silver-02\$vmName\" + $vmName + ".vhdx") `
    -SizeBytes 36GB

Start-VM -ComputerName $vmHost -Name $vmName
```

---

```PowerShell
cls
```

#### # Extend partition

```PowerShell
$driveLetter = "C"

$partition = Get-Partition -DriveLetter $driveLetter |
    where { $_.DiskNumber -ne $null }

$size = (Get-PartitionSupportedSize `
    -DiskNumber $partition.DiskNumber `
    -PartitionNumber $partition.PartitionNumber)

Resize-Partition `
    -DiskNumber $partition.DiskNumber `
    -PartitionNumber $partition.PartitionNumber `
    -Size $size.SizeMax
```

## Issue - Not enough free space to install patches using Windows Update

~4 GB of free space, but unable to install **2018-10 Cumulative Update for Windows Server 2016 for x64-based Systems (KB4462917)**.

### Expand C:

---

**FOOBAR16**

```PowerShell
cls
```

#### # Increase size of VHD

```PowerShell
$vmHost = "TT-HV05B"
$vmName = "TT-TFS02"

Stop-VM -ComputerName $vmHost -Name $vmName

Resize-VHD `
    -ComputerName $vmHost `
    -Path ("C:\ClusterStorage\iscsi02-Silver-02\$vmName\" + $vmName + ".vhdx") `
    -SizeBytes 40GB

Start-VM -ComputerName $vmHost -Name $vmName
```

---

```PowerShell
cls
```

#### # Extend partition

```PowerShell
$driveLetter = "C"

$partition = Get-Partition -DriveLetter $driveLetter |
    where { $_.DiskNumber -ne $null }

$size = (Get-PartitionSupportedSize `
    -DiskNumber $partition.DiskNumber `
    -PartitionNumber $partition.PartitionNumber)

Resize-Partition `
    -DiskNumber $partition.DiskNumber `
    -PartitionNumber $partition.PartitionNumber `
    -Size $size.SizeMax
```

## Upgrade to Team Foundation Server 2018 Update 3.1

```PowerShell
cls
```

### # Install Team Foundation Server 2018 Update 3.1

```PowerShell
$imagePath = ("\\TT-FS01\Products\Microsoft\Team Foundation Server 2018" `
    + "\mu_team_foundation_server_2018_update_3.1_x64_dvd_2bf84f42.iso")

$imageDriveLetter = (Mount-DiskImage -ImagePath $ImagePath -PassThru |
    Get-Volume).DriveLetter
```

& ("\$imageDriveLetter" + ":\\Tfs2018.3.1.exe")

```PowerShell
cls
```

### # Upgrade Elasticsearch

```PowerShell
Push-Location "C:\Program Files\Microsoft Team Foundation Server 2018\Search\zip"

.\Configure-TFSSearch.ps1 -Operation update -User elasticuser -Password {password}
```

> **Note**
>
> When prompted to continue, type **Y** and press **Enter**.

```PowerShell
Pop-Location
```

### Upgrade Team Foundation Server 2018

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B4/7B6D1CBD2C19B51003FBD95CB42F5746255C67B4.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/96/87F9537C67E51072B267648E285275E47A50E096.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0E/B77E501BCF3F0C553B856C3906EE1E5EC763DA0E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B1/D21FF8038A7BB5D628EBFB7FF0063A96458A9BB1.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3D/08625E85F9F5E76945844C194A038C25E6F7443D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B5/DC625A045CA3985949FE4BA331E50C2F75C3B4B5.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B6/2433F6C51D019301BA1A511D7D142D14E74722B6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A0/A1C54B4D7B2CF14B52C34749572D03B5729676A0.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/12/AD6801931D6F8D505116E70965B0AD7522193112.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FD/FFC70967F41E187BBDB8C493A5B621D400784AFD.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DF/C696A1E4117EA711F772FDC1423214B5D9334ADF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A3/D907DBA8FCD3901E0FB194160D3C816503BC34A3.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/69/1162CFBC05E4E21286D627C176AA5B135B078569.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/04/56272E5E7CFC6C7CF4C7F0F966D6C994DD18F504.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/60/6D820ABAF78E9997E6269539B15147312C27B160.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/33/72093A1AB7492E89BD7BFEAC95FE364629E1E733.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5F/5D27BE40722E3DB933FC69FCCA8D14A05C77CB5F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2C/84964D2E74A66B508FD40C3892ACC395389D7B2C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E1/1C8893713FBD811558E07EFB6F7FCC7DF1D4E4E1.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/22/848E53D606E5045DC0A31D23C44F3D7BA1233222.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B4/0E323053BD244F73542440CADFF31AFEECCAA2B4.png)

### Issue - Error searching work items and code

We encountered an unexpected error when processing your request

From <[https://tfs.technologytoolbox.com/DefaultCollection/_search?type=work%20item&lp=apps-workitems-Collection&text=generation&_a=search](https://tfs.technologytoolbox.com/DefaultCollection/_search?type=work%20item&lp=apps-workitems-Collection&text=generation&_a=search)>

#### Reference

**Search reports unexpected error after installing 2018 Update 3**\
From <[https://developercommunity.visualstudio.com/content/problem/377940/search-reports-unexpected-error-after-installing-2.html](https://developercommunity.visualstudio.com/content/problem/377940/search-reports-unexpected-error-after-installing-2.html)>

#### Solution - Download and install patch

Download patch - [https://aka.ms/tfs2018.3patch](https://aka.ms/tfs2018.3patch)

Install patch


**TODO:**

```PowerShell
cls
```

## # Enter a product key and activate Windows

```PowerShell
slmgr /ipk {product key}
```

**Note:** When notified that the product key was set successfully, click **OK**.

```Console
slmgr /ato
```

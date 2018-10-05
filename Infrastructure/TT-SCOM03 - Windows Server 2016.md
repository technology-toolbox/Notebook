# TT-SCOM03 - Windows Server 2016

Wednesday, March 28, 2018
5:29 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

### Create domain group for SCOM administrators

(skipped -- since this was done previously)

### Add SCOM administrators to group

(skipped -- since this was done previously)

### Install Windows Server 2016

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "TT-SCOM03"
$vmPath = "E:\NotBackedUp\VMs\$vmName"
$vhdPath = "$vmPath\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 8GB `
    -SwitchName "Embedded Team Switch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 4

Start-VM -ComputerName $vmHost -Name $vmName
```

---

#### Install custom Windows Server 2016 image

- On the **Task Sequence** step, select **Windows Server 2016** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **TT-SCOM03**.
  - Click **Next**.
- On the **Applications** step, ensure no items are selected and click **Next**.

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

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Move computer to different OU

```PowerShell
$vmName = "TT-SCOM03"

$targetPath = ("OU=System Center Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

---

### Login as .\\foo

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
$vmName = "TT-SCOM03"

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
$vmName = "TT-SCOM03"
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

### Configure storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 32 GB       | 4K                   | OSDisk       |

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

##### # Add virtual DVD drive

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "TT-SCOM03"

Add-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName
```

---

```PowerShell
cls
```

#### # Change drive letter for DVD-ROM

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
```

### Add virtual machine to Hyper-V protection group in DPM

## Prepare for SCOM installation

### Reference

**System requirements for System Center 2016 - Operations Manager**\
From <[https://technet.microsoft.com/en-us/system-center-docs/om/plan/system-requirements](https://technet.microsoft.com/en-us/system-center-docs/om/plan/system-requirements)>

### Create SCOM service accounts

---

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Create service account for "Management server action account"

```PowerShell
$displayName = 'Service account for Operations Manager "action account"'
$defaultUserName = 's-scom-action'

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@corp.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=IT,DC=corp,DC=technologytoolbox,DC=com"

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

#### # Create service account for "System Center Configuration service and System Center Data Access service"

```PowerShell
$displayName =
    'Service account for Operations Manager "Data Access"'

$defaultUserName = "s-scom-das"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@corp.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=IT,DC=corp,DC=technologytoolbox,DC=com"

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

#### # Create service account for "Data Reader account"

```PowerShell
$displayName = 'Service account for Operations Manager "Data Reader"'
$defaultUserName = "s-scom-data-reader"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@corp.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=IT,DC=corp,DC=technologytoolbox,DC=com"

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

#### # Create service account for "Data Writer account"

```PowerShell
$displayName = 'Service account for Operations Manager "Data Writer"'
$defaultUserName = "s-scom-data-writer"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@corp.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=IT,DC=corp,DC=technologytoolbox,DC=com"

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

### Login as local administrator

```PowerShell
cls
```

### # Add System Center setup account to local Administrators group

```PowerShell
$localGroup = "Administrators"
$domain = "TECHTOOLBOX"
$serviceAccount = "setup-systemcenter"

([ADSI]"WinNT://./$localGroup,group").Add(
    "WinNT://$domain/$serviceAccount,user")
```

### # Add SCOM "Data Access" service account to local Administrators group

```PowerShell
$localGroup = "Administrators"
$domain = "TECHTOOLBOX"
$serviceAccount = "s-scom-das"

([ADSI]"WinNT://./$localGroup,group").Add(
    "WinNT://$domain/$serviceAccount,user")
```

### # Add SCOM administrators domain group to local Administrators group

```PowerShell
$localGroup = "Administrators"
$domain = "TECHTOOLBOX"
$domainGroup = "Operations Manager Admins"

([ADSI]"WinNT://./$localGroup,group").Add(
    "WinNT://$domain/$domainGroup,group")
```

```PowerShell
cls
```

### # Install SSL certificate

#### # Create certificate for Reporting Services and Operations Manager web console

##### # Create certificate request

```PowerShell
$hostname = "systemcenter.technologytoolbox.com"
$altHostname = "systemcenter"

& "C:\NotBackedUp\Public\Toolbox\PowerShell\New-CertificateRequest.ps1" `
    -Subject ("CN=$hostname,OU=IT" `
        + ",O=Technology Toolbox,L=Parker,S=CO,C=US") `
    -SANs $hostname, $altHostname
```

---

**PowerShell - Run as TECHTOOLBOX\\jjameson-admin**

##### # Submit certificate request to Certification Authority

###### # Add Active Directory Certificate Services site to the "Trusted sites" zone and browse to the site

```PowerShell
$adcsUrl = [Uri] "https://cipher01.corp.technologytoolbox.com"

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-InternetSecurityZoneMapping.ps1 `
    -Zone LocalIntranet `
    -Patterns $adcsUrl.AbsoluteUri

Start-Process $adcsUrl.AbsoluteUri
```

---

> **Note**
>
> Copy the certificate request to the clipboard.

**To submit the certificate request to an enterprise CA:**

1. On the computer hosting the Operations Manager feature for which you are requesting a certificate, start Internet Explorer, and browse to Active Directory Certificate Services site ([https://cipher01.corp.technologytoolbox.com/](https://cipher01.corp.technologytoolbox.com/)).
2. On the **Welcome** page, click **Request a certificate**.
3. On the **Advanced Certificate Request** page, click **Submit a certificate request by using a base-64-encoded CMC or PKCS #10 file, or submit a renewal request by using a base-64-encoded PKCS #7 file.**
4. On the **Submit a Certificate Request or Renewal Request** page, in the **Saved Request** text box, paste the contents of the certificate request generated in the previous procedure.
5. In the **Certificate Template** section, select the certificate template (**Technology Toolbox Web Server - Exportable**), and then click **Submit**. When prompted to allow the digital certificate operation to be performed, click **Yes**.
6. On the **Certificate Issued** page, click **Download certificate** and save the certificate.

---

**PowerShell - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

##### # Import the certificate into the certificate store

```PowerShell
Start-Process $PSHOME\powershell.exe `
    -ArgumentList "-Command Start-Process PowerShell.exe -Verb Runas" `
    -Wait
```

---

**Administrator: PowerShell - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
$certFile = "C:\Users\jjameson-admin\Downloads\certnew.cer"

CertReq.exe -Accept $certFile

If ($? -eq $true)
{
    Remove-Item $certFile
}

Exit
```

---

```Console
Exit
```

---

### Login as TECHTOOLBOX\\setup-systemcenter

```PowerShell
cls
```

### # Install and configure SQL Server Reporting Services

#### # Install SQL Server 2016 Reporting Services

```PowerShell
$imagePath = "\\TT-FS01\Products\Microsoft\SQL Server 2016" `
    + "\en_sql_server_2016_standard_with_service_pack_1_x64_dvd_9540929.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$installer = $imageDriveLetter + ":\setup.exe"

& $installer
```

On the **Feature Selection** step, select **Reporting Services - Native**.

On the **Server Configuration** step, on the **Service Accounts** tab:

- In the **Account Name** column for **SQL Server Reporting Services**, type **NT AUTHORITY\\NETWORK SERVICE**.
- In the **Startup Type** column for **SQL Server Reporting Services**, ensure **Automatic** is selected.

---

**SQL Server Management Studio - TT-SQL01**

#### -- Temporarily add SCOM installation account to sysadmin role in SQL Server

```SQL
USE [master]
GO
CREATE LOGIN [TECHTOOLBOX\setup-systemcenter]
FROM WINDOWS WITH DEFAULT_DATABASE=[master]
GO
ALTER SERVER ROLE [sysadmin]
ADD MEMBER [TECHTOOLBOX\setup-systemcenter]
GO
```

---

#### Configure SQL Server Reporting Services

1. Start **Reporting Services Configuration Manager**. If prompted by User Account Control to allow the program to make changes to the computer, click **Yes**.
2. In the **Reporting Services Configuration Connection** dialog box, ensure the name of the server and SQL Server instance are both correct, and then click **Connect**.
3. In the **Report Server Status** pane, click **Start** if the server is not already started.
4. In the navigation pane, click **Service Account**.
5. In the **Service Account** pane, ensure **Use built-in account** is selected and the account is set to **Network Service**.
6. In the navigation pane, click **Web Service URL**.
7. In the **Web Service URL **pane:
   1. Confirm the following warning message appears:
   2. In the **Report Server Web Service Site identification** section, in the **HTTPS Certificate** dropdown list, select the SSL certificate installed previously for System Center (**systemcenter.technologytoolbox.com**).
   3. Click **Apply**.
8. In the navigation pane, click **Database**.
9. In the **Report Server Database** pane, click **Change Database**.
10. In the **Report Server Database Configuration Wizard** window:
    1. In the **Action** pane, ensure **Create a new report server database** is selected, and then click **Next**.
    2. In the **Database Server** pane, type the name of the database server (**TT-SQL01**) in the **Server Name** box, click **Test Connection** and confirm the test succeeded, and then click **Next**.
    3. In the **Database **pane, type the name of the database (**ReportServer_SCOM**) in the **Database Name** box and then click **Next**.
    4. In the **Credentials **pane, ensure **Authentication Type** is set to **Service Credentials** and then click **Next**.
    5. On the **Summary** page, verify the information is correct, and then click **Next**.
    6. Click **Finish** to close the wizard.
11. In the navigation pane, click **Web Portal URL**.
12. In the **Web Portal URL **pane:
    1. Confirm the following warning message appears:
    2. Click **Apply**.
13. In the navigation pane, click **Encryption Keys**.
14. In the **Encryption Keys **pane, click **Backup**.
15. In the **Backup Encryption Key** window:
    1. In the **File Location **box, specify the location where you want to store a copy of this key.
    2. In the **Password** box, type a password for the file.
    3. In the **Confirm Password** box, retype the password for the file.
    4. Click **OK**.

Report Server Web Service is not configured. Default values have been provided to you. To accept these defaults simply press the Apply button, else change them and then press Apply.

The Web Portal virtual directory name is not configured. To configure the directory, enter a name or use the default value that is provided, and then click Apply.

> **Important**
>
> Store the key on a separate computer from the one that is running Reporting Services.

**C:\\NotBackedUp\\Temp\\Reporting Services - SCOM.snk**

---

**PowerShell - Run as TECHTOOLBOX\\jjameson-admin**

#### # Move encryption key backup to file server

```PowerShell
copy "C:\NotBackedUp\Temp\Reporting Services - SCOM.snk" `
    \\TT-FS01\Users$\jjameson-admin\Documents
```

---

---

**SQL Server Management Studio - TT-SQL01**

#### -- Remove SCOM installation account from sysadmin role in SQL Server

```SQL
USE [master]
GO
ALTER SERVER ROLE [sysadmin]
DROP MEMBER [TECHTOOLBOX\setup-systemcenter]
GO
```

---

```PowerShell
cls
```

#### # Remove SQL Server installation media

```PowerShell
Dismount-DiskImage -ImagePath $imagePath
```

#### Add Reporting Services databases to AlwaysOn Availability Group

---

**SQL Server Management Studio - TT-SQL01A**

##### -- Change recovery model for Reporting Services  TempDB from Simple to Full

```SQL
USE [master]
GO
ALTER DATABASE [ReportServer_SCOMTempDB] SET RECOVERY FULL WITH NO_WAIT
GO
```

##### -- Backup Reporting Services databases

```Console
DECLARE @backupFilePath VARCHAR(255) =
    'Z:\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\'
        + 'ReportServer_SCOM.bak'

BACKUP DATABASE ReportServer_SCOM
    TO DISK = @backupFilePath
    WITH FORMAT, INIT, SKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 5

SET @backupFilePath =
    'Z:\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\'
        + 'ReportServer_SCOMTempDB.bak'

BACKUP DATABASE ReportServer_SCOMTempDB
    TO DISK = @backupFilePath
    WITH FORMAT, INIT, SKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 5

GO
```

##### -- Backup transaction logs

```Console
DECLARE @backupFilePath VARCHAR(255) =
    'Z:\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\'
        + 'ReportServer_SCOM.trn'

BACKUP LOG ReportServer_SCOM
    TO DISK = @backupFilePath
    WITH NOFORMAT, NOINIT, NOSKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 5

SET @backupFilePath =
    'Z:\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\'
        + 'ReportServer_SCOMTempDB.trn'

BACKUP LOG ReportServer_SCOMTempDB
    TO DISK = @backupFilePath
    WITH NOFORMAT, NOINIT, NOSKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 5

GO
```

##### -- Add Reporting Services databases to Availability Group

```SQL
ALTER AVAILABILITY GROUP [TT-SQL01] ADD DATABASE ReportServer_SCOM
ALTER AVAILABILITY GROUP [TT-SQL01] ADD DATABASE ReportServer_SCOMTempDB
GO
```

---

---

**SQL Server Management Studio - TT-SQL01B**

##### -- Configure RSExecRole in system databases

```SQL
USE [master]
GO
CREATE ROLE [RSExecRole]
GO
GRANT EXECUTE ON [sys].[xp_sqlagent_enum_jobs] TO [RSExecRole]
GRANT EXECUTE ON [sys].[xp_sqlagent_is_starting] TO [RSExecRole]
GRANT EXECUTE ON [sys].[xp_sqlagent_notify] TO [RSExecRole]
GO
USE [msdb]
GO
CREATE ROLE [RSExecRole]
GO
GRANT EXECUTE ON [dbo].[sp_add_category] TO [RSExecRole]
GRANT EXECUTE ON [dbo].[sp_add_job] TO [RSExecRole]
GRANT EXECUTE ON [dbo].[sp_add_jobschedule] TO [RSExecRole]
GRANT EXECUTE ON [dbo].[sp_add_jobserver] TO [RSExecRole]
GRANT EXECUTE ON [dbo].[sp_add_jobstep] TO [RSExecRole]
GRANT EXECUTE ON [dbo].[sp_delete_job] TO [RSExecRole]
GRANT EXECUTE ON [dbo].[sp_help_category] TO [RSExecRole]
GRANT EXECUTE ON [dbo].[sp_help_job] TO [RSExecRole]
GRANT EXECUTE ON [dbo].[sp_help_jobschedule] TO [RSExecRole]
GRANT EXECUTE ON [dbo].[sp_verify_job_identifiers] TO [RSExecRole]
GRANT SELECT ON [dbo].[syscategories] TO [RSExecRole]
GRANT SELECT ON [dbo].[sysjobs] TO [RSExecRole]
GO
```

##### -- Create login used by Reporting Services databases

```SQL
USE [master]
GO

CREATE LOGIN [TECHTOOLBOX\TT-SCOM03$] FROM WINDOWS
WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english]
GO
```

##### -- Add login used by Reporting Services to RSExecRole in system databases

```SQL
USE [master]
GO
CREATE USER [TECHTOOLBOX\TT-SCOM03$] FOR LOGIN [TECHTOOLBOX\TT-SCOM03$]
ALTER ROLE [RSExecRole] ADD MEMBER [TECHTOOLBOX\TT-SCOM03$]
GO
USE [msdb]
GO
CREATE USER [TECHTOOLBOX\TT-SCOM03$] FOR LOGIN [TECHTOOLBOX\TT-SCOM03$]
ALTER ROLE [RSExecRole] ADD MEMBER [TECHTOOLBOX\TT-SCOM03$]
GO
```

##### -- Restore Reporting Services databases from backup

```Console
DECLARE @backupFilePath VARCHAR(255) =
    '\\TT-SQL01A\SQL-Backups\ReportServer_SCOM.bak'

RESTORE DATABASE ReportServer_SCOM
    FROM DISK = @backupFilePath
    WITH  NORECOVERY,  NOUNLOAD,  STATS = 5

SET @backupFilePath =
    '\\TT-SQL01A\SQL-Backups\ReportServer_SCOMTempDB.bak'

RESTORE DATABASE ReportServer_SCOMTempDB
    FROM DISK = @backupFilePath
    WITH  NORECOVERY,  NOUNLOAD,  STATS = 5

GO
```

##### -- Restore transaction logs from backup

```Console
DECLARE @backupFilePath VARCHAR(255) =
    '\\TT-SQL01A\SQL-Backups\ReportServer_SCOM.trn'

RESTORE DATABASE ReportServer_SCOM
    FROM DISK = @backupFilePath
    WITH  NORECOVERY,  NOUNLOAD,  STATS = 5

SET @backupFilePath =
    '\\TT-SQL01A\SQL-Backups\ReportServer_SCOMTempDB.trn'

RESTORE DATABASE ReportServer_SCOMTempDB
    FROM DISK = @backupFilePath
    WITH  NORECOVERY,  NOUNLOAD,  STATS = 5

GO
```

##### -- Wait for the replica to start communicating

```Console
begin try
    declare @conn bit
    declare @count int
    declare @replica_id uniqueidentifier
    declare @group_id uniqueidentifier
    set @conn = 0
    set @count = 30 -- wait for 5 minutes

    if (serverproperty('IsHadrEnabled') = 1)
        and (isnull(
            (select member_state from master.sys.dm_hadr_cluster_members where upper(member_name COLLATE Latin1_General_CI_AS) = upper(cast(serverproperty('ComputerNamePhysicalNetBIOS') as nvarchar(256)) COLLATE Latin1_General_CI_AS)), 0) <> 0)
        and (isnull((select state from master.sys.database_mirroring_endpoints), 1) = 0)
    begin
        select @group_id = ags.group_id
        from master.sys.availability_groups as ags
        where name = N'TT-SQL01'

        select @replica_id = replicas.replica_id
        from master.sys.availability_replicas as replicas
        where
            upper(replicas.replica_server_name COLLATE Latin1_General_CI_AS) =
                upper(@@SERVERNAME COLLATE Latin1_General_CI_AS)
            and group_id = @group_id

    while @conn <> 1 and @count > 0
        begin
            set @conn = isnull(
                (select connected_state
                from master.sys.dm_hadr_availability_replica_states as states
                where states.replica_id = @replica_id), 1)

        if @conn = 1
            begin
                -- exit loop when the replica is connected,
                -- or if the query cannot find the replica status
                break
            end

            waitfor delay '00:00:10'
            set @count = @count - 1
        end
    end
end try
begin catch
    -- If the wait loop fails, do not stop execution of the alter database statement
end catch
GO

USE [master]
GO

ALTER DATABASE [ReportServer_SCOM] SET HADR AVAILABILITY GROUP = [TT-SQL01]
ALTER DATABASE [ReportServer_SCOMTempDB] SET HADR AVAILABILITY GROUP = [TT-SQL01]
GO
```

---

```PowerShell
cls
```

### # Install IIS

```PowerShell
Install-WindowsFeature `
    NET-WCF-HTTP-Activation45, `
    Web-Static-Content, `
    Web-Default-Doc, `
    Web-Dir-Browsing, `
    Web-Http-Errors, `
    Web-Http-Logging, `
    Web-Request-Monitor, `
    Web-Filtering, `
    Web-Stat-Compression, `
    Web-Mgmt-Console, `
    Web-Metabase, `
    Web-Asp-Net, `
    Web-Windows-Auth `
    -Source '\\TT-FS01\Products\Microsoft\Windows Server 2016\Sources\SxS' `
    -Restart
```

> **Note**
>
> HTTP Activation is required but is not included in the list of prerequisites on TechNet.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/85/5AF94B5986A5DFD2414DAE2DC8D3BF3145BE7D85.png)

#### Reference

[https://technet.microsoft.com/en-us/system-center-docs/om/plan/system-requirements](https://technet.microsoft.com/en-us/system-center-docs/om/plan/system-requirements)

```PowerShell
cls
```

### # Configure website for Operations Manager web console

#### # Create IIS website for Operations Manager web console

```PowerShell
$hostHeader = "systemcenter"
$siteName = "System Center Web Site"
$sitePath = "C:\inetpub\wwwroot\SystemCenter"

$appPool = New-WebAppPool -Name $siteName

New-Item -Type Directory -Path $sitePath | Out-Null

New-Website `
    -Name $siteName `
    -HostHeader $hostHeader `
    -PhysicalPath $sitePath `
    -ApplicationPool $siteName | Out-Null
```

#### # Add HTTPS binding to website

```PowerShell
$cert = Get-ChildItem -Path Cert:\LocalMachine\My |
    Where { $_.Subject -like "CN=`systemcenter*" }

New-WebBinding `
    -Name $siteName `
    -Protocol https `
    -Port 443 `
    -HostHeader systemcenter `
    -SslFlags 0

(Get-WebBinding `
    -Name $siteName `
    -Protocol https).AddSslCertificate($cert.Thumbprint, "my")
```

#### Configure name resolution for Operations Manager web console

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
Add-DNSServerResourceRecordCName `
    -ComputerName TT-DC06 `
    -ZoneName technologytoolbox.com `
    -Name systemcenter `
    -HostNameAlias TT-SCOM03.corp.technologytoolbox.com
```

---

```PowerShell
cls
```

### # Install Microsoft System CLR Types for SQL Server 2014

```PowerShell
& "\\TT-FS01\Products\Microsoft\System Center 2016\Microsoft CLR Types for SQL Server 2014\SQLSysClrTypes.msi"
```

```PowerShell
cls
```

### # Install Microsoft Report Viewer 2015 Runtime

```PowerShell
& "\\TT-FS01\Products\Microsoft\System Center 2016\Microsoft Report Viewer 2015 Runtime\ReportViewer.msi"
```

```PowerShell
cls
```

## # Install Operations Manager

### Configure database server for SCOM 2016 installation

---

**TT-SQL01A**

#### # Create temporary firewall rules for SCOM 2016 installation

```PowerShell
New-NetFirewallRule `
    -Name "SCOM 2016 Installation - TCP" `
    -DisplayName "SCOM 2016 Installation - TCP" `
    -Group 'Technology Toolbox (Custom)' `
    -Protocol "TCP" `
    -LocalPort "135", "445", "49152-65535" `
    -Profile Domain `
    -Direction Inbound `
    -Action Allow

New-NetFirewallRule `
    -Name "SCOM 2016 Installation - UDP" `
    -DisplayName "SCOM 2016 Installation - UDP" `
    -Group 'Technology Toolbox (Custom)' `
    -Protocol "UDP" `
    -LocalPort "137" `
    -Profile Domain `
    -Direction Inbound `
    -Action Allow
```

---

##### Reference

**SCOM 2012 - Installing Operations Manager Database on server behind a firewall**\
Pasted from <[http://social.technet.microsoft.com/Forums/systemcenter/en-US/6c3dc8ff-4f66-4c73-9c9e-4ca948cde3ff/scom-2012-installing-operations-manager-database-on-server-behind-a-firewall?forum=operationsmanagerdeployment](http://social.technet.microsoft.com/Forums/systemcenter/en-US/6c3dc8ff-4f66-4c73-9c9e-4ca948cde3ff/scom-2012-installing-operations-manager-database-on-server-behind-a-firewall?forum=operationsmanagerdeployment)>

---

**TT-SQL01A**

```PowerShell
cls
```

#### # Temporarily add SCOM installation account to local Administrators group on SQL Server

```PowerShell
$localGroup = "Administrators"
$domain = "TECHTOOLBOX"
$domainUser = "setup-systemcenter"

([ADSI]"WinNT://./$localGroup,group").Add(
    "WinNT://$domain/$domainUser,user")
```

---

[08:19:16]:        Error:        :GetRemoteOSVersion(): Threw Exception.Type: System.UnauthorizedAccessException, Exception Error Code: 0x80070005, Exception.Message: Access is denied. (Exception from HRESULT: 0x80070005 (E_ACCESSDENIED))\
[08:19:16]:        Error:        :StackTrace:   at System.Runtime.InteropServices.Marshal.ThrowExceptionForHRInternal(Int32 errorCode, IntPtr errorInfo)\
   at System.Management.ManagementScope.InitializeGuts(Object o)\
   at System.Management.ManagementScope.Initialize()\
   at System.Management.ManagementObjectSearcher.Initialize()\
   at System.Management.ManagementObjectSearcher.Get()\
   at Microsoft.EnterpriseManagement.OperationsManager.Setup.Common.SetupValidationHelpers.GetRemoteOSVersion(String remoteComputer)

---

**SQL Server Management Studio - TT-SQL01A**

#### -- Temporarily add SCOM installation account to sysadmin role in SQL Server

```SQL
USE [master]
GO
ALTER SERVER ROLE [sysadmin]
ADD MEMBER [TECHTOOLBOX\setup-systemcenter]
GO
```

---

```PowerShell
cls
```

### # Extract SCOM setup files

```PowerShell
$imagePath = "\\TT-FS01\Products\Microsoft\System Center 2016" `
    + "\en_system_center_2016_operations_manager_x64_dvd_9216830.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$installer = $imageDriveLetter + ":\SC2016_SCOM_EN.exe"

& $installer
```

Destination location: **C:\\NotBackedUp\\Temp\\System Center 2016 Operations Manager**

```PowerShell
Dismount-DiskImage -ImagePath $imagePath

$installer = "C:\NotBackedUp\Temp\System Center 2016 Operations Manager\Setup.exe"

& $installer
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/73/01E21318903E12D73885F9A2BF35D2DDC483C073.png)

Select **Download the latest updates to the setup program** and then click **Install**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/82/0CDBEA77CD9496C194CD9E86C1CF1355F67C1D82.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7C/D9C16BB3304B86686DCDFA06AAD892DF12A77B7C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6D/78A2009EEAC4229FEF104752118BA5760471526D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9F/537D1F6557104135F99304BFBF14A48BF1C2B79F.png)

Click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7E/F41A7F0FE07D0CB003C16DFD62D1BA7872F9F07E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E1/020C2B493B0925D837B925D186AD5BC6BC115CE1.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F3/5E57BBEB23924B734C13B44521E4D7838495D6F3.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7F/33CD91DF2185870D95DE8A547566530325C23D7F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E5/D2E8B0B7574ED8477E6375A0D89D60879F0B60E5.png)

Press Tab to connect to the database server.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F0/636A2EF90A7E4426C2BDC872BA5BC4BC54597EF0.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E1/BD70C4F7ED1E4879CE41B29AE6458B00651B71E1.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A1/74A10D6A1BEACD4213C2682CD4691A5F50AD77A1.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/42/BDD86267724895435905AB5B73E1B21625451742.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7F/D83A8C4D32577085F6D16902EAC307101432BF7F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6A/43E9FB6C4372CC12E40B2D523237F8B70EE5C96A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E6/5101D053D2CBF4D12DCBBE6C12E882EC6BA4CDE6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B2/CEFCD00B1F004A23A86F960EC92DF7C934665DB2.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A8/1DAE864F8AE18BAE15571A15A69F00700C9D43A8.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EB/0B13C8030662C4C687FA78EC0BF0904E9C0B6DEB.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/52/2E63667BF93752EF3324A55D801B31EA9FABC252.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/79/EFFC118244371048B0EFD36473A51C6F8C238D79.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B8/2300D5ED1DEEE9F65F04859FBD31B33BEF92D1B8.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AA/CC2176092C4FBFFDCFDA1BD826FEDC8E9BF4CBAA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/24/E151888D81919732C5AF0EF34BCCC65B9A0FA124.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A2/1D660D92D5232200A048A07F0FA203A5E83F80A2.png)

### Configure database server after SCOM 2016 installation

---

**TT-SQL01A**

```PowerShell
cls
```

#### # Disable firewall rules for SCOM 2016 installation

```PowerShell
Disable-NetFirewallRule -Name "SCOM 2016 Installation - TCP"
Disable-NetFirewallRule -Name "SCOM 2016 Installation - UDP"
```

#### # Remove SCOM installation account from local Administrators group on SQL Server

```PowerShell
$localGroup = "Administrators"
$domain = "TECHTOOLBOX"
$domainUser = "setup-systemcenter"

([ADSI]"WinNT://./$localGroup,group").Remove(
    "WinNT://$domain/$domainUser,user")
```

---

---

**SQL Server Management Studio - TT-SQL01A**

#### -- Remove SCOM installation account from sysadmin role in SQL Server

```SQL
USE [master]
GO
ALTER SERVER ROLE [sysadmin]
DROP MEMBER [TECHTOOLBOX\setup-systemcenter]
GO
```

---

#### Add SCOM databases to AlwaysOn Availability Group

---

**SQL Server Management Studio - TT-SQL01A**

##### -- Change recovery model for SCOM databases from Simple to Full

```SQL
USE master
GO
ALTER DATABASE OperationsManager SET RECOVERY FULL WITH NO_WAIT
ALTER DATABASE OperationsManagerDW SET RECOVERY FULL WITH NO_WAIT
GO
```

##### -- Backup SCOM databases

```Console
DECLARE @backupFilePath VARCHAR(255) =
    'Z:\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\'
        + 'OperationsManager.bak'

BACKUP DATABASE OperationsManager
    TO DISK = @backupFilePath
    WITH FORMAT, INIT, SKIP, REWIND, NOUNLOAD, COMPRESSION, STATS = 5

SET @backupFilePath =
    'Z:\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\'
        + 'OperationsManagerDW.bak'

BACKUP DATABASE OperationsManagerDW
    TO DISK = @backupFilePath
    WITH FORMAT, INIT, SKIP, REWIND, NOUNLOAD, COMPRESSION, STATS = 5

GO
```

##### -- Backup transaction logs

```Console
DECLARE @backupFilePath VARCHAR(255) =
    'Z:\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\'
        + 'OperationsManager.trn'

BACKUP LOG OperationsManager
    TO DISK = @backupFilePath
    WITH NOFORMAT, NOINIT, NOSKIP, REWIND, NOUNLOAD, COMPRESSION, STATS = 5

SET @backupFilePath =
    'Z:\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\'
        + 'OperationsManagerDW.trn'

BACKUP LOG OperationsManagerDW
    TO DISK = @backupFilePath
    WITH NOFORMAT, NOINIT, NOSKIP, REWIND, NOUNLOAD, COMPRESSION, STATS = 5

GO
```

##### -- Add SCOM databases to Availability Group

```SQL
USE master
GO
ALTER AVAILABILITY GROUP [TT-SQL01] ADD DATABASE OperationsManager
ALTER AVAILABILITY GROUP [TT-SQL01] ADD DATABASE OperationsManagerDW
GO
```

---

---

**SQL Server Management Studio - TT-SQL01B**

##### -- Create logins used by SCOM

```SQL
USE master
GO

CREATE LOGIN [TECHTOOLBOX\s-scom-action] FROM WINDOWS
WITH DEFAULT_DATABASE=master

CREATE LOGIN [TECHTOOLBOX\s-scom-das] FROM WINDOWS
WITH DEFAULT_DATABASE=master

CREATE LOGIN [TECHTOOLBOX\s-scom-data-reader] FROM WINDOWS
WITH DEFAULT_DATABASE=master

CREATE LOGIN [TECHTOOLBOX\s-scom-data-writer] FROM WINDOWS
WITH DEFAULT_DATABASE=master

GO
```

##### -- Add login used by SCOM Reporting to roles in system databases

```SQL
USE master
GO
CREATE USER [TECHTOOLBOX\s-scom-data-reader]
FOR LOGIN [TECHTOOLBOX\s-scom-data-reader]

ALTER ROLE RSExecRole ADD MEMBER [TECHTOOLBOX\s-scom-data-reader]
GO

USE msdb
GO
CREATE USER [TECHTOOLBOX\s-scom-data-reader]
FOR LOGIN [TECHTOOLBOX\s-scom-data-reader]

ALTER ROLE RSExecRole ADD MEMBER [TECHTOOLBOX\s-scom-data-reader]
ALTER ROLE SQLAgentOperatorRole ADD MEMBER [TECHTOOLBOX\s-scom-data-reader]
ALTER ROLE SQLAgentReaderRole ADD MEMBER [TECHTOOLBOX\s-scom-data-reader]
ALTER ROLE SQLAgentUserRole ADD MEMBER [TECHTOOLBOX\s-scom-data-reader]
GO
```

##### -- Restore SCOM databases from backup

```Console
DECLARE @backupFilePath VARCHAR(255) =
    '\\TT-SQL01A\SQL-Backups\OperationsManager.bak'

RESTORE DATABASE OperationsManager
    FROM DISK = @backupFilePath
    WITH  NORECOVERY,  NOUNLOAD,  STATS = 5

SET @backupFilePath =
    '\\TT-SQL01A\SQL-Backups\OperationsManagerDW.bak'

RESTORE DATABASE OperationsManagerDW
    FROM DISK = @backupFilePath
    WITH  NORECOVERY,  NOUNLOAD,  STATS = 5

GO
```

##### -- Restore transaction logs from backup

```Console
DECLARE @backupFilePath VARCHAR(255) =
    '\\TT-SQL01A\SQL-Backups\OperationsManager.trn'

RESTORE DATABASE OperationsManager
    FROM DISK = @backupFilePath
    WITH  NORECOVERY,  NOUNLOAD,  STATS = 5

SET @backupFilePath =
    '\\TT-SQL01A\SQL-Backups\OperationsManagerDW.trn'

RESTORE DATABASE OperationsManagerDW
    FROM DISK = @backupFilePath
    WITH  NORECOVERY,  NOUNLOAD,  STATS = 5

GO
```

##### -- Wait for the replica to start communicating

```Console
begin try
    declare @conn bit
    declare @count int
    declare @replica_id uniqueidentifier
    declare @group_id uniqueidentifier
    set @conn = 0
    set @count = 30 -- wait for 5 minutes

    if (serverproperty('IsHadrEnabled') = 1)
        and (isnull(
            (select member_state from master.sys.dm_hadr_cluster_members where upper(member_name COLLATE Latin1_General_CI_AS) = upper(cast(serverproperty('ComputerNamePhysicalNetBIOS') as nvarchar(256)) COLLATE Latin1_General_CI_AS)), 0) <> 0)
        and (isnull((select state from master.sys.database_mirroring_endpoints), 1) = 0)
    begin
        select @group_id = ags.group_id
        from master.sys.availability_groups as ags
        where name = N'TT-SQL01'

        select @replica_id = replicas.replica_id
        from master.sys.availability_replicas as replicas
        where
            upper(replicas.replica_server_name COLLATE Latin1_General_CI_AS) =
                upper(@@SERVERNAME COLLATE Latin1_General_CI_AS)
            and group_id = @group_id

    while @conn <> 1 and @count > 0
        begin
            set @conn = isnull(
                (select connected_state
                from master.sys.dm_hadr_availability_replica_states as states
                where states.replica_id = @replica_id), 1)

        if @conn = 1
            begin
                -- exit loop when the replica is connected,
                -- or if the query cannot find the replica status
                break
            end

            waitfor delay '00:00:10'
            set @count = @count - 1
        end
    end
end try
begin catch
    -- If the wait loop fails, do not stop execution of the alter database statement
end catch
GO

USE master
GO
ALTER DATABASE OperationsManager SET HADR AVAILABILITY GROUP = [TT-SQL01]
ALTER DATABASE OperationsManagerDW SET HADR AVAILABILITY GROUP = [TT-SQL01]
GO
```

##### -- Enable execution of user code in the .NET Framework

```SQL
sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
sp_configure 'clr enabled', 1;
GO
RECONFIGURE;
GO
```

---

##### Reference

**Using SQL Server 2012 Always On Availability Groups with System Center 2012 SP1 - Operations Manager**\
From <[https://technet.microsoft.com/en-us/library/jj899851(v=sc.12).aspx](https://technet.microsoft.com/en-us/library/jj899851(v=sc.12).aspx)>

---

**SQL Server Management Studio - TT-SQL01**

#### -- Configure autogrowth for SCOM databases

```SQL
ALTER DATABASE OperationsManager
MODIFY FILE (NAME = N'MOM_DATA', MAXSIZE = UNLIMITED, FILEGROWTH = 102400KB)

ALTER DATABASE OperationsManager
MODIFY FILE (NAME = N'MOM_LOG', MAXSIZE = UNLIMITED, FILEGROWTH = 102400KB)

ALTER DATABASE OperationsManagerDW
MODIFY FILE (NAME = N'MOM_DATA', MAXSIZE = UNLIMITED, FILEGROWTH = 102400KB)

ALTER DATABASE OperationsManagerDW
MODIFY FILE (NAME = N'MOM_LOG', MAXSIZE = UNLIMITED, FILEGROWTH = 102400KB)

GO
```

#### -- Shrink transaction log files

```SQL
USE [OperationsManager]
GO
DBCC SHRINKFILE (N'MOM_LOG', 100)
GO
USE [OperationsManagerDW]
GO
DBCC SHRINKFILE (N'MOM_LOG', 100)
GO
```

---

## Fix Web address in notification emails

![(screenshot)](https://assets.technologytoolbox.com/screenshots/28/03F46301CF3B2E420B8C2E4137B377D0C9BA9D28.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/27/F303578B50EF831A0DC3C78E23C5CBA3914DB227.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1D/71682F3913FE0135D4051E072871786EFEB3741D.png)

## Create SMTP Channel

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0E/51F5AD444D79EAF87BC131FD3E4DA3B0EF5D2A0E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/40/3B37F0C274B09610ED827396B8E55B0BDFD2B140.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AF/69506DB963FBA5E742A33E14336B7F26B1B042AF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/14/C669D1F0842F7C5F9DDB812126D14CF37ACAB014.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FA/B742C28C3AFD8B03799D717AA68DDDF83CCD3CFA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D6/959B4B5C0A311B55719668ECFA277DC6BB665CD6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/91/3322FB9AD730452110F0D98F278316E9B8F62891.png)

Click **Finish** to accept the defaults.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D3/EFEE20D9A2E9F79ACD8BAFB13C6BAEE5FEAE61D3.png)

## Create a new subscriber

![(screenshot)](https://assets.technologytoolbox.com/screenshots/38/FABA2AB6F7C2FA357CE9D0D9D21AE134A2C7F138.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/19/0339DB56020BF568CEDE286E6A5FD55E76EA9F19.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A6/6DFAFE84C2AAA361BC20F7CBC39AB960120D1DA6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/84/8B3D3F1902055D9A580B63DB7D1546EFC0568384.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/13/3F238D240A1F1134809E17D6DA58F14A9DDE2713.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/14/7AA593DD7BA0D5DEFD68004ABFA66CFD7C01E814.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/80/174B2138CDCC67AC7C4015CE343F9D8765E9C780.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DF/839A952D0BD0158F66661EB0D0007E459A0D30DF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EA/C97C69F7E3FC5AF8409D336D2C22DF67F289C8EA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F8/FECC482A12A209F5660FC804AFBF6975EE625EF8.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EC/F87C9C98399F2B02998C964ACB1AFB48073BCEEC.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/29/18C05AAF5A06F1510BC570F367B6522C89BA7329.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E2/5435474B8373A3AABD856EE79810BDCF129ABFE2.png)

## Create subscription

![(screenshot)](https://assets.technologytoolbox.com/screenshots/76/F8C653E740E8AC862F96411112039F6E12C9BB76.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BE/73A6357382AEE463F582F0B974F7056D1D84E7BE.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7B/30A09A8C2293764DC0CC1F950DEEBF5221B70B7B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1C/93655215BB6AAC338DD35270DACDA1050CA5E71C.png)

Click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A5/F40F65E691120B7BEFFC58EF297576C79E7895A5.png)

Click **Add...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0F/E6EDB5D009F69B0D4A2590CDCE7877C646043E0F.png)

Click **Search**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F4/022B419448FA729F4EC329C2245B1E7EFE1DE4F4.png)

Select the subscriber, click **Add **to move it to the **Selected subscribers** list, and then click **OK**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B2/973639A2721C8DAE5FB37F20AD596888B92BF7B2.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/80/3D615581D03E13744C577D7CD965EB580E7EA980.png)

Click **Add...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3C/A43FE1951C5982C87AFADCE8CB09CA1101C4E83C.png)

Click **Search**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/39/9A0A3C9A8DE41DBD187AA59829FDEE54402C5139.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A1/DD2EBB817181314097152D99BA966AA12C39ACA1.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/78/66BB636A7C6DC2320F8B47A15017035590393578.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A1/2BA69BE6F12744BCBDF47A4DE76C5AE8586BE5A1.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/94/95E4637B037C4FDDEBA323F0B575BC0708FA0094.png)

## Add members to Operations Manager Operators role

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3D/51DB56AE00429DA62F215FA2E32AEDAC9EDC6A3D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/85/4F1AF0AFAF4CA5C69571235C97FB2FB880D97885.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/40/B4872E6F9F758A1AE0FA57AD59F259C90DF77340.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/77/0446B37CFE736C2D5DEF7C969B70A01B87D8DA77.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B1/27E1A1A3D86FBCF51B6B904CD77AE8168B2B82B1.png)

## Import management packs

HACK: Attempting to import management packs directly from the catalog now results in errors ("Verification failed"). To workaround the issue, download the latest versions of the management packs, install them, and then import them from disk.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/14/E35B36B1A88EA2254A61479C75358A610A0EA514.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CA/0CB8A54D53947679CF5D057FB11C5B7650E532CA.png)

Click **Add** and then click **Add from catalog...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2C/DB77AC2785DFE3714DAD01BF2101C79F4A537E2C.png)

Click **Search**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/25/87EC6B1C4710F2A67C9BBE557904E78F30A8CE25.png)

In the **Management packs in the catalog** list, expand **Microsoft Corporation**.

- Microsoft Corporation
  - ~~Office Servers~~
    - ~~SharePoint 2010 Products~~
      - ~~Microsoft.SharePoint.Foundation.2010~~
      - ~~Microsoft.SharePoint.Server.2010~~
  - ~~SQL Server~~
    - ~~SQL Server 2012~~
      - ~~SQL Server 2012 (Discovery)~~
      - ~~SQL Server 2012 (Monitoring)~~
      - ~~SQL Server Core Library~~
  - Windows Server
    - ~~Active Directory Server 2008~~
      - ~~Active Directory Server 2008 and above (Discovery)~~
      - ~~Active Directory Server 2008 and above (Monitoring)~~
      - ~~Active Directory Server Common Library~~
    - Core OS
      - Windows Server 2003 Operating System
      - Windows Server 2008 Operating System (Discovery)
      - Windows Server 2008 Operating System (Monitoring)
      - Windows Server 2008 R2 Best Practice Analyzer Monitoring
      - ~~Windows Server 2012 Operating System (Discovery)~~
      - ~~Windows Server 2012 Operating System (Monitoring)~~
      - Windows Server 2012 R2 Operating System (Discovery)
      - Windows Server 2012 R2 Operating System (Monitoring)
      - Windows Server Cluster Disks Monitoring
      - Windows Server Operating System Library
      - Windows Server Operating System Reports
    - Core OS 2016
      - Windows Server 2016 and 1709+ Operating System (Discovery)
      - Windows Server 2016 and 1709+ Operating System (Monitoring)
      - Windows Server Cluster Disks Monitoring
      - Windows Server Operating System Library
      - Windows Server Operating System Reports
    - ~~DHCP Server~~
      - ~~Microsoft Windows Server DHCP 2012 R2~~
      - ~~Microsoft Windows Server DHCP Library~~
    - ~~Domain Naming Service 2012/2012R2~~
      - ~~Microsoft Windows Server DNS Monitoring~~
    - ~~File Services 2012 R2~~
      - ~~File Services Management Pack for Windows Server 2012 R2~~
      - ~~File Services Management Pack Library~~
      - ~~Microsoft Windows Server iSCSI Target 2012 R2~~
      - ~~Microsoft Windows Server SMB 2012 R2~~
    - ~~Hyper-V 2012 R2~~
      - ~~Microsoft Windows Hyper-V 2012 R2 Discovery~~
      - ~~Microsoft Windows Hyper-V 2012 R2 Monitoring~~
      - ~~Microsoft Windows Hyper-V 2012 Library~~
    - IIS 2008
      - Windows Server 2008 Internet Information Services 7
    - IIS 2012
      - Microsoft Windows Server 2012 Internet Information Services 8
      - Windows Server Internet Information Services Library
    - IIS 2016
      - Microsoft Windows Server 2016 Internet Information Services 9
      - Windows Server Internet Information Services Library
    - Windows Server Cluster 2016
      - Windows Cluster Management Library
      - Windows Cluster Management Monitoring
      - Windows Server 2016 Cluster Management Library
      - Windows Server 2016 Cluster Management Monitoring
    - ~~Windows Update Services 3.0~~
      - ~~Windows Server Update Services 3.0~~
      - ~~Windows Server Update Services Core Library~~

![(screenshot)](https://assets.technologytoolbox.com/screenshots/64/0BFE24D1AF4DA2F92729B8835C9FB5D8267CFE64.png)

For each item that has a dependency that is not selected, click the **Resolve** link in the **Status** column.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/05/55C1642FDAA7C8850CFB2A159F812E38AB659705.png)

Repeat the previous steps the remaining warnings.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/63/6E7E95B499A0B282D7035BEAD7957A02D9838B63.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/95/D468C7A840355DA7E9ADCE922F748F042ED81795.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6C/61460EE8170D13D7C82591EFC0A764E2F0AE476C.png)

### Import DPM management packs

#### Import management packs

Download updated MP:

**System Center Management Packs for Data Protection Manager Reporting, Discovery and Monitoring**\
From <[https://www.microsoft.com/en-us/download/details.aspx?id=56560](https://www.microsoft.com/en-us/download/details.aspx?id=56560)>

Import the following management packs from **C:\\Program Files (x86)\\System Center Management Packs\\Microsoft System Center Management Pack for DPM 2016 (ENG)**:

- **Microsoft.SystemCenter.DataProtectionManager.Discovery.mp**
- **Microsoft.SystemCenter.DataProtectionManager.Library.mp**
- **Microsoft.SystemCenter.DataProtectionManager.Reporting.mp**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AF/084734430C83C06BE8886EBE48A866DA0B2663AF.png)

### Import Hyper-V management packs

Download management pack:

**Microsoft System Center 2016 Management Pack for Hyper-V**\
From <[https://www.microsoft.com/en-us/download/details.aspx?id=54918](https://www.microsoft.com/en-us/download/details.aspx?id=54918)>

Install management pack:

C:\\Program Files (x86)\\System Center Management Packs\\Microsoft System Center 2016 Management Pack for Hyper-V\\

### Reference

**Where are the Server 2016 Management Packs?**\
From <[https://blogs.technet.microsoft.com/kevinholman/2016/12/19/where-are-the-server-2016-management-packs/](https://blogs.technet.microsoft.com/kevinholman/2016/12/19/where-are-the-server-2016-management-packs/)>

```PowerShell
cls
```

## # Configure certificate for Operations Manager

### # Create certificate for Operations Manager

#### # Create request for Operations Manager certificate

```PowerShell
& "C:\NotBackedUp\Public\Toolbox\Operations Manager\Scripts\New-OperationsManagerCertificateRequest.ps1"
```

---

**PowerShell - Run as TECHTOOLBOX\\jjameson-admin**

#### # Submit certificate request to Certification Authority

##### # Add Active Directory Certificate Services site to the "Trusted sites" zone and browse to the site

```PowerShell
$adcsUrl = [Uri] "https://cipher01.corp.technologytoolbox.com"

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-InternetSecurityZoneMapping.ps1 `
    -Zone LocalIntranet `
    -Patterns $adcsUrl.AbsoluteUri

Start-Process $adcsUrl.AbsoluteUri
```

---

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

---

**PowerShell - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Import the certificate into the certificate store

```PowerShell
Start-Process $PSHOME\powershell.exe `
    -ArgumentList "-Command Start-Process PowerShell.exe -Verb Runas" `
    -Wait
```

---

**Administrator: PowerShell - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
$certFile = "C:\Users\jjameson-admin\Downloads\certnew.cer"

CertReq.exe -Accept $certFile

Remove-Item $certFile

Exit
```

---

```Console
Exit
```

---

```PowerShell
cls
```

### # Import the certificate into Operations Manager using MOMCertImport

```PowerShell
$hostName = ([System.Net.Dns]::GetHostByName(($env:computerName))).HostName

$certImportToolPath = "\\TT-FS01\Products\Microsoft" `
    + "\System Center 2016\SCOM\SupportTools\AMD64\MOMCertImport.exe"

& $certImportToolPath /SubjectName $hostName
```

## Configure security settings for manual agent installations

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7F/741CAC3BE93FCCCDB395A7CE2F94C8E2F85E167F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5F/32592A465DB232939818597DB470B0DE2E808C5F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/66/2FD73396ACFCADF8C72E2D574B74F4D02A15C166.png)

## Create rules to generate SCOM alerts for event log errors

**Operations Manager Alerts for Event Log Errors**\
Pasted from <[http://www.technologytoolbox.com/blog/jjameson/archive/2011/03/18/operations-manager-alerts-for-event-log-errors.aspx](http://www.technologytoolbox.com/blog/jjameson/archive/2011/03/18/operations-manager-alerts-for-event-log-errors.aspx)>

## Modify custom SCOM rules to filter out "noise"

### Modify rule for Application Event Log Error

Log Name:      Application\
Source:        Microsoft-Windows-Perflib\
Date:          3/22/2017 3:22:52 PM\
Event ID:      1008\
Task Category: None\
Level:         Error\
Keywords:      Classic\
User:          N/A\
Computer:      TT-SCOM03.corp.technologytoolbox.com\
Description:\
The Open Procedure for service "BITS" in DLL "C:\\Windows\\System32\\bitsperf.dll" failed. Performance data for this service will not be available. The first four bytes (DWORD) of the Data section contains the error code.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/14/66B25098E0CCC03EA67A568495922C394B9F2414.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/46/38C01D01063597F436E49A855C972B0C60971B46.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B7/B5EF23D24C9E359478B5F5C5C5452F50AC8C5FB7.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7E/2BC4A1B9546A88043D67706CEF1573557110927E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/07/8E7859BDB05259C255A69140960401B829C00907.png)

Click **Insert**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F6/A557552E6DBEFC22DA85906B562E868D4A687FF6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/45/ED57039DE01BDC58749883CA9EE7BB1B3E90FD45.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/16/FF03480B40846847FF09B102CCD6C2B8713C4416.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/55/EACFC170659AED391B61E7631CD34385E7306855.png)

Click **OK**.

On the **Application Event Log Error Properties** window, click **OK**.

### Modify rule for System Event Log Error

Log Name:      System\
Source:        Microsoft-Windows-FilterManager\
Date:          3/23/2017 11:31:28 AM\
Event ID:      3\
Task Category: None\
Level:         Error\
Keywords:\
User:          SYSTEM\
Computer:      TT-DPM01.corp.technologytoolbox.com\
Description:\
Filter Manager failed to attach to volume '\\Device\\Harddisk7\\DR3862'.  This volume will be unavailable for filtering until a reboot.  The final status was 0xC03A001C.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3D/E0EC29DFE2ECCDB421FD2E5FF1BEFB057B1D963D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/59/391BE88743A2B275A8E665C009C4348327CB1759.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EE/189568DC9DA325D20F3846FA184BBD35693F1AEE.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E7/91F796FF0F412E0CFE21992DBA60C65DB07815E7.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/07/8E7859BDB05259C255A69140960401B829C00907.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/59/58DFEBDD94D543E7E41D39B49EE0D4862772E359.png)

## Install SCOM agent on computers to manage

```PowerShell
cls
```

## # Enable agent proxy (e.g. on domain controllers and cluster nodes)

```PowerShell
Import-Module -Name OperationsManager

Get-SCOMAlert -ResolutionState 0 -Name "Agent Proxy not enabled" |
    ForEach-Object {
        $alert = $_

        $sep = $alert.Description.IndexOf("service (")
        $right = $alert.Description.Substring($sep+9)
        $end = $right.IndexOf(")")
        $left = $right.Substring(0, $end)

        $computerName = $left.Trim()

        $agent = Get-SCOMAgent -DNSHostName $computerName

        If ($agent.ProxyingEnabled.Value -eq $false)
        {
            Enable-SCOMAgentProxy -Agent $agent -Verbose
        }

        Resolve-SCOMAlert -Alert $alert -Verbose
    }
```

### References

**Powershell script to enable SCOM Agent Proxy**\
From <[http://www.itbl0b.com/2013/04/powershell-script-enable-scom-agent-proxy.html](http://www.itbl0b.com/2013/04/powershell-script-enable-scom-agent-proxy.html)>

**SCOM - Auto-Enabling Agent Proxying**\
From <[http://aquilaweb.net/2015/07/12/scom-auto-enabling-agent-proxying/](http://aquilaweb.net/2015/07/12/scom-auto-enabling-agent-proxying/)>

```PowerShell
cls
```

## # Register Service Principal Name for System Center Operations Manager

```PowerShell
setspn -A MSOMSdkSvc/TT-SCOM03 s-scom-das
setspn -A MSOMSdkSvc/TT-SCOM03.corp.technologytoolbox.com s-scom-das
```

### Reference

**OpsMgr 2012: What should the SPN’s look like?**\
From <[https://blogs.technet.microsoft.com/kevinholman/2011/08/08/opsmgr-2012-what-should-the-spns-look-like/](https://blogs.technet.microsoft.com/kevinholman/2011/08/08/opsmgr-2012-what-should-the-spns-look-like/)>

## Issue - EXECUTE permission was denied on the object 'sp_help_jobactivity'

Log Name:      Operations Manager\
Source:        DataAccessLayer\
Date:          3/23/2017 9:21:50 AM\
Event ID:      33333\
Task Category: None\
Level:         Warning\
Keywords:      Classic\
User:          N/A\
Computer:      TT-SCOM03.corp.technologytoolbox.com\
Description:\
Data Access Layer rejected retry on SqlError:\
 Request: MaintenanceScheduleList -- (IsAdmin=True), (CurrentUser=TECHTOOLBOX\\jjameson-fabric), (RETURN_VALUE=1)\
 Class: 14\
 Number: 229\
 Message: The EXECUTE permission was denied on the object 'sp_help_jobactivity', database 'msdb', schema 'dbo'.

### Solution

---

**SQL Server Management Studio - TT-SQL01A**

#### -- Fix permissions for SCOM "Data Access Service" account

```SQL
USE msdb
GO
CREATE USER [TECHTOOLBOX\s-scom-das] FOR LOGIN [TECHTOOLBOX\s-scom-das]
GO
ALTER ROLE SQLAgentReaderRole ADD MEMBER [TECHTOOLBOX\s-scom-das]
GO
```

---

---

**SQL Server Management Studio - TT-SQL01B**

#### -- Fix permissions for SCOM "Data Access Service" account

```SQL
USE msdb
GO
CREATE USER [TECHTOOLBOX\s-scom-das] FOR LOGIN [TECHTOOLBOX\s-scom-das]
GO
ALTER ROLE SQLAgentReaderRole ADD MEMBER [TECHTOOLBOX\s-scom-das]
GO
```

---

### Reference

**Enabling Scheduled Maintenance in SCOM 2016 UR1**\
From <[https://blogs.technet.microsoft.com/kevinholman/2016/10/22/enabling-scheduled-maintenance-in-scom-2016-ur1/](https://blogs.technet.microsoft.com/kevinholman/2016/10/22/enabling-scheduled-maintenance-in-scom-2016-ur1/)>

## Enter product key for System Center Operations Manager

**To upgrade from the evaluation version of Operations Manager to a licensed version:**

1. On a management server, click **Start**, click **All Programs**, click **Microsoft System Center 2016**, and then run **Operations Manager Shell** as administrator.
2. In the **Operations Manager Command Shell**, type the following command:
3. Restart the System Center Data Access Service. You can use the Microsoft Management Console to restart services.
4. Restart the System Center Data Access Service on all management servers in the management group.

```PowerShell
    Set-SCOMLicense {license key}
```

### Reference

**How to Upgrade from the Evaluation Version of Operations Manager**\
From <[https://technet.microsoft.com/en-us/library/hh966734(v=sc.12).aspx](https://technet.microsoft.com/en-us/library/hh966734(v=sc.12).aspx)>

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

## Complete post-installation tasks

### Login as TECHTOOLBOX\\jjameson-admin

```PowerShell
cls
```

### # Remove System Center setup account from local Administrators group

```PowerShell
$localGroup = "Administrators"
$domain = "TECHTOOLBOX"
$serviceAccount = "setup-systemcenter"

([ADSI]"WinNT://./$localGroup,group").Remove(
    "WinNT://$domain/$serviceAccount,user")
```

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Disable setup account for System Center

```PowerShell
Disable-ADAccount -Identity setup-systemcenter
```

---

## Set Resolution State to Acknowledged for "noise" alerts

---

**FOOBAR16**

```PowerShell
cls
Import-Module -Name OperationsManager

$resolutionStateNew = 0
$resolutionStateAcknowledged = 249
```

#### # Source: DCOM

#### # Event ID: 10016

#### #

#### # Event Description: The application-specific permission settings do not grant Local Activation permission...

#### # to the user NT AUTHORITY\\SYSTEM SID (S-1-5-18)...

```PowerShell
Get-SCOMAlert `
    -ComputerName TT-SCOM03 `
    -ResolutionState $resolutionStateNew `
    -Name "System Event Log Error" |
    where { $_.Description.Contains("Source: DCOM") } |
    where { $_.Description.Contains("Event ID: 10016") } |
    where { $_.Description.Contains(
"Event Description: The application-specific permission settings do not grant Local Activation permission") } |
    where { $_.Description.Contains(
"to the user NT AUTHORITY\SYSTEM SID (S-1-5-18)") } |
    foreach {
        $alert = $_

        Set-SCOMAlert -Alert $alert -ResolutionState $resolutionStateAcknowledged
    }
```

#### # Source: Microsoft-Windows-CAPI2

#### # Event ID: 513

#### #

#### # Event Description: Cryptographic Services failed while processing the OnIdentity() call in the System Writer Object

#### # ...

#### # AddLegacyDriverFiles: Unable to back up image of binary Microsoft Link-Layer Discovery Protocol

#### #

#### # Reference: https://support.microsoft.com/en-us/help/3209092/event-id-513-when-running-vss-in-windows-server-2016

```PowerShell
Get-SCOMAlert `
    -ComputerName TT-SCOM03 `
    -ResolutionState $resolutionStateNew `
    -Name "Application Event Log Error" |
    where { $_.Description.Contains("Source: Microsoft-Windows-CAPI2") } |
    where { $_.Description.Contains("Event ID: 513") } |
    where { $_.Description.Contains(
"Event Description: Cryptographic Services failed while processing the OnIdentity() call in the System Writer Object.") } |
    where { $_.Description.Contains("AddLegacyDriverFiles: Unable to back up image of binary Microsoft Link-Layer Discovery Protocol.") } |
    foreach {
        $alert = $_

        Set-SCOMAlert -Alert $alert -ResolutionState $resolutionStateAcknowledged
    }
```

#### # Source: PerfNet

#### # Event ID: 2004

#### #

#### # Event Description: Unable to open the Server service performance object...

```PowerShell
Get-SCOMAlert `
    -ComputerName TT-SCOM03 `
    -ResolutionState $resolutionStateNew `
    -Name "Application Event Log Error" |
    where { $_.Description.Contains("Source: PerfNet") } |
    where { $_.Description.Contains("Event ID: 2004") } |
    where { $_.Description.Contains(
"Event Description: Unable to open the Server service performance object.") } |
    foreach {
        $alert = $_

        Set-SCOMAlert -Alert $alert -ResolutionState $resolutionStateAcknowledged
    }
```

#### # Source: Software Protection Platform Service

#### # Event ID: 8198

#### #

#### # Event Description: License Activation (slui.exe) failed with the following error code

```PowerShell
Get-SCOMAlert `
    -ComputerName TT-SCOM03 `
    -ResolutionState $resolutionStateNew `
    -Name "Application Event Log Error" |
    where { $_.Description.Contains("Source: Software Protection Platform Service") } |
    where { $_.Description.Contains("Event ID: 8198") } |
    where { $_.Description.Contains(
"Event Description: License Activation (slui.exe) failed with the following error code:") } |
    foreach {
        $alert = $_

        Set-SCOMAlert -Alert $alert -ResolutionState $resolutionStateAcknowledged
    }
```

#### # Source: Service Control Manager

#### # Event ID: 7023

#### #

#### # Event Description: The Data Sharing Service service terminated with the following error...

```PowerShell
Get-SCOMAlert `
    -ComputerName TT-SCOM03 `
    -ResolutionState $resolutionStateNew `
    -Name "System Event Log Error" |
    where { $_.Description.Contains("Source: Service Control Manager") } |
    where { $_.Description.Contains("Event ID: 7023") } |
    where { $_.Description.Contains(
"Event Description: The Data Sharing Service service terminated with the following error") } |
    foreach {
        $alert = $_

        Set-SCOMAlert -Alert $alert -ResolutionState $resolutionStateAcknowledged
    }
```

#### # Source: Microsoft-Windows-Defrag

#### # Event ID: 257

#### #

#### # Event Description: The volume ... was not optimized because an error was encountered

#### # This operation is not supported on this filesystem. (0x89000020)

```PowerShell
Get-SCOMAlert `
    -ComputerName TT-SCOM03 `
    -ResolutionState $resolutionStateNew `
    -Name "Application Event Log Error" |
    where { $_.Description.Contains("Source: Microsoft-Windows-Defrag") } |
    where { $_.Description.Contains("Event ID: 257") } |
    where { $_.Description.Contains(
"Event Description: The volume ") } |
    where { $_.Description.Contains(
"was not optimized because an error was encountered:") } |
    where { $_.Description.Contains(
"This operation is not supported on this filesystem. (0x89000020)") } |
    foreach {
        $alert = $_

        Set-SCOMAlert -Alert $alert -ResolutionState $resolutionStateAcknowledged
    }
```

#### # Source: Microsoft-Windows-Defrag

#### # Event ID: 257

#### #

#### # Event Description: The volume ... was not optimized because an error was encountered

#### # Neither Slab Consolidation nor Slab Analysis will run if slabs are less than 8 MB. (0x8900002D)

```PowerShell
Get-SCOMAlert `
    -ComputerName TT-SCOM03 `
    -ResolutionState $resolutionStateNew `
    -Name "Application Event Log Error" |
    where { $_.Description.Contains("Source: Microsoft-Windows-Defrag") } |
    where { $_.Description.Contains("Event ID: 257") } |
    where { $_.Description.Contains(
"Event Description: The volume ") } |
    where { $_.Description.Contains(
"was not optimized because an error was encountered:") } |
    where { $_.Description.Contains(
"Neither Slab Consolidation nor Slab Analysis will run if slabs are less than 8 MB. (0x8900002D)") } |
    foreach {
        $alert = $_

        Set-SCOMAlert -Alert $alert -ResolutionState $resolutionStateAcknowledged
    }
```

#### # Source: Microsoft-Windows-Defrag

#### # Event ID: 257

#### #

#### # Event Description: The volume ... was not optimized because an error was encountered

#### # The parameter is incorrect. (0x80070057)

```PowerShell
Get-SCOMAlert `
    -ComputerName TT-SCOM03 `
    -ResolutionState $resolutionStateNew `
    -Name "Application Event Log Error" |
    where { $_.Description.Contains("Source: Microsoft-Windows-Defrag") } |
    where { $_.Description.Contains("Event ID: 257") } |
    where { $_.Description.Contains(
"Event Description: The volume ") } |
    where { $_.Description.Contains(
"was not optimized because an error was encountered:") } |
    where { $_.Description.Contains(
"The parameter is incorrect. (0x80070057)") } |
    foreach {
        $alert = $_

        Set-SCOMAlert -Alert $alert -ResolutionState $resolutionStateAcknowledged
    }
```

#### # Source: MSSQLSERVER

#### # Event ID: 35262

#### #

#### # Event Description: Skipping the default startup of database '...' because the database belongs to

#### # an availability group

```PowerShell
Get-SCOMAlert `
    -ComputerName TT-SCOM03 `
    -ResolutionState $resolutionStateNew `
    -Name "Application Event Log Error" |
    where { $_.Description.Contains("Source: MSSQLSERVER") } |
    where { $_.Description.Contains("Event ID: 35262") } |
    where { $_.Description.Contains(
"Event Description: Skipping the default startup of database") } |
    where { $_.Description.Contains(
"because the database belongs to an availability group") } |
    foreach {
        $alert = $_

        Set-SCOMAlert -Alert $alert -ResolutionState $resolutionStateAcknowledged
    }
```

---

## Make virtual machine highly available

---

**TT-VMM01A**

```PowerShell
$vm = Get-SCVirtualMachine -Name "TT-SCOM03"
$vmHost = Get-SCVMHost -ComputerName "TT-HV02C.corp.technologytoolbox.com"

Move-SCVirtualMachine `
    -VM $vm `
    -VMHost $vmHost `
    -HighlyAvailable $true `
    -Path "\\TT-SOFS01.corp.technologytoolbox.com\VM-Storage-Silver" `
    -UseDiffDiskOptimization
```

---

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Move VM to new Production VM network

```PowerShell
$vmName = "TT-SCOM03"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Production VM Network"
$ipPool = Get-SCStaticIPAddressPool -Name "Production-15 Address Pool"

Stop-SCVirtualMachine $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -IPv4AddressType Dynamic

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -IPv4AddressPools $ipPool `
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
$vmName = "TT-SCOM03"
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

**TODO:**

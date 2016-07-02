# JUGGERNAUT - Windows Server 2012 R2 Standard

Friday, May 01, 2015
11:00 AM

---

**MOONSTAR**

### # Delete old VM

```PowerShell
Stop-SCVirtualMachine JUGGERNAUT

Remove-SCVirtualMachine JUGGERNAUT
```

---

## Create VM

- Processors: **2**
- Memory: **4 GB**
- VHD size (GB): **32**
- VHD file name:** JUGGERNAUT**

## Install custom Windows Server 2012 R2 image

- Start-up disk: [\\\\ICEMAN\\Products\\Microsoft\\MDT-Deploy-x86.iso](\\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso)
- On the **Task Sequence** step, select **Windows Server 2012 R2** and click **Next**.
- On the **Computer Details** step, in the **Computer name** box, type **JUGGERNAUT** and click **Next**.
- On the **Applications** step, click **Next**.

```PowerShell
cls
```

## # Set password for local Administrator account

```PowerShell
$adminUser = [ADSI] "WinNT://./Administrator,User"
$adminUser.SetPassword("{password}")
```

```PowerShell
cls
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

```PowerShell
cls
```

## # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

```PowerShell
cls
```

## # Mirror Toolbox content

```PowerShell
robocopy \\ICEMAN\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E /MIR
```

```PowerShell
cls
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

Set-NetAdapterAdvancedProperty `
    -Name "LAN 1 - 192.168.10.x" `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping ICEMAN -f -l 8900
```

## Configure VM storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 32 GB       | 4K                   | OSDisk       |
| 1    | D:           | 3 GB        | 64K                  | Data01       |
| 2    | L:           | 1 GB        | 64K                  | Log01        |
| 3    | T:           | 1 GB        | 64K                  | Temp01       |
| 4    | Z:           | 10 GB       | 4K                   | Backup01     |

---

**ICEMAN**

### # Create Data01, Log01, Temp01, and Backup01 VHDs

```PowerShell
$vmName = "JUGGERNAUT"

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName" `
    + "_Data01.vhdx"

New-VHD -Path $vhdPath -SizeBytes 3GB
Add-VMHardDiskDrive -VMName $vmName -ControllerType SCSI -Path $vhdPath

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName" `
    + "_Log01.vhdx"

New-VHD -Path $vhdPath -SizeBytes 1GB
Add-VMHardDiskDrive -VMName $vmName -ControllerType SCSI -Path $vhdPath

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName" `
    + "_Temp01.vhdx"

New-VHD -Path $vhdPath -SizeBytes 1GB
Add-VMHardDiskDrive -VMName $vmName -ControllerType SCSI -Path $vhdPath

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName" `
    + "_Backup01.vhdx"

New-VHD -Path $vhdPath -SizeBytes 10GB
Add-VMHardDiskDrive -VMName $vmName -ControllerType SCSI -Path $vhdPath
```

---

```PowerShell
cls
```

### # Format Data01 drive

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

### # Format Log01 drive

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

### # Format Temp01 drive

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

### # Format Backup01 drive

```PowerShell
Get-Disk 4 |
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -DriveLetter Z -UseMaximumSize |
    Format-Volume `
        -FileSystem NTFS `
        -NewFileSystemLabel "Backup01" `
        -Confirm:$false
```

## Create service accounts for SQL Server

---

**XAVIER1**

### # Create the SQL Server service account

```PowerShell
$displayName = "Service account for SQL Server"
$defaultUserName = "s-sql"

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

### # Create the service account for SQL Server Agent

```PowerShell
$displayName = "Service account for SQL Server Agent"
$defaultUserName = "s-sql-agent"

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

### # Create the service account for SQL Server Reporting Services

```PowerShell
$displayName = "Service account for SQL Server Reporting Services"
$defaultUserName = "s-sql-rs"

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

## # Install SQL Server 2012 with SP2

---

**ICEMAN**

### # Insert SQL Server 2012 ISO image into VM

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\SQL Server 2012" `
    + "\en_sql_server_2012_enterprise_edition_with_service_pack_2_x64_dvd_4685849.iso"

Set-VMDvdDrive -VMName JUGGERNAUT -Path $imagePath
```

---

```PowerShell
cls
```

### # Install SQL Server

```PowerShell
X:\setup.exe
```

**# Note: .NET Framework 3.5 is required for some SQL Server 2012 features (e.g. Reporting Services).**

On the **Feature Selection** step, select:

- **Database Engine Services**
- **Reporting Services - Native**.
- **Management Tools - Complete**.

On the **Server Configuration** step:

- For the **SQL Server Agent** service:
  - Change the **Account Name** to **TECHTOOLBOX\\s-sql-agent**.
  - Change the **Startup Type** to **Automatic**.
- For the **SQL Server Database Engine **service:
  - Change the **Account Name** to **TECHTOOLBOX\\s-sql**.
  - Ensure the **Startup Type** is set to **Automatic**.
- For the **SQL Server Reporting Services **service:
  - Change the **Account Name** to **TECHTOOLBOX\\s-sql-rs**.
  - Ensure the **Startup Type** is set to **Automatic**.
- For the **SQL Server Browser** service, ensure the **Startup Type** is set to **Disabled**.

On the **Database Engine Configuration** step:

- On the **Server Configuration** tab, in the **Specify SQL Server administrators** section, click **Add...** and then add the domain group for SQL Server administrators.
- On the **Data Directories** tab:
  - In the **Data root directory** box, type **D:\\Microsoft SQL Server\\**.
  - In the **User database log directory** box, change the drive letter to **L:** (the value should be **L:\\Microsoft SQL Server\\MSSQL11.MSSQLSERVER\\MSSQL\\Data**).
  - In the **Temp DB directory** box, change the drive letter to **T:** (the value should be **T:\\Microsoft SQL Server\\MSSQL11.MSSQLSERVER\\MSSQL\\Data**).
  - In the **Backup directory** box, change the drive letter to **Z:** (the value should be **Z:\\Microsoft SQL Server\\MSSQL11.MSSQLSERVER\\MSSQL\\Backup**).

## Fix permissions to avoid "ESENT" errors in event log

```Console
icacls C:\Windows\System32\LogFiles\Sum\Api.chk /grant "NT Service\MSSQLSERVER":(M)

icacls C:\Windows\System32\LogFiles\Sum\Api.log /grant "NT Service\MSSQLSERVER":(M)

icacls C:\Windows\System32\LogFiles\Sum\SystemIdentity.mdb /grant "NT Service\MSSQLSERVER":(M)
```

### Reference

**Error 1032 messages in the Application log in Windows Server 2012**\
Pasted from <[http://support.microsoft.com/kb/2811566](http://support.microsoft.com/kb/2811566)>

## -- Configure TempDB

```SQL
ALTER DATABASE [tempdb]
    MODIFY FILE
    (
        NAME = N'tempdev'
        , SIZE = 256MB
        , MAXSIZE = 512MB
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
        + ', SIZE = 256MB'
        + ', MAXSIZE = 512MB'
        + ', FILEGROWTH = 128MB'
    + ')';

EXEC sp_executesql @sqlStatement;

ALTER DATABASE [tempdb]
    MODIFY FILE (
        NAME = N'templog',
        SIZE = 25MB,
        FILEGROWTH = 25MB
    )
```

## Add passthrough disks

---

**ICEMAN**

### # Add SCSI controller for pass-through disks

```PowerShell
$vmName = "JUGGERNAUT"

Stop-VM $vmName

Add-VMScsiController $vmName

Start-VM $vmName
```

---

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A2/1B96AC5F13C6531D0A7EAC01616A8D02AA828AA2.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CE/B9D8027BBA5BC60748FAD23CED7C4ACBE51DB1CE.png)

## # Install Data Protection Manager 2012 R2

---

**ICEMAN**

### # Insert DPM ISO image into VM

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\System Center 2012 R2" `
    + "\mu_system_center_2012_r2_data_protection_manager_x86_and_x64_dvd_2945939.iso"

Set-VMDvdDrive -VMName JUGGERNAUT -Path $imagePath
```

---

```PowerShell
cls
```

### # Install DPM 2012 R2

```PowerShell
X:\SCDPM\setup.exe
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/63/7EFABEE6E4F28F3CA7C38959AB5B5C02C6948563.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8B/DE6E3530B2C2E5130BF43C4B39E6F689065D4C8B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/29/381CC1E9266D9B36CE9F57FCB4E86EC9E1645129.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2A/30C531601404FE3967253B54820B5C0C0E30D32A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/65/1C311042A065709D117DE001D4BDC29925586665.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/12/6A78E40D429056559E524B702ACE9C90ABD66212.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3F/7A027013B98FA582639904D2A59AADCA79BD983F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1B/DC78488C7E4BCEE3AF2541D28F39859FAD5BA31B.png)

Restart-Computer

#### # Restart DPM setup

```PowerShell
X:\SCDPM\setup.exe
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/63/7EFABEE6E4F28F3CA7C38959AB5B5C02C6948563.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2A/30C531601404FE3967253B54820B5C0C0E30D32A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/85/7F8087AD6F18281CFB89EC8E24B8BB54E2D62685.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CB/70A3D0C92772D1971E9EB9177B78E86800317ECB.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5F/95CFDF5EDDE13965626F9F4A70BC995DF0675F5F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/09/3F42CA470B96A6F1EEB3853CACFED584F28C5309.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/14/75CAE9A264379EB7FCFFC6E544BE8A26B1505414.png)

Click **Use Microsoft Update when I check for updates (recommended)** and then click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/21/E77B4A3E91F633E24A1D8E38791BD8159CA69321.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/56/0CC80049382DF7E5D1F9BDD35E127E246DD44556.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/53/94B43C0A84564056BEE284DAA61E71FED6239553.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9C/0B31DB8059F2B6CAC957B81DE2FAE625AB17889C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1E/93E89F87922D670ED333C826AAEE492CED034C1E.png)

```PowerShell
cls
```

## # Move log file for DPM database from D: to L

### # Stop the DPM service

```PowerShell
Stop-Service DPM
Stop-Service DpmWriter
```

### -- Detach the DPM database

```Console
USE [master]
GO
EXEC master.dbo.sp_detach_db @dbname = N'DPMDB_JUGGERNAUT'
GO
```

```Console
cls
```

### # Move the log file for the DPM database

```PowerShell
move "D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\MSDPM2012`$DPMDB_JUGGERNAUT_log.ldf" "L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data"
```

### -- Attach the DPM database

```Console
USE [master]
GO
CREATE DATABASE [DPMDB_JUGGERNAUT] ON
( FILENAME = N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\MSDPM2012$DPMDB_JUGGERNAUT.mdf' ),
( FILENAME = N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\MSDPM2012$DPMDB_JUGGERNAUT_log.ldf' )
 FOR ATTACH
GO
```

```Console
cls
```

### # Start the DPM services

```PowerShell
Start-Service DpmWriter
Start-Service DPM
```

## Configure database file growth

```SQL
ALTER DATABASE [DPMDB_JUGGERNAUT]
    MODIFY FILE (
        NAME = N'MSDPM2012$DPMDB_JUGGERNAUT_dat',
        FILEGROWTH = 100MB
    )

ALTER DATABASE [DPMDB_JUGGERNAUT]
    MODIFY FILE (
        NAME = N'MSDPM2012$DPMDB_JUGGERNAUTLog_dat',
        FILEGROWTH = 25MB
    )
```

## Configure SQL Server backup

```PowerShell
cls
```

### # Create maintenance plans to backup DPM database

```PowerShell
mkdir "Z:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\Full"
mkdir "Z:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\Differential"
mkdir "Z:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\Transaction Log"
```

#### Full backup of all databases

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D7/E9B4AD115094D24286E2FD4D91A834C611368CD7.png)

Right-click **Maintenance Plans** and click **Maintenance Plan Wizard**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9D/704A09951485E3C05368B69C36408A1420DCBF9D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F9/74A07343F5EC0ADF19DC60BD77C0DDCF10A501F9.png)

In the **Schedule** section, click **Change...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/61/A16C7EA6E06310367C400A27C32F2517D00F0261.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/21/4A303D282592167075123900B75E5B39270EE021.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/30/1F526D384BD3B5362991EB03D53045B846E90830.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1E/C0402F796985C4D2CA811B0898D5AD58A237D51E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4D/71FC6103F1C3048856E7DA098870A616A449794D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CA/10BCEA4758880B6AFB64B971921F2E4658A40DCA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/02/07BDB2BE0B0324752C5B3995E00DDFD3B1C54302.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E7/5BC4DF7D314C5FDB0F74C7EF2EFCEB75D9871EE7.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6A/D07DCA4A3853B9F2EDD91B4C207E2943E8F5E86A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3E/68EDCE3E0914FE79478DCC7DD8BC4D9ADAEA693E.png)

#### Differential backup of all databases

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BC/67A8AB130CE9E9303899B4E0D75E3D6D0BE1F4BC.png)

#### Transaction log backup of all databases

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0C/1804598D619F7D35A4C79C1ABB59348AD5189E0C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AE/7F261629A3F51D9F3A5B880CFDCD78F583EF47AE.png)

```PowerShell
cls
```

### # Create scheduled task to delete old database backups

```PowerShell
[string] $xml = Get-Content `
  'C:\NotBackedUp\Public\Toolbox\PowerShell\Remove Old Database Backups.xml'

Register-ScheduledTask -TaskName "Remove Old Database Backups" -Xml $xml
```

## Execute maintenance plan to backup all databases

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BF/9B47F071EC5BE2FE29D61CC65F21C4B0E05184BF.png)

Right-click **Full Backup of All Databases** and click **Execute**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AF/4A7B63AABFD12DD015D778C5CF536E8948EDBEAF.png)

## Configure DCOM permissions for SQL Server Integration Services

Log Name:      System\
Source:        Microsoft-Windows-DistributedCOM\
Date:          1/22/2014 5:18:02 AM\
Event ID:      10016\
Task Category: None\
Level:         Error\
Keywords:      Classic\
User:          TECHTOOLBOX\\svc-sql-agent\
Computer:      JUGGERNAUT.corp.technologytoolbox.com\
Description:\
The application-specific permission settings do not grant Local Activation permission for the COM Server application with CLSID\
{FDC3723D-1588-4BA3-92D4-42C430735D7D}\
 and APPID\
{83B33982-693D-4824-B42E-7196AE61BB05}\
 to the user TECHTOOLBOX\\svc-sql-agent SID (S-1-5-21-3914637029-2275272621-3670275343-4111) from address LocalHost (Using LRPC) running in the application container Unavailable SID (Unavailable). This security permission can be modified using the Component Services administrative tool.\
Event Xml:\
<Event xmlns="[http://schemas.microsoft.com/win/2004/08/events/event](http://schemas.microsoft.com/win/2004/08/events/event)">\
  `<System>`\
    `<Provider Name="Microsoft-Windows-DistributedCOM" Guid="{1B562E86-B7AA-4131-BADC-B6F3A001407E}" EventSourceName="DCOM" />`\
    `<EventID Qualifiers="0">`10016`</EventID>`\
    `<Version>`0`</Version>`\
    `<Level>`2`</Level>`\
    `<Task>`0`</Task>`\
    `<Opcode>`0`</Opcode>`\
    `<Keywords>`0x8080000000000000`</Keywords>`\
    `<TimeCreated SystemTime="2014-01-22T12:18:02.869192000Z" />`\
    `<EventRecordID>`11632`</EventRecordID>`\
    `<Correlation />`\
    `<Execution ProcessID="788" ThreadID="4364" />`\
    `<Channel>`System`</Channel>`\
    `<Computer>`JUGGERNAUT.corp.technologytoolbox.com`</Computer>`\
    `<Security UserID="S-1-5-21-3914637029-2275272621-3670275343-4111" />`\
  `</System>`\
  `<EventData>`\
    `<Data Name="param1">`application-specific`</Data>`\
    `<Data Name="param2">`Local`</Data>`\
    `<Data Name="param3">`Activation`</Data>`\
    `<Data Name="param4">`{FDC3723D-1588-4BA3-92D4-42C430735D7D}`</Data>`\
    `<Data Name="param5">`{83B33982-693D-4824-B42E-7196AE61BB05}`</Data>`\
    `<Data Name="param6">`TECHTOOLBOX`</Data>`\
    `<Data Name="param7">`svc-sql-agent`</Data>`\
    `<Data Name="param8">`S-1-5-21-3914637029-2275272621-3670275343-4111`</Data>`\
    `<Data Name="param9">`LocalHost (Using LRPC)`</Data>`\
    `<Data Name="param10">`Unavailable`</Data>`\
    `<Data Name="param11">`Unavailable`</Data>`\
  `</EventData>`\
`</Event>`

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F6/A5C0C95ECE956FF1DBD7B82E9F7AD8DC49CB32F6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0C/7869E60C98C8F6102EFEEC5491788C50A966A60C.png)

Right-click **Microsoft SQL Server Integration Services 11.0** and click **Properties**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BA/7E91310C21AA0F6678F9242B63F707EC0C5FB0BA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/98/8B79030112E2E5FA5090E791619AD565D29E7298.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BE/3326BBC133CD87323E4290F6F20C042A85D903BE.png)

## Choose customer feedback option

**To choose the feedback option:**

1. In DPM Administrator Console, click **Management**, and then click **Options** on the tool ribbon.
2. In the **Options** window, on the **Customer Feedback** tab, select the **No, thank you** option and then  **OK**.

## Online disks using Disk Management

## Add disks to the storage pool

**To add disks to the storage pool**

1. In DPM Administrator Console, click **Management**, and then click the **Disks**.
2. Click **Add** on the tool ribbon.
The **Add Disks to Storage Pool** dialog box appears. The **Available disks** section lists the disks that you can add to the storage pool.
3. Select one or more disks, click **Add**, and then click **OK**.

Pasted from <[http://technet.microsoft.com/en-us/library/hh758075.aspx](http://technet.microsoft.com/en-us/library/hh758075.aspx)>

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F8/60A7255DCC366A5070F548C4A53A56FDE47E89F8.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/69/836DB2405E1EB4E309DEE07BDFEEC3343406AB69.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A7/34291F5B50DA9F7B4C582EC81B82DA850BC587A7.png)

## Create protection group for domain controllers

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6C/D50A7E4B18D2699A59B49E264192A1CAB904C26C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A2/EFF77FE2E5CA3B209B6E83F6D696FF3E3DEDCBA2.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/50/3F51BEA0EA802266085D669BEA89C8D9E59E8E50.png)

Ensure **Servers** is selected and then click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4F/841E0BDC6767C52778A84543B80F201D7A42B14F.png)

Expand **XAVIER1**, then expand **System Protection**, and then select **System State (includes Active Directory)**.

Repeat the previous step for **XAVIER2**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/95/7C7D44231A73401CD4B9D24D4C3091D8424F0095.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BA/D5019D1C8AC66E92C69D1F8DA6D622ADE5D4D9BA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/12/A14F746A6B28C591470060A1BD4226ACD925C012.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/59/F57922125AFC4F537FC951C66E202DCD7FE0DA59.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3E/5E0AFA8E57FE56504343946A999BC3828101D93E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/71/BC9252CFA985190E441186D77D15E1D23BECB471.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7B/1DCDCFD257422CE8883060A446E3AAA594B58B7B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6C/A3CC4EF8DCE5180229796A1E57E25C58C96C916C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8B/3432627B9914BD277FD59CBE8F0C38E4428FC28B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B1/EABDD9A4BA24BA197245967B561123E1976495B1.png)

## Create protection group - SQL Server Databases (TEST)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7B/567D0E550D174A218C8DA8F7381DE572838AB27B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A2/EFF77FE2E5CA3B209B6E83F6D696FF3E3DEDCBA2.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/50/3F51BEA0EA802266085D669BEA89C8D9E59E8E50.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C3/B4ED007234F0DC68E0D31CF08542DDE7107308C3.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E3/2F96840A22EC87B12E84C845A72D3E27D67669E3.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C6/6D9BDD3FCCBEEEDD9EF72415F6CC6C62C254BDC6.png)

For **Retention range**, specify **10 days**.

For **Synchronization frequency**, specify **Every 4 hour(s)**.

In the **Application recovery points** section, click **Modify...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/93/6F5A1356875129FAA4F41946C496F6BD85515693.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/63/DDB13B4A9C9D68A6EC154CAA3411B64F17320D63.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B7/8D6C7C4C144628266046FB701B88C9D4232FF1B7.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AF/E43A61CC7641FB168A6960B8C142C0C91456B6AF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7B/1DCDCFD257422CE8883060A446E3AAA594B58B7B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EB/7645163BA736F36A9B198B870169F0D0490BD0EB.png)

### Add "Local System" account to SQL Server sysadmin role

On the SQL Server (HAVOK-TEST), open SQL Server Management Studio and execute the following:

```SQL
ALTER SERVER ROLE [sysadmin] ADD MEMBER [NT AUTHORITY\SYSTEM]
GO
```

#### Reference

**Protection agent jobs may fail for SQL Server 2012 databases**\
Pasted from <[http://technet.microsoft.com/en-us/library/dn281948.aspx](http://technet.microsoft.com/en-us/library/dn281948.aspx)>

## Create protection group - SQL Server Databases

![(screenshot)](https://assets.technologytoolbox.com/screenshots/38/9BC59C1C391D5D48BCFA2EB51134E8E9BB6B5238.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A2/EFF77FE2E5CA3B209B6E83F6D696FF3E3DEDCBA2.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/50/3F51BEA0EA802266085D669BEA89C8D9E59E8E50.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A1/443F05F34224FB26CD3B86724479AE3C400D0DA1.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E6/E426960C766486E132D5DAD22441ABDD9F2714E6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9C/415C5EFE264CA38E1FA96744127C1FF1EC88169C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FB/DA15FC4273A0CB46CC35AA4A6BCF592266488AFB.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C9/9DE474F2EA6D63FBC83E38F4DE9E5AA67ABD7EC9.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7B/1DCDCFD257422CE8883060A446E3AAA594B58B7B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A8/C971848B2DB9892A765BB551A669704DD45855A8.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1F/1E4820C0182D65FEF71918748029FFE07C72031F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A9/0061E9550C33C86432F6A42F3770698DFDD2EBA9.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/76/AD25EC02939628E5F522E4DB212D9EE597818076.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1A/F6C3A482DAE8C68EEAEA6F00E19449551506B71A.png)

## Create protection group - Critical Files

Protection group name: **Critical Files**\
Retention range: **10 days**\
Synchronization frequency: **Just before a recovery point**\
File recovery points:

- Recovery points for files: **7:00 AM, 12:00 PM, 5:00 PM Everyday**

## Create protection group for Hyper-V

Protection group name: **Hyper-V**\
Retention range: **5 days**\
Application recovery points:

- Express Full Backup: **11:00 PM Everyday**

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

## # Install SCOM agent

```PowerShell
$imagePath = '\\ICEMAN\Products\Microsoft\System Center 2012 R2' `
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

## Resolve issues when connecting to SQL Server from FOOBAR8

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7C/A66B46FA9283C6626D58AAEC2FE1AD2EB85F5B7C.png)

### # Configure firewall rule for SQL Server Database Engine

```PowerShell
New-NetFirewallRule `
    -Name "SQL Server Database Engine" `
    -DisplayName "SQL Server Database Engine" `
    -Group 'Technology Toolbox (Custom)' `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 1433 `
    -Action Allow
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0E/412EF6ECCB80BC99BF7FD314DE306FB12818990E.png)

### Reference

**How to troubleshoot the "Cannot generate SSPI context" error message**\
From <[https://support.microsoft.com/en-us/kb/811889](https://support.microsoft.com/en-us/kb/811889)>

### # Fix SPNs for SQL Server instance (running as TECHTOOLBOX\\s-sql)

```PowerShell
setspn -D MSSQLSvc/JUGGERNAUT.corp.technologytoolbox.com JUGGERNAUT
setspn -D MSSQLSvc/JUGGERNAUT.corp.technologytoolbox.com:1433 JUGGERNAUT

setspn -S MSSQLSvc/JUGGERNAUT.corp.technologytoolbox.com s-sql
setspn -S MSSQLSvc/JUGGERNAUT.corp.technologytoolbox.com:1433 s-sql
```

## # Expand Z: (Backup01) drive

---

```PowerShell
Enter-PSSession ICEMAN
```

### # Increase the size of "Backup01" VHD

```PowerShell
$vmName = "JUGGERNAUT"

Resize-VHD `
    ("C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
        + $vmName + "_Backup01.vhdx") `
    -SizeBytes 13GB

Exit-PSSession
```

---

### # Extend partition

```PowerShell
$size = (Get-PartitionSupportedSize -DiskNumber 4 -PartitionNumber 1)
Resize-Partition -DiskNumber 4 -PartitionNumber 1 -Size $size.SizeMax
```

## # Configure firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

---

**FOOBAR8**

```PowerShell
$computer = 'JUGGERNAUT'

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

$scriptBlock = [scriptblock]::Create($command)

Invoke-Command -ComputerName $computer -ScriptBlock $scriptBlock
```

---

## Configure SMTP server for DPM

### Configure spam filter in Office 365

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F5/09FEF23706EA73B094C68CD75E08DEDC2FDCEFF5.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/24/9957ADC6F7B4F58B9BE77304D1EA2F084F16A424.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/31/5ED7F2CE8F519924C92C61C0E3E17F6613ADEC31.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/69/7267C9530745145BE7CAF41FAF09A40102F55D69.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F7/DA5991FA2272153F9F786460CECDFD202E6C02F7.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0A/81CEF0E05B62EE1B9540BB58BB24FB837527020A.png)

### Configure SMTP server in DPM

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9A/16A95681615397E1BCC3DE4515BAFA174F818F9A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/31/6BB81B8253EA516A71622351DB6A4E8645BB8531.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5F/3103236B64CFC4BC20F0B2D2C83EA1B72D0E4F5F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A3/4AB6E7B339816FD971724CD70E70D8A5CB6D82A3.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/14/32238B5F055108C004AB9CB09C9105338B1FF314.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/96/C3B8E90C6EED5067D2D2F1A1E82A10293527A296.png)

## Set up protection for live migration

### Reference

**Set up protection for live migration**\
From <[https://technet.microsoft.com/en-us/library/jj656643.aspx](https://technet.microsoft.com/en-us/library/jj656643.aspx)>

```PowerShell
cls
```

### # Install the VMM console

```PowerShell
$imagePath = '\\iceman\Products\Microsoft\System Center 2012 R2' `
    + '\mu_system_center_2012_r2_virtual_machine_manager_x86_and_x64_dvd_2913737.iso'

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

& ($imageDriveLetter + ":\Setup.exe")
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/62/60997802DE1D0243391A2FA44927FF7E3F160962.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BE/EB8E82E613AB6B5A91576F47E0C3F1048C7715BE.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/55/63C2F0563CD8ABFE0BD9A12AFB1D3A360673C355.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7B/E25157D8EDCFD7C7327880EDEC8B42FF7AA05A7B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D1/6782996D0CAA170F9A8FCB15AC2EAA6C6BDC4DD1.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/57/E403C040F0A39BEB1AB21A73D8D9454659E26957.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BE/85B51E633CFD2CE08467D8E30EDA1B7E4E1B58BE.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B9/E46B9AE2A518B3DA86EF87F29441793B3D815EB9.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/71/87A63FE2C78E00997B6628916CDB1F9E509BD971.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/47/17E8A97F5BD18071E9AFF932338A8FC175249047.png)

### Update VMM using Windows Update

**Update Rollup 9 for Microsoft System Center 2012 R2 - Virtual Machine Manager (KB3129783)**

### Add DPM machine account as Read-Only Administrator in VMM

**How to Create a Read-Only Administrator User Role in VMM**\
From <[https://technet.microsoft.com/en-us/library/hh356036.aspx](https://technet.microsoft.com/en-us/library/hh356036.aspx)>

---

**FOOBAR8**

1. Open **Virtual Machine Manager**.
2. In the **Settings** workspace, on the **Home** tab in the **Create** group, click **Create User Role**.
3. In the **Create User Role Wizard**:
   1. On the **Name and description** page, in the **Name** box, type **DPM Servers** and click **Next**.
   2. On the **Profile** page, select **Read-Only Administrator** and then click **Next**.
   3. On the **Members** page, click **Add** to add **TECHTOOLBOX\\JUGGERNAUT\$** to the user role with the **Select Users, Computers, or Groups** dialog box. After you have added the members, click **Next**.
   4. On the **Scope** page, select **All Hosts** and click **Next**.
   5. On the **Library servers** page, click **Next**.
   6. On the **Run As accounts** page, click **Next**.
   7. On the **Summary** page, review the settings you have entered and then click **Finish** to create the Read-Only Administrator user role.

---

```PowerShell
cls
```

### # Connect DPM server to VMM server

```PowerShell
Set-DPMGlobalProperty -DPMServerName JUGGERNAUT -KnownVMMServers MOONSTAR
```

## # Expand Z: (Backup01) drive

---

**FOOBAR8**

### # Expand VHD

```PowerShell
$vmHost = "ICEMAN"
$vmName = "JUGGERNAUT"

Resize-VHD `
    -ComputerName $vmHost `
    -Path ("C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
        + $vmName + "_Backup01.vhdx") `
    -SizeBytes 20GB
```

---

### # Extend partition

```PowerShell
$size = (Get-PartitionSupportedSize -DiskNumber 4 -PartitionNumber 1)
Resize-Partition -DiskNumber 4 -PartitionNumber 1 -Size $size.SizeMax
```

## Issue: Cannot connect to DPM Reporting from FOOBAR8

### # Solution: Configure firewall rule for SQL Server Reporting Services

```PowerShell
New-NetFirewallRule `
    -Name "SQL Server Reporting Services" `
    -DisplayName "SQL Server Reporting Services" `
    -Group 'Technology Toolbox (Custom)' `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 80 `
    -Action Allow
```

## # Clean up WinSxS folder

```PowerShell
Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase
```

## # Expand C: (OSDisk) drive

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5D/F8A57B596C9C1E8B5051E696CCFC997627D3CF5D.png)

Screen clipping taken: 6/27/2016 1:31 PM

---

**FOOBAR8**

### # Expand VHD

```PowerShell
$vmHost = "FORGE"
$vmName = "JUGGERNAUT"

Resize-VHD `
    -ComputerName $vmHost `
    -Path ("E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
        + $vmName + ".vhdx") `
    -SizeBytes 34GB
```

#### Issue

```PowerShell
Resize-VHD : Failed to resize the virtual disk.
The system failed to resize 'E:\NotBackedUp\VMs\JUGGERNAUT\Virtual Hard Disks\JUGGERNAUT.vhdx'.
The operation is not supported.
At line:1 char:1
+ Resize-VHD `
+ ~~~~~~~~~~~~
    + CategoryInfo          : NotImplemented: (Microsoft.Hyper...l.VMStorageTask:VMStorageTask) [Resize-VHD], VirtualizationOperationFailedException
    + FullyQualifiedErrorId : NotSupported,Microsoft.Vhd.PowerShell.ResizeVhdCommand
```

#### Workaround

```PowerShell
cls
Stop-VM -ComputerName $vmHost -Name $vmName

Resize-VHD `
    -ComputerName $vmHost `
    -Path ("E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
        + $vmName + ".vhdx") `
    -SizeBytes 34GB

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### # Extend partition

```PowerShell
$size = (Get-PartitionSupportedSize -DiskNumber 1 -PartitionNumber 1)
Resize-Partition -DiskNumber 1 -PartitionNumber 1 -Size $size.SizeMax
```

#### Issue

```PowerShell
Resize-Partition : Size Not Supported
At line:1 char:1
+ Resize-Partition -DiskNumber 1 -PartitionNumber 1 -Size $size.SizeMax
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (StorageWMI:ROOT/Microsoft/.../MSFT_Partition) [Resize-Partition], CimException
    + FullyQualifiedErrorId : StorageWMI 4097,Resize-Partition
```

#### Workaround

Extend volume using **Disk Management** console.

## Issue: Low disk space for backups

---

**FOOBAR8**

### # Shutdown VM

```PowerShell
$vmName = "JUGGERNAUT"
$oldVmHost = "FORGE"

Stop-VM -ComputerName $oldVmHost -Name $vmName
```

### Remove pass-through disks

```PowerShell
cls
```

### # Move VM from FORGE to BEAST

```PowerShell
$newVmHost = "BEAST"

Move-VM `
    -ComputerName $oldVmHost `
    -Name $vmName `
    -DestinationHost $newVmHost `
    -IncludeStorage `
    -DestinationStoragePath E:\NotBackedUp\VMs\$vmHName
```

### Add pass-through disks

```PowerShell
cls
```

### # Start VM

```PowerShell
Start-VM -ComputerName $newVmHost -Name $vmName
```

---

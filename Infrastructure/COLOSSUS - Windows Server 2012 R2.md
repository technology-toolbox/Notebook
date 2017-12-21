# COLOSSUS - Windows Server 2012 R2

Monday, May 18, 2015
7:42 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Create service account for WSUS

---

**XAVIER1**

### # Create the WSUS service account

```PowerShell
$displayName = "Service account for Windows Server Update Services"
$defaultUserName = "s-wsus"

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

## Create VM

- Processors: **2**
- Memory: **2 GB**
- VHD size (GB): **32**
- VHD file name:** COLOSSUS**

## Install custom Windows Server 2012 R2 image

- Start-up disk: [\\\\ICEMAN\\Products\\Microsoft\\MDT-Deploy-x86.iso](\\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso)
- On the **Task Sequence** step, select **Windows Server 2012 R2** and click **Next**.
- On the **Computer Details** step, in the **Computer name** box, type **COLOSSUS** and click **Next**.
- On the **Applications** step, do not select any applications, and click **Next**.

```PowerShell
cls
```

## # Set password for local Administrator account

```PowerShell
$adminUser = [ADSI] "WinNT://./Administrator,User"
$adminUser.SetPassword("{password}")
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

## Create share for WSUS content

---

**ICEMAN**

### # Create and share the WSUS\$ folder

```PowerShell
New-Item -Path D:\Shares\WSUS$ -ItemType Directory

New-SmbShare `
    -Name WSUS$ `
    -Path D:\Shares\WSUS$ `
    -CachingMode None `
    -ChangeAccess Everyone
```

#### # Remove "BUILTIN\\Users" permissions

```PowerShell
icacls D:\Shares\WSUS$ /inheritance:d
icacls D:\Shares\WSUS$ /remove:g "BUILTIN\Users"
```

#### # Grant COLOSSUS computer account modify access to WSUS share

```PowerShell
icacls D:\Shares\WSUS$ /grant 'COLOSSUS$:(OI)(CI)(M)'
```

#### # Grant WSUS service account read access to WSUS share

```PowerShell
icacls D:\Shares\WSUS$ /grant 'TECHTOOLBOX\s-wsus:(OI)(CI)(RX)'
```

---

## Install WSUS

![(screenshot)](https://assets.technologytoolbox.com/screenshots/30/95F18511CC7247AEBFB056D86C056311CDF89630.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/86/FB846A250D3906A80B6BCADC82439502C78B2186.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/57/DECAEA9056214F80ED23DAC35925BD48E9DFED57.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DB/6A839CBEFF04B4FE038EAC4BA699F2F44B5520DB.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B7/E46D8D9A779C378B7EC40C8FC9D7CFE8F7C85AB7.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/94/9A7204B4F1488D1F20747C3E64D592EEF2A42A94.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B0/BC7F47D96B2DED1BF4D3F703154465A103A903B0.png)

**Note:** .NET Framework 3.5 is already installed (included in custom Windows Server 2012 R2 image).

On the **Select features** page, click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DF/781FD98779CB611006D70034D4B17E9D3600CADF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8B/E6B3E7FD06A9E6A2DE52ED909516A038D387448B.png)

Clear the **WID Database **checkbox.\
Select the **Database** checkbox.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/37/4031BD06C91AD9D04DD3FE77EC08F208E0076D37.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C0/ADAC9E5EABE0C38CABC84C3AB0BD6783FB102FC0.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/11/793C28119EA24D9C8B75E86F84B539E02AD3D611.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F9/893AECD7B5782ED39B42DD634F51A07BB4638CF9.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/07/F7E386A0BAA49CF684B929FE7588E5D7329D0307.png)

On the **Select role services** page, click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/69/28D8EFE93FB36C2BE75486B650BCB4197FD27C69.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/94/70FF3874946F7CA61DC5B64697E2BBF80B9BFA94.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D3/0EA9AF84E2C83C1FE047915A090E9E0E288312D3.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/81/EC07ED853599E824AEEB5363DD10B7A36CCA1981.png)

Click **Launch Post-Installation tasks** to create the SUSDB database.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DE/A31230FF3E7F9339EB766A3E052175AF600D8DDE.png)

Wait for the configuration to complete.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DD/D8C5E2F705807CCB65951C7D199EBDE8075D76DD.png)

Configure WSUS database

Change auto-grow increment on SUSDB.mdf from 1 MB to 100 MB

## Configure WSUS

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A3/55029C1D2D40D052E79CB46843ED9509880256A3.png)

Right-click the WSUS server (**COLOSSUS**) and then click **Windows Server Update Services**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BF/59B523B58BAF38759E98CA89C95C8BC30CFB84BF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E1/79101F1DB298E5A71D7371D6D52F96906D6E23E1.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E9/6121955B47BDDD0DAB599829053D458284B86EE9.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7E/262435F7E3B602FB5C7A27B4A5101F2C65EB067E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AB/D1D866E3C28877F7ABF202EC205E217BFE586AAB.png)

Click **Start Connecting**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9E/8B6EEFB602732113E850408CF6E22F8944E9699E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5A/49C645116CACA18DB33D04C3F49D6B2951B4265A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/49/5A3A5F19A77F8FE68071F7166D9B348C73204649.png)

- Microsoft
  - Developer Tools, Runtimes, and Redistributables
    - Visual Studio 2010
    - Visual Studio 2012
    - Visual Studio 2013
  - Expression
    - Expression Design 4
    - Expression Web 4
  - Office
  - Silverlight
  - SQL Server
  - System Center
    - System Center 2012 R2 - Data Protection Manager
    - System Center 2012 R2 - Operations Manager
    - System Center 2012 R2 - Virtual Machine Manager
  - Windows

![(screenshot)](https://assets.technologytoolbox.com/screenshots/37/372FF0C6359D82EF6FF36E118CADD1024F6E8837.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3E/75DA8705948A2A9DCCED07E493A3A33B1F36C33E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C3/D387144AB751593511B9A78CAAB1D264168EF5C3.png)

Select **Begin initial synchronization** and then click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3F/FF3B78505B859800A50E68D1C4D807B58970083F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/69/C2ED7EF76661D9D8F560C4B789BB83208296D369.png)

## Fix path for "Content" virtual directory

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E8/89D2BA3C12018E4D5D803D92766E367ABB5364E8.png)

```PowerShell
Import-Module WebAdministration

Set-ItemProperty `
    "IIS:\Sites\WSUS Administration\Content" `
    -Name physicalPath `
    -Value "\\ICEMAN\WSUS$\WsusContent\"
```

## # Set credentials for accessing WSUS content on ICEMAN

```PowerShell
$displayName = "Service account for Windows Server Update Services"
$defaultUserName = "TECHTOOLBOX\s-wsus"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$password = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR(
        $cred.Password))

Set-ItemProperty `
    "IIS:\Sites\WSUS Administration\Content" `
    -Name userName `
    -Value $cred.UserName

Set-ItemProperty `
    "IIS:\Sites\WSUS Administration\Content" `
    -Name password `
    -Value $password
```

## Configure group policy for Windows Update

![(screenshot)](https://assets.technologytoolbox.com/screenshots/05/4F75EE5CAEDF7E8EFB10F970F7B2301F4CB07905.png)

## Add computer groups

Computers

- All Computers
  - Unassigned Computers
  - .**NET Framework 3.5**
  - **.NET Framework 4**
  - **.NET Framework 4 Client Profile**
  - **.NET Framework 4.5**
  - **Fabrikam**
    - **Fabrikam - Development**
    - **Fabrikam - Quality Assurance**
      - **Fabrikam - Beta Testing**
  - **Internet Explorer 10**
  - **Internet Explorer 11**
  - **Internet Explorer 7**
  - **Internet Explorer 8**
  - **Internet Explorer 9**
  - **Silverlight**
  - **Technology Toolbox**
    - **Development**
    - **Quality Assurance**
      - **Beta Testing**
    - **WSUS Servers**

1. In the **Update Services** console, in the navigation pane, expand **Computers**, and then select **All Computers**.
2. In the **Actions** pane, click **Add Computer Group...**
3. In the **Add Computer Group** window, in the **Name** box, type the name for the new computer group and click **OK**.

Configure automatic approval rules

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C5/8802A21A02AE3A0F8F9E06A10EEE7D1EC50BDCC5.png)

1. In the **Automatic Approvals** window, on the **Update Rules** tab, select **Default Automatic Approval Rule**.
2. In the **Rule properties** section, click **Critical Updates, Security Updates**.
3. In the **Choose Update Classifications** window:
   1. Select **Definition Updates**.
   2. Clear the checkboxes for all other update classifications.
   3. Click** OK**.
4. Confirm the **Rule properties** for the **Default Automatic Approval Rule** are configured as follows:**When an update is in Definition UpdatesApprove the update for all computers**
5. Select the **Default Automatic Approval Rule** checkbox.
6. Click **New Rule...**
7. In the **Add Rule** window:
   1. In the **Step 1: Select properties** section, select** When an update is in a specific classification**.
   2. In the **Step 2: Edit the properties** section:
      1. Click **any classification**.
         1. In the **Choose Update Classifications **window:
            1. Clear the **All Classifications **checkbox.
            2. Select the following checkboxes:
               - **Critical Updates**
               - **Security Updates**
         2. Click **OK**.
      2. Click **all computers**
         1. In the **Choose Computer Groups** window:
            1. Clear the **All Computers** checkbox.
            2. Select the following checkboxes:
               - **Fabrikam / Fabrikam - Quality Assurance / Fabrikam - Beta Testing**
               - **Technology Toolbox / Quality Assurance / Beta Testing**
         2. Click **OK**.
   3. In the **Step 3: Specify a name **box, type **Beta Testing Approval Rule**.
   4. Click **OK**.
8. In the **Automatic Approvals** window:
   1. Confirm the **Rule properties** for the **Beta Testing Approval Rule** are configured as follows:**When an update is in Critical Updates, Security UpdatesApprove the update for Fabrikam - Beta Testing, Beta Testing**
   2. Click **OK**.

## Install Report Viewer 2008 SP1

**Note: **.NET Framework 2.0 is required for Microsoft Report Viewer 2008 SP1.

```PowerShell
& '\\ICEMAN\Public\Download\Microsoft\Report Viewer 2008 SP1\ReportViewer.exe'
```

## Import scheduled task to cleanup WSUS

"C:\\NotBackedUp\\Public\\Toolbox\\WSUS\\WSUS Server Cleanup.xml"

## Create SQL job for WSUS database maintenance

Name: **WsusDBMaintenance**\
Steps:

- Step 1
  - Step name: **Defragment database and update statistics**
  - Type: **Transact-SQL script (T-SQL)**
  - Command: (click **Open...** and then select script - **"C:\\NotBackedUp\\Public\\Toolbox\\WSUS\\WsusDBMaintenance.sql"**)
  - Database: **SUSDB**\
    Schedule:

- Schedule 1
  - Name: **Weekly**
  - Frequency:
    - Occurs: **Weekly**
    - Recurs every: **1 week on Sunday**
  - Daily frequency:
    - Occurs once at: **10:00 AM**

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

## # Configure firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

---

**FOOBAR8**

```PowerShell
$computer = 'COLOSSUS'

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

$scriptBlock = [ScriptBlock]::Create($command)

Invoke-Command -ComputerName $computer -ScriptBlock $scriptBlock
```

---

## Issue: Windows Update (KB3159706) broke WSUS console

### Issue

WSUS clients started failing with error 0x8024401C

Attempting to open WSUS console generated errors, which led to the discovery of the following errors in the event log:

Log Name:      Application\
Source:        Windows Server Update Services\
Date:          5/13/2016 8:39:56 AM\
Event ID:      507\
Task Category: 1\
Level:         Error\
Keywords:      Classic\
User:          N/A\
Computer:      COLOSSUS.corp.technologytoolbox.com\
Description:\
Update Services failed its initialization and stopped.

Log Name:      System\
Source:        Service Control Manager\
Date:          5/13/2016 8:39:56 AM\
Event ID:      7031\
Task Category: None\
Level:         Error\
Keywords:      Classic\
User:          N/A\
Computer:      COLOSSUS.corp.technologytoolbox.com\
Description:\
The WSUS Service service terminated unexpectedly.  It has done this 1 time(s).  The following corrective action will be taken in 300000 milliseconds: Restart the service.

### References

**Update enables ESD decryption provision in WSUS in Windows Server 2012 and Windows Server 2012 R2**\
From <[https://support.microsoft.com/en-us/kb/3159706](https://support.microsoft.com/en-us/kb/3159706)>

**The long-term fix for KB3148812 issues**\
From <[https://blogs.technet.microsoft.com/wsus/2016/05/05/the-long-term-fix-for-kb3148812-issues/](https://blogs.technet.microsoft.com/wsus/2016/05/05/the-long-term-fix-for-kb3148812-issues/)>

### Solution

Manual steps required to complete the installation of this update

1. Open an elevated Command Prompt window, and then run the following command (case sensitive, assume "C" as the system volume):
"C:\\Program Files\\Update Services\\Tools\\wsusutil.exe" postinstall /servicing
2. Select **HTTP Activation **under **.NET Framework 4.5 Features** in the Server Manager Add Roles and Features wizard.
3. Restart the WSUS service.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7D/06E6407CAFFDA2F33739002CABD4137317C46E7D.jpg)

From <[https://support.microsoft.com/en-us/kb/3159706](https://support.microsoft.com/en-us/kb/3159706)>

## Issue - WSUS errors due to insufficient memory

Log Name:      Application\
Source:        System.ServiceModel 4.0.0.0\
Date:          5/14/2016 5:49:18 AM\
Event ID:      3\
Task Category: WebHost\
Level:         Error\
Keywords:      Classic\
User:          NETWORK SERVICE\
Computer:      COLOSSUS.corp.technologytoolbox.com\
Description:\
WebHost failed to process a request.\
 Sender Information: System.ServiceModel.ServiceHostingEnvironment+HostingManager/6044116\
 Exception: System.ServiceModel.ServiceActivationException: The service '/ClientWebService/client.asmx' cannot be activated due to an exception during compilation.  The exception message is: Memory gates checking failed because the free memory (78831616 bytes) is less than 5% of total memory.  As a result, the service will not be available for incoming requests.  To resolve this, either reduce the load on the machine or adjust the value of minFreeMemoryPercentageToActivateService on the serviceHostingEnvironment config element.. ---> System.InsufficientMemoryException: Memory gates checking failed because the free memory (78831616 bytes) is less than 5% of total memory.  As a result, the service will not be available for incoming requests.  To resolve this, either reduce the load on the machine or adjust the value of minFreeMemoryPercentageToActivateService on the serviceHostingEnvironment config element.\
   at System.ServiceModel.Activation.ServiceMemoryGates.Check(Int32 minFreeMemoryPercentage, Boolean throwOnLowMemory, UInt64& availableMemoryBytes)\
   at System.ServiceModel.ServiceHostingEnvironment.HostingManager.CheckMemoryCloseIdleServices(EventTraceActivity eventTraceActivity)\
   at System.ServiceModel.ServiceHostingEnvironment.HostingManager.EnsureServiceAvailable(String normalizedVirtualPath, EventTraceActivity eventTraceActivity)\
   --- End of inner exception stack trace ---\
   at System.ServiceModel.ServiceHostingEnvironment.HostingManager.EnsureServiceAvailable(String normalizedVirtualPath, EventTraceActivity eventTraceActivity)\
   at System.ServiceModel.ServiceHostingEnvironment.EnsureServiceAvailableFast(String relativeVirtualPath, EventTraceActivity eventTraceActivity)\
 Process Name: w3wp\
 Process ID: 3668

### Solution

Change VM to use dynamic memory (and increase maximum RAM from 2 GB to 4 GB):

- Startup RAM: **2 GB**
- Minimum RAM: **512 MB**
- Maximum RAM: **4 GB**

## Issue - WSUS crashing due to memory constraint

Windows Update failing on clients:

- HRESULT: 0x80244022
- HRESULT: 0x8024400A

### Troubleshooting

Log Name:      System\
Source:        Microsoft-Windows-WAS\
Date:          10/14/2016 9:32:42 AM\
Event ID:      5117\
Task Category: None\
Level:         Information\
Keywords:      Classic\
User:          N/A\
Computer:      COLOSSUS.corp.technologytoolbox.com\
Description:\
A worker process serving application pool 'WsusPool' has requested a recycle because it reached its private bytes memory limit.

Log Name:      System\
Source:        Microsoft-Windows-WAS\
Date:          10/14/2016 9:33:42 AM\
Event ID:      5002\
Task Category: None\
Level:         Error\
Keywords:      Classic\
User:          N/A\
Computer:      COLOSSUS.corp.technologytoolbox.com\
Description:\
Application pool 'WsusPool' is being automatically disabled due to a series of failures in the process(es) serving that application pool.

### Solution

Modify the properties for **WsusPool** to increase the **Private Memory Limit (KB)** from **1258015** to **2500000**.

## Upgrade to System Center Operations Manager 2016

### Uninstall SCOM 2012 R2 agent

```Console
msiexec /x `{786970C5-E6F6-4A41-B238-AE25D4B91EEA`}

Restart-Computer
```

### Install SCOM 2016 agent (using Operations Console)

## Issue - Incorrect IPv6 DNS server assigned by Comcast router

```Text
PS C:\Users\jjameson-admin> nslookup
Default Server:  cdns01.comcast.net
Address:  2001:558:feed::1
```

> **Note**
>
> Even after reconfiguring the **Primary DNS** and **Secondary DNS** settings on the Comcast router -- and subsequently restarting the VM -- the incorrect DNS server is assigned to the network adapter.

### Solution

```PowerShell
Set-DnsClientServerAddress `
    -InterfaceAlias Management `
    -ServerAddresses 2603:300b:802:8900::103, 2603:300b:802:8900::104

Restart-Computer
```

## Move WSUS database from HAVOK to TT-SQL01

### # Stop WSUS services

```PowerShell
Stop-Service wuauserv
Stop-Service W3SVC
Stop-Service WsusService
```

### Backup database

> **Note**
>
> Use backup/restore -- instead of database detach/attach -- due to different versions of SQL Server running on HAVOK and TT-SQL01. Initially, detach/attach was attempted but it did not restore the log file due to different file location (i.e. "L:\\Microsoft SQL Server\\MSSQL12.MSSQLSERVER\\..." vs. "L:\\Microsoft SQL Server\\MSSQL13.MSSQLSERVER\\...").

---

**HAVOK - SQL Server Management Studio**

#### -- Create copy-only database backup on source server

```SQL
DECLARE @databaseName VARCHAR(50) = 'SUSDB'

DECLARE @backupDirectory VARCHAR(255)

EXEC master.dbo.xp_instance_regread
    N'HKEY_LOCAL_MACHINE'
    , N'Software\Microsoft\MSSQLServer\MSSQLServer'
    , N'BackupDirectory'
    , @backupDirectory OUTPUT

DECLARE @backupFilePath VARCHAR(255) =
    @backupDirectory + '\' + @databaseName + '.bak'

DECLARE @backupName VARCHAR(100) = @databaseName + '-Full Database Backup'

BACKUP DATABASE @databaseName
    TO DISK = @backupFilePath
    WITH COMPRESSION
        , COPY_ONLY
        , INIT
        , NAME = @backupName
        , STATS = 10

GO
```

---

### Move database backup to destination server

---

**HAVOK**

```PowerShell
cls
```

#### # Move database backup

```PowerShell
Move-Item `
    -Path "Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\SUSDB.bak" `
    -Destination "\\TT-SQL01A\Z$\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup"
```

---

### Restore database on destination server

---

**TT-SQL01A - SQL Server Management Studio**

#### -- Restore database backup

```SQL
DECLARE @databaseName VARCHAR(50) = 'SUSDB'

DECLARE @dataFile VARCHAR(25) = @databaseName
DECLARE @logFile VARCHAR(25) = @databaseName + '_log'

DECLARE @backupDirectory VARCHAR(255)
DECLARE @dataDirectory VARCHAR(255) = CONVERT(
    VARCHAR(255),
    SERVERPROPERTY('instancedefaultdatapath'))

DECLARE @logDirectory VARCHAR(255) = CONVERT(
    VARCHAR(255),
    SERVERPROPERTY('instancedefaultlogpath'))

EXEC master.dbo.xp_instance_regread
    N'HKEY_LOCAL_MACHINE'
    , N'Software\Microsoft\MSSQLServer\MSSQLServer'
    , N'BackupDirectory'
    , @backupDirectory OUTPUT

DECLARE @backupFilePath VARCHAR(255) =
    @backupDirectory + '\' + @databaseName + '.bak'

DECLARE @dataFilePath VARCHAR(255) =
    @dataDirectory + '\' + @databaseName + '.mdf'

DECLARE @logFilePath VARCHAR(255) =
    @logDirectory + '\' + @databaseName + '.ldf'

RESTORE DATABASE @databaseName
    FROM DISK = @backupFilePath
    WITH REPLACE
        , MOVE @dataFile TO @dataFilePath
        , MOVE @logFile TO @logFilePath
        , STATS = 5

GO
```

#### -- Create login used by WSUS database

```SQL
USE master
GO

CREATE LOGIN [TECHTOOLBOX\COLOSSUS$] FROM WINDOWS
WITH DEFAULT_DATABASE=master, DEFAULT_LANGUAGE=us_english
GO
```

---

### Add SUSDB database to AlwaysOn Availability Group

---

**SQL Server Management Studio (TT-SQL01A)**

#### -- Change recovery model for WSUS database from Simple to Full

```SQL
USE master
GO
ALTER DATABASE SUSDB SET RECOVERY FULL WITH NO_WAIT
GO
```

#### -- Backup WSUS database

```SQL
DECLARE @backupFilePath VARCHAR(255) =
    'Z:\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\'
        + 'SUSDB.bak'

BACKUP DATABASE SUSDB
    TO DISK = @backupFilePath
    WITH FORMAT, INIT, SKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 5
GO
```

#### -- Backup WSUS transaction log

```SQL
DECLARE @backupFilePath VARCHAR(255) =
    'Z:\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\'
        + 'SUSDB.trn'

BACKUP LOG SUSDB
    TO DISK = @backupFilePath
    WITH NOFORMAT, NOINIT, NOSKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 5
GO
```

#### -- Add WSUS database to Availability Group

```SQL
ALTER AVAILABILITY GROUP [TT-SQL01] ADD DATABASE SUSDB
GO
```

---

---

**SQL Server Management Studio (TT-SQL01B)**

#### -- Create login used by WSUS database

```SQL
USE master
GO

CREATE LOGIN [TECHTOOLBOX\COLOSSUS$] FROM WINDOWS
WITH DEFAULT_DATABASE=master, DEFAULT_LANGUAGE=us_english
GO
```

#### -- Restore WSUS database from backup

```SQL
DECLARE @backupFilePath VARCHAR(255) =
    '\\TT-SQL01A\SQL-Backups\SUSDB.bak'

RESTORE DATABASE SUSDB
    FROM DISK = @backupFilePath
    WITH  NORECOVERY,  NOUNLOAD,  STATS = 5

GO
```

#### -- Restore WSUS transaction log from backup

```SQL
DECLARE @backupFilePath VARCHAR(255) =
    '\\TT-SQL01A\SQL-Backups\SUSDB.trn'

RESTORE DATABASE SUSDB
    FROM DISK = @backupFilePath
    WITH  NORECOVERY,  NOUNLOAD,  STATS = 5

GO
```

#### -- Wait for the replica to start communicating

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

ALTER DATABASE [SUSDB] SET HADR AVAILABILITY GROUP = [TT-SQL01]
GO
```

---

---

**SQL Server Management Studio (TT-SQL01)**

### -- Create SQL job for WSUS database maintenance

```Console
USE [msdb]
GO

/****** Object:  Job [WsusDBMaintenance]    Script Date: 8/15/2017 9:40:04 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 8/15/2017 9:40:04 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'WsusDBMaintenance',
    @enabled=1,
    @notify_level_eventlog=0,
    @notify_level_email=0,
    @notify_level_netsend=0,
    @notify_level_page=0,
    @delete_level=0,
    @description=N'No description available.',
    @category_name=N'[Uncategorized (Local)]',
    @owner_login_name=N'TECHTOOLBOX\jjameson-admin', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Defragment database and update statistics]    Script Date: 8/15/2017 9:40:04 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Defragment database and update statistics',
    @step_id=1,
    @cmdexec_success_code=0,
    @on_success_action=1,
    @on_success_step_id=0,
    @on_fail_action=2,
    @on_fail_step_id=0,
    @retry_attempts=0,
    @retry_interval=0,
    @os_run_priority=0, @subsystem=N'TSQL',
    @command=N'/******************************************************************************
This sample T-SQL script performs basic maintenance tasks on SUSDB
1. Identifies indexes that are fragmented and defragments them. For certain
   tables, a fill-factor is set in order to improve insert performance.
   Based on MSDN sample at http://msdn2.microsoft.com/en-us/library/ms188917.aspx
   and tailored for SUSDB requirements
2. Updates potentially out-of-date table statistics.
******************************************************************************/

USE SUSDB;
GO
SET NOCOUNT ON;

-- Rebuild or reorganize indexes based on their fragmentation levels
DECLARE @work_to_do TABLE (
    objectid int
    , indexid int
    , pagedensity float
    , fragmentation float
    , numrows int
)

DECLARE @objectid int;
DECLARE @indexid int;
DECLARE @schemaname nvarchar(130);
DECLARE @objectname nvarchar(130);
DECLARE @indexname nvarchar(130);
DECLARE @numrows int
DECLARE @density float;
DECLARE @fragmentation float;
DECLARE @command nvarchar(4000);
DECLARE @fillfactorset bit
DECLARE @numpages int

-- Select indexes that need to be defragmented based on the following
-- * Page density is low
-- * External fragmentation is high in relation to index size
PRINT ''Estimating fragmentation: Begin. '' + convert(nvarchar, getdate(), 121)
INSERT @work_to_do
SELECT
    f.object_id
    , index_id
    , avg_page_space_used_in_percent
    , avg_fragmentation_in_percent
    , record_count
FROM
    sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL , NULL, ''SAMPLED'') AS f
WHERE
    (f.avg_page_space_used_in_percent < 85.0 and f.avg_page_space_used_in_percent/100.0 * page_count < page_count - 1)
    or (f.page_count > 50 and f.avg_fragmentation_in_percent > 15.0)
    or (f.page_count > 10 and f.avg_fragmentation_in_percent > 80.0)

PRINT ''Number of indexes to rebuild: '' + cast(@@ROWCOUNT as nvarchar(20))

PRINT ''Estimating fragmentation: End. '' + convert(nvarchar, getdate(), 121)

SELECT @numpages = sum(ps.used_page_count)
FROM
    @work_to_do AS fi
    INNER JOIN sys.indexes AS i ON fi.objectid = i.object_id and fi.indexid = i.index_id
    INNER JOIN sys.dm_db_partition_stats AS ps on i.object_id = ps.object_id and i.index_id = ps.index_id

-- Declare the cursor for the list of indexes to be processed.
DECLARE curIndexes CURSOR FOR SELECT * FROM @work_to_do

-- Open the cursor.
OPEN curIndexes

-- Loop through the indexes
WHILE (1=1)
BEGIN
    FETCH NEXT FROM curIndexes
    INTO @objectid, @indexid, @density, @fragmentation, @numrows;
    IF @@FETCH_STATUS < 0 BREAK;

    SELECT
        @objectname = QUOTENAME(o.name)
        , @schemaname = QUOTENAME(s.name)
    FROM
        sys.objects AS o
        INNER JOIN sys.schemas as s ON s.schema_id = o.schema_id
    WHERE
        o.object_id = @objectid;

    SELECT
        @indexname = QUOTENAME(name)
        , @fillfactorset = CASE fill_factor WHEN 0 THEN 0 ELSE 1 END
    FROM
        sys.indexes
    WHERE
        object_id = @objectid AND index_id = @indexid;

    IF ((@density BETWEEN 75.0 AND 85.0) AND @fillfactorset = 1) OR (@fragmentation < 30.0)
        SET @command = N''ALTER INDEX '' + @indexname + N'' ON '' + @schemaname + N''.'' + @objectname + N'' REORGANIZE'';
    ELSE IF @numrows >= 5000 AND @fillfactorset = 0
        SET @command = N''ALTER INDEX '' + @indexname + N'' ON '' + @schemaname + N''.'' + @objectname + N'' REBUILD WITH (FILLFACTOR = 90)'';
    ELSE
        SET @command = N''ALTER INDEX '' + @indexname + N'' ON '' + @schemaname + N''.'' + @objectname + N'' REBUILD'';
    PRINT convert(nvarchar, getdate(), 121) + N'' Executing: '' + @command;
    EXEC (@command);
    PRINT convert(nvarchar, getdate(), 121) + N'' Done.'';
END

-- Close and deallocate the cursor.
CLOSE curIndexes;
DEALLOCATE curIndexes;


IF EXISTS (SELECT * FROM @work_to_do)
BEGIN
    PRINT ''Estimated number of pages in fragmented indexes: '' + cast(@numpages as nvarchar(20))
    SELECT @numpages = @numpages - sum(ps.used_page_count)
    FROM
        @work_to_do AS fi
        INNER JOIN sys.indexes AS i ON fi.objectid = i.object_id and fi.indexid = i.index_id
        INNER JOIN sys.dm_db_partition_stats AS ps on i.object_id = ps.object_id and i.index_id = ps.index_id

    PRINT ''Estimated number of pages freed: '' + cast(@numpages as nvarchar(20))
END
GO


--Update all statistics
PRINT ''Updating all statistics.'' + convert(nvarchar, getdate(), 121)
EXEC sp_updatestats
PRINT ''Done updating statistics.'' + convert(nvarchar, getdate(), 121)
GO',
    @database_name=N'SUSDB',
    @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Weekly',
    @enabled=1,
    @freq_type=8,
    @freq_interval=1,
    @freq_subday_type=1,
    @freq_subday_interval=0,
    @freq_relative_interval=0,
    @freq_recurrence_factor=1,
    @active_start_date=20161217,
    @active_end_date=99991231,
    @active_start_time=100000,
    @active_end_time=235959,
    @schedule_uid=N'e0a9c6bf-b402-47df-97c8-c70aeeb6d42b'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO
```

---

---

**HAVOK - SQL Server Management Studio**

### -- Delete database on source server

```SQL
USE master
GO
DROP DATABASE SUSDB
GO
```

### -- Delete SQL job for WSUS database maintenance

```SQL
USE msdb
GO
EXEC msdb.dbo.sp_delete_job @job_name=N'WsusDBMaintenance',
    @delete_unused_schedule=1

GO
```

---

```PowerShell
cls
```

### # Configure WSUS server for new database server

```PowerShell
Set-ItemProperty `
    -Path 'HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup' `
    -Name SqlServerName `
    -Value TT-SQL01

Get-ItemProperty `
    -Path 'HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup' `
    -Name SqlServerName
```

```PowerShell
cls
```

### # Stop WSUS services

```PowerShell
Start-Service WsusService
Start-Service W3SVC
Start-Service wuauserv
```

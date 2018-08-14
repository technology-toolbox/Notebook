# TT-VMM01A - Windows Server 2016 Standard Edition

Sunday, January 29, 2017
4:55 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create and configure setup account for Virtual Machine Manager

#### # Create setup account for Virtual Machine Manager

```PowerShell
$displayName = "Setup account for Virtual Machine Manager"
$defaultUserName = "setup-vmm"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@corp.technologytoolbox.com"
$orgUnit = "OU=Setup Accounts,OU=IT,DC=corp,DC=technologytoolbox,DC=com"

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

#### # Add setup account to VMM Admins domain group

```PowerShell
Add-ADGroupMember `
    -Identity "VMM Admins" `
    -Members "setup-vmm"
```

```PowerShell
cls
```

### # Create service account for Virtual Machine Manager cluster

```PowerShell
$displayName = "Service account for Virtual Machine Manager cluster (TT-VMM01)"
$defaultUserName = "s-vmm01"

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

```PowerShell
cls
```

### # Create "VMM management" service account (e.g. for adding file shares to VMM)

```PowerShell
$displayName = "Service account for VMM - Management (TT-VMM01)"
$defaultUserName = "s-vmm01-mgmt"

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

```PowerShell
cls
```

### # Create failover cluster objects in Active Directory

#### # Create cluster object for VMM failover cluster and delegate permission to create the cluster to any member of the VMM administrators group

```PowerShell
$failoverClusterName = "TT-VMM01-FC"
$delegate = "VMM Admins"
$orgUnit = "OU=System Center Servers,OU=Servers,OU=Resources,OU=IT," `
    + "DC=corp,DC=technologytoolbox,DC=com"

C:\NotBackedUp\Public\Toolbox\PowerShell\New-ClusterObject.ps1 `
    -Name $failoverClusterName  `
    -Delegate $delegate `
    -Path $orgUnit

# HACK: Wait a few seconds to avoid issue where the cluster object just created is not found when delegating permission

Start-Sleep -Seconds 5
```

#### # Create failover cluster name for VMM service and delegate permission to create the cluster name to the failover cluster service (TT-VMM01-FC\$)

```PowerShell
$failoverClusterName = "TT-VMM01"
$delegate = "TT-VMM01-FC$"
$description = "Failover cluster name for Virtual Machine Manager service"

C:\NotBackedUp\Public\Toolbox\PowerShell\New-ClusterObject.ps1 `
    -Name $failoverClusterName  `
    -Delegate $delegate `
    -Description $description `
    -Path $orgUnit
```

---

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV02A"
$vmName = "TT-VMM01A"
$vmPath = "E:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 4GB `
    -
Name "Tenant vSwitch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 2 `
    -StaticMemory

Set-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path \\TT-FS01\Products\Microsoft\MDT-Deploy-x86.iso

Start-VM -ComputerName $vmHost -Name $vmName
```

---

## Install custom Windows Server 2016 image

- On the **Task Sequence** step, select **Windows Server 2016** and click **Next**.
- On the **Computer Details** step, in the **Computer name** box, type **TT-VMM01A** and click **Next**.
- On the **Applications** step, do not select any applications, and click **Next**.

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
> When prompted for the secure string, type the password for the Administrator account.

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
$vmHost = "TT-HV02A"
$vmName = "TT-VMM01A"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

### # Move computer to "System Center Servers" OU

```PowerShell
$targetPath = ("OU=System Center Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath

Restart-VM -ComputerName $vmHost -VMName $vmName -Force
```

> **Important**
>
> Wait for the VM to restart before proceeding.

```PowerShell
cls
```

### # Add VMM administrators domain group to local Administrators group on VMM server

```PowerShell
$scriptBlock = {
    net localgroup Administrators "TECHTOOLBOX\VMM Admins" /ADD
}

Invoke-Command -ComputerName $vmName -ScriptBlock $scriptBlock
```

---

## Configure network settings

### Login as TECHTOOLBOX\\setup-vmm

### # Rename network connection

```PowerShell
$interfaceAlias = "Datacenter 1"

Get-NetAdapter -Physical

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping TT-FS01 -f -l 8900
```

## # Configure storage

### # Change drive letter for DVD-ROM

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

## # Prepare server for VMM installation

### # Set MaxPatchCacheSize to 0 (Recommended)

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

### Configure failover clustering

---

**FOOBAR8**

```PowerShell
cls
```

#### # Add a second network adapter for cluster network

```PowerShell
$vmHost = "TT-HV02A"
$vmName = "TT-VMM01A"

Stop-VM -ComputerName $vmHost -Name $vmName

Add-VMNetworkAdapter -ComputerName $vmHost -VMName $vmName -SwitchName "Tenant vSwitch"

Start-VM -ComputerName $vmHost -Name $vmName
```

---

#### Login as TECHTOOLBOX\\setup-vmm

```PowerShell
cls
```

#### # Configure cluster network settings

```PowerShell
$interfaceAlias = "Cluster"
```

##### # Rename cluster network adapter

```PowerShell
Get-NetAdapter `
    -InterfaceDescription "Microsoft Hyper-V Network Adapter #2" |
    Rename-NetAdapter -NewName $interfaceAlias
```

##### # Disable DHCP and router discovery

```PowerShell
Set-NetIPInterface `
    -InterfaceAlias $interfaceAlias `
    -Dhcp Disabled `
    -RouterDiscovery Disabled
```

##### # Configure static IPv4 address

```PowerShell
$ipAddress = "172.16.1.1"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24
```

##### # Configure static IPv6 address

**# Note:** Private IPv6 address range (fd66:d7e2:39d6:a4d9::/64) generated by [http://simpledns.com/private-ipv6.aspx](http://simpledns.com/private-ipv6.aspx)

```PowerShell
$ipAddress = "fd66:d7e2:39d6:a4da::1"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 64
```

```PowerShell
cls
```

#### # Install Failover Clustering feature

```PowerShell
Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools
```

> **Note**
>
> Install Failover Clustering feature on second node before proceeding to the next step.

```PowerShell
cls
```

#### # Run all cluster validation tests

```PowerShell
Test-Cluster -Node TT-VMM01A, TT-VMM01B
```

> **Note**
>
> Wait for the cluster validation tests to complete.

```PowerShell
& "$env:TEMP\Validation Report 2017.01.29 At 05.30.02.htm"
```

```PowerShell
cls
```

#### # Create cluster

```PowerShell
New-Cluster -Name TT-VMM01-FC -Node TT-VMM01A, TT-VMM01B -NoStorage

WARNING: There were issues while creating the clustered role that may prevent it from starting. For more information view the report file below.
WARNING: Report file location: C:\windows\cluster\Reports\Create Cluster Wizard TT-VMM01-FC on 2017.01.29 At 05.31.43.htm

Name
----
TT-VMM01-FC


& "C:\windows\cluster\Reports\Create Cluster Wizard TT-VMM01-FC on 2017.01.29 At 05.31.43.htm"
```

> **Note**
>
> The cluster creation report contains the following warning:
>
> - **An appropriate disk was not found for configuring a disk witness. The cluster is not configured with a witness. As a best practice, configure a witness to help achieve the highest availability of the cluster. If this cluster does not have shared storage, configure a File Share Witness or a Cloud Witness.**

#### Configure cluster quorum

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

##### # Configure file share for cluster quorum witness

```PowerShell
Enter-PSSession TT-FS01
```

---

**TT-FS01**

###### # Create folder

```PowerShell
$folderName = "Witness`$"
$path = "D:\Shares\$folderName"
```

###### # Grant permissions to VMM administrators

```PowerShell
icacls $path /grant '"VMM Admins":(OI)(CI)(RX)'
```

###### # Create folder for specific failover cluster (TT-VMM01-FC)

```PowerShell
$path = "$path\TT-VMM01-FC"

New-Item -Path $path -ItemType Directory
```

###### # Grant permissions for failover cluster service

```PowerShell
icacls $path /grant 'TT-VMM01-FC$:(OI)(CI)(F)'

exit
```

---

---

```PowerShell
cls
```

##### # Set file share as cluster quorum witness

```PowerShell
Set-ClusterQuorum -NodeAndFileShareMajority \\TT-FS01\Witness$\TT-VMM01-FC
```

### Configure Distributed Key Management in VMM

#### Reference

**Configuring Distributed Key Management in VMM**\
From <[https://technet.microsoft.com/en-us/library/gg697604(v=sc.12).aspx](https://technet.microsoft.com/en-us/library/gg697604(v=sc.12).aspx)>

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

To configure Distributed Key Management in VMM:

1. Open **ADSI Edit**.
2. In the left pane, expand **Default naming context** and then expand **CN=System**.
3. Right-click **CN=System**, point to **New**, and click **Object...**
4. In the **Create Object** window:
   1. In the class list, select **container**, and click **Next**.
   2. For the **cn** (**Common-Name**) attribute, in the **Value** box, type **VMM Distributed Key Management**, and click **Next**.
   3. Click **Finish**.
5. On the **View** menu, ensure **Advanced Features** is checked.
6. In the left pane, right-click **CN=VMM Distributed Key Management** and click **Properties**.
7. In the properties window for the container, on the **Security** tab, click **Advanced**.
8. In the **Advanced Security Settings for VMM Distributed Key Management **window, click **Add**.
9. In the **Permission Entry for VMM Distributed Key Management **window, click **Select a principal**.
10. In the **Select User, Computer, Service Account, or Group** window, specify the domain group for VMM administrators (**TECHTOOLBOX\\VMM Admins**) and click **OK**.
11. In the **Permission Entry for VMM Distributed Key Management **window:
    1. In the **Applies to** list, select **This object and all descendant objects**.
    2. In the **Permissions** section, select **Full control**.
    3. Click **OK**.
12. In the **Advanced Security Settings for VMM Distributed Key Management** window, click **OK**.
13. In the properties window for the container, click **OK**.

---

```PowerShell
cls
```

### # Install prerequisites for VMM Management Server

#### # Install Windows Assessment and Deployment Kit (Windows ADK) for Windows 10

```PowerShell
& "\\TT-FS01\Public\Download\Microsoft\Windows Kits\10\ADK\adksetup.exe"
```

1. On the **Specify Location** page, click **Next**.
2. On the **Windows Kits Privacy **page, click **Next**.
3. On the **License Agreement** page:
   1. Review the software license terms.
   2. If you agree to the terms, click **Accept**.
4. On the **Select the features you want to install **page:
   1. Select _only_ the following items:
      - **Deployment Tools**
      - **Windows Preinstallation Environment (Windows PE)**
   2. Click **Install**.

```PowerShell
cls
```

#### # Install SQL Server 2012 Native Client

```PowerShell
& "\\TT-FS01\Products\Microsoft\SQL Server 2012\Native Client\x64\sqlncli.msi"
```

```PowerShell
cls
```

#### # Install SQL Server 2012 Command Line Utilities

```PowerShell
& ("\\TT-FS01\Products\Microsoft\SQL Server 2012\Command Line Utilities\x64" `
    + "\SqlCmdLnUtils.msi")
```

#### Install updates

```PowerShell
cls
```

#### # Restart the server

```PowerShell
Restart-Computer
```

#### Login as TECHTOOLBOX\\setup-vmm

### # Add service account for Virtual Machine Manager to local Administrators group

```PowerShell
net localgroup Administrators TECHTOOLBOX\s-vmm01 /ADD
```

#### Reference

"If you specify a domain account, the account must be a member of the local Administrators group on the computer."

**_Specifying a Service Account for VMM_**\
From <[https://technet.microsoft.com/en-us/library/gg697600.aspx](https://technet.microsoft.com/en-us/library/gg697600.aspx)>

## Install VMM Management Server

### Reference

**Install VMM**\
From <[https://technet.microsoft.com/en-us/system-center-docs/vmm/deploy/deploy-install](https://technet.microsoft.com/en-us/system-center-docs/vmm/deploy/deploy-install)>

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Insert the VMM 2016 installation media

```PowerShell
$vmHost = "TT-HV02A"
$vmName = "TT-VMM01A"

$isoPath = "\\TT-FS01\Products\Microsoft\System Center 2016" `
    + "\mu_system_center_2016_virtual_machine_manager_x64_dvd_9368503.iso"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $isoPath
```

---

```PowerShell
cls
```

### # Extract VMM setup files

```PowerShell
X:\SC2016_SCVMM.EXE
```

Destination location: **C:\\NotBackedUp\\Temp\\System Center 2016 Virtual Machine Manager**

```PowerShell
cls
```

### # Install VMM Management Server on first cluster node

> **Note**
>
> Before beginning the installation of VMM, close any open programs and ensure that there are no pending restarts on the computer. For example, if you have installed a server role by using Server Manager or have applied a security update, you may need to restart the computer and then log on to the computer with the same user account to finish the installation of the server role or the security update.

**To install a VMM management server on the first cluster node:**

1. To start the Virtual Machine Manager Setup Wizard, on your installation media, right-click **setup.exe**, and then click **Run as administrator**.
2. On the main setup page, click **Install**.
3. On the **Select features to install** page:
   1. Select the **VMM management server** check box.
   2. When prompted to install VMM management server on this cluster and make it highly available, click **Yes**.
   3. Click **Next**.
4. On the **Product registration information** page, provide the appropriate information, and then click **Next**.
5. On the **Please read this license agreement** page, review the license agreement, select the **I have read, understood, and agree with the terms of the license agreement** check box, and then click **Next**.
6. On the **Diagnostic and Usage Data** page, review the data collection and usage policy and then click **Next**.
7. On the **Microsoft Update **page, select **On (recommended)** and then click **Next**.
8. On the **Installation location** page, ensure the default path is specified (**C:\\Program Files\\Microsoft System Center 2016\\Virtual Machine Manager**), and then click **Next**.
9. If all prerequisites have been met, the **Database configuration** page appears.
10. On the **Database configuration** page:
    1. In the **Server name** box, type the SQL Server cluster name (**TT-SQL01**).
    2. Leave the **Port** box empty.
    3. If the account you are using to install the VMM management server does not have the appropriate permissions to create a new SQL Server database, select the **Use the following credentials** check box, and then provide the user name and password of an account that has the appropriate permissions.
    4. Select or type the name of the instance of SQL Server that you want to use.
    5. Ensure the **New database** option is selected and the default database name (**VirtualManagerDB**) is specified.
    6. Click **Next**.
11. On the **Cluster configuration** page:
    1. In the **Name** box, type the name of the VMM cluster (**TT-VMM01**).
    2. Click **Next**.
12. On the **Configure service account and distributed key management** page:
    1. In the **Virtual Machine Manager Service Account** section, specify the account that will be used by the Virtual Machine Manager service (**TECHTOOLBOX\\s-vmm01**).
    2. In the **Distributed Key Management** section, type the location to store encryption keys in Active Directory.
    3. Click **Next**.
13. On the **Port configuration** page, click **Next** (use the default port numbers for each feature).
14. On the **Library configuration** page, click **Next**.
15. On the **Installation summary** page, review your selections and do one of the following:
16. On the **Setup completed... **page:
    1. Review any warnings that occurred.
    2. Clear the **Open the VMM console when this wizard closes** checkbox.
    3. Click **Close** to finish the installation.

```PowerShell
    & "C:\NotBackedUp\Temp\System Center 2016 Virtual Machine Manager\setup.exe"
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/77/48FFD2DB79A8C0E4B9CB8D78928A35648BF49377.png)

> **Note**
>
> The VMM console is automatically installed when you install a VMM management server.

**CN=VMM Distributed Key Management,CN=System,DC=corp,DC=technologytoolbox,DC=com**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AF/9E2972E41B3CD81141510F858C51473F1E9FBDAF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F3/60416A0E7833848FF314A09D4E951BCAA108B8F3.png)

> **Important**
>
> The ports that you assign during the installation of a VMM management server cannot be changed without uninstalling and reinstalling the VMM management server. Also, do not configure any feature with port number 5986 as it is been pre-assigned.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EE/02E4155E3F20C4075CBD921C20425918442DFCEE.png)

- Click **Previous** to change any selections.
- Click **Install** to install the VMM management server.

After you click **Install**, the **Installing features** page appears and installation progress is displayed.

> **Important**
>
> During Setup, VMM enables the following firewall rules, which remain in effect even if you later uninstall VMM:
>
> - File Server Remote Management
> - Windows Standards-Based Storage Management firewall rules

> **Note**
>
> If there is a problem with setup completing successfully, consult the log files in the **%SYSTEMDRIVE%\\ProgramData\\VMMLogs** folder. **ProgramData** is a hidden folder.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8C/8D3D5456532D4A449985997115CD4AF1898AE68C.png)

#### Issue -

The Service Principal Name (SPN) could not be registered in Active Directory Domain Services (AD DS) for the VMM management server.\
1) Use setspn.exe to create SPN for vmmserver using following command "C:\\windows\\system32\\setspn.exe  -S SCVMM/TT-VMM01.corp.technologytoolbox.com TECHTOOLBOX\\s-vmm01".\
2) Add SPN values to following registry key "Software\\Microsoft\\Microsoft System Center Virtual Machine Manager Server\\Setup\\VmmServicePrincipalNames".\
3) Run "C:\\Program Files\\Microsoft System Center 2016\\Virtual Machine Manager\\setup\\ConfigureSCPTool.exe -install TT-VMM01.corp.technologytoolbox.com TECHTOOLBOX\\TT-VMM01\$" to configure SCP.

If SPN and SCP are not registered, VMM consoles on other computers will not be able to connect to this VMM management server and deploying a Hyper-V host to a bare-metal computer will not work.\
A service connection point (SCP) could not be registered in Active Directory Domain Services (AD DS) for the VMM management server.\
Run "C:\\Program Files\\Microsoft System Center 2016\\Virtual Machine Manager\\setup\\ConfigureSCPTool.exe -install TT-VMM01.corp.technologytoolbox.com TECHTOOLBOX\\TT-VMM01\$" in a command window and then check AD DS. If an SCP is not registered, VMM consoles on other computers will not be able to connect to this VMM management server and deploying a Hyper-V host to a bare-metal computer will not work.

#### Solution

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

##### # Create SPN for Virtual Machine Manager service account

```PowerShell
setspn.exe -S SCVMM/TT-VMM01.corp.technologytoolbox.com TECHTOOLBOX\s-vmm01
```

---

```PowerShell
cls
```

##### # Add SPN value to VMM registry key

```PowerShell
$regKeyPath = "HKLM:\SOFTWARE\Microsoft" `
    + "\Microsoft System Center Virtual Machine Manager Server\Setup"

Set-ItemProperty `
```

    -Path \$regKeyPath `\
    -Name VmmServicePrincipalNames `\
    -Value "SCVMM/TT-VMM01.corp.technologytoolbox.com"

```PowerShell
$vmmServicePrincipalNames = $(Get-ItemProperty $regKeyPath).VmmServicePrincipalNames
```

##### # Create service connection point for VMM

```PowerShell
runas /USER:TECHTOOLBOX\jjameson-admin PowerShell
```

---

**PowerShell - Running as TECHTOOLBOX\\jjameson-admin**

```PowerShell
$scpTool = "C:\Program Files\Microsoft System Center 2016\Virtual Machine Manager" `
    + "\setup\ConfigureSCPTool.exe"

& $scpTool -install TT-VMM01.corp.technologytoolbox.com TECHTOOLBOX\TT-VMM01`$

exit
```

---

```PowerShell
cls
```

### # Remove temporary VMM setup files

```PowerShell
Remove-Item "C:\NotBackedUp\Temp\System Center 2016 Virtual Machine Manager" -Recurse
```

### Install VMM Management Server on second cluster node

### Add VMM database to AlwaysOn Availability Group

---

**SQL Server Management Studio (TT-SQL01A)**

#### -- Change recovery model for VMM database from Simple to Full

```SQL
USE [master]
GO
ALTER DATABASE [VirtualManagerDB] SET RECOVERY FULL WITH NO_WAIT
GO
```

#### -- Backup VMM database

```SQL
DECLARE @backupFilePath VARCHAR(255) =
    'Z:\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\'
        + 'VirtualManagerDB.bak'

BACKUP DATABASE VirtualManagerDB
    TO DISK = @backupFilePath
    WITH FORMAT, INIT, SKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 5
GO
```

#### -- Backup VMM transaction log

```SQL
DECLARE @backupFilePath VARCHAR(255) =
    'Z:\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\'
        + 'VirtualManagerDB.trn'

BACKUP LOG VirtualManagerDB
    TO DISK = @backupFilePath
    WITH NOFORMAT, NOINIT, NOSKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 5
GO
```

#### -- Add VMM database to Availability Group

```SQL
ALTER AVAILABILITY GROUP [TT-SQL01] ADD DATABASE VirtualManagerDB
GO
```

---

---

**SQL Server Management Studio (TT-SQL01B)**

#### -- Create logins used by VMM database

```SQL
USE [master]
GO

CREATE LOGIN [TECHTOOLBOX\setup-vmm] FROM WINDOWS
WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english]
GO

CREATE LOGIN [TECHTOOLBOX\s-vmm01] FROM WINDOWS
WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english]
GO
```

#### -- Restore VMM database from backup

```SQL
DECLARE @backupFilePath VARCHAR(255) =
    '\\TT-SQL01A\SQL-Backups\VirtualManagerDB.bak'

RESTORE DATABASE VirtualManagerDB
    FROM DISK = @backupFilePath
    WITH  NORECOVERY,  NOUNLOAD,  STATS = 5

GO
```

#### -- Restore VMM transaction log from backup

```SQL
DECLARE @backupFilePath VARCHAR(255) =
    '\\TT-SQL01A\SQL-Backups\VirtualManagerDB.trn'

RESTORE DATABASE VirtualManagerDB
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

ALTER DATABASE [VirtualManagerDB] SET HADR AVAILABILITY GROUP = [TT-SQL01]
GO
```

---

> **Important**
>
> Restart PowerShell for VMM cmdlets to be available.

```PowerShell
cls
```

## # Configure network infrastructure

### # Connect to VMM server

```PowerShell
Get-SCVMMServer -ComputerName TT-VMM01
```

### # Disable automatic creation of logical networks

```PowerShell
Set-SCVMMServer -AutomaticLogicalNetworkCreationEnabled $false
```

### Configure "Management" network

Note: The **Management** network is create as "one connected network" and supports network virtualization.

#### # Create logical network for management traffic

```PowerShell
$logicalNetwork = New-SCLogicalNetwork `
    -Name "Management" `
    -LogicalNetworkDefinitionIsolation $false `
    -EnableNetworkVirtualization $true `
    -UseGRE $true `
    -IsPVLAN $false
```

#### # Create network site for management traffic

```PowerShell
$hostGroups = @()
$hostGroups += Get-SCVMHostGroup -Name "All Hosts"

$subnetVlans = @()
$subnetVlans += New-SCSubnetVLan -Subnet "192.168.10.0/24" -VLanID 0

New-SCLogicalNetworkDefinition `
    -Name "Management - VLAN 0" `
    -LogicalNetwork $logicalNetwork `
    -VMHostGroup $hostGroups `
    -SubnetVLan $subnetVlans
```

#### # Create VM network for management traffic

```PowerShell
New-SCVMNetwork `
    -Name "Management VM Network" `
    -IsolationType NoIsolation `
    -LogicalNetwork $logicalNetwork
```

```PowerShell
cls
```

#### # Create IP address pool for management network

```PowerShell
$logicalNetwork = Get-SCLogicalNetwork -Name "Management"

$logicalNetworkDefinition = Get-SCLogicalNetworkDefinition `
```

    -Name "Management - VLAN 0"

```PowerShell
$addressPoolName = "Management Address Pool"

$ipAddressRangeStart = "192.168.10.110"
$ipAddressRangeEnd = "192.168.10.200"

$reservedAddresses = @()
$reservedAddresses += "192.168.10.150"
$reservedAddresses += "192.168.10.151"
$reservedAddresses += "192.168.10.152"
$reservedAddresses += "192.168.10.160"
$reservedAddresses += "192.168.10.161"
$reservedAddresses += "192.168.10.162"

$reservedAddressSet = $reservedAddresses -join ","

$subnet = "192.168.10.0/24"

$networkRoutes = @()

$gateways = @()
$gateways += New-SCDefaultGateway -IPAddress "192.168.10.1" -Automatic

$dnsServers = @("192.168.10.103", "192.168.10.104")

$dnsSuffix = ""
$dnsSearchSuffixes = @()

$winsServers = @()

New-SCStaticIPAddressPool `
    -Name $addressPoolName `
    -LogicalNetworkDefinition $logicalNetworkDefinition `
    -Subnet $subnet `
    -IPAddressRangeStart $ipAddressRangeStart `
    -IPAddressRangeEnd $ipAddressRangeEnd `
    -DefaultGateway $gateways `
    -DNSServer $dnsServers `
    -DNSSuffix $dnsSuffix `
    -DNSSearchSuffix $dnsSearchSuffixes `
    -NetworkRoute $networkRoutes `
    -IPAddressReservedSet $reservedAddressSet
```

### Configure "Datacenter" network (e.g. for storage, live migration, and cluster traffic)

Note: The **Datacenter **network is created as "VLAN-based independent networks" (the subnets might not be routable to one another).

```PowerShell
cls
```

#### # Create logical network for datacenter traffic

```PowerShell
$logicalNetwork = New-SCLogicalNetwork `
    -Name "Datacenter" `
    -LogicalNetworkDefinitionIsolation $true
```

#### # Create network sites for datacenter traffic

```PowerShell
$hostGroups = @()
$hostGroups += Get-SCVMHostGroup -Name "All Hosts"
```

##### # Create network site for storage traffic

```PowerShell
$subnetVlans = @()
$subnetVlans += New-SCSubnetVLan -Subnet "10.1.10.0/24" -VLanID 10

New-SCLogicalNetworkDefinition `
    -Name "Storage - VLAN 10" `
    -LogicalNetwork $logicalNetwork `
    -VMHostGroup $hostGroups `
    -SubnetVLan $subnetVlans
```

##### # Create network site for live migration traffic

```PowerShell
$subnetVlans = @()
$subnetVlans += New-SCSubnetVLan -Subnet "10.1.11.0/24" -VLanID 11

New-SCLogicalNetworkDefinition `
    -Name "Live Migration - VLAN 11" `
    -LogicalNetwork $logicalNetwork `
    -VMHostGroup $hostGroups `
    -SubnetVLan $subnetVlans
```

##### # Create network site for cluster traffic

```PowerShell
$subnetVlans = @()
$subnetVlans += New-SCSubnetVLan -Subnet "172.16.12.0/24" -VLanID 12

New-SCLogicalNetworkDefinition `
    -Name "Cluster - VLAN 12" `
    -LogicalNetwork $logicalNetwork `
    -VMHostGroup $hostGroups `
    -SubnetVLan $subnetVlans
```

#### # Create VM network for storage traffic

```PowerShell
$vmNetwork = New-SCVMNetwork `
    -Name "Storage VM Network" `
    -IsolationType VLANNetwork `
    -LogicalNetwork $logicalNetwork

$logicalNetworkDefinition = Get-SCLogicalNetworkDefinition `
    -Name "Storage - VLAN 10"

$subnetVLANs = @()

$subnetVLANs += (New-SCSubnetVLan -Subnet "10.1.10.0/24" -VLanID 10)

$vmSubnet = New-SCVMSubnet `
    -Name "Storage VM Network_0" `
    -LogicalNetworkDefinition $logicalNetworkDefinition `
    -SubnetVLan $subnetVLANs `
    -VMNetwork $vmNetwork
```

#### # Create IP address pool for storage network

```PowerShell
$logicalNetwork = Get-SCLogicalNetwork -Name "Datacenter"

$logicalNetworkDefinition = Get-SCLogicalNetworkDefinition `
```

    -Name "Storage - VLAN 10"

```PowerShell
$addressPoolName = "Storage Address Pool"

$ipAddressRangeStart = "10.1.10.20"
$ipAddressRangeEnd = "10.1.10.254"

$reservedAddresses = @()

$reservedAddressSet = $reservedAddresses -join ","

$subnet = "10.1.10.0/24"

$networkRoutes = @()

$gateways = @()
$gateways += New-SCDefaultGateway -IPAddress "10.1.10.1" -Automatic

$dnsServers = @("192.168.10.103", "192.168.10.104")

$dnsSuffix = ""
$dnsSearchSuffixes = @()

$winsServers = @()

New-SCStaticIPAddressPool `
    -Name $addressPoolName `
    -LogicalNetworkDefinition $logicalNetworkDefinition `
    -Subnet $subnet `
    -IPAddressRangeStart $ipAddressRangeStart `
    -IPAddressRangeEnd $ipAddressRangeEnd `
    -DefaultGateway $gateways `
    -DNSServer $dnsServers `
    -DNSSuffix $dnsSuffix `
    -DNSSearchSuffix $dnsSearchSuffixes `
    -NetworkRoute $networkRoutes `
    -IPAddressReservedSet $reservedAddressSet
```

#### # Create VM network for live migration traffic

```PowerShell
$vmNetwork = New-SCVMNetwork `
    -Name "Live Migration VM Network" `
    -IsolationType VLANNetwork `
    -LogicalNetwork $logicalNetwork

$logicalNetworkDefinition = Get-SCLogicalNetworkDefinition `
    -Name "Live Migration - VLAN 11"

$subnetVLANs = @()

$subnetVLANs += (New-SCSubnetVLan -Subnet "10.1.11.0/24" -VLanID 11)

$vmSubnet = New-SCVMSubnet `
    -Name "Live Migration VM Network_0" `
    -LogicalNetworkDefinition $logicalNetworkDefinition `
    -SubnetVLan $subnetVLANs `
    -VMNetwork $vmNetwork
```

#### # Create IP address pool for live migration network

```PowerShell
$logicalNetwork = Get-SCLogicalNetwork -Name "Datacenter"

$logicalNetworkDefinition = Get-SCLogicalNetworkDefinition `
```

    -Name "Live Migration - VLAN 11"

```PowerShell
$addressPoolName = "Live Migration Address Pool"

$ipAddressRangeStart = "10.1.11.20"
$ipAddressRangeEnd = "10.1.11.254"

$reservedAddresses = @()

$reservedAddressSet = $reservedAddresses -join ","

$subnet = "10.1.11.0/24"

$networkRoutes = @()

$gateways = @()
$gateways += New-SCDefaultGateway -IPAddress "10.1.11.1" -Automatic

$dnsServers = @("192.168.10.103", "192.168.10.104")

$dnsSuffix = ""
$dnsSearchSuffixes = @()

$winsServers = @()

New-SCStaticIPAddressPool `
    -Name $addressPoolName `
    -LogicalNetworkDefinition $logicalNetworkDefinition `
    -Subnet $subnet `
    -IPAddressRangeStart $ipAddressRangeStart `
    -IPAddressRangeEnd $ipAddressRangeEnd `
    -DefaultGateway $gateways `
    -DNSServer $dnsServers `
    -DNSSuffix $dnsSuffix `
    -DNSSearchSuffix $dnsSearchSuffixes `
    -NetworkRoute $networkRoutes `
    -IPAddressReservedSet $reservedAddressSet
```

#### # Create VM network for cluster traffic

```PowerShell
$vmNetwork = New-SCVMNetwork `
    -Name "Cluster VM Network" `
    -IsolationType VLANNetwork `
    -LogicalNetwork $logicalNetwork

$logicalNetworkDefinition = Get-SCLogicalNetworkDefinition `
    -Name "Cluster - VLAN 12"

$subnetVLANs = @()
$subnetVLANs += (New-SCSubnetVLan -Subnet "172.16.12.0/24" -VLanID 12)

$vmSubnet = New-SCVMSubnet `
    -Name "Cluster VM Network_0" `
    -LogicalNetworkDefinition $logicalNetworkDefinition `
    -SubnetVLan $subnetVLANs `
    -VMNetwork $vmNetwork
```

#### # Create IP address pool for cluster network

```PowerShell
$logicalNetwork = Get-SCLogicalNetwork -Name "Datacenter"

$logicalNetworkDefinition = Get-SCLogicalNetworkDefinition `
```

    -Name "Cluster - VLAN 12"

```PowerShell
$addressPoolName = "Cluster Address Pool"

$ipAddressRangeStart = "172.16.12.1"
$ipAddressRangeEnd = "172.16.12.254"

$reservedAddresses = @()

$reservedAddressSet = $reservedAddresses -join ","

$subnet = "172.16.12.0/24"

$networkRoutes = @()

$gateways = @()

$dnsServers = @()

$dnsSuffix = ""
$dnsSearchSuffixes = @()

$winsServers = @()

New-SCStaticIPAddressPool `
    -Name $addressPoolName `
    -LogicalNetworkDefinition $logicalNetworkDefinition `
    -Subnet $subnet `
    -IPAddressRangeStart $ipAddressRangeStart `
    -IPAddressRangeEnd $ipAddressRangeEnd `
    -DefaultGateway $gateways `
    -DNSServer $dnsServers `
    -DNSSuffix $dnsSuffix `
    -DNSSearchSuffix $dnsSearchSuffixes `
    -NetworkRoute $networkRoutes `
    -IPAddressReservedSet $reservedAddressSet
```

```PowerShell
cls
```

### # Create "trunk" uplink port profile

```PowerShell
$networkSites = @()
$networkSites += Get-SCLogicalNetworkDefinition -Name "Cluster - VLAN 12"
$networkSites += Get-SCLogicalNetworkDefinition -Name "Live Migration - VLAN 11"
$networkSites += Get-SCLogicalNetworkDefinition -Name "Management - VLAN 0"
$networkSites += Get-SCLogicalNetworkDefinition -Name "Storage - VLAN 10"

New-SCNativeUplinkPortProfile `
    -Name "Trunk Uplink" `
    -Description "" `
    -LogicalNetworkDefinition $networkSites `
    -LBFOLoadBalancingAlgorithm HostDefault `
    -LBFOTeamMode SwitchIndependent
```

### # Create virtual network adapter port profiles

```PowerShell
New-SCVirtualNetworkAdapterNativePortProfile `
    -Name "1 Gbps Tenant vNIC" `
    -Description ("A port profile for VMs that allows guest specified IP" `
        + " addresses and is restricted to 1 Gbps.") `
    -EnableGuestIPNetworkVirtualizationUpdates $true `
    -EnableIPsecOffload $true `
    -EnableVmq $true `
    -MaximumBandwidth 1024

New-SCVirtualNetworkAdapterNativePortProfile `
    -Name "Host management and SMB Multichannel" `
    -Description ("A port profile similar to the out-of-the-box 'Host" `
        + " management' profile that also enables virtual receive side" `
        + " scaling (vRSS) for SMB Multichannel.") `
    -EnableVrss $true `
    -EnableIPsecOffload $true `
    -EnableVmq $true `
    -MinimumBandwidthWeight 10

New-SCVirtualNetworkAdapterNativePortProfile `
    -Name "Live migration and SMB Multichannel" `
    -Description ("A port profile similar to the out-of-the-box 'Live" `
        + " migration' profile that also enables virtual receive side" `
        + " scaling (vRSS) for SMB Multichannel.") `
    -EnableVrss $true `
    -EnableIPsecOffload $true `
    -EnableVmq $true `
    -MinimumBandwidthWeight 40

New-SCVirtualNetworkAdapterNativePortProfile `
    -Name "SMB" `
    -Description ("A port profile that specifies the recommended" `
        + " configuration for host virtual network adapters that will be used" `
        + " to carry SMB traffic.") `
    -EnableVrss $true `
    -EnableIPsecOffload $true `
    -EnableVmq $true `
    -MinimumBandwidthWeight 40
```

### # Create port classifications

```PowerShell
New-SCPortClassification `
    -Name "1 Gbps Tenant vNIC" `
    -Description ("Port classification to be used for virtual machines that" `
        + " require guest dynamic IP allocation and should be constrained to " `
        + " 1 Gbps bandwidth.")

New-SCPortClassification `
    -Name "Host management and SMB Multichannel" `
    -Description ("Port classification to be used for host management" `
        + " traffic and SMB Multichannel.")

New-SCPortClassification `
    -Name "Live migration and SMB Multichannel" `
    -Description ("Port classification to be used for host live migration" `
        + " workloads and SMB Multichannel.")

New-SCPortClassification `
    -Name "SMB workload" `
    -Description "Port classification for host SMB workloads."
```

```PowerShell
cls
```

### # Configure "converged" logical switch

#### # Create logical switch

```PowerShell
$virtualSwitchExtensions = @()
$virtualSwitchExtensions += Get-SCVirtualSwitchExtension `
    -Name "Microsoft Windows Filtering Platform"

$logicalSwitch = New-SCLogicalSwitch `
    -Name "Embedded Team Switch" `
    -Description "" `
    -SwitchUplinkMode EmbeddedTeam `
    -MinimumBandwidthMode Weight `
    -VirtualSwitchExtensions $virtualSwitchExtensions
```

#### # Add virtual ports to logical switch

##### # Add "1 Gbps Tenant vNIC" virtual port (default)

```PowerShell
$portClassification = Get-SCPortClassification -Name "1 Gbps Tenant vNIC"

$networkAdapterPortProfile = Get-SCVirtualNetworkAdapterNativePortProfile `
    -Name "1 Gbps Tenant vNIC"

New-SCVirtualNetworkAdapterPortProfileSet `
    -Name $portClassification.Name `
    -PortClassification $portClassification `
    -LogicalSwitch $logicalSwitch `
    -IsDefaultPortProfileSet $true `
    -VirtualNetworkAdapterNativePortProfile $networkAdapterPortProfile
```

##### # Add "Host Cluster Workload" virtual port

```PowerShell
$portClassification = Get-SCPortClassification `
```

    -Name "Host Cluster Workload"

```PowerShell
$networkAdapterPortProfile = Get-SCVirtualNetworkAdapterNativePortProfile `
    -Name "Cluster"

New-SCVirtualNetworkAdapterPortProfileSet `
    -Name $portClassification.Name `
    -PortClassification $portClassification `
    -LogicalSwitch $logicalSwitch `
    -VirtualNetworkAdapterNativePortProfile $networkAdapterPortProfile
```

##### # Add "Host management" virtual port

```PowerShell
$portClassification = Get-SCPortClassification `
    -Name "Host management"

$networkAdapterPortProfile = Get-SCVirtualNetworkAdapterNativePortProfile `
    -Name "Host management"

New-SCVirtualNetworkAdapterPortProfileSet `
    -Name $portClassification.Name `
    -PortClassification $portClassification `
    -LogicalSwitch $logicalSwitch `
    -VirtualNetworkAdapterNativePortProfile $networkAdapterPortProfile
```

##### # Add "Host management and SMB Multichannel" virtual port

```PowerShell
$portClassification = Get-SCPortClassification `
```

    -Name "Host management and SMB Multichannel"

```PowerShell
$networkAdapterPortProfile = Get-SCVirtualNetworkAdapterNativePortProfile `
    -Name "Host management and SMB Multichannel"

New-SCVirtualNetworkAdapterPortProfileSet `
    -Name $portClassification.Name `
    -PortClassification $portClassification `
    -LogicalSwitch $logicalSwitch `
    -VirtualNetworkAdapterNativePortProfile $networkAdapterPortProfile
```

##### # Add "Live migration  workload" virtual port

```PowerShell
$portClassification = Get-SCPortClassification `
```

    -Name "Live migration  workload"

```PowerShell
$networkAdapterPortProfile = Get-SCVirtualNetworkAdapterNativePortProfile `
    -Name "Live migration"

New-SCVirtualNetworkAdapterPortProfileSet `
    -Name $portClassification.Name `
    -PortClassification $portClassification `
    -LogicalSwitch $logicalSwitch `
    -VirtualNetworkAdapterNativePortProfile $networkAdapterPortProfile
```

##### # Add "Live migration and SMB Multichannel" virtual port

```PowerShell
$portClassification = Get-SCPortClassification `
```

    -Name "Live migration and SMB Multichannel"

```PowerShell
$networkAdapterPortProfile = Get-SCVirtualNetworkAdapterNativePortProfile `
    -Name "Live migration and SMB Multichannel"

New-SCVirtualNetworkAdapterPortProfileSet `
    -Name $portClassification.Name `
    -PortClassification $portClassification `
    -LogicalSwitch $logicalSwitch `
    -VirtualNetworkAdapterNativePortProfile $networkAdapterPortProfile
```

##### # Add "SMB workload" virtual port

```PowerShell
$portClassification = Get-SCPortClassification -Name "SMB workload"

$networkAdapterPortProfile = Get-SCVirtualNetworkAdapterNativePortProfile `
    -Name "SMB"

New-SCVirtualNetworkAdapterPortProfileSet `
    -Name $portClassification.Name `
    -PortClassification $portClassification `
    -LogicalSwitch $logicalSwitch `
    -VirtualNetworkAdapterNativePortProfile $networkAdapterPortProfile
```

#### # Add virtual network adapters

```PowerShell
$uplinkPortProfile = Get-SCNativeUplinkPortProfile -Name "Trunk Uplink"

$uplinkPortProfileSet = New-SCUplinkPortProfileSet `
    -Name ("Trunk Uplink - " + $logicalSwitch.Name) `
    -LogicalSwitch $logicalSwitch `
    -NativeUplinkPortProfile $uplinkPortProfile
```

##### # Add virtual network adapter - Management

```PowerShell
$vmNetwork = Get-SCVMNetwork -Name 'Management VM Network'
$portClassification = Get-SCPortClassification `
    -Name 'Host management and SMB Multichannel'

New-SCLogicalSwitchVirtualNetworkAdapter `
    -Name "Management" `
    -UplinkPortProfileSet $uplinkPortProfileSet `
    -VMNetwork $vmNetwork `
    -PortClassification $portClassification `
    -IsUsedForHostManagement $true `
    -InheritsAddressFromPhysicalNetworkAdapter $true
```

##### # Add virtual network adapters - Storage 1 and Storage 2

```PowerShell
$vmNetwork = Get-SCVMNetwork "Storage VM Network"
$vmSubnet = Get-SCVMSubnet -Name "Storage VM Network_0"
$portClassification = Get-SCPortClassification -Name "SMB workload"
$ipV4Pool = Get-SCStaticIPAddressPool -Name "Storage Address Pool"

New-SCLogicalSwitchVirtualNetworkAdapter `
    -Name "Storage 1" `
    -UplinkPortProfileSet $uplinkPortProfileSet `
    -VMNetwork $vmNetwork `
    -VMSubnet $vmSubnet `
    -PortClassification $portClassification `
    -IPv4AddressType Static `
    -IPv4AddressPool $ipV4Pool

New-SCLogicalSwitchVirtualNetworkAdapter `
    -Name "Storage 2" `
    -UplinkPortProfileSet $uplinkPortProfileSet `
    -VMNetwork $vmNetwork `
    -VMSubnet $vmSubnet `
    -PortClassification $portClassification `
    -IPv4AddressType Static `
    -IPv4AddressPool $ipV4Pool
```

##### # Add virtual network adapter - Live Migration

```PowerShell
$vmNetwork = Get-SCVMNetwork "Live Migration VM Network"
$vmSubnet = Get-SCVMSubnet -Name "Live Migration VM Network_0"
$portClassification = Get-SCPortClassification `
    -Name "Live migration and SMB Multichannel"

$ipV4Pool = Get-SCStaticIPAddressPool -Name "Live Migration Address Pool"

New-SCLogicalSwitchVirtualNetworkAdapter `
    -Name "Live Migration" `
    -UplinkPortProfileSet $uplinkPortProfileSet `
    -VMNetwork $vmNetwork `
    -VMSubnet $vmSubnet `
    -PortClassification $portClassification `
    -IPv4AddressType Static `
    -IPv4AddressPool $ipV4Pool
```

##### # Add virtual network adapter - Cluster

```PowerShell
$vmNetwork = Get-SCVMNetwork "Cluster VM Network"
$vmSubnet = Get-SCVMSubnet -Name "Cluster VM Network_0"
$portClassification = Get-SCPortClassification `
    -Name "Host Cluster Workload"

$ipV4Pool = Get-SCStaticIPAddressPool -Name "Cluster Address Pool"

New-SCLogicalSwitchVirtualNetworkAdapter `
    -Name "Cluster" `
    -UplinkPortProfileSet $uplinkPortProfileSet `
    -VMNetwork $vmNetwork `
    -VMSubnet $vmSubnet `
    -PortClassification $portClassification `
    -IPv4AddressType Static `
    -IPv4AddressPool $ipV4Pool
```

```PowerShell
cls
```

## # Configure storage infrastructure

### # Create storage classifications

```PowerShell
New-SCStorageClassification -Name "Tenant Storage" -Description ""
New-SCStorageClassification -Name "Infrastructure Storage" -Description ""
New-SCStorageClassification -Name "Primary Pool" -Description ""

New-SCStorageClassification -Name "Gold" -Description ""
New-SCStorageClassification -Name "Silver" -Description ""
New-SCStorageClassification -Name "Bronze" -Description ""
```

### Configure file shares in VMM

#### Reference

**How to Add Windows File Server Shares in VMM**\
From <[https://technet.microsoft.com/en-us/library/jj860437(v=sc.12).aspx](https://technet.microsoft.com/en-us/library/jj860437(v=sc.12).aspx)>

```PowerShell
cls
```

#### # Create Run As Account for "VMM management" service account

```PowerShell
$displayName = "Service account for VMM - Management (TT-VMM01)"
$cred = Get-Credential -Message $displayName -UserName "TECHTOOLBOX\s-vmm01-mgmt"

New-SCRunAsAccount -Credential $cred -Name $displayName
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Add "VMM management" service account to Administrators group on SOFS nodes

```PowerShell
$command = "net localgroup Administrators TECHTOOLBOX\s-vmm01-mgmt /ADD"

$scriptBlock = [ScriptBlock]::Create($command)

@("TT-SOFS01A", "TT-SOFS01B") |
    ForEach-Object {
        Invoke-Command -ComputerName $_ -ScriptBlock $scriptBlock
    }
```

---

```PowerShell
cls
```

#### # Add file servers

```PowerShell
$runAsAccount = Get-SCRunAsAccount `
    -Name "Service account for VMM - Management (TT-VMM01)"
```

##### # Add Scale-Out File Server (TT-SOFS01)

```PowerShell
Add-SCStorageProvider `
    -ComputerName "TT-SOFS01-FC.corp.technologytoolbox.com" `
    -AddWindowsNativeWmiProvider `
    -Name "TT-SOFS01.corp.technologytoolbox.com" `
    -RunAsAccount $runAsAccount

Get-SCStorageArray -Name "Clustered Windows Storage on TT-SOFS01-FC" |
    Set-SCStorageArray -DiscoverPhysicalDisks
```

##### # Install VMM agent on SOFS nodes

```PowerShell
$FileServer = Get-SCStorageFileServer -Name 'TT-SOFS01.corp.technologytoolbox.com'

$Nodes = @("TT-SOFS01A.corp.technologytoolbox.com",
```

    "TT-SOFS01B.corp.technologytoolbox.com")

```PowerShell
Set-SCStorageFileServer -StorageFileServer $FileServer -AddExistingComputer $Nodes
```

#### # Configure file shares to be managed by VMM

##### # Configure "Silver" VM storage

```PowerShell
$fileServer = Get-SCStorageFileServer -Name 'TT-SOFS01.corp.technologytoolbox.com'

$fileShare = Get-SCStorageFileShare "VM-Storage-Silver"

$storageClassification = Get-SCStorageClassification -Name "Silver"

Set-SCStorageFileServer `
    -StorageFileServer $fileServer `
    -AddStorageFileShareToManagement $fileShare `
    -StorageClassificationAssociation $storageClassification
```

### Configure VMM library

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Create and share the VMM-Library folder

```PowerShell
Enter-PSSession TT-FS01
```

---

**TT-FS02**

##### # Create folder

```PowerShell
$folderName = "VMM-Library"
$path = "D:\Shares\$folderName"

New-Item -Path $path -ItemType Directory
```

##### # Remove "BUILTIN\\Users" permissions

```PowerShell
icacls $path /inheritance:d
icacls $path /remove:g "BUILTIN\Users"
```

#### # Grant VMM administrators full control

```PowerShell
icacls $path /grant '"VMM Admins":(OI)(CI)(F)'
```

##### # Share folder

```PowerShell
New-SmbShare `
    -Name $folderName `
    -Path $path `
    -CachingMode None `
    -FullAccess Everyone

exit
```

---

---

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Temporarily add "VMM management" service account to Administrators group on file server

```PowerShell
$command = "net localgroup Administrators TECHTOOLBOX\s-vmm01-mgmt /ADD"

$scriptBlock = [ScriptBlock]::Create($command)

@("TT-FS01") |
    ForEach-Object {
        Invoke-Command -ComputerName $_ -ScriptBlock $scriptBlock
    }
```

---

```PowerShell
cls
```

#### # Add library server

```PowerShell
$runAsAccount = Get-SCRunAsAccount `
    -Name "Service account for VMM - Management (TT-VMM01)"

$vmmMgmtCred = Get-Credential ($runAsAccount.Domain + "\" + $runAsAccount.UserName)

Add-SCLibraryServer `
    -ComputerName TT-FS01.corp.technologytoolbox.com `
    -Description "" `
    -Credential $vmmMgmtCred
```

#### # Set credentials to access remote files shares on library server

```PowerShell
$libraryServer = Get-SCLibraryServer -ComputerName 'TT-FS01.corp.technologytoolbox.com'

Set-SCLibraryServer `
    -LibraryServer $libraryServer `
    -LibraryServerManagementCredential $runAsAccount
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Grant VMM management account permissions on files shares

```PowerShell
Enter-PSSession TT-FS01
```

---

**TT-FS01**

```PowerShell
@("Products", "VM-Library", "VMM-Library") |
    ForEach-Object {
        $folderName = $_
        $path = "D:\Shares\$folderName"

        icacls $path /grant '"s-vmm01-mgmt":(OI)(CI)(RX)'
    }

exit
```

---

---

#### # Add library shares

```PowerShell
Add-SCLibraryShare `
    -SharePath "\\TT-FS01.corp.technologytoolbox.com\VMM-Library" `
    -Description "" `
    -AddDefaultResources

Add-SCLibraryShare `
    -SharePath "\\TT-FS01.corp.technologytoolbox.com\Products" `
    -Description ""

Add-SCLibraryShare `
    -SharePath "\\TT-FS01.corp.technologytoolbox.com\VM-Library" `
    -Description ""
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Remove "VMM management" service account from Administrators group on file server

```PowerShell
$command = "net localgroup Administrators TECHTOOLBOX\s-vmm01-mgmt /DELETE"

$scriptBlock = [ScriptBlock]::Create($command)

@("TT-FS01") |
    ForEach-Object {
        Invoke-Command -ComputerName $_ -ScriptBlock $scriptBlock
    }
```

---

```PowerShell
cls
```

## # Configure compute infrastructure

### # Create host groups in VMM

```PowerShell
New-SCVMHostGroup -Name Compute
New-SCVMHostGroup -Name Management
```

### Import Hyper-V hosts into VMM

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Add VMM administrators domain group and VMM management service account to Administrators group on Hyper-V servers

```PowerShell
$command = "
net localgroup Administrators 'TECHTOOLBOX\VMM Admins' /ADD

net localgroup Administrators TECHTOOLBOX\s-vmm01-mgmt /ADD
"

$scriptBlock = [ScriptBlock]::Create($command)

@("TT-HV02A", "TT-HV02B", "TT-HV02C", "TT-HV03") |
    ForEach-Object {
        Invoke-Command -ComputerName $_ -ScriptBlock $scriptBlock
    }
```

---

```PowerShell
cls
```

#### # Add Hyper-V compute cluster to VMM

```PowerShell
$runAsAccount = Get-SCRunAsAccount `
    -Name "Service account for VMM - Management (TT-VMM01)"

$hostGroup = Get-SCVMHostGroup -Name Compute

Add-SCVMHostCluster `
    -Name "TT-HV02-FC.corp.technologytoolbox.com" `
    -VMHostGroup $hostGroup `
    -Credential $runAsAccount
```

#### # Add Hyper-V management server to VMM

```PowerShell
$hostGroup = Get-SCVMHostGroup -Name Management

Add-SCVMHost `
    -ComputerName "TT-HV03.corp.technologytoolbox.com" `
    -VMHostGroup $hostGroup `
    -Credential $runAsAccount
```

#### # Add logical switch to Hyper-V host

```PowerShell
$vmHost = Get-SCVMHost -ComputerName TT-HV03.corp.technologytoolbox.com

$uplinkPortProfileSet = Get-SCUplinkPortProfileSet -Name "Trunk Uplink"

$teamNetworkAdapterA = Get-SCVMHostNetworkAdapter -VMHost $vmHost |
    ? { $_.ConnectionName -eq "Team 1A" }

Set-SCVMHostNetworkAdapter `
    -VMHostNetworkAdapter $teamNetworkAdapterA `
    -UplinkPortProfileSet $uplinkPortProfileSet

$teamNetworkAdapterB = Get-SCVMHostNetworkAdapter -VMHost $vmHost |
    ? { $_.ConnectionName -eq "Team 1B" }

Set-SCVMHostNetworkAdapter `
    -VMHostNetworkAdapter $teamNetworkAdapterB `
    -UplinkPortProfileSet $uplinkPortProfileSet

$networkAdapters = @($teamNetworkAdapterA, $teamNetworkAdapterB)

$logicalSwitch = Get-SCLogicalSwitch -Name "Team Switch"

New-SCVirtualNetwork `
    -VMHost $vmHost `
    -VMHostNetworkAdapters $networkAdapters `
    -LogicalSwitch $logicalSwitch `
    -DeployVirtualNetworkAdapters
```

> **Note**
>
> It may take a few minutes to configure the Hyper-V switches.

#### # Associate non-teamed adapters with logical network (e.g. Realtek PCIe GBE Family Controller on TT-HV03)

```PowerShell
$logicalNetwork = Get-SCLogicalNetwork -Name "Management"

@("TT-HV03.corp.technologytoolbox.com") |
    ForEach-Object {
        $vmHost = Get-SCVMHost -ComputerName $_

        $vmHostNetworkAdapter = Get-SCVMHostNetworkAdapter -VMHost $vmHost |
            ? { $_.UplinkPortProfileSet -eq $null }

        Set-SCVMHostNetworkAdapter `
            -VMHostNetworkAdapter $vmHostNetworkAdapter `
            -AddOrSetLogicalNetwork $logicalNetwork
    }
```

## # Configure network infrastructure for extranet

### # Connect to VMM server

```PowerShell
Get-SCVMMServer -ComputerName TT-VMM01
```

### # Configure network site and VM network for extranet

#### # Create network site for extranet

```PowerShell
$logicalNetwork = Get-SCLogicalNetwork -Name "Datacenter"

$hostGroups = @()
$hostGroups += Get-SCVMHostGroup -Name "All Hosts"

$subnetVlans = @()
$subnetVlans += New-SCSubnetVLan -Subnet "10.1.20.0/24" -VLanID 20

New-SCLogicalNetworkDefinition `
    -Name "Extranet - VLAN 20" `
    -LogicalNetwork $logicalNetwork `
    -VMHostGroup $hostGroups `
    -SubnetVLan $subnetVlans
```

#### # Create VM network for extranet

```PowerShell
$vmNetwork = New-SCVMNetwork `
    -Name "Extranet VM Network" `
    -IsolationType VLANNetwork `
    -LogicalNetwork $logicalNetwork

$logicalNetworkDefinition = Get-SCLogicalNetworkDefinition `
    -Name "Extranet - VLAN 20"

$subnetVLANs = @()

$subnetVLANs += (New-SCSubnetVLan -Subnet "10.1.20.0/24" -VLanID 20)

$vmSubnet = New-SCVMSubnet `
    -Name "Extranet VM Network_0" `
    -LogicalNetworkDefinition $logicalNetworkDefinition `
    -SubnetVLan $subnetVLANs `
    -VMNetwork $vmNetwork
```

#### # Create IP address pool for extranet network

```PowerShell
$logicalNetworkDefinition = Get-SCLogicalNetworkDefinition `
```

    -Name "Extranet - VLAN 20"

```PowerShell
$addressPoolName = "Extranet Address Pool"

$ipAddressRangeStart = "10.1.20.101"
$ipAddressRangeEnd = "10.1.20.254"

$vipAddresses = @("10.1.20.200-10.1.20.254")

$vipAddressSet = $vipAddresses -join ","

$reservedAddresses = @("10.1.20.103", "10.1.20.104")

$reservedAddressSet = $reservedAddresses -join ","

$subnet = "10.1.20.0/24"

$networkRoutes = @()

$gateways = @()
$gateways += New-SCDefaultGateway -IPAddress "10.1.20.1" -Automatic

$dnsServers = @("10.1.20.103", "10.1.20.104")

$dnsSuffix = "extranet.technologytoolbox.com"
$dnsSearchSuffixes = @()

$winsServers = @()

New-SCStaticIPAddressPool `
    -Name $addressPoolName `
    -LogicalNetworkDefinition $logicalNetworkDefinition `
    -Subnet $subnet `
    -IPAddressRangeStart $ipAddressRangeStart `
    -IPAddressRangeEnd $ipAddressRangeEnd `
    -DefaultGateway $gateways `
    -DNSServer $dnsServers `
    -DNSSuffix $dnsSuffix `
    -DNSSearchSuffix $dnsSearchSuffixes `
    -NetworkRoute $networkRoutes `
    -VIPAddressSet $vipAddressSet `
    -IPAddressReservedSet $reservedAddressSet
```

```PowerShell
cls
```

### # Add extranet network to "trunk" uplink port profile

```PowerShell
$logicalNetworkDefinition = Get-SCLogicalNetworkDefinition `
    -Name "Extranet - VLAN 20"

$uplinkPortProfile = Get-SCNativeUplinkPortProfile -Name "Trunk Uplink"

Set-SCNativeUplinkPortProfile `
    -NativeUplinkPortProfile $uplinkPortProfile `
    -AddLogicalNetworkDefinition $logicalNetworkDefinition
```

### # Add network adapter to "converged" logical switch

```PowerShell
$logicalSwitch = Get-SCLogicalSwitch -Name "Embedded Team Switch"

$uplinkPortProfileSet = Get-SCUplinkPortProfileSet `
    -Name "Trunk Uplink"

$vmNetwork = Get-SCVMNetwork "Extranet VM Network"
$vmSubnet = Get-SCVMSubnet -Name "Extranet VM Network_0"
$portClassification = Get-SCPortClassification `
    -Name "1 Gbps Tenant vNIC"

$ipV4Pool = Get-SCStaticIPAddressPool -Name "Extranet Address Pool"

New-SCLogicalSwitchVirtualNetworkAdapter `
    -Name "Extranet" `
    -UplinkPortProfileSet $uplinkPortProfileSet `
    -VMNetwork $vmNetwork `
    -VMSubnet $vmSubnet `
    -PortClassification $portClassification `
    -IPv4AddressType Static `
    -IPv4AddressPool $ipV4Pool

@("TT-HV02A.corp.technologytoolbox.com",
    "TT-HV02B.corp.technologytoolbox.com",
    "TT-HV02C.corp.technologytoolbox.com") |
    ForEach-Object {
        $vmHost = Get-SCVMHost -ComputerName $_

        New-SCVirtualNetworkAdapter `
            -VMHost $vmHost `
            -Name "Extranet" `
            -LogicalSwitch $logicalSwitch `
            -VMNetwork $vmNetwork `
            -VMSubnet $vmSubnet `
            -PortClassification $portClassification `
            -IPv4AddressType Static `
            -IPv4AddressPool $ipV4Pool
    }
```

## Configure NAS server (nas01.technologytoolbox.com)

### Create second storage VLAN

##### # Create network site for storage traffic

```PowerShell
$logicalNetwork = Get-SCLogicalNetwork -Name "Datacenter"

$hostGroups = @()
$hostGroups += Get-SCVMHostGroup -Name "All Hosts"

$subnetVlans = @()
$subnetVlans += New-SCSubnetVLan -Subnet "10.1.13.0/24" -VLanID 13

New-SCLogicalNetworkDefinition `
    -Name "Storage 2 - VLAN 13" `
    -LogicalNetwork $logicalNetwork `
    -VMHostGroup $hostGroups `
    -SubnetVLan $subnetVlans
```

##### # Add logical network definition to "Trunk Uplink" and "Storage Uplink" port profiles

```PowerShell
$logicalNetworkDefinition = Get-SCLogicalNetworkDefinition `
    -Name "Storage 2 - VLAN 13"

$portProfile = Get-SCNativeUplinkPortProfile -Name "Trunk Uplink"

Set-SCNativeUplinkPortProfile `
    -NativeUplinkPortProfile $portProfile `
    -AddLogicalNetworkDefinition $logicalNetworkDefinition

$portProfile = Get-SCNativeUplinkPortProfile -Name "Storage Uplink"

Set-SCNativeUplinkPortProfile `
    -NativeUplinkPortProfile $portProfile `
    -AddLogicalNetworkDefinition $logicalNetworkDefinition
```

#### # Create VM network for storage traffic

```PowerShell
$vmNetwork = New-SCVMNetwork `
    -Name "Storage 2 VM Network" `
    -IsolationType VLANNetwork `
    -LogicalNetwork $logicalNetwork

$logicalNetworkDefinition = Get-SCLogicalNetworkDefinition `
    -Name "Storage 2 - VLAN 13"

$subnetVLANs = @()
$subnetVLANs += (New-SCSubnetVLan -Subnet "10.1.13.0/24" -VLanID 13)

$vmSubnet = New-SCVMSubnet `
    -Name "Storage 2 VM Network_0" `
    -LogicalNetworkDefinition $logicalNetworkDefinition `
    -SubnetVLan $subnetVLANs `
    -VMNetwork $vmNetwork
```

#### # Create IP address pool for storage network

```PowerShell
$logicalNetworkDefinition = Get-SCLogicalNetworkDefinition `
```

    -Name "Storage 2 - VLAN 13"

```PowerShell
$addressPoolName = "Storage 2 Address Pool"

$ipAddressRangeStart = "10.1.13.20"
$ipAddressRangeEnd = "10.1.13.254"

$reservedAddresses = @()

$reservedAddressSet = $reservedAddresses -join ","

$subnet = "10.1.13.0/24"

$networkRoutes = @()

$gateways = @()
$gateways += New-SCDefaultGateway -IPAddress "10.1.13.1" -Automatic

$dnsServers = @("192.168.10.103", "192.168.10.104")

$dnsSuffix = ""
$dnsSearchSuffixes = @()

$winsServers = @()

New-SCStaticIPAddressPool `
    -Name $addressPoolName `
    -LogicalNetworkDefinition $logicalNetworkDefinition `
    -Subnet $subnet `
    -IPAddressRangeStart $ipAddressRangeStart `
    -IPAddressRangeEnd $ipAddressRangeEnd `
    -DefaultGateway $gateways `
    -DNSServer $dnsServers `
    -DNSSuffix $dnsSuffix `
    -DNSSearchSuffix $dnsSearchSuffixes `
    -NetworkRoute $networkRoutes `
    -IPAddressReservedSet $reservedAddressSet
```

## Configure Software Defined Networking (SDN)

### Create new VLAN for core infrastructure servers (e.g. domain controllers)

This is necessary because the current **Management** logical network was created with network virtualization enabled (and this cannot be disabled after a logical network is created). During the process of deploying SDN, errors occur due to the loss of connectivity to critical services (e.g. Active Directory) because VMs connected to the **Management** VM Network lose network connectivity after the **Microsoft Azure VFP Switch Extension** is enabled on the VM switches on the Hyper-V servers.

```PowerShell
cls
```

##### # Create network site for Production - VLAN 15 traffic

```PowerShell
$logicalNetwork = Get-SCLogicalNetwork -Name "Datacenter"

$hostGroups = @()
$hostGroups += Get-SCVMHostGroup -Name "All Hosts"

$subnetVlans = @()
$subnetVlans += New-SCSubnetVLan -Subnet "10.0.15.0/24" -VLanID 15

New-SCLogicalNetworkDefinition `
    -Name "Production - VLAN 15" `
    -LogicalNetwork $logicalNetwork `
    -VMHostGroup $hostGroups `
    -SubnetVLan $subnetVlans
```

##### # Add logical network definition to "Trunk Uplink" port profile

```PowerShell
$logicalNetworkDefinition = Get-SCLogicalNetworkDefinition `
    -Name "Production - VLAN 15"

$portProfile = Get-SCNativeUplinkPortProfile -Name "Trunk Uplink"

Set-SCNativeUplinkPortProfile `
    -NativeUplinkPortProfile $portProfile `
    -AddLogicalNetworkDefinition $logicalNetworkDefinition
```

#### # Create VM network for storage traffic

```PowerShell
$vmNetwork = New-SCVMNetwork `
    -Name "Production VM Network" `
    -IsolationType VLANNetwork `
    -LogicalNetwork $logicalNetwork

$subnetVLANs = @()
$subnetVLANs += (New-SCSubnetVLan -Subnet "10.0.15.0/24" -VLanID 15)

$vmSubnet = New-SCVMSubnet `
    -Name "Production VM Network_0" `
    -LogicalNetworkDefinition $logicalNetworkDefinition `
    -SubnetVLan $subnetVLANs `
    -VMNetwork $vmNetwork
```

#### # Create IP address pool for storage network

```PowerShell
$addressPoolName = "Production-15 Address Pool"

$ipAddressRangeStart = "10.0.15.101"
$ipAddressRangeEnd = "10.0.15.254"

$vipAddresses = @("10.0.15.231-10.0.15.254")

$vipAddressSet = $vipAddresses -join ","

$reservedAddresses = @()

$reservedAddressSet = $reservedAddresses -join ","

$subnet = "10.0.15.0/24"

$networkRoutes = @()

$gateways = @()
$gateways += New-SCDefaultGateway -IPAddress "10.0.15.1" -Automatic

$dnsServers = @("192.168.10.103", "192.168.10.104")

$dnsSuffix = "corp.technologytoolbox.com"
$dnsSearchSuffixes = @()

$winsServers = @()

New-SCStaticIPAddressPool `
    -Name $addressPoolName `
    -LogicalNetworkDefinition $logicalNetworkDefinition `
    -Subnet $subnet `
    -IPAddressRangeStart $ipAddressRangeStart `
    -IPAddressRangeEnd $ipAddressRangeEnd `
    -DefaultGateway $gateways `
    -DNSServer $dnsServers `
    -DNSSuffix $dnsSuffix `
    -DNSSearchSuffix $dnsSearchSuffixes `
    -NetworkRoute $networkRoutes `
    -VIPAddressSet $vipAddressSet `
    -IPAddressReservedSet $reservedAddressSet
```

---

**FOOBAR16**

```PowerShell
cls
```

#### # Create reverse lookup zones in DNS

```PowerShell
Add-DnsServerPrimaryZone `
    -ComputerName TT-DC08 `
    -NetworkID "10.0.15.0/24" `
    -ReplicationScope Forest
```

---

```PowerShell
cls
```

### # Configure "Management" network

#### # Create logical network for management traffic

```PowerShell
$logicalNetwork = New-SCLogicalNetwork `
    -Name "Management" `
    -LogicalNetworkDefinitionIsolation $false `
    -EnableNetworkVirtualization $false `
    -UseGRE $false `
    -IsPVLAN $false
```

#### # Create network site for management traffic

```PowerShell
$hostGroups = @()
$hostGroups += Get-SCVMHostGroup -Name "All Hosts"

$subnetVlans = @()
$subnetVlans += New-SCSubnetVLan -Subnet "10.1.30.0/24" -VLanID 30

New-SCLogicalNetworkDefinition `
    -Name "Management - VLAN 30" `
    -LogicalNetwork $logicalNetwork `
    -VMHostGroup $hostGroups `
    -SubnetVLan $subnetVlans
```

##### # Add logical network definition to "Trunk Uplink" port profile

```PowerShell
$logicalNetworkDefinition = Get-SCLogicalNetworkDefinition `
    -Name "Management - VLAN 30"

$portProfile = Get-SCNativeUplinkPortProfile -Name "Trunk Uplink"

Set-SCNativeUplinkPortProfile `
    -NativeUplinkPortProfile $portProfile `
    -AddLogicalNetworkDefinition $logicalNetworkDefinition
```

#### # Create VM network for management traffic

```PowerShell
New-SCVMNetwork `
    -Name "Management VM Network" `
    -IsolationType NoIsolation `
    -LogicalNetwork $logicalNetwork
```

```PowerShell
cls
```

#### # Create IP address pool for management network

```PowerShell
$logicalNetwork = Get-SCLogicalNetwork -Name "Management"

$logicalNetworkDefinition = Get-SCLogicalNetworkDefinition `
```

    -Name "Management - VLAN 30"

```PowerShell
$addressPoolName = "Management-30 Address Pool"

$ipAddressRangeStart = "10.1.30.101"
$ipAddressRangeEnd = "10.1.30.254"

$vipAddresses = @("10.1.30.231-10.1.30.254")

$vipAddressSet = $vipAddresses -join ","

$reservedAddresses = @()

$reservedAddressSet = $reservedAddresses -join ","

$subnet = "10.1.30.0/24"

$networkRoutes = @()

$gateways = @()
$gateways += New-SCDefaultGateway -IPAddress "10.1.30.1" -Automatic

$dnsServers = @("10.1.15.2", "10.1.15.3")

$dnsSuffix = "corp.technologytoolbox.com"
$dnsSearchSuffixes = @()

$winsServers = @()

New-SCStaticIPAddressPool `
    -Name $addressPoolName `
    -LogicalNetworkDefinition $logicalNetworkDefinition `
    -Subnet $subnet `
    -IPAddressRangeStart $ipAddressRangeStart `
    -IPAddressRangeEnd $ipAddressRangeEnd `
    -DefaultGateway $gateways `
    -DNSServer $dnsServers `
    -DNSSuffix $dnsSuffix `
    -DNSSearchSuffix $dnsSearchSuffixes `
    -NetworkRoute $networkRoutes `
    -VIPAddressSet $vipAddressSet `
    -IPAddressReservedSet $reservedAddressSet
```

```PowerShell
cls
```

### # Create new VLAN for Fabrikam servers

##### # Create network site for Fabrikam traffic

```PowerShell
$logicalNetwork = Get-SCLogicalNetwork -Name "Datacenter"

$hostGroups = @()
$hostGroups += Get-SCVMHostGroup -Name "All Hosts"

$subnetVlans = @()
$subnetVlans += New-SCSubnetVLan -Subnet "10.0.40.0/24" -VLanID 40

New-SCLogicalNetworkDefinition `
    -Name "Fabrikam - VLAN 40" `
    -LogicalNetwork $logicalNetwork `
    -VMHostGroup $hostGroups `
    -SubnetVLan $subnetVlans
```

##### # Add logical network definition to "Trunk Uplink" port profile

```PowerShell
$logicalNetworkDefinition = Get-SCLogicalNetworkDefinition `
    -Name "Fabrikam - VLAN 40"

$portProfile = Get-SCNativeUplinkPortProfile -Name "Trunk Uplink"

Set-SCNativeUplinkPortProfile `
    -NativeUplinkPortProfile $portProfile `
    -AddLogicalNetworkDefinition $logicalNetworkDefinition
```

#### # Create VM network for Fabrikam traffic

```PowerShell
$vmNetwork = New-SCVMNetwork `
    -Name "Fabrikam VM Network" `
    -IsolationType VLANNetwork `
    -LogicalNetwork $logicalNetwork

$subnetVLANs = @()
$subnetVLANs += (New-SCSubnetVLan -Subnet "10.0.40.0/24" -VLanID 40)

$vmSubnet = New-SCVMSubnet `
    -Name "Fabrikam VM Network_0" `
    -LogicalNetworkDefinition $logicalNetworkDefinition `
    -SubnetVLan $subnetVLANs `
    -VMNetwork $vmNetwork
```

#### # Create IP address pool for Fabrikam network

```PowerShell
$addressPoolName = "Fabrikam-40 Address Pool"

$ipAddressRangeStart = "10.0.40.101"
$ipAddressRangeEnd = "10.0.40.254"

$vipAddresses = @("10.0.40.200-10.0.40.254")

$vipAddressSet = $vipAddresses -join ","

$reservedAddresses = @()

$reservedAddressSet = $reservedAddresses -join ","

$subnet = "10.0.40.0/24"

$networkRoutes = @()

$gateways = @()
$gateways += New-SCDefaultGateway -IPAddress "10.0.40.1" -Automatic

$dnsServers = @("10.0.40.2", "10.0.40.3")

$dnsSuffix = "corp.fabrikam.com"
$dnsSearchSuffixes = @()

$winsServers = @()

New-SCStaticIPAddressPool `
    -Name $addressPoolName `
    -LogicalNetworkDefinition $logicalNetworkDefinition `
    -Subnet $subnet `
    -IPAddressRangeStart $ipAddressRangeStart `
    -IPAddressRangeEnd $ipAddressRangeEnd `
    -DefaultGateway $gateways `
    -DNSServer $dnsServers `
    -DNSSuffix $dnsSuffix `
    -DNSSearchSuffix $dnsSearchSuffixes `
    -NetworkRoute $networkRoutes `
    -VIPAddressSet $vipAddressSet `
    -IPAddressReservedSet $reservedAddressSet
```

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Move VM to new Production VM network

```PowerShell
$vmName = "TT-VMM01A"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName |
    where { $_.SlotId -eq 0 }

$vmNetwork = Get-SCVMNetwork -Name "Production VM Network"
$ipPool = Get-SCStaticIPAddressPool -Name "Production-15 Address Pool"

Stop-SCVirtualMachine $vmName

Start-Sleep -Seconds 60
```

> **Important**
>
> Verify the **TT-VMM01** cluster role fails over to **TT-VMM01B**.

```PowerShell
Read-SCVirtualMachine $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -MACAddressType Dynamic `
    -IPv4AddressType Dynamic

$vmNetwork = Get-SCVMNetwork -Name "Management VM Network"

$vm = Get-SCVirtualMachine $vmName

New-SCVirtualNetworkAdapter `
    -VM $vm `
    -VMNetwork $vmNetwork `
    -Synthetic

Start-SCVirtualMachine $vmName
```

### Update cluster resources

Change networks on IP Addresses for **TT-VMM01** and **TT-VMM01-FC**  to **10.1.15.0/24**.

```PowerShell
cls
```

### # Remove temporary VM network adapter

```PowerShell
$vmName = "TT-VMM01A"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName |
    where { $_.SlotId -eq 3 }

Stop-SCVirtualMachine $vmName

Remove-SCVirtualNetworkAdapter $networkAdapter

Start-SCVirtualMachine $vmName
```

---

```PowerShell
cls
```

### # Create new VLAN for Contoso servers

##### # Create network site for Contoso traffic

```PowerShell
$logicalNetwork = Get-SCLogicalNetwork -Name "Datacenter"

$hostGroups = @()
$hostGroups += Get-SCVMHostGroup -Name "All Hosts"

$subnetVlans = @()
$subnetVlans += New-SCSubnetVLan -Subnet "10.0.60.0/24" -VLanID 60

New-SCLogicalNetworkDefinition `
    -Name "Contoso - VLAN 60" `
    -LogicalNetwork $logicalNetwork `
    -VMHostGroup $hostGroups `
    -SubnetVLan $subnetVlans
```

##### # Add logical network definition to "Trunk Uplink" port profile

```PowerShell
$logicalNetworkDefinition = Get-SCLogicalNetworkDefinition `
    -Name "Contoso - VLAN 60"

$portProfile = Get-SCNativeUplinkPortProfile -Name "Trunk Uplink"

Set-SCNativeUplinkPortProfile `
    -NativeUplinkPortProfile $portProfile `
    -AddLogicalNetworkDefinition $logicalNetworkDefinition
```

#### # Create VM network for Contoso traffic

```PowerShell
$vmNetwork = New-SCVMNetwork `
    -Name "Contoso VM Network" `
    -IsolationType VLANNetwork `
    -LogicalNetwork $logicalNetwork

$subnetVLANs = @()
$subnetVLANs += (New-SCSubnetVLan -Subnet "10.0.60.0/24" -VLanID 60)

$vmSubnet = New-SCVMSubnet `
    -Name "Contoso VM Network_0" `
    -LogicalNetworkDefinition $logicalNetworkDefinition `
    -SubnetVLan $subnetVLANs `
    -VMNetwork $vmNetwork
```

#### # Create IP address pool for Contoso network

```PowerShell
$addressPoolName = "Contoso-60 Address Pool"

$ipAddressRangeStart = "10.0.60.101"
$ipAddressRangeEnd = "10.0.60.254"

$vipAddresses = @("10.0.60.200-10.0.60.254")

$vipAddressSet = $vipAddresses -join ","

$reservedAddresses = @()

$reservedAddressSet = $reservedAddresses -join ","

$subnet = "10.0.60.0/24"

$networkRoutes = @()

$gateways = @()
$gateways += New-SCDefaultGateway -IPAddress "10.0.60.1" -Automatic

$dnsServers = @("10.0.60.2", "10.0.60.3")

$dnsSuffix = "corp.contoso.com"
$dnsSearchSuffixes = @()

$winsServers = @()

New-SCStaticIPAddressPool `
    -Name $addressPoolName `
    -LogicalNetworkDefinition $logicalNetworkDefinition `
    -Subnet $subnet `
    -IPAddressRangeStart $ipAddressRangeStart `
    -IPAddressRangeEnd $ipAddressRangeEnd `
    -DefaultGateway $gateways `
    -DNSServer $dnsServers `
    -DNSSuffix $dnsSuffix `
    -DNSSearchSuffix $dnsSearchSuffixes `
    -NetworkRoute $networkRoutes `
    -VIPAddressSet $vipAddressSet `
    -IPAddressReservedSet $reservedAddressSet
```

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Move VM to new Management VM network

### # Configure network adapters on first cluster node

```PowerShell
$vmName = "TT-VMM01A"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName |
    where { $_.SlotId -eq 0 }

$vmNetwork = Get-SCVMNetwork -Name "Management VM Network"

Stop-SCVirtualMachine $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -MACAddressType Dynamic `
    -IPv4AddressType Dynamic

$vmNetwork = Get-SCVMNetwork -Name "Production VM Network"

$vm = Get-SCVirtualMachine $vmName

$networkAdapter = New-SCVirtualNetworkAdapter `
    -VM $vm `
    -VMNetwork $vmNetwork `
    -Synthetic

Start-SCVirtualMachine $vmName

Start-Sleep -Seconds 60
```

#### Move cluster role

> **Important**
>
> Verify the **TT-VMM01** cluster role fails over to **TT-VMM01B**.

### Configure network adapters on second cluster node

### Update cluster resources

Change networks on IP Addresses for **TT-VMM01** and **TT-VMM01-FC**  to **10.1.30.0/24**.

```PowerShell
cls
```

### # Clear DNS cache

#### # Clear DNS cache on localhost

```PowerShell
ipconfig /flushdns
```

#### # Clear DNS cache on servers

```PowerShell
$servers =  @(
    "TT-DPM02",
    "TT-SCOM03",
    "TT-VMM01A",
    "TT-VMM01B",
    "TT-WSUS03"
)

$servers |
    foreach {
        Invoke-Command -ScriptBlock { ipconfig /flushdns } -ComputerName $_
    }
```

### Remove temporary VM network adapters

#### Move cluster role

> **Important**
>
> Verify the **TT-VMM01** cluster role fails over to **TT-VMM01B**.

```PowerShell
cls
```

#### # Remove temporary VM network adapter on first cluster node

```PowerShell
$vmName = "TT-VMM01A"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName |
    where { $_.SlotId -eq 2 }

Stop-SCVirtualMachine $vmName

Remove-SCVirtualNetworkAdapter $networkAdapter

Start-SCVirtualMachine $vmName
```

---

```PowerShell
cls
```

#### # Create IP address pool for "Management - VLAN 0" network

```PowerShell
$logicalNetworkDefinition = Get-SCLogicalNetworkDefinition `
    -Name "Management - VLAN 0"

$addressPoolName = "Management-0 Address Pool"

$ipAddressRangeStart = "192.168.10.101"
$ipAddressRangeEnd = "192.168.10.254"

$vipAddresses = @("192.168.10.231-192.168.10.254")

$vipAddressSet = $vipAddresses -join ","

$reservedAddresses = @()

$reservedAddressSet = $reservedAddresses -join ","

$subnet = "192.168.10.0/24"

$networkRoutes = @()

$gateways = @()
$gateways += New-SCDefaultGateway -IPAddress "192.168.10.1" -Automatic

$dnsServers = @("10.1.30.2", "10.1.30.3")

$dnsSuffix = "corp.technologytoolbox.com"
$dnsSearchSuffixes = @()

$winsServers = @()

New-SCStaticIPAddressPool `
    -Name $addressPoolName `
    -LogicalNetworkDefinition $logicalNetworkDefinition `
    -Subnet $subnet `
    -IPAddressRangeStart $ipAddressRangeStart `
    -IPAddressRangeEnd $ipAddressRangeEnd `
    -DefaultGateway $gateways `
    -DNSServer $dnsServers `
    -DNSSuffix $dnsSuffix `
    -DNSSearchSuffix $dnsSearchSuffixes `
    -NetworkRoute $networkRoutes `
    -VIPAddressSet $vipAddressSet `
    -IPAddressReservedSet $reservedAddressSet
```

**TODO:**

#### # Associate network adapters with logical network

```PowerShell
@("TT-HV02A.corp.technologytoolbox.com",
    "TT-HV02B.corp.technologytoolbox.com",
    "TT-HV02C.corp.technologytoolbox.com",
    "TT-HV03.corp.technologytoolbox.com") |
    ForEach-Object {
        $vmHost = Get-SCVMHost -ComputerName $_

        $vmHostNetworkAdapter = Get-SCVMHostNetworkAdapter -VMHost $vmHost |
            ? { $_.ConnectionName -eq "Tenant Team" }

        $logicalNetwork = Get-SCLogicalNetwork -Name "Tenant Logical Network"

        Set-SCVMHostNetworkAdapter `
            -VMHostNetworkAdapter $vmHostNetworkAdapter `
            -AddOrSetLogicalNetwork $logicalNetwork
    }
```

```PowerShell
cls
```

## # Configure network virtualization

### # Configure TT-HV03 to run Windows Server Gateway VMs

#### # Specify this host is a dedicated network virtualization gateway, as a result it is not available for placement of virtual machines requiring network virtualization

```PowerShell
$vmHost = Get-SCVMHost -ComputerName TT-HV03.corp.technologytoolbox.com

Set-SCVMHost -VMHost $vmHost -IsDedicatedToNetworkVirtualizationGateway $true
```

### # Rename tenant VM network

```PowerShell
Get-SCVMNetwork -Name "Tenant VM Network" | select Name, LogicalNetwork

Name              LogicalNetwork
----              --------------
Tenant VM Network Datacenter Logical Network
Tenant VM Network Tenant Logical Network


Get-SCVMNetwork -Name "Tenant VM Network"  |
    ? { $_.LogicalNetwork -eq 'Tenant Logical Network' } |
    % {
        Set-SCVMNetwork -Name "Management VM Network" -VMNetwork $_
    }
```

### Configure forwarding gateway in VMM

#### Create forwarding gateway VM (TT-VM01)

#### Create Run As Account for "VMM setup account"

> **Note**
>
> Local admin rights are required on Hyper-V cluster to configure forwarding gateway.

```PowerShell
$displayName = "Setup account for Virtual Machine Manager"
$cred = Get-Credential -Message $displayName -UserName "TECHTOOLBOX\setup-vmm"

New-SCRunAsAccount -Credential $cred -Name $displayName
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Add VMM administrators group to local Administrators group on Hyper-V cluster node

```PowerShell
$command = "net localgroup Administrators 'TECHTOOLBOX\VMM Admins' /ADD"

$scriptBlock = [ScriptBlock]::Create($command)

@("TT-HV03") |
    ForEach-Object {
        Invoke-Command -ComputerName $_ -ScriptBlock $scriptBlock
    }
```

#### # Add VMM administrators group to local Administrators group on gateway cluster nodes

```PowerShell
$command = "net localgroup Administrators 'TECHTOOLBOX\VMM Admins' /ADD"

$scriptBlock = [ScriptBlock]::Create($command)

@("TT-GW01") |
    ForEach-Object {
        Invoke-Command -ComputerName $_ -ScriptBlock $scriptBlock
    }
```

---

```PowerShell
cls
```

#### # Create network service for forwarding gateway

```PowerShell
$runAsAccount = Get-SCRunAsAccount `
    -Name "Setup account for Virtual Machine Manager"

$configurationProvider = Get-SCConfigurationProvider `
    -Name "Microsoft Windows Server Gateway Provider"

$vmHostGroup = @()
$vmHostGroup += Get-SCVMHostGroup -Name "All Hosts"

$certificates = @()

$connectionString = `
    "VMHost=TT-HV03.corp.technologytoolbox.com;" `
    + "GatewayVM=TT-GW01.corp.technologytoolbox.com;" `
    + "BackendSwitch=Tenant Logical Switch;" `
    + "DirectRoutingMode=True;" `
    + "FrontEndServiceAddress=192.168.10.254"

Connection string:

VMHost=TT-HV03.corp.technologytoolbox.com;GatewayVM=TT-GW01.corp.technologytoolbox.com;BackendSwitch=Tenant Logical Switch;DirectRoutingMode=True;FrontEndServiceAddress=192.168.10.254


$networkService = Add-SCNetworkService `
    -Name "Windows Server Gateway - Forwarder" `
    -RunAsAccount $runAsAccount `
    -ConfigurationProvider $configurationProvider `
    -VMHostGroup $vmHostGroup `
    -ConnectionString $connectionString `
    -Certificate $certificates `
    -ProvisionSelfSignedCertificatesForNetworkService $true
```

\$runAsAccount = Get-SCRunAsAccount -ID "7e9daf4a-c271-4633-a5c4-e9d62c111298"\
# Get Configuration Provider 'Microsoft Windows Server Gateway Provider'\
\$configurationProvider = Get-SCConfigurationProvider -Name "Microsoft Windows Server Gateway Provider"\
\$vmHostGroup = @()\
\$vmHostGroup += Get-SCVMHostGroup -ID "0e3ba228-a059-46be-aa41-2f5cf0f4b96e"\
\$certificates = @()\
\$networkService = Add-SCNetworkService -Name "WSG" -RunAsAccount \$runAsAccount -ConfigurationProvider \$configurationProvider -VMHostGroup \$vmHostGroup -ConnectionString "VMHost=TT-HV03.corp.technologytoolbox.com;GatewayVM=TT-GW01.corp.technologytoolbox.com;BackendSwitch=Tenant Logical Switch;DirectRoutingMode=True;FrontEndServiceAddress=192.168.10.254" -RunAsynchronously -Certificate \$certificates -ProvisionSelfSignedCertificatesForNetworkService \$true\
\$networkServiceCapabilities = Get-SCNetworkServiceCapabilities -ConfigurationProvider \$configurationProvider -RunAsAccount \$runAsAccount -ConnectionString "VMHost=TT-HV03.corp.technologytoolbox.com;GatewayVM=TT-GW01.corp.technologytoolbox.com;BackendSwitch=Tenant Logical Switch;DirectRoutingMode=True;FrontEndServiceAddress=192.168.10.254"\
\$frontEndAdapter = \$networkServiceCapabilities.NetworkAdapters[1]\
# Get Logical Network Definition 'Tenant Network Site 0'\
\$frontEnd = Get-SCLogicalNetworkDefinition -ID "4a6792d1-d715-45ef-80e6-9c3ab88c95c2"\
Add-SCNetworkConnection -Name "Front End" -LogicalNetworkDefinition \$frontEnd -Service \$networkService -NetworkAdapter \$frontEndAdapter -ConnectionType "FrontEnd" -RunAsynchronously\
\$backEndAdapter = \$networkServiceCapabilities.NetworkAdapters[2]\
# Get Logical Network Definition 'Tenant Network Site 0'\
\$backEnd = Get-SCLogicalNetworkDefinition -ID "4a6792d1-d715-45ef-80e6-9c3ab88c95c2"\
Add-SCNetworkConnection -Name "Back End" -LogicalNetworkDefinition \$backEnd -Service \$networkService -NetworkAdapter \$backEndAdapter -ConnectionType "BackEnd" -RunAsynchronously

#### # Configure "front end network"

```PowerShell
$networkServiceCapabilities = Get-SCNetworkServiceCapabilities `
    -ConnectionString $connectionString `
    -ConfigurationProvider $configurationProvider `
    -RunAsAccount $runAsAccount

$frontEndAdapter = $networkServiceCapabilities.NetworkAdapters |
    ? { $_.AdapterName -eq "Datacenter 1" }

$frontEndLogicalNetwork = Get-SCLogicalNetworkDefinition -Name "Tenant Network Site 0"

Add-SCNetworkConnection `
    -Service $networkService `
    -ConnectionType FrontEnd `
    -LogicalNetworkDefinition $frontEndLogicalNetwork `
    -NetworkAdapter $frontEndAdapter `
    -Name "Front End"
```

#### # Configure "back end network"

```PowerShell
$backEndAdapter = $networkServiceCapabilities.NetworkAdapters |
    ? { $_.AdapterName -eq "Back end (network virtualization)" }

$backEndLogicalNetwork = Get-SCLogicalNetworkDefinition -Name "Tenant Network Site 0"

Add-SCNetworkConnection `
    -Service $networkService `
    -ConnectionType BackEnd `
    -LogicalNetworkDefinition $backEndLogicalNetwork `
    -NetworkAdapter $backEndAdapter `
    -Name "Back End"

Add-SCNetworkConnection : Execution of Microsoft.SystemCenter.NetworkService::InstallDeviceConnection on the
configuration provider 4ee559f1-f479-480c-9458-d14b8b1c1779 failed. Detailed exception:
Microsoft.VirtualManager.Utils.CarmineException: Unable to set up Remote Access server to support multi-tenancy mode.
The back end network adapter for Hyper-V Network Virtualization on host TT-HV03.corp.technologytoolbox.com is neither
connected to any virtual switch nor switch name provided in connection string.
Connect the VM network adapter to a switch, or specify the switch name in connection string using
BackendSwitch=SwitchName.
Fix the issue in Remote Access server and retry the operation. (Error ID: 21426)

Check the documentation for the configuration provider or contact the publisher support.

To restart the job, run the following command:
PS> Restart-Job -Job (Get-VMMServer tt-vmm01 | Get-Job | where { $_.ID -eq "{3e9b7887-2c10-4920-b6e1-46e21658d50d}"})
At line:1 char:1
+ Add-SCNetworkConnection `
+ ~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : ReadError: (:) [Add-SCNetworkConnection], CarmineException
    + FullyQualifiedErrorId : 21426,Microsoft.SystemCenter.VirtualMachineManager.Cmdlets.AddSCNetworkServiceConnection
   Cmdlet
```

```PowerShell
cls
```

### # Create a VM network and virtual subnets

#### # Create subnets

```PowerShell
$logicalNetwork = Get-SCLogicalNetwork -Name "Tenant Logical Network"

$vmNetwork = New-SCVMNetwork -Name "CorpNet" -LogicalNetwork $logicalNetwork -IsolationType WindowsNetworkVirtualization -CAIPAddressPoolType IPV4 -PAIPAddressPoolType IPV4

Write-Output $vmNetwork

$subnet = New-SCSubnetVLan -Subnet "10.10.3.0/24"
New-SCVMSubnet -Name "Accounting Subnet" -VMNetwork $vmNetwork -SubnetVLan $subnet

$subnet = New-SCSubnetVLan -Subnet "10.10.4.0/24"
New-SCVMSubnet -Name "HR Subnet" -VMNetwork $vmNetwork -SubnetVLan $subnet

$gatewayDevice = Get-SCNetworkGateway -Name "Windows Server Gateway - Forwarder"

$VmNetworkGateway = Add-SCVMNetworkGateway -Name "CorpNet_Gateway" -EnableBGP $false -NetworkGateway $gatewayDevice -VMNetwork $vmNetwork
```

#### # Create IP pool for Accounting subnet

```PowerShell
$vmSubnet = Get-SCVMSubnet -Name "Accounting Subnet"

$gateways = @()
$gateways += New-SCDefaultGateway -IPAddress "10.10.3.1" -Automatic

$dnsServers = @("192.168.10.103", "192.168.10.104")

New-SCStaticIPAddressPool `
    -Name "Accounting IP Pool" `
    -VMSubnet $vmSubnet `
    -Subnet "10.10.3.0/24" `
    -IPAddressRangeStart "10.10.3.2" `
    -IPAddressRangeEnd "10.10.3.254" `
    -DefaultGateway $gateways `
    -DNSServer $dnsServers
```

#### # Create IP pool for HR subnet

```PowerShell
$vmSubnet = Get-SCVMSubnet -Name "HR Subnet"

$gateways = @()
$gateways += New-SCDefaultGateway -IPAddress "10.10.4.1" -Automatic

$dnsServers = @("192.168.10.103", "192.168.10.104")

New-SCStaticIPAddressPool `
    -Name "HR IP Pool" `
    -VMSubnet $vmSubnet `
    -Subnet "10.10.4.0/24" `
    -IPAddressRangeStart "10.10.4.2" `
    -IPAddressRangeEnd "10.10.4.254" `
    -DefaultGateway $gateways `
    -DNSServer $dnsServers
```

```PowerShell
cls
```

### # Create Accounting and HR VMs

#### Create VM template

```PowerShell
New-SCVirtualScsiAdapter -VMMServer tt-vmm01 -JobGroup 5d824475-d403-4920-a2dd-4e8ad08a4064 -AdapterID 7 -ShareVirtualScsiAdapter $false -ScsiControllerType DefaultTypeNoType


New-SCVirtualDVDDrive -VMMServer tt-vmm01 -JobGroup 5d824475-d403-4920-a2dd-4e8ad08a4064 -Bus 1 -LUN 0


New-SCVirtualNetworkAdapter -VMMServer tt-vmm01 -JobGroup 5d824475-d403-4920-a2dd-4e8ad08a4064 -MACAddressType Dynamic -Synthetic -IPv4AddressType Dynamic -IPv6AddressType Dynamic


Set-SCVirtualCOMPort -NoAttach -VMMServer tt-vmm01 -GuestPort 1 -JobGroup 5d824475-d403-4920-a2dd-4e8ad08a4064


Set-SCVirtualCOMPort -NoAttach -VMMServer tt-vmm01 -GuestPort 2 -JobGroup 5d824475-d403-4920-a2dd-4e8ad08a4064


Set-SCVirtualFloppyDrive -RunAsynchronously -VMMServer tt-vmm01 -NoMedia -JobGroup 5d824475-d403-4920-a2dd-4e8ad08a4064

$CPUType = Get-SCCPUType -VMMServer tt-vmm01 | where {$_.Name -eq "3.60 GHz Xeon (2 MB L2 cache)"}

New-SCHardwareProfile -VMMServer tt-vmm01 -CPUType $CPUType -Name "Profiled69d85d0-0130-41be-aa3e-b9bbb37da53c" -Description "Profile used to create a VM/Template" -CPUCount 2 -MemoryMB 2048 -DynamicMemoryEnabled $true -DynamicMemoryMinimumMB 1024 -DynamicMemoryMaximumMB 4096 -DynamicMemoryBufferPercentage 20 -MemoryWeight 5000 -VirtualVideoAdapterEnabled $false -CPUExpectedUtilizationPercent 20 -DiskIops 0 -CPUMaximumPercent 100 -CPUReserve 0 -NumaIsolationRequired $false -NetworkUtilizationMbps 0 -CPURelativeWeight 100 -HighlyAvailable $false -DRProtectionRequired $false -CPULimitFunctionality $false -CPULimitForMigration $false -CheckpointType Production -Generation 1 -JobGroup 5d824475-d403-4920-a2dd-4e8ad08a4064



$StorageClassification = Get-SCStorageClassification -VMMServer tt-vmm01 | where {$_.Name -eq "Local Storage"}
$VirtualHardDisk = Get-SCVirtualHardDisk -VMMServer tt-vmm01 | where {$_.Location -eq "\\TT-FS01.corp.technologytoolbox.com\VM-Library\VHDs\WS2016-Std.vhdx"} | where {$_.HostName -eq "TT-FS01.corp.technologytoolbox.com"}

New-SCVirtualDiskDrive -VMMServer tt-vmm01 -IDE -Bus 0 -LUN 0 -StorageClassification $StorageClassification -JobGroup cfdc8c88-1702-4dff-b58c-5d4746938e36 -CreateDiffDisk $false -VirtualHardDisk $VirtualHardDisk -VolumeType BootAndSystem

$HardwareProfile = Get-SCHardwareProfile -VMMServer tt-vmm01 | where {$_.Name -eq "Profiled69d85d0-0130-41be-aa3e-b9bbb37da53c"}
$LocalAdministratorCredential = get-credential

$OperatingSystem = Get-SCOperatingSystem -VMMServer tt-vmm01 -ID "b808453f-f2b5-451f-894f-001c49db255a" | where {$_.Name -eq "Windows Server 2016 Standard"}

$template = New-SCVMTemplate -Name "Windows Server 2016 Standard (Desktop Experience)" -RunAsynchronously -Generation 1 -HardwareProfile $HardwareProfile -JobGroup cfdc8c88-1702-4dff-b58c-5d4746938e36 -ComputerName "*" -TimeZone 10 -LocalAdministratorCredential $LocalAdministratorCredential  -FullName "" -OrganizationName "" -Workgroup "WORKGROUP" -AnswerFile $null -OperatingSystem $OperatingSystem
```

#### Create VM - ACCT01

```PowerShell
# ------------------------------------------------------------------------------
# Create Virtual Machine Wizard Script
# ------------------------------------------------------------------------------
# Script generated on Wednesday, January 18, 2017 5:00:15 AM by Virtual Machine Manager
#
# For additional help on cmdlet usage, type get-help <cmdlet name>
# ------------------------------------------------------------------------------


New-SCVirtualScsiAdapter -VMMServer tt-vmm01 -JobGroup 294a661b-54cf-45a6-bd6b-d0b954cb4b67 -AdapterID 7 -ShareVirtualScsiAdapter $false -ScsiControllerType DefaultTypeNoType


New-SCVirtualDVDDrive -VMMServer tt-vmm01 -JobGroup 294a661b-54cf-45a6-bd6b-d0b954cb4b67 -Bus 1 -LUN 0

$VMSubnet = Get-SCVMSubnet -VMMServer tt-vmm01 -Name "Accounting Subnet" | where {$_.VMNetwork.ID -eq "81d4545e-ad3f-4aa5-b5ec-081302606c81"}
$VMNetwork = Get-SCVMNetwork -VMMServer tt-vmm01 -Name "CorpNet" -ID "81d4545e-ad3f-4aa5-b5ec-081302606c81"

New-SCVirtualNetworkAdapter -VMMServer tt-vmm01 -JobGroup 294a661b-54cf-45a6-bd6b-d0b954cb4b67 -MACAddress "00:00:00:00:00:00" -MACAddressType Static -Synthetic -EnableVMNetworkOptimization $false -EnableMACAddressSpoofing $false -EnableGuestIPNetworkVirtualizationUpdates $false -IPv4AddressType Static -IPv6AddressType Dynamic -VMSubnet $VMSubnet -VMNetwork $VMNetwork


Set-SCVirtualCOMPort -NoAttach -VMMServer tt-vmm01 -GuestPort 1 -JobGroup 294a661b-54cf-45a6-bd6b-d0b954cb4b67


Set-SCVirtualCOMPort -NoAttach -VMMServer tt-vmm01 -GuestPort 2 -JobGroup 294a661b-54cf-45a6-bd6b-d0b954cb4b67


Set-SCVirtualFloppyDrive -RunAsynchronously -VMMServer tt-vmm01 -NoMedia -JobGroup 294a661b-54cf-45a6-bd6b-d0b954cb4b67

$CPUType = Get-SCCPUType -VMMServer tt-vmm01 | where {$_.Name -eq "3.60 GHz Xeon (2 MB L2 cache)"}

New-SCHardwareProfile -VMMServer tt-vmm01 -CPUType $CPUType -Name "Profiled0753748-ceee-49a5-a84e-48a24a2d0a49" -Description "Profile used to create a VM/Template" -CPUCount 2 -MemoryMB 2048 -DynamicMemoryEnabled $true -DynamicMemoryMinimumMB 1024 -DynamicMemoryMaximumMB 4096 -DynamicMemoryBufferPercentage 20 -MemoryWeight 5000 -VirtualVideoAdapterEnabled $false -CPUExpectedUtilizationPercent 20 -DiskIops 0 -CPUMaximumPercent 100 -CPUReserve 0 -NumaIsolationRequired $false -NetworkUtilizationMbps 0 -CPURelativeWeight 100 -HighlyAvailable $false -DRProtectionRequired $false -CPULimitFunctionality $false -CPULimitForMigration $false -CheckpointType Production -Generation 1 -JobGroup 294a661b-54cf-45a6-bd6b-d0b954cb4b67



$Template = Get-SCVMTemplate -VMMServer tt-vmm01 -ID "ec25a5d3-1072-4531-ba79-2e891824985f" | where {$_.Name -eq "Windows Server 2016 Standard (Desktop Experience)"}
$HardwareProfile = Get-SCHardwareProfile -VMMServer tt-vmm01 | where {$_.Name -eq "Profiled0753748-ceee-49a5-a84e-48a24a2d0a49"}

$OperatingSystem = Get-SCOperatingSystem -VMMServer tt-vmm01 -ID "b808453f-f2b5-451f-894f-001c49db255a" | where {$_.Name -eq "Windows Server 2016 Standard"}

New-SCVMTemplate -Name "Temporary Template9c396dc8-adc9-4fc5-a34d-bb58c118df6c" -Template $Template -HardwareProfile $HardwareProfile -JobGroup b21b42c3-f704-4985-ae78-f89c60ffa565 -ComputerName "ACCT01" -TimeZone 10  -Workgroup "WORKGROUP" -AnswerFile $null -OperatingSystem $OperatingSystem



$template = Get-SCVMTemplate -All | where { $_.Name -eq "Temporary Template9c396dc8-adc9-4fc5-a34d-bb58c118df6c" }
$virtualMachineConfiguration = New-SCVMConfiguration -VMTemplate $template -Name "ACCT01"
Write-Output $virtualMachineConfiguration
$vmHost = Get-SCVMHost -ID "c18c97b2-84c4-45d9-9c17-d5699824d76f"
Set-SCVMConfiguration -VMConfiguration $virtualMachineConfiguration -VMHost $vmHost
Update-SCVMConfiguration -VMConfiguration $virtualMachineConfiguration

$AllNICConfigurations = Get-SCVirtualNetworkAdapterConfiguration -VMConfiguration $virtualMachineConfiguration



Update-SCVMConfiguration -VMConfiguration $virtualMachineConfiguration
New-SCVirtualMachine -Name "ACCT01" -VMConfiguration $virtualMachineConfiguration -Description "" -BlockDynamicOptimization $false -StartVM -JobGroup "b21b42c3-f704-4985-ae78-f89c60ffa565" -ReturnImmediately -StartAction "NeverAutoTurnOnVM" -StopAction "SaveVM"
```

**TODO:**

```PowerShell
cls
```

### # Set Host Access Account on Hyper-V hosts

```PowerShell
$hostManagementAccount = Get-SCRunAsAccount -Name $displayName

Get-SCVMHost |
    ForEach-Object {
        Set-SCVMHost -VMHost $_ -VMHostManagementCredential $hostManagementAccount
    }
```

```PowerShell
cls
```

### # Add files shares to Hyper-V hosts

```PowerShell
@("VM-Storage-Gold", "VM-Storage-Silver", "VM-Storage-Bronze") |
    ForEach-Object {
        $fileShare = Get-SCStorageFileShare -Name $_

        Get-SCVMHost |
            ForEach-Object {
                Register-SCStorageFileShare -StorageFileShare $fileShare -VMHost $_
            }
    }
```

---

**TT-VMM01B**

## # Reconfigure "Cluster" network adapter

```PowerShell
$vm = Get-SCVirtualMachine TT-VMM01A

Stop-SCVirtualMachine $vm

$networkAdapter =  Get-SCVirtualNetworkAdapter -VM $vm |
    ? { $_.SlotId -eq 1 }
```

### # Connect network adapter to Cluster VM Network

```PowerShell
$vmNetwork = Get-SCVMNetwork -Name "Cluster VM Network"

$vmSubnet = $vmNetwork.VMSubnet[0]

$portClassification = Get-SCPortClassification -Name "Host Cluster Workload"

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VirtualNetwork "Embedded Team Switch" `
    -PortClassification $portClassification `
    -VMNetwork $vmNetwork `
    -VMSubnet $vmSubnet
```

### # Assign static IP address to network adapter for cluster traffic

```PowerShell
$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"

$ipAddressPool = Get-SCStaticIPAddressPool -Name "Cluster Address Pool"

$macAddress = Grant-SCMACAddress `
    -MACAddressPool $macAddressPool `
    -Description $vm.Name `
    -VirtualNetworkAdapter $networkAdapter

$ipAddress = Grant-SCIPAddress `
    -GrantToObjectType VirtualNetworkAdapter `
    -GrantToObjectID $networkAdapter.ID `
    -StaticIPAddressPool $ipAddressPool `
    -Description $vm.Name

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -MACAddressType Static `
    -MACAddress $macAddress `
    -IPv4AddressType Static `
    -IPv4Address $ipAddress

Start-SCVirtualMachine $vm
```

---

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

```Console
cls
```

## # Install SCOM agent

```PowerShell
$imagePath = '\\TT-FS01\Products\Microsoft\System Center 2012 R2' `
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

```PowerShell
cls
```

### # Add "VMM management" service account to Administrators group on file servers

```PowerShell
$command = "net localgroup Administrators TECHTOOLBOX\s-vmm01-mgmt /ADD"

$scriptBlock = [ScriptBlock]::Create($command)

@("TT-FS01") |
    ForEach-Object {
        Invoke-Command -ComputerName $_ -ScriptBlock $scriptBlock
    }
```

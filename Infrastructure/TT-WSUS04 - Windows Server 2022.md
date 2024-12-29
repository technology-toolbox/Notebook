# TT-WSUS04 - Windows Server 2022 Standard Edition

Saturday, December 3, 2022\
6:38 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

Reference:

**Deploy Windows Server Update Services**\
From <[https://learn.microsoft.com/en-us/windows-server/administration/windows-server-update-services/deploy/deploy-windows-server-update-services](https://learn.microsoft.com/en-us/windows-server/administration/windows-server-update-services/deploy/deploy-windows-server-update-services)>

## Plan WSUS deployment

## Step 0: Deploy and configure server infrastructure

---

**TT-ADMIN05** - Run as administrator

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05F"
$vmName = "TT-WSUS04"
$vmPath = "E:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

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
    -ProcessorCount 2 `
    -DynamicMemory `
    -MemoryMinimumBytes 4GB `
    -MemoryMaximumBytes 8GB `
    -AutomaticCheckpointsEnabled $false

Set-VMNetworkAdapterVlan `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Access `
    -VlanId 30

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Install custom Windows Server 2022 image

- On the **Task Sequence** step, select **Windows Server 2022** and click
  **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **TT-WSUS04**.
  - Click **Next**.
- On the **Applications** step, do not select any applications, and click
  **Next**.

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

### Login using local administrator account (**.\\foo**)

### # Set first boot device to hard drive

```PowerShell
$vmHost = "TT-HV05F"

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

### # Move computer to different OU

```PowerShell
$targetPath = "OU=Windows Update Servers,OU=Servers,OU=Resources," `
    + "OU=Information Technology,DC=corp,DC=technologytoolbox,DC=com"

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

### # Configure Windows Update

```PowerShell
# Add machine to security group for Windows Update schedule
Add-ADGroupMember -Identity "Windows Update - Slot 9" -Members ($vmName + '$')
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

**TT-ADMIN05** - Run as administrator

```PowerShell
cls
```

```PowerShell
# Configure static IP address using VMM

$vmName = "TT-WSUS04"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Management VM Network"
$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"
$ipPool = Get-SCStaticIPAddressPool -Name "Management-30 Address Pool"

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
| 1    | D:           | 150 GB      | 4K                   | Data01       |

#### Configure separate VHD for WSUS content

---

**TT-ADMIN05** - Run as administrator

```PowerShell
cls
```

##### # Add disk for WSUS content

```PowerShell
$vmHost = "TT-HV05F"
$vmName = "TT-WSUS04"

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 150GB
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

##### # Initialize disks and format volumes

```PowerShell
Get-Disk 1 |
    Initialize-Disk -PartitionStyle GPT -PassThru |
    New-Partition -UseMaximumSize -DriveLetter D |
    Format-Volume `
        -FileSystem NTFS `
        -NewFileSystemLabel "Data01" `
        -Confirm:$false
```

---

**TT-ADMIN05** - Run as administrator

```PowerShell
cls
```

### # Make virtual machine highly available

```PowerShell
$vmName = "TT-WSUS04"
```

#### # Migrate VM to shared storage

```PowerShell
$vm = Get-SCVirtualMachine -Name $vmName
$vmHost = $vm.VMHost

Move-SCVirtualMachine `
    -VM $vm `
    -VMHost $vmHost `
    -HighlyAvailable $true `
    -Path "C:\ClusterStorage\iscsi02-Silver-02" `
    -UseDiffDiskOptimization
```

#### # Allow migration to host with different processor version

```PowerShell
Stop-SCVirtualMachine -VM $vmName

Set-SCVirtualMachine -VM $vmName -CPULimitForMigration $true

Start-SCVirtualMachine -VM $vmName
```

---

### Configure backup

#### Add virtual machine to Hyper-V protection group in DPM

```PowerShell
cls
```

### # Configure monitoring

#### # Install Operations Manager agent

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\System Center 2019\SCOM\agent" `
    + "\AMD64\MOMAgent.msi"

$installerArguments = "MANAGEMENT_GROUP=HQ" `
    + " MANAGEMENT_SERVER_DNS=TT-SCOM01C" `
    + " ACTIONS_USE_COMPUTER_ACCOUNT=1"

Start-Process `
    -FilePath msiexec.exe `
    -ArgumentList "/i `"$installerPath`" $installerArguments" `
    -Wait
```

#### Approve manual agent install in Operations Manager

```PowerShell
cls
```

#### # Enable performance counters for Server Manager

```PowerShell
$taskName = "\Microsoft\Windows\PLA\Server Manager Performance Monitor"

Enable-ScheduledTask -TaskName $taskName

logman start "Server Manager Performance Monitor"
```

---

**TT-ADMIN05** - Run as administrator

```PowerShell
cls

$vmName = "TT-WSUS04"
```

### Install and configure prerequisites for WSUS

> **Note**
>
> The WSUS console requires Report Viewer 2012 (which in turn requires System
> CLR Types for SQL Server 2012).

```PowerShell
cls
```

#### # Install System CLR Types for SQL Server 2012

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\System Center 2012 R2" `
    + "\Microsoft System CLR Types for SQL Server 2012\SQLSysClrTypes.msi"

Start-Process `
    -FilePath $installerPath `
    -Wait
```

```PowerShell
cls
```

#### # Install Report Viewer 2012

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\Report Viewer 2012 Runtime" `
    + "\ReportViewer.msi"

Start-Process `
    -FilePath $installerPath `
    -Wait
```

> **Note**
>
> The scheduled task for updating WSUS computer operating systems requires the
> SQL Server PowerShell module.

```PowerShell
cls
```

### # Install SQL Server PowerShell module

```PowerShell
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

Install-Module SqlServer -MinimumVersion 16.5.0
```

## Step 1: Install WSUS Server Role

Reference:

**Step 1: Install the WSUS Server Role**\
From <[https://learn.microsoft.com/en-us/windows-server/administration/windows-server-update-services/deploy/1-install-the-wsus-server-role](https://learn.microsoft.com/en-us/windows-server/administration/windows-server-update-services/deploy/1-install-the-wsus-server-role)>

**To install the WSUS server role:**

1. In **Server Manager**, click **Manage**, and then click **Add Roles and
   Features**.
2. On the **Before you begin** page, click **Next**.
3. On the **Select installation type** page, confirm the **Role-based or
   feature-based installation** option is selected and click **Next**.
4. On the **Select destination server** page:
   1. Ensure the **Select a server from the server pool** option is selected.
   2. In the **Server Pool** list, select the server for the WSUS server role.
   3. Click **Next**.
5. On the **Select server roles** page:
   1. Select **Windows Server Update Services**.
   2. A dialog window opens for adding the features required for WSUS. Click
      **Add Features**.
   3. Click **Next**.
6. On the **Select features** page, click **Next**.
7. On the **Windows Server Update Services** page, click **Next**.
8. On the **Select role services** page:
   1. Clear the **WID Connectivity** checkbox.
   2. Ensure the **WSUS Services** checkbox is selected.
   3. Select the **SQL Server Connectivity** checkbox.
   4. Click **Next**.
9. On the **Content location selection** page:
   1. Ensure the **Store updates in the following location** checkbox is
      selected.
   2. In the location box, type **D:\\WSUS**.
   3. Click **Next**.
10. On the **Database Instance Selection** page:
    1. In the **Specify an existing database server** box, type **TT-SQL01**.
    2. Click **Check connection** and confirm the wizard is able to successfully
       connect to the server.
    3. Click **Next**.
11. On the **Web Server Role (IIS)** page, review the information, and then
    click **Next**.
12. On the **Select roles services** page, click **Next**.
13. On the **Confirm installation selections** page, review the selected
    options, and click **Install**. The WSUS installation wizard runs. This
    might take several minutes to complete.
14. Wait for the WSUS installation to complete.
15. In the summary window on the **Installation progress** page, click **Launch
    Post-Installation tasks**. The text changes to: **Please wait while your
    server is configured**.
16. When the task has finished, the text changes to: **Configuration
    successfully completed**. Click **Close**.
17. In **Server Manager**, verify if a notification appears to inform you that a
    restart is required. This can vary according to the installed server role.
    If it requires a restart make sure to restart the server to complete the
    installation.

## Step 2: Configure WSUS

References:

**Step 2: Configure WSUS**\
From <[https://learn.microsoft.com/en-us/windows-server/administration/windows-server-update-services/deploy/2-configure-wsus](https://learn.microsoft.com/en-us/windows-server/administration/windows-server-update-services/deploy/2-configure-wsus)>

**Create custom indexes in WSUS database**\
From <[https://learn.microsoft.com/en-us/troubleshoot/mem/configmgr/update-management/wsus-maintenance-guide#create-custom-indexes](https://learn.microsoft.com/en-us/troubleshoot/mem/configmgr/update-management/wsus-maintenance-guide#create-custom-indexes)>

**Grant permissions to update computer operating systems (scheduled task)**\
From <[https://github.com/Borgquite/Update-WSUSComputerOperatingSystems](https://github.com/Borgquite/Update-WSUSComputerOperatingSystems)>

**Disable recycling and configure memory limits**\
From <[https://learn.microsoft.com/en-us/troubleshoot/mem/configmgr/update-management/windows-server-update-services-best-practices#disable-recycling-and-configure-memory-limits](https://learn.microsoft.com/en-us/troubleshoot/mem/configmgr/update-management/windows-server-update-services-best-practices#disable-recycling-and-configure-memory-limits)>

### Configure WSUS database

---

**SQL Server Management Studio** - Database Engine - **TT-SQL01**

```SQL
-- Set auto-grow increment on SUSDB.mdf to 128 MB
ALTER DATABASE [SUSDB]
MODIFY FILE ( NAME = N'SUSDB', FILEGROWTH = 131072KB )

-- Create custom indexes in WSUS database

-- Create custom index in tbLocalizedPropertyForRevision
USE [SUSDB]

CREATE NONCLUSTERED INDEX [nclLocalizedPropertyID]
ON [dbo].[tbLocalizedPropertyForRevision]
(
    [LocalizedPropertyID] ASC
)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF,
    DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

-- Create custom index in tbRevisionSupersedesUpdate
CREATE NONCLUSTERED INDEX [nclSupercededUpdateID]
ON [dbo].[tbRevisionSupersedesUpdate]
(
    [SupersededUpdateID] ASC
)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF,
    DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

-- Grant permissions to update computer operating systems (scheduled task)
GRANT SELECT ON [dbo].[tbComputerTargetDetail] TO [TECHTOOLBOX\TT-WSUS04$]
GO
GRANT UPDATE ON [dbo].[tbComputerTargetDetail] TO [TECHTOOLBOX\TT-WSUS04$]
GO
```

---

```PowerShell
cls
```

### # Disable recycling and configure memory limits in IIS for WSUS

```PowerShell
Import-Module WebAdministration

# Set "(General): Queue Length" to 2000 (default is 1000)
Set-ItemProperty `
    -Path IIS:\AppPools\WsusPool `
    -Name queueLength `
    -Value 2000

# Set "Process Model: Idle Time-out" to 0 (i.e. no time-out; default is 20
# minutes)
Set-ItemProperty `
    -Path IIS:\AppPools\WsusPool `
    -Name processModel.idleTimeout `
    -Value ([TimeSpan]::FromMinutes(0))

# Set "Process Model: Ping Enabled" to False (default is True)
Set-ItemProperty `
    -Path IIS:\AppPools\WsusPool `
    -Name processModel.pingingEnabled `
    -Value $false

# Set "Recycling: Private Memory Limit" to 0 (i.e. unlimited; default is
# 1,546,440 KB)
Set-ItemProperty `
    -Path IIS:\AppPools\WsusPool `
    -Name recycling.periodicRestart.privateMemory `
    -Value 0

# Set "Recycling: Regular Time Interval" to 0 (i.e. no periodic recycling;
# default is to recycle every 1,740 minutes)
Set-ItemProperty `
    -Path IIS:\AppPools\WsusPool `
    -Name recycling.periodicRestart.time `
    -Value "00:00:00"
```

### Configure WSUS by using WSUS Configuration Wizard

**To configure WSUS:**

1. In the **Server Manager** navigation pane, select **WSUS**.
2. In the servers list, right-click the WSUS server (**TT-WSUS04**) and then
   click **Windows Server Update Services**. The **Windows Server Update
   Services Wizard** opens.
3. On the **Before You Begin** page, review the information, and then click
   **Next**.
4. On the **Join the Microsoft Update Improvement Program** page, click
   **Next**.
5. On the **Choose Upstream Server** page, ensure the **Synchronize from
   Microsoft Update** option is selected and click **Next**.
6. On the **Specify Proxy Server** page, ensure the **Use a proxy server when
   synchronizing** checkbox is not selected, and click **Next**.
7. On the **Connect to Upstream Server** page, click **Start Connecting**.
    > **Note**
    >
    > When connecting to the upstream server, WSUS performs a partial
    > synchronization (which subsequently appears in the **Synchronizations**
    > list in the WSUS console). This initial synchronization may take
    > approximately 30 minutes to complete.
8. Wait for the information to be downloaded and then click **Next**.
9. On the **Choose Languages** page:
   1. Select the **Download updates in only these languages** option.
   2. In the list of languages, select **English**.
   3. Click **Next**.
10. After selecting the appropriate language options for your deployment, click
    **Next** to continue.
11. On the **Choose Products** page:
    1. Select the following products:
        - [ ] **Microsoft**
            - [x] **Azure File Sync**
            - [ ] **Developer Tools, Runtimes, and Redistributables**
                - [x] **.NET 5.0**
                - [x] **.NET 6.0**
                - [x] **.NET 7.0**
                - [x] **.NET 8.0**
                - [x] **.NET Core 2.1**
                - [x] **.NET Core 3.1**
                - [x] **Visual Studio 2017**
                - [x] **Visual Studio 2019**
                - [x] **Visual Studio 2022**
            - [ ] **Expression**
                - [x] **Expression Design 4**
                - [x] **Expression Web 4**
            - [ ] **Office**
                - [x] **Microsoft 365 Apps/Office 2019/Office LTSC**
                - [x] **SharePoint Server 2019/Office Online Server**
                - [x] **SharePoint Server Subscription Edition**
            - [ ] **PowerShell**
                - [x] **PowerShell - x64**
            - [x] **Silverlight**
            - [ ] **SQL Server**
                - [x] **Microsoft SQL Server 2016**
                - [x] **Microsoft SQL Server 2017**
                - [x] **Microsoft SQL Server 2019**
                - [x] **Microsoft SQL Server 2022**
                - [x] **Microsoft SQL Server Management Studio v18**
                - [x] **Microsoft SQL Server Management Studio v20**
            - [ ] **System Center**
                - [x] **System Center 2019 - Operations Manager**
                - [x] **System Center 2019 - Orchestrator**
                - [x] **System Center 2019 - Virtual Machine Manager**
                - [x] **System Center 2019 Data Protection Manager**
                - [x] **System Center 2022 - Data Protection Manager**
                - [x] **System Center 2022 - Operations Manager**
                - [x] **System Center 2022 - Orchestrator**
                - [x] **System Center 2022 - Virtual Machine Manager**
            - [x] **Windows Admin Center**
            - [x] **Windows Subsystem for Linux**
            - [ ] **Windows**
                - [x] **Microsoft Defender Antivirus**
                - [x] **Microsoft Edge**
                - [x] **Microsoft Server operating system-21H2**
                - [x] **Microsoft Server Operating System-22H2**
                - [x] **Microsoft Server Operating System-23H2**
                - [x] **Microsoft Server Operating System-24H2**
                - [x] **Windows 10, version 1903 and later**
                - [x] **Windows 10**
                - [x] **Windows 11**
                - [x] **Windows Server 2012 R2**
                - [x] **Windows Server 2016**
                - [x] **Windows Server 2019**
    2. Click **Next**.
12. On the **Choose Classifications** page:
    1. Select the following classifications:
        - **Critical Updates**
        - **Definition Updates**
        - **Feature Packs**
        - **Security Updates**
        - **Service Packs**
        - **Tools**
        - **Update Rollups**
        - **Updates**
        - **Upgrades**

        > **Important**
        >
        > Ensure the **Driver Sets** and **Drivers** classifications are *not*
        > selected. WSUS has a number of known issues when drivers are included.
    2. Click **Next**.
13. On the **Set Sync Schedule** page:
    1. Select the **Synchronize automatically** option.
    2. In the **First synchronization** box, specify **11:10:00 PM**.
    3. Click **Next**.
14. On the **Finished** page:
    1. Select the **Begin initial synchronization** checkbox.
    2. Click **Finish**. The WSUS Management Console appears.
    3. ~~Wait for the initial synchronization to complete before proceeding.~~

> **Note**
>
> The initial synchronization should complete in approximately 7-1/2 hours.

### Configure WSUS computer groups

**To create a computer group:**

1. In the **Update Services** console, in the navigation pane, expand
   **Computers**, and then select **All Computers**.
2. In the **Actions** pane, click **Add Computer Group...**
3. In the **Add Computer Group** window, in the **Name** box, type the name for
   the new computer group and click **OK**.

Configure the computer groups as follows:

- **All Computers**
  - **Unassigned Computers**
  - **Contoso - Critical**
    - **Contoso - Broad**
      - **Contoso - Preview**
  - **Fabrikam - Critical**
    - **Fabrikam - Broad**
      - **Fabrikam - Preview**
  - **Technology Toolbox - Critical**
    - **Technology Toolbox - Broad**
      - **Technology Toolbox - Preview**

### Perform initial WSUS database maintenance (rebuild/reorganize indexes)

1. Open **SQL Server Management Studio**.
2. Connect to the WSUS database server (**TT-SQL01C**).
3. Execute the following SQL script:

    **C:\\NotBackedUp\\Public\\Toolbox\\WSUS\\WsusDBMaintenance.sql**

### Add WSUS database to AlwaysOn Availability Group

---

**SQL Server Management Studio (TT-SQL01C)**

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
    'Z:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\Full\'
        + 'SUSDB.bak'

BACKUP DATABASE SUSDB
    TO DISK = @backupFilePath
    WITH FORMAT, INIT, SKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 5
GO
```

#### -- Backup WSUS transaction log

```SQL
DECLARE @backupFilePath VARCHAR(255) =
    'Z:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\Transaction Log\'
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

**SQL Server Management Studio (TT-SQL01D)**

#### -- Create login used by WSUS database

```SQL
USE master
GO

CREATE LOGIN [TECHTOOLBOX\TT-WSUS04$] FROM WINDOWS
WITH DEFAULT_DATABASE=master, DEFAULT_LANGUAGE=us_english
GO
```

---

### Secure WSUS with Secure Sockets Layer protocol

```PowerShell
cls
```

#### # Install SSL certificate

```PowerShell
# Location of file containing SSL certificate public and private keys
$certFilePath = `
    "\\TT-FS01\Backups\Certificates\External\wsus.technologytoolbox.com.pfx"

# Store certificate in "Personal / Certificates" for computer account
$certStoreLocation = "Cert:\LocalMachine\My"

# Prompt for password previously used to encrypt PFX file
$certPassword = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted for the secure string, type the password for the exported certificate.

```PowerShell
Import-PfxCertificate `
    -FilePath $certFilePath `
    -CertStoreLocation $certStoreLocation `
    -Password $certPassword
```

```PowerShell
cls
```

#### # Configure SSL on WSUS server

```PowerShell
Push-Location 'C:\Program Files\Update Services\Tools\'

.\WsusUtil.exe ConfigureSSL wsus.technologytoolbox.com

Pop-Location
```

```PowerShell
cls
```

#### # Add HTTPS binding to WSUS website in IIS

```PowerShell
$cert = Get-ChildItem -Path Cert:\LocalMachine\My |
    Where { $_.Subject -like "CN=wsus.technologytoolbox.com" }

Set-WebBinding `
    -Name "WSUS Administration" `
    -BindingInformation ":8531:" `
    -PropertyName HostHeader `
    -Value wsus.technologytoolbox.com

(Get-WebBinding `
    -Name "WSUS Administration" `
    -Port 8531).AddSslCertificate($cert.Thumbprint, "my")
```

### Configure name resolution for WSUS

---

**TT-ADMIN05** - Run as administrator

```PowerShell
# Remove existing DNS CNAME record for WSUS (i.e. "wsus.technologytoolbox.com")
Remove-DnsServerResourceRecord `
    -ComputerName TT-DC10 `
    -ZoneName technologytoolbox.com `
    -Name wsus `
    -RRType CName `
    -Force

# Add DNS CNAME record for WSUS (i.e. "wsus.technologytoolbox.com")
Add-DNSServerResourceRecordCName `
    -ComputerName TT-DC10 `
    -ZoneName technologytoolbox.com `
    -Name wsus `
    -HostNameAlias TT-WSUS04.corp.technologytoolbox.com
```

---

### Validate WSUS name resolution and SSL configuration

[http://wsus.technologytoolbox.com:8530/Content/anonymousCheckFile.txt](http://wsus.technologytoolbox.com:8530/Content/anonymousCheckFile.txt)

[https://wsus.technologytoolbox.com:8531/Content/anonymousCheckFile.txt](https://wsus.technologytoolbox.com:8531/Content/anonymousCheckFile.txt)

### Configure firewall for Windows Update

#### Identify static IP address for WSUS server

```Shell
nslookup TT-WSUS04
```

Output:

```Text
...

Non-authoritative answer:
Name:    TT-WSUS04.corp.technologytoolbox.com
Address:  10.1.30.139
```

#### Configure firewall rule to allow inbound traffic to WSUS server

```PowerShell
cls
```

### # Import scheduled task to update WSUS computer operating systems

```PowerShell
# Ensure custom "Temp" folder exists
If ((Test-Path C:\NotBackedUp\Temp) -eq $false)
{
    New-Item -Path C:\NotBackedUp\Temp -ItemType Directory
}
```

```PowerShell
Get-Content ('C:\NotBackedUp\Public\Toolbox\WSUS\' `
      + 'Update WSUS Computer Operating Systems.xml') |
    Out-String |
    Register-ScheduledTask -TaskName "Update WSUS Computer Operating Systems"
```

```PowerShell
cls
```

### # Import scheduled task to cleanup WSUS

```PowerShell
# Ensure custom "Temp" folder exists
If ((Test-Path C:\NotBackedUp\Temp) -eq $false)
{
    New-Item -Path C:\NotBackedUp\Temp -ItemType Directory
}
```

```PowerShell
Get-Content 'C:\NotBackedUp\Public\Toolbox\WSUS\WSUS Server Cleanup.xml' |
    Out-String |
    Register-ScheduledTask -TaskName "WSUS Server Cleanup"
```

#### Reference

**The complete guide to Microsoft WSUS and Configuration Manager SUP
maintenance**\
From <[https://support.microsoft.com/en-us/help/4490644/complete-guide-to-microsoft-wsus-and-configuration-manager-sup-maint](https://support.microsoft.com/en-us/help/4490644/complete-guide-to-microsoft-wsus-and-configuration-manager-sup-maint)>

### Create SQL job for WSUS database maintenance

Name: **WsusDBMaintenance**\
Steps:

- Step 1

  - Step name: **Defragment database and update statistics**
  - Type: **Transact-SQL script (T-SQL)**
  - Command: (click **Open...** and then select script -
    **"C:\\NotBackedUp\\Public\\Toolbox\\WSUS\\WsusDBMaintenance.sql"**)
  - Database: **SUSDB**

Schedule:

- Schedule 1

  - Name: **Weekly**
  - Frequency:
    - Occurs: **Weekly**
    - Recurs every: **1 week on Sunday**
  - Daily frequency:
    - Occurs once at: **10:00 AM**

## Step 3: Approve and Deploy Updates in WSUS

Reference:

**Approve and Deploy Updates in WSUS**\
From <[https://docs.microsoft.com/en-us/windows-server/administration/windows-server-update-services/deploy/3-approve-and-deploy-updates-in-wsus](https://docs.microsoft.com/en-us/windows-server/administration/windows-server-update-services/deploy/3-approve-and-deploy-updates-in-wsus)>

### Approve updates for WSUS clients

**To approve and deploy WSUS updates:**

1. In the **Update Services** console, click **Updates**. In the right pane, an
   update status summary is displayed for **All Updates**, **Critical Updates**,
   **Security Updates**, and **WSUS Updates**.
2. In the **All Updates** section, click **Updates needed by computers**.
3. In the list of updates, select the updates that you want to approve for
   installation. Information about a selected update is available in the bottom
   pane of the **Updates** panel. To select multiple contiguous updates, hold
   down the **shift** key while clicking the update names. To select multiple
   noncontiguous updates, press down the **CTRL** key while clicking the update
   names.
4. Right-click the selection, and then click **Approve**.
5. In the **Approve Updates** dialog box:
   1. Select the desired computer group, click the down arrow, and click
      **Approved for Install**.
   2. Click **OK**.
6. The **Approval Progress** window appears, which shows the progress of the
   tasks that affect update approval. When the approval process is complete,
   click **Close**.

### Configure automatic approval rules

**To configure automatic approval rules:**

1. Open the **Update Services** console.
2. In the left navigation pane, expand the WSUS server and select **Options**.
3. In the **Options** pane, select **Automatic Approvals**.
4. In the **Automatic Approvals** window, on the **Update Rules** tab, select
   **Default Automatic Approval Rule**.
5. In the **Rule properties** section, click **Critical Updates, Security
   Updates**.
6. In the **Choose Update Classifications** window:
   1. Select **Definition Updates**.
   2. Clear the checkboxes for all other update classifications.
   3. Click **OK**.
7. Confirm the **Rule properties** for the **Default Automatic Approval Rule**
   are configured as follows:\
   \
   **When an update is in *Definition Updates***\
   \
   **Approve the update for *all computers***

8. Select the **Default Automatic Approval Rule** checkbox.
9. Click **New Rule...**
10. In the **Add Rule** window:
    1. In the **Step 1: Select properties** section, select **When an update is
       in a specific classification**.
    2. In the **Step 2: Edit the properties** section:
       1. Click **any classification**.
          1. In the **Choose Update Classifications** window:
             1. Clear the **All Classifications** checkbox.
             2. Select the following checkboxes:
                - **Critical Updates**
                - **Security Updates**
          2. Click **OK**.
       2. Click **all computers**
          1. In the **Choose Computer Groups** window:
             1. Clear the **All Computers** checkbox.
             2. Select the following checkboxes:
                - [ ] **Contoso - Critical**
                    - [ ] **Contoso - Broad**
                        - [x] **Contoso - Preview**
                - [ ] **Fabrikam - Critical**
                    - [ ] **Fabrikam - Broad**
                        - [x] **Fabrikam - Preview**
          2. Click **OK**.
    3. In the **Step 3: Specify a name** box, type **Preview Approval Rule**.
    4. Click **OK**.
11. In the **Automatic Approvals** window:

    1. Confirm the **Rule properties** for the **Preview Approval Rule**
       are configured as follows:\
       \
       **When an update is in *Critical Updates, Security Updates***\
       \
       **Approve the update for *Contoso - Preview, Fabrikam - Preview***

    2. Click **OK**.

```PowerShell
cls
```

### # Decline superseded updates older than 60 days

```PowerShell
C:\NotBackedUp\Public\Toolbox\WSUS\Decline-SupersededUpdates.ps1 `
    -UpdateServer TT-WSUS04 `
    -Port 8530 `
    -ExclusionPeriod 60
```

## Step 4: Configure Group Policy settings for Automatic Updates

### Configure "default Windows Update" group policy

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FF/90D027F45985EDDE45459FFE24B90162DB4EC7FF.png)

### Configure "manual Windows Update" group policy

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3D/6E21C9B289F9BA9956C626E0233D90918321943D.png)

### Configure group policies for each "Windows Update slot"

![(screenshot)](https://assets.technologytoolbox.com/screenshots/70/30DD2864E090A114EA8533C7805470816BC07470.png)

**TODO:**

## Maintain WSUS environment

### Issue - Synchronizations view in WSUS console hangs (then requires console reset)

#### Problem

**spSearchUpdates** sproc returns more than 24,000 rows

#### Solution

---

**SQL Server Management Studio** - Database Engine - **TT-SQL01**

##### -- Clear the synchronization history

```SQL
USE SUSDB
GO

DELETE FROM tbEventInstance
WHERE EventNamespaceID = '2'
    AND EventID IN ('381', '382', '384', '386', '387', '389')
```

---

References:

**Synchronization Tab crashes the WSUS console**\
From <[https://conexiva.wordpress.com/2016/02/23/synchronization-tab-crashes-the-wsus-console/](https://conexiva.wordpress.com/2016/02/23/synchronization-tab-crashes-the-wsus-console/)>

**Clearing the Synchronization history in the WSUS console**\
From <[https://blogs.technet.microsoft.com/sus/2009/03/04/clearing-the-synchronization-history-in-the-wsus-console/](https://blogs.technet.microsoft.com/sus/2009/03/04/clearing-the-synchronization-history-in-the-wsus-console/)>

## WSUS update approvals

```PowerShell
Get-WsusUpdate -Approval AnyExceptDeclined |
    #select -First 5 |
    foreach {
        New-Object -TypeName PSObject -Property @{
          'UpdateId' = $_.UpdateId;
          'Title' = $_.Update.Title;
          'Classification' = $_.Classification;
          'Approved' = $_.Approved;
        }
    } |
    Export-Csv `
        -Path C:\NotBackedUp\Temp\WSUS-Updates.csv `
        -NoTypeInformation `
        -Encoding UTF8

Get-WsusUpdate -Approval Declined |
    #select -First 5 |
    foreach {
        New-Object -TypeName PSObject -Property @{
          'UpdateId' = $_.UpdateId;
          'Title' = $_.Update.Title;
          'Classification' = $_.Classification;
          'Approved' = $_.Approved;
        }
    } |
    Export-Csv `
        -Path C:\NotBackedUp\Temp\WSUS-Updates.csv `
        -NoTypeInformation `
        -Encoding UTF8 `
        -Append


$wsusServer = Get-WsusServer

$wsusServer.GetComputerTargetGroups() |
    foreach {
        $computerGroup = $_

        $updateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope

        $updateScope.ApprovedStates = "Any"
        $updateScope.ApprovedComputerTargetGroups.Add($computerGroup) | Out-Null

        $wsusServer.GetUpdateApprovals($updateScope) |
            foreach {
                New-Object -TypeName PSObject -Property @{
                    'ComputerGroup' = $computerGroup.Name;
                    'UpdateId' = $_.Id;
                    'Action' = $_.Action;
                }
            }
    } |
    Export-Csv `
        -Path C:\NotBackedUp\Temp\WSUS-Updates-By-Computer-Group.csv `
        -NoTypeInformation `
        -Encoding UTF8
```

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

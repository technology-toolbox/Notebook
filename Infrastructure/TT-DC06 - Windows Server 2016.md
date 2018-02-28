﻿# TT-DC06 - Windows Server 2016

Wednesday, February 21, 2018
1:43 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV02A"
$vmName = "TT-DC06"
$vmPath = "E:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 2GB `
    -SwitchName "Embedded Team Switch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -DynamicMemory `
    -MemoryMinimumBytes 1GB `
    -MemoryMaximumBytes 2GB `
    -ProcessorCount 2

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Install custom Windows Server 2016 image

- On the **Task Sequence** step, select **Windows Server 2016** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **TT-DC06**.
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

```PowerShell
cls
```

#### # Configure static IP addresses

##### # Disable DHCP and router discovery

```PowerShell
Set-NetIPInterface `
    -InterfaceAlias $interfaceAlias `
    -Dhcp Disabled `
    -RouterDiscovery Disabled
```

##### # Configure static IPv4 address

```PowerShell
$ipAddress = "192.168.10.103"

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
    -ServerAddresses 192.168.10.104
```

##### # Configure static IPv6 address

```PowerShell
$ipAddress = "2603:300b:802:89e0::103"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 64
```

##### # Configure IPv6 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 2603:300b:802:89e0::104
```

### Configure storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 32 GB       | 4K                   | OSDisk       |
| 1    | D:           | 5 GB        | 4K                   | Data01       |

#### Configure separate VHD for Active Directory data

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

##### # Add disk for Active Directory data

```PowerShell
$vmHost = "TT-HV02A"
$vmName = "TT-DC06"

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 5GB
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

```PowerShell
cls
```

### # Configure Windows Update

#### # Add machine to security group for Windows Update schedule

```PowerShell
Add-ADGroupMember -Identity "Windows Update - Slot 2" -Members "TT-DC06$"
```

## Configure domain controller

### Login as TECHTOOLBOX\\jjameson-admin

### # Install Active Directory Domain Services

```PowerShell
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools -Restart
```

> **Note**
>
> A restart was not needed after installing Active Directory Domain Services.

```PowerShell
cls
```

### # Promote server to domain controller

```PowerShell
Import-Module ADDSDeployment

Install-ADDSDomainController `
    -DatabasePath "D:\Windows\NTDS" `
    -DomainName "corp.technologytoolbox.com" `
    -LogPath "D:\Windows\NTDS" `
    -SysvolPath "D:\Windows\SYSVOL" `
    -Force:$true
```

> **Note**
>
> When prompted, specify the password for the administrator account when the computer is started in Safe Mode or a variant of Safe Mode, such as Directory Services Restore Mode.

### Disable DNS on IPv6 link-local address

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A1/59E0906A2726FFD2DBB4983F9EF41B663AC1F6A1.png)

### # Configure firewall for cross-forest trust (EXTRANET --> TECHTOOLBOX)

```PowerShell
reg add HKLM\SYSTEM\CurrentControlSet\Services\NTDS\Parameters `
```

    /v "TCP/IP Port" /t REG_DWORD /d 58349

```PowerShell
reg add HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters `
```

    /v DCTcpipPort /t REG_DWORD /d 51164

```PowerShell
Restart-Computer
```

## Configure NTP

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Disable Hyper-V time synchronization service

```PowerShell
$vmHost = "TT-HV02A"
$vmName = "TT-DC06"

Disable-VMIntegrationService `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Name "Time Synchronization"
```

---

### Configure NTP

```Text
PS C:\windows\system32> cd HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\DateTime
PS HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DateTime> dir


    Hive: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\DateTime


Name                           Property
----                           --------
Servers                        (default) : 1
                               1         : time.windows.com
                               2         : time.nist.gov
```

**How to configure an authoritative time server in Windows Server**\
Pasted from <[http://support.microsoft.com/kb/816042](http://support.microsoft.com/kb/816042)>

**Synchronize the Time Server for the Domain Controller with an External Source**\
Pasted from <[http://technet.microsoft.com/en-us/library/cc784553(v=ws.10).aspx](http://technet.microsoft.com/en-us/library/cc784553(v=ws.10).aspx)>

**Configuring an authoritative time source for your Windows domain**\
Pasted from <[http://windowshell.wordpress.com/2012/01/02/configuring-an-authoritative-time-source-for-your-windows-domain/](http://windowshell.wordpress.com/2012/01/02/configuring-an-authoritative-time-source-for-your-windows-domain/)>

**Configuring Time Synchronization for all Computers in a Windows domain**\
Pasted from <[http://www.altaro.com/hyper-v/configuring-time-synchronization-for-all-computers-in-windows-domain/](http://www.altaro.com/hyper-v/configuring-time-synchronization-for-all-computers-in-windows-domain/)>

**How to configure your virtual Domain Controllers and avoid simple mistakes with resulting big problems**\
Pasted from <[http://www.sole.dk/how-to-configure-your-virtual-domain-controllers-and-avoid-simple-mistakes-with-resulting-big-problems/](http://www.sole.dk/how-to-configure-your-virtual-domain-controllers-and-avoid-simple-mistakes-with-resulting-big-problems/)>

**Configure a time server for Active Directory domain controllers**\
Pasted from <[http://www.techrepublic.com/blog/the-enterprise-cloud/configure-a-time-server-for-active-directory-domain-controllers/](http://www.techrepublic.com/blog/the-enterprise-cloud/configure-a-time-server-for-active-directory-domain-controllers/)>

**Setting a Domain Controller to Sync with External NTP Server**\
Pasted from <[http://seanofarrelll.blogspot.com/2010/04/setting-domain-controller-to-sync-with.html](http://seanofarrelll.blogspot.com/2010/04/setting-domain-controller-to-sync-with.html)>

**Time Synchronization in Hyper-V**\
From <[http://blogs.msdn.com/b/virtual_pc_guy/archive/2010/11/19/time-synchronization-in-hyper-v.aspx](http://blogs.msdn.com/b/virtual_pc_guy/archive/2010/11/19/time-synchronization-in-hyper-v.aspx)>

```Console
reg add HKLM\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\VMICTimeProvider /v Enabled /t reg_dword /d 0
```

When prompted to overwrite the value, type **yes**.

```Console
w32tm /config /syncfromflags:DOMHIER /update

net stop w32time
net start w32time

w32tm /resync /force

w32tm /query /source
```

NtpServer: time.windows.com,0x1 time-nw.nist.gov,0x1 time-b.nist.gov,0x1 time.nist.gov,0x1 time-a.nist.gov,0x1\
SpecialPollInterval: 900\
MaxPosPhaseCorrection: 3600 Decimal\
MaxNegPhaseCorrection: 3600 Decimal

**To configure an internal time server to synchronize with an external time source, follow these steps:**

1. Change the server type to NTP. To do this, follow these steps:
   1. Click **Start**, click **Run**, type **regedit**, and then click **OK**.
   2. Locate and then click the following registry subkey:
**HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\W32Time\\Parameters\\Type**
   3. In the pane on the right, right-click **Type**, and then click **Modify**.
   4. In **Edit Value**, type **NTP** in the **Value data** box, and then click **OK**.
2. Set AnnounceFlags to 5. To do this, follow these steps:
   1. Locate and then click the following registry subkey:
**HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\W32Time\\Config\\AnnounceFlags**
   2. In the pane on the right, right-click **AnnounceFlags**, and then click **Modify**.
   3. In **Edit DWORD Value**, type **5** in the **Value data** box, and then click **OK**.

**Notes**
      - If an authoritative time server that is configured to use an AnnounceFlag value of 0x5 does not synchronize with an upstream time server, a client server may not correctly synchronize with the authoritative time server when the time synchronization between the authoritative time server and the upstream time server resumes. Therefore, if you have a poor network connection or other concerns that may cause time synchronization failure of the authoritative server to an upstream server, set the AnnounceFlag value to 0xA instead of to 0x5.
      - If an authoritative time server that is configured to use an AnnounceFlag value of 0x5 and to synchronize with an upstream time server at a fixed interval that is specified in SpecialPollInterval, a client server may not correctly synchronize with the authoritative time server after the authoritative time server restarts. Therefore, if you configure your authoritative time server to synchronize with an upstream NTP server at a fixed interval that is specified in SpecialPollInterval, set the AnnounceFlag value to 0xA instead of 0x5.
3. Enable NTPServer. To do this, follow these steps:
   1. Locate and then click the following registry subkey:
**HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\W32Time\\TimeProviders\\NtpServer**
   2. In the pane on the right, right-click **Enabled**, and then click **Modify**.
   3. In **Edit DWORD Value**, type **1** in the **Value data** box, and then click **OK**.
4. Specify the time sources. To do this, follow these steps:
   1. Locate and then click the following registry subkey:
**HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\W32Time\\Parameters**
   2. In the pane on the right, right-click **NtpServer**, and then click **Modify**.
   3. In **Edit Value**, type Peers in the **Value data** box, and then click **OK**.

**Note **Peers is a placeholder for a space-delimited list of peers from which your computer obtains time stamps. Each DNS name that is listed must be unique. You must append **,0x1** to the end of each DNS name. If you do not append **,0x1** to the end of each DNS name, the changes that you make in step 5 will not take effect.
5. Select the poll interval. To do this, follow these steps:
   1. Locate and then click the following registry subkey:
**HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\W32Time\\TimeProviders\\NtpClient\\SpecialPollInterval**
   2. In the pane on the right, right-click **SpecialPollInterval**, and then click **Modify**.
   3. In **Edit DWORD Value**, type TimeInSeconds in the **Value data** box, and then click **OK**. 

**Note **TimeInSeconds is a placeholder for the number of seconds that you want between each poll. A recommended value is 900 Decimal. This value configures the Time Server to poll every 15 minutes.
6. Configure the time correction settings. To do this, follow these steps:
   1. Locate and then click the following registry subkey:
**HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\W32Time\\Config\\MaxPosPhaseCorrection**
   2. In the pane on the right, right-click **MaxPosPhaseCorrection**, and then click **Modify**.
   3. In **Edit DWORD Value**, click to select **Decimal** in the **Base** box.
   4. In **Edit DWORD Value**, type TimeInSeconds in the **Value data** box, and then click **OK**. 

**Note **TimeInSeconds is a placeholder for a reasonable value, such as 1 hour (3600) or 30 minutes (1800). The value that you select will depend on the poll interval, network condition, and external time source.
   5. Locate and then click the following registry subkey: 
**HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\W32Time\\Config\\MaxNegPhaseCorrection**
   6. In the pane on the right, right-click **MaxNegPhaseCorrection**, and then click **Modify**.
   7. In **Edit DWORD Value**, click to select **Decimal** in the **Base** box.
   8. In **Edit DWORD Value**, type TimeInSeconds in the **Value data** box, and then click **OK**. 

**Note **TimeInSeconds is a placeholder for a reasonable value, such as 1 hour (3600) or 30 minutes (1800). The value that you select will depend on the poll interval, network condition, and external time source.
7. Close Registry Editor.
8. At the command prompt, type the following command to restart the Windows Time service, and then press Enter:
**net stop w32time && net start w32time**

Pasted from <[http://support.microsoft.com/kb/816042](http://support.microsoft.com/kb/816042)>

```Console
w32tm /resync /rediscover
```

## Configure backups

### # Add Windows Server Backup feature (DPM dependency for System State backups)

```PowerShell
Add-WindowsFeature Windows-Server-Backup
```

```PowerShell
cls
```

### # Install DPM agent

```PowerShell
$installer = "\\TT-FS01\Products\Microsoft\System Center 2016" `
    + "\DPM\Agents\DPMAgentInstaller_x64.exe"

& $installer TT-DPM02.corp.technologytoolbox.com
```

Review the licensing agreement. If you accept the Microsoft Software License Terms, select **I accept the license terms and conditions**, and then click **OK**.

Confirm the agent installation completed successfully and the following firewall exceptions have been added:

- Exception for DPMRA.exe in all profiles
- Exception for Windows Management Instrumentation service
- Exception for RemoteAdmin service
- Exception for DCOM communication on port 135 (TCP and UDP) in all profiles

#### Reference

**Installing Protection Agents Manually**\
Pasted from <[http://technet.microsoft.com/en-us/library/hh757789.aspx](http://technet.microsoft.com/en-us/library/hh757789.aspx)>

---

**FOOBAR11 - DPM Management Shell**

```PowerShell
cls
```

### # Attach DPM agent

```PowerShell
$productionServer = 'TT-DC06'

.\Attach-ProductionServer.ps1 `
    -DPMServerName TT-DPM02 `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `
    -UserName jjameson-admin
```

---

## Configure monitoring

### Install Operations Manager agent

Install SCOM agent using Operations Manager console

### Configure SCOM agent for domain controller

#### Enable agent proxy

In the **Agent Properties** window, on the **Security** tab, select **Allow this agent to act as a proxy and discover managed objects on other computers** and then click **OK**.

```PowerShell
cls
```

#### # Enable SCOM agent to run as LocalSystem on domain controller

```PowerShell
Push-Location "C:\Program Files\Microsoft Monitoring Agent\Agent"

.\HSLockdown.exe HQ /R "NT AUTHORITY\SYSTEM"

Pop-Location

Restart-Service HealthService
```

##### Reference

**Deploying SCOM 2016 Agents to Domain controllers - some assembly required**\
From <[https://blogs.technet.microsoft.com/kevinholman/2016/11/04/deploying-scom-2016-agents-to-domain-controllers-some-assembly-required/](https://blogs.technet.microsoft.com/kevinholman/2016/11/04/deploying-scom-2016-agents-to-domain-controllers-some-assembly-required/)>

**TODO:**

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
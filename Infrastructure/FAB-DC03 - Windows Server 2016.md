# FAB-DC03 - Windows Server 2016

Thursday, May 17, 2018
5:39 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "FAB-DC03"
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
  - In the **Computer name** box, type **FAB-DC03**.
  - Specify **WORKGROUP**.
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

# Join domain

```PowerShell
Add-Computer -DomainName corp.fabrikam.com -Restart
```

---

**FAB-DC01 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Remove old domain controller

##### # Demote domain controller

```PowerShell
Import-Module ADDSDeployment

Uninstall-ADDSDomainController `
    -DemoteOperationMasterRole:$true `
    -RemoveDnsDelegation:$true
```

> **Note**
>
> When prompted, specify the password for the local administrator account.

##### Remove Active Directory Domain Services and DNS roles

> **Note**
>
> Restart the computer to complete the removal of the roles.

##### # Stop server

```PowerShell
Stop-Computer
```

---

```PowerShell
cls
```

#### # Configure static IP addresses

```PowerShell
$interfaceAlias = "Management"
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
$ipAddress = "10.0.40.2"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24 `
    -DefaultGateway 10.0.40.1
```

##### # Configure IPv4 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 10.0.40.3
```

### Configure storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 32 GB       | 4K                   | OSDisk       |
| 1    | D:           | 5 GB        | 4K                   | Data01       |

#### Configure separate VHD for Active Directory data

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

##### # Add disk for Active Directory data

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "FAB-DC03"

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

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Configure Windows Update

#### # Add machine to security group for Windows Update schedule

```PowerShell
Add-ADGroupMember -Identity "Windows Update - Slot 19" -Members "FAB-DC03$"
```

---

## Configure domain controller

### Login as FABRIKAM\\jjameson-admin

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
    -DomainName "corp.fabrikam.com" `
    -LogPath "D:\Windows\NTDS" `
    -SysvolPath "D:\Windows\SYSVOL" `
    -Force:$true
```

> **Note**
>
> When prompted, specify the password for the administrator account when the computer is started in Safe Mode or a variant of Safe Mode, such as Directory Services Restore Mode.

### # Configure firewall for cross-forest trust (EXTRANET --> FABRIKAM)

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

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Disable Hyper-V time synchronization service

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "FAB-DC03"

Disable-VMIntegrationService `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Name "Time Synchronization"
```

---

### # Configure NTP settings

```PowerShell
w32tm /config /syncfromflags:DOMHIER /update

Restart-service w32time
```

#### # Change the server type to NTP

```PowerShell
Set-ItemProperty `
    -Path HKLM:SYSTEM\CurrentControlSet\Services\W32Time\Parameters `
    -Name Type `
    -Value NTP
```

#### # Set AnnounceFlags to 5

```PowerShell
Set-ItemProperty `
    -Path HKLM:SYSTEM\CurrentControlSet\Services\W32Time\Config `
    -Name AnnounceFlags `
    -Value 5
```

#### # Enable NTPServer

```PowerShell
Set-ItemProperty `
    -Path HKLM:SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpServer `
    -Name Enabled `
    -Value 1
```

#### # Specify the time sources

```PowerShell
Set-ItemProperty `
    -Path HKLM:SYSTEM\CurrentControlSet\Services\W32Time\Parameters `
    -Name NtpServer `
    -Value "ntp.extranet.technologytoolbox.com,0x1 time.windows.com,0x1"
```

#### # Set poll interval to every 15 minutes (900 seconds)

```PowerShell
Set-ItemProperty `
    -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpClient `
    -Name SpecialPollInterval `
    -Value 900
```

#### # Configure time correction settings

```PowerShell
Set-ItemProperty `
    -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config `
    -Name MaxPosPhaseCorrection `
    -Value 3600

Set-ItemProperty `
    -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config `
    -Name MaxNegPhaseCorrection `
    -Value 3600

Restart-Service w32time

w32tm /resync /rediscover
```

```PowerShell
cls
```

## # Configure backups

### # Add Windows Server Backup feature (DPM dependency for System State backups)

```PowerShell
Add-WindowsFeature Windows-Server-Backup
```

```PowerShell
cls
```

### # Install DPM agent

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\System Center 2016" `
    + "\DPM\Agents\DPMAgentInstaller_x64.exe"

$installerArguments = "TT-DPM02.corp.technologytoolbox.com"

Start-Process `
    -FilePath $installerPath `
    -ArgumentList "$installerArguments" `
    -Wait
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

**FOOBAR16 - DPM Management Shell**

```PowerShell
cls
```

### # Attach DPM agent

```PowerShell
$productionServer = 'FAB-DC03'

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

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Move VM to new Fabrikam VM network

```PowerShell
$vmName = "FAB-DC03"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Fabrikam VM Network"

Stop-SCVirtualMachine $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork

Start-SCVirtualMachine $vmName
```

### Update IP addresses

#### IPv4

IP address: **10.0.40.2**\
Subnet mask: **255.255.255.0**\
Default gateway: **10.0.40.1**

Preferred DNS server: **10.0.40.3**\
Alternate DNS server: **127.0.0.1**

#### IPv6

IP address: **Obtain an IPv6 address automatically**

DNS servers: **Obtain DNS server address automatically**

```PowerShell
cls
```

### # Update DNS on IP address pool in VMM

```PowerShell
$ipAddressPool = Get-SCStaticIPAddressPool -Name "Fabrikam-40 Address Pool"

Set-SCStaticIPAddressPool `
    -StaticIPAddressPool $ipAddressPool `
    -DNSServer @("10.0.40.2", "10.0.40.3")
```

### # Update DNS settings on VMs

```PowerShell
$script = [scriptblock] {
    $interfaceAlias = "Management"

    Set-DNSClientServerAddress `
        -InterfaceAlias $interfaceAlias `
        -ServerAddresses @(("10.0.40.2", "10.0.40.3")
}

$fabrikamNetwork = Get-SCVMNetwork "Fabrikam VM Network"

Get-SCVirtualMachine |
    Get-SCVirtualNetworkAdapter |
    where { $_.IPv4AddressType -eq "Static" } |
    where { $_.VMNetwork -in ($fabrikamNetwork) } |
    select -ExpandProperty Name |
    foreach {
        Write-Host "Updating DNS settings on $_"

        Invoke-Command -ScriptBlock $script -ComputerName $_
    }
```

---

## Migrate from FRS to DFS replication

### References

**Windows Server version 1709 no longer supports FRS**\
From <[https://support.microsoft.com/en-us/help/4025991/windows-server-version-1709-no-longer-supports-frs](https://support.microsoft.com/en-us/help/4025991/windows-server-version-1709-no-longer-supports-frs)>

**Streamlined Migration of FRS to DFSR SYSVOL**\
From <[https://techcommunity.microsoft.com/t5/Storage-at-Microsoft/Streamlined-Migration-of-FRS-to-DFSR-SYSVOL/ba-p/425405](https://techcommunity.microsoft.com/t5/Storage-at-Microsoft/Streamlined-Migration-of-FRS-to-DFSR-SYSVOL/ba-p/425405)>

**SYSVOL Replication Migration Guide: FRS to DFS Replication**\
From <[https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/dd640019(v=ws.10)](https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/dd640019(v=ws.10))>

### Ensure domain functional level is at least Windows Server 2008

### Ensure free disk space

On the volume containing the SYSVOL folder, ensure there is at least as much free space as the size of the current SYSVOL folder, plus a 10% fudge factor.

### Ensure correct security policy

Ensure the built-in **Administrators** group has the **Manage auditing and security log** user right on all your domain controllers.\

### Ensure AD replication is working

---

**FAB-TEST01 - Run as FABRIKAM\\jjameson-admin**

#### Install Active Directory Replication Status Tool

**Active Directory Replication Status Tool**\
From <[https://www.microsoft.com/en-us/download/details.aspx?id=30005](https://www.microsoft.com/en-us/download/details.aspx?id=30005)>

---

### Ensure SYSVOL is shared

---

**FAB-TEST01 - Run as FABRIKAM\\jjameson-admin**

```PowerShell
cls
```

#### # Run diagnostic tests for each domain controller

```PowerShell
dcdiag /e /test:sysvolcheck /test:advertising /s:FAB-DC03

dcdiag /e /test:sysvolcheck /test:advertising /s:FAB-DC04
```

---

### Migrate to "Prepared" state

> **Note**
>
> **FAB-DC04** is currently the PDC Emulator for the FABRIKAM domain.

---

**FAB-DC04 - Run as FABRIKAM\\jjameson-admin**

```PowerShell
cls
```

#### # Initiate migration to "Prepared" state

```PowerShell
dfsrmig /setglobalstate 1

Current DFSR global state: 'Start'
New DFSR global state: 'Prepared'

Migration will proceed to 'Prepared' state. DFSR service will
copy the contents of SYSVOL to SYSVOL_DFSR
folder.

If any domain controller is unable to start migration, try manual polling.
Or run with option /CreateGlobalObjects.
Migration can start anytime between 15 minutes to 1 hour.
Succeeded.
```

```PowerShell
cls
```

#### # Check migration status

```PowerShell
dfsrmig /getmigrationstate

The following domain controllers have not reached Global state ('Prepared'):

Domain Controller (Local Migration State) - DC Type
===================================================

FAB-DC04 ('Start') - Primary DC
FAB-DC03 ('Start') - Writable DC

Migration has not yet reached a consistent state on all domain controllers.
State information might be stale due to Active Directory Domain Services latency.
```

```PowerShell
cls
```

#### # Force replication

```PowerShell
repadmin /syncall /force /A /P /e /d
Syncing all NC's held on FAB-DC04.
Syncing partition: DC=ForestDnsZones,DC=corp,DC=fabrikam,DC=com
CALLBACK MESSAGE: The following replication is in progress:
...
CALLBACK MESSAGE: SyncAll Finished.
SyncAll terminated with no errors.

Syncing partition: DC=DomainDnsZones,DC=corp,DC=fabrikam,DC=com
CALLBACK MESSAGE: The following replication is in progress:
...
CALLBACK MESSAGE: SyncAll Finished.
SyncAll terminated with no errors.

Syncing partition: CN=Schema,CN=Configuration,DC=corp,DC=fabrikam,DC=com
CALLBACK MESSAGE: The following replication is in progress:
...
CALLBACK MESSAGE: SyncAll Finished.
SyncAll terminated with no errors.

Syncing partition: CN=Configuration,DC=corp,DC=fabrikam,DC=com
CALLBACK MESSAGE: The following replication is in progress:
...
CALLBACK MESSAGE: SyncAll Finished.
SyncAll terminated with no errors.

Syncing partition: DC=corp,DC=fabrikam,DC=com
CALLBACK MESSAGE: The following replication is in progress:
...
CALLBACK MESSAGE: SyncAll Finished.
SyncAll terminated with no errors.
```

```PowerShell
cls
```

#### # Check migration status

```PowerShell
dfsrmig /getmigrationstate

All domain controllers have migrated successfully to the Global state ('Prepared').
Migration has reached a consistent state on all domain controllers.
Succeeded.
```

---

### Migrate to "Redirected" state

---

**FAB-DC04 - Run as FABRIKAM\\jjameson-admin**

```PowerShell
cls
```

#### # Initiate migration to "Redirected" state

```PowerShell
dfsrmig /setglobalstate 2

Current DFSR global state: 'Prepared'
New DFSR global state: 'Redirected'

Migration will proceed to 'Redirected' state. The SYSVOL share
will be changed to SYSVOL_DFSR folder,
which is replicated using DFSR.

Succeeded.
```

```PowerShell
cls
```

#### # Check migration status

```PowerShell
dfsrmig /getmigrationstate

The following domain controllers have not reached Global state ('Redirected'):

Domain Controller (Local Migration State) - DC Type
===================================================

FAB-DC04 ('Prepared') - Primary DC
FAB-DC03 ('Prepared') - Writable DC

Migration has not yet reached a consistent state on all domain controllers.
State information might be stale due to Active Directory Domain Services latency.
```

```PowerShell
cls
```

#### # Force replication

```PowerShell
repadmin /syncall /force /A /P /e /d
Syncing all NC's held on FAB-DC04.
Syncing partition: DC=ForestDnsZones,DC=corp,DC=fabrikam,DC=com
CALLBACK MESSAGE: The following replication is in progress:
...
CALLBACK MESSAGE: SyncAll Finished.
SyncAll terminated with no errors.

Syncing partition: DC=DomainDnsZones,DC=corp,DC=fabrikam,DC=com
CALLBACK MESSAGE: The following replication is in progress:
...
CALLBACK MESSAGE: SyncAll Finished.
SyncAll terminated with no errors.

Syncing partition: CN=Schema,CN=Configuration,DC=corp,DC=fabrikam,DC=com
CALLBACK MESSAGE: The following replication is in progress:
...
CALLBACK MESSAGE: SyncAll Finished.
SyncAll terminated with no errors.

Syncing partition: CN=Configuration,DC=corp,DC=fabrikam,DC=com
CALLBACK MESSAGE: The following replication is in progress:
...
CALLBACK MESSAGE: SyncAll Finished.
SyncAll terminated with no errors.

Syncing partition: DC=corp,DC=fabrikam,DC=com
CALLBACK MESSAGE: The following replication is in progress:
...
CALLBACK MESSAGE: SyncAll Finished.
SyncAll terminated with no errors.
```

```PowerShell
cls
```

#### # Check migration status

```PowerShell
dfsrmig /getmigrationstate

All domain controllers have migrated successfully to the Global state ('Redirected').
Migration has reached a consistent state on all domain controllers.
Succeeded.
```

---

### Migrate to "Eliminated" state

---

**FAB-DC04 - Run as FABRIKAM\\jjameson-admin**

```PowerShell
cls
```

#### # Initiate migration to "Eliminated" state

```PowerShell
dfsrmig /setglobalstate 3

Current DFSR global state: 'Redirected'
New DFSR global state: 'Eliminated'

Migration will proceed to 'Eliminated' state. It is not possible
to revert this step.

If any read-only domain controller is stuck in the 'Eliminating' state for too long
 run with option /DeleteRoNtfrsMember.
Succeeded.
```

```PowerShell
cls
```

#### # Check migration status

```PowerShell
dfsrmig /getmigrationstate

The following domain controllers have not reached Global state ('Eliminated'):

Domain Controller (Local Migration State) - DC Type
===================================================

FAB-DC04 ('Redirected') - Primary DC
FAB-DC03 ('Redirected') - Writable DC

Migration has not yet reached a consistent state on all domain controllers.
State information might be stale due to Active Directory Domain Services latency.
```

```PowerShell
cls
```

#### # Force replication

```PowerShell
repadmin /syncall /force /A /P /e /d
Syncing all NC's held on FAB-DC04.
Syncing partition: DC=ForestDnsZones,DC=corp,DC=fabrikam,DC=com
CALLBACK MESSAGE: The following replication is in progress:
...
CALLBACK MESSAGE: SyncAll Finished.
SyncAll terminated with no errors.

Syncing partition: DC=DomainDnsZones,DC=corp,DC=fabrikam,DC=com
CALLBACK MESSAGE: The following replication is in progress:
...
CALLBACK MESSAGE: SyncAll Finished.
SyncAll terminated with no errors.

Syncing partition: CN=Schema,CN=Configuration,DC=corp,DC=fabrikam,DC=com
CALLBACK MESSAGE: The following replication is in progress:
...
CALLBACK MESSAGE: SyncAll Finished.
SyncAll terminated with no errors.

Syncing partition: CN=Configuration,DC=corp,DC=fabrikam,DC=com
CALLBACK MESSAGE: The following replication is in progress:
...
CALLBACK MESSAGE: SyncAll Finished.
SyncAll terminated with no errors.

Syncing partition: DC=corp,DC=fabrikam,DC=com
CALLBACK MESSAGE: The following replication is in progress:
...
CALLBACK MESSAGE: SyncAll Finished.
SyncAll terminated with no errors.
```

```PowerShell
cls
```

#### # Check migration status

```PowerShell
dfsrmig /getmigrationstate

All domain controllers have migrated successfully to the Global state ('Eliminated').
Migration has reached a consistent state on all domain controllers.
Succeeded.
```

---

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

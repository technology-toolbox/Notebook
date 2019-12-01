# TT-DC10 - Windows Server 2019

Saturday, May 18, 2019
6:14 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure infrastructure

---

**FOOBAR18 - Run as local administrator**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "TT-DC10"
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
    -ProcessorCount 2 `
    -DynamicMemory `
    -MemoryMinimumBytes 1GB `
    -MemoryMaximumBytes 4GB `
    -AutomaticCheckpointsEnabled $false

Add-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName

$vmDvdDrive = Get-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName

Set-VMFirmware `
    -ComputerName $vmHost `
    -VMName $vmName `
    -EnableSecureBoot Off `
    -FirstBootDevice $vmDvdDrive

Set-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path "\\TT-FS01\Products\Microsoft\Windows Server 2019\en_windows_server_2019_updated_march_2019_x64_dvd_2ae967ab.iso"

Set-VMDvdDrive : Failed to add device 'Virtual CD/DVD Disk'.
User Account does not have permission to open attachment.
'TT-DC10' failed to add device 'Virtual CD/DVD Disk'. (Virtual machine ID EC05A148-C379-45A8-B3A4-67B62105F7A0)
'TT-DC10': User account does not have permission required to open attachment '\\TT-FS01\Products\Microsoft\Windows Server
2019\en_windows_server_2019_updated_march_2019_x64_dvd_2ae967ab.iso'. Error: 'General access denied error' (0x80070005). (Virtual
machine ID EC05A148-C379-45A8-B3A4-67B62105F7A0)
At line:1 char:1
+ Set-VMDvdDrive `
+ ~~~~~~~~~~~~~~~~
    + CategoryInfo          : PermissionDenied: (:) [Set-VMDvdDrive], VirtualizationException
    + FullyQualifiedErrorId : AccessDenied,Microsoft.HyperV.PowerShell.Commands.SetVMDvdDrive

$iso = Get-SCISO |
    where {$_.Name -eq "en_windows_server_2019_updated_march_2019_x64_dvd_2ae967ab.iso"}

Get-SCVirtualMachine -Name $vmName | Read-SCVirtualMachine

Get-SCVirtualMachine -Name $vmName |
    Get-SCVirtualDVDDrive |
    Set-SCVirtualDVDDrive -ISO $iso -Link

#Start-VM -ComputerName $vmHost -Name $vmName
Start-SCVirtualMachine -VM $vmName
```

---

### Install Windows Server 2019

1. When prompted, select **Windows Server 2019 Standard (Desktop Experience)**.
2. Specify a password for the local Administrator account.

### # Rename local Administrator account

```PowerShell
$adminUser = [ADSI] 'WinNT://./Administrator,User'
$adminUser.Rename('foo')

logoff
```

### Login as .\\foo

```PowerShell
cls
```

### # Set time zone

```PowerShell
tzutil /s "Mountain Standard Time"
```

### # Rename computer and join domain

```PowerShell
$computerName = "TT-DC10"

Rename-Computer -NewName $computerName -Restart
```

Wait for the VM to restart and then execute the following command to join the **TECHTOOLBOX** domain:

```PowerShell
Add-Computer -DomainName corp.technologytoolbox.com -Restart
```

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

robocopy $source $destination /E /XD git-for-windows "Microsoft SDKs"
```

### # Set MaxPatchCacheSize to 0 (recommended)

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

### Configure storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 32 GB       | 4K                   | OSDisk       |
| 1    | D:           | 5 GB        | 4K                   | Data01       |

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

#### Configure separate VHD for Active Directory data

---

**FOOBAR18 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

##### # Add disk for Active Directory data

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "TT-DC10"

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

### Configure networking

---

**FOOBAR18 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Move VM to Management VM network

```PowerShell
$vmName = "TT-DC10"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Management VM Network"

Stop-SCVirtualMachine $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork

Start-SCVirtualMachine $vmName
```

---

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

---

**TT-DC08 - Run as TECHTOOLBOX\\jjameson-admin**

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
$ipAddress = "10.1.30.2"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24 `
    -DefaultGateway 10.1.30.1
```

##### # Configure IPv4 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 10.1.30.3
```

---

**FOOBAR18 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Configure Windows Update

#### # Add machine to security group for Windows Update schedule

```PowerShell
Add-ADGroupMember -Identity "Windows Update - Slot 2" -Members "TT-DC10$"
```

---

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

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EC/F5B075A8778A8C7920162AB474FC51F8024B47EC.png)

Screen clipping taken: 5/18/2019 7:49 AM

> **Note**
>
> When prompted, specify the password for the administrator account when the computer is started in Safe Mode or a variant of Safe Mode, such as Directory Services Restore Mode.

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

**FOOBAR18 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Disable Hyper-V time synchronization service

```PowerShell
$vmHost = "TT-HV05A"
$vmName = "TT-DC10"

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

**FOOBAR18 - DPM Management Shell**

```PowerShell
cls
```

### # Attach DPM agent

```PowerShell
$productionServer = 'TT-DC10'

.\Attach-ProductionServer.ps1 `
    -DPMServerName TT-DPM02 `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `
    -UserName jjameson-admin
```

---

### Add virtual machine to domain controllers protection group in DPM

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

## Upgrade to Data Protection Manager 2019

```PowerShell
cls
```

### # Remove DPM 2016 agent

```PowerShell
msiexec /x `{14DD5B44-17CE-4E89-8BEB-2E6536B81B35`}
```

> **Important**
>
> Restart the computer to complete the removal of the DPM agent.

```PowerShell
Restart-Computer
```

### # Install DPM 2019 agent

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\System Center 2019" `
    + "\DPM\Agents\DPMAgentInstaller_x64.exe"

$installerArguments = "TT-DPM05.corp.technologytoolbox.com"

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

**TT-ADMIN02 - DPM Management Shell**

```PowerShell
cls
```

### # Attach DPM agent

```PowerShell
$productionServer = 'TT-DC10'

.\Attach-ProductionServer.ps1 `
    -DPMServerName TT-DPM05 `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `
    -UserName jjameson-admin
```

---

### Add virtual machine to domain controllers protection group in DPM

## Upgrade to Operations Manager 2019

```PowerShell
cls
```

### # Remove SCOM 2016 agent

```PowerShell
msiexec /x `{742D699D-56EB-49CC-A04A-317DE01F31CD`}
```

```PowerShell
cls
```

### # Install SCOM agent

```PowerShell
$msiPath = "\\TT-FS01\Products\Microsoft\System Center 2019\SCOM\agent\AMD64" `
    + "\MOMAgent.msi"

msiexec.exe /i $msiPath `
    MANAGEMENT_GROUP=HQ `
    MANAGEMENT_SERVER_DNS=TT-SCOM01C `
    ACTIONS_USE_COMPUTER_ACCOUNT=1
```

### Approve manual agent install in Operations Manager

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

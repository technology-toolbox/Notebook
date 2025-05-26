# TT-DC13 - Windows Server 2022 Domain Controller

Monday, May 26, 2025\
6:15 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure server infrastructure

---

**TT-ADMIN05** - Run as administrator

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV06B"
$vmName = "TT-DC13"
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

Set-VMNetworkAdapterVlan `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Access `
    -VlanId 30

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Install custom Windows Server 2022 image

- On the **Task Sequence** step, select **Windows Server 2022** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **TT-DC13**.
  - Ensure the **Join a domain** option is selected and the **Domain to join** box contains **corp.technologytoolbox.com**.
  - Click **Next**.
- On the **Applications** step, do not select any applications, and click **Next**.

### # Rename local Administrator account and set password

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

$password = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted, type the password for the local administrator account.

```PowerShell
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

$adminUser = [ADSI] 'WinNT://./Administrator,User'
$adminUser.Rename('foo')
$adminUser.SetPassword($plainPassword)

logoff
```

---

### Log in as local administrator account

---

**TT-ADMIN05** - Run as domain administrator

```PowerShell
cls
```

### # Configure Windows Update

#### # Add machine to security group for Windows Update schedule

```PowerShell
Add-ADGroupMember -Identity "Windows Update - Slot 4" -Members "TT-DC13$"
```

---

### Configure storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 32 GB       | 4K                   | OSDisk       |
| 1    | D:           | 5 GB        | 4K                   | Data01       |
| 2    | Z:           | 20 GB       | 4K                   | Backup01     |

#### Configure separate VHDs for Active Directory data and backups

---

**TT-ADMIN05** - Run as administrator

```PowerShell
cls
```

##### # Add disk for Active Directory data

```PowerShell
$vmHost = "TT-HV06B"
$vmName = "TT-DC13"

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 5GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path $vhdPath `
    -ControllerType SCSI
```

##### # Add disk for local backups using Windows Server Backup

```PowerShell
$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Backup01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 20GB
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

###### # Initialize data disk and format volume

```PowerShell
Get-Disk 1 |
    Initialize-Disk -PartitionStyle GPT -PassThru |
    New-Partition -UseMaximumSize -DriveLetter D |
    Format-Volume `
        -FileSystem NTFS `
        -NewFileSystemLabel "Data01" `
        -Confirm:$false
```

###### # Initialize backup disk and format volume

```PowerShell
Get-Disk 2 |
    Initialize-Disk -PartitionStyle GPT -PassThru |
    New-Partition -UseMaximumSize -DriveLetter Z |
    Format-Volume `
        -FileSystem NTFS `
        -NewFileSystemLabel "Backup01" `
        -Confirm:$false
```

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

ping TT-DC11 -f -l 8900
```

```PowerShell
cls
```

#### # Disable Link-Layer Topology Discovery

```PowerShell
Get-NetAdapter |
    foreach {
        $interfaceAlias = $_.Name

        Write-Host ("Disabling Link-Layer Topology Discovery on interface" `
            + " ($interfaceAlias)...")

        Disable-NetAdapterBinding -Name $interfaceAlias `
            -DisplayName "Link-Layer Topology Discovery Mapper I/O Driver"

        Disable-NetAdapterBinding -Name $interfaceAlias `
            -DisplayName "Link-Layer Topology Discovery Responder"
    }
```

> **Note**
>
> This avoids flooding the firewall log with numerous entries for UDP 5355 broadcast.

```PowerShell
cls
```

#### # Disable NetBIOS over TCP/IP

```PowerShell
Get-NetAdapter |
    foreach {
        $interfaceAlias = $_.Name

        Write-Host ("Disabling NetBIOS over TCP/IP on interface" `
            + " ($interfaceAlias)...")

        $adapter = Get-WmiObject -Class "Win32_NetworkAdapter" `
            -Filter "NetConnectionId = '$interfaceAlias'"

        $adapterConfig = `
            Get-WmiObject -Class "Win32_NetworkAdapterConfiguration" `
                -Filter "Index= '$($adapter.DeviceID)'"

        # Disable NetBIOS over TCP/IP
        $adapterConfig.SetTcpipNetbios(2)
    }
```

> **Note**
>
> This avoids flooding the firewall log with numerous entries for UDP 137 broadcast.

---

**TT-DC11** - Run as domain administrator

```PowerShell
cls
```

#### # Validate health of domain controllers and replication services

##### # Validate health of domain controllers

```Console
dcdiag /s:TT-DC11
```

```Console
dcdiag /s:TT-DC12
```

```PowerShell
cls
```

##### # Validate health of replication services

```Console
repadmin /replsummary
```

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

> **Important**
>
> Wait for the computer to restart to complete the process of demoting the domain controller.

##### # Remove Active Directory Domain Services and DNS roles

```PowerShell
Uninstall-WindowsFeature AD-Domain-Services, DNS -Restart
```

> **Important**
>
> Wait for the computer to restart to complete the removal of the roles.

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
$ipAddress = "10.1.30.3"

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
    -ServerAddresses 10.1.30.2
```

## Configure domain controller

### Log in as domain administrator

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

> **Important**
>
> Wait for the initial directory synchronization to complete and for the server to restart.

### # Configure firewall for cross-forest trust (EXTRANET --> TECHTOOLBOX)

```PowerShell
reg add HKLM\SYSTEM\CurrentControlSet\Services\NTDS\Parameters `
    /v "TCP/IP Port" /t REG_DWORD /d 58349

reg add HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters `
    /v DCTcpipPort /t REG_DWORD /d 51164

Restart-Computer
```

## # Remove obsolete domain controller

### # Remove obsolete domain controller from Active Directory

```PowerShell
Get-ADComputer TT-DC11 | Remove-ADObject -Recursive -Confirm:$false
```

---

**TT-ADMIN05** - Run as administrator

```PowerShell
cls
```

### # Delete obsolete domain controller VM

```PowerShell
Remove-SCVirtualMachine TT-DC11
```

---

```PowerShell
cls
```

## # Configure backups

### # Add Windows Server Backup feature

```PowerShell
Add-WindowsFeature Windows-Server-Backup
```

### # Add exclusions to Microsoft Defender Antivirus scans for backups

#### # Add exclusion for dedicated backup disk

```PowerShell
Add-MpPreference -ExclusionPath "\Device\HarddiskVolumeShadowCopy*\"
```

##### Reference

[Exclude backups (Volume Shadow Copy) from Windows Defender](https://superuser.com/a/1704700)

> **Note**
>
> The above exclusion avoids antivirus scanning when _writing_ files to the disk dedicated for backups (which can be observed -- without the exclusion added -- by using Process Monitor from the Sysinternals tools). However, if that is the only exclusion configured, very high CPU usage is still observed for the **Antimalware Service Executable** process when a backup is running (due to antivirus scans when _reading_ files to backup). To avoid this, exclude the process for **Windows Server Backup** as well.

#### # Add exclusion for Windows Server Backup process

```PowerShell
Add-MpPreference -ExclusionProcess "C:\Windows\System32\wbengine.exe"
```

```PowerShell
cls
```

### # Add server to DPM protection group

#### # Configure firewall rule for remote install of DPM agent

```PowerShell
New-NetFirewallRule `
    -Name "DPM Remote Agent Install" `
    -DisplayName "DPM Remote Agent Install" `
    -Group "Technology Toolbox (Custom)" `
    -Direction Inbound `
    -RemoteAddress (Resolve-DnsName TT-DPM07).IPAddress `
    -Action Allow
```

#### Install DPM protection agent

```PowerShell
cls
```

#### # Disable firewall rule for remote install of DPM agent

```PowerShell
Disable-NetFirewallRule -Name "DPM Remote Agent Install"
```

#### Add server to Domain Controllers protection group in DPM

| Selected Members                                           | Computer     |
| ---------------------------------------------------------- | ------------ |
| System Protection\System State (includes Active Directory) | TT-DC13      |
| D:\                                                        | TT-DC13      |

```PowerShell
cls
```

## # Configure monitoring

### # Copy SCOM agent installation files

```PowerShell
$source = "\\TT-FS01\Products\Microsoft\System Center 2019\SCOM\Agent\AMD64"
$destination = "C:\NotBackedUp\Temp\SCOM\Agent\AMD64"

robocopy $source $destination /E
```

### # Install SCOM agent

```PowerShell
$installerPath = "C:\NotBackedUp\Temp\SCOM\Agent\AMD64\MOMAgent.msi"

$installerArguments = "MANAGEMENT_GROUP=HQ" `
    + " MANAGEMENT_SERVER_DNS=tt-scom01c.corp.technologytoolbox.com" `
    + " ACTIONS_USE_COMPUTER_ACCOUNT=1"

Start-Process `
    -FilePath msiexec.exe `
    -ArgumentList "/i `"$installerPath`" $installerArguments" `
    -Wait
```

In the **Microsoft Monitoring Agent Setup** window:

1. On the **Agent Setup Options** step, select the **Connect the agent to System Center Operations Manager** checkbox, and then click **Next**.
1. On the **Microsoft Update** step, select **Use Microsoft Update when I check for updates (recommended)**, and then click **Next**.

> **Important**
>
> Wait for the installation to complete.

```PowerShell
cls
```

#### # Remove Operations Manager installation files

```PowerShell
Remove-Item C:\NotBackedUp\Temp\SCOM -Recurse
```

### Approve manual agent install in Operations Manager

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

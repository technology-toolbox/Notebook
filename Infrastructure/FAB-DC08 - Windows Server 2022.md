# FAB-DC08 - Windows Server 2022 Domain Controller

Monday, January 6, 2025\
5:41 AM

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
$vmHost = "TT-HV05E"
$vmName = "FAB-DC08"
$vmPath = "D:\NotBackedUp\VMs" # Start with SSD storage, then migrate to NAS
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
  - In the **Computer name** box, type **FAB-DC08**.
  - Select **Join a workgroup.**
  - In the **Workgroup** box, type **WORKGROUP**.
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

**TT-ADMIN05** - Run as administrator

```PowerShell
cls
```

### # Move VM to Fabrikam VM network

```PowerShell
$vmName = "FAB-DC08"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Fabrikam VM Network"

Stop-SCVirtualMachine $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork

Start-SCVirtualMachine $vmName
```

---

### Log in as local administrator account

```PowerShell
cls
```

### # Join domain

```PowerShell
Add-Computer -DomainName corp.fabrikam.com -Restart
```

> **Note**
>
> When prompted, enter the credentials for a domain administrator.

---

**FAB-DC06** - Run as domain administrator

```PowerShell
cls
```

### # Configure Windows Update

#### # Add machine to security group for Windows Update schedule

```PowerShell
Add-ADGroupMember -Identity "Windows Update - Slot 18" -Members "FAB-DC08$"
```

---

### Configure storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 32 GB       | 4K                   | OSDisk       |
| 1    | D:           | 5 GB        | 4K                   | Data01       |
| 2*   | (none)       | 65 GB       | 4K                   | Backup01     |

\* - Dedicated backup disk managed by Windows Server Backup

#### Configure separate VHDs for Active Directory data and backups

---

**TT-ADMIN05** - Run as administrator

```PowerShell
cls
```

##### # Add disk for Active Directory data

```PowerShell
$vmHost = "TT-HV05E"
$vmName = "FAB-DC08"

# Start with SSD storage, then migrate to NAS
$vhdPath = "D:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
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
# Start with SSD storage, then migrate to NAS
$vhdPath = "D:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Backup01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 65GB
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

> **Note**
>
> The dedicated backup disk is initialized and formatted when configuring backups.

```PowerShell
cls
```

### # Configure networking

```PowerShell
$interfaceAlias = "Fabrikam-40"
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

ping FAB-DC06 -f -l 8900
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

**FAB-DC06** - Run as domain administrator

```PowerShell
cls
```

#### # Validate health of domain controllers and replication services

##### # Validate health of domain controllers

```Console
dcdiag /s:FAB-DC07
```

```Console
dcdiag /s:FAB-DC06
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
$interfaceAlias = "Fabrikam-40"
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
$ipAddress = "10.0.40.3"

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
    -ServerAddresses 10.0.40.2
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
    -DomainName "corp.fabrikam.com" `
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

### # Configure firewall for cross-forest trust (EXTRANET --> FABRIKAM)

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
Get-ADComputer FAB-DC06 | Remove-ADObject -Recursive -Confirm:$false
```

---

**TT-ADMIN05** - Run as administrator

```PowerShell
cls
```

### # Delete obsolete domain controller VM

```PowerShell
Remove-SCVirtualMachine FAB-DC06
```

---

---

**TT-ADMIN05** - Run as administrator

```PowerShell
cls
```

## # Make virtual machine highly available

### # Migrate VM to shared storage

```PowerShell
$vmName = "FAB-DC08"

$vm = Get-SCVirtualMachine -Name $vmName
$vmHost = $vm.VMHost

# Note: Refresh VM properties to avoid issue where primary VHD (C:) is migrated
# to shared storage but secondary VHD (D:) is not

Read-SCVirtualMachine -VM $vm

Move-SCVirtualMachine `
    -VM $vm `
    -VMHost $vmHost `
    -HighlyAvailable $true `
    -Path "C:\ClusterStorage\iscsi02-Silver-03" `
    -UseDiffDiskOptimization
```

```PowerShell
cls
```

### # Allow migration to host with different processor version

```PowerShell
Stop-SCVirtualMachine -VM $vmName

Set-SCVirtualMachine -VM $vmName -CPULimitForMigration $true

Start-SCVirtualMachine -VM $vmName
```

```PowerShell
cls
```

## # Configure anti-affinity class names for virtual machines

```PowerShell
$antiAffinityClassNames = `
    New-Object System.Collections.Specialized.StringCollection

$antiAffinityClassNames.Add("FAB-DC")

(Get-ClusterGroup `
    -Cluster TT-HV05-FC `
    -Name 'SCVMM FAB-DC07 Resources' `
    ).AntiAffinityClassNames = $antiAffinityClassNames

(Get-ClusterGroup `
    -Cluster TT-HV05-FC `
    -Name 'SCVMM FAB-DC08 Resources' `
    ).AntiAffinityClassNames = $antiAffinityClassNames

Get-ClusterGroup -Cluster TT-HV05-FC |
    where { $_.GroupType -eq "VirtualMachine" } |
    select Name, AntiAffinityClassNames
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

### # Configure daily System State backup

#### # Schedule daily System State backup

```PowerShell
$policy = New-WBPolicy

Set-WBVssBackupOption -Policy $policy -VssFullBackup

Add-WBSystemState -Policy $policy

$backupDisk = Get-WBDisk | where { $_.Properties -match "ValidTarget" }

Get-Disk -Number $backupDisk.DiskNumber | Set-Disk -IsOffline $false

Get-Disk -Number $backupDisk.DiskNumber | Set-Disk -IsReadOnly $false

$backupTarget = New-WBBackupTarget -Disk $backupDisk -Label "Backup01"

Add-WBBackupTarget -Policy $policy -Target $backupTarget

Set-WBSchedule -Policy $policy 16:00

Set-WBPolicy -Policy $policy -Force
```

#### # Add scheduled task to remove old backups

```PowerShell
$action = New-ScheduledTaskAction `
    -Execute "wbadmin" `
    -Argument "delete systemstatebackup -keepVersions:4 -quiet"

$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -RunLevel Highest

$trigger = New-ScheduledTaskTrigger -Daily -At '3:55 PM'

$task = New-ScheduledTask `
    -Action $action `
    -Principal $principal `
    -Trigger $trigger

Register-ScheduledTask 'Delete old System State backups' -InputObject $task
```

### Add virtual machine to Hyper-V protection group in DPM

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

# EXT-DC13 - Windows Server 2022 Domain Controller

Saturday, May 24, 2025\
7:51 AM

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
$vmName = "EXT-DC13"
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
  - In the **Computer name** box, type **EXT-DC13**.
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

### # Move VM to Extranet VM network

```PowerShell
$vmName = "EXT-DC13"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Extranet-20 VM Network"

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
Add-Computer -DomainName extranet.technologytoolbox.com -Restart
```

> **Note**
>
> When prompted, enter the credentials for a domain administrator.

---

**EXT-DC11** - Run as domain administrator

```PowerShell
cls
```

### # Configure Windows Update

#### # Add machine to security group for Windows Update schedule

```PowerShell
Add-ADGroupMember -Identity "Windows Update - Slot 3" -Members "EXT-DC13$"
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
$vmHost = "TT-HV06B"
$vmName = "EXT-DC13"

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
$interfaceAlias = "Extranet-20"
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

ping EXT-DC11 -f -l 8900
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

**EXT-DC11** - Run as domain administrator

```PowerShell
cls
```

#### # Validate health of domain controllers and replication services

##### # Validate health of domain controllers

```Console
dcdiag /s:EXT-DC12
```

```Console
dcdiag /s:EXT-DC11
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
$interfaceAlias = "Extranet-20"
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
$ipAddress = "10.1.20.3"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24 `
    -DefaultGateway 10.1.20.1
```

##### # Configure IPv4 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 10.1.20.2
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
    -DomainName "extranet.technologytoolbox.com" `
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

## # Remove obsolete domain controller

### # Remove obsolete domain controller from Active Directory

```PowerShell
Get-ADComputer EXT-DC11 | Remove-ADObject -Recursive -Confirm:$false
```

---

**TT-ADMIN05** - Run as administrator

```PowerShell
cls
```

### # Delete obsolete domain controller VM

```PowerShell
Remove-SCVirtualMachine EXT-DC11
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
$vmName = "EXT-DC13"

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

$antiAffinityClassNames.Add("EXT-DC")

(Get-ClusterGroup `
    -Cluster TT-HV06-FC `
    -Name 'SCVMM EXT-DC12 Resources' `
    ).AntiAffinityClassNames = $antiAffinityClassNames

(Get-ClusterGroup `
    -Cluster TT-HV06-FC `
    -Name 'SCVMM EXT-DC13 Resources' `
    ).AntiAffinityClassNames = $antiAffinityClassNames

Get-ClusterGroup -Cluster TT-HV06-FC |
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

Set-WBSchedule -Policy $policy 17:00

Set-WBPolicy -Policy $policy -Force
```

#### # Add scheduled task to remove old backups

```PowerShell
$action = New-ScheduledTaskAction `
    -Execute "wbadmin" `
    -Argument "delete systemstatebackup -keepVersions:4 -quiet"

$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -RunLevel Highest

$trigger = New-ScheduledTaskTrigger -Daily -At '4:55 PM'

$task = New-ScheduledTask `
    -Action $action `
    -Principal $principal `
    -Trigger $trigger

Register-ScheduledTask 'Delete old System State backups' -InputObject $task
```

### Add virtual machine to Hyper-V protection group in DPM

```PowerShell
cls
```

## # Configure monitoring

### # Create certificate for Operations Manager

#### # Create request for Operations Manager certificate

```PowerShell
& "C:\NotBackedUp\Public\Toolbox\Operations Manager\Scripts\New-OperationsManagerCertificateRequest.ps1"
```

#### # Submit certificate request to the Certification Authority

##### # Add Active Directory Certificate Services site to the "Trusted sites" zone and browse to the site

```PowerShell
[Uri] $adcsUrl = [Uri] "https://cipher01.corp.technologytoolbox.com"

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-InternetSecurityZoneMapping.ps1 `
    -Zone LocalIntranet `
    -Patterns $adcsUrl.AbsoluteUri

Start-Process $adcsUrl.AbsoluteUri
```

##### # Submit the certificate request to an enterprise CA

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

```PowerShell
cls
```

#### # Import the certificate into the certificate store

```PowerShell
$certFile = "C:\Users\jjameson-admin\Downloads\certnew.cer"

CertReq.exe -Accept $certFile
```

```PowerShell
cls
```

#### # Delete the certificate file

```PowerShell
Remove-Item $certFile
```

---

**TT-ADMIN05** - Run as administrator

```PowerShell
cls
```

### # Copy SCOM agent installation files

```PowerShell
$computerName = "EXT-DC13.extranet.technologytoolbox.com"

net use "\\$computerName\IPC$" /USER:EXTRANET\jjameson-admin
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$source = "\\TT-FS01\Products\Microsoft\System Center 2019\SCOM\Agent\AMD64"
$destination = "\\$computerName\C`$\NotBackedUp\Temp\SCOM\Agent\AMD64"

robocopy $source $destination /E

$source = "\\TT-FS01\Products\Microsoft\System Center 2019\SCOM" `
    + "\SupportTools\AMD64"

$destination = "\\$computerName\C`$\NotBackedUp\Temp\SCOM\SupportTools\AMD64"

robocopy $source $destination /E
```

---

```PowerShell
cls
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

### # Import the certificate into Operations Manager using MOMCertImport

```PowerShell
$hostName = ([System.Net.Dns]::GetHostByName(($env:computerName))).HostName

$certImportToolPath = "C:\NotBackedUp\Temp\SCOM\SupportTools\AMD64"

Push-Location "$certImportToolPath"

.\MOMCertImport.exe /SubjectName $hostName

Pop-Location
```

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

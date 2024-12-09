# CON-DC05 - Windows Server 2019 Domain Controller

Friday, April 10, 2020\
8:52 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure server infrastructure

---

**TT-ADMIN03** - Run as administrator

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05D"
$vmName = "CON-DC05"
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

### Install custom Windows Server 2019 image

- On the **Task Sequence** step, select **Windows Server 2019** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **CON-DC05**.
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

---

**TT-ADMIN03** - Run as administrator

```PowerShell
cls
```

### # Move VM to Contoso VM network

```PowerShell
$vmName = "CON-DC05"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Contoso-60 VM Network"

Stop-SCVirtualMachine $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -MACAddressType Dynamic `
    -IPv4AddressType Dynamic

Start-SCVirtualMachine $vmName
```

---

### Login as .\\foo

### # Set MaxPatchCacheSize to 0 (recommended)

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

### # Join domain

```PowerShell
Add-Computer -DomainName corp.contoso.com -Restart
```

---

**CON-DC03** - Run as domain administrator

```PowerShell
cls
```

### # Configure Windows Update

#### # Add machine to security group for Windows Update schedule

```PowerShell
Add-ADGroupMember -Identity "Windows Update - Slot 17" -Members "CON-DC05$"
```

---

### Configure storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 32 GB       | 4K                   | OSDisk       |
| 1    | D:           | 5 GB        | 4K                   | Data01       |

#### Configure separate VHD for Active Directory data

---

**TT-ADMIN03** - Run as administrator

```PowerShell
cls
```

##### # Add disk for Active Directory data

```PowerShell
$vmHost = "TT-HV05D"
$vmName = "CON-DC05"

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

### # Configure networking

```PowerShell
$interfaceAlias = "Contoso-60"
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

ping CON-DC03 -f -l 8900
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

**CON-DC03** - Run as administrator

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
$interfaceAlias = "Contoso-60"
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
$ipAddress = "10.0.60.2"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24 `
    -DefaultGateway 10.0.60.1
```

##### # Configure IPv4 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 10.0.60.3
```

## Configure domain controller

### Login as CONTOSO\\Administrator

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
    -DomainName "corp.contoso.com" `
    -LogPath "D:\Windows\NTDS" `
    -SysvolPath "D:\Windows\SYSVOL" `
    -Force:$true
```

> **Note**
>
> When prompted, specify the password for the administrator account when the computer is started in Safe Mode or a variant of Safe Mode, such as Directory Services Restore Mode.

## Configure NTP

---

**TT-ADMIN03** - Run as administrator

```PowerShell
cls
```

### # Disable Hyper-V time synchronization service

```PowerShell
$vmHost = "TT-HV05D"
$vmName = "CON-DC05"

Disable-VMIntegrationService `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Name "Time Synchronization"
```

---

### # Configure NTP settings

```PowerShell
w32tm /config /syncfromflags:DOMHIER /update

Restart-Service w32time
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
    -Value ("time.windows.com,0x1 time-nw.nist.gov,0x1 time-b.nist.gov,0x1" `
        + " time.nist.gov,0x1 time-a.nist.gov,0x1")
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

#### # Configure DNS record for NTP (ntp.corp.contoso.com)

```PowerShell
Get-DnsServerResourceRecord -ZoneName corp.contoso.com -Name ntp |
    Remove-DnsServerResourceRecord -ZoneName corp.contoso.com -Force

Add-DnsServerResourceRecordCName `
    -ZoneName "corp.contoso.com" `
    -Name "ntp" `
    -HostNameAlias "CON-DC05.corp.contoso.com"
```

---

**TT-ADMIN03** - Run as administrator

```PowerShell
cls
```

## # Make virtual machine highly available

### # Migrate VM to shared storage

```PowerShell
$vm = Get-SCVirtualMachine -Name "CON-DC05"

# Note: Refresh VM properties to avoid issue where primary VHD (C:) is migrated
# to shared storage but secondary VHD (D:) is not

Read-SCVirtualMachine -VM $vm

Move-SCVirtualMachine `
    -VM $vm `
    -VMHost $vm.VMHost `
    -HighlyAvailable $true `
    -Path "C:\ClusterStorage\iscsi02-Silver-01" `
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

$antiAffinityClassNames.Add("CON-DC")

(Get-ClusterGroup `
    -Cluster TT-HV05-FC `
    -Name 'SCVMM CON-DC05 Resources').AntiAffinityClassNames = `
    $antiAffinityClassNames

(Get-ClusterGroup `
    -Cluster TT-HV05-FC `
    -Name 'SCVMM CON-DC06 Resources').AntiAffinityClassNames = `
    $antiAffinityClassNames

Get-ClusterGroup -Cluster TT-HV05-FC |
    where { $_.GroupType -eq "VirtualMachine" } |
    select Name, AntiAffinityClassNames
```

---

## Configure backups

### Add virtual machine to Hyper-V protection group in DPM

**TODO:**

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

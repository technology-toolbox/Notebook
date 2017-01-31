# TT-SOFS01A - Windows Server 2016

Tuesday, January 31, 2017
5:04 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV03"
$vmName = "TT-SOFS01A"
$vmPath = "D:\NotBackedUp\VMs"
$vhdFolderPath = "$vmPath\$vmName\Virtual Hard Disks"
$vhdPath = "$vhdFolderPath\$vmName.vhdx"
$sysPrepedImage = "\\TT-FS01\VM-Library\VHDs\WS2016-Std-Core.vhdx"

$vhdUncPath = "\\$vmHost\" + $vhdPath.Replace(":", "`$")

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 2GB `
    -SwitchName "Tenant vSwitch"

Copy-Item $sysPrepedImage $vhdUncPath

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 4 `
    -DynamicMemory `
    -MemoryMaximumBytes 8GB

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Set password for the local Administrator account

```Console
PowerShell
```

```Console
cls
```

### # Rename local Administrator account

```PowerShell
$adminUser = [ADSI] 'WinNT://./Administrator,User'

$adminUser.Rename('foo')

logoff
```

### Rename server and join domain

#### Login as local administrator account

```Console
PowerShell
```

```Console
cls
```

### # Rename server

```PowerShell
Rename-Computer -NewName TT-SOFS01A -Restart
```

> **Note**
>
> Wait for the VM to restart.

#### Login as local administrator account

```Console
PowerShell
```

```Console
cls
```

### # Join server to domain

```PowerShell
Add-Computer -DomainName corp.technologytoolbox.com -Restart
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Move computer to different OU

```PowerShell
$vmName = "TT-SOFS01A"

$targetPath = ("OU=Storage Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

### # Add fabric administrators domain group to local Administrators group on file servers

```PowerShell
$command = 'net localgroup Administrators "TECHTOOLBOX\Fabric Admins" /ADD'

$scriptBlock = [ScriptBlock]::Create($command)

Invoke-Command -ComputerName $vmName -ScriptBlock $scriptBlock
```

---

## Configure networking

### Login as fabric adminstrator

```Console
PowerShell
```

```Console
cls
```

### # Configure network settings

```PowerShell
$interfaceAlias = "Datacenter 1"
```

#### # Rename network connection

```PowerShell
Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping TT-FS01 -f -l 8900
```

---

**FOOBAR8**

```PowerShell
cls
```

### # Add a network adapters for iSCSI storage

```PowerShell
$vmHost = "TT-HV03"
$vmName = "TT-SOFS01A"

Stop-VM -ComputerName $vmHost -Name $vmName

Add-VMNetworkAdapter `
    -ComputerName $vmHost `
    -VMName $vmName `
    -SwitchName "Internal vSwitch 1"

Add-VMNetworkAdapter `
    -ComputerName $vmHost `
    -VMName $vmName `
    -SwitchName "Internal vSwitch 2"

Start-VM -ComputerName $vmHost -Name $vmName
```

---

#### Login as fabric adminstrator

```Console
PowerShell
```

```Console
cls
```

### # Configure iSCSI storage network adapters

#### # Rename network connection

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter #2" |
    Rename-NetAdapter -NewName "iSCSI 1"

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter #3" |
    Rename-NetAdapter -NewName "iSCSI 2"
```

#### # Configure static IPv4 addresses

```PowerShell
$interfaceAlias = "iSCSI 1"
$ipAddress = "10.1.12.4"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24

$interfaceAlias = "iSCSI 2"
$ipAddress = "10.1.12.5"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24
```

#### # Configure network adapters for dedicated iSCSI traffic

```PowerShell
@("iSCSI 1", "iSCSI 2") |
    % {
        $interfaceAlias = $_

        Disable-NetAdapterBinding -Name $interfaceAlias `
            -DisplayName "Client for Microsoft Networks"

        Disable-NetAdapterBinding -Name $interfaceAlias `
            -DisplayName "File and Printer Sharing for Microsoft Networks"

        Disable-NetAdapterBinding -Name $interfaceAlias `
            -DisplayName "Link-Layer Topology Discovery Mapper I/O Driver"

        Disable-NetAdapterBinding -Name $interfaceAlias `
            -DisplayName "Link-Layer Topology Discovery Responder"

        $adapter = Get-WmiObject -Class "Win32_NetworkAdapter" `
            -Filter "NetConnectionId = '$interfaceAlias'"

        $adapterConfig = Get-WmiObject -Class "Win32_NetworkAdapterConfiguration" `
            -Filter "Index= '$($adapter.DeviceID)'"

        # Do not register this connection in DNS
        $adapterConfig.SetDynamicDNSRegistration($false)

        # Disable NetBIOS over TCP/IP
        $adapterConfig.SetTcpipNetbios(2)

        # Enable jumbo frames
        Set-NetAdapterAdvancedProperty -Name $interfaceAlias `
            -DisplayName "Jumbo Packet" -RegistryValue 9014
    }

Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"
```

```PowerShell
cls
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

### Login as fabric administrator account

```Console
PowerShell
```

```Console
cls
```

### # Configure networking

#### # Configure network settings

```PowerShell
$interfaceAlias = "Datacenter 1"
```

#### # Rename network connection

```PowerShell
Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping TT-FS01 -f -l 8900
```

## Configure failover clustering network

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Add a second network adapter for cluster network

```PowerShell
$vmHost = "FORGE"
$vmName = "TT-SOFS01A"

Stop-VM -ComputerName $vmHost -Name $vmName

Add-VMNetworkAdapter -ComputerName $vmHost -VMName $vmName -SwitchName "Production"

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Login as fabric adminstrator

```Console
PowerShell
```

```Console
cls
```

### # Configure cluster network settings

#### # Configure cluster network adapter

```PowerShell
$interfaceAlias = "Cluster"
```

##### # Configure cluster network adapter

```PowerShell
Get-NetAdapter `
    -InterfaceDescription "Microsoft Hyper-V Network Adapter #2" |
    Rename-NetAdapter -NewName $interfaceAlias
```

##### # Disable DHCP and router discovery

```PowerShell
Set-NetIPInterface -InterfaceAlias $interfaceAlias -Dhcp Disabled -RouterDiscovery Disabled
```

##### # Configure static IPv4 address

```PowerShell
$ipAddress = "172.16.3.1"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24
```

#### # Configure static IPv6 address

**# Note:** Private IPv6 address range (fd66:d7e2:39d6:a4d9::/64) generated by [http://simpledns.com/private-ipv6.aspx](http://simpledns.com/private-ipv6.aspx)

```PowerShell
$ipAddress = "fd66:d7e2:39d6:a4db::1"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 64
```

## Configure storage

### Login using fabric administrator account

```Console
PowerShell
```

### # Change drive letter for DVD-ROM

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
```

### Configure shared storage for SOFS cluster

#### Configure iSCSI server

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

##### # Create iSCSI target

```PowerShell
$initiatorIds = @(
    "IQN:iqn.1991-05.com.microsoft:tt-sofs01a.corp.technologytoolbox.com",
    "IQN:iqn.1991-05.com.microsoft:tt-sofs01b.corp.technologytoolbox.com")

New-IscsiServerTarget `
    -ComputerName ICEMAN `
    -TargetName TT-SOFS01 `
    -InitiatorIds $initiatorIds
```

##### # Create iSCSI disks

```PowerShell
New-IscsiVirtualDisk `
    -ComputerName ICEMAN `
    -Path E:\iSCSIVirtualDisks\TT-SOFS01_Quorum.vhdx `
    -SizeBytes 512MB

New-IscsiVirtualDisk `
    -ComputerName ICEMAN `
    -Path E:\iSCSIVirtualDisks\TT-SOFS01_Data01.vhdx `
    -SizeBytes 150GB
```

##### # Map iSCSI disks to target

```PowerShell
Add-IscsiVirtualDiskTargetMapping `
    -ComputerName ICEMAN `
    -TargetName TT-SOFS01 `
    -Path E:\iSCSIVirtualDisks\TT-SOFS01_Quorum.vhdx

Add-IscsiVirtualDiskTargetMapping `
    -ComputerName ICEMAN `
    -TargetName TT-SOFS01 `
    -Path E:\iSCSIVirtualDisks\TT-SOFS01_Data01.vhdx
```

---

```PowerShell
cls
```

#### # Configure iSCSI client

##### # Start iSCSI service

```PowerShell
Set-Service msiscsi -StartupType Automatic

Start-Service msiscsi
```

##### # Connect to iSCSI Portal

```PowerShell
New-IscsiTargetPortal -TargetPortalAddress iscsi-01

Connect-IscsiTarget `
    -NodeAddress "iqn.1991-05.com.microsoft:iceman-tt-sofs01-target" `
    -IsPersistent $true
```

##### # Online and initialize disks

```PowerShell
Get-Disk |
    ? {$_.FriendlyName -eq "MSFT Virtual HD"} |
    % {
        $disk = $_

        If ($disk.IsOffline -eq $true) {
            Set-Disk -Number $disk.Number -IsOffline $false
        }

        If ($disk.PartitionStyle -eq 'RAW') {
            Initialize-Disk -Number $disk.Number -PartitionStyle MBR
        }
    }
```

## Deploy Scale-Out File Server

**Install Prerequisites for Scale-Out File Server**\
From <[https://technet.microsoft.com/en-us/library/hh831478(v=ws.11).aspx](https://technet.microsoft.com/en-us/library/hh831478(v=ws.11).aspx)>

```PowerShell
cls
```

### # Install role services and features

```PowerShell
Install-WindowsFeature -Name Failover-Clustering, File-Services -IncludeManagementTools
```

```PowerShell
cls
```

### # Run all cluster validation tests

```PowerShell
Test-Cluster -Node TT-SOFS01A, TT-SOFS01B
```

> **Note**
>
> Wait for the cluster validation tests to complete.

### # Review cluster validation report

```PowerShell
$source = "$env:TEMP\Validation Report 2017.01.14 At 18.03.21.htm"
$destination = "\\ICEMAN.corp.technologytoolbox.com\Public"

Copy-Item $source $destination
```

---

**WOLVERINE**

```PowerShell
& "\\ICEMAN\Public\Validation Report 2017.01.14 At 18.03.21.htm"
```

---

```PowerShell
cls
```

### # Create cluster

```PowerShell
New-Cluster -Name TT-SOFS01-FC -Node TT-SOFS01A, TT-SOFS01B

WARNING: There were issues while creating the clustered role that may prevent it from starting. For more information view the report file below.
WARNING: Report file location: C:\windows\cluster\Reports\Create Cluster Wizard TT-VMM01-FC on 2017.01.12 At 05.31.12.htm

Name
----
TT-VMM01-FC


& "C:\windows\cluster\Reports\Create Cluster Wizard TT-VMM01-FC on 2017.01.12 At 05.31.12.htm"
```

> **Note**
>
> The cluster creation report contains the following warnings:
>
> - **An appropriate disk was not found for configuring a disk witness. The cluster is not configured with a witness. As a best practice, configure a witness to help achieve the highest availability of the cluster. If this cluster does not have shared storage, configure a File Share Witness or a Cloud Witness.**

## Benchmark storage performance

### Benchmark C: (Mirror SSD/HDD storage space)

### Benchmark D: (Mirror SSD storage space - 2x Samsung 840 512GB)

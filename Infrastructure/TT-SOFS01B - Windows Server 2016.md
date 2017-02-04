# TT-SOFS01B - Windows Server 2016

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
$vmName = "TT-SOFS01B"
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
    -SwitchName "Embedded Team Switch"

Copy-Item $sysPrepedImage $vhdUncPath

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 4 `
    -DynamicMemory `
    -MemoryMinimumBytes 2GB `
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
Rename-Computer -NewName TT-SOFS01B -Restart
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
$vmName = "TT-SOFS01B"

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
$interfaceAlias = "Management"
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

Start-Sleep -Seconds 15

ping TT-FS01 -f -l 8900
```

---

**FOOBAR8**

```PowerShell
cls
```

#### # Add network adapters for iSCSI storage

```PowerShell
$vmHost = "TT-HV03"
$vmName = "TT-SOFS01B"

Stop-SCVirtualMachine -VM $vmName
```

PS C:\\>\$VM = Get-SCVirtualMachine -Name "VM05"\
PS C:\\> \$LogicalNet = Get-SCLogicalNetwork -Name "LogicalNetwork01"\
PS C:\\> \$VirtualNet = Get-SCVirtualNetwork -Name "ExternalVirtualNetwork01"

New-SCVirtualNetworkAdapter `\
-VM \$VM `\
-LogicalNetwork \$LogicalNet `\
-VirtualNetwork \$VirtualNet `\
-MACAddress "00-16-D3-CC-00-1A" `\
-MACAddressType "Static" `\
-VLANEnabled \$True `\
-VLANId 3

```PowerShell
New-SCVirtualNetworkAdapter -VirtualNetwork "Internal vSwitch 1" -Synthetic

New-SCVirtualNetworkAdapter -VMMServer tt-vmm01 -JobGroup c636f0a6-3fcd-4ff3-9883-86b0714fd442 -VirtualNetwork "Internal vSwitch 2" -Synthetic

$VMSubnet = Get-SCVMSubnet -VMMServer tt-vmm01 -Name "Storage VM Network_0" | where {$_.VMNetwork.ID -eq "f3ed0cfe-df0b-4653-9879-c7a0c0d1a459"}

$VMNetwork = Get-SCVMNetwork -VMMServer tt-vmm01 -Name "Storage VM Network" -ID "f3ed0cfe-df0b-4653-9879-c7a0c0d1a459"

$PortClassification = Get-SCPortClassification -VMMServer tt-vmm01 | where {$_.Name -eq "SMB workload"}

New-SCVirtualNetworkAdapter -VMMServer tt-vmm01 -JobGroup c636f0a6-3fcd-4ff3-9883-86b0714fd442 -MACAddressType Dynamic -VirtualNetwork "Embedded Team Switch" -Synthetic -IPv4AddressType Dynamic -IPv6AddressType Dynamic -VMSubnet $VMSubnet -VMNetwork $VMNetwork -PortClassification $PortClassification



$VirtualNetworkAdapter = Get-SCVirtualNetworkAdapter -VMMServer tt-vmm01 -Name "TT-SOFS01B" -ID "504d4cb9-5254-405c-ae31-ed888063726b"
$VMNetwork = Get-SCVMNetwork -VMMServer tt-vmm01 -Name "Management VM Network" -ID "11ceb7c3-7522-47e5-84c0-7f5fe50519fb"
$PortClassification = Get-SCPortClassification -VMMServer tt-vmm01 | where {$_.Name -eq "Host management"}

Set-SCVirtualNetworkAdapter -VirtualNetworkAdapter $VirtualNetworkAdapter -VMNetwork $VMNetwork -VLanEnabled $false -VirtualNetwork "Embedded Team Switch" -MACAddressType Dynamic -IPv4AddressType Dynamic -IPv6AddressType Dynamic -PortClassification $PortClassification -JobGroup c636f0a6-3fcd-4ff3-9883-86b0714fd442












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

```PowerShell
cls
```

#### # Add network adapters for SMB traffic (SOFS storage)

```PowerShell
$vmHost = "TT-HV03"
$vmName = "TT-SOFS01B"

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
$ipAddress = "10.1.13.4"

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

### # Install Multipath I/O

```PowerShell
Install-WindowsFeature -Name Multipath-IO -IncludeManagementTools -Restart
```

### Login as fabric administrator account

```Console
PowerShell
```

```Console
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

### # Configure iSCSI client

#### # Start iSCSI service

```PowerShell
Set-Service msiscsi -StartupType Automatic

Start-Service msiscsi
```

#### # Connect to iSCSI Portal

```PowerShell
New-IscsiTargetPortal -TargetPortalAddress iscsi01

Start-Sleep 30

Connect-IscsiTarget `
    -NodeAddress "iqn.1991-05.com.microsoft:tt-hv03-tt-sofs01-target" `
    -IsPersistent $true
```

```PowerShell
cls
```

#### # Online and initialize disks

```PowerShell
$iscsiDisks = Get-Disk | ? {$_.BusType -eq "iSCSI"}

$quorumDiskNumber = $iscsiDisks |
    sort Size |
    select -First 1 |
    select -ExpandProperty Number

$iscsiDisks |
    % {
        $disk = $_

        If ($disk.IsOffline -eq $true) {
            Set-Disk -Number $disk.Number -IsOffline $false
        }

        If ($disk.PartitionStyle -eq 'RAW') {
            If ($disk.Number -eq $quorumDiskNumber) {
                # Note: ReFS cannot be used on small disks (e.g. 512 MB)

                Initialize-Disk -Number $disk.Number -PartitionStyle GPT -PassThru |
                    New-Partition -UseMaximumSize |
                    Format-Volume `
                        -FileSystem NTFS `
                        -NewFileSystemLabel "Quorum" `
                        -Confirm:$false
            }
            Else {
                Initialize-Disk -Number $disk.Number -PartitionStyle GPT -PassThru |
                    New-Partition -UseMaximumSize |
                    Format-Volume `
                        -FileSystem ReFS `
                        -NewFileSystemLabel "CSV01" `
                        -Confirm:$false
            }
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

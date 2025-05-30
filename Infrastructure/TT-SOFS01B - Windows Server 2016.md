# TT-SOFS01B - Windows Server 2016

Tuesday, January 31, 2017\
5:04 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

---

**FOOBAR8** - Run as administrator

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
    -SwitchName "Team Switch"

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

**FOOBAR8** - Run as administrator

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

**TT-VMM01A** - Run as administrator

```PowerShell
cls
```

#### # Set port classification on management network adapter

```PowerShell
$vmName = "TT-SOFS01B"

$vm = Get-SCVirtualMachine $vmName

$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vm

$portClassification = Get-SCPortClassification -Name "Host management"

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -PortClassification $PortClassification
```

#### # Add network adapters for iSCSI and SMB (SOFS) traffic

```PowerShell
Stop-SCVirtualMachine -VM $vm
```

##### # Add two internal network adapters for iSCSI traffic

```PowerShell
New-SCVirtualNetworkAdapter -VM $vm -VirtualNetwork "Internal vSwitch 1" -Synthetic
New-SCVirtualNetworkAdapter -VM $vm -VirtualNetwork "Internal vSwitch 2" -Synthetic
```

##### # Add network adapter for SMB traffic

```PowerShell
$vmNetwork = Get-SCVMNetwork -Name "Storage VM Network"

$vmSubnet = $vmNetwork.VMSubnet[0]

$portClassification = Get-SCPortClassification -Name "SMB workload"

$networkAdapter = New-SCVirtualNetworkAdapter `
    -VirtualNetwork "Embedded Team Switch" `
    -PortClassification $portClassification `
    -Synthetic `
    -VM $vm `
    -VMNetwork $vmNetwork `
    -VMSubnet $vmSubnet
```

##### # Assign static IP address to network adapter for SMB traffic

```PowerShell
$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"

$ipAddressPool = Get-SCStaticIPAddressPool -Name "Storage Address Pool"

$macAddress = Grant-SCMACAddress `
    -MACAddressPool $macAddressPool `
    -Description $vm.Name `
    -VirtualNetworkAdapter $networkAdapter

$ipAddress = Grant-SCIPAddress `
    -GrantToObjectType VirtualNetworkAdapter `
    -GrantToObjectID $networkAdapter.ID `
    -StaticIPAddressPool $ipAddressPool `
    -Description $vm.Name

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -MACAddressType Static `
    -MACAddress $macAddress `
    -IPv4AddressType Static `
    -IPv4Address $ipAddress
```

#### # Restart VM

```PowerShell
Start-SCVirtualMachine -VM $vm
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
$iScsiAdapters = Get-NetAdapter -Physical |
    where { $_.LinkSpeed -eq "10 Gbps" } |
    sort ifIndex

$iScsiAdapters[0] | Rename-NetAdapter -NewName "iSCSI 1"
$iScsiAdapters[1] | Rename-NetAdapter -NewName "iSCSI 2"
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
    foreach {
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
```

```PowerShell
cls
```

### # Configure SMB storage network adapter

```PowerShell
$interfaceAlias = "Storage"
```

#### # Rename network connection

```PowerShell
$networkAdapter = Get-NetAdapter -Physical |
    where { $_.LinkSpeed -eq "2 Gbps" -and $_.Name -ne "Management" }

$networkAdapter | Rename-NetAdapter -NewName $interfaceAlias
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

### Configure iSCSI client

```PowerShell
cls
```

#### # Start iSCSI service

```PowerShell
Set-Service msiscsi -StartupType Automatic

Start-Service msiscsi
```

#### # Configure MPIO settings

##### # Enable automatic claiming of all iSCSI volumes

```PowerShell
Enable-MSDSMAutomaticClaim -BusType iSCSI
```

##### # Set default load balancing policy

```PowerShell
Set-MSDSMGlobalDefaultLoadBalancePolicy -Policy RR
```

##### # Configure disk timeout

```PowerShell
Set-MPIOSetting -NewDiskTimeout 60

Restart-Computer
```

### Login as fabric administrator account

```Console
PowerShell
```

#### # Connect to iSCSI portal (using multiple paths)

```PowerShell
New-IscsiTargetPortal `
    -TargetPortalAddress 10.1.12.2 `
    -InitiatorPortalAddress 10.1.12.4

New-IscsiTargetPortal `
    -TargetPortalAddress 10.1.13.2 `
    -InitiatorPortalAddress 10.1.13.4

Start-Sleep 30
```

#### # Connect first path to iSCSI target

```PowerShell
Connect-IscsiTarget `
    -NodeAddress "iqn.1991-05.com.microsoft:tt-hv03-tt-sofs01-target" `
    -TargetPortalAddress 10.1.12.2 `
    -InitiatorPortalAddress 10.1.12.4 `
    -IsMultipathEnabled $true `
    -IsPersistent $true
```

#### # Connect additional paths to iSCSI target

```PowerShell
Connect-IscsiTarget `
    -NodeAddress "iqn.1991-05.com.microsoft:tt-hv03-tt-sofs01-target" `
    -TargetPortalAddress 10.1.13.2 `
    -InitiatorPortalAddress 10.1.13.4 `
    -IsMultipathEnabled $true `
    -IsPersistent $true
```

```PowerShell
cls
```

#### # Online and initialize disks

```PowerShell
$iscsiDisks = Get-Disk | where {$_.BusType -eq "iSCSI"}

$quorumDiskNumber = $iscsiDisks |
    sort Size |
    select -First 1 |
    select -ExpandProperty Number

$iscsiDisks |
    foreach {
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

```PowerShell
cls
```

### # Configure networking -- after VMM switch fiasco

#### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select Name, InterfaceDescription | sort InterfaceDescription

Get-NetAdapter `
    -InterfaceDescription "Microsoft Hyper-V Network Adapter #4" |
    Rename-NetAdapter -NewName "Storage 1"

Get-NetAdapter `
    -InterfaceDescription "Microsoft Hyper-V Network Adapter #5" |
    Rename-NetAdapter -NewName "Storage 2"
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapter -Physical |
    foreach {
        Set-NetAdapterAdvancedProperty -Name $_.Name `
            -DisplayName "Jumbo Packet" -RegistryValue 9014
    }

Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"
```

```PowerShell
cls
```

#### # Configure static IP addresses on "Storage 1" network

```PowerShell
$interfaceAlias = "Storage 1"
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
$ipAddress = "10.1.10.11"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24
```

##### # Configure static IPv6 address

**# Note:** Private IPv6 address range (fd87:77eb:097e:95a1::/64) generated by [http://simpledns.com/private-ipv6.aspx](http://simpledns.com/private-ipv6.aspx)

```PowerShell
$ipAddress = "fd87:77eb:097e:95a1::11"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 64
```

##### # Configure IPv4 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 192.168.10.103,192.168.10.104
```

##### # Configure IPv6 DNS servers

```PowerShell
Set-DnsClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 2603:300b:802:8900::103, 2603:300b:802:8900::104
```

```PowerShell
cls
```

#### # Configure static IP addresses on "Storage 2" network

```PowerShell
$interfaceAlias = "Storage 2"
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
$ipAddress = "10.1.10.12"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24
```

##### # Configure static IPv6 address

```PowerShell
$ipAddress = "fd87:77eb:097e:95a1::12"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 64
```

##### # Configure IPv4 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 192.168.10.103,192.168.10.104
```

##### # Configure IPv6 DNS servers

```PowerShell
Set-DnsClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 2603:300b:802:8900::103, 2603:300b:802:8900::104
```

```PowerShell
cls
```

## # Install DPM agent

### # Install DPM 2016 agent

```PowerShell
net use \\TT-FS01\Products /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$installer = "\\TT-FS01\Products\Microsoft\System Center 2016" `
    + "\Agents\DPMAgentInstaller_x64.exe"

& $installer TT-DPM01.corp.technologytoolbox.com
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

**TT-DPM01** - DPM Management Shell

```PowerShell
cls
```

### # Attach DPM agent

```PowerShell
$productionServer = 'TT-SOFS01B'

.\Attach-ProductionServer.ps1 `
    -DPMServerName TT-DPM01 `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `
    -UserName jjameson-admin
```

---

## Issue - Incorrect IPv6 DNS server assigned by Comcast router

```Text
PS C:\Users\jjameson-admin> nslookup
Default Server:  cdns01.comcast.net
Address:  2001:558:feed::1
```

> **Note**
>
> Even after reconfiguring the **Primary DNS** and **Secondary DNS** settings on the Comcast router -- and subsequently restarting the VM -- the incorrect DNS server is assigned to the network adapter.

### Solution

```PowerShell
Set-DnsClientServerAddress `
    -InterfaceAlias Management `
    -ServerAddresses 2603:300b:802:8900::103, 2603:300b:802:8900::104

Restart-Computer
```

## Rebuild DPM 2016 server (replace TT-DPM01 with TT-DPM02)

```Console
PowerShell
```

### # Remove DPM agent

```PowerShell
MsiExec.exe /X "{14DD5B44-17CE-4E89-8BEB-2E6536B81B35}"
```

> **Note**
>
> The command to remove the DPM agent can be obtained from the following PowerShell:
>
> ```PowerShell
> Get-ChildItem HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall |
>     Get-ItemProperty |
>     where { $_.DisplayName -eq 'Microsoft System Center 2016  DPM Protection Agent' } |
>     select UninstallString
> ```

Restart the server to complete the removal.

```PowerShell
Restart-Computer
```

> **Note**
>
> Wait for the computer to restart.

```Console
PowerShell
```

### # Install DPM agent

```PowerShell
$installer = "\\TT-FS01\Products\Microsoft\System Center 2016" `
    + "\DPM\Agents\DPMAgentInstaller_x64.exe"

& $installer TT-DPM02.corp.technologytoolbox.com
```

---

**TT-DPM02** - DPM Management Shell

```PowerShell
cls
```

### # Attach DPM agent

```PowerShell
$productionServer = 'TT-SOFS01B'

.\Attach-ProductionServer.ps1 `
    -DPMServerName TT-DPM02 `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `
    -UserName jjameson-admin
```

---

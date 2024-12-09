# TT-MGMT01 - Windows Server 2016

Saturday, January 21, 2017\
7:37 AM

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
$vmHost = "TT-HV02A"
$vmName = "TT-MGMT01"
$vmPath = "E:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"
$sysPrepedImage = "\\TT-FS01\VM-Library\VHDs\WS2016-Std.vhdx"

$vhdUncPath = $vhdPath.Replace("E:", "\\TT-HV02A\E$")

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
    -ProcessorCount 2 `
    -DynamicMemory `
    -MemoryMinimumBytes 512MB `
    -MemoryMaximumBytes 4GB

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Set password for the local Administrator account

```PowerShell
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

```PowerShell
cls
```

### # Rename server

```PowerShell
Rename-Computer -NewName TT-MGMT01 -Restart
```

> **Note**
>
> Wait for the VM to restart.

#### Login as local administrator account

```PowerShell
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
$vmName = "TT-MGMT01"

$targetPath = ("OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

---

```PowerShell
cls
```

### # Set time zone

```PowerShell
tzutil /s "Mountain Standard Time"
```

### # Copy Toolbox content

```PowerShell
$source = "\\TT-FS01\Public\Toolbox"
$destination = "C:\NotBackedUp\Public\Toolbox"

robocopy $source $destination  /E /XD "Microsoft SDKs"
```

### # Set MaxPatchCacheSize to 0 (recommended)

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

```PowerShell
cls
```

### # Configure networking

#### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "Datacenter 1"
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name "Datacenter 1" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

ping ICEMAN -f -l 8900
```

```PowerShell
cls
```

#### # Configure static IP addresses on "Datacenter 1" network

```PowerShell
$interfaceAlias = "Datacenter 1"
```

##### # Configure static IPv4 address

```PowerShell
$ipAddress = "192.168.10.101"

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
    -ServerAddresses 192.168.10.103,192.168.10.104
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

```PowerShell
cls
```

## # Deploy DHCP server

### # Add roles for DHCP

```PowerShell
Install-WindowsFeature `
    -Name DHCP `
    -IncludeManagementTools `
    -Restart
```

```PowerShell
cls
```

### # Add DHCP local security groups

```PowerShell
Add-DhcpServerSecurityGroup
```

#### Reference

**DHCP default local security groups**\
From <[https://technet.microsoft.com/en-us/library/ee941205(v=ws.10).aspx](https://technet.microsoft.com/en-us/library/ee941205(v=ws.10).aspx)>

```PowerShell
# Create IPv4 scope

Add-DhcpServerv4Scope `
    -Name "Scope 1" `
    -StartRange 192.168.10.2 `
    -EndRange 192.168.10.100 `
    -SubnetMask 255.255.255.0 `
    -State Inactive

Set-DhcpServerv4OptionValue -ScopeId 192.168.10.0 -OptionId 3 -Value 192.168.10.1

Set-DhcpServerv4OptionValue -ScopeId 192.168.10.0 -OptionId 6 -Value 192.168.10.103, 192.168.10.104

Set-DhcpServerv4OptionValue -ScopeId 192.168.10.0 -OptionId 15 -Value corp.technologytoolbox.com

# Create IPv6 scope

Add-DhcpServerv6Scope `
    -Name "Scope 1" `
    -Prefix 2603:300b:802:8900:: `
    -State Inactive

# Set DHCPv6 scope option - "23 - DNS Recursive Name Service IPv6 Address List
Set-DhcpServerv6OptionValue -Prefix 2603:300b:802:8900:: -OptionId 23 -Value 2603:300b:802:8900::103, 2603:300b:802:8900::104
```

```PowerShell
cls
# Configure DHCP failover in load balanced mode

$secureString = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted for the secure string, type the shared secret for DHCP failover.

```PowerShell
$sharedSecret = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString))

Add-DhcpServerv4Failover `
    -PartnerServer TT-MGMT02.corp.technologytoolbox.com `
    -Name TT-MGMT01-TT-MGMT02 `
    -ScopeID 192.168.10.0 `
    -LoadBalancePercent 50 `
    -SharedSecret $sharedSecret


Confirm:
```

The shared secret is not encrypted across process boundaries. You should use this parameter only if the machine is\
trusted. Do you want to perform this action?

**Configure DHCP failover in load balance mode**\
From <[https://technet.microsoft.com/en-us/library/dn338975(v=ws.11).aspx](https://technet.microsoft.com/en-us/library/dn338975(v=ws.11).aspx)>

```PowerShell
cls
```

### # Authorize DHCP server in Active Directory

```PowerShell
Add-DhcpServerInDC -DnsName TT-MGMT01 -IPAddress 192.168.10.101
```

```PowerShell
cls
```

### # Activate IPv4 scope

```PowerShell
Set-DhcpServerv4Scope -ScopeId 192.168.10.0 -State Active
```

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

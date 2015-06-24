# STORM - Windows Server 2012 R2 Standard

Saturday, January 04, 2014
2:52 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Install Windows Server 2012 R2

## Set time zone

```Console
sconfig
```

## Rename the server and join domain

```Console
sconfig
```

## # Download PowerShell help files

```PowerShell
Update-Help
```

## Change drive letter for DVD-ROM

### To change the drive letter for the DVD-ROM using PowerShell

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
```

### Reference

**Change CD ROM Drive Letter in Newly Built VM's to Z:\\ Drive**\
Pasted from <[http://www.vinithmenon.com/2012/10/change-cd-rom-drive-letter-in-newly.html](http://www.vinithmenon.com/2012/10/change-cd-rom-drive-letter-in-newly.html)>

## Rename network connections

```PowerShell
Get-NetAdapter -Physical

Get-NetAdapter `
    -InterfaceDescription "Intel(R) 82574L Gigabit Network Connection" |
        Rename-NetAdapter -NewName "LAN 1 - 192.168.10.x"

Get-NetAdapter -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter" |
    Rename-NetAdapter -NewName "iSCSI 1 - 10.1.10.x"

Get-NetAdapter `
    -InterfaceDescription "Intel(R) 82579LM Gigabit Network Connection" |
        Rename-NetAdapter -NewName "LAN 2 - 192.168.10.x"
```

## Configure static IPv4 address

```PowerShell
$ipAddress = "192.168.10.124"

New-NetIPAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -IPAddress $ipAddress `
    -PrefixLength 24 `
    -DefaultGateway 192.168.10.1

Set-DNSClientServerAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -ServerAddresses 192.168.10.103,192.168.10.104
```

## Configure static IPv6 address

```PowerShell
$ipAddress = "2601:1:8200:6000::124"

New-NetIPAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -IPAddress $ipAddress `
    -PrefixLength 64

Set-DNSClientServerAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -ServerAddresses 2601:1:8200:6000::103,2601:1:8200:6000::104
```

## Configure iSCSI network adapter

```PowerShell
$ipAddress = "10.1.10.124"

New-NetIPAddress `
    -InterfaceAlias "iSCSI 1 - 10.1.10.x" `
    -IPAddress $ipAddress `
    -PrefixLength 24

Disable-NetAdapterBinding `
    -Name "iSCSI 1 - 10.1.10.x" `
    -DisplayName "Client for Microsoft Networks"

Disable-NetAdapterBinding `
    -Name "iSCSI 1 - 10.1.10.x" `
    -DisplayName "File and Printer Sharing for Microsoft Networks"

Disable-NetAdapterBinding `
    -Name "iSCSI 1 - 10.1.10.x" `
    -DisplayName "Link-Layer Topology Discovery Mapper I/O Driver"

Disable-NetAdapterBinding `
    -Name "iSCSI 1 - 10.1.10.x" `
    -DisplayName "Link-Layer Topology Discovery Responder"

$adapter = Get-WmiObject `
    -Class "Win32_NetworkAdapter" `
    -Filter "NetConnectionId = 'iSCSI 1 - 10.1.10.x'"

$adapterConfig = Get-WmiObject `
    -Class "Win32_NetworkAdapterConfiguration" `
    -Filter "Index= '$($adapter.DeviceID)'"

# Do not register this connection in DNS
$adapterConfig.SetDynamicDNSRegistration($false)

# Disable NetBIOS over TCP/IP
$adapterConfig.SetTcpipNetbios(2)
```

## Configure VM network adapter

```PowerShell
Disable-NetAdapterBinding `
    -Name "LAN 2 - 192.168.10.x" `
    -DisplayName "Client for Microsoft Networks"

Disable-NetAdapterBinding `
    -Name "LAN 2 - 192.168.10.x" `
    -DisplayName "File and Printer Sharing for Microsoft Networks"

Disable-NetAdapterBinding `
    -Name "LAN 2 - 192.168.10.x" `
    -DisplayName "Link-Layer Topology Discovery Mapper I/O Driver"

Disable-NetAdapterBinding `
    -Name "LAN 2 - 192.168.10.x" `
    -DisplayName "Link-Layer Topology Discovery Responder"

$adapter = Get-WmiObject `
    -Class "Win32_NetworkAdapter" `
    -Filter "NetConnectionId = 'LAN 2 - 192.168.10.x'"

$adapterConfig = Get-WmiObject `
    -Class "Win32_NetworkAdapterConfiguration" `
    -Filter "Index= '$($adapter.DeviceID)'"

# Do not register this connection in DNS
$adapterConfig.SetDynamicDNSRegistration($false)

# Disable NetBIOS over TCP/IP
$adapterConfig.SetTcpipNetbios(2)
```

## Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name "LAN 1 - 192.168.10.x" `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

Set-NetAdapterAdvancedProperty `
    -Name "LAN 2 - 192.168.10.x" `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

Set-NetAdapterAdvancedProperty `
    -Name "iSCSI 1 - 10.1.10.x" `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping ICEMAN -f -l 8900
ping 10.1.10.106 -f -l 8900
```

## Enable Virtualization in BIOS

Intel Virtualization Technology: **Enabled**

## Add Hyper-V role

```PowerShell
Install-WindowsFeature `
    -Name Hyper-V `
    -IncludeManagementTools `
    -Restart
```

## Create virtual switches

```PowerShell
New-VMSwitch `
    -Name "Virtual LAN 2 - 192.168.10.x" `
    -NetAdapterName "LAN 2 - 192.168.10.x" `
    -AllowManagementOS $true

New-VMSwitch `
    -Name "Virtual iSCSI 1 - 10.1.10.x" `
    -NetAdapterName "iSCSI 1 - 10.1.10.x" `
    -AllowManagementOS $true
```

## Enable jumbo frames on virtual switches

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name "vEthernet (Virtual LAN 2 - 192.168.10.x)" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Set-NetAdapterAdvancedProperty `
    -Name "vEthernet (Virtual iSCSI 1 - 10.1.10.x)" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

ping ICEMAN -f -l 8900
ping 10.1.10.106 -f -l 8900
```

## Modify "guest" virtual switch to disallow management OS

```PowerShell
Get-VMSwitch "Virtual LAN 2 - 192.168.10.x" |
    Set-VMSwitch -AllowManagementOS $false
```

## Configure default folder to store VMs

```Console
mkdir C:\NotBackedUp\VMs
Set-VMHost -VirtualMachinePath C:\NotBackedUp\VMs
```

## Migrate VMs from BEAST to STORM

- foobar7
- POLARIS

## # Install SCOM agent

```PowerShell
$imagePath = '\\iceman\Products\Microsoft\System Center 2012 R2' `
    + '\en_system_center_2012_r2_operations_manager_x86_and_x64_dvd_2920299.iso'

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$msiPath = $imageDriveLetter + ':\agent\AMD64\MOMAgent.msi'

msiexec.exe /i $msiPath `
    MANAGEMENT_GROUP=HQ `
    MANAGEMENT_SERVER_DNS=JUBILEE `
    ACTIONS_USE_COMPUTER_ACCOUNT=1
```

## # Approve manual agent install in Operations Manager

## # Install DPM 2012 R2 agent

```PowerShell
$imagePath = "\\iceman\Products\Microsoft\System Center 2012 R2\" `
    + "mu_system_center_2012_r2_data_protection_manager_x86_and_x64_dvd_2945939.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$installer = $imageDriveLetter + ":\SCDPM\Agents\DPMAgentInstaller_x64.exe"

& $installer JUGGERNAUT.corp.technologytoolbox.com
```

Review the licensing agreement. If you accept the Microsoft Software License Terms, select **I accept the license terms and conditions**, and then click **OK**.

Confirm the agent installation completed successfully and the following firewall exceptions have been added:

- Exception for DPMRA.exe in all profiles
- Exception for Windows Management Instrumentation service
- Exception for RemoteAdmin service
- Exception for DCOM communication on port 135 (TCP and UDP) in all profiles

### Reference

**Installing Protection Agents Manually**\
Pasted from <[http://technet.microsoft.com/en-us/library/hh757789.aspx](http://technet.microsoft.com/en-us/library/hh757789.aspx)>

## Attach DPM agent

On the DPM server (JUGGERNAUT), open **DPM Management Shell**, and run the following commands:

```PowerShell
$productionServer = "STORM"

.\Attach-ProductionServer.ps1 `
    -DPMServerName JUGGERNAUT `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `-UserName jjameson-admin
```

## # Configure Live Migration (without Failover Clustering)

### # Configure the server for live migration

```PowerShell
Enable-VMMigration

Add-VMMigrationNetwork 192.168.10.124

Set-VMHost -VirtualMachineMigrationAuthenticationType Kerberos
```

### Reference

**Configure Live Migration and Migrating Virtual Machines without Failover Clustering**\
Pasted from <[http://technet.microsoft.com/en-us/library/jj134199.aspx](http://technet.microsoft.com/en-us/library/jj134199.aspx)>

## # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

## # Update static IPv6 address

```PowerShell
netsh int ipv6 delete address "LAN 1 - 192.168.10.x" 2601:1:8200:6000::124

netsh int ipv6 delete dns "LAN 1 - 192.168.10.x" 2601:1:8200:6000::103
netsh int ipv6 delete dns "LAN 1 - 192.168.10.x" 2601:1:8200:6000::104

netsh int ipv6 add address "LAN 1 - 192.168.10.x" 2601:282:4201:e500::124

netsh int ipv6 add dns "LAN 1 - 192.168.10.x" 2601:282:4201:e500::103
netsh int ipv6 add dns "LAN 1 - 192.168.10.x" 2601:282:4201:e500::104
```

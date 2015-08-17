# FORGE - Windows Server 2012 R2 Standard

Monday, October 20, 2014
4:33 PM

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

## # Change drive letter for DVD-ROM

### # To change the drive letter for the DVD-ROM using PowerShell

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

## # Rename network connections

```PowerShell
Get-NetAdapter -Physical

Get-NetAdapter -InterfaceDescription "Intel(R) Ethernet Connection I217-V" |
    Rename-NetAdapter -NewName "LAN 1 - 192.168.10.x"

Get-NetAdapter -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter" |
    Rename-NetAdapter -NewName "LAN 2 - 192.168.10.x"
```

## # Configure static IPv4 address

```PowerShell
$ipAddress = "192.168.10.105"

New-NetIPAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -IPAddress $ipAddress `
    -PrefixLength 24 `
    -DefaultGateway 192.168.10.1

Set-DNSClientServerAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -ServerAddresses 192.168.10.103,192.168.10.104
```

## # Configure static IPv6 address

```PowerShell
$ipAddress = "2601:1:8200:6000::105"

New-NetIPAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -IPAddress $ipAddress `
    -PrefixLength 64

Set-DNSClientServerAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -ServerAddresses 2601:1:8200:6000::103,2601:1:8200:6000::104
```

## # Configure VM network adapter

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

## # Enable jumbo frames

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

ping ICEMAN -f -l 8900
ping 10.1.10.106 -f -l 8900
```

## Enable Virtualization in BIOS

Intel Virtualization Technology: **Enabled**

## # Add Hyper-V role

```PowerShell
Install-WindowsFeature `
    -Name Hyper-V `
    -IncludeManagementTools `
    -Restart
```

## # Create virtual switches

```PowerShell
New-VMSwitch `
    -Name "Virtual LAN 2 - 192.168.10.x" `
    -NetAdapterName "LAN 2 - 192.168.10.x" `
    -AllowManagementOS $true
```

## # Enable jumbo frames on virtual switches

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name "vEthernet (Virtual LAN 2 - 192.168.10.x)" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

ping ICEMAN -f -l 8900
ping 10.1.10.106 -f -l 8900
```

## # Modify "guest" virtual switch to disallow management OS

```PowerShell
Get-VMSwitch "Virtual LAN 2 - 192.168.10.x" |
    Set-VMSwitch -AllowManagementOS $false
```

## # Configure default folder to store VMs

```PowerShell
mkdir C:\NotBackedUp\VMs
Set-VMHost -VirtualMachinePath C:\NotBackedUp\VMs
```

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
$productionServer = "FORGE"

.\Attach-ProductionServer.ps1 `
    -DPMServerName JUGGERNAUT `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `
    -UserName jjameson-admin
```

## Add computer to DPM Protection Group

![(screenshot)](https://assets.technologytoolbox.com/screenshots/55/AD5931EFE42E2CD38A5F621934B1F19D76EE1F55.png)

## # Configure Live Migration (without Failover Clustering)

### # Configure the server for live migration

```PowerShell
Enable-VMMigration

Add-VMMigrationNetwork 192.168.10.105

Set-VMHost -VirtualMachineMigrationAuthenticationType Kerberos
```

### # Add computer to "Hyper-V Servers" group

```PowerShell
Add-ADGroupMember "Hyper-V Servers" -Members "FORGE$"
```

### Reference

**Configure Live Migration and Migrating Virtual Machines without Failover Clustering**\
Pasted from <[http://technet.microsoft.com/en-us/library/jj134199.aspx](http://technet.microsoft.com/en-us/library/jj134199.aspx)>

## Restart the server

## Add server to Virtual Machine Manager

## # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

## # Update static IPv6 address

```PowerShell
netsh int ipv6 delete address "LAN 1 - 192.168.10.x" 2601:1:8200:6000::105

netsh int ipv6 delete dns "LAN 1 - 192.168.10.x" 2601:1:8200:6000::103
netsh int ipv6 delete dns "LAN 1 - 192.168.10.x" 2601:1:8200:6000::104

netsh int ipv6 add address "LAN 1 - 192.168.10.x" 2601:282:4201:e500::105

netsh int ipv6 add dns "LAN 1 - 192.168.10.x" 2601:282:4201:e500::103
netsh int ipv6 add dns "LAN 1 - 192.168.10.x" 2601:282:4201:e500::104
```

## # Configure firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

---

**FOOBAR8**

```PowerShell
$computer = 'FORGE'

$command = "New-NetFirewallRule ``
    -Name 'Remote Windows Update (Dynamic RPC)' ``
    -DisplayName 'Remote Windows Update (Dynamic RPC)' ``
    -Description 'Allows remote auditing and installation of Windows updates via POSHPAIG (http://poshpaig.codeplex.com/)' ``
    -Group 'Technology Toolbox (Custom)' ``
    -Program '%windir%\system32\dllhost.exe' ``
    -Direction Inbound ``
    -Protocol TCP ``
    -LocalPort RPC ``
    -Profile Domain ``
    -Action Allow"

$scriptBlock = [scriptblock]::Create($command)

Invoke-Command -ComputerName $computer -ScriptBlock $scriptBlock
```

---

# ROGUE - Windows Server 2012 R2 Standard

Monday, December 23, 2013
6:19 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Install Windows Server 2012 R2

## Set time zone

```Console
sconfig
```

## WinRM service SPN warnings

```Console
setspn -A WSMAN/ROGUE.corp.technologytoolbox.com ROGUE
setspn -A WSMAN/ROGUE ROGUE
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

## Enable Intel 82579V network adapter

After installing Windows Server 2012 R2 on the new hardware for ROGUE, the built-in Intel 82579V network adapter on the ASUS P8Z77-V motherboard was not recognized.

### To enable the Intel 82579V network adapter in Windows Server 2012

1. To be able to modify the drivers, temporarily disable driver integrity checks and enable test signing by running the following commands:
2. Restart the server.
3. Download the network drivers from the Intel website:\
   **Network Adapter Driver for Windows Server 2012 R2**\
   Pasted from <[https://downloadcenter.intel.com/Detail_Desc.aspx?agr=Y&DwnldID=23073&lang=eng&OSVersion=Windows%20Server%202012%20R2*&DownloadType=Drivers](https://downloadcenter.intel.com/Detail_Desc.aspx?agr=Y&DwnldID=23073&lang=eng&OSVersion=Windows%20Server%202012%20R2*&DownloadType=Drivers)>
4. Use WinZip to extract the contents of the download (**PROWin64.exe**) to a temporary folder (e.g. C:\\NotBackedUp\\Temp\\Drivers\\LAN).
5. Copy the driver files to a temporary location on the server:
6. Open the e1c63x64.inf file in Notepad:
7. In the **[ControlFlags]** section delete the following three lines:\
   ExcludeFromSelect = \\    PCI\\VEN_8086&DEV_1502,\\    PCI\\VEN_8086&DEV_1503
8. In the **[Intel.NTamd64.6.3.1]** section, select and copy the four **%E1503NC** lines.
9. Paste the four lines in the **[Intel.NTamd64.6.3]** section below the **%E1502NC** lines.
10. Save the file.
11. Install the network adapter driver:
12. Enable driver integrity checks and disable test signing by running the following commands:
13. Restart the server.

```Console
    bcdedit -set loadoptions DISABLE_INTEGRITY_CHECKSbcdedit -set TESTSIGNING ON
```

```Console
    robocopy C:\NotBackedUp\Temp\Drivers\LAN \\ROGUE\C$\NotBackedUp\Temp\Drivers\LAN /E
```

```Console
    Notepad.exe C:\NotBackedUp\Temp\Drivers\LAN\PRO1000\Winx64\NDIS64\e1c64x64.inf
```

```Console
    pnputil -i -a C:\NotBackedUp\Temp\Drivers\LAN\PRO1000\Winx64\NDIS64\e1c64x64.inf
```

When promped with **Windows can't verify the publisher of this driver software**, click **Install this driver software anyway**.

```Console
    bcdedit -set loadoptions ENABLE_INTEGRITY_CHECKSbcdedit -set TESTSIGNING OFF
```

### Reference

**Enable the Intel 82579V NIC in Windows Server 2012**\
[http://www.ivobeerens.nl/2012/08/08/enable-the-intel-82579v-nic-in-windows-server-2012/](http://www.ivobeerens.nl/2012/08/08/enable-the-intel-82579v-nic-in-windows-server-2012/)

## Rename network connections

```PowerShell
Get-NetAdapter -Physical

Get-NetAdapter `
    -InterfaceDescription "Intel(R) 82579V Gigabit Network Connection" |
        Rename-NetAdapter -NewName "LAN 1 - 192.168.10.x"

Get-NetAdapter -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter" |
    Rename-NetAdapter -NewName "iSCSI 1 - 10.1.10.x"

Get-NetAdapter -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter #2" |
    Rename-NetAdapter -NewName "LAN 2 - 192.168.10.x"
```

## Configure static IPv4 address

```PowerShell
$ipAddress = "192.168.10.102"

New-NetIPAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -IPAddress $ipAddress `
    -PrefixLength 24 `
    -DefaultGateway 192.168.10.1

Set-DNSClientServerAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -ServerAddresses 192.168.10.104,192.168.10.103
```

## Configure static IPv6 address

```PowerShell
$ipAddress = "2601:1:8200:6000::102"

New-NetIPAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -IPAddress $ipAddress `
    -PrefixLength 64

Set-DNSClientServerAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -ServerAddresses 2601:1:8200:6000::104,2601:1:8200:6000::103
```

## Configure iSCSI network adapter

```PowerShell
$ipAddress = "10.1.10.102"

New-NetIPAddress -InterfaceAlias "iSCSI 1 - 10.1.10.x" -IPAddress $ipAddress `
    -PrefixLength 24

Disable-NetAdapterBinding -Name "iSCSI 1 - 10.1.10.x" `
    -DisplayName "Client for Microsoft Networks"

Disable-NetAdapterBinding -Name "iSCSI 1 - 10.1.10.x" `
    -DisplayName "File and Printer Sharing for Microsoft Networks"

Disable-NetAdapterBinding -Name "iSCSI 1 - 10.1.10.x" `
    -DisplayName "Link-Layer Topology Discovery Mapper I/O Driver"

Disable-NetAdapterBinding -Name "iSCSI 1 - 10.1.10.x" `
    -DisplayName "Link-Layer Topology Discovery Responder"

$adapter = Get-WmiObject -Class "Win32_NetworkAdapter" `
    -Filter "NetConnectionId = 'iSCSI 1 - 10.1.10.x'"

$adapterConfig = Get-WmiObject -Class "Win32_NetworkAdapterConfiguration" `
    -Filter "Index= '$($adapter.DeviceID)'"

# Do not register this connection in DNS
$adapterConfig.SetDynamicDNSRegistration($false)

# Disable NetBIOS over TCP/IP
$adapterConfig.SetTcpipNetbios(2)
```

## Configure VM network adapter

```PowerShell
Disable-NetAdapterBinding -Name "LAN 2 - 192.168.10.x" `
    -DisplayName "Client for Microsoft Networks"

Disable-NetAdapterBinding -Name "LAN 2 - 192.168.10.x" `
    -DisplayName "File and Printer Sharing for Microsoft Networks"

Disable-NetAdapterBinding -Name "LAN 2 - 192.168.10.x" `
    -DisplayName "Link-Layer Topology Discovery Mapper I/O Driver"

Disable-NetAdapterBinding -Name "LAN 2 - 192.168.10.x" `
    -DisplayName "Link-Layer Topology Discovery Responder"

$adapter = Get-WmiObject -Class "Win32_NetworkAdapter" `
    -Filter "NetConnectionId = 'LAN 2 - 192.168.10.x'"

$adapterConfig = Get-WmiObject -Class "Win32_NetworkAdapterConfiguration" `
    -Filter "Index= '$($adapter.DeviceID)'"

# Do not register this connection in DNS
$adapterConfig.SetDynamicDNSRegistration($false)

# Disable NetBIOS over TCP/IP
$adapterConfig.SetTcpipNetbios(2)
```

## Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name "LAN 1 - 192.168.10.x" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Set-NetAdapterAdvancedProperty -Name "LAN 2 - 192.168.10.x" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Set-NetAdapterAdvancedProperty -Name "iSCSI 1 - 10.1.10.x" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

ping BEAST -f -l 8900
ping 10.1.10.106 -f -l 8900
```

Note: Trying to ping BEAST or the iSCSI network adapter on ICEMAN with a 9000 byte packet from ROGUE resulted in an error (suggesting that jumbo frames were not configured). Note that 9000 works from ICEMAN to BEAST. When I decreased the packet size to 8900, it worked on ROGUE. (It also worked with 8970 bytes.)

## Add Hyper-V role

```PowerShell
Install-WindowsFeature -Name Hyper-V -Restart
```

No PowerShell cmdlets available (e.g. Get-VM)

```PowerShell
Install-WindowsFeature `
    -Name Hyper-V `
    -IncludeManagementTools `
    -Restart
```

## Create virtual switches

```PowerShell
New-VMSwitch -Name "Virtual LAN 2 - 192.168.10.x" `
    -NetAdapterName "LAN 2 - 192.168.10.x" -AllowManagementOS $true

New-VMSwitch -Name "Virtual iSCSI 1 - 10.1.10.x" `
    -NetAdapterName "iSCSI 1 - 10.1.10.x" -AllowManagementOS $true
```

## Enable jumbo frames on virtual switches

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name "vEthernet (Virtual LAN 2 - 192.168.10.x)" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Set-NetAdapterAdvancedProperty -Name "vEthernet (Virtual iSCSI 1 - 10.1.10.x)" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

ping BEAST -f -l 8900
ping 10.1.10.106 -f -l 8900
```

## Download PowerShell help files

```PowerShell
Update-Help
```

## Configure default folder to store VMs

```Console
mkdir C:\NotBackedUp\VMs
Set-VMHost -VirtualMachinePath C:\NotBackedUp\VMs
```

## Migrate XAVIER1 from STORM to ROGUE

Shutdown XAVIER1

On STORM:

```PowerShell
Export-VM XAVIER1 -Path 'D:\Shares\VM Library\ROGUE'
```

On ROGUE:

```PowerShell
Import-VM `
    -Path "\\STORM\VM Library\ROGUE\XAVIER1\Virtual Machines\E228C7D2-F15F-450A-BFAE-4FE9CE1CE11F.XML" `
    -Copy `
    -VirtualMachinePath "C:\NotBackedUp\VMs\XAVIER1\Virtual Machines" `
    -VhdDestinationPath "C:\NotBackedUp\VMs\XAVIER1\Virtual Hard Disks" `
    -SnapshotFilePath "C:\NotBackedUp\VMs\XAVIER1\Snapshots"
```

Import-VM : Unable to import virtual machine due to configuration errors.  Please use Compare-VM to repair the virtual machine.\
At line:1 char:1\
+ Import-VM -Path "[\\\\STORM\\VM Library\\ROGUE\\XAVIER1\\Virtual Machines\\E228C7D2-F15F](\\STORM\VM Library\ROGUE\XAVIER1\Virtual Machines\E228C7D2-F15F) ...\
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\
    + CategoryInfo          : NotSpecified: (:) [Import-VM], VirtualizationOperationFailedException\
    + FullyQualifiedErrorId : Microsoft.HyperV.PowerShell.Commands.ImportVMCommand

```PowerShell
robocopy "\\STORM\VM Library\ROGUE\XAVIER1" C:\NotBackedUp\VMs\XAVIER1 /E /MIR

Import-VM `
    -Path 'C:\NotBackedUp\VMs\XAVIER1\Virtual Machines\E228C7D2-F15F-450A-BFAE-4FE9CE1CE11F.XML' -Register
```

Import-VM : Unable to import virtual machine due to configuration errors.  Please use Compare-VM to repair the virtual machine.\
At line:1 char:1\
+ Import-VM `\
+ ~~~~~~~~~~~\
    + CategoryInfo          : NotSpecified: (:) [Import-VM], VirtualizationOperationFailedException\
    + FullyQualifiedErrorId : Microsoft.HyperV.PowerShell.Commands.ImportVMCommand

```PowerShell
$report = Compare-VM `
    -Path 'C:\NotBackedUp\VMs\XAVIER1\Virtual Machines\E228C7D2-F15F-450A-BFAE-4FE9CE1CE11F.XML'

$report.Incompatibilities | Format-Table -AutoSize

Message                                                        MessageId Source
-------                                                        --------- ------
Could not find Ethernet switch 'Virtual LAN 1 - 192.168.10.x'.     33012 Microsoft.HyperV.PowerShell.VMNetworkAdapter

$report.Incompatibilities[0].Source | Disconnect-VMNetworkAdapter

Compare-VM -CompatibilityReport $report

Import-VM -CompatibilityReport $report
```

Modify settings on XAVIER1 to connect network adapter to **Virtual LAN 2 - 192.168.10.x** switch

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
$productionServer = "ROGUE"

.\Attach-ProductionServer.ps1 `
    -DPMServerName JUGGERNAUT `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `-UserName jjameson-admin
```

## # Configure Live Migration (without Failover Clustering)

### # Configure the server for live migration

```PowerShell
Enable-VMMigration

Add-VMMigrationNetwork 192.168.10.102

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
netsh int ipv6 delete address "LAN 1 - 192.168.10.x" 2601:1:8200:6000::102

netsh int ipv6 delete dns "LAN 1 - 192.168.10.x" 2601:1:8200:6000::103
netsh int ipv6 delete dns "LAN 1 - 192.168.10.x" 2601:1:8200:6000::104

netsh int ipv6 add address "LAN 1 - 192.168.10.x" 2601:282:4201:e500::102

netsh int ipv6 add dns "LAN 1 - 192.168.10.x" 2601:282:4201:e500::103
netsh int ipv6 add dns "LAN 1 - 192.168.10.x" 2601:282:4201:e500::104
```

## # Configure firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

---

**FOOBAR8**

```PowerShell
$computer = 'ROGUE'

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

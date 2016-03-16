# ANGEL (originally ICEMAN) - Windows Server 2012 R2 Standard

Sunday, December 29, 2013
2:11 PM

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

## Download PowerShell help files

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

Get-NetAdapter -InterfaceDescription "Realtek PCIe GBE Family Controller" |
    Rename-NetAdapter -NewName "LAN 1 - 192.168.10.x"

Get-NetAdapter -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter" |
    Rename-NetAdapter -NewName "iSCSI 1 - 10.1.10.x"

Get-NetAdapter -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter #2" |
    Rename-NetAdapter -NewName "LAN 2 - 192.168.10.x"
```

## # Configure static IPv4 address

```PowerShell
$ipAddress = "192.168.10.106"

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
$ipAddress = "2601:1:8200:6000::106"

New-NetIPAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -IPAddress $ipAddress `
    -PrefixLength 64

Set-DNSClientServerAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -ServerAddresses 2601:1:8200:6000::103, 2601:1:8200:6000::104
```

## Configure iSCSI network adapter

```PowerShell
$ipAddress = "10.1.10.106"

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
    -DisplayName "Jumbo Frame" `
    -RegistryValue 9216

Set-NetAdapterAdvancedProperty `
    -Name "LAN 2 - 192.168.10.x" `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

Set-NetAdapterAdvancedProperty `
    -Name "iSCSI 1 - 10.1.10.x" `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping XAVIER1-f -l 9000
```

## Enable Virtualization in BIOS

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

ping XAVIER1 -f -l 8900
ping 10.1.10.103 -f -l 8900
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

## Add DHCP feature

```PowerShell
Install-WindowsFeature DHCP -IncludeManagementTools

Set-DhcpServerv4OptionValue `
    -DNSServer 192.168.10.103,192.168.10.104 `
    -DNSDomain corp.technologytoolbox.com `
    -Router 192.168.10.1

Add-DhcpServerSecurityGroup

Add-DhcpServerv4Scope `
    -Name "Default Scope" `
    -StartRange 192.168.10.2 `
    -EndRange 192.168.10.100 `
    -SubnetMask 255.255.255.0

Add-DhcpServerInDC -DNSName corp.technologytoolbox.com

WARNING: ...Failed to initiate the authorization check on the DHCP server. Error: There are no more endpoints available from the endpoint mapper.  (1753).
```

**Workaround: Authorize the DHCP server from DHCP Manager on FOOBAR8.**

## Add File Server feature

```PowerShell
Add-WindowsFeature FS-FileServer
```

## Add iSCSI Target feature

```PowerShell
Add-WindowsFeature FS-iSCSITarget-Server
```

## Configure direct-attached storage

Error trying to initialize new disks (Seagate 3TB Constellation drives)

**Disk Management**\
_The operation cannot be completed because selected disk(s) are unallocated disk(s)._

```Console
diskpart
list disk
select disk 1
online disk
attribute disk clear readonly
clean
convert gpt
create partition primary
list partition
select partition 2
format fs=ntfs label="Data01" quick
assign letter=D
list disk
select disk 2
online disk
attribute disk clear readonly
clean
convert gpt
create partition primary
list partition
select partition 2
format fs=ntfs label="Data02" quick
assign letter=E
list disk
```

## Create iSCSI virtual disk (BEAST-Backup02.vhdx)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/94/8A46C109719A2E0D2A0DC3CC581BBB61D7775394.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/86/DF9A21AF2F94041BA811B57922AA9D05328EA786.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/31/FE1ED57D87939AB3F2735DCDFE67D0C8A9D33F31.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/27/05F7CADA34DA6BCA410BCBBA2891ACA117035127.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2F/16EB813537A5C688DA2522151F47C5AFFA1DF22F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7F/FB864BBD1CB47E15C1340F1D8D6FC5B3F44CB37F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/21/BE8408A36EA8B71A816D5CFD258B5AF991BA4721.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E4/71C1BB115AB0918208A53814B2B605F4495E87E4.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1C/49E27ECCBB2DE7BD18F6236C762901DB222B141C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/21/9CC80061FE07EECB787DAF2158BC44777FC05521.png)

## Create file shares

VM Library

## Set high performance power option

```Console
powercfg -list

Existing Power Schemes (* Active)
-----------------------------------
Power Scheme GUID: 381b4222-f694-41f0-9685-ff5bb260df2e  (Balanced) *
Power Scheme GUID: 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c  (High performance)
Power Scheme GUID: a1841308-3541-4fab-bc81-f71556f20b4a  (Power saver)

powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

powercfg -list

Existing Power Schemes (* Active)
-----------------------------------
Power Scheme GUID: 381b4222-f694-41f0-9685-ff5bb260df2e  (Balanced)
Power Scheme GUID: 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c  (High performance) *
Power Scheme GUID: a1841308-3541-4fab-bc81-f71556f20b4a  (Power saver)
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

## Approve manual agent install in Operations Manager

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
$productionServer = "ICEMAN"

.\Attach-ProductionServer.ps1 `
    -DPMServerName JUGGERNAUT `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `-UserName jjameson-admin
```

## Create share for TFS builds

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1B/4464774519D35962D43997A35B52BB85E98B261B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7B/4587A4E307CCF80FFE9C976C05D9E52D6485497B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0D/7155D1840B9D0F87FBDDC4428CFB6D50DC7BDC0D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E7/649C4976EEED95889D960BC29944B7C564D3F2E7.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/95/95D420FD63DF58EEA603E619C76AB32623F2B095.png)

Clear the **Allow caching of share** checkbox and click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FC/6008874110A054831AF216122A9EADB52C8B96FC.png)

Click **Customize permissions...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BC/4301102AC1E21CAE8A8678C1FE59A43CC7F682BC.png)

Click **Disable inheritance**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/28/45F9E2F5240D55B6E1C43890D3D3879450AEF128.png)

Remove permissions for **Users (ICEMAN\\Users)**.

Click **Add**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BB/27DAB15DD5E3190D7D50C9A5557CF36080C597BB.png)

In the **Basic permissions** section, select **Modify**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F3/EEAEAD5DA3B024AED6C4155D862D07DEDD54CAF3.png)

Click **Add**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E1/DEB2D7865E20996988F635AB6606A5164AB572E1.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A7/DEF8A4D88C885877B4266FC9287C2023F7B2A2A7.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D8/36DA02F912474DECE4197C41A58F173A0D9889D8.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C0/9D236A1D3A75E57252E57D793989B3248F4B1EC0.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DD/5C7267CDFA76264DF1A16855B165E2B60C8010DD.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/14/50E4F221A1A4A30336E03EE7800DADCB75B79714.png)

## Create share for WSUS content

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DD/B3769D6754084CAA44B0838B97B8F13EFEDA00DD.png)

On the **TASKS** menu, click **New Share...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/45/3ACAD3842C10466C1BE55E3F91503C0EE5BEBD45.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C3/C588A3BD1073180E3A10EE09640237CF4293C8C3.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B3/0072FC73C55540231BDDF1C816C829AFEA614FB3.png)

Clear the **Allow caching of share** checkbox.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3A/9D0F8F4E9ED6C0F4C4669DB2C1D92E23622BC93A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/18/30DA1CDBE2A4305C3D7DACF97552416C977D1818.png)

Click **Customize permissions...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/35/AA2900786DB12CEA7FD505C2D640895127FB7D35.png)

Click **Disable inheritance**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7D/A7D2C9BCA83AF82B0DBA90746E9AD85103FE287D.png)

Remove permissions for **Users (ICEMAN\\Users)**.

Click **Add**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/62/7A9D9243611C69A419121D041D70B9BAD3949362.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DA/5B05E519CE33E4BF0D55B02870794A34BB4808DA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/38/9FEB87B8840CBAFCC550AD034BEACC8501800638.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C0/633A816366CE28B340EB26C5EF44E7B51EB041C0.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/55/2F595B04E3AA4499605CD6EFA312676ECF781455.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9D/A6B78DC2A2A554469DC4D7411D186EDD9E1D0E9D.png)

## Create iSCSI virtual disk (EXT-SQL01-Quorum.vhdx)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FD/35948179ECB3BC7FA22D690DBEE24A4EC5DBFAFD.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B0/569F1BBCD4525007DCFE1B658079BAAC8F6F64B0.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EE/C851E3B79CE9BD2103AEB00A74665E48119402EE.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E2/5257A96C70A0FEDB7A41E439FCD454CB035A72E2.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/05/3149502FDFD305B6F0FBDC6D671464251AC9B205.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/74/5724AD4D0DBD4C7197F6F61AFA56B9E840A05E74.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F9/551ED6B2353BA8DA0BB0EA94E461B00FC07A63F9.png)

Click **Add...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FA/462F4CE59A3F577D05E87973414024443881ACFA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2B/6B997E115288522B40325FA7F41ACA9281A74E2B.png)

On the **Enable Authentication **page, ensure **Enable CHAP** is not selected.

> **Important**
>
> Due to a bug in the Microsoft iSCSI initiator, CHAP must be configured after discovering the iSCSI target.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B3/E73DD3A84FE81C611D39C4621D403CABEDBB48B3.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/07/FC90D66DA8630DC746910515A397FFCCA1D20307.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EC/D5B7854904A97CBEC76E0BD052AEBDF4BA0753EC.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8C/641FDE4D85DBF0B73FAE77A4CB2D51E674B2D28C.png)

## Add iSCSI initiator to existing iSCSI target - ICEMAN

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4D/84036776E5E28F8C0E911894BBCCB78A3485F84D.png)

In the **iSCSI TARGETS** section, right-click the iSCSI target (**ext-sql01**) and click **Properties**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/33/A23A31EAC597BA540338286123DCB7FB44FA6733.png)

Click **Add...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DE/61CD557B0C71DA6BD9C8425295B692E4C3E3DCDE.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9F/564CD45E460A42B1445CBACACED58CAE0B90279F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4E/8198DD4D0107CEEB4EC1AE6D37985E3D92785B4E.png)

## Create iSCSI virtual disk (EXT-SQL01-Data01.vhdx)

On the **iSCSI** panel, on the **TASKS** menu, click **New iSCSI Virtual Disk...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2E/7816AA9A43A682CFAB89C8298E2748F78F22F22E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E3/56F5C341CA6227D8BF6B4AF828F087C249E1A1E3.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/52/1490ADFA4B56E382778E037D3228C52F0F417352.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8F/327EA6F2280FC6F210DFF25E84EF4B23BFD3EC8F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DE/185895CD3742913C6901048526EFA1CC96F859DE.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/80/1BCBCAC3A5D9BBECD84F55F5E8267684E12DEA80.png)

Wait for the virtual disk to be initialized.

## Create iSCSI virtual disk (EXT-SQL01-Log01.vhdx)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FD/910B7039054BD6C412B494A459F12DA103AA58FD.png)

Wait for the virtual disk to be initialized.

## Create iSCSI virtual disk (EXT-SQL01-Temp01.vhdx)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E9/AD8CF411CC00C29C82676C008182615365ECA3E9.png)

## Create iSCSI virtual disk (EXT-SQL01-Backup01.vhdx)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/31/E6273391EB1F2E4912B48D96BDA34C02E4D43431.png)

## # Configure Live Migration (without Failover Clustering)

### # Configure the server for live migration

```PowerShell
Enable-VMMigration

Add-VMMigrationNetwork 192.168.10.106

Set-VMHost -VirtualMachineMigrationAuthenticationType Kerberos
```

### Reference

**Configure Live Migration and Migrating Virtual Machines without Failover Clustering**\
Pasted from <[http://technet.microsoft.com/en-us/library/jj134199.aspx](http://technet.microsoft.com/en-us/library/jj134199.aspx)>

## # Download and save PowerShell help files (WIN8-TEST1)

```PowerShell
mkdir \\iceman\Public\Download\Microsoft\PowerShell\Help

Save-Help -DestinationPath \\iceman\Public\Download\Microsoft\PowerShell\Help
```

## # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

## # Update static IPv6 address

```PowerShell
netsh int ipv6 delete address "LAN 1 - 192.168.10.x" 2601:1:8200:6000::106

netsh int ipv6 delete dns "LAN 1 - 192.168.10.x" 2601:1:8200:6000::103
netsh int ipv6 delete dns "LAN 1 - 192.168.10.x" 2601:1:8200:6000::104

netsh int ipv6 add address "LAN 1 - 192.168.10.x" 2601:282:4201:e500::106

netsh int ipv6 add dns "LAN 1 - 192.168.10.x" 2601:282:4201:e500::103
netsh int ipv6 add dns "LAN 1 - 192.168.10.x" 2601:282:4201:e500::104
```

## # Configure firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

---

**FOOBAR8**

```PowerShell
$computer = 'ICEMAN'

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

$scriptBlock = [ScriptBlock]::Create($command)

Invoke-Command -ComputerName $computer -ScriptBlock $scriptBlock
```

---

## # Create file share (\\\\ICEMAN\\Archive)

```PowerShell
New-Item -ItemType Directory -Path D:\Shares\Archive

New-SmbShare `
  -Name Archive `
  -Path D:\Shares\Archive `
  -CachingMode None `
  -ChangeAccess Everyone
```

```PowerShell
cls
```

## # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter `
    -InterfaceDescription "Realtek PCIe GBE Family Controller" |
    Rename-NetAdapter -NewName "Management"

Get-NetAdapter `
    -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter" |
    Rename-NetAdapter -NewName "Storage"

Get-NetAdapter -InterfaceDescription "Intel(R) Gigabit CT Desktop Adapter #2" |
    Rename-NetAdapter -NewName "Production"
```

```PowerShell
cls
```

## # Enable SMB Multichannel

### # Modify "Production" virtual switch to allow management OS

```PowerShell
Get-VMSwitch "Production" |
    Set-VMSwitch -AllowManagementOS $true
```

```PowerShell
cls
```

## # Change IP addresses and rename server (before renaming TEMP to ICEMAN)

### # Change static IPv4 addresses for "Management" and "Storage" network adapters

```PowerShell
sconfig
```

> **Note**
>
> New "Management" IP address: **192.168.10.199**\
> New "Storage" IP address: **10.1.10.199**

### # Change static IPv6 address for "Management" network adapter

```PowerShell
$oldIpAddress = "2601:282:4201:e500::106"
$newIpAddress = "2601:282:4201:e500::199"
$ifIndex = Get-NetAdapter -InterfaceAlias "Management" |
    Select -ExpandProperty InterfaceIndex

New-NetIPAddress `
    -InterfaceIndex $ifIndex `
    -IPAddress $newIpAddress

Remove-NetIPAddress `
    -InterfaceIndex $ifIndex `
    -IPAddress $oldIpAddress
```

```PowerShell
cls
```

### # Rename server

```PowerShell
sconfig
```

> **Note**
>
> New server name: **ICEMAN-OLD**

```PowerShell
Restart-Server
```

## # Change IP addresses and rename server (after renaming TEMP to ICEMAN)

### # Change static IPv4 addresses for "Management" and "Storage" network adapters

```PowerShell
sconfig
```

> **Note**
>
> New "Management" IP address: **192.168.10.107**\
> New "Storage" IP address: **10.1.10.107**

```PowerShell
cls
```

### # Change static IPv6 address for "Management" network adapter

```PowerShell
$oldIpAddress = "2601:282:4201:e500::199"
$newIpAddress = "2601:282:4201:e500::107"
$ifIndex = Get-NetAdapter -InterfaceAlias "Management" |
    Select -ExpandProperty InterfaceIndex

New-NetIPAddress `
    -InterfaceIndex $ifIndex `
    -IPAddress $newIpAddress

Remove-NetIPAddress `
    -InterfaceIndex $ifIndex `
    -IPAddress $oldIpAddress
```

```PowerShell
cls
```

### # Rename server

```PowerShell
sconfig
```

> **Note**
>
> New server name: **ANGEL**

```PowerShell
Restart-Server
```

## # Remove iSCSI Target feature

```PowerShell
Uninstall-WindowsFeature FS-iSCSITarget-Server -IncludeManagementTools
```

## # Remove DHCP feature

```PowerShell
Uninstall-WindowsFeature DHCP -IncludeManagementTools -Restart
```

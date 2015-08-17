# EXT-SQL01B - Windows Server 2008 R2 Enterprise

Friday, January 31, 2014
9:01 AM

```Console
12345678901234567890123456789012345678901234567890123456789012345678901234567890

PowerShell
```

## # Create virtual machine

```PowerShell
$vmName = "EXT-SQL01B"

New-VM `
    -Name $vmName `
    -Path C:\NotBackedUp\VMs `
    -MemoryStartupBytes 4GB `
    -SwitchName "Virtual LAN 2 - 192.168.10.x"

Set-VMProcessor -VMName $vmName -Count 4

$sysPrepedImage = "\\ICEMAN\VHD Library\WS2008-R2-ENT.vhdx"

mkdir "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks"

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

Copy-Item $sysPrepedImage $vhdPath

Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath

Start-VM $vmName
```

## # Rename the server and join domain

```PowerShell
# Note: Rename-Computer is not available on Windows Server 2008 R2
netdom renamecomputer $env:COMPUTERNAME /newname:EXT-SQL01B /reboot

# Note: "-Restart" parameter is not available on Windows Server 2008 R2
# Note: "-Credential" parameter must be specified to avoid error
Add-Computer `
    -DomainName extranet.technologytoolbox.com `-Credential EXTRANET\jjameson-admin

Restart-Computer
```

## # Change drive letter for DVD-ROM

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
```

## # Reset WSUS configuration

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\WSUS\Reset WSUS for SysPrep Image.cmd'
```

## Add network adapter (Virtual iSCSI 1 - 10.1.10.x)

## # Rename network connections

```PowerShell
# Note: Get-NetAdapter is not available on Windows Server 2008 R2
netsh interface show interface

netsh interface set interface name="Local Area Connection" newname="LAN 1 - 192.168.10.x"

netsh interface set interface name="Local Area Connection 2" newname="iSCSI 1 - 10.1.10.x"
```

## # Configure static IP address

```PowerShell
$ipAddress = "192.168.10.203"

# Note: New-NetIPAddress is not available on Windows Server 2008 R2

netsh interface ipv4 set address name="LAN 1 - 192.168.10.x" source=static address=$ipAddress mask=255.255.255.0 gateway=192.168.10.1

# Note: Set-DNSClientServerAddress is not available on Windows Server 2008 R2

netsh interface ipv4 set dnsserver name="LAN 1 - 192.168.10.x" source=static address=192.168.10.209

netsh interface ipv4 add dnsserver name="LAN 1 - 192.168.10.x" address=192.168.10.210
```

## # Configure iSCSI network adapter

```PowerShell
$ipAddress = "10.1.10.203"

# Note: New-NetIPAddress is not available on Windows Server 2008 R2

netsh interface ipv4 set address name = "iSCSI 1 - 10.1.10.x" source=static address=$ipAddress mask=255.255.255.0

# Note: Disable-NetAdapterBinding is not available on Windows Server 2008 R2

# Disable "Client for Microsoft Networks"
C:\NotBackedUp\Public\Toolbox\nvspbind\x64\nvspbind.exe -d "iSCSI 1 - 10.1.10.x" ms_msclient

# Disable "File and Printer Sharing for Microsoft Networks"
C:\NotBackedUp\Public\Toolbox\nvspbind\x64\nvspbind.exe -d "iSCSI 1 - 10.1.10.x" ms_server

# Disable "Link-Layer Topology Discovery Mapper I/O Driver"
C:\NotBackedUp\Public\Toolbox\nvspbind\x64\nvspbind.exe -d "iSCSI 1 - 10.1.10.x" ms_lltdio

# Disable "Link-Layer Topology Discovery Responder"
C:\NotBackedUp\Public\Toolbox\nvspbind\x64\nvspbind.exe -d "iSCSI 1 - 10.1.10.x" ms_rspndr

$adapter = Get-WmiObject -Class "Win32_NetworkAdapter" `
    -Filter "NetConnectionId = 'iSCSI 1 - 10.1.10.x'"

$adapterConfig = Get-WmiObject -Class "Win32_NetworkAdapterConfiguration" `
    -Filter "Index= '$($adapter.DeviceID)'"

# Do not register this connection in DNS
$adapterConfig.SetDynamicDNSRegistration($false)

# Disable NetBIOS over TCP/IP
$adapterConfig.SetTcpipNetbios(2)
```

## # Enable jumbo frames

```PowerShell
# Note: Get-NetAdapterAdvancedProperty is not available on Windows Server 2008 R2

netsh interface ipv4 show interface

Idx     Met         MTU          State                Name
---  ----------  ----------  ------------  ---------------------------
  1          50  4294967295  connected     Loopback Pseudo-Interface 1
 11           5        1500  connected     LAN 1 - 192.168.10.x
 18           5        1500  connected     iSCSI 1 - 10.1.10.x


netsh interface ipv4 set subinterface "LAN 1 - 192.168.10.x" mtu=9014 store=persistent

netsh interface ipv4 set subinterface "iSCSI 1 - 10.1.10.x" mtu=9014 store=persistent
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C0/DE4A8BB73A26DFE80036F03F4C7DABC72A37BBC0.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AC/359C0F95AA7D36CDE70BDC5DD886BD1EE3ADB2AC.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F6/9E68B6EBF97963F60D76C8E4980983801510FEF6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7A/FE8CEE531A1335FD9A2FB2CC259BDBFCC42C687A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CE/AE20D522971A50AF377C36A3584DBB9B28BC42CE.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C5/A13511971496E3BFE5274A0A30715A4DF1D8DFC5.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/32/FC81C1D498BB7CEA8FAFD470A203A291B45DA132.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DB/AF8913DC9C0420A9AF7CBA3AC1DD8863096B8ADB.png)

```Console
ping ICEMAN -f -l 8900
ping 10.1.10.106 -f -l 8900
```

## Configure network binding order

In the **Network Connections** window, press F10 to view the menu.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A9/1D564C0C36FAD89CB2968F7D66FB11629AB57FA9.png)

On the **Advanced** menu, click **Advanced Settings...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0D/E5027155CEEC2E17E4C82CD44D5F1027AE1B520D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/00/02EFAC1CA528D1624046A17ADF9E73611DE58300.png)

## Enable iSCSI Initiator

Start -> iSCSI Initiator

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DF/3F6DE64EBF1E201BDD47D798802EEBB2C9A72CDF.png)

Click Yes.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5B/38F75FA3835C75B20A80D63314FE3463D9B3095B.png)

On the **Discovery** tab, click **Discover Portal...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/84/997A95199AEF4EA39C096740C00C6E13D59C4884.png)

In the **Discover Target Portal** window:

1. In the **IP address or DNS name** box, type **10.1.10.106**.
2. Ensure **Port** is set to the default (**3260**).
3. Click **OK**.

## Add iSCSI initiator to existing iSCSI target - ICEMAN

## Discover iSCSI target

On the **Targets** tab, in the **Discovered targets** section, click **Refresh**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2D/7223A178CAADEDCA2A2B38149467775F97BFFC2D.png)

Click **Connect**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0F/F822B682F3FA259F81BCBC2D1F2CA28BB42C840F.png)

In the Connect To Target window:

1. Ensure **Add this connection to the list of Favorite Targets** is selected.
2. Click **OK**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AF/2AE588CD3B9A672DC74995AB45446DD528C75EAF.png)

On the **Volumes and Devices** tab, click **Auto Configure**.

## Confirm the iSCSI disks appear offline

![(screenshot)](https://assets.technologytoolbox.com/screenshots/16/76835E27A9DE92EA475DD3B894973EAFA64A0F16.png)

## Install Failover Clustering feature

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BB/1A03746120FCA9D70FF9B0086946EBA2D22ADFBB.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/69/BA9E71E2A3841BD0E56D47A1E27CD74CF4858969.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A2/A3796F4D78CA6FE2E3A30845DDE0541546AEABA2.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E4/DDC573BC740127AC6A82BBB21D6A7580D3A547E4.png)

## Install .NET Framework 3.5

**Note:** SQL Server 2008 R2 Setup requires Microsoft .NET Framework 3.5 SP1 to be installed.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5E/392A74F1E8F7FBAF8878636FA76058D9C2633B5E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/91/59074FC1C70A065F1DD17C47DB81DD531FA17D91.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/24/82BC5B510F0B9674E890DE59A21285C71F661424.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C4/051689FF752F56810DE36FB3885D8D946F1495C4.png)

## Add node to SQL Server failover cluster

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A1/E768E1A1AF8244A2AD175B3ECE385CE1B673F3A1.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/38/3A4841EFCCB0A52384424C3CA17A7FB65E793538.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/59/F40D442C8F42759CD42EBA64C63B0BBB1D957A59.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AD/568DE4ACC70DD8930E9FE9147B7B1822295FEEAD.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EA/BC46DFC6DB9E448D59E2797E49344782D48629EA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/99/99282EC453EC3A4FA77746FC24C50D778C92E799.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A6/1A6E475424F9648C941D91E89FB0304D53A90CA6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6A/51DD07BE7BC72545A180AB4C478F03AEA613E26A.png)

```Console
C:\NotBackedUp\Public\Toolbox\nvspbind\x64\nvspbind.exe /o ms_tcpip

...
Protocols:

{D7DBFF6D-F51F-4C94-BF35-9CFEBEBA7578}
"ms_tcpip"
"Internet Protocol Version 4 (TCP/IPv4)":
   enabled:   Local Area Connection* 9
   enabled:   LAN 1 - 192.168.10.x
   enabled:   iSCSI 1 - 10.1.10.x

cleaning up...finished (0)

C:\NotBackedUp\Public\Toolbox\nvspbind\x64\nvspbind.exe /++ "LAN 1 - 192.168.10.x" ms_tcpip
...
acquiring write lock...success


Protocols:

{D7DBFF6D-F51F-4C94-BF35-9CFEBEBA7578}
"ms_tcpip"
"Internet Protocol Version 4 (TCP/IPv4)":
   enabled:   Local Area Connection* 9
   enabled:   LAN 1 - 192.168.10.x
   enabled:   iSCSI 1 - 10.1.10.x

moving 'LAN 1 - 192.168.10.x' to the top

   enabled:   LAN 1 - 192.168.10.x
   enabled:   Local Area Connection* 9
   enabled:   iSCSI 1 - 10.1.10.x

'LAN 1 - 192.168.10.x' found

cleaning up...releasing write lock...success
finished (0)
```

Click **Re-run**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1E/2F67AA29F3A9C33695D705F26E807CF9BDD8851E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E8/D666103CC55D6810EFD349F727C8B02AF75D16E8.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4A/8AFC7EE8FFC962DEB3B621CBC2F56DC9C42A604A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BB/D2F42A5EB09582E2FF1D0AE8F0609F7C6B6AB5BB.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0E/917F2CC4307468C57D42F9F8FABD38D3CDC38F0E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4E/141B72144E29F2C8A98D58E96E8B4B54FC48734E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A5/1BC8A4A8DF5AF8159B0F3AA0E65A740B6717ADA5.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D6/40B7743F2E4104AAEE7ADA4C11B475E584943CD6.png)

## Install SQL Server 2008 R2 Service Pack 2

## # Configure firewall rule for SQL Server

```PowerShell
# Note: New-NetFirewallRule is not available on Windows Server 2008 R2

netsh advfirewall firewall add rule `
    name="SQL Server Database Engine" `
    dir=in `
    action=allow `
    protocol=TCP `
    localport=1433
```

## # Change PowerShell execution policy

```PowerShell
Set-ExecutionPolicy RemoteSigned -Force
```

## Create scheduled task to delete old database backups

## Configure DCOM permissions for SSIS

The application-specific permission settings do not grant Local Launch permission for the COM Server application with CLSID\
{46063B1E-BE4A-4014-8755-5B377CD462FC}\
 and APPID\
{FAAFC69C-F4ED-4CCA-8849-7B882279EDBE}\
 to the user EXTRANET\\svc-sql-agent SID (S-1-5-21-224930944-1780242101-1199596236-1107) from address LocalHost (Using LRPC). This security permission can be modified using the Component Services administrative tool.

Using the steps in **[KB 2000474](KB 2000474) Workaround 1**, add **Local Launch** permissions on **MsDtsServer100** to **EXTRANET\\svc-sql-agent**.

## # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

## # Configure firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
# Note: New-NetFirewallRule is not available on Windows Server 2008 R2

netsh advfirewall firewall add rule `
    name="Remote Windows Update (Dynamic RPC)" `
    description="Allows remote auditing and installation of Windows updates via POSHPAIG (http://poshpaig.codeplex.com/)" `
    program="%windir%\system32\dllhost.exe" `
    dir=in `
    protocol=TCP `
    localport=RPC `
    profile=Domain `
    action=Allow
```

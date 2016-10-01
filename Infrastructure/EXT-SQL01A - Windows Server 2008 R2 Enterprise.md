# EXT-SQL01A - Windows Server 2008 R2 Enterprise

Sunday, April 17, 2016
5:27 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

### # Create virtual machine

```PowerShell
$vmHost = "STORM"
$vmName = "EXT-SQL01A"

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path E:\NotBackedUp\VMs `
    -MemoryStartupBytes 4GB `
    -SwitchName "Production"

Set-VM `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ProcessorCount 4

$sysPrepedImage = "\\ICEMAN\VM-Library\VHDs\WS2008-R2-ENT.vhdx"

mkdir "\\$vmHost\E$\NotBackedUp\VMs\$vmName\Virtual Hard Disks"

Copy-Item $sysPrepedImage $vhdPath.Replace('E:', "\\$vmHost\E`$")

Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path $vhdPath

# Add network adapter for iSCSI (Storage)

Add-VMNetworkAdapter `
    -ComputerName $vmHost `
    -VMName $vmName `
    -SwitchName "Storage"

Start-VM -ComputerName $vmHost -Name $vmName
```

---

```PowerShell
cls
```

## # Rename local Administrator account

```PowerShell
$adminUser = [ADSI] 'WinNT://./Administrator,User'
$adminUser.Rename('foo')

logoff
```

## Login as EXT-SQL01A\\foo

## # Rename network connections

# **Note:** Get-NetAdapter is not available on Windows Server 2008 R2

```Console
netsh interface show interface

netsh interface set interface name="Local Area Connection" newname="Production"

netsh interface set interface name="Local Area Connection 2" newname="Storage"
```

```Console
cls
```

## # Configure "Production" network adapter

```PowerShell
$interfaceAlias = "Production"
```

### # Configure static IPv4 address

```PowerShell
$ipAddress = "192.168.10.211"
```

# **Note:** New-NetIPAddress is not available on Windows Server 2008 R2

```Console
netsh interface ipv4 set address name=$interfaceAlias source=static address=$ipAddress mask=255.255.255.0 gateway=192.168.10.1
```

# **Note:** Set-DNSClientServerAddress is not available on Windows Server 2008 R2

```Console
netsh interface ipv4 set dnsserver name=$interfaceAlias source=static address=192.168.10.209

netsh interface ipv4 add dnsserver name=$interfaceAlias address=192.168.10.210
```

### # Configure static IPv6 address

```PowerShell
$ipAddress = "2601:282:4201:e500::211"
```

# **Note:** New-NetIPAddress is not available on Windows Server 2008 R2

```Console
netsh interface ipv6 set address interface=$interfaceAlias address=$ipAddress store=persistent
```

# **Note:** Set-DNSClientServerAddress is not available on Windows Server 2008 R2

```Console
netsh interface ipv6 set dnsserver name=$interfaceAlias source=static address=2601:282:4201:e500::209

netsh interface ipv6 add dnsserver name=$interfaceAlias address=2601:282:4201:e500::210
```

```Console
cls
```

## # Configure "Storage" network adapter

```PowerShell
$interfaceAlias = "Storage"
```

### # Configure static IPv4 address

```PowerShell
$ipAddress = "10.1.10.211"
```

# **Note:** New-NetIPAddress is not available on Windows Server 2008 R2

```Console
netsh interface ipv4 set address name=$interfaceAlias source=static address=$ipAddress mask=255.255.255.0
```

### # Disable features on iSCSI network adapter

# **Note:** Disable-NetAdapterBinding is not available on Windows Server 2008 R2

```PowerShell
# Disable "Client for Microsoft Networks"
C:\NotBackedUp\Public\Toolbox\nvspbind\x64\nvspbind.exe -d $interfaceAlias ms_msclient

# Disable "File and Printer Sharing for Microsoft Networks"
C:\NotBackedUp\Public\Toolbox\nvspbind\x64\nvspbind.exe -d $interfaceAlias ms_server

# Disable "Link-Layer Topology Discovery Mapper I/O Driver"
C:\NotBackedUp\Public\Toolbox\nvspbind\x64\nvspbind.exe -d $interfaceAlias ms_lltdio

# Disable "Link-Layer Topology Discovery Responder"
C:\NotBackedUp\Public\Toolbox\nvspbind\x64\nvspbind.exe -d $interfaceAlias ms_rspndr

$adapter = Get-WmiObject -Class "Win32_NetworkAdapter" `
    -Filter "NetConnectionId = '$interfaceAlias'"

$adapterConfig = Get-WmiObject -Class "Win32_NetworkAdapterConfiguration" `
    -Filter "Index= '$($adapter.DeviceID)'"

# Do not register this connection in DNS
$adapterConfig.SetDynamicDNSRegistration($false)

# Disable NetBIOS over TCP/IP
$adapterConfig.SetTcpipNetbios(2)
```

## Enable jumbo frames

**Note:** Get-NetAdapterAdvancedProperty is not available on Windows Server 2008 R2

1. Open **Network and Sharing Center**.
2. In the **Network and Sharing Center **window, click **Production**.
3. In the **Production Status** window, click **Properties**.
4. In the **Production Properties** window, on the **Networking** tab, click **Configure**.
5. In the **Microsoft Virtual Machine Bus Network Adapter Properties** window:
   1. On the **Advanced **tab:
      1. In the **Property** list, select **Jumbo Packet**.
      2. In the **Value** dropdown, select **9014 Bytes**.
   2. Click **OK**.
6. Repeat the previous steps for the **Storage** network adapter.
7. Open Task Scheduler.
8. Click **Import Task...**
9. In the **Open** dialog:
   1. In the **File name** box, type **C:\\NotBackedUp\\Public\\Toolbox\\PowerShell\\Remove Old Database Backups.xml**.
   2. Click **Open**.
10. In the **Create Task **dialog, click **OK**.

```Console
netsh interface ipv4 show interface

Idx     Met         MTU          State                Name
---  ----------  ----------  ------------  ---------------------------
  1          50  4294967295  connected     Loopback Pseudo-Interface 1
 11           5        9000  connected     Production
 13           5        9000  connected     Storage

ping ICEMAN -f -l 8900
ping 10.1.10.106 -f -l 8900
```

```Console
cls
```

## # Rename computer

# **Note:** Rename-Computer is not available on Windows Server 2008 R2

```PowerShell
netdom renamecomputer $env:COMPUTERNAME /newname:EXT-SQL01A /reboot
```

> **Important**
>
> Wait for the computer to restart.

## # Join domain

# **Note:**\
# "-Restart" parameter is not available on Windows Server 2008 R2\
# "-Credential" parameter must be specified to avoid error

```PowerShell
Add-Computer `
    -DomainName extranet.technologytoolbox.com `
    -Credential EXTRANET\jjameson-admin
```

> **Note**
>
> When prompted, type the password for the domain account.

```PowerShell
Restart-Computer
```

## Move computer to "SQL Servers" OU

---

**EXT-DC01**

```PowerShell
$computerName = "EXT-SQL01A"
$targetPath = ("OU=SQL Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=extranet,DC=technologytoolbox,DC=com")

Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath
```

---

## Login as EXTRANET\\jjameson-admin

```PowerShell
cls
```

## # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
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

```PowerShell
cls
```

## # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

## # Configure firewall rules for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
netsh advfirewall firewall set rule `
    name="File and Printer Sharing (Echo Request - ICMPv4-In)" profile=any `
    new enable=yes

netsh advfirewall firewall set rule `
    name="File and Printer Sharing (Echo Request - ICMPv6-In)" profile=any `
    new enable=yes

netsh advfirewall firewall set rule `
    name="File and Printer Sharing (SMB-In)" profile=any new enable=yes

netsh advfirewall firewall add rule `
    name="Remote Windows Update (Dynamic RPC)" `
    description="Allows remote auditing and installation of Windows updates via POSHPAIG (http://poshpaig.codeplex.com/)" `
    program="%windir%\system32\dllhost.exe" `
    dir=in `
    protocol=TCP `
    localport=RPC `
    profile=domain `
    action=Allow
```

## # Disable firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
netsh advfirewall firewall set rule `
    name="Remote Windows Update (Dynamic RPC)" new enable=no
```

```PowerShell
cls
```

## # Configure network binding order

```PowerShell
C:\NotBackedUp\Public\Toolbox\nvspbind\x64\nvspbind.exe /o ms_tcpip
...
Protocols:

{D7DBFF6D-F51F-4C94-BF35-9CFEBEBA7578}
"ms_tcpip"
"Internet Protocol Version 4 (TCP/IPv4)":
   enabled:   Storage
   enabled:   Production

cleaning up...finished (0)

C:\NotBackedUp\Public\Toolbox\nvspbind\x64\nvspbind.exe /++ "Production" ms_tcpip
...
acquiring write lock...success


Protocols:

{D7DBFF6D-F51F-4C94-BF35-9CFEBEBA7578}
"ms_tcpip"
"Internet Protocol Version 4 (TCP/IPv4)":
   enabled:   Storage
   enabled:   Production

moving 'Production' to the top

   enabled:   Production
   enabled:   Storage

'Production' found

cleaning up...releasing write lock...success
finished (0)
```

## Enable iSCSI Initiator

**Start** -> **iSCSI Initiator**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DF/3F6DE64EBF1E201BDD47D798802EEBB2C9A72CDF.png)

Click **Yes**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5B/38F75FA3835C75B20A80D63314FE3463D9B3095B.png)

On the **Discovery** tab, click **Discover Portal...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/84/997A95199AEF4EA39C096740C00C6E13D59C4884.png)

In the **Discover Target Portal** window:

1. In the **IP address or DNS name** box, type **10.1.10.106**.
2. Ensure **Port** is set to the default (**3260**).
3. Click **OK**.

## Create iSCSI virtual disks

| **Server** | **Name**           | **Volume** | **Path**                                       | **Size** | **Type**              |
| ---------- | ------------------ | ---------- | ---------------------------------------------- | -------- | --------------------- |
| ICEMAN     | EXT-SQL01-Quorum   | E:         | E:\\iSCSIVirtualDisks\\EXT-SQL01-Quorum.vhdx   | 512 MB   | Dynamically expanding |
| ICEMAN     | EXT-SQL01-Data01   | E:         | E:\\iSCSIVirtualDisks\\EXT-SQL01-Data01.vhdx   | 150 GB   | Fixed size            |
| ICEMAN     | EXT-SQL01-Log01    | E:         | E:\\iSCSIVirtualDisks\\EXT-SQL01-Log01.vhdx    | 25 GB    | Fixed size            |
| ICEMAN     | EXT-SQL01-Temp01   | E:         | E:\\iSCSIVirtualDisks\\EXT-SQL01-Temp01.vhdx   | 4 GB     | Fixed size            |
| ICEMAN     | EXT-SQL01-Backup01 | E:         | E:\\iSCSIVirtualDisks\\EXT-SQL01-Backup01.vhdx | 400 GB   | Dynamically expanding |

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

## Format the iSCSI disks

![(screenshot)](https://assets.technologytoolbox.com/screenshots/58/6C0090FB5D9B2C7374718A5010E32C78396F3A58.png)

Right-click **Disk 1** and then click **Online**. The status of the disk changes from **Offline** to **Not Initialized**.

Right-click **Disk 1** and then click **Initialize Disk**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B5/DFF44CFEAB403757ACFD84F51C1C888A022605B5.png)

Right-click the unallocated space on **Disk 1** and click **New Simple Volume..**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/42/0430C4C9ABFCC78D659DCFA2D93713CEDD821A42.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5C/C9C2317AB04FD707FBB58C861439316FA9023B5C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/42/5A19FDE6EF7FD5ACF090DD5FB24936E8EBCD9042.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/28/D3642189D41FFC353BA86E21FB0156EB36C10B28.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/46/CA8C8078B0AA0D8B4662A6DFE75C526B7DC14A46.png)

Repeat the steps above for the remaining disks.

> **Important**
>
> When formatting the **Data01**, **Log01**, **Temp01**, and** Backup01** disks, specify **64K** for the allocation unit size.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F5/37DBBA865AF96917C4ABC03CBE75DEC0361773F5.png)

## Install Failover Clustering feature

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BB/1A03746120FCA9D70FF9B0086946EBA2D22ADFBB.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/69/BA9E71E2A3841BD0E56D47A1E27CD74CF4858969.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A2/A3796F4D78CA6FE2E3A30845DDE0541546AEABA2.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E4/DDC573BC740127AC6A82BBB21D6A7580D3A547E4.png)

## Install Failover Clustering feature - EXT-SQL01B

## Validate failover cluster configuration and create cluster

The following steps must be performed by a member of the **EXTRANET\\Domain Admins** group (in order to create and configure the **EXT-SQL01** computer account in Active Directory -- i.e. the failover cluster virtual network name account).

![(screenshot)](https://assets.technologytoolbox.com/screenshots/92/30168140DCBE391C3899AEE66451A7B7EB4E5292.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/90/EDD87C0E2684E9E285BC3FEE03BB17F5B7BB9B90.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/91/57169AFB95049F585E2A7FC715E35AEF5334A891.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CE/5ECF8F7917DC7815148BF367D62B9D2E5B51D7CE.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2E/A9E142F0DE946BBE28ED10B6E79A16914F297D2E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D2/CD81BE5279351C5EACA88CF5999086E0ED6EECD2.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/34/1E647BAFCCE714F0C7782CBE727006DE3222EA34.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A7/3E1D513547FFA3833EC4E71169A66ED7D4800BA7.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/86/A898AC2170E787E180410B8FDE8BAFE54928A386.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1C/781F3F66CFE950E3592063E5AA3171963F34931C.png)

Click **Create the cluster now using the validated nodes...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/96/EEF5C609EA1E2824C8F14B847D210F5ED4B62496.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C2/C70A87B55EC0E0D20F1326C576D2704684886EC2.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/71/636C53F6CCF7F3C0BFA03180E05DDEC113A8D571.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DA/9E88AEF333BA6AFC9CADE611B76288700D25C0DA.png)

## Confirm cluster quorum settings

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A1/BD7BE781250976838BD789C73DD5B3B64DD716A1.png)

## Install .NET Framework 3.5

**Note:** SQL Server 2008 R2 Setup requires Microsoft .NET Framework 3.5 SP1 to be installed.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5E/392A74F1E8F7FBAF8878636FA76058D9C2633B5E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/91/59074FC1C70A065F1DD17C47DB81DD531FA17D91.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/24/82BC5B510F0B9674E890DE59A21285C71F661424.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C4/051689FF752F56810DE36FB3885D8D946F1495C4.png)

## Install SQL Server 2008 R2

![(screenshot)](https://assets.technologytoolbox.com/screenshots/31/674C362999BC5BF4D0D18A1D7DA44D3B879D2831.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/38/3A4841EFCCB0A52384424C3CA17A7FB65E793538.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/59/F40D442C8F42759CD42EBA64C63B0BBB1D957A59.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AD/568DE4ACC70DD8930E9FE9147B7B1822295FEEAD.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EA/BC46DFC6DB9E448D59E2797E49344782D48629EA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DA/0990195491E5432E96FB8578D08249D004CF6CDA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A6/1A6E475424F9648C941D91E89FB0304D53A90CA6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6A/51DD07BE7BC72545A180AB4C478F03AEA613E26A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3F/45083D27C0F58C4946DE010A99EB6803410E683F.png)

Fix binding order and run SQL Server Setup again.

```Console
C:\NotBackedUp\Public\Toolbox\nvspbind\x64\nvspbind.exe /o ms_tcpip
...
Protocols:

{D7DBFF6D-F51F-4C94-BF35-9CFEBEBA7578}
"ms_tcpip"
"Internet Protocol Version 4 (TCP/IPv4)":
   enabled:   Local Area Connection* 9
   enabled:   Production
   enabled:   Storage

cleaning up...finished (0)

C:\NotBackedUp\Public\Toolbox\nvspbind\x64\nvspbind.exe /++ "Production" ms_tcpip
...
acquiring write lock...success


Protocols:

{D7DBFF6D-F51F-4C94-BF35-9CFEBEBA7578}
"ms_tcpip"
"Internet Protocol Version 4 (TCP/IPv4)":
   enabled:   Local Area Connection* 9
   enabled:   Production
   enabled:   Storage

moving 'Production' to the top

   enabled:   Production
   enabled:   Local Area Connection* 9
   enabled:   Storage

'Production' found

cleaning up...releasing write lock...success
finished (0)
```

From Detail.txt:

2014-02-01 08:47:00 Slp: Init rule target object: Microsoft.SqlServer.Configuration.SetupExtension.NetworkBindingFacet\
2014-02-01 08:47:00 Slp:   NetworkBindingFacet: Looking up network binding order.\
2014-02-01 08:47:00 Slp:   NetworkBindingFacet:   Network: 'LAN 1 - 192.168.10.x' Device: '\\Device\\{135B5C69-92FD-47E5-B016-777E597F0F52}' Domain: 'extranet.technologytoolbox.com' Adapter Id: '{135B5C69-92FD-47E5-B016-777E597F0F52}'\
2014-02-01 08:47:00 Slp:   NetworkBindingFacet:   Network: 'Local Area Connection* 9' Device: '\\Device\\{E522D006-7BF8-4899-ACA0-64D71E88D9E1}' Domain: '' Adapter Id: '{E522D006-7BF8-4899-ACA0-64D71E88D9E1}'\
2014-02-01 08:47:00 Slp:   NetworkBindingFacet:   Network: 'iSCSI 1 - 10.1.10.x' Device: '\\Device\\{15F2221D-8DBC-499C-9A43-9CC4BA20CAA9}' Domain: '' Adapter Id: '{15F2221D-8DBC-499C-9A43-9CC4BA20CAA9}'\
2014-02-01 08:47:00 Slp: IsDomainInCorrectBindOrder: The top network interface 'LAN 1 - 192.168.10.x' is bound to domain 'extranet.technologytoolbox.com' and the current domain is 'CORP.TECHNOLOGYTOOLBOX.COM'.

Restart SQL Server setup.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6C/DFD89F35828006CF77C4BCAB95EC6832F843866C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B8/873F41C6CB5F3F7F68CEDA8BF0C467B5007A7AB8.png)

Select:

- **Database Engine Services**
- **Management Tools - Complete**

**Note:** When **Database Engine Services** is selected, **SQL Server Replication** and **Full-Text Search** are automatically selected (and cannot be cleared without also clearing **Database Engine Services**). Similarly, **Management Tools - Basic** is automatically selected when **Management Tools - Complete** is selected.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/79/AAAD714C71FB93377FEEB0B0319DB126FD6E2D79.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/20/5E6E65E2E98D6E16268F0CF4C17F2151011ABF20.png)

In the **SQL Server Network Name** box, type the SQL Server cluster name (**EXT-SQL01**).

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FF/405A3A36A68A097D87FFE439F51CAB2A481A75FF.png)

On the **Cluster Resource Group** page, ensure **SQL Server cluster resource group name** is set to the default value of **SQL Server (MSSQLSERVER)**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F3/C433F98BE513D16CA1EC1648C025E2C3C3FC0DF3.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2F/F4213B26C52A73AC3084071B982CDF1C6159C02F.png)

On the **Cluster Disk Selection **page, select all of the available cluster disks (**Cluster Disk 2**, **Cluster Disk 3**, **Cluster Disk 4**, and **Cluster Disk 5**).

![(screenshot)](https://assets.technologytoolbox.com/screenshots/36/67F72027648299B0F68E2AE87FC934E1F85A5236.png)

On the **Cluster Network Configuration** page:

1. In the **IPv4** row:
   1. Clear the checkbox in the **DHCP** column.
   2. In the **Address** column, type the IP address (**192.168.10.205**) corresponding to the SQL Server cluster name.
2. In the **IPv6** row, clear the checkbox to prevent IPv6 from being used for the cluster network.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4D/C58149F179EDD10BA67A6AC5E03AB55BEBED824D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/66/0BB08D4B587A9C54FEAA436DA1E093A214873D66.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9B/09CAC25426C11B6DEDDA722B81130E627BE38D9B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/72/22F845557E0A095E75E2CFD6A271B3F312AE0C72.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/18/CBA8AFAC0A7493F6BD668F3D016EDD356CD78718.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CA/089D56FD79DF2D4F68D7C4CD57F6B6CDF5F4E7CA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/07/589984854AA7DCE7B652336A2494E073CEDDC707.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/69/5CE6820A04DD494D8C11F0624C83510EE5817969.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/13/230BCD1D043B28DF451CBD351F190C387EFE3013.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/92/891EF81D2D651820480819886CBED1D3A59EFD92.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/91/361209BF9D3E52E83E937B7FDF4E31FD40043091.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D6/8140E264B00C0542EB1D1F72F3E0E09C0AF6F7D6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5F/DEFB5839B73E4833FC0010A2EE497B4BC051EF5F.png)

## Add node to SQL Server failover cluster - EXT-SQL01B

## Install SQL Server 2008 R2 Service Pack 3

![(screenshot)](https://assets.technologytoolbox.com/screenshots/71/51F97F9682528CBEECC6FC68E17134DD988A2E71.png)

In the **Server Name** section, right-click the SQL Server cluster name and click **Properties**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A2/C34227E3F6CA5B633E91A8E44546B879A9ED05A2.png)

In the **Possible Owners** list, clear the checkbox for the passive node (**EXT-SQL01B**) and then click **OK**.

Install service pack on EXT-SQL01B.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DD/4BA7A05164145C4ECC3CF501D83B559E0C26D1DD.png)

UAC, click **Yes**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/48/810D807FC363531FA3EB129D6CFCA49F2D0D7948.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/19/8FF2BFD7F337D56388A0681D02881B5064934D19.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/40/A097E11B4A027FC22196B8614B1C946CB56F9C40.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9A/233D7B030E24C173D4861AA0DCE300B49431129A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2F/50598949BF657AF427F770EE6981D71D1E36932F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/12/D66DFD1B39F191703B9E557519CF7CFC29ADA112.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/87/E5DE0103903B7F3797C9D20C0C2319DE8441B587.png)

In the **Server Name** section, right-click the SQL Server cluster name and click **Properties**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/18/EA852AA03D3B6830A56DC00FBEAF6F496F028018.png)

In the **Possible Owners** list, select the checkbox for the passive node (**EXT-SQL01B**) and then click **OK**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/74/CED77B4D9FA75A43DCC5F8CEC295234479BBE474.png)

Under **Services and applications**, right-click **SQL Server (MSSQLSERVER)**, point to **Move this service or application to another node**, and click **1 - Move to node EXT-SQL01B**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D3/8B12513F87E733A61616137F3891F738960920D3.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E2/DD82C16614D2F7B35A09022C6577F35B437E25E2.png)

Wait for the **Status** column to show **Online** for all of the resources.

Repeat the process to update the other cluster node (EXT-SQL01A). After the upgrade is complete, move  SQL Server back to EXT-SQL01A.

```PowerShell
cls
```

## # Configure firewall rule for SQL Server

# **Note:** New-NetFirewallRule is not available on Windows Server 2008 R2

```PowerShell
netsh advfirewall firewall add rule `
    name="SQL Server Database Engine" `
    dir=in `
    action=allow `
    protocol=TCP `
    localport=1433
```

```PowerShell
cls
```

## # Create backup maintenance plans

### # Create folders for database backups

```PowerShell
mkdir Z:\MSSQL10_50.MSSQLSERVER\MSSQL\Backup\Full

mkdir 'Z:\MSSQL10_50.MSSQLSERVER\MSSQL\Backup\Transaction Log'

mkdir Z:\MSSQL10_50.MSSQLSERVER\MSSQL\Backup\Differential
```

### Create maintenance plans

<table>
<thead>
<th>
<p><strong>Name</strong></p>
</th>
<th>
<p><strong>Frequency</strong></p>
</th>
<th>
<p><strong>Daily Frequency</strong></p>
</th>
</thead>
<tr>
<td valign='top'>
<p>Full Backup of All Databases</p>
</td>
<td valign='top'>
<p>Occurs: <strong>Weekly</strong><br />
Recurs every: <strong>1</strong> week on</p>
<ul>
<li><strong>Sunday</strong></li>
</ul>
</td>
<td valign='top'>
<p>Occurs once at: <strong>12:00:00 AM</strong></p>
</td>
</tr>
<tr>
<td valign='top'>
<p>Transaction Log Backup of All Databases</p>
</td>
<td valign='top'>
<p>Occurs: <strong>Daily</strong><br />
Recurs every: <strong>1</strong> day</p>
</td>
<td valign='top'>
<p>Occurs every: <strong>1 hour</strong><br />
Starting at:<strong> 12:55:00 AM</strong><br />
Ending at:<strong> 11:59:59 PM</strong></p>
</td>
</tr>
<tr>
<td valign='top'>
<p>Differential Backup of All Databases</p>
</td>
<td valign='top'>
<p>Occurs: <strong>Daily</strong><br />
Recurs every: <strong>1</strong> day</p>
</td>
<td valign='top'>
<p>Occurs once at: <strong>11:30:00 PM</strong></p>
</td>
</tr>
</table>

```PowerShell
cls
```

## # Create scheduled task to delete old database backups

### # Change PowerShell execution policy

```PowerShell
Set-ExecutionPolicy RemoteSigned -Force
```

### Import scheduled task

## Configure DCOM permissions for SSIS

The application-specific permission settings do not grant Local Launch permission for the COM Server application with CLSID\
{46063B1E-BE4A-4014-8755-5B377CD462FC}\
 and APPID\
{FAAFC69C-F4ED-4CCA-8849-7B882279EDBE}\
 to the user EXTRANET\\svc-sql-agent SID (S-1-5-21-224930944-1780242101-1199596236-1107) from address LocalHost (Using LRPC). This security permission can be modified using the Component Services administrative tool.

Using the steps in **[KB 2000474](KB 2000474) Workaround 1**, add **Local Launch** permissions on **MsDtsServer100** to **EXTRANET\\svc-sql-agent**.

```PowerShell
cls
```

## # Install and configure System Center Operations Manager

### # Create certificate for Operations Manager

#### # Create request for Operations Manager certificate

```PowerShell
& "C:\NotBackedUp\Public\Toolbox\Operations Manager\Scripts\New-OperationsManagerCertificateRequest.ps1"
```

#### Submit certificate request to the Certification Authority

**To submit the certificate request to an enterprise CA:**

1. On the computer hosting the Operations Manager feature for which you are requesting a certificate, start Internet Explorer, and browse to Active Directory Certificate Services site ([https://cipher01.corp.technologytoolbox.com/](https://cipher01.corp.technologytoolbox.com/)).
2. On the **Welcome** page, click **Request a certificate**.
3. On the **Advanced Certificate Request** page, click **Submit a certificate request by using a base-64-encoded CMC or PKCS #10 file, or submit a renewal request by using a base-64-encoded PKCS #7 file.**
4. On the **Submit a Certificate Request or Renewal Request** page, in the **Saved Request** text box, paste the contents of the certificate request generated in the previous procedure.
5. In the **Certificate Template** section, select the Operations Manager certificate template (**Technology Toolbox Operations Manager**), and then click **Submit**. When prompted to allow the digital certificate operation to be performed, click **Yes**.
6. On the **Certificate Issued** page, click **Download certificate** and save the certificate.

```PowerShell
cls
```

#### # Import the certificate into the certificate store

```PowerShell
$certFile = "C:\Users\jjameson-admin\Downloads\certnew.cer"

CertReq.exe -Accept $certFile

Remove-Item $certFile
```

```PowerShell
cls
```

### # Install SCOM agent

---

**FOOBAR8**

```PowerShell
cls
```

### # Mount the Operations Manager installation media

```PowerShell
$imagePath = `
    '\\ICEMAN\Products\Microsoft\System Center 2012 R2' `
    + '\en_system_center_2012_r2_operations_manager_x86_and_x64_dvd_2920299.iso'

Set-VMDvdDrive -ComputerName STORM -VMName EXT-SQL01A -Path $imagePath
```

---

```PowerShell
$msiPath = 'X:\agent\AMD64\MOMAgent.msi'

msiexec.exe /i $msiPath `
    MANAGEMENT_GROUP=HQ `
    MANAGEMENT_SERVER_DNS=jubilee.corp.technologytoolbox.com `
    ACTIONS_USE_COMPUTER_ACCOUNT=1
```

```PowerShell
cls
```

### # Import the certificate into Operations Manager using MOMCertImport

```PowerShell
$hostName = ([System.Net.Dns]::GetHostByName(($env:computerName))).HostName

$certImportToolPath = 'X:\SupportTools\AMD64'

Push-Location "$certImportToolPath"

.\MOMCertImport.exe /SubjectName $hostName

Pop-Location
```

---

**FOOBAR8**

```PowerShell
cls
```

### # Remove the Operations Manager installation media

```PowerShell
Set-VMDvdDrive -ComputerName STORM -VMName EXT-SQL01A -Path $null
```

---

### # Approve manual agent install in Operations Manager

```PowerShell
cls
```

## # Resolve WMI error after every reboot

### Alert

_Source: WinMgmt_\
_Event ID: 10_\
_Event Category: 0_\
_User: N/A_\
_Computer: EXT-SQL01A.extranet.technologytoolbox.com_\
_Event Description: Event filter with query "SELECT * FROM __InstanceModificationEvent WITHIN 60 WHERE TargetInstance ISA "Win32_Processor" AND TargetInstance.LoadPercentage > 99" could not be reactivated in namespace "//./root/CIMV2" because of error 0x80041003. Events cannot be delivered through this filter until the problem is corrected._

### Reference

**Event ID 10 is logged in the Application log after you install Service Pack 1 for Windows 7 or Windows Server 2008 R2**\
From <[https://support.microsoft.com/en-us/kb/2545227](https://support.microsoft.com/en-us/kb/2545227)>

### Solution

---

**VBScript**

```PowerShell
strComputer = "."

Set objWMIService = GetObject("winmgmts:" _
  & "{impersonationLevel=impersonate}!\\" _
  & strComputer & "\root\subscription")

Set obj1 = objWMIService.ExecQuery("select * from __eventfilter where name='BVTFilter' and query='SELECT * FROM __InstanceModificationEvent WITHIN 60 WHERE TargetInstance ISA ""Win32_Processor"" AND TargetInstance.LoadPercentage > 99'")

For Each obj1elem in obj1
  set obj2set = obj1elem.Associators_("__FilterToConsumerBinding")
  set obj3set = obj1elem.References_("__FilterToConsumerBinding")

  For each obj2 in obj2set
    WScript.echo "Deleting the object"
    WScript.echo obj2.GetObjectText_

    obj2.Delete_
  Next

  For each obj3 in obj3set
    WScript.echo "Deleting the object"
    WScript.echo obj3.GetObjectText_

    obj3.Delete_
  Next

  WScript.echo "Deleting the object"
  WScript.echo obj1elem.GetObjectText_

  obj1elem.Delete_
Next
```

---

## # Enter a product key and activate Windows

```PowerShell
slmgr /ipk {product key}
```

**Note:** When notified that the product key was set successfully, click **OK**.

```Console
slmgr /ato
```

## Issue - IPv6 address range changed by Comcast

### # Remove static IPv6 address

```PowerShell
$interfaceAlias = "Production"

$ipAddress = "2601:282:4201:e500::211"
```

# **Note:** Remove-NetIPAddress is not available on Windows Server 2008 R2

```Console
netsh interface ipv6 delete address interface=$interfaceAlias address=$ipAddress store=persistent
```

### # Update IPv6 DNS servers

# **Note:** Set-DNSClientServerAddress is not available on Windows Server 2008 R2

```Console
netsh interface ipv6 set dnsserver name=$interfaceAlias source=static address=2603:300b:802:8900::209

netsh interface ipv6 add dnsserver name=$interfaceAlias address=2603:300b:802:8900::210
```

**TODO:**

## Issue: Expired sessions are not being deleted from the ASP.NET Session State database (Central Administion > Review problems and solutions)

### Details from SQL Server job history

Date		9/15/2014 7:25:00 AM\
Log		Job History (SessionState_Job_DeleteExpiredSessions)

Step ID		0\
Server		EXT-SQL01\
Job Name		SessionState_Job_DeleteExpiredSessions\
Step Name		(Job outcome)\
Duration		00:00:00\
Sql Severity		0\
Sql Message ID		0\
Operator Emailed\
Operator Net sent\
Operator Paged\
Retries Attempted		0

Message\
The job failed.  Unable to determine if the owner (TECHTOOLBOX\\jjameson-admin) of job SessionState_Job_DeleteExpiredSessions has server access (reason: Could not obtain information about Windows NT group/user 'TECHTOOLBOX\\jjameson-admin', error code 0x5. [SQLSTATE 42000] (Error 15404)).

### Resolution

```SQL
USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_id=N'62c052aa-a3cd-444f-a781-ae79eca6359e',
    @owner_login_name=N'EXTRANET\svc-sharepoint'
GO
```

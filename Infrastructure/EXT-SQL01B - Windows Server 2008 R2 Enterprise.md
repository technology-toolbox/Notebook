# EXT-SQL01B - Windows Server 2008 R2 Enterprise

Sunday, April 17, 2016
12:16 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

### # Create virtual machine

```PowerShell
$vmHost = "BEAST"
$vmName = "EXT-SQL01B"

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

## Login as EXT-SQL01B\\foo

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
$ipAddress = "192.168.10.212"
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
$ipAddress = "2601:282:4201:e500::212"
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
$ipAddress = "10.1.10.212"
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
netdom renamecomputer $env:COMPUTERNAME /newname:EXT-SQL01B /reboot
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
$computerName = "EXT-SQL01B"
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

Fix binding order:

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

```Console
Cls
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

Set-VMDvdDrive -ComputerName BEAST -VMName EXT-SQL01B -Path $imagePath
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
Set-VMDvdDrive -ComputerName BEAST -VMName EXT-SQL01B -Path $null
```

---

### # Approve manual agent install in Operations Manager

```PowerShell
cls
```

## # Resolve WMI error after every reboot

### Alert

Source: WinMgmt\
Event ID: 10\
Event Category: 0\
User: N/A\
Computer: EXT-SQL01B.extranet.technologytoolbox.com\
Event Description: Event filter with query "SELECT * FROM __InstanceModificationEvent WITHIN 60 WHERE TargetInstance ISA "Win32_Processor" AND TargetInstance.LoadPercentage > 99" could not be reactivated in namespace "//./root/CIMV2" because of error 0x80041003. Events cannot be delivered through this filter until the problem is corrected.

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

$ipAddress = "2601:282:4201:e500::212"
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

## # Upgrade to System Center Operations Manager 2016

### # Uninstall SCOM 2012 R2 agent

```PowerShell
msiexec /x `{786970C5-E6F6-4A41-B238-AE25D4B91EEA`}

Restart-Computer
```

### # Install SCOM 2016 agent

```PowerShell
net use \\tt-fs01.corp.technologytoolbox.com\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$msiPath = "\\tt-fs01.corp.technologytoolbox.com\Products\Microsoft" `
    + "\System Center 2016\Agents\SCOM\AMD64\MOMAgent.msi"

msiexec.exe /i $msiPath `
    MANAGEMENT_GROUP=HQ `
    MANAGEMENT_SERVER_DNS=tt-scom01.corp.technologytoolbox.com `
    ACTIONS_USE_COMPUTER_ACCOUNT=1
```

> **Important**
>
> Wait for the installation to complete.

### Approve manual agent install in Operations Manager

**TODO:**

# XAVIER1 (2013-12-29) - Windows Server 2012 R2

Sunday, December 29, 2013
3:05 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Create virtual machine

```PowerShell
icacls 'C:\NotBackedUp\VMs\XAVIER1\Virtual Hard Disks\XAVIER1.vhd'

copy '\\STORM\VM Library\ws2012std-r2\Virtual Hard Disks\ws2012std-r2.vhd' `
    'C:\NotBackedUp\VMs\XAVIER1\Virtual Hard Disks\XAVIER1.vhd'

$vmName = "XAVIER1"

Set-VMMemory `
    -VMName $vmName `
    -DynamicMemoryEnabled $true `
    -MaximumBytes 2GB `
    -MinimumBytes 256MB `
    -StartupBytes 512MB

Start-VM $vmName
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EC/3D908EEB5274F9E4C78AF5A99B0E4F78F01BCAEC.png)

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

## Rename the server and join domain

```Console
sconfig
```

## Add network adapter (iSCSI 1 - 10.1.10.x)

## Rename network connections

```PowerShell
Get-NetAdapter -Physical

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "LAN 1 - 192.168.10.x"

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter #2" |
    Rename-NetAdapter -NewName "iSCSI 1 - 10.1.10.x"
```

## Configure static IP address

```PowerShell
$ipAddress = "192.168.10.103"

New-NetIPAddress -InterfaceAlias "LAN 1 - 192.168.10.x" -IPAddress $ipAddress `
    -PrefixLength 24 -DefaultGateway 192.168.10.1

Set-DNSClientServerAddress -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -ServerAddresses 192.168.10.104
```

## Configure iSCSI network adapter

```PowerShell
$ipAddress = "10.1.10.103"

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

## Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name "LAN 1 - 192.168.10.x" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Set-NetAdapterAdvancedProperty -Name "iSCSI 1 - 10.1.10.x" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Restart-Computer

ping BEAST -f -l 8900
ping 10.1.10.106 -f -l 8900
```

Note: Trying to ping BEAST or the iSCSI network adapter on ICEMAN with a 9000 byte packet from XAVIER1 resulted in an error (suggesting that jumbo frames were not configured). Note that 9000 works from ICEMAN to BEAST. When I decreased the packet size to 8900, it worked on XAVIER1. (It also worked with 8970 bytes.)

## Enable iSCSI Initiator

Start -> iSCSI Initiator

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EB/4A53DA5A4340A8ABE5F2AF9FFAADA619B36BA5EB.png)

Click Yes.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9A/B54534041BE9EBB7BFFD0E55049BF636C6FC889A.png)

## Create iSCSI virtual disk (XAVIER1-Backup01.vhdx)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1B/777148954AF6A60422F00404E1E136A546AB501B.png)

## Discover iSCSI Target portal

![(screenshot)](https://assets.technologytoolbox.com/screenshots/72/8313A23CC5FB9E97557F1E272594355FF3E6B572.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2A/6213B3CD19D36E47382BF220A9022F68F9BB042A.png)

Try using PowerShell instead

```PowerShell
$chapUserName = "iqn.1991-05.com.microsoft:xavier1.corp.technologytoolbox.com"

New-IscsiTargetPortal -TargetPortalAddress 10.1.10.106 `
    -AuthenticationType OneWayCHAP `
    -ChapUserName $chapUserName -ChapSecret {password}

Get-iScsiTarget | Connect-iScsitarget -AuthenticationType OneWayCHAP `
    -ChapUserName $chapUserName -ChapSecret {password}
```

Connect-iScsitarget : Authentication Failure.\
At line:1 char:19\
+ Get-iScsiTarget | Connect-iScsitarget -AuthenticationType OneWayCHAP -ChapUserNa ...\
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\
    + CategoryInfo          : NotSpecified: (MSFT_iSCSITarget:ROOT/Microsoft/...SFT_iSCSITarget) [Connect-IscsiTarget]\
   , CimException\
    + FullyQualifiedErrorId : HRESULT 0xefff0009,Connect-IscsiTarget

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FC/7798425A70F41A427A520AFCDB8F049B70374AFC.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5B/413419677D759BB760ED3DAF0AA09FB2DEC5EB5B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/81/F685A7642CD3846C0B3355A402323E3DBA073981.png)

On the **Volumes and Devices** tab, click **Auto Configure**.

## Online the iSCSI LUN

```PowerShell
Get-Disk | Set-Disk -IsOffline $false
```

The PowerShell above doesn't work (the disk still appears offline in Disk Management).

## Add Windows Server Backup feature

```PowerShell
Add-WindowsFeature Windows-Server-Backup -IncludeManagementTools
```

## Configure and run backup

![(screenshot)](https://assets.technologytoolbox.com/screenshots/18/61DBD3F3387DED5C868C17FB30F19A51018F4418.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/70/83DD076968F7C85EADB59647F29ABC09710E2E70.png)

On the **Features** step, click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8F/1D1089E5512D3C7ED60ED9AC136148430FF2078F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A8/C129E0181684EF8D57398F8D788E3DD3C5A4E5A8.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BF/CC28CFE53982D1FD59B88DF14BA0AF2097742ABF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D3/074A4B24163ABC9250EDF2F507BACF85FE2A7CD3.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AA/E1CC63EB399C62F25754ACB1688769E35B26C2AA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DA/F43E9DC0EF3C0EDED49478476C9C86926CC9C2DA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C7/A3B54695E5D00D3C2C54201C503E10DC8E74BEC7.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6C/425A28412D60AC07AA3E4CD79FB82C089BB8506C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D3/47BA2FF3FF900B89553E9593F758E060744901D3.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5C/8196103BFC38F83BFD6F3D359AE75A4AA268BC5C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/29/6B8FE8AD773737E5E69DA191BC50A1E3EF602C29.png)

Restart the server

## Convert VHD to new format

Stop the virtual machine

```Console
cd 'C:\NotBackedUp\VMs\XAVIER1\Virtual Hard Disks'
Convert-VHD -Path .\XAVIER1.vhd -DestinationPath .\XAVIER1.vhdx
Set-VHD .\XAVIER1.vhdx -PhysicalSectorSizeBytes 4096
Remove-Item .\XAVIER1.vhd
```

Modify VM settings to change path for virtual hard disk file

## Migrate XAVIER1 from STORM to ROGUE

## Configure NTP

PS C:\\Windows\\system32> cd HKLM:SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\DateTime\
PS HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\DateTime> dir

    Hive: HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\DateTime

Name                           Property\
----                           --------\
Servers                        (default) : 1\
                               1         : time.windows.com\
                               3         : time-nw.nist.gov\
                               5         : time-b.nist.gov\
                               2         : time.nist.gov\
                               4         : time-a.nist.gov

**How to configure an authoritative time server in Windows Server**\
Pasted from <[http://support.microsoft.com/kb/816042](http://support.microsoft.com/kb/816042)>

**Synchronize the Time Server for the Domain Controller with an External Source**\
Pasted from <[http://technet.microsoft.com/en-us/library/cc784553(v=ws.10).aspx](http://technet.microsoft.com/en-us/library/cc784553(v=ws.10).aspx)>

**Configuring an authoritative time source for your Windows domain**\
Pasted from <[http://windowshell.wordpress.com/2012/01/02/configuring-an-authoritative-time-source-for-your-windows-domain/](http://windowshell.wordpress.com/2012/01/02/configuring-an-authoritative-time-source-for-your-windows-domain/)>

**Configuring Time Synchronization for all Computers in a Windows domain**\
Pasted from <[http://www.altaro.com/hyper-v/configuring-time-synchronization-for-all-computers-in-windows-domain/](http://www.altaro.com/hyper-v/configuring-time-synchronization-for-all-computers-in-windows-domain/)>

**How to configure your virtual Domain Controllers and avoid simple mistakes with resulting big problems**\
Pasted from <[http://www.sole.dk/how-to-configure-your-virtual-domain-controllers-and-avoid-simple-mistakes-with-resulting-big-problems/](http://www.sole.dk/how-to-configure-your-virtual-domain-controllers-and-avoid-simple-mistakes-with-resulting-big-problems/)>

**Configure a time server for Active Directory domain controllers**\
Pasted from <[http://www.techrepublic.com/blog/the-enterprise-cloud/configure-a-time-server-for-active-directory-domain-controllers/](http://www.techrepublic.com/blog/the-enterprise-cloud/configure-a-time-server-for-active-directory-domain-controllers/)>

**Setting a Domain Controller to Sync with External NTP Server**\
Pasted from <[http://seanofarrelll.blogspot.com/2010/04/setting-domain-controller-to-sync-with.html](http://seanofarrelll.blogspot.com/2010/04/setting-domain-controller-to-sync-with.html)>

NtpServer: time.windows.com,0x1 time-nw.nist.gov,0x1 time-b.nist.gov,0x1 time.nist.gov,0x1 time-a.nist.gov,0x1\
MaxPosPhaseCorrection: 3600 Decimal\
MaxNegPhaseCorrection: 3600 Decimal

Numerous attempts to synchronize time failed:

- Restart computer
- w32tm /resync /rediscover

Finally ended up disabling **Time synchronization** service in virtual machine settings -- which contradicts Ben's blog post:

**Time Synchronization in Hyper-V**\
Pasted from <[http://blogs.msdn.com/b/virtual_pc_guy/archive/2010/11/19/time-synchronization-in-hyper-v.aspx](http://blogs.msdn.com/b/virtual_pc_guy/archive/2010/11/19/time-synchronization-in-hyper-v.aspx)>

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

## Remove Windows Server Backup

```PowerShell
wbadmin delete catalog

wevtutil cl Microsoft-Windows-Backup

Remove-WindowsFeature Windows-Server-Backup -Remove
```

## Remove iSCSI disks and stop iSCSI Initiator service

![(screenshot)](https://assets.technologytoolbox.com/screenshots/56/80FA8C5896BD1ECBF7D4F27BE0DC1BFFD371F756.png)

Click **Remove**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C5/A8CC409F92D5BC05F0025A94EB22BA44D4CE02C5.png)

Click **Remove**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/48/AD24DD5BD590F3DE7B457773C4E1A7EA14B8B248.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6C/659DC3CF16315FD81C3D1280DED5E57BA258B66C.png)

Stop service and then change **Startup type** to **Manual**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8C/94E50655366996A40DBB22509D17530DD87BF48C.png)

Restart the computer.

## # Add Windows Server Backup feature

```PowerShell
Add-WindowsFeature `
    Windows-Server-Backup `
    -IncludeManagementTools `-Source '\\ICEMAN\Products\Microsoft\Windows Server 2012 R2\Sources\SxS'
```

## # Install DPM agent

```PowerShell
$imagePath = "\\iceman\Products\Microsoft\System Center 2012 R2" `
    + "\mu_system_center_2012_r2_data_protection_manager_x86_and_x64_dvd_2945939.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$installer = $imageDriveLetter + ":\SCDPM\Agents\DPMAgentInstaller_x64.exe"

& $installer JUGGERNAUT.corp.technologytoolbox.com
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8B/DE6E3530B2C2E5130BF43C4B39E6F689065D4C8B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DB/B15AC92355B12F0F970BB08BE054CBE3D62C6DDB.png)

### Reference

**Installing Protection Agents Manually**\
Pasted from <[http://technet.microsoft.com/en-us/library/hh757789.aspx](http://technet.microsoft.com/en-us/library/hh757789.aspx)>

## Attach DPM agent

**Note: Did *not* create "Allow DPM Remote Agent Push" firewall rule**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/97/C2EBDBC18CAD62D7948875B1C4A24CC84BA31B97.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/29/3A987323C13C1AD9020B6F2EC3602CC74B951F29.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2C/E1DB4D360771821A2A05956589E2B8E6D2AC142C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/09/ECFF5CC2AE843F8D0E1C79A50771BF5951775B09.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B7/09C288AB704BB1FF036B084768B9C4D8944F97B7.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/33/CD1ED6522C17EAA8F23B945DF6F3424291BAB433.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/39/A4BA5A9925C42417D34CB4ED41F05222DA722739.png)

### Reference

**Attaching Protection Agents**\
Pasted from <[http://technet.microsoft.com/en-us/library/hh757916.aspx](http://technet.microsoft.com/en-us/library/hh757916.aspx)>

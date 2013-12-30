# XAVIER2 (2013-12-29) - Windows Server 2012 R2

Sunday, December 29, 2013
3:05 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Create virtual machine

```PowerShell
icacls 'C:\NotBackedUp\VMs\XAVIER2\Virtual Hard Disks\XAVIER2.vhd'

copy '\\STORM\VM Library\ws2012std-r2\Virtual Hard Disks\ws2012std-r2.vhd' `
    'C:\NotBackedUp\VMs\XAVIER2\Virtual Hard Disks\XAVIER2.vhd'

$vmName = "XAVIER2"

Set-VMMemory `
    -VMName $vmName `
    -DynamicMemoryEnabled $true `
    -MaximumBytes 2GB `
    -MinimumBytes 256MB `
    -StartupBytes 512MB

Start-VM $vmName
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/01/0199B8E889E0F7F904D64D1971F5A1E5FD3B1B01.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EE/C7623B9D9759D3500C99099F64ED5B2115BA62EE.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BF/65B1B9F4877C1FEEF582C7D78549373FD5CCF6BF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/00/65DD2DDF9A6B95EE82F269413EE5C7B8BEADF800.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/52/D0DC7A8120091CB4E0A0C87D35452F6313019A52.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D6/36842CB5D7336F1CB4CF0F89B8271AF59FB8BFD6.png)

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

![(screenshot)](https://assets.technologytoolbox.com/screenshots/31/77F8FFB92F52749671F56F5B2DE847273093B531.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/68/C31326C399FDE72552A14CC590DC1026D2AA2868.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/38/28C2EC69F80466908219CA2B4803DE2E3D0A7338.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/65/1C5F8E932EAE27E08857352BDBA7D2FDA55EE165.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D7/1935237937E431C0576742771F4BA093BFB796D7.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/70/DC832E2BC6BB1171070D86F8025A1B6DA77E1170.png)

## Rename network connection

```PowerShell
Get-NetAdapter -Physical

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "LAN 1 - 192.168.10.x"
```

## Configure static IP address

```PowerShell
$ipAddress = "192.168.10.104"

New-NetIPAddress -InterfaceAlias "LAN 1 - 192.168.10.x" -IPAddress $ipAddress `
    -PrefixLength 24 -DefaultGateway 192.168.10.1

Set-DNSClientServerAddress -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -ServerAddresses 192.168.10.103,192.168.10.104
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/25/5CFE3AB76865E7FB14ABB0083FF2576A180E4F25.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BF/C1701DF2C5E324097C72A697E4298A79EDD72DBF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/30/95F18511CC7247AEBFB056D86C056311CDF89630.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2A/E0D0C0A53D17F9E2DCBC3A2ECB3387E403DAB32A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DB/53FD22EF24962F60F270380E8C3E8A352BC150DB.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/54/EB6403E9F02D11A48E6836EC7A8B7C8E7283E954.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A5/9BDDC9D841D62E3A5B658AE6E6DA6475AB292EA5.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FA/29835D73F1783E60AE4570565720B1D28D7719FA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8F/89013EB683AB8A7E2108016531D69C096FDDA38F.png)

On the **Features** step, click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/26/9F952E3838E994BACAD3ECCD59F4358DA67F0026.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/90/44305DAAA0E7AA89C211BE4F1A4CE1FA5296F490.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/94/70FF3874946F7CA61DC5B64697E2BBF80B9BFA94.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/45/9FFF78B26CDCEA3FD07E229064F66F48855A8345.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1A/1A0F5A6B0CA38FD5897E01B74833085AFC19751A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F2/1253437CB248293978956EA71C38F5074036C7F2.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E1/82A09619946260FC6D8B6BD7FE01086226F39CE1.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/17/9C5D0A2947FA127E7448B74C7D8130348CF6CD17.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5E/B7F4FB092FE45559E3697B91EBD8D439C47B6E5E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/48/B7A12629D88B4E1672C3D5B9B3B8A508DED26848.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/64/AB604BC43A2F9429E5B3761933AA8C8B11C9DA64.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5E/8BDAAA5F87A584D46C8BE96094F0801D1AF1715E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9B/9E4B48E7ECA5AE6899A305FA215EA6547638989B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/93/0EFC0F81D75573B9562152EB1B4377EEB1E64893.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2B/288CC3157F01B1ED4105CE4D1178DDDA303D542B.png)

Click **View script**

```PowerShell
#
# Windows PowerShell script for AD DS Deployment
#

Import-Module ADDSDeployment
Install-ADDSDomainController `
-NoGlobalCatalog:$false `
-CreateDnsDelegation:$true `
-CriticalReplicationOnly:$false `
-DatabasePath "C:\Windows\NTDS" `
-DomainName "corp.technologytoolbox.com" `
-InstallDns:$true `
-LogPath "C:\Windows\NTDS" `
-NoRebootOnCompletion:$false `
-SiteName "Default-First-Site" `
-SysvolPath "C:\Windows\SYSVOL" `
-Force:$true
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E8/DE1165A26F535E8225942626561620A292FBFDE8.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E2/828D5FBAA68C62AB52E60DBD40D56CDA1676D4E2.png)

Wait for server to restart

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B8/0FF971159D593DD5BA088BC90E35377D815579B8.png)

## Add network adapter (Virtual iSCSI 1 - 10.1.10.x)

## Rename iSCSI network connection

```PowerShell
Get-NetAdapter -Physical

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter #2" |
    Rename-NetAdapter -NewName "iSCSI 1 - 10.1.10.x"

Get-NetAdapter -Physical
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/95/20E4C35F689933FC42CC887E6582187A5B4D5695.png)

## # Configure iSCSI network adapter

```PowerShell
$ipAddress = "10.1.10.104"

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

## # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name "LAN 1 - 192.168.10.x" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Set-NetAdapterAdvancedProperty -Name "iSCSI 1 - 10.1.10.x" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

ping BEAST -f -l 8900
ping 10.1.10.106 -f -l 8900
```

Note: Trying to ping BEAST or the iSCSI network adapter on ICEMAN with a 9000 byte packet from XAVIER2 resulted in an error (suggesting that jumbo frames were not configured). Note that 9000 works from ICEMAN to BEAST. When I decreased the packet size to 8900, it worked on XAVIER2. (It also worked with 8970 bytes.)

## Enable iSCSI Initiator

Start -> iSCSI Initiator

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DF/3F6DE64EBF1E201BDD47D798802EEBB2C9A72CDF.png)

Click **Yes**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5B/38F75FA3835C75B20A80D63314FE3463D9B3095B.png)

## Discover iSCSI Target portal

On the **Discovery** tab, in the **Target portals** section, click **Discover Portal...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/01/5AF2023C517FB8FDD3FACC7214E310797B6A0401.png)

In the **Discover Target Portal** window, in the **IP address or DNS name** box, type **10.1.10.106**, and then click **OK**.

## Create iSCSI virtual disk (XAVIER2-Backup01.vhdx)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/71/D7E61D1EB8206FD6D5C5044BBE92767E9A6B5071.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/90/A222DAA567A68DE76ABEEA1FE95632349EEB3090.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5A/850F6496A17CB0821DD5E88252B32403C1091B5A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A2/C39058A2E059B98FA52D494B4C8BAAB1F186BBA2.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/01/98CE812BBCC1D35A681B16B23D69916527994A01.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F9/551ED6B2353BA8DA0BB0EA94E461B00FC07A63F9.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/67/3F7B136DB150BEFD2033803A3C3AC8E6EA818367.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DA/AAD595666AA29AB645C763745695DA863923ABDA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EA/B959B689AEC5207309B9262E89EED49B197D24EA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3D/30153B16CA543BFB0D81B04FE31BF04792F1593D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4C/CBE127A313427057ED5A31303D0BB8212F1C024C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E3/391185C152DBD047CD23F73891E2E0D74996C5E3.png)

Wait for iSCSI virtual disk to be cleared.

## Configure CHAP on iSCSI Target portal

```PowerShell
Remove-IscsiTargetPortal -TargetPortalAddress 10.1.10.106

$chapUserName = "iqn.1991-05.com.microsoft:xavier2.corp.technologytoolbox.com"

New-IscsiTargetPortal -TargetPortalAddress 10.1.10.106 `
    -AuthenticationType OneWayCHAP `
    -ChapUserName $chapUserName -ChapSecret {password}
```

## Configure CHAP on iSCSI Target

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DA/6029B939D5BA8F88098F2F9B8B425516CC35FADA.png)

Click **Connect**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/77/50DC77E45AA28D3BFF48AB02FBDF90144F668077.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C2/3EF7AB9D2670CE32C6F9E92B676C59D3AEBC21C2.png)

On the **Volumes and Devices** tab, click **Auto Configure**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D3/A34E7F894EE4E7C175929A873C63A657500ED5D3.png)

## Online the iSCSI LUN

![(screenshot)](https://assets.technologytoolbox.com/screenshots/27/964A9E28D8E0C0487BFB50CFB98545BAEB224C27.png)

Right click **Disk 1** and then click **Online**.

Right click **Disk 1** and then click **Initialize Disk**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B8/29131AA6EDE5CBFC5A52427B6154BCCE839750B8.png)

## Add Windows Server Backup feature

```PowerShell
Add-WindowsFeature Windows-Server-Backup -IncludeManagementTools
```

## Configure and run backup

## Convert VHD to new format

Stop the virtual machine

```Console
cd 'C:\NotBackedUp\VMs\XAVIER2\Virtual Hard Disks'
Convert-VHD -Path .\XAVIER2.vhd -DestinationPath .\XAVIER2.vhdx
Set-VHD .\XAVIER2.vhdx -PhysicalSectorSizeBytes 4096
Remove-Item .\XAVIER2.vhd
```

Modify VM settings to change path for virtual hard disk file

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

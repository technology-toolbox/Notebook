# EXT-DC02 - Windows Server 2012 R2 Standard

Wednesday, January 01, 2014
4:56 AM

```Console
12345678901234567890123456789012345678901234567890123456789012345678901234567890

PowerShell
```

## Create virtual machine

```PowerShell
$vmName = "EXT-DC02"

New-VM `
    -Name $vmName `
    -Path C:\NotBackedUp\VMs `
    -MemoryStartupBytes 512MB `
    -SwitchName "Virtual LAN 2 - 192.168.10.x"

Set-VMMemory `
    -VMName $vmName `
    -DynamicMemoryEnabled $true `
    -MaximumBytes 2GB `
    -MinimumBytes 256MB `
    -StartupBytes 512MB

$sysPrepedImage =
    "\\STORM\VM Library\ws2012std-r2\Virtual Hard Disks\ws2012std-r2.vhd"

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

Convert-VHD `
    -Path $sysPrepedImage `
    -DestinationPath $vhdPath

Set-VHD $vhdPath -PhysicalSectorSizeBytes 4096

Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath

Start-VM $vmName
```

## Rename the server and join domain

```PowerShell
Rename-Computer -NewName EXT-DC02 -Restart

Add-Computer -DomainName extranet.technologytoolbox.com -Restart
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

## Rename network connection

```PowerShell
Get-NetAdapter -Physical

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "LAN 1 - 192.168.10.x"
```

## Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name "LAN 1 - 192.168.10.x" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

ping ICEMAN -f -l 8900
```

## Configure static IP address

```PowerShell
$ipAddress = "192.168.10.210"

New-NetIPAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -IPAddress $ipAddress `
    -PrefixLength 24 `
    -DefaultGateway 192.168.10.1

Set-DNSClientServerAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -ServerAddresses 192.168.10.209
```

## Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name "LAN 1 - 192.168.10.x" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

ping EXT-DC01 -f -l 8900
```

## Add Active Directory

![(screenshot)](https://assets.technologytoolbox.com/screenshots/99/D4CF279CF2AA6A3601568EE5571B7F6B103C7699.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BA/C6221CB04BF9D6B24491E288D2AD87E75A617DBA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B0/EDD7259698D18F449694B606B66C2B7DA867E7B0.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1D/70D3EC009DD99DD7D1069B9B1DEFCB5BE7DC4A1D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C5/55516E30EC7360A0AC59124BF3B7213A041AC4C5.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F5/4B4F2EE4877CCAEDDF7ABCF6435BFA2DDCF984F5.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/86/7E28DC33FC53BAB6E48C3DD17D686FCD56AE4886.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B7/3D45333EE3943C403E907D1EBD6E2A6D08DD05B7.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/91/8B8A912FECC30CECAB4FCF71533942E98E0CA891.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4B/1A99409128FC2A6ED3E84DCEE0F12D351F3EB54B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BE/FAE8E9DB2C916D1251EF079A9BB76548CEBD79BE.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/15/A8A1766C1EE18227E1F2D33865A2AEFDB344D215.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8F/BD8D8916D36280066C38443FD6BEE9D76215458F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7D/15AC4F98DE14D170E6C567987A7D827CF3A86B7D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8E/46250388AFDFC14C0794949D423570BFC76E208E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5C/6FD5FFED429FBE04969C1915EF7E3A03A65C1B5C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/33/E513C6B99710854C9174C443B9300077C2E5E733.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E1/1D763FA2E0F4E10773010510891724884183B6E1.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5C/76BCD8DECE475435ADF2F1216C4AF38E6996175C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C5/A9D911DFC9D6EBF5A9A331691E06B5672A8099C5.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/79/D8222D13B74C0BACF11CF39165F9E2A7851B5D79.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B5/3658A0B08DD59D459C141524CD9F1B2742BF85B5.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7F/7B3950066497B15DA4064A0A637350C30540267F.png)

```PowerShell
#
# Windows PowerShell script for AD DS Deployment
#

Import-Module ADDSDeployment
Install-ADDSDomainController `
    -NoGlobalCatalog:$false `
    -CreateDnsDelegation:$false `
    -CriticalReplicationOnly:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -DomainName "extranet.technologytoolbox.com" `
    -InstallDns:$true `
    -LogPath "C:\Windows\NTDS" `
    -NoRebootOnCompletion:$false `
    -SiteName "Default-First-Site-Name" `
    -SysvolPath "C:\Windows\SYSVOL" `
    -Force:$true
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8B/0AF91B7677B81E80AA582B8D9E48E399FA23938B.png)

## # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

## # Update static IPv6 address

```PowerShell
netsh int ipv6 delete address "LAN 1 - 192.168.10.x" 2601:1:8200:6000::210

netsh int ipv6 delete dns "LAN 1 - 192.168.10.x" 2601:1:8200:6000::209

netsh int ipv6 add address "LAN 1 - 192.168.10.x" 2601:282:4201:e500::210

netsh int ipv6 add dns "LAN 1 - 192.168.10.x" 2601:282:4201:e500::209 index=1
```

## # Configure firewall rules for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
New-NetFirewallRule `
    -Name 'Remote Windows Update (DCOM-In)' `
    -DisplayName 'Remote Windows Update (DCOM-In)' `
    -Description 'Allows remote auditing and installation of Windows updates via POSHPAIG (http://poshpaig.codeplex.com/)' `
    -Group 'Remote Windows Update' `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 135 `
    -Profile Domain `
    -Action Allow

New-NetFirewallRule `
    -Name 'Remote Windows Update (Dynamic RPC)' `
    -DisplayName 'Remote Windows Update (Dynamic RPC)' `
    -Description 'Allows remote auditing and installation of Windows updates via POSHPAIG (http://poshpaig.codeplex.com/)' `
    -Group 'Remote Windows Update' `
    -Program '%windir%\system32\dllhost.exe' `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort RPC `
    -Profile Domain `
    -Action Allow

Enable-NetFirewallRule `
    -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)"

Enable-NetFirewallRule `
    -DisplayName "File and Printer Sharing (Echo Request - ICMPv6-In)"
```

## # Disable firewall rules for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
Disable-NetFirewallRule -Group 'Remote Windows Update'
```

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

```PowerShell
net use \\iceman.corp.technologytoolbox.com\IPC$ /USER:TECHTOOLBOX\jjameson

$imagePath = `
    '\\iceman.corp.technologytoolbox.com\Products\Microsoft\System Center 2012 R2' `
    + '\en_system_center_2012_r2_operations_manager_x86_and_x64_dvd_2920299.iso'

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$msiPath = $imageDriveLetter + ':\agent\AMD64\MOMAgent.msi'

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

$certImportToolPath = $imageDriveLetter + ':\SupportTools\AMD64'

cd "$certImportToolPath"

.\MOMCertImport.exe /SubjectName $hostName
```

### # Approve manual agent install in Operations Manager

## Issue - IPv6 address range changed by Comcast

### # Update static IPv6 address

```PowerShell
$oldIpAddress = "2601:282:4201:e500::210"
$newIpAddress = "2603:300b:802:8900::210"
$ifIndex = Get-NetIPAddress $oldIpAddress |
    Select -ExpandProperty InterfaceIndex

New-NetIPAddress `
    -InterfaceIndex $ifIndex `
    -IPAddress $newIpAddress

Remove-NetIPAddress `
    -InterfaceIndex $ifIndex `
    -IPAddress $oldIpAddress `
    -Confirm:$false
```

### # Update IPv6 DNS servers

```PowerShell
Set-DnsClientServerAddress `
    -InterfaceIndex $ifIndex `
    -ServerAddresses 2603:300b:802:8900::209, ::1
```

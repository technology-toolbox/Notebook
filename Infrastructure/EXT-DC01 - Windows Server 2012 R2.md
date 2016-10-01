# EXT-DC01 - Windows Server 2012 R2 Standard

Wednesday, January 01, 2014
1:29 PM

```Console
12345678901234567890123456789012345678901234567890123456789012345678901234567890

PowerShell
```

## Create virtual machine

```PowerShell
$vmName = "EXT-DC01"

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

## Rename network connection

```PowerShell
Get-NetAdapter -Physical

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "LAN 1 - 192.168.10.x"
```

## Configure static IP address

```PowerShell
$ipAddress = "192.168.10.209"

New-NetIPAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -IPAddress $ipAddress `
    -PrefixLength 24 `
    -DefaultGateway 192.168.10.1

Set-DNSClientServerAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -ServerAddresses 192.168.10.210
```

## Add network adapter (Virtual iSCSI 1 - 10.1.10.x)

```PowerShell
$vmName = "EXT-DC01"
Stop-VM $vmName

Add-VMNetworkAdapter `
    -VMName $vmName `
    -SwitchName "Virtual iSCSI 1 - 10.1.10.x"

Start-VM $vmName
```

## Rename iSCSI network connection

```PowerShell
Get-NetAdapter -Physical

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter #2" |
    Rename-NetAdapter -NewName "iSCSI 1 - 10.1.10.x"

Get-NetAdapter -Physical
```

## Configure iSCSI network adapter

```PowerShell
$ipAddress = "10.1.10.209"

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

ping BEAST -f -l 8900
ping 10.1.10.106 -f -l 8900
```

Note: Trying to ping BEAST or the iSCSI network adapter on ICEMAN with a 9000 byte packet from EXT-DC01 resulted in an error (suggesting that jumbo frames were not configured). Note that 9000 works from ICEMAN to BEAST. When I decreased the packet size to 8900, it worked on EXT-DC01. (It also worked with 8970 bytes.)

## Enable iSCSI Initiator

Start -> iSCSI Initiator

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DF/3F6DE64EBF1E201BDD47D798802EEBB2C9A72CDF.png)

Click **Yes**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5B/38F75FA3835C75B20A80D63314FE3463D9B3095B.png)

## Discover iSCSI Target portal

On the **Discovery** tab, in the **Target portals** section, click **Discover Portal...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/01/5AF2023C517FB8FDD3FACC7214E310797B6A0401.png)

In the **Discover Target Portal** window, in the **IP address or DNS name** box, type **10.1.10.106**, and then click **OK**.

## Create iSCSI virtual disk (EXT-DC01-Backup01.vhdx)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/01/686CE825AC91BDF99951DBCD8F7690F371546301.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EB/656ADB35FD8EEF0A7B11DA729274265968179BEB.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DF/57B50BC438A6DC8B165527073200E56523C287DF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D6/BC2BF480D916A413C35BDCB9D96286E3238854D6.png)

On the **Specify target name** page, in the **Name** box, type **EXT-DC01**.

...

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4C/D58CF0CD33AA14745BEF24C7AD218376A64DBE4C.png)

Wait for iSCSI virtual disk to be cleared.

## Configure CHAP on iSCSI Target portal

```PowerShell
Remove-IscsiTargetPortal -TargetPortalAddress 10.1.10.106 -Confirm:$false

$chapUserName =
    "iqn.1991-05.com.microsoft:ext-dc01.extranet.technologytoolbox.com"

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

## Online the iSCSI LUN

![(screenshot)](https://assets.technologytoolbox.com/screenshots/77/FBA6BF731CDCAC84DD427F80A3A6655B70C27677.png)

Right click the iSCSI disk and then click **Bring Online**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CE/7E5092864A06644E0FF221133B7F1C495E284DCE.png)

Right click the iSCSI disk and then click **Initialize**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/18/83698A23B069E9543AFD696A0D65CD40A7B6E018.png)

## Add Windows Server Backup feature

```PowerShell
Add-WindowsFeature Windows-Server-Backup -IncludeManagementTools
```

## Configure backup

![(screenshot)](https://assets.technologytoolbox.com/screenshots/72/DAD684016272EB43172772D9AA3D376AD8477D72.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/46/CFB300166C9DADBE687AEAE1E535C4859DFD7D46.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2F/447794D00DC121CEEA52D6ABB621CA8A1931FF2F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1C/5DC1614003A2C154462A9E5307063F379A8C791C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/30/93543A5E69AF0C3FB8D7C06B4AB521C66A8AA430.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8A/76B2744A4FAF0AC451ECE7C9A524CF9C204B3F8A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/76/9AE82625AADF351C5C528ACAEEA0B0C37F022276.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DC/8A19F23482F40332647E26B7E10519FDD9FE94DC.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7F/FC355C3088FA367ED026BDE422A52A563C83F77F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/57/4C743ADFC3B611610FC8E74908CC63D419B83757.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8F/FC290D776C4FCEF3F74FDC5555F7C33A9695F38F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A1/018655B85C749E22AEDFD1626868CFE412DFC5A1.png)

## Backup server using scheduled backup options

In the **Actions** pane, click **Backup Once...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9F/3F748A9AB88CE6B0BCD80D2D7DC9599A5681909F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2B/B3630C0D77E8D82BCF740D851606E4F0DC65762B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/74/1E042D520283C8E5E8440370466DA31C68FDE774.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3C/AC4F9E620B8F05ADC28A4CC8E549B0549375763C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/02/552057DB75CD9E37002CDC2DB6BB678ABD8ED302.png)

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
    -DomainName "extranet.technologytoolbox.com" `
    -InstallDns:$true `
    -LogPath "C:\Windows\NTDS" `
    -NoRebootOnCompletion:$false `
    -SiteName "Default-First-Site-Name" `
    -SysvolPath "C:\Windows\SYSVOL" `
    -Force:$true
```

## # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

## Enable Active Directory recycle bin

1. Open **Active Directory Administrative Center**
2. Click **Raise the domain functional level...**
   - Raise the domain functional level to **Windows Server 2008 R2**
3. Click **Raise the forest functional level...**
   - Raise the forest functional level to **Windows Server 2008 R2**
4. Click **Enable Recycle Bin...**

## # Rename service accounts

```PowerShell
$VerbosePreference = "Continue"

Get-ADUser -Filter {SamAccountName -like "svc-*"} |
    ForEach-Object {
        If ($_.Name -like "Service account *")
        {
            Write-Verbose "Renaming service account ($($_.SamAccountName))..."

            $newName = $_.Name.Replace("Service account", "Old service account")

            Write-Debug "Current name: $($_.Name)"
            Write-Debug "New name: $newName"

            Set-ADUser $_ -DisplayName $newName

            Rename-ADObject -Identity $_ -NewName $newName
        }
    }
```

```PowerShell
cls
```

## # Create service accounts for Fabrikam Demo applications

### # Create service account - "Service account for Fabrikam Web application"

```PowerShell
$displayName = "Service account for Fabrikam Web application"
$defaultUserName = "s-web-fabrikam"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@corp.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=IT,DC=extranet,DC=technologytoolbox,DC=com"

New-ADUser `
    -Name $displayName `
    -DisplayName $displayName `
    -SamAccountName $cred.UserName `
    -AccountPassword $cred.Password `
    -UserPrincipalName $userPrincipalName `
    -Path $orgUnit `
    -Enabled:$true `
    -CannotChangePassword:$true `
    -PasswordNeverExpires:$true
```

### # Create service account - 'Service account for SharePoint "Portal Super User"'

```PowerShell
$displayName = 'Service account for SharePoint "Portal Super User"'
$defaultUserName = "s-sp-psu"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@corp.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=IT,DC=extranet,DC=technologytoolbox,DC=com"

New-ADUser `
    -Name $displayName `
    -DisplayName $displayName `
    -SamAccountName $cred.UserName `
    -AccountPassword $cred.Password `
    -UserPrincipalName $userPrincipalName `
    -Path $orgUnit `
    -Enabled:$true `
    -CannotChangePassword:$true `
    -PasswordNeverExpires:$true
```

### # Create service account - 'Service account for SharePoint "Portal Super Reader"'

```PowerShell
$displayName = 'Service account for SharePoint "Portal Super Reader"'
$defaultUserName = "s-sp-psr"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@corp.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=IT,DC=extranet,DC=technologytoolbox,DC=com"

New-ADUser `
    -Name $displayName `
    -DisplayName $displayName `
    -SamAccountName $cred.UserName `
    -AccountPassword $cred.Password `
    -UserPrincipalName $userPrincipalName `
    -Path $orgUnit `
    -Enabled:$true `
    -CannotChangePassword:$true `
    -PasswordNeverExpires:$true
```

### # Create service account - "Service account for Fabrikam Web application (DEV)"

```PowerShell
$displayName = "Service account for Fabrikam Web application (DEV)"
$defaultUserName = "s-web-fabrikam-dev"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@corp.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=Development,DC=extranet,DC=technologytoolbox,DC=com"

New-ADUser `
    -Name $displayName `
    -DisplayName $displayName `
    -SamAccountName $cred.UserName `
    -AccountPassword $cred.Password `
    -UserPrincipalName $userPrincipalName `
    -Path $orgUnit `
    -Enabled:$true `
    -CannotChangePassword:$true `
    -PasswordNeverExpires:$true
```

### # Create service account - 'Service account for SharePoint "Portal Super User" (DEV)'

```PowerShell
$displayName = 'Service account for SharePoint "Portal Super User" (DEV)'
$defaultUserName = "s-sp-psu-dev"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@corp.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=Development,DC=extranet,DC=technologytoolbox,DC=com"

New-ADUser `
    -Name $displayName `
    -DisplayName $displayName `
    -SamAccountName $cred.UserName `
    -AccountPassword $cred.Password `
    -UserPrincipalName $userPrincipalName `
    -Path $orgUnit `
    -Enabled:$true `
    -CannotChangePassword:$true `
    -PasswordNeverExpires:$true
```

### # Create service account - 'Service account for SharePoint "Portal Super Reader" (DEV)'

```PowerShell
$displayName = 'Service account for SharePoint "Portal Super Reader" (DEV)'
$defaultUserName = "s-sp-psr-dev"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@corp.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=Development,DC=extranet,DC=technologytoolbox,DC=com"

New-ADUser `
    -Name $displayName `
    -DisplayName $displayName `
    -SamAccountName $cred.UserName `
    -AccountPassword $cred.Password `
    -UserPrincipalName $userPrincipalName `
    -Path $orgUnit `
    -Enabled:$true `
    -CannotChangePassword:$true `
    -PasswordNeverExpires:$true
```

## # Update static IPv6 address

```PowerShell
netsh int ipv6 delete address "LAN 1 - 192.168.10.x" 2601:1:8200:6000::209

netsh int ipv6 delete dns "LAN 1 - 192.168.10.x" 2601:1:8200:6000::210

netsh int ipv6 add address "LAN 1 - 192.168.10.x" 2601:282:4201:e500::209

netsh int ipv6 add dns "LAN 1 - 192.168.10.x" 2601:282:4201:e500::210 index=1
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

Push-Location "$certImportToolPath"

.\MOMCertImport.exe /SubjectName $hostName

Pop-Location
```

### # Approve manual agent install in Operations Manager

## Resolve issue with resolving smtp-test.technologytoolbox.com

### Alert

Source: Microsoft-SharePoint Products-SharePoint Foundation\
Event ID: 6856\
Event Category: 4\
User: EXTRANET\\svc-sharepoint\
Computer: EXT-APP01A.extranet.technologytoolbox.com\
Event Description: Cannot resolve name of SMTP host smtp-test.technologytoolbox.com.

### Solution

Add conditional forwarder for **technologytoolbox.com** (**XAVIER1**, **XAVIER2**)

## Install Microsoft Message Analyzer 1.4

## Issue - IPv6 address range changed by Comcast

### # Update static IPv6 address

```PowerShell
$oldIpAddress = "2601:282:4201:e500::209"
$newIpAddress = "2603:300b:802:8900::209"
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
    -ServerAddresses 2603:300b:802:8900::210, ::1
```

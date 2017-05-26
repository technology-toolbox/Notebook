# EXT-DC04 - Windows Server 2016

Thursday, January 26, 2017
4:49 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV02A"
$vmName = "EXT-DC04"
$vmPath = "E:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"
$sysPrepedImage = "\\TT-FS01\VM-Library\VHDs\WS2016-Std.vhdx"

$vhdUncPath = $vhdPath.Replace("E:", "\\TT-HV02A\E$")

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 2GB `
    -SwitchName "Tenant vSwitch"

Copy-Item $sysPrepedImage $vhdUncPath

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 2 `
    -DynamicMemory `
    -MemoryMaximumBytes 4GB `
    -MemoryMinimumBytes 1GB

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Set password for the local Administrator account

```PowerShell
cls
```

### # Rename local Administrator account

```PowerShell
$adminUser = [ADSI] 'WinNT://./Administrator,User'

$adminUser.Rename('foo')

logoff
```

```PowerShell
cls
```

### # Configure networking

```PowerShell
$interfaceAlias = "Datacenter"
```

#### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

#### # Configure static IPv4 address

```PowerShell
$ipAddress = "192.168.10.209"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24 `
    -DefaultGateway 192.168.10.1
```

#### # Configure IPv4 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 192.168.10.210
```

#### # Configure static IPv6 address

```PowerShell
$ipAddress = "2603:300b:802:8900::209"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress
```

##### # Configure IPv6 DNS server

```PowerShell
Set-DnsClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 2603:300b:802:8900::210
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

Start-Sleep -Seconds 10

ping iceman.corp.technologytoolbox.com -f -l 8900
```

### Rename server and join domain

#### Login as local administrator account

```PowerShell
cls
```

### # Rename server

```PowerShell
Rename-Computer -NewName EXT-DC04 -Restart
```

> **Note**
>
> Wait for the VM to restart.

### Login as local administrator account

```PowerShell
cls
```

### # Join server to domain

```PowerShell
Add-Computer -DomainName extranet.technologytoolbox.com -Restart
```

### Login as domain administrator account

### # Set time zone

```PowerShell
tzutil /s "Mountain Standard Time"
```

### # Copy Toolbox content

```PowerShell
net use \\TT-FS01.corp.technologytoolbox.com\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$source = "\\TT-FS01.corp.technologytoolbox.com\Public\Toolbox"
$destination = "C:\NotBackedUp\Public\Toolbox"

robocopy $source $destination  /E /XD "Microsoft SDKs"
```

### # Set MaxPatchCacheSize to 0 (recommended)

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

## Configure storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label | Host Cache |
| ---- | ------------ | ----------- | -------------------- | ------------ | ---------- |
| 0    | C:           | 32 GB       | 4K                   |              | Read/Write |
| 1    | D:           | 5 GB        | 4K                   | Data01       | None       |

```PowerShell
cls
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

---

**FOOBAR8**

```PowerShell
cls
```

### # Add disk for Active Directory storage

```PowerShell
$vmHost = "TT-HV02A"
$vmName = "EXT-DC04"

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 5GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path $vhdPath `
    -ControllerType SCSI
```

---

```PowerShell
cls
```

### # Initialize disks and format volumes

```PowerShell
Get-Disk 1 |
    Initialize-Disk -PartitionStyle GPT -PassThru |
    New-Partition -UseMaximumSize -DriveLetter D |
    Format-Volume `
        -FileSystem NTFS `
        -NewFileSystemLabel "Data01" `
        -Confirm:$false
```

## Configure domain controller

### Login as EXTRANET\\jjameson-admin

```PowerShell
cls
```

### # Install Active Directory Domain Services

```PowerShell
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools -Restart
```

> **Note**
>
> A restart was not needed after installing Active Directory Domain Services.

```PowerShell
cls
```

### # Promote server to domain controller

```PowerShell
Import-Module ADDSDeployment

Install-ADDSDomainController `
    -DomainName "extranet.technologytoolbox.com" `
    -DatabasePath "D:\Windows\NTDS" `
    -LogPath "D:\Windows\NTDS" `
    -SysvolPath "D:\Windows\SYSVOL" `
    -CreateDnsDelegation:$false `
    -SiteName "Technology-Toolbox-HQ" `
    -CriticalReplicationOnly:$false `
    -InstallDns:$true `
    -NoGlobalCatalog:$false `
    -NoRebootOnCompletion:$false `
    -Force:$true
```

> **Note**
>
> When prompted, specify the password for the administrator account when the computer is started in Safe Mode or a variant of Safe Mode, such as Directory Services Restore Mode.

```PowerShell
cls
```

## # Install and configure System Center Operations Manager

### # Create certificate for Operations Manager

#### # Create request for Operations Manager certificate

```PowerShell
& "C:\NotBackedUp\Public\Toolbox\Operations Manager\Scripts\New-OperationsManagerCertificateRequest.ps1"
```

#### # Submit certificate request to the Certification Authority

##### # Add Active Directory Certificate Services site to the "Trusted sites" zone and browse to the site

```PowerShell
[Uri] $adcsUrl = [Uri] "https://cipher01.corp.technologytoolbox.com"

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-InternetSecurityZoneMapping.ps1 `
    -Zone LocalIntranet `
    -Patterns $adcsUrl.AbsoluteUri

Start-Process $adcsUrl.AbsoluteUri
```

##### # Submit the certificate request to an enterprise CA

> **Note**
>
> Copy the certificate request to the clipboard.

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
```

```PowerShell
cls
```

#### # Delete the certificate file

```PowerShell
Remove-Item $certFile
```

### # Install SCOM agent

```PowerShell
net use \\TT-FS01.corp.technologytoolbox.com\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

#### # Mount the Operations Manager installation media

```PowerShell
$imagePath = ('\\TT-FS01.corp.technologytoolbox.com\Products\Microsoft' `
    + '\System Center 2012 R2' `
    + '\en_system_center_2012_r2_operations_manager_x86_and_x64_dvd_2920299.iso')

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter
```

#### # Start the Operations Manager installation

```PowerShell
$msiPath = $imageDriveLetter + ':\agent\AMD64\MOMAgent.msi'

msiexec.exe /i $msiPath `
    MANAGEMENT_GROUP=HQ `
    MANAGEMENT_SERVER_DNS=jubilee.corp.technologytoolbox.com `
    ACTIONS_USE_COMPUTER_ACCOUNT=1
```

> **Important**
>
> Wait for the installation to complete.

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

#### # Remove the Operations Manager installation media

```PowerShell
Dismount-DiskImage -ImagePath $imagePath
```

### Approve manual agent install in Operations Manager

### Configure SCOM agent for domain controller

In the **Agent Properties** window, on the **Security** tab, select **Allow this agent to act as a proxy and discover managed objects on other computers** and then click **OK**.

```PowerShell
cls
```

## # Enter a product key and activate Windows

```PowerShell
slmgr /ipk {product key}
```

> **Note**
>
> When notified that the product key was set successfully, click **OK**.

```Console
slmgr /ato
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

### Configure SCOM agent for domain controller

#### Enable agent proxy

In the **Agent Properties** window, on the **Security** tab, select **Allow this agent to act as a proxy and discover managed objects on other computers** and then click **OK**.

```PowerShell
cls
```

#### # Enable SCOM agent to run as LocalSystem on domain controller

```PowerShell
Push-Location "C:\Program Files\Microsoft Monitoring Agent\Agent"

.\HSLockdown.exe HQ /R "NT AUTHORITY\SYSTEM"

Pop-Location

Restart-Service HealthService
```

##### Reference

**Deploying SCOM 2016 Agents to Domain controllers - some assembly required**\
From <[https://blogs.technet.microsoft.com/kevinholman/2016/11/04/deploying-scom-2016-agents-to-domain-controllers-some-assembly-required/](https://blogs.technet.microsoft.com/kevinholman/2016/11/04/deploying-scom-2016-agents-to-domain-controllers-some-assembly-required/)>

## Configure NTP

```Text
PS C:\windows\system32> cd HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\DateTime
PS HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DateTime> dir


    Hive: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\DateTime


Name                           Property
----                           --------
Servers                        (default) : 1
                               1         : time.windows.com
                               2         : time.nist.gov


reg add HKLM\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\VMICTimeProvider /v Enabled /t reg_dword /d 0
```

When prompted to overwrite the value, type **yes**.

NtpServer: time.windows.com,0x1 time-nw.nist.gov,0x1 time-b.nist.gov,0x1 time.nist.gov,0x1 time-a.nist.gov,0x1\
SpecialPollInterval: 900\
MaxPosPhaseCorrection: 3600 Decimal\
MaxNegPhaseCorrection: 3600 Decimal

**To configure an internal time server to synchronize with an external time source, follow these steps:**

1. Change the server type to NTP. To do this, follow these steps:
   1. Click **Start**, click **Run**, type **regedit**, and then click **OK**.
   2. Locate and then click the following registry subkey:
**HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\W32Time\\Parameters\\Type**
   3. In the pane on the right, right-click **Type**, and then click **Modify**.
   4. In **Edit Value**, type **NTP** in the **Value data** box, and then click **OK**.
2. Set AnnounceFlags to 5. To do this, follow these steps:
   1. Locate and then click the following registry subkey:
**HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\W32Time\\Config\\AnnounceFlags**
   2. In the pane on the right, right-click **AnnounceFlags**, and then click **Modify**.
   3. In **Edit DWORD Value**, type **5** in the **Value data** box, and then click **OK**.

**Notes**
      - If an authoritative time server that is configured to use an AnnounceFlag value of 0x5 does not synchronize with an upstream time server, a client server may not correctly synchronize with the authoritative time server when the time synchronization between the authoritative time server and the upstream time server resumes. Therefore, if you have a poor network connection or other concerns that may cause time synchronization failure of the authoritative server to an upstream server, set the AnnounceFlag value to 0xA instead of to 0x5.
      - If an authoritative time server that is configured to use an AnnounceFlag value of 0x5 and to synchronize with an upstream time server at a fixed interval that is specified in SpecialPollInterval, a client server may not correctly synchronize with the authoritative time server after the authoritative time server restarts. Therefore, if you configure your authoritative time server to synchronize with an upstream NTP server at a fixed interval that is specified in SpecialPollInterval, set the AnnounceFlag value to 0xA instead of 0x5.
3. Enable NTPServer. To do this, follow these steps:
   1. Locate and then click the following registry subkey:
**HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\W32Time\\TimeProviders\\NtpServer**
   2. In the pane on the right, right-click **Enabled**, and then click **Modify**.
   3. In **Edit DWORD Value**, type **1** in the **Value data** box, and then click **OK**.
4. Specify the time sources. To do this, follow these steps:
   1. Locate and then click the following registry subkey:
**HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\W32Time\\Parameters**
   2. In the pane on the right, right-click **NtpServer**, and then click **Modify**.
   3. In **Edit Value**, type Peers in the **Value data** box, and then click **OK**.

**Note **Peers is a placeholder for a space-delimited list of peers from which your computer obtains time stamps. Each DNS name that is listed must be unique. You must append **,0x1** to the end of each DNS name. If you do not append **,0x1** to the end of each DNS name, the changes that you make in step 5 will not take effect.
5. Select the poll interval. To do this, follow these steps:
   1. Locate and then click the following registry subkey:
**HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\W32Time\\TimeProviders\\NtpClient\\SpecialPollInterval**
   2. In the pane on the right, right-click **SpecialPollInterval**, and then click **Modify**.
   3. In **Edit DWORD Value**, type TimeInSeconds in the **Value data** box, and then click **OK**. 

**Note **TimeInSeconds is a placeholder for the number of seconds that you want between each poll. A recommended value is 900 Decimal. This value configures the Time Server to poll every 15 minutes.
6. Configure the time correction settings. To do this, follow these steps:
   1. Locate and then click the following registry subkey:
**HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\W32Time\\Config\\MaxPosPhaseCorrection**
   2. In the pane on the right, right-click **MaxPosPhaseCorrection**, and then click **Modify**.
   3. In **Edit DWORD Value**, click to select **Decimal** in the **Base** box.
   4. In **Edit DWORD Value**, type TimeInSeconds in the **Value data** box, and then click **OK**. 

**Note **TimeInSeconds is a placeholder for a reasonable value, such as 1 hour (3600) or 30 minutes (1800). The value that you select will depend on the poll interval, network condition, and external time source.
   5. Locate and then click the following registry subkey: 
**HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\W32Time\\Config\\MaxNegPhaseCorrection**
   6. In the pane on the right, right-click **MaxNegPhaseCorrection**, and then click **Modify**.
   7. In **Edit DWORD Value**, click to select **Decimal** in the **Base** box.
   8. In **Edit DWORD Value**, type TimeInSeconds in the **Value data** box, and then click **OK**. 

**Note **TimeInSeconds is a placeholder for a reasonable value, such as 1 hour (3600) or 30 minutes (1800). The value that you select will depend on the poll interval, network condition, and external time source.
7. Close Registry Editor.
8. At the command prompt, type the following command to restart the Windows Time service, and then press Enter:
**net stop w32time && net start w32time**

Pasted from <[http://support.microsoft.com/kb/816042](http://support.microsoft.com/kb/816042)>

```Console
w32tm /resync /rediscover
```

## # Move VM to extranet VLAN

### # Enable DHCP

```PowerShell
$interfaceAlias = Get-NetAdapter `
    -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    select -ExpandProperty Name

@("IPv4", "IPv6") | ForEach-Object {
    $addressFamily = $_

    $interface = Get-NetAdapter $interfaceAlias |
        Get-NetIPInterface -AddressFamily $addressFamily

    If ($interface.Dhcp -eq "Disabled")
    {
        # Remove existing gateway
        $ipConfig = $interface | Get-NetIPConfiguration

        If ($addressFamily -eq "IPv4" -and $ipConfig.Ipv4DefaultGateway)
        {
            $interface |
                Remove-NetRoute -AddressFamily $addressFamily -Confirm:$false
        }

        If ($addressFamily -eq "IPv6" -and $ipConfig.Ipv6DefaultGateway)
        {
            $interface |
                Remove-NetRoute -AddressFamily $addressFamily -Confirm:$false
        }

        # Enable DHCP
        $interface | Set-NetIPInterface -DHCP Enabled

        # Configure the  DNS Servers automatically
        $interface | Set-DnsClientServerAddress -ResetServerAddresses
    }
}
```

### # Rename network connection

```PowerShell
$interfaceAlias = "Extranet"

Get-NetAdapter `
    -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

### # Disable jumbo frames

```PowerShell
Set-NetAdapterAdvancedProperty `
    -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 1514

Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"
```

---

**TT-VMM01A**

```PowerShell
cls
```

### # Change VM network

```PowerShell
$vmName = "EXT-DC04"

$vmNetwork = Get-SCVMNetwork -Name "Extranet VM Network"

$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName |
    ? { $_.SlotId -eq 0 }

Stop-SCVirtualMachine $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork

Start-SCVirtualMachine $vmName
```

---

### # Configure static IPv4 address

```PowerShell
$interfaceAlias = "Extranet"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress 10.1.20.103 `
    -PrefixLength 24 `
    -DefaultGateway 10.1.20.1
```

#### # Configure IPv4 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 10.1.20.104, 127.0.0.1
```

# XAVIER1 - Windows Server 2012 R2 Standard

Sunday, December 29, 2013
3:05 PM

```Console
12345678901234567890123456789012345678901234567890123456789012345678901234567890

PowerShell
```

## # Create virtual machine

```PowerShell
$vmName = "XAVIER1"

New-VM `
    -Name $vmName `
    -Path C:\NotBackedUp\VMs `
    -MemoryStartupBytes 512MB `
    -SwitchName "Virtual LAN 2 - 192.168.10.x"

Set-VMMemory `
    -VMName $vmName `
    -DynamicMemoryEnabled $true `
    -MaximumBytes 2GB

$sysPrepedImage =
    "\\ICEMAN\VM Library\ws2012std-r2\Virtual Hard Disks\ws2012std-r2.vhd"

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

Convert-VHD `
    -Path $sysPrepedImage `
    -DestinationPath $vhdPath

Set-VHD $vhdPath -PhysicalSectorSizeBytes 4096

Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath

Start-VM $vmName
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EC/3D908EEB5274F9E4C78AF5A99B0E4F78F01BCAEC.png)

## # Rename network connection

```PowerShell
Get-NetAdapter -Physical

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "LAN 1 - 192.168.10.x"
```

## # Configure static IPv4 address

```PowerShell
$ipAddress = "192.168.10.103"

New-NetIPAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -IPAddress $ipAddress `
    -PrefixLength 24 `
    -DefaultGateway 192.168.10.1

Set-DNSClientServerAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -ServerAddresses 192.168.10.104,127.0.0.1
```

## # Configure static IPv6 address

```PowerShell
$ipAddress = "2601:1:8200:6000::103"

New-NetIPAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -IPAddress $ipAddress `
    -PrefixLength 64

Set-DNSClientServerAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -ServerAddresses 2601:1:8200:6000::104,::1
```

## # Rename the server and join domain

```PowerShell
Rename-Computer -NewName XAVIER1 -Restart

Add-Computer -DomainName corp.technologytoolbox.com -Restart
```

## # Download PowerShell help files

```PowerShell
Update-Help
```

## # Change drive letter for DVD-ROM

### # To change the drive letter for the DVD-ROM using PowerShell

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
```

## # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name "LAN 1 - 192.168.10.x" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

ping ICEMAN -f -l 8900
```

## # Install Active Directory Domain Services

```PowerShell
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools -Restart
```

## # Promote server to domain controller

```PowerShell
Import-Module ADDSDeployment

Install-ADDSDomainController `
    -NoGlobalCatalog:$false `
    -CreateDnsDelegation:$false `
    -CriticalReplicationOnly:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -DomainName "corp.technologytoolbox.com" `
    -InstallDns:$true `
    -LogPath "C:\Windows\NTDS" `
    -NoRebootOnCompletion:$false `
    -SiteName "Default-First-Site" `
    -SysvolPath "C:\Windows\SYSVOL"
```

## # Add Windows Server Backup feature (DPM dependency)

```PowerShell
Add-WindowsFeature Windows-Server-Backup
```

## # Install DPM agent

```PowerShell
$imagePath = "\\iceman\Products\Microsoft\System Center 2012 R2\" `
    + "mu_system_center_2012_r2_data_protection_manager_x86_and_x64_dvd_2945939.iso"

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

## # Copy Toolbox content

```PowerShell
robocopy \\iceman\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E
```

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

**Time Synchronization in Hyper-V**\
From <[http://blogs.msdn.com/b/virtual_pc_guy/archive/2010/11/19/time-synchronization-in-hyper-v.aspx](http://blogs.msdn.com/b/virtual_pc_guy/archive/2010/11/19/time-synchronization-in-hyper-v.aspx)>

```Console
reg add HKLM\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\VMICTimeProvider /v Enabled /t reg_dword /d 0
```

When prompted to overwrite the value, type **yes**.

```Console
w32tm /config /syncfromflags:DOMHIER /update

net stop w32time & net start w32time

w32tm /resync /force

w32tm /query /source
```

NtpServer: time.windows.com,0x1 time-nw.nist.gov,0x1 time-b.nist.gov,0x1 time.nist.gov,0x1 time-a.nist.gov,0x1\
SpecialPollInterval: 900\
MaxPosPhaseCorrection: 3600 Decimal\
MaxNegPhaseCorrection: 3600 Decimal

### To configure an internal time server to synchronize with an external time source, follow these steps

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

## Create VMM Distributed Key Management container in Active Directory

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F9/C9A809E09F317B0049FE9AC455849CDC5D88DAF9.png)

Right-click **CN=System**, point to **New** and click **Object...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/83/2F8D95EB606F7952727330E5C534B09B93FE7383.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5A/F536EB10B36967208E62FFEC07DC6DDF95F15A5A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F9/E4725EAE2D0CB9879E21EBF7DF7BCF0040427AF9.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7B/F02A8DF54FB4D3578E9848BCF34CBC9F074E4C7B.png)

Right-click the new container and click **Properties**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/53/EF03E0354486723B0E51CBDFBEDBEA0544434A53.png)

In the properties window for the container, on the **Security** tab, click **Add...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D4/101CF26F7D9FF692C8DA307B3097E1E1F89C50D4.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2D/005B12BD9C5653B805934B7FE2C1D7D79825F72D.png)

Click **Advanced**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/53/0E68A1F941CAD2E9BB1A350A1B8DF455BA6C6B53.png)

In the **Permission entries** list, select the **VMM Administrators** group and click **Edit**.

In the **Permission Entry for VMM Distributed Key Management** window:

1. In the **Applies to** list, select **This object and all descendant objects**.
2. In the **Permissions** section, select **Full control**.
3. Click **OK**.

In the **Advanced Security Settings for VMM Distributed Key Management** window, click **OK**.

In the properties window for the container, click **OK**.

## Resolve SCOM alerts due to disk fragmentation

### Alert Name

Logical Disk Fragmentation Level is high

### Alert Description

The disk C: (C:) on computer XAVIER1.corp.technologytoolbox.com has high fragmentation level. File Percent Fragmentation value is 11%. Defragmentation recommended: true.

### Resolution

##### # Copy Toolbox content

```PowerShell
robocopy \\iceman\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E
```

##### # Create scheduled task to optimize drives

```PowerShell
[string] $xml = Get-Content `
  'C:\NotBackedUp\Public\Toolbox\Scheduled Tasks\Optimize Drives.xml'

Register-ScheduledTask -TaskName "Optimize Drives" -Xml $xml
```

## Resolve IPv6 issue

### Configure static IPv6 address

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7D/13DB426CA9B5D35D261B52DB2BD05AE20D93E77D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2A/6CC5EDD6FDE5C50D515CA7E6D184D2DCB562B92A.png)

### Create IPv6 reverse lookup zone

![(screenshot)](https://assets.technologytoolbox.com/screenshots/01/78632B2567565D7298DE746D6416EB4AA28C5D01.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/14/94B21BB28618C02E6781741E09212748692D9514.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A1/24EFABB7A0465E05CDEA2D80D256B3A4C67BF4A1.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/72/F2D55F95C4920600418E8F4D9417CCEEB5385872.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D2/E32ABADC94C3C11C2AEF5168D76BFB67493274D2.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/41/1C3627568D1B6CE35D2FDC56D62ECD1D5C187441.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8E/AF44CE75638DB0F49B00629B83106F8593DA788E.png)

After running **ipconfig /registerdns** on WOLVERINE:

![(screenshot)](https://assets.technologytoolbox.com/screenshots/85/9DA965A5F8EC8DA9DFA7429438CAA38087C60E85.png)

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

## # Configure firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

---

**FOOBAR8**

```PowerShell
$computer = 'XAVIER1'$command = "New-NetFirewallRule ``
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

## Resolve issue with Get-SmbDelegation cmdlet

### Issue

```Text
PS C:\Windows\system32> Get-SmbDelegation -SmbServer ICEMAN
CheckDelegationPrerequisites : SMB Delegation cmdlets require the Active Directory forest to be in Windows Server 2012 forest functional level.
At C:\windows\system32\windowspowershell\v1.0\Modules\SmbShare\SmbScriptModule.psm1:72 char:14
+     $check = CheckDelegationPrerequisites
+              ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [Write-Error], WriteErrorException
    + FullyQualifiedErrorId : Microsoft.PowerShell.Commands.WriteErrorException,CheckDelegationPrerequisites
```

### Solution

#### Raise domain functional level

Current domain functional level: **Windows Server 2008 R2**\
New domain functional level:  **Windows Server 2012**

#### Raise forest functional level

Current forest functional level: **Windows Server 2008 R2**\
New forest functional level:  **Windows Server 2012**

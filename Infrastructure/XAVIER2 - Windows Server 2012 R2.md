# XAVIER2 - Windows Server 2012 R2 Standard

Sunday, December 29, 2013
3:05 PM

```Console
12345678901234567890123456789012345678901234567890123456789012345678901234567890

PowerShell
```

## # Create virtual machine

```PowerShell
$vmName = "XAVIER2"

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

![(screenshot)](https://assets.technologytoolbox.com/screenshots/01/0199B8E889E0F7F904D64D1971F5A1E5FD3B1B01.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EE/C7623B9D9759D3500C99099F64ED5B2115BA62EE.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BF/65B1B9F4877C1FEEF582C7D78549373FD5CCF6BF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/00/65DD2DDF9A6B95EE82F269413EE5C7B8BEADF800.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D7/369785CE95AEFDFE524D91BC64480EA02934C1D7.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/10/3BE814FDDD6FCE9020BFFE7E5C62A363E6CCFF10.png)

## # Rename network connection

```PowerShell
Get-NetAdapter -Physical

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "LAN 1 - 192.168.10.x"
```

## # Configure static IP address

```PowerShell
$ipAddress = "192.168.10.104"

New-NetIPAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -IPAddress $ipAddress `
    -PrefixLength 24 `
    -DefaultGateway 192.168.10.1

Set-DNSClientServerAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -ServerAddresses 192.168.10.103
```

## # Rename the server and join domain

```PowerShell
Rename-Computer -NewName XAVIER2 -Restart

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

## # Add Windows Server Backup feature

```PowerShell
Add-WindowsFeature Windows-Server-Backup -IncludeManagementTools
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

## # Copy Toolbox content

```PowerShell
robocopy \\iceman\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E
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

![(screenshot)](https://assets.technologytoolbox.com/screenshots/88/F2543DD416103365AFDEDC6D5B9622E844745688.png)

## Configure NTP

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

## # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

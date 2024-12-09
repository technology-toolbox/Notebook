# TT-FS01C - Windows Server 2022 File Server

Saturday, October 23, 2021\
4:38 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure infrastructure

---

**TT-ADMIN04** - Run as administrator

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05E"
$vmName = "TT-FS01C"
$vmPath = "E:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 2GB `
    -SwitchName "Embedded Team Switch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 2 `
    -DynamicMemory `
    -MemoryMinimumBytes 2GB `
    -MemoryMaximumBytes 4GB `
    -AutomaticCheckpointsEnabled $false

Set-VMNetworkAdapterVlan `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Access `
    -VlanId 30

Add-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName

$vmDvdDrive = Get-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName

Set-VMFirmware `
    -ComputerName $vmHost `
    -VMName $vmName `
    -EnableSecureBoot Off `
    -FirstBootDevice $vmDvdDrive

Set-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path "\\TT-FS01\Products\Microsoft\Windows Server 2022\en-us_windows_server_version_2022_updated_october_2021_x64_dvd_b6e25591.iso"
```

```Text
Set-VMDvdDrive: Failed to add device 'Virtual CD/DVD Disk'.
User Account does not have permission to open attachment.
'TT-FS01C' failed to add device 'Virtual CD/DVD Disk'. (Virtual machine ID CC5D1560-BAE1-483C-AEDD-14A6F553DC19)
'TT-FS01C': User account does not have permission required to open attachment '\\TT-FS01\Products\Microsoft\Windows Server 2022\en-us_windows_server_version_2022_updated_october_2021_x64_dvd_b6e25591.iso'. Error: 'General access denied error' (0x80070005). (Virtual machine ID CC5D1560-BAE1-483C-AEDD-14A6F553DC19)
```

```PowerShell
cls
$iso = Get-SCISO |
    where {$_.Name -eq "en-us_windows_server_version_2022_updated_october_2021_x64_dvd_b6e25591.iso"}

Get-SCVirtualMachine -Name $vmName | Read-SCVirtualMachine

Get-SCVirtualMachine -Name $vmName |
    Get-SCVirtualDVDDrive |
    Set-SCVirtualDVDDrive -ISO $iso -Link

Start-SCVirtualMachine -VM $vmName
```

---

### Set password for the local Administrator account

After the restart required to complete the installation, the password for the
Administrator user must be changed before signing in.

### # Stop SConfig from launching at sign-in

```PowerShell
Set-SConfig -AutoLaunch $false
```

```PowerShell
cls
```

### # Rename local Administrator account

```PowerShell
$adminUser = [ADSI] 'WinNT://./Administrator,User'

$adminUser.Rename('foo')

logoff
```

### Configure networking

---

**TT-ADMIN04** - Run as administrator

```PowerShell
cls
```

#### # Assign static IP address to VM

```PowerShell
$vmName = "TT-FS01C"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"
$ipAddressPool = Get-SCStaticIPAddressPool -Name "Management-30 Address Pool"

Stop-SCVirtualMachine $vmName

$macAddress = Grant-SCMACAddress `
    -MACAddressPool $macAddressPool `
    -Description $vmName `
    -VirtualNetworkAdapter $networkAdapter

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -MACAddressType Static `
    -MACAddress $macAddress `
    -IPv4AddressPools $ipAddressPool `
    -IPv4AddressType Static

Start-SCVirtualMachine $vmName
```

---

#### Login as local administrator account

```PowerShell
cls
```

```PowerShell
$interfaceAlias = "Management"
```

#### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Start-Sleep -Seconds 10

ping TT-DC10.corp.technologytoolbox.com -f -l 8900
```

```PowerShell
cls
```

#### # Disable Link-Layer Topology Discovery on all domain computers

```PowerShell
Get-NetAdapter |
    foreach {
        $interfaceAlias = $_.Name

        Write-Host ("Disabling Link-Layer Topology Discovery on interface" `
            + " ($interfaceAlias)...")

        Disable-NetAdapterBinding -Name $interfaceAlias `
            -DisplayName "Link-Layer Topology Discovery Mapper I/O Driver"

        Disable-NetAdapterBinding -Name $interfaceAlias `
            -DisplayName "Link-Layer Topology Discovery Responder"
    }
```

> **Note**
>
> This avoids flooding the firewall log with numerous entries for UDP 5355
> broadcast.

```PowerShell
cls
```

#### # Disable NetBIOS over TCP/IP

```PowerShell
Get-NetAdapter |
    foreach {
        $interfaceAlias = $_.Name

        Write-Host ("Disabling NetBIOS over TCP/IP on interface" `
            + " ($interfaceAlias)...")

        $adapter = Get-WmiObject -Class "Win32_NetworkAdapter" `
            -Filter "NetConnectionId = '$interfaceAlias'"

        $adapterConfig = `
            Get-WmiObject -Class "Win32_NetworkAdapterConfiguration" `
                -Filter "Index= '$($adapter.DeviceID)'"

        # Disable NetBIOS over TCP/IP
        $adapterConfig.SetTcpipNetbios(2)
    }
```

> **Note**
>
> This avoids flooding the firewall log with numerous entries for UDP 137
> broadcast.

### Rename server and join domain

```PowerShell
cls
```

### # Rename server

```PowerShell
Rename-Computer -NewName TT-FS01C -Restart
```

> **Note**
>
> Wait for the VM to restart.

#### Login as local administrator account

```PowerShell
cls
```

### # Join server to domain

```PowerShell
Add-Computer -DomainName corp.technologytoolbox.com -Restart
```

---

**TT-ADMIN04** - Run as administrator

```PowerShell
cls
```

### # Move computer to different OU

```PowerShell
$vmName = "TT-FS01C"

$targetPath = ("OU=Storage Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

### # Configure Windows Update

#### # Add machine to security group for Windows Update schedule

```PowerShell
Add-ADGroupMember -Identity "Windows Update - Slot 2" -Members ($vmName + '$')
```

---

#### Login as local administrator account

```PowerShell
cls
```

### # Set time zone

```PowerShell
tzutil /s "Mountain Standard Time"
```

### # Copy Toolbox content

```PowerShell
$source = "\\TT-FS01\Public\Toolbox"
$destination = "C:\NotBackedUp\Public\Toolbox"

robocopy $source $destination  /E /XD git-for-windows "Microsoft SDKs"
```

### # Set MaxPatchCacheSize to 0 (recommended)

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

---

### Configure storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 32 GB       | 4K                   | OSDisk       |
| 1    | D:           | 600 GB      | 4K                   | Data01       |
| 2    | E:           | 600 GB      | 4K                   | Data02       |
| 3    | F:           | 200 GB      | 4K                   | Data03       |

```PowerShell
cls
```

#### # Change drive letter for DVD-ROM

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
```

#### Configure separate VHDs for file shares

---

**TT-ADMIN04** - Run as administrator

```PowerShell
cls
```

##### # Add disk for data

```PowerShell
$vmHost = "TT-HV05E"
$vmName = "TT-FS01C"

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 600GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path $vhdPath `
    -ControllerType SCSI

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Data02.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 600GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path $vhdPath `
    -ControllerType SCSI

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Data03.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Dynamic -SizeBytes 200GB
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

##### # Initialize disks and format volumes

```PowerShell
Get-Disk 1 |
    Initialize-Disk -PartitionStyle GPT -PassThru |
    New-Partition -UseMaximumSize -DriveLetter D |
    Format-Volume `
        -FileSystem NTFS `
        -NewFileSystemLabel "Data01" `
        -Confirm:$false

Get-Disk 2 |
    Initialize-Disk -PartitionStyle GPT -PassThru |
    New-Partition -UseMaximumSize -DriveLetter E |
    Format-Volume `
        -FileSystem NTFS `
        -NewFileSystemLabel "Data02" `
        -Confirm:$false

Get-Disk 3 |
    Initialize-Disk -PartitionStyle GPT -PassThru |
    New-Partition -UseMaximumSize -DriveLetter F |
    Format-Volume `
        -FileSystem NTFS `
        -NewFileSystemLabel "Data03" `
        -Confirm:$false
```

```PowerShell
cls
```

## # Deploy file server

### # Add roles for File and Storage Services

```PowerShell
Install-WindowsFeature `
    -Name FS-FileServer, FS-Resource-Manager `
    -IncludeManagementTools `
    -Restart
```

```PowerShell
cls
```

## # Migrate file shares

### # Copy content from old file server (TT-FS01)

```PowerShell
robocopy '\\TT-FS01\D$\Shares' D:\Shares /B /COPYALL /NP /E /MIR /SL
```

> **Note**
>
> **D:\Shares\Products\Drivers** contains symbolic links to share installation
> files for various hardware.
>
> For example:
>
> dir /AL /S
>
> ...
>
> Directory of D:\Shares\Products\Drivers\Intel\Network\82579LM\Windows 10
>
> ... `<SYMLINK`> PROWinx64.exe [..\..\Windows 10\PROWinx64.exe]
>
> Directory of D:\Shares\Products\Drivers\Intel\Network\I217-V\Windows 10
>
> ... `<SYMLINK`> PROWinx64.exe [..\..\Windows 10\PROWinx64.exe]

```PowerShell
robocopy '\\TT-FS01\E$\Shares' E:\Shares /B /COPYALL /NP /E /MIR

robocopy '\\TT-FS01\F$\Shares' F:\Shares /B /COPYALL /NP /E /MIR
```

```PowerShell
cls
```

### # Create file shares

#### # Create file shares for user profiles and home directories (with offline files enabled)

```PowerShell
New-SmbShare `
    -Name Profiles$ `
    -Path E:\Shares\Profiles$ `
    -CachingMode Manual `
    -FullAccess "Roaming User Profiles Users and Computers"

New-SmbShare `
    -Name Users$ `
    -Path E:\Shares\Users$ `
    -CachingMode Manual `
    -FullAccess "Folder Redirection Users"
```

```PowerShell
cls
```

#### # Create remaining file shares (with offline files disabled)

```PowerShell
Get-ChildItem D:\Shares, E:\Shares, F:\Shares |
    where { $_.FullName -notin ('E:\Shares\Profiles$', 'E:\Shares\Users$') } |
    foreach {
        New-SmbShare `
            -Name $_.Name `
            -Path $_.FullName `
            -CachingMode None `
            -ChangeAccess "Authenticated Users"
    }
```

## Rename file servers (cutover)

---

**TT-ADMIN04** - Run as domain administrator

```PowerShell
cls
```

### # Rename old file server

```PowerShell
Rename-Computer -NewName TT-FS01-OLD -ComputerName TT-FS01 -Restart
```

> **Note**
>
> Wait for the VM to restart.

```PowerShell
cls
```

### # Rename new file server

```PowerShell
Rename-Computer -NewName TT-FS01 -ComputerName TT-FS01C -Restart
```

> **Note**
>
> Wait for the VM to restart.

---

## # Configure monitoring

### # Install SCOM agent

```PowerShell
$msiPath = "\\TT-FS01\Products\Microsoft\System Center 2019\SCOM\agent\AMD64" `
    + "\MOMAgent.msi"

msiexec.exe /i $msiPath `
    MANAGEMENT_GROUP=HQ `
    MANAGEMENT_SERVER_DNS=TT-SCOM01C `
    ACTIONS_USE_COMPUTER_ACCOUNT=1
```

### Approve manual agent install in Operations Manager

```PowerShell
cls
```

## # Configure backup

### # Install DPM agent

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\System Center 2019" `
    + "\DPM\Agents\DPMAgentInstaller_x64.exe"

$installerArguments = "TT-DPM06.corp.technologytoolbox.com"

Start-Process `
    -FilePath $installerPath `
    -ArgumentList "$installerArguments" `
    -Wait
```

Review the licensing agreement. If you accept the Microsoft Software License
Terms, click **Accept**.

Confirm the agent installation completed successfully and the following firewall
exceptions have been added:

- Exception for DPMRA.exe in all profiles
- Exception for Windows Management Instrumentation service
- Exception for RemoteAdmin service
- Exception for DCOM communication on port 135 (TCP and UDP) in all profiles

#### Reference

**Installing Protection Agents Manually**\
Pasted from <[http://technet.microsoft.com/en-us/library/hh757789.aspx](http://technet.microsoft.com/en-us/library/hh757789.aspx)>

---

**TT-ADMIN04** - DPM Management Shell

```PowerShell
cls
```

### # Attach DPM agent

```PowerShell
$productionServer = 'TT-FS01'

.\Attach-ProductionServer.ps1 `
    -DPMServerName TT-DPM06 `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `
    -UserName jjameson-admin
```

---

### Add volumes to protection group in DPM

```PowerShell
cls
```

### # Configure antivirus on DPM protected server

#### # Disable real-time monitoring by Windows Defender for DPM server

```PowerShell
[array] $excludeProcesses = Get-MpPreference | select -ExpandProperty ExclusionProcess

$excludeProcesses +=
   "$env:ProgramFiles\Microsoft Data Protection Manager\DPM\bin\DPMRA.exe"

Set-MpPreference -ExclusionProcess $excludeProcesses
```

#### # Configure antivirus software to delete infected files

```PowerShell
Set-MpPreference -LowThreatDefaultAction Remove
Set-MpPreference -ModerateThreatDefaultAction Remove
Set-MpPreference -HighThreatDefaultAction Remove
Set-MpPreference -SevereThreatDefaultAction Remove
```

#### Reference

**Run antivirus software on the DPM server**\
From <[https://docs.microsoft.com/en-us/system-center/dpm/run-antivirus-server?view=sc-dpm-2019](https://docs.microsoft.com/en-us/system-center/dpm/run-antivirus-server?view=sc-dpm-2019)>

---

**TT-ADMIN04** - Run as administrator

```PowerShell
cls
```

## # Configure library server for Virtual Machine Manager (VMM)

### # Install VMM agent on file server

```PowerShell
$fileServer = "tt-fs01.corp.technologytoolbox.com"

$credential = Get-Credential "TECHTOOLBOX\jjameson-admin"

Add-SCLibraryServer -ComputerName $fileServer -Credential $credential
```

## # Add file share to VMM library

```PowerShell
$sharePath = "\\tt-fs01.corp.technologytoolbox.com\Products"

Add-SCLibraryShare -SharePath $sharePath -UseAlternateDataStream $true
```

---

**TODO:**

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

```PowerShell
slmgr /ato
```

# TT-FS01 - Windows Server 2016

Saturday, January 21, 2017
7:37 AM

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
$vmHost = "TT-HV02C"
$vmName = "TT-FS01"
$vmPath = "E:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"
$sysPrepedImage = "\\ICEMAN\VMM-Library\VHDs\WS2016-Std-Core.vhdx"

$vhdUncPath = $vhdPath.Replace("E:", "\\TT-HV02C\E$")

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
    -MemoryMinimumBytes 2GB

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Set password for the local Administrator account

```Console
PowerShell
```

```Console
cls
```

### # Rename local Administrator account

```PowerShell
$adminUser = [ADSI] 'WinNT://./Administrator,User'

$adminUser.Rename('foo')

logoff
```

### Rename server and join domain

#### Login as local administrator account

```Console
PowerShell
```

```Console
cls
```

### # Rename server

```PowerShell
Rename-Computer -NewName TT-FS01 -Restart
```

> **Note**
>
> Wait for the VM to restart.

#### Login as local administrator account

```Console
PowerShell
```

```Console
cls
```

### # Join server to domain

```PowerShell
Add-Computer -DomainName corp.technologytoolbox.com -Restart
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Move computer to different OU

```PowerShell
$vmName = "TT-FS01"

$targetPath = ("OU=Storage Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

---

```Console
PowerShell
```

```Console
cls
```

### # Set time zone

```PowerShell
tzutil /s "Mountain Standard Time"
```

### # Copy Toolbox content

```PowerShell
$source = "\\ICEMAN\Public\Toolbox"
$destination = "C:\NotBackedUp\Public\Toolbox"

robocopy $source $destination  /E /XD "Microsoft SDKs"
```

### # Set MaxPatchCacheSize to 0 (recommended)

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

```PowerShell
cls
```

### # Configure networking

#### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "Management"
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name "Management" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

ping ICEMAN -f -l 8900
```

```PowerShell
cls
```

## # Configure storage

### # Change drive letter for DVD-ROM

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

### # Add disks for file storage (Data01 and Data02)

```PowerShell
$vmHost = "TT-HV02C"
$vmName = "TT-FS01"

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 600GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path $vhdPath `
    -ControllerType SCSI

$vhdPath = "F:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Data02.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 600GB
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
        -FileSystem ReFS `
        -NewFileSystemLabel "Data01" `
        -Confirm:$false

Get-Disk 2 |
    Initialize-Disk -PartitionStyle GPT -PassThru |
    New-Partition -UseMaximumSize -DriveLetter E |
    Format-Volume `
        -FileSystem ReFS `
        -NewFileSystemLabel "Data02" `
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

### # Copy content from ICEMAN

```PowerShell
robocopy '\\ICEMAN\E$\Shares' D:\Shares /COPYALL /NP /E /MIR `
    /XD Archive Backups Builds Profiles`$ Public Users`$ Witness`$

robocopy '\\ICEMAN\E$\Shares' E:\Shares /COPYALL /NP /E /MIR `
    /XD MDT-Build`$ MDT-Deploy`$ Profiles`$ Products Profiles$ Temp Users`$ VM-Library VMM-Library Witness`$ WSUS`$
```

### # Create file shares

```PowerShell
Get-ChildItem D:\Shares, E:\Shares |
    % {
    New-SmbShare `
        -Name $_.Name `
        -Path $_.FullName `
        -CachingMode None `
        -ChangeAccess Everyone
}
```

### Change the location for WSUS content

---

**COLOSSUS**

```Console
cd "C:\Program Files\Update Services\Tools"
.\WsusUtil.exe movecontent '\\TT-FS01\WSUS$' C:\move.log -skipcopy
```

---

#### Reference

**Changing the Location where You Store Update Files Locally**\
From <[https://technet.microsoft.com/en-us/library/cc708480(v=ws.10).aspx#Anchor_1](https://technet.microsoft.com/en-us/library/cc708480(v=ws.10).aspx#Anchor_1)>

## Install DPM agent

```Console
PowerShell
```

### # Install DPM 2016 agent

```PowerShell
$installer = "\\TT-FS01\Products\Microsoft\System Center 2016" `
    + "\Agents\DPMAgentInstaller_x64.exe"

& $installer TT-DPM01.corp.technologytoolbox.com
```

### Attach DPM agent

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

## Issue: VM is very sluggish when many files are being copied

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Increase minimum memory for virtual machine

```PowerShell
$vmHost = "TT-HV02C"
$vmName = "TT-FS01"

Stop-VM -ComputerName $vmHost -Name $vmName

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -MemoryMinimumBytes 2GB

Start-VM -ComputerName $vmHost -Name $vmName
```

---

## Issue: SMB Multichannel not working across Hyper-V cluster nodes

---

**TT-VMM01A**

```PowerShell
cls
```

### # Add a second network adapter for SMB Multichannel

```PowerShell
$vmName = "TT-FS01"
$portClassification = Get-SCPortClassification -Name "SMB workload"
$vmNetwork = Get-SCVMNetwork -Name "Storage VM Network"
$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"
$ipPool = Get-SCStaticIPAddressPool -Name "Storage Address Pool"

Stop-SCVirtualMachine -VM $vmName

$networkAdapter = New-SCVirtualNetworkAdapter `
    -VM $vmName `
    -PortClassification $portClassification `
    -Synthetic
```

### # Configure static IP address using VMM

```PowerShell
$macAddress = Grant-SCMACAddress `
    -MACAddressPool $macAddressPool `
    -Description $vmName `
    -VirtualNetworkAdapter $networkAdapter

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -MACAddressType Static `
    -MACAddress $macAddress

$ipAddress = Grant-SCIPAddress `
    -GrantToObjectType VirtualNetworkAdapter `
    -GrantToObjectID $networkAdapter.ID `
    -StaticIPAddressPool $ipPool `
    -Description $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -IPv4AddressType Static `
    -IPv4Addresses $IPAddress.Address

Start-SCVirtualMachine $vmName
```

---

```PowerShell
cls
```

### # Configure networking

```PowerShell
$interfaceAlias = "Storage"
```

#### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter #3" |
    Rename-NetAdapter -NewName $interfaceAlias
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

ping 10.1.10.25 -f -l 8900
```

---

**TT-VMM01B**

## # Assign static IP address

```PowerShell
$vm = Get-SCVirtualMachine TT-FS01

Stop-SCVirtualMachine $vm

$networkAdapter =  Get-SCVirtualNetworkAdapter -VM $vm |
    ? { $_.SlotId -eq 0 }

$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"

$ipAddressPool = Get-SCStaticIPAddressPool -Name "Management Address Pool"

$macAddress = Grant-SCMACAddress `
    -MACAddressPool $macAddressPool `
    -Description $vm.Name `
    -VirtualNetworkAdapter $networkAdapter

$ipAddress = Grant-SCIPAddress `
    -GrantToObjectType VirtualNetworkAdapter `
    -GrantToObjectID $networkAdapter.ID `
    -StaticIPAddressPool $ipAddressPool `
    -Description $vm.Name

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -MACAddressType Static `
    -MACAddress $macAddress `
    -IPv4AddressType Static `
    -IPv4Address $ipAddress

Start-SCVirtualMachine $vm
```

---

## Issue - Incorrect IPv6 DNS server assigned by Comcast router

```Text
PS C:\Users\jjameson-admin> nslookup
Default Server:  cdns01.comcast.net
Address:  2001:558:feed::1
```

> **Note**
>
> Even after reconfiguring the **Primary DNS** and **Secondary DNS** settings on the Comcast router -- and subsequently restarting the VM -- the incorrect DNS server is assigned to the network adapter.

### Solution

```PowerShell
Set-DnsClientServerAddress `
    -InterfaceAlias Management `
    -ServerAddresses 2603:300b:802:8900::103, 2603:300b:802:8900::104

Restart-Computer
```

## Rebuild DPM 2016 server (replace TT-DPM01 with TT-DPM02)

### # Remove DPM agent

```PowerShell
MsiExec.exe /X "{14DD5B44-17CE-4E89-8BEB-2E6536B81B35}"
```

> **Note**
>
> The command to remove the DPM agent can be obtained from the following PowerShell:
>
> ```PowerShell
> Get-ChildItem HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall |
>     Get-ItemProperty |
>     where { $_.DisplayName -eq 'Microsoft System Center 2016  DPM Protection Agent' } |
>     select UninstallString
> ```

Restart the server to complete the removal.

```PowerShell
Restart-Computer
```

> **Note**
>
> Wait for the computer to restart.

```Console
PowerShell
```

### # Install DPM agent

```PowerShell
$installer = "\\TT-FS01\Products\Microsoft\System Center 2016" `
    + "\DPM\Agents\DPMAgentInstaller_x64.exe"

& $installer TT-DPM02.corp.technologytoolbox.com
```

---

**TT-DPM02 - DPM Management Shell**

```PowerShell
cls
```

### # Attach DPM agent

```PowerShell
$productionServer = 'TT-FS01'

.\Attach-ProductionServer.ps1 `
    -DPMServerName TT-DPM02 `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `
    -UserName jjameson-admin
```

---

## Issue - Disk full (D:)

---

**FOOBAR10**

```PowerShell
cls
```

### # Add disk for file storage (Data03)

```PowerShell
$vmHost = "TT-HV02C"
$vmName = "TT-FS01"

$vhdPath = "D:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Data03.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 200GB
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

### # Initialize disk and format volume

```PowerShell
Get-Disk 3 |
    Initialize-Disk -PartitionStyle GPT -PassThru |
    New-Partition -UseMaximumSize -DriveLetter F |
    Format-Volume `
        -FileSystem ReFS `
        -NewFileSystemLabel "Data03" `
        -Confirm:$false
```

```PowerShell
cls
```

### # Copy files to new volume

```PowerShell
robocopy D:\Shares\VM-Library F:\Shares\VM-Library /COPYALL /NP /E
```

> **Note**
>
> Warnings are displayed when using the /COPYALL option (to copy permissions) because the volumes are formatted using ReFS (not NTFS). However, after checking the permissions on the files afterwards, the permissions were found to be copied as expected.This was further confirmed by the following PowerShell:
>
> ```Console
> icacls D:\Shares\VM-Library /save C:\NotBackedUp\Temp\tmp.txt /T
> icacls F:\Shares\VM-Library /save C:\NotBackedUp\Temp\tmp2.txt /T
> Get-FileHash -Algorithm SHA1 C:\NotBackedUp\Temp\tmp*.txt | select Hash, Path
>
> Hash                                     Path
> ----                                     ----
> F131F41B8B39ABCDB5194BFC40BA6E34F056270B C:\NotBackedUp\Temp\tmp.txt
> F131F41B8B39ABCDB5194BFC40BA6E34F056270B C:\NotBackedUp\Temp\tmp2.txt
> ```

```PowerShell
cls
```

### # Compare files to ensure identical copies

```PowerShell
$LeftFolder = "D:\Shares\VM-Library"
$RightFolder = "F:\Shares\VM-Library"

$LeftSideHash = Get-ChildItem $LeftFolder -Recurse |
    Get-FileHash |
    select @{Label="Path";Expression={$_.Path.Replace($LeftFolder,"")}},Hash

$RightSideHash = Get-ChildItem $RightFolder -Recurse |
    Get-FileHash |
    select @{Label="Path";Expression={$_.Path.Replace($RightFolder,"")}},Hash

Compare-Object $LeftSideHash $RightSideHash -Property Path,Hash
```

#### Reference

**Compare contents of two folders using PowerShell Get-FileHash**\
From <[http://almoselhy.azurewebsites.net/2014/12/compare-contents-of-two-folders-using-powershell-get-filehash/](http://almoselhy.azurewebsites.net/2014/12/compare-contents-of-two-folders-using-powershell-get-filehash/)>

```PowerShell
cls
```

### # Recreate file share

```PowerShell
Get-SmbShare -Name VM-Library | Remove-SmbShare -Confirm:$false

Get-ChildItem F:\Shares |
    foreach {
    New-SmbShare `
        -Name $_.Name `
        -Path $_.FullName `
        -CachingMode None `
        -ChangeAccess Everyone
}
```

### # Remove old copies of files

```PowerShell
Remove-Item D:\Shares\VM-Library -Recurse
```

### Add new volume to DPM protection group

Protection Group: Critical Files\
Computer: TT-FS01\
Volume: F:\\

## Move file share to different drive

```PowerShell
$oldPath = "E:\Shares\Backups"
$newPath = "F:\Shares\Backups"
```

### # Copy files

```PowerShell
robocopy $oldPath $newPath /E /COPYALL
```

```PowerShell
cls
```

### # Change path for SMB share

```PowerShell
function Change-SharePath {
    [cmdletbinding(SupportsShouldProcess=$true)]
    param(
        $OldPath,
        $NewPath
    )

    $RegPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Shares'
    dir -Path $RegPath | Select-Object -ExpandProperty Property | ForEach-Object {
        $ShareName = $_
        $ShareData = Get-ItemProperty -Path $RegPath -Name $ShareName |
            Select-Object -ExpandProperty $ShareName

        if ($ShareData | Where-Object { $_ -eq  "Path=$OldPath"}) {
            $ShareData = $ShareData -replace [regex]::Escape("Path=$OldPath"), "Path=$NewPath"

            if ($PSCmdlet.ShouldProcess($ShareName, 'Change-SharePath')) {
                Set-ItemProperty -Path $RegPath -Name $ShareName -Value $ShareData
            }
        }
    }
}

Change-SharePath -OldPath $oldPath -NewPath $newPath -Verbose
```

```PowerShell
cls
```

### # Restart "Server" service

```PowerShell
Restart-Service -Name lanmanserver
```

### Reference

**Changing Shared Folders’ Path**\
From <[https://blogs.technet.microsoft.com/pstips/2014/12/21/changing-shared-folders-path/](https://blogs.technet.microsoft.com/pstips/2014/12/21/changing-shared-folders-path/)>

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Move VM to new Production VM network

```PowerShell
$vmName = "TT-FS01"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Production VM Network"
$ipPool = Get-SCStaticIPAddressPool -Name "Production-15 Address Pool"

Stop-SCVirtualMachine $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -IPv4AddressPools $ipPool `
    -IPv4AddressType Static

Start-SCVirtualMachine $vmName
```

---

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Move VM to new Management VM network

```PowerShell
$vmName = "TT-FS01"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Management VM Network"
$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"
$ipAddressPool = Get-SCStaticIPAddressPool -Name "Management-30 Address Pool"

Stop-SCVirtualMachine $vmName

$macAddress = Grant-SCMACAddress `
    -MACAddressPool $macAddressPool `
    -Description $vmName `
    -VirtualNetworkAdapter $networkAdapter

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -MACAddressType Static `
    -MACAddress $macAddress `
    -IPv4AddressPools $ipAddressPool `
    -IPv4AddressType Static

Start-SCVirtualMachine $vmName
```

---

```PowerShell
cls
```

## # Configure monitoring

### # Install Operations Manager agent

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\System Center 2016\SCOM\Agent\AMD64" `
    + "\MOMAgent.msi"

$installerArguments = "MANAGEMENT_GROUP=HQ" `
    + " MANAGEMENT_SERVER_DNS=TT-SCOM03" `
    + " ACTIONS_USE_COMPUTER_ACCOUNT=1"

Start-Process `
    -FilePath msiexec.exe `
    -ArgumentList "/i `"$installerPath`" $installerArguments" `
    -Wait
```

### Approve manual agent install in Operations Manager

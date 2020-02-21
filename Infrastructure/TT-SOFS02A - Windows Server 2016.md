# TT-SOFS02A - Windows Server 2016

Wednesday, February 28, 2018
6:04 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create failover cluster objects in Active Directory

#### # Create cluster object for SOFS failover cluster and delegate permission to create the cluster to any member of the fabric administrators group

```PowerShell
$failoverClusterName = "TT-SOFS02-FC"
$delegate = "Fabric Admins"
$orgUnit = "OU=Storage Servers,OU=Servers,OU=Resources,OU=IT," `
    + "DC=corp,DC=technologytoolbox,DC=com"

C:\NotBackedUp\Public\Toolbox\PowerShell\New-ClusterObject.ps1 `
    -Name $failoverClusterName  `
    -Delegate $delegate `
    -Path $orgUnit

# HACK: Wait a few seconds to avoid issue where the cluster object just created is not found when delegating permission

Start-Sleep -Seconds 5
```

#### # Create failover cluster name for VMM service and delegate permission to create the cluster name to the failover cluster service (TT-VMM01-FC\$)

```PowerShell
$failoverClusterName = "TT-SOFS02"
$delegate = "TT-SOFS02-FC$"
$description = "Failover cluster name for Scale-Out File Server"

C:\NotBackedUp\Public\Toolbox\PowerShell\New-ClusterObject.ps1 `
    -Name $failoverClusterName  `
    -Delegate $delegate `
    -Description $description `
    -Path $orgUnit
```

---

---

**FOOBAR11- Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV02A"
$vmName = "TT-SOFS02A"
$vmPath = "F:\NotBackedUp\VMs"
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
    -DynamicMemory `
    -MemoryMinimumBytes 2GB `
    -MemoryMaximumBytes 4GB `
    -ProcessorCount 2

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
```

---

**TT-HV02A - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Mount ISO image for Windows Server 2016

```PowerShell
$vmName = "TT-SOFS02A"

$isoPath = "\\TT-FS01\Products\Microsoft\Windows Server 2016" `
    + "\en_windows_server_2016_x64_dvd_9718492.iso"

Set-VMDvdDrive `
    -VMName $vmName `
    -Path $isoPath
```

---

```PowerShell
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
Rename-Computer -NewName TT-SOFS02A -Restart
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

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls

$vmName = "TT-SOFS02A"
```

### # Move computer to different OU

```PowerShell
$targetPath = ("OU=Storage Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

### # Add fabric administrators domain group to local Administrators group on file servers

```PowerShell
$command = 'net localgroup Administrators "TECHTOOLBOX\Fabric Admins" /ADD'

$scriptBlock = [ScriptBlock]::Create($command)

Invoke-Command -ComputerName $vmName -ScriptBlock $scriptBlock
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
$source = "\\TT-FS01\Public\Toolbox"
$destination = "C:\NotBackedUp\Public\Toolbox"

robocopy $source $destination  /E /XD "Microsoft SDKs" /NP
```

### # Set MaxPatchCacheSize to 0 (recommended)

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

## Configure networking

### Login as fabric administrator

```Console
PowerShell
```

```Console
cls
```

### # Configure network settings

```PowerShell
$interfaceAlias = "Management"
```

#### # Rename network connection

```PowerShell
Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

Start-Sleep -Seconds 15

ping TT-FS01 -f -l 8900
```

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Set port classification on management network adapter

```PowerShell
$vmName = "TT-SOFS02A"

$vm = Get-SCVirtualMachine $vmName

$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vm

$portClassification = Get-SCPortClassification -Name "Host management"

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -PortClassification $PortClassification
```

#### # Add network adapter for SMB (SOFS) traffic

```PowerShell
Stop-SCVirtualMachine -VM $vm
```

##### # Add network adapter for SMB traffic

```PowerShell
$vmNetwork = Get-SCVMNetwork -Name "Storage VM Network"

$vmSubnet = $vmNetwork.VMSubnet[0]

$portClassification = Get-SCPortClassification -Name "SMB workload"

$networkAdapter = New-SCVirtualNetworkAdapter `
    -VirtualNetwork "Embedded Team Switch" `
    -PortClassification $portClassification `
    -Synthetic `
    -VM $vm `
    -VMNetwork $vmNetwork `
    -VMSubnet $vmSubnet
```

##### # Assign static IP address to network adapter for SMB traffic

```PowerShell
$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"

$ipAddressPool = Get-SCStaticIPAddressPool -Name "Storage Address Pool"

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
```

#### # Restart VM

```PowerShell
Start-SCVirtualMachine -VM $vm
```

---

#### Login as fabric adminstrator

```Console
PowerShell
```

```Console
cls
```

### # Configure SMB storage network adapter

```PowerShell
$interfaceAlias = "Storage"
```

#### # Rename network connection

```PowerShell
$networkAdapter = Get-NetAdapter -Physical |
    ? { $_.LinkSpeed -eq "2 Gbps" -and $_.Name -ne "Management" }

$networkAdapter | Rename-NetAdapter -NewName $interfaceAlias
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping 10.1.10.56 -f -l 8900
```

### Configure storage

> **Note**
>
> Storage Spaces Direct requires a minimum of 3 physical disks:\
> **Error 51001 with Storage Spaces Direct**\
> From <[http://www.oneblogpost.co.uk/2016/10/17/error-51001-with-storage-spaces-direct/](http://www.oneblogpost.co.uk/2016/10/17/error-51001-with-storage-spaces-direct/)>
>
> ...or is it 4 physical disks?
>
> **Storage Spaces Direct hardware requirements**\
> From <[https://docs.microsoft.com/en-us/windows-server/storage/storage-spaces/storage-spaces-direct-hardware-requirements](https://docs.microsoft.com/en-us/windows-server/storage/storage-spaces/storage-spaces-direct-hardware-requirements)>
>
> For this cluster, 4 "physical" disks are used.

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 32 GB       | 4K                   | OSDisk       |
| 1    |              | 500 GB      |                      |              |
| 2    |              | 500 GB      |                      |              |
| 3    |              | 500 GB      |                      |              |
| 4    |              | 500 GB      |                      |              |

---

**FOOBAR11- Run as administrator**

```PowerShell
cls

$vmHost = "TT-HV02A"
$vmName = "TT-SOFS02A"
```

#### # Remove DVD drive from virtual machine

```PowerShell
Get-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName |
    Remove-VMDvdDrive
```

#### # Add disk for storage pool (Data01)

```PowerShell
$vhdPath = "F:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 500GB -Fixed

Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path $vhdPath `
    -ControllerType SCSI
```

#### # Add disk for storage pool (Data02)

```PowerShell
$vhdPath = "F:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Data02.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 500GB -Fixed

Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path $vhdPath `
    -ControllerType SCSI
```

#### # Add disk for storage pool (Data03)

```PowerShell
$vhdPath = "F:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Data03.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 500GB -Fixed

Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path $vhdPath `
    -ControllerType SCSI
```

#### # Add disk for storage pool (Data04)

```PowerShell
$vhdPath = "F:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Data04.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 500GB -Fixed

Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path $vhdPath `
    -ControllerType SCSI
```

---

## Deploy Storage Spaces Direct

**Hyper-converged solution using Storage Spaces Direct in Windows Server 2016**\
From <[https://docs.microsoft.com/en-us/windows-server/storage/storage-spaces/hyper-converged-solution-using-storage-spaces-direct#step-1-deploy-windows-server](https://docs.microsoft.com/en-us/windows-server/storage/storage-spaces/hyper-converged-solution-using-storage-spaces-direct#step-1-deploy-windows-server)>

```PowerShell
cls
```

### # Install role services and features

```PowerShell
Install-WindowsFeature `
    -Name Failover-Clustering `
    -IncludeManagementTools `
    -Restart
```

```PowerShell
cls
```

### # Run all cluster validation tests

```PowerShell
Test-Cluster `
    -Node TT-SOFS02A `
    -Include "Storage Spaces Direct", "Inventory", "Network", "System Configuration"
```

> **Note**
>
> Wait for the cluster validation tests to complete.

### # Review cluster validation report

```PowerShell
$source = "$env:TEMP\Validation Report 2018.02.28 At 12.17.29.htm"
$destination = "\\TT-FS01\Public"

Copy-Item $source $destination
```

---

**WOLVERINE**

```PowerShell
cls
& "\\TT-FS01\Public\Validation Report 2018.02.28 At 12.17.29.htm"
```

---

```PowerShell
cls
```

### # Create cluster

```PowerShell
New-Cluster -Name TT-SOFS02-FC -Node TT-SOFS02A

Name
----
TT-SOFS02-FC
```

```PowerShell
cls
```

### # Enable Storage Spaces Direct

```PowerShell
Enable-ClusterStorageSpacesDirect

WARNING: 2018/02/28-13:08:12.860 Node TT-SOFS02A: No disks found to be used for cache
WARNING: 2018/02/28-13:08:12.876 C:\Windows\Cluster\Reports\Enable-ClusterS2D on 2018.02.28-13.08.12.860.htm
```

```PowerShell
cls
```

#### # Check media type configuration

```PowerShell
Get-StoragePool "S2D on TT-SOFS02-FC" |
    Get-PhysicalDisk |
    Sort Size |
    ft FriendlyName, Size, MediaType, HealthStatus, OperationalStatus -AutoSize
```

```PowerShell
cls
```

#### # Change fault domain awareness (required for single node cluster)

```PowerShell
Set-StoragePool `
    -FriendlyName "S2D on TT-SOFS02-FC" `
    -FaultDomainAwarenessDefault PhysicalDisk
```

**Deploying Storage Spaces Direct on a Single Node SOFS Cluster**\
From <[https://www.danielstechblog.info/deploying-storage-spaces-direct-on-a-single-node-sofs-cluster/](https://www.danielstechblog.info/deploying-storage-spaces-direct-on-a-single-node-sofs-cluster/)>

```PowerShell
cls
```

#### # Create cluster shared volume

```PowerShell
New-Volume `
    -FriendlyName "Volume1" `
    -FileSystem CSVFS_ReFS `
    -StoragePoolFriendlyName S2D* `
    -UseMaximumSize `
    -ResiliencySettingName Parity
```

```PowerShell
cls
```

## # Configure Scale-Out File Server

### # Install role services and features

```PowerShell
Install-WindowsFeature `
    -Name File-Services `
    -IncludeManagementTools `
    -Restart
```

```PowerShell
cls
```

### # Create cluster role

```PowerShell
Add-ClusterScaleOutFileServerRole -Name TT-SOFS02
```

### # Create continuously available file share on the cluster shared volume

#### # Create folder

```PowerShell
$folderName = "VM-Storage-Bronze"
$path = "C:\ClusterStorage\Volume1\Shares\$folderName"

New-Item -Path $path -ItemType Directory
```

#### # Remove "BUILTIN\\Users" and "Everyone" permissions

```PowerShell
icacls $path /inheritance:d
icacls $path /remove:g "BUILTIN\Users"
icacls $path /remove:g "Everyone"
```

#### # Share folder

```PowerShell
New-SmbShare `
    -Name $folderName `
    -Path $path `
    -Caching None `
    -FullAccess Everyone
```

#### # Grant permissions for fabric administrators

```PowerShell
icacls $path /grant '"Fabric Admins":(OI)(CI)(RX)'
```

#### # Grant permissions for VMM management account

```PowerShell
icacls $path /grant '"s-vmm01-mgmt":(OI)(CI)(F)'
```

#### # Grant permissions for Hyper-V servers

```PowerShell
icacls $path /grant 'Hyper-V Servers:(OI)(CI)(F)'

icacls $path /grant 'TT-HV02A$:(OI)(CI)(F)'
icacls $path /grant 'TT-HV02B$:(OI)(CI)(F)'
icacls $path /grant 'TT-HV02C$:(OI)(CI)(F)'
```

### Enable CSV cache

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Increase RAM on cluster nodes

```PowerShell
cls
```

##### # Increase RAM on node "A"

```PowerShell
$vmHost = "TT-HV02A"
$vmName = "TT-SOFS02A"

Stop-VM -ComputerName $vmHost -Name $vmName

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -StaticMemory `
    -MemoryStartupBytes 4GB

Start-VM -ComputerName $vmHost -Name $vmName
```

```PowerShell
cls
```

#### # Configure CSV cache

```PowerShell
(Get-Cluster TT-SOFS02-FC).BlockCacheSize = 1024
```

```PowerShell
cls
```

#### # Restart cluster nodes

##### # Restart node "A"

```PowerShell
$vmHost = "TT-HV02A"
$vmName = "TT-SOFS02A"

Restart-VM -ComputerName $vmHost -Name $vmName
```

---

```PowerShell
cls
```

### # Benchmark storage performance

#### # Create temporary drive mapping for testing

```PowerShell
net use D: \\TT-SOFS02\VM-Storage-Bronze

& 'C:\NotBackedUp\Public\Toolbox\ATTO Disk Benchmark\Bench32.exe'
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BD/13D161AF443F54248815CBCCEBA1C203EADA55BD.png)

Screen clipping taken: 2/28/2018 3:18 PM

```PowerShell
cls
```

#### # Remove temporary drive mapping for testing

```PowerShell
net use D: /delete
```

## Configure file share in VMM

### Reference

**How to Add Windows File Server Shares in VMM**\
From <[https://technet.microsoft.com/en-us/library/jj860437(v=sc.12).aspx](https://technet.microsoft.com/en-us/library/jj860437(v=sc.12).aspx)>

### Create Run As Account for "VMM management" service account

(previously completed for TT-SOFS01)

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Add "VMM management" service account to Administrators group on SOFS nodes

```PowerShell
$command = "net localgroup Administrators TECHTOOLBOX\s-vmm01-mgmt /ADD"

$scriptBlock = [ScriptBlock]::Create($command)

@("TT-SOFS02A") |
    ForEach-Object {
        Invoke-Command -ComputerName $_ -ScriptBlock $scriptBlock
    }
```

```PowerShell
cls
```

### # Add file servers

```PowerShell
$runAsAccount = Get-SCRunAsAccount `
    -Name "Service account for VMM - Management (TT-VMM01)"
```

#### # Add Scale-Out File Server (TT-SOFS02)

```PowerShell
Add-SCStorageProvider `
    -ComputerName "TT-SOFS02-FC.corp.technologytoolbox.com" `
    -AddWindowsNativeWmiProvider `
    -Name "TT-SOFS02.corp.technologytoolbox.com" `
    -RunAsAccount $runAsAccount

Get-SCStorageArray -Name "Clustered Windows Storage on TT-SOFS02-FC" |
    Set-SCStorageArray -DiscoverPhysicalDisks
```

```PowerShell
cls
```

#### # Install VMM agent on SOFS nodes

```PowerShell
$fileServer = Get-SCStorageFileServer `
    -Name 'TT-SOFS02.corp.technologytoolbox.com'

$nodes = @("TT-SOFS02A.corp.technologytoolbox.com")

Set-SCStorageFileServer `
    -StorageFileServer $fileServer `
    -AddExistingComputer $nodes

WARNING: The Set-SCStorageFileServer cmdlet parameter sets for adding and removing scale-out file server nodes have been deprecated. Please use the Install-SCStorageFileServer cmdlet for adding nodes and the Uninstall-SCStorageFileServer cmdlet for removing nodes.
```

```PowerShell
cls
```

### # Configure file share to be managed by VMM

#### # Configure "Bronze" VM storage

```PowerShell
$fileServer = Get-SCStorageFileServer `
    -Name 'TT-SOFS02.corp.technologytoolbox.com'

$fileShare = Get-SCStorageFileShare "VM-Storage-Bronze"

$storageClassification = Get-SCStorageClassification -Name "Bronze"

Set-SCStorageFileServer `
    -StorageFileServer $fileServer `
    -AddStorageFileShareToManagement $fileShare `
    -StorageClassificationAssociation $storageClassification
```

```PowerShell
cls
```

### # Make file share available to hosts

```PowerShell
$hostCluster = Get-SCVMHostCluster -Name "TT-HV02-FC"

$fileShare = Get-SCStorageFileShare "VM-Storage-Bronze"

Register-SCStorageFileShare `
    -StorageFileShare $fileShare `
    -VMHostCluster $hostCluster
```

---

```PowerShell
cls
```

## # Install DPM agent

### # Install DPM 2016 agent

```PowerShell
$installer = "\\TT-FS01\Products\Microsoft\System Center 2016" `
    + "\DPM\Agents\DPMAgentInstaller_x64.exe"

& $installer TT-DPM02.corp.technologytoolbox.com
```

Review the licensing agreement. If you accept the Microsoft Software License Terms, select **I accept the license terms and conditions**, and then click **OK**.

Confirm the agent installation completed successfully and the following firewall exceptions have been added:

- Exception for DPMRA.exe in all profiles
- Exception for Windows Management Instrumentation service
- Exception for RemoteAdmin service
- Exception for DCOM communication on port 135 (TCP and UDP) in all profiles

#### Reference

**Installing Protection Agents Manually**\
Pasted from <[http://technet.microsoft.com/en-us/library/hh757789.aspx](http://technet.microsoft.com/en-us/library/hh757789.aspx)>

---

**TT-DPM02 - DPM Management Shell**

```PowerShell
cls
```

### # Attach DPM agent

```PowerShell
$productionServer = 'TT-SOFS02A'

.\Attach-ProductionServer.ps1 `
    -DPMServerName TT-DPM02 `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `
    -UserName jjameson-admin
```

---

## Move virtual machines to new file share

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls

Function MoveVirtualMachineToBronzeStorage($vmName)
{
    Write-Host "Moving VM ($vmName)..."

    $stopwatch = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-Stopwatch.ps1

    $vm = Get-SCVirtualMachine -Name $vmName

    Move-SCVirtualMachine `
        -VM $vm `
        -VMHost $vm.HostName `
        -Path "\\TT-SOFS02.corp.technologytoolbox.com\VM-Storage-Bronze" `
        -UseLAN `
        -UseDiffDiskOptimization |
        select MostRecentTask, MostRecentTaskUIState

    $stopwatch.Stop()
    C:\NotBackedUp\Public\Toolbox\PowerShell\Write-ElapsedTime.ps1 $stopwatch
}

MoveVirtualMachineToBronzeStorage "CON-ADFS1"
MoveVirtualMachineToBronzeStorage "CON-DC2"
MoveVirtualMachineToBronzeStorage "CON-DC1"
MoveVirtualMachineToBronzeStorage "FAB-DC01"
MoveVirtualMachineToBronzeStorage "FAB-DC02"
MoveVirtualMachineToBronzeStorage "FAB-WEB01"
MoveVirtualMachineToBronzeStorage "BANSHEE"
MoveVirtualMachineToBronzeStorage "CIPHER01"
MoveVirtualMachineToBronzeStorage "CRYPTID"
MoveVirtualMachineToBronzeStorage "CYCLOPS"
MoveVirtualMachineToBronzeStorage "CYCLOPS-TEST"
MoveVirtualMachineToBronzeStorage "DAZZLER"
MoveVirtualMachineToBronzeStorage "EXT-DC04"
MoveVirtualMachineToBronzeStorage "EXT-DC05"
MoveVirtualMachineToBronzeStorage "EXT-RRAS1"
MoveVirtualMachineToBronzeStorage "EXT-WAC02A"
MoveVirtualMachineToBronzeStorage "FOOBAR7"
MoveVirtualMachineToBronzeStorage "FOOBAR11"
MoveVirtualMachineToBronzeStorage "HAVOK-TEST"
MoveVirtualMachineToBronzeStorage "MIMIC"
MoveVirtualMachineToBronzeStorage "POLARIS-TEST"
MoveVirtualMachineToBronzeStorage "TT-DEPLOY4"
MoveVirtualMachineToBronzeStorage "TT-SCOM01"
MoveVirtualMachineToBronzeStorage "USWVTFS006"
MoveVirtualMachineToBronzeStorage "USWVTFS007"
MoveVirtualMachineToBronzeStorage "USWVTFS008"
MoveVirtualMachineToBronzeStorage "EXT-SQL02"
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

```Console
slmgr /ato
```

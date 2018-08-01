# TT-VMM01B - Windows Server 2016 Standard Edition

Sunday, January 29, 2017
4:56 AM

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
$vmHost = "TT-HV02B"
$vmName = "TT-VMM01B"
$vmPath = "E:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 4GB `
    -SwitchName "Tenant vSwitch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 2 `
    -StaticMemory

Set-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path \\TT-FS01\Products\Microsoft\MDT-Deploy-x86.iso

Start-VM -ComputerName $vmHost -Name $vmName
```

---

## Install custom Windows Server 2016 image

- On the **Task Sequence** step, select **Windows Server 2016** and click **Next**.
- On the **Computer Details** step, in the **Computer name** box, type **TT-VMM01B** and click **Next**.
- On the **Applications** step, do not select any applications, and click **Next**.

```PowerShell
cls
```

## # Rename local Administrator account and set password

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

$password = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted for the secure string, type the password for the Administrator account.

```PowerShell
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

$adminUser = [ADSI] 'WinNT://./Administrator,User'
$adminUser.Rename('foo')
$adminUser.SetPassword($plainPassword)

logoff
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Remove disk from virtual CD/DVD drive

```PowerShell
$vmHost = "TT-HV02B"
$vmName = "TT-VMM01B"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

### # Move computer to "System Center Servers" OU

```PowerShell
$targetPath = ("OU=System Center Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath

Restart-VM -ComputerName $vmHost -VMName $vmName -Force
```

> **Important**
>
> Wait for the VM to restart before proceeding.

```PowerShell
cls
```

### # Add VMM administrators domain group to local Administrators group on VMM server

```PowerShell
$scriptBlock = {
    net localgroup Administrators "TECHTOOLBOX\VMM Admins" /ADD
}

Invoke-Command -ComputerName $vmName -ScriptBlock $scriptBlock
```

---

## Configure network settings

### Login as TECHTOOLBOX\\setup-vmm

### # Rename network connection

```PowerShell
$interfaceAlias = "Datacenter 1"

Get-NetAdapter -Physical

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping TT-FS01 -f -l 8900
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

```PowerShell
cls
```

## # Prepare server for VMM installation

### # Set MaxPatchCacheSize to 0 (Recommended)

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

### Configure failover clustering

---

**FOOBAR8**

```PowerShell
cls
```

#### # Add a second network adapter for cluster network

```PowerShell
$vmHost = "TT-HV02B"
$vmName = "TT-VMM01B"

Stop-VM -ComputerName $vmHost -Name $vmName

Add-VMNetworkAdapter -ComputerName $vmHost -VMName $vmName -SwitchName "Tenant vSwitch"

Start-VM -ComputerName $vmHost -Name $vmName
```

---

#### Login as TECHTOOLBOX\\setup-vmm

```PowerShell
cls
```

#### # Configure cluster network settings

```PowerShell
$interfaceAlias = "Cluster"
```

##### # Rename cluster network adapter

```PowerShell
Get-NetAdapter `
    -InterfaceDescription "Microsoft Hyper-V Network Adapter #2" |
    Rename-NetAdapter -NewName $interfaceAlias
```

##### # Disable DHCP and router discovery

```PowerShell
Set-NetIPInterface `
    -InterfaceAlias $interfaceAlias `
    -Dhcp Disabled `
    -RouterDiscovery Disabled
```

##### # Configure static IPv4 address

```PowerShell
$ipAddress = "172.16.1.2"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24
```

##### # Configure static IPv6 address

**# Note:** Private IPv6 address range (fd66:d7e2:39d6:a4d9::/64) generated by [http://simpledns.com/private-ipv6.aspx](http://simpledns.com/private-ipv6.aspx)

```PowerShell
$ipAddress = "fd66:d7e2:39d6:a4da::2"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 64
```

```PowerShell
cls
```

#### # Install Failover Clustering feature

```PowerShell
Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools
```

```PowerShell
cls
```

### # Install prerequisites for VMM Management Server

#### # Install Windows Assessment and Deployment Kit (Windows ADK) for Windows 10

```PowerShell
& "\\TT-FS01\Public\Download\Microsoft\Windows Kits\10\ADK\adksetup.exe"
```

1. On the **Specify Location** page, click **Next**.
2. On the **Windows Kits Privacy **page, click **Next**.
3. On the **License Agreement** page:
   1. Review the software license terms.
   2. If you agree to the terms, click **Accept**.
4. On the **Select the features you want to install **page:
   1. Select _only_ the following items:
      - **Deployment Tools**
      - **Windows Preinstallation Environment (Windows PE)**
   2. Click **Install**.

```PowerShell
cls
```

#### # Install SQL Server 2012 Native Client

```PowerShell
& "\\TT-FS01\Products\Microsoft\SQL Server 2012\Native Client\x64\sqlncli.msi"
```

```PowerShell
cls
```

#### # Install SQL Server 2012 Command Line Utilities

```PowerShell
& ("\\TT-FS01\Products\Microsoft\SQL Server 2012\Command Line Utilities\x64" `
    + "\SqlCmdLnUtils.msi")
```

#### Install updates

```PowerShell
cls
```

#### # Restart the server

```PowerShell
Restart-Computer
```

#### Login as TECHTOOLBOX\\setup-vmm

### # Add service account for Virtual Machine Manager to local Administrators group

```PowerShell
net localgroup Administrators TECHTOOLBOX\s-vmm01 /ADD
```

## Install VMM Management Server

---

**FOOBAR8**

```PowerShell
cls
```

### # Insert the VMM 2016 installation media

```PowerShell
$vmHost = "TT-HV02B"
$vmName = "TT-VMM01B"

$isoPath = "\\TT-FS01\Products\Microsoft\System Center 2016" `
    + "\mu_system_center_2016_virtual_machine_manager_x64_dvd_9368503.iso"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $isoPath
```

---

```PowerShell
cls
```

### # Extract VMM setup files

```PowerShell
X:\SC2016_SCVMM.EXE
```

Destination location: **C:\\NotBackedUp\\Temp\\System Center 2016 Virtual Machine Manager**

```PowerShell
cls
```

### # Install VMM Management Server on second cluster node

**To install a VMM management server on the second cluster node:**

1. To start the Virtual Machine Manager Setup Wizard, on your installation media, right-click **setup.exe**, and then click **Run as administrator**.
2. On the main setup page, click **Install**.
3. On the **Select features to install** page:
   1. Select the **VMM management server** check box.
   2. When prompted to add this server as a node to the VMM cluster, click **Yes**.
   3. Click **Next**.
4. On the **Product registration information** page, provide the appropriate information, and then click **Next**.
5. On the **Please read this license agreement** page, review the license agreement, select the **I have read, understood, and agree with the terms of the license agreement** check box, and then click **Next**.
6. On the **Diagnostic and Usage Data** page, review the data collection and usage policy and then click **Next**.
7. On the **Microsoft Update **page, select **On (recommended)** and then click **Next**.
8. On the **Installation location** page, ensure the default path is specified (**C:\\Program Files\\Microsoft System Center 2016\\Virtual Machine Manager**), and then click **Next**.
9. If all prerequisites have been met, the **Database configuration** page appears.
10. On the **Database configuration** page:
    1. Note that most of the information is read-only since it was specified when installing VMM on the first cluster node.
    2. If the account you are using to install the VMM management server does not have the appropriate permissions to connect to SQL Server, select the **Use the following credentials** check box, and then provide the user name and password of an account that has the appropriate permissions.
    3. Click **Next**.
11. On the **Configure service account and distributed key management** page, type the password for the VMM service account, and click **Next**.
12. On the **Port configuration** page:
    1. Note the information is read-only since it was specified when installing VMM on the first cluster node.
    2. Click **Next**.
13. On the **Library configuration** page, click **Next**.
14. On the **Installation summary** page, review your selections and do one of the following:
15. On the **Setup completed... **page:
    1. Review any warnings that occurred.
    2. Clear the **Open the VMM console when this wizard closes** checkbox.
    3. Click **Close** to finish the installation.

```PowerShell
    & "C:\NotBackedUp\Temp\System Center 2016 Virtual Machine Manager\setup.exe"
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8A/FF837C110E9EF96E119F361E55627A2C070D718A.png)

> **Note**
>
> The VMM console is automatically installed when you install a VMM management server.

- Click **Previous** to change any selections.
- Click **Install** to install the VMM management server.

After you click **Install**, the **Installing features** page appears and installation progress is displayed.

> **Note**
>
> If there is a problem with setup completing successfully, consult the log files in the **%SYSTEMDRIVE%\\ProgramData\\VMMLogs** folder. **ProgramData** is a hidden folder.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/06/DEE7172375DF301C89AB32698A91D6642A78AE06.png)

```PowerShell
cls
```

### # Remove temporary VMM setup files

```PowerShell
Remove-Item "C:\NotBackedUp\Temp\System Center 2016 Virtual Machine Manager" -Recurse
```

---

**TT-VMM01A**

## # Reconfigure "Cluster" network adapter

```PowerShell
$vm = Get-SCVirtualMachine TT-VMM01B

Stop-SCVirtualMachine $vm

$networkAdapter =  Get-SCVirtualNetworkAdapter -VM $vm |
    ? { $_.SlotId -eq 1 }
```

### # Connect network adapter to Cluster VM Network

```PowerShell
$vmNetwork = Get-SCVMNetwork -Name "Cluster VM Network"

$vmSubnet = $vmNetwork.VMSubnet[0]

$portClassification = Get-SCPortClassification -Name "Host Cluster Workload"

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VirtualNetwork "Embedded Team Switch" `
    -PortClassification $portClassification `
    -VMNetwork $vmNetwork `
    -VMSubnet $vmSubnet
```

### # Assign static IP address to network adapter for cluster traffic

```PowerShell
$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"

$ipAddressPool = Get-SCStaticIPAddressPool -Name "Cluster Address Pool"

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

```PowerShell
cls
```

## # Enter a product key and activate Windows

```PowerShell
slmgr /ipk {product key}
```

**Note:** When notified that the product key was set successfully, click **OK**.

```Console
slmgr /ato
```

```Console
cls
```

## # Install SCOM agent

```PowerShell
$imagePath = '\\TT-FS01\Products\Microsoft\System Center 2012 R2' `
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

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Move VM to new Production VM network

```PowerShell
$vmName = "TT-VMM01B"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName |
    where { $_.SlotId -eq 0 }

$vmNetwork = Get-SCVMNetwork -Name "Production VM Network"
$ipPool = Get-SCStaticIPAddressPool -Name "Production-15 Address Pool"

Stop-SCVirtualMachine $vmName

Start-Sleep -Seconds 60
```

> **Important**
>
> Verify the **TT-VMM01** cluster role fails over to **TT-VMM01A**.

```PowerShell
Read-SCVirtualMachine $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -MACAddressType Dynamic `
    -IPv4AddressType Dynamic

$vmNetwork = Get-SCVMNetwork -Name "Management VM Network"

$vm = Get-SCVirtualMachine $vmName

New-SCVirtualNetworkAdapter `
    -VM $vm `
    -VMNetwork $vmNetwork `
    -Synthetic

Start-SCVirtualMachine $vmName
```

### Update cluster resources

Change networks on IP Addresses for **TT-VMM01** and **TT-VMM01-FC**  to **10.1.15.0/24**.

```PowerShell
cls
```

### # Remove temporary VM network adapter

```PowerShell
$vmName = "TT-VMM01B"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName |
    where { $_.SlotId -eq 3 }

Stop-SCVirtualMachine $vmName

Start-Sleep -Seconds 60
```

> **Important**
>
> Verify the **TT-VMM01** cluster role fails over to **TT-VMM01A**.

```PowerShell
Read-SCVirtualMachine $vmName

Remove-SCVirtualNetworkAdapter $networkAdapter

Start-SCVirtualMachine $vmName
```

---

**TODO:**

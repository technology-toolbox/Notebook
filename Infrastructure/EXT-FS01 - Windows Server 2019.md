# EXT-FS01 - Windows Server 2019 File Server

Monday, June 3, 2019
8:04 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure infrastructure

---

**FOOBAR18 - Run as local administrator**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "EXT-FS01"
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
    -MemoryMinimumBytes 1GB `
    -MemoryMaximumBytes 4GB `
    -AutomaticCheckpointsEnabled $false

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
    -Path "\\TT-FS01\Products\Microsoft\Windows Server 2019\en_windows_server_2019_updated_march_2019_x64_dvd_2ae967ab.iso"

Set-VMDvdDrive : Failed to add device 'Virtual CD/DVD Disk'.
User Account does not have permission to open attachment.
'EXT-FS01' failed to add device 'Virtual CD/DVD Disk'. (Virtual machine ID 557181FC-4CEB-4C05-BA97-611D2A5A54D7)
'EXT-FS01': User account does not have permission required to open attachment '\\TT-FS01\Products\Microsoft\Windows Server
2019\en_windows_server_2019_updated_march_2019_x64_dvd_2ae967ab.iso'. Error: 'General access denied error' (0x80070005). (Virtual
machine ID 557181FC-4CEB-4C05-BA97-611D2A5A54D7)
At line:1 char:1
+ Set-VMDvdDrive `
+ ~~~~~~~~~~~~~~~~
    + CategoryInfo          : PermissionDenied: (:) [Set-VMDvdDrive], VirtualizationException
    + FullyQualifiedErrorId : AccessDenied,Microsoft.HyperV.PowerShell.Commands.SetVMDvdDrive

$iso = Get-SCISO |
    where {$_.Name -eq "en_windows_server_2019_updated_march_2019_x64_dvd_2ae967ab.iso"}

Get-SCVirtualMachine -Name $vmName | Read-SCVirtualMachine

Get-SCVirtualMachine -Name $vmName |
    Get-SCVirtualDVDDrive |
    Set-SCVirtualDVDDrive -ISO $iso -Link

#Start-VM -ComputerName $vmHost -Name $vmName
Start-SCVirtualMachine -VM $vmName
```

---

### Install Windows Server 2019

1. When prompted, select **Windows Server 2019 Standard**.
2. Specify a password for the local Administrator account.

### # Rename local Administrator account

```PowerShell
$adminUser = [ADSI] 'WinNT://./Administrator,User'
$adminUser.Rename('foo')

logoff
```

### Login as .\\foo

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

robocopy $source $destination /E /XD git-for-windows "Microsoft SDKs" /NP
```

### # Set MaxPatchCacheSize to 0 (recommended)

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

---

**FOOBAR18 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Move VM to Extranet VM network

```PowerShell
$vmName = "EXT-FS01"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Extranet-20 VM Network"

Stop-SCVirtualMachine $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork

Start-SCVirtualMachine $vmName
```

---

### Login as .\\foo

```PowerShell
cls
```

### # Set time zone

```PowerShell
tzutil /s "Mountain Standard Time"
```

### # Rename computer and join domain

```PowerShell
$computerName = "EXT-FS01"

Rename-Computer -NewName $computerName -Restart
```

Wait for the VM to restart and then execute the following command to join the **EXTRANET** domain:

```PowerShell
Add-Computer -DomainName extranet.technologytoolbox.com -Restart
```

---

**EXT-DC10 - Run as EXTRANET\\jjameson-admin**

```PowerShell
Cls

$vmName = "EXT-FS01"
```

### # Move computer to different OU

```PowerShell
$targetPath = ("OU=Servers,OU=Resources,OU=IT" `
    + ",DC=extranet,DC=technologytoolbox,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

### # Configure Windows Update

#### # Add machine to security group for Windows Update schedule

```PowerShell
Add-ADGroupMember -Identity "Windows Update - Slot 9" -Members ($vmName + '$')
```

---

### Configure storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 32 GB       | 4K                   | OSDisk       |
| 1    | D:           | 200 GB      | 4K                   | Data01       |

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

#### Configure separate VHD for data

---

**FOOBAR18 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

##### # Add disk for data

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "EXT-FS01"

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Data01.vhdx"

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
```

```PowerShell
cls
```

### # Configure networking

```PowerShell
$interfaceAlias = "Extranet-20"
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

Start-Sleep -Seconds 5

ping EXT-DC10 -f -l 8900
```

---

**FOOBAR18 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Make virtual machine highly available

### # Migrate VM to shared storage

```PowerShell
$vmName = "EXT-FS01"

$vm = Get-SCVirtualMachine -Name $vmName
$vmHost = $vm.VMHost

Move-SCVirtualMachine `
    -VM $vm `
    -VMHost $vmHost `
    -HighlyAvailable $true `
    -Path "C:\ClusterStorage\iscsi02-Silver-01" `
    -UseDiffDiskOptimization
```

```PowerShell
cls
```

### # Allow migration to host with different processor version

```PowerShell
Stop-SCVirtualMachine -VM $vmName

Set-SCVirtualMachine -VM $vmName -CPULimitForMigration $true

Start-SCVirtualMachine -VM $vmName
```

---

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

### # Create file shares

```PowerShell
mkdir D:\Shares\Products
mkdir D:\Shares\Public
mkdir D:\Shares\SymbolCache

Get-ChildItem D:\Shares |
    foreach {
        New-SmbShare `
            -Name $_.Name `
            -Path $_.FullName `
            -CachingMode None `
            -ChangeAccess Everyone
    }
```

## Configure backups

### Add virtual machine to Hyper-V protection group in DPM

```PowerShell
cls
```

## # Configure monitoring

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

---

**FOOBAR18 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Copy SCOM agent installation files

```PowerShell
$computerName = "EXT-FS01.extranet.technologytoolbox.com"

net use "\\$computerName\IPC`$" /USER:EXTRANET\jjameson-admin
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$source = "\\TT-FS01\Products\Microsoft\System Center 2016\SCOM\Agent\AMD64"
$destination = "\\$computerName\C`$\NotBackedUp\Temp\SCOM\Agent\AMD64"

robocopy $source $destination /E

$source = "\\TT-FS01\Products\Microsoft\System Center 2016\SCOM" `
    + "\SupportTools\AMD64"

$destination = "\\$computerName\C`$\NotBackedUp\Temp\SCOM\SupportTools\AMD64"

robocopy $source $destination /E
```

---

```PowerShell
cls
```

### # Install SCOM agent

```PowerShell
$installerPath = "C:\NotBackedUp\Temp\SCOM\Agent\AMD64\MOMAgent.msi"

$installerArguments = "MANAGEMENT_GROUP=HQ" `
    + " MANAGEMENT_SERVER_DNS=tt-scom03.corp.technologytoolbox.com" `
    + " ACTIONS_USE_COMPUTER_ACCOUNT=1"

Start-Process `
    -FilePath msiexec.exe `
    -ArgumentList "/i `"$installerPath`" $installerArguments" `
    -Wait
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

$certImportToolPath = "C:\NotBackedUp\Temp\SCOM\SupportTools\AMD64"

Push-Location "$certImportToolPath"

.\MOMCertImport.exe /SubjectName $hostName

Pop-Location
```

```PowerShell
cls
```

#### # Remove Operations Manager installation files

```PowerShell
Remove-Item C:\NotBackedUp\Temp\SCOM -Recurse
```

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

## Issue - Firewall log contains numerous entries for UDP 137 broadcast

### Solution

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

## Issue - Firewall log contains numerous entries for UDP 5355 broadcast

### Solution

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

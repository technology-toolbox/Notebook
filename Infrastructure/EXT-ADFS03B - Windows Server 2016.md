# EXT-ADFS03B - Windows Server 2016

Wednesday, March 28, 2018
8:45 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

### Install Windows Server 2016

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05B"
$vmName = "EXT-ADFS03B"
$vmPath = "E:\NotBackedUp\VMs\$vmName"
$vhdPath = "$vmPath\Virtual Hard Disks\$vmName.vhdx"

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

Start-VM -ComputerName $vmHost -Name $vmName
```

---

#### Install custom Windows Server 2016 image

- On the **Task Sequence** step, select **Windows Server 2016** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **EXT-ADFS02B**.
  - Select **Join a workgroup**.
  - In the **Workgroup **box, type **WORKGROUP**.
  - Click **Next**.
- On the **Applications** step, ensure no items are selected and click **Next**.

#### # Rename local Administrator account and set password

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

$password = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted, type the password for the local Administrator account.

```PowerShell
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

$adminUser = [ADSI] 'WinNT://./Administrator,User'
$adminUser.Rename('foo')
$adminUser.SetPassword($plainPassword)

logoff
```

### Configure networking

#### Configure static IP address

---

**TT-VMM01A**

```PowerShell
cls
```

##### # Configure static IP address using VMM

```PowerShell
$vmName = "EXT-ADFS03B"

$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"

$vmNetwork = Get-SCVMNetwork -Name "Extranet-20 VM Network"

$ipPool = Get-SCStaticIPAddressPool -Name "Extranet-20 Address Pool"

$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName |
    ? { $_.SlotId -eq 0 }

Stop-SCVirtualMachine $vmName

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

#### Login as .\\foo

#### # Rename network connections

```PowerShell
$interfaceAlias = "Extranet-20"

Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

### # Join servers to domain

```PowerShell
$cred = Get-Credential EXTRANET\jjameson-admin

Add-Computer -DomainName extranet.technologytoolbox.com -Credential $cred -Restart
```

---

**EXT-DC08 - Run as EXTRANET\\jjameson-admin**

```PowerShell
cls
```

##### # Move computer to different OU

```PowerShell
$computerName = "EXT-ADFS03B"

$targetPath = ("OU=Servers,OU=Resources,OU=IT" `
    + ",DC=extranet,DC=technologytoolbox,DC=com")

Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath
```

##### # Configure Windows Update

###### # Add machine to security group for Windows Update schedule

```PowerShell
$domainGroupName = "Windows Update - Slot 7"

Add-ADGroupMember -Identity $domainGroupName -Members ($computerName + '$')
```

---

### Configure backup

#### Add virtual machine to Hyper-V protection group in DPM

```PowerShell
cls
```

## # Install and configure AD FS

### # Import certificate for secure communication with AD FS

#### # Copy certificate

##### # Temporarily enable firewall rule for copying files to server

```PowerShell
Enable-NetFirewallRule -DisplayName "File and Printer Sharing (SMB-In)"
```

---

**WOLVERINE - Run as TECHTOOLBOX\\jjameson**

```PowerShell
cls
```

##### # Copy certificate from internal file server

```PowerShell
$computerName = "EXT-ADFS03B.extranet.technologytoolbox.com"
$certFile = "fs.technologytoolbox.com.pfx"

$source = "\\TT-FS01\Users$\jjameson\My Documents\Technology Toolbox LLC" `
    + "\Certificates\Internal"

$destination = "\\$computerName\C$\NotBackedUp\Temp"

net use "\\$computerName\C`$" /USER:EXTRANET\jjameson-admin
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```Console
robocopy $source $destination $certFile
```

---

```PowerShell
cls
```

#### # Disable firewall rule for copying files to server

```PowerShell
Disable-NetFirewallRule -DisplayName "File and Printer Sharing (SMB-In)"
```

#### # Install certificate

```PowerShell
$certPassword = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted for the secure string, type the password for the exported certificate.

```PowerShell
$certFile = "C:\NotBackedUp\Temp\fs.technologytoolbox.com.pfx"

Import-PfxCertificate `
    -FilePath $certFile `
    -CertStoreLocation Cert:\LocalMachine\My `
    -Password $certPassword

If ($? -eq $true)
{
    Remove-Item $certFile
}
```

```PowerShell
cls
```

### # Add AD FS server role

```PowerShell
Install-WindowsFeature ADFS-Federation -IncludeManagementTools
```

```PowerShell
cls
```

### # Add second federation server to AD FS farm

```PowerShell
$cert = Get-ChildItem -Path Cert:\LocalMachine\My |
    Where { $_.Subject -like "CN=fs.technologytoolbox.com,*" }

$installationCredential = Get-Credential EXTRANET\jjameson-admin
```

> **Note**
>
> When prompted, type the password for the domain administrator account.

```PowerShell
$serviceAccountCredential = Get-Credential TECHTOOLBOX\s-adfs
```

> **Note**
>
> When prompted, type the password for the service account.

```PowerShell
$databaseHostName = "EXT-SQL03"

Import-Module ADFS

Add-AdfsFarmNode `
    -CertificateThumbprint $cert.Thumbprint `
    -Credential $installationCredential `
    -ServiceAccountCredential $serviceAccountCredential `
    -SQLConnectionString ("Data Source=" + $databaseHostName + ";" `
        + "Initial Catalog=ADFSConfiguration;" `
        + "Integrated Security=True;" `
        + "Min Pool Size=20")



WARNING: A machine restart is required to complete ADFS service configuration. For more information, see:
http://go.microsoft.com/fwlink/?LinkId=798725
WARNING: Failed to register SSL bindings for Device Registration Service: An item with the same key has already been added..

Message                                   Context              Status
-------                                   -------              ------
The configuration completed successfully. DeploymentSucceeded Success


Restart-Computer
```

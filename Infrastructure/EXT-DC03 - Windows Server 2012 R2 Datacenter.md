# EXT-DC03 - Windows Server 2012 R2 Datacenter

Tuesday, July 19, 2016
2:29 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

### Install Windows Server 2012 R2

---

**WOLVERINE**

```PowerShell
$VerbosePreference = "Continue"
```

```PowerShell
cls
```

#### # Get list of Windows Server 2012 R2 images

```PowerShell
Add-AzureAccount

Get-AzureVMImage |
    where { $_.Label -like "Windows Server 2012 R2*" } |
    select Label, ImageName
```

```PowerShell
cls
```

#### # Use latest OS image

```PowerShell
$imageName = `
    "a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-R2-20160617" `
    + "-en.us-127GB.vhd"
```

#### # Create VM

```PowerShell
If ($localAdminCred -eq $null)
{
    $localAdminCred = Get-Credential `
        -UserName foo `
        -Message ("Type the user name and password for the local" `
            + " administrator account.")
}

If ($domainCred -eq $null)
{
    $domainCred = Get-Credential `
        -UserName jjameson-admin `
        -Message "Type the user name and password for joining the domain."
}

$storageAccount = "techtoolbox"
$location = "West US"
$vmName = "EXT-DC03"
$cloudService = $vmName
$instanceSize = "Basic_A0"
$vhdPath = "https://$storageAccount.blob.core.windows.net/vhds/$vmName"
$localAdminUserName = $localAdminCred.UserName
$localPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR(
        $localAdminCred.Password))

$domainName = "EXTRANET"
$fqdn = "extranet.technologytoolbox.com"
$domainUserName = $domainCred.UserName
$domainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR(
        $domainCred.Password))

$orgUnit = "OU=Servers,OU=Resources,OU=IT," `
    + "DC=extranet,DC=technologytoolbox,DC=com"

$virtualNetwork = "West US VLAN1"
$subnetName = "Azure-Production"
$ipAddress = "10.71.2.100"

$vmConfig = New-AzureVMConfig `
    -Name $vmName `
    -ImageName $imageName `
    -InstanceSize $instanceSize `
    -MediaLocation ($vhdPath + "/$vmName.vhd") |
    Add-AzureProvisioningConfig `
        -AdminUsername $localAdminUserName `
        -Password $localPassword `
        -WindowsDomain `
        -JoinDomain $fqdn `
        -Domain $domainName `
        -DomainUserName $domainUserName `
        -DomainPassword $domainPassword `
        -MachineObjectOU $orgUnit ` |
    Add-AzureDataDisk `
        -CreateNew `
        -DiskLabel Data01 `
        -DiskSizeInGB 5 `
        -LUN 0 `
        -HostCaching None `
        -MediaLocation ($vhdPath + "/$vmName" + "_Data01.vhd") |
    Set-AzureSubnet -SubnetNames $subnetName |
    Set-AzureStaticVNetIP -IPAddress $ipAddress

Set-AzureSubscription `
    -SubscriptionId ********-fdf5-4fd0-b21b-{redacted} `
    -CurrentStorageAccountName $storageAccount

New-AzureVM `
    -ServiceName $cloudService `
    -Location $location `
    -VNetName $virtualNetwork `
    -VMs $vmConfig
```

---

#### Configure ACLs on endpoints

##### PowerShell endpoint

| **Order** | **Description**    | **Action** | **Remote Subnet** |
| --------- | ------------------ | ---------- | ----------------- |
| 0         | Technology Toolbox | Permit     | 50.246.207.160/30 |

##### Remote Desktop endpoint

| **Order** | **Description**    | **Action** | **Remote Subnet** |
| --------- | ------------------ | ---------- | ----------------- |
| 0         | Technology Toolbox | Permit     | 50.246.207.160/30 |

---

**WOLVERINE**

```PowerShell
$vmName = "EXT-DC03"

$vm = Get-AzureVM -ServiceName $vmName -Name $vmName

$endpointNames = "PowerShell", "RemoteDesktop"

$endpointNames |
    ForEach-Object {
        $endpointName = $_

        $endpoint = $vm | Get-AzureEndpoint -Name $endpointName

        $acl = New-AzureAclConfig

        Set-AzureAclConfig `
            -AddRule `
            -ACL $acl `
            -Action Permit `
            -RemoteSubnet "50.246.207.160/30" `
            -Description "Technology Toolbox" `
            -Order 0

        Set-AzureEndpoint -Name $endpointName -VM $vm -ACL $acl |
            Update-AzureVM

    }
```

---

#### Configure network settings

> **Note**
>
> Do not enable jumbo frames on Azure VM (currently, large packets cannot be sent over VPN tunnel).

##### # Rename network connection

```PowerShell
Get-NetAdapter -Physical

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "Azure - Production"
```

```PowerShell
cls
```

##### # Configure setting for Azure VM to create reverse DNS record

```PowerShell
$netAdapter = Get-NetAdapter

$wmiNetAdapter = Get-WmiObject `
    -Class "Win32_NetworkAdapter" `
    -Filter "NetConnectionId = '$($netAdapter.Name)'"

$adapterConfig = Get-WmiObject `
    -Class "Win32_NetworkAdapterConfiguration" `
    -Filter "Index= '$($wmiNetAdapter.DeviceID)'"

$adapterConfig.SetDynamicDNSRegistration(
    $true, # Register this connection's addresses in DNS
    $true) # Use this connection's DNS suffix DNS registration
```

###### Reference

**Enabling DNS Reverse lookup in Azure IaaS**\
From <[http://blogs.technet.com/b/denisrougeau/archive/2014/02/27/enabling-dns-reverse-lookup-in-azure-iaas.aspx](http://blogs.technet.com/b/denisrougeau/archive/2014/02/27/enabling-dns-reverse-lookup-in-azure-iaas.aspx)>

#### Configure VM storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label      | Host Cache |
| ---- | ------------ | ----------- | -------------------- | ----------------- | ---------- |
| 0    | C:           | 127 GB      | 4K                   |                   | Read/Write |
| 1    | D:           | 20 GB       | 4K                   | Temporary Storage |            |
| 2    | E:           | 5 GB        | 4K                   | Data01            | None       |

```PowerShell
cls
```

##### # Change drive letter for DVD-ROM

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
```

##### # Create "Data01" drive

```PowerShell
Get-Disk 2 |
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -DriveLetter E -UseMaximumSize |
    Format-Volume `
        -FileSystem NTFS `
        -NewFileSystemLabel "Data01" `
        -Confirm:$false
```

```PowerShell
cls
```

#### # Set MaxPatchCacheSize to 0 (Recommended)

```PowerShell
reg add HKLM\Software\Policies\Microsoft\Windows\Installer /v MaxPatchCacheSize /t REG_DWORD /d 0 /f
```

#### # Copy Toolbox content

```PowerShell
net use \\iceman.corp.technologytoolbox.com\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
robocopy \\iceman.corp.technologytoolbox.com\Public\Toolbox `
    C:\NotBackedUp\Public\Toolbox /E
```

#### # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

```PowerShell
cls
```

### # Install and configure System Center Operations Manager

#### # Create certificate for Operations Manager

##### # Create request for Operations Manager certificate

```PowerShell
& "C:\NotBackedUp\Public\Toolbox\Operations Manager\Scripts\New-OperationsManagerCertificateRequest.ps1"
```

##### Submit certificate request to the Certification Authority

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

##### # Import the certificate into the certificate store

```PowerShell
$certFile = "C:\Users\jjameson-admin\Downloads\certnew.cer"

CertReq.exe -Accept $certFile

Remove-Item $certFile
```

```PowerShell
cls
```

#### # Install SCOM agent

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

#### # Import the certificate into Operations Manager using MOMCertImport

```PowerShell
$hostName = ([System.Net.Dns]::GetHostByName(($env:computerName))).HostName

$certImportToolPath = $imageDriveLetter + ':\SupportTools\AMD64'

cd "$certImportToolPath"

.\MOMCertImport.exe /SubjectName $hostName
```

#### # Approve manual agent install in Operations Manager

```PowerShell
cls
```

## # Configure domain controller

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
    -NoGlobalCatalog:$false `
    -CreateDnsDelegation:$false `
    -Credential (Get-Credential) `
    -CriticalReplicationOnly:$false `
    -DatabasePath "E:\Windows\NTDS" `
    -DomainName "extranet.technologytoolbox.com" `
    -InstallDns:$true `
    -LogPath "E:\Windows\NTDS" `
    -NoRebootOnCompletion:$false `
    -SiteName "Azure-West-US" `
    -SysvolPath "E:\Windows\SYSVOL" `
    -Force:$true
```

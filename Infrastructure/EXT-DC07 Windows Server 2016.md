# EXT-DC07 Windows Server 2016

Wednesday, May 10, 2017\
9:54 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

### Install Windows Server 2016

---

**WOLVERINE** - Run as administrator

```PowerShell
$VerbosePreference = "Continue"
```

```PowerShell
cls
```

#### # Get list of Windows Server 2016 images

```PowerShell
Add-AzureAccount

Get-AzureVMImage |
    where { $_.Label -like "Windows Server 2016*" } |
    select Label, ImageName
```

```PowerShell
cls
```

#### # Use latest OS image

```PowerShell
$imageName = `
    "a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2016-Datacenter-20170406" `
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

$subscriptionId = "********-fdf5-4fd0-b21b-{redacted}"
$storageAccount = "techtoolbox"
$location = "West US"
$vmName = "EXT-DC07"
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
    -SubscriptionId $subscriptionId `
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

**WOLVERINE** - Run as administrator

```PowerShell
$vmName = "EXT-DC07"

$vm = Get-AzureVM -ServiceName $vmName -Name $vmName

$endpointNames = "PowerShell", "RemoteDesktop"

$endpointNames |
    foreach {
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

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter #2" |
    Rename-NetAdapter -NewName "Azure - Production"
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

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label | Host Cache |
| --- | --- | --- | --- | --- | --- |
| 0 | C: | 127 GB | 4K |  | Read/Write |
| 1 | D: | 20 GB | 4K | Temporary Storage |  |
| 2 | E: | 5 GB | 4K | Data01 | None |

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

#### # Set MaxPatchCacheSize to 0 (Recommended)

```PowerShell
reg add HKLM\Software\Policies\Microsoft\Windows\Installer /v MaxPatchCacheSize /t REG_DWORD /d 0 /f
```

#### # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

## Configure domain controller

---

**EXT-DC01** - Run as administrator

### # Create Active Directory site

```PowerShell
$siteName = "Azure-West-US"
$subnet = "10.71.0.0/16"

New-ADReplicationSite -Name $siteName

New-ADReplicationSubnet -Name $subnet -Site $siteName

Set-ADReplicationSiteLink `
    -Identity DEFAULTIPSITELINK `
    -SitesIncluded @{Add="$siteName"}
```

---

### Login as EXTRANET\\jjameson-admin

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

### # Download PowerShell help files

```PowerShell
Update-Help
```

### # Promote server to domain controller

```PowerShell
Import-Module ADDSDeployment

Install-ADDSDomainController `
    -NoGlobalCatalog:$false `
    -CreateDnsDelegation:$false `
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

> **Note**
>
> When prompted, specify the password for the administrator account when the computer is started in Safe Mode or a variant of Safe Mode, such as Directory Services Restore Mode.

## Issue - DNS errors

```Text
Log Name:      System
Source:        Microsoft-Windows-DNS-Client
Date:          5/11/2017 1:35:49 AM
Event ID:      1014
Task Category: (1014)
Level:         Warning
Keywords:      (268435456)
User:          NETWORK SERVICE
Computer:      EXT-DC07.extranet.technologytoolbox.com
Description:
Name resolution for the name microsoft.com timed out after none of the configured DNS servers responded.
```

### Troubleshooting

```Text
PS C:\Windows\system32> nslookup
DNS request timed out.
    timeout was 2 seconds.
Default Server:  UnKnown
Address:  ::1

> exit

PS C:\Windows\system32> Get-DnsClientServerAddress -InterfaceAlias "Azure - Production" | select AddressFamily, ServerAddresses

AddressFamily ServerAddresses
------------- ---------------
            2 {192.168.10.209, 192.168.10.210, 127.0.0.1}
           23 {::1}
```

### Solution

```Text
PS C:\Windows\system32> Set-DnsClientServerAddress -InterfaceAlias "Azure - Production" -ResetServerAddresses
PS C:\Windows\system32> Get-DnsClientServerAddress -InterfaceAlias "Azure - Production" | select AddressFamily, ServerAddresses

AddressFamily ServerAddresses
------------- ---------------
            2 {192.168.10.209, 192.168.10.210}
           23 {}

PS C:\Windows\system32> nslookup
Default Server:  EXT-DC04.extranet.technologytoolbox.com
Address:  192.168.10.209

> exit

PS C:\Windows\system32> Restart-Computer
```

```Console
cls
```

## # Install and configure System Center Operations Manager

### # Create certificate for Operations Manager

#### # Copy Toolbox content

```PowerShell
net use \\tt-fs01.corp.technologytoolbox.com\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$source = "\\tt-fs01.corp.technologytoolbox.com\Public\Toolbox"
$dest = "C:\NotBackedUp\Public\Toolbox"

robocopy $source $dest /E /NP /XD "Microsoft SDKs"
```

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

Remove-Item $certFile
```

### # Install SCOM agent

```PowerShell
net use \\tt-fs01.corp.technologytoolbox.com\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$msiPath = "\\tt-fs01.corp.technologytoolbox.com\Products\Microsoft" `
    + "\System Center 2016\SCOM\agent\AMD64\MOMAgent.msi"

msiexec.exe /i $msiPath `
    MANAGEMENT_GROUP=HQ `
    MANAGEMENT_SERVER_DNS=tt-scom01.corp.technologytoolbox.com `
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

$certImportToolPath = "\\tt-fs01.corp.technologytoolbox.com\Products\Microsoft" `
    + "\System Center 2016\SCOM\SupportTools\AMD64\MOMCertImport.exe"

& $certImportToolPath /SubjectName $hostName
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

**TODO:**

## Issue - License Activation failures

```Text
Log Name:      Application
Source:        Microsoft-Windows-Security-SPP
Date:          3/27/2017 1:27:16 PM
Event ID:      8198
Task Category: None
Level:         Error
Keywords:      Classic
User:          N/A
Computer:      EXT-DC07.extranet.technologytoolbox.com
Description:
License Activation (slui.exe) failed with the following error code:
hr=0xC004F074
Command-line arguments:
RuleId=502ff3ba-669a-4674-bbb1-601f34a3b968;Action=AutoActivateSilent;AppId=55c92734-d682-4d71-983e-d6ec3f16059f;SkuId=00091344-1ea4-4f37-b789-01750ba6988c;NotificationInterval=1440;Trigger=TimerEvent
```

### Solution

```Console
C:\NotBackedUp\Public\Toolbox\Sysinternals\psping.exe kms.core.windows.net:1688

cscript c:\windows\system32\slmgr.vbs /ckhc

cscript c:\windows\system32\slmgr.vbs /skms kms.core.windows.net:1688

cscript c:\windows\system32\slmgr.vbs /ato
```

### References

**Windows Server 2012 Datacenter Not Activating - Windows Azure**\
From <[https://social.msdn.microsoft.com/Forums/azure/en-US/f29d5fe7-4f0f-433d-8333-1d336f68a4db/windows-server-2012-datacenter-not-activating-windows-azure?forum=WAVirtualMachinesforWindows](https://social.msdn.microsoft.com/Forums/azure/en-US/f29d5fe7-4f0f-433d-8333-1d336f68a4db/windows-server-2012-datacenter-not-activating-windows-azure?forum=WAVirtualMachinesforWindows)>\
**Troubleshooting Windows activation failures on Azure VMs**\
From <[https://blogs.msdn.microsoft.com/mast/2014/12/23/troubleshooting-windows-activation-failures-on-azure-vms/](https://blogs.msdn.microsoft.com/mast/2014/12/23/troubleshooting-windows-activation-failures-on-azure-vms/)>

**TODO:**

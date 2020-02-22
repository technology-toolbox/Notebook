# EXT-GW01A - Windows Server 2016

Friday, January 13, 2017
1:37 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Create failover cluster names in Active Directory

---

**FOOBAR8 - Run as administrator**

```PowerShell
cls
```

### # Create failover cluster name in Active Directory

```PowerShell
$failoverClusterName = "EXT-GW01-FC"
$description = "Failover cluster virtual network name"
$orgUnit = "OU=Servers,OU=Resources,OU=IT," `
    + "DC=corp,DC=technologytoolbox,DC=com"

New-ADComputer `
    -Name $failoverClusterName  `
    -Description $description `
    -Path $orgUnit `
    -Enabled:$false

Start-Sleep -Seconds 15
```

### # Add "Full Control" permission to the VMM administrators group (since a member of that group will create the cluster)

```PowerShell
$failoverClusterCreator = New-Object System.Security.Principal.NTAccount(
    "TECHTOOLBOX\VMM Admins")

$computer = Get-ADComputer -Identity $failoverClusterName
$computerObject = Get-ADObject -Identity $computer.DistinguishedName -Properties *
$securityDescriptor = $computerObject.nTSecurityDescriptor

$accessRule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(
    $failoverClusterCreator,
    "GenericAll",
    "Allow")

$securityDescriptor.AddAccessRule($accessRule)

Set-ADObject $computerObject -Replace @{ nTSecurityDescriptor = $securityDescriptor }

Start-Sleep -Seconds 15

TODO:
```

### # Create failover cluster name for gateway

```PowerShell
$failoverClusterName = "TT-GW01"
$description = "Failover cluster name for Virtual Machine Manager"
$orgUnit = "OU=System Center Servers,OU=Servers,OU=Resources,OU=IT," `
    + "DC=corp,DC=technologytoolbox,DC=com"

New-ADComputer `
    -Name $failoverClusterName  `
    -Description $description `
    -Path $orgUnit `
    -Enabled:$false

Start-Sleep -Seconds 15
```

### # Add "Full Control" permission to the user that will create the VMM cluster role (which, in this case, will be the cluster service -- i.e. TECHTOOLBOX\\TT-VMM01-FC\$)

```PowerShell
$failoverClusterAccount = New-Object System.Security.Principal.NTAccount(
    "TECHTOOLBOX\TT-VMM01-FC$")

$computer = Get-ADComputer -Identity $failoverClusterName
$computerObject = Get-ADObject -Identity $computer.DistinguishedName -Properties *
$securityDescriptor = $computerObject.nTSecurityDescriptor

$accessRule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(
    $failoverClusterAccount,
    "GenericAll",
    "Allow")

$securityDescriptor.AddAccessRule($accessRule)

Set-ADObject $computerObject -Replace @{ nTSecurityDescriptor = $securityDescriptor }
```

---

---

**FOOBAR8 - Run as administrator**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV01A"
$vmName = "EXT-GW01A"
$vmPath = "E:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"
$isoPath = "\\ICEMAN\Products\Microsoft\Windows Server 2016" `
    + "\en_windows_server_2016_x64_dvd_9327751.iso"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 2GB `
    -SwitchName "Tenant vSwitch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 2 `
    -DynamicMemory `
    -MemoryMaximumBytes 4GB

Set-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path $isoPath

Start-VM -ComputerName $vmHost -Name $vmName
```

---

## Install Windows Server 2016 Standard ("Core")

```Console
PowerShell
```

```Console
cls
```

## # Set time zone

```PowerShell
tzutil /s "Mountain Standard Time"
```

## # Rename local Administrator account

```PowerShell
$adminUser = [ADSI] 'WinNT://./Administrator,User'
$adminUser.Rename('foo')

logoff
```

## Login as local administrator account

```Console
PowerShell
```

```Console
cls
```

### # Configure network settings

```PowerShell
$interfaceAlias = "Datacenter 1"
```

#### # Rename network connection

```PowerShell
Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

#### # Configure DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 192.168.10.209,192.168.10.210

Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 2603:300b:802:8900::209,2603:300b:802:8900::210
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping ICEMAN -f -l 8900
```

```PowerShell
cls
```

### # Rename the server and join domain

```PowerShell
Rename-Computer -NewName EXT-GW01A -Restart
```

> **Note**
>
> Wait for the VM to restart.

```Console
PowerShell

Add-Computer -DomainName extranet.technologytoolbox.com -Restart
```

---

**FOOBAR8 - Run as administrator**

```PowerShell
cls
```

### # Remove disk from virtual CD/DVD drive

```PowerShell
$vmHost = "TT-HV01A"
$vmName = "EXT-GW01A"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

---

---

**EXT-DC01** - Run as domain administrator

```PowerShell
cls
```

### # Move computer to "Servers" OU

```PowerShell
$computer = "EXT-GW01A"

$targetPath = ("OU=Servers,OU=Resources,OU=IT" `
    + ",DC=extranet,DC=technologytoolbox,DC=com")

Get-ADComputer $computer | Move-ADObject -TargetPath $targetPath
```

---

## Login as EXTRANET\\jjameson-admin

```Console
PowerShell
```

```Console
cls
```

## # Copy Toolbox content

```PowerShell
$source = "\\ICEMAN.corp.technologytoolbox.com\Public\Toolbox"
$destination = "C:\NotBackedUp\Public\Toolbox"

net use $source /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```Console
robocopy $source $destination  /E /XD "Microsoft SDKs"
```

## # Set MaxPatchCacheSize to 0 (Recommended)

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

## # Select "High performance" power scheme

```PowerShell
powercfg.exe /L
powercfg.exe /S SCHEME_MIN
powercfg.exe /L
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

## Issue - Windows Update hangs downloading cumulative update

### Reference

**Windows Update Step hanging - Windows 10 1607**\
From <[https://social.technet.microsoft.com/Forums/en-US/35309dd8-f87a-41e1-8a20-33ffbb2648e2/windows-update-step-hanging-windows-10-1607?forum=mdt](https://social.technet.microsoft.com/Forums/en-US/35309dd8-f87a-41e1-8a20-33ffbb2648e2/windows-update-step-hanging-windows-10-1607?forum=mdt)>

In order for the MDT Windows Update action to work when having a local WSUS (known bug), you really need to slipstream [KB3197954](KB3197954) or later into the image during the WinPE phase. In MDT that is done by adding it as a package in the Deployment Workbench, and create a selection profile for Windows 10 x64 v1607.

From <[http://deploymentresearch.com/Research/Post/540/Building-a-Windows-10-v1607-reference-image-using-MDT-2013-Update-2](http://deploymentresearch.com/Research/Post/540/Building-a-Windows-10-v1607-reference-image-using-MDT-2013-Update-2)>

```PowerShell
cls
```

### # Solution - Install cumulative update for Windows Server 2016

```PowerShell
$source = "\\ICEMAN\Products\Microsoft\Windows 10\Patches"
$destination = "C:\NotBackedUp\Temp"
$patch = "windows10.0-kb3213522-x64_fc88893ff1fbe75cac5f5aae7ff1becee55c89dd.msu"

net use $source /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
robocopy $source $destination $patch

& "$destination\$patch"
```

> **Note**
>
> When prompted, restart the computer to complete the installation.

```PowerShell
PowerShell
```

```PowerShell
cls
Remove-Item ("C:\NotBackedUp\Temp" `
    + "\windows10.0-kb3213522-x64_fc88893ff1fbe75cac5f5aae7ff1becee55c89dd.msu")
```

## # Add VMM administrators domain group to local Administrators group

```PowerShell
$domain = "TECHTOOLBOX"
$domainGroup = "VMM Admins"

([ADSI]"WinNT://./Administrators,group").Add(
    "WinNT://$domain/$domainGroup,group")

logoff
```

## Install RRAS roles

### Login as TECHTOOLBOX\\setup-vmm

```Console
PowerShell
```

```Console
cls

Install-WindowsFeature RemoteAccess -IncludeManagementTools
Install-WindowsFeature DirectAccess-VPN -IncludeManagementTools
Install-WindowsFeature Routing -IncludeManagementTools

Restart-Computer
```

## Install patches using Windows Update

---

**FOOBAR8 - Run as administrator**

```PowerShell
cls
```

### # Update VM baseline

```PowerShell
$vmHost = "TT-HV01A"
$vmName = "EXT-GW01A"

C:\NotBackedUp\Public\Toolbox\PowerShell\Update-VMBaseline `
    -ComputerName $vmHost `
    -Name $vmName `
    -Confirm:$false

Start-VM -ComputerName $vmHost -Name $vmName
```

---

## Configure failover clustering

### Login as TECHTOOLBOX\\setup-vmm

```Console
PowerShell
```

```Console
cls
```

### # Install Failover Clustering feature

```PowerShell
Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools
```

```PowerShell
cls
```

### # Run all cluster validation tests

```PowerShell
Test-Cluster -Node EXT-GW01A, EXT-GW01B
```

> **Note**
>
> Wait for the cluster validation tests to complete.

```Text
WARNING: Network - Validate Network Communication: The test reported some warnings..
WARNING:
Test Result:
HadUnselectedTests, ClusterConditionallyApproved
Testing has completed for the tests you selected. You should review the warnings in the Report.  A cluster solution is supported by Microsoft only if you run all cluster validation tests, and all tests succeed (with or without warnings).
Test report file path: C:\Users\setup-vmm\AppData\Local\Temp\2\Validation Report 2017.01.14 At 06.40.21.htm

Mode                LastWriteTime         Length Name
----                -------------         ------ ----
-a----        1/14/2017   6:41 AM         496787 Validation Report 2017.01.14 At 06.40.21.htm
```

### # Review cluster validation report

```PowerShell
$source = "$env:TEMP\Validation Report 2017.01.14 At 06.40.21.htm"
$destination = "\\ICEMAN.corp.technologytoolbox.com\Public"

net use $destination /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
Copy-Item $source $destination
```

---

**WOLVERINE** - Run as administrator

```PowerShell
& "\\ICEMAN\Public\Validation Report 2017.01.14 At 06.40.21.htm"
```

---

> **Note**
>
> The cluster creation report contains the following warnings:
>
> - **Node EXT-GW01B.extranet.technologytoolbox.com is reachable from Node EXT-GW01A.extranet.technologytoolbox.com by only one pair of network interfaces. It is possible that this network path is a single point of failure for communication within the cluster. Please verify that this single path is highly available, or consider adding additional networks to the cluster.**
> - **Node EXT-GW01A.extranet.technologytoolbox.com is reachable from Node EXT-GW01B.extranet.technologytoolbox.com by only one pair of network interfaces. It is possible that this network path is a single point of failure for communication within the cluster. Please verify that this single path is highly available, or consider adding additional networks to the cluster.**

```PowerShell
cls
```

### # Create cluster

```PowerShell
New-Cluster -Name EXT-GW01-FC -Node EXT-GW01A, EXT-GW01B -NoStorage

WARNING: There were issues while creating the clustered role that may prevent it from starting. For more information
view the report file below.
WARNING: Report file location: C:\Windows\cluster\Reports\Create Cluster Wizard EXT-GW01-FC on 2017.01.14 At 06.44.22.htm

Name
----
EXT-GW01-FC
```

```PowerShell
cls
```

### # Review cluster report

```PowerShell
$source = "C:\Windows\cluster\Reports\" `
    + "Create Cluster Wizard EXT-GW01-FC on 2017.01.14 At 06.44.22.htm"

$destination = "\\ICEMAN.corp.technologytoolbox.com\Public"

net use $destination /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
Copy-Item $source $destination
```

---

**WOLVERINE** - Run as administrator

```PowerShell
& "\\ICEMAN\Public\Create Cluster Wizard EXT-GW01-FC on 2017.01.14 At 06.44.22.htm"
```

---

```PowerShell
& "C:\windows\cluster\Reports\Create Cluster Wizard TT-VMM01-FC on 2017.01.12 At 09.29.41.htm"
```

> **Note**
>
> The cluster creation report contains the following warnings:
>
> - **An appropriate disk was not found for configuring a disk witness. The cluster is not configured with a witness. As a best practice, configure a witness to help achieve the highest availability of the cluster. If this cluster does not have shared storage, configure a File Share Witness or a Cloud Witness.**

## Configure multitenant gateway

---

**FOOBAR8** - Run as administrator

```PowerShell
cls
```

### # Add a second network adapter for network virtualization

```PowerShell
$vmHost = "TT-HV01A"
$vmName = "EXT-GW01A"

Stop-VM -ComputerName $vmHost -Name $vmName

Add-VMNetworkAdapter -ComputerName $vmHost -VMName $vmName

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Install remote access and enable multitenancy

```Console
PowerShell

Install-RemoteAccess -MultiTenancy
```

### Rename network adapters

Notepad C:\\NotBackedUp\\Temp\\Get-Subnet.ps1

---

File - **Get-Subnet.ps1**

```PowerShell
$ErrorActionPreference = "stop";

$ErrorCode_Success = 0;
$ErrorCode_Failed = 1;

Function Get-Subnet {
    Param(
        [Net.IPAddress]$IPAddress,
        [int]          $PrefixLength)

    try
    {
        $AddressBytes = $IPAddress.GetAddressBytes();

        $NumberOfBytesToZero = $AddressBytes.Length - [int][System.Math]::Floor($PrefixLength / 8);
        $Remainder = $PrefixLength % 8;


        for($Index = 0; $Index -lt ($NumberOfBytesToZero - 1); $Index++)
        {
            $AddressBytes[$AddressBytes.Length-1-$Index] = 0;
        }

        if( $Remainder -eq 0 )
        {
            $AddressBytes[$AddressBytes.Length - $NumberOfBytesToZero] = 0;
        }
        else
        {
            $BitsToMove = 8 - $Remainder;
            $Mask = (255 -shr $BitsToMove) -shl $BitsToMove;
            $AddressBytes[$AddressBytes.Length - $NumberOfBytesToZero] = $AddressBytes[$AddressBytes.Length - $NumberOfBytesToZero] -band $Mask;
        }

        $SubnetIP = new-object System.Net.IPAddress(,$AddressBytes);
        $SubnetIPWithPrefixString = "{0}/{1}" -f $SubnetIP, $PrefixLength;

        Return $SubnetIPWithPrefixString;
    }
    catch
    {
        Write-Output "Caught an exception:";
        Write-Output "    Exception Type: $($_.Exception.GetType().FullName)";
        Write-Output "    Exception Message: $($_.Exception.Message)";
        Write-Output "    Exception HResult: $($_.Exception.HResult)";
        Exit $($_.Exception.HResult);
    }
}
```

---

Notepad "C:\\NotBackedUp\\Temp\\Rename Network Adapters.ps1"

---

File - **Rename Network Adapters.ps1**

```PowerShell
. .\Get-Subnet.ps1;

$ErrorActionPreference = "stop";

$ErrorCode_Success = 0;
$ErrorCode_Failed = 1;

#
# Process Adapters on the machine
$Adapters = get-netadapter;
foreach ($Adapter in $Adapters) {

    $NewAdapterName = "";

    Write-Output "Processing Adapter: $($Adapter.Name) with ifindex: $($Adapter.ifindex)";

    #
    # For the disconnected adapter, name it to BackEnd
    if ($Adapter.Status -eq "Disconnected")
    {
       Write-Output "    Adapter is disconnected. Naming it to 'BackEnd'";
       rename-netadapter -Name $Adapter.name -NewName "BackEnd";
       continue;
    }

    #
    # Ignore other adapters
    if ($Adapter.Status -ne "Up")
    {
       Write-Output "    Adapter Status is not UP... Ignoring Adapter";
       continue;
    }

    #
    # Getting the NetProfile.Name
    Write-Output "    Getting NetProfile.Name from NetIPConfiguration";
    $NetIPConfig = Get-NetIPConfiguration | where {$_.InterfaceIndex -eq $Adapter.ifindex};
    $NetProfileName = $NetIPConfig.NetProfile.Name;

    Write-Output "    Getting IPv4 Address";
    $ip = get-netIPAddress | where {$_.InterfaceIndex -eq $Adapter.ifindex -and  $_.addressfamily -eq 2};
    if (!$ip)
    {
        Write-Output "    No IPv4 Address on the Adapter proceeding with with IPv6";
        $ip = get-netIPAddress | where {$_.InterfaceIndex -eq $Adapter.ifindex -and  $_.addressfamily -eq 23};
        if (!$ip)
        {
            Write-Output "Failed to get IP Address for adapter $($Adapter.Name) with ifindex: $($Adapter.ifindex)";
            Exit $ErrorCode_Failed;
        }
    }

    Write-Output "    Calculate SubNet IP for IP Address $($ip[0].IPAddress) and PrefixLength $($ip[0].PrefixLength)";
    $SubNetIP = Get-Subnet -IPAddress $ip[0].IPAddress -PrefixLength $ip[0].PrefixLength;
    if ($SubNetIP -eq "")
    {
        Write-Output "Failed to calculate SubNet IP for IP Address $($ip[0].IPAddress) and PrefixLength $($ip[0].PrefixLength)";
        Exit $ErrorCode_Failed;
    }

    $SubNetIP = $SubNetIP -replace '/','_';
    Write-Output "    New name will be based on: $SubNetIP";

    # Remove invalid characters
    $NewAdapterName = $NewAdapterName -replace ':','';


    #
    # If the other nic already has this name increment the postfix
    $PostFix = 1;
    if ($NetProfleName -eq "")
    {
        $AdapterName = $SubNetIP;
    }
    else
    {
        $AdapterName =  $NetProfileName + "_" + $SubNetIP;
    }

    $TmpAdapters = get-netadapter;
    foreach ($TmpAdapter in $TmpAdapters)
    {
        if (($TmpAdapter.Name -eq $AdapterName) -and ($TmpAdapter.ifIndex -ne $Adapter.ifIndex))
        {
            $AdapterName = $AdapterName + "_" + [String]$PostFix;
            $PostFix++;
            break;
        }
    }

    #
    # Now rename the NIC
    try
    {
        Write-Output "    Renaming adapter from '$($Adapter.name)' to '$AdapterName'";
        rename-netAdapter -Name $Adapter.name -NewName $AdapterName;
    }
    catch
    {
        Write-Output "Caught an exception:";
        Write-Output "    Exception Type: $($_.Exception.GetType().FullName)";
        Write-Output "    Exception Message: $($_.Exception.Message)";
        Write-Output "    Exception HResult: $($_.Exception.HResult)";
    }
}

Exit $ErrorCode_Success;
```

---

Push-Location C:\\NotBackedup\\Temp

& ".\\Rename Network Adapters.ps1"

Pop-Location

### Add RRAS cluster resource

Add-ClusterResourceType -Name "RAS Cluster Resource" -Dll \$env:windir\\System32\\RasClusterRes.dll

---

**EXT-DC01** - Run as domain administrator

```PowerShell
cls
```

## # Move computer to "Gateway Servers" OU

```PowerShell
$computer = "EXT-GW01A"

$targetPath = ("OU=Gateway Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=extranet,DC=technologytoolbox,DC=com")

Get-ADComputer $computer | Move-ADObject -TargetPath $targetPath
```

---

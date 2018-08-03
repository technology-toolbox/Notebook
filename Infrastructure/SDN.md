# SDN

Monday, July 30, 2018
6:12 AM

---

**FOOBAR16**

```PowerShell
cls
```

## # Configure Production-15 network

### # Add new subnets to Active Directory site

```PowerShell
$siteName = "Technology-Toolbox-HQ"

New-ADReplicationSubnet -Name "10.1.15.0/24" -Site $siteName
New-ADReplicationSubnet -Name "2603:300b:802:89e1::/64" -Site $siteName
```

### # Create reverse lookup zones in DNS

```PowerShell
Add-DnsServerPrimaryZone `
    -ComputerName TT-DC08 `
    -NetworkID "10.1.15.0/24" `
    -ReplicationScope Forest

Add-DnsServerPrimaryZone `
    -ComputerName TT-DC08 `
    -NetworkID "2603:300b:802:89e1::/64" `
    -ReplicationScope Forest
```

```PowerShell
cls
```

### # Create reverse lookup zones in DNS

```PowerShell
Add-DnsServerPrimaryZone `
    -ComputerName TT-DC08 `
    -NetworkID "10.1.30.0/24" `
    -ReplicationScope Forest

Add-DnsServerPrimaryZone `
    -ComputerName TT-DC08 `
    -NetworkID "10.1.31.0/24" `
    -ReplicationScope Forest

Add-DnsServerPrimaryZone `
    -ComputerName TT-DC08 `
    -NetworkID "172.28.6.0/24" `
    -ReplicationScope Forest

Add-DnsServerPrimaryZone `
    -ComputerName TT-DC08 `
    -NetworkID "192.168.50.0/24" `
    -ReplicationScope Forest

Add-DnsServerPrimaryZone `
    -ComputerName TT-DC08 `
    -NetworkID "192.168.51.0/24" `
    -ReplicationScope Forest
```

---

---

**FOOBAR16**

```PowerShell
cls
```

#### # Disable extension on logical switch in VMM

```PowerShell
$logicalSwitch = Get-SCLogicalSwitch -Name "Embedded Team Switch"

Set-SCLogicalSwitch -LogicalSwitch $logicalSwitch -VirtualSwitchExtensions @()
```

#### Reference

Clear the checkbox "Microsoft Window Filtering Platform". New SDN stack uses Virtual Filtering Platform (VFP) from Azure instead of the default Windows Filtering Platform.

**Step-by-step for deploying a SDNv2 using VMM - Part 2**\
From <[https://blogs.technet.microsoft.com/larryexchange/2016/05/30/step-by-step-for-deploying-a-sdnv2-using-vmm-part-2/](https://blogs.technet.microsoft.com/larryexchange/2016/05/30/step-by-step-for-deploying-a-sdnv2-using-vmm-part-2/)>

---

---

**TT-DEPLOY-SDN**

```Console
cls
robocopy '\\WOLVERINE\C$\NotBackedUp\GitHub\SDN' C:\NotBackedUp\SDN /E
```

```Console
cls
```

#### # Configure SDNExpress share

```PowerShell
$sdnExpressPath = "C:\NotBackedUp\SDN\SDNExpress"

New-SmbShare `
  -Name SDNExpress `
  -Path $sdnExpressPath `
  -CachingMode None `
  -FullAccess "NT AUTHORITY\Authenticated Users"
```

```PowerShell
cls
```

#### # Copy Windows Datacenter image to SDNExpress share

```PowerShell
robocopy \\TT-FS01\VM-Library\VHDs "$sdnExpressPath\images" WS2016-Dc-Core.vhdx
```

```PowerShell
cls
```

#### # Install Hyper-V Module for Windows PowerShell

```PowerShell
Install-WindowsFeature Hyper-V-PowerShell
```

```PowerShell
cls
```

#### # Add "HostUsername" account to local Administrators group on Hyper-V nodes

```PowerShell
$hyperVHosts = @("TT-HV05A", "TT-HV05B", "TT-HV05C")
$domain = "TECHTOOLBOX"
$username = "s-nc01-host"

$script = "
([ADSI]'WinNT://./Administrators,group').Add(
    'WinNT://$domain/$username,user')
"

$scriptBlock = [ScriptBlock]::Create($script)

$hyperVHosts |
    foreach {
        $computer = $_

        Invoke-Command -ComputerName $computer -ScriptBlock $scriptBlock
    }
```

```PowerShell
cls
```

#### # Remove virtual switch extension on Hyper-V nodes

```PowerShell
$logicalSwitch = Get-SCLogicalSwitch -Name "Embedded Team Switch"

Set-SCLogicalSwitch -LogicalSwitch $logicalSwitch -VirtualSwitchExtensions @()
```

```PowerShell
cls
```

## # Deploy SDN

```PowerShell
Push-Location C:\NotBackedUp\SDN\SDNExpress\scripts
```

```PowerShell
cls
.\SDNExpress.ps1 -ConfigurationDataFile .\FabricConfig.TECHTOOLBOX.psd1 -Verbose
```

```PowerShell
cls
.\SDNExpressUndo.ps1 -ConfigurationDataFile .\FabricConfig.TECHTOOLBOX.psd1 -Verbose
```

---

## Issue -

```Text
PS D:\NotBackedUp\SDN\SDNExpress\scripts> .\SDNExpress.ps1 -ConfigurationDataFile .\FabricConfig.TECHTOOLBOX.psd1 -Verbose
VERBOSE: Using configuration from file [.\FabricConfig.TECHTOOLBOX.psd1]
VERBOSE: STAGE 1: Housekeeping
VERBOSE: Script version is 1.2 and FabricConfig version is 1.2
VERBOSE: Populating defaults into parameters that were not set in config file.
VERBOSE: Starting MAC is 001DD8000000
VERBOSE: Assigned MAC 001DD8000000 to [TT-NC01A] [Management]
VERBOSE: Assigned MAC 001dd8000001 to [TT-MUX01A] [HNVPA]
VERBOSE: Assigned MAC 001dd8000002 to [TT-MTGW01A] [Management]
VERBOSE: Assigned MAC 001dd8000003 to [TT-MTGW01A] [HNVPA]
VERBOSE: Assigned MAC 001dd8000004 to [TT-MTGW01A] [Transit]
VERBOSE: Assigned MAC 001dd8000005 to [TT-NC01B] [Management]
VERBOSE: Assigned MAC 001dd8000006 to [TT-MUX01B] [HNVPA]
VERBOSE: Assigned MAC 001dd8000007 to [TT-MTGW-GRE01A] [Management]
VERBOSE: Assigned MAC 001dd8000008 to [TT-MTGW-GRE01A] [HNVPA]
VERBOSE: Assigned MAC 001dd8000009 to [TT-MTGW-GRE01A] [Transit]
VERBOSE: Assigned MAC 001dd800000a to [TT-NC01C] [Management]
VERBOSE: Assigned MAC 001dd800000b to [TT-MTGW01B] [Management]
VERBOSE: Assigned MAC 001dd800000c to [TT-MTGW01B] [HNVPA]
VERBOSE: Assigned MAC 001dd800000d to [TT-MTGW01B] [Transit]
VERBOSE: Assigned MAC 001dd800000e to [TT-MTGW-GRE01B] [Management]
VERBOSE: Assigned MAC 001dd800000f to [TT-MTGW-GRE01B] [HNVPA]
VERBOSE: Assigned MAC 001dd8000010 to [TT-MTGW-GRE01B] [Transit]
VERBOSE: VM TT-NC01A is a Network Controller
VERBOSE: VM TT-MUX01A is a MUX
VERBOSE: VM TT-MTGW01A is a Gateway or Other
VERBOSE: VM TT-MTGW01A is a Gateway or Other
VERBOSE: VM TT-MTGW01A is a Gateway or Other
VERBOSE: VM TT-NC01B is a Network Controller
VERBOSE: VM TT-MUX01B is a MUX
VERBOSE: VM TT-MTGW-GRE01A is a Gateway or Other
VERBOSE: VM TT-MTGW-GRE01A is a Gateway or Other
VERBOSE: VM TT-MTGW-GRE01A is a Gateway or Other
VERBOSE: VM TT-NC01C is a Network Controller
VERBOSE: VM TT-MTGW01B is a Gateway or Other
VERBOSE: VM TT-MTGW01B is a Gateway or Other
VERBOSE: VM TT-MTGW01B is a Gateway or Other
VERBOSE: VM TT-MTGW-GRE01B is a Gateway or Other
VERBOSE: VM TT-MTGW-GRE01B is a Gateway or Other
VERBOSE: VM TT-MTGW-GRE01B is a Gateway or Other
VERBOSE: Service Fabric ring members: TT-NC01A TT-NC01B TT-NC01C
VERBOSE: Setting a MuxVirtualServerResourceId to TT-MUX01A
VERBOSE: Setting a MuxResourceId to TT-MUX01A
VERBOSE: Setting Mux HnvPaMac to 00-1D-D8-00-00-01
VERBOSE: Setting a MuxVirtualServerResourceId to TT-MUX01B
VERBOSE: Setting a MuxResourceId to TT-MUX01B
VERBOSE: Setting Mux HnvPaMac to 00-1D-D8-00-00-06
VERBOSE: Setting a InternalNicMAC to 00-1D-D8-00-00-03
VERBOSE: Setting a ExternalNicMAC to 00-1D-D8-00-00-04
VERBOSE: Setting a ExternalIPAddress to
VERBOSE: Setting a ExternalLogicalNetwork to Transit
VERBOSE: Setting gateway VM InternalNicPortProfileId to TT-MTGW01A_Internal
VERBOSE: Setting gateway VM ExternalNicPortProfileId to TT-MTGW01A_external
VERBOSE: Gateway Internal MAC is 00-1D-D8-00-00-03 before normalization.
VERBOSE: Gateway External MAC is 00-1D-D8-00-00-04 before normalization.
VERBOSE: Setting gateway node InternalNicPortProfileId to TT-MTGW01A_Internal
VERBOSE: Setting gateway node ExternalNicPortProfileId to TT-MTGW01A_External
VERBOSE: Setting a InternalNicMAC to 00-1D-D8-00-00-08
VERBOSE: Setting a ExternalNicMAC to 00-1D-D8-00-00-09
VERBOSE: Setting a ExternalIPAddress to
VERBOSE: Setting a ExternalLogicalNetwork to Transit
VERBOSE: Setting gateway VM InternalNicPortProfileId to TT-MTGW-GRE01A_Internal
VERBOSE: Setting gateway VM ExternalNicPortProfileId to TT-MTGW-GRE01A_external
VERBOSE: Gateway Internal MAC is 00-1D-D8-00-00-08 before normalization.
VERBOSE: Gateway External MAC is 00-1D-D8-00-00-09 before normalization.
VERBOSE: Setting gateway node InternalNicPortProfileId to TT-MTGW-GRE01A_Internal
VERBOSE: Setting gateway node ExternalNicPortProfileId to TT-MTGW-GRE01A_External
VERBOSE: Setting a InternalNicMAC to 00-1D-D8-00-00-0C
VERBOSE: Setting a ExternalNicMAC to 00-1D-D8-00-00-0D
VERBOSE: Setting a ExternalIPAddress to
VERBOSE: Setting a ExternalLogicalNetwork to Transit
VERBOSE: Setting gateway VM InternalNicPortProfileId to TT-MTGW01B_Internal
VERBOSE: Setting gateway VM ExternalNicPortProfileId to TT-MTGW01B_external
VERBOSE: Gateway Internal MAC is 00-1D-D8-00-00-0C before normalization.
VERBOSE: Gateway External MAC is 00-1D-D8-00-00-0D before normalization.
VERBOSE: Setting gateway node InternalNicPortProfileId to TT-MTGW01B_Internal
VERBOSE: Setting gateway node ExternalNicPortProfileId to TT-MTGW01B_External
VERBOSE: Setting a InternalNicMAC to 00-1D-D8-00-00-0F
VERBOSE: Setting a ExternalNicMAC to 00-1D-D8-00-00-10
VERBOSE: Setting a ExternalIPAddress to
VERBOSE: Setting a ExternalLogicalNetwork to Transit
VERBOSE: Setting gateway VM InternalNicPortProfileId to TT-MTGW-GRE01B_Internal
VERBOSE: Setting gateway VM ExternalNicPortProfileId to TT-MTGW-GRE01B_external
VERBOSE: Gateway Internal MAC is 00-1D-D8-00-00-0F before normalization.
VERBOSE: Gateway External MAC is 00-1D-D8-00-00-10 before normalization.
VERBOSE: Setting gateway node InternalNicPortProfileId to TT-MTGW-GRE01B_Internal
VERBOSE: Setting gateway node ExternalNicPortProfileId to TT-MTGW-GRE01B_External
VERBOSE: Finished populating defaults.
VERBOSE: --------------------------------------------
VERBOSE: --- Performing pre-deployment validation ---
VERBOSE: --------------------------------------------
VERBOSE: nc01.corp.technologytoolbox.com
VERBOSE: PASSED: network controller DNS registration test.
VERBOSE: TT-HV05A
FAILED: DNS lookup test for host name: 'TT-HV05A'.
REASON: TT-HV05A has more than one entry in DNS this will cause SLB to not function correctly.
ACTION: (1) Make sure management adapter on host 'TT-HV05A' is the only adapter configured to register itself in DNS.
ACTION: (2) Use ipconfig /registerdns on 'TT-HV05A' to force it to re-register.
ACTION: (3) Use ipconfig /flushdns to flush entries from this computer's DNS cache.
ACTION: (4) Verify that only one address is returned from 'resolve-dnsname TT-HV05A' cmdlet.
VERBOSE: PASSED: WINRM reachability test to 'TT-HV05A'.
VERBOSE: PASSED: Remote powershell test to 'TT-HV05A'.
VERBOSE: TT-HV05B
FAILED: DNS lookup test for host name: 'TT-HV05B'.
REASON: TT-HV05B has more than one entry in DNS this will cause SLB to not function correctly.
ACTION: (1) Make sure management adapter on host 'TT-HV05B' is the only adapter configured to register itself in DNS.
ACTION: (2) Use ipconfig /registerdns on 'TT-HV05B' to force it to re-register.
ACTION: (3) Use ipconfig /flushdns to flush entries from this computer's DNS cache.
ACTION: (4) Verify that only one address is returned from 'resolve-dnsname TT-HV05B' cmdlet.
VERBOSE: PASSED: WINRM reachability test to 'TT-HV05B'.
VERBOSE: PASSED: Remote powershell test to 'TT-HV05B'.
VERBOSE: TT-HV05C
FAILED: DNS lookup test for host name: 'TT-HV05C'.
REASON: TT-HV05C has more than one entry in DNS this will cause SLB to not function correctly.
ACTION: (1) Make sure management adapter on host 'TT-HV05C' is the only adapter configured to register itself in DNS.
ACTION: (2) Use ipconfig /registerdns on 'TT-HV05C' to force it to re-register.
ACTION: (3) Use ipconfig /flushdns to flush entries from this computer's DNS cache.
ACTION: (4) Verify that only one address is returned from 'resolve-dnsname TT-HV05C' cmdlet.
VERBOSE: PASSED: WINRM reachability test to 'TT-HV05C'.
VERBOSE: PASSED: Remote powershell test to 'TT-HV05C'.
VERBOSE: --------------------------------------------
VERBOSE: ---  Pre-deployment validation complete  ---
VERBOSE: ---     Validation found 03 error(s).    ---
VERBOSE: --------------------------------------------
VERBOSE: Exiting due to validation errors.  Use -skipvalidation to ignore errors.
PS D:\NotBackedUp\SDN\SDNExpress\scripts>
```

### Solution

```PowerShell
Get-NetIPConfiguration -InterfaceAlias "Storage-10" |
    Get-NetConnectionProfile |
    Set-DnsClient -RegisterThisConnectionsAddress:$false -Verbose

Get-NetIPConfiguration -InterfaceAlias "Storage-13" |
    Get-NetConnectionProfile |
    Set-DnsClient -RegisterThisConnectionsAddress:$false -Verbose

Get-NetIPConfiguration -InterfaceAlias "vEthernet (Live Migration)" |
    Get-NetConnectionProfile |
    Set-DnsClient -RegisterThisConnectionsAddress:$false -Verbose

ipconfig /registerdns
```

## Issue -

```Text
PS D:\NotBackedUp\SDN\SDNExpress\scripts> .\SDNExpress.ps1 -ConfigurationDataFile .\FabricConfig.TECHTOOLBOX.psd1 -Verbose
VERBOSE: Using configuration from file [.\FabricConfig.TECHTOOLBOX.psd1]
VERBOSE: STAGE 1: Housekeeping
...
VERBOSE: STAGE 2.1: Compile DSC resources
...

    Directory: D:\NotBackedUp\SDN\SDNExpress\scripts\AddGatewayNetworkAdapters


Mode                LastWriteTime         Length Name
----                -------------         ------ ----
-a----        7/30/2018   7:28 AM          90058 TT-HV05A.mof
-a----        7/30/2018   7:28 AM          90258 TT-HV05B.mof
-a----        7/30/2018   7:28 AM         190382 TT-HV05C.mof
PSDesiredStateConfiguration\Node : The term 'Get-VMSwitchExtensionPortFeature' is not recognized as the name of a
cmdlet, function, script file, or operable program. Check the spelling of the name, or if a path was included, verify
that the path is correct and try again.
At D:\NotBackedUp\SDN\SDNExpress\scripts\SDNExpress.ps1:1942 char:5
+     Node $AllNodes.Where{$_.ServiceFabricRingMembers -ne $null}.NodeN ...
+     ~~~~
    + CategoryInfo          : ObjectNotFound: (Get-VMSwitchExtensionPortFeature:String) [PSDesiredStateConfiguration\node], ParentContainsErrorRecordException
    + FullyQualifiedErrorId : CommandNotFoundException,PSDesiredStateConfiguration\node

Compilation errors occurred while processing configuration 'ConfigureGatewayNetworkAdapterPortProfiles'. Please review
the errors reported in error stream and modify your configuration code appropriately.
At
C:\windows\system32\WindowsPowerShell\v1.0\Modules\PSDesiredStateConfiguration\PSDesiredStateConfiguration.psm1:3917
char:5
+     throw $ErrorRecord
+     ~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidOperation: (ConfigureGatewa...terPortProfiles:String) [], InvalidOperationException
    + FullyQualifiedErrorId : FailToProcessConfiguration
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9F/5E488D17719CC9C85AAD662331E3795CA7D66E9F.png)

Screen clipping taken: 7/30/2018 7:33 AM

## Issue -

### Solution

```PowerShell
Disable-VMSwitchExtension `
    -VMSwitchName "Embedded Team Switch" `
    -Name "Microsoft Azure VFP Switch Extension"
```

## Issue -

### Solution

```Console
robocopy \\TT-FS01\Public\NCHostAgent C:\ProgramData\Microsoft\Windows\NcHostAgent

copy \\TT-FS01\Public\NcHostAgent.reg C:\NotBackedUp\Temp

regedit /S C:\NotBackedUp\Temp\NcHostAgent.reg
```

```Text
(!(*Port in [3389, 1494, 1503])) AND
((IPv4.Source == 10.1.15.49) OR
(IPv4.Destination == 10.1.15.49))
```


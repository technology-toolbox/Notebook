# Replace Production VM network

Tuesday, August 14, 2018
10:24 AM

```PowerShell
cls
```

## # Remove dependent resources

### # Disconnect VMs from VM network

```PowerShell
$vmNetwork = Get-SCVMNetwork "Production VM Network"

Get-SCVirtualMachine |
    sort Name |
    foreach {
        $vm = $_
        $vmName = $vm.Name

        $vm |
            Get-SCVirtualNetworkAdapter |
            where { $_.VMNetwork -eq $vmNetwork } |
            foreach {
                Write-Host "Updating network configuration on $vmName..."

                If ($vm.VirtualMachineState -ne "PowerOff")
                {
                    Stop-SCVirtualMachine -VM $vm -Verbose |
                        select Name, MostRecentTask, MostRecentTaskUIState
                }

                Set-SCVirtualNetworkAdapter `
                    -VirtualNetworkAdapter $_ `
                    -NoConnection |
                    select Name, MostRecentTask, MostRecentTaskUIState
            }
    }
```

```PowerShell
cls
```

### # Revoke static IP addresses

```PowerShell
Get-SCStaticIPAddressPool -Name "Production-15 Address Pool" |
    Get-SCIPAddress |
    Revoke-SCIPAddress
```

### # Remove static IP address pool

```PowerShell
Get-SCStaticIPAddressPool -Name "Production-15 Address Pool" |
    Remove-SCStaticIPAddressPool
```

### # Remove VM network

```PowerShell
Get-SCVMNetwork -Name "Production VM Network" |
    Remove-SCVMNetwork
```

```PowerShell
cls
```

### # Remove network site from uplink port profile

```PowerShell
$logicalNetworkDefinition = Get-SCLogicalNetworkDefinition -Name "Production - VLAN 15"

$portProfile = Get-SCNativeUplinkPortProfile -Name "Trunk Uplink"

$logicalNetworkDefinitionsToRemove = @()
$logicalNetworkDefinitionsToRemove += $logicalNetworkDefinition

Set-SCNativeUplinkPortProfile `
    -NativeUplinkPortProfile $portProfile `
    -RemoveLogicalNetworkDefinition $logicalNetworkDefinitionsToRemove
```

### # Remove network site (a.k.a. logical network definition)

```PowerShell
Remove-SCLogicalNetworkDefinition $logicalNetworkDefinition
```

### Create network site and VM network

```PowerShell
cls
```

### # Connect domain controllers to VM network

```PowerShell
@("CON-DC1",
    "CON-DC2") |
    foreach {
        $vmName = $_
        $vm = Get-SCVirtualMachine -Name $vmName

        $vm |
            Get-SCVirtualNetworkAdapter |
            where { $_.SlotId -eq 0 } |
            foreach {
                Write-Host "Updating network configuration on $vmName..."

                Set-SCVirtualNetworkAdapter `
                    -VirtualNetworkAdapter $_ `
                    -VMNetwork $vmNetwork

                Start-SCVirtualMachine -VM $vm |
                        select Name, MostRecentTask, MostRecentTaskUIState
            }
    }
```

---

**CON-DC1** - Run as administrator

```PowerShell
cls
```

### # Remove stale network adapters

\$env:devmgr_show_nonpresent_devices = 1

```Console
start devmgmt.msc
```

```Console
cls
```

### # Configure network adapter

```PowerShell
$interfaceAlias = "Contoso-60"
```

#### # Rename network connection

```PowerShell
Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

#### # Configure static IP address

```PowerShell
$ipAddress = "10.0.60.2"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24 `
    -DefaultGateway 10.0.60.1

Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 10.0.60.3, 127.0.0.1
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014
```

```PowerShell
cls
```

## # Configure Contoso-60 network

### # Add subnet to Active Directory site

```PowerShell
$siteName = "Contoso-HQ"

New-ADReplicationSubnet -Name "10.0.60.0/24" -Site $siteName
```

### # Add reverse lookup zone in DNS

```PowerShell
Add-DnsServerPrimaryZone `
    -NetworkID "10.0.60.0/24" `
    -ReplicationScope Forest
```

---

---

**CON-DC2** - Run as administrator

```PowerShell
cls
```

### # Remove stale network adapters

\$env:devmgr_show_nonpresent_devices = 1

```Console
start devmgmt.msc
```

```Console
cls
```

### # Configure network adapter

```PowerShell
$interfaceAlias = "Contoso-60"
```

#### # Rename network connection

```PowerShell
Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

#### # Configure static IP address

```PowerShell
$ipAddress = "10.0.60.3"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24 `
    -DefaultGateway 10.0.60.1

Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 10.0.60.2, 127.0.0.1
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping CON-DC1 -f -l 8900
```

---

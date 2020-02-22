# Replace Fabrikam VM network

Tuesday, August 14, 2018
10:24 AM

```PowerShell
cls
```

## # Remove dependent resources

### # Disconnect VMs from VM network

```PowerShell
$vmNetwork = Get-SCVMNetwork "Fabrikam VM Network"

Get-SCVirtualMachine |
    sort Name -Descending |
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
Get-SCStaticIPAddressPool -Name "Fabrikam-40 Address Pool" |
    Get-SCIPAddress |
    Revoke-SCIPAddress
```

```PowerShell
cls
```

### # Connect domain controllers to VM network

```PowerShell
@("FAB-DC01",
    "FAB-DC02") |
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

**FAB-DC01** - Run as administrator

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
$interfaceAlias = "Fabrikam-40"
```

#### # Rename network connection

```PowerShell
Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

#### # Configure static IP address

```PowerShell
$ipAddress = "10.0.40.2"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24 `
    -DefaultGateway 10.0.40.1

Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 10.0.40.3, 127.0.0.1
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

## # Configure Fabrikam-40 network

### # Add subnet to Active Directory site

```PowerShell
$siteName = "Fabrikam-HQ"

New-ADReplicationSubnet -Name "10.0.40.0/24" -Site $siteName
```

### # Add reverse lookup zone in DNS

```PowerShell
Add-DnsServerPrimaryZone `
    -NetworkID "10.0.40.0/24" `
    -ReplicationScope Forest
```

---

---

**FAB-DC02** - Run as administrator

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
$interfaceAlias = "Fabrikam-40"
```

#### # Rename network connection

```PowerShell
Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

#### # Configure static IP address

```PowerShell
$ipAddress = "10.0.40.3"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24 `
    -DefaultGateway 10.0.40.1

Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 10.0.40.2, 127.0.0.1
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping FAB-DC01 -f -l 8900
```

---

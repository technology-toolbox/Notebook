# EXT-DC03 - Windows Server 2012 R2 Datacenter

Monday, March 02, 2015
4:03 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Create VM using Azure portal

```PowerShell
cls
```

## # Download PowerShell help files

```PowerShell
Update-Help
```

## # Join domain

```PowerShell
Add-Computer -DomainName extranet.technologytoolbox.com -Restart
```

## Configure VM storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label      | Host Cache |
| ---- | ------------ | ----------- | -------------------- | ----------------- | ---------- |
| 0    | C:           | 127 GB      | 4K                   |                   | Read/Write |
| 1    | D:           | 20 GB       | 4K                   | Temporary Storage |            |
| 2    | F:           | 5 GB        | 4K                   | Data01            | None       |

Add data disk (F:)

## # [WOLVERINE] Configure static IPv4 address

```PowerShell
$cloudService = "techtoolbox-extranet"
$vmName = "EXT-DC03"
$ipAddress = "10.71.2.100"

Get-AzureVM -ServiceName $cloudService -Name $vmName |
    Set-AzureStaticVNetIP -IPAddress $ipAddress |
    Update-AzureVM
```

```PowerShell
cls
```

# Configure setting for Azure VM to create reverse DNS record

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

Reference:

**Enabling DNS Reverse lookup in Azure IaaS**\
From <[http://blogs.technet.com/b/denisrougeau/archive/2014/02/27/enabling-dns-reverse-lookup-in-azure-iaas.aspx](http://blogs.technet.com/b/denisrougeau/archive/2014/02/27/enabling-dns-reverse-lookup-in-azure-iaas.aspx)>

## # Install Active Directory Domain Services

```PowerShell
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools -Restart
```

## # Promote server to domain controller

```PowerShell
Import-Module ADDSDeployment

Install-ADDSDomainController `
    -NoGlobalCatalog:$false `
    -CreateDnsDelegation:$false `
    -Credential (Get-Credential) `
    -CriticalReplicationOnly:$false `
    -DatabasePath "F:\Windows\NTDS" `
    -DomainName "extranet.technologytoolbox.com" `
    -InstallDns:$true `
    -LogPath "F:\Windows\NTDS" `
    -NoRebootOnCompletion:$false `
    -SiteName "Azure-West-US" `
    -SysvolPath "F:\Windows\SYSVOL" `
    -Force:$true
```

## Configure ACLs on endpoints

### PowerShell endpoint

| **Order** | **Description**    | **Action** | **Remote Subnet** |
| --------- | ------------------ | ---------- | ----------------- |
| 0         | Technology Toolbox | Permit     | 50.246.207.160/30 |

### Remote Desktop endpoint

| **Order** | **Description**    | **Action** | **Remote Subnet** |
| --------- | ------------------ | ---------- | ----------------- |
| 0         | Technology Toolbox | Permit     | 50.246.207.160/30 |

```PowerShell
$vm = Get-AzureVM -ServiceName techtoolbox-mgmt -Name EXT-DC03

$endpointNames = "PowerShell", "Remote Desktop"

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

## # Copy Toolbox content

```PowerShell
net use "\\iceman.corp.technologytoolbox.com\Public" /USER:TECHTOOLBOX\jjameson

robocopy \\iceman.corp.technologytoolbox.com\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E
```

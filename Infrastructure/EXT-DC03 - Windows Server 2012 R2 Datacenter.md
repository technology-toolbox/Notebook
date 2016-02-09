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

```PowerShell
cls
```

## # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

## # Configure firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
New-NetFirewallRule `
    -Name 'Remote Windows Update (Dynamic RPC)' `
    -DisplayName 'Remote Windows Update (Dynamic RPC)' `
    -Description 'Allows remote auditing and installation of Windows updates via POSHPAIG (http://poshpaig.codeplex.com/)' `
    -Group 'Technology Toolbox (Custom)' `
    -Program '%windir%\system32\dllhost.exe' `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort RPC `
    -Profile Domain `
    -Action Allow
```

```PowerShell
cls
```

## # Install and configure System Center Operations Manager

### # Create certificate for Operations Manager

#### # Create request for Operations Manager certificate

```PowerShell
& "C:\NotBackedUp\Public\Toolbox\Operations Manager\Scripts\New-OperationsManagerCertificateRequest.ps1"
```

#### Submit certificate request to the Certification Authority

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

```PowerShell
cls
```

### # Install SCOM agent

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

### # Import the certificate into Operations Manager using MOMCertImport

```PowerShell
$hostName = ([System.Net.Dns]::GetHostByName(($env:computerName))).HostName

$certImportToolPath = $imageDriveLetter + ':\SupportTools\AMD64'

cd "$certImportToolPath"

.\MOMCertImport.exe /SubjectName $hostName
```

### # Approve manual agent install in Operations Manager

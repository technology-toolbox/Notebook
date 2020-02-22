# FAB-WAP01 - Windows Server 2012 R2

Thursday, June 04, 2015
2:03 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

### Install Windows Server 2012 R2

---

**WOLVERINE** - Run as administrator

```PowerShell
$VerbosePreference = "Continue"
```

```PowerShell
cls
# Get list of Windows Server 2012 R2 images

Get-AzureVMImage |
    where { $_.Label -like "Windows Server 2012 R2*" } |
    select Label, ImageName

# Use latest OS image

$imageName = `
    "a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-R2-201505.01-en.us-127GB.vhd"
```

```PowerShell
cls
# Create VM

$localAdminCred = Get-Credential `
    -UserName Administrator `
    -Message "Type the user name and password for the local Administrator account."

$domainCred = Get-Credential `
    -UserName jjameson-admin `
    -Message "Type the user name and password for joining the domain."

$storageAccount = "fabrikam3"
$location = "West US"
$vmName = "FAB-WAP01"
$cloudService = "fab-wap"
$instanceSize = "Basic_A1"
$vhdPath = "https://$storageAccount.blob.core.windows.net/vhds/$vmName"
$localAdminUserName = $localAdminCred.UserName
$localPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR(
        $localAdminCred.Password))

$dns1 = New-AzureDns -Name FAB-DC01 -IPAddress 192.168.10.201
$dns2 = New-AzureDns -Name FAB-DC02 -IPAddress 192.168.10.202
$domainName = "FABRIKAM"
$fqdn = "corp.fabrikam.com"
$domainUserName = $domainCred.UserName
$domainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR(
        $domainCred.Password))

$orgUnit = "OU=Azure,OU=Servers,OU=Resources,OU=IT,DC=corp,DC=fabrikam,DC=com"
$virtualNetwork = "West US VLAN1"
$subnetName = "Azure-Production"

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
        -MachineObjectOU $orgUnit |
    Set-AzureSubnet -SubnetNames $subnetName

New-AzureVM `
    -ServiceName $cloudService `
    -Location $location `
    -VNetName $virtualNetwork `
    -DnsSettings $dns1, $dns2 `
    -VMs $vmConfig
```

---

### Configure ACLs on endpoints

#### PowerShell endpoint

| **Order** | **Description**    | **Action** | **Remote Subnet** |
| --------- | ------------------ | ---------- | ----------------- |
| 0         | Technology Toolbox | Permit     | 50.246.207.160/30 |

#### Remote Desktop endpoint

| **Order** | **Description**    | **Action** | **Remote Subnet** |
| --------- | ------------------ | ---------- | ----------------- |
| 0         | Technology Toolbox | Permit     | 50.246.207.160/30 |

---

**WOLVERINE** - Run as administrator

```PowerShell
$vmName = "FAB-WAP01"
$cloudService = "fab-wap"

$vm = Get-AzureVM -ServiceName $cloudService -Name $vmName

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

### # Disable Azure BGInfo extension (conflicts with FABRIKAM logon script)

---

**WOLVERINE** - Run as administrator

```PowerShell
$vmName = "FAB-WAP01"
$cloudService = "fab-wap"

Get-AzureVM -ServiceName $cloudService -Name $vmName |
    Set-AzureVMBGInfoExtension -Disable |
    Update-AzureVM
```

---

### # Copy Toolbox content

```PowerShell
net use \\ext-dc03.extranet.technologytoolbox.com\IPC$ /USER:EXTRANET\jjameson-admin

robocopy `
    \\ext-dc03.extranet.technologytoolbox.com\C$\NotBackedUp\Public\Toolbox `
    C:\NotBackedUp\Public\Toolbox /E
```

## Install and Configure the Web Application Proxy Server

### Reference

**Install and Configure the Web Application Proxy Server**\
From <[https://technet.microsoft.com/en-us/library/dn383662.aspx](https://technet.microsoft.com/en-us/library/dn383662.aspx)>

### Configure certificates

#### Enroll SSL certificate for AD FS

##### # Create certificate request

```PowerShell
mkdir D:\NotBackedUp\Temp

cd D:\NotBackedUp\Temp

C:\NotBackedUp\Public\Toolbox\PowerShell\New-CertificateRequest.ps1 `
    -Subject "CN=fs.fabrikam.com,OU=IT,O=Fabrikam Technologies,L=Denver,S=CO,C=US" `
    -SANs fs.fabrikam.com,enterpriseregistration.corp.fabrikam.com
```

##### # Create certificate using Active Directory Certificate Services

###### # Add ADCS website to the "Trusted sites" zone in Internet Explorer

```PowerShell
[string] $adcsHostname = "cipher01.corp.technologytoolbox.com"

[string] $adcsDomainName = $adcsHostname.Split('.')[-2..-1] -join '.'

[string] $adcsHost = $adcsHostname.Substring(
    0,
    $adcsHostName.Length - $adcsDomainName.Length -1)

[string] $registryKey = ("HKCU:\Software\Microsoft\Windows" `
    + "\CurrentVersion\Internet Settings\ZoneMap\EscDomains" `
    + "\" + $adcsDomainName)

If ((Test-Path $registryKey) -eq $false)
{
    New-Item $registryKey | Out-Null
}

$registryKey = $registryKey + "\" + $adcsHost

If ((Test-Path $registryKey) -eq $false)
{
    New-Item $registryKey | Out-Null
}

Set-ItemProperty -Path $registryKey -Name https -Value 2
```

###### # Open Internet Explorer and browse to the ADCS site

```PowerShell
& 'C:\Program Files (x86)\Internet Explorer\iexplore.exe' ("https://" + $adcsHostname)
```

###### Request certificate

1. On the **Welcome** page of the Active Directory Certificate Services site, in the **Select a task** section, click **Request a certificate**.
2. On the **Advanced Certificate Request** page, click **Submit a certificate request by using a base-64-encoded CMC or PKCS #10 file, or submit a renewal request by using a base-64-encoded PKCS #7 file.**
3. On the **Submit a Certificate Request or Renewal Request** page:
   1. In the **Saved Request** box, copy/paste the certificate request generated previously.
   2. In the **Certificate Template** dropdown list, select **Technology Toolbox Web Server**.
   3. Click **Submit >**.
4. When prompted to allow the Web site to perform a digital certificate operation on your behalf, click **Yes**.
5. On the **Certificate Issued** page, ensure the **DER encoded** option is selected and click **Download certificate**. When prompted to save the certificate file, click **Save**.
6. After the file is saved, open the download folder in Windows Explorer and rename the certificate file to match the subject name (i.e. **fs.fabrikam.com.cer**).

##### # Import certificate

```PowerShell
Import-Certificate `
    -FilePath "C:\Users\jjameson-admin\Downloads\certnew.cer" `
    -CertStoreLocation Cert:\LocalMachine\My
```

### # Install the Remote Access role

```PowerShell
Install-WindowsFeature Web-Application-Proxy -IncludeManagementTools
```

### # Configure Web Application Proxy

```PowerShell
$cert = Get-ChildItem -Path Cert:\LocalMachine\My |
    Where { $_.Subject -like "CN=fs.fabrikam.com,*" }

Install-WebApplicationProxy `
    -CertificateThumbprint $cert.Thumbprint `
    -FederationServiceName 'fs.fabrikam.com'
```

## # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

## # Configure firewall rules for [http://poshpaig.codeplex.com/](POSHPAIG)

```PowerShell
New-NetFirewallRule `
    -Name 'Remote Windows Update (DCOM-In)' `
    -DisplayName 'Remote Windows Update (DCOM-In)' `
    -Description 'Allows remote auditing and installation of Windows updates via POSHPAIG (http://poshpaig.codeplex.com/)' `
    -Group 'Remote Windows Update' `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 135 `
    -Profile Domain `
    -Action Allow

New-NetFirewallRule `
    -Name 'Remote Windows Update (Dynamic RPC)' `
    -DisplayName 'Remote Windows Update (Dynamic RPC)' `
    -Description 'Allows remote auditing and installation of Windows updates via POSHPAIG (http://poshpaig.codeplex.com/)' `
    -Group 'Remote Windows Update' `
    -Program '%windir%\system32\dllhost.exe' `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort RPC `
    -Profile Domain `
    -Action Allow

Enable-NetFirewallRule `
    -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)"

Enable-NetFirewallRule `
    -DisplayName "File and Printer Sharing (Echo Request - ICMPv6-In)"
```

## # Disable firewall rules for [http://poshpaig.codeplex.com/](POSHPAIG)

```PowerShell
Disable-NetFirewallRule -Group 'Remote Windows Update'
```

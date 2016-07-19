# EXT-RRAS1 - Windows Server 2012 R2 Standard

Monday, March 02, 2015
6:09 AM

```Console
12345678901234567890123456789012345678901234567890123456789012345678901234567890

PowerShell
```

## # [FORGE] Create virtual machine

```PowerShell
$vmName = "EXT-RRAS1"

New-VM `
    -Name $vmName `
    -Path C:\NotBackedUp\VMs `
    -MemoryStartupBytes 1GB `
    -SwitchName "Virtual LAN 2 - 192.168.10.x"

New-Item -ItemType Directory "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks"

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

$sysPrepedImage = "\\ICEMAN\VM-Library\VHDs\WS2012-R2-STD.vhdx"

Copy-Item $sysPrepedImage $vhdPath

Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath

Start-VM $vmName
```

Configure server settings

On the **Settings** page:

1. Ensure the following default values are selected:
   1. **Country or region: United States**
   2. **App language: English (United States)**
   3. **Keyboard layout: US**
2. Click **Next**.
3. Type the product key and then click **Next**.
4. Review the software license terms and then click **I accept**.
5. Type a password for the built-in administrator account and then click **Finish**.

```Console
PowerShell
```

## # Rename the server and join domain

```PowerShell
Rename-Computer -NewName EXT-RRAS1 -Restart
```

Wait for the VM to restart and then execute the following command to join the **EXTRANET** domain:

```Console
PowerShell
Add-Computer -DomainName extranet.technologytoolbox.com -Restart
```

```Console
cls
```

### # [FORGE] Add second network adapter to virtual machine

```PowerShell
$vmName = "EXT-RRAS1"

Stop-VM $vmName

Add-VMNetworkAdapter -VMName $vmName -SwitchName "Virtual LAN 2 - 192.168.10.x"

Start-VM $vmName
```

# Rename network connections

```PowerShell
Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "LAN 1 - 192.168.10.x"

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter #2" |
    Rename-NetAdapter -NewName "WAN"
```

## # Enable jumbo frames

```PowerShell
Set-NetAdapterAdvancedProperty `
    -Name "LAN 1 - 192.168.10.x" `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping ICEMAN -f -l 8900
```

```PowerShell
cls
```

## # Configure static IPv4 addresses

```PowerShell
$ipAddress = "192.168.10.219"

New-NetIPAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -IPAddress $ipAddress `
    -PrefixLength 24

Set-DNSClientServerAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -ServerAddresses 192.168.10.209,192.168.10.210

$ipAddress = "50.246.207.161"

New-NetIPAddress `
    -InterfaceAlias "WAN" `
    -IPAddress $ipAddress `
    -PrefixLength 24 `
    -DefaultGateway 50.246.207.162

# Note: No DNS servers are specified for "WAN" network adapter
```

```PowerShell
cls
```

## # Configure static IPv6 address

```PowerShell
$ipAddress = "2601:1:8200:6000::219"

New-NetIPAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -IPAddress $ipAddress `
    -PrefixLength 64

Set-DNSClientServerAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -ServerAddresses 2601:1:8200:6000::209,2601:1:8200:6000::210
```

```PowerShell
cls
```

# Configure WAN network adapter

```PowerShell
Disable-NetAdapterBinding `
    -Name "WAN" `
    -DisplayName "Client for Microsoft Networks"

Disable-NetAdapterBinding `
    -Name "WAN" `
    -DisplayName "File and Printer Sharing for Microsoft Networks"

$adapter = Get-WmiObject `
    -Class "Win32_NetworkAdapter" `
    -Filter "NetConnectionId = 'WAN'"

$adapterConfig = Get-WmiObject `
    -Class "Win32_NetworkAdapterConfiguration" `
    -Filter "Index= '$($adapter.DeviceID)'"

# Do not register this connection in DNS
$adapterConfig.SetDynamicDNSRegistration($false)

# Disable NetBIOS over TCP/IP
$adapterConfig.SetTcpipNetbios(2)

TODO:

Disable-NetAdapterBinding `
    -Name "WAN" `
    -DisplayName "Link-Layer Topology Discovery Mapper I/O Driver"

Disable-NetAdapterBinding `
    -Name "WAN" `
    -DisplayName "Link-Layer Topology Discovery Responder"
```

```PowerShell
cls
```

## # Change drive letter for DVD-ROM

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
```

## Install patches using Windows Update

- 1 important update available

## # Install RRAS role

```PowerShell
Install-WindowsFeature RemoteAccess -IncludeManagementTools
Install-WindowsFeature Routing -IncludeManagementTools
```

## # Install Site-to-Site VPN

```PowerShell
Install-RemoteAccess -VpnType VpnS2S
```

## # Add and configure S2S VPN interface

```PowerShell
Add-VpnS2SInterface `
    -Name "Azure VPN" `
    -Destination 23.101.195.227 `
    -Protocol IKEv2 `
    -AuthenticationMethod PSKOnly `
    -ResponderAuthenticationMethod PSKOnly `
    -NumberOfTries 3 `
    -IPv4Subnet @("10.71.0.0/16:100") `
    -SharedSecret {shared secret}

Set-VpnServerIPsecConfiguration -EncryptionType MaximumEncryption

Set-VpnS2SInterface -Name "Azure VPN" -InitiateConfigPayload $false -Force
```

## # Set S2S VPN connection to be persistent by editing the router.pbk file

```PowerShell
Function Invoke-WindowsApi(
    [string] $dllName,
    [Type] $returnType,
    [string] $methodName,
    [Type[]] $parameterTypes,
    [Object[]] $parameters
    )
{
  ## Begin to build the dynamic assembly
  $domain = [AppDomain]::CurrentDomain
  $name = New-Object Reflection.AssemblyName 'PInvokeAssembly'
  $assembly = $domain.DefineDynamicAssembly($name, 'Run')
  $module = $assembly.DefineDynamicModule('PInvokeModule')
  $type = $module.DefineType('PInvokeType', "Public,BeforeFieldInit")

  $inputParameters = @()

  for($counter = 1; $counter -le $parameterTypes.Length; $counter++)
  {
     $inputParameters += $parameters[$counter - 1]
  }

  $method = $type.DefineMethod($methodName, 'Public,HideBySig,Static,PinvokeImpl',$returnType, $parameterTypes)

  ## Apply the P/Invoke constructor
  $ctor = [Runtime.InteropServices.DllImportAttribute].GetConstructor([string])
  $attr = New-Object Reflection.Emit.CustomAttributeBuilder $ctor, $dllName
  $method.SetCustomAttribute($attr)

  ## Create the temporary type, and invoke the method.
  $realType = $type.CreateType()

  $ret = $realType.InvokeMember($methodName, 'Public,Static,InvokeMethod', $null, $null, $inputParameters)

  return $ret
}

Function Set-PrivateProfileString(
    $file,
    $category,
    $key,
    $value)
{
  ## Prepare the parameter types and parameter values for the Invoke-WindowsApi script
  $parameterTypes = [string], [string], [string], [string]
  $parameters = [string] $category, [string] $key, [string] $value, [string] $file

  ## Invoke the API
  [void] (Invoke-WindowsApi "kernel32.dll" ([UInt32]) "WritePrivateProfileString" $parameterTypes $parameters)
}

Set-PrivateProfileString `
    $env:windir\System32\ras\router.pbk `
    "Azure VPN" `
    "IdleDisconnectSeconds" `
    "0"

Set-PrivateProfileString `
    $env:windir\System32\ras\router.pbk `
    "Azure VPN" `
    "RedialOnLinkFailure" `
    "1"
```

```PowerShell
cls
```

## # Restart the RRAS service

```PowerShell
Restart-Service RemoteAccess
```

```PowerShell
cls
```

## # Connect Azure VPN

```PowerShell
Connect-VpnS2SInterface -Name "Azure VPN"
```

## # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

```PowerShell
cls
```

## # Install and configure System Center Operations Manager

### # Create certificate for Operations Manager

#### Download Certification Authority certificate chain

1. Start Internet Explorer, and browse to Active Directory Certificate Services site ([https://cipher01.corp.technologytoolbox.com/](https://cipher01.corp.technologytoolbox.com/)).
2. On the **Welcome** page, click **Download a CA certificate, certificate chain, or CRL**.
3. On the **Download a CA Certificate, Certificate Chain, or CRL **page, click **Download CA certificate chain** and save the certificate chain to a file share ([\\\\iceman.corp.technologytoolbox.com\\Temp\\certnew.p7b](\\iceman.corp.technologytoolbox.com\Temp\certnew.p7b)).

```PowerShell
cls
```

#### # Import the certificate chain into the certificate store

---

**FOOBAR8**

### # Download root CA and issuing CA certificates

```PowerShell
$rootCertFile = "Technology Toolbox Root Certificate Authority.crt"

$source = "http://pki.technologytoolbox.com/certs/" + $rootCertFile

$destination = "\\iceman.corp.technologytoolbox.com\Temp\" + $rootCertFile

Invoke-WebRequest $source -OutFile $destination

$issuingCaCertFile = "Technology Toolbox Issuing Certificate Authority 01.crt"

$source = "http://pki.technologytoolbox.com/certs/" + $issuingCaCertFile

$destination = "\\iceman.corp.technologytoolbox.com\Temp\" + $issuingCaCertFile

Invoke-WebRequest $source -OutFile $destination
```

---

```PowerShell
$rootCert = "\\iceman.corp.technologytoolbox.com\Temp\Technology Toolbox Root Certificate Authority.crt"

CertUtil.exe -addstore Root $rootCert


$issuingCaCertFile = "\\iceman.corp.technologytoolbox.com\Temp\Technology Toolbox Issuing Certificate Authority 01.crt"

CertUtil.exe -addstore Root $rootCert
```

```PowerShell
cls
```

#### # Import the certificate chain into the certificate store

```PowerShell
$certChainFile = "\\iceman.corp.technologytoolbox.com\Temp\certnew.p7b"

CertReq.exe -Accept -machine $certChainFile

Remove-Item $certFile
```

#### # Create request for Operations Manager certificate

```PowerShell
net use \\iceman.corp.technologytoolbox.com\IPC$ /USER:TECHTOOLBOX\jjameson

& "C:\NotBackedUp\Public\Toolbox\Operations Manager\Scripts\New-OperationsManagerCertificateRequest.ps1" |
    Out-File \\iceman.corp.technologytoolbox.com\Temp\cert-req.txt
```

#### Submit certificate request to the Certification Authority

**To submit the certificate request to an enterprise CA:**

1. Start Internet Explorer, and browse to Active Directory Certificate Services site ([https://cipher01.corp.technologytoolbox.com/](https://cipher01.corp.technologytoolbox.com/)).
2. On the **Welcome** page, click **Request a certificate**.
3. On the **Advanced Certificate Request** page, click **Submit a certificate request by using a base-64-encoded CMC or PKCS #10 file, or submit a renewal request by using a base-64-encoded PKCS #7 file.**
4. On the **Submit a Certificate Request or Renewal Request** page, in the **Saved Request** text box, paste the contents of the certificate request generated in the previous procedure.
5. In the **Certificate Template** section, select the Operations Manager certificate template (**Technology Toolbox Operations Manager**), and then click **Submit**. When prompted to allow the digital certificate operation to be performed, click **Yes**.
6. On the **Certificate Issued** page click **Download certificate** and save the certificate to a file share ([\\\\iceman.corp.technologytoolbox.com\\Temp\\certnew.cer](\\iceman.corp.technologytoolbox.com\Temp\certnew.cer)).

```PowerShell
cls
```

#### # Import the certificate into the certificate store

```PowerShell
$certFile = "\\iceman.corp.technologytoolbox.com\Temp\certnew.cer"

CertReq.exe -Accept $certFile

Remove-Item $certFile
```

```PowerShell
cls
```

### # Install SCOM agent

---

**FOOBAR8**

```PowerShell
cls
```

#### # Mount the Operations Manager installation media

```PowerShell
$imagePath = `
    '\\ICEMAN\Products\Microsoft\System Center 2012 R2' `
    + '\en_system_center_2012_r2_operations_manager_x86_and_x64_dvd_2920299.iso'

Set-VMDvdDrive -ComputerName BEAST -VMName EXT-RRAS1 -Path $imagePath
```

---

```PowerShell
$msiPath = 'X:\agent\AMD64\MOMAgent.msi'

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

$certImportToolPath = 'X:\SupportTools\AMD64'

Push-Location "$certImportToolPath"

.\MOMCertImport.exe /SubjectName $hostName

Pop-Location
```

---

**FOOBAR8**

```PowerShell
cls
```

### # Remove the Operations Manager installation media

```PowerShell
Set-VMDvdDrive -ComputerName BEAST -VMName EXT-RRAS1 -Path $null
```

---

### # Approve manual agent install in Operations Manager

## # Update network settings

```PowerShell
$interfaceAlias = "Production"
```

### # Rename network connection

```PowerShell
Get-NetAdapter -Physical | select Name, InterfaceDescription

Get-NetAdapter `
    -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

### # Disable DHCP

```PowerShell
@("IPv4", "IPv6") | ForEach-Object {
    $addressFamily = $_

    $interface = Get-NetAdapter $interfaceAlias |
        Get-NetIPInterface -AddressFamily $addressFamily

    If ($interface.Dhcp -eq "Enabled")
    {
        # Remove existing gateway
        $ipConfig = $interface | Get-NetIPConfiguration

        If ($ipConfig.Ipv4DefaultGateway -or $ipConfig.Ipv6DefaultGateway)
        {
            $interface |
                Remove-NetRoute -AddressFamily $addressFamily -Confirm:$false
        }

        # Disable DHCP
        $interface | Set-NetIPInterface -DHCP Disabled
    }
}
```

### # Update static IPv6 address

```PowerShell
$oldIpAddress = "2601:1:8200:6000::219"
$newIpAddress = "2601:282:4201:e500::219"

Remove-NetIPAddress -IPAddress $oldIpAddress -Confirm:$false

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $newIpAddress `
    -PrefixLength 64
```

### # Update IPv6 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 2601:282:4201:e500::209,2601:282:4201:e500::210
```

## # Recreate S2S VPN interface

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3F/368D1BF856D544BAB764530D68B45E246B4CA93F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5A/3C1FF964225D17A2B3251A5A64DBCEC7A8D3AB5A.png)

```PowerShell
Remove-VpnS2SInterface -Name "Azure VPN"
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FA/50368F1FB51E070F76778E0532373B330E90ECFA.png)

```PowerShell
Add-VpnS2SInterface `
    -Name "Azure VPN" `
    -Destination 40.112.208.55 `
    -Protocol IKEv2 `
    -AuthenticationMethod PSKOnly `
    -ResponderAuthenticationMethod PSKOnly `
    -NumberOfTries 3 `
    -IPv4Subnet @("10.71.0.0/16:100") `
    -SharedSecret {shared secret}

Set-VpnServerIPsecConfiguration -EncryptionType MaximumEncryption

Set-VpnS2SInterface -Name "Azure VPN" -InitiateConfigPayload $false -Force
```

### # Set S2S VPN connection to be persistent by editing the router.pbk file

```PowerShell
Function Invoke-WindowsApi(
    [string] $dllName,
    [Type] $returnType,
    [string] $methodName,
    [Type[]] $parameterTypes,
    [Object[]] $parameters
    )
{
  ## Begin to build the dynamic assembly
  $domain = [AppDomain]::CurrentDomain
  $name = New-Object Reflection.AssemblyName 'PInvokeAssembly'
  $assembly = $domain.DefineDynamicAssembly($name, 'Run')
  $module = $assembly.DefineDynamicModule('PInvokeModule')
  $type = $module.DefineType('PInvokeType', "Public,BeforeFieldInit")

  $inputParameters = @()

  for($counter = 1; $counter -le $parameterTypes.Length; $counter++)
  {
     $inputParameters += $parameters[$counter - 1]
  }

  $method = $type.DefineMethod($methodName, 'Public,HideBySig,Static,PinvokeImpl',$returnType, $parameterTypes)

  ## Apply the P/Invoke constructor
  $ctor = [Runtime.InteropServices.DllImportAttribute].GetConstructor([string])
  $attr = New-Object Reflection.Emit.CustomAttributeBuilder $ctor, $dllName
  $method.SetCustomAttribute($attr)

  ## Create the temporary type, and invoke the method.
  $realType = $type.CreateType()

  $ret = $realType.InvokeMember($methodName, 'Public,Static,InvokeMethod', $null, $null, $inputParameters)

  return $ret
}

Function Set-PrivateProfileString(
    $file,
    $category,
    $key,
    $value)
{
  ## Prepare the parameter types and parameter values for the Invoke-WindowsApi script
  $parameterTypes = [string], [string], [string], [string]
  $parameters = [string] $category, [string] $key, [string] $value, [string] $file

  ## Invoke the API
  [void] (Invoke-WindowsApi "kernel32.dll" ([UInt32]) "WritePrivateProfileString" $parameterTypes $parameters)
}

Set-PrivateProfileString `
    $env:windir\System32\ras\router.pbk `
    "Azure VPN" `
    "IdleDisconnectSeconds" `
    "0"

Set-PrivateProfileString `
    $env:windir\System32\ras\router.pbk `
    "Azure VPN" `
    "RedialOnLinkFailure" `
    "1"
```

```PowerShell
cls
```

### # Restart the RRAS service

```PowerShell
Restart-Service RemoteAccess
```

```PowerShell
cls
```

### # Connect Azure VPN

```PowerShell
Connect-VpnS2SInterface -Name "Azure VPN"
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F5/BFCE3E53A37ECD5B0EAB68FE5C1100CDF93774F5.png)

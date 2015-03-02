# EXT-RRAS1 (2015-03-01) - Windows Server 2012 R2 Standard

Sunday, March 01, 2015
11:53 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## # [EXT-DC01] Create computer account in Active Directory OU

**# Note:** This is required to avoid Group Policy issues (e.g. enabling Terminal Services)

```PowerShell
$name = "EXT-RRAS1"
$path = "OU=VPN Servers,OU=Servers,OU=Resources,OU=IT,DC=extranet,DC=technologytoolbox,DC=com"

New-ADComputer -Name $name -Path $path
```

[MOONSTAR] Create VM

- Cores: 1
- Memory
  - Startup memory: 512 MB
  - Minimum memory: 32 MB (default)
  - Maximum memory: 2048 MB
  - Memory buffer percentage: 20 (default)
- Network adapters: 2
- Primary VHD
  - Size (GB): 32
  - File name: EXT-RRAS1

## Install Windows Server 2012 R2 with Update (Core)

Insert ISO image: **en_windows_server_2012_r2_with_update_x64_dvd_4065220.iso**

1. Ensure the following default values are selected:
   1. **Language to install: English (United States)**
   2. **Time and currency format: English (United States)**
   3. **Keyboard or input method: US**
2. Click **Next**.
3. Click **Install now**.
4. Type the product key and then click **Next**.
5. When prompted to select the operating system to install, ensure **Windows Server 2012 R2 Standard (Server Core Installation)** is selected, and then click **Next**.
6. Review the software license terms, select the **I accept the license terms** checkbox, and then click **Next**.
7. When prompted to select which type of installation, click **Custom: Install Windows only (advanced)**.
8. When prompted for where to install Windows, ensure **Drive 0 Unallocated Space** is selected and click **Next**.
9. Wait for Windows to be installed, and then specify the password for the Administrator account.

```Console
PowerShell
```

## # Set time zone

```PowerShell
tzutil /s "Mountain Standard Time"
```

# Rename network connections

```PowerShell
Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "LAN 1 - 192.168.10.x"

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter #2" |
    Rename-NetAdapter -NewName "WAN"
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

## # Disable IPv6 address on external network adapter

```PowerShell
Disable-NetAdapterBinding -Name "WAN" -ComponentID ms_tcpip6
```

```PowerShell
cls
```

## # Enable jumbo frames

```PowerShell
Set-NetAdapterAdvancedProperty `
    -Name "LAN 1 - 192.168.10.x" `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping ICEMAN.corp.technologytoolbox.com -f -l 8900
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

```PowerShell
cls
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

## Install patches using Windows Update (round 1)

- 57 important updates available

## Install patches using Windows Update (round 2)

- 2 important updates available

```Console
PowerShell
```

## # Install RRAS role

```PowerShell
Install-WindowsFeature RemoteAccess -IncludeManagementTools
Install-WindowsFeature Routing -IncludeManagementTools -Restart

PowerShell
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

```PowerShell
cls
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

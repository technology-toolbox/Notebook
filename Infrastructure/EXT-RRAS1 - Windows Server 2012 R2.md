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

# FAB-DC01 - Windows Server 2012 R2 Standard

Saturday, January 18, 2014
11:34 AM

```Console
12345678901234567890123456789012345678901234567890123456789012345678901234567890

PowerShell
```

## # Create virtual machine

```PowerShell
$vmName = "FAB-DC01"

New-VM `
    -Name $vmName `
    -Path C:\NotBackedUp\VMs `
    -MemoryStartupBytes 512MB `
    -SwitchName "Virtual LAN 2 - 192.168.10.x"

Set-VMMemory `
    -VMName $vmName `
    -DynamicMemoryEnabled $true `
    -MaximumBytes 2GB

$sysPrepedImage =
    "\\ICEMAN\VM Library\ws2012std-r2\Virtual Hard Disks\ws2012std-r2.vhd"

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

Convert-VHD `
    -Path $sysPrepedImage `
    -DestinationPath $vhdPath

Set-VHD $vhdPath -PhysicalSectorSizeBytes 4096

Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath

Start-VM $vmName
```

## # Rename the server and join domain

```PowerShell
Rename-Computer -NewName FAB-DC01 -Restart

Add-Computer -DomainName corp.fabrikam.com -Restart
```

## # Download PowerShell help files

```PowerShell
Update-Help
```

## # Change drive letter for DVD-ROM

### # To change the drive letter for the DVD-ROM using PowerShell

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
```

## # Rename network connection

```PowerShell
Get-NetAdapter -Physical

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "LAN 1 - 192.168.10.x"
```

## # Configure static IP address

```PowerShell
$ipAddress = "192.168.10.200"

New-NetIPAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -IPAddress $ipAddress `
    -PrefixLength 24 `
    -DefaultGateway 192.168.10.1

Set-DNSClientServerAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -ServerAddresses 192.168.10.208
```

## # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name "LAN 1 - 192.168.10.x" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

ping ICEMAN -f -l 8900
```

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
    -CriticalReplicationOnly:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -DomainName "corp.fabrikam.com" `
    -InstallDns:$true `
    -LogPath "C:\Windows\NTDS" `
    -NoRebootOnCompletion:$false `
    -SiteName "Default-First-Site-Name" `
    -SysvolPath "C:\Windows\SYSVOL"
```

## Enable Active Directory recycle bin

1. Open **Active Directory Administrative Center**
2. Click **Raise the domain functional level...**
   - Raise the domain functional level to **Windows Server 2008 R2**
3. Click **Raise the forest functional level...**
   - Raise the forest functional level to **Windows Server 2008 R2**
4. Click **Enable Recycle Bin...**

## # Rename service accounts

```PowerShell
$VerbosePreference = "Continue"

Get-ADUser -Filter {SamAccountName -like "svc-*"} |
    ForEach-Object {
        If ($_.Name -like "Service account *")
        {
            Write-Verbose "Renaming service account ($($_.SamAccountName))..."

            $newName = $_.Name.Replace("Service account", "Old service account")

            Write-Debug "Current name: $($_.Name)"
            Write-Debug "New name: $newName"

            Set-ADUser $_ -DisplayName $newName

            Rename-ADObject -Identity $_ -NewName $newName
        }
    }
```

```PowerShell
cls
```

## # Create service accounts for Fabrikam Demo applications

### # Create service account - "Service account for Fabrikam Web application (DEV)"

```PowerShell
$displayName = "Service account for Fabrikam Web application (DEV)"
$defaultUserName = "s-web-fabrikam-dev"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@corp.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=Development,DC=corp,DC=fabrikam,DC=com"

New-ADUser `
    -Name $displayName `
    -DisplayName $displayName `
    -SamAccountName $cred.UserName `
    -AccountPassword $cred.Password `
    -UserPrincipalName $userPrincipalName `
    -Path $orgUnit `
    -Enabled:$true `
    -CannotChangePassword:$true `
    -PasswordNeverExpires:$true
```

```PowerShell
cls
```

## # Configure service account for User Profile Synchronization

### # Create service account - "Service account for User Profile Synchronization (DEV)"

```PowerShell
$displayName = "Service account for User Profile Synchronization (DEV)"
$defaultUserName = "s-ups-dev"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@corp.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=Development,DC=corp,DC=fabrikam,DC=com"

New-ADUser `
    -Name $displayName `
    -DisplayName $displayName `
    -SamAccountName $cred.UserName `
    -AccountPassword $cred.Password `
    -UserPrincipalName $userPrincipalName `
    -Path $orgUnit `
    -Enabled:$true `
    -CannotChangePassword:$true `
    -PasswordNeverExpires:$true
```

### # Grant Replicate Directory Changes permission to UPS service account

```PowerShell
$serviceAccount = "FABRIKAM\s-ups-dev"

$rootDSE = [ADSI]"LDAP://RootDSE"
$defaultNamingContext = $rootDse.defaultNamingContext
$configurationNamingContext = $rootDse.configurationNamingContext
$userPrincipal = New-Object Security.Principal.NTAccount($serviceAccount)

dsacls.exe "$defaultNamingContext" /G "$($userPrincipal):CA;Replicating Directory Changes"
dsacls.exe "$configurationNamingContext" /G "$($userPrincipal):CA;Replicating Directory Changes"
```

> **Important**
>
> When the NetBIOS domain name is different than the FQDN, the Replicating Directory Changes permission must be granted on the Configuration Naming Context (as well as the domain itself).\
> Reference:
>
> **How to grant the Replicate Directory Change on the domain configuration partition**\
> From <[http://blogs.technet.com/b/steve_chen/archive/2010/09/20/user-profile-sync-sharepoint-2010.aspx](http://blogs.technet.com/b/steve_chen/archive/2010/09/20/user-profile-sync-sharepoint-2010.aspx)>

## Configure Active Directory sites

Rename default site

![(screenshot)](https://assets.technologytoolbox.com/screenshots/41/B628631B7CCFC0E8CE1C2708A6209141FF6F5F41.png)

Right-click **Default-First-Site-Name** and click **Rename**.\
Rename the site to **Fabrikam-HQ**.

Create site - "Azure-West-US"

Right-click **Sites** and click **New Site...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2D/ED1FA02879AE6D6EF2CC5D728DE0EB291F1A2A2D.png)

In the **Name** box, type **Azure-West-US**.\
In the list of site links, select **DEFAULTIPSITELINK**.\
Click **OK**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EE/6707DDB70DB3473FE1EC4A438E6A36D4ADF50BEE.png)

Click **OK**.

### Create subnets

| **Prefix**      | **Site**     |
| --------------- | ------------ |
| 10.71.0.0/16    | Azure-Web-US |
| 192.168.10.0/24 | Fabrikam-HQ  |

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B2/CFF43AF8F287B61729CC57A1479A1B01B560F4B2.png)

Right-click **Subnets** and click **New Subnet...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AF/29C3BE1E498600BC2E383606C349C20D1BD3D4AF.png)

In the **Prefix** box, type **10.71.0.0/16**.\
In the list of sites, select **Azure-West-US**.\
Click **OK**.

Repeat the steps to create the **192.168.10.0/24** subnet for the **Fabrikam-HQ** site.

## # Create DNS records for Fabrikam sites

#### # Create Host (A) record - "my.fabrikam.com"

```PowerShell
Add-DnsServerResourceRecordA `
    -Name "my" `
    -IPv4Address 10.71.4.100 `
    -ZoneName "fabrikam.com"
```

#### # Create Host (A) record - "portal.fabrikam.com"

```PowerShell
Add-DnsServerResourceRecordA `
    -Name "portal" `
    -IPv4Address 10.71.4.100 `
    -ZoneName "fabrikam.com"
```

## # Configure firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

---

**FOOBAR8**

```PowerShell
$cred = Get-Credential FABRIKAM\jjameson-admin

$computer = 'FAB-DC01'

$command = "New-NetFirewallRule ``
    -Name 'Remote Windows Update (Dynamic RPC)' ``
    -DisplayName 'Remote Windows Update (Dynamic RPC)' ``
    -Description 'Allows remote auditing and installation of Windows updates via POSHPAIG (http://poshpaig.codeplex.com/)' ``
    -Group 'Technology Toolbox (Custom)' ``
    -Program '%windir%\system32\dllhost.exe' ``
    -Direction Inbound ``
    -Protocol TCP ``
    -LocalPort RPC ``
    -Profile Domain ``
    -Action Allow"

$scriptBlock = [scriptblock]::Create($command)

Invoke-Command -ComputerName $computer -Credential $cred -ScriptBlock $scriptBlock
```

---

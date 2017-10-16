# CON-DC1 - Windows Server 2012 R2

Tuesday, December 6, 2016
9:10 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "FORGE"
$vmName = "CON-DC1"
$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path C:\NotBackedUp\VMs `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 2GB `
    -SwitchName "Production"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 2 `
    -StaticMemory

Set-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path \\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso

Start-VM -ComputerName $vmHost -Name $vmName
```

---

## Install custom Windows Server 2012 R2 image

- Start-up disk: [\\\\ICEMAN\\Products\\Microsoft\\MDT-Deploy-x86.iso](\\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso)
- On the **Task Sequence** step, select **Windows Server 2012 R2** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **CON-DC1**.
  - Select **Join a workgroup**.
  - In the **Workgroup** box, type **WORKGROUP**.
  - Click **Next**.
- On the Applications step:
  - Click **Next**.

```PowerShell
cls
```

## # Set password for local Administrator account

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

$password = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted for the secure string, type the password for the Administrator account.

```PowerShell
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

$adminUser = [ADSI] 'WinNT://./Administrator,User'
$adminUser.SetPassword($plainPassword)

logoff
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Remove disk from virtual CD/DVD drive

```PowerShell
$vmHost = "FORGE"
$vmName = "CON-DC1"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

---

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

## # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

```PowerShell
cls
```

## # Configure network settings

### # Rename network connection

```PowerShell
$interfaceAlias = "Production"

Get-NetAdapter -Physical

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

### # Configure static IP addresses

#### # Configure static IPv4 address

```PowerShell
$ipAddress = "192.168.10.231"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress `
    -PrefixLength 24 `
    -DefaultGateway 192.168.10.1
```

> **Note**
>
> After changing the IP address, Windows prompts for the network type (i.e. public or private).

```PowerShell
cls
```

#### # Configure static IPv6 address

```PowerShell
$ipAddress = "2603:300b:802:8900::231"

New-NetIPAddress `
    -InterfaceAlias $interfaceAlias `
    -IPAddress $ipAddress
```

### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

ping ICEMAN -f -l 8900
```

```PowerShell
cls
```

## # Install Active Directory Domain Services

```PowerShell
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools -Restart
```

> **Note**
>
> No restart was needed after installing AD DS.

```PowerShell
cls
```

## # Create Active Directory forest

```PowerShell
Import-Module ADDSDeployment

Install-ADDSForest `
    -CreateDnsDelegation:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -DomainMode "Win2012R2" `
    -DomainName "corp.contoso.com" `
    -DomainNetbiosName "CONTOSO" `
    -ForestMode "Win2012R2" `
    -InstallDns:$true `
    -LogPath "C:\Windows\NTDS" `
    -NoRebootOnCompletion:$false `
    -SysvolPath "C:\Windows\SYSVOL"
```

> **Note**
>
> When prompted, type the safe mode administrator password.

## # Enable Active Directory recycle bin

```PowerShell
Enable-ADOptionalFeature `
    -Identity "Recycle Bin Feature" `
    -Scope ForestOrConfigurationSet `
    -Target corp.contoso.com `
    -Confirm:$false
```

## # Rename default Active Directory site

```PowerShell
$siteName = "Default-First-Site-Name"
$newSiteName = "Contoso-HQ"

Get-ADReplicationSite -Identity $siteName |
    Rename-ADObject -NewName $newSiteName
```

## Promote CON-DC2 to domain controller

```PowerShell
cls
```

## # Configure DNS servers

```PowerShell
$interfaceAlias = "Production"

Set-DnsClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 192.168.10.232, 127.0.0.1

Set-DnsClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 2603:300b:802:8900::232, ::1
```

```PowerShell
cls
```

## # Create reverse lookup zones in DNS

```PowerShell
Add-DnsServerPrimaryZone -NetworkID "192.168.10.0/24" -ReplicationScope Forest

Add-DnsServerPrimaryZone `
    -NetworkID "2603:300b:802:8900::/64" `
    -ReplicationScope Forest
```

```PowerShell
cls
```

## # Create demo users

##### # Create OU for demo users

```PowerShell
New-ADOrganizationalUnit `
    -Name "Demo" `
    -Path "DC=corp,DC=contoso,DC=com"

New-ADOrganizationalUnit `
    -Name "Users" `
    -Path "OU=Demo,DC=corp,DC=contoso,DC=com"
```

##### # Copy input file

```PowerShell
net use \\ICEMAN\Public /USER:TECHTOOLBOX\jjameson

New-Item -Type Directory -Path C:\NotBackedUp\Temp

Copy-Item "\\ICEMAN\Public\Fake Users.csv" C:\NotBackedUp\Temp

cd C:\NotBackedUp\Temp

$password = ConvertTo-SecureString "{redacted}" -AsPlainText -Force
$orgUnit = "OU=Users,OU=Demo,DC=corp,DC=contoso,DC=com"

Import-Csv "Fake Users.csv" |
    ? { $_.NameSet -eq "American" } |
    select -First 5000 |
    % {
        $displayName = $_.GivenName + " " + $_.Surname
        $emailAddress = $_.Username + "@contoso.com"
        $userPrincipalName = $_.Username + "@corp.contoso.com"

        New-ADUser `
            -Name $displayName `
            -DisplayName $displayName `
            -GivenName $_.GivenName `
            -Surname $_.Surname `
            -EmailAddress $emailAddress `
            -OfficePhone $_.TelephoneNumber `
            -SamAccountName $_.Username `
            -AccountPassword $password `
            -UserPrincipalName $userPrincipalName `
            -Path $orgUnit `
            -Enabled:$true `
            -PasswordNeverExpires:$true
    }
```

```PowerShell
cls
```

## # Configure Active Directory organizational units

```PowerShell
New-ADOrganizationalUnit -Name IT -Path "DC=corp,DC=contoso,DC=com"
New-ADOrganizationalUnit `
    -Name "Admin Accounts" `
    -Path "OU=IT,DC=corp,DC=contoso,DC=com"

New-ADOrganizationalUnit -Name Groups -Path "OU=IT,DC=corp,DC=contoso,DC=com"

New-ADOrganizationalUnit -Name Resources -Path "OU=IT,DC=corp,DC=contoso,DC=com"
New-ADOrganizationalUnit `
    -Name Laptops `
    -Path "OU=Resources,OU=IT,DC=corp,DC=contoso,DC=com"

New-ADOrganizationalUnit `
    -Name Servers `
    -Path "OU=Resources,OU=IT,DC=corp,DC=contoso,DC=com"

New-ADOrganizationalUnit `
    -Name Workstations `
    -Path "OU=Resources,OU=IT,DC=corp,DC=contoso,DC=com"

New-ADOrganizationalUnit `
    -Name "Service Accounts" `
    -Path "OU=IT,DC=corp,DC=contoso,DC=com"

New-ADOrganizationalUnit `
    -Name "Setup Accounts" `
    -Path "OU=IT,DC=corp,DC=contoso,DC=com"

New-ADOrganizationalUnit -Name Users -Path "OU=IT,DC=corp,DC=contoso,DC=com"
```

```PowerShell
cls
```

## # Configure Windows Update

### # Create security groups for Windows Update

```PowerShell
New-ADGroup `
```

    -Name "Windows Update - Slot 17" `\
    -GroupCategory Security `\
    -GroupScope Global `\
    -Path "OU=Groups,OU=IT,DC=corp,DC=contoso,DC=com"

```PowerShell
New-ADGroup `
```

    -Name "Windows Update - Slot 21" `\
    -GroupCategory Security `\
    -GroupScope Global `\
    -Path "OU=Groups,OU=IT,DC=corp,DC=contoso,DC=com"

```PowerShell
New-ADGroup `
```

    -Name "Windows Update - Slot 22" `\
    -GroupCategory Security `\
    -GroupScope Global `\
    -Path "OU=Groups,OU=IT,DC=corp,DC=contoso,DC=com"

### # Add computers to security groups for Windows Update

```PowerShell
Add-ADGroupMember -Identity "Windows Update - Slot 17" -Members "CON-DC1$"
Add-ADGroupMember -Identity "Windows Update - Slot 21" -Members "CON-DC2$"
Add-ADGroupMember -Identity "Windows Update - Slot 22" -Members "CON-ADFS1$"
```

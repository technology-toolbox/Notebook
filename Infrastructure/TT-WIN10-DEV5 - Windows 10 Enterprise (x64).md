# TT-WIN10-DEV5 - Windows 10 Enterprise (x64)

Thursday, June 21, 2018
1:35 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure workstation

---

**WOLVERINE - Run as administrator**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmName = "TT-WIN10-DEV5"
$vmPath = "D:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 50GB `
    -MemoryStartupBytes 4GB `
    -SwitchName "Management"

Set-VM `
    -Name $vmName `
    -ProcessorCount 4 `
    -AutomaticCheckpointsEnabled $false

Start-VM -Name $vmName
```

---

### Install custom Windows 10 image

- On the **Task Sequence** step, select **Windows 10 Enterprise (x64)** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **TT-WIN10-DEV5**.
  - Click **Next**.
- On the **Applications** step:
  - Select the following applications:
    - **Adobe**
      - **Adobe Reader 8.3.1**
    - **Chrome**
      - **Chrome (64-bit)**
    - **Microsoft**
      - **Remote Server Administration Tools for Windows 10**
      - **SQL Server 2017 Management Studio**
    - **Mozilla**
      - **Firefox (64-bit)**
      - **Thunderbird**
  - Click **Next**.

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Move computer to different OU

```PowerShell
$vmName = "TT-WIN10-DEV5"

$targetPath = ("OU=Workstations,OU=Resources,OU=Development" `
    + ",DC=corp,DC=technologytoolbox,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

---

### Login as TECHTOOLBOX\\jjameson-admin

### # Rename local Administrator account and set password

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

$password = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted, type the password for the local Administrator account.

```PowerShell
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

$adminUser = [ADSI] 'WinNT://./Administrator,User'
$adminUser.Rename('foo')
$adminUser.SetPassword($plainPassword)
```

### # Enable local Administrator account

```PowerShell
$Disabled = 0x0002
$adminUser.UserFlags.Value = $adminUser.UserFlags.Value -bxor $Disabled
$adminUser.SetInfo()
```

#### Reference

**Managing Local User Accounts with PowerShell**\
From <[https://mcpmag.com/articles/2015/05/07/local-user-accounts-with-powershell.aspx](https://mcpmag.com/articles/2015/05/07/local-user-accounts-with-powershell.aspx)>

### Login as .\\foo

### # Copy Toolbox content

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$source = "\\TT-FS01\Public\Toolbox"
$destination = "C:\NotBackedUp\Public\Toolbox"

robocopy $source $destination /E /XD git-for-windows "Microsoft SDKs"
```

### # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

### # Configure networking

```PowerShell
$interfaceAlias = "Management"
```

#### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Start-Sleep -Seconds 5

ping TT-FS01 -f -l 8900
```

### Configure storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 50 GB       | 4K                   | OSDisk       |

```PowerShell
cls
```

## # Install Visual Studio 2017

### # Launch Visual Studio 2017 setup

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$setupPath = "\\TT-FS01\Products\Microsoft\Visual Studio 2017\Enterprise" `
    + "\vs_setup.exe"

Start-Process `
    -FilePath $setupPath `
    -Wait
```

Select the following workloads:

- **.NET desktop development**
- **ASP.NET and web development**
- **Office/SharePoint development**

> **Note**
>
> When prompted, restart the computer to complete the installation.

```PowerShell
cls
```

## # Install Git

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$setupPath = "\\TT-FS01\Products\Git\Git-2.16.2-64-bit.exe"

Start-Process `
    -FilePath $setupPath `
    -Wait
```

```PowerShell
cls
```

## # Install Visual Studio Code

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$setupPath = "\\TT-FS01\Products\Microsoft\Visual Studio Code" `
    + "\VSCodeSetup-x64-1.24.1.exe"

$arguments = "/silent" `
    + " /mergetasks='!runcode,addcontextmenufiles,addcontextmenufolders,addtopath'"

Start-Process `
    -FilePath $setupPath `
    -ArgumentList $arguments `
    -Wait
```

### Issue

**Installer doesn't disable launch of VScode even when installing with /mergetasks=!runcode**\
From <[https://github.com/Microsoft/vscode/issues/46350](https://github.com/Microsoft/vscode/issues/46350)>

```PowerShell
cls
```

## # Install Ruby

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$setupPath = "\\TT-FS01\Products\Ruby\rubyinstaller-devkit-2.4.4-1-x64.exe"

Start-Process `
    -FilePath $setupPath `
    -Wait
```

```PowerShell
cls
```

## # Install Ruby dependencies for debugging in Visual Studio Code

```Shell
gem install ruby-debug-ide

gem install debase
```

### Reference

**VS Code Ruby Extension**\
From <[https://github.com/rubyide/vscode-ruby#install-ruby-dependencies](https://github.com/rubyide/vscode-ruby#install-ruby-dependencies)>

```PowerShell
cls
```

## # Install Check Point VPN client

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$msiPath = "\\TT-FS01\Archive\Clients\Securitas\Check_Point_VPN_client" `
    + "\Securitas-USA-VPN_E80.72.msi"

$arguments = "/i `"$msiPath`" /qr"

Start-Process `
    -FilePath 'msiexec.exe' `
    -ArgumentList $arguments `
    -Wait
```

> **Note**
>
> When prompted, restart the computer to complete the installation.

## Install updates using Windows Update

> **Note**
>
> Repeat until there are no updates available for the computer.

```PowerShell
cls
```

## # Back up virtual machine

```PowerShell
$vmName = "TT-WIN10-DEV5"

Stop-VM $vmName

$exportPath = "Z:\Backup\VMs"

If ((Test-Path $exportPath) -eq $false)
{
    New-Item -ItemType Directory -Path $exportPath
}

Get-VM $vmName | Export-VM -Path $exportPath -Verbose
```

**TODO:**

## # Enter a product key and activate Windows

```PowerShell
slmgr /ipk {product key}
```

> **Note**
>
> When notified that the product key was set successfully, click **OK**.

```Console
slmgr /ato
```

## Activate Microsoft Office

1. Start Word 2016
2. Enter product key

## Install dependencies for building SharePoint solutions

### Install reference assemblies

```Console
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```Console
robocopy `
    '\\TT-FS01\Builds\Reference Assemblies' `
    'C:\Program Files\Reference Assemblies' /E

& 'C:\Program Files\Reference Assemblies\Microsoft\SharePoint v4\AssemblyFoldersEx - x64.reg'

& 'C:\Program Files\Reference Assemblies\Microsoft\SharePoint v5\AssemblyFoldersEx - x64.reg'
```

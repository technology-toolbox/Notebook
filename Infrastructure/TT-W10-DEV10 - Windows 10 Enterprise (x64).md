# TT-W10-DEV10 - Windows 10 Enterprise (x64)

Thursday, May 23, 2019\
9:30 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure workstation

---

**FOOBAR18** - Run as administrator

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "TT-W10-DEV10"
$vmPath = "D:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 50GB `
    -MemoryStartupBytes 4GB `
    -SwitchName "Embedded Team Switch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 4 `
    -AutomaticCheckpointsEnabled $false

Set-VMNetworkAdapterVlan `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Access `
    -VlanId 30

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Install custom Windows 10 image

- On the **Task Sequence** step, select **Windows 10 Enterprise (x64)** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **TT-W10-DEV10**.
  - Click **Next**.
- On the **Applications** step:
  - Select the following applications:
    - **Adobe**
      - **Adobe Reader 8.3.1**
    - **Chrome**
      - **Chrome (64-bit)**
    - **Microsoft**
      - **SQL Server 2017 Management Studio**
    - **Mozilla**
      - **Firefox (64-bit)**
      - **Thunderbird**
  - Click **Next**.

> **Note**
>
> After the custom Windows 10 image is installed, the following message is displayed:\
> This user can't sign in because this account is currently disabled.\
> Click **OK** to acknowledge the local Administrator account is disabled by default in Windows 10.

### Login as TECHTOOLBOX\\jjameson-fabric

> **Important**
>
> Wait for the "Install Applications" and other remaining deployment steps to complete before proceeding.

---

**FOOBAR18** - Run as administrator

```PowerShell
cls

$vmName = "TT-W10-DEV10"
```

### # Move computer to different OU

```PowerShell
$targetPath = ("OU=Workstations,OU=Resources,OU=Development" `
    + ",DC=corp,DC=technologytoolbox,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

### # Configure Windows Update

#### # Add machine to security group for Windows Update schedule

```PowerShell
Add-ADGroupMember -Identity "Windows Update - Slot 21" -Members ($vmName + '$')
```

---

### Rename local Administrator account and set password

---

**PowerShell** - Run as administrator

```PowerShell
cls
```

#### # Prompt for local Administrator password

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

$password = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted, type the password for the local Administrator account.

```PowerShell
$adminUser = [ADSI] 'WinNT://./Administrator,User'
```

#### # Rename local Administrator account

```PowerShell
$adminUser.Rename('foo')
```

#### # Set password for local Administrator account

```PowerShell
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

$adminUser.SetPassword($plainPassword)
```

#### # Enable local Administrator account

```PowerShell
$Disabled = 0x0002
$adminUser.UserFlags.Value = $adminUser.UserFlags.Value -bxor $Disabled
$adminUser.SetInfo()
```

---

#### Reference

**Managing Local User Accounts with PowerShell**\
From <[https://mcpmag.com/articles/2015/05/07/local-user-accounts-with-powershell.aspx](https://mcpmag.com/articles/2015/05/07/local-user-accounts-with-powershell.aspx)>

---

**FOOBAR18** - Run as administrator

```PowerShell
cls
```

### # Move VM to Production VM network

```PowerShell
$vmName = "TT-W10-DEV10"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Production VM Network"

Stop-SCVirtualMachine $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -MACAddressType Dynamic `
    -IPv4AddressType Dynamic

Start-SCVirtualMachine $vmName
```

---

### Login as .\\foo

### # Set MaxPatchCacheSize to 0 (recommended)

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

### # Configure networking

```PowerShell
$interfaceAlias = "Production"
```

#### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

```PowerShell
cls
```

## # Install SharePoint Online Management Shell

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$installerPath = "\\TT-FS01\Public\Download\Microsoft\SharePoint\Online" `
    + "\SharePointOnlineManagementShell_8316-1200_x64_en-us.msi"

Start-Process `
    -FilePath msiexec.exe `
    -ArgumentList "/i `"$installerPath`"" `
    -Wait
```

```PowerShell
cls
```

## # Install Visual Studio 2019

### # Launch Visual Studio 2019 setup

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$setupPath = "\\TT-FS01\Products\Microsoft\Visual Studio 2019\Enterprise" `
    + "\vs_setup.exe"

Start-Process -FilePath $setupPath -Wait
```

Select the following workloads:

- **ASP.NET and web development**
- **Azure development**
- **Python development**
- **Node.js development**
- **.NET desktop development**
- **Desktop development with C++**
- **Universal Windows Platform development**
- **Data storage and processing**
- **Data science and analytical applications**
- **Office/SharePoint development**
- **.NET Core cross-platform development**

> **Note**
>
> When prompted, restart the computer to complete the installation.

### Install Visual Studio 2019 updates

Open Visual Studio and install all updates (on the **Help** menu, select **Check for Updates**).

> **Note**
>
> When prompted, restart the computer to complete the updates.

```PowerShell
cls
```

## # Install and configure Git

### # Install Git

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$setupPath = "\\TT-FS01\Products\Git\Git-2.21.0-64-bit.exe"

Start-Process -FilePath $setupPath -Wait
```

On the **Choosing the default editor used by Git** step, select **Use the Nano editor by default**.

> **Important**
>
> Wait for the installation to complete and restart PowerShell for environment changes to take effect.

```Console
exit
```

```Console
cls
```

### # Configure symbolic link (e.g. for bash shell)

```PowerShell
Push-Location C:\NotBackedUp\Public\Toolbox\cmder\vendor

cmd /c mklink /J git-for-windows "C:\Program Files\Git"

Pop-Location
```

### # Configure Git to use SourceGear DiffMerge

```PowerShell
git config --global diff.tool diffmerge

git config --global difftool.diffmerge.cmd  '"C:/NotBackedUp/Public/Toolbox/DiffMerge/x64/sgdm.exe \"$LOCAL\" \"$REMOTE\"'
```

#### Reference

**Git for Windows (MSysGit) or Git Cmd**\
From <[https://sourcegear.com/diffmerge/webhelp/sec__git__windows__msysgit.html](https://sourcegear.com/diffmerge/webhelp/sec__git__windows__msysgit.html)>

```PowerShell
cls
```

## # Install GitHub Desktop

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$setupPath = "\\TT-FS01\Products\GitHub\GitHubDesktopSetup.exe"

Start-Process -FilePath $setupPath -Wait
```

> **Important**
>
> Wait for the installation to complete.

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
    + "\VSCodeSetup-x64-1.34.0.exe"

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
$setupPath = "\\TT-FS01\Products\Ruby\rubyinstaller-devkit-2.5.5-1-x64.exe"

Start-Process -FilePath $setupPath -Wait
```

> **Important**
>
> Wait for the installation to complete and restart PowerShell for environment changes to take effect.

```Console
exit
```

## # Install Ruby dependencies for debugging in Visual Studio Code

```Shell
gem install ruby-debug-ide

gem install debase
```

### Reference

**VS Code Ruby Extension**\
From <[https://github.com/rubyide/vscode-ruby#install-ruby-dependencies](https://github.com/rubyide/vscode-ruby#install-ruby-dependencies)>

## Install updates using Windows Update

> **Note**
>
> Repeat until there are no updates available for the computer.

## Allow remote access by all domain users

Add **TECHTOOLBOX\\Domain Users** to **Remote Desktop Users**.

```PowerShell
cls
```

## # Baseline virtual machine

```PowerShell
Restart-Computer
```

> **Important**
>
> Wait for the VM to reach idle state after restarting before continuing.

---

**FOOBAR18** - Run as administrator

```PowerShell
cls
```

### # Checkpoint VM

```PowerShell
$vmName = "TT-W10-DEV10"
$checkpointName = "Baseline"

Stop-SCVirtualMachine -VM $vmName

New-SCVMCheckpoint -VM $vmName -Name $checkpointName

Start-SCVirtualMachine -VM $vmName
```

---

## Back up virtual machine

### Add VM to Hyper-V protection group in Data Protection Manager

**TODO:**

```PowerShell
cls
```

## # Install Microsoft SQL Server 2017

### # Create folders for Distributed Replay Client

```PowerShell
mkdir "D:\NotBackedUp\Microsoft SQL Server\DReplayClient\WorkingDir\"
mkdir "D:\NotBackedUp\Microsoft SQL Server\DReplayClient\ResultDir\"
```

### # Install SQL Server

```PowerShell
net use \\TT-FS01\Products /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$sourcePath = "\\TT-FS01\Products\Microsoft\SQL Server 2017"
$destPath = "C:\NotBackedUp\Temp"
$isoFilename = "en_sql_server_2017_developer_x64_dvd_11296168.iso"

robocopy $sourcePath $destPath $isoFilename

$imagePath = "$destPath\$isoFilename"

Function Ensure-MountedDiskImage
{
    [CmdletBinding()]
    Param(
        [Parameter(Position = 1, Mandatory = $true)]
        [string] $ImagePath)

    $imageDriveLetter = (Get-DiskImage -ImagePath $ImagePath|
        Get-Volume).DriveLetter

    If ($imageDriveLetter -eq $null)
    {
        Write-Verbose "Mounting disk image ($ImagePath)..."
        $imageDriveLetter = (Mount-DiskImage -ImagePath $ImagePath -PassThru |
            Get-Volume).DriveLetter
    }

    return $imageDriveLetter
}

$imageDriveLetter = Ensure-MountedDiskImage $imagePath

If ((Get-Process -Name "setup" -ErrorAction SilentlyContinue) -eq $null)
{
    $setupPath = $imageDriveLetter + ':\setup.exe'

    Write-Verbose "Starting setup..."

    & $setupPath

    Start-Sleep -Seconds 15
}
```

On the **Feature Selection** step, click **Select All** and then clear the checkbox for **PolyBase Query Service for External Data **(since this requires the Java Runtime Environment to be installed).

On the **Server Configuration** page:

- For **SQL Server Database Engine**, change the **Startup Type** to **Manual**.
- For **SQL Server Analysis Services**, change the **Startup Type** to **Manual**.
- For **SQL Server Integration Services 14.0**, change the **Startup Type** to **Manual**.
- For **SQL Server Integration Services Scale Out Master 14.0**, change the **Startup Type** to **Manual**.
- For **SQL Server Integration Services Scale Out Worker 14.0**, change the **Startup Type** to **Manual**.

On the **Database Engine Configuration** page:

- On the **Server Configuration** tab, click **Add Current User**.
- On the **Data Directories** tab:
  - Change the **Data root directory** to **D:\\NotBackedUp\\Microsoft SQL Server\\**
  - Change the **Backup directory** to **Z:\\Microsoft SQL Server\\MSSQL14.MSSQLSERVER\\MSSQL\\Backup**

On the **Analysis Services Configuration** page:

- On the **Server Configuration** tab, click **Add Current User**.
- On the **Data Directories** tab:
  - Change the **Data directory** to **D:\\NotBackedUp\\Microsoft SQL Server\\MSAS14.MSSQLSERVER\\OLAP\\Data.**
  - Change the **Log file directory** to **D:\\NotBackedUp\\Microsoft SQL Server\\MSAS14.MSSQLSERVER\\OLAP\\Log.**
  - Change the **Temp directory** to **D:\\NotBackedUp\\Microsoft SQL Server\\MSAS14.MSSQLSERVER\\OLAP\\Temp.**
  - Change the **Backup directory** to **Z:\\NotBackedUp\\Microsoft SQL Server\\MSAS14.MSSQLSERVER\\OLAP\\Backup**.

On the **Distributed Replay Controller** page, click **Add Current User**.

On the **Distributed Replay Client** page:

- On the **Server Configuration** tab, click **Add Current User**.
  - Change the **Working Directory** to **D:\\NotBackedUp\\Microsoft SQL Server\\DReplayClient\\WorkingDir\\.**
  - Change the **Result Directory** to **D:\\NotBackedUp\\Microsoft SQL Server\\DReplayClient\\ResultDir\\.**

```PowerShell
cls
```

### # Remove installation media

```PowerShell
Dismount-DiskImage $imagePath

Remove-Item $imagePath -Confirm:$true
```

```PowerShell
cls
```

## # Install Microsoft Teams

```PowerShell
& "\\TT-FS01\Products\Microsoft\Teams\Teams_windows_x64.exe"
```

```PowerShell
cls
```

## # Install dependencies for building SharePoint solutions

### # Install reference assemblies

```PowerShell
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

```Console
cls
```

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

1. Start Microsoft Word
2. Enter product key

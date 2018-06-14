# TT-WIN10-DEV4 - Windows 10 Enterprise (x64)

Thursday, June 14, 2018
10:31 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure workstation

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "TT-WIN10-DEV4"
$vmPath = "D:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 80GB `
    -MemoryStartupBytes 4GB `
    -SwitchName "Embedded Team Switch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 4

Start-VM -ComputerName $vmHost -Name $vmName
```

---

### Install custom Windows 10 image

- On the **Task Sequence** step, select **Windows 10 Enterprise (x64)** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **TT-WIN10-DEV4**.
  - Click **Next**.
- On the **Applications** step:
  - Select the following applications:
    - **Adobe Reader 8.3.1**
    - **Chrome (64-bit)**
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
$vmName = "TT-WIN10-DEV4"

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
| 0    | C:           | 80 GB       | 4K                   | Windows      |

### Configure backup

#### Add virtual machine to Hyper-V protection group in DPM

```PowerShell
cls
```

## # Install Visual Studio 2008

```PowerShell
$imagePath = '\\TT-FS01\Products\Microsoft\Visual Studio 2008' `
    + '\en_visual_studio_team_system_2008_team_suite_x86_dvd_x14-26461.iso'

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

Start-Process `
    -FilePath "$imageDriveLetter`:\setup.exe" `
    -Wait

Dismount-DiskImage -ImagePath $imagePath
```

```PowerShell
cls
```

## # Install Visual Studio 2008 Team Explorer

```PowerShell
$imagePath = '\\TT-FS01\Products\Microsoft\Visual Studio 2008' `
    + '\VS2008TeamExplorer.iso'

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

Start-Process `
    -FilePath "$imageDriveLetter`:\setup.exe" `
    -Wait

Dismount-DiskImage -ImagePath $imagePath
```

```PowerShell
cls
```

## # Install Visual Studio 2008 Service Pack 1

```PowerShell
$imagePath = '\\TT-FS01\Products\Microsoft\Visual Studio 2008\Patches' `
    + '\en_visual_studio_2008_service_pack_1_x86_dvd_x15-12962.iso'

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

Start-Process `
    -FilePath "$imageDriveLetter`:\vs90sp1\SPInstaller.exe" `
    -ArgumentList "/passive" `
    -Wait

Dismount-DiskImage -ImagePath $imagePath
```

> **Note**
>
> When prompted, restart the computer to complete the installation.

```PowerShell
cls
```

## # Install Visual Studio 2010

```PowerShell
$imagePath = '\\TT-FS01\Products\Microsoft\Visual Studio 2010' `
    + '\en_visual_studio_2010_ultimate_x86_dvd_509116.iso'

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

Start-Process `
    -FilePath "$imageDriveLetter`:\setup.exe" `
    -Wait

Dismount-DiskImage -ImagePath $imagePath
```

```PowerShell
cls
```

## # Install Visual Studio 2010 Service Pack 1

```PowerShell
$imagePath = '\\TT-FS01\Products\Microsoft\Visual Studio 2010\Patches\Service Pack 1' `
    + '\mu_visual_studio_2010_sp1_x86_x64_dvd_651704.iso'

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

Start-Process `
    -FilePath "$imageDriveLetter`:\setup.exe" `
    -ArgumentList "/passive /showfinalerror" `
    -Wait

Dismount-DiskImage -ImagePath $imagePath
```

> **Note**
>
> When prompted, restart the computer to complete the installation.

```PowerShell
cls
```

## # Install Visual Studio 2012

```PowerShell
$imagePath = '\\TT-FS01\Products\Microsoft\Visual Studio 2012' `
    + '\en_visual_studio_ultimate_2012_x86_dvd_920947.iso'

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

Start-Process `
    -FilePath "$imageDriveLetter`:\vs_ultimate.exe" `
    -Wait

Dismount-DiskImage -ImagePath $imagePath
```

### Issue

![(screenshot)](https://assets.technologytoolbox.com/screenshots/84/80C336B1EB474B5CF3255B0725E509FED420FA84.png)

```PowerShell
cls
```

## # Install Visual Studio 2012 Update 5

```PowerShell
$imagePath = '\\TT-FS01\Products\Microsoft\Visual Studio 2012\Update 5' `
    + '\mu_visual_studio_2012_update_5_x86_dvd_6967467.iso'

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

Start-Process `
    -FilePath "$imageDriveLetter`:\VS2012.5.exe" `
    -ArgumentList "/Passive /ForceRestart" `
    -Wait

Dismount-DiskImage -ImagePath $imagePath
```

```PowerShell
cls
```

## # Install WiX

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\WiX" `
    + "\wix37.exe"

Start-Process `
    -FilePath $installerPath `
    -Wait
```

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

## Login as .\\foo

## Install Team Foundation Server Integration Tools (March 2012 Release)

> **Note**
>
> The TFS Integration Tools setup checks if Team Explorer 2008, 2010, or "Dev 11" is installed. Since it does not recognize Team Explorer 2012 (which is actually "Dev 11"), Team Explorer 2010 must be installed.

### # Add TFS service account to the local Administrators group

```PowerShell
net localgroup Administrators /add TECHTOOLBOX\svc-tfs
```

### Login as TECHTOOLBOX\\svc-tfs

```PowerShell
cls
```

### # Install TFS Integation Tools

```PowerShell
$msiPath = "\\TT-FS01\Public\Download\Microsoft" `
    + "\TFS Integration Tools (March 2012)\TFSIntegrationTools.msi"

$arguments = "/i `"$msiPath`""

Start-Process `
    -FilePath 'msiexec.exe' `
    -ArgumentList $arguments `
    -Wait
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2E/D74C9ED403CF4A1C9AFD266FB33B551290809D2E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8E/77A9F6C6C496EB60F62B649CDE236D6854D11B8E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4B/941E1A768BB914C23C54769C6197964C26DC3F4B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3E/F2CA6164A62CDEF045C9D1E6D17128F2320F913E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/74/D0C32112954749D82BB0E39B353D741B2D889574.png)

#### Issue

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BC/9C6C1B725C38F6A5583DE67F594F70E9E39030BC.png)

#### Solution

---

**HAVOK - SQL Server Management Studio**

##### -- Temporarily add TECHTOOLBOX\\svc-tfs to dbcreator role

```SQL
ALTER SERVER ROLE [dbcreator] ADD MEMBER [TECHTOOLBOX\svc-tfs]
```

---

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E9/405B71E89649E7720F589C7533774CA436F018E9.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/33/3DCF1D2C6C58DCDB7A6726E7DE6BF08094E6F433.png)

---

**HAVOK - SQL Server Management Studio**

##### -- Remove TECHTOOLBOX\\svc-tfs from dbcreator role

```SQL
ALTER SERVER ROLE [dbcreator] DROP MEMBER [TECHTOOLBOX\svc-tfs]
```

---

```Console
logoff
```

### Login as .\\foo

## Fix permissions issue with TFS Integration

### Issue

System.UnauthorizedAccessException: Access to the path 'C:\\Program Files (x86)\\Microsoft Team Foundation Server Integration Tools\\17559.txt' is denied.\
   at System.IO.__Error.WinIOError(Int32 errorCode, String maybeFullPath)\
   at System.IO.FileStream.Init(String path, FileMode mode, FileAccess access, Int32 rights, Boolean useRights, FileShare share, Int32 bufferSize, FileOptions options, SECURITY_ATTRIBUTES secAttrs, String msgPath, Boolean bFromProxy)\
   at System.IO.FileStream..ctor(String path, FileMode mode, FileAccess access, FileShare share, Int32 bufferSize, FileOptions options)\
   at System.IO.StreamWriter.CreateFile(String path, Boolean append)\
   at System.IO.StreamWriter..ctor(String path, Boolean append, Encoding encoding, Int32 bufferSize)\
   at System.IO.StreamWriter..ctor(String path)\
   at Microsoft.TeamFoundation.Migration.Tfs2010VCAdapter.TfsVCMigrationProvider.codeReview(IEnumerable`1 pendChanges, Int32 changeset, HashSet`1 implicitRenames, HashSet`1 implicitAdds, HashSet`1 skippedActions, Int32& changeCount, Boolean autoResolve)\
   at Microsoft.TeamFoundation.Migration.Tfs2010VCAdapter.TfsVCMigrationProvider.Checkin(ChangeGroup group, HashSet`1 implicitRenames, HashSet`1 implicitAdds, HashSet`1 skippedActions, Int32& changesetId)\
   at Microsoft.TeamFoundation.Migration.Tfs2010VCAdapter.TfsVCMigrationProvider.ProcessChangeGroup(ChangeGroup group)

### Solution

#### # Grant "Modify" permissions to service account used to run TFS Integration

```PowerShell
icacls 'C:\Program Files (x86)\Microsoft Team Foundation Server Integration Tools' `
    /grant TECHTOOLBOX\svc-tfs:`(OI`)`(CI`)`(M`)
```

## Install updates using Windows Update

> **Note**
>
> Repeat until there are no updates available for the computer.

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

# WOLVERINE - Windows 10 Enterprise x64

Wednesday, August 9, 2017
3:00 AM

## Install Windows 10 Enterprise (x64)

#### Install custom Windows 10 image

- On the **Task Sequence** step, select **Windows 10 Enterprise** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **WOLVERINE**.
  - Specify **WORKGROUP**.
  - Click **Next**.
- On the **Applications** step, ensure no items are selected and click **Next**.

#### # Rename local Administrator account and set password

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

logoff
```

---

**FOOBAR10 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Move computer to different OU

```PowerShell
$vmName = "WOLVERINE"

$targetPath = ("OU=Workstations,OU=Resources,OU=Development" `
    + ",DC=corp,DC=technologytoolbox,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

---

### Login as local administrator account

### # Configure networking

```PowerShell
$interfaceAlias = "Management"
```

#### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter -InterfaceDescription "Intel(R) Ethernet Connection I217-V" |
    Rename-NetAdapter -NewName $interfaceAlias
```

#### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

ping TT-FS01 -f -l 8900
```

```PowerShell
cls
```

### # Disable 'Automatically detect proxy settings' in Internet Explorer

```PowerShell
Function Disable-AutomaticallyDetectProxySettings {
    # Read connection settings from Internet Explorer.
    $regKeyPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Connections\"
    $conSet = $(Get-ItemProperty $regKeyPath).DefaultConnectionSettings

    # Index into DefaultConnectionSettings where the relevant flag resides.
    $flagIndex = 8

    # Bit inside the relevant flag which indicates whether or not to enable automatically detect proxy settings.
    $autoProxyFlag = 8

    if ($($conSet[$flagIndex] -band $autoProxyFlag) -eq $autoProxyFlag)
    {
        # 'Automatically detect proxy settings' was enabled, adding one disables it.
        Write-Host "Disabling 'Automatically detect proxy settings'."
        $mask = -bnot $autoProxyFlag
        $conSet[$flagIndex] = $conSet[$flagIndex] -band $mask
        $conSet[4]++
        Set-ItemProperty -Path $regKeyPath -Name DefaultConnectionSettings -Value $conSet
    }

    $conSet = $(Get-ItemProperty $regKeyPath).DefaultConnectionSettings
    if ($($conSet[$flagIndex] -band $autoProxyFlag) -ne $autoProxyFlag)
    {
    	Write-Host "'Automatically detect proxy settings' is disabled."
    }
}

Disable-AutomaticallyDetectProxySettings
```

#### Reference

**Disable-AutomaticallyDetectSettings.ps1**\
From <[https://gist.github.com/ReubenBond/1387620](https://gist.github.com/ReubenBond/1387620)>

### # Join domain

```PowerShell
Add-Computer -DomainName corp.technologytoolbox.com -Restart
```

### Configure storage

```PowerShell
cls
```

#### # Change drive letter for DVD-ROM

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
```

#### Physical disks

<table>
<tr>
<td valign='top'>
<p>Disk</p>
</td>
<td valign='top'>
<p>Description</p>
</td>
<td valign='top'>
<p>Capacity</p>
</td>
<td valign='top'>
<p>Drive Letter</p>
</td>
<td valign='top'>
<p>Volume Size</p>
</td>
<td valign='top'>
<p>Allocation Unit Size</p>
</td>
<td valign='top'>
<p>Volume Label</p>
</td>
</tr>
<tr>
<td valign='top'>
<p>0</p>
</td>
<td valign='top'>
<p>Model: WDC WD1001FALS-00E3A0<br />
Serial number: WD-******283566</p>
</td>
<td valign='top'>
<p>1 TB</p>
</td>
<td valign='top'>
<p>Z:</p>
</td>
<td valign='top'>
<p>931 GB</p>
</td>
<td valign='top'>
<p>4K</p>
</td>
<td valign='top'>
<p>Backup01</p>
</td>
</tr>
<tr>
<td valign='top'>
<p>1</p>
</td>
<td valign='top'>
<p>Model: Samsung SSD 850 PRO 512GB<br />
Serial number: *********27828J</p>
</td>
<td valign='top'>
<p>512 GB</p>
</td>
<td valign='top'>
<p>C:</p>
</td>
<td valign='top'>
<p>472 GB</p>
</td>
<td valign='top'>
<p>4K</p>
</td>
<td valign='top'>
<p>System</p>
</td>
</tr>
<tr>
<td valign='top'>
<p>2</p>
</td>
<td valign='top'>
<p>Model: M4-CT512M4SSD2<br />
Serial number: 0000000*********8440</p>
</td>
<td valign='top'>
<p>512 GB</p>
</td>
<td valign='top'>
<p>D:</p>
</td>
<td valign='top'>
<p>477 GB</p>
</td>
<td valign='top'>
<p>4K</p>
</td>
<td valign='top'>
<p>Gold01</p>
</td>
</tr>
<tr>
<td valign='top'>
<p>3</p>
</td>
<td valign='top'>
<p>Model: C300-CTFDDAC128MAG<br />
Serial number: 0000000*********31DC</p>
</td>
<td valign='top'>
<p>128 GB</p>
</td>
<td valign='top'>
<p>E:</p>
</td>
<td valign='top'>
<p>119 GB</p>
</td>
<td valign='top'>
<p>4K</p>
</td>
<td valign='top'>
<p>Silver01</p>
</td>
</tr>
<tr>
<td valign='top'>
<p>4</p>
</td>
<td valign='top'>
<p>Model: WDC WD1002FAEX-00Y9A0<br />
Serial number: WD-******201582</p>
</td>
<td valign='top'>
<p>1TB</p>
</td>
<td valign='top'>
<p>F:</p>
</td>
<td valign='top'>
<p>931 GB</p>
</td>
<td valign='top'>
<p>4K</p>
</td>
<td valign='top'>
<p>Bronze01</p>
</td>
</tr>
</table>

```PowerShell
Get-PhysicalDisk | sort DeviceId

Get-PhysicalDisk | select DeviceId, Model, SerialNumber, CanPool | sort DeviceId
```

```PowerShell
cls
```

#### # Configure partitions and volumes

##### # Rename "Windows" volume to "System"

```PowerShell
Get-Volume -DriveLetter C | Set-Volume -NewFileSystemLabel System
```

##### # Create "Gold01" volume (D:)

```PowerShell
Get-PhysicalDisk |    where { $_.SerialNumber -eq '0000000*********8440' } |    Get-Disk |    Clear-Disk -RemoveData -Confirm:$false -PassThru |    Initialize-Disk -PartitionStyle GPT -PassThru |    New-Partition -DriveLetter "D" -UseMaximumSize |    Format-Volume `        -FileSystem NTFS `        -NewFileSystemLabel "Gold01" `        -Confirm:$false
```

```PowerShell
cls
```

##### # Create "Silver01" volume (E:)

```PowerShell
Get-PhysicalDisk |    where { $_.SerialNumber -eq '0000000*********31DC' } |    Get-Disk |    Clear-Disk -RemoveData -Confirm:$false -PassThru |    Initialize-Disk -PartitionStyle GPT -PassThru |    New-Partition -DriveLetter "E" -UseMaximumSize |    Format-Volume `        -FileSystem NTFS `        -NewFileSystemLabel "Silver01" `        -Confirm:$false
```

```PowerShell
cls
```

##### # Create "Bronze01" volume (F:)

```PowerShell
Get-PhysicalDisk |     where { $_.SerialNumber -eq 'WD-******201582' } |     Get-Disk |     Clear-Disk -RemoveData -Confirm:$false -PassThru |     Initialize-Disk -PartitionStyle GPT -PassThru |     New-Partition -DriveLetter "F" -UseMaximumSize |     Format-Volume `        -FileSystem NTFS `        -NewFileSystemLabel "Bronze01" `        -Confirm:$false
```

```PowerShell
cls
```

##### # Create "Backup01" volume (Z:)

```PowerShell
Get-PhysicalDisk |     where { $_.SerialNumber -eq 'WD-******283566' } |     Get-Disk |     Clear-Disk -RemoveData -Confirm:$false -PassThru |     Initialize-Disk -PartitionStyle GPT -PassThru |     New-Partition -DriveLetter "Z" -UseMaximumSize |     Format-Volume `        -FileSystem ReFS `        -NewFileSystemLabel "Backup01" `        -Confirm:$false
```

### Create default folders

> **Important**
>
> Run the following commands using a non-elevated command prompt (to avoid issues with customizing the folder icons).

---

**Command Prompt**

```Console
mkdir C:\NotBackedUp\Public\Symbols
mkdir C:\NotBackedUp\Temp
```

---

```PowerShell
cls
```

### # Set MaxPatchCacheSize to 0

```PowerShell
reg add HKLM\Software\Policies\Microsoft\Windows\Installer /v MaxPatchCacheSize /t REG_DWORD /d 0 /f
```

```PowerShell
cls
```

### # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

### # Copy Toolbox content

```PowerShell
net use \\TT-FS01\ipc$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```Console
robocopy \\TT-FS01\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E
```

### # Configure cmder shortcut in Windows Explorer ("Cmder Here")

```PowerShell
C:\NotBackedUp\Public\Toolbox\cmder\Cmder.exe /REGISTER ALL
```

### # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

### # Configure firewall rules for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
Set-ExecutionPolicy RemoteSigned -Scope Process -Force

C:\NotBackedUp\Public\Toolbox\PowerShell\Enable-RemoteWindowsUpdate.ps1 -Verbose
C:\NotBackedUp\Public\Toolbox\PowerShell\Disable-RemoteWindowsUpdate.ps1  -Verbose
```

```PowerShell
cls
```

## # Install and configure Microsoft Money

### # Install Microsoft Money

```PowerShell
net use \\TT-FS01\Products /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
& "\\TT-FS01\Products\Microsoft\Money 2008\USMoneyBizSunset.exe"
```

### Patch Money DLL to avoid crash when importing transactions

1. Open DLL in hex editor:
2. Make the following changes:

```Console
    C:\NotBackedUp\Public\Toolbox\HxD\HxD.exe "C:\Program Files (x86)\Microsoft Money Plus\MNYCoreFiles\mnyob99.dll"
```

    File offset **003FACE8**: Change **85** to **8D**\
    File offset **003FACED**: Change **50** to **51**\
    File offset **003FACF0**: Change **FF** to **85**\
    File offset **003FACF6**: Change **E8** to **B9**

#### Reference

**Microsoft Money crashes during import of account transactions or when changing a payee of a downloaded transaction**\
From <[http://blogs.msdn.com/b/oldnewthing/archive/2012/11/13/10367904.aspx](http://blogs.msdn.com/b/oldnewthing/archive/2012/11/13/10367904.aspx)>

```PowerShell
cls
```

### # Create custom invoice template

```PowerShell
& "C:\Program Files (x86)\Microsoft Money Plus\MNYCoreFiles\tmplbldr.exe"
```

In the **New Template** window:

1. Ensure **Create new template** is selected and click **Next**.
2. In the **Name** box, type **Technology Toolbox** and click **Next**.
3. Ensure **Portrait **is selected and click **Finish**.
4. On the **File** menu, click **Save**.

> **Note**
>
> The new invoice template is created in the following folder:
>
> C:\\Users\\All Users\\Microsoft\\Money\\17.0\\Invoice

#### Overwrite file with custom template

```PowerShell
Copy-Item `
    '\\TT-FS01\Users$\jjameson\My Documents\Technology Toolbox LLC\InvoiceTemplate.htm' `
    'C:\Users\All Users\Microsoft\Money\17.0\Invoice\usr19.htm'
```

#### Configure default invoice template

Edit invoice listing (2008Invoice.ntd) to move the "Technology Toolbox" invoice to the top (so it is selected by default).

```Console
Notepad "C:\Users\All Users\Microsoft\Money\17.0\Invoice\2008Invoice.ntd"
```

#### Reference

**Sunset Home & Business - Invoice issues**\
From <[https://microsoftmoneyoffline.wordpress.com/sunset-home-business-invoices/](https://microsoftmoneyoffline.wordpress.com/sunset-home-business-invoices/)>

```PowerShell
cls
```

## # Install Microsoft Office Professional Plus 2016

```PowerShell
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

$isoFilename = "en_office_professional_plus_2016_x86_x64_dvd_6962141.iso"

$imagePath = "\\TT-FS01\Products\Microsoft\Office 2016" `
    + "\$isoFilename"

$imageDriveLetter = Ensure-MountedDiskImage $imagePath

$setupPath = $imageDriveLetter + ':\setup.exe'

& $setupPath
```

### Issue

Error: "The system cannot find the file specified."

#### Workaround

```PowerShell
$tempPath = "C:\NotBackedUp\Temp"

Copy-Item $imagePath $tempPath

$imagePath = "$tempPath\$isoFilename"

$imageDriveLetter = Ensure-MountedDiskImage $imagePath

$setupPath = $imageDriveLetter + ':\setup.exe'

& "$imageDriveLetter`:"

& $setupPath
```

> **Important**
>
> Wait for the installation to complete.

```Console
C:

Dismount-DiskImage $imagePath
```

```Console
cls
```

## # Install Microsoft Visio Professional 2016

```PowerShell
$isoFilename = "en_visio_professional_2016_x86_x64_dvd_6962139.iso"

$imagePath = "\\TT-FS01\Products\Microsoft\Visio 2016" `
    + "\$isoFilename"

$imageDriveLetter = Ensure-MountedDiskImage $imagePath

$setupPath = $imageDriveLetter + ':\setup.exe'

& "$imageDriveLetter`:"

& $setupPath
```

> **Important**
>
> Wait for the installation to complete.

```Console
C:

Dismount-DiskImage $imagePath
```

```Console
cls
```

## # Install Microsoft InfoPath 2013

```PowerShell
& "\\TT-FS01\Products\Microsoft\Office 2013\infopath_4753-1001_x86_en-us.exe"
```

> **Important**
>
> Wait for the installation to complete.

```PowerShell
cls
```

## # Install Adobe Reader

### # Install Adobe Reader 8.3

```PowerShell
& "\\TT-FS01\Products\Adobe\AdbeRdr830_en_US.msi"
```

> **Important**
>
> Wait for the installation to complete.

### # Install update for Adobe Reader

```PowerShell
& "\\TT-FS01\Products\Adobe\AdbeRdrUpd831_all_incr.msp"
```

```PowerShell
cls
```

## # Install Mozilla Firefox

```PowerShell
& "\\TT-FS01\Products\Mozilla\Firefox\Firefox Setup 55.0.exe" -ms
```

```PowerShell
cls
```

## # Install Google Chrome

```PowerShell
& \\TT-FS01\Products\Google\Chrome\googlechromestandaloneenterprise64.msi
```

```PowerShell
cls
```

## # Install Paint.NET

```PowerShell
& "\\TT-FS01\Products\Paint.NET\paint.net.4.0.17.install.zip"
```

## Install Microsoft Expression Studio 4

---

**WOLVERINE**

```PowerShell
cls
```

### # Copy installation media from internal file server

```PowerShell
$isoFile = "en_expression_studio_4_ultimate_x86_dvd_537032.iso"

$sourcePath = "\\TT-FS01\Products\Microsoft\Expression Studio"

$destPath = "C:\NotBackedUp\Temp"

robocopy $sourcePath $destPath $isoFile
```

---

Error running setup: "Your computer is scheduled to restart. Restart your computer and run Setup to continue installing this Expression program."

```PowerShell
Restart-Computer

Use the "Toolbox" script to install Expression Studio
```

```PowerShell
cls
```

## # Install Microsoft SQL Server 2016

```PowerShell
net use \\TT-FS01\Products /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$sourcePath = "\\TT-FS01\Products\Microsoft\SQL Server 2016"
$destPath = "C:\NotBackedUp\Temp"
$isoFilename = "en_sql_server_2016_developer_x64_dvd_8777069.iso"

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
- For **SQL Server Reporting Services**, change the **Startup Type** to **Manual**.
- For **SQL Server Integration Services 13.0**, change the **Startup Type** to **Manual**.

On the **Database Engine Configuration** page:

- On the **Server Configuration** tab, click **Add Current User**.
- On the **Data Directories** tab:
  - Change the **Data root directory** to **D:\\NotBackedUp\\Microsoft SQL Server\\**
  - Change the **Backup directory** to **Z:\\Microsoft SQL Server\\MSSQL13.MSSQLSERVER\\MSSQL\\Backup**

On the **Analysis Services Configuration** page:

- On the **Server Configuration** tab, click **Add Current User**.
- On the **Data Directories** tab:
  - Change the **Data directory** to **D:\\NotBackedUp\\Microsoft SQL Server\\MSAS13.MSSQLSERVER\\OLAP\\Data.**
  - Change the **Log file directory** to **D:\\NotBackedUp\\Microsoft SQL Server\\MSAS13.MSSQLSERVER\\OLAP\\Log.**
  - Change the **Temp directory** to **D:\\NotBackedUp\\Microsoft SQL Server\\MSAS13.MSSQLSERVER\\OLAP\\Temp.**
  - Change the **Backup directory** to **Z:\\NotBackedUp\\Microsoft SQL Server\\MSAS13.MSSQLSERVER\\OLAP\\Backup**.

On the **Distributed Replay Controller **page, click **Add Current User**.

```PowerShell
Dismount-DiskImage $imagePath
```

```PowerShell
cls
```

## # Install Microsoft SQL Server Management Studio (Release 17.2)

```PowerShell
& '\\TT-FS01\Products\Microsoft\SQL Server 2016\SSMS-Setup-ENU.exe'
```

```PowerShell
cls
```

## # Install Microsoft Visual Studio 2017 Enterprise with Update 2

```PowerShell
net use \\TT-FS01\Products /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
& '\\TT-FS01\Products\Microsoft\Visual Studio 2017\Enterprise\vs_Enterprise.exe'
```

```PowerShell
cls
```

## # Install Visual Studio Code

```PowerShell
& '\\TT-FS01\Products\Microsoft\Visual Studio Code\VSCodeSetup-x64-1.15.0.exe'
```

On the **Select Additional Tasks** page, select the following checkboxes:

- **Add "Open with Code" action to Windows Explorer file context menu**
- **Add "Open with Code" action to Windows Explorer directory context menu**
- **Add to PATH (available after restart)**

```PowerShell
cls
```

## # Configure development environment

### # Install IIS

```PowerShell
Enable-WindowsOptionalFeature `
    -Online `
    -All `
    -FeatureName IIS-ManagementConsole, `
        IIS-ASPNET45, `
        IIS-DefaultDocument, `
        IIS-DirectoryBrowsing, `
        IIS-HttpErrors, `
        IIS-StaticContent, `
        IIS-HttpLogging, `
        IIS-HttpCompressionStatic, `
        IIS-RequestFiltering, `
        IIS-WindowsAuthentication
```

### # Configure symbol path for debugging

```PowerShell
$symbolPath = "SRV*C:\NotBackedUp\Public\Symbols" `
     + "*\\TT-FS01\Public\Symbols" `
     + "*http://msdl.microsoft.com/download/symbols"

[Environment]::SetEnvironmentVariable("_NT_SYMBOL_PATH", $symbolPath, "Machine")
```

### # Install reference assemblies

```PowerShell
net use \\TT-FS01\ipc$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$source = '\\TT-FS01\Builds\Reference Assemblies'
$dest = 'C:\Program Files\Reference Assemblies'

robocopy $source $dest /E

& "$dest\Microsoft\SharePoint v4\AssemblyFoldersEx - x64.reg"
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/62/DE96621F16BC51A75B6410BE1B94F33F9B8A0F62.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5E/06DBAE68F16F7F83442A5F1916BFBEFEFC0DD15E.png)

```PowerShell
& "$dest\Microsoft\SharePoint v5\AssemblyFoldersEx - x64.reg"
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AE/E9FD2601E62121DA76E1227B4436C7ED8F069CAE.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BB/9A7DF5FF756E44DAC0D8F600AA2D457598370EBB.png)

```PowerShell
cls
```

## # Install and configure Node.js

### # Install Node.js

```PowerShell
& \\TT-FS01\Products\node.js\node-v6.11.2-x64.msi
```

> **Important**
>
> Restart PowerShell for change to PATH environment variable to take effect.

### Change NPM file locations to avoid issues with redirected folders

#### Reference

**npm on windows, install with -g flag should go into appdata/local rather than current appdata/roaming?**\
From <[https://github.com/npm/npm/issues/4564](https://github.com/npm/npm/issues/4564)>

**`npm install -g bower` goes into infinite loop on windows with %appdata% being a UNC path**\
From <[https://github.com/npm/npm/issues/8814](https://github.com/npm/npm/issues/8814)>

> **Note**
>
> As illustrated in the following screenshot, the latest version of NPM (3.10.10) successfully installs the latest version of Bower (1.8.0) when %APPDATA% refers to a network location -- so it appears this problem has been fixed.
>
> ![(screenshot)](https://assets.technologytoolbox.com/screenshots/50/023FB51E49C5E086909FFCCD50D6AB5E5426CF50.png)
>
> ```Text
> PS C:\Users\jjameson> $env:APPDATA
> \\TT-FS01\Users$\jjameson\Application Data
> PS C:\Users\jjameson> npm install -g bower
> npm WARN deprecated bower@1.8.0: ..psst! While Bower is maintained, we recommend Yarn and Webpack for *new* front-end projects! Yarn's advantage is security and reliability, and Webpack's is support for both CommonJS and AMD projects. Currently there's no migration path, but please help to create it: https://github.com/bower/bower/issues/2467
> \\TT-FS01\Users$\jjameson\Application Data\npm\bower -> \\TT-FS01\Users$\jjameson\Application Data\npm\node_modules\bower\bin\bower
> \\TT-FS01\Users$\jjameson\Application Data\npm
> `-- bower@1.8.0
> ```
>
> However, it still seems like a good idea to install global packages to %LOCALAPPDATA% instead of %APPDATA%:\
> **npm on windows, install with -g flag should go into appdata/local rather than current appdata/roaming?**\
> From <[https://github.com/npm/npm/issues/17325](https://github.com/npm/npm/issues/17325)>

#### # Configure installed version of npm to avoid issues with redirected folders

```PowerShell
notepad "C:\Program Files\nodejs\node_modules\npm\npmrc"
```

---

**C:\\Program Files\\nodejs\\node_modules\\npm\\npmrc**

```Text
;prefix=${APPDATA}\npm
prefix=${LOCALAPPDATA}\npm
cache=${LOCALAPPDATA}\npm-cache
```

---

```PowerShell
cls
```

### # Change NPM "global" locations to shared location for all users

```PowerShell
mkdir "$env:ALLUSERSPROFILE\npm-cache"

mkdir "$env:ALLUSERSPROFILE\npm\node_modules"

npm config --global set prefix "$env:ALLUSERSPROFILE\npm"

npm config --global set cache "$env:ALLUSERSPROFILE\npm-cache"

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-PathFolders.ps1 `
    -Folders "$env:ALLUSERSPROFILE\npm" `
    -EnvironmentVariableTarget Machine
```

## Install global NPM packages

### Reference

**Install the Yeoman toolset**\
From <[http://yeoman.io/codelab/setup.html](http://yeoman.io/codelab/setup.html)>

```PowerShell
cls
```

### # Install Grunt CLI

```PowerShell
npm install --global grunt-cli
```

```PowerShell
cls
```

### # Install Gulp

```PowerShell
npm install --global gulp
```

```PowerShell
cls
```

### # Install Bower

```PowerShell
npm install --global bower
```

```PowerShell
cls
```

### # Install Karma CLI

```PowerShell
npm install --global karma-cli
```

```PowerShell
cls
```

### # Install Yeoman

```PowerShell
npm install --global yo
```

```PowerShell
cls
```

### # Install Yeoman generators

```PowerShell
npm install --global generator-karma

npm install --global generator-angular
```

```PowerShell
cls
```

### # Install rimraf

```PowerShell
npm install --global rimraf
```

## Configure npm locations for TECHTOOLBOX\\jjameson account

---

**runas /USER:TECHTOOLBOX\\jjameson PowerShell.exe**

```PowerShell
npm config --global set prefix "$env:ALLUSERSPROFILE\npm"

npm config --global set cache "$env:ALLUSERSPROFILE\npm-cache"
```

---

## Configure Visual Studio 2017 to use newer versions of Node.js and NPM

### Before

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0F/3B5712D6462D49CC17DB1EFE2DDAF657FB52E00F.png)

### After

![(screenshot)](https://assets.technologytoolbox.com/screenshots/58/51CCEAA9A97B80142D704A7789E6919ADBFF7258.png)

### Reference

**Synchronizing node version with your environment in Visual Studio 2017**\
From <[https://www.domstamand.com/synchronizing-node-version-with-your-environment-in-visual-studio-2017/](https://www.domstamand.com/synchronizing-node-version-with-your-environment-in-visual-studio-2017/)>

```PowerShell
cls
```

## # Install PowerShell modules

```PowerShell
Install-PackageProvider NuGet -MinimumVersion '2.8.5.201' -Force

Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

Install-Module -Name 'posh-git'
```

```PowerShell
cls
```

## # Install Chocolatey

```PowerShell
((New-Object System.Net.WebClient).DownloadString(
    'https://chocolatey.org/install.ps1')) |
    Invoke-Expression
```

> **Important**
>
> Restart PowerShell for environment changes to take effect.

```Console
exit
```

### Reference

**Installing Chocolatey**\
From <[https://chocolatey.org/install](https://chocolatey.org/install)>

## # Install HTML Tidy

```PowerShell
choco install html-tidy -y
```

## Install GitHub Desktop

[https://desktop.github.com/](https://desktop.github.com/)

## Install Fiddler

```PowerShell
cls
```

## # Install Microsoft Message Analyzer

```PowerShell
& "\\TT-FS01\Products\Microsoft\Message Analyzer 1.4\MessageAnalyzer64.msi"
```

"Windows blocked the installation of a digitally unsigned driver..."

**Microsoft Message Anlayzer 1.4 - 'A Digitally Signed Driver Is Required'**From <[https://social.technet.microsoft.com/Forums/windows/en-US/48b4c226-fc3d-4793-b544-3440ed13424a/microsoft-message-anlayzer-14-a-digitally-signed-driver-is-required?forum=messageanalyzer](https://social.technet.microsoft.com/Forums/windows/en-US/48b4c226-fc3d-4793-b544-3440ed13424a/microsoft-message-anlayzer-14-a-digitally-signed-driver-is-required?forum=messageanalyzer)>

```PowerShell
cls
```

## # Install Microsoft Log Parser 2.2

```PowerShell
& "\\TT-FS01\Public\Download\Microsoft\LogParser 2.2\LogParser.msi"
```

```PowerShell
cls
```

## # Install Remote Desktop Connection Manager

```PowerShell
& "\\TT-FS01\Products\Microsoft\Remote Desktop Connection Manager\rdcman.msi"
```

## Install software for HP Photosmart 6515

[http://support.hp.com/us-en/drivers/selfservice/HP-Photosmart-6510-e-All-in-One-Printer-series---B2/5058334/model/5191793](http://support.hp.com/us-en/drivers/selfservice/HP-Photosmart-6510-e-All-in-One-Printer-series---B2/5058334/model/5191793)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B5/C53FF5F0549B9F389E6E62519EB11652F68F81B5.png)

## Share printer

![(screenshot)](https://assets.technologytoolbox.com/screenshots/01/2EDCC101189FC9A8E4E5FD9205D12E8EB82B2F01.png)

Click **Change Sharing Options**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/94/39D600ED528C73CAE3772FDA8A9E263E29CBF094.png)

## Install and configure Hyper-V

### Enable Hyper-V

```PowerShell
cls
```

### # Configure VM storage

```PowerShell
mkdir D:\NotBackedUp\VMs

Set-VMHost -VirtualMachinePath D:\NotBackedUp\VMs
```

```PowerShell
cls
```

### # Create virtual switches

```PowerShell
New-VMSwitch `
    -Name "Management" `
    -NetAdapterName "Management" `
    -AllowManagementOS $true
```

### # Enable jumbo frames on virtual switches

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name "vEthernet (Management)" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

ping TT-FS01 -f -l 8900
```

```PowerShell
cls
```

### # Download PowerShell help files

```PowerShell
Update-Help
```

```PowerShell
cls
```

## # Enter a product key and activate Windows

```PowerShell
slmgr /ipk {product key}
```

**Note:** When notified that the product key was set successfully, click **OK**.

```Console
slmgr /ato
```

## Install updates using Windows Update

**Note:** Repeat until there are no updates available for the computer.

```PowerShell
cls
```

### # Delete C:\\Windows\\SoftwareDistribution folder (4.7 GB)

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse
```

```PowerShell
cls
```

## # Install Python 2 (dependency for PocketSense)

### # Install Python (using default options)

```PowerShell
net use \\TT-FS01\ipc$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
& "\\TT-FS01\Products\Python\python-2.7.13.amd64.msi"
```

### # Add Python folders to PATH environment variable

```PowerShell
Set-ExecutionPolicy RemoteSigned -Force

$pythonPathFolders = 'C:\Python27\', 'C:\Python27\Scripts'

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-PathFolders.ps1 `
    -Folders $pythonPathFolders `
    -EnvironmentVariableTarget Machine
```

## # Configure Git to use SourceGear DiffMerge

```PowerShell
git config --global diff.tool diffmerge

git config --global difftool.diffmerge.cmd  '"C:/NotBackedUp/Public/Toolbox/DiffMerge/x64/sgdm.exe \"$LOCAL\" \"$REMOTE\"'
```

### Reference

**Git for Windows (MSysGit) or Git Cmd**\
From <[https://sourcegear.com/diffmerge/webhelp/sec__git__windows__msysgit.html](https://sourcegear.com/diffmerge/webhelp/sec__git__windows__msysgit.html)>

```PowerShell
cls
```

## # Upgrade Node.js

### # Copy installer from internal file server

```PowerShell
$installer = "node-v6.11.5-x64.msi"

$source = "\\TT-FS01\Products\node.js"
$destination = "C:\NotBackedUp\Temp"

robocopy $source $destination $installer
```

##### # Install new version of Node.js

```PowerShell
Start-Process `
    -FilePath "C:\NotBackedUp\Temp\$installer" `
    -Wait
```

#### # Change NPM file locations to avoid issues with redirected folders

```PowerShell
notepad "C:\Program Files\nodejs\node_modules\npm\npmrc"
```

---

**C:\\Program Files\\nodejs\\node_modules\\npm\\npmrc**

```Text
;prefix=${APPDATA}\npm
prefix=${LOCALAPPDATA}\npm
cache=${LOCALAPPDATA}\npm-cache
```

---

```PowerShell
cls
```

#### # Change npm "global" locations to shared location for all users

```PowerShell
npm config --global set prefix "$env:ALLUSERSPROFILE\npm"

npm config --global set cache "$env:ALLUSERSPROFILE\npm-cache"
```

#### # Clear NPM cache

```PowerShell
npm cache clean
```

> **Important**
>
> If an error occurs when clearing the NPM cache, try running the command a second time:
>
> ```Text
> PS C:\windows\system32> npm cache clean
> npm ERR! Windows_NT 6.3.9600
> npm ERR! argv "C:\\Program Files\\nodejs\\node.exe" "C:\\Program Files\\nodejs\\node_modules\\npm\\bin\\npm-cli.js" "cache" "clean"
> npm ERR! node v6.11.5
> npm ERR! npm  v3.10.10
> npm ERR! path C:\ProgramData\npm-cache
> npm ERR! code EPERM
> npm ERR! errno -4048
> npm ERR! syscall rmdir
>
> npm ERR! Error: EPERM: operation not permitted, rmdir 'C:\ProgramData\npm-cache'
> npm ERR!     at Error (native)
> npm ERR!  { Error: EPERM: operation not permitted, rmdir 'C:\ProgramData\npm-cache'
> npm ERR!     at Error (native)
> npm ERR!   errno: -4048,
> npm ERR!   code: 'EPERM',
> npm ERR!   syscall: 'rmdir',
> npm ERR!   path: 'C:\\ProgramData\\npm-cache' }
> npm ERR!
> npm ERR! Please try running this command again as root/Administrator.
>
> npm ERR! Please include the following file with any support request:
> npm ERR!     C:\windows\system32\npm-debug.log
> PS C:\windows\system32>
> PS C:\windows\system32> npm cache clean
> PS C:\windows\system32>
> ```

### # Install new global NPM packages

```PowerShell
npm install --global @angular/cli@1.4.9
```

**TODO:**

## Disk Cleanup

## # Configure credential helper for Git

```PowerShell
git config --global credential.helper !"C:\\NotBackedUp\\Public\\Toolbox\\git-credential-winstore.exe"
```

## # Configure e-mail and name for Git

```PowerShell
git config --global user.email "jeremy_jameson@live.com"
git config --global user.name "Jeremy Jameson"
```

## Other stuff that may need to be done

### Install Android SDK (for debugging Chrome on Samsung Galaxy)

#### Reference

[http://stackoverflow.com/a/24410867](http://stackoverflow.com/a/24410867)

#### Install Samsung USB driver

#### Install Java SE Development Kit 8u66

[http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html](http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html)

#### Install Android "SDK Tools Only"

[http://developer.android.com/sdk/index.html#Other](http://developer.android.com/sdk/index.html#Other)

#### Install Android SDK Platform-tools

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1E/75601D9C9EF795A16D815FE580D6571F20B23C1E.png)

#### Detect devices

```Console
cd C:\Program Files (x86)\Android\android-sdk\platform-tools

adb.exe devices
```

### Install Chutzpah Test Adapter

1. Open Visual Studio.
2. In the **Tools** menu, click **Extensions and Updates...**
3. In the **Extensions and Updates** dialog window:
   1. Select the **Online** pane.
   2. In the search box, type **Chutzpah**.
   3. In the list of items, select **Chutzpah Test Adapter for the Test Explorer**, and click **Download**.
   4. Review the license terms, and click **Install**.
   5. Wait for the extension to be installed.
   6. Click **Restart Now**.

### Install Chutzpah Test Runner

1. Open Visual Studio.
2. In the **Tools** menu, click **Extensions and Updates...**
3. In the **Extensions and Updates** dialog window:
   1. Select the **Online** pane.
   2. In the search box, type **Chutzpah**.
   3. In the list of items, select **Chutzpah Test Runner Context Menu Extension**, and click **Download**.
   4. Review the license terms, and click **Install**.
   5. Wait for the extension to be installled.
   6. Click **Restart Now**.

### Install Apple iTunes

### Install Sandcastle

#### Sandcastle Documentation Compiler Tools

#### Sandcastle Help File Builder

### Install MSBuild Community Tasks

### Install ASP.NET ViewState Helper 2.0.1

### Install Inkscape 0.48

### Install Web Essentials 2015

### # Clone repository - Training

```PowerShell
mkdir src\Repos

cd src\Repos

git clone https://techtoolbox.visualstudio.com/DefaultCollection/_git/Training
```

### # Install ng-demos

#### # Install package dependencies

```PowerShell
npm install -g node-inspector
```

#### # Clone repo

```PowerShell
cd Training

git clone https://github.com/johnpapa/ng-demos.git
```

#### # Install packages

```PowerShell
cd ng-demos\modular

npm install
```

#### # Run dev build

```PowerShell
gulp serve-dev-debug
```

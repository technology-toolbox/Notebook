# STORM - Windows 10 Enterprise x64

Monday, July 2, 2018\
11:20 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Install Windows 10 Enterprise (x64)

### Install custom Windows 10 image

- On the **Task Sequence** step, select **Windows 10 Enterprise (x64)** and
  click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **STORM**.
  - Specify **WORKGROUP**.
  - Click **Next**.
- On the **Applications** step:
  - Select the following applications:
    - **Adobe**
      - **Adobe Reader 8.3.1**
    - **Microsoft**
      - **SQL Server Management Studio**
    - **Mozilla**
      - **Firefox (64-bit)**
      - **Thunderbird**
  - Click **Next**.

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

logoff
```

Install DaVinci Resolve

### Rename computer and join domain

```PowerShell
$computerName = "STORM"

Rename-Computer -NewName $computerName -Restart
```

Wait for the VM to restart and then execute the following command to join the
**TECHTOOLBOX **domain:

```PowerShell
Add-Computer -DomainName corp.technologytoolbox.com -Restart
```

---

**FOOBAR16** - Run as administrator

```PowerShell
cls
```

### # Move computer to different OU

```PowerShell
$vmName = "STORM"

$targetPath = ("OU=Workstations,OU=Resources,OU=Development" `
    + ",DC=corp,DC=technologytoolbox,DC=com")

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

---

### Login as local administrator account

### # Install NVIDIA display driver

```PowerShell
$setupPath = "\\TT-FS01\Products\Drivers\NVIDIA\GTX-1070" `
    + "\441.41-desktop-win10-64bit-international-whql.exe"

Start-Process -FilePath $setupPath -Wait
```

> **Important**
>
> Wait for the installation to complete.

### # Configure networking

```PowerShell
$interfaceAlias = "LAN"
```

#### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

$interfaceDescription = "Intel(R) Gigabit CT Desktop Adapter"

Get-NetAdapter -InterfaceDescription $interfaceDescription |
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

Start-Sleep -Seconds 5

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

```PowerShell
cls
```

### # Configure storage

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

| Disk | Model                           | Serial Number                  | Capacity | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------------------------- | ------------------------------ | -------- | ------------ | ----------- | -------------------- | ------------ |
| 0    | Samsung SSD 850 PRO 256GB       | \*\*\*\*\*\*\*\*\*19550Z       | 256 GB   | C:           | 235 GB      | 4K                   | System       |
| 1    | Samsung Samsung SSD 860 EVO 1TB | \*\*\*\*\*\*\*\*\*26709R       | 1 TB     | E:           | 931 GB      | 4K                   | Gold01       |
| 2    | WDC WD1001FALS-00E3A0           | WD-\*\*\*\*\*\*283566          | 1 TB     | Z:           | 931 GB      | 4K                   | Backup01     |
| 3    | WDC WD1002FAEX-00Y9A0           | WD-\*\*\*\*\*\*201582          | 1 TB     | F:           | 931 GB      | 4K                   | Bronze01     |
| 4    | ST1000NM0033-9ZM173             | \*\*\*\*\*EMV                  | 1 TB     |              |             |                      |              |
| 5    | ST1000NM0033-9ZM173             | \*\*\*\*\*4YL                  | 1 TB     |              |             |                      |              |
| 6    | Samsung SSD 970 PRO 512GB       | \*\*\*\*\*\*\*\*\*\_81B1_6431. | 512 GB   | D:           |             | 4K                   | Platinum01   |

```PowerShell
Get-PhysicalDisk | sort DeviceId

Get-PhysicalDisk | select DeviceId, Model, SerialNumber, CanPool |
    sort DeviceId | Format-Table -AutoSize
```

```PowerShell
cls
```

#### # Configure partitions and volumes

##### # Rename "Windows" volume to "System"

```PowerShell
Get-Volume -DriveLetter C | Set-Volume -NewFileSystemLabel System
```

```PowerShell
cls
```

## # Install software for HP Photosmart 6515

```PowerShell
$setupPath = "\\TT-FS01\Products\HP\Photosmart 6515\PS6510_1315-1.exe"

Start-Process -FilePath $setupPath -Wait
```

On the **Software Selections** step:

1. Click **Customize Software Selections**.
2. Clear the checkboxes for the following items:
   - **HP Update**
   - **HP Photosmart 6510 series Product Improvement**
   - **Bing Bar for HP (includes HP Smart Print)**
   - **HP Photosmart 6510 series Help**
   - **HP Photo Creations**

[http://support.hp.com/us-en/drivers/selfservice/HP-Photosmart-6510-e-All-in-One-Printer-series---B2/5058334/model/5191793](http://support.hp.com/us-en/drivers/selfservice/HP-Photosmart-6510-e-All-in-One-Printer-series---B2/5058334/model/5191793)

### Disable background apps

1. Open **Windows Settings**.
2. In the **Windows Setttings** window, select **Privacy**.
3. On the **Privacy** page, select **Background apps**.
4. On the **Background apps** page, disable the following apps from running in
   the background:
   - **3D Viewer**
   - **Calculator**
   - **Camera**
   - **Feedback Hub**
   - **Get Help**
   - **Maps**
   - **Microsoft Solitaire Collection**
   - **Microsoft Store**
   - **Mobile Plans**
   - **Movies & TV**
   - **Office**
   - **OneNote**
   - **Paint 3D**
   - **People**
   - **Photos**
   - **Print 3D**
   - **Snip & Sketch**
   - **Sticky Notes**
   - **Tips**
   - **Voice Recorder**
   - **Xbox**
   - **Your Phone**

#### Issue: Photos app consumes high CPU

```PowerShell
cls
```

### # Enable firewall rules for Disk Management

```PowerShell
Enable-NetFirewallRule -DisplayGroup "Remote Volume Management"
```

### # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

```PowerShell
cls
```

### # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

### # Configure firewall rules for [http://poshpaig.codeplex.com/](POSHPAIG)

```PowerShell
Set-ExecutionPolicy RemoteSigned -Scope Process -Force

C:\NotBackedUp\Public\Toolbox\PowerShell\Enable-RemoteWindowsUpdate.ps1 -Verbose
C:\NotBackedUp\Public\Toolbox\PowerShell\Disable-RemoteWindowsUpdate.ps1 `
    -Verbose
```

### Create default folders

> **Important**
>
> Run the following commands using a non-elevated command prompt (to avoid
> issues with customizing the folder icons).

---

```Console
mkdir C:\NotBackedUp\Public\Symbols
mkdir C:\NotBackedUp\Temp
mkdir C:\NotBackedUp\vscode-data
```

---

```PowerShell
cls
```

### # Configure cmder shortcut in Windows Explorer ("Cmder Here")

```PowerShell
C:\NotBackedUp\Public\Toolbox\cmder\Cmder.exe /REGISTER ALL
```

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

### # Create virtual switches

```PowerShell
$interfaceAlias = "LAN"

New-VMSwitch `
    -Name $interfaceAlias `
    -NetAdapterName $interfaceAlias `
    -AllowManagementOS $true
```

### # Enable jumbo frames on virtual switches

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name "vEthernet ($interfaceAlias)" `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

Start-Sleep -Seconds 5

ping TT-FS01 -f -l 8900
```

### Install Microsoft Office

### Install OneNote 2016

### Install Google Chrome

### # Install Bitwarden

```PowerShell
net use \\TT-FS01\Products /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$setupPath = "\\TT-FS01\Products\Bitwarden\Bitwarden-Installer-1.16.6.exe"

Start-Process -FilePath $setupPath -Wait
```

> **Important**
>
> Wait for the installation to complete.

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
$setupPath = "\\TT-FS01\Products\Microsoft\Money 2008\USMoneyBizSunset.exe"

Start-Process -FilePath $setupPath -Wait
```

> **Important**
>
> Wait for the installation to complete.

### Patch Money DLL to avoid crash when importing transactions

1. Open DLL in hex editor:

   ```Console
   C:\NotBackedUp\Public\Toolbox\HxD\HxD.exe "C:\Program Files (x86)\Microsoft Money Plus\MNYCoreFiles\mnyob99.dll"
   ```

2. Make the following changes:

   File offset **003FACE8**: Change **85** to **8D**\
   File offset **003FACED**: Change **50** to **51**\
   File offset **003FACF0**: Change **FF** to **85**\
   File offset **003FACF6**: Change **E8** to **B9**

#### Reference

**Microsoft Money crashes during import of account transactions or when changing
a payee of a downloaded transaction**\
From <[http://blogs.msdn.com/b/oldnewthing/archive/2012/11/13/10367904.aspx](http://blogs.msdn.com/b/oldnewthing/archive/2012/11/13/10367904.aspx)>

```PowerShell
cls
```

### # Configure firewall rule to block Microsoft Money quote service

```PowerShell
New-NetFirewallRule `
    -Name "BlockMicrosoftMoney" `
    -DisplayName "Block Microsoft Money" `
    -Direction Outbound `
    -Program "%ProgramFiles%\Microsoft Money Plus\MNYCoreFiles\msmoney.exe" `
    -Action Block
```

#### Reference

**Eliminating the "online updating"delays and errors when opening Money**\
From <[https://microsoftmoneyoffline.wordpress.com/2016/06/06/eliminating-the-online-updatingdelays-and-errors-when-opening-money/](https://microsoftmoneyoffline.wordpress.com/2016/06/06/eliminating-the-online-updatingdelays-and-errors-when-opening-money/)>

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

```PowerShell
cls
```

#### # Overwrite file with custom template

```PowerShell
Copy-Item `
    'C:\Users\jjameson\OneDrive - Technology Toolbox\InvoiceTemplate.htm' `
    'C:\Users\All Users\Microsoft\Money\17.0\Invoice\usr19.htm'
```

#### Configure default invoice template

Edit invoice listing (2008Invoice.ntd) to move the "Technology Toolbox" invoice
to the top (so it is selected by default).

```Console
Notepad "C:\Users\All Users\Microsoft\Money\17.0\Invoice\2008Invoice.ntd"
```

#### Reference

**Sunset Home & Business - Invoice issues**\
From <[https://microsoftmoneyoffline.wordpress.com/sunset-home-business-invoices/](https://microsoftmoneyoffline.wordpress.com/sunset-home-business-invoices/)>

### Install and configure MSMoneyQuotes

```PowerShell
cls
```

### # Install Python 2 (dependency for PocketSense)

#### # Install Python (using default options)

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$setupPath = "\\TT-FS01\Products\Python\python-2.7.15.amd64.msi"

Start-Process -FilePath $setupPath -Wait
```

> **Important**
>
> Wait for the installation to complete.

```PowerShell
cls
```

#### # Add Python folders to PATH environment variable

```PowerShell
Set-ExecutionPolicy RemoteSigned -Scope Process -Force

$pythonPathFolders = 'C:\Python27\', 'C:\Python27\Scripts'

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-PathFolders.ps1 `
    -Folders $pythonPathFolders `
    -EnvironmentVariableTarget Machine
```

### # Copy PocketSense files

```PowerShell
$source = "\\TT-FS01\Users$\jjameson\My Documents\Finances\MS Money\PocketSense"
$destination = "C:\BackedUp\MS Money\PocketSense"

robocopy $source $destination /E
```

```PowerShell
cls
```

## # Configure backup

### # Install DPM agent

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\System Center 2019" `
    + "\DPM\Agents\DPMAgentInstaller_x64.exe"

$installerArguments = "TT-DPM05.corp.technologytoolbox.com"

Start-Process `
    -FilePath $installerPath `
    -ArgumentList "$installerArguments" `
    -Wait
```

Review the licensing agreement. If you accept the Microsoft Software License
Terms, select **I accept the license terms and conditions**, and then click
**OK**.

Confirm the agent installation completed successfully and the following firewall
exceptions have been added:

- Exception for DPMRA.exe in all profiles
- Exception for Windows Management Instrumentation service
- Exception for RemoteAdmin service
- Exception for DCOM communication on port 135 (TCP and UDP) in all profiles

#### Reference

**Installing Protection Agents Manually**\
Pasted from <[http://technet.microsoft.com/en-us/library/hh757789.aspx](http://technet.microsoft.com/en-us/library/hh757789.aspx)>

---

**TT-ADMIN02** - DPM Management Shell

```PowerShell
cls
```

### # Attach DPM agent

```PowerShell
$productionServer = 'STORM'

.\Attach-ProductionServer.ps1 `
    -DPMServerName TT-DPM05 `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `
    -UserName jjameson-admin
```

---

### Add virtual machine to DPM protection group

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
$imagePath = ("\\TT-FS01\Products\Microsoft\SQL Server 2017" `
    + "\en_sql_server_2017_developer_x64_dvd_11296168.iso")

$imageDriveLetter = (Mount-DiskImage -ImagePath $ImagePath -PassThru |
    Get-Volume).DriveLetter

& ("$imageDriveLetter" + ":\setup.exe")
```

On the **Feature Selection** step, click **Select All** and then clear the
checkbox for **PolyBase Query Service for External Data** (since this requires
the Java Runtime Environment to be installed).

On the **Server Configuration** page:

- For **SQL Server Database Engine**, change the **Startup Type** to **Manual**.
- For **SQL Server Analysis Services**, change the **Startup Type** to
  **Manual**.
- For **SQL Server Integration Services 14.0**, change the **Startup Type** to
  **Manual**.
- For **SQL Server Integration Services Scale Out Master 14.0**, change the
  **Startup Type** to **Manual**.
- For **SQL Server Integration Services Scale Out Worker 14.0**, change the
  **Startup Type** to **Manual**.

On the **Database Engine Configuration** page:

- On the **Server Configuration** tab, click **Add Current User**.
- On the **Data Directories** tab:
  - Change the **Data root directory** to **D:\\NotBackedUp\\Microsoft SQL
    Server\\**
  - Change the **Backup directory** to **Z:\\Microsoft SQL
    Server\\MSSQL14.MSSQLSERVER\\MSSQL\\Backup**

On the **Analysis Services Configuration** page:

- On the **Server Configuration** tab, click **Add Current User**.
- On the **Data Directories** tab:
  - Change the **Data directory** to **D:\\NotBackedUp\\Microsoft SQL
    Server\\MSAS14.MSSQLSERVER\\OLAP\\Data.**
  - Change the **Log file directory** to **D:\\NotBackedUp\\Microsoft SQL
    Server\\MSAS14.MSSQLSERVER\\OLAP\\Log.**
  - Change the **Temp directory** to **D:\\NotBackedUp\\Microsoft SQL
    Server\\MSAS14.MSSQLSERVER\\OLAP\\Temp.**
  - Change the **Backup directory** to **Z:\\NotBackedUp\\Microsoft SQL
    Server\\MSAS14.MSSQLSERVER\\OLAP\\Backup**.

On the **Distributed Replay Controller** page, click **Add Current User**.

On the **Distributed Replay Client** page:

- On the **Server Configuration** tab, click **Add Current User**.
  - Change the **Working Directory** to **D:\\NotBackedUp\\Microsoft SQL
    Server\\DReplayClient\\WorkingDir\\.**
  - Change the **Result Directory** to **D:\\NotBackedUp\\Microsoft SQL
    Server\\DReplayClient\\ResultDir\\.**

```PowerShell
cls
```

### # Remove installation media

```PowerShell
Dismount-DiskImage $imagePath
```

### # Install cumulative update for SQL Server

```PowerShell
& "\\TT-FS01\Products\Microsoft\SQL Server 2017\Patches\CU17\SQLServer2017-KB4515579-x64.exe"
```

```PowerShell
cls
```

### # Configure settings for SQL Server Agent job history log

#### # Do not limit size of SQL Server Agent job history log

```PowerShell
$sqlcmd = @"
EXEC msdb.dbo.sp_set_sqlagent_properties @jobhistory_max_rows=-1,
    @jobhistory_max_rows_per_job=-1
```

"@

```PowerShell
Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

##### Reference

**SQL SERVER - Dude, Where is the SQL Agent Job History? - Notes from the Field
#017**\
From <[https://blog.sqlauthority.com/2014/02/27/sql-server-dude-where-is-the-sql-agent-job-history-notes-from-the-field-017/](https://blog.sqlauthority.com/2014/02/27/sql-server-dude-where-is-the-sql-agent-job-history-notes-from-the-field-017/)>

```PowerShell
cls
```

#### # Configure SQL Server maintenance

##### # Create database for SQL Server maintenance

```PowerShell
$sqlcmd = "CREATE DATABASE SqlMaintenance"

Invoke-Sqlcmd $sqlcmd -Verbose -Debug:$false

Set-Location C:
```

##### # Create maintenance table, stored procedures, and jobs

```PowerShell
$url = "https://raw.githubusercontent.com/technology-toolbox" `
    + "/sql-server-maintenance-solution/master/MaintenanceSolution.sql"

$tempFileName = [System.IO.Path]::GetTempFileName()

Invoke-WebRequest -Uri $url -OutFile $tempFileName

Invoke-Sqlcmd -InputFile $tempFileName -Verbose -Debug:$false

Set-Location C:

Remove-Item $tempFileName
```

##### # Configure schedules for SQL Server maintenance jobs

```PowerShell
$url = "https://raw.githubusercontent.com/technology-toolbox" `
    + "/sql-server-maintenance-solution/master/JobSchedules.sql"

$tempFileName = [System.IO.Path]::GetTempFileName()

Invoke-WebRequest -Uri $url -OutFile $tempFileName

Invoke-Sqlcmd -InputFile $tempFileName -Verbose -Debug:$false

Set-Location C:

Remove-Item $tempFileName
```

##### Reference

**SQL Server Backup, Integrity Check, and Index and Statistics Maintenance**\
From <[https://ola.hallengren.com/](https://ola.hallengren.com/)>

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
    + "\VSCodeSetup-x64-1.40.2.exe"

$arguments = "/silent" `
    + " /mergetasks='!runcode,addcontextmenufiles,addcontextmenufolders" `
        + ",addtopath'"

Start-Process `
    -FilePath $setupPath `
    -ArgumentList $arguments `
    -Wait
```

> **Important**
>
> Wait for the installation to complete.

### Issue

**Installer doesn't disable launch of VScode even when installing with
/mergetasks=!runcode**\
From <[https://github.com/Microsoft/vscode/issues/46350](https://github.com/Microsoft/vscode/issues/46350)>

### Modify Visual Studio Code shortcut to use custom extension and user data locations

```Console
"C:\Program Files\Microsoft VS Code\Code.exe" --extensions-dir "C:\NotBackedUp\vscode-data\extensions" --user-data-dir "C:\NotBackedUp\vscode-data\user-data"
```

### Install Visual Studio Code extensions

#### Install extension: Azure Resource Manager Tools

#### Install extension: Beautify

#### TODO: Install extension: C/C++

```PowerShell
ms-vscode.cpptools
```

#### Install extension: C&#35;

#### Install extension: Debugger for Chrome

#### TODO: Install extension: ES7 React/Redux/GraphQL/React-Native snippets

```Text
dsznajder.es7-react-js-snippets
```

#### Install extension: ESLint

#### Install extension: GitLens - Git supercharged

#### Install extension: markdownlint

#### Install extension: PowerShell

#### Install extension: Prettier - Code formatter

#### Install extension: SQL Server (mssql)

#### Install extension: TSLint

#### TODO: Install extension: VBScript

```Text
darfka.vbscript
```

#### Install extension: vscode-icons

#### Install extension: XML Tools

---

> **Notes**
>
> Potential issue when using both Beautify and Prettier extensions:
>
> **Prettier & Beautify**\
> From <[https://css-tricks.com/prettier-beautify/](https://css-tricks.com/prettier-beautify/)>
>
> HTML formatting issue with Prettier:
>
> **Add the missing option to disable crappy Prettier VSCode HTML formatter
> #636**\
> From <[https://github.com/prettier/prettier-vscode/issues/636](https://github.com/prettier/prettier-vscode/issues/636)>

---

#### Configure Visual Studio Code settings

1. Press **Ctrl+Shift+P**
2. Select **Preferences: Open Settings (JSON)**

---

File - **settings.json**

```JSON
{
    "editor.formatOnSave": true,
    "editor.renderWhitespace": "boundary",
    "editor.rulers": [80],
    "files.trimTrailingWhitespace": true,
    "git.autofetch": true,
    "html.format.wrapLineLength": 80,
    "prettier.disableLanguages": ["html"],
    "terminal.integrated.shell.windows":
        "C:\\windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe",
    "workbench.iconTheme": "vscode-icons"
}
```

---

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

### Install .NET Core 2.2 SDK

[https://dotnet.microsoft.com/download/dotnet-core/thank-you/sdk-2.2.207-windows-x64-installer](https://dotnet.microsoft.com/download/dotnet-core/thank-you/sdk-2.2.207-windows-x64-installer)

#### Reference

**Download .NET Core 2.2**\
From <[https://dotnet.microsoft.com/download/dotnet-core/2.2](https://dotnet.microsoft.com/download/dotnet-core/2.2)>

```PowerShell
cls
```

### # Install .NET Framework 4.6.2 Developer Pack

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$setupPath = "\\TT-FS01\Public\Download\Microsoft\dotNet" `
    + "\NDP462-DevPack-KB3151934-ENU.exe"

Start-Process -FilePath $setupPath -Wait
```

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
$setupPath = "\\TT-FS01\Products\Git\Git-2.24.0-64-bit.exe"

Start-Process -FilePath $setupPath -Wait
```

On the **Choosing the default editor used by Git** step, select **Use the Nano
editor by default**.

> **Important**
>
> Wait for the installation to complete and restart PowerShell for environment
> changes to take effect.

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

## # Install GitKraken

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$setupPath = "\\TT-FS01\Products\Axosoft\GitKrakenSetup-6.3.1.exe"

Start-Process -FilePath $setupPath -Wait
```

> **Important**
>
> Wait for the installation to complete.

```PowerShell
cls
```

## # Install and configure Node.js

### # Install Node.js

```PowerShell
net use \\EXT-FS01\IPC$ /USER:EXTRANET\jjameson-admin
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$setupPath = "\\TT-FS01\Products\node.js\node-v12.13.1-x64.msi"

Start-Process -FilePath $setupPath -Wait
```

> **Important**
>
> Wait for the installation to complete. Restart PowerShell for the change to
> PATH environment variable to take effect.

```Console
exit
```

### # Change NPM file locations to avoid issues with redirected folders

```PowerShell
notepad "C:\Program Files\nodejs\node_modules\npm\npmrc"
```

---

File - **C:\\Program Files\\nodejs\\node_modules\\npm\\npmrc**

```Text
;prefix=${APPDATA}\npm
prefix=${LOCALAPPDATA}\npm
cache=${LOCALAPPDATA}\npm-cache
```

---

```PowerShell
cls
```

## # Install PowerShell modules

### # Install posh-git module (e.g. for Powerline Git prompt customization)

#### # Install NuGet package provider (to bypass prompt when installing posh-git module)

```PowerShell
Install-PackageProvider NuGet -MinimumVersion '2.8.5.201' -Force
```

#### # Trust PSGallery repository (to bypass prompt when installing posh-git module)

```PowerShell
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
```

### # Install PowerShell for GitHub API

```PowerShell
Install-Module -Name PowerShellForGitHub
```

#### # Install posh-git module

```PowerShell
Install-Module -Name 'posh-git'
```

### Upgrade Azure PowerShell module

#### Remove AzureRM module

1. Open **Programs and Features**
2. Uninstall **Microsoft Azure PowerShell - April 2018**

```PowerShell
cls
```

#### # Install new Azure PowerShell module

```PowerShell
Install-Module -Name Az -AllowClobber -Scope AllUsers
```

```PowerShell
cls
```

## # Install development tools

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

```PowerShell
cls
```

### # Install SharePoint Online Management Shell

```PowerShell
$installerPath = "\\TT-FS01\Public\Download\Microsoft\SharePoint\Online" `
    + "\SharePointOnlineManagementShell_19418-12000_x64_en-us.msi"

Start-Process `
    -FilePath msiexec.exe `
    -ArgumentList "/i `"$installerPath`"" `
    -Wait
```

> **Important**
>
> Wait for the installation to complete.

```PowerShell
cls
```

### # Install SharePoint PnP cmdlets

```PowerShell
Install-Module SharePointPnPPowerShellOnline
```

```PowerShell
cls
```

### # Install Chocolatey

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

### # Install HTML Tidy

```PowerShell
choco install html-tidy
```

The recent package changes indicate a reboot is necessary.\
Please reboot at your earliest convenience.

```PowerShell
Restart-Computer
```

### # Install Minikube

```PowerShell
choco install minikube
```

```PowerShell
cls
```

#### # Start Minikube

```PowerShell
minikube start --vm-driver=hyperv
```

#### Reference

**Install Minikube**\
From <[https://kubernetes.io/docs/tasks/tools/install-minikube/](https://kubernetes.io/docs/tasks/tools/install-minikube/)>

```PowerShell
cls
```

### # Install FileZilla

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$setupPath =
"\\TT-FS01\Products\FileZilla\FileZilla_3.46.0_win64-setup.exe"

Start-Process -FilePath $setupPath -Wait
```

```PowerShell
cls
```

### # Install Postman

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$setupPath = "\\TT-FS01\Products\Postman\Postman-win64-7.13.0-Setup.exe"

Start-Process -FilePath $setupPath -Wait
```

```PowerShell
cls
```

### # Install Fiddler

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$setupPath = "\\TT-FS01\Products\Telerik\FiddlerSetup.exe"

$arguments = "/S /D=C:\Program Files\Telerik\Fiddler"

Start-Process `
    -FilePath $setupPath `
    -ArgumentList $arguments `
    -Wait
```

### Reference

**Default Install Path**\
[https://www.telerik.com/forums/default-install-path#t8qFEfoMnUWlg50zptFlHQ](https://www.telerik.com/forums/default-install-path#t8qFEfoMnUWlg50zptFlHQ)

```PowerShell
cls
```

### # Install Microsoft Message Analyzer

```PowerShell
$setupPath = "\\TT-FS01\Products\Microsoft\Message Analyzer 1.4\MessageAnalyzer64.msi"

Start-Process -FilePath $setupPath -Wait
```

> **Important**
>
> Wait for the installation to complete.

"Windows blocked the installation of a digitally unsigned driver..."

**Microsoft Message Anlayzer 1.4 - 'A Digitally Signed Driver Is Required'**\
From <[https://social.technet.microsoft.com/Forums/windows/en-US/48b4c226-fc3d-4793-b544-3440ed13424a/microsoft-message-anlayzer-14-a-digitally-signed-driver-is-required?forum=messageanalyzer](https://social.technet.microsoft.com/Forums/windows/en-US/48b4c226-fc3d-4793-b544-3440ed13424a/microsoft-message-anlayzer-14-a-digitally-signed-driver-is-required?forum=messageanalyzer)>

```PowerShell
cls
```

### # Install Wireshark

```PowerShell
$setupPath = "\\TT-FS01\Products\Wireshark\Wireshark-win64-3.0.7.exe"

Start-Process -FilePath $setupPath -Wait
```

> **Important**
>
> Wait for the installation to complete.

```PowerShell
cls
```

### # Install Microsoft Log Parser 2.2

```PowerShell
$setupPath = "\\TT-FS01\Public\Download\Microsoft\LogParser 2.2\LogParser.msi"

Start-Process -FilePath $setupPath -Wait
```

> **Important**
>
> Wait for the installation to complete.

```PowerShell
cls
```

### # Install Remote Desktop Connection Manager

```PowerShell
$setupPath = "\\TT-FS01\Products\Microsoft" `
    + "\Remote Desktop Connection Manager\rdcman.msi"

Start-Process -FilePath $setupPath -Wait
```

> **Important**
>
> Wait for the installation to complete.

```PowerShell
cls
```

### # Install Microsoft Expression Studio 4

### # Copy installation media from internal file server

```PowerShell
$isoFile = "en_expression_studio_4_ultimate_x86_dvd_537032.iso"

$source = "\\TT-FS01\Products\Microsoft\Expression Studio"

$destination = "C:\NotBackedUp\Temp"

robocopy $source $destination $isoFile
```

### Install Expression Studio

Use the "Toolbox" script to install Expression Studio

```PowerShell
cls
```

## # Install Paint.NET

```PowerShell
& "\\TT-FS01\Products\Paint.NET\paint.net.4.2.8.install.zip"
```

> **Important**
>
> Wait for the installation to complete.

```PowerShell
cls
```

## # Configure development environment

### # Configure NuGet global package location

```PowerShell
[Environment]::SetEnvironmentVariable(
    "NUGET_PACKAGES",
    "C:\NotBackedUp\.nuget\packages",
    "Machine")
```

### # Configure symbol path for debugging

```PowerShell
$symbolPath = "SRV*C:\NotBackedUp\Public\Symbols" `
     + "*\\TT-FS01\Public\Symbols" `
     + "*https://msdl.microsoft.com/download/symbols"

[Environment]::SetEnvironmentVariable(
    "_NT_SYMBOL_PATH",
    $symbolPath,
    "Machine")
```

```PowerShell
cls
```

### # Install reference assemblies

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$source = '\\TT-FS01\Builds\Reference Assemblies'
$destination = 'C:\Program Files\Reference Assemblies'

robocopy $source $destination /E

& "$destination\Microsoft\SharePoint v4\AssemblyFoldersEx - x64.reg"
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/62/DE96621F16BC51A75B6410BE1B94F33F9B8A0F62.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5E/06DBAE68F16F7F83442A5F1916BFBEFEFC0DD15E.png)

```PowerShell
& "$destination\Microsoft\SharePoint v5\AssemblyFoldersEx - x64.reg"
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AE/E9FD2601E62121DA76E1227B4436C7ED8F069CAE.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BB/9A7DF5FF756E44DAC0D8F600AA2D457598370EBB.png)

```PowerShell
cls
```

## # Configure hosts file

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    -IPAddress 10.1.20.99 `
    -Hostnames EXT-VS2017-DEV2, www-local.technologytoolbox.com
```

```PowerShell
cls
```

## # Download PowerShell help files

```PowerShell
Update-Help
```

## Install updates using Windows Update

> **Note**
>
> Repeat until there are no updates available for the computer.

## Disk Cleanup

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

## # Enter a product key and activate Windows

```PowerShell
slmgr /ipk {product key}
```

**Note:** When notified that the product key was set successfully, click **OK**.

```Console
slmgr /ato
```

## Configure profile for TECHTOOLBOX\\jjameson

> **Important**
>
> Login as TECHTOOLBOX\\jjameson

### Disable background apps

1. Open **Windows Settings**.
2. In the **Windows Setttings** window, select **Privacy**.
3. On the **Privacy** page, select **Background apps**.
4. On the **Background apps** page, disable the following apps from running in
   the background:
   - **3D Viewer**
   - **Calculator**
   - **Camera**
   - **Feedback Hub**
   - **Get Help**
   - **Maps**
   - **Microsoft Photos**
   - **Microsoft Solitaire Collection**
   - **Microsoft Store**
   - **Mobile Plans**
   - **Movies & TV**
   - **Office**
   - **OneNote**
   - **Paint 3D**
   - **People**
   - **Print 3D**
   - **Snip & Sketch**
   - **Sticky Notes**
   - **Tips**
   - **Voice Recorder**
   - **Your Phone**

#### Issue: Photos app consumes high CPU

```PowerShell
cls
```

### # Configure e-mail and name for Git

```PowerShell
git config --global user.email "jjameson@technologytoolbox.com"
git config --global user.name "Jeremy Jameson"
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

### # Configure personal access token for GitHub PowerShell module

Set-GitHubAuthentication

```PowerShell
cls
```

### # Install GitHub Desktop

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

### # Add NPM "global" location to PATH environment variable

```PowerShell
Set-ExecutionPolicy RemoteSigned -Scope Process -Force

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-PathFolders.ps1 `
    -Folders "$env:LOCALAPPDATA\npm" `
    -EnvironmentVariableTarget User
```

> **Important**
>
> Restart PowerShell for the change to PATH environment variable to take effect.

```Console
exit
```

### Install global NPM packages

> **Important**
>
> Install global NPM packages using a non-elevated instance of PowerShell (to
> avoid issues when subsequently running the npm install command as a "normal"
> user).

---

**Non-elevated** PowerShell instance

```PowerShell
cls
```

### # Install Angular CLI

```PowerShell
npm install --global --no-optional @angular/cli@7.3.9
```

### # Install Bitwarden CLI

```PowerShell
npm install --global @bitwarden/cli
```

### # Install Create React App

```PowerShell
npm install --global --no-optional create-react-app@3.2.0
```

### # Install rimraf

```PowerShell
npm install --global --no-optional rimraf@3.0.0
```

### # Install Yeoman, Gulp, and web app generator

```PowerShell
npm install --global --no-optional yo gulp-cli generator-webapp
```

---

#### Reference

**Web app generator**\
From <[https://www.npmjs.com/package/generator-webapp](https://www.npmjs.com/package/generator-webapp)>

```PowerShell
cls
```

## # Upgrade Git

### # Install Git

```PowerShell
$setupPath = "\\TT-FS01\Products\Git\Git-2.24.1.2-64-bit.exe"

Start-Process -FilePath $setupPath -Wait
```

On the **Choosing the default editor used by Git** step, select **Use the Nano
editor by default**.

> **Important**
>
> Wait for the installation to complete and restart PowerShell for environment
> changes to take effect.

## Replace DPM server (TT-DPM05 --> TT-DPM06)

```PowerShell
cls
```

### # Update DPM server

```PowerShell
cd 'C:\Program Files\Microsoft Data Protection Manager\DPM\bin\'

.\SetDpmServer.exe -dpmServerName TT-DPM06.corp.technologytoolbox.com
```

---

**TT-ADMIN04** - DPM Management Shell

```PowerShell
cls
```

### # Attach DPM agent

```PowerShell
$productionServer = 'STORM'

.\Attach-ProductionServer.ps1 `
    -DPMServerName TT-DPM06 `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `
    -UserName jjameson-admin
```

---

That doesn't work...

> Error:\
> Data Protection Manager Error ID: 307\
> The protection agent operation failed because DPM detected an unknown DPM
> protection agent on storm.corp.technologytoolbox.com.
>
> Recommended action:\
> Use Add or Remove Programs in Control Panel to uninstall the protection agent from
> storm.corp.technologytoolbox.com, then reinstall the protection agent and perform
> the operation again.

```PowerShell
cls
```

### # Remove DPM 2019 Agent Coordinator

```PowerShell
msiexec /x `{356B3986-6B7D-4513-B72D-81EB4F43ADE6`}
```

```PowerShell
cls
```

### # Remove DPM 2019 Protection Agent

```PowerShell
msiexec /x `{CC6B6758-3A68-4BBA-9D61-1F3278D6A7EA`}
```

> **Important**
>
> Restart the computer to complete the removal of the DPM agent.

```PowerShell
Restart-Computer
```

### # Install DPM 2019 agent

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\System Center 2019" `
    + "\DPM\Agents\DPMAgentInstaller_x64.exe"

$installerArguments = "TT-DPM06.corp.technologytoolbox.com"

Start-Process `
    -FilePath $installerPath `
    -ArgumentList "$installerArguments" `
    -Wait
```

---

**TT-ADMIN04** - DPM Management Shell

```PowerShell
cls
```

### # Attach DPM agent

```PowerShell
$productionServer = 'STORM'

.\Attach-ProductionServer.ps1 `
    -DPMServerName TT-DPM06 `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `
    -UserName jjameson-admin
```

---

### Add client to protection group in DPM

```PowerShell
cls
```

### # Configure antivirus on DPM protected server

#### # Disable real-time monitoring by Windows Defender for DPM server

```PowerShell
[array] $excludeProcesses = Get-MpPreference | select -ExpandProperty ExclusionProcess

$excludeProcesses +=
   "$env:ProgramFiles\Microsoft Data Protection Manager\DPM\bin\DPMRA.exe"

Set-MpPreference -ExclusionProcess $excludeProcesses
```

#### # Configure antivirus software to delete infected files

```PowerShell
Set-MpPreference -LowThreatDefaultAction Remove
Set-MpPreference -ModerateThreatDefaultAction Remove
Set-MpPreference -HighThreatDefaultAction Remove
Set-MpPreference -SevereThreatDefaultAction Remove
```

#### Reference

**Run antivirus software on the DPM server**\
From <[https://docs.microsoft.com/en-us/system-center/dpm/run-antivirus-server?view=sc-dpm-2019](https://docs.microsoft.com/en-us/system-center/dpm/run-antivirus-server?view=sc-dpm-2019)>

## Install Docker for Windows

### Reference

[Install Docker Desktop on Windows](https://docs.docker.com/docker-for-windows/install/)

### Install Windows Subsystem for Linux (WSL)

#### Reference

[Windows Subsystem for Linux Installation Guide for Windows 10](https://docs.microsoft.com/en-us/windows/wsl/install-win10)

```PowerShell
cls
```

#### # Enable Windows Subsystem for Linux

```PowerShell
dism.exe /online /enable-feature `
    /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
```

```PowerShell
cls
```

#### # Enable Virtual Machine feature

```PowerShell
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all `
    /norestart
```

#### Download and install Linux kernel update package

[WSL2 Linux kernel update package for x64 machines](https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi)

```PowerShell
cls
```

#### # Set WSL 2 as default version

```PowerShell
wsl --set-default-version 2
```

#### Install Linux distribution of choice

[Ubuntu 20.04 LTS](https://www.microsoft.com/store/apps/9n6svws3rx71)

### Install Docker Desktop

[Docker Desktop for Windows](https://desktop.docker.com/win/stable/amd64/Docker%20Desktop%20Installer.exe)

### Install additional Visual Studio Code extensions for Docker development

#### Install extension: Docker

```Text
ext install ms-azuretools.vscode-docker
```

#### Install extension: Kubernetes

```Text
ext install ms-kubernetes-tools.vscode-kubernetes-tools
```

#### Install extension: Remote - Containers

```Text
ext install ms-vscode-remote.remote-containers
```

#### Install extension: Remote - WSL

```Text
ext install ms-vscode-remote.remote-wsl
```

**TODO:**

## Share printer

![(screenshot)](https://assets.technologytoolbox.com/screenshots/01/2EDCC101189FC9A8E4E5FD9205D12E8EB82B2F01.png)

Click **Change Sharing Options**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/94/39D600ED528C73CAE3772FDA8A9E263E29CBF094.png)

## Other stuff that may need to be done

```PowerShell
cls
```

### # Configure credential helper for Git

```PowerShell
git config --global credential.helper !"C:\\NotBackedUp\\Public\\Toolbox\\git-credential-winstore.exe"
```

```PowerShell
cls
```

### # Install OpenCV

```PowerShell
setx -m OPENCV_DIR "C:\Program Files\OpenCV-3.4.6\opencv\build\x64\vc15"
```

#### # Add OpenCV bin folder to PATH environment variable

```PowerShell
Set-ExecutionPolicy RemoteSigned -Scope Process -Force

$openCVPathFolder = "%OPENCV_DIR%\bin"

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-PathFolders.ps1 `
    -Folders $openCVPathFolder `
    -EnvironmentVariableTarget Machine
```

```PowerShell
cls
```

### # Install Microsoft InfoPath 2013

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$setupPath = "\\TT-FS01\Products\Microsoft\Office 2013" `
    + "\infopath_4753-1001_x86_en-us.exe"

Start-Process `
    -FilePath $setupPath `
    -Wait
```

> **Important**
>
> Wait for the installation to complete.

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

### Install Apple iTunes

### Install ASP.NET ViewState Helper 2.0.1

### Install Inkscape 0.48

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

```PowerShell
cls
```

## # Create and configure Caelum website

### # Set environment variables

```PowerShell
[Environment]::SetEnvironmentVariable(
  "CAELUM_URL",
  "http://www-local.technologytoolbox.com",
  "Machine")
```

> **Important**
>
> Restart PowerShell for environment variable to be available.

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    -IPAddress 127.0.0.1 `
    -Hostnames www-local.technologytoolbox.com
```

### # Rebuild website

```PowerShell
cd "C:\NotBackedUp\techtoolbox\Caelum\Main\Source\Deployment Files\Scripts"

& '.\Rebuild Website.ps1'
```

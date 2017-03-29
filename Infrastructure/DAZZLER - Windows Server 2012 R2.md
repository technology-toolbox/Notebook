# DAZZLER - Windows Server 2012 R2 Standard

Monday, September 14, 2015
9:23 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

---

**FOOBAR8**

## Create VM using Virtual Machine Manager

- Processors: **2**
- Memory: **Dynamic**
- Startup memory: **2 GB**
- Minimum memory: **512 MB**
- Maximum memory: **4 GB**
- VHD size (GB): **45**
- VHD file name:** DAZZLER**
- Virtual DVD drive: **[\\\\ICEMAN\\Products\\Microsoft\\MDT-Deploy-x86.iso](\\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso)**
- Network Adapter 1:** Virtual LAN 2 - 192-168.10.x**
- Host:** STORM**
- Automatic actions
  - **Turn on the virtual machine if it was running with the physical server stopped**
  - **Save State**
  - Operating system: **Windows Server 2012 R2 Standard**

---

## Install custom Windows Server 2012 R2 image

- On the **Task Sequence** step, select **Windows Server 2012 R2** and click **Next**.
- On the **Computer Details** step, in the **Computer name** box, type **DAZZLER** and click **Next**.
- On the **Applications** step, do not select any applications, and click **Next**.

## # Rename local Administrator account and set password

```PowerShell
$adminUser = [ADSI] 'WinNT://./Administrator,User'
$adminUser.Rename('foo')
$adminUser.SetPassword('{password}')

logoff
```

```PowerShell
cls
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

## # Rename network connection

```PowerShell
Get-NetAdapter -Physical

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "LAN 1 - 192.168.10.x"
```

## # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name "LAN 1 - 192.168.10.x" `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping ICEMAN -f -l 8900
```

```PowerShell
cls
```

## # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

## # Enable firewall rules for inbound "ping" requests (required for POSHPAIG)

```PowerShell
$profile = Get-NetFirewallProfile "Domain"

Get-NetFirewallRule -AssociatedNetFirewallProfile $profile |
    Where-Object { $_.DisplayName -eq "File and Printer Sharing (Echo Request - ICMPv4-In)" `
        -or $_.DisplayName -eq "File and Printer Sharing (Echo Request - ICMPv6-In)" } |
    Enable-NetFirewallRule
```

## # Configure firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
New-NetFirewallRule `
    -Name 'Remote Windows Update (Dynamic RPC)' `
    -DisplayName 'Remote Windows Update (Dynamic RPC)' `
    -Description 'Allows remote auditing and installation of Windows updates via POSHPAIG (http://poshpaig.codeplex.com/)' `
    -Group 'Technology Toolbox (Custom)' `
    -Program '%windir%\system32\dllhost.exe' `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort RPC `
    -Profile Domain `
    -Action Allow
```

## Install TFS 2015

---

**FOOBAR8**

### # Insert the TFS 2015 installation media

```PowerShell
$vmHost = 'STORM'
$vmName = 'DAZZLER'

$isoPath = '\\ICEMAN\Products\Microsoft\Team Foundation Server 2015\en_visual_studio_team_foundation_server_2015_x86_x64_dvd_6909713.iso'

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $isoPath
```

---

```PowerShell
cls
```

### # Launch TFS setup

```PowerShell
& X:\tfs_server.exe
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EA/6D39BC62E175B233B1441C7C6FB65024A2604FEA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D4/4DA3F24CA364993CF60A7D5B90046260FBA7A3D4.png)

Wait for the installation to finish. The Team Foundation Server Configuration Center appears.

## Configure TFS build service

![(screenshot)](https://assets.technologytoolbox.com/screenshots/11/EA8A19941D52DBDF0474BE6D3945F2290E1FF311.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5D/275DC32A855B6954CFF5A9491EF0CE0AA8DE095D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/14/85713281FFF5FE1FB188972BA9850BB79AE6AE14.png)

Click **Browse**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D9/7437EFA2C795F5A5805FFC66D85D36E3FCBFC8D9.png)

Click **Servers...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4B/E38081C7B25FADBA13091BDBCDAE4E13E3592E4B.png)

Click **Add...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/61/50A910F58DB543DEF3EA4DC855EAA0E05046BB61.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D0/161C14CC854832335E9A0ADB9CF0E25D606A73D0.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/35/B99099CDB96BE50644EF3E18371C992EEDD07E35.png)

Click **Close**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D7/8FBDD55D163131A68054E7D6D2912F426A9208D7.png)

Click **Connect**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/98/B122469608FCD9655ACA4C540F92C3AE797AE898.png)

Click **No**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/54/AD0123D29CDA54FE7AA7E8DCC647CC5E86B30D54.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3C/CC8000F3C49CF64758A75BACAF2C4C5AE2FA193C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7E/5931A738A34379B9DDD4702D160501A2D3F4CF7E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/69/DD7564DC51D4E22EF36345EABD748E5AA432C669.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EF/D5D3BC92F4DC5B909DC92410E6B71E057B1C0AEF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/21/D918193BF6F58B66DEA45A483A53F2483080ED21.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/66/D6F5A38658A15A5BB75C24A02C40457559FDEE66.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/18/F51B74A9137355C9F1AF5EFBB33CF212C7D19018.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2C/166961C21FDA6CBD1255196C7C2B17AC0772DB2C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A7/EF08C700F48D205A19D110C76C6849BA74888DA7.png)

## Configure permissions on drop folder for TFS builds

```Console
icacls \\ICEMAN\D$\Shares\Builds /grant 'TECHTOOLBOX\s-tfs-build:(OI)(CI)(M)'
```

The above works, but it is faster to run it locally...

```Console
icacls D:\Shares\Builds /grant 'TECHTOOLBOX\s-tfs-build:(OI)(CI)(M)'
```

## Install Visual Studio 2010

---

**FOOBAR8**

### # Insert the Visual Studio 2010 installation media

```PowerShell
$vmHost = 'STORM'
$vmName = 'DAZZLER'

$isoPath = '\\ICEMAN\Products\Microsoft\Visual Studio 2010\en_visual_studio_2010_ultimate_x86_dvd_509116.iso'

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $isoPath
```

---

```PowerShell
cls
```

### # Launch Visual Studio 2010 setup

```PowerShell
& X:\setup.exe
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/88/146E5D20C292D377FC2574871795AD229670AD88.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DA/DA0C1589B3BAD5304249A682D122CC402C959ADA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8E/38456F55A159451E4B397C071FE4BE910C77BD8E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4C/3789D61F70E1CD7860B481EAF6012D2619B7244C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9F/968CB57C822C2204B5A9B64F2FF0B2B1A234CC9F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/21/4E671485E5C0D0E4ADF9D9AD38EB7B296FD63621.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C6/F9D3B082A70D27B613213911583781844580BAC6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/05/69127FB9449719D20CF70F4D249D7118781A0205.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C6/AC1F23424AF5A0DF2FAF8717FD82D96D227AD3C6.png)

## Install Visual Studio 2010 Service Pack 1

---

**FOOBAR8**

### # Insert the Visual Studio 2010 SP1 installation media

```PowerShell
$vmHost = 'STORM'
$vmName = 'DAZZLER'

$isoPath = '\\ICEMAN\Products\Microsoft\Visual Studio 2010\Patches\Service Pack 1\mu_visual_studio_2010_sp1_x86_x64_dvd_651704.iso'

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $isoPath
```

---

```PowerShell
cls
```

### # Launch Visual Studio 2010 SP1 setup

```PowerShell
& X:\Setup.exe
```

```PowerShell
cls
```

## # Install Visual Studio 2015

**Note:** Windows Identity Foundation is a prerequisite for installing the Microsoft Office Developer Tools feature in Visual Studio 2015.

### # Install Windows Identity Foundation 3.5

```PowerShell
Install-WindowsFeature Windows-Identity-Foundation
```

---

**FOOBAR8**

### # Insert the Visual Studio 2015 installation media

```PowerShell
$vmHost = 'STORM'
$vmName = 'DAZZLER'

$isoPath = '\\ICEMAN\Products\Microsoft\Visual Studio 2015\en_visual_studio_enterprise_2015_x86_x64_dvd_6850497.iso'

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $isoPath
```

---

```PowerShell
cls
```

### # Launch Visual Studio 2015 setup

```PowerShell
& X:\vs_enterprise.exe
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4D/CB8D2970754D88629E3E6D51F1E4BDCAB8A0FD4D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/93/FECD5CD3DB25CEF8B7E376A92F71B45AC6C4EC93.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/30/6AB2199E908EAA655850B6D365791212FCDD3130.png)

Select the following features:

- Windows and Web Development
  - **Microsoft Office Developer Tools**
  - **Microsoft Web Developer Tools**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CA/65B2F28CB988A0CF60367E1CCF3606394A8CDFCA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4B/7F1B8CBAB3901BD011BBE30EE4C900CEC7D40D4B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2B/FA482E8FD5C26A618DAE0445EC9BF7B7C5F2172B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/37/B88BC8416B3FF3FFACACF45FD5FB4BC306EE0437.png)

## # Install reference assemblies

```PowerShell
robocopy `
    '\\ICEMAN\Public\Reference Assemblies' `
    'C:\Program Files\Reference Assemblies' /E

& 'C:\Program Files\Reference Assemblies\Microsoft\SharePoint v4\AssemblyFoldersEx - x64.reg'
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6C/902A6F7E87FE80BE063AE9BCAB23370FFA39AC6C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C6/015FE6C9EB4A879F2DD482B9CC976A5C0718C9C6.png)

```PowerShell
& 'C:\Program Files\Reference Assemblies\Microsoft\SharePoint v5\AssemblyFoldersEx - x64.reg'
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/44/2CA7474E335103FFC798B5E4DC2557A18C302944.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F2/8549DDC36653E1D36BBE2C9DEAE28FD64EDE40F2.png)

```PowerShell
cls
```

## # Install MSBuild Community Tasks

```PowerShell
& "\\ICEMAN\Public\Download\MSBuild.Community.Tasks.v1.4.0.88.msi"
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4D/6B8A6E40EB4FF5A78BC3285E72578034D993A54D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/25/F4B41E98225C97F0D9AFEE853C3FB8243977BB25.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/55/5F1A49D61487A8F729B533398F4E47DA63708055.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/75/81C760FC93EAE1409CF58DF2D5B0BD96A5DFE575.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/46/B1B0EA42F79F7341CD17D5EA0A1B237C7F7CBC46.png)

```PowerShell
cls
```

## # Install Python (dependency for many node.js packages)

### # Install Python (using default options)

```PowerShell
& "\\ICEMAN\Products\Python\python-2.7.10.amd64.msi"
```

### # Add Python folders to PATH environment variable

```PowerShell
Set-ExecutionPolicy RemoteSigned -Force

$pythonPathFolders = 'C:\Python27\', 'C:\Python27\Scripts'

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-PathFolders.ps1 `
    -Folders $pythonPathFolders `
    -EnvironmentVariableTarget Machine
```

```PowerShell
cls
```

## # Install Git (required by npm to download packages from GitHub)

### # Install Git (using default options)

```PowerShell
& \\ICEMAN\Products\Git\Git-2.5.3-64-bit.exe
```

### # Add Git folder to PATH environment variable

```PowerShell
$gitPathFolder = 'C:\Program Files\Git\cmd'

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-PathFolders.ps1 `
    -Folders $gitPathFolder `
    -EnvironmentVariableTarget Machine
```

```PowerShell
cls
```

## # Install and configure Node.js

### # Install Node.js

```PowerShell
# & \\ICEMAN\Products\node.js\node-v0.12.5-x64.msi

& \\ICEMAN\Products\node.js\node-v4.1.1-x64.msi
```

> **Important**
>
> Restart PowerShell for change to PATH environment variable to take effect.

### # Change NPM file locations to avoid issues with redirected folders

```PowerShell
notepad "C:\Program Files\nodejs\node_modules\npm\npmrc"
```

In Notepad, change:

```Text
    prefix=${APPDATA}\npm
```

...to:

```Text
    ;prefix=${APPDATA}\npm
    prefix=${LOCALAPPDATA}\npm
    cache=${LOCALAPPDATA}\npm-cache
```

#### Reference

**npm on windows, install with -g flag should go into appdata/local rather than current appdata/roaming?**\
From <[https://github.com/npm/npm/issues/4564](https://github.com/npm/npm/issues/4564)>

**`npm install -g bower` goes into infinite loop on windows with %appdata% being a UNC path**\
From <[https://github.com/npm/npm/issues/8814](https://github.com/npm/npm/issues/8814)>

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

#### Reference

**How to use npm with node.exe?**\
http://stackoverflow.com/a/9366416

### # Configure NPM to use HTTP instead of HTTPS

```PowerShell
npm config --global set registry http://registry.npmjs.org/
```

#### Reference

**npm not working - "read ECONNRESET"**\
From <[http://stackoverflow.com/questions/18419144/npm-not-working-read-econnreset](http://stackoverflow.com/questions/18419144/npm-not-working-read-econnreset)>

```PowerShell
cls
```

## # Install global NPM packages

### # Install Grunt CLI

```PowerShell
npm install --global grunt-cli
```

### # Install Gulp

```PowerShell
npm install --global gulp
```

### # Install Bower

```PowerShell
npm install --global bower
```

## # Install rimraf

```PowerShell
npm install --global rimraf
```

```PowerShell
cls
```

## # Configure NPM for TFS Build service account

---

```Console
runas /USER:TECHTOOLBOX\s-tfs-build PowerShell.exe
```

### # Set NPM "global" locations to shared location for all users

```PowerShell
npm config --global set prefix "$env:ALLUSERSPROFILE\npm"

npm config --global set cache "$env:ALLUSERSPROFILE\npm-cache"
```

### # Set NPM "local" locations to local AppData folder

```PowerShell
npm config set prefix "$env:LOCALAPPDATA\npm"

npm config set cache "$env:LOCALAPPDATA\npm-cache"
```

### # Configure NPM to use HTTP instead of HTTPS

```PowerShell
npm config --global set registry http://registry.npmjs.org/
```

---

## # Set build controller on all build definitions

---

**WIN8-DEV1**

```PowerShell
[string] $TfsUrl = "http://cyclops:8080/tfs"
[string] $NewBuildController = "DAZZLER - Controller"

$ErrorActionPreference = "Stop"

Add-Type -Path "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\ReferenceAssemblies\v2.0\Microsoft.TeamFoundation.Common.dll"

Add-Type -Path "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\ReferenceAssemblies\v2.0\Microsoft.TeamFoundation.Client.dll"

Add-Type -Path "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\ReferenceAssemblies\v2.0\Microsoft.TeamFoundation.Build.Client.dll"

$tfsUri = New-Object System.Uri $TfsUrl
$tpc = New-Object Microsoft.TeamFoundation.Client.TfsTeamProjectCollection $tfsUri

$buildServerType = [Microsoft.TeamFoundation.Build.Client.IBuildServer]

$buildClient = $tpc.GetService($buildServerType)
$controller = $buildClient.GetBuildController($NewBuildController)

$versionControlType =
    [Microsoft.TeamFoundation.VersionControl.Client.VersionControlServer]

$versionControlServer = $tpc.GetService($versionControlType)

$teamProjects = $versionControlServer.GetAllTeamProjects($true)

$teamProjects | ForEach-Object {
    $teamProject = $_.Name

    Write-Verbose "Processing team project ($teamProject)..."

    $buildDefinitions = $buildClient.QueryBuildDefinitions($teamProject)
    $buildDefinitions | ForEach-Object {
        $buildDefinitionName = $_.Name

        Write-Verbose "Processing build definition ($buildDefinitionName)..."
        Write-Verbose "Build controller: $($_.BuildController.Name)"

        if ($_.BuildController.Uri -ne $controller.Uri) {
            Write-Host ("Setting build definition ($buildDefinitionName) to" `
                + " use new build controller ($NewBuildController)...")

            $_.BuildController = $controller
            $_.Save()
        }
        else {
            Write-Verbose ("Build definition ($buildDefinitionName) is already" `
                + " using the specified build controller ($NewBuildController).")
        }
    }
}
```

---

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

```Console
cls
```

## # Install SCOM agent

```PowerShell
$imagePath = '\\iceman\Products\Microsoft\System Center 2012 R2' `
    + '\en_system_center_2012_r2_operations_manager_x86_and_x64_dvd_2920299.iso'

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$msiPath = $imageDriveLetter + ':\agent\AMD64\MOMAgent.msi'

msiexec.exe /i $msiPath `
    MANAGEMENT_GROUP=HQ `
    MANAGEMENT_SERVER_DNS=JUBILEE `
    ACTIONS_USE_COMPUTER_ACCOUNT=1
```

## # Approve manual agent install in Operations Manager

## Configure DCOM permissions for TFS Build

### Issue

Log Name:      System\
Source:        Microsoft-Windows-DistributedCOM\
Date:          9/14/2015 11:27:39 AM\
Event ID:      10016\
Task Category: None\
Level:         Error\
Keywords:      Classic\
User:          TECHTOOLBOX\\s-tfs-build\
Computer:      DAZZLER.corp.technologytoolbox.com\
Description:\
The machine-default permission settings do not grant Local Activation permission for the COM Server application with CLSID\
{3EEF301F-B596-4C0B-BD92-013BEAFCE793}\
 and APPID\
{3EEF301F-B596-4C0B-BD92-013BEAFCE793}\
 to the user TECHTOOLBOX\\s-tfs-build SID (S-1-5-21-3914637029-2275272621-3670275343-10684) from address LocalHost (Using LRPC) running in the application container Unavailable SID (Unavailable). This security permission can be modified using the Component Services administrative tool.

### Resolution

Using the steps in **[KB 2000474](KB 2000474) Workaround 1**, add **Local Launch** and **Local Activate** permissions on **{3EEF301F-B596-4C0B-BD92-013BEAFCE793}** (Desktop Undo Manager) to **TECHTOOLBOX\\s-tfs-build**.

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\TFS\Scripts\Configure DCOM Permissions.ps1'
```

## Issue - "npm ERR! code ECONNRESET" when building Employee Portal

### Issue

```Console
"D:\Builds\14\Securitas EmployeePortal\CI - Main\src\Code\Web\node_modules\grunt-sass\node_modules\node-sass\vendor\win32-x64-46\binding.node" exists.
 testing binary.
Binary is fine; exiting.
npm ERR! Windows_NT 6.3.9600
npm ERR! argv "C:\\Program Files\\nodejs\\node.exe" "C:\\Program Files\\nodejs\\node_modules\\npm\\bin\\npm-cli.js" "install"
npm ERR! node v4.1.1
npm ERR! npm  v2.14.4
npm ERR! code ECONNRESET
npm ERR! errno ECONNRESET
...
```

### References

**npm ERR! Callback called more than once #10322**\
From <[https://github.com/npm/npm/issues/10322](https://github.com/npm/npm/issues/10322)>

**Seeing elevated network read ECONNRESET from AWS #12484**\
From <[https://github.com/npm/npm/issues/12484](https://github.com/npm/npm/issues/12484)>

**Seeing elevated network read ECONNRESET from AWS #10**\
From <[https://github.com/npm/registry/issues/10](https://github.com/npm/registry/issues/10)>

### Solution

```PowerShell
cls
```

#### # Upgrade Node.js

##### # Install new version of Node.js

```PowerShell
& \\ICEMAN\Products\node.js\node-v4.4.7-x64.msi
```

> **Important**
>
> Wait for the installation to complete.

```PowerShell
cls
```

##### # Configure NPM to use HTTPs instead of HTTP

```PowerShell
npm config --global set registry https://registry.npmjs.org/
```

##### # Clear NPM cache

```PowerShell
npm cache clear
```

## Upgrade to System Center Operations Manager 2016

### Uninstall SCOM 2012 R2 agent

```Console
msiexec /x `{786970C5-E6F6-4A41-B238-AE25D4B91EEA`}

Restart-Computer
```

### Install SCOM 2016 agent (using Operations Console)

## Issue - Incorrect IPv6 DNS server assigned by Comcast router

```Text
PS C:\Users\jjameson-admin> nslookup
Default Server:  cdns01.comcast.net
Address:  2001:558:feed::1
```

> **Note**
>
> Even after reconfiguring the **Primary DNS** and **Secondary DNS** settings on the Comcast router -- and subsequently restarting the VM -- the incorrect DNS server is assigned to the network adapter.

### Solution

```PowerShell
Set-DnsClientServerAddress `
    -InterfaceAlias Management `
    -ServerAddresses 2603:300b:802:8900::103, 2603:300b:802:8900::104

Restart-Computer
```

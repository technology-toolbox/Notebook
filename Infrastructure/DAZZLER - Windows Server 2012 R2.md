# DAZZLER (2015-09-09) - Windows Server 2012 R2 Standard

Wednesday, September 9, 2015
4:53 AM

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

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6A/64CCDFB28B91F862315258358F6AA7F3260A836A.png)

From log file:

[0504:0554][2015-09-09T14:53:01]i000: MUX:  ExecuteError: Package (WindowsIdentityExtensions_x64) failed: Error Message Id: 0 ErrorMessage: Installation of Microsoft Identity Extensions requires Windows Identity Foundation v1.0 to be installed

### # Install Windows Identity Foundation 3.5

```PowerShell
Install-WindowsFeature Windows-Identity-Foundation
```

### Modify Visual Studio 2015 to add Microsoft Office Developer Tools

1. **Control Panel > Programs > Programs and Features**
2. Double-click **Microsoft Visual Studio Enterprise 2015**.
3. Click **Modify**.

Ugh...Microsoft Office Developer Tools does not appear to be installed when you subsequently check the installed features of Visual Studio 2015 through Control Panel. (Punt)

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

**TODO:**

## Modify build definition to specify VisualStudioVersion

### Build failure

**Debug | Any CPU**\
 1 error(s), 0 warning(s)

- \$/foobar/Dev/Lab1/Source/TechnologyToolbox.Foobar.sln - 1 error(s), 0 warning(s), View Log File
  - C:\\Builds\\5\\foobar\\CI - Dev - Lab1\\Sources\\Source\\Web\\TechnologyToolbox.Foobar.Web.csproj (121): The imported project "C:\\Program Files (x86)\\MSBuild\\Microsoft\\VisualStudio\\v11.0\\SharePointTools\\Microsoft.VisualStudio.SharePoint.targets" was not found. Confirm that the path in the `<Import>` declaration is correct, and that the file exists on disk.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D5/D88B46693D7A711EEABBB4C519823FC254CC10D5.png)

### Build failure

**Default Configuration and Platform**\
1 error(s), 0 warning(s)

- \$/foobar/Main/Source/IncrementAssemblyVersion.proj - 1 error(s), 0 warning(s), View Log File
  - C:\\Builds\\5\\foobar\\Automated Build - Main\\Sources\\Source\\IncrementAssemblyVersion.proj (19): The command ""..\\IDE\\tf.exe" checkout AssemblyVersionInfo.txt AssemblyVersionInfo.cs" exited with code 3.

1. Edit **IncrementAssemblyVersion.proj** and change **\$(VS110COMNTOOLS)** to **\$(VS120COMNTOOLS)** on line 12.
2. Restart the computer to ensure the environment variable is set as expected (after installing Visual Studio).

## Resolve SCOM alerts due to TFS app pool timeout

### Alert Name

Application Pool worker process is unresponsive

### Alert Description

_A process serving application pool 'Microsoft Team Foundation Server Message Queue Application Pool' exceeded time limits during shut down. The process id was '396'._

### Investigation

```PowerShell
# Convert alert timestamp to UTC

(Get-Date "4/20/2014 11:53:06PM").ToUniversalTime()

Monday, April 21, 2014 5:53:06 AM
```

From IIS log file:

```Console
2014-04-21 05:49:16 192.168.10.14 POST /tfs/queue/DefaultCollection/Services/v4.0/MessageQueueService2.svc - 8080 TECHTOOLBOX\svc-build 192.168.10.18 Team+Foundation+(TFSBuildServiceHost.exe,+12.0.21005.1,+Other,+SKU:18) - 202 0 0 300031
```

300031 / 1000 / 60 = 5.0005

So, the request from DAZZLER is timing out after 5 minutes.

```C#
// Microsoft.TeamFoundation.Framework.Server.TeamFoundationMessageQueueService
private void LoadSettings(TeamFoundationRequestContext requestContext)
{
...
    try
    {
        RegistryEntryCollection registryEntryCollection = service.ReadEntriesFallThru(requestContext.Elevate(), "/Service/MessageQueue/Settings/...");

        timeSpan = registryEntryCollection["IdleTimeout"].GetValue<TimeSpan>(TimeSpan.FromMinutes(5.0));

...
```

### Resolution

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C4/F8FF9323E8A1A1455F4BA9DCBEFB6CFE6E4CF6C4.png)

Right-click **Microsoft Team Foundation Server Message Queue Application Pool** and then click **Advanced Settings...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0E/D16A01C0FA824D40AD813DFBBE27DC39BE2F610E.png)

In the **Advanced Settings** window, notice **Shutdown Time Limit (seconds)** is set to the default value of **90**.

Change **Shutdown Time Limit (seconds)** to **300** and then click **OK**.

## # Install reference assemblies for building SharePoint 2013 projects

### Build failure

**Debug | Any CPU**\
444 error(s), 5 warning(s)

- \$/Securitas ClientPortal/Dev/Lab2/Code/SecuritasClientPortal.sln - 444 error(s), 5 warning(s), View Log File
- DefaultRoleDefinitionPermissions.cs (1): The type or namespace name 'SharePoint' does not exist in the namespace 'Microsoft' (are you missing an assembly reference?)
- SharePoint\\SharePointPublishingHelper.cs (2328): The type or namespace name 'PublishingPage' could not be found (are you missing a using directive or an assembly reference?)
- SharePoint\\SharePointPublishingHelper.cs (2288): The type or namespace name 'PublishingPage' could not be found (are you missing a using directive or an assembly reference?)
- ...

```PowerShell
robocopy '\\iceman\Public\Reference Assemblies' 'C:\Program Files\Reference Assemblies' /E

& "C:\Program Files\Reference Assemblies\Microsoft\SharePoint v5\AssemblyFoldersEx - x64.reg"
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

**TODO:**

## Resolve SCOM alerts due to disk fragmentation

### Alert Name

Logical Disk Fragmentation Level is high

### Alert Description

The disk C: (C:) on computer DAZZLER.corp.technologytoolbox.com has high fragmentation level. File Percent Fragmentation value is 15%. Defragmentation recommended: true.

### Resolution

#### # Copy Toolbox content

```PowerShell
robocopy \\iceman\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E
```

#### # Create scheduled task to optimize drives

```PowerShell
[string] $xml = Get-Content `
  'C:\NotBackedUp\Public\Toolbox\Scheduled Tasks\Optimize Drives.xml'

Register-ScheduledTask -TaskName "Optimize Drives" -Xml $xml
```

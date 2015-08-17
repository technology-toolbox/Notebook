# DAZZLER - Windows Server 2012 R2 Standard

Sunday, January 19, 2014
10:39 AM

```Console
12345678901234567890123456789012345678901234567890123456789012345678901234567890

PowerShell
```

## # [BEAST] Create virtual machine

```PowerShell
$vmName = "DAZZLER"

New-VM `
    -Name $vmName `
    -Path C:\NotBackedUp\VMs `
    -MemoryStartupBytes 512MB `
    -SwitchName "Virtual LAN 2 - 192.168.10.x"

Set-VMMemory `
    -VMName $vmName `
    -DynamicMemoryEnabled $true `-MaximumBytes 2GB

Set-VM -VMName $vmName -ProcessorCount 2

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

## # Rename the server and join domain

```PowerShell
Rename-Computer -NewName DAZZLER -Restart
```

Wait for the VM to restart and then execute the following command to join the **TECHTOOLBOX **domain:

```PowerShell
Add-Computer -DomainName corp.technologytoolbox.com -Restart
```

## # Change drive letter for DVD-ROM

```PowerShell
# To change the drive letter for the DVD-ROM using PowerShell:

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

## # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name "LAN 1 - 192.168.10.x" `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping ICEMAN -f -l 8900
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

## # Install .NET Framework 3.5

```PowerShell
Install-WindowsFeature `
    NET-Framework-Core `
    -Source '\\ICEMAN\Products\Microsoft\Windows Server 2012 R2\Sources\SxS'
```

## Install Visual Studio 2010

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7F/1009F1F2A3D40D598DE48BFBC3E0F8BBB75DE87F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/39/35A7FB5C8EEF5BD0DC0C5B9CAF18BBB1BF6D1D39.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EA/0041AF9002242B47E6A3CF7725398ED210C653EA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/93/29D714C58735C688CD566C35D3B3173B87F23F93.png)

Select **Custom** and then click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7C/BC717F1AA6059D447AE4E9BE4F79607BE091F77C.png)

Clear the checkbox for **Microsoft SQL Server 2008 Express Service Pack 1 (x64)** and then click **Install**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/67/C4C093368987E03339654638743AA09F8930DA67.png)

## Install Visual Studio 2010 Service Pack 1

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E5/8CA4E18A021BDAB3BFC166F4088A00EDF75011E5.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/61/DCAEDF788CE03ECC90662FAC83FD3F55BCF00261.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1B/A2CC672C3AD3D422EDB28D3E422717A4002B301B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E1/9D76042D7AA95269E01C6BFB73FBD8624E9591E1.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F0/131D389EC11EF216C2EB88B4E4E836A4C3923DF0.png)

## Create share on ICEMAN for TFS builds

## Install Team Foundation Server 2013 with Update 4

Mount the TFS 2013 with Update 4 installation image and open **tfs_server.exe**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CE/1327877DDD2B2CA0AA8F839EB9AE315DC9D49ECE.png)

UAC, click **Yes**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/35/04D4550CC8BC98F3875ACC105362BF1E1DDEDF35.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1C/28585579BE3B2F70C330C83979C572272241E31C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AE/A27A9A034AAF4831727AB713046A3325A294AFAE.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/88/D7E2D952B94C330712574C4BA37F68B3F2641788.png)

Click **Browse**...

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B1/2C034774A536453F17FBF925766830B230F190B1.png)

Click **Servers...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2D/FBD0E0D13036C2C318F342DF42B88F93DA88C82D.png)

Click **Add...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/68/F6B3F2DF8E3531EF7CDB6ABFDC3773457512E568.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0D/0BEEB8C8446857557F573B8586A304D7AC75970D.png)

Click **Close**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/54/2211A91C05906F854782BF7D17E817A2509B2B54.png)

Click **Connect**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/99/7DB920E233ADA00DA560001A5F84BAB419C78399.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/38/5E6EF18B1F6D8885525D950E77E3FB2B03DA5A38.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FE/B585F44D2CF8C9B0485582FFAC3C5DB7487044FE.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CC/8A4F74A42143086A9C69ED8FE86577A76FEC3FCC.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/80/2D582BEDBE8C9544E49E0D10DD577B7ED572D880.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/86/70191EFA936586174CEB644FD00A6C7EDBB40D86.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/88/40091CCCF59C5FBC343E03C6EB90B7A412212088.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/30/4DBEAFCAEAC7DE48F13E525AD22385548A945530.png)

## # Install reference assemblies

### Build failure

**Debug | Any CPU**\
 130 error(s), 2 warning(s)

- \$/foobar/Dev/Lab1/Source/TechnologyToolbox.Foobar.sln - 130 error(s), 2 warning(s), View Log File
  -  DefaultRoleDefinitionPermissions.cs (1): The type or namespace name 'SharePoint' does not exist in the namespace 'Microsoft' (are you missing an assembly reference?)
  -  DefaultSiteGroupPermissions.cs (1): The type or namespace name 'SharePoint' does not exist in the namespace 'Microsoft' (are you missing an assembly reference?)
  -  Diagnostics\\DiagnosticsService.cs (3): The type or namespace name 'SharePoint' does not exist in the namespace 'Microsoft' (are you missing an assembly reference?)
  -  Diagnostics\\DiagnosticsService.cs (18): The type or namespace name 'SPDiagnosticsServiceBase' could not be found (are you missing a using directive or an assembly reference?)
  -  Diagnostics\\SPLogger.cs (3): The type or namespace name 'SharePoint' does not exist in the namespace 'Microsoft' (are you missing an assembly reference?)
  -  C:\\Windows\\Microsoft.NET\\Framework64\\v4.0.30319\\Microsoft.Common.targets (1605): Could not resolve this reference. Could not locate the assembly "Microsoft.SharePoint". Check to make sure the assembly exists on disk. If this reference is required by your code, you may get compilation errors.
  -  C:\\Windows\\Microsoft.NET\\Framework64\\v4.0.30319\\Microsoft.Common.targets (1605): Could not resolve this reference. Could not locate the assembly "Microsoft.SharePoint.Security". Check to make sure the assembly exists on disk. If this reference is required by your code, you may get compilation errors.

A large number of error or warning messages were logged, so only some of them appear above. To see all error and warning messages logged in this completed build, click View Log File.

```PowerShell
robocopy `
    '\\iceman\Public\Reference Assemblies' `
    'C:\Program Files\Reference Assemblies' /E

& 'C:\Program Files\Reference Assemblies\Microsoft\SharePoint v4\AssemblyFoldersEx - x64.reg'
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EB/1F1A4F8F0CEED610298D317AA578BFCE2D2FC7EB.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1D/200DE2DB31296592F13A3BAFCC365F04E7AB721D.png)

## Modify build definition to specify VisualStudioVersion

### Build failure

**Debug | Any CPU**\
 1 error(s), 0 warning(s)

- \$/foobar/Dev/Lab1/Source/TechnologyToolbox.Foobar.sln - 1 error(s), 0 warning(s), View Log File
  - C:\\Builds\\5\\foobar\\CI - Dev - Lab1\\Sources\\Source\\Web\\TechnologyToolbox.Foobar.Web.csproj (121): The imported project "C:\\Program Files (x86)\\MSBuild\\Microsoft\\VisualStudio\\v11.0\\SharePointTools\\Microsoft.VisualStudio.SharePoint.targets" was not found. Confirm that the path in the `<Import>` declaration is correct, and that the file exists on disk.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D5/D88B46693D7A711EEABBB4C519823FC254CC10D5.png)

## # [BEAST] Increase the size of VHD

```PowerShell
$vmName = "DAZZLER"

Stop-VM $vmName

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

Resize-VHD -Path $vhdPath -SizeBytes 45GB

Start-VM $vmName
```

## # Expand C: drive

```PowerShell
$size = (Get-PartitionSupportedSize -DiskNumber 0 -PartitionNumber 2)
Resize-Partition -DiskNumber 0 -PartitionNumber 2 -Size $size.SizeMax
```

## Install Visual Studio 2013 with Update 4

### Build failure

**Other Errors and Warnings**

- 2 error(s), 0 warning(s)
  - TF900547: The directory containing the assemblies for the Visual Studio Test Runner is not valid ''.
  - TF900547: The directory containing the assemblies for the Visual Studio Test Runner is not valid ''.

### Reference

In TFS 2012>>Build Definition, we can set VS 2010(MSTest) as Test runner.\
But in TFS 2013 Preview version>>Build Definition, it seems we can’t change the Test runner, and it set to VS 2013 Test Runner by default.

Pasted from <[http://social.msdn.microsoft.com/Forums/vstudio/en-US/fa5b1406-d8bb-4555-a4ab-4f9fd1690b8e/tf900547-the-directory-containing-the-assemblies-for-the-visual-studio-test-runner-is-not-valid?forum=tfsbuild](http://social.msdn.microsoft.com/Forums/vstudio/en-US/fa5b1406-d8bb-4555-a4ab-4f9fd1690b8e/tf900547-the-directory-containing-the-assemblies-for-the-visual-studio-test-runner-is-not-valid?forum=tfsbuild)>

Mount the Visual Studio 2013 installation image and open **vs_ultimate.exe**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2A/CBF47F07155C951308F9BE9191234C6A2EC4AB2A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C7/855E57C189851F88D70F5C397C1F362E66D6E9C7.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AB/3CC7ECE2DD5475F5B2D7B8653F3D428690E46DAB.png)

Ensure the default optional features are selected to install:

- **Blend for Visual Studio**
- **LightSwitch**
- **Microsoft Foundation Classes for C++**
- **Microsoft Office Developer Tools**
- **Microsoft SQL Server Data Tools**
- **Microsoft Web Developer Tools**
- **Silverlight Development Kit**

Click **INSTALL**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4F/7A00A0B01B8316C6B43F5F44CDDB12147111854F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5A/C60C85EF5AE731F27CB4C642C6DAC99A9B41CF5A.png)

```PowerShell
cls
```

## # Install MSBuild Community Tasks

```PowerShell
& "\\iceman\Public\Download\MSBuild.Community.Tasks.v1.4.0.42.msi"
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8C/74D0E9BE47C2CCE7FEBD063B5BC495958CC5208C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9D/EBBE6EA4A8596BA3E94342E8FEC94011E03A3E9D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/50/5B346604E05233AC260F36E8E7BABCEC26183E50.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9D/3FF5052E3C065A984BDB50169B8C88DD178BD19D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/90/A98FBB838C23E5D21B8E41DBC1900723C6D9AB90.png)

### Build failure

**Default Configuration and Platform**\
1 error(s), 0 warning(s)

- \$/foobar/Main/Source/IncrementAssemblyVersion.proj - 1 error(s), 0 warning(s), View Log File
  - C:\\Builds\\5\\foobar\\Automated Build - Main\\Sources\\Source\\IncrementAssemblyVersion.proj (19): The command ""..\\IDE\\tf.exe" checkout AssemblyVersionInfo.txt AssemblyVersionInfo.cs" exited with code 3.

1. Edit **IncrementAssemblyVersion.proj** and change **\$(VS110COMNTOOLS)** to **\$(VS120COMNTOOLS)** on line 12.
2. Restart the computer to ensure the environment variable is set as expected (after installing Visual Studio).

## # Increase the size of VHD

![(screenshot)](https://assets.technologytoolbox.com/screenshots/45/56C102833B54558B03F13DFAAE03C3E03288F245.png)

```PowerShell
$vmName = "DAZZLER"

Stop-VM $vmName

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

Resize-VHD -Path $vhdPath -SizeBytes 34GB

Start-VM $vmName
```

## # Expand C: drive

```PowerShell
$size = (Get-PartitionSupportedSize -DiskNumber 0 -PartitionNumber 2)
Resize-Partition -DiskNumber 0 -PartitionNumber 2 -Size $size.SizeMax
```

## Resolve SCOM alerts due to disk fragmentation

### Alert Name

Logical Disk Fragmentation Level is high

### Alert Description

The disk C: (C:) on computer DAZZLER.corp.technologytoolbox.com has high fragmentation level. File Percent Fragmentation value is 12%. Defragmentation recommended: true.

### Resolution

##### # Copy Toolbox content

```PowerShell
robocopy \\iceman\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E
```

##### # Create scheduled task to optimize drives

```PowerShell
[string] $xml = Get-Content `
  'C:\NotBackedUp\Public\Toolbox\Scheduled Tasks\Optimize Drives.xml'

Register-ScheduledTask -TaskName "Optimize Drives" -Xml $xml
```

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

## # Increase the size of "DAZZLER" VHD

```PowerShell
$vmName = "DAZZLER"

Stop-VM $vmName

Resize-VHD `
    ("C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
        + $vmName + ".vhdx") `
    -SizeBytes 36GB

Start-VM $vmName
```

## # Expand C: drive

```PowerShell
$size = (Get-PartitionSupportedSize -DiskNumber 0 -PartitionNumber 1)
Resize-Partition -DiskNumber 0 -PartitionNumber 1 -Size $size.SizeMax
```

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

## Install Visual Studio 2013 Update 4

### Build failure

**Debug | Any CPU**\
5 error(s), 0 warning(s)

- \$/Securitas ClientPortal/Dev/Lab2/Code/SecuritasClientPortal.sln - 5 error(s), 0 warning(s), View Log File
- C:\\Builds\\6\\Securitas ClientPortal\\CI - Lab2\\Sources\\Code\\Portal\\Web\\PortalWeb\\Securitas.Portal.Web.csproj (1306): The imported project "C:\\Program Files (x86)\\MSBuild\\Microsoft\\VisualStudio\\v11.0\\SharePointTools\\Microsoft.VisualStudio.SharePoint.targets" was not found. Confirm that the path in the `<Import>` declaration is correct, and that the file exists on disk.
- C:\\Builds\\6\\Securitas ClientPortal\\CI - Lab2\\Sources\\Code\\Portal\\Workflows\\Securitas.Portal.Workflows.csproj (231): The imported project "C:\\Program Files (x86)\\MSBuild\\Microsoft\\VisualStudio\\v11.0\\SharePointTools\\Microsoft.VisualStudio.SharePoint.targets" was not found. Confirm that the path in the `<Import>` declaration is correct, and that the file exists on disk.
- ...

Ugh...VS 2013 Update 4 said it needed 5 GB of free space -- and DAZZLER had over 6 GB -- but it still ran out of space!

## # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

## # Configure firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

---

**FOOBAR8**

```PowerShell
$computer = 'DAZZLER'

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

Invoke-Command -ComputerName $computer -ScriptBlock $scriptBlock
```

---

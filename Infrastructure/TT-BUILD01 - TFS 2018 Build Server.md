# TT-BUILD01 - TFS 2018 Build Server

Wednesday, April 4, 2018
6:26 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy Team Foundation Server 2018

### Deploy and configure the server infrastructure

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "TT-BUILD01"
$vmPath = "E:\NotBackedUp\VMs\$vmName"
$vhdPath = "$vmPath\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 2GB `
    -SwitchName "Embedded Team Switch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 2

Start-VM -ComputerName $vmHost -Name $vmName
```

---

#### Install custom Windows Server 2016 image

- On the **Task Sequence** step, select **Windows Server 2016** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **TT-BUILD01**.
  - Click **Next**.
- On the **Applications** step, do not select any applications, and click **Next**.

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

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Set first boot device to hard drive

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "TT-BUILD01"

$vmHardDiskDrive = Get-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName |
    where { $_.ControllerType -eq "SCSI" `
        -and $_.ControllerNumber -eq 0 `
        -and $_.ControllerLocation -eq 0 }

Set-VMFirmware `
    -ComputerName $vmHost `
    -VMName $vmName `
    -FirstBootDevice $vmHardDiskDrive
```

#### # Move computer to different OU

```PowerShell
$targetPath = "OU=Team Foundation Servers,OU=Servers" `
    + ",OU=Resources,OU=IT" `
    + ",DC=corp,DC=technologytoolbox,DC=com"

Get-ADComputer $vmName | Move-ADObject -TargetPath $targetPath
```

#### # Configure Windows Update

##### # Add machine to security group for Windows Update schedule

```PowerShell
Add-ADGroupMember -Identity "Windows Update - Slot 1" -Members ($vmName + '$')
```

---

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

robocopy $source $destination /E /XD "Microsoft SDKs"
```

### # Set MaxPatchCacheSize to 0 (recommended)

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

### # Enable performance counters for Server Manager

```PowerShell
$taskName = "\Microsoft\Windows\PLA\Server Manager Performance Monitor"

Enable-ScheduledTask -TaskName $taskName

logman start "Server Manager Performance Monitor"
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

#### Configure static IP address

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

##### # Configure static IP address using VMM

```PowerShell
$vmName = "TT-BUILD01"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Management VM Network"
$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"
$ipPool = Get-SCStaticIPAddressPool -Name "Management Address Pool"

Stop-SCVirtualMachine $vmName

$macAddress = Grant-SCMACAddress `
    -MACAddressPool $macAddressPool `
    -Description $vmName `
    -VirtualNetworkAdapter $networkAdapter

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -MACAddressType Static `
    -MACAddress $macAddress

$ipAddress = Grant-SCIPAddress `
    -GrantToObjectType VirtualNetworkAdapter `
    -GrantToObjectID $networkAdapter.ID `
    -StaticIPAddressPool $ipPool `
    -Description $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -IPv4AddressType Static `
    -IPv4Addresses $IPAddress.Address

Start-SCVirtualMachine $vmName
```

---

### Configure storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 32 GB       | 4K                   | OSDisk       |
| 1    | D:           | 5 GB        | 4K                   | Data01       |

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Configure storage for the SQL Server

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "TT-BUILD01"
$vmPath = "E:\NotBackedUp\VMs\$vmName"
```

##### # Add "Data01" VHD

```PowerShell
$vhdPath = $vmPath + "\Virtual Hard Disks\$vmName" + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 5GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path $vhdPath `
    -ControllerType SCSI
```

---

##### # Format Data01 drive

```PowerShell
Get-Disk 1 |
  Initialize-Disk -PartitionStyle GPT -PassThru |
  New-Partition -DriveLetter D -UseMaximumSize |
  Format-Volume `
    -FileSystem NTFS `
    -NewFileSystemLabel "Data01" `
    -Confirm:$false
```

### Add virtual machine to Hyper-V protection group in DPM

## Set up TFS Build server

```PowerShell
cls
```

### # Add TFS setup account to local Administrators group

```PowerShell
$domain = "TECHTOOLBOX"
$username = "setup-tfs"

([ADSI]"WinNT://./Administrators,group").Add(
    "WinNT://$domain/$username,user")
```

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Enable setup account for TFS

```PowerShell
Enable-ADAccount -Identity setup-tfs
```

---

### Login as TECHTOOLBOX\\setup-tfs

```PowerShell
cls
```

### # Install Visual Studio 2017

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
> If prompted, restart the computer to complete the installation.

```PowerShell
cls
```

### # Install other dependencies for building solutions

#### # Install reference assemblies

```PowerShell
net use \\TT-FS01\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$source = "\\TT-FS01\Builds\Reference Assemblies"
$destination = "C:\Program Files\Reference Assemblies"

robocopy $source $destination /E

& "$destination\Microsoft\SharePoint v4\AssemblyFoldersEx - x64.reg"
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6C/902A6F7E87FE80BE063AE9BCAB23370FFA39AC6C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C6/015FE6C9EB4A879F2DD482B9CC976A5C0718C9C6.png)

```PowerShell
& "$destination\Microsoft\SharePoint v5\AssemblyFoldersEx - x64.reg"
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/44/2CA7474E335103FFC798B5E4DC2557A18C302944.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F2/8549DDC36653E1D36BBE2C9DEAE28FD64EDE40F2.png)

```PowerShell
cls
```

#### # Install and configure Python

##### # Install Python

```PowerShell
$installerPath = "\\TT-FS01\Products\Python\python-2.7.14.amd64.msi"

Start-Process `
    -FilePath $installerPath `
    -Wait
```

```PowerShell
cls
```

##### # Add Python folders to PATH environment variable

```PowerShell
Set-ExecutionPolicy RemoteSigned -Scope Process -Force

$pythonPathFolders = 'C:\Python27\', 'C:\Python27\Scripts'

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-PathFolders.ps1 `
    -Folders $pythonPathFolders `
    -EnvironmentVariableTarget Machine
```

#### # Install and configure Git

##### # Install Git

```PowerShell
& \\TT-FS01\Products\Git\Git-2.16.1.3-64-bit.exe
```

> **Note**
>
> 1. On the **Choosing the default editor used by Git** step:
>    1. In the dropdown list, select **Use the Nano editor by default**.
>    2. Click **Next**.
> 2. On the **Choosing HTTPS transport backend** step:
>    1. Select **Use the native Windows Secure Channel library**.
>    2. Click **Next**.

##### Configure Git to use https:// URLs (instead of git:// URLS)

(skipped)

```PowerShell
cls
```

#### # Install and configure Node.js

##### # Install Node.js

```PowerShell
$installerPath = "\\TT-FS01\Products\node.js\node-v8.9.1-x64.msi"

Start-Process `
    -FilePath $installerPath `
    -Wait
```

> **Important**
>
> Restart PowerShell for change to PATH environment variable to take effect.

##### # Change NPM file locations to avoid issues with redirected folders

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

##### # Change NPM "global" locations to shared location for all users

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

```PowerShell
cls
```

#### # Install global NPM packages

##### # Install Angular CLI

```PowerShell
npm install --global --no-optional @angular/cli@1.4.9
```

```PowerShell
cls
```

##### # Install rimraf

```PowerShell
npm install --global rimraf@2.6.2
```

```PowerShell
cls
```

#### # Install TypeScript update for Visual Studio 2017

```PowerShell
$setupFile = ("\\TT-FS01\Products\Microsoft\Visual Studio 2017" `
     + "\TypeScript 2.6.2 for Visual Studio 2017\TypeScript_SDK.exe")

Start-Process -FilePath $setupFile -Wait
```

```PowerShell
cls
```

### # Configure agent pool to automatically provision queues in team projects

```PowerShell
$url = "https://tfs.technologytoolbox.com/DefaultCollection/_admin/_AgentPool"

Start-Process -FilePath $url -Wait
```

```PowerShell
cls
```

### # Configure permissions for build service account

```PowerShell
$url = "https://tfs.technologytoolbox.com/DefaultCollection/_admin/_AgentPool"

Start-Process -FilePath $url -Wait
```

```PowerShell
cls
```

### # Download and configure build agent

#### # Download build agent

```PowerShell
$source = ("\\TT-FS01\Products\Microsoft\Team Foundation Server 2018" `
    + "\Build\vsts-agent-win7-x64-2.122.2.zip")

$destination = "C:\NotBackedUp\Temp"

If ((Test-Path $destination) -eq $false)
{
    New-Item -ItemType Directory -Path $destination
}

Copy-Item $source $destination
```

#### # Install and configure first build agent

```PowerShell
$buildAgentPath = "D:\Build-Agent-1"

mkdir $buildAgentPath

Add-Type -AssemblyName System.IO.Compression.FileSystem

[System.IO.Compression.ZipFile]::ExtractToDirectory(
     "C:\NotBackedUp\Temp\vsts-agent-win7-x64-2.122.2.zip",
     $buildAgentPath)

cd $buildAgentPath

.\config.cmd
```

```PowerShell
cls
```

## # Configure builds for team projects

### # Create build queues for existing team projects

```PowerShell
$tfsUrl = "https://tfs.technologytoolbox.com"
$collectionName = "DefaultCollection"
$collectionUrl = "$tfsUrl/$collectionName"

# Get the list of team projects
$response = Invoke-RestMethod `
    -Uri "$collectionUrl/_apis/projects" `
    -UseDefaultCredentials

$json = $response.value

$projects = $json | select -ExpandProperty name

# Ensure a build queue exists in each team project
$projects |
    foreach {
        $projectName = $_
        $projectUrl = "$collectionUrl/$projectName"
        $apiUrl = ("$projectUrl/_apis/distributedtask/queues" `
            + "?api-version=3.0-preview.1")

        $response = Invoke-RestMethod `
            -UseDefaultCredentials `
            -Uri $apiUrl

        # Only create a queue if one does not exist
        If ($response.count -eq 0)
        {
            Write-Host "Creating build queue in project ($projectName)..."

            $postRequest = "{ " `
                + "name: 'default'" `
                + ", pool: { " `
                        + "id: 1" `
                    + " }" `
                + " }"

            Invoke-RestMethod `
                -Uri $apiUrl `
                -Body $postRequest `
                -ContentType "application/json" `
                -Method Post `
                -UseDefaultCredentials |
                Out-Null
        }
    }
```

## Install updates

### Install updates using Windows Update

### Install Visual Studio 2017 update version 15.6.4

## Complete setup

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Disable setup account for TFS

```PowerShell
Disable-ADAccount -Identity setup-tfs
```

---

```PowerShell
cls
```

### # Install TypeScript 2.7.2 for Visual Studio 2017

##### # Copy installer from internal file server

```PowerShell
$installer = "TypeScript_SDK.exe"

$source = ("\\TT-FS01\Products\Microsoft\Visual Studio 2017" `
     + "\TypeScript 2.7.2 for Visual Studio 2017")

$destination = 'C:\NotBackedUp\Temp'

robocopy $source $destination $installer
```

##### # Install new version of TypeScript for Visual Studio 2017

```PowerShell
Start-Process `
    -FilePath C:\NotBackedUp\Temp\TypeScript_SDK.exe `
    -Wait
```

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Move VM to new Production VM network

```PowerShell
$vmName = "TT-BUILD01"
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

**TODO:**

---

**FOOBAR11**

```PowerShell
cls
```

## # Make virtual machine highly available

```PowerShell
$vm = Get-SCVirtualMachine -Name TT-BUILD01
$vmHost = $vm.VMHost

Move-SCVirtualMachine `
    -VM $vm `
    -VMHost $vmHost `
    -HighlyAvailable $true `
    -Path "C:\ClusterStorage\iscsi02-Silver-02" `
    -UseDiffDiskOptimization
```

---

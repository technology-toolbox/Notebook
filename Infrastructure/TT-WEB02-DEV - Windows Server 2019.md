# TT-WEB02-DEV - Windows Server 2019

Wednesday, February 26, 2020\
7:24 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure infrastructure

---

**TT-ADMIN03** - Run as administrator

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "TT-WEB02-DEV"
$vmPath = "E:\NotBackedUp\VMs\$vmName"
$vhdPath = "$vmPath\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 1.75GB `
    -SwitchName "Embedded Team Switch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -CheckpointType Standard

Start-Sleep -Seconds 10

$vmNetwork = Get-SCVMNetwork -Name "Management VM Network"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork

Start-SCVirtualMachine -VM $vmName
```

---

### Install custom Windows Server 2019 image

- On the **Task Sequence** step, select **Windows Server 2019** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **TT-WEB02-DEV**.
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

**TT-ADMIN03** - Run as administrator

```PowerShell
cls

$vmName = "TT-WEB02-DEV"
$vmHost = "TT-HV05C"
```

### # Set first boot device to hard drive

```PowerShell

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

## # Move virtual machine to Production VM network

```PowerShell
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Production VM Network"
$ipAddressPool = Get-SCStaticIPAddressPool -Name "Production-15 Address Pool"

Stop-SCVirtualMachine $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -MacAddressType Static `
    -IPv4AddressPools $ipAddressPool `
    -IPv4AddressType Static

Start-SCVirtualMachine $vmName
```

---

### Login as .\\foo

```PowerShell
cls
```

### # Configure network settings

```PowerShell
$interfaceAlias = "Production"
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
| 0    | C:           | 32 GB       | 4K                   | OSDisk       |
| 1    | D:           | 10 GB       | 4K                   | Data01       |

---

**TT-ADMIN03** - Run as administrator

```PowerShell
cls
```

#### # Configure storage for web server

##### # Add "Data01" VHD

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "TT-WEB02-DEV"
$vmPath = "E:\NotBackedUp\VMs\$vmName"
$vhdPath = $vmPath + "\Virtual Hard Disks\$vmName" + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 10GB
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

---

**TT-ADMIN03** - Run as domain administrator

```PowerShell
cls
```

#### # Move computer to different organizational unit

```PowerShell
$computerName = "TT-WEB02-DEV"
$targetPath = "OU=Web Servers,OU=Servers" `
    + ",OU=Resources,OU=Development" `
    + ",DC=corp,DC=technologytoolbox,DC=com"

Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath
```

### # Configure Windows Update

#### # Add computer to security group for Windows Update schedule

```PowerShell
Add-ADGroupMember `
    -Identity "Windows Update - Slot 17" `
    -Members "$computerName`$"
```

---

#### Login as .\\foo

#### # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

> **Note**
>
> PowerShell remoting must be enabled for remote Windows Update using PoshPAIG ([https://github.com/proxb/PoshPAIG](https://github.com/proxb/PoshPAIG)).

```PowerShell
cls
```

### # Enable performance counters for Server Manager

```PowerShell
$taskName = "\Microsoft\Windows\PLA\Server Manager Performance Monitor"

Enable-ScheduledTask -TaskName $taskName

logman start "Server Manager Performance Monitor"
```

---

**TT-ADMIN03** - Run as administrator

```PowerShell
cls
```

### # Make virtual machine highly available

#### # Migrate VM to shared storage

```PowerShell
$vmName = "TT-WEB02-DEV"

$vm = Get-SCVirtualMachine -Name $vmName
$vmHost = $vm.VMHost

Move-SCVirtualMachine `
    -VM $vm `
    -VMHost $vmHost `
    -HighlyAvailable $true `
    -Path "C:\ClusterStorage\iscsi02-Silver-03" `
    -UseDiffDiskOptimization
```

#### # Allow migration to host with different processor version

```PowerShell
Stop-SCVirtualMachine -VM $vmName

Set-SCVirtualMachine -VM $vmName -CPULimitForMigration $true

Start-SCVirtualMachine -VM $vmName
```

---

### Configure backup

#### Add virtual machine to Hyper-V protection group in DPM

---

**TT-ADMIN03** - Run as administrator

```PowerShell
cls
```

### # Checkpoint VM

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "TT-WEB02-DEV"
$checkpointName = "Baseline"

Stop-VM -ComputerName $vmHost -Name $vmName

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName $checkpointName

Start-VM -ComputerName $vmHost -Name $vmName
```

---

```PowerShell
cls
```

## # Install and configure IIS

### # Enable role - Web Server (IIS)

```PowerShell
Enable-WindowsOptionalFeature `
    -Online `
    -FeatureName `
        IIS-CommonHttpFeatures,
        IIS-DefaultDocument,
        IIS-DirectoryBrowsing,
        IIS-HealthAndDiagnostics,
        IIS-HttpCompressionStatic,
        IIS-HttpErrors,
        IIS-HttpLogging,
        IIS-ManagementConsole,
        IIS-Performance,
        IIS-RequestFiltering,
        IIS-Security,
        IIS-StaticContent,
        IIS-WebServer,
        IIS-WebServerManagementTools,
        IIS-WebServerRole
```

### # Add features for ASP.NET

```PowerShell
Enable-WindowsOptionalFeature `
    -Online `
    -FeatureName `
        IIS-ApplicationDevelopment,
        IIS-ASPNET45,
        IIS-ISAPIExtensions,
        IIS-ISAPIFilter,
        IIS-NetFxExtensibility45,
        NetFx4Extended-ASPNET45
```

```PowerShell
cls
```

## # Install Web Platform Installer

```PowerShell
$installerPath = "\\TT-FS01\Products\Microsoft\Web Platform Installer 5.0" `
    + "\WebPlatformInstaller_amd64_en-US.msi"

Start-Process `
    -FilePath msiexec.exe `
    -ArgumentList "/i `"$installerPath`"" `
    -Wait
```

```PowerShell
cls
```

## # Install Web Deploy 3.6

```PowerShell
$webpiPath = Join-Path "$env:ProgramFiles" `
    "Microsoft\Web Platform Installer\WebpiCmd-x64.exe"

Start-Process `
    -FilePath $webpiPath `
    -ArgumentList "/Install /Products:`"WDeploy36NoSmo`" /AcceptEula" `
    -Wait
```

```PowerShell
cls
```

## # Install and configure Technology Toolbox website

```PowerShell
$hostHeader = "www-dev.technologytoolbox.com"

Import-Module WebAdministration

$appPoolName = $hostHeader

New-WebAppPool -Name $appPoolName

$appPool = Get-Item IIS:\AppPools\$appPoolName

$appPool.processModel.identityType = "NetworkService"
$appPool | Set-Item

$physicalPath = "D:\home\$hostHeader\wwwroot"

New-Item -ItemType Directory -Path $physicalPath

$site = New-WebSite `
    -name $hostHeader `
    -PhysicalPath $physicalPath `
    -HostHeader $hostHeader `
    -ApplicationPool $appPoolName

New-Item -ItemType Directory -Path "$physicalPath\blog"

$vdir = New-WebVirtualDirectory `
    -Site $hostHeader `
    -Name blog `
    -PhysicalPath "$physicalPath\blog"
```

```PowerShell
cls
```

### # Configure SSL

#### # Install certificate for secure communication

##### # Copy certificate

```PowerShell
$certFile = "www-dev.technologytoolbox.com.pfx"

$sourcePath = "\\TT-FS01\Public\Certificates\Internal"

$destPath = "C:\NotBackedUp\Temp"

New-Item -ItemType Directory -Path $destPath

Copy-Item "$sourcePath\$certFile" $destPath
```

##### # Install certificate

```PowerShell
$certPassword = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted for the secure string, type the password for the exported certificate.

```PowerShell
$certFilePath = "C:\NotBackedUp\Temp\$certFile"

Import-PfxCertificate `
    -FilePath $certFilePath `
    -CertStoreLocation Cert:\LocalMachine\My `
    -Password $certPassword

If ($? -eq $true)
{
    Remove-Item $certFilePath -Verbose
}
```

#### # Add HTTPS binding to IIS website

```PowerShell
$cert = Get-ChildItem -Path Cert:\LocalMachine\My |
    Where { $_.Subject -like "CN=`www-dev.technologytoolbox.com,*" }

New-WebBinding `
    -Name $hostHeader `
    -Protocol https `
    -Port 443 `
    -HostHeader $hostHeader `
    -SslFlags 0

$cert |
    New-Item `
        -Path ("IIS:\SslBindings\0.0.0.0!443!" + $hostHeader)
```

```PowerShell
cls
```

### # Copy website installation files

```PowerShell
robocopy \\TT-FS01\Builds\Caelum\_latest C:\NotBackedUp\Temp\Caelum\_latest /E /MIR /NP

robocopy \\TT-FS01\Builds\Subtext\_latest C:\NotBackedUp\Temp\Subtext\_latest /E /MIR /NP
```

### # Install Subtext

#### # Modify parameters for Subtext deployment

```PowerShell
Push-Location C:\NotBackedUp\Temp\Subtext\_latest

Notepad Subtext.Web.SetParameters.xml
```

> **Note**
>
> Update the `<setParameter>` element in the parameters XML file as specified in the following table:
>
> | Name                     | Value                              |
> | ------------------------ | ---------------------------------- |
> | IIS Web Application Name | www-dev.technologytoolbox.com/blog |

```PowerShell
cls
```

#### # Test web deployment for Subtext virtual directory

```PowerShell
.\Subtext.Web.deploy.cmd /T
```

> **Note**
>
> Review the actions that will be performed by Web Deploy.

```PowerShell
cls
```

#### # Perform web deployment for Subtext virtual directory

```PowerShell
.\Subtext.Web.deploy.cmd /Y

Pop-Location
```

```PowerShell
cls
```

### # Install Caelum

#### # Modify parameters for Caelum deployment

```PowerShell
Push-Location C:\NotBackedUp\Temp\Caelum\_latest

Notepad Website.SetParameters.xml
```

> **Note**
>
> Update the `<setParameter>` elements in the parameters XML file as specified in the following table:
>
> | Name | Value |
> | --- | --- |
> | IIS Web Application Name | www-dev.technologytoolbox.com |
> | SMTP Host | smtp-test.technologytoolbox.com |
> | SMTP Port | 587 |
> | SMTP User Name |  |
> | SMTP Password |  |
> | CaelumEntities-Web.config Connection String | ...data source=TT-SQL03;... |
> | CaelumData-Web.config Connection String | Server=TT-SQL03;... |

```PowerShell
cls
```

#### # Test web deployment for Caelum website

```PowerShell
.\Website.deploy.cmd /T `"-skip:objectName=dirPath,absolutePath=blog,skipAction=Delete -skip:objectName=filePath,absolutePath=blog\\*,skipAction=Delete`"
```

> **Note**
>
> Review the actions that will be performed by Web Deploy.

```PowerShell
cls
```

#### # Perform web deployment for Caelum website

```PowerShell
.\Website.deploy.cmd /Y `"-skip:objectName=dirPath,absolutePath=blog,skipAction=Delete -skip:objectName=filePath,absolutePath=blog\\*,skipAction=Delete`"

Pop-Location
```

```PowerShell
cls
```

### # Remove website installation files

```PowerShell
Remove-Item C:\NotBackedUp\Temp\Caelum -Recurse

Remove-Item C:\NotBackedUp\Temp\Subtext -Recurse
```

---

**TT-ADMIN03** - Run as administrator

```PowerShell
cls
```

## # Delete VM checkpoint - "Baseline"

```PowerShell
$vmHost = 'TT-HV05C'
$vmName = 'TT-WEB02-DEV'

Remove-VMSnapshot `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Name 'Baseline'

# Wait a few seconds for merge to start...
Start-Sleep -Seconds 5

while (Get-VM -ComputerName $vmHost -VMName $vmName |
    Where Status -eq "Merging disks") {
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 5
}

Write-Host
Write-Host "VM checkpoint deleted"
```

---

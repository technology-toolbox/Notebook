# TT-W8-TEST-02 - Windows 8.1 Enterprise (x64)

Monday, November 23, 2020\
2:37 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure workstation

---

**TT-ADMIN04** - Run as administrator

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05E"
$vmName = "TT-W8-TEST-02"
$vmPath = "E:\NotBackedUp\VMs\$vmName"
$vhdPath = "$vmPath\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 40GB `
    -MemoryStartupBytes 2GB `
    -SwitchName "Embedded Team Switch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 2 `
    -DynamicMemory `
    -MemoryMinimumBytes 256MB `
    -MemoryMaximumBytes 4GB

Start-Sleep -Seconds 10

$vmNetwork = Get-SCVMNetwork -Name "Management VM Network"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork

Start-SCVirtualMachine $vmName
```

---

### Install custom Windows 8.1 image

- On the **Task Sequence** step, select **Windows 8.1 Enterprise (x64)** and click
  **Next**.
- On the **Computer Details** step, in the **Computer name** box, type
  **TT-W8-TEST-02** and click **Next**.
- On the **Applications** step:
  - Select the following items:
    - Adobe
      - **Adobe Reader 8.3.1**
    - Google
      - **Chrome (64-bit)**
    - Mozilla
      - **Firefox (64-bit)**
      - **Thunderbird (64-bit)**
  - Click **Next**.

### # Rename local Administrator account and set password

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

$password = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted, type the password to use for the local Administrator account.

```PowerShell
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

$adminUser = [ADSI] 'WinNT://./Administrator,User'
$adminUser.Rename('foo')
$adminUser.SetPassword($plainPassword)

logoff
```

---

**TT-ADMIN04** - Run as administrator

```PowerShell
cls
```

### # Set first boot device to hard drive

```PowerShell
$vmHost = "TT-HV05E"
$vmName = "TT-W8-TEST-02"

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

---

### Configure network settings

#### Login as .\\foo

#### # Configure network adapter

```PowerShell
$interfaceAlias = "Management"
```

##### # Rename network connection

```PowerShell
Get-NetAdapter -Physical | select InterfaceDescription

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName $interfaceAlias
```

##### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Start-Sleep -Seconds 5

ping TT-DC10 -f -l 8900
```

```PowerShell
cls
```

##### # Disable NetBIOS over TCP/IP

```PowerShell
Get-NetAdapter |
    foreach {
        $interfaceAlias = $_.Name

        Write-Host ("Disabling NetBIOS over TCP/IP on interface" `
            + " ($interfaceAlias)...")

        $adapter = Get-WmiObject -Class "Win32_NetworkAdapter" `
            -Filter "NetConnectionId = '$interfaceAlias'"

        $adapterConfig = `
            Get-WmiObject -Class "Win32_NetworkAdapterConfiguration" `
                -Filter "Index= '$($adapter.DeviceID)'"

        # Disable NetBIOS over TCP/IP
        $adapterConfig.SetTcpipNetbios(2)
    }
```

### Configure storage

| Disk | Drive Letter | Volume Size | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------------------- | ------------ |
| 0    | C:           | 40 GB       | 4K                   | OSDisk       |

---

**TT-ADMIN04** - Run as domain administrator

```PowerShell
cls
```

#### # Move computer to different organizational unit

```PowerShell
$computerName = "TT-W8-TEST-02"

$targetPath = "OU=Workstations,OU=Resources,OU=Quality Assurance" `
    + ",DC=corp,DC=technologytoolbox,DC=com"

Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath
```

### # Configure Windows Update

#### # Add computer to security group for Windows Update schedule

```PowerShell
Add-ADGroupMember `
  -Identity "Windows Update - Slot 19" `
  -Members "$computerName`$"
```

---

```PowerShell
cls
```

#### # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

> **Note**
>
> PowerShell remoting must be enabled for remote Windows Update using PoshPAIG
> ([https://github.com/proxb/PoshPAIG](https://github.com/proxb/PoshPAIG)).

```PowerShell
cls
```

### # Allow domain users to logon remotely

```PowerShell
$domain = "TECHTOOLBOX"
$groupName = "Domain Users"

([ADSI]"WinNT://./Remote Desktop Users,group").Add(
    "WinNT://$domain/$groupName,group")
```

### Install updates using Windows Update

> **Note**
>
> Repeat until there are no updates available for the computer.

```PowerShell
cls
```

### # Enter product key and activate Windows

```PowerShell
slmgr /ipk {product key}
```

> **Note**
>
> When notified that the product key was set successfully, click **OK**.

```Console
slmgr /ato
```

### Activate Microsoft Office

1. Start Word 2013
2. Enter product key

```PowerShell
cls
```

## # Snapshot VM

### # Delete C:\\Windows\\SoftwareDistribution folder

```PowerShell
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse

Start-Service wuauserv
```

```PowerShell
cls
```

### # Shutdown VM

```PowerShell
Stop-Computer
```

### Snapshot VM - "Baseline"

---

**TT-ADMIN04** - Run as administrator

```PowerShell
cls
```

```PowerShell
$vmHost = "TT-HV05E"
$vmName = "TT-W8-TEST-02"
```

#### # Specify configuration in VM notes

```PowerShell
$notes = Get-VM -ComputerName $vmHost -VMName $vmName |
    select -ExpandProperty Notes

$newNotes = `
"Windows 8.1 Enterprise (x64)
Microsoft Office Professional Plus 2013 (x86)
Adobe Reader 8.3.1
Google Chrome (64-bit)
Mozilla Firefox (64-bit)
Mozilla Thunderbird (64-bit)" `
    + [System.Environment]::NewLine `
    + [System.Environment]::NewLine `
    + $notes

Set-VM `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Notes $newNotes
```

#### # Snapshot VM - "Baseline"

```PowerShell
$snapshotName = "Baseline"

Checkpoint-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -SnapshotName $snapshotName
```

---

### Configure backup

#### Add virtual machine to Hyper-V protection group in DPM

**TODO:**

## Update Hyper-V Integration Services

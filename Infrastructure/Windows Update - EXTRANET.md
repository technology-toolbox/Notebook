﻿# Windows Update - EXTRANET

Saturday, January 11, 2014
7:56 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Patch EXT-DC08 (before patching other machines)

## Patch remaining EXTRANET machines

### Prepare development and test VMs for patching

---

**FOOBAR16**

```PowerShell
cls
$activity = "Prepare development and test VMs for patching"
```

#### # Define list of development and test VMs

```PowerShell
$virtualMachinesWithSnapshots = @(
    [PSCustomObject] @{ VMName = 'EXT-ADFS01A'; VMHost = 'TT-HV05A'; },
    [PSCustomObject] @{ VMName = 'EXT-FOOBAR'; VMHost = 'TT-HV05B'; },
    [PSCustomObject] @{ VMName = 'EXT-FOOBAR3'; VMHost = 'TT-HV05A'; },
    [PSCustomObject] @{ VMName = 'EXT-FOOBAR4'; VMHost = 'WOLVERINE'; },
    [PSCustomObject] @{ VMName = 'EXT-FOOBAR7'; VMHost = 'TT-HV05A'; },
    [PSCustomObject] @{ VMName = 'EXT-FOOBAR9'; VMHost = 'WOLVERINE'; },
    [PSCustomObject] @{ VMName = 'EXT-WAP01A'; VMHost = 'TT-HV05A'; })
```

#### # Revert VMs to most recent checkpoint

```PowerShell
$virtualMachinesWithSnapshots |
    ForEach-Object {
        $vmHost = $_.VMHost
        $vmName = $_.VMName

        Write-Progress `
            -Activity $activity `
            -Status "Reverting VM ($vmName) to most recent checkpoint..."

        Get-VMSnapshot -ComputerName $vmHost -VMName $vmName |
            Sort-Object CreationTime |
            Select-Object -Last 1 |
            Restore-VMSnapshot -Confirm:$false -Verbose
    }
```

#### # Start VMs

```PowerShell
$startupDelayInSeconds = 30

$virtualMachinesWithSnapshots |
    ForEach-Object {
        $vmHost = $_.VMHost
        $vmName = $_.VMName

        Write-Progress `
            -Activity $activity `
            -Status "Starting virtual machine ($vmName)..."

        Start-VM -ComputerName $vmHost -VMName $vmName

        Write-Progress `
            -Activity $activity `
            -Status "Waiting for virtual machine ($vmName) to start..."

        Start-Sleep -Seconds $startupDelayInSeconds
    }
```

---

---

**EXT-DC08**

```PowerShell
cls
```

### # Enable firewall rules for remote Windows Update

```PowerShell
$activity = "Enable firewall rules for remote Windows Update"

$script = "
Set-ExecutionPolicy Bypass -Scope Process -Force

& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Enable-RemoteWindowsUpdate.ps1' ``
    -Verbose
"

$scriptBlock = [ScriptBlock]::Create($script)

Get-Content "C:\Users\jjameson-admin\Desktop\Computer List for Windows Update.txt" |
    ForEach-Object {
        $computer = $_

        Write-Progress `
            -Activity $activity `
            -Status "Enabling remote Windows Update on computer ($computer)..."

        Invoke-Command -ComputerName $computer -ScriptBlock $scriptBlock
    }
```

---

### Mirror Toolbox content across all domain computers

---

**FOOBAR16**

```PowerShell
cls
```

#### # Mirror Toolbox content from internal file server to extranet server

```PowerShell
$computerName = "EXT-DC08.extranet.technologytoolbox.com"

net use \\$computerName\C$ /USER:EXTRANET\jjameson-admin
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$source = "\\TT-FS01.corp.technologytoolbox.com\Public\Toolbox"
$destination = "\\$computerName\C`$\NotBackedUp\Public\Toolbox"

robocopy $source $destination /E /MIR /XD git-for-windows "Microsoft SDKs"
```

---

---

**EXT-DC08**

```PowerShell
cls
```

#### # Mirror Toolbox content to all EXTRANET computers

```PowerShell
$source = "C:\NotBackedUp\Public\Toolbox"

$computers = Get-ADComputer -Filter * |
    Where-Object { $_.Name -notin
        @('EXT-SP2013-DEV',
        'EXT-SQL01',
        'EXT-SQL01-FC') } |
    select Name

$computers | ForEach-Object {
    $destination = '\\' + $_.Name + '\C$\NotBackedUp\Public\Toolbox'

    robocopy $source $destination /E /MIR /XD "Microsoft SDKs" /R:1 /W:1
}
```

```PowerShell
cls
```

### # Start PowerShell Patch/Audit Utility and install updates

```PowerShell
cd C:\NotBackedUp\Public\Toolbox\PowerShell\PoshPAIG_2_1_5_1

.\Start-PoshPAIG.ps1
```

---

---

**FOOBAR16**

```PowerShell
cls
```

### # Reboot computers

```PowerShell
$activity = "Reboot computers"
```

#### # Shutdown VMs that depend on EXT-SQL02

```PowerShell
$virtualMachines = @(
    'EXT-ADFS02B',
    'EXT-ADFS02A',
    'EXT-WEB02B',
    'EXT-WEB02A',
    'EXT-APP02A')

$virtualMachines |
    ForEach-Object {
        $vmName = $_

        Write-Progress `
            -Activity $activity `
            -Status "Stopping virtual machine ($vmName)..."

        Get-SCVirtualMachine -Name $vmName |
            Stop-SCVirtualMachine |
            select Name, MostRecentTask, MostRecentTaskUIState
    }
```

```PowerShell
cls
```

#### # Reboot EXT-SQL02

```PowerShell
Get-SCVirtualMachine -Name EXT-SQL02 |
    Stop-SCVirtualMachine |
    select Name, MostRecentTask, MostRecentTaskUIState

Get-SCVirtualMachine -Name EXT-SQL02 |
    Start-SCVirtualMachine |
    select Name, MostRecentTask, MostRecentTaskUIState
```

```PowerShell
cls
```

#### # Start VMs that depend on EXT-SQL02

```PowerShell
$startupDelayInSeconds = 30

# Start virtual machines in the reverse order in which they are shut down
[Array]::Reverse($virtualMachines)

$virtualMachines |
    ForEach-Object {
        $vmName = $_

        Write-Progress `
            -Activity $activity `
            -Status "Starting virtual machine ($vmName)..."

        Get-SCVirtualMachine -Name $_ |
            Start-SCVirtualMachine |
            select Name, MostRecentTask, MostRecentTaskUIState

        Write-Progress `
            -Activity $activity `
            -Status "Waiting for virtual machine ($vmName) to start..."

        Start-Sleep -Seconds $startupDelayInSeconds
    }
```

---

---

**EXT-DC08**

```PowerShell
cls
```

### # Start PowerShell Patch/Audit Utility and check for pending reboots

```PowerShell
cd C:\NotBackedUp\Public\Toolbox\PowerShell\PoshPAIG_2_1_5_1

.\Start-PoshPAIG.ps1
```

```PowerShell
cls
```

### # Disable firewall rules for remote Windows Update

```PowerShell
$activity = "Disable firewall rules for remote Windows Update"

$script = "
Set-ExecutionPolicy Bypass -Scope Process -Force

& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Disable-RemoteWindowsUpdate.ps1' ``
    -Verbose
"

$scriptBlock = [scriptblock]::Create($script)

Get-Content "C:\Users\jjameson-admin\Desktop\Computer List for Windows Update.txt" |
    ForEach-Object {
        $computer = $_

        Write-Progress `
            -Activity $activity `
            -Status "Disabling remote Windows Update on computer ($computer)..."

        Invoke-Command -ComputerName $computer -ScriptBlock $scriptBlock
    }
```

---

### Update checkpoints on development and test VMs after patching

---

**FOOBAR16**

```PowerShell
cls
```

#### # Define list of development and test VMs

```PowerShell
$virtualMachinesWithSnapshots = @(
    [PSCustomObject] @{ VMName = 'EXT-ADFS01A'; VMHost = 'TT-HV05A'; },
    [PSCustomObject] @{ VMName = 'EXT-FOOBAR'; VMHost = 'TT-HV05B'; },
    [PSCustomObject] @{ VMName = 'EXT-FOOBAR3'; VMHost = 'TT-HV05A'; },
    [PSCustomObject] @{ VMName = 'EXT-FOOBAR4'; VMHost = 'WOLVERINE'; },
    [PSCustomObject] @{ VMName = 'EXT-FOOBAR7'; VMHost = 'TT-HV05A'; },
    [PSCustomObject] @{ VMName = 'EXT-FOOBAR9'; VMHost = 'WOLVERINE'; },
    [PSCustomObject] @{ VMName = 'EXT-WAP01A'; VMHost = 'TT-HV05A'; })
```

#### # Stop VMs after patching and update "Baseline" checkpoints

```PowerShell
$virtualMachinesWithSnapshots |
    ForEach-Object {
        $vmHost = $_.VMHost
        $vmName = $_.VMName

        C:\NotBackedUp\Public\Toolbox\PowerShell\Update-VMBaseline.ps1 `
            -ComputerName $vmHost `
            -Name $vmName `
            -Confirm:$false `
            -Verbose
    }
```

---
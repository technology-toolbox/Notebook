# Windows Update - TECHTOOLBOX

Saturday, January 11, 2014\
7:56 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Patch TT-ADMIN04 (before patching other machines)

## Patch remaining TECHTOOLBOX machines

### Prepare development and test VMs for patching

---

**TT-ADMIN04** - Run as domain administrator

```PowerShell
cls
$activity = "Prepare development and test VMs for patching"
```

#### # Define list of development and test VMs

```PowerShell
$virtualMachinesWithSnapshots = @(
    [PSCustomObject] @{ VMName = 'TT-VS2013-DEV'; VMHost = 'STORM'; },
    [PSCustomObject] @{ VMName = 'TT-W10-DEV-10'; VMHost = 'STORM'; },
    [PSCustomObject] @{ VMName = 'TT-W10-DEV-11'; VMHost = 'TT-HV05E'; },
    [PSCustomObject] @{ VMName = 'TT-W7-TEST-04'; VMHost = 'TT-HV05E'; },
    [PSCustomObject] @{ VMName = 'TT-W7-TEST-05'; VMHost = 'TT-HV05E'; },
    [PSCustomObject] @{ VMName = 'TT-W7-TEST-06'; VMHost = 'TT-HV05E'; },
    [PSCustomObject] @{ VMName = 'TT-W8-TEST-02'; VMHost = 'TT-HV05E'; })
```

#### # Revert VMs to most recent checkpoint

```PowerShell
$virtualMachinesWithSnapshots |
    foreach {
        $vmHost = $_.VMHost
        $vmName = $_.VMName

        Write-Progress `
            -Activity $activity `
            -Status "Reverting VM ($vmName) to most recent checkpoint..."

        Get-VMSnapshot -ComputerName $vmHost -VMName $vmName |
            sort CreationTime |
            select -Last 1 |
            Restore-VMSnapshot -Confirm:$false -Verbose
    }
```

#### # Start VMs

```PowerShell
$startupDelayInSeconds = 30

$virtualMachinesWithSnapshots |
    foreach {
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

Get-Content "\\TT-FS01\Users$\jjameson-admin\My Documents\Computer List for Windows Update.txt" |
    where { $_ -notin @('BANSHEE') } |
    foreach {
        $computer = $_

        Write-Progress `
            -Activity $activity `
            -Status "Enabling remote Windows Update on computer ($computer)..."

        Invoke-Command -ComputerName $computer -ScriptBlock $scriptBlock
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

```PowerShell
cls
```

### # Reboot computers

```PowerShell
$activity = "Reboot computers"
```

#### # Shutdown VMs that depend on HAVOK and HAVOK-TEST

```PowerShell
$virtualMachines = @(
    'DAZZLER',
    'CYCLOPS',
    'POLARIS',
    'COLOSSUS',
    'POLARIS-TEST',
    'CYCLOPS-TEST')

$virtualMachines |
    foreach {
        $vmName = $_

        Write-Progress `
            -Activity $activity `
            -Status "Stopping virtual machine ($vmName)..."

        Get-SCVirtualMachine -Name $vmName |
            where { $_.VirtualMachineState -eq 'Running' } |
            Stop-SCVirtualMachine |
            select Name, MostRecentTask, MostRecentTaskUIState
    }
```

```PowerShell
cls
```

#### # Reboot HAVOK and HAVOK-TEST

```PowerShell
$virtualMachines = @(
    'HAVOK',
    'HAVOK-TEST')

$virtualMachines |
    foreach {
        $vmName = $_

        Write-Progress `
            -Activity $activity `
            -Status "Stopping virtual machine ($vmName)..."

        Get-SCVirtualMachine -Name $vmName |
            where { $_.VirtualMachineState -eq 'Running' } |
            Stop-SCVirtualMachine |
            select Name, MostRecentTask, MostRecentTaskUIState

        Write-Progress `
            -Activity $activity `
            -Status "Starting virtual machine ($vmName)..."

        Get-SCVirtualMachine -Name $vmName |
            Start-SCVirtualMachine |
            select Name, MostRecentTask, MostRecentTaskUIState
    }
```

```PowerShell
cls
```

#### # Shutdown SharePoint 2013 test farm (database VM stored on NAS)

```PowerShell
$sharePointVirtualMachines = @(
    'EXT-WAP03B',
    'EXT-WAP03A',
    'EXT-ADFS03B',
    'EXT-ADFS03A',
    'EXT-WEB03B',
    'EXT-WEB03A',
    'EXT-APP03A',
    'EXT-SQL03')

$sharePointVirtualMachines |
    foreach {
        $vmName = $_

        Write-Progress `
            -Activity $activity `
            -Status "Stopping virtual machine ($vmName)..."

        Get-SCVirtualMachine -Name $vmName |
            where { $_.VirtualMachineState -eq 'Running' } |
            Stop-SCVirtualMachine |
            select Name, MostRecentTask, MostRecentTaskUIState
    }
```

```PowerShell
cls
```

#### # Shutdown VMs stored on NAS

```PowerShell
$coreVirtualMachines = @(
    'EXT-DC08',
    'EXT-DC09',
    'FOOBAR7',
    'FOOBAR18',
    'FOOBAR19',
    'HAVOK-TEST')

Get-SCVirtualMachine |
    where { $_.Location -like 'C:\ClusterStorage\*' } |
    where { $_.Name -notin $coreVirtualMachines } |
    where { $_.VirtualMachineState -eq 'Running' } |
    foreach {
        $vmName = $_.Name

        Write-Progress `
            -Activity $activity `
            -Status "Stopping virtual machine ($vmName)..."

        Stop-SCVirtualMachine $_ |
            select Name, MostRecentTask, MostRecentTaskUIState
    }
```

#### # Shutdown "core" VMs -- except FOOBAR18 and FOOBAR19

```PowerShell
Get-SCVirtualMachine |
    where { $_.Name -in $coreVirtualMachines } |
    where { $_.Name -notin @('FOOBAR18', 'FOOBAR19') } |
    where { $_.VirtualMachineState -eq 'Running' } |
    foreach {
        $vmHost = $_

        $vmName = $_.Name

        Write-Progress `
            -Activity $activity `
            -Status "Stopping virtual machine ($vmName)..."

        Stop-SCVirtualMachine $_ |
            select Name, MostRecentTask, MostRecentTaskUIState
    }
```

```PowerShell
cls
```

#### # Reboot TT-HV03 and TT-DC04

```PowerShell
@('TT-HV03', 'TT-DC04') |
    foreach {
        Restart-Computer $_
    }
```

```PowerShell
cls
```

#### # Restart PowerShell (to avoid issue after VM restarts from saved state)

```PowerShell
Exit
```

```PowerShell
cls
$activity = "Reboot computers"
```

#### # Reboot TT-HV02A

```PowerShell
Restart-Computer TT-HV02A

ping -t TT-HV02A
```

```PowerShell
cls
```

#### # Reboot TT-HV02B

```PowerShell
Restart-Computer TT-HV02B

ping -t TT-HV02B
```

```PowerShell
cls
```

#### # Reboot TT-HV02C

```PowerShell
Restart-Computer TT-HV02C

ping -t TT-HV02C
```

```PowerShell
cls
```

#### # Start VMs that depend on HAVOK and HAVOK-TEST

```PowerShell
$startupDelayInSeconds = 30

$virtualMachines = @(
    'DAZZLER',
    'CYCLOPS',
    'POLARIS',
    'COLOSSUS',
    'POLARIS-TEST',
    'CYCLOPS-TEST')

# Start virtual machines in the reverse order in which they are shut down
[Array]::Reverse($virtualMachines)

$virtualMachines |
    foreach {
        $vmName = $_

        Write-Progress `
            -Activity $activity `
            -Status "Starting virtual machine ($vmName)..."

        Get-SCVirtualMachine -Name $vmName |
            where { $_.VirtualMachineState -ne 'Running' } |
            Start-SCVirtualMachine |
            select Name, MostRecentTask, MostRecentTaskUIState

        Write-Progress `
            -Activity $activity `
            -Status "Waiting for virtual machine ($vmName) to start..."

        Start-Sleep -Seconds $startupDelayInSeconds
    }
```

```PowerShell
cls
```

#### # Start SharePoint 2013 test farm (database VM stored on NAS)

```PowerShell
$startupDelayInSeconds = 30

$sharePointVirtualMachines = @(
    'EXT-WAP02B',
    'EXT-WAP02A',
    'EXT-ADFS02B',
    'EXT-ADFS02A',
    'EXT-WEB02B',
    'EXT-WEB02A',
    'EXT-APP02A',
    'EXT-SQL02')

# Start virtual machines in the reverse order in which they are shut down
[Array]::Reverse($sharePointVirtualMachines)

$sharePointVirtualMachines |
    foreach {
        $vmName = $_

        Write-Progress `
            -Activity $activity `
            -Status "Starting virtual machine ($vmName)..."

        Get-SCVirtualMachine -Name $vmName |
            where { $_.VirtualMachineState -ne 'Running' } |
            Start-SCVirtualMachine |
            select Name, MostRecentTask, MostRecentTaskUIState

        Write-Progress `
            -Activity $activity `
            -Status "Waiting for virtual machine ($vmName) to start..."

        Start-Sleep -Seconds $startupDelayInSeconds
    }
```

#### # Start SharePoint 2010 development farm (iSCSI dependency to TT-HV03)

```PowerShell
$startupDelayInSeconds = 30

$sharePointVirtualMachines = @(
    'EXT-SQL01B',
    'EXT-WEB01B',
    'EXT-WEB01A',
    'EXT-APP01A',
    'EXT-SQL01A')

# Start virtual machines in the reverse order in which they are shut down
[Array]::Reverse($sharePointVirtualMachines)

$sharePointVirtualMachines |
    foreach {
        $vmName = $_

        Write-Progress `
            -Activity $activity `
            -Status "Starting virtual machine ($vmName)..."

        Get-SCVirtualMachine -Name $vmName |
            where { $_.VirtualMachineState -ne 'Running' } |
            Start-SCVirtualMachine |
            select Name, MostRecentTask, MostRecentTaskUIState

        Write-Progress `
            -Activity $activity `
            -Status "Waiting for virtual machine ($vmName) to start..."

        Start-Sleep -Seconds $startupDelayInSeconds
    }
```

#### # Start VMs stored on NAS

```PowerShell
$startupDelayInSeconds = 15

Get-SCVirtualMachine |
    where { $_.Location -like 'C:\ClusterStorage\*' } |
    where { $_.Name -notin @(
        'CRYPTID',
        'DEVOPS2012',
        'EXT-RRAS1',
        'FAB-FOOBAR4') } |
    where { $_.VirtualMachineState -ne 'Running' } |
    foreach {
        $vmName = $_.Name

        Write-Progress `
            -Activity $activity `
            -Status "Starting virtual machine ($vmName)..."

        Start-SCVirtualMachine $_ |
            select Name, MostRecentTask, MostRecentTaskUIState

        Write-Progress `
            -Activity $activity `
            -Status "Waiting for virtual machine ($vmName) to start..."

        Start-Sleep -Seconds $startupDelayInSeconds
    }
```

```PowerShell
cls
```

### # Restart PowerShell Patch/Audit Utility and check for pending reboots

```PowerShell
cd C:\NotBackedUp\Public\Toolbox\PowerShell\PoshPAIG_2_1_5_1

.\Start-PoshPAIG.ps1
```

### Reboot remaining computers

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

$scriptBlock = [ScriptBlock]::Create($script)

Get-Content "\\TT-FS01\Users$\jjameson-admin\My Documents\Computer List for Windows Update.txt" |
    where { $_ -notin @('BANSHEE') } |
    foreach {
        $computer = $_

        Write-Progress `
            -Activity $activity `
            -Status "Disabling remote Windows Update on computer ($computer)..."

        Invoke-Command -ComputerName $computer -ScriptBlock $scriptBlock
    }
```

```PowerShell
cls
```

### # Stop VMs after patching and update "Baseline" checkpoints

```PowerShell
$virtualMachinesWithSnapshots = @(
    [PSCustomObject] @{ VMName = 'TT-VS2013-DEV'; VMHost = 'STORM'; },
    [PSCustomObject] @{ VMName = 'TT-W10-DEV-10'; VMHost = 'STORM'; },
    [PSCustomObject] @{ VMName = 'TT-W10-DEV-11'; VMHost = 'TT-HV05E'; },
    [PSCustomObject] @{ VMName = 'TT-W7-TEST-04'; VMHost = 'TT-HV05E'; },
    [PSCustomObject] @{ VMName = 'TT-W7-TEST-05'; VMHost = 'TT-HV05E'; },
    [PSCustomObject] @{ VMName = 'TT-W7-TEST-06'; VMHost = 'TT-HV05E'; },
    [PSCustomObject] @{ VMName = 'TT-W8-TEST-02'; VMHost = 'TT-HV05E'; })

$virtualMachinesWithSnapshots |
    foreach {
        $vmHost = $_.VMHost
        $vmName = $_.VMName

        C:\NotBackedUp\Public\Toolbox\PowerShell\Update-VMBaseline.ps1 `
            -ComputerName $vmHost `
            -Name $vmName `
            -Confirm:$false
    }
```

---

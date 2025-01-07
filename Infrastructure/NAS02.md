# NAS02

Friday, March 30, 2018\
10:38 AM

| Interface | Name       | MAC Address       | Port |
| --------- | ---------- | ----------------- | ---- |
| em0       | Management | 68:05:CA:19:13:32 | 24   |
| igb0      | Storage-10 | AC:1F:6B:43:D0:CA | 14   |
| igb1      | Storage-13 | AC:1F:6B:43:D0:CB | 13   |

![(screenshot)](https://assets.technologytoolbox.com/screenshots/19/42467F91F9ECEF93E7114F75394DAC9C37C64519.png)

## Upgrade NAS

---

**TT-ADMIN05** - Run as administrator

```PowerShell
cls
```

### # Shutdown VMs stored on NAS

```PowerShell
$activity = 'Upgrade NAS'
```

#### # Shutdown all VMs stored on NAS except "core" VMs

```PowerShell
$coreVirtualMachines = @(
    'CON-DC05',
    'CON-DC06',
    'EXT-DC10',
    'EXT-DC11',
    'FAB-DC05',
    'FAB-DC06',
    'TT-ADMIN05')

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

```PowerShell
cls
```

#### # Shutdown remaining VMs stored on NAS (i.e. "core" VMs)

```PowerShell
Get-SCVirtualMachine |
    where { $_.Location -like 'C:\ClusterStorage\*' } |
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

#### # Start "core" VMs stored on NAS

```PowerShell
$activity = 'Upgrade NAS'

$startupDelayInSeconds = 30

# Start virtual machines in the reverse order in which they are shut down
[Array]::Reverse($coreVirtualMachines)

Get-SCVirtualMachine |
    where { $_.Location -like 'C:\ClusterStorage\*' } |
    where { $_.Name -in $coreVirtualMachines } |
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

#### # Start remaining VMs stored on NAS

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

---

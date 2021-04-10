# Windows Update - EXTRANET

Saturday, January 11, 2014\
7:56 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Patch EXT-DC10 (before patching other machines)

## Patch remaining EXTRANET machines

### Prepare development and test VMs for patching

---

**TT-ADMIN03** - Run as administrator

```PowerShell
cls
$activity = "Prepare development and test VMs for patching"
```

#### # Define list of development and test VMs

```PowerShell
$virtualMachinesWithSnapshots = @(
    [PSCustomObject] @{ VMName = 'EXT-ADFS01A'; VMHost = 'TT-HV05D'; },
    [PSCustomObject] @{ VMName = 'EXT-FOOBAR2'; VMHost = 'TT-HV05D'; },
    [PSCustomObject] @{ VMName = 'EXT-FOOBAR8'; VMHost = 'TT-HV05E'; },
    [PSCustomObject] @{ VMName = 'EXT-VS2008-DEV1'; VMHost = 'TT-HV05F'; },
    [PSCustomObject] @{ VMName = 'EXT-VS2010-DEV1'; VMHost = 'STORM'; },
    [PSCustomObject] @{ VMName = 'EXT-VS2012-DEV1'; VMHost = 'TT-HV05F'; },
    [PSCustomObject] @{ VMName = 'EXT-VS2013-DEV1'; VMHost = 'TT-HV05F'; },
    [PSCustomObject] @{ VMName = 'EXT-VS2015-DEV1'; VMHost = 'TT-HV05F'; },
    [PSCustomObject] @{ VMName = 'EXT-VS2017-DEV1'; VMHost = 'TT-HV05F'; },
    [PSCustomObject] @{ VMName = 'EXT-VS2017-DEV2'; VMHost = 'TT-HV05F'; },
    [PSCustomObject] @{ VMName = 'EXT-VS2017-DEV3'; VMHost = 'TT-HV05F'; },
    [PSCustomObject] @{ VMName = 'EXT-VS2019-DEV1'; VMHost = 'TT-HV05F'; },
    [PSCustomObject] @{ VMName = 'EXT-VS2019-DEV2'; VMHost = 'TT-HV05F'; },
    [PSCustomObject] @{ VMName = 'EXT-WAP01A'; VMHost = 'TT-HV05D'; })
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

---

---

**EXT-DC10** - Run as domain administrator

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
    foreach {
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

**TT-ADMIN03** - Run as administrator

```PowerShell
cls
```

#### # Mirror Toolbox content from internal file server to extranet server

```PowerShell
$computerName = "EXT-DC10.extranet.technologytoolbox.com"

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

**EXT-DC10** - Run as domain administrator

```PowerShell
cls
```

#### # Mirror Toolbox content to all EXTRANET computers

```PowerShell
$source = "C:\NotBackedUp\Public\Toolbox"

$computers = Get-ADComputer -Filter * |
    where { $_.Name -notin
        @('EXT-SEQ02',
        'EXT-SP2013-DEV',
        'EXT-SQL01',
        'EXT-SQL01-FC') } |
    select Name

$computers | foreach {
    $destination = '\\' + $_.Name + '\C$\NotBackedUp\Public\Toolbox'

    robocopy $source $destination /E /MIR /XD git-for-windows "Microsoft SDKs" /R:1 /W:1
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

**TT-ADMIN03** - Run as administrator

```PowerShell
cls
```

### # Reboot computers

```PowerShell
$activity = "Reboot computers"
```

#### # Shutdown VMs that depend on EXT-SQL03

```PowerShell
$virtualMachines = @(
    'EXT-ADFS03B',
    'EXT-ADFS03A',
    'EXT-WEB03B',
    'EXT-WEB03A',
    'EXT-APP03A')

$virtualMachines |
    foreach {
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

#### # Reboot EXT-SQL03

```PowerShell
Get-SCVirtualMachine -Name EXT-SQL03 |
    Stop-SCVirtualMachine |
    select Name, MostRecentTask, MostRecentTaskUIState

Get-SCVirtualMachine -Name EXT-SQL03 |
    Start-SCVirtualMachine |
    select Name, MostRecentTask, MostRecentTaskUIState
```

```PowerShell
cls
```

#### # Start VMs that depend on EXT-SQL03

```PowerShell
$startupDelayInSeconds = 30

# Start virtual machines in the reverse order in which they are shut down
[Array]::Reverse($virtualMachines)

$virtualMachines |
    foreach {
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

**EXT-DC10** - Run as domain administrator

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

$scriptBlock = [ScriptBlock]::Create($script)

Get-Content "C:\Users\jjameson-admin\Desktop\Computer List for Windows Update.txt" |
    foreach {
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

**TT-ADMIN03** - Run as administrator

```PowerShell
cls
```

#### # Define list of development and test VMs

```PowerShell
$virtualMachinesWithSnapshots = @(
    [PSCustomObject] @{ VMName = 'EXT-ADFS01A'; VMHost = 'TT-HV05D'; },
    [PSCustomObject] @{ VMName = 'EXT-FOOBAR2'; VMHost = 'TT-HV05D'; },
    [PSCustomObject] @{ VMName = 'EXT-FOOBAR8'; VMHost = 'TT-HV05E'; },
    [PSCustomObject] @{ VMName = 'EXT-VS2008-DEV1'; VMHost = 'TT-HV05F'; },
    [PSCustomObject] @{ VMName = 'EXT-VS2010-DEV1'; VMHost = 'STORM'; },
    [PSCustomObject] @{ VMName = 'EXT-VS2012-DEV1'; VMHost = 'TT-HV05F'; },
    [PSCustomObject] @{ VMName = 'EXT-VS2013-DEV1'; VMHost = 'TT-HV05F'; },
    [PSCustomObject] @{ VMName = 'EXT-VS2015-DEV1'; VMHost = 'TT-HV05F'; },
    [PSCustomObject] @{ VMName = 'EXT-VS2017-DEV1'; VMHost = 'TT-HV05F'; },
    [PSCustomObject] @{ VMName = 'EXT-VS2017-DEV2'; VMHost = 'TT-HV05F'; },
    [PSCustomObject] @{ VMName = 'EXT-VS2017-DEV3'; VMHost = 'TT-HV05F'; },
    [PSCustomObject] @{ VMName = 'EXT-VS2019-DEV1'; VMHost = 'TT-HV05F'; },
    [PSCustomObject] @{ VMName = 'EXT-VS2019-DEV2'; VMHost = 'TT-HV05F'; },
    [PSCustomObject] @{ VMName = 'EXT-WAP01A'; VMHost = 'TT-HV05D'; })
```

#### # Stop VMs after patching and update "Baseline" checkpoints

```PowerShell
$virtualMachinesWithSnapshots |
    foreach {
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

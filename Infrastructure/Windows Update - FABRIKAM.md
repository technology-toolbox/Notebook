# Windows Update - FABRIKAM

Saturday, January 11, 2014
7:56 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Patch FAB-DC01 (before patching other machines)

## Patch remaining FABRIKAM machines

### Prepare development and test VMs for patching

---

**FOOBAR10**

```PowerShell
cls
$activity = "Prepare development and test VMs for patching"
```

#### # Define list of development and test VMs

```PowerShell
$virtualMachinesWithSnapshots = @(
    [PSCustomObject] @{ VMName = 'FAB-FOOBAR4'; VMHost = 'TT-HV05C'; },
    [PSCustomObject] @{ VMName = 'FAB-TEST1'; VMHost = 'WOLVERINE'; })
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
$startupDelayInSeconds = 15

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

**FAB-DC01**

```PowerShell
cls
```

### # Enable firewall rules for remote Windows Update

```PowerShell
$script = "
Set-ExecutionPolicy Bypass -Scope Process -Force

& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Enable-RemoteWindowsUpdate.ps1' ``
    -Verbose
"

$scriptBlock = [ScriptBlock]::Create($script)

Get-Content "C:\Users\jjameson-admin\Desktop\Computer list for Windows Update.txt" |
    ForEach-Object {
        $computer = $_

        Write-Host "Enabling remote Windows Update on computer ($computer)..."

        Invoke-Command -ComputerName $computer -ScriptBlock $scriptBlock
    }
```

```PowerShell
cls
```

### # Mirror Toolbox content across all domain computers

```PowerShell
net use \\TT-FS01.corp.technologytoolbox.com\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```PowerShell
$source = "\\TT-FS01.corp.technologytoolbox.com\Public\Toolbox"

$computers = Get-ADComputer -Filter * |
    Where-Object { $_.Name -notin
        @('EXCHANGE-CAS') } |
    select Name

$computers | ForEach-Object {
    $dest = '\\' + $_.Name + '\C$\NotBackedUp\Public\Toolbox'

    robocopy $source $dest /E /MIR /XD "Microsoft SDKs" /R:1 /W:1
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

### # Disable firewall rules for remote Windows Update

```PowerShell
$script = "
Set-ExecutionPolicy Bypass -Scope Process -Force

& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Disable-RemoteWindowsUpdate.ps1' ``
    -Verbose
"

$scriptBlock = [scriptblock]::Create($script)

Get-Content "C:\Users\jjameson-admin\Desktop\Computer list for Windows Update.txt" |
    ForEach-Object {
        $computer = $_

        Write-Host "Disabling remote Windows Update on computer ($computer)..."

        Invoke-Command -ComputerName $computer -ScriptBlock $scriptBlock
    }
```

---

### Update checkpoints on development and test VMs after patching

---

**FOOBAR10**

```PowerShell
cls
```

#### # Define list of development and test VMs

```PowerShell
$virtualMachinesWithSnapshots = @(
    [PSCustomObject] @{ VMName = 'FAB-FOOBAR4'; VMHost = 'TT-HV05B'; },
    [PSCustomObject] @{ VMName = 'FAB-TEST1'; VMHost = 'WOLVERINE'; })
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

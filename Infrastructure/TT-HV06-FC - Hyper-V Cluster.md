# TT-HV06-FC - Hyper-V Cluster

Tuesday, January 14, 2025\
9:16 AM

```PowerShell
cls
```

## # Configure anti-affinitity

```PowerShell
Get-ClusterGroup -Cluster TT-HV06-FC |
    where { $_.GroupType -eq "VirtualMachine" } |
    select Name, AntiAffinityClassNames
```

```output
Name            AntiAffinityClassNames
----            ----------------------
CIPHER01        {}
CON-DC05        {}
CON-DC06        {}
CON-W10-TEST-03 {}
EXT-DC10        {}
EXT-DC11        {}
EXT-FS01        {}
EXT-SQL03       {}
EXT-WAC02A      {}
FAB-ADFS02      {}
FAB-ADMIN01     {}
FAB-DC07        {}
FAB-DC08        {}
FAB-FS01        {}
FAB-WEB01       {}
HAVOK-TEST      {}
TT-ADMIN01      {}
TT-ADMIN04      {}
TT-DEPLOY4      {}
TT-DOCKER02     {}
TT-MAIL-TEST01  {}
TT-SQL02        {}
TT-TFS02        {}
TT-WEB02-DEV    {}
TT-WEB03-DEV    {}
TT-WSUS04       {}
```

```PowerShell
$antiAffinityClassNames = New-Object System.Collections.Specialized.StringCollection
$antiAffinityClassNames.Add("CON-DC")
(Get-ClusterGroup `
    -Cluster TT-HV06-FC `
    -Name 'CON-DC05').AntiAffinityClassNames = $antiAffinityClassNames

(Get-ClusterGroup `
    -Cluster TT-HV06-FC `
    -Name 'CON-DC06').AntiAffinityClassNames = $antiAffinityClassNames

Get-ClusterGroup -Cluster TT-HV06-FC |
    where { $_.GroupType -eq "VirtualMachine" } |
    select Name, AntiAffinityClassNames
```

```output
Name            AntiAffinityClassNames
----            ----------------------
CIPHER01        {}
CON-DC05        {CON-DC}
CON-DC06        {CON-DC}
CON-W10-TEST-03 {}
EXT-DC10        {}
EXT-DC11        {}
EXT-FS01        {}
EXT-SQL03       {}
EXT-WAC02A      {}
FAB-ADFS02      {}
FAB-ADMIN01     {}
FAB-DC07        {}
FAB-DC08        {}
FAB-FS01        {}
FAB-WEB01       {}
HAVOK-TEST      {}
TT-ADMIN01      {}
TT-ADMIN04      {}
TT-DEPLOY4      {}
TT-DOCKER02     {}
TT-MAIL-TEST01  {}
TT-SQL02        {}
TT-TFS02        {}
TT-WEB02-DEV    {}
TT-WEB03-DEV    {}
TT-WSUS04       {}
```

```PowerShell
cls
```

## # "General" properties

### # Check preferred owners

```PowerShell
Get-ClusterGroup -Cluster TT-HV06-FC |
    where { $_.GroupType -eq "VirtualMachine" } |
    Get-ClusterOwnerNode
```

```output
ClusterObject   OwnerNodes
-------------   ----------
CIPHER01        {TT-HV06C}
CON-DC05        {TT-HV06A}
CON-DC06        {TT-HV06B}
CON-W10-TEST-03 {}
EXT-DC10        {TT-HV06A}
EXT-DC11        {TT-HV06B}
EXT-FS01        {}
EXT-SQL03       {TT-HV06B}
EXT-WAC02A      {}
FAB-ADFS02      {}
FAB-ADMIN01     {}
FAB-DC07        {TT-HV06A}
FAB-DC08        {TT-HV06B}
FAB-FS01        {}
FAB-WEB01       {}
HAVOK-TEST      {TT-HV06C}
TT-ADMIN01      {}
TT-ADMIN04      {}
TT-DEPLOY4      {}
TT-DOCKER02     {}
TT-MAIL-TEST01  {}
TT-SQL02        {TT-HV06C}
TT-TFS02        {}
TT-WEB02-DEV    {TT-HV06B}
TT-WEB03-DEV    {TT-HV06C}
TT-WSUS04       {}
```

```PowerShell
cls
```

### # Check priority of each VM

```PowerShell
Get-ClusterGroup -Cluster TT-HV06-FC |
    where { $_.GroupType -eq "VirtualMachine" } |
    select Name, Priority |
    Format-Table -AutoSize
```

```output
Name            Priority
----            --------
CIPHER01            3000
CON-DC05            2000
CON-DC06            1000
CON-W10-TEST-03     1000
EXT-DC10            3000
EXT-DC11            2000
EXT-FS01            1000
EXT-SQL03           2000
EXT-WAC02A          1000
FAB-ADFS02          1000
FAB-ADMIN01         1000
FAB-DC07            3000
FAB-DC08            2000
FAB-FS01            1000
FAB-WEB01           1000
HAVOK-TEST          2000
TT-ADMIN01          3000
TT-ADMIN04          2000
TT-DEPLOY4          1000
TT-DOCKER02         3000
TT-MAIL-TEST01      2000
TT-SQL02            2000
TT-TFS02            1000
TT-WEB02-DEV        1000
TT-WEB03-DEV        1000
TT-WSUS04           2000
```

```PowerShell
cls
```

## # "Failover" properties

### # Configure failback options

```PowerShell
Get-ClusterGroup -Cluster TT-HV06-FC |
    where { $_.GroupType -eq "VirtualMachine" } |
    foreach {
        $_.AutoFailbackType = 1     # Allow failback
        $_.FailbackWindowStart = 21 # 9:00 PM
        $_.FailbackWindowEnd = 22   # 10:00 PM
    }
```

```PowerShell
cls
```

### # View failback configuration

```PowerShell
Get-ClusterGroup -Cluster TT-HV06-FC |
    where { $_.GroupType -eq "VirtualMachine" } |
    select Name, AutoFailbackType, FailbackWindowStart, FailbackWindowEnd
```

```output
Name            AutoFailbackType FailbackWindowStart FailbackWindowEnd
----            ---------------- ------------------- -----------------
CIPHER01                       1                  21                22
CON-DC05                       1                  21                22
CON-DC06                       1                  21                22
CON-W10-TEST-03                1                  21                22
EXT-DC10                       1                  21                22
EXT-DC11                       1                  21                22
EXT-FS01                       1                  21                22
EXT-SQL03                      1                  21                22
EXT-WAC02A                     1                  21                22
FAB-ADFS02                     1                  21                22
FAB-ADMIN01                    1                  21                22
FAB-DC07                       1                  21                22
FAB-DC08                       1                  21                22
FAB-FS01                       1                  21                22
FAB-WEB01                      1                  21                22
HAVOK-TEST                     1                  21                22
TT-ADMIN01                     1                  21                22
TT-ADMIN04                     1                  21                22
TT-DEPLOY4                     1                  21                22
TT-DOCKER02                    1                  21                22
TT-MAIL-TEST01                 1                  21                22
TT-SQL02                       1                  21                22
TT-TFS02                       1                  21                22
TT-WEB02-DEV                   1                  21                22
TT-WEB03-DEV                   1                  21                22
TT-WSUS04                      1                  21                22
```

```PowerShell
cls
```

### # Verify VMs are running on preferred owner

```PowerShell
Get-ClusterGroup -Cluster TT-HV06-FC -Verbose:$false |
    where { $_.GroupType -eq "VirtualMachine" } |
    foreach {
        $ownerNodeInfo = Get-ClusterOwnerNode `
            -Cluster TT-HV06-FC `
            -Group $_.Name `
            -Verbose:$false

        If ($ownerNodeInfo.OwnerNodes.Length -gt 0)
        {
            $preferredOwner = $ownerNodeInfo.OwnerNodes[0].Name

            If ($_.OwnerNode -eq $preferredOwner)
            {
                Write-Verbose "$($_.Name) is running on the preferred owner ($preferredOwner)."
            }
            Else
            {
                Write-Warning ("$($_.Name) is running on $($_.OwnerNode)" `
                    + " -- which is not the preferred owner ($preferredOwner).")
            }
        }
    }
```

```PowerShell
cls
```

### # Move VMs to preferred owner

```PowerShell
$clusterName = "TT-HV06-FC"

Get-ClusterGroup -Cluster $clusterName |
    where { $_.GroupType -eq "VirtualMachine" } |
    foreach {
        $ownerNodeInfo = Get-ClusterOwnerNode -Cluster $clusterName -Group $_.Name

        If ($ownerNodeInfo.OwnerNodes.Length -gt 0)
        {
            $preferredOwner = $ownerNodeInfo.OwnerNodes[0].Name

            If ($_.OwnerNode -ne $preferredOwner)
            {
                Write-Verbose "Moving VM ($($_.Name)) to preferred owner ($preferredOwner)..."

                Move-ClusterVirtualMachineRole `
                    -Cluster $clusterName `
                    -Name $_.Name `
                    -Node $preferredOwner
            }
        }
    }
```

```PowerShell
cls
```

## # Virtual disk info

```PowerShell
Get-ClusterGroup -Cluster TT-HV06-FC |
    where { $_.GroupType -eq "VirtualMachine" } |
    foreach {
        Get-VM -ComputerName $_.OwnerNode -Name $_.Name |
            Get-VMHardDiskDrive |
            Get-VHD -ComputerName $_.OwnerNode |
            select Path, @{N="Size"; E={[Math]::Round(($_.Size / 1GB), 2) }}
    } |
    Format-Table -AutoSize
```

```PowerShell
cls
```

## # Stop VMs in desired order

```PowerShell
Import-Csv 'C:\NotBackedUp\Temp\Cluster VMs.csv' |
    sort @{ e = {$_.StartupOrder -as [int]} } -Descending |
    where { $_.StartupOrder -ne 0 } |
    foreach {
        $vm = Get-SCVirtualMachine -Name $_.Name

        If ($vm.VirtualMachineState -eq 'Running')
        {
            Write-Verbose "Stopping VM ($($vm.Name))..."

            Stop-SCVirtualMachine $vm |
                select Name, MostRecentTask, MostRecentTaskUIState
        }
    }
```

```PowerShell
cls
```

## # Start VMs in desired order

```PowerShell
Import-Csv 'C:\NotBackedUp\Temp\Cluster VMs.csv' |
    sort @{ e = {$_.StartupOrder -as [int]} } |
    where { $_.StartupOrder -ne 0 } |
    foreach {
        $vm = Get-SCVirtualMachine -Name $_.Name

        If ($vm.VirtualMachineState -ne 'Running')
        {
            Write-Verbose "Starting VM ($($vm.Name))..."

            Start-SCVirtualMachine $vm |
                select Name, MostRecentTask, MostRecentTaskUIState

            Start-Sleep -Seconds 30
        }
    }
```

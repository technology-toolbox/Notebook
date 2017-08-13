# TT-HV02 - Hyper-V Cluster

Friday, March 3, 2017
4:40 AM

```PowerShell
cls
```

## # Configure anti-affinitity

```PowerShell
Get-ClusterGroup |
    ? { $_.GroupType -eq "VirtualMachine" } |
    select Name, AntiAffinityClassNames

Name                         AntiAffinityClassNames
----                         ----------------------
SCVMM BANSHEE Resources      {}
SCVMM CIPHER01 Resources     {}
SCVMM COLOSSUS Resources     {}
SCVMM CON-ADFS1 Resources    {}
SCVMM CON-DC1 Resources      {}
SCVMM CON-DC2 Resources      {}
SCVMM CRYPTID Resources      {}
SCVMM CYCLOPS Resources      {}
SCVMM CYCLOPS-TEST Resources {}
SCVMM DAZZLER Resources      {}
SCVMM EXT-DC04 Resources     {}
SCVMM EXT-DC05 Resources     {}
SCVMM EXT-RRAS1 Resources    {}
SCVMM EXT-SQL02 Resources    {}
SCVMM EXT-WAC02A Resources   {}
SCVMM FAB-DC01 Resources     {}
SCVMM FAB-DC02 Resources     {}
SCVMM FAB-WEB01 Resources    {}
SCVMM FOOBAR7 Resources      {}
SCVMM HAVOK-TEST Resources   {}
SCVMM JUBILEE Resources      {}
SCVMM MIMIC Resources        {}
SCVMM MIMIC2 Resources       {}
SCVMM POLARIS-TEST Resources {}

$antiAffinityClassNames = New-Object System.Collections.Specialized.StringCollection
$antiAffinityClassNames.Add("CON-DC")
(Get-ClusterGroup 'SCVMM CON-DC1 Resources').AntiAffinityClassNames = $antiAffinityClassNames
(Get-ClusterGroup 'SCVMM CON-DC2 Resources').AntiAffinityClassNames = $antiAffinityClassNames

$antiAffinityClassNames = New-Object System.Collections.Specialized.StringCollection
$antiAffinityClassNames.Add("EXT-DC")
(Get-ClusterGroup 'SCVMM EXT-DC04 Resources').AntiAffinityClassNames = $antiAffinityClassNames
(Get-ClusterGroup 'SCVMM EXT-DC05 Resources').AntiAffinityClassNames = $antiAffinityClassNames

$antiAffinityClassNames = New-Object System.Collections.Specialized.StringCollection
$antiAffinityClassNames.Add("FAB-DC")
(Get-ClusterGroup 'SCVMM FAB-DC01 Resources').AntiAffinityClassNames = $antiAffinityClassNames
(Get-ClusterGroup 'SCVMM FAB-DC02 Resources').AntiAffinityClassNames = $antiAffinityClassNames

Get-ClusterGroup -Cluster TT-HV02-FC |
    ? { $_.GroupType -eq "VirtualMachine" } |
    select Name, AntiAffinityClassNames

Name                         AntiAffinityClassNames
----                         ----------------------
SCVMM BANSHEE Resources      {}
SCVMM CIPHER01 Resources     {}
SCVMM COLOSSUS Resources     {}
SCVMM CON-ADFS1 Resources    {}
SCVMM CON-DC1 Resources      {CON-DC}
SCVMM CON-DC2 Resources      {CON-DC}
SCVMM CRYPTID Resources      {}
SCVMM CYCLOPS Resources      {}
SCVMM CYCLOPS-TEST Resources {}
SCVMM DAZZLER Resources      {}
SCVMM EXT-DC04 Resources     {EXT-DC}
SCVMM EXT-DC05 Resources     {EXT-DC}
SCVMM EXT-RRAS1 Resources    {}
SCVMM EXT-SQL02 Resources    {}
SCVMM EXT-WAC02A Resources   {}
SCVMM FAB-DC01 Resources     {FAB-DC}
SCVMM FAB-DC02 Resources     {FAB-DC}
SCVMM FAB-WEB01 Resources    {}
SCVMM FOOBAR7 Resources      {}
SCVMM HAVOK-TEST Resources   {}
SCVMM JUBILEE Resources      {}
SCVMM MIMIC Resources        {}
SCVMM MIMIC2 Resources       {}
SCVMM POLARIS-TEST Resources {}
```

```PowerShell
cls
```

## # "General" properties

### # Check preferred owners

```PowerShell
Get-ClusterGroup -Cluster TT-HV02-FC |
    where { $_.GroupType -eq "VirtualMachine" } |
    Get-ClusterOwnerNode

ClusterObject                OwnerNodes
-------------                ----------
SCVMM BANSHEE Resources      {}
SCVMM CIPHER01 Resources     {}
SCVMM COLOSSUS Resources     {}
SCVMM CON-ADFS1 Resources    {}
SCVMM CON-DC1 Resources      {TT-HV02A}
SCVMM CON-DC2 Resources      {TT-HV02B}
SCVMM CRYPTID Resources      {}
SCVMM CYCLOPS Resources      {}
SCVMM CYCLOPS-TEST Resources {}
SCVMM DAZZLER Resources      {}
SCVMM EXT-DC04 Resources     {TT-HV02A}
SCVMM EXT-DC05 Resources     {TT-HV02B}
SCVMM EXT-RRAS1 Resources    {}
SCVMM EXT-SQL02 Resources    {TT-HV02C}
SCVMM EXT-WAC02A Resources   {}
SCVMM FAB-DC01 Resources     {TT-HV02A}
SCVMM FAB-DC02 Resources     {TT-HV02B}
SCVMM FAB-WEB01 Resources    {}
SCVMM FOOBAR10 Resources     {}
SCVMM FOOBAR7 Resources      {}
SCVMM HAVOK-TEST Resources   {}
SCVMM MIMIC Resources        {}
SCVMM MIMIC2 Resources       {}
SCVMM POLARIS-TEST Resources {TT-HV02B}
SCVMM TT-SCOM01 Resources    {}
```

```PowerShell
cls
```

### # Check priority of each VM

```PowerShell
Get-ClusterGroup -Cluster TT-HV02-FC |
    where { $_.GroupType -eq "VirtualMachine" } |
    select Name, Priority |
    ft -auto

Name                         Priority
----                         --------
SCVMM BANSHEE Resources          1000
SCVMM CIPHER01 Resources         2000
SCVMM COLOSSUS Resources         2000
SCVMM CON-ADFS1 Resources        1000
SCVMM CON-DC1 Resources          1000
SCVMM CON-DC2 Resources          1000
SCVMM CRYPTID Resources             0
SCVMM CYCLOPS Resources          2000
SCVMM CYCLOPS-TEST Resources     1000
SCVMM DAZZLER Resources          1000
SCVMM EXT-DC04 Resources         3000
SCVMM EXT-DC05 Resources         3000
SCVMM EXT-RRAS1 Resources           0
SCVMM EXT-SQL02 Resources        3000
SCVMM EXT-WAC02A Resources       1000
SCVMM FAB-DC01 Resources         3000
SCVMM FAB-DC02 Resources         3000
SCVMM FAB-WEB01 Resources        1000
SCVMM FOOBAR10 Resources         2000
SCVMM FOOBAR7 Resources          1000
SCVMM HAVOK-TEST Resources       1000
SCVMM MIMIC Resources            1000
SCVMM MIMIC2 Resources           1000
SCVMM POLARIS-TEST Resources     1000
SCVMM TT-SCOM01 Resources        2000
```

```PowerShell
cls
```

## # "Failover" properties

### # Configure failback options

```PowerShell
Get-ClusterGroup -Cluster TT-HV02-FC |
    where { $_.GroupType -eq "VirtualMachine" } |
    foreach {
        $_.AutoFailbackType = 1     # Allow failback
        $_.FailbackWindowStart = 21 # 9:00 PM
        $_.FailbackWindowEnd = 0    # 12:00 AM
    }
```

```PowerShell
cls
```

### # View failback configuration

```PowerShell
Get-ClusterGroup -Cluster TT-HV02-FC |
    where { $_.GroupType -eq "VirtualMachine" } |
    select Name, AutoFailbackType, FailbackWindowStart, FailbackWindowEnd

Name                         AutoFailbackType FailbackWindowStart FailbackWindowEnd
----                         ---------------- ------------------- -----------------
SCVMM BANSHEE Resources                     1                  21                 0
SCVMM CIPHER01 Resources                    1                  21                 0
SCVMM COLOSSUS Resources                    1                  21                 0
SCVMM CON-ADFS1 Resources                   1                  21                 0
SCVMM CON-DC1 Resources                     1                  21                 0
SCVMM CON-DC2 Resources                     1                  21                 0
SCVMM CRYPTID Resources                     1                  21                 0
SCVMM CYCLOPS Resources                     1                  21                 0
SCVMM CYCLOPS-TEST Resources                1                  21                 0
SCVMM DAZZLER Resources                     1                  21                 0
SCVMM EXT-DC04 Resources                    1                  21                 0
SCVMM EXT-DC05 Resources                    1                  21                 0
SCVMM EXT-RRAS1 Resources                   1                  21                 0
SCVMM EXT-SQL02 Resources                   1                  21                 0
SCVMM EXT-WAC02A Resources                  1                  21                 0
SCVMM FAB-DC01 Resources                    1                  21                 0
SCVMM FAB-DC02 Resources                    1                  21                 0
SCVMM FAB-WEB01 Resources                   1                  21                 0
SCVMM FOOBAR10 Resources                    1                  21                 0
SCVMM FOOBAR7 Resources                     1                  21                 0
SCVMM HAVOK-TEST Resources                  1                  21                 0
SCVMM MIMIC Resources                       1                  21                 0
SCVMM MIMIC2 Resources                      1                  21                 0
SCVMM POLARIS-TEST Resources                1                  21                 0
SCVMM TT-SCOM01 Resources                   1                  21                 0
```

```PowerShell
cls
```

### # Verify VMs are running on preferred owner

```PowerShell
Get-ClusterGroup -Cluster TT-HV02-FC -Verbose:$false |
    where { $_.GroupType -eq "VirtualMachine" } |
    foreach {
        $ownerNodeInfo = Get-ClusterOwnerNode `
            -Cluster TT-HV02-FC `
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
Get-ClusterGroup -Cluster TT-HV02-FC |
    where { $_.GroupType -eq "VirtualMachine" } |
    foreach {
        $ownerNodeInfo = Get-ClusterOwnerNode -Cluster TT-HV02-FC -Group $_.Name

        If ($ownerNodeInfo.OwnerNodes.Length -gt 0)
        {
            $preferredOwner = $ownerNodeInfo.OwnerNodes[0].Name

            If ($_.OwnerNode -ne $preferredOwner)
            {
                Write-Verbose "Moving VM ($($_.Name)) to preferred owner ($preferredOwner)..."

                Move-ClusterVirtualMachineRole -Name $_.Name -Node $preferredOwner
            }
        }
    }
```

```PowerShell
cls
```

## # Virtual disk info

```PowerShell
Get-ClusterGroup -Cluster TT-HV02-FC  |
    where { $_.GroupType -eq "VirtualMachine" } |
    foreach {
        Get-VM -ComputerName $_.OwnerNode -Name $_.Name |
            Get-VMHardDiskDrive |
            Get-VHD -ComputerName $_.OwnerNode |
            select Path, @{N=’Size’; E={[Math]::Round(($_.Size / 1GB), 2) }}
    } | ft -auto
```

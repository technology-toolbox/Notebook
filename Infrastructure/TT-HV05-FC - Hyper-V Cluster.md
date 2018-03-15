# TT-HV05-FC - Hyper-V Cluster

Thursday, June 14, 2018
12:20 PM

```PowerShell
cls
```

## # Configure anti-affinitity

```PowerShell
Get-ClusterGroup -Cluster TT-HV05-FC |
    where { $_.GroupType -eq "VirtualMachine" } |
    select Name, AntiAffinityClassNames

Name                          AntiAffinityClassNames
----                          ----------------------
SCVMM BANSHEE Resources       {}
SCVMM CIPHER01 Resources      {}
SCVMM CON-DC1 Resources       {CON-DC}
SCVMM CON-DC2 Resources       {CON-DC}
SCVMM EXT-DC08 Resources      {}
SCVMM EXT-DC09 Resources      {}
SCVMM EXT-WAC02A Resources    {}
SCVMM FAB-ADFS02 Resources    {}
SCVMM FAB-DC01 Resources      {FAB-DC}
SCVMM FAB-DC02 Resources      {FAB-DC}
SCVMM FAB-FOOBAR4 Resources   {}
SCVMM FAB-WEB01 Resources     {}
SCVMM FOOBAR16 Resources      {}
SCVMM FOOBAR17 Resources      {}
SCVMM HAVOK-TEST Resources    {}
SCVMM MIMIC Resources         {}
SCVMM POLARIS Resources       {}
SCVMM TT-DEPLOY4 Resources    {}
SCVMM TT-SCOM03 Resources     {}
SCVMM TT-SQL02 Resources      {}
SCVMM TT-TFS02 Resources      {}
SCVMM TT-WIN10-DEV1 Resources {}
SCVMM TT-WSUS03 Resources     {}

$antiAffinityClassNames = New-Object System.Collections.Specialized.StringCollection
$antiAffinityClassNames.Add("EXT-DC")
(Get-ClusterGroup -Cluster TT-HV05-FC -Name 'SCVMM EXT-DC08 Resources').AntiAffinityClassNames = $antiAffinityClassNames

(Get-ClusterGroup -Cluster TT-HV05-FC -Name 'SCVMM EXT-DC09 Resources').AntiAffinityClassNames = $antiAffinityClassNames

Get-ClusterGroup -Cluster TT-HV05-FC |
    where { $_.GroupType -eq "VirtualMachine" } |
    select Name, AntiAffinityClassNames

Name                          AntiAffinityClassNames
----                          ----------------------
SCVMM BANSHEE Resources       {}
SCVMM CIPHER01 Resources      {}
SCVMM CON-DC1 Resources       {CON-DC}
SCVMM CON-DC2 Resources       {CON-DC}
SCVMM EXT-DC08 Resources      {EXT-DC}
SCVMM EXT-DC09 Resources      {EXT-DC}
SCVMM EXT-WAC02A Resources    {}
SCVMM FAB-ADFS02 Resources    {}
SCVMM FAB-DC01 Resources      {FAB-DC}
SCVMM FAB-DC02 Resources      {FAB-DC}
SCVMM FAB-FOOBAR4 Resources   {}
SCVMM FAB-WEB01 Resources     {}
SCVMM FOOBAR16 Resources      {}
SCVMM FOOBAR17 Resources      {}
SCVMM HAVOK-TEST Resources    {}
SCVMM MIMIC Resources         {}
SCVMM POLARIS Resources       {}
SCVMM TT-DEPLOY4 Resources    {}
SCVMM TT-SCOM03 Resources     {}
SCVMM TT-SQL02 Resources      {}
SCVMM TT-TFS02 Resources      {}
SCVMM TT-WIN10-DEV1 Resources {}
SCVMM TT-WSUS03 Resources     {}
```

```PowerShell
cls
```

## # "General" properties

### # Check preferred owners

```PowerShell
Get-ClusterGroup -Cluster TT-HV05-FC |
    where { $_.GroupType -eq "VirtualMachine" } |
    Get-ClusterOwnerNode

ClusterObject                 OwnerNodes
-------------                 ----------
SCVMM BANSHEE Resources       {}
SCVMM CIPHER01 Resources      {}
SCVMM CON-DC1 Resources       {TT-HV05A}
SCVMM CON-DC2 Resources       {TT-HV05B}
SCVMM EXT-DC08 Resources      {TT-HV05A}
SCVMM EXT-DC09 Resources      {TT-HV05B}
SCVMM EXT-WAC02A Resources    {}
SCVMM FAB-ADFS02 Resources    {}
SCVMM FAB-DC01 Resources      {TT-HV05A}
SCVMM FAB-DC02 Resources      {TT-HV05B}
SCVMM FAB-FOOBAR4 Resources   {}
SCVMM FAB-WEB01 Resources     {}
SCVMM FOOBAR16 Resources      {}
SCVMM FOOBAR17 Resources      {}
SCVMM HAVOK-TEST Resources    {TT-HV05C}
SCVMM MIMIC Resources         {}
SCVMM POLARIS Resources       {}
SCVMM TT-DEPLOY4 Resources    {}
SCVMM TT-SCOM03 Resources     {}
SCVMM TT-SQL02 Resources      {TT-HV05C}
SCVMM TT-TFS02 Resources      {TT-HV05B}
SCVMM TT-WIN10-DEV1 Resources {}
SCVMM TT-WSUS03 Resources     {}
```

```PowerShell
cls
```

### # Check priority of each VM

```PowerShell
Get-ClusterGroup -Cluster TT-HV05-FC |
    where { $_.GroupType -eq "VirtualMachine" } |
    select Name, Priority |
    Format-Table -Auto

Name                          Priority
----                          --------
SCVMM BANSHEE Resources           2000
SCVMM CIPHER01 Resources          3000
SCVMM CON-DC1 Resources           1000
SCVMM CON-DC2 Resources           1000
SCVMM EXT-DC08 Resources          3000
SCVMM EXT-DC09 Resources          2000
SCVMM EXT-WAC02A Resources        1000
SCVMM FAB-ADFS02 Resources        1000
SCVMM FAB-DC01 Resources          2000
SCVMM FAB-DC02 Resources          1000
SCVMM FAB-FOOBAR4 Resources       2000
SCVMM FAB-WEB01 Resources         1000
SCVMM FOOBAR16 Resources          2000
SCVMM FOOBAR17 Resources          2000
SCVMM HAVOK-TEST Resources        1000
SCVMM MIMIC Resources             2000
SCVMM POLARIS Resources           2000
SCVMM TT-DEPLOY4 Resources        1000
SCVMM TT-SCOM03 Resources         2000
SCVMM TT-SQL02 Resources          3000
SCVMM TT-TFS02 Resources          2000
SCVMM TT-WIN10-DEV1 Resources     1000
SCVMM TT-WSUS03 Resources         2000
```

```PowerShell
cls
```

## # "Failover" properties

### # Configure failback options

```PowerShell
Get-ClusterGroup -Cluster TT-HV05-FC |
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
Get-ClusterGroup -Cluster TT-HV05-FC |
    where { $_.GroupType -eq "VirtualMachine" } |
    select Name, AutoFailbackType, FailbackWindowStart, FailbackWindowEnd

Name                          AutoFailbackType FailbackWindowStart FailbackWindowEnd
----                          ---------------- ------------------- -----------------
SCVMM BANSHEE Resources                      1                  21                 0
SCVMM CIPHER01 Resources                     1                  21                 0
SCVMM CON-DC1 Resources                      1                  21                 0
SCVMM CON-DC2 Resources                      1                  21                 0
SCVMM EXT-DC08 Resources                     1                  21                 0
SCVMM EXT-DC09 Resources                     1                  21                 0
SCVMM EXT-WAC02A Resources                   1                  21                 0
SCVMM FAB-ADFS02 Resources                   1                  21                 0
SCVMM FAB-DC01 Resources                     1                  21                 0
SCVMM FAB-DC02 Resources                     1                  21                 0
SCVMM FAB-FOOBAR4 Resources                  1                  21                 0
SCVMM FAB-WEB01 Resources                    1                  21                 0
SCVMM FOOBAR16 Resources                     1                  21                 0
SCVMM FOOBAR17 Resources                     1                  21                 0
SCVMM HAVOK-TEST Resources                   1                  21                 0
SCVMM MIMIC Resources                        1                  21                 0
SCVMM POLARIS Resources                      1                  21                 0
SCVMM TT-DEPLOY4 Resources                   1                  21                 0
SCVMM TT-SCOM03 Resources                    1                  21                 0
SCVMM TT-SQL02 Resources                     1                  21                 0
SCVMM TT-TFS02 Resources                     1                  21                 0
SCVMM TT-WIN10-DEV1 Resources                1                  21                 0
SCVMM TT-WSUS03 Resources                    1                  21                 0
```

```PowerShell
cls
```

### # Verify VMs are running on preferred owner

```PowerShell
Get-ClusterGroup -Cluster TT-HV05-FC -Verbose:$false |
    where { $_.GroupType -eq "VirtualMachine" } |
    foreach {
        $ownerNodeInfo = Get-ClusterOwnerNode `
            -Cluster TT-HV05-FC `
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
$clusterName = "TT-HV05-FC"

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
Get-ClusterGroup -Cluster TT-HV05-FC |
    where { $_.GroupType -eq "VirtualMachine" } |
    foreach {
        Get-VM -ComputerName $_.OwnerNode -Name $_.Name |
            Get-VMHardDiskDrive |
            Get-VHD -ComputerName $_.OwnerNode |
            select Path, @{N=’Size’; E={[Math]::Round(($_.Size / 1GB), 2) }}
    } | ft -auto
```

# Windows Update Clean Up

Friday, July 14, 2017\
4:07 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

---

**EXT-DC10** - Run as domain administrator

```PowerShell
cls
```

## # Clean up Windows Update files on all domain computers

```PowerShell
$script = @"
Param(
    [Parameter(Position = 1, Mandatory = `$true, ValueFromPipeline = `$true)]
    [String] `$ComputerName)

Process {
    Invoke-Command -ComputerName `$ComputerName -ScriptBlock {
        Stop-Service wuauserv

        Remove-Item C:\Windows\SoftwareDistribution -Recurse

        Start-Service wuauserv
    }
}
"@

$tempFileName = [System.IO.Path]::GetTempFileName()
$tempFileName = $tempFileName.Replace(".tmp", ".ps1")

Set-Content -Path $tempFileName -Value ($script -replace "`n", "`r`n")

$computersToExclude = @(
    'EXT-SQL01',       # SQL Server failover cluster
    'EXT-SQL01-FC'     # SQL Server failover cluster
    'EXT-SEQ02',       # Ubuntu server
    'EXT-UD20-DEV-01'  # Ubuntu server
    )

$computers = Get-ADComputer -Filter * |
    where { $_.Name -notin $computersToExclude } |
    sort Name |
    select -ExpandProperty Name

$computers |
    C:\NotBackedUp\Public\Toolbox\PowerShell\Run-CommandMultiThreaded.ps1 `
        -Command $tempFileName `
        -InputParam ComputerName `
        -MaxThreads 5

Remove-Item -Path $tempFileName
```

---

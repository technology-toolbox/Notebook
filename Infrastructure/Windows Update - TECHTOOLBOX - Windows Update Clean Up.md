# Windows Update Clean Up

Friday, July 14, 2017
4:07 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

---

**FOOBAR16**

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

$computers = Get-ADComputer -Filter * |
    where { $_.Name -notin
        @('BANSHEE',
            'SQL2014-DEV',
            'TFS2015-DEV',
            'TT-HV02-FC',
            'TT-SOFS01',
            'TT-SOFS01-FC',
            'TT-SQL01',
            'TT-SQL01-FC',
            'TT-VMM01',
            'TT-VMM01-FC') } |
    select -ExpandProperty Name

$computers |
    C:\NotBackedUp\Public\Toolbox\PowerShell\Run-CommandMultiThreaded.ps1 `
        -Command $tempFileName `
        -InputParam ComputerName `
        -MaxThreads 5

Remove-Item -Path $tempFileName
```

---

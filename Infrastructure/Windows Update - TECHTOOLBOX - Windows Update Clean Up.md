# Windows Update Clean Up

Friday, July 14, 2017
4:07 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

---

**FOOBAR10**

```PowerShell
cls
```

## # Clean up Windows Update files on all domain computers

```PowerShell
$script = "
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse

Start-Service wuauserv
"

$scriptBlock = [ScriptBlock]::Create($script)

$computers = Get-ADComputer -Filter * |
    Where-Object { $_.Name -notin
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
    select Name

$computers | ForEach-Object {
    $computer = $_.Name

    Write-Host "Cleaning up Windows Update files ($computer)..."

    Invoke-Command -ComputerName $computer -ScriptBlock $scriptBlock
}
```

---

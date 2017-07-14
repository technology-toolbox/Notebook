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
        @('EXCHANGE-CAS') } |
    select Name

$computers | ForEach-Object {
    $computer = $_.Name

    Write-Host "Cleaning up Windows Update files ($computer)..."

    Invoke-Command -ComputerName $computer -ScriptBlock $scriptBlock
}
```

---

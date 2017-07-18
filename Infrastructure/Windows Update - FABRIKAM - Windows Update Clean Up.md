# Windows Update Clean Up

Friday, July 14, 2017
4:07 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

---

**FAB-DC01**

```PowerShell
cls
```

## # Clean up Windows Update files on all domain computers

```PowerShell
$script = @"
Stop-Service wuauserv

Remove-Item C:\Windows\SoftwareDistribution -Recurse

Start-Service wuauserv
"@

$tempFileName = [System.IO.Path]::GetTempFileName()
$tempFileName = $tempFileName.Replace(".tmp", ".ps1")

Set-Content -Path $tempFileName -Value ($script -replace "`n", "`r`n")

$computers = Get-ADComputer -Filter * |
    Where-Object { $_.Name -notin @('EXCHANGE-CAS') } |
    select Name

$computers |
    C:\NotBackedUp\Public\Toolbox\PowerShell\Run-CommandMultiThreaded.ps1 `
        -Command $tempFileName `
        -MaxThreads 5

Remove-Item -Path $tempFileName
```

---

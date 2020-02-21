# Update Baseline Images

Tuesday, June 12, 2018
8:14 AM

## Build baseline images

---

**TT-HV02A** / **TT-HV02B** / **TT-HV02C**

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows 7 Ultimate (x86) - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\TT-FS01\Products\Microsoft\MDT-Build-x86.iso `
    -SwitchName "Embedded Team Switch" `
    -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows 7 Ultimate (x64) - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\TT-FS01\Products\Microsoft\MDT-Build-x86.iso `
    -SwitchName "Embedded Team Switch" `
    -VhdSize 40GB `
    -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows Server 2008 R2 - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\TT-FS01\Products\Microsoft\MDT-Build-x86.iso `
    -SwitchName "Embedded Team Switch" `
    -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows 8.1 Enterprise (x64) - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\TT-FS01\Products\Microsoft\MDT-Build-x86.iso `
    -SwitchName "Embedded Team Switch" `
    -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows Server 2012 R2 Standard - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\TT-FS01\Products\Microsoft\MDT-Build-x86.iso `
    -SwitchName "Embedded Team Switch" `
    -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image - "SharePoint Server 2013 - Development"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\TT-FS01\Products\Microsoft\MDT-Build-x86.iso `
    -SwitchName "Embedded Team Switch" `
    -VhdSize 60GB `
    -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows 10 Enterprise (x64) - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\TT-FS01\Products\Microsoft\MDT-Build-x86.iso `
    -SwitchName "Embedded Team Switch" `
    -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows Server 2016 - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\TT-FS01\Products\Microsoft\MDT-Build-x86.iso `
    -SwitchName "Embedded Team Switch" `
    -Force
```

```PowerShell
cls
```

### # Create temporary VM to build image - "Windows Server 2019 - Baseline"

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Create Temporary VM.ps1' `
    -IsoPath \\TT-FS01\Products\Microsoft\MDT-Build-x86.iso `
    -SwitchName "Embedded Team Switch" `
    -Force
```

---

## Update MDT production deployment images

---

**WOLVERINE - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
Push-Location C:\NotBackedUp\techtoolbox\Infrastructure\Main\Scripts

& '.\Update Deployment Images.ps1'

Pop-Location
```

---

# CONTOSO-DC2

Thursday, January 14, 2016
1:49 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create virtual machine (CONTOSO-DC2)

```PowerShell
$vmHost = "FORGE"

$vmName = "CONTOSO-DC2"

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path C:\NotBackedUp\VMs `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 2GB `
    -SwitchName "Virtual LAN 2 - 192.168.10.x"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -ProcessorCount 2 `
    -StaticMemory

Set-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path \\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso

Start-VM -ComputerName $vmHost -Name $vmName
```

---

## Install custom Windows Server 2008 R2 image

- Start-up disk: [\\\\ICEMAN\\Products\\Microsoft\\MDT-Deploy-x86.iso](\\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso)
- On the **Task Sequence** step, select **Windows Server 2008 R2** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **CONTOSO-DC2**.
  - Select **Join a workgroup**.
  - In the **Workgroup** box, type **WORKGROUP**.
  - Click **Next**.
- On the Applications step:
  - Click **Next**.

```PowerShell
cls
```

## # Rename local Administrator account and set password

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

$password = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

**Note:** When prompted for the secure string, type the password for the Administrator account.

```PowerShell
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

$adminUser = [ADSI] 'WinNT://./Administrator,User'
$adminUser.Rename('foo')
$adminUser.SetPassword($plainPassword)
```

### # Configure local Administrator account to require a password and then logoff

```PowerShell
net user foo /passwordreq:yes

logoff
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Remove disk from virtual CD/DVD drive

```PowerShell
$vmHost = "FORGE"

$vmName = "CONTOSO-DC2"

Set-VMDvdDrive -ComputerName $vmHost -VMName $vmName -Path $null
```

---

```PowerShell
cls
```

## # Change drive letter for DVD-ROM

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
```

```PowerShell
cls
```

## # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

## # Configure firewall rules for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
# Note: New-NetFirewallRule is not available on Windows Server 2008 R2

netsh advfirewall firewall add rule `
    name="Remote Windows Update (Dynamic RPC)" `
    description="Allows remote auditing and installation of Windows updates via POSHPAIG (http://poshpaig.codeplex.com/)" `
    program="%windir%\system32\dllhost.exe" `
    dir=in `
    protocol=TCP `
    localport=RPC `
    profile=Domain `
    action=Allow
```

## # Disable firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
netsh advfirewall firewall set rule `
    name="Remote Windows Update (Dynamic RPC)" new enable=no
```

```PowerShell
cls
```

## # Configure network settings

### # Configure static IP addresses

```PowerShell
netsh interface ipv4 set address `
    name="Local Area Connection" `
    source=static `
    address=192.168.10.222 `
    mask=255.255.255.0 `
    gateway=192.168.10.1

netsh interface ipv6 set address `
    interface="Local Area Connection" `
    address=2601:282:4201:e500::222
```

### # Configure DNS servers

```PowerShell
netsh interface ipv4 add dnsservers `
    name="Local Area Connection" `
    address=192.168.10.221

netsh interface ipv6 add dnsservers `
    name="Local Area Connection" `
    address=2601:282:4201:e500::221
```

```PowerShell
cls
```

## # Promote to domain controller

```PowerShell
dcpromo
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4C/29B482F4835FB19446739FF94C95EEEE72928A4C.png)

Click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A6/6B3B31D6DF11F9B6FB77A9B91C7AF8ACA48310A6.png)

 Click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E5/57C9CF5481475CB6F9FE461610651E98BEFA70E5.png)

Select **Existing forest** and then select **Add a domain controller to an existing domain**.\
Click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5C/EA516F501D1E086E377776EEEA74A375B89B7F5C.png)

Click **Set**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B6/42CF8D2322FB243B3764A2935DF229B3EC03F5B6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/50/96CD106D9C7223F7AFDB9F2F4CADA7B45C205A50.png)

Click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A2/10AFF5E948CCD253FAFEA9B857A8A3C01BDC6BA2.png)

Click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/44/EA64370113A56DC81F0CB7687DC7FCC1EA663944.png)

Click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/97/EB4069F5CD07B320E1AC0493470A0D08FA6FA197.png)

Ensure **DNS server** and **Global catalog** are selected and click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/10/776A13A62D3B5FE44D6379951CF4528455E22510.png)

Click **Yes**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9D/E99545ED6811AE122069C982846E3F74E4BDB29D.png)

Click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0E/D3D79E8E6471B03D6F1DA4E19C7EF85DD2415C0E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DB/297557706DA340D2E6EB3AE312E27F6B6E005BDB.png)

Click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5D/2714BDF4A95F044B28B89DAEE9AE7E71F3D7CC5D.png)

Select **Reboot on completion**.

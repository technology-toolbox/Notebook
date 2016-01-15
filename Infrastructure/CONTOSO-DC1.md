# CONTOSO-DC1

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

### # Create virtual machine (CONTOSO-DC1)

```PowerShell
$vmHost = "FORGE"

$vmName = "CONTOSO-DC1"

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
  - In the **Computer name** box, type **CONTOSO-DC1**.
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

$vmName = "CONTOSO-DC1"

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
    address=192.168.10.221 `
    mask=255.255.255.0 `
    gateway=192.168.10.1

netsh interface ipv6 set address `
    interface="Local Area Connection" `
    address=2601:282:4201:e500::221
```

```PowerShell
cls
```

## # Promote to domain controller

```PowerShell
dcpromo
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/11/3C1B4C1B6B8EE02C91C584B8B800CA2A487FDE11.png)

Select **Use advanced mode installation**.\
Click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F5/CCBE954418E58868007D48C55BD2852C2158D3F5.png)

Click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D9/C4B73C1F6846E7A8F1E852494D23772F158821D9.png)

Select **Create a new domain in a new forest**.\
Click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/66/653202A4DBE10283CE36A12C70E0FF40D730BD66.png)

Click **OK**.

```Console
net user foo /passwordreq:yes
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/79/D051E1FF68709560B81339855898EB3D55027679.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/59/09231DB07407B9347F0F5E43D1AB24B402366459.png)

In the **FQDN of the forest root domain** box, type **corp.contoso.com**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/75/F0A36760812CB3B72AD8C8FCFDC618B86F7C4475.png)

In the **Domain NetBIOS name** box, type **CONTOSO**.\
Click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5D/512C683AD8BB13CF33C96630341EA6BC9DE29D5D.png)

In the **Forest functional level** dropdown list, select **Windows Server 2008 R2**.\
Click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/98/CBEE442A958B3C02508681860922862808E7E698.png)

Ensure **DNS server** is selected.\
Click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7E/F70E9769BBEC5879DDFF0AA047698A29090D857E.png)

Click **Yes**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3F/4510472DB1EAA570BE95B2FD0D18FBDA1443103F.png)

Click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D6/7FB4BC9197CA92503C0FD54AF96853D995050BD6.png)

Type the password and click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6C/FD4C40FC68486D884243D8412210E5F0CA802E6C.png)

Click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/62/65763518385C7044BEEAC7DECE4C19E7D691C662.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/51/07FF838F2E57630C0909E972339F4E2756E84E51.png)

Click **Finish**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/81/D05F8E1F463556560286D8A005F3EAA3FED09281.png)

Click **Restart Now**.

```PowerShell
cls
```

## # Promote CONTOSO-DC2 to domain controller

```PowerShell
cls
```

## # Configure DNS servers

```PowerShell
netsh interface ipv4 add dnsservers `
    name="Local Area Connection" `
    address=192.168.10.222 `
    index=1

netsh interface ipv6 add dnsservers `
    name="Local Area Connection" `
    address=2601:282:4201:e500::222 `
    index=1
```

## # Import DNS zone - us.pinkertons.com

```PowerShell
robocopy \\ICEMAN\Archive\Clients\Securitas\DNS C:\NotBackedUp\Temp\DNS /E
```

### Attempt 1 (failed)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/54/F54C738623E742110987946D46C8619E752DF454.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F9/D2059EC24ECF0DE9E68D1A6B881AACEDDCD4C9F9.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/76/74225F11812B7972BDF266074448D39434AB4A76.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DE/3AD512454D4044F2F56F3DEAC79C55C5DA6581DE.png)

Right-click **us.pinkertons.com** and click **Properties**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/72/5C7FA88C6CDA98163A70FB021997295BB7345B72.png)

Click the **Change...** button next to **Type: Active Directory-Integrated**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/81/EF60BE66EC4A0E296D7A143BD9B3E566DBC2EC81.png)

Clear the checkbox -- **Store the zone in Active Directory (available on if DNS server is a domain controller)**\
Click **OK**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1B/1782D28E8BC6DAD54F2BBEE7C7D675299FC60D1B.png)

Click **Yes**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AC/BBF11A54FD2EEF8DA4A381B7D52B219A4C882BAC.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/77/6FEC8466FE51F2E17FC85E1513EC4E0204702177.png)

### Attempt 2

```Console
copy \NotBackedUp\Temp\DNS\PNKUS.txt C:\Windows\System32\dns\us.pinkertons.com.dns
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/90/327F0A7B1E6037EF04B88A9F3641B25F2204FB90.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/25/A7E22799132E9AD5BCF4093E65D3758560568A25.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9D/68FFA0FA3863F8D8176F9ED99F61D11883E5B39D.png)

Clear the checkbox -- **Store the zone in Active Directory (available on if DNS server is a writeable domain controller)**\
Click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/61/3BBAC30C82D998A8041958EA618754B607666A61.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E5/5DDCEF1D0E55FACC7046FB7593F888E19D7102E5.png)

Select **Use this existing file**.\
Click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/78/FEE930A22E573799D1BC1742AA990CD6B5820F78.png)

Click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4F/F9883983E9969C903834D393FE6801C0AF83184F.png)

Click **Finish**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/59/0ACA7ACE33CACF1AC865622F5BEE009DC033B059.png)

#### Change DNS zone to AD integrated

![(screenshot)](https://assets.technologytoolbox.com/screenshots/21/892443746D2415CF4FB9DC1001A92BF3C7832D21.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A7/A44B9C201F4033ED6A48153A1E25B202969907A7.png)

#### "Sniff" the network to see if DC lookup is generating the expected traffic...

```Console
nltest /DSGETDC:us.pinkertons.com
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AF/6094C262E99343D86335A75B3948E78DF119BBAF.png)

Yep, it's trying to communicate with 10.1.16.117 using LDAP...success.

Function Remove-DnsServerResourceRecord(\
\$ZoneName,\
\$Name,\
\$RRType,\
\$ComputerName = ".")\
{\
    \$cmd = "dnscmd \$ComputerName /RecordDelete \$ZoneName \$Name \$RRType" 

    Write-Host "cmd: \$cmd"
    #Invoke-Expression \$cmd\
}

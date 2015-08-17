# FAB-WEB01- Windows Server 2012 R2

Thursday, May 28, 2015
6:10 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Create VM

- Processors: **2**
- Memory: **2 GB**
- VHD size (GB): **32**
- VHD file name:** FAB-WEB01**
- Virtual DVD drive:
  - **Existing ISO image**
  - **[\\\\ICEMAN\\Products\\Microsoft\\MDT-Deploy-x86.iso](\\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso)**
  - **Share file instead of copying it**
- Network Adapter 1:
  - **Connected to a VM network**
  - VM network: **Virtual LAN 2 - 192.168.10.x**
- Automatic actions:
  - **Turn on the virtual machine if it was running when the physical server stopped**
  - Delay startup (seconds): **90**

## Install custom Windows Server 2012 R2 image

- On the **Task Sequence** step, select **Windows Server 2012 R2** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **FAB-WEB01**.
  - Select **Join a workgroup**.
  - In the **Workgroup** box, type **WORKGROUP**.
  - Click **Next**.
- On the **Applications** step, do not select any applications, and click **Next**.

```PowerShell
cls
```

## # Set password for local Administrator account

```PowerShell
$adminUser = [ADSI] "WinNT://./Administrator,User"
$adminUser.SetPassword("{password}")
```

```PowerShell
cls
```

## # Rename network connection

```PowerShell
Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "LAN 1 - 192.168.10.x"
```

## # Enable jumbo frames

```PowerShell
Set-NetAdapterAdvancedProperty `
    -Name "LAN 1 - 192.168.10.x" `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping ICEMAN -f -l 8900
```

```PowerShell
cls
```

## # Configure DNS servers

### # Configure IPv4 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -ServerAddresses 192.168.10.201,192.168.10.202
```

### # Configure IPv6 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -ServerAddresses 2601:1:8200:6000::201,2601:1:8200:6000::202
```

## # Join server to domain

```PowerShell
Add-Computer -DomainName corp.fabrikam.com -Restart
```

```PowerShell
cls
```

## # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
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

## # Install IIS server role

```PowerShell
Install-WindowsFeature `
    -Name Web-Server, Web-Scripting-Tools, NET-Framework-45-ASPNET, Web-Asp-Net45 `
    -IncludeManagementTools
```

## Install SQL Server 2012 Express LocalDB

```PowerShell
net use \\ICEMAN\ipc$ /USER:TECHTOOLBOX\jjameson

& '\\ICEMAN\Products\Microsoft\SQL Server 2012\LocalDB\x64\SqlLocalDB.MSI'
```

## Install ASP.NET MVC 4

```PowerShell
& '\\ICEMAN\Public\Download\Microsoft\dotNet\ASP.NET MVC 4 for Visual Studio 2010 SP1\AspNetMVC4Setup.exe'
```

## Install Fabrikam Fiber application

## # Configure application pool for Fabrikam website

```PowerShell
Import-Module WebAdministration

$appPool = New-Item "IIS:\AppPools\FabrikamAppPool"

$appPool.enable32BitAppOnWin64 = $true
$appPool.processModel.loadUserProfile = $true
$appPool | Set-Item

Set-ItemProperty -Path IIS:\Sites\Fabrikam -Name ApplicationPool -Value FabrikamAppPool
```

## # Configure permissions on App_Data folder

```PowerShell
$appDataPath = (Get-Item IIS:\\Sites\Fabrikam).physicalPath + "App_Data"
$appPoolIdentity = "IIS APPPOOL\FabrikamAppPool"

icacls $appDataPath /grant ($appPoolIdentity + ":(OI)(CI)(M)") | Out-Default
```

```PowerShell
cls
```

## # Enter a product key and activate Windows

```PowerShell
slmgr /ipk {product key}
```

**Note:** When notified that the product key was set successfully, click **OK**.

```Console
slmgr /ato
```

## # Configure firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

---

**FOOBAR8**

```PowerShell
$cred = Get-Credential FABRIKAM\jjameson-admin

$computer = 'FAB-WEB01.corp.fabrikam.com'

$command = "New-NetFirewallRule ``
    -Name 'Remote Windows Update (Dynamic RPC)' ``
    -DisplayName 'Remote Windows Update (Dynamic RPC)' ``
    -Description 'Allows remote auditing and installation of Windows updates via POSHPAIG (http://poshpaig.codeplex.com/)' ``
    -Group 'Technology Toolbox (Custom)' ``
    -Program '%windir%\system32\dllhost.exe' ``
    -Direction Inbound ``
    -Protocol TCP ``
    -LocalPort RPC ``
    -Profile Domain ``
    -Action Allow"

$scriptBlock = [scriptblock]::Create($command)

Invoke-Command -ComputerName $computer -Credential $cred -ScriptBlock $scriptBlock
```

---

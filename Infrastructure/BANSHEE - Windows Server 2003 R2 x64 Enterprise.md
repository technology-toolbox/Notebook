# BANSHEE - Windows Server 2003 R2 x64 Enterprise

Friday, February 14, 2014
9:22 AM

```Console
12345678901234567890123456789012345678901234567890123456789012345678901234567890

PowerShell
```

## # Create virtual machine

```PowerShell
$vmName = "BANSHEE"

New-VM `
    -Name $vmName `
    -Path C:\NotBackedUp\VMs `
    -MemoryStartupBytes 512MB `
    -SwitchName "Virtual LAN 2 - 192.168.10.x"

Set-VMMemory `
    -VMName $vmName `
    -DynamicMemoryEnabled $true `-MinimumBytes 128MB `
    -MaximumBytes 1024MB

$sysPrepedImage =
    "\\iceman\VHD Library\WS2003-R2-X64-ENT.vhdx"

mkdir "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks"

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

Copy-Item -Path $sysPrepedImage -Destination $vhdPath

Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath

Start-VM $vmName
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/29/D82D2F58075A6E7A4C92CAB5077A399285E41429.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0F/18CFA0F2AEB71EF715E78359FD22C187C38F400F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E1/D9B77AED760465AB0230AFF7F3D639C96F9CA9E1.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A3/5CA57ACAD746E8433A751C4E6C5709F365E94FA3.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/32/E44CDC2E6475EF56C2964521F1AD89B8EB67DE32.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/92/8139BEF13C3D8E228027826046469C7F7F65A792.png)

## Add mail server role

Mount the Windows Server 2003 R2 with Service Pack 2 ISO image.

On the **Manage Your Server** page, in the **Adding Roles to Your Server** section, click **Add or remove a role**.

In the **Configure Your Server Wizard** window:

1. On the **Preliminary Steps** page, click **Next**.
2. On the **Server Role** page, in the list of server roles, click **Mail server (POP3, SMTP)** and then click **Next**.
3. On the Configure POP3 Service page:
   1. In the **Authentication method** dropdown, select **Active Directory-Integrated**.
   2. In the **E-mail domain name** box, type **technologytoolbox.com**.
   3. Click **Next**.
4. On the **Summary of Selections** page, click **Next**.
5. When notified that this server is now a mail server, click **Finish**.

## Configure SMTP server

In the **Authentication** window, select both **Anonymous access** and **Integrated Windows Authentication** and then click **OK**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4F/928BB1B4484FA3ACD24CCA2045856EA408D89A4F.png)

In the **Outbound Security** window:

1. Select **Integrated Windows Authentication** and specify the credentials for the mail service account.
2. Click **OK**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1F/097125F6759D5366927EED3FEFD5E6901C6DAB1F.png)

In the **Advanced Delivery** window:

1. In the **Smart host** box, type **smarthost.technologytoolbox.com**.
2. Click **OK**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/84/17DC4D37ADFD4E5CF31758EBA134629657DF4584.png)

## Add mailboxes

## Install SCOM agent

Mount the SCOM 2012 R2 ISO image:

[\\\\iceman\\Products\\Microsoft\\System Center 2012 R2\\](\\iceman\Products\Microsoft\System Center 2012 R2\)en_system_center_2012_r2_operations_manager_x86_and_x64_dvd_2920299.iso

### REM Install MSXML 6.0 Parser and SDK (prerequisite for SCCOM agent)

```Console
D:\msxml\amd64\msxml6.msi
```

### REM Install Microsoft Monitoring Agent

```Console
msiexec.exe /i D:\agent\AMD64\MOMAgent.msi ^
MANAGEMENT_GROUP=HQ ^
MANAGEMENT_SERVER_DNS=JUBILEE ^
ACTIONS_USE_COMPUTER_ACCOUNT=1
```

## Approve manual agent install in Operations Manager

## Troubleshoot e-mail issues with Fabrikam Exchange Server

### NetMon filter

```Text
!(Tcp.port == 3389) and !(Tcp.port == 1494) and !(Tcp.port == 1503)
AND !(Destination == "[*BROADCAST [FF-FF-FF-FF-FF-FF]]")
AND !(ProtocolName == "ARP")
AND !(ProtocolName == "BROWSER")
AND !(ProtocolName == "ICMPv6")
AND !(ProtocolName == "IGMP")
AND !(ProtocolName == "LLMNR")
AND !(ProtocolName == "NbtNs")
AND !(ProtocolName == "SMB")
AND !(ProtocolName == "SSDP")
```

### Update SMTP server configuration

In the **Outbound Security** window, select **Anonymous access**. (When **Integrated Windows Authentication** was selected, BANSHEE would attempt to authenticate with FAB-EX01 using the TECHTOOLBOX\\svc-mail account -- which obviously doesn't work.)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/55/125E12DCA7A5C6524DE85FC915133EB5099D9E55.png)

In the **Advanced Delivery** window, clear the **Smart host** box (since **smarthost.technologytoolbox.com** is no longer used).

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CF/7F26F2FC904B232A87A81A101A239AD692EF77CF.png)

## Convert BANSHEE to test SMTP server

### Disable relay e-mail

![(screenshot)](https://assets.technologytoolbox.com/screenshots/12/DE6F627F9344E9272A223D51852E694F01F66112.png)

On the **Default SMTP Virtual Server Properties** window:

1. Click **Relay...**
2. On the **Relay Restrictions** window, clear the checkbox for **Allow all computers which successfully authenticate to relay, regardless of the list above** and click **OK**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CA/0AAE7E4E85AA9E696F9AA63149A0EDB9B7E64BCA.png)

## Upgrade to System Center Operations Manager 2016

### Uninstall SCOM 2012 R2 agent

```Console
msiexec /x {786970C5-E6F6-4A41-B238-AE25D4B91EEA}
```

Restart the server

### Install SCOM 2016 agent

> **Note**
>
> Installing the SCOM agent using the Operations Console results in an error (presumably due to Windows Server 2003):
>
> From agent install log:
>
> ```Text
> MSI (s) (7C:9C) [08:16:29:147]: Windows Installer installed the product. Product Name: Microsoft Monitoring Agent. Product Version: 8.0.10918.0. Product Language: 0. Installation success or error status: 1603.
> ```

```Console
msiexec.exe /i "\\TT-FS01\Products\Microsoft\System Center 2016\Agents\SCOM\AMD64\MOMAgent.msi" MANAGEMENT_GROUP=HQ MANAGEMENT_SERVER_DNS=TT-SCOM01 ACTIONS_USE_COMPUTER_ACCOUNT=1
```

Yep, SCOM 2016 agent is not supported on Windows Server 2003:

This product must be installed on Windows Vista SP2, Windows Server 2008 SP2, or later.

### Reinstall SCOM 2012 R2 agent

---

**TT-VMM01A**

```PowerShell
cls
```

#### # Insert SCOM 2012 R2 installation media

```PowerShell
$vmName = "BANSHEE"
$isoName = "en_system_center_2012_r2_operations_manager_x86_and_x64_dvd_2920299.iso"

$dvdDrive = Get-SCVirtualDVDDrive -VM $vmName

$iso = Get-SCISO | where {$_.Name -eq $isoName}

Set-SCVirtualDVDDrive -VirtualDVDDrive $dvdDrive -ISO $iso -Link
```

---

#### REM Install Microsoft Monitoring Agent

```Console
msiexec.exe /i D:\agent\AMD64\MOMAgent.msi ^
MANAGEMENT_GROUP=HQ ^
MANAGEMENT_SERVER_DNS=TT-SCOM01 ^
ACTIONS_USE_COMPUTER_ACCOUNT=1
```

---

**TT-VMM01A**

```PowerShell
cls
```

#### # Remove SCOM 2012 R2 installation media

```PowerShell
$vmName = "BANSHEE"

$dvdDrive = Get-SCVirtualDVDDrive -VM $vmName

Set-SCVirtualDVDDrive -VirtualDVDDrive $dvdDrive -NoMedia
```

---

### Approve manual agent install in Operations Manager

---

**FOOBAR11 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Configure static IP address using VMM

```PowerShell
$vmName = "BANSHEE"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Management VM Network"
$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"
$ipPool = Get-SCStaticIPAddressPool -Name "Management Address Pool"

Stop-SCVirtualMachine $vmName

$macAddress = Grant-SCMACAddress `
    -MACAddressPool $macAddressPool `
    -Description $vmName `
    -VirtualNetworkAdapter $networkAdapter

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -MACAddressType Static `
    -MACAddress $macAddress

$ipAddress = Grant-SCIPAddress `
    -GrantToObjectType VirtualNetworkAdapter `
    -GrantToObjectID $networkAdapter.ID `
    -StaticIPAddressPool $ipPool `
    -Description $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -IPv4AddressType Static `
    -IPv4Addresses $IPAddress.Address

Start-SCVirtualMachine $vmName
```

---

---

**FOOBAR11**

```PowerShell
cls
```

## # Make virtual machine highly available

### # Migrate VM to shared storage

```PowerShell
$vmName = "BANSHEE"

$vm = Get-SCVirtualMachine -Name $vmName
$vmHost = $vm.VMHost

Move-SCVirtualMachine `
    -VM $vm `
    -VMHost $vmHost `
    -HighlyAvailable $true `
    -Path "\\TT-SOFS01.corp.technologytoolbox.com\VM-Storage-Silver" `
    -UseDiffDiskOptimization
```

### # Allow migration to host with different processor version

```PowerShell
Stop-SCVirtualMachine -VM $vmName

Set-SCVirtualMachine -VM $vmName -CPULimitForMigration $true

Start-SCVirtualMachine -VM $vmName
```

---

## Rebuild System Center Operations Manager 2016 server

### Uninstall SCOM 2012 R2 agent

```Console
msiexec /x {786970C5-E6F6-4A41-B238-AE25D4B91EEA}
```

Restart the server

### Install SCOM 2012 R2 agent

---

**FOOBAR11**

```PowerShell
cls
```

#### # Insert SCOM 2012 R2 installation media

```PowerShell
$vmName = "BANSHEE"
$isoName = "en_system_center_2012_r2_operations_manager_x86_and_x64_dvd_2920299.iso"

$dvdDrive = Get-SCVirtualDVDDrive -VM $vmName

$iso = Get-SCISO | where {$_.Name -eq $isoName}

Set-SCVirtualDVDDrive -VirtualDVDDrive $dvdDrive -ISO $iso -Link
```

---

#### REM Install Microsoft Monitoring Agent

```Console
msiexec.exe /i D:\agent\AMD64\MOMAgent.msi ^
  MANAGEMENT_GROUP=HQ ^
  MANAGEMENT_SERVER_DNS=TT-SCOM03 ^
  ACTIONS_USE_COMPUTER_ACCOUNT=1
```

---

**TT-VMM01A**

```PowerShell
cls
```

#### # Remove SCOM 2012 R2 installation media

```PowerShell
$vmName = "BANSHEE"

$dvdDrive = Get-SCVirtualDVDDrive -VM $vmName

Set-SCVirtualDVDDrive -VirtualDVDDrive $dvdDrive -NoMedia
```

---

### Approve manual agent install in Operations Manager

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Move VM to new Production VM network

```PowerShell
$vmName = "BANSHEE"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Production VM Network"
$ipAddressPool = Get-SCStaticIPAddressPool -Name "Production-15 Address Pool"

Stop-SCVirtualMachine $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -IPv4AddressPools $ipAddressPool `
    -IPv4AddressType Static

Start-SCVirtualMachine $vmName
```

---

---

**FOOBAR16 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

## # Move VM to new Management VM network

```PowerShell
$vmName = "BANSHEE"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Management VM Network"
$ipPool = Get-SCStaticIPAddressPool -Name "Management Address Pool"

Stop-SCVirtualMachine $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -IPv4AddressPools $ipPool `
    -IPv4AddressType Static

Start-SCVirtualMachine $vmName
```

---

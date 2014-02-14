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
    -MemoryStartupBytes 256MB `
    -SwitchName "Virtual LAN 2 - 192.168.10.x"

Set-VMMemory `
    -VMName $vmName `
    -DynamicMemoryEnabled $true `-MinimumBytes 128MB `
    -MaximumBytes 512MB

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

# EXT-WEB01B - Windows Server 2008 R2 Standard

Friday, January 31, 2014
9:01 AM

```Console
12345678901234567890123456789012345678901234567890123456789012345678901234567890

PowerShell
```

## # Create virtual machine

```PowerShell
$vmName = "EXT-WEB01B"

New-VM `
    -Name $vmName `
    -Path C:\NotBackedUp\VMs `
    -MemoryStartupBytes 4GB `
    -SwitchName "Virtual LAN 2 - 192.168.10.x"

Set-VMProcessor -VMName $vmName -Count 4

$sysPrepedImage = "\\ICEMAN\VHD Library\WS2008-R2-STD.vhdx"

mkdir "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks"

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

Copy-Item $sysPrepedImage $vhdPath

Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath

Start-VM $vmName
```

## # Rename the server and join domain

```PowerShell
# Note: Rename-Computer is not available on Windows Server 2008 R2
netdom renamecomputer $env:COMPUTERNAME /newname:EXT-WEB01B /reboot

# Note: "-Restart" parameter is not available on Windows Server 2008 R2
# Note: "-Credential" parameter must be specified to avoid error
Add-Computer `
    -DomainName extranet.technologytoolbox.com `-Credential EXTRANET\jjameson-admin

Restart-Computer
```

## # Change drive letter for DVD-ROM

### # To change the drive letter for the DVD-ROM using PowerShell

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
```

## # Reset WSUS configuration

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\WSUS\Reset WSUS for SysPrep Image.cmd'
```

## # Add disks for SharePoint storage (Data01 and Log01)

```PowerShell
$vmName = "EXT-WEB01B"

Stop-VM $vmName

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Data01.vhdx"

New-VHD -Path $vhdPath -Dynamic -SizeBytes 5GB
Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath -ControllerType SCSI

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Log01.vhdx"

New-VHD -Path $vhdPath -Dynamic -SizeBytes 5GB
Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath -ControllerType SCSI

Start-VM $vmName
```

## # Initialize disks and format volumes

```PowerShell
# Note: Get-Disk is not available on Windows Server 2008 R2

DISKPART

SELECT DISK 1
CREATE PARTITION PRIMARY
FORMAT FS=NTFS LABEL="Data01" QUICK
ASSIGN LETTER=D

SELECT DISK 2
CREATE PARTITION PRIMARY
FORMAT FS=NTFS LABEL="Log01" QUICK
ASSIGN LETTER=L

EXIT
```

## Prepare the farm server

1. From the SharePoint Server 2010 with Service Pack 1 installation location, double-click the appropriate executable file.
2. Click **Install software prerequisites** on the splash screen. If prompted by User Account Control to allow the program to make changes to the computer, click **Yes**.
3. On the **Welcome to the Microsoft® SharePoint® 2010 Products Preparation Tool** page, click **Next**.
4. Review the licensing agreement. If you accept the terms and conditions, select **I accept the terms of the License Agreement(s)**, and then click **Next**.
5. On the **Installation Complete** page, click **Finish**.
6. Restart the server to complete the installation of the prerequisites.

## Install SharePoint Server 2010

1. If the SharePoint installation splash screen is not already showing, from the SharePoint Server 2010 installation location, double-click the appropriate executable file.
2. Click **Install SharePoint Server** on the splash screen. If prompted by User Account Control to allow the program to make changes to the computer, click **Yes**.
3. On the **Enter your Product Key** page, type the corresponding SharePoint Server 2010 Enterprise CAL product key, and then click **Continue**.
4. Review the licensing agreement. If you accept the terms and conditions, select **I accept the terms of this agreement**, and then click **Continue**.
5. On the **Choose the installation you want** page, click **Server Farm**.
6. On the **Server Type** tab, click **Complete**.
7. On the **File Location** tab, change the search index path to **D:\\Program Files\\Microsoft Office Servers\\14.0\\Data**, and then click **Install Now**.
8. Wait for the installation to finish.
9. On the **Run Configuration Wizard** page, clear the **Run the SharePoint Products and Technologies Configuration Wizard now** checkbox, and then click **Close**.

## Add Web server to the farm

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9F/B472EFD8A76E7E794B8660950395C0A58534709F.png)

## Add SharePoint Central Administration to the Local intranet zone

## # Add the SharePoint bin folder to the PATH environment variable

```PowerShell
$sharePointBinFolder = $env:ProgramFiles +
    "\Common Files\Microsoft Shared\web server extensions\14\BIN"

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-PathFolders.ps1 `
    $sharePointBinFolder `
    -EnvironmentVariableTarget "Machine"
```

## Grant DCOM permissions on IIS WAMREG admin Service

### Reference

**Event ID 10016, KB 920783, and the WSS_WPG Group**\
Pasted from <[http://www.technologytoolbox.com/blog/jjameson/archive/2009/10/17/event-id-10016-kb-920783-and-the-wss-wpg-group.aspx](http://www.technologytoolbox.com/blog/jjameson/archive/2009/10/17/event-id-10016-kb-920783-and-the-wss-wpg-group.aspx)>

## Grant DCOM permissions on MSIServer (000C101C-0000-0000-C000-000000000046)

Using the steps in the previous section, grant **Local Launch** and **Local Activation** permissions to the **WSS_ADMIN_WPG** group on the MSIServer application:

**{000C101C-0000-0000-C000-000000000046}**

## # Rename TaxonomyPicker.ascx

```PowerShell
ren "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\14\TEMPLATE\CONTROLTEMPLATES\TaxonomyPicker.ascx" TaxonomyPicker.ascx_broken
```

## Install SharePoint Server 2010 Service Pack 2

After installing the update on each server in the farm, run the SharePoint Products and Technologies Configuration Wizard (PSConfigUI.exe) on each server in the farm.

## Upgrade Hyper-V integration services

## Add network adapter (Virtual LAN 2 - 192.168.10.x)

Enable MAC address spoofing

## Rename network connections

Rename **Local Area Connection** to **LAN 1 - 192.168.10.x**.

Rename **Local Area Connection 2** to **NLB - 192.168.10.x**.

## Configure static IP address on NLB network connection

- IP address: 192.168.10.152
- Subnet mask: 255.255.255.0
- Default gateway: (none)
- Preferred DNS server: (none)
- Alternate DNS server: (none)

## Install and configure Network Load Balancing

## Create and configure the Fabrikam Extranet Web application

Pasted from <[http://www.technologytoolbox.com/blog/jjameson/archive/2013/04/30/installation-guide-for-sharepoint-server-2010-and-office-web-apps.aspx](http://www.technologytoolbox.com/blog/jjameson/archive/2013/04/30/installation-guide-for-sharepoint-server-2010-and-office-web-apps.aspx)>

### Configure the People Picker to support searches across one-way trust

```Console
stsadm -o setapppassword -password {Key}
```

### Configure SSL on the Internet zone

#### Import SSL certificate for extranet.fabrikam.com

#### Add HTTPS binding

![(screenshot)](https://assets.technologytoolbox.com/screenshots/53/9298D611A6EB3A449B051602F8525DE69C43EB53.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/97/4C088BB640C52DA2088D721BBD96DCEFF2DE2E97.png)

Click Add...

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F0/5EA31F2BD37022A9F53AEA04E62CFEEC121915F0.png)

In the **Add Site Binding** window:

1. In the **Type** dropdown, click https.
2. In the **IP address** box, type 192.168.10.162.
3. In the **SSL certificate** dropdown, click **extranet.fabrikam.com**.
4. Click **OK**.

## Deploy the Fabrikam Extranet solution and create partner sites

### Configure logging

Copy contents of "Add Event Log Sources.ps1" and paste into PowerShell window.

**Issue: ULS logging stopped due to free space below ~1.1GB**

**Expand L: drive to 10GB**

**Create and configure the SecuritasConnect Web application**

**Enable disk-based caching for the Web application**

```Console
notepad C:\inetpub\wwwroot\wss\VirtualDirectories\client-dev.securitasinc.com80\web.config

    <BlobCache location="..." path="..." maxSize="1" enabled="true" />
```

## # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

## # Configure firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
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

# EXT-WEB01A - Windows Server 2008 R2 Standard

Friday, January 31, 2014
9:01 AM

```Console
12345678901234567890123456789012345678901234567890123456789012345678901234567890

PowerShell
```

## # Create virtual machine

```PowerShell
$vmName = "EXT-WEB01A"

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
netdom renamecomputer $env:COMPUTERNAME /newname:EXT-WEB01A /reboot

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
$vmName = "EXT-WEB01A"

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

![(screenshot)](https://assets.technologytoolbox.com/screenshots/71/BE886DF61650C40EFA0F5BA4BE6216D7AE342271.png)

Enable MAC address spoofing

## Rename network connections

Rename **Local Area Connection** to **LAN 1 - 192.168.10.x**.

Rename **Local Area Connection 2** to **NLB - 192.168.10.x**.

## Configure static IP address on NLB network connection

- IP address: 192.168.10.151
- Subnet mask: 255.255.255.0
- Default gateway: (none)
- Preferred DNS server: (none)
- Alternate DNS server: (none)

## Install and configure Network Load Balancing

![(screenshot)](https://assets.technologytoolbox.com/screenshots/68/01F4ADAB5B13AEBC077D0B7EAE39C30FFD6A2A68.png)

Click **Add Features**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/76/A6C415E95118F138F717839261D3E8279B313F76.png)

Click the checkbox for **Network Load Balancing** and then click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/09/FBDAA4D23F70BADF76F87663C91A802FED083609.png)

Click **Install**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0A/6C6052AD94B6AEDE606FBD6D5FDA7B1995F9660A.png)

Click **Close**.

Start **Network Load Balancing Manager**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/51/2BBCFC44D226F33541DE2F31EA3502F100691B51.png)

On the **Cluster** menu, click **New**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/83/F0948FA6AE48D78F4C2367229B9E6415E9FF1A83.png)

In the **Host** box, type **EXT-WEB01A** and click **Connect**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F5/628665A3D2DAA4E4B578DADE7741C031370BFCF5.png)

Click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A1/F39E75D21921D0416557DBEF41F82D0359C47CA1.png)

Click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5F/64A3B388B62D140360E05661B2A81251EABF5B5F.png)

Click **Add...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F8/78533FBBE8EA13C30F68409325C72F5E456AB5F8.png)

Ensure **Add IPv4 address** is selected. In the **IPv4 address** box, type **192.168.10.150**. Ensure Subnet mask is set to **255.255.255.0**, and click **OK**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C6/3D3DEC197767075E2EE6CADFA8D12C48CABBA8C6.png)

Click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/10/934DA5C6BA68FCCF0CC9FC4EDB8E18004CD8D210.png)

In the **Full Internet name** box, type **ext-web01.extranet.technologytoolbox.com** and click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B2/0124D7C5EF6FE6AAD8A9B92AB49DBD9E49B5E8B2.png)

Click **Finish**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3F/09468A09D7A0C4BFA8D0416C45AAB1716A256E3F.png)

On the **Cluster** menu, click **Add Host**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/61/754E9EA0B908615ADDE9E9987DB88611B1A11761.png)

In the **Host** box, type **EXT-WEB01B** and click **Connect**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DA/D5D01399E6CE8E02B436E65263798F96032170DA.png)

Click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/10/F900F1005D373A9E4650A5C1A0FB7FA6668F2610.png)

Click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2B/5F1286B5AAB3535BFCEBF37292722321C4926C2B.png)

Click **Finish**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D0/81EB3C852B79507106B648578B204586FF0376D0.png)

## Create and configure the Fabrikam Extranet Web application

Pasted from <[http://www.technologytoolbox.com/blog/jjameson/archive/2013/04/30/installation-guide-for-sharepoint-server-2010-and-office-web-apps.aspx](http://www.technologytoolbox.com/blog/jjameson/archive/2013/04/30/installation-guide-for-sharepoint-server-2010-and-office-web-apps.aspx)>

### Configure the People Picker to support searches across one-way trust

```Console
stsadm -o setapppassword -password {Key}
```

### Configure SSL on the Internet zone

#### Add IP address for Fabrikam Extranet Web application to NLB cluster

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B5/38FB8D2B5ADE17021F3AC9306DB6044C4B98B9B5.png)

On the **Cluster** menu, click **Properties**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FC/43677FE823F2FD821D36A9C075E47C9606BA93FC.png)

Click Add...

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A4/88417439BA916AB45110EE25F828C2BCF10D63A4.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E9/04383D30514D7B2BAEA676A27592DCA2B395E7E9.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/54/30D2FC4AB862DC0F49B73C8850C82E9202FC4154.png)

Click **Yes**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/59/B644DCCE9DB3F95500E3E63D2631FB620C841759.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/44/37542FA6077DE122FEE8DEFBA00B2159C7086244.png)

#### Import SSL certificate for extranet.fabrikam.com

1. Start MMC.
2. Add **Certificates** snap-in for **Local Computer**.
3. Expand **Certificates (Local Computer)** --> **Personal**.
4. Right-click **Certificates**, point to **All Tasks**, and click **Import...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1F/02F934EEC54E30FEC745614653AE0977AED5471F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/74/1FFB9232BD39C1F068D0C36C7906DE96D9F0BC74.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DA/CECAA6B99AA12AFE7F5803AE7AC47FBC527891DA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/01/46E57EF9995000989211622C5CF4F06D44A53801.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7A/F15D4693BAC6C8EBACB2D97F00A8EA8B9949EC7A.png)

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

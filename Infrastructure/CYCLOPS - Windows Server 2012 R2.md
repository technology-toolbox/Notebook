# CYCLOPS - Windows Server 2012 R2 Standard

Sunday, January 05, 2014
4:56 AM

```Console
12345678901234567890123456789012345678901234567890123456789012345678901234567890

PowerShell
```

## # Create virtual machine

```PowerShell
$vmName = "CYCLOPS"

New-VM `
    -Name $vmName `
    -Path C:\NotBackedUp\VMs `
    -MemoryStartupBytes 512MB `
    -SwitchName "Virtual LAN 2 - 192.168.10.x"

Set-VMProcessor -VMName $vmName -Count 2

Set-VMMemory `
    -VMName $vmName `
    -DynamicMemoryEnabled $true `
    -MaximumBytes 2GB

$sysPrepedImage =
    "\\ICEMAN\VM Library\ws2012std-r2\Virtual Hard Disks\ws2012std-r2.vhd"

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

Convert-VHD `
    -Path $sysPrepedImage `
    -DestinationPath $vhdPath

Set-VHD $vhdPath -PhysicalSectorSizeBytes 4096

Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath

Start-VM $vmName
```

## # Rename the server and join domain

```PowerShell
Rename-Computer -NewName CYCLOPS -Restart

Add-Computer -DomainName corp.technologytoolbox.com -Restart
```

## # Download PowerShell help files

```PowerShell
Update-Help
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

## # Rename network connection

```PowerShell
Get-NetAdapter -Physical

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "LAN 1 - 192.168.10.x"
```

## # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name "LAN 1 - 192.168.10.x" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

ping ICEMAN -f -l 8900
```

## # Install .NET Framework 3.5

```PowerShell
Install-WindowsFeature `
    NET-Framework-Core `
    -Source '\\ICEMAN\Products\Microsoft\Windows Server 2012 R2\Sources\SxS'
```

## # Install SQL Server Reporting Services

**# Note: .NET Framework 3.5 is required for SQL Server Reporting Services.**

### Reference

**Set up SQL Server for TFS**\
Pasted from <[http://msdn.microsoft.com/en-us/library/jj620927.aspx](http://msdn.microsoft.com/en-us/library/jj620927.aspx)>

SQL Server 2012 with SP1

On the **Feature Selection** step, select **Reporting Services - Native**.

On the **Server Configuration** step, on the **Service Accounts** tab:

- In the **Account Name** column for **SQL Server Reporting Services**, type **NT AUTHORITY\\NETWORK SERVICE**.
- In the **Startup Type** column for **SQL Server Reporting Services**, ensure **Automatic** is selected.

## # Install SCOM agent

```PowerShell
$imagePath = '\\iceman\Products\Microsoft\System Center 2012 R2' `
    + '\en_system_center_2012_r2_operations_manager_x86_and_x64_dvd_2920299.iso'

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$msiPath = $imageDriveLetter + ':\agent\AMD64\MOMAgent.msi'

msiexec.exe /i $msiPath `
    MANAGEMENT_GROUP=HQ `
    MANAGEMENT_SERVER_DNS=JUBILEE `
    ACTIONS_USE_COMPUTER_ACCOUNT=1
```

## # Approve manual agent install in Operations Manager

## Install TFS 2013

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E6/65AABA80C93D17531C20149CA08428EB296DE2E6.png)

UAC, click **Yes**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/13/BB4AA879AFA667688AC9CE95D33FF37D26FBBB13.png)

Wait for the installation to finish. The Team Foundation Server Configuration Center appears.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DB/FD1454E31549D3D03F38B6AF99AC19CF48674DDB.png)

## -- Restore TFS databases (OLTP) (HAVOK)

## Restore TFS Analysis Services database (HAVOK)

## Configure Reporting Services for TFS (using restored database)

1. Start **Reporting Services Configuration Manager**. If prompted by User Account Control to allow the program to make changes to the computer, click **Yes**.
2. In the **Reporting Services Configuration Connection** dialog box, ensure the name of the server and SQL Server instance are both correct, and then click **Connect**.
3. In the **Report Server Status** pane, click **Start** if the server is not already started.
4. In the navigation pane, click **Service Account**.
5. In the **Service Account** pane, ensure **Use built-in account** is selected and the account is set to **Network Service**.
6. In the navigation pane, click **Web Service URL**.
7. In the **Web Service URL **pane:
   1. Confirm the following warning message appears:
   2. Click **Apply**.
8. In the navigation pane, click **Database**.
9. In the **Report Server Database** pane, click **Change Database**.
10. In the **Report Server Database Configuration Wizard** window:
    1. In the **Action** pane, ensure **Choose an existing report server database** is selected, and then click **Next**.
    2. In the **Database Server** pane, type the name of the database server (**HAVOK-TEST**) in the **Server Name** box, click **Test Connection** and confirm the test succeeded, and then click **Next**.
    3. In the **Database **pane, in the **Report Server Database** list, select the restored database (**ReportServer_TFS**) and then click **Next**.
    4. In the **Credentials **pane, ensure **Authentication Type** is set to **Service Credentials** and then click **Next**.
    5. On the **Summary** page, verify the information is correct, and then click **Next**.
    6. Click **Finish** to close the wizard.
11. In the navigation pane, click **Report Manager URL**.
12. In the **Report Manager URL **pane:
    1. Confirm the following warning message appears:
    2. Click **Apply**.
13. In the navigation pane, click **Encryption Keys**.
14. In the **Encryption Keys **pane, click **Restore**.
15. In the **Restore Encryption Key** window:
    1. In the **File Location **box, specify the location of the backup file for the encryption key.
    2. In the **Password** box, type the password for the backup file.
    3. Click **OK**.
16. In the navigation pane, click **Scale-out Deployment**.
17. In the **Scale-out Deployment** pane, choose the previous report server from the scale-out deployment status page and click **Remove Server**. When prompted to confirm removing the selected server, click **OK**.

Report Server Web Service is not configured. Default values have been provided to you. To accept these defaults simply press the Apply button, else change them and then press Apply.

The Report Manager virtual directory name is not configured. To configure the directory, enter a name or use the default value that is provided, and then click Apply.

**[\\\\iceman\\Users\$\\jjameson-admin\\Documents\\Reporting Services - CYCLOPS.snk](\\iceman\Users$\jjameson-admin\Documents\Reporting Services - CYCLOPS.snk)**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/27/98740CDFB118C8CE2628DD0BBCF124B539F51527.png)

**Workaround:**

```Console
    cd "\Program Files (x86)\Microsoft SQL Server\110\Tools\Binn"
    .\RSKeyMgmt.exe -l
    .\RSKeyMgmt.exe -r 9676f436-13b9-4bef-8260-c01ee43ffb02
```

### Reference

**Fix up the report server**\
Pasted from <[http://msdn.microsoft.com/en-us/library/jj620932.aspx](http://msdn.microsoft.com/en-us/library/jj620932.aspx)>

## Update data sources in SQL Server Reporting Services

![(screenshot)](https://assets.technologytoolbox.com/screenshots/17/BB083738A65E535048B05A6AEF1BC64B5011F017.png)

Repeat the steps for the **Tfs2010ReportDS** data source.

## Upgrade TFS

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5E/227CF7BA4CD5761128A36D5BB1E27EB56106775E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/89/BBED7022323381794575E54D9346F72A0F77CD89.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/99/A2EEAEBE91D666092CD2E6FC78A293289BAAEC99.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CE/A83261F4B635908665B6341B1FF9AC51054E75CE.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E2/46EBE16590899994718DC1BFF07BB97E20CCE9E2.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7F/C340FD954CD9E20B7EACF9740647D9773FA53A7F.png)

If necessary, change the name in the **Reporting Services Instances** box and click **Populate URLs**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/08/8F1B2185D2281BC60AB03B23452439FBF68AE908.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F5/CAD3293E3F3AF73BEEF75C1F74B378960BEF20F5.png)

In the **SQL Server Instance** box, type the name of the database server and then click **Test**.

Click **List Available Databases**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AB/32CD479C162976D92FF9171BF3FD03FB5326DCAB.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/28/CBE6EE55081A9D6597CB5826CA430EFFC4C19E28.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/91/E42A6E4F7FC1600AD893F2DC0D51D4C72B77CC91.png)

Clear the **Configure SharePoint for use with Team Foundation Server** checkbox.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2C/29C7ECD1C19FE7E1969CA495F3C7DA4B781BDF2C.png)

Click **Verify**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/57/D38139D27FDB680516C700795E33C7622110C057.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DF/C45EA0EA5B691DD379261C83881ED269072B80DF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D9/D6CD71353E3F5B13787D15F4300EB044D30ED0D9.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/01/D0C4A510F507C04BD12EA691B5E8781D103B2C01.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8C/BDE1F7845BEBB954828192EDF15F3A0B19502E8C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FC/125B280550982F97BA11B4C0A14DC5847D752BFC.png)

To configure the new features for a team project, follow the steps in [http://go.microsoft.com/fwlink/?LinkID=229859](http://go.microsoft.com/fwlink/?LinkID=229859)

## # Deploy http://www-test.technologytoolbox.com

```PowerShell
setx /m CAELUM_URL http://www-test.technologytoolbox.com

Copy-Item `
    '\\iceman\Builds\Caelum\_latest\Deployment Files\Scripts\Rebuild Website.ps1' `'C:\NotBackedUp\Temp\Rebuild Website.ps1'

& 'C:\NotBackedUp\Temp\Rebuild Website.ps1' 1.0.265.0 2.5.2.15

cd C:\inetpub\wwwroot

robocopy `    www.technologytoolbox.com\blog\Images\www_technologytoolbox_com `    www-test.technologytoolbox.com\blog\Images\www_technologytoolbox_com /E

robocopy `    www.technologytoolbox.com\Documents `    www-test.technologytoolbox.com\Documents /E
```

### # Tweak Web.config files

```PowerShell
Notepad "C:\inetpub\wwwroot\www-test.technologytoolbox.com\Web.config"
```

**# Comment out section starting on line 9:**

```XML
    <sectionGroup name="scripting" ...>
        ...
    </sectionGroup>
```

**# Replace BEAST with HAVOK in connection strings**

```Console
Notepad "C:\inetpub\wwwroot\www-test.technologytoolbox.com\blog\Web.config"
```

**# Comment out section starting on line 9:**

```XML
    <sectionGroup name="scripting" ...>
        ...
    </sectionGroup>
```

**# Replace BEAST with HAVOK in connection strings**

## Configure an SMTP server for TFS

![(screenshot)](https://assets.technologytoolbox.com/screenshots/51/45CB6748AA9B637B5E6BC8C11E22A015FF1F8F51.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CF/EA484EE4078C134B28719FBF2A89FBD698C63CCF.png)

In the **Email Alert Settings** section, click **Send Test Email**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E9/10286ADAF5C842508DC38F8908D86A0FFD90A4E9.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D6/9505DBEDCC6C73B9915BEC5DF14F73C1FA6FABD6.png)

## Resolve SCOM alerts due to disk fragmentation

### Alert Name

Logical Disk Fragmentation Level is high

### Alert Description

The disk C: (C:) on computer CYCLOPS.corp.technologytoolbox.com has high fragmentation level. File Percent Fragmentation value is 14%. Defragmentation recommended: true.

### Resolution

##### # Copy Toolbox content

```PowerShell
robocopy \\iceman\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E
```

##### # Create scheduled task to optimize drives

```PowerShell
[string] $xml = Get-Content `
  'C:\NotBackedUp\Public\Toolbox\Scheduled Tasks\Optimize Drives.xml'

Register-ScheduledTask -TaskName "Optimize Drives" -Xml $xml
```

## # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

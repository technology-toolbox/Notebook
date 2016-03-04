# EXT-APP01A - Windows Server 2008 R2 Standard

Friday, January 31, 2014
9:01 AM

```Console
12345678901234567890123456789012345678901234567890123456789012345678901234567890

PowerShell
```

## # Create virtual machine

```PowerShell
$vmName = "EXT-APP01A"

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
netdom renamecomputer $env:COMPUTERNAME /newname:EXT-APP01A /reboot

# Note: "-Restart" parameter is not available on Windows Server 2008 R2
# Note: "-Credential" parameter must be specified to avoid error
Add-Computer `
    -DomainName extranet.technologytoolbox.com `-Credential EXTRANET\jjameson-admin

Restart-Computer
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

## # Reset WSUS configuration

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\WSUS\Reset WSUS for SysPrep Image.cmd'
```

## # Add disks for SharePoint storage (Data01 and Log01)

```PowerShell
$vmName = "EXT-APP01A"

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

## # Create and configure the farm

```PowerShell
C:\NotBackedUp\Public\Toolbox\SharePoint\Scripts\New-SPFarm.ps1 `
    -DatabaseServer EXT-SQL01 `
    -CentralAdminAuthProvider NTLM
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AC/43F15D33B65CD93A5D6E0603398FD0BF758EE3AC.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F4/15CD8D04F00638DAC0909259C028250B166EA2F4.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6F/35494ADCDD47ACE1F057184A91E3D90369409D6F.png)

## Add SharePoint Central Administration to the Local intranet zone

## Add Web servers to the farm (EXT-WEB01A and EXT-WEB01B)

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

## Configure diagnostic logging and usage and health data collection

### To configure diagnostic logging

1. Click **Start**, point to **All Programs**, click **Microsoft SharePoint 2010 Products**, and then click **SharePoint 2010 Central Administration**. If prompted by User Account Control to allow the program to make changes to the computer, click **Yes**.
2. On the Central Administration home page, click **Monitoring**.
3. In the **Reporting** section, click **Configure diagnostic logging**.
4. On the **Diagnostic Logging** page, configure the settings as specified in the table below, and then click **OK**.

| **Section** | **Setting** | **Value**                                               |
| ----------- | ----------- | ------------------------------------------------------- |
| Trace Log   | Path        | L:\\Program Files\\Microsoft Office Servers\\14.0\\Logs |

### To configure usage and health data collection

1. On the **Monitoring** page in Central Administration, in the **Reporting** section, click **Configure usage and health data collection**.
2. On the **Configure web analytics and health data collection **page, configure the settings as specified in the table below, and then click **OK**.

| **Section**                    | **Setting**                   | **Value**                                               |
| ------------------------------ | ----------------------------- | ------------------------------------------------------- |
| Usage Data Collection          | Enable usage data collection  | Yes (checked)                                           |
| Usage Data Collection Settings | Log file location             | L:\\Program Files\\Microsoft Office Servers\\14.0\\Logs |
|                                | Maximum log file size         | 1 GB                                                    |
| Health Data Collection         | Enable health data collection | Yes (checked)                                           |
| Logging Database Server        | Database Server               | EXT-SQL01                                               |
|                                | Database Name                 | WSS_Logging                                             |

## # Configure outgoing e-mail settings

```PowerShell
Add-PSSnapin Microsoft.SharePoint.PowerShell

$smtpServer = "smtp-test.technologytoolbox.com"
$fromAddress = "svc-sharepoint-test@technologytoolbox.com"
$replyAddress = "no-reply@technologytoolbox.com"
$characterSet = 65001 # Unicode (UTF-8)

$centralAdmin = Get-SPWebApplication -IncludeCentralAdministration |
    Where-Object { $_.IsAdministrationWebApplication -eq $true }

$centralAdmin.UpdateMailSettings(
    $smtpServer,
    $fromAddress,
    $replyAddress,
    $characterSet)
```

## Install SharePoint Server 2010 Service Pack 2

After installing the update on each server in the farm, run the SharePoint Products and Technologies Configuration Wizard (PSConfigUI.exe) on each server in the farm.

## Upgrade Hyper-V integration services

## Create and configure the Fabrikam Extranet Web application

Pasted from <[http://www.technologytoolbox.com/blog/jjameson/archive/2013/04/30/installation-guide-for-sharepoint-server-2010-and-office-web-apps.aspx](http://www.technologytoolbox.com/blog/jjameson/archive/2013/04/30/installation-guide-for-sharepoint-server-2010-and-office-web-apps.aspx)>

### Copy Fabrikam Extranet build to SharePoint server

### Create the Web application and initial site collections

```PowerShell
& '.\Create Web Application.ps1'

& '.\Create Site Collections.ps1'
```

### Configure object cache user accounts

```PowerShell
& '.\Configure Object Cache User Accounts.ps1'

iisreset
```

### Configure the People Picker to support searches across one-way trust

```Console
stsadm -o setapppassword -password {Key}

stsadm -o setproperty -pn peoplepicker-searchadforests -pv "domain:extranet.technologytoolbox.com,EXTRANET\svc-web-fabrikam,{password};domain:corp.fabrikam.com,FABRIKAM\svc-web-fabrikam,{password};domain:corp.technologytoolbox.com,TECHTOOLBOX\svc-web-fabrikam,{password}" -url http://extranet.fabrikam.com
```

### Modify the permissions on the registry key where the encrypted credentials are stored

The default permissions on the registry key where the encrypted credentials are stored only grant access to the following service accounts and groups:

- SYSTEM
- NETWORK SERVICE
- WSS_RESTRICTED_WPG_V4
- Administrators

The permissions must be modified on each Web server in order to allow the service account for the Web application to read the encrypted credentials.

#### To modify the permissions on the registry key where the encrypted credentials are stored

1. Click the **Start** menu, type **regedit**, and then click **regedit.exe**. If prompted by **User Account Control **to allow the program to make changes to this computer, click **Yes**.
2. In the **Registry Editor** window, find the following key:

**HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Shared Tools\\Web Server Extensions\\14.0\\Secure**
3. Right-click on the **HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Shared Tools\\Web Server Extensions\\14.0\\Secure** key and then click **Permissions**.
4. In the **Permissions for Secure** dialog box, click **Add...**
5. In the **Select Users, Computers, Service Accounts, or Groups** dialog box:
   1. Type **WSS_WPG**.
   2. Click **Locations...**
   3. In the **Locations** dialog box, click the name of the local computer and then click **OK**.
   4. Click **Check Names** to verify the group name.
   5. Click **OK**.
6. In the **Permissions for WSS_WPG** section, select the **Allow** checkbox for the **Read** permission.
7. Click **OK**.
8. Repeat the steps above on each Web server in the farm.
9. Create domain local group: **EXTRANET\\SharePoint Admins**
10. Add the following members to **EXTRANET\\SharePoint Admins**:
11. Add **EXTRANET\\SharePoint Admins **to SharePoint **Farm Administrators** group
12. [EXT-SQL01A] Create SQL Server login for **EXTRANET\\SharePoint Admins **group and add it to the **SharePoint_Shell_Access** role in **SharePoint_Config** database.
13. Stop SQL Server
14. Using **Failover Cluster Manager**, take **Cluster Disk 3** offline
15. Extend iSCSI virtual disk
16. Using **Failover Cluster Manager**, bring **Cluster Disk 3** online
17. Using **Disk Management**, extend volume to 25GB.
18. Start SQL Server

**Note:**\
At this point, users can select users and groups from the listed forests and domains from any front-end Web server in the farm.

### Configure SSL on the Internet zone

EXT-WEB01A - Import SSL certificate and add HTTPS binding

EXT-WEB01B - Import SSL certificate and add HTTPS binding

### Enable anonymous access to the site

```PowerShell
& '.\Enable Anonymous Access.ps1'
```

### Configure claims-based authentication

#### Create and configure the membership/role database

```Console
cd %WinDir%\Microsoft.NET\Framework\v2.0.50727

aspnet_regsql.exe
```

EXT-SQL01A - Add the service accounts to the membership/role database

#### Add Web.config modifications for claims-based authentication

#### Create a user in the database using IIS Manager

- **jeremy_jameson@hotmail.com**
- **jeremy_jameson@yahoo.com**

### Validate claims authentication configuration

**Enable disk-based caching for the Web application**

**Configure SharePoint groups**

## Configure service applications

### Configure the State Service

```PowerShell
& '.\Configure State Service.ps1'
```

### Create and configure the Search Service Application

```PowerShell
& '.\Configure SharePoint Search.ps1'
```

### Configure the search crawl schedules

## Install and configure Office Web Apps

### Install Office Web Apps

### Run PSConfig to register Office Web Apps services

### Start the Office Web Apps service instances and create service applications

### Configure Excel Services Application trusted location

### Configure the Office Web Apps cache

```PowerShell
& '.\Configure Office Web Apps Cache.ps1'

iisreset
```

### Grant access to the Web application content database for Office Web Apps

```PowerShell
$webApp = Get-SPWebApplication -Identity "http://extranet.fabrikam.com"

$webApp.GrantAccessToProcessIdentity("EXTRANET\svc-spserviceapp")
```

## Deploy the Fabrikam Extranet solution and create partner sites

### Configure logging

```PowerShell
& '.\Add Event Log Sources.ps1'
```

### Install Fabrikam SharePoint solutions and activate the features

```PowerShell
& '.\Add Solutions.ps1'
& '.\Deploy Solutions.ps1'
& '.\Activate Features.ps1'
```

### Configure sample content

```Console
pushd ..\..\Tools\TestConsole\bin\Release
Fabrikam.Demo.Tools.TestConsole.exe http://extranet.fabrikam.com
popd
```

## Create and configure a partner site

### Create site collection for a Fabrikam partner

```PowerShell
& '.\Create Partner Site Collection.ps1' "Contoso Shipping"
```

### Apply the "Fabrikam Partner Site" template to the top-level site

### Update the partner site home page

## Create and configure a team collaboration site

### Create the team collaboration site

### Update the team site home page

**Issue: ULS logging stopped due to free space below ~1.1GB**

**Expand L: drive to 10GB**

## Configure SharePoint administrators

- **EXTRANET\\jjameson-admin**
- **TECHTOOLBOX\\SharePoint Administrators**

**SecuritasConnect prerequisites**

**Enable session state**

```PowerShell
Enable-SPSessionStateService -DatabaseServer EXT-SQL01 -DatabaseName SessionState
```

**Install Prince on front-end Web servers**

**Copy SecuritasConnect build to SharePoint server**

```Console
robocopy \\iceman\Builds\Securitas\ClientPortal\3.0.591.0 C:\NotBackedUp\Builds\Securitas\ClientPortal\3.0.591.0 /E
```

**Note:** 3.0.591.0 = "v3.0 Sprint-10"

**Create and configure the SecuritasConnect Web application**

### Set environment variables

```PowerShell
[Environment]::SetEnvironmentVariable(
    "SECURITAS_CLIENT_PORTAL_URL",
    "http://client-dev.securitasinc.com",
    "Machine")
```

**Create the Web application and initial site collections**

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\3.0.591.0\DeploymentFiles\Scripts

& '.\Create Web Application.ps1'
```

When prompted for the credentials for the Web application service account:

1. In the **User name** box, type **EXTRANET\\svc-web-sec-2010-dev**.
2. In the **Password** box, type the corresponding password for the service account.
3. Click **OK**.

```PowerShell
& '.\Create Site Collections.ps1'
```

**Configure machine key for Web application**

```PowerShell
& '.\Configure Machine Key.ps1'
```

**Configure object cache user accounts**

> **Important**
>
> Run the following script when logged in as **EXTRANET\\jjameson-admin** (*not* **TECHTOOLBOX\\jjameson-admin**).

```PowerShell
& '.\Configure Object Cache User Accounts.ps1'

iisreset
```

**Configure the People Picker to support searches across one-way trust**

**Specify the credentials for accessing the trusted forest**

```Console
stsadm -o setproperty -pn peoplepicker-searchadforests -pv "domain:extranet.technologytoolbox.com,EXTRANET\svc-web-fabrikam,{password};domain:corp.fabrikam.com,FABRIKAM\svc-web-fabrikam,{password};domain:corp.technologytoolbox.com,TECHTOOLBOX\svc-web-fabrikam,{password}" -url http://client-dev.securitasinc.com
```

**Enable disk-based caching for the Web application**

```Console
notepad C:\inetpub\wwwroot\wss\VirtualDirectories\client-dev.securitasinc.com80\web.config

    <BlobCache location="..." path="..." maxSize="1" enabled="true" />
```

**Configure the Office Web Apps cache**

```PowerShell
& '.\Configure Office Web Apps Cache.ps1'

iisreset
```

**Grant access to the Web application content database for Office Web Apps**

```PowerShell
$webApp = Get-SPWebApplication -Identity "http://client-dev.securitasinc.com"
$webApp.GrantAccessToProcessIdentity("EXTRANET\svc-spserviceapp")
```

**Deploy the SecuritasConnect solution**

**Create and configure the SecuritasPortal database**

Restore SecuritasPortal backup from PROD

**[EXT-SQL01A] Configure permissions for the SecuritasPortal database**

**Configure logging**

```PowerShell
& '.\Add Event Log Sources.ps1'
```

**Configure claims-based authentication**

**Install SecuritasConnect solutions and activate the features**

```PowerShell
& '.\Add Solutions.ps1'

& '.\Deploy Solutions.ps1'

& '.\Activate Features.ps1'
```

Browse to the site and activate **Securitas - Application Settings** feature.

**Import template site content**

```PowerShell
& '.\Import Template Site Content.ps1'
```

**Add "Page Type" Column to List Settings for PODS Template Sites**

**Configure trusted root authorities in SharePoint**

```PowerShell
& '.\Configure Trusted Root Authorities.ps1'
```

**Configure C&C landing site**

```PowerShell
$site = Get-SPSite "http://client-dev.securitasinc.com/sites/cc"
$group = $site.RootWeb.SiteGroups["Collaboration & Community Visitors"]
$group.AddUser(
    "c:0-.f|securitassqlroleprovider|branch managers",
    $null,
    "Branch Managers",
    $null)

$claim = New-SPClaimsPrincipal -Identity "Branch Managers" -IdentityType WindowsSecurityGroupName

$branchManagersUser = $site.RootWeb.EnsureUser($claim.ToEncodedString())
$group.AddUser($branchManagersUser)
$site.Dispose()
```

**Create and configure C&C site collections**

**Create site collection for a Securitas client**

```PowerShell
& '.\Create Client Site Collection.ps1' "ABC Company"
```

**Apply the "Securitas Client Site" template to the top-level site**

**Modify the site title, description, and logo**

**Update the client site home page**

**Create a blog site**

**Create a wiki site**

```PowerShell
$siteUrl = "http://client-dev.securitasinc.com/sites/ABC-Company"

Enable-SPFeature "TaxonomyFieldAdded" -Url $siteUrl
```

## Add iSCSI disk for SharePoint backups

**Add network adapter (Virtual iSCSI 1 - 10.1.10.x)**

**# Rename network connections**

```Console
# Note: Get-NetAdapter is not available on Windows Server 2008 R2
netsh interface show interface

netsh interface set interface name="Local Area Connection" newname="LAN 1 - 192.168.10.x"

netsh interface set interface name="Local Area Connection 2" newname="iSCSI 1 - 10.1.10.x"
```

**# Configure static IP address**

```PowerShell
$ipAddress = "192.168.10.206"

# Note: New-NetIPAddress is not available on Windows Server 2008 R2

netsh interface ipv4 set address name="LAN 1 - 192.168.10.x" source=static address=$ipAddress mask=255.255.255.0 gateway=192.168.10.1

# Note: Set-DNSClientServerAddress is not available on Windows Server 2008 R2

netsh interface ipv4 set dnsserver name="LAN 1 - 192.168.10.x" source=static address=192.168.10.209

netsh interface ipv4 add dnsserver name="LAN 1 - 192.168.10.x" address=192.168.10.210
```

**# Configure iSCSI network adapter**

```PowerShell
$ipAddress = "10.1.10.206"

# Note: New-NetIPAddress is not available on Windows Server 2008 R2

netsh interface ipv4 set address name = "iSCSI 1 - 10.1.10.x" source=static address=$ipAddress mask=255.255.255.0

# Note: Disable-NetAdapterBinding is not available on Windows Server 2008 R2

# Disable "Client for Microsoft Networks"
C:\NotBackedUp\Public\Toolbox\nvspbind\x64\nvspbind.exe -d "iSCSI 1 - 10.1.10.x" ms_msclient

# Disable "File and Printer Sharing for Microsoft Networks"
C:\NotBackedUp\Public\Toolbox\nvspbind\x64\nvspbind.exe -d "iSCSI 1 - 10.1.10.x" ms_server

# Disable "Link-Layer Topology Discovery Mapper I/O Driver"
C:\NotBackedUp\Public\Toolbox\nvspbind\x64\nvspbind.exe -d "iSCSI 1 - 10.1.10.x" ms_lltdio

# Disable "Link-Layer Topology Discovery Responder"
C:\NotBackedUp\Public\Toolbox\nvspbind\x64\nvspbind.exe -d "iSCSI 1 - 10.1.10.x" ms_rspndr

$adapter = Get-WmiObject -Class "Win32_NetworkAdapter" `
    -Filter "NetConnectionId = 'iSCSI 1 - 10.1.10.x'"

$adapterConfig = Get-WmiObject -Class "Win32_NetworkAdapterConfiguration" `
    -Filter "Index= '$($adapter.DeviceID)'"

# Do not register this connection in DNS
$adapterConfig.SetDynamicDNSRegistration($false)

# Disable NetBIOS over TCP/IP
$adapterConfig.SetTcpipNetbios(2)
```

**# Enable jumbo frames**

```Console
# Note: Get-NetAdapterAdvancedProperty is not available on Windows Server 2008 R2

netsh interface ipv4 show interface

Idx     Met         MTU          State                Name
---  ----------  ----------  ------------  ---------------------------
  1          50  4294967295  connected     Loopback Pseudo-Interface 1
 11           5        1500  connected     LAN 1 - 192.168.10.x
 18           5        1500  connected     iSCSI 1 - 10.1.10.x


netsh interface ipv4 set subinterface "LAN 1 - 192.168.10.x" mtu=9014 store=persistent

netsh interface ipv4 set subinterface "iSCSI 1 - 10.1.10.x" mtu=9014 store=persistent
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C0/DE4A8BB73A26DFE80036F03F4C7DABC72A37BBC0.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AC/359C0F95AA7D36CDE70BDC5DD886BD1EE3ADB2AC.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F6/9E68B6EBF97963F60D76C8E4980983801510FEF6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7A/FE8CEE531A1335FD9A2FB2CC259BDBFCC42C687A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CE/AE20D522971A50AF377C36A3584DBB9B28BC42CE.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C5/A13511971496E3BFE5274A0A30715A4DF1D8DFC5.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/32/FC81C1D498BB7CEA8FAFD470A203A291B45DA132.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DB/AF8913DC9C0420A9AF7CBA3AC1DD8863096B8ADB.png)

```Console
ping ICEMAN -f -l 8900
ping 10.1.10.106 -f -l 8900
```

**Configure network binding order**

In the **Network Connections** window, press F10 to view the menu.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A9/1D564C0C36FAD89CB2968F7D66FB11629AB57FA9.png)

On the **Advanced** menu, click **Advanced Settings...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0D/E5027155CEEC2E17E4C82CD44D5F1027AE1B520D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/00/02EFAC1CA528D1624046A17ADF9E73611DE58300.png)

**Enable iSCSI Initiator**

Start -> iSCSI Initiator

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DF/3F6DE64EBF1E201BDD47D798802EEBB2C9A72CDF.png)

Click Yes.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5B/38F75FA3835C75B20A80D63314FE3463D9B3095B.png)

On the **Discovery** tab, click **Discover Portal...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/84/997A95199AEF4EA39C096740C00C6E13D59C4884.png)

In the **Discover Target Portal** window:

1. In the **IP address or DNS name** box, type **10.1.10.106**.
2. Ensure **Port** is set to the default (**3260**).
3. Click **OK**.

**Create iSCSI virtual disk**

| **Server** | **Volume** | **Name**            | **Size** | **Type of Disk**      | **iSCSI Target** |
| ---------- | ---------- | ------------------- | -------- | --------------------- | ---------------- |
| ICEMAN     | D:         | EXT-APP01A-Backup01 | 200 GB   | Dynamically expanding | ext-app01a       |

**Discover iSCSI target**

On the **Targets** tab, in the **Discovered targets** section, click **Refresh**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/09/A8F1E5BBD5A417A47338D1BD0297B91E6D993E09.png)

Click **Connect**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/46/7CDFE7D572FC3C9757931F3E92EC0FF91960FE46.png)

In the Connect To Target window:

1. Ensure **Add this connection to the list of Favorite Targets** is selected.
2. Click **OK**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8E/676F01175334589FD37136341694FE527B7B7B8E.png)

On the **Volumes and Devices** tab, click **Auto Configure**.

**Format the iSCSI disks**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/42/CD1C8CACA3A24D2F72443DED7A7B5F9B173D5842.png)

If the new iSCSI disk is not online, right-click **Disk 3** and then click **Online**. The status of the disk changes from **Offline** to **Not Initialized**. Right-click **Disk 3** and then click **Initialize Disk**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6D/E952250D05EC4D56782C6DB80016FE77C555A86D.png)

Right-click the unallocated space on **Disk 3** and click **New Simple Volume..**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/42/0430C4C9ABFCC78D659DCFA2D93713CEDD821A42.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3C/EDE929011CA1561163100E24EE587DBC6399A73C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E9/2774273E5E404C2340C3703898B4D093ACB0C0E9.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5D/D33ABF2949143677C27BDE804A496C423B38235D.png)

**Important:** When formatting the **Backup01** disk, specify **64K** for the allocation unit size.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/49/F75E1C2BFE0B7C638FB09A85FA13BA16220DC649.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BF/4B395F5AE3D2427E586F08CEBD64DAF81DBBCCBF.png)

**Create "Backups" share**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4E/823BF26C5F42FB037E466D30EB34D4124C75044E.png)

Click **Provision Share...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3C/F78B9DDB095EA0EDC34AF86A8793C741CC31DE3C.png)

Click **Browse...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CA/2E6DE516EA52A9136A346E249954531307AA12CA.png)

Click **Make New Folder**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/68/2A805F8A01ADE896559D8C595343BCC9DB424568.png)

Name the new folder **Backups**.\
Click **OK**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9D/55512937F5A60966E482EA4A6B4E688DE4F6C59D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CF/AA4FF7B3BA313CAFE0C72698433864EBF1F917CF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/66/FA1555DB549F1BCF8B16B3E9EB44DAAB09273366.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0C/1FE9D8EF915FB312882E7AB84FC601D4062C130C.png)

Click **Advanced...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/13/2BDA1926878A7975966BAD058A9FDCF3E1806313.png)

On the **Caching** tab, select **No files or programs from the share are available offline.**\
Click** OK**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/09/A4288111571D8CD16DD3C99DE08B2C387C2B3009.png)

Click **Permissions...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/24/763E1D2DCE66443D234971B96E107CCEC55FAB24.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FE/35DB2D089F6D9618BB9DB4BAAC7C6390C72A2FFE.png)

Click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/89/4BF65DE3C0279FD7E36CD4E9AB04365B43977389.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/39/8EF2D7A2AE85C8997E9A561506E23A85BA41DF39.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0E/081412CB772B8EABC0AE9A38DA4EC15E4FD2CA0E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/53/F6585B0153A15F31972CD84452A4B0F4BD2AAE53.png)

Click **Properties**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/76/231E01A8F36659CE7815A34E287E557353828E76.png)

On the **Permissions** tab, click **NTFS Permissions**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0C/C35D9BB07E6B9755AB1F6B4E05B43392ACAA770C.png)

Click **Advanced**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/53/43F83B3DD32EF58CC520F45CBB66D98468318C53.png)

Clear the **Include inheritable permissions from this objects's parent** checkbox.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9E/C242F782F1375197E18C6C4DB09F007C5F3DFB9E.png)

Click **Add**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CD/5BC19A15253B9F055304A6CC1E2530A71368C5CD.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D1/9FBD0E8DE442F3776C2A529EA0FB0D39EC581DD1.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0B/923CC971AD9518085EACCA6E3B24AA33B4582F0B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2C/955665CCEA971DC1E22546ABC925C29FBC5C852C.png)

Click the **Farm** checkbox and then click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0B/5C59583C20DDCE8EF17BA6D794BD9BDBEA46600B.png)

In the **Backup location** box, type [\\\\EXT-APP01A\\Backups](\\EXT-APP01A\Backups).

Click **Start Backup**.

**Upgrade to SecuritasConnect "v3.0 Sprint-11" release**

**Copy SecuritasConnect build to SharePoint server**

```Console
robocopy \\iceman\Builds\Securitas\ClientPortal\3.0.595.2 C:\NotBackedUp\Builds\Securitas\ClientPortal\3.0.595.2 /E
```

**Note:** 3.0.595.2 = "v3.0 Sprint-11"

**Backup the SharePoint farm**

**Remove previous versions of the SecuritasConnect WSPs**

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\3.0.591.0\DeploymentFiles\Scripts

& '.\Deactivate Features.ps1'

& '.\Retract Solutions.ps1'
```

**Note**\
Retracting solutions in a farm environment comprised of multiple SharePoint servers is performed using SharePoint timer jobs. Errors that occur while running the deployment timer jobs are not reported when retracting solutions using PowerShell. Consequently you need to use Central Administration to verify the solutions were successfully retracted from all servers in the farm.

[http://ext-app01a:22812/_admin/Solutions.aspx](http://ext-app01a:22812/_admin/Solutions.aspx)

```PowerShell
& '.\Delete Solutions.ps1'
```

**Install the new versions of the SecuritasConnect WSPs and activate the features**

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\3.0.595.2\DeploymentFiles\Scripts

& '.\Add Solutions.ps1'

& '.\Deploy Solutions.ps1'
```

**Note**\
Deploying solutions in a farm environment comprised of multiple SharePoint servers is accomplished using SharePoint timer jobs. Errors that occur while running the deployment timer jobs are not reported when deploying solutions using PowerShell. Consequently you need to use Central Administration to verify the solutions were successfully deployed to all servers in the farm.

[http://ext-app01a:22812/_admin/Solutions.aspx](http://ext-app01a:22812/_admin/Solutions.aspx)

```PowerShell
& '.\Activate Features.ps1'
```

**Configure trusted root authorities for LMS REST API**

```PowerShell
& '.\Configure Trusted Root Authorities.ps1'
```

**Configure the application settings for the LMS REST API**

**Upgrade to SecuritasConnect "v3.0 Sprint-12" release**

**Copy SecuritasConnect build to SharePoint server**

```Console
robocopy \\iceman\Builds\Securitas\ClientPortal\3.0.606.0 C:\NotBackedUp\Builds\Securitas\ClientPortal\3.0.606.0 /E
```

**Note:** 3.0.606.0 = "v3.0 Sprint-12"

**Backup the SharePoint farm**

**Remove previous versions of the SecuritasConnect WSPs**

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\3.0.595.2\DeploymentFiles\Scripts

& '.\Deactivate Features.ps1'

& '.\Retract Solutions.ps1'
```

**Note**\
Retracting solutions in a farm environment comprised of multiple SharePoint servers is performed using SharePoint timer jobs. Errors that occur while running the deployment timer jobs are not reported when retracting solutions using PowerShell. Consequently you need to use Central Administration to verify the solutions were successfully retracted from all servers in the farm.

[http://ext-app01a:22812/_admin/Solutions.aspx](http://ext-app01a:22812/_admin/Solutions.aspx)

```PowerShell
& '.\Delete Solutions.ps1'
```

**Install the new versions of the SecuritasConnect WSPs and activate the features**

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\3.0.606.0\DeploymentFiles\Scripts

& '.\Add Solutions.ps1'

& '.\Deploy Solutions.ps1'
```

**Note**\
Deploying solutions in a farm environment comprised of multiple SharePoint servers is accomplished using SharePoint timer jobs. Errors that occur while running the deployment timer jobs are not reported when deploying solutions using PowerShell. Consequently you need to use Central Administration to verify the solutions were successfully deployed to all servers in the farm.

[http://ext-app01a:22812/_admin/Solutions.aspx](http://ext-app01a:22812/_admin/Solutions.aspx)

```PowerShell
& '.\Activate Features.ps1'
```

**Upgrade to SecuritasConnect "v3.0 Sprint-14" release**

**Copy SecuritasConnect build to SharePoint server**

```Console
robocopy \\iceman\Builds\Securitas\ClientPortal\3.0.609.0 C:\NotBackedUp\Builds\Securitas\ClientPortal\3.0.609.0 /E
```

**Note:** 3.0.609.0 = "v3.0 Sprint-14"

**Backup the SharePoint farm**

Update Z:\\Backups\\Backups.txt

**Remove previous versions of the SecuritasConnect WSPs**

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\3.0.606.0\DeploymentFiles\Scripts

& '.\Deactivate Features.ps1'

& '.\Retract Solutions.ps1'
```

**Note**\
Retracting solutions in a farm environment comprised of multiple SharePoint servers is performed using SharePoint timer jobs. Errors that occur while running the deployment timer jobs are not reported when retracting solutions using PowerShell. Consequently you need to use Central Administration to verify the solutions were successfully retracted from all servers in the farm.

[http://ext-app01a:22812/_admin/Solutions.aspx](http://ext-app01a:22812/_admin/Solutions.aspx)

```PowerShell
& '.\Delete Solutions.ps1'
```

**Install the new versions of the SecuritasConnect WSPs and activate the features**

```PowerShell
cd C:\NotBackedUp\Builds\Securitas\ClientPortal\3.0.609.0\DeploymentFiles\Scripts

& '.\Add Solutions.ps1'

& '.\Deploy Solutions.ps1'
```

**Note**\
Deploying solutions in a farm environment comprised of multiple SharePoint servers is accomplished using SharePoint timer jobs. Errors that occur while running the deployment timer jobs are not reported when deploying solutions using PowerShell. Consequently you need to use Central Administration to verify the solutions were successfully deployed to all servers in the farm.

[http://ext-app01a:22812/_admin/Solutions.aspx](http://ext-app01a:22812/_admin/Solutions.aspx)

```PowerShell
& '.\Activate Features.ps1'
```

**Crawl error**

[http://client-dev.securitasinc.com](http://client-dev.securitasinc.com)\
This item could not be crawled because the repository did not respond within the specified timeout period. Try to crawl the repository at a later time, or increase the timeout value on the Proxy and Timeout page in search administration. You might also want to crawl this repository during off-peak usage times.

Add hosts entry for **client-dev.securitasinc.com **on** EXTAPP01A**:

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Add-Hostnames.ps1 `
    -IPAddress 192.168.10.206 `
    -Hostnames ext-app01a,client-dev.securitasinc.com
```

**Restore WSS_Content_SecuritasPortal from PROD backup**

Extend iSCSI virtual disk (**EXT-SQL01-Log01.vhdx**) from **25GB** (due to insufficient free space to restore backup)

## # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

```PowerShell
cls
```

## # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
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

```PowerShell
cls
```

## # Install and configure System Center Operations Manager

### # Create certificate for Operations Manager

#### # Create request for Operations Manager certificate

```PowerShell
& "C:\NotBackedUp\Public\Toolbox\Operations Manager\Scripts\New-OperationsManagerCertificateRequest.ps1"
```

#### Submit certificate request to the Certification Authority

**To submit the certificate request to an enterprise CA:**

1. On the computer hosting the Operations Manager feature for which you are requesting a certificate, start Internet Explorer, and browse to Active Directory Certificate Services site ([https://cipher01.corp.technologytoolbox.com/](https://cipher01.corp.technologytoolbox.com/)).
2. On the **Welcome** page, click **Request a certificate**.
3. On the **Advanced Certificate Request** page, click **Submit a certificate request by using a base-64-encoded CMC or PKCS #10 file, or submit a renewal request by using a base-64-encoded PKCS #7 file.**
4. On the **Submit a Certificate Request or Renewal Request** page, in the **Saved Request** text box, paste the contents of the certificate request generated in the previous procedure.
5. In the **Certificate Template** section, select the Operations Manager certificate template (**Technology Toolbox Operations Manager**), and then click **Submit**. When prompted to allow the digital certificate operation to be performed, click **Yes**.
6. On the **Certificate Issued** page, click **Download certificate** and save the certificate.

```PowerShell
cls
```

#### # Import the certificate into the certificate store

```PowerShell
$certFile = "C:\Users\jjameson-admin\Downloads\certnew.cer"

CertReq.exe -Accept $certFile

Remove-Item $certFile
```

```PowerShell
cls
```

### # Install SCOM agent

---

**FOOBAR8**

```PowerShell
cls
```

#### # Mount the Operations Manager installation media

```PowerShell
$imagePath = `
    '\\ICEMAN\Products\Microsoft\System Center 2012 R2' `
    + '\en_system_center_2012_r2_operations_manager_x86_and_x64_dvd_2920299.iso'

Set-VMDvdDrive -ComputerName ANGEL -VMName EXT-APP01A -Path $imagePath
```

---

```PowerShell
$msiPath = 'X:\agent\AMD64\MOMAgent.msi'

msiexec.exe /i $msiPath `
    MANAGEMENT_GROUP=HQ `
    MANAGEMENT_SERVER_DNS=jubilee.corp.technologytoolbox.com `
    ACTIONS_USE_COMPUTER_ACCOUNT=1
```

```PowerShell
cls
```

### # Import the certificate into Operations Manager using MOMCertImport

```PowerShell
$hostName = ([System.Net.Dns]::GetHostByName(($env:computerName))).HostName

$certImportToolPath = 'X:\SupportTools\AMD64'

Push-Location "$certImportToolPath"

.\MOMCertImport.exe /SubjectName $hostName

Pop-Location
```

---

**FOOBAR8**

```PowerShell
cls
```

### # Remove the Operations Manager installation media

```PowerShell
Set-VMDvdDrive -ComputerName ANGEL -VMName EXT-APP01A -Path $null
```

---

### # Approve manual agent install in Operations Manager

```PowerShell
cls
```

## # Configure VSS permissions for SharePoint Search

### Alert

_Source: VSS_\
_Event ID: 8193_\
_Event Category: 0_\
_User: N/A_\
_Computer: EXT-APP01A.extranet.technologytoolbox.com_\
_Event Description: Volume Shadow Copy Service error: Unexpected error calling routine RegOpenKeyExW(-2147483646,SYSTEM\\CurrentControlSet\\Services\\VSS\\Diag,...). hr = 0x80070005, Access is denied._\
_._

_Operation:_\
_Initializing Writer_

_Context:_\
_Writer Class Id: {0ff1ce14-0201-0000-0000-000000000000}_\
_Writer Name: OSearch14 VSS Writer_\
_Writer Instance ID: {ebc9810a-18ae-4f9e-ad6f-f3802faf1dd8}_

### Solution

```PowerShell
$serviceAccount = "EXTRANET\svc-sharepoint"

New-ItemProperty `
    -Path HKLM:\SYSTEM\CurrentControlSet\Services\VSS\VssAccessControl `
    -Name $serviceAccount `
    -PropertyType DWord `
    -Value 1 | Out-Null

$acl = Get-Acl HKLM:\SYSTEM\CurrentControlSet\Services\VSS\Diag
$rule = New-Object System.Security.AccessControl.RegistryAccessRule(
    $serviceAccount, "FullControl", "ContainerInherit", "None", "Allow")

$acl.SetAccessRule($rule)
Set-Acl -Path HKLM:\SYSTEM\CurrentControlSet\Services\VSS\Diag -AclObject $acl
```

```PowerShell
cls
```

## # Resolve WMI error after every reboot

### Alert

_Source: WinMgmt_\
_Event ID: 10_\
_Event Category: 0_\
_User: N/A_\
_Computer: EXT-APP01A.extranet.technologytoolbox.com_\
_Event Description: Event filter with query "SELECT * FROM __InstanceModificationEvent WITHIN 60 WHERE TargetInstance ISA "Win32_Processor" AND TargetInstance.LoadPercentage > 99" could not be reactivated in namespace "//./root/CIMV2" because of error 0x80041003. Events cannot be delivered through this filter until the problem is corrected._

### Reference

**Event ID 10 is logged in the Application log after you install Service Pack 1 for Windows 7 or Windows Server 2008 R2**\
From <[https://support.microsoft.com/en-us/kb/2545227](https://support.microsoft.com/en-us/kb/2545227)>

### Solution

---

**VBScript**

```PowerShell
strComputer = "."

Set objWMIService = GetObject("winmgmts:" _
  & "{impersonationLevel=impersonate}!\\" _
  & strComputer & "\root\subscription")

Set obj1 = objWMIService.ExecQuery("select * from __eventfilter where name='BVTFilter' and query='SELECT * FROM __InstanceModificationEvent WITHIN 60 WHERE TargetInstance ISA ""Win32_Processor"" AND TargetInstance.LoadPercentage > 99'")

For Each obj1elem in obj1
  set obj2set = obj1elem.Associators_("__FilterToConsumerBinding")
  set obj3set = obj1elem.References_("__FilterToConsumerBinding")

  For each obj2 in obj2set
    WScript.echo "Deleting the object"
    WScript.echo obj2.GetObjectText_

    obj2.Delete_
  Next

  For each obj3 in obj3set
    WScript.echo "Deleting the object"
    WScript.echo obj3.GetObjectText_

    obj3.Delete_
  Next

  WScript.echo "Deleting the object"
  WScript.echo obj1elem.GetObjectText_

  obj1elem.Delete_
Next
```

---

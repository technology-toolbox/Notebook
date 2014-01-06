# JUBILEE - Windows Server 2012 R2 Standard

Sunday, January 05, 2014
10:52 AM

```Console
12345678901234567890123456789012345678901234567890123456789012345678901234567890

PowerShell
```

## # [BEAST] Create virtual machine

```PowerShell
$vmName = "JUBILEE"

New-VM `
    -Name $vmName `
    -Path C:\NotBackedUp\VMs `
    -MemoryStartupBytes 2GB `
    -SwitchName "Virtual LAN 2 - 192.168.10.x"

Set-VMProcessor -VMName $vmName -Count 2

Set-VMMemory `
    -VMName $vmName `
    -DynamicMemoryEnabled $true `
    -MaximumBytes 6GB

New-Item -ItemType Directory "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks"

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

$sysPrepedImage = "\\ICEMAN\VM-Library\VHDs\WS2012-R2-STD.vhdx"

Copy-Item $sysPrepedImage $vhdPath

Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath

Start-VM $vmName
```

Configure server settings

On the **Settings** page:

1. Ensure the following default values are selected:
   1. **Country or region: United States**
   2. **App language: English (United States)**
   3. **Keyboard layout: US**
2. Click **Next**.
3. Type the product key and then click **Next**.
4. Review the software license terms and then click **I accept**.
5. Type a password for the built-in administrator account and then click **Finish**.

## # Rename the server and join domain

```PowerShell
Rename-Computer -NewName JUBILEE -Restart
```

Wait for the VM to restart and then execute the following command to join the **TECHTOOLBOX **domain:

```PowerShell
Add-Computer -DomainName corp.technologytoolbox.com -Restart
```

## # Change drive letter for DVD-ROM

```PowerShell
# To change the drive letter for the DVD-ROM using PowerShell:

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

## # Rename network connection

```PowerShell
Get-NetAdapter -Physical

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "LAN 1 - 192.168.10.x"
```

## # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name "LAN 1 - 192.168.10.x" `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping ICEMAN -f -l 8900
```

```PowerShell
cls
```

## # Add SCOM Administrators domain group to local Administrators group

```PowerShell
$group = [ADSI]"WinNT://./Administrators,group"
$group.Add("WinNT://TECHTOOLBOX/Operations Manager Admins")
```

**Note:** "net localgroup ... /add" is simpler, but it doesn't work with long group names

Reference:\
[http://serverfault.com/questions/21826/net-localgroup-add-group-with-spaces-and-ampersand](http://serverfault.com/questions/21826/net-localgroup-add-group-with-spaces-and-ampersand)

## Install SCOM prerequisites

```PowerShell
cls
```

### # Install .NET Framework 3.5

```PowerShell
Install-WindowsFeature `
    NET-Framework-Core `
    -Source '\\ICEMAN\Products\Microsoft\Windows Server 2012 R2\Sources\SxS'
```

### Install SQL Server Reporting Services

**Note:** .NET Framework 3.5 is required for SQL Server Reporting Services.

#### Reference

**Set up SQL Server for TFS**\
Pasted from <[http://msdn.microsoft.com/en-us/library/jj620927.aspx](http://msdn.microsoft.com/en-us/library/jj620927.aspx)>

```PowerShell
cls
```

#### # [BEAST] Insert SQL Server 2012 ISO image into VM

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\SQL Server 2012\" `
    + "en_sql_server_2012_enterprise_edition_with_service_pack_2_x64_dvd_4685849.iso"

Set-VMDvdDrive -VMName JUBILEE -Path $imagePath
```

```PowerShell
cls
```

#### # Install SQL Server 2012 Reporting Services

```PowerShell
X:\setup.exe
```

On the **Feature Selection** step, select **Reporting Services - Native**.

On the **Server Configuration** step, on the **Service Accounts** tab:

- In the **Account Name** column for **SQL Server Reporting Services**, type **NT AUTHORITY\\NETWORK SERVICE**.
- In the **Startup Type** column for **SQL Server Reporting Services**, ensure **Automatic** is selected.

### Configure SQL Server Reporting Services

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
    1. In the **Action** pane, ensure **Create a new report server database** is selected, and then click **Next**.
    2. In the **Database Server** pane, type the name of the database server (**HAVOK**) in the **Server Name** box, click **Test Connection** and confirm the test succeeded, and then click **Next**.
    3. In the **Database **pane, type the name of the database (**ReportServer_SCOM**) in the **Database Name** box and then click **Next**.
    4. In the **Credentials **pane, ensure **Authentication Type** is set to **Service Credentials** and then click **Next**.
    5. On the **Summary** page, verify the information is correct, and then click **Next**.
    6. Click **Finish** to close the wizard.
11. In the navigation pane, click **Report Manager URL**.
12. In the **Report Manager URL **pane:
    1. Confirm the following warning message appears:
    2. Click **Apply**.
13. In the navigation pane, click **Encryption Keys**.
14. In the **Encryption Keys **pane, click **Backup**.
15. In the **Backup Encryption Key** window:
    1. In the **File Location **box, specify the location where you want to store a copy of this key.
    2. In the **Password** box, type a password for the file.
    3. In the **Confirm Password** box, retype the password for the file.
    4. Click **OK**.

Report Server Web Service is not configured. Default values have been provided to you. To accept these defaults simply press the Apply button, else change them and then press Apply.

The Report Manager virtual directory name is not configured. To configure the directory, enter a name or use the default value that is provided, and then click Apply.

> **Important**
>
> Store the key on a separate computer from the one that is running Reporting Services.

**[\\\\iceman\\Users\$\\jjameson-admin\\Documents\\Reporting Services - JUBILEE.snk](\\iceman\Users$\jjameson-admin\Documents\Reporting Services - JUBILEE.snk)**

```PowerShell
cls
```

### # Install IIS

```PowerShell
Install-WindowsFeature `
    NET-WCF-HTTP-Activation45, `
    Web-Static-Content, `
    Web-Default-Doc, `
    Web-Dir-Browsing, `
    Web-Http-Errors, `
    Web-Http-Logging, `
    Web-Request-Monitor, `
    Web-Filtering, `
    Web-Stat-Compression, `
    Web-Mgmt-Console, `
    Web-Metabase, `
    Web-Asp-Net, `
    Web-Windows-Auth `
    -Source '\\ICEMAN\Products\Microsoft\Windows Server 2012 R2\Sources\SxS' `
    -Restart
```

**Note:** HTTP Activation is required but is not included in the list of prerequisites on TechNet.

#### Reference

[http://technet.microsoft.com/en-us/library/dn249696.aspx#BKMK_RBF_WebConsole](http://technet.microsoft.com/en-us/library/dn249696.aspx#BKMK_RBF_WebConsole)

### Create IIS Website for System Center

Using DNS Manager, create a new alias (CNAME record) for the System Center website:

Alias name: **systemcenter**\
Full qualified domain name (FQDN) for target host: **JUBILEE.corp.technologytoolbox.com**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/68/8FBD746FF190C41613B03EE6826A1ADEB6E61168.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D9/7D1658A4C2D1D6CC73D9C37E26E0BC51158218D9.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7B/6A8E8851FB501840F2C15C73066DE3D3D89B0A7B.png)

```Console
mkdir C:\inetpub\wwwroot\SystemCenter
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B6/9120D04F8AF1562877204935DB6DAA64B2AB1FB6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/57/B897FBB030C747EE57509B566F39BD25CC542757.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B2/94872097D3B3C0F76EA6D4451902D58764C958B2.png)

Click **No**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CD/BC0B0D2896C2FE7738289B408E3BBB9B51A2E3CD.png)

Right-click **Sites** and then click **Add Website...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FF/49B7A8AA613933C965FFFB2E0EC063A986D239FF.png)

```PowerShell
cls
```

### # Install Microsoft System CLR Types for SQL Server 2012

## & "\\\\iceman\\Products\\Microsoft\\System Center 2012 R2\\Microsoft System CLR Types for SQL Server 2012\\SQLSysClrTypes.msi"

```PowerShell
cls
```

### # Install Microsoft Report Viewer Runtime

& "[\\\\iceman\\Products\\Microsoft\\System Center 2012 R2\\Microsoft Report Viewer Runtime\\ReportViewer.msi](\\iceman\Products\Microsoft\System Center 2012 R2\Microsoft Report Viewer Runtime\ReportViewer.msi)"

## [HAVOK] Create temporary firewall rules on database server for SCOM 2012 installation

**SCOM 2012 - Installing Operations Manager Database on server behind a firewall**\
Pasted from <[http://social.technet.microsoft.com/Forums/systemcenter/en-US/6c3dc8ff-4f66-4c73-9c9e-4ca948cde3ff/scom-2012-installing-operations-manager-database-on-server-behind-a-firewall?forum=operationsmanagerdeployment](http://social.technet.microsoft.com/Forums/systemcenter/en-US/6c3dc8ff-4f66-4c73-9c9e-4ca948cde3ff/scom-2012-installing-operations-manager-database-on-server-behind-a-firewall?forum=operationsmanagerdeployment)>

Add "temporary" firewall rules for SCOM 2012 installation:

Name: **SCOM 2012 Installation - TCP**\
Protocol:** TCP**\
Local Port:** 135, 445, 49152-65535**\
Profile: **Domain**\
Direction: **Inbound**\
Action: **Allow**

Name: **SCOM 2012 Installation - UDP**\
Protocol:** UDP**\
Local Port:** 137**\
Profile: **Domain**\
Direction: **Inbound**\
Action: **Allow**

```PowerShell
New-NetFirewallRule `
    -DisplayName "SCOM 2012 Installation - TCP" `
    -Protocol "TCP" `
    -LocalPort "135", "445", "49152-65535" `
    -Profile Domain `
    -Direction Inbound `
    -Action Allow

New-NetFirewallRule `
    -DisplayName "SCOM 2012 Installation - UDP" `
    -Protocol "UDP" `
    -LocalPort "137" `
    -Profile Domain `
    -Direction Inbound `
    -Action Allow
```

## # Install Operations Manager

```PowerShell
cls
```

#### # [BEAST] Insert SCOM 2012 ISO image into VM

```PowerShell
$imagePath = "\\iceman\Products\Microsoft\System Center 2012 R2\" `
    + "en_system_center_2012_r2_operations_manager_x86_and_x64_dvd_2920299.iso"

Set-VMDvdDrive -VMName JUBILEE -Path $imagePath
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/06/37E3980F82E21B260ABBA2EA5CC5232317A21C06.png)

Select **Download the latest updates to the setup program** and then click **Install**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3B/0D64CEC89947B224EFFB7A4C1E1534EE19669A3B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/70/29E74E615134A7149BA55A753F7231DA754B8170.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FB/280631F22B118ABE9EA449D74EBD600795A54BFB.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F4/F7482DA8797247106FB4B7562A03B35E1775A9F4.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EA/6B3BBD97A8DE48D64AE5FCD6C53DA172F08179EA.png)

Click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7A/84CBF49FE524E539D7A16C968076D7E84D99FE7A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/57/09444DEA7BAA842EEC7E79802D4AE70086CB6257.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/56/C0589C026CEA4BD0773A70E960F5EF3994C1ED56.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AD/A57132621078BBE6D7777D10B8C550F407B9D8AD.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8A/BF536A1216473E26DC633B0B89FE70B459DA5E8A.png)

Press Tab to connect to the database server.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1E/AF80EE7EA595294686C1D35B6424199EDF1CE11E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7B/7A3CC1DB068B1BE12DAAB602014FC35A92745A7B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/94/5FD3C5C7C3594B7BCF79148BA6975B232743D994.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EA/71B1EDC1F91D709A6032DB6988C5AFE5456EB0EA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/14/B8BCDD8946EB62F2D4B73B91728A6253F8C20414.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DC/9F3D1CFA49E5CE33114AC56312C4C50D6C7AA8DC.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8C/5D06F0E8094EA01126252D515F76FC5F5B28E18C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FF/7E47881C2E96CD9774BC85984E7E436C02E360FF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/22/DD519A5F991933B895B28B8B3EEE7F5DBAEB3C22.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DA/894078AB6ED377D40A9E4559CE8324DAE53C21DA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5C/C5F7E9F4EAEF06B695CCDBEE690244601E7CD35C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/08/75B28D59F45DA77D9EB209A99FD259CFB3F61108.png)

## # [HAVOK] Disable temporary firewall rules on database server

```PowerShell
Disable-NetFirewallRule -DisplayName "SCOM 2012 Installation - TCP"
Disable-NetFirewallRule -DisplayName "SCOM 2012 Installation - UDP"
```

## Create SMTP Channel

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BA/38B9E25E6660CD5F5F60EC28E23FCD694D75EABA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A3/019E525F37F25924ED5BDEFAED9337C4B07190A3.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/09/541E7DFC17496D687D0936A4316AF49FFA2C5009.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1B/7F86DFDA7287D581B56138123702FACF62BC211B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/81/1D8E8796D2FF93578EE3EFF05DA7F8A24D64C081.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E2/DFB3538463AF8CE1B80383AE6329A8CC76B996E2.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/22/ECCB260F0CE32376E509148ED80DE493140D2C22.png)

Click **Finish** to accept the defaults.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AF/F61F15BEEB94F6FCDEA245B17CC7FABB48B89FAF.png)

## Create a new subscriber

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C8/36A4E83F5B9808EBE18CBBEDD092D50FCE5323C8.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2E/44F940D5CD5C7C74986FD878E4C45DCF286FA72E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/76/486C19FEA382F5E044B1CD4C2D4657F3A0EBB076.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9C/52750BFBF80CFF6AB8DB3D8DE294DC010162879C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CA/FC52C7AC1621B9772DCA96D758AEFE7068B015CA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/39/19801DDBBF87992063843EC24130D0E960605139.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/52/21B0319D3735E725C6192304D0E781BB4164B252.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/60/E05C3808A4F8B078D55C2C19161F507CB47E4C60.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A3/BC52D5E2FD74293AF9EDEF307DC5975D5E2395A3.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/75/AFCB05358312A70AAEE893D7E1B92D1DA15AD275.png)

## Create subscription

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0B/658751BA60B977CD3DC68BADC6477CAE7093430B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E3/70750A400596BFDAF86EEDB2AD339C8482CB63E3.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6E/060F2F9F49287E844FCE4FD981FD1E0163B74F6E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5C/72E51D5737E28B6A4253AC55420788223A103C5C.png)

Click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A2/1DA51C0052725495428B9C7BAA41786EE36906A2.png)

Click **Add...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0E/B73537AD69CF0B9AA7B406B07289B454756B4C0E.png)

Click **Search**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/72/1F95EFEBABF10D1D8F962FFE57077CAAFA410972.png)

Select the subscriber, click **Add **to move it to the **Selected subscribers** list, and then click **OK**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C7/8EF3A8B683AD3EBEDE55D7DF56AFDE832F3D5FC7.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C6/0C667CFC5C473A69BC57DEC4209C4F9265C196C6.png)

Click **Add...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2E/B0521D941540E599AAC3D4679E3109965A0D412E.png)

Click **Search**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7A/93793B9AA623507D8134C1C95904E9E33978097A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/40/FE1B71529B27D0BDB2AA0D227D1489A984D35C40.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/53/A5C0BA7905200EA4E817683551EFB79306441C53.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FA/C852A20D1934A1E634B3F738E233C626D89826FA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2F/6707E1F4E350507E849BA75B7F599B520313CE2F.png)

## Import management packs

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0F/9179881C54AE5ADD73F3C5883399A0F4AB86DD0F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CC/230EADBEB038D883B242C4C7D63BF019FB463FCC.png)

Click **Add** and then click **Add from catalog...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A4/8D9865AC9F0EE48E64C9920B67894CB530A802A4.png)

Click **Search**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/25/87EC6B1C4710F2A67C9BBE557904E78F30A8CE25.png)

In the **Management packs in the catalog** list, expand **Microsoft Corporation**.

- Microsoft Corporation
  - ~~Office Servers~~
    - ~~SharePoint 2010 Products~~
      - ~~Microsoft.SharePoint.Foundation.2010~~
      - ~~Microsoft.SharePoint.Server.2010~~
  - ~~SQL Server~~
    - ~~SQL Server 2012~~
      - ~~SQL Server 2012 (Discovery)~~
      - ~~SQL Server 2012 (Monitoring)~~
      - ~~SQL Server Core Library~~
  - Windows Server
    - ~~Active Directory Server 2008~~
      - ~~Active Directory Server 2008 and above (Discovery)~~
      - ~~Active Directory Server 2008 and above (Monitoring)~~
      - ~~Active Directory Server Common Library~~
    - Core OS
      - Windows Server 2003 Operating System
      - Windows Server 2008 Operating System (Discovery)
      - Windows Server 2008 Operating System (Monitoring)
      - Windows Server 2012 R2 Operating System (Discovery)
      - Windows Server 2012 R2 Operating System (Monitoring)
      - Windows Server Operating System Library
      - Windows Server Operating System Reports
    - ~~DHCP Server~~
      - ~~Microsoft Windows Server DHCP 2012 R2~~
      - ~~Microsoft Windows Server DHCP Library~~
    - ~~Domain Naming Service 2012/2012R2~~
      - ~~Microsoft Windows Server DNS Monitoring~~
    - ~~File Services 2012 R2~~
      - ~~File Services Management Pack for Windows Server 2012 R2~~
      - ~~File Services Management Pack Library~~
      - ~~Microsoft Windows Server iSCSI Target 2012 R2~~
      - ~~Microsoft Windows Server SMB 2012 R2~~
    - Hyper-V 2012 R2\
      Microsoft Windows Hyper-V 2012 R2 Discovery\
      Microsoft Windows Hyper-V 2012 R2 Monitoring\
      Microsoft Windows Hyper-V 2012 Library
    - IIS 2008
      - Windows Server 2008 Internet Information Services 7
      - Windows Server Internet Information Services Library
    - IIS 2012
      - Windows Server 2012 Internet Information Services 8
      - Windows Server Internet Information Services Library
    - ~~Windows Update Services 3.0~~
      - ~~Windows Server Update Services 3.0~~
      - ~~Windows Server Update Services Core Library~~

![(screenshot)](https://assets.technologytoolbox.com/screenshots/80/FB0EAC5FEEE3FCFAD1BA6069A548282A5BCA8A80.png)

For each item that has a dependency that is not selected, click the **Resolve** link in the **Status** column.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/24/4F5557A0C72FE1C68B1A5FE442CD505CD55B8724.png)

Repeat the previous steps the remaining warnings.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E5/164040C845789192961A9CC4449A5FEE1F378EE5.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4B/38B20AA8EA4687C442EB78271EC75851E7EF9F4B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B5/9E9BCA6F0219FF7883F8CAD1AE0C05FB4796FCB5.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/90/5F6FA540FA70D9AFDACDBD4776905EB848AA2690.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/34/4825B66027B732F667683B1E977A97A118A42134.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F2/9D1929615F59AA193F7EE2721F97F25F92A302F2.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/22/3A51E67ED6C362EFC843A89A29C874B65A91EB22.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AB/5E7D8C09EDF2B5FC6C221CDA06104452CA005CAB.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EB/58FB48553F9BFF8EB95B7B119CDA07D667E1E7EB.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E6/70D7B5750939AB5997FBA07EA2015E22A80928E6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CC/230EADBEB038D883B242C4C7D63BF019FB463FCC.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F2/52C4FD5D62E9C42735CE0EA07E0A9177B3AFE9F2.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C3/4DF720BACFD9079A943A207842044715A4113EC3.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/10/A9200A55DC3A9C5FB451B7A6ECE1D0DFC164F910.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/03/2F1FC208D4B63E76E23123F871A9234A4E74FB03.png)

## Configure security settings for manual agent installations

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A4/E46318ED283C00A3BE5D3CF77CAA6FCB130AE6A4.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9C/EF4C7D4779C2030A7A880D33F06358763386279C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/20/8474378C09FE370A1213FE8E37352E7DB032BD20.png)

## Create rules to generate SCOM alerts for event log errors

**Operations Manager Alerts for Event Log Errors**\
Pasted from <[http://www.technologytoolbox.com/blog/jjameson/archive/2011/03/18/operations-manager-alerts-for-event-log-errors.aspx](http://www.technologytoolbox.com/blog/jjameson/archive/2011/03/18/operations-manager-alerts-for-event-log-errors.aspx)>

## Install SCOM agent on computers to manage

## Configure domain controllers to manage

![(screenshot)](https://assets.technologytoolbox.com/screenshots/02/A71E4F54079FD0B2DB85A4FC0CB78F761EB46C02.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F5/73A4F65DD992BCF8CA070E4938A0FDFED809B2F5.png)

In the **Agent Properties** window, on the **Security** tab, select **Allow this agent to act as a proxy and discover managed objects on other computers** and then click **OK**.

## # Register Service Principal Name for System Center Operations Manager

```PowerShell
setspn -A MSOMSdkSvc/JUBILEE JUBILEE
setspn -A MSOMSdkSvc/JUBILEE.corp.technologytoolbox.com JUBILEE
```

## Reinstall SCOM Web console on Default Web Site (to fix host header issue)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/04/957734D4961E603EED70C32014A2EEACB3B87904.png)

Alert: Application Event Log Error
Source: ROGUE.corp.technologytoolbox.com
Path: Not Present
Last modified by: TECHTOOLBOX\\jjameson-admin
Last modified time: 1/13/2014 5:31:43 AM
Alert description: Source: Microsoft-Windows-User Profiles Service
Event ID: 1504
Event Category: 0
User: TECHTOOLBOX\\jjameson-admin
Computer: ROGUE.corp.technologytoolbox.com
Event Description: Windows cannot update your roaming profile completely. Check previous events for more details.\
Alert view link: ["http://]("http://)[JUBILEE](JUBILEE)[/OperationsManager?DisplayMode=Pivot&AlertID=%7b3e7f44b2-19e9-460e-a269-5290785e86e4%7d"](/OperationsManager?DisplayMode=Pivot&AlertID=%7b3e7f44b2-19e9-460e-a269-5290785e86e4%7d")
Notification subscription ID generating this message: {78899052-4C1D-3C2D-98A5-63E603521E1C}

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C7/2023633C0FCB02B32B704184432933FD8E0618C7.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/93/1C6943F92C89D6814236B6A89D03C6801F9EE993.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C7/37D9327AAC329667BD00AE3B21223692D918B0C7.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/86/7D9EDA7FCD457FF912A6DDAD68C8F42769776686.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/82/4C03EAD48B78D69DF9D5A71754E909FB9DC40582.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F2/CFC09A0718271243BF49763DB54B7F036B60C8F2.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/91/1B66255365B2ABB457F7E7E1B0BCDDB8230A3991.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/11/0A8F715EE7CDAA58FD3BF8B3E94E6AA28EFF2311.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/89/9BF7028710BFC9898A2A38A721AF417DD17C5B89.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DC/9F3D1CFA49E5CE33114AC56312C4C50D6C7AA8DC.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C1/98C19CEFE4312B7B2D45BDCAAF84A9008D23EFC1.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1D/35AEFB18B01B6C0AFF7B245CEB6B4DA8AFD0FC1D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BA/CB42C174DEC82A8833FD526BDD0DAE886F7D2DBA.png)

Click **Cancel**. Repeat process by running **Setup.exe** from Operations Manager ISO file.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9E/1956F410F3F21CEC95AC34E829AC9B4351B5E89E.png)

In IIS Manager, right-click **Sites** -> **System Center Web Site** and then click **Remove**.

```Console
rmdir C:\inetpub\wwwroot\SystemCenter
```

## # Install DPM 2012 R2 agent

```PowerShell
$imagePath = "\\iceman\Products\Microsoft\System Center 2012 R2\" `
    + "mu_system_center_2012_r2_data_protection_manager_x86_and_x64_dvd_2945939.iso"

$imageDriveLetter = (Mount-DiskImage -ImagePath $imagePath -PassThru |
    Get-Volume).DriveLetter

$installer = $imageDriveLetter + ":\SCDPM\Agents\DPMAgentInstaller_x64.exe"

& $installer JUGGERNAUT.corp.technologytoolbox.com
```

Review the licensing agreement. If you accept the Microsoft Software License Terms, select **I accept the license terms and conditions**, and then click **OK**.

Confirm the agent installation completed successfully and the following firewall exceptions have been added:

- Exception for DPMRA.exe in all profiles
- Exception for Windows Management Instrumentation service
- Exception for RemoteAdmin service
- Exception for DCOM communication on port 135 (TCP and UDP) in all profiles

### Reference

**Installing Protection Agents Manually**\
Pasted from <[http://technet.microsoft.com/en-us/library/hh757789.aspx](http://technet.microsoft.com/en-us/library/hh757789.aspx)>

## Attach DPM agent

On the DPM server (JUGGERNAUT), open **DPM Management Shell**, and run the following commands:

```PowerShell
$productionServer = "JUBILEE"

.\Attach-ProductionServer.ps1 `
    -DPMServerName JUGGERNAUT `
    -PSName $productionServer `
    -Domain TECHTOOLBOX `-UserName jjameson-admin
```

## Modify custom SCOM rule to filter out "noise"

Log Name:      Application\
Source:        Microsoft-Windows-Perflib\
Date:          1/15/2014 5:03:43 AM\
Event ID:      1008\
Task Category: None\
Level:         Error\
Keywords:      Classic\
User:          N/A\
Computer:      POLARIS.corp.technologytoolbox.com\
Description:\
The Open Procedure for service "WmiApRpl" in DLL "C:\\Windows\\system32\\wbem\\wmiaprpl.dll" failed. Performance data for this service will not be available. The first four bytes (DWORD) of the Data section contains the error code.\
Event Xml:\
<Event xmlns="[http://schemas.microsoft.com/win/2004/08/events/event](http://schemas.microsoft.com/win/2004/08/events/event)">\
  `<System>`\
    `<Provider Name="Microsoft-Windows-Perflib" Guid="{13B197BD-7CEE-4B4E-8DD0-59314CE374CE}" EventSourceName="Perflib" />`\
    `<EventID Qualifiers="49152">`1008`</EventID>`\
    `<Version>`0`</Version>`\
    `<Level>`2`</Level>`\
    `<Task>`0`</Task>`\
    `<Opcode>`0`</Opcode>`\
    `<Keywords>`0x80000000000000`</Keywords>`\
    `<TimeCreated SystemTime="2014-01-15T12:03:43.000000000Z" />`\
    `<EventRecordID>`2486`</EventRecordID>`\
    `<Correlation />`\
    `<Execution ProcessID="0" ThreadID="0" />`\
    `<Channel>`Application`</Channel>`\
    `<Computer>`POLARIS.corp.technologytoolbox.com`</Computer>`\
    `<Security />`\
  `</System>`\
  `<UserData>`\
    `<EventXML xmlns="Perflib">`\
      `<param1>`WmiApRpl`</param1>`\
      `<param2>`C:\\Windows\\system32\\wbem\\wmiaprpl.dll`</param2>`\
      `<binaryDataSize>`8`</binaryDataSize>`\
      `<binaryData>`1500000000000000`</binaryData>`\
    `</EventXML>`\
  `</UserData>`\
`</Event>`

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B9/A6DFA734136FDDDE3049272676CB38955F7EE3B9.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/65/31DC78C1840A24293BD1C724F91073F9FEEF1E65.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/10/7A31127D5E67BBD105244AA781AD7347474D5B10.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8C/8F3529A65F2097D8482DA5F0C09048ACC419B28C.png)

Click **Insert**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1F/90EA690F84853B61E0F130B8B3A6A0AB771FF01F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/46/E0F97346F89637D504B42933DFE53464E66B3646.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/55/EACFC170659AED391B61E7631CD34385E7306855.png)

Click **OK**.

On the **Application Event Log Error Properties** window, click **OK**.

Repeat the steps above for the **System Event Log Error** rule.

## Import DPM management packs

1. Mount the DPM 2012 R2 DVD.
2. Import the following management packs from **D:\\SCDPM\\ManagementPacks\\en-US**:
3. **Microsoft.SystemCenter.DataProtectionManager.2012.Discovery.mp**
4. **Microsoft.SystemCenter.DataProtectionManager.2012.Library.mp**

## Resolve SCOM alerts due to disk fragmentation

### Alert Name

Logical Disk Fragmentation Level is high

### Alert Description

The disk C: (C:) on computer JUBILEE.corp.technologytoolbox.com has high fragmentation level. File Percent Fragmentation value is 13%. Defragmentation recommended: true.

### Resolution

#### # Copy Toolbox content

```PowerShell
robocopy \\iceman\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E
```

#### # Create scheduled task to optimize drives

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

## Change SMTP channel for Operations Manager

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DF/68F1C036941ED40C37AA999B56A3C8B6AFCCE9DF.png)

Fix Web address in notification emails

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F6/3A8AC3D6E6A9F3212455443048C14FDB630090F6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/46/BFE63FA980FEF9DEB949523E48F5B472EA989E46.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/40/1108A7087A63B2F799619CDE7F7B07AAF168E140.png)

## Add members to Operations Manager Operators role

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C6/7FB8DB73BC23FCFAD76219277D823AA43B9128C6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CE/6F06FEA17EB738564002BAA2C49BDF48F8E833CE.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/27/5DA365DEF6C85A7CC416DBFC9FA982884AA53327.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/60/66C5207B1368AB4EF8325D05BFFFF79028A72B60.png)

## # Configure firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

---

**FOOBAR8**

```PowerShell
$computer = 'JUBILEE'

$command = "New-NetFirewallRule ``
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

Invoke-Command -ComputerName $computer -ScriptBlock $scriptBlock
```

---

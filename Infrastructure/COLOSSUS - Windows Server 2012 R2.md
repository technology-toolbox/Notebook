# COLOSSUS (2014-01-18) - Windows Server 2012 R2 Standard

Saturday, January 18, 2014
6:03 AM

```Console
12345678901234567890123456789012345678901234567890123456789012345678901234567890

PowerShell
```

## # Create virtual machine

```PowerShell
$vmName = "COLOSSUS"

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
Rename-Computer -NewName COLOSSUS -Restart

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

## Add network adapter (Virtual iSCSI 1 - 10.1.10.x)

## # Rename network connections

```PowerShell
Get-NetAdapter -Physical

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "LAN 1 - 192.168.10.x"

Get-NetAdapter -InterfaceDescription "Microsoft Hyper-V Network Adapter #2" |
    Rename-NetAdapter -NewName "iSCSI 1 - 10.1.10.x"
```

## # Configure static IP address

```PowerShell
$ipAddress = "192.168.10.107"

New-NetIPAddress -InterfaceAlias "LAN 1 - 192.168.10.x" -IPAddress $ipAddress `
    -PrefixLength 24 -DefaultGateway 192.168.10.1

Set-DNSClientServerAddress -InterfaceAlias "LAN 1 - 192.168.10.x" `
    -ServerAddresses 192.168.10.103, 192.168.10.104
```

## # Configure iSCSI network adapter

```PowerShell
$ipAddress = "10.1.10.107"

New-NetIPAddress -InterfaceAlias "iSCSI 1 - 10.1.10.x" -IPAddress $ipAddress `
    -PrefixLength 24

Disable-NetAdapterBinding -Name "iSCSI 1 - 10.1.10.x" `
    -DisplayName "Client for Microsoft Networks"

Disable-NetAdapterBinding -Name "iSCSI 1 - 10.1.10.x" `
    -DisplayName "File and Printer Sharing for Microsoft Networks"

Disable-NetAdapterBinding -Name "iSCSI 1 - 10.1.10.x" `
    -DisplayName "Link-Layer Topology Discovery Mapper I/O Driver"

Disable-NetAdapterBinding -Name "iSCSI 1 - 10.1.10.x" `
    -DisplayName "Link-Layer Topology Discovery Responder"

$adapter = Get-WmiObject -Class "Win32_NetworkAdapter" `
    -Filter "NetConnectionId = 'iSCSI 1 - 10.1.10.x'"

$adapterConfig = Get-WmiObject -Class "Win32_NetworkAdapterConfiguration" `
    -Filter "Index= '$($adapter.DeviceID)'"

# Do not register this connection in DNS
$adapterConfig.SetDynamicDNSRegistration($false)

# Disable NetBIOS over TCP/IP
$adapterConfig.SetTcpipNetbios(2)
```

## # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty -Name "LAN 1 - 192.168.10.x" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

Set-NetAdapterAdvancedProperty -Name "iSCSI 1 - 10.1.10.x" `
    -DisplayName "Jumbo Packet" -RegistryValue 9014

ping BEAST -f -l 8900
```

## Enable iSCSI Initiator

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

## Create iSCSI virtual disk (COLOSSUS-Data01.vhdx)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FD/35948179ECB3BC7FA22D690DBEE24A4EC5DBFAFD.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B0/569F1BBCD4525007DCFE1B658079BAAC8F6F64B0.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6C/6CD939A15096C1906BE9CC4FE358F4B4AD2E746C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3F/05A25CCBDCA0F0AED86BA5494918EED66822143F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7A/BE3C7A3449B6754BDEF34757C19F23724774867A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F9/551ED6B2353BA8DA0BB0EA94E461B00FC07A63F9.png)

Click **Add...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9A/3DA08FFC9276D647578FA17AEEF106BD07C84D9A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/05/7CA097164F37CA941F185CC80C0581CEC3F37405.png)

On the **Enable Authentication **page, ensure **Enable CHAP** is not selected.

**Important:** Due to a bug in the Microsoft iSCSI initiator, CHAP must be configured after discovering the iSCSI target.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5C/0A833AE0E5E9405605C62188D085AEDA5858CD5C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/07/FC90D66DA8630DC746910515A397FFCCA1D20307.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EC/D5B7854904A97CBEC76E0BD052AEBDF4BA0753EC.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5E/7A05BEAEF9C8E3F003BBC60EEE8BACA57C20515E.png)

## Discover iSCSI target

![(screenshot)](https://assets.technologytoolbox.com/screenshots/62/80CE4F1C167F236B318DF200C0A528880D902362.png)

## Configure CHAP

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F8/8CEFECE34EA1FD776108D831654F18DE5094C5F8.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F3/709DC3807B523BD45ACED36CBE10726C856112F3.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F6/8927B45633AC9AF51073BF6371F12C873B6294F6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AC/BE8BEA07967FCA420D1C81D728CB20F23326A3AC.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F1/9A2299D396E2E704A0533325A88C98B20C7F25F1.png)

In the **Advanced Settings**, click OK.

In the **Discover Target Portal** window, click OK.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2B/E8270B6D7F65197153C60AC49AE09FB636D7C72B.png)

Click **OK**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0C/7A17A540838F0CE67D9267BB8EFC57635317700C.png)

Click **Connect**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4E/C146673DB42EE1644E9946303008D9A7927E7D4E.png)

Click **Advanced..**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C8/4BA8A9B6364BE7DE81693DE925DD9C42D6E064C8.png)

In the **Advanced Settings** window:

1. Select **Enable CHAP log on**.
2. In the Target secret box, type the CHAP secret for the iSCSI initiator.
3. Click **OK**.

In the Connect To Target window:

1. Ensure **Add this connection to the list of Favorite Targets** is selected.
2. Click **OK**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5D/BAAFBC84810C7FC00BF5172BCC5667FFE308A85D.png)

On the **Volumes and Devices** tab, click **Auto Configure**.

## Format the iSCSI disk

![(screenshot)](https://assets.technologytoolbox.com/screenshots/77/CB2FA98CA269FF756909607D86287D31A1085377.png)

Right-click **Disk 1** and then click **Online**. The status of the disk changes from **Offline** to **Not Initialized**.

Right-click **Disk 1** and then click **Initialize Disk**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B8/29131AA6EDE5CBFC5A52427B6154BCCE839750B8.png)

Right-click the unallocated space on **Disk 1** and click **New Simple Volume..**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F7/648041F0F1B80B911094614C0DB5D2979B2175F7.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/23/6710B47A160F71745C378645376677B0D6B57023.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DE/6FC32A0FA9A98AD87474E3643C5A007A02E08DDE.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D1/24D3046E82DAC6F8F12DCADBA1A403BD29766BD1.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2A/93D29831CA7EB1A679D42008E5BEE08570A7EA2A.png)

## Install WSUS

![(screenshot)](https://assets.technologytoolbox.com/screenshots/30/95F18511CC7247AEBFB056D86C056311CDF89630.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/86/FB846A250D3906A80B6BCADC82439502C78B2186.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/57/DECAEA9056214F80ED23DAC35925BD48E9DFED57.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DB/6A839CBEFF04B4FE038EAC4BA699F2F44B5520DB.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B7/E46D8D9A779C378B7EC40C8FC9D7CFE8F7C85AB7.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/94/9A7204B4F1488D1F20747C3E64D592EEF2A42A94.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/20/1A1B8E1EB55ACEB4C4E3AED45EC88A0797C6BA20.png)

On the **Select features** page, click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DF/781FD98779CB611006D70034D4B17E9D3600CADF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8B/E6B3E7FD06A9E6A2DE52ED909516A038D387448B.png)

Clear the **WID Database **checkbox.\
Select the **Database** checkbox.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/37/4031BD06C91AD9D04DD3FE77EC08F208E0076D37.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C0/ADAC9E5EABE0C38CABC84C3AB0BD6783FB102FC0.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/11/793C28119EA24D9C8B75E86F84B539E02AD3D611.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F9/893AECD7B5782ED39B42DD634F51A07BB4638CF9.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/07/F7E386A0BAA49CF684B929FE7588E5D7329D0307.png)

On the **Select role services** page, click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/69/28D8EFE93FB36C2BE75486B650BCB4197FD27C69.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/94/70FF3874946F7CA61DC5B64697E2BBF80B9BFA94.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D3/0EA9AF84E2C83C1FE047915A090E9E0E288312D3.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/81/EC07ED853599E824AEEB5363DD10B7A36CCA1981.png)

Click **Launch Post-Installation tasks** to create the SUSDB database.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DE/A31230FF3E7F9339EB766A3E052175AF600D8DDE.png)

Wait for the configuration to complete.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DD/D8C5E2F705807CCB65951C7D199EBDE8075D76DD.png)

## Configure WSUS

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A3/55029C1D2D40D052E79CB46843ED9509880256A3.png)

Right-click the WSUS server (**COLOSSUS**) and then click **Windows Server Update Services**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BF/59B523B58BAF38759E98CA89C95C8BC30CFB84BF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E1/79101F1DB298E5A71D7371D6D52F96906D6E23E1.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E9/6121955B47BDDD0DAB599829053D458284B86EE9.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7E/262435F7E3B602FB5C7A27B4A5101F2C65EB067E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AB/D1D866E3C28877F7ABF202EC205E217BFE586AAB.png)

Click **Start Connecting**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9E/8B6EEFB602732113E850408CF6E22F8944E9699E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5A/49C645116CACA18DB33D04C3F49D6B2951B4265A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/49/5A3A5F19A77F8FE68071F7166D9B348C73204649.png)

- Microsoft
  - Developer Tools, Runtimes, and Redistributables
    - Visual Studio 2010
    - Visual Studio 2012
    - Visual Studio 2013
  - Expression
    - Expression Design 4
    - Expression Web 4
  - Office
  - SQL Server
  - System Center
    - System Center 2012 R2 - Data Protection Manager
    - System Center 2012 R2 - Operations Manager
    - System Center 2012 R2 - Virtual Machine Manager
  - Windows

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F6/619FA785A38F081B829FEA3BF5010372DE5605F6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3E/75DA8705948A2A9DCCED07E493A3A33B1F36C33E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C3/D387144AB751593511B9A78CAAB1D264168EF5C3.png)

Select **Begin initial synchronization** and then click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3F/FF3B78505B859800A50E68D1C4D807B58970083F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9E/88120904C395BE9C60555A75CF2E648CAE83FE9E.png)

## Configure group policy for Windows Update

![(screenshot)](https://assets.technologytoolbox.com/screenshots/05/4F75EE5CAEDF7E8EFB10F970F7B2301F4CB07905.png)

## Configure auto-approval rules

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C5/8802A21A02AE3A0F8F9E06A10EEE7D1EC50BDCC5.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1F/B4245B951EFE7CE3AE1F7609502BF8658612301F.png)

In the **Automatic Approvals** window, on the **Update Rules** tab, select **Default Automatic Approval Rule**.

In the **Rule properties** section, click **Critical Update, Security Updates**.

In the **Choose Update Classifications** window, select **Critical Updates**,** Definition Updates**, and** Security Updates**, and then click **OK**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/09/6CFEB96F9B1E3D896821C9BBC903CAAC24334409.png)

In the **Automatic Approvals** window, click **OK**.

## Add computer groups

Computers

- All Computers
  - Unassigned Computers
  - .NET Framework 3.5
  - .NET Framework 4
  - .NET Framework 4 Client Profile
  - Fabrikam
  - Internet Explorer 10
  - Internet Explorer 7
  - Internet Explorer 8
  - Internet Explorer 9
  - Silverlight
  - Technology Toolbox
    - WSUS Servers

1. In the **Update Services** console, in the navigation pane, expand **Computers**, and then select **All Computers**.
2. In the Actions pane, click Add Computer Group...
3. In the **Add Computer Group** window, in the **Name** box, type the name for the new computer group and click **OK**.

## # Install .NET Framework 3.5

```PowerShell
Install-WindowsFeature `
    NET-Framework-Core `
    -Source '\\ICEMAN\Products\Microsoft\Windows Server 2012 R2\Sources\SxS'
```

## # Install Report Viewer 2008 SP1

**# Note: .NET Framework 2.0 is required for Microsoft Report Viewer 2008 SP1.**

& '[\\\\iceman\\Public\\Download\\Microsoft\\Report Viewer 2008 SP1\\ReportViewer.exe'](\\iceman\Public\Download\Microsoft\Report Viewer 2008 SP1\ReportViewer.exe')

## Error installing updates

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7F/381E71374086BC9E13A3274747390073A3FE797F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C4/57241505A2E0133E5CE65C1AF6999172BBFDB6C4.png)

When WSUS configured the Content folder in IIS, it omitted the "\\\\" from the path name.  Instead of pointing the folder to "[\\\\`<servername>`\\`<sharename>`\\WsusContent](\\<servername>\<sharename>\WsusContent)", it gave it a path of "`<servername>`\\`<sharename>`\\WsusContent".  As a result, it was directing requests to that virtual directory to a non-existing local folder, somewhere in C:\\Program Files.  This results in error code 80244017 on clients.

I just edited the Content virtual directory and placed a "\\\\" at the front, gave the folder a domain "Connect As" credential, and it is working like a charm!

Pasted from <[http://social.technet.microsoft.com/Forums/windowsserver/en-US/f3c1ba0f-8044-40ed-8dff-cfea09947d57/multiple-wsus-v6-server-2012-sharing-unc-path-with-the-content?forum=winserverwsus](http://social.technet.microsoft.com/Forums/windowsserver/en-US/f3c1ba0f-8044-40ed-8dff-cfea09947d57/multiple-wsus-v6-server-2012-sharing-unc-path-with-the-content?forum=winserverwsus)>

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3B/6298C221FF5E434E731C0BB54350BC0B32B9AB3B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C0/AD20F7B625FD3BFD11FB5CC1AB845840645AFEC0.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AE/CB44F6D6E5A4BBBFA5C4BD5703C55AFBC5031EAE.png)

Install Microsoft Message Analyzer (to troubleshoot issue with accessing [\\\\ICEMAN\\WSUS\$\\WsusContent](\\ICEMAN\WSUS$\WsusContent))

Attempted a number of methods for accessing the files using machine account (CYCLOPS\$):

1. Granting permissions for anonymous access on [\\\\ICEMAN\\WSUS\$](\\ICEMAN\WSUS$) (ANONYMOUS LOGON  - Read & execute)
2. Adding SPNs to COLOSSUS machine account (HTTP/COLOSSUS and HTTP/COLOSSUS.corp.technologytoolbox.com)
3. Configuring COLOSUS machine account to be trusted for delegation
4. ```PowerShell
       Setting userName and password properties to empty strings:
       Import-Module WebAdministration
   
       Set-ItemProperty `
           "IIS:\Sites\WSUS Administration\Content" `
           -Name userName `
           -Value ""
   
       Set-ItemProperty `
           "IIS:\Sites\WSUS Administration\Content" `
           -Name password `
           -Value ""
   ```

**Reference:**[http://kb4sp.wordpress.com/2011/10/24/setting-up-unc-path-mapping-with-pass-through-authentication-in-iis-7-and-7-5-windows-2008-and-2008r2/](http://kb4sp.wordpress.com/2011/10/24/setting-up-unc-path-mapping-with-pass-through-authentication-in-iis-7-and-7-5-windows-2008-and-2008r2/)

Ended up creating a service account for WSUS and using that instead.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/66/1899735369971F4C3310E3C7493A93657EA74666.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/83/353881FA69AA645C643DFD4BC745E27AA9753383.png)

## Configure e-mail notifications

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E0/AD85A99658542E344E0FBC8EB01FFC0ED421AEE0.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/68/78272A3294F49D454A4E958E7248A0BC69023168.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D6/9981FD029AF299079A2FDED5832178A8443194D6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/53/BDF7CEA7CDC006DF399B716FD0D9BF0F41288F53.png)

## # Create scheduled task to cleanup WSUS

```PowerShell
mkdir C:\NotBackedUp\Temp
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D0/99FF2A6184B963024BDA16202B0E76B27A4F08D0.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/37/8288CB51F0E1BA909C235F4BC076862AEFCE4837.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F6/B2F21D27E1738ED8038E3CEBF703D7F46AB551F6.png)

On the **Actions** tab, click **New...**

In the **New Action** window, specify the following settings:

Action: **Start a program**\
Program/script: **C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe**\
Arguments: **-command "&{C:\\NotBackedUp\\Public\\Toolbox\\WSUS\\Cleanup-WSUS.ps1}" > C:\\NotBackedUp\\Temp\\WSUS-Server-Cleanup.log**

Run the cleanup task.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8B/8751C83329E477CA7A0AE3CB88627144BE7B748B.png)

## Disable iSCSI Initiator

1. Disconnect iSCSI Target
2. Change **Startup type** of **Microsoft iSCSI Initiator Service** to **Manual**.
3. Stop VM
4. Remove iSCSI network adapter
5. Start VM

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

## Resolve SCOM alerts due to disk fragmentation

### Alert Name

Logical Disk Fragmentation Level is high

### Alert Description

The disk C: (C:) on computer COLOSSUS.corp.technologytoolbox.com has high fragmentation level. File Percent Fragmentation value is 21%. Defragmentation recommended: true.

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

## WSUS cleanup

SUSDB.mdf is ~4.5 GB

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A6/4466919CEF3373574D23485F2AA00ADD8FD2DDA6.png)

Reaching nearly 60K updates (mostly drivers)

1. Modify Products and Classifications to remove drivers
2. Decline all drivers
3. Remove declined updates from WSUS

![(screenshot)](https://assets.technologytoolbox.com/screenshots/47/21BA8B8F4E387990CFA4A569A0FDFBFD6B193947.png)

```PowerShell
    $wsus.GetUpdates() |
        where {$_.IsDeclined -eq $true} |
        ForEach-Object {
            $wsus.DeleteUpdate($_.Id.UpdateId.ToString())
            Write-Host $_.Title removed
        }
```

From <[http://www.flexecom.com/how-to-delete-driver-updates-from-wsus-3-0/](http://www.flexecom.com/how-to-delete-driver-updates-from-wsus-3-0/)>

After shrinking database, SUSDB.mdf is still ~3.5 GB

![(screenshot)](https://assets.technologytoolbox.com/screenshots/07/5ECC7A426275117208A76A744781E809305CDA07.png)

Computers

- All Computers
  - Fabrikam
    - Fab - Development
      - EXT-FOOBAR5
  - Internet Explorer 10
    - FOOBAR9
    - WIN7-TEST1
    - WIN7-TEST1
  - Technology Toolbox
    - Development
      - EXT-FOOBAR4
      - FOOBAR8
      - FOOBAR9
      - POLARIS-DEV
    - Quality Assurance
      - *-TEST*

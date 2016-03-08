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

Set-VMDvdDrive -ComputerName ANGEL -VMName EXT-WEB01B -Path $imagePath
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
Set-VMDvdDrive -ComputerName ANGEL -VMName EXT-WEB01B -Path $null
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
_Computer: EXT-WEB01B.extranet.technologytoolbox.com_\
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
_Computer: EXT-WEB01B.extranet.technologytoolbox.com_\
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

## Resolve permissions issue with SharePoint tracing

### Alert

_Source: Microsoft-SharePoint Products-SharePoint Foundation_\
_Event ID: 2163_\
_Event Category: 88_\
_User: NT AUTHORITY\\LOCAL SERVICE_\
_Computer: EXT-WEB01B.extranet.technologytoolbox.com_\
_Event Description: Tracing Service failed to create the trace log file at location specified in SOFTWARE\\Microsoft\\Shared Tools\\Web Server Extensions\\14.0\\WSS\\LogDir. Error 0x0: The operation completed successfully. . Traces will be written to the following directory: C:\\Windows\\SERVIC~2\\LOCALS~1\\AppData\\Local\\Temp\\._

### Solution

```PowerShell
icacls "L:\Program Files\Microsoft Office Servers\14.0\Logs" `
    /grant "NT AUTHORITY\LOCAL SERVICE:(OI)(CI)(F)"
```

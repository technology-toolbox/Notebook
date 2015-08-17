# MOONSTAR - Windows Server 2012 R2 Standard

Sunday, January 19, 2014
10:39 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

Minimum RAM: 2 GB

If you install the VMM management server in a virtual machine and you use the Dynamic Memory feature of Hyper-V, you must set the startup RAM for the virtual machine to be at least 2048 MB.

Pasted from <[http://technet.microsoft.com/en-us/library/gg610562.aspx](http://technet.microsoft.com/en-us/library/gg610562.aspx)>

```Console
PowerShell
```

## # Create virtual machine

```PowerShell
$vmName = "MOONSTAR"

New-VM `
    -Name $vmName `
    -Path C:\NotBackedUp\VMs `
    -MemoryStartupBytes 4GB `
    -SwitchName "Virtual LAN 2 - 192.168.10.x"

Set-VMProcessor -VMName $vmName -Count 2

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
Rename-Computer -NewName MOONSTAR -Restart

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

## Create VMM administrators group in Active Directory

Group name: **VMM Administrators**\
Group (SamAccountName) name: **VMM Administrators**\
Description:** Complete and unrestricted access to Virtual Machine Manager**

## Add users to VMM administrators domain group

## # Add VMM administrators domain group to local Administrators group

```PowerShell
net localgroup Administrators "TECHTOOLBOX\VMM Administrators" /ADD
```

## Create service account for Virtual Machine Manager in Active Directory

User UPN logon: **svc-vmm@corp.technologytoolbox.com**\
User SamAccountName login: **corp\\svc-vmm**

Password options:

- **Password never expires**
- **User cannot change password**

## # Add service account for Virtual Machine Manager to local Administrators group

```PowerShell
net localgroup Administrators TECHTOOLBOX\svc-vmm /ADD
```

### Reference

If you specify a domain account, the account must be a member of the local Administrators group on the computer.

Pasted from <[http://technet.microsoft.com/en-us/library/gg697600.aspx](http://technet.microsoft.com/en-us/library/gg697600.aspx)>

## Create VMM Distributed Key Management container in Active Directory - XAVIER1

## Install prerequisites for VMM Management Server

"[\\\\iceman\\Public\\Download\\Microsoft\\Windows Kits\\8.1\\ADK\\adksetup.exe](\\iceman\Public\Download\Microsoft\Windows Kits\8.1\ADK\adksetup.exe)"

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E3/A320AA5A7D6E45D9068B221950E08328B717ECE3.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2A/CDB64F12D246CA565DC183B9CE522581BC9DBB2A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FE/468070F3EF7A9DF64EBC14668EFF46A494CCE2FE.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EC/D72066475926AA1C47FE71BED323E814613639EC.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A6/9A3803153C5CE3057CCFCD07A6B906C8ADFB20A6.png)

UAC, click **Yes**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CF/AC21E9EDEF908198F461C2185917939A29F50BCF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/93/BAD23B0F3D218B55A990B8B2B1DDA936905B1D93.png)

### Install SQL Server 2012 Native Client

"[\\\\iceman\\Products\\Microsoft\\SQL Server 2012\\Native Client\\x64\\sqlncli.msi](\\iceman\Products\Microsoft\SQL Server 2012\Native Client\x64\sqlncli.msi)"

### Install SQL Server 2012 Command Line Utilities

"[\\\\iceman\\Products\\Microsoft\\SQL Server 2012\\Command Line Utilities\\x64\\SqlCmdLnUtils.msi](\\iceman\Products\Microsoft\SQL Server 2012\Command Line Utilities\x64\SqlCmdLnUtils.msi)"

## Install VMM Management Server

Mount the ISO image:

"[\\\\iceman\\Products\\Microsoft\\System Center 2012 R2\\mu_system_center_2012_r2_virtual_machine_manager_x86_and_x64_dvd_2913737.iso](\\iceman\Products\Microsoft\System Center 2012 R2\mu_system_center_2012_r2_virtual_machine_manager_x86_and_x64_dvd_2913737.iso)"

### To install a VMM management server

1. To start the Virtual Machine Manager Setup Wizard, on your installation media, right-click **setup.exe**, and then click **Run as administrator**.
2. On the main setup page, click **Install**.
3. ~~If you have not installed Microsoft .NET Framework, VMM will prompt you to install now.~~
4. On the **Select features to install** page, select the **VMM management server** check box, and then click **Next**.
5. On the **Product registration information** page, provide the appropriate information, and then click **Next**.
6. On the **Please read this license agreement** page, review the license agreement, select the **I have read, understood, and agree with the terms of the license agreement** check box, and then click **Next**.
7. On the **Customer Experience Improvement Program (CEIP)** page, select either option and then click **Next**.
8. On the **Installation location** page, ensure the default path is specified (**C:\\Program Files\\Microsoft System Center 2012 R2\\Virtual Machine Manager**), and then click **Next**.
9. If all prerequisites have been met, the **Database configuration** page appears.
10. On the **Database configuration** page:
    1. In the Server name box, type the name of the computer that is running SQL Server (HAVOK).
    2. Leave the **Port** box empty.
    3. If the account you are using to install the VMM management server does not have the appropriate permissions to create a new SQL Server database, select the **Use the following credentials** check box, and then provide the user name and password of an account that has the appropriate permissions.
    4. Select or type the name of the instance of SQL Server that you want to use.
    5. Ensure the **New database** option is selected and the default database name (**VirtualManagerDB**) is specified.
    6. Click **Next**.
11. On the **Configure service account and distributed key management** page:
    1. In the Virtual Machine Manager Service Account section, specify the account that will be used by the Virtual Machine Manager service.
    2. Under **Distributed Key Management**, select whether to store encryption keys in Active Directory.
       ![(screenshot)](https://assets.technologytoolbox.com/screenshots/BC/8E6FE4999E14C675D87318235C87BF0DB8FB91BC.png)
    3. Click **Next**.
12. On the **Port configuration** page, for each feature use the default port numbers, or provide a unique port number that is appropriate in your environment, and then click **Next**.
    ![(screenshot)](https://assets.technologytoolbox.com/screenshots/1F/210AF8F3255EF813BBC0675E8111E913B711A91F.png)
13. 
14. On the **Library configuration** page, select whether to create a new library share or to use an existing library share on the computer.In the **Share name** box, type **VM-Library**.
15. On the **Installation summary** page, review your selections and do one of the following:
    - Click **Previous** to change any selections.
    - Click **Install** to install the VMM management server.

After you click **Install**, the **Installing features** page appears and installation progress is displayed.
16. On the **Setup completed successfully** page, click **Close** to finish the installation.
To open the VMM console, ensure that the **Open the VMM console when this wizard closes** check box is selected. Alternatively for VMM in System Center 2012 SP1or in System Center 2012 R2, you can click the **Virtual Machine Manager Console** icon on the desktop.\
    During Setup, VMM enables the following firewall rules, which remain in effect even if you later uninstall VMM:

> **Note**
>
> Before beginning the installation of VMM, close any open programs and ensure that there are no pending restarts on the computer. For example, if you have installed a server role by using Server Manager or have applied a security update, you may need to restart the computer and then log on to the computer with the same user account to finish the installation of the server role or the security update.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D8/F373F8E1592208BAB1B439003109E502339B6ED8.png)

> **Note**
>
> The VMM console is automatically installed when you install a VMM management server.

CN=VMM Distributed Key Management,CN=System,DC=corp,DC=technologytoolbox,DC=com

> **Important**
>
> The ports that you assign during the installation of a VMM management server cannot be changed without uninstalling and reinstalling the VMM management server. Also, do not configure any feature with port number 5986 as it is been pre-assigned.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FD/E69F79BD59019D698F89EF289DF6E31CFAF66DFD.png)

> **Note**
>
> The default library share created by VMM is named **MSSCVMMLibrary** and the folder is located at **%SYSTEMDRIVE%\\ProgramData\\Virtual Machine Manager Library Files**. **ProgramData** is a hidden folder, and you cannot remove it.\
> After the VMM management server is installed, you can add library shares and additional library servers by using the VMM console or by using the VMM command shell.

After you have specified a library share, click **Next**.

- File Server Remote Management
- Windows Standards-Based Storage Management firewall rules

> **Note**
>
> If there is a problem with setup completing successfully, consult the log files in the **%SYSTEMDRIVE%\\ProgramData\\VMMLogs** folder. **ProgramData** is a hidden folder.

Pasted from <[http://technet.microsoft.com/en-us/library/gg610656.aspx](http://technet.microsoft.com/en-us/library/gg610656.aspx)>

## Create host groups in VMM

- **All Hosts**
  - **Hyper-V - Windows Server 2012 R2**

Right-click **All Hosts** and click **Create Host Group**.

## Add hosts to host group

Right-click the host group and click **Add Hyper-V Hosts and Clusters**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D0/8516714137B2E57E3F1736B95DA3B709DA9047D0.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/69/2BCFD803C16C858F31BC3EBDCEC2ABEA276FA869.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/27/341303BEB31C1C9EBCA1F90DB7A05FAD19783527.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A4/BFC2C93E8E97EE2C20259F40BB5B13EF30A070A4.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/62/6950CF59AB8E59637B162E8AB22CD49C6FF98862.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/67/95EE39282DA3AEA135B563901745DD8F26DAD867.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/91/FF88B1CCCE0340D9D5FA77A721AB34CBC7B7D191.png)

Restart STORM

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BF/701200FBF6911B7B97874EC7EC8E0CA41E166EBF.png)

## Add library server (ICEMAN)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5E/E5D85CBED7BD01BE849747D0DB0E78B0DB1D565E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C1/D5709F4BED84B576CA1EAE2417712C6B5CCEA9C1.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A8/B22F92674BC53118BD49CE49E7FB4AF808D33EA8.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0B/6CC6D78FA9F8E07D57D34BAD4C870D309AECC10B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2D/0861E41C1A2173C3AEB9F5EF8D59477DE480632D.png)

Click View Script

\$credential = Get-Credential\
Add-SCLibraryShare -AddDefaultResources -Description "" -JobGroup "2212438d-fa7f-40ae-a36b-e1130d9dba78" -SharePath "[\\\\iceman.corp.technologytoolbox.com\\VM-Library](\\iceman.corp.technologytoolbox.com\VM-Library)"\
Add-SCLibraryServer -ComputerName "iceman.corp.technologytoolbox.com" -Description "" -JobGroup "2212438d-fa7f-40ae-a36b-e1130d9dba78" -RunAsynchronously -Credential \$credential

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EA/EAF864EFCF6B54F8A4179CDEC40E9904A02745EA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9C/FD6BC61543E402CACBF98F2D506CFD10DAE1439C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8D/F8C2FC23AEA09EA9FDEE08D674C55B430AB3248D.png)

## # Copy VHDs to VM-Library share

```PowerShell
robocopy `
    "C:\ProgramData\Virtual Machine Manager Library Files\VHDs" `
    \\iceman\VM-Library\VHDs
```

## Add Products share to VMM Library

1. Open Virtual Machine Manager Console and select the **Library** workspace.
2. Under **Library Servers**, right-click **iceman.corp.technologytoolbox.com** and click **Add Library Shares**.
3. In the **Add Library Shares** window:
   1. On the **Add Library Shares** step, select the checkbox for the **Products** share and click **Next**.
   2. On the **Summary** step, confirm the settings and then click **Add Library Shares**.
4. Wait for the VMM job to complete.

## Resolve SCOM alerts due to disk fragmentation

### Alert Name

Logical Disk Fragmentation Level is high

### Alert Description

The disk C: (C:) on computer MOONSTAR.corp.technologytoolbox.com has high fragmentation level. File Percent Fragmentation value is 13%. Defragmentation recommended: true.

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

## # Configure firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

---

**FOOBAR8**

```PowerShell
$computer = 'MOONSTAR'

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

Invoke-Command -ComputerName $computer -ScriptBlock $scriptBlock
```

---

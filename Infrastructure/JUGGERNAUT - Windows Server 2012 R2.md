# JUGGERNAUT (2014-01-05) - Windows Server 2012 R2 Standard

Sunday, January 05, 2014
10:17 AM

```Console
12345678901234567890123456789012345678901234567890123456789012345678901234567890

PowerShell
```

## # Create virtual machine

```PowerShell
$vmName = "JUGGERNAUT"

New-VM `
    -Name $vmName `
    -Path C:\NotBackedUp\VMs `
    -MemoryStartupBytes 512MB `
    -SwitchName "Virtual LAN 2 - 192.168.10.x"

Set-VMProcessor -VMName $vmName -Count 2

Set-VMMemory `
    -VMName $vmName `
    -DynamicMemoryEnabled $true `
    -MaximumBytes 4GB

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
Rename-Computer -NewName JUGGERNAUT -Restart

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

## # Add disks for SQL Server storage (Data01, Log01, Temp01, and Backup01)

```PowerShell
$vmName = "JUGGERNAUT"

Stop-VM $vmName

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Data01.vhdx"

New-VHD -Path $vhdPath -Fixed -SizeBytes 2GB
Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath -ControllerType SCSI

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Log01.vhdx"

New-VHD -Path $vhdPath -Fixed -SizeBytes 1GB
Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath -ControllerType SCSI

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Temp01.vhdx"

New-VHD -Path $vhdPath -Fixed -SizeBytes 1GB
Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath -ControllerType SCSI

$vhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
    + $vmName + "_Backup01.vhdx"

New-VHD -Path $vhdPath -Dynamic -SizeBytes 6GB
Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath -ControllerType SCSI

Start-VM $vmName
```

## # Initialize disks and format volumes

```PowerShell
Get-Disk 1 |
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -UseMaximumSize -DriveLetter D |
    Format-Volume `
        -FileSystem NTFS `
        -AllocationUnitSize 64KB `
        -NewFileSystemLabel "Data01" `
        -Confirm:$false

Get-Disk 2 |
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -UseMaximumSize -DriveLetter L |
    Format-Volume `
        -FileSystem NTFS `
        -AllocationUnitSize 64KB `
        -NewFileSystemLabel "Log01" `
        -Confirm:$false

Get-Disk 3 |
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -UseMaximumSize -DriveLetter T |
    Format-Volume `
        -FileSystem NTFS `
        -AllocationUnitSize 64KB `
        -NewFileSystemLabel "Temp01" `
        -Confirm:$false

Get-Disk 4 |
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -UseMaximumSize -DriveLetter Z |
    Format-Volume `
        -FileSystem NTFS `
        -AllocationUnitSize 64KB `
        -NewFileSystemLabel "Backup01" `
        -Confirm:$false
```

## # Install .NET Framework 3.5

```PowerShell
Install-WindowsFeature `
    NET-Framework-Core `
    -Source '\\ICEMAN\Products\Microsoft\Windows Server 2012 R2\Sources\SxS'
```

## # Install SQL Server 2012 with SP1

**# Note: .NET Framework 3.5 is required for some SQL Server 2012 features (e.g. Reporting Services).**

On the **Feature Selection** step, select:

- **Database Engine Services**
- **Reporting Services - Native**.
- **Management Tools - Complete**.

On the **Server Configuration** step:

- For the **SQL Server Agent** service, change the **Startup Type** to **Automatic**.
- For the **SQL Server Browser** service, leave the **Startup Type** as **Disabled**.

On the **Database Engine Configuration** step:

- On the **Server Configuration** tab, in the **Specify SQL Server administrators** section, click **Add...** and then add the domain group for SQL Server administrators.
- On the **Data Directories** tab:
  - In the **Data root directory** box, type **D:\\Microsoft SQL Server\\**.
  - In the **User database log directory** box, change the drive letter to **L:** (the value should be **L:\\Microsoft SQL Server\\MSSQL11.MSSQLSERVER\\MSSQL\\Data**).
  - In the **Temp DB directory** box, change the drive letter to **T:** (the value should be **T:\\Microsoft SQL Server\\MSSQL11.MSSQLSERVER\\MSSQL\\Data**).
  - In the **Backup directory** box, change the drive letter to **Z:** (the value should be **Z:\\Microsoft SQL Server\\MSSQL11.MSSQLSERVER\\MSSQL\\Backup**).

## Fix permissions to avoid "ESENT" errors in event log

```Console
icacls C:\Windows\System32\LogFiles\Sum\Api.chk /grant "TECHTOOLBOX\svc-sql":(M)

icacls C:\Windows\System32\LogFiles\Sum\Api.log /grant "TECHTOOLBOX\svc-sql":(M)

icacls C:\Windows\System32\LogFiles\Sum\SystemIdentity.mdb /grant "TECHTOOLBOX\svc-sql":(M)
```

### Reference

**Error 1032 messages in the Application log in Windows Server 2012**\
Pasted from <[http://support.microsoft.com/kb/2811566](http://support.microsoft.com/kb/2811566)>

## # Add passthrough disks

## # Install Data Protection Manager 2012 R2

![(screenshot)](https://assets.technologytoolbox.com/screenshots/63/7EFABEE6E4F28F3CA7C38959AB5B5C02C6948563.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8B/DE6E3530B2C2E5130BF43C4B39E6F689065D4C8B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/29/381CC1E9266D9B36CE9F57FCB4E86EC9E1645129.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2A/30C531601404FE3967253B54820B5C0C0E30D32A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/65/1C311042A065709D117DE001D4BDC29925586665.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/12/6A78E40D429056559E524B702ACE9C90ABD66212.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3F/7A027013B98FA582639904D2A59AADCA79BD983F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0D/4D07BAA5B229356F8D0DBE38656382B9B884980D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1B/DC78488C7E4BCEE3AF2541D28F39859FAD5BA31B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/63/B8FAE16DCBFB56E88E2171644612B17904BCB463.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0B/14D711CD0027DF2034BF3B2D7CF4AF05B4907A0B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D0/EFA6E1AF2DA6D1B0B6F28C92E46EF3417840F2D0.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6F/5C3E28D3AD1151EEA666B549875721D82376A76F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F4/89AE27C6E3DE19717751F5434E218563969A5DF4.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/19/A306233547F3203C655021775DF1393FA59E2619.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5F/05E44C83C60EE5E6649BF9ED64C9ECA1929B385F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EC/61AC99C8E440769ED6ECF37421040FE2DDEF73EC.png)

Click **Apply**. Reporting Services Configuration Manager prompts to backup the encryption key.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D4/A2DC2DA73369B944D881B79D724D5CBD3C420ED4.png)

Click **OK**. Reporting Services Configuration Manager prompts for administrator credentials for applying permissions for the new service account.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/37/FFAC12FA3783F5325E7AAD977B9F65DACE116737.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/61/71CB7EC1638556092F0B567C991DF1B5474B6561.png)

Open SQL Server Configuration manager and confirm the service accounts have been changed to domain accounts.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A5/BB7D87D6EE7053FF54704C792728B7E85DC489A5.png)

## # Increase memory (minimum of 2GB)

```PowerShell
$vmName = "JUGGERNAUT"

Stop-VM $vmName

Set-VMMemory `
    -VMName $vmName `
    -DynamicMemoryEnabled $true `
    -MaximumBytes 4GB `-MinimumBytes 2GB `-StartupBytes 2GB

Start-VM $vmName
```

## Install Data Protection Manager

![(screenshot)](https://assets.technologytoolbox.com/screenshots/63/7EFABEE6E4F28F3CA7C38959AB5B5C02C6948563.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2A/30C531601404FE3967253B54820B5C0C0E30D32A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/85/7F8087AD6F18281CFB89EC8E24B8BB54E2D62685.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CB/70A3D0C92772D1971E9EB9177B78E86800317ECB.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5F/95CFDF5EDDE13965626F9F4A70BC995DF0675F5F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/09/3F42CA470B96A6F1EEB3853CACFED584F28C5309.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/14/75CAE9A264379EB7FCFFC6E544BE8A26B1505414.png)

Click **Use Microsoft Update when I check for updates (recommended)** and then click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/21/E77B4A3E91F633E24A1D8E38791BD8159CA69321.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/56/0CC80049382DF7E5D1F9BDD35E127E246DD44556.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/53/94B43C0A84564056BEE284DAA61E71FED6239553.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9C/0B31DB8059F2B6CAC957B81DE2FAE625AB17889C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1E/93E89F87922D670ED333C826AAEE492CED034C1E.png)

## Choose customer feedback option

**To choose the feedback option:**

1. In DPM Administrator Console, click **Management**, and then click **Options** on the tool ribbon.
2. In the **Options** window, on the **Customer Feedback** tab, select the **No, thank you** option and then  **OK**.

## Online disks using Disk Management

## Add disks to the storage pool

**To add disks to the storage pool**

1. In DPM Administrator Console, click **Management**, and then click the **Disks**.
2. Click **Add** on the tool ribbon.
The **Add Disks to Storage Pool** dialog box appears. The **Available disks** section lists the disks that you can add to the storage pool.
3. Select one or more disks, click **Add**, and then click **OK**.

Pasted from <[http://technet.microsoft.com/en-us/library/hh758075.aspx](http://technet.microsoft.com/en-us/library/hh758075.aspx)>

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F8/60A7255DCC366A5070F548C4A53A56FDE47E89F8.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/69/836DB2405E1EB4E309DEE07BDFEEC3343406AB69.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A7/34291F5B50DA9F7B4C582EC81B82DA850BC587A7.png)

## Create protection group for domain controllers

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6C/D50A7E4B18D2699A59B49E264192A1CAB904C26C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A2/EFF77FE2E5CA3B209B6E83F6D696FF3E3DEDCBA2.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/50/3F51BEA0EA802266085D669BEA89C8D9E59E8E50.png)

Ensure **Servers** is selected and then click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4F/841E0BDC6767C52778A84543B80F201D7A42B14F.png)

Expand **XAVIER1**, then expand **System Protection**, and then select **System State (includes Active Directory)**.

Repeat the previous step for **XAVIER2**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/95/7C7D44231A73401CD4B9D24D4C3091D8424F0095.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BA/D5019D1C8AC66E92C69D1F8DA6D622ADE5D4D9BA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/12/A14F746A6B28C591470060A1BD4226ACD925C012.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/59/F57922125AFC4F537FC951C66E202DCD7FE0DA59.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3E/5E0AFA8E57FE56504343946A999BC3828101D93E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/71/BC9252CFA985190E441186D77D15E1D23BECB471.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7B/1DCDCFD257422CE8883060A446E3AAA594B58B7B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6C/A3CC4EF8DCE5180229796A1E57E25C58C96C916C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8B/3432627B9914BD277FD59CBE8F0C38E4428FC28B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B1/EABDD9A4BA24BA197245967B561123E1976495B1.png)

## Create protection group for SQL Server databases (TEST)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7B/567D0E550D174A218C8DA8F7381DE572838AB27B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A2/EFF77FE2E5CA3B209B6E83F6D696FF3E3DEDCBA2.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/50/3F51BEA0EA802266085D669BEA89C8D9E59E8E50.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C3/B4ED007234F0DC68E0D31CF08542DDE7107308C3.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E3/2F96840A22EC87B12E84C845A72D3E27D67669E3.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C6/6D9BDD3FCCBEEEDD9EF72415F6CC6C62C254BDC6.png)

For **Retention range**, specify **10 days**.

For **Synchronization frequency**, specify **Every 4 hour(s)**.

In the **Application recovery points** section, click **Modify...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/93/6F5A1356875129FAA4F41946C496F6BD85515693.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/63/DDB13B4A9C9D68A6EC154CAA3411B64F17320D63.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B7/8D6C7C4C144628266046FB701B88C9D4232FF1B7.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AF/E43A61CC7641FB168A6960B8C142C0C91456B6AF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7B/1DCDCFD257422CE8883060A446E3AAA594B58B7B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EB/7645163BA736F36A9B198B870169F0D0490BD0EB.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5B/7C3DD344842CDCEE9AC6A0E70C37B537EAE4C15B.png)

## Add "Local System" account to SQL Server sysadmin role

On the SQL Server (HAVOK-TEST), open SQL Server Management Studio and execute the following:

```SQL
ALTER SERVER ROLE [sysadmin] ADD MEMBER [NT AUTHORITY\SYSTEM]
GO
```

### Reference

**Protection agent jobs may fail for SQL Server 2012 databases**\
Pasted from <[http://technet.microsoft.com/en-us/library/dn281948.aspx](http://technet.microsoft.com/en-us/library/dn281948.aspx)>

## Create protection group for SQL Server databases

![(screenshot)](https://assets.technologytoolbox.com/screenshots/38/9BC59C1C391D5D48BCFA2EB51134E8E9BB6B5238.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A2/EFF77FE2E5CA3B209B6E83F6D696FF3E3DEDCBA2.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/50/3F51BEA0EA802266085D669BEA89C8D9E59E8E50.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A1/443F05F34224FB26CD3B86724479AE3C400D0DA1.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E6/E426960C766486E132D5DAD22441ABDD9F2714E6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9C/415C5EFE264CA38E1FA96744127C1FF1EC88169C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FB/DA15FC4273A0CB46CC35AA4A6BCF592266488AFB.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C9/9DE474F2EA6D63FBC83E38F4DE9E5AA67ABD7EC9.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7B/1DCDCFD257422CE8883060A446E3AAA594B58B7B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A8/C971848B2DB9892A765BB551A669704DD45855A8.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1F/1E4820C0182D65FEF71918748029FFE07C72031F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A9/0061E9550C33C86432F6A42F3770698DFDD2EBA9.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/76/AD25EC02939628E5F522E4DB212D9EE597818076.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1A/F6C3A482DAE8C68EEAEA6F00E19449551506B71A.png)

## Expand disk allocation for "SQL Server Databases" protection groups

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9F/8510CBA4F4BA7FA074B5183038320107ED90D09F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/37/9F7AA22E35F5283B86A8F46772E2EE43C11C3237.png)

Right-click the protection group and click **Modify disk allocation...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DA/560F04FCF7874975A9022FCD6110A228C41362DA.png)

Identify the storage pool that needs to be expanded (by clicking the **Co-located SQL Server** links).

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2D/C1ADC5356A154CADF204F7991F5AF311AED4E32D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/54/49382BC6D047948467F5A716684DF33034ADB854.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9F/8510CBA4F4BA7FA074B5183038320107ED90D09F.png)

Right-click the alert and click **Create a recovery point...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/5C/FE9A29C4FA9F2F543AC0C6BB0D4ECCDC4C31EC5C.png)

## Move log file for DPM database from D: to L

### Stop the DPM service

```Console
net stop msdpm
```

### Detach the DPM database

```SQL
USE [master]
GO
EXEC master.dbo.sp_detach_db @dbname = N'DPMDB_JUGGERNAUT'
GO
```

### Move the log file for the DPM database

```Console
move "D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\MSDPM2012$DPMDB_JUGGERNAUT_log.ldf" "L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data"
```

### Attach the DPM database

```SQL
USE [master]
GO
CREATE DATABASE [DPMDB_JUGGERNAUT] ON
( FILENAME = N'D:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\MSDPM2012$DPMDB_JUGGERNAUT.mdf' ),
( FILENAME = N'L:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\MSDPM2012$DPMDB_JUGGERNAUT_log.ldf' )
 FOR ATTACH
GO
```

### Start the DPM service

```Console
net start msdpm
```

## Create maintenance plans to backup SQL Server databases

```Console
mkdir "Z:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\Full"
mkdir "Z:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\Differential"
mkdir "Z:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\Transaction Log"
```

### Full backup of all databases

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D7/E9B4AD115094D24286E2FD4D91A834C611368CD7.png)

Right-click **Maintenance Plans** and click **Maintenance Plan Wizard**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/9D/704A09951485E3C05368B69C36408A1420DCBF9D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F9/74A07343F5EC0ADF19DC60BD77C0DDCF10A501F9.png)

In the **Schedule** section, click **Change...**

![(screenshot)](https://assets.technologytoolbox.com/screenshots/61/A16C7EA6E06310367C400A27C32F2517D00F0261.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/21/4A303D282592167075123900B75E5B39270EE021.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/30/1F526D384BD3B5362991EB03D53045B846E90830.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/1E/C0402F796985C4D2CA811B0898D5AD58A237D51E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/4D/71FC6103F1C3048856E7DA098870A616A449794D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CA/10BCEA4758880B6AFB64B971921F2E4658A40DCA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/02/07BDB2BE0B0324752C5B3995E00DDFD3B1C54302.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E7/5BC4DF7D314C5FDB0F74C7EF2EFCEB75D9871EE7.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/6A/D07DCA4A3853B9F2EDD91B4C207E2943E8F5E86A.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3E/68EDCE3E0914FE79478DCC7DD8BC4D9ADAEA693E.png)

### Differential backup of all databases

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BC/67A8AB130CE9E9303899B4E0D75E3D6D0BE1F4BC.png)

### Transaction log backup of all databases

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0C/1804598D619F7D35A4C79C1ABB59348AD5189E0C.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AE/7F261629A3F51D9F3A5B880CFDCD78F583EF47AE.png)

## Execute maintenance plan to backup all databases

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BF/9B47F071EC5BE2FE29D61CC65F21C4B0E05184BF.png)

Right-click **Full Backup of All Databases** and click **Execute**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AF/4A7B63AABFD12DD015D778C5CF536E8948EDBEAF.png)

## Configure DCOM permissions for SQL Server Integration Services

Log Name:      System\
Source:        Microsoft-Windows-DistributedCOM\
Date:          1/22/2014 5:18:02 AM\
Event ID:      10016\
Task Category: None\
Level:         Error\
Keywords:      Classic\
User:          TECHTOOLBOX\\svc-sql-agent\
Computer:      JUGGERNAUT.corp.technologytoolbox.com\
Description:\
The application-specific permission settings do not grant Local Activation permission for the COM Server application with CLSID\
{FDC3723D-1588-4BA3-92D4-42C430735D7D}\
 and APPID\
{83B33982-693D-4824-B42E-7196AE61BB05}\
 to the user TECHTOOLBOX\\svc-sql-agent SID (S-1-5-21-3914637029-2275272621-3670275343-4111) from address LocalHost (Using LRPC) running in the application container Unavailable SID (Unavailable). This security permission can be modified using the Component Services administrative tool.\
Event Xml:\
<Event xmlns="[http://schemas.microsoft.com/win/2004/08/events/event](http://schemas.microsoft.com/win/2004/08/events/event)">\
  `<System>`\
    `<Provider Name="Microsoft-Windows-DistributedCOM" Guid="{1B562E86-B7AA-4131-BADC-B6F3A001407E}" EventSourceName="DCOM" />`\
    `<EventID Qualifiers="0">`10016`</EventID>`\
    `<Version>`0`</Version>`\
    `<Level>`2`</Level>`\
    `<Task>`0`</Task>`\
    `<Opcode>`0`</Opcode>`\
    `<Keywords>`0x8080000000000000`</Keywords>`\
    `<TimeCreated SystemTime="2014-01-22T12:18:02.869192000Z" />`\
    `<EventRecordID>`11632`</EventRecordID>`\
    `<Correlation />`\
    `<Execution ProcessID="788" ThreadID="4364" />`\
    `<Channel>`System`</Channel>`\
    `<Computer>`JUGGERNAUT.corp.technologytoolbox.com`</Computer>`\
    `<Security UserID="S-1-5-21-3914637029-2275272621-3670275343-4111" />`\
  `</System>`\
  `<EventData>`\
    `<Data Name="param1">`application-specific`</Data>`\
    `<Data Name="param2">`Local`</Data>`\
    `<Data Name="param3">`Activation`</Data>`\
    `<Data Name="param4">`{FDC3723D-1588-4BA3-92D4-42C430735D7D}`</Data>`\
    `<Data Name="param5">`{83B33982-693D-4824-B42E-7196AE61BB05}`</Data>`\
    `<Data Name="param6">`TECHTOOLBOX`</Data>`\
    `<Data Name="param7">`svc-sql-agent`</Data>`\
    `<Data Name="param8">`S-1-5-21-3914637029-2275272621-3670275343-4111`</Data>`\
    `<Data Name="param9">`LocalHost (Using LRPC)`</Data>`\
    `<Data Name="param10">`Unavailable`</Data>`\
    `<Data Name="param11">`Unavailable`</Data>`\
  `</EventData>`\
`</Event>`

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F6/A5C0C95ECE956FF1DBD7B82E9F7AD8DC49CB32F6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0C/7869E60C98C8F6102EFEEC5491788C50A966A60C.png)

Right-click **Microsoft SQL Server Integration Services 11.0** and click **Properties**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BA/7E91310C21AA0F6678F9242B63F707EC0C5FB0BA.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/98/8B79030112E2E5FA5090E791619AD565D29E7298.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BE/3326BBC133CD87323E4290F6F20C042A85D903BE.png)

## Resolve SCOM alerts due to disk fragmentation

### Alert Name

Logical Disk Fragmentation Level is high

### Alert Description

The disk C: (C:) on computer JUGGERNAUT.corp.technologytoolbox.com has high fragmentation level. File Percent Fragmentation value is 13%. Defragmentation recommended: true.

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

## Expand Z: (Backup01) drive

### Alert Name

Logical Disk Free Space is low

### Alert Description

_The disk Z: on computer JUGGERNAUT.corp.technologytoolbox.com is running out of disk space._

### Investigation

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D2/976034E38F193EA9E55010C4B3E995B0C91B59D2.png)

### Resolution

#### # Increase the size of "Backup01" VHD

```PowerShell
$vmName = "JUGGERNAUT"

Stop-VM $vmName

Resize-VHD `
    ("C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
        + $vmName + "_Backup01.vhdx") `
    -SizeBytes 8GB

Start-VM $vmName
```

#### # Extend partition

```PowerShell
$size = (Get-PartitionSupportedSize -DiskNumber 4 -PartitionNumber 1)
Resize-Partition -DiskNumber 4 -PartitionNumber 1 -Size $size.SizeMax
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E4/650E5EFCBB93E63A3F9BD823C8F98B940CCF13E4.png)

## Expand Z: (Backup01) drive

### Alert Name

Logical Disk Free Space is low

### Alert Description

_The disk Z: on computer JUGGERNAUT.corp.technologytoolbox.com is running out of disk space._

### Investigation

![(screenshot)](https://assets.technologytoolbox.com/screenshots/00/E6F966A2EE68C6EF36AE78EF3B1665BF7F2EB400.png)

### Resolution

#### # Increase the size of "Backup01" VHD

```PowerShell
$vmName = "JUGGERNAUT"

Stop-VM $vmName

Resize-VHD `
    ("C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
        + $vmName + "_Backup01.vhdx") `
    -SizeBytes 10GB

Start-VM $vmName
```

#### # Extend partition

```PowerShell
$size = (Get-PartitionSupportedSize -DiskNumber 4 -PartitionNumber 1)
Resize-Partition -DiskNumber 4 -PartitionNumber 1 -Size $size.SizeMax
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/24/06B5626C22E74EB89C4FEB8358B8A7CFD1A7FF24.png)

## Expand Z: (Backup01) drive

### Alert Name

Logical Disk Free Space is low

### Alert Description

_The disk Z: on computer JUGGERNAUT.corp.technologytoolbox.com is running out of disk space._

### Investigation

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EF/53630C63BDB74DE198EDEA1CDD33F8CB3D53F3EF.png)

### Resolution

#### # Increase the size of "Backup01" VHD

```PowerShell
$vmName = "JUGGERNAUT"

Stop-VM $vmName

Resize-VHD `
    ("C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
        + $vmName + "_Backup01.vhdx") `
    -SizeBytes 12GB

Start-VM $vmName
```

#### # Extend partition

```PowerShell
$size = (Get-PartitionSupportedSize -DiskNumber 4 -PartitionNumber 1)
Resize-Partition -DiskNumber 4 -PartitionNumber 1 -Size $size.SizeMax
```

![(screenshot)](https://assets.technologytoolbox.com/screenshots/55/BB6A37AF1C2E984AE324DDE8398172FF1856DC55.png)

## # Expand Z: (Backup01) drive

---

**ICEMAN**

### # Increase the size of "Backup01" VHD

```PowerShell
$vmName = "JUGGERNAUT"

Resize-VHD `
    ("C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\" `
        + $vmName + "_Backup01.vhdx") `
    -SizeBytes 20GB
```

---

### # Extend partition

```PowerShell
$size = (Get-PartitionSupportedSize -DiskNumber 4 -PartitionNumber 1)
Resize-Partition -DiskNumber 4 -PartitionNumber 1 -Size $size.SizeMax
```

## # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

<table>
<thead>
<th>
<p><strong>Protection Group</strong></p>
</th>
<th>
<p><strong>Group Members</strong></p>
</th>
<th>
<p><strong>Short-Term</strong></p>
</th>
<th>
<p><strong>Goals</strong></p>
</th>
<th>
</th>
</thead>
<tr>
<td valign='top'>
</td>
<td valign='top'>
</td>
<td valign='top'>
<p>Retention range</p>
</td>
<td valign='top'>
<p>Synchronization frequency</p>
</td>
<td valign='top'>
<p>Recovery points</p>
</td>
</tr>
<tr>
<td valign='top'>
<p>Critical Files</p>
</td>
<td valign='top'>
<p>ICEMAN</p>
<ul>
<li>All Volumes
<ul>
<li>D:\\</li>
</ul>
</li>
</ul>
</td>
<td valign='top'>
<p>10 days</p>
</td>
<td valign='top'>
<p>Just before a recovery point</p>
</td>
<td valign='top'>
<p>8:00 AM, 12:00 PM, 5:30 PM Everyday</p>
</td>
</tr>
<tr>
<td valign='top'>
<p>Domain Controllers</p>
</td>
<td valign='top'>
<p>XAVIER1</p>
<ul>
<li>System Protection
<ul>
<li>System State (includes Active Directory)<br />
XAVIER2</li>
</ul>
</li>
</ul>
<ul>
<li>System Protection
<ul>
<li>System State (includes Active Directory)</li>
</ul>
</li>
</ul>
</td>
<td valign='top'>
<p>5 days</p>
</td>
<td valign='top'>
<p>N/A</p>
</td>
<td valign='top'>
<p>8:00 PM Everyday</p>
</td>
</tr>
<tr>
<td valign='top'>
<p>Hyper-V</p>
</td>
<td valign='top'>
<p>BEAST</p>
<ul>
<li>HyperV
<ul>
<li>Host Component</li>
<li>CIPHER01</li>
<li>COLOSSUS</li>
<li>CYCLOPS</li>
<li>POLARIS-TEST<br />
FORGE</li>
</ul>
</li>
</ul>
<ul>
<li>HyperV
<ul>
<li>Host Component</li>
<li>EXT-FOOBAR3</li>
<li>EXT-RRAS1</li>
<li>POLARIS-DEV<br />
ICEMAN</li>
</ul>
</li>
</ul>
<ul>
<li>HyperV
<ul>
<li>Host Component</li>
<li>MOONSTAR<br />
ROGUE</li>
</ul>
</li>
</ul>
<ul>
<li>HyperV
<ul>
<li>Host Component</li>
<li>BANSHEE</li>
<li>CYCLOPS-TEST</li>
<li>EXT-APP01A</li>
<li>foobar</li>
<li>EXT-WEB01B</li>
<li>JUBILEE<br />
STORM</li>
</ul>
</li>
</ul>
<ul>
<li>HyperV
<ul>
<li>Host Component</li>
<li>CRYPTID</li>
<li>DAZZLER</li>
<li>EXT-WEB01A</li>
<li>foobar7</li>
<li>FOOBAR8</li>
<li>MIMIC</li>
<li>POLARIS</li>
</ul>
</li>
</ul>
</td>
<td valign='top'>
<p>5 days</p>
</td>
<td valign='top'>
<p>N/A</p>
</td>
<td valign='top'>
<p>11:00 PM Everyday</p>
</td>
</tr>
<tr>
<td valign='top'>
<p>SQL Server Databases</p>
</td>
<td valign='top'>
<p>HAVOK</p>
<ul>
<li>All SQL Servers
<ul>
<li>(Auto) HAVOK</li>
</ul>
</li>
</ul>
</td>
<td valign='top'>
<p>10 days</p>
</td>
<td valign='top'>
<p>Every 15 minutes</p>
</td>
<td valign='top'>
<p>6:00 PM Everyday</p>
</td>
</tr>
<tr>
<td valign='top'>
<p>SQL Server Databases (TEST)</p>
</td>
<td valign='top'>
<p>HAVOK-TEST</p>
<ul>
<li>All SQL Servers
<ul>
<li>(Auto) HAVOK-TEST</li>
</ul>
</li>
</ul>
</td>
<td valign='top'>
<p>10 days</p>
</td>
<td valign='top'>
<p>Every 4 hour(s)</p>
</td>
<td valign='top'>
<p>7:00 PM Everyday</p>
</td>
</tr>
</table>

![(screenshot)](https://assets.technologytoolbox.com/screenshots/17/755CC35E29B10446B41515C44F11ED70E75D6317.png)

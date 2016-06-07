# EXT-SQL02 - Windows Server 2012 R2 Standard

Wednesday, June 1, 2016
7:19 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure the server infrastructure

### Install Windows Server 2012 R2

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Create virtual machine

```PowerShell
$vmHost = "FORGE"
$vmName = "EXT-SQL02"

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Path E:\NotBackedUp\VMs `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 32GB `
    -MemoryStartupBytes 8GB `
    -SwitchName "Production"

Set-VM `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ProcessorCount 4

Set-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path \\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso

Start-VM -ComputerName $vmHost -Name $vmName
```

---

#### Install custom Windows Server 2012 R2 image

- Start-up disk: [\\\\ICEMAN\\Products\\Microsoft\\MDT-Deploy-x86.iso](\\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso)
- On the **Task Sequence** step, select **Windows Server 2012 R2** and click **Next**.
- On the **Computer Details** step:
  - In the **Computer name** box, type **EXT-SQL02**.
  - Select **Join a workgroup**.
  - In the **Workgroup **box, type **WORKGROUP**.
  - Click **Next**.
- On the **Applications** step, ensure no items are selected and click **Next**.

```PowerShell
cls
```

#### # Copy latest Toolbox content

```PowerShell
net use \\iceman.corp.technologytoolbox.com\IPC$ /USER:TECHTOOLBOX\jjameson
```

> **Note**
>
> When prompted, type the password to connect to the file share.

```Console
robocopy \\iceman.corp.technologytoolbox.com\Public\Toolbox C:\NotBackedUp\Public\Toolbox /E /MIR
```

### # Rename local Administrator account and set password

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

$password = C:\NotBackedUp\Public\Toolbox\PowerShell\Get-SecureString.ps1
```

> **Note**
>
> When prompted, type the password for the local Administrator account.

```PowerShell
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

$adminUser = [ADSI] 'WinNT://./Administrator,User'
$adminUser.Rename('foo')
$adminUser.SetPassword($plainPassword)

logoff
```

### Login as EXT-SQL02\\foo

```PowerShell
cls
```

### # Configure network settings

#### # Rename network connections

```PowerShell
Get-NetAdapter -Physical | select Name, InterfaceDescription

Get-NetAdapter `
    -InterfaceDescription "Microsoft Hyper-V Network Adapter" |
    Rename-NetAdapter -NewName "Production"
```

#### # Configure "Production" network adapter

```PowerShell
$interfaceAlias = "Production"
```

##### # Configure IPv4 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 192.168.10.209,192.168.10.210
```

##### # Configure IPv6 DNS servers

```PowerShell
Set-DNSClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses 2601:282:4201:e500::209,2601:282:4201:e500::210
```

##### # Enable jumbo frames

```PowerShell
Get-NetAdapterAdvancedProperty -DisplayName "Jumbo*"

Set-NetAdapterAdvancedProperty `
    -Name $interfaceAlias `
    -DisplayName "Jumbo Packet" `
    -RegistryValue 9014

ping ICEMAN -f -l 8900
```

```PowerShell
cls
```

### # Join domain

```PowerShell
Add-Computer `
    -DomainName extranet.technologytoolbox.com `
    -Credential (Get-Credential EXTRANET\jjameson-admin) `
    -Restart
```

#### Move computer to "SQL Servers" OU

---

**EXT-DC01 - Run as EXTRANET\\jjameson-admin**

```PowerShell
$computerName = "EXT-SQL02"
$targetPath = ("OU=SQL Servers,OU=Servers,OU=Resources,OU=IT" `
    + ",DC=extranet,DC=technologytoolbox,DC=com")

Get-ADComputer $computerName | Move-ADObject -TargetPath $targetPath

Restart-Computer $computerName
```

---

### Login as EXTRANET\\jjameson-admin

### # Select "High performance" power scheme

```PowerShell
powercfg.exe /L

powercfg.exe /S SCHEME_MIN

powercfg.exe /L
```

### # Change drive letter for DVD-ROM

```PowerShell
$cdrom = Get-WmiObject -Class Win32_CDROMDrive
$driveLetter = $cdrom.Drive

$volumeId = mountvol $driveLetter /L
$volumeId = $volumeId.Trim()

mountvol $driveLetter /D

mountvol X: $volumeId
```

### # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

### # Configure firewall rules for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Enable-RemoteWindowsUpdate.ps1 -Verbose
```

### # Disable firewall rules for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Disable-RemoteWindowsUpdate.ps1 -Verbose
```

```PowerShell
cls
```

### # Install and configure System Center Operations Manager

#### # Create certificate for Operations Manager

##### # Create request for Operations Manager certificate

```PowerShell
& "C:\NotBackedUp\Public\Toolbox\Operations Manager\Scripts\New-OperationsManagerCertificateRequest.ps1"
```

##### # Submit certificate request to the Certification Authority

###### # Add Active Directory Certificate Services site to the "Trusted sites" zone and browse to the site

```PowerShell
$adcsUrl = [Uri] "https://cipher01.corp.technologytoolbox.com"

[string] $registryKey = ("HKCU:\Software\Microsoft\Windows" `
    + "\CurrentVersion\Internet Settings\ZoneMap\EscDomains" `
    + "\$($adcsUrl.Host)")

If ((Test-Path $registryKey) -eq $false)
{
    New-Item $registryKey | Out-Null
}

Set-ItemProperty -Path $registryKey -Name $adcsUrl.Scheme -Value 2

Start-Process $adcsUrl.AbsoluteUri
```

> **Note**
>
> Copy the certificate request to the clipboard.

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

##### # Import the certificate into the certificate store

```PowerShell
$certFile = "C:\Users\jjameson-admin\Downloads\certnew.cer"

CertReq.exe -Accept $certFile

Remove-Item $certFile
```

#### # Install SCOM agent

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

##### # Mount the Operations Manager installation media

```PowerShell
$imagePath = `
    '\\ICEMAN\Products\Microsoft\System Center 2012 R2' `
    + '\en_system_center_2012_r2_operations_manager_x86_and_x64_dvd_2920299.iso'

Set-VMDvdDrive -ComputerName FORGE -VMName EXT-SQL02 -Path $imagePath
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

#### # Import the certificate into Operations Manager using MOMCertImport

```PowerShell
$hostName = ([System.Net.Dns]::GetHostByName(($env:computerName))).HostName

$certImportToolPath = 'X:\SupportTools\AMD64'

Push-Location "$certImportToolPath"

.\MOMCertImport.exe /SubjectName $hostName

Pop-Location
```

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Remove the Operations Manager installation media

```PowerShell
Set-VMDvdDrive -ComputerName STORM -VMName EXT-SQL02 -Path $null
```

---

#### # Approve manual agent install in Operations Manager

### # Enter a product key and activate Windows

```PowerShell
slmgr /ipk {product key}
```

> **Note**
>
> When notified that the product key was set successfully, click **OK**.

```Console
slmgr /ato
```

## Configure VM storage

| Disk | Drive Letter | Volume Size | VHD Type | Allocation Unit Size | Volume Label |
| ---- | ------------ | ----------- | -------- | -------------------- | ------------ |
| 0    | C:           | 32 GB       | Dynamic  | 4K                   | OSDisk       |
| 1    | D:           | 90 GB       | Fixed    | 64K                  | Data01       |
| 2    | L:           | 10 GB       | Fixed    | 64K                  | Log01        |
| 3    | T:           | 4 GB        | Fixed    | 64K                  | Temp01       |
| 4    | Z:           | 100GB       | Dynamic  | 4K                   | Backup01     |

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

### # Create Data01, Log01, and Backup01 VHDs

```PowerShell
$vmHost = "FORGE"
$vmName = "EXT-SQL02"

$vhdPath = "D:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName" `
    + "_Data01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Fixed -SizeBytes 90GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ControllerType SCSI `
    -Path $vhdPath

$vhdPath = "D:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName" `
    + "_Log01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Fixed -SizeBytes 10GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ControllerType SCSI `
    -Path $vhdPath

$vhdPath = "D:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName" `
    + "_Temp01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -Fixed -SizeBytes 4GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ControllerType SCSI `
    -Path $vhdPath

$vhdPath = "E:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName" `
    + "_Backup01.vhdx"

New-VHD -ComputerName $vmHost -Path $vhdPath -SizeBytes 100GB
Add-VMHardDiskDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -ControllerType SCSI `
    -Path $vhdPath
```

---

```PowerShell
cls
```

### # Initialize disks and format volumes

#### # Format Data01 drive

```PowerShell
Get-Disk 1 |
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -DriveLetter D -UseMaximumSize |
    Format-Volume `
        -AllocationUnitSize 64KB `
        -FileSystem NTFS `
        -NewFileSystemLabel "Data01" `
        -Confirm:$false
```

#### # Format Log01 drive

```PowerShell
Get-Disk 2 |
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -DriveLetter L -UseMaximumSize |
    Format-Volume `
        -AllocationUnitSize 64KB `
        -FileSystem NTFS `
        -NewFileSystemLabel "Log01" `
        -Confirm:$false
```

#### # Format Temp01 drive

```PowerShell
Get-Disk 3 |
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -DriveLetter T -UseMaximumSize |
    Format-Volume `
        -AllocationUnitSize 64KB `
        -FileSystem NTFS `
        -NewFileSystemLabel "Temp01" `
        -Confirm:$false
```

#### # Format Backup01 drive

```PowerShell
Get-Disk 4 |
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -DriveLetter Z -UseMaximumSize |
    Format-Volume `
        -FileSystem NTFS `
        -NewFileSystemLabel "Backup01" `
        -Confirm:$false
```

### # Set MaxPatchCacheSize to 0 (Recommended)

```PowerShell
C:\NotBackedUp\Public\Toolbox\PowerShell\Set-MaxPatchCacheSize.ps1 0
```

### Install latest service pack and updates

### Install SQL Server 2014

> **Important**
>
> Login as **EXTRANET\\jjameson-admin** to install SQL Server.

---

**FOOBAR8 - Run as TECHTOOLBOX\\jjameson-admin**

```PowerShell
cls
```

#### # Mount SQL Server 2014 installation media

```PowerShell
$imagePath = "\\ICEMAN\Products\Microsoft\SQL Server 2014" `
    + "\en_sql_server_2014_developer_edition_with_service_pack_1_x64_dvd_6668542.iso"

Set-VMDvdDrive -ComputerName FORGE -VMName EXT-SQL02 -Path $imagePath
```

---

```PowerShell
& X:\setup.exe
```

---

**SQL Server Management Studio**

### -- Configure TempDB data and log files

```SQL
ALTER DATABASE [tempdb]
  MODIFY FILE
  (
    NAME = N'tempdev'
    , SIZE = 512MB
    , MAXSIZE = 768MB
    , FILEGROWTH = 128MB
  );

DECLARE @dataPath VARCHAR(300);

SELECT
  @dataPath = REPLACE([filename], '.mdf','')
FROM
  sysaltfiles s
WHERE
  name = 'tempdev';

DECLARE @sqlStatement NVARCHAR(500);

SELECT @sqlStatement =
  N'ALTER DATABASE [tempdb]'
    + 'ADD FILE'
    + '('
      + 'NAME = N''tempdev2'''
      + ', FILENAME = ''' + @dataPath + '2.mdf'''
      + ', SIZE = 512MB'
      + ', MAXSIZE = 768MB'
      + ', FILEGROWTH = 128MB'
    + ')';

EXEC sp_executesql @sqlStatement;

SELECT @sqlStatement =
  N'ALTER DATABASE [tempdb]'
    + 'ADD FILE'
    + '('
      + 'NAME = N''tempdev3'''
      + ', FILENAME = ''' + @dataPath + '3.mdf'''
      + ', SIZE = 512MB'
      + ', MAXSIZE = 768MB'
      + ', FILEGROWTH = 128MB'
    + ')';

EXEC sp_executesql @sqlStatement;

SELECT @sqlStatement =
  N'ALTER DATABASE [tempdb]'
    + 'ADD FILE'
    + '('
      + 'NAME = N''tempdev4'''
      + ', FILENAME = ''' + @dataPath + '4.mdf'''
      + ', SIZE = 512MB'
      + ', MAXSIZE = 768MB'
      + ', FILEGROWTH = 128MB'
    + ')';

EXEC sp_executesql @sqlStatement;
ALTER DATABASE [tempdb]
  MODIFY FILE (
    NAME = N'templog',
    SIZE = 50MB,
    FILEGROWTH = 10MB
  )
```

---

---

**SQL Server Management Studio**

### -- Configure "Max Degree of Parallelism" for SharePoint

```SQL
EXEC sys.sp_configure N'show advanced options', N'1'
RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'max degree of parallelism', N'1'
RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'show advanced options', N'0'
RECONFIGURE WITH OVERRIDE
GO
```

---

```PowerShell
cls
```

### # Configure permissions on \\Windows\\System32\\LogFiles\\Sum files

```PowerShell
icacls C:\Windows\System32\LogFiles\Sum\Api.chk `
    /grant "NT Service\MSSQLSERVER:(M)"

icacls C:\Windows\System32\LogFiles\Sum\Api.log `
    /grant "NT Service\MSSQLSERVER:(M)"

icacls C:\Windows\System32\LogFiles\Sum\SystemIdentity.mdb `
    /grant "NT Service\MSSQLSERVER:(M)"
```

### # Configure firewall rule for SQL Server

```PowerShell
New-NetFirewallRule `
    -Name 'SQL Server Database Engine' `
    -DisplayName 'SQL Server Database Engine' `
    -Description 'Allows remote access to SQL Server Database Engine' `
    -Group 'SQL Server' `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 1433 `
    -Profile Domain `
    -Action Allow
```

### # Enable TCP/IP protocol for SharePoint 2013 connections (SQL Server 2008 drivers)

```PowerShell
[Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")
[Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlWmiManagement")

$wmi = New-Object ('Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer').

$uri = "ManagedComputer[@Name='" + $env:COMPUTERNAME + "']" `
    + "/ServerInstance[@Name='MSSQLSERVER']" `
    + "/ServerProtocol[@Name='Tcp']"

$tcpProtocol = $wmi.GetSmoObject($uri)
$tcpProtocol.IsEnabled = $true
$tcpProtocol.Alter()

Stop-Service SQLSERVERAGENT

Restart-Service MSSQLSERVER

Start-Sleep -Seconds 15

Start-Service SQLSERVERAGENT
```

## Extend Data01 volume (D:) from 90 GB to 100 GB

> **Note**
>
> This process was performed after completing the SharePoint 2013 upgrade.

---

**FOOBAR8**

```PowerShell
Resize-VHD `
    -ComputerName FORGE `
    -Path "D:\NotBackedUp\VMs\EXT-SQL02\Virtual Hard Disks\EXT-SQL02_Data01.vhdx" `
    -SizeBytes 100GB
```

---

```PowerShell
Get-Partition -DriveLetter D


   Disk Number: 1

PartitionNumber  DriveLetter Offset                                        Size Type
---------------  ----------- ------                                        ---- ----
1                D           1048576                                      90 GB IFS


$size = (Get-PartitionSupportedSize -DiskNumber 1 -PartitionNumber 1)
Resize-Partition -DiskNumber 1 -PartitionNumber 1 -Size $size.SizeMax

Get-Partition -DriveLetter D


   Disk Number: 1

PartitionNumber  DriveLetter Offset                                        Size Type
---------------  ----------- ------                                        ---- ----
1                D           1048576                                     100 GB IFS
```

## Expand backup volume

### Move Backup01 VHD to ICEMAN

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2D/46330C9362DF59D31244DB17343DB02AD347DA2D.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A4/ADCD983D2D2DE13DFD89F290C422657B60B56EA4.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/45/2ECA83F8FA9B7176D3C56DB206E24C52BE3AA945.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F8/E66D481A46AAF46A104498D1B05E485CF139B7F8.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D3/266B4D6C29727F78869BF395A29981B99307A4D3.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/50/031E8050C3B45BF87F9005878CB1BFC072D8AA50.png)

[\\\\iceman.corp.technologytoolbox.com\\VM-Storage-Silver\\EXT-SQL02\\](\\iceman.corp.technologytoolbox.com\VM-Storage-Silver\EXT-SQL02\)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A7/6A447F908B86F86BB402798E18C66BD1804F24A7.png)

### Expand Backup01 VHD

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E2/E834DBFBBE0CFCF7438E01135C6A14D7492F97E2.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/CE/C54D0749E02FBEB34351F072EA790A96187DB1CE.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/48/743059D28409658B0C323C8845C9EA339EC9ED48.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D5/E57C24239D9F888F68A7EDF48E7DC4F44DB337D5.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/2C/45FF1EB4EBB351B0F4B1C872A0B7D3DF96A78C2C.png)

```PowerShell
cls
```

### # Expand Z: partition

```PowerShell
$maxSize = (Get-PartitionSupportedSize -DriveLetter Z).SizeMax

Resize-Partition -DriveLetter Z -Size $maxSize
```

```PowerShell
cls
```

## # Configure SQL Server backups

### # Delete PROD backups

```PowerShell
Remove-Item "Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full" -Recurse
```

### # Create folders for backups

```PowerShell
mkdir "Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Differential"
mkdir "Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Full"
mkdir "Z:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\Transaction Log"
```

### Create maintenance plans

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A4/92EAB0ACBC0CFA9CE4DEDC7EC4E11178C6E4BEA4.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3B/6B2D0A94DA29FE8AE6BE575600EAAC81FC39453B.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/ED/68EC3AB26AEEC9F704CA15C22E2335A8DEC27AED.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/0F/9D4735C00E9C5A69DF9513C8C2970FF05CD1E20F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/EF/0840D973A0BE838AFA974EA8DD0C037A1AA002EF.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/94/9F33C9E1FCAEF021C023C2CBBF3A9FE0D6E45A94.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/47/F4B705FEB0DABFBEB96891879D18AB5A2B9AC947.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/F7/D1F01DF32846332C9F50696D6218DF9195998EF7.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/30/F0F72922397B1B266B1C1C6864B8B766CD9B1E30.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/10/12FCA3503A84FD62BE38507210566B0949435E10.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/FD/92974E28265DE92F42D0A7A2C240A4B2E0A6C0FD.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/68/348133783DF27FFC3442A97FF0D633E9F6E3E468.png)

Click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/77/AA95227C0936FC4B3D3767EFD2A87740A7D2A877.png)

Click Finish.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/D4/D4E1C303E2A2B267DF7CF29BDAD4AC6871DAB7D4.png)

Click Close.

Execute maintenance plan to backup databases.

Diff backups

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E6/5D0821A67E2699D0E7D61751FF92DEE479CD8EE6.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A5/910820131F02D93389562BE1629678A07E5D11A5.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/71/DE90D224862447B2AF95A5A43E0D566ED9982971.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C5/1A8EF1DB5B2FF306796C1F3BD0FE249D6895D9C5.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/AE/E9DDBF6B6B3BDC73A9D9BF53CC94F043B066B4AE.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/87/F52787696AF303146E9A28C77604A432D42E0687.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/A1/EFFC50003F55582EE106DB9D4B650478534817A1.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B0/F2D247EEC5EBC002CF6E30E269F22895EE044FB0.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/68/348133783DF27FFC3442A97FF0D633E9F6E3E468.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/66/199D5CF3E0D38BDCD201AFA56CCA7BDB46F50866.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B6/022C9A742A243162881FBA86EEA5D85466A9D9B6.png)

Tran logs

Transaction Log Backup of All Databases

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C4/50DBCFEA92E579D8141565980415B7BA2B3CC4C4.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B1/C9526CAB07B7C275D5B24E901D2CA5E623CBCEB1.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/8B/67B61D66F6141F1B2E143AA4EE162A552013868B.png)

## Execute maintenance plan - Full Backup of All Databases

Start 6/2/2016 8:46:36 PM\
End 6/2/2016 9:06:18 PM

Duration: 20 minutes

### Network utilization

#### ICEMAN

![(screenshot)](https://assets.technologytoolbox.com/screenshots/BC/F73B1828336A853D8A19AE9442B01DC636D377BC.png)

#### FORGE

![(screenshot)](https://assets.technologytoolbox.com/screenshots/83/C7EA41467D7EDE7354A56C648F4193B734B3D583.png)

### Solution

#### Move VHD back to DAS

**E:\\NotBackedUp\\VMs\\EXT-SQL02\\Virtual Hard Disks\\EXT-SQL02_Backup01.vhdx**

Start 6/3/2016 4:09:21 AM\
End 6/3/2016 4:17:51 AM

Duration: 8.5 minutes

## Configure DCOM permissions for SQL Server

### Issue

Source: DCOM\
Event ID: 10016\
Event Category: 0\
User: NT SERVICE\\SQLSERVERAGENT\
Computer: EXT-SQL02.extranet.technologytoolbox.com\
Event Description: The application-specific permission settings do not grant Local Activation permission for the COM Server application with CLSID\
{806835AE-FD04-4870-A1E8-D65535358293}\
and APPID\
{EE4171E6-C37E-4D04-AF4C-8617BC7D4914}\
to the user NT SERVICE\\SQLSERVERAGENT SID (S-1-5-80-344959196-2060754871-2302487193-2804545603-1466107430) from address LocalHost (Using LRPC) running in the application container Unavailable SID (Unavailable). This security permission can be modified using the Component Services administrative tool.

> **Note**
>
> **EE4171E6-C37E-4D04-AF4C-8617BC7D4914** is the ID for **Microsoft SQL Server Integration Services 12.0**.

### Solution

```PowerShell
& 'C:\NotBackedUp\Public\Toolbox\SQL\Configure DCOM Permissions.ps1'
```

**TODO:**

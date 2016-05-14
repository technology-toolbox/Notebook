# COLOSSUS - Windows Server 2012 R2

Monday, May 18, 2015
7:42 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Create service account for WSUS

---

**XAVIER1**

### # Create the WSUS service account

```PowerShell
$displayName = "Service account for Windows Server Update Services"
$defaultUserName = "s-wsus"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$userPrincipalName = $cred.UserName + "@corp.technologytoolbox.com"
$orgUnit = "OU=Service Accounts,OU=IT,DC=corp,DC=technologytoolbox,DC=com"

New-ADUser `
    -Name $displayName `
    -DisplayName $displayName `
    -SamAccountName $cred.UserName `
    -AccountPassword $cred.Password `
    -UserPrincipalName $userPrincipalName `
    -Path $orgUnit `
    -Enabled:$true `
    -CannotChangePassword:$true `
    -PasswordNeverExpires:$true
```

---

## Create VM

- Processors: **2**
- Memory: **2 GB**
- VHD size (GB): **32**
- VHD file name:** COLOSSUS**

## Install custom Windows Server 2012 R2 image

- Start-up disk: [\\\\ICEMAN\\Products\\Microsoft\\MDT-Deploy-x86.iso](\\ICEMAN\Products\Microsoft\MDT-Deploy-x86.iso)
- On the **Task Sequence** step, select **Windows Server 2012 R2** and click **Next**.
- On the **Computer Details** step, in the **Computer name** box, type **COLOSSUS** and click **Next**.
- On the **Applications** step, do not select any applications, and click **Next**.

```PowerShell
cls
```

## # Set password for local Administrator account

```PowerShell
$adminUser = [ADSI] "WinNT://./Administrator,User"
$adminUser.SetPassword("{password}")
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

## # Change drive letter for DVD-ROM

```PowerShell
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

## Create share for WSUS content

---

**ICEMAN**

### # Create and share the WSUS\$ folder

```PowerShell
New-Item -Path D:\Shares\WSUS$ -ItemType Directory

New-SmbShare `
    -Name WSUS$ `
    -Path D:\Shares\WSUS$ `
    -CachingMode None `
    -ChangeAccess Everyone
```

#### # Remove "BUILTIN\\Users" permissions

```PowerShell
icacls D:\Shares\WSUS$ /inheritance:d
icacls D:\Shares\WSUS$ /remove:g "BUILTIN\Users"
```

#### # Grant COLOSSUS computer account modify access to WSUS share

```PowerShell
icacls D:\Shares\WSUS$ /grant 'COLOSSUS$:(OI)(CI)(M)'
```

#### # Grant WSUS service account read access to WSUS share

```PowerShell
icacls D:\Shares\WSUS$ /grant 'TECHTOOLBOX\s-wsus:(OI)(CI)(RX)'
```

---

## Install WSUS

![(screenshot)](https://assets.technologytoolbox.com/screenshots/30/95F18511CC7247AEBFB056D86C056311CDF89630.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/86/FB846A250D3906A80B6BCADC82439502C78B2186.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/57/DECAEA9056214F80ED23DAC35925BD48E9DFED57.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/DB/6A839CBEFF04B4FE038EAC4BA699F2F44B5520DB.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B7/E46D8D9A779C378B7EC40C8FC9D7CFE8F7C85AB7.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/94/9A7204B4F1488D1F20747C3E64D592EEF2A42A94.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/B0/BC7F47D96B2DED1BF4D3F703154465A103A903B0.png)

**Note:** .NET Framework 3.5 is already installed (included in custom Windows Server 2012 R2 image).

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

Configure WSUS database

Change auto-grow increment on SUSDB.mdf from 1 MB to 100 MB

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
  - Silverlight
  - SQL Server
  - System Center
    - System Center 2012 R2 - Data Protection Manager
    - System Center 2012 R2 - Operations Manager
    - System Center 2012 R2 - Virtual Machine Manager
  - Windows

![(screenshot)](https://assets.technologytoolbox.com/screenshots/37/372FF0C6359D82EF6FF36E118CADD1024F6E8837.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3E/75DA8705948A2A9DCCED07E493A3A33B1F36C33E.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C3/D387144AB751593511B9A78CAAB1D264168EF5C3.png)

Select **Begin initial synchronization** and then click **Next**.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/3F/FF3B78505B859800A50E68D1C4D807B58970083F.png)

![(screenshot)](https://assets.technologytoolbox.com/screenshots/69/C2ED7EF76661D9D8F560C4B789BB83208296D369.png)

## Fix path for "Content" virtual directory

![(screenshot)](https://assets.technologytoolbox.com/screenshots/E8/89D2BA3C12018E4D5D803D92766E367ABB5364E8.png)

```PowerShell
Import-Module WebAdministration

Set-ItemProperty `
    "IIS:\Sites\WSUS Administration\Content" `
    -Name physicalPath `
    -Value "\\ICEMAN\WSUS$\WsusContent\"
```

## # Set credentials for accessing WSUS content on ICEMAN

```PowerShell
$displayName = "Service account for Windows Server Update Services"
$defaultUserName = "TECHTOOLBOX\s-wsus"

$cred = Get-Credential -Message $displayName -UserName $defaultUserName

$password = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR(
        $cred.Password))

Set-ItemProperty `
    "IIS:\Sites\WSUS Administration\Content" `
    -Name userName `
    -Value $cred.UserName

Set-ItemProperty `
    "IIS:\Sites\WSUS Administration\Content" `
    -Name password `
    -Value $password
```

## Configure group policy for Windows Update

![(screenshot)](https://assets.technologytoolbox.com/screenshots/05/4F75EE5CAEDF7E8EFB10F970F7B2301F4CB07905.png)

## Add computer groups

Computers

- All Computers
  - Unassigned Computers
  - .**NET Framework 3.5**
  - **.NET Framework 4**
  - **.NET Framework 4 Client Profile**
  - **.NET Framework 4.5**
  - **Fabrikam**
    - **Fabrikam - Development**
    - **Fabrikam - Quality Assurance**
      - **Fabrikam - Beta Testing**
  - **Internet Explorer 10**
  - **Internet Explorer 11**
  - **Internet Explorer 7**
  - **Internet Explorer 8**
  - **Internet Explorer 9**
  - **Silverlight**
  - **Technology Toolbox**
    - **Development**
    - **Quality Assurance**
      - **Beta Testing**
    - **WSUS Servers**

1. In the **Update Services** console, in the navigation pane, expand **Computers**, and then select **All Computers**.
2. In the **Actions** pane, click **Add Computer Group...**
3. In the **Add Computer Group** window, in the **Name** box, type the name for the new computer group and click **OK**.

Configure automatic approval rules

![(screenshot)](https://assets.technologytoolbox.com/screenshots/C5/8802A21A02AE3A0F8F9E06A10EEE7D1EC50BDCC5.png)

1. In the **Automatic Approvals** window, on the **Update Rules** tab, select **Default Automatic Approval Rule**.
2. In the **Rule properties** section, click **Critical Updates, Security Updates**.
3. In the **Choose Update Classifications** window:
   1. Select **Definition Updates**.
   2. Clear the checkboxes for all other update classifications.
   3. Click** OK**.
4. Confirm the **Rule properties** for the **Default Automatic Approval Rule** are configured as follows:**When an update is in Definition UpdatesApprove the update for all computers**
5. Select the **Default Automatic Approval Rule** checkbox.
6. Click **New Rule...**
7. In the **Add Rule** window:
   1. In the **Step 1: Select properties** section, select** When an update is in a specific classification**.
   2. In the **Step 2: Edit the properties** section:
      1. Click **any classification**.
         1. In the **Choose Update Classifications **window:
            1. Clear the **All Classifications **checkbox.
            2. Select the following checkboxes:
               - **Critical Updates**
               - **Security Updates**
         2. Click **OK**.
      2. Click **all computers**
         1. In the **Choose Computer Groups** window:
            1. Clear the **All Computers** checkbox.
            2. Select the following checkboxes:
               - **Fabrikam / Fabrikam - Quality Assurance / Fabrikam - Beta Testing**
               - **Technology Toolbox / Quality Assurance / Beta Testing**
         2. Click **OK**.
   3. In the **Step 3: Specify a name **box, type **Beta Testing Approval Rule**.
   4. Click **OK**.
8. In the **Automatic Approvals** window:
   1. Confirm the **Rule properties** for the **Beta Testing Approval Rule** are configured as follows:**When an update is in Critical Updates, Security UpdatesApprove the update for Fabrikam - Beta Testing, Beta Testing**
   2. Click **OK**.

## Install Report Viewer 2008 SP1

**Note: **.NET Framework 2.0 is required for Microsoft Report Viewer 2008 SP1.

```PowerShell
& '\\ICEMAN\Public\Download\Microsoft\Report Viewer 2008 SP1\ReportViewer.exe'
```

```PowerShell
cls
```

## # Enter a product key and activate Windows

```PowerShell
slmgr /ipk {product key}
```

**Note:** When notified that the product key was set successfully, click **OK**.

```Console
slmgr /ato
```

## # Install SCOM agent

```PowerShell
$imagePath = '\\ICEMAN\Products\Microsoft\System Center 2012 R2' `
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

## # Configure firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

---

**FOOBAR8**

```PowerShell
$computer = 'COLOSSUS'

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

## Issue: Windows Update (KB3159706) broke WSUS console

### Issue

WSUS clients started failing with error 0x8024401C

Attempting to open WSUS console generated errors, which led to the discovery of the following errors in the event log:

Log Name:      Application\
Source:        Windows Server Update Services\
Date:          5/13/2016 8:39:56 AM\
Event ID:      507\
Task Category: 1\
Level:         Error\
Keywords:      Classic\
User:          N/A\
Computer:      COLOSSUS.corp.technologytoolbox.com\
Description:\
Update Services failed its initialization and stopped.

Log Name:      System\
Source:        Service Control Manager\
Date:          5/13/2016 8:39:56 AM\
Event ID:      7031\
Task Category: None\
Level:         Error\
Keywords:      Classic\
User:          N/A\
Computer:      COLOSSUS.corp.technologytoolbox.com\
Description:\
The WSUS Service service terminated unexpectedly.  It has done this 1 time(s).  The following corrective action will be taken in 300000 milliseconds: Restart the service.

### References

**Update enables ESD decryption provision in WSUS in Windows Server 2012 and Windows Server 2012 R2**\
From <[https://support.microsoft.com/en-us/kb/3159706](https://support.microsoft.com/en-us/kb/3159706)>

**The long-term fix for KB3148812 issues**\
From <[https://blogs.technet.microsoft.com/wsus/2016/05/05/the-long-term-fix-for-kb3148812-issues/](https://blogs.technet.microsoft.com/wsus/2016/05/05/the-long-term-fix-for-kb3148812-issues/)>

### Solution

Manual steps required to complete the installation of this update

1. Open an elevated Command Prompt window, and then run the following command (case sensitive, assume "C" as the system volume):
"C:\\Program Files\\Update Services\\Tools\\wsusutil.exe" postinstall /servicing
2. Select **HTTP Activation **under **.NET Framework 4.5 Features** in the Server Manager Add Roles and Features wizard.
3. Restart the WSUS service.

![(screenshot)](https://assets.technologytoolbox.com/screenshots/7D/06E6407CAFFDA2F33739002CABD4137317C46E7D.jpg)

From <[https://support.microsoft.com/en-us/kb/3159706](https://support.microsoft.com/en-us/kb/3159706)>

# TT-UBU16-DEV1 - Ubuntu 16.04 Desktop

Tuesday, February 20, 2018
4:32 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure infrastructure

---

**WOLVERINE - Run as local administrator**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmName = "TT-UBU16-DEV1"
$vmPath = "D:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 20GB `
    -MemoryStartupBytes 4GB `
    -SwitchName "Management"

Set-VM `
    -Name $vmName `
    -AutomaticCheckpointsEnabled $false `
    -ProcessorCount 4 `
    -StaticMemory

Add-VMDvdDrive `
    -VMName $vmName

$vmDvdDrive = Get-VMDvdDrive `
    -VMName $vmName

Set-VMFirmware `
    -VMName $vmName `
    -EnableSecureBoot Off `
    -FirstBootDevice $vmDvdDrive

Set-VMDvdDrive `
    -VMName $vmName `
    -Path "\\TT-FS01\Products\Ubuntu\ubuntu-16.04.3-desktop-amd64.iso"

Start-VM -Name $vmName
```

---

### Install Linux desktop

### # Install security updates

```Shell
sudo unattended-upgrade -v

reboot
```

### # Check IP address

```Shell
ifconfig | grep "inet addr"
```

### # Enable SSH

```Shell
sudo apt-get install openssh-server
```

---

**WOLVERINE - Run as local administrator**

```PowerShell
cls
```

### # Checkpoint VM

```PowerShell
$checkpointName = "Baseline Ubuntu Desktop 16.04"
$vmName = "TT-UBU16-DEV1"

Stop-VM -Name $vmName

Checkpoint-VM `
    -Name $vmName `
    -SnapshotName $checkpointName

Start-VM -Name $vmName
```

---

### Configure Active Directory integration

#### References

**Join Ubuntu 16.04 into Active Directory Domain**\
From <[http://ricktbaker.com/2017/11/08/ubuntu-16-with-active-directory-connectivity/](http://ricktbaker.com/2017/11/08/ubuntu-16-with-active-directory-connectivity/)>

**SSSD and Active Directory**\
From <[https://help.ubuntu.com/lts/serverguide/sssd-ad.html](https://help.ubuntu.com/lts/serverguide/sssd-ad.html)>

**Realmd and SSSD Active Directory Authentication**\
From <[http://outsideit.net/realmd-sssd-ad-authentication/](http://outsideit.net/realmd-sssd-ad-authentication/)>

#### # Install packages

```Shell
sudo apt install krb5-user ntp realmd samba sssd
```

#### # Configure NTP

```Shell
sudo nano /etc/ntp.conf
```

---

**/etc/ntp.conf**

```
...

# Specify one or more NTP servers.
server tt-dc04.corp.technologytoolbox.com
server tt-dc05.corp.technologytoolbox.com

# Use servers from the NTP Pool Project. Approved by Ubuntu Technical Board
# on 2011-02-08 (LP: #104525). See http://www.pool.ntp.org/join.html for
# more information.
#pool 0.ubuntu.pool.ntp.org iburst
#pool 1.ubuntu.pool.ntp.org iburst
#pool 2.ubuntu.pool.ntp.org iburst
#pool 3.ubuntu.pool.ntp.org iburst

# Use Ubuntu's ntp server as a fallback.
#pool ntp.ubuntu.com

...
```

---

```Shell
/etc/init.d/ntp restart
```

```Shell
clear
```

#### # Join machine to domain

sudo realm join corp.technologytoolbox.com --user-principal=jjameson-admin@CORP.TECHNOLOGYTOOLBOX.COM --verbose

sudo kinit jjameson-admin@CORP.TECHNOLOGYTOOLBOX.COM

sudo realm --verbose join my.domain.com --user-principal=UBUNTU/administrator@MY.DOMAIN.COM

From <[http://ricktbaker.com/2017/11/08/ubuntu-16-with-active-directory-connectivity/](http://ricktbaker.com/2017/11/08/ubuntu-16-with-active-directory-connectivity/)>

# Configure Ubuntu desktop authentication

sudo nano /etc/lightdm/lightdm.conf.d/50-unity-greeter.conf

# TT-DOCKER01

Wednesday, May 8, 2019
2:43 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure infrastructure

---

**FOOBAR18 - Run as local administrator**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "TT-DOCKER01"
$vmPath = "D:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 25GB `
    -MemoryStartupBytes 4GB `
    -SwitchName "Embedded Team Switch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -AutomaticCheckpointsEnabled $false `
    -ProcessorCount 4 `
    -StaticMemory

Add-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName

$vmDvdDrive = Get-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName

Set-VMFirmware `
    -ComputerName $vmHost `
    -VMName $vmName `
    -EnableSecureBoot Off `
    -FirstBootDevice $vmDvdDrive

Set-VMDvdDrive `
    -ComputerName $vmHost `
    -VMName $vmName `
    -Path "\\TT-FS01\Products\Ubuntu\ubuntu-18.04.2-live-server-amd64.iso"

Set-VMDvdDrive : Failed to add device 'Virtual CD/DVD Disk'.
User Account does not have permission to open attachment.
'TT-DOCKER01' failed to add device 'Virtual CD/DVD Disk'. (Virtual machine ID 59625409-653B-4E4C-A382-0B6AFF01741D)
'TT-DOCKER01': User account does not have permission required to open attachment
'\\TT-FS01\Products\Ubuntu\ubuntu-18.04.2-live-server-amd64.iso'. Error: 'General access denied error' (0x80070005). (Virtual machine
ID 59625409-653B-4E4C-A382-0B6AFF01741D)
At line:1 char:1
+ Set-VMDvdDrive `
+ ~~~~~~~~~~~~~~~~
    + CategoryInfo          : PermissionDenied: (:) [Set-VMDvdDrive], VirtualizationException
    + FullyQualifiedErrorId : AccessDenied,Microsoft.HyperV.PowerShell.Commands.SetVMDvdDrive

$iso = Get-SCISO |
    where {$_.Name -eq "ubuntu-18.04.2-live-server-amd64.iso"}

Get-SCVirtualMachine -Name $vmName | Read-SCVirtualMachine

Get-SCVirtualMachine -Name $vmName |
    Get-SCVirtualDVDDrive |
    Set-SCVirtualDVDDrive -ISO $iso -Link

#Start-VM -ComputerName $vmHost -Name $vmName
Start-SCVirtualMachine -VM $vmName
```

---

### Install Linux server

> **Note**
>
> When prompted, restart the computer to complete the installation.

### Install updates using Software Updater

### # Update APT packages

```Shell
sudo apt-get update
sudo apt-get upgrade -y
```

### # Install security updates

```Shell
sudo unattended-upgrade -v
```

> **Note**
>
> Wait for the updates to be installed and then restart the computer.

```Shell
sudo reboot
```

### # Check IP address

```Shell
ifconfig | grep inet
```

### # Enable SSH

```Shell
sudo apt install openssh-server -y
```

---

**FOOBAR18 - Run as local administrator**

```PowerShell
cls
```

### # Checkpoint VM

```PowerShell
$checkpointName = "Baseline Ubuntu Server 18.04.2"
$vmName = "TT-DOCKER01"

Stop-SCVirtualMachine -VM $vmName

New-SCVMCheckpoint -VM $vmName -Name $checkpointName

Start-SCVirtualMachine -VM $vmName
```

---

### Configure Active Directory integration

#### References

**Windows Integration Guide**\
From <[https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/windows_integration_guide/](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/windows_integration_guide/)>

**Join Ubuntu 18.04 to Active Directory**\
From <[https://bitsofwater.com/2018/05/08/join-ubuntu-18-04-to-active-directory/](https://bitsofwater.com/2018/05/08/join-ubuntu-18-04-to-active-directory/)>

**Join Ubuntu 16.04 into Active Directory Domain**\
From <[http://ricktbaker.com/2017/11/08/ubuntu-16-with-active-directory-connectivity/](http://ricktbaker.com/2017/11/08/ubuntu-16-with-active-directory-connectivity/)>

**SSSD and Active Directory**\
From <[https://help.ubuntu.com/lts/serverguide/sssd-ad.html](https://help.ubuntu.com/lts/serverguide/sssd-ad.html)>

**Realmd and SSSD Active Directory Authentication**\
From <[http://outsideit.net/realmd-sssd-ad-authentication/](http://outsideit.net/realmd-sssd-ad-authentication/)>

```Shell
clear
```

#### # Validate DNS servers

```PowerShell
systemd-resolve --status

...
        DNS Servers: 10.1.30.2
                     10.1.30.3
...
```

```PowerShell
clear
```

#### # Validate Active Directory DNS records

##### # Validate LDAP SRV records

```Shell
dig -t SRV _ldap._tcp.corp.technologytoolbox.com

; <<>> DiG 9.11.3-1ubuntu1.7-Ubuntu <<>> -t SRV _ldap._tcp.corp.technologytoolbox.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 16964
;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;_ldap._tcp.corp.technologytoolbox.com. IN SRV

;; ANSWER SECTION:
_ldap._tcp.corp.technologytoolbox.com. 600 IN SRV 0 100 389 TT-DC08.corp.technologytoolbox.com.
_ldap._tcp.corp.technologytoolbox.com. 600 IN SRV 0 100 389 TT-DC09.corp.technologytoolbox.com.

;; Query time: 1 msec
;; SERVER: 127.0.0.53#53(127.0.0.53)
;; WHEN: Wed May 08 21:22:31 UTC 2019
;; MSG SIZE  rcvd: 122
```

```Shell
clear
```

##### # Validate domain controller SRV records

```Shell
dig @10.1.30.2 -t SRV _ldap._tcp.dc._msdcs.corp.technologytoolbox.com

; <<>> DiG 9.11.3-1ubuntu1.7-Ubuntu <<>> @10.1.30.2 -t SRV _ldap._tcp.dc._msdcs.corp.technologytoolbox.com
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 22021
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4000
;; QUESTION SECTION:
;_ldap._tcp.dc._msdcs.corp.technologytoolbox.com. IN SRV

;; ANSWER SECTION:
_ldap._tcp.dc._msdcs.corp.technologytoolbox.com. 600 IN SRV 0 100 389 TT-DC08.corp.technologytoolbox.com.
_ldap._tcp.dc._msdcs.corp.technologytoolbox.com. 600 IN SRV 0 100 389 TT-DC09.corp.technologytoolbox.com.

;; ADDITIONAL SECTION:
TT-DC08.corp.technologytoolbox.com. 3600 IN A   10.1.30.2
TT-DC09.corp.technologytoolbox.com. 3600 IN A   10.1.30.3

;; Query time: 1 msec
;; SERVER: 10.1.30.2#53(10.1.30.2)
;; WHEN: Wed May 08 21:24:53 UTC 2019
;; MSG SIZE  rcvd: 216
```

```Shell
clear
```

#### # Install prerequisites for using realmd

```Shell
sudo apt install realmd -y
```

```Shell
clear
```

#### # Install dependencies for joining Active Directory domain

```Shell
sudo apt install \
    sssd-tools \
    sssd \
    libnss-sss \
    libpam-sss \
    adcli \
    samba-common-bin \
    packagekit \
    -y
```

#### Configure realmd

> **Note**
>
> Note the default home directory path (specified by the **fallback_homedir** setting in **/etc/sssd/sssd.conf**) is **/home/%u@%d** (e.g. **/home/jjameson@corp.technologytoolbox.com**). To create home directories under a "domain" directory, the **default-home** setting is specified in **/etc/realmd.conf** prior to joining the Active Directory domain.

```Shell
sudoedit /etc/realmd.conf
```

---

**/etc/realmd.conf**

```INI
[users]
default-home = /home/%D/%U

[corp.technologytoolbox.com]
fully-qualified-names = no
```

---

##### Reference

**realmd.conf**\
From <[https://www.freedesktop.org/software/realmd/docs/realmd-conf.html](https://www.freedesktop.org/software/realmd/docs/realmd-conf.html)>

```Shell
clear
```

#### # Modify hostname to avoid error registering SPN on computer account

```Shell
sudoedit /etc/hostname
```

---

**/etc/hostname**

```PowerShell
tt-docker01.corp.technologytoolbox.com
```

---

```Shell
sudo reboot

cat /etc/hostname

tt-docker01

sudo hostnamectl set-hostname tt-docker01.corp.technologytoolbox.com

cat /etc/hostname

tt-docker01.corp.technologytoolbox.com
```

> **Note**
>
> Changing the hostname to the fully qualified domain name avoids an error when creating the service principal name for the computer account when joining the Active Directory domain. For example:
>
> ```Text
>  * Modifying computer account: userPrincipalName
>  ! Couldn't set service principals on computer account CN=tt-docker01,CN=Computers,DC=corp,DC=technologytoolbox,DC=com: 00002083: AtrErr: DSID-03151904, #1:
>         0: 00002083: DSID-03151904, problem 1006 (ATT_OR_VALUE_EXISTS), data 0, Att 90303 (servicePrincipalName)
> ```
>
> **realmd: Set service principals on computer account fails**\
> From <[https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=858981](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=858981)>

```Shell
clear
```

#### # Discover Active Directory domain

```Shell
realm discover corp.technologytoolbox.com -v

 * Resolving: _ldap._tcp.corp.technologytoolbox.com
 * Performing LDAP DSE lookup on: 10.1.30.3
 * Performing LDAP DSE lookup on: 10.1.30.2
 * Successfully discovered: corp.technologytoolbox.com
corp.technologytoolbox.com
  type: kerberos
  realm-name: CORP.TECHNOLOGYTOOLBOX.COM
  domain-name: corp.technologytoolbox.com
  configured: no
  server-software: active-directory
  client-software: sssd
  required-package: sssd-tools
  required-package: sssd
  required-package: libnss-sss
  required-package: libpam-sss
  required-package: adcli
  required-package: samba-common-bin
```

```Shell
clear
```

#### # Join Active Directory domain

```Text
sudo realm join -v -U jjameson-admin corp.technologytoolbox.com --os-name="Linux (Ubuntu Server)" --os-version=18.04

[sudo] password for foo:
 * Resolving: _ldap._tcp.corp.technologytoolbox.com
 * Performing LDAP DSE lookup on: 10.1.30.2
 * Performing LDAP DSE lookup on: 10.1.30.3
 * Successfully discovered: corp.technologytoolbox.com
Password for jjameson-admin:
 * Unconditionally checking packages
 * Resolving required packages
 * LANG=C /usr/sbin/adcli join --verbose --domain corp.technologytoolbox.com --domain-realm CORP.TECHNOLOGYTOOLBOX.COM --domain-controller 10.1.30.2 --os-name Linux (Ubuntu Server) --os-version 18.04 --login-type user --login-user jjameson-admin --stdin-password
 * Using domain name: corp.technologytoolbox.com
 * Calculated computer account name from fqdn: TT-DOCKER01
 * Using domain realm: corp.technologytoolbox.com
 * Sending netlogon pings to domain controller: cldap://10.1.30.2
 * Received NetLogon info from: TT-DC08.corp.technologytoolbox.com
 * Wrote out krb5.conf snippet to /var/cache/realmd/adcli-krb5-6IKiEq/krb5.d/adcli-krb5-conf-z6bri9
 * Authenticated as user: jjameson-admin@CORP.TECHNOLOGYTOOLBOX.COM
 * Looked up short domain name: TECHTOOLBOX
 * Using fully qualified name: tt-docker01
 * Using domain name: corp.technologytoolbox.com
 * Using computer account name: TT-DOCKER01
 * Using domain realm: corp.technologytoolbox.com
 * Calculated computer account name from fqdn: TT-DOCKER01
 * Generated 120 character computer password
 * Using keytab: FILE:/etc/krb5.keytab
 * Computer account for TT-DOCKER01$ does not exist
 * Found well known computer container at: CN=Computers,DC=corp,DC=technologytoolbox,DC=com
 * Calculated computer account: CN=TT-DOCKER01,CN=Computers,DC=corp,DC=technologytoolbox,DC=com
 * Created computer account: CN=TT-DOCKER01,CN=Computers,DC=corp,DC=technologytoolbox,DC=com
 * Set computer password
 * Retrieved kvno '2' for computer account in directory: CN=TT-DOCKER01,CN=Computers,DC=corp,DC=technologytoolbox,DC=com
 * Modifying computer account: dNSHostName
 * Modifying computer account: userAccountControl
 * Modifying computer account: operatingSystem, operatingSystemVersion, operatingSystemServicePack
 * Modifying computer account: userPrincipalName
 * Discovered which keytab salt to use
 * Added the entries to the keytab: TT-DOCKER01$@CORP.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb5.keytab
 * Added the entries to the keytab: host/TT-DOCKER01@CORP.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb5.keytab
 * Added the entries to the keytab: host/TT-DOCKER01.corp.technologytoolbox.com@CORP.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb5.keytab
 * Added the entries to the keytab: RestrictedKrbHost/TT-DOCKER01@CORP.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb5.keytab  * Added the entries to the keytab: RestrictedKrbHost/TT-DOCKER01.corp.technologytoolbox.com@CORP.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb5.keytab
 * /usr/sbin/update-rc.d sssd enable
 * /usr/sbin/service sssd restart
 * Successfully enrolled machine in realm

sudo reboot
```

```Shell
clear
```

#### # Test the system configuration after joining the domain

```Shell
id jjameson-admin

uid=453810610(jjameson-admin) gid=453800513(domain users) groups=453800513(domain users),453805108(sql server admins (dev)),453805111(team foundation server admins (dev)),453800512(domain admins),453805109(sharepoint admins (dev)),453807606(folder redirection users),453820632(network controller (nc01) admins),453804121(sql server admins),453806113(sharepoint admins (test)),453806114(team foundation server admins (test)),453809619(vmm admins),453805619(team foundation server admins),453807608(roaming user profiles users and computers),453805616(sharepoint admins),453800572(denied rodc password replication group),453800519(enterprise admins),453800518(schema admins),453806106(sql server admins (test))
```

```Shell
clear
```

#### # Configure home directories

```Shell
sudoedit /etc/pam.d/common-session
```

---

**/etc/pam.d/common-session**

```Text
...
# and here are more per-package modules (the "Additional" block)
session required        pam_unix.so
session required        pam_mkhomedir.so umask=0077
session optional                        pam_sss.so
session optional        pam_systemd.so
session optional        pam_ecryptfs.so unwrap
# end of pam-auth-update config
```

---

```Shell
clear
```

#### # Configure AppArmor to work with non-standard home directories

```Shell
sudo dpkg-reconfigure apparmor
```

> **Note**
>
> When prompted for additional home directories, type **/home/corp.technologytoolbox.com/** and select **OK**.

##### References

**How do I make AppArmor work with a non-standard HOME directory?**\
From <[https://help.ubuntu.com/community/AppArmor](https://help.ubuntu.com/community/AppArmor)>

**How can I use snap when I don’t use /home/\$USER?**\
From <[https://forum.snapcraft.io/t/how-can-i-use-snap-when-i-dont-use-home-user/3352](https://forum.snapcraft.io/t/how-can-i-use-snap-when-i-dont-use-home-user/3352)>

**Permission denied on launch**\
From <[https://forum.snapcraft.io/t/permission-denied-on-launch/909](https://forum.snapcraft.io/t/permission-denied-on-launch/909)>

**cannot create user data directory: Bad file descriptor**\
From <[https://github.com/anbox/anbox/issues/43](https://github.com/anbox/anbox/issues/43)>

```Shell
clear
```

#### # Login as domain user

```Shell
su - jjameson-admin

Password:
Creating directory '/home/corp.technologytoolbox.com/jjameson-admin'.

exit
```

```Shell
clear
```

#### # Add domain user to "sudo" group

```Shell
sudo usermod -aG sudo jjameson-admin
```

```Shell
clear
```

## # Install Git

```Shell
sudo apt-get update
sudo apt-get upgrade
```

```Shell
clear
sudo apt-get install git
```

### Reference

**Installing _Git_ on _Linux_**\
From <[https://gist.github.com/derhuerst/1b15ff4652a867391f03#file-linux-md](https://gist.github.com/derhuerst/1b15ff4652a867391f03#file-linux-md)>

## Install Docker CE

### Reference

**Get Docker CE for Ubuntu**\
From <[https://docs.docker.com/install/linux/docker-ce/ubuntu/](https://docs.docker.com/install/linux/docker-ce/ubuntu/)>

```Shell
clear
```

### # Set up repository

#### # Update apt package index

```Shell
sudo apt-get update
```

```Shell
clear
```

#### # Install packages to allow apt to use repository over HTTPS

```Shell
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common \
    -y
```

```Shell
clear
```

#### # Add Docker's official GPG key

```Shell
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
```

```Shell
clear
```

#### # Verify key with fingerprint 9DC8 5822 9FC7 DD38 854A E2D8 8D81 803C 0EBF CD88

```Shell
sudo apt-key fingerprint 0EBFCD88

pub   rsa4096 2017-02-22 [SCEA]
      9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88
uid           [ unknown] Docker Release (CE deb) <docker@docker.com>
sub   rsa4096 2017-02-22 [S]
```

```Shell
clear
```

#### # Set up stable repository

```PowerShell
sudo add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
```

> **Note**
>
> The **lsb_release -cs** sub-command returns the name of your Ubuntu distribution, such as **bionic**.

```Shell
clear
```

### # Install Docker

#### # Update the apt package index

```Shell
sudo apt-get update
```

```Shell
clear
```

#### # Install the latest version of Docker CE and containerd

```Shell
sudo apt-get install docker-ce docker-ce-cli containerd.io -y
```

```Shell
clear
```

#### # Verify Docker is installed correctly by running hello-world image

```Shell
sudo docker run hello-world
```

## Install Docker Compose

### Reference

**Install Docker Compose**\
From <[https://docs.docker.com/compose/install/](https://docs.docker.com/compose/install/)>

```Shell
clear
```

### # Download current stable release of Docker Compose

```Shell
sudo curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
```

```Shell
clear
```

### # Apply executable permissions to the binary

```Shell
sudo chmod +x /usr/local/bin/docker-compose
```

## Install PowerShell Core

### Reference

**Installing PowerShell Core on Linux**\
From <[https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-6](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-6)>

```Shell
clear
```

### # Install via package repository

#### # Download Microsoft repository GPG keys

```PowerShell
cd /tmp

wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb
```

```PowerShell
clear
```

#### # Register Microsoft repository GPG keys

```Shell
sudo dpkg -i packages-microsoft-prod.deb
```

```Shell
clear
```

#### # Update list of products

```Shell
sudo apt-get update
```

```Shell
clear
```

#### # Install PowerShell

```Shell
sudo apt-get install powershell -y
```

```Shell
clear
```

#### # Start PowerShell

```Shell
pwsh
```

```Shell
clear
```

#### # Update help

```PowerShell
Update-Help
```

```PowerShell
clear
```

#### # Exit PowerShell

```PowerShell
exit
```

---

**FOOBAR18 - Run as local administrator**

```PowerShell
cls
```

## # Remove VM checkpoint

```PowerShell
$vmName = "TT-DOCKER01"
```

##### # Shutdown VM

```PowerShell
Stop-SCVirtualMachine -VM $vmName
```

##### # Remove VM snapshot

```PowerShell
Get-SCVMCheckpoint -VM $vmName |
    Remove-SCVMCheckpoint
```

##### # Start VM

```PowerShell
Start-SCVirtualMachine -VM $vmName
```

---

## Configure backups

### Add virtual machine to Hyper-V protection group in DPM

**TODO:**

## Install MailHog

```Shell
sudo docker run --restart unless-stopped --name mailhog -p 25:1025 -p 80:8025 -d mailhog/mailhog
```

### Reference

**Setting up SMTP mail server using mailhog docker image**\
From <[https://www.linkedin.com/pulse/setting-up-smtp-mail-server-using-mailhog-docker-image-chopparapu](https://www.linkedin.com/pulse/setting-up-smtp-mail-server-using-mailhog-docker-image-chopparapu)>

## Install Bitwarden

### Hosting Installation Id & Key

Installation Id: 6417d075-9d6f-49e4-bea1-{redacted}\
Installation Key: MZFRpz4Lo25o\*\*\*\*\*\*\*\*

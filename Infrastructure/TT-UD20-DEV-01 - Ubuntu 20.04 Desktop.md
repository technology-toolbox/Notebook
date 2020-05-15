# TT-UD20-DEV-01 - Ubuntu 20.04 Desktop

Friday, May 15, 2020
7:55 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure infrastructure

---

**STORM** - Run as administrator

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmName = "TT-UD20-DEV-01"
$vmPath = "D:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 25GB `
    -MemoryStartupBytes 4GB `
    -SwitchName "LAN"

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
    -Path "\\TT-FS01\Products\Ubuntu\ubuntu-20.04-desktop-amd64.iso"

Start-VM -Name $vmName
```

---

### Install Linux desktop

> **Note**
>
> When prompted, restart the computer to complete the installation.

1. On the **Connect Your Online Accounts** page, click **Skip**.
2. On the **Livepatch** page, click **Next**.
3. On the **Help improve Ubuntu** page:
   1. Click **No, don't send system info**.
   2. Click **Next**.
4. On the **Privacy** page, ensure **Location Services** is disabled and click **Next**.
5. On the **You're ready to go!** page, click **Done**.

> **Note**
>
> Skip setup of Livepatch for security updates due to current license limitations (free for up to 3 computers).

### Install updates using Software Updater

> **Note**
>
> When prompted, restart the computer to complete the update process.

### # Update APT packages

```Shell
sudo apt-get update
sudo apt-get -y upgrade
```

```Shell
clear
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

### # Install network tools (e.g. ifconfig)

```Shell
sudo apt-get -y install net-tools
```

### # Check IP address

```Shell
ifconfig | grep inet
```

### # Enable SSH

```Shell
sudo apt-get -y install openssh-server
```

---

**STORM** - Run as administrator

```PowerShell
cls
```

### # Checkpoint VM

```PowerShell
$checkpointName = "Baseline Ubuntu Desktop 20.04"
$vmName = "TT-UD20-DEV-01"

Stop-VM -Name $vmName

Checkpoint-VM `
    -Name $vmName `
    -SnapshotName $checkpointName

Start-VM -Name $vmName
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

```Shell
nmcli device show eth0 | grep IP4.DNS
```

```Text
IP4.DNS[1]:                             10.1.30.2
IP4.DNS[2]:                             10.1.30.3
```

```Shell
clear
```

#### # Validate Active Directory DNS records

##### # Validate LDAP SRV records

```Shell
dig -t SRV _ldap._tcp.corp.technologytoolbox.com
```

```Text
; <<>> DiG 9.16.1-Ubuntu <<>> -t SRV _ldap._tcp.corp.technologytoolbox.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 18207
;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;_ldap._tcp.corp.technologytoolbox.com. IN SRV

;; ANSWER SECTION:
_ldap._tcp.corp.technologytoolbox.com. 600 IN SRV 0 100 389 tt-dc11.corp.technologytoolbox.com.
_ldap._tcp.corp.technologytoolbox.com. 600 IN SRV 0 100 389 tt-dc10.corp.technologytoolbox.com.

;; Query time: 3 msec
;; SERVER: 127.0.0.53#53(127.0.0.53)
;; WHEN: Fri May 15 08:21:19 MDT 2020
;; MSG SIZE  rcvd: 174
```

```Shell
clear
```

##### # Validate domain controller SRV records

```Shell
dig @10.1.30.2 -t SRV _ldap._tcp.dc._msdcs.corp.technologytoolbox.com
```

```Text
; <<>> DiG 9.16.1-Ubuntu <<>> @10.1.30.2 -t SRV _ldap._tcp.dc._msdcs.corp.technologytoolbox.com
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 45518
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 3, AUTHORITY: 0, ADDITIONAL: 4

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4000
;; QUESTION SECTION:
;_ldap._tcp.dc._msdcs.corp.technologytoolbox.com. IN SRV

;; ANSWER SECTION:
_ldap._tcp.dc._msdcs.corp.technologytoolbox.com. 600 IN SRV 0 100 389 TT-DC10.corp.technologytoolbox.com.
_ldap._tcp.dc._msdcs.corp.technologytoolbox.com. 600 IN SRV 0 100 389 tt-dc10.corp.technologytoolbox.com.
_ldap._tcp.dc._msdcs.corp.technologytoolbox.com. 600 IN SRV 0 100 389 tt-dc11.corp.technologytoolbox.com.

;; ADDITIONAL SECTION:
TT-DC10.corp.technologytoolbox.com. 3600 IN A   10.1.30.2
tt-dc10.corp.technologytoolbox.com. 3600 IN A   10.1.30.2
tt-dc11.corp.technologytoolbox.com. 3600 IN A   10.1.30.3

;; Query time: 0 msec
;; SERVER: 10.1.30.2#53(10.1.30.2)
;; WHEN: Fri May 15 08:22:03 MDT 2020
;; MSG SIZE  rcvd: 286
```

```Shell
clear
```

#### # Install prerequisites for using realmd

```Shell
sudo apt-get -y install realmd
```

#### Configure realmd

> **Note**
>
> Note the default home directory path (specified by the **fallback_homedir** setting in **/etc/sssd/sssd.conf**) is **/home/%u@%d** (e.g. **/home/jjameson@corp.technologytoolbox.com**). To create home directories under a "domain" directory, the **default-home** setting is specified in **/etc/realmd.conf** prior to joining the Active Directory domain.

```Shell
clear
sudoedit /etc/realmd.conf
```

---

File - **/etc/realmd.conf**

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

File - **/etc/hostname**

```Text
TT-UD20-DEV-01.corp.technologytoolbox.com
```

---

```Shell
sudo reboot
```

> **Note**
>
> Changing the hostname to the fully qualified domain name avoids an error when creating the service principal name for the computer account when joining the Active Directory domain. For example:
>
> ```Text
>  * Modifying computer account: userPrincipalName
>  ! Couldn't set service principals on computer account CN=TT-UD20-DEV-01,CN=Computers,DC=corp,DC=technologytoolbox,DC=com: 00002083: AtrErr: DSID-03151904, #1:
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
realm discover -v
```

```Text
 * Resolving: _ldap._tcp.corp.technologytoolbox.com
 * Performing LDAP DSE lookup on: 10.1.30.2
 * Performing LDAP DSE lookup on: 10.1.30.3
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
sudo realm join -v -U jjameson-admin corp.technologytoolbox.com --os-name="Linux (Ubuntu Desktop)" --os-version=20.04
```

```Text
[sudo] password for foo:
 * Resolving: _ldap._tcp.corp.technologytoolbox.com
 * Performing LDAP DSE lookup on: 10.1.30.3
 * Performing LDAP DSE lookup on: 10.1.30.2
 * Successfully discovered: corp.technologytoolbox.com
Password for jjameson-admin:
 * Unconditionally checking packages
 * Resolving required packages
 * Installing necessary packages: sssd-tools adcli sssd libnss-sss libpam-sss
 * LANG=C /usr/sbin/adcli join --verbose --domain corp.technologytoolbox.com --domain-realm CORP.TECHNOLOGYTOOLBOX.COM --domain-controller 10.1.30.3 --os-name Linux (Ubuntu Desktop) --os-version 20.04 --login-type user --login-user jjameson-admin --stdin-password
 * Using domain name: corp.technologytoolbox.com
 * Calculated computer account name from fqdn: TT-UD20-DEV-01
 * Using domain realm: corp.technologytoolbox.com
 * Sending NetLogon ping to domain controller: 10.1.30.3
 * Received NetLogon info from: TT-DC11.corp.technologytoolbox.com
 * Wrote out krb5.conf snippet to /var/cache/realmd/adcli-krb5-FgewvB/krb5.d/adcli-krb5-conf-lDuCpy
 * Authenticated as user: jjameson-admin@CORP.TECHNOLOGYTOOLBOX.COM
 * Looked up short domain name: TECHTOOLBOX
 * Looked up domain SID: S-1-5-21-3914637029-2275272621-3670275343
 * Using fully qualified name: TT-UD20-DEV-01.corp.technologytoolbox.com
 * Using domain name: corp.technologytoolbox.com
 * Using computer account name: TT-UD20-DEV-01
 * Using domain realm: corp.technologytoolbox.com
 * Calculated computer account name from fqdn: TT-UD20-DEV-01
 * Generated 120 character computer password
 * Using keytab: FILE:/etc/krb5.keytab
 * Computer account for TT-UD20-DEV-01$ does not exist
 * Found well known computer container at: CN=Computers,DC=corp,DC=technologytoolbox,DC=com
 * Calculated computer account: CN=TT-UD20-DEV-01,CN=Computers,DC=corp,DC=technologytoolbox,DC=com
 * Encryption type [3] not permitted.
 * Encryption type [1] not permitted.
 * Created computer account: CN=TT-UD20-DEV-01,CN=Computers,DC=corp,DC=technologytoolbox,DC=com
 * Sending NetLogon ping to domain controller: 10.1.30.3
 * Received NetLogon info from: TT-DC11.corp.technologytoolbox.com
 * Set computer password
 * Retrieved kvno '2' for computer account in directory: CN=TT-UD20-DEV-01,CN=Computers,DC=corp,DC=technologytoolbox,DC=com
 * Checking RestrictedKrbHost/TT-UD20-DEV-01.corp.technologytoolbox.com
 *    Added RestrictedKrbHost/TT-UD20-DEV-01.corp.technologytoolbox.com
 * Checking RestrictedKrbHost/TT-UD20-DEV-01
 *    Added RestrictedKrbHost/TT-UD20-DEV-01
 * Checking host/TT-UD20-DEV-01.corp.technologytoolbox.com
 *    Added host/TT-UD20-DEV-01.corp.technologytoolbox.com
 * Checking host/TT-UD20-DEV-01
 *    Added host/TT-UD20-DEV-01
 ! Couldn't authenticate with keytab while discovering which salt to use: TT-UD20-DEV-01$@CORP.TECHNOLOGYTOOLBOX.COM: Client 'TT-UD20-DEV-01$@CORP.TECHNOLOGYTOOLBOX.COM' not found in Kerberos database
 * Added the entries to the keytab: TT-UD20-DEV-01$@CORP.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb5.keytab
 * Added the entries to the keytab: host/TT-UD20-DEV-01@CORP.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb5.keytab
 * Added the entries to the keytab: host/TT-UD20-DEV-01.corp.technologytoolbox.com@CORP.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb5.keytab
 * Added the entries to the keytab: RestrictedKrbHost/TT-UD20-DEV-01@CORP.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb5.keytab
 * Added the entries to the keytab: RestrictedKrbHost/TT-UD20-DEV-01.corp.technologytoolbox.com@CORP.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb5.keytab
 * /usr/sbin/update-rc.d sssd enable
 * /usr/sbin/service sssd restart
 * Successfully enrolled machine in realm
```

```Shell
sudo reboot
```

```Shell
clear
```

#### # Test the system configuration after joining the domain

```Shell
id jjameson
```

```Text
uid=453801112(jjameson) gid=453800513(domain users) groups=453800513(domain users),453804117(sso administrators (dev)),453805111(team foundation server admins (dev)),453805109(sharepoint admins (dev)),453801113(all developers),453807606(folder redirection users),453806158(jameson family),453804109(development admins),453806161(extranet approvers (dev)),453806107(fabrikam account team),453806174(fast search admins (dev)),453807608(roaming user profiles users and computers),453806162(extranet authors (dev)),453805108(sql server admins (dev))
```

```Shell
clear
```

#### # Configure home directories

```Shell
sudoedit /etc/pam.d/common-session
```

---

File - **/etc/pam.d/common-session**

```Text
...
# and here are more per-package modules (the "Additional" block)
session required        pam_unix.so
session required        pam_mkhomedir.so umask=0077
session optional                        pam_sss.so
session optional        pam_systemd.so
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

When prompted for additional home directories, type **/home/corp.technologytoolbox.com/** and select **OK**.

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
su - jjameson
```

```Text
Broadcast message from systemd-journald@TT-UD20-DEV-01.corp.technologytoolbox.com (Fri 2020-05-15 08:33:58 MDT):

sssd[be[622]: Group Policy Container with DN [cn={09931EAD-8D08-4F58-BD7F-F92B16403B8E},cn=policies,cn=system,DC=corp,DC=technologytoolbox,DC=com] is unreadable or has unreadable or missing attributes. In order to fix this make sure that this AD object has following attributes readable: nTSecurityDescriptor, cn, gPCFileSysPath, gPCMachineExtensionNames, gPCFunctionalityVersion, flags. Alternatively if you do not have access to the server or can not change permissions on this object, you can use option ad_gpo_ignore_unreadable = True which will skip this GPO. See ad_gpo_ignore_unreadable in 'man sssd-ad' for details.

su: System error
```

```Shell
clear
```

#### # Ignore unreadable group policies

```Shell
sudoedit /etc/sssd/sssd.conf
```

---

File - **/etc/sssd/sssd.conf**

```Text
...
[domain/corp.technologytoolbox.com]
...
ad_gpo_ignore_unreadable = True
```

---

```Shell
sudo reboot
```

```Shell
clear
```

#### # Login as domain user

```Shell
su - jjameson
```

```Text
Password:
Creating directory '/home/corp.technologytoolbox.com/jjameson'.
```

```Shell
exit
```

```Shell
clear
```

#### # Add domain user to "sudo" group

```Shell
sudo usermod -aG sudo jjameson
```

---

**STORM** - Run as administrator

```PowerShell
cls
```

## # Update VM baseline

```PowerShell
$vmName = "TT-UD20-DEV-01"

C:\NotBackedUp\Public\Toolbox\PowerShell\Update-VMBaseline `
    -Name $vmName `
    -Confirm:$false

Start-VM -Name $vmName
```

---

```Shell
clear
```

## # Install Google Chrome

### # Download Google Chrome installation file

```Shell
pushd /tmp

wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
```

### # Install Google Chrome

```Shell
sudo dpkg -i google-chrome-stable_current_amd64.deb
```

```Shell
clear
```

### # Remove Google Chrome installation file

```Shell
rm google-chrome-stable_current_amd64.deb

popd
```

### Reference

**How to Install Google Chrome Web Browser on Ubuntu 18.04**\
From <[https://linuxize.com/post/how-to-install-google-chrome-web-browser-on-ubuntu-18-04/](https://linuxize.com/post/how-to-install-google-chrome-web-browser-on-ubuntu-18-04/)>

```Shell
clear
```

## # Install htop

```Shell
sudo apt-get -y install htop
```

```Shell
clear
```

## # Install and configure Powerline

```Shell
sudo apt-get -y install powerline
```

```Shell
clear
```

## # Install Git

```Shell
sudo apt-get update
sudo apt-get -y install git
```

### Reference

**Installing _Git_ on _Linux_**\
From <[https://gist.github.com/derhuerst/1b15ff4652a867391f03#file-linux-md](https://gist.github.com/derhuerst/1b15ff4652a867391f03#file-linux-md)>

```Shell
clear
```

## # Install GitKraken

### # Download GitKraken installation file

```Shell
pushd /tmp

wget https://release.gitkraken.com/linux/gitkraken-amd64.deb
```

### # Install GitKraken

```Shell
sudo dpkg -i gitkraken-amd64.deb
```

```Text
...
Unpacking gitkraken (6.6.0) ...
dpkg: dependency problems prevent configuration of gitkraken:
 gitkraken depends on gconf2; however:
  Package gconf2 is not installed.
 gitkraken depends on gconf-service; however:
  Package gconf-service is not installed.
 gitkraken depends on python; however:
  Package python is not installed.

dpkg: error processing package gitkraken (--install):
 dependency problems - leaving unconfigured
Processing triggers for gnome-menus (3.36.0-1ubuntu1) ...
Processing triggers for desktop-file-utils (0.24-1ubuntu2) ...
Processing triggers for mime-support (3.64ubuntu1) ...
Errors were encountered while processing:
 gitkraken
```

```Shell
clear
```

### # Remove GitKraken installation file

```Shell
rm gitkraken-amd64.deb

popd
```

### # Install GitKraken dependencies

```Shell
sudo apt-get -y --fix-broken install
```

### Reference

**How to Install GitKraken**\
From <[https://support.gitkraken.com/how-to-install/](https://support.gitkraken.com/how-to-install/)>

```Shell
clear
```

## # Install LTS version of Node.js

### # Add Node.js PPA

```Shell
sudo apt-get -y install curl
```

```Shell
clear
```

```Shell
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
```

```Shell
clear
```

### # Install Node.js

```Shell
sudo apt-get -y install nodejs
```

```Shell
clear
```

### # Verify Node.js and NPM versions

```Shell
node -v

npm -v
```

### Reference

**How to Install Latest Node.js and NPM on Ubuntu with PPA**\
From <[https://tecadmin.net/install-latest-nodejs-npm-on-ubuntu/](https://tecadmin.net/install-latest-nodejs-npm-on-ubuntu/)>

```Shell
clear
```

## # Install Visual Studio Code

```Shell
sudo snap install --classic code
```

```Shell
clear
```

## # Install .NET Core SDK

### # Register Microsoft key and feed

```Shell
pushd /tmp

wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb

sudo dpkg -i packages-microsoft-prod.deb
```

```Shell
clear
```

### # Remove Microsoft key and feed installation file

```Shell
rm packages-microsoft-prod.deb

popd
```

```Shell
clear
```

### # Install .NET SDK

```Shell
sudo apt-get update

sudo apt-get -y install apt-transport-https

sudo apt-get update

sudo apt-get -y install dotnet-sdk-3.1
```

### Reference

**Ubuntu 20.04 Package Manager - Install .NET Core**\
From <[https://docs.microsoft.com/en-us/dotnet/core/install/linux-package-manager-ubuntu-2004](https://docs.microsoft.com/en-us/dotnet/core/install/linux-package-manager-ubuntu-2004)>

```Shell
clear
```

## # Install Postman

### # Install Postman using Snap (currently version 7.24.0)

```Shell
sudo snap install postman
```

```Shell
clear
```

## # Install SourceGear DiffMerge

### # Download updated version of SourceGear DiffMerge

```Shell
pushd /tmp

wget -c https://drive.google.com/uc?id=1sj_6QHV15tIzQBIGJaopMsogyds0pxD9 -O diffmerge_4.2.1.81 7.beta_amd64.deb
```

```Shell
clear
```

### # Install libcurl (dependency)

```Shell
sudo apt-get -y install libcurl4-openssl-dev
```

#### Reference

diffmerge: error while loading shared libraries: libpng12.so.0: cannot open shared object file: No such file or directory

From <[https://support.sourcegear.com/viewtopic.php?f=33&t=22981](https://support.sourcegear.com/viewtopic.php?f=33&t=22981)>

```Shell
clear
```

### # Install SourceGear DiffMerge

```Shell
sudo dpkg -i diffmerge_4.2.1.817.beta_amd64.deb
```

```Shell
clear
```

### # Remove SourceGear DiffMerge installation file

```Shell
rm diffmerge_4.2.1.817.beta_amd64.deb

popd
```

```Shell
clear
```

## # Install Wireshark

```Shell
sudo apt-get update
sudo apt-get -y install wireshark
```

> **Note**
>
> When prompted whether to allow non-superusers to capture packets, select **Yes**.

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
sudo apt-get -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
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
```

```Text
pub   rsa4096 2017-02-22 [SCEA]
      9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88
uid           [ unknown] Docker Release (CE deb) <docker@docker.com>
sub   rsa4096 2017-02-22 [S]
```

```Shell
clear
```

#### # Set up stable repository

```Shell
sudo add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
```

> **Note**
>
> The **lsb_release -cs** sub-command returns the name of your Ubuntu distribution, such as **focal**.

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
sudo apt-get -y install docker-ce docker-ce-cli containerd.io
```

```Text
Package docker-ce is not available, but is referred to by another package.
This may mean that the package is missing, has been obsoleted, or
is only available from another source

E: Package 'docker-ce' has no installation candidate
E: Unable to locate package docker-ce-cli
```

> _As of today, the release file for Ubuntu 20.04 LTS focal is not available._
>
> **How to install docker community on Ubuntu 20.04 LTS?**\
> From <[https://askubuntu.com/a/1230190](https://askubuntu.com/a/1230190)>

```Shell
clear
```

```Shell
sudo add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    bionic \
    stable"
```

```Shell
clear
```

```Shell
sudo apt-get -y install docker-ce docker-ce-cli containerd.io
```

```Shell
clear
```

#### # Verify Docker is installed correctly by running hello-world image

```Shell
sudo docker run hello-world
```

```Shell
clear
```

### # Add users to "docker" group

```Shell
sudo usermod -aG docker foo
sudo usermod -aG docker jjameson
```

```Shell
clear
```

### # Verify docker command works for non-root user

```Shell
sudo reboot
```

```Shell
clear
docker run hello-world
```

#### Reference

**Manage Docker as a non-root user**\
From <[https://docs.docker.com/install/linux/linux-postinstall/](https://docs.docker.com/install/linux/linux-postinstall/)>

## Install Docker Compose

### Reference

**Install Docker Compose**\
From <[https://docs.docker.com/compose/install/](https://docs.docker.com/compose/install/)>

```Shell
clear
```

### # Download current stable release of Docker Compose

```Shell
sudo curl -L "https://github.com/docker/compose/releases/download/1.25.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
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

```Shell
pushd /tmp

wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
```

```Shell
clear
```

#### # Register Microsoft repository GPG keys

```Shell
sudo dpkg -i packages-microsoft-prod.deb
```

```Shell
clear
```

### # Remove Microsoft repository GPG keys installation file

```Shell
rm packages-microsoft-prod.deb

popd
```

```Shell
clear
```

#### # Enable the "universe" repositories

```Shell
sudo add-apt-repository universe
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
sudo apt-get -y install powershell
```

```Text
E: Unable to locate package powershell
```

```Shell
clear
sudo snap install powershell --classic
```

```Shell
clear
```

#### # Start PowerShell

```Shell
pwsh
```

```PowerShell
clear
```

#### # Update help

```PowerShell
Update-Help
```

```Text
Update-Help: Failed to update Help for the module(s) 'PSDesiredStateConfiguration, ThreadJob' with UI culture(s) {en-US} : One or more errors occurred. (Response status code does not indicate success: 404 (The specified blob does not exist.).).
English-US help content is available and can be installed using: Update-Help -UICulture en-US.
```

```PowerShell
clear
```

#### # Exit PowerShell

```PowerShell
exit
```

```Shell
clear
```

## # Install mkcert

### # Install prerequisites for mkcert

#### # Install "certutil"

```Shell
sudo apt-get -y install libnss3-tools
```

```Shell
clear
```

#### # Install Linuxbrew

```Shell
sudo apt-get -y install linuxbrew-wrapper
```

```Text
E: Unable to locate package linuxbrew-wrapper
```

#### TODO: Add Linuxbrew to Bash profile

```Shell
echo 'export PATH="$PATH:/home/linuxbrew/.linuxbrew/bin"' >> ~/.bash_profile
echo 'export MANPATH="$MANPATH:/home/linuxbrew/.linuxbrew/share/man"' >> ~/.bash_profile
echo 'export INFOPATH="$INFOPATH/home/linuxbrew/.linuxbrew/share/info"' >> ~/.bash_profile
```

```Shell
clear
```

### # TODO: Configure brew

```Shell
brew
```

```Shell
clear
```

### # TODO: Install mkcert

```Shell
/home/linuxbrew/.linuxbrew/bin/brew install mkcert
```

```Shell
clear
```

### # TODO: Install mkcert local CA

```Shell
/home/linuxbrew/.linuxbrew/bin/mkcert -install
```

### Reference

**mkcert**\
From <[https://github.com/FiloSottile/mkcert](https://github.com/FiloSottile/mkcert)>

```Shell
clear
```

## # Install Go

```Shell
sudo snap install go --classic
```

```Shell
clear
```

## # Install dependencies for building Bootstrap

### # Install Ruby using APT

#### # Update package index

```Shell
sudo apt-get update
```

#### # Install Ruby

```Shell
sudo apt-get -y install ruby-full
```

```Shell
clear
```

#### # Verify Ruby version

```Shell
ruby --version
```

```Shell
clear
```

### # Install Ruby dependency for building Bootstrap

```Shell
sudo gem install bundler
```

```Shell
clear
```

### # Install Hugo

```Shell
sudo snap install hugo --channel=extended
```

### References

**Build tools**\
From <[https://getbootstrap.com/docs/4.3/getting-started/build-tools/](https://getbootstrap.com/docs/4.3/getting-started/build-tools/)>

**How To Install Ruby on Ubuntu 18.04**\
From <[https://linuxize.com/post/how-to-install-ruby-on-ubuntu-18-04/](https://linuxize.com/post/how-to-install-ruby-on-ubuntu-18-04/)>

**Bundler**\
From <[https://bundler.io/](https://bundler.io/)>

**Install Hugo**\
From <[https://gohugo.io/getting-started/installing](https://gohugo.io/getting-started/installing)>

```Shell
clear
```

## # Install Subversion client

```Shell
sudo apt-get update
sudo apt-get -y install subversion
```

```Shell
clear
sudo apt-get -y install libapache2-svn
```

```Text
Reading package lists... Done
Building dependency tree
Reading state information... Done
E: Unable to locate package libapache2-svn
```

### Reference

**Apache Subversion Binary Packages**\
From <[https://subversion.apache.org/packages.html](https://subversion.apache.org/packages.html)>

```Shell
clear
```

## # Install SmartSVN

### # Download SmartSVN installation file

```Shell
pushd /tmp

wget -c https://www.smartsvn.com/downloads/smartsvn/smartsvn-linux-11_0_0.tar.gz
```

```Shell
clear
```

### # Install SmartSVN

```Shell
sudo tar xvzf smartsvn-linux-11_0_0.tar.gz -C /usr/share
```

```Shell
clear
```

### # Remove SmartSVN installation file

```Shell
rm smartsvn-linux-11_0_0.tar.gz

popd
```

### # Add menu item for SmartSVN

```Shell
/usr/share/smartsvn/bin/add-menuitem.sh
```

```Shell
clear
```

## # Install Java

### # Install OpenJDK 11

```Shell
sudo apt-get update
```

```Shell
clear
sudo apt-get -y install default-jdk
```

#### Issue - Jackcess Encrypt unit tests fail with OpenJDK 11

**How to resolve java.lang.NoClassDefFoundError: javax/xml/bind/JAXBException in Java 9**\
From <[https://stackoverflow.com/questions/43574426/how-to-resolve-java-lang-noclassdeffounderror-javax-xml-bind-jaxbexception-in-j](https://stackoverflow.com/questions/43574426/how-to-resolve-java-lang-noclassdeffounderror-javax-xml-bind-jaxbexception-in-j)>

#### Resolution - Use OpenJDK 8 instead

### Reference

**How to install Java on Ubuntu 18.04**\
From <[https://linuxize.com/post/install-java-on-ubuntu-18-04/](https://linuxize.com/post/install-java-on-ubuntu-18-04/)>

```Shell
clear
```

### # Install OpenJDK 8

```Shell
sudo apt-get update
sudo apt-get -y install openjdk-8-jdk
```

### Reference

**Installing Specific Versions of OpenJDK**\
From <[https://www.digitalocean.com/community/tutorials/how-to-install-java-with-apt-on-ubuntu-18-04](https://www.digitalocean.com/community/tutorials/how-to-install-java-with-apt-on-ubuntu-18-04)>

```Shell
clear
```

## # Install Maven

```Shell
sudo apt-get update
sudo apt-get -y install maven
```

### Reference

**How to install Apache Maven on Ubuntu 18.04**\
From <[https://linuxize.com/post/how-to-install-apache-maven-on-ubuntu-18-04/](https://linuxize.com/post/how-to-install-apache-maven-on-ubuntu-18-04/)>

```Shell
clear
```

## # Install DBeaver

### # Download DBeaver installation file

```Shell
pushd /tmp

wget https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb
```

### # Install DBeaver

```Shell
sudo dpkg -i dbeaver-ce_latest_amd64.deb
```

```Shell
clear
```

### # Remove DBeaver installation file

```Shell
rm dbeaver-ce_latest_amd64.deb

popd
```

```Shell
clear
```

## # Configure display resolution

```Shell
sudoedit /etc/default/grub
```

---

File - **/etc/realmd.conf**

```Text
...
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash video=hyperv_fb:1920x1080"
...
```

---

```Shell
sudo update-grub

sudo reboot
```

### Reference

**Changing Ubuntu Screen Resolution in a Hyper-V VM**\
From <[https://blogs.msdn.microsoft.com/virtual_pc_guy/2014/09/19/changing-ubuntu-screen-resolution-in-a-hyper-v-vm/](https://blogs.msdn.microsoft.com/virtual_pc_guy/2014/09/19/changing-ubuntu-screen-resolution-in-a-hyper-v-vm/)>

## Configure user profile - jjameson

### Background

```Shell
clear
```

### # Configure Git

```Shell
git config --global user.name "Jeremy Jameson"
git config --global user.email jjameson@technologytoolbox.com
```

### Favorites

- **Chrome**
- **Firefox**
- **Terminal**
- **Visual Studio Code**
- **GitKraken**
- **Files**
- **Thunderbird Mail**
- **Ubuntu Software**
- **Help**

### Configure Dock

#### Move Dock to bottom

#### Move "Show Applications" to left

```Shell
gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-at-top true
```

##### Reference

**How do I move the "Show Applications" icon in Ubuntu Dock?**\
From <[https://askubuntu.com/questions/966704/how-do-i-move-the-show-applications-icon-in-ubuntu-dock](https://askubuntu.com/questions/966704/how-do-i-move-the-show-applications-icon-in-ubuntu-dock)>

### Add Terminal color schemes using Gogh

Gogh - Color Scheme for Gnome Terminal and Pantheon Terminal\
\
[https://mayccoll.github.io/Gogh/](https://mayccoll.github.io/Gogh/)\

| Name                    | ID  |
| ----------------------- | --- |
| Afterglow               |     |
| Arthur                  |     |
| Broadcast               |     |
| Darkside                |     |
| Desert                  |     |
| Hybrid                  |     |
| Idle Toes               |     |
| Japanesque              |     |
| Later This Evening      |     |
| N0tch2k                 | 105 |
| Neutron                 |     |
| Pnevma                  |     |
| Spacegray Eighties Dull |     |
| Teerb                   |     |
| Wombat                  |     |

```Shell
bash -c "$(wget -qO- https://git.io/vQgMr)"
```

\
105

### Configure Terminal preferences

- Color scheme - N0tch2k
- Size - 132x43

```Shell
clear
```

### # Configure Powerline for Bash shell

```Shell
nano ~/.bashrc
```

---

File - **~/.bashrc**

```Text
...

# Enable Powerline
powerline-daemon -q
POWERLINE_BASH_CONTINUATION=1
POWERLINE_BASH_SELECT=1
. /usr/share/powerline/bindings/bash/powerline.sh
```

---

```Shell
clear
```

### # Enable Git branch support in Powerline

#### # Create powerline configuration file

```Shell
mkdir -p ~/.config/powerline
```

#### # Set theme

```Shell
cat <<-'EOF' > ~/.config/powerline/config.json
{
    "ext": {
        "shell": {
            "theme": "default_leftonly"
        }
    }
}
EOF
```

#### # Load new configuration

```Shell
powerline-daemon --replace
```

#### Reference

**How to install powerline for Bash on Fedora with git branch support**\
From <[https://eshlox.net/2017/08/10/how-to-install-powerline-for-bash-on-fedora-with-git-branch-support/](https://eshlox.net/2017/08/10/how-to-install-powerline-for-bash-on-fedora-with-git-branch-support/)>

### Install Visual Studio Code extensions

#### Install extension: Azure Resource Manager Tools

```Text
ext install msazurermtools.azurerm-vscode-tools
```

#### Install extension: Beautify

```Text
ext install hookyqr.beautify
```

#### Install extension: C&#35;

```Text
ext install ms-vscode.csharp
```

#### Install extension: Debugger for Chrome

```Text
ext install msjsdiag.debugger-for-chrome
```

#### Install extension: ESLint

```Text
ext install dbaeumer.vscode-eslint
```

#### Install extension: GitLens - Git supercharged

```Text
ext install eamodio.gitlens
```

### Install extension: Java Extension Pack

```Text
ext install vscjava.vscode-java-pack
```

#### Install extension: markdownlint

```Text
ext install davidanson.vscode-markdownlint
```

#### Install extension: PowerShell

```Text
ext install ms-vscode.powershell
```

#### Install extension: Prettier - Code formatter

```Text
ext install esbenp.prettier-vscode
```

#### Install extension: TSLint

```Text
ext install ms-vscode.vscode-typescript-tslint-plugin
```

#### Install extension: vscode-icons

```Text
ext install vscode-icons-team.vscode-icons
```

### Configure Powerline font in Visual Studio Code

#### User settings

1. Open the Command Palette (press **Ctrl+Shift+P**).
2. Type **Preferences: Open User Settings**.
3. Click **Open settings (JSON)**.

```JSON
{
    "editor.suggestSelection": "first",
    "java.semanticHighlighting.enabled": true,
    "terminal.integrated.fontFamily": "monospace, PowerlineSymbols",
    "vsintellicode.modify.editor.suggestSelection": "automaticallyOverrodeDefaultValue",
    "workbench.iconTheme": "vscode-icons"
}
```

#### Reference

**Powerline broken symbols in VSCode integrated terminal**\
From <[https://github.com/oh-my-fish/theme-bobthefish/issues/125](https://github.com/oh-my-fish/theme-bobthefish/issues/125)>

### Configure Visual Studio Code settings

1. Open the **Command Palette** (press **Ctrl+Shift+P**)
2. Select **Preferences: Open Settings (JSON)**

---

File - **settings.json**

```JSON
{
    "editor.formatOnSave": true,
    "editor.renderWhitespace": "boundary",
    "editor.rulers": [80],
    "files.trimTrailingWhitespace": true,
    "git.autofetch": true,
    "html.format.wrapLineLength": 80,
    "java.semanticHighlighting.enabled": true,
    "prettier.disableLanguages": ["html", "vue"],
    "terminal.integrated.fontFamily": "monospace, PowerlineSymbols",
    "vsintellicode.modify.editor.suggestSelection": "automaticallyOverrodeDefaultValue",
    "workbench.iconTheme": "vscode-icons"
}
```

---

```Shell
clear
```

## # Clone repository from Azure DevOps

```Shell
mkdir ~/techtoolbox

cd ~/techtoolbox

git clone https://techtoolbox@dev.azure.com/techtoolbox/Training-Docker/_git/Training-Docker

Personal access token: dkwy6iplg6a75vnyxgvafmfuqyzl3wsmoimhzxfkca{redacted}
```

```Shell
clear
```

## # Configure Git credential store

```Shell
cd ~/techtoolbox/Training-Docker
git config credential.helper 'store'

git pull

cat ~/.git-credentials
```

---

**STORM** - Run as administrator

```PowerShell
cls
```

## # Update VM baseline

```PowerShell
$vmName = "TT-UD20-DEV-01"

C:\NotBackedUp\Public\Toolbox\PowerShell\Update-VMBaseline `
    -Name $vmName `
    -Confirm:$false

$newSnapshotName = ("Baseline development environment")

Get-VMSnapshot -VMName $vmName |
    Rename-VMSnapshot -NewName $newSnapshotName

Start-VM -Name $vmName
```

---

**TODO:**

```Shell
clear
```

## # Install and run cAdvisor

```Shell
sudo docker run \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  --publish=8080:8080 \
  --detach=true \
  --name=cadvisor \
  google/cadvisor:latest
```

### Reference

**cAdvisor - Analyzes resource usage and performance characteristics of running containers**\
From <[https://github.com/google/cadvisor](https://github.com/google/cadvisor)>

```Shell
clear
```

## # Install Apache NetBeans

```Shell
sudo snap install netbeans --classic
```

### Reference

**How to Install Netbeans on Ubuntu 18.04**\
From <[https://linuxize.com/post/how-to-install-netbeans-on-ubuntu-18-04/](https://linuxize.com/post/how-to-install-netbeans-on-ubuntu-18-04/)>

```Shell
clear
```

## # Clone and build Jackcess

### # Clone Jackcess repository

```Shell
mkdir ~/SourceForge
mkdir ~/SourceForge/jackcess

cd ~/SourceForge/jackcess

svn checkout https://svn.code.sf.net/p/jackcess/code/jackcess/trunk
```

### # Build Jackcess

```Shell
cd ~/SourceForge/jackcess/trunk

mvn install
```

## # Clone and build Jackcess Encrypt

### # Clone Jackcess Encrypt repository

```Shell
mkdir ~/SourceForge/jackcessencrypt

cd ~/SourceForge/jackcessencrypt

svn checkout https://svn.code.sf.net/p/jackcessencrypt/code/trunk
```

### # Build Jackcess Encrypt

```Shell
cd ~/SourceForge/jackcessencrypt/trunk

mvn install
```

```Shell
clear
```

## # Update Visual Studio Code

```Shell
sudo snap refresh code --classic
```

---

**STORM** - Run as administrator

```PowerShell
cls
```

### # Checkpoint VM

```PowerShell
$checkpointName = "Jackcess development"
$vmName = "TT-UD20-DEV-01"

Stop-VM -Name $vmName

Checkpoint-VM `
    -Name $vmName `
    -SnapshotName $checkpointName

Start-VM -Name $vmName
```

---

## Miscellaneous

```Shell
clear
```

### # Allow a non-superuser to capture packets with Wireshark

```Shell
sudo usermod -a -G wireshark jjameson
```

```Shell
clear
```

### # Install package for troubleshooting Kerberos (e.g. kinit)

```Shell
sudo apt-get -y install krb5-user
```

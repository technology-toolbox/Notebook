﻿# TT-UD18-DEV-03 - Ubuntu 18.04 Desktop

Friday, January 25, 2019
1:24 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure infrastructure

---

**STORM - Run as local administrator**

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmName = "TT-UD18-DEV-03"
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
    -Path "\\TT-FS01\Products\Ubuntu\ubuntu-18.04.1-desktop-amd64.iso"

Start-VM -Name $vmName
```

---

### Install Linux desktop

> **Note**
>
> When prompted, restart the machine to complete the installation.

1. On the **What's new in Ubuntu** page, click **Next**.
2. On the **Livepatch** page, click **Next**.
3. On the **Help improve Ubuntu** page:
   1. Click **No, don't send system info**.
   2. Click **Next**.
4. On the **Ready to go** page, click **Done**.

> **Note**
>
> Skip setup of Livepatch for security updates due to current license limitations (free for up to 3 machines).

### # Install security updates

```Shell
sudo unattended-upgrade -v
```

> **Note**
>
> Wait for the updates to be installed and then restart the machine.

```Shell
sudo reboot
```

### # Install network tools (e.g. ifconfig)

```Shell
sudo apt install net-tools
```

### # Check IP address

```Shell
ifconfig | grep inet
```

### # Enable SSH

```Shell
sudo apt install openssh-server
```

---

**STORM - Run as local administrator**

```PowerShell
cls
```

### # Checkpoint VM

```PowerShell
$checkpointName = "Baseline Ubuntu Desktop 18.04"
$vmName = "TT-UD18-DEV-03"

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

; <<>> DiG 9.11.3-1ubuntu1.3-Ubuntu <<>> -t SRV _ldap._tcp.corp.technologytoolbox.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 60143
;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;_ldap._tcp.corp.technologytoolbox.com. IN SRV

;; ANSWER SECTION:
_ldap._tcp.corp.technologytoolbox.com. 600 IN SRV 0 100 389 TT-DC09.corp.technologytoolbox.com.
_ldap._tcp.corp.technologytoolbox.com. 600 IN SRV 0 100 389 TT-DC08.corp.technologytoolbox.com.

;; Query time: 1 msec
;; SERVER: 127.0.0.53#53(127.0.0.53)
;; WHEN: Fri Jan 25 14:09:53 MST 2019
;; MSG SIZE  rcvd: 122
```

```Shell
clear
```

##### # Validate domain controller SRV records

```Shell
dig @10.1.30.2 -t SRV _ldap._tcp.dc._msdcs.corp.technologytoolbox.com

; <<>> DiG 9.11.3-1ubuntu1.3-Ubuntu <<>> @10.1.30.2 -t SRV _ldap._tcp.dc._msdcs.corp.technologytoolbox.com
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 16414
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4000
; COOKIE: 5f26f015d5acfa2c (echoed)
;; QUESTION SECTION:
;_ldap._tcp.dc._msdcs.corp.technologytoolbox.com. IN SRV

;; ANSWER SECTION:
_ldap._tcp.dc._msdcs.corp.technologytoolbox.com. 600 IN SRV 0 100 389 TT-DC08.corp.technologytoolbox.com.
_ldap._tcp.dc._msdcs.corp.technologytoolbox.com. 600 IN SRV 0 100 389 TT-DC09.corp.technologytoolbox.com.

;; ADDITIONAL SECTION:
TT-DC08.corp.technologytoolbox.com. 3600 IN A   10.1.30.2
TT-DC09.corp.technologytoolbox.com. 3600 IN A   10.1.30.3

;; Query time: 2 msec
;; SERVER: 10.1.30.2#53(10.1.30.2)
;; WHEN: Fri Jan 25 14:10:09 MST 2019
;; MSG SIZE  rcvd: 228
```

```Shell
clear
```

#### # Install prerequisites for using realmd

```Shell
sudo apt install realmd
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

```Text
TT-UD18-DEV-03.corp.technologytoolbox.com
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
>  ! Couldn't set service principals on computer account CN=TT-UD18-DEV-03,CN=Computers,DC=corp,DC=technologytoolbox,DC=com: 00002083: AtrErr: DSID-03151904, #1:
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
sudo realm join -v -U jjameson-admin corp.technologytoolbox.com --os-name="Linux (Ubuntu Desktop)" --os-version=18.04

[sudo] password for foo:
 * Resolving: _ldap._tcp.corp.technologytoolbox.com
 * Performing LDAP DSE lookup on: 10.1.30.3
 * Performing LDAP DSE lookup on: 10.1.30.2
 * Successfully discovered: corp.technologytoolbox.com
Password for jjameson-admin:
 * Unconditionally checking packages
 * Resolving required packages
 * Installing necessary packages: adcli libpam-sss libnss-sss sssd sssd-tools
 * LANG=C /usr/sbin/adcli join --verbose --domain corp.technologytoolbox.com --domain-realm CORP.TECHNOLOGYTOOLBOX.COM --domain-controlle
r 10.1.30.2 --os-name Linux (Ubuntu Desktop) --os-version 18.04 --login-type user --login-user jjameson-admin --stdin-password
 * Using domain name: corp.technologytoolbox.com
 * Calculated computer account name from fqdn: TT-UD18-DEV-03
 * Using domain realm: corp.technologytoolbox.com
 * Sending netlogon pings to domain controller: cldap://10.1.30.2
 * Received NetLogon info from: TT-DC08.corp.technologytoolbox.com
 * Wrote out krb5.conf snippet to /var/cache/realmd/adcli-krb5-GpHnQa/krb5.d/adcli-krb5-conf-AJD4CI
 * Authenticated as user: jjameson-admin@CORP.TECHNOLOGYTOOLBOX.COM
 * Looked up short domain name: TECHTOOLBOX
 * Using fully qualified name: TT-UD18-DEV-03.corp.technologytoolbox.com
 * Using domain name: corp.technologytoolbox.com
 * Using computer account name: TT-UD18-DEV-03
 * Using domain realm: corp.technologytoolbox.com
 * Calculated computer account name from fqdn: TT-UD18-DEV-03
 * Generated 120 character computer password
 * Using keytab: FILE:/etc/krb5.keytab
 * Computer account for TT-UD18-DEV-03$ does not exist
 * Found well known computer container at: CN=Computers,DC=corp,DC=technologytoolbox,DC=com
 * Calculated computer account: CN=TT-UD18-DEV-03,CN=Computers,DC=corp,DC=technologytoolbox,DC=com
 * Created computer account: CN=TT-UD18-DEV-03,CN=Computers,DC=corp,DC=technologytoolbox,DC=com
 * Set computer password
 * Retrieved kvno '2' for computer account in directory: CN=TT-UD18-DEV-03,CN=Computers,DC=corp,DC=technologytoolbox,DC=com
 * Modifying computer account: dNSHostName
 * Modifying computer account: userAccountControl
 * Modifying computer account: operatingSystem, operatingSystemVersion, operatingSystemServicePack
 * Modifying computer account: userPrincipalName
 * Discovered which keytab salt to use
 * Added the entries to the keytab: TT-UD18-DEV-03$@CORP.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb5.keytab
 * Added the entries to the keytab: host/TT-UD18-DEV-03@CORP.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb5.keytab
 * Added the entries to the keytab: host/TT-UD18-DEV-03.corp.technologytoolbox.com@CORP.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb5.keytab
 * Added the entries to the keytab: RestrictedKrbHost/TT-UD18-DEV-03@CORP.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb5.keytab
 * Added the entries to the keytab: RestrictedKrbHost/TT-UD18-DEV-03.corp.technologytoolbox.com@CORP.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb
5.keytab
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
id jjameson

uid=453801112(jjameson) gid=453800513(domain users) groups=453800513(domain users),453806158(jameson family),453805109(sharepoint admins (dev)),453807606(folder redirection users),453820115(business unit - global enterprise solutions),453806144(all it staff),453804109(development admins),453806161(extranet approvers (dev)),453806186(branch managers - old),453806107(fabrikam account team),453806154(dow force sync users),453806174(fast search admins (dev)),453820120(business unit - og&p),453820112(business unit - canada),453801110(visual sourcesafe users),453820114(business unit - scis),453820113(business unit - central atlantic),453801153(channel partner managers),453807608(roaming user profiles users and computers),453820117(business unit - north east),453806162(extranet authors (dev)),453820116(business unit - north central),453820118(business unit - pacific),453820110(business unit - multiregional),453805108(sql server admins (dev)),453820111(business unit - national accounts),453804117(sso administrators (dev)),453805111(team foundation server admins (dev)),453801113(all developers),453820119(business unit - south),453814616(branch managers)
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

Password:
Creating directory '/home/corp.technologytoolbox.com/jjameson'.

exit
```

```Shell
clear
```

## # Install Google Chrome

### # Download Google Chrome

```Shell
cd /tmp

wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
```

### # Install Google Chrome

```Shell
sudo dpkg -i google-chrome-stable_current_amd64.deb
```

### Reference

**How to Install Google Chrome Web Browser on Ubuntu 18.04**\
From <[https://linuxize.com/post/how-to-install-google-chrome-web-browser-on-ubuntu-18-04/](https://linuxize.com/post/how-to-install-google-chrome-web-browser-on-ubuntu-18-04/)>

```Shell
clear
```

## # Install and configure Powerline

```Shell
sudo apt install powerline

nano ~/.bashrc
```

---

**~/.bashrc**

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

```Shell
clear
```

## # Install GitKraken

### # Download GitKraken

```Shell
cd /tmp

wget https://release.gitkraken.com/linux/gitkraken-amd64.deb
```

### # Install GitKraken

```Shell
sudo dpkg -i gitkraken-amd64.deb
```

```Shell
clear
```

### # Install GitKraken dependencies

```Shell
sudo apt --fix-broken install
```

### Reference

**How to Install GitKraken**\
From <[https://support.gitkraken.com/how-to-install/](https://support.gitkraken.com/how-to-install/)>

## Install Visual Studio Code

```Shell
clear
```

## # Install .NET Core SDK

### # Register Microsoft key and feed

```Shell
cd /tmp

wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb

sudo dpkg -i packages-microsoft-prod.deb
```

```Shell
clear
```

### # Install .NET SDK

```Shell
sudo add-apt-repository universe

sudo apt-get install apt-transport-https

sudo apt-get update

sudo apt-get install dotnet-sdk-2.2
```

### Reference

**Install .NET Core SDK on Linux Ubuntu 18.04 x64**\
From <[https://dotnet.microsoft.com/download/linux-package-manager/ubuntu18-04/sdk-current](https://dotnet.microsoft.com/download/linux-package-manager/ubuntu18-04/sdk-current)>

```Shell
clear
```

## # Install Wireshark

```Shell
sudo apt-get update
sudo apt-get install wireshark
```

> **Note**
>
> When prompted whether to allow non-superusers to capture packets, select **Yes**.

```Shell
clear
```

## # Configure display resolution

```Shell
sudoedit /etc/default/grub
```

---

**/etc/realmd.conf**

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

### Add Terminal color schemes using Gogh

Gogh - Color Scheme for Gnome Terminal and Pantheon Terminal\
\
[https://mayccoll.github.io/Gogh/](https://mayccoll.github.io/Gogh/)\

| Afterglow               | 6   |
| ----------------------- | --- |
| Arthur                  | 9   |
| Broadcast               | 18  |
| Darkside                | 31  |
| Desert                  | 32  |
| Hybrid                  | 66  |
| Idle Toes               | 69  |
| Japanesque              | 72  |
| Later This Evening      | 76  |
| N0tch2k                 | 92  |
| Neutron                 | 95  |
| Pnevma                  | 116 |
| Spacegray Eighties Dull | 137 |
| Teerb                   | 145 |
| Wombat                  | 166 |

```Shell
bash -c  "$(wget -qO- https://git.io/vQgMr)"
```

\
6 9 18 31 32 66 69 72 76 92 95 116 137 145 166

### Configure Terminal preferences

- Color scheme - N0tch2k
- Size - 132x43

```Shell
clear
```

### # Enable Powerline

```Shell
nano ~/.bashrc
```

---

**~/.bashrc**

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

#### Install extension: C#

#### Install extension: Debugger for Chrome

#### Install extension: ESLint

#### Install extension: GitLens - Git supercharged

#### Install extension: markdownlint

#### Install extension: Prettier - Code formatter

#### Install extension: TSLint

#### Install extension: vscode-icons

### Configure Powerline font in Visual Studio Code

#### User settings

1. Open the Command Palette (press **Ctrl+Shift+P**).
2. Type **Preferences: Open User Settings**.
3. Click** Open settings (JSON)**.

```JSON
{
    "terminal.integrated.fontFamily": "monospace, PowerlineSymbols"
}
```

#### Reference

**Powerline broken symbols in VSCode integrated terminal**\
From <[https://github.com/oh-my-fish/theme-bobthefish/issues/125](https://github.com/oh-my-fish/theme-bobthefish/issues/125)>

---

**STORM - Run as local administrator**

```PowerShell
cls
```

## # Update VM baseline

```PowerShell
$vmName = "TT-UD18-DEV-03"

C:\NotBackedUp\Public\Toolbox\PowerShell\Update-VMBaseline `
    -Name $vmName `
    -Confirm:$false

$newSnapshotName = ("Baseline development environment")

Get-VMSnapshot -VMName $vmName |
    Rename-VMSnapshot -NewName $newSnapshotName
```

---

**TODO:**

```Shell
clear
```

#### # Allow a non-superuser to capture packets with Wireshark

```Shell
sudo usermod -a -G wireshark jjameson
```

```Shell
clear
```

#### # Install package for troubleshooting Kerberos (e.g. kinit)

```Shell
sudo apt install krb5-user
```
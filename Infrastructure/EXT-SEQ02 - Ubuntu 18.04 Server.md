# EXT-SEQ02 - Ubuntu 18.04 Server

Saturday, March 7, 2020\
9:25 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure infrastructure

---

**TT-ADMIN02** - Run as administrator

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "EXT-SEQ02"
$vmPath = "E:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 25GB `
    -MemoryStartupBytes 3.75GB `
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
    -Path "\\TT-FS01\Products\Ubuntu\ubuntu-18.04.4-live-server-amd64.iso"
```

```Text
Set-VMDvdDrive : Failed to add device 'Virtual CD/DVD Disk'.
User Account does not have permission to open attachment.
'EXT-SEQ02' failed to add device 'Virtual CD/DVD Disk'. (Virtual machine ID BB0DC5F5-4568-467F-8312-D914527EFFB3)
'EXT-SEQ02': User account does not have permission required to open attachment
'\\TT-FS01\Products\Ubuntu\ubuntu-18.04.4-live-server-amd64.iso'. Error: 'General access denied error'
(0x80070005). (Virtual machine ID BB0DC5F5-4568-467F-8312-D914527EFFB3)
At line:1 char:1
+ Set-VMDvdDrive `
+ ~~~~~~~~~~~~~~~~
    + CategoryInfo          : PermissionDenied: (:) [Set-VMDvdDrive], VirtualizationException
    + FullyQualifiedErrorId : AccessDenied,Microsoft.HyperV.PowerShell.Commands.SetVMDvdDrive
```

```PowerShell
cls
$iso = Get-SCISO |
    where {$_.Name -eq "ubuntu-18.04.4-live-server-amd64.iso"}

Get-SCVirtualMachine -Name $vmName | Read-SCVirtualMachine

Get-SCVirtualMachine -Name $vmName |
    Get-SCVirtualDVDDrive |
    Set-SCVirtualDVDDrive -ISO $iso -Link

$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Extranet-20 VM Network"
$ipAddressPool = Get-SCStaticIPAddressPool -Name "Extranet-20 Address Pool"

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -IPv4AddressPools $ipAddressPool `
    -IPv4AddressType Static |
    select IPv4Addresses
```

```Text
IPv4Addresses
-------------
{10.1.20.164}
```

```PowerShell
Start-SCVirtualMachine -VM $vmName
```

---

### Install Linux server

Network interface configuration

| Setting        | Value                          |
| -------------- | ------------------------------ |
| Subnet         | 10.1.20.0/24                   |
| Address        | 10.1.20.164                    |
| Gateway        | 10.1.20.1                      |
| Name servers   | 10.1.20.2,10.1.20.3            |
| Search domains | extranet.technologytoolbox.com |

> **Important**
>
> When prompted, select to install **OpenSSH server** and **Docker**.

```Shell
clear
```

### # Check IP address

```Shell
ifconfig | grep inet
```

```Shell
clear
```

### # Install updates

#### # Update APT packages

```Shell
sudo apt-get update
```

> **Note**
>
> When prompted, type the password to run the command as root.

```Shell
clear
```

```Shell
sudo apt-get upgrade -y
```

```Shell
clear
```

#### # Install security updates

```Shell
sudo unattended-upgrade -v
```

> **Note**
>
> Wait for the updates to be installed and then restart the computer.

```Shell
sudo reboot
```

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
systemd-resolve --status
```

```Text
...
        DNS Servers: 10.1.20.2
                     10.1.20.3
...
```

```PowerShell
clear
```

#### # Validate Active Directory DNS records

##### # Validate LDAP SRV records

```Shell
dig -t SRV _ldap._tcp.extranet.technologytoolbox.com
```

```Text
; <<>> DiG 9.11.3-1ubuntu1.11-Ubuntu <<>> -t SRV _ldap._tcp.extranet.technologytoolbox.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 40564
;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;_ldap._tcp.extranet.technologytoolbox.com. IN SRV

;; ANSWER SECTION:
_ldap._tcp.extranet.technologytoolbox.com. 600 IN SRV 0 100 389 EXT-DC10.extranet.technologytoolbox.com.
_ldap._tcp.extranet.technologytoolbox.com. 600 IN SRV 0 100 389 EXT-DC11.extranet.technologytoolbox.com.

;; Query time: 2 msec
;; SERVER: 127.0.0.53#53(127.0.0.53)
;; WHEN: Sat Mar 07 16:40:28 UTC 2020
;; MSG SIZE  rcvd: 128
```

```Shell
clear
```

##### # Validate domain controller SRV records

```Shell
dig @10.1.30.2 -t SRV _ldap._tcp.dc._msdcs.extranet.technologytoolbox.com
```

```Text
; <<>> DiG 9.11.3-1ubuntu1.11-Ubuntu <<>> @10.1.30.2 -t SRV _ldap._tcp.dc._msdcs.extranet.technologytoolbox.com
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 12745
;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4000
;; QUESTION SECTION:
;_ldap._tcp.dc._msdcs.extranet.technologytoolbox.com. IN        SRV

;; ANSWER SECTION:
_ldap._tcp.dc._msdcs.extranet.technologytoolbox.com. 600 IN SRV 0 100 389 EXT-DC11.extranet.technologytoolbox.com.
_ldap._tcp.dc._msdcs.extranet.technologytoolbox.com. 600 IN SRV 0 100 389 EXT-DC10.extranet.technologytoolbox.com.

;; ADDITIONAL SECTION:
EXT-DC11.extranet.technologytoolbox.com. 3083 IN A 10.1.20.3
EXT-DC10.extranet.technologytoolbox.com. 444 IN A 10.1.20.2

;; Query time: 2 msec
;; SERVER: 10.1.30.2#53(10.1.30.2)
;; WHEN: Sat Mar 07 16:40:47 UTC 2020
;; MSG SIZE  rcvd: 230
```

```Shell
clear
```

#### # Install prerequisites for using realmd

```Shell
sudo apt-get install realmd -y
```

> **Note**
>
> When prompted, type the password to run the command as root.

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
> The default home directory path (specified by the **fallback_homedir** setting
> in **/etc/sssd/sssd.conf**) is **/home/%u@%d** (e.g.
> **/home/jjameson-admin@extranet.technologytoolbox.com**). To create home
> directories under a "domain" directory (e.g.
> **/home/extranet.technologytoolbox.com/jjameson-admin**), the **default-home**
> setting is specified in **/etc/realmd.conf** prior to joining the Active
> Directory domain.

```Shell
clear
sudoedit /etc/realmd.conf
```

---

File - **/etc/realmd.conf**

```INI
[users]
default-home = /home/%D/%U

[extranet.technologytoolbox.com]
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
#sudoedit /etc/hostname

sudo hostnamectl set-hostname ext-seq02.extranet.technologytoolbox.com
cat /etc/hostname
```

---

File - **/etc/hostname**

```Text
ext-seq02.extranet.technologytoolbox.com
```

---

```Shell
sudo reboot
```

> **Note**
>
> Changing the hostname to the fully qualified domain name avoids an error when
> creating the service principal name for the computer account when joining the
> Active Directory domain. For example:
>
> ```Text
>  * Modifying computer account: userPrincipalName
>  ! Couldn't set service principals on computer account CN=ext-seq02,CN=Computers,DC=extranet,DC=technologytoolbox,DC=com: 00002083: AtrErr: DSID-03151904, #1:
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
realm discover extranet.technologytoolbox.com -v
```

```Text
 * Resolving: _ldap._tcp.extranet.technologytoolbox.com
 * Performing LDAP DSE lookup on: 10.1.20.3
 * Performing LDAP DSE lookup on: 10.1.20.2
 * Successfully discovered: extranet.technologytoolbox.com
extranet.technologytoolbox.com
  type: kerberos
  realm-name: EXTRANET.TECHNOLOGYTOOLBOX.COM
  domain-name: extranet.technologytoolbox.com
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

```Shell
sudo realm join -v -U jjameson-admin extranet.technologytoolbox.com --os-name="Linux (Ubuntu Server)" --os-version=18.04
```

```Text
 * Resolving: _ldap._tcp.extranet.technologytoolbox.com
 * Performing LDAP DSE lookup on: 10.1.20.2
 * Performing LDAP DSE lookup on: 10.1.20.3
 * Successfully discovered: extranet.technologytoolbox.com
Password for jjameson-admin:
```

```Text
 * Unconditionally checking packages
 * Resolving required packages
 * LANG=C /usr/sbin/adcli join --verbose --domain extranet.technologytoolbox.com --domain-realm EXTRANET.TECHNOLOGYTOOLBOX.COM --domain-controller 10.1.20.2 --os-name Linux (Ubuntu Server) --os-version 18.04 --login-type user --login-user jjameson-admin --stdin-password
 * Using domain name: extranet.technologytoolbox.com
 * Calculated computer account name from fqdn: EXT-SEQ02
 * Using domain realm: extranet.technologytoolbox.com
 * Sending netlogon pings to domain controller: cldap://10.1.20.2
 * Received NetLogon info from: EXT-DC10.extranet.technologytoolbox.com
 * Wrote out krb5.conf snippet to /var/cache/realmd/adcli-krb5-qR91m4/krb5.d/adcli-krb5-conf-tTCu6E
 * Authenticated as user: jjameson-admin@EXTRANET.TECHNOLOGYTOOLBOX.COM
 * Looked up short domain name: EXTRANET
 * Using fully qualified name: ext-seq02.extranet.technologytoolbox.com
 * Using domain name: extranet.technologytoolbox.com
 * Using computer account name: EXT-SEQ02
 * Using domain realm: extranet.technologytoolbox.com
 * Calculated computer account name from fqdn: EXT-SEQ02
 * Generated 120 character computer password
 * Using keytab: FILE:/etc/krb5.keytab
 * Computer account for EXT-SEQ02$ does not exist
 * Found well known computer container at: CN=Computers,DC=extranet,DC=technologytoolbox,DC=com
 * Calculated computer account: CN=EXT-SEQ02,CN=Computers,DC=extranet,DC=technologytoolbox,DC=com
 * Created computer account: CN=EXT-SEQ02,CN=Computers,DC=extranet,DC=technologytoolbox,DC=com
 * Set computer password
 * Retrieved kvno '2' for computer account in directory: CN=EXT-SEQ02,CN=Computers,DC=extranet,DC=technologytoolbox,DC=com
 * Modifying computer account: dNSHostName
 * Modifying computer account: userAccountControl
 * Modifying computer account: operatingSystem, operatingSystemVersion, operatingSystemServicePack
 * Modifying computer account: userPrincipalName
 * Discovered which keytab salt to use
 * Added the entries to the keytab: EXT-SEQ02$@EXTRANET.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb5.keytab
 * Added the entries to the keytab: host/EXT-SEQ02@EXTRANET.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb5.keytab
 * Added the entries to the keytab: host/ext-seq02.extranet.technologytoolbox.com@EXTRANET.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb5.keytab
 * Added the entries to the keytab: RestrictedKrbHost/EXT-SEQ02@EXTRANET.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb5.keytab
 * Added the entries to the keytab: RestrictedKrbHost/ext-seq02.extranet.technologytoolbox.com@EXTRANET.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb5.keytab
 * /usr/sbin/update-rc.d sssd enable
 * /usr/sbin/service sssd restart
 * Successfully enrolled machine in realm
```

```Shell
sudo reboot
```

#### # Test the system configuration after joining the domain

```Shell
id jjameson-admin
```

```Text
uid=1357001118(jjameson-admin) gid=1357000513(domain users) groups=1357000513(domain users),1357000572(denied rodc password replication group),1357007134(message capture users),1357002123(sharepoint admins),1357002126(sql server admins (dev)),1357002127(sharepoint admins (dev)),1357000520(group policy creator owners),1357007102(sql server admins),1357000518(schema admins),1357000519(enterprise admins),1357000512(domain admins)
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

```Text
Skipping profile in /etc/apparmor.d/disable: usr.sbin.rsyslogd
Warning: found usr.sbin.sssd in /etc/apparmor.d/force-complain, forcing complain mode
Warning failed to create cache: usr.sbin.sssd
```

> **Note**
>
> When prompted for additional home directories, type
> **/home/extranet.technologytoolbox.com/** and select **OK**.

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
```

```Text
Password:
Creating directory '/home/extranet.technologytoolbox.com/jjameson-admin'.
```

```Shell
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

### # Manage Docker as a non-root user

```Shell
sudo groupadd docker

sudo usermod -aG docker $USER
sudo usermod -aG docker jjameson-admin

sudo reboot
```

### # Validate Docker configuration

```Shell
docker run hello-world
```

```Shell
clear
```

## # Install Seq

```Shell
docker volume create seq-data

docker run \
  -d \
  --restart unless-stopped \
  --name seq \
  -e ACCEPT_EULA=Y \
  --volume seq-data:/data \
  -p 80:80 \
  -p 5341:5341 \
  datalust/seq:latest
```

### Configure name resolution for Seq

---

**TT-ADMIN03** - Run as administrator

```PowerShell
cls
```

#### # Configure name resolution for seq.corp.technologytoolbox.com

```PowerShell
Add-DnsServerResourceRecordA `
    -ComputerName TT-DC10 `
    -Name seq `
    -IPv4Address 10.1.20.164 `
    -ZoneName corp.technologytoolbox.com
```

---

---

**EXT-DC10** - Run as administrator

```PowerShell
cls
```

#### # Configure name resolution for seq.extranet.technologytoolbox.com

```PowerShell
Add-DNSServerResourceRecordCName `
    -ZoneName extranet.technologytoolbox.com `
    -Name seq `
    -HostNameAlias EXT-SEQ02.extranet.technologytoolbox.com
```

---

```Shell
clear
```

## # Install updates

### # Update APT packages

```Shell
sudo apt-get update
```

> **Note**
>
> When prompted, type the password to run the command as root.

```Shell
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

```Shell
clear
```

## # Upgrade Seq

```Shell
docker ps -a
```

```Text
CONTAINER ID    IMAGE                  ...    NAMES
...             datalust/seq:latest    ...    seq
...
```

```Shell
# Stop container

docker stop seq

# Remove container

docker rm seq

# Remove image

docker rmi seq

# Deploy latest version of Seq

docker run \
  -d \
  --restart unless-stopped \
  --name seq \
  -e ACCEPT_EULA=Y \
  --volume seq-data:/data \
  -p 80:80 \
  -p 5341:5341 \
  datalust/seq:latest
```

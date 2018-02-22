# TT-UBU16-DEV2 - Ubuntu 16.04 Desktop

Wednesday, February 21, 2018
11:24 AM

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
$vmName = "TT-UBU16-DEV2"
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
```

> **Note**
>
> Wait for the updates to be installed and then restart the machine.

```Shell
reboot
```

### # Enable SSH

```Shell
sudo apt install openssh-server
```

---

**WOLVERINE - Run as local administrator**

```PowerShell
cls
```

### # Checkpoint VM

```PowerShell
$checkpointName = "Baseline Ubuntu Desktop 16.04"
$vmName = "TT-UBU16-DEV2"

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

**Join Ubuntu 16.04 into Active Directory Domain**\
From <[http://ricktbaker.com/2017/11/08/ubuntu-16-with-active-directory-connectivity/](http://ricktbaker.com/2017/11/08/ubuntu-16-with-active-directory-connectivity/)>

**SSSD and Active Directory**\
From <[https://help.ubuntu.com/lts/serverguide/sssd-ad.html](https://help.ubuntu.com/lts/serverguide/sssd-ad.html)>

**Realmd and SSSD Active Directory Authentication**\
From <[http://outsideit.net/realmd-sssd-ad-authentication/](http://outsideit.net/realmd-sssd-ad-authentication/)>

### # Check IP address

```Shell
ifconfig | grep "inet addr"
```

---

**WOLVERINE**

```Shell
clear
```

#### # Connect to machine using SSH

```Shell
ssh local-admin@192.168.10.94
```

---

```Shell
clear
```

#### # Validate DNS servers

```Shell
nmcli device show eth0 | grep IP4.DNS
IP4.DNS[1]:                             192.168.10.103
IP4.DNS[2]:                             192.168.10.104
```

```Shell
clear
```

#### # Validate Active Directory DNS records

##### # Validate LDAP SRV records

```Shell
dig -t SRV _ldap._tcp.corp.technologytoolbox.com

; <<>> DiG 9.10.3-P4-Ubuntu <<>> -t SRV _ldap._tcp.corp.technologytoolbox.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 49756
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 5

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4000
;; QUESTION SECTION:
;_ldap._tcp.corp.technologytoolbox.com. IN SRV

;; ANSWER SECTION:
_ldap._tcp.corp.technologytoolbox.com. 600 IN SRV 0 100 389 TT-DC06.corp.technologytoolbox.com.
_ldap._tcp.corp.technologytoolbox.com. 600 IN SRV 0 100 389 TT-DC07.corp.technologytoolbox.com.

;; ADDITIONAL SECTION:
TT-DC06.corp.technologytoolbox.com. 3600 IN A   192.168.10.103
TT-DC06.corp.technologytoolbox.com. 3600 IN AAAA 2603:300b:802:89e0::103
TT-DC07.corp.technologytoolbox.com. 3600 IN A   192.168.10.104
TT-DC07.corp.technologytoolbox.com. 3600 IN AAAA 2603:300b:802:89e0::104

;; Query time: 0 msec
;; SERVER: 127.0.1.1#53(127.0.1.1)
;; WHEN: Thu Feb 22 09:18:23 MST 2018
;; MSG SIZE  rcvd: 262
```

```Shell
clear
```

##### # Validate domain controller SRV records

```Shell
dig -t SRV _ldap._tcp.dc._msdcs.corp.technologytoolbox.com

; <<>> DiG 9.10.3-P4-Ubuntu <<>> -t SRV _ldap._tcp.dc._msdcs.corp.technologytoolbox.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 31989
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 5

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4000
;; QUESTION SECTION:
;_ldap._tcp.dc._msdcs.corp.technologytoolbox.com. IN SRV

;; ANSWER SECTION:
_ldap._tcp.dc._msdcs.corp.technologytoolbox.com. 600 IN SRV 0 100 389 TT-DC06.corp.technologytoolbox.com.
_ldap._tcp.dc._msdcs.corp.technologytoolbox.com. 600 IN SRV 0 100 389 TT-DC07.corp.technologytoolbox.com.

;; ADDITIONAL SECTION:
TT-DC06.corp.technologytoolbox.com. 3600 IN A   192.168.10.103
TT-DC06.corp.technologytoolbox.com. 3600 IN AAAA 2603:300b:802:89e0::103
TT-DC07.corp.technologytoolbox.com. 3600 IN A   192.168.10.104
TT-DC07.corp.technologytoolbox.com. 3600 IN AAAA 2603:300b:802:89e0::104

;; Query time: 0 msec
;; SERVER: 127.0.1.1#53(127.0.1.1)
;; WHEN: Thu Feb 22 09:19:50 MST 2018
;; MSG SIZE  rcvd: 272
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
> The **--os-name** and **--os-version** parameters are not currently supported with the **realm join** command (using Ubuntu 16.04.3 LTS).
>
> Also note the default home directory path (specified by the **fallback_homedir** setting in **/etc/sssd/sssd.conf**) is **/home/%u@%d** (e.g. **/home/jjameson@corp.technologytoolbox.com**). To create home directories under a "domain" directory, the **default-home** setting is specified in **/etc/realmd.conf** prior to joining the Active Directory domain.

```Shell
sudoedit /etc/realmd.conf
```

---

**/etc/realmd.conf**

```INI
[users]
default-home = /home/%D/%U

[active-directory]
os-name = Linux (Ubuntu Desktop)
os-version = 16.04

[corp.technologytoolbox.com]
computer-ou = OU=Workstations,OU=Resources,OU=Development,DC=corp,DC=technologytoolbox,DC=com
fully-qualified-names = no
```

---

##### Reference

**realmd.conf**\
From <[https://www.freedesktop.org/software/realmd/docs/realmd-conf.html](https://www.freedesktop.org/software/realmd/docs/realmd-conf.html)>

```Shell
clear
```

#### # TODO: Modify hostname to avoid error registering SPN on computer account

```Shell
sudoedit /etc/hostname
```

---

**/etc/hostname**

```Text
TT-UBU16-DEV2.corp.technologytoolbox.com
```

---

> **Note**
>
> Changing the hostname to the fully qualified domain name avoids an error when creating the service principal name for the computer account when joining the Active Directory domain. For example:
>
> ```Text
>  * Modifying computer account: userPrincipalName
>  ! Couldn't set service principals on computer account CN=TT-UBU16-DEV1,CN=Computers,DC=corp,DC=technologytoolbox,DC=com: 00002083: AtrErr: DSID-03151904, #1:
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
 * Performing LDAP DSE lookup on: 192.168.10.104
 * Performing LDAP DSE lookup on: 2603:300b:802:89e0::104
 * Performing LDAP DSE lookup on: 192.168.10.104
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
sudo realm join -v -U jjameson-admin corp.technologytoolbox.com
 * Resolving: _ldap._tcp.corp.technologytoolbox.com
 * Performing LDAP DSE lookup on: 192.168.10.104
 * Performing LDAP DSE lookup on: 2603:300b:802:89e0::104
 * Performing LDAP DSE lookup on: 192.168.10.104
 * Successfully discovered: corp.technologytoolbox.com
Password for jjameson-admin:
 * Unconditionally checking packages
 * Resolving required packages
 * LANG=C /usr/sbin/adcli join --verbose --domain corp.technologytoolbox.com --domain-realm CORP.TECHNOLOGYTOOLBOX.COM --domain-controller 192.168.10.104 --os-name Linux (Ubuntu Desktop) --os-version 16.04 --login-type user --login-user jjameson-admin --stdin-password --user-principal
 * Using domain name: corp.technologytoolbox.com
 * Calculated computer account name from fqdn: TT-UBU16-DEV1
 * Using domain realm: corp.technologytoolbox.com
 * Sending netlogon pings to domain controller: cldap://192.168.10.104
 * Received NetLogon info from: TT-DC05.corp.technologytoolbox.com
 * Wrote out krb5.conf snippet to /var/cache/realmd/adcli-krb5-7lhtDV/krb5.d/adcli-krb5-conf-XfcH2k
 * Authenticated as user: jjameson-admin@CORP.TECHNOLOGYTOOLBOX.COM
 * Looked up short domain name: TECHTOOLBOX
 * Using fully qualified name: tt-ubu16-dev1
 * Using domain name: corp.technologytoolbox.com
 * Using computer account name: TT-UBU16-DEV1
 * Using domain realm: corp.technologytoolbox.com
 * Calculated computer account name from fqdn: TT-UBU16-DEV1
 * With user principal: host/tt-ubu16-dev1@CORP.TECHNOLOGYTOOLBOX.COM
 * Generated 120 character computer password
 * Using keytab: FILE:/etc/krb5.keytab
 * Computer account for TT-UBU16-DEV1$ does not exist
 * Found well known computer container at: CN=Computers,DC=corp,DC=technologytoolbox,DC=com
 * Calculated computer account: CN=TT-UBU16-DEV1,CN=Computers,DC=corp,DC=technologytoolbox,DC=com
 * Created computer account: CN=TT-UBU16-DEV1,CN=Computers,DC=corp,DC=technologytoolbox,DC=com
 * Set computer password
 * Retrieved kvno '2' for computer account in directory: CN=TT-UBU16-DEV1,CN=Computers,DC=corp,DC=technologytoolbox,DC=com
 * Modifying computer account: dNSHostName
 * Modifying computer account: userAccountControl
 * Modifying computer account: operatingSystem, operatingSystemVersion, operatingSystemServicePack
 * Modifying computer account: userPrincipalName
 ! Couldn't set service principals on computer account CN=TT-UBU16-DEV1,CN=Computers,DC=corp,DC=technologytoolbox,DC=com: 00002083: AtrErr: DSID-03151904, #1:
        0: 00002083: DSID-03151904, problem 1006 (ATT_OR_VALUE_EXISTS), data 0, Att 90303 (servicePrincipalName)

 * Discovered which keytab salt to use
 * Added the entries to the keytab: TT-UBU16-DEV1$@CORP.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb5.keytab
 * Added the entries to the keytab: host/tt-ubu16-dev1@CORP.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb5.keytab
 * Added the entries to the keytab: host/TT-UBU16-DEV1@CORP.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb5.keytab
 * Cleared old entries from keytab: FILE:/etc/krb5.keytab
 * Added the entries to the keytab: host/tt-ubu16-dev1@CORP.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb5.keytab
 * Added the entries to the keytab: RestrictedKrbHost/TT-UBU16-DEV1@CORP.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb5.keytab
 * Added the entries to the keytab: RestrictedKrbHost/tt-ubu16-dev1@CORP.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb5.keytab
 * /usr/sbin/update-rc.d sssd enable
update-rc.d: error: cannot find a LSB script for sssd
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
uid=453801112(jjameson) gid=453800513(domain users) groups=453800513(domain users),453804109(development admins),453806186(branch managers - old),453805111(team foundation server administrators (dev)),453801110(visual sourcesafe users),453801153(channel partner managers),453814616(branch managers),453806144(all it staff),453805109(sharepoint admins (dev)),453806158(jameson family),453806154(dow force sync users),453806174(fast search administrators (dev)),453801113(all developers),453807608(roaming user profiles users and computers),453807606(folder redirection users),453804117(sso administrators (dev)),453806161(extranet approvers (dev)),453806162(extranet authors (dev)),453806107(fabrikam account team),453805108(sql server admins (dev))
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
session required        pam_mkhomedir.so skel=/etc/skel/ umask=0077
session optional                        pam_sss.so
session optional        pam_systemd.so
session optional        pam_ecryptfs.so unwrap
# end of pam-auth-update config
```

---

```Shell
clear
```

#### # Override GPO access policy

```Shell
sudoedit /etc/sssd/sssd.conf
```

---

**/etc/pam.d/common-session**

```INI
...
[domain/corp.technologytoolbox.com]
...
ad_gpo_access_control = permissive
```

---

```Shell
sudo systemctl restart sssd
```

> **Note**
>
> For more information on this step, refer to the following bug:
>
> **sssd user can't login and ssh to server**\
> From <[https://bugs.launchpad.net/ubuntu/+source/sssd/+bug/1579092](https://bugs.launchpad.net/ubuntu/+source/sssd/+bug/1579092)>

```Shell
clear
```

#### # Login as domain user

```Shell
su - jjameson
Creating directory '/home/corp.technologytoolbox.com/jjameson'.

exit
```

```Shell
clear
```

#### # Configure Ubuntu desktop authentication

```Shell
sudoedit /etc/lightdm/lightdm.conf
```

---

**/etc/lightdm/lightdm.conf**

```INI
[SeatDefaults]
greeter-show-manual-login=true
greeter-hide-users=true
```

---

```Shell
sudo reboot
```

```Shell
clear
```

#### # Configure Samba client

```Shell
sudo mkdir -pv /etc/samba
```

```Shell
clear
sudoedit /etc/samba/smb.conf
```

---

**/etc/samba/smb.conf**

```INI
[global]

# Try to use Simple and Protected NEGOciation (as specified by rfc2478) with
# supporting servers (including WindowsXP, Windows2000 and Samba 3.0) to agree
# upon an authentication mechanism. This enables Kerberos authentication in
# particular.
client use spnego = yes

# Specify how kerberos tickets are verified:
#   secrets and keytab - use the secrets.tdb first, then the system keytab
kerberos method = secrets and keytab

# Configure Samba to act as a domain member in an Active Directory domain
```

# (realm). To operate in this mode, the machine needs to have Kerberos\
# installed and configured and the machine needs to be joined to the domain.

```Text
security = ads
```

---

```Shell
sudo reboot
```

##### Reference

**smb.conf — The configuration file for the Samba suite**\
From <[https://www.samba.org/samba/docs/current/man-html/smb.conf.5.html](https://www.samba.org/samba/docs/current/man-html/smb.conf.5.html)>

```Shell
clear
```

#### # Configure Kerberos

```Shell
sudoedit /etc/krb5.conf
```

---

**/etc/krb5.conf**

```INI
[libdefaults]
;default_realm = CORP.TECHNOLOGYTOOLBOX.COM
;dns_lookup_realm = false
dns_lookup_kdc = true
```

---

```Shell
sudo reboot
```

**TODO:**

```Shell
clear
```

#### # Install package for troubleshooting Kerberos (e.g. kinit)

```Shell
sudo apt install krb5-user
```

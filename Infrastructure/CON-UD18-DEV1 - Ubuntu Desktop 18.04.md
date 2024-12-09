# CON-UD18-DEV1 - Ubuntu 18.04 Desktop

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
$vmName = "CON-UD18-DEV1"
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
    -Path "\\TT-FS01\Products\ubuntu-18.04.4-desktop-amd64.iso"
```

```Text
Set-VMDvdDrive : Failed to add device 'Virtual CD/DVD Disk'.
User Account does not have permission to open attachment.
'CON-UD18-DEV1' failed to add device 'Virtual CD/DVD Disk'. (Virtual machine ID
8F98B27E-0D64-4102-9D06-7964E8B8A09E)
'CON-UD18-DEV1': User account does not have permission required to open attachment
'\\TT-FS01\Products\Ubuntu\ubuntu-18.04.4-desktop-amd64.iso'. Error: 'General access denied error' (0x80070005).
(Virtual machine ID 8F98B27E-0D64-4102-9D06-7964E8B8A09E)
At line:1 char:1
+ Set-VMDvdDrive `
+ ~~~~~~~~~~~~~~~~
    + CategoryInfo          : PermissionDenied: (:) [Set-VMDvdDrive], VirtualizationException
    + FullyQualifiedErrorId : AccessDenied,Microsoft.HyperV.PowerShell.Commands.SetVMDvdDrive
```

```PowerShell
cls
$iso = Get-SCISO |
    where {$_.Name -eq "ubuntu-18.04.4-desktop-amd64.iso"}

Get-SCVirtualMachine -Name $vmName | Read-SCVirtualMachine

Get-SCVirtualMachine -Name $vmName |
    Get-SCVirtualDVDDrive |
    Set-SCVirtualDVDDrive -ISO $iso -Link

$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Contoso VM Network"
$ipAddressPool = Get-SCStaticIPAddressPool -Name "Contoso-60 Address Pool"

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
{10.0.60.102}
```

```PowerShell
Start-SCVirtualMachine -VM $vmName
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

### # Enable SSH

```Shell
sudo apt-get install openssh-server -y
```

### # Check IP address

```Shell
ip address | grep eth0
```

> **Note**
>
> Static IP address is not configured automatically by VMM.

### Configure static IP address

#### Reference

**How to configure a static IP address in Ubuntu Server 18.04**\
From <[https://www.techrepublic.com/article/how-to-configure-a-static-ip-address-in-ubuntu-server-18-04/](https://www.techrepublic.com/article/how-to-configure-a-static-ip-address-in-ubuntu-server-18-04/)>

#### # Create netplan YAML file to define static IP configuration

```PowerShell
cd /etc/netplan

sudo nano 01-netcfg.yaml
```

---

File - **/etc/netplan/01-netcfg.yaml**

```Text
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      addresses: [10.0.60.102/24]
      gateway4: 10.0.60.1
      nameservers:
        addresses: [10.0.60.2,10.0.60.3]
```

---

```Shell
clear
```

#### # Restart networking using netplan

```Shell
sudo netplan apply
```

```Shell
clear
```

#### # Check IP address

```Shell
ip address | grep eth0
```

#### Update IP address in DNS

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
        DNS Servers: 10.0.60.2
                     10.0.60.3
...
```

```PowerShell
clear
```

#### # Validate Active Directory DNS records

##### # Validate LDAP SRV records

```Shell
dig -t SRV _ldap._tcp.corp.contoso.com
```

```Text
; <<>> DiG 9.11.3-1ubuntu1.11-Ubuntu <<>> -t SRV _ldap._tcp.corp.contoso.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 16571
;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;_ldap._tcp.corp.contoso.com.   IN      SRV

;; ANSWER SECTION:
_ldap._tcp.corp.contoso.com. 600 IN     SRV     0 100 389 CON-DC04.corp.contoso.com.
_ldap._tcp.corp.contoso.com. 600 IN     SRV     0 100 389 con-dc03.corp.contoso.com.

;; Query time: 1 msec
;; SERVER: 127.0.0.53#53(127.0.0.53)
;; WHEN: Sat Mar 14 12:02:26 MDT 2020
;; MSG SIZE  rcvd: 114
```

```Shell
clear
```

##### # Validate domain controller SRV records

```Shell
dig @10.0.60.2 -t SRV _ldap._tcp.dc._msdcs.corp.contoso.com
```

```Text
; <<>> DiG 9.11.3-1ubuntu1.11-Ubuntu <<>> @10.0.60.2 -t SRV _ldap._tcp.dc._msdcs.corp.contoso.com
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 29077
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 3, AUTHORITY: 0, ADDITIONAL: 4

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4000
;; QUESTION SECTION:
;_ldap._tcp.dc._msdcs.corp.contoso.com. IN SRV

;; ANSWER SECTION:
_ldap._tcp.dc._msdcs.corp.contoso.com. 600 IN SRV 0 100 389 CON-DC03.corp.contoso.com.
_ldap._tcp.dc._msdcs.corp.contoso.com. 600 IN SRV 0 100 389 con-dc03.corp.contoso.com.
_ldap._tcp.dc._msdcs.corp.contoso.com. 600 IN SRV 0 100 389 CON-DC04.corp.contoso.com.

;; ADDITIONAL SECTION:
CON-DC03.corp.contoso.com. 3600 IN      A       10.0.60.2
con-dc03.corp.contoso.com. 3600 IN      A       10.0.60.2
CON-DC04.corp.contoso.com. 3600 IN      A       10.0.60.3

;; Query time: 1 msec
;; SERVER: 10.0.60.2#53(10.0.60.2)
;; WHEN: Sat Mar 14 12:05:01 MDT 2020
;; MSG SIZE  rcvd: 249
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
> The default home directory path (specified by the **fallback_homedir** setting in **/etc/sssd/sssd.conf**) is **/home/%u@%d** (e.g. **/home/jjameson-admin@corp.contoso.com**). To create home directories under a "domain" directory (e.g. **/home/corp.contoso.com/jjameson-admin**), the **default-home** setting is specified in **/etc/realmd.conf** prior to joining the Active Directory domain.

```Shell
clear
sudo nano /etc/realmd.conf
```

---

File - **/etc/realmd.conf**

```INI
[users]
default-home = /home/%D/%U

[corp.contoso.com]
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
sudo hostnamectl set-hostname con-ud18-dev1.corp.contoso.com
cat /etc/hostname
```

---

File - **/etc/hostname**

```Text
con-ud18-dev1.corp.contoso.com
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
>  ! Couldn't set service principals on computer account CN=con-ud18-dev1,CN=Computers,DC=corp,DC=contoso,DC=com: 00002083: AtrErr: DSID-03151904, #1:
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
realm discover corp.contoso.com -v
```

```Text
 * Resolving: _ldap._tcp.corp.contoso.com
 * Performing LDAP DSE lookup on: 10.0.60.3
 * Performing LDAP DSE lookup on: 10.0.60.2
 * Successfully discovered: corp.contoso.com
corp.contoso.com
  type: kerberos
  realm-name: CORP.CONTOSO.COM
  domain-name: corp.contoso.com
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
sudo realm join -v -U Administrator corp.contoso.com --os-name="Linux (Ubuntu Desktop)" --os-version=18.04
```

```Text
 * Resolving: _ldap._tcp.corp.contoso.com
 * Performing LDAP DSE lookup on: 10.0.60.2
 * Performing LDAP DSE lookup on: 10.0.60.3
 * Successfully discovered: corp.contoso.com
Password for Administrator:
```

```Text
 * Unconditionally checking packages
 * Resolving required packages
 * LANG=C /usr/sbin/adcli join --verbose --domain corp.contoso.com --domain-realm CORP.CONTOSO.COM --domain-controller 10.0.60.3 --os-name Linux (Ubuntu Desktop) --os-version 18.04 --login-type user --login-user Administrator --stdin-password
 * Using domain name: corp.contoso.com
 * Calculated computer account name from fqdn: CON-UD18-DEV1
 * Using domain realm: corp.contoso.com
 * Sending netlogon pings to domain controller: cldap://10.0.60.3
 * Received NetLogon info from: CON-DC04.corp.contoso.com
 * Wrote out krb5.conf snippet to /var/cache/realmd/adcli-krb5-hHOEqa/krb5.d/adcli-krb5-conf-Z6xOZT
 * Authenticated as user: Administrator@CORP.CONTOSO.COM
 * Looked up short domain name: CONTOSO
 * Using fully qualified name: con-ud18-dev1.corp.contoso.com
 * Using domain name: corp.contoso.com
 * Using computer account name: CON-UD18-DEV1
 * Using domain realm: corp.contoso.com
 * Calculated computer account name from fqdn: CON-UD18-DEV1
 * Generated 120 character computer password
 * Using keytab: FILE:/etc/krb5.keytab
 * Computer account for CON-UD18-DEV1$ does not exist
 * Found well known computer container at: CN=Computers,DC=corp,DC=contoso,DC=com
 * Calculated computer account: CN=CON-UD18-DEV1,CN=Computers,DC=corp,DC=contoso,DC=com
 * Created computer account: CN=CON-UD18-DEV1,CN=Computers,DC=corp,DC=contoso,DC=com
 * Set computer password
 * Retrieved kvno '2' for computer account in directory: CN=CON-UD18-DEV1,CN=Computers,DC=corp,DC=contoso,DC=com
 * Modifying computer account: dNSHostName
 * Modifying computer account: userAccountControl
 * Modifying computer account: operatingSystem, operatingSystemVersion, operatingSystemServicePack
 * Modifying computer account: userPrincipalName
 ! Couldn't authenticate with keytab while discovering which salt to use: CON-UD18-DEV1$@CORP.CONTOSO.COM: Client 'CON-UD18-DEV1$@CORP.CONTOSO.COM' not found in Kerberos database
 * Added the entries to the keytab: CON-UD18-DEV1$@CORP.CONTOSO.COM: FILE:/etc/krb5.keytab
 * Added the entries to the keytab: host/CON-UD18-DEV1@CORP.CONTOSO.COM: FILE:/etc/krb5.keytab
 * Added the entries to the keytab: host/con-ud18-dev1.corp.contoso.com@CORP.CONTOSO.COM: FILE:/etc/krb5.keytab
 * Added the entries to the keytab: RestrictedKrbHost/CON-UD18-DEV1@CORP.CONTOSO.COM: FILE:/etc/krb5.keytab
 * Added the entries to the keytab: RestrictedKrbHost/con-ud18-dev1.corp.contoso.com@CORP.CONTOSO.COM: FILE:/etc/krb5.keytab
 * /usr/sbin/update-rc.d sssd enable
 * /usr/sbin/service sssd restart
 * Successfully enrolled machine in realm
```

```Shell
sudo reboot
```

#### # Test the system configuration after joining the domain

```Shell
id aparks
```

```Text
uid=1809605044(aparks) gid=1809600513(domain users) groups=1809600513(domain users)
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
> When prompted for additional home directories, type **/home/corp.contoso.com/** and select **OK**.

##### References

**How do I make AppArmor work with a non-standard HOME directory?**\
From <[https://help.ubuntu.com/community/AppArmor](https://help.ubuntu.com/community/AppArmor)>

**How can I use snap when I don�t use /home/\$USER?**\
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
su - aparks
```

```Text
Password:
Creating directory '/home/corp.contoso.com/aparks'.
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

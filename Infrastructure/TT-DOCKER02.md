# TT-DOCKER02

Thursday, April 15 2021\
4:08 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure infrastructure

---

**TT-ADMIN04** - Run as administrator

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05F"
$vmName = "TT-DOCKER02"
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
    -Path "\\TT-FS01\Products\Ubuntu\ubuntu-20.04-live-server-amd64.iso"
```

```Text
Set-VMDvdDrive : Failed to add device 'Virtual CD/DVD Disk'.
User Account does not have permission to open attachment.
'TT-DOCKER02' failed to add device 'Virtual CD/DVD Disk'. (Virtual machine ID A71F998E-89DA-4E09-A479-AE5A152C8CE5)
'TT-DOCKER02': User account does not have permission required to open attachment
'\\TT-FS01\Products\Ubuntu\ubuntu-20.04-live-server-amd64.iso'. Error: 'General access denied error' (0x80070005).
(Virtual machine ID A71F998E-89DA-4E09-A479-AE5A152C8CE5)
At line:1 char:1
+ Set-VMDvdDrive `
+ ~~~~~~~~~~~~~~~~
    + CategoryInfo          : PermissionDenied: (:) [Set-VMDvdDrive], VirtualizationException
    + FullyQualifiedErrorId : AccessDenied,Microsoft.HyperV.PowerShell.Commands.SetVMDvdDrive
```

```PowerShell
$iso = Get-SCISO |
    where {$_.Name -eq "ubuntu-20.04-live-server-amd64.iso"}

Get-SCVirtualMachine -Name $vmName | Read-SCVirtualMachine

Get-SCVirtualMachine -Name $vmName |
    Get-SCVirtualDVDDrive |
    Set-SCVirtualDVDDrive -ISO $iso -Link

#Start-VM -ComputerName $vmHost -Name $vmName
Start-SCVirtualMachine -VM $vmName
```

---

### Install Ubuntu server

- On the **SSH Setup** step, select **Install OpenSSH server**.
- On the **Featured Server Snaps** step, select the following items:
    - **docker**
    - **powershell**

> **Note**
>
> When prompted, restart the computer to complete the installation.

### Install updates using Software Updater

### # Update APT packages

```Shell
sudo apt-get update
sudo apt-get upgrade -y
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

```Shell
clear
```

### # Check IP address

```Shell
ifconfig | grep inet
```

---

**TT-ADMIN04** - Run as administrator

```PowerShell
cls
```

### # Checkpoint VM

```PowerShell
$checkpointName = "Baseline Ubuntu Server 20.04.3"
$vmName = "TT-DOCKER02"

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
```

```Text
...
        DNS Servers: 10.1.30.2
                     10.1.30.3
...
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
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 34222
;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;_ldap._tcp.corp.technologytoolbox.com. IN SRV

;; ANSWER SECTION:
_ldap._tcp.corp.technologytoolbox.com. 600 IN SRV 0 100 389 tt-dc10.corp.technologytoolbox.com.
_ldap._tcp.corp.technologytoolbox.com. 600 IN SRV 0 100 389 tt-dc11.corp.technologytoolbox.com.

;; Query time: 3 msec
;; SERVER: 127.0.0.53#53(127.0.0.53)
;; WHEN: Thu Apr 15 22:41:46 UTC 2021
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
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 54750
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 3, AUTHORITY: 0, ADDITIONAL: 4

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4000
;; QUESTION SECTION:
;_ldap._tcp.dc._msdcs.corp.technologytoolbox.com. IN SRV

;; ANSWER SECTION:
_ldap._tcp.dc._msdcs.corp.technologytoolbox.com. 600 IN SRV 0 100 389 tt-dc11.corp.technologytoolbox.com.
_ldap._tcp.dc._msdcs.corp.technologytoolbox.com. 600 IN SRV 0 100 389 TT-DC10.corp.technologytoolbox.com.
_ldap._tcp.dc._msdcs.corp.technologytoolbox.com. 600 IN SRV 0 100 389 tt-dc10.corp.technologytoolbox.com.

;; ADDITIONAL SECTION:
tt-dc11.corp.technologytoolbox.com. 3600 IN A   10.1.30.3
TT-DC10.corp.technologytoolbox.com. 3600 IN A   10.1.30.2
tt-dc10.corp.technologytoolbox.com. 3600 IN A   10.1.30.2

;; Query time: 0 msec
;; SERVER: 10.1.30.2#53(10.1.30.2)
;; WHEN: Thu Apr 15 22:42:24 UTC 2021
;; MSG SIZE  rcvd: 286
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
clear
```

```Shell
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
cat /etc/hostname
```

```Text
tt-docker02
```

```Shell
sudo hostnamectl set-hostname tt-docker02.corp.technologytoolbox.com

cat /etc/hostname
```

```Text
tt-docker02.corp.technologytoolbox.com
```

```Shell
sudo reboot
```

> **Note**
>
> Changing the hostname to the fully qualified domain name avoids an error when creating the service principal name for the computer account when joining the Active Directory domain. For example:
>
> ```Text
>  * Modifying computer account: userPrincipalName
>  ! Couldn't set service principals on computer account CN=tt-docker02,CN=Computers,DC=corp,DC=technologytoolbox,DC=com: 00002083: AtrErr: DSID-03151904, #1:
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
```

```Text
 * Resolving: _ldap._tcp.corp.technologytoolbox.com
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
sudo realm join -v -U jjameson-admin corp.technologytoolbox.com --os-name="Linux (Ubuntu Server)" --os-version=20.04
```

```Text
 * Resolving: _ldap._tcp.corp.technologytoolbox.com
 * Performing LDAP DSE lookup on: 10.1.30.2
 * Successfully discovered: corp.technologytoolbox.com
Password for jjameson-admin:
 * Unconditionally checking packages
 * Resolving required packages
 * LANG=C /usr/sbin/adcli join --verbose --domain corp.technologytoolbox.com --domain-realm CORP.TECHNOLOGYTOOLBOX.COM --domain-controller 10.1.30.2 --os-name Linux (Ubuntu Server) --os-version 20.04 --login-type user --login-user jjameson-admin --stdin-password
 * Using domain name: corp.technologytoolbox.com
 * Calculated computer account name from fqdn: TT-DOCKER02
 * Using domain realm: corp.technologytoolbox.com
 * Sending NetLogon ping to domain controller: 10.1.30.2
 * Received NetLogon info from: TT-DC10.corp.technologytoolbox.com
 * Wrote out krb5.conf snippet to /var/cache/realmd/adcli-krb5-fwgBVl/krb5.d/adcli-krb5-conf-Jf2BXj
 * Authenticated as user: jjameson-admin@CORP.TECHNOLOGYTOOLBOX.COM
 * Using GSS-SPNEGO for SASL bind
 * Looked up short domain name: TECHTOOLBOX
 * Looked up domain SID: S-1-5-21-3914637029-2275272621-3670275343
 * Using fully qualified name: tt-docker02.corp.technologytoolbox.com
 * Using domain name: corp.technologytoolbox.com
 * Using computer account name: TT-DOCKER02
 * Using domain realm: corp.technologytoolbox.com
 * Calculated computer account name from fqdn: TT-DOCKER02
 * Generated 120 character computer password
 * Using keytab: FILE:/etc/krb5.keytab
 * Computer account for TT-DOCKER02$ does not exist
 * Found well known computer container at: CN=Computers,DC=corp,DC=technologytoolbox,DC=com
 * Calculated computer account: CN=TT-DOCKER02,CN=Computers,DC=corp,DC=technologytoolbox,DC=com
 * Encryption type [3] not permitted.
 * Encryption type [1] not permitted.
 * Created computer account: CN=TT-DOCKER02,CN=Computers,DC=corp,DC=technologytoolbox,DC=com
 * Sending NetLogon ping to domain controller: 10.1.30.2
 * Received NetLogon info from: TT-DC10.corp.technologytoolbox.com
 * Set computer password
 * Retrieved kvno '2' for computer account in directory: CN=TT-DOCKER02,CN=Computers,DC=corp,DC=technologytoolbox,DC=com
 * Checking RestrictedKrbHost/tt-docker02.corp.technologytoolbox.com
 *    Added RestrictedKrbHost/tt-docker02.corp.technologytoolbox.com
 * Checking RestrictedKrbHost/TT-DOCKER02
 *    Added RestrictedKrbHost/TT-DOCKER02
 * Checking host/tt-docker02.corp.technologytoolbox.com
 *    Added host/tt-docker02.corp.technologytoolbox.com
 * Checking host/TT-DOCKER02
 *    Added host/TT-DOCKER02
 * Discovered which keytab salt to use
 * Added the entries to the keytab: TT-DOCKER02$@CORP.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb5.keytab
 * Added the entries to the keytab: host/TT-DOCKER02@CORP.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb5.keytab
 * Added the entries to the keytab: host/tt-docker02.corp.technologytoolbox.com@CORP.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb5.keytab
 * Added the entries to the keytab: RestrictedKrbHost/TT-DOCKER02@CORP.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb5.keytab
 * Added the entries to the keytab: RestrictedKrbHost/tt-docker02.corp.technologytoolbox.com@CORP.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb5.keytab
 * /usr/sbin/update-rc.d sssd enable
 * /usr/sbin/service sssd restart
 * Successfully enrolled machine in realm
 ```

 ```Shell
 clear
 ```

```Shell
sudo reboot
```

```Shell
clear
```

#### # Test the system configuration after joining the domain

```Shell
id jjameson-admin
```

```Text
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
```

```Text
Broadcast message from systemd-journald@tt-docker02.corp.technologytoolbox.com (Thu 2021-04-15 22:58:51 UTC):

sssd_be[827]: Group Policy Container with DN [cn={09931EAD-8D08-4F58-BD7F-F92B16403B8E},cn=policies,cn=system,DC=corp,DC=technologytoolbox,DC=com] is unreadable or has unreadable or missing attributes. In order to fix this make sure that this AD object has following attributes readable: nTSecurityDescriptor, cn, gPCFileSysPath, gPCMachineExtensionNames, gPCFunctionalityVersion, flags. Alternatively if you do not have access to the server or can not change permissions on this object, you can use option ad_gpo_ignore_unreadable = True which will skip this GPO. See ad_gpo_ignore_unreadable in 'man sssd-ad' for details.


Message from syslogd@tt-docker02 at Apr 15 22:58:51 ...
 sssd_be[827]: Group Policy Container with DN [cn={09931EAD-8D08-4F58-BD7F-F92B16403B8E},cn=policies,cn=system,DC=corp,DC=technologytoolbox,DC=com] is unreadable or has unreadable or missing attributes. In order to fix this make sure that this AD object has following attributes readable: nTSecurityDescriptor, cn, gPCFileSysPath, gPCMachineExtensionNames, gPCFunctionalityVersion, flags. Alternatively if you do not have access to the server or can not change permissions on this object, you can use option ad_gpo_ignore_unreadable = True which will skip this GPO. See ad_gpo_ignore_unreadable in 'man sssd-ad' for details.
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
su - jjameson-admin
```

```Text
Password:
Creating directory '/home/corp.technologytoolbox.com/jjameson-admin'.
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

## # Install Git

### # Update APT packages

```Shell
sudo apt-get update
sudo apt-get upgrade -y
```

```Shell
clear
```

```Shell
sudo apt-get install git
```

### Reference

**Installing _Git_ on _Linux_**\
From <[https://gist.github.com/derhuerst/1b15ff4652a867391f03#file-linux-md](https://gist.github.com/derhuerst/1b15ff4652a867391f03#file-linux-md)>

```Shell
clear
```

## # Test Docker installation

### # Verify Docker is installed correctly by running hello-world image

```Shell
sudo docker run hello-world
```

```Shell
clear
```

## # Install Docker Compose

### # Download current stable release of Docker Compose

```Shell
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
```

```Shell
clear
```

### # Apply executable permissions to the binary

```Shell
sudo chmod +x /usr/local/bin/docker-compose
```

### # Test Docker Compose installation

```Shell
docker-compose --version
```

### Reference

**Install Docker Compose**\
From <[https://docs.docker.com/compose/install/](https://docs.docker.com/compose/install/)>

---

**TT-ADMIN04** - Run as administrator

```PowerShell
cls
```

## # Remove VM checkpoint

```PowerShell
$vmName = "TT-DOCKER02"
```

### # Shutdown VM

```PowerShell
Stop-SCVirtualMachine -VM $vmName
```

### # Remove VM snapshot

```PowerShell
Get-SCVMCheckpoint -VM $vmName |
    Remove-SCVMCheckpoint
```

### # Start VM

```PowerShell
Start-SCVirtualMachine -VM $vmName
```

---

---

**TT-ADMIN04** - Run as administrator

```PowerShell
cls
```

## # Make virtual machine highly available

### # Migrate VM to shared storage

```PowerShell
$vmName = "TT-DOCKER02"

$vm = Get-SCVirtualMachine -Name $vmName
$vmHost = $vm.VMHost

Move-SCVirtualMachine `
    -VM $vm `
    -VMHost $vmHost `
    -HighlyAvailable $true `
    -Path "C:\ClusterStorage\iscsi02-Silver-01" `
    -UseDiffDiskOptimization
```

```PowerShell
cls
```

### # Allow migration to host with different processor version

```PowerShell
Stop-SCVirtualMachine -VM $vmName

Set-SCVirtualMachine -VM $vmName -CPULimitForMigration $true

Start-SCVirtualMachine -VM $vmName
```

---

## Configure backups

### Add virtual machine to Hyper-V protection group in DPM

**TODO:**

```Shell
clear
```

## # Remove cached Docker images

```Shell
sudo docker system prune df

sudo docker system prune -a

sudo docker system prune df
```

# TT-MAIL-TEST01

Friday, May 17, 2019\
9:08 AM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure infrastructure

---

**FOOBAR18** - Run as administrator

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmHost = "TT-HV05C"
$vmName = "TT-MAIL-TEST01"
$vmPath = "D:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 25GB `
    -MemoryStartupBytes 2GB `
    -SwitchName "Embedded Team Switch"

Set-VM `
    -ComputerName $vmHost `
    -Name $vmName `
    -AutomaticCheckpointsEnabled $false `
    -ProcessorCount 2 `
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
'TT-MAIL-TEST01' failed to add device 'Virtual CD/DVD Disk'. (Virtual machine ID 2AE56627-B5E1-489B-B8D4-C2733F9940C9)
'TT-MAIL-TEST01': User account does not have permission required to open attachment
'\\TT-FS01\Products\Ubuntu\ubuntu-18.04.2-live-server-amd64.iso'. Error: 'General access denied error' (0x80070005). (Virtual machine
ID 2AE56627-B5E1-489B-B8D4-C2733F9940C9)
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
sudo apt-get install openssh-server -y
```

---

**FOOBAR18** - Run as administrator

```PowerShell
cls
```

### # Checkpoint VM

```PowerShell
$checkpointName = "Baseline Ubuntu Server 18.04.2"
$vmName = "TT-MAIL-TEST01"

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
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 41644
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
;; WHEN: Fri May 17 15:53:53 UTC 2019
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
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 55294
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
;; WHEN: Fri May 17 15:54:28 UTC 2019
;; MSG SIZE  rcvd: 216
```

```Shell
clear
```

#### # Install prerequisites for using realmd

```Shell
sudo apt-get install realmd -y
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
> The default home directory path (specified by the **fallback_homedir** setting in **/etc/sssd/sssd.conf**) is **/home/%u@%d** (e.g. **/home/jjameson@corp.technologytoolbox.com**). To create home directories under a "domain" directory (e.g. **/home/corp.technologytoolbox.com/jjameson**), the **default-home** setting is specified in **/etc/realmd.conf** prior to joining the Active Directory domain.

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
sudoedit /etc/hostname
```

---

File - **/etc/hostname**

```Text
tt-mail-test01.corp.technologytoolbox.com
```

---

```Shell
sudo reboot

cat /etc/hostname

tt-mail-test01

sudo hostnamectl set-hostname tt-mail-test01.corp.technologytoolbox.com

cat /etc/hostname

tt-mail-test01.corp.technologytoolbox.com
```

> **Note**
>
> Changing the hostname to the fully qualified domain name avoids an error when creating the service principal name for the computer account when joining the Active Directory domain. For example:
>
> ```Text
>  * Modifying computer account: userPrincipalName
>  ! Couldn't set service principals on computer account CN=tt-mail-test01,CN=Computers,DC=corp,DC=technologytoolbox,DC=com: 00002083: AtrErr: DSID-03151904, #1:
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

 * Resolving: _ldap._tcp.corp.technologytoolbox.com
 * Performing LDAP DSE lookup on: 10.1.30.2
 * Performing LDAP DSE lookup on: 10.1.30.3
 * Successfully discovered: corp.technologytoolbox.com
Password for jjameson-admin:
 * Unconditionally checking packages
 * Resolving required packages
 * LANG=C /usr/sbin/adcli join --verbose --domain corp.technologytoolbox.com --domain-realm CORP.TECHNOLOGYTOOLBOX.COM --domain-controller 10.1.30.2 --os-name Linux (Ubuntu Server) --os-version 18.04 --login-type user --login-user jjameson-admin --stdin-password
 * Using domain name: corp.technologytoolbox.com
 * Calculated computer account name from fqdn: TT-MAIL-TEST01
 * Using domain realm: corp.technologytoolbox.com
 * Sending netlogon pings to domain controller: cldap://10.1.30.2
 * Received NetLogon info from: TT-DC08.corp.technologytoolbox.com
 * Wrote out krb5.conf snippet to /var/cache/realmd/adcli-krb5-q81fL4/krb5.d/adcli-krb5-conf-Ng7r0u
 * Authenticated as user: jjameson-admin@CORP.TECHNOLOGYTOOLBOX.COM
 * Looked up short domain name: TECHTOOLBOX
 * Using fully qualified name: tt-mail-test01.corp.technologytoolbox.com
 * Using domain name: corp.technologytoolbox.com
 * Using computer account name: TT-MAIL-TEST01
 * Using domain realm: corp.technologytoolbox.com
 * Calculated computer account name from fqdn: TT-MAIL-TEST01
 * Generated 120 character computer password
 * Using keytab: FILE:/etc/krb5.keytab
 * Computer account for TT-MAIL-TEST01$ does not exist
 * Found well known computer container at: CN=Computers,DC=corp,DC=technologytoolbox,DC=com
 * Calculated computer account: CN=TT-MAIL-TEST01,CN=Computers,DC=corp,DC=technologytoolbox,DC=com
 * Created computer account: CN=TT-MAIL-TEST01,CN=Computers,DC=corp,DC=technologytoolbox,DC=com
 * Set computer password
 * Retrieved kvno '2' for computer account in directory: CN=TT-MAIL-TEST01,CN=Computers,DC=corp,DC=technologytoolbox,DC=com
 * Modifying computer account: dNSHostName
 * Modifying computer account: userAccountControl
 * Modifying computer account: operatingSystem, operatingSystemVersion, operatingSystemServicePack
 * Modifying computer account: userPrincipalName
 * Discovered which keytab salt to use
 * Added the entries to the keytab: TT-MAIL-TEST01$@CORP.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb5.keytab
 * Added the entries to the keytab: host/TT-MAIL-TEST01@CORP.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb5.keytab
 * Added the entries to the keytab: host/tt-mail-test01.corp.technologytoolbox.com@CORP.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb5.keytab
 * Added the entries to the keytab: RestrictedKrbHost/TT-MAIL-TEST01@CORP.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb5.keytab
 * Added the entries to the keytab: RestrictedKrbHost/tt-mail-test01.corp.technologytoolbox.com@CORP.TECHNOLOGYTOOLBOX.COM: FILE:/etc/krb5.keytab
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

File - **/etc/pam.d/common-session**

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

```PowerShell
sudo apt-get update
sudo apt-get upgrade -y
```

```PowerShell
clear
sudo apt-get install git

Reading package lists... Done
Building dependency tree
Reading state information... Done
git is already the newest version (1:2.17.1-1ubuntu0.4).
0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.
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

---

**FOOBAR18** - Run as administrator

```PowerShell
cls
```

## # Remove VM checkpoint

```PowerShell
$vmName = "TT-MAIL-TEST01"
```

### # Shutdown VM

```PowerShell
Stop-SCVirtualMachine -VM $vmName
```

### # Remove VM snapshot

```PowerShell
Get-SCVMCheckpoint -VM $vmName | Remove-SCVMCheckpoint
```

### # Start VM

```PowerShell
Start-SCVirtualMachine -VM $vmName
```

---

## Configure backups

### Add virtual machine to Hyper-V protection group in DPM

## Configure name resolution for email server

---

**FOOBAR18** - Run as administrator

```PowerShell
Add-DNSServerResourceRecordCName `
    -ComputerName TT-DC08 `
    -ZoneName technologytoolbox.com `
    -Name mail-test `
    -HostNameAlias TT-MAIL-TEST01.corp.technologytoolbox.com

Add-DNSServerResourceRecordCName `
    -ComputerName TT-DC08 `
    -ZoneName technologytoolbox.com `
    -Name smtp-test `
    -HostNameAlias TT-MAIL-TEST01.corp.technologytoolbox.com
```

---

```Shell
clear
```

## # Install MailHog

```Shell
sudo docker run \
    --name "mailhog" \
    --publish 25:1025 \
    --publish 80:8025 \
    --restart unless-stopped \
    --tty \
    mailhog/mailhog
```

### Reference

**Setting up SMTP mail server using mailhog docker image**\
From <[https://www.linkedin.com/pulse/setting-up-smtp-mail-server-using-mailhog-docker-image-chopparapu](https://www.linkedin.com/pulse/setting-up-smtp-mail-server-using-mailhog-docker-image-chopparapu)>

```Shell
clear
```

### # Stop "mailhog" container

```Shell
sudo docker stop mailhog
```

```Shell
clear
```

## # Install poste.io

```Shell
sudo docker volume create mail-test-data

sudo docker run \
    --hostname "mail-test.technologytoolbox.com" \
    --name "mail-test" \
    --net=host \
    --volume /etc/localtime:/etc/localtime:ro \
    --volume mail-test-data:/data \
    --tty \
    analogic/poste.io
```

### Configure poste.io

```Shell
clear
```

### # Backup poste.io data volume

#### # Stop "mail-test" container

```Shell
sudo docker stop mail-test
```

```Shell
clear
```

#### # Backup data volume

##### # - Launch a new container and mount the volume from the "mail-test" container

##### # - Mount a local host directory as /backup

##### # - Pass a command that adds the contents of the data volume to a tar file inside the /backup directory

```Shell
now=$(date +"%Y-%m-%d_%H-%M-%S")
backupFilename=mail-test-data_$now.tar

sudo docker run \
    --rm \
    --volume /var/backups:/backup \
    --volumes-from mail-test \
    ubuntu \
    tar cvf /backup/$backupFilename /data
```

```Shell
clear
```

#### # Start "mail-test" container

```Shell
sudo docker start mail-test
```

```Shell
clear
```

### # Restore poste.io data volume

#### # Stop "mail-test" container

```Shell
sudo docker stop mail-test
```

```Shell
clear
```

#### # Create "mail-test-restore" container

```Shell
sudo docker run --name mail-test-restore --volume /data ubuntu /bin/bash
```

#### # Un-tar the backup file in the new container's data volume

```Shell
sudo docker run \
    --rm \
    --volume /var/backups:/backup \
    --volumes-from mail-test \
    ubuntu \
    bash -c "cd /data && tar xvf /backup/mail-test-data_2019-05-29_22-28-32.tar --strip 1"
```

```Shell
clear
```

#### # Remove "mail-test-restore" container (to forcibly disconnect from volumes)

```Shell
sudo docker container rm mail-test-restore
```

```Shell
clear
```

#### # Start "mail-test" container

```Shell
sudo docker start mail-test
```

```Shell
clear
```

### # Remove mail-test container and data volume

```Shell
sudo docker stop mail-test

#sudo docker rm mail-test --volumes

sudo docker rm mail-test
#sudo docker volume rm mail-test-data
```

```Shell
clear
```

### # Run mail-test container (and configure to always restart)

```Shell
sudo docker run \
    --hostname "mail-test.technologytoolbox.com" \
    --name "mail-test" \
    --net=host \
    --volume /etc/localtime:/etc/localtime:ro \
    --volume mail-test-data:/data \
    --restart always \
    analogic/poste.io

sudo docker logs mail-test
```

## Move VM to Production VM network

---

**FOOBAR18** - Run as administrator

```PowerShell
cls
```

### # Configure network adapter for Production VM network

```PowerShell
$vmName = "TT-MAIL-TEST01"
$networkAdapter = Get-SCVirtualNetworkAdapter -VM $vmName
$vmNetwork = Get-SCVMNetwork -Name "Production VM Network"
$ipAddressPool = Get-SCStaticIPAddressPool -Name "Production-15 Address Pool"

Stop-SCVirtualMachine $vmName

Set-SCVirtualNetworkAdapter `
    -VirtualNetworkAdapter $networkAdapter `
    -VMNetwork $vmNetwork `
    -IPv4AddressPools $ipAddressPool `
    -IPv4AddressType Static

Start-SCVirtualMachine $vmName
```

---

> **Note**
>
> IPv4 address allocated by VMM: **10.0.15.110**

### # Check IP address

```Shell
ifconfig | grep inet
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
      addresses: [10.0.15.110/24]
      nameservers:
        addresses: [10.0.15.2,10.0.15.3]
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
ifconfig | grep inet
```

#### Update IP address in DNS

> **Note**
>
> After changing to a static IP address, poste.io was still binding to the old IP address (DHCP - 192.168.10.x). To resolve this issue, the container was stopped, removed, and recreated (including restoring the data volume from backup).

---

**FOOBAR18** - Run as administrator

```PowerShell
cls
```

## # Make virtual machine highly available

### # Migrate VM to shared storage

```PowerShell
$vmName = "TT-MAIL-TEST01"

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

## Install certificate for mail server

---

**TT-WIN10-DEV6** - Run as administrator

```PowerShell
cls
```

### # Create certificate for mail server

#### # Create certificate request

```PowerShell
& "C:\NotBackedUp\Public\Toolbox\PowerShell\New-CertificateRequest.ps1" `
    -Subject ("CN=mail-test.technologytoolbox.com,OU=Quality Assurance," `
        + "O=Technology Toolbox,L=Parker,S=CO,C=US") `
    -SANs mail-test.technologytoolbox.com,smtp-test.technologytoolbox.com
```

#### # Submit certificate request to the Certification Authority

##### # Add Active Directory Certificate Services site to the "Trusted sites" zone and browse to the site

```PowerShell
[Uri] $adcsUrl = [Uri] "https://cipher01.corp.technologytoolbox.com"

C:\NotBackedUp\Public\Toolbox\PowerShell\Add-InternetSecurityZoneMapping.ps1 `
    -Zone LocalIntranet `
    -Patterns $adcsUrl.AbsoluteUri

Start-Process $adcsUrl.AbsoluteUri
```

##### # Submit the certificate request to an enterprise CA

> **Note**
>
> Copy the certificate request to the clipboard.

**To submit the certificate request to an enterprise CA:**

1. Start Internet Explorer, and browse to the Active Directory Certificate Services site ([https://cipher01.corp.technologytoolbox.com/](https://cipher01.corp.technologytoolbox.com/)).
2. On the **Welcome** page, click **Request a certificate**.
3. On the **Advanced Certificate Request** page, click **Submit a certificate request by using a base-64-encoded CMC or PKCS #10 file, or submit a renewal request by using a base-64-encoded PKCS #7 file.**
4. On the **Submit a Certificate Request or Renewal Request** page, in the **Saved Request** text box, paste the contents of the certificate request generated in the previous procedure.
5. In the **Certificate Template** section, select the certificate template (**Technology Toolbox Web Server - Exportable**), and then click **Submit**. When prompted to allow the digital certificate operation to be performed, click **Yes**.
6. On the **Certificate Issued** page, click **Download certificate** and save the certificate.

```PowerShell
cls
```

#### # Import the certificate into the certificate store

```PowerShell
$certFile = "C:\Users\jjameson-admin\Downloads\certnew.cer"

CertReq.exe -Accept $certFile
```

```PowerShell
cls
```

#### # Delete the certificate file

```PowerShell
Remove-Item $certFile
```

#### Export certificate

Filename: **C:\NotBackedUp\Temp\mail-test.technologytoolbox.com.pfx**

```PowerShell
cls
```

#### # Split PFX certificate into required files

```PowerShell
Push-Location C:\NotBackedUp\Temp
```

##### # Extract private key from PFX certificate file

```PowerShell
C:\NotBackedUp\Public\Toolbox\OpenSSL-Win64\bin\openssl.exe `
    pkcs12 -nocerts -nodes `
    -in mail-test.technologytoolbox.com.pfx `
    -out mail-test.technologytoolbox.com.key
```

> **Note**
>
> When prompted, type the password specified previously when exporting the certificate.

##### # Extract public key from PFX certificate file

```PowerShell
C:\NotBackedUp\Public\Toolbox\OpenSSL-Win64\bin\openssl.exe `
    pkcs12 -clcerts -nokeys `
    -in mail-test.technologytoolbox.com.pfx `
    -out mail-test.technologytoolbox.com.crt
```

> **Note**
>
> When prompted, type the password specified previously when exporting the certificate.

##### # Extract Certificate Authority (CA) certificate chain from PFX certificate file

```PowerShell
C:\NotBackedUp\Public\Toolbox\OpenSSL-Win64\bin\openssl.exe `
    pkcs12 -cacerts -chain -nokeys `
    -in mail-test.technologytoolbox.com.pfx `
    -out chain.crt
```

> **Note**
>
> When prompted, type the password specified previously when exporting the certificate.

```PowerShell
Pop-Location
```

---

**TODO:**

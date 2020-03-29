# TT-DOCKER02-DEV

Friday, March 6, 2020
2:25 PM

```Text
12345678901234567890123456789012345678901234567890123456789012345678901234567890
```

## Deploy and configure infrastructure

---

**WOLVERINE** - Run as administrator

```PowerShell
cls
```

### # Create virtual machine

```PowerShell
$vmName = "TT-DOCKER02-DEV"
$vmPath = "D:\NotBackedUp\VMs"
$vhdPath = "$vmPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

New-VM `
    -Name $vmName `
    -Generation 2 `
    -Path $vmPath `
    -NewVHDPath $vhdPath `
    -NewVHDSizeBytes 20GB `
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
    -Path "\\TT-FS01\Products\Ubuntu\ubuntu-18.04.4-live-server-amd64.iso"

Start-VM -Name $vmName
```

---

### Install Linux server

> **Important**
>
> When prompted, select to install openssh-server and Docker.

### # Install security updates

```Shell
sudo unattended-upgrade -v

reboot
```

### # Check IP address

```Shell
ifconfig | grep inet
```

### Install Docker Compose

```Shell
sudo curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
```

```Shell
sudo chmod +x /usr/local/bin/docker-compose
```

```Shell
docker volume create seq-data

docker run \
  -d \
  --restart unless-stopped \
  --name seq \
  -e ACCEPT_EULA=Y \
  --volume seq-data:/data \
  -p 8080:80 \
  -p 5341:5341 \
  datalust/seq:latest
```

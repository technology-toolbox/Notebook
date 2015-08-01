# Migrate VMs from VirtualBox to Hyper-V

Friday, July 31, 2015
3:12 PM

## # Create virtual machine (WIN7-TEST1)

```PowerShell
$vmName = "WIN7-TEST1"

Function ConvertVM($vmName) {
    New-VM `
        -Name $vmName `
        -Path C:\NotBackedUp\VMs `
        -MemoryStartupBytes 2GB `
        -SwitchName "Virtual LAN 2 - 192.168.10.x"

    $sourceVdi = "C:\NotBackedUp\Temp\VirtualBox\Test\$vmName\$vmName.vdi"

    $tempVhdPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhd"

    & 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' clonehd $sourceVdi $tempVhdPath --format VHD

    $vhdxPath = "C:\NotBackedUp\VMs\$vmName\Virtual Hard Disks\$vmName.vhdx"

    Convert-VHD `
        -Path $tempVhdPath `
        -DestinationPath $vhdxPath

    Set-VHD $vhdxPath -PhysicalSectorSizeBytes 4096

    Add-VMHardDiskDrive -VMName $vmName -Path $vhdxPath

    Start-VM $vmName
}



$ErrorActionPreference = 'Stop'

Get-ChildItem C:\NotBackedUp\Temp\VirtualBox -Filter *.vdi -Recurse |
 % {
    $sourceVdi = $_.FullName

    If ($sourceVdi.Contains('{') -eq $false)
    {
        $tempVhdPath = $sourceVdi.Replace('.vdi', '.vhd')

        Write-Host "Converting $sourceVdi..."

        & 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' clonehd $sourceVdi $tempVhdPath --format VHD

        $vhdxPath = $tempVhdPath.Replace('.vhd', '.vhdx')

        Write-Host "Converting $tempVhdPath..."

        Convert-VHD -Path $tempVhdPath -DestinationPath $vhdxPath

        Set-VHD $vhdxPath -PhysicalSectorSizeBytes 4096

        Write-Host "Removing $sourceVdi..."

        Remove-Item $sourceVdi

        Write-Host "Removing $tempVhdPath..."

        Remove-Item $tempVhdPath
    }
 }
```

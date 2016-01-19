# Azure Virtual Machines

Friday, June 05, 2015
5:26 AM

# Manage Azure virtual machines

## # Start VMs - sync

```PowerShell
Add-AzureAccount

Get-AzureVM -ServiceName fab-adfs | Start-AzureVM

Get-AzureVM -ServiceName fab-ex | Start-AzureVM

Get-AzureVM -ServiceName fab-wap | Start-AzureVM

Get-AzureVM -ServiceName ext-foobar5 | Start-AzureVM

Get-AzureVM -ServiceName ext-foobar6 | Start-AzureVM
```

## # Start VMs - async

```PowerShell
Add-AzureAccount

Start-Job -ScriptBlock { Get-AzureVM -ServiceName fab-adfs | Start-AzureVM }

Start-Job -ScriptBlock { Get-AzureVM -ServiceName fab-ex | Start-AzureVM }

Start-Job -ScriptBlock { Get-AzureVM -ServiceName fab-wap | Start-AzureVM }

Start-Job -ScriptBlock { Get-AzureVM -ServiceName ext-foobar5 | Start-AzureVM }

Start-Job -ScriptBlock { Get-AzureVM -ServiceName ext-foobar6 | Start-AzureVM }
```

## # Stop VMs - async

```PowerShell
Add-AzureAccount

Start-Job -ScriptBlock { Get-AzureVM -ServiceName fab-adfs | Stop-AzureVM -Force }

Start-Job -ScriptBlock { Get-AzureVM -ServiceName fab-ex | Stop-AzureVM -Force }

Start-Job -ScriptBlock { Get-AzureVM -ServiceName fab-wap | Stop-AzureVM -Force }

Start-Job -ScriptBlock { Get-AzureVM -ServiceName ext-foobar5 | Stop-AzureVM -Force }

Start-Job -ScriptBlock { Get-AzureVM -ServiceName ext-foobar6 | Stop-AzureVM -Force }
```

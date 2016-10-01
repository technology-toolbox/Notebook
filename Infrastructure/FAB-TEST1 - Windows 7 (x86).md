# FAB-TEST1 - Windows 7 (x86)

Tuesday, May 12, 2015
6:28 PM

```PowerShell
cls
```

## # Enable PowerShell remoting

```PowerShell
Enable-PSRemoting -Confirm:$false
```

## # Enable firewall rules for inbound "ping" requests (required for POSHPAIG)

```PowerShell
# Note: Enable-NetFirewallRule is not available on Windows 7

netsh advfirewall firewall set rule `
    name="File and Printer Sharing (Echo Request - ICMPv4-In)" `
    profile="domain" new enable=yes

netsh advfirewall firewall set rule `
    name="File and Printer Sharing (Echo Request - ICMPv6-In)" `
    profile="domain" new enable=yes
```

## # Configure firewall rule for POSHPAIG (http://poshpaig.codeplex.com/)

```PowerShell
# Note: New-NetFirewallRule is not available on Windows 7

netsh advfirewall firewall add rule `
    name="Remote Windows Update (Dynamic RPC)" `
    description="Allows remote auditing and installation of Windows updates via POSHPAIG (http://poshpaig.codeplex.com/)" `
    program="%windir%\system32\dllhost.exe" `
    dir=in `
    protocol=TCP `
    localport=RPC `
    profile=Domain `
    action=Allow
```

## Baseline

Windows 7\
Microsoft Office Professional Plus 2010\
Remote Server Administration Tools for Windows 7 SP1\
Disk Cleanup

#192.168.10.212	fab-foobar2 client-local.securitasinc.com cloud-local.securitasinc.com extranet-local.fabrikam.com\
#192.168.10.214	fab-foobar4 client-local.securitasinc.com cloud-local.securitasinc.com extranet-local.fabrikam.com\
10.71.4.100	ext-foobar6 ext-foobar6.extranet.technologytoolbox.com client-local.securitasinc.com cloud-local.securitasinc.com media-local.securitasinc.com portal-local.securitasinc.com\
#10.71.2.5	fs.fabrikam.com mail.fabrikam.com

## Issue - IPv6 address range changed by Comcast

### # Update IPv6 DNS servers

```PowerShell
$interfaceAlias = "Local Area Connection"
```

# **Note:** Set-DNSClientServerAddress is not available on Windows 7

```Console
netsh interface ipv6 set dnsserver name=$interfaceAlias source=static address=2603:300b:802:8900::201

netsh interface ipv6 add dnsserver name=$interfaceAlias address=2603:300b:802:8900::202
```

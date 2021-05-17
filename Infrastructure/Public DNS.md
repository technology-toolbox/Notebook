# Public DNS

Monday, May 17, 2021\
10:13 AM

```PowerShell
cls
```

## # Migrate DNS records from register.com to Azure DNS

### # Create "A" records

```PowerShell
New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name '@' -RecordType A -Ttl 3600 `
  -DnsRecords (New-AzDnsRecordConfig -Ipv4Address 40.122.160.156) |
  Out-Null
```

```PowerShell
cls
```

### # Create "MX" records

```PowerShell
New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name '@' -RecordType MX -Ttl 3600 `
  -DnsRecords (
    New-AzDnsRecordConfig `
      -Exchange 'technologytoolbox-com.mail.protection.outlook.com' `
      -Preference 0) |
  Out-Null

New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName teams.technologytoolbox.com `
  -Name '@' -RecordType MX -Ttl 3600 `
  -DnsRecords (
    New-AzDnsRecordConfig `
      -Exchange 'teams-technologytoolbox-com.mail.protection.outlook.com' `
      -Preference 0) |
  Out-Null
```

```PowerShell
cls
```

### # Create "CNAME" records

```PowerShell
New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name '1927534' -RecordType CNAME -Ttl 3600 `
  -DnsRecords (New-AzDnsRecordConfig -Cname 'sendgrid.net.') |
  Out-Null

New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name 'assets' -RecordType CNAME -Ttl 3600 `
  -DnsRecords (New-AzDnsRecordConfig -Cname 'metatropi-01.azureedge.net.') |
  Out-Null

New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name 'autodiscover' -RecordType CNAME -Ttl 3600 `
  -DnsRecords (New-AzDnsRecordConfig -Cname 'autodiscover.outlook.com.') |
  Out-Null

New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName teams.technologytoolbox.com `
  -Name 'autodiscover' -RecordType CNAME -Ttl 3600 `
  -DnsRecords (New-AzDnsRecordConfig -Cname 'autodiscover.outlook.com.') |
  Out-Null

New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name 'awverify' -RecordType CNAME -Ttl 3600 `
  -DnsRecords (
    New-AzDnsRecordConfig -Cname 'awverify.techtoolbox.azurewebsites.net.') |
  Out-Null

New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name 'awverify.www' -RecordType CNAME -Ttl 3600 `
  -DnsRecords (
    New-AzDnsRecordConfig -Cname 'awverify.techtoolbox.azurewebsites.net.') |
  Out-Null

New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name 'commento' -RecordType CNAME -Ttl 3600 `
  -DnsRecords (
    New-AzDnsRecordConfig -Cname 'techtoolbox-commento.azurewebsites.net.') |
  Out-Null

New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name 'em191' -RecordType CNAME -Ttl 3600 `
  -DnsRecords (New-AzDnsRecordConfig -Cname 'u21544276.wl027.sendgrid.net.') |
  Out-Null

New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name 'em9248' -RecordType CNAME -Ttl 3600 `
  -DnsRecords (New-AzDnsRecordConfig -Cname 'u1927534.wl035.sendgrid.net.') |
  Out-Null

New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name 'enterpriseenrollment' -RecordType CNAME -Ttl 3600 `
  -DnsRecords (
    New-AzDnsRecordConfig -Cname 'enterpriseenrollment.manage.microsoft.com.') |
  Out-Null

New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name 'enterpriseregistration' -RecordType CNAME -Ttl 3600 `
  -DnsRecords (
    New-AzDnsRecordConfig -Cname 'enterpriseregistration.windows.net.') |
  Out-Null

New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name 'lyncdiscover' -RecordType CNAME -Ttl 3600 `
  -DnsRecords (New-AzDnsRecordConfig -Cname 'webdir.online.lync.com.') |
  Out-Null

New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name 'msoid' -RecordType CNAME -Ttl 3600 `
  -DnsRecords (
    New-AzDnsRecordConfig -Cname 'clientconfig.microsoftonline-p.net.') |
  Out-Null

New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name 'pgadmin4' -RecordType CNAME -Ttl 3600 `
  -DnsRecords (
    New-AzDnsRecordConfig -Cname 'techtoolbox-pgadmin4.azurewebsites.net.') |
  Out-Null

New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name 's1._domainkey' -RecordType CNAME -Ttl 3600 `
  -DnsRecords (
    New-AzDnsRecordConfig -Cname 's1.domainkey.u21544276.wl027.sendgrid.net.') |
  Out-Null

New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name 's2._domainkey' -RecordType CNAME -Ttl 3600 `
  -DnsRecords (
    New-AzDnsRecordConfig -Cname 's2.domainkey.u21544276.wl027.sendgrid.net.') |
  Out-Null

New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name 'saz._domainkey' -RecordType CNAME -Ttl 3600 `
  -DnsRecords (
    New-AzDnsRecordConfig -Cname 'saz.domainkey.u1927534.wl035.sendgrid.net.') |
  Out-Null

New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name 'saz2._domainkey' -RecordType CNAME -Ttl 3600 `
  -DnsRecords (
    New-AzDnsRecordConfig -Cname 'saz2.domainkey.u1927534.wl035.sendgrid.net.') |
  Out-Null

New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name 'selector1._domainkey' -RecordType CNAME -Ttl 3600 `
  -DnsRecords (
    New-AzDnsRecordConfig `
      -Cname ('selector1-technologytoolbox-com._domainkey' `
        + '.techtoolbox.onmicrosoft.com.')) |
  Out-Null

New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name 'selector2._domainkey' -RecordType CNAME -Ttl 3600 `
  -DnsRecords (
    New-AzDnsRecordConfig `
      -Cname ('selector2-technologytoolbox-com._domainkey' `
        + '.techtoolbox.onmicrosoft.com.')) |
  Out-Null

New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name 'sip' -RecordType CNAME -Ttl 3600 `
  -DnsRecords (New-AzDnsRecordConfig -Cname 'sipdir.online.lync.com.') |
  Out-Null

New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name 'url665' -RecordType CNAME -Ttl 3600 `
  -DnsRecords (New-AzDnsRecordConfig -Cname 'sendgrid.net.') |
  Out-Null

New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name 'www' -RecordType CNAME -Ttl 3600 `
  -DnsRecords (
    New-AzDnsRecordConfig -Cname 'nice-wave-0f7d7c51e.azurestaticapps.net.') |
  Out-Null
```

```PowerShell
cls
```

### # Create "TXT" records

```PowerShell
New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name '@' -RecordType TXT -Ttl 7200 `
  -DnsRecords (
    New-AzDnsRecordConfig `
      -Value 'v=spf1 include:spf.protection.outlook.com -all') |
  Out-Null

Get-AzDnsRecordSet `
  -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name '@' -RecordType TXT |
  Add-AzDnsRecordConfig `
    -Value 'google-site-verification=LzQJ4C7DVBHccHu-iktJPvVPxqiyChEJaB_nf3XXQiI' |
  Set-AzDnsRecordSet |
  Out-Null

Get-AzDnsRecordSet `
  -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name '@' -RecordType TXT |
  Add-AzDnsRecordConfig `
    -Value 'google-site-verification=RCaci3p1mj1fzyNvq1LhBaDh2pbF43ydBgR6nRpt5eE' |
  Set-AzDnsRecordSet |
  Out-Null

New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name '_acme-challenge.darkstat.corp' -RecordType TXT -Ttl 7200 `
  -DnsRecords (
    New-AzDnsRecordConfig -Value 'g0iBAH4EmddxxRwwUlFSPLNXiIfFndEpGjC4FlfBiE8') |
  Out-Null

New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name '_acme-challenge.fw01.corp' -RecordType TXT -Ttl 7200 `
  -DnsRecords (
    New-AzDnsRecordConfig -Value 'hT27YolJPgTOEtr0D5Xym3LXprWVb9qbxI27pEHyTj0') |
  Out-Null

New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name '_acme-challenge.k8s-01.corp' -RecordType TXT -Ttl 7200 `
  -DnsRecords (
    New-AzDnsRecordConfig -Value '8YUvR9gffXbguCk1_at7fjwvBp9I-9SHUV1JRcIgtqA') |
  Out-Null

New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name '_acme-challenge.sw01.corp' -RecordType TXT -Ttl 7200 `
  -DnsRecords (
    New-AzDnsRecordConfig -Value 'gaR8wTg2ckiloj27C2NUGWQL7LUswquchv3u3J-LKS8') |
  Out-Null

New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name '_dmarc' -RecordType TXT -Ttl 7200 `
  -DnsRecords (
    New-AzDnsRecordConfig `
      -Value ('v=DMARC1; p=quarantine; sp=reject; pct=100;' `
        + ' rua=mailto:dmarc-rua@technologytoolbox.com;' `
        + ' ruf=mailto:dmarc-ruf@technologytoolbox.com; fo=1')) |
  Out-Null

New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name '_github-challenge-technology-toolbox' -RecordType TXT -Ttl 7200 `
  -DnsRecords (New-AzDnsRecordConfig -Value '689bf4d1ac') |
  Out-Null

New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name 'asuid.commento' -RecordType TXT -Ttl 7200 `
  -DnsRecords (
    New-AzDnsRecordConfig -Value `
      '3F25BE394868A4C8283C89DDB11BF3D777D5F22F0B95EC19706468F25CD10873') |
  Out-Null

New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name 'asuid.pgadmin4' -RecordType TXT -Ttl 7200 `
  -DnsRecords (
    New-AzDnsRecordConfig -Value `
      '3F25BE394868A4C8283C89DDB11BF3D777D5F22F0B95EC19706468F25CD10873') |
  Out-Null

New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name 'teams' -RecordType TXT -Ttl 7200 `
  -DnsRecords (
    New-AzDnsRecordConfig `
      -Value 'v=spf1 include:spf.protection.outlook.com -all') |
  Out-Null
```

```PowerShell
cls
```

### # Create "SRV" records

```PowerShell
New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name _sip._tls -RecordType SRV -Ttl 3600 `
  -DnsRecords (
    New-AzDnsRecordConfig -Priority 0 -Weight 1 -Port 443 `
      -Target 'sipdir.online.lync.com.') |
  Out-Null

New-AzDnsRecordSet -ResourceGroupName 'Zeus-02-test' `
  -ZoneName technologytoolbox.com `
  -Name _sipfederationtls._tcp -RecordType SRV -Ttl 3600 `
  -DnsRecords (
    New-AzDnsRecordConfig -Priority 0 -Weight 1 -Port 5061 `
      -Target 'sipfed.online.lync.com.') |
  Out-Null
```

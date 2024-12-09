# IPMI Configuration

Thursday, April 5, 2018\
5:41 PM

| Server | Motherboard S/N | BMC MAC Address | Switch Port | IP Address | URL |
| --- | --- | --- | --- | --- | --- |
| TT-HV05A | NM163S000843 | 0C:C4:7A:AE:F2:24 | 7 | 10.1.14.2 | [https://ipmi-nm163s000843](https://ipmi-nm163s000843) |
| TT-HV05B | NM169S003213 | 0C:C4:7A:DD:62:89 | 8 | 10.1.14.3 | [https://ipmi-nm169s003213](https://ipmi-nm169s003213) |
| TT-HV05C | NM15CS027344 | 0C:C4:7A:AE:52:90 | 9 | 10.1.14.4 | [https://ipmi-nm15cs027344](https://ipmi-nm15cs027344) |
| TT-NAS02 | NM177S506675 | AC:1F:6B:49:CF:B7 | 10 | 10.1.14.5 | [https://ipmi-nm177s506675](https://ipmi-nm177s506675) |

```PowerShell
Function CreateSelfSignedCertificate([string] $ServerName, [switch] $ImportCertificate)
{
    $openSsl = "C:\NotBackedUp\Public\Toolbox\OpenSSL-Win64\bin\openssl.exe"

    $content = @"
[req]
 default_bits = 2048
 default_md = sha256
 distinguished_name = req_distinguished_name
 prompt = no
 x509_extensions = v3_req

[req_distinguished_name]
 countryName = US
 stateOrProvinceName = Colorado
 localityName = Parker
 0.organizationName = Technology Toolbox
 organizationalUnitName = IT
 commonName = $serverName.corp.technologytoolbox.com
 emailAddress = admin@technologytoolbox.com

[v3_req]
 keyUsage = digitalSignature, keyEncipherment
 extendedKeyUsage = serverAuth
 subjectAltName = @alt_names

[alt_names]
 DNS.1 = $serverName
 DNS.2 = $serverName.corp.technologytoolbox.com
"@

    $configFile = "$ServerName.cfg"

    Set-Content -Value $content -Path $configFile

    $keyFile = "$ServerName-key.pem"
    $certFile = "$ServerName-cert.pem"

    #& $openssl genrsa -out $keyFile 2048

    #& $openssl req -config $configFile -out "$ServerName.csr" -key $keyFile

    & $openssl req -new -x509 -newkey rsa:2048 -nodes -keyout $keyFile -out $certFile -days 1825 -config $configFile

    If ($ImportCertificate)
    {
        Import-Certificate `
            -FilePath $certFile `
            -CertStoreLocation Cert:\CurrentUser\Root
    }
}

$serialNumbers = ("NM163S000843", "NM169S003213", "NM15CS027344", "NM177S506675")

$serialNumbers |
    foreach {
        $serialNumber = $_

        $serverName = "ipmi-" + $serialNumber.ToLower()

        CreateSelfSignedCertificate -ServerName $serverName -ImportCertificate
    }
```

---

**FOOBAR11** - Run as administrator

```PowerShell
cls
```

## # Create internal DNS records

```PowerShell
Add-DnsServerResourceRecordA `
    -ComputerName TT-DC06 `
    -Name "ipmi-nm163s000843" `
    -IPv4Address 10.1.14.2 `
    -ZoneName "corp.technologytoolbox.com"

Add-DnsServerResourceRecordA `
    -ComputerName TT-DC06 `
    -Name "ipmi-nm169s003213" `
    -IPv4Address 10.1.14.3 `
    -ZoneName "corp.technologytoolbox.com"

Add-DnsServerResourceRecordA `
    -ComputerName TT-DC06 `
    -Name "ipmi-nm15cs027344" `
    -IPv4Address 10.1.14.4 `
    -ZoneName "corp.technologytoolbox.com"

Add-DnsServerResourceRecordA `
    -ComputerName TT-DC06 `
    -Name "ipmi-nm177s506675" `
    -IPv4Address 10.1.14.5 `
    -ZoneName "corp.technologytoolbox.com"
```

---

## References

**Installing a custom SSL certificate**\
From <[https://michael.stapelberg.de/posts/2014-01-11-building_supermicro_1u_server/](https://michael.stapelberg.de/posts/2014-01-11-building_supermicro_1u_server/)>

**SSL certificate chains, intermediate certs**\
From <[https://www.osso.nl/blog/fixing-ssl-certificate-chains-and-verify-they-work-properly/](https://www.osso.nl/blog/fixing-ssl-certificate-chains-and-verify-they-work-properly/)>

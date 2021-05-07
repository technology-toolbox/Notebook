# pfSense Firewall

Tuesday, September 12, 2017\
4:15 PM

## Decrypt configuration file

Reference:

<[https://docs.netgate.com/pfsense/en/latest/backup/restore.html#encrypted-configuration-files](https://docs.netgate.com/pfsense/en/latest/backup/restore.html#encrypted-configuration-files)>

### 2.5.0 and later

```Shell
grep -v "config.xml" "C:\Users\jjameson\Downloads\config.xml" | base64 -d | \
  openssl enc -d -aes-256-cbc -salt -md sha256 -pbkdf2 \
    -out config-decrypted.xml -pass pass:{password}
```

### Older versions

```Shell
grep -v "config.xml" "C:\Users\jjameson\Downloads\config.xml" | base64 -d | \
  openssl enc -d -aes-256-cbc -salt -md md5 -out config-decrypted.xml \
    -pass pass:{password}
```

## pfSense References

**TCP Flag Definitions**\
From <[https://www.netgate.com/docs/pfsense/firewall/tcp-flag-definitions.html](https://www.netgate.com/docs/pfsense/firewall/tcp-flag-definitions.html)>

**GUIDE: How To Traffic Shape With pfSense**\
From <[https://lime-technology.com/forums/topic/56426-guide-how-to-traffic-shape-with-pfsense/](https://lime-technology.com/forums/topic/56426-guide-how-to-traffic-shape-with-pfsense/)>

**pfSense: share bandwidth evenly - traffic limiter guide**\
From <[https://imgur.com/a/WR3DN](https://imgur.com/a/WR3DN)>

**Per IP traffic shaping-share bandwith evenly between IP addresses??**\
From <[https://forum.netgate.com/topic/57476/per-ip-traffic-shaping-share-bandwith-evenly-between-ip-addresses/2](https://forum.netgate.com/topic/57476/per-ip-traffic-shaping-share-bandwith-evenly-between-ip-addresses/2)>

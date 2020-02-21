# pfSense Firewall

Tuesday, September 12, 2017
4:15 PM

## Decrypt configuration file

```Shell
cat /tmp/config.xml | sed -e '1d' -e '$d' | base64 -d | openssl enc -d -aes-256-cbc -out config-decrypted.xml -k '{password}'
```

From <[https://forum.pfsense.org/index.php?topic=111080.msg621529#msg621529](https://forum.pfsense.org/index.php?topic=111080.msg621529#msg621529)>

```Console
cat "C:\Users\jjameson\Downloads\config.xml"  | sed -e '1d' -e '$d' | base64 -d | openssl enc -d -aes-256-cbc -out config.xml -k '{password}'



cls; ipconfig /release; ipconfig /release6; ipconfig /renew; ipconfig /renew6; ipconfig /all
```

## References

**TCP Flag Definitions**\
From <[https://www.netgate.com/docs/pfsense/firewall/tcp-flag-definitions.html](https://www.netgate.com/docs/pfsense/firewall/tcp-flag-definitions.html)>

**GUIDE: How To Traffic Shape With pfSense**\
From <[https://lime-technology.com/forums/topic/56426-guide-how-to-traffic-shape-with-pfsense/](https://lime-technology.com/forums/topic/56426-guide-how-to-traffic-shape-with-pfsense/)>

**pfSense: share bandwidth evenly - traffic limiter guide**\
From <[https://imgur.com/a/WR3DN](https://imgur.com/a/WR3DN)>

**Per IP traffic shaping-share bandwith evenly between IP addresses??**\
From <[https://forum.netgate.com/topic/57476/per-ip-traffic-shaping-share-bandwith-evenly-between-ip-addresses/2](https://forum.netgate.com/topic/57476/per-ip-traffic-shaping-share-bandwith-evenly-between-ip-addresses/2)>

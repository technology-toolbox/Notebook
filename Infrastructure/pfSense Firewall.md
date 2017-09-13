# pfSense Firewall

Tuesday, September 12, 2017
4:15 PM

## Decrypt configuration file

```Shell
cat /tmp/config.xml | sed -e '1d' -e '$d' | base64 -d | openssl enc -d -aes-256-cbc -out config-decrypted.xml -k '{password}'
```

From <[https://forum.pfsense.org/index.php?topic=111080.msg621529#msg621529](https://forum.pfsense.org/index.php?topic=111080.msg621529#msg621529)>

# Contoso IPv6 Configuration

Monday, August 20, 2018
10:12 AM

## System / Advanced / Networking

DHCP6 DUID: DUID-LLT\
DUID-LLT: 588069632\
Link-layer address: 00:30:bd:1e:3b:c7

```XML
        <global-v6duid>0e:00:00:00:00:01:23:0d:3b:00:00:30:bd:1e:3b:c7</global-v6duid>
```

## Interfaces / WAN

IPv6 Configuration Type: DHCP6\
DHCP6 Prefix Delegation size: 60\
Send IPv6 prefix hint: Yes (checked)

```XML
        <wan>
...
            <dhcp6-ia-pd-len>4</dhcp6-ia-pd-len>
            <dhcp6-ia-pd-send-hint></dhcp6-ia-pd-send-hint>
...
        </wan>
```

## Interfaces / CON60

IPv6 Configuration Type: Track Interface\
IPv6 Interface: WAN\
IPv6 Prefix ID: f

```XML
        <opt10>
...
            <ipaddrv6>track6</ipaddrv6>
            <track6-interface>wan</track6-interface>
            <track6-prefix-id>15</track6-prefix-id>
        </opt10>
```

## Services / DHCPv6 Server & RA / CON60 / DHCPv6 Server

Enable DHCPv6 server on interface CON60: Yes (checked)\
Range: From ::1000 To ::2000\
Prefix Delegation Size: 64

## Services / DHCPv6 Server & RA / CON60 / Router Advertisements

Router mode: Assisted - RA Flags [managed, other stateful], Prefix Flags [onlink, auto, router]\
Router priority: Normal

```XML
        <opt10>
            <ramode>assist</ramode>
            <rapriority>medium</rapriority>
            <rainterface></rainterface>
            <ravalidlifetime></ravalidlifetime>
            <rapreferredlifetime></rapreferredlifetime>
            <raminrtradvinterval></raminrtradvinterval>
            <ramaxrtradvinterval></ramaxrtradvinterval>
            <raadvdefaultlifetime></raadvdefaultlifetime>
            <radomainsearchlist></radomainsearchlist>
            <range>
                <from>::1000</from>
                <to>::2000</to>
            </range>
            <prefixrange>
                <from></from>
                <to></to>
                <prefixlength>64</prefixlength>
            </prefixrange>
            <defaultleasetime></defaultleasetime>
            <maxleasetime></maxleasetime>
            <netmask></netmask>
            <domain></domain>
            <domainsearchlist></domainsearchlist>
            <enable></enable>
            <ddnsdomain></ddnsdomain>
            <ddnsdomainprimary></ddnsdomainprimary>
            <ddnsdomainkeyname></ddnsdomainkeyname>
            <ddnsdomainkeyalgorithm>hmac-md5</ddnsdomainkeyalgorithm>
            <ddnsdomainkey></ddnsdomainkey>
            <ddnsclientupdates>allow</ddnsclientupdates>
            <tftp></tftp>
            <ldap></ldap>
            <bootfile_url></bootfile_url>
            <dhcpv6leaseinlocaltime></dhcpv6leaseinlocaltime>
            <numberoptions></numberoptions>
        </opt10>









        <rule>
            <id></id>
            <tracker>1534679559</tracker>
            <type>block</type>
            <interface>wan</interface>
            <ipprotocol>inet46</ipprotocol>
            <tag></tag>
            <tagged></tagged>
            <max></max>
            <max-src-nodes></max-src-nodes>
            <max-src-conn></max-src-conn>
            <max-src-states></max-src-states>
            <statetimeout></statetimeout>
            <statetype><![CDATA[keep state]]></statetype>
            <os></os>
            <protocol>udp</protocol>
            <source>
                <network>wan</network>
            </source>
            <destination>
                <any></any>
                <port>1900</port>
            </destination>
            <descr><![CDATA[Block SSDP (UPnP discovery)]]></descr>
            <created>
                <time>1534679559</time>
                <username>admin@192.168.10.84</username>
            </created>
            <updated>
                <time>1534679575</time>
                <username>admin@192.168.10.84</username>
            </updated>
        </rule>
```

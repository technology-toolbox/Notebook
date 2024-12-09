# Netgear GS724T v4 (192.168.10.239)

Monday, April 4, 2016\
5:30 AM

## Change administrator password

## Configure static IP address

1. Select the **System** tab, and then, if necessary, select the **Management **feature.
2. Select **IP Configuration**.
3. On the **IPv4 Network Interface Configuration** page:
   1. In the **IP Address** box, type **192.168.10.239**.
   2. In the **Subnet Mask** box, type **255.255.255.0**.
   3. In the **Default Gateway** box, type **192.168.10.1**.
   4. Click **Apply**.

## Enable jumbo frames

1. Select the **Switching** tab, and then, if necessary, select the **Ports** feature.
2. On the **Port Configuration** page, set the **Maximum Frame Size** for all ports to **9216** and click **Apply**.

## Configure Network Time Protocol (NTP)

1. Select the **System ? Management ? Time ? Time Configuration**.
2. On the **Time Configuration** page:
   1. In the **Time Configuration** section, for the **Clock Source **option, select **SNTP**.
   2. In the **SNTP Global Configuration** section, for the **Client Mode **option, select **Unicast**.
   3. Click **Apply**.
3. Select the **System ? Management ? Time ? SNTP Server Configuration**.
4. On the **SNTP Server Configuration** page:
   1. In the **Server Type** dropdown list, select **IPv4**.
   2. In the **Address** box, type **192.168.10.103**.
   3. In the **Port** box, ensure **123** is specified.
   4. In the **Priority** box, ensure **1** is specified.
   5. Click **Add**.
   6. In the **Address** box, type **192.168.10.104**.
   7. In the **Port** box, ensure **123** is specified.
   8. In the **Priority** box, type **2**.
   9. Click **Add**.

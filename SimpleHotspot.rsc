/interface ethernet set [ find default-name=ether2 ] master-port=ether5
/interface ethernet set [ find default-name=ether3 ] master-port=ether5
/interface ethernet set [ find default-name=ether4 ] master-port=ether5
/ip hotspot profile add dns-name=gateway.router hotspot-address=192.168.0.1/24 name=hsprof1
/ip pool add name=dhcp_pool1 ranges=192.168.0.10-192.168.0.200
/ip dhcp-server add address-pool=dhcp_pool1 disabled=no interface=ether5 lease-time=1h name=dhcp1
/ip hotspot add address-pool=dhcp_pool1 disabled=no idle-timeout=1h interface=ether5 name=hotspot1 profile=hsprof1
/ip hotspot user profile set [ find default=yes ] address-pool=dhcp_pool1
/tool user-manager customer set admin access=own-routers,own-users,own-profiles,own-limits,config-payment-gw
/ip address add address=192.168.0.1/24 interface=ether5 network=192.168.0.0
/ip dhcp-client add default-route-distance=0 dhcp-options=hostname,clientid disabled=no interface=ether1
/ip dhcp-client add add-default-route=no dhcp-options=hostname,clientid disabled=no interface=lte1 use-peer-dns=no use-peer-ntp=no
/ip dhcp-server network add address=192.168.0.0/24 dns-server=192.168.0.1 domain=router gateway=192.168.0.1 netmask=24 ntp-server=192.168.0.1
/ip dns set allow-remote-requests=yes servers=192.168.0.1
/ip firewall filter
  add action=passthrough chain=unused-hs-chain comment="place hotspot rules here" disabled=yes
  add chain=input comment="accept established connection packets" connection-state=established
  add chain=input comment="accept related connection packets" connection-state=related
  add action=drop chain=input comment="drop invalid packets" connection-state=invalid
  add action=drop chain=input comment="detect and drop port scan connections" protocol=tcp psd=21,3s,3,1
  add action=tarpit chain=input comment="suppress DoS attack" connection-limit=3,32 protocol=tcp src-address-list=black_list
  add action=add-src-to-address-list address-list=black_list address-list-timeout=1d chain=input comment="detect DoS attack" connection-limit=10,32 protocol=tcp
  add action=jump chain=input comment="jump to chain ICMP" jump-target=ICMP protocol=icmp
  add action=drop chain=input comment="drop ftp brute forcers" dst-port=21 protocol=tcp src-address-list=ftp_blacklist
  add chain=output content="530 Login incorrect" dst-limit=1/1m,9,dst-address/1m protocol=tcp
  add action=add-dst-to-address-list address-list=ftp_blacklist address-list-timeout=3h chain=output content="530 Login incorrect" protocol=tcp
  add action=drop chain=input comment="drop ssh brute forcers" dst-port=22 protocol=tcp src-address-list=ssh_blacklist
  add action=add-src-to-address-list address-list=ssh_blacklist address-list-timeout=1w3d chain=input connection-state=new dst-port=22 protocol=tcp src-address-list=ssh_stage3
  add action=add-src-to-address-list address-list=ssh_stage3 address-list-timeout=1m chain=input connection-state=new dst-port=22 protocol=tcp src-address-list=ssh_stage2
  add action=add-src-to-address-list address-list=ssh_stage2 address-list-timeout=1m chain=input connection-state=new dst-port=22 protocol=tcp src-address-list=ssh_stage1
  add action=add-src-to-address-list address-list=ssh_stage1 address-list-timeout=1m chain=input connection-state=new dst-port=22 protocol=tcp
  add chain=input comment="limited dns" disabled=yes dst-port=53 limit=2400/1m,5 protocol=udp
  add chain=input comment="allowed dns" disabled=yes dst-port=53 protocol=udp
  add action=jump chain=input comment="jump to chain services" jump-target=services
  add chain=input comment="Allow Broadcast Traffic" disabled=yes dst-address-type=broadcast
  add action=log chain=input disabled=yes log-prefix=Filter:
  add action=drop chain=input comment="drop everything else"
  add chain=ICMP comment="0:0 and limit for 5pac/s" icmp-options=0 limit=5,5 protocol=icmp
  add chain=ICMP comment="3:3 and limit for 5pac/s" icmp-options=3:3 limit=5,5 protocol=icmp
  add chain=ICMP comment="3:4 and limit for 5pac/s" icmp-options=3:4 limit=5,5 protocol=icmp
  add chain=ICMP comment="8:0 and limit for 5pac/s" icmp-options=8 limit=5,5 protocol=icmp
  add chain=ICMP comment="11:0 and limit for 5pac/s" icmp-options=11 limit=5,5 protocol=icmp
  add action=drop chain=ICMP comment="Drop everything else" protocol=icmp
  add chain=services comment="accept localhost" dst-address=127.0.0.1 src-address-list=127.0.0.1
  add chain=services comment="allow IPIP" disabled=yes protocol=ipencap
  add chain=services comment="allow PPTP and EoIP" protocol=gre
  add chain=services comment="allow IPSec" disabled=yes protocol=ipsec-esp
  add chain=services comment="allow IPSec" disabled=yes protocol=ipsec-ah
  add chain=services comment="allow OSPF" disabled=yes protocol=ospf
  add chain=services comment="allow SSH request" disabled=yes dst-port=22 protocol=tcp
  add chain=services comment="allow DNS request" disabled=yes dst-port=53 protocol=tcp
  add chain=services comment="Allow DNS request" dst-port=53 protocol=udp
  add chain=services comment="Allow DNS request" protocol=udp src-port=53
  add chain=services comment="allow DHCP" disabled=yes dst-port=67-68 protocol=udp
  add chain=services comment="Allow NTP" dst-port=123 protocol=udp
  add chain=services comment="Allow NTP" protocol=udp src-port=123
  add chain=services comment="allow SNMP" disabled=yes dst-port=161 protocol=tcp
  add chain=services comment="Allow BGP" disabled=yes dst-port=179 protocol=tcp
  add chain=services comment="allow https for Hotspot" disabled=yes dst-port=443 protocol=tcp
  add chain=services comment="allow IPSec connections" disabled=yes dst-port=500 protocol=udp
  add chain=services comment="allow Socks for Hotspot" disabled=yes dst-port=1080 protocol=tcp
  add chain=services comment="Allow PPTP" dst-port=1723 protocol=tcp
  add chain=services comment=UPnP disabled=yes dst-port=1900 protocol=udp
  add chain=services comment="Bandwidth server" disabled=yes dst-port=2000 protocol=tcp
  add chain=services comment=UPnP disabled=yes dst-port=2828 protocol=tcp
  add chain=services comment="allow BGP" disabled=yes dst-port=5000-5100 protocol=udp
  add chain=services comment=" MT Discovery Protocol" disabled=yes dst-port=5678 protocol=udp
  add chain=services comment="allow Web Proxy" disabled=yes dst-port=8080 protocol=tcp
  add chain=services comment="allow RIP" disabled=yes dst-port=520-521 protocol=udp
  add chain=services comment="allow DNS request" in-interface=ether5 protocol=tcp
  add chain=services comment="allow MACwinbox " in-interface=ether5 protocol=udp
  add action=return chain=services
/ip firewall nat
  add action=passthrough chain=unused-hs-chain comment="place hotspot rules here" disabled=yes
  add action=masquerade chain=srcnat out-interface=ether1
  add action=masquerade chain=srcnat out-interface=lte1
  add action=masquerade chain=srcnat comment="masquerade hotspot network" src-address=10.10.10.0/24
/ip firewall service-port
  set tftp disabled=yes
  set irc disabled=yes
  set h323 disabled=yes
  set sip disabled=yes
/ip hotspot user add name=admin password=Passw0rd
/ip hotspot walled-garden add comment="place hotspot rules here" disabled=yes
/ip route add distance=1 gateway=192.168.9.1 routing-mark=lte
/system clock set time-zone-name=Europe/Amsterdam
/system lcd set contrast=0 enabled=no port=parallel type=24x4
/system lcd page
  set time disabled=yes display-time=5s
  set resources disabled=yes display-time=5s
  set uptime disabled=yes display-time=5s
  set packets disabled=yes display-time=5s
  set bits disabled=yes display-time=5s
  set version disabled=yes display-time=5s
  set identity disabled=yes display-time=5s
  set ether1 disabled=yes display-time=5s
  set ether2 disabled=yes display-time=5s
  set ether3 disabled=yes display-time=5s
  set ether4 disabled=yes display-time=5s
  set ether5 disabled=yes display-time=5s
  set lte1 disabled=yes display-time=5s
/system ntp client
set enabled=yes primary-ntp=146.231.129.86 secondary-ntp=196.25.1.9

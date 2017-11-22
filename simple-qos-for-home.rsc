#Set bandwidth of the interface
:local interfaceBandwidth 100M

# delete old generated rules
/ip firewall address-list remove [/ip firewall address-list find comment~"QOS generator"] 
/ip firewall mangle remove [/ip firewall mangle find comment~"QOS generator"] 
/queue tree remove [/queue tree find comment~"QOS generator"] 

# address-lists
:for i from=1 to=10 do={/ip firewall address-list add list=WoT address=("login.p"."$i".".worldoftanks.net") comment="QOS generator: WoT"}

#
/ip firewall mangle
# prio_1
    add chain=prerouting action=mark-packet new-packet-mark=prio_1 protocol=icmp comment="QOS generator: ping"
    add chain=prerouting action=mark-packet new-packet-mark=prio_1 protocol=tcp port=53 comment="QOS generator: tcp DNS"
    add chain=prerouting action=mark-packet new-packet-mark=prio_1 protocol=udp port=53 comment="QOS generator: udp DNS"
    add chain=prerouting action=mark-packet new-packet-mark=prio_1 protocol=tcp tcp-flags=ack packet-size=0-123 comment="QOS generator: TCP ACK"
# prio_2
    add chain=prerouting action=mark-packet new-packet-mark=prio_2 dscp=40 comment="QOS generator"
    add chain=prerouting action=mark-packet new-packet-mark=prio_2 dscp=46 comment="QOS generator"
    add chain=prerouting action=mark-packet new-packet-mark=prio_2 protocol=udp port=5060,5061,10000-20000 comment="QOS generator: VoIP"
# prio_3
    add chain=prerouting action=mark-packet new-packet-mark=prio_3 protocol=tcp port=22 comment="QOS generator: SSH"
    add chain=prerouting action=mark-packet new-packet-mark=prio_3 src-address-list=WoT comment="QOS generator: WoT src"
    add chain=prerouting action=mark-packet new-packet-mark=prio_3 dst-address-list=WoT comment="QOS generator: WoT dst"
# prio_4
    add chain=prerouting action=mark-packet new-packet-mark=prio_4 protocol=tcp port=3389 comment="QOS generator: RDP"
    add chain=prerouting action=mark-packet new-packet-mark=prio_4 protocol=tcp port=80,443 comment="QOS generator: HTTP/HTTPS"

/ip firewall mangle
# prio_1
    add chain=prerouting action=set-priority new-priority=7 protocol=icmp comment="QOS generator: Wi-Fi: ping"
    add chain=prerouting action=set-priority new-priority=7 protocol=tcp port=53 comment="QOS generator: Wi-Fi: tcp DNS"
    add chain=prerouting action=set-priority new-priority=7 protocol=udp port=53 comment="QOS generator: Wi-Fi: udp DNS"
    add chain=prerouting action=set-priority new-priority=7 protocol=tcp tcp-flags=ack packet-size=0-123 comment="QOS generator"
# prio_2
    add chain=prerouting action=set-priority new-priority=6 dscp=40 comment="QOS generator: Wi-Fi: VoIP dscp 40"
    add chain=prerouting action=set-priority new-priority=6 dscp=46 comment="QOS generator: Wi-Fi: VoIP dscp 46"
    add chain=prerouting action=set-priority new-priority=6 protocol=udp port=5060,5061,10000-20000 comment="QOS generator: Wi-Fi: VoIP"
# prio_3
    add chain=prerouting action=set-priority new-priority=5 protocol=tcp port=22 comment="QOS generator: Wi-Fi: SSH"
    add chain=prerouting action=set-priority new-priority=5 src-address-list=WoT comment="QOS generator: Wi-Fi: WoT"
    add chain=prerouting action=set-priority new-priority=5 dst-address-list=WoT comment="QOS generator: Wi-Fi: WoT"
# prio_4
    add chain=prerouting action=set-priority new-priority=3 protocol=tcp port=3389 comment="QOS generator: Wi-Fi: RDP"

/queue tree add max-limit=$interfaceBandwidth name=QoS_global parent=global priority=1 comment="QOS generator: GLOBAL"
:for indexA from=1 to=4 do={
   /queue tree add \ 
      name=( "prio_" . "$indexA" ) \
      parent=QoS_global \
      priority=($indexA) \
      queue=ethernet-default \
      packet-mark=("prio_" . $indexA) \
      comment=("QOS generator")
}
/queue tree add name="prio_5_no_mark" parent=QoS_global priority=5 queue=ethernet-default \
    packet-mark=no-mark comment="QOS generator"
 

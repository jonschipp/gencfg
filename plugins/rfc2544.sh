#!/bin/bash
#
# See LICENSE for copyright information
#

rfc2544()
{

# Write configs to directory
RFCDIR=rfc2544-$(date +%s)
CRC=4
mkdir $RFCDIR

# data = rfc2544(((frame_size) - (eth_hdr + ip_hdr + udp_hdr)) - crc)
# $ echo $((64-$((14+20+8))-4))
# 18

data=( 18 82 210 466 722 978 1234 1472 )

for payload in "${data[@]}"
do

cat <<EOF | tee $RFCDIR/$(($payload+42+$CRC)).cfg

	/* RFC2544 - Frame Size: $(($payload+42)) */
{
 /* Dst Mac */
 ${1:-0xff,0xff,0xff,0xff,0xff,0xff,}
 /* Src Mac */
 ${2:-0x11,0x22,0x33,0x440,0x55,0x66,}
 /* EtherType */
 c16(0x0800),
 /* IPv4 Version, IHL, TOS */
 0b01000101, 0,
 /* IPv4 Total Len */
 c16($(($payload+20+8))),
 /* IPv4 Ident */
 drnd(2),
 /* IPv4 Flags, Frag Off */
 0b01000000, 0,
 /* IPv4 TTL */
 64,
 /* Proto UDP */
 17,
 /* IPv4 Checksum (IP header from, to) */
 csumip(14, 33),
 /* Source IP */
 ${3:-192,168,1,255,}
 /* Dest IP */
 ${4:-192,168,1,1,}
 /* UDP Source Port */
 c16(${5:-9}),
 /* UDP Dest Port */
 c16(${6:-9}),
 /* Length */
 c16($(($payload+8))),
 /* Checksum */
 c16(00),
 /* Data */
$(eval "printf ' 0xff,\n%.0s' {1..$payload}")
}

EOF
done
}


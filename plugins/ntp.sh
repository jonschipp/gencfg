#!/bin/bash
#
# See LICENSE for copyright information
#

ntp()
{
cat <<EOF
{
 /* Dst Mac */
 ${1:-0xaa,0xbb,0xcc,0xdd,0xee,0xff,}
 /* Src Mac */
 ${2:-0x11,0x22,0x33,0x440,0x55,0x66,}
 /* EtherType */
 c16(0x0800),
 /* IPv4 Version, IHL, TOS */
 0b01000101, 0,
 /* IPv4 Total Len */
 c16(36),
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
 ${3:-192,168,1,254,}
 /* Dest IP */
 ${4:-192,168,1,1,}
 /* UDP Source Port */
 c16(${5:-1123}),
 /* UDP Dest Port */
 c16(${6:-123}),
 /* Length */
 c16(16),
 /* Checksum */
 c16(00),

 /* NTP */

         /* Flags - NTPv2, Private mode */
         0b00010111,

         /* Auth, sequence - None */
	 0,

         /* Implementation - XNTPD */
         3,

         /* Request code - MON_GETLIST_1 */
         42,

         /* 4 bytes of padding */
         c32(0),
}
EOF
}

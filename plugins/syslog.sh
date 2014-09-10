#!/bin/bash
#
# See LICENSE for copyright information
#

syslog()
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
 c16(122),
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
 c16(${5:-514}),
 /* UDP Dest Port */
 c16(${6:-514}),
 /* Length */
 c16(102),
 /* Checksum */
 c16(00),

 /* Syslog - RFC5424 */

         /* PRI */
         0x3c,
         50,57,
         0x3e,

         /* Timestamp */
         /* 2013-05-13T13:30:12.12Z */
         "$(date +"%Y-%m-%dT%T.%SZ")",

         /* Host */
         0x20,
         '-',
         0x20,
         "trafgen.hostilenetwork.com",
         0x20,
         '-',
         0x20,

        /* MSG */

                /* Tag/Msg Data - RFC3164 */
                "trafgen/PID:0101",
                0x20,
                '-',
                0x20,

                /* Content */
                "Syslog Stresser!",
}
EOF
}

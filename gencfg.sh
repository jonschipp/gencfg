#!/bin/bash
# BSD License:
# Copyright (c) 2013, Jon Schipp
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# Redistributions of source code must retain the above copyright notice, this list of
# conditions and the following disclaimer. Redistributions in binary form must reproduce
# the above copyright notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
# SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

usage()
{
cat <<EOF

Trafgen configuration generator and syntax testing tool

      Generation:

	-G <type> packet type "syslog/beacon/rfc2544":
		\`\`rfc2544'' writes each frame size to dir
	-s <ip>   Source IP
	-d <ip>   Destination IP
	-m <mac>  Source Mac, aa:bb:cc...
	-M <mac>  Destination Mac, 00:11:22
	-p <num>  Source Port
	-P <num>  Destination Port
	-T <ssid> for type "beacon" e.g. \`\`-T "Awesome!"''
	   if "random", generate random SSID of length 8
	-n <num> of random generations for \`\`-T random'' only

      Input:

	-c <file> Exported C array (Wireshark)
	-r <file> PCAP file (requires netsniff-ng)

      Output:

	-S <type> Separator:
	   "comma/white/noendwhite/noendcomma"
	-o <file> Write to file (default: stdout)

Usage: $0 -h
$0 -c array.txt -S comma | trafgen --in - --out eth0 --num 100
$0 -G syslog -s 10.1.1.1 -d 10.1.1.2 -M 00:0c:29:8d:4d:a2
$0 -G beacon -T random -n 1000 -m de:ad:be:ef:00:00 -o beacon.cfg
EOF
}

output()
{
if [[ $OUT == "comma" ]]; then
cat - > ${OUTFILE:-/dev/stdout}
fi
if [[ $OUT == "white" ]]; then
	tr -d ',' > ${OUTFILE:-/dev/stdout}
fi
if [[ $OUT == "noendwhite" ]]; then
	sed 's/,//10' > ${OUTFILE:-/dev/stdout}
fi
if [ -z $OUT ]; then
cat - > ${OUTFILE:-/dev/stdout}
fi
}

coutput()
{
if [[ $OUT == "comma" ]]; then
	sed 's/.*{$/{/g;/0x/s/^/ /;s/;//;s/\/\*.*\*\///;s/\(0x[a-z0-9]\{2\}\) /\1,/' $INFILE > ${OUTFILE:-/dev/stdout}
fi
if [[ $OUT == "noendcomma" ]]; then
	sed 's/.*{$/{/g;/0x/s/^/ /;s/;//;s/\/\*.*\*\///' $INFILE > ${OUTFILE:-/dev/stdout}
fi
if [[ $OUT == "white" ]]; then
	sed 's/.*{$/{/g;/0x/s/^/ /;s/;//;s/\/\*.*\*\///;s/,/ /g' $INFILE > ${OUTFILE:-/dev/stdout}
fi
if [[ $OUT == "noendwhite" ]]; then
	sed 's/.*{$/{/g;/0x/s/^/ /;s/;//;s/\/\*.*\*\///' $INFILE > ${OUTFILE:-/dev/stdout}
fi
if [ -z $OUT ]; then
cat - < $INFILE > ${OUTFILE:-/dev/stdout}
fi
}

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
 c16(${5:-0}),
 /* UDP Dest Port */
 c16(${6:-0}),
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

beacon()
{
for n in $(seq 1 $NUM)
do

if [[ $SSID == random ]]; then
set -- "$1" "$2" "$(tr -dc "[:alpha:]" < /dev/urandom | head -c 8)"
fi

cat <<EOF
{

 /* Header Revision */
 0x00,

 /* Header Pad */
 0x00,

 /* Header Length */
 0x1a, 0x00,

 /* Present Flags */
 0x2f, 0x48, 0x00, 0x00,

 /* MAC Timestamp */
 0x20, 0x56, 0x92, 0x4c,
 0x00, 0x00, 0x00, 0x00,

 /* Flags (FCS Set)*/
 0x10,

 /* Data Rate */
 0x02,

 /* Channel Frequency */
 0x6c, 0x09,

 /* Channelt Type */
 0xa0, 0x00,

 /* SSI Signal */
 0xb8,

 /* Antenna */
 0x01,

 /* RX Flags */
 0x00, 0x00,

 /* Beacon */
 0x80, 0x00,

 /* Duration */
 0x00, 0x00,

 /* Dest MAC Address */
 ${1:-0xff,0xff,0xff,0xff,0xff,0xff,}

 /* Source Address */
 ${2:-0xaa, 0xbb, 0xcc, 0x11, 0x22, 0x33,}

 /* BSS ID */
 0x00, 0x27, 0x0d, 0x48, 0x7a, 0xb0,

 /* Fragment number & Sequence Number */
 0x20, 0x5b,

        /* 802.11 Management Frame */

 /* Timestamp */
 0x24, 0x80, 0xb4, 0x14, 0x15, 0x08, 0x00, 0x00,

 /* Beacon Interval */
 0x66, 0x00,

 /* Capabilities Information */
 0x31, 0x04, 0x00, 0x08,

 /* SSID */
 "${3:-trafgen!}",

 /* Supported Rates */
 0x01, 0x06, 0x98, 0x24, 0x30, 0x48, 0x60, 0x6c,

 /* DS Parameter Set */
 0x03, 0x01, 0x01,

 /* Traffic Indication Map */
 0x05, 0x04, 0x00, 0x01, 0x00, 0x00,

 /* County Information */
 0x07, 0x06, 0x55, 0x53, 0x20, 0x01, 0x0b, 0x1e,

 /* QBSS Load Element */
 0x0b, 0x05, 0x00, 0x00, 0x07, 0x8d, 0x5b,

 /* ERP Information */
 0x2a, 0x01, 0x00,

 /* HT Capabilites */
 0x2d, 0x1a, 0x2c, 0x18, 0x1b, 0xff, 0xff, 0x00, 0x00,
 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
 0x00,

 /* RSN Information */
 0x30, 0x14, 0x01, 0x00, 0x00, 0x0f, 0xac, 0x04, 0x01,
 0x00, 0x00, 0x0f, 0xac, 0x04, 0x01, 0x00, 0x00, 0x0f,
 0xac, 0x01, 0x28, 0x00,

 /* HT Information */
 0x3d, 0x16, 0x01, 0x00, 0x05, 0x00, 0x00, 0x00, 0x00,
 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,

 /* Vendor Tag */

        /* (Vendor Tag) Cisco*/
        0x96,

        /* Tag Length */
        0x06,

        /* Tag Interpretation */
        0x00, 0x40, 0x96, 0x00, 0x0e, 0x00,

 /*  Vendor Specific */
 0xdd, 0x18, 0x00, 0x50, 0xf2, 0x02, 0x01, 0x01, 0x80,
 0x00, 0x03, 0xa4, 0x00, 0x00, 0x27, 0xa4, 0x00, 0x00,
 0x42, 0x43, 0x5e, 0x00, 0x62, 0x32, 0x2f, 0x00,
 0xdd, 0x06, 0x00, 0x40, 0x96, 0x01, 0x01, 0x04,
 0xdd, 0x05, 0x00, 0x40, 0x96, 0x03, 0x05, 0xdd, 0x05,
 0x00, 0x40, 0x96, 0x0b, 0x09, 0xdd, 0x08, 0x00,
 0x40, 0x96, 0x13, 0x01, 0x00, 0x34, 0x01, 0xdd, 0x05,
 0x00, 0x40, 0x96, 0x14, 0x05, 0xdd, 0x1d, 0x00, 0x40,
 0x96, 0x0c, 0x03, 0x28, 0x46, 0xd5, 0x37, 0x66, 0xa7,
 0x3c, 0x01, 0x00, 0x00, 0x36, 0x78, 0x15, 0x00, 0x00,
 0x00, 0x4c, 0xd6, 0x7f, 0x39, 0x8f, 0x31, 0xdc, 0xaf,

 /* Frame check sequence */
 0xf3, 0x93, 0xc8, 0xd3,

}
EOF
done
}

# option and argument handling
while getopts "hc:d:G:m:M:n:o:r:p:P:s:S:T:" OPTION
do
     case $OPTION in
         h)
             usage
	     exit
	     ;;
	 c)
	     INTYPE="$OPTION"
	     INFILE="$OPTARG"
	     ;;
	 G)
	     if [[ "$OPTARG" == syslog ]]; then
	     TYPE="$OPTARG"
	     elif [[ "$OPTARG" == beacon ]]; then
	     TYPE="$OPTARG"
	     elif [[ "$OPTARG" == rfc2544 ]]; then
	     TYPE="$OPTARG"
	     else
	     echo "Unknown type!"
	     exit 1
	     fi
	     ;;
	 n)
	     NUM="$OPTARG"
	     ;;
	 o)
	     OUTFILE="$OPTARG"
	     ;;
	 S)
	     if [[ "$OPTARG" == comma ]]; then
	     OUT="$OPTARG"
	     elif [[ "$OPTARG" == white ]]; then
	     OUT="$OPTARG"
	     elif [[ "$OPTARG" == noendwhite ]]; then
	     OUT="$OPTARG"
	     elif [[ "$OPTARG" == noendcomma ]]; then
	     OUT="$OPTARG"
	     else
	     echo "Unknown separator!"
	     exit 1
	     fi
	     ;;

	  s)
	     SRCIP=$(echo $OPTARG | tr '.' ',')
	     ;;

	  d)
	     DSTIP=$(echo $OPTARG | tr '.' ',')
             ;;

          M)
	     DSTMAC=$(echo $OPTARG | sed 's/^/0x/;s/:/0x/g;s/\(0x[a-zA-Z0-9]\{2\}\)/\1,/g')
	     ;;

	  m)
	     SRCMAC=$(echo $OPTARG | sed 's/^/0x/;s/:/0x/g;s/\(0x[a-zA-Z0-9]\{2\}\)/\1,/g')
	     ;;
	  p)
	     SRCPORT="$OPTARG"
	     ;;
	  P)
	     DSTPORT="$OPTARG"
	     ;;

	  r)
	     INTYPE="$OPTION"
	     INFILE="$OPTARG"
	     ;;

   	  T)
	     if [[ "$OPTARG" == random ]]; then
	     SSID="random"
	     fi
	     SSID=$(echo $OPTARG | cut -c1-8)
	     ;;
         \?)
             ;;
     esac
done

 # meat

# C array
if [[ "$INTYPE" == "c" ]]; then
coutput
fi

#  PCAP
if [[ "$INTYPE" == "r" ]]; then
netsniff-ng --in $INFILE --out - | output
fi

# Syslog
if [[ "$TYPE" == "syslog" ]]; then
syslog ${DSTMAC:-""} ${SRCMAC:-""} ${SRCIP:-""} ${DSTIP:-""} ${SRCPORT:-""} ${DSTPORT:-""} | output
fi

# RFC2544
if [[ "$TYPE" == "rfc2544" ]]; then
rfc2544 ${DSTMAC:-""} ${SRCMAC:-""} ${SRCIP:-""} ${DSTIP:-""} ${SRCPORT:-""} ${DSTPORT:-""} | output
fi

# Beacon
if [[ "$TYPE" == "beacon" ]]; then
beacon ${DSTMAC:-""} ${SRCMAC:-""} ${SSID:-""} | output
fi

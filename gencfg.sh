#!/bin/bash
#
# See LICENSE for copyright information
#

usage()
{
cat <<EOF

Trafgen configuration generator and syntax testing tool

      Generation:

	-G <type> packet type "syslog/beacon/rfc2544/arp_request/arp_reply/ntp":
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

argcheck() {
# if less than n argument
if [ $ARGC -lt $1 ]; then
        echo "Missing arguments! Use \`\`-h'' for help."
        exit 1
fi
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

# Load plugins

. ./plugins/arp.sh
. ./plugins/beacon.sh
. ./plugins/ntp.sh
. ./plugins/rfc2544.sh
. ./plugins/syslog.sh

# Initialize variables
ARGC=$#

argcheck 1

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
	     elif [[ "$OPTARG" == ntp ]]; then
	     TYPE="$OPTARG"
	     elif [[ "$OPTARG" == arp_request ]]; then
	     TYPE="$OPTARG"
	     OPCODE="0x00,0x01,"
	     elif [[ "$OPTARG" == arp_reply ]]; then
	     TYPE="$OPTARG"
	     OPCODE="0x00,0x02,"
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

# ARP
if [[ "$TYPE" == "arp_request" ]] || [[ "$TYPE" == "arp_reply" ]]; then
arp ${DSTMAC:-""} ${SRCMAC:-""} ${SRCIP:-""} ${DSTIP:-""} | output
fi

# NTP
if [[ "$TYPE" == "ntp" ]]; then
ntp ${DSTMAC:-""} ${SRCMAC:-""} ${SRCIP:-""} ${DSTIP:-""} ${SRCPORT:-""} ${DSTPORT:-""} | output
fi


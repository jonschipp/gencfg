#!/bin/bash
usage()
{
cat <<EOF

Trafgen configuration generator and syntax testing tool

      Generation: 

	-G <type> "syslog" 	  
	-s <ip>   Source IP
	-d <ip>   Destination IP
	-m <mac>  Source Mac, aa:bb:cc...
	-M <mac>  Destination Mac, 00:11:22
 
      Input:

	-c <file> Exported C array (Wireshark)
	-p <file> PCAP file (requires netsniff-ng)

      Output:
	
	-s <type> Separator:
	   "comma/white/endwhite/noendcomma"
	-o <file> Write to file (default: stdout)

Usage: $0 -h
$0 -c array.txt -s comma | trafgen --in - --out eth0 --num 100
$0 -G syslog -s 10.1.1.1 -d 10.1.1.2 -M 00:0c:29:8d:4d:a2
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
if [[ $OUT == "endwhite" ]]; then
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
 c16(514),
 /* UDP Dest Port */
 c16(514),
 /* Length */
 c16(102),
 /* Checksum */
 c16(00),

 /* Syslog - RFC5424 */

         /* PRI */
         0x3c,
         50,57
         0x3e,

         /* Timestamp */
         /* "$(date +"%Y-%m-%dT%X.%SZ"), */
         "2013-05-13T13:30:12.12Z",

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

# option and argument handling
while getopts "hc:d:G:m:M:o:p:s:S:" OPTION
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
	     else
	     echo "Unknown type!"
	     exit 1
	     fi
	     ;;
	 o)
	     OUTFILE="$OPTARG"
	     ;;	
	 S)
	     if [[ "$OPTARG" == comma ]]; then
	     OUT="$OPTARG" 
	     elif [[ "$OPTARG" == white ]]; then
	     OUT="$OPTARG"
	     elif [[ "$OPTARG" == endwhite ]]; then
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
	     INTYPE="$OPTION"
	     INFILE="$OPTARG" 
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
if [[ "$INTYPE" == "p" ]]; then
netsniff-ng --in $INFILE --out - | output
fi

# Syslog
if [[ "$TYPE" == "syslog" ]]; then
syslog ${DSTMAC:-""} ${SRCMAC:-""} ${SRCIP:-""} ${DSTIP:-""} | output
fi

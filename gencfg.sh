#!/bin/bash
usage()
{
cat <<EOF

Trafgen configuration generator and syntax testing tool

      Generation: 

	-G  	  
	
      Input:

	-c <file> Exported C array (Wireshark)

      Output:
	
	-s <type> Separator:
	   "comma/white/noendcomma"
	-o <file> Write to file (default: stdout)

Usage: $0 -h
$0 -c array.txt -s comma | trafgen --in - --out eth0 --num 100
EOF
}

#filecheck()
#{
#}

output()
{
if [[ $OUT == "comma" ]]; then
	sed 's/.*{$/{/g;/0x/s/^/ /;s/;//;s/\/\*.*\*\///;s/\(0x[a-z0-9]\{2\}\) /\1,/' $INFILE > ${OUTFILE:-/dev/stdout}
fi 
if [[ $OUT == "noendcomma" ]]; then
	sed 's/.*{$/{/g;/0x/s/^/ /;s/;//;s/\/\*.*\*\///' $INFILE
fi 
if [[ $OUT == "white" ]]; then
	sed 's/.*{$/{/g;/0x/s/^/ /;s/;//;s/\/\*.*\*\///;s/,/ /g' $INFILE
fi
}

# option and argument handling
while getopts "hc:o:s:" OPTION
do
     case $OPTION in
         h)
             usage
	     exit
	     ;;
	 c) 
	     INFILE="$OPTARG" 
	     ;; 
	 o)
	     OUTFILE="$OPTARG"
	     ;;	
	 s)
	     if [[ "$OPTARG" == comma ]]; then
	     OUT="$OPTARG" 
	     elif [[ "$OPTARG" == white ]]; then
	     OUT="$OPTARG"
	     elif [[ "$OPTARG" == noendcomma ]]; then
	     OUT="$OPTARG"
	     else
	     echo "Unknown separator!"
	     exit 1
	     fi
	     ;;	
         \?)
             usage
             ;;
     esac
done

output

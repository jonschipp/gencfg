# gencfg

`gencfg` - A [trafgen](https://github.com/netsniff-ng/netsniff-ng) configuration generation and syntax testing tool

   * Generate premade and customizable packet generations
   * Apply byte separators to test syntax after changes to the lex parser
   * Convert input file to trafgen packet configuration

##### Todo (not ranked) [~~DONE~~]:

   * More packet configs
   * ~~Fix endwhite separator, now noendwhite~~
   * Apply separators consistently
   * ~~Create RFC2544 packet configurations~~
   * More configurable beacon frame fields
   * Write function to check for trafgen and netsniff-ng
   * Add NST packet configs.
   * Add config addressed in ip frag patch to linux kernel

## Usage:

```shell
Usage: ./gencfg -G <packet type> -S <separator> [-o out.txt]
```

### Non-Mandatory Options:

`-o` write output to file *e.g.* `-o packet.cfg` <br>
`-S` byte separator "comma/white/endwhite/noendcomma" *e.g.* `-S comma` <br>

Write configurations to a file or redirect to trafgen:
```shell
./gencfg ... | trafgen --in - --out eth0 --num 1000`
./gencfg ... -o packet.cfg && trafgen --in packet.cfg --out eth0 --num 1000`
```

## Packet Configuration:

Generate built-in packet configurations `-G <packet type>`

### Supported packet types:

   * beacon
   * syslog
   * arp_request
   * arp_replay
   * rfc2544

#### beacon:
Generation of 802.11 beacon frames. For proper byte alignment choose
an SSID of 8 alpha-numeric characters ( `-T "FreeWifi"` ). Random
generation of 8 characters via /dev/urandom can be done automatically
( `-T random` ) and the number of random SSID beacon generations can be
chosen ( `-n 1000` ). Other configurable option includes specifying the
source MAC address ( `-m 00:11:22:aa:bb:cc` ).

```shell
./gencfg -G beacon -T "FreeWifi" -m 00:11:22:aa:bb:cc
```

#### syslog:
Generate a syslog packet configuration. Configurable options
include source MAC, destination MAC, source IP, and destination IP.

```shell
./gencfg -G syslog -s 10.1.1.1 -d 10.1.1.2 -m de:ad:be:ef:00:00 -M 00:0c:29:8d:4d:a2
```

#### arp_request
Generate an ARP request frame. Configurable options include source MAC,
destination MAC, source IP, and destination IP. Destination MAC defaults
to the broadcast address (ff:ff:ff:ff:ff:ff).

```shell
./gencfg -G arp_request -s 10.1.1.1 -d 10.1.1.2 -m $(cat /sys/class/net/eth0/address)
```

Gratuitous ARP Request:

```shell
./gencfg -G arp_request -s 1.1.1.1 -d 1.1.1.1 -m 00:11:22:33:44:55
```

#### arp_reply
Generate an ARP reply frame. Configurable options include source MAC,
destination MAC, source IP, and destination IP.

```shell
./gencfg -G arp_request -s 10.1.1.1 -d 10.1.1.2 -m $(cat /sys/class/net/eth0/address)
```

Gratuitous ARP Reply:

```shell
./gencfg -G arp_reply -s 1.1.1.1 -d 1.1.1.1 -m 00:11:22:33:44:55
```

#### rfc2544
Generates an individual packet configuration based on the Ethernet frame <br>
sizes specified in ***RFC2544***, "Benchmarking Methodology for Network Interconnect Devices". <br>

Each size is written to a cfg file in directory titled `rfc2544-$ts` <br>
and to stdout. Sizes are outlined in ***Section 9.1***, *"Frame sizes to be <br>
used on Ethernet"* and consist of `64, 128, 256, 512, 1024, 1280, 1518.` <br>
Ethernet NICs add a 4 byte CRC to each frame which is accounted for in each <br>
configuration. E.g. for the 64 byte frame size, 60 bytes is configured by trafgen <br>
and the 4 bytes is added by the NIC, thus, totaling a frame size of 64 bytes. <br>
The default source and destination ports are set to UDP 9 (discard). <br>

```shell
./gencfg -G rfc2544 -s 10.1.1.1 -d 10.1.1.2 -m de:ad:be:ef:00:00 -M 00:0c:29:8d:4d:a2
```

## Conversion:

`-c` Convert C array of bytes exported from Wireshark. *e.g.* `-c carray.txt` <br>
`-p` Convert PCAP (requires netsniff-ng) to trafgen config *e.g.* `-p example.pcap` <br>

## Examples:
```shell
./gencfg -c array.txt -S comma | trafgen --in - --out eth0 --num 100
./gencfg -G syslog -s 10.1.1.1 -d 10.1.1.2 -M 00:0c:29:8d:4d:a2 -S white
./gencfg -G beacon -T random -n 1000 -m de:ad:be:ef:00:00 -o beacon.cfg
./gencfg -G beacon -T "FreeWifi" -o beacon.cfg | trafgen --in - --out wlan0 --rfraw --num 1000
./gencfg -G rfc2544 -s 192.168.1.10 -d 192.168.1.255 -M ff:ff:ff:ff:ff:ff -P 123
```

## Author:
***Jon Schipp*** (keisterstash) <br>
jonschipp [ at ] Gmail dot com <br>
`sickbits.net`, `jonschipp.com` <br>

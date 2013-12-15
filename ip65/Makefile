AS=ca65
LD=ld65
AFLAGS=

# ip65.lib : minimal IP stack (UDP only)
# ip65_tcp.lib : full featured TCP/IP stack
# ip65_wiznet.lib : hybrid stack for use with the w5100 chip : UDP,ICMP & ARP is done on host, TCP is on w5100

%.o: %.c
	$(CC) -c $(CFLAGS) $<

%.o: %.s
	$(AS) $(AFLAGS) $<

ETHOBJS=\
	copymem.o \
	config.o \
	timer.o \
	eth.o \
	arp.o \
	ip65.o \
	printf.o \
	debug.o \
	http.o \
	httpd.o \
	dhcp.o \
	dns.o \
	dottedquad.o \
	output_buffer.o\
	tftp.o \
	parser.o \
	string_utils.o \
	telnet.o \
	xmodem.o \
	url.o \
	arithmetic.o\
	ip.o \
	sntp.o \
	icmp.o \
	cifs.o \
	udp.o

all: ip65.lib ip65_tcp.lib ip65_wiznet.lib

ip65.lib: $(ETHOBJS) function_dispatcher.s 
	$(AS) $(AFLAGS) function_dispatcher.s
	$(AS) $(AFLAGS) ip.s
	$(AS) $(AFLAGS) icmp.s
	ar65 a ip65.lib $(ETHOBJS) function_dispatcher.o 

ip65_tcp.lib: tcp.o $(ETHOBJS) function_dispatcher.s tcp.s
	$(AS) $(AFLAGS) function_dispatcher.s -DTCP -DAPI_VERSION=2
	$(AS) $(AFLAGS) ip.s -DTCP
	$(AS) $(AFLAGS) icmp.s -DTCP
	ar65 a ip65_tcp.lib $(ETHOBJS) function_dispatcher.o tcp.o

ip65_wiznet.lib: $(ETHOBJS) function_dispatcher.s
	$(AS) $(AFLAGS) function_dispatcher.s 
	$(AS) $(AFLAGS) ip.s 
	$(AS) $(AFLAGS) icmp.s -DTCP
	ar65 a ip65_wiznet.lib $(ETHOBJS) function_dispatcher.o 

clean:
	rm -f *.o
	rm -f ip65.lib
	rm -f ip65_tcp.lib
	rm -f ip65_wiznet.lib

distclean: clean
	rm -f *~

AS=ca65
LD=ld65
AFLAGS=


%.o: %.c
	$(CC) -c $(CFLAGS) $<

%.o: %.s
	$(AS) $(AFLAGS) $<

ETHOBJS= \
	copymem.o \
	config.o \
	timer.o \
	cs8900a.o \
	eth.o \
	arp.o \
	icmp.o \
	udp.o \
	ip65.o \
	printf.o \
	debug.o \
  dhcp.o \
  dns.o \
  dottedquad.o \
  output_buffer.o\
  tftp.o \
  arithmetic.o\
  
  
all: ip65.lib ip65_tcp.lib

ip65.lib: $(ETHOBJS) function_dispatcher.s ip.s
	$(AS) $(AFLAGS) function_dispatcher.s
	$(AS) $(AFLAGS) ip.s
	ar65 a ip65.lib $(ETHOBJS) function_dispatcher.o ip.o

ip65_tcp.lib: tcp.o $(ETHOBJS) function_dispatcher.s ip.s tcp.s
	$(AS) $(AFLAGS) function_dispatcher.s -DTCP -DAPI_VERSION=2
	$(AS) $(AFLAGS) ip.s -DTCP
	ar65 a ip65_tcp.lib $(ETHOBJS) function_dispatcher.o ip.o tcp.o

clean:
	rm -f *.o
	rm -f ip65.lib
	rm -f ip65_tcp.lib


distclean: clean
	rm -f *~

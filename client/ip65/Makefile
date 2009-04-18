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
	ip.o \
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
  function_dispatcher.o \  
  
all: ip65.lib 

ip65.lib: $(ETHOBJS) 
	ar65 a ip65.lib $^


clean:
	rm -f *.o
	rm -f ip65.lib


distclean: clean
	rm -f *~

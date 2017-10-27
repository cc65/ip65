# ip65.lib : minimal IP stack (UDP only)
# ip65_tcp.lib : full featured TCP/IP stack

all: ip65.lib ip65_tcp.lib

%.o: %.s
	ca65 $<

%_tcp.o: %.s
	ca65 -DTCP -o $@ $<

IP65OBJS=\
	arithmetic.o \
	arp.o \
	config.o \
	copymem.o \
	dhcp.o \
	dns.o \
	dottedquad.o \
	eth.o \
	http.o \
	httpd.o \
	ip65.o \
	tftp.o \
	timer.o \
	output_buffer.o \
	parser.o \
	sntp.o \
	string_utils.o \
	udp.o \
	url.o

ip65.lib: $(IP65OBJS) ip.o icmp.o
	ar65 a $@ $^

ip65_tcp.lib: $(IP65OBJS) ip_tcp.o icmp_tcp.o tcp.o
	ar65 a $@ $^

clean:
	-rm -f *.o
	-rm -f *.lib

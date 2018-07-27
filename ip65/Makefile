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
	config_c.o \
	copymem.o \
	dhcp.o \
	dhcp_c.o \
	dns.o \
	dns_c.o \
	dottedquad.o \
	dottedquad_c.o \
	download.o \
	download_c.o \
	driver_c.o \
	eth.o \
	http.o \
	http_c.o \
	httpd.o \
	httpd_c.o \
	icmp_c.o \
	input_c.o \
	ip65.o \
	ip65_c.o \
	tcp_c.o \
	tftp.o \
	tftp_c.o \
	timer.o \
	timer_c.o \
	output_buffer.o \
	parser.o \
	sntp.o \
	sntp_c.o \
	string_utils.o \
	udp.o \
	udp_c.o \
	url.o \
	url_c.o

ip65.lib: $(IP65OBJS) ip.o icmp.o
	ar65 a $@ $^

ip65_tcp.lib: $(IP65OBJS) ip_tcp.o icmp_tcp.o tcp.o
	ar65 a $@ $^

clean:
	-rm -f *.o
	-rm -f *.lib

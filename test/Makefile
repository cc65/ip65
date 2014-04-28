# Build for Cirrus Logic CS8900A based devices:
# make

# Build for Standard Microsystems LAN91C96 based devices:
# make eth=sm

# Build for WIZnet W5100 based devices:
# make eth=wn

CC     = cl65
AS     = ca65
LD     = ld65
CFLAGS = -Oirs -t $(TARGET)
AFLAGS =

ifeq ($(eth),sm)
  A2DRIVERLIB  = ../drivers/a2lancegs.lib
else ifeq ($(eth),wn)
else
  C64DRIVERLIB = ../drivers/c64rrnet.lib
  A2DRIVERLIB  = ../drivers/a2uther.lib
  VICDRIVERLIB = ../drivers/vic20rrnet.lib
endif

IP65LIB    = ../ip65/ip65.lib
IP65TCPLIB = ../ip65/ip65_tcp.lib

INCFILES = \
  ../inc/common.i\
  ../inc/commonprint.i\
  ../inc/net.i\

all: prg bin

prg: \
	ip65 \
	drivers \
	cifs_tcp.prg \
	dns.prg \
	dottedquad.prg \
	geturl_tcp.prg \
	httpd_tcp.prg \
	parsequerystring.prg \
	parser_tcp.prg \
	ping_tcp.prg \
	sntp.prg \
	tcp_tcp.prg \
	tftp.prg

bin: \
	ip65 \
	drivers \
	cifs_tcp.bin \
	dns.bin \
	dottedquad.bin \
	geturl_tcp.bin \
	httpd_tcp.bin \
	parsequerystring.bin \
	parser_tcp.bin \
	ping_tcp.bin \
	sntp.bin \
	tcp_tcp.bin \
	tftp.bin

vicprg: \
	ip65 \
	drivers \
	cifs_tcp.vicprg \
	dns.vicprg \
	dottedquad.vicprg \
	geturl_tcp.vicprg \
	httpd_tcp.vicprg \
	parsequerystring.vicprg \
	parser_tcp.vicprg \
	ping_tcp.vicprg \
	sntp.vicprg \
	tcp_tcp.vicprg \
	tftp.vicprg

ip65:
	make -C ../ip65 all

drivers:
	make -C ../drivers all

d64: ip65.d64

dsk: ip65.dsk

%.o: %.s
	$(AS) $(AFLAGS) $<

%.prg: %.o $(IP65LIB) $(C64DRIVERLIB) $(INCFILES)
	$(LD) -o $*.prg -t c64 -m $*.c64.map -vm $< $(IP65LIB) $(C64DRIVERLIB) c64.lib

%_tcp.prg: %.o $(IP65TCPLIB) $(C64DRIVERLIB) $(INCFILES)
	$(LD) -o $(subst _tcp,,$*).prg -t c64 -m $(subst _tcp,,$*).c64.map -vm $< $(IP65TCPLIB) $(C64DRIVERLIB) c64.lib

%.bin: %.o $(IP65LIB) $(A2DRIVERLIB) $(INCFILES)
	$(LD) -o $*.bin -t apple2 -m $*.a2.map -vm $< $(IP65LIB) $(A2DRIVERLIB) apple2.lib

%_tcp.bin: %.o $(IP65TCPLIB) $(A2DRIVERLIB) $(INCFILES)
	$(LD) -o $(subst _tcp,,$*).bin -t apple2 -m $(subst _tcp,,$*).a2.map -vm $< $(IP65TCPLIB) $(A2DRIVERLIB) apple2.lib

%.vicprg: %.o $(IP65LIB) $(VICDRIVERLIB) $(INCFILES)
	$(LD) -o $*.vicprg -C vic20-32k.cfg -m $*.vic.map -vm $< $(IP65LIB) $(VICDRIVERLIB) vic20.lib

%_tcp.vicprg: %.o $(IP65TCPLIB) $(VICDRIVERLIB) $(INCFILES)
	$(LD) -o $(subst _tcp,,$*).vicprg -C vic20-32k.cfg -m $(subst _tcp,,$*).vic.map -vm $< $(IP65TCPLIB) $(VICDRIVERLIB) vic20.lib

ip65.d64: prg
	$(C1541) -format ip65,00 d64 $@
	$(C1541) -attach $@ -write dns.prg        dns,p
	$(C1541) -attach $@ -write dottedquad.prg dottedquad,p
	$(C1541) -attach $@ -write geturl.prg     geturl,p
	$(C1541) -attach $@ -write httpd.prg      httpd,p
	$(C1541) -attach $@ -write parser.prg     parser,p
	$(C1541) -attach $@ -write ping.prg       ping,p
	$(C1541) -attach $@ -write sntp.prg       sntp,p
	$(C1541) -attach $@ -write tcp.prg        tcp,p
	$(C1541) -attach $@ -write tftp.prg       tftp,p

ip65.dsk: bin
	cp prodos.dsk $@
	java -jar $(AC) -cc65 $@ dns        bin 0 < dns.bin
	java -jar $(AC) -cc65 $@ dottedquad bin 0 < dottedquad.bin
	java -jar $(AC) -cc65 $@ geturl     bin 0 < geturl.bin
	java -jar $(AC) -cc65 $@ httpd      bin 0 < httpd.bin
	java -jar $(AC) -cc65 $@ parser     bin 0 < parser.bin
	java -jar $(AC) -cc65 $@ ping       bin 0 < ping.bin
	java -jar $(AC) -cc65 $@ sntp       bin 0 < sntp.bin
	java -jar $(AC) -cc65 $@ tcp        bin 0 < tcp.bin
	java -jar $(AC) -cc65 $@ tftp       bin 0 < tftp.bin

clean:
	-rm -f *.o *.prg *.bin *.vicprg *.map
	-rm -f ip65.d64 ip65.dsk

distclean: clean
	-rm -f *~

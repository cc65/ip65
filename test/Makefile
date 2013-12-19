CC=cl65
AS=ca65
LD=ld65
CFLAGS=-Oirs -t $(TARGET)
AFLAGS=

IP65LIB=../ip65/ip65.lib
IP65TCPLIB=../ip65/ip65_tcp.lib
C64RRNETLIB=../drivers/c64rrnet.lib
C64WIZNETLIB=../drivers/c64wiznet.lib
IP65WIZNETLIB=../ip65/ip65_wiznet.lib
A2UTHERLIB=../drivers/a2uther.lib
A2LANCEGSLIB=../drivers/a2lancegs.lib
VIC20RRNETLIB=../drivers/vic20rrnet.lib

INCFILES=\
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
	parsequerystring.prg \
	parser_tcp.prg \
	ping_tcp.prg \
	sntp.prg \
	tcp_tcp.prg \
	tftp.prg \
#	vic20.prg \
	wiznet.prg

bin: \
	ip65 \
	drivers \
	cifs_tcp.bin \
	dns.bin \
	dottedquad.bin \
	geturl_tcp.bin \
	parsequerystring.bin \
	parser_tcp.bin \
	ping_tcp.bin \
	sntp.bin \
	tcp_tcp.bin \
	tftp.bin \
#	lancegs.bin

ip65:
	make -C ../ip65 all

drivers:
	make -C ../drivers all

d64: ip65.d64

dsk: ip65.dsk

%.o: %.s
	$(AS) $(AFLAGS) $<

%.prg: %.o $(IP65LIB) $(C64RRNETLIB) $(INCFILES) ../cfg/c64prg.cfg
	$(LD) -o $*.prg -C ../cfg/c64prg.cfg -m $*.c64.map -vm $< $(IP65LIB) $(C64RRNETLIB) c64.lib

%_tcp.prg: %.o $(IP65TCPLIB) $(C64RRNETLIB) $(INCFILES) ../cfg/c64prg.cfg
	$(LD) -o $(subst _tcp,,$*).prg -C ../cfg/c64prg.cfg -m $(subst _tcp,,$*).c64.map -vm $< $(IP65TCPLIB) $(C64RRNETLIB) c64.lib

%.bin: %.o $(IP65LIB) $(A2UTHERLIB) $(INCFILES) ../cfg/a2bin.cfg
	$(LD) -o $*.bin -C ../cfg/a2bin.cfg -m $*.a2.map -vm $< $(IP65LIB) $(A2UTHERLIB) apple2.lib

%_tcp.bin: %.o $(IP65TCPLIB) $(A2UTHERLIB) $(INCFILES) ../cfg/a2bin.cfg
	$(LD) -o $(subst _tcp,,$*).bin -C ../cfg/a2bin.cfg -m $(subst _tcp,,$*).a2.map -vm $< $(IP65TCPLIB) $(A2UTHERLIB) apple2.lib

wiznet.prg: wiznet.o $(IP65WIZNETLIB) $(C64WIZNETLIB) $(INCFILES) ../cfg/c64prg.cfg
	$(LD) -o wiznet.prg -C ../cfg/c64prg.cfg -m wiznet.map -vm $< $(IP65WIZNETLIB) $(C64WIZNETLIB)

vic20.prg: vic20.o $(IP65TCPLIB) $(VIC20RRNETLIB) $(INCFILES) ../cfg/vic20prg.cfg
	$(LD) -o vic20.prg -C ../cfg/vic20prg.cfg -m vic20.map -vm $< $(IP65TCPLIB) $(VIC20RRNETLIB)  

lancegs.bin: lancegs.o $(IP65LIB) $(A2LANCEGSLIB) $(INCFILES) ../cfg/a2bin.cfg
	$(LD) -o lancegs.bin -C ../cfg/a2bin.cfg -m lancegs.a2.map -vm $< $(IP65LIB) $(A2LANCEGSLIB)

ip65.d64: prg
	$(C1541) -format ip65,00 d64 $@
	$(C1541) -attach $@ -write dns.prg        dns,p
	$(C1541) -attach $@ -write dottedquad.prg dottedquad,p
	$(C1541) -attach $@ -write geturl.prg     geturl,p
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
	java -jar $(AC) -cc65 $@ parser     bin 0 < parser.bin
	java -jar $(AC) -cc65 $@ ping       bin 0 < ping.bin
	java -jar $(AC) -cc65 $@ sntp       bin 0 < sntp.bin
	java -jar $(AC) -cc65 $@ tcp        bin 0 < tcp.bin
	java -jar $(AC) -cc65 $@ tftp       bin 0 < tftp.bin

clean:
	rm -f *.o *.bin *.prg *.map
	rm -f ip65.d64 ip65.dsk

distclean: clean
	rm -f *~

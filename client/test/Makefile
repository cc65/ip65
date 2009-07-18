CC=cl65
AS=ca65
LD=ld65
CFLAGS=-Oirs -t $(TARGET)
AFLAGS=


IP65LIB=../ip65/ip65.lib

IP65TCPLIB=../ip65/ip65_tcp.lib

C64PROGLIB=../drivers/c64prog.lib
C64PNB65LIB=../drivers/c64nb65.lib
APPLE2PROGLIB=../drivers/apple2prog.lib

INCFILES=\
  ../inc/common.i\
  ../inc/commonprint.i\
  ../inc/net.i\

all: \
	ip65test.dsk \
	testdns.prg \
	gopher_browser.prg \
	testdns.pg2 \
	testtftp.prg \
	testtftp.pg2\
	test_cart_api.prg\
	testdottedquad.pg2\
	testdottedquad.prg\
	test_tcp.prg \

%.o: %.c
	$(CC) -c $(CFLAGS) $<

%.o: %.s
	$(AS) $(AFLAGS) $<

%.prg: %.o $(IP65LIB) $(C64PROGLIB) $(INCFILES) ../cfg/c64prg.cfg
	$(LD) -m  $*.map -vm -C ../cfg/c64prg.cfg -o  $*.prg  $(AFLAGS) $< $(IP65LIB) $(C64PROGLIB)  

test_tcp.prg: test_tcp.o $(IP65TCPLIB) $(C64PROGLIB) $(INCFILES) ../cfg/c64prg.cfg
	$(LD) -m  test_tcp.map -vm -C ../cfg/c64prg.cfg -o  test_tcp.prg  $(AFLAGS) $< $(IP65TCPLIB) $(C64PROGLIB)  

#gopher_browser.prg: gopher_browser.o $(IP65TCPLIB) $(C64PROGLIB) $(INCFILES) ../cfg/c64prg.cfg ../inc/gopher.i
#	$(LD) -m  gopher_browser.map -vm -C ../cfg/c64prg.cfg -o  gopher_browser.prg  $(AFLAGS) $< $(IP65TCPLIB) $(C64PROGLIB)  


%.pg2: %.o $(IP65LIB) $(APPLE2PROGLIB) $(INCFILES) ../cfg/a2bin.cfg
	$(LD) -C ../cfg/a2bin.cfg -o  $*.pg2  $(AFLAGS) $< $(IP65LIB) $(APPLE2PROGLIB)

ip65test.dsk: testdns.pg2 testdottedquad.pg2 testtftp.pg2
		ripxplore.rb --init BeautifulBoot ip65test.dsk -a testdns.pg2 -t AppleBinary
		ripxplore.rb ip65test.dsk -a testtftp.pg2 -t AppleBinary
		ripxplore.rb ip65test.dsk -a testdottedquad.pg2 -t AppleBinary
		ripxplore.rb ip65test.dsk -a testdns.pg2 -t AppleBinary

clean:
	rm -f *.o *.pg2 *.prg
	rm -f ip65test.dsk

distclean: clean
	rm -f *~

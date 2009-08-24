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
	testdns.prg \
	test_disk_io.prg \
	test_disk_io.d64 \
	testdns.pg2 \
	testtftp.prg \
	testtftp.pg2\
	test_cart_api.prg\
	testdottedquad.pg2\
	testdottedquad.prg\
	test_tcp.prg \
	test_parser.prg \
	test_ping.prg \
	test_get_url.prg \
#	ip65test.dsk \

%.o: %.c
	$(CC) -c $(CFLAGS) $<

%.o: %.s
	$(AS) $(AFLAGS) $<

%.prg: %.o $(IP65LIB) $(C64PROGLIB) $(INCFILES) ../cfg/c64prg.cfg
	$(LD) -m  $*.map -vm -C ../cfg/c64prg.cfg -o  $*.prg  $(AFLAGS) $< $(IP65LIB) $(C64PROGLIB)  

test_tcp.prg: test_tcp.o $(IP65TCPLIB) $(C64PROGLIB) $(INCFILES) ../cfg/c64prg.cfg
	$(LD) -m  test_tcp.map -vm -C ../cfg/c64prg.cfg -o  test_tcp.prg  $(AFLAGS) $< $(IP65TCPLIB) $(C64PROGLIB)  

test_parser.prg: test_parser.o $(IP65TCPLIB) $(C64PROGLIB) $(INCFILES) ../cfg/c64prg.cfg
	$(LD) -m  test_parser.map -vm -C ../cfg/c64prg.cfg -o  test_parser.prg  $(AFLAGS) $< $(IP65TCPLIB) $(C64PROGLIB)  

test_get_url.prg: test_get_url.o $(IP65TCPLIB) $(C64PROGLIB) $(INCFILES) ../cfg/c64prg.cfg
	$(LD) -m  test_get_url.map -vm -C ../cfg/c64prg.cfg -o  test_get_url.prg  $(AFLAGS) $< $(IP65TCPLIB) $(C64PROGLIB)  

test_ping.prg: test_ping.o $(IP65TCPLIB) $(C64PROGLIB) $(INCFILES) ../cfg/c64prg.cfg
	$(LD) -m  test_ping.map -vm -C ../cfg/c64prg.cfg -o  test_ping.prg  $(AFLAGS) $< $(IP65TCPLIB) $(C64PROGLIB)  

%.pg2: %.o $(IP65LIB) $(APPLE2PROGLIB) $(INCFILES) ../cfg/a2bin.cfg
	$(LD) -C ../cfg/a2bin.cfg -o  $*.pg2  $(AFLAGS) $< $(IP65LIB) $(APPLE2PROGLIB)

    
ip65test.dsk: testdns.pg2 testdottedquad.pg2 testtftp.pg2 
		ripxplore.rb --init BeautifulBoot ip65test.dsk -a testdns.pg2 -t AppleBinary
		ripxplore.rb ip65test.dsk -a testdns.pg2 -t AppleBinary    
		ripxplore.rb ip65test.dsk -a testtftp.pg2 -t AppleBinary
		ripxplore.rb ip65test.dsk -a testdottedquad.pg2 -t AppleBinary
		ripxplore.rb ip65test.dsk -a testdns.pg2 -t AppleBinary
	
test_disk_io.d64:  test_disk_io.prg 
		ripxplore.rb --init CbmDos test_disk_io.d64 -a test_disk_io.prg
		cp screen_prg.bin screen.prg
		ripxplore.rb test_disk_io.d64 -a screen.prg 
    
clean:
	rm -f *.o *.pg2 *.prg
	rm -f ip65test.dsk
  
distclean: clean
	rm -f *~

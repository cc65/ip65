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
APPLE2PROGLIB=../drivers/apple2prog.lib
VIC20RRNETLIB=../drivers/vic20rrnet.lib

INCFILES=\
  ../inc/common.i\
  ../inc/commonprint.i\
  ../inc/net.i\

all: \
	ip65 \
	drivers \
	test_getc.prg \
	testdns.prg \
	test_cifs.prg \
	test_disk_io.prg \
	testdns.pg2 \
	testtftp.prg \
	testtftp.pg2 \
	test_cart_api.prg \
	test_vt100.prg \
	testdottedquad.pg2 \
	testdottedquad.prg \
	test_tcp.prg \
	test_xmodem.prg \
	test_vic20.prg \
	test_httpd.prg \
	test_parser.prg \
	test_ping.prg \
	test_sntp.prg \
	test_get_url.prg \
	test_wiznet.prg \
	test_parse_querystring.prg \
#	test_xmodem.d64 \
#	httpd_test.d64 \
#	ip65test.dsk \
#	test_disk_io.d64 \


ip65:
	make -C ../ip65 all

drivers:
	make -C ../drivers all

%.o: %.s
	$(AS) $(AFLAGS) $<


%.prg: %.o $(IP65LIB) $(C64RRNETLIB) $(INCFILES) ../cfg/c64prg.cfg
	$(LD) -m  $*.map -vm -C ../cfg/c64prg.cfg -o  $*.prg  $(AFLAGS) $< $(IP65LIB) $(C64RRNETLIB)  


test_tcp.prg: test_tcp.o $(IP65TCPLIB) $(C64RRNETLIB) $(INCFILES) ../cfg/c64prg.cfg
	$(LD) -m  test_tcp.map -vm -C ../cfg/c64prg.cfg -o  test_tcp.prg  $(AFLAGS) $< $(IP65TCPLIB) $(C64RRNETLIB)  

test_xmodem.o: test_xmodem.s ../ip65/xmodem.s
	$(AS) $(AFLAGS) $<


test_xmodem.prg: test_xmodem.o $(IP65TCPLIB) $(C64RRNETLIB) $(INCFILES) ../cfg/c64prg.cfg 
	$(LD) -m  test_xmodem.map -vm -C ../cfg/c64prg.cfg -o  test_xmodem.prg  $(AFLAGS) $< $(IP65TCPLIB) $(C64RRNETLIB)  

test_parser.prg: test_parser.o $(IP65TCPLIB) $(C64RRNETLIB) $(INCFILES) ../cfg/c64prg.cfg
	$(LD) -m  test_parser.map -vm -C ../cfg/c64prg.cfg -o  test_parser.prg  $(AFLAGS) $< $(IP65TCPLIB) $(C64RRNETLIB)  


test_get_url.prg: test_get_url.o $(IP65TCPLIB) $(C64RRNETLIB) $(INCFILES) ../cfg/c64prg.cfg
	$(LD) -m  test_get_url.map -vm -C ../cfg/c64prg.cfg -o  test_get_url.prg  $(AFLAGS) $< $(IP65TCPLIB) $(C64RRNETLIB)  


test_ping.prg: test_ping.o $(IP65TCPLIB) $(C64RRNETLIB) $(INCFILES) ../cfg/c64prg.cfg
	$(LD) -m  test_ping.map -vm -C ../cfg/c64prg.cfg -o  test_ping.prg  $(AFLAGS) $< $(IP65TCPLIB) $(C64RRNETLIB)  

test_wiznet.prg: test_wiznet.o $(C64WIZNETLIB) $(IP65WIZNETLIB) $(INCFILES) ../cfg/c64prg.cfg
	$(LD) -m  test_wiznet.map -vm -C ../cfg/c64prg.cfg -o test_wiznet.prg  $(AFLAGS) $<  $(IP65WIZNETLIB) $(C64WIZNETLIB)
	cp test_wiznet.prg ../../server/boot/autoexec.prg


test_cifs.prg: test_cifs.o $(IP65TCPLIB) $(C64RRNETLIB) $(INCFILES) ../cfg/c64prg.cfg 
	$(LD) -m  test_cifs.map -vm -C ../cfg/c64prg.cfg -o  test_cifs.prg  $(AFLAGS) $< $(IP65TCPLIB) $(C64RRNETLIB)  

test_vic20.prg: test_vic20.o $(IP65TCPLIB) $(VIC20RRNETLIB) $(INCFILES) ../cfg/vic20prg.cfg
	$(LD) -m  test_vic20.map -vm -C ../cfg/vic20prg.cfg -o  test_vic20.prg  $(AFLAGS) $< $(IP65TCPLIB) $(VIC20RRNETLIB)  

%.pg2: %.o $(IP65LIB) $(APPLE2PROGLIB) $(INCFILES) ../cfg/a2bin.cfg
	$(LD) -C ../cfg/a2bin.cfg -o  $*.pg2  $(AFLAGS) $< $(IP65LIB) $(APPLE2PROGLIB)




httpd_test.d64:  test_httpd.prg index.html file1.html
	cp test_httpd.prg autoexec.prg
	ripxplore.rb --init CbmDos httpd_test.d64 -a autoexec.prg
	ripxplore.rb httpd_test.d64 -a index.html -t C64Seq
	ripxplore.rb httpd_test.d64 -a file1.html -t C64Seq


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


test_xmodem.d64:  test_xmodem.prg 
		ripxplore.rb --init CbmDos test_xmodem.d64 -a test_xmodem.prg

clean:
	rm -f *.o *.pg2 *.prg
	rm -f ip65test.dsk

  
distclean: clean
	rm -f *~

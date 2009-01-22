CC=cl65
AS=ca65
LD=ld65
CFLAGS=-Oirs -t $(TARGET)
AFLAGS=


IP65LIB=../ip65/ip65.lib
C64NETLIB=../drivers/c64net.lib
APPLE2NETLIB=../drivers/apple2net.lib

INCFILES=\
  ../inc/common.i\
  ../inc/commonprint.i\
  ../inc/net.i\

%.o: %.c
	$(CC) -c $(CFLAGS) $<

%.o: %.s
	$(AS) $(AFLAGS) $<

%.bin: %.o $(IP65LIB) $(APPLE2NETLIB) $(INCFILES) ../cfg/a2bin.cfg
	$(LD) -m  $*.map -C ../cfg/a2bin.cfg -o  $*.bin  $(AFLAGS) $< $(IP65LIB) $(APPLE2NETLIB)

%.prg: %.o $(IP65LIB) $(C64NETLIB) $(INCFILES) ../cfg/c64prg.cfg
	$(LD) -m  $*.map -C ../cfg/c64prg.cfg -o  $*.prg  $(AFLAGS) $< $(IP65LIB) $(C64NETLIB)  

ip65test.dsk: testdns.bin
		dsktool.rb --init dos33 ip65test.dsk -a testdns.bin -t B


all: \
	ip65test.dsk \
	testdns.bin \
	testdns.prg \  
	
  
clean:
	rm -f *.o
	rm -f testdns.prg testdns.map testdns.bin
	rm -f ip65test.dsk

distclean: clean
	rm -f *~

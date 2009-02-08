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

%.prg: %.o $(IP65LIB) $(C64NETLIB) $(INCFILES) ../cfg/c64prg.cfg
	$(LD) -m  $*.map -C ../cfg/c64prg.cfg -o  $*.prg  $(AFLAGS) $< $(IP65LIB) $(C64NETLIB)  

%.bin: %.o $(IP65LIB) $(APPLE2NETLIB) $(INCFILES) ../cfg/a2bin.cfg
	$(LD) -m  $*.map -C ../cfg/a2bin.cfg -o  $*.bin  $(AFLAGS) $< $(IP65LIB) $(APPLE2NETLIB)

ip65test.d64: testdns.prg testdottedquad.prg

ip65test.dsk: testdns.bin testdottedquad.bin
		ripxplore.rb --init AppleDos ip65test.dsk -a testdns.bin -t AppleBinary
		ripxplore.rb ip65test.dsk -a testdns.bin -t AppleBinary

all: \
	ip65test.dsk \
	testdns.prg \
	testdns.bin \
	testdottedquad.bin \
	testdottedquad.prg \
	ip65test.d64 \
  
clean:
	rm -f *.o
	rm -f testdns.prg testdns.map testdns.bin testdottedquad.prg testdottedquad.bin
	rm -f ip65test.dsk

distclean: clean
	rm -f *~

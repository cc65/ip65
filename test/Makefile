CC=cl65
AS=ca65
LD=ld65
CFLAGS=-Oirs -t $(TARGET)
AFLAGS=


IP65LIB=../ip65/ip65.lib
C64NETLIB=../drivers/c64net.lib

INCFILES=\
  ../inc/common.i\
  ../inc/commonprint.i\
  ../inc/net.i\

%.o: %.c
	$(CC) -c $(CFLAGS) $<

%.o: %.s
	$(AS) $(AFLAGS) $<

%.prg: %.o $(IP65LIB) $(C64NETLIB) $(INCFILES)
	$(LD) -m  $*.map -C ../cfg/c64prg.cfg -o  $*.prg  $(AFLAGS) $< $(IP65LIB) $(C64NETLIB)  

all: \
	testeth.prg \
	testarp.prg \
	testarpcache.prg \
	testping.prg \
	testcksum.prg \
	testsend.prg \
	testtimer.prg \
	testudp.prg \
	testudpsend.prg \
	testdns.prg \
  testtcpsend.prg \

clean:
	rm -f *.o
	rm -f testeth.prg testeth.map
	rm -f testarp.prg testarp.map
	rm -f testarpcache.prg testarpcache.map
	rm -f testping.prg testping.map
	rm -f testsend.prg testsend.map
	rm -f testcksum.prg testcksum.map
	rm -f testtimer.prg testtimer.map
	rm -f testudp.prg testudp.map
	rm -f testudpsend.prg testudpsend.map
	rm -f testdns.prg testdns.map
	rm -f testtcpsend.prg testtcpsend.map

distclean: clean
	rm -f *~

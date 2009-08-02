CC=cl65
AS=ca65
LD=ld65
CFLAGS=-Oirs -t $(TARGET)
AFLAGS=


IP65LIB=../ip65/ip65.lib

IP65TCPLIB=../ip65/ip65_tcp.lib

C64PNB65LIB=../drivers/c64nb65.lib
APPLE2PROGLIB=../drivers/apple2prog.lib

INCFILES=\
  ../inc/common.i\
  ../inc/commonprint.i\
  ../inc/net.i\

all: \
	kipper.dsk \
  
%.o: %.c
	$(CC) -c $(CFLAGS) $<

%.o: %.s
	$(AS) $(AFLAGS) $<

kipper.o: kipper.s ../inc/gopher.i ../inc/telnet.i
	$(AS) $(AFLAGS) $<

kipper.pg2: kipper.o $(IP65TCPLIB) $(APPLE2PROGLIB) $(INCFILES) ../cfg/a2bin.cfg 
	$(LD)  -C ../cfg/a2bin.cfg -m kipper.map -vm -o  kipper.pg2  $(AFLAGS) $< $(IP65TCPLIB) $(APPLE2PROGLIB)

#%.pg2: %.o $(IP65LIB) $(APPLE2PROGLIB) $(INCFILES) ../cfg/a2bin.cfg
#	$(LD) -C ../cfg/a2bin.cfg -o  $*.pg2  $(AFLAGS) $< $(IP65LIB) $(APPLE2PROGLIB)

kipper.dsk:  kipper.pg2
		ripxplore.rb --init BeautifulBoot kipper.dsk -a kipper.pg2 -t AppleBinary		
    
clean:
	rm -f *.o *.pg2 *.prg
	rm -f kipper.dsk
  
distclean: clean
	rm -f *~

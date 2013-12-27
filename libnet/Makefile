CC=cc65
CL=cl65
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
LIBNET=libnet.o

INCFILES=\
  ../inc/common.i\
  ../inc/commonprint.i\
  ../inc/net.i\

all: \
	ip65 \
	drivers \
	libnet.o \
	test_sntp.prg \

ip65:
	make -C ../ip65 all

drivers:
	make -C ../drivers all

%.o: %.s
	$(AS) $(AFLAGS) $<

test_sntp.prg: test_sntp.c $(IP65TCPLIB) $(C64RRNETLIB) $(INCFILES) $(LIBNET)
	$(CL) $< -m test_sntp.map -C c64libnet.cfg -o $@  $(LIBNET)  $(IP65TCPLIB) $(C64RRNETLIB) 
	$(CC) test_sntp.c	#this just makes a asm listing to help debug
	


clean:
	-rm -f *.o *.pg2 *.prg *.map
	-rm -f ip65test.dsk

  
distclean: clean
	-rm -f *~

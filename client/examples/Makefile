CC=cl65
AS=ca65
LD=ld65
CFLAGS=-Oirs -t $(TARGET)
AFLAGS=


IP65TCPLIB=../ip65/ip65_tcp.lib

C64PROGLIB=../drivers/c64prog.lib

INCFILES=\
  ../inc/common.i\
  ../inc/commonprint.i\
  ../inc/net.i\

all: \
	comatomx.prg \

%.o: %.s sine_data.i 
	$(AS) $(AFLAGS) $<

sine_data.i: make_sine_data.rb
	ruby make_sine_data.rb
  
%.prg: %.o $(IP65LIB) $(C64PROGLIB) $(INCFILES) ../cfg/c64prg.cfg
	$(LD) -m  $*.map -vm -C ../cfg/c64prg.cfg -o  $*.prg  $(AFLAGS) $< $(IP65TCPLIB) $(C64PROGLIB)  

clean:
	rm -f *.o *.pg2 *.prg
	rm -f ip65test.dsk
  
distclean: clean
	rm -f *~

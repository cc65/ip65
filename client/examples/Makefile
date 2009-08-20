CC=cl65
AS=ca65
LD=ld65
CFLAGS=-Oirs -t $(TARGET)
AFLAGS=


IP65TCPLIB=../ip65/ip65_tcp.lib
#C64PROGLIB=../drivers/c64prog.lib
#NT2PLAY=nt2play.o
INCFILES=\
  ../inc/common.i\
  ../inc/commonprint.i\
  ../inc/net.i\

all: \
	comatomx.prg \

%.o: %.s 
	$(AS) $(AFLAGS) $<

comatomx.o: comatomx.s sine_data.i 
	$(AS) $(AFLAGS) $<

sine_data.i: make_sine_data.rb
	ruby make_sine_data.rb
  
comatomx.prg: comatomx.o nt2play.o $(IP65TCPLIB) $(C64PROGLIB) $(INCFILES) ../cfg/c64prg.cfg
	$(LD) -m  comatomx.map -vm -C ../cfg/c64prg.cfg -o  comatomx.prg  $(AFLAGS) $< $(IP65TCPLIB) $(C64PROGLIB) $(NT2PLAY)
	cp comatomx.prg ../../server/boot/
clean:
	rm -f *.o *.pg2 *.prg *.map
  
distclean: clean
	rm -f *~

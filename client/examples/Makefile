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

all: 	upnatom.prg upnatom.d64

%.o: %.s 
	$(AS) $(AFLAGS) $<

upnatom.o: upnatom.s sine_data.i 
	$(AS) $(AFLAGS) $<

sine_data.i: make_sine_data.rb
	ruby make_sine_data.rb
  
upnatom.prg: upnatom.o nt2play.o $(IP65TCPLIB) $(C64PROGLIB) $(INCFILES) ../cfg/c64prg.cfg
	$(LD) -m  upnatom.map -vm -C ../cfg/c64prg.cfg -o  upnatom.prg  $(AFLAGS) $< $(IP65TCPLIB) $(C64PROGLIB) $(NT2PLAY)
	cp upnatom.prg ../../server/boot/
  
upnatom.d64:  upnatom.prg url.cfg
	cp upnatom.prg autoexec.prg
	ripxplore.rb --init CbmDos upnatom.d64 -a autoexec.prg
	ripxplore.rb  upnatom.d64 -a url.cfg -t C64Seq

clean:
	rm -f *.o *.pg2 *.prg *.map upnatom.d64
  
distclean: clean
	rm -f *~

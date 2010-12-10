AS=ca65
LD=ld65
CFLAGS=-Oirs -t $(TARGET)
AFLAGS= 

INCFILES=\
  ../inc/common.i\
  ../inc/commonprint.i\
  ../inc/net.i\
  ../inc/menu.i\
  ../inc/kipper_constants.i\
  ../inc/version.i\

IP65LIB=../ip65/ip65.lib

IP65TCPLIB=../ip65/ip65_tcp.lib

C64RRNETLIB=../drivers/c64rrnet.lib

all:  kipperterm2.prg kipperterm2.d64

kipperterm2.o: kipperterm2.s $(INCFILES) ../inc/telnet.i ../inc/config_menu.i ../inc/gopher.i
	$(AS) $(AFLAGS) -o $@ $<

%.o: %.s $(INCFILES) 
	$(AS) $(AFLAGS) $<

%.prg: %.o $(IP65LIB) $(C64RRNETLIB) $(INCFILES) ../cfg/c64fullprg.cfg
	$(LD) -m  $*.map -vm -C ../cfg/c64fullprg.cfg -o  $*.prg  $(AFLAGS) $< $(IP65TCPLIB) $(C64RRNETLIB)  
	ruby ../carts/set_ip_config.rb $@ mac auto

kipperterm2.d64: kipperterm2.prg addresses.txt abe.bas
	ripxplore.rb --init CbmDos $@ -a kipperterm2.prg
	ripxplore.rb $@ -a 80columns -t C64Prg
	ripxplore.rb $@ -a addresses.txt -t C64Seq
	ripxplore.rb $@ -a abe -t C64Prg
	cp kipperterm2.d64 ../../server/boot
 
clean:
	rm -f *.o *.bin *.map *.prg *.pg2 *.dsk *.d64

distclean: clean
	rm -f *~

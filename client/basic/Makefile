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

IP65LIB=../ip65/ip65_tcp.lib
C64RRNETLIB=../drivers/c64rrnet.lib
VIC20RRNETLIB=../drivers/vic20rrnet.lib

all:  ip65 kipperbas.d64 bails.d64 kipperbasv20.prg

ip65:
	make -C ../ip65 all

%.o: %.s $(INCFILES) timestamp.rb
	ruby timestamp.rb > timestamp.i
	$(AS) $(AFLAGS) $<
	
%.prg: %.o $(IP65LIB) $(C64RRNETLIB) $(INCFILES) ../cfg/kipperbas.cfg
	$(LD) -m  $*.map -vm -C ../cfg/kipperbas.cfg -o  $*.prg  $(AFLAGS) $< $(IP65LIB) $(C64RRNETLIB)  

kipperbasv20.prg: kipperbasv20.o $(IP65LIB) $(VIC20RRNETLIB) $(INCFILES) ../cfg/kipperbasv20.cfg
	$(LD) -m  kipperbasv20.map -vm -C ../cfg/kipperbasv20.cfg -o  kipperbasv20.prg  $(AFLAGS) $< $(IP65LIB) $(VIC20RRNETLIB)  
                                      

bails.d64: bails.prg 
#	ripxplore.rb -r -e kbload $@ -o kbload
#	ripxplore.rb -r -e kbapp $@ -o kbapp
#	ripxplore.rb $@ -I CbmDos -a kipperbas.prg
	ripxplore.rb $@  -a bails.prg

kipperbas.d64: kipperbas.prg chat
#	ripxplore.rb -r -e kbload $@ -o kbload
#	ripxplore.rb -r -e kbapp $@ -o kbapp
	ripxplore.rb $@ -I CbmDos -a kipperbas.prg
#	ripxplore.rb $@  -a kipperbas.prg
	cp chat autoexec.bas
#	ripxplore.rb $@  -a autoexec.bas -t C64Prg
clean:
	rm -f *.o *.bin *.map *.prg

distclean: clean
	rm -f *~

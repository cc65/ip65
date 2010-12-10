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

all:  ip65 kipperbas.d64 bails.d64 

ip65:
	make -C ../ip65 all

%.o: %.s $(INCFILES) 
	$(AS) $(AFLAGS) $<
	
%.prg: %.o $(IP65LIB) $(C64RRNETLIB) $(INCFILES) ../cfg/kipperbas.cfg
	$(LD) -m  $*.map -vm -C ../cfg/kipperbas.cfg -o  $*.prg  $(AFLAGS) $< $(IP65LIB) $(C64RRNETLIB)  
                                      

bails.d64: bails.prg 
#	ripxplore.rb -r -e kbload $@ -o kbload
#	ripxplore.rb -r -e kbapp $@ -o kbapp
#	ripxplore.rb $@ -I CbmDos -a kipperbas.prg
	ripxplore.rb $@  -a bails.prg

kipperbas.d64: kipperbas.prg 
#	ripxplore.rb -r -e kbload $@ -o kbload
#	ripxplore.rb -r -e kbapp $@ -o kbapp
#	ripxplore.rb $@ -I CbmDos -a kipperbas.prg
	ripxplore.rb $@  -a kipperbas.prg

clean:
	rm -f *.o *.bin *.map *.prg

distclean: clean
	rm -f *~

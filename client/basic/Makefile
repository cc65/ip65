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

#IP65LIB=../ip65/ip65.lib
IP65LIB=../ip65/ip65_tcp.lib
#IP65TCPLIB=../ip65/ip65_tcp.lib

C64PROGLIB=../drivers/c64prog.lib

all:  gopherd.d64 kipperbas.d64

%.o: %.s $(INCFILES) 
	$(AS) $(AFLAGS) $<
	
%.prg: %.o $(IP65LIB) $(C64PROGLIB) $(INCFILES) ../cfg/c64_mlstub.cfg
	$(LD) -m  $*.map -vm -C ../cfg/c64_mlstub.cfg -o  $*.prg  $(AFLAGS) $< $(IP65LIB) $(C64PROGLIB)  


kipperbas.d64: kipperbas.prg 
	ripxplore.rb -r -e kbload $@ -o kbload
	ripxplore.rb -r -e kbapp $@ -o kbapp
	ripxplore.rb $@ -a kipperbas.prg

  
gopherd.d64: mlstub.prg gophermap.txt addresses.txt
	ripxplore.rb -r -e gopherd $@ -o gopherd.bas
	ripxplore.rb $@ -a mlstub.prg
	ripxplore.rb $@ -a gophermap.txt -t C64Seq
	ripxplore.rb $@ -a addresses.txt -t C64Seq
  
clean:
	rm -f *.o *.bin *.map *.prg

distclean: clean
	rm -f *~

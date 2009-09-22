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

TCP_INCFILES=../inc/gopher.i ../inc/telnet.i ../inc/ping.i
IP65LIB=../ip65/ip65.lib

IP65TCPLIB=../ip65/ip65_tcp.lib

C64PROGLIB=../drivers/c64prog.lib
C64NB65LIB=../drivers/c64nb65.lib

all:  kipperkart.bin kipperkart_rr.bin netboot.bin

kipperkart.o: kipperkart.s $(INCFILES) $(TCP_INCFILES)
	$(AS) $(AFLAGS) -o $@ $<

%.o: %.s $(INCFILES) 
	$(AS) $(AFLAGS) $<

%.prg: %.o $(IP65LIB) $(C64PROGLIB) $(INCFILES) ../cfg/c64prg.cfg
	$(LD) -m  $*.map -vm -C ../cfg/c64prg.cfg -o  $*.prg  $(AFLAGS) $< $(IP65LIB) $(C64PROGLIB)  

netboot.bin: netboot.o $(IP65LIB) $(C64PROGLIB) $(INCFILES) ../cfg/c64_8kcart.cfg
	$(LD) -m netboot.map -vm -C ../cfg/c64_8kcart.cfg -o $@  $< $(IP65LIB) $(C64PROGLIB)  
	ruby fix_cart.rb $@ 8192

kipperkart.bin: kipperkart.o $(IP65TCPLIB) $(C64NB65LIB) $(INCFILES) ../cfg/c64_16kcart.cfg
	$(LD) -m kipperkart.map -vm -C ../cfg/c64_16kcart.cfg -o $@  $< $(IP65TCPLIB) $(C64NB65LIB)  
	ruby fix_cart.rb $@ 16384
	ruby dupe_cart.rb kipperkart.bin kipperkart_29c040.bin 32
  
kipperkart_rr.bin: kipperkart.bin 
	cp crt8040.obj rrnet_header.bin	
	cat rrnet_header.bin kipperkart.bin > kipperkart_rr.bin
	ruby fix_cart.rb $@ 32768
  
c64boot.d64: netboot_ram.prg 
	ripxplore.rb --init CbmDos $@ -a netboot_ram.prg
	ripxplore.rb $@ -a ..\test\test_cart_api.prg
  
d64_upload.d64: d64_upload.prg
	cp d64_upload.prg ../../server/boot/
	ripxplore.rb --init CbmDos $@ -a d64_upload.prg
  
clean:
	rm -f *.o *.bin *.map *.prg *.pg2 *.dsk *.d64

distclean: clean
	rm -f *~

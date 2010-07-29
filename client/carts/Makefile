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

C64PROGLIB=../drivers/c64prog.lib
#C64NB65LIB=../drivers/c64nb65.lib

all:  kipperkart.bin kipperkart_rr.bin netboot.bin kipperterm.bin kipperkart.prg kipperterm.prg kipperterm_rr.bin kippergo.bin kipperkart.prg kippergo.prg kippergo_rr.bin kipperdisk.d64

kipperkart.o: kipperkart.s $(INCFILES)  ../inc/ping.i ../inc/disk_transfer.i ../inc/sidplay.i   ../inc/config_menu.i
	$(AS) $(AFLAGS) -o $@ $<

kipperterm.o: kipperterm.s $(INCFILES) ../inc/telnet.i ../inc/config_menu.i
	$(AS) $(AFLAGS) -o $@ $<

kippergo.o: kippergo.s $(INCFILES) ../inc/gopher.i ../inc/telnet.i ../inc/config_menu.i
	$(AS) $(AFLAGS) -o $@ $<

%.o: %.s $(INCFILES) 
	$(AS) $(AFLAGS) $<

kipperkart.prg: kipperkart.bin c64_cart_ram_header.prg
	cat c64_cart_ram_header.prg kipperkart.bin > kipperkart.prg

kipperterm.prg: kipperterm.bin c64_cart_ram_header.prg
	cat c64_cart_ram_header.prg kipperterm.bin > kipperterm.prg

kippergo.prg: kippergo.bin c64_cart_ram_header.prg
	cat c64_cart_ram_header.prg kippergo.bin > kippergo.prg

%.prg: %.o $(IP65LIB) $(C64PROGLIB) $(INCFILES) ../cfg/c64prg.cfg
	$(LD) -m  $*.map -vm -C ../cfg/c64prg.cfg -o  $*.prg  $(AFLAGS) $< $(IP65LIB) $(C64PROGLIB)  

netboot.bin: netboot.o $(IP65LIB) $(C64PROGLIB) $(INCFILES) ../cfg/c64_8kcart.cfg
	$(LD) -m netboot.map -vm -C ../cfg/c64_8kcart.cfg -o $@  $< $(IP65LIB) $(C64PROGLIB)  
	ruby fix_cart.rb $@ 8192

kipperkart.bin: kipperkart.o $(IP65TCPLIB) $(C64PROGLIB) $(INCFILES) ../cfg/c64_16kcart.cfg
	$(LD) -m kipperkart.map -vm -C ../cfg/c64_16kcart.cfg -o $@  $< $(IP65TCPLIB) $(C64PROGLIB)  
	ruby fix_cart.rb $@ 16384
	ruby set_ip_config.rb $@ mac auto
	ruby dupe_cart.rb kipperkart.bin kipperkart_29c040.bin 32

kipperterm.bin: kipperterm.o $(IP65TCPLIB) $(C64PROGLIB) $(INCFILES) ../cfg/c64_16kcart.cfg
	$(LD) -m kipperterm.map -vm -C ../cfg/c64_16kcart.cfg -o $@  $< $(IP65TCPLIB) $(C64PROGLIB)  
	ruby fix_cart.rb $@ 16384
	ruby dupe_cart.rb kipperterm.bin kipperterm_29c040.bin 32

kipperterm_rr.bin: kipperterm.bin 
	cp crt8040.obj rrnet_header.bin	
	cat rrnet_header.bin kipperterm.bin > kipperterm_rr.bin
	ruby fix_cart.rb $@ 32768


kippergo.bin: kippergo.o $(IP65TCPLIB) $(C64PROGLIB) $(INCFILES) ../cfg/c64_16kcart.cfg
	$(LD) -m kippergo.map -vm -C ../cfg/c64_16kcart.cfg -o $@  $< $(IP65TCPLIB) $(C64PROGLIB)  
	ruby fix_cart.rb $@ 16384
	ruby dupe_cart.rb kippergo.bin kippergo_29c040.bin 32

kippergo_rr.bin: kippergo.bin 
	cp crt8040.obj rrnet_header.bin	
	cat rrnet_header.bin kippergo.bin > kippergo_rr.bin
	ruby fix_cart.rb $@ 32768

kipperkart_rr.bin: kipperkart.bin 
	cp crt8040.obj rrnet_header.bin	
	cat rrnet_header.bin kipperkart.bin > kipperkart_rr.bin
	ruby fix_cart.rb $@ 32768
  
kipperdisk.d64: kipperkart.prg kipperterm.prg kipperkart.prg kippergo.prg
	ripxplore.rb --init CbmDos $@ -a kipperkart.prg
	ripxplore.rb $@ -a kipperterm.prg
	ripxplore.rb $@ -a kippergo.prg
	cp $@ ../../server/boot/
  		
d64_upload.d64: d64_upload.prg
	cp d64_upload.prg ../../server/boot/
	ripxplore.rb --init CbmDos $@ -a d64_upload.prg
  
clean:
	rm -f *.o *.bin *.map *.prg *.pg2 *.dsk *.d64

distclean: clean
	rm -f *~

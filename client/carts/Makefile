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
C64WIZNETLIB=../drivers/c64wiznet.lib
IP65WIZNETLIB=../ip65/ip65_wiznet.lib

all:    ip65 drivers\
	kkwiz.bin \
	kkwiz.prg \
	bobcart.bin \
	kipperkart.bin \
	kipperkart_rr.bin \
	netboot.bin \
	kipperterm.bin \
	kipperkart.prg \
	kipperterm.prg \
	kipperterm_rr.bin \
	kippergo.bin \
	kipperkart.prg \
	kippergo.prg \
	kippergo_rr.bin \
	kkwiz_rr.bin \
	telnetd.prg \
	kipperdisk.d64 \

kipperkart.o: kipperkart.s $(INCFILES)  ../inc/ping.i ../inc/disk_transfer.i ../inc/sidplay.i   ../inc/config_menu.i
	$(AS) $(AFLAGS) -o $@ $<

kipperterm.o: kipperterm.s $(INCFILES) ../inc/telnet.i ../inc/config_menu.i
	$(AS) $(AFLAGS) -o $@ $<

kippergo.o: kippergo.s $(INCFILES) ../inc/gopher.i ../inc/telnet.i ../inc/config_menu.i
	$(AS) $(AFLAGS) -o $@ $<

%.o: %.s $(INCFILES) 
	ruby timestamp.rb > timestamp.i
	$(AS) $(AFLAGS) $<

kipperkart.prg: kipperkart.bin c64_cart_ram_header.prg
	cat c64_cart_ram_header.prg kipperkart.bin > kipperkart.prg


kkwiz.prg: kkwiz.bin c64_cart_ram_header.prg
	cat c64_cart_ram_header.prg kkwiz.bin > kkwiz.prg

kipperterm.prg: kipperterm.bin c64_cart_ram_header.prg
	cat c64_cart_ram_header.prg kipperterm.bin > kipperterm.prg

kippergo.prg: kippergo.bin c64_cart_ram_header.prg
	cat c64_cart_ram_header.prg kippergo.bin > kippergo.prg

%.prg: %.o $(IP65LIB) $(C64RRNETLIB) $(INCFILES) ../cfg/c64prg.cfg
	$(LD) -m  $*.map -vm -C ../cfg/c64prg.cfg -o  $*.prg  $(AFLAGS) $< $(IP65LIB) $(C64RRNETLIB)  


netboot.bin: netboot.o $(IP65LIB) $(C64RRNETLIB) $(INCFILES) ../cfg/c64_8kcart.cfg
	$(LD) -m netboot.map -vm -C ../cfg/c64_8kcart.cfg -o $@  $< $(IP65LIB) $(C64RRNETLIB)  
	ruby fix_cart.rb $@ 8192

kipperkart.bin: kipperkart.o $(IP65TCPLIB) $(C64RRNETLIB) $(INCFILES) ../cfg/c64_16kcart.cfg
	$(LD) -m kipperkart.map -vm -C ../cfg/c64_16kcart.cfg -o $@  $< $(IP65TCPLIB) $(C64RRNETLIB)  
	ruby fix_cart.rb $@ 16384
	ruby set_ip_config.rb $@ mac auto
	ruby dupe_cart.rb kipperkart.bin kipperkart_29c040.bin 32

kipperterm.bin: kipperterm.o $(IP65TCPLIB) $(C64RRNETLIB) $(INCFILES) ../cfg/c64_16kcart.cfg
	$(LD) -m kipperterm.map -vm -C ../cfg/c64_16kcart.cfg -o $@  $< $(IP65TCPLIB) $(C64RRNETLIB)  
	ruby fix_cart.rb $@ 16384
	ruby dupe_cart.rb kipperterm.bin kipperterm_29c040.bin 32

kipperterm_rr.bin: kipperterm.bin 
	cp crt8040.obj rrnet_header.bin	
	cat rrnet_header.bin kipperterm.bin > kipperterm_rr.bin
	ruby fix_cart.rb $@ 32768


kippergo.bin: kippergo.o $(IP65TCPLIB) $(C64RRNETLIB) $(INCFILES) ../cfg/c64_16kcart.cfg
	$(LD) -m kippergo.map -vm -C ../cfg/c64_16kcart.cfg -o $@  $< $(IP65TCPLIB) $(C64RRNETLIB)  
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

bobcart.bin: bobcart.o $(IP65TCPLIB) $(C64RRNETLIB) $(INCFILES) ../cfg/c64_8kcart.cfg
	$(LD) -m bobcart.map -vm -C ../cfg/c64_8kcart.cfg -o $@  $< $(IP65TCPLIB) $(C64RRNETLIB)  
	ruby fix_cart.rb $@ 8192

kkwiz.bin: kipperkart.o $(IP65WIZNETLIB) $(C64WIZNETLIB) $(INCFILES) ../cfg/c64_16kcart.cfg
	$(LD) -m kkwiz.map -vm -C ../cfg/c64_16kcart.cfg -o $@  $< $(IP65WIZNETLIB) $(C64WIZNETLIB)
	ruby fix_cart.rb $@ 16384
#	ruby set_ip_config.rb $@ mac auto

kkwiz_rr.bin: kkwiz.bin 
	cp crt8040.obj rrnet_header.bin	
	cat rrnet_header.bin kkwiz.bin > kkwiz_rr.bin
	ruby fix_cart.rb $@ 32768
	cp kkwiz_rr.bin ../wiznet/

telnetd.bin: telnetd.o $(IP65TCPLIB) $(C64RRNETLIB) $(INCFILES) ../cfg/c64_8kcart.cfg
	$(LD) -m telnetd.map -vm -C ../cfg/c64_8kcart.cfg -o $@  $< $(IP65TCPLIB) $(C64RRNETLIB)
	ruby ../carts/fix_cart.rb $@ 8192

telnetd.prg: telnetd.bin cartheader.prg
	cat cartheader.prg telnetd.bin > $@
  		
d64_upload.d64: d64_upload.prg
	cp d64_upload.prg ../../server/boot/
	ripxplore.rb --init CbmDos $@ -a d64_upload.prg
  
clean:
	rm -f *.o *.bin *.map *.prg *.pg2 *.dsk *.d64

distclean: clean
	rm -f *~

ip65:
	make -C ../ip65 all

drivers:
	make -C ../drivers all

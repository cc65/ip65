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


all: ip65 drivers\
	wizboot.bin \
	wizboot2.prg \
	cartheader.prg \
	wiztest.prg \
	wizboot.prg \
	telnetd.bin \
	telnetd.prg \
	wizbobcart.prg \
	kt2wiz.d64	\
	wiztest.d64 \
	bootc64.prg \
	
%.o: %.s $(INCFILES) timestamp.rb
	ruby timestamp.rb > timestamp.i
	$(AS) $(AFLAGS) $<


%.prg: %.o $(IP65WIZNETLIB) $(C64WIZNETLIB) $(INCFILES) ../cfg/c64prg.cfg
	$(LD) -m  $*.map -vm -C ../cfg/c64prg.cfg -o  $*.prg  $(AFLAGS) $< $(IP65WIZNETLIB) $(C64WIZNETLIB)


wizboot.bin: wizboot.o $(IP65WIZNETLIB) $(C64WIZNETLIB) $(INCFILES) ../cfg/c64_8kcart.cfg
	$(LD) -m wizboot.map -vm -C ../cfg/c64_8kcart.cfg -o $@  $< $(IP65WIZNETLIB) $(C64WIZNETLIB)  
	ruby ../carts/fix_cart.rb $@ 8192

wizboot.prg: wizboot.bin cartheader.prg
	cat cartheader.prg wizboot.bin > $@

wizflash.prg: wizboot.bin wizflashheader.prg
	cat wizflashheader.prg wizboot.bin > $@

telnetd.o: ../carts/telnetd.s $(INCFILES) timestamp.rb
	$(AS) $(AFLAGS) ../carts/telnetd.s -o telnetd.o

telnetd.bin: telnetd.o $(IP65WIZNETLIB) $(C64WIZNETLIB) $(INCFILES) ../cfg/c64_8kcart.cfg
	$(LD) -m telnetd.map -vm -C ../cfg/c64_8kcart.cfg -o $@  $< $(IP65WIZNETLIB) $(C64WIZNETLIB)  
	ruby ../carts/fix_cart.rb $@ 8192

telnetd.prg: telnetd.bin cartheader.prg
	cat cartheader.prg telnetd.bin > $@

wizbobcart.bin: wizbobcart.o $(IP65WIZNETLIB) $(C64WIZNETLIB) $(INCFILES) wizbobcart.cfg
	$(LD) -m wizbobcart.map -vm -C wizbobcart.cfg -o $@  $< $(IP65WIZNETLIB) $(C64WIZNETLIB) 
	ruby ../carts/fix_cart.rb $@ 8192

wizbobcart.prg: wizbobcart.bin cartheader.prg
	cat cartheader.prg wizbobcart.bin > $@
	
wiztest.d64: wiztest.prg wizboot.prg wizflash.prg
	ripxplore.rb -I CbmDos $@
	ripxplore.rb -a wizboot.prg $@
	ripxplore.rb -a wiztest.prg $@
	ripxplore.rb -a	wizflash.prg $@
	
clean:
	rm -f *.o *.bin *.map *.prg *.pg2 *.dsk *.d64

distclean: clean
	rm -f *~

ip65:
	make -C ../ip65 all

drivers:
	make -C ../drivers all

kt2wiz.d64:
	make -C ../kipperterm2 kt2wiz.d64
	
	
bootc64.prg:
#	cp wizbobcart.prg ../../server/boot/bootc64.prg
#	cp telnetd.prg ../../server/boot/bootc64.prg
#	cp wizboot2.prg ../../server/boot/bootc64.prg	
	cp wiztest.prg	../../server/boot/bootc64.prg
#	cp wizflash.prg	../../server/boot/bootc64.prg
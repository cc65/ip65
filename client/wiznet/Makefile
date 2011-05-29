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
	bootc64.prg \
	
%.o: %.s $(INCFILES) 
	$(AS) $(AFLAGS) $<


%.prg: %.o $(IP65WIZNETLIB) $(C64WIZNETLIB) $(INCFILES) ../cfg/c64prg.cfg
	$(LD) -m  $*.map -vm -C ../cfg/c64prg.cfg -o  $*.prg  $(AFLAGS) $< $(IP65WIZNETLIB) $(C64WIZNETLIB)


kipperwizdisk.d64: ../carts/kkwiz.prg ../kipperterm2/kt2wiz.prg 
	ripxplore.rb --init CbmDos $@ -a ../carts/kkwiz.prg
	ripxplore.rb $@ -a ../kipperterm2/addresses.txt -t C64Seq
	ripxplore.rb $@ -a ../kipperterm2/abe -t C64Prg
	ripxplore.rb $@ -a ../kipperterm2/kt2wiz.prg -t C64Prg
	ripxplore.rb $@ -a ../examples/webnoter.prg -t C64Prg	
	cp $@ ../../server/boot/

wizboot.bin: wizboot.o $(IP65WIZNETLIB) $(C64WIZNETLIB) $(INCFILES) ../cfg/c64_8kcart.cfg
	$(LD) -m wizboot.map -vm -C ../cfg/c64_8kcart.cfg -o $@  $< $(IP65WIZNETLIB) $(C64WIZNETLIB)  
	ruby ../carts/fix_cart.rb $@ 8192

wizboot.prg: wizboot.bin cartheader.prg
	cat cartheader.prg wizboot.bin > wizboot.prg

clean:
	rm -f *.o *.bin *.map *.prg *.pg2 *.dsk *.d64

distclean: clean
	rm -f *~

ip65:
	make -C ../ip65 all

drivers:
	make -C ../drivers all

bootc64.prg:
#	cp wizboot.prg ../../server/boot/bootc64.prg
	cp wiztest.prg ../../server/boot/bootc64.prg
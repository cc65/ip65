AS=ca65
LD=ld65
CFLAGS=-Oirs -t $(TARGET)
AFLAGS= 

INCFILES=\
  ../inc/common.i\
  ../inc/commonprint.i\
  ../inc/net.i\
  ../inc/menu.i\
  ../inc/nb65_constants.i\

IP65LIB=../ip65/ip65.lib

C64PROGLIB=../drivers/c64prog.lib
C64NB65LIB=../drivers/c64nb65.lib
APPLE2PROGLIB=../drivers/apple2prog.lib

BOOTA2.PG2=../../server/boot/BOOTA2.PG2
  
all:  utherboot.dsk $(BOOTA2.PG2)  nb65_rrnet.bin   nb65_std_cart.bin nb65_c64_ram.prg d64_upload.prg c64boot.d64 d64_upload.d64
  
nb65_c64_ram.o: nb65_c64.s $(INCFILES)
	$(AS) -DBANKSWITCH_SUPPORT=0 $(AFLAGS) -o $@ $<

nb65_std_cart.o: nb65_c64.s $(INCFILES)
	$(AS) -DBANKSWITCH_SUPPORT=1 $(AFLAGS) -o $@ $<

nb65_rrnet.o: nb65_c64.s $(INCFILES)
	$(AS) -DBANKSWITCH_SUPPORT=2 $(AFLAGS) -o $@ $<

%.o: %.s $(INCFILES) 
	$(AS) $(AFLAGS) $<

nb65_c64_ram_header.bin: nb65_c64_ram_header.o ../cfg/c64prg.cfg 
	$(LD) -C ../cfg/c64prg.cfg -o $@  nb65_c64_ram_header.o 

nb65_c64_ram.prg: nb65_c64_ram_header.bin nb65_c64_ram.o $(IP65LIB) $(C64NB65LIB) $(INCFILES) ../cfg/rrbin.cfg
	$(LD) -m nb65_c64_ram.map -vm -C ../cfg/rrbin.cfg -o nb65_c64_ram.bin  nb65_c64_ram.o $(IP65LIB) $(C64NB65LIB)
	cat nb65_c64_ram_header.bin nb65_c64_ram.bin> nb65_c64_ram.prg

%.prg: %.o $(IP65LIB) $(C64PROGLIB) $(INCFILES) ../cfg/c64prg.cfg
	$(LD) -m  $*.map -vm -C ../cfg/c64prg.cfg -o  $*.prg  $(AFLAGS) $< $(IP65LIB) $(C64PROGLIB)  

nb65_std_cart.bin: nb65_std_cart.o $(IP65LIB) $(C64NB65LIB) $(INCFILES) ../cfg/rrbin.cfg
	$(LD) -m nb65_std_cart.map -vm -C ../cfg/rrbin.cfg -o $@  $< $(IP65LIB) $(C64NB65LIB)  
	ruby fix_cart.rb $@ 8192

nb65_rrnet.bin: nb65_rrnet.o $(IP65LIB) $(C64NB65LIB) $(INCFILES) ../cfg/rrbin.cfg
	$(LD) -m nb65_rrnet.map -Ln nb65_rr.lab -vm -C ../cfg/rrbin.cfg -o $@  $< $(IP65LIB) $(C64NB65LIB)  
	ruby fix_cart.rb $@ 8193

utherboot.pg2: utherboot.o $(IP65LIB) $(APPLE2PROGLIB) $(INCFILES) ../cfg/a2language_card.cfg
	$(LD) -m utherboot.map -C ../cfg/a2language_card.cfg -o $@  $< $(IP65LIB) $(APPLE2PROGLIB)  

utherboot.dsk: utherboot.pg2
	ripxplore.rb --init AppleDos utherboot.dsk -a utherboot.pg2 -t AppleBinary
	ripxplore.rb utherboot.dsk -a hello -t Applesoft

c64boot.d64: nb65_c64_ram.prg 
	ripxplore.rb --init CbmDos $@ -a nb65_c64_ram.prg
	ripxplore.rb $@ -a ..\test\test_cart_api.prg

d64_upload.d64: d64_upload.prg
	ripxplore.rb --init CbmDos $@ -a d64_upload.prg

$(BOOTA2.PG2): bootmenu.o $(IP65LIB) $(APPLE2PROGLIB) $(INCFILES) ../cfg/a2language_card.cfg
	$(LD) -m bootmenu.map -C ../cfg/a2language_card.cfg -o $(BOOTA2.PG2)  $< $(IP65LIB) $(APPLE2PROGLIB)  
  
clean:
	rm -f *.o *.bin *.map *.prg *.pg2 *.dsk *.d64
	rm -f $(BOOTA2.PG2)

distclean: clean
	rm -f *~

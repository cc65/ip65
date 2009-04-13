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
  
all: \
	rrnetboot.bin \
	utherboot.dsk \
	64nicboot.bin  \
	$(BOOTA2.PG2) \  

rrnetboot.o: rrnetboot.s $(INCFILES)
	$(AS) -DBANKSWITCH_SUPPORT=2 $(AFLAGS) $<

64nicboot.o: rrnetboot.s $(INCFILES)
	$(AS) -DBANKSWITCH_SUPPORT=1 $(AFLAGS) -o 64nicboot.o $<

%.o: %.s $(INCFILES) 
	$(AS) $(AFLAGS) $<

rrnetboot.bin: rrnetboot.o $(IP65LIB) $(C64NB65LIB) $(INCFILES) ../cfg/rrbin.cfg
	$(LD) -m rrnetboot.map -vm -C ../cfg/rrbin.cfg -o rrnetboot.bin  $< $(IP65LIB) $(C64NB65LIB)  
	ruby fix_cart.rb rrnetboot.bin 8193

64nicboot.bin: 64nicboot.o $(IP65LIB) $(C64NB65LIB) $(INCFILES) ../cfg/rrbin.cfg
	$(LD) -C ../cfg/rrbin.cfg -o 64nicboot.bin  $< $(IP65LIB) $(C64NB65LIB)  
	ruby fix_cart.rb 64nicboot.bin 8192

utherboot.pg2: utherboot.o $(IP65LIB) $(APPLE2PROGLIB) $(INCFILES) ../cfg/a2language_card.cfg
	$(LD) -m utherboot.map -C ../cfg/a2language_card.cfg -o utherboot.pg2  $< $(IP65LIB) $(APPLE2PROGLIB)  

utherboot.dsk: utherboot.pg2
	ripxplore.rb --init AppleDos utherboot.dsk -a utherboot.pg2 -t AppleBinary
	ripxplore.rb utherboot.dsk -a hello -t Applesoft

$(BOOTA2.PG2): bootmenu.o $(IP65LIB) $(APPLE2PROGLIB) $(INCFILES) ../cfg/a2language_card.cfg
	$(LD) -m bootmenu.map -C ../cfg/a2language_card.cfg -o $(BOOTA2.PG2)  $< $(IP65LIB) $(APPLE2PROGLIB)  
  
clean:
	rm -f *.o
	rm -f rrnetboot.bin rrnetboot.map 
	rm -f 64nicboot.bin 64nicboot.map 
	rm -f utherboot.pg2 utherboot.map utherboot.dsk
	rm -f $(BOOTA2.PG2)

distclean: clean
	rm -f *~

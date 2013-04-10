AS=ca65
LD=ld65
CFLAGS=-Oirs -t $(TARGET)
AFLAGS= 

INCFILES=\
  ../inc/common.i\
  ../inc/commonprint.i\
  ../inc/net.i\
  ../inc/menu.i\
  ../inc/kipper_constants.i

IP65LIB=../ip65/ip65.lib

APPLE2PROGLIB=../drivers/a2uther.lib
  
%.o: %.s $(INCFILES) $(APPLE2PROGLIB) 
	$(AS) $(AFLAGS) $<

all: utherboot.dsk
  
#c700_rom.bin: c700_rom.o ../cfg/a2rom.cfg 
#	$(LD) -C ../cfg/a2rom.cfg  -o $@ c700_rom.o $(APPLE2PROGLIB)  
#
#bankswitch_eeprom.bin: bankswitch_eeprom.o ../cfg/a2rom.cfg 
#	$(LD) -C ../cfg/a2rom.cfg  -o $@ bankswitch_eeprom.o $(APPLE2PROGLIB)  
#
#applewin.exe: c700_rom.bin bankswitch_eeprom.bin patch_applewin.rb
#	ruby patch_applewin.rb
 

utherboot.pg2: utherboot.o $(IP65LIB) $(APPLE2PROGLIB) $(INCFILES) ../cfg/a2language_card.cfg
	$(LD) -m utherboot.map -C ../cfg/a2language_card.cfg -o $@  $< $(IP65LIB) $(APPLE2PROGLIB)  

utherboot.dsk: utherboot.pg2
	ripxplore.rb --init AppleDos utherboot.dsk -a utherboot.pg2 -t AppleBinary
	ripxplore.rb utherboot.dsk -a hello -t Applesoft
	

clean:
	rm -f *.o *.bin *.map *.prg *.pg2 *.dsk *.d64

distclean: clean
	rm -f *~

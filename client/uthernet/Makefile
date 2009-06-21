AS=ca65
LD=ld65
CFLAGS=-Oirs -t $(TARGET)
AFLAGS= 

INCFILES=\
  ../inc/common.i\
  ../inc/commonprint.i\
  ../inc/simpleprint.i\
  ../inc/net.i\
  ../inc/menu.i\
  ../inc/nb65_constants.i\
  nb65_version.i\

IP65LIB=../ip65/ip65.lib

APPLE2PROGLIB=../drivers/apple2prog.lib
  
%.o: %.s $(INCFILES) $(APPLE2PROGLIB) 
	$(AS) $(AFLAGS) $<

all: applewin.exe
  
c700_rom.bin: c700_rom.o ../cfg/a2rom.cfg 
	$(LD) -C ../cfg/a2rom.cfg  -o $@ c700_rom.o $(APPLE2PROGLIB)  

bankswitch_eeprom.bin: bankswitch_eeprom.o ../cfg/a2rom.cfg 
	$(LD) -C ../cfg/a2rom.cfg  -o $@ bankswitch_eeprom.o $(APPLE2PROGLIB)  

applewin.exe: c700_rom.bin bankswitch_eeprom.bin patch_applewin.rb
	ruby patch_applewin.rb
  
clean:
	rm -f *.o *.bin *.map *.prg *.pg2 *.dsk *.d64

distclean: clean
	rm -f *~

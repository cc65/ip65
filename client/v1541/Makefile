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

IP65LIB=../ip65/ip65_tcp.lib

C64PROGLIB=../drivers/c64prog.lib

all: v1541.prg 


%.o: %.s $(INCFILES) 
	$(AS) $(AFLAGS) $<

%.d64: %.prg 
	ripxplore.rb $*.d64 -I CbmDos -a $*.prg
	
%.prg: %.o $(IP65LIB) $(C64PROGLIB) $(INCFILES) v1541.cfg
	$(LD) -m  $*.map -vm -C v1541.cfg -o  $*.prg  $(AFLAGS) $< $(IP65LIB) $(C64PROGLIB)  
                                      

clean:
	rm -f *.o *.bin *.map *.prg *.d64

distclean: clean
	rm -f *~
